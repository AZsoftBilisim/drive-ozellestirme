
#Region Variables

//used by the mechanism for processing changes in PM details
&AtClient
Var CachedValues;


#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	If Parameters.Key.IsEmpty() Then
		If Parameters.Property("PurchaseDocumentsAll") Then
			PurchasingDocumentsList.LoadValues(Parameters.PurchaseDocumentsAll);
		EndIf;
		Parameters.Property("PurchasingEditableDocument", PurchasingEditableDocument);
		OnReadCreateAtServer();
	EndIf;
	
	VisibilityOfGoodsReceiptCreation = AccessRight("Insert", Metadata.Documents.VendorInvoice);
	Items.ListOfPurchaseDocumentsPurchasesCreatePTU.Visible = VisibilityOfGoodsReceiptCreation;
	VisibilityOfTicketCreation = AccessRight("Insert", Metadata.Documents.ElectronicTicketTransaction);
	Items.AListOfPurchasingDocumentsPurchaseToCreateAnETicket.Visible = VisibilityOfTicketCreation;
	
	CreateButtons = 0;
	If VisibilityOfGoodsReceiptCreation Then
		CreateButtons = CreateButtons + 1;
	EndIf;
	If VisibilityOfTicketCreation Then
		CreateButtons = CreateButtons + 1;
	EndIf;
	
	If CreateButtons = 1 Then
		
		If VisibilityOfGoodsReceiptCreation Then
			CreationElement = Items.ListOfPurchaseDocumentsPurchasesCreatePTU;
		ElsIf VisibilityOfTicketCreation Then
			CreationElement = Items.AListOfPurchasingDocumentsPurchaseToCreateAnETicket;
		EndIf;
		
		CreationElement.Title = NStr("vi = 'Tạo mới';
									|ru = 'Создать';
									|en = 'Create'; fa = 'ایجاد';
									|it = 'Creare';
									|pl = 'Create';
									|tr = 'Oluştur'");
		Items.Move(CreationElement, Items.PurchaseDocumentsAll.CommandBar, Items.PurchasingDocumentListCreateGroup);
	EndIf;
	
	If CreateButtons = 0 Then
		Items.ListOfPurchaseDocumentsPurchasesPickUp.Visible = False;
		Items.AListOfPurchasingDocumentsPurchaseToRemove.Visible = False;
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.ExpenseReport.ItemsAndDimensionsSelectionParameters(Object.Status);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
	EditRight = AccessRight("Update", Metadata.Documents.ExpenseReport);
	Items.AListOfPurchasingDocumentsPurchaseToRemove.Enabled = EditRight;
	Items.ListOfPurchaseDocumentsPurchasesPickUp.Enabled = EditRight;
	Items.PurchasingDocumentListCreateGroup.Enabled = EditRight;
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	

	SetupParameters = Documents.ExpenseReport.AccountingAccountSettings_(Object.Status);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)

	If ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SelectedRows = Items.OtherExpenses.SelectedRows;
		For Each String In SelectedRows Do
			RowData = Object.OtherExpenses.FindByID(String);
			RowData.Department = SelectionResult;
		EndDo;
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.ExpenseReport.ItemsAndDimensionsSelectionParameters(Object.Status);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OnReadCreateAtServer();
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	SetupParameters = Documents.ExpenseReport.AccountingAccountSettings_(Object.Status);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	For Each TableRow In Object.CurrencyConversion Do
		Items.CurrencyConversion.CurrentRow = TableRow.GetID();
		GenerateCourseInText();
	EndDo;
	
	InitializeVATMethod();
	
	If Object.Posted And Object.Status = Enums.ExpenseReportStatuses.Upholded Then
		CashServer.RevaluateFundsHeldByAccountablePersons(
			Object.Organization, Object.Date, Object.AdvanceHolder);
	EndIf;
	
	FillInAmountReceived();
	UpdatePurchaseDocuments();
	
	CalculateDocumentAmount(ThisForm);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ExpenseReport", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.AdditionalProperties.Insert("PurchaseDocumentsAll", PurchasingDocumentsList.UnloadValues());
	CurrentObject.AdditionalProperties.Insert("PurchasingEditableDocument", PurchasingEditableDocument);
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	MoveDateOfDocument(WriteParameters, CurrentObject);
	
	If ValueIsFilled(RecognizedDocuments) Then
		CurrentObject.AdditionalProperties.Insert("RecognizedDocuments",
			CommonClientServer.CollapseArray(RecognizedDocuments.UnloadValues()));
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_VendorInvoice"
		Or EventName = "Record_TicketsAndReservations" Then
		
		DefinePrintingSingleAdvanceReport();
		
		If PrintASingleExpenseReport Then
			
			ProcessPurchaseDocumentEntry();
			Items.PurchaseDocumentsAll.Refresh();
			
		EndIf;
		
		CalculateDocumentAmount(ThisForm);
	EndIf;
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	

	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtServer
Procedure ProcessPurchaseDocumentEntry();
	
	If ValueIsFilled(Object.Ref) Then
		PurchasingDocumentsList.LoadValues(Documents.ExpenseReport.PurchasingDocumentsList(Object.Ref));
	EndIf;
	UpdatePurchaseDocuments();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not Object.OtherExpenses.Count()
		And Not Object.PaymentToVendors.Count()
		And Not Object.CurrencyConversion.Count()
		And Not PurchasingDocumentsList.Count() Then
		
		If Object.Multicurrency Then
			Text = NStr("vi = 'Số tiền đã chi bằng 0.
				|Cần điền dữ liệu trên thẻ ""Mua hàng"", ""Chi phí"", ""Thanh toán cho nhà cung cấp"" hoặc ""Quy đổi tiền tệ""';
				|ru = 'Сумма израсходованных денежных средств равна 0.
				|Необходимо заполнить данные на закладке ""Закупки"", ""Расходы "", ""Оплата поставщикам"" или ""Конвертация валюты""';
				|en = 'Spent cash amount is 0.
				|Fill in data on the ""Purchases"", the ""Expenses"", the ""Payment to vendors"" or ""Currency conversion"" tab'; fa = 'Spent cash amount is 0.
				|Fill in data on the ""Purchases"", the ""Expenses"", the ""Payment to vendors"" or ""Currency conversion"" tab';
				|it = 'Importo di denaro speso è pari a 0.
				|È necessario compilare i dati nella scheda ""Acquisti"", ""Spese"", ""Pagamento ai fornitori"" o ""Conversione valuta""';
				|pl = 'Wartość wydanych pieniędzy jest równa 0.
				|Należy wypełnić dane w zakładkach „Zakup”, „Koszty”, „Płatności dla dostawców” lub „Konwersja walut”.';
				|tr = 'Harcanan para miktarı 0''a eşit.
				|""Satın almalar"", ""Giderler"", ""Tedarikçilere ödeme"" veya ""Para birimi dönüştürme"" sekmesindeki verileri doldurmanız gerekir.'");
		Else
			Text = NStr("vi = 'Số tiền đã chi bằng 0.
				|Cần điền dữ liệu trên thẻ ""Mua hàng"", ""Chi phí"", hoặc ""Thanh toán cho nhà cung cấp""';
				|ru = 'Сумма израсходованных денежных средств равна 0.
				|Необходимо заполнить данные на закладке ""Закупки"", ""Расходы "" или ""Оплата поставщикам""';
				|en = 'Spent cash amount is 0.
				|Fill in data on the ""Purchases"", the ""Expenses"" or the ""Payment to vendors"" tab'; fa = 'Spent cash amount is 0.
				|Fill in data on the ""Purchases"", the ""Expenses"" or the ""Payment to vendors"" tab';
				|it = 'Importo di denaro speso è pari a 0.
				|È necessario compilare i dati nella scheda ""Acquisti"", ""Spese"" o ""Pagamento ai fornitori""';
				|pl = 'Wartość wydanych pieniędzy jest równa 0.
				|Należy wypełnić dane w zakładce „Zakupy”, „Wydatki” lub „Płatności dla dostawców”';
				|tr = 'Harcanan para miktarı 0''a eşit.
				|""Satın almalar"", ""Giderler"" veya ""Tedarikçilere ödeme"" sekmesindeki verileri doldurmanız gerekir.'");
		EndIf;
		
		CommonClientServer.MessageToUser(Text,,, "AmountExpensed", Cancel);
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If ValueIsFilled(PurchasingEditableDocument) And ValueIsFilled(Object.Ref) Then
		NotifyChoice(Object.Ref);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	AskAQuestion = False;
	FoundRows = New Array;
	For Each TableRow In Object.PaymentToVendors Do
		If TableRow.AmountARAP > 0
			And TableRow.ARAPCurrency <> Object.Currency Then
			AskAQuestion = True;
			FoundRows.Add(TableRow);
		EndIf;
	EndDo;
	
	If Object.ConfirmationDate < Object.Date Then
		Object.ConfirmationDate = Object.Date;
	EndIf;
	
	If AskAQuestion Then
		Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject, New Structure("FoundRows", FoundRows));
		ShowQueryBox(Notification, NStr("vi = 'Xóa số tiền hạch toán?';
										|ru = 'Очистить суммы взаиморасчетов?';
										|en = 'Clear AR/AP amounts?'; fa = 'Clear AR/AP amounts?';
										|it = 'Cancellare gli importi di regolamenti reciproci?';
										|pl = 'Oczyścić wartości rozliczeń wzajemnych?';
										|tr = 'Alacak / Borç muhasebe tutarı silinsin mi?'"), QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	DateOnChangeServer();
	
	CalculateDocumentAmount(ThisForm);
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FoundRows = AdditionalParameters.FoundRows;
		For Each TableRow In FoundRows Do
			TableRow.AmountARAP = 0;
		EndDo;
	EndIf;
	
	DateOnChangeServer();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	UpdatePurchaseForActivity();
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	DefinePrintingSingleAdvanceReport();
	
	If Not PrintASingleExpenseReport Then
		PurchasingDocumentsList.Clear();
		UpdatePurchaseDocuments();
	EndIf;
	
	ConfigureDependentFormElementsOnServer("PrintASingleExpenseReport");
	
EndProcedure

&AtClient
Procedure ConfirmationDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.ConfirmationDate < Object.Date Then
		Object.ConfirmationDate = Object.Date;
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	CalculateDocumentAmount(ThisForm);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	Object.BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	UpdatePurchaseForActivity();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	FillInAmountReceived();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If CurrentCurrency <> Object.Currency
		And Object.PaymentToVendors.Total("AmountARAP") <> 0 Then
		For Each TableRow In Object.PaymentToVendors Do
			TableRow.AmountARAP = 0;
			If Not ValueIsFilled(TableRow.ARAPObject) Then
				TableRow.ARAPCurrency = Undefined;
			EndIf;
		EndDo;
	EndIf;
	
	If PurchasingDocumentsList.Count() > 0 Then
		QueryText = NStr("vi = 'Danh sách chứng từ mua hàng sẽ bị xóa, tiếp tục?';
						|ru = 'Список документов закупки будет очищен, продолжить ?';
						|en = 'Purchase document list will be cleared. Continue?'; fa = 'Purchase document list will be cleared. Continue?';
						|it = 'Список документов закупки будет очищен, продолжить ?';
						|pl = 'Purchase document list will be cleared. Continue?';
						|tr = 'Satın alma belgelerinin listesi temizlenecektir, devam edilsin mi?'");
		ShowQueryBox(New CallbackDescription("ListOfDocumentsQuestionEnd", ThisObject), QueryText, QuestionDialogMode.YesNo);
	Else
		ListOfDocumentsQuestionEnd(DialogReturnCode.Yes,Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOfDocumentsQuestionEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		PurchasingDocumentsList.Clear();
		
		If CurrentCurrency <> Object.Currency
			And ValueIsFilled(Object.Currency)
			And Object.AmountExpensed <> 0 Then
			
			QueryText = StrTemplate(NStr("vi = 'Tính lại số tiền trong chứng từ theo nguyên tệ %1 ?';
										|ru = 'Пересчитать суммы в документе в валюту %1 ?';
										|en = 'Convert amounts in the document in %1?'; fa = 'Convert amounts in the document in %1?';
										|it = 'Ricalcolare gli importi del documento in valuta %1 ?';
										|pl = 'Przelicz wartości w dokumencie do waluty %1 ?';
										|tr = 'Belgedeki tutarlar %1 para birimine göre yeniden hesaplansın mı?'"), Object.Currency);
			ShowQueryBox(New CallbackDescription("CurrencyOnChangeClientCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
			
		Else
			
			CurrentCurrency = Object.Currency;
			CurrencyOnChangeServer();
			CalculateDocumentAmount(ThisForm);
			
		EndIf;
	Else
		Object.Currency = CurrentCurrency;
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyOnChangeClientCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		ConversionOfDocumentAmountsIntoCurrencyServer();
		CalculateDocumentAmount(ThisForm);
		
		Text = StrTemplate(NStr("vi = 'Số tiền trong chứng từ đã được tính lại theo nguyên tệ %1';
								|ru = 'Суммы в документе пересчитаны в валюту %1';
								|en = 'Document amounts are converted to currency %1'; fa = 'Document amounts are converted to currency %1';
								|it = 'Gli importi nel documento sono stati ricalcolati in valuta %1';
								|pl = 'Wartości wa dokumencie zostały przeliczone do waluty %1';
								|tr = 'Belgedeki tutarlar %1 para birimine göre yeniden hesaplandı'"), Object.Currency);
		ShowUserNotification(NStr("vi = 'Số tiền tính lại';
									|ru = 'Суммы пересчитаны';
									|en = 'Amounts are recalculated'; fa = 'Amounts are recalculated';
									|it = 'Importi ricalcolati';
									|pl = 'Wartości zostały przeliczone';
									|tr = 'Tutarlar yeniden hesaplandı'"),, Text, PictureLib.Information32);
		
	Else
		UpdatePurchaseDocuments();
	EndIf;
	
	CurrentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer()
	
	FillInAmountReceived();
	UpdatePurchaseDocuments();
	
EndProcedure

&AtClient
Procedure AdvanceHolderOnChange(Item)
	
	AdvanceHolderOnChangeServer();
	CalculateDocumentAmount(ThisForm);
	
EndProcedure

&AtServer
Procedure AdvanceHolderOnChangeServer()
	
	If Not ValueIsFilled(Object.Department) Then
		Object.Department = PersonsTM.DivisionOfIndividual(Object.AdvanceHolder);
	EndIf;
	
	FillInAmountReceived();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	StatusChangedOnServer();
	
EndProcedure

&AtServer
Procedure StatusChangedOnServer()
	
	If Object.Status = Enums.ExpenseReportStatuses.Upholded Then
		Object.ConfirmationDate = CurrentSessionDate();
	EndIf;
	
	FillInAmountReceived();
	
	ItemsAndDimensionsSelectionParameters = Documents.ExpenseReport.ItemsAndDimensionsSelectionParameters(Object.Status);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	SetupParameters = Documents.ExpenseReport.AccountingAccountSettings_(Object.Status);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	ConfigureDependentFormElementsOnServer("Status");
	
EndProcedure

&AtClient
Procedure MultipleCurrenciesOnChange(Item)
	
	Modified = True;
	
	MultipleCurrenciesWhenChangedOnServer();
	CalculateDocumentAmount(ThisForm);
	
EndProcedure

&AtServer
Procedure MultipleCurrenciesWhenChangedOnServer()
	
	Object.Multicurrency = (MultipleCurrencies = 1);
	
	If Object.Multicurrency Then
		For Each TSRow In Object.OtherExpenses Do
			TSRow.Currency = Object.Currency;
		EndDo;
		For Each TSRow In Object.PaymentToVendors Do
			TSRow.Currency = Object.Currency;
		EndDo;
		Object.Currency = Undefined;
	Else
		Object.CurrencyConversion.Clear();
	EndIf;
	
	FillInAmountReceived();
	
	ConfigureDependentFormElementsOnServer("Multicurrency,MultiCurrencyBasement");
	
EndProcedure

&AtClient
Procedure PurchaseForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	ClearMessages();
	
	
	Return;
	
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);	
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	FillInAmountReceived();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPurchaseDocumentsAll

&AtClient
Procedure PurchaseDocumentsAllSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.CurrentData <> Undefined Then
		ShowValue(, Item.CurrentData.DocumentPurchases);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentToVendors

&AtClient
Procedure PaymentToVendorsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.PaymentToVendors.CurrentData;
	If Not Object.Multicurrency And Not CurrentData = Undefined Then
		CurrentData.Currency = Object.Currency;
	EndIf;
	CalculateDocumentAmount(ThisObject);
	
EndProcedure

&AtClient
Procedure PaymentToVendorsAfterDeleteRow(Item)
	
	CalculateDocumentAmount(ThisObject);
	
EndProcedure

&AtClient
Procedure PaymentToVendorsVendorOnChange(Item)
	
	TableRow = Items.PaymentToVendors.CurrentData;
	
	If TableRow <> Undefined Then
		TableRow.ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	EndIf;
	
	If TableRow = Undefined
		Or Not ValueIsFilled(TableRow.Vendor)
		Or ValueIsFilled(TableRow.Counterparty) Then
		Return;
	EndIf;
	
	DefaultCounterparty = GetPartnerSDefaultCounterparty(TableRow.Vendor);
	If DefaultCounterparty <> Undefined Then
		TableRow.Counterparty = DefaultCounterparty;
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentToVendorsSumOnChange(Item)
	
	Items.PaymentToVendors.CurrentData.AmountARAP = 0;
	
EndProcedure

&AtClient
Procedure PaymentToVendorsARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	CurrentData = Items.PaymentToVendors.CurrentData;
	If CurrentData <> Undefined Then
		ARAPObject = CurrentData.ARAPObject;
	EndIf;
	
	ARAPAccountingClient.ARAPObjectStartChoice(ThisForm, Item, StandardProcessing,, ARAPObject);
	
EndProcedure

&AtClient
Procedure PaymentToVendorsARAPObjectChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	TableRow = Items.PaymentToVendors.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		FillPropertyValues(TableRow, ValueSelected);
		TableRow.Vendor = ValueSelected.Partner;
		Modified = True;
	EndIf; 
	
EndProcedure

&AtClient
Procedure PaymentToVendorsARAPCurrencyOnChange(Item)
	
	Items.PaymentToVendors.CurrentData.AmountARAP = 0;
	Items.PaymentToVendors.CurrentData.ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOtherExpenses

&AtClient
Procedure OtherExpensesSelection(Item, RowSelected, Field, StandardProcessing)
	
	TicketFields = New Array;
	TicketFields.Add("OtherExpensesLineNumber");
	TicketFields.Add("OtherExpensesIncomingDocumentNumber");
	TicketFields.Add("OtherExpensesIncomingDocumentDate");
	TicketFields.Add("OtherExpensesExternalDocumentName");
	TicketFields.Add("OtherExpensesContent");
	TicketFields.Add("OtherExpensesSum");
	TicketFields.Add("OtherExpensesCurrency");
	TicketFields.Add("OtherExpensesCashFlowItem");
	
	If TicketFields.Find(Field.Name) <> Undefined Then
		
		TSRow = Object.OtherExpenses.FindByID(RowSelected);
		
		If ValueIsFilled(TSRow.ElectronicTicket) Then
			FormParameters = New Structure;
			FormParameters.Insert("Key", TSRow.ElectronicTicket);
			OpenForm("Document.ElectronicTicketTransaction.ObjectForm", FormParameters, ThisObject);
			StandardProcessing = False;
		EndIf;
	EndIf;
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.OtherExpenses.CurrentData;
	
	If NewRow Then
		If Copy Then
			GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
		Else
			CurrentData.Department = Object.Department;
			CurrentData.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.OtherExpenses");
		EndIf;
	EndIf;
	
	
EndProcedure

&AtClient
Procedure OtherExpensesOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.OtherExpenses.CurrentData;
	If Not Object.Multicurrency And Not CurrentData = Undefined Then
		CurrentData.Currency = Object.Currency;
	EndIf;
	CalculateDocumentAmount(ThisObject);
	
EndProcedure

&AtClient
Procedure OtherExpensesAfterDeleteRow(Item)
	
	CalculateDocumentAmount(ThisObject);
	
EndProcedure

&AtServer
Procedure OtherExpensesExpenseItemOnChangeServer(TagName);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	
EndProcedure

&AtClient
Procedure OtherExpensesExpenseItemOnChange(Item)
	
	OtherExpensesExpenseItemOnChangeServer(Item.Name);
	
EndProcedure

&AtClient
Procedure OtherExpensesExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesSumOnChange(Item)
	
	CurrentData = Items.OtherExpenses.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Sum",               CurrentData.Sum);
	CurrentRow.Insert("VATRate",           CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",            CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",           CurrentData.AmountIncludingVAT);
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow);
	
EndProcedure

&AtClient
Procedure OtherExpensesVATRateOnChange(Item)
	
	CurrentRow = Items.OtherExpenses.CurrentData;
	If InsignificantVATRateOnServer(CurrentRow.VATRate) Then
		CurrentRow.VATAccountingMethod = 0;
	EndIf;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure OtherExpensesVATAmountOnChange(Item)
	
	CurrentRow = Items.OtherExpenses.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure OtherExpensesVATAccountingMethodOnChange(Item)
	
	CurrentRow = Items.OtherExpenses.CurrentData;
	CurrentRow.InvIsSubmitted = (CurrentRow.VATAccountingMethod = 1);
	
EndProcedure

&AtClient
Procedure OtherExpensesVATAccountingMethodStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentRow = Object.OtherExpenses.FindByID(Items.OtherExpenses.CurrentRow);
	
	Item.ChoiceList.Clear();
	If ValueIsFilled(CurrentRow.ElectronicTicket) Then
		Item.ChoiceList.Add(0, NStr("vi = 'Ghi vào chi phí';
									|ru = 'Списать в расходы';
									|en = 'Expense as'; fa = 'هزینه به عنوان';
									|it = 'Stornare sulle spese';
									|pl = 'Spisać do rozchodów';
									|tr = 'Gider yazılacak'"));
		Item.ChoiceList.Add(2, NStr("vi = 'Khấu trừ theo quy định (hoặc chứng từ khác)';
									|ru = 'Принять к вычету по БСО (или иному документу)';
									|en = 'Accept for deduction by accountable forms (or by another document)'; fa = 'پذیرش برای کسر بر اساس فرم‌های حسابداری (یا بر اساس سند دیگر)';
									|it = 'Accetta la detrazione per moduli di segnalazioni rigorosi (o altro documento)';
									|pl = 'Przyjąć do odliczenia według BSO (lub innego dokumentu)';
									|tr = 'BSO''ya (veya başka bir belgeye) göre kesinti için kabul edin'"));
	Else
		Item.ChoiceList.Add(0, NStr("vi = 'Ghi vào chi phí';
									|ru = 'Списать в расходы';
									|en = 'Expense as'; fa = 'هزینه به عنوان';
									|it = 'Stornare sulle spese';
									|pl = 'Spisać do rozchodów';
									|tr = 'Gider yazılacak'"));
		Item.ChoiceList.Add(1, NStr("vi = 'Khấu trừ theo hóa đơn GTGT';
									|ru = 'Принять к вычету по СФ';
									|en = 'Accept for deduction'; fa = 'پذیرش برای کسر';
									|it = 'Accetta la deduzione da Fatture';
									|pl = 'Przyjąć do odliczenia według FVAT';
									|tr = 'Fatura kesintisi için kabul et'"));
		Item.ChoiceList.Add(2, NStr("vi = 'Khấu trừ theo quy định (hoặc chứng từ khác)';
									|ru = 'Принять к вычету по БСО (или иному документу)';
									|en = 'Accept for deduction by accountable forms (or by another document)'; fa = 'پذیرش برای کسر بر اساس فرم‌های حسابداری (یا بر اساس سند دیگر)';
									|it = 'Accetta la detrazione per moduli di segnalazioni rigorosi (o altro documento)';
									|pl = 'Przyjąć do odliczenia według BSO (lub innego dokumentu)';
									|tr = 'BSO''ya (veya başka bir belgeye) göre kesinti için kabul edin'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCurrencyConversion

&AtClient
Procedure CurrencyConversionCurrencyOnChange(Item)
	
	RecalculateConversionRate();
	
EndProcedure

&AtClient
Procedure CurrencyConversionSumOnChange(Item)
	
	ConversionRateOnChangeServer();
	
EndProcedure

&AtServer
Procedure ConversionRateOnChangeServer()
	
	TableRow = Object.CurrencyConversion.FindByID(Items.CurrencyConversion.CurrentRow);
	RecalculateConversionParameters(TableRow, "ConversionRate")
	
EndProcedure

&AtClient
Procedure CurrencyConversionCurrencyOfConversionOnChange(Item)
	
	RecalculateConversionRate();
	
EndProcedure

&AtClient
Procedure CurrencyConversionConversionAmountOnChange(Item)
	
	ConversionAmountWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure ConversionAmountWhenChangedOnServer()
	
	TableRow = Object.CurrencyConversion.FindByID(Items.CurrencyConversion.CurrentRow);
	RecalculateConversionParameters(TableRow, "ConversionAmount")
	
EndProcedure

&AtClient
Procedure CurrencyConversionRate_OnChange(Item)
	
	ConversionRateOnChangeServer();
	
EndProcedure

&AtClient
Procedure CurrencyConversionOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateDocumentAmount(ThisForm);
	
EndProcedure

&AtClient
Procedure CurrencyConversionAfterDeleteRow(Item)
	
	CalculateDocumentAmount(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure CheckCounterparties(Command)
	
	
	Return;
	
EndProcedure

// This procedure is used in the AutoTest of the sales process.
//
&AtClient
Procedure AutoTestFillInTheReceivedAdvances(Command) Export
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.OtherExpenses;
	Notification = New CallbackDescription("AutoTestFillInTheReceivedAdvancesCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure SelectionByStock(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	If Not Object.Multicurrency Then
		CheckParameters.CheckedAttributes.Insert("Currency", NStr("vi = 'Tiền tệ';
																	|ru = 'Валюта';
																	|en = 'Currency'; fa = 'ارز';
																	|it = 'Valuta';
																	|pl = 'Waluta';
																	|tr = 'Para birimi'"));
	EndIf;
	Notification = New CallbackDescription("SelectionBasedOnBalancesAfterVerification", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure PopulateConversion(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.CurrencyConversion;
	Notification = New CallbackDescription("PopulateConversionCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure AddATicket(Command)
	
	Filter = New Structure;
	Filter.Insert("Employee", Object.AdvanceHolder);
	Filter.Insert("Department", Object.Department);
	Filter.Insert("Organization", Object.Organization);
	Filter.Insert("ElectronicTicket", PredefinedValue("Document.ElectronicTicketTransaction.EmptyRef"));
	If Not Object.Multicurrency Then
		Filter.Insert("Currency", Object.Currency);
	EndIf;
	Filter.Insert("NoRefund", True);
	Filter.Insert("AlreadySelectedTickets",AlreadySelectedTickets());
	Filter.Insert("ExpenseReportDate", Object.Date);
	
	TicketSelectionParameters = New Structure;
	TicketSelectionParameters.Insert("Filter", Filter);
	
	OpenForm("Document.ElectronicTicketTransaction.Form.TicketChoiceForm", TicketSelectionParameters, ThisObject,,,,
		New CallbackDescription("ProcessingTicketSelection", ThisObject));
	
EndProcedure

&AtClient
Procedure ProcessingTicketSelection(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		AddLineBasedOnTicketData(Result);
	EndIf;
	
EndProcedure

&AtServer
Procedure AddLineBasedOnTicketData(TicketLink)
	
	TicketDetails = New Structure;
	TicketDetails.Insert("IncomingDocumentNumber", "TicketNumber");
	TicketDetails.Insert("IncomingDocumentDate", "Date");
	TicketDetails.Insert("ExternalDocumentName", "ServiceType");
	TicketDetails.Insert("Content", "TripDetails");
	TicketDetails.Insert("Currency");
	TicketDetails.Insert("CashFlowItem");
	TicketDetails.Insert("Counterparty", "CounterpartyCarrier");
	TicketDetails.Insert("Department", "Department");
	
	TicketAttributeValues = Common.ObjectAttributesValues(TicketLink, TicketDetails);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ETicketData.VATRate AS VATRate,
	|	SUM(ETicketData.VATAmount) AS VATAmount,
	|	SUM(ETicketData.Sum) AS Sum
	|FROM
	|	(SELECT
	|		Operations.VATRate AS VATRate,
	|		CASE
	|			WHEN Operations.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -Operations.VATAmount
	|			ELSE Operations.VATAmount
	|		END AS VATAmount,
	|		CASE
	|			WHEN Operations.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -Operations.Sum
	|			ELSE Operations.Sum
	|		END AS Sum
	|	FROM
	|		Document.ElectronicTicketTransaction.Operations AS Operations
	|	WHERE
	|		Operations.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Operations.VATRate,
	|		CASE
	|			WHEN Operations.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -Operations.VATAmount
	|			ELSE Operations.VATAmount
	|		END,
	|		CASE
	|			WHEN Operations.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|				THEN -Operations.Sum
	|			ELSE Operations.Sum
	|		END
	|	FROM
	|		Document.ElectronicTicketTransaction.Operations AS Operations
	|	WHERE
	|		Operations.Ref.ElectronicTicket = &Ref
	|		AND NOT Operations.Ref.DeletionMark) AS ETicketData
	|
	|GROUP BY
	|	ETicketData.VATRate
	|
	|HAVING
	|	SUM(ETicketData.Sum) > 0";
	
	Query.SetParameter("Ref", TicketLink);
	Operations = Query.Execute().Unload();
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	RowsToProcess = New Array();
	
	For Each Operation In Operations Do
		TSRow = Object.OtherExpenses.Add();
		TSRow.ElectronicTicket = TicketLink;
		FillPropertyValues(TSRow, TicketAttributeValues);
		TSRow.VATRate = Operation.VATRate;
		TSRow.VATAmount = Operation.VATAmount;
		TSRow.Sum = Operation.Sum;
		
		
		RowsToProcess.Add(TSRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.OtherExpenses,
		CachedValues);
	
EndProcedure

&AtClient
Procedure FillInTheDepartment(Command)
	
	If ThereAreNoLinesOfOtherExpenses() Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Department", Object.Department);
	OpenForm("Catalog.BusinessStructure.ChoiceForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure FillInExpenseAssetItem(Command)
	
	If ThereAreNoLinesOfOtherExpenses() Then
		Return;
	EndIf;
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject, Items.OtherExpensesExpenseItem, Items.OtherExpenses.SelectedRows);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.OtherExpenses;
	TableData = Object.OtherExpenses;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.Insert("FieldNameQuantity", "Sum");
	StringSplittingParameters.Insert("Title", NStr("vi = 'Nhập số tiền vào một dòng mới';
													|ru = 'Введите сумму в новой строке';
													|en = 'Enter amount in a new line'; fa = 'Enter amount in a new line';
													|it = 'Inserire importo nella nuova riga';
													|pl = 'Wprowadź kwotę w nowym wierszu';
													|tr = 'Tutarı yeni satırda giriniz'"));
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export
	
	CurrentRow = Items.OtherExpenses.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure TransferLineToPaymentsToSuppliers(Command)
	
	CurrentData = Items.OtherExpenses.CurrentData;
	If CurrentData <> Undefined Then
		NewRow = Object.PaymentToVendors.Add();
		FillPropertyValues(NewRow, CurrentData,, "LineNumber");
		Object.OtherExpenses.Delete(Object.OtherExpenses.IndexOf(CurrentData));
	EndIf;
	
EndProcedure

&AtClient
Procedure TransferLineToExpenses(Command)
	
	CurrentData = Items.PaymentToVendors.CurrentData;
	If CurrentData <> Undefined Then
		NewRow = Object.OtherExpenses.Add();
		FillPropertyValues(NewRow, CurrentData, , "LineNumber");
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, NewRow, "Object.OtherExpenses");
		Object.PaymentToVendors.Delete(Object.PaymentToVendors.IndexOf(CurrentData));
	EndIf;
	
EndProcedure

&AtClient
Procedure PurchasingSelect(Command)
	
	PickingParameters = New Structure("AdvanceHolder, Organization, Department, Multicurrency");
	FillPropertyValues(PickingParameters, Object);
	PickingParameters.Insert("Currency", ?(Object.Multicurrency, Undefined, Object.Currency));
	PickingParameters.Insert("AmountReceived", CurrencyTotalsTable.Total("ReceivedEmails"));
	PickingParameters.Insert("AmountExpensed", CurrencyTotalsTable.Total("Spent") + CurrencyTotalsTable.Total("PurchaseAmount_3"));
	PickingParameters.Insert("PurchasingDocumentsList", PurchasingDocumentsList);
	PickingParameters.Insert("DocumentReference", Object.Ref);
	PickingParameters.Insert("ExpenseReportDate", Object.Date);
	
	OpenForm("Document.ExpenseReport.Form.SelectPurchaseDocuments",
		PickingParameters,
		ThisForm,,,,
		New CallbackDescription("PurchasingSelectCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure PurchasingSelectCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined And IsTempStorageURL(Result) Then
		ProcessingSelectionOfPurchaseDocuments(Result);
		CalculateDocumentAmount(ThisForm);
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfPurchaseDocuments(AddressInStorage)
	
	PurchasingDocumentsList.LoadValues(GetFromTempStorage(AddressInStorage));
	UpdatePurchaseDocuments();
	
EndProcedure

&AtClient
Procedure PurchasingDelete(Command)
	
	SelectedDocuments_ = New Array;
	If Items.PurchaseDocumentsAll.SelectedRows.Count() Then
		For Each SelectedRow In Items.PurchaseDocumentsAll.SelectedRows Do
			SelectedDocuments_.Add(Items.PurchaseDocumentsAll.RowData(SelectedRow).DocumentPurchases);
		EndDo;
		DeletePurchaseDocumentsFromList(SelectedDocuments_);
		Modified = True;
	EndIf;
	
	CalculateDocumentAmount(ThisForm);
	
EndProcedure

&AtServer
Procedure DeletePurchaseDocumentsFromList(DocumentsToDelete)
	
	SelectedDocuments = TMCommonUse.DeleteDuplicateElementsFromArray(PurchasingDocumentsList.UnloadValues());
	
	For Each DocumentForDeletion In DocumentsToDelete Do
		ElementIndex = SelectedDocuments.Find(DocumentForDeletion);
		If ElementIndex <> Undefined Then
			SelectedDocuments.Delete(ElementIndex);
		EndIf;
	EndDo;
	
	PurchasingDocumentsList.LoadValues(SelectedDocuments);
	
	UpdatePurchaseDocuments();
	
EndProcedure

&AtClient
Procedure PurchasingCreate(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("Organization", Object.Organization);
	FillingValues.Insert("AdvanceHolder", Object.AdvanceHolder);
	FillingValues.Insert("Department", Object.Department);
	FillingValues.Insert("BusinessOperation",
		PredefinedValue("Enum.BusinessTransactions.PurchaseViaAdvanceHolder"));
	
	CreationParameters = New Structure;
	CreationParameters.Insert("DocumentName", "VendorInvoice");
	CreationParameters.Insert("FillingValues", FillingValues);
	
	HowToCreateQuestionDocument(CreationParameters);
	
EndProcedure

&AtClient
Procedure HowToCreateAnETicket(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("Organization", Object.Organization);
	FillingValues.Insert("AdvanceHolder", Object.AdvanceHolder);
	FillingValues.Insert("Department", Object.Department);
	FillingValues.Insert("BusinessOperation",
		PredefinedValue("Enum.BusinessTransactions.BookingViaAdvanceHolder"));
	
	CreationParameters = New Structure;
	CreationParameters.Insert("DocumentName", "ElectronicTicketTransaction");
	CreationParameters.Insert("FillingValues", FillingValues);
	
	HowToCreateQuestionDocument(CreationParameters);
	
EndProcedure

&AtClient
Procedure HowToCreateQuestionDocument(AdditionalParameters)
	
	Handler = New CallbackDescription("HowToCreateCompletionDocument", ThisObject, AdditionalParameters);
	
	If Object.Ref.IsEmpty() Then
		QueryText = NStr("vi = 'Giấy thanh toán tiền tạm ứng chưa được ghi lại.
			|Việc tạo chứng từ mua hàng chỉ có thể được thực hiện sau khi Giấy thanh toán tiền tạm ứng đã được ghi lại.
			|Dữ liệu sẽ được ghi lại.';
			|ru = 'Авансовый отчет еще не записан.
			|Создание документа закупки возможно только после записи авансового отчета.
			|Данные будут записаны.';
			|en = 'The expense report is not recorded yet.
			|You can create the purchase document only after recording the expense report.
			|Data will be recorded.'; fa = 'The expense report is not recorded yet.
			|You can create the purchase document only after recording the expense report.
			|Data will be recorded.';
			|it = 'Nota spese non è ancora stata salvata. 
			| Creazione del documento di acquisto è possibile solo dopo il salvataggio della nota spese.
			| I dati saranno salvati.';
			|pl = 'Raport zaliczkowy nie został jeszcze zarejestrowany.
			|Utworzenie dokumentu zamówienia jest możliwe dopiero po zarejestrowaniu raportu zaliczkowego.
			|Dane zostaną zapisane.';
			|tr = 'Gider raporu henüz kaydedilmedi.
			|Satın alma belgesi oluşturmak ancak gider raporu kaydedildikten sonra mümkündür.
			|Veriler kaydedilecektir.'");
		ShowQueryBox(Handler, QueryText, QuestionDialogMode.OKCancel);
	Else
		RunCallback(Handler, DialogReturnCode.Ignore);
	EndIf;
	
EndProcedure

&AtClient
Procedure HowToCreateCompletionDocument(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.OK Then
		Write();
	ElsIf Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	FillingValues = AdditionalParameters.FillingValues;
	FillingValues.Insert("ExpenseReport", Object.Ref);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	
	OpenForm("Document." + AdditionalParameters.DocumentName + ".ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure PurchasesCreateTrafficRules(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure UploadCashierSChecks(Command)
	
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function ThereAreNoLinesOfOtherExpenses()
	
	SelectedRows = Items.OtherExpenses.SelectedRows;
	
	If Object.OtherExpenses.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Trong danh sách ""Chi phí"" chưa điền dòng nào.';
								|ru = 'В список ""Расходы"" не введено ни одной строки.';
								|en = 'No lines entered in the ""Expenses"" list.'; fa = 'No lines entered in the ""Expenses"" list.';
								|it = 'Nell''elenco ""Spese"" non è stata immessa alcuna riga.';
								|pl = 'Do listy ""Wydatki"" nie wprowadzono ani jednego wiersza.';
								|tr = '""Giderler"" listesine hiçbir satır girilmemiştir.'"));
		Return True;
	ElsIf SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Trong danh sách ""Chi phí"" chưa chọn dòng nào.';
								|ru = 'В списке ""Расходы"" не выделено ни одной строки.';
								|en = 'No line is selected in the ""Expenses"" list.'; fa = 'No line is selected in the ""Expenses"" list.';
								|it = 'Nell''elenco ""Spese"" non è stata selezionata nessuna riga.';
								|pl = 'W liście ""Расходы"" nie wybrano ani jednego wiersza.';
								|tr = '""Giderler"" listesinde satır seçilmemiş.'"));
		Return True
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Procedure MoveDateOfDocument(WriteParameters, CurrentObject)
	
	If Not WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		Return;
	EndIf;

	If ValueIsFilled(CurrentObject.Ref) Then
		Return;
	EndIf;
	
	If CurrentObject.Date = EndOfDay(CurrentObject.Date) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Date",CurrentObject.Date);
	Query.SetParameter("Organization",CurrentObject.Organization);
	Query.SetParameter("Department",CurrentObject.Department);
	Query.SetParameter("AdvanceHolder",CurrentObject.AdvanceHolder);
	
	Query.Text = 
	"SELECT TOP 1
	|	Document.Ref AS Ref
	|FROM
	|	Document.ExpenseReport AS Document
	|WHERE	
	|Document.Posted
	|	AND Document.Organization = &Organization
	|	AND Document.Department = &Department
	|	AND Document.AdvanceHolder = &AdvanceHolder
	|	AND Document.Date = &Date";
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Object.Date = Object.Date + 1;
		CurrentObject.Date = CurrentObject.Date + 1;
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//

	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm, "OtherExpensesAmountIncludingVAT");
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesCounterparty.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.VATRates.EXCLUDINGVAT;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ExpenseReportStatuses.Upholded;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	OrdersServer.SetAppearanceOfCanceledLine(ConditionalAppearance,
		Items.OtherExpenses,
		Items.OtherExpensesRejected.Name,
		Items.OtherExpensesReasonForRejection.Name);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesReasonForRejection.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.CancellationReason");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Black);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesDepartment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesVATRate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesVATAmount.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesAmountIncludingVAT.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesVATAccountingMethod.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesInvoice.Name);
	ItemField = Item.Fields.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ExpenseReportStatuses.Upholded;
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CurrencyConversionRate_.Name);
	
	Item.Appearance.SetParameterValue("Text", "");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesVATAccountingMethod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.VATAccountingMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi vào chi phí';
													|ru = 'Списать в расходы';
													|en = 'Expense as'; fa = 'هزینه به عنوان';
													|it = 'Stornare sulle spese';
													|pl = 'Spisać do rozchodów';
													|tr = 'Gider yazılacak'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesVATAccountingMethod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.VATAccountingMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Khấu trừ theo hóa đơn';
													|ru = 'Принять к вычету по СФ';
													|en = 'Accept for deduction'; fa = 'پذیرش برای کسر';
													|it = 'Accetta la deduzione da Fatture';
													|pl = 'Przyjąć do odliczenia według FVAT';
													|tr = 'Fatura kesintisi için kabul et'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesVATAccountingMethod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	RightValue = VATAccountingERPInternalClientServerCached.ListOfInsignificantBets();
	RightValue.Add(Catalogs.VATRates.EmptyRef());
	ItemFilter.RightValue = RightValue;
	
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("Enabled", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesInvoice.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.VATAccountingMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("Enabled", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesInvoice.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.VATAccountingMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Enabled", True);
	
	// Other document
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesOtherDocument.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.VATAccountingMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 2;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.TaxInvoice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Invoice
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesInvoice.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.VATAccountingMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.TaxInvoice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.VATAccountingMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.Counterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesInvoice.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup1 = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.InvoiceNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.InvoiceDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	FilterGroup2 = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.InvoiceNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.InvoiceDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	// E-ticket
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OtherExpensesIncomingDocumentNumber.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OtherExpensesIncomingDocumentDate.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OtherExpensesExternalDocumentName.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OtherExpensesContent.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OtherExpensesSum.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OtherExpensesCurrency.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OtherExpensesCashFlowItem.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OtherExpensesVATRate.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OtherExpensesVATAmount.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OtherExpensesCounterparty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.ElectronicTicket");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// VATAmount
	Item = ConditionalAppearance.Items.Add();
	
	Fields = Item.Fields.Items;
	ItemField = Fields.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesVATAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	
	RatesWithoutVAT = VATAccountingERPInternalClientServerCached.ListOfInsignificantBets();
	RatesWithoutVAT.Add(Catalogs.VATRates.EmptyRef());
	
	ItemFilter.RightValue = RatesWithoutVAT;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	CurrencyOfComplianceAccounting                             = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	UseMultipleCurrencies                  = GetFunctionalOption("UseMultipleCurrencies");
	UseExpenseReportStatuses         = GetFunctionalOption("UseExpenseReportStatuses");
	ControlIssueOfCashByPurposes   = GetFunctionalOption("ControlIssueOfCashByPurposes");
	StartDateOfPrintingSingleExpenseReport     = Constants.StartDateOfPrintingSingleExpenseReport.Get();
	SingleExpenseReportUnconditionally              = Not Constants.VisibilityOfStartDateOfPrintingSingleExpenseReport.Get();
	DefinePrintingSingleAdvanceReport();
	
	If UseExpenseReportStatuses Then
		ConfirmationRight = UserRightsCached.ApprovalOfExpenseReports();
	Else
		ConfirmationRight = True;
	EndIf;
	
	CurrentCurrency = Object.Currency;
	MultipleCurrencies = Number(Object.Multicurrency);
	If MultipleCurrencies Then
		For Each TableRow In Object.CurrencyConversion Do
			Items.CurrencyConversion.CurrentRow = TableRow.GetID();
			GenerateCourseInText();
		EndDo;
	EndIf;
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.OtherExpensesExpenseItem.Title = NStr("vi = 'Dạng chi phí';
													|ru = 'Статья расходов';
													|en = 'Expense item'; fa = 'قلم هزینه';
													|it = 'Voce di spese';
													|pl = 'Rodzaj kosztu';
													|tr = 'Gider kalemi'");
	EndIf;
	
	Items.OtherExpensesVATGroup.Visible = GetFunctionalOption("UseVATAccounting");
	
	If Not AccessRight("Edit", Metadata.Documents.ExpenseReport) Then
		Items.OneCurrency.Enabled = False;
		Items.MultipleCurrencies.Enabled = False;
	EndIf;
	
	InitializeVATMethod();
	FillInSelectionListVATMethod();
	
	If ValueIsFilled(Object.Ref) Then
		PurchasingDocumentsList.LoadValues(Documents.ExpenseReport.PurchasingDocumentsList(Object.Ref));
	EndIf;
	UpdatePurchaseDocuments();
	
	FillInAmountReceived();
	CalculateDocumentAmount(ThisObject);
	
	UpdatePurchaseForActivity(False);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializeVATMethod()
	
	For Each TableRow In Object.OtherExpenses Do
		If TableRow.InvIsSubmitted Then
			TableRow.VATAccountingMethod = 1;
		Else
			TableRow.VATAccountingMethod = 0;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInSelectionListVATMethod()
	
	SelectionListVATMethod = Items.OtherExpensesVATAccountingMethod.ChoiceList;
	SelectionListVATMethod.Clear();
	SelectionListVATMethod.Add(0, NStr("vi = 'Ghi vào chi phí';
										|ru = 'Списать в расходы';
										|en = 'Expense as'; fa = 'هزینه به عنوان';
										|it = 'Stornare sulle spese';
										|pl = 'Spisać do rozchodów';
										|tr = 'Gider yazılacak'"));
	SelectionListVATMethod.Add(1, NStr("vi = 'Cần tiếp nhận vào khấu trừ';
										|ru = 'Принять к вычету';
										|en = 'Accept for deduction'; fa = 'پذیرش برای کسر';
										|it = 'Accettare per la detrazione';
										|pl = 'Przyjąć do odliczenia';
										|tr = 'Çıkarmaya kabul et'"));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("UseMultipleCurrencies");
	FormAttributes.Insert("PrintASingleExpenseReport");
	FormAttributes.Insert("UseExpenseReportStatuses");
	FormAttributes.Insert("ControlIssueOfCashByPurposes");
	FormAttributes.Insert("MultiCurrencyBasement");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateDocumentAmount(Form)
	
	Object = Form.Object;
	
	CurrencyTotals = New Map;
	IssuanceObjectives = New Map;
	IssuancePurpose     = PredefinedValue("Catalog.CashFlowReportItems.EmptyRef");
	
	For Each TSRow In Form.CurrencyTotalsTable Do
		
		If Form.ControlIssueOfCashByPurposes Then
			IssuancePurpose = TSRow.IssuancePurpose;
			IssuanceObjectives.Insert(IssuancePurpose);
		EndIf;
		
		If TSRow.ReceivedEmails <> 0 Then
			
			AddAmountToTotalsByCurrency(CurrencyTotals,
			                             TSRow.Currency,
			                             IssuancePurpose,
			                             TSRow.ReceivedEmails,
			                             "ReceivedEmails");
		
		EndIf;
		If TSRow.PurchaseAmount_3 <> 0 Then
			
			AddAmountToTotalsByCurrency(CurrencyTotals,
			                             TSRow.Currency,
			                             IssuancePurpose,
			                             TSRow.PurchaseAmount_3,
			                             "Spent");
			
			AddAmountToTotalsByCurrency(CurrencyTotals,
			                             TSRow.Currency,
			                             IssuancePurpose,
			                             TSRow.PurchaseAmount_3,
			                             "PurchaseAmount_3");
			
		EndIf;
		
		AddAmountToTotalsByCurrency(CurrencyTotals,
		                             TSRow.Currency,
		                             IssuancePurpose,
		                             TSRow.Returned,
		                             "Spent");
		
		AddAmountToTotalsByCurrency(CurrencyTotals,
		                             TSRow.Currency,
		                             IssuancePurpose,
		                             TSRow.Returned,
		                             "Returned");
		
		AddAmountToTotalsByCurrency(CurrencyTotals,
		                             TSRow.Currency,
		                             IssuancePurpose,
		                             TSRow.OpeningBalance,
		                             "OpeningBalance");
		
		AddAmountToTotalsByCurrency(CurrencyTotals,
		                             TSRow.Currency,
		                             IssuancePurpose,
		                             TSRow.InitialOverExpenditure,
		                             "InitialOverExpenditure");
	
	EndDo;
	
	For Each TSRow In Object.OtherExpenses Do
		
		If Form.ControlIssueOfCashByPurposes Then
			IssuancePurpose = TSRow.CashFlowItem;
			IssuanceObjectives.Insert(IssuancePurpose);
		EndIf;
		
		If TSRow.Canceled Then
			
			AddAmountToTotalsByCurrency(CurrencyTotals,
			                             ?(Form.Object.Multicurrency,TSRow.Currency,Form.Object.Currency),
			                             IssuancePurpose,
			                             TSRow.Sum + ?(Form.Object.PriceIncludesVAT,0,TSRow.VATAmount),
			                             "TurnDown");
		
		Else
			
			AddAmountToTotalsByCurrency(CurrencyTotals,
			                             ?(Form.Object.Multicurrency,
			                             TSRow.Currency,Form.Object.Currency),
			                             IssuancePurpose,
			                             TSRow.Sum + ?(Form.Object.PriceIncludesVAT,0,TSRow.VATAmount),
			                             "Spent");
		
		EndIf;
		
	EndDo;
	
	For Each TSRow In Object.PaymentToVendors Do
		
		If Form.ControlIssueOfCashByPurposes Then
			IssuancePurpose = TSRow.CashFlowItem;
			IssuanceObjectives.Insert(IssuancePurpose);
		EndIf;
		
		AddAmountToTotalsByCurrency(CurrencyTotals,
		                             TSRow.Currency,
		                             IssuancePurpose,
		                             TSRow.Sum,
		                             "Spent");
		
	EndDo;
	
	For Each TSRow In Object.CurrencyConversion Do
		
		If Form.ControlIssueOfCashByPurposes Then
			IssuancePurpose = TSRow.CashFlowItem;
			IssuanceObjectives.Insert(IssuancePurpose);
		EndIf;
		
		AddAmountToTotalsByCurrency(CurrencyTotals,
		                             TSRow.Currency,
		                             IssuancePurpose,
		                             -TSRow.Sum,
		                             "Converted");
		
		AddAmountToTotalsByCurrency(CurrencyTotals,
		                             TSRow.CurrencyOfConversion,
		                             IssuancePurpose,
		                             TSRow.ConversionAmount,
		                             "Converted");
		
	EndDo;
	
	Form.OutputIssuanceObjectives = IssuanceObjectives.Count() > 1;
	CurrencyRowsThatAreBeingDeleted = New Array;
	
	For Each KeyAndValueCurrency In CurrencyTotals Do
		
		LinesToDelete = New Array;
		
		For Each KeyAndValue In KeyAndValueCurrency.Value Do
		
			TotalsLine = KeyAndValue.Value;
			InTotal = TotalsLine.OpeningBalance 
				- TotalsLine.InitialOverExpenditure
				+ TotalsLine.ReceivedEmails
				+ TotalsLine.Converted
				- TotalsLine.Spent;
			If InTotal < 0 Then
				TotalsLine.overspending = -InTotal;
				TotalsLine.Balance = 0;
			Else
				TotalsLine.overspending = 0;
				TotalsLine.Balance = InTotal;
			EndIf;
			DeleteRow = True;
			For Each KeyAndValueTotals In TotalsLine Do
				If KeyAndValueTotals.Value <> 0 Then
					DeleteRow = False;
					Break;
				EndIf;
			EndDo;
			If DeleteRow Then
				LinesToDelete.Add(KeyAndValue.Key);
			EndIf;
			
		EndDo;
		
		For Each RowToDelete In LinesToDelete Do
			KeyAndValueCurrency.Value.Delete(RowToDelete);
		EndDo;
		
		If Not KeyAndValueCurrency.Value.Count() Then
			CurrencyRowsThatAreBeingDeleted.Add(KeyAndValueCurrency.Key);
		EndIf;
		
	EndDo;
	
	For Each RowToDelete In CurrencyRowsThatAreBeingDeleted Do
		CurrencyTotals.Delete(RowToDelete);
	EndDo;
	
	Form.CurrencyTotalsTable.Clear();
	For Each KeyAndValueCurrency In CurrencyTotals Do
		
		For Each KeyAndValue In KeyAndValueCurrency.Value Do
	
			NewRow = Form.CurrencyTotalsTable.Add();
			NewRow.Currency     = KeyAndValueCurrency.Key;
			NewRow.IssuancePurpose = KeyAndValue.Key;
		
			If Form.OutputIssuanceObjectives Then
				KeyAndValue.Value.OpeningBalance = KeyAndValue.Value.OpeningBalance - KeyAndValue.Value.InitialOverExpenditure;
				KeyAndValue.Value.InitialOverExpenditure = 0;
				KeyAndValue.Value.Balance = KeyAndValue.Value.Balance - KeyAndValue.Value.overspending;
				KeyAndValue.Value.overspending = 0;
			EndIf;
			
			FillPropertyValues(NewRow, KeyAndValue.Value);
	
		EndDo;
		
	EndDo;
	
	Form.MultiCurrencyBasement = CurrencyTotals.Count() > 1
	                             Or Object.Multicurrency
	                             Or Form.OutputIssuanceObjectives;
	
	If Not Form.Object.Multicurrency Then
		Object.AmountExpensed = 0;
		Object.AmountRejected = 0;
		Form.AmountReceived = 0;
		
		For Each Page1 In Form.CurrencyTotalsTable Do
			Form.AmountReceived = Form.AmountReceived + Page1.ReceivedEmails;
			Object.AmountRejected = Object.AmountRejected + Page1.TurnDown;
			Object.AmountExpensed = Object.AmountExpensed + Page1.Spent;
		EndDo;
	EndIf;
	
	If Not Form.MultiCurrencyBasement Then
		If Form.CurrencyTotalsTable.Count() = 1 Then
			Form.BalanceOverspend = ?(Form.CurrencyTotalsTable[0].Balance > 0,Form.CurrencyTotalsTable[0].Balance,Form.CurrencyTotalsTable[0].overspending);
			Form.OpeningBalanceOverExpenditure = ?(Form.CurrencyTotalsTable[0].OpeningBalance > 0,Form.CurrencyTotalsTable[0].OpeningBalance,Form.CurrencyTotalsTable[0].InitialOverExpenditure);
		Else
			Form.BalanceOverspend = 0;
			Form.OpeningBalanceOverExpenditure = 0;
		EndIf;
		
		If Form.CurrencyTotalsTable.Count() > 0
			And Form.CurrencyTotalsTable[0].overspending > 0 Then
			Form.Items.BalanceOverspend.Title = NStr("vi = 'Chi quá';
													|ru = 'Перерасход';
													|en = 'Over-expenditure'; fa = 'هزینه مازاد';
													|it = 'Eccesso di spesa';
													|pl = 'Over-expenditure';
													|tr = 'Fazla harcama'");
		Else
			Form.Items.BalanceOverspend.Title = NStr("vi = 'Số dư';
													|ru = 'Остаток';
													|en = 'Balance'; fa = 'مانده';
													|it = 'Rimanenze';
													|pl = 'Balance';
													|tr = 'Bakiye'");
		EndIf;
		
		If Form.CurrencyTotalsTable.Count() > 0
			And Form.CurrencyTotalsTable[0].InitialOverExpenditure > 0 Then
			Form.Items.OpeningBalanceOverExpenditure.Title = NStr("vi = 'Bội chi đầu';
																	|ru = 'Начальный перерасход';
																	|en = 'Opening over-expenditure'; fa = 'مازاد هزینه‌کرد افتتاحیه';
																	|it = 'Начальный перерасход';
																	|pl = 'Opening over-expenditure';
																	|tr = 'İlk fazla harcama'");
		Else
			Form.Items.OpeningBalanceOverExpenditure.Title = NStr("vi = 'Dư đầu';
																	|ru = 'Начальный остаток';
																	|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
																	|it = 'Начальный остаток';
																	|pl = 'Saldo początkowe';
																	|tr = 'Açılış bakiyesi'");
		EndIf;
	Else
		
		Form.MulticurrencyAmounts = RowMultiCurrencyAmounts(CurrencyTotals);
		
		Form.Items.CurrencyTotalsTableInitialOverExpenditure.Visible = Not Form.OutputIssuanceObjectives;
		Form.Items.CurrencyTotalsTableoverspending.Visible          = Not Form.OutputIssuanceObjectives;
		Form.Items.CurrencyTotalsTableIssuancePurpose.Visible          = Form.OutputIssuanceObjectives;
		Form.Items.CurrencyTotalsTableOpeningBalance.Title = ?(Form.OutputIssuanceObjectives,
		                                                                NStr("vi = 'Số dư đầu / bội chi đầu';
																			|ru = 'Начальный остаток / перерасход';
																			|en = 'Opening balance / over-expenditure'; fa = 'Opening balance / over-expenditure';
																			|it = 'Opening balance / over-expenditure';
																			|pl = 'Opening balance / over-expenditure';
																			|tr = 'Açılış bakiyesi / yeniden taşıma'"),
		                                                                NStr("vi = 'Số dư đầu';
																			|ru = 'Начальный остаток';
																			|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
																			|it = 'Saldo iniziale';
																			|pl = 'Saldo początkowe';
																			|tr = 'Açılış bakiyesi'"));
		Form.Items.CurrencyTotalsTableBalance.Title          = ?(Form.OutputIssuanceObjectives,
		                                                                NStr("vi = 'Số dư / bội chi';
																			|ru = 'Остаток / перерасход';
																			|en = 'Balance / over-expenditure'; fa = 'Balance / over-expenditure';
																			|it = 'Balance / over-expenditure';
																			|pl = 'Balance / over-expenditure';
																			|tr = 'Bakiye / Fazla Harcama'"),
		                                                                NStr("vi = 'Số dư';
																			|ru = 'Остаток';
																			|en = 'Balance'; fa = 'مانده';
																			|it = 'Balance';
																			|pl = 'Balance';
																			|tr = 'Bakiye'"));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConversionOfDocumentAmountsIntoCurrencyServer()
	
	StructureOfNewCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.Currency, Object.Date, CurrencyOfComplianceAccounting);
	
	For Each TableRow In Object.OtherExpenses Do
		StructureOfCurExchangeRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(TableRow.Currency, Object.Date, CurrencyOfComplianceAccounting);
		
		TableRow.Sum = ProcessingOfExchangeRatesTM.ConvertAtRate(
			TableRow.Sum, StructureOfCurExchangeRates, StructureOfNewCurrencyRates);
		
		TableRow.VATAmount = PriceManagementSystemClientServer.CalculateVATAmount(TableRow.Sum, TableRow.VATRate, Object.PriceIncludesVAT);
		TableRow.AmountIncludingVAT = TableRow.Sum + ?(Object.PriceIncludesVAT, 0, TableRow.VATAmount);
		TableRow.Currency = Object.Currency;
	EndDo;
	
	For Each TableRow In Object.PaymentToVendors Do
		StructureOfCurExchangeRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(TableRow.Currency, Object.Date, CurrencyOfComplianceAccounting);
		TableRow.Sum = ProcessingOfExchangeRatesTM.ConvertAtRate(
			TableRow.Sum, StructureOfCurExchangeRates, StructureOfNewCurrencyRates);
		TableRow.Currency = Object.Currency;
	EndDo;
	
	CurrencyOnChangeServer();
	
EndProcedure

&AtServerNoContext
Function GetPartnerSDefaultCounterparty(Partner)
	
	Return PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Partner);
	
EndFunction

&AtClientAtServerNoContext
Function ParametersForConvertingAmountOfNDSVToTS(Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	
	Return StructureOfRecalculationOfAmount;
	
EndFunction

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure FillInAmountReceived()
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("AdvanceHolder", Object.AdvanceHolder);
	Query.SetParameter("Department", Object.Department);
	Query.SetParameter("Date", ?(ValueIsFilled(Object.Date),Object.Date,CurrentSessionDate()));
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("DocumentsArray", ?(ValueIsFilled(Object.Ref),CommonClientServer.ValueInArray(Object.Ref),New Array));
	
	Query.Text = Documents.ExpenseReport.QueryTextExpenseReportData(Query, "HeaderData_")
	+ "
	|SELECT
	|	SUM(HeaderData_.OpeningBalance) AS OpeningBalance,
	|	SUM(HeaderData_.InitialOverExpenditure) AS InitialOverExpenditure,
	|	SUM(HeaderData_.AmountIssuedInCash + HeaderData_.AmountIssuedByCard) AS ReceivedEmails,
	|	SUM(HeaderData_.AmountReturned) AS Returned,
	|	HeaderData_.IssuancePurpose AS IssuancePurpose,
	|	HeaderData_.Currency AS Currency
	|FROM HeaderData_ AS HeaderData_
	|GROUP BY
	|	HeaderData_.Currency,
	|	HeaderData_.IssuancePurpose
	|";
	
	SampleReceived = Query.Execute().Select();
	
	Table = FormAttributeToValue("CurrencyTotalsTable");
	ArrayOfExcludedColumns = CommonClientServer.ArrayOfValues("PurchaseAmount_3","Currency","Rate","Stretching");
	ArrayOfExcludedColumns.Add("IssuancePurpose");
	For Each TableColumn2 In Table.Columns Do
		If ArrayOfExcludedColumns.Find(TableColumn2.Name)= Undefined Then
			Table.FillValues(0, TableColumn2.Name);
		EndIf;
	EndDo;
		
	While SampleReceived.Next() Do
		TotalByCurrencyLine = Table.Add();
		TotalByCurrencyLine.Currency = SampleReceived.Currency;
		TotalByCurrencyLine.ReceivedEmails = SampleReceived.ReceivedEmails;
		TotalByCurrencyLine.Returned = SampleReceived.Returned;
		TotalByCurrencyLine.OpeningBalance = SampleReceived.OpeningBalance;
		TotalByCurrencyLine.InitialOverExpenditure = SampleReceived.InitialOverExpenditure;
		TotalByCurrencyLine.IssuancePurpose = SampleReceived.IssuancePurpose;
	EndDo;
	
	Table.GroupBy("Currency, IssuancePurpose, Rate, Stretching",
	                 "OpeningBalance, InitialOverExpenditure, ReceivedEmails, Returned, Spent, overspending, TurnDown, Balance, Converted, PurchaseAmount_3");
	ValueToFormAttribute(Table, "CurrencyTotalsTable");
	
	MultiCurrencyBasement = CurrencyTotalsTable.Count() > 1 Or Object.Multicurrency;
	
EndProcedure

&AtServer
Procedure UpdatePurchaseDocuments()
	
	PurchaseDocumentsAll.Parameters.SetParameterValue("PurchasingDocumentsList", PurchasingDocumentsList);
	
	//PurchasingDocumentsNumber
	QueryText = "SELECT COUNT(*) AS PurchasingDocumentsNumber FROM (" + PurchaseDocumentsAll.QueryText + ") AS Data"; //@query-part
	Query = New Query(QueryText);
	
	For Each QueryParameter In PurchaseDocumentsAll.Parameters.Items Do
		Query.SetParameter(String(QueryParameter.Parameter), QueryParameter.Value);
	EndDo;
	
	Selection = Query.Execute().Select();
	Selection.Next();
	PurchasingDocumentsNumber = Selection.PurchasingDocumentsNumber;
	
	//Totals
	QueryText = 
	"SELECT
	|	SUM(Data.Sum),
	|	Data.Currency AS Currency,
	|	Data.CashFlowItem AS IssuancePurpose
	|FROM 
	|	&PurchaseDocumentsAll AS Data
	|GROUP BY
	|	Data.Currency,
	|	Data.CashFlowItem";
	QueryText = StrReplace(QueryText, "&PurchaseDocumentsAll", StrTemplate("(%1)", PurchaseDocumentsAll.QueryText));
		
	Query = New Query(QueryText);
	
	For Each QueryParameter In PurchaseDocumentsAll.Parameters.Items Do
		Query.SetParameter(String(QueryParameter.Parameter), QueryParameter.Value);
	EndDo;
	
	Selection = Query.Execute().Select();
	
	Table = FormAttributeToValue("CurrencyTotalsTable");
	Table.FillValues(0, "PurchaseAmount_3");
	While Selection.Next() Do
		TotalByCurrencyLine = Table.Add();
		TotalByCurrencyLine.Currency       = Selection.Currency;
		TotalByCurrencyLine.IssuancePurpose   = Selection.IssuancePurpose;
		TotalByCurrencyLine.PurchaseAmount_3 = Selection.Sum;
	EndDo;
	Table.GroupBy("Currency, IssuancePurpose, Rate, Stretching",
	                 "OpeningBalance, InitialOverExpenditure, ReceivedEmails, Returned, Spent, overspending, TurnDown, Balance, Converted, PurchaseAmount_3");
	ValueToFormAttribute(Table, "CurrencyTotalsTable");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddAmountToTotalsByCurrency(CurrencyTotals, Currency, IssuancePurpose, Sum, Column)
	
	TotalByCurrency_ = CurrencyTotals.Get(Currency);
	If TotalByCurrency_ = Undefined Then
		TotalByCurrency_ = InitializeTotalByCurrency(IssuancePurpose, Sum, Column);
		CurrencyTotals.Insert(Currency, TotalByCurrency_);
	EndIf;

	GoalSummary = TotalByCurrency_.Get(IssuancePurpose);
	If GoalSummary = Undefined Then
		GoalSummary = InitializeGoalResult();
		TotalByCurrency_.Insert(IssuancePurpose, GoalSummary);
	EndIf;
	
	InitialAmount_ = 0;
	GoalSummary.Property(Column, InitialAmount_);
	GoalSummary.Insert(Column, InitialAmount_ + Sum);
	
EndProcedure

&AtClientAtServerNoContext
Function InitializeTotalByCurrency(IssuancePurpose, Sum, Column)
	
	TotalByCurrency_ = New Map;
	
	GoalSummary = TotalByCurrency_.Get(IssuancePurpose);
	If GoalSummary = Undefined Then
		GoalSummary = InitializeGoalResult();
		TotalByCurrency_.Insert(IssuancePurpose, GoalSummary);
	EndIf;
	
	Return TotalByCurrency_;
	
EndFunction

&AtClientAtServerNoContext
Function InitializeGoalResult()

	GoalSummary = New Structure;
	GoalSummary.Insert("OpeningBalance", 0);
	GoalSummary.Insert("InitialOverExpenditure", 0);
	GoalSummary.Insert("ReceivedEmails", 0);
	GoalSummary.Insert("Returned", 0);
	GoalSummary.Insert("Spent", 0);
	GoalSummary.Insert("Converted", 0);
	GoalSummary.Insert("TurnDown", 0);
	GoalSummary.Insert("Balance", 0);
	GoalSummary.Insert("overspending", 0);
	GoalSummary.Insert("PurchaseAmount_3", 0);
	
	Return GoalSummary;
	
EndFunction

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtClient
Procedure AutoTestFillInTheReceivedAdvancesCompletion(Result, AdditionalParameters) Export 
	
	FillInReceivedAdvances();
	
	If Object.OtherExpenses.Count() = 0 Then
		If ValueIsFilled(Object.Department) Then
			Text = StrTemplate(
				NStr("vi = 'Người tạm ứng không có các khoản tạm ứng được cấp mà anh ta đã không báo cáo cho doanh nghiệp %1 trong bộ phận %2 bằng tiền tệ %3';
					|ru = 'У подотчетного лица отсутствуют выданные авансы, за которые он не отчитался перед организацией %1 в подразделении %2 в валюте %3';
					|en = 'The advance holder has no advances received for which he or she has not reported to the %1 company in the %2 business unit in %3 currency'; fa = 'The advance holder has no advances received for which he or she has not reported to the %1 company in the %2 business unit in %3 currency';
					|it = 'Il responsabile non è in possesso degli anticipi rilasciati di cui non ha ancora presentato il rendiconto all''azienda %1 nel reparto %2 in valuta %3';
					|pl = 'Osoba odpowiedzialna nie ma wystawionych zaliczek, które nie zgłosiła firm %1 w dziale %2 w walucie obcej %3';
					|tr = 'Sorumlu kişinin, %2 departmanındaki %1 iş yerine %3 para biriminde rapor etmediği, verilmiş avansı yoktur.'"),
				Object.Organization, Object.Department, Object.Currency);
		Else
			Text = StrTemplate(
				NStr("vi = 'Người tạm ứng không có các khoản tạm ứng được cấp mà anh ta đã không báo cáo cho doanh nghiệp %1 bằng tiền tệ %2 không chỉ ra bộ phận';
					|ru = 'У подотчетного лица отсутствуют выданные авансы, за которые он не отчитался перед организацией %1 в валюте %2 без указания подразделения';
					|en = 'The advance holder has no advances received for which he or she has not reported to the %1 company in %2 currency without specifying a business unit'; fa = 'The advance holder has no advances received for which he or she has not reported to the %1 company in %2 currency without specifying a business unit';
					|it = 'Il responsabile non è in possesso degli anticipi rilasciati di cui non ha ancora presentato il rendiconto all''azienda%1 in valuta %2 senza indicazione del reparto';
					|pl = 'Osoba odpowiedzialna nie ma wystawionych zaliczek, które nie zgłosiła firm %1 w walucie obcej %2 bez podania działu';
					|tr = 'Sorumlu kişinin, belirtilen departman olmadan %1 iş yerine %2 para biriminde rapor etmediği, verilmiş avansı yoktur.'"),
				Object.Organization, Object.Currency);
		EndIf;
		CommonClientServer.MessageToUser(Text);
	EndIf;
	
	CalculateDocumentAmount(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInReceivedAdvances()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInReceivedAdvances();
	ValueToFormAttribute(DocumentObject, "Object");
	
	InitializeVATMethod();
	
	IncomeAndExpensesServer.UpdateServiceDetails(ThisObject);
	
	For Each ExpenseLine_ In Object.OtherExpenses Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, ExpenseLine_, "Object.OtherExpenses");
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectionBasedOnBalancesAfterVerification(Result, AdditionalParameters) Export
	
	Notification = New CallbackDescription("SelectionByStockCompletion", ThisObject);
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.AddToPaymentDecryption(ThisForm, Items.SelectionByStock.Name, Notification);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm, "SelectionByStock");
EndProcedure

&AtClient
Procedure SelectionByStockCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		SelectionByStockCompletionServer();
	EndIf;
EndProcedure

&AtServer
Procedure SelectionByStockCompletionServer()
	ARAPAccountingFormWork.DownloadPaymentTranscriptFromTemporaryStorage(ThisForm);
	For Each TableRow In Object.PaymentToVendors Do
		If Object.Multicurrency Then
			TableRow.Currency = TableRow.ARAPCurrency;
		EndIf;
	EndDo;
	CalculateDocumentAmount(ThisForm);
EndProcedure

&AtClient
Procedure PopulateConversionCompletion(Result, AdditionalParameters) Export
	
	CalculateDocumentAmount(ThisForm);
	
	For Each TableRow In CurrencyTotalsTable Do
		If TableRow.Balance > 0 Then
			NewRow = Object.CurrencyConversion.Add();
			NewRow.Currency = TableRow.Currency;
			NewRow.Sum = TableRow.Balance;
		EndIf;
		If TableRow.overspending > 0 Then
			NewRow = Object.CurrencyConversion.Add();
			NewRow.CurrencyOfConversion = TableRow.Currency;
			NewRow.ConversionAmount = TableRow.overspending;
		EndIf;
	EndDo;
	
	If Object.CurrencyConversion.Count() = 0 Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Người tạm ứng không có tiền từ doanh nghiệp %1';
				|ru = 'У подотчетного лица отсутствуют денежные средства от организации %1';
				|en = 'Advance holder has no %1 company cash'; fa = 'Advance holder has no %1 company cash';
				|it = 'Il responsabile non è in possesso di mezzi finanziari dell''azienda %1';
				|pl = 'Zaliczkobiorca nie ma środków pieniężnych-gotówki od firmy %1';
				|tr = 'Sorumlu kişinin, %1 iş yerinden parası bulunmuyor'"),
			Object.Organization);
		CommonClientServer.MessageToUser(Text);
	EndIf;
	
	CalculateDocumentAmount(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Function RowMultiCurrencyAmounts(CurrencyTotals)
	
	StringBalance = New Array;
	LineOverspend = New Array;
	
	For Each CurrencyKeyAndValue In CurrencyTotals Do
		
		InTotalBalance = 0;
		TotalOverExpenditure = 0;
		Currency = String(CurrencyKeyAndValue.Key);
		
		For Each KeyAndValue In CurrencyKeyAndValue.Value Do
			
			TotalsLine = KeyAndValue.Value;
			If TotalsLine.Balance <> 0 Then
	
				If TotalsLine.Balance < 0 Then
					TotalOverExpenditure = TotalOverExpenditure + -1 * TotalsLine.Balance;
				Else
					InTotalBalance = InTotalBalance + TotalsLine.Balance;
				EndIf;
	
			EndIf;
	
			If TotalsLine.overspending <> 0 Then
				TotalOverExpenditure = TotalOverExpenditure + TotalsLine.overspending;
			EndIf;
			
		EndDo;
	
		If InTotalBalance <> 0 Then
			StringBalance.Add(String(InTotalBalance) + " " + Currency + " ");
		EndIf;
		If TotalOverExpenditure <> 0 Then
			LineOverspend.Add(String(TotalOverExpenditure) + " " + Currency + " ");
		EndIf;
		
	EndDo;
	
	If Not StringBalance.Count() And Not LineOverspend.Count() Then
		TotalString = New FormattedString(NStr("vi = 'Số dư-';
												|ru = 'Остаток -';
												|en = 'Balance -'; fa = 'Balance -';
												|it = 'Residuo -';
												|pl = 'Saldo -';
												|tr = 'Bakiye -'"));
	Else
		ResultingStringArray = New Array;
		
		If StringBalance.Count() Then
			ResultingStringArray.Add(NStr("vi = 'Số dư';
											|ru = 'Остаток';
											|en = 'Balance'; fa = 'مانده';
											|it = 'Rimanenze';
											|pl = 'Balance';
											|tr = 'Bakiye'") + " ");
			ResultingStringArray.Add(StringBalance);
		EndIf;
		
		If LineOverspend.Count() Then
			ResultingStringArray.Add(NStr("vi = 'Chi quá';
											|ru = 'Перерасход';
											|en = 'Over-expenditure'; fa = 'هزینه مازاد';
											|it = 'Eccesso di spesa';
											|pl = 'Over-expenditure';
											|tr = 'Fazla harcama'") + " ");
			ResultingStringArray.Add(LineOverspend);
		EndIf;
		
		TotalString = New FormattedString(ResultingStringArray);
	EndIf;
	
	Return TotalString;
	
EndFunction

&AtServer
Procedure RecalculateConversionRate()
	
	TableRow = Object.CurrencyConversion.FindByID(Items.CurrencyConversion.CurrentRow);
	RecalculateConversionParameters(TableRow, "CurrencyOfConversion")
	
EndProcedure

&AtServer
Procedure RecalculateConversionParameters(TableRow, Var_AttributeName)
	
	ConversionParameters_SSLy = CashServer.InitializeConversionParameters();
	FillPropertyValues(ConversionParameters_SSLy, TableRow);
	ConversionParameters_SSLy.DocumentAmount = TableRow.Sum;
	ConversionParameters_SSLy.Date = Object.Date;
	ConversionParameters_SSLy.CurrencyOfComplianceAccounting = CurrencyOfComplianceAccounting;
	
	CashServer.CalculateConversionParameters(ConversionParameters_SSLy, Var_AttributeName);
	FillPropertyValues(TableRow, ConversionParameters_SSLy);
	TableRow.Sum = ConversionParameters_SSLy.DocumentAmount;
	
	GenerateCourseInText();
	
EndProcedure

&AtServer
Procedure GenerateCourseInText()
	
	TableRow = Object.CurrencyConversion.FindByID(Items.CurrencyConversion.CurrentRow);
	
	CourseTemplate = "%1 %2 = %3 %4";
	
	If TableRow.ConversionRate <> 0 Then
		If TableRow.Currency = CurrencyOfComplianceAccounting Then
			TableRow.RateAsText = StrTemplate(
				CourseTemplate,
				String(Format(TableRow.ConversionRate, "NFD=4")),
				TableRow.Currency,
				TableRow.ConversionRateMultiplier,
				TableRow.CurrencyOfConversion);
		Else
			TableRow.RateAsText = StrTemplate(
				CourseTemplate,
				TableRow.ConversionRateMultiplier,
				TableRow.Currency,
				String(Format(TableRow.ConversionRate, "NFD=4")),
				TableRow.CurrencyOfConversion);
		EndIf;
	Else
		TableRow.RateAsText = "0";
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePurchaseForActivity(Fill = True)
	
	FillParameters = Documents.ExpenseReport.ParametersForFillingInVATActivityType(Object);
	
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.PurchaseForActivity,
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.PurchaseForActivity,
		Object.PurchaseForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure DefinePrintingSingleAdvanceReport()
	
	If ValueIsFilled(StartDateOfPrintingSingleExpenseReport) Then
		If ValueIsFilled(Object.Date) Then
			PrintASingleExpenseReport = (Object.Date >= StartDateOfPrintingSingleExpenseReport);
		Else
			PrintASingleExpenseReport = (CurrentSessionDate() >= StartDateOfPrintingSingleExpenseReport);
		EndIf;
	Else
		PrintASingleExpenseReport = SingleExpenseReportUnconditionally;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function InsignificantVATRateOnServer(PaymentVATRate)
	
	Return VATAccountingERP.InsignificantRate(PaymentVATRate);
	
EndFunction

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	RecalculatedRows =
		Object.OtherExpenses.FindRows(New Structure("ElectronicTicket", Documents.ElectronicTicketTransaction.EmptyRef()));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(RecalculatedRows,
	                                                         StructureOfActions,
	                                                         Object.OtherExpenses,
	                                                         CachedValues);
	
EndProcedure

&AtServer
Function AlreadySelectedTickets()
	ArrayOfTickets = Object.OtherExpenses.Unload(,"ElectronicTicket").UnloadColumn("ElectronicTicket");
	ArrayOfTickets = CommonClientServer.CollapseArray(ArrayOfTickets);
	Return ArrayOfTickets;
EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_ConfirmationDate" Then
		ConfirmationDateOnChange(Items.ConfirmationDate);
	ElsIf Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion

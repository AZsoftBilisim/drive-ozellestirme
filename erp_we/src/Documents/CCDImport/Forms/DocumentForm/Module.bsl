#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var PartitionCache; // used for processing links between sections and products
&AtClient
Var OldPartitionNumber; // support for editing the section number
&AtClient
Var NewSectionNumber; // support for editing the section number

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	Items.GoodsSelectFromTheDesign.Visible = 
		Not GetFunctionalOption("ControlCompanyStockBalanceForRegistrationByReceipts");
		
	ArticleAvailabilityParameters = New Structure("CustomsFee, CustomsPenalty", Object.CustomsFee, Object.CustomsPenalty);
	ItemsAndDimensionsSelectionParameters = Documents.CCDImport.ItemsAndDimensionsSelectionParameters(ArticleAvailabilityParameters);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	EndIf;
	
	Items.PageSectionsProducts.Title = ?(Object.UseSections,  NStr("vi = 'Phần tờ khai HQ';
																	|ru = 'Разделы ГТД';
																	|en = 'CCD sections'; fa = 'بخش‌های CCD';
																	|it = 'Sezioni della dichiarazione doganale';
																	|pl = 'Rozdziały ŁDC';
																	|tr = 'GB''nin Bölümleri'"),  NStr("vi = 'Hàng hóa TKHQ';
																								|ru = 'Товары ГТД';
																								|en = 'CCD goods'; fa = 'CCD goods';
																								|it = 'Merce Dichiarazione Doganale di Carico';
																								|pl = 'Wiersze pozycji ŁDC';
																								|tr = 'GKB''nin Ürünleri'"));
	Items.SectionsGroup.Visible = Object.UseSections;
	Items.GroupGoods.ShowTitle = Object.UseSections; 
	Items.GroupGoods.Representation =  ?(Object.UseSections, UsualGroupRepresentation.WeakSeparation, UsualGroupRepresentation.None);
	If Object.UseSections Then
		Items.GroupGoods.TitleDataPath = "Object.Goods.RowsCount";
	EndIf;
	Items.GoodsShowAllGoods.Visible = Object.UseSections;
	Items.GoodsSetThePartitionNumber.Visible = Object.UseSections;
	Items.GoodsFillInTheSectionNumber.Visible = Object.UseSections;
	Items.GoodsSectionNumber.Visible = Object.UseSections;
	
	Items.GoodsVATRate.Visible = Not Object.UseSections;
	Items.GoodsDutyRate.Visible = Not Object.UseSections;
	
	VATAccountingSettings = VATAccountingERP.AccountingSettings();
	VATTaxation = VATAccountingSettings.BasicTaxationVATSales;
	
	CCDImportLocalization.SetMaskOfCustomsDeclarationNumber(Items.DeclarationNo.Mask);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
		Items.GroupTotalProducts.BackColor = New Color();
	EndIf;
	SetAvailabilityOfClipboardCommands();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber",, NStr("vi = 'đối với mục đích kế toán';
																								|ru = 'для целей учета';
																								|en = 'for accounting purposes'; fa = 'for accounting purposes';
																								|it = 'для целей учета';
																								|pl = 'for accounting purposes';
																								|tr = 'muhasebe amaçları için'"));
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	ArticleAvailabilityParameters = New Structure("CustomsFee, CustomsPenalty", CurrentObject.CustomsFee, CurrentObject.CustomsPenalty);
	ItemsAndDimensionsSelectionParameters = Documents.CCDImport.ItemsAndDimensionsSelectionParameters(ArticleAvailabilityParameters);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	UpdateDocumentAmountOnForm();
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	WriteParameters.Property("WriteMode", WriteMode);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	If Object.Status = Enums.CustomsDeclarationStatus.ReleasedFromCustoms And WriteMode = DocumentWriteMode.Posting Then
		
		If Object.UseSections Then
			If Object.Goods.FindRows(New Structure("SectionNumber", 0)).Count() > 0 Then
				Cancel = True;
			EndIf;
		EndIf;
		
		If Cancel Then
			Items.GoodsShowAllGoods.Check = True;
			ConfigureFillingServices(Items, Object);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	FillInFormDetails();
	FillInAdditionalProductAttributes();
	FillInSerialNumberOfProductInProductsServerTable();
	EstablishUseOfExcisableItems();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_CCDImport", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisForm, EventName, Parameter) Then
		PaymentCreditedServer(EventName, Parameter, Source);
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingAddProductsSelection(ValueSelected, CurPartitionData(Items.Sections), False, "GoodsAddressInStorage");
		
	ElsIf ChoiceSource.FormName = "CommonForm.SelectGoodsByReceipts" Then
		
		ProcessingAddProductsSelection(ValueSelected, CurPartitionData(Items.Sections), False, "GoodsAddressInStorage", "Goods", True);
		
	ElsIf ChoiceSource.FormName = "AccumulationRegister.GoodsForRegistrationOfImportDocuments.Form.SelectionByStock" Then
		
		ProcessingAddProductsSelection(ValueSelected, CurPartitionData(Items.Sections),True);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	EndIf;
	
	VATAccountingERPClient.ProcessingChangesInStateOfVATPaymentOnInvoice(
		ChoiceSource,
		ValueSelected,
		Items.InvoicePaymentStatus);
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusOnChange(Item)
	If ValueIsFilled(Object.Status) And DocumentStatus <> Object.Status
	 And Object.Status = PredefinedValue("Enum.CustomsDeclarationStatus.ReleasedFromCustoms") Then
		DateOfProduction = Object.Date;
		ShowInputDate(New CallbackDescription("StatusOnChangeCompletion", ThisObject, New Structure("DateOfProduction", DateOfProduction)), DateOfProduction, NStr("vi = 'Ngày thông quan';
																																									|ru = 'Дата выпуска с таможни';
																																									|en = 'Date of release from the customs'; fa = 'Date of release from the customs';
																																									|it = 'Data rilascio dalla dogana';
																																									|pl = 'Data wyprowadzenia z urzędu celnego';
																																									|tr = 'Gümrükten çıkış tarihi'"), DateFractions.Date);
        Return;
	EndIf;
	DocumentStatus = Object.Status;
EndProcedure

&AtClient
Procedure StatusOnChangeCompletion(Date, AdditionalParameters) Export
    
	DateOfProduction = ?(Date = Undefined, AdditionalParameters.DateOfProduction, Date);
	PerCurDate = CommonClient.SessionDate(); 	

	If (Date <> Undefined) Then
		If Date > PerCurDate Then
			ClearMessages();
			ErrorText = NStr("vi = 'Ngày thông quan không thể lớn hơn hiện tại!';
							|ru = 'Дата выпуска с таможни не может быть больше текущей!';
							|en = 'The release date from customs cannot be later than the current date!'; fa = 'The release date from customs cannot be later than the current date!';
							|it = 'Data di rilascio dalla dogana non può essere successiva alla data odierna!';
							|pl = 'Data wydania z urzędu celnego nie może być większa bieżącej!';
							|tr = 'Gümrükten çıkış tarihi güncel tarihten sonra olamaz!'");
			CommonClientServer.MessageToUser(ErrorText, Object.Ref, "Object");
			Return;	
		EndIf;
		Object.Date = EndOfDay(DateOfProduction);
	EndIf;
	
    DocumentStatus = Object.Status;

EndProcedure

&AtClient
Procedure VendorOnChange(Item)
	VendorOnChangeServer();
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
	If ThereAreStringsOfExcellentCurrency() Then
		RecalculateAmountAtExchangeRateOnDate();
	EndIf; 
	
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationOnChangeServer();
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
EndProcedure

&AtClient
Procedure LabelReceiptTitleClick(Item, StandardProcessing)
	StandardProcessing = False;
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			ReceiptsList,
			NStr("vi = 'Tiếp nhận hàng hóa nhập khẩu (%DocumentsCount%)';
				|ru = 'Поступления по импорту (%DocumentsCount%)';
				|en = 'Imported receipt (%DocumentsCount%)'; fa = 'Imported receipt (%DocumentsCount%)';
				|it = 'Ricevute importazioni (%DocumentsCount%)';
				|pl = 'Wpływy z importu (%DocumentsCount%)';
				|tr = 'İthalat makbuzları (%DocumentsCount%)'")
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure RegistrationOptionOnChange(Item)
	
	CurrencyChanged = False;
	RegistrationOptionOnChangeServer(CurrencyChanged);
	
	If CurrencyChanged Then
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		DocumentCurrency = Object.Currency;
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	PartnerOnChangeServer();
EndProcedure

&AtClient
Procedure VendorSCounterpartyOnChange(Item)
	
	VendorSCounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	CounterpartyOnChangeServer();
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	TermsOnChangeServer();
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	ContractOnChangeServer();
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	If CurrentPage = Items.PageSectionsProducts Then
		ActivateSection();
	EndIf;
	If CurrentPage.Name = "PageGeneral" Then
		UpdateDocumentAmountOnForm();
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisForm);
	EndIf;
EndProcedure

&AtClient
Procedure ExpenseItemFeeOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ExpenseItemFeeStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemPenaltyOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);	
	
EndProcedure

&AtClient
Procedure ExpenseItemPenaltyStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionFeesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionFeesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure ExpensesDimensionFeesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure ExpensesDimensionPenaltiesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure


&AtClient
Procedure ExpensesDimensionPenaltiesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure ExpensesDimensionPenaltiesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure PaymentViaSinglePersonalAccountOnChange(Item)
	
	VATAccountingERPClient.ProcessingChangesInPaymentStateOfNDSInDocumentForm(
		Items.InvoicePaymentStatus,
		Not Object.PaymentViaSinglePersonalAccount);
		
EndProcedure

&AtClient
Procedure GoodsGoodsSequenceNumberOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	UpdateTheseLinesWhenChangingSerialNumberOfProduct(CurrentRow, Object);
		
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateTheseLinesWhenChangingSerialNumberOfProduct(CurrentRow, Object)
	
	CurrentRow.GoodsSequenceNumber = TrimAll(CurrentRow.GoodsSequenceNumber);
	If ValueIsFilled(Object.DeclarationNo) Then
		NewNumberForSF = DeclarationNoForInvoice(TrimAll(Object.DeclarationNo), CurrentRow.GoodsSequenceNumber);
		If CurrentRow.DeclarationNoForInvoice <> NewNumberForSF Then
			CurrentRow.DeclarationNoForInvoice = NewNumberForSF;
			CurrentRow.CCDNumber = Undefined;
		EndIf;	
	EndIf;
	
EndProcedure	

&AtClient
Procedure DeclarationNoEditTextChange(Item, Text, StandardProcessing)
	
	CurrentTextDeclarationNumbers = Text;
	AttachIdleHandler("Attachable_DisplayInformationAboutErrorsInNumber", 0.1, True);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
			
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSections

&AtClient
Procedure SectionsOnActivateRow(Item)
	AttachIdleHandler("ActivateSection", 0.2, True);
EndProcedure

&AtClient
Procedure SectionsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	NewSectionNumber = NewSectionNumber(Object.Sections);
	If (NewSectionNumber > SectionNumberLimit) Then
		Cancel = True;
	EndIf;
	
	If Cancel Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Đã tới hạn số thứ tự của phân hệ, không thể tạo mới phân hệ. Hãy kiểm tra bộ đánh số của phân hệ.';
				|ru = 'Достигнут предельный номер раздела, новый раздел добавить нельзя. Проверьте нумерацию разделов.';
				|en = 'The limit count of section was reached, cannot add a new section. Check the section numbering.'; fa = 'The limit count of section was reached, cannot add a new section. Check the section numbering.';
				|it = 'Raggiunto il numero limite della sezione, non è possibile aggiungere altre sezioni. Verificate la numerazione delle sezioni.';
				|pl = 'Osiągnięto limit numerów sekcji, nie możesz dodać nowej sekcji. Sprawdź numerację sekcji.';
				|tr = 'Bölüm sayısı sınırına ulaşıldı, yeni bir bölüm eklenemiyor. Bölüm numaralandırmasını kontrol edin.'"),
			Object.Ref,
			"Sections[" + (Items.Sections.CurrentData.LineNumber - 1) + "].SectionNumber",);
	EndIf;
EndProcedure

&AtClient
Procedure SectionsOnStartEdit(Item, NewRow, Copy)
	If NewRow Then
		Item.CurrentData.SectionNumber = NewSectionNumber;
		Item.CurrentData.ExciseTaxAmount = 0;
	EndIf;
	OldPartitionNumber = Item.CurrentData.SectionNumber;
EndProcedure

&AtClient
Procedure SectionsOnEditEnd(Item, NewRow, CancelEdit)
	If Item.CurrentData <> Undefined Then
		If NewRow And Not CancelEdit Then
			ReplaceItemInSelectionList(
				Items.GoodsSectionNumber.ChoiceList, -1, Item.CurrentData.SectionNumber, Items.GoodsSectionNumber.Format);
		EndIf;
		OldPartitionNumber = Item.CurrentData.SectionNumber;
	EndIf;
EndProcedure

&AtClient
Procedure SectionsBeforeDeleteRow(Item, Cancel)
	Sections = ProcessingOfTabularFormsClientServer.CollectionItems(Object.Sections, Items.Sections.SelectedRows);
	PartitionCache = New Map;
	For Each Section In Sections Do
		PartitionCache.Insert(Section.SectionNumber, Section.SectionNumber);
	EndDo;
EndProcedure

&AtClient
Procedure SectionsAfterDeleteRow(Item)
	ClearProductSectionNumbers(PartitionCache);
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
EndProcedure

&AtClient
Procedure SectionsSectionNumberOnChange(Item)
	NewSectionNumber = Items.Sections.CurrentData.SectionNumber;
	If SectionNumberIsUnique(Object.Sections, NewSectionNumber) Then
				
		// changing the section number for related products
		FillInTabpartyFields("Goods", New Structure("SectionNumber", NewSectionNumber), New Structure("SectionNumber", OldPartitionNumber));
		// let's remove the old section number from the list of sections in the goods
		ReplaceItemInSelectionList(
			Items.GoodsSectionNumber.ChoiceList, OldPartitionNumber, NewSectionNumber, Items.GoodsSectionNumber.Format);
		
		ActivateSection();	
	Else
		Items.Sections.CurrentData.SectionNumber = OldPartitionNumber;
		CommonClientServer.MessageToUser(
			StrReplace(NStr("vi = 'Đã có phần số %1. Hãy chỉ ra số thứ tự khác trong phần';
							|ru = 'Раздел №%1 уже существует. Укажите другой номер раздела';
							|en = 'Section No.%1 already exists. Specify another section number'; fa = 'Section No.%1 already exists. Specify another section number';
							|it = 'La sezione №%1 esiste già. Indicate un altro numero di sezione';
							|pl = 'Sekcja nr%1 już istnieje. Podaj inny numer sekcji.';
							|tr = 'Bölüm No%1 zaten mevcut. Farklı bir bölüm numarası girin.'"), "%1", NewSectionNumber),
			Object.Ref,
			"Sections[" + (Items.Sections.CurrentData.LineNumber - 1) + "].SectionNumber",);
	EndIf;
	NewSectionNumber = Items.Sections.CurrentData.SectionNumber;
EndProcedure

&AtClient
Procedure SectionsCustomsValueOnChange(Item)
	Section = Items.Sections.CurrentData;
	RecalculateFields(Section, "DutyAmount, VATAmount", Section, Object.UseSections);
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
	AllocateAmongGoodsServer(False);
EndProcedure

&AtClient
Procedure SectionsDutyRateOnChange(Item)
	Section = Items.Sections.CurrentData;
	RecalculateFields(Section, "DutyAmount, VATAmount", Section, Object.UseSections);
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
	AllocateAmongGoodsServer(False);
EndProcedure

&AtClient
Procedure SectionsDutyAmountOnChange(Item)
	Section = Items.Sections.CurrentData;
	RecalculateFields(Section, "DutyRate, VATAmount", Section, Object.UseSections);
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
	AllocateAmongGoodsServer(False);
EndProcedure

&AtClient
Procedure SectionsVATRateOnChange(Item)
	Section = Items.Sections.CurrentData;
	RecalculateFields(Section, "VATAmount", Section, Object.UseSections);
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
	AllocateAmongGoodsServer(False);
EndProcedure

&AtClient
Procedure SectionsVATAmountOnChange(Item)
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
	AllocateAmongGoodsServer(False);
EndProcedure


#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	If NewRow And Not Copy Then
		If Object.UseSections Then
			SectionData = CurPartitionData(Items.Sections);
			FillPropertyValues(Items.Goods.CurrentData, SectionData, "SectionNumber, VATRate, DutyRate, OriginCountry, Warehouse");
		EndIf;
		If ValueIsFilled(Object.DeclarationNo) Then
			Item.CurrentData.DeclarationNoForInvoice = DeclarationNoForInvoice(TrimAll(Object.DeclarationNo), Item.CurrentData.LineNumber);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
	UpdateInformationOnReceipts();
	RecalculateAmountsInSection();
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	Actions = New Structure;
	Actions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	Actions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	Actions.Insert("RecalculateNumberOfUnits");
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	Actions.Insert("FillInCountryOfOriginOfProduct",
						BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	Actions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	Actions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName", FormName, "Goods"));
	If Not Object.UseSections Then
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		ParametersFillInVATRate.VATTaxation = VATTaxation;
		Actions.Insert("FillInVATRate", ParametersFillInVATRate);
	EndIf;
	If UseExcisableGoods Then
		ParametersForFillingInExcisableItemAttribute =
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object);
		Actions.Insert("FillInExcisableItemAttribute", ParametersForFillingInExcisableItemAttribute);
		ParametersForRecalculationOfExciseTaxAmount =
			BatchProcessingOfTablePartClientServer.ParametersForRecalculationOfExciseTaxAmount(Object, True);
		Actions.Insert("RecalculateExciseTaxAmount", ParametersForRecalculationOfExciseTaxAmount);
	EndIf;
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(Actions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions,
		"Warehouse",
		True);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	
	RecalculateFields(CurrentRow, "VATAmount", CurPartitionData(Items.Sections), Object.UseSections);
	RecalculateAmountsInSection();
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
    CurrentRow = Items.Goods.CurrentData;
	Actions = New Structure;
	Actions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	Actions = New Structure;
	Actions.Insert("RecalculateNumberOfUnits");
	If UseExcisableGoods And CurrentRow.ExcisableGoods Then
		ParametersForRecalculationOfExciseTaxAmount =
			BatchProcessingOfTablePartClientServer.ParametersForRecalculationOfExciseTaxAmount(Object, True);
		Actions.Insert("RecalculateExciseTaxAmount", ParametersForRecalculationOfExciseTaxAmount);
	EndIf;
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions,
		"Warehouse",
		True);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	If UseExcisableGoods And CurrentRow.ExcisableGoods Then
		RecalculateFields(CurrentRow, "VATAmount", CurPartitionData(Items.Sections), Object.UseSections);
		RecalculateAmountsInSection();
	EndIf;
EndProcedure

&AtClient
Procedure GoodsProductsUnitOfMeasureOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If UseExcisableGoods And CurrentRow.ExcisableGoods Then
		
		Actions = New Structure;
		ParametersForRecalculationOfExciseTaxAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculationOfExciseTaxAmount(
			Object, True);
		Actions.Insert("RecalculateExciseTaxAmount", ParametersForRecalculationOfExciseTaxAmount);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
		RecalculateFields(CurrentRow, "VATAmount", CurPartitionData(Items.Sections), Object.UseSections);
		RecalculateAmountsInSection();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	Actions = New Structure;
	Actions.Insert("RecalculateNumberOfUnits");
	If UseExcisableGoods And CurrentRow.ExcisableGoods Then
		ParametersForRecalculationOfExciseTaxAmount =
			BatchProcessingOfTablePartClientServer.ParametersForRecalculationOfExciseTaxAmount(Object, True);
		Actions.Insert("RecalculateExciseTaxAmount", ParametersForRecalculationOfExciseTaxAmount);
	EndIf;
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions,
		"Warehouse",
		True);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	If UseExcisableGoods And CurrentRow.ExcisableGoods Then
		RecalculateFields(CurrentRow, "VATAmount", CurPartitionData(Items.Sections), Object.UseSections);
		RecalculateAmountsInSection();
	EndIf;
EndProcedure

&AtClient
Procedure GoodsExciseTaxAmountOnChange(Item)
	OwnGoods = Items.Goods.CurrentData;
	RecalculateFields(OwnGoods, "VATAmount", CurPartitionData(Items.Sections), Object.UseSections);
	RecalculateAmountsInSection();
EndProcedure

&AtClient
Procedure GoodsCustomsValueOnChange(Item)
	OwnGoods = Items.Goods.CurrentData;
	RecalculateFields(OwnGoods, "DutyAmount, VATAmount", CurPartitionData(Items.Sections), Object.UseSections);
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
EndProcedure

&AtClient
Procedure GoodsDutyRateOnChange(Item)
	OwnGoods = Items.Goods.CurrentData;
	RecalculateFields(OwnGoods, "DutyAmount, VATAmount", CurPartitionData(Items.Sections), Object.UseSections);
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	OwnGoods = Items.Goods.CurrentData;
	RecalculateFields(OwnGoods, "VATAmount", CurPartitionData(Items.Sections), Object.UseSections);
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
EndProcedure

&AtClient
Procedure GoodsDutyAmountOnChange(Item)
	OwnGoods = Items.Goods.CurrentData;
	RecalculateFields(OwnGoods, "DutyRate, VATAmount", CurPartitionData(Items.Sections), Object.UseSections);
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
EndProcedure

&AtClient
Procedure GoodsCCDNumberOnChange(Item)
	CCDData = GeneralPurposeTMServerCall.ObjectAttributesValues(Items.Goods.CurrentData.CCDNumber, "Code, OriginCountry, GoodsSequenceNumber");
	Items.Goods.CurrentData.GoodsSequenceNumber = CCDData.GoodsSequenceNumber;
	Items.Goods.CurrentData.DeclarationNoForInvoice = CCDData.Code;
	Items.Goods.CurrentData.OriginCountry = CCDData.OriginCountry;
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);

EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters",
													CurrentRow.Warehouse, SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsDocumentInflowOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	DocumentReceivedWhenServerChanges(CurrentRow.GetID());
	
EndProcedure

&AtClient
Procedure GoodsSectionNumberOnChange(Item)
	
	OwnGoods = Items.Goods.CurrentData;
	RecalculateFields(OwnGoods, "DutyAmount, VATAmount", CurPartitionData(Items.Sections), Object.UseSections);
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure AllocateAmongGoods(Command)
	
	ClearMessages();
	
	ErrorText = "";
	If Object.Sections.Count() = 0 Then
		ErrorText = NStr("vi = 'Cần tạo ít nhất một mục của tờ khai và điền hàng hóa vào mục đó.';
						|ru = 'Необходимо создать хотя бы один раздел декларации и заполнить в нем товары.';
						|en = 'You must create at least one declaration section and fill in goods in it.'; fa = 'You must create at least one declaration section and fill in goods in it.';
						|it = 'È necessario creare almeno una sezione della dichiarazione, e ivi compilarvi i prodotti.';
						|pl = 'Musisz utworzyć przynajmniej jeden rozdział deklaracji i wypełnić w nim wiersze pozycji.';
						|tr = 'Beyannamenin en az bir bölümü oluşturulmalı ve ürünler doldurulmalıdır.'");
		CommonClientServer.MessageToUser(ErrorText, Object.Ref, "Object.Sections");
		Return;
	EndIf;
	If Object.Goods.Count() = 0 Then
		ErrorText = NStr("vi = 'Cần điền hàng hóa trong tờ khai. Có thể thực hiện điều này bằng lệnh ""Điền"" hoặc thực hiện thủ công.';
						|ru = 'Необходимо заполнить товары декларации. Это можно сделать с помощью команды ""Заполнить"" или вручную.';
						|en = 'You must fill in declared goods. You can do it with command ""Fill in"" or manually.'; fa = 'You must fill in declared goods. You can do it with command ""Fill in"" or manually.';
						|it = 'È necessario compilare i prodotti della dichiarazione. È possibile farlo tramite il comando ""Compila"", oppure manualmente.';
						|pl = 'Należy wypełnić wiersze pozycji deklaracji. Można to zrobić za pomocą polecenia ""Wypełnij"" lub ręcznie.';
						|tr = 'Mal beyanlarını doldurulmalıdır. Bu, ""Doldur"" komutuyla veya manuel olarak yapılabilir.'");
		CommonClientServer.MessageToUser(ErrorText, Object.Ref, "Object.Goods");
		Return;
	EndIf;
		
	Filter = New Structure("SectionNumber");
	Sections = ProcessingOfTabularFormsClientServer.CollectionItems(Object.Sections, Items.Sections.SelectedRows);
	SectionsList = "";
	For Each Section In Sections Do
		SectionNumber = Format(Section.SectionNumber, "NZ=0; NG=0");
		SectionsList = SectionsList + ?(ValueIsFilled(SectionsList), ", ", "") + SectionNumber;
		
		If Section.CustomsValue = 0. Then
			ErrorText = NStr("vi = 'Cần đặt giá trị hải quan trong phần% Phần số%.';
							|ru = 'Необходимо задать таможенную стоимость в разделе %SectionNumber%.';
							|en = 'Specify customs value in section %SectionNumber%.'; fa = 'Specify customs value in section %SectionNumber%.';
							|it = 'È necessario specificare il valore doganale nella sezione %SectionNumber%.';
							|pl = 'Należy podać wartość celną w rozdziale %SectionNumber%.';
							|tr = 'Gümrük değeri %SectionNumber% bölümünde ayarlanmalıdır.'");
			ErrorText = StrReplace(ErrorText, "%SectionNumber%", SectionNumber);
			CostField = CommonClientServer.PathToTabularSection("Sections", Section.LineNumber, "CustomsValue");
			CommonClientServer.MessageToUser(ErrorText, Object.Ref, CostField, "Object");
		EndIf;
		
		Filter.SectionNumber = Section.SectionNumber;
		Goods = Object.Goods.FindRows(Filter);
		For Each OwnGoods In Goods Do
			If OwnGoods.CustomsValue = 0. Then
				ErrorText =
					NStr("vi = 'Cần điền trước giá trị hải quan của hàng hóa trong dòng %RowOfProduct% phần %SectionNumber%.';
						|ru = 'Необходимо предварительно заполнить таможенную стоимость товара в строке %RowOfProduct% раздела %SectionNumber%.';
						|en = 'Fill in customs value of goods in line %RowOfProduct% of section %SectionNumber% in advance.'; fa = 'Fill in customs value of goods in line %RowOfProduct% of section %SectionNumber% in advance.';
						|it = 'È necessario innanzitutto compilare il valore doganale del prodotto nella riga %RowOfProduct% della sezione %SectionNumber%.';
						|pl = 'Należy najpierw wprowadzić wartość celną towaru w wierszu %RowOfProduct% rozdziału %SectionNumber%.';
						|tr = 'Malların gümrük değeri %SectionNumber% bölümün %RowOfProduct% satırına önceden doldurulmalıdır.'");
				ErrorText = StrReplace(ErrorText, "%SectionNumber%", SectionNumber);
				ErrorText = StrReplace(ErrorText, "%RowOfProduct%", Format(OwnGoods.LineNumber, "NZ=0; NG=0"));
				CostField = CommonClientServer.PathToTabularSection("Goods", OwnGoods.LineNumber, "CustomsValue");
				CommonClientServer.MessageToUser(ErrorText, Object.Ref, CostField, "Object");
			EndIf;
		EndDo;
		If Goods.Count() = 0 Then
			ErrorText = NStr("vi = 'Bạn phải điền vào các sản phẩm của phần% Phần số%. Điều này có thể được thực hiện bằng cách sử dụng lệnh Fill hoặc bằng tay.';
							|ru = 'Необходимо заполнить товары раздела %SectionNumber%. Это можно сделать с помощью команды ""Заполнить"" или вручную.';
							|en = 'Fill in goods of section %SectionNumber% using the ""Fill in"" command or manually.'; fa = 'Fill in goods of section %SectionNumber% using the ""Fill in"" command or manually.';
							|it = 'È necessario compilare i prodotti della sezione %SectionNumber%. È possibile farlo tramite il comando ""Compila"", oppure manualmente.';
							|pl = 'Należy wypełnić wiersze pozycji rozdziału %SectionNumber%. Można to zrobić za pomocą polecenia ""Wypełnij"" lub ręcznie.';
							|tr = 'Bölüm %SectionNumber%''deki ürünleri doldurmanız gerekmektedir. Bu, ""Doldur"" komutu kullanılarak veya manuel olarak yapılabilir.'");
			ErrorText = StrReplace(ErrorText, "%SectionNumber%", SectionNumber);
			CommonClientServer.MessageToUser(ErrorText, Object.Ref, "Object.Goods");
		EndIf;
	EndDo;
	
	If ErrorText <> "" Or Sections.Count() = 0 Then
		Return;
	EndIf;
	
	AllocateAmongGoodsServer();
	
	ExplanationText = ?(Sections.Count() > 1,
		NStr("vi = 'Số tiền %SectionsList%  được phân bổ cho hàng hóa';
			|ru = 'Суммы разделов %SectionsList% распределены на товары';
			|en = 'Totals of sections %SectionsList% are divided between the goods'; fa = 'Totals of sections %SectionsList% are divided between the goods';
			|it = 'Somme delle sezioni %SectionsList% distribuite per prodotti';
			|pl = 'Kwoty rozdziałów %SectionsList% są rozdzielane na wiersze pozycji';
			|tr = '%SectionsList% bölümlerindeki tutarlar ürünleri tahsis edilir'"),
		NStr("vi = 'Số tiền %SectionsList% được phân bổ cho hàng hóa';
			|ru = 'Суммы раздела %SectionsList% распределены на товары';
			|en = 'Totals of the %SectionsList% section are divided between the goods'; fa = 'Totals of the %SectionsList% section are divided between the goods';
			|it = 'Somme della sezione %SectionsList% distribuite per prodotti';
			|pl = 'Kwoty rozdziału %SectionsList% są rozdzielane na wiersze pozycji';
			|tr = '%SectionsList% bölümündeki tutarlar ürünleri tahsis edilir'"));
	ShowUserNotification(
		NStr("vi = 'Đã thực hiện lệnh';
			|ru = 'Команда выполнена';
			|en = 'Command executed'; fa = 'Command executed';
			|it = 'Comando eseguito';
			|pl = 'Polecenie wykonano';
			|tr = 'Komut yapıldı'"), ,
		StrReplace(ExplanationText, "%SectionsList%", SectionsList), PictureLib.Information32);
EndProcedure

&AtClient
Procedure CalculateByGoods(Command)
	If Object.Goods.Count() > 0 And Object.Sections.Count() > 0 Then
		CalculateByGoodsServer();
	EndIf;
EndProcedure

&AtClient
Procedure ShowAllGoods(Command)
	Items.GoodsShowAllGoods.Check = Not Items.GoodsShowAllGoods.Check;
	ConfigureFillingServices(Items, Object);
	ActivateSection();
EndProcedure

&AtClient
Procedure SetThePartitionNumber(Command)
	FillInTabpartyFields("Goods", New Structure("SectionNumber", CurPartitionData(Items.Sections).SectionNumber));
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInTheSectionNumber(Command)
	CurrentSection = CurPartitionData(Items.Sections).SectionNumber;
	FillInTabpartyFields("Goods", New Structure("SectionNumber", CurrentSection), New Structure("SectionNumber", 0));
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.CCDImport.DocumentForm.Command.SelectGoods");
	
	Warehouse = CurPartitionData(Items.Sections).Warehouse;
	PickingParameters = New Structure;
	PickingParameters.Insert("Document", Object.Ref);
	PickingParameters.Insert("Date", DocumentDate(Object.Date));
	PickingParameters.Insert("Warehouse", Warehouse);
	PickingParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	PickingParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	PickingParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders",  True);
	PickingParameters.Insert("SelectionModeWithoutAmountParameters",             True);
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", PickingParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SelectFromReceipt(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Vendor",   NStr("vi = 'Nhà cung cấp';
																|ru = 'Поставщик';
																|en = 'Vendor'; fa = 'تأمین‌کننده';
																|it = 'Fornitore';
																|pl = 'Dostawca';
																|tr = 'Tedarikçi'"));
	Notification = New CallbackDescription("SelectFromReceiptCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure SelectFromReceiptCompletion(Result, AdditionalParameters) Export 
	
	SectionData = CurPartitionData(Items.Sections);
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Partner",          Object.Vendor);
	PickingParameters.Insert("Organization",      Object.Organization);
	PickingParameters.Insert("Warehouse",            SectionData.Warehouse);
	PickingParameters.Insert("PurchaseByImport", True);
	PickingParameters.Insert("ShowContainers",   False);
	PickingParameters.Insert("ShowProducts_", True);
	PickingParameters.Insert("PriceIncludesVAT",  False);
	PickingParameters.Insert("Currency",           Object.Currency);
	PickingParameters.Insert("Date",             DocumentDate(Object.Date));
	
	OpenForm("CommonForm.SelectGoodsByReceipts", PickingParameters, ThisForm);
	
	UpdateInformationOnReceipts();
	
EndProcedure

&AtClient
Procedure SelectFromTheDesign(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Vendor",   NStr("vi = 'Nhà cung cấp';
																|ru = 'Поставщик';
																|en = 'Vendor'; fa = 'تأمین‌کننده';
																|it = 'Fornitore';
																|pl = 'Dostawca';
																|tr = 'Tedarikçi'"));
	Notification = New CallbackDescription("SelectFromTheDesignCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure SelectFromTheDesignCompletion(Result, AdditionalParameters) Export
	
	SectionData = CurPartitionData(Items.Sections);
	FilterOfProducts_ = New Structure("SectionNumber", SectionData.SectionNumber);
	AddressInStorage = PutInStorage("Goods", "Products, Characteristic, Series, Warehouse, Count, DocumentInflow", FilterOfProducts_);
	Warehouse = SectionData.Warehouse;
	
	PickingParameters = New Structure;
	PickingParameters.Insert("AddressInStorage", AddressInStorage);
	PickingParameters.Insert("Organization",     Object.Organization);
	PickingParameters.Insert("Warehouse",           Warehouse);
	PickingParameters.Insert("Date",            Object.Date);
	PickingParameters.Insert("Vendor",       Object.Vendor);
	
	OpenForm("AccumulationRegister.GoodsForRegistrationOfImportDocuments.Form.SelectionByStock", PickingParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure FillInTheCostOfSelectedLines(Command)
	Var PriceKind;
	ForBlankLines = False;
	SelectVendorsPriceType(PriceKind,ForBlankLines);
EndProcedure

&AtClient
Procedure FillInTheCostOfEmptyLines(Command)
	Var PriceKind;
	ForBlankLines = True;
	SelectVendorsPriceType(PriceKind,ForBlankLines);
EndProcedure

&AtClient
Procedure SetTheCountryOfOrigin(Command)
	If Items.Goods.SelectedRows.Count()>0 Then
		OpenForm("Catalog.WorldCountries.ChoiceForm", New Structure("ChoiceMode", True),,,,, New CallbackDescription("SetTheCountryOfOriginCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure SetTheCountryOfOriginCompletion(Result, AdditionalParameters) Export
    
    OriginCountry = Result;
    If ValueIsFilled(OriginCountry) Then
        FillInTabpartyFields("Goods", New Structure("OriginCountry, CCDNumber", OriginCountry, Undefined));
    EndIf;

EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.CreditPaymentForm);
	
EndProcedure

&AtClient
Procedure SetUpAWarehouse(Command)
	If Items.Goods.SelectedRows.Count()>0 Then
		OpeningParameters = New Structure;
		OpeningParameters.Insert("SelectWarehouseGroup", False);
		OpenForm("Catalog.Warehouses.ChoiceForm", OpeningParameters,,,,, New CallbackDescription("SetUpAWarehouseCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure SetUpAWarehouseCompletion(Result, AdditionalParameters) Export
    
    PlacementWarehouse = Result;
    If ValueIsFilled(PlacementWarehouse) Then
        SetUpAWarehouseServer(PlacementWarehouse);
    EndIf;

EndProcedure

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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_DisplayInformationAboutErrorsInNumber()
	
	UpdateInformationAboutErrorsInNumber(CurrentTextDeclarationNumbers, 
									   BeginningOfCorrectPeriod, 
									   EndOfCorrectPeriod, 
									   Items.ErrorInTheCustomsDeclarationNumber);
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard(CurPartitionData(Items.Sections));
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InvoicePaymentStatus(Command)
	
	VATAccountingERPClient.OpenInvoiceVATPaymentStateForm(Object.Ref, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

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
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpenseItemFee.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CustomsFee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ExpenseItemFee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpenseItemFee.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CustomsFee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ExpenseItemFee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpenseItemPenalty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CustomsPenalty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ExpenseItemPenalty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpenseItemPenalty.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CustomsPenalty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ExpenseItemPenalty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SectionsDutyAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Sections.DutyRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Sections.DutyAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SectionsDutyAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Sections.DutyRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExciseTaxAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ExcisableGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SectionsExciseTaxAmount.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExciseTaxAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseExcisableGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SectionsExciseTaxAmount.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExciseTaxAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseExcisableGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	
	//
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	//
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	
	AddConditionalAppearanceLocalization();
	
EndProcedure

#Region OnChangeAttributes

&AtClient
Procedure RecalculateAmountAtExchangeRateOnDate()
	
	QueryText = NStr("vi = 'Tờ khai hải quan đã lập theo mua hàng tính theo ngoại tệ; tính số tiền theo tỷ giá vào ngày trên chứng từ?';
					|ru = 'Таможенная декларация оформлена по поступлениям в иностранной валюте, пересчитать сумму по курсу на дату документа?';
					|en = 'The customs declaration is drawn up according to receipt in foreign currency. Recalculate the amount according to the exchange rate as of the document date?'; fa = 'The customs declaration is drawn up according to receipt in foreign currency. Recalculate the amount according to the exchange rate as of the document date?';
					|it = 'Dichiarazione doganale rilasciata per le ricevute in valuta estera. Ricalcolare l''importo al tasso di cambio alla data del documento?';
					|pl = 'Deklaracja celna sporządzona po otrzymaniu waluty obcej, przeliczyć kwotę wg kursu wymiany w dniu dokumentu?';
					|tr = 'Döviz cinsinden makbuzlar üzerine düzenlenen gümrük beyannamesi, belge tarihindeki döviz kuru tutarı kapsamında yeniden hesaplansın mı?'");
	
	ButtonsList = New ValueList();
	ButtonsList.Add(DialogReturnCode.OK, NStr("vi = 'Tính lại';
												|ru = 'Пересчитать';
												|en = 'Recalculate'; fa = 'محاسبه مجدد';
												|it = 'Ricalcolare';
												|pl = 'Recalculate';
												|tr = 'Yeniden hesapla'"));
	ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Không tính lại';
													|ru = 'Не пересчитывать';
													|en = 'Do not recalculate'; fa = 'Do not recalculate';
													|it = 'Non ricalcolare';
													|pl = 'Nie przeliczać';
													|tr = 'Hesaplamamak'"));
	
	ShowQueryBox(New CallbackDescription("RecalculateAmountAtExchangeRateOnDateCompletion", ThisObject), QueryText, ButtonsList);
	
EndProcedure

&AtClient
Procedure RecalculateAmountAtExchangeRateOnDateCompletion(QuestionResult, AdditionalParameters) Export
    
    If QuestionResult = DialogReturnCode.OK Then
        CurrencyConversionServer();
    EndIf;

EndProcedure

&AtServer
Procedure CurrencyConversionServer()

	Actions = New Structure();
	SetActionsForAdditionalProductAttributes(Actions);
	If Actions.Property("RecalculateNumberOfUnits") Then	// When calculating the customs value, this action is not required
		Actions.Delete("RecalculateNumberOfUnits");
	EndIf;
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	NewDeal = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, Object.Date, CurrencyOfComplianceAccounting);
	NewRateParameters   = New Structure("Currency, CourseNumerator, CourseDenominator", DocumentCurrency,   NewDeal.CourseNumerator,   NewDeal.CourseDenominator);

	CustomsDeclarationImportGoods = Object.Goods.Unload(,"Products,Characteristic,DocumentInflow,Count");
	
	Query = New Query();
	Query.SetParameter("CustomsDeclarationImportGoods", CustomsDeclarationImportGoods);
	Query.SetParameter("CurrencyOfComplianceAccounting", CurrencyOfComplianceAccounting);
	Query.Text =
	"SELECT
   |	CustomsDeclarationImportGoods.Products AS Products,
   |	CustomsDeclarationImportGoods.Characteristic AS Characteristic,
   |	CustomsDeclarationImportGoods.DocumentInflow AS DocumentInflow,
   |	CustomsDeclarationImportGoods.Count AS Count
   |INTO CustomsDeclarationImportGoods
   |FROM
   |	&CustomsDeclarationImportGoods AS CustomsDeclarationImportGoods
   |;
   |
   |////////////////////////////////////////////////////////////////////////////////
   |SELECT
   |	CustomsDeclarationImportGoods.Products AS Products,
   |	CustomsDeclarationImportGoods.Characteristic AS Characteristic,
   |	CustomsDeclarationImportGoods.DocumentInflow AS DocumentInflow,
   |	SUM(CustomsDeclarationImportGoods.Count) AS Count
   |INTO TsvodnayaTDI
   |FROM
   |	CustomsDeclarationImportGoods AS CustomsDeclarationImportGoods
   |
   |GROUP BY
   |	CustomsDeclarationImportGoods.DocumentInflow,
   |	CustomsDeclarationImportGoods.Characteristic,
   |	CustomsDeclarationImportGoods.Products
   |;
   |
   |////////////////////////////////////////////////////////////////////////////////
   |SELECT
   |	PurchaseOfGoodsServicesGoods.Products AS Products,
   |	PurchaseOfGoodsServicesGoods.Characteristic AS Characteristic,
   |	SUM(PurchaseOfGoodsServicesGoods.Count) AS Count,
   |	PurchaseOfGoodsServicesGoods.Ref AS DocumentInflow,
   |	SUM(PurchaseOfGoodsServicesGoods.Sum) AS Sum
   |INTO UninvoicedReceipt
   |FROM
   |	Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
   |		INNER JOIN TsvodnayaTDI AS TsvodnayaTDI
   |		ON PurchaseOfGoodsServicesGoods.Products = TsvodnayaTDI.Products
   |			AND PurchaseOfGoodsServicesGoods.Characteristic = TsvodnayaTDI.Characteristic
   |			AND PurchaseOfGoodsServicesGoods.Ref = TsvodnayaTDI.DocumentInflow
   |
   |GROUP BY
   |	PurchaseOfGoodsServicesGoods.Ref,
   |	PurchaseOfGoodsServicesGoods.Products,
   |	PurchaseOfGoodsServicesGoods.Characteristic
   |;
   |
   |////////////////////////////////////////////////////////////////////////////////
   |SELECT
   |	CustomsDeclarationImportGoods.DocumentInflow AS DocumentInflow,
   |	VendorInvoice.Currency AS Currency
   |FROM
   |	CustomsDeclarationImportGoods AS CustomsDeclarationImportGoods
   |		INNER JOIN Document.VendorInvoice AS VendorInvoice
   |		ON CustomsDeclarationImportGoods.DocumentInflow = VendorInvoice.Ref
   |WHERE
   |	NOT VendorInvoice.Currency = &CurrencyOfComplianceAccounting
   |;
   |
   |////////////////////////////////////////////////////////////////////////////////
   |SELECT
   |	CustomsDeclarationImportGoods.DocumentInflow AS DocumentInflow,
   |	CustomsDeclarationImportGoods.Products AS Products,
   |	CustomsDeclarationImportGoods.Characteristic AS Characteristic,
   |	CustomsDeclarationImportGoods.Count * UninvoicedReceipt.Sum / UninvoicedReceipt.Count AS Sum,
   |	CustomsDeclarationImportGoods.Count AS Count
   |FROM
   |	CustomsDeclarationImportGoods AS CustomsDeclarationImportGoods
   |		LEFT JOIN UninvoicedReceipt AS UninvoicedReceipt
   |		ON CustomsDeclarationImportGoods.Products = UninvoicedReceipt.Products
   |			AND CustomsDeclarationImportGoods.Characteristic = UninvoicedReceipt.Characteristic
   |			AND CustomsDeclarationImportGoods.DocumentInflow = UninvoicedReceipt.DocumentInflow
   |;
   |
   |////////////////////////////////////////////////////////////////////////////////
   |SELECT
   |	UninvoicedReceipt.Products AS Products,
   |	UninvoicedReceipt.Characteristic AS Characteristic,
   |	UninvoicedReceipt.Sum AS Sum,
   |	UninvoicedReceipt.DocumentInflow AS DocumentInflow,
   |	UninvoicedReceipt.Count AS Count
   |FROM
   |	(SELECT
   |		CustomsDeclarationImportGoods.Products AS Products,
   |		CustomsDeclarationImportGoods.Characteristic AS Characteristic,
   |		CustomsDeclarationImportGoods.DocumentInflow AS DocumentInflow,
   |		SUM(CustomsDeclarationImportGoods.Count) AS QuantityAmount
   |	FROM
   |		CustomsDeclarationImportGoods AS CustomsDeclarationImportGoods
   |	
   |	GROUP BY
   |		CustomsDeclarationImportGoods.Products,
   |		CustomsDeclarationImportGoods.DocumentInflow,
   |		CustomsDeclarationImportGoods.Characteristic) AS TDITCollapsed
   |		INNER JOIN CustomsDeclarationImportGoods AS CustomsDeclarationImportGoods
   |		ON TDITCollapsed.Products = CustomsDeclarationImportGoods.Products
   |			AND TDITCollapsed.Characteristic = CustomsDeclarationImportGoods.Characteristic
   |			AND TDITCollapsed.DocumentInflow = CustomsDeclarationImportGoods.DocumentInflow
   |			AND TDITCollapsed.QuantityAmount <> CustomsDeclarationImportGoods.Count
   |		INNER JOIN UninvoicedReceipt AS UninvoicedReceipt
   |		ON TDITCollapsed.Products = UninvoicedReceipt.Products
   |			AND TDITCollapsed.Characteristic = UninvoicedReceipt.Characteristic
   |			AND TDITCollapsed.DocumentInflow = UninvoicedReceipt.DocumentInflow
   |			AND TDITCollapsed.QuantityAmount = UninvoicedReceipt.Count
   |
   |GROUP BY
   |	UninvoicedReceipt.Products,
   |	UninvoicedReceipt.DocumentInflow,
   |	UninvoicedReceipt.Characteristic,
   |	UninvoicedReceipt.Sum,
   |	UninvoicedReceipt.Count";
	
	Result = Query.ExecuteBatch();
	
	If Result[3].IsEmpty() Then
		Return;
	EndIf;
	
	ReceiptDetails 	= Result[3].Unload();
	ReceiptAmountTable = Result[4].Unload();
	TableOfAdjustments 	= Result[5].Unload();
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	CurrentSection = -1;
	For Each OwnGoods In Object.Goods Do
		
		If Not ValueIsFilled(OwnGoods.DocumentInflow) Then
			Continue;
		EndIf;
		
		If CurrentSection <> OwnGoods.SectionNumber Then
			CurrentSection = OwnGoods.SectionNumber;
			Found4 = Object.Sections.FindRows(New Structure("SectionNumber", CurrentSection));
			SectionData = ?(Found4.Count() > 0, Found4[0], EmptyPartitionData());
		EndIf;
		RowCurrency = ReceiptDetails.Find(OwnGoods.DocumentInflow,"DocumentInflow");
		CurrencyOfReceipt = ?(RowCurrency = Undefined, DocumentCurrency, RowCurrency.Currency);
		CurRate_1 = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOfReceipt, Object.Date, CurrencyOfComplianceAccounting);
		SourceRateParameters = New Structure("Currency, CourseNumerator, CourseDenominator", CurrencyOfReceipt, CurRate_1.CourseNumerator, CurRate_1.CourseDenominator);
		
		Filter = New Structure("Products,Characteristic,DocumentInflow,Count");
		FillPropertyValues(Filter,OwnGoods);
		ReceiptLines = ReceiptAmountTable.FindRows(Filter);
		If ReceiptLines.Count() > 0 Then
			ReceiptLine = ReceiptLines[0];
			OwnGoods.CustomsValue = ProcessingOfExchangeRatesTM.ConvertAtRate(ReceiptLine.Sum, SourceRateParameters, NewRateParameters);
			RowsToProcess.Add(OwnGoods);
				
			RecalculateFields(OwnGoods, "DutyAmount, VATAmount", SectionData, Object.UseSections);
		EndIf;
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		Actions,
		Object.Goods,
		CachedValues);

	If TableOfAdjustments.Count() > 0 Then
		
		CurrentSection = -1;
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		RowsToProcess = New Array();
		
		For Each OwnGoodsBalanced In TableOfAdjustments Do
			
			AmountForAllocation = ProcessingOfExchangeRatesTM.ConvertAtRate(OwnGoodsBalanced.Sum, SourceRateParameters, NewRateParameters);
			
			Filter = New Structure("Products,Characteristic,DocumentInflow");
			FillPropertyValues(Filter,OwnGoodsBalanced);
			FoundRows = Object.Goods.FindRows(Filter);
			
			If CurrentSection <> FoundRows[0].SectionNumber Then
				CurrentSection = FoundRows[0].SectionNumber;
				Found4 = Object.Sections.FindRows(New Structure("SectionNumber", CurrentSection));
				SectionData = ?(Found4.Count() > 0, Found4[0], EmptyPartitionData());
			EndIf;
			RowCurrency = ReceiptDetails.Find(FoundRows[0].DocumentInflow,"DocumentInflow");
			CurrencyOfReceipt = ?(RowCurrency = Undefined, DocumentCurrency, RowCurrency.Currency);
			CurRate_1 = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOfReceipt, Object.Date, CurrencyOfComplianceAccounting);
			SourceRateParameters = New Structure("Currency, CourseNumerator, CourseDenominator", CurrencyOfReceipt, CurRate_1.CourseNumerator, CurRate_1.CourseDenominator);
			
			CustomsValueTable = Object.Goods.Unload(FoundRows, "CustomsValue");
			CustomsValueTable.GroupBy(,"CustomsValue");

			FoundRows[0].CustomsValue = FoundRows[0].CustomsValue + AmountForAllocation - CustomsValueTable[0].CustomsValue;
			RowsToProcess.Add(FoundRows[0]);
			RecalculateFields(FoundRows[0], "DutyAmount, VATAmount", SectionData, Object.UseSections);
		EndDo; 

		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			Actions,
			Object.Goods,
			CachedValues);

	EndIf;
	
	CopyProduct = Object.Goods.Unload(,"SectionNumber,CustomsValue");
	CopyProduct.GroupBy("SectionNumber","CustomsValue");
	
	For Each Section In Object.Sections Do
		SectionRow = CopyProduct.Find(Section.SectionNumber,"SectionNumber");
		If SectionRow <> Undefined Then
			Section.CustomsValue = SectionRow.CustomsValue;
			RecalculateFields(Section, "DutyAmount, VATAmount", Section, Object.UseSections);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function ThereAreStringsOfExcellentCurrency()

	ReceiptDocuments = Object.Goods.Unload(,"DocumentInflow");
	
	Query = New Query();
	Query.SetParameter("RevenueTable_",ReceiptDocuments);
	Query.SetParameter("CurrencyOfComplianceAccounting", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
	Query.Text = 
		"SELECT
		|	RevenueTable_.DocumentInflow
		|INTO RevenueTable_
		|FROM
		|	&RevenueTable_ AS RevenueTable_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RevenueTable_.DocumentInflow
		|FROM
		|	RevenueTable_ AS RevenueTable_
		|WHERE
		|	NOT RevenueTable_.DocumentInflow.Currency = &CurrencyOfComplianceAccounting";
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

&AtServer
Procedure VendorOnChangeServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Vendor, Object.VendorSCounterparty);
	FillInFormDetails(True);
	CustomizeFormElements();
	UpdateInformationOnReceipts();
	OsichitEconomicOperation();
	
EndProcedure

&AtServer
Procedure VendorSCounterpartyOnChangeServer()
	
	UpdateInformationOnReceipts();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
		
		CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
			Object.CompanyBankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
		
		FillInSubordinatePropertiesForStatistics("Organization");
		
		EstablishUseOfExcisableItems();
		UpdateVATAmount();
		UpdateDocumentAmountOnForm();
		
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
	FillInFormDetails(True);
	CustomizeFormElements();
	
	RecalculateNumberOfRNPT();
	OsichitEconomicOperation();
	
EndProcedure

&AtServer
Procedure RegistrationOptionOnChangeServer(CurrencyChanged)
		
	FillInFormDetails();
	
	If SettlementsWithCustoms Then

		Object.PaymentMethod = Enums.PaymentForms.BankAccountPayment;
				
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		CustomizeFormElements();
		
	Else
		
		CustomizeFormElements();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	If ValueIsFilled(Object.Partner) Then
		Documents.CCDImport.FillInByPartner(Object, Object.Partner);
		FillInSubordinatePropertiesForStatistics("Counterparty");
	EndIf;
	
	AttributesArray = New Array;
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	AttributesArray.Add("Partner");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	FillInFormDetails(True);
	CustomizeFormElements();

EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
		If Not Catalogs.CounterpartyBankAccounts.VerifyBankAccountHolder(
			Object.CounterpartyBankAccount, Object.Counterparty) Then
			ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Object.Counterparty);
			Object.CounterpartyBankAccount =
				CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
		EndIf;
		FillInSubordinatePropertiesForStatistics("Counterparty");
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
	CustomizeFormElements();

EndProcedure

&AtServer
Procedure TermsOnChangeServer()
	
	If ValueIsFilled(Object.Terms) Then
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Object.Terms);
		Documents.CCDImport.FillInAccordingToTermsOfPurchase(Object, PurchaseConditions);
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	AttributesArray = New Array;
	AttributesArray.Add("Partner");
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	FillInFormDetails(True);
	CustomizeFormElements();
	
EndProcedure


&AtServer
Procedure DocumentReceivedWhenServerChanges(RowID)
	
	CurrentRow = Object.Goods.FindByID(RowID);
	
	If CurrentRow <> Undefined Then
		ReceiptDetails = Common.ObjectAttributesValues(CurrentRow.DocumentInflow, "PurchaseForActivity, BusinessOperation");
		CurrentRow.PurchaseForActivity = ReceiptDetails.PurchaseForActivity;
		CurrentRow.BusinessOperation  = ReceiptDetails.BusinessOperation;
	EndIf;
	
	UpdateInformationOnReceipts();
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		
		FillInDefaultContract();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
	
	If Not ValueIsFilled(Object.CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = LocalAccountingCurrency;
		Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
			ParametersOfAccount);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	FillInFormDetails(True);
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm,"Date");
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	EstablishUseOfExcisableItems();
	UpdateVATAmount();
	UpdateDocumentAmountOnForm();
	
EndProcedure

#EndRegion

#Region ProcessingFormCommandsOnServer

&AtServer
Procedure AllocateAmongGoodsServer(DistributeCustomsValue = True)
	Filter = New Structure("SectionNumber");
	If DistributeCustomsValue Then
		ListOfSectionLines = Items.Sections.SelectedRows;
	Else
		ListOfSectionLines = New Array();
		ListOfSectionLines.Add(Items.Sections.CurrentRow);
	EndIf;
	Sections = ProcessingOfTabularFormsClientServer.CollectionItems(Object.Sections, ListOfSectionLines);
	For Each Section In Sections Do
		Filter.SectionNumber = Section.SectionNumber;
		ProductsOfSection = Object.Goods.Unload(Filter); // Array of LineOfATabularSection
		
		If ProductsOfSection.Count() > 0 Then
			Coefficients = ProductsOfSection.UnloadColumn("CustomsValue");
			If UseExcisableGoods And Section.ExciseTaxAmount <> 0 Then
				For Each OwnGoods In ProductsOfSection Do
					If ValueIsFilled(OwnGoods.ExciseTaxAmount) Then
						Coefficients[OwnGoods.LineNumber-1] = Coefficients[OwnGoods.LineNumber-1] + OwnGoods.ExciseTaxAmount;
					EndIf;
				EndDo;
			EndIf;
			If DistributeCustomsValue Then
				NewAmounts = Common.DistributeAmountInProportionToCoefficients(Section.CustomsValue, Coefficients);
				If NewAmounts <> Undefined Then
					ProductsOfSection.LoadColumn(NewAmounts, "CustomsValue");
				EndIf;
			EndIf;	
			NewAmounts = Common.DistributeAmountInProportionToCoefficients(Section.DutyAmount, Coefficients);
			If NewAmounts <> Undefined Then
				ProductsOfSection.LoadColumn(NewAmounts, "DutyAmount");
			EndIf;
			NewAmounts = Common.DistributeAmountInProportionToCoefficients(Section.VATAmount, Coefficients);
			If NewAmounts <> Undefined Then
				ProductsOfSection.LoadColumn(NewAmounts, "VATAmount");
			EndIf;
		EndIf;
		
		For Each OwnGoods In ProductsOfSection Do
			Object.Goods[OwnGoods.LineNumber-1].VATRate = Section.VATRate;
			Object.Goods[OwnGoods.LineNumber-1].DutyRate = Section.DutyRate;
			If DistributeCustomsValue Then
				Object.Goods[OwnGoods.LineNumber-1].CustomsValue = ?(Section.CustomsValue <> 0., OwnGoods.CustomsValue, 0.);
			EndIf;	
			Object.Goods[OwnGoods.LineNumber-1].DutyAmount = ?(Section.DutyAmount <> 0., OwnGoods.DutyAmount, 0.);
			Object.Goods[OwnGoods.LineNumber-1].VATAmount = ?(Section.VATAmount <> 0., OwnGoods.VATAmount, 0.);
		EndDo;
	EndDo;
		
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
EndProcedure

&AtServer
Procedure CalculateByGoodsServer()
	Filter = New Structure("SectionNumber");
	Sections = ProcessingOfTabularFormsClientServer.CollectionItems(Object.Sections, Items.Sections.SelectedRows);
	For Each Section In Sections Do
		Filter.SectionNumber = Section.SectionNumber;
		ProductsOfSection = Object.Goods.FindRows(Filter);
		If ProductsOfSection.Count() > 0 Then
			Section.CustomsValue = 0.;
			Section.ExciseTaxAmount = 0;
			RecalculateFields(Section, "DutyAmount, VATAmount", Section, Object.UseSections);
			For Each OwnGoods In ProductsOfSection Do
				Section.CustomsValue = Section.CustomsValue + OwnGoods.CustomsValue;
				Section.DutyAmount = Section.DutyAmount + OwnGoods.DutyAmount;
				Section.VATAmount = Section.VATAmount + OwnGoods.VATAmount;
				Section.ExciseTaxAmount = Section.ExciseTaxAmount + OwnGoods.ExciseTaxAmount;
			EndDo;
			RecalculateFields(Section, "DutyRate", Section, Object.UseSections);
		EndIf;
	EndDo;
	
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
EndProcedure

&AtServer
Procedure ProcessingAddProductsSelection(ValueSelected, SectionData, DeleteRows_1, AddressName_ = Undefined, TabSectionName=Undefined, ToFillCost = False)
	
	StructureOfActions = New Structure;
	If Not Object.UseSections Then
		VATAccountingSettings = VATAccountingERP.AccountingSettings();
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		ParametersFillInVATRate.VATTaxation = VATAccountingSettings.MainActivityVATProcurement;
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	EndIf;
	If UseExcisableGoods Then
		ParametersForRecalculationOfExciseTaxAmount =
			BatchProcessingOfTablePartClientServer.ParametersForRecalculationOfExciseTaxAmount(Object, True);
		StructureOfActions.Insert("RecalculateExciseTaxAmount", ParametersForRecalculationOfExciseTaxAmount);
	EndIf;
	
	SetActionsForAdditionalProductAttributes(StructureOfActions);
	
	If DeleteRows_1 Then
		DeleteLines = Object.Goods.FindRows(New Structure("SectionNumber", SectionData.SectionNumber));
		For Each DeletionRow In DeleteLines Do
			Object.Goods.Delete(DeletionRow);
		EndDo;
	EndIf;
	
	If AddressName_<>Undefined Then
		ProductBuffer = GetFromTempStorage(ValueSelected[AddressName_]);
		If TabSectionName<>Undefined Then
			ProductBuffer = ProductBuffer[TabSectionName];
		EndIf;
	Else
		ProductBuffer = GetFromTempStorage(ValueSelected);
	EndIf;
	
	RowsToProcess = New Array;
	
	For Each BufferElement In ProductBuffer Do
		OwnGoods = Object.Goods.Add();
		FillPropertyValues(
			OwnGoods, 
			BufferElement);
		If ToFillCost Then
			OwnGoods.CustomsValue = BufferElement.Sum;
		EndIf;
		If Object.UseSections Then
			FillPropertyValues(OwnGoods, SectionData, "SectionNumber, VATRate, DutyRate, OriginCountry");
		EndIf;
		UpdateTheseLinesWhenChangingSerialNumberOfProduct(OwnGoods, Object);
		RowsToProcess.Add(OwnGoods);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
			
	For Each OwnGoods In RowsToProcess Do
		RecalculateFields(OwnGoods, "DutyAmount, VATAmount", SectionData, Object.UseSections);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	UpdateInformationOnReceipts();
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
	
	RecalculateAmountsInPartitionsAtServer(SectionData);
	
EndProcedure

&AtServer
Procedure SetCostServer(Val PriceKind = Undefined, FilterOfProducts_ = Undefined)
	If FilterOfProducts_ = Undefined Then
		ProductsFilling = ProcessingOfTabularFormsClientServer.CollectionItems(Object.Goods, Items.Goods.SelectedRows);
	Else
		ProductsFilling = Object.Goods.FindRows(FilterOfProducts_);
	EndIf;
	PriceKind = ?(ValueIsFilled(PriceKind), PriceKind, Catalogs.VendorPriceTypes.EmptyRef());
	
	FillParameters = New Structure;
	FillParameters.Insert("PopulationFields",    "Price");
	FillParameters.Insert("Date",              DocumentDateServer(Object.Date));
	FillParameters.Insert("Currency",            Object.Currency);
	FillParameters.Insert("VendorPriceKind", PriceKind);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, ProductsFilling, FillParameters);
	
	Actions = New Structure;
	SetActionsForAdditionalProductAttributes(Actions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;
	CurrentSection = -1;
	For Each OwnGoods In ProductsFilling Do
		If CurrentSection <> OwnGoods.SectionNumber Then
			CurrentSection = OwnGoods.SectionNumber;
			Found4 = Object.Sections.FindRows(New Structure("SectionNumber", CurrentSection));
			SectionData = ?(Found4.Count() > 0, Found4[0], EmptyPartitionData());
		EndIf;
		OwnGoods.CustomsValue = OwnGoods.NumberOfPackages * OwnGoods.Price;
		RowsToProcess.Add();
		RecalculateFields(OwnGoods, "DutyAmount, VATAmount", SectionData, Object.UseSections);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		Actions,
		Object.Goods,
		CachedValues);
	
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
EndProcedure

#EndRegion

#Region FormTablesSupport

&AtClient
Procedure ActivateSection()
	Selection_Section = CurPartitionData(Items.Sections).SectionNumber;
	BySections = Not Items.GoodsShowAllGoods.Check;
	Goods = Items.Goods;
	If BySections And (Goods.RowFilter = Undefined Or Goods.RowFilter.SectionNumber <> Selection_Section) Then // enable selection
		Goods.RowFilter = New FixedStructure("SectionNumber", Selection_Section);
	ElsIf Not BySections And Goods.RowFilter<>Undefined Then // turn off selection
		Goods.RowFilter = Undefined;
	EndIf; // don't change anything
EndProcedure

&AtClientAtServerNoContext
Function NewSectionNumber(Sections)
	MaxNumber = 0;
	For Each Section In Sections Do
		If Section.SectionNumber > MaxNumber Then
			MaxNumber = Section.SectionNumber;
		EndIf;
	EndDo;
	Return MaxNumber + 1;
EndFunction

&AtServer
Procedure ClearProductSectionNumbers(OldNumbers)
	For Each OwnGoods In Object.Goods Do
		If OldNumbers[OwnGoods.SectionNumber]<>Undefined Then
			OwnGoods.SectionNumber = 0;
		EndIf;
	EndDo;
	Selection = Items.GoodsSectionNumber.ChoiceList;
	For Each OldNumber In OldNumbers Do
		FoundItem = Selection.FindByValue(OldNumber.Value);
		Selection.Delete(FoundItem);
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Procedure ReplaceItemInSelectionList(Selection, PreviousValue2, NewValue, Format);
	ChoiceItem = Selection.FindByValue(PreviousValue2);
	If Undefined <> ChoiceItem Then
		Selection.Delete(ChoiceItem);
	EndIf;
	ChoiceItem = Selection.FindByValue(PreviousValue2);
	If Undefined = ChoiceItem Then
		Selection.Add(NewValue, Format(NewValue, Format));
	EndIf;
	Selection.SortByValue();
EndProcedure

&AtClientAtServerNoContext
Function CurPartitionData(Sections)
	SectionData = EmptyPartitionData();
	If Sections.CurrentData <> Undefined Then
		FillPropertyValues(SectionData, Sections.CurrentData);
	EndIf;
	Return SectionData;
EndFunction

&AtClientAtServerNoContext
Function EmptyPartitionData()
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("SectionNumber",        0);
	ReturnStructure.Insert("DutyRate",       0.);
	ReturnStructure.Insert("VATRate",           Undefined);
	ReturnStructure.Insert("Warehouse",               Undefined);
	ReturnStructure.Insert("OriginCountry", Undefined);
	
	Return ReturnStructure;
	
EndFunction

&AtClientAtServerNoContext
Procedure RecalculateFields(CurrentData, Val RecalculationFields, Val SectionData, Val UseSections)
	
	RecalculationFields = Lower(RecalculationFields);
	If StrFind(RecalculationFields, "dutyamount")>0 Then
		If UseSections Then
			CurrentData.DutyRate = SectionData.DutyRate;
		EndIf;
		CurrentData.DutyAmount = CurrentData.CustomsValue * CurrentData.DutyRate / 100.;
	ElsIf StrFind(RecalculationFields, "dutyrate")>0 Then
		CurrentData.DutyRate =
			100. * ?(CurrentData.CustomsValue=0., 0., CurrentData.DutyAmount / CurrentData.CustomsValue);
	EndIf;
	If StrFind(RecalculationFields, "vatamount")>0 Then
		If UseSections Then
			CurrentData.VATRate = SectionData.VATRate;
		EndIf;
		CurrentData.VATAmount =
			PriceManagementSystemClientServer.CalculateVATAmount(
				CurrentData.CustomsValue + CurrentData.DutyAmount + CurrentData.ExciseTaxAmount,
				CurrentData.VATRate,
				False);
	EndIf;
EndProcedure

// Value Fields-Structure ("Field1, Field2,...", Value1, Value2, ...)
&AtServer
Procedure FillInTabpartyFields(TabSectionName, ValueFields, FilterTabSections = Undefined)
	If FilterTabSections = Undefined Then
		Rows =
			ProcessingOfTabularFormsClientServer.CollectionItems(Object[TabSectionName], Items[TabSectionName].SelectedRows);
	Else
		Rows = Object[TabSectionName].FindRows(FilterTabSections);
	EndIf;
	For Each String In Rows Do
		FillPropertyValues(String, ValueFields);
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Function SectionNumberIsUnique(Sections, SectionNumber)
	NumberMet = False;
	For Each Section In Sections Do
		If NumberMet And (Section.SectionNumber = SectionNumber) Then
			Return False;
		EndIf;
		NumberMet = NumberMet Or (Section.SectionNumber = SectionNumber);
	EndDo;
	Return True;
EndFunction

&AtServer
Procedure UpdateVATAmount()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	If UseExcisableGoods Then
		
		ParametersForFillingInExcisableItemAttribute =
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object);
		ParametersForRecalculationOfExciseTaxAmount =
			BatchProcessingOfTablePartClientServer.ParametersForRecalculationOfExciseTaxAmount(Object, True);
		
		StructureOfActions.Insert("FillInExcisableItemAttribute", ParametersForFillingInExcisableItemAttribute);
		StructureOfActions.Insert("RecalculateExciseTaxAmount", ParametersForRecalculationOfExciseTaxAmount);
		
	EndIf;
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	For Each String In Object.Goods Do
		If Not UseExcisableGoods Then
			String.ExciseTaxAmount = 0;
		EndIf;
		String.VATAmount =
			PriceManagementSystemClientServer.CalculateVATAmount(
				String.CustomsValue + String.DutyAmount + String.ExciseTaxAmount,
				String.VATRate,
				False);
	EndDo;
	
	If Object.UseSections Then
		
		AmountsBySection = Object.Goods.Unload(, "SectionNumber, ExciseTaxAmount");
		AmountsBySection.GroupBy("SectionNumber","ExciseTaxAmount");
		AmountsBySection.Indexes.Add("SectionNumber");
		
		For Each Section In Object.Sections Do
			SectionRow = AmountsBySection.Find(Section.SectionNumber, "SectionNumber");
			If SectionRow <> Undefined Then
				Section.ExciseTaxAmount = SectionRow.ExciseTaxAmount;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecalculateAmountsInSection(ForAllSections = False)
	
	If Not Object.UseSections Or Not UseExcisableGoods Then
		Return;
	EndIf;
	
	If ForAllSections Then
		Sections = Object.Sections;
	Else
		ListOfSectionLines = CommonClientServer.ValueInArray(Items.Sections.CurrentRow);
		Sections = ProcessingOfTabularFormsClientServer.CollectionItems(Object.Sections, ListOfSectionLines);
	EndIf;
	
	Filter = New Structure("SectionNumber");
	
	For Each Section In Sections Do
	
		Section.ExciseTaxAmount = 0;
		
		Filter.SectionNumber = Section.SectionNumber;
		ProductsOfSection = Object.Goods.FindRows(Filter);
		For Each SectionRow In ProductsOfSection Do
			Section.ExciseTaxAmount = Section.ExciseTaxAmount + SectionRow.ExciseTaxAmount;
		EndDo;
	
	EndDo;
	
EndProcedure

&AtServer
Procedure RecalculateAmountsInPartitionsAtServer(SectionData)
	
	If Not Object.UseSections Or Not UseExcisableGoods Then
		Return;
	EndIf;
	
	Filter = New Structure("SectionNumber", SectionData.SectionNumber);
	Sections = Object.Sections.Unload(Filter, "LineNumber");
	For Each SectionRow In Sections Do
		ProductsOfSection = Object.Goods.Unload(Filter, "ExciseTaxAmount");
		ProductsOfSection.GroupBy(,"ExciseTaxAmount");
		Section = Object.Sections[SectionRow.LineNumber-1];
		Section.ExciseTaxAmount = ProductsOfSection[0].ExciseTaxAmount;
	EndDo;
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "")
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text)Then
		ExceptionText = NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - để chỉ ra sê-ri trong chứng từ này, không cần gọi ra Server.';
							|ru = 'Ошибка при попытке указать серии - в этом документе для указания серий не нужен серверный вызов.';
							|en = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.'; fa = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.';
							|it = 'Si è verificato un errore durante il tentativo di indicare le serie - in questo documento non è necessaria la chiamata al server per indicare le serie.';
							|pl = 'Błąd podczas próby określenia serii - w tym dokumencie nie jest wymagane wywołanie serwera, aby wskazać serię.';
							|tr = 'Bir parti belirtmeye çalışırken hata oluştu - bu belgede bir parti belirtmek için sunucu çağrısı gerekmez.'");
		Raise ExceptionText;
	EndIf;
EndProcedure

#EndRegion

#Region Other

&AtServer
Function PutInStorage(TabSectionName, FieldsNames, FilterParameters)
	Return PutToTempStorage(Object[TabSectionName].Unload(FilterParameters, FieldsNames), UUID);
EndFunction

&AtServer
Procedure OnReadCreateAtServer()
	
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	FillInFormDetails();
	EstablishUseOfExcisableItems();
	FillInAdditionalProductAttributes();
	FillInSerialNumberOfProductInProductsServerTable();
	CustomizeFormElements();
	ConfigurePartitionSelection();
	
	// The division number.The maximum value MUST be set for normal operation.
	SectionNumberLimit = Metadata.Documents.CCDImport.TabularSections.Sections.Attributes.SectionNumber.MaxValue;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
																									Documents.CCDImport));
	
	UpdateInformationOnReceipts();
	
	CorrectPeriod = PurchasesServer.CorrectPeriodForEnteringDocumentsCustomsDeclarationNumbers();
	
	BeginningOfCorrectPeriod = CorrectPeriod.BeginningOfCorrectPeriod;
	EndOfCorrectPeriod  = CorrectPeriod.EndOfCorrectPeriod;
	
	CurrentTextDeclarationNumbers = Object.DeclarationNo;
	
	UpdateInformationAboutErrorsInNumber(CurrentTextDeclarationNumbers, 
									   BeginningOfCorrectPeriod, 
									   EndOfCorrectPeriod, 
									   Items.ErrorInTheCustomsDeclarationNumber);
	
EndProcedure

&AtServer
Procedure FillInFormDetails(UpdateObject = False)
	
	If Not ValueIsFilled(DocumentCurrency) Then
		DocumentCurrency = Object.Currency;
	EndIf;
	SettlementsWithCustoms = (Object.RegistrationOption = Enums.BusinessTransactions.RegisterCCDUnassisted);
	DocumentStatus = Object.Status;
		
	VATAccountingERP.SetTitleOfStateOfVATPaymentOnInvoice(
		Object.Ref,
		Items.InvoicePaymentStatus,
		Object.PaymentViaSinglePersonalAccount);
		
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
EndProcedure

&AtClientAtServerNoContext
Function DifferencesInTotals(Sections, Goods)
	Return New Structure("DifferenceOfCosts, DifferenceOfDuties, VATDifference",
		Sections.Total("CustomsValue") - Goods.Total("CustomsValue"),
		Sections.Total("DutyAmount") - Goods.Total("DutyAmount"),
		Sections.Total("VATAmount") - Goods.Total("VATAmount")); // client-server optimizations
EndFunction

&AtServer
Procedure SetActionsForAdditionalProductAttributes(Actions)
	Actions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	Actions.Insert("RecalculateNumberOfUnits");
	If UseExcisableGoods Then
		ParametersForFillingInExcisableItemAttribute =
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object);
		Actions.Insert("FillInExcisableItemAttribute", ParametersForFillingInExcisableItemAttribute);
	EndIf;
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(Actions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions,
		"Warehouse",
		True);
		
EndProcedure

&AtServer
Procedure SetStockTypeSelectionParameters()
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization"));
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups") Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.Products", "Items.Goods.CurrentData.Products"));
	EndIf;
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByVendors") Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.Vendor", "Object.Vendor"));
	EndIf;
	Items.GoodsInventoryOwnerAttribute.ChoiceParameterLinks = New FixedArray(ParametersArray);
EndProcedure

&AtServer
Procedure FillInAdditionalProductAttributes()
	Actions = New Structure;
	SetActionsForAdditionalProductAttributes(Actions);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, Actions, Undefined);
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	Items.Counterparty.Title = ?(SettlementsWithCustoms, NStr("vi = 'Đối tác hải quan';
																|ru = 'Контрагент таможни';
																|en = 'Customs counterparty'; fa = 'Customs counterparty';
																|it = 'Contraente doganale';
																|pl = 'Kontrahent urzędu celnego';
																|tr = 'Gümrük cari hesabı'"), NStr("vi = 'Đối tác môi giới';
																									|ru = 'Контрагент брокера';
																									|en = 'Broker counterparty'; fa = 'Broker counterparty';
																									|it = 'Contraente  del broker';
																									|pl = 'Kontrahent brokera';
																									|tr = 'Aracı cari hesabı'"));
	Items.CounterpartyBankAccount.Title = ?(SettlementsWithCustoms,
		NStr("vi = 'Tài khoản của đối tác thông quan';
			|ru = 'Счет контрагента таможни';
			|en = 'Customs counterparty account'; fa = 'Customs counterparty account';
			|it = 'Счет контрагента таможни';
			|pl = 'Customs counterparty account';
			|tr = 'Gümrük cari hesabı'"),
		NStr("vi = 'Tài khoản của đối tác môi giới';
			|ru = 'Счет контрагента брокера';
			|en = 'Broker counterparty account'; fa = 'Broker counterparty account';
			|it = 'Счет контрагента брокера';
			|pl = 'Broker counterparty account';
			|tr = 'Komisyoncu cari hesabı'"));
	
	PartnerSelectionParameters = New Array;
	If SettlementsWithCustoms Then
		PartnerSelectionParameters.Add(New ChoiceParameter("Filter.OtherRelations", SettlementsWithCustoms));
	Else
		PartnerSelectionParameters.Add(New ChoiceParameter("Filter.Vendor", True));
	EndIf;
	Items.Partner.ChoiceParameters = New FixedArray(PartnerSelectionParameters);
	
	Items.GroupExpenses.Visible = GetFunctionalOption("UseAccountingOfOtherIncomeExpenses");
	
	Items.Terms.Enabled = Not SettlementsWithCustoms;
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	Items.Contract.MarkIncomplete =
		Items.Contract.Enabled And ValueIsFilled(Object.Terms) And Not ValueIsFilled(Object.Contract);
		
	CurrenciesOfDocumentAndLocalAccountingAreDifferent = Object.Currency <> LocalAccountingCurrency;
	If CurrenciesOfDocumentAndLocalAccountingAreDifferent Then
		TitleTextExciseTaxAmount = StrTemplate(NStr("vi = 'Số tiền thuế tiêu thụ đặc biệt, %1';
													|ru = 'Сумма акциза, %1';
													|en = 'Excise amount, %1'; fa = 'Excise amount, %1';
													|it = 'Excise amount, %1';
													|pl = 'Excise amount, %1';
													|tr = 'Tüketim vergisi tutarı, %1'"), LocalAccountingCurrency);
	Else
		TitleTextExciseTaxAmount = NStr("vi = 'Số tiền thuế tiêu thụ đặc biệt';
										|ru = 'Сумма акциза';
										|en = 'Excise amount'; fa = 'مبلغ عوارض';
										|it = 'Importo accisa';
										|pl = 'Wartość akcyzy';
										|tr = 'Tüketim tutarı'");
	EndIf;
	Items.SectionsExciseTaxAmount.Title = TitleTextExciseTaxAmount;
	Items.GoodsExciseTaxAmount.Title = TitleTextExciseTaxAmount;
	Items.LocalAccountingCurrencySections.Visible = CurrenciesOfDocumentAndLocalAccountingAreDifferent;
	Items.LocalAccountingCurrency.Visible = CurrenciesOfDocumentAndLocalAccountingAreDifferent;
	Items.ResultsSectionsExciseSections.Visible = UseExcisableGoods;
	Items.ResultsGoodsAmountOfExciseDuty.Visible = UseExcisableGoods;
	
	ConfigureFillingServices(Items, Object);
	SetStockTypeSelectionParameters();
EndProcedure

&AtServer
Procedure ConfigurePartitionSelection()
	Selection = Items.GoodsSectionNumber.ChoiceList;
	Selection.Clear();
	For Each Section In Object.Sections Do
		Selection.Add(Section.SectionNumber, Format(Section.SectionNumber, Items.GoodsSectionNumber.Format));
	EndDo;
	Selection.SortByValue();
	Selection.Insert(0, 0, Format(0, Items.GoodsSectionNumber.Format));
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureFillingServices(Items, Object)
	BySections = Not Items.GoodsShowAllGoods.Check;
	
	Items.GoodsSelectFromReceipt.Enabled = BySections;
	Items.GoodsSelectGoods.Enabled = BySections;
	Items.GoodsSelectFromTheDesign.Enabled = BySections;
	
	Items.GoodsFillInTheSectionNumber.Enabled = Not BySections;
	Items.GoodsSetThePartitionNumber.Enabled = Not BySections;
		
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	OperationsOfSelectionOfAgreementsContracts = Documents.CCDImport.OperationsOfSelectionOfAgreementsContracts();
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Object.ARAPCurrency;
	Contract = PurchasesServer.GetDefaultContract(
		Object, OperationsOfSelectionOfAgreementsContracts, AddlParameters);
	If (Contract <> Object.Contract) Then
		Object.Contract = Contract;
		PurchasesServerCall.FillInBankAccountsUnderAgreement(
			Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
		FillInSubordinatePropertiesForStatistics("Contract");
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
EndProcedure

&AtClient
Function DocumentDate(DateObject)
	Return ?(ValueIsFilled(DateObject), DateObject, CommonClient.SessionDate());
EndFunction

&AtServer
Function DocumentDateServer(DateObject)
	Return ?(ValueIsFilled(DateObject), DateObject, CurrentSessionDate());
EndFunction

&AtClient
Procedure SelectVendorsPriceType(VendorPriceKind,ForBlankLines)
	
	VendorPriceKind = DefaultVendorPriceView(DocumentDate(Object.Date), Object.Vendor);
	
	If VendorPriceKind = Undefined Then
		PickingParameters = New Structure;
		PickingParameters.Insert("Filter", New Structure("Owner", Object.Vendor));
		
		OpenForm("Catalog.VendorPriceTypes.ChoiceForm", 
			PickingParameters,,,,,
			New CallbackDescription("SelectVendorsPriceTypeCompletion",ThisObject, New Structure("ForBlankLines", ForBlankLines)),
			FormWindowOpeningMode.LockOwnerWindow);
	Else
		SetCost(VendorPriceKind, ForBlankLines);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectVendorsPriceTypeCompletion(Result, AddlParameters) Export
	
	VendorPriceKind = Result;
	ForBlankLines = AddlParameters.ForBlankLines;
	
	If ValueIsFilled(VendorPriceKind) Then
		SetCost(VendorPriceKind, ForBlankLines);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCost(VendorPriceKind, ForBlankLines)
	If ForBlankLines Then
		SetCostServer(VendorPriceKind, New Structure("CustomsValue", 0.));
	Else
		SetCostServer(VendorPriceKind);
	EndIf;
EndProcedure

&AtServerNoContext
Function DefaultVendorPriceView(DocumentDate, Partner)
	SetPrivilegedMode(True);
	
	Query = New Query("
		|SELECT DISTINCT TOP 2
		|	Prices.VendorPriceKind
		|FROM
		|	InformationRegister.ItemsPricesOfVendor AS Prices
		|WHERE
		|	Prices.Partner = &Partner
		|	AND Prices.Period <= ENDOFPERIOD(&DocumentDate, DAY)
		|");
	Query.SetParameter("DocumentDate", DocumentDate);
	Query.SetParameter("Partner", Partner);
	Selection = Query.Execute().Select();
	
	If Selection.Count() > 1 Then
		Return Undefined;
	ElsIf Selection.Count() = 0 Then
		Return Catalogs.VendorPriceTypes.EmptyRef();
	EndIf;
	While Selection.Next() Do
		Return Selection.VendorPriceKind;
	EndDo;
EndFunction

&AtClientAtServerNoContext
Function DeclarationNoForInvoice(DeclarationNo, ExtensionNumber)
	DeclarationNoForInvoice = DeclarationNo;
	If ValueIsFilled(ExtensionNumber) Then
		DeclarationNoForInvoice = DeclarationNo + "/" + ExtensionNumber;
	EndIf;	
	Return DeclarationNoForInvoice;
EndFunction

&AtServer
Procedure SetUpAWarehouseServer(PlacementWarehouse)
	
	FillInTabpartyFields("Goods", New Structure("Warehouse", PlacementWarehouse));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure UpdateInformationOnReceipts()
	
	ReceiptsList.Clear();
	For Each CurRow In Object.Goods Do
		If ValueIsFilled(CurRow.DocumentInflow) And ReceiptsList.FindByValue(CurRow.DocumentInflow) = Undefined Then
			ReceiptsList.Add(CurRow.DocumentInflow);
		EndIf;
	EndDo;
	
	If ReceiptsList.Count() = 1 Then
		UninvoicedReceipt = ReceiptsList[0].Value;
	EndIf;
	
	If ReceiptsList.Count() > 1 Then
		ReceiptHeaderText = StrReplace(
			NStr("vi = 'Tất cả chứng từ: %NumberOfReceipts_%';
				|ru = 'Всего документов: %NumberOfReceipts_%';
				|en = 'Total documents: %NumberOfReceipts_%'; fa = 'Total documents: %NumberOfReceipts_%';
				|it = 'Totale documenti: %NumberOfReceipts_%';
				|pl = 'Razem dokumentów: %NumberOfReceipts_%';
				|tr = 'Tüm belgeler: %NumberOfReceipts_%'"), 
			"%NumberOfReceipts_%",
			ReceiptsList.Count());
		UninvoicedReceipt = Undefined;
	EndIf;
	
	If ReceiptsList.Count() < 1 Then
		UninvoicedReceipt = Undefined;
	EndIf;
	
	If ReceiptsList.Count() <= 1 Then
		Items.PagesReceipts.CurrentPage = Items.PageReceipt;
	Else
		Items.PagesReceipts.CurrentPage = Items.PageReceipts;
	EndIf;
	
EndProcedure

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter, Source)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClickCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		
		ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
		If ChangedBankingDetails.Count() > 0 Then
			LabelCurrenciesClickCompletionServer(ClosingResult);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure FillInSerialNumberOfProductInProductsServerTable()
	
	CCDNumbersOfGoods = Object.Goods.Unload(,"CCDNumber");
	CCDNumbersOfGoods.GroupBy("CCDNumber","");
	
	SerialNumbersOfGoodsByCCDNumbers = GeneralPurposeTMServerCall.ObjectsAttributeValue(CCDNumbersOfGoods.UnloadColumn("CCDNumber"), "GoodsSequenceNumber");
	For Each RowOfProduct In Object.Goods Do
		ProductLineSerialNumberOfProduct = "";
		GoodsSequenceNumber = SerialNumbersOfGoodsByCCDNumbers[RowOfProduct.CCDNumber];
		If ValueIsFilled(RowOfProduct.CCDNumber) And ValueIsFilled(GoodsSequenceNumber) Then
			ProductLineSerialNumberOfProduct = GoodsSequenceNumber;
		ElsIf ValueIsFilled(RowOfProduct.DeclarationNoForInvoice) Then
			ProductLineSerialNumberOfProduct = Catalogs.CCDNumbers.SerialNumberOfGoodsFromNumberOfCustomsDeclaration(RowOfProduct.DeclarationNoForInvoice);
		EndIf;	
		If ProductLineSerialNumberOfProduct <> RowOfProduct.GoodsSequenceNumber Then
			RowOfProduct.GoodsSequenceNumber = ProductLineSerialNumberOfProduct;
		EndIf;	
	EndDo;	
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateInformationAboutErrorsInNumber(CurrentTextDeclarationNumbers, 
											 BeginningOfCorrectPeriod, 
											 EndOfCorrectPeriod, 
											 ElementErrorInCustomsDeclarationNumber)

	CheckResult = VATAccountingClientServerLocalization.CheckCorrectnessOfCustomsDeclarationNumber(
		CurrentTextDeclarationNumbers, BeginningOfCorrectPeriod, EndOfCorrectPeriod);
		
	ElementErrorInCustomsDeclarationNumber.Title = VATAccountingClientServerLocalization.TextOfErrorInCustomsDeclarationNumber(CheckResult.ErrorCode);
	ElementErrorInCustomsDeclarationNumber.Visible = (Not CheckResult.ErrorCode = 0);

EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If ValueIsFilled(Object.Organization) Then
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Warehouse",
												True);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
	EndIf;
	
EndProcedure

&AtServer
Procedure OsichitEconomicOperation()
	
	For Each RowOfGoods In Object.Goods Do
		RowOfGoods.BusinessOperation = Undefined;
	EndDo;
	
EndProcedure

&AtServer
Procedure EstablishUseOfExcisableItems()
	
	UseExcisableGoods =
		ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(Object.Organization, Object.Date);
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
EndProcedure

&AtServer
Function FillInSubordinatePropertiesForStatistics(ParentPropsName)
	Return ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndFunction

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard(SectionData)
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	
	Columns = "Products,Characteristic,Package,NumberOfPackages";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	Actions = New Structure;
	If UseExcisableGoods Then
		ParametersForRecalculationOfExciseTaxAmount =
			BatchProcessingOfTablePartClientServer.ParametersForRecalculationOfExciseTaxAmount(Object, True);
		Actions.Insert("RecalculateExciseTaxAmount", ParametersForRecalculationOfExciseTaxAmount);
	EndIf;
		
	SetActionsForAdditionalProductAttributes(Actions);
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		OwnGoods = Object.Goods.Add();
		FillPropertyValues(OwnGoods, RowOfProduct);
		If Object.UseSections Then
			FillPropertyValues(OwnGoods, SectionData, "SectionNumber, VATRate, DutyRate, OriginCountry, Warehouse");
		EndIf;
		RowsToProcess.Add(OwnGoods);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		Actions,
		Object.Goods);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	FillPropertyValues(ThisForm, DifferencesInTotals(Object.Sections, Object.Goods));
	
	RecalculateAmountsInPartitionsAtServer(SectionData);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard() And Not Items.GoodsShowAllGoods.Check);
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		Not Items.GoodsShowAllGoods.Check);
	
EndProcedure

&AtServer
Procedure UpdateDocumentAmountOnForm()
	DocumentAmount = Documents.CCDImport.DocumentAmount(Object);
EndProcedure

#EndRegion

#EndRegion

#Region StandardBspMechanisms

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
EndProcedure


#EndRegion

#EndRegion

#Region Localization 

&AtServer
Procedure AddConditionalAppearanceLocalization()
	
	
EndProcedure

&AtClient
Procedure DeclarationNoOnChange(Item)
	
	UpdateInformationAboutErrorsInNumber(CurrentTextDeclarationNumbers, 
									   BeginningOfCorrectPeriod, 
									   EndOfCorrectPeriod, 
									   Items.ErrorInTheCustomsDeclarationNumber);
	
EndProcedure

&AtClient
Procedure SetTheNumberForTheSfizProductLineNumber(Command)
EndProcedure

&AtClient
Procedure SetTheNumberForTheSfizSection(Command)
EndProcedure


&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm);
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_Date" Then
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

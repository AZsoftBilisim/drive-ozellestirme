#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.SubcontractorReport2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	// GLAccountSettings
	SetupParameters = Documents.SubcontractorReport2_5.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	// End GLAccountSettings
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
		
	#Region StandardMechanisms
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// The connected equipment
	TMCommonUse.CustomizePeripherals(ThisObject, "ManufacturedProducts,SideAndIntermediateRelease,MaterialsAndWorks");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.SubcontractorReport2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	// GLAccountSettings
	SetupParameters = Documents.SubcontractorReport2_5.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	// End GLAccountSettings
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	BeforeWriteAtClientServer();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer()
	
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// GLAccountSettings
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End GLAccountSettings
	
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInServiceDetails();
	FillInDependentServiceDetailsOnServer();
	FillInServiceDetailsOfTableParts();
	UpdateCostGroups();
	
	// ItemsAndDimensionsSelectionParameters
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	// End ItemsAndDimensionsSelectionParameters
	
	// GLAccountSettings
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	// End GLAccountSettings
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject);
	
	CalculateDocumentTotals(ThisObject);
	CustomizeFormElements();
	SetSubscriptionForFormElementChangeEvents();
	
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_SubcontractorReport2_5", WriteParameters, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			BarcodeData_5 = EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter);
			
			If Items.GroupPages.CurrentPage = Items.ServicesPage Then
				TSName = "Services";
			ElsIf Items.GroupPages.CurrentPage = Items.GroupMaterialsAndWorks Then
				TSName = "MaterialsAndWorks";
			Else
				If TypeOf(CurrentItem) = Type("FormTable")
					And Items.GroupPages.CurrentPage = Items.OutputProductsPage Then
					
					TSName = CurrentItem.Name;
					
				Else
					TSName = "ManufacturedProducts";
				EndIf;
			EndIf;
			
			ProcessBarcodes(BarcodeData_5, TSName);
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5, Parameter.TSName);
		
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter) Then
		ProcessingAndSettlementsOnServer(EventName, Parameter);
	EndIf;
	
	If EventName = "Write_PurchaseAdjustment"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Property("DocumentBasis")
		And Parameter.DocumentBasis = Object.Ref Then
		UpdateFlagThereAreAdjustments();
		ConfigureDependentFormElements(ThisObject, "ThereAreAdjustingEntries");
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		ConfigureClipboardCommands(ThisObject, True);
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName, ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		UpdateInvoiceText(New Structure);
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		HandlingSelectionSelectionOnClient(ValueSelected, "MaterialsAndWorks");
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		HandlingSelectionSelectionOnClient(ValueSelected, "Services");
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsTransferredToCustody.Form.Form" Then
		SelectionProcessingSelectionOfTransferredGoods(ValueSelected);
	ElsIf ChoiceSource <> Undefined 
		And TypeOf(ChoiceSource) = Type("ClientApplicationForm") 
		And ChoiceSource.FormName = "CommonForm.EnterCostShare" Then
		
		CurrentData = CurrentItem.CurrentData;
		If CurrentData = Undefined Then 
			Return;
		EndIf;
		
		ProcessingInputOfFractionOfCost(CurrentItem, CurrentData, ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters[ValueSelected.TSName], ValueSelected);
		
		ProductsSeriesRecalculatePrices(, ValueSelected.TSName);
		
		If ValueSelected.TSName = "ManufacturedProducts" Then
			
			CalculatePercentageOfCostAllocationForOutputProducts();
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#Region IsMain

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If CurrentPage.Name = "MainGroup3" Then
		ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisObject);
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderInvoice_3OnChange(Item)
	
	If Object.ByOrders Then
		SelectionByOrdersToProcessors();
	Else
		
		QueryText =
			NStr("vi = 'Sản phẩm đầu ra, sản phẩm phụ, nguyên vật liệu và công việc, dịch vụ sẽ bị xóa.
				|Tiếp tục?';
				|ru = 'Выходные изделия, побочные изделия, материалы и работы, услуги будут очищены.
				|Продолжить?';
				|en = 'Finished products, by-products, materials and works, services will be cleared.
				|Continue?'; fa = 'Finished products, by-products, materials and works, services will be cleared.
				|Continue?';
				|it = 'Produzione in uscita, sottoprodotti, materiali e lavori e servizi saranno cancellati.
				|Continuare?';
				|pl = 'Wyroby wyjściowe, wyroby poboczne, materiały i prace, usługi zostaną wyczyszczone.
				|Kontynuować?';
				|tr = 'Üretilen nihai ürünler, yan nihai ürünler, malzemeler ve işler, hizmetler temizlenecektir.
				|Devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("RemoveInvoiceOnOrderCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();
	
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyWhenChangesAreMadeOnServer();
	
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer(Undefined);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure ProcessingServicesOnChange(Item)
	
	RecyclingServicesWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure GroupCostsOnChange(Item)
	
	If GroupCostsBeforeChange = Object.GroupCosts Then
		Return;
	EndIf;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.SubcontractorReport2_5.Form.DocumentForm.GroupCostsOnChange");
	
	GroupingCostsForChangesOnServer();
	
EndProcedure

&AtClient
Procedure MethodOfAllocatingFinishedProductCostsOnChange(Item)
	
	MethodForAllocatingCostsForOutputProductsWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisObject, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure CalculationsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ReportsTMClientOverridable.OpenPaymentCardWithSuppliersReport("PaymentCardWithSuppliersAccordingToDocumentsContext", Object.Ref);
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisObject, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure InvoiceTextReceivedURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	
	RegistrationParameters.Ref				= Object.Ref;
	RegistrationParameters.Date				= Object.Date;
	RegistrationParameters.Organization		= Object.Organization;
	RegistrationParameters.Counterparty			= Object.Counterparty;
	RegistrationParameters.VATTaxation	= Object.VATTaxation;
	RegistrationParameters.PurchaseOfGoodsWorksServices = True;
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(
		ThisObject,
		Var_URL,
		StandardProcessing,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#Region More

&AtClient
Procedure ManagerOnChange(Item)
	FillInSubordinatePropertiesForStatistics("Manager");
EndProcedure

&AtClient
Procedure IncomingDocumentNumberTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	ListOfReportsByNumber = ReportsOnProcessorData(Object.Ref, Object.Counterparty, Text);
	
	If ListOfReportsByNumber.Count() = 0 Then
		Return;
	EndIf;
		
	ButtonsList = New ValueList;
	If ListOfReportsByNumber.Count() = 1 Then
		QueryText = NStr("vi = 'Trong cơ sở thông tin đã tồn tại đơn hàng có số như vậy theo dữ liệu của bên nhận gia công. Tiếp tục?';
						|ru = 'В информационной базе уже существует заказ с таким же номером по данным переработчика. Продолжить?';
						|en = 'Order with the same number by subcontractor data already exists in the infobase. Continue?'; fa = 'Order with the same number by subcontractor data already exists in the infobase. Continue?';
						|it = 'Nel database informatico esiste già un ordine con stesso numero in base ai dati del subfornitore. Continuare?';
						|pl = 'W bazie informacyjnej już istnieje zamówienie o takim samym numerze według danych przetwórcy. Kontynuować?';
						|tr = 'Bilgi tabanında, fason üreticiye göre aynı numaraya sahip bir sipariş zaten mevcut. Devam edilsin mi?'");
		ButtonsList.Add("OpenOrderList", NStr("vi = 'Mở đơn hàng';
												|ru = 'Открыть заказ';
												|en = 'Open order'; fa = 'Open order';
												|it = 'Aprire ordine';
												|pl = 'Otwórz zamówienie';
												|tr = 'Siparişi aç'"));
	Else
		QueryText = NStr("vi = 'Trong cơ sở thông tin đã tồn tại các đơn hàng có số như vậy theo dữ liệu của bên nhận gia công. Tiếp tục?';
						|ru = 'В информационной базе уже существуют заказы с таким же номером по данным переработчика. Продолжить?';
						|en = 'Orders with the same number by subcontractor data already exist in the infobase. Continue?'; fa = 'Orders with the same number by subcontractor data already exist in the infobase. Continue?';
						|it = 'Nel database informatico esistono già gli ordini con stesso numero in base ai dati del subfornitore. Continuare?';
						|pl = 'W bazie informacyjnej już istnieją zamówienia o takim samym numerze według danych przetwórcy. Kontynuować?';
						|tr = 'Bilgi tabanında, fason üreticiye göre aynı numaraya sahip siparişler zaten mevcut. Devam edilsin mi?'");
		ButtonsList.Add("OpenOrderList", NStr("vi = 'Mở danh sách đơn hàng';
												|ru = 'Открыть список заказов';
												|en = 'Open order list'; fa = 'باز کردن فهرست سفارش‌ها';
												|it = 'Aprire elenco ordini';
												|pl = 'Otwórz listę zamówień';
												|tr = 'Sipariş listesini aç'"));
	EndIf;
	
	ButtonsList.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Continue';
									|tr = 'Devam et'"));
	
	CallbackDescription =
		New CallbackDescription(
			"IncomingDocumentNumberTextEditEndCompletion",
			ThisObject,
			New Structure("OrderList", ListOfReportsByNumber));
	
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	PriceIncludesVATWhenChangedOnServer(CachedValues);
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	TaxationOfVATWhenChangingOnServer();
EndProcedure

&AtClient
Procedure PurchaseForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	If ValueIsFilled(Object.PriceKind)
		And (Object.SideAndIntermediateRelease.Count()
			Or Object.MaterialsAndWorks.Count()) Then
		
		CallbackDescription = New CallbackDescription("PriceKindOnChangeCompletion", ThisObject);
		QueryText = NStr("vi = 'Điền lại đơn giá vào các phần bảng?';
						|ru = 'Перезаполнить цены в табличных частях?';
						|en = 'Refill prices in tables?'; fa = 'Refill prices in tables?';
						|it = 'Ricompilare i prezzi nelle parti tabellari?';
						|pl = 'Wypełnić ponownie ceny w sekcjach tabelarycznych?';
						|tr = 'Tablo bölümlerinde fiyatlar yeniden doldurulsun mu?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	DirectionOfActivityWhenChangingOnServer();
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProducts

&AtClient
Procedure ManufacturedProductsSelection(Item, RowSelected, Field, StandardProcessing)
	TableSelection("ManufacturedProducts", Field, StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ProcessingSelectionOfSelectionOnServer(ValueSelected, "ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsOnStartEdit(Item, NewRow, Copy)
	TableAtBeginningOfEditing("ManufacturedProducts", NewRow, Copy);
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeDeleteRow(Item, Cancel)
	TableBeforeDeletion("ManufacturedProducts", Item, Cancel);
EndProcedure

&AtServer
Procedure OutputBeforeDeletionOnServer()
	
	For Each CurID_ In Items.ManufacturedProducts.SelectedRows Do
		DeleteCostGroup(CurID_);
	EndDo;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnChange(Item)
	TableWhenModified("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsAfterDeleteRow(Item)
	TableAfterDeletion("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	TableBeforeEndOfEditing("ManufacturedProducts", Item, NewRow, CancelEdit, Cancel);
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseGroupClearing(Item, StandardProcessing)
	TableCostGroupCleaning("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseGroupOpening(Item, StandardProcessing)
	TableCostGroupDiscovery("ManufacturedProducts", StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostGroupStartOfSelection("ManufacturedProducts", StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsProductsOnChange(Item)
	TableProductsWhenChanged("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsCharacteristicOnChange(Item)
	TableCharacteristicsWhenChanging("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	TableSeriesStartSelection("ManufacturedProducts", Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsSeriesOnChange(Item)
	TableSeriesWhenChanged("ManufacturedProducts");
	ProductsSeriesRecalculatePrices(, "ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsPackageOnChange(Item)
	PackingTableWhenChanging("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsNumberOfPackagesOnChange(Item)
	TableNumberOfPackagesWhenChanged("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsPriceOnChange(Item)
	TablePriceWhenChanged("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsSumOnChange(Item)
	TableAmountWhenChanged("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsToExpenseAsOnChange(Item)
	TableChargeToExpensesWhenChangesAreMade("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	TableItemOfExpenditureSelection(Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseItemOnChange(Item)
	TableItemOfExpenditureInCaseOfChange(Item);
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostAnalyticsStartOfSelection(Item, StandardProcessing)
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	TableCostAnalyticsAutoSelection(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	TableCostAnalyticsEndOfTextEntry(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSideAndIntermediateRelease

&AtClient
Procedure SideAndIntermediateReleaseSelection(Item, RowSelected, Field, StandardProcessing)
	TableSelection("SideAndIntermediateRelease", Field, StandardProcessing);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ProcessingSelectionOfSelectionOnServer(ValueSelected, "SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseOnStartEdit(Item, NewRow, Copy)
	TableAtBeginningOfEditing("SideAndIntermediateRelease", NewRow, Copy);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseOnChange(Item)
	TableWhenModified("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseBeforeDeleteRow(Item, Cancel)
	TableBeforeDeletion("SideAndIntermediateRelease", Item, Cancel);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseAfterDeleteRow(Item)
	TableAfterDeletion("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	TableBeforeEndOfEditing("SideAndIntermediateRelease", Item, NewRow, CancelEdit, Cancel);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseGroupClearing(Item, StandardProcessing)
	TableCostGroupCleaning("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseGroupOpening(Item, StandardProcessing)
	TableCostGroupDiscovery("SideAndIntermediateRelease", StandardProcessing);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostGroupStartOfSelection("SideAndIntermediateRelease", StandardProcessing);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseProductsOnChange(Item)
	TableProductsWhenChanged("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseCharacteristicOnChange(Item)
	TableCharacteristicsWhenChanging("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	TableSeriesStartSelection("SideAndIntermediateRelease", Item, StandardProcessing);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSeriesOnChange(Item)
	TableSeriesWhenChanged("SideAndIntermediateRelease");
	ProductsSeriesRecalculatePrices(, "SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePackageOnChange(Item)
	PackingTableWhenChanging("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseNumberOfPackagesOnChange(Item)
	TableNumberOfPackagesWhenChanged("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePriceOnChange(Item)
	TablePriceWhenChanged("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSumOnChange(Item)
	TableAmountWhenChanged("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseToExpenseAsOnChange(Item)
	TableChargeToExpensesWhenChangesAreMade("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	TableItemOfExpenditureSelection(Item, StandardProcessing);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseItemOnChange(Item)
	TableItemOfExpenditureInCaseOfChange(Item);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostAnalyticsStartOfSelection(Item, StandardProcessing)
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	TableCostAnalyticsAutoSelection(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	TableCostAnalyticsEndOfTextEntry(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndWorks

&AtClient
Procedure MaterialsAndWorksSelection(Item, RowSelected, Field, StandardProcessing)
	TableSelection("MaterialsAndWorks", Field, StandardProcessing);
EndProcedure

&AtClient
Procedure MaterialsAndWorksOnStartEdit(Item, NewRow, Copy)
	TableAtBeginningOfEditing("MaterialsAndWorks", NewRow, Copy);
EndProcedure

&AtClient
Procedure MaterialsAndWorksOnChange(Item)
	TableWhenModified("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	TableBeforeEndOfEditing("MaterialsAndWorks", Item, NewRow, CancelEdit, Cancel);
EndProcedure

&AtClient
Procedure MaterialsAndWorksBeforeDeleteRow(Item, Cancel)
	TableBeforeDeletion("MaterialsAndWorks", Item, Cancel);
EndProcedure

&AtClient
Procedure MaterialsAndWorksAfterDeleteRow(Item)
	TableAfterDeletion("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksMainOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	If CurrentData.Main Then
		MaterialsAndWorksChangedOnServer(CurrentData.GetID());
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksExpenseGroupClearing(Item, StandardProcessing)
	TableCostGroupCleaning("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksExpenseGroupOpening(Item, StandardProcessing)
	TableCostGroupDiscovery("MaterialsAndWorks", StandardProcessing);
EndProcedure

&AtClient
Procedure MaterialsAndWorksExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostGroupStartOfSelection("MaterialsAndWorks", StandardProcessing);
EndProcedure

&AtClient
Procedure MaterialsAndWorksProductsOnChange(Item)
	TableProductsWhenChanged("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksCharacteristicOnChange(Item)
	TableCharacteristicsWhenChanging("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	TableSeriesStartSelection("MaterialsAndWorks", Item, StandardProcessing);
EndProcedure

&AtClient
Procedure MaterialsAndWorksSeriesOnChange(Item)
	TableSeriesWhenChanged("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksPackageOnChange(Item)
	PackingTableWhenChanging("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksNumberOfPackagesOnChange(Item)
	TableNumberOfPackagesWhenChanged("MaterialsAndWorks");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersServices

&AtClient
Procedure ServicesSelection(Item, RowSelected, Field, StandardProcessing)
	TableSelection("Services", Field, StandardProcessing);
EndProcedure

&AtClient
Procedure ServicesOnStartEdit(Item, NewRow, Copy)
	TableAtBeginningOfEditing("Services", NewRow, Copy);
EndProcedure

&AtClient
Procedure ServicesOnChange(Item)
	TableWhenModified("Services");
EndProcedure

&AtClient
Procedure ServicesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	TableBeforeEndOfEditing("Services", Item, NewRow, CancelEdit, Cancel);
EndProcedure

&AtClient
Procedure ServicesExpenseGroupClearing(Item, StandardProcessing)
	TableCostGroupCleaning("Services");
EndProcedure

&AtClient
Procedure ServicesExpenseGroupOpening(Item, StandardProcessing)
	TableCostGroupDiscovery("Services", StandardProcessing);
EndProcedure

&AtClient
Procedure ServicesExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostGroupStartOfSelection("Services", StandardProcessing);
EndProcedure

&AtClient
Procedure ServicesProductsOnChange(Item)
	TableProductsWhenChanged("Services");
EndProcedure

&AtClient
Procedure ServicesCharacteristicOnChange(Item)
	TableCharacteristicsWhenChanging("Services");
EndProcedure

&AtClient
Procedure ServicesCountOnChange(Item)
	TableNumberOfPackagesWhenChanged("Services");
EndProcedure

&AtClient
Procedure ServicesPriceOnChange(Item)
	TablePriceWhenChanged("Services");
EndProcedure

&AtClient
Procedure ServicesVendorPriceKindOnChange(Item)
	
	CurrentData = Items.Services.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsFillInPrice(ThisObject, "Services", StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);	
	
EndProcedure

&AtClient
Procedure ServicesSumOnChange(Item)
	TableAmountWhenChanged("Services");
EndProcedure

&AtClient
Procedure ServicesVATRateOnChange(Item)
	
	CurrentData = Items.Services.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsForRecalculatingAmounts(ThisObject, "Services", StructureOfActions, "VATAmount, AmountIncludingVAT");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ServicesVATAmountOnChange(Item)
	
	CurrentData = Items.Services.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsForRecalculatingAmounts(ThisObject, "Services", StructureOfActions, "AmountIncludingVAT");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCommon

&AtClient
Procedure TableSelection(TSName, Field, StandardProcessing)
	
	CurrentData = Items[TSName].CurrentData;
	
	If TSName = "ManufacturedProducts"
		And (Field = Items[TSName + "CostShare"]
			Or Field = Items[TSName + "CostSharePercentage"]
			Or Field = Items[TSName + "ThereAreErrorsOfFillingInCostShare"]) Then
		OpenCostShareEntryForm(CurrentData, StandardProcessing);
	ElsIf Field = Items[TSName + "ExpenseGroup"]
		And Field.ReadOnly Then
		TableCostGroupDiscovery(TSName, StandardProcessing);
	ElsIf (Field = Items.ManufacturedProductsTransactionRecordingPresentation
			Or Field = Items.SideAndIntermediateReleaseTransactionRecordingPresentation)
		And ValueIsFilled(CurrentData.ExpenseItem) Then
		GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure TableAtBeginningOfEditing(TSName, NewRow, Copy)
	
	CurrentData = Items[TSName].CurrentData;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items[TSName], ThisObject);
	
	StructureOfActions = New Structure;
	
	If NewRow Then
		
		If Not TSName = "MaterialsAndWorks" Then
			CurrentData.RowCode = 0;
			OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ByOrders);
		EndIf;
		
		If Not Copy Then
			AddActionsFillInPriceView(ThisObject, TSName, StructureOfActions);
			AddActionsInitializeArticleAndAnalytics(ThisObject, TSName, StructureOfActions);
		EndIf;
		
	EndIf;
	
	If Copy Then
		
		If TSName = "ManufacturedProducts" Then
			CurrentData.RowCodeProducts = 0;
		EndIf;
		
		AddActionsCheckSeriesCalculateStatus(ThisObject, TSName, StructureOfActions);
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If NewRow
		And Not TSName = "MaterialsAndWorks"
		And False Then
		CalculateDocumentTotals(ThisObject, "QuantityOverOrder");
	EndIf;
	
EndProcedure

&AtClient
Procedure TableBeforeDeletion(TSName, Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items[TSName], ThisObject);
	
	If TSName = "ManufacturedProducts"
		And Not Object.ByOrders Then
		OutputBeforeDeletionOnServer();
	EndIf;
	
	If Not TSName = "Services" Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item,
			CachedValues,
			SeriesSpecificationParameters[TSName]);
	EndIf;
	
EndProcedure

&AtClient
Procedure TableAfterDeletion(TSName)
	
	TableAfterDeletionOnServer(TSName);
	
EndProcedure

&AtServer
Procedure TableAfterDeletionOnServer(TSName)
	
	For Each CurrentData In CostGroups Do
		TableFillInDependentServiceDetailsOfCostGroup(TSName, CurrentData.CostGroupNumber);
	EndDo;
	
	If TSName = "ManufacturedProducts" Then
		CalculatePercentageOfCostAllocationForOutputProducts();
	EndIf;
	
EndProcedure

&AtClient
Procedure TableBeforeEndOfEditing(TSName, Item, NewRow, CancelEdit, Cancel)
	
	If NewRow
		And CancelEdit Then
		Return;
	EndIf;
	
	CurrentData = Items[TSName].CurrentData;
	
	TableBeforeEndOfEditingOnServer(
		TSName,
		CurrentData.GetID(),
		NewRow,
		CancelEdit);
	
EndProcedure

&AtServer
Procedure TableBeforeEndOfEditingOnServer(TSName, CurrentID, NewRow, CancelEdit)
	
	CurrentData = Object[TSName].FindByID(CurrentID);
	LineCache = ProcessingOfTabularFormsClientServer.LineCache(Items[TSName], ThisObject);
	
	If TSName = "ManufacturedProducts" Then
		
		If Not Object.ByOrders Then
			AddChangeCostGroup(CurrentData);
		Else
			
			SetDefaultCostGroupNumber(TSName, CurrentID);
			
			TableFillInDependentServiceDetailsOfCostGroup(TSName, LineCache.CostGroupNumber);
			TableFillInDependentServiceDetailsOfCostGroup(TSName, CurrentData.CostGroupNumber);
			
		EndIf;
		
		Groups = New Array;
		Groups.Add(LineCache.CostGroupNumber);
		Groups.Add(CurrentData.CostGroupNumber);
		CalculatePercentageOfCostAllocationForOutputProducts(Groups);
		
	Else
		
		SetDefaultCostGroupNumber(TSName, CurrentID);
		
		TableFillInDependentServiceDetailsOfCostGroup(TSName, LineCache.CostGroupNumber);
		TableFillInDependentServiceDetailsOfCostGroup(TSName, CurrentData.CostGroupNumber);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TableWhenModified(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	If Not TSName = "MaterialsAndWorks" Then
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ByOrders);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		AttributesList = "QuantityOverOrder,NumberOfProducts,TheRecordsAreKeptByCCD";
	ElsIf TSName = "Services" Then
		AttributesList = "QuantityOverOrder,AmountOfServices";
	Else
		AttributesList = "NotExecuteJob";
	EndIf;
	
	CalculateDocumentTotals(ThisObject, AttributesList);
	
EndProcedure

&AtClient
Procedure TableCostGroupCleaning(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	CostGroupNumberBeforeChange = CurrentData.CostGroupNumber;
	
	CurrentData.CostGroupNumber = 0;
	CurrentData.ExpenseGroup = "";
	CurrentData.ProductionStage = Undefined;
	
	If Object.ByOrders
		And Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		And TSName = "ManufacturedProducts" Then
		CurrentData.MethodOfAllocatingFinishedProductCosts = Undefined;
	EndIf;
	If Object.ByOrders
		And (Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOM")
			Or Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
			Or Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments"))
		And TSName = "ManufacturedProducts" Then
		CurrentData.BillOfMaterials = Undefined;
	EndIf;
	
	If TSName = "MaterialsAndWorks"
		And UseImportedGoods Then
		CurrentData.ThereIsImportedProduct = False;
		CurrentData.Main             = False;
	EndIf;
	
	TableFillInDependentServiceDetailsOfCostGroup(TSName, CostGroupNumberBeforeChange);
	
EndProcedure

&AtClient
Procedure TableCostGroupDiscovery(TSName, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items[TSName].CurrentData;
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		And ValueIsFilled(CurrentData.ProductionStage) Then
		ShowValue(, CurrentData.ProductionStage);
	EndIf;
EndProcedure

&AtClient
Procedure TableCostGroupStartOfSelection(TSName, StandardProcessing = False)
	
	StandardProcessing = False;
	
	If Items[TSName].SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng mà nhóm chi phí sẽ được điền.';
							|ru = 'Необходимо выбрать строки, для которых будет заполнена группа затрат.';
							|en = 'Select the lines for which a cost group will be populated.'; fa = 'Select the lines for which a cost group will be populated.';
							|it = 'È necessario selezionare le righe per le quali sarà compilato il gruppo delle spese.';
							|pl = 'Należy wybrać wiersze, dla których będzie wypełniona grupa kosztów.';
							|tr = 'Maliyet grubunun doldurulacağı satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("GroupCosts",         Object.GroupCosts);
	FormParameters.Insert("CostGroupNumber",         Items[TSName].CurrentData.CostGroupNumber);
	FormParameters.Insert("CostGroupStorageAddress", PutCostGroupDataInStorage(TSName));
	
	FormParameters.Insert(
		"CostGroupFields_",
		ProcessingByThirdPartiesClientServer.ListOfCostGroupFieldsInProcessorSReport(Object.GroupCosts));
	
	CallbackDescription = New CallbackDescription("TableCostGroupStartOfSelectionCompletion", ThisObject, TSName);
	OpenForm("CommonForm.SelectExpenseGroupTransferringToProcessing", FormParameters,,,,, CallbackDescription);
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure TableFillInDependentServiceDetailsOfCostGroup(TSName, CostGroupNumber)
	
	If (TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease")
		And Not CostGroupNumber = 0 Then
		
		CostGroupDescription = CostGroupDataByCostGroupNumber(CostGroupNumber);
		
		FillInDependentServiceDetailsOfCostGroup(CostGroupDescription);
		
		If UseImportedGoods Then
			
			UpdateServiceDetailsOfCostGroupInLinkedTS(CostGroupDescription, "MaterialsAndWorks", "ThereIsImportedProduct");
			
			If Not CostGroupDescription.ThereIsImportedProduct Then
				ClearPrimaryByCostGroupFlag(CostGroupNumber);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TableProductsWhenChanged(TSName)
	
	CallbackDescription = New CallbackDescription("TableProductsWhenChangedCompletion", ThisObject, TSName);
	KeyDetailsTableWhenChanging(TSName, CallbackDescription);
	
EndProcedure

&AtClient
Procedure TableProductsWhenChangedCompletion(Result, TSName) Export
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsWhenChangingProducts(ThisObject, TSName, StructureOfActions);
	AddActionsCheckFillSpecification(ThisObject, TSName, StructureOfActions, CurrentData);
	AddActionsFillInPrice(ThisObject, TSName, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If TSName = "MaterialsAndWorks"
		And CurrentData.TheRecordsAreKeptByCCD = 0 Then
		CurrentData.Main = False;
	ElsIf (TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease")
		And CurrentData.TheRecordsAreKeptByCCD Then
		TheRecordsAreKeptByCCD = True;
	ElsIf TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		CalculateDocumentTotals(ThisObject, "TheRecordsAreKeptByCCD");
	EndIf;
	
EndProcedure

&AtClient
Procedure TableCharacteristicsWhenChanging(TSName)
	
	CallbackDescription = New CallbackDescription("TableCharacteristicsWhenChangingCompletion", ThisObject, TSName);
	KeyDetailsTableWhenChanging(TSName, CallbackDescription);
	
EndProcedure

&AtClient
Procedure TableCharacteristicsWhenChangingCompletion(Result, TSName) Export
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsWhenChangingCharacteristic(ThisObject, TSName, StructureOfActions);
	AddActionsCheckFillSpecification(ThisObject, TSName, StructureOfActions, CurrentData);
	AddActionsCheckFillShareCost(ThisObject, TSName, StructureOfActions);
	AddActionsFillInPrice(ThisObject, TSName, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure TableSeriesStartSelection(TSName, Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(TSName, Item.EditText, Items[TSName].CurrentData);
	
EndProcedure

&AtClient
Procedure TableSeriesWhenChanged(TSName)
	
	CurrentData     = Items[TSName].CurrentData;
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value                   = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters[TSName], ValueSelected);
	
EndProcedure

&AtClient
Procedure ProductsSeriesRecalculatePrices(CurrentRow = Undefined, TSName)
	
	If Not (TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease") Then
		Return;
	EndIf;
	
	If CurrentRow = Undefined Then
		CurrentRow = Items[TSName].CurrentData;
	EndIf;
	
	If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentRow.Products, "Series", Object.Date) Then
		
		StructureOfActions = New Structure;

		AddActionsFillInPrice(ThisObject, TSName, StructureOfActions);

		If TSName = "ManufacturedProducts" Then
			StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
		EndIf;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PackingTableWhenChanging(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsWhenChangingPackaging(ThisObject, TSName, StructureOfActions, CurrentData);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure TableNumberOfPackagesWhenChanged(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsWhenChangingQuantity(ThisObject, TSName, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure TablePriceWhenChanged(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	If TSName = "Services" Then
		AttributesList = "Sum, VATAmount, AmountIncludingVAT";
	Else
		AttributesList = "Sum";
	EndIf;
	
	AddActionsForRecalculatingAmounts(ThisObject, TSName, StructureOfActions, AttributesList);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure TableAmountWhenChanged(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	If TSName = "Services" Then
		AttributesList = "Price, VATAmount, AmountIncludingVAT";
	Else
		AttributesList = "Price";
	EndIf;
	
	AddActionsForRecalculatingAmounts(ThisObject, TSName, StructureOfActions, AttributesList);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure TableChargeToExpensesWhenChangesAreMade(TSName)
	
	CallbackDescription = New CallbackDescription("TableChargeToExpensesWhenChangesAreMadeCompletion", ThisObject, TSName);
	KeyDetailsTableWhenChanging(TSName, CallbackDescription);
	
EndProcedure

&AtClient
Procedure TableChargeToExpensesWhenChangesAreMadeCompletion(Result, TSName) Export
	
	CurrentData = Items[TSName].CurrentData;
	
	If CurrentData.ToExpenseAs Then
		CurrentData.Purpose = Undefined;
	EndIf;
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "Object." + TSName);
	GLAccountSettingsClientServer.WhenChangingAccountAvailabilityDetailsInLine(ThisObject, CurrentData, "Object." + TSName);
	
EndProcedure

&AtClient
Procedure TableItemOfExpenditureSelection(Item, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TableItemOfExpenditureInCaseOfChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure TableCostAnalyticsStartOfSelection(Item, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TableCostAnalyticsAutoSelection(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TableCostAnalyticsEndOfTextEntry(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure KeyDetailsTableWhenChanging(TSName, CallbackDescription)
	
	CurrentData = Items[TSName].CurrentData;
	LineCache = ProcessingOfTabularFormsClientServer.LineCache(Items[TSName], ThisObject);
	
	If TSName = "MaterialsAndWorks"
		Or CurrentData.RowCode = 0
		Or (CurrentData.Products = LineCache.Products
			And CurrentData.Characteristic = LineCache.Characteristic
			And (Not CommonClientServer.HasAttributeOrObjectProperty(CurrentData, "ToExpenseAs")
				Or CurrentData.ToExpenseAs = LineCache.ToExpenseAs)) Then
		RunCallback(CallbackDescription, True);
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName",              TSName);
	AdditionalParameters.Insert("CurrentData",      CurrentData);
	AdditionalParameters.Insert("LineCache",          LineCache);
	AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
	
	IssueNotification =
		New CallbackDescription(
			"KeyDetailsTableWhenChangingCompletion",
			ThisObject,
			AdditionalParameters);
	
	QueryText = NStr("vi = 'Dòng được soạn sẽ không liên quan đến dòng của đơn hàng. Tiếp tục?';
					|ru = 'Редактируемая строка перестанет быть связанной со строкой заказа. Продолжить?';
					|en = 'The edited line will be unlinked from the order line. Continue?'; fa = 'The edited line will be unlinked from the order line. Continue?';
					|it = 'La riga da modificare non sarà più associata alla riga dell''ordine. Continuare?';
					|pl = 'Edytowany wiersz nie będzie powiązany z wierszem zamówienia. Kontynuować?';
					|tr = 'Düzenlenecek satır, artık sipariş satırına bağlı olmayacaktır. Devam edilsin mi?'");
	ShowQueryBox(IssueNotification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure KeyDetailsTableWhenChangingCompletion(Result, AdditionalParameters) Export
	
	CurrentData = AdditionalParameters.CurrentData;
	
	// If the user has confirmed the change in the value of the key details.
	If Result = DialogReturnCode.Yes Then
		
		StructureOfActions = New Structure;
		
		If Not AdditionalParameters.TSName = "MaterialsAndWorks" Then
			CurrentData.RowCode = 0;
			OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ByOrders);
		EndIf;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		
		If Not AdditionalParameters.TSName = "MaterialsAndWorks" Then
			CalculateDocumentTotals(ThisObject, "QuantityOverOrder");
		EndIf;
		
		RunCallback(AdditionalParameters.CallbackDescription, True);
		
	Else
		FillPropertyValues(CurrentData, AdditionalParameters.LineCache);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region IsMain

&AtClient
Procedure CloseOrder(Command)
	
	If Modified
		Or Not Object.Posted Then
		ShowQueryBox(
			New CallbackDescription("CloseOrderCompletion", ThisObject),
			NStr("vi = 'Cần kết chuyển chứng từ để thực hiện giao dịch. Kết chuyển chứng từ?';
				|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
				|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
				|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
				|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
				|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),
			QuestionDialogMode.YesNo);
	Else
		CloseOrderFragment();
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	ARAPAccountingClient.PaymentSettlement(ThisObject, Items.CreditPaymentForm);
EndProcedure

#EndRegion

#Region ManufacturedProducts

&AtClient
Procedure ManufacturedProductsPickUpProducts(Command)
	TablePickUpProducts("ManufacturedProducts");
EndProcedure

&AtClient
Procedure SelectOutputProductsFromOrder(Command)
	
	AddItemsFromSalesOrderGoodsIssue("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputProductsFillTSAccordingToOrderSpecification(Command)
	TableFillTsByOrderSpecification("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsToRefillCostlyTS(Command)
	
	If ItIsPossibleToReFillAccordingToSpecification() Then
		
		If Not Object.SideAndIntermediateRelease.Count() = 0
			Or Not Object.MaterialsAndWorks.Count() = 0
			Or Not Object.Services.Count() = 0 Then
		
			If Object.ByOrders Then
				QueryText = NStr("vi = 'Điền lại sản phẩm phụ, nguyên vật liệu và công việc, dịch vụ của các nhóm chi phí đã chọn theo đơn hàng?';
								|ru = 'Перезаполнить побочные изделия, материалы и работы, услуги выделенных групп затрат по заказу?';
								|en = 'Refill by-products, materials and works, services of the selected cost groups against the order?'; fa = 'Refill by-products, materials and works, services of the selected cost groups against the order?';
								|it = 'Ricompilare sottoprodotti, materiali e lavori e servizi dei gruppi di spesa evidenziati per ordine?';
								|pl = 'Ponownie wypełnić wyroby poboczne, materiały i prace, usługi zaznaczonych grup kosztów według zamówienia?';
								|tr = 'Siparişe göre belirtilen maliyet gruplarının nihai yan ürünleri, malzemeleri ve işleri, hizmetleri yeniden doldurulsun mu?'");
			Else
				QueryText = NStr("vi = 'Điền lại sản phẩm phụ, nguyên vật liệu và công việc, dịch vụ của nhóm chi phí đã chọn theo bảng kê chi tiết?';
								|ru = 'Перезаполнить побочные изделия, материалы и работы, услуги выделенных групп затрат по спецификации?';
								|en = 'Refill by-products, materials and works, services of the selected cost groups by the bill of materials?'; fa = 'Refill by-products, materials and works, services of the selected cost groups by the bill of materials?';
								|it = 'Ricompilare sottoprodotti, materiali e lavori e servizi dei gruppi di spesa evidenziati per specifica?';
								|pl = 'Ponownie wypełnić wyroby poboczne, materiały i prace, usługi zaznaczonych grup kosztów według specyfikacji?';
								|tr = 'Ürün reçetesine göre belirtilen maliyet gruplarının nihai yan ürünleri, malzemeleri ve işleri, hizmetleri yeniden doldurulsun mu?'");
			EndIf;
			
			CallbackDescription = New CallbackDescription("ManufacturedProductsToRefillCostlyTSCompletion", ThisObject);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			
		Else
			ManufacturedProductsToRefillCostlyTSCompletion(DialogReturnCode.Yes);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OutputProductsTransferToByProducts(Command)
	
	If Items.ManufacturedProducts.SelectedRows.Count() > 0 Then
		OutputItemsAreMovedToSideItemsOnServer();
		CalculateDocumentTotals(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure OutputProductsFillInPricesByPriceType(Command)
	
	ClearMessages();
	
	PricesCalculated = FillInPricesByPriceKindServer("ManufacturedProducts");
	SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	
EndProcedure

&AtClient
Procedure OutputProductsFillInThePricesAccordingToTheCalculation(Command)
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If CurrentData = Undefined Then
		Return
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert(
		"SelectedRows",
		TMCommonUseClientServer.Array(CurrentData.GetID(), False));
	
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("Date", Object.Date);
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("ProductionDispatcherBusinessUnit", Object.Department);
	FilterStructure1.Insert("Product", CurrentData.Products);
	CostObjects = New Array();
	If ValueIsFilled(CurrentData.BillOfMaterials) Then
		CostObjects.Add(CurrentData.BillOfMaterials);
	EndIf;
	FilterStructure1.Insert("CostObjects", CostObjects);
	FilterStructure1.Insert("Characteristic", CurrentData.Characteristic);
	FilterStructure1.Insert("Purpose", CurrentData.Purpose);
	
	FormParameters = New Structure;
	FormParameters.Insert("FilterStructure1", FilterStructure1);
	
	FormParameters.Insert("State", 
		PredefinedValue("Enum.StatesOfStandardCostEstimateCalculation.Calculated"));
	
	OpenForm(
		"Document.StandardCosting2_2.Form.ChoiceForm",
		FormParameters,,,,,
		New CallbackDescription("SelectionOfPlannedCalculationEnds", ThisObject, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	Return;
	
EndProcedure

&AtClient
Procedure OutputItemsFillCostGroup(Command)
	TableFillCostGroup("ManufacturedProducts");
EndProcedure

&AtClient
Procedure OutputProductsFromRecipient(Command)
	RecipientDataTable("ManufacturedProducts");
EndProcedure

&AtClient
Procedure OutputProductsSpecifyTheSeries(Command)
	OpenSelectionOfSeries("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsCopyLines(Command)
	TableCopyRows("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsInsertRows(Command)
	InsertRowsTable("ManufacturedProducts");
EndProcedure

&AtClient
Procedure OutputItemsSplitLine(Command)
	TableSplitRow("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsImportDataFromPDT(Command)
	TableImportDataFromPDT("ManufacturedProducts");
EndProcedure

&AtClient
Procedure FinishedProductsSearchByBarcode(Command)
	BarcodeSearchTable("ManufacturedProducts");
EndProcedure

#EndRegion

#Region SideAndIntermediateRelease

&AtClient
Procedure ByProductsPickUpProducts(Command)
	TablePickUpProducts("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsToPickUpFromOrder(Command)
	
	AddItemsFromSalesOrderGoodsIssue("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsFillTSAccordingToOrderSpecification(Command)
	TableFillTsByOrderSpecification("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsFillInPricesByPriceType(Command)
	
	ClearMessages();
	
	PricesCalculated = FillInPricesByPriceKindServer("SideAndIntermediateRelease", Items.SideAndIntermediateRelease.SelectedRows);
	SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	
EndProcedure

&AtClient
Procedure ByProductsFillInTheCostGroup(Command)
	TableFillCostGroup("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsFillOutTheCalculationArticle(Command)
	TableFillArticleCalculation("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsFillRecipient(Command)
	RecipientDataTable("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsSpecifyTheSeries(Command)
	OpenSelectionOfSeries("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsCopyLines(Command)
	TableCopyRows("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsInsertRows(Command)
	InsertRowsTable("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsSplitString(Command)
	TableSplitRow("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsBarcodeSearch(Command)
	BarcodeSearchTable("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseImportDataFromPDT(Command)
	TableImportDataFromPDT("SideAndIntermediateRelease");
EndProcedure

#EndRegion

#Region MaterialsAndWorks

&AtClient
Procedure MaterialsAndWorksPickUpProducts(Command)
	TablePickUpProducts("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure PickUpSubmittedMaterials(Command)
	
	Cancel = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Organization) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
						|ru = 'Поле ""Организация"" не заполнено';
						|en = '""Company"" is required'; fa = '""Company"" is required';
						|it = 'Il campo ""Società"" non è compilato';
						|pl = 'Nie wypełniono pola ""Firma""';
						|tr = '""İş Yeri"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.Organization", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Partner) Then
		ErrorText = StrTemplate(NStr("vi = 'Chưa điền trường ""%1""';
									|ru = 'Поле ""%1"" не заполнено';
									|en = 'Field ""%1"" is blank'; fa = 'Field ""%1"" is blank';
									|it = 'Il campo ""%1"" non è compilato';
									|pl = 'Pole ""%1"" nie jest wypełnione';
									|tr = '""%1"" alanı doldurulmadı'"), Items.Partner.Title);
		CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.Partner", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Hợp đồng""';
						|ru = 'Поле ""Договор"" не заполнено';
						|en = '""Contract"" is not filled in.'; fa = '""Contract"" is not filled in.';
						|it = 'Il campo ""Accordo"" non è compilato';
						|pl = 'Pole ""Umowa"" nie jest wypełnione';
						|tr = '""Sözleşme"" alanı doldurulmamış'");
		CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.Contract", "", Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(True,
		"Document.SubcontractorReport2_5.DocumentForm.Command.SelectTransferredGoods");
	
	AddressOfGoods = PlaceGoodsInStorageForSelectionOfTransferredGoods();
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref",                Object.Ref);
	FormParameters.Insert("Organization",           Object.Organization);
	FormParameters.Insert("Owner",              Object.Partner);
	FormParameters.Insert("Contract",               Object.Contract);
	FormParameters.Insert("Title",             NStr("vi = 'Chọn hàng hóa đã chuyển giao đi gia công';
													|ru = 'Подбор товаров, переданных переработчику';
													|en = 'Pick goods transferred to subcontractor'; fa = 'Pick goods transferred to subcontractor';
													|it = 'Selezione articoli trasferiti all''elaboratore';
													|pl = 'Wybór towarów przekazanych przetwórcy';
													|tr = 'Fason üreticiye transfer edilen ürünlerin seçimi'"));
	FormParameters.Insert("CollapseGTDNumbers",     True);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("AddressOfGoodsInvoiceInVault", AddressOfGoods);
	
	OpenForm(
		"DataProcessor.SelectGoodsTransferredToCustody.Form.Form",
		FormParameters,
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorkFillTSAccordingToSpecificationOrder(Command)
	TableFillTsByOrderSpecification("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksFillInTheCostGroup(Command)
	TableFillCostGroup("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksFillOutTheCalculationArticle(Command)
	TableFillArticleCalculation("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksSpecifyTheSeries(Command)
	OpenSelectionOfSeries("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksCopyLines(Command)
	TableCopyRows("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksInsertLines(Command)
	InsertRowsTable("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksSplitLine(Command)
	TableSplitRow("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksSearchByBarcode(Command)
	BarcodeSearchTable("MaterialsAndWorks");
EndProcedure

&AtClient
Procedure MaterialsAndWorksImportDataFromPDT(Command)
	TableImportDataFromPDT("MaterialsAndWorks");
EndProcedure

#EndRegion

#Region Services

&AtClient
Procedure ServicesPickUpProducts(Command)
	TablePickUpProducts("Services");
EndProcedure

&AtClient
Procedure ServicesFillTSByOrderSpecification(Command)
	TableFillTsByOrderSpecification("Services");
EndProcedure

&AtClient
Procedure ServicesFillInPricesBySupplierPriceType(Command)
	
	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(Object, "Services", NStr("vi = 'Dịch vụ';
																													|ru = 'Услуги';
																													|en = 'Services'; fa = 'خدمات';
																													|it = 'Servizi';
																													|pl = 'Services';
																													|tr = 'Hizmetler'")) Then
		
		CurrentData = Items.Services.CurrentData;
		
		If Not CurrentData = Undefined
			And Not ValueIsFilled(CurrentData.VendorPriceKind) Then
			PartnerPricesFillingClient.SelectVendorsPriceType(
				New CallbackDescription("ServicesFillInPricesBySupplierPriceTypeCompletion", ThisObject),
				Object.Partner,
				Object.PriceIncludesVAT);
		Else
			ServicesFillInPricesBySupplierPriceTypeCompletion(CurrentData.VendorPriceKind, Undefined);
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure ServicesSelectAndCompleteService(Command)
	
	If Items.Services.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Để điền dịch vụ, bạn phải chọn dòng.';
								|ru = 'Для заполнения услуги необходимо выбрать строки.';
								|en = 'To fill in the service, select lines.'; fa = 'To fill in the service, select lines.';
								|it = 'Per compilare il servizio è necessario selezionare le righe.';
								|pl = 'Aby wypełnić usługę, musisz wybrać wiersz.';
								|tr = 'Hizmetin doldurulması için satırları seçmeniz gerekmektedir.'"));
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("ServicesSelectAndCompleteServiceCompletion", ThisObject);
	FilterParameters = New Structure("ItemsType", PredefinedValue("Enum.ItemsTypes.Work_5"));
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	OpenForm("Catalog.Products.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure ServicesFillCostGroup(Command)
	TableFillCostGroup("Services");
EndProcedure

&AtClient
Procedure ServicesFillOutCalculationArticle(Command)
	TableFillArticleCalculation("Services");
EndProcedure

&AtClient
Procedure ServicesCopyRows(Command)
	TableCopyRows("Services");
EndProcedure

&AtClient
Procedure ServicesInsertRows(Command)
	InsertRowsTable("Services");
EndProcedure

&AtClient
Procedure ServicesToSplitTheString(Command)
	TableSplitRow("Services");
EndProcedure

&AtClient
Procedure BarcodeSearchServices(Command)
	BarcodeSearchTable("Services");
EndProcedure

&AtClient
Procedure ServicesImportDataFromPDT(Command)
	TableImportDataFromPDT("Services");
EndProcedure

#EndRegion

#Region TableCommandHandlers

&AtClient
Procedure TablePickUpProducts(TSName)
	
	PickUpProduct(TSName);
	
EndProcedure

&AtClient
Procedure TableFillTsByOrderSpecification(TSName)
	
	If Not Object[TSName].Count() = 0 Then
			
			If Object.ByOrders Then
				QueryText = NStr("vi = 'Phần bảng sẽ được điền lại theo đơn hàng. Tiếp tục?';
								|ru = 'Табличная часть будет перезаполнена по заказу. Продолжить?';
								|en = 'The table will be refilled against the order. Continue?'; fa = 'The table will be refilled against the order. Continue?';
								|it = 'La parte tabellare sarà ricompilata in base all''ordine. Continuare?';
								|pl = 'Sekcja tabelaryczna będzie ponownie wypełniona według zamówienia. Kontynuować?';
								|tr = 'Tablo bölümü, siparişe göre yeniden doldurulacaktır. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Phần bảng sẽ được điền lại theo bảng kê chi tiết. Tiếp tục?';
								|ru = 'Табличная часть будет перезаполнена по спецификациям. Продолжить?';
								|en = 'The table will be refilled by the bills of materials. Continue?'; fa = 'The table will be refilled by the bills of materials. Continue?';
								|it = 'La parte tabellare sarà ricompilata in base alle specifiche. Continuare?';
								|pl = 'Sekcja tabelaryczna będzie ponownie wypełniona według specyfikacji. Kontynuować?';
								|tr = 'Tablo bölümü, ürün reçetesine göre yeniden doldurulacaktır. Devam edilsin mi?'");
			EndIf;
			
			CallbackDescription = New CallbackDescription("TableFillTsByOrderSpecificationCompletion", ThisObject, TSName);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			
	Else
		TableFillTsByOrderSpecificationCompletion(DialogReturnCode.Yes, TSName);
	EndIf;
	
EndProcedure

&AtClient
Procedure TableFillCostGroup(TSName)
	TableCostGroupStartOfSelection(TSName);
EndProcedure

&AtClient
Procedure TableFillArticleCalculation(TSName)

	If Items[TSName].SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng để điền dạng tính giá thành.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить статью калькуляции.';
							|en = 'Select the lines for which it is required to populate the product cost element.'; fa = 'Select the lines for which it is required to populate the product cost element.';
							|it = 'È necessario selezionare le righe per le quali si deve compilare la voce di calcolo.';
							|pl = 'Należy wybrać wiersze, dla których trzeba wypełnić pozycję kalkulacji.';
							|tr = 'Ürün maliyet kalemini doldurmanız gereken satırları seçmeniz gerekmektedir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	CostTypes = New Array;
	CostTypes.Add(PredefinedValue("Enum.CostTypes.Material_"));
	If TSName = "SideAndIntermediateRelease" Then
		CostTypes.Add(PredefinedValue("Enum.CostTypes.RecyclableWaste"));
	ElsIf TSName = "Services" Then
		CostTypes.Add(PredefinedValue("Enum.CostTypes.Other"));
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ExpenseType", CostTypes);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	
	CallbackDescription = New CallbackDescription("FillInTheCostingItemCompletion", ThisObject, AdditionalParameters);
	OpenForm("Catalog.ProductCostElements.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure RecipientDataTable(TSName)
	
	TSParameters = New Structure;
	TSParameters.Insert("NameTSForm"  , TSName);
	TSParameters.Insert("NameTsObject" , TSName);
	
	If TSName = "ManufacturedProducts" Then
		TSParameters.Insert("PresentationOfTS" , NStr("vi = 'Sản phẩm đầu ra';
														|ru = 'Выходные изделия';
														|en = 'Finished products'; fa = 'Finished products';
														|it = 'Prodotti finiti';
														|pl = 'Wyroby gotowe';
														|tr = 'Üretilen nihai ürünler'"));
	ElsIf TSName = "SideAndIntermediateRelease" Then
		TSParameters.Insert("PresentationOfTS" , NStr("vi = 'Sản phẩm phụ';
														|ru = 'Побочные изделия';
														|en = 'By-products'; fa = 'By-products';
														|it = 'Sottoprodotti';
														|pl = 'Produkty uboczne';
														|tr = 'Yan nihai ürünler'"));
	EndIf;
	
	TSParameters.Insert("WarehouseInHeader", False);
	TSParameters.Insert("Filter", New Structure("IsFolder", False));
	
	CallbackDescription =
		New CallbackDescription(
			"FillInRecipientCompletion",
			ThisObject,
			New Structure("TSParameters", TSParameters));
	
	ItemsTypes = New Array;
	ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	ProductionClient.OpenRecipientSelectionForm(
		ThisObject,
		Object,
		TSParameters,
		ItemsTypes,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure TableCopyRows(TSName)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		CopyLinesOnServer(TSName);
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items[TSName].SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRowsTable(TSName)
	
	NumberOfProductsBeforeInsertion = Object[TSName].Count();
	
	GetLinesFromClipboard(TSName);
	
	NumberOfInserted = Object[TSName].Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
		
EndProcedure

&AtClient
Procedure TableSplitRow(TSName)
	
	FormTable  = Items[TSName];
	TableData = Object[TSName];
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	Notification = New CallbackDescription("TableSplitRowCompletion", ThisObject, AdditionalParameters);
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	If TSName = "Services" Then
		StringSplittingParameters.FieldNameQuantity = "Count";
		StringSplittingParameters.Title = NStr("vi = 'Hãy nhập số lượng công việc trong dòng mới';
												|ru = 'Введите количество работ в новой строке';
												|en = 'Enter quantity of works in a new line'; fa = 'Enter quantity of works in a new line';
												|it = 'Inserire la quantità di lavori nella nuova riga';
												|pl = 'Wprowadź ilość prac w nowym wierszu';
												|tr = 'Yeni satırdaki iş miktarını girin'");
	EndIf;
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure BarcodeSearchTable(TSName)
	
	ClearMessages();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	Notification = New CallbackDescription("BarcodeSearchTableCompletion", ThisObject, AdditionalParameters);
	
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure TableImportDataFromPDT(TSName)
	
	ClearMessages();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	Notification = New CallbackDescription("DownloadTableFromTSDCompletion", ThisObject, AdditionalParameters);
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(Notification, UUID);
	
EndProcedure

#EndRegion

#Region ObjectCommands_

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

#EndRegion

#Region StandardCommands

#Region WorkingWithCounterparties

&AtClient
Procedure CheckCounterparties(Command)
	
	Return;
	
EndProcedure





#EndRegion

#Region FilesOperations

&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure

#EndRegion

#Region AttachableCommands

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// StandardSubsystems.SourceDocumentsOriginalsRecording

&AtClient
Procedure Attachable_OriginalStateDecorationClick()
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject, Items.OriginalStateDecoration);
EndProcedure

//End StandardSubsystems.SourceDocumentsOriginalsRecording

#EndRegion

// IntegrationWith1CDocumentManagementSubsystem
#Region IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

#EndRegion
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#EndRegion

#Region Private

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region StandardLayoutTabularParts

	EstablishConditionalAppearanceOfProductCharacteristics("ManufacturedProducts");
	EstablishConditionalAppearanceOfProductCharacteristics("SideAndIntermediateRelease");
	EstablishConditionalAppearanceOfProductCharacteristics("MaterialsAndWorks");
	EstablishConditionalAppearanceOfProductCharacteristics("Services");
	
	SetConditionalAppearanceOfUnitsOfMeasurement("ManufacturedProducts");
	SetConditionalAppearanceOfUnitsOfMeasurement("SideAndIntermediateRelease");
	SetConditionalAppearanceOfUnitsOfMeasurement("MaterialsAndWorks");
	
	SetConditionalAppearanceOfProductAssignment("ManufacturedProducts");
	SetConditionalAppearanceOfProductAssignment("SideAndIntermediateRelease");
	SetConditionalAppearanceOfProductAssignment("MaterialsAndWorks");
	
	EstablishConditionalAppearanceOfProductSeries("ManufacturedProducts");
	EstablishConditionalAppearanceOfProductSeries("SideAndIntermediateRelease");
	EstablishConditionalAppearanceOfProductSeries("MaterialsAndWorks");
	
	#Region VATAccounting
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(
		ThisObject,
		"ServicesVATRate",
		"ServicesVATAmount",
		"ServicesAmountIncludingVAT");
	
	VATAccountingERP.SetConditionalAppearanceOfVATAmountsAtPurchaseVATRate(
		ThisObject,
		"ServicesVATRate",
		"ServicesVATAmount");
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject, "ServicesAmountIncludingVAT");
	
	#EndRegion
	
	#EndRegion
	
	#Region GroupCosts
	
	#Region CostGroups
	
	// Setting the visibility of the cost group column of output items from the type of grouping
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsExpenseGroup.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Setting the visibility of the cost group column from the number of groups
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsExpenseGroup.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SideAndIntermediateReleaseExpenseGroup.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksExpenseGroup.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesExpenseGroup.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NumberOfCostGroups");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#EndRegion
	
	#Region ManufacturedProducts
	
	#Region BillOfMaterials
	
	// The specification is required only for the "By specifications" and "By specifications and assignments" groups
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsBillOfMaterials.Name);
	
	Groups = New ValueList;
	Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductBOM);
	Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = Groups;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The specification is not edited during order production
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsBillOfMaterials.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Groups = New ValueList;
	Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductBOM);
	Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments);
	Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductionStages);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = Groups;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region CostShare
	
	// Setting the percentage registration
	ProductionServer.SetConditionalAppearanceOfShareCostPercentageField(ThisObject, "Object", "ManufacturedProducts");
	
	// Setting the visibility of the Cost Share column by cost grouping
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsCostShare.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsCostSharePercentage.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsThereAreErrorsOfFillingInCostShare.Name);
	
	Groups = New ValueList;
	Groups.Add(Enums.CostGroupingsInTollingOrder.ByProducts);
	Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = Groups;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region TargetCost
	
	// Visibility of planned cost fields.
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsPrice.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseTargetCost");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region ExpenseAs
	
	SetConditionalAppearanceWriteOffForExpenses_("ManufacturedProducts");
	
	#EndRegion
	
	#Region Recipient
	
	SetConditionalAppearanceRecipient("ManufacturedProducts");
	
	#EndRegion
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	#Region ExpenseAs
	
	SetConditionalAppearanceWriteOffForExpenses_("SideAndIntermediateRelease");
	
	#EndRegion
	
	#Region Recipient
	
	SetConditionalAppearanceRecipient("SideAndIntermediateRelease");
	
	#EndRegion
	
	#EndRegion
	
	#Region MaterialsAndWorks
	
	// Visibility of the "Main" column
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksMain.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Only viewing the "Main" column
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksMain.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.ThereIsImportedProduct");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting the bold font of the main materials
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorks.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.Main");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
	
	#EndRegion
	
	#Region Other
	
	#Region LinesOfBusiness
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	#EndRegion
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceOfProductCharacteristics(TSName)
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, 
		TSName + "Characteristic",
		"Object." + TSName + ".ItemVariantsAreUsed");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfUnitsOfMeasurement(TSName)
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = TSName + "ProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object." + TSName + ".Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfProductAssignment(TSName)
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(
		ThisObject,
		TSName + "Purpose",
		"Object." + TSName + ".ItemsType",
		False);
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		
		DestinationField_ = Items[TSName + "Purpose"]; // FormField
		
		// the assignment is not available if the line is by order
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(DestinationField_.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".SubcontractOrder");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".RowCode");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = 0;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
		If TSName = "ManufacturedProducts" Then
			
			// assignment is not necessary if it does not participate in cost grouping
			Item = ConditionalAppearance.Items.Add();
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(DestinationField_.Name);
			
			Groups = New ValueList;
			Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments);
			Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments);
			
			OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			
			ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue  = New DataCompositionField("Object.GroupCosts");
			ItemFilter.ComparisonType   = DataCompositionComparisonType.NotInList;
			ItemFilter.RightValue = Groups;
			
			ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue  = New DataCompositionField("Object.ByOrders");
			ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
			
			Item.Appearance.SetParameterValue("MarkIncomplete", False);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceOfProductSeries(TSName)
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		"SeriesAlwaysWHGoods", 
		TSName + "Series", 
		"Object." + TSName + ".BatchesIndicationStatus",
		"Object." + TSName + ".ItemsType");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceWriteOffForExpenses_(TSName)
	
	// the purpose is not indicated when writing off expenses
	Item = ConditionalAppearance.Items.Add();
	
	DestinationField_ = Items[TSName + "Purpose"]; // FormField
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(DestinationField_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor"     , StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text"          , NStr("vi = '<không được sử dụng để ghi giảm vào chi phí>';
															|ru = '<не используется при списании на расходы>';
															|en = '<not used while writing off as expenses>'; fa = '<not used while writing off as expenses>';
															|it = '<non viene usato durante storno sulle spese>';
															|pl = '<nie używane podczas rozchodu na wydatki>';
															|tr = '<giderlere yazılırken kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceRecipient(TSName)
	
	RecipientField = Items[TSName + "Recipient"]; // FormField
	
	// The recipient, when the flag is set, is charged for expenses with the type work
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(RecipientField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ItemsType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".Recipient");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.Department"));
	
	// The recipient with the unchecked flag is charged for expenses with the type work
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(RecipientField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ItemsType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".Recipient");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Recipient for the types of goods / multi-turn packaging	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(RecipientField.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ItemsType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text",          NStr("vi = '<dành cho công việc>';
															|ru = '<для работ>';
															|en = '<for works>'; fa = '<for works>';
															|it = '<per i lavori>';
															|pl = '<dla robót>';
															|tr = '<iş için>'"));
	Item.Appearance.SetParameterValue("TextColor",     StyleColors.InaccessibleCellTextColor);
	
EndProcedure

#EndRegion

#Region ConfiguringFormElements

&AtServer
Procedure CustomizeFormElements()
	
	ConfigureDependentFormElements(ThisObject);
	ConfigureDependentFormElementsOnServer();
	FillInCostGroupingSelectionList();
	FillInRecyclingServiceSelectionList();
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
	ConfigureClipboardCommands(ThisObject, ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
	Items.ManufacturedProductsToRefillCostlyTS.Visible = UseProduction;
	
	Items.OrderInvoiceGroup.Visible = GetFunctionalOption("UseSubcontractOrders2_5");
	
	ProductDataManagement.SetSpecificationSelectionParameters(Items.ManufacturedProductsBillOfMaterials, BOMSelectionParameters);
	
	Items.ManufacturedProductsSeries.Visible =
		SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	Items.SideAndIntermediateReleaseSeries.Visible =
		SeriesSpecificationParameters.SideAndIntermediateRelease.UseItemsBatch;
	Items.MaterialsAndWorksSeries.Visible =
		SeriesSpecificationParameters.MaterialsAndWorks.UseItemsBatch;
	
	Items.OutputProductsSpecifyTheSeries.Visible =
		SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	Items.ByProductsSpecifyTheSeries.Visible =
		SeriesSpecificationParameters.SideAndIntermediateRelease.UseItemsBatch;
	Items.MaterialsAndWorksSpecifyTheSeries.Visible =
		SeriesSpecificationParameters.MaterialsAndWorks.UseItemsBatch;
	
	Items.OutputProductsFillInThePlannedPrices.Visible = UseTargetCost;
	
	If Not AccessRight("Update", Metadata.Documents.SubcontractOrder2_5) Then
		Items.CloseOrder.Enabled = False;
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm
// 	AttributesList - String
&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	Object = Form.Object;
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	SpecifiedOrder =
		ValueIsFilled(Object.SubcontractOrder);
	
	If Initialize
		Or AttributesList.Property("ThereAreAdjustingEntries")
		Or AttributesList.Property("ByOrders") Then
		Items.ProcessingServices.ReadOnly = 
			SpecifiedOrder
			Or Form.ThereAreAdjustingEntries;
	EndIf;
	
	If Initialize
		Or AttributesList.Property("GroupCosts")
		Or AttributesList.Property("ByOrders") Then
		
		Items.GroupFinishedProducts.Visible =
			Not Object.GroupCosts =
				PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
			Or (SpecifiedOrder
				And Form.ThereIsReleaseStage)
			Or Not SpecifiedOrder;
		
		If Not Object.GroupCosts =
				PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
			Or (SpecifiedOrder
				And Form.ThereIsReleaseStage)
			Or Not SpecifiedOrder Then
			Items.GroupByProducts_2.Behavior = UsualGroupBehavior.Collapsible;
		Else
			Items.GroupByProducts_2.Behavior = UsualGroupBehavior.Usual;
		EndIf;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("GroupCosts") Then
		
		Items.MethodOfAllocatingFinishedProductCosts.Visible =
			Object.GroupCosts =
					PredefinedValue("Enum.CostGroupingsInTollingOrder.NoGrouping")
			Or Object.GroupCosts =
					PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOM")
			Or Object.GroupCosts =
					PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments");
		
		ConfigureCostGroupElements(Form);
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("ByOrders") Then
		
		Items.Organization.ReadOnly             = SpecifiedOrder;
		Items.Department.ReadOnly           = SpecifiedOrder;
		Items.Partner.ReadOnly                 = SpecifiedOrder;
		Items.Counterparty.ReadOnly              = SpecifiedOrder;
		Items.Contract.ReadOnly                 = SpecifiedOrder;
		Items.GroupCosts.ReadOnly       = SpecifiedOrder;
		
		Items.CloseOrder.Visible =
			SpecifiedOrder
			And Not Object.GroupCosts =
				PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages");
		
		Items.OutputProductsFillTSAccordingToOrderSpecification.Visible = SpecifiedOrder;
		Items.SelectOutputProductsFromOrder.Visible               = SpecifiedOrder;
		Items.ByProductsToPickUpFromOrder.Visible               = SpecifiedOrder;
		
		ItemVisibility =
			SpecifiedOrder
			Or Not Object.ByOrders
				And Form.UseProduction;
		
		Items.ByProductsFillTSAccordingToOrderSpecification.Visible  = ItemVisibility;
		Items.MaterialsAndWorkFillTSAccordingToSpecificationOrder.Visible = ItemVisibility;
		Items.ServicesFillTSByOrderSpecification.Visible           = ItemVisibility;
		
		If ItemVisibility Then
			
			ItemTitle = NStr("vi = 'Theo đơn hàng';
							|ru = 'По заказу';
							|en = 'Against order'; fa = 'در مقابل سفارش';
							|it = 'Per ordine';
							|pl = 'Wg umowy';
							|tr = 'Siparişe göre'");
			If Not Object.ByOrders Then
				ItemTitle = NStr("vi = 'Theo bảng kê chi tiết';
								|ru = 'По спецификациям';
								|en = 'By bills of materials'; fa = 'بر اساس فهرست‌های مواد';
								|it = 'In base alle specifiche';
								|pl = 'Wg specyfikacji';
								|tr = 'Ürün reçetelerine göre'");
			EndIf;
			
			Items.ByProductsFillTSAccordingToOrderSpecification.Title  = ItemTitle;
			Items.MaterialsAndWorkFillTSAccordingToSpecificationOrder.Title = ItemTitle;
			Items.ServicesFillTSByOrderSpecification.Title           = ItemTitle;
			
		EndIf;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("ProcessingServices") Then
		
		UseServices = 
			Object.ProcessingServices =
				PredefinedValue("Enum.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder");
		
		Items.PaymentGroup_2.Visible                 = UseServices;
		Items.GroupInTotal.Visible                  = UseServices;
		Items.TaxInvoiceGroup.Visible            = UseServices;
		Items.ServicesPage.Visible               = UseServices;
		Items.CompanyBankAccount.Visible    = UseServices;
		Items.CounterpartyBankAccount.Visible    = UseServices;
		Items.FinancialAccountingGroup.Visible       = UseServices;
		Items.RegisterVendorPrices.Visible = UseServices;
		
		If UseServices Then
			Form.InvoiceTextReceived = SubmissionOfInvoicesReceived(Object);
		EndIf;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("VATTaxation") Then
		
		If VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(Object.VATTaxation) Then
			Items.PageGroupDocumentAmount.CurrentPage = Items.PageVAT;
		Else
			Items.PageGroupDocumentAmount.CurrentPage = Items.PageExcludingVAT;
		EndIf;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("BusinessOperation") Then 
	
		If Form.Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5") Then
			
			Form.Items.PageGroupDocumentAmount.CurrentPage = Form.Items.PageExcludingVAT;
			Form.Items.PageVAT.Visible        = False;
			Form.Items.FieldWithoutNdsproduction.Visible = False;
			
		Else
			
			Form.Items.PageVAT.Visible        = True;
			Form.Items.FieldWithoutNdsproduction.Visible = True;
			
		EndIf; 
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(AttributesList = "")
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("Partner")
		Or AttributesList.Property("Counterparty") 
		Or AttributesList.Property("Organization") Then
		ConfigureCounterpartyAgreementElement();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsByOrder(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	Items.PictureDiscrepancyOrder.Visible =
		ValueIsFilled(Object.SubcontractOrder)
		And Not Form.QuantityOverOrder = 0;
			
	If Form.QuantityOverOrder > 0 Then
		Form.DiscrepancyOrderText = NStr("vi = 'Các dòng phía trên đơn hàng: %1';
										|ru = 'Строк сверх заказа: %1';
										|en = 'Lines exceeding the order: %1'; fa = 'Lines exceeding the order: %1';
										|it = 'Righe in eccesso rispetto all''ordine: %1';
										|pl = 'Wierzy przewyższających zamówienie: %1';
										|tr = 'Sipariş fazlası satırı: %1'");
		Form.DiscrepancyOrderText = StrTemplate(Form.DiscrepancyOrderText, Form.QuantityOverOrder);
		Items.PictureDiscrepancyOrder.Picture  = PictureLib.ExceededOrder;
	Else
		Form.DiscrepancyOrderText = "";
		Items.PictureDiscrepancyOrder.Picture  = PictureLib.AnEmptyPicture;
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm
// 	List of Requirements - Line
&AtClientAtServerNoContext
Procedure ConfigureCostGroupElements(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If Not Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.NoGrouping") Then
		
		ListOfCostGroupFields =
			?(Object.ByOrders,
				ProcessingByThirdPartiesClientServer.ListOfOrderCostGroupFieldsForProcessor(Object.GroupCosts),
				ProcessingByThirdPartiesClientServer.ListOfCostGroupFieldsInProcessorSReport(Object.GroupCosts));
		
		GroupTitle = ProcessingByThirdPartiesClientServer.CostGroupFieldHeader2_5(ListOfCostGroupFields);
		
		Item = Items.ManufacturedProductsExpenseGroup; // FormField
		Item.Title  = GroupTitle;
		
		Item = Items.SideAndIntermediateReleaseExpenseGroup; // FormField
		Item.Title  = GroupTitle;
		
		Item = Items.MaterialsAndWorksExpenseGroup; // FormField
		Item.Title  = GroupTitle;
		
		Item = Items.ServicesExpenseGroup; // FormField
		Item.Title  = GroupTitle;
		
		TooltipTemplate = ProcessingByThirdPartiesClientServer.CostGroupFieldHintTemplate2_5(Object.GroupCosts);
			
		Items.ManufacturedProductsExpenseGroup.ToolTip = StrTemplate(TooltipTemplate, NStr("vi = 'sản phẩm';
																							|ru = 'изделие';
																							|en = 'finished product'; fa = 'finished product';
																							|it = 'prodotto';
																							|pl = 'finished product';
																							|tr = 'nihai ürün'"));
		Items.SideAndIntermediateReleaseExpenseGroup.ToolTip = StrTemplate(TooltipTemplate, NStr("vi = 'sản phẩm';
																								|ru = 'изделие';
																								|en = 'finished product'; fa = 'finished product';
																								|it = 'prodotto';
																								|pl = 'finished product';
																								|tr = 'nihai ürün'"));
		Items.ServicesExpenseGroup.ToolTip          = StrTemplate(TooltipTemplate, NStr("vi = 'dịch vụ';
																						|ru = 'услуга';
																						|en = 'service'; fa = 'service';
																						|it = 'servizio';
																						|pl = 'service';
																						|tr = 'hizmet'"));
		Items.MaterialsAndWorksExpenseGroup.ToolTip = StrTemplate(TooltipTemplate, NStr("vi = 'nguyên vật liệu/công việc';
																						|ru = 'материал/работа';
																						|en = 'material/work'; fa = 'material/work';
																						|it = 'materiale/lavoro';
																						|pl = 'material/work';
																						|tr = 'malzeme/iş'"));
		
	EndIf;
	
	OpenButton =
		Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages");
	
	Items.ManufacturedProductsExpenseGroup.OpenButton  = OpenButton;
	Items.SideAndIntermediateReleaseExpenseGroup.OpenButton  = OpenButton;
	Items.ServicesExpenseGroup.OpenButton           = OpenButton;
	Items.MaterialsAndWorksExpenseGroup.OpenButton = OpenButton;
	
EndProcedure

&AtServer
Procedure SetSubscriptionForFormElementChangeEvents()
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("Date");
	ItemArray.Add("Organization");
	ItemArray.Add("Department");
	ItemArray.Add("Partner");
	ItemArray.Add("Counterparty");
	ItemArray.Add("Contract");
	ItemArray.Add("GroupCosts");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("PurchaseForActivity");
	ItemArray.Add("LineOfBusiness");
	ItemArray.Add("ByOrders");
	
	// Controls related to payment
	ItemArray.Add("CompanyBankAccount");
	ItemArray.Add("CounterpartyBankAccount");
	ItemArray.Add("ARAPObjectSettings");
	ItemArray.Add("PaymentMethod");
	
	If Not Object.ByOrders Then
		
		NamesOfTSElements = New Array;
		
		NamesOfTSElements.Add("ManufacturedProductsExpenseGroup");
		NamesOfTSElements.Add("ManufacturedProductsProducts");
		NamesOfTSElements.Add("ManufacturedProductsCharacteristic");
		NamesOfTSElements.Add("ManufacturedProductsPurpose");
		NamesOfTSElements.Add("ManufacturedProductsSeries");
		NamesOfTSElements.Add("ManufacturedProductsNumberOfPackages");
		NamesOfTSElements.Add("ManufacturedProductsPackage");
		NamesOfTSElements.Add("ManufacturedProductsBillOfMaterials");
		
		ExceptionNames = New Array;
		AddExceptionNamesOfSubordinateElements(Items.ManufacturedProducts, NamesOfTSElements, ExceptionNames);
		
		// Controls associated with the output TablerefErences
		ItemArray.Add("ManufacturedProducts;BeforeAddRow,BeforeDeleteRow;" + StrConcat(ExceptionNames, ","));
		
		// Commands related to the output TablerefErences
		ItemArray.Add("OutputProductsAdd");
		ItemArray.Add("CopyOutputItems");
		ItemArray.Add("OutputProductsDelete");
		ItemArray.Add("ManufacturedProductsInsertRows");
		ItemArray.Add("FinishedProductsSearchByBarcode");
		ItemArray.Add("ManufacturedProductsImportDataFromPDT");
		
		ItemArray.Add("OutputProductsContextMenuAdd");
		ItemArray.Add("OutputProductsContextMenuCopy");
		ItemArray.Add("OutputItemsContextMenuDelete");
		
		ItemArray.Add("ManufacturedProductsPickUpProducts");
		ItemArray.Add("SelectOutputProductsFromOrder");
		ItemArray.Add("ManufacturedProductsToRefillCostlyTS");
		ItemArray.Add("OutputItemsFillCostGroup");
		ItemArray.Add("OutputProductsSpecifyTheSeries");
		ItemArray.Add("OutputProductsTransferToByProducts");
		
	EndIf;
	
	NamesOfTSElements = New Array;
	NamesOfTSElements.Add("ServicesExpenseGroup");
	NamesOfTSElements.Add("ServicesProducts");
	NamesOfTSElements.Add("ServicesCharacteristic");
	NamesOfTSElements.Add("ServicesCount");
	NamesOfTSElements.Add("ServicesVendorPriceKind");
	NamesOfTSElements.Add("ServicesPrice");
	NamesOfTSElements.Add("ServicesSum");
	NamesOfTSElements.Add("ServicesVATAmount");
	NamesOfTSElements.Add("ServicesVATRate");
	NamesOfTSElements.Add("ServicesAmountIncludingVAT");
	NamesOfTSElements.Add("ServicesProductCostElement");
	
	ExceptionNames = New Array;
	AddExceptionNamesOfSubordinateElements(Items.Services, NamesOfTSElements, ExceptionNames);
	
	// Controls associated with the Services table
	ItemArray.Add("Services;BeforeAddRow,BeforeDeleteRow,BeforeRowChange;" + StrConcat(ExceptionNames, ","));
	
	// Commands related to the Services table
	ItemArray.Add("AddServices");
	ItemArray.Add("CopyServices");
	ItemArray.Add("DeleteServices");
	ItemArray.Add("ServicesInsertRows");
	ItemArray.Add("BarcodeSearchServices");
	ItemArray.Add("ServicesImportDataFromPDT");
	
	ItemArray.Add("ServicesContextMenuAdd");
	ItemArray.Add("CopyContextMenuServices");
	ItemArray.Add("ServicesContextMenuDelete");
	
	ItemArray.Add("ServicesPickUpProducts");
	ItemArray.Add("ServicesFillTSByOrderSpecification");
	ItemArray.Add("ServicesFillInPricesBySupplierPriceType");
	ItemArray.Add("ServicesFillCostGroup");
	ItemArray.Add("ServicesSelectAndCompleteService");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
EndProcedure

&AtServer
Procedure ConfigureCounterpartyAgreementElement()
	
	ObjectParameters = New Structure("Partner, Counterparty, Organization, Contract");
	FillPropertyValues(ObjectParameters, Object);
	
	PurchasesServer.SetContractAvailability(
		ObjectParameters,
		Items.Contract.Enabled,
		False,
		Object.Contract);
	
EndProcedure

&AtServer
Procedure FillInCostGroupingSelectionList()
	
	UsageParameters = Enums.CostGroupingsInTollingOrder.UsageParameters();
	
	UsageParameters.ByProductBOM = UseProduction;
	
	If GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		UsageParameters.ByProductsAndAssignments     = True;
		UsageParameters.ByProductBOMAndAssignments = UseProduction;
	EndIf;
	If Not Object.ByOrders Then
		UsageParameters.ByProductionStages = False;
	EndIf;
	Enums.CostGroupingsInTollingOrder.FillInSelectionData(
		Items.GroupCosts.ChoiceList,
		UsageParameters);
	
EndProcedure

&AtServer
Procedure FillInRecyclingServiceSelectionList()
	
	Items.ProcessingServices.ChoiceList.Clear();
	
	ServicesAreSpecifiedInOrderReport = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder;
	PresentationServicesAreSpecifiedInOrderReport = "";
	If Not Object.ByOrders Then
		PresentationServicesAreSpecifiedInOrderReport = NStr("vi = 'Chỉ ra trong báo cáo';
															|ru = 'Указываются в отчете';
															|en = 'Specified in the report'; fa = 'Specified in the report';
															|it = 'Vengono specificati nei report';
															|pl = 'Wskazywane w raporcie';
															|tr = 'Raporda belirtilmektedir'");
	EndIf;
	
	Items.ProcessingServices.ChoiceList.Add(ServicesAreSpecifiedInOrderReport, PresentationServicesAreSpecifiedInOrderReport);
	
	ServicesAreIssuedSeparately = Enums.OptionsOfRegisteringProcessingDocumentServices.RegisteredSeparately;
	
	Items.ProcessingServices.ChoiceList.Add(ServicesAreIssuedSeparately);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm
// 	ItemsAvailability - Boolean
&AtClientAtServerNoContext
Procedure ConfigureClipboardCommands(Form, ItemsAvailability)
	
	Items = Form.Items;
	
	Item = Items.ManufacturedProductsInsertRows; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.OutputItemsContextMenuInsertLines; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.ByProductsInsertRows; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.ByProductsContextMenuInsertLines; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.MaterialsAndWorksInsertLines; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.MaterialsAndWorksContextMenuInsertLines; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.ServicesInsertRows; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.ServicesContextMenuInsertRows; // FormButton
	Item.Enabled = ItemsAvailability;
	
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

#EndRegion

#Region FormEventHandlers

#Region FormEvents

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInServiceDetails();
	FillInDependentServiceDetailsOnServer();
	FillInServiceDetailsOfTableParts();
	UpdateCostGroups();
	
	UpdatePurchaseForActivity(, False);
	UpdateVATTaxation_(, False);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	UpdateInvoiceText(New Structure);
	
	CalculateDocumentTotals(ThisObject);
	CustomizeFormElements();
	SetSubscriptionForFormElementChangeEvents();
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected, TSName)
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	ValueSelected.Insert("TSName", TSName);
	
	ProcessingSelectionOfSelectionOnServer(ValueSelected, TSName);
	
EndProcedure

&AtClient
Procedure HandlingSelectionSelectionOnClientCompletion(Response, ValueSelected) Export
	
	If Response = DialogReturnCode.Yes Then
		Object.NotShipInInstallments = False;
		ConfigureDependentFormElements(ThisObject, "NotShipInInstallments");
	EndIf;
	
	ProcessingSelectionOfSelectionOnServer(ValueSelected, ValueSelected.TSName);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected, TSName)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	DocumentTable = Object[TSName]; // FormDataCollection
	
	If TSName = "ManufacturedProducts"
			And UseTargetCost
		Or TSName = "SideAndIntermediateRelease" Then
		ListOfProperties = "Products, Characteristic, Package, Price, NumberOfPackages, Count";
	ElsIf TSName = "ManufacturedProducts" Then
		ListOfProperties = "Products, Characteristic, Package, NumberOfPackages, Count";
	ElsIf TSName = "MaterialsAndWorks" Then
		ListOfProperties = "Products, Characteristic, Package, NumberOfPackages, Count";
	ElsIf TSName = "Services" Then
		ListOfProperties = "Products, Characteristic, VendorPriceKind, Price, Count";
	EndIf;
	
	Groups = New Array;
	DimensionsToFillIn = New Array;
	
	ProductData_2 = New Array;
	RowsToProcess = New Array;
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentData = DocumentTable.Add();
		FillPropertyValues(CurrentData, RowOfProduct, ListOfProperties);
		
		If TSName = "ManufacturedProducts"
			And Not Object.ByOrders Then
			
			ProductData_2.Add(
				ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
					Object, CurrentData, BOMSelectionParameters, ThisObject));
			
		EndIf;
		
		RowsToProcess.Add(CurrentData);
		
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	
	AddActionsFillInServiceDetailsOfProductItem(TSName, StructureOfActions);
	AddActionsFillInVATRate(ThisObject, TSName, StructureOfActions);
	AddActionsForRecalculatingAmounts(ThisObject, TSName, StructureOfActions);
	AddActionsClearFillArticleAnalytics(ThisObject, TSName, StructureOfActions);
	AddActionsCheckSeriesCalculateStatus(ThisObject, TSName, StructureOfActions);
	
	If Not TSName = "MaterialsAndWorks" Then
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ByOrders);
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		DocumentTable,
		CachedValues);
	
	For Each CurrentData In RowsToProcess Do
		
		If TSName = "ManufacturedProducts" Then
			
			If Not Object.ByOrders Then
				AddChangeCostGroup(CurrentData, True);
			Else
				SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
			EndIf;
			
			Groups.Add(CurrentData.CostGroupNumber);
			
		Else
			SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
		EndIf;
		
		DimensionsToFillIn.Add(CurrentData.CostGroupNumber);
		
	EndDo;
	
	StructureOfActions = New Structure;
	AddActionsCheckFillShareCost(ThisObject, TSName, StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(TableOfGoods, StructureOfActions);
	
	If TSName = "ManufacturedProducts" Then
		CalculatePercentageOfCostAllocationForOutputProducts(Groups);
	EndIf;
	
	If Not DimensionsToFillIn.Count() = 0 Then
		DimensionsToFillIn = CommonClientServer.CollapseArray(DimensionsToFillIn);
		For Each CurGroup In DimensionsToFillIn Do
			TableFillInDependentServiceDetailsOfCostGroup(TSName, CurGroup);
		EndDo;
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		AttributesList = "QuantityOverOrder,NumberOfProducts,TheRecordsAreKeptByCCD";
	ElsIf TSName = "Services" Then
		AttributesList = "QuantityOverOrder,AmountOfServices";
	Else
		AttributesList = "NotExecuteJob";
	EndIf;
	
	CalculateDocumentTotals(ThisObject, AttributesList);
	
EndProcedure

&AtServer
Procedure SelectionProcessingSelectionOfTransferredGoods(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	DimensionsToFillIn = New Array;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	AddActionsFillInServiceDetailsOfProductItem("MaterialsAndWorks", StructureOfActions);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	AddActionsFillInServiceDetailsOfProductItem("MaterialsAndWorks", StructureOfActions);
	AddActionsCheckSeriesCalculateStatus(ThisObject, "MaterialsAndWorks", StructureOfActions);
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		ProductsSearch = New Structure();
		ProductsSearch.Insert("Products", RowOfProduct.Products);
		ProductsSearch.Insert("Characteristic", RowOfProduct.Characteristic);
		ProductsSearch.Insert("Purpose", RowOfProduct.Purpose);
		ProductsSearch.Insert("Series", RowOfProduct.Series);
		ProductLines_2 = Object.MaterialsAndWorks.FindRows(ProductsSearch);
		
		If ProductLines_2.Count() = 0 Then
			
			CurrentData = Object.MaterialsAndWorks.Add();
			FillPropertyValues(CurrentData, RowOfProduct);
			
			SetDefaultCostGroupNumber("MaterialsAndWorks", CurrentData.GetID());
			DimensionsToFillIn.Add(CurrentData.CostGroupNumber);
			
		ElsIf ProductLines_2.Count() = 1 Then
			
			CurrentData = ProductLines_2[0];
			
		ElsIf ProductLines_2.Count() > 1 Then
			
			For Each RowToDelete In ProductLines_2 Do
				Object.MaterialsAndWorks.Delete(RowToDelete);
			EndDo;
			
			CurrentData = Object.MaterialsAndWorks.Add();
			FillPropertyValues(CurrentData, RowOfProduct);
			
			SetDefaultCostGroupNumber("MaterialsAndWorks", CurrentData.GetID());
			DimensionsToFillIn.Add(CurrentData.CostGroupNumber);
			
		EndIf;
		
		CurrentData.Count = RowOfProduct.QuantityIsSelected;
		
		RowsToProcess.Add(CurrentData);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.MaterialsAndWorks,
		CachedValues);
	
	If Not DimensionsToFillIn.Count() = 0 Then
		DimensionsToFillIn = CommonClientServer.CollapseArray(DimensionsToFillIn);
		For Each CurGroup In DimensionsToFillIn Do
			TableFillInDependentServiceDetailsOfCostGroup("MaterialsAndWorks", CurGroup);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function PlaceGoodsInStorageForSelectionOfTransferredGoods()
	
	Address = PutToTempStorage(
		Object.MaterialsAndWorks.Unload(,"LineNumber, Products, Characteristic, Purpose, Series, Count"),
		UUID);
	
	Return Address;
	
EndFunction

#EndRegion

#Region FormItems

#Region IsMain

&AtClient
Procedure RemoveInvoiceOnOrderCompletion(Response, AdditionalParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.SubcontractorReport2_5.Form.DocumentForm.InvoiceByOrder");
	
	If Response = DialogReturnCode.Yes Then
		RemoveInvoiceForOrderOnServer();
	Else
		Object.ByOrders = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure RemoveInvoiceForOrderOnServer()

	Object.SubcontractOrder = Undefined;
	Object.GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping;
	Object.MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	
	Object.ManufacturedProducts.Clear();
	Object.SideAndIntermediateRelease.Clear();
	Object.MaterialsAndWorks.Clear();
	Object.Services.Clear();
	
	ThereIsReleaseStage = False;
	
	GroupingCostsForChangesOnServer();
	
	FillInRecyclingServiceSelectionList();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "OrderInvoice_3");
	
	FillInDependentServiceDetailsOnServer("ByOrders");
	CalculateDocumentTotals(ThisObject);
	CustomizeFormElements();
	SetSubscriptionForFormElementChangeEvents();
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	UpdatePurchaseForActivity();
	
	StructureOfActions = New Structure;
	AddActionsFillInVATRate(ThisObject, "Services", StructureOfActions);
	AddActionsForRecalculatingAmounts(ThisObject, "Services", StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(Object.Services, StructureOfActions, Undefined);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Date");
	
	FillInDependentServiceDetailsOnServer("Date");
	MethodForAllocatingCostsForOutputProductsWhenChangingOnServer();
	
	CalculateDocumentTotals(ThisObject, "AmountOfServices");
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer(ChangesTakenIntoAccount = Undefined)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	TheCounterpartyPriorToTheChange = Object.Counterparty;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	If TheCounterpartyPriorToTheChange <> Object.Counterparty Then
		FillInDefaultContract(ChangesTakenIntoAccount);
	EndIf;
	
	CounterpartyWhenChangesAreMadeOnServer(ChangesTakenIntoAccount);
	AgreementWhenModifiedOnServer(ChangesTakenIntoAccount);
	
	FillInDependentServiceDetailsOnServer("Partner");
	
	If Not ValueIsFilled(Object.SubcontractOrder)
		And UseLinesOfBusiness
		And Not ChangesTakenIntoAccount.Property("LineOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, , Object.Contract);
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("PurchaseForActivity") Then
		UpdatePurchaseForActivity(ChangesTakenIntoAccount);
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("VATTaxation") Then
		UpdateVATTaxation_(ChangesTakenIntoAccount);
	EndIf;
	
	ConfigureDependentFormElementsOnServer("Partner");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Partner");
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	UpdateInvoiceText(ChangesTakenIntoAccount);
	ProcessChangeOfDirection(ChangesTakenIntoAccount);
	
EndProcedure

&AtServer
Procedure CounterpartyWhenChangesAreMadeOnServer(ChangesTakenIntoAccount = Undefined)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	If ChangesTakenIntoAccount.Property("Counterparty") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract(ChangesTakenIntoAccount);
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Object.Counterparty);
		Object.CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(
			ParametersOfAccount, Object.CounterpartyBankAccount);
		
		FillInSubordinatePropertiesForStatistics("Counterparty");
		
	EndIf;
	
	AgreementWhenModifiedOnServer(ChangesTakenIntoAccount);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
	ChangesTakenIntoAccount.Insert("Counterparty");
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer(ChangesTakenIntoAccount = Undefined)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	If ChangesTakenIntoAccount.Property("Contract") Then
		Return;
	EndIf;
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	ContractDetails_ = "Department, Manager, ForeignCurrencyTransaction";
	ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, ContractDetails_);
	For Each CurrentAttribute In ContractDetails_ Do
		If ValueIsFilled(CurrentAttribute.Value) Then
			Object[CurrentAttribute.Key] = CurrentAttribute.Value;
		EndIf;
	EndDo;
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
		Object.CounterpartyBankAccount);
	
	If Not ValueIsFilled(Object.CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
			ParametersOfAccount, Object.CompanyBankAccount, Object.PaymentMethod);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	If Not ValueIsFilled(Object.SubcontractOrder)
		And UseLinesOfBusiness
		And Not ChangesTakenIntoAccount.Property("LineOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, , Object.Contract);
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("PurchaseForActivity") Then
		UpdatePurchaseForActivity(ChangesTakenIntoAccount);
	EndIf;
	
	ContractDetails_ = "ContractType, PurchaseRegistrationOption";
	ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, ContractDetails_);
	Object.BusinessOperation = Catalogs.CounterpartyContracts.BusinessOperation(ContractDetails_.ContractType, ContractDetails_.PurchaseRegistrationOption);
	If Not ValueIsFilled(Object.BusinessOperation) Then
		Object.BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5;
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("VATTaxation") Then
		UpdateVATTaxation_(ChangesTakenIntoAccount);
	EndIf;
	ConfigureDependentFormElements(ThisObject, "BusinessOperation");
	
	ConfigureCounterpartyAgreementElement();
	
	UpdateInvoiceText(ChangesTakenIntoAccount);
	ProcessChangeOfDirection(ChangesTakenIntoAccount);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
	ChangesTakenIntoAccount.Insert("Contract");
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer(ChangesTakenIntoAccount = Undefined)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	If ChangesTakenIntoAccount.Property("Organization") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract(ChangesTakenIntoAccount);
	EndIf;
	
	AgreementWhenModifiedOnServer(ChangesTakenIntoAccount);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(
		Object.Organization,
		Object.CompanyBankAccount,
		Object.PaymentMethod,
		Object.LineOfBusiness,
		Object.ForeignCurrencyTransaction);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	UpdateInvoiceText(ChangesTakenIntoAccount);
	ProcessChangeOfDirection(ChangesTakenIntoAccount);
	
	FillInDependentServiceDetailsOnServer("Organization");
	
	ChangesTakenIntoAccount.Insert("Organization");
	
EndProcedure

&AtServer
Procedure RecyclingServicesWhenChangesAreMadeOnServer()
	
	UseServices = 
		Object.ProcessingServices =
			PredefinedValue("Enum.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder");
	
	If Not UseServices Then
		
		Object.Services.Clear();
		Object.PaymentScheduleSteps.Clear();
		Object.ARAPDetails.Clear();
		
		Object.CompanyBankAccount    = Undefined;
		Object.CounterpartyBankAccount    = Undefined;
		Object.PaymentMethod                  = Undefined;
		Object.ForeignCurrencyTransaction                = Undefined;
		Object.FinancialAccountingGroup       = Undefined;
		
		Object.RegisterVendorPrices = False;
		
		Object.AmountARAP         = 0;
		Object.AmountARAPByOrder = 0;
		Object.DocumentAmount              = 0;
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ProcessingServices");
	
	ConfigureDependentFormElements(ThisObject, "ProcessingServices");
	CalculateDocumentTotals(ThisObject, "QuantityOverOrder");
	
EndProcedure

&AtServer
Procedure MethodForAllocatingCostsForOutputProductsWhenChangingOnServer()
	
	CostAllocationParameters =
		New FixedStructure(Documents.SubcontractorReport2_5.CostAllocationParameters(Object));
	
	If Object.GroupCosts <> Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		ProductionServer.CalculateFractionOfCost(Object, CostAllocationParameters);
	EndIf;
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

&AtServer
Procedure GroupingCostsForChangesOnServer()
	
	If Not ValueIsFilled(Object.GroupCosts) Then
		Object.GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping;
	EndIf;
	
	CostGroups.Clear();
	Object.MaximumNumberOfCostGroup = 0;
	NumberOfCostGroups = 0;
	
	For Each CurrentData In Object.ManufacturedProducts Do
		AddChangeCostGroup(CurrentData, True);
	EndDo;
	
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping Then
		CostGroupIndex = 1;
	ElsIf NumberOfCostGroups = 1 Then
		CostGroupIndex = Object.MaximumNumberOfCostGroup;
	Else
		CostGroupIndex = 0;
	EndIf;
	
	DimensionsToFillIn = New Array;
	DimensionsToFillIn.Add(CostGroupIndex);
	
	For Each CurrentData In Object.SideAndIntermediateRelease Do
		
		DimensionsToFillIn.Add(CurrentData.CostGroupNumber);
		
		CurrentData.CostGroupNumber = CostGroupIndex;
		CurrentData.ExpenseGroup = "";
		
	EndDo;
	
	BasicMaterials = New Map();
	For Each CurrentData In Object.MaterialsAndWorks Do
		
		DimensionsToFillIn.Add(CurrentData.CostGroupNumber);
		
		CurrentData.CostGroupNumber = CostGroupIndex;
		CurrentData.ExpenseGroup = "";
		
		MainMaterial = BasicMaterials.Get(CurrentData.CostGroupNumber);
		If MainMaterial = Undefined Then
			BasicMaterials.Insert(CurrentData.CostGroupNumber, False);
			MainMaterial = BasicMaterials.Get(CurrentData.CostGroupNumber);
		EndIf;
		
		If Not MainMaterial
			And CurrentData.Main Then
			BasicMaterials.Insert(CurrentData.CostGroupNumber, True);
		ElsIf CurrentData.Main Then
			CurrentData.Main = False;
		EndIf;
		
	EndDo;
	
	For Each CurrentData In Object.Services Do
		
		DimensionsToFillIn.Add(CurrentData.CostGroupNumber);
		
		CurrentData.CostGroupNumber = CostGroupIndex;
		CurrentData.ExpenseGroup = "";
		
	EndDo;
	
	For Each CurGroup In CostGroups Do
		TableFillInDependentServiceDetailsOfCostGroup("ManufacturedProducts", CurGroup.CostGroupNumber);
	EndDo;
	
	DimensionsToFillIn = CommonClientServer.CollapseArray(DimensionsToFillIn);
	UpdateServiceDetailsOfCostGroupsInLinkedTS(DimensionsToFillIn);
	
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments Then
		Object.MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.EmptyRef();
	ElsIf Not ValueIsFilled(Object.MethodOfAllocatingFinishedProductCosts) Then
		Object.MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	EndIf;
	
	MethodForAllocatingCostsForOutputProductsWhenChangingOnServer();
	
	ConfigureDependentFormElements(ThisObject, "GroupCosts");
	
	CalculateDocumentTotals(ThisObject);
	
	GroupCostsBeforeChange = Object.GroupCosts;
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		PaymentStagesLabelClickFinishOnServer(ChangedBankingDetails);
	EndIf;
	
EndProcedure

&AtServer
Procedure PaymentStagesLabelClickFinishOnServer(ChangedBankingDetails)
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
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
			If ClosingResult.RecalculateDocumentAmounts Then
				PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	
	If ChangedBankingDetails.Property("ARAPCurrency") Then
		FillInDefaultContract(Undefined);
	EndIf;
	
	If ClosingResult.RecalculateDocumentAmounts Then
		DocumentAmountOnChangeServer(ClosingResult.DocumentAmount);
	EndIf;
	
	If ChangedBankingDetails.Property("Currency") Then
		
		ConvertAmountsOfDocumentSProductsIntoCurrency();
		
		DocumentCurrency = Object.Currency;
		FillInSubordinatePropertiesForStatistics("Currency");
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
EndProcedure

#EndRegion

#Region CommonTableEvents

#Region SetOfSeries

&AtClient
Procedure Attachable_OpenSeriesSelectionWhenScanningProductBarCode_ManufacturedProducts()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.ManufacturedProducts.FindByID(CurDataId);
	OpenSelectionOfSeries("ManufacturedProducts",, CurrentData);

EndProcedure

&AtClient
Procedure Attachable_OpenSeriesSelectionWhenScanningProductBarCode_SideAndIntermediateRelease()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.SideAndIntermediateRelease.FindByID(CurDataId);
	OpenSelectionOfSeries("SideAndIntermediateRelease",, CurrentData);

EndProcedure

&AtClient
Procedure Attachable_OpenSeriesSelectionWhenScanningProductBarCode_MaterialsAndWorks()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.MaterialsAndWorks.FindByID(CurDataId);
	OpenSelectionOfSeries("MaterialsAndWorks",, CurrentData);

EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(TSName, Text = "", CurrentData = Undefined)
	
	NeedServerCall =
		ProductsClient.YouNeedServerCallToSpecifySeries(
			ThisObject,
			SeriesSpecificationParameters[TSName],
			Text,
			CurrentData);
	
	If NeedServerCall Then
		
		If CurrentData = Undefined Then
			CurDataId = Items[TSName].CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(TSName, CurDataId);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
		AdditionalParameters.Insert("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
		
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm(
			ParametersOfSeriesIndicationForm.FormName,
			ParametersOfSeriesIndicationForm,
			ThisObject,,,,
			CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(ClosingResult, AdditionalParameters) Export

	If Not ClosingResult = Undefined Then

		ProcessIndicationOfSeriesOnServer(
			AdditionalParameters.SeriesSpecificationParameters,
			AdditionalParameters.ParametersOfSeriesIndicationForm);

		ProductsSeriesRecalculatePrices(, AdditionalParameters.SeriesSpecificationParameters.NameTSGoods);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessIndicationOfSeriesOnServer(SeriesSpecificationParameters, ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	
	ProductsServer.ProcessSeriesIndication_(
		Object,
		SeriesSpecificationParameters,
		ParametersOfSeriesIndicationForm,
		StructureOfActions);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(TSName, CurrentID)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(
				Object,
				SeriesSpecificationParameters[TSName],
				CurrentID,
				ThisObject);
	
EndFunction

#EndRegion

&AtServer
Procedure MaterialsAndWorksChangedOnServer(CurrentID)
	
	CurrentData = Object.MaterialsAndWorks.FindByID(CurrentID);
	
	ClearPrimaryByCostGroupFlag(CurrentData.CostGroupNumber);
	
	CurrentData.Main = True;
	
EndProcedure

#EndRegion

#Region ManufacturedProducts

&AtClient
Procedure OpenCostShareEntryForm(CurrentData, StandardProcessing)
	
	If Object.MethodOfAllocatingFinishedProductCosts =
			PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares")
		And Not Object.GroupCosts =
				PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	NoErrors_ =
		ProductionClient.CheckFillingBeforeEnteringCostFraction(
			CurrentData,
			CostAllocationParameters);
	
	If NoErrors_ Then
		
		FormParameters =
			ParametersOfCostShareEntryForm_(
				CurrentData.GetID());
		
		OpenForm(
			"CommonForm.EnterCostShare",
			FormParameters,
			ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingInputOfFractionOfCost(Item, CurrentData, ValueSelected)
	
	If CurrentData.CostShare <> ValueSelected.CostShare Then
		
		ProductionClientServer.FillInCostFractionInLine(CurrentData, ValueSelected);
		
		Groups = New Array;
		Groups.Add(CurrentData.CostGroupNumber);
		CalculatePercentageOfCostAllocationForOutputProducts(Groups);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region More

&AtClient
Procedure IncomingDocumentNumberTextEditEndCompletion(QuestionResult, AdditionalParameters) Export
	
	ListOfReportsByNumber = AdditionalParameters.OrderList;
	
	If QuestionResult = "OpenOrderList" Then
		If ListOfReportsByNumber.Count() > 1 Then
			FormParameters = New Structure;
			FormParameters.Insert("DocumentsList", ListOfReportsByNumber);
			FormParameters.Insert("Title", NStr("vi = 'Báo cáo gia công (%DocumentsCount%)';
												|ru = 'Отчеты переработчиков (%DocumentsCount%)';
												|en = 'Subcontracting services notifications received (%DocumentsCount%)'; fa = 'Subcontracting services notifications received (%DocumentsCount%)';
												|it = 'I report dei trasformatori (%DocumentsCount%)';
												|pl = 'raporty przetwórców (%DocumentsCount%)';
												|tr = 'Alınan fason hizmetleri bildirimi (%DocumentsCount%)'"));
			OpenForm("CommonForm.ViewingListOfDocuments", FormParameters);
		Else
			FormParameters = New Structure("Key", ListOfReportsByNumber.Get(0).Value);
			OpenForm("Document.SubcontractorReport2_5.ObjectForm", FormParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure PriceIncludesVATWhenChangedOnServer(CachedValues)
	
	StructureOfActions = New Structure;
	AddActionsForRecalculatingAmounts(ThisObject, "Services", StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(Object.Services, StructureOfActions, CachedValues);
	
	FillInDependentServiceDetailsOnServer("PriceIncludesVAT");
	
EndProcedure

&AtServer
Procedure TaxationOfVATWhenChangingOnServer()
	
	StructureOfActions = New Structure;
	
	AddActionsFillInVATRate(ThisObject, "Services", StructureOfActions);
	AddActionsForRecalculatingAmounts(ThisObject, "Services", StructureOfActions);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject,
		"Products",
		StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Services, StructureOfActions, Undefined);
	
	CalculateDocumentTotals(ThisObject, "AmountOfServices");
	
	ConfigureDependentFormElements(ThisObject, "VATTaxation");
	
EndProcedure

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		// &PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement(
			"Document.SubcontractorReport2_5.Form.DocumentForm.PriceKindOnChange");
		
		PricesCalculated = FillInPricesByPriceKindServer("SideAndIntermediateRelease");
		PricesCalculated = Min(PricesCalculated, FillInPricesByPriceKindServer("MaterialsAndWorks"));
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer(ChangesTakenIntoAccount = Undefined)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	If ChangesTakenIntoAccount.Property("LineOfBusiness") Then
		Return;
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("PurchaseForActivity") Then
		UpdatePurchaseForActivity(ChangesTakenIntoAccount);
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("VATTaxation") Then
		UpdateVATTaxation_(ChangesTakenIntoAccount);
	EndIf;
	
	ProcessChangeOfDirection(ChangesTakenIntoAccount);
	ChangesTakenIntoAccount.Insert("LineOfBusiness");
	
EndProcedure

#EndRegion

#Region CostGroups

&AtClient
Procedure TableCostGroupStartOfSelectionCompletion(Result, TSName) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	TableCostGroupStartSelectionEndOnServer(Result, TSName, Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure TableCostGroupStartSelectionEndOnServer(Result, TSName, Val SelectedRows)

	Groups = New Array;
	Groups.Add(Result.CostGroupNumber);
	
	For Each RowID In SelectedRows Do
		
		CurrentData = Object[TSName].FindByID(RowID);
		
		Groups.Add(CurrentData.CostGroupNumber);
		
		CurrentData.CostGroupNumber = Result.CostGroupNumber;
		CurrentData.ExpenseGroup      = Result.ExpenseGroup;
		CurrentData.ProductionStage  = Result.ReferenceOrder;
		
		If Object.ByOrders
			And Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
			And TSName = "ManufacturedProducts" Then
			CurrentData.MethodOfAllocatingFinishedProductCosts = Result.MethodOfAllocatingFinishedProductCosts;
		EndIf;
		If Object.ByOrders
			And (Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOM
				Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
				Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments)
			And TSName = "ManufacturedProducts" Then
			CurrentData.BillOfMaterials = Result.BillOfMaterials;
		EndIf;
		
		If TSName = "MaterialsAndWorks"
			And UseImportedGoods Then
			
			CurrentData.ThereIsImportedProduct = Result.ThereIsImportedProduct;
			
			If Not CurrentData.ThereIsImportedProduct Then
				CurrentData.Main = False;
			ElsIf CurrentData.Main Then
				
				FoundRows = BasicMaterialsOfCostGroup(CurrentData.CostGroupNumber);
				If FoundRows.Count() > 1 Then
					CurrentData.Main = False;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Groups = CommonClientServer.CollapseArray(Groups);
	For Each CostGroupNumber In Groups Do
		TableFillInDependentServiceDetailsOfCostGroup(TSName, CostGroupNumber);
	EndDo;
	
	If TSName = "ManufacturedProducts" Then
		CalculatePercentageOfCostAllocationForOutputProducts(Groups);
	EndIf;
	
EndProcedure

#EndRegion

#Region SupportingProcedures

#Region VATAccounting

&AtServer
Procedure UpdatePurchaseForActivity(ChangesTakenIntoAccount = Undefined, Fill = True)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	FillParameters = Documents.SubcontractorReport2_5.ParametersForFillingInVATActivityType(Object);
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
	
	ChangesTakenIntoAccount.Insert("PurchaseForActivity");
	
EndProcedure

&AtServer
Procedure UpdateVATTaxation_(ChangesTakenIntoAccount = Undefined, Fill = True)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	FillParameters = Documents.SubcontractorReport2_5.ParametersForFillingInVATTaxationPurchases(Object);
	
	If Fill Then
		
		VATAccountingERP.FillInVATTaxationPurchases(
			Object.VATTaxation,
			FillParameters,
			VATAccountingCachedParameterValues);
		
		TaxationOfVATWhenChangingOnServer();
		
	EndIf;
	
	VATAccountingERP.FillInListOfVATTaxChoices(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
	ChangesTakenIntoAccount.Insert("VATTaxation");
	
EndProcedure

#EndRegion

#Region ARAPAccounting

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisObject, TagName);
EndProcedure

&AtServer
Procedure ProcessingAndSettlementsOnServer(EventName, Parameter)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisObject, EventName, Parameter);
	
EndProcedure

#EndRegion

&AtServer
Procedure ProcessChangeOfDirection(ChangesTakenIntoAccount)
	
	If Not ChangesTakenIntoAccount.Property("LineOfBusiness") Then
		
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		
		For Each CurrentData In Object.ManufacturedProducts Do
			If Not Object.ByOrders Then
				AddChangeCostGroup(CurrentData, True);
			EndIf;
		EndDo;
		
		For Each CurGroup In CostGroups Do
			TableFillInDependentServiceDetailsOfCostGroup("ManufacturedProducts", CurGroup.CostGroupNumber);
		EndDo;
		
		CalculatePercentageOfCostAllocationForOutputProducts();
		
		ChangesTakenIntoAccount.Insert("LineOfBusiness");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateInvoiceText(ChangesTakenIntoAccount)
	
	If Not ChangesTakenIntoAccount.Property("InvoiceText") Then
		
		InvoiceTextReceived = SubmissionOfInvoicesReceived(Object);
		
		ChangesTakenIntoAccount.Insert("InvoiceText");
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function SubmissionOfInvoicesReceived(Object)
	
	RegistrationParameters = Documents.SubcontractorReport2_5.ParametersForRegisteringInvoicesReceived(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
		
	Return InvoicesReceivedOnBasisOf.Presentation;
	
EndFunction

&AtServerNoContext
Function ReportsOnProcessorData(CurrentOrder, Counterparty, IncomingDocumentNumber)
	
	DocumentAttributes = Common.ObjectAttributesValues(CurrentOrder, "IncomingDocumentDate, Date");
	IncomingDocumentDate =
		?(ValueIsFilled(DocumentAttributes.IncomingDocumentDate),
			DocumentAttributes.IncomingDocumentDate,
			?(ValueIsFilled(DocumentAttributes.Date), DocumentAttributes.Date, CurrentSessionDate()));

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	SubcontractorReport.Ref AS Ref
	|FROM
	|	Document.SubcontractorReport2_5 AS SubcontractorReport
	|WHERE
	|	NOT SubcontractorReport.Ref = &CurrentReport
	|	AND SubcontractorReport.Date BETWEEN
	|		BEGINOFPERIOD(&IncomingDocumentDate, YEAR)
	|		AND ENDOFPERIOD(&IncomingDocumentDate, YEAR)
	|	AND SubcontractorReport.IncomingDocumentNumber = &IncomingDocumentNumber
	|	AND SubcontractorReport.Counterparty = &Counterparty
	|	AND NOT SubcontractorReport.DeletionMark
	|";

	Query.SetParameter("IncomingDocumentDate", IncomingDocumentDate);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("CurrentReport", CurrentOrder);
	Query.SetParameter("IncomingDocumentNumber", IncomingDocumentNumber);
	
	ListOfReportsByNumber = New ValueList;
	ListOfReportsByNumber.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));

	Return ListOfReportsByNumber;

EndFunction

&AtServer
Procedure CalculatePercentageOfCostAllocationForOutputProducts(Groups = Undefined)
	
	ProductionServer.CalculatePercentageOfCostAllocationForOutputProducts(Object, CostAllocationParameters, Groups);
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	RecalculationParameters = PriceManagementSystem.ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(Object.PriceIncludesVAT, DocumentAmount, "Count");
	
	PriceManagementSystem.RecalculateTableAmountsONChangeOfExchangeRate(Object.Services, RecalculationParameters);
	
	CalculateDocumentTotals(ThisObject, "QuantityOverOrder,AmountOfServices");
	
EndProcedure

&AtServer
Procedure ConvertAmountsOfDocumentSProductsIntoCurrency()
	
	OldCurrency                = DocumentCurrency;
	NewCurrency                 = Object.Currency;
	DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date,CurrentSessionDate());
	
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate, BaseCurrency);
	StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate, BaseCurrency);
	
	// Recalculate the prices
	If UseTargetCost Then
		For Each CurRow In Object.ManufacturedProducts Do
			CurRow.Price = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(CurRow.Price,
				StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
		EndDo;
	EndIf;
	
	For Each CurRow In Object.SideAndIntermediateRelease Do
		CurRow.Price = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(CurRow.Price,
			StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
	EndDo;
	
	// Recalculate the amount
	If UseTargetCost Then
		StructureOfActions = New Structure;
		AddActionsForRecalculatingAmounts(ThisObject, "ManufacturedProducts", StructureOfActions, "Sum");
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions, CachedValues);
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsForRecalculatingAmounts(ThisObject, "SideAndIntermediateRelease", StructureOfActions, "Sum");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions, CachedValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateDocumentTotals(Form, AttributesList = "")
	
	Object = Form.Object;
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("AmountOfServices") Then
		Object.DocumentAmount =
			Object.Services.Total("AmountIncludingVAT");
	EndIf;
	
	If Initialize
		Or AttributesList.Property("NumberOfProducts") Then
		Form.QuantityOfFinishedProducts = 
			Object.ManufacturedProducts.Count()
			+ Object.SideAndIntermediateRelease.Count();
	EndIf;
	
	If Initialize
		Or AttributesList.Property("QuantityOverOrder") Then
		Form.QuantityOverOrder = 
			Object.ManufacturedProducts.Total("OrderDiscrepancy_3")
			+ Object.SideAndIntermediateRelease.Total("OrderDiscrepancy_3")
			+ Object.Services.Total("OrderDiscrepancy_3");
		ConfigureDependentFormElementsByOrder(Form);
	EndIf;
	
	If Initialize
		Or AttributesList.Property("TheRecordsAreKeptByCCD") Then
		Form.TheRecordsAreKeptByCCD =
			Not (Object.ManufacturedProducts.Total("TheRecordsAreKeptByCCD")
				+ Object.SideAndIntermediateRelease.Total("TheRecordsAreKeptByCCD")) = 0;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

#Region IsMain
&AtClient
Procedure CloseOrderCompletion(QuestionResult, AdditionalParameters) Export
	
	CallbackDescription = New CallbackDescription("CloseOrderFragment", ThisObject);
	WriteParameters = New Structure;
	WriteParameters.Insert("ActionAfterRecording", CallbackDescription);
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	
	If Not QuestionResult = DialogReturnCode.No Then
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseOrderFragment(Result = Undefined, AdditionalParameters = Undefined) Export
	
	ListOfOrdersToClose = New ValueList;
	ListOfOrdersToClose.Add(Object.SubcontractOrder);
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm(
		"DataProcessor.OrderClosureWizard.Form.ClosureForm",
		ClosureStructure,
		ThisObject,,,,
		Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region ObjectCommands_

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	Close();
EndProcedure

#EndRegion

#Region TableCommandHandlers

&AtServer
Procedure OutputItemsAreMovedToSideItemsOnServer()
	
	Groups = New Array;
	LinesToDelete = New Array;
	
	For Each RowID In Items.ManufacturedProducts.SelectedRows Do
		
		ProductionLine = Object.ManufacturedProducts.FindByID(RowID);
		FillPropertyValues(Object.SideAndIntermediateRelease.Add(), ProductionLine,, "CostGroupNumber, ExpenseGroup");
		
		Groups.Add(ProductionLine.CostGroupNumber);
		LinesToDelete.Add(ProductionLine);
		
	EndDo;
	
	For Each CurRow In LinesToDelete Do
		Object.ManufacturedProducts.Delete(CurRow);
	EndDo;
	
	CalculatePercentageOfCostAllocationForOutputProducts(Groups);
	
EndProcedure

&AtClient
Procedure SelectionOfPlannedCalculationEnds(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInPlanningCalculationsAndPricesOnServer(
		AdditionalParameters.SelectedRows,
		Result);
		
EndProcedure

&AtClient
Procedure TableSplitRowCompletion(Result, AdditionalParameters) Export 
	
	TSName = AdditionalParameters.TSName;
	CurrentRow = Items[TSName].CurrentData;
	
	If Result <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsWhenChangingQuantity(ThisObject, TSName, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(Result, StructureOfActions, CachedValues);
		
		If TSName = "ManufacturedProducts" Then
			
			Result.RowCodeProducts = 0;
			
			ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(
				Result,
				CurrentRow,
				Object.MethodOfAllocatingFinishedProductCosts);
			
			Groups = New Array;
			Groups.Add(CurrentRow.CostGroupNumber);
			CalculatePercentageOfCostAllocationForOutputProducts(Groups);
			
		EndIf;
		
		If TSName = "MaterialsAndWorks" Then
			Result.Main = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadTableFromTSDCompletion(Result, AdditionalParameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods, AdditionalParameters.TSName);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure BarcodeSearchTableCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2, AdditionalParameters.TSName);
	
EndProcedure

&AtClient
Procedure PickUpProduct(TSName)
	
	If Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Tiền tệ""';
				|ru = 'Поле ""Валюта"" не заполнено';
				|en = '""Currency"" is required'; fa = '""Currency"" is required';
				|it = 'Il campo ""Valuta"" non è compilato';
				|pl = 'Pole ""Waluta"" nie jest wypełnione';
				|tr = '""Para Birimi"" alanı doldurulmadı'"),
			Object.Ref,
			"Object.Currency");
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("HideManualDiscounts",    True);
	FormParameters.Insert("PriceIncludesVAT",         Object.PriceIncludesVAT);
	FormParameters.Insert("Currency",                  Object.Currency);
	FormParameters.Insert("Date",                    Object.Date);
	FormParameters.Insert("Document",                Object.Ref);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", False);
		
	If TSName = "Services" Then
		FormParameters.Insert("FilterByProductType", ProductsClientServer.JobSelection(False));
		FormParameters.Insert("Department", Object.Department);
	Else
		FormParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductReusablePackagingWork(False));
		FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	EndIf;
	
	If Not TSName = "Services" Then
		FormParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
	EndIf;
	
	If TSName = "MaterialsAndWorks" Then
		
		FormParameters.Insert("Department",        Object.Department);
		FormParameters.Insert("AllWarehouseBalance", False);
		FormParameters.Insert("UseAdvancedFeaturesOfSalesOrder", True);
		
		ProductSelectionForm = "DataProcessor.SelectGoodsToSalesDocument.Form";
		FormOwner = ThisObject;
		
	Else
		
		FormParameters.Insert("Partner", Object.Partner);
		
		ProductSelectionForm = "DataProcessor.SelectGoodsToPurchaseDocument.Form";
		
		If TSName = "Services" Then
			FormOwner = ThisObject;
		Else
			FormOwner = Items[TSName];
		EndIf;
		
	EndIf;
	
	OpenForm(ProductSelectionForm, FormParameters, FormOwner, UUID);
	
EndProcedure

&AtClient
Procedure AddItemsFromSalesOrderGoodsIssue(TSName)
	
	CallbackDescription = New CallbackDescription("AddItemsFromSalesOrderGoodsIssueCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("OrderDocument",               Object.SubcontractOrder);
	FormParameters.Insert("SubcontractorReport",  Object.Ref);
	FormParameters.Insert("GroupCosts",   Object.GroupCosts);
	FormParameters.Insert("TabularSections",      DataOfWare());
	
	If TSName = "SideAndIntermediateRelease" Then
		FormParameters.Insert("OnlyByProducts", True);
	EndIf;
	
	OpenForm("Document.SubcontractorReport2_5.Form.SelectProductsFromOrder", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure AddItemsFromSalesOrderGoodsIssueCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;

	Modified = True;
	SelectionOfGoodsFromOrderCompletionOnServer(ClosingResult);

	CalculateDocumentTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure SelectionOfGoodsFromOrderCompletionOnServer(FillingData)
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	Groups = New Array;
	TheStructureOfTheSearch = New Structure("RowCode, CostGroupNumber");
	
	ProcessedLinesAreManufacturedProducts = New Array;
	ProcessedRowsAreWaste = New Array;
	For Each ProductionData In FillingData Do
		
		FillPropertyValues(TheStructureOfTheSearch, ProductionData);
		
		If ProductionData.CostType = Enums.CostTypesOfFinishedProducts.Calculating Then
			TSName = "ManufacturedProducts";
			FoundRows = Object.ManufacturedProducts.FindRows(TheStructureOfTheSearch);
		Else
			TSName = "SideAndIntermediateRelease";
			FoundRows = 
				?(TheStructureOfTheSearch.RowCode = 0,
					New Array,
					Object.SideAndIntermediateRelease.FindRows(TheStructureOfTheSearch));
		EndIf;
		
		If FoundRows.Count() = 0 Then
			CurrentData = Object[TSName].Add();
			FillPropertyValues(CurrentData, ProductionData);
		Else
			CurrentData = FoundRows[0];
			CurrentData.Count = CurrentData.Count + ProductionData.Count;
		EndIf;
		
		If TSName = "ManufacturedProducts" Then
			Groups.Add(CurrentData.CostGroupNumber);
			ProcessedLinesAreManufacturedProducts.Add(CurrentData);
		Else
			ProcessedRowsAreWaste.Add(CurrentData);
		EndIf;
		
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	AddActionsFillInServiceDetailsOfProductItem("ManufacturedProducts", StructureOfActions);
	AddActionsCheckSeriesCalculateStatus(ThisObject, "ManufacturedProducts", StructureOfActions);
	AddActionsFillInPriceView(ThisObject, "ManufacturedProducts", StructureOfActions);
	AddActionsFillInPrice(ThisObject, "ManufacturedProducts", StructureOfActions);
	AddActionsCheckFillShareCost(ThisObject, "ManufacturedProducts", StructureOfActions);
	
	GLAccountSettingsClientServer.InsertActionFillInDefaultAccountingAccountsSetting(
		StructureOfActions,
		ThisObject,
		"Object.ManufacturedProducts");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAreManufacturedProducts,
		StructureOfActions,
		Object.ManufacturedProducts,
		CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	AddActionsFillInServiceDetailsOfProductItem("SideAndIntermediateRelease", StructureOfActions);
	AddActionsCheckSeriesCalculateStatus(ThisObject, "SideAndIntermediateRelease", StructureOfActions);
	AddActionsFillInPriceView(ThisObject, "SideAndIntermediateRelease", StructureOfActions);
	AddActionsFillInPrice(ThisObject, "SideAndIntermediateRelease", StructureOfActions);
	AddActionsCheckFillShareCost(ThisObject, "SideAndIntermediateRelease", StructureOfActions);
	
	GLAccountSettingsClientServer.InsertActionFillInDefaultAccountingAccountsSetting(
		StructureOfActions,
		ThisObject,
		"Object.SideAndIntermediateRelease");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsAreWaste,
		StructureOfActions,
		Object.SideAndIntermediateRelease,
		CachedValues);
	
	UpdateCostGroups();
	
	If Not Groups.Count() = 0 Then
		CalculatePercentageOfCostAllocationForOutputProducts(Groups);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionByOrdersToProcessors()
	
	FilterParameters = New Structure;
	
	If ValueIsFilled(Object.Organization) Then
		FilterParameters.Insert("Organization", Object.Organization);
	EndIf;
	If ValueIsFilled(Object.Partner) Then
		FilterParameters.Insert("Partner", Object.Partner);
	EndIf;
	If ValueIsFilled(Object.LineOfBusiness) Then
		FilterParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	EndIf;
	CallbackDescription = New CallbackDescription("SelectionByOrdersToProcessorsCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	FormParameters.Insert("Contract", Object.Contract);
	FormParameters.Insert("Recorder", Object.Ref);
	OpenForm(
		"Document.SubcontractOrder2_5.Form.SelectOrderForSubcontractorReport", 
		FormParameters,,,,, 
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure SelectionByOrdersToProcessorsCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("DocumentRef.SubcontractOrder2_5") Then
		SelectionByOrdersProcessorsCompletionOnServer(Result);
	Else
		Object.ByOrders = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SelectionByOrdersProcessorsCompletionOnServer(SubcontractOrder)
	
	Object.ManufacturedProducts.Clear();
	Object.SideAndIntermediateRelease.Clear();
	Object.MaterialsAndWorks.Clear();
	Object.Services.Clear();
	
	Documents.SubcontractorReport2_5.FillInBasedOnOrder(Object, SubcontractOrder);
	
	FillInServiceDetails();
	FillInDependentServiceDetailsOnServer();
	FillInServiceDetailsOfTableParts();
	
	UpdateCostGroups();
	
	UpdatePurchaseForActivity(, False);
	UpdateVATTaxation_(, False);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "OrderInvoice_3");
	
	CalculateDocumentTotals(ThisObject);
	CustomizeFormElements();
	SetSubscriptionForFormElementChangeEvents();
	
EndProcedure

&AtClient
Procedure FillInRecipientCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	TSParameters      = AdditionalParameters.TSParameters;
	
	FillInRecipientOnServer(TSParameters, Items[TSParameters.NameTSForm].SelectedRows, Result);
	
	ShowUserNotification(
		NStr("vi = 'Đã điền người nhận';
			|ru = 'Получатель заполнен';
			|en = 'Recipient is filled in'; fa = 'Recipient is filled in';
			|it = 'Il destinatario è compilato';
			|pl = 'Odbiorca wypełniony';
			|tr = 'Alıcı dolduruldu'"),,
		NStr("vi = 'Đối với các dòng được chọn đã điền người nhận';
			|ru = 'Для выделенных строк выполнено заполнение получателя';
			|en = 'Recipients are filled in for the selected lines'; fa = 'Recipients are filled in for the selected lines';
			|it = 'Per le righe selezionata è stata eseguita la compilazione del destinatario';
			|pl = 'Dla wybranych wierszy wykonano wypełnienie odbiorcy';
			|tr = 'Belirtilen satırlar için alıcı dolduruldu'"),
		PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure FillInRecipientOnServer(TSParameters, Val SelectedRows, Result)
	
	TSName = TSParameters.NameTsObject;
	
	For Each RowID In SelectedRows Do
		
		RowData = Object[TSName].FindByID(RowID);
		
		If Not RowData.ItemsType = Enums.ItemsTypes.Work_5 Then
			Continue;
		EndIf;
		
		RowData.Recipient = Result;
		
	EndDo;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, SelectedRows);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItemCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	TSName = AdditionalParameters.TSName;
	
	For Each RowID In Items[TSName].SelectedRows Do
		RowData = Object[TSName].FindByID(RowID);
		RowData.ProductCostElement = Result;
	EndDo;
	
EndProcedure

&AtClient
Procedure ServicesFillInPricesBySupplierPriceTypeCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		PricesCalculated = FillInPricesBySupplierPriceTypeOnServer(Result, Items.Services.SelectedRows);
		PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesSelectAndCompleteServiceCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	ServicesSelectAndCompleteEndServiceOnServer(ClosingResult, CachedValues);
	
EndProcedure

&AtServer
Procedure ServicesSelectAndCompleteEndServiceOnServer(ClosingResult, CachedValues)
	
	StructureOfActions = New Structure;
	AddActionsFillInPrice(ThisObject, "Services", StructureOfActions);
	AddActionsWhenChangingProducts(ThisObject, "Services", StructureOfActions);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ByOrders);
	
	RowsToProcess = New Array;
	For Each RowID In Items.Services.SelectedRows Do
		
		CurrentData = Object.Services.FindByID(RowID);
		CurrentData.Products = ClosingResult;
		
		RowsToProcess.Add(CurrentData);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Services,
		CachedValues);
	
	CalculateDocumentTotals(ThisObject, "QuantityOverOrder");
	
EndProcedure

#Region StandardCommands

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard(TSName) 
	
	FilterParameters = New Map;
	If TSName = "Services" Then
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.JobSelection(False));
	Else
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductReusablePackagingWork(False));
	EndIf;
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Count,
		|VendorPriceKind,Price,VATRate,BillOfMaterials,ProductCostElement,Recipient";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	TabularSection = Object[TSName]; // FormDataCollection
	SelectedRows = New Array;
	
	StructureOfActions = New Structure;
	AddActionsFillInPriceView(ThisObject, TSName, StructureOfActions);
	AddActionsFillInPrice(ThisObject, TSName, StructureOfActions);
	AddActionsInitializeArticleAndAnalytics(ThisObject, TSName, StructureOfActions);
	AddActionsWhenChangingProducts(ThisObject, TSName, StructureOfActions);
	AddActionsWhenChangingCharacteristic(ThisObject, TSName, StructureOfActions);
	
	If Not TSName = "MaterialsAndWorks" Then
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ByOrders);
	EndIf;
	
	DimensionsToFillIn = New Array;
	RowsToProcess = New Array();
	ProductData_2 = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
	
		CurrentData = TabularSection.Add();
		FillPropertyValues(CurrentData, RowOfProduct);
		
		If Object.ByOrders
			And Not TSName = "MaterialsAndWorks" Then
			CurrentData.SubcontractOrder = Object.SubcontractOrder;
		EndIf;
		
		If TSName = "ManufacturedProducts"
			And Not Object.ByOrders Then
			
			ProductData_2.Add(
				ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
					Object, CurrentData, BOMSelectionParameters, ThisObject));
			
		EndIf;
		
		RowsToProcess.Add(CurrentData);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TabularSection,
		CachedValues);
	
	If TSName = "ManufacturedProducts"
			And Not Object.ByOrders Then
		
		ProductDataManagement.FillInSpecificationInLines(
			RowsToProcess, ProductData_2, BOMSelectionParameters);
		
	EndIf;
	
	For Each CurrentData In RowsToProcess Do
	
		If TSName = "ManufacturedProducts" Then
			
			If Not Object.ByOrders Then
				AddChangeCostGroup(CurrentData, True);
			Else
				SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
			EndIf;
			
			SelectedRows.Add(CurrentData.GetID());
			
		Else
			SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
		EndIf;
		
		DimensionsToFillIn.Add(CurrentData.CostGroupNumber);
		
	EndDo;
	
	DimensionsToFillIn = CommonClientServer.CollapseArray(DimensionsToFillIn);
	For Each CurGroup In DimensionsToFillIn Do
		TableFillInDependentServiceDetailsOfCostGroup(TSName, CurGroup);
	EndDo;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, SelectedRows);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndRegion

#Region FillType

#Region ServiceDetails_

&AtServer
Procedure FillInServiceDetails()
	
	GroupCostsBeforeChange = Object.GroupCosts;
	DocumentCurrency = Object.Currency;
	HaveRightToAddAdjustments = AccessRight("Insert", Metadata.Documents.PurchaseAdjustment);
	
	UseImportedGoods = GetFunctionalOption("UseImportedGoods");
	
	UseLinesOfBusiness =
		GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	UseDebitNotes =
		GetFunctionalOption("UseDebitNotes");
	
	UseProduction = GetFunctionalOption("UseProduction");
	
	UpdateFlagThereAreAdjustments();
	
	CostAllocationParameters =
		New FixedStructure(Documents.SubcontractorReport2_5.CostAllocationParameters(Object));
	
	SeriesSpecificationParameters =
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.SubcontractorReport2_5));
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, Documents.SubcontractorReport2_5);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ManufacturedProducts);
	ProcessingOfTabularForms.InitializeRowCache(Items.SideAndIntermediateRelease);
	ProcessingOfTabularForms.InitializeRowCache(Items.MaterialsAndWorks);
	ProcessingOfTabularForms.InitializeRowCache(Items.Services);
	
EndProcedure

&AtServer
Procedure FillInDependentServiceDetailsOnServer(AttributesList = "")
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("Partner")
		Or AttributesList.Property("PriceIncludesVAT") Then
		FillInDefaultVendorPriceView();
	EndIf;
	
	If Initialize
		Or AttributesList.Property("Date")
		Or AttributesList.Property("Organization") Then
		FillOutUseOfPlannedCost();
	EndIf;
	
	If Initialize
		Or AttributesList.Property("ByOrders") Then
		UpdateDiscrepancyOrder();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTableParts(ListOfTS = "")
	
	StructureOfTS = New Structure(ListOfTS);
	Initialize = Not ValueIsFilled(StructureOfTS);
	
	If Initialize
		Or StructureOfTS.Property("ManufacturedProducts") Then
		
		StructureOfActions = New Structure;
		AddActionsFillInServiceDetailsOfProductItem("ManufacturedProducts", StructureOfActions);
		
		BatchProcessingOfTablePartServer.TreatTS(
			Object.ManufacturedProducts,
			StructureOfActions,
			Undefined);
		
		If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			CalculatePercentageOfCostAllocationForOutputProducts();
		EndIf;
		
	EndIf;
	
	If Initialize
		Or StructureOfTS.Property("SideAndIntermediateRelease") Then
		
		StructureOfActions = New Structure;
		AddActionsFillInServiceDetailsOfProductItem("SideAndIntermediateRelease", StructureOfActions);
		
		BatchProcessingOfTablePartServer.TreatTS(
			Object.SideAndIntermediateRelease,
			StructureOfActions,
			Undefined);
		
	EndIf;
			
	If Initialize
		Or StructureOfTS.Property("MaterialsAndWorks") Then
		
		StructureOfActions = New Structure;
		AddActionsFillInServiceDetailsOfProductItem("MaterialsAndWorks", StructureOfActions);
		
		BatchProcessingOfTablePartServer.TreatTS(
			Object.MaterialsAndWorks,
			StructureOfActions,
			Undefined);
		
	EndIf;
	
	If Initialize
		Or StructureOfTS.Property("Services") Then
		
		StructureOfActions = New Structure;
		AddActionsFillInServiceDetailsOfProductItem("Services", StructureOfActions);
		
		BatchProcessingOfTablePartServer.TreatTS(
			Object.Services,
			StructureOfActions,
			Undefined);
		
	EndIf;
	FillInServiceDetailsOfTabularPartsByOrder(ListOfTS);
EndProcedure	

&AtServer
Procedure FillInServiceDetailsOfTabularPartsByOrder(ListOfTS = "")
	
	If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		Return;
	EndIf;
	
	StructureOfTS = New Structure(ListOfTS);
	ProcessedTS = New Structure;
	
	Initialize = Not ValueIsFilled(StructureOfTS);
	
	Query = New Query;
	QueryTexts = New Array;
	CurTableNumber = -1;
	
	#Region ManufacturedProducts
	
	If Initialize
		Or StructureOfTS.Property("ManufacturedProducts") Then
		
		Query.SetParameter("ManufacturedProducts", Object.ManufacturedProducts.Unload(, "LineNumber, ProductionStage"));
		QueryTexts.Add(
		"SELECT
		|	Table.LineNumber,
		|	Table.ProductionStage
		|INTO TTOutputProducts
		|FROM
		|	&ManufacturedProducts AS Table
		|
		|INDEX BY
		|	ProductionStage
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.LineNumber,
		|	DetailsOfOrder.MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
		|	DetailsOfOrder.NextStageNo AS NextStageNo
		|FROM
		|	TTOutputProducts AS Table
		|	
		|	LEFT JOIN Document.ProductionStage2_2 AS DetailsOfOrder
		|	ON DetailsOfOrder.Ref = Table.ProductionStage
		|");
		
		CurTableNumber = CurTableNumber + 2;
		ProcessedTS.Insert("ManufacturedProducts", CurTableNumber);
		
	EndIf;
	
	#EndRegion
	
	If QueryTexts.Count() = 0 Then
		Return;
	EndIf;
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	ThereIsReleaseStage = False;
	For Each CurTS In ProcessedTS Do
		
		Table = Result[CurTS.Value].Unload(); // ValueTable
		For Each CurRow In Table Do
			
			FillPropertyValues(Object[CurTS.Key][CurRow.LineNumber - 1], CurRow);
			
			If CurTS.Key = "ManufacturedProducts" Then
				ThereIsReleaseStage =
					ThereIsReleaseStage
					Or ProductionManagementClientServer.ThisIsAProductionIssueStage(CurRow);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If Initialize
		Or StructureOfTS.Property("ManufacturedProducts") Then
		CalculatePercentageOfCostAllocationForOutputProducts();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultVendorPriceView()
	
	DefaultVendorPriceView = Catalogs.VendorPriceTypes.EmptyRef();
	
	SelectingTypeOfPrices = New Structure("Owner, PriceIncludesVAT", Object.Partner, Object.PriceIncludesVAT);
	DefaultVendorPriceView = Catalogs.VendorPriceTypes.DefaultPriceType(DefaultVendorPriceView, SelectingTypeOfPrices);
	
EndProcedure

&AtServer
Procedure FillOutUseOfPlannedCost()
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy",
		Object.Organization,
		Object.Date);
	
	If Not AccountingPolicyParameters = Undefined Then
		UseTargetCost = AccountingPolicyParameters.ProductCostingByPlannedCost;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDiscrepancyOrder(Val NamesOfTS = Undefined)
	
	If NamesOfTS = Undefined Then
		NamesOfTS = New Array;
		NamesOfTS.Add("ManufacturedProducts");
		NamesOfTS.Add("SideAndIntermediateRelease");
		NamesOfTS.Add("Services");
	ElsIf TypeOf(NamesOfTS) = Type("String") Then
		NamesOfTS = StrSplit(NamesOfTS, ",", False);
	EndIf;
	
	StructureOfActions = New Structure;
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.ByOrders);
	
	For Each TSName In NamesOfTS Do
		
		If TSName = "MaterialsAndWorks" Then
			Continue;
		EndIf;
		
		BatchProcessingOfTablePartServer.TreatTS(Object[TSName], StructureOfActions, Undefined);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region StructureOfActions

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingProducts(Form, TSName, StructureOfActions)
	
	AddActionsFillInServiceDetailsOfProductItem(TSName, StructureOfActions);
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	
	If Not TSName = "Services" Then
		StructureOfActions.Insert("CheckFillPackageByOwner");
	EndIf;
	
	ActionParameters = New Structure;
	ActionParameters.Insert("FormName", Form.FormName);
	ActionParameters.Insert("TabularSectionName", TSName);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ActionParameters);
	
	If Not TSName = "Services" Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(Form, StructureOfActions);
	EndIf;
	
	AddActionsFillInVATRate(Form, TSName, StructureOfActions);
	AddActionsCheckSeriesCalculateStatus(Form, TSName, StructureOfActions);
	AddActionsWhenChangingQuantity(Form, TSName, StructureOfActions);
	AddActionsClearFillArticleAnalytics(Form, TSName, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsFillInVATRate(Form, TSName, StructureOfActions)
	
	If TSName = "Services" Then
		StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Form.Object));
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsFillInServiceDetailsOfProductItem(TSName, StructureOfActions)
	
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease"
		Or TSName = "MaterialsAndWorks" Then
		StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingCharacteristic(Form, TSName, StructureOfActions)
	
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable",
		New Structure("FormName, TabularSectionName", Form.FormName, TSName));
	
	If Not TSName = "Services" Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(Form, StructureOfActions);
	EndIf;
	
	AddActionsClearFillArticleAnalytics(Form, TSName, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingPackaging(Form, TSName, StructureOfActions, CurrentData)
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentData.Count);
	EndIf;
	
	AddActionsWhenChangingQuantity(Form, TSName, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsCheckSeriesCalculateStatus(Form, TSName, StructureOfActions)
	
	If TSName = "Services" Then
		Return;
	EndIf;
	
	ActionParameters = New Structure;
	ActionParameters.Insert("Warehouse", Form.Object.Contract);
	ActionParameters.Insert("SeriesSpecificationParameters", Form.SeriesSpecificationParameters[TSName]);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", ActionParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingQuantity(Form, TSName, StructureOfActions)
	
	If Not TSName = "Services" Then
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	EndIf;
	
	AddActionsCheckFillShareCost(Form, TSName, StructureOfActions);
	AddActionsForRecalculatingAmounts(Form, TSName, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsCheckFillSpecification(Form, TSName, StructureOfActions, CurrentData)
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If TSName = "ManufacturedProducts"
		And Not Form.Object.ByOrders Then
		
		FillParameters =
			ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
				Form.Object,
				CurrentData,
				Form.BOMSelectionParameters);
		
		StructureOfActions.Insert("CheckFillSpecification", FillParameters);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsClearFillArticleAnalytics(Form, TSName, StructureOfActions)
	
	If Not TSName = "ManufacturedProducts"
		And Not TSName = "SideAndIntermediateRelease" Then
		Return;
	EndIf;
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
		StructureOfActions,
		Form,
		"Object." + TSName);
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		Form,
		PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"),
		Form.Object.Organization,
		Form.Object.Department,
		"Object." + TSName);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsInitializeArticleAndAnalytics(Form, TSName, StructureOfActions)
	
	If Not TSName = "ManufacturedProducts"
		And Not TSName = "SideAndIntermediateRelease" Then
		Return;
	EndIf;
	
	IncomeAndExpensesClientServer.InsertActionInitializeArticleAndAnalyticsAfterAddingLine(
		StructureOfActions,
		Form,
		"Object." + TSName);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsCheckFillShareCost(Form, TSName, StructureOfActions)
	
	If Not TSName = "ManufacturedProducts" Then
		Return;
	EndIf;
	
	StructureOfActions.Insert("CheckFillInCostShare", Form.CostAllocationParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsFillInPriceView(Form, TSName, StructureOfActions)
	
	If TSName = "Services" Then
		ActionParameters = New Structure;
		ActionParameters.Insert("NameOfPriceTypeField", "VendorPriceKind");
		ActionParameters.Insert("PriceKind", Form.DefaultVendorPriceView);
		StructureOfActions.Insert("FillInPriceView", ActionParameters);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsFillInPrice(Form, TSName, StructureOfActions)
	
	If Not TSName = "ManufacturedProducts"
		And Not TSName = "SideAndIntermediateRelease"
		And Not TSName = "Services"
		Or TSName = "ManufacturedProducts"
			And Not Form.UseTargetCost Then
		Return;
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		ActionName = "FillInSalePrice";
	ElsIf TSName = "Services" Then
		ActionName = "FillInPurchasePrice";
	EndIf;
	
	StructureOfActions.Insert(ActionName, ParametersForFillingInPriceInTSLine(TSName, Form.Object));
	AddActionsForRecalculatingAmounts(Form, TSName, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsForRecalculatingAmounts(Form, TSName, StructureOfActions, AttributesList = "")
	
	If Not TSName = "ManufacturedProducts"
		And Not TSName = "SideAndIntermediateRelease"
		And Not TSName = "Services"
		Or TSName = "ManufacturedProducts"
			And Not Form.UseTargetCost Then
		Return;
	EndIf;
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	FieldNameQuantity = "NumberOfPackages";
	If TSName = "Services" Then
		FieldNameQuantity = "Count";
	EndIf;
	
	If TSName = "Services"
		And (Initialize
			Or AttributesList.Property("VATAmount")
			Or AttributesList.Property("AmountIncludingVAT")) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Form.Object);
	EndIf;
	
	// The price is recalculated only when the amount changes, so its recalculation is not added by default
	If AttributesList.Property("Price") Then
		StructureOfActions.Insert("RecalculatePriceByAmount", FieldNameQuantity);
	EndIf;
	
	If Initialize
		Or AttributesList.Property("Sum") Then
		StructureOfActions.Insert("RecalculateAmount", FieldNameQuantity);
	EndIf;
	
	If TSName = "Services"
		And (Initialize
			Or AttributesList.Property("VATAmount")) Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	EndIf;
	
	If TSName = "Services"
		And (Initialize
			Or AttributesList.Property("AmountIncludingVAT")) Then
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	If TSName = "Services" Then
		StructureOfActions.Insert("ClearAmountOfSettlements");
	EndIf;
	
EndProcedure

#EndRegion

#Region ObjectAttributes

&AtServer
Procedure FillInDefaultContract(ChangesTakenIntoAccount)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	ObjectParameters = New Structure("Partner, Contract, Counterparty, Organization");
	FillPropertyValues(ObjectParameters, Object);
	ObjectParameters.Insert("Terms", Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Object.Currency;
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
			And UseLinesOfBusiness Then
		AddlParameters.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	Contract =
		PurchasesServer.GetDefaultContract(
			ObjectParameters,
			Object.BusinessOperation, 
			AddlParameters);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		AgreementWhenModifiedOnServer(ChangesTakenIntoAccount);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
EndProcedure

&AtServer
Function FillInPricesByPriceKindServer(TSName, Val SelectedRows = Undefined)
	
	Cancel = False;
	LinesToBeRefilled = Undefined;
	
	If Not SelectedRows = Undefined Then
		
		If SelectedRows.Count() = 0 Then
			
			If TSName = "SideAndIntermediateRelease" Then
				MessageText = NStr("vi = 'Trong bảng ""Sản phẩm phụ"" chưa chọn dòng nào. 
										|Không thể điền đơn giá.';
										|ru = 'В таблице ""Побочные изделия"" не выбрано ни одной строки. 
										|Цены не могут быть заполнены.';
										|en = 'No rows were selected in the By-products table. 
										|Prices cannot be filled in.'; fa = 'No rows were selected in the By-products table. 
										|Prices cannot be filled in.';
										|it = 'Nella tabella ""Sottoprodotti"" non è stata selezionata alcuna riga.
										|I prezzi non possono essere compilati.';
										|pl = 'W tabeli ""Produkty uboczne"" nie wybrano ani jednego wiersza.
										|Nie można wypełnić cen.';
										|tr = '""Yan Nihai Ürünler"" tablosunda herhangi bir satır seçilmedi.
										|Fiyatlar doldurulamaz.'");
			ElsIf TSName = "ManufacturedProducts" Then
				MessageText = NStr("vi = 'Trong bảng ""Sản phẩm đầu ra"" chưa chọn dòng nào. 
										|Không thể điền đơn giá.';
										|ru = 'В таблице ""Выходные изделия"" не выбрано ни одной строки. 
										|Цены не могут быть заполнены.';
										|en = 'No rows were selected in the ""Finished products"" table.
										|Prices cannot be filled in.'; fa = 'No rows were selected in the ""Finished products"" table.
										|Prices cannot be filled in.';
										|it = 'Nella tabella ""Prodotti finiti"" non è stata selezionata nessuna riga. 
										| I prezzi non possono essere compilati.';
										|pl = 'W tabeli ""Produkty wyjściowe"" nie wybrano ani jednego wiersza.
										|Nie można wypełnić cen.';
										|tr = '""Üretilen Nihai Ürünler"" tablosunda herhangi bir satır seçilmedi.
										|Fiyatlar doldurulamaz.'");
			Else
				MessageText = NStr("vi = 'Trong bảng ""Nguyên vật liệu và công việc"" chưa chọn một dòng nào. 
										|Không thể điền đơn giá.';
										|ru = 'В таблице ""Материалы и работы"" не выбрано ни одной строки. 
										|Цены не могут быть заполнены.';
										|en = 'No rows were selected in the ""Materials and works"" table. 
										|Prices cannot be filled in.'; fa = 'No rows were selected in the ""Materials and works"" table. 
										|Prices cannot be filled in.';
										|it = 'Nella tabella ""Materiali e lavori"" non è stata selezionata alcuna riga. 
										|I prezzi non possono essere compilati.';
										|pl = 'W tabeli ""Materiały i prace"" nie wybrano ani jednego wiersza. 
										|Ceny nie mogą być wypełnione.';
										|tr = '""Malzemeler ve İşler"" tablosunda herhangi bir satır seçilmedi.
										|Fiyatlar doldurulamaz.'");
			EndIf;
			
			Common.MessageToUser(MessageText,, TSName, "Object", Cancel);
			
			If Not ValueIsFilled(Object.PriceKind) Then
				MessageText = NStr("vi = 'Chưa điền trường ""Dạng giá"".';
									|ru = 'Не заполнено поле ""Вид цены"".';
									|en = '""Price type"" is required.'; fa = '""Price type"" is required.';
									|it = 'Il campo ""Tipo di prezzo"" non è compilato.';
									|pl = 'Nie wypełniono pole ""Rodzaj ceny""';
									|tr = '""Fiyat Türü"" alanı doldurulmadı.'");
				Common.MessageToUser(MessageText,, "PriceKind", "Object", Cancel);
			EndIf;
			
		EndIf;
		
		If Cancel Then
			Return False;
		EndIf;
		
		LinesToBeRefilled = New Array;
		For Each RowID In SelectedRows Do
			LinesToBeRefilled.Add(Object[TSName].FindByID(RowID));
		EndDo;
		
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("Date",			Object.Date);
	FillParameters.Insert("Organization",		Object.Organization);
	FillParameters.Insert("Currency",			Object.Currency);
	FillParameters.Insert("PriceKind",			Object.PriceKind);
	FillParameters.Insert("PopulationFields",	"Price");
	
	StructureOfActions = New Structure;
	
	AddActionsForRecalculatingAmounts(ThisObject, TSName, StructureOfActions, "Sum");
	
	PricesCalculated =
		EnterprisePricesFillingServer.FillInPrices(
			Object[TSName],
			LinesToBeRefilled,
			FillParameters,
			StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure FillInPlanningCalculationsAndPricesOnServer(Val SelectedRows = Undefined, StandardCostEstimate = Undefined)
	
	If SelectedRows = Undefined Then
		Return;
	EndIf;
		
	CostGroupNumbers = New Array();
	For Each Id In SelectedRows Do
		RowOfProduct = Object.ManufacturedProducts.FindByID(Id);
		CostGroupNumbers.Add(RowOfProduct.CostGroupNumber);
	EndDo;
	
	CostGroupNumbers = CommonClientServer.CollapseArray(CostGroupNumbers);
	RowsArray = New Array;
	For Each IconNumberOfExpenseGroup In CostGroupNumbers Do
		ProductLines_2 = Object.ManufacturedProducts.FindRows(New Structure("CostGroupNumber", IconNumberOfExpenseGroup));
		CommonClientServer.SupplementArray(RowsArray, ProductLines_2);
	EndDo;
	
	FillParameters = Documents.StandardCosting2_2.DescriptionOfPriceFillingParameterInCollection();
	FillParameters.DocumentDate = Object.Date;
	FillParameters.DocumentCurrency = Object.Currency;
	FillParameters.StandardCostEstimate = StandardCostEstimate;
	
	Documents.StandardCosting2_2.FillInPricesByCalculationInCollection(
		Object.ManufacturedProducts,
		RowsArray,
		FillParameters);
	
EndProcedure

&AtServer
Function FillInPricesBySupplierPriceTypeOnServer(VendorPriceKind, Val SelectedRows = Undefined)
	
	LinesToBeRefilled = Undefined;
	
	If Not SelectedRows = Undefined Then
		
		If SelectedRows.Count() = 0 Then
			
			MessageText = NStr("vi = 'Chưa chọn dòng nào trong bảng ""Dịch vụ"". 
									|Không thể điền đơn giá.';
									|ru = 'В таблице ""Услуги"" не выбрано ни одной строки. 
									|Цены не могут быть заполнены.';
									|en = 'No rows were selected in the ""Services"" table. 
									|Prices cannot be filled in.'; fa = 'No rows were selected in the ""Services"" table. 
									|Prices cannot be filled in.';
									|it = 'Nella tabella ""Servizi"" non è stata selezionata alcuna riga. 
									|I prezzi non possono essere compilati.';
									|pl = 'W tabeli ""Usługi"" nie wybrano ani jednego wiersza. 
									|Ceny nie mogą być wypełnione.';
									|tr = '""Hizmetler"" tablosunda herhangi bir satır seçilmedi.
									|Fiyatlar doldurulamaz.'");
			Common.MessageToUser(MessageText,, "Services", "Object");
			
			Return False;
			
		EndIf;
		
		LinesToBeRefilled = New Array;
		For Each CurRow In SelectedRows Do
			LinesToBeRefilled.Add(Object.Services.FindByID(CurRow));
		EndDo;
		
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsForRecalculatingAmounts(ThisObject, "Services", StructureOfActions);
	
	FillParameters = New Structure();
	FillParameters.Insert("PopulationFields", "Price, VendorPriceKind");
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("VendorPriceKind", VendorPriceKind);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		Object.Services,
		LinesToBeRefilled,
		FillParameters,
		StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure TableFillTsByOrderSpecificationCompletion(Result, TSName) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.SubcontractorReport2_5.Form.DocumentForm.Command." + TSName + "FillInTSAccordingToOrderSpecification");
	
	If Result = DialogReturnCode.Yes Then
		TableFillInTsByOrderSpecificationOnServer(TSName);
	EndIf;
	
EndProcedure

&AtServer
Procedure TableFillInTsByOrderSpecificationOnServer(TSName)
	
	ListOfGroups = CostGroups.Unload(, "CostGroupNumber").UnloadColumn("CostGroupNumber");
	ResubmitByOrderSpecificationOnServer(ListOfGroups, TSName);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsToRefillCostlyTSCompletion(Result, AdditionalParameters = Undefined) Export
	
	If Result = DialogReturnCode.Yes Then
		
		ListOfGroups = New Array;
		For Each RowID In Items.ManufacturedProducts.SelectedRows Do
			ListOfGroups.Add(Object.ManufacturedProducts.FindByID(RowID).CostGroupNumber);
		EndDo;
		ListOfGroups = CommonClientServer.CollapseArray(ListOfGroups);
		
		ResubmitByOrderSpecificationOnServer(ListOfGroups, "SideAndIntermediateRelease, MaterialsAndWorks, Services");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ResubmitByOrderSpecificationOnServer(ListOfGroups, ListOfTS = "")
	
	// &PerformanceMeasurement
	Measurement =
		PerformanceMonitor.StartTimeConsumingOperationMeasurement(
			"Document.SubcontractorReport2_5.Form.DocumentForm.Command.ManufacturedProductsToRefillCostlyTS");
	
	NamesOfTS         = New Structure(ListOfTS);
	FillInAll_    = NamesOfTS.Count() = 0;
	ProductList_ = New Array;
	
	Filter = New Structure("CostGroupNumber");
	
	For Each CurGroup In ListOfGroups Do
		
		Filter.CostGroupNumber = CurGroup;
		
		If Object.ByOrders
			And (FillInAll_
				Or NamesOfTS.Property("ManufacturedProducts")) Then
			ClearTSByCostGroup("ManufacturedProducts", CurGroup);
		ElsIf Not Object.ByOrders Then
			FoundRows = Object.ManufacturedProducts.FindRows(Filter);
			For Each CurRow In FoundRows Do
				ProductList_.Add(CurRow);
			EndDo;
		EndIf;
		
		If FillInAll_
			Or NamesOfTS.Property("SideAndIntermediateRelease") Then
			ClearTSByCostGroup("SideAndIntermediateRelease", CurGroup);
		EndIf;
		
		If FillInAll_
			Or NamesOfTS.Property("MaterialsAndWorks") Then
			ClearTSByCostGroup("MaterialsAndWorks", CurGroup);
		EndIf;
		
		If FillInAll_
			Or NamesOfTS.Property("Services") Then
			ClearTSByCostGroup("Services", CurGroup);
		EndIf;
		
	EndDo;
	
	If Object.ByOrders Then
		Documents.SubcontractorReport2_5.FillInProductsMaterialsServicesOnRequest(Object, ListOfGroups, ListOfTS);
	Else
		Documents.SubcontractorReport2_5.FillInByProductsMaterialsServicesAccordingToSpecification(Object, ProductList_, ListOfTS);
	EndIf;
	
	FillInDependentServiceDetailsOnServer("ByOrders");
	
	If FillInAll_
		And Not Object.ByOrders Then
		ListOfTS = "SideAndIntermediateRelease, MaterialsAndWorks, Services";
	EndIf;
	
	FillInServiceDetailsOfTableParts(ListOfTS);
	
	If FillInAll_
		Or NamesOfTS.Property("ManufacturedProducts")
		Or NamesOfTS.Property("SideAndIntermediateRelease") Then
		
		For Each CurGroup In ListOfGroups Do
			
			CostGroupDescription = CostGroupDataByCostGroupNumber(CurGroup);
			FillInDependentServiceDetailsOfCostGroup(CostGroupDescription);
			
			If Not CostGroupDescription.ThereIsImportedProduct Then
				ClearPrimaryByCostGroupFlag(CurGroup);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	UpdateServiceDetailsOfCostGroupsInLinkedTS();
	
	CalculateDocumentTotals(ThisObject);
	
	// &PerformanceMeasurement
	If Object.ByOrders Then
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ListOfGroups.Count());
	Else
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ProductList_.Count());
	EndIf;
	
EndProcedure

#EndRegion

#Region Barcodes

&AtClient
Procedure ProcessBarcodes(BarcodeData_5, TSName)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	TheseAreServices = TSName = "Services";
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsWhenChangingQuantity(ThisObject, TSName, StructureOfActionsWithModifiedStrings);
	
	StructureOfActionsWithAddedStrings = New Structure;
	AddActionsWhenChangingProducts(ThisObject, TSName, StructureOfActionsWithAddedStrings);
	AddActionsWhenChangingCharacteristic(ThisObject, TSName, StructureOfActionsWithAddedStrings);
	AddActionsFillInPriceView(ThisObject, TSName, StructureOfActionsWithAddedStrings);
	AddActionsFillInPrice(ThisObject, TSName, StructureOfActionsWithAddedStrings);
	AddActionsInitializeArticleAndAnalytics(ThisObject, TSName, StructureOfActionsWithAddedStrings);
	
	If Not TheseAreServices Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	EndIf;
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.TSName                                  = TSName;
	StructureOfActions.NotUsePackages                 = TheseAreServices;
	StructureOfActions.OnlyWorks                           = TheseAreServices;
	StructureOfActions.OnlyGoodsAndWork                    = Not TheseAreServices;
	
	If TheseAreServices Then
		StructureOfActions.ColumnNameQuantity = "Count";
	Else
		StructureOfActions.SeriesSpecificationParameters = SeriesSpecificationParameters[TSName];
	EndIf;
	
	ProcessBarcodesOnServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If Not TheseAreServices Then
		If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
			CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
			
			If TSName = "ManufacturedProducts" Then
				AttachIdleHandler("Attachable_OpenSeriesSelectionWhenScanningProductBarCode_ManufacturedProducts", 0.1, True);
			ElsIf TSName = "SideAndIntermediateRelease" Then
				AttachIdleHandler("Attachable_OpenSeriesSelectionWhenScanningProductBarCode_SideAndIntermediateRelease", 0.1, True);
			Else
				AttachIdleHandler("Attachable_OpenSeriesSelectionWhenScanningProductBarCode_MaterialsAndWorks", 0.1, True);
			EndIf;
		EndIf;
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		FormTable = Items[TSName]; // FormTable
		FormTable.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	CalculateDocumentTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessBarcodesOnServer(StructureOfActionParameters, CachedValues)
	
	TSName = StructureOfActionParameters.TSName;
	NumberOfRowsBeforeChange = Object[TSName].Count();
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	RowsCount = Object[TSName].Count();
	
	If Not RowsCount = NumberOfRowsBeforeChange Then
		
		DimensionsToFillIn = New Array;
		ProductData_2 = New Array;
		RowsToProcess = New Array;
		For IndexOf = NumberOfRowsBeforeChange + 1 To RowsCount Do
			
			CurrentData = Object[TSName][IndexOf - 1];
			
			If TSName = "ManufacturedProducts"
				And Not Object.ByOrders Then
				
				ProductData_2.Add(
					ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
						Object, CurrentData, BOMSelectionParameters, ThisObject));
					RowsToProcess.Add(CurrentData);
				
			EndIf;
			
			If TSName = "ManufacturedProducts" Then
				If Not Object.ByOrders Then
					AddChangeCostGroup(CurrentData, True);
				Else
					SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
				EndIf;
			Else
				SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
			EndIf;
			
			DimensionsToFillIn.Add(CurrentData.CostGroupNumber);
			
		EndDo;
		
		If TSName = "ManufacturedProducts"
			And Not Object.ByOrders Then
			ProductDataManagement.FillInSpecificationInLines(RowsToProcess, ProductData_2, BOMSelectionParameters);
		EndIf;
		
		DimensionsToFillIn = CommonClientServer.CollapseArray(DimensionsToFillIn);
		For Each CurGroup In DimensionsToFillIn Do
			TableFillInDependentServiceDetailsOfCostGroup(TSName, CurGroup);
		EndDo;
		
	EndIf;
	
	UpdateDiscrepancyOrder(StructureOfActionParameters.TSName);
	
EndProcedure

#EndRegion

#Region SupportingProcedures

&AtClientAtServerNoContext
Function ParametersForFillingInPriceInTSLine(TSName, Object)
	
	PriceFillingParameters_ = Undefined;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object, True);
	ElsIf TSName = "Services" Then
		PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object);
		//Installing an empty link to the packaging, since there is no record of work on packaging
		PriceFillingParameters_.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	EndIf;
	
	Return PriceFillingParameters_;
	
EndFunction

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

// This procedure should be used if the rows were added programmatically (not interactively), for example, when pasting from
// a buffer, or when filling in according to the specification. The procedure performs actions that depend on the data in the rows.
//
&AtServer
Procedure AfterChangingTSStringsProgrammaticallyOnServer(TSName, Val SelectedRows = Undefined)
	
	If TSName = "ManufacturedProducts" Then
	
		Groups = New Array;
		If SelectedRows <> Undefined Then
			For Each RowID In SelectedRows Do
				RowData = Object.ManufacturedProducts.FindByID(RowID);
				Groups.Add(RowData.CostGroupNumber);
			EndDo;
		EndIf;
		
		CalculatePercentageOfCostAllocationForOutputProducts(Groups);
		
	EndIf;
	
	If Not TSName = "Services" Then
	
		RowsArray = Undefined;
		If SelectedRows <> Undefined Then
			RowsArray = New Array;
			For Each RowID In SelectedRows Do
				RowsArray.Add(Object[TSName].FindByID(RowID));
			EndDo;
		EndIf;
		
		ProductsServer.FillInStatusesForSpecifyingSeries(
			Object,
			SeriesSpecificationParameters[TSName],
			RowsArray);
		
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		AttributesList = "QuantityOverOrder,NumberOfProducts,TheRecordsAreKeptByCCD";
	ElsIf TSName = "Services" Then
		AttributesList = "QuantityOverOrder,AmountOfServices";
	Else
		AttributesList = "NotExecuteJob";
	EndIf;
	
	CalculateDocumentTotals(ThisObject, AttributesList);
	
EndProcedure

&AtServer
Function ParametersOfCostShareEntryForm_(CurrentID)
	
	FormParameters =
		ProductionServer.ParametersOfCostShareEntryForm(
			Object,
			CostAllocationParameters,
			CurrentID);
	
	Return FormParameters;
	
EndFunction

&AtClient
Function ItIsPossibleToReFillAccordingToSpecification()
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Cần chọn sản phẩm.';
								|ru = 'Необходимо выбрать выбрать изделие.';
								|en = 'Select a product.'; fa = 'Select a product.';
								|it = 'È necessario selezionare il prodotto.';
								|pl = 'Należy wybrać wybrać wyrób.';
								|tr = 'Nihai ürün seçmeniz gerekmektedir.'"));
		Return False;
	EndIf;
	
	If Object.ByOrders Then
		Return True;
	EndIf; 
	
	Cancel = False;
	For Each CurrentRow In Items.ManufacturedProducts.SelectedRows Do
		CurrentData = Object.ManufacturedProducts.FindByID(CurrentRow);
		If Not ValueIsFilled(CurrentData.BillOfMaterials) Then
			MessageText = StrTemplate(NStr("vi = 'Chưa điền trường ""Bảng kê chi tiết"" vào dòng %1 của danh sách ""Sản phẩm đầu ra""';
											|ru = 'Не заполнено поле ""Спецификация"" в строке %1 списка ""Выходные изделия""';
											|en = '""Bill of materials"" is required in line %1 of the ""Finished products"" list'; fa = '""Bill of materials"" is required in line %1 of the ""Finished products"" list';
											|it = 'Il campo ""Specifiche"" non è completato nella riga %1 dell''elenco ""Prodotti in uscita""';
											|pl = 'Nie jest wypełnione pole ""Specyfikacja"" w wierszu %1 listy ""Wyroby wyjściowe""';
											|tr = '""Üretilen Nihai Ürünler"" listesinin %1 satırındaki ""Ürün Reçetesi"" alanı doldurulmadı'"), CurrentData.LineNumber);
			AttributePath1 = CommonClientServer.PathToTabularSection("Object.ManufacturedProducts", CurrentData.LineNumber, "BillOfMaterials");
			CommonClient.MessageToUser(MessageText, Object.Ref, AttributePath1,, Cancel);
		EndIf;
	EndDo;
	
	Return Not Cancel;
	
EndFunction

#EndRegion

#EndRegion

#Region GroupCosts

&AtServer
Procedure AddChangeCostGroup(CurrentData, BatchMode = False)
	
	FilterStructure1 = CostGroupSelectionStructure(CurrentData);
	CostGroupPresentation = CostGroupPresentation(FilterStructure1);
	
	GroupNumberBeforeChange = CurrentData.CostGroupNumber;
	
	CostGroupDescription = CostGroupData(FilterStructure1);
	If CostGroupDescription.CostGroupNumber = 0 Then
		
		NewCostGroup = CostGroups.Add();
		FillPropertyValues(NewCostGroup, FilterStructure1);
		
		Object.MaximumNumberOfCostGroup = Object.MaximumNumberOfCostGroup + 1;
		NumberOfCostGroups = NumberOfCostGroups + 1;
		
		NewCostGroup.CostGroupNumber = Object.MaximumNumberOfCostGroup;
		NewCostGroup.ExpenseGroup = CostGroupPresentation;
		
		FillPropertyValues(CostGroupDescription, NewCostGroup);
		
	EndIf;
	
	FillInServiceDetailsOfCostGroup(CostGroupDescription);
	
	If Not GroupNumberBeforeChange = CostGroupDescription.CostGroupNumber
		And NumberOfIdentifyingRows(CostGroupDataByCostGroupNumber(GroupNumberBeforeChange)) = 1 Then
		
		UpdateLinksToCostGroup(GroupNumberBeforeChange, CostGroupDescription);
		
		FilterStructure1 = New Structure("CostGroupNumber", GroupNumberBeforeChange);
		
		FoundRows = CostGroups.FindRows(FilterStructure1);
		For Each CurGroup In FoundRows Do
			CostGroups.Delete(CurGroup);
			NumberOfCostGroups = NumberOfCostGroups - 1;
		EndDo;
		
	EndIf;
	
	CurrentData.CostGroupNumber = CostGroupDescription.CostGroupNumber;
	CurrentData.ExpenseGroup = CostGroupDescription.ExpenseGroup;
	
	If Not BatchMode Then
		
		FillInDependentServiceDetailsOfCostGroup(CostGroupDescription);
		
		If UseImportedGoods Then
			
			UpdateServiceDetailsOfCostGroupInLinkedTS(CostGroupDescription, "MaterialsAndWorks", "ThereIsImportedProduct");
			
			If Not CostGroupDescription.ThereIsImportedProduct Then
				ClearPrimaryByCostGroupFlag(CostGroupDescription.CostGroupNumber);
			EndIf;
			
		EndIf;
		
		CostGroupDescription = CostGroupDataByCostGroupNumber(GroupNumberBeforeChange);
		If Not CostGroupDescription.CostGroupNumber = 0 Then
			
			FillInDependentServiceDetailsOfCostGroup(CostGroupDescription);
			
			If UseImportedGoods Then
				
				UpdateServiceDetailsOfCostGroupInLinkedTS(CostGroupDescription, "MaterialsAndWorks", "ThereIsImportedProduct");
				
				If Not CostGroupDescription.ThereIsImportedProduct Then
					ClearPrimaryByCostGroupFlag(CostGroupDescription.CostGroupNumber);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteCostGroup(CurrentID)
	
	CurrentData = Object.ManufacturedProducts.FindByID(CurrentID);
	
	CostGroupDescription = CostGroupDataByCostGroupNumber(CurrentData.CostGroupNumber);
	
	If NumberOfIdentifyingRows(CostGroupDescription) = 1 Then
		
		CostGroupDescription = CostGroupDescription();
		ClearTSByCostGroup("SideAndIntermediateRelease", CurrentData.CostGroupNumber);
		ClearTSByCostGroup("MaterialsAndWorks", CurrentData.CostGroupNumber);
		ClearTSByCostGroup("Services", CurrentData.CostGroupNumber);
		
		CalculateDocumentTotals(ThisObject, "AmountOfServices");
		
		FilterStructure1 = New Structure("CostGroupNumber", CurrentData.CostGroupNumber);
		FoundRows = CostGroups.FindRows(FilterStructure1);
		For Each CurGroup In FoundRows Do
			CostGroups.Delete(CurGroup);
			NumberOfCostGroups = NumberOfCostGroups - 1;
		EndDo;
		
	Else
		Return;
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - formaclient applications
// 	TSName - String
//
&AtServer
Procedure SetDefaultCostGroupNumber(TSName, CurrentID)
	
	CurrentData = Object[TSName].FindByID(CurrentID);
	
	If Not CurrentData = Undefined
		And CurrentData.CostGroupNumber = 0
		And NumberOfCostGroups = 1 Then
		
		CurrentData.ExpenseGroup = CostGroups[0].ExpenseGroup;
		CurrentData.CostGroupNumber = CostGroups[0].CostGroupNumber;
		CurrentData.ProductionStage  = CostGroups[0].ReferenceOrder;
		
		If Object.ByOrders
			And Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
			And TSName = "ManufacturedProducts" Then
			CurrentData.MethodOfAllocatingFinishedProductCosts = CostGroups[0].MethodOfAllocatingFinishedProductCosts;
		EndIf;
		If Object.ByOrders
			And (Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOM
				Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
				Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments)
			And TSName = "ManufacturedProducts" Then
			CurrentData.BillOfMaterials = CostGroups[0].BillOfMaterials;
		EndIf;
		
		If TSName = "MaterialsAndWorks"
			And UseImportedGoods Then
			CurrentData.ThereIsImportedProduct = CostGroups[0].ThereIsImportedProduct;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateCostGroups()
	
	Documents.SubcontractorReport2_5.UpdateCostGroups(Object, CostGroups, NumberOfCostGroups);
	
	For Each CurGroup In CostGroups Do
		FillInDependentServiceDetailsOfCostGroup(CurGroup);
	EndDo;
	
	UpdateServiceDetailsOfCostGroupsInLinkedTS();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfCostGroup(CostGroupDescription)
	
	Documents.SubcontractorReport2_5.FillInServiceDetailsOfCostGroup(Object, CostGroups, CostGroupDescription);
	
EndProcedure

&AtServer
Procedure FillInDependentServiceDetailsOfCostGroup(CostGroupDescription)
	
	If UseImportedGoods Then
		Documents.SubcontractorReport2_5.FillInDependentServiceDetailsOfCostGroup(Object, CostGroups, CostGroupDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateServiceDetailsOfCostGroupsInLinkedTS(AdditionalCostGroupNumbers = Undefined)
	
	ProcessedCostGroups = New Map();
	
	For Each CurGroup In CostGroups Do
		
		CurGroup.ExpenseGroup = CostGroupPresentation(CurGroup);
		
		UpdateServiceDetailsOfCostGroupInLinkedTS(CurGroup, "ManufacturedProducts",  "ExpenseGroup");
		UpdateServiceDetailsOfCostGroupInLinkedTS(CurGroup, "SideAndIntermediateRelease",  "ExpenseGroup");
		UpdateServiceDetailsOfCostGroupInLinkedTS(CurGroup, "MaterialsAndWorks", "ExpenseGroup, ThereIsImportedProduct");
		UpdateServiceDetailsOfCostGroupInLinkedTS(CurGroup, "Services",           "ExpenseGroup");
		
		ProcessedCostGroups.Insert(CurGroup.CostGroupNumber);
		
	EndDo;
	
	If Not AdditionalCostGroupNumbers = Undefined Then
		
		For Each CostGroupNumber In AdditionalCostGroupNumbers Do
			
			If Not ProcessedCostGroups.Get(CostGroupNumber) = Undefined Then
				Continue;
			EndIf;
			
			CostGroupDescription = CostGroupDataByCostGroupNumber(CostGroupNumber);
			
			CostGroupDescription.ExpenseGroup = CostGroupPresentation(CostGroupDescription);
			
			UpdateServiceDetailsOfCostGroupInLinkedTS(CostGroupDescription, "MaterialsAndWorks", "ThereIsImportedProduct");
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateServiceDetailsOfCostGroupInLinkedTS(CostGroupDescription, TSName, AttributesNames)
	
	FilterStructure1 = New Structure("CostGroupNumber", CostGroupDescription.CostGroupNumber);
	
	Rows = Object[TSName].FindRows(FilterStructure1);
	For Each CurRow In Rows Do
		FillPropertyValues(CurRow, CostGroupDescription, AttributesNames);
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateLinksToCostGroup(CurrentGroupNumber, CostGroupDescription)
	
	If CurrentGroupNumber = 0
		And Not CostGroups.Count() = 1 Then
		Return;
	EndIf;
	
	FilterStructure1 = New Structure("CostGroupNumber", CurrentGroupNumber);
	If Object.ByOrders Then
		
		Rows = Object.ManufacturedProducts.FindRows(FilterStructure1);
		For Each CurrentData In Rows Do
			
			CurrentData.ExpenseGroup = CostGroupDescription.ExpenseGroup;
			CurrentData.CostGroupNumber = CostGroupDescription.CostGroupNumber;
			CurrentData.ProductionStage = CostGroupDescription.ReferenceOrder;
			
			If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
				CurrentData.MethodOfAllocatingFinishedProductCosts = CostGroupDescription.MethodOfAllocatingFinishedProductCosts;
			EndIf;
			
			If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOM
				Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
				Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments Then
				CurrentData.BillOfMaterials = CostGroupDescription.BillOfMaterials;
			EndIf;
			
		EndDo;
		
	EndIf;
	Rows = Object.SideAndIntermediateRelease.FindRows(FilterStructure1);
	For Each CurrentData In Rows Do
		
		CurrentData.ExpenseGroup      = CostGroupDescription.ExpenseGroup;
		CurrentData.CostGroupNumber = CostGroupDescription.CostGroupNumber;
		CurrentData.ProductionStage  = CostGroupDescription.ReferenceOrder;
	EndDo;
	
	Rows = Object.MaterialsAndWorks.FindRows(FilterStructure1);
	For Each CurrentData In Rows Do
		
		CurrentData.ExpenseGroup         = CostGroupDescription.ExpenseGroup;
		CurrentData.CostGroupNumber    = CostGroupDescription.CostGroupNumber;
		
		If UseImportedGoods Then
			CurrentData.ThereIsImportedProduct = CostGroupDescription.ThereIsImportedProduct;
			If Not CurrentData.ThereIsImportedProduct Then
				CurrentData.Main = False;
			EndIf;
		EndIf;
		CurrentData.ProductionStage = CostGroupDescription.ReferenceOrder;
	EndDo;
	
	Rows = Object.Services.FindRows(FilterStructure1);
	For Each CurrentData In Rows Do
		
		CurrentData.ExpenseGroup      = CostGroupDescription.ExpenseGroup;
		CurrentData.CostGroupNumber = CostGroupDescription.CostGroupNumber;
		CurrentData.ProductionStage  = CostGroupDescription.ReferenceOrder;
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearTSByCostGroup(TSName, CurrentGroupNumber)
	
	Table = Object[TSName].Unload(); // ValueTable
	Table.Indexes.Add("CostGroupNumber");
	
	Filter = New Structure("CostGroupNumber", CurrentGroupNumber);
	FoundRows = Table.FindRows(Filter);
	For Each CurRow In FoundRows Do
		Table.Delete(CurRow);
	EndDo;
	
	Object[TSName].Load(Table);
	
EndProcedure

&AtServer
Procedure ClearPrimaryByCostGroupFlag(CurrentGroupNumber)
	
	FoundRows = BasicMaterialsOfCostGroup(CurrentGroupNumber);
	For Each FoundRow In FoundRows Do
		FoundRow.Main = False;
	EndDo;
	
EndProcedure

&AtServer
Function BasicMaterialsOfCostGroup(CurrentGroupNumber)
	
	FilterStructure1 = New Structure("CostGroupNumber, Main", CurrentGroupNumber, True);
	
	Return Object.MaterialsAndWorks.FindRows(FilterStructure1);
	
EndFunction

&AtServer
Function CostGroupDescription()
	
	CostGroupDescription = New Structure;
	
	Columns = CostGroups.Unload(New Array).Columns; // ValueTableColumnCollection
	For Each Column In Columns Do
		CostGroupDescription.Insert(Column.Name, Column.ValueType.AdjustValue());
	EndDo;
	
	Return CostGroupDescription;
	
EndFunction

&AtServer
Function CostGroupDataByCostGroupNumber(CurrentGroupNumber)
	
	FilterStructure1 = New Structure("CostGroupNumber", CurrentGroupNumber);
	Return CostGroupData(FilterStructure1);

EndFunction

&AtServer
Function CostGroupData(FilterStructure1)
	
	CostGroupDescription = CostGroupDescription();
	
	FoundRows = CostGroups.FindRows(FilterStructure1);
	If Not FoundRows.Count() = 0 Then
		FillPropertyValues(CostGroupDescription, FoundRows[0]);
	EndIf;
	
	Return CostGroupDescription;

EndFunction

&AtServer
Function CostGroupSelectionStructure(CurrentData)
	
	FieldList =
		ProcessingByThirdPartiesClientServer.ListOfCostGroupFieldsInProcessorSReport(Object.GroupCosts);
	
	FilterStructure1 = ProcessingByThirdPartiesClientServer.CostGroupSelectionStructure(FieldList);
	
	If Not CurrentData = Undefined Then
		FillPropertyValues(FilterStructure1, CurrentData);
	EndIf;
	
	Return FilterStructure1;
	
EndFunction

&AtServer
Function NumberOfIdentifyingRows(CostGroupDescription)
	
	FilterStructure1 = New Structure("CostGroupNumber", CostGroupDescription.CostGroupNumber);
	FoundRows = Object.ManufacturedProducts.FindRows(FilterStructure1);
	
	Return FoundRows.Count();
	
EndFunction

&AtServer
Function CostGroupPresentation(Var_Group)
	
	Return ProcessingByThirdPartiesClientServer.CostGroupPresentation(
				Var_Group,
				ProcessingByThirdPartiesClientServer.ListOfCostGroupFieldsInProcessorSReport(Object.GroupCosts));
	
EndFunction 

&AtServer
Function PutCostGroupDataInStorage(TSName)
	
	Table = CostGroups.Unload();
	Return PutToTempStorage(Table, UUID);
	
EndFunction

#EndRegion

#Region ChangeControl

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If Not PerformChecksBeforeChangingProps() Then
		TMCommonUseClient.ReturnPreviousPropsValue(ThisObject, Item);
		Return;
	Else
		TMCommonUseClient.SaveAttributeValue(ThisObject, Item);
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ChangeControlHandleEventOnChange(Item);
	EndIf;

EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure Attachable_Command_SetAvailabilityOfItemsByStatusServer(Command)
	
	If Not PerformChecksBeforeChangingProps() Then
		Return;
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ChangeControlHandleCommandEvent(Command);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If Not PerformChecksBeforeChangingProps() Then
		Cancel = True;
		Return;
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Property(Name) Then
		ChangeControlHandleEventBeforeDeletion(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not PerformChecksBeforeChangingProps() Then
		Cancel = True;
		Return;
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeAddRow.Property(Name) Then
		ChangeControlProcessEventBeforeYouStartAdding(Item, Cancel, Copy, Parent, Var_Group);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If StructureOfActionsControlOfNonAgreedChanges = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(StructureOfActionsControlOfNonAgreedChanges.AttributesValues[Item.Name], Item.CurrentData);
	
EndProcedure

&AtClient
Function PerformChecksBeforeChangingProps()
	
	ClearMessages();
	
	ThereAreInvoices_1 = False;
	PropsCanBeChanged = False;
	
	Notification = New CallbackDescription("QuestionResultCompletion", ThisObject);
	
	If StructureOfActionsControlOfNonAgreedChanges = Undefined
		Or StructureOfActionsControlOfNonAgreedChanges.AlertIsExpected Then
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
	EndIf;
	
	CheckForAdjustmentsAndInvoices(Object.Ref, ThereAreAdjustingEntries, ThereAreInvoices_1);
	
	If (ThereAreAdjustingEntries
			Or ThereAreInvoices_1)
		And Not HaveRightToAddAdjustments
		And UseDebitNotes Then
		
		If ThereAreAdjustingEntries Then
			MessageText = NStr("vi = 'Trên cơ sở chứng từ đã nhập điều chỉnh.
								|Không đủ quyền để tạo điều chỉnh bảng kê của người nhận gia công.';
								|ru = 'На основании документа введена корректировка.
								|Недостаточно прав для создания корректировки отчета переработчика.';
								|en = 'Adjustment is generated based on the document.
								|You are not authorized to create adjustment of ""Subcontracting services notification received"".'; fa = 'Adjustment is generated based on the document.
								|You are not authorized to create adjustment of ""Subcontracting services notification received"".';
								|it = 'È stata inserita una rettifica sulla base del documento.
								|Diritti insufficienti per la creazione della rettifica del report dell''elaboratore.';
								|pl = 'Na podstawie dokumentu wprowadzono korektę.
								|Nie wystarcza praw do utworzenia korekty raportu przetwórcy.';
								|tr = 'Belge temelinde düzeltme girildi.
								|Alınan fason hizmetleri bildirimine düzeltme oluşturmak için yeterli erişim yetkisi yok.'");
		Else
			MessageText = NStr("vi = 'Trên cơ sở chứng từ đã ghi nhận hóa đơn GTGT.
								|Không đủ quyền để tạo điều chỉnh bảng kê của người nhận gia công.';
								|ru = 'На основании документа зарегистрирована счет-фактура.
								|Недостаточно прав для создания корректировки отчета переработчика.';
								|en = 'Tax invoice is registered based on the document.
								|You are not authorized to create adjustment of ""Subcontracting services notification received"".'; fa = 'Tax invoice is registered based on the document.
								|You are not authorized to create adjustment of ""Subcontracting services notification received"".';
								|it = 'È stata registrata una fattura fiscale sulla base del documento.
								|Diritti insufficienti per la creazione della rettifica del report dell''elaboratore.';
								|pl = 'Na podstawie dokumentu zarejestrowano fakturę.
								|Nie wystarcza praw do wykonania korekty raportu przetwórcy.';
								|tr = 'Belge temelinde vergi faturası kaydedildi.
								|Alınan fason hizmetleri bildirimine düzeltme oluşturmak için yeterli erişim yetkisi yok.'");
		EndIf;
		
		CommonClient.MessageToUser(MessageText);
		
	ElsIf ThereAreAdjustingEntries
		And UseDebitNotes Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add("EnterTheAdjustment", NStr("vi = 'Nhập điều chỉnh';
													|ru = 'Ввести корректировку';
													|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
													|it = 'Inserire rettifica';
													|pl = 'Wprowadź korektę';
													|tr = 'Düzenleme yapın'"));
		ButtonsList.Add("UndoChanges", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Trên cơ sở chứng từ đã nhập điều chỉnh.
				|Cấm thay đổi chứng từ gốc.';
				|ru = 'На основании документа введена корректировка.
				|Изменение исходного документа запрещено.';
				|en = 'Adjustment is generated based on the document.
				|The source document cannot be changed.'; fa = 'Adjustment is generated based on the document.
				|The source document cannot be changed.';
				|it = 'È stata inserita una rettifica sulla base del documento.
				|È vietato modificare il documento originale.';
				|pl = 'Na podstawie dokumentu wprowadzono korektę.
				|Zmiana dokumentu źródłowego jest zabroniona.';
				|tr = 'Belge temelinde düzeltme girildi.
				|Orijinal belgenin değiştirilmesi yasaktır.'"),
			ButtonsList,,
			"EnterTheAdjustment");
		
	ElsIf ThereAreInvoices_1
		And UseDebitNotes Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add("EnterTheAdjustment", NStr("vi = 'Nhập điều chỉnh';
													|ru = 'Ввести корректировку';
													|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
													|it = 'Inserire rettifica';
													|pl = 'Wprowadź korektę';
													|tr = 'Düzenleme yapın'"));
		ButtonsList.Add("UndoChanges", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Trên cơ sở chứng từ đã ghi nhận hóa đơn GTGT.
				|Nhập điều chỉnh bảng kê của người nhận gia công để xuất hóa đơn GTGT đã chỉnh sửa?';
				|ru = 'На основании документа зарегистрирована счет-фактура.
				|Ввести корректировку отчета переработчика для выставления исправленных счетов-фактур?';
				|en = 'Tax invoice is registered based on the document.
				|Enter adjustment of ""Subcontracting services notification received"" to issue corrected tax invoices?'; fa = 'Tax invoice is registered based on the document.
				|Enter adjustment of ""Subcontracting services notification received"" to issue corrected tax invoices?';
				|it = 'È stata registrata una fattura fiscale sulla base del documento.
				|Inserire rettifica del report dell''elaboratore per l''emissione di fattura fiscali corrette?';
				|pl = 'Na podstawie dokumentu zarejestrowano fakturę.
				|Wprowadzić korektę raportu przetwórcy w celu wystawienia skorygowanych faktur?';
				|tr = 'Belge temelinde vergi faturası kaydedildi.
				|Düzeltilmiş vergi faturaları oluşturmak için alınan fason üretici hizmetleri bildirimine düzenleme yapılsın mı?'"),
			ButtonsList,,
			"EnterTheAdjustment");
		
	Else
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	Return PropsCanBeChanged;
	
EndFunction

&AtClient
Procedure QuestionResultCompletion(ResponseCode, AdditionalParameters) Export
	
	If ResponseCode = "EnterTheAdjustment" Then // "Enter an adjustment"
		OpenForm("Document.PurchaseAdjustment.ObjectForm", New Structure("Basis", Object.Ref));
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - Form element
&AtClient
Procedure ChangeControlHandleEventOnChange(Item)
	
	// Header Controls
	If Item.Name = "Date" Then
		DateOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = "Department" Then
		Return;
	ElsIf Item.Name = "Partner" Then
		PartnerOnChange(Item);
	ElsIf Item.Name = "Counterparty" Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = "Contract" Then
		ContractOnChange(Item);
	ElsIf Item.Name = "GroupCosts" Then
		GroupCostsOnChange(Item);
	ElsIf Item.Name = "PriceIncludesVAT" Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = "VATTaxation" Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = "PurchaseForActivity" Then
		Return;
	ElsIf Item.Name = "LineOfBusiness" Then
		LineOfBusinessOnChange(Item);
	ElsIf Item.Name = "ByOrders" Then
		OrderInvoice_3OnChange(Item);
	// Controls related to payment
	ElsIf Item.Name = "CompanyBankAccount" Then
		Return;
	ElsIf Item.Name = "CounterpartyBankAccount" Then
		Return;
	ElsIf Item.Name = "ARAPObjectSettings" Then
		Return;
	ElsIf Item.Name = "PaymentMethod" Then
		Return;
	// Controls associated with the output TablerefErences
	ElsIf Item.Name = "ManufacturedProductsExpenseGroup" Then
		Return;
	ElsIf Item.Name = "ManufacturedProductsProducts" Then
		ManufacturedProductsProductsOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductsCharacteristic" Then
		ManufacturedProductsCharacteristicOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductsPurpose" Then
		Return;
	ElsIf Item.Name = "ManufacturedProductsSeries" Then
		ManufacturedProductsSeriesOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductsNumberOfPackages" Then
		ManufacturedProductsNumberOfPackagesOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductsPackage" Then
		ManufacturedProductsPackageOnChange(Item);
	ElsIf Item.Name = "ManufacturedProductsBillOfMaterials" Then
		Return;
	// Controls associated with the Services table
	ElsIf Item.Name = "ServicesExpenseGroup" Then
		Return;
	ElsIf Item.Name = "ServicesProducts" Then
		ServicesProductsOnChange(Item);
	ElsIf Item.Name = "ServicesCharacteristic" Then
		ServicesCharacteristicOnChange(Item);
	ElsIf Item.Name = "ServicesCount" Then
		ServicesCountOnChange(Item);
	ElsIf Item.Name = "ServicesVendorPriceKind" Then
		ServicesVendorPriceKindOnChange(Item);
	ElsIf Item.Name = "ServicesPrice" Then
		ServicesPriceOnChange(Item);
	ElsIf Item.Name = "ServicesSum" Then
		ServicesSumOnChange(Item);
	ElsIf Item.Name = "ServicesVATAmount" Then
		ServicesVATAmountOnChange(Item);
	ElsIf Item.Name = "ServicesVATRate" Then
		ServicesVATRateOnChange(Item);
	ElsIf Item.Name = "ServicesAmountIncludingVAT" Then
		Return;
	ElsIf Item.Name = "ProductCostElement" Then
		Return;
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ChangeControlHandleCommandEvent(Command)
	
	// Commands related to the output TablerefErences
	If Command.Name = "ManufacturedProductsInsertRows" Then
		ManufacturedProductsInsertRows(Command);
	ElsIf Command.Name = "FinishedProductsSearchByBarcode" Then
		FinishedProductsSearchByBarcode(Command);
	ElsIf Command.Name = "ManufacturedProductsImportDataFromPDT" Then
		ManufacturedProductsImportDataFromPDT(Command);
	ElsIf Command.Name = "ManufacturedProductsPickUpProducts" Then
		ManufacturedProductsPickUpProducts(Command);
	ElsIf Command.Name = "SelectOutputProductsFromOrder" Then
		SelectOutputProductsFromOrder(Command);
	ElsIf Command.Name = "ManufacturedProductsToRefillCostlyTS" Then
		ManufacturedProductsToRefillCostlyTS(Command);
	ElsIf Command.Name = "OutputItemsFillCostGroup" Then
		OutputItemsFillCostGroup(Command);
	ElsIf Command.Name = "OutputProductsSpecifyTheSeries" Then
		OutputProductsSpecifyTheSeries(Command);
	ElsIf Command.Name = "OutputProductsTransferToByProducts" Then
		OutputProductsTransferToByProducts(Command);
	// Commands related to the Services table
	ElsIf Command.Name = "ServicesInsertRows" Then
		ServicesInsertRows(Command);
	ElsIf Command.Name = "BarcodeSearchServices" Then
		BarcodeSearchServices(Command);
	ElsIf Command.Name = "ServicesImportDataFromPDT" Then
		ServicesImportDataFromPDT(Command);
	ElsIf Command.Name = "ServicesPickUpProducts" Then
		ServicesPickUpProducts(Command);
	ElsIf Command.Name = "ServicesFillTSByOrderSpecification" Then
		ServicesFillTSByOrderSpecification(Command);
	ElsIf Command.Name = "ServicesFillInPricesBySupplierPriceType" Then
		ServicesFillInPricesBySupplierPriceType(Command);
	ElsIf Command.Name = "ServicesFillCostGroup" Then
		ServicesFillCostGroup(Command);
	ElsIf Command.Name = "ServicesSelectAndCompleteService" Then
		ServicesSelectAndCompleteService(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Command);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ChangeControlHandleEventBeforeDeletion(Item, Cancel)
	If Item.Name = "ManufacturedProducts" Then
		ManufacturedProductsBeforeDeleteRow(Item, Cancel);
	ElsIf Item.Name = "Services" Then
		Return;
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ChangeControlProcessEventBeforeYouStartAdding(Item, Cancel, Copy, Parent, Var_Group)
	
	If Item.Name = "ManufacturedProducts" Then
		Return;
	ElsIf Item.Name = "Services" Then
		Return;
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;

EndProcedure

&AtServerNoContext
Procedure CheckForAdjustmentsAndInvoices(Ref, ThereAreAdjustingEntries, ThereAreInvoices_1)
	
	PurchasesServer.CheckForAdjustmentsAndInvoices(Ref, Ref, ThereAreAdjustingEntries, ThereAreInvoices_1);
	
EndProcedure

&AtServer
Procedure UpdateFlagThereAreAdjustments()
	
	ThereAreInvoices_ = False;
	CheckForAdjustmentsAndInvoices(Object.Ref, ThereAreAdjustingEntries, ThereAreInvoices_);
	
EndProcedure

// Parameters:
// 	Item - FormField, FormButton, FormGroup, FormTable - Form element
// 	ItemsNames - Array - element names
// 	ExceptionNames - Array - exception names
&AtServer
Procedure AddExceptionNamesOfSubordinateElements(Item, ItemsNames, ExceptionNames)
	
	If TypeOf(Item) = Type("FormGroup")
		Or TypeOf(Item) = Type("FormTable") Then
		For Each CurItem In Item.ChildItems Do
			AddExceptionNamesOfSubordinateElements(CurItem, ItemsNames, ExceptionNames)
		EndDo;
	ElsIf ItemsNames.Find(Item.Name) = Undefined Then
		ExceptionNames.Add(Item.Name);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function DataOfWare()
	
	NamesOfTS = New Array;
	NamesOfTS.Add("ManufacturedProducts");
	NamesOfTS.Add("SideAndIntermediateRelease");
	
	FieldsData = ProductionServer.TableFieldStructure();
	FieldsData.MainField = "SubcontractOrder, RowCode, Products, Characteristic, Count";
	FieldsData.DefaultValues.Insert("SubcontractOrder", Object.SubcontractOrder);
	
	TSData = New Structure;
	For Each TSName In NamesOfTS Do

		TSData.Insert(
			TSName,
			ProductionServer.PlaceStringDataInTemporaryStorage(ThisObject, "Object", TSName, False, FieldsData));
	
	EndDo;
	
	Return TSData;
	
EndFunction

#EndRegion

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

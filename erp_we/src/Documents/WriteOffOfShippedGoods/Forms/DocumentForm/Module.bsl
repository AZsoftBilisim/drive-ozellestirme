
#Region Variables

&AtClient
Var PreviousRowDetails; //used to unlink the receipt line from the order line

&AtClient
Var CachedValues; //It is used by the mechanism for processing changes in PM details.

&AtClient
Var CurDataId; //Used to pass the current line to the waiting handler.

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",						Object);
	AdditionalParameters.Insert("ItemForPlacementName",	"GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization",		True);
	PropertyManager.OnCreateAtServer(ThisObject,			AdditionalParameters);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
		Object.SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByPriceType;
		
		SourseOfInformationAboutPricesForPrintingOnChangeServer();
	Else
		SetAvailabilityViewPrices(Object.SourseOfInformationAboutPricesForPrinting);
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffOfShippedGoods.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	// Setting up accounting accounts.
	SetupParameters = Documents.WriteOffOfShippedGoods.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	FillingCommands = New Array();
	FillingCommands.Add(Items.GoodsFillInCCDNumbers);
	FillingCommands.Add(Items.GoodsSelectTransferredGoods);
	
	If Object.Patch Then
		For Each FillingCommand In FillingCommands Do
			FillingCommand.Visible = False;
		EndDo;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttributesNames =
		"Products,
		|Characteristic,
		|Purpose,
		|Warehouse,
		|Count,
		|ItemsType,
		|ItemVariantsAreUsed";
	
	PreviousRowDetails = New Structure(AttributesNames);
	
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
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "CommonForm.AddItemsFromSalesOrderGoodsIssue" Then
		
		ProcessingProductSelectionFromOrder(ValueSelected.AddressInStorage);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsTransferredToCustody.Form.Form" Then
		
		SelectionProcessingSelectionOfTransferredGoods(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		ContractOnChange(Items[Parameter]);
	EndIf;
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// Handler of the "Properties" subsystem
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffOfShippedGoods.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	// Setting up accounting accounts.
	SetupParameters = Documents.WriteOffOfShippedGoods.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Handler = Documents.WriteOffOfShippedGoods.ActionHandler(Object.BusinessOperation);
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	FillInServiceDetailsForProductRange();
	UpdateInformationOnOrders();
	UpdateOrderDeviations();
	
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Title = "";
	AutoTitle = True;
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_WriteOffOfShippedGoods", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If BusinessTransactionBeforeTheChange = Object.BusinessOperation Then
		Return;
	EndIf;
	
	BusinessOperationOnChangeServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure PriceKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	OriginalPriceView = Object.PriceKind;
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	NewKindOfPrice = Object.PriceKind;
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure ReferenceOrderPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "Open_Order" Then
		ShowValue(, Object.ReferenceOrder)
	Else
		
		// &PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement(
			"Document.WriteOffOfShippedGoods.Form.ReferenceChoiceForm");

		CallbackDescription = New CallbackDescription("CustomerSChoice", ThisObject);
		OpenOrderSelection(CallbackDescription);

	EndIf;
	
EndProcedure

&AtClient
Procedure CaptionOrderTitleClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	TitleText    = NStr("vi = 'Lệnh (%DocumentsCount%)';
						|ru = 'Распоряжения (%DocumentsCount%)';
						|en = 'References (%DocumentsCount%)'; fa = 'References (%DocumentsCount%)';
						|it = 'Disposizioni (%DocumentsCount%)';
						|pl = 'Zamówienia (%DocumentsCount%)';
						|tr = 'Talimatlar (%DocumentsCount%)'");
	OpeningParameters = New Structure("DocumentsList, Title", ListOfOrders_, TitleText);
	
	OpenForm("CommonForm.ViewingListOfDocuments",
	    OpeningParameters,
	    ThisObject,
	    ,
	    ,
	    ,
	    Undefined,
	    FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = DocumentCurrency;
		
		Return;
	EndIf;
	
	FillInPriceTypes();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	OriginalPriceView = Object.PriceKind;
	PartnerOnChangeServer();
	
	
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	OriginalPriceView = Object.PriceKind;
	CounterpartyOnChangeServer();
	
	
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	If Terms = Object.Terms Then
		Return;
	EndIf;
	
	OriginalPriceView = Object.PriceKind;
	TermsOnChangeServer();
	
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	AgreementSelectionParameters.Item               = Item;
	AgreementSelectionParameters.Partner               = Object.Partner;
	AgreementSelectionParameters.Document              = Object.Terms;
	AgreementSelectionParameters.DocumentDate         = Object.Date;
	AgreementSelectionParameters.FormDataStructure  = Object;
	AgreementSelectionParameters.BusinessOperation = ContractBusinessTransaction;
	AgreementSelectionParameters.ConsignmentSales25 = ?(ConsignmentSales25, True, Undefined);
	AgreementSelectionParameters.ShipmentWithDeferredTransferOfTitle25 = ?(ShipmentWithDeferredTransferOfTitle25,
																			True,
																			Undefined);
	AgreementSelectionParameters.ContractsAreUsed = ?(ShipmentWithDeferredTransferOfTitle25,
																	True,
																	Undefined);
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure TransactionRecordingPresentationClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OriginalPriceView = Object.PriceKind;
	
	OrganizationOnChangeServer();
	
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	PurchasesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	OriginalPriceView = Object.PriceKind;
	
	If ShipmentWithDeferredTransferOfTitle25 Then
	
		If Contract = Object.Contract Then
			Return;
		EndIf;
		
		If Object.Goods.Count() > 0 Then
		
			ButtonsList = New ValueList;
			ButtonsList.Add("Continue", NStr("vi = 'Xóa hàng hóa';
											|ru = 'Очистить товары';
											|en = 'Clear goods'; fa = 'Clear goods';
											|it = 'Cancellare le merci';
											|pl = 'Oczyść wiersze pozycji';
											|tr = 'Ürünleri temizle'"));
			ButtonsList.Add("Unlink", NStr("vi = 'Hủy liên kết với lệnh';
											|ru = 'Отвязать от распоряжения';
											|en = 'Unlink from reference'; fa = 'جدا کردن از مرجع';
											|it = 'Scollegare dalla disposizione';
											|pl = 'Odwiąż od dyspozycji';
											|tr = 'Emirden ayır'"));
			
			QueryText = NStr("vi = 'Khi thay đổi hợp đồng, cần xóa hết danh sách ""Hàng hóa"" hoặc bỏ liên kết dòng khỏi lệnh. Tiếp tục?';
							|ru = 'При изменении договора список ""Товары"" необходимо очистить, либо отвязать строки от распоряжения. Продолжить?';
							|en = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the contract. Continue?'; fa = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the contract. Continue?';
							|it = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the contract. Continue?';
							|pl = 'It is required to clear the ""Goods"" list or unlink lines from the reference while changing the contract. Continue?';
							|tr = 'Ambar değiştiğinde, ""Ürünler"" listesinin temizlenmesi veya satırların siparişlerden ayrılması gerekir. Devam edilsin mi?'");
			
			Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
			ShowQueryBox(Notification, QueryText, ButtonsList);
			
		Else
			
			ContractOnChangeServer();
			
		EndIf;
			
		Return;
	EndIf;
	
	ContractOnChangeServer();
	
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Warehouse <> Object.Warehouse Then
		
		If Object.Goods.Count() > 0
			And Not ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse)
			And ValueIsFilled(Warehouse) Then
			
			QueryText = NStr("vi = 'Khi thay đổi kho bãi, các dòng trong danh sách ""Hàng hóa"" sẽ bị bỏ liên kết khỏi lệnh. Tiếp tục?';
							|ru = 'При изменении склада строки списка ""Товары"" будут отвязаны от распоряжений. Продолжить?';
							|en = 'If you change the warehouse, the ""Goods"" list lines will be unlinked from references. Continue?'; fa = 'If you change the warehouse, the ""Goods"" list lines will be unlinked from references. Continue?';
							|it = 'If you change the warehouse, the ""Goods"" list lines will be unlinked from references. Continue?';
							|pl = 'If you change the warehouse, the ""Goods"" list lines will be unlinked from references. Continue?';
							|tr = 'Ambar değiştirildiğinde ürün listesi satırları siparişlerden ayrıştırılacaktır. Devam edilsin mi?'");
			Notification = New CallbackDescription("WarehouseOnChangeCompletion", ThisObject);
			ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
			
			Return;
			
		EndIf;
		
		WarehouseOnChangeServer(False, False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReduceShipmentByReferenceOnChange(Item)
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
EndProcedure

&AtClient
Procedure SourseOfInformationAboutPricesForPrintingOnChange(Item)
	
	SourseOfInformationAboutPricesForPrintingOnChangeServer();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
			
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = "GoodsCCDNumber" Then
		PurchasesClient.FillInListOfCCDNumberSelection(Items.Goods.CurrentData, Items.GoodsCCDNumber.ChoiceList);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	
	FillPropertyValues(PreviousRowDetails, Items.Goods.CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData; 
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If ShipmentWithDeferredTransferOfTitle25 Then
		
		StructureOfActions = New Structure;
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
		BatchProcessingOfTablePartClient.ProcessTSString(
			CurrentRow,
			StructureOfActions,
			Undefined);
		
	EndIf;

	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText,
		ShipmentWithDeferredTransferOfTitle25);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	If ShipmentWithDeferredTransferOfTitle25 Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If NewRow And Not UseWriteOffForMultipleOrders Then
			CurrentData.ReferenceOrder = Object.ReferenceOrder;
		ElsIf NewRow Then
			CurrentData.ReferenceOrder = Undefined;
		EndIf;

		If Copy Then
			CurrentData.RowCode = 0;
			CurrentData.Purpose = Undefined;
			CurrentData.ReferenceOrder = Undefined;
			
			If ShipmentWithDeferredTransferOfTitle25 Then
				
				StructureOfActions = New Structure;
				OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
				BatchProcessingOfTablePartClient.ProcessTSString(
					CurrentData,
					StructureOfActions,
					Undefined);
					
			EndIf;
			
			UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText,
				ShipmentWithDeferredTransferOfTitle25);
			
		EndIf;
		
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,
																CachedValues,
																SeriesSpecificationParameters,
																Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData        = Items.Goods.CurrentData;
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(Item,
																			CachedValues,
																			SeriesSpecificationParameters);
	
	If UpdateSeriesStatuses Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	
	If Not CancelEdit Then
		
		If ShipmentWithDeferredTransferOfTitle25 Then
			
			LineCache =
				?(NewRow,
				Undefined,
				ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
			
			WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);

			TotalWarehouses_ = WarehouseTable.Count();
			WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses,
				TotalWarehouses_);
				
		EndIf;
		
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText,
		ShipmentWithDeferredTransferOfTitle25);
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsReferenceOrder Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If ValueIsFilled(CurrentData.ReferenceOrder) Then
			ShowValue(Undefined, CurrentData.ReferenceOrder);
		ElsIf ValueIsFilled(Object.ReferenceOrder) Then
			ShowValue(Undefined, Object.ReferenceOrder);
		EndIf;
	
	EndIf;

EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(Item,
																			CachedValues,
																			SeriesSpecificationParameters,
																			True);
	
	GoodsAfterDeleteRowServer(UpdateSeriesStatuses, CachedValues);
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	FillInArticleAttribute                  = New Structure("Products", "SKU");
	FillInProductTypeAttribute_          = New Structure("Products", "ItemsType");
	FillInCCDTrackingAttribute         = New Structure("Products", "TheRecordsAreKeptByCCD");
	CheckSeriesCalculateStatus           = New Structure("Warehouse, SeriesSpecificationParameters",
																CurrentRow.Warehouse, SeriesSpecificationParameters);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName", FormName, "Goods");
	CountryOfOriginFillingParameters   = BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters();
	
	StructureOfActions = New Structure;

	StructureOfActions.Insert("FillInArticleAttribute",            FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",    FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",     CheckSeriesCalculateStatus);
	StructureOfActions.Insert("FillInCCDTrackingAttribute",   FillInCCDTrackingAttribute);
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct", CountryOfOriginFillingParameters);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
	If ConsignmentSales25 And ValueIsFilled(Object.PriceKind) Then
		PricesCalculated = FillInPricesByPriceKindServer(CurrentRow.GetID());
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	EndIf;
	
	FillPropertyValues(PreviousRowDetails, CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CharacteristicOnChangeOverridable = New Structure("FormName, TabularSectionName", FormName, "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", CharacteristicOnChangeOverridable);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Items.Goods.CurrentData;
	
	FillInCountryOfOriginForCCDNumber = New Structure("CCDNumber", ValueSelected);
	
	StructureOfActions = New Structure("FillInCountryOfOriginForCCDNumber", FillInCountryOfOriginForCCDNumber);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.FieldNameQuantity = "Count";
	AdditionalParameters.BasisOfCostOfAdmission = False;
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

&AtClient
Procedure GoodsCountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", "Count");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	CallbackDescription = New CallbackDescription("GoodsWarehouseWhenChangingQuestionToUserCompletion",
														ThisObject,
														AdditionalParameters);
	
	QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow);

EndProcedure

&AtClient
Procedure GoodsReferenceOrderStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;

	If Items.Goods.CurrentData <> Undefined Then
		
		CallbackDescription = New CallbackDescription("SelectReferenceCompletion", ThisObject);
		OpenOrderSelection(CallbackDescription);
		Return;
		
	EndIf;
	
	UpdateInformationOnOrders();
	
EndProcedure

&AtClient
Procedure GoodsReferenceOrderOnChange(Item)
	UpdateInformationOnOrders();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand,
												Var_URL = Undefined,
												StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure
// End StandardSubsystems.Properties

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

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

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

#Region FormTableCommandHandlersGoods

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
	
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	CurrentData = FormTable.CurrentData;
	TableData = Object.Goods;
	
	AttributesNames   = "Sum";
	FieldNameQuantity = "Count";
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
								AttributesNames, FieldNameQuantity);
	
	PartitioningParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	PartitioningParameters.FieldNameQuantity = "Count";
	
	If Not FormTable.CurrentData = Undefined Then
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, CurrentData);
	EndIf;
	
	AdditionalParameters = New Structure("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	CallbackDescription      = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, CallbackDescription, PartitioningParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(
			AdditionalParameters.StructureOfRecalculationOfAmount,
			CurrentRow);
		
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(
			AdditionalParameters.StructureOfRecalculationOfAmount,
			NewRow);
		
		BatchProcessingOfTablePartClientServer.RecalculateAmounts(
			AdditionalParameters.StructureOfRecalculationOfAmount);
		
		WhenChangingWarehouseInTablePartServer();
		
	EndIf;

EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	AddressOfTheGoodsInTheTemporaryStorage = PutTablePartOfGoodsInTemporaryStorageToCheckQuantity();
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Ref",            Object.Ref);
	OpeningParameters.Insert("TabularSectionName", "Goods");
	
	OpeningParameters.Insert("NotUsePackages", True);
	OpeningParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	OpeningParameters.Insert("AddressInTempStorage", AddressOfTheGoodsInTheTemporaryStorage);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", True);
	
	CallbackDescription = New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject);
	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters, ThisObject, , , , CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Modified   = True;
		CachedValues = ?(CachedValues = Undefined,
								BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(),
								CachedValues);
		
		ChangeTablePartBasedOnResultsOfCheck(Result, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure SelectTransferredGoods(Command)
	
	Cancel = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Partner) Then
		ErrorText = CommonClientServer.FillingErrorText( , , Items.Partner.Title);
		
		CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.Partner", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
						|ru = 'Поле ""Организация"" не заполнено';
						|en = 'The ""Company"" field is required'; fa = 'The ""Company"" field is required';
						|it = 'Il campo ""Società"" non è compilato';
						|pl = 'Nie wypełniono pola ""Firma""';
						|tr = '""İş yeri"" alanı doldurulmadı'");
		
		CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.Organization", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		ErrorText = NStr("vi = 'Trường ""Hợp đồng"" chưa điền';
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
		"Document.WriteOffOfShippedGoods.DocumentForm.Command.SelectTransferredGoods");
	
	AddressOfGoods = PlaceGoodsInStorageForSelectionOfTransferredGoods();
	
	FormCaption = ?(ShipmentWithDeferredTransferOfTitle25,
						NStr("vi = 'Chọn hàng hóa đã giao cho khách';
							|ru = 'Подбор товаров, отгруженных клиенту';
							|en = 'Pick goods shipped to customer'; fa = 'Pick goods shipped to customer';
							|it = 'Pick goods shipped to customer';
							|pl = 'Pick goods shipped to customer';
							|tr = 'Müşteriye sevk edilen ürünlerin seçimi'"),
						"");
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref",                Object.Ref);
	FormParameters.Insert("Owner",              Object.Partner);
	FormParameters.Insert("Organization",           Object.Organization);
	FormParameters.Insert("Contract",               Object.Contract);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("AddressOfGoodsInvoiceInVault", AddressOfGoods);
	FormParameters.Insert("Title",             FormCaption);
	FormParameters.Insert(
		"CollapseGTDNumbers",
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsWriteOffAtToller"));
	OpenForm("DataProcessor.SelectGoodsTransferredToCustody.Form.Form", FormParameters, ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure PickUpItemsByOrder(Command)
	OpenSelectionByOrders();
EndProcedure

&AtClient
Procedure FillInTheGTDPoNumbersForTheTransferredGoods(Command)
	
	ThereAreFilledInCCDNumbers = False;
	For Each Page1 In Object.Goods Do
		If ValueIsFilled(Page1.CCDNumber) Then
			ThereAreFilledInCCDNumbers = True;
			Break;
		EndIf;
	EndDo;
	
	If ThereAreFilledInCCDNumbers Then
		CallbackDescription = New CallbackDescription("ProcessAnswerToQuestionAboutFillingInCCDNumbers", ThisObject);
		QueryText = NStr("vi = 'Số TKHQ sẽ bị xóa và điền lại. Tiếp tục?';
						|ru = 'Будут очищены и перезаполнены номера ГТД. Продолжить?';
						|en = 'CCD numbers will be cleared and refilled. Continue?'; fa = 'CCD numbers will be cleared and refilled. Continue?';
						|it = 'I numeri delle polizze doganali di carico verranno eliminati e reinseriti. Continuare?';
						|pl = 'Numery LP zostaną wyczyszczone i uzupełnione. Kontynuować?';
						|tr = 'GKB numarası silinecek ve yeniden doldurulacaktır. Devam edilsin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		FillInCCDNumbersForTransferredGoodsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesUnderAgreement(Command)
	
	If Not ValueIsFilled(Object.Contract) Then
		ShowMessageBox(, NStr("vi = 'Trong chứng từ chưa chỉ ra hợp đồng với người nhận ký gửi. Không thể điền đơn giá.';
								|ru = 'В документе не указан договор с комиссионером. Цены не могут быть заполнены.';
								|en = 'The contract with a consignee is not specified in the document. Prices cannot be filled in.'; fa = 'The contract with a consignee is not specified in the document. Prices cannot be filled in.';
								|it = 'Nel documento non è indicato l''accordo con il commissionario. I prezzi non possono essere compilati.';
								|pl = 'Dokument nie zawiera kontraktu z komisantem. Ceny nie mogą byś wypełnione.';
								|tr = 'Belge, konsinye ile yapılan sözleşmeyi göstermemektedir. Fiyatlar doldurulamaz.'"));
	Else
		ContractOnChangeServer();
		
		If ValueIsFilled(NewKindOfPrice) Then
			Object.PriceKind = NewKindOfPrice;
			PricesCalculated = FillInPricesByPriceKindServer();
			SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		Else
			ShowMessageBox(,NStr("vi = 'Trong hợp đồng chưa chỉ ra dạng giá kế toán. Không thể điền đơn giá.';
								|ru = 'В договоре не указан учетный вид цен. Цены не могут быть заполнены.';
								|en = 'The accounting price type is not specified in the contract. Prices cannot be filled in.'; fa = 'The accounting price type is not specified in the contract. Prices cannot be filled in.';
								|it = 'Nell''accordo non è indicato il tipo di prezzo di contabilità. I prezzi non possono essere compilati.';
								|pl = 'Kontrakt nie zawiera ewidencyjnego rodzaju cen. Ceny nie mogą być wypełnione.';
								|tr = 'Sözleşmede fiyatların muhasebe türü belirtilmemiştir. Fiyatlar doldurulamaz.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UnlinkFromOrder(Command)

	SelectedRows = Items.Goods.SelectedRows;
	
	If SelectedRows.Count() > 0 Then
		UnlinkFromOrderServer(False);
		NotifyAboutEndOfUnbindingLines(SelectedRows.Count());
	Else
		WarningText = NStr("vi = 'Hãy chọn dòng cần bỏ liên kết với lệnh.';
							|ru = 'Выберите строки, которые необходимо отвязать от распоряжения.';
							|en = 'Select lines which should be unlinked from the reference.'; fa = 'Select lines which should be unlinked from the reference.';
							|it = 'Select lines which should be unlinked from the reference.';
							|pl = 'Select lines which should be unlinked from the reference.';
							|tr = 'Siparişlerden çıkarılması gereken satırları seçin.'");
		ShowMessageBox(Undefined, WarningText);
	EndIf;

EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure DateOnChangeServer()
	
	HowToSetSeriesVisibility();
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	ShipmentWithDeferredTransferOfTitle25 = ThisIsWriteOffOfShippedItemsToCustomer(Object.BusinessOperation);
	
	Object.Partner    = PredefinedValue("Catalog.Partners.EmptyRef");
	Object.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
	Object.Terms = PredefinedValue("Catalog.TermsOfSale.EmptyRef");
	
	PartnerOnChangeServer();
	CounterpartyOnChangeServer();
	ContractOnChangeServer();
	SetAvailabilityViewPrices(Object.SourseOfInformationAboutPricesForPrinting);
	
	If ConsignmentSales25
		Or ShipmentWithDeferredTransferOfTitle25 Then
		
		Object.SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByPriceType;
		
	EndIf;
	
	SourseOfInformationAboutPricesForPrintingOnChangeServer();
	
	Handler = Documents.WriteOffOfShippedGoods.ActionHandler(Object.BusinessOperation);
	
	ContractBusinessTransaction = Handler.ContractBusinessTransaction();
	
	Handler.AdjustItemSelectionSettings(ThisObject, Object);
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	SetVisibilityOfElementsByOperationServer();
	SetAvailabilityViewPrices(Object.SourseOfInformationAboutPricesForPrinting);
	UpdateInformationOnOrders();
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ValueToFormAttribute(DocumentSales, "Object");
	
	Terms = Object.Terms;
	If ValueIsFilled(Object.Terms) Then
		DocumentCurrency = Object.Currency;
	EndIf;
	
	Handler = Documents.WriteOffOfShippedGoods.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	WarehouseOnChangeServer(False, True);
	FillInServiceDetailsForProductRange();
	FillInCurrencyAndNewPriceTypeForContractAgreement();
	FillInPriceTypes();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
			Object.Contract);
		SetLBEditingOption();
	EndIf;
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	Handler = Documents.WriteOffOfShippedGoods.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	FillInPriceTypes();
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	Terms = Object.Terms;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement();
	ValueToFormAttribute(DocumentSales, "Object");
	
	Handler = Documents.WriteOffOfShippedGoods.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
	EndIf;
	
	WarehouseOnChangeServer(False, True);
	FillInServiceDetailsForProductRange();
	FillInPriceTypes();
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	FillInCurrencyAndNewPriceTypeForContractAgreement();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
				Object.Contract);
		EndIf;
	EndIf;
	
	Handler = Documents.WriteOffOfShippedGoods.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	FillInPriceTypes();
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtClient
Procedure ContractOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Object.Contract = Contract;
		Return;
	EndIf;
	
	ClearLines =
		Result = "Continue";
	
	UnbindLines =
		Result = "Unlink";
		
	ContractOnChangeServer(ClearLines, UnbindLines);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer(ClearLines = False, UnbindLines = False)
	
	Contract = Object.Contract;
	
	If ClearLines Then
		
		Object.ReferenceOrder = Undefined;
		Object.Goods.Clear();
		
	ElsIf UnbindLines Then
		
		UnlinkFromOrderServer(True, False);
		
	EndIf;
	
	UpdateInformationOnOrders();
	UpdateDependentDetailsOfServerByOrderForm();
	
	ContractDetails_ = New Structure("Currency, LineOfBusiness, Department", "ARAPCurrency");
	Catalogs.CounterpartyContracts.FillInDocumentDetails(Object, Object.Contract, ContractDetails_);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		SetLBEditingOption();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	FillInCurrencyAndNewPriceTypeForContractAgreement();
	FillInPriceTypes();
	
EndProcedure

&AtServer
Procedure SourseOfInformationAboutPricesForPrintingOnChangeServer()
	
	SourseOfInformationAboutPricesForPrinting = Object.SourseOfInformationAboutPricesForPrinting;
	
	SetPriceViewValue(SourseOfInformationAboutPricesForPrinting);
	SetAvailabilityViewPrices(SourseOfInformationAboutPricesForPrinting);
	FillInPriceTypes();
	
EndProcedure

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Object.PriceKind = AdditionalParameters;
		PricesCalculated = FillInPricesByPriceKindServer();
		OriginalPriceView = Object.PriceKind;
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, AdditionalParameters);
	ElsIf Not Object.PriceKind = OriginalPriceView Then
		Object.PriceKind = OriginalPriceView;
	EndIf;
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(ClearLines_ = True, UntieAllLinesFromOrder = False)
	
	If Not ShipmentWithDeferredTransferOfTitle25 Then
		Return;
	EndIf;
	
	Warehouse       = Object.Warehouse;
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	
	SetParametersForSelectingProductsWarehouse();
	
	If ClearLines_
		And Not WarehouseGroup_
		And Object.Goods.Count() > 0 Then
		
		Object.Goods.Clear();
		
	EndIf;
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True);
	
	If UntieAllLinesFromOrder Then
		UnlinkFromOrderServer();
	EndIf;
	
	UpdateInformationOnOrders();
	WhenChangingWarehouseInTablePartServer();
	HowToSetSeriesVisibility();
	
	Items.GroupLabelAndPictureSeveralWarehouses.Visible = WarehouseGroup_;
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingProductsWarehouse()
	
	GoodsWarehouse                 = Items.GoodsWarehouse;
	ParameterValue           = WarehouseSelectionData(Object.Warehouse);
	GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	TMCommonUseClientServer.AddSelectionParameter(GoodsWarehouse, "Ref", ParameterValue);
	
EndProcedure

&AtServerNoContext
Function WarehouseSelectionData(Warehouse)
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY(&GroupOfWarehouses)
	|	AND Warehouses.IsFolder = FALSE
	|	AND Warehouses.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices)";
	
	Query.SetParameter("GroupOfWarehouses", Warehouse);
	
	WarehouseTable = Query.Execute().Unload();
	WarehouseArray  = WarehouseTable.UnloadColumn("Ref");
	
	Return WarehouseArray;
	
EndFunction

&AtServer
Procedure UnlinkFromOrderServer(AllRows = True, UntieOnlyStrings = True)
	
	Var CachedValues;
	
	If Not ShipmentWithDeferredTransferOfTitle25 Then
		Return;
	EndIf;
	
	If AllRows Then
		RowsCollection = Object.Goods;
	Else
		RowsCollection = Items.Goods.SelectedRows;
	EndIf;
	
	For Each CurRow In RowsCollection Do
		
		If AllRows Then
			TableRow = CurRow;
			CurRow = TableRow.GetID();
		Else
			TableRow = Object.Goods.FindByID(CurRow);
		EndIf;
		
		ProductsClientServer.UpdateCachedValuesToAccountForSeries(
			TableRow,
			CachedValues,
			SeriesSpecificationParameters);
		
		TableRow.RowCode = 0;
		TableRow.Purpose = Undefined;
		
		If UntieOnlyStrings Then
			TableRow.OrderDiscrepancy_3 = 1;
		Else
			TableRow.ReferenceOrder = Undefined;
		EndIf;
		
		// Reassign the series lines
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			Object,
			SeriesSpecificationParameters,
			CurRow,
			CachedValues);
		
	EndDo;
	
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

&AtServer
Procedure UpdateOrderDeviations()
	
	If Not ShipmentWithDeferredTransferOfTitle25 Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.Goods,
		StructureOfActions,
		Undefined);
	
EndProcedure

&AtServer
Procedure UpdateDependentDetailsOfServerByOrderForm()
	
	If Not ShipmentWithDeferredTransferOfTitle25 Then
		Return;
	EndIf;
	
	If Object.Goods.Count() = 0 Then
		
		DiscrepancyOrderText = "";
		
		Items.GroupDiscrepancyOnOrder.Visible = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
		
		Return;
		
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText,
		ShipmentWithDeferredTransferOfTitle25);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDependentDetailsOfOrderForm_(FormItems, Goods, DiscrepancyOrderText,
	ShipmentWithDeferredTransferOfTitle25)

	If Not ShipmentWithDeferredTransferOfTitle25 Then
		Return;
	EndIf;
	
	NumberOfDiscrepancies = Goods.Total("OrderDiscrepancy_3");
	
	FormItems.GroupDiscrepancyOnOrder.Visible = NumberOfDiscrepancies > 0;
	FormItems.GroupDiscrepancyOnOrders.Visible = NumberOfDiscrepancies > 0;
	
	If NumberOfDiscrepancies > 0 Then
		DiscrepancyOrderText = NStr("vi = 'Dòng trên lệnh: %NumberOfDiscrepancies%';
									|ru = 'Строк сверх распоряжения: %NumberOfDiscrepancies%';
									|en = 'Lines beyond reference: %NumberOfDiscrepancies%'; fa = 'Lines beyond reference: %NumberOfDiscrepancies%';
									|it = 'Righe oltre la disposizione: %NumberOfDiscrepancies%';
									|pl = 'Wierszy ponad zamówienia: %NumberOfDiscrepancies%';
									|tr = 'Talimatların üzerindeki satırlar: %NumberOfDiscrepancies%'");
		DiscrepancyOrderText = StrReplace(DiscrepancyOrderText, "%NumberOfDiscrepancies%", NumberOfDiscrepancies);
	Else
		DiscrepancyOrderText = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	If Not ShipmentWithDeferredTransferOfTitle25 Then
		Return;
	EndIf;
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_, False);
	
	TotalWarehouses_ = WarehouseTable.Count();
	
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses,
		TotalWarehouses_);
	
EndProcedure

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure GoodsWarehouseWhenChangingQuestionToUserCompletion(Result,
																		AdditionalParameters) Export
	
	If Not Result Then
		
		WhenChangingWarehouseInTablePartServer();
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	If AdditionalParameters.LineDetachedFromOrder Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
			StructureOfActions);
	EndIf;
	If ShipmentWithDeferredTransferOfTitle25 Then
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
	UpdateDependentDetailsOfOrderForm_(
		Items,
		Object.Goods,
		DiscrepancyOrderText,
		ShipmentWithDeferredTransferOfTitle25);
	
EndProcedure

&AtClient
Procedure QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow)
	
	// If the current line is not related to the order.
	If CurrentRow.RowCode = 0 Then
		RunCallback(CallbackDescription, True);
		
		Return;
	EndIf;
	
	// If none of the key details have changed.
	If CurrentRow.Products = PreviousRowDetails.Products
		And CurrentRow.Characteristic = PreviousRowDetails.Characteristic
		And CurrentRow.Warehouse = PreviousRowDetails.Warehouse Then
		
		RunCallback(CallbackDescription, True);
		
		Return;
		
	EndIf;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	AdditionalParameters.CallbackDescription = CallbackDescription;
	
	IssueNotification = New CallbackDescription(
		"QuestionToUserWhenChangingDetailsOfLineQuestionCompletion", ThisObject, AdditionalParameters);
	
	QueryText = NStr("vi = 'Dòng đang chỉnh sửa sẽ không còn liên kết với dòng trong lệnh. Tiếp tục?';
					|ru = 'Редактируемая строка перестанет быть связанной со строкой распоряжения. Продолжить?';
					|en = 'The edited line will be unlinked from the reference line. Continue?'; fa = 'The edited line will be unlinked from the reference line. Continue?';
					|it = 'The edited line will be unlinked from the reference line. Continue?';
					|pl = 'The edited line will be unlinked from the reference line. Continue?';
					|tr = 'Düzenlenecek satır artık sipariş satırına bağlı olmayacaktır. Devam edilsin mi?'");
	
	ShowQueryBox(IssueNotification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// Question to the user when changing the details of the line question completion.
// 
// Parameters:
//	Response - DialogReturnCode
//	AdditionalParameters - Structure - 
&AtClient
Procedure QuestionToUserWhenChangingDetailsOfLineQuestionCompletion(Response, AdditionalParameters) Export
	
	CurrentRow      = AdditionalParameters.CurrentRow;
	CallbackDescription = AdditionalParameters.CallbackDescription;
	
	// If the user has confirmed the change in the value of the key details.
	If Response = DialogReturnCode.Yes Then
		CurrentRow.RowCode = 0;
		AdditionalParameters.LineDetachedFromOrder = True;
		RunCallback(CallbackDescription, True);
	Else
		// If the user refused to change the linked string, we return the old values.
		FillPropertyValues(CurrentRow, PreviousRowDetails);
		RunCallback(CallbackDescription, False);
	EndIf;
	
EndProcedure

// Goods nomenclature when changing the question to the user completion.
// 
// Parameters:
//	Result - Boolean
//	AdditionalParameters - Structure - 
&AtClient
Procedure GoodsNomenclatureWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result
		And ShipmentInExcessOfOrder Then
		
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	GoodsProductsOnChangeClient(CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChangeClient(CurrentRow)

	FillInArticleAttribute                  = New Structure("Products", "SKU");
	FillInProductTypeAttribute_          = New Structure("Products", "ItemsType");
	FillInCCDTrackingAttribute         = New Structure("Products", "TheRecordsAreKeptByCCD");
	CheckSeriesCalculateStatus           = New Structure("Warehouse, SeriesSpecificationParameters",
																CurrentRow.Warehouse, SeriesSpecificationParameters);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName", FormName, "Goods");
	CountryOfOriginFillingParameters   = BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters();
	
	StructureOfActions = New Structure;

	StructureOfActions.Insert("FillInArticleAttribute",            FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",    FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",     CheckSeriesCalculateStatus);
	StructureOfActions.Insert("FillInCCDTrackingAttribute",   FillInCCDTrackingAttribute);
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct", CountryOfOriginFillingParameters);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
	If ConsignmentSales25 And ValueIsFilled(Object.PriceKind) Then
		PricesCalculated = FillInPricesByPriceKindServer(CurrentRow.GetID());
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	EndIf;
	
	FillPropertyValues(PreviousRowDetails, CurrentRow);

EndProcedure

// Goods characteristic when changing the question to the user completion.
// 
// Parameters:
//	Result - Boolean
//	AdditionalParameters - Structure -
//
&AtClient
Procedure GoodsCharacteristicWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result
		And ShipmentInExcessOfOrder Then
		
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	GoodsCharacteristicOnChangeClient(CurrentRow);

EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChangeClient(CurrentRow)
		
	CharacteristicOnChangeOverridable = New Structure("FormName, TabularSectionName", FormName, "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", CharacteristicOnChangeOverridable);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		CachedValues);
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties





#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	
	If ShipmentWithDeferredTransferOfTitle25 Then 
		ArrayOfProductTypes = CommonClientServer.ValueInArray(Enums.ItemsTypes.OwnGoods);
		FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
	Else
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	EndIf;
	
	Columns = "Products,Characteristic,Count,CCDNumber";
	If ShipmentWithDeferredTransferOfTitle25 Then 
		Columns = Columns + ",Warehouse,Sum,AmountIncludingVAT";
	EndIf;
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	If TableOfGoods.Columns.Find("AmountIncludingVAT") <> Undefined Then
		
		If TableOfGoods.Columns.Find("Sum") <> Undefined Then
			TableOfGoods.Columns.Delete("Sum");
		EndIf;
		
		TableColumn2 = TableOfGoods.Columns.AmountIncludingVAT; // ValueTableColumn
		TableColumn2.Name = "Sum";
		
	EndIf;
	
	StructureOfActions    = New Structure;
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	If ShipmentWithDeferredTransferOfTitle25 Then
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
		StructureOfActions.Insert("RecalculatePriceByAmount", "Count");
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText, ShipmentWithDeferredTransferOfTitle25);
	
EndProcedure

#EndRegion

#Region InventoryKinds

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes = InventoriesServer.OptionsForEditingInventoryTypes();
	OptionsForEditingInventoryTypes.StorageLocationInTabularPart = False;
	OptionsForEditingInventoryTypes.Warehouse = Object.Contract;
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject, OptionsForEditingInventoryTypes);
	
EndFunction

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure SelectionProcessingSelectionOfTransferredGoods(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	CollapseGTDNumbers = False;
	CollapseGTDNumbers = Object.BusinessOperation = Enums.BusinessTransactions.GoodsWriteOffAtToller;
	For Each RowOfProduct In TableOfGoods Do
		
		ProductsSearch = New Structure();
		ProductsSearch.Insert("Products", RowOfProduct.Products);
		ProductsSearch.Insert("Characteristic", RowOfProduct.Characteristic);
		ProductsSearch.Insert("Purpose", RowOfProduct.Purpose);
		If Not CollapseGTDNumbers Then
			ProductsSearch.Insert("CCDNumber", RowOfProduct.CCDNumber);
		EndIf;
		ProductsSearch.Insert("Series", RowOfProduct.Series);
		ProductLines_2 = Object.Goods.FindRows(ProductsSearch);
		
		If ProductLines_2.Count() = 0 Then
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
		ElsIf ProductLines_2.Count() = 1 Then
			CurrentRow = ProductLines_2[0];
		ElsIf ProductLines_2.Count() > 1 Then
			For Each RowToDelete In ProductLines_2 Do
				Object.Goods.Delete(RowToDelete);
			EndDo;
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
		EndIf;
		
		CurrentRow.Count = RowOfProduct.QuantityIsSelected;
		
		If ShipmentWithDeferredTransferOfTitle25 And ValueIsFilled(Object.ReferenceOrder) Then
			CurrentRow.ReferenceOrder = Object.ReferenceOrder;
		EndIf;
		
		If ConsignmentSales25
			And ValueIsFilled(Object.PriceKind) Then
			
			FillInPricesByPriceKindServer(CurrentRow.GetID());
			
		EndIf;
		
	EndDo;
	
	WhenChangingWarehouseInTablePartServer();
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

&AtServer
Function PlaceGoodsInStorageForSelectionOfTransferredGoods()
	
	Address = PutToTempStorage(
		Object.Goods.Unload(,"LineNumber, Products, Characteristic, Purpose, CCDNumber, Series, Count"),
		UUID);
	
	Return Address;
	
EndFunction

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	GroupColumns = "Products, ItemsType, Characteristic, ItemVariantsAreUsed, Series, 
						|BatchesIndicationStatus";
	
	UnloadedColumns = GroupColumns + ", Count";
	
	TabularPartProducts = Object.Goods.Unload(, UnloadedColumns);
	TabularPartProducts.GroupBy(GroupColumns, "Count");
	TabularPartProducts.Columns.Add("NumberOfPackages");
	
	For Each TSRow In TabularPartProducts Do
		TSRow.NumberOfPackages = TSRow.Count;
	EndDo;
	
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable   = GetFromTempStorage(ReturnParameters.Goods);
	RowsToProcess = New Array;
	LinesToDelete = New Array;
	
	SelectionColumns = "Products, Characteristic, Series, BatchesIndicationStatus";
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure(SelectionColumns);
		FillPropertyValues(Filter, SourceRow);
		
		FoundRows = Object.Goods.FindRows(Filter);
		
		For Each TSRow In FoundRows Do
			
			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If TSRow.Count = 0
				And SourceRow.NumberOfPackages < 0 Then
				
				Continue;
				
			EndIf;
			
			If SourceRow.NumberOfPackages >= 0 Then
				
				TSRow.Count       = TSRow.Count + SourceRow.NumberOfPackages;
				SourceRow.NumberOfPackages = 0;
				
			Else
				
				QuantityToWriteOff = -SourceRow.NumberOfPackages;
				QuantityPerLine   = TSRow.Count;
				
				If QuantityToWriteOff > QuantityPerLine Then
					SourceRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
					TSRow.Count               = 0;
				Else
					SourceRow.NumberOfPackages = 0;
					TSRow.Count               = QuantityPerLine - QuantityToWriteOff;
				EndIf;
				
			EndIf;
			
			If TSRow.Count = 0 Then
				LinesToDelete.Add(TSRow);
			Else
				RowsToProcess.Add(TSRow);
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			
			TSRow.Count = SourceRow.NumberOfPackages;
			RowsToProcess.Add(TSRow);
		EndIf;
		
	EndDo;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	If ShipmentWithDeferredTransferOfTitle25 Then
		OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText, ShipmentWithDeferredTransferOfTitle25);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function SeriesSpecificationParameters()
	
	ObjectManager = Documents.WriteOffOfShippedGoods;
	
	Return New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, ObjectManager));
	
EndFunction

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsSpecifySeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible               = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,
																				SeriesSpecificationParameters,
																				Text,
																				CurrentData);
	
	If NeedServerCall Then
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		AdditionalParameters     = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
		CallbackDescription          = New CallbackDescription("OpenSelectionOfSeriesCompletion",
																ThisObject,
																AdditionalParameters);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName, ParametersOfSeriesIndicationForm, ThisObject, , , , CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ProcessSeriesIndication_Server(AdditionalParameters.ParametersOfSeriesIndicationForm);
	EndIf;
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object,
															SeriesSpecificationParameters,
															CurDataId,
															ThisObject);
	
EndFunction

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,
																						SeriesSpecificationParameters,
																						IDCurrentRow,
																						CachedValues);
	
EndProcedure

&AtServer
Procedure HowToSetSeriesVisibility()
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
EndProcedure

#EndRegion

#Region CCDNumbers

&AtClient
Procedure ProcessSelectionOfCCDNumber(CalculationResult1)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	RowID = CurrentData.GetID();
	
	If RowID = Undefined Then
		Return;
	EndIf;
	
	CCDNumbersFilledIn = False;
	CCDNumber = Undefined;
	
	ProcessIndicationOfCCDNumberServer(RowID, CalculationResult1, CCDNumbersFilledIn, CCDNumber);
	
	PurchasesClient.NotifyAboutFillingInGTNumbersInTabularPart(CCDNumbersFilledIn, CCDNumber);
	
EndProcedure

&AtServer
Procedure ProcessIndicationOfCCDNumberServer(RowID,
											CalculationResult1,
											CCDNumbersFilledIn,
											CCDNumber)
	
	SelectionData_1	= GetFromTempStorage(CalculationResult1.AddressInTempStorage);
	CCDNumber		= ?(SelectionData_1.ResidualNumberOfCCD <> Undefined,
						CCDNumber,
						SelectionData_1.MainNumberOfCCD);
	
	PickingParameters = PurchasesServer.CCDNumberSelectionParameters();
	PickingParameters.FieldNameNumberOfPackages = "Count";
	
	ProcessingActions = New Structure;
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		ProcessingActions.Insert("RecalculateAmount", "Count");
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												PickingParameters,
												ProcessingActions);
	
EndProcedure

&AtClient
Procedure ProcessAnswerToQuestionAboutFillingInCCDNumbers(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInCCDNumbersForTransferredGoodsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCCDNumbersForTransferredGoodsOnServer()
	
	FillParameters = PurchasesServer.ParametersForFillingInCCDNumbersBasedOnCredentials();
	QueryOptions = FillParameters.QueryOptions;
	
	PeriodDate_	= EndOfDay(CurrentSessionDate());
	Period		= New Boundary(PeriodDate_, BoundaryType.Including);
	
	RequestParametersToFillIn = "Organization, Contract, Ref";
	FillPropertyValues(QueryOptions, Object, RequestParametersToFillIn);
	
	QueryOptions.Period = Period;
	
	DataAcquisitionOption = ?(
		ShipmentWithDeferredTransferOfTitle25,
		"ByBalanceOnWay",
		"KeeperSLeftovers");
	
	PurchasesServer.FillInCCDNumbersAccordingToCredentials(Object.Goods, DataAcquisitionOption, FillParameters);
	
EndProcedure

#EndRegion

#Region Other

#Region References

&AtClient
Procedure CustomerSChoice(ValueSelected, Var_Parameters) Export
	
	If ValueSelected <> Undefined Then
		Modified  = True;
		
		If Object.Goods.Count() > 0 Then
			NotificationParameters = New Structure("ValueSelected", ValueSelected);
			CallbackDescription  = New CallbackDescription("CustomerSChoiceCompletion",
															ThisObject,
															NotificationParameters);
			
			QueryText = NStr("vi = 'Các dòng trong danh sách Hàng hóa sẽ được điền lại theo lệnh đã chọn. Tiếp tục?';
							|ru = 'Строки в списке Товары будут перезаполнены по выбранному распоряжению. Продолжить?';
							|en = 'This will re-populate rows in the Item list based on the selected references. Continue?'; fa = 'This will re-populate rows in the Item list based on the selected references. Continue?';
							|it = 'Le righe nell''elenco Merci verranno ricompilate in base alla disposizione selezionata. Continuare?';
							|pl = 'Wiersze na liście Wiersze pozycji zostaną wypełnione ponownie zgodnie z wybranym zaówieniem. Kontynuować?';
							|tr = 'Ürünler listesindeki satırlar seçilen sipariş tarafından yeniden doldurulacaktır. Devam edilsin mi?'");
			
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Else
			FillInByOrderServer(ValueSelected);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomerSChoiceCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Object.Goods.Clear();
	FillInByOrderServer(AdditionalParameters.ValueSelected);
	
EndProcedure

&AtServer
Procedure PresentationOfOrderServer()
	
	AddChangeOrderCommand = AccessRight("Update", Metadata.Documents.WriteOffOfShippedGoods);
	
	LinkOrder = "<a href='Open_Order'>%1</a>";
	InscriptionOrder = "‹%1›";
	LinkToChangeOrder = "<a href='SelectReference'>%2</a>";
	ReferencesArrray = New Array;
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		
		ReferencesArrray.Add(LinkOrder);
		OrderHeader = String(Object.ReferenceOrder);
		
	Else
		
		ReferencesArrray.Add(InscriptionOrder);
		OrderHeader = NStr("ru = 'не выбрано';
							|vi = 'not selected';
							|en = 'not selected'; fa = 'not selected';
							|it = 'не выбрано';
							|pl = 'not selected';
							|tr = 'seçilmedi'");
		
	EndIf;
	
	CommandTitle = Undefined;
	If AddChangeOrderCommand Then
		
		ReferencesArrray.Add(LinkToChangeOrder);
		
		If ValueIsFilled(Object.ReferenceOrder) Then
			CommandTitle = NStr("vi = 'Thay đổi';
								|ru = 'Изменить';
								|en = 'Edit'; fa = 'ویرایش';
								|it = 'Edit';
								|pl = 'Edit';
								|tr = 'Değiştir'");
		Else
			CommandTitle = NStr("vi = 'Chọn';
								|ru = 'Выбрать';
								|en = 'Select'; fa = 'انتخاب';
								|it = 'Выбрать';
								|pl = 'Select';
								|tr = 'Seç'");
		EndIf;
		
	EndIf;
	
	ReferenceOrderPresentation = StringFunctions.FormattedString(
		StrConcat(ReferencesArrray, " "),
		OrderHeader,
		CommandTitle);
	
EndProcedure

&AtServer
Procedure FillInByOrderServer(ReferenceOrder)
	
	If Not ValueIsFilled(ReferenceOrder) Then
		Return;
	EndIf;
	
	Object.ReferenceOrder = ReferenceOrder;
	
	InvoiceManager = Documents.WriteOffOfShippedGoods;
	
	HeaderAttributes = InvoiceManager.HeaderAttributes();
	FillPropertyValues(HeaderAttributes, Object);
	
	GoodsTable = Object.Goods.Unload();
	
	AnArrayOfOrders = CommonClientServer.ValueInArray(ReferenceOrder);
	
	FillParameters = InvoiceManager.DocumentFillingParameters();
	InvoiceManager.InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders);
	
	InvoiceManager.FillInByOrdersOrders(GoodsTable, Object.Ref, FillParameters);
	
	TableColumn2 = GoodsTable.Columns.Count; // ValueTableColumn
	TableColumn2.Name = "QuantityBeforeChange_";
	
	TableColumn2 = GoodsTable.Columns.QuantityInOrder; // ValueTableColumn
	TableColumn2.Name = "Count";
	
	Object.Goods.Load(GoodsTable);
	
	If Object.Goods.Count() > 0 Then
		If TypeOf(Object.ReferenceOrder) = Type("DocumentRef.SourceDocument") Then
			
			WarehouseTS = Undefined;
			For Each TSRow In Object.Goods Do
				
				If ValueIsFilled(TSRow.Warehouse) Then
					WarehouseTS = TSRow.Warehouse;
					Break;
				EndIf;
				
			EndDo;
			
			If ValueIsFilled(WarehouseTS) Then
				Object.Warehouse = WarehouseTS;
			EndIf;
			
		Else
			Object.Warehouse = Common.ObjectAttributeValue(Object.ReferenceOrder, "Warehouse");
		EndIf;
	EndIf;
	
	WarehouseOnChangeServer(False, False);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

&AtServer
Procedure UpdateInformationOnOrders()
	
	If Not ShipmentWithDeferredTransferOfTitle25 Then
		
		Object.ReferenceOrder = Undefined;
		
		For Each TSRow In Object.Goods Do
			TSRow.ReferenceOrder = Undefined;
		EndDo;
		
		ListOfOrders_.Clear();
		
		Return;
	EndIf;
	
	Items.Pages_Order.Visible = True;
	Items.Pages_Order.Enabled = True;
	
	ListOfOrders_.Clear();
	InAllRowsThereIsOrder = True;
	For Each CurRow In Object.Goods Do
		If ValueIsFilled(CurRow.ReferenceOrder) Then
			If  ListOfOrders_.FindByValue(CurRow.ReferenceOrder) = Undefined Then
				ListOfOrders_.Add(CurRow.ReferenceOrder);
			EndIf;
		Else
			InAllRowsThereIsOrder = False;
		EndIf;
	EndDo;
	
	If ListOfOrders_.Count() = 1 And InAllRowsThereIsOrder Then
		Object.ReferenceOrder = ListOfOrders_[0].Value;
	ElsIf ListOfOrders_.Count() > 1
		Or Not InAllRowsThereIsOrder Then
		Object.ReferenceOrder = Undefined;
	EndIf;
	
	If ListOfOrders_.Count() > 1 Then
		LabelTotalOrders = NStr("vi = 'Tổng số chứng từ';
								|ru = 'Всего документов';
								|en = 'Total documents'; fa = 'Total documents';
								|it = 'Total documents';
								|pl = 'Total documents';
								|tr = 'Belgelerin tümü'");
		InscriptionIsTitleOfOrders = LabelTotalOrders + ": " + ListOfOrders_.Count();
	EndIf;
	
	If ListOfOrders_.Count() <= 1 Then
		Items.Pages_Order.CurrentPage = Items.Page_Order;
		PresentationOfOrderServer();
	Else
		Items.Pages_Order.CurrentPage = Items.PageOfOrder;
		Items.PageOfOrder.Enabled = True;
	EndIf;
	
	If ValueIsFilled(Object.ReferenceOrder) Or Not UseWriteOffForMultipleOrders Then
		Items.GoodsGroupReference.Group = ColumnsGroup.Vertical;
	Else
		Items.GoodsGroupReference.Group = ColumnsGroup.InCell;
	EndIf;
	
	SetPropertiesToReduceShipmentByOrder();
	
EndProcedure

&AtServer
Procedure SetPropertiesToReduceShipmentByOrder()
	
	ReceiptAgainstOrder = False;
	
	For Each ReferenceOrder In ListOfOrders_ Do
		If TypeOf(ReferenceOrder.Value) <> Type("DocumentRef.SourceDocument")
			And TypeOf(ReferenceOrder.Value) <> Type("DocumentRef.GoodsShipmentToCustomer") Then
			ReceiptAgainstOrder = True;
			
			Break;
		EndIf;
	EndDo;
	
	If Not ReceiptAgainstOrder And Object.ReduceShipmentByReference Then 
		Object.ReduceShipmentByReference = False;
	EndIf;
	
	Items.ReduceShipmentByReference.Enabled = ReceiptAgainstOrder;
	
EndProcedure

&AtClient
Procedure OpenOrderSelection(CallbackDescription)

	NamesOfDocumentDetails =
		"Ref,
		|Partner,
		|Counterparty,
		|Terms,
		|Organization,
		|Contract,
		|SalesOpportunity,
		|Warehouse,
		|Department,
		|LineOfBusiness,
		|Currency
		|";
		
	FormParameters = New Structure(NamesOfDocumentDetails);
	FillPropertyValues(FormParameters, Object);

	OpenForm("Document.WriteOffOfShippedGoods.Form.ReferenceChoiceForm",
	    FormParameters,
	    ThisObject,
	    ,
	    ,
	    ,
	    CallbackDescription,
	    FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure OpenSelectionByOrders()
	
	AttributesNames =
		"Currency,
		|Contract,
		|Counterparty,
		|LineOfBusiness,
		|Organization,
		|Partner,
		|Department,
		|SalesOpportunity,
		|Warehouse,
		|Terms,
		|Ref,
		|BusinessOperation
		|";

	HeaderAttributes = New Structure(AttributesNames);
	FillPropertyValues(HeaderAttributes, Object);
	
	FormParameters = New Structure;
	FormParameters.Insert("HeaderAttributes",                           HeaderAttributes);
	FormParameters.Insert("Invoice",                                Object.Ref);
	FormParameters.Insert("OrdersAreUsed",                       True);
	FormParameters.Insert("InvoiceForOrders",                       True);
	FormParameters.Insert("OrderDocument",                                    Object.ReferenceOrder);
	FormParameters.Insert("AdvancedWarehousingOnShipment",                 False);
	FormParameters.Insert("AdvancedWarehousingOnGoodsReceipt",              False);
	FormParameters.Insert("AddressGoods",                              AddressInvoiceGoods());
	FormParameters.Insert("UseInvoicesForSeveralOrders", UseWriteOffForMultipleOrders);
	
	OpenForm("CommonForm.AddItemsFromSalesOrderGoodsIssue",
		FormParameters,
		ThisObject,
		UUID,
		,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtServer
Function AddressInvoiceGoods()
	
	ColumnDescriptionNumberOfPackages = New TypeDescription("Number",
		New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	
	Table = Object.Goods.Unload(); // ValueTable -
	Table.Columns.Add("NumberOfPackages", ColumnDescriptionNumberOfPackages);
	
	ColumnValuesQuantity = Table.UnloadColumn("Count");
	Table.LoadColumn(ColumnValuesQuantity, "NumberOfPackages");
	
	AddressInTempStorage = PutToTempStorage(Table, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtClient
Procedure SelectReferenceCompletion(Result, AdditionalParameters) Export
	
	Items.Goods.CurrentData.ReferenceOrder = Result;
	
	UpdateInformationOnOrders();
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(AddressInStorage)
	
	FieldsNames = "RowCode, CCDNumber, "
		+ Documents.WriteOffOfShippedGoods.KeyFieldsOfGoodsTable();
	
	Table = GetFromTempStorage(AddressInStorage).Goods; // ValueTable -
	Table.Sort(FieldsNames + " Desc");
	
	Table.Columns.Delete("Count");
	Table.Columns["NumberOfPackages"].Name = "Count";
	
	RowsRecalculateAmount = New Array;
	
	// Grouping a table by row keys.
	StringTree = New Array;
		
	For Each TableRow In Table Do
		
		If TableRow.QuantityInOrder <> TableRow.Count Then
			RowsRecalculateAmount.Add(TableRow);
		EndIf;
		
		RowsArray = New Array;
		RowsArray.Add(TableRow);
		
		StringTree.Add(RowsArray);
		
	EndDo;
	
	ActionsToRecalculateAmount = New Structure("RecalculateAmount", "Count");
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsRecalculateAmount, ActionsToRecalculateAmount, Table);
	
	InvoicesServer.FillInProductsSelectedFromOrder(StringTree, FieldsNames, Object.Goods, New Structure);
	
	UpdateInformationOnOrders();
	UpdateOrderDeviations();
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	WhenChangingWarehouseInTablePartServer();
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText, ShipmentWithDeferredTransferOfTitle25);
	
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	LinesOfBusinessServer.ReFillInServiceDetailsOfTablePart(ThisObject);
	
EndProcedure

#EndRegion

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Setting the conditional design for the 'Warehouse' element
	WarehousesServer.SetConditionalAppearanceOfWarehouseInHeader(ThisObject);
	
	// Setting the conditional design for the items of the nomenclature of the tabular part 'Goods'
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, True);
	
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	// Setting the conditional design for the elements 'NomerGTD' and 'Country of origin' of the tabular part 'Goods'
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOriginCountry.Name);
	
	TypesOfGoods = New ValueList;
	TypesOfGoods.Add(Enums.ItemsTypes.OwnGoods);
	TypesOfGoods.Add(Enums.ItemsTypes.ReusablePackage);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = TypesOfGoods;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<ürünler için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOriginCountry.Name);
	
	ProcessorOperations = New ValueList;
	ProcessorOperations.Add(Enums.BusinessTransactions.GoodsWriteOffAtToller);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ProcessorOperations;
	
	Item.Appearance.SetParameterValue("Visible", False);
	// Setting a conditional layout for the 'Price' and 'Amount' elements of the 'Goods' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShipmentWithDeferredTransferOfTitle25");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeviationFromShipmentConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShipmentWithDeferredTransferOfTitle25"); 
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Setting the conditional design of the order submission element
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferenceOrderPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ResultIssueColor);
	
	// Setting the conditional design for the 'Order' element of the 'Goods' tabular part

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseWriteOffForMultipleOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShipmentWithDeferredTransferOfTitle25");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa chọn lệnh';
													|ru = 'Распоряжение не выбрано';
													|en = 'The reference is not selected'; fa = 'The reference is not selected';
													|it = 'The reference is not selected';
													|pl = 'The reference is not selected';
													|tr = 'Sipariş seçilmemiş'"));
	
	// Setting the conditional design for the 'Division' element
	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisObject);
	
	// Setting the conditional design for the 'Activity Direction' element
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	// Setting the conditional design for the type of prices
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject, "PriceKind", "Object.PriceKind");
	
	// Setting the conditional design for the 'Warehouse' element of the 'Goods' tabular part
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShipmentWithDeferredTransferOfTitle25");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetLBEditingOption()
	
	LBAvailabilityParameters = LinesOfBusinessServer.ParametersLBEditingCapability();
	
	LBAvailabilityParameters.Contract           = Object.Contract;
	LBAvailabilityParameters.ARAPObjectSettings   = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	
	LinesOfBusinessServer.SetLBEditingOption(ThisObject, LBAvailabilityParameters);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UseLinesOfBusiness      = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	ToUseTermsOfSales         = GetFunctionalOption("ToUseTermsOfSales");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	UseWriteOffForMultipleOrders =
		GetFunctionalOption("UseSaleByMultipleOrders");

	ShipmentWithDeferredTransferOfTitle25 = ThisIsWriteOffOfShippedItemsToCustomer(Object.BusinessOperation);
	ShipmentInExcessOfOrder                     = UserRightsCached.SalesInExcessOfOrder();
	DeviationFromShipmentConditions             = UserRightsCached.VarianceFromSalesTermsAndConditions();
	
	Documents.WriteOffOfShippedGoods.ConfigureBusinessTransactionDetails(ThisObject, Object);
	
	Handler = Documents.WriteOffOfShippedGoods.ActionHandler(Object.BusinessOperation);
	Handler.SetContractAvailability(ThisObject, Object);
	
	Handler.AdjustItemSelectionSettings(ThisObject, Object);
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	
	ContractBusinessTransaction    = Handler.ContractBusinessTransaction();
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	ConsignmentSales25 =
		Object.BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense;
	DocumentCurrency       = Object.Currency;
	Warehouse                 = Object.Warehouse;
	WarehouseGroup_           = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	Contract               = Object.Contract;
	Terms            = Object.Terms;
	
	Items.GroupLabelAndPictureSeveralWarehouses.Visible   = WarehouseGroup_;
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	FillInPriceTypes();
	UpdateDependentDetailsOfServerByOrderForm();
	UpdateInformationOnOrders();
	UpdateOrderDeviations();
	SetVisibilityOfSeriesElements();
	FillInServiceDetailsForProductRange();
	SetVisibilityOfElementsByOperationServer();
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	SetAvailabilityViewPrices(Object.SourseOfInformationAboutPricesForPrinting);
	SetParametersForSelectingProductsWarehouse();
	
	WhenChangingWarehouseInTablePartServer();
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	OriginalPriceView = Object.PriceKind;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInArticleAttribute                    = New Structure("Products", "SKU");
	FillInProductTypeAttribute_            = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	FillInCCDTrackingAttribute           = New Structure("Products", "TheRecordsAreKeptByCCD");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",          FillInArticleAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",  FillInProductTypeAttribute_);
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											FillInFeatureAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute", FillInCCDTrackingAttribute);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	Handler = Documents.WriteOffOfShippedGoods.ActionHandler(Object.BusinessOperation);
	DefaultContract = Handler.GetDefaultContract(Object);
	
	If Object.Contract <> DefaultContract Then
		Object.Contract = DefaultContract;
	EndIf;
	
	FillInCurrencyAndNewPriceTypeForContractAgreement();
	
EndProcedure

&AtServer
Procedure SetPriceViewValue(SourseOfInformationAboutPricesForPrinting)
	
	If SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByPriceType Then
		Object.PriceKind = Catalogs.TypesOfPrices.DefaultPriceType(Object.PriceKind, GetParametersForSelectingPriceType());
	ElsIf SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost Then
		Object.PriceKind = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityViewPrices(SourseOfInformationAboutPricesForPrinting)
	
	ConsignmentSales25 = Object.BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense;
	
	If ConsignmentSales25
		And SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByPriceType Then
		Items.SourseOfInformationAboutPricesForPrinting.Visible = False;
	Else
		Items.SourseOfInformationAboutPricesForPrinting.Visible = True;
	EndIf;
		
	If SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByPriceType Then
		Items.PriceKind.Enabled = True;
	ElsIf SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost Then
		Items.PriceKind.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	EndIf;
	
	UpdateDependentDetailsOfServerByOrderForm();
	UpdateInformationOnOrders();
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.WriteOffOfShippedGoods.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);

	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
	Items.Totals1Group.Visible = Items.GoodsSum.Visible;
	
EndProcedure

&AtServer
Function FillInPricesByPriceKindServer(RowID = Undefined)
	
	If RowID = Undefined Then
		RowsArray = Undefined;
	Else
		RowsArray = New Array;
		RowsArray.Add(Object.Goods.FindByID(RowID));
	EndIf;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray, True);
	
	ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	
	FillParameters = New Structure();
	FillParameters.Insert("Date",                      Object.Date);
	FillParameters.Insert("Partner",                   Object.Partner);
	FillParameters.Insert("PriceKind",                   Object.PriceKind);
	FillParameters.Insert("Organization",               Object.Organization);
	FillParameters.Insert("Currency",                    Object.Currency);
	FillParameters.Insert("PopulationFields",            "Price, Sum");
	FillParameters.Insert("ColumnsByValue",         ColumnsByValue);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure FillInPriceTypes()
	
	If Object.SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByPriceType Then
		SelectionParametersPriceType = New Array;
		SelectionParametersPriceType.Add(New ChoiceParameter("OutputAnArbitraryTypeOfPrices", True));
		SelectionParametersPriceType.Add(New ChoiceParameter("Filter.Status",               Enums.StatusesOfPriceTypeValidity.Valid));
		SelectionParametersPriceType.Add(New ChoiceParameter("UseWhileSellingToCustomers",     True));
		SelectionParametersPriceType.Add(New ChoiceParameter("Filter.IsFolder",            False));
		SelectionParametersPriceType.Add(New ChoiceParameter("Filter.DeletionMark",      False));
		
		If Object.BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense Then
			SelectionParametersPriceType.Add(New ChoiceParameter("Filter.PriceCurrency", Object.Currency));
			
			If Not ReadOnly
				And ValueIsFilled(Object.PriceKind)
				And Common.ObjectAttributeValue(Object.PriceKind, "PriceCurrency") <> Object.Currency Then
				
				Object.PriceKind = Catalogs.TypesOfPrices.EmptyRef();
				
			EndIf;
		EndIf;
		
		Items.PriceKind.ChoiceParameters = New FixedArray(SelectionParametersPriceType);
		
		If Not ReadOnly
			And ValueIsFilled(Object.PriceKind)
			And Not Common.ObjectAttributeValue(Object.PriceKind, "UseWhileSellingToCustomers") Then
			
			Object.PriceKind = Catalogs.TypesOfPrices.EmptyRef();
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function GetParametersForSelectingPriceType()
	
	PriceTypesSelectionParameters = New Structure;
	PriceTypesSelectionParameters.Insert("Status", Enums.StatusesOfPriceTypeValidity.Valid);
	PriceTypesSelectionParameters.Insert("UseWhileSellingToCustomers", True);
	PriceTypesSelectionParameters.Insert("IsFolder", False);
	PriceTypesSelectionParameters.Insert("DeletionMark", False);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense Then
		PriceTypesSelectionParameters.Insert("PriceCurrency", Object.Currency);
	EndIf;
	
	Return PriceTypesSelectionParameters;
	
EndFunction

&AtClientAtServerNoContext
Function ThisIsWriteOffOfShippedItemsToCustomer(BusinessOperation)
	
	Return BusinessOperation = PredefinedValue("Enum.BusinessTransactions.WriteOffOfShippedGoods");
	
EndFunction

&AtServerNoContext
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse)
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
EndFunction

&AtClient
Procedure NotifyAboutEndOfUnbindingLines(NumberOfLinesWorked, LinesWereUnlinked = True)

	If LinesWereUnlinked Then
		MessageText = NStr("vi = 'Các dòng liên quan';
							|ru = 'Строки отвязаны';
							|en = 'Lines were unlinked'; fa = 'Lines were unlinked';
							|it = 'Righe dissociate';
							|pl = 'Wierze odłączone';
							|tr = 'Satırlar çıkarıldı'");
		ExplanationText = NStr("vi = 'Trong chứng từ, có dòng (%Count%) bị bỏ liên kết với lệnh.';
								|ru = 'В документе от распоряжений отвязано строк (%Count%).';
								|en = 'In the document, the lines (%Count%) are unlinked from the references.'; fa = 'In the document, the lines (%Count%) are unlinked from the references.';
								|it = 'In the document, the lines (%Count%) are unlinked from the references.';
								|pl = 'In the document, the lines (%Count%) are unlinked from the references.';
								|tr = 'Belgede, siparişlerden ayrılmış bir satır mevcuttur (%Count%).'");
		ExplanationText = StrReplace(ExplanationText, "%Count%", NumberOfLinesWorked);
	Else
		MessageText = NStr("vi = 'Các dòng không liên quan';
							|ru = 'Строки не отвязаны';
							|en = 'Lines were not unlinked'; fa = 'Lines were not unlinked';
							|it = 'Righe non dissociate';
							|pl = 'Wierze nie odłączone';
							|tr = 'Satırlar çıkarılmadı'");
		ExplanationText = NStr("vi = 'Không có dòng nào liên quan.';
								|ru = 'Ни одна строка не была отвязана.';
								|en = 'No line was unlinked.'; fa = 'No line was unlinked.';
								|it = 'Nessuna riga è stata dissociata.';
								|pl = 'Nie odłączono ani jednego wiersza.';
								|tr = 'Herhangi bir satır çıkarılmadı.'");
	EndIf;
	
	ShowUserNotification(MessageText, , ExplanationText, PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * CurrentRow - FormDataCollectionItem, FormDataStructure, FormDataTreeItem - 
// * CallbackDescription - CallbackDescription - 
// * LineDetachedFromOrder - Boolean - 
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("CurrentRow", Undefined);
	Result.Insert("CallbackDescription", Undefined);
	Result.Insert("LineDetachedFromOrder", False);
	Return Result;
	
EndFunction

&AtServer
Procedure FillInCurrencyAndNewPriceTypeForContractAgreement()
	
	If ValueIsFilled(Object.Contract) 
		And Object.BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense Then
			ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "ARAPCurrency, PriceTypeAccountingPriceType");
			If Object.Currency <> ContractDetails_.ARAPCurrency Then
				OriginalPriceView = Catalogs.TypesOfPrices.EmptyRef();
				Object.Currency = ContractDetails_.ARAPCurrency;
			EndIf;
			NewKindOfPrice = ContractDetails_.PriceTypeAccountingPriceType;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtDepositorSExpense
		And ValueIsFilled(Object.Terms) Then
		NewKindOfPrice = Common.ObjectAttributeValue(Object.Terms,"PricesKind");
	Else
		NewKindOfPrice = OriginalPriceView;
	EndIf;
	
EndProcedure

&AtClient
Procedure AskQuestionWhenChangingPriceType()
	
	If ConsignmentSales25
		And ValueIsFilled(NewKindOfPrice)
		And Not OriginalPriceView = NewKindOfPrice
		And Object.SourseOfInformationAboutPricesForPrinting = PredefinedValue("Enum.SourcesOfPriceInformationForPrinting.ByPriceType") Then
		
		If Object.Goods.Count() > 0 Then
			CallbackDescription = New CallbackDescription("PriceKindOnChangeCompletion", ThisObject, NewKindOfPrice);
			
			QueryText = NStr("vi = 'Điền đơn giá theo dạng giá ""%PriceKind%""?';
							|ru = 'Заполнить цены по виду цен ""%PriceKind%""?';
							|en = 'Fill in prices by price type ""%PriceKind%""?'; fa = 'Fill in prices by price type ""%PriceKind%""?';
							|it = 'Compilare i prezzi per il tipo di prezzi ""%PriceKind%""?';
							|pl = 'Podaj ceny według rodzaju ceny ""%PriceKind%""?';
							|tr = 'Fiyatlar, ""%PriceKind%"" fiyat türüne göre doldurulsun mu?'");
			QueryText = StrReplace(QueryText, "%PriceKind%", NewKindOfPrice);
			
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		Else
			Object.PriceKind = NewKindOfPrice;
			OriginalPriceView = NewKindOfPrice;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Result = DialogReturnCode.No Then
		Object.Warehouse = Warehouse;
		Return;
	EndIf;
	
	WarehouseOnChangeServer(False, True);
	
EndProcedure

#Region StandardSubsystems_Properties

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

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

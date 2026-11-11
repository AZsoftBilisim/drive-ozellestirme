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

	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If Parameters.FillByWarehouseDocument 
		Or Parameters.FillingValues.Property("FillByWarehouseDocument") 
		Or (ValueIsFilled(Parameters.Basis) 
			And TypeOf(Parameters.Basis) = Type("Structure")
			And Parameters.Basis.Property("FillByWarehouseDocument")) 
		Then
		RefillByReceivingServer(False, True);
		Modified = True;
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	SetVisibility1();
	
	
	SetAvailabilityOfClipboardCommands();
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(SelectionResult);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, SelectionResult);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters,,True);
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_UninvoicedReceipt", WriteParameters, Object.Ref);
	
	DocumentCorrectionClient.AfterWrite(Object);
	

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetAvailabilityOfItemsByStatusServer();
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
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
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = Items.AdvancedGroup.Name
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	PurchasesClient.StartSelectingSupplierAgreement(
		Item,
		StandardProcessing,
		Object.Partner,
		Object.Terms,
		Object.Date);

EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		Object.Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
		PartnerClearingServer();
		Return;
	EndIf;
	
	WhenChangingPartnerServer();
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.Item = Item;
	
	QuestionUserBeforeFillingInAgreement(
		New CallbackDescription("PartnerWhenChangingQuestionEnds", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	                                                       
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	QuestionUserBeforeFillingInAgreement(
		New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	PurchasesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	WhenChangingAgreementServer(True, True);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	WhenBusinessTransactionChangesServer();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WhenChangingWarehouseServer(True);
	
EndProcedure

&AtClient
Procedure VendorPriceKindOnChange(Item)
	
	If Not ValueIsFilled(Object.VendorPriceKind) Then
		Return;
	EndIf;
	
	QueryText       = NStr("vi = 'Điền lại giá theo dạng giá?';
							|ru = 'Перезаполнить цены по виду цены?';
							|en = 'Refill prices by the price type?'; fa = 'Refill prices by the price type?';
							|it = 'Ricompilare i prezzi per tipo di prezzo?';
							|pl = 'Wypełnić ponownie wg rodzaju cen?';
							|tr = 'Fiyat türüne göre fiyatlar yeniden doldurulsun mu?'");
	CallbackDescription = New CallbackDescription("SupplierSPriceViewWhenQuestionChanges", ThisObject);
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True, NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Ricompilare';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False,   NStr("vi = 'Không điền lại';
									|ru = 'Не перезаполнять';
									|en = 'Do not refill'; fa = 'Do not refill';
									|it = 'Non ricompilare';
									|pl = 'Nie wypełniaj ponownie';
									|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(CallbackDescription, QueryText, AnswersOptions);
	
EndProcedure

&AtClient
Procedure SupplierSPriceViewWhenQuestionChanges(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer <> Undefined
		And UserAnswer Then
		
		FillInPricesBySupplierPriceType();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Not SelectedOperationWithoutPrices(Object.BusinessOperation) Then
		Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
	Else
		DateOnChangeServer(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	FillInSubordinatePropertiesForStatistics("Manager");
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure VATActivityTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If Not ValueIsFilled(DocumentCurrency) Then
		DocumentCurrency = Object.Currency;
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = DocumentCurrency;
		Return;
	EndIf;
	
	If DocumentCurrency <> Object.Currency
		And Object.Goods.Total("Price") > 0 Then
		
		MessageText = NStr("vi = 'Tính lại số tiền trong chứng từ theo nguyên tệ ""%Currency%""?';
							|ru = 'Пересчитать суммы в документе в валюту ""%Currency%""?';
							|en = 'Convert amounts in the document in %Currency%?'; fa = 'Convert amounts in the document in %Currency%?';
							|it = 'Ricalcolare gli importi del documento in valuta ""%Currency%""?';
							|pl = 'Przeliczyć kwoty w dokumencie na walutę ""%Currency%""?';
							|tr = 'Belgedeki tutarlar ""%Currency%"" para birimine göre yeniden hesaplansın mı?'");
		MessageText = StrReplace(MessageText, "%Currency%", Object.Currency);
		
		Notification = New CallbackDescription("RecalculateAmountsWhenChangingCurrency", ThisObject);
		ShowQueryBox(Notification, MessageText, QuestionDialogMode.YesNo);
	Else
		DocumentCurrency = Object.Currency;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReferenceOrderPresentationURLProcessing(Item,
																FormattedStringURL,
																StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "Open_Order" Then
		ShowValue(, Object.ReferenceOrder)
	Else
		
		// &PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement("Document.ReceiptOfGoodsToWarehouse.Form.SelectReference");
		
		OrderSelectionFormParameters = New Structure;
		OrderSelectionFormParameters.Insert("Partner",				Object.Partner);
		OrderSelectionFormParameters.Insert("Counterparty",				Object.Counterparty);
		OrderSelectionFormParameters.Insert("Terms",				Object.Terms);
		OrderSelectionFormParameters.Insert("BusinessOperation",	Object.BusinessOperation);
		OrderSelectionFormParameters.Insert("Organization",			Object.Organization);
		OrderSelectionFormParameters.Insert("Contract",				Object.Contract);
		OrderSelectionFormParameters.Insert("Warehouse",					Object.Warehouse);
		
		CallbackDescription = New CallbackDescription("CustomerSChoice", ThisObject);
		
		OpenForm("Document.ReceiptOfGoodsToWarehouse.Form.SelectReference",
					OrderSelectionFormParameters,
					ThisObject,
					,
					,
					,
					CallbackDescription,
					FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure StructuralUnitOnChange(Item)
	
	UpdateTypeOfVATActivity();
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)

	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters, True);

	If SeriesStatusesNeedToBeUpdated Then

		GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues); // server call

	EndIf;

	If SeriesStatusesNeedToBeUpdated Then

		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters);

	EndIf;

EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item, CachedValues, SeriesSpecificationParameters, Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.Goods.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.Goods.CurrentData <> Undefined Then
		
		PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts", NStr("vi = 'Nhà cung cấp';
																										|ru = 'Поставщик';
																										|en = 'Vendor'; fa = 'تأمین‌کننده';
																										|it = 'Fornitore';
																										|pl = 'Dostawca';
																										|tr = 'Tedarikçi'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	ItemBeforePartnerItemChanges = CurrentRow.Products;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If CurrentRow.Products <> ItemBeforePartnerItemChanges Then
		StructureOfActions = New Structure;
		
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("SeriesSpecificationParameters, Warehouse", SeriesSpecificationParameters, Object.Warehouse));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * CurrentRow - FormDataCollectionItem - 
// * Item - FormGroup, FormTable, FormField, FormButton - Form element
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("CurrentRow");
	Result.Insert("Item");
	Return Result;
	
EndFunction

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;

	RunCallback(
		New CallbackDescription(
			"GoodsCharacteristicWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters), 
		True);
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	SpecifiedVATRate = CurrentRow.VATRate;

EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
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

&AtServer
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)

	If SeriesStatusesNeedToBeUpdated Then

		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);

	EndIf;

EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = Items.GoodsPartnerProducts.Name Then
		
		CurrentData = Items.Goods.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.GoodsPartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.GoodsPartnerProducts.ChoiceParameters, CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);

EndProcedure

&AtClient
Procedure GoodsToControlQualityOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

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
Procedure FillThePricesByTermsOfSales(Command)

	TabularSectionName           = "Goods";
	TabularSectionPresentation = NStr("vi = 'Hàng hóa';
										|ru = 'Товары';
										|en = 'Goods'; fa = 'کالاها';
										|it = 'Merci';
										|pl = 'Wiersze pozycji';
										|tr = 'Ürünler'");
	
	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, TabularSectionName, TabularSectionPresentation) Then
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(, ErrorText);
		
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ReceiptOfGoodsToWarehouse.DocumentForm.Command.SelectGoods");
	
	Cancel = False;
	
	OperationWithoutPrices = SelectedOperationWithoutPrices(Object.BusinessOperation);
	
	If Not OperationWithoutPrices
		And Not ValueIsFilled(Object.Currency) Then
		
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
		
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	FilterByProductType = New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",                Object.Ref);
	FormParameters.Insert("Date",                    Object.Date);
	FormParameters.Insert("Partner",                 Object.Partner);
	FormParameters.Insert("Terms",              Object.Terms);
	If Not OperationWithoutPrices Then
		FormParameters.Insert("Currency",              Object.Currency);
		FormParameters.Insert("PriceIncludesVAT",     Object.PriceIncludesVAT);
	EndIf;
	FormParameters.Insert("FilterByProductType", FilterByProductType);
	FormParameters.Insert("HideTheViewPriceColumn",  OperationWithoutPrices);
	FormParameters.Insert("HideTheItemPricesCommand",   OperationWithoutPrices);
	FormParameters.Insert("SelectionModeWithoutAmountParameters", OperationWithoutPrices);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", False);
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure FillInThePricesForReceipts(Command)
	
	If Not ValueIsFilled(Object.Partner) Then
		Raise NStr("vi = 'Để điền đơn giá theo những lần tiếp nhận gần nhất, cần chỉ ra nhà cung cấp';
					|ru = 'Для заполнения цен по последним поступлениям необходимо указать поставщика';
					|en = 'To fill in the prices for the latest receipts, specify the vendor'; fa = 'To fill in the prices for the latest receipts, specify the vendor';
					|it = 'Per ricompilare i prezzi in base agli ultimi arrivi, è necessario specificare il fornitore';
					|pl = 'Aby wypełnić ceny za ostatnie wpływy, należy określić dostawcę';
					|tr = 'Son tedariklerin fiyatlarını doldurmak için tedarikçi belirtilmelidir'");
	EndIf;
	
	PricesAreFilledOut = False;
	FillInPricesForLatestReceipts(PricesAreFilledOut);
	
	If PricesAreFilledOut Then
		ShowUserNotification(
			NStr("vi = 'Đã điền đơn giá';
				|ru = 'Цены заполнены';
				|en = 'Prices are filled out'; fa = 'Prices are filled out';
				|it = 'I prezzi sono compilati';
				|pl = 'Wypełniono ceny';
				|tr = 'Fiyatlar dolduruldu'"),
			,
			NStr("vi = 'Trong các dòng của chứng từ có điền đơn giá';
				|ru = 'В строках документа заполнены цены';
				|en = 'Prices are populated in the document lines'; fa = 'Prices are populated in the document lines';
				|it = 'Nelle righe del documento sono compilati i prezzi';
				|pl = 'W wierszach dokumentu wypełniono ceny';
				|tr = 'Belgedeki satırlar fiyatlarla doldurulmuştur'"),
			PictureLib.Information32);
	Else
		ShowUserNotification(
			NStr("vi = 'Chưa điền đơn giá';
				|ru = 'Цены не заполнены';
				|en = 'Prices are not filled in'; fa = 'Prices are not filled in';
				|it = 'I prezzi non sono compilati';
				|pl = 'Nie wypełniono ceny';
				|tr = 'Fiyatlar doldurulmadı'"),
			,
			NStr("vi = 'Chưa điền đơn giá vào dòng nào';
				|ru = 'Ни в одной строке цена не заполнена';
				|en = 'No lines have prices filled in'; fa = 'No lines have prices filled in';
				|it = 'Il prezzo non è compilato in alcuna riga';
				|pl = 'W żadnym wierszu nie wypełniono ceny';
				|tr = 'Hiçbir satırda fiyat doldurulmamıştır'"),
			PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
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
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	

	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		If ValueIsFilled(Object.Ref) Then
			Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Items[Parameter]);
		Else
			ContractOnChange(Items[Parameter]);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure ShowSupplierProducts(Command)
	
	PartnersProductsClient.ShowThePartnerSNomenclature(Object.Partner, Object.Ref, Items.Goods.CurrentData, NStr("vi = 'Nhà cung cấp';
																												|ru = 'Поставщик';
																												|en = 'Vendor'; fa = 'تأمین‌کننده';
																												|it = 'Fornitore';
																												|pl = 'Vendor';
																												|tr = 'Tedarikçi'"));
	
EndProcedure

&AtClient
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisForm);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow),
		UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult.Result Then
		ProcessBarcodes(ExecutionResult.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeTheQualityOfTheItem(Command)
	
	CurrentRow = Items.Goods.CurrentData;
	ClearMessages();
	If CurrentRow = Undefined Then
		MessageText = NStr("vi = 'Hãy chọn dòng của phần bảng';
							|ru = 'Выберите строку табличной части';
							|en = 'Select a table row'; fa = 'Select a table row';
							|it = 'Selezionare una riga della parte tabulare';
							|pl = 'Wybierz wiersz części tabelarycznej';
							|tr = 'Tablo bölümündeki satırı seçin'");
		CommonClientServer.MessageToUser(MessageText);
		Return
	EndIf;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckPackagingByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	If ValueIsFilled(CurrentRow.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentRow.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentRow.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
	EndIf;	
		
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
	SeriesVerificationParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	SeriesVerificationParameters.Warehouse = Object.Warehouse;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SplitTheFactString(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitTheFactStringCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItem(Command)
	
	If Not TMCommonUseClient.CheckForRowsInList(Object.Goods, "Goods") Then
		Return;
	EndIf;
	
	GoodsAddressInStorage = PlaceGoodsInTemporaryStorageServer("Goods");
	PurchasesClient.OpenSupplierProductListForm(
		New CallbackDescription("FillInTheItemByThePartnerSItemCompletion", ThisObject),
		GoodsAddressInStorage,
		ThisForm);
	
EndProcedure

&AtClient
Procedure FillInSeriesAccordingToDataOfReceiptOfGoodsAndServices(Command)
	
	FillingResult = FillInSeriesAccordingToDataPTiYOnServer();
	
	ProductsClient.NotifyAboutReFillingSeries(FillingResult.HasChanges, FillingResult.NumberIsInitiallyCorrect);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItemCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		FillInItemsFromTemporaryStorageServer(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",            PutTablePartOfGoodsInTemporaryStorageToCheckQuantity());
	OpeningParameters.Insert("TabularSectionName",                    "Goods");
	OpeningParameters.Insert("Ref",                               Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", True);
	OpeningParameters.Insert("SeriesSpecificationParameters",               SeriesSpecificationParameters);
	OpeningParameters.Insert("Terms",                           Object.Terms);
	
	ReturnParameters = Undefined;

	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters,,,,, New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
    
    ReturnParameters = Result;
    
    If ReturnParameters <> Undefined Then
        
        ChangeTablePartBasedOnResultsOfCheck(
			ReturnParameters, 
			?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
        Modified = True;
        
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
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer("Goods");
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.FillInThePartnerSNomenclature = Object.Partner;
	ImportParameters.ImportPrices  = True;
	ImportParameters.ImportAmounts = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ImportParameters.FilterParameters.Insert("ItemsType", ArrayOfProductTypes);
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject, "Goods");
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice(Command)
	
	FillInPricesBySupplierPriceType(True);
	
EndProcedure

&AtClient
Procedure RefillByReceiving(Command)
	
	ClearMessages();
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.ReferenceOrder) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Lệnh""';
							|ru = 'Поле ""Распоряжение"" не заполнено';
							|en = '""Reference"" is required'; fa = '""Reference"" is required';
							|it = 'Il campo ""Disposizione"" non è compilato';
							|pl = 'Pole ""Zamówienie"" nie jest wypełnione';
							|tr = '""Sipariş"" alanı doldurulmadı'");
		
		CommonClient.MessageToUser(MessageText, Object.ReferenceOrder, "Object.ReferenceOrder", , Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Warehouse) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Kho bãi""';
							|ru = 'Поле ""Склад"" не заполнено';
							|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
							|it = 'Il campo ""Magazzino"" non è compilato';
							|pl = 'Nie wypełniono pola ""Magazyn""';
							|tr = '""Ambar"" alanı doldurulmamış'");
		
		CommonClient.MessageToUser(MessageText, Object.Warehouse, "Object.Warehouse", , Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	ThereAreAcceptedGoods	= False;
	HasChanges		= RefillByReceivingServer(ThereAreAcceptedGoods);
	
	PurchasesClient.NotifyAboutEndOfReplenishmentOfGoodsForAcceptance(HasChanges, ThereAreAcceptedGoods);
	
	If HasChanges Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Mallar"" listesine hiçbir satır girilmemiştir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

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

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure GoodsCharacteristicWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure FirstChoiceServer(ValueSelected)
	
	PropertiesToExclude = "";
	
	If TypeOf(ValueSelected.ReferenceOrder) = Type("CatalogRef.CounterpartyContracts") Then
		PropertiesToExclude = "Warehouse, Currency";
	EndIf;
	
	FillPropertyValues(Object, ValueSelected, , PropertiesToExclude);
	
	DisposalWarehouses = DisposalWarehouses(True);
	
	If ValueSelected.ThisIsWarehouseGroup
		And ValueIsFilled(Object.Warehouse)
		And DisposalWarehouses.Find(Object.Warehouse) = Undefined Then
		
		Object.Warehouse = Catalogs.Warehouses.EmptyRef();
		
	EndIf;
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	WhenBusinessTransactionChangesServer(False);
	WhenChangingAgreementServer(False);
	ShowOrderPresentation();
	SetParametersForSelectingWarehouseProps(DisposalWarehouses);
	
	If TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		PurchasesServer.SetContractAvailability(Object,
													Items.Contract.Enabled,
													Items.Contract.Visible,
													Object.Contract);
	EndIf;
	
	If TypeOf(Object.ReferenceOrder) = Type("DocumentRef.VendorInvoice") Then
		FillInUsingInvoice = True;
	Else
		FillInUsingInvoice = False;
	EndIf;
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations(False);
	EconomicOperationOfAcceptance = PairsOfSeparatePurchaseOperations.Get(Object.BusinessOperation);
	
	FillingData = New Structure();
	FillingData.Insert("DocumentBasis", Object.ReferenceOrder);
	FillingData.Insert("Warehouse", Object.Warehouse);
	FillingData.Insert("FillInUsingInvoice", FillInUsingInvoice);
	FillingData.Insert("EconomicOperationOfAcceptance", EconomicOperationOfAcceptance);
	
	Object.Goods.Clear();
	
	Value = FormDataToValue(Object, Type("DocumentObject.ReceiptOfGoodsToWarehouse"));
	Value.Fill(FillingData);
	ValueToFormData(Value, Object);
	
	DocumentCurrency = Object.Currency;
	Warehouse = Object.Warehouse;
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReceiptOfGoodsToWarehouse));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetVisibility1();
	
	CalculateTotals_(ThisForm);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract();
		
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	PurchasesServer.SetContractAvailability(
		Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	FillInVATTaxationPurchases();
	UpdateTypeOfVATActivity();
	
	ClearOrder();
	ClearWarehouseFieldSelectionParameters();
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Object.ReferenceOrder, Object.Contract);
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsToWarehouse,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
	EndIf;
	
	PurchasesServer.SetContractAvailability(
		Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	FillInVATTaxationPurchases();
	UpdateTypeOfVATActivity();
	
	ClearOrder();
	ClearWarehouseFieldSelectionParameters();
	
	ResponsiblePersonsServer.InstallManager(Object, Object.ReferenceOrder);
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Object.ReferenceOrder, Object.Contract);
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsToWarehouse,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AgreementWhenChangingQuestionCompletion(UserAnswer, AdditionalParameters) Export
	
	RecalculatePrices_2 = ValueIsFilled(Object.Terms)
						And Object.Goods.Count() > 0
						And UserAnswer;
	
	WhenChangingAgreementAtServer(RecalculatePrices_2);
	
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomerSChoice(ValueSelected, Var_Parameters) Export
	
	If ValueSelected <> Undefined Then
		Modified = True;
		
		If Object.Goods.Count() > 0 Then
			QueryText = NStr("vi = 'Các dòng trong danh sách Hàng hóa sẽ được điền lại theo lệnh đã chọn. Tiếp tục?';
							|ru = 'Строки в списке Товары будут перезаполнены по выбранному распоряжению. Продолжить?';
							|en = 'This will re-populate rows in the Item list based on the selected references. Continue?'; fa = 'This will re-populate rows in the Item list based on the selected references. Continue?';
							|it = 'Le righe nell''elenco Merci verranno ricompilate in base alla disposizione selezionata. Continuare?';
							|pl = 'Wiersze na liście Wiersze pozycji zostaną wypełnione ponownie zgodnie z wybranym zaówieniem. Kontynuować?';
							|tr = 'Ürünler listesindeki satırlar seçilen sipariş tarafından yeniden doldurulacaktır. Devam edilsin mi?'");
			ShowQueryBox(New CallbackDescription("CustomerSChoiceCompletion",
				ThisObject,
				New Structure("ValueSelected", ValueSelected)),
				QueryText,
				QuestionDialogMode.YesNo);
		Else
			FirstChoiceClientCallServer(ValueSelected);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomerSChoiceCompletion(QuestionResult, AdditionalParameters) Export
	
	ValueSelected = AdditionalParameters.ValueSelected;
	
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FirstChoiceClientCallServer(ValueSelected);
	
EndProcedure

&AtClient
Procedure FirstChoiceClientCallServer(ValueSelected)
	
	FirstChoiceServer(ValueSelected);
	
	If TypeOf(Object.ReferenceOrder) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		CallbackDescription = New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject);
		
		QuestionUserBeforeFillingInAgreement(CallbackDescription);
	EndIf;
	
EndProcedure

// Parameters:
// 	UserAnswer - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure PartnerWhenChangingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If ValueIsFilled(Object.Terms) Then
		If UserAnswer Then
			ErrorText = "";
			PricesCalculated = FillThePricesByTermsOfSalesServer(True, ErrorText);
			PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		EndIf;
		PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	EndIf;
	
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisForm, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn nhà cung cấp>';
													|ru = '<выберите поставщика>';
													|en = '<select vendor>'; fa = '<select vendor>';
													|it = '<selezionare il fornitore>';
													|pl = '<wybierz dostawcę>';
													|tr = '<tedarikçi seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisForm);
	
	//
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);

	//

	WarehousesServer.SetConditionalAppearanceOfWarehouseInHeader(ThisForm);

	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, False);

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferenceOrderPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ResultIssueColor);
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingPartnerServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentPurchases = FormAttributeToValue("Object");
	DocumentPurchases.FillInDefaultPurchaseConditions(False);
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	DocumentCurrency = Object.Currency;
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	WhenBusinessTransactionChangesServer(False);
	
	WhenChangingWarehouseServer();
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;

	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	PurchasesServer.SetContractAvailability(
		Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	ClearOrder();
	ClearWarehouseFieldSelectionParameters();
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.ReferenceOrder);
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Object.ReferenceOrder, Object.Contract);
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsToWarehouse,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerClearingServer()
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.ReferenceOrder);
	
EndProcedure

&AtServer
Procedure ClearOrder()
	
	If Not ValueIsFilled(Object.ReferenceOrder) Then
		Return;
	EndIf;
	
	AttributesNames = "Partner, Counterparty, BusinessOperation, Organization";
	
	If TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.TermsOfPurchaseFromVendors")
		And TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.CounterpartyContracts") Then
		
		AttributesNames = AttributesNames + ", Terms, Contract";
	
	EndIf;
	
	If TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.CounterpartyContracts") Then
		AttributesNames = AttributesNames + ", Warehouse";
	EndIf;
	
	DetailsOfOrder = Common.ObjectAttributesValues(Object.ReferenceOrder, AttributesNames);
	
	If Object.Partner <> DetailsOfOrder.Partner
			And ValueIsFilled(Object.Partner)
		
		Or Object.Counterparty <> DetailsOfOrder.Counterparty
			And ValueIsFilled(DetailsOfOrder.Counterparty)
			And ValueIsFilled(Object.Counterparty)
		
		Or Object.Organization <> DetailsOfOrder.Organization
			And ValueIsFilled(DetailsOfOrder.Organization)
			And ValueIsFilled(Object.Organization)
		
		Or DetailsOfOrder.Property("Warehouse")
			And Object.Warehouse <> DetailsOfOrder.Warehouse
			And ValueIsFilled(DetailsOfOrder.Warehouse)
			And ValueIsFilled(Object.Warehouse)
			And SettingsValueCached.FolderHierarchy(Object.Warehouse).Find(DetailsOfOrder.Warehouse) = Undefined Then
		
		Object.ReferenceOrder = Undefined;
		
	EndIf;
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		
		If TypeOf(Object.ReferenceOrder) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			
			BasicDisposalOperation = PurchasesServer.MainEconomicOperationOfSeparatePurchase(
												DetailsOfOrder.BusinessOperation);
			
			If (Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery
						Or Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit)
					And BasicDisposalOperation <> Enums.BusinessTransactions.ImportFromEAEU
					
				Or (Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery
						Or Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit)
					And BasicDisposalOperation <> Enums.BusinessTransactions.PurchaseFromSupplier
				
				Or Object.BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit
					And BasicDisposalOperation <> Enums.BusinessTransactions.PurchaseByImport Then
				
				Object.ReferenceOrder = Undefined;
				
			EndIf;
			
			If Object.Terms <> Object.ReferenceOrder Then
				Object.ReferenceOrder = Undefined;
			EndIf;
			
		ElsIf TypeOf(Object.ReferenceOrder) = Type("CatalogRef.CounterpartyContracts") Then
			
			PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations();
			
			If PairsOfSeparatePurchaseOperations.Get(Object.BusinessOperation) <> DetailsOfOrder.BusinessOperation Then
				Object.ReferenceOrder = Undefined;
			EndIf;
			
			If Object.Contract <> Object.ReferenceOrder Then
				Object.ReferenceOrder = Undefined;
			EndIf;
			
		Else
			
			If Object.Contract <> DetailsOfOrder.Contract
				And ValueIsFilled(Object.Contract)
				
				Or Object.Terms <> DetailsOfOrder.Terms
				And ValueIsFilled(DetailsOfOrder.Terms) Then
				
				Object.ReferenceOrder = Undefined;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ShowOrderPresentation();
	
EndProcedure

&AtServer
Procedure ClearWarehouseFieldSelectionParameters()
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		Return;
	EndIf;
	
	Items.Warehouse.ChoiceParameters = New FixedArray(New Array);
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(RecalculatePrices_2 = True)
	
	PriceIncludesVAT					= Object.PriceIncludesVAT;
	DirectionsOfActivity	= Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Terms) Then
		
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Object.Terms, True, True);
		
		DocumentPurchases = FormAttributeToValue("Object");
		DocumentPurchases.FillInTermsOfPurchase(PurchaseConditions);
		
		ValueToFormAttribute(DocumentPurchases, "Object");
		
		DocumentCurrency = Object.Currency;
		
		If RecalculatePrices_2 Then
			
			StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
			
			FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
			FillParameters.Insert("PopulationFields",		"Price, VATRate");
			FillParameters.Insert("Date",				Object.Date);
			FillParameters.Insert("Currency",				Object.Currency);
			FillParameters.Insert("Terms",			Object.Terms);
			FillParameters.Insert("VATTaxation",	Object.VATTaxation);
			FillParameters.Insert("Organization", Object.Organization);
			
			ActionsWithStrings = New Structure;
			ActionsWithStrings.Insert("RecalculateAmount",		"NumberOfPackages");
			ActionsWithStrings.Insert("RecalculateVATAmount",	StructureOfRecalculationOfAmount);
			ActionsWithStrings.Insert("RecalculateAmountWithVAT",	StructureOfRecalculationOfAmount);
			
			PartnerPricesFillingServer.FillInPrices(Object.Goods, Undefined, FillParameters, ActionsWithStrings);
			
		ElsIf PriceIncludesVAT <> Object.PriceIncludesVAT Then
			
			StructureOfRecalculationOfAmount = ParametersForRecalculatingNDSWTCHAmount(ThisForm);
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
			
			BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
			
		EndIf;
		
		WhenChangingWarehouseServer();
		
		BusinessTransactionBeforeTheChange = Object.BusinessOperation;
		WhenBusinessTransactionChangesServer(False);
		
		StructureOfNamesOfTableParts = New Structure("Goods");
		FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
		
	EndIf;
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;

	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ClearOrder();
	ClearWarehouseFieldSelectionParameters();
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Object.ReferenceOrder, Object.Contract);
	EndIf;
	
	CalculateTotals_(ThisForm);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.ReferenceOrder);
	
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsToWarehouse,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementServer(ClearingOrder, DirectModificationOfContractField = False)
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, 
			Object.Terms, Object.Contract);
		EndIf;
		
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	FillInVATTaxationPurchases();
	
	If ClearingOrder Then
		ClearOrder();
		ClearWarehouseFieldSelectionParameters();
	EndIf;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Object.ReferenceOrder, Object.Contract);
	EndIf;
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.ReferenceOrder);
	SetVisibility1();
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsToWarehouse,
			Object,
			CacheQualityControl,
			DirectModificationOfContractField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenBusinessTransactionChangesServer(ChallengeByCommand = True)
	
	If Object.BusinessOperation <> BusinessTransactionBeforeTheChange Then
		Object.Contract = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	FillInBusinessPartOfAgreement();
	
	If ChallengeByCommand Then
		
		If ValueIsFilled(Object.Terms)
			And ValueIsFilled(Object.BusinessOperation) Then
			
			AgreementOperation			= Common.ObjectAttributeValue(Object.Terms,
											"BusinessOperation");
			BasicDocumentOperation_	= PurchasesServer.MainEconomicOperationOfSeparatePurchase(
											Object.BusinessOperation);
			
			Object.Terms = ?(AgreementOperation = BasicDocumentOperation_,
									Object.Terms,
									Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
			
		EndIf;
		
		FillInDefaultContract();
		ClearOrder();
		ClearWarehouseFieldSelectionParameters();
		
	EndIf;
	
	SetVisibility1();
	
	FillInVATTaxationPurchases();
	UpdateTypeOfVATActivity();
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Object.ReferenceOrder, Object.Contract);
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsToWarehouse,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsToWarehouse,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseServer(DirectModificationOfWarehouseField = False)
	
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsToWarehouse,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	If Warehouse = Object.Warehouse Then
		
		Return;
		
	EndIf;
	Warehouse = Object.Warehouse;
	
	PrepareFillSetSeriesVisibility();
	UpdateTypeOfVATActivity();
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = ParametersForRecalculatingNDSWTCHAmount(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisForm);
	
EndProcedure

&AtServer
Function DateOnChangeServer(RecalculatePrices_2)
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	Else
		PricesCalculated = False;
	EndIf;
	
	FillInVATTaxationPurchases();
	UpdateTypeOfVATActivity();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	PrepareFillSetSeriesVisibility();
	If QualityControl.UpdateActionParameters(
			Documents.ReceiptOfGoodsToWarehouse,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure RecalculateAmountsWhenChangingCurrency(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		RecalculateAmountsWhenChangingCurrencyServer(CachedValues);
	EndIf;
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure RecalculateAmountsWhenChangingCurrencyServer(CachedValues)
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, DocumentDate, BaseCurrency);
	StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.Currency,  DocumentDate, BaseCurrency);
	
	For Each CurRow In Object.Goods Do
		CurRow.Price = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
			CurRow.Price,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates);
	EndDo;
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

#EndRegion

#Region PriceManagementSystem

&AtServer
Function FillThePricesByTermsOfSalesServer(OnAllLines = False, ErrorText = "")
	
	If Common.ObjectAttributeValue(Object.Terms, "PriceIncludesVAT") <> Object.PriceIncludesVAT Then
		ErrorText = 
		NStr("vi = 'Các giá trị đã đặt cho trường ""Đơn giá gồm thuế GTGT"" trong chứng từ và thỏa thuận là khác nhau.';
			|ru = 'Установленные значения полей ""Цена включает НДС"" в документе и соглашении разные.';
			|en = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.'; fa = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.';
			|it = 'I valori impostati dei campi ""Prezzo IVA inclusa"" nel documento e nell''accordo differiscono.';
			|pl = 'Ustawione wartości pól ""Cena brutto"" w dokumencie i umową są różne.';
			|tr = 'Belgedeki ve sözleşmedeki ""KDV dahildir"" alanlarının hesaplanan değerleri farklıdır.'");
		Return False;
	EndIf;

	If OnAllLines Then
		RowsArray = Undefined;
	Else
		RowsArray = New Array;
		
		For Each String In Items.Goods.SelectedRows Do
			RowsArray.Add(Object.Goods.FindByID(String));
		EndDo;
	EndIf;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields",     "Price");
	FillParameters.Insert("Date",               Object.Date);
	FillParameters.Insert("Currency",             Object.Currency);
	FillParameters.Insert("Terms",         Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("Organization", Object.Organization);
	
	ActionsWithStrings = New Structure;
		
	ActionsWithStrings.Insert("RecalculateAmount",     "NumberOfPackages");
	ActionsWithStrings.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	ActionsWithStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, ActionsWithStrings);
	
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure FillInPricesBySupplierPriceType(FillSelectedLines = False)
	
	TabularSectionName           = "Goods";
	TabularSectionPresentation = NStr("vi = 'Hàng hóa';
										|ru = 'Товары';
										|en = 'Goods'; fa = 'کالاها';
										|it = 'Merci';
										|pl = 'Wiersze pozycji';
										|tr = 'Ürünler'");
	
	FillInPrices = PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(Object, TabularSectionName,
		TabularSectionPresentation);
	
	If FillInPrices Then
		
		If Not ValueIsFilled(Object.VendorPriceKind) Then
			WarningText = NStr("vi = 'Chứng từ không chỉ ra dạng giá của nhà cung cấp. Không thể điền được giá.';
								|ru = 'В документе не указан вид цены поставщика. Цены не могут быть заполнены';
								|en = 'Vendor price type is not specified in the document. Prices cannot be filled in'; fa = 'Vendor price type is not specified in the document. Prices cannot be filled in';
								|it = 'Il documento non indica il tipo di prezzo del fornitore. I prezzi non possono essere compilati';
								|pl = 'W dokumencie nie podano rodzaj ceny dostawcy. Ceny nie mogą zostać wypełnione';
								|tr = 'Belgede tedarikçi fiyat türü belirtilmemiştir. Fiyatlar doldurulamaz'");
			
			ShowMessageBox(, WarningText);
		Else
			PricesCalculated = FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(FillSelectedLines);
			
			PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, Object.VendorPriceKind);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(FillSelectedLines)
	
	RowsArray = Undefined;
	
	If FillSelectedLines Then
		RowsArray = New Array;
		
		For Each String In Items.Goods.SelectedRows Do
			TableRow = Object.Goods.FindByID(String);
			RowsArray.Add(TableRow);
		EndDo;
	EndIf;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields",    "Price, VATRate");
	FillParameters.Insert("Date",              Object.Date);
	FillParameters.Insert("Currency",            Object.Currency);
	FillParameters.Insert("VendorPriceKind", Object.VendorPriceKind);
	FillParameters.Insert("Organization", Object.Organization);
	
	ActionsWithStrings = New Structure;
	ActionsWithStrings.Insert("RecalculateAmount",     "NumberOfPackages");
	ActionsWithStrings.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	ActionsWithStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, ActionsWithStrings);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure FillInPricesForLatestReceipts(PricesAreFilledOut)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SourceTable.LineNumber    AS LineNumber,
	|	SourceTable.Products   AS Products,
	|	SourceTable.Characteristic AS Characteristic,
	|	SourceTable.Package       AS Package
	|	
	|INTO GoodsTable
	|FROM
	|	&SourceTable AS SourceTable
	|	
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorInvoice.Ref.PointInTime AS PointInTime,
	|	VendorInvoice.Products         AS Products,
	|	VendorInvoice.Characteristic       AS Characteristic,
	|	VendorInvoice.Package             AS Package,
	|	VendorInvoice.VendorPriceKind    AS VendorPriceKind,
	|	VendorInvoice.Price                 AS Price,
	|	VendorInvoice.Ref.Currency        AS Currency
	|	
	|INTO RevenuePrices
	|FROM
	|	Document.VendorInvoice.Goods AS VendorInvoice
	|	
	|	INNER JOIN
	|		GoodsTable
	|	ON
	|		VendorInvoice.Products = GoodsTable.Products
	|		AND VendorInvoice.Characteristic = GoodsTable.Characteristic
	|WHERE
	|	VendorInvoice.Ref.Posted
	|	AND VendorInvoice.Ref.Partner = &Partner
	|	AND VendorInvoice.Ref.Date   <= &Date
	|	
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RevenuePrices.Products         AS Products,
	|	RevenuePrices.Characteristic       AS Characteristic,
	|	RevenuePrices.Package             AS Package,
	|	RevenuePrices.Price                 AS Price,
	|	RevenuePrices.VendorPriceKind    AS VendorPriceKind,
	|	RevenuePrices.Currency               AS Currency
	|	
	|INTO PricesOfRecentReceipts
	|FROM
	|	RevenuePrices AS RevenuePrices 
	|	
	|	LEFT JOIN 
	|		RevenuePrices AS Filter
	|	ON
	|		RevenuePrices.Products = Filter.Products
	|		AND RevenuePrices.Characteristic = Filter.Characteristic
	|		AND RevenuePrices.PointInTime < Filter.PointInTime
	|WHERE
	|	Filter.PointInTime IS NULL
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber    AS LineNumber,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Package       AS Package,
	|	PricesOfRecentReceipts.VendorPriceKind AS VendorPriceKind,
	|	CASE
	|		WHEN
	|			GoodsTable.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		THEN
	|			&QueryTextPackagingFactor1
	|		ELSE
	|			1
	|	END
	|	* PricesOfRecentReceipts.Price / ISNULL(&QueryTextPackagingFactor2, 1)
	|	* CASE
	|		WHEN &Currency <> PricesOfRecentReceipts.Currency
	|			THEN CASE
	|					WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|						AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN 
	|						(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|						/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END AS Price
	|FROM
	|	GoodsTable AS GoodsTable
	|	
	|	LEFT JOIN 
	|		PricesOfRecentReceipts AS PricesOfRecentReceipts
	|		
	|	ON 
	|		GoodsTable.Products = PricesOfRecentReceipts.Products
	|		AND GoodsTable.Characteristic = PricesOfRecentReceipts.Characteristic
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|	ON 
	|		PricesOfRecentReceipts.Currency = CurrencyRatesPrices.Currency
	|	
	|	LEFT JOIN 
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON
	|		TRUE";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"GoodsTable.Package",
			"GoodsTable.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PricesOfRecentReceipts.Package",
			"PricesOfRecentReceipts.Products"));
	
	Query.SetParameter("SourceTable", Object.Goods.Unload(,"LineNumber, Products, Characteristic, Package"));
	Query.SetParameter("Date", ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	Query.SetParameter("Currency", Object.Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	Query.SetParameter("Partner", Object.Partner);
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	RowsToProcess = New Array();
		
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		TSRow = Object.Goods[Selection.LineNumber - 1];
		TSRow.Price = Selection.Price;
		RowsToProcess.Add(TSRow);
		
		PricesAreFilledOut = True;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If Not ValueIsFilled(Object.Currency) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Tiền tệ""';
												|ru = 'Поле ""Валюта"" не заполнено';
												|en = '""Currency"" is required'; fa = '""Currency"" is required';
												|it = 'Il campo ""Valuta"" non è compilato';
												|pl = 'Pole ""Waluta"" nie jest wypełnione';
												|tr = '""Para Birimi"" alanı doldurulmadı'"), Object.Ref, "Object.Currency",,Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm, SeriesSpecificationParameters, Text, CurrentData)Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;

		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		ReturnValue_1 = Undefined;

		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
    EndIf;

EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActionsWithAddedStrings.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, ThisObject);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, ThisObject);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.GoodsOnly                           = True;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible               = SeriesSpecificationParameters.UseCostAccountingByBatches;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,StructureOfActions);

EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);
	
EndProcedure

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReceiptOfGoodsToWarehouse));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetVisibility1();
	
EndProcedure

&AtServer
Function FillInSeriesAccordingToDataPTiYOnServer()
	
	GoodsTable = Object.Goods.Unload();
	GoodsTable.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	GoodsTable.FillValues(Object.Warehouse, "Warehouse");
	
	ResultOfFillingInSeries = ProductsServer.FillOutSeriesBasedOnProductDataFromPartners(GoodsTable, Object, False);
	
	If ResultOfFillingInSeries.HasChanges Then
		StructureOfActions = New Structure();
		StructureOfActions.Insert(
			"RecalculateNumberOfPackages",
			BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
		BatchProcessingOfTablePartServer.TreatTS(GoodsTable, StructureOfActions, Undefined);
		
		Object.Goods.Load(ResultOfFillingInSeries.GoodsTable);
		
		ProductsServer.FillInSeriesByFEFO(Object, SeriesSpecificationParameters, False);
	EndIf;
	
	FillingResult = New Structure("HasChanges, NumberIsInitiallyCorrect");
	FillPropertyValues(FillingResult, ResultOfFillingInSeries);
	
	Return FillingResult;
	
EndFunction

#EndRegion

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = Items.Date.Name Then
		DateOnChange(Item);
	ElsIf Item.Name = Items.Partner.Name Then
		PartnerOnChange(Item);
	ElsIf Item.Name = Items.Terms.Name Then
		TermsOnChange(Item);
	ElsIf Item.Name = Items.Contract.Name Then
		ContractOnChange(Item);
	ElsIf Item.Name = Items.PriceIncludesVAT.Name Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = Items.VATTaxation.Name Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = Items.Organization.Name Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = Items.Counterparty.Name Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = Items.Warehouse.Name Then
		WarehouseOnChange(Item);
	ElsIf Item.Name = Items.GoodsPartnerProducts.Name Then
		GoodsPartnerProductsOnChange(Item);
	ElsIf Item.Name = Items.GoodsSeries.Name Then
		GoodsSeriesOnChange(Item);
	ElsIf Item.Name = Items.GoodsNumberOfPackages.Name Then
		GoodsNumberOfPackagesOnChange(Item);
	ElsIf Item.Name = Items.GoodsPackage.Name Then
		GoodsPackageOnChange(Item);
	ElsIf Item.Name = Items.GoodsPrice.Name Then
		GoodsPriceOnChange(Item);
	ElsIf Item.Name = Items.GoodsSum.Name Then
		GoodsSumOnChange(Item);
	ElsIf Item.Name = Items.GoodsVATRate.Name Then
		GoodsVATRateOnChange(Item);
	ElsIf Item.Name = Items.GoodsVATAmount.Name Then
		GoodsVATAmountOnChange(Item);
	ElsIf Item.Name = Items.GoodsToControlQuality.Name Then
		GoodsToControlQualityOnChange(Item);
	ElsIf Item.Name = Items.GoodsQualityConfirmationDate.Name Then
		GoodsQualityConfirmationDateOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	
	If Command.Name = Commands.SearchByBarcode.Name Then
		SearchByBarcodeExecute(Command);
	ElsIf Command.Name = Commands.GetWeight.Name Then
		GetWeight(Command);
	ElsIf Command.Name = Commands.ImportDataFromPDT.Name Then
		ImportDataFromPDT(Command);
	ElsIf Command.Name = Commands.FillThePricesByTermsOfSales.Name Then
		FillThePricesByTermsOfSales(Command);
	ElsIf Command.Name = Commands.FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice.Name Then
		FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice(Command);
	ElsIf Command.Name = Commands.ChangeQuality.Name Then
		ChangeTheQualityOfTheItem(Command);
	ElsIf Command.Name = Commands.SplitTheFactString.Name Then
		SplitTheFactString(Command);
	ElsIf Command.Name = Commands.SelectGoods.Name Then
		SelectGoods(Command);
	ElsIf Command.Name = Commands.FillInTheItemByThePartnerSItem.Name Then
		FillInTheItemByThePartnerSItem(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Command);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	If Item.Name = Items.Goods.Name Then
		GoodsBeforeDeleteRow(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

#EndRegion

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	TMCommonUseClient.SaveAttributeValue(ThisForm, Item);
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventOnChange(Item);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_Clicking_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Click.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandlePushEvent(Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure Attachable_Command_SetAvailabilityOfItemsByStatusServer(Command)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
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
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item, Cancel, Copy, Parent, Var_Group)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeAddRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingDetailsDependingOnStatus()
	
	SetAvailabilityOfItemsByStatusServer();
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisForm);
	
EndProcedure

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Price";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
		
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

&AtServer
Procedure FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts)
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	
	If StructureOfNamesOfTableParts.Property("Goods") Then
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	EndIf;	
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseTermsOfPurchases		= GetFunctionalOption("UseTermsOfPurchases");
	UseLinesOfBusiness		= GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UseDebitNotes	= GetFunctionalOption("UseDebitNotes");
	
	DocumentCurrency = Object.Currency;
	Contract = Object.Contract;
	Warehouse = Object.Warehouse;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReceiptOfGoodsToWarehouse));
	SetVisibility1();
	
	SetVisibilityOfElementsByOperationServer();
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		SetParametersForSelectingWarehouseProps(DisposalWarehouses());
	EndIf;
	
	ShowOrderPresentation();
	SetAvailabilityOfItemsByStatusServer();
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	DocumentDateBeforeChange = Object.Date;
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	PrepareFillSetSeriesVisibility();
	
	If TypeOf(Object.ReferenceOrder) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		
		AgreementOperation = Common.ObjectAttributeValue(Object.ReferenceOrder, "BusinessOperation");
		SeparatePurchaseOperationsByAgreement = PurchasesServer.BusinessOperationsOnMain(AgreementOperation);
		
		OperationsForDocument = PurchasesServer.EconomicOperationsOfSeparatePurchase(FullDocumentName(), Object.ReferenceOrder);
		
		TotalOperations = OperationsForDocument.Count() - 1;
		For IndexOf = 0 To TotalOperations Do
			DocumentOperation_ = OperationsForDocument[TotalOperations - IndexOf];
			If SeparatePurchaseOperationsByAgreement.Find(DocumentOperation_) = Undefined Then
				OperationsForDocument.Delete(TotalOperations - IndexOf);
			EndIf;
		EndDo;
		
		Items.BusinessOperation.ChoiceList.LoadValues(OperationsForDocument);
	Else
		Items.BusinessOperation.ChoiceList.LoadValues(
			PurchasesServer.EconomicOperationsOfSeparatePurchase(FullDocumentName()));
	EndIf;
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	FillInBusinessPartOfAgreement();
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	FillParameters = Documents.ReceiptOfGoodsToWarehouse.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	UpdateTypeOfVATActivity(False);
	
	CalculateTotals_(ThisForm);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

&AtServer
Procedure ShowOrderPresentation()
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		If ReadOnly Then
			ReferenceOrderPresentation = StringFunctions.FormattedString("<a href='Open_Order'>%1</a>", String(Object.ReferenceOrder));
		Else
			ReferenceOrderPresentation = StringFunctions.FormattedString("<a href='Open_Order'>%1</a>  <a href='SelectReference'>%2</a>",
				String(Object.ReferenceOrder), NStr("vi = 'Thay đổi';
													|ru = 'Изменить';
													|en = 'Change'; fa = 'تغییر';
													|it = 'Изменить';
													|pl = 'Change';
													|tr = 'Değiştir'"));
		EndIf;
	Else
		If ReadOnly Then
			ReferenceOrderPresentation = StringFunctions.FormattedString("‹%1›", NStr("vi = 'chưa chọn';
																						|ru = 'не выбрано';
																						|en = 'not selected'; fa = 'not selected';
																						|it = 'не выбрано';
																						|pl = 'not selected';
																						|tr = 'seçilmedi'"));
		Else
			ReferenceOrderPresentation = StringFunctions.FormattedString("‹%1›  <a href='SelectReference'>%2</a>",
				NStr("vi = 'chưa chọn';
					|ru = 'не выбрано';
					|en = 'not selected'; fa = 'not selected';
					|it = 'не выбрано';
					|pl = 'not selected';
					|tr = 'seçilmedi'"), NStr("vi = 'Chọn';
													|ru = 'Выбрать';
													|en = 'Select'; fa = 'انتخاب';
													|it = 'Выбрать';
													|pl = 'Select';
													|tr = 'Seç'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function PlaceGoodsInTemporaryStorageServer(CollectionName)
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(Object[CollectionName]);
	
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	TableOfGoods = GetFromTempStorage(AddressInTempStorage); // DocumentTabularSection.ReceiptOfGoodsToWarehouse.Goods
	
	FillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	FillInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", FillInVATRate);
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;
	
	For Each CurRow In TableOfGoods Do
		
		ArrayOfCollectionRows = Object.Goods.FindRows(New Structure("LineNumber", CurRow.LineNumber));
		If ArrayOfCollectionRows.Count() <> 1 Then
			Continue;
		Else
			CollectionRow = ArrayOfCollectionRows[0];
		EndIf;
		
		FillPropertyValues(CollectionRow, CurRow, "Products, Characteristic, Package");
		RowsToProcess.Add(CollectionRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Object.Currency;
	
	Object.Contract = PurchasesServer.GetDefaultContract(Object, ContractBusinessTransaction, AddlParameters);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts);
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsPartnerProducts);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingWarehouseProps(DisposalWarehouses)
	
	FormField = Items.Warehouse;
	FieldSelectionParameters = New Array;
	
	For Each ChoiceParameter In FormField.ChoiceParameters Do
		If Not ChoiceParameter.Name = "Filter.Ref" Then
			FieldSelectionParameters.Add(ChoiceParameter);
		EndIf;
	EndDo;
	
	If ValueIsFilled(DisposalWarehouses) Then
		SelectionParameterToAdd = New ChoiceParameter("Filter.Ref", DisposalWarehouses);
		
		FieldSelectionParameters.Add(SelectionParameterToAdd);
	EndIf;
	
	FormField.ChoiceParameters = New FixedArray(FieldSelectionParameters);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	FillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	FillInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", FillInVATRate);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "PartnerProducts, Products, Characteristic, Package, Price, NumberOfPackages");
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
		
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, TSName)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	RowsToProcess = New Array;
	
	If TSName = "Goods" Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
	
	For Each RowOfGoods In ItemsFromStorage Do
		ObjectTSGoods = Object[TSName]; // DocumentTabularSection.ReceiptOfGoodsToWarehouse.Goods
		StringTSGoods = ObjectTSGoods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods);
		If TSName = "Goods" Then
			RowsToProcess.Add(StringTSGoods);
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TSName]);
	
	If TSName = "Goods" Then
		FillInStatusesForSpecifyingSeriesServer();
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(Form);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

&AtClient
Procedure QuestionUserBeforeFillingInAgreement(CallbackDescription)
	
	If Object.Goods.Count() = 0
		Or Not ValueIsFilled(Object.Terms)
		Or SelectedOperationWithoutPrices(Object.BusinessOperation) Then
		
		RunCallback(CallbackDescription, False);
		
		Return;
		
	EndIf;
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True,	NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Ricompilare';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False,		NStr("vi = 'Không điền lại';
											|ru = 'Не перезаполнять';
											|en = 'Do not refill'; fa = 'Do not refill';
											|it = 'Non ricompilare';
											|pl = 'Nie wypełniaj ponownie';
											|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(CallbackDescription,
					NStr("vi = 'Điền lại giá theo thỏa thuận?';
						|ru = 'Перезаполнить цены по соглашению?';
						|en = 'Refill prices by terms of sales?'; fa = 'Refill prices by terms of sales?';
						|it = 'Ricompilare i prezzi in base all''accordo?';
						|pl = 'Wypełnić ceny ponownie wg porozumienia?';
						|tr = 'Fiyatlar anlaşmaya göre yeniden doldurulsun mu?'"),
					AnswersOptions);
	
EndProcedure

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	TabularPartProducts = Object.Goods.Unload(,"Products, Characteristic, ItemVariantsAreUsed, Package, NumberOfPackages, Series, BatchesIndicationStatus, BatchesIndicationStatusInWarehouses, BatchesIndicationStatusGoodsAtPartners, ItemsType");
	TabularPartProducts.GroupBy("Products, Characteristic, ItemVariantsAreUsed, Package, Series, BatchesIndicationStatus, BatchesIndicationStatusInWarehouses, BatchesIndicationStatusGoodsAtPartners, ItemsType", "NumberOfPackages");
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	RowsToProcess = New Array;
	ProcessedLinesAreNew = New Array;
	LinesToDelete = New Array;
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("Products, Characteristic, Series, BatchesIndicationStatus, Package");
		
		FillPropertyValues(Filter, SourceRow);
		FoundRows = Object.Goods.FindRows(Filter);
		For Each TSRow In FoundRows Do
			
			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If TSRow.NumberOfPackages = 0
				And SourceRow.NumberOfPackages < 0 Then
				
				Continue;
				
			EndIf;
			
			If SourceRow.NumberOfPackages >= 0 Then
				
				TSRow.NumberOfPackages = TSRow.NumberOfPackages + SourceRow.NumberOfPackages;
				SourceRow.NumberOfPackages = 0;
				
			Else
				
				QuantityToWriteOff = -SourceRow.NumberOfPackages;
				QuantityPerLine   = TSRow.NumberOfPackages;
				
				If QuantityToWriteOff > QuantityPerLine Then
					SourceRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
					TSRow.NumberOfPackages       = 0;
				Else
					SourceRow.NumberOfPackages = 0;
					TSRow.NumberOfPackages       = QuantityPerLine - QuantityToWriteOff;
				EndIf;
				
			EndIf;
			
			If TSRow.NumberOfPackages > 0 Then
				RowsToProcess.Add(TSRow);
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			
			ProcessedLinesAreNew.Add(TSRow);
			
		EndIf;
		
	EndDo;

			StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
			
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAreNew,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FilterCriterion = New Structure("NumberOfPackages", 0);
	FoundRows = Object.Goods.FindRows(FilterCriterion);
	
	For Each TSRow In FoundRows Do
		LinesToDelete.Add(TSRow);
	EndDo;
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure FillInBusinessPartOfAgreement()
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations();
	ContractBusinessTransaction = PairsOfSeparatePurchaseOperations.Get(Object.BusinessOperation);
	
	ThisIsAnImport = (ContractBusinessTransaction = Enums.BusinessTransactions.ImportGoodsInTransit);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ParametersForRecalculatingNDSWTCHAmount(Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Form.Object);
	
	Return StructureOfRecalculationOfAmount;
	
EndFunction

&AtClientAtServerNoContext
Function ParametersForConvertingAmountOfNDSVToTS(Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	
	Return StructureOfRecalculationOfAmount;
	
EndFunction

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	RecalculatePrices_2 = False;
	
	If QuestionResult = True Then
		RecalculatePrices_2 = True;
	EndIf;
	
	PricesCalculated = DateOnChangeServer(RecalculatePrices_2);
	DocumentDateBeforeChange = Object.Date;
	
	If RecalculatePrices_2 Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure SplitTheFactStringCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisForm);
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);

	CalculateTotals_(ThisObject);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);
	
	For Each LineOfATabularSection In SelectedRows Do
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	If Not UserRightsCached.VarianceFromPurchaseConditions() Then
		
		ItemArray = New Array;
		
		// Header Controls
		ItemArray.Add("Partner");
		ItemArray.Add("Terms");
		ItemArray.Add("Contract");
		ItemArray.Add("PriceIncludesVAT");
		ItemArray.Add("VATTaxation");
		ItemArray.Add("VATActivityType");
		ItemArray.Add("Organization");
		ItemArray.Add("Counterparty");
		ItemArray.Add("BusinessOperation");
		ItemArray.Add("Manager");
		ItemArray.Add("SalesOpportunity");
		ItemArray.Add("Department");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
	EndIf;
	
EndProcedure

&AtServer
Function RefillByReceivingServer(ThereAreAcceptedGoods = False, CleanUpIfNot = False)
	
	StructureOfRecalculationOfAmount	= BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmount");
	StructureOfActionsWithModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInPurchasePrice",
		BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute",
													New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_",
													New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute",
													New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmount");
	StructureOfActionsWithAddedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus",
													New Structure("SeriesSpecificationParameters, Warehouse",
																	SeriesSpecificationParameters, Object.Warehouse));
	
	StructureOfActionsWithAddedStrings.Insert("ProductsOnChangeOverridable",
													New Structure("FormName, TabularSectionName",
																	ThisForm.FormName, "Goods"));
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	FillingWarehouse = Object.Warehouse;
	
	ReferenceArray = New Array();
	ReferenceArray.Add(Object.ReferenceOrder);
	
	GoodsReceiptOption = ?(Object.GoodsReceiptOption = Enums.GoodsReceiptOptions.SplitByInvoicesOnly,
								Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices,
								Object.GoodsReceiptOption);
	
	FillParameters = PurchasesServer.FillingParametersForActualAcceptance();
	FillParameters.DocumentInflow                    = Object.Ref;
	FillParameters.DateOfReceipt                        = Object.Date;
	FillParameters.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	FillParameters.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	FillParameters.Warehouse                                  = FillingWarehouse;
	FillParameters.ReferenceArray                     = ReferenceArray;
	FillParameters.Terms                             = Object.Terms;
	FillParameters.Contract                                = Object.Contract;
	FillParameters.GoodsReceiptOption                  = GoodsReceiptOption;
	
	HasChanges = PurchasesServer.FillInGoodsOnActualAcceptance(Object.Goods,
																		FillParameters,
																		ThereAreAcceptedGoods);
	
	If Not ThereAreAcceptedGoods
		And CleanUpIfNot Then
		
		Object.Goods.Clear();
		
	EndIf;
	
	FillInStatusesForSpecifyingSeriesServer();
	
	Return HasChanges;
	
EndFunction

&AtServer
Function FullDocumentName()
	
	Return "Document.ReceiptOfGoodsToWarehouse";
	
EndFunction

&AtServer
Procedure SetVisibility1()
	
	SetVisibilityOfSeriesElements();
	
	OperationWithoutPrices = SelectedOperationWithoutPrices(Object.BusinessOperation);
	
	Items.GroupCurrencyPriceType.Visible          = Not OperationWithoutPrices;
	Items.CurrencyGroup_2.Visible                 = Not OperationWithoutPrices;
	Items.GroupPrices.Visible                   = Not OperationWithoutPrices;
	Items.GoodsPrice.Visible                   = Not OperationWithoutPrices;
	Items.GoodsSum.Visible                  = Not OperationWithoutPrices;
	Items.GoodsVATRate.Visible              = Not OperationWithoutPrices;
	Items.GoodsVATAmount.Visible               = Not OperationWithoutPrices;
	Items.GoodsAmountIncludingVAT.Visible              = Not OperationWithoutPrices;
	Items.PriceIncludesVAT.Visible              = Not OperationWithoutPrices;
	Items.RegisterVendorPrices.Visible = Not OperationWithoutPrices;
	Items.GroupInTotal.Visible                  = Not OperationWithoutPrices;
	
EndProcedure

&AtClientAtServerNoContext
Function SelectedOperationWithoutPrices(BusinessOperation)
	
	Return BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit");
	
EndFunction

&AtServer
Function DisposalWarehouses(ClearWarehouse = False)
	
	DisposalWarehouses = New Array;
	
	If TypeOf(Object.ReferenceOrder) = Type("DocumentRef.PurchaseOrder")
		Or TypeOf(Object.ReferenceOrder) = Type("DocumentRef.VendorInvoice") Then
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	GoodsToReceive.Warehouse AS Warehouse
		|FROM
		|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
		|WHERE
		|	GoodsToReceive.DocumentInflow = &ReferenceOrder";
		
		Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		While Selection.Next() Do
			DisposalWarehouses.Add(Selection.Warehouse);
		EndDo;
		
		If ClearWarehouse
			And ValueIsFilled(Object.Warehouse)
			And DisposalWarehouses.Find(Object.Warehouse) = Undefined Then
			
			Object.Warehouse = Undefined;
			
		EndIf;
		
	EndIf;
	
	Return DisposalWarehouses;
	
EndFunction

&AtServer
Procedure FillInVATTaxationPurchases()
	
	FillParameters = Documents.ReceiptOfGoodsToWarehouse.ParametersForFillingInVATTaxationPurchases(Object);
	
	VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation,
												FillParameters,
												VATAccountingCachedParameterValues);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = ParametersForRecalculatingNDSWTCHAmount(ThisForm);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	CalculateTotals_(ThisForm);

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure UpdateTypeOfVATActivity(FillInTypeOfActivity = True)
	
	FillParameters = Documents.ReceiptOfGoodsToWarehouse.ParametersForFillingInVATActivityType(Object);
	
	If FillInTypeOfActivity Then
		
		OperationWithoutPrices = SelectedOperationWithoutPrices(Object.BusinessOperation);
		
		If OperationWithoutPrices Then
			Object.VATActivityType = Undefined;
		EndIf;
		
		VATAccountingERP.FillInTypeOfActivityVAT(Object.VATActivityType, FillParameters,
			VATAccountingCachedParameterValues);
		
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(Items.VATActivityType,
														Object.VATActivityType,
														FillParameters,
														VATAccountingCachedParameterValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	
	OperationWithoutPrices = SelectedOperationWithoutPrices(Form.Object.BusinessOperation);
	
	If OperationWithoutPrices Then
		Form.Items.GroupInTotal.Visible = False;
	Else
		Form.Items.GroupInTotal.Visible = True;
		
		If VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(Form.Object.VATTaxation) Then
			Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
			Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
		Else
			Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
			Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure
// 
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	GoodsPartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

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

#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	#Region IntegratedSubsystems
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// BarcodesAndTradeEquipment
	TMCommonUse.CustomizePeripherals(ThisObject);
	// End BarcodesAndTradeEquipment
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	SetAvailabilityOfClipboardCommands(ThisObject, ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	RightToReadSubstitutes = GetFunctionalOption("UseAlternativeMaterials")
						  And AccessRight("Read", Metadata.InformationRegisters.AlternativeMaterials);
	
	Items.GoodsSelectSubstitutes.Visible = RightToReadSubstitutes;
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseRequest.ItemsAndDimensionsSelectionParameters(Object.PurchaseObjective);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	Items.GoodsFillInTermsOfPurchaseBasedOnCommercialOffers.Visible = CommercialProposalsDocumentsTM.UseRequestsForCommercialOffersFromSuppliers();
	SetParametersForSelectingAgreements();
	SetContractsSelectionParameters();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	#EndRegion
	
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseRequest.ItemsAndDimensionsSelectionParameters(Object.PurchaseObjective);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OnReadCreateAtServer();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
		
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	#EndRegion
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	FillInFormDetails();
	FormControl();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	#Region IntegratedSubsystems
	
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
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
		
	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		
		FillInServiceDetailsOfAgreements();
		GoodsLineManagement();
		
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommands(ThisObject, True);
		
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		// A new value has been entered:
		Modified = True;
	EndIf;
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(
		Undefined,
		ThisObject,
		"BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	#EndRegion
	
	GoodsLineManagement();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	#Region IntegratedSubsystems
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	HideCanceledLines = Settings.Get("HideCanceledLines");
	
	HowToUpdateRowSelectionForCanceledRows(ThisObject, HideCanceledLines, True);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SelectedRows = Items.Goods.SelectedRows;
		
		For Each String In SelectedRows Do
			
			RowData = Object.Goods.FindByID(String);
			UpdateDivisionOfGoodsLine(RowData, ValueSelected, True);
			
		EndDo;
	ElsIf ChoiceSource.FormName = "Document.EngineeringChangeOrder.Form.SubstitutionOfMaterialsWithAlternativeMaterials" Then
		
		Replace_With_Analogues(ValueSelected.AddressInStorage);
	EndIf;
	
	SetWhetherWarehouseIsFull(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_PurchaseRequest", WriteParameters, Object.Ref);
	
	#Region IntegratedSubsystems
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	#EndRegion
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region Protocol

&AtClient
Procedure StatusPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	OperationsWithDocumentProtocolClient.ProcessProtocolNavigationLink(
		ThisObject,
		FormattedStringURL,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure ArtistPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	OperationsWithDocumentProtocolClient.ProcessProtocolNavigationLink(
		ThisObject,
		FormattedStringURL,
		StandardProcessing);
	
EndProcedure

#EndRegion

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(
		Object,
		New CallbackDescription("DateOnChangeCompletion", ThisObject),
		"Goods",
		False);
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)

	OrganizationWhenChangedOnServer(CachedValues);
	GoodsLineManagement();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If Object.Currency <> DocumentCurrency Then
		
		WhenChangingCurrencyServer(CachedValues);
		
		If Object.Goods.Total("Price") > 0 Then
			PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		EndIf;
		
	EndIf;
	
	DocumentCurrency = Object.Currency;
	GoodsLineManagement();
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATWhenChangedOnServer();
	GoodsLineManagement();

EndProcedure

&AtClient
Procedure OneDateReceiptOnChange(Item)
	
	If Object.OneDateReceipt Then
		SetDesiredDateOfReceiptInHeader();
	Else
		Object.RequestedDeliveryDate = Undefined;
	EndIf;
		
	Items.RequestedDeliveryDate.Visible = Object.OneDateReceipt;
	
EndProcedure

&AtClient
Procedure RequestedDeliveryDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	SetDesiredDateOfReceiptInTable();
EndProcedure

&AtClient
Procedure PurchaseObjectiveOnChange(Item)
	
	PurchaseTargetOnChangeATServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

#Region TableEvents

&AtClient
Procedure GoodsOnActivateRow(Item)
	// A call without a waiting handler, because after the handler, the activation of the input field is reset.
	GoodsLineManagement();
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem.Name = "GoodsPartnerProducts" Then
		SetSelectionOfPartnerItem();
	EndIf;

EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	RowOfGoods = Items.Goods.CurrentData;
	If NewRow And Not Copy Then
		
		RowOfGoods.Department = Object.Department;
		
		If Object.OneDateReceipt Then
			RowOfGoods.RequestedDeliveryDate = Object.RequestedDeliveryDate;
		EndIf;
		
		RowOfGoods.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
		
		Actions = New Structure;
		Actions.Insert("FillInPresentationOfTermsOfPurchase"); // Filling with an "empty value"
		BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);
		
	EndIf;
	
	If NewRow Then
		// Activation will be performed before filling in the data in the line
		//   Therefore, we call for calculation based on the completed data:
		GoodsLineManagement();
	EndIf;
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	RowOfGoods = Items.Goods.CurrentData;
	
	If Not CancelEdit Then
		
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, RowOfGoods, LineCache, WarehouseGroup_);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	EndIf;
	
	SetWhetherWarehouseIsFull(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	CalculateFinalIndicatorsOfApplication(ThisObject);
	UpdateWarehouseGroupImage();
	SetWhetherWarehouseIsFull(ThisObject);
EndProcedure

#EndRegion

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	ClearMessages();
	
	RowOfGoods = Items.Goods.CurrentData;
	
	Actions = New Structure;
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, True));
	Actions.Insert("CheckCharacteristicsByOwner", RowOfGoods.Characteristic);
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("CheckFillPackageByOwner", RowOfGoods.Package);
	Actions.Insert("RecalculateNumberOfUnits");
	Actions.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	Actions.Insert("FillInProductNameOfProductPartner", True);
	
	CommonClientServer.SupplementStructure(Actions, ActionsToFillInPrice(Object), True);
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInVATRate(Object, FormCache), True);
		
	If ControlProductRange(FormCache) Then
		Actions.Insert("CheckRowAssortment", AssortmentVerificationParameters(Object));
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	UpdateDivisionOfGoodsLine(RowOfGoods, Object.Department);
	SetWhetherWarehouseIsFull(ThisObject);
	CalculateFinalIndicatorsOfApplication(ThisObject);
	GoodsLineManagement();
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	RowOfGoods = Items.Goods.CurrentData;
	
	Actions = New Structure;
	Actions.Insert("FillInProductNameOfProductPartner", True);
	CommonClientServer.SupplementStructure(Actions, ActionsToFillInPrice(Object), True);
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInVATRate(Object, FormCache), True);
	Actions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);

	CalculateFinalIndicatorsOfApplication(ThisObject);
	GoodsLineManagement();
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	
	GoodsDestinationOnChangeATServer(CachedValues);
	GoodsLineManagement();
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	RowOfGoods = Items.Goods.CurrentData;
	Actions = ActionsWhenChangingQuantity(Object.PriceIncludesVAT);
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);

	CalculateFinalIndicatorsOfApplication(ThisObject);
	GoodsLineManagement();
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	RowOfGoods = Items.Goods.CurrentData;
	
	Actions = New Structure;
	Actions.Insert("FillInProductNameOfProductPartner", True);
	CommonClientServer.SupplementStructure(Actions, ActionsWhenChangingQuantity(Object.PriceIncludesVAT), True);
	
	If RowOfGoods.Count > 0 Then
		Actions.Insert("RecalculatePricePerPackage", RowOfGoods.Count);
		CommonClientServer.SupplementStructure(Actions, ActionsForFillingInSummaryDetailsOfForm(), True);
	Else
		CommonClientServer.SupplementStructure(Actions, ActionsToFillInPrice(Object), True);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsCanceledOnChange(Item)
	
	RowOfGoods = Items.Goods.CurrentData;
	
	Actions = New Structure;
	Actions.Insert("WhenChangingProductType", // Filling out the warehouse obligation
		New Structure("ThereAreWorks, IsCanceled", True, True));
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInSummaryDetailsOfForm(), True);
	
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	HowToUpdateRowSelectionForCanceledRows(ThisObject, HideCanceledLines, False);
	SetWhetherWarehouseIsFull(ThisObject);
	
EndProcedure

//@skip-check module-structure-form-event-regions -- Attributes are displayed in the "basement"
#Region PurchaseTerms

&AtClient
Procedure GoodsPartnerOnChange(Item)
	
	PartnerItemsOnChangeATServer(CachedValues);
	GoodsLineManagement();
	
EndProcedure

&AtClient
Procedure PartnerProductsAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Waiting = 0 Then
		SetSelectionOfPartnerItem();
	EndIf;
	
EndProcedure

 &AtClient
Procedure GoodsPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	RowOfGoods = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", RowOfGoods);
	
	ClosingNotification1 = New CallbackDescription("ProcessPartnerItemSelection", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, RowOfGoods.Partner, RowOfGoods, Item.Title, ClosingNotification1);

EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	ProcessChangesToPartnerSItemList();
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

#Region Terms

&AtClient
Procedure GoodsTermsOnChange(Item)
	
	ItemsAgreementOnChangeATServer(CachedValues);
	GoodsLineManagement();
	
EndProcedure

&AtClient
Procedure GoodsTermsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	CurrentData = Items.Goods.CurrentData;
	
	PurchasesClient.StartSelectingSupplierAgreement(
		Item,
		StandardProcessing,
		CurrentData.Partner,
		CurrentData.Terms,
		Object.Date);
		
EndProcedure
	
#EndRegion

&AtClient
Procedure GoodsCounterpartyOnChange(Item)
	
	GoodsCounterpartyOnChangeATServer(CachedValues);
	GoodsLineManagement();
	
EndProcedure

&AtClient
Procedure GoodsContractCreating(Item, StandardProcessing)
	
	RowOfGoods = Items.Goods.CurrentData;
	PurchasesClient.OpenContractCreationForm(
		ThisObject,
		Item,
		"Items.Goods.CurrentData.Contract",
		RowOfGoods.Partner,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsContractOnChange(Item)
	
	GoodsContractOnChangeATServer(CachedValues);
	GoodsLineManagement();
	
EndProcedure

&AtClient
Procedure GoodsVATTaxationOnChange(Item)
	
	GoodsVATTaxationOnChangesATServer(CachedValues);
	GoodsLineManagement();
	
EndProcedure

&AtClient
Procedure GoodsVendorPriceKindOnChange(Item)
	
	RowOfGoods = Items.Goods.CurrentData;
	
	Actions = ActionsToFillInPrice(Object);
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	RowOfGoods = Items.Goods.CurrentData;
	
	Actions = ActionsForRecalculatingAmount(Object.PriceIncludesVAT);
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	SaveSpecifiedVATRATE(FormCache, RowOfGoods.VATRate);
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	RowOfGoods = Items.Goods.CurrentData;
	
	Actions = ActionsForRecalculatingAmount(Object.PriceIncludesVAT);
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	RowOfGoods = Items.Goods.CurrentData;
	
	PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInVHFPurchases(
		Object,
		True); // Disabling manual discounts
	
	Actions = New Structure;
	Actions.Insert("RecalculatePriceDiscountForAmountInPurchases", PriceFillingParameters_);
	CommonClientServer.SupplementStructure(Actions, ActionsForRecalculatingAmount(Object.PriceIncludesVAT, False), True);
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	RowOfGoods = Items.Goods.CurrentData;
	
	Actions = ActionsForRecalculatingAmount(Object.PriceIncludesVAT, False, False);
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

#Region PurchaseTerms

&AtClient
Procedure CopyPurchaseConditions(Command)
	
	If Not CheckForSelectedLines(False) Then
		Return;
	EndIf;
	
	PurchaseParameterBuffer = New Structure;
	PurchaseParameterBuffer.Insert("Partner");
	PurchaseParameterBuffer.Insert("Counterparty");
	PurchaseParameterBuffer.Insert("Terms");
	PurchaseParameterBuffer.Insert("Contract");
	PurchaseParameterBuffer.Insert("VendorPriceKind");
	PurchaseParameterBuffer.Insert("Currency");
	PurchaseParameterBuffer.Insert("VATTaxation");
	PurchaseParameterBuffer.Insert("VATRate");
	
	Items.GoodsInsertPurchaseConditions.Enabled = True;
	
	CurrentData = Items.Goods.CurrentData;
	FillPropertyValues(PurchaseParameterBuffer, CurrentData);

EndProcedure

&AtClient
Procedure InsertPurchaseConditions(Command)
	
	If Not ValueIsFilled(PurchaseParameterBuffer)
		Or Not CheckForSelectedLines() Then
		Return;
	EndIf;
	
	InsertPurchaseTermsAtServer(Items.Goods.SelectedRows);
	CalculateFinalIndicatorsOfApplication(ThisObject);
	GoodsLineManagement();
	
EndProcedure

#EndRegion

#Region CommercialProposals

&AtClient
Procedure StartFillingInTermsOfPurchaseBasedOnCommercialOffers(Command)
	
	ClearMessages();
	
	If Not CheckForSelectedLines() Then
		Return;
	EndIf;
	
	FillingResult = FillInTermsOfPurchaseBasedOnCommercialOffers(Items.Goods.SelectedRows);
	
	For Each ItemsLineNumber In FillingResult.LineNumbersWithBlankPurchaseConditions Do
		
		ErrorText = StrTemplate(
			NStr("vi = 'Đối với dòng %1 danh sách ""Hàng hóa"" không tìm thấy điều kiện mua hàng trong báo giá đã chọn.';
				|ru = 'Для строки %1 списка ""Товары"" не найдены условия закупки в выбранных коммерческих предложениях.';
				|en = 'No purchase conditions are found for line %1 of the ""Goods"" list in the selected sales quotations.'; fa = 'No purchase conditions are found for line %1 of the ""Goods"" list in the selected sales quotations.';
				|it = 'No purchase conditions are found for line %1 of the ""Goods"" list in the selected sales quotations.';
				|pl = 'No purchase conditions are found for line %1 of the ""Goods"" list in the selected sales quotations.';
				|tr = '""Mallar"" listesinin %1 satırı için seçili satış tekliflerinde satın alma koşulu bulunamadı.'"),
			ItemsLineNumber);
		
		PathToItem = CommonClientServer.PathToTabularSection(
			"Object.Goods",
			ItemsLineNumber,
			"PresentationOfTermsOfPurchase");
		
		CommonClient.MessageToUser(
			ErrorText,
			,
			PathToItem);
			
	EndDo;
	
	If FillingResult.Cancel Then
		
		ShowMessageBox(, FillingResult.ErrorText);
		
	Else
		
		NumberOfRawRows = FillingResult.LineNumbersWithBlankPurchaseConditions.Count();
		
		ThereAreFilledLines = Items.Goods.SelectedRows.Count() > NumberOfRawRows;
		If ThereAreFilledLines Then
			MessageText = NStr("vi = 'Đã điền điều kiện mua hàng.';
								|ru = 'Условия закупки заполнены.';
								|en = 'The purchase conditions are filled.'; fa = 'The purchase conditions are filled.';
								|it = 'The purchase conditions are filled.';
								|pl = 'The purchase conditions are filled.';
								|tr = 'Satın alma koşulları dolduruldu'");
		Else
			MessageText = NStr("vi = 'Không thể điền điều kiện mua hàng.';
								|ru = 'Не удалось заполнить условия закупки.';
								|en = 'Cannot fill in the purchase conditions.'; fa = 'Cannot fill in the purchase conditions.';
								|it = 'Cannot fill in the purchase conditions.';
								|pl = 'Cannot fill in the purchase conditions.';
								|tr = 'Satın alma koşulları doldurulamadı.'");
		EndIf;
		
		ExplanationText = StrTemplate(NStr("vi = 'Đã điền điều kiện mua hàng vào %1 trong số %2 dòng.';
											|ru = 'Условия закупки заполнены в %1 из %2 строк.';
											|en = 'The purchase conditions are filled in %1 out of %2 lines.'; fa = 'The purchase conditions are filled in %1 out of %2 lines.';
											|it = 'The purchase conditions are filled in %1 out of %2 lines.';
											|pl = 'The purchase conditions are filled in %1 out of %2 lines.';
											|tr = 'Satın alma koşulları %2 satırın %1''inde dolduruldu.'"),
			Items.Goods.SelectedRows.Count() - NumberOfRawRows,
			Items.Goods.SelectedRows.Count());
			
		ShowUserNotification(MessageText,, ExplanationText, PictureLib.Information32);
		
		CalculateFinalIndicatorsOfApplication(ThisObject);
		GoodsLineManagement();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CancelLines

&AtClient
Procedure HideCanceledLines(Command)
	
	HideCanceledLines = Not HideCanceledLines;
	
	HowToUpdateRowSelectionForCanceledRows(ThisObject, HideCanceledLines, True);
	
EndProcedure

&AtClient
Procedure CancelSelectedLines(Command)
	
	If Not CheckForSelectedLines() Then
		Return;
	EndIf;
	
	Actions = New Structure;
	Actions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled", True, True));
		
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInSummaryDetailsOfForm(), True);
	
	For Each RowID In Items.Goods.SelectedRows Do
		
		RowOfGoods = Object.Goods.FindByID(RowID);
		
		If Not RowOfGoods.Canceled Then
			RowOfGoods.Canceled = True;
			BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);
		EndIf;
		
	EndDo;
	
	UpdateWarehouseGroupImage();
	CalculateFinalIndicatorsOfApplication(ThisObject);
	SetWhetherWarehouseIsFull(ThisObject);
	
	ShowUserNotification(
		NStr("vi = 'Hủy các dòng đã chọn';
			|ru = 'Выделенные строки отменены';
			|en = 'Selected lines are canceled'; fa = 'Selected lines are canceled';
			|it = 'Righe selezionate annullate';
			|pl = 'Zaznaczone wiersze anulowano';
			|tr = 'Seçili satırlar iptal edildi'"),
		,
		NStr("vi = 'Đã hủy các dòng được chọn trong đơn hàng.';
			|ru = 'Выделенные строки заказа отменены.';
			|en = 'Selected items are canceled from the order.'; fa = 'Selected items are canceled from the order.';
			|it = 'Righe selezionate dell''ordine sono annullate.';
			|pl = 'Wydzielone wiersze zamówienia zamówienia są anulowane.';
			|tr = 'Seçili sipariş satırları iptal edildi.'"),
		PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure UndoLinesThatAreNotOrdered(Command)
	
	Result = UndoLinesThatAreNotOrderedServer();
	If Not IsBlankString(Result.WarningText) Then
		ShowMessageBox(, Result.WarningText);
		Return;
	EndIf;
	
	If Result.ThereAreCanceledLines = 0 Then
		
		ShowUserNotification(
			NStr("vi = 'Các dòng chưa hủy';
				|ru = 'Строки не отменены';
				|en = 'Lines were not canceled'; fa = 'Lines were not canceled';
				|it = 'Righe non annullate';
				|pl = 'Wiersze nie są anulowane';
				|tr = 'Satırlar iptal edilmedi'"),
			,
			NStr("vi = 'Đã lập đơn hàng theo tất cả các dòng yêu cầu. Không thể hủy các dòng này.';
				|ru = 'По всем строкам заявки оформлены заказы. Строки не могут быть отменены.';
				|en = 'The orders are registered for all request lines. The lines cannot be canceled.'; fa = 'The orders are registered for all request lines. The lines cannot be canceled.';
				|it = 'The orders are registered for all request lines. The lines cannot be canceled.';
				|pl = 'The orders are registered for all request lines. The lines cannot be canceled.';
				|tr = 'Tüm talep satırları için siparişler oluşturuldu. Satırlar iptal edilemez'"),
			PictureLib.Information32);
			
	Else
		
		ShowUserNotification(
			NStr("vi = 'Các dòng bị hủy';
				|ru = 'Строки отменены';
				|en = 'Lines were canceled'; fa = 'Lines were canceled';
				|it = 'Righe annullate';
				|pl = 'Wiersze są anulowane';
				|tr = 'Satırlar iptal edildi'"),
			,
			NStr("vi = 'Đã hủy tất cả các dòng yêu cầu mà chưa đặt hàng.';
				|ru = 'Все незаказанные строки заявки отменены.';
				|en = 'All the unordered request lines are canceled.'; fa = 'All the unordered request lines are canceled.';
				|it = 'All the unordered request lines are canceled.';
				|pl = 'All the unordered request lines are canceled.';
				|tr = 'Sipariş edilmeyen tüm talep satırları iptal edildi.'"),
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region IntegratedSubsystems

#Region BarcodesAndTradeEquipment

&AtClient
Procedure SearchByBarcodeExecute(Command)
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	PeripheralsPortableDataTerminalsServerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

#EndRegion

#Region FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region Properties

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Clipboard

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
	SetWhetherWarehouseIsFull(ThisObject);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

#EndRegion

#Region LineBreakdown

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

#EndRegion

#Region SelectGoods

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.PurchaseRequest.DocumentForm.Command.SelectGoods");
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",        Object.Ref);
	FormParameters.Insert("Warehouse",           Object.Warehouse);
	FormParameters.Insert("Date",            Object.Date);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	
	// The selection of goods in the document is carried out by the applicant, not the buyer.
	// The partner and the agreement are unknown for the selection of price types.
	FormParameters.Insert("SelectionModeWithoutAmountParameters", True); 
	FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False)));
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

#EndRegion 

#Region Substitutes

&AtClient
Procedure SelectSubstitutes(Command)
	PerformanceMonitorClient.TimeMeasurement(
		"Document.PurchaseRequest.Form.DocumentForm.Command.SelectSubstitutes");
	
	OpenSelectionOfAnalogues();
	Return; // in UT and KA the handler is empty
	
EndProcedure

#EndRegion

#Region LoadingFromFile

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.FillingDate  = Object.Date;
	ImportParameters.Organization     = Object.Organization;
	ImportParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	ImportParameters.ImportPrices   = True;
	ImportParameters.ImportAmounts  = True;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

#EndRegion

#Region DocumentRecording

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, False);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, False);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, False);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

#EndRegion

#EndRegion

#Region FillType

&AtClient
Procedure FillInTheWarehouseInSelectedLines(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	
	If Not WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(
		Object,
		Object.Goods,
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Goods'; fa = 'کالاها';
			|it = 'Goods';
			|pl = 'Goods';
			|tr = 'Mallar'"),
		SelectedRows) Then
			
		Return;
	EndIf;
		
	SelectGroup = New Array;
	SelectGroup.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrders"));
	SelectGroup.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"));
	
	Filter = New Structure;
	Filter.Insert("SelectGroup", SelectGroup);
	Filter.Insert("IsFolder",    False);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter", Filter);
	OpeningParameters.Insert("GroupOfWarehouses", Object.Warehouse);

	OpenForm(
		"Catalog.Warehouses.ChoiceForm",
		OpeningParameters,
		ThisObject,,,,
		New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion

#Region PurchaseOrders

&AtClient
Async Procedure CreatePurchaseOrderForSupplier(Command)
	
	ClearMessages();
	
	If Not CheckForSelectedLines() Then
		Return;
	EndIf;
	
	If Modified
		Or Object.Ref.IsEmpty()
		Or Not Object.Posted Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Kết chuyển và tiếp tục';
												|ru = 'Провести и продолжить';
												|en = 'Post and continue'; fa = 'Post and continue';
												|it = 'Pubblicare e continuare';
												|pl = 'Zatwierdzić i kontynuować';
												|tr = 'Kaydet ve devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("vi = 'Để tạo đơn hàng đặt nhà cung cấp, chứng từ sẽ được kết chuyển. Tiếp tục?';
						|ru = 'Для создания заказа поставщику документ будет проведен. Продолжить?';
						|en = 'To create a purchase order, the document will be posted. Continue?'; fa = 'To create a purchase order, the document will be posted. Continue?';
						|it = 'To create a purchase order, the document will be posted. Continue?';
						|pl = 'To create a purchase order, the document will be posted. Continue?';
						|tr = 'Tedarikçi siparişi oluşturmak için belge kaydedilecek. Devam edilsin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, Buttons);
		
		If Response <> DialogReturnCode.OK Then
			Return;
		EndIf;
		
		WriteParameters = New Structure;
		WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
		If Not Write(WriteParameters) Then
			Return;
		EndIf;
		
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement("Document.PurchaseRequest.DocumentForm.Command.CreatePurchaseOrderForSupplier");
	
	SelectedRows = Items.Goods.SelectedRows;
	DescriptionOfOrderToBeCreated = DescriptionOfOrderToBeCreated(SelectedRows);
	
	If DescriptionOfOrderToBeCreated.OrderData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Theo các dòng đã chọn, không cần nhập đơn hàng mới.';
								|ru = 'По выделенным строкам не требуется ввод новых заказов.';
								|en = 'No new orders are required for the selected lines.'; fa = 'No new orders are required for the selected lines.';
								|it = 'No new orders are required for the selected lines.';
								|pl = 'No new orders are required for the selected lines.';
								|tr = 'Seçili satırlar için yeni sipariş girişi gerekmiyor.'"));
		Return;
	EndIf;
	
	OpenForm("Document.PurchaseOrder.ObjectForm",
		New Structure("FillingValues", DescriptionOfOrderToBeCreated.OrderData),
		ThisObject,
		True);
		
	If ValueIsFilled(DescriptionOfOrderToBeCreated.NotProcessedSourceLines) Then
		
		MessageText = NStr("vi = 'Không thể xếp các dòng được chọn vào một đơn hàng.';
							|ru = 'Невозможно разместить выделенные строки в одном заказе.';
							|en = 'Cannot place selected lines in one order.'; fa = 'Cannot place selected lines in one order.';
							|it = 'Cannot place selected lines in one order.';
							|pl = 'Cannot place selected lines in one order.';
							|tr = 'Seçili satırlar tek bir siparişe yerleştirilemez.'");
		ExplanationText = StrTemplate(NStr("vi = 'Dòng đã chọn: %1. Đã xử lý: %2. Cần lập đơn hàng: %3';
											|ru = 'Выделено строк: %1. Обработано: %2. Требуют формирования заказов: %3';
											|en = 'Selected lines: %1. Processed: %2. Require order generation: %3'; fa = 'Selected lines: %1. Processed: %2. Require order generation: %3';
											|it = 'Selected lines: %1. Processed: %2. Require order generation: %3';
											|pl = 'Selected lines: %1. Processed: %2. Require order generation: %3';
											|tr = 'Seçili satır: %1. İşlenen: %2. Sipariş oluşturulması gereken: %3'"),
			SelectedRows.Count(),
			DescriptionOfOrderToBeCreated.ProcessedSourceLines,
			DescriptionOfOrderToBeCreated.NotProcessedSourceLines);
		
		ShowUserNotification(MessageText,, ExplanationText, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	FillInFormDetails();
	FormControl();
EndProcedure

&AtServer
Procedure FillInFormDetails()
	
	// It is used as the previous value and is displayed even when the F.O. "Use as much as possible" is turned off: 
	DocumentCurrency = Object.Currency;
	
	OperationsWithDocumentProtocol.FillInFormDetails(ThisObject);
	InitializeFormCache();
		
	Actions = New Structure;
	Actions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	Actions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled", True, True));
	
	Actions.Insert("FillInServiceDetailsForPurpose",
		New Structure("OnlyDestinationType", True));
		
	CommonClientServer.SupplementStructure(Actions,
		PurchaseRequestClientServer.ActionsOfFillingInBusinessOfOperation(),
		True);
	
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInSummaryDetailsOfForm(), True);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, Actions);
	
	FillInServiceDetailsOfAgreements();
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	UpdateWarehouseGroupImage();
	CalculateFinalIndicatorsOfApplication(ThisObject);
	SetWhetherWarehouseIsFull(ThisObject);
	
EndProcedure

#Region PurchaseTerms

&AtClientAtServerNoContext
Procedure CalculateFinalIndicatorsOfApplication(Form)
	
	// Filling in the totals according to the "Products" table
	CollectionProducts = Form.Object.Goods;
	Form.TotalSNDSAmount = CollectionProducts.Total("AmountIncludingVAT") - CollectionProducts.Total("AmountIncludingVATCanceled");
	Form.AmountTotalVAT = CollectionProducts.Total("VATAmount") - CollectionProducts.Total("VATAmountCanceled");
		
EndProcedure

&AtServer
Procedure InsertPurchaseTermsAtServer(Val SelectedRows)
	
	ReadyForProcessing_ = New Array;
	For Each RowID In SelectedRows Do
		RowOfGoods = Object.Goods.FindByID(RowID);
		FillPropertyValues(RowOfGoods, PurchaseParameterBuffer);
		ReadyForProcessing_.Add(RowOfGoods);
	EndDo;
	
	Actions = New Structure;
	ParametersForFillingOutAgreement = BatchProcessingOfTablePartClientServer.ParametersForFillingOutSupplierAgreements();
	Actions.Insert("FillInNumberOfSupplierAgreements", ParametersForFillingOutAgreement);
	Actions.Insert("FillInAttributesAccordingToSupplierSAgreement");
	
	If ValueIsFilled(PurchaseParameterBuffer.VendorPriceKind) Then
		CommonClientServer.SupplementStructure(Actions, ActionsToFillInPrice(Object), True);
	Else
		CommonClientServer.SupplementStructure(Actions, ActionsForRecalculatingAmount(Object.PriceIncludesVAT));
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReadyForProcessing_,
		Actions,
		Object.Goods,
		BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues());
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingAgreements()
	
	AvailableTransactions = Documents.PurchaseRequest.AvailableAgreementOfOperations();
	
	TMCommonUseClientServer.AddSelectionParameter(
		Items.Terms, "BusinessOperation",
		AvailableTransactions);
		
	TMCommonUseClientServer.AddSelectionParameter(
		Items.GoodsTerms, "BusinessOperation",
		AvailableTransactions);
	
EndProcedure

&AtServer
Procedure SetContractsSelectionParameters()

	TMCommonUseClientServer.AddSelectionParameter(
		Items.Contract, "ContractType",
		AvailableTypesOfContracts(FormCache));
		
	TMCommonUseClientServer.AddSelectionParameter(
		Items.GoodsContract, "ContractType",
		AvailableTypesOfContracts(FormCache));
	
EndProcedure

#EndRegion

#Region AdditionalElementEventHandlers

#Region Date_
// The use of "Date" is "unacceptable in this context"

&AtClient
Procedure DateOnChangeCompletion(RecalculatePrices_2, AdditionalParameters) Export 
	
	If Not RecalculatePrices_2 Then
		Return;
	EndIf;
	
	DateOfChangeOnServer();
	GoodsLineManagement();
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	MaintainAssortmentControl(FormCache, Object.Warehouse, Object.Date);
	Actions = New Structure;
	CommonClientServer.SupplementStructure(Actions, ActionsToFillInPrice(Object), True);
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInVATRate(Object, FormCache), True);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, Actions);
	
	If ControlProductRange(FormCache) Then
		ProductRangeServer.CheckAssortmentOfTableOfSelectedProducts(Object, "Warehouse");
	EndIf;
	
EndProcedure

#EndRegion

#Region Organization

&AtServer
Procedure OrganizationWhenChangedOnServer(CachedValues)
	
	Actions = New Structure;
		
	ParametersForFillingOutContract = BatchProcessingOfTablePartClientServer.DefaultContractFillingParameters();
	ParametersForFillingOutContract.Organization = Object.Organization;
	ParametersForFillingOutContract.ARAPCurrency = Object.Currency;
	ParametersForFillingOutContract.ContractType = AvailableTypesOfContracts(FormCache);
	Actions.Insert("FillInDefaultContract", ParametersForFillingOutContract);
	CommonClientServer.SupplementStructure(Actions, ActionsOfFillingInVATTaxation(Object, FormCache), True);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, Actions, CachedValues);
	
	RecalculateVATAmountAtAdjustedRates(CachedValues);
	
EndProcedure

#EndRegion

#Region Warehouse

&AtClient
Procedure FillInTheWarehouseInSelectedLinesCompletion(SelectedWarehouse, AdditionalParameters) Export

	If Not ValueIsFilled(SelectedWarehouse) Then
		Return;
	EndIf;
	
	SelectedRows = Items.Goods.SelectedRows;
	FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse);
	WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(
		SelectedWarehouse,
		FilledWithRows,
		SelectedRows.Count());

EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val SelectedRows, SelectedWarehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(
		Object.Goods,
		SelectedRows,
		SelectedWarehouse);
	
	If FilledWithRows > 0 Then
		UpdateWarehouseGroupImage();
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtServer
Procedure WarehouseOnChangeServer()
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, False);
	
	MaintainAssortmentControl(FormCache, Object.Warehouse, Object.Date);
	
	If ControlProductRange(FormCache) Then
		ProductRangeServer.CheckAssortmentOfTableOfSelectedProducts(Object, "Warehouse");
	EndIf;
	
	FormManagementByWarehouse();
	
EndProcedure

&AtServer
Procedure FormManagementByWarehouse()
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	UpdateWarehouseGroupImage();
	SetParametersForSelectingProductsWarehouse();
	
	If Not WarehouseGroup_ Then
		Items.ProductsGroupRecipient.Title = NStr("vi = 'Bộ phận nhận';
													|ru = 'Подразделение-получатель';
													|en = 'Receiving business unit'; fa = 'واحد تجاری دریافت‌کننده';
													|it = 'Reparto-destinatario';
													|pl = 'Dział-odbiorca';
													|tr = 'Alıcı departman'");
	Else
		Items.ProductsGroupRecipient.Title = NStr("vi = 'Người nhận';
													|ru = 'Получатель';
													|en = 'Recipient'; fa = 'گیرنده';
													|it = 'Destinatario';
													|pl = 'Odbiorca';
													|tr = 'Alıcı'");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateWarehouseGroupImage()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
EndProcedure

#EndRegion

#Region Purpose

&AtServer
Procedure GoodsDestinationOnChangeATServer(CachedValues)
	
	RowOfGoods = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	Actions = New Structure;
	Actions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	
	ParametersForFillingOutContract = BatchProcessingOfTablePartClientServer.DefaultContractFillingParameters();
	ParametersForFillingOutContract.Organization = Object.Organization;
	ParametersForFillingOutContract.ARAPCurrency = Object.Currency;
	ParametersForFillingOutContract.ContractType = AvailableTypesOfContracts(FormCache);
	Actions.Insert("FillInDefaultContract", ParametersForFillingOutContract);
	CommonClientServer.SupplementStructure(Actions, ActionsOfFillingInVATTaxation(Object, FormCache), True);
	
	BatchProcessingOfTablePartServer.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	RecalculateVATAmountAtAdjustedRates(CachedValues);
	
EndProcedure

#EndRegion

#Region Currency

&AtServer
Procedure WhenChangingCurrencyServer(CachedValues) 
	
	Actions = New Structure;
	
	ParametersForFillingOutContract = BatchProcessingOfTablePartClientServer.DefaultContractFillingParameters();
	ParametersForFillingOutContract.Organization = Object.Organization;
	ParametersForFillingOutContract.ARAPCurrency = Object.Currency;
	ParametersForFillingOutContract.ContractType = AvailableTypesOfContracts(FormCache);
	Actions.Insert("FillInDefaultContract", ParametersForFillingOutContract);
	CommonClientServer.SupplementStructure(Actions, ActionsOfFillingInVATTaxation(Object, FormCache), True);
	CommonClientServer.SupplementStructure(
		Actions,
		ActionsForFillingInSummaryDetailsOfForm(),
		True);
	
	RecalculationParameters = PriceManagementSystem.ParametersForConvertingTableAmountsToCurrency(
		Object.PriceIncludesVAT,
		DocumentCurrency,
		Object.Currency,
		?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
		
	PriceManagementSystem.ConvertTableAmountsToCurrency(Object.Goods, RecalculationParameters);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, Actions, CachedValues);
	RecalculateVATAmountAtAdjustedRates(CachedValues);
	
EndProcedure

#EndRegion

#Region PriceIncludesVAT

&AtServer
Procedure PriceIncludesVATWhenChangedOnServer()
	
	Actions = ActionsForRecalculatingAmount(Object.PriceIncludesVAT, False, True);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, Actions);
	SetAvailabilityOfItemsWithVAT();
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure
#EndRegion

#Region Partner

&AtServer
Procedure PartnerItemsOnChangeATServer(CachedValues)

	RowOfGoods = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	Actions = New Structure;
	
	ParametersForFillingOutAgreement = BatchProcessingOfTablePartClientServer.ParametersForFillingOutSupplierAgreements();
	ParametersForFillingOutAgreement.BusinessOperation = Documents.PurchaseRequest.AvailableAgreementOfOperations();
	Actions.Insert("FillInDefaultSupplierAgreement", ParametersForFillingOutAgreement);
	
	Actions.Insert("FillInPartnerSDefaultCounterparty", True);
	
	ParametersForFillingOutContract = BatchProcessingOfTablePartClientServer.DefaultContractFillingParameters();
	ParametersForFillingOutContract.Organization = Object.Organization;
	ParametersForFillingOutContract.ARAPCurrency = Object.Currency;
	ParametersForFillingOutContract.ContractType = AvailableTypesOfContracts(FormCache);
	Actions.Insert("FillInDefaultContract", ParametersForFillingOutContract);
	CommonClientServer.SupplementStructure(Actions, ActionsOfFillingInVATTaxation(Object, FormCache), True);
	
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInPriceType(Object), True);
	
	Actions.Insert("FillInProductNameOfProductPartner", True);
	
	BatchProcessingOfTablePartServer.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	FillInServiceDetailsOfAgreements(RowOfGoods);
	RecalculateVATAmountAtAdjustedRates(CachedValues);
	CalculateFinalIndicatorsOfApplication(ThisObject);

EndProcedure

#EndRegion

#Region Counterparty

&AtServer
Procedure GoodsCounterpartyOnChangeATServer(CachedValues)
	
	RowOfGoods = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	Actions = New Structure;
	
	ParametersForFillingOutContract = BatchProcessingOfTablePartClientServer.DefaultContractFillingParameters();
	ParametersForFillingOutContract.Organization = Object.Organization;
	ParametersForFillingOutContract.ARAPCurrency = Object.Currency;
	ParametersForFillingOutContract.ContractType = AvailableTypesOfContracts(FormCache);
	Actions.Insert("FillInDefaultContract", ParametersForFillingOutContract);
	CommonClientServer.SupplementStructure(Actions, ActionsOfFillingInVATTaxation(Object, FormCache), True);
	BatchProcessingOfTablePartServer.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	RecalculateVATAmountAtAdjustedRates(CachedValues);
	
EndProcedure

#EndRegion

#Region Terms

&AtServer
Procedure ItemsAgreementOnChangeATServer(CachedValues)
	
	RowOfGoods = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	Actions = New Structure;
	
	Actions.Insert("FillInPartnerSDefaultCounterparty", True);
	
	ParametersForFillingOutContract = BatchProcessingOfTablePartClientServer.DefaultContractFillingParameters();
	ParametersForFillingOutContract.Organization = Object.Organization;
	ParametersForFillingOutContract.ARAPCurrency = Object.Currency;
	ParametersForFillingOutContract.ContractType = AvailableTypesOfContracts(FormCache);
	Actions.Insert("FillInDefaultContract", ParametersForFillingOutContract);
	CommonClientServer.SupplementStructure(Actions, ActionsOfFillingInVATTaxation(Object, FormCache), True);
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInPriceType(Object), True);
	
	Actions.Insert("FillInProductNameOfProductPartner", True);
	
	BatchProcessingOfTablePartServer.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	CachedValues.ProcessedRows.Clear(); // Clearing rows with an adjusted VAT rate
	
	FillInServiceDetailsOfAgreements(RowOfGoods);
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

#EndRegion

#Region Contract

&AtServer
Procedure GoodsContractOnChangeATServer(CachedValues)
	
	RowOfGoods = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	Actions = ActionsOfFillingInVATTaxation(Object, FormCache);
	BatchProcessingOfTablePartServer.ProcessTSString(RowOfGoods, Actions, CachedValues);
	RecalculateVATAmountAtAdjustedRates(CachedValues);
	
EndProcedure

#EndRegion

#Region VATTaxation

&AtServer
Procedure GoodsVATTaxationOnChangesATServer(CachedValues)
	
	RowOfGoods = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	Actions = PurchaseRequestClientServer.VATRateAdjustmentActions(Object, SpecifiedVATRate(FormCache));
	BatchProcessingOfTablePartServer.ProcessTSString(RowOfGoods, Actions, CachedValues);
	RecalculateVATAmountAtAdjustedRates(CachedValues);
	
EndProcedure

#EndRegion

#Region PartnerProducts

&AtClient
Procedure ProcessPartnerItemSelection(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	Items.Goods.CurrentData.PartnerProducts = ValueSelected;
	Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(AdditionalParameters.FormItem);
	ProcessChangesToPartnerSItemList();
	
EndProcedure

&AtClient
Procedure ProcessChangesToPartnerSItemList()
	
	RowOfGoods = Items.Goods.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Items.GoodsPartnerProducts.ChoiceParameters, RowOfGoods);
	PartnersProductsClient.SetPackageSelectionParameters(Items.PartnerProducts.ChoiceParameters, RowOfGoods);
	
	Actions = New Structure;
	
	Actions.Insert("FillInTheItemByThePartnerSItem");
	
	Actions.Insert("CheckCharacteristicsByOwner", RowOfGoods.Characteristic);
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("CheckFillPackageByOwner", RowOfGoods.Package);
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled", True, True));
	
	Actions.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
	Actions.Insert("RecalculateNumberOfUnits");
	
	CommonClientServer.SupplementStructure(Actions, ActionsToFillInPrice(Object), True);
	
	BatchProcessingOfTablePartClient.ProcessTSString(RowOfGoods, Actions, CachedValues);
	
	UpdateDivisionOfGoodsLine(RowOfGoods, Object.Department);

	CalculateFinalIndicatorsOfApplication(ThisObject);
	SetWhetherWarehouseIsFull(ThisObject);
	UpdateWarehouseGroupImage();

EndProcedure

#EndRegion

#Region RequestedDeliveryDate

&AtServer
Procedure SetDesiredDateOfReceiptInHeader()
	Object.RequestedDeliveryDate = MaximumDesiredDateOfReceipt();	
	SetDesiredDateOfReceiptInTable();
EndProcedure

&AtServer
Function MaximumDesiredDateOfReceipt()
	
	ReturnValue = '00010101';
	For Each RowOfGoods In Object.Goods Do
		ReturnValue = Max(ReturnValue, RowOfGoods.RequestedDeliveryDate);
	EndDo;
	
	Return ReturnValue;
	
EndFunction

&AtServer
Procedure SetDesiredDateOfReceiptInTable()
	
	For Each RowOfGoods In Object.Goods Do
		RowOfGoods.RequestedDeliveryDate = Object.RequestedDeliveryDate;
	EndDo;
	
EndProcedure

#EndRegion

&AtServer
Procedure PurchaseTargetOnChangeATServer()
	
	ArticleSelectionOptions = Documents.PurchaseRequest.ItemsAndDimensionsSelectionParameters(Object.PurchaseObjective);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ArticleSelectionOptions);
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
	If Not Documents.PurchaseRequest.MonitorBDRLimits(Object) Then
		Object.LineOfBusiness = Undefined;
		For Each TSRow In Object.Goods Do
			TSRow.BudgetFlowItem = Undefined;
		EndDo;
	EndIf;
	
	FormControl();
	
EndProcedure

#EndRegion

#Region LineBreakdown

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	If NewRow = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Items.Goods.CurrentData;
	
	Actions = ActionsWhenChangingQuantity(Object.PriceIncludesVAT);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	BatchProcessingOfTablePartClient.ProcessTSString(NewRow,   Actions, CachedValues);
	
	UpdateWarehouseGroupImage();
	
EndProcedure

#EndRegion

#Region CommercialProposals

&AtServer
Function FillInTermsOfPurchaseBasedOnCommercialOffers(Val RowsIDs)
	
	LineNumbers = New Array;
	For Each RowID In RowsIDs Do
		RowOfGoods = Object.Goods.FindByID(RowID);
		LineNumbers.Add(RowOfGoods.LineNumber);
	EndDo;
	
	FillParameters = CommercialProposalsDocumentsTM.ParametersForFillingInTermsOfPurchaseForCommercialOffers();
	FillParameters.Document = Object.Ref;
	FillParameters.DateOfCourse = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	FillParameters.Currency = Object.Currency;
	FillParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	
	FillParameters.ThereIsAPartner = True;
	FillParameters.ThereIsCounterparty = True;
	FillParameters.LineNumbers = LineNumbers;
	
	CommonClientServer.SupplementStructure(FillParameters.ActionsWithModifiedStrings, ActionsForRecalculatingAmount(Object.PriceIncludesVAT), True);
	FillParameters.ActionsWithModifiedStrings.Insert("FillInProductNameOfProductPartner", True);
	
	// The agreement is not filled in in KP requests, we fill it in with the default value:
	ParametersForFillingOutAgreement = BatchProcessingOfTablePartClientServer.ParametersForFillingOutSupplierAgreements();
	ParametersForFillingOutAgreement.BusinessOperation = Documents.PurchaseRequest.AvailableAgreementOfOperations();
	FillParameters.ActionsWithModifiedStrings.Insert("FillInDefaultSupplierAgreement", ParametersForFillingOutAgreement);
	
	ParametersForFillingOutContract = BatchProcessingOfTablePartClientServer.DefaultContractFillingParameters();
	ParametersForFillingOutContract.Organization = Object.Organization;
	ParametersForFillingOutContract.ARAPCurrency = Object.Currency;
	ParametersForFillingOutContract.ContractType = AvailableTypesOfContracts(FormCache);
	FillParameters.ActionsWithModifiedStrings.Insert("FillInDefaultContract", ParametersForFillingOutContract);
	CommonClientServer.SupplementStructure(
		FillParameters.ActionsWithModifiedStrings,
		ActionsOfFillingInVATTaxation(Object, FormCache),
		True);
	
	FillingResult = CommercialProposalsDocumentsTM.FillInTermsOfPurchaseBasedOnCommercialOffers(Object.Goods, FillParameters);
	FillInServiceDetailsOfAgreements(FillingResult.ModifiedRows);
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Cancel", FillingResult.Cancel);
	ReturnValue.Insert("ErrorText", FillingResult.ErrorText);
	ReturnValue.Insert("LineNumbersWithBlankPurchaseConditions", FillingResult.LineNumbersWithBlankPurchaseConditions);
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#Region CancelLines

&AtClientAtServerNoContext
Procedure HowToUpdateRowSelectionForCanceledRows(Form, HideCancelledRows, SetGoodsMarkToHideCanceledRows = True)
	
	If HideCancelledRows Then
		Form.Items.Goods.RowFilter = New FixedStructure("Canceled", False);
	Else
		Form.Items.Goods.RowFilter = Undefined;
	EndIf;
	
	If SetGoodsMarkToHideCanceledRows Then
		Form.Items.GoodsHideCanceledLines.Check = HideCancelledRows;
	EndIf;
	
EndProcedure

&AtServer
Function AllLinesAreCanceled()
	
	For Each RowOfGoods In Object.Goods Do
		
		If Not RowOfGoods.Canceled Then
			Return False;
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion

#Region DocumentRecording

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormControl

&AtServer
Procedure FormControl()

	FormManagementByWarehouse();
	SetAvailabilityOfItemsWithVAT();
	SetAvailabilityOfItemsByStatusServer();
	Items.RequestedDeliveryDate.Visible = Object.OneDateReceipt;
	Items.GoodsCreatePurchaseOrderForSupplier.Visible =
		Enums.PurchaseRequestStatuses.AgreedUpon(Object.Status)
		And ValueFromTheCache(FormCache, "RightToAddOrderToSupplier");
	
	VisibilityOfLimitingAnalystFields = Documents.PurchaseRequest.MonitorBDRLimits(Object);
	Items.LineOfBusiness.Visible = VisibilityOfLimitingAnalystFields;
	Items.GoodsBudgetFlowItem.Visible = VisibilityOfLimitingAnalystFields;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalListAppearanceClientServer.NewDesignElement(ThisObject,
		Items.GoodsRequestedDeliveryDate.Name,
		"Visible",
		False,
		"Object.OneDateReceipt",
		True);
		
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	SetConditionalAppearanceOfWarehouse();
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject,,, False);
	SetConditionalAppearanceOfDivision();
	EstablishConditionalAppearanceOfAgreement();
	EstablishConditionalAppearanceOfContract();
	
	VendorSpecificItems = New Array;
	VendorSpecificItems.Add(Items.GoodsCounterparty.Name);
	VendorSpecificItems.Add(Items.GoodsPartnerProducts.Name);
	VendorSpecificItems.Add(Items.GoodsVendorPriceKind.Name);
	
	ConditionalListAppearanceClientServer.NewDesignElementForUnavailableField(ThisObject,
		VendorSpecificItems,
		StyleColors.UnavailableTextColor,
		TextSelectSupplier(),
		"Object.Goods.Partner",
		True,
		DataCompositionComparisonType.NotFilled);
	
	ConditionalListAppearanceClientServer.NewDesignElementForUnavailableField(ThisObject,
		Items.GoodsPresentationOfTermsOfPurchase.Name,
		StyleColors.UnavailableTextColor,
		NStr("vi = '<Chưa điền>';
			|ru = '<Не заполнены>';
			|en = '<Not filled in>'; fa = '<Not filled in>';
			|it = '<Not filled in>';
			|pl = '<Not filled in>';
			|tr = '<Doldurulmadı>'"),
		"Object.Goods.PresentationOfTermsOfPurchase",
		True,
		DataCompositionComparisonType.NotFilled);
	
	OrdersServer.SetAppearanceOfCanceledLine(ConditionalAppearance,
		Items.Goods,
		Items.GoodsCanceled.Name,,
		Items.GoodsPrice.Name,
		Items.GoodsSum.Name);
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisObject,
		Items.GoodsVATRate.Name,
		Items.GoodsVATAmount.Name,
		Items.GoodsAmountIncludingVAT.Name,
		"Object.Goods.VATTaxation");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfWarehouse()
	
	// Hidden if specified in the header (not a group):
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject);
	
	ItemReusablePackaging = New ValueList;
	ItemReusablePackaging.Add(Enums.ItemsTypes.OwnGoods);
	ItemReusablePackaging.Add(Enums.ItemsTypes.ReusablePackage);
	
	// Hidden if the item type is not stored in the warehouse:
	AppearanceItem = ConditionalListAppearanceClientServer.NewDesignElement(
		ThisObject,
		Items.GoodsWarehouse.Name,
		"Visible",
		False,
		"Object.Goods.ItemsType",
		ItemReusablePackaging,
		DataCompositionComparisonType.NotInList);
		
	DataCompositionClientServer.AddFilter(AppearanceItem.Filter,
		"Object.Goods.Warehouse",
		True,
		DataCompositionComparisonType.NotFilled);
	
	// Editing is prohibited if the item type is not stored in the warehouse:
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.ToCheckWhetherWarehouseIsFull = True;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	// Mark blank:
	AppearanceItem = ConditionalListAppearanceClientServer.NewSimpleDesignElementWithDesignParameter(
		ThisObject,
		Items.GoodsWarehouse.Name,
		"MarkIncomplete",
		True);
		
	DataCompositionClientServer.AddFilter(AppearanceItem.Filter,
		"Object.Goods.Warehouse",
		True,
		DataCompositionComparisonType.NotFilled);
		
	DataCompositionClientServer.AddFilter(AppearanceItem.Filter,
		"Object.Goods.ItemsType",
		ItemReusablePackaging,
		DataCompositionComparisonType.InList);
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "GoodsWarehouse", "Object.Goods.Warehouse", "Object.Goods.WarehouseIsRequired");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfDivision()
	
	ItemReusablePackaging = New ValueList;
	ItemReusablePackaging.Add(Enums.ItemsTypes.OwnGoods);
	ItemReusablePackaging.Add(Enums.ItemsTypes.ReusablePackage);
	
	// Disabling visibility if a warehouse is specified in the table:
	AppearanceItem = ConditionalListAppearanceClientServer.NewSimpleDesignElementWithDesignParameter(
		ThisObject,
		Items.GoodsDepartment.Name,
		"Visible",
		False);
	 
	DataCompositionClientServer.AddFilter(
		AppearanceItem.Filter,
		"Object.Goods.ItemsType",
		ItemReusablePackaging,
		DataCompositionComparisonType.InList);
		
	DataCompositionClientServer.AddFilter(
		AppearanceItem.Filter,
		"WarehouseGroup_",
		True);
		
	// Explanatory inscription if the warehouses are not in the tabular part:
	AppearanceItem = ConditionalListAppearanceClientServer.NewSimpleDesignElement(
		ThisObject,
		Items.GoodsDepartment.Name);
		
	AppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	AppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<cho dịch vụ và công việc>';
															|ru = '<для услуг и работ>';
															|en = '<for services and works>'; fa = '<for services and works>';
															|it = '<per servizi e lavori>';
															|pl = '<dla usług i prac>';
															|tr = '<iş ve hizmetler için>'"));
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	AppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
		
	DataCompositionClientServer.AddFilter(AppearanceItem.Filter,
		"Object.Goods.ItemsType",
		ItemReusablePackaging,
		DataCompositionComparisonType.InList);
	
	DataCompositionClientServer.AddFilter(
		AppearanceItem.Filter,
		"WarehouseGroup_",
		False);
	
	// Disabling verification for agency procurement:
	AppearanceItem = ConditionalListAppearanceClientServer.NewSimpleDesignElementWithDesignParameter(
		ThisObject,
		Items.GoodsDepartment.Name,
		"MarkIncomplete",
		False);
		
	DataCompositionClientServer.AddFilter(AppearanceItem.Filter,
		"Object.Goods.ItemsType",
		Enums.ItemsTypes.Work_5);
		
	DataCompositionClientServer.AddFilter(AppearanceItem.Filter,
		"Object.Goods.AssignmentType",
		Enums.AssignmentTypes.DeliveryForPrincipal);
		
EndProcedure

&AtServer
Procedure SetParametersForSelectingProductsWarehouse()
	
	Query = New Query(
	"SELECT ALLOWED
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY(&GroupOfWarehouses)
	|	AND Warehouses.IsFolder = FALSE
	|	AND Warehouses.SelectGroup <> VALUE(Enum.SelectWarehouseGroup.Disable)");

	Query.SetParameter("GroupOfWarehouses", Object.Warehouse);
	AvailableWarehouses = Query.Execute().Unload().UnloadColumn("Ref");
	
	Items.GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	TMCommonUseClientServer.AddSelectionParameter(Items.GoodsWarehouse, "Ref", AvailableWarehouses);

EndProcedure

&AtClient
Procedure SetSelectionOfPartnerItem()
	
	KeyWasChanged = False;
	CurrentData = Items.Goods.CurrentData;
	PartnerItemSelection = ValueFromTheCache(FormCache, "PartnerItemSelection");
	
	For Each KeyAndValue In PartnerItemSelection Do
		
		If CurrentData[KeyAndValue.Key] <> KeyAndValue.Value Then
			KeyWasChanged = True;
			Break;
		EndIf;
		
	EndDo;
	
	If Not KeyWasChanged Then
		Return;
	EndIf;
	
	FillPropertyValues(PartnerItemSelection, CurrentData);
	
	PartnersProductsClient.FillInPartnerProductSelectionList(
		PartnerItemSelection.Partner,
		CurrentData,
		Items.GoodsPartnerProducts.ChoiceList);
		
	Items.PartnerProducts.ChoiceList.Clear();
	CommonClientServer.SupplementList(
		Items.PartnerProducts.ChoiceList,
		Items.GoodsPartnerProducts.ChoiceList,
		False);
		
	PartnersProductsClient.SetPackageSelectionParameters(
		Items.GoodsPartnerProducts.ChoiceParameters,
		CurrentData);
		
	PartnersProductsClient.SetPackageSelectionParameters(
		Items.PartnerProducts.ChoiceParameters,
		CurrentData);
		
EndProcedure

&AtClientAtServerNoContext
Procedure SetWhetherWarehouseIsFull(Form)
	
	Form.WarehouseIsRequired = ?(Form.Object.Goods.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

#EndRegion

#Region GoodsLineManagement

&AtClient
Procedure GoodsLineManagement()
	
	RowOfGoods = Items.Goods.CurrentData;
	
	SetAvailabilityOfAgreement(RowOfGoods);
	SetContractAvailability(RowOfGoods);
	
	VendorSpecificItemsAreAvailable = False;
	HintForEnteringVendorSpecificItems = "";
	LineIsHighlighted = True;
	
	If RowOfGoods = Undefined Then
		// Items are unavailable
		LineIsHighlighted = False;
	ElsIf Not ValueIsFilled(RowOfGoods.Partner) Then
		HintForEnteringVendorSpecificItems = TextSelectSupplier();
	Else
		VendorSpecificItemsAreAvailable = True;
	EndIf;
		
	VendorSpecificItems = New Array;
	VendorSpecificItems.Add(Items.Counterparty);
	VendorSpecificItems.Add(Items.PartnerProducts);
	VendorSpecificItems.Add(Items.VendorPriceKind);
	
	For Each FormItem // FormField
		In VendorSpecificItems Do 
		
		FormItem.Enabled    = VendorSpecificItemsAreAvailable;
		FormItem.InputHint = HintForEnteringVendorSpecificItems;
		 
	EndDo;
	
	ActivationParametersOnClient = New Structure;
	HeaderData_ = New Structure;
	HeaderData_.Insert("Date", Object.Date);
	HeaderData_.Insert("Ref", Object.Ref);
	ActivationParametersOnClient.Insert("HeaderData_", HeaderData_);
	
	RowData = New Structure;
	RowData.Insert("Counterparty", PredefinedValue("Catalog.Counterparties.EmptyRef"));
	RowData.Insert("Contract", PredefinedValue("Catalog.CounterpartyContracts.EmptyRef"));
	RowData.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.EmptyRef"));
	RowData.Insert("VATTaxation", PredefinedValue("Enum.VATTaxationTypes.EmptyRef"));
	RowData.Insert("VATRate", PredefinedValue("Catalog.VATRates.EmptyRef"));
	ActivationParametersOnClient.Insert("RowData", RowData);
	If LineIsHighlighted Then
		FillPropertyValues(RowData, RowOfGoods);
	EndIf;
	
	ActivationParameters = LineActivationParameters(ActivationParametersOnClient);
	
	Items.VATTaxation.Enabled = ActivationParameters.TaxationAccessibility;
	Items.VATTaxation.ChoiceList.Clear();
	CommonClientServer.SupplementList(
		Items.VATTaxation.ChoiceList,
		ActivationParameters.TaxationSelectionList,
		False);
	
	Items.GoodsVATTaxation.ReadOnly = Not ActivationParameters.TaxationAccessibility;
	Items.GoodsVATTaxation.ChoiceList.Clear();
	CommonClientServer.SupplementList(
		Items.GoodsVATTaxation.ChoiceList,
		ActivationParameters.TaxationSelectionList,
		False);
	
	TypesOfTaxationWithoutVAT = VATAccountingERPClientServer.TypesOfTaxationThatHideVATDetails(Items.GoodsVATRate);
	BlockVATAttributes = Not LineIsHighlighted
		Or TypesOfTaxationWithoutVAT.Find(RowData.VATTaxation) <> Undefined;
		
	BlockVATAmount = BlockVATAttributes
		Or Not ValueIsFilled(RowData.VATRate)
		Or ActivationParameters.VATRate0;
	
	// If the line is unavailable, the elements must be decorated in the same style:
	Items.Partner.Enabled   = LineIsHighlighted;
	Items.VATRate.Enabled = Not BlockVATAttributes;
	Items.Price.Enabled      = LineIsHighlighted;
	Items.Sum.Enabled     = LineIsHighlighted;
	Items.VATAmount.Enabled  = Not BlockVATAmount;
	Items.AmountIncludingVAT.Enabled = LineIsHighlighted;
	
EndProcedure

&AtServerNoContext
Function LineActivationParameters(ActivationParametersOnClient)
	
	// The element cannot be transferred from the client to the server,
	//    and the modification of the value in the table differs from the modification in the header.
	//    Therefore, we use the structure as an adapter to obtain the necessary properties.
	FormItemDescription = New Structure;
	FormItemDescription.Insert("ChoiceList", New ValueList);
	FormItemDescription.Insert("Visible",    True);
	FormItemDescription.Insert("Title",    "");
	
	FillParameters          = VATAccountingERPClientServer.ParametersOfBatchFillingInOfTaxationVATPurchases();
	FillParameters.Date     = ActivationParametersOnClient.HeaderData_.Date;
	FillParameters.Document = ActivationParametersOnClient.HeaderData_.Ref;
	
	VATTaxationParameters = Documents.PurchaseRequest.VATTaxationParameters(
		ActivationParametersOnClient.RowData,
		FillParameters);
	
	VATAccountingERP.FillInListOfVATTaxChoices(
		FormItemDescription,
		ActivationParametersOnClient.RowData.VATTaxation,
		VATTaxationParameters);
	
	VATRate0 = Not ValueIsFilled(ActivationParametersOnClient.RowData.VATRate)
		Or VATAccountingERP.InsignificantRate(ActivationParametersOnClient.RowData.VATRate);
	
	ReturnValue = New Structure;
	ReturnValue.Insert("TaxationSelectionList", FormItemDescription.ChoiceList);
	ReturnValue.Insert("TaxationAccessibility", FormItemDescription.Visible);
	ReturnValue.Insert("VATRate0", VATRate0);
	
	Return ReturnValue;
	
EndFunction

#Region Terms

&AtClient
Procedure SetAvailabilityOfAgreement(RowOfGoods)
	
	FormItem = Items.Find("Terms");
	If FormItem = Undefined Then
		Return;
	EndIf;
	
	ItemIsAvailable = False;
	InputHint = "";
	
	If RowOfGoods = Undefined Then
		// Item Not Available
	ElsIf ValueIsFilled(RowOfGoods.Terms) Then
		ItemIsAvailable = True; // An invalid agreement must be available
	ElsIf Not ValueIsFilled(RowOfGoods.Partner) Then
		InputHint = TextSelectSupplier();
	ElsIf RowOfGoods.NumberOfAgreements = 0 Then
		InputHint = NStr("vi = '<không có thỏa thuận>';
						|ru = '<соглашения отсутствуют>';
						|en = '<purchase terms are missing>'; fa = '<purchase terms are missing>';
						|it = '<purchase terms are missing>';
						|pl = '<purchase terms are missing>';
						|tr = '<anlaşma yok>'");
	Else
		ItemIsAvailable = True;
	EndIf;

	FormItem.Enabled    = ItemIsAvailable;
	FormItem.InputHint = InputHint;
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceOfAgreement()
	
	TagName = Items.GoodsTerms.Name;
	
	AppearanceItem = ConditionalListAppearanceClientServer.NewDesignElementForUnavailableField(ThisObject,
		TagName,
		StyleColors.UnavailableTextColor,
		NStr("vi = '<không có thỏa thuận>';
			|ru = '<соглашения отсутствуют>';
			|en = '<purchase terms are missing>'; fa = '<purchase terms are missing>';
			|it = '<purchase terms are missing>';
			|pl = '<purchase terms are missing>';
			|tr = '<anlaşma yok>'"),
		"Object.Goods.NumberOfAgreements",
		True,
		DataCompositionComparisonType.NotFilled);
		
	// An invalid agreement must be available
	DataCompositionClientServer.AddFilter(AppearanceItem.Filter,
		"Object.Goods.Terms",
		True,
		DataCompositionComparisonType.NotFilled);
		
	ConditionalListAppearanceClientServer.NewDesignElementForUnavailableField(ThisObject,
		TagName,
		StyleColors.UnavailableTextColor,
		TextSelectSupplier(),
		"Object.Goods.Partner",
		True,
		DataCompositionComparisonType.NotFilled);
	
EndProcedure

#EndRegion

#Region Contract

&AtClient
Procedure SetContractAvailability(RowOfGoods)
	
	FormItem = Items.Find("Contract");
	If FormItem = Undefined Then
		Return;
	EndIf;
	
	ItemIsAvailable = False;
	InputHint = "";
	If RowOfGoods = Undefined Then
		// Item Not Available
	ElsIf Not ValueIsFilled(Object.Organization) Then
		InputHint = NStr("vi = '<chọn doanh nghiệp>';
						|ru = '<выберите организацию>';
						|en = '<select company>'; fa = '<select company>';
						|it = '<select company>';
						|pl = '<select company>';
						|tr = '<iş yerini seçin>'");
	ElsIf Not ValueIsFilled(RowOfGoods.Partner) Then
		InputHint = TextSelectSupplier();
	ElsIf Not ValueIsFilled(RowOfGoods.Counterparty) Then
		InputHint = NStr("vi = '<chọn đối tác>';
						|ru = '<выберите контрагента>';
						|en = '<select a counterparty>'; fa = '<select a counterparty>';
						|it = '<select a counterparty>';
						|pl = '<select a counterparty>';
						|tr = '<cari hesabı seçin>'");
	ElsIf Not RowOfGoods.ContractsAreUsed Then
		InputHint = NStr("vi = '<không sử dụng>';
						|ru = '<не используется>';
						|en = '<not used>'; fa = '<استفاده نمی‌شود>';
						|it = '<non viene utilizzato>';
						|pl = '<nie używa się>';
						|tr = '<kullanılmayan>'");
	Else
		ItemIsAvailable = True;
	EndIf;
	
	FormItem.Enabled    = ItemIsAvailable;
	FormItem.InputHint = InputHint;
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceOfContract()
	
	TagName = Items.GoodsContract.Name;
	
	ConditionalListAppearanceClientServer.NewDesignElementForUnavailableField(ThisObject,
		TagName,
		StyleColors.UnavailableTextColor,
		NStr("vi = '<không sử dụng>';
			|ru = '<не используется>';
			|en = '<not used>'; fa = '<استفاده نمی‌شود>';
			|it = '<non viene utilizzato>';
			|pl = '<nie używa się>';
			|tr = '<kullanılmayan>'"),
		"Object.Goods.ContractsAreUsed",
		False);
	
	ConditionalListAppearanceClientServer.NewDesignElementForUnavailableField(ThisObject,
		TagName,
		StyleColors.UnavailableTextColor,
		NStr("vi = '<chọn đối tác>';
			|ru = '<выберите контрагента>';
			|en = '<select a counterparty>'; fa = '<select a counterparty>';
			|it = '<select a counterparty>';
			|pl = '<select a counterparty>';
			|tr = '<cari hesabı seçin>'"),
		"Object.Goods.Counterparty",
		True,
		DataCompositionComparisonType.NotFilled);
		
	ConditionalListAppearanceClientServer.NewDesignElementForUnavailableField(ThisObject,
		TagName,
		StyleColors.UnavailableTextColor,
		TextSelectSupplier(),
		"Object.Goods.Partner",
		True,
		DataCompositionComparisonType.NotFilled);
		
	ConditionalListAppearanceClientServer.NewDesignElementForUnavailableField(ThisObject,
		TagName,
		StyleColors.UnavailableTextColor,
		NStr("vi = '<chọn doanh nghiệp>';
			|ru = '<выберите организацию>';
			|en = '<select company>'; fa = '<select company>';
			|it = '<select company>';
			|pl = '<select company>';
			|tr = '<iş yerini seç>'"),
		"Object.Organization",
		True,
		DataCompositionComparisonType.NotFilled);
	
EndProcedure

#EndRegion

&AtServer
Procedure SetAvailabilityOfItemsWithVAT()
	
	Items.GoodsAmountIncludingVAT.Visible = Not Object.PriceIncludesVAT;
	Items.AmountIncludingVAT.Visible       = Not Object.PriceIncludesVAT;
	
EndProcedure

&AtClientAtServerNoContext
Function TextSelectSupplier()
	Return NStr("vi = '<chọn nhà cung cấp>';
				|ru = '<выберите поставщика>';
				|en = '<select vendor>'; fa = '<select vendor>';
				|it = '<selezionare il fornitore>';
				|pl = '<wybierz dostawcę>';
				|tr = '<tedarikçi seçin>'");
EndFunction

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel) 
	
	If Not ValueIsFilled(Object.Currency) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Tiền tệ""';
										|ru = 'Поле ""Валюта"" не заполнено';
										|en = '""Currency"" is required'; fa = '""Currency"" is required';
										|it = 'Il campo ""Valuta"" non è compilato';
										|pl = 'Pole ""Waluta"" nie jest wypełnione';
										|tr = '""Para Birimi"" alanı doldurulmadı'"), Object.Ref, "Object.Currency",,Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	SelectedGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	Actions = New Structure;
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, True));
	Actions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	Actions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	
	CommonClientServer.SupplementStructure(Actions, ActionsOfFillingInVATTaxation(Object, FormCache), True);
	CommonClientServer.SupplementStructure(Actions, ActionsForRecalculatingAmount(Object.PriceIncludesVAT), True);
	
	RowsToProcess = New Array;
	
	For Each SelectedString_ In SelectedGoods Do
		
		RowOfGoods = Object.Goods.Add();
		FillPropertyValues(RowOfGoods, SelectedString_, 
			"PartnerProducts, Products, Characteristic, Package, Warehouse, 
			|VendorPriceKind, Price, NumberOfPackages, Count, Sum");
		
		If Object.OneDateReceipt Then
			RowOfGoods.RequestedDeliveryDate = Object.RequestedDeliveryDate;
		EndIf;
		
		RowsToProcess.Add(RowOfGoods);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		Actions,
		Object.Goods);
	
	For Each RowOfGoods In RowsToProcess Do
		UpdateDivisionOfGoodsLine(RowOfGoods, Object.Department);
	EndDo;
		
	If ControlProductRange(FormCache) Then
		ProductRangeServer.CheckAssortmentOfTableOfSelectedProducts(Object, "Warehouse", SelectedGoods);
	EndIf;

	CalculateFinalIndicatorsOfApplication(ThisObject);
	UpdateWarehouseGroupImage();

EndProcedure

#EndRegion

#Region FormCache

&AtServer
Procedure InitializeFormCache()

	FormCache = New Structure;
		
	SetValueInCache(FormCache,
		"FinalStatuses",
		Enums.PurchaseRequestStatuses.FinalStatuses());
	
	SetValueInCache(FormCache,
		"AvailableTypesOfContracts",
		Documents.PurchaseRequest.AvailableTypesOfContracts());
		
	SaveSpecifiedVATRATE(FormCache, Catalogs.VATRates.EmptyRef());
	MaintainAssortmentControl(FormCache, Object.Warehouse, Object.Date);
	
	SetValueInCache(FormCache,
		"NamesOfDetailsOfTermsOfPurchase",
		Documents.PurchaseRequest.NamesOfDetailsOfTermsOfPurchase());
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	PartnerItemSelection = New Structure;
	PartnerItemSelection.Insert("Partner");
	PartnerItemSelection.Insert("Products");
	PartnerItemSelection.Insert("Characteristic");
	PartnerItemSelection.Insert("Package");
	SetValueInCache(FormCache,
		"PartnerItemSelection",
		PartnerItemSelection);
	
	SetValueInCache(FormCache,
		"RightToAddOrderToSupplier",
		AccessRight("Insert", Metadata.Documents.PurchaseOrder));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetValueInCache(FormCache, PropertyName, PropertyValue)
	
	If Not FormCache.Property(PropertyName) Then
		
		FormCache.Insert(PropertyName);
		
	EndIf;
	
	FormCache[PropertyName] = PropertyValue;
	
EndProcedure

// The value from the cache.
// 
// Parameters:
//  FormCache - Structure - Form Attributes of the same name
//  PropertyName - String - The name of the property in the cache, set via "Set the value of the cache"
// 
// Returns:
//  Arbitrary - Previously saved value
&AtClientAtServerNoContext
Function ValueFromTheCache(FormCache, PropertyName)
	
	Return FormCache[PropertyName];
	
EndFunction

&AtClientAtServerNoContext
Function AvailableTypesOfContracts(FormCache)
	Return ValueFromTheCache(FormCache, "AvailableTypesOfContracts");
EndFunction

#Region SavedVATRate

&AtClientAtServerNoContext
Procedure SaveSpecifiedVATRATE(FormCache, SpecifiedVATRate)
	SetValueInCache(FormCache, "SpecifiedVATRate", SpecifiedVATRate);
EndProcedure

&AtClientAtServerNoContext
Function SpecifiedVATRate(FormCache)
	Return ValueFromTheCache(FormCache, "SpecifiedVATRate");
EndFunction

#EndRegion

#Region AssortmentControl

&AtServerNoContext
Procedure MaintainAssortmentControl(FormCache, Warehouse, Date)
	
	 SetValueInCache(FormCache,
	 	"ControlProductRange",
	 	ProductRangeServerCached.ControlProductRange(Warehouse, Date));
	
EndProcedure
	
&AtClientAtServerNoContext
Function ControlProductRange(FormCache)
	
	Return ValueFromTheCache(FormCache, "ControlProductRange");
	
EndFunction

&AtClientAtServerNoContext
Function AssortmentVerificationParameters(Object)
	
	ReturnValue = ProductRangeClientServer.AssortmentVerificationParameters();
	ReturnValue.Ref = Object.Ref;
	ReturnValue.Warehouse = Object.Warehouse;
	ReturnValue.Date = ?(ValueIsFilled(Object.RequestedDeliveryDate), Object.RequestedDeliveryDate, Object.Date);
	ReturnValue.MessageText = NStr("vi = 'Hàng hóa %1 không thuộc danh điểm cửa hàng. Không nên đặt mua mặt hàng này.';
									|ru = 'Товар %1 не включен в ассортимент магазина. Заказывать его не рекомендуется.';
									|en = 'Item ""%1"" is not in this selling point''s product range. Please reconsider adding it to the order.'; fa = 'Item ""%1"" is not in this selling point''s product range. Please reconsider adding it to the order.';
									|it = 'Il prodotto %1 non è incluso nell''assortimento del negozio. Ordinarlo non è consigliabile.';
									|pl = 'Towar %1 nie jest włączony do asortymentu sklepu. Nie zaleca się zamawiać go.';
									|tr = 'Ürün%1 mağazanın ürün yelpazesine dahil değildir. Sipariş edilmesi tavsiye edilmez.'");
	ReturnValue.NameOfAssortmentResource = "PurchasesAreAllowed";
	ReturnValue.CheckedYouCanAdd = True;
	ReturnValue.AllowAdding = True;
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#EndRegion

#Region BatchProcessingOfTablePart

&AtClientAtServerNoContext
Function ActionsWhenChangingQuantity(PriceIncludesVAT)
	
	Actions = PurchaseRequestClientServer.ActionsWhenChangingQuantity(PriceIncludesVAT);
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInSummaryDetailsOfForm(), True);
	
	Return Actions;
	
EndFunction

&AtClientAtServerNoContext
Function ActionsForFillingInPriceType(Object)

	Actions = PurchaseRequestClientServer.ActionsForFillingInPriceType(Object);
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInSummaryDetailsOfForm(), True);
	
	Return Actions;
	
EndFunction

&AtClientAtServerNoContext
Function ActionsToFillInPrice(Object)

	Actions = PurchaseRequestClientServer.ActionsToFillInPrice(Object);
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInSummaryDetailsOfForm(), True);
	
	Return Actions;
	
EndFunction

&AtClientAtServerNoContext
Function ActionsOfFillingInVATTaxation(Object, FormCache)
	
	SpecifiedVATRate = SpecifiedVATRate(FormCache);
	Actions = PurchaseRequestClientServer.ActionsOfFillingInVATTaxation(Object, SpecifiedVATRate);
	
	// Since taxation may change the VAT rate, it is necessary to recalculate the amounts.
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInSummaryDetailsOfForm(), True);
	
	Return Actions; 
	
EndFunction

&AtClientAtServerNoContext
Function ActionsForFillingInVATRate(Object, FormCache)

	SpecifiedVATRate = SpecifiedVATRate(FormCache);
	Actions = PurchaseRequestClientServer.ActionsForFillingInVATRate(Object, SpecifiedVATRate);
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInSummaryDetailsOfForm(), True);
	
	Return Actions;
		
EndFunction

&AtClientAtServerNoContext
Function ActionsForRecalculatingAmount(PriceIncludesVAT, RecalculateAmount = True, RecalculateVATAmount = True)
	
	Actions = PurchaseRequestClientServer.ActionsForRecalculatingAmount(PriceIncludesVAT, RecalculateAmount, RecalculateVATAmount);
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInSummaryDetailsOfForm(), True);
	
	Return Actions;
	
EndFunction

&AtClientAtServerNoContext
Function ActionsForFillingInSummaryDetailsOfForm()
	
	DescriptionOfDuplicates = New Structure("Canceled", "VATAmount, AmountIncludingVAT");
	Actions = New Structure;
	Actions.Insert("FillInDuplicateDependentDetails", DescriptionOfDuplicates);
	Actions.Insert("FillInPresentationOfTermsOfPurchase");
	
	Return Actions
	
EndFunction

&AtServer
Procedure FillInServiceDetailsOfAgreements(ProductLines_2 = Undefined)
	
	Actions = New Structure;
	
	ParametersForFillingOutAgreement = BatchProcessingOfTablePartClientServer.ParametersForFillingOutSupplierAgreements();
	
	// The Attributes to be filled in are used only for interactive work and do not participate in batch processing.
	Actions.Insert("FillInAttributesAccordingToSupplierSAgreement"); 
	
	// It is filled in in privileged mode. You can't add it to the general request package.
	Actions.Insert("FillInNumberOfSupplierAgreements", ParametersForFillingOutAgreement); 
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	If ProductLines_2 = Undefined Then
		
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods,
			Actions,
			CachedValues);
	
	ElsIf TypeOf(ProductLines_2) = Type("Array") Then
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(ProductLines_2,
			Actions,
			Object.Goods,
			CachedValues);
		
	Else
		
		BatchProcessingOfTablePartServer.ProcessTSString(ProductLines_2,
			Actions,
			CachedValues);
	
	EndIf;
	
EndProcedure

// Recalculates the VAT amount in the rows of the table part for rows 
// in which the VAT rate was changed after calling the action "Adjust the Seconds" of processing the table part.
// Parameters:
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
&AtServer
Procedure RecalculateVATAmountAtAdjustedRates(CachedValues)
	
	If CachedValues = Undefined Then
		Return; // Batch processing was not initialized because there are no lines to process.
	EndIf;
	
	Actions = ActionsForRecalculatingAmount(Object.PriceIncludesVAT, False, True);
	BatchProcessingOfTablePartServer.ProcessTSStrings(CachedValues.ProcessedRows,
		Actions,
		Object.Goods,
		CachedValues);
	CachedValues.ProcessedRows.Clear();
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

#EndRegion

#Region IntegratedSubsystems

#Region Protocol

&AtClient
Procedure Attachable_ONChangeOfProtocol(ChangesDetails, AdditionalParameters = Undefined) Export
	
	If Not ChangesDetails.ChangedProperties.Property("Status") Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("OnChangingStatusAfterQuestion", ThisObject);
	
	If Object.Status = PredefinedValue("Enum.PurchaseRequestStatuses.Closed_")
		And ThereAreLinesThatAreNotOrdered() Then
		
		QueryText = NStr("vi = 'Trong chứng từ có các dòng mà chưa lập đơn hàng đặt nhà cung cấp. Hủy các mặt hàng chưa đặt mua?';
						|ru = 'В документе присутствуют строки, по которым не сформированы заказы поставщикам. Отменить незаказанные товары?';
						|en = 'The document contains lines for which there are no purchase orders generated. Cancel unordered items?'; fa = 'The document contains lines for which there are no purchase orders generated. Cancel unordered items?';
						|it = 'The document contains lines for which there are no purchase orders generated. Cancel unordered items?';
						|pl = 'The document contains lines for which there are no purchase orders generated. Cancel unordered items?';
						|tr = 'Belgede satın alma siparişleri oluşturulmamış satırlar var. Siparişi verilmeyen mallar iptal edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		RunCallback(CallbackDescription, DialogReturnCode.No);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangingStatusAfterQuestion(AnswerIsToCancelLinesThatWereNotOrdered, AdditionalParameters = Undefined) Export
	
	UndoLinesThatAreNotOrdered = AnswerIsToCancelLinesThatWereNotOrdered = DialogReturnCode.Yes;
	OnChangeOfStatusATServer(UndoLinesThatAreNotOrdered);
	
EndProcedure

&AtServer
Procedure OnChangeOfStatusATServer(UndoLinesThatAreNotOrdered)
	
	If UndoLinesThatAreNotOrdered Then
		UndoLinesThatAreNotOrderedServer();
	EndIf;
	
	If Not Enums.PurchaseRequestStatuses.AgreedUpon(Object.Status) Then
		// The application can be closed or returned to work without re-approval
		Object.Approved = False;
	EndIf;
	
	FormControl();
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

#EndRegion

#Region LoadingFromFile

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
		SetWhetherWarehouseIsFull(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	Actions = New Structure;
	Actions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	Actions.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	Actions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled", True, True));
	
	CommonClientServer.SupplementStructure(Actions, ActionsOfFillingInVATTaxation(Object, FormCache), True);
	CommonClientServer.SupplementStructure(Actions, ActionsWhenChangingQuantity(Object.PriceIncludesVAT), True);
	
	RowsToProcess = New Array;
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	For Each SourceRow In ItemsFromStorage Do
		RowOfGoods = Object.Goods.Add();
		FillPropertyValues(RowOfGoods, SourceRow);
		RowsToProcess.Add(RowOfGoods);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		Actions,
		Object.Goods);
	
	For Each RowOfGoods In RowsToProcess Do
		UpdateDivisionOfGoodsLine(RowOfGoods, Object.Department);
	EndDo;
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	UpdateWarehouseGroupImage();
	
EndProcedure

#EndRegion

#Region AttachableCommands

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

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// Standard subsystems.Pluggable Commands
//
// A utility method for making a contextual call to the server from the "Pluggable Commands" subsystem.
// Parameters:
//  ExecutionParameters - Structure
//  AdditionalParameters - Arbitrary - not use.
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ActionsWhenChangingQuantity = ActionsWhenChangingQuantity(Object.PriceIncludesVAT);
	
	ActionsWithAddedLines = New Structure;
	
	CommonClientServer.SupplementStructure(ActionsWithAddedLines, ActionsToFillInPrice(Object), True);
	CommonClientServer.SupplementStructure(ActionsWithAddedLines, ActionsForFillingInVATRate(Object, FormCache), True);
	
	ActionsWithAddedLines.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
	ActionsWithAddedLines.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ActionsWithAddedLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ActionsWithAddedLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ActionsWithAddedLines.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled", True, True));
	
	CommonClientServer.SupplementStructure(ActionsWithAddedLines, ActionsOfFillingInVATTaxation(Object, FormCache), True);
	CommonClientServer.SupplementStructure(ActionsWithAddedLines, ActionsWhenChangingQuantity, True);
	
	ActionsWithModifiedStrings = New Structure;
	CommonClientServer.SupplementStructure(ActionsWithModifiedStrings, ActionsWhenChangingQuantity, True);
	
	BarcodeProcessingParameters = BarcodingOfItemsClient.BarcodeProcessingParameters();
	BarcodeProcessingParameters.Barcodes                              = BarcodeData_5;
	BarcodeProcessingParameters.StructureOfActionsWithAddedStrings = ActionsWithAddedLines;
	BarcodeProcessingParameters.StructureOfActionsWithModifiedStrings  = ActionsWithModifiedStrings;
	
	If ControlProductRange(FormCache) Then
		BarcodeProcessingParameters.AssortmentVerificationParameters = AssortmentVerificationParameters(Object);
	EndIf;
		
	ProcessBarcodesServer(BarcodeProcessingParameters, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(BarcodeProcessingParameters, CachedValues, ThisObject);
	
	If BarcodeProcessingParameters.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = BarcodeProcessingParameters.CurrentRow;
		RowOfGoods = Items.Goods.CurrentData;
		
		If Object.OneDateReceipt Then
			RowOfGoods.RequestedDeliveryDate = Object.RequestedDeliveryDate;
		EndIf;
		
		UpdateDivisionOfGoodsLine(RowOfGoods, Object.Department);
		
	EndIf;
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	SetWhetherWarehouseIsFull(ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(BarcodeProcessingParameters, CachedValues)
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, BarcodeProcessingParameters, CachedValues);
	RecalculateVATAmountAtAdjustedRates(CachedValues);
EndProcedure

#EndRegion

#Region FilesOperations

// StandardSubsystems.FilesOperations
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
// End StandardSubsystems.FilesOperations

#EndRegion

#Region Properties

// StandardSubsystems.Properties 
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
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

#EndRegion

#Region IntegrationWith1CDocumentManagementSubsystem

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

//@skip-check invocation-form-event-handler - Implementation features.
// Event handlers are reassigned to the "subscription", then the original handler is called.
#Region ControlOfInconsistentChanges

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemsNames = New Array;
	
	// Header:
	ItemsNames.Add(Items.Date.Name);
	ItemsNames.Add(Items.Organization.Name);
	ItemsNames.Add(Items.Department.Name);
	ItemsNames.Add(Items.Warehouse.Name);
	
	ItemsNames.Add(Items.Currency.Name);
	ItemsNames.Add(Items.PriceIncludesVAT.Name);
	ItemsNames.Add(Items.OneDateReceipt.Name);
	ItemsNames.Add(Items.RequestedDeliveryDate.Name);
	
	// goods:
	ItemsNames.Add("Goods;BeforeAddRow,BeforeDeleteRow");
	ItemsNames.Add(Items.GoodsProducts.Name);
	ItemsNames.Add(Items.GoodsCharacteristic.Name);
	ItemsNames.Add(Items.GoodsNumberOfPackages.Name);
	ItemsNames.Add(Items.GoodsPackage.Name);
	ItemsNames.Add(Items.GoodsWarehouse.Name);
	ItemsNames.Add(Items.GoodsCanceled.Name);
	ItemsNames.Add(Items.GoodsRequestedDeliveryDate.Name);
	
	For Each AttributeName In ValueFromTheCache(FormCache, "NamesOfDetailsOfTermsOfPurchase") Do
		
		ItemsNames.Add(Items[AttributeName].Name);
		ItemsNames.Add(Items["Goods" + AttributeName].Name);
		
	EndDo;
	
	// Commands (products):
	ItemsNames.Add(Items.GoodsInsertRows.Name);
	ItemsNames.Add(Items.GoodsSearchByBarcode.Name);
	ItemsNames.Add(Items.GoodsImportDataFromPDT.Name);
	ItemsNames.Add(Items.GoodsInsertPurchaseConditions.Name);
	ItemsNames.Add(Items.GoodsFillInTermsOfPurchaseBasedOnCommercialOffers.Name);
	ItemsNames.Add(Items.ProductsPickUpTheNomenclature.Name);
	ItemsNames.Add(Items.GoodsSelectSubstitutes.Name);
	ItemsNames.Add(Items.GoodsImportFromExternalFile.Name);
	
	ItemsNames.Add(Items.GoodsCancelSelectedLines.Name);
	ItemsNames.Add(Items.GoodsUndoLinesThatAreNotOrdered.Name);
	
	ItemsNames.Add(Items.GoodsFillInTheWarehouseInSelectedLines.Name);
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(
		ThisObject,
		ItemsNames);
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	
	TagName = Item.Name;
	
	If ValueFromTheCache(FormCache, "NamesOfDetailsOfTermsOfPurchase").Find(TagName) <> Undefined Then
		// Changing the prefix of an element located in the "basement":
		TagName = "Goods" + TagName;
	EndIf;
	
	If TagName = Items.Date.Name Then
		DateOnChange(Item);
	ElsIf TagName = Items.Organization.Name Then
		OrganizationOnChange(Item);
	ElsIf TagName = Items.Warehouse.Name Then
		WarehouseOnChange(Item);
	ElsIf TagName = Items.Currency.Name Then
		CurrencyOnChange(Item);
	ElsIf TagName = Items.PriceIncludesVAT.Name Then
		PriceIncludesVATOnChange(Item);
	ElsIf TagName = Items.OneDateReceipt.Name Then
		OneDateReceiptOnChange(Item);
	ElsIf TagName = Items.RequestedDeliveryDate.Name Then
		RequestedDeliveryDateOnChange(Item);
	// goods:
	ElsIf TagName = Items.GoodsProducts.Name Then
		GoodsProductsOnChange(Item);
	ElsIf TagName = Items.GoodsCharacteristic.Name Then
		GoodsCharacteristicOnChange(Item);
	ElsIf TagName = Items.GoodsNumberOfPackages.Name Then
		GoodsNumberOfPackagesOnChange(Item);
	ElsIf TagName = Items.GoodsPackage.Name Then
		GoodsPackageOnChange(Item);
	ElsIf TagName = Items.GoodsCanceled.Name Then
		GoodsCanceledOnChange(Item);
	ElsIf TagName = Items.GoodsPartner.Name Then
		GoodsPartnerOnChange(Item);
	ElsIf TagName = Items.GoodsCounterparty.Name Then
		GoodsCounterpartyOnChange(Item);
	ElsIf TagName = Items.GoodsTerms.Name Then
		GoodsTermsOnChange(Item);
	ElsIf TagName = Items.GoodsContract.Name Then
		GoodsContractOnChange(Item);
	ElsIf TagName = Items.GoodsVendorPriceKind.Name Then
		GoodsVendorPriceKindOnChange(Item);
	ElsIf TagName = Items.GoodsPartnerProducts.Name Then
		GoodsPartnerProductsOnChange(Item);
	ElsIf TagName = Items.GoodsPrice.Name Then
		GoodsPriceOnChange(Item);
	ElsIf TagName = Items.GoodsSum.Name Then
		GoodsSumOnChange(Item);
	ElsIf TagName = Items.GoodsVATRate.Name Then
		GoodsVATRateOnChange(Item);
	ElsIf TagName = Items.GoodsVATAmount.Name Then
		GoodsVATAmountOnChange(Item);
	ElsIf TagName = Items.GoodsPurpose.Name Then
		GoodsPurposeOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)

	If Command.Name = Commands.InsertRows.Name Then
		InsertRows(Command);
	ElsIf Command.Name = Commands.SearchByBarcode.Name Then
		SearchByBarcodeExecute(Command);
	ElsIf Command.Name = Commands.ImportDataFromPDT.Name Then
		ImportDataFromPDT(Command);
	ElsIf Command.Name = Commands.InsertPurchaseConditions.Name Then
		InsertPurchaseConditions(Command);
	ElsIf Command.Name = Commands.FillInTermsOfPurchaseBasedOnCommercialOffers.Name Then
		StartFillingInTermsOfPurchaseBasedOnCommercialOffers(Command);
	ElsIf Command.Name = Commands.SelectGoods.Name Then
		SelectGoods(Command);
	ElsIf Command.Name = Commands.SelectSubstitutes.Name Then
		SelectSubstitutes(Command);
	ElsIf Command.Name = Commands.ImportFromExternalFile.Name Then
		ImportFromExternalFile(Command);
	ElsIf Command.Name = Commands.CancelSelectedLines.Name Then
		CancelSelectedLines(Command);
	ElsIf Command.Name = Commands.UndoLinesThatAreNotOrdered.Name Then
		 UndoLinesThatAreNotOrdered(Command);
	ElsIf Command.Name = Commands.FillInTheWarehouseInSelectedLines.Name Then
		FillInTheWarehouseInSelectedLines(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
// Cancel - Boolean - The event parameter with the same name.
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	
	If Item.Name = "Goods" Then
		GoodsBeforeDeleteRow(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
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
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
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
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
// Cancel - Boolean - The event parameter with the same name.
&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
// Cancel - Boolean - The event parameter with the same name.
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
// Cancel - Boolean - The event parameter with the same name.
// Copy - Boolean - The event parameter with the same name.
// Parent - Undefined - The event parameter with the same name.
// Var_Group - Boolean - The event parameter with the same name.
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item, Cancel, Copy, Parent, Var_Group)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
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
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisObject);
	
EndProcedure

#EndRegion
#Region Substitutes

&AtClient
Procedure OpenSelectionOfAnalogues()
	
	If Not CheckForSelectedLines() Then
		Return;
	EndIf;
	
	AlternativeMaterialsClient.OpenSelectionOfAnalogues(AnalogSelectionParameters(), ThisObject);
	
EndProcedure

// Generates parameters for selecting analogs
// 
// Returns:
//  Structure - See AlternativeMaterials.AnalogSelectionParameters
//
&AtServer
Function AnalogSelectionParameters()

	SourceType = New TypeDescription("DocumentRef.PurchaseRequest");
	FormParameters = AlternativeMaterials.AnalogSelectionParameters(SourceType);
	
	ObjectTable = Object.Goods.Unload();//ValueTable
	ObjectTable.Columns.Add("WithAssignment", New TypeDescription("Boolean"));
	
	FormData1 = New Structure;
	FormData1.Insert("Items", Items);
	FormData1.Insert("UUID", UUID);
	FormData1.Insert("Object", New Structure);
	FormData1.Object.Insert("Goods", ObjectTable.CopyColumns());
	
	For Each TableRow In ObjectTable Do
		
		TableRow.WithAssignment = ValueIsFilled(TableRow.Purpose);
		
		RowID = Object.Goods[TableRow.LineNumber - 1].GetID();
		
		If Items.Goods.SelectedRows.Find(RowID) = Undefined Then
			Continue;
		EndIf;
		
		FormTable = FormData1.Object.Goods; //ValueTable
		FillPropertyValues(FormTable.Add(), TableRow);
		
	EndDo;
	
	// GoodsParameters
	FieldsStructure = AlternativeMaterials.StructureOfTableFieldsToReplaceWithAnalogues();
	FieldsStructure.AdditionalFields.Insert("Ref", New TypeDescription("DocumentRef.PurchaseRequest"));
	FieldsStructure.DefaultValues.Insert("Ref", Object.Ref);
	FieldsStructure.DefaultValues.Insert("Warehouse", Object.Warehouse);
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", New Array);
	RowFilter.Canceled.Add(False);
	
	AddlParameters = AlternativeMaterials.AdditionalParameters();
	AddlParameters.RowFilter     = RowFilter;
	AddlParameters.SourceOfResults = ObjectTable;
	
	ProductData_9 = AlternativeMaterials.GetProductData(
		FormData1, "Object", "Goods", 1, False, FieldsStructure, AddlParameters);
		
	FillPropertyValues(FormParameters.GoodsParameters, ProductData_9);
	
	// SubstitutesParameters
	ParametersTable = FormParameters.SubstitutesParameters.ParametersTable;
	
	TableRow = ParametersTable.Add();
	TableRow.PermissionValidityDate = BegOfDay(CurrentSessionDate());
	TableRow.Ref = Object.Ref;
	
	//@skip-check bsl-legacy-check-expression-type
	FormParameters.SubstitutesParameters.ParametersTable = 
		PutToTempStorage(ParametersTable, UUID);
		
	FormParameters.SubstitutesParameters.Warehouse = Object.Warehouse;
	
	Return FormParameters;
	
EndFunction

&AtServer
Procedure Replace_With_Analogues(AddressInStorage = Undefined)
	
	AdditionalFields = New Array;
	AdditionalFields.Add("VendorPriceKind");
	AdditionalFields.Add("Department");
	AdditionalFields.Add("Warehouse");
	AdditionalFields.Add("Purpose");
	AdditionalFields.Add("Partner");
	AdditionalFields.Add("Counterparty");
	AdditionalFields.Add("Terms");
	AdditionalFields.Add("NumberOfAgreements");
	AdditionalFields.Add("ContractsAreUsed");
	AdditionalFields.Add("Contract");
	AdditionalFields.Add("RequestedDeliveryDate");
	
	Result = AlternativeMaterials.PerformReplacementForAnalogues(
		Object.Goods,
		AddressInStorage,
		StrConcat(AdditionalFields, ", "),
		"Action_Substitutes_ToReserve_");
		
	IndexesOfModifiedRows = Result.IndexesOfModifiedRows;
	IndexesOfNewRows = Result.IndexesOfNewRows;
	
	NumberOfReplacementsMade = IndexesOfModifiedRows.Count() + IndexesOfNewRows.Count();
	MessageText  = StrTemplate(NStr("vi = 'Dòng đã thay đổi: %1';
									|ru = 'Измененных строк: %1';
									|en = 'Changed lines: %1'; fa = 'Changed lines: %1';
									|it = 'Измененных строк: %1';
									|pl = 'Changed lines: %1';
									|tr = 'Değiştirilen satırlar: %1'"), NumberOfReplacementsMade);
	Common.MessageToUser(MessageText);
	
	If NumberOfReplacementsMade = 0 Then
		Return;
	EndIf;
	
	Modified = True;
	
	Actions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	RowsToProcess = New Array;
	CommonClientServer.SupplementStructure(Actions, ActionsWhenChangingQuantity(Object.PriceIncludesVAT), True);
	For Each RowIndex In IndexesOfModifiedRows Do
		RowsToProcess.Add(Object.Goods[RowIndex]);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		Actions,
		Object.Goods,
		CachedValues);
	
	Actions = New Structure;
	
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, True));
	Actions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		Actions.Insert(
		"ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName", FormName, "Goods"));
		
	CommonClientServer.SupplementStructure(Actions, ActionsOfFillingInVATTaxation(Object, FormCache), True);
	CommonClientServer.SupplementStructure(Actions, ActionsToFillInPrice(Object), True);
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInVATRate(Object, FormCache), True);
	
	Actions.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
	Actions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
		
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	RowsToProcess = New Array;
	
	For Each RowIndex In IndexesOfNewRows Do
		RowsToProcess.Add(Object.Goods[RowIndex]);
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		Actions,
		Object.Goods,
		CachedValues);
	
	For Each RowOfGoods In RowsToProcess Do
		UpdateDivisionOfGoodsLine(RowOfGoods, Object.Department);
	EndDo;
	
	If ControlProductRange(FormCache) Then
		ProductRangeServer.CheckAssortmentOfTableOfSelectedProducts(Object, "Warehouse");
	EndIf;
	
	UpdateWarehouseGroupImage();
	CalculateFinalIndicatorsOfApplication(ThisObject);
	
EndProcedure

#EndRegion
#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	Columns.Add("Package");
	Columns.Add("NumberOfPackages");
	Columns.Add("Price");
	Columns.Add("Department");
	Columns.Add("Warehouse");
	Columns.Add("Partner");
	Columns.Add("Counterparty");
	Columns.Add("Terms");
	Columns.Add("Contract");
	
	RowsFromClipboard = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(RowsFromClipboard) Then
		Return;
	EndIf;
	
	Actions = New Structure;
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, True));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	Actions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	
	Actions.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	CommonClientServer.SupplementStructure(Actions, ActionsWhenChangingQuantity(Object.PriceIncludesVAT), True);
	CommonClientServer.SupplementStructure(Actions, ActionsOfFillingInVATTaxation(Object, FormCache), True);
	
	RowsToProcess = New Array;
	For Each LineFromBuffer In RowsFromClipboard Do
		
		RowOfGoods = Object.Goods.Add();
		FillPropertyValues(RowOfGoods, LineFromBuffer);
		RowsToProcess.Add(RowOfGoods);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		Actions,
		Object.Goods);
	
	FillInServiceDetailsOfAgreements(RowsToProcess);
		
	For Each RowOfGoods In RowsToProcess Do
		
		If Object.OneDateReceipt Then
			RowOfGoods.RequestedDeliveryDate = Object.RequestedDeliveryDate;
		EndIf;
		
		UpdateDivisionOfGoodsLine(RowOfGoods, Object.Department);
		
	EndDo;
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	UpdateWarehouseGroupImage();

EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, AccessibilityValue)
	
	ItemsNames = New Array;
	ItemsNames.Add("GoodsInsertRows");
	ItemsNames.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		ItemsNames,
		"Enabled",
		AccessibilityValue);
	
EndProcedure

#EndRegion

#EndRegion

#Region GeneralProceduresAndFunctions

&AtClient
Function CheckForSelectedLines(MultipleSelectionMode = True)
	
	WarningText = "";
	
	If Object.Goods.Count() = 0 Then
		
		WarningText = NStr("vi = 'Chưa điền bảng hàng hóa.';
							|ru = 'Таблица товаров не заполнена.';
							|en = 'Add items to the order.'; fa = 'Add items to the order.';
							|it = 'La tabella delle merci non è compilata.';
							|pl = 'Nie wypełniono tabeli towarów.';
							|tr = 'Mal tablosu eksiktir.'");
		
	ElsIf Items.Goods.SelectedRows.Count() = 0 Then
		
		If MultipleSelectionMode Then
			WarningText = NStr("vi = 'Trong bảng hàng hóa không có các dòng đã chọn.';
								|ru = 'В таблице товаров отсутствуют выделенные строки.';
								|en = 'Select at least one item.'; fa = 'Select at least one item.';
								|it = 'Nella tabella delle merci non ci sono righe selezionate.';
								|pl = 'Brak wybranych wierszy w tabeli towarów.';
								|tr = 'Mallar tablosunda seçili satır yoktur.'");
		Else
			WarningText = NStr("vi = 'Cần chọn dòng hàng hóa.';
								|ru = 'Необходимо выделить строку товаров.';
								|en = 'Select the goods line.'; fa = 'Select the goods line.';
								|it = 'Select the goods line.';
								|pl = 'Select the goods line.';
								|tr = 'Mal satırı seçilmelidir.'");
		EndIf;
		
	EndIf;
	
	CheckPassed = IsBlankString(WarningText);
	If Not CheckPassed Then
		ShowMessageBox(Undefined, WarningText);
	EndIf;
	
	Return CheckPassed;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateDivisionOfGoodsLine(RowOfGoods, Department, ReFill_ = False)
	
	If RowOfGoods.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
		Or RowOfGoods.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
		Or RowOfGoods.ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then

		RowOfGoods.Department = Undefined;

	ElsIf (ReFill_ Or Not ValueIsFilled(RowOfGoods.Department)) 
		And (RowOfGoods.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")
			Or RowOfGoods.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")) Then
			
		RowOfGoods.Department = Department;
	
	EndIf;
	
EndProcedure

#EndRegion

#Region PurchaseOrders

&AtServer
Function DescriptionOfOrderToBeCreated(Val SelectedRows)
	
	LineNumbers = New Array;
	For Each RowID In SelectedRows Do
		LineNumbers.Add(Object.Goods.FindByID(RowID).LineNumber);
	EndDo;
	
	DescriptionOfOrderToBeCreated = Documents.PurchaseRequest.DescriptionOfOrderToBeCreated(Object.Ref, LineNumbers);
	
	If DescriptionOfOrderToBeCreated.OrderData <> Undefined Then
		
		DescriptionOfOrderToBeCreated.OrderData.Goods = PutToTempStorage(
			DescriptionOfOrderToBeCreated.OrderData.Goods,
			UUID);
		
	EndIf;
	
	Return DescriptionOfOrderToBeCreated;
	
EndFunction

&AtServer
Function ThereAreLinesThatAreNotOrdered()
	Return Documents.PurchaseRequest.ThereAreLinesThatAreNotOrdered(Object);
EndFunction

&AtServer
Function UndoLinesThatAreNotOrderedServer()
	
	ReturnValue = New Structure;
	ReturnValue.Insert("WarningText", "");
	ReturnValue.Insert("ThereAreCanceledLines", False);
	
	If Not Object.Posted Then
		ReturnValue.WarningText = NStr("vi = 'Không thể tính số lượng chưa đặt hàng trong chứng từ chưa kết chuyển.';
										|ru = 'Невозможно рассчитать незаказанное количество для непроведенного документа.';
										|en = 'Cannot calculate an unordered quantity for an unposted document.'; fa = 'Cannot calculate an unordered quantity for an unposted document.';
										|it = 'Cannot calculate an unordered quantity for an unposted document.';
										|pl = 'Cannot calculate an unordered quantity for an unposted document.';
										|tr = 'Kaydedilmemiş belge için sipariş verilmeyen miktar hesaplanamaz.'");
	ElsIf Not ValueIsFilled(Object.Goods) Then
		ReturnValue.WarningText = NStr("vi = 'Chưa điền bảng hàng hóa.';
										|ru = 'Таблица товаров не заполнена.';
										|en = 'Add items to the order.'; fa = 'Add items to the order.';
										|it = 'La tabella delle merci non è compilata.';
										|pl = 'Nie wypełniono tabeli towarów.';
										|tr = 'Mal tablosu eksiktir.'");
	ElsIf AllLinesAreCanceled() Then
		ReturnValue.WarningText = NStr("vi = 'Đã hủy tất cả các dòng.';
										|ru = 'Все строки отменены.';
										|en = 'All lines are canceled.'; fa = 'All lines are canceled.';
										|it = 'Tutte le righe sono annullate.';
										|pl = 'Wszystkie wiersze anulowano.';
										|tr = 'Tüm satırlar iptal edildi.'");
	EndIf;
	
	If Not IsBlankString(ReturnValue.WarningText) Then
		Return ReturnValue;
	EndIf;
	
	Result = Documents.PurchaseRequest.UndoLinesThatAreNotOrdered(Object);
	ReturnValue.ThereAreCanceledLines = ValueIsFilled(Result.CancelledRows);
	
	Actions = New Structure;
	Actions.Insert("WhenChangingProductType", // Filling out the warehouse obligation
		New Structure("ThereAreWorks, IsCanceled", True, True));
	CommonClientServer.SupplementStructure(Actions, ActionsForFillingInSummaryDetailsOfForm(), True);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(Result.ModifiedRows, Actions, Object.Goods);
	
	CalculateFinalIndicatorsOfApplication(ThisObject);
	HowToUpdateRowSelectionForCanceledRows(ThisObject, HideCanceledLines, False);
	SetWhetherWarehouseIsFull(ThisObject);
	UpdateWarehouseGroupImage();
	
	Return ReturnValue;
	
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
	ElsIf Item.Name = "sh_ShamsiInput_RequestedDeliveryDate" Then
		RequestedDeliveryDateOnChange(Items.RequestedDeliveryDate);
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

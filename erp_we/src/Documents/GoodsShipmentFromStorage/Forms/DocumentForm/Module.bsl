
#Region Variables

&AtClient
Var CachedValues; //It is used by the mechanism for processing changes in PM details.

&AtClient
Var CurDataId; //Used to pass the current line to the waiting handler.


&AtClient
Var ParametersForRecording Export;

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
	AdditionalParameters.Insert("Object",                   Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization",  True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ElsIf Parameters.FillingValues.Property("FillByWarehouseDocument") Then
		RefillByNotes();
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	PurchasesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	
	SetAvailabilityOfClipboardCommands();
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	FillingCommands = New Array();
	FillingCommands.Add(Items.GoodsPickUpTheGoodsAcceptedForSafeStorage);
	FillingCommands.Add(Items.GoodsRefillByShipment);
	
	If Object.Patch Then
		For Each FillingCommand In FillingCommands Do
			FillingCommand.Visible = False;
		EndDo;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	Items.EPDStateGroup.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");

	
	sh_ShamsiInit(); // sh_ShamsiInit
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

	SetFieldHeadersForBusinessTransactions();
	EnableWaitingHandlerReceivingCarriers();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsReceivedForCustody.Form.Form" Then
		
		PricesCalculated = False;
		
		ProcessingOfSelectionSelectionOfServerAcceptedForResponsibleStorage(ValueSelected, PricesCalculated);
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	ElsIf ChoiceSource.FormName = "Document.GoodsShipmentFromStorage.Form.FormOfGoodSelectionByPurchaseForPrincipal" Then
		
		PricesCalculated = False;
		SelectionProcessingSelectionOfDocumentsForPrincipal(ValueSelected, PricesCalculated);
		NotifyAboutEndOfFillingInPrices();
	ElsIf ChoiceSource.FormName = "CommonForm.AddItemsFromSalesOrderGoodsIssue" Then
		
		ProcessingProductSelectionFromOrder(ValueSelected.AddressInStorage);
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			
			Modified = True;
			FillPropertyValues(Object, ValueSelected,, "Basis");
			Object.BasisForPrint = ValueSelected.Basis;

		EndIf;
		
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
	
	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		UpdateVisibilityOfAgreements();
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	NotificationProcessingLocalization(EventName, Parameter, Source);
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		ContractOnChange(Items[Parameter]);
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
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
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting
		And Object.Goods.Count() > 0
		And Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.OfferToFillIn")
			Or Not ValueIsFilled(Object.ReusablePackageFillingStatus) Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		TableName = "Goods";
		ColumnsNames = "Products,Characteristic,Count,Warehouse";
		
		AskAQuestion = ReusablePackageServerCall.AskQuestionAboutFillingMultiTurnContainers(
			Object,
			TableName,
			ColumnsNames);
		
		If AskAQuestion Then
			
			Cancel = True;
			CallbackDescription = New CallbackDescription(
				"BeforeRecordingOfferToPickUpMultiTurnContainer",
				ThisObject,
				AdditionalParameters);
			
			ReusablePackageClient.OfferToPickUpMultiTurnContainer(
				ThisObject,
				TableName,
				ColumnsNames,
				CallbackDescription,
				AskAQuestion);
			
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject,
															AdditionalParameters.WriteParameters,
															False,
															True);
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()

	Result = TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
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
	UpdateOrderDeviations();
	CustomizeForm(ThisObject);
	
	FillInServiceDetailsForProductRange();
	
	
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_GoodsShipmentFromStorage", WriteParameters, Object.Ref);
	
	
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

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
	EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	Var PricesCalculated;
	
	If Not QuestionResult = DialogReturnCode.Cancel Then
		DateOnChangeServer(QuestionResult, PricesCalculated);
	EndIf;
	
	If QuestionResult = True Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		Object.Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
		
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
		
		Return;
	EndIf;
	
	WhenChangingPartnerServer();
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.Item = Item;
	
	CallbackDescription = New CallbackDescription("PartnerWhenChangingQuestionEnds", ThisObject,
		AdditionalParameters);
	
	QuestionUserBeforeFillingInPricesByAgreement(CallbackDescription);
	
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
		Else
			PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
		EndIf;
	EndIf;
	
	FillBaseForPrinting();
	
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	CallbackDescription = New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject);
	
	QuestionUserBeforeFillingInPricesByAgreement(CallbackDescription);
	
EndProcedure

&AtClient
Procedure AgreementWhenChangingQuestionCompletion(UserAnswer, AdditionalParameters) Export
	
	Var PricesCalculated;
	
	RecalculatePrices_2 = ValueIsFilled(Object.Terms)
		And Object.Goods.Count() > 0
		And UserAnswer;
	
	WhenChangingAgreementAtServer(RecalculatePrices_2, PricesCalculated);
	
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale") Then
		
		AdditionalSelection = New Structure("BusinessOperation", 
			PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale"));
		
		PurchasesClient.StartSelectingSupplierAgreement(Item, StandardProcessing, Object.Partner, Object.Terms,
			Object.Date, AdditionalSelection);
			
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then	
		
		AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
		
		AgreementSelectionParameters.Item                     = Item;
		AgreementSelectionParameters.Partner                     = Object.Partner;
		AgreementSelectionParameters.Document                    = Object.Terms;
		AgreementSelectionParameters.DocumentDate               = Object.Date;
		AgreementSelectionParameters.FormDataStructure        = Object;
		AgreementSelectionParameters.ContractsAreUsed = True;
		
		SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	PurchasesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	BasisChanged = BasisChanged And ValueIsFilled(Object.Basis);
	ContractOnChangeServer();
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Warehouse <> Object.Warehouse Then
		WarehouseOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	OldBusinessOperation = BusinessTransactionBeforeTheChange;
	
	If Object.BusinessOperation = OldBusinessOperation Then
		Return;
	EndIf;
	
	GoodsNeedToBeCleaned = False;
	NeedToCleanUpPartner = False;
	
	DeliveryForPrincipal = PredefinedValue(
		"Enum.BusinessTransactions.DeliveryForPrincipal");
	
	// We determine the need to clean goods for operations that do not require goods
	If Object.BusinessOperation = DeliveryForPrincipal And Object.ByOrder Then
		GoodsNeedToBeCleaned = True;
	EndIf;
	GivingOperations = New Array;
	GivingOperations.Add(PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5"));
	GivingOperations.Add(PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5"));
	
	If GivingOperations.Find(Object.BusinessOperation) <>
			GivingOperations.Find(OldBusinessOperation) Then
		
		GoodsNeedToBeCleaned = True;
		NeedToCleanUpPartner = True;
		
	ElsIf GivingOperations.Find(Object.BusinessOperation) <> Undefined Then
		GoodsNeedToBeCleaned = True;
		
	EndIf;
	If GoodsNeedToBeCleaned And Object.Goods.Count() > 0 Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("OldBusinessOperation", OldBusinessOperation);
		AdditionalParameters.Insert("NeedToCleanUpPartner", NeedToCleanUpPartner);
		AdditionalParameters.Insert("NeedToClearGoods", True);
		
		Notification = New CallbackDescription(
			"BusinessOperationOnChangeCompletion",
			ThisObject,
			AdditionalParameters);
		
		ButtonsList = New ValueList;
		ButtonsList.Add("ClearGoods", NStr("ru = 'Очистить товары';
											|vi = 'Очистить товары';
											|en = 'Очистить товары'; fa = 'Очистить товары';
											|it = 'Очистить товары';
											|pl = 'Очистить товары';
											|tr = 'Очистить товары'"));
		ButtonsList.Add("Cancel", NStr("ru = 'Отмена';
										|vi = 'Отмена';
										|en = 'Отмена'; fa = 'Отмена';
										|it = 'Отмена';
										|pl = 'Отмена';
										|tr = 'Отмена'"));
		
		ShowQueryBox(
			Notification,
			NStr("ru = 'При изменении хозяйственной операции необходимо очистить табличную часть Товары. Очистить товары?';
				|vi = 'При изменении хозяйственной операции необходимо очистить табличную часть Товары. Очистить товары?';
				|en = 'При изменении хозяйственной операции необходимо очистить табличную часть Товары. Очистить товары?'; fa = 'При изменении хозяйственной операции необходимо очистить табличную часть Товары. Очистить товары?';
				|it = 'При изменении хозяйственной операции необходимо очистить табличную часть Товары. Очистить товары?';
				|pl = 'При изменении хозяйственной операции необходимо очистить табличную часть Товары. Очистить товары?';
				|tr = 'При изменении хозяйственной операции необходимо очистить табличную часть Товары. Очистить товары?'"),
			ButtonsList,
			,
			"ClearGoods");
		
		Return;
	EndIf;
	
	PerformActionsONChangesOfOperations(NeedToCleanUpPartner);
	
EndProcedure

#Region EventHandlersDelivery

&AtClient
Procedure MethodPlaceOfDeliveryCarrierIfChanged(Item)
	
	MethodPlaceOfDeliveryCarrierIfChangedServer(Item.Name);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOnChange(Item)
	
	ProcessAddressChange(Item, "DeliveryAddress");
	
EndProcedure

&AtClient
Procedure DeliveryAddressClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierOnChange(Item)
	
	ProcessAddressChange(Item, "DeliveryAddressOfCarrier");
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure SpecialTransportationConditionsOnChange(Item)
	
	SpecialTransportationConditionsOnChangeServer();
	
EndProcedure

#EndRegion

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Object.ContactPerson.IsEmpty() Then
		Return;
	ElsIf Not Object.Partner.IsEmpty() Then
		Return;
	EndIf;
	
	PartnerChanged_ = False;
	
	ContactPersonOnChangeServer(PartnerChanged_);
	
	If Not PartnerChanged_ Then
		Return;
	EndIf;
	
	If Not ValueIsFilled (Object.Partner) Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
	EndIf;
	
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	DirectionOfActivityWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		WhenChangingCurrencyServer(Object.Currency, PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency));
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ClearMessages();
	TextDocumentsBasedOnURLProcessingLocalization(FormattedStringURL, StandardProcessing);
	
EndProcedure

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * Item - FormGroup, FormTable, FormField, FormButton - Form element
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("Item");
	Return Result;
	
EndFunction

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
			
EndProcedure

&AtClient
Procedure DecorationOfEPDClick(Item)
	
	
EndProcedure

&AtClient
Procedure DecorationToIssueEPDClick(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure PrintDetails(Item)
	
	OpenPrintDetails();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts", NStr("vi = 'Nhà cung cấp';
																									|ru = 'Поставщик';
																									|en = 'Vendor'; fa = 'تأمین‌کننده';
																									|it = 'Fornitore';
																									|pl = 'Vendor';
																									|tr = 'Tedarikçi'"));
	
	If Object.ByOrder And Field = Items.GoodsSalesOrder Then
		
		If ValueIsFilled(Items.Goods.CurrentData.SalesOrder) Then
			ShowValue(Undefined, Items.Goods.CurrentData.SalesOrder);
		ElsIf ValueIsFilled(Object.Basis) Then
			ShowValue(Undefined, Object.Basis);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = "GoodsPartnerProducts" Then
		
		CurrentData = Items.Goods.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.GoodsPartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.GoodsPartnerProducts.ChoiceParameters, CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	CurrentData = Items.Goods.CurrentData; 
	
	If Copy
		And CurrentData <> Undefined Then
		
		CurrentData.RowCode = 0;
		
		UpdateOrderDeviationsInLine(CurrentData, Object.ByOrder, Object.BusinessOperation);
		UpdateDependentDetailsOfOrderForm_(Object.Goods, DiscrepancyOrderText, Items);
		
	EndIf;
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters,
		Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.Goods.CurrentData;
	
	ServerHandlers = New Structure;
	ServerHandlers.Insert("InstallBase", False);
	ServerHandlers.Insert("ServerCallRequired__", False);
	ServerHandlers.Insert("NewRow", False);
	
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, ServerHandlers);
	
	ServerHandlers.Insert("UpdateSeriesStatuses", 
		ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters));
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	If Not CancelEdit Then
		CacheLines = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, CacheLines, WarehouseGroup_, False);
		
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses,
			TotalWarehouses_);
		ServerHandlers.InstallBase = True;
		If NewRow Then
			AssignmentsClient.AfterSpecifyingOrderInLine(ThisObject, CurrentData);

			ServerHandlers.NewRow = True;

		EndIf;
	EndIf;
	
	If ServerHandlers.ServerCallRequired__
		Or ServerHandlers.UpdateSeriesStatuses
		Or ServerHandlers.InstallBase Then
		GoodsAtEndOfEditingOnServer(
			CurrentData.GetID(), ServerHandlers, CachedValues);
	EndIf;
	
	If ServerHandlers.UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters, True) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	GoodsAfterDeleteRowServer();
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	CurrentData = Items.Goods.CurrentData; 
	
	If CurrentData <> Undefined Then
		UpdateOrderDeviationsInLine(CurrentData, Object.ByOrder, Object.BusinessOperation);
		UpdateDependentDetailsOfOrderForm_(Object.Goods, DiscrepancyOrderText, Items);
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure GoodsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	UpdateDependentDetailsOfOrderForm_(Object.Goods, DiscrepancyOrderText, Items);
	Return;
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	ItemBeforePartnerItemChanges = CurrentRow.Products;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	FillInArticleAttribute         = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
		WarehouseGroup_);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("FillInArticleAttribute",               FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",       FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	If ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert(
			"FillInTermsOfPurchase",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If CurrentRow.Products <> ItemBeforePartnerItemChanges Then
		StructureOfActions = New Structure;
		
		AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
			ThisObject, "Products", StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	FillInArticleAttribute                  = New Structure("Products", "SKU");
	FillInProductTypeAttribute_          = New Structure("Products", "ItemsType");
	CheckSeriesCalculateStatus           = New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse,
		SeriesSpecificationParameters);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName", FormName,
		"Goods");
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
		WarehouseGroup_);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("FillInArticleAttribute",               FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",       FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",        CheckSeriesCalculateStatus);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("CheckFillWarehouse",                  CheckFillWarehouse);
	
	If ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert(
			"FillInTermsOfPurchase",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInCustomerSOrderForIntendedPurpose(CurrentRow, Object, ListOfGrounds);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CharacteristicOnChangeOverridable = New Structure("FormName, TabularSectionName", FormName,
		"Goods");
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", CharacteristicOnChangeOverridable);
	If ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert(
			"FillInTermsOfPurchase",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Characteristic", StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
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
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow                  = Items.Goods.CurrentData;
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters",
		CurrentRow.Warehouse, SeriesSpecificationParameters);
	
	StructureOfActions = New Structure("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	
	TheCurrentDataRow = Items.Goods.CurrentData;
	If Object.ByOrder And Not TheCurrentDataRow = Undefined Then
		FillInCustomerSOrderForIntendedPurpose(TheCurrentDataRow, Object, ListOfGrounds);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSalesOrderStartChoice(Item, ChoiceData, StandardProcessing)
	If Object.BusinessOperation =
					PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5") Then
		
		StandardProcessing = False;
		
		CurrentData = Items.Goods.CurrentData;
		
		If CurrentData <> Undefined Then
		
			FilterParameters = New Structure;
			FilterParameters.Insert("BusinessOperation",   Object.BusinessOperation);
			FilterParameters.Insert("Organization",             Object.Organization);
			FilterParameters.Insert("Partner",                 Object.Partner);
			FilterParameters.Insert("Counterparty",              Object.Counterparty);
			FilterParameters.Insert("Contract",                 Object.Contract);
			FilterParameters.Insert("Currency",                  Object.Currency);
			FilterParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
			
			FormParameters = New Structure;
			FormParameters.Insert("Filter",       FilterParameters);
			FormParameters.Insert("Warehouse",       Object.Warehouse);
			FormParameters.Insert("Recorder", Object.Ref);
			FormParameters.Insert("Title",   NStr("vi = 'Đơn hàng bên đặt gia công';
													|ru = 'Заказы давальцев';
													|en = 'Subcontracting sales orders'; fa = 'سفارش‌های فروش پیمانکاری فرعی';
													|it = 'Ordini dei prestatori';
													|pl = 'Zamówienia właścicieli surowców';
													|tr = 'Sağlayıcı siparişleri'"));
			
			OpenForm(
				"Document.GoodsShipmentFromStorage.Form.ReferenceChoiceForm",
				FormParameters,,,,,
				New CallbackDescription("GoodsSalesOrderStartChoiceCompletion", ThisObject),
				FormWindowOpeningMode.LockOwnerWindow);
			
			Return;
		
		EndIf;
		
		ProductsCustomerOrderStartSelectionFragment();
		
	EndIf;
	Return; // in UT and KA the handler is empty
	
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
// End StandardSubsystems.FilesOperations

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
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
Procedure CheckCounterparties(Command)
	
	
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
	
	CurrentData = Items.Goods.CurrentData;
	UpdateOrderDeviationsInLine(CurrentData, Object.ByOrder, Object.BusinessOperation);
	UpdateDependentDetailsOfOrderForm_(Object.Goods, DiscrepancyOrderText, Items);
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
	
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);

EndProcedure
&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		WhenChangingWarehouseInTablePartServer();
		
	EndIf;
	
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
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	Notification = New CallbackDescription("DownloadFromTSDCompletion", ThisObject);
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(Notification, UUID);
	
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
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisObject);
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow);
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(Notification, UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		StructureOfActions                = New Structure;
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	Else
		
		EquipmentManagerTMClient.ReportError(ExecutionResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)

	OpeningParameters = New Structure;
	OpeningParameters.Insert("Ref",                               Object.Ref);
	OpeningParameters.Insert("Warehouse",                                Object.Warehouse);
	OpeningParameters.Insert("TabularSectionName",                    "Goods");
	OpeningParameters.Insert("SeriesSpecificationParameters",               SeriesSpecificationParameters);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", True);
	OpeningParameters.Insert("AddressInTempStorage",
		PutTablePartOfGoodsInTemporaryStorageToCheckQuantity());
	
	ReturnParameters = Undefined;
	CallbackDescription    = New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject);
	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters, , , , , CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	ReturnParameters = Result;
	
	If ReturnParameters <> Undefined Then
		
		ChangeTablePartBasedOnResultsOfCheck(ReturnParameters,
			?(CachedValues = Undefined,
				BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(),
				CachedValues));
		
		Modified = True;
		
	EndIf;

EndProcedure

&AtClient
Procedure UnlinkFromOrder(Command)
	SelectedRows = Items.Goods.SelectedRows;
	If SelectedRows.Count() > 0 Then
		UnlinkFromOrderServer(False);
		NotifyAboutEndOfUnbindingLines(SelectedRows.Count());
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Hãy chọn dòng mà cần hủy liên kết với đơn hàng.';
										|ru = 'Выберите строки, которые необходимо отвязать от заказа.';
										|en = 'Select lines to remove from the order.'; fa = 'Select lines to remove from the order.';
										|it = 'Selezionare le righe da dissociare dall''ordine.';
										|pl = 'Wybierz wierze, które należy odłączyć od zamówienia.';
										|tr = 'Siparişten çıkarılacak satırları seçin.'"));
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

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

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.GoodsShipmentFromStorage.Form.DocumentForm.SelectGoods");
	
	Cancel = False;
	If Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	FilterByProductType = New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",                                      Object.Ref);
	FormParameters.Insert("Date",                                          Object.Date);
	FormParameters.Insert("Terms",                                    Object.Terms);
	FormParameters.Insert("Partner",                                       Object.Partner);
	FormParameters.Insert("Warehouse",                                         Object.Warehouse);
	FormParameters.Insert("LineOfBusiness",                       Object.LineOfBusiness);
	FormParameters.Insert("Currency",                                        Object.Currency);
	FormParameters.Insert("FilterByProductType",                       FilterByProductType);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders",  True);
	FormParameters.Insert("HideManualDiscounts",                          True);
	GivingOperations = New Array;
	GivingOperations.Add(PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5"));
	GivingOperations.Add(PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5"));
	
	If GivingOperations.Find(Object.BusinessOperation) <> Undefined Then
		FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	EndIf;
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure PickUpTheGoodsAcceptedForSafeStorage(Command)
	
	SelectionOfGoodsAcceptedForResponsibleStorage();
	
EndProcedure

&AtClient
Procedure AddReusablePackage(Command)
	
	ReusablePackageClient.SelectReusablePackage(ThisObject, "Goods", 
		"Products,Characteristic,Count,Warehouse");
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItem(Command)
	
	If Not TMCommonUseClient.CheckForRowsInList(Object.Goods, "Goods") Then
		Return;
	EndIf;
	
	FilterItemsType = New Array;
	FilterItemsType.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	FilterItemsType.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	
	Notification = New CallbackDescription("FillInTheItemByThePartnerSItemCompletion", ThisObject);
	
	PurchasesClient.OpenSupplierProductListForm(Notification, PlaceGoodsInTemporaryStorageServer(),
		ThisObject, FilterItemsType);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItemCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		FillInItemsFromTemporaryStorageServer(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInSeriesByFEFO(Command)
	
	If ThereAreFilledSeriesByFEFO() Then
		
		Notification = New CallbackDescription("CompleteSeriesOnFEFOCompletion", ThisObject);
		
		ProductsClient.AskQuestionAboutReFillingSeriesByFEFO(Notification);
		
		Return;
		
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteSeriesOnFEFOCompletion(Result, AdditionalParameters) Export 
	
	If Not Result Then
		Return;
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
	EndIf;

EndProcedure

&AtClient
Procedure RefillByShipment(Command)
	
	If SalesClient.ItIsNecessaryToFillInGoodsOnShipment(Object.Posted) Then
		
		ShipmentStatus = SalesServerCall.GetStateOfActualShipment(Object.Ref);
		
		If ShipmentStatus.ThereAreUnassembledGoods Then
			
			AdditionalParameters = New Structure("ShipmentStatus", ShipmentStatus);
			Notification              = New CallbackDescription("QuestionAboutReFillingWithShippedGoodsCompletion",
				ThisObject, AdditionalParameters);
			
			SalesClient.QuestionAboutReFillingWithShippedGoods(Notification, ShipmentStatus.ThereAreShippedGoods);
			
		Else
			
			RefillByShipmentCompletion(ShipmentStatus);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionAboutReFillingWithShippedGoodsCompletion(Result, AdditionalParameters) Export
	
	If Not Result.Refill Then
		Return;
	EndIf;
	
	RefillByShipmentCompletion(AdditionalParameters.ShipmentStatus, Result.FillWithUnassembledGoods);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.FillInThePartnerSNomenclature = Object.Partner;
	ImportParameters.ImportPrices = True;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)
	
	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																								|ru = 'Товары';
																								|en = 'Goods'; fa = 'کالاها';
																								|it = 'Merci';
																								|pl = 'Wiersze pozycji';
																								|tr = 'Ürünler'")) Then
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(, ErrorText);
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice(Command)

	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(Object, "Goods", NStr("vi = 'Hàng hóa';
																												|ru = 'Товары';
																												|en = 'Goods'; fa = 'کالاها';
																												|it = 'Merci';
																												|pl = 'Wiersze pozycji';
																												|tr = 'Ürünler'")) Then
		
		CallbackDescription = New CallbackDescription("FillInPricesOfSelectedRowsSelectionVendorPriceViewCompletion",
			ThisObject);
		
		PartnerPricesFillingClient.SelectVendorsPriceType(CallbackDescription,Object.Partner);
		
	EndIf;

EndProcedure

&AtClient
Procedure FillInPricesByTypeOfGiverSPrices(Command)
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Sản phẩm trả lại';
																									|ru = 'Возвращаемая продукция';
																									|en = 'Products to return'; fa = 'Products to return';
																									|it = 'Возвращаемая продукция';
																									|pl = 'Products to return';
																									|tr = 'İade edilen imal edilen ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("FillInPricesOfSelectedLinesSelectionPriceTypeEnd", ThisObject);
		PriceSelectionOptions.UseWhileTransferringProductsToMaterialProvider = True;
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesByCosts(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document.GoodsShipmentFromStorage.Form.DocumentForm.Command.FillInPricesByCosts");
	
	ClearMessages();
	If Object.Goods.Count() = 0 Then
		MessageText = NStr("vi = 'Trong chứng từ chưa điền bảng ""Hàng hóa"". Không thể điền đơn giá';
							|ru = 'В документе не заполнена таблица ""Товары"". Цены не могут быть заполнены';
							|en = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices'; fa = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices';
							|it = 'Nel documento non è compilata la tabella ""Merci"". I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wypełniona tabela ""Wiersze pozycji"". Ceny nie mogą być wypełnione.';
							|tr = 'Belgedeki ""Ürünler"" tablosu doldurulmamıştır. Fiyatlar doldurulamıyor'");
		CommonClient.MessageToUser(MessageText, , "Goods", "Object");
		Return;
	EndIf;
	
	FillInPricesByCostsServer(CachedValues);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsSelectionVendorPriceViewCompletion(VendorPriceKind, AdditionalParameters) Export
	
	If ValueIsFilled(VendorPriceKind) Then
		PricesCalculated = FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(VendorPriceKind);
		
		PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, VendorPriceKind);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLines(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	PresentationOfTS  = NStr("vi = 'Hàng hóa';
							|ru = 'Товары';
							|en = 'Goods'; fa = 'کالاها';
							|it = 'Merci';
							|pl = 'Wiersze pozycji';
							|tr = 'Ürünler'");
	
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, Object.Goods, PresentationOfTS, SelectedRows) Then
		
		SelectedWarehouse = Undefined;
		
		FilterStructure1         = New Structure("SelectGroup, IsFolder",
			PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"), False);
		ParametersStructure     = New Structure("Filter, GroupOfWarehouses", FilterStructure1, Object.Warehouse);
		AdditionalParameters = New Structure("SelectedRows", SelectedRows);
		
		CallbackDescription = New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion", ThisObject,
			AdditionalParameters);
		
		OpenForm("Catalog.Warehouses.ChoiceForm", ParametersStructure, ThisObject, , , , CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLinesCompletion(Result, AdditionalParameters) Export
	
	SelectedWarehouse   = Result;
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If ValueIsFilled(SelectedWarehouse) Then
		FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse);
		RowsSelectedCount  = SelectedRows.Count();
		
		WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(SelectedWarehouse, FilledWithRows, RowsSelectedCount);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	HeaderAttributes = New Structure(
							"Organization,
							|Partner,
							|Counterparty,
							|Contract,
							|Department,
							|Warehouse,
							|SalesOpportunity,
							|Currency,
							|BusinessOperation,
							|Ref");
	
	FillPropertyValues(HeaderAttributes, Object);
	
	AdditionalFields = New Structure;
	AdditionalFields.Insert("DateOfReceipt");
	AdditionalFields.Insert("Warehouse");
	AdditionalFields.Insert("SalesOpportunity");
	
	FormParameters = New Structure;
	FormParameters.Insert("HeaderAttributes",			HeaderAttributes);
	FormParameters.Insert("OrderDocument",					Object.Basis);
	FormParameters.Insert("Invoice",				Object.Ref);
	FormParameters.Insert("InvoiceForOrders",		Object.ByOrder);
	FormParameters.Insert("OrdersAreUsed",		True);
	FormParameters.Insert("AdvancedWarehousingOnShipment", AdvancedWarehousingOnShipment);
	FormParameters.Insert("AddressGoods",				AddressInTemporaryStorageOfGoodsWaybill());
	FormParameters.Insert("AdditionalFields",		AdditionalFields);
	FormParameters.Insert(
		"UseInvoicesForSeveralOrders",
		UseSaleByMultipleOrders(ThisObject));
	
	OpenForm(
		"CommonForm.AddItemsFromSalesOrderGoodsIssue",
		FormParameters,
		ThisObject,
		UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	Return;
	
EndProcedure

&AtClient
Procedure FillInReceiptDocument(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng mà muốn điền chứng từ tiếp nhận.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить документ поступления.';
							|en = 'Select the lines for which it is required to populate a receipt document.'; fa = 'Select the lines for which it is required to populate a receipt document.';
							|it = 'Select the lines for which it is required to populate a receipt document.';
							|pl = 'Select the lines for which it is required to populate a receipt document.';
							|tr = 'Mal giriş belgesi için doldurulması gereken satırları seçmelisiniz.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Organization",    Object.Organization);
	FilterParameters.Insert("Partner",        Object.Partner);
	FilterParameters.Insert("Counterparty",     Object.Counterparty);
	FilterParameters.Insert("Contract",        Object.Contract);
	If True Then
		FilterParameters.Insert("Terms", Object.Terms);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInReceiptDocumentCompletion", ThisObject);
	OpenForm("Document.GoodsReceiptForStorage.Form.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInReceiptDocumentCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		FillInReceiptDocumentOnServer(Result);
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	
	SupplementDeliveryInformationWithContactsServer();
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure MethodPlaceOfDeliveryCarrierIfChangedServer(ItemName)
	
	GoodsDelivery.FillInDeliveryDetails(Items, ItemName, Object);
	UpdateTextDocumentsBasedOn();

EndProcedure

&AtServer
Procedure DateOnChangeServer(RecalculatePrices_2, PricesCalculated)
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	Else
		PricesCalculated = False;
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	TableWarehouses = Object.Goods.Unload(, "Warehouse").UnloadColumn("Warehouse");
	AdvancedWarehousingOnShipment = WarehousesServer.ThereIsOrderWarehouseForShipment(TableWarehouses, Object.Date, Object.Warehouse);
	
	FillSetVisibilityAndReFillAvailabilityByShipment();
	
EndProcedure

&AtServer
Procedure WhenChangingPartnerServer()
	
	OldCurrency                  = DocumentCurrency;
	DocumentPurchases               = FormAttributeToValue("Object");
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentPurchases.FillInDefaultPurchaseConditions(False, Object.BusinessOperation);
	ResponsiblePersonsServer.FillInManager_(DocumentPurchases);
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract();
		
	EndIf;
	
	SetVisibilityOfAgreements(Object.Partner, Object.BusinessOperation, Items.Terms);
	
	If ValueIsFilled(Object.Terms) Then
		DocumentCurrency = Object.Currency;
		
		ExecuteRecalculateDocumentAmountsServer(OldCurrency, DocumentCurrency);
	EndIf;
	
	SalesServer.PartnerOnChange(Object);
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	WarehouseOnChangeServer();
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	FillInServiceDetailsForProductRange();
	
	GoodsDelivery.FillInDeliveryDetails(Items, "Partner", Object);
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		SetLBEditingOption();
	EndIf;
	
	AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract();
		
	EndIf;
	
	SalesServer.PartnerOnChange(Object);
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		SetLBEditingOption();
	EndIf;
	
	AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(RecalculatePrices_2 = True, PricesCalculated = False)
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	OldCurrency                  = DocumentCurrency;
	DocumentPurchases               = FormAttributeToValue("Object");
	DirectionsOfActivity = Object.LineOfBusiness;
	PurchaseConditions                = PurchasesServer.GetPurchaseTermsAndConditions(DocumentPurchases.Terms, True, True);
	ResponsiblePersonsServer.FillInManager_(DocumentPurchases);
	DocumentPurchases.FillInTermsOfPurchase(PurchaseConditions);
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	DocumentCurrency = Object.Currency;
	
	If RecalculatePrices_2 Then
		
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields", "Price");
		FillParameters.Insert("Date",           Object.Date);
		FillParameters.Insert("Currency",         Object.Currency);
		FillParameters.Insert("Terms",     Object.Terms);
		FillParameters.Insert("Organization", Object.Organization);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		
		PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, Undefined, FillParameters, StructureOfActions);
		
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
		
	EndIf;
	
	WarehouseOnChangeServer();
	
	ExecuteRecalculateDocumentAmountsServer(OldCurrency, DocumentCurrency);
	FillInServiceDetailsForProductRange();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		SetLBEditingOption();
	EndIf;
	
	AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If Not ValueIsFilled(Object.Currency) Then
			
			Object.Currency = SettingsValueClientServerCached.CurrencyOfOrganizationSRegulatedAccounting(
				Object.Organization);
			
			DocumentCurrency = Object.Currency;
			
		EndIf;
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
			SetLBEditingOption();
		EndIf;
		
		CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
			Object.CompanyBankAccount, Undefined, Object.LineOfBusiness);
		
		FillInSubordinatePropertiesForStatistics("Organization");
		
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	UpdateTextDocumentsBasedOn();	
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
		Object.CounterpartyBankAccount);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,Object.Contract);
		SetLBEditingOption();
	EndIf;
	
	AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	FillInAttributesFromContract();
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	Warehouse       = Object.Warehouse;
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	Items.GroupPictureAndLabelMultipleWarehouses.Visible   = WarehouseGroup_;
	
	StructureOfResponsible = PurchasesServer.GetWarehouseManager(Object.Warehouse, Object.Manager);
	
	If StructureOfResponsible <> Undefined Then
		Object.IssuiedBy          = StructureOfResponsible.EmployeeResponsible;
		Object.IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
	EndIf;
	
	SetParametersForSelectingProductsWarehouse();
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True);
	
	WhenChangingWarehouseInTablePartServer();
	FillSetVisibilityAndReFillAvailabilityByShipment();
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer(PartnerChanged_)
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	
	If OwnerOfContactPerson <> Object.Partner Then
		PartnerChanged_ = True;
		Object.Partner   = OwnerOfContactPerson;
		
		WhenChangingPartnerServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()
	
	AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure WhenChangingCurrencyServer(NewCurrency, RecalculateAmounts)
	
	If RecalculateAmounts Then
		OldCurrency = DocumentCurrency;
		
		ExecuteRecalculateDocumentAmountsServer(OldCurrency, NewCurrency);
	EndIf;
	
EndProcedure
&AtClient
Procedure ShipmentByOrdersOnChange()
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.GoodsShipmentFromStorage.Form.DocumentForm.Item.UseTheBase.OnChange");
	
	SetAvailabilityOfClipboardCommandsOnClient();
	
	If Object.ByOrder Then
		
		If UseSaleByMultipleOrders(ThisObject) Then
			
			If Object.Goods.Count() = 0 Then
				QueryText = NStr("vi = 'Sẽ điền lại danh sách Hàng hóa bằng số dư của hàng hóa chưa được tạo theo đơn hàng.
										|Tiếp tục?';
										|ru = 'Список Товары будет перезаполнен остатками неоформленных товаров по заказам.
										|Продолжить?';
										|en = 'The Goods list will be refilled with the remaining unregistered goods by orders.
										|Continue?'; fa = 'The Goods list will be refilled with the remaining unregistered goods by orders.
										|Continue?';
										|it = 'L''elenco Merci sarà ricompilato con i saldi non formalizzati delle merci in base agli ordini.
										|Continuare?';
										|pl = 'Lista Wiersze pozycji zostanie ponownie wypełniona przez resztki nieodebranych towarów z zamówień.
										|Kontynuować?';
										|tr = 'Ürünler listesi işlenmemiş ürünlerin bakiyeleri ile yeniden doldurulacaktır.
										| Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa sẽ được gắn với dòng của đơn hàng.
										|Tiếp tục?';
										|ru = 'Строки в списке Товары будут привязаны к строкам заказов.
										|Продолжить?';
										|en = 'The Goods list lines will be linked to the order lines.
										|Continue?'; fa = 'The Goods list lines will be linked to the order lines.
										|Continue?';
										|it = 'Le stringhe nell''elenco Merci saranno associate alle stringhe dell''ordine.
										|Continuare?';
										|pl = 'Wiersze na liście Towary będą powiązane z wierszami zamówień.
										|Kontynuować?';
										|tr = 'Ürünler listesindeki satırlar sipariş satırlarına bağlanacaktır.
										| Devam edilsin mi?'");
			EndIf;
			
		Else
			
			FilterParameters = New Structure;
			FilterParameters.Insert("BusinessOperation",   Object.BusinessOperation);
			FilterParameters.Insert("Organization",             Object.Organization);
			FilterParameters.Insert("Partner",                 Object.Partner);
			FilterParameters.Insert("Counterparty",              Object.Counterparty);
			FilterParameters.Insert("Contract",                 Object.Contract);
			FilterParameters.Insert("Currency",                  Object.Currency);
			FilterParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
			
			FormParameters = New Structure;
			FormParameters.Insert("Filter",       FilterParameters);
			FormParameters.Insert("Warehouse",       Object.Warehouse);
			FormParameters.Insert("Recorder", Object.Ref);
			
			OpenForm(
				"Document.GoodsShipmentFromStorage.Form.ReferenceChoiceForm",
				FormParameters,,,,,
				New CallbackDescription("ShippingOnOrdersWhenChangingAfterSelection", ThisObject),
				FormWindowOpeningMode.LockOwnerWindow);
			
			Return;
			
		EndIf;
			
	Else
		
		If Object.Goods.Count() > 0 Then
			
			If UseSaleByMultipleOrders(ThisObject) Then
				QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa không còn liên kết với dòng trong đơn hàng.
										|Tiếp tục?';
										|ru = 'Строки в списке Товары перестанут быть связанными со строками заказов.
										|Продолжить?';
										|en = 'The Goods list lines will be unlinked from the lines in the orders.
										|Continue?'; fa = 'The Goods list lines will be unlinked from the lines in the orders.
										|Continue?';
										|it = 'Le stringhe nell''elenco Merci non saranno più associate alle stringhe degli ordini.
										|Continuare?';
										|pl = 'Wiersze na liście Towary nie będą więcej powiązane z wierszami zamówień.
										|Kontynuować?';
										|tr = 'Ürünler listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir.
										| Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa không còn liên kết với dòng trong đơn hàng.
										|Tiếp tục?';
										|ru = 'Строки в списке Товары перестанут быть связанными со строками заказа.
										|Продолжить?';
										|en = 'The Goods list lines will be unlinked from the order lines.
										|Continue?'; fa = 'The Goods list lines will be unlinked from the order lines.
										|Continue?';
										|it = 'Le stringhe nell''elenco Merci non saranno più associate alle stringhe dell''ordine.
										|Continuare?';
										|pl = 'Wiersze na liście Towary nie będą więcej powiązane z wierszami zamówienia.
										|Kontynuować?';
										|tr = 'Ürünler listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir.
										| Devam edilsin mi?'");
			EndIf;
			
		Else
			
			ShipmentByOrdersOnChangeServer();
			Return;
			
		EndIf;
		
	EndIf;
	
	ShippingOnOrdersWhenIssueChanges(Undefined, QueryText);
	
EndProcedure

&AtServer
Procedure ShipmentByOrdersOnChangeServer()
	
	WhenShipmentChangesForSeveralOrders();
	AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	
EndProcedure

&AtClient
Procedure ShippingOnOrdersWhenChangingAfterSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Object.ByOrder = False;
		Return;
	EndIf;
	
	If Object.Goods.Count() = 0 Then
		QueryText = NStr("vi = 'Sẽ điền lại danh sách hàng hóa bằng số dư của hàng hóa chưa tạo theo chứng từ %1.
								|Tiếp tục?';
								|ru = 'Список товары будет заполнен остатками неоформленных товаров по документу %1.
								|Продолжить?';
								|en = 'The Goods list will be filled with the remaining unregistered goods by the %1 document.
								|Continue?'; fa = 'The Goods list will be filled with the remaining unregistered goods by the %1 document.
								|Continue?';
								|it = 'L''elenco di merci sarà compilato con i saldi non formalizzati delle merci in base al documento %1.
								|Continuare?';
								|pl = 'Lista Towary zostanie wypełniona niezarejestrowanymi zapasami według dokumentu %1.
								|Kontynuować?';
								|tr = 'Ürün listesi, %1 belgesindeki işlenmemiş ürünlerin bakiyeleri ile doldurulacaktır.
								| Devam edilsin mi?'");
	Else
		QueryText = NStr("vi = 'Các dòng trong danh sách Hàng hóa sẽ được liên kết với các dòng của chứng từ %1.
								|Các dòng không thể được liên kết với các dòng thứ tự sẽ bị xóa. Tiếp tục?';
								|ru = 'Строки в списке Товары будут привязаны к строкам документа %1.
								|Строки, которые невозможно привязать к строкам заказа, будут удалены. Продолжить?';
								|en = 'The Goods list lines will be linked to the %1 document lines.
								|Lines that cannot be linked to the order lines will be deleted. Continue?'; fa = 'The Goods list lines will be linked to the %1 document lines.
								|Lines that cannot be linked to the order lines will be deleted. Continue?';
								|it = 'Le stringhe nell''elenco Merci saranno associate alle stringhe del documento %1. 
								|Le stringhe che non possono essere associate alle stringhe dell''ordine saranno eliminate. Continuare?';
								|pl = 'Wiersze na liście Towary zostaną połączone z wierszami dokumentu %1.
								|Wiersze, których nie można połączyć z wierszami zamówień, zostaną usunięte. Kontynuować?';
								|tr = 'Ürünler listesindeki satırlar %1 belgesinin satırlarına bağlanacaktır.
								| Sipariş satırlarına bağlanamayan satırlar silinecektir. Devam edilsin mi?'");
	EndIf;
	
	QueryText = StrTemplate(QueryText, Result.SalesOrder);
	ShippingOnOrdersWhenIssueChanges(Result.SalesOrder, QueryText);

EndProcedure

&AtClient
Procedure ShippingOnOrdersWhenIssueChanges(OrderDocument, QueryText)
	
	CallbackDescription = New CallbackDescription(
		"ShipmentByOrdersOnChangeCompletion", ThisObject, New Structure("OrderDocument", OrderDocument));
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ShipmentByOrdersOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	OrderDocument = AdditionalParameters.OrderDocument;
	
	If QuestionResult = DialogReturnCode.No Then
		Object.ByOrder = Not Object.ByOrder;
		Return;
	EndIf;
	
	If ValueIsFilled(OrderDocument) Then
		Object.Basis = OrderDocument;
	EndIf;
	
	WhenShipmentChangesForSeveralOrders();
	
	SetVisibilityByOrder(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenShipmentChangesForSeveralOrders()
	
	If Object.ByOrder Then

		If Object.Goods.Count() = 0 Then
			FillInFromOrderServer();
		Else
			LinkShipmentLinesToOrders(Not UseSaleByMultipleOrders(ThisObject));
		EndIf;
		
		AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
		
	Else
		
		Object.Basis = Undefined;
		ListOfGrounds.Clear();
		
		UnlinkFromOrderServer(True, False);
		
		ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(
			Object.ReusablePackageFillingStatus);
		
	EndIf;
	
	InstallBase();
	UpdateOrderDeviations();
	UpdateDependentDetailsOfOrderForm_Server();
	
	SetAvailabilityOfClipboardCommands();
	SetLBEditingOption();
	
	GoodsDelivery.WhenChangingFlagForOrders(Items, Object, Object.ByOrder);
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion


#Region InventoryKinds

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
	
EndFunction

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
		Not Common.EmptyClipboard("Rows"));
	
EndProcedure

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Price,Warehouse,DocumentInflow";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;

	FillInProductTypeAttribute_          = New Structure("Products", "ItemsType");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_",       FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);

	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");

	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();

		FillPropertyValues(CurrentRow, RowOfProduct);
		UpdateOrderDeviationsInLine(CurrentRow, Object.ByOrder, Object.BusinessOperation);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	CheckSeriesCalculateStatus = New Structure();
	CheckSeriesCalculateStatus.Insert("Warehouse", Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	CheckSeriesCalculateStatus.Insert("GoodsTable", RowsToProcess);
	CheckSeriesCalculateStatus.Insert("SeriesTable", Object.SetOfSeries);
	
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);

	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

#EndRegion

#Region BusinessTransactions

&AtServer
Procedure BusinessOperationOnChangeServer()

	CustomizeForm(ThisObject);
	UpdateDependentDetailsOfOrderForm_Server();
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
EndProcedure

// Customizes the form
//
// Parameters:
//  Form - ClientApplicationForm - 
//
&AtServerNoContext
Procedure CustomizeForm(Form)
	
	Object   = Form.Object;
	Items = Form.Items;
	If Object.BusinessOperation =
					PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5") Then
		
		Form.AutoTitle = False;
		
		ObjectPresentation = TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
		
		If ValueIsFilled(Form.Parameters.Key) Then
			Form.Title = StrTemplate(NStr("vi = '%1 %2 ngày %3';
											|ru = '%1 %2 от %3';
											|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
											|it = '%1 %2 del %3';
											|pl = '%1 %2 z dnia %3';
											|tr = '%3 tarihli %1 %2'"), ObjectPresentation, Object.Number, Object.Date);
		Else
			Form.Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
											|ru = '%1 (создание)';
											|en = '%1 (create)'; fa = '%1 (create)';
											|it = '%1 (creazione)';
											|pl = '%1 (utworzenie)';
											|tr = '%1 (oluştur)'"), ObjectPresentation);
		EndIf;
		
		Items.GoodsSelectGoodsByOrdersNotes.Visible = True;
		Items.GoodsFillInReceiptDocument.Visible    = False;
		Items.Currency.Visible                                = True;
		
		Items.GoodsFillThePricesByTermsOfSales.Visible       = False;
		Items.GoodsFillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice.Visible = False;
		Items.ByTypeOfGiverSPrices.Visible                             = True;
		
	ElsIf Object.BusinessOperation =
						PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5") Then
		
		Form.AutoTitle = False;
		
		ObjectPresentation = TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver();
		
		If ValueIsFilled(Form.Parameters.Key) Then
			Form.Title = StrTemplate(NStr("vi = '%1 %2 ngày %3';
											|ru = '%1 %2 от %3';
											|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
											|it = '%1 %2 del %3';
											|pl = '%1 %2 z dnia %3';
											|tr = '%3 tarihli %1 %2'"), ObjectPresentation, Object.Number, Object.Date);
		Else
			Form.Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
											|ru = '%1 (создание)';
											|en = '%1 (create)'; fa = '%1 (create)';
											|it = '%1 (creazione)';
											|pl = '%1 (utworzenie)';
											|tr = '%1 (oluştur)'"), ObjectPresentation);
		EndIf;
		
		Items.GoodsSelectGoodsByOrdersNotes.Visible = False;
		Items.GoodsFillInReceiptDocument.Visible    = True;
		Items.Currency.Visible                                = True;
		
		Items.GoodsFillThePricesByTermsOfSales.Visible       = False;
		Items.GoodsFillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice.Visible = True;
		Items.ByTypeOfGiverSPrices.Visible                             = False;
			
	Else
		Form.AutoTitle = True;
		Form.Title     = "";
		
		Items.GoodsSelectGoodsByOrdersNotes.Visible = False;
		Items.GoodsFillInReceiptDocument.Visible    = True;
		Items.Currency.Visible                                = True;
		
		Items.GoodsFillThePricesByTermsOfSales.Visible       = True;
		Items.GoodsFillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice.Visible = True;
		Items.ByTypeOfGiverSPrices.Visible                             = False;
	EndIf;
	SetVisibilityOfAgreements(Object.Partner, Object.BusinessOperation, Items.Terms);
	Items.Partner.Title = PartnersAndCounterparties.HeaderOfPartnerDetailsDependingOnBusinessOperation(
		Object.BusinessOperation, True);
	
EndProcedure
&AtServer
Procedure SetUpConnectionsForContractSelectionParameters()
	
	// ChoiceParameterLinks
	ArrayOfSelectParameterRelationships = New Array;
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink(
			"Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink(
			"Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));
		
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink(
			"Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	
	// ChoiceParameters
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
	
	ChoiceParametersArray.Add(
		New ChoiceParameter(
				"Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	
	GivingOperations = New Array;
	GivingOperations.Add(PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5"));
	GivingOperations.Add(PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5"));
	
	If GivingOperations.Find(Object.BusinessOperation) = Undefined Then
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink(
				"Filter.ARAPCurrency", "Object.Currency", LinkedValueChangeMode.Clear));
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink(
				"Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
			
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink(
				"Filter.BusinessOperation", "ContractBusinessTransaction", LinkedValueChangeMode.Clear));
				
	Else
		
		ChoiceParametersArray.Add(
			New ChoiceParameter(
					"Filter.BusinessOperation", TollingSchemeClientServer.ContractBusinessTransaction()));
		
	EndIf;
	
	Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
EndProcedure

&AtServer
Function AddressInTemporaryStorageOfGoodsWaybill()
	
	TypesOfProducts_ = New Array;
	TypesOfProducts_.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	TypesOfProducts_.Add(Type("DocumentRef.GoodsShipmentFromStorage"));
	
	TypeOfOrder = New TypeDescription(TypesOfProducts_);
	DateType         = New TypeDescription("Date");
	
	Table = Object.Goods.Unload();
	Table.Columns.SalesOrder.Name = "CustomerSOriginalOrder";
	
	Table.Columns.Add("DateOfShipment",    DateType);
	Table.Columns.Add("DateOfReceipt", DateType);
	Table.Columns.Add("SalesOrder",    TypeOfOrder);
	Table.Columns.Add("SalesOpportunity",          New TypeDescription("CatalogRef.SalesOpportunitiesToCustomer"));
	
	For Each String In Table Do
		String.SalesOrder =
			?(ValueIsFilled(String.CustomerSOriginalOrder), String.CustomerSOriginalOrder, Object.Ref);
	EndDo;
	
	Table.FillValues(CurrentSessionDate(), "DateOfShipment");
	Table.FillValues(CurrentSessionDate(), "DateOfReceipt");
	Table.FillValues(Object.SalesOpportunity,       "SalesOpportunity");
	
	Return PutToTempStorage(Table, UUID);
	
EndFunction
#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	FillInArticleAttribute         = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
		WarehouseGroup_);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActionsWithAddedStrings.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
		StructureOfActionsWithAddedStrings);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, ThisObject);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, ThisObject);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	
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
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters,
		CachedValues);
	If StructureOfActionParameters.CurrentRow <> Undefined Then
		
		AddedRow = Object.Goods.FindByID(StructureOfActionParameters.CurrentRow);
		If AddedRow <> Undefined
			And Not ValueIsFilled(AddedRow.SalesOrder) Then
			FillInCustomerSOrderForIntendedPurpose(AddedRow, Object, ListOfGrounds);
		EndIf;
		
	EndIf;
	UpdateOrderDeviations();
	UpdateDependentDetailsOfOrderForm_Server();
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods       = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	ListOfProperties = "PartnerProducts, Products, Characteristic, ItemVariantsAreUsed, Package, Price,
		|NumberOfPackages";
	
	If ValueIsFilled(Object.Warehouse) Then
		ListOfProperties = ListOfProperties + ", Warehouse";
	EndIf;
	
	StructureOfActions = New Structure;
	
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		RowsToProcess.Add(CurrentRow);
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	For Each CurrentRow In RowsToProcess Do
		UpdateOrderDeviationsInLine(CurrentRow, Object.ByOrder, Object.BusinessOperation);
	EndDo;
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	UpdateDependentDetailsOfOrderForm_Server();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure ProcessingOfSelectionSelectionOfServerAcceptedForResponsibleStorage(ValueSelected, PricesCalculated)
	
	RowsArray = New Array;
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	PriceFillingParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	PriceFillingParameters.Insert("PopulationFields", "Price");
	PriceFillingParameters.Insert("Date",           Object.Date);
	PriceFillingParameters.Insert("Currency",         Object.Currency);
	PriceFillingParameters.Insert("Terms",     Object.Terms);
	PriceFillingParameters.Insert("Organization", Object.Organization);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	FillInOverOrder = Object.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
						   And Object.ByOrder;
	
	If FillInOverOrder Then
		CurrentOrder =
			?(ListOfGrounds.Count() = 1,
				ListOfGrounds[0].Value,
				?(ListOfGrounds.Count() = 0
					And Object.ByOrder,
					Object.Basis,
					Undefined));
	EndIf;
	For Each RowOfProduct In TableOfGoods Do
		
		CanAddLine = False;
		ProductsSearch = New Structure();
		ProductsSearch.Insert("Products", RowOfProduct.Products);
		ProductsSearch.Insert("Characteristic", RowOfProduct.Characteristic);
		ProductsSearch.Insert("Purpose", RowOfProduct.Purpose);
		If Not RowOfProduct.DifferentSeriesAccounting Then
			ProductsSearch.Insert("Series", RowOfProduct.Series);
		EndIf;
		ProductsSearch.Insert("Warehouse", RowOfProduct.StorageLocation);
		ProductLines_2 = Object.Goods.FindRows(ProductsSearch);
		
		If ProductLines_2.Count() = 0 Then
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.Warehouse = RowOfProduct.StorageLocation;
			CanAddLine = True;
		ElsIf ProductLines_2.Count() = 1 Then
			CurrentRow = ProductLines_2[0];
		ElsIf ProductLines_2.Count() > 1 Then
			For Each RowToDelete In ProductLines_2 Do
				Object.Goods.Delete(RowToDelete);
			EndDo;
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.Warehouse = RowOfProduct.StorageLocation;
			CanAddLine = True;
		EndIf;
		
		CurrentRow.Count = RowOfProduct.QuantityIsSelected;
		If FillInOverOrder And CanAddLine Then
			CurrentRow.SalesOrder = CurrentOrder;
			UpdateOrderDeviationsInLine(CurrentRow, True, Object.BusinessOperation);
		EndIf;
		RowsArray.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	StructureOfPriceCalculationActions = New Structure;
	StructureOfPriceCalculationActions.Insert("RecalculateAmount");
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, RowsArray, PriceFillingParameters,
		StructureOfPriceCalculationActions);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	TabularPartProducts = Object.Goods.Unload(,"Products, Characteristic, ItemVariantsAreUsed, Package,
		|NumberOfPackages, Series, BatchesIndicationStatus, ItemsType, Warehouse");
	TabularPartProducts.GroupBy("Products, Characteristic, ItemVariantsAreUsed, Package, Series,
		|BatchesIndicationStatus, ItemsType, Warehouse", "NumberOfPackages");
	
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
		
		Filter = New Structure("Products, Characteristic, Series, BatchesIndicationStatus, Package, Warehouse");
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
				UpdateOrderDeviationsInLine(TSRow, Object.ByOrder, Object.BusinessOperation);
				RowsToProcess.Add(TSRow);
				
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			UpdateOrderDeviationsInLine(TSRow, Object.ByOrder, Object.BusinessOperation);
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

	FillInArticleAttribute         = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
		WarehouseGroup_);

	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);

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
	
	WhenChangingWarehouseInTablePartServer();
	
	If Not ProcessedLinesAreNew.Count() = 0 Then
		UpdateDependentDetailsOfOrderForm_Server();
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure FillSetVisibilityAndReFillAvailabilityByShipment()
	
	Items.GoodsRefillByShipment.Enabled = AdvancedWarehousingOnShipment;
	SeriesSpecificationParameters                             = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(Object,Documents.GoodsShipmentFromStorage));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsFillInSeriesByFEFO.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	
	OpenSelectionOfSeries(, CurrentData);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject, SeriesSpecificationParameters, Text, CurrentData) Then
		
		If Not Items.GoodsSpecifySeries.Enabled Then
			Return;
		EndIf;
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		AdditionalParameters     = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
		CallbackDescription          = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject,
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
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId,
		ThisObject);
	
EndFunction

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, SeriesSpecificationParameters,
		IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Function ThereAreFilledSeriesByFEFO()
	
	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Object.Goods);
	
EndFunction

&AtServer
Function FillInSeriesByFEFOServer()
	
	If ProductsServer.ThereAreLinesWithFEFOFilledSeries_(Object.Goods) Then
		ProductsServer.FillInSeriesByFEFO(Object, SeriesSpecificationParameters);
		FormEvents.WhenChangingElement(ThisObject, "Goods");
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion

#Region Delivery

&AtServer
Procedure SpecialTransportationConditionsOnChangeServer()
	
	GoodsDelivery.SpecialTransportationConditionsOnChange(Items, Object);
	
EndProcedure

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
	
EndProcedure

&AtClient
Procedure ProcessAddressChange(Item, NameOfAddressDetails)
	
	AttributesNames = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses(NameOfAddressDetails);
	
	If IsBlankString(Object[AttributesNames.NameOfDetailsOfDeliveryAddress]) Then
		
		GoodsDeliveryClient.ClearAddressPresentation(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
	Else
		
		GoodsDeliveryClient.WhenChangingAddressPresentation(
			Item,
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
		DeliveryAddressOnChangeATServer(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues]);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeliveryAddressOnChangeATServer(Address, AddressValue, FieldValueAddress)
	
	CustomFormatAddress = ContactsManager.AddressEnteredInFreeFormat(AddressValue);
	If Not CustomFormatAddress Then
		
		CountryData1 = ContactsManager.ContactInformationAddressCountry(AddressValue);
		
		NewAddressStructure = ContactsManager.InfoAboutAddress();
		NewAddressStructure.Presentation = Address;
		NewAddressStructure.Country = CountryData1.Description;
		NewAddressStructure.CountryCode = CountryData1.Code;
		
		AddressValue = ContactsManager.ContactInformationInJSON(
			NewAddressStructure,
			Enums.ContactInformationTypes.Address);
		
		SetAddressTypeInFreeForm(AddressValue);
		
	EndIf;
	
	FieldValueAddress = ContactsManager.ContactInformationToXML(
		AddressValue,
		Address,
		Enums.ContactInformationTypes.Address);
	
EndProcedure

&AtServerNoContext
Procedure SetAddressTypeInFreeForm(DeliveryAddressValue)
	
	StringTypeToReplace = """addressType"": ""Administrative-territorial""";
	StringIsFreeType = """addressType"": ""FreeForm""";
	DeliveryAddressValue = StrReplace(DeliveryAddressValue, StringTypeToReplace, StringIsFreeType);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TextsFieldsDocumentsBasedOn.Clear();
	UpdateTextDocumentsBasedOnLocalization();
	TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	GivingOperations = New ValueList;
	GivingOperations.Add(Enums.BusinessTransactions.TransferToMaterialProvider2_5);
	GivingOperations.Add(Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	// Setting the conditional design for the 'Warehouse' element
	WarehousesServer.SetConditionalAppearanceOfWarehouseInHeader(ThisObject);
	
	// Setting the conditional design for the 'Partner Nomenclature' element of the 'Products' tabular part.
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
	
	// Setting the conditional design for the items of the nomenclature of the tabular part 'Goods'.
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject,
		"SeriesWhenPlanningShipmentWHGoodsAreIndicated");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	
	// Setting the conditional design for the 'Price' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = GivingOperations;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Setting the conditional design for the 'Amount' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Sum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = GivingOperations;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Setting the conditional design for the 'Warehouse' element of the 'Goods' tabular part
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting the conditional design for the 'Division' element
	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisObject);
	
	// Setting the conditional design for the 'Activity Direction' element
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.DeliveryForPrincipal;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.DeliveryForPrincipal;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không có đơn hàng nào được chọn';
													|ru = 'Заказ не выбран';
													|en = 'No orders selected'; fa = 'No orders selected';
													|it = 'Nessun ordine selezionato';
													|pl = 'Nie wybrano zamówienia';
													|tr = 'Sipariş seçilmedi'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.DeliveryForPrincipal;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentInflow.Name);
	
	TransactionList = New ValueList;
	TransactionList.Add(Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale);
	TransactionList.Add(Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = TransactionList;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("UseReportToMaterialProviderBySeveralOrders2_5");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ByOrder");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Basis");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("UseReportToMaterialProviderBySeveralOrders2_5");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ByOrder");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Basis");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnToMaterialProvider2_5;
	
	Item.Appearance.SetParameterValue("Visible", False);

	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Basis");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vượt quá trên đơn hàng, chưa chọn đơn hàng';
													|ru = 'Сверх заказа, заказ не выбран';
													|en = 'In excess of the order, the order is not selected'; fa = 'In excess of the order, the order is not selected';
													|it = 'Oltre all''ordine, l''ordine non è selezionato';
													|pl = 'Przewyższa zamówienie, zamówienie nie wybrane';
													|tr = 'Sipariş fazlası, sipariş seçilmedi'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	SelectionGroupAnd = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Basis");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.DeliveryForPrincipal;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	GivingOperations = New ValueList;
	GivingOperations.Add(Enums.BusinessTransactions.TransferToMaterialProvider2_5);
	GivingOperations.Add(Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = GivingOperations;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	UseLinesOfBusiness  = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UseSaleByMultipleOrders = GetFunctionalOption("UseSaleByMultipleOrders");
	UseSalesOrders = GetFunctionalOption("UseSalesOrders");
	UseMaterialProviderOrder2_5                  = GetFunctionalOption("UseMaterialProviderOrder2_5");
	UseReportToMaterialProviderBySeveralOrders2_5 =
		GetFunctionalOption("UseReportToMaterialProviderBySeveralOrders2_5");
	DisableControlOfManufacturedProductTransferToProvider = UserRightsCached.DisableControlOfManufacturedProductTransferToProvider();
	
	BusinessOperationSelectionList = Items.BusinessOperation.ChoiceList;
	Documents.GoodsShipmentFromStorage.FillInListOfBusinessOperations(BusinessOperationSelectionList);
	
	Items.BusinessOperation.Visible = BusinessOperationSelectionList.Count() > 1;
	
	If Not ValueIsFilled(Object.BusinessOperation)
	   And Items.BusinessOperation.ChoiceList.Count() = 1 Then
		Object.BusinessOperation = BusinessOperationSelectionList[0].Value;
	EndIf;
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	SetUpConnectionsForContractSelectionParameters();
	
	UpdateOrderDeviations();
	CustomizeForm(ThisObject);
	
	UpdateDependentDetailsOfOrderForm_Server();
	
	Warehouse                         = Object.Warehouse;
	DocumentCurrency               = Object.Currency;
	UseOptionsForSeparatingProductsInSalesContract = (Constants.OptionOfGoodsAssignmentInSales.Get() = Enums.OptionsOfGoodsAssignmentInSales.Contract);
	If Object.BusinessOperation = Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale Then
		ContractBusinessTransaction = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		ContractBusinessTransaction = Enums.BusinessTransactions.DeliveryForPrincipal;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		  Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		ContractBusinessTransaction = TollingSchemeClientServer.ContractBusinessTransaction();
	EndIf;
	
	BasisChanged = False;
	If AccessRight("Update", Metadata.Documents.GoodsShipmentFromStorage) Then
		
		PrintBasisTable.Load(Documents.GoodsShipmentFromStorage.PrintBasisTable(Object));
		BaseStructure = Documents.GoodsShipmentFromStorage.StructureOfBaseForPrinting(Object);
		BasisChanged =
			TrimAll(Object.BasisForPrint) <> BaseStructure.BasisForPrint
			Or TrimAll(Object.BaseDocumentNumber) <> BaseStructure.BaseDocumentNumber
			Or Object.ReferenceDocumentDateForPrintForms <> BaseStructure.ReferenceDocumentDateForPrintForms;
		
	EndIf;
	
	AssignmentsServer.OnReadCreateAtServer(ThisObject);
	
	InstallBase();
	
	SetVisibilityByOrder(ThisObject);
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	WarehouseOnChangeServer();
	
	FillInServiceDetailsForProductRange();
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	BackgroundTaskData =
		GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object, Object.ByOrder,,,True);
	
	UpdateTextDocumentsBasedOn();
	
EndProcedure

&AtClient
Procedure EnableWaitingHandlerReceivingCarriers()
	
	If BackgroundTaskData.Property("JobID") Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("UpdateListOfCarriersNotification", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(
			BackgroundTaskData, CallbackOnCompletion, IdleParameters);
	EndIf;

EndProcedure

&AtClient
Procedure UpdateListOfCarriersNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		GoodsDeliveryClient.UpdateListOfCarriers(Items.CarrierPartner.ChoiceList, Result);
		RefreshDataRepresentation(Items.CarrierPartner);
		BackgroundTaskData = New Structure;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateVisibilityOfAgreements()

	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
		
		Items.Terms.Visible = False;
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5")
	 Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5") Then
		
		Items.Terms.Visible = False;
		
	ElsIf ValueIsFilled(Object.Partner) Then
		NumberOfSupplierAgreements = PurchasesServerCall.GetNumberOfAgreementsWithSupplier(Object.Partner);
		Items.Terms.Visible = NumberOfSupplierAgreements > 0;
	EndIf

EndProcedure

&AtServerNoContext
Procedure SetVisibilityOfAgreements(Partner, BusinessOperation, AgreementElement)
	
	If BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		
		AgreementElement.Visible = False;
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
	 Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		
		AgreementElement.Visible = False;
		
	ElsIf ValueIsFilled(Partner) Then
		NumberOfSupplierAgreements = PurchasesServerCall.GetNumberOfAgreementsWithSupplier(Partner);
		AgreementElement.Visible = NumberOfSupplierAgreements > 0;
	EndIf
	
EndProcedure

// Sets the visibility of the elements depending on the value of the "Order" Attribute.
// 
// Parameters:
//  Form - ClientApplicationForm -
//
&AtClientAtServerNoContext
Procedure SetVisibilityByOrder(Form)
	
	Items = Form.Items;
	Object   = Form.Object;
	
	ItemArray = New Array;
	If Not Object.BusinessOperation =
					PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
		ItemArray.Add("GoodsUnlinkFromOrder");
		ItemArray.Add("GoodsContextMenuUnlinkFromOrder");
	EndIf;
	ItemArray.Add("GoodsGroupSalesOrder");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemArray, "Visible", Object.ByOrder And OrdersUse(Form));
	
EndProcedure

&AtClient
Procedure QuestionUserBeforeFillingInPricesByAgreement(CallbackDescription)
	
	If Object.Goods.Count() = 0
		Or Not ValueIsFilled(Object.Terms) Then
		RunCallback(CallbackDescription, False);
		
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Điền lại giá theo thỏa thuận?';
					|ru = 'Перезаполнить цены по соглашению?';
					|en = 'Refill prices by terms of sales?'; fa = 'Refill prices by terms of sales?';
					|it = 'Ricompilare i prezzi in base all''accordo?';
					|pl = 'Wypełnić ceny ponownie wg porozumienia?';
					|tr = 'Fiyatlar anlaşmaya göre yeniden doldurulsun mu?'");
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True, NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Ricompilare';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False, NStr("vi = 'Không điền lại';
									|ru = 'Не перезаполнять';
									|en = 'Do not refill'; fa = 'Do not refill';
									|it = 'Non ricompilare';
									|pl = 'Nie wypełniaj ponownie';
									|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(CallbackDescription, QueryText, AnswersOptions);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInArticleAttribute                    = New Structure("Products", "SKU");
	FillInProductTypeAttribute_            = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
		FillInFeatureAttribute);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", ParametersForFillingInBankingDetails);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_, False);
	
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses,
		TotalWarehouses_);
	
	TableWarehouses            = Object.Goods.Unload(, "Warehouse").UnloadColumn("Warehouse");
	AdvancedWarehousingOnShipment = WarehousesServer.ThereIsOrderWarehouseForShipment(TableWarehouses, Object.Date, Object.Warehouse);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	
	FillInArticleAttribute         = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
		WarehouseGroup_);
	
	StructureOfActionsAddedLines = CommonClientServer.CopyStructure(
		ActionStructureModifiedStrings);
	StructureOfActionsAddedLines.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	StructureOfActionsAddedLines.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(Object, AddressOfContainerInStorage, "Goods",
		"Products,Characteristic,Warehouse", ActionStructureModifiedStrings, StructureOfActionsAddedLines);
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
		WarehouseGroup_);
	
	StructureOfActions    = New Structure;
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	ItemsFromStorage    = GetFromTempStorage(GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	RowsToProcess = New Array();
	
	For Each RowOfGoods In ItemsFromStorage Do
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods,, "RowCode");
		RowsToProcess.Add(StringTSGoods);
		UpdateOrderDeviationsInLine(StringTSGoods, Object.ByOrder, Object.BusinessOperation);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	For Each RowOfGoods In Object.Goods Do
		FillInCustomerSOrderForIntendedPurpose(StringTSGoods, Object, ListOfGrounds);
	EndDo;
	
	WhenChangingWarehouseInTablePartServer();
	UpdateDependentDetailsOfOrderForm_Server();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtServer
Procedure ExecuteRecalculateDocumentAmountsServer(OldCurrency, NewCurrency)
	
	If OldCurrency <> NewCurrency Then
		DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date,CurrentSessionDate());
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisObject, OldCurrency, NewCurrency, LocalAccountingCurrency, DocumentDate);
		StructureOfOldCurrencyRates = CourseStructures.StructureOfOldCurrencyRates;
		StructureOfNewCurrencyRates  = CourseStructures.StructureOfNewCurrencyRates;
		
		// Recalculate the price
		PriceManagementSystem.ConvertAmountsToCurrencyProducts(
			Object, OldCurrency, NewCurrency, StructureOfOldCurrencyRates, StructureOfNewCurrencyRates, False);
		
		// Recalculate the amount
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount");
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	If UseLinesOfBusiness Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.Currency;
		AddlParameters.LineOfBusiness = Object.LineOfBusiness;
		Contract = PurchasesServer.GetDefaultContract(Object, ContractBusinessTransaction, AddlParameters);
			
	Else
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.Currency;
		Contract = PurchasesServer.GetDefaultContract(Object, ContractBusinessTransaction, AddlParameters);
		
	EndIf;
	
	If Contract <> Object.Contract Then
		
		Object.Contract = Contract;
		
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
			Object.CounterpartyBankAccount);
		
		FillInAttributesFromContract();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAttributesFromContract()
	
	If ValueIsFilled(Object.Contract) Then
		
		ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "ARAPCurrency, Department");
		Object.Department = ContractDetails_.Department;
		
		If Not ValueIsFilled(Object.Currency) Then
			Object.Currency   = ContractDetails_.ARAPCurrency;
			DocumentCurrency = Object.Currency;
		EndIf;
		
		FillInSubordinatePropertiesForStatistics("Contract");
		
	EndIf;
	
	FillBaseForPrinting();
	
	PrintBasisTable.Load(Documents.GoodsShipmentFromStorage.PrintBasisTable(Object));
	
EndProcedure

&AtServerNoContext
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse)
	
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	
EndFunction

&AtServer
Procedure SetParametersForSelectingProductsWarehouse()
	
	WarehouseSelectionData                  = WarehouseSelectionData(Object.Warehouse);
	Items.GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	TMCommonUseClientServer.AddSelectionParameter(Items.GoodsWarehouse, "Ref", WarehouseSelectionData);
	
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
	|	AND Warehouses.SelectGroup <> VALUE(Enum.SelectWarehouseGroup.Disable)";
	
	Query.SetParameter("GroupOfWarehouses", Warehouse);
	
	WarehouseArray = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return WarehouseArray;
	
EndFunction

&AtClient
Procedure SelectionOfGoodsAcceptedForResponsibleStorage()
	
	Cancel = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Partner) Then
		ErrorText = CommonClientServer.FillingErrorText( , , Items.Partner.Title);
		CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.Partner", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
										|ru = 'Поле ""Организация"" не заполнено';
										|en = '""Company"" is required'; fa = '""Company"" is required';
										|it = 'Il campo ""Società"" non è compilato';
										|pl = 'Nie wypełniono pola ""Firma""';
										|tr = '""İş yeri"" alanı doldurulmadı'"), Object.Ref,
			"Object.Organization", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Warehouse) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Kho bãi""';
										|ru = 'Поле ""Склад"" не заполнено';
										|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
										|it = 'Il campo ""Magazzino"" non è compilato';
										|pl = 'Nie wypełniono pola ""Magazyn""';
										|tr = '""Ambar"" alanı doldurulmamış'"), Object.Ref,
			"Object.Warehouse", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		CommonClient.MessageToUser(NStr("vi = 'Trường ""Hợp đồng"" chưa điền';
										|ru = 'Поле ""Договор"" не заполнено';
										|en = '""Contract"" is not filled in.'; fa = '""Contract"" is not filled in.';
										|it = 'Il campo ""Accordo"" non è compilato';
										|pl = 'Pole ""Umowa"" nie jest wypełnione';
										|tr = '""Sözleşme"" alanı doldurulmamış'"), Object.Ref,
			"Object.Contract", "", Cancel);
	EndIf;
	
	If Not Cancel Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Owner",              Object.Partner);
		FormParameters.Insert("Date",                  Object.Date);
		FormParameters.Insert("Organization",           Object.Organization);
		FormParameters.Insert("Warehouse",                 Object.Warehouse);
		FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
		FormParameters.Insert("Contract",               Object.Contract);
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
			FormParameters.Insert("Assignments",               PrincipalAssignment);
			If ValueIsFilled(Object.Basis) Then
				ArrayOfBases = New ValueList();
				ArrayOfBases.Add(Object.Basis);
				FormParameters.Insert("OrderList", ArrayOfBases);
			Else	
				FormParameters.Insert("OrderList", ListOfGrounds);
			EndIf;
			FormParameters.Insert("ByOrder", Object.ByOrder);
			UpdateOrderShipmentFlag();
			FormParameters.Insert("AdvancedWarehousingOnShipment", AdvancedWarehousingOnShipment);
			AddressOfTheShipmentItemsInTheTemporaryStorage = GetAddressOfStorageOfEnteredData();
			FormParameters.Insert("AddressOfTheShipmentItemsInTheTemporaryStorage", AddressOfTheShipmentItemsInTheTemporaryStorage);
			FormParameters.Insert("DocumentShipments", Object.Ref);
			FormParameters.Insert("Counterparty", Object.Counterparty);
			
			OpenForm("Document.GoodsShipmentFromStorage.Form.FormOfGoodSelectionByPurchaseForPrincipal", FormParameters, ThisObject,
				UUID);
			
		Else
		
			AddressOfGoods = PlaceGoodsInStorageForSelectionOfAcceptedGoods();
			
			FormParameters.Insert("Ref", Object.Ref);
			FormParameters.Insert("AddressOfGoodsInvoiceInVault", AddressOfGoods);
			If Object.BusinessOperation =
							PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5") Then
				
				FormParameters.Insert("Title", NStr("vi = 'Lựa chọn sản phẩm xuất xưởng';
													|ru = 'Подбор выпущенной продукции';
													|en = 'Pick released goods'; fa = 'انتخاب کالای تولیدشده';
													|it = 'Selezione di prodotti rilasciati';
													|pl = 'Wybór wypuszczonej produkcji';
													|tr = 'Piyasaya sürülen ürünlerin seçimi'"));
				
				InventoryTypes = New ValueList;
				InventoryTypes.Add(PredefinedValue("Enum.InventoryTypes.ProductsOfMaterialProvider"));
				If DisableControlOfManufacturedProductTransferToProvider Then
					InventoryTypes.Add(PredefinedValue("Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider"));
				EndIf;
				
				FormParameters.Insert("InventoryType", InventoryTypes);
				
			ElsIf Object.BusinessOperation =
								PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5") Then
				
				FormParameters.Insert(
					"InventoryType", PredefinedValue("Enum.InventoryTypes.MaterialOfMaterialProvider"));
				
			EndIf;
			OpenForm("DataProcessor.SelectGoodsReceivedForCustody.Form.Form", FormParameters, ThisObject,
				UUID);
			
		EndIf;
			
	EndIf;
	
EndProcedure

&AtServer
Function PlaceGoodsInTemporaryStorageServer()
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(Object.Goods);
	
EndFunction

&AtServer
Function PlaceGoodsInStorageForSelectionOfAcceptedGoods()
	
	Columns = "LineNumber, Products, Characteristic, Purpose, Series, BatchesIndicationStatus, Warehouse, Count";
	
	Result = Object.Goods.Unload(, Columns);
	
	Result.Columns.Warehouse.Name = "StorageLocation";
	
	Address = PutToTempStorage(Result, UUID);
	
	Return Address;
	
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	TableOfGoods = GetFromTempStorage(AddressInTempStorage); // DocumentTabularSection.GoodsShipmentFromStorage.Goods
	
	FillInArticleAttribute                    = New Structure("Products", "SKU");
	FillInProductTypeAttribute_            = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	
	CheckFillWarehouse = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
		WarehouseGroup_);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",                    FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",            FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each CurRow In TableOfGoods Do
		
		Filter                = New Structure("LineNumber", CurRow.LineNumber);
		ArrayOfCollectionRows = Object.Goods.FindRows(Filter);
		
		If ArrayOfCollectionRows.Count() <> 1 Then
			Continue;
		Else
			CollectionRow = ArrayOfCollectionRows[0];
		EndIf;
		
		FillPropertyValues(CollectionRow, CurRow, "Products, Characteristic, Package");
		RowsToProcess.Add(CollectionRow);
		
	EndDo;
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure RefillByShipmentCompletion(ShipmentStatus, FillWithUnassembledGoods = False)
	
	HasChanges = FillInShippingServer(ShipmentStatus, FillWithUnassembledGoods);
	
	SalesClient.NotifyEndOfReplenishmentOfGoodsForShipment(HasChanges,
		ShipmentStatus.ThereAreShippedGoods
			Or ShipmentStatus.ThereAreUnassembledGoods);
	
EndProcedure

&AtServer
Function FillInShippingServer(ShipmentStatus, FillWithUnassembledGoods = False)
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmount");
	
	FillInArticleAttribute         = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	
	StructureOfActionsWithAddedStrings.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmount");
	
	ParametersStructure = SalesServer.StructureOfDocumentToFillInForActualShipment();
	
	FillPropertyValues(ParametersStructure, Object);
	FillPropertyValues(ParametersStructure, ShipmentStatus);
	
	ParametersStructure.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	ParametersStructure.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	ParametersStructure.FillWithUnassembledGoods          = FillWithUnassembledGoods;
	ParametersStructure.PaddingLines                        = True;
	ParametersStructure.SeriesSpecificationParameters                 = ProductsServer.SeriesSpecificationParameters(Object,
		Documents.GoodsShipmentFromStorage);
	ParametersStructure.WarehouseInTablePart                   = WarehouseGroup_;
	
	HasChanges = SalesServer.FillInByActualShipment(Object, ParametersStructure);
	
	Return HasChanges;
	
EndFunction

&AtServer
Function FillThePricesByTermsOfSalesServer(OnAllLines = False, ErrorText = "")
	
	If OnAllLines Then
		RowsArray = Undefined;
	Else
		RowsArray = New Array;
		
		For Each String In Items.Goods.SelectedRows Do
			RowsArray.Add(Object.Goods.FindByID(String));
		EndDo;
		
	EndIf;
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields", "Price");
	FillParameters.Insert("Date",           Object.Date);
	FillParameters.Insert("Currency",         Object.Currency);
	FillParameters.Insert("Terms",     Object.Terms);
	FillParameters.Insert("Organization", Object.Organization);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(VendorPriceKind)
	
	RowsArray = New Array;
	
	For Each String In Items.Goods.SelectedRows Do
		TableRow = Object.Goods.FindByID(String);
		
		RowsArray.Add(TableRow);
	EndDo;
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields",    "Price");
	FillParameters.Insert("Date",              Object.Date);
	FillParameters.Insert("Currency",            Object.Currency);
	FillParameters.Insert("VendorPriceKind", VendorPriceKind);
	FillParameters.Insert("Organization", Object.Organization);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.Goods, ArrayOfSelectedRows, Warehouse);
	
	If FilledWithRows > 0 Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		WhenChangingWarehouseInTablePartServer();
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtServer
Procedure FillInReceiptDocumentOnServer(DocumentInflow)
	
	For Each CurrentID In Items.Goods.SelectedRows Do
		CurrentData = Object.Goods.FindByID(CurrentID);
		CurrentData.DocumentInflow = DocumentInflow;
	EndDo;
	
EndProcedure
&AtServer
Procedure FillInFromOrderServer()
	
	Object.Goods.Clear();
	
	If UseSaleByMultipleOrders(ThisObject) Then
		AnArrayOfOrders = Undefined;
	Else
		AnArrayOfOrders = New Array;
		AnArrayOfOrders.Add(Object.Basis);
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("DisplayMessage_1", False);
	
	Documents.GoodsShipmentFromStorage.FillByOrderBalances(
		Object, Object.Goods, Warehouse, AnArrayOfOrders, FillParameters);
	
	UpdateOrderInformation();
	
	FillInServiceDetailsForProductRange();
	
	WhenChangingWarehouseInTablePartServer();
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsShipmentFromStorage);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, New FixedStructure(SeriesSpecificationParameters));
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure RefillByNotes()
	
	FillingStructure = SalesServerCall.ReFillInvoiceForOrders(Object);
	
	If FillingStructure.HasChanges Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Function LinkShipmentLinesToOrders(SelectByOrder_)
	
	If Not GetFunctionalOption("UseMaterialProviderOrder2_5")
	 Or Not UseSaleByMultipleOrders(ThisObject) And Not ValueIsFilled(Object.Basis) Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.SalesOrder.SalesOpportunity AS SalesOpportunity,
	|	OrdersTable.SalesOrder        AS SalesOrder,
	|	OrdersTable.Products        AS Products,
	|	OrdersTable.Characteristic      AS Characteristic,
	|	OrdersTable.RowCode           AS RowCode,
	|	OrdersTable.Warehouse               AS Warehouse,
	|	OrdersTable.Series               AS Series,
	|	SUM(OrdersTable.ToTransfer)    AS ToTransferBalance
	|INTO Orders
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder     AS SalesOrder,
	|		TurnoversByOrders.Products     AS Products,
	|		TurnoversByOrders.Characteristic   AS Characteristic,
	|		TurnoversByOrders.RowCode        AS RowCode,
	|		TurnoversByOrders.Warehouse            AS Warehouse,
	|		TurnoversByOrders.Series            AS Series,
	|		(TurnoversByOrders.QuantityToBeShippedTurnover
	|			- TurnoversByOrders.ShippedQuantityTurnover) AS ToTransfer
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded AS TurnoversByOrders
	|	WHERE
	|		(TurnoversByOrders.QuantityToBeShippedTurnover
	|			- TurnoversByOrders.ShippedQuantityTurnover) <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		OrdersRegisterRecords.ReferenceOrder   AS SalesOrder,
	|		OrdersRegisterRecords.Products   AS Products,
	|		OrdersRegisterRecords.Characteristic AS Characteristic,
	|		OrdersRegisterRecords.RowCode      AS RowCode,
	|		OrdersRegisterRecords.Warehouse          AS Warehouse,
	|		OrdersRegisterRecords.Series          AS Series,
	|		CASE
	|			WHEN OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
	|				THEN -OrdersRegisterRecords.Count
	|			ELSE OrdersRegisterRecords.Count
	|		END AS ToTransfer
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
	|	WHERE
	|		OrdersRegisterRecords.Recorder = &Recorder
	|		AND OrdersRegisterRecords.Factor IN
	|			(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|		AND OrdersRegisterRecords.Active
	|		AND CASE
	|			WHEN &SelectByOrder_
	|				THEN OrdersRegisterRecords.ReferenceOrder = &SalesOrder
	|			ELSE OrdersRegisterRecords.ReferenceOrder.Partner     = &Partner
	|				AND OrdersRegisterRecords.ReferenceOrder.Counterparty  = &Counterparty
	|				AND OrdersRegisterRecords.ReferenceOrder.Contract     = &Contract
	|				AND OrdersRegisterRecords.ReferenceOrder.Organization = &Organization
	|				AND OrdersRegisterRecords.ReferenceOrder.Currency      = &Currency
	|				AND OrdersRegisterRecords.ReferenceOrder.SalesOpportunity      = &SalesOpportunity
	|				AND (NOT &UseLinesOfBusiness
	|					OR OrdersRegisterRecords.ReferenceOrder.LineOfBusiness = &LineOfBusiness)
	|				AND OrdersRegisterRecords.ReferenceOrder.BusinessOperation IN (&EconomicOperationsOfOrders)
	|		END
	|		AND CASE
	|			WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
	|				THEN OrdersRegisterRecords.Warehouse IN HIERARCHY (&Warehouse)
	|					OR OrdersRegisterRecords.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE OrdersRegisterRecords.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &Warehouse)
	|		END
	|		AND (OrdersRegisterRecords.Products, OrdersRegisterRecords.Characteristic) IN
	|				(SELECT
	|					Goods.Products   AS Products,
	|					Goods.Characteristic AS Characteristic
	|				FROM
	|					Goods AS Goods)) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.SalesOrder,
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.RowCode,
	|	OrdersTable.Warehouse,
	|	OrdersTable.Series,
	|	OrdersTable.SalesOrder.SalesOpportunity
	|
	|HAVING
	|	SUM(OrdersTable.ToTransfer) > 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(*)         AS DuplicateCount,
	|	Orders.Products   AS Products,
	|	Orders.Characteristic AS Characteristic,
	|	Orders.Series          AS Series,
	|	Orders.Warehouse          AS Warehouse
	|INTO DuplicatesOfProducts
	|FROM
	|	Orders AS Orders
	|
	|GROUP BY
	|	Orders.Products,
	|	Orders.Characteristic,
	|	Orders.Series,
	|	Orders.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Orders.SalesOrder            AS SalesOrder,
	|	Orders.Products            AS Products,
	|	Orders.Characteristic          AS Characteristic,
	|	Orders.RowCode               AS RowCode,
	|	CASE
	|		WHEN GiverSOrder2_5Products.WithAssignment
	|			THEN Orders.SalesOrder.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                          AS Purpose,
	|	Orders.Warehouse                   AS Warehouse,
	|	Orders.Series                   AS Series,
	|	Orders.ToTransferBalance        AS ToTransferBalance,
	|	0                              AS Allocated,
	|	DuplicatesOfProducts.DuplicateCount  AS DuplicateCount
	|FROM
	|	Orders AS Orders
	|
	|		LEFT JOIN DuplicatesOfProducts AS DuplicatesOfProducts
	|		ON Orders.Products   = DuplicatesOfProducts.Products
	|		 AND Orders.Characteristic = DuplicatesOfProducts.Characteristic
	|		 AND Orders.Warehouse          = DuplicatesOfProducts.Warehouse
	|		 AND Orders.Series          = DuplicatesOfProducts.Series
	|
	|		LEFT JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS GiverSOrder2_5Products
	|		ON Orders.SalesOrder = GiverSOrder2_5Products.Ref
	|		 AND Orders.RowCode    = GiverSOrder2_5Products.RowCode
	|
	|ORDER BY
	|	GiverSOrder2_5Products.Products,
	|	GiverSOrder2_5Products.Characteristic,
	|	GiverSOrder2_5Products.Warehouse,
	|	GiverSOrder2_5Products.Series,
	|	GiverSOrder2_5Products.DateOfShipment,
	|	GiverSOrder2_5Products.Ref,
	|	GiverSOrder2_5Products.LineNumber
	|";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"CASE
		|				WHEN &SelectByOrder_
		|					THEN ReferenceOrder = &SalesOrder
		|				ELSE ReferenceOrder.Partner = &Partner
		|					AND ReferenceOrder.Counterparty = &Counterparty
		|					AND ReferenceOrder.Contract = &Contract
		|					AND ReferenceOrder.Organization = &Organization
		|					AND ReferenceOrder.Currency = &Currency
		|					AND ReferenceOrder.SalesOpportunity = &SalesOpportunity
		|					AND (NOT &UseLinesOfBusiness
		|						OR ReferenceOrder.LineOfBusiness = &LineOfBusiness)
		|					AND ReferenceOrder.BusinessOperation IN (&EconomicOperationsOfOrders)
		|			END
		|		AND CASE
		|				WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
		|					THEN Warehouse IN HIERARCHY (&Warehouse)
		|					OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|				ELSE Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &Warehouse)
		|			END
		|		AND (Products, Characteristic) IN
		|			(SELECT
		|					Goods.Products AS Products,
		|					Goods.Characteristic AS Characteristic
		|				FROM
		|					Goods AS Goods)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	Query.SetParameter("SalesOrder",            Object.Basis);
	Query.SetParameter("Partner",                 Object.Partner);
	Query.SetParameter("Counterparty",              Object.Counterparty);
	Query.SetParameter("Contract",                 Object.Contract);
	Query.SetParameter("Organization",             Object.Organization);
	Query.SetParameter("SalesOpportunity",                  Object.SalesOpportunity);
	Query.SetParameter("Currency",                  Object.Currency);
	Query.SetParameter("Warehouse",                   Object.Warehouse);
	Query.SetParameter("Recorder",             Object.Ref);
	Query.SetParameter("SelectByOrder_",        SelectByOrder_);
	Query.SetParameter("LineOfBusiness", Object.LineOfBusiness);
	Query.SetParameter(
		"UseLinesOfBusiness",
		GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness"));
	
	EconomicOperationsOfOrders = New Array;
	EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.TransferToMaterialProvider2_5);
	EconomicOperationsOfOrders.Add(TollingSchemeClientServer.ContractBusinessTransaction());
	EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.Subcontracting2_5);
	EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
	EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5);
	EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
	
	Query.SetParameter("EconomicOperationsOfOrders", EconomicOperationsOfOrders);
	
	Query.SetParameter(
		"Goods", Object.Goods.Unload(, "RowCode, Products, Characteristic, SalesOrder"));
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.ExecuteBatch();
	If QueryResult[1].IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = QueryResult[3].Select();
	
	TableOfUnallocatedGoods = New ValueTable();
	TableOfUnallocatedGoods.Columns.Add("Products");
	TableOfUnallocatedGoods.Columns.Add("Characteristic");
	TableOfUnallocatedGoods.Columns.Add("Warehouse");
	TableOfUnallocatedGoods.Columns.Add("Series");
	TableOfUnallocatedGoods.Columns.Add("SalesOrder");
	TableOfUnallocatedGoods.Columns.Add("RowCode");
	TableOfUnallocatedGoods.Columns.Add("Count");
	TableOfUnallocatedGoods.Columns.Add("Purpose");
	
	While Selection.Next() Do
		
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("Products",   Selection.Products);
		TheStructureOfTheSearch.Insert("Characteristic", Selection.Characteristic);
		TheStructureOfTheSearch.Insert("Warehouse",          Selection.Warehouse);
		TheStructureOfTheSearch.Insert("Series",          Selection.Series);
		TheStructureOfTheSearch.Insert("RowCode",      0);
		
		FoundRows = Object.Goods.FindRows(TheStructureOfTheSearch);
		RetainedQuantity = Selection.ToTransferBalance;
		
		// If there are no duplicates, we distribute the order line to the invoice lines
		If Selection.DuplicateCount < 2 Then
		
			For Each CurRow In FoundRows Do
			
				FillPropertyValues(CurRow, Selection, "RowCode, SalesOrder, Purpose");
				RetainedQuantity = RetainedQuantity - CurRow.Count;
				
				If RetainedQuantity <= 0 Then
					Break;
				EndIf;
			
			EndDo;
			
		// If there are duplicates, we distribute the order lines according to the invoice lines, taking into account the quantity.
		Else
			
			// On the first pass, we will fill in only if the quantity in the order line and the invoice match.
			
			MatchingStringFound = False;
			
			For Each CurRow In FoundRows Do
				
				If CurRow.Count = Selection.ToTransferBalance Then
					
					MatchingStringFound = True;
					FillPropertyValues(CurRow, Selection, "RowCode, SalesOrder, Purpose");
					
					Break;
					
				EndIf;
				
			EndDo;
			
			If Not MatchingStringFound Then
				
				NewRow = TableOfUnallocatedGoods.Add();
				FillPropertyValues(NewRow, Selection);
				NewRow.Count = RetainedQuantity;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// We will distribute duplicates of goods that were not distributed on the first pass
	If TableOfUnallocatedGoods.Count() > 0 Then

		RowsToProcess = New Array;

		For Each UnallocatedRow In TableOfUnallocatedGoods Do
			
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("RowCode",      0);
			TheStructureOfTheSearch.Insert("SalesOrder",   Undefined);
			TheStructureOfTheSearch.Insert("Products",   UnallocatedRow.Products);
			TheStructureOfTheSearch.Insert("Characteristic", UnallocatedRow.Characteristic);
			TheStructureOfTheSearch.Insert("Warehouse",          UnallocatedRow.Warehouse);
			TheStructureOfTheSearch.Insert("Series",          UnallocatedRow.Series);
			
			ProductLines_3 = Object.Goods.FindRows(TheStructureOfTheSearch);
			
			For Each LineProducts_ In ProductLines_3 Do
				
				If LineProducts_.Count = UnallocatedRow.Count Then
					
					FillPropertyValues(
						LineProducts_, UnallocatedRow, "RowCode, SalesOrder, Purpose");
					
					UnallocatedRow.Count = 0;
					
				ElsIf LineProducts_.Count > UnallocatedRow.Count Then
					
					Difference = LineProducts_.Count - UnallocatedRow.Count;
					
					NewLineProducts = Object.Goods.Add();
					FillPropertyValues(NewLineProducts, LineProducts_);
					NewLineProducts.Count = Difference;
					ProductLines_3.Add(NewLineProducts);
					
					FillPropertyValues(
						LineProducts_, UnallocatedRow, "RowCode, SalesOrder, Purpose, Count");
					
					UnallocatedRow.Count = 0;
					
					RowsToProcess.Add(NewLineProducts);
					
					RowsToProcess.Add(LineProducts_);
					
				ElsIf LineProducts_.Count < UnallocatedRow.Count Then
					
					Difference = UnallocatedRow.Count - LineProducts_.Count;
					
					FillPropertyValues(
						LineProducts_, UnallocatedRow, "RowCode, SalesOrder, Purpose");
					
					UnallocatedRow.Count = Difference;
					
				EndIf;
				
				If UnallocatedRow.Count = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		EndDo;

		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages");
		StructureOfActions.Insert("RecalculateAmount");

		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			Undefined);

		UpdateOrderDeviations();
	
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	Return True;
	
EndFunction

&AtServer
Procedure ProcessingProductSelectionFromOrder(AddressInStorage)
	
	CalculationResult1 = GetFromTempStorage(AddressInStorage);
	Table = CalculationResult1.Goods; //ValueTable
	
	FieldsNames = "LineNumber";
	TheStructureOfTheSearch = New Structure(FieldsNames);
	Table.Sort(FieldsNames + " Desc");
	
	// Grouping a table by row keys.
	StringTree = New Array;
	For Each TableRow In Table Do
		
		If TheStructureOfTheSearch.LineNumber <> TableRow.LineNumber Then
			
			RowsArray = New Array;
			StringTree.Add(RowsArray);
			
			FillPropertyValues(TheStructureOfTheSearch, TableRow);
			
		EndIf;
		
		RowsArray.Add(TableRow);
		
	EndDo;
	
	OrderRelationshipFields = New Structure;
	OrderRelationshipFields.Insert("RowCode",    0);
	OrderRelationshipFields.Insert("SalesOrder", Documents.MaterialProviderOrder2_5.EmptyRef());
	
	AddedRows = InvoicesServer.FillInProductsSelectedFromOrder(
		StringTree, FieldsNames, Object.Goods, OrderRelationshipFields);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",         New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, ValuesInCache);
	
	For Each LineProducts_ In AddedRows Do
		If ValueIsFilled(LineProducts_.SalesOrder) Then
			Object.ByOrder = True;
			Continue;
		EndIf;
	EndDo;
	
	InstallBase();
	UpdateOrderDeviations();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SalesServerLocalization.TransferBarcodesOfPackages(ThisObject, CalculationResult1.PackageBarcodes);
	
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtServer
Procedure UnlinkFromOrderServer(AllRows = True, UntieOnlyStrings = True)
	
	Var CachedValues;
	
	AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	
	StructureOfActions = New Structure;
	
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	If AllRows Then
		RowsCollection = Object.Goods;
	Else
		RowsCollection = Items.Goods.SelectedRows;
	EndIf;
	
	RowsToProcess = New Array;
	
	For Each CurRow In RowsCollection Do
		
		TableRow = ?(AllRows, CurRow, Object.Goods.FindByID(CurRow));
		
		ProductsClientServer.UpdateCachedValuesToAccountForSeries(TableRow,CachedValues,SeriesSpecificationParameters);
		
		TableRow.RowCode = 0;
		
		If UntieOnlyStrings Then
			TableRow.OrderDiscrepancy_3 = 1;
		Else
			TableRow.SalesOrder = Undefined;
		EndIf;
		
		RowsToProcess.Add(CurRow);
		// Reassign the series lines
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			Object, SeriesSpecificationParameters, TableRow.GetID(), CachedValues);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	UpdateDependentDetailsOfOrderForm_Server();
	AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateOrderDeviationsInLine(TableRow, ShipmentByOrders, BusinessOperation)
	
	If TableRow <> Undefined Then
		
		GiverSOperation = BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5")
			Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5");
		
		If ShipmentByOrders Then
			TableRow.OrderDiscrepancy_3 = ?(TableRow.RowCode = 0 And GiverSOperation, 1, 0);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOrderDeviations()
	
	For Each TableRow In Object.Goods Do
		UpdateOrderDeviationsInLine(TableRow, Object.ByOrder, Object.BusinessOperation);
	EndDo;
	
EndProcedure

&AtClient
Procedure NotifyAboutEndOfUnbindingLines(NumberOfLinesWorked, LinesWereUnlinked = True)

	If LinesWereUnlinked Then
		
		ShowUserNotification(
			NStr("vi = 'Các dòng đã bỏ liên kết';
				|ru = 'Строки отвязаны';
				|en = 'Lines were unlinked'; fa = 'Lines were unlinked';
				|it = 'Righe dissociate';
				|pl = 'Wierze odłączone';
				|tr = 'Ayrılmış satırlar'"),,
			StrTemplate(NStr("vi = 'Trong chứng từ, bỏ liên kết các dòng với đơn hàng (%1).';
							|ru = 'В документе от заказов отвязано строк (%1).';
							|en = 'In the document, the lines (%1) are unlinked from the orders.'; fa = 'In the document, the lines (%1) are unlinked from the orders.';
							|it = 'Nel documento saranno scollegate le stringhe (%1).';
							|pl = 'W dokumencie odwiązano od zamówień (%1) wierszy.';
							|tr = 'Belgede siparişlerden ayrılmış satırlar (%1) vardır.'"), NumberOfLinesWorked),
			PictureLib.Information32);
		
	Else
		
		ShowUserNotification(
			NStr("vi = 'Các dòng chưa bỏ liên kết';
				|ru = 'Строки не отвязаны';
				|en = 'Lines were not unlinked'; fa = 'Lines were not unlinked';
				|it = 'Righe non dissociate';
				|pl = 'Wierze nie odłączone';
				|tr = 'Birleşik satırlar'"),,
			NStr("vi = 'Không có dòng nào bỏ liên kết.';
				|ru = 'Ни одна строка не была отвязана.';
				|en = 'No line was unlinked.'; fa = 'No line was unlinked.';
				|it = 'Nessuna riga è stata dissociata.';
				|pl = 'Nie odłączono ani jednego wiersza.';
				|tr = 'Hiçbir satır ayrılmamış.'"),
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure
&AtClientAtServerNoContext
Function UseSaleByMultipleOrders(Form)
	
	Object = Form.Object;
	If Object.BusinessOperation =
					PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5") Then
		UseMultipleOrders = Form.UseReportToMaterialProviderBySeveralOrders2_5;
	Else
		UseMultipleOrders = Form.UseSaleByMultipleOrders;
	EndIf;
	Return UseMultipleOrders;
	
EndFunction

&AtClientAtServerNoContext
Function OrdersUse(Form)
	
	Object = Form.Object;
	If Object.BusinessOperation =
					PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5") Then
		OrdersUse = Form.UseMaterialProviderOrder2_5;
	Else
		OrdersUse = Form.UseSalesOrders;
	EndIf;
	Return OrdersUse;
	
EndFunction

&AtServer
Procedure UpdateDependentDetailsOfOrderForm_Server()
	
	If Object.Goods.Count() = 0
	 Or Not Object.ByOrder
	 Or Not UseMaterialProviderOrder2_5 Then
	 	
		Items.GroupLabelDiscrepancyOrder.Visible = False;
		Items.GroupLabelDiscrepancyOrders.Visible = False;
		
		DiscrepancyOrderText = "";
		
		If Object.Goods.Count() > 0 Then
			RowsArray = Object.Goods.FindRows(New Structure("OrderDiscrepancy_3", 1));
			For Each TableRow In RowsArray Do
				TableRow.OrderDiscrepancy_3 = 0
			EndDo;
		EndIf;
		
	Else
		
		UpdateDependentDetailsOfOrderForm_(Object.Goods, DiscrepancyOrderText, Items);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDependentDetailsOfOrderForm_(Goods, DiscrepancyOrderText, FormItems)
	
	NumberOfDiscrepancies = Goods.Total("OrderDiscrepancy_3");
	
	FormItems.GroupLabelDiscrepancyOrder.Visible = NumberOfDiscrepancies > 0;
	FormItems.GroupLabelDiscrepancyOrders.Visible = NumberOfDiscrepancies > 0;
	
	If NumberOfDiscrepancies > 0 Then
		DiscrepancyOrderText = StrTemplate(NStr("vi = 'Các dòng phía trên đơn hàng: %1';
												|ru = 'Строк сверх заказа: %1';
												|en = 'Lines exceeding the order: %1'; fa = 'Lines exceeding the order: %1';
												|it = 'Righe in eccesso rispetto all''ordine: %1';
												|pl = 'Wierzy przewyższających zamówienie: %1';
												|tr = 'Sipariş fazlası satırı: %1'"), NumberOfDiscrepancies);
	Else
		DiscrepancyOrderText = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenPrintDetails()
		
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	DeliveryOrderData = GoodsDeliveryClientServer.OrderParameters();
	FillPropertyValues(DeliveryOrderData, Object);
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DeliveryAddress",                   Object.DeliveryAddress);
	ParametersStructure.Insert("DeliveryAddressValue",           Object.DeliveryAddressValue);
	ParametersStructure.Insert("DeliveryAddressFieldValues",      Object.DeliveryAddressFieldValues);
	ParametersStructure.Insert("DeliveryOrderData",    DeliveryOrderData);
	ParametersStructure.Insert("Ref",                          Object.Ref);
	ParametersStructure.Insert("ShipperBankAccount",  Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",   Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",       Object.CounterpartyBankAccount);
	ParametersStructure.Insert("Shipper",                Object.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                 Object.GoodsRecipient);
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy",              Object.LetterOfAuthorityIssuedBy);
	ParametersStructure.Insert("PowerOfAttorneyDate",                Object.PowerOfAttorneyDate);
	ParametersStructure.Insert("PowerOfAttorneyPerson",                Object.PowerOfAttorneyPerson);
	ParametersStructure.Insert("PowerOfAttorneyNumber",               Object.PowerOfAttorneyNumber);
	ParametersStructure.Insert("Contract",                         Object.Contract);
	ParametersStructure.Insert("Basis",                       Object.BasisForPrint);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                   Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",                  Object.BaseDocumentNumber);
	ParametersStructure.Insert("IssuiedBy",                        Object.IssuiedBy);
	ParametersStructure.Insert("IssuiedByJobTitle",               Object.IssuiedByJobTitle);
	ParametersStructure.Insert("Partner",                         Object.Partner);
	ParametersStructure.Insert("BusinessOperation",           Object.BusinessOperation);
	ParametersStructure.Insert("Counterparty",                      Object.Counterparty);
	ParametersStructure.Insert("ReadOnly",                  ReadOnly);
	ParametersStructure.Insert("ObjectType",                     "GoodsShipmentFromStorage");
	ParametersStructure.Insert("CompanyBankAccount",       Object.CompanyBankAccount);
	ParametersStructure.Insert("Organization",                     Object.Organization);
	ParametersStructure.Insert("Date",                            Object.Date);
	ParametersStructure.Insert("Director",                    Object.Director);
	ParametersStructure.Insert("ChiefAccountant",                Object.ChiefAccountant);
	ParametersStructure.Insert("PrintBasisTable",       PrintBasisTable);

	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure FillBaseForPrinting()
	
	If Not BasisChanged Then
		BaseStructure = Documents.GoodsShipmentFromStorage.StructureOfBaseForPrinting(Object);
		FillPropertyValues(Object, BaseStructure);
	EndIf;
	
EndProcedure

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

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

// End StandardSubsystems.Properties

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

#EndRegion

#Region ServiceEventHandlersForGoodsFormTableElements

&AtServer
Procedure GoodsAfterDeleteRowServer()
	
	WhenChangingWarehouseInTablePartServer();
	InstallBase();
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer(RowID, Handlers, CachedValues)
	
	If Handlers.UpdateSeriesStatuses Then
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, SeriesSpecificationParameters,
			RowID, CachedValues);
	EndIf;
	
	If Handlers.ServerCallRequired__ Then
		FormEvents.WhenChangingElement(ThisObject, "Goods");
	EndIf;
	
	If Handlers.InstallBase Then
		InstallBase();
	EndIf;
	
	If Handlers.NewRow Then
		
		TableRow = Object.Goods.FindByID(RowID);
		If (Object.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5)
				And ValueIsFilled(TableRow.SalesOrder) Then
			TableRow.Purpose = Common.ObjectAttributeValue(TableRow.SalesOrder, "Purpose");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure BusinessOperationOnChangeCompletion(Response, AdditionalParameters) Export
	
	If Response = "ClearGoods" Then
		PerformActionsONChangesOfOperations(
			AdditionalParameters.NeedToCleanUpPartner,
			AdditionalParameters.NeedToClearGoods,
			False);
	ElsIf Response = "Cancel" Then
		Object.BusinessOperation = AdditionalParameters.OldBusinessOperation;
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformActionsONChangesOfOperations(NeedToCleanUpPartner, NeedToClearGoods = False, SkipSettingUpHouseholdOfOperation = False)
	
	If NeedToCleanUpPartner Then
		Object.Partner    = PredefinedValue("Catalog.Partners.EmptyRef");
		Object.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
		Object.Contract    = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
		PartnerOnChange(Items.Partner);
		CounterpartyOnChange(Items.Counterparty);
		ContractOnChange(Items.Contract);
	EndIf;
	
	If NeedToClearGoods And Object.Goods.Count() > 0 Then
		Object.Goods.Clear();
	EndIf;
	SetUpConnectionsForContractSelectionParameters();
	SetBusinessTransactionForContractAndSelectPartner();
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtServer
Procedure UpdateOrderShipmentFlag()
	TableWarehouses = Object.Goods.Unload(,"Warehouse").UnloadColumn("Warehouse");
	AdvancedWarehousingOnShipment = WarehousesServer.ThereIsOrderWarehouseForShipment(TableWarehouses, Object.Date, Object.Warehouse);
EndProcedure

&AtClient
Procedure SetBusinessTransactionForContractAndSelectPartner()
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale") Then
			Object.ByOrder = False;
	ElsIf Object.BusinessOperation =
								PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5")
		  Or Object.BusinessOperation =
		  						PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5") Then
		
		Object.ByOrder  = False;
		Object.Basis = Undefined;
	Else
			If Not TypeOf(Object.Basis) = Type("DocumentRef.SalesOrder") Then
				Object.Basis = Undefined;
			EndIf;
	EndIf;
	
	SetFieldHeadersForBusinessTransactions();
	InstallBase();
	
EndProcedure

&AtClient
Procedure SetFieldHeadersForBusinessTransactions()
	
	NewArray = New Array;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale") Then
			ContractBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale");
			NewArray.Add(New ChoiceParameter("Filter.Vendor", True));
			Items.UseTheBase.Enabled = True;
			Items.GoodsSalesOrder.Visible = Object.ByOrder;
			Items.GoodsSalesOrder.ChoiceButton = False;
			
			Items.GoodsSalesOrder.Title = NStr("vi = 'Đơn hàng của khách';
												|ru = 'Заказ клиента';
												|en = 'Sales order'; fa = 'سفارش فروش';
												|it = 'Ordine del cliente';
												|pl = 'Zamówienie klienta';
												|tr = 'Satış siparişi'");
			Items.GoodsPickUpTheGoodsAcceptedForSafeStorage.Title =
				NStr("vi = 'Chọn hàng hóa, để bảo quản';
					|ru = 'Подобрать товары, принятые на ответственное хранение';
					|en = 'Select available VMI'; fa = 'انتخاب VMI موجود';
					|it = 'Seleziona le merci accettate per la custodia di sicurezza';
					|pl = 'Wybierz wiersze pozycji przyjęte do depozytowania';
					|tr = 'Sorumlu olunan depoya alınacak ürünleri seçin'");
	ElsIf Object.BusinessOperation =
						PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5") Then
		
		ContractBusinessTransaction = TollingSchemeClientServer.ContractBusinessTransaction();
		
		Items.GoodsSalesOrder.Title = NStr("vi = 'Đơn hàng của bên đặt gia công';
											|ru = 'Заказ давальца';
											|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
											|it = 'Ordine del committente';
											|pl = 'Zamówienie dostawcy';
											|tr = 'Sağlayıcı siparişi'");
		Items.GoodsPickUpTheGoodsAcceptedForSafeStorage.Title =
			NStr("vi = 'Chọn sản phẩm được sản xuất cho bên đặt gia công';
				|ru = 'Подобрать продукцию, произведенную для давальца';
				|en = 'Pick products manufactured for the provider'; fa = 'Pick products manufactured for the provider';
				|it = 'Selezionare i prodotti assemblati per il fornitore';
				|pl = 'Wybierz produkcję, wyprodukowaną dla właściciela surowców';
				|tr = 'Sağlayıcı için üretilen ürünleri seçin'");
		
		Items.GoodsSalesOrder.ChoiceButton = True;
			
		NewArray.Add(New ChoiceParameter("Filter.Client", True));
		NewArray.Add(New ChoiceParameter("Filter.Vendor", True));
		
	ElsIf Object.BusinessOperation =
						PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5") Then
		
		ContractBusinessTransaction = TollingSchemeClientServer.ContractBusinessTransaction();
		
		Items.GoodsSalesOrder.Title = NStr("vi = 'Đơn hàng của bên đặt gia công';
											|ru = 'Заказ давальца';
											|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
											|it = 'Ordine del committente';
											|pl = 'Zamówienie dostawcy';
											|tr = 'Sağlayıcı siparişi'");
		Items.GoodsPickUpTheGoodsAcceptedForSafeStorage.Title =
			NStr("vi = 'Chọn nguyên vật liệu đã nhận từ bên đặt gia công';
				|ru = 'Подобрать сырье, принятое от давальца';
				|en = 'Pick raw materials received from the provider'; fa = 'Pick raw materials received from the provider';
				|it = 'Selezionare le materie prime ricevute dal fornitore';
				|pl = 'Wybierz surowce, przyjęte od właściciela surowców';
				|tr = 'Sağlayıcıdan alınan hammaddeleri seçin'");
		
		NewArray.Add(New ChoiceParameter("Filter.Client", True));
		NewArray.Add(New ChoiceParameter("Filter.Vendor", True));
	Else
			
		ContractBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal");
		NewArray.Add(New ChoiceParameter("Filter.Client", True));
		Items.GoodsSalesOrder.Visible    = Object.ByOrder;
		Items.GoodsSalesOrder.ChoiceButton = False;
		
		Items.GoodsSalesOrder.Title = NStr("vi = 'Đơn hàng của khách';
											|ru = 'Заказ клиента';
											|en = 'Sales order'; fa = 'سفارش فروش';
											|it = 'Ordine del cliente';
											|pl = 'Zamówienie klienta';
											|tr = 'Satış siparişi'");
		Items.GoodsPickUpTheGoodsAcceptedForSafeStorage.Title =
			NStr("vi = 'Chọn hàng hóa, để bảo quản';
				|ru = 'Подобрать товары, принятые на ответственное хранение';
				|en = 'Select available VMI'; fa = 'انتخاب VMI موجود';
				|it = 'Seleziona le merci accettate per la custodia di sicurezza';
				|pl = 'Wybierz wiersze pozycji przyjęte do depozytowania';
				|tr = 'Sorumlu olunan depoya alınacak ürünleri seçin'");
		
	EndIf;
	
	NewParameters = New FixedArray(NewArray);
	Items.Partner.ChoiceParameters = NewParameters;
	
EndProcedure

&AtServer
Procedure InstallBase()
	
	Items.UseTheBase.Enabled = True;
	If Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		
		UpdateOrderInformation();
		If ListOfGrounds.Count() = 1 Then
			Object.Basis = ListOfGrounds[0].Value;
			AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
		ElsIf Not ValueIsFilled(Object.Basis) Then
			Object.Basis = Undefined;
			If ListOfGrounds.Count() = 0 Then
				AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
			EndIf;
		EndIf;
		
		Items.UseTheBase.Enabled = False;
		If UseOptionsForSeparatingProductsInSalesContract Then
			Object.ByOrder = False;
			Items.PagesOrder.Visible = False;
		Else
			Object.ByOrder = True;
			Items.PagesOrder.Visible = True;
		EndIf;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
		
		UpdateOrderInformation();
		
		If Object.ByOrder Then
			
			If ListOfGrounds.Count() > 0 Then
				
				If ListOfGrounds.Count() = 1
				   And Object.Basis <> ListOfGrounds[0].Value Then
					
					Object.Basis = ListOfGrounds[0].Value;
					
				ElsIf Object.Basis <> Undefined
						And Not UseSaleByMultipleOrders(ThisObject) Then
					
					Object.Basis = Undefined;
					
				EndIf;
				
			EndIf;
			
			If Not ValueIsFilled(Object.Basis) And ListOfGrounds.Count() = 0 Then
				Object.ByOrder = False;
			EndIf;
			
		Else
			Object.Basis = Undefined;
		EndIf;
		
		Items.PagesOrder.Visible           = UseMaterialProviderOrder2_5;
		Items.UseTheBase.Enabled = UseMaterialProviderOrder2_5;
		AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		
		Object.ByOrder  = False;
		
		NumberOfBases = ListOfGrounds.Count();
		If NumberOfBases = 1 Then
			If TypeOf(ListOfGrounds[0].Value) <> Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
				Object.Basis = Undefined;
				ListOfGrounds.Clear();
			EndIf;
		ElsIf NumberOfBases > 1 Then
			Object.Basis = Undefined;
			ListOfGrounds.Clear();
		ElsIf ValueIsFilled(Object.Basis)
				And TypeOf(Object.Basis) <> Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
			Object.Basis = Undefined;
		EndIf;	
		
		Items.PagesOrder.Visible = False;
		Items.UseTheBase.Enabled = False;
		AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	Else
		Items.PagesOrder.Visible = False;
		AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	EndIf;
	
	FillBaseForPrinting();
	
	PrintBasisTable.Load(Documents.GoodsShipmentFromStorage.PrintBasisTable(Object));
	
EndProcedure

&AtClient
Procedure NotifyAboutEndOfFillingInPrices(PricesCalculated = True)

	If PricesCalculated Then
		ShowUserNotification(
			NStr("vi = 'Đơn giá điền';
				|ru = 'Цены заполнены';
				|en = 'Prices are filled out'; fa = 'Prices are filled out';
				|it = 'I prezzi sono compilati';
				|pl = 'Wypełniono ceny';
				|tr = 'Fiyatlar doldurulmuştur'"),
			,
			NStr("vi = 'Kiểm tra tính chính xác của giá trong báo cáo cho người đặt ký gửi và hóa đơn được phát hành';
				|ru = 'Проверьте правильность цен в отчете принципалу и счет-фактуре выданной';
				|en = 'Check that the prices in the report to the principal and the commercial invoice issued are correct'; fa = 'Check that the prices in the report to the principal and the commercial invoice issued are correct';
				|it = 'Controllate la correttezza dei prezzi nel report al mandante e nella fattura emessa';
				|pl = 'Sprawdź prawidłowość cen w raporcie do zleceniodawcy i w wydanej fakturze VAT';
				|tr = 'İş verene verilen rapordaki ve kesilen faturadaki fiyatların doğru olup olmadığını kontrol edin'"),
			PictureLib.Information32);
	Else
		ShowUserNotification(
			NStr("vi = 'Chưa điền đơn giá';
				|ru = 'Цены не заполнены';
				|en = 'Prices are not filled in'; fa = 'Prices are not filled in';
				|it = 'I prezzi non sono compilati';
				|pl = 'Nie wypełniono ceny';
				|tr = 'Fiyatlar doldurulmamıştır'"),
			,
			NStr("vi = 'Bạn phải tự điền giá';
				|ru = 'Необходимо вручную заполнить цены';
				|en = 'You should fill in prices manually'; fa = 'You should fill in prices manually';
				|it = 'È necessario compilare i prezzi manualmente';
				|pl = 'Należy ręcznie wypełnić ceny';
				|tr = 'Fiyatların elle doldurulması gerekir'"),
			PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelHeaderSalesOrdersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	If Object.BusinessOperation =
							PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5") Then
		ValueOfHeaderParameter = NStr("vi = 'Đơn hàng của bên đặt gia công (%DocumentsCount%)';
										|ru = 'Заказы давальцев (%DocumentsCount%)';
										|en = 'Subcontracting sales orders (%DocumentsCount%)'; fa = 'Subcontracting sales orders (%DocumentsCount%)';
										|it = 'Ordini dei prestatori (%DocumentsCount%)';
										|pl = 'Zamówienia właścicieli surowca (%DocumentsCount%)';
										|tr = 'Sağlayıcı siparişleri (%DocumentsCount%)'");
	Else
		ValueOfHeaderParameter = NStr("vi = 'Đơn hàng của người đặt ký gửi(%DocumentsCount%)';
										|ru = 'Заказы принципала (%DocumentsCount%)';
										|en = 'Principal''s order (%DocumentsCount%)'; fa = 'Principal''s order (%DocumentsCount%)';
										|it = 'Gli ordini del mandante (%DocumentsCount%)';
										|pl = 'Zamówienia zleceniodawcy (%DocumentsCount%)';
										|tr = 'İş veren siparişi (%DocumentsCount%)'");
	EndIf;
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			ListOfGrounds,
			ValueOfHeaderParameter),
		ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtServer
Function GetAddressOfStorageOfEnteredData()
	
	AddressOfGoods = PutToTempStorage(Object.Goods.Unload());
	
	Return AddressOfGoods;
	
EndFunction

&AtClient
Procedure UseTheBaseOnChange(Item)
	
	ClearMessages();
	If Object.BusinessOperation =
					PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5") Then
		ShipmentByOrdersOnChange();
		Return;
	EndIf;
	If Not (Object.ByOrder Or UseSaleByMultipleOrders(ThisObject)) Then
		If ValueIsFilled(Object.Basis) Then
			MessageToUserText = NStr("vi = 'Các hàng trong bảng hàng hóa không còn được liên kết với chứng từ %BasisObject%.';
									|ru = 'Строки таблицы ""Товары"" больше не связаны с документом %BasisObject%.';
									|en = 'Rows of ""Goods"" table are no longer related to the %BasisObject% document.'; fa = 'Rows of ""Goods"" table are no longer related to the %BasisObject% document.';
									|it = 'Le righe della ""Merci"" non sono più collegati con il documento %BasisObject%.';
									|pl = 'Wiersze tabeli ""Wiersze pozycji"" więcej nie są związane z dokumentem %BasisObject%.';
									|tr = '""Ürünler"" tablosunun satırları artık %BasisObject% belgesine bağlı değildir.'");
			MessageToUserText = StrReplace(MessageToUserText, "%BasisObject%", Object.Basis);
			CommonClient.MessageToUser(MessageToUserText, Object.Ref, "", "", );
		EndIf;	
	EndIf;
	
	Object.Basis = Undefined;
	For Each RowOfGoods In Object.Goods Do
		If Not Object.ByOrder Then
			RowOfGoods.SalesOrder = Undefined;
		EndIf;
	EndDo;
	GivingOperations = New Array;
	GivingOperations.Add(PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5"));
	GivingOperations.Add(PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5"));
	
	If GivingOperations.Find(Object.BusinessOperation) = Undefined Then
		TMCommonUseClientServer.SetFormItemProperty(
			Items, "GoodsSalesOrder", "Visible", Object.ByOrder);
	EndIf;
	InstallBase();
	
EndProcedure

&AtServer
Procedure SelectionProcessingSelectionOfDocumentsForPrincipal(ValueSelected, PricesCalculated)
	
	CalculationResult1 = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	TableOfGoods = CalculationResult1.Goods;
	
	For Each RowOfProduct In TableOfGoods Do
		
		SelectionByLineCode = New Structure();
		SelectionByLineCode.Insert("Purpose", RowOfProduct.Purpose);
		SelectionByLineCode.Insert("Products", RowOfProduct.Products);
		SelectionByLineCode.Insert("Series", RowOfProduct.Series);
		SelectionByLineCode.Insert("Characteristic", RowOfProduct.Characteristic);
		ExcludeColumns = "";
		
		If ValueIsFilled(RowOfProduct.SalesOrder) Then
			SelectionByLineCode.Insert("SalesOrder", RowOfProduct.SalesOrder);
			SelectionByLineCode.Insert("Package", RowOfProduct.Package);
		Else
			ExcludeColumns = "SalesOrder";
		EndIf;
		
		FoundEnteredStrings = Object.Goods.FindRows(SelectionByLineCode);
		For Each FoundRow In FoundEnteredStrings Do
			Object.Goods.Delete(FoundRow);
		EndDo;
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct,,ExcludeColumns);
		
	EndDo;
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	InstallBase();
	SalesServerLocalization.TransferBarcodesOfPackages(ThisObject, CalculationResult1.PackageBarcodes);
	
EndProcedure

&AtServer
Procedure UpdateOrderInformation()
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "ListOfGrounds";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.Basis";
	ParametersOfUpdate.TitleLabelName               = "LabelHeaderSalesOrders";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "GoodsGroupSalesOrder";
	ParametersOfUpdate.OrderNameInTablePart          = "SalesOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseSaleByMultipleOrders(ThisObject);
	ParametersOfUpdate.OrdersUse                = OrdersUse(ThisObject);
	
	OrdersServer.UpdateOrderInformationInForm(ThisObject, Object.Goods, ParametersOfUpdate);
	
EndProcedure

&AtClient
Procedure GoodsSalesOrderStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		Items.Goods.CurrentData.SalesOrder = Result.SalesOrder;
		Items.Goods.CurrentData.Purpose =  Result.Purpose;
	EndIf;
	ProductsCustomerOrderStartSelectionFragment();
	
EndProcedure

&AtClient
Procedure ProductsCustomerOrderStartSelectionFragment()
	
	InstallBase();
	Items.Goods.Refresh();
	
EndProcedure

&AtServerNoContext
Function GetOrderByDestination(CurrentData)
	SalesOrder = Undefined;
	If ValueIsFilled(CurrentData) Then
		SalesOrder = Common.ObjectAttributeValue(CurrentData, "OrderDocument");
	EndIf;
	Return SalesOrder;
EndFunction

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

&AtClientAtServerNoContext
Procedure FillInCustomerSOrderForIntendedPurpose(TheCurrentDataRow, Object, ListOfGrounds)
	If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5") Then
		
		TheCurrentDataRow.SalesOrder =
			?(ListOfGrounds.Count() = 1,
				ListOfGrounds[0].Value,
				?(ListOfGrounds.Count() = 0
					And Object.ByOrder,
					Object.Basis,
					Undefined));
		
		TheCurrentDataRow.RowCode = 0;
		
	ElsIf Object.BusinessOperation <>
						PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5") Then
		TheCurrentDataRow.SalesOrder = GetOrderByDestination(TheCurrentDataRow.Purpose);
	EndIf;
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedLinesSelectionPriceTypeEnd(PriceKind, AdditionalParameters) Export
	
	If ValueIsFilled(PriceKind) Then
		PricesCalculated = FillInPricesOfSelectedLinesByPriceTypeServer(PriceKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PriceKind);
	EndIf;
	
EndProcedure

&AtServer
Function FillInPricesOfSelectedLinesByPriceTypeServer(PriceKind)
	
	PricesCalculated = False;
	RowsArray = New Array;
	
	For Each String In Items.Goods.SelectedRows Do
		TableRow = Object.Goods.FindByID(String);
		RowsArray.Add(TableRow);
	EndDo;
	
	If RowsArray.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa chọn dòng.';
							|ru = 'Не выбраны строки.';
							|en = 'Lines are not selected.'; fa = 'Lines are not selected.';
							|it = 'Не выбраны строки.';
							|pl = 'Lines are not selected.';
							|tr = 'Satırlar seçilmedi.'");
		Common.MessageToUser(MessageText);
	Else
		FillParameters = EnterprisePricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.PopulationFields = "Price";
		FillParameters.Date           = Object.Date;
		FillParameters.Currency         = Object.Currency;
		FillParameters.PriceKind        = PriceKind;
		FillParameters.Organization    = Object.Organization;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount");
		
		PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, StructureOfActions);
	EndIf;
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesByCostsServer(CachedValues)
	
	RowsArray = New Array;
	
	For Each String In Items.Goods.SelectedRows Do
		TableRow = Object.Goods.FindByID(String);
		RowsArray.Add(TableRow);
	EndDo;

	RequestingPreliminaryData = New Query;
	RequestingPreliminaryData.Text = 
	"SELECT
	|	InventoryCostCalculationCompanies.Ref.PreliminaryCalculation AS PreliminaryCalculation
	|FROM
	|	Document.InventoryCostCalculation.Companies AS InventoryCostCalculationCompanies
	|WHERE
	|	InventoryCostCalculationCompanies.Ref.Posted
	|	AND InventoryCostCalculationCompanies.Organization = &Organization
	|	AND InventoryCostCalculationCompanies.Ref.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef)
	|	AND InventoryCostCalculationCompanies.Ref.Date BETWEEN BEGINOFPERIOD(&Date, MONTH) AND ENDOFPERIOD(&Date, MONTH)";
	
	RequestingPreliminaryData.SetParameter("Date", Object.Date);
	RequestingPreliminaryData.SetParameter("Organization", Object.Organization);
	PreliminaryData = RequestingPreliminaryData.Execute().Select();
	
	If PreliminaryData.Next() Then
		PreliminaryCalculation = PreliminaryData.PreliminaryCalculation;
	ElsIf RowsArray.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa chọn dòng.';
							|ru = 'Не выбраны строки.';
							|en = 'Lines are not selected.'; fa = 'Lines are not selected.';
							|it = 'Не выбраны строки.';
							|pl = 'Lines are not selected.';
							|tr = 'Satırlar seçilmedi.'");
		Common.MessageToUser(MessageText);
		Return False;
	Else
		MessageText = NStr("vi = 'Không thể điền đơn giá theo giá vốn trong chứng từ %Document%: trong %Period% chưa tính giá vốn.';
							|ru = 'Не удалось заполнить цены по себестоимости в документе %Document%: на %Period% не произведен расчет себестоимости.';
							|en = 'Cannot fill in prices by cost in document %Document%: cost is not calculated for %Period%.'; fa = 'Cannot fill in prices by cost in document %Document%: cost is not calculated for %Period%.';
							|it = 'Impossibile compilare i prezzi al costo di produzione per il documento %Document%: al %Period% non è stato calcolato il costo di produzione.';
							|pl = 'Nie można wypełnić cen w dokumencie %Document%: na okres %Period% wartość kosztu własnego nie została obliczona.';
							|tr = 'Maliyet fiyatları %Document%belgeye doldurulamadı: %Period% üzerinde maliyet hesaplaması yapılmadı.'");
		MessageText = StrReplace(MessageText, "%Document%", Object.Ref);
		MessageText = StrReplace(MessageText, "%Period%", Format(BegOfMonth(Object.Date),"DLF=DD"));
		Common.MessageToUser(MessageText);
		Return False;
	EndIf;
	
	OtherColumnNames = New Structure;
	OtherColumnNames.Insert("Products",   "Products");
	OtherColumnNames.Insert("Characteristic", "Characteristic");

	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Warehouse", Object.Warehouse);
	FillParameters.Insert("PreliminaryCalculation", PreliminaryCalculation);
	FillParameters.Insert("OtherColumnNames", OtherColumnNames);
	FillParameters.Insert("PopulationFields", "PriceOffBalance");
	
	PriceIsFilledIn = SalesServer.FillInPricesByCosts(
		Object.Goods, // Table part
		RowsArray, // Selected lines (fill in all lines)
		FillParameters,,CachedValues);
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	If PriceIsFilledIn Then
		
		RowsToProcess = New Array();
		
		For Each RowOfProduct In RowsArray Do
			If RowOfProduct.Price <> RowOfProduct.PriceOffBalance Then
				RowOfProduct.Price = RowOfProduct.PriceOffBalance;
				RowsToProcess.Add(RowOfProduct);
			EndIf;
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			CachedValues);
		
	EndIf;
	
EndFunction

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure SetLBEditingOption()
	
	LBAvailabilityParameters = LinesOfBusinessServer.ParametersLBEditingCapability();
	
	LBAvailabilityParameters.OrderInvoice_3 = Object.ByOrder;
	LBAvailabilityParameters.Contract           = Object.Contract;
	LBAvailabilityParameters.ARAPObjectSettings   = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	
	LinesOfBusinessServer.SetLBEditingOption(ThisObject, LBAvailabilityParameters);
	
EndProcedure

#EndRegion

#Region Localization

&AtClient
Procedure NotificationProcessingLocalization(EventName, Parameter, Source)
	
	
	Return;
	
EndProcedure


&AtServer
Procedure UpdateTextDocumentsBasedOnLocalization()
	
	
	Return;
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessingLocalization(FormattedStringURL, StandardProcessing)
	

	Return;
	
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

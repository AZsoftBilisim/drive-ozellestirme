#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var PreviousRowDetails; //used to unlink the receipt line from the order line

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
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		Items.GroupDiscrepancyOnOrder.Visible = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
	EndIf;
	
	If Parameters.FillByWarehouseDocument 
		Or Parameters.FillingValues.Property("FillByWarehouseDocument") 
		Or (ValueIsFilled(Parameters.Basis) 
			And TypeOf(Parameters.Basis) = Type("Structure")
			And Parameters.Basis.Property("FillByWarehouseDocument")) 
		Then
		
		LinkLinesToOrder = False;
		LinkLinesToOrder =
			ValueIsFilled(Parameters.Key)
			And Object.ReceiptUnderOrders
			And Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
		FillInServerAcceptanceForm(False, LinkLinesToOrder);
		Modified = True;
		
	EndIf;
	
	SetAvailabilityAgreements();
	
	PurchasesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	
	If Not UsePurchaseOrders Then
		Items.PicturePriceDeviationOrder.Visible = False;
		Items.PicturePriceDeviationOrders.Visible = False;
		Items.GroupDiscrepancyOnOrder.Visible = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
	EndIf;
	
	If Not Object.ReceiptUnderOrders Then
		Items.GoodsPictureIndex.Visible = False; 
	EndIf;

	If UseReceiptForMultipleOrders Then
		Items.GoodsSelectGoodsByOrdersNotes.Title = NStr("vi = 'Chọn hàng hóa từ đơn hàng';
														|ru = 'Подобрать товары из заказов';
														|en = 'Pick goods from orders'; fa = 'Pick goods from orders';
														|it = 'Selezionare le merci dagli ordini';
														|pl = 'Dobierz wiersze pozycji z zamówienia';
														|tr = 'Siparişlerden mal seçme'");
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	SetTitleFillInByOrdersOrders();
	UpdateDestinationPresentation();
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		Items.CloseOrder.Enabled = False;
	Else
		Items.CloseOrder.Enabled = AccessRight("Update",Metadata.Documents.PurchaseOrder);
	EndIf;
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject, Object.Date);
	
	
	SetAvailabilityOfClipboardCommands();
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.LogOfPurchaseDocuments.Form.SelectionOfGoodsFromOrderForm" Then
		
		GetProductsFromStorage(SelectionResult.GoodsAddressInStorage);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(SelectionResult);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(SelectionResult.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, SelectionResult);
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(SelectionResult);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
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
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting
		And Object.Goods.Count() > 0
		And (Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.OfferToFillIn")
			Or Not ValueIsFilled(Object.ReusablePackageFillingStatus)) Then
		
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
	
	If EventName = "ClosingOrders" And Parameter = Object.Ref Then
		ProcessOrderClosingNotification();
	EndIf;

	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		
		SetAvailabilityAgreements();
		
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
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
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		Actions = New Structure;
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			Actions,
			"Warehouse",
			True);
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, , , Actions);
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.No Then
		
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
		
	EndIf;
	
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

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_GoodsReceiptForStorage", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
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
	
	FillInPricesOfOrderProductRange();
	FillInShopPantryAttributeInTable(False);
	UpdateDestinationPresentation();
	
	CustomizeForm();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	
	
	UnlockFormDataForEdit();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	PreviousRowDetails = New Structure(
		"PartnerProducts,
		|Products,
		|Characteristic,
		|Purpose,
		|Package,
		|Count,
		|NumberOfPackages,
		|Warehouse,
		|ItemsType,
		|ItemVariantsAreUsed,
		|PurchaseOrder,
		|RowCode");
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	EnableWaitingHandlerReceivingCarriers();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
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

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * CurrentRow - FormDataCollectionItem - 
// * Item - FormGroup, FormTable, FormField, FormButton - Form element
// * CallbackDescription - CallbackDescription - 
&AtClient
Function AdditionalCompletionProcessingParameters()
	
	Result = New Structure;
	Result.Insert("CurrentRow");
	Result.Insert("Item");
	Result.Insert("CallbackDescription");
	Return Result;
	
EndFunction

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
	QuestionUserBeforeFillingInPricesByAgreement(
		New CallbackDescription("PartnerWhenChangingQuestionEnds", ThisObject, AdditionalParameters));
	
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

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract();
		
		If Not ValueIsFilled(Object.CounterpartyBankAccount) Then
			Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
		EndIf;
		FillInSubordinatePropertiesForStatistics("Counterparty");
		
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		SetLBEditingOption();
	EndIf;
	
	RowsArray = AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	UpdateDestinationPresentation();
	If RowsArray.Count() > 0
	 Or DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Object.PurchaseOrder, Object.Contract);
		FillInAttributesFromContract();
	EndIf;
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptForStorage,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	If DocumentCurrency <> Object.Currency Then
		CurrencyOnChange(Items.Currency);
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
			Object.CompanyBankAccount);
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
			SetLBEditingOption();
		EndIf;
		
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	RowsArray = AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	UpdateDestinationPresentation();
	If RowsArray.Count() > 0
	 Or DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Object.PurchaseOrder, Object.Contract);
		FillInAttributesFromContract();
	EndIf;
	
	WhenChangingKeyDetailsStatusOfEDO();
	RecalculateNumberOfRNPT();
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptForStorage,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
	If DocumentCurrency <> Object.Currency Then
		CurrencyOnChange(Items.Currency);
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	QuestionUserBeforeFillingInPricesByAgreement(
		New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure AgreementWhenChangingQuestionCompletion(UserAnswer, AdditionalParameters) Export
	
	WhenChangingAgreementAtServer(
		ValueIsFilled(Object.Terms)
		And Object.Goods.Count() > 0
		And UserAnswer);

	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	PurchasesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	WhenChangingAgreementServer(CachedValues, True);
	
	If DocumentCurrency <> Object.Currency Then
		CurrencyOnChange(Items.Currency);
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Warehouse <> Object.Warehouse Then
		
		PreviousValueWarehouseGroup = WarehouseGroup_;
		
		If QuestionOfCleaningWarehouseIsNecessary() Then
			
			If WarehouseGroup_ Then
				QueryText = NStr("vi = 'Các dòng theo đơn hàng, mà trong đó kho bãi không nằm trong nhóm kho bãi ""%Warehouse%"" sẽ bị xóa khỏi danh sách ""Hàng hóa"". Tiếp tục?';
								|ru = 'Строки по заказу, в которых склад не входит в группу складов ""%Warehouse%"" будут удалены из списка ""Товары"". Продолжить?';
								|en = 'The order lines containing a warehouse that does not belong to the ""%Warehouse%"" group will be deleted from the Item list. Continue?'; fa = 'The order lines containing a warehouse that does not belong to the ""%Warehouse%"" group will be deleted from the Item list. Continue?';
								|it = 'Le righe per un ordine nel quale il magazzino non è incluso nel gruppo dei magazzini ""%Warehouse%"" verranno cancellate dall''elenco ""Merci"". Continuare?';
								|pl = 'Wiersze zamówienia, w których magazyn nie znajduje się w grupie magazynowej ""%Warehouse%"", zostaną usunięte z listy ""Wiersze pozycji"". Kontynuować?';
								|tr = 'Deponun ""%Warehouse% depo grubunun bir parçası olmadığı sipariş satırları ""Ürünler"" listesinden kaldırılacaktır. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Các dòng theo đơn hàng, trong đó kho bãi khác với ""%Warehouse%"" sẽ bị xóa khỏi danh sách ""Hàng hóa"". Tiếp tục?';
								|ru = 'Строки по заказу, в которых склад отличается от ""%Warehouse%"" будут удалены из списка ""Товары"". Продолжить?';
								|en = 'The order lines containing a warehouse other than ""%Warehouse%"" will be deleted from the Item list. Continue?'; fa = 'The order lines containing a warehouse other than ""%Warehouse%"" will be deleted from the Item list. Continue?';
								|it = 'Le righe per un ordine nel quale il magazzino è diverso da ""%Warehouse%"" verranno cancellate dall''elenco ""Merci"". Continuare?';
								|pl = 'Wiersze zamówienia, w których magazyn różni się od ""%Warehouse%"" zostaną usunięte z listy ""Wiersze pozycji"". Kontynuować?';
								|tr = '""%Warehouse%"" dışında bir stok içeren bir sipariş satırları ""Ürünler"" listesinden kaldırılacaktır. Devam edilsin mi?'");
			EndIf;
			
			QueryText = StrReplace(QueryText, "%Warehouse%", Object.Warehouse);
			
			ShowQueryBox(New CallbackDescription("WarehouseOnChangeCompletion",
													ThisObject,
													New Structure("PreviousValueWarehouseGroup", PreviousValueWarehouseGroup)),
							QueryText,
							QuestionDialogMode.YesNo);
			
			Return;
			
		EndIf;
		
		WhenChangingWarehouseServer(True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    PreviousValueWarehouseGroup = AdditionalParameters.PreviousValueWarehouseGroup;
    
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        
        Object.Warehouse = Warehouse;
        WarehouseGroup_ = PreviousValueWarehouseGroup;
        Return;
        
    EndIf;
    
    
    WhenChangingWarehouseServer(True);

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	
	RecalculatePrices_2 = False;
	
	If Not Object.ReceiptUnderOrders  Then
		Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
		Return;
	EndIf;
	
	PricesCalculated = DateOnChangeServer(RecalculatePrices_2);
	DocumentDateBeforeChange = Object.Date;
	
	If RecalculatePrices_2 Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodPlaceOfDeliveryCarrierIfChanged(Item)
	
	FillInAndSetDeliveryAttributesServer(Item.Name);
	
EndProcedure

&AtClient
Procedure OpenAContract(Item)
	If ValueIsFilled(Object.Contract) Then
		OpenForm("Catalog.CounterpartyContracts.Form.ItemForm", 
		New Structure("Key", Object.Contract));
	EndIf;
EndProcedure

&AtClient
Procedure OpenAgreement(Item)
	If ValueIsFilled(Object.Terms) Then
		OpenForm("Catalog.TermsOfPurchaseFromVendors.Form.ItemForm", 
		New Structure("Key", Object.Terms));
	EndIf;
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

&AtServer
Procedure FillInAndSetDeliveryAttributesServer(FormItemName);
	
	GoodsDelivery.FillInDeliveryDetails(Items, FormItemName, Object);
	
EndProcedure

&AtClient
Procedure ReceiptUnderOrdersOnChange(Item)
	
	PurchaseOrder = Undefined;
	
	If Object.ReceiptUnderOrders Then
		
		OpenBaseSelectionForm(True);
			
		Return;
		
	Else
		
		If Object.Goods.Count() > 0 Then
			
			If UseReceiptForMultipleOrders Then
				QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa không còn liên kết với dòng trong đơn hàng. Tiếp tục?';
								|ru = 'Строки в списке Товары перестанут быть связанными со строками заказов. Продолжить?';
								|en = 'The Item list lines will be unlinked from the lines in the orders. Continue?'; fa = 'The Item list lines will be unlinked from the lines in the orders. Continue?';
								|it = 'Le righe nell''elenco Merci non saranno più associate alle righe degli ordini. Continuare?';
								|pl = 'Wiersze na liście Wiersze pozycji nie będą więcej powiązane z wierszami zamówień. Kontynuować?';
								|tr = 'Ürünler listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa không còn liên kết với dòng trong đơn hàng. Tiếp tục?';
								|ru = 'Строки в списке Товары перестанут быть связанными со строками заказа. Продолжить?';
								|en = 'The Item list lines will be unlinked from the order lines. Continue?'; fa = 'The Item list lines will be unlinked from the order lines. Continue?';
								|it = 'Le righe nell''elenco Merci non saranno più associate alle righe dell''ordine. Continuare?';
								|pl = 'Wiersze na liście Wiersze pozycji nie będą więcej powiązane z wierszami zamówienia. Kontynuować?';
								|tr = 'Ürünler listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
			EndIf;
			
		Else
			
			WhenChangingReceiptsForMultipleOrders();
			Return;
			
		EndIf;
		
	EndIf;
	
	ReceiptForOrdersWhenFragmentChanges(PurchaseOrder, QueryText);
EndProcedure

&AtClient
Procedure ReceiptForOrdersWhenChangedAfterSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		If Not ValueIsFilled(Object.PurchaseOrder)
			And OrderList.Count() = 0 Then
			Object.ReceiptUnderOrders = False;
		EndIf;
		Return;
	EndIf;
	
	
	If TypeOf(Result) = Type("Array") And Result.Count() = 1 Then
		PurchaseOrder = Result[0];
	Else
		PurchaseOrder = Result;
	EndIf;
		
	If TypeOf(Result) = Type("Array") And Result.Count() > 1 Then
		QueryText = NStr("vi = 'Sẽ điền lại danh sách Hàng hóa bằng số dư hàng hóa chưa lập theo đơn hàng. Tiếp tục?';
						|ru = 'Список Товары будет перезаполнен по остаткам неоформленных товаров выбранных заказов. Продолжить?';
						|en = 'The Goods list will be refilled with the remaining unregistered goods of selected orders. Continue?'; fa = 'The Goods list will be refilled with the remaining unregistered goods of selected orders. Continue?';
						|it = 'L''elenco Merci sarà ricompilato in base ai saldi delle merci non formalizzate degli ordini selezionati. Continuare?';
						|pl = 'Lista Towary zostanie ponownie wypełniona stanem zapasów nieodebranych towarów z zamówień. Kontynuować?';
						|tr = 'Ürünler listesi, seçilen siparişlerin bekleyen kalemlerinin kalanlarıyla yeniden doldurulacaktır. Devam edilsin mi?'");
	ElsIf TypeOf(Result) = Type("Array") And Result.Count() = 0 Then
		QueryText = NStr("vi = 'Sẽ bỏ liên kết danh sách Hàng hóa với đơn hàng. Tiếp tục?';
						|ru = 'Список Товары будет отвязан от заказов. Продолжить?';
						|en = 'The Goods list will be unlinked from orders. Continue?'; fa = 'The Goods list will be unlinked from orders. Continue?';
						|it = 'L''elenco Merci sarà scollegato dagli ordini. Continuare?';
						|pl = 'Lista Towary zostanie odwiązana od zamówień. Kontynuować?';
						|tr = 'Mal listesi siparişlerden ayrıştırılacaktır. Devam edilsin mi?'");
	Else
		QueryText = NStr("vi = 'Sẽ điền danh sách Hàng hóa bằng số dư của hàng hóa chưa được lập theo chứng từ %PurchaseOrder%. Tiếp tục?';
						|ru = 'Список Товары будет заполнен остатками неоформленных товаров по документу %PurchaseOrder%. Продолжить?';
						|en = 'The Goods list will be filled with the remaining unregistered goods by the %PurchaseOrder% document. Continue?'; fa = 'The Goods list will be filled with the remaining unregistered goods by the %PurchaseOrder% document. Continue?';
						|it = 'L''elenco Merci sarà compilato con i saldi delle merci non formalizzate in base al documento %PurchaseOrder%. Continuare?';
						|pl = 'Lista Wiersze pozycji zostanie wypełniona stanem zapasów towarów według dokumentu %PurchaseOrder%. Kontynuować?';
						|tr = 'Ürünler listesi %PurchaseOrder%belgesinden kalan ürünlerle doldurulacaktır. Devam edilsin mi?'");
		QueryText = StrReplace(QueryText, "%PurchaseOrder%", PurchaseOrder);
	EndIf;
	
	ReceiptForOrdersWhenFragmentChanges(PurchaseOrder, QueryText);
	
EndProcedure

&AtClient
Procedure ReceiptForOrdersWhenFragmentChanges(Val PurchaseOrder, Val QueryText)
	
	NotificationParameters	= New Structure("PurchaseOrder", PurchaseOrder);
	CallbackDescription	= New CallbackDescription("ReceiptUnderOrdersOnChangeCompletion",
													ThisObject,
													NotificationParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ReceiptUnderOrdersOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	PurchaseOrder = AdditionalParameters.PurchaseOrder;
	
	If QuestionResult = DialogReturnCode.No Then
		Object.ReceiptUnderOrders = Not Object.ReceiptUnderOrders;
		
		Return;
	EndIf;
	
	OrderList.Clear();
	
	If ValueIsFilled(PurchaseOrder) Then
		If TypeOf(PurchaseOrder) = Type("Array") Then
			If PurchaseOrder.Count() = 1 Then
				Object.PurchaseOrder = PurchaseOrder[0];
				Object.ReceiptUnderOrders = True;
			ElsIf PurchaseOrder.Count() > 1 Then
				OrderList.LoadValues(PurchaseOrder);
				Object.ReceiptUnderOrders = True;
			Else
				Object.ReceiptUnderOrders = False;
			EndIf;
		Else
			Object.PurchaseOrder = PurchaseOrder;
		EndIf;
	Else
		Object.ReceiptUnderOrders = False;
	EndIf;
	
	WhenChangingReceiptsForMultipleOrders();
	
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
Procedure HandedOverByChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	Object.HandedOverBy          = ValueSelected.HandedOverBy;
	Object.HandedOverJobTitle = ValueSelected.HandedOverJobTitle;
	
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
		OnChangeCurrencyOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure VendorPriceKindOnChange(Item)
	
	If Not ValueIsFilled(Object.VendorPriceKind)
		Or Object.Goods.Count() = 0 Then
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
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure


&AtClient
Procedure BusinessOperationOnChange(Item)
	If Object.BusinessOperation = BusinessTransactionBeforeTheChange Then
		Return;
	EndIf;
	
	Object.Partner           = PredefinedValue("Catalog.Partners.EmptyRef");
	Object.Counterparty        = PredefinedValue("Catalog.Counterparties.EmptyRef");
	Object.Contract           = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
	Object.VendorPriceKind = PredefinedValue("Catalog.VendorPriceTypes.EmptyRef");
	PartnerOnChange(Items.Partner);
	CounterpartyOnChange(Items.Counterparty);
	ContractOnChange(Items.Contract);
	VendorPriceKindOnChange(Items.VendorPriceKind);
	
	WhenBusinessTransactionChangesServer();
	Return; // in UT and KA the handler is empty
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure  

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfReceiptOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)

	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters, True);

	If SeriesStatusesNeedToBeUpdated Or UseReceiptForMultipleOrders Then

		GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues); // server call

	Else

		UpdateDependentDetailsOfServerByOrderForm();

	EndIf;

	If SeriesStatusesNeedToBeUpdated Then

		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters);

	EndIf;

	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	WhenChangingWarehouseInTablePartServer();

EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Goods.CurrentData;
	
	If NewRow And CurrentData <> Undefined
		And Object.ReceiptUnderOrders Then
		
		If Not UseReceiptForMultipleOrders Then
			CurrentData.PurchaseOrder = Object.PurchaseOrder;
		EndIf;
		CurrentData.OrderDiscrepancy_3 = 1;
		CurrentData.RowCode = 0;
		CurrentData.OrderPrice = 0;
		
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters, Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	FinishEditingProductsLine(Item, NewRow, CancelEdit);
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If Object.ReceiptUnderOrders Then 
		If CurrentRow <> Undefined Then
			If CurrentRow.RowCode = 0 Then
				CurrentRow.OrderDiscrepancy_3 = 1;
			Else
				CurrentRow.OrderDiscrepancy_3 = 0;
			EndIf;
		EndIf;
		UpdateDependentDetailsOfOrderForm_(
			Items,
			Object.Goods,
			DiscrepancyOrderText);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.Goods.CurrentData <> Undefined Then
		
		If Field = Items.GoodsPurchaseOrder Then
			
			If ValueIsFilled(Items.Goods.CurrentData.PurchaseOrder) Then
				ShowValue(New CallbackDescription("GoodsSelectionCompletion", ThisObject, New Structure("Field", Field)), Items.Goods.CurrentData.PurchaseOrder);
                Return;
			ElsIf ValueIsFilled(Object.PurchaseOrder) Then
				ShowValue(New CallbackDescription("GoodsSelectionCompletion", ThisObject, New Structure("Field", Field)), Object.PurchaseOrder);
                Return;
			EndIf;
			
		ElsIf Field = Items.GoodsSalesOpportunity Then
			
			ShowValue(, Items.Goods.CurrentData.SalesOpportunity);
						
		EndIf;
		
		PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts", NStr("vi = 'Nhà cung cấp';
																										|ru = 'Поставщик';
																										|en = 'Vendor'; fa = 'تأمین‌کننده';
																										|it = 'Fornitore';
																										|pl = 'Dostawca';
																										|tr = 'Tedarikçi'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelectionCompletion(AdditionalParameters) Export
    
    Field = AdditionalParameters.Field;
	
	PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts", NStr("vi = 'Nhà cung cấp';
																									|ru = 'Поставщик';
																									|en = 'Vendor'; fa = 'تأمین‌کننده';
																									|it = 'Fornitore';
																									|pl = 'Dostawca';
																									|tr = 'Tedarikçi'"));

EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	
	FillPropertyValues(PreviousRowDetails, Items.Goods.CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCCDNumberType", FillParameters);
	Actions.Insert("FillInCountryOfOriginForCCDNumber", FillParameters);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions,
		"Warehouse",
		True);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

&AtClient
Procedure GoodsPurchaseOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
		
		OpenBaseSelectionForm(False,CurrentData);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPurchaseOrderStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentData = AdditionalParameters.CurrentData;
	
	Items.Goods.CurrentData.PurchaseOrder = Result.PurchaseOrder;
	
	If ValueIsFilled(CurrentData.PurchaseOrder) Then
		CurrentData.SalesOpportunity = GetDealOnOrderToSupplier(CurrentData.PurchaseOrder);
	Else
		CurrentData.SalesOpportunity = PredefinedValue("Catalog.SalesOpportunitiesToCustomer.EmptyRef");
	EndIf;
	
	AfterSpecifyingOrderInLine(CurrentData);
	
	UpdateOrderInformation();
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInShopPantryAttribute");
	
	If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5") Then
		StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
	EndIf;
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	AdditionalParameters.Insert("StructureOfActions", StructureOfActions);
	
	If CurrentRow.RowCode <> 0 Then
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		AdditionalParameters.Insert("ClearActionStructure", True);
		QuestionUserWhenChangingRowDetails(
			New CallbackDescription("ProductsPartnerSNomenclatureWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
			CurrentRow);
		
	Else
		
		ProductsPartnerSNomenclatureWhenChangingQuestionToUserCompletion(True, AdditionalParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsPartnerSNomenclatureWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	ItemBeforePartnerItemChanges = CurrentRow.Products;
	
	If AdditionalParameters.Property("ClearActionStructure") Then
		StructureOfActions = New Structure;
	Else
		StructureOfActions = AdditionalParameters.StructureOfActions;
	EndIf;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInShopPantryAttribute");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillingOutAppointment = New Structure;
	If CurrentRow.Products <> ItemBeforePartnerItemChanges Then
		AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, FillingOutAppointment);
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, FillingOutAppointment, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsNomenclatureWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure GoodsNomenclatureWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
	
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "Goods"));
	StructureOfActions.Insert("FillInShopPantryAttribute");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsCharacteristicWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure GoodsCharacteristicWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("CharacteristicOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "Goods"));
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
		If Object.ReceiptUnderOrders And CurrentRow.RowCode > 0 Then
			StructureOfActions.Insert("RecalculateOrderPricePerPackage", CurrentRow.Count);
		EndIf;
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
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
	UpdateOrderDeviationsInLine(CurrentRow, Object.ReceiptUnderOrders);
	
	If Object.ReceiptUnderOrders Then
		UpdateLabelForDeviationsFromOrderPrices();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	UpdateOrderDeviationsInLine(CurrentRow, Object.ReceiptUnderOrders);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsWarehouseWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

// Parameters:
//	Result - Boolean - result of the user's response.
//	AdditionalParameters - See AdditionalCompletionProcessingParameters.
&AtClient
Procedure GoodsWarehouseWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		
		WhenChangingWarehouseInTablePartServer();
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters",
													CurrentRow.Warehouse, SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	StructureOfActions.Insert("FillInShopPantryAttribute");
	
	If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5") Then
		StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
	EndIf;
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
EndProcedure

&AtClient
Procedure GoodsPurchaseOrderOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
	
		If ValueIsFilled(CurrentData.PurchaseOrder) Then
			CurrentData.SalesOpportunity = GetDealOnOrderToSupplier(CurrentData.PurchaseOrder);
		Else
			CurrentData.SalesOpportunity = PredefinedValue("Catalog.SalesOpportunitiesToCustomer.EmptyRef");
		EndIf;
		
		AfterSpecifyingOrderInLine(CurrentData);
		
	EndIf;
	
	UpdateOrderInformation();
	
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
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)

	If SeriesStatusesNeedToBeUpdated Then

		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);

	EndIf;

	UpdateOrderInformation();
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = Items.GoodsPartnerProducts.Name Then
		
		CurrentData = Items.Goods.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.GoodsPartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.GoodsPartnerProducts.ChoiceParameters, CurrentData);
		
	ElsIf Item.CurrentItem.Name = Items.GoodsCCDNumber.Name Then
		PurchasesClient.FillInListOfCCDNumberSelection(
			Items.Goods.CurrentData, 
			Items.GoodsCCDNumber.ChoiceList);
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
// End StandardSubsystems.FilesOperations

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


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
	EndIf
	
EndProcedure

&AtClient
Procedure AutoTestFillInPricesByAgreement() Export

	FillThePricesByTermsOfSales(Undefined);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.GoodsReceiptForStorage.Form.DocumentForm.SelectGoods");
	
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
	FormParameters.Insert("Document",        Object.Ref);
	FormParameters.Insert("Partner",         Object.Partner);
	FormParameters.Insert("Terms",      Object.Terms);
	FormParameters.Insert("PriceIncludesVAT", Undefined);
	FormParameters.Insert("Warehouse",      Object.Warehouse);
	FormParameters.Insert("Currency",     Object.Currency);
	FormParameters.Insert("Date",       Object.Date);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders",  True);
	FormParameters.Insert("FilterByProductType", FilterByProductType);
	FormParameters.Insert("HideManualDiscounts", True);
	FormParameters.Insert("VendorPriceKind", Object.VendorPriceKind);
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	
	AddItemsFromSalesOrderGoodsIssue();
	
EndProcedure

&AtClient
Procedure FillInThePricesForReceipts(Command)
	
	If Not ValueIsFilled(Object.Partner) Then
		If Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5") Then
			TextException = NStr("vi = 'Để điền đơn giá theo các lần nhập gần đây, cần chỉ ra bên đặt gia công';
								|ru = 'Для заполнения цен по последним поступлениям необходимо указать давальца';
								|en = 'To fill the prices for the latest receipts, specify the provider'; fa = 'To fill the prices for the latest receipts, specify the provider';
								|it = 'Per la compilazione dei prezzi in base alle ultime ricezioni è necessario indicare il fornitore';
								|pl = 'Aby wypełnić ceny za ostatnie wpływy, należy określić właściciela surowców';
								|tr = 'Son teslimatların fiyatlarını doldurmak için sağlayıcı belirtilmelidir'");
		Else
			TextException = NStr("vi = 'Để điền đơn giá theo lần tiếp nhận gần nhất, cần chỉ ra nhà cung cấp';
								|ru = 'Для заполнения цен по последним поступлениям необходимо указать поставщика';
								|en = 'To fill in the prices for the latest receipts, specify the vendor'; fa = 'To fill in the prices for the latest receipts, specify the vendor';
								|it = 'Per ricompilare i prezzi in base agli ultimi arrivi, è necessario specificare il fornitore';
								|pl = 'Aby wypełnić ceny za ostatnie wpływy, należy określić dostawcę';
								|tr = 'Son teslimatların fiyatlarını doldurmak için tedarikçi belirtilmelidir'");
		EndIf;
		Raise TextException;
		
	EndIf;
	
	PricesAreFilledOut = False;
	FillInPricesForLatestReceipts(PricesAreFilledOut);
	
	If PricesAreFilledOut Then
		Modified = True;
		
		ShowUserNotification(
			NStr("vi = 'Đơn giá điền';
				|ru = 'Цены заполнены';
				|en = 'Prices are filled out'; fa = 'Prices are filled out';
				|it = 'I prezzi sono compilati';
				|pl = 'Wypełniono ceny';
				|tr = 'Fiyatlar doldurulmuştur'"),
			,
			NStr("vi = 'Trong các dòng của chứng từ có điền giá';
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
				|tr = 'Fiyatlar doldurulmamıştır'"),
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
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisObject);
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
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
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
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow = Undefined Then
		MessageText = NStr("vi = 'Hãy chọn dòng của phần bảng';
							|ru = 'Выберите строку табличной части';
							|en = 'Select a table row'; fa = 'Select a table row';
							|it = 'Selezionare una riga della parte tabulare';
							|pl = 'Wybierz wiersz części tabelarycznej';
							|tr = 'Tablo bölümündeki satırı seçin'");
		CommonClient.MessageToUser(MessageText);
		Return
	EndIf;
	
	If ValueIsFilled(CurrentRow.RowCode) Then
		ShowMessageBox(Undefined, NStr("vi = 'Đối với một dòng đặt hàng, không được phép thay đổi chất lượng. Sử dụng lệnh ""Hủy liên kết các dòng với đơn hàng"".';
										|ru = 'Для строки по заказу запрещено изменять качество. Воспользуйтесь командой ""Отвязать строки от заказа"".';
										|en = 'Cannot change quantity for the order line. Use the Unlink lines from the order command.'; fa = 'Cannot change quantity for the order line. Use the Unlink lines from the order command.';
										|it = 'Per la riga sull''ordine è vietato modificare la qualità. Usare il comando ""Scollegare le righe dall''ordine"".';
										|pl = 'Dla wiersza z zamówienia zabrania się zmiana jakości. Użyj polecenia ""Odłącz wiersze od zamówienia"".';
										|tr = 'Bir satır için miktarın siparişe göre değiştirilmesine izin verilmez. ""Satırları siparişten ayır"" komutunu kullanın.'"));
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckPackagingByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	If ValueIsFilled(CurrentRow.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentRow.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentRow.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
	EndIf;	
		
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
	SeriesVerificationParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	SeriesVerificationParameters.Warehouse = CurrentRow.Warehouse;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	NotificationOfSuccessfulExecution = New CallbackDescription("ChangeTheQualityOfTheItemCompletion", ThisObject);
	
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues, NotificationOfSuccessfulExecution);
	
EndProcedure

&AtClient
Procedure ChangeTheQualityOfTheItemCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FinishEditingProductsLine(Items.Goods, False, False);
	
EndProcedure

&AtClient
Procedure FillInCCDNumbers(Command)
	
	NotificationParameters	= New Structure("CCDNumbersFilledIn", Undefined);
	CallbackDescription	= New CallbackDescription("FillInCCDNumbersCompletion", ThisObject, NotificationParameters);
	
	OpenForm("Catalog.CCDNumbers.ChoiceForm",
				,
				ThisObject,
				UUID,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCCDNumbersCompletion(Result, AdditionalParameters) Export
	
	CCDNumber = Result;
	CCDNumbersFilledIn = AdditionalParameters.CCDNumbersFilledIn;
	
	If ValueIsFilled(CCDNumber) Then
		FillInCCDNumbersOnServer(CCDNumber, CCDNumbersFilledIn);
	EndIf;
	
	PurchasesClient.NotifyAboutFillingInGTNumbersInTabularPart(CCDNumbersFilledIn, CCDNumber);
	
EndProcedure

&AtClient
Procedure FillInTheGTDNumbersForReceipts(Command)
	
	FillIn_CCDNumbersForLatestReceipts();
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLines(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, Object.Goods, NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Goods';
																									|tr = 'Ürünler'"), SelectedRows) Then
		FilterStructure1 = New Structure("SelectGroup,IsFolder", PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"), False);
		ParametersStructure = New Structure("Filter,GroupOfWarehouses", FilterStructure1, Object.Warehouse);
		
		OpenForm("Catalog.Warehouses.ChoiceForm",
					ParametersStructure,
					ThisObject,
					,
					,
					,
					New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion",
											ThisObject,
											New Structure("SelectedRows", SelectedRows)),
					FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLinesCompletion(Result, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    SelectedWarehouse = Result;
    If ValueIsFilled(SelectedWarehouse) Then
        FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse);
        WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(SelectedWarehouse, FilledWithRows, SelectedRows.Count());
    EndIf;

EndProcedure

&AtClient
Procedure SplitTheFactString(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	AdditionalParameters = AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(FormTable.CurrentData);
	
	Notification = New CallbackDescription("SplitTheFactStringCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItem(Command)
	
	If Not TMCommonUseClient.CheckForRowsInList(Object.Goods, "Goods") Then
		Return;
	EndIf;
	
	FilterItemsType = New Array;
	FilterItemsType.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	FilterItemsType.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	
	GoodsAddressInStorage = PlaceGoodsInTemporaryStorageServer("Goods");
	PurchasesClient.OpenSupplierProductListForm(
		New CallbackDescription("FillInTheItemByThePartnerSItemCompletion", ThisObject),
		GoodsAddressInStorage,
		ThisObject, FilterItemsType);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItemCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		FillInItemsFromTemporaryStorageServer(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowPriceVariances(Command)
	
	ShowPriceVariances = Not ShowPriceVariances;
	Items.GoodsShowPriceVariances.Check = ShowPriceVariances; 
	Items.Goods.RowFilter = Undefined;
	
	If ShowPriceVariances Then
		Items.Goods.RowFilter = New FixedStructure("PriceChanged", True);
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseOrder(Command)
	
	If ValueIsFilled(Object.PurchaseOrder) Or OrderList.Count() > 0 Then
		If Modified
			Or Not Object.Posted Then
			
			ShowQueryBox(New CallbackDescription("CloseOrderCompletion", ThisObject),
							NStr("vi = 'Chứng từ chưa được kết chuyển. Kết chuyển chứng từ?';
								|ru = 'Документ не проведен. Провести документ?';
								|en = 'The document is not posted. Post the document?'; fa = 'The document is not posted. Post the document?';
								|it = 'Il documento non è registrato. Registrare il documento?';
								|pl = 'Dokument nie został zaksięgowany. Zaksięgować dokument?';
								|tr = 'Belge kaydedilemedi. Belge kaydedilsin mi?'"),
							QuestionDialogMode.YesNo);
			
			Return;
			
		EndIf;
		
		CloseOrderFragment();
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Không có đơn hàng để đóng';
										|ru = 'Нет заказов для закрытия';
										|en = 'No orders for closing'; fa = 'No orders for closing';
										|it = 'Nessun ordine da chiudere';
										|pl = 'Nie ma zamówień do zamknięcia';
										|tr = 'Kapatma emri yok'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseOrderCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response = DialogReturnCode.No Then
        Return;
    ElsIf Not Write(New Structure("WriteMode, PostingMode", DocumentWriteMode.Posting, DocumentPostingMode.RealTime)) Then
        Return;
    EndIf;
    
    CloseOrderFragment();

EndProcedure

&AtClient
Procedure CloseOrderFragment()
    
    ListOfOrdersToClose = New ValueList;
    If ValueIsFilled(Object.PurchaseOrder) Then
        ListOfOrdersToClose.Add(Object.PurchaseOrder)
    Else
        ListOfOrdersToClose.LoadValues(OrderList.UnloadValues())
    EndIf;
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CorrectPrices",          True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure
					,,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
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
	OpeningParameters.Insert("ReceiptUnderOrders",                 Object.ReceiptUnderOrders);
	
	ReturnParameters = Undefined;

	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters,,,,, New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
    
    ReturnParameters = Result;
    
    If ReturnParameters <> Undefined Then
        
        ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, ?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
        Modified = True;
        
    EndIf;

EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
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
Procedure AddReusablePackage(Command)
	
	ReusablePackageClient.SelectReusablePackage(
		ThisObject,
		"Goods",
		"Products,Characteristic,Count,Warehouse");
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.FillInThePartnerSNomenclature = Object.Partner;
	ImportParameters.ImportPrices  = True;
	ImportParameters.ImportAmounts = True;
	ImportParameters.ImportCCD   = True;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer());
	
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

&AtClient
Procedure FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice(Command)
	
	FillInPricesBySupplierPriceType(True);
	
EndProcedure

&AtClient
Procedure ChangeBaseDocuments(Command)
	
	OpenBaseSelectionForm(True);
	
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

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);

	//

	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOpportunity.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOpportunity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOpportunity.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceiptUnderOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Approved");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceiptUnderOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối chiếu đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối chiếu đơn hàng, chưa chọn đơn hàng>';
													|ru = '<сверх заказа, заказ не выбран>';
													|en = '<exceeding the order, the order is not selected>'; fa = '<exceeding the order, the order is not selected>';
													|it = '<oltre all''ordine, l''ordine non è selezionato>';
													|pl = '<przewyższa zamówienie, zamówienie nie wybrane>';
													|tr = '<sipariş fazlası, sipariş seçilmedi>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.PurchaseOrder"));
	
	//
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject);

	//
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOpportunity.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceiptUnderOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceiptUnderOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối chiếu đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));

	//

	WarehousesServer.SetConditionalAppearanceOfWarehouseInHeader(ThisObject);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPercentageOfDeviationFromTheOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPictureIndex.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceiptUnderOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPercentageOfDeviationFromTheOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPictureIndex.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.OrderPrice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("Object.Goods.Price");

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPercentageOfDeviationFromTheOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPictureIndex.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.OrderPrice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("Object.Goods.Price");

	Item.Appearance.SetParameterValue("TextColor", WebColors.Green);

	//
	
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisObject;
	InstallationParameters.ThisIsAdmission        = True;
	
	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False);

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceiptUnderOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject);
	
	// Setting the conditional design for the 'Price' element of the 'Products' tabular part
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
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
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// only view the Destination if the string code is full

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Conditional design of the destination in the list of materials that matches the destination in the header.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("PurposePresentation"));
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields);
	
EndProcedure

&AtServer
Procedure SetLBEditingOption()
	
	LBAvailabilityParameters = LinesOfBusinessServer.ParametersLBEditingCapability();
	
	LBAvailabilityParameters.OrderInvoice_3 = Object.ReceiptUnderOrders;
	LBAvailabilityParameters.Contract           = Object.Contract;
	LBAvailabilityParameters.ARAPObjectSettings   = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	
	LinesOfBusinessServer.SetLBEditingOption(ThisObject, LBAvailabilityParameters);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtServer
Procedure WhenChangingPartnerServer()
	
	If Not ValueIsFilled(Object.Organization) Then
		DescriptionOfBankingDetailsToFillIn = New Structure;
		ParametersOfBankingDetailsToFillIn = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
		ParametersOfBankingDetailsToFillIn.StatisticsCollectionSections.UseAlways = "Author";
		ParametersOfBankingDetailsToFillIn.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
		ParametersOfBankingDetailsToFillIn.FillInIf.ObjectFieldsFilledIn = "Author";
		ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(DescriptionOfBankingDetailsToFillIn, "Organization", ParametersOfBankingDetailsToFillIn);
		
		ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Partner", DescriptionOfBankingDetailsToFillIn);
	EndIf;
	
	DocumentPurchases = FormAttributeToValue("Object");
	DocumentPurchases.FillInDefaultPurchaseConditions(False);
	ResponsiblePersonsServer.FillInManager_(DocumentPurchases, False);
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	SetAvailabilityAgreements();
	
	DocumentCurrency = Object.Currency;
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		SetLBEditingOption();
	EndIf;

	FillInAndSetDeliveryAttributesServer("Partner");
	
	AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	UpdateDestinationPresentation();
	FillInPassedFieldSelectionList();
	FillInSubordinatePropertiesForStatistics("Partner"); // Filling in Passed and passed Due
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	WhenChangingWarehouseServer();
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Object.PurchaseOrder, Object.Contract);
		FillInAttributesFromContract();
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptForStorage,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(RecalculatePrices_2=True)
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Terms) Then
		
		DocumentPurchases = FormAttributeToValue("Object");
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(DocumentPurchases.Terms, True, True);
		DocumentPurchases.FillInTermsOfPurchase(PurchaseConditions);
		ValueToFormAttribute(DocumentPurchases, "Object");
		
		DocumentCurrency = Object.Currency;
		
		If RecalculatePrices_2 Then
			
			FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
			FillParameters.Insert("PopulationFields", "Price");
			FillParameters.Insert("Date",           Object.Date);
			FillParameters.Insert("Currency",         Object.Currency);
			FillParameters.Insert("Terms",     Object.Terms);
			FillParameters.Insert("Organization", Object.Organization);
			
			ActionsWithStrings = New Structure;
			ActionsWithStrings.Insert("RecalculateAmount", "NumberOfPackages");
			
			PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, Undefined, FillParameters, ActionsWithStrings);
			
		EndIf;
		
		WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
		WhenChangingWarehouseServer();
		
		StructureOfNamesOfTableParts = New Structure("Goods");
		FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
		PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
		
		If Object.ReceiptUnderOrders Then
			UpdateOrderDeviations();
		EndIf;
		
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		SetLBEditingOption();
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	RowsArray = AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	UpdateDestinationPresentation();
	If RowsArray.Count() > 0
	 Or DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Object.PurchaseOrder, Object.Contract);
		FillInAttributesFromContract();
	EndIf;
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptForStorage,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementServer(CachedValues, DirectModificationOfContractField = False)
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(
		Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
	FillInAttributesFromContract();
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		SetLBEditingOption();
	EndIf;

	RowsArray = AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	UpdateDestinationPresentation();
	If RowsArray.Count() > 0
	 Or DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Object.PurchaseOrder, Object.Contract);
		FillInCurrencyAccordingToContract();
		FillInSubordinatePropertiesForStatistics("Contract");
	EndIf;
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object, Object.ReceiptUnderOrders,,SummaryDeliveryInformation);
	ResponsiblePersonsServer.FillInManager_(Object);
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptForStorage,
			Object,
			CacheQualityControl,
			DirectModificationOfContractField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseServer(DirectModificationOfWarehouseField = False)
	
	Warehouse = Object.Warehouse;
	
	SetParametersForSelectingProductsWarehouse();
	
	StructureOfResponsible = PurchasesServer.GetWarehouseManager(Object.Warehouse, Object.Manager);
	If StructureOfResponsible <> Undefined Then
		Object.ReceivedBy = StructureOfResponsible.EmployeeResponsible;
		Object.AcceptedPosition = StructureOfResponsible.ResponsiblePosition;
	EndIf;
	
	If Object.Goods.Count() > 0 Then
		
		ArrayOfRowsToDelete_1 = New Array();
		
		If WarehouseGroup_ Then
			
			WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True);
			
			For Each CurRow In Object.Goods Do
				
				If ValueIsFilled(CurRow.RowCode)
					And ValueIsFilled(CurRow.PurchaseOrder)
					And Not ValueIsFilled(CurRow.Warehouse) Then
					
					ArrayOfRowsToDelete_1.Add(CurRow);
					
				EndIf;
			
			EndDo;
			
		Else
		
			ArrayOfRowsToDelete_1 = New Array();
			
			For Each CurRow In Object.Goods Do
				
				If ValueIsFilled(CurRow.RowCode)
					And ValueIsFilled(CurRow.PurchaseOrder)
					And Object.Warehouse <> CurRow.Warehouse Then
					ArrayOfRowsToDelete_1.Add(CurRow);
				EndIf;
				
			EndDo;
			
		EndIf;
		
		For Each CurItem In ArrayOfRowsToDelete_1 Do
			Object.Goods.Delete(CurItem);
		EndDo;
		
	EndIf;
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True);
	FillInShopPantryAttributeInTable(True);
	UpdateOrderInformation();
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	WhenChangingWarehouseInTablePartServer();
	
	RecalculateNumberOfRNPT();
	
	PrepareFillSetSeriesVisibility();
	
	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
	SetTitleFillInByOrdersOrders();
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptForStorage,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingReceiptsForMultipleOrders()
	
	VisibilityOfElements = UnlinkVisibilityFromOrder();
	
	Items.GoodsUnlinkFromOrder.Visible                = VisibilityOfElements;
	Items.GoodsContextMenuUnlinkFromOrder.Visible = VisibilityOfElements;
	Items.GoodsPictureIndex.Visible                  = VisibilityOfElements;
	
	If Object.ReceiptUnderOrders Then
		
		If Not UseReceiptForMultipleOrders 
			And ValueIsFilled(Object.PurchaseOrder) Then
			If TypeOf(Object.PurchaseOrder) = Type("DocumentRef.MaterialProviderOrder2_5") Then
				TermsFromOrder = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
			Else
				TermsFromOrder = Common.ObjectAttributeValue(Object.PurchaseOrder, "Terms");
			EndIf;
			If TermsFromOrder <> Object.Terms 
				And ValueIsFilled(TermsFromOrder) Then
				
				Object.Terms = TermsFromOrder;
				WhenChangingAgreementAtServer();
				
			EndIf;
			
			FillPropertyValues(Object,
				Object.PurchaseOrder,
				"Currency, Counterparty, Contract, Organization, Partner, BusinessOperation");
			If TypeOf(Object.PurchaseOrder) = Type("DocumentRef.MaterialProviderOrder2_5") Then
				Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
			EndIf;
		EndIf;
		
		FillInFromOrderServer();
		
	Else
		
		If ValueIsFilled(Object.PurchaseOrder) Then
			Object.PurchaseOrder = Undefined;
			AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
		EndIf;
		
		UntieLinesFromOrdersToSuppliers();
		OrderList.Clear();
		ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
		
	EndIf;
	
	SetVisibilityOfElementsByOperationServer();
	SetStockTypeSelectionParameters();
	SetVisibilityOfItemsByOrder();
	SetLBEditingOption();
	FillInPricesOfOrderProductRange();
	UpdateOrderInformation();
	GoodsDelivery.WhenChangingFlagForOrders(Items, Object, Object.ReceiptUnderOrders);
	
	RowsArray = AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	If RowsArray.Count() > 0 Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	UpdateDestinationPresentation();
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

&AtServer
Function DateOnChangeServer(RecalculatePrices_2)
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	Else
		PricesCalculated = False;
	EndIf;
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	PrepareFillSetSeriesVisibility();
	SetTitleFillInByOrdersOrders();
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptForStorage,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure DateOfReceiptOnChangeServer()
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptForStorage,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
	UpdateDestinationPresentation();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure RecalculateAmountsWhenChangingCurrency(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		RecalculateAmountsWhenChangingCurrencyServer(CachedValues);
	Else
		OnChangeCurrencyOnServer();
	EndIf;
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure RecalculateAmountsWhenChangingCurrencyServer(CachedValues)
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, DocumentDate, BaseCurrency);
	StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.Currency,  DocumentDate, BaseCurrency);
	
	For Each CurRow In Object.Goods Do
		CurRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(
			CurRow.Price,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates);
	EndDo;
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	For Each CurRow In Object.Goods Do
		UpdateOrderDeviationsInLine(CurRow, Object.ReceiptUnderOrders);
	EndDo;
	
	If Object.ReceiptUnderOrders Then
		UpdateLabelForDeviationsFromOrderPrices();
	EndIf;
	
	OnChangeCurrencyOnServer();
	
EndProcedure
&AtServer
Procedure WhenBusinessTransactionChangesServer()
	
	If Object.Goods.Count() > 0 Then
		Object.Goods.Clear();
	EndIf;
	
	Object.ReceiptUnderOrders = Object.ReceiptUnderOrders And OrdersUse(ThisObject);
	
	If Object.ReceiptUnderOrders Then
		Object.ReceiptUnderOrders = False;
		WhenChangingReceiptsForMultipleOrders();
	EndIf;
	
	SetAvailabilityAgreements();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		
		ParametersForRecalculatingNumberOfUnits = ProductionClientServer.ParametersForRecalculatingNumberOfUnits();
		
		If ValueIsFilled(Object.Terms) Then
			Object.Terms = Undefined;
		EndIf;
		
	Else
		
		ParametersForRecalculatingNumberOfUnits = Undefined;
		
	EndIf;
	
	AdjustItemSelectionSettings();
	
	CustomizeForm();
	UpdateOrderInformation();
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptForStorage,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure
&AtClient
Procedure OpenBaseSelectionForm(SelectionOfSeveralBases, CurrentData = Undefined);
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.GoodsReceiptForStorage.Form.DocumentForm.GoodsPurchaseOrderStartChoice");
		If Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5") Then
			BusinessOperation = New Array;
			BusinessOperation.Add(TollingSchemeClientServer.ContractBusinessTransaction());
			BusinessOperation.Add(PredefinedValue("Enum.BusinessTransactions.Subcontracting2_5"));
			BusinessOperation.Add(PredefinedValue("Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5"));
			BusinessOperation.Add(PredefinedValue("Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5"));
			BusinessOperation.Add(PredefinedValue("Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5"));
		Else
			BusinessOperation = Object.BusinessOperation;
		EndIf;
	FilterParameters = New Structure();
	FilterParameters.Insert("Currency",                    Object.Currency);
	FilterParameters.Insert("Counterparty",                Object.Counterparty);
	FilterParameters.Insert("Contract",                   Object.Contract);
	FilterParameters.Insert("Organization",               Object.Organization);
	FilterParameters.Insert("Partner",                   Object.Partner);
	FilterParameters.Insert("Terms",                Object.Terms);
	FilterParameters.Insert("Department",             Object.Department);
	FilterParameters.Insert("BusinessOperation",     BusinessOperation);
	FilterParameters.Insert("PriceIncludesVAT",           Undefined);
	FilterParameters.Insert("LineOfBusiness",   Object.LineOfBusiness);
	FilterParameters.Insert("ToReturnReusablePackage", False);
	FilterParameters.Insert("PackageDepositIsRequired",      False);
	FilterParameters.Insert("GoodsReceiptOption",     Object.GoodsReceiptOption);
	FilterParameters.Insert("DocumentBusinessTransaction", Object.BusinessOperation);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter",             FilterParameters);
	FormParameters.Insert("Warehouse",             Object.Warehouse);
	FormParameters.Insert("Recorder",       Object.Ref);
	FormParameters.Insert("HideAdditionalSelections", True);
	FormParameters.Insert("MultipleChoice", SelectionOfSeveralBases And UseReceiptForMultipleOrders);
	
	If OrderList.Count() = 0 Then
		AnArrayOfOrders = New Array();
		If ValueIsFilled(Object.PurchaseOrder) Then
			AnArrayOfOrders.Add(Object.PurchaseOrder);
		EndIf;
		FormParameters.Insert("BasisDocuments", AnArrayOfOrders);
	Else
		FormParameters.Insert("BasisDocuments", OrderList);
	EndIf;
	
	If Object.BusinessOperation = 
			PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5") Then
		FormParameters.Insert("Title", NStr("vi = 'Đơn hàng bên đặt gia công';
											|ru = 'Заказы давальцев';
											|en = 'Subcontracting sales orders'; fa = 'سفارش‌های فروش پیمانکاری فرعی';
											|it = 'Ordini dei prestatori';
											|pl = 'Zamówienia właścicieli surowców';
											|tr = 'Sağlayıcı siparişleri'"));
	EndIf;
	
	If SelectionOfSeveralBases Then
		ClosingNotification_ = New CallbackDescription("ReceiptForOrdersWhenChangedAfterSelection", ThisObject);
	Else
		NotificationParameters =  New Structure("CurrentData", CurrentData);
		ClosingNotification_  = New CallbackDescription("GoodsPurchaseOrderStartChoiceCompletion", ThisObject,
			NotificationParameters);
	EndIf;
	
	OpenForm("DataProcessor.LogOfPurchaseDocuments.Form.ReferenceChoiceForm", FormParameters, , , , ,
		ClosingNotification_, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region PriceManagementSystem

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
	
	ActionsWithStrings = New Structure;
	ActionsWithStrings.Insert("RecalculateAmount", "NumberOfPackages");
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, ActionsWithStrings);
	
	If Object.ReceiptUnderOrders Then
		UpdateOrderDeviations();
	EndIf;
	
	Return PricesCalculated;
	
EndFunction

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
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields",    "Price");
	FillParameters.Insert("Date",              Object.Date);
	FillParameters.Insert("Currency",            Object.Currency);
	FillParameters.Insert("VendorPriceKind", Object.VendorPriceKind);
	FillParameters.Insert("Organization", Object.Organization);
	
	ActionsWithStrings = New Structure;
	ActionsWithStrings.Insert("RecalculateAmount", "NumberOfPackages");
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, ActionsWithStrings);
	
	If Object.ReceiptUnderOrders Then
		UpdateOrderDeviations();
	EndIf;
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure FillInPricesOfOrderProductRange()
	
	If Not Object.ReceiptUnderOrders Then
		For Each CurRow In Object.Goods Do
			CurRow.OrderPrice = 0;
			UpdateOrderDeviationsInLine(CurRow, Object.ReceiptUnderOrders);
		EndDo;
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	Goods.PurchaseOrder AS PurchaseOrder,
	|	Goods.RowCode       AS RowCode,
	|	Goods.Price            AS Price,
	|	Goods.Package        AS Package,
	|	Goods.Products    AS Products
	|INTO
	|	Goods
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.RowCode <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsTable.Ref    AS Ref,
	|	DocumentsTable.Date      AS Date,
	|	DocumentsTable.Currency    AS Currency,
	|	TabularSection.RowCode    AS RowCode,
	|	TabularSection.Products AS Products,
	|	TabularSection.Package     AS Package,
	|	TabularSection.Price         AS Price
	|INTO GoodsFromOrder
	|FROM
	|	Document.PurchaseOrder AS DocumentsTable
	|		LEFT JOIN Document.PurchaseOrder.Goods AS TabularSection
	|		ON DocumentsTable.Ref = TabularSection.Ref
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|		   Goods AS Goods
	|		WHERE
	|		   Goods.PurchaseOrder = DocumentsTable.Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref    AS Ref,
	|	DocumentsTable.Date      AS Date,
	|	DocumentsTable.Currency    AS Currency,
	|	TabularSection.RowCode    AS RowCode,
	|	TabularSection.Products AS Products,
	|	TabularSection.Package     AS Package,
	|	TabularSection.Price         AS Price
	|FROM
	|	Document.MaterialProviderOrder2_5 AS DocumentsTable
	|		LEFT JOIN Document.MaterialProviderOrder2_5.UsedMaterials AS TabularSection
	|		ON DocumentsTable.Ref = TabularSection.Ref
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|		   Goods AS Goods
	|		WHERE
	|		   Goods.PurchaseOrder = DocumentsTable.Ref)
	|
	|INDEX BY
	|	Ref,
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromOrder.Ref    AS PurchaseOrder,
	|	GoodsFromOrder.Date AS OrderDate,
	|	GoodsFromOrder.RowCode AS RowCode,
	|	(GoodsFromOrder.Price/ISNULL(&QueryTextPackagingFactor1,1))*ISNULL(&QueryTextPackagingFactor2, 1)      AS OrderPrice,
	|	GoodsFromOrder.Package AS OrderPackage,
	|	GoodsFromOrder.Currency AS OrderCurrency
	|FROM
	|	Goods AS Goods
	|LEFT JOIN
	|	GoodsFromOrder AS GoodsFromOrder
	|ON
	|	Goods.PurchaseOrder = GoodsFromOrder.Ref
	|	AND Goods.RowCode = GoodsFromOrder.RowCode
	|");
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"GoodsFromOrder.Package",
			"Goods.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	Query.SetParameter("Goods", Object.Goods.Unload(,"Products, PurchaseOrder,RowCode,Price,Package"));

	QueryResultsArray = Query.ExecuteBatch();
	QueryResult = QueryResultsArray[2]; // QueryResult
	Selection = QueryResult.Select();
	
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	For Each CurRow In Object.Goods Do
		If ValueIsFilled(CurRow.RowCode) Then
			Selection.Reset();
			FilterStructure1 = New Structure("PurchaseOrder,RowCode", CurRow.PurchaseOrder, CurRow.RowCode);
			
			If Selection.FindNext(FilterStructure1) Then
				CurRow.OrderPrice = ProcessingOfExchangeRatesTM.ConvertToCurrency(Selection.OrderPrice,
						BaseCurrency,
						Selection.OrderCurrency,
						Object.Currency,
						Selection.OrderDate);
			EndIf;
	
		Else
			CurRow.OrderPrice = 0;
		EndIf;
		UpdateOrderDeviationsInLine(CurRow, Object.ReceiptUnderOrders);
	EndDo;
	
	UpdateOrderInformation();
	
EndProcedure

&AtServer
Procedure FillInPricesForLatestReceipts(PricesAreFilledOut)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SourceTable.LineNumber    AS LineNumber,
	|	SourceTable.Products   AS Products,
	|	SourceTable.Characteristic AS Characteristic,
	|	SourceTable.Package       AS Package
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
	|SELECT DISTINCT
	|	GoodsReceiptForStorage.Ref.PointInTime AS PointInTime,
	|	GoodsReceiptForStorage.Ref.Currency        AS Currency,
	|	GoodsReceiptForStorage.Products         AS Products,
	|	GoodsReceiptForStorage.Characteristic       AS Characteristic,
	|	GoodsReceiptForStorage.Package             AS Package,
	|	GoodsReceiptForStorage.Price                 AS Price
	|INTO RevenuePrices
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS GoodsReceiptForStorage
	|		INNER JOIN GoodsTable AS GoodsTable
	|		ON GoodsReceiptForStorage.Products = GoodsTable.Products
	|			AND GoodsReceiptForStorage.Characteristic = GoodsTable.Characteristic
	|WHERE
	|	GoodsReceiptForStorage.Ref.Posted
	|	AND GoodsReceiptForStorage.Ref.Partner = &Partner
	|	AND GoodsReceiptForStorage.Ref.Date <= &Date
	|	AND GoodsReceiptForStorage.Ref.BusinessOperation = &BusinessOperation
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RevenuePrices.Products         AS Products,
	|	RevenuePrices.Characteristic       AS Characteristic,
	|	RevenuePrices.Package             AS Package,
	|	RevenuePrices.Price                 AS Price,
	|	RevenuePrices.Currency               AS Currency
	|INTO PricesOfRecentReceipts
	|FROM
	|	RevenuePrices AS RevenuePrices
	|		LEFT JOIN RevenuePrices AS Filter
	|		ON RevenuePrices.Products = Filter.Products
	|			AND RevenuePrices.Characteristic = Filter.Characteristic
	|			AND RevenuePrices.PointInTime < Filter.PointInTime
	|WHERE
	|	Filter.PointInTime IS NULL
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsTable.LineNumber    AS LineNumber,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Package       AS Package,
	|	CASE
	|		WHEN GoodsTable.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN &QueryTextPackagingFactor1
	|		ELSE 1
	|	END
	|	* PricesOfRecentReceipts.Price / ISNULL(&QueryTextPackagingFactor2, 1)
	|	* CASE
	|		WHEN &Currency <> PricesOfRecentReceipts.Currency
	|			THEN CASE
	|					WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|							AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|							AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|							AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|						THEN (CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator) / (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END                        AS Price
	|FROM
	|	GoodsTable AS GoodsTable
	|		LEFT JOIN PricesOfRecentReceipts AS PricesOfRecentReceipts
	|		ON GoodsTable.Products = PricesOfRecentReceipts.Products
	|			AND GoodsTable.Characteristic = PricesOfRecentReceipts.Characteristic
	|	
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|		ON PricesOfRecentReceipts.Currency = CurrencyRatesPrices.Currency
	|	
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|		ON TRUE";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"GoodsTable.Package",
			"GoodsTable.Products"));
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PricesOfRecentReceipts.Package",
			"PricesOfRecentReceipts.Products"));
	
	Query.SetParameter("Date", 			 ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	Query.SetParameter("Currency", 		 Object.Currency);
	Query.SetParameter("Partner", 		 Object.Partner);
	Query.SetParameter("SourceTable", Object.Goods.Unload(,"LineNumber, Products, Characteristic, Package"));
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
	Query.SetParameter("BusinessOperation", Object.BusinessOperation);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateAmount");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		PricesAreFilledOut = True;
		
		TSRow = Object.Goods[Selection.LineNumber - 1];
		FillPropertyValues(TSRow, Selection, "Price");
		RowsToProcess.Add(TSRow);
		
	EndDo;
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			CachedValues);
	
	If Object.ReceiptUnderOrders Then
		UpdateOrderDeviations();
	EndIf;
	
EndProcedure

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

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure AddItemsFromSalesOrderGoodsIssue()
	
	Try
		Modified = True;
		
		LockFormDataForEdit();
	Except
		ShowMessageBox(,ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	AddressOfGoods     = "";
	PickingFormName  = "DataProcessor.LogOfPurchaseDocuments.Form.SelectionOfGoodsFromOrderForm";
	ArrayOfStringCodes = New Array;
	
	BeforeSelectingProductsFromOrder(ArrayOfStringCodes, AddressOfGoods);
	
	PickingParameters = New Structure(
		"PurchaseOrder,
		|Ref,
		|Date,
		|Partner,
		|Counterparty,
		|Terms,
		|Organization,
		|Warehouse,
		|Contract,
		|BusinessOperation,
		|DocumentCurrency,
		|LineOfBusiness,
		|ReceiptUnderOrders,
		|AdvancedWarehousingOnReceiving,
		|AddressGoodsReceiptGoodsInTheTemporaryStorage,
		|GoodsReceiptOption,
		|ArrayOfStringCodes");
	
	FillPropertyValues(PickingParameters, Object);
	
	PickingParameters.DocumentCurrency = Object.Currency;
	PickingParameters.ArrayOfStringCodes = ArrayOfStringCodes;
	PickingParameters.AdvancedWarehousingOnReceiving = AdvancedWarehousingOnReceiving;
	PickingParameters.AddressGoodsReceiptGoodsInTheTemporaryStorage = AddressOfGoods;
	
	OpenForm(PickingFormName, PickingParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure BeforeSelectingProductsFromOrder(ArrayOfStringCodes, AddressOfGoods)
	
	For Each TSRow In Object.Goods Do
		
		If TSRow.RowCode <> 0 And ValueIsFilled(TSRow.PurchaseOrder) Then
			ArrayOfStringCodes.Add(New Structure("RowCode,PurchaseOrder", TSRow.RowCode, TSRow.PurchaseOrder));
		EndIf;
		
	EndDo;
	
	AddressOfGoods = PutToTempStorage(Object.Goods.Unload());
	
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
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject, SeriesSpecificationParameters, Text, CurrentData)Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
					ParametersOfSeriesIndicationForm,
					ThisObject,
					,
					,
					,
					New CallbackDescription("OpenSelectionOfSeriesCompletion",
											ThisObject,
											New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)),
					FormWindowOpeningMode.LockOwnerWindow);
		
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
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActionsWithAddedStrings.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, ThisObject);
	StructureOfActionsWithAddedStrings.Insert("FillInShopPantryAttribute");
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, ThisObject);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.AddOnlyProductsOverAndAboveOrder        = True;
	StructureOfActions.GoodsOnly                           = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	
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
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	StructureOfActions.Insert("FillInShopPantryAttribute");
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
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsReceiptForStorage));
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
	
	ProcessingActions = New Structure;
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions, ThisObject);
	Else
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			ProcessingActions,
			"Warehouse",
			True);
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												Undefined,
												ProcessingActions);
	
	UpdateDependentDetailsOfOrderForm_(Items,
											Object.Goods,
											DiscrepancyOrderText);
	
EndProcedure

&AtServer
Procedure FillInCCDNumbersOnServer(Val CCDNumber, CCDNumbersFilledIn)
	
	PurchasesServer.FillInGTNumbersInTabularPart(
		Object.Goods,
		CCDNumber,
		Items.Goods.SelectedRows,
		CCDNumbersFilledIn);
	
EndProcedure

&AtClient
Procedure FillIn_CCDNumbersForLatestReceipts()
	
	CCDNumbersFilledIn = False;
	FillIn_CCDNumbersForLatestReceiptsServer(CCDNumbersFilledIn);
	
	PurchasesClient.NotifyAboutFillingInGTNumbersInTabularPart(CCDNumbersFilledIn);
	
EndProcedure

&AtServer
Procedure FillIn_CCDNumbersForLatestReceiptsServer(CCDNumbersFilledIn)
	
	PurchasesServer.FillIn_CCDNumbersForLatestReceipts(Object.Goods, CCDNumbersFilledIn);
	
EndProcedure

#EndRegion

#Region Assignments

&AtClient
Procedure AfterSpecifyingOrderInLine(TableRow)
	
	AssignmentsClient.AfterSpecifyingOrderInLine(ThisObject, TableRow);
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5")
		And ValueIsFilled(TableRow.PurchaseOrder)
		And Not TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
		
		TableRow.Purpose = GeneralPurposeTMServerCall.ObjectAttributeValue(
			TableRow.PurchaseOrder,
			"AssignmentMaterials");
		
	EndIf;
EndProcedure

&AtServer
Procedure UpdateDestinationPresentation()
	
	DestinationPattern = Documents.GoodsReceiptForStorage.DestinationPattern(Object);
	
	DocumentAttributes = New Structure("Number, Date, Recipient", Object.Number, Object.Date, Object.Partner);
	PurposePresentation = Catalogs.Assignments.PresentationOfDestinationByTemplate(
		DestinationPattern,
		DocumentAttributes);
	
EndProcedure
#EndRegion

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = Items.Date.Name Then
		DateOnChange(Item);
	ElsIf Item.Name = Items.BusinessOperation.Name Then
		BusinessOperationOnChange(Item);
	ElsIf Item.Name = Items.Partner.Name Then
		PartnerOnChange(Item);
	ElsIf Item.Name = Items.Terms.Name Then
		TermsOnChange(Item);
	ElsIf Item.Name = Items.Contract.Name Then
		ContractOnChange(Item);
	ElsIf Item.Name = Items.Organization.Name Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = Items.Counterparty.Name Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = Items.ReceiptAgainstOrder.Name Then
		ReceiptUnderOrdersOnChange(Item);
	ElsIf Item.Name = Items.ReceiptUnderOrders.Name Then
		ReceiptUnderOrdersOnChange(Item);
	ElsIf Item.Name = Items.Warehouse.Name Then
		WarehouseOnChange(Item);
	ElsIf Item.Name = Items.Currency.Name Then
		CurrencyOnChange(Item);
	ElsIf Item.Name = Items.GoodsPartnerProducts.Name Then
		GoodsPartnerProductsOnChange(Item);
	ElsIf Item.Name = Items.GoodsProducts.Name Then
		GoodsProductsOnChange(Item);
	ElsIf Item.Name = Items.GoodsCharacteristic.Name Then
		GoodsCharacteristicOnChange(Item);
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
	ElsIf Item.Name = Items.GoodsWarehouse.Name Then
		GoodsWarehouseOnChange(Item);
	ElsIf Item.Name = Items.GoodsPurchaseOrder.Name Then
		GoodsPurchaseOrderOnChange(Item);
	ElsIf Item.Name = Items.GoodsCCDNumber.Name Then
		GoodsCCDNumberOnChange(Item);
	ElsIf Item.Name = Items.GoodsToControlQuality.Name Then
		GoodsToControlQualityOnChange(Item);
	ElsIf Item.Name = Items.GoodsQualityConfirmationDate.Name Then
		GoodsQualityConfirmationDateOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = Commands.UnlinkFromOrder.Name Then
		UnlinkFromOrder(Command);
	ElsIf Command.Name = Commands.SearchByBarcode.Name Then
		SearchByBarcodeExecute(Command);
	ElsIf Command.Name = Commands.GetWeight.Name Then
		GetWeight(Command);
	ElsIf Command.Name = Commands.ImportDataFromPDT.Name Then
		ImportDataFromPDT(Command);
	ElsIf Command.Name = Commands.CheckQuantityInTheDocument.Name Then
		CheckQuantityInTheDocument(Command);
	ElsIf Command.Name = Commands.FillThePricesByTermsOfSales.Name Then
		FillThePricesByTermsOfSales(Command);
	ElsIf Command.Name = Commands.FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice.Name Then
		FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice(Command);
	ElsIf Command.Name = Commands.FillInCCDNumbers.Name Then
		FillInCCDNumbers(Command);
	ElsIf Command.Name = Commands.FillInTheGTDNumbersForReceipts.Name Then
		FillInTheGTDNumbersForReceipts(Command);
	ElsIf Command.Name = Commands.GoodsSelectGoodsByOrdersNotes.Name Then
		SelectGoodsByOrdersNotes(Command);
	ElsIf Command.Name = Commands.ChangeQuality.Name Then
		ChangeTheQualityOfTheItem(Command);
	ElsIf Command.Name = Commands.SplitTheFactString.Name Then
		SplitTheFactString(Command);
	ElsIf Command.Name = Commands.SelectGoods.Name Then
		SelectGoods(Command);
	ElsIf Command.Name = Commands.FillInTheItemByThePartnerSItem.Name Then
		FillInTheItemByThePartnerSItem(Command);
	ElsIf Command.Name = Commands.AddReusablePackage.Name Then
		AddReusablePackage(Command);
	ElsIf Command.Name = Commands.FillInTheWarehouseInSelectedLines.Name Then
		FillInTheWarehouseInSelectedLines(Command);
	ElsIf Command.Name = Commands.FillInThePricesForReceipts.Name Then
		FillInThePricesForReceipts(Command);
	ElsIf Command.Name = Commands.InsertRows.Name Then
		InsertRows(Command);
	ElsIf Command.Name = Commands.ImportFromExternalFile.Name Then
		ImportFromExternalFile(Command);
	ElsIf Command.Name = Commands.ChangeBaseDocuments.Name Then
		ChangeBaseDocuments(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Command);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	If Item.Name = Items.Goods.Name Then
		GoodsBeforeRowChange(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	If Item.Name = Items.Goods.Name Then
		GoodsBeforeDeleteRow(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	TMCommonUseClient.SaveAttributeValue(ThisObject, Item);
	
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

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Price,CCDNumber,Warehouse";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	StructureOfActions.Insert("FillInShopPantryAttribute");
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		If Object.ReceiptUnderOrders Then
			CurrentRow.OrderDiscrepancy_3 = 1;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	WhenChangingWarehouseInTablePartServer();
	FillInStatusesForSpecifyingSeriesServer();
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
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

&AtServer
Procedure FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts)
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
											New Structure("Products", "TheRecordsAreKeptByCCD"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	
	If StructureOfNamesOfTableParts.Property("Goods") Then
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	EndIf;	
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseReceiptForMultipleOrders = GetFunctionalOption("UseReceiptForMultipleOrders");
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UsePurchaseOrders = GetFunctionalOption("UsePurchaseOrders");
	UseMaterialProviderOrder2_5 = GetFunctionalOption("UseMaterialProviderOrder2_5");
	UseTermsOfPurchases = GetFunctionalOption("UseTermsOfPurchases");
	UseDebitNotes = GetFunctionalOption("UseDebitNotes");
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	BusinessOperationSelectionList = Items.BusinessOperation.ChoiceList;
	BusinessOperationSelectionList.Clear();
	
	If GetFunctionalOption("UseCustodyDuringPurchase") Then
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
	EndIf;
	
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5);
		
		OptionOfMaterialAssignmentUponSubcontractingServicesDelivered =
			Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Get();
		
	EndIf;
	
	Items.BusinessOperation.Visible = BusinessOperationSelectionList.Count() > 1;
	
	If Not ValueIsFilled(Object.BusinessOperation)
	   And Items.BusinessOperation.ChoiceList.Count() = 1 Then
		Object.BusinessOperation = BusinessOperationSelectionList[0].Value;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		UseTermsOfPurchases = False;
	EndIf;
	
	ParametersForRecalculatingNumberOfUnits = Undefined;
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		ParametersForRecalculatingNumberOfUnits = ProductionClientServer.ParametersForRecalculatingNumberOfUnits();
	EndIf;
	
	RecalculateNumberOfUnits =
		Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
		And Not ValueIsFilled(Object.Ref);
		
	FillInShopPantryAttributeInTable(RecalculateNumberOfUnits);
	
	AdjustItemSelectionSettings();
	
	CustomizeForm();
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	SetAvailabilityAgreements();
	
	DocumentCurrency = Object.Currency;
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	Warehouse = Object.Warehouse;
	Contract = Object.Contract;
	
	SetParametersForSelectingProductsWarehouse();
	
	WhenChangingWarehouseInTablePartServer();
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsReceiptForStorage));
	SetVisibilityOfSeriesElements();
	
	SetVisibilityOfElementsByOperationServer();
	SetStockTypeSelectionParameters();
	SetAvailabilityOfItemsByStatusServer();
	FillInPricesOfOrderProductRange();
	UpdateOrderInformation();
	SetVisibilityOfItemsByOrder();
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(
		Items,
		Object.Goods,
		DiscrepancyOrderText);

	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	DocumentDateBeforeChange = Object.Date;
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	BackgroundTaskData = GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object,
		Object.ReceiptUnderOrders,,SummaryDeliveryInformation,True);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	AssignmentsServer.OnReadCreateAtServer(ThisObject);
	
	PrepareFillSetSeriesVisibility();
	
	FillInPassedFieldSelectionList();
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

&AtServerNoContext
Function GetDealOnOrderToSupplier(PurchaseOrder)
	
	Return Common.ObjectAttributeValue(PurchaseOrder, "SalesOpportunity");
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateOrderDeviationsInLine(CurrentRow, ReceiptUnderOrders)
	
	If CurrentRow.Price < CurrentRow.OrderPrice
		And CurrentRow.OrderPrice <> 0
		And CurrentRow.RowCode <> 0 Then
		
		CurrentRow.PictureIndex = 3;
		CurrentRow.PriceChanged = True;
		
		If CurrentRow.Price <> 0 Then
			CurrentRow.PercentageOfDeviationFromTheOrderPrice = 100 - (CurrentRow.OrderPrice * 100 / CurrentRow.Price);
		Else
			CurrentRow.PercentageOfDeviationFromTheOrderPrice = 100;
		EndIf;
		
	ElsIf CurrentRow.Price > CurrentRow.OrderPrice
		And CurrentRow.OrderPrice <> 0
		And CurrentRow.RowCode <> 0 Then
		
		CurrentRow.PictureIndex = 1;
		CurrentRow.PriceChanged = True;
		
		If CurrentRow.Price <> 0 Then
			CurrentRow.PercentageOfDeviationFromTheOrderPrice = 100 - (CurrentRow.OrderPrice * 100 / CurrentRow.Price);
		Else
			CurrentRow.PercentageOfDeviationFromTheOrderPrice = 100;
		EndIf;
		
	Else
		
		CurrentRow.PictureIndex = 8;
		CurrentRow.PriceChanged = False;
		CurrentRow.PercentageOfDeviationFromTheOrderPrice = 0;
		
	EndIf;
	
	If ReceiptUnderOrders Then
		If CurrentRow.RowCode = 0 Then
			CurrentRow.OrderDiscrepancy_3 = 1;
		Else
			CurrentRow.OrderDiscrepancy_3 = 0;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOrderDeviations()
	
	For Each CurRow In Object.Goods Do
		UpdateOrderDeviationsInLine(CurRow, Object.ReceiptUnderOrders);
	EndDo;
	
EndProcedure

&AtServer
Function PlaceGoodsInTemporaryStorageServer(CollectionName)
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(Object[CollectionName]);
	
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	TableOfGoods = GetFromTempStorage(AddressInTempStorage); // DocumentTabularSection.GoodsReceiptForStorage.Goods
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	StructureOfActions.Insert("FillInShopPantryAttribute");
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
	EndIf;
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
		Object.Goods);
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	WhenChangingWarehouseInTablePartServer();
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtServer
Procedure UpdateOrderInformation()
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.PurchaseOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = Items.GoodsGroupPurchaseOrder.Name;
	ParametersOfUpdate.OrderNameInTablePart          = "PurchaseOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseReceiptForMultipleOrders;
	ParametersOfUpdate.OrdersUse                = OrdersUse(ThisObject);
	
	Items.ChangeBaseDocuments.Enabled = ParametersOfUpdate.OrdersUse;
	
	OrdersServer.UpdateOrderInformationInForm(ThisObject, Object.Goods, ParametersOfUpdate);
	
	UpdateLabelForDeviationsFromOrderPrices();
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "SalesOpportunity", "Visible",
		(Object.ReceiptUnderOrders And ValueIsFilled(Object.PurchaseOrder)) Or Not Object.ReceiptUnderOrders);
	TMCommonUseClientServer.SetFormItemProperty(Items, "SalesOpportunity", "Enabled", Not Object.ReceiptUnderOrders);
	
	If ValueIsFilled(Object.PurchaseOrder) Then
		Object.SalesOpportunity = GetDealOnOrderToSupplier(Object.PurchaseOrder);
	ElsIf Object.ReceiptUnderOrders Then
		Object.SalesOpportunity = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateLabelForDeviationsFromOrderPrices()
	
	If Object.ReceiptUnderOrders And
		Object.Goods.FindRows(New Structure("PriceChanged", True)).Count() > 0 Then
		
		If ValueIsFilled(Object.PurchaseOrder) Then
			PriceVarianceText = NStr("vi = 'Đơn giá khác với đơn giá trong đơn hàng';
									|ru = 'Цены отличаются от заказа';
									|en = 'Prices differ from the order'; fa = 'قیمت‌ها با سفارش متفاوت هستند';
									|it = 'I prezzi si differenziano dall''ordine';
									|pl = 'Ceny różnią się od zamówienia';
									|tr = 'Fiyatlar siparişten siparişe değişmektedir'");
		Else
			PriceVarianceText = NStr("vi = 'Đơn giá khác với đơn giá trong đơn hàng';
									|ru = 'Цены отличаются от заказов';
									|en = 'Prices differ from the orders'; fa = 'Prices differ from the orders';
									|it = 'I prezzi si differenziano dagli ordini';
									|pl = 'Ceny różnią się od zamówień';
									|tr = 'Fiyatlar siparişten siparişe değişmektedir'");
		EndIf;
		
		Items.PicturePriceDeviationOrders.Picture = PictureLib.Warning;
		Items.PicturePriceDeviationOrder.Picture = PictureLib.Warning;
		ToolTipText = NStr("vi = 'Để đặt bộ lọc theo các dòng có chênh lệch đơn giá 
		|hãy thực hiện lệnh ""Hiển thị chênh lệch đơn giá"" trong nhóm lệnh ""Đơn giá""';
		|ru = 'Для установки фильтра по строкам с отклонением цены 
		|воспользуйтесь командой ""Показать отклонения цен"" в группе команд ""Цены""';
		|en = 'To set the filter by the lines with price variance, 
		|use command ""Show price variances"" in command group ""Prices""'; fa = 'To set the filter by the lines with price variance, 
		|use command ""Show price variances"" in command group ""Prices""';
		|it = 'Per impostare il filtro per le righe con la deviazione di prezzo 
		|utilizzare il comando ""Visualizzare le deviazioni di prezzo"" nel gruppo comandi ""Prezzi""';
		|pl = 'Aby ustawić filtr dla wierszy z odchyleniem ceny 
		|użyj polecenia ""Pokaż odchylenia cen"" w grupie poleceń ""Ceny""';
		|tr = 'Fiyat sapmaları olan satırlar için bir filtre ayarlamak üzere
		| ""Fiyatlar"" komut grubundaki ""Fiyat sapmalarını göster"" komutunu kullanın'");
	Else
		PriceVarianceText = "";
		AnEmptyPicture =  New Picture();
		Items.PicturePriceDeviationOrders.Picture = AnEmptyPicture;
		Items.PicturePriceDeviationOrder.Picture = AnEmptyPicture;
		ToolTipText = "";
	EndIf;
	
	Items.LabelPriceDeviationOrder.ToolTip   = ToolTipText;
	Items.LabelPriceDeviationOrders.ToolTip  = ToolTipText;
	Items.PicturePriceDeviationOrders.ToolTip = ToolTipText;
	Items.PicturePriceDeviationOrder.ToolTip  = ToolTipText;
	
EndProcedure

&AtServer
Procedure ProcessOrderClosingNotification()
	
	FillInPricesOfOrderProductRange();
	UpdateLabelForDeviationsFromOrderPrices();
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Object.Currency;
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		Contract = PurchasesServer.GetDefaultContract(
					Object, TollingSchemeClientServer.ContractBusinessTransaction(), AddlParameters);
	Else
		Contract = PurchasesServer.GetDefaultContract(
					Object, Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale, AddlParameters);
	EndIf;
	If Contract <> Object.Contract Then
		
		Object.Contract = Contract;
		FillInAttributesFromContract();
		PurchasesServerCall.FillInBankAccountsUnderAgreement(
			Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
			
		FillInCurrencyAccordingToContract();
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptForStorage,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAttributesFromContract()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
		And ValueIsFilled(Object.Contract) Then
		
		ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "ARAPCurrency, Department");
		Object.Department = ContractDetails_.Department;
		
		If Not ValueIsFilled(Object.Currency) Then
			Object.Currency   = ContractDetails_.ARAPCurrency;
			DocumentCurrency = Object.Currency;
		EndIf;
		
	EndIf;
	
EndProcedure
&AtServer
Procedure FillInFromOrderServer()
	
	Object.Goods.Clear();
	
	If UseReceiptForMultipleOrders
		And OrderList.Count() > 0 Then
		AnArrayOfOrders = OrderList;
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(Object.PurchaseOrder);
	EndIf;
	
	Documents.GoodsReceiptForStorage.FillByOrderBalances(
		Object,
		Object.Goods,
		Warehouse,
		AnArrayOfOrders);
	
	FillInPricesOfOrderProductRange();
	UpdateOrderInformation();
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	FillInShopPantryAttributeInTable();
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	RecalculateNumberOfRNPT();
	WhenChangingWarehouseInTablePartServer();
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtServer
Procedure UntieLinesFromOrdersToSuppliers()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	For Each CurRow In Object.Goods Do
		
		CurRow.RowCode = 0;
		CurRow.PurchaseOrder = Undefined;
		CurRow.SalesOpportunity = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
		
	EndDo;

	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfItemsByOrder()
	
	Items.GoodsShowPriceVariances.Visible = Object.ReceiptUnderOrders;
	Items.GoodsAddReusablePackage.Visible = Not Object.ReceiptUnderOrders;
	Items.ChangeBaseDocuments.Visible         = Object.ReceiptUnderOrders;
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		Items.CloseOrder.Visible						  = False;
		Items.CloseOrders_2.Visible					  = False;
		Items.ChangeBaseDocuments.Visible		  = Object.ReceiptUnderOrders;
	Else
		Items.CloseOrder.Visible  = Object.ReceiptUnderOrders;
		Items.CloseOrders_2.Visible = Object.ReceiptUnderOrders;
	EndIf;
EndProcedure

&AtServer
Function QuestionOfCleaningWarehouseIsNecessary()
	
	AskAQuestion = False;
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	
	If Not WarehouseGroup_ Then
		
		For Each CurRow In Object.Goods Do
			
			If ValueIsFilled(CurRow.PurchaseOrder)
				And ValueIsFilled(CurRow.RowCode)
				And ValueIsFilled(CurRow.Warehouse)
				And CurRow.Warehouse <> Object.Warehouse Then
				
				AskAQuestion = True;
				Break;
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each CurRow In Object.Goods Do
			
			If ValueIsFilled(CurRow.PurchaseOrder)
				And ValueIsFilled(CurRow.RowCode)
				And ValueIsFilled(CurRow.Warehouse) Then
				
				AskAQuestion = True;
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return AskAQuestion;
	
EndFunction

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts);
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsPartnerProducts);
	
EndProcedure

&AtServer
Procedure SetStockTypeSelectionParameters()
	
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization"));
	ParametersArray.Add(New ChoiceParameterLink("Filter.BusinessOperation", "Object.BusinessOperation"));
	ParametersArray.Add(New ChoiceParameterLink("Filter.Products", "Items.Goods.CurrentData.Products"));
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.Department", "Object.Department"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.Manager", "Object.Manager"));
	EndIf;
	If GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities") Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.SalesOpportunity", "Object.SalesOpportunity"));
	EndIf;
	If GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.Purpose", "Items.Goods.CurrentData.Purpose"));
		
		If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
			
			ParametersArray.Add(New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty"));
			ParametersArray.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization"));
			ParametersArray.Add(New ChoiceParameterLink("Filter.Partner", "Object.Partner"));
			ParametersArray.Add(New ChoiceParameterLink("Filter.Contract", "Object.Contract"));
			ParametersArray.Add(New ChoiceParameterLink("Filter.Terms", "Object.Terms"));
			ParametersArray.Add(New ChoiceParameterLink("Filter.LineOfBusiness", "Object.LineOfBusiness"));
			
		EndIf;
		
	EndIf;
	
	ParametersArray.Add(New ChoiceParameterLink("Filter.Consignor", "Object.Partner"));
	ParametersArray.Add(New ChoiceParameterLink("Filter.Terms", "Object.Terms"));
	// DEBUGGING
	//Array of parameters.Add(New link of the selection parameter("Selection.Currency", "Object.Currency"));
	
	Items.GoodsInventoryOwnerAttribute.ChoiceParameterLinks = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	StructureOfActions.Insert("FillInShopPantryAttribute");
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "PartnerProducts, Products, Characteristic, Package, Warehouse, Price, NumberOfPackages");
		
		If Object.ReceiptUnderOrders Then
			CurrentRow.OrderDiscrepancy_3 = 1;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
		
	WhenChangingWarehouseInTablePartServer();
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtServer
Procedure GetProductsFromStorage(GoodsAddressInStorage)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage); // DocumentTabularSection.GoodsReceiptForStorage.Goods
	
	SearchStructureForOrderItems = New Structure("RowCode,PurchaseOrder");
	StructureOfSearchForGoodsWaybill = New Structure("LineNumber");
	
	If SeriesSpecificationParameters.UseCostAccountingByBatches Then
		SearchStructureForOrderItems.Insert("Series");
		StructureOfSearchForGoodsWaybill.Insert("Series");
	EndIf;	
	
	DefaultAssignmentHasChanged = False;
	For Each RowOfGoods In ItemsFromStorage Do
		
		If RowOfGoods.RowCode<>0 And ValueIsFilled(RowOfGoods.PurchaseOrder) Then
			SearchStructureForOrderItems.RowCode = RowOfGoods.RowCode;
			SearchStructureForOrderItems.PurchaseOrder = RowOfGoods.PurchaseOrder;
			If SeriesSpecificationParameters.UseCostAccountingByBatches Then
				SearchStructureForOrderItems.Series = RowOfGoods.Series;
			EndIf;	
			ArrayOfTSRows = Object.Goods.FindRows(SearchStructureForOrderItems);
		Else
			StructureOfSearchForGoodsWaybill.LineNumber = RowOfGoods.LineNumber;
			If SeriesSpecificationParameters.UseCostAccountingByBatches Then
				StructureOfSearchForGoodsWaybill.Series = RowOfGoods.Series;
			EndIf;	
			ArrayOfTSRows = Object.Goods.FindRows(StructureOfSearchForGoodsWaybill);
		EndIf;
		
		If ArrayOfTSRows.Count() = 0 Then
			
			StringTSGoods = Object.Goods.Add();
			
		ElsIf ArrayOfTSRows.Count() = 1 Then
			
			StringTSGoods = ArrayOfTSRows[0];
			
		ElsIf ArrayOfTSRows.Count() > 1 Then
			
			For Each RowToDelete In ArrayOfTSRows Do
				
				Object.Goods.Delete(RowToDelete);
				
			EndDo;
			
			StringTSGoods = Object.Goods.Add();
			
		EndIf;
		
		FillPropertyValues(StringTSGoods, RowOfGoods);
		If Not UseReceiptForMultipleOrders 
			And ValueIsFilled(StringTSGoods.PurchaseOrder) 
			And Object.PurchaseOrder <> StringTSGoods.PurchaseOrder Then
			
			Object.PurchaseOrder = StringTSGoods.PurchaseOrder;
			DefaultAssignmentHasChanged = True;
			
		EndIf;
		
		If DefaultAssignmentHasChanged Then
			AssignmentsServer.WhenYouChangeDestinationTemplateInDocument(ThisObject);
			UpdateDestinationPresentation();
		EndIf;
		
	EndDo;
	FillInShopPantryAttributeInTable();
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	StructureOfActions = New Structure;
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	FillInPricesOfOrderProductRange();
	WhenChangingWarehouseInTablePartServer();
	
	UpdateOrderInformation();
	Object.ReceiptUnderOrders = ValueIsFilled(Object.PurchaseOrder) Or OrderList.Count() > 0;
	UpdateOrderDeviations();
	
	SetVisibilityOfItemsByOrder();
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, TSName)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	If TSName = "Goods" Then
		AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
			StructureOfActions);
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions,
			"Warehouse",
			True);
		StructureOfActions.Insert("FillInShopPantryAttribute");
	
		If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
		EndIf;
	EndIf;
	
	RowsToProcess = New Array;
	
	For Each RowOfGoods In ItemsFromStorage Do
		ObjectTS = Object[TSName]; // DocumentTabularSection.GoodsReceiptForStorage.Goods
		StringTSGoods = ObjectTS.Add();
		If TSName = "Goods" Then
			FillPropertyValues(StringTSGoods, RowOfGoods, , "RowCode");
			If Object.ReceiptUnderOrders Then
				StringTSGoods.OrderDiscrepancy_3 = 1;
			EndIf;
			
			RowsToProcess.Add(StringTSGoods);
			
		Else 
			FillPropertyValues(StringTSGoods, RowOfGoods);
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TSName]);
	
	If TSName = "Goods" Then
		FillInStatusesForSpecifyingSeriesServer();
		PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
		FillInPricesOfOrderProductRange();
		WhenChangingWarehouseInTablePartServer();
		UpdateOrderInformation();
	EndIf;

EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.Goods, ArrayOfSelectedRows, Warehouse, True);
	
	Rows = New Array;
	For Each RowID In ArrayOfSelectedRows Do
		Rows.Add(Object.Goods.FindByID(RowID));
	EndDo;
	FillInShopPantryAttributeInTable(, Rows);
	If FilledWithRows > 0 Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.ProcessTSStrings(Rows, StructureOfActions, Object.Goods);
		WhenChangingWarehouseInTablePartServer();
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtServer
Function LinkReceiptLinesToOrdersToSuppliers(SelectByOrder_, FillInPricesByOrder = False)
	
	If Not (UsePurchaseOrders Or UseMaterialProviderOrder2_5)
		Or Not UseReceiptForMultipleOrders And Not ValueIsFilled(Object.PurchaseOrder) Then
		
		Return False;
		
	EndIf;
	
	TextSourceData =
		"SELECT
		|	Goods.Products   AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.PurchaseOrder AS PurchaseOrder,
		|	Goods.RowCode,
		|	Goods.Warehouse,
		|	Goods.Count
		|INTO DocumentGoods
		|FROM
		|	&Goods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products   AS Products,
		|	Goods.Characteristic AS Characteristic
		|INTO Goods
		|FROM
		|	DocumentGoods AS Goods
		|WHERE
		|	Goods.RowCode = 0
		|	OR Goods.PurchaseOrder = UNDEFINED
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Warehouses.Ref AS Warehouse
		|INTO Warehouses
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref IN HIERARCHY(&Warehouse)
		|	AND NOT Warehouses.DeletionMark
		|	AND &WarehouseGroup_1
		|
		|UNION ALL
		|
		|SELECT
		|	&Warehouse AS Warehouse
		|WHERE
		|	NOT &WarehouseGroup_1
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse
		|
		|INDEX BY
		|	Warehouse
		|;
		|";
	
	If SelectByOrder_ Then
		QueryTextBalance =
			"SELECT
			|	OrdersTable.PurchaseOrder.SalesOpportunity    AS SalesOpportunity,
			|	OrdersTable.PurchaseOrder           AS PurchaseOrder,
			|	OrdersTable.Products              AS Products,
			|	OrdersTable.Characteristic            AS Characteristic,
			|	OrdersTable.RowCode                 AS RowCode,
			|	OrdersTable.Warehouse                     AS Warehouse,
			|	SUM(OrdersTable.ToRegister)        AS ToRegisterBalance
			|INTO
			|	PurchaseOrders
			|FROM
			|	(SELECT
			|		OrdersBalance.PurchaseOrder        AS PurchaseOrder,
			|		OrdersBalance.Products           AS Products,
			|		OrdersBalance.Characteristic         AS Characteristic,
			|		OrdersBalance.RowCode              AS RowCode,
			|		OrdersBalance.Warehouse                  AS Warehouse,
			|		OrdersBalance.ToRegisterBalance     AS ToRegister
			|	FROM
			|		AccumulationRegister.PurchaseOrders.Balance(,
			|			(PurchaseOrder, Products, Characteristic)
			|				IN (SELECT
			|						&PurchaseOrder AS PurchaseOrder,
			|						Goods.Products AS Products,
			|						Goods.Characteristic AS Characteristic
			|					FROM
			|						Goods AS Goods)
			|			AND Warehouse IN (SELECT
			|							Warehouses.Warehouse
			|						FROM
			|							Warehouses AS Warehouses)) AS OrdersBalance
			|
			|	UNION ALL
			|
			|	SELECT
			|		TrafficOrders.PurchaseOrder,
			|		TrafficOrders.Products,
			|		TrafficOrders.Characteristic,
			|		TrafficOrders.RowCode,
			|		TrafficOrders.Warehouse,
			|		CASE
			|			WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN -TrafficOrders.ToRegister
			|			ELSE TrafficOrders.ToRegister
			|		END
			|	FROM
			|		AccumulationRegister.PurchaseOrders AS TrafficOrders
			|	WHERE
			|		TrafficOrders.Recorder = &Recorder
			|		AND (PurchaseOrder, Products, Characteristic)
			|			IN (SELECT
			|					&PurchaseOrder AS PurchaseOrder,
			|					Goods.Products AS Products,
			|					Goods.Characteristic AS Characteristic
			|				FROM
			|					Goods AS Goods)
			|		AND Warehouse IN (SELECT
			|						Warehouses.Warehouse
			|					FROM
			|						Warehouses AS Warehouses)
			|		AND TrafficOrders.Active
			|	) AS OrdersTable
			|	
			|	GROUP BY
			|		OrdersTable.PurchaseOrder,
			|		OrdersTable.Products,
			|		OrdersTable.Characteristic,
			|		OrdersTable.RowCode,
			|		OrdersTable.Warehouse
			|	
			|	HAVING
			|		SUM(OrdersTable.ToRegister) > 0
			|;
			|";
	Else
		QueryTextBalance =
			"SELECT
			|	OrdersTable.PurchaseOrder.SalesOpportunity    AS SalesOpportunity,
			|	OrdersTable.PurchaseOrder           AS PurchaseOrder,
			|	OrdersTable.Products              AS Products,
			|	OrdersTable.Characteristic            AS Characteristic,
			|	OrdersTable.RowCode                 AS RowCode,
			|	OrdersTable.Warehouse                     AS Warehouse,
			|	SUM(OrdersTable.ToRegister)        AS ToRegisterBalance
			|INTO
			|	PurchaseOrders
			|FROM
			|	(SELECT
			|		OrdersBalance.PurchaseOrder        AS PurchaseOrder,
			|		OrdersBalance.Products           AS Products,
			|		OrdersBalance.Characteristic         AS Characteristic,
			|		OrdersBalance.RowCode              AS RowCode,
			|		OrdersBalance.Warehouse                  AS Warehouse,
			|		OrdersBalance.ToRegisterBalance     AS ToRegister
			|	FROM
			|		AccumulationRegister.PurchaseOrders.Balance(,
			|			(Products, Characteristic) IN (SELECT
			|												Goods.Products AS Products,
			|												Goods.Characteristic AS Characteristic
			|											FROM
			|												Goods AS Goods)
			|			AND Warehouse IN (SELECT
			|							Warehouses.Warehouse
			|						FROM
			|							Warehouses AS Warehouses)) AS OrdersBalance
			|		LEFT JOIN Document.PurchaseOrder AS OrdersToSupplier
			|		ON OrdersToSupplier.Ref = OrdersBalance.PurchaseOrder
			|
			|	WHERE
			|		OrdersToSupplier.Partner = &Partner
			|		AND OrdersToSupplier.Counterparty = &Counterparty
			|		AND OrdersToSupplier.Contract = &Contract
			|		AND OrdersToSupplier.Organization = &Organization
			|		AND OrdersToSupplier.BusinessOperation IN(&BusinessTransactions)
			|		AND OrdersToSupplier.GoodsReceiptOption = &GoodsReceiptOption
			|		AND OrdersToSupplier.Terms = &Terms
			|
			|	UNION ALL
			|
			|	SELECT
			|		OrdersBalance.PurchaseOrder        AS PurchaseOrder,
			|		OrdersBalance.Products           AS Products,
			|		OrdersBalance.Characteristic         AS Characteristic,
			|		OrdersBalance.RowCode              AS RowCode,
			|		OrdersBalance.Warehouse                  AS Warehouse,
			|		OrdersBalance.ToRegisterBalance     AS ToRegister
			|	FROM
			|		AccumulationRegister.PurchaseOrders.Balance(,
			|			(Products, Characteristic) IN
			|					(SELECT
			|						Goods.Products   AS Products,
			|						Goods.Characteristic AS Characteristic
			|					FROM
			|						Goods AS Goods)
			|			AND Warehouse IN
			|				(SELECT
			|					Warehouses.Warehouse
			|				FROM
			|					Warehouses AS Warehouses)) AS OrdersBalance
			|		INNER JOIN Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
			|		ON OrdersBalance.PurchaseOrder = MaterialProviderOrder2_5.Ref
			|
			|	WHERE
			|		MaterialProviderOrder2_5.Partner                 = &Partner
			|		AND MaterialProviderOrder2_5.Counterparty            = &Counterparty
			|		AND MaterialProviderOrder2_5.Contract               = &Contract
			|		AND MaterialProviderOrder2_5.Organization           = &Organization
			|		AND MaterialProviderOrder2_5.GoodsReceiptOption = &GoodsReceiptOption
			|		AND MaterialProviderOrder2_5.BusinessOperation IN(&BusinessTransactions)
			|
			|	UNION ALL
			|
			|	SELECT
			|		TrafficOrders.PurchaseOrder        AS PurchaseOrder,
			|		TrafficOrders.Products           AS Products,
			|		TrafficOrders.Characteristic         AS Characteristic,
			|		TrafficOrders.RowCode              AS RowCode,
			|		TrafficOrders.Warehouse                  AS Warehouse,
			|		CASE
			|			WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN -TrafficOrders.ToRegister
			|			ELSE TrafficOrders.ToRegister
			|		END                                 AS ToRegister
			|	FROM
			|		AccumulationRegister.PurchaseOrders AS TrafficOrders
			|		LEFT JOIN Document.PurchaseOrder AS OrdersToSupplier
			|		ON OrdersToSupplier.Ref = TrafficOrders.PurchaseOrder
			|
			|	WHERE
			|		TrafficOrders.Recorder = &Recorder
			|		AND (Products, Characteristic)
			|			IN (SELECT
			|					Goods.Products AS Products,
			|					Goods.Characteristic AS Characteristic
			|				FROM
			|					Goods AS Goods)
			|		AND TrafficOrders.Warehouse IN (SELECT
			|						Warehouses.Warehouse
			|					FROM
			|						Warehouses AS Warehouses)
			|		AND OrdersToSupplier.Partner = &Partner
			|		AND OrdersToSupplier.Counterparty = &Counterparty
			|		AND OrdersToSupplier.Contract = &Contract
			|		AND OrdersToSupplier.Organization = &Organization
			|		AND OrdersToSupplier.GoodsReceiptOption = &GoodsReceiptOption
			|		AND OrdersToSupplier.BusinessOperation IN(&BusinessTransactions)
			|		AND OrdersToSupplier.Terms = &Terms
			|		AND TrafficOrders.Active
			|
			|	UNION ALL
			|
			|	SELECT
			|		TrafficOrders.PurchaseOrder        AS PurchaseOrder,
			|		TrafficOrders.Products           AS Products,
			|		TrafficOrders.Characteristic         AS Characteristic,
			|		TrafficOrders.RowCode              AS RowCode,
			|		TrafficOrders.Warehouse                  AS Warehouse,
			|		CASE
			|			WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN -TrafficOrders.ToRegister
			|			ELSE TrafficOrders.ToRegister
			|		END                                 AS ToRegister
			|	FROM
			|		AccumulationRegister.PurchaseOrders AS TrafficOrders
			|		
			|		INNER JOIN Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
			|		ON TrafficOrders.PurchaseOrder = MaterialProviderOrder2_5.Ref
			|
			|	WHERE
			|		TrafficOrders.Recorder = &Recorder
			|		AND TrafficOrders.Active
			|		AND TRUE IN
			|			(SELECT TOP 1
			|				TRUE
			|			FROM
			|				Goods AS Goods
			|			WHERE
			|				Goods.Products     = TrafficOrders.Products
			|				AND Goods.Characteristic = TrafficOrders.Characteristic)
			|		AND TRUE IN
			|			(SELECT TOP 1
			|				TRUE
			|			FROM
			|				Warehouses AS Warehouses
			|			WHERE
			|				Warehouses.Warehouse = TrafficOrders.Warehouse)
			|		AND MaterialProviderOrder2_5.Partner               = &Partner
			|		AND MaterialProviderOrder2_5.Counterparty            = &Counterparty
			|		AND MaterialProviderOrder2_5.Contract               = &Contract
			|		AND MaterialProviderOrder2_5.Organization           = &Organization
			|		AND MaterialProviderOrder2_5.GoodsReceiptOption = &GoodsReceiptOption
			|		AND MaterialProviderOrder2_5.BusinessOperation IN(&BusinessTransactions)
			|
			|	UNION ALL
			|
			|	SELECT
			|		DocumentGoods.PurchaseOrder,
			|		DocumentGoods.Products,
			|		DocumentGoods.Characteristic,
			|		DocumentGoods.RowCode,
			|		DocumentGoods.Warehouse,
			|		-DocumentGoods.Count
			|	FROM
			|		DocumentGoods AS DocumentGoods
			|	WHERE
			|		DocumentGoods.RowCode <> 0
			|	) AS OrdersTable
			|	
			|	GROUP BY
			|		OrdersTable.PurchaseOrder,
			|		OrdersTable.Products,
			|		OrdersTable.Characteristic,
			|		OrdersTable.RowCode,
			|		OrdersTable.Warehouse
			|	
			|	HAVING
			|		SUM(OrdersTable.ToRegister) > 0
			|;
			|";
	EndIf;
	
	QueryTextOrders =
		"SELECT
		|	COUNT(*)                        AS DuplicateCount,
		|	PurchaseOrders.Products       AS Products,
		|	PurchaseOrders.Characteristic     AS Characteristic,
		|	PurchaseOrders.Warehouse              AS Warehouse
		|INTO
		|	DuplicatesOfProducts
		|FROM
		|	PurchaseOrders AS PurchaseOrders
		|
		|GROUP BY
		|	PurchaseOrders.Products,
		|	PurchaseOrders.Characteristic,
		|	PurchaseOrders.Warehouse
		|;
		|SELECT
		|	PurchaseOrderGoods.Ref          AS Ref,
		|	PurchaseOrderGoods.LineNumber     AS LineNumber,
		|	PurchaseOrderGoods.DateOfReceipt AS DateOfReceipt,
		|	0                                     AS Price,
		|	PurchaseOrders.SalesOpportunity             AS SalesOpportunity,
		|	PurchaseOrders.PurchaseOrder    AS PurchaseOrder,
		|	PurchaseOrders.Products       AS Products,
		|	PurchaseOrders.Characteristic     AS Characteristic,
		|	PurchaseOrders.RowCode          AS RowCode,
		|	PurchaseOrders.Warehouse              AS Warehouse,
		|	PurchaseOrders.ToRegisterBalance AS ToRegisterBalance,
		|	0                                    AS Allocated,
		|	DuplicatesOfProducts.DuplicateCount        AS DuplicateCount
		|FROM
		|	PurchaseOrders AS PurchaseOrders
		|LEFT JOIN
		|	DuplicatesOfProducts
		|ON
		|	PurchaseOrders.Products = DuplicatesOfProducts.Products
		|	AND PurchaseOrders.Characteristic = DuplicatesOfProducts.Characteristic
		|	AND PurchaseOrders.Warehouse = DuplicatesOfProducts.Warehouse
		|LEFT JOIN
		|	Document.PurchaseOrder.Goods AS PurchaseOrderGoods
		|ON
		|	PurchaseOrderGoods.Ref = PurchaseOrders.PurchaseOrder
		|	AND PurchaseOrderGoods.RowCode = PurchaseOrders.RowCode
		|WHERE
		|	NOT &ThisIsReceiptFromGiver2_5
		|
		|UNION ALL
		|
		|SELECT
		|	ISNULL(MaterialProviderOrder2_5UsedMaterials.Ref, UNDEFINED)              AS Ref,
		|	ISNULL(MaterialProviderOrder2_5UsedMaterials.LineNumber, 0)                    AS LineNumber,
		|	ISNULL(MaterialProviderOrder2_5UsedMaterials.DateOfReceipt, DATETIME(1,1,1)) AS DateOfReceipt,
		|	ISNULL(MaterialProviderOrder2_5UsedMaterials.Price, 0)                           AS Price,
		|	PurchaseOrders.SalesOpportunity                                              AS SalesOpportunity,
		|	PurchaseOrders.PurchaseOrder                                     AS PurchaseOrder,
		|	PurchaseOrders.Products                                        AS Products,
		|	PurchaseOrders.Characteristic                                      AS Characteristic,
		|	PurchaseOrders.RowCode                                           AS RowCode,
		|	PurchaseOrders.Warehouse                                               AS Warehouse,
		|	PurchaseOrders.ToRegisterBalance                                  AS ToRegisterBalance,
		|	0                                                                     AS Allocated,
		|	DuplicatesOfProducts.DuplicateCount                                         AS DuplicateCount
		|FROM
		|	PurchaseOrders AS PurchaseOrders
		|
		|		LEFT JOIN DuplicatesOfProducts AS DuplicatesOfProducts
		|		ON PurchaseOrders.Products   = DuplicatesOfProducts.Products
		|		 AND PurchaseOrders.Characteristic = DuplicatesOfProducts.Characteristic
		|		 AND PurchaseOrders.Warehouse          = DuplicatesOfProducts.Warehouse
		|
		|		LEFT JOIN Document.MaterialProviderOrder2_5.UsedMaterials AS MaterialProviderOrder2_5UsedMaterials
		|		ON PurchaseOrders.PurchaseOrder = MaterialProviderOrder2_5UsedMaterials.Ref 
		|		 AND PurchaseOrders.RowCode       = MaterialProviderOrder2_5UsedMaterials.RowCode
		|WHERE
		|	&ThisIsReceiptFromGiver2_5
		|ORDER BY
		|	Ref,
		|	LineNumber,
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	DateOfReceipt
		|";
		
	QueryText =
		TextSourceData
		+ QueryTextBalance
		+ QueryTextOrders;
	
	Query = New Query(QueryText);
	StructureOfActionsSum = New Structure;
	StructureOfActionsSum.Insert("RecalculateAmount");

	ProcessedRowsAmount = New Array;
	StructureOfActionsQuantityAmount = New Structure;
	StructureOfActionsQuantityAmount.Insert("RecalculateNumberOfPackages");
	StructureOfActionsQuantityAmount.Insert("RecalculateAmount");
	StructureOfActionsQuantityAmount.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);

	ProcessedLinesQuantityAmount = New Array;

	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActionsQuantityAmount,
		"Warehouse",
		True);
	
	BusinessTransactions = New Array;
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		BusinessTransactions.Add(TollingSchemeClientServer.ContractBusinessTransaction());
		BusinessTransactions.Add(Enums.BusinessTransactions.Subcontracting2_5);
		BusinessTransactions.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
		BusinessTransactions.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5);
		BusinessTransactions.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
		Query.SetParameter("ThisIsReceiptFromGiver2_5", True);
	Else
		BusinessTransactions.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
		Query.SetParameter("ThisIsReceiptFromGiver2_5", False);
	EndIf;
	WarehouseGroup_1 = Common.ObjectAttributeValue(Object.Warehouse, "IsFolder");
	
	Query.SetParameter("PurchaseOrder",           Object.PurchaseOrder);
	Query.SetParameter("Partner",                   Object.Partner);
	Query.SetParameter("Counterparty",                Object.Counterparty);
	Query.SetParameter("Contract",                   Object.Contract);
	Query.SetParameter("Organization",               Object.Organization);
	Query.SetParameter("BusinessTransactions",     BusinessTransactions);
	Query.SetParameter("Terms",                Object.Terms);
	Query.SetParameter("GoodsReceiptOption",     Object.GoodsReceiptOption);
	Query.SetParameter("Warehouse",                     Object.Warehouse);
	Query.SetParameter("WarehouseGroup_1",              ?(WarehouseGroup_1 = Undefined, False, WarehouseGroup_1));
	Query.SetParameter("Recorder",               Object.Ref);
	
	Query.SetParameter("Goods",  Object.Goods.Unload(,"RowCode,Products,Characteristic,PurchaseOrder,Warehouse,Count"));
	Query.TempTablesManager = New TempTablesManager;
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	If QueryResult[3].IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = QueryResult[5].Select();
	
	TableOfUnallocatedGoods = New ValueTable();
	TableOfUnallocatedGoods.Columns.Add("Products");
	TableOfUnallocatedGoods.Columns.Add("Characteristic");
	TableOfUnallocatedGoods.Columns.Add("Warehouse");
	TableOfUnallocatedGoods.Columns.Add("PurchaseOrder");
	TableOfUnallocatedGoods.Columns.Add("RowCode");
	TableOfUnallocatedGoods.Columns.Add("Count");
	TableOfUnallocatedGoods.Columns.Add("SalesOpportunity");
	TableOfUnallocatedGoods.Columns.Add("Order");
	
	StringCodeFields			= "RowCode, PurchaseOrder, SalesOpportunity";
	FieldsLineCodeQuantity = StringCodeFields + ", Count";
	If FillInPricesByOrder Then
		
		StringCodeFields 			= StringCodeFields + ", Price";
		FieldsLineCodeQuantity = FieldsLineCodeQuantity + ", Price";
		
		TableOfUnallocatedGoods.Columns.Add("Price");
		
	EndIf;
	While Selection.Next() Do
		
		UseOrder = True;
		
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("Products",   Selection.Products);
		TheStructureOfTheSearch.Insert("Characteristic", Selection.Characteristic);
		TheStructureOfTheSearch.Insert("Warehouse",          Selection.Warehouse);
		TheStructureOfTheSearch.Insert("RowCode",      0);
		TheStructureOfTheSearch.Insert("PurchaseOrder", Selection.PurchaseOrder);
		
		FoundRows = Object.Goods.FindRows(TheStructureOfTheSearch);
		
		If FoundRows.Count() = 0 Then
			UseOrder = False;
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("Products",   Selection.Products);
			TheStructureOfTheSearch.Insert("Characteristic", Selection.Characteristic);
			TheStructureOfTheSearch.Insert("Warehouse",          Selection.Warehouse);
			TheStructureOfTheSearch.Insert("RowCode",      0);
			TheStructureOfTheSearch.Insert("PurchaseOrder", Undefined);
			FoundRows = Object.Goods.FindRows(TheStructureOfTheSearch);
		EndIf;
		
		RetainedQuantity = Selection.ToRegisterBalance;
		
		// If there are no duplicates, we distribute the order line to the invoice lines
		If Selection.DuplicateCount < 2 Then
		
			For Each CurRow In FoundRows Do
			
				FillPropertyValues(CurRow, Selection, StringCodeFields);
				
				QuantityPerLine = CurRow.Count;
				
				If QuantityPerLine > RetainedQuantity Then
					
					CurRow.Count = RetainedQuantity;
					
					ProcessedLinesQuantityAmount.Add(CurRow);
				ElsIf FillInPricesByOrder Then
					ProcessedRowsAmount.Add(CurRow);
				EndIf;
				
				RetainedQuantity = RetainedQuantity - QuantityPerLine;
				
				If RetainedQuantity < 0 Then
					NewRow = TableOfUnallocatedGoods.Add();
					FillPropertyValues(NewRow, Selection, , "RowCode");
					NewRow.Count = -RetainedQuantity;
					
					NewLineProducts = Object.Goods.Add();
					FillPropertyValues(NewLineProducts, CurRow, , "RowCode,PurchaseOrder");
					NewLineProducts.Count = -RetainedQuantity;
					ProcessedLinesQuantityAmount.Add(NewLineProducts);
				ElsIf RetainedQuantity = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		// If there are duplicates, we distribute the order lines according to the invoice lines, taking into account the quantity.
		Else
			
			// On the first pass, we will fill in only if the quantity in the order line and the invoice match.
			
			MatchingStringFound = False;
			
			For Each CurRow In FoundRows Do
				
				If CurRow.Count = Selection.ToRegisterBalance Then
					
					MatchingStringFound = True;
					FillPropertyValues(CurRow, Selection, StringCodeFields);
					If FillInPricesByOrder Then
						ProcessedLinesQuantityAmount.Add(CurRow);
					EndIf;
					Break;
					
				EndIf;
				
			EndDo;
			
			If Not MatchingStringFound Then
				
				NewRow = TableOfUnallocatedGoods.Add();
				FillPropertyValues(NewRow, Selection);
				NewRow.Count = RetainedQuantity;
				NewRow.Order    = ?(UseOrder, 1, 0);
			EndIf;
			
		EndIf;
		
	EndDo;

	// We will distribute duplicates of goods that were not distributed on the first pass
	If TableOfUnallocatedGoods.Count() > 0 Then

		TableOfUnallocatedGoods.Sort("Order Desc");

		For Each UnallocatedRow In TableOfUnallocatedGoods Do
			
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("RowCode", 0);
			TheStructureOfTheSearch.Insert("PurchaseOrder", UnallocatedRow.PurchaseOrder);
			TheStructureOfTheSearch.Insert("Products",   UnallocatedRow.Products);
			TheStructureOfTheSearch.Insert("Characteristic", UnallocatedRow.Characteristic);
			TheStructureOfTheSearch.Insert("Warehouse",          UnallocatedRow.Warehouse);
			
			ProductLines_3 = Object.Goods.FindRows(TheStructureOfTheSearch);
			
			If ProductLines_3.Count() = 0 Then
				
				TheStructureOfTheSearch = New Structure();
				TheStructureOfTheSearch.Insert("RowCode", 0);
				TheStructureOfTheSearch.Insert("PurchaseOrder", Undefined);
				TheStructureOfTheSearch.Insert("Products",   UnallocatedRow.Products);
				TheStructureOfTheSearch.Insert("Characteristic", UnallocatedRow.Characteristic);
				TheStructureOfTheSearch.Insert("Warehouse",          UnallocatedRow.Warehouse);
				
				ProductLines_3 = Object.Goods.FindRows(TheStructureOfTheSearch);
			
			EndIf;
			
			For Each LineProducts_ In ProductLines_3 Do
				
				If LineProducts_.Count = UnallocatedRow.Count Then
					FillPropertyValues(LineProducts_, UnallocatedRow, StringCodeFields);
					UnallocatedRow.Count = 0;
					If FillInPricesByOrder Then
						ProcessedLinesQuantityAmount.Add(LineProducts_);
					EndIf;
				ElsIf LineProducts_.Count > UnallocatedRow.Count Then
					Difference = LineProducts_.Count - UnallocatedRow.Count;
					
					NewLineProducts = Object.Goods.Add();
					FillPropertyValues(NewLineProducts, LineProducts_);
					NewLineProducts.Count = Difference;
					ProductLines_3.Add(NewLineProducts);
					
					FillPropertyValues(LineProducts_, UnallocatedRow, FieldsLineCodeQuantity);
					
					UnallocatedRow.Count = 0;
					
					ProcessedLinesQuantityAmount.Add(NewLineProducts);
					ProcessedLinesQuantityAmount.Add(LineProducts_);
					
				ElsIf LineProducts_.Count < UnallocatedRow.Count Then
					Difference = UnallocatedRow.Count - LineProducts_.Count;
					FillPropertyValues(LineProducts_, UnallocatedRow, StringCodeFields);
					UnallocatedRow.Count = Difference;
					If FillInPricesByOrder Then
						ProcessedLinesQuantityAmount.Add(LineProducts_);
					EndIf;
				EndIf;
				
				If UnallocatedRow.Count = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		EndDo;
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesQuantityAmount,
		StructureOfActionsQuantityAmount,
		Object.Goods,
		Undefined);
	BatchProcessingOfTablePartServer.ProcessTSString(
		ProcessedRowsAmount,
		StructureOfActionsSum,
		Undefined,
		Object.Goods);

	FillInShopPantryAttributeInTable();
	Return True;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", Form.ParametersForRecalculatingNumberOfUnits);
	StructureOfActions.Insert("RecalculateAmount");
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Form.Object,
		StructureOfActions,
		"Warehouse",
		True);
	
EndProcedure

&AtClient
Procedure QuestionUserBeforeFillingInPricesByAgreement(CallbackDescription)
	
	If Object.Goods.Count() = 0
		Or Not ValueIsFilled(Object.Terms) Then
		RunCallback(CallbackDescription, False);
		Return;
	EndIf;
	
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
	
	ShowQueryBox(
		CallbackDescription,
		NStr("vi = 'Điền lại giá theo thỏa thuận?';
			|ru = 'Перезаполнить цены по соглашению?';
			|en = 'Refill prices by terms of sales?'; fa = 'Refill prices by terms of sales?';
			|it = 'Ricompilare i prezzi in base all''accordo?';
			|pl = 'Wypełnić ceny ponownie wg porozumienia?';
			|tr = 'Fiyatlar anlaşmaya göre yeniden doldurulsun mu?'"),
		AnswersOptions);
	
EndProcedure

&AtClient
Procedure QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow)
	
	// If the current line is not related to the order
	If CurrentRow.RowCode = 0 Then
		RunCallback(CallbackDescription, True);
		Return;
	EndIf;
	
	// If none of the key details have changed
	If CurrentRow.Products = PreviousRowDetails.Products
		And CurrentRow.Characteristic = PreviousRowDetails.Characteristic
		And CurrentRow.Purpose = PreviousRowDetails.Purpose
		And CurrentRow.Warehouse = PreviousRowDetails.Warehouse Then
		RunCallback(CallbackDescription, True);
		Return;
	EndIf;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	AdditionalParameters.CallbackDescription = CallbackDescription;
	QueryText = NStr("vi = 'Dòng được soạn sẽ không liên quan đến dòng của đơn hàng. Tiếp tục?';
					|ru = 'Редактируемая строка перестанет быть связанной со строкой заказа. Продолжить?';
					|en = 'The edited line will be unlinked from the order line. Continue?'; fa = 'The edited line will be unlinked from the order line. Continue?';
					|it = 'La riga da modificare non sarà più associata alla riga dell''ordine. Continuare?';
					|pl = 'Edytowany wiersz nie będzie powiązany z wierszem zamówienia. Kontynuować?';
					|tr = 'Düzenlenecek satır artık sipariş satırına bağlı olmayacaktır. Devam edilsin mi?'");
	ShowQueryBox(
		New CallbackDescription("QuestionToUserWhenChangingDetailsOfLineQuestionCompletion", ThisObject, AdditionalParameters),
		QueryText,
		QuestionDialogMode.YesNo);
	
EndProcedure

// Parameters:
// 	Response - DialogReturnCode - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure QuestionToUserWhenChangingDetailsOfLineQuestionCompletion(Response, AdditionalParameters) Export
	
	// If the user has confirmed the change in the value of the key details
	If Response = DialogReturnCode.Yes Then
		
		AdditionalParameters.CurrentRow.RowCode = 0;
		AdditionalParameters.CurrentRow.OrderPrice = 0;
		UpdateOrderDeviationsInLine(AdditionalParameters.CurrentRow, Object.ReceiptUnderOrders);
		RunCallback(AdditionalParameters.CallbackDescription, True);
		
	Else
		
		// If the user refused to change the linked string, we will return the old values
		FillPropertyValues(AdditionalParameters.CurrentRow, PreviousRowDetails);
		RunCallback(AdditionalParameters.CallbackDescription, False);
		
	EndIf;
	
EndProcedure

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	TabularPartProducts = Object.Goods.Unload(,"Products, Characteristic, ItemVariantsAreUsed, Package, NumberOfPackages, Series, BatchesIndicationStatus, Warehouse, ItemsType, PurchaseOrder");
	TabularPartProducts.GroupBy("Products, Characteristic, ItemVariantsAreUsed, Package, Series, BatchesIndicationStatus, Warehouse, ItemsType, PurchaseOrder", "NumberOfPackages");
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	Return AddressInTempStorage;
	
EndFunction

&AtServerNoContext
Procedure SortArrayOfRowsProductsByOrderSupplier(RowsArray)
	
	SortTable = New ValueTable;
	SortTable.Columns.Add("TableRow");
	SortTable.Columns.Add("Order", New TypeDescription("Number"));
	
	For Each ArrayElement In RowsArray Do
		NewRow = SortTable.Add();
		NewRow.TableRow = ArrayElement;
		If ValueIsFilled(ArrayElement.PurchaseOrder) Then
			NewRow.Order = 1;
		Else
			NewRow.Order = 0;
		EndIf;
	EndDo;
	
	SortTable.Sort("Order");
	RowsArray = SortTable.UnloadColumn("TableRow");
	
EndProcedure

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	RowsToProcess = New Array;
	ProcessedLinesAreNew = New Array;
	LinesToDelete = New Array;
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("Products, Characteristic, Series, BatchesIndicationStatus, Package, Warehouse, PurchaseOrder");
		FillPropertyValues(Filter, SourceRow);
		FoundRows = Object.Goods.FindRows(Filter);
		SortArrayOfRowsProductsByOrderSupplier(FoundRows);
		
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
			
			If Object.ReceiptUnderOrders Then
				TSRow.OrderDiscrepancy_3 = 1;
			EndIf;
			
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

	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	StructureOfActions.Insert("FillInShopPantryAttribute");
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
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtClient
Procedure LabelHeadingOrdersToSuppliersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenBaseSelectionForm(True);
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_, False);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisObject);
	
EndFunction

&AtClient
Procedure UnlinkFromOrder(Command)
	SelectedRows = Items.Goods.SelectedRows;
	If SelectedRows.Count()>0 Then
		For Each CurRow In SelectedRows Do
			TableRow = Object.Goods.FindByID(CurRow);
			TableRow.RowCode = 0;
			TableRow.OrderDiscrepancy_3 = 1;
		EndDo;
		UpdateDependentDetailsOfServerByOrderForm();
		NotifyAboutEndOfUnbindingLines(SelectedRows.Count());
	Else
		WarningText = NStr("vi = 'Hãy chọn dòng cần hủy liên kết với đơn hàng.';
							|ru = 'Выберите строки, которые необходимо отвязать от заказа.';
							|en = 'Select lines to remove from the order.'; fa = 'Select lines to remove from the order.';
							|it = 'Selezionare le righe da dissociare dall''ordine.';
							|pl = 'Wybierz wierze, które należy odłączyć od zamówienia.';
							|tr = 'Siparişten çıkarılacak satırları seçin.'");
		ShowMessageBox(Undefined, WarningText);
	EndIf; 
EndProcedure

&AtServer
Procedure UpdateDependentDetailsOfServerByOrderForm()
	
	If Object.Goods.Count() = 0 Or Not UnlinkVisibilityFromOrder() Then
		Items.GroupDiscrepancyOnOrder.Visible = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
		DiscrepancyOrderText = "";
		
		If Object.Goods.Count()>0 Then
			For Each LineProducts_ In Object.Goods Do
				LineProducts_.OrderDiscrepancy_3 = 0;
			EndDo;
		EndIf;
		
		NumberOfDiscrepancies = 0;
		
		Return;
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(
		Items,
		Object.Goods,
		DiscrepancyOrderText);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDependentDetailsOfOrderForm_(FormItems, Goods, DiscrepancyOrderText)
	NumberOfDiscrepancies = Goods.Total("OrderDiscrepancy_3");
	
	FormItems.GroupDiscrepancyOnOrder.Visible = NumberOfDiscrepancies > 0;
	FormItems.GroupDiscrepancyOnOrders.Visible = NumberOfDiscrepancies > 0;
	
	If NumberOfDiscrepancies > 0 Then
		DiscrepancyOrderText = StrReplace(NStr("vi = 'Dòng trên đơn hàng: %NumberOfDiscrepancies%';
												|ru = 'Строк сверх заказа: %NumberOfDiscrepancies%';
												|en = 'Lines in excess of order: %NumberOfDiscrepancies%'; fa = 'Lines in excess of order: %NumberOfDiscrepancies%';
												|it = 'Righe oltre all''ordine: %NumberOfDiscrepancies%';
												|pl = 'Wierszy ponad zamówienia: %NumberOfDiscrepancies%';
												|tr = 'Sipariş fazlası satırı: %NumberOfDiscrepancies%'"), "%NumberOfDiscrepancies%", NumberOfDiscrepancies);
	Else
		DiscrepancyOrderText = "";
		NumberOfDiscrepancies = 0;
	EndIf;
EndProcedure

&AtClient
Procedure NotifyAboutEndOfUnbindingLines(NumberOfLinesWorked, LinesWereUnlinked = True)

	If LinesWereUnlinked Then
		NotificationText1 = NStr("vi = 'Trong chứng từ đã bỏ các dòng (%%Count%%) khỏi đơn hàng.';
								|ru = 'В документе от заказов отвязано строк (%%Count%%).';
								|en = 'In the document, the lines (%%Count%%) are detached from the orders.'; fa = 'In the document, the lines (%%Count%%) are detached from the orders.';
								|it = 'Righe dissociate (%%Count%%) dagli ordini nel documento.';
								|pl = 'W dokumencie odłączyć od zamówienia (%%Count%%) wierszy.';
								|tr = 'Belgede siparişlerden ayrılmış satırlar (%Count%) vardır.'");
		NotificationText1 = StrReplace(NotificationText1, "%%Count%%", NumberOfLinesWorked);
		ShowUserNotification(
			NStr("vi = 'Các dòng liên quan';
				|ru = 'Строки отвязаны';
				|en = 'Lines were unlinked'; fa = 'Lines were unlinked';
				|it = 'Righe dissociate';
				|pl = 'Wierze odłączone';
				|tr = 'Ayrılmış satırlar'"),
			,
			NotificationText1,
			PictureLib.Information32);
	Else
		ShowUserNotification(
			NStr("vi = 'Dòng có liên quan';
				|ru = 'Строки не отвязаны';
				|en = 'Lines were not unlinked'; fa = 'Lines were not unlinked';
				|it = 'Righe non dissociate';
				|pl = 'Wierze nie odłączone';
				|tr = 'Birleşik satırlar'"),
			,
			NStr("vi = 'Không có dòng nào liên quan.';
				|ru = 'Ни одна строка не была отвязана.';
				|en = 'No line was unlinked.'; fa = 'No line was unlinked.';
				|it = 'Nessuna riga è stata dissociata.';
				|pl = 'Nie odłączono ani jednego wiersza.';
				|tr = 'Hiçbir satır ayrılmamış.'"),
			PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityAgreements()
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "Terms", "Visible", False);
	Else
		If ValueIsFilled(Object.Partner) Then
			
			NumberOfAgreementsWithPostavshik  =
				PurchasesServerCall.GetNumberOfAgreementsWithSupplier(Object.Partner);
				
			TMCommonUseClientServer.SetFormItemProperty(
				Items, "Terms", "Visible", NumberOfAgreementsWithPostavshik > 0);
				
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ActionStructureModifiedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		ActionStructureModifiedStrings);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		ActionStructureModifiedStrings,
		"Warehouse",
		True);
	
	StructureOfActionsAddedLines = Common.CopyRecursive(ActionStructureModifiedStrings);
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsAddedLines.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActionsAddedLines.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActionsAddedLines.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActionsAddedLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsAddedLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsAddedLines.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsAddedLines);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActionsAddedLines);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActionsAddedLines,
		"Warehouse",
		True);
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic,Warehouse",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
	FillInShopPantryAttributeInTable();
	StructureOfNamesOfTableParts = New Structure("Goods");	
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	WhenChangingWarehouseInTablePartServer();
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

#EndRegion
#Region BusinessTransactions

&AtServer
Procedure CustomizeForm()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		
		AutoTitle = False;
		
		ObjectPresentation = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
		
		If ValueIsFilled(Parameters.Key) Then
			Title = StrTemplate(NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'"), ObjectPresentation, Object.Number, Object.Date);
		Else
			Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
									|ru = '%1 (создание)';
									|en = '%1 (create)'; fa = '%1 (create)';
									|it = '%1 (creazione)';
									|pl = '%1 (tworzenie)';
									|tr = '%1 (oluştur)'"), ObjectPresentation);
		EndIf;
		
		Items.Partner.Title               = NStr("vi = 'Bên đặt gia công';
												|ru = 'Давалец';
												|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
												|it = 'Fornitore';
												|pl = 'Material provider';
												|tr = 'Malzeme tedarikçisi'");
		Items.GoodsPurchaseOrder.Title = NStr("vi = 'Đơn hàng của bên đặt gia công';
												|ru = 'Заказ давальца';
												|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
												|it = 'Ordine del committente';
												|pl = 'Zamówienie dostawcy';
												|tr = 'Sağlayıcı siparişi'");
		
		Items.CloseOrder.Enabled               = False;
		
		Items.GoodsFillThePricesByTermsOfSales.Visible    = False;
		Items.GoodsAddReusablePackage.Visible = False;
		
		Items.GoodsPurpose.SkipOnInput =
			Object.ReceiptUnderOrders
			Or OptionOfMaterialAssignmentUponSubcontractingServicesDelivered =
					Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing;
		
	Else
		
		AutoTitle = True;
		Title     = "";
		
		Items.Partner.Title               = NStr("vi = 'Nhà cung cấp';
												|ru = 'Поставщик';
												|en = 'Vendor'; fa = 'تأمین‌کننده';
												|it = 'Fornitore';
												|pl = 'Vendor';
												|tr = 'Tedarikçi'");
		Items.GoodsPurchaseOrder.Title = NStr("vi = 'Đơn hàng đặt nhà cung cấp';
												|ru = 'Заказ поставщику';
												|en = 'Purchase order'; fa = 'سفارش خرید';
												|it = 'Ordine al fornitore';
												|pl = 'Zamówienie do dostawcy';
												|tr = 'Satın alma siparişi'");
		
		Items.CloseOrder.Enabled               = AccessRight("Update", Metadata.Documents.PurchaseOrder);
		
		Items.GoodsFillThePricesByTermsOfSales.Visible    = True;
		Items.GoodsAddReusablePackage.Visible = Not Object.ReceiptUnderOrders;
		
		Items.GoodsPurpose.SkipOnInput          = Undefined;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AdjustItemSelectionSettings()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then 
	
		// Partner
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Client", True));
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
	
		Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
		//Contract
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
		
		ChoiceParametersArray.Add(
			New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	
		ChoiceParametersArray.Add(
			New ChoiceParameter(
					"Filter.BusinessOperation", TollingSchemeClientServer.ContractBusinessTransaction()));
	
	
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
		
		Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
		Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	Else
	
		// Partner
		ChoiceParametersArray = New Array;
	
		Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
		//Contract
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
		
		ChoiceParametersArray.Add(
			New ChoiceParameter(
					"Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	
		ChoiceParametersArray.Add(
			New ChoiceParameter(
					"Filter.BusinessOperation", Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale));
	
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
	
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink(
					"Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
		
		Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
		Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInShopPantryAttributeInTable(RecalculateNumberOfUnits = Undefined, Rows = Undefined)
	
	ProductionServer.FillInShopPantryAttributeInTable(Object.Goods,,, Rows);
	
	If RecalculateNumberOfUnits = True
		Or RecalculateNumberOfUnits = Undefined
			And Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
	
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
		StructureOfActions = New Structure;
	
		StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
	
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	EndIf;
	
EndProcedure

#EndRegion
#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function FillInServerAcceptanceForm(ThereAreAcceptedGoods, LinkLinesToOrder = False)
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmount");
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		StructureOfActionsWithModifiedStrings.Insert(
			"RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
	EndIf;
	StructureOfActionsWithAddedStrings = New Structure;
	
	StructureOfActionsWithAddedStrings.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmount");
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	StructureOfActionsWithAddedStrings.Insert("FillInShopPantryAttribute");
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		StructureOfActionsWithAddedStrings.Insert(
			"RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits);
	EndIf;
	If Object.ReceiptUnderOrders Then
		ReferenceArray = Object.Goods.Unload(, "PurchaseOrder").UnloadColumn("PurchaseOrder");
		If ValueIsFilled(Object.PurchaseOrder)
			And ReferenceArray.Find(Object.PurchaseOrder) = Undefined Then
			ReferenceArray.Add(Object.PurchaseOrder);
		EndIf;
	Else
		ReferenceArray = Undefined;
	EndIf;
	
	If Catalogs.Warehouses.IsFolder(Object.Warehouse) Then
		Selection = Catalogs.Warehouses.Select(Object.Warehouse);
		WarehouseArray = New Array;
		While Selection.Next() Do
			WarehouseArray.Add(Selection.Ref);
		EndDo;
	EndIf;
	
	FillingWarehouse = ?(Catalogs.Warehouses.IsFolder(Object.Warehouse),WarehouseArray,Object.Warehouse);
	
	FillParameters = PurchasesServer.FillingParametersForActualAcceptance();
	FillParameters.DocumentInflow                    = Object.Ref;
	FillParameters.DateOfReceipt                        = Object.Date;
	FillParameters.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	FillParameters.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	FillParameters.Warehouse                                  = FillingWarehouse;
	FillParameters.ReferenceArray                     = ReferenceArray;
	FillParameters.Terms                             = Object.Terms;
	FillParameters.GoodsReceiptOption                  = Object.GoodsReceiptOption;
	
	HasChanges = PurchasesServer.FillInGoodsOnActualAcceptance(
		Object.Goods,
		FillParameters,
		ThereAreAcceptedGoods);
	
	If HasChanges And LinkLinesToOrder Then
		
		LinkReceiptLinesToOrdersToSuppliers(Not UseReceiptForMultipleOrders, True);
		
	EndIf;
	
	WhenChangingWarehouseInTablePartServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	RecalculateNumberOfRNPT();
	FillInStatusesForSpecifyingSeriesServer();
	UpdateOrderInformation();
	
	If Object.ReceiptUnderOrders Then
		UpdateOrderDeviations();
	EndIf;
	
	Return HasChanges;
	
EndFunction

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
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

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
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
		StructureOfActions.Insert("FillInShopPantryAttribute");
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
	WhenChangingWarehouseInTablePartServer();
	UpdateDependentDetailsOfOrderForm_(
		Items,
		Object.Goods,
		DiscrepancyOrderText);
	
EndProcedure

&AtServerNoContext
Function WarehouseSelectionData(Warehouse)

	Query = New Query(
	"SELECT ALLOWED
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY(&GroupOfWarehouses)
	|	AND Warehouses.IsFolder = FALSE
	|	AND Warehouses.SelectGroup <> VALUE(Enum.SelectWarehouseGroup.Disable)");

	Query.SetParameter("GroupOfWarehouses", Warehouse);
	WarehouseArray = Query.Execute().Unload().UnloadColumn("Ref");
	Return WarehouseArray;

EndFunction

&AtServer
Procedure SetParametersForSelectingProductsWarehouse()
	
	Items.GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	WarehouseSelectionData = WarehouseSelectionData(Object.Warehouse);
	
	TMCommonUseClientServer.AddSelectionParameter(Items.GoodsWarehouse, "Ref", WarehouseSelectionData);
	
EndProcedure

&AtClient
Procedure SpecialTransportationConditionsOnChange(Item)
	
	SpecialTransportationConditionsOnChangeServer();
	
EndProcedure

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	
	SupplementDeliveryInformationWithContactsServer();
	
EndProcedure

&AtServer
Procedure SpecialTransportationConditionsOnChangeServer()
	
	GoodsDelivery.SpecialTransportationConditionsOnChange(Items, Object);
	
EndProcedure

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
	
EndProcedure

&AtServer
Procedure SetTitleFillInByOrdersOrders()
	
	TableWarehouses = Object.Goods.Unload(,"Warehouse").UnloadColumn("Warehouse");
	AdvancedWarehousingOnReceiving = WarehousesServer.ThereIsOrderForReceiptWarehouse(TableWarehouses, Object.Date, Object.Warehouse);
	
	If Not AdvancedWarehousingOnReceiving And Not UseReceiptForMultipleOrders And UsePurchaseOrders Then
		TitleFillIn = NStr("vi = 'Chọn hàng hóa từ đơn hàng';
							|ru = 'Подобрать товары из заказа';
							|en = 'Pick goods from order'; fa = 'انتخاب کالاها از سفارش';
							|it = 'Selezionare le merci dall''ordine';
							|pl = 'Dobierz wiersze pozycji i zamówienia';
							|tr = 'Siparişten mal seçme'");
	ElsIf Not AdvancedWarehousingOnReceiving And UseReceiptForMultipleOrders And UsePurchaseOrders Then
		TitleFillIn = NStr("vi = 'Chọn hàng hóa từ đơn hàng';
							|ru = 'Подобрать товары из заказов';
							|en = 'Pick goods from orders'; fa = 'Pick goods from orders';
							|it = 'Selezionare le merci dagli ordini';
							|pl = 'Dobierz wiersze pozycji z zamówienia';
							|tr = 'Siparişlerden mal seçme'");
	ElsIf AdvancedWarehousingOnReceiving And Not UsePurchaseOrders Then
		TitleFillIn = NStr("vi = 'Chọn hàng hóa theo đơn';
							|ru = 'Подобрать товары по ордерам';
							|en = 'Pick goods by notes'; fa = 'انتخاب کالا بر اساس حواله‌ها';
							|it = 'Selezionare le merci in base ai mandati';
							|pl = 'Wybierz wiersze pozycji wg zleceń';
							|tr = 'Emirlere göre mal seçme'");
	Else
		TitleFillIn = NStr("vi = 'Chọn hàng hóa theo đơn đặt hàng / đơn hàng';
							|ru = 'Подобрать товары по заказам/ордерам';
							|en = 'Add items from Purchase order/Goods receipt'; fa = 'Add items from Purchase order/Goods receipt';
							|it = 'Seleziona le merci in base agli ordini/mandati';
							|pl = 'Wybierz wiersze pozycji wg zamówień/zleceń';
							|tr = 'Emir/siparişlere göre mal seçme'");
	EndIf;
	Items.GoodsSelectGoodsByOrdersNotes.Title = TitleFillIn;
	
EndProcedure

&AtServer
Procedure FillInPassedFieldSelectionList()
	
	If Not ValueIsFilled(Object.Partner) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT ALLOWED TOP 10
	|	MAX(GoodsReceiptForStorage.Date) AS Date,
	|	GoodsReceiptForStorage.HandedOverBy AS HandedOverBy
	|INTO VT_PassedDate
	|FROM
	|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
	|WHERE
	|	GoodsReceiptForStorage.Posted
	|	AND GoodsReceiptForStorage.Partner = &Partner
	|	AND GoodsReceiptForStorage.HandedOverBy <> """"
	|	AND GoodsReceiptForStorage.BusinessOperation = &BusinessOperation
	|
	|GROUP BY
	|	GoodsReceiptForStorage.HandedOverBy
	|
	|ORDER BY
	|	Date DESC
	|
	|INDEX BY
	|	Date,
	|	HandedOverBy
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MAX(GoodsReceiptForStorage.Ref) AS Ref
	|INTO TT_References
	|FROM
	|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
	|		INNER JOIN VT_PassedDate AS VT_PassedDate
	|		ON (VT_PassedDate.Date = GoodsReceiptForStorage.Date)
	|			AND (VT_PassedDate.HandedOverBy = GoodsReceiptForStorage.HandedOverBy)
	|			AND (GoodsReceiptForStorage.Partner = &Partner)
	|			AND GoodsReceiptForStorage.BusinessOperation = &BusinessOperation
	|
	|GROUP BY
	|	GoodsReceiptForStorage.HandedOverBy
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_References.Ref.HandedOverBy AS HandedOverBy,
	|	TT_References.Ref.HandedOverJobTitle AS HandedOverJobTitle
	|FROM
	|	TT_References AS TT_References
	|
	|ORDER BY
	|	TT_References.Ref.Date DESC";
	
	Query = New Query(QueryText);
	Query.SetParameter("Partner", Object.Partner);
	Query.SetParameter("BusinessOperation", Object.BusinessOperation);
	
	Selection = Query.Execute().Select();
	
	Items.HandedOverBy.ChoiceList.Clear();
	While Selection.Next() Do
		If Not IsBlankString(Selection.HandedOverBy) Then
			StructurePassed = New Structure("HandedOverBy, HandedOverJobTitle", Selection.HandedOverBy, Selection.HandedOverJobTitle);
			Items.HandedOverBy.ChoiceList.Add(StructurePassed,Selection.HandedOverBy);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If ValueIsFilled(Object.Warehouse)
		And ValueIsFilled(Object.Organization) Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Warehouse",
												True);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	If Not Object.ReceiptUnderOrders Then
		ItemArray.Add("Date");
	EndIf;
	
	// Header Controls
	ItemArray.Add("Partner");
	ItemArray.Add("Terms");
	ItemArray.Add("Contract");
	
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	ItemArray.Add("ReceiptAgainstOrder");
	ItemArray.Add("ReceiptUnderOrders");
	
	ItemArray.Add("BusinessOperation");
	ItemArray.Add("SalesOpportunity");
	ItemArray.Add("Department");
	
	ItemArray.Add("Warehouse");
	ItemArray.Add("Currency");
	
	ItemArray.Add("Goods;BeforeAddRow,BeforeDeleteRow,BeforeRowChange");
	
	ItemArray.Add("GoodsUnlinkFromOrder");
	ItemArray.Add("GoodsContextMenuUnlinkFromOrder");
	
	ItemArray.Add("GoodsSearchByBarcode");
	ItemArray.Add("GoodsGetWeight");
	ItemArray.Add("GoodsImportDataFromPDT");
	ItemArray.Add("GoodsCheckQuantityInTheDocument");
	ItemArray.Add("GoodsFillThePricesByTermsOfSales");
	ItemArray.Add("GoodsFillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice");
	ItemArray.Add("GoodsFillInThePricesForReceipts");
	ItemArray.Add("GoodsFillInCCDNumbers");
	ItemArray.Add("GoodsFillInTheGTDNumbersForReceipts");
	ItemArray.Add("GoodsSelectGoodsByOrdersNotes");
	ItemArray.Add("GoodsChangeQuality");
	
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsSplitRow");
	ItemArray.Add("GoodsContextMenuSplitTheFactString");
	ItemArray.Add("ProductsPickUpTheNomenclature");
	ItemArray.Add("GoodsFillInTheItemByThePartnerSItem");
	ItemArray.Add("GoodsAddReusablePackage");
	
	ItemArray.Add("GoodsImportFromExternalFile");
	ItemArray.Add("GoodsFillInTheWarehouseInSelectedLines");
	
	ItemArray.Add("ChangeBaseDocuments");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
	If Not Object.ReceiptUnderOrders Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsFillInTheWarehouseInSelectedLines", "Enabled", WarehouseGroup_);
	Else
		TMCommonUseClientServer.SetFormItemProperty(Items,"GoodsFillInTheWarehouseInSelectedLines", "Visible", False);
	EndIf;
	
	UnlinkVisibilityFromOrder = UnlinkVisibilityFromOrder();
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsUnlinkFromOrder",                "Visible", UnlinkVisibilityFromOrder);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsContextMenuUnlinkFromOrder", "Visible", UnlinkVisibilityFromOrder);
	
	If Object.ReceiptUnderOrders And Not UserRightsCached.VarianceFromPurchaseConditions() Then
		
		ItemArray = New Array;
		
		// Header Controls
		ItemArray.Add("Partner");
		ItemArray.Add("Terms");
		ItemArray.Add("Organization");
		ItemArray.Add("Counterparty");
		ItemArray.Add("BusinessOperation");
		ItemArray.Add("Manager");
		ItemArray.Add("SalesOpportunity");
		ItemArray.Add("Department");
		If Object.BusinessOperation <> Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			ItemArray.Add("Contract");
		EndIf;
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
	EndIf;
	
EndProcedure

&AtServer
Function UnlinkVisibilityFromOrder()
	
	VisibilityAttribute = UsePurchaseOrders 
					   And Object.ReceiptUnderOrders;
	VisibilityAttribute =
		VisibilityAttribute
		And Object.BusinessOperation <> Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
		Or UseMaterialProviderOrder2_5 
			And Object.ReceiptUnderOrders
			And Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
	Return VisibilityAttribute; 
	
EndFunction

&AtClient
Procedure FinishEditingProductsLine(Item, NewRow, CancelEdit)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
		
		If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters) Then
			IDCurrentRow = CurrentData.GetID();
			
			FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
			ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		EndIf;
		
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateDependentDetailsOfOrderForm_(Items, Object.Goods, DiscrepancyOrderText);
	
	If Not CancelEdit Then
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	EndIf;
	
EndProcedure

// Parameters:
// Selected value-Reference Link.Nomenclature of Contragents
// Additional Parameters-Structure-additional parameters.
&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure - advanced setting.
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	GoodsPartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

&AtServerNoContext
Function GetDefaultCounterpartyBankAccountServer(Counterparty)
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	
	Return CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	
EndFunction

&AtServerNoContext
Function OrdersUse(Form)
	
	Object = Form.Object;
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		OrdersUse = Form.UseMaterialProviderOrder2_5;
	Else
		OrdersUse = Form.UsePurchaseOrders;
	EndIf;
	Return OrdersUse;
	
EndFunction

&AtServer
Procedure FillInCurrencyAccordingToContract()
	
	If ValueIsFilled(Object.Contract) Then
		ContractCurrency = Common.ObjectAttributeValue(Object.Contract, "ARAPCurrency");
		If ContractCurrency <> Object.Currency Then
			Object.Currency = ContractCurrency;
			OnChangeCurrencyOnServer();
		EndIf;
	EndIf;
	
EndProcedure
	
&AtServer
Procedure OnChangeCurrencyOnServer()
	
	If ValueIsFilled(Object.Terms) Then
		AgreementCurrency = Common.ObjectAttributeValue(Object.Terms, "Currency");
		If AgreementCurrency <> Object.Currency Then
			Object.Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.Contract) Then
		ContractCurrency = Common.ObjectAttributeValue(Object.Contract, "ARAPCurrency");
		If ContractCurrency <> Object.Currency Then
			Contract = Catalogs.CounterpartyContracts.EmptyRef();
			Object.Contract = Contract;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.VendorPriceKind) Then
		CurrencyOfPriceType = Common.ObjectAttributeValue(Object.VendorPriceKind, "Currency");
		If CurrencyOfPriceType <> Object.Currency Then
			Object.VendorPriceKind = Catalogs.VendorPriceTypes.EmptyRef();
		EndIf;
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptForStorage,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
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
	ElsIf Item.Name = "sh_ShamsiInput_DateOfReceipt" Then
		DateOfReceiptOnChange(Items.DateOfReceipt);
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

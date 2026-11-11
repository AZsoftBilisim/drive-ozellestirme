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
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	UseSimplifiedPaymentSchemeInPurchasing = GetFunctionalOption("UseSimplifiedPaymentSchemeInPurchasing");
	
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
		If ThisForm.ReadOnly Then
			MessageText = NStr("vi = 'Không thể điền lại chứng từ ""%Document%"" vì đã thiết lập ngày cấm thay đổi!';
								|ru = 'Нельзя перезаполнить документ ""%Document%"", т.к. установлена дата запрета изменений!';
								|en = 'Can not refill the document ""%Document%"", because period-end closing date is set.'; fa = 'Can not refill the document ""%Document%"", because period-end closing date is set.';
								|it = 'Non è possibile ricompilare il documento ""%Document%"" perché è stata inserita la data di divieto di modifica!';
								|pl = 'Nie można wypełnić ponownie dokument ""%Document%"", ponieważ ustawiono datę zakazu zmian!';
								|tr = '""%Document%"" belgesinin üzerine yazılamaz çünkü değişiklik yasağı tarihi belirlenmiştir!'");
			MessageText = StrReplace(MessageText, "%Document%", Object.Ref);
			Common.MessageToUser(MessageText, Object.Ref);
		Else
			If Not GetDataOnAvailabilityOfAdjustmentsAndInvoices(Object.Ref) Then
				Cancel = True;
			Else
				FillInServerAcceptanceForm(False);
				Modified = True;
			EndIf;
		EndIf;
	EndIf;

	PurchasesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	TMCommonUseClientServer.SetFormItemProperty(Items, "BaseGroup_", "Visible", ValueIsFilled(Object.DocumentBasis));
	
	If Not UsePurchaseOrders Then
		Items.PicturePriceDeviationOrder.Visible = False;
		Items.PicturePriceDeviationOrders.Visible = False;
		Items.GroupDiscrepancyOnOrder.Visible = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
	EndIf;
	
	Contract = Object.Contract;
	
	Counterparty = Object.Counterparty;
	
	ReceiptOfGoodsIsUsed = GetFunctionalOption("UseGoodsInTransitFromVendors");
	Items.GoodsFillInSeriesAccordingToGoodsReceiptData.Visible = ReceiptOfGoodsIsUsed;
	
	ReceiptForSeparatePurchase =
		EconomicOperationsOfSeparatePurchase().Find(Object.BusinessOperation) <> Undefined;
	Items.GoodsFillInSeriesAccordingToGoodsReceiptData.Enabled = ReceiptForSeparatePurchase;
	
	If Not Object.ReceiptUnderOrders Or Not RightToReadOrdersToSupplier Then
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
	
	If Not GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") And Not GetFunctionalOption("UseBusinessUnits") Then
		Items.ProductsGroupRecipient.Visible = False;
	ElsIf Not WarehouseGroup_ Then
		Items.ProductsGroupRecipient.Title = NStr("vi = 'Bộ phận-nơi nhận';
													|ru = 'Подразделение-получатель';
													|en = 'Receiving business unit'; fa = 'واحد تجاری دریافت‌کننده';
													|it = 'Reparto-destinatario';
													|pl = 'Receiving business unit';
													|tr = 'Alıcı departman'");
	EndIf;
		
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	SetTitleFillInByOrdersOrders();
	
	Items.CloseOrder.Enabled = AccessRight("Update",Metadata.Documents.PurchaseOrder);
	Items.CloseOrders_2.Enabled = AccessRight("Update",Metadata.Documents.PurchaseOrder);
	Items.GoodsShowPriceVariances.Enabled = RightToReadOrdersToSupplier;
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	EstablishVisibilityOfRNPTQuantity();
	
	
	SetAvailabilityOfClipboardCommands();
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoice.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);	
	
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	OptionOfExecutionOfContractOfPurchases = PurchasesServer.GetVariantOfProcurementContract(Object.Contract);
	OptionForRegisteringServiceReceiptDocuments = PurchasesServer.GetVariantOfRegistrationOfDocumentsForAdmissionToServices(Object.Contract);
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);
	ThereIsRightToAddAdjustments = HaveRightToAddAdjustments();
	
	SetVisibilityOfActualDateOfOperation();
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoice.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenReadingOnServer(ThisObject);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

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
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(SelectionResult, ChoiceSource) Then
		
		UpdateTextDocumentsBasedOn();

	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(SelectionResult.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
	
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, SelectionResult);
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(SelectionResult);
		
	ElsIf ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SelectedRows = Items.Goods.SelectedRows;
		
		For Each String In SelectedRows Do
			
			RowData = Object.Goods.FindByID(String);
			
			If (RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Or
				RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
				And (Not RowData.ToExpenseAs Or ValueIsFilled(RowData.Purpose)) Then
				Continue;
			EndIf;
			
			RowData.Department = SelectionResult;
			
		EndDo;
		
	ElsIf ChoiceSource.FormName = "CommonForm.AttributesForExpenseReportPrinting" Then
		
		If SelectionResult <> Undefined Then
			FillPropertyValues(Object, SelectionResult);
		EndIf;
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
	SetWhetherWarehouseIsFull();
	
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
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter) Then
		ChangedPaymentServer(EventName, Parameter, Source);
	EndIf;
	
	If EventName = "UpdateInformationSecurityDocumentAfterFillingItOut"  And Parameter.Find(Object.Ref) <> Undefined Then
		Read();
	ElsIf EventName = "UpdateIBDocumentAfterFillingItOutFromFile"  And Parameter.Find(Object.Ref) <> Undefined Then
		OnReadCreateAtServer();
	ElsIf EventName = "ClosingOrders" And Parameter = Object.Ref Then
		ProcessOrderClosingNotification();
	EndIf;

	If EventName = "ChangedStatusDependentBankingDetails"
		And Parameter.UUID = UUID Then
		If Object.Approved Then
			Object.Approved = False;
		EndIf;
		AttachIdleHandler("Attachable_WhenChangingDetailsDependingOnStatus", 0.1, True);
	EndIf;
	
	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		
		SetAvailabilityAgreements();
		
		UpdateShippingSummary();
		
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;

	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	If EventName = "Write_PurchaseAdjustment"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Property("DocumentBasis")
		And Parameter.DocumentBasis = Object.Ref Then
		UpdateFlagThereAreAdjustments();
	EndIf;
	
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
	
	If EventName = "Recording_NotificationOfSpecialTaxRegimes" Then
		
		UpdateTextDocumentsBasedOn();
		
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

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Catalogs.TermsOfPurchaseFromVendors.AgreementIsUsedForAcceptance(Object.GoodsReceiptOption)
		And AdvancedWarehousingOnReceiving Then
		ErrorText = NStr("vi = 'Đã chọn thỏa thuận với phương án tiếp nhận như vậy, khi đó việc mua sẵm sẽ được tiến hành theo khuôn khổ thỏa thuận nói chung.
			|Tính năng tạo chứng từ với các thỏa thuận như vậy dùng để kết thúc những biến động đã bắt đầu theo thỏa thuận.
			|Không nên tạo mới chứng từ với các thỏa thuận như vậy.';
			|ru = 'Выбрано соглашение с таким вариантом приемки, при котором приобретение будет проводиться в рамках соглашения в целом.
			|Возможность создания документов с такими соглашениями оставлена для того, что бы закрыть уже начатые движения по соглашениям.
			|Создавать новые документы с такими соглашениями не рекомендуется.';
			|en = 'The selected agreement has the receiving option by which purchase will be made within the agreement. 
			|You can create documents with these agreements to close started agreement records.
			|It is not recommended that you create new documents with these agreements.'; fa = 'The selected agreement has the receiving option by which purchase will be made within the agreement. 
			|You can create documents with these agreements to close started agreement records.
			|It is not recommended that you create new documents with these agreements.';
			|it = 'È stato selezionato un accordo con una tale opzione di accettazione, in cui l''acquisizione verrà effettuata nell''ambito dell''accordo in toto.
			|La possibilità di creare documenti con tali accordi è stata lasciata al fine di chiudere i movimenti già avviati sugli accordi.
			|Non è consigliabile creare i documenti nuovi contenenti tali accordi.';
			|pl = 'Umowa została wybrana z taką opcją akceptacji, w której nabycie zostanie zatwierdzone w ramach umowy w całości. 
			|Możliwość tworzenia dokumentów z takimi umowami pozostawia się w celu zamknięcia ruchów już rozpoczętych na podstawie umów. 
			|Nie zaleca się tworzenia nowych dokumentów z takimi umowami.';
			|tr = 'Satın alma işleminin bütünüyle anlaşmanın bir parçası olarak gerçekleştirileceği kabul opsiyonlu bir anlaşma seçilmiştir. 
			|Bu tür anlaşmalarla belge oluşturma seçeneği, anlaşmalar üzerinde zaten başlatılmış olan hareketleri kapatmak için bırakılmıştır. 
			|Bu tür anlaşmalarla yeni belgeler oluşturulması önerilmez.'");
		Common.MessageToUser(ErrorText, , "Terms");
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	VendorInvoiceLocalization.FillCheckProcessingAtServer(ThisObject, Cancel, CheckedAttributes);
	
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
			
		Else
			
			FillInPurchaseOrderInLines();
			BeforeWriteAtClientServer();
			
		EndIf;
		
	EndIf;
	
	FillInPurchaseOrderInLines();
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.No Then
		
		FillInPurchaseOrderInLines();
		BeforeWriteAtClientServer();
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer()
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisForm);
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	If ValueIsFilled(RecognizedDocuments) Then
		CurrentObject.AdditionalProperties.Insert("RecognizedDocuments",
			CommonClientServer.CollapseArray(RecognizedDocuments.UnloadValues()));
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
		
	Notify("Write_VendorInvoice", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
	
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
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	UpdateVHFWarehouseObligation();
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	FillInServiceDetailsForPurposeOfVTCH();
	

	FillInPricesOfOrderProductRange();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	
	UpdateTextDocumentsBasedOn();
	
	If Object.Posted
		And Object.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
		CashServer.RevaluateFundsHeldByAccountablePersons(Object.Organization, Object.Date, Object.AdvanceHolder);
		
	EndIf;
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	UnlockFormDataForEdit();
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
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
		|RowCode,
		|ToExpenseAs");
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	If ValueIsFilled(CashierSCheckGoods) Then
		Attachable_Command_SetAvailabilityOfItemsByStatusServer(Commands.UploadCashierSChecks);
	EndIf;
	
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
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
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If CurrentPage.Name = "MainGroup3" Then
		ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AdditionalFilters = New Structure;
	If EconomicOperationsOfSeparatePurchase().Find(Object.BusinessOperation) <> Undefined Then
		AdditionalFilters.Insert("ContractsAreUsed", True);
	EndIf;
	
	PurchasesClient.StartSelectingSupplierAgreement(
		Item,
		StandardProcessing,
		Object.Partner,
		Object.Terms,
		Object.Date,
		AdditionalFilters);
	
EndProcedure

&AtClient
Procedure TermsAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If EconomicOperationsOfSeparatePurchase().Find(Object.BusinessOperation) <> Undefined Then
		DataGetParameters.Filter.Insert("ContractsAreUsed", True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		Object.Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
		PartnerClearingServer();
		Return;
	EndIf;
	
	PartnerOnChangeServer();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Item", Item);
	EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object,
		New CallbackDescription("PartnerWhenChangingQuestionEnds", ThisObject, AdditionalParameters));
	
EndProcedure

// Partner when changing the question completion.
// 
// Parameters:
//  UserAnswer - DialogReturnCode, Boolean - 
//  AdditionalParameters - Structure -
&AtClient
Procedure PartnerWhenChangingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If ValueIsFilled(Object.Terms) Then
		If Not UserAnswer = DialogReturnCode.Cancel And UserAnswer Then
			ErrorText = "";
			PricesCalculated = FillThePricesByTermsOfSalesServer(True,ErrorText);
			PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		EndIf;
		PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	EndIf;
	
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	PurchasesServer.SetContractAvailability(
		Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract();
		
		If Not (ValueIsFilled(Object.CounterpartyBankAccount) And Counterparty = Object.Counterparty) Then
			Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
		EndIf;
		
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	WhenChangingDirectionOfActivityServer();
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer();
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	Counterparty = Object.Counterparty;
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	WhenChangingKeyDetailsStatusOfEDO();
	
	OriginalViewOfCounterparty = CounterpartyLegEntInd;
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
	If OriginalViewOfCounterparty <> CounterpartyLegEntInd Then
		
		CashServerLocalization.FillInAttributeForPurchasingFromSelfEmployedPerson(ThisObject);
		OperationWithSelfEmployedWhenChangingOnServer();
		
	EndIf;
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject);
	
	If QualityControl.UpdateActionParameters(
			Documents.VendorInvoice,
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
	
	
EndProcedure

&AtClient
Procedure ShipperOnChange(Item)
	
	If ValueIsFilled(Object.Shipper) Then
		Object.ShipperBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Shipper);
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
		PurchasesServer.SetContractAvailability(
			Object,
			Items.Contract.Enabled,
			Items.Contract.Visible,
			Object.Contract);
		
	EndIf;
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		FillInTypeOfActivityVAT();
		FillInVATTaxationPurchases();
		VATTaxationOnChangeServer();
		
		CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
			Object.CompanyBankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
		
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Organization");
	ResponsiblePersonsServer.InstallManager(
		Object, PurchasesServer.DocumentBasis(Object, "ReceiptUnderOrders, PurchaseOrder, Goods.PurchaseOrder"));	
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	WhenChangingDirectionOfActivityServer();
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	Object.ExpenseReport = Undefined;
	UpdateTextAdvanceReport();
	WhenChangingKeyDetailsStatusOfEDO();
	
	RecalculateNumberOfRNPT();
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject);
	
	If QualityControl.UpdateActionParameters(
			Documents.VendorInvoice,
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
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object,
		New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure AgreementWhenChangingQuestionCompletion(UserAnswer, AdditionalParameters) Export
	
	TermsOnChangeServer(
		ValueIsFilled(Object.Terms)
		And Object.Goods.Count() > 0
		And Not UserAnswer = DialogReturnCode.Cancel
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
	
	ContractOnChangeServer(True);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
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
				QueryText = NStr("vi = 'Các dòng theo đơn hàng mà trong đó kho bãi khác với ""%Warehouse%"" sẽ bị xóa khỏi danh sách ""Hàng hóa"". Tiếp tục?';
								|ru = 'Строки по заказу, в которых склад отличается от ""%Warehouse%"" будут удалены из списка ""Товары"". Продолжить?';
								|en = 'The order lines containing a warehouse other than ""%Warehouse%"" will be deleted from the Item list. Continue?'; fa = 'The order lines containing a warehouse other than ""%Warehouse%"" will be deleted from the Item list. Continue?';
								|it = 'Le righe per un ordine nel quale il magazzino è diverso da ""%Warehouse%"" verranno cancellate dall''elenco ""Merci"". Continuare?';
								|pl = 'Wiersze zamówienia, w których magazyn różni się od ""%Warehouse%"" zostaną usunięte z listy ""Wiersze pozycji"". Kontynuować?';
								|tr = '""%Warehouse%"" dışında bir stok içeren bir sipariş satırları ""Ürünler"" listesinden kaldırılacaktır. Devam edilsin mi?'");
			EndIf;
			
			QueryText = StrReplace(QueryText, "%Warehouse%", Object.Warehouse);
			
			ShowQueryBox(New CallbackDescription("WarehouseOnChangeCompletion", ThisObject, New Structure("PreviousValueWarehouseGroup", PreviousValueWarehouseGroup)), QueryText, QuestionDialogMode.YesNo);
			
			Return;
			
		EndIf;
		
		WarehouseOnChangeServer(True);
		
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
	
	WarehouseOnChangeServer(True);

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
Procedure AdjustmentModeFromPreviousDateOnChange(Item)
	
	If AdjustmentModeFromPreviousDate And Not ValueIsFilled(Object.ActualTransactionDate) Then
		Object.ActualTransactionDate = Object.Date;
	ElsIf Not AdjustmentModeFromPreviousDate Then
		Object.ActualTransactionDate = Date(1,1,1);
	EndIf;
	
	Items.ActualTransactionDate.Enabled = AdjustmentModeFromPreviousDate;
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceCreateClick(Item)
	
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceOrderListClick(Item)
	
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceAddToDeliveryOrderClick(Item)
	
	
EndProcedure


&AtClient
Procedure MethodPlaceOfDeliveryCarrierIfChanged(Item)
	
	FillInAndSetDeliveryAttributesServer(Item.Name);
	
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
	ClearMessages();
	If Object.ReceiptUnderOrders Then
		
		If UseReceiptForMultipleOrders Then
		
			If Object.Goods.Count() = 0 Then
				QueryText = NStr("vi = 'Danh sách Hàng hóa sẽ được điền lại bằng số dư hàng hóa chưa tiếp nhận theo đơn hàng. Tiếp tục?';
								|ru = 'Список Товары будет перезаполнен остатками непоступивших товаров по заказам. Продолжить?';
								|en = 'The Item list will be repopulated with residual unreceived goods against orders. Continue?'; fa = 'The Item list will be repopulated with residual unreceived goods against orders. Continue?';
								|it = 'L''elenco Merci sarà ricompilato con rimanenze delle merci mancanti all''arrivo per gli ordini. Continuare?';
								|pl = 'Lista Wiersze pozycji zostanie ponownie wypełniona przez resztki nieodebranych towarów z zamówień. Kontynuować?';
								|tr = 'Ürünler listesi ödenmemiş sipariş bakiyeleri ile yeniden doldurulacaktır. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa sẽ được gắn với dòng của đơn hàng. Tiếp tục?';
								|ru = 'Строки в списке Товары будут привязаны к строкам заказов. Продолжить?';
								|en = 'The Item list lines will be linked with the order lines. Continue?'; fa = 'The Item list lines will be linked with the order lines. Continue?';
								|it = 'Le righe nell''elenco ""Merci"" saranno associate alle righe degli ordini. Continuare?';
								|pl = 'Wiersze na liście Wiersze pozycji będą powiązane z wierszami zamówień. Kontynuować?';
								|tr = 'Ürünler listesindeki satırlar sipariş satırlarına bağlanacaktır. Devam edilsin mi?'");
			EndIf;
			
		Else
			
			UpdateTextDocumentsBasedOn();
			
			// &PerformanceMeasurement
			PerformanceMonitorClient.StartTimeMeasurement(True,
				"Document.VendorInvoice.Form.DocumentForm.ReceiptUnderOrdersOnChange");
			
			FilterParameters = New Structure();
			FilterParameters.Insert("Currency",                    Object.Currency);
			FilterParameters.Insert("Counterparty",                Object.Counterparty);
			FilterParameters.Insert("Contract",                   Object.Contract);
			FilterParameters.Insert("VATTaxation",        Object.VATTaxation);
			FilterParameters.Insert("Organization",               Object.Organization);
			FilterParameters.Insert("Partner",                   Object.Partner);
			FilterParameters.Insert("Terms",                Object.Terms);
			FilterParameters.Insert("BusinessOperation",     Object.BusinessOperation);
			FilterParameters.Insert("PriceIncludesVAT",           Object.PriceIncludesVAT);
			FilterParameters.Insert("ARAPObjectSettings",           Object.ARAPObjectSettings);
			FilterParameters.Insert("ToReturnReusablePackage", Object.ToReturnReusablePackage);
			FilterParameters.Insert("PackageDepositIsRequired",      Object.PackageDepositIsRequired);
			FilterParameters.Insert("LineOfBusiness",   Object.LineOfBusiness);
			FilterParameters.Insert("GoodsReceiptOption",     Object.GoodsReceiptOption);
			FilterParameters.Insert("FinancialAccountingGroup",    Object.FinancialAccountingGroup);
			FilterParameters.Insert("Department",             Object.Department);
			
			FormParameters = New Structure;
			FormParameters.Insert("Filter",             FilterParameters);
			FormParameters.Insert("Warehouse",             Object.Warehouse);
			FormParameters.Insert("Recorder",       Object.Ref);
			FormParameters.Insert("HideAdditionalSelections", True);
			
			ClosingNotification_  = New CallbackDescription("ReceiptForOrdersWhenChangedAfterSelection", ThisObject);
			
			OpenForm("DataProcessor.LogOfPurchaseDocuments.Form.ReferenceChoiceForm", FormParameters, , , , ,
				ClosingNotification_, FormWindowOpeningMode.LockOwnerWindow);
			
			Return;
			
		EndIf;
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
			
			ReceiptForMultipleOrdersWhenChanging();
			Return;
			
		EndIf;
		
	EndIf;
	
	ReceiptForOrdersWhenFragmentChanges(PurchaseOrder, QueryText);
EndProcedure

&AtClient
Procedure ReceiptForOrdersWhenChangedAfterSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Object.ReceiptUnderOrders = False;
		Return;
	EndIf;
	
	PurchaseOrder = Result.PurchaseOrder;
	
	If Object.Goods.Count() = 0 Then
		QueryText = StrReplace(NStr("vi = 'Danh sách Hàng hóa sẽ được điền bằng số dư hàng hóa chưa tiếp nhận theo chứng từ %PurchaseOrder%. Tiếp tục?';
									|ru = 'Список Товары будет заполнен остатками непоступивших товаров по документу %PurchaseOrder%. Продолжить?';
									|en = 'The Item list will be populated with residual unreceived goods according to the %PurchaseOrder% document. Continue?'; fa = 'The Item list will be populated with residual unreceived goods according to the %PurchaseOrder% document. Continue?';
									|it = 'L''elenco Merci sarà compilato con rimanenze delle merci delle merci mancanti all''arrivo per il documento %PurchaseOrder%. Continuare?';
									|pl = 'Lista Wiersze pozycji zostanie wypełniona przez resztki nieodebranych towarów według dokumentu %PurchaseOrder%. Kontynuować?';
									|tr = '%PurchaseOrder% Belgesi kapsamındaki ürünler listesi ödenmemiş sipariş bakiyeleri ile doldurulacaktır. Devam edilsin mi?'"), "%PurchaseOrder%", PurchaseOrder);
	Else
		QueryText = StrReplace(NStr("vi = 'Các dòng trong danh sách Hàng hóa sẽ được gắn với dòng của chứng từ %PurchaseOrder%. Tiếp tục?';
									|ru = 'Строки в списке Товары будут привязаны к строкам документа %PurchaseOrder%. Продолжить?';
									|en = 'The Item list lines will be linked to lines of the %PurchaseOrder% document. Continue?'; fa = 'The Item list lines will be linked to lines of the %PurchaseOrder% document. Continue?';
									|it = 'Le righe nell''elenco Merci saranno collegate alle righe dell''ordine %PurchaseOrder%. Continuare?';
									|pl = 'Wiersze na liście Wiersze pozycji będą powiązane z wierszami dokumentu %PurchaseOrder%. Kontynuować?';
									|tr = 'Ürünler listesindeki satırlar, %PurchaseOrder%belgesinin satırlarına bağlanacaktır. Devam edilsin mi?'"), "%PurchaseOrder%", PurchaseOrder);
	EndIf;
	
	
	ReceiptForOrdersWhenFragmentChanges(Result, QueryText);
	
EndProcedure

&AtClient
Procedure ReceiptForOrdersWhenFragmentChanges(Val Result, Val QueryText)
	
	If TypeOf(Result) <> Type("Structure") Then
		Result = New Structure("PurchaseOrder", Result);
	EndIf;
	
	ShowQueryBox(New CallbackDescription("ReceiptUnderOrdersOnChangeCompletion", ThisObject, Result), QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ReceiptUnderOrdersOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	PurchaseOrder = AdditionalParameters.PurchaseOrder;
	
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.No Then
		Object.ReceiptUnderOrders = Not Object.ReceiptUnderOrders;
		Return;
	EndIf;
	
	If ValueIsFilled(PurchaseOrder) Then
		Object.PurchaseOrder = PurchaseOrder;
		If AdditionalParameters.Property("ARAPObjectSettings") Then
			Object.ARAPObjectSettings = AdditionalParameters.ARAPObjectSettings;
		EndIf;
	EndIf;
	ReceiptUnderOrdersOnChangeServer();
	
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesReceivedServer(Val Object)
	
	Return Documents.VendorInvoice.ParametersForRegisteringInvoicesReceived(Object);
	
EndFunction	

&AtClient
Procedure ToReturnReusablePackageOnChange(Item)
	
	ToReturnReusablePackageOnChangeServer();
	
EndProcedure

&AtClient
Procedure PackageDepositIsRequiredOnChange(Item)
	CalculateFinalRevenueFigures(ThisForm);
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	FillInSubordinatePropertiesForStatistics("Manager");
EndProcedure

&AtClient
Procedure AttributesForExpenseReportPrintingClick(Item)
	
	PrintData = New Structure;
	PrintData.Insert("AdvancePurpose",             Object.AdvancePurpose);
	PrintData.Insert("DocumentsCount",         Object.DocumentsCount);
	PrintData.Insert("SheetQuantity",             Object.SheetQuantity);
	PrintData.Insert("Director",                 Object.Director);
	PrintData.Insert("ChiefAccountant",             Object.ChiefAccountant);
	
	PrintData.Insert("Date",                         Object.Date);
	PrintData.Insert("Organization",                  Object.Organization);
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("PrintData", PrintData);
	ParametersStructure.Insert("DocumentName", "VendorInvoice");
	
	OpenForm("CommonForm.AttributesForExpenseReportPrinting", ParametersStructure, ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
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
	
	If ClosingResult.RecalculateDocumentAmounts Then
		DocumentAmountOnChangeServer(ClosingResult.DocumentAmount);
	EndIf;
	If ChangedBankingDetails.Property("Currency") Then
		DocumentCurrency = Object.Currency;
		FillInSubordinatePropertiesForStatistics("Currency");
	EndIf;
	If ChangedBankingDetails.Property("ARAPCurrency") Then
		FillInDefaultContract();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification );
	
EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm, TagName);
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
		
		If ChangedBankingDetails.Count() > 0 Then
			Object.Approved                = False;
		EndIf;
		
	EndIf;
	
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
	SetAvailabilityOfItemsByStatusServer();
	
EndProcedure

&AtClient
Procedure PurchaseForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure TextExpenseReportURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "ClearAdvanceReport" Then
		
		StandardProcessing = False;
		Object.ExpenseReport = Undefined;
		Modified = True;
		TextExpenseReport = New FormattedString(NStr("vi = 'Đưa vào giấy thanh toán tạm ứng';
													|ru = 'Включить в авансовый отчет';
													|en = 'To include in expense report'; fa = 'To include in expense report';
													|it = 'Includere nel rapporto spese';
													|pl = 'Dołączyć do raportu rozchodów';
													|tr = 'Gider raporuna ekle'"),,,, "ToIncludeInExpenseReport");
		
	ElsIf FormattedStringURL = "ToIncludeInExpenseReport" Then
		
		StandardProcessing = False;
		
		Filter = New Structure;
		Filter.Insert("Organization", Object.Organization);
		Filter.Insert("Department", Object.Department);
		Filter.Insert("AdvanceHolder", Object.AdvanceHolder);
		
		FormParameters = New Structure("Filter", Filter);
		FormParameters.Insert("Date", Object.Date);
		FormParameters.Insert("DocumentPurchases", Object.Ref);
		FormParameters.Insert("Currency", Object.Currency);
		
		Notification = New CallbackDescription("AfterSelectingAdvanceReport", ThisObject);
		
		OpenForm("Document.ExpenseReport.Form.SelectionFormOfCreation", FormParameters, ThisObject,,,, Notification);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSelectingAdvanceReport(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Object.ExpenseReport = Result;
		Modified = True;
		UpdateTextAdvanceReport();
	EndIf;
	
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
Procedure StructuralUnitOnChange(Item)
	
	FillInTypeOfActivityVAT();
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesReceivedServer(Object);
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(
		ThisForm,
		Var_URL,
		StandardProcessing,
		RegistrationParameters);

	FiscalOperationNavigationLinkProcessing(Item, Var_URL, StandardProcessing);
	
	ParametersOfDOPPInstallation = New Structure();
	ParametersOfDOPPInstallation.Insert("Organization", Object.Organization);
	ParametersOfDOPPInstallation.Insert("Basis",   Object.Ref);
	ParametersOfDOPPInstallation.Insert("Date",        Object.Date);
	
	VATAccountingERPClient.ProcessingOfNavigationLinkDOPP(ThisObject, ParametersOfDOPPInstallation, Var_URL, StandardProcessing);
	
	
EndProcedure

&AtServer
Procedure ConfigureVisibilityOfTeamFillInDivision();
	CommandVisibility = Not (EconomicOperationsOfSeparatePurchase(False, True).Find(Object.BusinessOperation) <> Undefined
					And Common.ObjectAttributeValue(Object.Contract, "PurchaseRegistrationOption", True) = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices);
	Items.GoodsFillInTheDepartment.Visible = CommandVisibility;
EndProcedure

&AtClient
Procedure OperationWithSelfEmployedPersonOnChange(Item)
	
	OperationWithSelfEmployedWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure StatusOfSelfEmployedReceiptClick(Item, StandardProcessing)

	StandardProcessing = False;
	CashClientLocalization.BeforeUploadingSelfEmployedPersonSReceiptToDocument(ThisObject);

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
	
	If Items.Goods.CurrentData <> Undefined Then
		
		ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
		ProductsClient.UpdateCachedValuesToAccountForSeries(
					Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
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

	CalculateFinalRevenueFigures(ThisForm);
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	WhenChangingWarehouseInTablePartServer();
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.Goods.CurrentData;
		
	If CurrentRow <> Undefined 
		And Object.ReceiptUnderOrders And NewRow Then 
		If Not UseReceiptForMultipleOrders Then
			CurrentRow.PurchaseOrder = Object.PurchaseOrder;
		EndIf;
		CurrentRow.OrderDiscrepancy_3 = 1;
		CurrentRow.RowCode = 0;
		CurrentRow.OrderPrice = 0;
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters, Copy);
				
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Goods");
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	FinishEditingProductsLine(Item, NewRow, CancelEdit);
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If Object.ReceiptUnderOrders Then 
		If Object.Goods.Count()>0 And CurrentRow <> Undefined Then
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
		
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"Document.VendorInvoice.Form.DocumentForm.GoodsPurchaseOrderStartChoice");
		
		FilterParameters = New Structure();
		FilterParameters.Insert("Currency",                    Object.Currency);
		FilterParameters.Insert("Counterparty",                Object.Counterparty);
		FilterParameters.Insert("Contract",                   Object.Contract);
		FilterParameters.Insert("VATTaxation",        Object.VATTaxation);
		FilterParameters.Insert("Organization",               Object.Organization);
		FilterParameters.Insert("Partner",                   Object.Partner);
		FilterParameters.Insert("Terms",                Object.Terms);
		FilterParameters.Insert("BusinessOperation",     Object.BusinessOperation);
		FilterParameters.Insert("PriceIncludesVAT",           Object.PriceIncludesVAT);
		FilterParameters.Insert("ARAPObjectSettings",           Object.ARAPObjectSettings);
		FilterParameters.Insert("ToReturnReusablePackage", Object.ToReturnReusablePackage);
		FilterParameters.Insert("PackageDepositIsRequired",      Object.PackageDepositIsRequired);
		FilterParameters.Insert("LineOfBusiness",   Object.LineOfBusiness);
		FilterParameters.Insert("GoodsReceiptOption",     Object.GoodsReceiptOption);
		FilterParameters.Insert("FinancialAccountingGroup",    Object.FinancialAccountingGroup);
		FilterParameters.Insert("Department",             Object.Department);
		FilterParameters.Insert("OperationWithSelfEmployedPerson",      Object.OperationWithSelfEmployedPerson);

		FormParameters = New Structure;
		FormParameters.Insert("Filter",             FilterParameters);
		FormParameters.Insert("Warehouse",             Object.Warehouse);
		FormParameters.Insert("Recorder",       Object.Ref);
		FormParameters.Insert("HideAdditionalSelections", True);
		
		NotificationParameters =  New Structure("CurrentData", CurrentData);
		ClosingNotification_  = New CallbackDescription("GoodsPurchaseOrderStartChoiceCompletion", ThisObject,
			NotificationParameters);
		
		OpenForm("DataProcessor.LogOfPurchaseDocuments.Form.ReferenceChoiceForm", FormParameters, , , , ,
			ClosingNotification_, FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
		
	EndIf;
	
	UpdateOrderInformation();
	
EndProcedure

&AtClient
Procedure GoodsPurchaseOrderStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.ARAPObjectSettings <> Object.ARAPObjectSettings Then
		ThereAreSpecifiedOrders = False;
		For Each RowOfProduct In Object.Goods Do 
			If ValueIsFilled(RowOfProduct.PurchaseOrder)
				And RowOfProduct.GetID() <> Items.Goods.CurrentData.GetID() Then
				ThereAreSpecifiedOrders = True;
			EndIf;
		EndDo;
		If ThereAreSpecifiedOrders Then
			MessageText = NStr("vi = 'Trong chứng từ đã chọn, trình tự hạch toán %1 khác với trình tự hạch toán của chứng từ %2.';
								|ru = 'У выбранного заказа порядок расчетов %1 отличается от порядка расчетов документа %2.';
								|en = 'The %1 payment terms of the selected order differ from the %2 payment terms of the document.'; fa = 'The %1 payment terms of the selected order differ from the %2 payment terms of the document.';
								|it = 'У выбранного заказа порядок расчетов %1 отличается от порядка расчетов документа %2.';
								|pl = 'The %1 payment terms of the selected order differ from the %2 payment terms of the document.';
								|tr = 'Seçilen emir için %1 alacak/borç muhasebesi prosedürü %2 belgesinin alacak/borç muhasebesi prosedüründen farklıdır.'");
			MessageText = StrTemplate(MessageText, Result.ARAPObjectSettings, Object.ARAPObjectSettings);
			RowIndex = Object.Goods.FindByID(Items.Goods.CurrentData.GetID()).LineNumber - 1;
			CommonClient.MessageToUser(MessageText,,"Object.Goods[" + RowIndex + "].PurchaseOrder");
			Return;
		Else
			Object.ARAPObjectSettings = Result.ARAPObjectSettings;
		EndIf;
	EndIf;
	
	CurrentData = AdditionalParameters.CurrentData;
	
	PurchaseOrder = Result.PurchaseOrder;
	
	Items.Goods.CurrentData.PurchaseOrder = PurchaseOrder;
	
	If ValueIsFilled(CurrentData.PurchaseOrder) Then
		CurrentData.SalesOpportunity = GetDealOnOrderToSupplier(CurrentData.PurchaseOrder);
	Else
		CurrentData.SalesOpportunity = PredefinedValue("Catalog.SalesOpportunitiesToCustomer.EmptyRef");
	EndIf;
	
	UpdateOrderInformation();
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	AdditionalParameters.Insert("StructureOfActions", StructureOfActions);
	StructureOfActions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True));
	
	If CurrentRow.RowCode <> 0 Then
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		SetWhetherWarehouseIsFull();
		
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
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	If AdditionalParameters.Property("ClearActionStructure") Then
		StructureOfActions = New Structure;
	Else
		StructureOfActions = AdditionalParameters.StructureOfActions;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		ItemList = New Array;
		ItemList.Add(CurrentRow.Products);
		
		If ValueIsFilled(CurrentRow.Products) And Not CheckServerItemParameters() Then
			CurrentRow.Products = Undefined; 
			Return;
		EndIf;
	EndIf;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True));
	StructureOfActions.Insert("FillInServiceDetailsForPurpose");
	
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision",
		DataToFillInWriteOFFAttributeForExpenses(Object.BusinessOperation, OptionForRegisteringServiceReceiptDocuments));
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	FillingOutAppointment = New Structure();
	If CurrentRow.Products <> ItemBeforePartnerItemChanges Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, FillingOutAppointment);
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, FillingOutAppointment, CachedValues);
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Goods");
	
	CalculateFinalRevenueFigures(ThisForm);
	
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If ValueIsFilled(CurrentRow.Products) And Not CheckServerItemParameters() Then
		CurrentRow.Products = Undefined; 
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsNomenclatureWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

// Goods nomenclature when changing the question to the user completion.
// 
// Parameters:
//  Result - Boolean -
//  AdditionalParameters - Structure -
&AtClient
Procedure GoodsNomenclatureWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = StructureOfActionsONChangesInItemList(ThisObject, CurrentRow);
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Goods");
	
	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
	CalculateFinalRevenueFigures(ThisForm);
	
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsCharacteristicWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

// Goods characteristic when changing the question to the user completion.
// 
// Parameters:
//  Result - Boolean -
//  AdditionalParameters - Structure -
&AtClient
Procedure GoodsCharacteristicWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	StructureOfActions.Insert("FillInServiceDetailsForPurpose");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,, "ToExpenseAs"));
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision",
		DataToFillInWriteOFFAttributeForExpenses(Object.BusinessOperation, OptionForRegisteringServiceReceiptDocuments));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	CurrentData.InventoryOwnerAttribute = PredefinedValue("Catalog.InventoryKinds.EmptyRef");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
		If Object.ReceiptUnderOrders And CurrentRow.RowCode > 0 Then
			StructureOfActions.Insert("RecalculateOrderPricePerPackage", CurrentRow.Count);
		EndIf;
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	UpdateOrderDeviationsInLine(CurrentRow, Object.ReceiptUnderOrders, Object.PackageDepositIsRequired);
	
	CalculateFinalRevenueFigures(ThisForm);
	
	If Object.ReceiptUnderOrders Then
		UpdateLabelForDeviationsFromOrderPrices();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalRevenueFigures(ThisForm);
	
	SpecifiedVATRate = CurrentRow.VATRate;

EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	UpdateOrderDeviationsInLine(CurrentRow, Object.ReceiptUnderOrders, Object.PackageDepositIsRequired);
	
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVendorPriceKindOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);	
	
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("RecalculateAmountOfManualDiscount_", False));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("RecalculateAmountOfManualDiscount_", False));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountForAmountInPurchases",  BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInVHFPurchases(Object, Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement")));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	UpdateOrderDeviationsInLine(CurrentRow, Object.ReceiptUnderOrders, Object.PackageDepositIsRequired);
	
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsAmountARAPOnChange(Item)
	CurrentData = Items.Goods.CurrentData;
	If CurrentData <> Undefined Then
		CurrentData.AmountVATARAP = 0;
	EndIf;
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsWarehouseWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

// Parameters:
//	Result - Boolean - result of the user's response.
//	AdditionalParameters - Structure - additional parameters for processing the result of the user's response.
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
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	
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
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

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
	ElsIf Item.CurrentItem.Name = "GoodsPartnerProducts" Then
		
		CurrentData = Items.Goods.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.GoodsPartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.GoodsPartnerProducts.ChoiceParameters, CurrentData);
		
	ElsIf Item.CurrentItem.Name = "GoodsCCDNumber" Then
		PurchasesClient.FillInListOfCCDNumberSelection(
			Items.Goods.CurrentData,
			Items.GoodsCCDNumber.ChoiceList);
	EndIf;
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
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
Procedure GoodsDimensionOfExpensesOnChange(Item)
	
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
	
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
Procedure FillThePricesByTermsOfSales(Command)

	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																								|ru = 'Товары';
																								|en = 'Goods'; fa = 'کالاها';
																								|it = 'Merci';
																								|pl = 'Wiersze pozycji';
																								|tr = 'Ürünler'")) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(,ErrorText);
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AutoTestFillInPricesByAgreement() Export

	FillThePricesByTermsOfSales(Undefined);
	
EndProcedure

&AtClient
Procedure FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPrices(Command)

	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(Object, "Goods", NStr("vi = 'Hàng hóa';
																												|ru = 'Товары';
																												|en = 'Goods'; fa = 'کالاها';
																												|it = 'Merci';
																												|pl = 'Wiersze pozycji';
																												|tr = 'Ürünler'")) Then
		
		PartnerPricesFillingClient.SelectVendorsPriceType(
			New CallbackDescription("FillInPricesOfSelectedRowsSelectionVendorPriceViewCompletion", ThisObject),
			Object.Partner,
			Object.PriceIncludesVAT);
		
	EndIf;

EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsSelectionVendorPriceViewCompletion(VendorPriceKind, AdditionalParameters) Export
	
	If ValueIsFilled(VendorPriceKind) Then
		PricesCalculated = FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(VendorPriceKind);
		PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, VendorPriceKind);
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLines(Command)

	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Goods", NStr("vi = 'Hàng hóa';
																										|ru = 'Товары';
																										|en = 'Goods'; fa = 'کالاها';
																										|it = 'Merci';
																										|pl = 'Wiersze pozycji';
																										|tr = 'Ürünler'")) Then
		Return;
	EndIf;

	AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(True);
	
	Notification = New CallbackDescription(
		"AssignAManualDiscountForSelectedLinesCompletion", 
		ThisObject, 
		New Structure("AddressInTempStorage", AddressInTempStorage));
	
	DiscountsMarkupsFillingClient.OpenFormForAssigningManualDiscounts(
		AddressInTempStorage,
		Object.Currency,
		Notification,
		True);
	
EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLinesCompletion(AmountOfManualDiscountMarkUp, AdditionalParameters) Export 
	
	AddressInTempStorage = AdditionalParameters.AddressInTempStorage;
	
	If AmountOfManualDiscountMarkUp <> Undefined Then
		
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, Items.Goods.SelectedRows, AddressInTempStorage);
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Object.Currency);
		
		CalculateFinalRevenueFigures(ThisForm);
		
	EndIf;

EndProcedure

&AtClient
Procedure CancelManualDiscounts(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToCancelManualDiscountsMarkups(Object, "Goods", NStr("vi = 'Hàng hóa';
																											|ru = 'Товары';
																											|en = 'Goods'; fa = 'کالاها';
																											|it = 'Merci';
																											|pl = 'Wiersze pozycji';
																											|tr = 'Ürünler'")) Then
		Return;
	EndIf;
	
	CancelManualDiscountsOnServer();
	DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins();
	
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.VendorInvoice.DocumentForm.Command.SelectGoods");
	
	Cancel = False;
	If Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	EconomicOperationsOfSeparatePurchase = EconomicOperationsOfSeparatePurchase();
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",        Object.Ref);
	FormParameters.Insert("Partner",         Object.Partner);
	FormParameters.Insert("Terms",      Object.Terms);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("Warehouse",      Object.Warehouse);
	FormParameters.Insert("Currency",     Object.Currency);
	FormParameters.Insert("Date",       Object.Date);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders",  True);
	
	ThisIsPurchaseOfWorksUnderProcessingContract = False;
	If ValueIsFilled(Object.Contract) Then
		ContractType = GeneralPurposeTMServerCall.ObjectAttributeValue(Object.Contract, "ContractType");
		ThisIsPurchaseOfWorksUnderProcessingContract = (ContractType = PredefinedValue("Enum.ContractTypes.TransferToTolling2_5")
												Or ContractType = PredefinedValue("Enum.ContractTypes.SubcontractingToTheEAEUCountries"));
	EndIf;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement") Then
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
		FormParameters.Insert("HideManualDiscounts", True);
	ElsIf EconomicOperationsOfSeparatePurchase.Find(Object.BusinessOperation) <> Undefined Then
		FilterByProductType = New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
		FormParameters.Insert("FilterByProductType", FilterByProductType);
	ElsIf ThisIsPurchaseOfWorksUnderProcessingContract Then 
		FilterByProductType = New FixedArray(ProductsClientServer.JobSelection(False));
		FormParameters.Insert("FilterByProductType", FilterByProductType);
	Else
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False)));
	EndIf;
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SelectGoodsByOrdersNotes(Command)
	
	AddItemsFromSalesOrderGoodsIssue();
	
EndProcedure

&AtClient
Procedure FillInThePricesForReceipts(Command)
	
	If Not ValueIsFilled(Object.Partner) Then
		Raise NStr("vi = 'Để điền đơn giá theo những lần tiếp nhận gần nhất, cần chỉ ra nhà cung cấp';
					|ru = 'Для заполнения цен по последним поступлениям необходимо указать поставщика';
					|en = 'To fill in the prices for the latest receipts, specify the vendor'; fa = 'To fill in the prices for the latest receipts, specify the vendor';
					|it = 'Per ricompilare i prezzi in base agli ultimi arrivi, è necessario specificare il fornitore';
					|pl = 'Aby wypełnić ceny za ostatnie wpływy, należy określić dostawcę';
					|tr = 'Son teslimatların fiyatlarını doldurmak için tedarikçi belirtilmelidir'");
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
				|tr = 'Fiyatlar doldurulmuştur'"),
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
		
		CalculateFinalRevenueFigures(ThisForm);
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
	
	CurrentRow = Items.Goods.CurrentData;
	ClearMessages();
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
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckPackagingByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Goods");
	
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
	
	Notification = New CallbackDescription("ChangeTheQualityOfTheItemCompletion", ThisObject);
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues, Notification);
	
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

		OpenForm("Catalog.Warehouses.ChoiceForm", ParametersStructure, ThisForm,,,, New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), FormWindowOpeningMode.LockOwnerWindow);
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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInNomenclatureAccordingToSupplierSNomenclature(Command)
	
	If Not TMCommonUseClient.CheckForRowsInList(Object.Goods, "Goods") Then
		Return;
	EndIf;
	
	GoodsAddressInStorage = PlaceGoodsInTemporaryStorageServer("Goods");
	PurchasesClient.OpenSupplierProductListForm(
		New CallbackDescription("FillInNomenclatureAccordingToSupplierSNomenclatureCompletion", ThisObject),
		GoodsAddressInStorage,
		ThisObject);
	
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
	
	If Modified
		Or Not Object.Posted Then
		
		ShowQueryBox(New CallbackDescription("CloseOrderCompletion", ThisObject),
						NStr("vi = 'Cần kết chuyển chứng từ để thực hiện giao dịch. Kết chuyển chứng từ?';
							|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
							|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
							|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
							|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
							|tr = 'Bir işlemin gerçekleştirilmesi için belgenin düzenlenmesi gerekir. Belge düzenlensin mi?'"),
						QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	CloseOrderFragment();
	
EndProcedure

&AtClient
Procedure CloseOrderCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	ElsIf Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
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
	
	CheckQuantityInTheDocumentClient();
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	ReturnParameters = Result;
	
	If ReturnParameters <> Undefined Then
		ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, ?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
		
		Modified = True;
		
		CalculateFinalRevenueFigures(ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	SetWhetherWarehouseIsFull();
	
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
		ThisForm,
		"Goods",
		"Products,Characteristic,Count,Warehouse");
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)

	EconomicImportOperations = EconomicImportOperations();
	EconomicOperationsOfSeparatePurchase = EconomicOperationsOfSeparatePurchase();
	ReceiptForSeparatePurchase = (EconomicOperationsOfSeparatePurchase.Find(Object.BusinessOperation) <> Undefined);
	BusinessOperationAdmissionToCommission = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement"));
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.FillInThePartnerSNomenclature = Object.Partner;
	ImportParameters.ImportPrices   = True;
	ImportParameters.ImportAmounts  = True;
	ImportParameters.ImportCCD    = EconomicImportOperations.Find(Object.BusinessOperation) = Undefined;
	ImportParameters.ImportDiscounts = Not BusinessOperationAdmissionToCommission;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	ImportParameters.ThisIsReusablePackage  = Object.ToReturnReusablePackage;

	If ReceiptForSeparatePurchase Then
		ImportParameters.FilterParameters.Insert("ItemsType",
			ProductsClientServer.SelectionByProductReusablePackagingService(False));
	ElsIf BusinessOperationAdmissionToCommission Then
		ImportParameters.FilterParameters.Insert("ItemsType",
			ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	EndIf;

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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
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
Procedure CalculationsClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisForm, Item, StandardProcessing);
	
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
Procedure FillInSeriesAccordingToGoodsReceiptData(Command)
	
	FillingResult = FillInSeriesBasedOnReceiptOfGoodsOnServer();
	
	ProductsClient.NotifyAboutReFillingSeries(FillingResult.HasChanges, FillingResult.NumberIsInitiallyCorrect);
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.CreditPaymentForm);
	
EndProcedure

&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

EndProcedure

&AtClient
Procedure UploadCashierSChecks(Command)
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
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure SetConditionalAppearanceForArticlesAndAnalytics()

	InvoicingOperations = New ValueList;
	InvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	InvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToExpenseAs.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExpenseItem.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFillInTheDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = InvoicingOperations;
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
		ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("OptionOfExecutionOfContractOfPurchases");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices;
		
		ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("OptionForRegisteringServiceReceiptDocuments");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced;
	
	Item.Appearance.SetParameterValue("Visible", False);

	
	// only view if the product or container or service or work and the appointment is filled
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToExpenseAs.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = InvoicingOperations;

	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
		SelectionGroupAnd1 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.ItemsTypes.OperationService;
			
		SelectionGroupAnd2 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
			ItemFilter.RightValue = ValueList;
			
			ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		
			
		SelectionGroupAnd3 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
			ItemFilter.RightValue = ValueList;
			
			ItemFilter = SelectionGroupAnd3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit"));
			ValueList.Add(PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit"));
			ValueList.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit"));
			ItemFilter.RightValue = ValueList;
				
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// explanatory inscription, if the product or container or work and the destination is filled in

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExpenseItem.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với hàng hóa và công việc chưa được chỉ định>';
													|ru = '<для товаров и работ без назначения>';
													|en = '<for goods and works without assignment>'; fa = '<for goods and works without assignment>';
													|it = '<per articoli e lavori senza assegnazione>';
													|pl = '<dla towarów i prac bez przeznaczenia>';
													|tr = '<varış yeri olmayan mallar ve işler için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

&AtServer
Function CheckServerItemParameters()
	
	Cancel = False;
	
	Documents.VendorInvoice.CheckItemTypes(Object.BusinessOperation, Object.Organization, 
		Object.Contract, Object.Goods.Unload().UnloadColumn("Products"), Cancel);
	
	Return Not Cancel;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	UseGoodsInTransitFromVendors  = GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseUninvoicedDeliveries = GetFunctionalOption("UseUninvoicedDeliveries");
	
	EconomicOperationsOfSeparatePurchase = EconomicOperationsOfSeparatePurchase(UseGoodsInTransitFromVendors, UseUninvoicedDeliveries);
	ListOfSeparatePurchaseOperations = New ValueList();
	ListOfSeparatePurchaseOperations.LoadValues(EconomicOperationsOfSeparatePurchase);

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
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OperationService;
	
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

	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisForm);

	//

	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);

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
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
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

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountARAP.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.ARAPCurrency");

	Item.Appearance.SetParameterValue("Visible", False);

	//
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfInputFieldCountryOfOrigin = "GoodsCCDNumberOriginCountry";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceInDocumentPurchaseOfGoodsServices(ThisObject);

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

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfSeparatePurchaseOperations;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPObjectSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ARAPObjectSettings.ByCounterpartyContracts;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ListOfSeparatePurchaseOperations;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPObjectSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ARAPObjectSettings.ByCounterpartyContracts;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "GoodsWarehouse", "Object.Goods.Warehouse", "Object.Goods.WarehouseIsRequired");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");

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
	ItemFilter.LeftValue = New DataCompositionField("RightToReadOrdersToSupplier");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

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

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);
	
	EconomicImportOperations = EconomicImportOperations();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = EconomicImportOperations;

	Item.Appearance.SetParameterValue("Visible", False);

	//
	
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisForm;
	InstallationParameters.ThisIsAdmission        = True;
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsInventoryOwnerAttribute.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<mallar için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, False);

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);

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
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	
	
	SetConditionalAppearanceForArticlesAndAnalytics();
	
	// explanatory inscription for the division, if the warehouses are not in the tabular part

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WarehouseGroup_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<khi ghi giảm vào chi phí>';
													|ru = '<при списании на расходы>';
													|en = '<when writing off as expenses>'; fa = '<when writing off as expenses>';
													|it = '<durante lo storno sulle spese>';
													|pl = '<przy wyksięgowaniu na rozchody>';
													|tr = '<gider yazılması>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		
	// we do not fill out the Division if the position is purchased under the principal
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AssignmentType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.AssignmentTypes.DeliveryForPrincipal");

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với mua hàng không theo chi nhánh>';
													|ru = '<для закупки не под принципала>';
													|en = '<for purchasing not for principal>'; fa = '<for purchasing not for principal>';
													|it = '<для закупки не под принципала>';
													|pl = '<for purchasing not for principal>';
													|tr = '<müvekkil kapsamında olmayan satın almalar için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// Warehouse and division clearance
	// disabling warehouse visibility if work or service or goods are written off for expenses

	InvoicingOperations = New ValueList;
	InvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	InvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = InvoicingOperations;
	
	FilterGroup0 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup0.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

		ItemFilter = FilterGroup0.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ValueList = New ValueList;
		ValueList.Add(Enums.ItemsTypes.Work_5);
		ValueList.Add(Enums.ItemsTypes.OperationService);
		ItemFilter.RightValue = ValueList;
		
		ItemFilter = FilterGroup0.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;

	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = InvoicingOperations;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WarehouseGroup_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// disabling the visibility of the division if the goods or containers or commission operation, and the goods are not charged for expenses.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ProductsServer.ListOfBusinessOperationsExcludingServicesAndWorks();

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

		ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ValueList = New ValueList;
		ValueList.Add(Enums.ItemsTypes.OwnGoods);
		ValueList.Add(Enums.ItemsTypes.ReusablePackage);
		ItemFilter.RightValue = ValueList;
	
		ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("WarehouseGroup_");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Removing the mark of an unfilled division, if the Goods or Work on agency procurement, and the goods are not written off for expenses

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	FilterGroup0 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup0.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
		FilterGroup1 = FilterGroup0.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Department");
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			
				FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
				FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				
					ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
					ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
					ValueList = New ValueList;
					ValueList.Add(Enums.ItemsTypes.OwnGoods);
					ValueList.Add(Enums.ItemsTypes.ReusablePackage);
					ItemFilter.RightValue = ValueList;
					
					ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
					ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
					ItemFilter.RightValue = True;

				FilterGroup4 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
				FilterGroup4.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				
					ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
					ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
					ValueList = New ValueList;
					ValueList.Add(Enums.ItemsTypes.OperationService);
					ValueList.Add(Enums.ItemsTypes.Work_5);
					ItemFilter.RightValue = ValueList;
					
					ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
					ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

				FilterGroup5 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
				FilterGroup5.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				
					ItemFilter = FilterGroup5.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
					ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
					ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
					
					ItemFilter = FilterGroup5.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AssignmentType");
					ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
					ItemFilter.RightValue = Enums.AssignmentTypes.DeliveryForPrincipal;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// setting the mark of an unfilled division, if the Product

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Department");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
			FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
				ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
				ValueList = New ValueList;
				ValueList.Add(Enums.ItemsTypes.OwnGoods);
				ValueList.Add(Enums.ItemsTypes.ReusablePackage);
				ItemFilter.RightValue = ValueList;
				
				ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = True;

			FilterGroup4 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup4.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
				ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
				ValueList = New ValueList;
				ValueList.Add(Enums.ItemsTypes.OperationService);
				ValueList.Add(Enums.ItemsTypes.Work_5);
				ItemFilter.RightValue = ValueList;
				
				ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
				ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

			FilterGroup5 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup5.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
				ItemFilter = FilterGroup5.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
				
				ItemFilter = FilterGroup5.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AssignmentType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
				ItemFilter.RightValue = Enums.AssignmentTypes.DeliveryForPrincipal;
		
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// only view totals if Betcands = BezNDS or NDS0%

	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisForm);
	
	// only view the Destination if the string code is full

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	// Visibility of the details of the incoming document
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsIncomingDocumentNumber.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsIncomingDocumentDate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExternalDocumentName.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.PurchaseViaAdvanceHolder;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Counterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("StartDateOfPrintingSingleExpenseReport");
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Partner.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Counterparty.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.PurchaseViaAdvanceHolder;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	ItemsTypes = Enums.ItemsTypes;
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ToExpenseAs", True);
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ItemsType", ItemsTypes.Work_5);
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ItemsType", ItemsTypes.OperationService);
	QualityControl.AddFilter(FlagDisabled, "Object.BusinessOperation",
		Enums.BusinessTransactions.PurchaseFromVendorLocal);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure PartnerOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;

	DocumentPurchases = FormAttributeToValue("Object");
	DocumentPurchases.FillInDefaultPurchaseConditions(False);
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, DocumentPurchases);
	DocumentBasis = PurchasesServer.DocumentBasis(DocumentPurchases, "ReceiptUnderOrders, PurchaseOrder, Goods.PurchaseOrder");
	ResponsiblePersonsServer.InstallManager(DocumentPurchases, DocumentBasis);
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
	If Contract <> Object.Contract Then
		ContractOnChangeServer();
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	WarehouseOnChangeServer();
	BusinessOperationOnChangeServer(False);
	ToReturnReusablePackageOnChangeServer();
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	FillInServiceDetailsForPurposeOfVTCH();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalRevenueFigures(ThisForm);
	UpdateTextDocumentsBasedOn();
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	CounterpartyOnChangeServer();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;

	FillInAndSetDeliveryAttributesServer("Partner");
	WhenChangingDirectionOfActivityServer();
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	If QualityControl.UpdateActionParameters(
			Documents.VendorInvoice,
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
	DocumentBasis = PurchasesServer.DocumentBasis(Object, "ReceiptUnderOrders, PurchaseOrder, Goods.PurchaseOrder");
	ResponsiblePersonsServer.InstallManager(Object, DocumentBasis);
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer(RecalculatePrices_2=True)
	
	DirectionsOfActivity = Object.LineOfBusiness;
	PriceIncludesVAT = Object.PriceIncludesVAT;
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	OldWarehouse = Object.Warehouse;
	If ValueIsFilled(Object.Terms) Then
		
		DocumentPurchases = FormAttributeToValue("Object");
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(DocumentPurchases.Terms, True, True);
		DocumentPurchases.FillInTermsOfPurchase(PurchaseConditions);
		ValueToFormAttribute(DocumentPurchases, "Object");
		
		If Contract <> Object.Contract Then
			ContractOnChangeServer();
		EndIf;
		
		If ValueIsFilled(Object.Organization) Then
			CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
				Object.CompanyBankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
		EndIf;
		
		DocumentCurrency = Object.Currency;
		
		AttributesArray = New Array;
		AttributesArray.Add("Currency");
		AttributesArray.Add("ARAPCurrency");
		AttributesArray.Add("Partner");
		AttributesArray.Add("LineOfBusiness");
		AttributesArray.Add("Organization");
		AttributesArray.Add("Terms");
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
		
		If RecalculatePrices_2 Then
			StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
			
			PriceFillingParameters_ = PartnerPricesFillingServer.NewFillOptionsFillPrices();
			PriceFillingParameters_.Insert("PopulationFields", "Price, VATRate, VendorPriceKind");
			PriceFillingParameters_.Insert("Date", Object.Date);
			PriceFillingParameters_.Insert("Organization", Object.Organization);
			PriceFillingParameters_.Insert("Currency", Object.Currency);
			PriceFillingParameters_.Insert("Terms", Object.Terms);
			PriceFillingParameters_.Insert("VATTaxation", Object.VATTaxation);
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
			StructureOfActions.Insert("ClearAmountOfSettlements", Undefined);
			StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
			
			PartnerPricesFillingServer.FillInPrices(
				Object.Goods,
				Undefined, // Array of strings
				PriceFillingParameters_,
				StructureOfActions);
			
		ElsIf PriceIncludesVAT <> Object.PriceIncludesVAT Then
			
			StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("ClearAmountOfSettlements");
			
			BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
			
		EndIf;
		
		If Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
			And UseDiscountAdjustmentsInPurchases Then
			PurchasesServer.CancelManualDiscounts(Object, "Goods", True);
		EndIf;
		
		WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
		WarehouseOnChangeServer();
		BusinessOperationOnChangeServer(False);
		ToReturnReusablePackageOnChangeServer();
		UpdateAvailabilityOfReturnContainerItems(ThisForm);
		
		StructureOfNamesOfTableParts = New Structure("Goods");
		FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
		PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
		ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
		TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
		
		If Object.ReceiptUnderOrders Then
			UpdateOrderDeviations();
		EndIf;
		CalculateFinalRevenueFigures(ThisForm);
		
		UpdateTextDocumentsBasedOn();
		
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, PurchasesServer.DocumentBasis(Object, "ReceiptUnderOrders, PurchaseOrder, Goods.PurchaseOrder"));
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	WhenChangingDirectionOfActivityServer();
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object, Object.ReceiptUnderOrders,,SummaryDeliveryInformation);
	
	ReferenceOrder = OrderToReceiveOptionOfAcceptanceOfGoods();
	Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder, Object.Contract);
	Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
	
	If OldWarehouse <> Object.Warehouse
		Or QualityControl.UpdateActionParameters(
			Documents.VendorInvoice,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer(DirectModificationOfContractField = False)
	
	DirectionsOfActivity = Object.LineOfBusiness;
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	If Contract <> Object.Contract Then
		ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer();
	
	FillInTypeOfActivityVAT();
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
		Object.CounterpartyBankAccount);

	If Not ValueIsFilled(Object.CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = LocalAccountingCurrency;
		Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
			ParametersOfAccount);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Contract");
	WhenChangingDirectionOfActivityServer();
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		ReferenceOrder = OrderToReceiveOptionOfAcceptanceOfGoods();
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder, Object.Contract);
		Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
	EndIf;
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object, Object.ReceiptUnderOrders,,SummaryDeliveryInformation);
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, PurchasesServer.DocumentBasis(Object, "ReceiptUnderOrders, PurchaseOrder, Goods.PurchaseOrder"));
	
	SetProductSelectionParameters();
	
	OptionOfExecutionOfContractOfPurchases = PurchasesServer.GetVariantOfProcurementContract(Object.Contract);
	OptionForRegisteringServiceReceiptDocuments = PurchasesServer.GetVariantOfRegistrationOfDocumentsForAdmissionToServices(Object.Contract);
	
	SetUpWriteOffColumnsForExpensesTSProducts();
	
	ConfigureVisibilityOfTeamFillInDivision();
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject);
	
	If QualityControl.UpdateActionParameters(
			Documents.VendorInvoice,
			Object,
			CacheQualityControl,
			DirectModificationOfContractField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
		Or Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
		UntieLinesFromOrdersToSuppliers();
		LinkReceiptLinesToOrdersToSuppliers(Not UseReceiptForMultipleOrders);	
	EndIf;
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	RecalculationParameters = PriceManagementSystem.ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(Object.PriceIncludesVAT, DocumentAmount);
	RecalculationParameters.RecalculateAutomaticDiscounts = False;
	RecalculationParameters.RecalculateManualDiscounts         = True;
	
	PriceManagementSystem.RecalculateTableAmountsONChangeOfExchangeRate(
		Object.Goods,
		RecalculationParameters);
	
	If Object.ReceiptUnderOrders Then
		FillInPricesOfOrderProductRange();
	EndIf;
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalRevenueFigures(ThisForm);
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer(ChallengeByCommand = True)
	
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServerCall.BusinessOperationsOnMain(
		PredefinedValue("Enum.BusinessTransactions.ImportFromEAEU"));
	
	BusinessTransactionsImportPurchase = PurchasesServerCall.BusinessOperationsOnMain(
		PredefinedValue("Enum.BusinessTransactions.PurchaseByImport"));
	
	EconomicOperationOfContractIsNew = GetBusinessTransaction(Object.BusinessOperation);
	If EconomicOperationOfContractIsNew <> ContractBusinessTransaction Then
		Object.Contract = Undefined;
		ContractBusinessTransaction = EconomicOperationOfContractIsNew;
	EndIf;
	
	If ChallengeByCommand Then
		FillInDefaultContract();
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		
		Object.ToReturnReusablePackage = False;
		Object.ReusablePackagesReturnDate = Undefined;
		ToReturnReusablePackageOnChangeServer();
		
		If UseDiscountAdjustmentsInPurchases Then
			PurchasesServer.CancelManualDiscounts(Object,"Goods", True);
			TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal Then
		
		Object.ReceiptUnderOrders = False;
		ReceiptForMultipleOrdersWhenChanging();

		Object.ToReturnReusablePackage = False;
		ToReturnReusablePackageOnChangeServer();
		
	ElsIf BusinessTransactionsImportPurchase.Find(Object.BusinessOperation) <> Undefined
		Or BusinessTransactionsProcurementInEAEUCountries.Find(Object.BusinessOperation) <> Undefined Then
		
		Object.ToReturnReusablePackage = False;
		ToReturnReusablePackageOnChangeServer();
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
		Object.ReceiptUnderOrders = False;
		Object.PurchaseOrder = Undefined;
		Object.Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
		UntieLinesFromOrdersToSuppliers();
		OrderList.Clear();
		SetVisibilityOfCommandsByOrder();
		UpdateDependentDetailsOfServerByOrderForm();
		UpdateOrderInformation();
		
	EndIf;
	
	ReceiptForSeparatePurchase =
		EconomicOperationsOfSeparatePurchase().Find(Object.BusinessOperation) <> Undefined;
	Items.GoodsFillInSeriesAccordingToGoodsReceiptData.Enabled = ReceiptForSeparatePurchase;
	
	If ReceiptForSeparatePurchase
		And ValueIsFilled(Object.Terms) Then

		ContractsAreUsed = Common.ObjectAttributeValue(Object.Terms,
			"ContractsAreUsed");
		If ContractsAreUsed <> Undefined And Not ContractsAreUsed Then
			Object.Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
		EndIf;

	EndIf;
	
	EstablishVisibilityOfRNPTQuantity();
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	SetVisibilityOfElementsByOperationServer();
	SetStockTypeSelectionParameters();
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalRevenueFigures(ThisForm);
	
	SetAvailabilityAgreements();
	
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
	PrepareFillSetSeriesVisibility();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer();
	
	FillInTypeOfActivityVAT();
	
	UpdateTextDocumentsBasedOn();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	FormEvents.WhenChangingElement(ThisObject, "BusinessOperation");
	
	SetUpWriteOffColumnsForExpensesTSProducts();
	
	ConfigureVisibilityOfTeamFillInDivision();
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	CashServerLocalization.FillInAttributeForPurchasingFromSelfEmployedPerson(ThisObject);
	OperationWithSelfEmployedWhenChangingOnServer();
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject);
	
	If QualityControl.UpdateActionParameters(
			Documents.VendorInvoice,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	SetVisibilityOfActualDateOfOperation();
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(DirectEditingOfWarehouseField = False)
	
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
			
			WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True, "ToExpenseAs");
			
			For Each CurRow In Object.Goods Do
				
				If (CurRow.ItemsType = Enums.ItemsTypes.OwnGoods
						Or CurRow.ItemsType = Enums.ItemsTypes.ReusablePackage)
					And ValueIsFilled(CurRow.RowCode)
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
					And (CurRow.ItemsType = Enums.ItemsTypes.OwnGoods 
						Or CurRow.ItemsType = Enums.ItemsTypes.ReusablePackage)
					And Object.Warehouse <> CurRow.Warehouse Then
					ArrayOfRowsToDelete_1.Add(CurRow);
				EndIf;
				
			EndDo;
			
		EndIf;
		
		For Each CurItem In ArrayOfRowsToDelete_1 Do
			Object.Goods.Delete(CurItem);
		EndDo;
		
	EndIf;
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True, "ToExpenseAs");
	
	RecalculateNumberOfRNPT();
	
	UpdateOrderInformation();
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	WhenChangingWarehouseInTablePartServer();
	CalculateFinalRevenueFigures(ThisForm);
	
	PrepareFillSetSeriesVisibility();
	
	FillInTypeOfActivityVAT();
	
	If Not WarehouseGroup_ Then
		Items.ProductsGroupRecipient.Title = NStr("vi = 'Bộ phận-nơi nhận';
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
	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
	SetTitleFillInByOrdersOrders();
	
	If QualityControl.UpdateActionParameters(
			Documents.VendorInvoice,
			Object,
			CacheQualityControl,
			DirectEditingOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	FlagChanged = VATAccountingLocalization.SetPriceIncludesVATOnVATTaxation(Object.PriceIncludesVAT, Object.VATTaxation);
	If FlagChanged Then
		For Each RowOfGoods In Object.Goods Do
			RowOfGoods.VendorPriceKind = Undefined;
		EndDo;
	EndIf;
	VATAccountingLocalization.SetAvailabilityPriceIncludesVATOnVATTaxation(Items.PriceIncludesVAT, Object.VATTaxation);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfFillingInVATRate = 
	BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, False, Object.ToReturnReusablePackage);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
			
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalRevenueFigures(ThisForm);
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisForm);
	
	UpdateTextDocumentsBasedOn();
	
	SetSupplierCommitment();

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalRevenueFigures(ThisForm);
	
	
EndProcedure

&AtServer
Procedure ReceiptForMultipleOrdersWhenChanging()
	
	If Object.ReceiptUnderOrders Then
		
		If Not UseReceiptForMultipleOrders 
			And ValueIsFilled(Object.PurchaseOrder) Then
			
			TermsFromOrder = Common.ObjectAttributeValue(Object.PurchaseOrder, "Terms");
			If TermsFromOrder <> Object.Terms 
				And ValueIsFilled(TermsFromOrder) Then
				
				Object.Terms = TermsFromOrder;
				TermsOnChangeServer();
				
			EndIf;
			FillPropertyValues(Object,
				Object.PurchaseOrder,
				"Currency, Counterparty, Contract, VATTaxation, Organization, Partner, BusinessOperation, 
				|GoodsReceiptOption, PriceIncludesVAT, ToReturnReusablePackage");
		EndIf;
		
		If Object.Goods.Count() = 0 Then
			FillInFromOrderServer();
		Else
			LinkReceiptLinesToOrdersToSuppliers(Not UseReceiptForMultipleOrders);
		EndIf;
		
	Else
		
		UntieLinesFromOrdersToSuppliers();
		OrderList.Clear();
		Object.PurchaseOrder = Undefined;
		ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	EndIf;
	
	SetVisibilityOfElementsByOperationServer();
	SetAvailabilityAgreements();
	SetStockTypeSelectionParameters();
	SetVisibilityOfCommandsByOrder();
	FillInPricesOfOrderProductRange();
	UpdateOrderInformation();
	UpdateTextDocumentsBasedOn();
	SetAvailabilityOfItemsByStatusServer();
	GoodsDelivery.WhenChangingFlagForOrders(Items, Object, Object.ReceiptUnderOrders);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	AttributesArray = New Array;
	AttributesArray.Add("ReceiptUnderOrders");
	AttributesArray.Add("ARAPObjectSettings");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	ResponsiblePersonsServer.InstallManager(
		Object, PurchasesServer.DocumentBasis(Object, "ReceiptUnderOrders, PurchaseOrder, Goods.PurchaseOrder"));
	
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
	
	FillInTypeOfActivityVAT();
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfFillingInVATRate = 
	BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, False, Object.ToReturnReusablePackage);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
			
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm,"Date");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	PrepareFillSetSeriesVisibility();
	SetTitleFillInByOrdersOrders();
	DefinePrintingSingleAdvanceReport();
	SetVisibilityOfDetailsPrintAdvanceReport();
	EstablishVisibilityOfRNPTQuantity();
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.VendorInvoice,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalRevenueFigures(ThisForm);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		FillInDefaultContract();
	EndIf;
	
	WhenChangingDirectionOfActivityServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	
EndProcedure

&AtServer
Procedure WhenChangingDirectionOfActivityServer()
	
	ModifiedRows = LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	PurchasesServer.ClearDetailsOfChargeForExpensesWhenSettingDestinationInTablePart(ModifiedRows);
	
EndProcedure

&AtServer
Procedure OperationWithSelfEmployedWhenChangingOnServer()
	
	FillInDefaultContract();
	CashServerLocalization.OperationWithSelfEmployedPersonOnChange(ThisObject);
	VATTaxationOnChangeServer();
	
EndProcedure

#EndRegion

#Region PricingAndDiscounts

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
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	RecalculateAmountTakingIntoAccountManualDiscount = New Structure("Clear", False);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
	StructureOfActions.Insert("ClearAmountOfSettlements", Undefined);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", RecalculateAmountTakingIntoAccountManualDiscount);
	
	PriceFillingParameters_ = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	PriceFillingParameters_.Insert("PopulationFields", "Price, VendorPriceKind");
	PriceFillingParameters_.Insert("Date", Object.Date);
	PriceFillingParameters_.Insert("Organization", Object.Organization);
	PriceFillingParameters_.Insert("Currency", Object.Currency);
	PriceFillingParameters_.Insert("Terms", Object.Terms);
	PriceFillingParameters_.Insert("VATTaxation", Object.VATTaxation);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray, // Array of strings
		PriceFillingParameters_,
		StructureOfActions);
	If Object.ReceiptUnderOrders Then
		UpdateOrderDeviations();
	EndIf;
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalRevenueFigures(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(VendorPriceKind)
	
	RowsArray = New Array;
	For Each String In Items.Goods.SelectedRows Do
		TableRow = Object.Goods.FindByID(String);
		If TableRow.RowCode = 0 Then
			RowsArray.Add(TableRow);
		EndIf;
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	PriceFillingParameters_ = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	PriceFillingParameters_.Insert("PopulationFields", "Price, VendorPriceKind");
	PriceFillingParameters_.Insert("Date", Object.Date);
	PriceFillingParameters_.Insert("Organization", Object.Organization);
	PriceFillingParameters_.Insert("Currency", Object.Currency);
	PriceFillingParameters_.Insert("VendorPriceKind", VendorPriceKind);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
	StructureOfActions.Insert("ClearAmountOfSettlements", Undefined);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray,
		PriceFillingParameters_,
		StructureOfActions);
		
	If Object.ReceiptUnderOrders Then
		UpdateOrderDeviations();
	EndIf;
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalRevenueFigures(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure AssignManualDiscountOnServer(AmountOfDiscountMarkUp, Val SelectedRows, AddressInTempStorage)
	
	DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
	DiscountParameters.AutomaticDiscountsAreUsed = False;
	DiscountParameters.CalculateAmountWithVAT			 = True;
	DiscountParameters.CalculateAmountOfSettlements_1	 = True;
	DiscountParameters.SelectedRows				 = SelectedRows;
	DiscountParameters.AddressInTempStorage		 = AddressInTempStorage;
	
	DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "Goods", AmountOfDiscountMarkUp, DiscountParameters);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
EndProcedure

&AtServer
Procedure CancelManualDiscountsOnServer()
	
	DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "Goods", False, True, True);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
EndProcedure

&AtServer
Procedure FillInPricesOfOrderProductRange()
	
	If Not RightToReadOrdersToSupplier Then
		Return;
	EndIf;
	
	If Not Object.ReceiptUnderOrders Then
		For Each CurRow In Object.Goods Do
			CurRow.OrderPrice = 0;
			UpdateOrderDeviationsInLine(CurRow, Object.ReceiptUnderOrders, Object.PackageDepositIsRequired);
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
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.RowCode <> 0
	|;
	|SELECT
	|	GoodsFromOrder.Ref    AS PurchaseOrder,
	|	GoodsFromOrder.Ref.Date AS OrderDate,
	|	GoodsFromOrder.Ref.Currency AS OrderCurrency,
	|	GoodsFromOrder.RowCode AS RowCode,
	|	(GoodsFromOrder.Price/ISNULL(&QueryTextPackagingFactor1,1))*ISNULL(&QueryTextPackagingFactor2, 1) AS OrderPrice,
	|	GoodsFromOrder.Package  AS OrderPackage
	|FROM
	|	Goods AS Goods
	|LEFT JOIN
	|	Document.PurchaseOrder.Goods AS GoodsFromOrder
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
	QueryResult = QueryResultsArray[1]; // QueryResult
	Selection = QueryResult.Select();
	
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	For Each CurRow In Object.Goods Do
		If ValueIsFilled(CurRow.RowCode) Then
			Selection.Reset();
			FilterStructure1 = New Structure("PurchaseOrder,RowCode", CurRow.PurchaseOrder, CurRow.RowCode);
			If Selection.FindNext(FilterStructure1) Then
				If Selection.OrderCurrency = Object.Currency Then
					CurRow.OrderPrice = Selection.OrderPrice;
				ElsIf Selection.OrderCurrency = Object.ARAPCurrency Then
					If Object.Currency = BaseCurrency Then
						CurRow.OrderPrice = Selection.OrderPrice * Object.CourseNumerator / Object.CourseDenominator;
					Else
						CurRow.OrderPrice = Selection.OrderPrice / Object.CourseNumerator * Object.CourseDenominator;
					EndIf;
				Else
					CurRow.OrderPrice = ProcessingOfExchangeRatesTM.ConvertToCurrency(Selection.OrderPrice,
							BaseCurrency,
							Selection.OrderCurrency,
							Object.Currency,
							Object.Date);
				EndIf;
			EndIf;
		Else
			CurRow.OrderPrice = 0;
		EndIf;
		UpdateOrderDeviationsInLine(CurRow, Object.ReceiptUnderOrders, Object.PackageDepositIsRequired);
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
	Query.SetParameter("Partner", Object.Partner);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
		
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	RowsToProcess = New Array();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		TSRow = Object.Goods[Selection.LineNumber - 1];
		FillPropertyValues(TSRow, Selection, "Price, VendorPriceKind");
		RowsToProcess.Add(TSRow);
		
		PricesAreFilledOut = True;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	If Object.ReceiptUnderOrders Then
		UpdateOrderDeviations();
	EndIf;
	
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure CheckQuantityInTheDocumentClient()
	
	OnlyNonLabeledProductsHaveBeenUnloaded = False;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",             PutTablePartOfGoodsInTemporaryStorageToCheckQuantity(OnlyNonLabeledProductsHaveBeenUnloaded));
	OpeningParameters.Insert("TabularSectionName",                     "Goods");
	OpeningParameters.Insert("Ref",                                Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed",  True);
	OpeningParameters.Insert("SeriesSpecificationParameters",                SeriesSpecificationParameters);
	OpeningParameters.Insert("Terms",                            Object.Terms);
	OpeningParameters.Insert("ReceiptUnderOrders",                  Object.ReceiptUnderOrders);
	OpeningParameters.Insert("OnlyNonLabeledProductsHaveBeenUnloaded", OnlyNonLabeledProductsHaveBeenUnloaded);
	OpeningParameters.Insert("Warehouse",                                 Object.Warehouse);
	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters,,,,, New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddItemsFromSalesOrderGoodsIssue()
	
	Try
		LockFormDataForEdit();
		Modified = True;
	Except
		ShowMessageBox(,BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ArrayOfStringCodes = New Array;
	AddressOfGoods = "";
	BusinessTransaction_Selection = Object.BusinessOperation;
	
	BeforeSelectingProductsFromOrder(ArrayOfStringCodes, AddressOfGoods, BusinessTransaction_Selection);
	
	PickingParameters = New Structure();
	PickingParameters.Insert("BusinessOperation", BusinessTransaction_Selection);
	PickingParameters.Insert("PurchaseOrder", Object.PurchaseOrder);
	PickingParameters.Insert("DocumentCurrency", Object.Currency);
	PickingParameters.Insert("Ref", Object.Ref);
	PickingParameters.Insert("Date", Object.Date);
	PickingParameters.Insert("Warehouse", Object.Warehouse);
	PickingParameters.Insert("ArrayOfStringCodes", ArrayOfStringCodes);
	PickingParameters.Insert("Partner", Object.Partner);
	PickingParameters.Insert("Counterparty", Object.Counterparty);
	PickingParameters.Insert("Contract", Object.Contract);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Terms", Object.Terms);
	PickingParameters.Insert("ARAPCurrency", Object.ARAPCurrency);
	PickingParameters.Insert("VATTaxation", Object.VATTaxation);
	PickingParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	PickingParameters.Insert("ARAPObjectSettings", Object.ARAPObjectSettings);
	PickingParameters.Insert("ToReturnReusablePackage", Object.ToReturnReusablePackage);
	PickingParameters.Insert("PackageDepositIsRequired", Object.PackageDepositIsRequired);
	PickingParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	PickingParameters.Insert("AddressGoodsReceiptGoodsInTheTemporaryStorage", AddressOfGoods);
	PickingParameters.Insert("AdvancedWarehousingOnReceiving", AdvancedWarehousingOnReceiving);
	PickingParameters.Insert("ReceiptUnderOrders", Object.ReceiptUnderOrders);
	PickingParameters.Insert("GoodsReceiptOption", Object.GoodsReceiptOption);
	PickingParameters.Insert("Department", Object.Department);
	PickingParameters.Insert("FinancialAccountingGroup", Object.FinancialAccountingGroup);
	PickingParameters.Insert("OperationWithSelfEmployedPerson", Object.OperationWithSelfEmployedPerson);
	PickingParameters.Insert("OnlyWorksServices", Not BusinessTransaction_Selection = Object.BusinessOperation);
	
	OpenForm(
		"DataProcessor.LogOfPurchaseDocuments.Form.SelectionOfGoodsFromOrderForm",
		PickingParameters,
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure BeforeSelectingProductsFromOrder(ArrayOfStringCodes, AddressOfGoods, BusinessTransaction_Selection)
	
	For Each TSRow In Object.Goods Do
		
		If TSRow.RowCode <> 0 And ValueIsFilled(TSRow.PurchaseOrder) Then
			ArrayOfStringCodes.Add(New Structure("RowCode,PurchaseOrder", TSRow.RowCode, TSRow.PurchaseOrder));
		EndIf;
		
	EndDo;
	
	AddressOfGoods = PutToTempStorage(Object.Goods.Unload());
	
	PurchaseOrderIsBT = Common.ObjectAttributeValue(Object.PurchaseOrder, "BusinessOperation");
	
	If PurchaseOrderIsBT = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt 
		And Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
		OptionForRegisteringServiceReceiptDocuments = Common.ObjectAttributeValue(Object.Contract, "OptionForRegisteringServiceReceiptDocuments");
		
		If OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed Then
			BusinessTransaction_Selection = PurchaseOrderIsBT;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If Not ValueIsFilled(Object.Currency) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Tiền tệ""';
										|ru = 'Поле ""Валюта"" не заполнено';
										|en = '""Currency"" is required'; fa = '""Currency"" is required';
										|it = 'Il campo ""Valuta"" non è compilato';
										|pl = 'Pole ""Waluta"" nie jest wypełnione';
										|tr = '""Para Birimi"" alanı doldurulmadı'"),
													Object.Ref,
													"Object.Currency",
													,
													Cancel);
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
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	
	If Result <> Undefined Then
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
	StructureOfActionsWithAddedStrings.Insert("FillInCountryOfOriginOfProduct",
													BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActionsWithAddedStrings.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, ThisObject);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithAddedStrings.Insert("FillInServiceDetailsForPurpose");
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, ThisObject);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.AddOnlyProductsOverAndAboveOrder        = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	CalculateFinalRevenueFigures(ThisObject);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	ItemsTypes = ProductsServer.AcceptableItemTypesToChooseFrom(Object.BusinessOperation);
	
	ThereAreWorks = ItemsTypes.Find(Enums.ItemsTypes.Work_5) <> Undefined;
	ThereAreServices = ItemsTypes.Find(Enums.ItemsTypes.OperationService) <> Undefined;
	
	StructureOfActionParameters.GoodsOnly = Not (ThereAreWorks
												Or ThereAreServices);
	StructureOfActionParameters.OnlyGoodsAndWork = ThereAreWorks
														And Not ThereAreServices;
	StructureOfActionParameters.OnlyGoodsAndServices = ThereAreServices
														And Not ThereAreWorks;
	
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
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,StructureOfActions);
	CalculateFinalRevenueFigures(ThisForm);

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
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.VendorInvoice));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtServer
Function FillInSeriesBasedOnReceiptOfGoodsOnServer()
	
	GoodsTable = Object.Goods.Unload();
	
	ResultOfFillingInSeries = ProductsServer.FillOutSeriesBasedOnProductDataFromPartners(GoodsTable, Object, True);
	
	If ResultOfFillingInSeries.HasChanges Then
		StructureOfActions = New Structure();
		StructureOfActions.Insert(
			"RecalculateNumberOfPackages",
			BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions,
			"Warehouse",
			True);
		
		BatchProcessingOfTablePartServer.TreatTS(GoodsTable, StructureOfActions, Undefined);
		
		Object.Goods.Load(GoodsTable);
		
		ProductsServer.FillInSeriesByFEFO(Object, SeriesSpecificationParameters, False);
	EndIf;
	
	FillingResult = New Structure("HasChanges, NumberIsInitiallyCorrect");
	FillPropertyValues(FillingResult, ResultOfFillingInSeries);
	
	Return FillingResult;
	
EndFunction

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
	
	CCDNumbersFilledIn	= False;
	CCDNumber			= Undefined;
	
	ProcessIndicationOfCCDNumberServer(RowID,
										CalculationResult1,
										CCDNumbersFilledIn,
										CCDNumber);
	
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
	
	CalculateFinalRevenueFigures(ThisObject);
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

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = "Date" Then
		DateOnChange(Item);
	ElsIf Item.Name = "Partner" Then
		PartnerOnChange(Item);
	ElsIf Item.Name = "Terms" Then
		TermsOnChange(Item);
	ElsIf Item.Name = "Contract" Then
		ContractOnChange(Item);
	ElsIf Item.Name = "PriceIncludesVAT" Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = "Counterparty" Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = "VATTaxation" Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = "ReceiptAgainstOrder" Then
		ReceiptUnderOrdersOnChange(Item);
	ElsIf Item.Name = "ReceiptUnderOrders" Then
		ReceiptUnderOrdersOnChange(Item);
	ElsIf Item.Name = "BusinessOperation" Then
		BusinessOperationOnChange(Item);
	ElsIf Item.Name = "Warehouse" Then
		WarehouseOnChange(Item);
	ElsIf Item.Name = "ToReturnReusablePackage" Then
		ToReturnReusablePackageOnChange(Item);
	ElsIf Item.Name = "PackageDepositIsRequired" Then
		PackageDepositIsRequiredOnChange(Item);
	ElsIf Item.Name = "StructuralUnit" Then
		StructuralUnitOnChange(Item);
	ElsIf Item.Name = "GoodsPartnerProducts" Then
		GoodsPartnerProductsOnChange(Item);
	ElsIf Item.Name = "GoodsProducts" Then
		GoodsProductsOnChange(Item);
	ElsIf Item.Name = "GoodsCharacteristic" Then
		GoodsCharacteristicOnChange(Item);
	ElsIf Item.Name = "GoodsPurpose" Then
		GoodsPurposeOnChange(Item);
	ElsIf Item.Name = "GoodsSeries" Then
		GoodsSeriesOnChange(Item);
	ElsIf Item.Name = "GoodsNumberOfPackages" Then
		GoodsNumberOfPackagesOnChange(Item);
	ElsIf Item.Name = "GoodsPackage" Then
		GoodsPackageOnChange(Item);
	ElsIf Item.Name = "GoodsVendorPriceKind" Then
		GoodsVendorPriceKindOnChange(Item);
	ElsIf Item.Name = "GoodsPrice" Then
		GoodsPriceOnChange(Item);
	ElsIf Item.Name = "GoodsPercentRateOfManualDiscount" Then
		GoodsPercentRateOfManualDiscountOnChange(Item);
	ElsIf Item.Name = "GoodsManualDiscount" Then
		GoodsManualDiscountOnChange(Item);
	ElsIf Item.Name = "GoodsSum" Then
		GoodsSumOnChange(Item);
	ElsIf Item.Name = "GoodsAmountARAP" Then
		GoodsAmountARAPOnChange(Item);
	ElsIf Item.Name = "GoodsVATRate" Then
		GoodsVATRateOnChange(Item);
	ElsIf Item.Name = "GoodsVATAmount" Then
		GoodsVATAmountOnChange(Item);
	ElsIf Item.Name = "GoodsWarehouse" Then
		GoodsWarehouseOnChange(Item);
	ElsIf Item.Name = "GoodsPurchaseOrder" Then
		GoodsPurchaseOrderOnChange(Item);
	ElsIf Item.Name = "GoodsToExpenseAs" Then
		GoodsToExpenseAsOnChange(Item);
	ElsIf Item.Name = "GoodsExpenseItem" Then
		GoodsExpenseItemOnChange(Item);
	ElsIf Item.Name = "GoodsCCDNumber" Then
		GoodsCCDNumberOnChange(Item);
	ElsIf Item.Name = "GoodsDimensionOfExpenses" Then
		GoodsDimensionOfExpensesOnChange(Item);
	ElsIf Item.Name = "GoodsToControlQuality" Then
		GoodsToControlQualityOnChange(Item);
	ElsIf Item.Name = "GoodsQualityConfirmationDate" Then
		GoodsQualityConfirmationDateOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = "UnlinkFromOrder" Then
		UnlinkFromOrder(Command);
	ElsIf Command.Name = "SearchByBarcode" Then
		SearchByBarcodeExecute(Command);
	ElsIf Command.Name = "GetWeight" Then
		GetWeight(Command);
	ElsIf Command.Name = "ImportDataFromPDT" Then
		ImportDataFromPDT(Command);
	ElsIf Command.Name = "CheckQuantityInTheDocument" Then
		CheckQuantityInTheDocument(Command);
	ElsIf Command.Name = "FillThePricesByTermsOfSales" Then
		FillThePricesByTermsOfSales(Command);
	ElsIf Command.Name = "FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice" Then
		FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPrices(Command);
	ElsIf Command.Name = "FillInThePricesForReceipts" Then
		FillInThePricesForReceipts(Command);
	ElsIf Command.Name = "FillInCCDNumbers" Then
		FillInCCDNumbers(Command);
	ElsIf Command.Name = "FillInTheGTDNumbersForReceipts" Then
		FillInTheGTDNumbersForReceipts(Command);
	ElsIf Command.Name = "GoodsSelectGoodsByOrdersNotes" Then
		SelectGoodsByOrdersNotes(Command);
	ElsIf Command.Name = "ChangeQuality" Then
		ChangeTheQualityOfTheItem(Command);
	ElsIf Command.Name = "CancelManualDiscounts" Then
		CancelManualDiscounts(Command);
	ElsIf Command.Name = "AssignAManualDiscountToSelectedRows" Then
		AssignAManualDiscountForSelectedLines(Command);
	ElsIf Command.Name = "SplitTheFactString" Then
		SplitTheFactString(Command);
	ElsIf Command.Name = "SelectGoods" Then
		SelectGoods(Command);
	ElsIf Command.Name = "FillInNomenclatureAccordingToSupplierSNomenclature" Then
		FillInNomenclatureAccordingToSupplierSNomenclature(Command);
	ElsIf Command.Name = "AddReusablePackage" Then
		AddReusablePackage(Command);
	ElsIf Command.Name = "FillInTheWarehouseInSelectedLines" Then
		FillInTheWarehouseInSelectedLines(Command);
	ElsIf Command.Name = Commands.InsertRows.Name Then
		InsertRows(Command);
	ElsIf Command.Name = Commands.ImportFromExternalFile.Name Then
		ImportFromExternalFile(Command);
	ElsIf Command.Name = Commands.FillInTheDepartment.Name Then
		FillInTheDepartment(Command);
	ElsIf Command.Name = Commands.FillInVATRate.Name Then
		FillInVATRate(Command);
	ElsIf Command.Name = Commands.UploadCashierSChecks.Name Then
		UploadCashierSChecks(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Command);
	EndIf;
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	If Item.Name = "Goods" Then
		GoodsBeforeRowChange(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	If Item.Name = "Goods" Then
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

&AtClient
Function PerformChecksBeforeChangingStatus()
	
	Var ThereAreInvoices_1;
	
	PropsCanBeChanged = False;
	
	AdditionalParameters = New Structure;
	Notification = New CallbackDescription(
			"QuestionResultCompletion", ThisObject, AdditionalParameters);
	
	If StructureOfActionsControlOfNonAgreedChanges = Undefined
		Or StructureOfActionsControlOfNonAgreedChanges.AlertIsExpected Then
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	ClearMessages();
	
	CheckForAdjustmentsAndInvoices(Object.Ref, ThereAreAdjustingEntries, ThereAreInvoices_1);
	
	If Not ThereIsRightToAddAdjustments And (ThereAreAdjustingEntries Or ThereAreInvoices_1) And UseDebitNotes Then
		
		If ThereAreAdjustingEntries Then
			MessageText = NStr("vi = 'Trên cơ sở chứng từ đã nhập điều chỉnh mua hàng.
				|Không đủ quyền để tạo điều chỉnh tiếp nhận.';
				|ru = 'На основании документа введена корректировка приобретения.
				|Недостаточно прав для создания корректировки поступления.';
				|en = 'Purchase adjustment is generated from base document.
				|Insufficient rights to create the purchase adjustment.'; fa = 'Purchase adjustment is generated from base document.
				|Insufficient rights to create the purchase adjustment.';
				|it = 'Sulla base del documento è stato immessa una rettifica di acquisizione.
				|Non ci sono diritti sufficienti per creare la rettifica di arrivo.';
				|pl = 'Na podstawie tego dokumentu wprowadzono korektę zakupu. 
				| Brak wystarczających uprawnień do korekty wpływu.';
				|tr = 'Belge temelinde bir satın alma düzeltmesi girilmiştir. 
				|Bir gelir düzeltmesi oluşturmak için yeterli hak verilmemiştir.'");
		Else
			MessageText = NStr("vi = 'Trên cơ sở chứng từ đã ghi nhận hóa đơn GTGT.
				|Không đủ quyền để tạo điều chỉnh tiếp nhận.';
				|ru = 'На основании документа зарегистрирован счет-фактура.
				|Недостаточно прав для создания корректировки поступления.';
				|en = 'Based on the document the tax invoice was registered.
				|Insufficient rights to adjust the receipt.'; fa = 'Based on the document the tax invoice was registered.
				|Insufficient rights to adjust the receipt.';
				|it = 'Sulla base del documento è stata registrata una fattura.
				|Non ci sono diritti sufficienti per creare la rettifica di arrivo.';
				|pl = 'Na podstawie dokumentu zarejestrowano fakturę.
				|Niewystarczające uprawnienia do wykonania korekty wpływu.';
				|tr = 'Temel belgeye bir fatura kaydedilmiştir. 
				|Bir makbuz düzeltmesi oluşturmak için yetersiz haklar.'");
		EndIf;
		
		CommonClientServer.MessageToUser(MessageText);
		
	ElsIf ThereAreAdjustingEntries And UseDebitNotes Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add("EnterTheAdjustment", NStr("vi = 'Nhập điều chỉnh';
													|ru = 'Ввести корректировку';
													|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
													|it = 'Inserire rettifica';
													|pl = 'Wprowadź korektę';
													|tr = 'Bir düzenleme yapın'"));
		ButtonsList.Add("UndoChanges", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Trên cơ sở chứng từ đã nhập điều chỉnh mua sắm.
				|Cấm thay đổi chứng từ gốc.';
				|ru = 'На основании документа введена корректировка приобретения.
				|Изменение исходного документа запрещено.';
				|en = 'Purchase adjustment is generated from base document.
				|Editing the original document is not allowed.'; fa = 'Purchase adjustment is generated from base document.
				|Editing the original document is not allowed.';
				|it = 'Sulla base del documento è stato inserita una rettifica di acquisto.
				|La modifica del documento originale è vietata.';
				|pl = 'Na podstawie dokumentu jest wprowadzono korektę zakupu.
				|Zmiana dokumentu źródłowego jest zabroniona.';
				|tr = 'Temel belgeye bir satın alma düzenlemesi girilmiştir.
				| Orijinal belge değiştirilemez.'"),
			ButtonsList,
			,
			"EnterTheAdjustment");
		
	ElsIf ThereAreInvoices_1 And UseDebitNotes Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add("EnterTheAdjustment", NStr("vi = 'Nhập điều chỉnh';
													|ru = 'Ввести корректировку';
													|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
													|it = 'Inserire rettifica';
													|pl = 'Wprowadź korektę';
													|tr = 'Bir düzenleme yapın'"));
		ButtonsList.Add("UndoChanges", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Trên cơ sở chứng từ đã ghi nhận hóa đơn GTGT. Nhập điều chỉnh tiếp nhận
				|để xuất hóa đơn GTGT đã chỉnh sửa?';
				|ru = 'На основании документа зарегистрирован счет-фактура. Ввести корректировку поступления
				|для выставления исправленных счетов-фактур?';
				|en = 'Based on the document the tax invoice was registered.
				|Adjust the receipt to issue corrected tax invoices?'; fa = 'Based on the document the tax invoice was registered.
				|Adjust the receipt to issue corrected tax invoices?';
				|it = 'Sulla base del documento è stata registrata una fattura. Effettuare una rettifica di arrivo
				|per l''emissione delle fatture corrette?';
				|pl = 'Na podstawie dokumentu zarejestrowano fakturę. Dokonać korekty rachunku wpływu
				|w celu wystawienia skorygowanych faktur?';
				|tr = 'Belge temelinde bir fatura kaydedilmiştir. Değiştirilmiş faturaları düzenlemek için 
				|bir gelir düzeltmesi girilsin mi?'"),
			ButtonsList,
			,
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
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If Not PerformChecksBeforeChangingStatus() Then
		TMCommonUseClient.ReturnPreviousPropsValue(ThisForm, Item);
		Return;
	Else
		TMCommonUseClient.SaveAttributeValue(ThisForm, Item);
	EndIf;
	
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
	
	If Not PerformChecksBeforeChangingStatus() Then
		Return;
	EndIf;
	
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
	
	If Not PerformChecksBeforeChangingStatus() Then
		Cancel = True;
		Return;
	EndIf;
	
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
	
	If Not PerformChecksBeforeChangingStatus() Then
		Cancel = True;
		Return;
	EndIf;
	
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

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	EconomicOperationsOfSeparatePurchase = EconomicOperationsOfSeparatePurchase();
	ReceiptForSeparatePurchase = 
		EconomicOperationsOfSeparatePurchase.Find(Object.BusinessOperation) <> Undefined;

	ItemsTypes = ProductsServer.AcceptableItemTypesToChooseFrom(
		Object.BusinessOperation,
		Not ReceiptForSeparatePurchase);
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ItemsTypes);

	Columns = "Products,Characteristic,Package,NumberOfPackages,Price,PercentRateOfManualDiscount,ManualDiscount,
		|CCDNumber,Warehouse,Department,Certificate,PassportNumber";

	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);

	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));  
	ParametersForFillingInVATRate =
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
		
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
		
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("WhenChangingProductType",
			New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	If TableOfGoods.Columns.Find("ManualDiscount") <> Undefined Then
		StructureOfActions.RecalculateAmountTakingIntoAccountManualDiscount.Insert("RecalculateAmountOfManualDiscount_", False);
	EndIf;
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	
	RowsToProcess = New Array();

	For Each RowOfProduct In TableOfGoods Do

		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		If Object.ReceiptUnderOrders Then
			CurrentRow.OrderDiscrepancy_3 = 1;
		EndIf;
		If Not UseDiscountAdjustmentsInPurchases Then
			CurrentRow.PercentRateOfManualDiscount = 0;
			CurrentRow.ManualDiscount = 0;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	For Each CurrentRow In RowsToProcess Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Goods");
	EndDo;
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);

	FillInAttributeForDebitingExpensesForServices();
	
	WhenChangingWarehouseInTablePartServer();
	CalculateFinalRevenueFigures(ThisForm);
	FillInStatusesForSpecifyingSeriesServer();
	FillInServiceDetailsForPurposeOfVTCH();
	
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
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", ParametersForFillingInBankingDetails);

	If StructureOfNamesOfTableParts.Property("Goods") Then
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseDiscountAdjustmentsInPurchases = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
	UseReceiptForMultipleOrders = GetFunctionalOption("UseReceiptForMultipleOrders");
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UsePurchaseOrders = GetFunctionalOption("UsePurchaseOrders");
	UseTermsOfPurchases = GetFunctionalOption("UseTermsOfPurchases");
	UseDebitNotes = GetFunctionalOption("UseDebitNotes");
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	StartDateOfPrintingSingleExpenseReport = Constants.StartDateOfPrintingSingleExpenseReport.Get();
	SingleExpenseReportUnconditionally = Not Constants.VisibilityOfStartDateOfPrintingSingleExpenseReport.Get();
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	RightToReadOrdersToSupplier = AccessRight("Read", Metadata.Documents.PurchaseOrder);
	DefinePrintingSingleAdvanceReport();
	
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	
	DocumentCurrency = Object.Currency;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	Warehouse = Object.Warehouse;
	
	SetParametersForSelectingProductsWarehouse();
	
	WhenChangingWarehouseInTablePartServer();
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
	
	SetStockTypeSelectionParameters();
	SetAvailabilityOfItemsByStatusServer();
	FillInPricesOfOrderProductRange();
	SetVisibilityOfElementsByOperationServer();
	SetVisibilityOfCommandsByOrder();
	UpdateOrderInformation();
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	UpdateDependentDetailsOfOrderForm_(
		Items,
		Object.Goods,
		DiscrepancyOrderText);
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
	OldContract = Object.Contract;
	If Object.BusinessOperation <> Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		// Can clear the Contract.
		PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible);
		If QualityControl.UpdateActionParameters(
				Documents.VendorInvoice,
				Object,
				CacheQualityControl) Then
				
			StructureOfActions = New Structure();
			StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
			BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
			
		EndIf;
	EndIf;
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalRevenueFigures(ThisForm);
	
	UpdateTextAdvanceReport();
	
	UpdateTextDocumentsBasedOn();
	
	DocumentDateBeforeChange = Object.Date;
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object, Object.ReceiptUnderOrders,,SummaryDeliveryInformation);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	PrepareFillSetSeriesVisibility();
	SetVisibilityOfSeriesElements();
	
	FillOperationSelectionList();
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	FillParameters = Documents.VendorInvoice.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	
	FillParameters = Documents.VendorInvoice.ParametersForFillingInVATActivityType(Object);
	VATAccountingERP.FillInActivitySelectionList(Items.PurchaseForActivity, Object.PurchaseForActivity, FillParameters, VATAccountingCachedParameterValues);
	FillInServiceDetailsForPurposeOfVTCH();
	UpdateVHFWarehouseObligation();
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	VATAccountingLocalization.SetAvailabilityPriceIncludesVATOnVATTaxation(Items.PriceIncludesVAT, Object.VATTaxation);
	SetProductSelectionParameters();
	ConfigureVisibilityOfTeamFillInDivision();
	
	SetCorrectionModeFromLastDate();
	
	OperationWithSelfEmployedPerson = Object.OperationWithSelfEmployedPerson;
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject);
	CashServerLocalization.SetStatusOfUploadingReceipts(ThisObject); 
	
EndProcedure

&AtServerNoContext
Function GetBusinessTransaction(BusinessOperation)
	
	ContractBusinessTransaction = BusinessOperation;
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseViaAdvanceHolder")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorLocal") Then
		
		ContractBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier");
		
	EndIf;
	
	Return ContractBusinessTransaction;
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateFinalRevenueFigures(Form)
	
	// Calculation of the total for the tabular part "Goods"
	CollectionProducts = Form.Object.Goods;
	Form.AmountTotal = ?(Form.Object.PackageDepositIsRequired, 
		CollectionProducts.Total("AmountIncludingVAT"),
		CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages"));
	Form.VATAmount = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("VATAmount"),
		CollectionProducts.Total("VATAmountWithoutReusablePackages"));
	Form.PackageDepositValue = ?(Form.Object.PackageDepositIsRequired,CollectionProducts.Total("AmountIncludingVAT")
			- CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages"),0);

	EconomicImportOperations = EconomicImportOperations();
	EconomicOperationsImportFromEAEU = EconomicOperationsImportFromEAEU();
	
	If EconomicImportOperations.Find(Form.Object.BusinessOperation) <> Undefined
		Or EconomicOperationsImportFromEAEU.Find(Form.Object.BusinessOperation) <> Undefined Then
		
		Form.Items.VATPageGroup.Visible = False;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
		
	Else
		Form.Items.VATPageGroup.Visible = True;
		
		PurchaseIsSubjectToVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(Form.Object.VATTaxation);
		
		If PurchaseIsSubjectToVAT Then
			Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
			Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
		Else
			Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
			Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetDealOnOrderToSupplier(PurchaseOrder)
	
	Return Common.ObjectAttributeValue(PurchaseOrder, "SalesOpportunity");
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateOrderDeviationsInLine(CurrentRow, ReceiptUnderOrders, PackageDepositIsRequired)
	
	If CurrentRow.Price < CurrentRow.OrderPrice And CurrentRow.OrderPrice <> 0 And CurrentRow.RowCode <> 0 Then
		
		CurrentRow.PictureIndex = 3;
		CurrentRow.PriceChanged = True;
		If CurrentRow.Price <> 0 Then
			CurrentRow.PercentageOfDeviationFromTheOrderPrice = 100 - (CurrentRow.OrderPrice * 100 / CurrentRow.Price);
		Else
			CurrentRow.PercentageOfDeviationFromTheOrderPrice = 100;
		EndIf;
		
	ElsIf CurrentRow.Price > CurrentRow.OrderPrice And CurrentRow.OrderPrice <> 0 And CurrentRow.RowCode <> 0 Then
		
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
		UpdateOrderDeviationsInLine(CurRow, Object.ReceiptUnderOrders, Object.PackageDepositIsRequired);
	EndDo;
	
EndProcedure

&AtServer
Function PlaceGoodsInTemporaryStorageServer(CollectionName)
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(Object[CollectionName]);
	
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	TableOfGoods = GetFromTempStorage(AddressInTempStorage); // DocumentTabularSection.VendorInvoice.Goods
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));  
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
		
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	
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
	FillInServiceDetailsForPurposeOfVTCH();
	FillInAttributeForDebitingExpensesForServices();
	WhenChangingWarehouseInTablePartServer();
	CalculateFinalRevenueFigures(ThisForm);
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtServer
Procedure UpdateOrderInformation()
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.PurchaseOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "GoodsGroupPurchaseOrder";
	ParametersOfUpdate.OrderNameInTablePart          = "PurchaseOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseReceiptForMultipleOrders;

	OrdersServer.UpdateOrderInformationInForm(ThisForm, Object.Goods, ParametersOfUpdate);
		
	UpdateLabelForDeviationsFromOrderPrices();
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "SalesOpportunity", "Visible",
		(Object.ReceiptUnderOrders And ValueIsFilled(Object.PurchaseOrder)) Or Not Object.ReceiptUnderOrders);
	TMCommonUseClientServer.SetFormItemProperty(Items, "SalesOpportunity", "Enabled", Not Object.ReceiptUnderOrders);
	
	If RightToReadOrdersToSupplier Then
		If ValueIsFilled(Object.PurchaseOrder) Then
			Object.SalesOpportunity = GetDealOnOrderToSupplier(Object.PurchaseOrder);
		ElsIf Object.ReceiptUnderOrders Then
			Object.SalesOpportunity = Undefined;
		EndIf;
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
		Items.PicturePriceDeviationOrders.Picture = PictureLib.AnEmptyPicture;
		Items.PicturePriceDeviationOrder.Picture = PictureLib.AnEmptyPicture;
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
	
	EconomicOperationOfSelection = PurchasesServer.BusinessOperationsOnMain(ContractBusinessTransaction);
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency		= Object.ARAPCurrency;
		AddlParameters.LineOfBusiness	= Object.LineOfBusiness;
		AddlParameters.ContractWithSelfEmployedPerson		= Object.OperationWithSelfEmployedPerson;
		DefaultContract = PurchasesServer.GetDefaultContract(Object, EconomicOperationOfSelection, AddlParameters);
		
	Else
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.ARAPCurrency;
		AddlParameters.ContractWithSelfEmployedPerson = Object.OperationWithSelfEmployedPerson;
		DefaultContract = PurchasesServer.GetDefaultContract(Object, EconomicOperationOfSelection, AddlParameters);
		
	EndIf;
	
	UseAgreementsByAgreement = Not ValueIsFilled(Object.Terms)
		Or Common.ObjectAttributeValue(Object.Terms, "ContractsAreUsed");
	If (Contract <> DefaultContract
		Or Not ValueIsFilled(Object.Contract))
		And UseAgreementsByAgreement Then
		
		Object.Contract = DefaultContract;
		
		If ValueIsFilled(Object.Contract) Then
			FillInTypeOfActivityVAT();
			FillInVATTaxationPurchases();
			VATTaxationOnChangeServer();
		EndIf;
		
		ContractOnChangeServer();
		
	EndIf;
	
	Contract = Object.Contract;
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object, Object.ReceiptUnderOrders,,SummaryDeliveryInformation);
	
EndProcedure

&AtServer
Procedure FillInFromOrderServer()
	
	Object.Goods.Clear();
	
	If UseReceiptForMultipleOrders Then
		AnArrayOfOrders = Undefined;
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(Object.PurchaseOrder);
	EndIf;
	
	Documents.VendorInvoice.FillByOrderBalances(
		Object,
		Object.Goods,
		Warehouse,
		AnArrayOfOrders);
	
	FillInPricesOfOrderProductRange();
	UpdateOrderInformation();
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	RecalculateNumberOfRNPT();
	FillInServiceDetailsForPurposeOfVTCH();
	FillInAttributeForDebitingExpensesForServices();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	WhenChangingWarehouseInTablePartServer();
	CalculateFinalRevenueFigures(ThisForm);
	FillInStatusesForSpecifyingSeriesServer();
	
	QualityControl.UpdateActionParameters(Documents.VendorInvoice, Object, CacheQualityControl);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtServer
Procedure UntieLinesFromOrdersToSuppliers()
	
	For Each CurRow In Object.Goods Do
		
		CurRow.RowCode = 0;
		CurRow.PurchaseOrder = Documents.PurchaseOrder.EmptyRef();
		CurRow.SalesOpportunity = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommandsByOrder()
	
	Items.GoodsShowPriceVariances.Visible = Object.ReceiptUnderOrders;
	Items.CloseOrder.Visible = Object.ReceiptUnderOrders;
	Items.CloseOrders_2.Visible = Object.ReceiptUnderOrders;
	Items.GoodsAddReusablePackage.Visible = Not Object.ReceiptUnderOrders;
	
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
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	If Not Object.ReceiptUnderOrders Then
		ItemArray.Add("Date");
	EndIf;
	
	// Header Controls
	ItemArray.Add("Partner");
	ItemArray.Add("Terms");
	ItemArray.Add("Contract");
	
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("PaymentMethod");
	ItemArray.Add("ARAPObjectSettings");
	ItemArray.Add("ReceiptAgainstOrder");
	ItemArray.Add("ReceiptUnderOrders");
	
	ItemArray.Add("BusinessOperation");
	ItemArray.Add("SalesOpportunity");
	ItemArray.Add("StructuralUnit");
	ItemArray.Add("PurchaseForActivity");
	
	ItemArray.Add("Warehouse");
	
	ItemArray.Add("ToReturnReusablePackage");
	ItemArray.Add("ReusablePackagesReturnDate");
	ItemArray.Add("PackageDepositIsRequired");
	
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
	ItemArray.Add("GoodsCCDNumberOriginCountry");
	ItemArray.Add("GoodsFillInTheGTDNumbersForReceipts");
	ItemArray.Add("GoodsSelectGoodsByOrdersNotes");
	ItemArray.Add("GoodsChangeQuality");
	
	ItemArray.Add("GoodsCancelManualDiscounts");
	ItemArray.Add("GoodsAssignAManualDiscountToSelectedRows");
	
	ItemArray.Add("GoodsSplitRow");
	ItemArray.Add("GoodsContextMenuSplitTheFactString");
	ItemArray.Add("ProductsPickUpTheNomenclature");
	ItemArray.Add("GoodsFillInTheItemByThePartnerSItem");
	ItemArray.Add("GoodsAddReusablePackage");
	
	ItemArray.Add("GoodsFillInTheWarehouseInSelectedLines");
	
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsImportFromExternalFile");
	ItemArray.Add("GoodsFillInTheDepartment");
	ItemArray.Add("GoodsFillInVATRate");
	
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
	If Not Object.ReceiptUnderOrders Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsFillInTheWarehouseInSelectedLines", "Enabled", WarehouseGroup_);
	Else
		TMCommonUseClientServer.SetFormItemProperty(Items,"GoodsFillInTheWarehouseInSelectedLines", "Visible", False);
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsUnlinkFromOrder",                "Visible", Object.ReceiptUnderOrders);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsContextMenuUnlinkFromOrder", "Visible", Object.ReceiptUnderOrders);
	
	If Object.ReceiptUnderOrders And Not UserRightsCached.VarianceFromPurchaseConditions()
		And (ValueIsFilled(Object.PurchaseOrder) Or OrderList.Count() > 0) Then
		
		ItemArray = New Array;
		
		// Header Controls
		ItemArray.Add("Partner");
		ItemArray.Add("Terms");
		ItemArray.Add("Contract");
		ItemArray.Add("VATTaxation");
		ItemArray.Add("PriceIncludesVAT");
		ItemArray.Add("Organization");
		ItemArray.Add("Counterparty");
		ItemArray.Add("BusinessOperation");
		ItemArray.Add("Manager");
		ItemArray.Add("SalesOpportunity");
		ItemArray.Add("Department");
		ItemArray.Add("PurchaseForActivity");
		ItemArray.Add("ReceiptAgainstOrder");
		ItemArray.Add("ReceiptUnderOrders");
		ItemArray.Add("ToReturnReusablePackage");
		ItemArray.Add("PackageDepositIsRequired");
		ItemArray.Add("ReusablePackagesReturnDate");
		
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.VendorInvoice.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);

	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	ItemArray = New Array();
	ItemArray.Add("Calculations");
	ItemArray.Add("PaymentHeader");
	ItemArray.Add("CreditPaymentForm");
	ItemArray.Add("ARAPObjectSettings");
	ItemArray.Add("DecorationPaymentSteps");
	
	VisibilityOfElements = 
		(Object.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement) 
		And (Object.BusinessOperation <> Enums.BusinessTransactions.PurchaseViaAdvanceHolder);
		
	Items.GoodsAssignAManualDiscountToSelectedRows.Visible = VisibilityOfElements;
	Items.GoodsCancelManualDiscounts.Visible = VisibilityOfElements;
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", VisibilityOfElements);
	
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts);
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsPartnerProducts);
	
	ItemArray = New Array();
	ItemArray.Add("GoodsFillInCCDNumbers");
	ItemArray.Add("GoodsCCDNumberOriginCountry");
	ItemArray.Add("GoodsFillInTheGTDNumbersForReceipts");
	
	EconomicImportOperations = EconomicImportOperations();
	
	VisibilityOfElements = (EconomicImportOperations.Find(Object.BusinessOperation) = Undefined);

	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", VisibilityOfElements);
	
	Items.ReceiptUnderOrders.Enabled = Not Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal;
	Items.ReceiptAgainstOrder.Enabled = Not Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal;
	
	PurchaseViaAdvanceHolder = (Object.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder);
	
	
	ItemArray = New Array();
	ItemArray.Add("ReceiptAgainstOrder");
	ItemArray.Add("GoodsFillInTheItemByThePartnerSItem");
	ItemArray.Add("GoodsSelectGoodsByOrdersNotes");
	ItemArray.Add("GoodsPartnerProductsCode");
	ItemArray.Add("GoodsPartnerProductsSKU");
	ItemArray.Add("GoodsFillThePricesByTermsOfSales");
	ItemArray.Add("GoodsFillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice");
	ItemArray.Add("GoodsFillInThePricesForReceipts");
	
	SetAvailabilityAgreements();
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Not PurchaseViaAdvanceHolder);
	
	SetSupplierCommitment();
	SetVisibilityOfDetailsPrintAdvanceReport();
	
	If Not PurchaseViaAdvanceHolder Then
		PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSupplierCommitment()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder
		And Object.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		
		Items.Partner.AutoMarkIncomplete = False;
		Items.Counterparty.AutoMarkIncomplete = False;
	Else
		Items.Partner.AutoMarkIncomplete = Undefined;
		Items.Counterparty.AutoMarkIncomplete = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfDetailsPrintAdvanceReport()
	
	PurchaseViaAdvanceHolder = (Object.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder);
	
	VisibilityOfAdvanceReportPrintingDetails = PurchaseViaAdvanceHolder
		And Not PrintASingleExpenseReport
		And AccessRight("View", Metadata.CommonForms.AttributesForExpenseReportPrinting);
		
	Items.AttributesForExpenseReportPrinting.Visible = VisibilityOfAdvanceReportPrintingDetails;
	Items.PrintGroup.Visible = VisibilityOfAdvanceReportPrintingDetails;
	
	Items.TextExpenseReport.Visible = PurchaseViaAdvanceHolder 
												And PrintASingleExpenseReport
												And AccessRight("View", Metadata.Documents.ExpenseReport);
	
EndProcedure

&AtServer
Procedure SetStockTypeSelectionParameters()
	
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization"));
	ParametersArray.Add(New ChoiceParameterLink("Filter.BusinessOperation", "Object.BusinessOperation"));
	ParametersArray.Add(New ChoiceParameterLink("Filter.Products", "Items.Goods.CurrentData.Products"));
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.Consignor", "Object.Partner"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.Terms", "Object.Terms"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.Contract", "Object.Contract"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.Currency", "Object.Currency"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.VATTaxation", "Object.VATTaxation"));
	EndIf;
	
	Items.GoodsInventoryOwnerAttribute.ChoiceParameterLinks = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	If Not CheckServerItemParameters() Then
		Return;
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU")); 
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(Object, StructureOfActions, "Warehouse", True);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;
	CopiedFields = "PartnerProducts,
					|Products,
					|Characteristic,
					|Package,
					|Warehouse,
					|VendorPriceKind,
					|Price,
					|Sum,
					|NumberOfPackages,
					|PercentRateOfManualDiscount,
					|ManualDiscount";
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, CopiedFields);
		
		If Object.ReceiptUnderOrders Then
			CurrentRow.OrderDiscrepancy_3 = 1;
		EndIf;
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	For Each CurrentRow In RowsToProcess Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Goods");
	EndDo;
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	FillInServiceDetailsForPurposeOfVTCH();
	FillInAttributeForDebitingExpensesForServices();
	
	WhenChangingWarehouseInTablePartServer();
	CalculateFinalRevenueFigures(ThisForm);
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure GetProductsFromStorage(GoodsAddressInStorage)
	
	StructureOfActionsWithRecalculationOfAmounts = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithRecalculationOfAmounts, ThisObject);
	StructureOfActionsWithRecalculationOfAmounts.Delete("ClearAmountOfSettlements");
	StructureOfActionsWithRecalculationOfAmounts.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True));
	StructureOfActionsWithRecalculationOfAmounts.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	StructureOfActionsWithoutRecalculationOfAmounts = New Structure;
	StructureOfActionsWithoutRecalculationOfAmounts.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True));
	StructureOfActionsWithoutRecalculationOfAmounts.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage); // DocumentTabularSection.VendorInvoice.Goods
	
	SearchStructureForOrderItems = New Structure("RowCode,PurchaseOrder,Series");
	StructureOfSearchForGoodsWaybill = New Structure("LineNumber");
	
	GoodsFromOrder = New Array;
	InvoiceGoods = New Array;
	
	For Each RowOfGoods In ItemsFromStorage Do
		
		If RowOfGoods.RowCode<>0 And ValueIsFilled(RowOfGoods.PurchaseOrder) Then
			SearchStructureForOrderItems.RowCode = RowOfGoods.RowCode;
			SearchStructureForOrderItems.PurchaseOrder = RowOfGoods.PurchaseOrder;
			SearchStructureForOrderItems.Series = RowOfGoods.Series;
			ArrayOfTSRows = Object.Goods.FindRows(SearchStructureForOrderItems);
			StructureOfActions = StructureOfActionsWithoutRecalculationOfAmounts;
			ItemFromOrder = True;
		Else
			StructureOfSearchForGoodsWaybill.LineNumber = RowOfGoods.LineNumber;
			ArrayOfTSRows = Object.Goods.FindRows(StructureOfSearchForGoodsWaybill);
			StructureOfActions = StructureOfActionsWithRecalculationOfAmounts;
			ItemFromOrder = False;
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
		
		If ItemFromOrder Then
			GoodsFromOrder.Add(StringTSGoods);
		Else
			InvoiceGoods.Add(StringTSGoods);
		EndIf;
		
	EndDo;
	
	CachedValuesAreServiceValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfFillingInVATRate = 
	BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, False, Object.ToReturnReusablePackage);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesAreServiceValues);
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		GoodsFromOrder,
		StructureOfActionsWithoutRecalculationOfAmounts,
		Object.Goods);
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		InvoiceGoods,
		StructureOfActionsWithRecalculationOfAmounts,
		Object.Goods);
	
	RowsToProcess = New Array;
	CommonClientServer.SupplementArray(RowsToProcess, GoodsFromOrder);
	CommonClientServer.SupplementArray(RowsToProcess, InvoiceGoods);
	
	For Each StringTSGoods In RowsToProcess Do
		
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, StringTSGoods, "Object.Goods");
		
		If Not UseReceiptForMultipleOrders
			And ValueIsFilled(StringTSGoods.PurchaseOrder)
			And Object.PurchaseOrder <> StringTSGoods.PurchaseOrder Then
			
			Object.PurchaseOrder = StringTSGoods.PurchaseOrder;
			
		EndIf;
	EndDo;
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	FillInServiceDetailsForPurposeOfVTCH();
	
	InvoicingOperations = New Array;
	InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"));
	InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
	
	UnfacturedDeliveriesOfServicesWorks = InvoicingOperations.Find(Object.BusinessOperation) <> Undefined
			And OptionForRegisteringServiceReceiptDocuments = PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced");
	If Not UnfacturedDeliveriesOfServicesWorks Then
		
		FillInAttributeForDebitingExpensesForServices();
		
	EndIf;
	
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ClearAmountOfSettlements");
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateFinalRevenueFigures(ThisForm);
	
	WhenChangingWarehouseInTablePartServer();
	
	UpdateOrderInformation();
	Object.ReceiptUnderOrders = ValueIsFilled(Object.PurchaseOrder) Or OrderList.Count() > 0;
	FillInPricesOfOrderProductRange();
	UpdateOrderDeviations();
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ReceiptUnderOrders");
	
	SetVisibilityOfCommandsByOrder();
	
	DocumentBasis = PurchasesServer.DocumentBasis(Object, "ReceiptUnderOrders, PurchaseOrder, Goods.PurchaseOrder");
	ResponsiblePersonsServer.InstallManager(Object, DocumentBasis);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, TSName)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, ThereIsWriteOffForExpenses", True, True));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	
	If TSName = "Goods" Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
			StructureOfActions);
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions,
			"Warehouse",
			True);
	EndIf;
	
	ObjectTS = Object[TSName]; // FormDataCollection
	RowsToProcess = New Array;
	
	For Each RowOfGoods In ItemsFromStorage Do
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
		ObjectTS,
		CachedValues);
		
	For Each StringTSGoods In RowsToProcess Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, StringTSGoods, "Object.Goods");
	EndDo;
	
	If TSName = "Goods" Then
		ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
		TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
		
		InvoicingOperations = New Array;
		InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"));
		InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
		
		UnfacturedDeliveriesOfServicesWorks = InvoicingOperations.Find(Object.BusinessOperation) <> Undefined
			And OptionForRegisteringServiceReceiptDocuments = PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced");
		If Not UnfacturedDeliveriesOfServicesWorks Then
			
			FillInAttributeForDebitingExpensesForServices();
			
		EndIf;
		
		FillInStatusesForSpecifyingSeriesServer();
		PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
		FillInPricesOfOrderProductRange();
		WhenChangingWarehouseInTablePartServer();
		UpdateOrderInformation();
		UpdateVHFWarehouseObligation();
		FillInServiceDetailsForPurposeOfVTCH();
	EndIf;

	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtServer
Procedure ChangedPaymentServer(EventName, Parameter, Source)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.Goods, ArrayOfSelectedRows, Warehouse, True, "ToExpenseAs");
	
	If FilledWithRows > 0 Then
		RowsToProcess = New Array();
		For Each Id In ArrayOfSelectedRows Do
			RowsToProcess.Add(Object.Goods.FindByID(Id));
		EndDo;
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.Goods);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		WhenChangingWarehouseInTablePartServer();
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtServer
Function LinkReceiptLinesToOrdersToSuppliers(SelectByOrder_)
	
	If Not UsePurchaseOrders Or
		(Not UseReceiptForMultipleOrders
		And Not ValueIsFilled(Object.PurchaseOrder)) Then
		
		Return False;
		
	EndIf;

	Query = New Query("
		|SELECT
		|	Goods.Products   AS Products,
		|	Goods.Characteristic AS Characteristic
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|WHERE
		|	Goods.RowCode = 0
		|	AND Goods.PurchaseOrder = VALUE(Document.PurchaseOrder.EmptyRef)
		|;
		|SELECT ALLOWED
		|	OrdersTable.PurchaseOrder.SalesOpportunity    AS SalesOpportunity,
		|	OrdersTable.PurchaseOrder           AS PurchaseOrder,
		|	OrdersTable.ARAPObjectSettings           AS ARAPObjectSettings,
		|	OrdersTable.Products              AS Products,
		|	OrdersTable.Characteristic            AS Characteristic,
		|	OrdersTable.RowCode                 AS RowCode,
		|	OrdersTable.Warehouse                     AS Warehouse,
		|	OrdersTable.Purpose                AS Purpose,
		|	OrdersTable.ToExpenseAs          AS ToExpenseAs,
		|	OrdersTable.ExpenseItem AS ExpenseItem,
		|	OrdersTable.Department AS Department,
		|	SUM(OrdersTable.ToRegister)        AS ToRegisterBalance	
		|INTO PurchaseOrders
		|FROM
		|	(SELECT
		|		OrdersBalance.PurchaseOrder        AS PurchaseOrder,
		|		OrdersBalance.PurchaseOrder.ARAPObjectSettings AS ARAPObjectSettings,
		|		OrdersBalance.Products           AS Products,
		|		OrdersBalance.Characteristic         AS Characteristic,
		|		OrdersBalance.RowCode              AS RowCode,
		|		OrdersBalance.Warehouse                  AS Warehouse,
		|		ISNULL(GoodsFromOrder.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose,
		|		ISNULL(GoodsFromOrder.ToExpenseAs, FALSE) AS ToExpenseAs,
		|		ISNULL(GoodsFromOrder.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
		|		ISNULL(GoodsFromOrder.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) AS ExpenseItem,
		|		OrdersBalance.ToRegisterBalance     AS ToRegister 
		|	FROM
		|		AccumulationRegister.PurchaseOrders.Balance(,
		|				CASE WHEN &SelectByOrder_ THEN
		|					PurchaseOrder  = &PurchaseOrder
		|				ELSE
		|					PurchaseOrder.Partner = &Partner
		|					AND PurchaseOrder.Counterparty = &Counterparty
		|					AND PurchaseOrder.Contract = &Contract
		|					AND PurchaseOrder.Organization = &Organization
		|					AND PurchaseOrder.GoodsReceiptOption = &GoodsReceiptOption
		|					AND PurchaseOrder.BusinessOperation IN (&BusinessOperation)
		|					AND PurchaseOrder.Terms = &Terms
		|					AND (PurchaseOrder.Currency = &ARAPCurrency OR
		|					VALUE(Enum.BusinessTransactions.ConsignmentProcurement) IN (&BusinessOperation))
		|					AND PurchaseOrder.VATTaxation = &VATTaxation
		|					AND PurchaseOrder.PriceIncludesVAT = &PriceIncludesVAT
		|					AND PurchaseOrder.ToReturnReusablePackage = &ToReturnReusablePackage
		|					AND PurchaseOrder.PackageDepositIsRequired = &PackageDepositIsRequired
		|				END
		|				AND
		|				CASE
		|					WHEN
		|						CAST(&Warehouse AS Catalog.Warehouses).IsFolder
		|					THEN
		|						Warehouse IN HIERARCHY (&Warehouse) OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|					ELSE
		|						Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &Warehouse)
		|				END
		|			AND (Products, Characteristic) IN
		|			(SELECT
		|				Goods.Products AS Products,
		|				Goods.Characteristic AS Characteristic
		|			FROM
		|				Goods AS Goods)
		|			AND PurchaseOrder.OperationWithSelfEmployedPerson = &OperationWithSelfEmployedPerson
		|			) AS OrdersBalance
		|		LEFT JOIN Document.PurchaseOrder.Goods AS GoodsFromOrder
		|		ON GoodsFromOrder.Ref = OrdersBalance.PurchaseOrder
		|		AND GoodsFromOrder.RowCode = OrdersBalance.RowCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		TrafficOrders.PurchaseOrder,
		|		TrafficOrders.PurchaseOrder.ARAPObjectSettings,
		|		TrafficOrders.Products,
		|		TrafficOrders.Characteristic,
		|		TrafficOrders.RowCode,
		|		TrafficOrders.Warehouse,
		|		ISNULL(GoodsFromOrder.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose,
		|		ISNULL(GoodsFromOrder.ToExpenseAs, FALSE) AS ToExpenseAs, 
		|		ISNULL(GoodsFromOrder.Department, VALUE(Catalog.BusinessStructure.EmptyRef)),
		|		ISNULL(GoodsFromOrder.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)),
		|		CASE WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|				-TrafficOrders.ToRegister
		|			ELSE
		|				TrafficOrders.ToRegister
		|		END
		|	FROM
		|		AccumulationRegister.PurchaseOrders AS TrafficOrders
		|		LEFT JOIN Document.PurchaseOrder.Goods AS GoodsFromOrder
		|		ON GoodsFromOrder.Ref = TrafficOrders.PurchaseOrder
		|		AND GoodsFromOrder.RowCode = TrafficOrders.RowCode
		|
		|	WHERE
		|		TrafficOrders.Recorder = &Recorder
		|		AND CASE WHEN &SelectByOrder_ THEN
		|			TrafficOrders.PurchaseOrder = &PurchaseOrder
		|		ELSE
		|			TrafficOrders.PurchaseOrder.Partner = &Partner
		|			AND TrafficOrders.PurchaseOrder.Counterparty = &Counterparty
		|			AND TrafficOrders.PurchaseOrder.Contract = &Contract
		|			AND TrafficOrders.PurchaseOrder.Organization = &Organization
		|			AND TrafficOrders.PurchaseOrder.GoodsReceiptOption = &GoodsReceiptOption
		|			AND TrafficOrders.PurchaseOrder.BusinessOperation IN (&BusinessOperation)
		|			AND TrafficOrders.PurchaseOrder.Terms = &Terms
		|			AND (TrafficOrders.PurchaseOrder.Currency = &ARAPCurrency OR
		|				VALUE(Enum.BusinessTransactions.ConsignmentProcurement) IN (&BusinessOperation))
		|			AND TrafficOrders.PurchaseOrder.VATTaxation = &VATTaxation
		|			AND TrafficOrders.PurchaseOrder.PriceIncludesVAT = &PriceIncludesVAT
		|			AND TrafficOrders.PurchaseOrder.ToReturnReusablePackage = &ToReturnReusablePackage
		|			AND TrafficOrders.PurchaseOrder.PackageDepositIsRequired = &PackageDepositIsRequired
		|		END
		|		AND TrafficOrders.Active
		|				AND CASE
		|					WHEN
		|						CAST(&Warehouse AS Catalog.Warehouses).IsFolder
		|					THEN
		|						TrafficOrders.Warehouse IN HIERARCHY (&Warehouse) OR TrafficOrders.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|					ELSE
		|						TrafficOrders.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &Warehouse)
		|				END
		|			AND (TrafficOrders.Products, TrafficOrders.Characteristic) IN
		|			(SELECT
		|				Goods.Products AS Products,
		|				Goods.Characteristic AS Characteristic
		|			FROM
		|				Goods AS Goods)
		|		AND PurchaseOrder.OperationWithSelfEmployedPerson = &OperationWithSelfEmployedPerson
		|	) AS OrdersTable
		|	
		|	GROUP BY
		|		OrdersTable.PurchaseOrder,
		|		OrdersTable.ARAPObjectSettings,
		|		OrdersTable.Products,
		|		OrdersTable.Characteristic,
		|		OrdersTable.RowCode,
		|		OrdersTable.Warehouse,
		|		OrdersTable.Purpose,
		|		OrdersTable.ExpenseItem,
		|		OrdersTable.Department,
		|		OrdersTable.ToExpenseAs
		|	
		|	HAVING
		|		SUM(OrdersTable.ToRegister) > 0
		|;
		|SELECT
		|	COUNT(*)                        AS DuplicateCount,
		|	PurchaseOrders.Products       AS Products,
		|	PurchaseOrders.Characteristic     AS Characteristic,
		|	PurchaseOrders.Warehouse              AS Warehouse
		|INTO DuplicatesOfProducts
		|FROM
		|	PurchaseOrders AS PurchaseOrders
		|GROUP BY
		|	Products,
		|	Characteristic,
		|	Warehouse
		|;
		|SELECT
		|	PurchaseOrders.SalesOpportunity             AS SalesOpportunity,
		|	PurchaseOrders.PurchaseOrder    AS PurchaseOrder,
		|	PurchaseOrders.ARAPObjectSettings    AS ARAPObjectSettings,
		|	PurchaseOrders.Products       AS Products,
		|	PurchaseOrders.Characteristic     AS Characteristic,
		|	PurchaseOrders.RowCode          AS RowCode,
		|	PurchaseOrders.Warehouse              AS Warehouse,
		|	PurchaseOrders.Purpose         AS Purpose,
		|	CASE
	    |		WHEN &FillingOutCostAnalytics
	    |			THEN PurchaseOrders.ToExpenseAs
	    |		ELSE FALSE
	    |	END AS ToExpenseAs,
		|	PurchaseOrders.ExpenseItem AS ExpenseItem,
		|	PurchaseOrders.Department AS Department,
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
		|ORDER BY
		|	PurchaseOrderGoods.Products,
		|	PurchaseOrderGoods.Characteristic,
		|	PurchaseOrderGoods.Warehouse,
		|	PurchaseOrderGoods.DateOfReceipt,
		|	PurchaseOrderGoods.Ref,
		|	PurchaseOrderGoods.LineNumber
		|");
		
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);

	InvoicingImportOfEAEUOrPurchasingFromSupplier = Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
												Or Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
	
	FillingOutCostAnalytics = Not InvoicingImportOfEAEUOrPurchasingFromSupplier;
	Query.SetParameter("FillingOutCostAnalytics", FillingOutCostAnalytics);		
	Query.SetParameter("PurchaseOrder",           Object.PurchaseOrder);
	Query.SetParameter("Partner",                   Object.Partner);
	Query.SetParameter("Counterparty",                Object.Counterparty);
	Query.SetParameter("Contract",                   Object.Contract);
	Query.SetParameter("Organization",               Object.Organization);
	
	OptionForRegisteringServiceReceiptDocuments = Common.ObjectAttributeValue(Object.Contract, "OptionForRegisteringServiceReceiptDocuments");
	
	If Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal Or
		Object.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.PurchaseFromSupplier);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier 
		And Not Object.Contract = Catalogs.CounterpartyContracts.EmptyRef() 
		And OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed Then
		BusinessTransactions = New Array;
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
		Query.SetParameter("BusinessOperation", BusinessTransactions);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU 
		And Not Object.Contract = Catalogs.CounterpartyContracts.EmptyRef() 
		And OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed Then
		BusinessTransactions = New Array;
		BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEU);
		BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
		Query.SetParameter("BusinessOperation", BusinessTransactions);
	Else
		Query.SetParameter("BusinessOperation", ContractBusinessTransaction);
	EndIf;
	
	Query.SetParameter("Terms",                Object.Terms);
	Query.SetParameter("ARAPCurrency",      Object.ARAPCurrency);
	Query.SetParameter("GoodsReceiptOption",     Object.GoodsReceiptOption);
	Query.SetParameter("VATTaxation",        Object.VATTaxation);
	Query.SetParameter("PriceIncludesVAT",           Object.PriceIncludesVAT);
	Query.SetParameter("ToReturnReusablePackage", Object.ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired",      Object.PackageDepositIsRequired);
	Query.SetParameter("Warehouse",                     Object.Warehouse);
	Query.SetParameter("Recorder",               Object.Ref);
	Query.SetParameter("SelectByOrder_",          SelectByOrder_);
	
	Query.SetParameter("Goods",  Object.Goods.Unload(,"RowCode,Products,Characteristic,PurchaseOrder"));
	
	Query.SetParameter("OperationWithSelfEmployedPerson",      Object.OperationWithSelfEmployedPerson);
	
	QueryResult = Query.ExecuteBatch();
	If QueryResult[1].IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = QueryResult[3].Select();
	
	ArrayOfARAPObjectsSettings = New Array();
	While Selection.Next() Do
		If ValueIsFilled(Selection.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(Selection.ARAPObjectSettings) = Undefined Then
			ArrayOfARAPObjectsSettings.Add(Selection.ARAPObjectSettings);
		EndIf;
	EndDo;
	
	If ArrayOfARAPObjectsSettings.Count() > 1 Then
		Common.MessageToUser(NStr("vi = 'Trong các đơn hàng đã tìm thấy, khác trường ""Trình tự hạch toán""';
									|ru = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|en = 'The ""Payment terms"" field data is different for the found orders'; fa = 'The ""Payment terms"" field data is different for the found orders';
									|it = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|pl = 'The ""Payment terms"" field data is different for the found orders';
									|tr = 'Bulunan siparişlerin farklı bir ""Alacak/Borç muhasebesi prosedürü"" alanı mevcut'"));
		Return False;
	EndIf;
	
	Selection.Reset();
	
	TableOfUnallocatedGoods = New ValueTable();
	TableOfUnallocatedGoods.Columns.Add("Products");
	TableOfUnallocatedGoods.Columns.Add("Characteristic");
	TableOfUnallocatedGoods.Columns.Add("Warehouse");
	TableOfUnallocatedGoods.Columns.Add("PurchaseOrder");
	TableOfUnallocatedGoods.Columns.Add("RowCode");
	TableOfUnallocatedGoods.Columns.Add("Count");
	TableOfUnallocatedGoods.Columns.Add("SalesOpportunity");
	TableOfUnallocatedGoods.Columns.Add("Purpose");
	TableOfUnallocatedGoods.Columns.Add("ToExpenseAs");

	RowsToProcess = New Array; 
	
	ImportOfEAEUOrPurchaseFromSupplier = Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
		Or Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;

	While Selection.Next() Do
				
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("Products",    Selection.Products);
		TheStructureOfTheSearch.Insert("Characteristic",  Selection.Characteristic);
		TheStructureOfTheSearch.Insert("Warehouse",           Selection.Warehouse);
		TheStructureOfTheSearch.Insert("Purpose",      Selection.Purpose);

		If FillingOutCostAnalytics Then 
			TheStructureOfTheSearch.Insert("ToExpenseAs",Selection.ToExpenseAs);
		EndIf;
		
		TheStructureOfTheSearch.Insert("RowCode",       0);
		TheStructureOfTheSearch.Insert("PurchaseOrder", Documents.PurchaseOrder.EmptyRef());
		
		ProductLines_3 = Object.Goods.FindRows(TheStructureOfTheSearch);
		RetainedQuantity = Selection.ToRegisterBalance;
		
		// If there are no duplicates, we distribute the order line to the invoice lines
		If Selection.DuplicateCount < 2 Then
		
			For Each LineProducts_ In ProductLines_3 Do
			
				If RetainedQuantity = 0 Then
					Break;
				EndIf;
				
				If ImportOfEAEUOrPurchaseFromSupplier Then 
					FillPropertyValues(LineProducts_, Selection, "RowCode,PurchaseOrder,SalesOpportunity,Purpose, Department, ExpenseItem");
				Else
					FillPropertyValues(LineProducts_, Selection, "RowCode,PurchaseOrder,SalesOpportunity,Purpose");
				EndIf;
				
				QuantityPerLine = LineProducts_.Count;
				
				If QuantityPerLine > RetainedQuantity Then
					LineProducts_.Count = RetainedQuantity;
					If RowsToProcess.Find(LineProducts_) = Undefined Then
						RowsToProcess.Add(LineProducts_);
					EndIf;
				EndIf;
				
				RetainedQuantity = RetainedQuantity - QuantityPerLine;
				
				If RetainedQuantity < 0 Then
					NewLineProducts = Object.Goods.Insert(Object.Goods.IndexOf(LineProducts_) + 1);
					FillPropertyValues(NewLineProducts, LineProducts_, , "RowCode,PurchaseOrder");
					NewLineProducts.Count = -RetainedQuantity;
					RowsToProcess.Add(NewLineProducts);
					
					RetainedQuantity = 0;
				EndIf;
				
			EndDo;

		// If there are duplicates, we distribute the order lines according to the invoice lines, taking into account the quantity.
		Else
			
			// On the first pass, we will fill in only if the quantity in the order line and the invoice match.
			
			For Each LineProducts_ In ProductLines_3 Do
				
				If LineProducts_.Count = Selection.ToRegisterBalance Then
					FillPropertyValues(LineProducts_, Selection, "RowCode,PurchaseOrder,SalesOpportunity,Purpose");
					RetainedQuantity = 0;
					
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If RetainedQuantity > 0 Then
			NewRow = TableOfUnallocatedGoods.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.Count = RetainedQuantity;
		EndIf;
		
	EndDo;
	
	// We will distribute duplicates of goods that were not distributed on the first pass
	If TableOfUnallocatedGoods.Count() > 0 Then
		
		For Each UnallocatedRow In TableOfUnallocatedGoods Do
			
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("Products",    UnallocatedRow.Products);
			TheStructureOfTheSearch.Insert("Characteristic",  UnallocatedRow.Characteristic);
			TheStructureOfTheSearch.Insert("Warehouse",           UnallocatedRow.Warehouse);
			TheStructureOfTheSearch.Insert("Purpose",      UnallocatedRow.Purpose);
			TheStructureOfTheSearch.Insert("ToExpenseAs",UnallocatedRow.ToExpenseAs);
			TheStructureOfTheSearch.Insert("RowCode",       0);
			TheStructureOfTheSearch.Insert("PurchaseOrder", Documents.PurchaseOrder.EmptyRef());
			
			ProductLines_3 = Object.Goods.FindRows(TheStructureOfTheSearch);
			
			For Each LineProducts_ In ProductLines_3 Do
				
				If UnallocatedRow.Count = 0 Then
					Break;
				EndIf;
				
				If LineProducts_.Count = UnallocatedRow.Count Then
					FillPropertyValues(LineProducts_, UnallocatedRow, "RowCode,PurchaseOrder,SalesOpportunity,Purpose");
					UnallocatedRow.Count = 0;
					
				ElsIf LineProducts_.Count > UnallocatedRow.Count Then 
					NewLineProducts = Object.Goods.Insert(Object.Goods.IndexOf(LineProducts_) + 1);
					FillPropertyValues(NewLineProducts, LineProducts_, , "RowCode,PurchaseOrder");
					NewLineProducts.Count = LineProducts_.Count - UnallocatedRow.Count;
					RowsToProcess.Add(NewLineProducts);
					
					FillPropertyValues(LineProducts_, UnallocatedRow, "RowCode,PurchaseOrder,SalesOpportunity,Purpose,Count");
					If RowsToProcess.Find(LineProducts_) = Undefined Then
						RowsToProcess.Add(LineProducts_);
					EndIf;
					UnallocatedRow.Count = 0;
					
				ElsIf LineProducts_.Count < UnallocatedRow.Count Then
					FillPropertyValues(LineProducts_, UnallocatedRow, "RowCode,PurchaseOrder,SalesOpportunity,Purpose");
					UnallocatedRow.Count = UnallocatedRow.Count - LineProducts_.Count;
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);

	Return True;
	
EndFunction

&AtServerNoContext
Function GetDefaultCounterpartyBankAccountServer(Counterparty)
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	
	Return CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Form.Object,
		StructureOfActions,
		"Warehouse",
		True);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
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
		And CurrentRow.Warehouse = PreviousRowDetails.Warehouse
		And CurrentRow.ToExpenseAs = PreviousRowDetails.ToExpenseAs Then
		RunCallback(CallbackDescription, True);
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
	QueryText = NStr("vi = 'Dòng được soạn sẽ sẽ không liên quan đến dòng của đơn hàng. Tiếp tục?';
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

// Question to the user when changing the details of the line question completion.
// 
// Parameters:
//  Response - DialogReturnCode -
//  AdditionalParameters - Structure -
&AtClient
Procedure QuestionToUserWhenChangingDetailsOfLineQuestionCompletion(Response, AdditionalParameters) Export
	
	// If the user has confirmed the change of the key Attribute value
	If Response = DialogReturnCode.Yes Then
		
		AdditionalParameters.CurrentRow.RowCode = 0;
		AdditionalParameters.CurrentRow.OrderPrice = 0;
		UpdateOrderDeviationsInLine(AdditionalParameters.CurrentRow, Object.ReceiptUnderOrders, Object.PackageDepositIsRequired);
		RunCallback(AdditionalParameters.CallbackDescription, True);
		
	Else
		
		// If the user refused to change the linked string, we return the old values
		FillPropertyValues(AdditionalParameters.CurrentRow, PreviousRowDetails);
		RunCallback(AdditionalParameters.CallbackDescription, False);
		
	EndIf;
	
EndProcedure

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity(OnlyNonLabeledProductsHaveBeenUnloaded = False)
	
	TabularPartProducts = Object.Goods.Unload();
	If TabularPartProducts.Columns.Find("MarkedProducts") <> Undefined Then
		CurrentRowNumber = TabularPartProducts.Count()-1;
		While CurrentRowNumber >= 0 Do
			If TabularPartProducts[CurrentRowNumber].MarkedProducts Then
				TabularPartProducts.Delete(CurrentRowNumber);
				OnlyNonLabeledProductsHaveBeenUnloaded = True;
			EndIf;
			CurrentRowNumber = CurrentRowNumber - 1;
		EndDo;
	EndIf;
	TabularPartProducts.GroupBy("Products, Characteristic, ItemVariantsAreUsed, Package, Series, BatchesIndicationStatus, Warehouse, ItemsType, PurchaseOrder", "NumberOfPackages");
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	StructureOfActionsFoundString = New Structure;
				
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsFoundString, ThisObject);
	
	ActionStructureNewLine = New Structure;
			
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		ActionStructureNewLine.Insert("FillInTermsOfPurchase",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		ActionStructureNewLine.Insert("FillInPurchasePrice",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	ActionStructureNewLine.Insert("FillInVATRate", ParametersForFillingInVATRate);
	ActionStructureNewLine.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	ActionStructureNewLine.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
		
	ActionStructureNewLine.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
		
	ActionStructureNewLine.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ActionStructureNewLine.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ActionStructureNewLine.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	ActionStructureNewLine.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		ActionStructureNewLine);
	AddActionsToStructureWhenChangingPackagesNumber(ActionStructureNewLine, ThisObject);
	ActionStructureNewLine.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	ActionStructureNewLine.Insert("FillInServiceDetailsForPurpose");
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", ActionStructureNewLine);
	
	LinesToDelete = New Array;
	RowsToProcess = New Array;
	AddedRows = New Array;
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("Products, Characteristic, Series, BatchesIndicationStatus, Package, Warehouse, PurchaseOrder");
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
				If Object.ReceiptUnderOrders Then
					TSRow.OrderDiscrepancy_3 = 1;
				EndIf;
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
			
			AddedRows.Add(TSRow);
		EndIf;
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActionsFoundString,
		Object.Goods,
		CachedValues);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		ActionStructureNewLine,
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
	
	FillInAttributeForDebitingExpensesForServices();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtClient
Procedure LabelHeadingOrdersToSuppliersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			OrderList,
			NStr("vi = 'Đơn hàng đặt nhà cung cấp (%DocumentsCount%)';
				|ru = 'Заказы поставщикам (%DocumentsCount%)';
				|en = 'Purchase orders (%DocumentsCount%)'; fa = 'Purchase orders (%DocumentsCount%)';
				|it = 'Ordini ai fornitori (%DocumentsCount%)';
				|pl = 'Zamówienia dla dostawców (%DocumentsCount%)';
				|tr = 'Satın alma siparişleri (%DocumentsCount%)'")
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_, False);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	UpdateDependentDetailsOfServerByOrderForm();
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	BusinessTransactionsImportPurchase = PurchasesServerCall.BusinessOperationsOnMain(
									PredefinedValue("Enum.BusinessTransactions.PurchaseByImport"));
	
	If ValueIsFilled(Object.Warehouse)
		And ValueIsFilled(Object.Organization)
		And BusinessTransactionsImportPurchase.Find(Object.BusinessOperation) = Undefined Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Warehouse",
												True);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtServerNoContext
Procedure CheckForAdjustmentsAndInvoices(Ref, ThereAreAdjustingEntries, ThereAreInvoices_1)
	
	PurchasesServer.CheckForAdjustmentsAndInvoices(Ref, Ref, ThereAreAdjustingEntries, ThereAreInvoices_1);
	
EndProcedure

&AtServerNoContext
Function HaveRightToAddAdjustments()
	
	Return AccessRight("Insert", Metadata.Documents.PurchaseAdjustment);
	
EndFunction

&AtServer
Function AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(SelectedLinesOnly)
	
	ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
	ParametersStructure.TableName = "Goods";
	ParametersStructure.OnlyForSelectedLines = SelectedLinesOnly;
	Return DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryPurchaseStorage(
		ThisForm,UUID, ParametersStructure);
	
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
	
	If Object.Goods.Count() = 0 Or Not Object.ReceiptUnderOrders Or Not UsePurchaseOrders Then
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
		DiscrepancyOrderText = StrReplace(NStr("vi = 'Dòng khác với đơn hàng: %NumberOfDiscrepancies%';
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
	
	If Object.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		Items.Terms.Visible = False;
	ElsIf ValueIsFilled(Object.Partner) Then
		NumberOfSupplierAgreements  = PurchasesServerCall.GetNumberOfAgreementsWithSupplier(Object.Partner);
		Items.Terms.Visible = ValueIsFilled(Object.Terms) Or NumberOfSupplierAgreements > 0;
	Else
		Items.Terms.Visible = False;
	EndIf;

EndProcedure

&AtServerNoContext
Procedure UpdateAvailabilityOfReturnContainerItems(Form)
	
	EconomicImportOperations    = EconomicImportOperations();
	EconomicOperationsImportFromEAEU = EconomicOperationsImportFromEAEU();
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"ToReturnReusablePackage",
		"Enabled",
		Form.Object.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorLocal
		And EconomicImportOperations.Find(Form.Object.BusinessOperation) = Undefined
		And EconomicOperationsImportFromEAEU.Find(Form.Object.BusinessOperation) = Undefined
		And Form.Object.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"ReusablePackagesReturnDate",
		"Enabled",
		Form.Object.ToReturnReusablePackage);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"PackageDepositIsRequired",
		"Enabled",
		Form.Object.ToReturnReusablePackage
		And Form.Object.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorLocal
		And EconomicImportOperations.Find(Form.Object.BusinessOperation) = Undefined
		And EconomicOperationsImportFromEAEU.Find(Form.Object.BusinessOperation) = Undefined
		And Form.Object.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement);
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ActionStructureModifiedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ActionStructureModifiedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages"); 
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	ActionStructureModifiedStrings.Insert("FillInVATRate", ParametersForFillingInVATRate);
	ActionStructureModifiedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	ActionStructureModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	ActionStructureModifiedStrings.Insert("ClearAmountOfSettlements");
	ActionStructureModifiedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		ActionStructureModifiedStrings);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		ActionStructureModifiedStrings,
		"Warehouse",
		True);
	
	StructureOfActionsAddedLines = Common.CopyRecursive(ActionStructureModifiedStrings);
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActionsAddedLines.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActionsAddedLines.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActionsAddedLines.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActionsAddedLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsAddedLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsAddedLines.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsAddedLines.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsAddedLines.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActionsAddedLines.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActionsAddedLines);
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActionsAddedLines);
	
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
	
	StructureOfNamesOfTableParts = New Structure("Goods");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	FillInServiceDetailsForPurposeOfVTCH();
	CalculateFinalRevenueFigures(ThisForm);
	WhenChangingWarehouseInTablePartServer();
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtServer
Procedure ToReturnReusablePackageOnChangeServer()
	
	If Not Object.ToReturnReusablePackage Then
		Object.PackageDepositIsRequired = False;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInServiceDetailsForPurpose");
		
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);

	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure(
		"WithoutReusablePackages",
		"Sum,VATAmount,AmountIncludingVAT,ManualDiscount");
	
EndFunction

&AtClient
Procedure GoodsToExpenseAsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("WriteOffGoodsAsExpensesQuestionToUserEnd", ThisObject, AdditionalParameters),
		CurrentRow)
	
EndProcedure

&AtClient
Procedure WriteOffGoodsAsExpensesQuestionToUserEnd(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	TableRow = AdditionalParameters["CurrentRow"];
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,, "ToExpenseAs"));
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department, ThereIsWriteOffForExpenses", Object.Department, True));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters",
		TableRow.Warehouse, SeriesSpecificationParameters));
	
	If Not TableRow.ToExpenseAs Then
		IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure FillInTheDepartment(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	
	If Object.Goods.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
								|ru = 'В список ""Товары"" не введено ни одной строки.';
								|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
								|it = 'Nell''elenco ""Merci"" non è stata immessa alcuna riga.';
								|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
								|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir.'"));
		Return;
	Else
		
		RequiredFilling_ = False;
		
		For Each String In SelectedRows Do
			
			RowData = Object.Goods.FindByID(String);
			
			If (RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Or
				RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
				And (Not RowData.ToExpenseAs Or ValueIsFilled(RowData.Purpose)) Then
				Continue;
			EndIf;
			
			RequiredFilling_ = True;
			Break;
			
		EndDo;
		
		If Not RequiredFilling_ Then
			ShowMessageBox( , NStr("vi = 'Tại các dòng đã chọn trong danh sách ""Hàng hóa"" không cần điền bộ phận-nơi nhận.';
									|ru = 'В выделенных строках списка ""Товары"" заполнение подразделения-получателя не требуется.';
									|en = 'No need to specify a Receiving business unit for the selected items.'; fa = 'No need to specify a Receiving business unit for the selected items.';
									|it = 'Nelle righe selezionate dell''elenco ""Merci"" non è richiesta la compilazione del reparto-destinatario.';
									|pl = 'W zaznaczonych wierszach listy ""Wiersze pozycji"" wypełnienie działów-odbiorców nie jest wymagane.';
									|tr = '""Ürünler"" listesinin seçili satırlarında alıcı departmanın doldurulmasına gerek yoktur.'"));
			Return;
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure("Department", Object.Department);
	
	OpenForm("Catalog.BusinessStructure.ChoiceForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	ClearMessages();

	FillInVATRateOnServer(VATRate, CachedValues);

	CalculateFinalRevenueFigures(ThisObject);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());

	TSStrings = ProcessingOfTabularFormsClientServer.CollectionItems(Object.Goods, Items.Goods.SelectedRows);
	RowsToDelete = New Array;
	For Each LineOfATabularSection In TSStrings Do
		If Object.ToReturnReusablePackage
			And LineOfATabularSection.ItemsType = Enums.ItemsTypes.ReusablePackage Then
			RowsToDelete.Add(LineOfATabularSection);
			Continue;
		EndIf;
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	For Each LineToDelete In RowsToDelete Do
		TSStrings.Delete(TSStrings.Find(LineToDelete));
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		TSStrings,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalRevenueFigures(ThisObject);
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);

	UpdateTextDocumentsBasedOn();

	SetSupplierCommitment();

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

#EndRegion

#Region WorkingWithCounterparties



&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function FillInServerAcceptanceForm(ThereAreAcceptedGoods)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmount");
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActionsWithModifiedStrings.Insert("ClearAmountOfSettlements");
	StructureOfActionsWithModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	StructureOfActionsWithAddedStrings = New Structure;
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActionsWithAddedStrings.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActionsWithAddedStrings.Insert("RecalculateAmount");
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsWithAddedStrings.Insert("ClearAmountOfSettlements");
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);

	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActionsWithAddedStrings);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);
	
	If Object.ReceiptUnderOrders Then
		Orders = Object.Goods.Unload(, "PurchaseOrder");
		Orders.GroupBy("PurchaseOrder");
		ReferenceArray = Orders.UnloadColumn("PurchaseOrder");
		If ValueIsFilled(Object.PurchaseOrder) And
			ReferenceArray.Find(Object.PurchaseOrder) = Undefined Then
			ReferenceArray.Add(Object.PurchaseOrder);
		EndIf;
		If ReferenceArray.Count() = 0
			And ValueIsFilled(Parameters.Basis)
			And TypeOf(Parameters.Basis) = Type("Structure")
			And Parameters.Basis.Property("DocumentBasis") Then
				Parameters.Basis.Property("DocumentBasis", ReferenceArray);
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
	FillParameters.Contract                                = Object.Contract;
	FillParameters.FillInByReceipts                = EconomicOperationsOfSeparatePurchase().Find(Object.BusinessOperation)<>Undefined;
	FillParameters.GoodsReceiptOption                  = Object.GoodsReceiptOption;
	
	HasChanges = PurchasesServer.FillInGoodsOnActualAcceptance(Object.Goods,
																		FillParameters,
																		ThereAreAcceptedGoods);
	
	DistributeByOrders();
	WhenChangingWarehouseInTablePartServer();
	FillInServiceDetailsForPurposeOfVTCH();
	RecalculateNumberOfRNPT();
	CalculateFinalRevenueFigures(ThisForm);
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	UpdateOrderInformation();
	
	If Object.ReceiptUnderOrders Then
		UpdateOrderDeviations();
	EndIf;
	
	Return HasChanges;
	
EndFunction

&AtServer
Procedure DistributeByOrders(AddUnallocated = True)

	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("PurchaseOrder", New TypeDescription("DocumentRef.PurchaseOrder"));
	TableOfGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfGoods.Columns.Add("RowCode", New TypeDescription("Number", New NumberQualifiers(10, 0)));
	TableOfGoods.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(15, 3)));
	TableOfGoods.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	TableOfGoods.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(10, 0)));
	TableOfGoods.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TableOfGoods.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	TableOfGoods.Columns.Add("Price", TMCommonUse.MoneyFieldTypeDescription());
	TableOfGoods.Columns.Add("VATRate", New TypeDescription("CatalogRef.VATRates"));
	TableOfGoods.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription());
	TableOfGoods.Columns.Add("VATAmount", TMCommonUse.MoneyFieldTypeDescription());
	TableOfGoods.Columns.Add("AmountIncludingVAT", TMCommonUse.MoneyFieldTypeDescription());
	TableOfGoods.Columns.Add("PercentRateOfManualDiscount", New TypeDescription("Number", New NumberQualifiers(5, 2)));
	TableOfGoods.Columns.Add("ManualDiscount", TMCommonUse.MoneyFieldTypeDescription());
	TableOfGoods.Columns.Add("SalesOpportunity", New TypeDescription("CatalogRef.SalesOpportunitiesToCustomer"));
	TableOfGoods.Columns.Add("ExpenseItem", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems"));
	TableOfGoods.Columns.Add("DimensionOfExpenses", New TypeDescription("CatalogRef.OtherExpenses"));
	TableOfGoods.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	TableOfGoods.Columns.Add("ToExpenseAs", New TypeDescription("Boolean"));
	TableOfGoods.Columns.Add("VendorPriceKind", New TypeDescription("CatalogRef.VendorPriceTypes"));
	TableOfGoods.Columns.Add("PartnerProducts", New TypeDescription("CatalogRef.ProductCrossReferences"));
	TableOfGoods.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	TableOfGoods.Columns.Add("NumberOfPackages", New TypeDescription("Number", New NumberQualifiers(15, 3)));
	TableOfGoods.Columns.Add("ZoomRatio", New TypeDescription("Number", New NumberQualifiers(15, 5)));
	
	If UseReceiptForMultipleOrders Then
		AnArrayOfOrders = Undefined;
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(Object.PurchaseOrder);
	EndIf;
	
	Documents.VendorInvoice.FillByOrderBalances(
				Object,
				TableOfGoods,
				Object.Warehouse,
				AnArrayOfOrders);
	
	OrderOrder = False;
	
	TheStructureOfTheSearch = New Structure("Warehouse,Products,Characteristic,Purpose,RowCode");
	
	If Object.Goods.Count()<>0 Then
		DocumentInflow = Object.Goods.Get(0).PurchaseOrder;
		OrderOrder   = (TypeOf(DocumentInflow) = Type("DocumentRef.PurchaseOrder"));
	EndIf;
	
	If OrderOrder Then
		TheStructureOfTheSearch.Insert("PurchaseOrder");
	EndIf;
	
	ArrayOfStringsWithoutAllocation = New Array();
	
	For Each RowOfProduct In Object.Goods Do
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfProduct);
		FoundRows = TableOfGoods.FindRows(TheStructureOfTheSearch);

		If FoundRows.Count() = 0 Then
			ArrayOfStringsWithoutAllocation.Add(RowOfProduct);
			Continue;
		EndIf;
		
		RetainedQuantity = RowOfProduct.Count;
		
		For Each LineOfProductsByOrders In FoundRows Do
			
			If LineOfProductsByOrders.Count = 0 Then
				Continue;
			EndIf;
			
			QuantityToDistribution = Min(RetainedQuantity, LineOfProductsByOrders.Count);
			LineOfProductsByOrders.Count = LineOfProductsByOrders.Count - QuantityToDistribution;
			RetainedQuantity = RetainedQuantity - QuantityToDistribution;
			
			If LineOfProductsByOrders.Count = 0 Then
				TableOfGoods.Delete(LineOfProductsByOrders);
			EndIf;	
			
			If RetainedQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	TheStructureOfTheSearch = New Structure("Warehouse,Products,Characteristic,Purpose");
	
	If OrderOrder Then
		TheStructureOfTheSearch.Insert("PurchaseOrder");
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	StructureOfActions.Delete("ClearAmountOfSettlements");
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	
	For Each RowWithoutAllocation In  ArrayOfStringsWithoutAllocation Do
		
		DistributeDocumentProductsByOrder(Object.Goods, RowWithoutAllocation, TableOfGoods, OrderOrder, StructureOfActions, TheStructureOfTheSearch, AddUnallocated);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure DistributeDocumentProductsByOrder(DocumentGoodsWithoutDistribution, RowWithoutAllocation, OrderBalances_, OrderOrder, StructureOfActions, TheStructureOfTheSearch, AddUnallocated)
	
	CachedValues = Undefined;
	
	FillPropertyValues(TheStructureOfTheSearch, RowWithoutAllocation);
	FoundRows = OrderBalances_.FindRows(TheStructureOfTheSearch);
	
	If FoundRows.Count() = 0 Then
		Return;
	EndIf;

	
	RetainedQuantity = RowWithoutAllocation.Count;
	LineOfProductsByOrders = FoundRows[0];
		
		QuantityToDistribution = Min(RetainedQuantity, LineOfProductsByOrders.Count);
				
		If LineOfProductsByOrders.Count >= RetainedQuantity Then
			FillPropertyValues(RowWithoutAllocation, LineOfProductsByOrders, "RowCode, Price, VATRate");
			RowWithoutAllocation.OrderPrice = LineOfProductsByOrders.Price;
			RowWithoutAllocation.OrderDiscrepancy_3 = 0;
			LineOfProductsByOrders.Count = LineOfProductsByOrders.Count - QuantityToDistribution;
			RetainedQuantity = RetainedQuantity - QuantityToDistribution;
			
			BatchProcessingOfTablePartServer.ProcessTSString(RowWithoutAllocation, StructureOfActions, CachedValues);

			If LineOfProductsByOrders.Count = 0 Then
				OrderBalances_.Delete(LineOfProductsByOrders);
			EndIf;
		ElsIf AddUnallocated And QuantityToDistribution > 0 Then
			RetainedQuantity = RetainedQuantity - QuantityToDistribution;
			RowWithoutAllocation.Count = QuantityToDistribution;
			
			NewRowWithoutAllocation = DocumentGoodsWithoutDistribution.Add();
			FillPropertyValues(NewRowWithoutAllocation, RowWithoutAllocation);
			NewRowWithoutAllocation.Count = RetainedQuantity;
			
			FillPropertyValues(RowWithoutAllocation, LineOfProductsByOrders, "RowCode, Price, VATRate");
			RowWithoutAllocation.OrderPrice = LineOfProductsByOrders.Price;
			RowWithoutAllocation.OrderDiscrepancy_3 = 0;
			
			LineOfProductsByOrders.Count = LineOfProductsByOrders.Count - QuantityToDistribution;
			
			BatchProcessingOfTablePartServer.ProcessTSString(RowWithoutAllocation, StructureOfActions, CachedValues);

			If LineOfProductsByOrders.Count = 0 Then
				OrderBalances_.Delete(LineOfProductsByOrders);
			EndIf;
			DistributeDocumentProductsByOrder(DocumentGoodsWithoutDistribution, NewRowWithoutAllocation, OrderBalances_, OrderOrder, StructureOfActions, TheStructureOfTheSearch, AddUnallocated);  
		ElsIf RowWithoutAllocation.Count > 0 Then
			RowWithoutAllocation.OrderDiscrepancy_3 = 1;
			RowWithoutAllocation.OrderPrice = 0;
			RowWithoutAllocation.RowCode = 0;
		EndIf;
			
EndProcedure

&AtServer
Procedure FillInAttributeForDebitingExpensesForServices()
	
	// filling in the write-off attribute for expenses
	FilterStructure1 = New Structure("ItemsType", Enums.ItemsTypes.OperationService);
	FoundRows = Object.Goods.FindRows(FilterStructure1);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision",
		DataToFillInWriteOFFAttributeForExpenses(Object.BusinessOperation, OptionForRegisteringServiceReceiptDocuments));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		FoundRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	For Each String In FoundRows Do
		IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, String, "Object.Goods");
	EndDo;
	
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
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		WhenChangingWarehouseInTablePartServer();
		
		CalculateFinalRevenueFigures(ThisForm);
		
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
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

&AtServer
Procedure UpdateTextAdvanceReport()
	
	TextExpenseReport = ExpenseReportLocalization.TextExpenseReport(Object.ExpenseReport);
	
EndProcedure

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TextsFieldsDocumentsBasedOn.Clear();
	
	RegistrationParameters = Documents.VendorInvoice.ParametersForRegisteringInvoicesReceived(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
	
	InvoiceTextReceived = InvoicesReceivedOnBasisOf.Presentation;
	GeneratingFiscalChecksServer.UpdateFiscalCheckBreakdownHyperlink(Object.Ref, ThisObject, InvoiceTextReceived);
	
	TextsFieldsDocumentsBasedOn.Add(InvoiceTextReceived);
	
	ParametersForRegisteringImportNotifications = VendorInvoiceLocalization.ParametersForRegisteringImportNotificationsOfTraceableGoods(Object);
	NotificationOfImportationOnBasisOf = AccountingForTraceableGoodsLocalization.NotificationsOfImportOfTraceableGoodsOnDocumentOfReceipt(ParametersForRegisteringImportNotifications);
	TextsFieldsDocumentsBasedOn.Add(NotificationOfImportationOnBasisOf.PresentationOfOrderForRegistration);
	TextsFieldsDocumentsBasedOn.Add(NotificationOfImportationOnBasisOf.PresentationOfImportNotification);
	
	If Not Object.ReceiptUnderOrders Then
		PresentationOfDPP = VATAccountingLocalization.EventDocumentsOnPreliminaryDeliveries(Object, AmountTotal);
		TextsFieldsDocumentsBasedOn.Add(PresentationOfDPP);
	EndIf;
	
	TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
	
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

&AtClient
Procedure IncomingDocumentNumberOnChange(Item)
	
	FormEventsClient.WhenChangingElement(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomingDocumentDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FormEventsClient.WhenChangingElement(ThisObject, Item);
	
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
		TitleFillIn = NStr("vi = 'Chọn hàng hóa theo lệnh';
							|ru = 'Подобрать товары по ордерам';
							|en = 'Pick goods by notes'; fa = 'انتخاب کالا بر اساس حواله‌ها';
							|it = 'Selezionare le merci in base ai mandati';
							|pl = 'Wybierz wiersze pozycji wg zleceń';
							|tr = 'Emirlere göre mal seçme'");
	Else
		TitleFillIn = NStr("vi = 'Chọn hàng hóa theo đơn đặt hàng / lệnh';
							|ru = 'Подобрать товары по заказам/ордерам';
							|en = 'Add items from Purchase order/Goods receipt'; fa = 'Add items from Purchase order/Goods receipt';
							|it = 'Seleziona le merci in base agli ordini/mandati';
							|pl = 'Wybierz wiersze pozycji wg zamówień/zleceń';
							|tr = 'Emir/siparişlere göre mal seçme'");
	EndIf;
	Items.GoodsSelectGoodsByOrdersNotes.Title = TitleFillIn;
	
EndProcedure

&AtServer
Procedure ReceiptUnderOrdersOnChangeServer()
	VisibilityOfElements = Object.ReceiptUnderOrders;
	
	Items.GoodsUnlinkFromOrder.Visible = VisibilityOfElements;
	Items.GoodsContextMenuUnlinkFromOrder.Visible = VisibilityOfElements;
	Items.GoodsPictureIndex.Visible = VisibilityOfElements;
	
	ReceiptForMultipleOrdersWhenChanging();
	UpdateDependentDetailsOfServerByOrderForm();
	
	Object.PaymentScheduleSteps.Clear();
	
	UpdateTextDocumentsBasedOn();
	
EndProcedure

&AtClient
Procedure FinishEditingProductsLine(Item, NewRow, CancelEdit)
	
	CalculateFinalRevenueFigures(ThisForm);
	
	CurrentData = Items.Goods.CurrentData;
		
	If CurrentData <> Undefined Then
		If Object.ReceiptUnderOrders And NewRow
			And Not CancelEdit Then 
			If Not UseReceiptForMultipleOrders Or ValueIsFilled(Object.PurchaseOrder) Then
				CurrentData.PurchaseOrder = Object.PurchaseOrder;
			EndIf;
			CurrentData.OrderDiscrepancy_3 = 1;
			CurrentData.RowCode = 0;
			CurrentData.OrderPrice = 0;
		EndIf;
		
		If ProductsClient.SeriesStatusesNeedToBeUpdated(
			Item,CachedValues,SeriesSpecificationParameters) Then
			
			IDCurrentRow = CurrentData.GetID();
			
			FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
			ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
			
		EndIf;
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateDependentDetailsOfOrderForm_(
		Items,
		Object.Goods,
		DiscrepancyOrderText);
	
	If Not CancelEdit Then
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	EndIf;
	
	SetWhetherWarehouseIsFull();
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("GoodsAtEndOfEditingForServerCall", 0.5, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAtEndOfEditingForServerCall()
	
	GoodsAtEndOfEditingOnServer();
	
EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer()
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Function FullDocumentName()
	
	Return "Document.VendorInvoice";
	
EndFunction

&AtServerNoContext
Function EconomicImportOperationsServer()
	
	Return Documents.VendorInvoice.EconomicImportOperations();
	
EndFunction

&AtClientAtServerNoContext
Function EconomicImportOperations()
	
	Return EconomicImportOperationsServer();
	
EndFunction

&AtServerNoContext
Function EconomicOperationsImportFromEAEUServer()
	
	Return Documents.VendorInvoice.EconomicOperationsImportFromEAEU();
	
EndFunction

&AtClientAtServerNoContext
Function EconomicOperationsImportFromEAEU()
	
	Return EconomicOperationsImportFromEAEUServer();
	
EndFunction

&AtClientAtServerNoContext
Function EconomicOperationsOfSeparatePurchase(UseGoodsInTransit = True,
		UseUninvoicedDeliveries = True)
	
	EconomicOperationsOfSeparatePurchase = New Array;
	
	If UseGoodsInTransit Then
		EconomicOperationsOfSeparatePurchase.Add(
			PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit"));
		EconomicOperationsOfSeparatePurchase.Add(
			PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit"));
		EconomicOperationsOfSeparatePurchase.Add(
			PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit"));
	EndIf;
	
	If UseUninvoicedDeliveries Then
		EconomicOperationsOfSeparatePurchase.Add(
			PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
		EconomicOperationsOfSeparatePurchase.Add(
			PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"));
	EndIf;
	
	Return EconomicOperationsOfSeparatePurchase;
	
EndFunction

&AtServerNoContext
Function GetDataOnAvailabilityOfAdjustmentsAndInvoices(DocmentLink)
	
	PropsCanBeChanged = False;
	ThereAreInvoices_ = False;
	ThereAreAdjustingEntries = False;
	CheckForAdjustmentsAndInvoices(DocmentLink, ThereAreAdjustingEntries, ThereAreInvoices_);
	
	If ThereAreAdjustingEntries Then
		MessageText = NStr("vi = 'Trên cơ sở chứng từ, đã nhập điều chỉnh mua sắm.
				|Cấm thay đổi chứng từ gốc.';
				|ru = 'На основании документа введена корректировка приобретения.
				|Изменение исходного документа запрещено.';
				|en = 'Purchase adjustment is generated from base document.
				|Editing the original document is not allowed.'; fa = 'Purchase adjustment is generated from base document.
				|Editing the original document is not allowed.';
				|it = 'На основании документа введена корректировка приобретения.
				|Изменение исходного документа запрещено.';
				|pl = 'Na podstawie dokumentu jest wprowadzono korektę zakupu.
				|Zmiana dokumentu źródłowego jest zabroniona.';
				|tr = 'Temel belgeye bir satın alma düzeltmesi girilmiştir.
				| Orijinal belge değiştirilemez.'");
		Common.MessageToUser(MessageText);
	ElsIf ThereAreInvoices_ Then
		MessageText = NStr("vi = 'Trên cơ sở chứng từ đã ghi nhận hóa đơn GTGT.
				|Cấm thay đổi chứng từ gốc.';
				|ru = 'На основании документа зарегистрирован счет-фактура.
				|Изменение исходного документа запрещено.';
				|en = 'Tax invoice is registered based on the document.
				|The source document cannot be changed.'; fa = 'Tax invoice is registered based on the document.
				|The source document cannot be changed.';
				|it = 'На основании документа зарегистрирован счет-фактура.
				|Изменение исходного документа запрещено.';
				|pl = 'Tax invoice is registered based on the document.
				|The source document cannot be changed.';
				|tr = 'Belge esas alınarak fatura kaydı yapılmıştır.
				|Orijinal belgenin değiştirilmesi yasaktır.'");
		Common.MessageToUser(MessageText);
	Else
		PropsCanBeChanged = True;
	EndIf;
		
	Return PropsCanBeChanged;
	
EndFunction

&AtServer
Procedure DateOfReceiptOnChangeServer()
	
	If QualityControl.UpdateActionParameters(
			Documents.VendorInvoice,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateShippingSummary()
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object, Object.ReceiptUnderOrders,,SummaryDeliveryInformation);
	
EndProcedure

&AtServer
Procedure FillInVATTaxationPurchases()
	
	FillParameters = Documents.VendorInvoice.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Procedure FillInTypeOfActivityVAT()
	
	FillParameters = Documents.VendorInvoice.ParametersForFillingInVATActivityType(Object);
	VATAccountingERP.FillInTypeOfActivityVAT(Object.PurchaseForActivity, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInActivitySelectionList(Items.PurchaseForActivity, Object.PurchaseForActivity, FillParameters, VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Function OrderToReceiveOptionOfAcceptanceOfGoods()
	
	OptionOfAcceptanceOfGoodsContract = Common.ObjectAttributeValue(Object.Contract, "GoodsReceiptOption");
	OptionOfAcceptanceOfGoodsAgreement = Common.ObjectAttributeValue(Object.Terms, "GoodsReceiptOption");
	
	If Catalogs.CounterpartyContracts.AgreementIsUsedDuringAcceptance(OptionOfAcceptanceOfGoodsContract)
		And AdvancedWarehousingOnReceiving Then
		Return Object.Contract;
	ElsIf Catalogs.TermsOfPurchaseFromVendors.AgreementIsUsedForAcceptance(OptionOfAcceptanceOfGoodsAgreement)
		And AdvancedWarehousingOnReceiving
		And Object.BusinessOperation <> Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		Return Object.Terms;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure SetCorrectionModeFromLastDate()
	
	AdjustmentModeFromPreviousDate = ValueIsFilled(Object.ActualTransactionDate);
	Items.ActualTransactionDate.Enabled = AdjustmentModeFromPreviousDate;
	
EndProcedure

&AtClient
Procedure SetWhetherWarehouseIsFull()
	
	WarehouseIsRequired = ?(Object.Goods.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

&AtServer
Procedure UpdateFlagThereAreAdjustments()
	ThereAreInvoices_ = False;
	CheckForAdjustmentsAndInvoices(Object.Ref, ThereAreAdjustingEntries, ThereAreInvoices_);
EndProcedure

&AtServer
Procedure UpdateVHFWarehouseObligation()
	
	FillParameters = New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True);
	StructureOfActions = New Structure;
 	StructureOfActions.Insert("WhenChangingProductType", FillParameters);
 	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	WarehouseIsRequired  = ?(Object.Goods.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForPurposeOfVTCH()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInServiceDetailsForPurpose");
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
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

&AtServer
Procedure SetProductSelectionParameters()
	
	ParametersArray = New Array;
	If ValueIsFilled(Object.Contract) Then
		SetPrivilegedMode(True);
		ContractType = Common.ObjectAttributeValue(Object.Contract, "ContractType");
		If ContractType = Enums.ContractTypes.TransferToTolling2_5
			Or ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries Then
			ParametersArray.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(ProductsClientServer.JobSelection(False))));
			Items.GoodsProducts.ChoiceParameters = New FixedArray(ParametersArray);
		Else 
			ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts);
		EndIf;
		SetPrivilegedMode(False);
	Else 
		ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts);
	EndIf;
	
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

&AtClient
Procedure FillInNomenclatureAccordingToSupplierSNomenclatureCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		FillInItemsFromTemporaryStorageServer(Result);
		
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	Items.BusinessOperation.ChoiceList.LoadValues(
		PurchasesServer.EconomicOperationsOfSeparatePurchase(FullDocumentName()));
	
	OnlyOperation = Items.BusinessOperation.ChoiceList.Count() = 1;
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"BusinessOperation",
		"ReadOnly",
			(OnlyOperation And ValueIsFilled(Object.BusinessOperation))
			Or (Object.ReceiptUnderOrders And Not UserRightsCached.VarianceFromPurchaseConditions()
				And (ValueIsFilled(Object.PurchaseOrder) Or OrderList.Count() > 0)));
				
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm);
EndProcedure

&AtServer
Procedure EstablishVisibilityOfRNPTQuantity()
	
	BusinessTransactionsImportPurchase = PurchasesServerCall.BusinessOperationsOnMain(
									PredefinedValue("Enum.BusinessTransactions.PurchaseByImport"));
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	Items.ProductsGroupQuantityByRNPT.Visible = Items.ProductsGroupQuantityByRNPT.Visible
														And BusinessTransactionsImportPurchase.Find(Object.BusinessOperation) = Undefined;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfActualDateOfOperation()
	
	InvoicingOperations = New Array;
	InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"));
	InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
	
	Items.GroupLastDate.Visible = InvoicingOperations.Find(Object.BusinessOperation) = Undefined;
	
EndProcedure

#Region FiscalTransaction

&AtClient
Procedure FiscalOperationNavigationLinkProcessing(Item, Var_URL, StandardProcessing)
	
	If Var_URL = "IssueCashReceipt" Then
		
		StandardProcessing = False;
			
		GeneratingFiscalChecksClient.DisplayReceipt(
			ThisObject,
			New CallbackDescription("FiscalTransactionCompletion", ThisObject));

	ElsIf "OpenRecordOfFiscalTransaction" = Var_URL Then
		
		StandardProcessing = False;
		
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref);
		
	ElsIf "ConfigureHardware_" = Var_URL Then
		
		StandardProcessing = False;
		
		OpenForm("DataProcessor.PreviewReceipt.Form.ErrorOfCREConnection");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FiscalTransactionCompletion(Result, AdditionalParameters) Export
	
	UpdateTextDocumentsBasedOn();
	
EndProcedure

#EndRegion

&AtServer
Procedure SetUpWriteOffColumnsForExpensesTSProducts()
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision",
		DataToFillInWriteOFFAttributeForExpenses(Object.BusinessOperation, OptionForRegisteringServiceReceiptDocuments));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,, "ToExpenseAs"));
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.Goods,
		StructureOfActions);
	
	LinesForClearingExpenseAnalyticsItems = New Array;
	
	For Each LineProducts_ In Object.Goods Do
		If Not LineProducts_.ToExpenseAs Then
			LinesForClearingExpenseAnalyticsItems.Add(LineProducts_);
		EndIf;
		
		IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, LineProducts_, "Object.Goods");
		
	EndDo;
	
	If LinesForClearingExpenseAnalyticsItems.Count() > 0 Then
		
		StructureOfActions = New Structure;
		IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);

		BatchProcessingOfTablePartServer.ProcessTSStrings(
			LinesForClearingExpenseAnalyticsItems,
			StructureOfActions,
			Object.Goods);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPurchaseOrderInLines()
	
	If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement") Then
		
		If Object.ReceiptUnderOrders And ValueIsFilled(Object.PurchaseOrder) Then
			For Each CurRow In Object.Goods Do
				If Not ValueIsFilled(CurRow.PurchaseOrder) Then
					CurRow.PurchaseOrder = Object.PurchaseOrder;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterUploadingSelfEmployedReceipt(CashRegisterReceiptData, AdditionalParameters) Export

	AfterUploadingSelfEmployedReceiptOnServer(CashRegisterReceiptData);
	FilesOperationsClient.NotificationProcessing(ThisObject, "Write_File");

EndProcedure

&AtServer
Procedure AfterUploadingSelfEmployedReceiptOnServer(Receipt)

	CashServerLocalization.SetStatusOfUploadingReceipts(ThisObject);

EndProcedure

&AtClientAtServerNoContext
Function DataToFillInWriteOFFAttributeForExpenses(BusinessOperation, OptionForRegisteringServiceReceiptDocuments)
	
	FillingData = New Structure;
	
	InvoicingOperations = New Array;
	InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"));
	InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
	
	ThisIsInvoiceForGoods = InvoicingOperations.Find(BusinessOperation) <> Undefined;
	
	ThisIsInvoiceForServicesAndWorks = ThisIsInvoiceForGoods 
		And OptionForRegisteringServiceReceiptDocuments = PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced");
	
	FillingData.Insert("ThisIsInvoiceForGoods", ThisIsInvoiceForGoods);
	FillingData.Insert("ThisIsInvoiceForServicesAndWorks", ThisIsInvoiceForServicesAndWorks);
	
	Return FillingData;
	
EndFunction


&AtClientAtServerNoContext
Function StructureOfActionsONChangesInItemList(Form, CurrentRow)
	
	Object = Form.Object;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object,
		Form.WarehouseGroup_, , ,"ToExpenseAs"));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If Form.UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = Form.SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
		BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters",
		CurrentRow.Warehouse, Form.SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(Form, StructureOfActions);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		Form.FormName, "Goods"));
	StructureOfActions.Insert("FillInServiceDetailsForPurpose");
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision",
		DataToFillInWriteOFFAttributeForExpenses(Object.BusinessOperation,
		Form.OptionForRegisteringServiceReceiptDocuments));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", Form.CacheQualityControl);
	
	Return StructureOfActions;

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	ElsIf Item.Name = "sh_ShamsiInput_IncomingDocumentDate" Then
		IncomingDocumentDateOnChange(Items.IncomingDocumentDate);
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

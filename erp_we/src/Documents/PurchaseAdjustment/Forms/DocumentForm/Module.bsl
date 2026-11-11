#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var PreviousRowDetails; //used to unlink the receipt line from the order line

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
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	ReadRightPurchase = AccessRight("Read", Metadata.Documents.VendorInvoice);
	ReadRightServicesAndOtherAssets = AccessRight("Read", Metadata.Documents.VendorInvoiceServicesAndAssets);
	
	SetHeadingIncomeExpenseItem();
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", Object.DocumentBasis);
	OptionsForSelection.Insert("DocumentDate", Object.Date);
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", Object.DocumentBasis);
	SetupParameters = Documents.PurchaseAdjustment.AccountingAccountSettings_(OptionsForSelection);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject, "Object.Goods.Purpose");
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;

	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	CalculateFinalRevenueFigures(ThisForm);
	SetAvailabilityOfClipboardCommands();
	
	EstablishVisibilityOfRNPTQuantity();
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents
	
	OptionOfExecutionOfContractOfPurchases = PurchasesServer.GetVariantOfProcurementContract(Object.Contract);
	OptionForRegisteringServiceReceiptDocuments = PurchasesServer.GetVariantOfRegistrationOfDocumentsForAdmissionToServices(Object.Contract);
	
	ArrayOfElementsCCDNumber = New Array;
	ArrayOfElementsCCDNumber.Add("GoodsCCDNumber");
	ArrayOfElementsCCDNumber.Add("DiscrepanciesCCDNumber");
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, ArrayOfElementsCCDNumber, AdjustmentOfPurchaseOfOtherAssetServices);

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
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", Object.DocumentBasis);
	OptionsForSelection.Insert("DocumentDate", Object.Date);
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", Object.DocumentBasis);
	SetupParameters = Documents.PurchaseAdjustment.AccountingAccountSettings_(OptionsForSelection);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	OnReadCreateAtServer();

	CalculateFinalRevenueFigures(ThisForm);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)

	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);

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
	
	CalculateFinalRevenueFigures(ThisForm);
	
	DiscrepanciesAreUsed = 
		(Object.AdjustmentKind <> PredefinedValue("Enum.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated")
		And Object.AdjustmentKind <> PredefinedValue("Enum.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated"));
		
	If DiscrepanciesAreUsed And Not DiscrepanciesAreRelevant Then
		
		Cancel = True;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes,	NStr("vi = 'Điền lại';
														|ru = 'Перезаполнить';
														|en = 'Refill'; fa = 'پرکردن مجدد';
														|it = 'Ricompilare';
														|pl = 'Refill';
														|tr = 'Yeniden doldur'"));
		ButtonsList.Add(DialogReturnCode.Cancel,NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Cancel';
													|tr = 'İptal'"));
		
		ShowQueryBox(
			New CallbackDescription("BeforeRecordingShowQuestionFillInDiscrepancies", ThisObject, AdditionalParameters),
			NStr("vi = 'Phần bảng ""Hàng hóa"" đã thay đổi. Điền lại chênh lệch?';
				|ru = 'Табличная часть ""Товары"" была изменена. Перезаполнить расхождения?';
				|en = 'The Goods table was changed. Refill the discrepancies?'; fa = 'The Goods table was changed. Refill the discrepancies?';
				|it = 'La parte tabulare ""Merci"" è stata modificata. Ricompilare le discrepanze?';
				|pl = 'Sekcja tabelaryczna ""Wiersze pozycji"" została zmieniona. Wypełnić odchylenie ponownie?';
				|tr = '""Ürünler"" tablo kısmı değiştirilmiştir. Tutarsızlıklar yeniden doldurulsun mu?'"),
			ButtonsList,
			,
			DialogReturnCode.Yes);
		Return;
		
	ElsIf WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		AskQuestionsWhenConducting(WriteParameters);
		
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure AskQuestionsWhenConducting(WriteParameters)
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters,,True);
	
EndProcedure

&AtClient
Procedure BeforeRecordingShowQuestionFillInDiscrepancies(Response, AdditionalParameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckForPromiscuity = False;
	Notification = New CallbackDescription("BeforeRecordingCheckPossibilityOfFillingInTablePart",
		ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure BeforeRecordingCheckPossibilityOfFillingInTablePart(Result, AdditionalParameters) Export
	
	If Result Then
		
		FillInTheDiscrepanciesServer();
		ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
		
	EndIf;
	
	Items.GroupPages.CurrentPage = Items.DiscrepancyGroup;
	
	WriteParameters = AdditionalParameters.WriteParameters;
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		AskQuestionsWhenConducting(WriteParameters);
	Else
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters,,True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	UpdateServiceDetailsOfTableParts();
	UpdateCostGroups();
	SetAvailabilityOfItemsByStatusServer();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	GenerateHeaderForReportAdjustmentsToProcessor();
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Discrepancies);
	
	UpdateTextDocumentsBasedOn();
	
	UnlockFormDataForEdit();
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "ChangedStatusDependentBankingDetails"
		And Parameter.UUID = UUID Then
		If Object.Approved Then
			Object.Approved = False;
		EndIf;
		AttachIdleHandler("Attachable_WhenChangingDetailsDependingOnStatus", 0.1, True);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	If EventName = "UpdateInformationSecurityDocumentAfterFillingItOut"  And Parameter.Find(Object.Ref) <> Undefined Then
		ThisForm.Read();
	EndIf; 
	
	
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
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
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.PurchaseAdjustment.Form.SelectionOfGoodsFromOrderForm" Then
		ProcessingProductSelectionFromOrder(ValueSelected.GoodsAddressInStorage);
	ElsIf ChoiceSource.FormName = "Document.PurchaseAdjustment.Form.ChoiceFormOfCorrectedDocument" Then
		ProcessingSelectionOfDocumentBeingCorrected(ValueSelected);
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		UpdateTextDocumentsBasedOn();
	ElsIf ChoiceSource.FormName = "Document.PurchaseAdjustment.Form.PurchaseDocumentsPickForm" Then
		AddAcquisitionDocumentToDebtAdjustmentTable(ValueSelected);
	ElsIf TypeOf(ValueSelected) = Type("DocumentRef.VendorInvoice")
		Or TypeOf(ValueSelected) = Type("DocumentRef.VendorInvoiceServicesAndAssets")
		Or TypeOf(ValueSelected) = Type("DocumentRef.SubcontractorReport2_5")
		Then
		ProcessingDocumentSelectionViaServer(ValueSelected);
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		ProcessSelectionOfCCDNumber(ValueSelected);
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("DocumentBasis", Object.DocumentBasis);
	
	Notify("Write_PurchaseAdjustment", WriteParameters, Object.Ref);
	
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	GenerateHeaderForReportAdjustmentsToProcessor();
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
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

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage.Name = "MainGroup3" Then
		ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisForm);
	EndIf;
	
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
	
	If Object.Discrepancies.Count() = 0 Then
		SetUpRNPTAccounting();
		
		Return;
	EndIf;
	
	AdjustmentPeriod_ = ?(ValueIsFilled(Object.Date), Object.Date, CommonClient.SessionDate());
	ReceiptPeriod   = GeneralPurposeTMServerCall.ObjectAttributeValue(Object.DocumentBasis, "Date");
	
	NewValue = ReceiptPeriod < BegOfMonth(AdjustmentPeriod_);
	
	If LastPeriodAdjustment <> NewValue And TypeOf(Object.DocumentBasis)= Type("DocumentRef.VendorInvoice") Then
		
		If LastPeriodAdjustment Then
			QueryText = NStr("vi = 'Điều chỉnh được chuyển sang một tháng với chứng từ-cơ sở. Điền lại chênh lệch?';
							|ru = 'Корректировка перенесена в один месяц с документом-основанием. Перезаполнить расхождения?';
							|en = 'Adjustment is transferred to the same month as base document. Fill in the discrepancies again?'; fa = 'Adjustment is transferred to the same month as base document. Fill in the discrepancies again?';
							|it = 'La rettifica rinviata allo stesso mese del documento-causale. Ricompilare le discrepanze?';
							|pl = 'Zapis korygujący jest przeniesiony w jednym miesiącu z dokumentem podstawą. Wypełnić odchylenie ponownie?';
							|tr = 'Düzenleme, temel belge ile aynı aya taşınmıştır. Tutarsızlıklar yeniden doldurulsun mu?'");
		Else
			QueryText = NStr("vi = 'Điều chỉnh chuyển sang tháng chênh với chứng từ cơ sở. Điền lại chênh lệch?';
							|ru = 'Корректировка перенесена в месяц, отличный от документа-основания. Перезаполнить расхождения?';
							|en = 'Adjusting entry is transferred to the month different from the base document. Fill in the discrepancies again?'; fa = 'Adjusting entry is transferred to the month different from the base document. Fill in the discrepancies again?';
							|it = 'La rettifica rinviata al mese diverso da quello del documento-causale. Ricompilare le discrepanze?';
							|pl = 'Zapis korygujący jest przeniesiony do miesiąca, różniącego się od dokumentu podstawy. Wypełnić odchylenie ponownie?';
							|tr = 'Düzenleme, temel belgeden başka bir aya taşınmıştır. Tutarsızlıklar yeniden doldurulsun mu?'");
		EndIf;
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.OK, NStr("vi = 'Điền lại';
													|ru = 'Перезаполнить';
													|en = 'Refill'; fa = 'پرکردن مجدد';
													|it = 'Ricompilare';
													|pl = 'Refill';
													|tr = 'Yeniden doldur'"));
		ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Cancel';
														|tr = 'İptal'"));
		
		ShowQueryBox(New CallbackDescription("DateOnChangeCompletion", ThisObject, New Structure("NewValue", NewValue)), QueryText, ButtonsList);
		
	Else
		DateOnChangeServer();
	EndIf;
	
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	NewValue = AdditionalParameters.NewValue;
	
	Response = QuestionResult;
	If Response = DialogReturnCode.OK Then
		LastPeriodAdjustment = NewValue;
		
		CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
		CheckParameters.CheckForPromiscuity = False;
		Notification = New CallbackDescription("DateOfChangeAfterVerification", ThisObject);
		ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
		
		DateOnChangeServer();
	ElsIf Response = DialogReturnCode.Cancel Then
		Object.Date = GeneralPurposeTMServerCall.ObjectAttributeValue(Object.Ref, "Date");
	EndIf;
	
EndProcedure
	
&AtClient
Procedure BaseDocumentPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		
		ShowValue(Undefined, Object.DocumentBasis);
		
	Else
		
		TypesList = New ValueList;
		BasisType = TypeOf(Object.DocumentBasis);
		If BasisType = Type("DocumentRef.SubcontractorReport2_5")Then
			TypesList.Add(Type("DocumentRef.SubcontractorReport2_5"));
		Else
			If ReadRightPurchase Then
				TypesList.Add(Type("DocumentRef.VendorInvoice"));
			EndIf;
			If ReadRightServicesAndOtherAssets Then
				TypesList.Add(Type("DocumentRef.VendorInvoiceServicesAndAssets"));
			EndIf;
		EndIf;
		CallbackDescription = New CallbackDescription("BaseDocumentPresentationClickCompletion", ThisObject);
		ShowChooseFromList(CallbackDescription, TypesList, Items.BaseDocumentPresentation);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BaseDocumentPresentationClickCompletion(ValueSelected, Var_Parameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	ArrayOfBusinessTransactions = New Array;
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier"));
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery"));
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit"));
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit"));
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
	
	StructureFilter = New Structure;
	StructureFilter.Insert("Posted", True);
	StructureFilter.Insert("BusinessOperation", ArrayOfBusinessTransactions);
	
	If ValueSelected.Value = Type("DocumentRef.VendorInvoice") Then
		ChoiceFormName = "Document.VendorInvoice.ChoiceForm";
	ElsIf ValueSelected.Value = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		ChoiceFormName = "Document.VendorInvoiceServicesAndAssets.ChoiceForm";
	ElsIf ValueSelected.Value = Type("DocumentRef.SubcontractorReport2_5") Then
		ChoiceFormName = "Document.SubcontractorReport2_5.ChoiceForm";
		StructureFilter.Insert("BusinessOperation",PredefinedValue("Enum.BusinessTransactions.ProductionByToller2_5"));
	EndIf;
	
	OpenForm(
		ChoiceFormName,
		New Structure("Filter", StructureFilter),
		ThisForm);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	ExpenseItemOnChangeServer();
	
EndProcedure

&AtServer
Procedure ExpenseItemOnChangeServer()
	ParametersForAccessibility = New Structure("BusinessOperation, DocumentBasis", Object.AdjustmentKind, Object.DocumentBasis);
	SetupParameters = Documents.PurchaseAdjustment.AccountingAccountSettings_(ParametersForAccessibility);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);	
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	IncomeItemOnChangeServer();
	
EndProcedure

&AtServer
Procedure IncomeItemOnChangeServer()
	ParametersForAccessibility = New Structure("BusinessOperation, DocumentBasis", Object.AdjustmentKind, Object.DocumentBasis);
	SetupParameters = Documents.PurchaseAdjustment.AccountingAccountSettings_(ParametersForAccessibility);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer(CachedValues);
	
	DiscrepanciesAreRelevant = False;
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
	DiscrepanciesAreRelevant = False;
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure SubmissionOfTheDocumentOfTheBasisOfTheActOfDiscrepanciesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.DiscrepancyReportFollowingReceiptBaseDocument) Then
		ShowValue(,Object.DiscrepancyReportFollowingReceiptBaseDocument);
	EndIf;
	
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
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
	If Object.Currency <> CurrentCurrency
		Or Object.ARAPCurrency <> CurCurrencyOfSettlements Then
		CurrentCurrency = Object.Currency;
		CurCurrencyOfSettlements =  Object.ARAPCurrency;
		ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification);
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesReceivedServer(Object);
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(
		ThisObject,
		FormattedStringURL,
		StandardProcessing,
		RegistrationParameters);
		
	
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
Procedure OperationOnChange(Item)
	OperationOnChangeServer();
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationOnChangeServer();
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	PartnerOnChangeServer();
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	CounterpartyOnChangeServer();
EndProcedure

&AtClient
Procedure TextSetUpRecordOfAssetsInComplAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
EndProcedure

&AtClient
Procedure TextSetUpRecordOfLiabilitiesInComplAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
EndProcedure

&AtClient
Procedure PresentationOfCorrectedDocumentClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.CorrectedDocument) Then
		ShowValue(, Object.CorrectedDocument);	
	Else
		PickUpDocumentToBeCorrected();		
	EndIf;
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If Items.Goods.CurrentData <> Undefined Then
		
		If Field = Items.GoodsPurchaseOrder Then
			
			If ValueIsFilled(CurrentRow.PurchaseOrder) Then
				ShowValue(, CurrentRow.PurchaseOrder);
			EndIf;
			
		EndIf;
		GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);		
		PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts", NStr("vi = 'Nhà cung cấp';
																										|ru = 'Поставщик';
																										|en = 'Vendor'; fa = 'تأمین‌کننده';
																										|it = 'Fornitore';
																										|pl = 'Vendor';
																										|tr = 'Tedarikçi'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters, Copy);
				
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow And Not Copy Then
		
		If Object.ReceiptUnderOrders Then
			If ValueIsFilled(Object.DocumentBasis)
				And TypeOf(Object.DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
				OrderDocument = PredefinedValue("Document.PurchaseOrder.EmptyRef");
			Else
				OrderDocument = Undefined;
			EndIf;
			ReceiptUnderSeveralOrders = False;
			For Each LineProducts_ In Object.Goods Do
				If LineProducts_.LineNumber = CurrentRow.LineNumber Then
					Continue;
				EndIf;
				If ValueIsFilled(OrderDocument) And LineProducts_.PurchaseOrder <> OrderDocument Then
					ReceiptUnderSeveralOrders = True;
					Break;
				Else
					OrderDocument = LineProducts_.PurchaseOrder;
				EndIf;
			EndDo;
			
			If Not ReceiptUnderSeveralOrders Then
				CurrentRow.PurchaseOrder = OrderDocument;
			EndIf;
			
		EndIf;
		
		If Not WarehouseGroup_ Then
			CurrentRow.Warehouse = Object.Warehouse;
		EndIf;
		
		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
			CurrentRow.ToExpenseAs = True;
		EndIf;
		If SubcontractorReportAdjustment Then
			CurrentRow.Department = FoundationDivision;
			CurrentRow.LineOfBusiness = DirectionOfActivityOfFoundation;
		EndIf;
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Goods");
		
		If AdjustmentOfPurchaseOfOtherAssetServices Then
			FillInOfficialTraceabilityAttributesInProductLine(CurrentRow);
		EndIf;
		
	EndIf;
	
	//Setting up accounting accounts 
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData <> Undefined Then
		GoodsAtEndOfEditingOnServer(CurrentData.GetID(), CachedValues);
		
		If Not CancelEdit Then
			LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
			WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
			TotalWarehouses_ = WarehouseTable.Count();
			WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer(CurrentID, CachedValues)
	SetDefaultCostGroupNumber(CurrentID);
	FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(CurrentID, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)

	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters, True);

	If SeriesStatusesNeedToBeUpdated  Then

		GoodsAfterDeleteRowServer(CachedValues); // server call

	EndIf;

	If SeriesStatusesNeedToBeUpdated Then

		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters);

	EndIf;
	
	DiscrepanciesAreRelevant = False;
	CalculateFinalRevenueFigures(ThisForm);
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
			
		ElsIf Item.CurrentItem.Name = "GoodsCCDNumber"
			And Not AdjustmentOfPurchaseOfOtherAssetServices Then
			PurchasesClient.FillInListOfCCDNumberSelection(
			Items.Goods.CurrentData, 
			Items.GoodsCCDNumber.ChoiceList);
	EndIf;
EndProcedure

&AtClient
Procedure GoodsExpenseGroupClearing(Item, StandardProcessing)
	CurrentData = Items.Goods.CurrentData;
	
	CurrentData.CostGroupNumber = 0;
	CurrentData.ExpenseGroup = "";
	Return;
	
EndProcedure

&AtClient
Procedure GoodsExpenseGroupOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Goods.CurrentData;
	If GroupingOfBaseCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		And ValueIsFilled(CurrentData.ProductionStage) Then
		ShowValue(, CurrentData.ProductionStage);
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure GoodsExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	If Items.Goods.SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng mà sẽ điền nhóm chi phí.';
							|ru = 'Необходимо выбрать строки, для которых будет заполнена группа затрат.';
							|en = 'Select the lines for which a cost group will be populated.'; fa = 'Select the lines for which a cost group will be populated.';
							|it = 'È necessario selezionare le righe per le quali sarà compilato il gruppo delle spese.';
							|pl = 'Należy wybrać wiersze, dla których będzie wypełniona grupa kosztów.';
							|tr = 'Maliyet grubunun doldurulacağı satırları seçmelisiniz.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("GroupCosts",         GroupingOfBaseCosts);
	FormParameters.Insert("CostGroupNumber",         Items.Goods.CurrentData.CostGroupNumber);
	FormParameters.Insert("CostGroupStorageAddress", PutCostGroupDataInStorage());
	
	FormParameters.Insert(
		"CostGroupFields_",
		ProcessingByThirdPartiesClientServer.ListOfCostGroupFieldsInProcessorSReport(GroupingOfBaseCosts));
	
	CallbackDescription = New CallbackDescription("TableCostGroupStartOfSelectionCompletion", ThisObject);
	OpenForm("CommonForm.SelectExpenseGroupTransferringToProcessing", FormParameters,,,,, CallbackDescription);
	Return;
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	
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
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	If AdditionalParameters.Property("ClearActionStructure") Then
		StructureOfActions = New Structure;
	Else
		StructureOfActions = AdditionalParameters.StructureOfActions;
	EndIf;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	If AdjustmentOfPurchaseOfOtherAssetServices Then
		FillInOfficialTraceabilityAttributesInProductLine(CurrentRow);
	Else
		StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	EndIf;
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
		StructureOfActions,
		ThisObject);
		
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.AdjustmentKind,
		Object.Organization,
		Object.Department);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillingOutAppointment = New Structure();
	If CurrentRow.Products <> ItemBeforePartnerItemChanges Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, FillingOutAppointment);
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, FillingOutAppointment, CachedValues);
	
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * CurrentRow - FormDataCollectionItem, FormDataStructure, FormDataTreeItem - 
// * CallbackDescription - CallbackDescription - 
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("CurrentRow");
	Result.Insert("CallbackDescription");
	Return Result;
	
EndFunction

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
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	If AdjustmentOfPurchaseOfOtherAssetServices Then
		FillInOfficialTraceabilityAttributesInProductLine(CurrentRow);
	Else
		StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	EndIf;
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
		
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
		StructureOfActions,
		ThisObject);
		
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.AdjustmentKind,
		Object.Organization,
		Object.Department);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision",
		DataToFillInWriteOFFAttributeForExpenses(Object.BusinessOperation, OptionOfExecutionOfContractOfPurchases,
			OptionForRegisteringServiceReceiptDocuments));
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Goods");
	
	CalculateFinalRevenueFigures(ThisForm);
	
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
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalRevenueFigures(ThisForm);
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
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
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
Procedure GoodsCountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count", ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("Price",		 CurrentData.Price);
	CurrentRow.Insert("Sum",		 CurrentData.Sum);
	CurrentRow.Insert("VATRate",	 CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",	 CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",	 CurrentData.AmountIncludingVAT);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisForm);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow, , "Count");
	CalculateFinalRevenueFigures(ThisForm);
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count", ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages", CurrentData.NumberOfPackages);
	CurrentRow.Insert("Price",				 CurrentData.Price);
	CurrentRow.Insert("Sum",				 CurrentData.Sum);
	CurrentRow.Insert("VATRate",			 CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",			 CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",			 CurrentData.AmountIncludingVAT);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow, , "Count");
	CalculateFinalRevenueFigures(ThisForm);
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count", ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages", CurrentData.NumberOfPackages);
	CurrentRow.Insert("Price",				 CurrentData.Price);
	CurrentRow.Insert("Sum",				 CurrentData.Sum);
	CurrentRow.Insert("VATRate",			 CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",			 CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",			 CurrentData.AmountIncludingVAT);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow, , "Count");
	CalculateFinalRevenueFigures(ThisForm);
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count", ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages", CurrentData.NumberOfPackages);
	CurrentRow.Insert("Price",				 CurrentData.Price);
	CurrentRow.Insert("Sum",				 CurrentData.Sum);
	CurrentRow.Insert("VATRate",			 CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",			 CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",			 CurrentData.AmountIncludingVAT);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow, , "Count");
	CalculateFinalRevenueFigures(ThisForm);

	SpecifiedVATRate = CurrentRow.VATRate;

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
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPurchaseOrderOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If ValueIsFilled(CurrentRow.PurchaseOrder) Then
		CurrentRow.SalesOpportunity = GetDealOnOrderToSupplier(CurrentRow.PurchaseOrder);
	Else
		CurrentRow.SalesOpportunity = PredefinedValue("Catalog.SalesOpportunitiesToCustomer.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsToExpenseAsOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "Object.Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,, "ToExpenseAs"));
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department, ThereIsWriteOffForExpenses", Object.Department, True));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Warehouse, SeriesSpecificationParameters));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow <> Undefined
		And Object.ReceiptUnderOrders And Object.Goods.Count()>0 Then
		If CurrentRow.RowCode = 0 Then
			CurrentRow.OrderDiscrepancy_3 = 1;
		Else
			CurrentRow.OrderDiscrepancy_3 = 0;
		EndIf;
	EndIf;
	
	DiscrepanciesAreRelevant = False;
	If AdjustmentOfPurchaseOfOtherAssetServices Then
		FillInOfficialTraceabilityAttributesInProductLine(CurrentRow);
	EndIf;
	
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
Procedure GoodsCCDNumberOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCCDNumberType", FillParameters);
	Actions.Insert("FillInCountryOfOriginForCCDNumber", FillParameters);
	
	If AdjustmentOfPurchaseOfOtherAssetServices Then
		FillInOfficialTraceabilityAttributesInProductLine(CurrentData);
	Else
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			Actions,
			"Warehouse",
			True);
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
		
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.DocumentCurrency = Object.Currency;
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
	If AdjustmentOfPurchaseOfOtherAssetServices Then
		FillInOfficialTraceabilityAttributesInProductLine(CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	If Items.Goods.CurrentData <> Undefined Then
		
		ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
		ProductsClient.UpdateCachedValuesToAccountForSeries(
					Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	FillPropertyValues(PreviousRowDetails, Items.Goods.CurrentData);
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsAssignmentWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
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
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDiscrepancies

&AtClient
Procedure DiscrepanciesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentRow = Items.Discrepancies.CurrentData;
	
	If Field = Items.DiscrepanciesPurchaseOrder Then
		
		If ValueIsFilled(CurrentRow.PurchaseOrder) Then
			ShowValue(Undefined, CurrentRow.PurchaseOrder);
		EndIf;
		
	EndIf;
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
EndProcedure

&AtClient
Procedure DiscrepanciesOnActivateCell(Item)
	
	TableRow = Items.Discrepancies.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem <> Undefined
		And Item.CurrentItem = Items.DiscrepanciesPostingOption Then
		
		ChoiceList = Items.DiscrepanciesPostingOption.ChoiceList;
		ChoiceList.Clear();
		
		TypesOfItemAdjustments = New Array;
		TypesOfItemAdjustments.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		TypesOfItemAdjustments.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		
		ThisIsProductNotWrittenOffForExpenses = TypesOfItemAdjustments.Find(TableRow.ItemsType) <> Undefined And Not TableRow.ToExpenseAs;
		
		If TableRow.NumberOfPackages > 0 Then
			If Not BasisDiscrepancyCertificateAfterReceiving And TableRow.AmountIncludingVAT <> 0 Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs"));
			EndIf;
			If Not ThisIsProductNotWrittenOffForExpenses Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost"));
			ElsIf UninvoicedReceiptDocumentIsUsed
				And ThisIsProductNotWrittenOffForExpenses Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners"));
			ElsIf TableRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncludeDuringPhysicalInventoryCount"));
			Else
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock"));
			EndIf;
		ElsIf TableRow.NumberOfPackages < 0 Then
			If Not BasisDiscrepancyCertificateAfterReceiving And TableRow.AmountIncludingVAT <> 0 Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome"));
			EndIf;
			If Not ThisIsProductNotWrittenOffForExpenses Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost"));
			ElsIf UninvoicedReceiptDocumentIsUsed
				And ThisIsProductNotWrittenOffForExpenses Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners"));
			ElsIf TableRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseIncludeDuringPhysicalInventoryCount"));
			Else
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock"));
			EndIf;
		ElsIf TableRow.NumberOfPackages = 0 And (TableRow.AmountIncludingVAT > 0
			Or (TableRow.AmountIncludingVAT = 0 And TableRow.VATAmount > 0)) Then
			If Not BasisDiscrepancyCertificateAfterReceiving
				And Not TableRow.AmountIncludingVAT = 0 Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs"));
			EndIf;	
			If Not UninvoicedReceiptDocumentIsUsed Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost"));
			EndIf;
			If UninvoicedReceiptDocumentIsUsed Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners"));
			EndIf;
		ElsIf TableRow.NumberOfPackages = 0 And (TableRow.AmountIncludingVAT < 0
			Or (TableRow.AmountIncludingVAT = 0 And TableRow.VATAmount < 0)) Then
			If Not BasisDiscrepancyCertificateAfterReceiving
				And Not TableRow.AmountIncludingVAT = 0 Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome"));
			EndIf;
			If Not UninvoicedReceiptDocumentIsUsed Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost"));
			EndIf;
			If UninvoicedReceiptDocumentIsUsed Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners"));
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscrepanciesPostingOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Discrepancies.CurrentData;
	
	If TypeOf(ValueSelected) = Type("EnumRef.OptionsOfPostingReceiptAdjustingEntries") Then
		
		CurrentRow.PostingOption = ValueSelected;
		
	Else
		
		CurrentRow.PostingOption = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
		
	EndIf;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClient
Procedure DiscrepanciesDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DiscrepanciesDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure DiscrepanciesDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DiscrepanciesAmountARAPOnChange(Item)
	CurrentData = Items.Discrepancies.CurrentData;
	If CurrentData <> Undefined Then
		CurrentData.AmountVATARAP = 0;
	EndIf;
EndProcedure

&AtClient
Procedure DiscrepanciesExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DiscrepanciesExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure DiscrepanciesOnStartEdit(Item, NewRow, Copy)
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Discrepancies, ThisObject);
	CurrentRow = Items.Discrepancies.CurrentData;
	If NewRow And Not Copy Then
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Discrepancies");
	EndIf;	
EndProcedure

&AtClient
Procedure DiscrepanciesToExpenseAsOnChange(Item)
	
	CurrentData = Items.Discrepancies.CurrentData;
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "Object.Discrepancies");
	
EndProcedure

&AtClient
Procedure DiscrepanciesToControlQualityOnChange(Item)
	
	CurrentData = Items.Discrepancies.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscrepanciesQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.Discrepancies.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersARAPAdjustment

&AtClient
Procedure ARAPAdjustmentSelection(Item, RowSelected, Field, StandardProcessing)
	If Field = Items.ARAPAdjustmentDocumentAcquisitions
		Or Field = Items.ARAPAdjustmentARAPObject
		Or Field = Items.ARAPAdjustmentAmountIncludingVAT Then
		ShowValue(, Items.ARAPAdjustment.CurrentData.DocumentAcquisitions);
	EndIf;
EndProcedure

&AtClient
Procedure ARAPAdjustmentBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure ARAPAdjustmentOnEditEnd(Item, NewRow, CancelEdit)
	If Not CancelEdit Then
		ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	EndIf;
EndProcedure

&AtClient
Procedure ARAPAdjustmentAdjustmentSumOnChange(Item)
	
	CurrentRow = Items.ARAPAdjustment.CurrentData;
	CurrentRow.SumOfVATAdjustments =
		PriceManagementSystemClientServer.CalculateVATAmount(
			CurrentRow.AdjustmentSum, 
			CurrentRow.VATRate,
			True,
			Object.VATTaxation);
	CurrentRow.AmountARAP = 0;
	
EndProcedure

&AtClient
Procedure ARAPAdjustmentVATRateOnChange(Item)
	
	CurrentRow = Items.ARAPAdjustment.CurrentData;
	
	CurrentRow.VATAmount =
		PriceManagementSystemClientServer.CalculateVATAmount(
			CurrentRow.AmountIncludingVAT, 
			CurrentRow.VATRate,
			True,
			Object.VATTaxation);
			
	CurrentRow.SumOfVATAdjustments =
		PriceManagementSystemClientServer.CalculateVATAmount(
			CurrentRow.AdjustmentSum, 
			CurrentRow.VATRate,
			True,
			Object.VATTaxation);
	
	CurrentRow.AmountARAP = 0;
	
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
Procedure FillInBySourceData(Command)
	
	If Not ValueIsFilled(Object.DocumentBasis) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Chứng từ-cơ sở""';
				|ru = 'Поле ""Документ-основание"" не заполнено';
				|en = '""Base document"" is required'; fa = '""Base document"" is required';
				|it = 'Поле ""Документ-основание"" не заполнено';
				|pl = '""Base document"" is required';
				|tr = '""Temel belge"" alanı doldurulmamış'"),
			,
			"BaseDocumentPresentation");
		Return;
	EndIf;
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckForPromiscuity = False;
	CheckParameters.TabularSection = Object.Goods;
	Notification = New CallbackDescription("FillInBySourceDataCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInAccordingToDiscrepancyCertificate(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckForPromiscuity = False;
	CheckParameters.TabularSection = Object.Goods;
	Notification = New CallbackDescription("FillInAccordingToDiscrepancyCertificateCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInAccordingToDiscrepancyCertificateCompletion(Result, AdditionalParameters) Export 
	
	FillInAccordingToDiscrepancyCertificateServer();
	
EndProcedure

&AtClient
Procedure SelectGoodsFromOrder(Command)
	
	DetailsOfFoundationDocument = DetailsOfFoundationDocument(Object.DocumentBasis);
	
	ArrayOfStringCodes = New Array;
	For Each TSRow In Object.Goods Do
		
		If TSRow.RowCode <> 0 And ValueIsFilled(TSRow.PurchaseOrder) Then
			ArrayOfStringCodes.Add(New Structure("RowCode,PurchaseOrder", TSRow.RowCode, TSRow.PurchaseOrder));
		EndIf;
		
	EndDo;
	
	PickingParameters = New Structure;
	PickingParameters.Insert("DocumentCurrency", Object.Currency);
	PickingParameters.Insert("Document", Object.Ref);
	PickingParameters.Insert("DocumentBasis", Object.DocumentBasis);
	PickingParameters.Insert("Warehouse", Object.Warehouse);
	PickingParameters.Insert("ArrayOfStringCodes", ArrayOfStringCodes);
	PickingParameters.Insert("Partner", Object.Partner);
	PickingParameters.Insert("Counterparty", Object.Counterparty);
	PickingParameters.Insert("Contract", Object.Contract);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Terms", Object.Terms);
	PickingParameters.Insert("ARAPCurrency", Object.ARAPCurrency);
	PickingParameters.Insert("VATTaxation", DetailsOfFoundationDocument.VATTaxation);
	PickingParameters.Insert("PriceIncludesVAT", DetailsOfFoundationDocument.PriceIncludesVAT);
	PickingParameters.Insert("Date", Object.Date);
	
	OpenForm(
		"Document.PurchaseAdjustment.Form.SelectionOfGoodsFromOrderForm",
		PickingParameters,
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.FieldNameQuantity = ?(Not NumberOfPackagesIsUsed,"Count","NumberOfPackages");
	
	AdditionalParameters = AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(FormTable.CurrentData);
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
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
		PricesCalculated = FillThePricesByTermsOfSalesServer(ErrorText);
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		DiscrepanciesAreRelevant = False;
		
	EndIf;
	
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
		PricesCalculated = FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPricesServer(VendorPriceKind);
		PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, VendorPriceKind);
		DiscrepanciesAreRelevant = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLines(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, Object.Goods, NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'"), SelectedRows) Then
		FilterStructure1 = New Structure("SelectGroup,IsFolder", PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"), False);
		ParametersStructure = New Structure("Filter,GroupOfWarehouses", FilterStructure1, Object.Warehouse);
		
		AdditionalParameters = New Structure("SelectedRows", SelectedRows);
		CallbackDescription = New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm("Catalog.Warehouses.ChoiceForm", 
			ParametersStructure,
			ThisForm,,,,
			CallbackDescription,
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
        DiscrepanciesAreRelevant = False;
    EndIf;

EndProcedure

&AtClient
Procedure FillInTheDiscrepancies(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckForPromiscuity = False;
	CheckParameters.TabularSection = Object.Discrepancies;
	Notification = New CallbackDescription("FillInTheDiscrepanciesCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure SetRecordingOptions(Command)
	
	SettingsForReflectionOptions = ManagingReflectionOptions();
	SettingsForReflectionOptions.OptionSelectionIsInteractive = True;
	
	DefineGroupsOfReflectionOptionsToSelect(Object.Discrepancies, SettingsForReflectionOptions);
	
	If Not SettingsForReflectionOptions.ThereAreLinesToChange Then
		ShowMessageBox(Undefined, NStr("vi = 'Không có dòng, trong đó có thể thay đổi phương án hiển thị.';
										|ru = 'Нет строк, в которых доступно изменение варианта отражения.';
										|en = 'No lines in which posting options can be changed.'; fa = 'No lines in which posting options can be changed.';
										|it = 'Non ci sono righe nelle quali fosse disponibile la modifica della variante di visualizzazione.';
										|pl = 'Brak wierszy, w których jest dostępna zmiana wariantu odzwierciedlenia.';
										|tr = 'Yansıtma seçeneği değişikliğinin mevcut olduğu hiçbir satır yoktur.'"));
		Return;
	EndIf;
	
	FillInReflectionOptionsForGroups(SettingsForReflectionOptions);
	SelectInteractivelyOptionsForReflectingAdjustmentsToImplementationsFragment(SettingsForReflectionOptions);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.PurchaseAdjustment.DocumentForm.Command.SelectGoods");
	
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
	FormParameters.Insert("Partner",         Object.Partner);
	FormParameters.Insert("Terms",      Object.Terms);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("Warehouse",           Object.Warehouse);
	FormParameters.Insert("Currency",          Object.Currency);
	FormParameters.Insert("Date",            Object.Date);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders",  True);
	FormParameters.Insert("HideManualDiscounts", True);
	
	EconomicOperationsOfSeparatePurchase = EconomicOperationsOfSeparatePurchase();
	
	If EconomicOperationsOfSeparatePurchase.Find(Object.BusinessOperation) <> Undefined Then
		FilterByProductType = New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
		FormParameters.Insert("FilterByProductType", FilterByProductType);
	ElsIf SubcontractorReportAdjustment Then
		FormParameters.Insert("FilterByProductType", ProductsClientServer.JobSelection(False));
		FormParameters.Insert("Department", FoundationDivision);
	Else
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False)));
	EndIf;
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisForm, UUID);
	
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
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
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
Procedure FillInTheItemByThePartnerSItemCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		FillInItemsFromTemporaryStorageServer(Result);
		
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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
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
Procedure FillInReasonForDebtAdjustment(Command)
	CallbackDescription = New CallbackDescription("InputReasonsForDebtAdjustmentCompletion", ThisObject);
	TitleOfInputForm = NStr("vi = 'Hãy nhập lý do điều chỉnh';
							|ru = 'Введите причину корректировки';
							|en = 'Enter adjustment reason'; fa = 'Enter adjustment reason';
							|it = 'Inserire motivo rettifica';
							|pl = 'Wprowadź przyczynę korekty';
							|tr = 'Düzeltme nedenini girin'");
	ShowInputString(CallbackDescription, , TitleOfInputForm, 500);
EndProcedure

&AtClient
Procedure PickUpDocumentsForDebtAdjustment(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Counterparty", Object.Counterparty);
	FormParameters.Insert("Currency", Object.Currency);
	FormParameters.Insert("ARAPCurrency", Object.ARAPCurrency);
	
	SelectedDocuments = New Array();
	For Each TableRow In Object.ARAPAdjustment Do
		SelectedDocuments.Add(TableRow.DocumentAcquisitions);
	EndDo;
	FormParameters.Insert("SelectedDocuments", SelectedDocuments);
	
	OpenForm("Document.PurchaseAdjustment.Form.PurchaseDocumentsPickForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure DistributeTotalAmountOfDebtAdjustmentToDocuments(Command)
	CallbackDescription = New CallbackDescription("EnteringAmountOfDebtAdjustmentCompletion", ThisObject);
	TitleOfInputForm = NStr("vi = 'Hãy nhập tổng số tiền điều chỉnh';
							|ru = 'Введите общую сумму корректировки';
							|en = 'Enter total adjustment amount'; fa = 'Enter total adjustment amount';
							|it = 'Inserire importo generale rettifica';
							|pl = 'Wprowadź ogólną kwotę korekty';
							|tr = 'Düzeltmenin toplam tutarını girin'");
	ShowInputNumber(CallbackDescription, 0, TitleOfInputForm, 31, 2);
EndProcedure

&AtClient
Procedure CalculateAmountOfDebtAdjustmentForInterest(Command)
	CallbackDescription = New CallbackDescription("EnteringDebtAdjustmentInterestCompletion", ThisObject);
	TitleOfInputForm = NStr("vi = 'Hãy nhập phần trăm điều chỉnh';
							|ru = 'Введите процент корректировки';
							|en = 'Enter adjustment interest'; fa = 'Enter adjustment interest';
							|it = 'Inserire percentuale rettifica';
							|pl = 'Wprowadź procent korekty';
							|tr = 'Düzeltme yüzdesini girin'");
	ShowInputNumber(CallbackDescription, 0, TitleOfInputForm, 5, 2);
EndProcedure

&AtClient
Procedure AllCorrections(Command)
	
	CorrectedDocument = CorrectedDocument();	
	
	DocumentCorrectionClient.OpenListOfFixes(CorrectedDocument, Object.Ref);	
	
EndProcedure

&AtClient
Procedure EditDocumentBeingCorrected(Command)
		
	PickUpDocumentToBeCorrected();
				
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

&AtClient
Function CorrectedDocument()
	
	CorrectedDocument = Undefined;
	
	If ValueIsFilled(Object.CorrectedDocument) Then
		CorrectedDocument = Object.CorrectedDocument;
	ElsIf Object.Posted Then
		CorrectedDocument = DocumentCorrectionServerCall.CorrectedDocument(Object.Ref);
	Else
		CorrectedDocument = Object.DocumentBasis;			
	EndIf;	
	
	Return CorrectedDocument;
	
EndFunction


&AtServer
Procedure SetConditionalAppearanceForArticlesAndAnalytics()

	InvoicingOperations = New ValueList;
	InvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	InvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToExpenseAs.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExpenseItem.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesDepartment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesToExpenseAs.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesExpenseItem.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesDimensionOfExpenses.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesAssetsLiabilitiesDimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesDimensionOfRevenue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operation");
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
	
	// only view if the service or job and the appointment is filled
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToExpenseAs.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = InvoicingOperations;

	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
		SelectionGroupAnd1 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(Enums.ItemsTypes.OperationService);
			
			ItemFilter.RightValue = ValueList;

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
			ItemFilter.LeftValue = New DataCompositionField("OptionOfExecutionOfContractOfPurchases");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.PurchaseRegistrationOptions.GoodsInTransit;
		
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// explanatory inscription, if the job is completed and the assignment is completed

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

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với hàng hóa/dịch vụ và công việc không có mục đích>';
													|ru = '<для товаров/услуг и работ без назначения>';
													|en = '<for goods/services and works without assignment>'; fa = '<for goods/services and works without assignment>';
													|it = '<per articoli/servizi e lavori senza assegnazione>';
													|pl = '<dla towarów/usług i prac bez przeznaczenia>';
													|tr = '< varış yeri olmayan mallar/hizmetler ve işler için'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	// explanatory inscription, if we do not write off work and expenses

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<khi ghi giảm vào chi phí>';
													|ru = '<при списании на расходы>';
													|en = '<when writing off as expenses>'; fa = '<when writing off as expenses>';
													|it = '<durante lo storno sulle spese>';
													|pl = '<przy wyksięgowaniu na rozchody>';
													|tr = '<gider yazılması>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	// the text of the expense analysis, if the item is not selected
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DimensionOfExpenses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn dạng chi phí>';
													|ru = '<выберите статью расходов>';
													|en = '<select an expense item>'; fa = '<select an expense item>';
													|it = '<selezionare la voce delle spese>';
													|pl = '<wybierz pozycję wydatków>';
													|tr = '<maliyet kalemini seçin>.'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	
	// Only view if the service or job and the appointment is filled (incl. Discrepancies).
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesToExpenseAs.Name);

	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
		SelectionGroupAnd1 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(Enums.ItemsTypes.OperationService);
			
			ItemFilter.RightValue = ValueList;

		SelectionGroupAnd2 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
			
			ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.Purpose");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
			
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// explanatory inscription, if the job is completed and the assignment is filled in (incl. Discrepancies)

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesExpenseItem.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesDimensionOfExpenses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với hàng hóa/dịch vụ và công việc không có mục đích>';
													|ru = '<для товаров/услуг и работ без назначения>';
													|en = '<for goods/services and works without assignment>'; fa = '<for goods/services and works without assignment>';
													|it = '<per articoli/servizi e lavori senza assegnazione>';
													|pl = '<dla towarów/usług i prac bez przeznaczenia>';
													|tr = '< varış yeri olmayan mallar/hizmetler ve işler için'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// explanatory inscription, if we do not write off work and expenses (incl. Discrepancies)

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesDimensionOfExpenses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<khi được ghi giảm vào chi phí / tài sản>';
													|ru = '<при списании на расходы/активы>';
													|en = '<while writing off as expenses/assets>'; fa = '<while writing off as expenses/assets>';
													|it = '<durante lo storno sulle spese/attivi>';
													|pl = '<podczas rozchodu na wydatki/aktywy>';
													|tr = '<giderlere/varlıklara yazılması>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// the text of the expense analysis, if the item is not selected (incl. Discrepancies)
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.DimensionOfExpenses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn dạng chi phí>';
													|ru = '<выберите статью расходов>';
													|en = '<select an expense item>'; fa = '<select an expense item>';
													|it = '<selezionare la voce delle spese>';
													|pl = '<wybierz pozycję wydatków>';
													|tr = '<maliyet kalemini seçin>.'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// visibility if the processor's report is being adjusted
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToExpenseAs.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExpenseItem.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAssetsLiabilitiesDimension.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfRevenue.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsExpenseAccountReglAccountingOfExpenses.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAccountReglAccountingForAssetsLiabilities.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesToExpenseAs.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesExpenseItem.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesAssetsLiabilitiesDimension.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesDimensionOfRevenue.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesDimensionOfExpenses.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesInTheExpenseAccountRegl.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesInTheReglAccountForAssetsAndLiabilities.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SubcontractorReportAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisForm);
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisForm,
		"DiscrepanciesVATRate",
		"DiscrepanciesVATAmount",
		"DiscrepanciesAmountIncludingVAT");
	
	//
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm);
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm, "DiscrepanciesAmountIncludingVAT");

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "DiscrepanciesProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Discrepancies.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisForm);
	
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisForm, "DiscrepanciesWarehouse");

	//
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.PathToFieldOfCorrectionAttributePUPA = "AdjustmentOfPurchaseOfOtherAssetServices";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber		= "DiscrepanciesCCDNumber";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToCCD	= "Object.Discrepancies.TheRecordsAreKeptByCCD";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "DiscrepanciesGTDCountryOfOriginNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	//
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfInputFieldCountryOfOrigin = "GoodsCCDNumberOriginCountry";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.PathToDocumentDateField				= "Object.Date";
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber				= "DiscrepanciesCCDNumber";
	ConditionalDesignParameters.NameOfInputFieldCountryOfOrigin	= "DiscrepanciesGTDCountryOfOriginNumber";
	ConditionalDesignParameters.PathToCCDNumberField					= "Object.Discrepancies.CCDNumber";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT			= "Object.Discrepancies.AccountingForTheRNPTIsMaintained";
	ConditionalDesignParameters.PathToItemTypeField			= "Object.Discrepancies.ItemsType";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceInDocumentPurchaseOfGoodsServices(ThisObject, True);
	
	//
	
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT();
	ConditionalDesignParameters.PathToFieldOfCorrectionAttributePUPA = "AdjustmentOfPurchaseOfOtherAssetServices";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT	= "DiscrepanciesQuantityByGBRN";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA	= "DiscrepanciesProductsFEACNUnitOfMeasure";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT		= "Object.Discrepancies.AccountingForTheRNPTIsMaintained";
	ConditionalDesignParameters.PathToItemTypeField		= "Object.Discrepancies.ItemsType";
	ConditionalDesignParameters.PathToCCDNumberTypeField			= "Object.Discrepancies.CCDNumberType";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject, ConditionalDesignParameters);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesCCDNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesGTDCountryOfOriginNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.TheRecordsAreKeptByCCD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<TKHQ không được sử dụng>';
													|ru = '<ГТД не используются>';
													|en = '<CCD numbers are not used>'; fa = '<CCD numbers are not used>';
													|it = '<Le dichiarazioni doganali di carico non vengono usate>';
													|pl = '<ŁDC nie jest używana>';
													|tr = '<GB kullanılmıyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<mallar için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

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
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesWarehouse.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesCCDNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesGTDCountryOfOriginNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<mallar için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesPurchaseOrder.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceiptUnderOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOpportunity.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesPurchaseOrder.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesRowCode.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesSalesOpportunity.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceiptUnderOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurchaseOrder.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseOrdersInTabularSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối chiếu đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối chiếu đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ToReturnReusablePackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisForm;
	InstallationParameters.ThisIsAdmission        = True;
	InstallationParameters.PathToSelectionFieldIsToReturnReusableContainer	= "ToReturnReusablePackage";
	InstallationParameters.PathToSelectionFieldRequiresDepositForContainer		= "PackageDepositIsRequired";
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, True);

	// design of items and cost analytics

	SetConditionalAppearanceForArticlesAndAnalytics();
	
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

	// Warehouse and division clearance
	// disabling the visibility of the warehouse if the work or service or product is written off for expenses.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ValueList.Add(Enums.ItemsTypes.OperationService);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);
	
	// disabling warehouse visibility if a job or service (incl. Discrepancies)

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ValueList.Add(Enums.ItemsTypes.OperationService);
	ItemFilter.RightValue = ValueList;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WarehouseGroup_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	// Disabling the visibility of the division if the goods or containers are not deductible for expenses, or commission operation.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

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
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WarehouseGroup_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

	// Disabling the visibility of the division if the goods or containers are not deductible for expenses (incl. Discrepancies).

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesDepartment.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WarehouseGroup_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

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

	// Explanatory inscription for the division, if the warehouses are not in the tabular part (incl. Discrepancies).

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ToExpenseAs");
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

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,,,False);
		
	// Disabling visibility of cost groups
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExpenseGroup.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesExpenseGroup.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SubcontractorReportAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NumberOfCostGroups");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Disabling the obligation to fill in the quantity
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SubcontractorReportAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Disabling the availability of a division, line of business
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsLineOfBusiness.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SubcontractorReportAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Disabling the obligation to fill in the costs
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SubcontractorReportAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	// Disabling the visibility of the calculation article
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductCostElement.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesProductCostElement.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SubcontractorReportAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFEACNCode.Name);
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesFEACNCode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFEACNCode.Name);
	
	ListOfCCDTypes = New ValueList();
	ListOfCCDTypes.Add(Enums.CCDNumberTypes.ProductBatchIDNumber);
	ListOfCCDTypes.Add(Enums.CCDNumberTypes.KitRNPT);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CCDNumberType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ListOfCCDTypes;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đối với TKHQ theo số đăng ký lô hàng hoặc theo bộ sản phẩm về số đăng ký lô hàng';
													|ru = 'Для ГТД по РНПТ или комплектам по РНПТ';
													|en = 'For CCD by RNPT or kits by RNPT'; fa = 'For CCD by RNPT or kits by RNPT';
													|it = 'Для ГТД по РНПТ или комплектам по РНПТ';
													|pl = 'For CCD by RNPT or kits by RNPT';
													|tr = 'RNPT''ye göre GKB veya RNPT''ye göre setler için'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesFEACNCode.Name);
	
	ListOfCCDTypes = New ValueList();
	ListOfCCDTypes.Add(Enums.CCDNumberTypes.ProductBatchIDNumber);
	ListOfCCDTypes.Add(Enums.CCDNumberTypes.KitRNPT);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.CCDNumberType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ListOfCCDTypes;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đối với TKHQ theo số đăng ký lô hàng hoặc theo bộ sản phẩm về số đăng ký lô hàng';
													|ru = 'Для ГТД по РНПТ или комплектам по РНПТ';
													|en = 'For CCD by RNPT or kits by RNPT'; fa = 'For CCD by RNPT or kits by RNPT';
													|it = 'Для ГТД по РНПТ или комплектам по РНПТ';
													|pl = 'For CCD by RNPT or kits by RNPT';
													|tr = 'RNPT''ye göre GKB veya RNPT''ye göre setler için'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.DiscrepanciesToControlQuality,
		Items.DiscrepanciesQualityConfirmationDate);
	FlagDisabled = New Array();
	ItemsTypes = Enums.ItemsTypes;
	QualityControl.AddFilter(FlagDisabled, "Object.Discrepancies.ToExpenseAs", True);
	QualityControl.AddFilter(FlagDisabled, "Object.Discrepancies.ItemsType", ItemsTypes.Work_5);
	QualityControl.AddFilter(FlagDisabled, "Object.Discrepancies.ItemsType", ItemsTypes.OperationService);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure VATTaxationOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	ParametersForFillingInVATStacks = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, False, ToReturnReusablePackage);
	ParametersForFillingInVATStacks.Date = ReferenceDocumentDateForCertificate;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", ParametersForFillingInVATStacks);
	BatchProcessingOfTablePartServer.TreatTS(Object.Discrepancies, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Discrepancies,
		CachedValues);
	
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	CalculateFinalRevenueFigures(ThisForm);
	
	UpdateTextDocumentsBasedOn();

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Date");
	
	FillInTypeOfActivityVAT();
	SetUpRNPTAccounting();
	
	If QualityControl.UpdateActionParameters(Documents.PurchaseAdjustment, Object, CacheQualityControl) Then
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Discrepancies, StructureOfActions);
	EndIf;
	
EndProcedure

&AtServer
Procedure OperationOnChangeServer()
	
	UpdateLabelsByOperation();
	SetVisibilityByOperation();
	UpdatePresentationElementsOfDocumentBeingCorrected();
	
	If Object.AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated 
		Or Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated Then
		Object.Goods.Clear();
		Object.Discrepancies.Clear();
		Object.Terms = Undefined;
		Object.Contract = Undefined;
		If ValueIsFilled(Object.DocumentBasis) Then
			AddAcquisitionDocumentToDebtAdjustmentTable(Object.DocumentBasis);
			Object.DocumentBasis = Undefined;
		EndIf;
	ElsIf  Object.AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection 
		Or Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties Then
		
		Object.ARAPAdjustment.Clear();
		SetPresentationOfFoundationDocument();
	
	EndIf;
	
	If Object.AdjustmentKind <> Enums.BusinessTransactions.ErrorCorrection Then
		Object.CorrectedDocument = Undefined;
	EndIf;
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", Object.DocumentBasis);
	OptionsForSelection.Insert("DocumentDate", Object.Date);
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	SetPresentationOfFoundationDocument();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(CachedValues)

	FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	If Object.Organization = CurrentCompany Then
		Return;
	EndIf;
	
	CurrentCompany = Object.Organization;
	ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If ValueIsFilled(Object.Organization) Then
	
		FillInVATTaxationPurchases();
		VATTaxationOnChangeServer(Undefined);
		FillInTypeOfActivityVAT();
		
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.DocumentBasis);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()

	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	If Object.Partner = CurPartner Then
		Return;
	EndIf;
	
	CurPartner = Object.Partner;
	ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();
	
	AttributesArray = New Array;
	AttributesArray.Add("Partner");
	AttributesArray.Add("Counterparty");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.DocumentBasis);
	
	UpdateTextDocumentsBasedOn();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()

	If Object.Counterparty = CurrentCounterparty Then
		Return;
	EndIf;
	
	CurrentCounterparty = Object.Counterparty;
	ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();
	
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
	AttributesArray = New Array;
	AttributesArray.Add("Counterparty");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
EndProcedure

&AtServer
Procedure ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails()
	
	Object.DocumentBasis = Undefined;
	Object.Goods.Clear();
	Object.Discrepancies.Clear();
	Object.PackageBarcodes.Clear();
	Object.ARAPAdjustment.Clear();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure GoodsAssignmentWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfActions = New Structure;
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	StructureOfActions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,, "ToExpenseAs"));
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision",
		DataToFillInWriteOFFAttributeForExpenses(Object.BusinessOperation, OptionOfExecutionOfContractOfPurchases,
			OptionForRegisteringServiceReceiptDocuments));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

#EndRegion

#Region FillType

&AtServer
Procedure FillInBySourceDataServer()
	
	Documents.PurchaseAdjustment.FillInProductsBasedOnSourceData(
		Object.DocumentBasis,
		Object.Goods,
		Object.Ref);
	For Each LineProducts_ In Object.Goods Do
		LineProducts_.GLAccountSettings = GLAccountSettingsServer.CopyOfAccountSettings(LineProducts_.GLAccountSettings, ThisObject);
	EndDo;
	AfterFillingInOriginalData();
	
EndProcedure

&AtServer
Function FillThePricesByTermsOfSalesServer(ErrorText = "")
	
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

	RowsArray = New Array;
	For Each String In Items.Goods.SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	PriceFillingParameters_ = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	PriceFillingParameters_.Insert("PopulationFields", "Price, VendorPriceKind");
	PriceFillingParameters_.Insert("Date", Object.Date);
	PriceFillingParameters_.Insert("Organization", Object.Organization);
	PriceFillingParameters_.Insert("Currency", Object.Currency);
	PriceFillingParameters_.Insert("Terms", Object.Terms);
	PriceFillingParameters_.Insert("VATTaxation", Object.VATTaxation);
	
	StructureOfActions = New Structure;

	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray, // Array of strings
		PriceFillingParameters_,
		StructureOfActions);
		
	CalculateFinalRevenueFigures(ThisForm);
	
	Return PricesCalculated;

EndFunction

&AtServer
Function FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPricesServer(VendorPriceKind)
	RowsArray = New Array;
	For Each String In Items.Goods.SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
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
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray,
		PriceFillingParameters_,
		StructureOfActions);
			
	CalculateFinalRevenueFigures(ThisForm);
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.Goods, ArrayOfSelectedRows, Warehouse, True, "ToExpenseAs");
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	WhenChangingWarehouseInTablePartServer();
	Return FilledWithRows;
	
EndFunction

&AtServer
Procedure FillInTheDiscrepanciesServer()
	
	If Not ValueIsFilled(Object.DocumentBasis) Then
		Common.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Chứng từ-cơ sở""';
				|ru = 'Поле ""Документ-основание"" не заполнено';
				|en = '""Base document"" is required'; fa = '""Base document"" is required';
				|it = 'Поле ""Документ-основание"" не заполнено';
				|pl = '""Base document"" is required';
				|tr = '""Temel belge"" alanı doldurulmamış'"),
			,
			"BaseDocumentPresentation");
		Return;
	EndIf;
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", Object.DocumentBasis);
	OptionsForSelection.Insert("DocumentDate", Object.Date);
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ProductsServer.RoundUpNumberOfUnitItems(Object);
	
	DocumentObject = FormDataToValue(Object, Type("DocumentObject.PurchaseAdjustment"));
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, DocumentObject);
	GLAccountSettingsServer.RecordFormSInvoiceSettings(ThisObject);
	DocumentObject.FillInTheDiscrepancies(UninvoicedReceiptDocumentIsUsed);
	Object.Discrepancies.Load(DocumentObject.Discrepancies.Unload());
	
	SeriesSpecificationParameters.NameTSGoods = "Discrepancies";
	SeriesSpecificationParameters.TSSeriesName  = "Discrepancies";
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	SeriesSpecificationParameters.NameTSGoods = "Goods";
	SeriesSpecificationParameters.TSSeriesName  = "Goods";
	If SubcontractorReportAdjustment Then
		For Each CurrentData In Object.Discrepancies Do
			
			TheStructureOfTheSearch = New Structure("CostGroupNumber", CurrentData.CostGroupNumber);
			
			FoundRows = CostGroups.FindRows(TheStructureOfTheSearch);
			If Not FoundRows.Count() = 0 Then
				CurrentData.ExpenseGroup = FoundRows[0].ExpenseGroup;
			EndIf;
			
		EndDo;
	EndIf;
	UpdateServiceDetailsOfTablePartOfDiscrepancy();
	GLAccountSettingsServer.UpdateSettingsPresentation(ThisObject, "Object.Discrepancies");
	DiscrepanciesAreRelevant = True;
	CalculateFinalRevenueFigures(ThisForm);

EndProcedure

&AtServer
Procedure FillInAccordingToDiscrepancyCertificateServer()
	
	DocumentObject = FormDataToValue(Object, Type("DocumentObject.PurchaseAdjustment"));
	Documents.PurchaseAdjustment.FillInGoodsAccordingToCertificateOfDiscrepancies(DocumentObject);
	ValueToFormData(DocumentObject, Object);
	
	AfterFillingInOriginalData();
	
EndProcedure 

&AtServer
Procedure AfterFillingInOriginalData()

	ActionsForFillIn = New Structure;
	ActionsForFillIn.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ActionsForFillIn.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	If AdjustmentOfPurchaseOfOtherAssetServices Then
		For Each RowGoods In Object.Goods Do
			FillInOfficialTraceabilityAttributesInProductLine(RowGoods);
		EndDo;
	Else
		ActionsForFillIn.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ActionsForFillIn);
	EndIf;
	ActionsForFillIn.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ActionsForFillIn);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	WhenChangingWarehouseInTablePartServer();
	FillInServiceDetailsForPurposeOfVTCH();
	IncomeAndExpensesServer.UpdateServiceDetails(ThisObject);
	DiscrepanciesAreRelevant = (Object.Discrepancies.Count() = 0);
	CalculateFinalRevenueFigures(ThisObject);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtServer
Procedure FillInVATTaxationPurchases()
	
	FillParameters = Documents.PurchaseAdjustment.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Procedure FillInTypeOfActivityVAT()
	
	FillParameters = Documents.PurchaseAdjustment.ParametersForFillingInVATActivityType(Object);
	VATAccountingERP.FillInTypeOfActivityVAT(Object.PurchaseForActivity, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInActivitySelectionList(Items.PurchaseForActivity, Object.PurchaseForActivity, FillParameters, VATAccountingCachedParameterValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInOfficialTraceabilityAttributesInProductLine(CurrentData, ThisIsDiscrepancy = False)
	
	If CurrentData <> Undefined Then
		If TypeOf(CurrentData.DimensionOfExpenses) = Type("CatalogRef.Assets") Then
			
			CCDNumberIsSpecified = ValueIsFilled(CurrentData.CCDNumber);
			CurrentData.TheRecordsAreKeptByCCD = ?(ThisIsDiscrepancy, CCDNumberIsSpecified, True);
			CurrentData.AccountingForTheRNPTIsMaintained = GoodsAreTraceable(CurrentData.CCDNumber);
			If Not CCDNumberIsSpecified Then
				If ValueIsFilled(CurrentData.FEACNCode) Then
					CurrentData.FEACNCode = Undefined;
				EndIf;
				CurrentData.OriginCountry = Undefined;
			EndIf;
			
		Else
			CurrentData.TheRecordsAreKeptByCCD = False;
			CurrentData.AccountingForTheRNPTIsMaintained = False;
			
			If ValueIsFilled(CurrentData.FEACNCode) Then
				CurrentData.FEACNCode = Undefined;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateFinalRevenueFigures(Form)
	
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseLocal = GetFunctionalOption("UseLocal");
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	SubcontractorReportAdjustment = False;
	SubcontractorReportAdjustment = (TypeOf(Object.DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5"));
	
	If SubcontractorReportAdjustment Then
		
		DetailsOfFoundationDocument      = DetailsOfFoundationDocument(Object.DocumentBasis);
		FoundationDivision           = DetailsOfFoundationDocument.Department;
		DirectionOfActivityOfFoundation = DetailsOfFoundationDocument.LineOfBusiness;
		GroupingOfBaseCosts       = DetailsOfFoundationDocument.GroupCosts;
		
	EndIf;
	
	GenerateHeaderForReportAdjustmentsToProcessor();
	Operation = EconomicOperationOfFoundationDocument(Object.DocumentBasis);
	SetBusinessOperationOfDocument(Object.DocumentBasis);
	SetPresentationOfFoundationDocument();
	
	If Not GetFunctionalOption("UseConsolidatedDebtAdjustmentTransactionsForAcquisition") Then
		OperationSelectionList = Items.Operation.ChoiceList;
		IncreaseInDebt = OperationSelectionList.FindByValue(
				Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated);
		If IncreaseInDebt <> Undefined 
			And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated Then
			OperationSelectionList.Delete(IncreaseInDebt);
		EndIf;
		
		DebtReduction_ = OperationSelectionList.FindByValue(
				Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated);
		If DebtReduction_ <> Undefined
			And Object.AdjustmentKind <> Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
			OperationSelectionList.Delete(DebtReduction_);
		EndIf;
	EndIf;
	
	SetVisibilityOfElementsByBase();
	
	SetAvailabilityOfItemsByStatusServer();
	
	SetVisibilityByOrders();
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	
	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.PurchaseAdjustment);
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseCostAccountingByBatches;
	Items.DiscrepanciesSeries.Visible           = SeriesSpecificationParameters.UseCostAccountingByBatches;
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible);
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
		
	WhenChangingWarehouseInTablePartServer();
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	
	AdjustmentOfPurchaseOfOtherAssetServices = (TypeOf(Object.DocumentBasis) = Type("DocumentRef.VendorInvoiceServicesAndAssets"));
	
	BasisDiscrepancyCertificateAfterReceiving = ValueIsFilled(Object.DiscrepancyReportFollowingReceiptBaseDocument);
	
	SetParametersForSelectingProductsWarehouse();
	SetProductSelectionParameters();
	SetParametersForSelectingGTDINumberOfHSCode();
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	UseOrdersInTabularSection = GetFunctionalOption("UseReceiptForMultipleOrders");
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	
	UpdateServiceDetailsOfTableParts(); 
	UpdateTextDocumentsBasedOn();
	UpdateCostGroups();
	SetOrderSelectionParametersForSupplier();
	
	If ValueIsFilled(Object.DocumentBasis) Then
		AdjustmentPeriod_ = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		SetPrivilegedMode(True);
		ReferenceDocumentDateForCertificate   = Common.ObjectAttributeValue(Object.DocumentBasis, "Date");
		SetPrivilegedMode(False);
		LastPeriodAdjustment = ReferenceDocumentDateForCertificate < BegOfMonth(AdjustmentPeriod_);
	Else
		ReferenceDocumentDateForCertificate = Object.Date;
	EndIf;
	
	DiscrepanciesAreRelevant = True;
	UpdateOrderDeviations();
	
	ToReturnReusablePackage = False;
	PackageDepositIsRequired 	  = False;
	
	If ValueIsFilled(Object.DocumentBasis)
		And TypeOf(Object.DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
		SetPrivilegedMode(True); 
		PropertiesNames = "ToReturnReusablePackage, PackageDepositIsRequired, BusinessOperation";
		ObjectAttributesValues = Common.ObjectAttributesValues(Object.DocumentBasis, PropertiesNames);
		ToReturnReusablePackage = ObjectAttributesValues.ToReturnReusablePackage;
		PackageDepositIsRequired 	  = ObjectAttributesValues.PackageDepositIsRequired; 
		EconomicOperationOfFoundationDocument = ObjectAttributesValues.BusinessOperation;
		SetPrivilegedMode(False);
	EndIf;
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	ProcessingOfTabularForms.InitializeRowCache(Items.Discrepancies);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	UpdateLabelsByOperation();
	SetVisibilityByOperation();
	UpdatePresentationElementsOfDocumentBeingCorrected();
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	FillInUsedDocumentReceiptOfGoodsAttribute();
	
	FillParameters = Documents.PurchaseAdjustment.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
	FillParameters = Documents.PurchaseAdjustment.ParametersForFillingInVATActivityType(Object);
	VATAccountingERP.FillInActivitySelectionList(
		Items.PurchaseForActivity,
		Object.PurchaseForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
	CurrentCompany = Object.Organization;
	CurrentCurrency = Object.Currency;
	CurCurrencyOfSettlements = Object.ARAPCurrency;
	CurrentCounterparty = Object.Counterparty;
	CurPartner = Object.Partner;
	
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

&AtServer
Procedure SetPresentationOfFoundationDocument()
	
	If ValueIsFilled(Object.DocumentBasis) Then
		
		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
			BaseDocumentPresentation = String(Object.DocumentBasis) + " (" + Operation + ")";
		Else
			BaseDocumentPresentation = Object.DocumentBasis;
		EndIf;
		
		Items.BaseDocumentPresentation.TextColor = StyleColors.HyperlinkColor;
		
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
		BaseDocumentPresentation = NStr("vi = 'Việc mua hàng hóa và dịch vụ <không được chọn>';
										|ru = 'Приобретение товаров и услуг <не выбран>';
										|en = 'Vendor invoice <not selected>'; fa = 'Vendor invoice <not selected>';
										|it = 'Acquisto delle merci e servizi <non selezionato>';
										|pl = 'Nabycie towarów i usług <nie wybrano>';
										|tr = 'Satın alma faturası <seçilmemiş>'");
		Items.BaseDocumentPresentation.TextColor = StyleColors.SpecialTextColor;
		
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		BaseDocumentPresentation = NStr("vi = 'Mua dịch vụ và tài sản khác <không chọn>';
										|ru = 'Приобретение услуг и прочих активов <не выбран>';
										|en = 'Vendor invoice — Services and Assets <not selected>'; fa = 'Vendor invoice — Services and Assets <not selected>';
										|it = 'Acquisto delle merci e altri attivi <non selezionato>';
										|pl = 'Nabycie usług i innych aktywów <nie wybrano>';
										|tr = 'Satın alma faturası — hizmetler ve varlıklar <seçilmemiş>'");
		Items.BaseDocumentPresentation.TextColor = StyleColors.SpecialTextColor;
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
		BaseDocumentPresentation = NStr("vi = 'Bảng kê của bên nhận gia công <chưa chọn>';
										|ru = 'Отчет переработчика <не выбран>';
										|en = 'Subcontracting services notification received is <not selected>'; fa = 'Subcontracting services notification received is <not selected>';
										|it = 'Report elaboratore <non selezionato>';
										|pl = 'Raport przetwórcy <nie jest wybrany>';
										|tr = 'Alınan fason üretici hizmetleri bildirimi <seçilmemiş>'");
		Items.BaseDocumentPresentation.TextColor = StyleColors.SpecialTextColor;
	Else
		BaseDocumentPresentation = NStr("vi = 'Hãy chọn chứng từ cơ sở';
										|ru = 'Выберите документ-основание';
										|en = 'Select a base document'; fa = 'Select a base document';
										|it = 'Selezionare documento base';
										|pl = 'Wybierz dokument źródłowy';
										|tr = 'Lütfen, temel belge seçin.'");
		Items.BaseDocumentPresentation.TextColor = StyleColors.SpecialTextColor;
	EndIf;
	
	If ValueIsFilled(Object.DiscrepancyReportFollowingReceiptBaseDocument) Then
		SubmissionOfTheDocumentOfTheBasisOfTheActOfDiscrepancies = Object.DiscrepancyReportFollowingReceiptBaseDocument;
		Items.SubmissionOfTheDocumentOfTheBasisOfTheActOfDiscrepancies.TextColor = StyleColors.HyperlinkColor;
	Else
		Items.GoodsFillInAccordingToDiscrepancyCertificate.Visible = False;
		Items.GroupOfGroundsForTheActOfDiscrepancies.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByBase()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.PurchaseAdjustment.FillInNamesOfDetailsOnBasis(
		Object.DocumentBasis, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	NumberOfPackagesIsUsed = Items.GoodsNumberOfPackages.Visible;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsCount", "Visible", Not NumberOfPackagesIsUsed);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsPurpose", "Visible", Not SubcontractorReportAdjustment);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsProductsUnitOfMeasure", "Visible", Items.GoodsProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsSelectGoods", "Visible", Items.GoodsProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsFillThePricesByTermsOfSales", "Visible", Items.GoodsProducts.Visible And Not SubcontractorReportAdjustment);
	TMCommonUseClientServer.SetFormItemProperty(Items, "DiscrepanciesCount", "Visible", Not NumberOfPackagesIsUsed);
	TMCommonUseClientServer.SetFormItemProperty(Items, "DiscrepanciesProductsUnitOfMeasure", "Visible", Items.DiscrepanciesProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsFillInTheItemByThePartnerSItem", "Visible", Items.GoodsProducts.Visible And Not SubcontractorReportAdjustment);
	
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("PictureMultipleWarehouses");
	ArrayOfElementNames.Add("SeveralWarehousesText");
	ArrayOfElementNames.Add("GoodsFillInTheWarehouseInSelectedLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", Items.GoodsWarehouse.Visible);
	
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("AmountForOtherExpenses");
	ArrayOfElementNames.Add("CurrencyForOtherExpenses");
	ArrayOfElementNames.Add("AllowanceForOtherExpenses");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", Items.ExpenseItem.Visible);
	
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("AmountForOtherIncome");
	ArrayOfElementNames.Add("OtherIncomeTax");
	ArrayOfElementNames.Add("TaxOnOtherIncome");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", Items.IncomeItem.Visible);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsCCDNumberOriginCountry", "Visible", Items.GoodsCCDNumber.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "DiscrepanciesGTDCountryOfOriginNumber", "Visible", Items.DiscrepanciesCCDNumber.Visible);
	
EndProcedure


&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	ItemArray.Add("Date");
	ItemArray.Add("Operation");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("Goods;BeforeAddRow,BeforeDeleteRow,BeforeRowChange");
	ItemArray.Add("Discrepancies");
	ItemArray.Add("ARAPAdjustment");
	ItemArray.Add("GoodsUnlinkFromOrder");
	ItemArray.Add("GoodsContextMenuUnlinkFromOrder");
	ItemArray.Add("GoodsFillInBySourceData");
	ItemArray.Add("GoodsFillInAccordingToDiscrepancyCertificate");
	ItemArray.Add("GoodsSelectGoods");
	ItemArray.Add("GoodsSelectGoodsFromOrder");
	ItemArray.Add("GoodsFillInTheItemByThePartnerSItem");
	ItemArray.Add("GoodsFillInVATRate");
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsSplitRow");
	ItemArray.Add("GoodsFillThePricesByTermsOfSales");
	ItemArray.Add("ProductsFillInPricesOfSelectedRowsBySupplierPriceType");
	ItemArray.Add("GoodsFillInTheWarehouseInSelectedLines");
	ItemArray.Add("DiscrepanciesFillInTheDiscrepancies");
	ItemArray.Add("DiscrepanciesSetRecordingOptions");
	ItemArray.Add("PickUpDocumentsForDebtAdjustment");
	ItemArray.Add("CalculateAmountOfDebtAdjustmentForInterest");
	ItemArray.Add("DistributeTotalAmountOfDebtAdjustmentToDocuments");
	ItemArray.Add("FillInReasonForDebtAdjustment");
	ItemArray.Add("EditDocumentBeingCorrected");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsUnlinkFromOrder", "Visible", Object.ReceiptUnderOrders);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsContextMenuUnlinkFromOrder", "Visible", Object.ReceiptUnderOrders);

EndProcedure

&AtServer
Procedure SetVisibilityByOrders()
	
	If Object.ReceiptUnderOrders Then
		Items.GoodsAdd.Title = NStr("vi = 'Thêm hàng hóa bên phía trên đơn hàng ';
									|ru = 'Добавить товары сверх заказа';
									|en = 'Add goods exceeding the order'; fa = 'افزودن کالای مازاد بر سفارش';
									|it = 'Aggiungere le merci oltre l''ordine';
									|pl = 'Dodaj wiersze pozycji ponad zamówienia';
									|tr = 'Sipariş fazlası ürünleri ekle'");
	Else
		Items.GoodsAdd.Title = NStr("vi = 'Thêm';
									|ru = 'Добавить';
									|en = 'Add'; fa = 'افزودن';
									|it = 'Aggiungere';
									|pl = 'Add';
									|tr = 'Ekle'");
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsSelectGoodsFromOrder", "Visible", Object.ReceiptUnderOrders And Not SubcontractorReportAdjustment);
	
EndProcedure

&AtServer
Procedure ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies()
	
	AmountForOtherIncome  = 0;
	AmountForOtherExpenses = 0;
	TotalAmountShovelcharge = 0;
	TotalAmountZhamanshina = 0;
	TotalAmountJavelina = 0;
	TotalAmountOfNDSUReduction = 0;
	ToExpenseAs = False;
	RecordInOtherIncome = False;
		
	If Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated Then
		CalculateTotalsFromDebtAdjustmentTable();
		ToExpenseAs = True;
		RecordInOtherIncome = False;
	ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
		CalculateTotalsFromDebtAdjustmentTable();
		ToExpenseAs = False;
		RecordInOtherIncome = True;
	Else
		CalculateTotalsFromDiscrepancyTable();
		RecordInOtherIncome = (AmountForOtherIncome > 0);
		ToExpenseAs  = (AmountForOtherExpenses > 0);
	EndIf;
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", Object.DocumentBasis);
	OptionsForSelection.Insert("RecordInOtherIncome", RecordInOtherIncome);
	OptionsForSelection.Insert("ToExpenseAs", ToExpenseAs);
	
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	AccountSelectionParameters_ = Documents.PurchaseAdjustment.AccountingAccountSettings_(OptionsForSelection);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, AccountSelectionParameters_);
	TextAmountForOtherExpensesAssets = Items.TextAmountForOtherExpensesAssets.Title 
		 + " " + String(AmountForOtherExpenses) + " " + String(Object.Currency);
	
	TextAmountForOtherIncomeLiabilities = Items.TextAmountForOtherIncomeLiabilities.Title
		 + " " + String(AmountForOtherIncome) + " " + String(Object.Currency);
	
	Items.TextAmountForOtherExpensesAssets.Enabled = ValueIsFilled(AmountForOtherExpenses);
	Items.TextAmountForOtherIncomeLiabilities.Enabled  = ValueIsFilled(AmountForOtherIncome);
	
	Items.ReduceAmountVATDeduction.Visible = Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties
													And (TotalAmountOfNDSUReduction > 0 And TotalAmountJavelina = 0)
													And Object.PurchaseForActivity <> Enums.VATTaxationTypes.ProductionWithLongCycle
													And Object.PurchaseForActivity <> Enums.VATTaxationTypes.SpaceActivity
													And Object.PurchaseForActivity <> Enums.VATTaxationTypes.SaleIsNotSubjectToVAT
													And Object.PurchaseForActivity <> Enums.VATTaxationTypes.SalesByPatent;
	
EndProcedure

&AtServer
Procedure CalculateTotalsFromDiscrepancyTable()
	
	For Each LineOfDiscrepancies In Object.Discrepancies Do
			
		TotalAmountShovelcharge = TotalAmountShovelcharge + ?(LineOfDiscrepancies.AmountIncludingVAT > 0, LineOfDiscrepancies.AmountIncludingVAT, 0);
		TotalAmountZhamanshina = TotalAmountZhamanshina + ?(LineOfDiscrepancies.AmountIncludingVAT < 0, -LineOfDiscrepancies.AmountIncludingVAT, 0);
		TotalAmountJavelina  = TotalAmountJavelina + ?(LineOfDiscrepancies.VATAmount > 0, LineOfDiscrepancies.VATAmount, 0);
		TotalAmountOfNDSUReduction  = TotalAmountOfNDSUReduction + ?(LineOfDiscrepancies.VATAmount < 0, -LineOfDiscrepancies.VATAmount, 0);
		
		If LineOfDiscrepancies.PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome Then
			AmountForOtherIncome = AmountForOtherIncome + ?(LineOfDiscrepancies.AmountIncludingVAT<0, -LineOfDiscrepancies.AmountIncludingVAT, LineOfDiscrepancies.AmountIncludingVAT);
		ElsIf LineOfDiscrepancies.PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs
			And Not LineOfDiscrepancies.ToExpenseAs Then
			AmountForOtherExpenses = AmountForOtherExpenses + ?(LineOfDiscrepancies.AmountIncludingVAT<0, -LineOfDiscrepancies.AmountIncludingVAT, LineOfDiscrepancies.AmountIncludingVAT);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateTotalsFromDebtAdjustmentTable()
	
	For Each TSRow In Object.ARAPAdjustment Do
		
		If Object.AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
			TotalAmountZhamanshina = TotalAmountZhamanshina + TSRow.AdjustmentSum;
			TotalAmountOfNDSUReduction = TotalAmountOfNDSUReduction + TSRow.SumOfVATAdjustments;
			AmountForOtherIncome = AmountForOtherIncome + TSRow.AdjustmentSum - TSRow.SumOfVATAdjustments;
		ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated Then
			TotalAmountShovelcharge = TotalAmountShovelcharge + TSRow.AdjustmentSum;
			TotalAmountJavelina = TotalAmountJavelina + TSRow.SumOfVATAdjustments;
			AmountForOtherExpenses = AmountForOtherExpenses + TSRow.AdjustmentSum - TSRow.SumOfVATAdjustments;
		EndIf
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TextsFieldsDocumentsBasedOn.Clear();
	
	RegistrationParameters = Documents.PurchaseAdjustment.ParametersForRegisteringInvoicesReceived(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
	
	InvoiceTextReceived = InvoicesReceivedOnBasisOf.Presentation;
	
	TextsFieldsDocumentsBasedOn.Add(InvoiceTextReceived);
	
	ParametersForRegisteringImportNotifications = PurchaseAdjustmentLocalization.ParametersForRegisteringImportNotificationsOfTraceableGoods(Object);
	NotificationOfImportationOnBasisOf = AccountingForTraceableGoodsLocalization.NotificationsOfImportOfTraceableGoodsOnDocumentOfReceipt(ParametersForRegisteringImportNotifications);
	TextsFieldsDocumentsBasedOn.Add(NotificationOfImportationOnBasisOf.PresentationOfOrderForRegistration);
	TextsFieldsDocumentsBasedOn.Add(NotificationOfImportationOnBasisOf.PresentationOfImportNotification);
	
	TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_, False);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
EndProcedure

&AtServer
Procedure UpdateServiceDetailsOfTableParts()
	
	ActionsForFillIn = New Structure;
	ActionsForFillIn.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ActionsForFillIn.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	If AdjustmentOfPurchaseOfOtherAssetServices Then
		For Each RowOfProduct In Object.Goods Do
			FillInOfficialTraceabilityAttributesInProductLine(RowOfProduct);
		EndDo;
	Else
		ActionsForFillIn.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ActionsForFillIn);
	EndIf;
	ActionsForFillIn.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ActionsForFillIn);
	
	FillInServiceDetailsForPurposeOfVTCH();
	UpdateServiceDetailsOfTablePartOfDiscrepancy();
	UpdateOrderDeviations();
	
EndProcedure

&AtServer
Procedure UpdateServiceDetailsOfTablePartOfDiscrepancy()
	
	ActionsForFillIn = New Structure;
	ActionsForFillIn.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ActionsForFillIn.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		ActionsForFillIn.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ActionsForFillIn);
	EndIf;
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Discrepancies, ActionsForFillIn);
	
	WarehouseData_2 = GetDataOnWarehouses();
	
	For Each LineOfDiscrepancies In Object.Discrepancies Do
		
		WarehouseData_1 = WarehouseData_2.Find(LineOfDiscrepancies.Warehouse);
		If WarehouseData_1 <> Undefined Then
			LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
		
		If AdjustmentOfPurchaseOfOtherAssetServices Then
			FillInOfficialTraceabilityAttributesInProductLine(LineOfDiscrepancies, True);
		EndIf;
		
	EndDo;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Discrepancies);
	
EndProcedure

&AtServer
Procedure SetOrderSelectionParametersForSupplier()
	
	DetailsOfFoundationDocument = DetailsOfFoundationDocument(Object.DocumentBasis);
	
	ParametersArray = New Array;
	
	SetPriceIncludesVAT	 = False;
	EstablishedVATTaxation = False;
	
	For Each Parameter In Items.GoodsPurchaseOrder.ChoiceParameters Do
		
		If Parameter.Name = "Filter.PriceIncludesVAT"
		 And Parameter.Value <> DetailsOfFoundationDocument.PriceIncludesVAT Then
			NewParameter1 = New ChoiceParameter(Parameter.Name, DetailsOfFoundationDocument.PriceIncludesVAT);
			ParametersArray.Add(NewParameter1);
			SetPriceIncludesVAT = True;
		ElsIf Parameter.Name = "Filter.VATTaxation"
		 And Parameter.Value <> DetailsOfFoundationDocument.VATTaxation Then
			NewParameter1 = New ChoiceParameter(Parameter.Name, DetailsOfFoundationDocument.VATTaxation);
			ParametersArray.Add(NewParameter1);
			EstablishedVATTaxation = True;
		Else
			ParametersArray.Add(Parameter);
		EndIf;
		
	EndDo;
	
	If Not SetPriceIncludesVAT Then
		Parameter = New ChoiceParameter("PriceIncludesVAT", DetailsOfFoundationDocument.PriceIncludesVAT);
		ParametersArray.Add(Parameter);
	EndIf;
	
	If Not EstablishedVATTaxation Then
		Parameter = New ChoiceParameter("VATTaxation", DetailsOfFoundationDocument.VATTaxation);
		ParametersArray.Add(Parameter);
	EndIf;
	
	Items.GoodsPurchaseOrder.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure ProcessingDocumentSelectionViaServer(ValueSelected)
	
	Modified = True;
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(ValueSelected);
	ValueToFormAttribute(DocumentObject, "Object");
	
	Object.DocumentBasis = ValueSelected;
	
	OnReadCreateAtServer();
	EstablishVisibilityOfRNPTQuantity();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
		
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(GoodsAddressInStorage)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	ProductSearchStructure_ = New Structure("RowCode,PurchaseOrder");
	For Each RowOfGoods In ItemsFromStorage Do
		
		// PM goods processing.
		ProductSearchStructure_.RowCode = RowOfGoods.RowCode;
		ProductSearchStructure_.PurchaseOrder = RowOfGoods.PurchaseOrder;
		ArrayOfTSRows = Object.Goods.FindRows(ProductSearchStructure_);
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
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, StringTSGoods, "Object.Goods");
		If AdjustmentOfPurchaseOfOtherAssetServices Then
			FillInOfficialTraceabilityAttributesInProductLine(RowOfGoods);
		EndIf;
		
	EndDo;
	
	ActionsForFillIn = New Structure;
	ActionsForFillIn.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ActionsForFillIn.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		ActionsForFillIn.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ActionsForFillIn);
	EndIf;
	ActionsForFillIn.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ActionsForFillIn);
	
	FillInAttributeForDebitingExpensesForServices();
	FillInServiceDetailsForPurposeOfVTCH();
	WhenChangingWarehouseInTablePartServer();
	DiscrepanciesAreRelevant = False;
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtServerNoContext
Function GetDealOnOrderToSupplier(PurchaseOrder)
	
	Return Common.ObjectAttributeValue(PurchaseOrder, "SalesOpportunity");
	
EndFunction

&AtServerNoContext
Function DetailsOfFoundationDocument(DocumentBasis)
	
	DetailsOfFoundation = New Structure;
	DetailsOfFoundation.Insert("PriceIncludesVAT");
	DetailsOfFoundation.Insert("VATTaxation");
	If TypeOf(DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
		DetailsOfFoundation.Insert("Department");
		DetailsOfFoundation.Insert("LineOfBusiness");
		DetailsOfFoundation.Insert("GroupCosts");
	EndIf;
	If ValueIsFilled(DocumentBasis)
		And TypeOf(DocumentBasis) <> Type("DocumentRef.SourceDocument") Then
	
		DetailsOfFoundation = Common.ObjectAttributesValues(DocumentBasis, DetailsOfFoundation);
	EndIf;
	
	Return DetailsOfFoundation;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenQuantityChanges(StructureOfActions, Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Form.Object,
		StructureOfActions,
		"Warehouse",
		True);
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServerNoContext
Procedure CheckForAdjustments(Ref, Basis, ThereAreAdjustingEntries)
	
	PurchasesServer.CheckForAdjustmentsAndInvoices(Ref, Basis, ThereAreAdjustingEntries, Undefined);
	
EndProcedure

&AtServerNoContext
Function CheckForCorrectionsAfterDocumentDate(Document)
	
	AttributesNames = "Date, AdjustmentKind, DocumentBasis, CorrectedDocument";
	DocumentAttributes = Common.ObjectAttributesValues(Document, AttributesNames);
	
	CheckParameters = InformationRegisters.DocumentCorrections.DocumentCorrectionVerificationParameters();
	CheckParameters.Ref = Document;
	CheckParameters.Date = DocumentAttributes.Date;
	CheckParameters.CorrectedDocument = Documents.PurchaseAdjustment.CorrectedDocument(DocumentAttributes);
	
	SetPrivilegedMode(True);
	Patch = DocumentCorrection.CorrectionAfterDocumentDate(CheckParameters);
	Patch = ?(ValueIsFilled(Patch), String(Patch), "");
	Return Patch;
	
EndFunction

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
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	OrderDocument = Undefined;
	OrderDiscrepancy_3 = 0;
	If Object.ReceiptUnderOrders Then
		OrderDiscrepancy_3 = 1;
	EndIf;
	
	If Object.ReceiptUnderOrders
		Or AdjustmentOfPurchaseOfOtherAssetServices Then
		
		For Each CurrentRow In Object.Goods Do
			If Object.ReceiptUnderOrders Then
				If ValueIsFilled(OrderDocument)
					And Not CurrentRow.PurchaseOrder = OrderDocument Then
					OrderDocument = Undefined;
					Break;
				Else
					OrderDocument = CurrentRow.PurchaseOrder;
				EndIf;
			EndIf;
			If AdjustmentOfPurchaseOfOtherAssetServices Then
				FillInOfficialTraceabilityAttributesInProductLine(CurrentRow);
			EndIf;
		EndDo;
		
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	EndIf;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ToReturnReusablePackage);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(
			CurrentRow,
			RowOfProduct,
			"PartnerProducts, Products, Characteristic, Package, Warehouse, Price, NumberOfPackages");
		
		If ValueIsFilled(OrderDocument)
			And Not ValueIsFilled(CurrentRow.PurchaseOrder) Then
			CurrentRow.PurchaseOrder = OrderDocument;
		EndIf;
		
		CurrentRow.OrderDiscrepancy_3 = OrderDiscrepancy_3;
		If SubcontractorReportAdjustment Then
			CurrentRow.Department = FoundationDivision;
			CurrentRow.LineOfBusiness = DirectionOfActivityOfFoundation;
		EndIf;
		
		SetDefaultCostGroupNumber(CurrentRow.GetID());
		RowsToProcess.Add(CurrentRow);
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	For Each CurrentRow In RowsToProcess Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Goods");
	EndDo;
	
	FillInAttributeForDebitingExpensesForServices();
	
	WhenChangingWarehouseInTablePartServer();
	DiscrepanciesAreRelevant = False;
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtServer
Procedure UpdateOrderDeviations()
	
	For Each CurRow In Object.Goods Do
		UpdateOrderDeviationsInLine(CurRow, Object.ReceiptUnderOrders);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateOrderDeviationsInLine(CurrentRow, ReceiptUnderOrders)
	If ReceiptUnderOrders Then
		If CurrentRow.RowCode = 0 Then
			CurrentRow.OrderDiscrepancy_3 = 1;
		Else
			CurrentRow.OrderDiscrepancy_3 = 0;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UnlinkFromOrder(Command)
	SelectedRows = Items.Goods.SelectedRows;
	If SelectedRows.Count()>0 Then
		For Each CurRow In SelectedRows Do
			TableRow = Object.Goods.FindByID(CurRow);
			TableRow.RowCode = 0;
			TableRow.OrderDiscrepancy_3 = 1;
		EndDo;
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

// Parameters:
// 	Response - DialogReturnCode - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure QuestionToUserWhenChangingDetailsOfLineQuestionCompletion(Response, AdditionalParameters) Export
	
	// If the user has confirmed the change in the value of the key details
	If Response = DialogReturnCode.Yes Then
		
		AdditionalParameters.CurrentRow.RowCode = 0;
		UpdateOrderDeviationsInLine(AdditionalParameters.CurrentRow, Object.ReceiptUnderOrders);
		RunCallback(AdditionalParameters.CallbackDescription, True);
		
	Else
		
		// If the user refused to change the linked string, we will return the old values
		FillPropertyValues(AdditionalParameters.CurrentRow, PreviousRowDetails);
		RunCallback(AdditionalParameters.CallbackDescription, False);
		
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
Function GetDataOnWarehouses()
	
	WarehousesOfDiscrepancies = Object.Discrepancies.Unload(,"Warehouse");
	WarehousesOfDiscrepancies.GroupBy("Warehouse");
	WarehousesOfDiscrepancies.Columns.Add("UseWarehouseManagemantSystemForGoodsSurplusesShortages",
		New TypeDescription("Boolean"));
	
	For Each Page1 In WarehousesOfDiscrepancies Do
		If ValueIsFilled(Page1.Warehouse) Then
			Page1.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Page1.Warehouse, Object.Date);
		EndIf;
	EndDo;
	
	Return WarehousesOfDiscrepancies;
	
EndFunction

&AtServer
Function PlaceGoodsInTemporaryStorageServer(CollectionName)
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(Object[CollectionName]);
	
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	TableOfGoods = GetFromTempStorage(AddressInTempStorage); // DocumentTabularSection.PurchaseAdjustment.Goods
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ToReturnReusablePackage);
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.AdjustmentKind,
		Object.Organization,
		Object.Department);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	For Each CurRow In TableOfGoods Do
		
		ArrayOfCollectionRows = Object.Goods.FindRows(New Structure("LineNumber", CurRow.LineNumber));
		If ArrayOfCollectionRows.Count() <> 1 Then
			Continue;
		Else
			CollectionRow = ArrayOfCollectionRows[0];
		EndIf;
		
		FillPropertyValues(CollectionRow, CurRow, "Products, Characteristic, Package");
		
		If AdjustmentOfPurchaseOfOtherAssetServices Then
			FillInOfficialTraceabilityAttributesInProductLine(CurRow);
		EndIf;
		
		RowsToProcess.Add(CollectionRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	WhenChangingWarehouseInTablePartServer();
	CalculateFinalRevenueFigures(ThisForm);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtServer
Procedure FillInAttributeForDebitingExpensesForServices()
	
	// filling in the write-off attribute for expenses
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.AdjustmentKind,
		Object.Organization,
		Object.Department);
		
	FilterStructure1 = New Structure("ItemsType", Enums.ItemsTypes.OperationService);
	FoundRows = Object.Goods.FindRows(FilterStructure1);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision",
		DataToFillInWriteOFFAttributeForExpenses(Object.BusinessOperation, OptionOfExecutionOfContractOfPurchases, 
			OptionForRegisteringServiceReceiptDocuments));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		FoundRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
			
	For Each String In FoundRows Do
			
		IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, String, "Object.Goods");
		
	EndDo;
	
EndProcedure
&AtServer
Procedure GenerateHeaderForReportAdjustmentsToProcessor()
	
	If SubcontractorReportAdjustment Then
		
		If Not ValueIsFilled(Object.Ref) Then
			AutoTitle = False;
			Title = NStr("vi = 'Điều chỉnh bảng kê của bên nhận gia công (tạo mới)';
						|ru = 'Корректировка отчета переработчика (создание)';
						|en = 'Adjust subcontracting services notification received (create)'; fa = 'Adjust subcontracting services notification received (create)';
						|it = 'Корректировка отчета переработчика (создание)';
						|pl = 'Adjust subcontracting services notification received (create)';
						|tr = 'Fason üretici raporunun düzenlenmesi (oluştur)'");
		Else
			Title = "";
			AutoTitle = True;
		EndIf;
		
		Items.Partner.Title = NStr("vi = 'Bên nhận gia công';
									|ru = 'Переработчик';
									|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
									|it = 'Subfornitore';
									|pl = 'Subcontractor';
									|tr = 'Fason üretici'");
		Items.Warehouse.Visible = False;
		Items.Terms.Visible = False;
		
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

&AtServer
Procedure UpdateLabelsByOperation() 
	
	If Object.AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
		
		Items.GroupDebtAdjustment.Title = NStr("vi = 'Giảm nợ';
												|ru = 'Уменьшение задолженности';
												|en = 'Payables decrease'; fa = 'کاهش پرداختنی‌ها';
												|it = 'Riduzione debito';
												|pl = 'Zmniejszenie zadłużenia';
												|tr = 'Borçlarda azalma'");
		Items.ARAPAdjustmentAdjustmentSum.Title = NStr("vi = 'Số tiền giảm';
														|ru = 'Сумма уменьшения';
														|en = 'Decrease amount'; fa = 'مبلغ کاهش';
														|it = 'Importo ridotto';
														|pl = 'Suma zmniejszenia';
														|tr = 'Azalma miktarı'");
		Items.ARAPAdjustmentSumOfVATAdjustments.Title = NStr("vi = 'Số tiền thuế GTGT giảm';
															|ru = 'Сумма НДС уменьшения';
															|en = 'Decrease VAT amount'; fa = 'Decrease VAT amount';
															|it = 'Importo IVA di riduzione';
															|pl = 'Kwota VAT zmniejszenia';
															|tr = 'KDV indirimi miktarı'");
		
	ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated Then
		
		Items.GroupDebtAdjustment.Title = NStr("vi = 'Tăng nợ';
												|ru = 'Увеличение задолженности';
												|en = 'Payables increase'; fa = 'افزایش پرداختنی‌ها';
												|it = 'Aumento debito';
												|pl = 'Zwiększenie zadłużenia';
												|tr = 'Borçlarda artış'");
		Items.ARAPAdjustmentAdjustmentSum.Title = NStr("vi = 'Số tiền tăng';
														|ru = 'Сумма увеличения';
														|en = 'Increase amount'; fa = 'مبلغ افزایش';
														|it = 'Importo aumentato';
														|pl = 'Wartość wzrostu';
														|tr = 'Artış miktarı'");
		Items.ARAPAdjustmentSumOfVATAdjustments.Title = NStr("vi = 'Số tiền thuế GTGT tăng';
															|ru = 'Сумма НДС увеличения';
															|en = 'Increase VAT amount'; fa = 'Increase VAT amount';
															|it = 'Importo IVA di aumento';
															|pl = 'Kwota VAT zwiększenia';
															|tr = 'KDV artışı miktarı'");
	
	Else
		
		Items.GroupDebtAdjustment.Title = NStr("vi = 'Điều chỉnh công nợ';
												|ru = 'Корректировка задолженности';
												|en = 'AR/AP adjustment'; fa = 'اصلاح دریافتنی/پرداختنی';
												|it = 'Rettifica dell''indebitamento';
												|pl = 'Korekta zadłużenia';
												|tr = 'Borçların düzenlenmesi'");
		Items.ARAPAdjustmentAdjustmentSum.Title = NStr("vi = 'Số tiền điều chỉnh';
														|ru = 'Сумма корректировки';
														|en = 'Adjustment amount'; fa = 'مبلغ تعدیل';
														|it = 'Importo di rettifica';
														|pl = 'Wartość zapisu korygującego';
														|tr = 'Düzeltme tutarı'");
		Items.ARAPAdjustmentSumOfVATAdjustments.Title = NStr("vi = 'Số tiền thuế GTGT điều chỉnh';
															|ru = 'Сумма НДС корректировки';
															|en = 'Adjustment VAT amount'; fa = 'مبلغ مالیات بر ارزش افزوده تعدیل';
															|it = 'Importo IVA di rettifica';
															|pl = 'Kwota VAT korekty';
															|tr = 'KDV düzeltme tutarı'");
	
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityByOperation()
	
	VisibilityProducts = 
		Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated
		And Object.AdjustmentKind <> Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated;
		
	Items.GroupGoods.Visible = VisibilityProducts;
	
	VisibilityOfElements = 
		Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated
		And Object.AdjustmentKind <> Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated;
		
	Items.DiscrepancyGroup.Visible = VisibilityOfElements;
	
	ThereAreTotalsOfDiscrepancies = 
		Object.AdjustmentKind <> Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated;
	
	ThereAreTotalsOfDiscrepanciesDecrease = 
		Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated;
		
	Items.TotalAmountShovelcharge.Visible = ThereAreTotalsOfDiscrepancies;
	Items.TotalAmountZhamanshina.Visible = ThereAreTotalsOfDiscrepanciesDecrease;
	Items.SummaryTheTotalIncreaseInVAT.Visible = ThereAreTotalsOfDiscrepancies;
	Items.TotalAmountOfTotalReductionWithoutVAT.Visible = ThereAreTotalsOfDiscrepanciesDecrease;
	Items.TotalAmountJavelina.Visible = ThereAreTotalsOfDiscrepancies;
	Items.TotalAmountOfNDSUReduction.Visible = ThereAreTotalsOfDiscrepanciesDecrease;
	
	ThereAreTotals = 
		Object.AdjustmentKind <> Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated
		And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated;
		
	Items.TotalSNDSAmount.Visible = ThereAreTotals;
	Items.GroupTotalVATAmount.Visible = ThereAreTotals;
	Items.GroupTotalAmountWithoutVAT.Visible = ThereAreTotals;
	
	ThisIsDebtAdjustment = 
		Object.AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated
		Or Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated;
	
	Items.GroupDebtAdjustment.Visible = ThisIsDebtAdjustment;
	Items.Partner.ReadOnly = Not ThisIsDebtAdjustment;
	Items.Counterparty.ReadOnly = Not ThisIsDebtAdjustment;
	Items.Organization.ReadOnly = Not ThisIsDebtAdjustment;
	Items.Contract.ReadOnly = Not ThisIsDebtAdjustment;
	Items.VATTaxation.ReadOnly = Not ThisIsDebtAdjustment;
	Items.PurchaseForActivity.ReadOnly = Not ThisIsDebtAdjustment;
	Items.Department.ReadOnly = Not ThisIsDebtAdjustment;
	
	Items.Warehouse.Visible = Not ThisIsDebtAdjustment;
	Items.BaseDocumentPresentation.Visible = Not ThisIsDebtAdjustment;
	Items.PriceIncludesVAT.Visible = Not ThisIsDebtAdjustment;
	Items.Terms.Visible = Not ThisIsDebtAdjustment;
	Items.Contract.Visible = Not ThisIsDebtAdjustment;
	
	ThisIsIncreaseInDebt = 
		Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated;
	Items.GroupOtherExpensesAssetsDebtAdjustment.Visible = ThisIsIncreaseInDebt;
	
	ThisIsReductionInDebt = 
		Object.AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated;
	Items.GroupOtherIncomeLiabilitiesDebtAdjustment.Visible = ThisIsReductionInDebt;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GroupDocumentBeingCorrected", 
		"Visible", ValueIsFilled(Object.DocumentBasis) And Object.AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection);
	
EndProcedure

&AtClientAtServerNoContext
Function ManagingReflectionOptions()
	
	SettingsForReflectionOptions = New Structure();

	SettingsForReflectionOptions.Insert("TSName", "Discrepancies");
	SettingsForReflectionOptions.Insert("ListOfOptionsToChooseFrom", New Array);
	SettingsForReflectionOptions.Insert("PropertyNameForSelectionResult", Undefined);
	SettingsForReflectionOptions.Insert("ThereAreLinesToChange", False);
	SettingsForReflectionOptions.Insert("ThereIsOptionToChangeReflection", False);
	SettingsForReflectionOptions.Insert("OptionSelectionIsInteractive", False);
	
	// The main set of conditions for setting reflection options.
	SettingsForReflectionOptions.Insert("ThereIsIncreaseInNumberOfOrdersInWarehouse", False);
	SettingsForReflectionOptions.Insert("ThereIsIncreaseInQuantityWithoutInventory", False);
	SettingsForReflectionOptions.Insert("ThereIsDecreaseInNumberOfOrdersInWarehouse", False);
	SettingsForReflectionOptions.Insert("ThereIsDecreaseInQuantityWithoutInventory", False);
	SettingsForReflectionOptions.Insert("ThereIsIncreaseOnlyInQuantityOfOrderWarehouse", False);
	SettingsForReflectionOptions.Insert("ThereIsIncreaseOnlyInQuantityWithoutInventory", False);
	SettingsForReflectionOptions.Insert("ThereIsDecreaseOnlyInQuantityOfOrderWarehouse", False);
	SettingsForReflectionOptions.Insert("ThereIsDecreaseOnlyInQuantityWithoutInventory", False);
	SettingsForReflectionOptions.Insert("ThereIsIncreaseInAmount", False);
	SettingsForReflectionOptions.Insert("ThereIsDecreaseInAmount", False);
	SettingsForReflectionOptions.Insert("ThereIsDecreaseOnlyInQuantity", False);
	SettingsForReflectionOptions.Insert("ThereIsIncreaseOnlyInQuantity", False);
		
	// The values that the user sets.
	SettingsForReflectionOptions.Insert("ReflectionOptionIncreasingQuantityByOrderWarehouse", Undefined);
	SettingsForReflectionOptions.Insert("ReflectionOptionIncreaseQuantityWithoutInventory", Undefined);
	SettingsForReflectionOptions.Insert("ReflectionOptionReductionOfQuantityByOrderWarehouse", Undefined);
	SettingsForReflectionOptions.Insert("ReflectionOptionReducingQuantityWithoutInventory", Undefined);
	SettingsForReflectionOptions.Insert("ReflectionOptionIsToIncreaseOnlyQuantityOfOrderWarehouse", Undefined);
	SettingsForReflectionOptions.Insert("ReflectionOptionIsToIncreaseOnlyQuantityWithoutInventory", Undefined);
	SettingsForReflectionOptions.Insert("ReflectionOptionIsToReduceOnlyQuantityOfOrderWarehouse", Undefined);
	SettingsForReflectionOptions.Insert("ReflectionOptionIsToReduceOnlyQuantityWithoutInventory", Undefined);
	SettingsForReflectionOptions.Insert("ReflectionOptionReducingAmount", Undefined);
	SettingsForReflectionOptions.Insert("ReflectionOptionIncreaseAmount", Undefined);
	SettingsForReflectionOptions.Insert("ReflectionOptionIsToReduceOnlyNumber", Undefined);
	SettingsForReflectionOptions.Insert("ReflectionOptionIsToIncreaseOnlyNumber", Undefined);
	
	Return SettingsForReflectionOptions;
	
EndFunction

&AtClient
Procedure DefineGroupsOfReflectionOptionsToSelect(TableOfDiscrepancies, SettingsForReflectionOptions)
	
	For Each LineOfDiscrepancies In TableOfDiscrepancies Do
			
		If (LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
			Or LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
			And Not LineOfDiscrepancies.ToExpenseAs Then	
			
			If LineOfDiscrepancies.NumberOfPackages > 0 And LineOfDiscrepancies.AmountIncludingVAT <> 0
			 	And LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				SettingsForReflectionOptions.ThereIsIncreaseInNumberOfOrdersInWarehouse = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			ElsIf LineOfDiscrepancies.NumberOfPackages > 0 And LineOfDiscrepancies.AmountIncludingVAT <> 0
				 And Not LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				SettingsForReflectionOptions.ThereIsIncreaseInQuantityWithoutInventory = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			ElsIf LineOfDiscrepancies.NumberOfPackages < 0 And LineOfDiscrepancies.AmountIncludingVAT <> 0
				 And LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				SettingsForReflectionOptions.ThereIsDecreaseInNumberOfOrdersInWarehouse = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			ElsIf LineOfDiscrepancies.NumberOfPackages < 0 And LineOfDiscrepancies.AmountIncludingVAT <> 0
				 And Not LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				SettingsForReflectionOptions.ThereIsDecreaseInQuantityWithoutInventory = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			ElsIf LineOfDiscrepancies.NumberOfPackages > 0 And LineOfDiscrepancies.AmountIncludingVAT = 0
			 	And LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				SettingsForReflectionOptions.ThereIsIncreaseOnlyInQuantityOfOrderWarehouse = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			ElsIf LineOfDiscrepancies.NumberOfPackages > 0 And LineOfDiscrepancies.AmountIncludingVAT = 0
				 And Not LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				SettingsForReflectionOptions.ThereIsIncreaseOnlyInQuantityWithoutInventory = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			ElsIf LineOfDiscrepancies.NumberOfPackages < 0 And LineOfDiscrepancies.AmountIncludingVAT = 0
				 And LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				SettingsForReflectionOptions.ThereIsDecreaseOnlyInQuantityOfOrderWarehouse = True;
				
			ElsIf LineOfDiscrepancies.NumberOfPackages < 0 And LineOfDiscrepancies.AmountIncludingVAT = 0
				 And Not LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				SettingsForReflectionOptions.ThereIsDecreaseOnlyInQuantityWithoutInventory = True;
			    SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			ElsIf LineOfDiscrepancies.NumberOfPackages = 0 And LineOfDiscrepancies.AmountIncludingVAT < 0 Then
				
				SettingsForReflectionOptions.ThereIsDecreaseInAmount = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			ElsIf LineOfDiscrepancies.NumberOfPackages = 0 And LineOfDiscrepancies.AmountIncludingVAT > 0 Then
				
				SettingsForReflectionOptions.ThereIsIncreaseInAmount = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			EndIf;
			
		EndIf;
		
		If (LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")
				Or LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
				Or LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.EmptyRef"))
			Or (LineOfDiscrepancies.ToExpenseAs And
				(LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
				Or LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))) Then
			
			If LineOfDiscrepancies.AmountIncludingVAT < 0 Then
				
				SettingsForReflectionOptions.ThereIsDecreaseInAmount = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			ElsIf LineOfDiscrepancies.AmountIncludingVAT > 0 Then
				
				SettingsForReflectionOptions.ThereIsIncreaseInAmount = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			ElsIf LineOfDiscrepancies.NumberOfPackages < 0 Then
				
				SettingsForReflectionOptions.ThereIsDecreaseOnlyInQuantity = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			ElsIf LineOfDiscrepancies.NumberOfPackages > 0 Then
				
				SettingsForReflectionOptions.ThereIsIncreaseOnlyInQuantity = True;
				SettingsForReflectionOptions.ThereAreLinesToChange = True;
				
			EndIf;
			
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInReflectionOptionsForGroups(SettingsForReflectionOptions)
	
	If SettingsForReflectionOptions.ThereIsIncreaseInNumberOfOrdersInWarehouse Then
		
		ListOfReflectionOptions = New ValueList;
		
		If Not BasisDiscrepancyCertificateAfterReceiving Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs"));
		EndIf;
		
		If UninvoicedReceiptDocumentIsUsed Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners"));
		Else
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncludeDuringPhysicalInventoryCount"));
		EndIf;
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionIncreasingQuantityByOrderWarehouse", ListOfReflectionOptions));
		
	EndIf;
	
	If SettingsForReflectionOptions.ThereIsIncreaseInQuantityWithoutInventory Then
		
		ListOfReflectionOptions = New ValueList;
		
		If Not BasisDiscrepancyCertificateAfterReceiving Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs"));
		EndIf;
		
		If UninvoicedReceiptDocumentIsUsed Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners"));
		Else
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock"));
		EndIf;
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionIncreaseQuantityWithoutInventory", ListOfReflectionOptions));
		
	EndIf;
	
	If SettingsForReflectionOptions.ThereIsDecreaseInNumberOfOrdersInWarehouse Then
		
		ListOfReflectionOptions = New ValueList;
		If Not BasisDiscrepancyCertificateAfterReceiving Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome"));
		EndIf;
		
		If UninvoicedReceiptDocumentIsUsed Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners"));
		Else
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseIncludeDuringPhysicalInventoryCount"));
		EndIf;
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionReductionOfQuantityByOrderWarehouse", ListOfReflectionOptions));
		
	EndIf;
	
	If SettingsForReflectionOptions.ThereIsDecreaseInQuantityWithoutInventory Then
		
		ListOfReflectionOptions = New ValueList;
		If Not BasisDiscrepancyCertificateAfterReceiving Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome"));
		EndIf;
		
		If UninvoicedReceiptDocumentIsUsed Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners"));
		Else
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock"));
		EndIf;
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionReducingQuantityWithoutInventory", ListOfReflectionOptions));
		
	EndIf;
	
	If SettingsForReflectionOptions.ThereIsIncreaseOnlyInQuantityOfOrderWarehouse Then
		
		ListOfReflectionOptions = New ValueList;
		
		If UninvoicedReceiptDocumentIsUsed Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners"));
		Else
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncludeDuringPhysicalInventoryCount"));
		EndIf;
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionIsToIncreaseOnlyQuantityOfOrderWarehouse", ListOfReflectionOptions));
		
	EndIf;
	
	If SettingsForReflectionOptions.ThereIsIncreaseOnlyInQuantityWithoutInventory Then
		
		ListOfReflectionOptions = New ValueList;
		
		If UninvoicedReceiptDocumentIsUsed Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners"));
		Else
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock"));
		EndIf;
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionIsToIncreaseOnlyQuantityWithoutInventory", ListOfReflectionOptions));
		
	EndIf;
	
	If SettingsForReflectionOptions.ThereIsDecreaseOnlyInQuantityOfOrderWarehouse Then
		
		ListOfReflectionOptions = New ValueList;
		
		If UninvoicedReceiptDocumentIsUsed Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners"));
		Else
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseIncludeDuringPhysicalInventoryCount"));
		EndIf;
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionIsToReduceOnlyQuantityOfOrderWarehouse", ListOfReflectionOptions));
		
	EndIf;
	
	If SettingsForReflectionOptions.ThereIsDecreaseOnlyInQuantityWithoutInventory Then
		
		ListOfReflectionOptions = New ValueList;
		
		If UninvoicedReceiptDocumentIsUsed Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners"));
		Else
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock"));
		EndIf;
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionIsToReduceOnlyQuantityWithoutInventory", ListOfReflectionOptions));
		
	EndIf;
	
	If SettingsForReflectionOptions.ThereIsDecreaseInAmount Then
		
		ListOfReflectionOptions = New ValueList;
		If Not BasisDiscrepancyCertificateAfterReceiving Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome"));
		EndIf;
		
		If UninvoicedReceiptDocumentIsUsed Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners"));
		Else
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost"));
		EndIf;
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionReducingAmount", ListOfReflectionOptions));
		
	EndIf;
	
	If SettingsForReflectionOptions.ThereIsIncreaseInAmount Then
		
		ListOfReflectionOptions = New ValueList;
		If Not BasisDiscrepancyCertificateAfterReceiving Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs"));
		EndIf;
		
		If UninvoicedReceiptDocumentIsUsed Then
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners"));
		Else
			ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost"));
		EndIf;
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionIncreaseAmount", ListOfReflectionOptions));
		
	EndIf;
	
	If SettingsForReflectionOptions.ThereIsDecreaseOnlyInQuantity Then
		
		ListOfReflectionOptions = New ValueList;
		ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost"));
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionIsToReduceOnlyNumber", ListOfReflectionOptions));
		
	EndIf;

	If SettingsForReflectionOptions.ThereIsIncreaseOnlyInQuantity Then
		
		ListOfReflectionOptions = New ValueList;
		ListOfReflectionOptions.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost"));
		
		SettingsForReflectionOptions.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionIsToIncreaseOnlyNumber", ListOfReflectionOptions));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectInteractivelyOptionsForReflectingAdjustmentsToImplementationsFragment(AdditionalParameters);

	If AdditionalParameters.ListOfOptionsToChooseFrom.Count() > 0 Then
		
		ListOfReflectionOptions = AdditionalParameters.ListOfOptionsToChooseFrom[0].ListOfReflectionOptions;
		StructureFilter = New Structure("Ref", ListOfReflectionOptions);
		AdditionalParameters.PropertyNameForSelectionResult = AdditionalParameters.ListOfOptionsToChooseFrom[0].PropertyNameForSelectionResult;
		AdditionalParameters.ListOfOptionsToChooseFrom.Delete(0);
		If ListOfReflectionOptions.Count() > 1 Then
			If AdditionalParameters.OptionSelectionIsInteractive Then
				OpenForm(
					"Enum.OptionsOfPostingReceiptAdjustingEntries.ChoiceForm", 
					New Structure("Filter, PropertyNameForSelectionResult", StructureFilter, AdditionalParameters.PropertyNameForSelectionResult),,,,,
					New CallbackDescription("SelectOptionsForReflectingImplementationAdjustmentsInteractively", ThisObject, AdditionalParameters), FormWindowOpeningMode.LockOwnerWindow);
				Return;
			Else
				SelectOptionsForReflectingImplementationAdjustmentsInteractively(Undefined, AdditionalParameters);
			EndIf;
		Else
			SelectOptionsForReflectingImplementationAdjustmentsInteractively(ListOfReflectionOptions[0].Value, AdditionalParameters);
		EndIf;
	Else
		
		// PM processing based on the results of the user's choice of reflection options.
		SetRecordingOptionsCompletion(AdditionalParameters);
		FillInCheckQualityDateOfQualityConfirmationServer();
		
	EndIf;
		
EndProcedure

&AtClient
Procedure SelectOptionsForReflectingImplementationAdjustmentsInteractively(PostingOption, AdditionalParameters) Export
	
	PropertyNameForSelectionResult = Undefined;
	If AdditionalParameters.Property("PropertyNameForSelectionResult", PropertyNameForSelectionResult) Then
		AdditionalParameters[PropertyNameForSelectionResult] = PostingOption;
		AdditionalParameters.ThereIsOptionToChangeReflection = True;
	EndIf;
	SelectInteractivelyOptionsForReflectingAdjustmentsToImplementationsFragment(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure SetRecordingOptionsCompletion(SettingsForReflectionOptions)
	
	If SettingsForReflectionOptions.ThereIsOptionToChangeReflection Then 
		
		For Each LineOfDiscrepancies In Object.Discrepancies Do
			
			If (LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
				Or LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
				And Not LineOfDiscrepancies.ToExpenseAs Then
				
				If LineOfDiscrepancies.NumberOfPackages > 0 And LineOfDiscrepancies.AmountIncludingVAT <> 0
					And LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionIncreasingQuantityByOrderWarehouse) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionIncreasingQuantityByOrderWarehouse;
					
				ElsIf LineOfDiscrepancies.NumberOfPackages > 0 And LineOfDiscrepancies.AmountIncludingVAT <> 0
					And (Not LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages)
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionIncreaseQuantityWithoutInventory) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionIncreaseQuantityWithoutInventory;
					
				ElsIf LineOfDiscrepancies.NumberOfPackages < 0 And LineOfDiscrepancies.AmountIncludingVAT <> 0
					And LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionReductionOfQuantityByOrderWarehouse) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionReductionOfQuantityByOrderWarehouse;
					
				ElsIf LineOfDiscrepancies.NumberOfPackages < 0 And LineOfDiscrepancies.AmountIncludingVAT <> 0
					And (Not LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages)
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionReducingQuantityWithoutInventory) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionReducingQuantityWithoutInventory;
					
				ElsIf LineOfDiscrepancies.NumberOfPackages > 0 And LineOfDiscrepancies.AmountIncludingVAT = 0
					And LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionIsToIncreaseOnlyQuantityOfOrderWarehouse) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionIsToIncreaseOnlyQuantityOfOrderWarehouse;
					
				ElsIf LineOfDiscrepancies.NumberOfPackages > 0 And LineOfDiscrepancies.AmountIncludingVAT = 0
					And (Not LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages)
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionIsToIncreaseOnlyQuantityWithoutInventory) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionIsToIncreaseOnlyQuantityWithoutInventory;
					
				ElsIf LineOfDiscrepancies.NumberOfPackages < 0 And LineOfDiscrepancies.AmountIncludingVAT = 0
					And LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionIsToReduceOnlyQuantityOfOrderWarehouse) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionIsToReduceOnlyQuantityOfOrderWarehouse;
					
				ElsIf LineOfDiscrepancies.NumberOfPackages < 0 And LineOfDiscrepancies.AmountIncludingVAT = 0
					And (Not LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages)
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionIsToReduceOnlyQuantityWithoutInventory) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionIsToReduceOnlyQuantityWithoutInventory;
				
				ElsIf LineOfDiscrepancies.NumberOfPackages = 0
					And LineOfDiscrepancies.AmountIncludingVAT < 0
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionReducingAmount) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionReducingAmount;
					
				ElsIf LineOfDiscrepancies.NumberOfPackages = 0
					And LineOfDiscrepancies.AmountIncludingVAT > 0
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionIncreaseAmount) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionIncreaseAmount;
					
				EndIf;
				
			EndIf;
			
			If (LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")
					Or LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
					Or LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.EmptyRef"))
				Or (LineOfDiscrepancies.ToExpenseAs And
					(LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
					Or LineOfDiscrepancies.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))) Then
				
				If LineOfDiscrepancies.AmountIncludingVAT < 0
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionReducingAmount) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionReducingAmount;
					
				ElsIf LineOfDiscrepancies.AmountIncludingVAT > 0
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionIncreaseAmount) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionIncreaseAmount;
					
				ElsIf LineOfDiscrepancies.NumberOfPackages < 0
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionIsToReduceOnlyNumber) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionIsToReduceOnlyNumber;
					
				ElsIf LineOfDiscrepancies.NumberOfPackages > 0
					And ValueIsFilled(SettingsForReflectionOptions.ReflectionOptionIsToIncreaseOnlyNumber) Then
					LineOfDiscrepancies.PostingOption = SettingsForReflectionOptions.ReflectionOptionIsToIncreaseOnlyNumber;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
		
	EndIf;
	
EndProcedure	

&AtServer
Procedure CustomizeElementsOfDocumentBeingCorrected()
	
	DocumentBeingCorrectedIsDisplayed = Items.GroupDocumentBeingCorrected.Visible;
	
	If Not DocumentBeingCorrectedIsDisplayed Then
		Return;	
	EndIf;	
		
	DocumentBeingCorrectedHasBeenFilledIn = ValueIsFilled(Object.CorrectedDocument);
	WidthOfDocumentBeingCorrectedElement = 0;
	TextColorChangeDocumentBeingCorrected = New Color;

	If DocumentBeingCorrectedHasBeenFilledIn Then
		WidthOfDocumentBeingCorrectedElement = 15;			
	Else
		WidthOfDocumentBeingCorrectedElement = 22;			
		TextColorChangeDocumentBeingCorrected = StyleColors.SpecialTextColor;
	EndIf;

	TMCommonUseClientServer.SetFormItemProperty(Items, "PresentationOfCorrectedDocument", 
		"Width", WidthOfDocumentBeingCorrectedElement);	
	TMCommonUseClientServer.SetFormItemProperty(Items, "PresentationOfCorrectedDocument", 
		"TextColor", TextColorChangeDocumentBeingCorrected);
	TMCommonUseClientServer.SetFormItemProperty(Items, "EditDocumentBeingCorrected", 
		"Visible", DocumentBeingCorrectedHasBeenFilledIn);
	
EndProcedure

&AtServer
Procedure UpdatePresentationElementsOfDocumentBeingCorrected()
	
	PresentationOfCorrectedDocument = DocumentCorrection.PresentationOfCorrectedDocument(Object.CorrectedDocument);	
		
	If Not ValueIsFilled(PresentationOfCorrectedDocument) Then
		PresentationOfCorrectedDocument = NStr("vi = 'Hãy chọn chứng từ được chỉnh sửa';
												|ru = 'Выберите исправляемый документ';
												|en = 'Select the document to correct'; fa = 'Select the document to correct';
												|it = 'Выберите исправляемый документ';
												|pl = 'Select the document to correct';
												|tr = 'Düzeltme belgesini seçin'");
	EndIf;	
	
	CustomizeElementsOfDocumentBeingCorrected();
		
EndProcedure


&AtClient
Procedure ProcessingSelectionOfDocumentBeingCorrected(Val ValueSelected)
	
	If ValueIsFilled(ValueSelected) Then
		Object.CorrectedDocument = ValueSelected;	
	EndIf;
	
	UpdatePresentationElementsOfDocumentBeingCorrected();
	
EndProcedure

&AtClient
Procedure PickUpDocumentToBeCorrected()

	CorrectionDate = Object.Date;
	
	If Not ValueIsFilled(Object.Ref) Then
		CorrectionDate = Undefined;	
	EndIf;	

	ListParameters = New Structure;
	ListParameters.Insert("DocumentBasis", Object.DocumentBasis);
	ListParameters.Insert("CorrectionDate", CorrectionDate);
		
	OpenForm("Document.PurchaseAdjustment.Form.ChoiceFormOfCorrectedDocument", ListParameters, ThisObject);
	
EndProcedure
&AtServerNoContext
Function GoodsAreTraceable(CCDNumber)
	
	Return VendorInvoiceServicesAndAssetsLocalization.GoodsAreTraceable(CCDNumber);
	
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

#EndRegion

#Region ControlOfInconsistentChanges


// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = "Date" Then
		DateOnChange(Item);
	ElsIf Item.Name = "Operation" Then
		OperationOnChange(Item);
	ElsIf Item.Name = "VATTaxation" Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = "PriceIncludesVAT" Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = "GoodsPartnerProducts" Then
		GoodsPartnerProductsOnChange(Item);
	ElsIf Item.Name = "GoodsProducts" Then
		GoodsProductsOnChange(Item);
	ElsIf Item.Name = "GoodsCharacteristic" Then
		GoodsCharacteristicOnChange(Item);
	ElsIf Item.Name = "GoodsSeries" Then
		GoodsSeriesOnChange(Item);
	ElsIf Item.Name = "GoodsNumberOfPackages" Then
		GoodsNumberOfPackagesOnChange(Item);
	ElsIf Item.Name = "GoodsPackage" Then
		GoodsPackageOnChange(Item);
	ElsIf Item.Name = "GoodsCount" Then
		GoodsCountOnChange(Item);
	ElsIf Item.Name = "GoodsPrice" Then
		GoodsPriceOnChange(Item);
	ElsIf Item.Name = "GoodsSum" Then
		GoodsSumOnChange(Item);
	ElsIf Item.Name = "DiscrepanciesAmountARAP" Then
		DiscrepanciesAmountARAPOnChange(Item)
	ElsIf Item.Name = "GoodsVATRate" Then
		GoodsVATRateOnChange(Item);
	ElsIf Item.Name = "GoodsVATAmount" Then
		GoodsVATAmountOnChange(Item);
	ElsIf Item.Name = "GoodsWarehouse" Then
		GoodsWarehouseOnChange(Item);
	ElsIf Item.Name = "GoodsPurchaseOrder" Then
		GoodsPurchaseOrderOnChange(Item);
	ElsIf Item.Name = "GoodsDepartment" Then
		
	ElsIf Item.Name = "GoodsToExpenseAs" Then
		GoodsToExpenseAsOnChange(Item);
	ElsIf Item.Name = "GoodsExpenseItem" Then
		GoodsExpenseItemOnChange(Item);
	ElsIf Item.Name = "GoodsPurpose" Then
		GoodsPurposeOnChange(Item);
	ElsIf Item.Name = "DiscrepanciesToControlQuality" Then
		DiscrepanciesToControlQualityOnChange(Item);
	ElsIf Item.Name = "DiscrepanciesQualityConfirmationDate" Then
		DiscrepanciesQualityConfirmationDateOnChange(Item);
	ElsIf Item.Name = Items.GoodsCCDNumber.Name Then
		GoodsCCDNumberOnChange(Item);
	ElsIf Item.Name = Items.ARAPAdjustmentVATRate.Name Then
		ARAPAdjustmentVATRateOnChange(Item);
	ElsIf Item.Name = Items.ARAPAdjustmentAdjustmentSum.Name Then
		ARAPAdjustmentAdjustmentSumOnChange(Item);
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
	ElsIf Command.Name = "FillInBySourceData" Then
		FillInBySourceData(Command);
	ElsIf Command.Name = "FillInAccordingToDiscrepancyCertificate" Then
		FillInAccordingToDiscrepancyCertificate(Command);
	ElsIf Command.Name = "SelectGoods" Then
		SelectGoods(Command);
	ElsIf Command.Name = "SelectGoodsFromOrder" Then
		SelectGoodsFromOrder(Command);
	ElsIf Command.Name = "FillInTheItemByThePartnerSItem" Then
		FillInTheItemByThePartnerSItem(Command);
	ElsIf Command.Name = "FillInVATRate" Then
		FillInVATRate(Command);
	ElsIf Command.Name = "SplitRow" Then
		SplitRow(Command);
	ElsIf Command.Name = "InsertRows" Then
		InsertRows(Command);
	ElsIf Command.Name = "FillThePricesByTermsOfSales" Then
		FillThePricesByTermsOfSales(Command);
	ElsIf Command.Name = "FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPrices" Then
		FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPrices(Command);
	ElsIf Command.Name = "FillInTheWarehouseInSelectedLines" Then
		FillInTheWarehouseInSelectedLines(Command);
	ElsIf Command.Name = "FillInTheDiscrepancies" Then
		FillInTheDiscrepancies(Command);
	ElsIf Command.Name = "SetRecordingOptions" Then
		SetRecordingOptions(Command);
	ElsIf Command.Name = "PickUpDocumentsForDebtAdjustment" Then
		PickUpDocumentsForDebtAdjustment(Command);
	ElsIf Command.Name = "CalculateAmountOfDebtAdjustmentForInterest" Then
		CalculateAmountOfDebtAdjustmentForInterest(Command);
	ElsIf Command.Name = "DistributeTotalAmountOfDebtAdjustmentToDocuments" Then
		DistributeTotalAmountOfDebtAdjustmentToDocuments(Command);
	ElsIf Command.Name = "FillInReasonForDebtAdjustment" Then
		FillInReasonForDebtAdjustment(Command);
	ElsIf Command.Name = "EditDocumentBeingCorrected" Then
		EditDocumentBeingCorrected(Command);
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
	If Item.Name = Items.ARAPAdjustment.Name Then
		ARAPAdjustmentBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Undefined);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

&AtClient
Function PerformChecksBeforeChangingStatus()
	
	Var ThereAreAdjustingEntries;
	Var CorrectionAfterDocumentDate;
	
	PropsCanBeChanged = False;
	
	AdditionalParameters = New Structure;
	Notification = New CallbackDescription(
			"QuestionResultCompletion", ThisObject, AdditionalParameters);
	
	If StructureOfActionsControlOfNonAgreedChanges = Undefined
		Or StructureOfActionsControlOfNonAgreedChanges.AlertIsExpected Then
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	ClearMessages();
	
	CheckForAdjustments(Object.Ref, Object.DocumentBasis, ThereAreAdjustingEntries);
	CorrectionAfterDocumentDate = CheckForCorrectionsAfterDocumentDate(Object.Ref);
	
	If ThereAreAdjustingEntries Then
		
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
				|tr = 'Temel belgeye bir satın alma düzeltmesi girilmiştir.
				| Orijinal belge değiştirilemez.'"),
			ButtonsList,
			,
			"EnterTheAdjustment");
		
	ElsIf ValueIsFilled(CorrectionAfterDocumentDate) Then
		
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
			NStr("vi = 'Nếu chỉnh sửa muộn hơn ngày của chứng từ hiện tại.
				|Đã cấm thay đổi chứng từ.';
				|ru = 'Есть исправление позднее даты текущего документа.
				|Изменение документа запрещено.';
				|en = 'There is a correction later than the current document date.
				|Cannot edit the document.'; fa = 'There is a correction later than the current document date.
				|Cannot edit the document.';
				|it = 'Есть исправление позднее даты текущего документа.
				|Изменение документа запрещено.';
				|pl = 'There is a correction later than the current document date.
				|Cannot edit the document.';
				|tr = 'Mevcut belgenin tarihinden daha sonra düzeltme mevcut.
				|Belgenin değiştirilmesi yasaktır.'"),
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
	
	If ResponseCode = "EnterTheAdjustment" Then
		OpenForm("Document.PurchaseAdjustment.ObjectForm", New Structure("Basis", Object.DocumentBasis));
	EndIf;
	
	CalculateFinalRevenueFigures(ThisForm);
	
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
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	Columns = "Products,Characteristic,Content,Package,NumberOfPackages,Count,Price,CCDNumber,Warehouse,
		|Department,LineOfBusiness,ItemsType";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	If TableOfGoods.Columns.Find("ItemsType") = Undefined Then
		TableOfGoods.Columns.Add("ItemsType", New TypeDescription("EnumRef.ItemsTypes"));
	EndIf;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ToReturnReusablePackage);
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
			StructureOfActions);
	EndIf;
	
	If NumberOfPackagesIsUsed Then
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	Else
		AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisForm);
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions,
			"Warehouse",
			True);
	EndIf;
	
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		EconomicOperationsOfSeparatePurchase = EconomicOperationsOfSeparatePurchase();
		
		If EconomicOperationsOfSeparatePurchase.Find(Object.BusinessOperation) <> Undefined Then
			SelectionByTypeOfNomenclature = ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False);
		ElsIf SubcontractorReportAdjustment Then
			SelectionByTypeOfNomenclature = ProductsClientServer.JobSelection(False);
		Else
			SelectionByTypeOfNomenclature = ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False);
		EndIf;
	EndIf;
	
	RowsToProcess = New Array();
	For Each RowOfProduct In TableOfGoods Do
		
		If Not AdjustmentOfPurchaseOfOtherAssetServices Then
			If SelectionByTypeOfNomenclature.Find(RowOfProduct.ItemsType) = Undefined Then
				Continue;
			EndIf;
		EndIf;
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		RowsToProcess.Add(CurrentRow);
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	For Each CurrentRow In RowsToProcess Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Goods");
		
		If AdjustmentOfPurchaseOfOtherAssetServices Then
			FillInOfficialTraceabilityAttributesInProductLine(CurrentRow);
		EndIf;
	EndDo;
	
	ActionsForFillIn = New Structure;
	ActionsForFillIn.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ActionsForFillIn.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		ActionsForFillIn.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ActionsForFillIn);
	EndIf;
	ActionsForFillIn.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ActionsForFillIn);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	FillInAttributeForDebitingExpensesForServices();
	
	WhenChangingWarehouseInTablePartServer();
	DiscrepanciesAreRelevant = False;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
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

#Region WorkingWithCounterparties





&AtClient
Procedure CheckCounterparties(Command)
	
	
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

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
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
		If NumberOfPackagesIsUsed Then
			AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions, ThisObject);
		Else
			AddActionsToStructureWhenQuantityChanges(ProcessingActions, ThisObject);
		EndIf;
	Else
		If NumberOfPackagesIsUsed Then
			AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
				Object,
				ProcessingActions,
				"Warehouse",
				True);
		EndIf;
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												Undefined,
												ProcessingActions);
	
	CalculateFinalRevenueFigures(ThisObject);
	
	DiscrepanciesAreRelevant = False;
	
EndProcedure

#EndRegion

#Region CostGroups

&AtServer
Procedure SetDefaultCostGroupNumber(CurrentID)
	
	CurrentData = Object.Goods.FindByID(CurrentID);
	
	If Not CurrentData = Undefined
		And CurrentData.CostGroupNumber = 0
		And NumberOfCostGroups = 1 Then
		
		CurrentData.ExpenseGroup = CostGroups[0].ExpenseGroup;
		CurrentData.CostGroupNumber = CostGroups[0].CostGroupNumber;
		CurrentData.ProductionStage  = CostGroups[0].ReferenceOrder;
	EndIf;
	
EndProcedure

&AtServer
Function PutCostGroupDataInStorage()
	
	Table = CostGroups.Unload();
	Return PutToTempStorage(Table, UUID);
	
EndFunction

&AtClient
Procedure TableCostGroupStartOfSelectionCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	TableCostGroupStartSelectionEndOnServer(Result, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure TableCostGroupStartSelectionEndOnServer(Result, Val SelectedRows)

	For Each RowID In SelectedRows Do
		
		CurrentData = Object.Goods.FindByID(RowID);
		
		CurrentData.CostGroupNumber = Result.CostGroupNumber;
		CurrentData.ExpenseGroup      = Result.ExpenseGroup;
		CurrentData.ProductionStage  = Result.ReferenceOrder;
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateCostGroups()
	
	If Not SubcontractorReportAdjustment
		Or Not ValueIsFilled(Object.DocumentBasis) Then
		Return;
	EndIf;
	
	DocumentAttributes =
		Common.ObjectAttributesValues(
			Object.DocumentBasis,
			"GroupCosts, ByOrders, SubcontractOrder, MaximumNumberOfCostGroup, ManufacturedProducts");
	
	Documents.SubcontractorReport2_5.UpdateCostGroups(DocumentAttributes, CostGroups, NumberOfCostGroups);
	
	UpdateCostGroupPresentation();
	
EndProcedure

&AtServer
Procedure UpdateCostGroupPresentation()
	
	If Not SubcontractorReportAdjustment Then
		Return;
	EndIf;
	
	FilterStructure1 = New Structure("CostGroupNumber");
	
	For Each CurGroup In CostGroups Do
		
		CurGroup.ExpenseGroup = CostGroupPresentation(CurGroup);
		
		FillPropertyValues(FilterStructure1, CurGroup);
		
		Rows = Object.Goods.FindRows(FilterStructure1);
		For Each CurRow In Rows Do
			CurRow.ExpenseGroup = CurGroup.ExpenseGroup;
		EndDo;
		
		Rows = Object.Discrepancies.FindRows(FilterStructure1);
		For Each CurRow In Rows Do
			CurRow.ExpenseGroup = CurGroup.ExpenseGroup;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Function CostGroupPresentation(Var_Group)
	
	Return ProcessingByThirdPartiesClientServer.CostGroupPresentation(
				Var_Group,
				ProcessingByThirdPartiesClientServer.ListOfCostGroupFieldsInProcessorSReport(GroupingOfBaseCosts));
	
EndFunction 

#EndRegion

&AtClient
Procedure DateOfChangeAfterVerification(Result, AdditionalParameters) Export
	
	FillInTheDiscrepanciesServer();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtClient
Procedure FillInBySourceDataCompletion(Result, AdditionalParameters) Export 
	
	FillInBySourceDataServer();
		
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		If NumberOfPackagesIsUsed Then
			AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
		Else
			AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisForm);
		EndIf;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		DiscrepanciesAreRelevant = False;
		
	EndIf;
	
	WhenChangingWarehouseInTablePartServer();
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
	CalculateFinalRevenueFigures(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInTheDiscrepanciesCompletion(Result, AdditionalParameters) Export 
	
	FillDiscrepanciesCompletionOnServer();
	
	SettingsForReflectionOptions = ManagingReflectionOptions();
	SettingsForReflectionOptions.OptionSelectionIsInteractive = False;
	
	DefineGroupsOfReflectionOptionsToSelect(Object.Discrepancies, SettingsForReflectionOptions);	
	FillInReflectionOptionsForGroups(SettingsForReflectionOptions);
	SelectInteractivelyOptionsForReflectingAdjustmentsToImplementationsFragment(SettingsForReflectionOptions);
    
EndProcedure

&AtServer
Procedure FillDiscrepanciesCompletionOnServer()
	
	FillInTheDiscrepanciesServer();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	CalculateFinalRevenueFigures(ThisForm);
	
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
	Items.DiscrepanciesWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	WarehouseSelectionData = WarehouseSelectionData(Object.Warehouse);
	
	TMCommonUseClientServer.AddSelectionParameter(Items.GoodsWarehouse, "Ref", WarehouseSelectionData);
	TMCommonUseClientServer.AddSelectionParameter(Items.DiscrepanciesWarehouse, "Ref", WarehouseSelectionData);
	
EndProcedure

&AtServer
Procedure SetProductSelectionParameters()
	If SubcontractorReportAdjustment Then
		ParametersArray = New Array;
		
		ParametersArray.Add(
			New ChoiceParameter(
				"Filter.ItemsType",
				New FixedArray(ProductsClientServer.JobSelection(False))));
		
		Items.GoodsProducts.ChoiceParameters = New FixedArray(ParametersArray);
		Items.DiscrepanciesProducts.ChoiceParameters = New FixedArray(ParametersArray);
	Else
		ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts);
		ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsPartnerProducts);
	EndIf;
EndProcedure

&AtServer
Procedure SetParametersForSelectingGTDINumberOfHSCode()
	
	ArrayOfCCDNumberParameters = New Array;
	ArrayOfParametersOfHSCode = New Array;
	ArrayOfCCDTypes = New ValueList;
	ArrayOfCCDTypes.Add(Enums.CCDNumberTypes.ProductBatchIDNumber);
	ArrayOfCCDTypes.Add(Enums.CCDNumberTypes.KitRNPT);
	
	If AdjustmentOfPurchaseOfOtherAssetServices Then
		ArrayOfCCDNumberParameters.Add(
			New ChoiceParameter(
				"ListOfCCDTypes",
				ArrayOfCCDTypes));
		
		ArrayOfParametersOfHSCode.Add(
			New ChoiceParameter(
				"Filter.TracedGoods",
				True));
		
	EndIf;
	Items.GoodsCCDNumber.ChoiceParameters = New FixedArray(ArrayOfCCDNumberParameters);
	Items.GoodsFEACNCode.ChoiceParameters = New FixedArray(ArrayOfParametersOfHSCode);
	
EndProcedure


&AtServer
Procedure SetHeadingIncomeExpenseItem()
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.GoodsExpenseItem.Title = NStr("vi = 'Ghi giảm vào chi phí';
											|ru = 'Списать на расходы';
											|en = 'Expense as'; fa = 'هزینه به عنوان';
											|it = 'Stornare sulle spese';
											|pl = 'Spisać w koszty';
											|tr = 'Gider olarak kaydet'");
		Items.DiscrepanciesToExpenseAs.Title = NStr("vi = 'Ghi giảm vào chi phí';
													|ru = 'Списать на расходы';
													|en = 'Expense as'; fa = 'هزینه به عنوان';
													|it = 'Stornare sulle spese';
													|pl = 'Spisać w koszty';
													|tr = 'Gider yazın'");
		Items.TextAmountForOtherExpensesAssets.Title = NStr("vi = 'Đối với chi phí:';
															|ru = 'На расходы:';
															|en = 'To expenses:'; fa = 'To expenses:';
															|it = 'Sulle spese:';
															|pl = 'Na wydatki:';
															|tr = 'Masraflar:'");
		Items.TextAmountForOtherIncomeLiabilities.Title = NStr("vi = 'Về thu nhập:';
																|ru = 'На доходы:';
																|en = 'To income:'; fa = 'To income:';
																|it = 'Sui ricavi:';
																|pl = 'Na dochody:';
																|tr = 'Gelirler:'");
		Items.ExpenseItem.Title = NStr("vi = 'Dạng chi phí';
										|ru = 'Статья расходов';
										|en = 'Expense item'; fa = 'قلم هزینه';
										|it = 'Voce di spese';
										|pl = 'Rodzaj kosztu';
										|tr = 'Gider kalemi'");
		Items.IncomeItem.Title = NStr("vi = 'Dạng thu nhập';
										|ru = 'Статья доходов';
										|en = 'Income item'; fa = 'قلم درآمد';
										|it = 'Voce dei ricavi';
										|pl = 'Rodzaj przychodów';
										|tr = 'Gelir kalemi'");
	EndIf;
	
EndProcedure

&AtServerNoContext
Function EconomicOperationOfFoundationDocument(DocumentBasis)
	
	Operation = Enums.BusinessTransactions.EmptyRef();
	
	If ValueIsFilled(DocumentBasis)
		And TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
		Operation = Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation");
	ElsIf ValueIsFilled(DocumentBasis)
		And TypeOf(DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
		Operation = Enums.BusinessTransactions.SubcontractorReportAdjustment;
	EndIf;
	
	Return Operation;
	
EndFunction

&AtServer
Procedure SetBusinessOperationOfDocument(DocumentBasis)
	
	BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
	If TypeOf(DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
		BusinessOperation = Enums.BusinessTransactions.SubcontractorReportAdjustment;
	EndIf;
	If Object.BusinessOperation <> BusinessOperation Then
		Object.BusinessOperation = BusinessOperation;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInUsedDocumentReceiptOfGoodsAttribute()
	
	If ValueIsFilled(Operation) Then
		SeparatePurchaseOperations = New Array;
		SeparatePurchaseOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
		SeparatePurchaseOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
		SeparatePurchaseOperations.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
		SeparatePurchaseOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
		SeparatePurchaseOperations.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
		
		UninvoicedReceiptDocumentIsUsed = SeparatePurchaseOperations.Find(Operation) <> Undefined;
	Else
		UninvoicedReceiptDocumentIsUsed = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);

	DiscrepanciesAreRelevant = False;

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);
	RowsToDelete = New Array;
	For Each LineOfATabularSection In SelectedRows Do
		If ToReturnReusablePackage
			And LineOfATabularSection.ItemsType = Enums.ItemsTypes.ReusablePackage Then
			RowsToDelete.Add(LineOfATabularSection);
			Continue;
		EndIf;
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	For Each LineToDelete In RowsToDelete Do
		SelectedRows.Delete(SelectedRows.Find(LineToDelete));
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	CalculateFinalRevenueFigures(ThisObject); 
	
	UpdateTextDocumentsBasedOn();

EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesReceivedServer(Val Object)
	
	Return Documents.PurchaseAdjustment.ParametersForRegisteringInvoicesReceived(Object);
	
EndFunction

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure SetUpRNPTAccounting()
	
	EstablishVisibilityOfRNPTQuantity();
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Warehouse",
												True);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfRNPTQuantity()
	
	BasisAcquisitionOfServicesOtherAssets = ValueIsFilled(Object.DocumentBasis)
												And TypeOf(Object.DocumentBasis) = Type("DocumentRef.VendorInvoiceServicesAndAssets");
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm,
																			Object.Date,,
																			BasisAcquisitionOfServicesOtherAssets);
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm,
																			Object.Date,
																			"TheDivergenceOfTheGroupNumberAtRNPT",
																			BasisAcquisitionOfServicesOtherAssets);
	
EndProcedure

&AtServer
Procedure AddAcquisitionDocumentToDebtAdjustmentTable(DocumentAcquisitions)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentAmountsInAccountingCurrency.Recorder AS DocumentAcquisitions,
	|	DocumentAmountsInAccountingCurrency.VATRate AS VATRate,
	|	DocumentAmountsInAccountingCurrency.ARAPObject AS ARAPObject,
	|	SUM(DocumentAmountsInAccountingCurrency.VATAmount) AS VATAmount,
	|	SUM(DocumentAmountsInAccountingCurrency.AmountExcludingVAT + DocumentAmountsInAccountingCurrency.VATAmount) AS AmountIncludingVAT
	|FROM
	|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|WHERE
	|	DocumentAmountsInAccountingCurrency.Recorder IN (&Recorder)
	|	AND DocumentAmountsInAccountingCurrency.PaymentType_ = &PaymentType_
	|GROUP BY
	|	DocumentAmountsInAccountingCurrency.Recorder,
	|	DocumentAmountsInAccountingCurrency.VATRate,
	|	DocumentAmountsInAccountingCurrency.ARAPObject
	|";
	Query.SetParameter("Recorder", DocumentAcquisitions);
	Query.SetParameter("PaymentType_", Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	While Selection.Next() Do
		
		Filter = New Structure();
		Filter.Insert("DocumentAcquisitions", Selection.DocumentAcquisitions);
		Filter.Insert("ARAPObject", Selection.ARAPObject);
		Filter.Insert("VATRate", Selection.VATRate);
		
		SearchResult = Object.ARAPAdjustment.FindRows(Filter);
		If SearchResult.Count() > 0 Then
			TableRow = SearchResult[0];
			FillPropertyValues(TableRow, Selection);
		Else
			NewRow = Object.ARAPAdjustment.Add();
			FillPropertyValues(NewRow, Selection);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure InputReasonsForDebtAdjustmentCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	For Each SelectedRow In Items.ARAPAdjustment.SelectedRows Do
		CurrentRow = Object.ARAPAdjustment.FindByID(SelectedRow);
		CurrentRow.ReasonForAdjustment = Result;
	EndDo;
	
EndProcedure

&AtClient
Procedure EnteringAmountOfDebtAdjustmentCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	ArrayOfCoefficients = New Array;
	For Each CurrentRow In Object.ARAPAdjustment Do
		ArrayOfCoefficients.Add(CurrentRow.AmountIncludingVAT);
	EndDo;
	
	AllocationResult = CommonClientServer.DistributeAmountInProportionToCoefficients(Result, ArrayOfCoefficients);
	IndexOf = 0;
	For Each CurrentRow In Object.ARAPAdjustment Do
		CurrentRow.AdjustmentSum = AllocationResult[IndexOf];
		CurrentRow.SumOfVATAdjustments =
			PriceManagementSystemClientServer.CalculateVATAmount(
				CurrentRow.AdjustmentSum, 
				CurrentRow.VATRate,
				True,
				Object.VATTaxation);
		CurrentRow.AmountARAP = 0;
		IndexOf = IndexOf + 1; 
	EndDo;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtClient
Procedure EnteringDebtAdjustmentInterestCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each RowID In Items.ARAPAdjustment.SelectedRows Do
		
		CurrentRow = Object.ARAPAdjustment.FindByID(RowID);
		CurrentRow.AdjustmentSum = CurrentRow.AmountIncludingVAT * Result / 100;
		CurrentRow.SumOfVATAdjustments =
			PriceManagementSystemClientServer.CalculateVATAmount(
				CurrentRow.AdjustmentSum, 
				CurrentRow.VATRate,
				True,
				Object.VATTaxation);
		CurrentRow.AmountARAP = 0;
	EndDo;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForPurposeOfVTCH()
	
	StructureOfActions = New Structure;
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
EndProcedure

&AtClientAtServerNoContext
Function DataToFillInWriteOFFAttributeForExpenses(BusinessOperation, OptionOfExecutionOfContractOfPurchases, OptionForRegisteringServiceReceiptDocuments)
	
	FillingData = New Structure;
	
	InvoicingOperations = New Array;
	InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"));
	InvoicingOperations.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
	ThisIsInvoiceForGoods = InvoicingOperations.Find(BusinessOperation) <> Undefined;
	
	ThisIsInvoiceForServicesAndWorks = ThisIsInvoiceForGoods And
		(OptionOfExecutionOfContractOfPurchases = PredefinedValue("Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices") Or
		OptionForRegisteringServiceReceiptDocuments = PredefinedValue("Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced"));
	
	FillingData.Insert("ThisIsInvoiceForGoods", ThisIsInvoiceForGoods);
	FillingData.Insert("ThisIsInvoiceForServicesAndWorks", ThisIsInvoiceForServicesAndWorks);
	
	Return FillingData;
	
EndFunction

&AtServer
Procedure FillInCheckQualityDateOfQualityConfirmationServer()
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Discrepancies, StructureOfActions);
	
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

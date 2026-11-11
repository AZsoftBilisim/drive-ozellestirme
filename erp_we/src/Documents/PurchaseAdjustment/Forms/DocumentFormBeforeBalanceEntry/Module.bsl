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
	
	SetFormHeader();
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	SetHeadingIncomeExpenseItem();
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", Object.DocumentBasis);
	OptionsForSelection.Insert("DocumentDate", Object.Date);
	OptionsForSelection.Insert("AdjustingEntryType", Object.AdjustingEntryType);
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ArticleAndAnalystSelectionParametersAdjustmentBeforeEnteringBalances(OptionsForSelection);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject, "AdjustmentTable.Purpose");
	RegistrarForSelectingAppointment = Object.Ref;
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("AdjustingEntryType", Object.AdjustingEntryType);
	SetupParameters = Documents.PurchaseAdjustment.AccountSettingsAdjustmentBeforeEnteringBalances(OptionsForSelection);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;

	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		PrepareFillSetSeriesVisibility();
		If ValueIsFilled(TypeOfPreviousAdjustment) Then
			Object.AdjustingEntryType = TypeOfPreviousAdjustment;
		EndIf;
	EndIf;
	CalculateFinalRevenueFigures(ThisObject);
	SetAvailabilityOfClipboardCommands();
	
	EstablishVisibilityOfRNPTQuantity();
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "AdjustmentTableCCDNumber", AdjustmentOfPurchaseOfOtherAssetServices);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", Object.DocumentBasis);
	OptionsForSelection.Insert("DocumentDate", Object.Date);
	OptionsForSelection.Insert("AdjustingEntryType", Object.AdjustingEntryType);
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ArticleAndAnalystSelectionParametersAdjustmentBeforeEnteringBalances(OptionsForSelection);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("AdjustingEntryType", Object.AdjustingEntryType);
	SetupParameters = Documents.PurchaseAdjustment.AccountSettingsAdjustmentBeforeEnteringBalances(OptionsForSelection);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	OnReadCreateAtServer();

	CalculateFinalRevenueFigures(ThisObject);
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	
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
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	CheckForDuplicateRowsInTableAndDeleteSeries(Cancel);
	GLAccountSettingsClient.BeforeWriteAtClient(ThisObject);
	UploadAdjustmentTableToDocumentData();
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		
		Return;
	EndIf;
	
	CalculateFinalRevenueFigures(ThisObject);
	
	If Cancel Then
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Title = "";
	AutoTitle = True;
	
	LoadAdjustmentTableFromDocumentDataOnServer();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	UpdateServiceDetailsOfTableParts();
	UpdateVHFWarehouseObligation();
	SetAvailabilityOfItemsByStatusServer();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject, CurrentObject.AdditionalProperties);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(AdjustmentTable);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	RegistrarForSelectingAppointment = Object.Ref;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
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
	
	If EventName = "UpdateInformationSecurityDocumentAfterFillingItOut" 
		And Parameter.Find(Object.Ref) <> Undefined Then
		
		Read();
		
	EndIf;
	
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName, ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
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
			
		ParametersForSpecifyingCCDNumber = PurchasesClient.ParametersForSpecifyingCCDNumber();
		ParametersForSpecifyingCCDNumber.TSName = "AdjustmentTable";
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, ParametersForSpecifyingCCDNumber, , Actions);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
	ElsIf ChoiceSource.FormName = "Document.PurchaseAdjustment.Form.ChoiceFormOfCorrectedDocument" Then
		ProcessingSelectionOfDocumentBeingCorrected(ValueSelected);
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		UpdateTextOfInvoiceReceived();
	ElsIf TypeOf(ValueSelected) = Type("DocumentRef.SourceDocument") Then
		ProcessingSelectionOfBaseDocumentClient(ValueSelected);
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("DocumentBasis", Object.DocumentBasis);
	
	Notify("Write_AdjustingPurchaseBeforeEnteringBalance", WriteParameters, Object.Ref);
	
	
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
		|RowCode,
		|QuantityAfter,
		|NumberOfPackagesAfter,
		|VATRate,
		|VATRateAfter,
		|AmountIncludingVAT,
		|AmountWithVATAfter,
		|Sum,
		|AmountAfter,
		|VATAmount,
		|VATAmountAfter");
	
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

	UpdateServiceFieldsOfValueTable();

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
		ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisObject);
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
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
	ReceiptPeriod   = ?(ValueIsFilled(Object.DocumentBasis),
		GeneralPurposeTMServerCall.ObjectAttributeValue(Object.DocumentBasis, "Date"), AdjustmentPeriod_);
	
	NewValue = ReceiptPeriod < BegOfMonth(AdjustmentPeriod_);
	
	If LastPeriodAdjustment <> NewValue 
		And TypeOf(Object.DocumentBasis)= Type("DocumentRef.SourceDocument") 
		And Object.AdjustingEntryType = PredefinedValue("Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices") Then
		
		If LastPeriodAdjustment Then
			QueryText = NStr("vi = 'Điều chỉnh được chuyển sang một tháng với chứng từ-cơ sở. Điền lại chênh lệch?';
							|ru = 'Корректировка перенесена в один месяц с документом-основанием. Перезаполнить расхождения?';
							|en = 'Adjustment is transferred to the same month as base document. Fill in the discrepancies again?'; fa = 'Adjustment is transferred to the same month as base document. Fill in the discrepancies again?';
							|it = 'La rettifica rinviata allo stesso mese del documento-causale. Ricompilare le discrepanze?';
							|pl = 'Zapis korygujący jest przeniesiony w jednym miesiącu z dokumentem podstawą. Wypełnić odchylenie ponownie?';
							|tr = 'Düzenleme, temel belge ile aynı aya taşınmıştır. Tutarsızlıklar yeniden doldurulsun mu?'");
		Else
			QueryText = NStr("vi = 'Điều chỉnh chuyển sang tháng khác với chứng từ cơ sở. Điền lại chênh lệch?';
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
		Notification = New CallbackDescription("DateOfChangeAfterVerification", ThisObject);
		ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
		
		DateOnChangeServer();
	ElsIf Response = DialogReturnCode.Cancel Then
		Object.Date = GeneralPurposeTMServerCall.ObjectAttributeValue(Object.Ref, "Date");
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	ExpenseItemOnChangeServer();
	
EndProcedure

&AtServer
Procedure ExpenseItemOnChangeServer()
	ParametersForAccessibility = New Structure("BusinessOperation, AdjustingEntryType", Object.AdjustmentKind, Object.AdjustingEntryType);
	SetupParameters = Documents.PurchaseAdjustment.AccountSettingsAdjustmentBeforeEnteringBalances(ParametersForAccessibility);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	IncomeItemOnChangeServer();
	
EndProcedure

&AtServer
Procedure IncomeItemOnChangeServer()
	ParametersForAccessibility = New Structure("BusinessOperation, AdjustingEntryType", Object.AdjustmentKind, Object.AdjustingEntryType);
	SetupParameters = Documents.PurchaseAdjustment.AccountSettingsAdjustmentBeforeEnteringBalances(ParametersForAccessibility);
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
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
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
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisObject, Item, StandardProcessing, Notification);

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
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
	If Object.Currency <> CurrentCurrency
		Or Object.ARAPCurrency <> CurCurrencyOfSettlements Then
		CurrencyOnChangeServer(Object.Currency);
		CurrentCurrency = Object.Currency;
		CurCurrencyOfSettlements =  Object.ARAPCurrency;
		ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();
	EndIf;
	
	If ChangedBankingDetails.Property("CourseNumerator")
		And ChangedBankingDetails.CourseNumerator <> Object.CourseNumerator Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert("ClearAmountOfSettlements");
		StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", "After");
		BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisObject, Item, StandardProcessing, Notification);
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
Procedure TextInvoiceReceivedProcessingNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
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
Procedure ContractCreating(Item, StandardProcessing)
	
	PurchasesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	UpdateServiceFieldsOfValueTable();
	
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
		And AdjustmentTable.Count() > 0
		And Not UserAnswer = DialogReturnCode.Cancel
		And UserAnswer);

	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustingEntryTypeOnChange(Item)
	
	If Not ValueIsFilled(Object.AdjustingEntryType) Then
		Object.AdjustingEntryType = TypeOfAdjustmentIsOld;
		
		Return;
	EndIf;
	
	If Object.AdjustingEntryType <> TypeOfAdjustmentIsOld
		And AdjustmentTable.Count() > 0 Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.OK, NStr("vi = 'Xóa';
													|ru = 'Очистить';
													|en = 'Clear'; fa = 'پاک کردن';
													|it = 'Cancellare';
													|pl = 'Clear';
													|tr = 'Temizle'"));
		ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Cancel';
														|tr = 'İptal'"));
		
		QueryText = NStr("vi = 'Xóa bảng dữ liệu điều chỉnh?';
						|ru = 'Очистить таблицу с данными по корректировке?';
						|en = 'Do you want to clear the table with adjustment data?'; fa = 'Do you want to clear the table with adjustment data?';
						|it = 'Cancellare tabella con i dati di correzione?';
						|pl = 'Wyczyścić tabele z danymi wg korekty?';
						|tr = 'Düzenleme verileriyle birlikte tablo temizlensin mi?'");
		
		ShowQueryBox(New CallbackDescription("AdjustingEntryTypeOnChangeCompletion", ThisObject), QueryText, ButtonsList);
		
	ElsIf Object.AdjustingEntryType <> TypeOfAdjustmentIsOld Then
		AdjustingEntryTypeOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustingEntryTypeOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.OK Then
		AdjustmentTable.Clear();
		AdjustingEntryTypeOnChangeServer();
		UpdateServiceFieldsOfValueTable();
	Else
		Object.AdjustingEntryType = TypeOfAdjustmentIsOld;
	EndIf;
	
EndProcedure

&AtClient
Procedure TypeOfCorrectionWhenChangingPresentationDocumentCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.OK Then
		AdjustmentTable.Clear();
		ProcessingDocumentSelectionViaServer(AdditionalParameters);
		FillInAdjustmentDataServer();
		UpdateServiceFieldsOfValueTable();
	Else
		Object.DocumentBasis = FoundationDocumentIsOld;
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInTypeOfActivityVAT();
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AdditionalFilters = New Structure;
	AdditionalFilters.Insert("BusinessOperation", Object.BusinessOperation);
	If ContractsAreUsed <> Undefined Then
		AdditionalFilters.Insert("ContractsAreUsed", ContractsAreUsed);
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
Procedure PresentationOfCorrectedDocumentClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.CorrectedDocument) Then
		ShowValue(, Object.CorrectedDocument);	
	Else
		PickUpDocumentToBeCorrected();		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAdjustmentTable

&AtClient
Procedure AdjustmentTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	If Items.AdjustmentTable.CurrentData <> Undefined Then
		GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
		PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "AdjustmentTablePartnerProducts", NStr("vi = 'Nhà cung cấp';
																													|ru = 'Поставщик';
																													|en = 'Vendor'; fa = 'تأمین‌کننده';
																													|it = 'Fornitore';
																													|pl = 'Dostawca';
																													|tr = 'Tedarikçi'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentTableOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.AdjustmentTable, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters, Copy);
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	If NewRow And Not Copy Then
		
		If Not WarehouseGroup_ Then
			CurrentRow.Warehouse = Object.Warehouse;
		EndIf;
		
		If AdjustmentOfPurchaseOfOtherAssetServices Then
			CurrentRow.ToExpenseAs = True;
		EndIf;
		
		If AdjustmentOfPurchaseOfOtherAssetServices Then
			FillInOfficialTraceabilityAttributesInProductLine(CurrentRow);
		EndIf;
		
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "ThisForm.AdjustmentTable");
		
	EndIf;
	
	// Setting up accounting accounts 
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	If NewRow Or Copy Then
		UpdateServiceFieldsOfValueTable();
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentTableOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	TableOfAdjustmentsAtEndOfEditingOnServer(CurrentData.GetID(), CachedValues);
	
	If Not CancelEdit Then
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.AdjustmentTable, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	EndIf;

EndProcedure

&AtServer
Procedure TableOfAdjustmentsAtEndOfEditingOnServer(CurrentID, CachedValues)
	
	FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(CurrentID, CachedValues);
	
EndProcedure

&AtClient
Procedure AdjustmentTableAfterDeleteRow(Item)
	
	UpdateServiceFieldsOfValueTable();
	
	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters, True);

	If SeriesStatusesNeedToBeUpdated  Then

		AdjustmentTableAfterDeleteRowServer(CachedValues); // server call

	EndIf;

	If SeriesStatusesNeedToBeUpdated Then

		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters);

	EndIf;
	
	CalculateFinalRevenueFigures(ThisObject);
	WhenChangingWarehouseInTablePartServer();
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure AdjustmentTableOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = "AdjustmentTablePartnerProducts" Then

		CurrentData = Items.AdjustmentTable.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.AdjustmentTablePartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.AdjustmentTablePartnerProducts.ChoiceParameters, CurrentData);
			
		ElsIf Item.CurrentItem.Name = "AdjustmentTableCCDNumber"
			And Not AdjustmentOfPurchaseOfOtherAssetServices Then
			PurchasesClient.FillInListOfCCDNumberSelection(
			Items.AdjustmentTable.CurrentData, 
			Items.AdjustmentTableCCDNumber.ChoiceList);
			
	ElsIf Item.CurrentItem = Items.AdjustmentTablePostingOption
			And Not Items.AdjustmentTable.CurrentData = Undefined Then
		
		TableRow = Items.AdjustmentTable.CurrentData;
		
		ChoiceList = GetReflectionOptionsAvailableForString(TableRow);
		Items.AdjustmentTablePostingOption.ChoiceList.LoadValues(ChoiceList);
		
	ElsIf Item.CurrentItem = Items.AdjustmentTableOptionToReflectWriteOff
			And Not Items.AdjustmentTable.CurrentData = Undefined Then
		
		TableRow = Items.AdjustmentTable.CurrentData;
		
		ChoiceList = GetAvailableOptionsForReflectingWriteOffForLine(TableRow);
		Items.AdjustmentTableOptionToReflectWriteOff.ChoiceList.LoadValues(ChoiceList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentTableOnChange(Item)
	
	Modified = True;
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	If CurrentData <> Undefined
		And CurrentData.LineNumber <> AdjustmentTable.IndexOf(CurrentData)+1 Then
		CurrentData.LineNumber = AdjustmentTable.IndexOf(CurrentData)+1;
		
		SelectionByLineNumber_ = New Structure();
		SelectionByLineNumber_.Insert("LineNumber", CurrentData.LineNumber);
		
		FoundRows = AdjustmentTable.FindRows(SelectionByLineNumber_);
		For Each TableRow In FoundRows Do
			If TableRow <> CurrentData Then
				TableRow.LineNumber = AdjustmentTable.IndexOf(TableRow)+1;
			EndIf;
		EndDo;
	EndIf;
	
	If CurrentData <> Undefined
		And PreviousRowDetails.NumberOfPackages <> Undefined Then
		
		DivergenceOfVATRate = CurrentData.VATRate <> CurrentData.VATRateAfter
		And (CurrentData.QuantityAfter > 0
			Or CurrentData.AmountIncludingVAT > 0
			Or CurrentData.VATAmount > 0);
				
		If PreviousRowDetails.VATRate <> CurrentData.VATRate
			Or PreviousRowDetails.VATRateAfter <> CurrentData.VATRateAfter
			Or PreviousRowDetails.ItemsType <> CurrentData.ItemsType Then
			CurrentData.OptionToReflectWriteOff = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
		EndIf;
		
		NumberOfPackages_Discrepancy = CurrentData.NumberOfPackagesAfter - CurrentData.NumberOfPackages;
		AmountWithVATDiscrepancy = CurrentData.AmountWithVATAfter - CurrentData.AmountIncludingVAT;
		VATAmountDiscrepancy = CurrentData.VATAmountAfter - CurrentData.VATAmount;
		
		PreviousNumberOfPackagesDiscrepancy = PreviousRowDetails.NumberOfPackagesAfter - PreviousRowDetails.NumberOfPackages;
		PreviousSumWithVATDiscrepancy = PreviousRowDetails.AmountWithVATAfter - PreviousRowDetails.AmountIncludingVAT;
		PreviousVATAmountDiscrepancy = PreviousRowDetails.VATAmountAfter - PreviousRowDetails.VATAmount;
		
		If CurrentData.NumberOfPackages = 0
			And CurrentData.AmountIncludingVAT = 0
			And CurrentData.VATAmount = 0
			And ValueIsFilled(CurrentData.OptionToReflectWriteOff) Then
			CurrentData.OptionToReflectWriteOff = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
		EndIf;
		
		If (Not DivergenceOfVATRate And NumberOfPackages_Discrepancy = 0 And AmountWithVATDiscrepancy = 0 And VATAmountDiscrepancy = 0)
			Or PreviousRowDetails.ItemsType <> CurrentData.ItemsType Then
			CurrentData.PostingOption = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
		ElsIf Not DivergenceOfVATRate And ((NumberOfPackages_Discrepancy >= 0 And PreviousNumberOfPackagesDiscrepancy < 0)
			Or (NumberOfPackages_Discrepancy = 0 And AmountWithVATDiscrepancy >= 0
				And PreviousNumberOfPackagesDiscrepancy = 0 And PreviousSumWithVATDiscrepancy < 0)
			Or (NumberOfPackages_Discrepancy = 0 And AmountWithVATDiscrepancy = 0 And VATAmountDiscrepancy >= 0
				And PreviousNumberOfPackagesDiscrepancy = 0 And PreviousSumWithVATDiscrepancy = 0 And PreviousVATAmountDiscrepancy < 0)
			Or (NumberOfPackages_Discrepancy < 0 And PreviousNumberOfPackagesDiscrepancy >= 0)
			Or (NumberOfPackages_Discrepancy = 0 And AmountWithVATDiscrepancy < 0
				And PreviousNumberOfPackagesDiscrepancy = 0 And PreviousSumWithVATDiscrepancy >= 0)
			Or (NumberOfPackages_Discrepancy = 0 And AmountWithVATDiscrepancy = 0 And VATAmountDiscrepancy < 0
				And PreviousNumberOfPackagesDiscrepancy = 0 And PreviousSumWithVATDiscrepancy = 0 And PreviousVATAmountDiscrepancy >= 0)) Then
			CurrentData.PostingOption = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
		EndIf;
		
		ChoiceList = GetReflectionOptionsAvailableForString(CurrentData);
		If ChoiceList.Find(CurrentData.PostingOption) = Undefined Then
			If ChoiceList.Count() = 1 Then
				CurrentData.PostingOption = ChoiceList[0];
			Else
				CurrentData.PostingOption = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
			EndIf;
		EndIf;
		
	EndIf;
	
	If CurrentData <> Undefined 
		And Not ValueIsFilled(CurrentData.PostingOption) Then
		
		CurrentData.PostingOption = VariantOfReflectionByLine(CurrentData);
			
	EndIf;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies(True);
	CalculateFinalRevenueFigures(ThisObject);
	SetWhetherWarehouseIsFull();
	If AdjustmentOfPurchaseOfOtherAssetServices Then
		FillInOfficialTraceabilityAttributesInProductLine(CurrentData);
	EndIf;
	
	If RecordInOtherIncomeNew <> RecordInOtherIncome
		Or ToExpenseAsNew <> ToExpenseAs Then
		
		ToExpenseAs = ToExpenseAsNew;
		RecordInOtherIncome = RecordInOtherIncomeNew;
		
		AttachIdleHandler("UpdateSelectionOfAccountingItems", 0.1, True);
		
	EndIf;
		
EndProcedure

&AtClient
Procedure AdjustmentTablePartnerProductsOnChange(Item)
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	UpdateDataAfterProductChanges(True);
	
EndProcedure

&AtClient
Procedure AdjustmentTableProductsOnChange(Item)
	
	UpdateDataAfterProductChanges();
	
EndProcedure

&AtClient
Procedure AdjustmentTablePurposeOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	CurrentData.ToExpenseAs = False;
	StructureOfActions = New Structure;
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	StructureOfActions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	CurrentData.InventoryOwnerAttribute = PredefinedValue("Catalog.InventoryKinds.EmptyRef");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	If CurrentData.AssignmentType = PredefinedValue("Enum.AssignmentTypes.DeliveryForPrincipal") Then
		CurrentData.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	EndIf;
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateDataAfterProductChanges(AccordingToPartnerSProductLIST = False)
	
	SeriesSpecificationParameters.NameTSGoods = "Goods";
	SeriesSpecificationParameters.TSSeriesName = "Goods";

	CurrentRow = Items.AdjustmentTable.CurrentData;
	Suffix = "After";
	
	CurrentRow.PriceAfter = 0;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.Suffix = Suffix;
	
	WarehouseParameters = New Structure;
	WarehouseParameters.Insert("CheckDate", Object.Date);
	
	StructureOfActions = New Structure;
	
	If AccordingToPartnerSProductLIST Then
		StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	EndIf;

	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("FillInOrderWarehouseAttribute", WarehouseParameters);
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
	StructureOfActions.Insert("FillInVATRateSuffix", ParametersFillInVATRate);
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSuffixAmount", New Structure ("Suffix, QuantityName", Suffix, "NumberOfPackages"));
	
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	
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
	StructureOfActions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True));
	StructureOfActions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "AdjustmentTable"));
		
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
	
	If CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
		Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
		Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Set")
		Or ValueIsFilled(CurrentRow.Purpose) Then
		
		CurrentRow.ToExpenseAs = False;
		CurrentRow.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		
	ElsIf CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		
		CurrentRow.ToExpenseAs = True;
		
	EndIf;
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "AdjustmentTable");
	
	SetWhetherWarehouseIsFull();
	CalculateFinalRevenueFigures(ThisObject);
	
	SeriesSpecificationParameters.NameTSGoods = "AdjustmentTable";
	SeriesSpecificationParameters.TSSeriesName = "AdjustmentTable";
	
EndProcedure

&AtClient
Procedure TableAdjustmentCharacteristicWhenChanging(Item)
	
	Suffix = "After";
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSuffixAmount", Suffix);
	
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "AdjustmentTable"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTablePackageOnChange(Item)
	
	Suffix = "After";
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", Suffix);
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	If CurrentRow.QuantityAfter > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackageSuffix", 
				New Structure("Count, Suffix", CurrentRow.QuantityAfter, Suffix));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSuffixAmount", Suffix);
	
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True,
		Suffix);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	StructureOfActions = New Structure;
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True,
		"After");
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalRevenueFigures(ThisObject);
EndProcedure

&AtClient
Procedure AdjustmentTableNumberOfPackagesAfterOnChange(Item)
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	StructureOfActions = New Structure;
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Warehouse",
		True);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject, "After");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalRevenueFigures(ThisObject);
EndProcedure

&AtClient
Procedure AdjustmentTableCountOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count",			 ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("Price",					 CurrentData.Price);
	CurrentRow.Insert("Sum",					 CurrentData.Sum);
	CurrentRow.Insert("VATRate",				 CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",				 CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",				 CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountARAP",	 CurrentData.AmountARAP);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow, , "Count");
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableQuantityAfterOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("QuantityAfter",			 ?(CurrentData.QuantityAfter <> 0, CurrentData.QuantityAfter, 1));
	CurrentRow.Insert("PriceAfter",					 CurrentData.PriceAfter);
	CurrentRow.Insert("AmountAfter",				 CurrentData.AmountAfter);
	CurrentRow.Insert("VATRateAfter",			 CurrentData.VATRateAfter);
	CurrentRow.Insert("VATAmountAfter",				 CurrentData.VATAmountAfter);
	CurrentRow.Insert("AmountWithVATAfter",			 CurrentData.AmountWithVATAfter);
	CurrentRow.Insert("NumberOfPackagesAfter",	 0);
	CurrentRow.Insert("AmountOfSettlementsAfter",	 CurrentData.AmountOfSettlementsAfter);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisObject, "After");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.NumberOfPackagesAfter = CurrentRow.NumberOfPackagesAfter;
	CurrentData.PriceAfter = CurrentRow.PriceAfter;
	CurrentData.AmountAfter = CurrentRow.AmountAfter;
	CurrentData.VATRateAfter = CurrentRow.VATRateAfter;
	CurrentData.VATAmountAfter = CurrentRow.VATAmountAfter;
	CurrentData.AmountWithVATAfter = CurrentRow.AmountWithVATAfter;
	CurrentData.AmountOfSettlementsAfter = CurrentRow.AmountOfSettlementsAfter;
	
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTablePriceOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count", ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages", CurrentData.NumberOfPackages);
	CurrentRow.Insert("Price",				 CurrentData.Price);
	CurrentRow.Insert("Sum",				 CurrentData.Sum);
	CurrentRow.Insert("VATRate",			 CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",			 CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",			 CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountARAP",CurrentData.AmountARAP);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow, , "Count");
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTablePriceAfterOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count", ?(CurrentData.QuantityAfter <> 0, CurrentData.QuantityAfter, 1));
	CurrentRow.Insert("NumberOfPackages", CurrentData.NumberOfPackagesAfter);
	CurrentRow.Insert("Price",				 CurrentData.PriceAfter);
	CurrentRow.Insert("Sum",				 CurrentData.AmountAfter);
	CurrentRow.Insert("VATRate",			 CurrentData.VATRateAfter);
	CurrentRow.Insert("VATAmount",			 CurrentData.VATAmountAfter);
	CurrentRow.Insert("AmountIncludingVAT",			 CurrentData.AmountWithVATAfter);
	CurrentRow.Insert("AmountARAP",CurrentData.AmountOfSettlementsAfter);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.NumberOfPackagesAfter = CurrentRow.NumberOfPackages;
	CurrentData.PriceAfter = CurrentRow.Price;
	CurrentData.AmountAfter = CurrentRow.Sum;
	CurrentData.VATRateAfter = CurrentRow.VATRate;
	CurrentData.VATAmountAfter = CurrentRow.VATAmount;
	CurrentData.AmountWithVATAfter = CurrentRow.AmountIncludingVAT;
	CurrentData.AmountOfSettlementsAfter = CurrentRow.AmountARAP;
	
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableSumOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count", ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages", CurrentData.NumberOfPackages);
	CurrentRow.Insert("Price",				 CurrentData.Price);
	CurrentRow.Insert("Sum",				 CurrentData.Sum);
	CurrentRow.Insert("VATRate",			 CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",			 CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",			 CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountARAP",CurrentData.AmountARAP);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow, , "Count");
	
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableAmountAfterOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count", ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages", CurrentData.NumberOfPackagesAfter);
	CurrentRow.Insert("Price",				 CurrentData.PriceAfter);
	CurrentRow.Insert("Sum",				 CurrentData.AmountAfter);
	CurrentRow.Insert("VATRate",			 CurrentData.VATRateAfter);
	CurrentRow.Insert("VATAmount",			 CurrentData.VATAmountAfter);
	CurrentRow.Insert("AmountIncludingVAT",			 CurrentData.AmountWithVATAfter);
	CurrentRow.Insert("AmountARAP",CurrentData.AmountOfSettlementsAfter);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.NumberOfPackagesAfter = CurrentRow.NumberOfPackages;
	CurrentData.PriceAfter = CurrentRow.Price;
	CurrentData.AmountAfter = CurrentRow.Sum;
	CurrentData.VATRateAfter = CurrentRow.VATRate;
	CurrentData.VATAmountAfter = CurrentRow.VATAmount;
	CurrentData.AmountWithVATAfter = CurrentRow.AmountIncludingVAT;
	CurrentData.AmountOfSettlementsAfter = CurrentRow.AmountARAP;
	
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableVATAmountOnChange(Item)
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure AdjustmentTableVATAmountAfterOnChange(Item)
	
	Suffix = "After";
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure AdjustmentTableVATRateOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count", ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages", CurrentData.NumberOfPackages);
	CurrentRow.Insert("Price",				 CurrentData.Price);
	CurrentRow.Insert("Sum",				 CurrentData.Sum);
	CurrentRow.Insert("VATRate",			 CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",			 CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",			 CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountARAP",CurrentData.AmountARAP);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow, , "Count");
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableVATRateAfterOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count", ?(CurrentData.QuantityAfter <> 0, CurrentData.QuantityAfter, 1));
	CurrentRow.Insert("NumberOfPackages", CurrentData.NumberOfPackagesAfter);
	CurrentRow.Insert("Price",				 CurrentData.PriceAfter);
	CurrentRow.Insert("Sum",				 CurrentData.AmountAfter);
	CurrentRow.Insert("VATRate",			 CurrentData.VATRateAfter);
	CurrentRow.Insert("VATAmount",			 CurrentData.VATAmountAfter);
	CurrentRow.Insert("AmountIncludingVAT",			 CurrentData.AmountWithVATAfter);
	CurrentRow.Insert("AmountARAP",CurrentData.AmountOfSettlementsAfter);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.NumberOfPackagesAfter = CurrentRow.NumberOfPackages;
	CurrentData.PriceAfter = CurrentRow.Price;
	CurrentData.AmountAfter = CurrentRow.Sum;
	CurrentData.VATRateAfter = CurrentRow.VATRate;
	CurrentData.VATAmountAfter = CurrentRow.VATAmount;
	CurrentData.AmountWithVATAfter = CurrentRow.AmountIncludingVAT;
	CurrentData.AmountOfSettlementsAfter = CurrentRow.AmountARAP;
	
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableWarehouseOnChange(Item)
	
	SeriesSpecificationParameters.NameTSGoods = "Goods";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
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
	
	SeriesSpecificationParameters.NameTSGoods = "AdjustmentTable";
	SeriesSpecificationParameters.TSSeriesName = "AdjustmentTable";
	
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtClient
Procedure AdjustmentTableToExpenseAsOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "AdjustmentTable");
	
	If (CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Or
		CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
		Or CurrentData.AssignmentType = PredefinedValue("Enum.AssignmentTypes.DeliveryForPrincipal") Then
		CurrentData.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	EndIf;
	
	ListOfReflectionOptions = GetReflectionOptionsAvailableForString(CurrentData);
	If ListOfReflectionOptions.Find(CurrentData.PostingOption) = Undefined Then
		If ListOfReflectionOptions.Count() > 0 Then
			CurrentData.PostingOption = ListOfReflectionOptions[0];
		EndIf;
	EndIf;
	If CurrentData.VATRate <> CurrentData.VATRateAfter
		And (CurrentData.Count > 0 Or CurrentData.Sum > 0 Or CurrentData.VATAmount > 0) Then
		ListOfOptionsForReflectingWriteOffs = GetAvailableOptionsForReflectingWriteOffForLine(CurrentData);
		If ListOfOptionsForReflectingWriteOffs.Find(CurrentData.OptionToReflectWriteOff) = Undefined Then
			If ListOfOptionsForReflectingWriteOffs.Count() > 0 Then
				CurrentData.OptionToReflectWriteOff = ListOfOptionsForReflectingWriteOffs[0];
			EndIf;
		EndIf;
	Else
		CurrentData.OptionToReflectWriteOff = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
	EndIf;

EndProcedure

&AtClient
Procedure AdjustmentTableExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AdjustmentTableSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure AdjustmentTableSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.AdjustmentTable.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.AdjustmentTable.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtClient
Procedure AdjustmentTableDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AdjustmentTableDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AdjustmentTableDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AdjustmentTableCCDNumberOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
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
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			Actions,
			"Warehouse",
			True,
			"After");
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure AdjustmentTableCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.DocumentCurrency = Object.Currency;
	AdditionalParameters.FieldNameQuantity	= ?(NumberOfPackagesIsUsed,
													"NumberOfPackagesAfter",
													"QuantityAfter");
	AdditionalParameters.NameOfVATAmountField_		= "VATAmountAfter";
	AdditionalParameters.NameOfAmountFieldWithVAT	= "AmountWithVATAfter";
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	FormParameters = New Structure("CreationParameters", CreationParameters);
	
	OpenForm("Catalog.CCDNumbers.Form.ItemForm",
				FormParameters,
				ThisObject,
				UUID);
	
EndProcedure

&AtClient
Procedure AdjustmentTableBeforeDeleteRow(Item, Cancel)
	
	If Items.AdjustmentTable.CurrentData <> Undefined Then
		
		ProcessingOfTabularFormsClient.CacheCurLine(Items.AdjustmentTable, ThisObject);
		ProductsClient.UpdateCachedValuesToAccountForSeries(
					Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentTableBeforeRowChange(Item, Cancel)
	FillPropertyValues(PreviousRowDetails, Items.AdjustmentTable.CurrentData);
EndProcedure

&AtClient
Procedure AdjustmentTablePartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);

EndProcedure

&AtClient
Procedure AdjustmentTableExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AdjustmentTablePostingOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	If TypeOf(ValueSelected) = Type("EnumRef.OptionsOfPostingReceiptAdjustingEntries") Then
		
		CurrentRow.PostingOption = ValueSelected;
		
	Else
		
		CurrentRow.PostingOption = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
		
	EndIf;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtClient
Procedure TableOfAdjustmentsReflectionOptionProcessingOfWriteOffSelection(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	If TypeOf(ValueSelected) = Type("EnumRef.OptionsOfPostingReceiptAdjustingEntries") Then
		
		CurrentRow.OptionToReflectWriteOff = ValueSelected;
		
	Else
		
		CurrentRow.OptionToReflectWriteOff = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
		
	EndIf;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	CalculateFinalRevenueFigures(ThisObject);
	
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
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = AdjustmentTable.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = AdjustmentTable.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	UpdateTitleOfAdjustmentTable();
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.AdjustmentTable) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.AdjustmentTable.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
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
Procedure ShowSupplierProducts(Command)
	
	PartnersProductsClient.ShowThePartnerSNomenclature(Object.Partner, Object.Ref, Items.AdjustmentTable.CurrentData, NStr("vi = 'Nhà cung cấp';
																															|ru = 'Поставщик';
																															|en = 'Vendor'; fa = 'تأمین‌کننده';
																															|it = 'Fornitore';
																															|pl = 'Dostawca';
																															|tr = 'Tedarikçi'"));
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItem(Command)
	
	If Not TMCommonUseClient.CheckForRowsInList(AdjustmentTable, NStr("vi = 'Dữ liệu điều chỉnh';
																		|ru = 'Данные корректировки';
																		|en = 'Adjustment data'; fa = 'Adjustment data';
																		|it = 'Dati di correzione';
																		|pl = 'Dane korekty';
																		|tr = 'Düzeltme verileri'")) Then
		Return;
	EndIf;
	
	GoodsAddressInStorage = PlaceGoodsInTemporaryStorageServer("AdjustmentTable");
	PurchasesClient.OpenSupplierProductListForm(
		New CallbackDescription("FillInTheItemByThePartnerSItemCompletion", ThisObject),
		GoodsAddressInStorage,
		ThisObject);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItemCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		FillInItemsFromTemporaryStorageServer(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)

	ObjectStructure = New Structure;
	ObjectStructure.Insert("Terms", Object.Terms);
	ObjectStructure.Insert("Currency", Object.Currency);
	ObjectStructure.Insert("AdjustmentTable", AdjustmentTable);
	TabularSectionPresentation = NStr("vi = 'Dữ liệu điều chỉnh';
										|ru = 'Данные корректировки';
										|en = 'Correction data'; fa = 'داده‌های اصلاح';
										|it = 'Dati di correzione';
										|pl = 'Dane korekty';
										|tr = 'Düzeltme verileri'");
	
	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(ObjectStructure, "AdjustmentTable", TabularSectionPresentation) Then
		
		PricesCalculated = FillThePricesByTermsOfSalesServer();
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		DiscrepanciesAreRelevant = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPrices(Command)

	ObjectStructure = New Structure;
	ObjectStructure.Insert("Currency", Object.Currency);
	ObjectStructure.Insert("AdjustmentTable", AdjustmentTable);
	TabularSectionPresentation = NStr("vi = 'Dữ liệu điều chỉnh';
										|ru = 'Данные корректировки';
										|en = 'Correction data'; fa = 'داده‌های اصلاح';
										|it = 'Dati di correzione';
										|pl = 'Dane korekty';
										|tr = 'Düzeltme verileri'");
	
	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(ObjectStructure, "AdjustmentTable", TabularSectionPresentation) Then
		
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
	
	SelectedRows = Items.AdjustmentTable.SelectedRows;
	TabularSectionPresentation = NStr("vi = 'Dữ liệu điều chỉnh';
										|ru = 'Данные корректировки';
										|en = 'Correction data'; fa = 'داده‌های اصلاح';
										|it = 'Dati di correzione';
										|pl = 'Dane korekty';
										|tr = 'Düzeltme verileri'");
	
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, AdjustmentTable, TabularSectionPresentation, SelectedRows) Then
		FilterStructure1 = New Structure("SelectGroup,IsFolder", PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"), False);
		ParametersStructure = New Structure("Filter,GroupOfWarehouses", FilterStructure1, Object.Warehouse);
		
		AdditionalParameters = New Structure("SelectedRows", SelectedRows);
		CallbackDescription = New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm("Catalog.Warehouses.ChoiceForm", 
			ParametersStructure,
			ThisObject,,,,
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
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document.PurchaseAdjustment.DocumentForm.Command.SelectGoods");
	
	SeriesSpecificationParameters.NameTSGoods = "Goods";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
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
	FormParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False)));
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisObject, UUID);
	
	SeriesSpecificationParameters.NameTSGoods = "AdjustmentTable";
	SeriesSpecificationParameters.TSSeriesName = "AdjustmentTable";
	
EndProcedure

&AtClient
Procedure BaseDocumentPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	If FormattedStringURL = "SelectDocument" Then
		OpenBaseSelectionForm();
	ElsIf ValueIsFilled(Object.DocumentBasis) Then
		ShowValue(Undefined, Object.DocumentBasis);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAdjustmentData(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = AdjustmentTable;
	CheckParameters.CheckForPromiscuity = False;
	Notification = New CallbackDescription("FillInAdjustmentDataCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
	
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
	
	// only view if the service or job and the appointment is filled
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableToExpenseAs.Name);

	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
		SelectionGroupAnd1 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(Enums.ItemsTypes.OperationService);
			
			ItemFilter.RightValue = ValueList;

		SelectionGroupAnd2 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
			ItemFilter.RightValue = ValueList;
			
			ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Purpose");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// explanatory inscription, if the job is completed and the assignment is completed

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableExpenseItem.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableDimensionOfExpenses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ValueList = New ValueList;
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với hàng hóa và công việc chưa được chỉ định>';
													|ru = '<для товаров и работ без назначения>';
													|en = '<for goods and works without assignment>'; fa = '<for goods and works without assignment>';
													|it = '<per articoli e lavori senza assegnazione>';
													|pl = '<dla towarów i prac bez przeznaczenia>';
													|tr = '<varış yeri olmayan mallar ve işler için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	// explanatory inscription, if we do not write off work and expenses

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableDimensionOfExpenses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Purpose");
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
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.DimensionOfExpenses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ToExpenseAs");
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
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableExpenseItem.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	// explanatory inscription, if the product or container or work and the destination is filled in

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableExpenseItem.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableDimensionOfExpenses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Purpose");
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
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisObject,
		"AdjustmentTableVATRate",
		"AdjustmentTableVATAmount",
		"AdjustmentTableAmountIncludingVAT");
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisObject,
		"AdjustmentTableVATRateAfter",
		"AdjustmentTableVATAmountAfter",
		"AdjustmentTableAmountWithVATAfter");
	//
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject, "AdjustmentTableAmountIncludingVAT");
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject, "AdjustmentTableAmountWithVATAfter");
	
	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "AdjustmentTableProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "AdjustmentTable.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
																	"AdjustmentTableCharacteristic",
																	"AdjustmentTable.ItemVariantsAreUsed");

	//
	
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject, "AdjustmentTableWarehouse");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "AdjustmentTableWarehouse", "AdjustmentTable.Warehouse", "AdjustmentTable.WarehouseIsRequired");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");
	
	//
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber					= "AdjustmentTableCCDNumber";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToCCD				= "AdjustmentTable.TheRecordsAreKeptByCCD";
	ConditionalDesignParameters.PathToFieldOfCorrectionAttributePUPA	= "AdjustmentOfPurchaseOfOtherAssetServices";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "AdjustmentTableCCDNumberCountryOfOrigin";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.PathToDocumentDateField				= "Object.Date";
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber				= "AdjustmentTableCCDNumber";
	ConditionalDesignParameters.NameOfInputFieldCountryOfOrigin	= "AdjustmentTableCCDNumberCountryOfOrigin";
	ConditionalDesignParameters.PathToCCDNumberField					= "AdjustmentTable.CCDNumber";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT			= "AdjustmentTable.AccountingForTheRNPTIsMaintained";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	//
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT();
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT	= "AdjustmentTableQuantityByGBRN";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA	= "AdjustmentTableItemUnitOfFEA";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT		= "AdjustmentTable.AccountingForTheRNPTIsMaintained";
	ConditionalDesignParameters.PathToItemTypeField		= "AdjustmentTable.ItemsType";
	ConditionalDesignParameters.PathToCCDNumberTypeField			= "AdjustmentTable.CCDNumberType";
	ConditionalDesignParameters.PathToFieldOfCorrectionAttributePUPA = "AdjustmentOfPurchaseOfOtherAssetServices";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
	
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT();
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT	= "AdjustmentTableQuantityAccordingToRNPTAfter";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA	= "AdjustmentTableProductUnitOfMeasurementOfFEAAfter";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT		= "AdjustmentTable.AccountingForTheRNPTIsMaintained";
	ConditionalDesignParameters.PathToItemTypeField		= "AdjustmentTable.ItemsType";
	ConditionalDesignParameters.PathToCCDNumberTypeField			= "AdjustmentTable.CCDNumberType";
	ConditionalDesignParameters.PathToFieldOfCorrectionAttributePUPA = "AdjustmentOfPurchaseOfOtherAssetServices";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableQuantityByGBRN.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableQuantityAccordingToRNPTAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.QuantityAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
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
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<mallar için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, 
														True,
														"AdjustmentTableSeries",
														"AdjustmentTable.BatchesIndicationStatus",
														"AdjustmentTable.ItemsType");
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject,
														"AdjustmentTablePurpose",
														"AdjustmentTable.ItemsType");
	
	// design of items and cost analytics

	SetConditionalAppearanceForArticlesAndAnalytics();
	
	// Removing the mark of an unfilled division, if the Goods or Work on agency procurement, and the goods are not written off for expenses
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableDepartment.Name);

	FilterGroup0 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup0.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
		FilterGroup1 = FilterGroup0.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Department");
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			
				FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
				FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				
					ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
					ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
					ValueList = New ValueList;
					ValueList.Add(Enums.ItemsTypes.OwnGoods);
					ValueList.Add(Enums.ItemsTypes.ReusablePackage);
					ItemFilter.RightValue = ValueList;
					
					ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ToExpenseAs");
					ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
					ItemFilter.RightValue = True;

				FilterGroup4 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
				FilterGroup4.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				
					ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
					ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
					ValueList = New ValueList;
					ValueList.Add(Enums.ItemsTypes.OperationService);
					ValueList.Add(Enums.ItemsTypes.Work_5);
					ItemFilter.RightValue = ValueList;
					
					ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Purpose");
					ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

				FilterGroup5 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
				FilterGroup5.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				
					ItemFilter = FilterGroup5.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
					ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
					ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
					
					ItemFilter = FilterGroup5.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AssignmentType");
					ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
					ItemFilter.RightValue = Enums.AssignmentTypes.DeliveryForPrincipal;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// setting the mark of an unfilled division, if the Product

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableDepartment.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Department");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
			FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
				ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
				ValueList = New ValueList;
				ValueList.Add(Enums.ItemsTypes.OwnGoods);
				ValueList.Add(Enums.ItemsTypes.ReusablePackage);
				ItemFilter.RightValue = ValueList;
				
				ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ToExpenseAs");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = True;

			FilterGroup4 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup4.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
				ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
				ValueList = New ValueList;
				ValueList.Add(Enums.ItemsTypes.OperationService);
				ValueList.Add(Enums.ItemsTypes.Work_5);
				ItemFilter.RightValue = ValueList;
				
				ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Purpose");
				ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

			FilterGroup5 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup5.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
				ItemFilter = FilterGroup5.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
				
				ItemFilter = FilterGroup5.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AssignmentType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
				ItemFilter.RightValue = Enums.AssignmentTypes.DeliveryForPrincipal;
		
	Item.Appearance.SetParameterValue("MarkIncomplete", True);


	// Registration of the warehouse and division
	// disabling the visibility of the warehouse, if the work or service.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
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
	
	// disabling warehouse visibility if a job or service

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
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
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableDepartment.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ToExpenseAs");
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
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ToExpenseAs");
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
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AssignmentType");
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

	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AdjustingEntryType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets");
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableOptionToReflectWriteOff.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountIncludingVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.QuantityAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountWithVATAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATAmountAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableOptionToReflectWriteOff.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.OptionToReflectWriteOff");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTablePostingOption.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.QuantityAfter");

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountIncludingVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.AmountWithVATAfter");

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATAmountAfter");

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");

	Item.Appearance.SetParameterValue("ReadOnly", False);

	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTablePostingOption.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.PostingOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.QuantityAfter");

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountIncludingVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.AmountWithVATAfter");

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATAmountAfter");

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTablePostingOption.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.QuantityAfter");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountIncludingVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.AmountWithVATAfter");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATAmountAfter");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có chênh lệch>';
													|ru = '<нет расхождений>';
													|en = '<no discrepancies>'; fa = '<no discrepancies>';
													|it = '<nessuna discrepanza>';
													|pl = '<brak odchylenia>';
													|tr = '<tutarsızlık yok>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableNumberOfPackages.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.NumberOfPackagesAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableNumberOfPackagesAfter.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.PriceAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.NumberOfPackagesAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.NumberOfPackagesAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableInscriptionBeforeChange.Name);
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'trước khi điều chỉnh:';
													|ru = 'до корректировки:';
													|en = 'before adjustment:'; fa = 'before adjustment:';
													|it = 'prima della correzione:';
													|pl = 'przed korektą:';
													|tr = 'düzeltmeden önce:'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableInscriptionAfterChange.Name);
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'sau khi điều chỉnh:';
													|ru = 'после корректировки:';
													|en = 'after adjustment:'; fa = 'after adjustment:';
													|it = 'dopo la correzione:';
													|pl = 'po korekcie:';
													|tr = 'düzeltmeden sonra:'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableVATRate.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Sum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableVATRateAfter.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.QuantityAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	SetConditionalRegistrationOfPriceAmounts("Sum","Count","AmountAfter");
	SetConditionalRegistrationOfPriceAmounts("Price","Count","PriceAfter");
	SetConditionalRegistrationOfPriceAmounts("AmountAfter","QuantityAfter", "Sum");
	SetConditionalRegistrationOfPriceAmounts("PriceAfter","QuantityAfter", "Price");
	
	//
	
	SetConditionalColorScheme();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountOfSettlementsAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.ARAPCurrency");
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountARAP.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.ARAPCurrency");
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableFEACNCode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableFEACNCode.Name);
	
	ListOfCCDTypes = New ValueList();
	ListOfCCDTypes.Add(Enums.CCDNumberTypes.ProductBatchIDNumber);
	ListOfCCDTypes.Add(Enums.CCDNumberTypes.KitRNPT);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.CCDNumberType");
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
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableCCDNumber.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure SetConditionalRegistrationOfPriceAmounts(Field, QuantityField, RelatedField)
	
	TableName = "AdjustmentTable";
	PathToElementField = TableName + "." + Field;
	FieldItem = TableName + Field;
	PathToQuantityField = TableName + "." + QuantityField;
	PathToFieldOfLinkedElement = TableName + "." + RelatedField;
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[FieldItem].Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToElementField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToQuantityField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToElementField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldOfLinkedElement);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentOfPurchaseOfOtherAssetServices");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure


&AtServer
Procedure SetConditionalColorScheme()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Sum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.AmountAfter");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);

	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountWithVATAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountIncludingVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.AmountWithVATAfter");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableVATAmountAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATAmountAfter");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTablePriceAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.PriceAfter");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableNumberOfPackagesAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.NumberOfPackagesAfter");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableNumberOfPackagesAfter.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.NumberOfPackagesAfter");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.PositiveValueTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountAfter.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Sum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.AmountAfter");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.PositiveValueTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountWithVATAfter.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountIncludingVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.AmountWithVATAfter");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.PositiveValueTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableVATAmountAfter.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATAmountAfter");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.PositiveValueTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTablePriceAfter.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.PriceAfter");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.PositiveValueTextColor);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure VATTaxationOnChangeServer(CachedValues)
	
	VATAccountingLocalization.SetPriceIncludesVATOnVATTaxation(Object.PriceIncludesVAT, Object.VATTaxation);
	VATAccountingLocalization.SetAvailabilityPriceIncludesVATOnVATTaxation(Items.PriceIncludesVAT, Object.VATTaxation);
	
	Suffix = "After";
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, False, ToReturnReusablePackage);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffix", ParametersFillInVATRate);
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions, Undefined);
	
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	
	CalculateFinalRevenueFigures(ThisObject);
	
	UpdateTextOfInvoiceReceived();
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	Suffix = "After";
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	
	BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions, CachedValues);
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Date");
	
	FillInTypeOfActivityVAT();
	SetUpRNPTAccounting();
	
	UpdateServiceDetailsOfTableParts();
	
	For Each TableRow In AdjustmentTable Do
		
		ChoiceList = GetReflectionOptionsAvailableForString(TableRow);
		If ChoiceList.Find(TableRow.PostingOption) = Undefined Then
			TableRow.PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.EmptyRef();
		EndIf;
		
		WriteOffSelectionList = GetAvailableOptionsForReflectingWriteOffForLine(TableRow);
		If ChoiceList.Find(TableRow.OptionToReflectWriteOff) = Undefined Then
			TableRow.OptionToReflectWriteOff = Enums.OptionsOfPostingReceiptAdjustingEntries.EmptyRef();
		EndIf;
		
	EndDo;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtServer
Procedure OperationOnChangeServer()
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", Object.DocumentBasis);
	OptionsForSelection.Insert("DocumentDate", Object.Date);
	OptionsForSelection.Insert("AdjustingEntryType", Object.AdjustingEntryType);
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ArticleAndAnalystSelectionParametersAdjustmentBeforeEnteringBalances(OptionsForSelection);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Object.AdjustmentKind <> Enums.BusinessTransactions.ErrorCorrection Then
		Object.CorrectedDocument = Undefined;
	EndIf;
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	SetPresentationOfFoundationDocument();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	SetVisibilityOfDocumentBeingCorrected();
	UpdatePresentationElementsOfDocumentBeingCorrected();
		
EndProcedure

&AtServer
Procedure SetVisibilityOfDocumentBeingCorrected()
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GroupDocumentBeingCorrected", 
		"Visible", ValueIsFilled(Object.DocumentBasis) And Object.AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection);
	
EndProcedure

&AtServer
Procedure AdjustmentTableAfterDeleteRowServer(CachedValues)
	
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
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	If Object.Partner = CurPartner Then
		Return;
	EndIf;
	
	CurPartner = Object.Partner;
	ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	FillInDefaultPurchaseConditions(False);
	ResponsiblePersonsServer.FillInManager_(Object);
	
	If CurContract <> Object.Contract Then
		ContractOnChangeServer();
	EndIf;
	CurContract = Object.Contract;
	
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	WarehouseOnChangeServer();

	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(AdjustmentTable, Object.Partner);
	
	UpdateServiceDetailsOfTableParts();
	
	CalculateFinalRevenueFigures(ThisObject);
	UpdateTextOfInvoiceReceived();
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	CounterpartyOnChangeServer();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
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
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer(RecalculatePrices_2=True)
	
	PriceIncludesVAT = Object.PriceIncludesVAT;
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Terms) Then
		
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Object.Terms, True, True);
		FillInTermsOfPurchase(PurchaseConditions);
		
		If CurContract <> Object.Contract Then
			ContractOnChangeServer();
		EndIf;
		
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
			StructureOfActions.Insert("ClearAmountOfSettlements");
			
			PricesCalculated = PartnerPricesFillingServer.FillInPrices(
				AdjustmentTable,
				Undefined, // Array of strings
				PriceFillingParameters_,
				StructureOfActions);
			
			If PricesCalculated Then
				Suffix = "After";
				StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
				
				StructureOfActions = New Structure;
				StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
				StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
				StructureOfActions.Insert("RecalculateSuffixAmount", New Structure ("Suffix, QuantityName", Suffix, "NumberOfPackages"));
				StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
				
				For Each String In AdjustmentTable Do
					String.PriceAfter = String.Price;
				EndDo;
				BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions);
			EndIf;
			
		ElsIf PriceIncludesVAT <> Object.PriceIncludesVAT Then
			
			Suffix = "After";
			StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
			StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
			
			StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
			
			StructureOfActions.Insert("ClearAmountOfSettlements");
			StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
			
			BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions, Undefined);
			
		EndIf;
		
		WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
		WarehouseOnChangeServer();
		
		UpdateServiceDetailsOfTableParts();
		
		CalculateFinalRevenueFigures(ThisForm);
		
		UpdateTextOfInvoiceReceived();
		
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	SetVisibilityOfElementsByTypeOfAdjustmentServer();
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	If CurContract <> Object.Contract Then
		ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	If ValueIsFilled(Object.Contract)
		And Common.ObjectAttributeValue(Object.Contract, "ContractType") = Enums.ContractTypes.TransferToTolling2_5 Then
		AdjustingProcessor = True;
	Else
		AdjustingProcessor = False;
	EndIf;
	
	If AdjustingProcessor
		And Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
		ItIsNotPossibleToDeleteRows();
	EndIf;
	FillInVATTaxationPurchases();
	FillInRestrictionsWhenChangingContract();
	SetVisibilityOfElementsByTypeOfAdjustmentServer();
	SetVisibilityOfElementsByBase();
	
	VATTaxationOnChangeServer(Undefined);
	
	FillInTypeOfActivityVAT();
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure FillInRestrictionsWhenChangingContract()

	ListOfProductLISTTypes = New Array();
	ListOfProductLISTTypes.Add(Enums.ItemsTypes.OwnGoods);
	ListOfProductLISTTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ListOfProductLISTTypes.Add(Enums.ItemsTypes.Work_5);
	ListOfProductLISTTypes.Add(Enums.ItemsTypes.OperationService);
		
	ArrayOfContractTypes = New Array();
	ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.WithVendor"));
	ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.TransferToTolling2_5"));
	
	If ValueIsFilled(Object.Contract)
		And Common.ObjectAttributeValue(Object.Contract,"ContractType") = Enums.ContractTypes.TransferToTolling2_5 Then
		
		ListOfProductLISTTypes.Clear();
		ListOfProductLISTTypes.Add(Enums.ItemsTypes.OperationService);
		
		NewArray = New Array();
		NewArray.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(ListOfProductLISTTypes)));
		Items.AdjustmentTableProducts.ChoiceParameters = New FixedArray(NewArray);
		
		AdjustmentTypeElement = Items.AdjustingEntryType.ChoiceList.FindByValue(Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices);
		If AdjustmentTypeElement <> Undefined Then
			AdjustmentTypeElement.Presentation = NStr("vi = 'Điều chỉnh dịch vụ về mặt hàng';
														|ru = 'Корректировка услуг по номенклатуре';
														|en = 'Service adjustment by items'; fa = 'Service adjustment by items';
														|it = 'Correzione dei servizi per nomenclatura';
														|pl = 'Korekta usług wg produktu';
														|tr = 'Hizmetlerin öğeye göre düzeltilmesi'");
		EndIf;
		
		AdjustmentTypeElement = Items.AdjustingEntryType.ChoiceList.FindByValue(Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets);
		If AdjustmentTypeElement <> Undefined Then
			AdjustmentTypeElement.Presentation = NStr("vi = 'Điều chỉnh dịch vụ về nội dung';
														|ru = 'Корректировка услуг по содержанию';
														|en = 'Service adjustment by scope'; fa = 'Service adjustment by scope';
														|it = 'Correzione dei servizi per contenuto';
														|pl = 'Korekta usług wg treści';
														|tr = 'İçeriğe ilişkin hizmetlerin düzeltilmesi'");
		EndIf;
		
	Else
		
		AdjustmentTypeElement = Items.AdjustingEntryType.ChoiceList.FindByValue(Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices);
		If AdjustmentTypeElement <> Undefined Then
			AdjustmentTypeElement.Presentation = NStr("vi = 'Điều chỉnh về hàng hóa và dịch vụ';
														|ru = 'Корректировка по товарам и услугам';
														|en = 'Adjustment by goods and services'; fa = 'تعدیل بر اساس کالا و خدمات';
														|it = 'Correzione per merci e servizi';
														|pl = 'Korekta według towarów i usług';
														|tr = 'Mal ve hizmetler için düzenleme'");
		EndIf;
		
		AdjustmentTypeElement = Items.AdjustingEntryType.ChoiceList.FindByValue(Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets);
		If AdjustmentTypeElement <> Undefined Then
			AdjustmentTypeElement.Presentation = NStr("vi = 'Điều chỉnh về dịch vụ và tài sản khác';
														|ru = 'Корректировка по услугам и прочим активам';
														|en = 'Adjustment by services and other assets'; fa = 'تعدیل بر اساس خدمات و سایر دارایی‌ها';
														|it = 'Correzione per servizi e altri attivi';
														|pl = 'Korekta według usług i innych aktywów';
														|tr = 'Hizmetler ve diğer varlıklar için düzenleme'");
		EndIf;
		
	EndIf;
	NewArray = New Array();
	NewArray.Add(New ChoiceParameter("Filter.ContractType", New FixedArray(ArrayOfContractTypes)));
	NewArray.Add(New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	NewArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
	Items.Contract.ChoiceParameters = New FixedArray(NewArray);
	
	NewArray = New Array();
	NewArray.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(ListOfProductLISTTypes)));
	Items.AdjustmentTableProducts.ChoiceParameters = New FixedArray(NewArray);
	
	Return;
	
EndProcedure
&AtServer
Procedure ItIsNotPossibleToDeleteRows()
	
	ArrayOfRowsToDelete_ = New Array();
	
	For Each AdjustmentLine In AdjustmentTable Do
		If AdjustmentLine.ItemsType <> Enums.ItemsTypes.OperationService Then
			ArrayOfRowsToDelete_.Add(AdjustmentLine);
		EndIf;
	EndDo;
	
	For Each RowToDelete In ArrayOfRowsToDelete_ Do
		AdjustmentTable.Delete(RowToDelete);
	EndDo;
	
EndProcedure
&AtServer
Procedure AdjustingEntryTypeOnChangeServer()
	
	AdjustmentOfPurchaseOfOtherAssetServices = 
		Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	
	If AdjustmentOfPurchaseOfOtherAssetServices
		And ValueIsFilled(Object.Warehouse) Then
		Object.Warehouse = Catalogs.Warehouses.EmptyRef();
	EndIf;
	
	SetVisibilityOfElementsByTypeOfAdjustmentServer();
	SetVisibilityOfElementsByBase();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	SetTypeOfAdjustment();
	SetParametersForSelectingGTDINumberOfHSCode();
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "AdjustmentTableCCDNumber", AdjustmentOfPurchaseOfOtherAssetServices);
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	SetParametersForSelectingProductsWarehouse();
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, AdjustmentTable, True, "ToExpenseAs");
	
	WhenChangingWarehouseInTablePartServer();
	PrepareFillSetSeriesVisibility();
	FillInTypeOfActivityVAT();
	
	If Not WarehouseGroup_ Then
		Items.AdjustmentTableRecipient.Title = NStr("vi = 'Bộ phận nhận';
													|ru = 'Подразделение-получатель';
													|en = 'Receiving business unit'; fa = 'واحد تجاری دریافت‌کننده';
													|it = 'Reparto-destinatario';
													|pl = 'Dział-odbiorca';
													|tr = 'Alıcı departman'");
	Else
		Items.AdjustmentTableRecipient.Title = NStr("vi = 'Người nhận';
													|ru = 'Получатель';
													|en = 'Recipient'; fa = 'گیرنده';
													|it = 'Destinatario';
													|pl = 'Odbiorca';
													|tr = 'Alıcı'");
	EndIf;
	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
	
	UpdateServiceDetailsOfTableParts();
	
	For Each TableRow In AdjustmentTable Do
		
		If (TableRow.ItemsType = Enums.ItemsTypes.OwnGoods
			Or TableRow.ItemsType = Enums.ItemsTypes.ReusablePackage)
			And TableRow.Count <> TableRow.QuantityAfter Then
			
			ChoiceList = GetReflectionOptionsAvailableForString(TableRow);
			If ChoiceList.Find(TableRow.PostingOption) = Undefined Then
				TableRow.PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.EmptyRef();
			EndIf;
			
			WriteOffSelectionList = GetAvailableOptionsForReflectingWriteOffForLine(TableRow);
			If ChoiceList.Find(TableRow.OptionToReflectWriteOff) = Undefined Then
				TableRow.OptionToReflectWriteOff = Enums.OptionsOfPostingReceiptAdjustingEntries.EmptyRef();
			EndIf;
		
		EndIf;
		
	EndDo;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency)
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisObject, CurrentCurrency, NewCurrency, LocalAccountingCurrency, DocumentDate);
	StructureOfOldCurrencyRates = CourseStructures.StructureOfOldCurrencyRates;
	StructureOfNewCurrencyRates  = CourseStructures.StructureOfNewCurrencyRates;
	
	RecalculationParameters = PriceManagementSystem.ParametersForConvertingTableAmountsToCurrency(Object.PriceIncludesVAT, CurrentCurrency, NewCurrency, DocumentDate);
	RecalculationParameters.StructureOfOldCurrencyRates = StructureOfOldCurrencyRates;
	RecalculationParameters.StructureOfNewCurrencyRates = StructureOfNewCurrencyRates;
	
	PriceManagementSystem.ConvertTableAmountsToCurrency(AdjustmentTable, RecalculationParameters);
	
	ColumnStructure1 = New Structure;
	ColumnStructure1.Insert("PriceAfter","Price");
	ColumnStructure1.Insert("AmountAfter", "Sum");
	ColumnStructure1.Insert("VATAmountAfter", "VATAmount");
	ColumnStructure1.Insert("AmountWithVATAfter", "AmountIncludingVAT");
	ColumnStructure1.Insert("VATRateAfter", "VATRate");
	ColumnStructure1.Insert("QuantityAfter", "Count");
	ColumnStructure1.Insert("NumberOfPackagesAfter", "NumberOfPackages");
	
	TemporaryAdjustmentTable = 
		TMCommonUse.ExportValuesTable(AdjustmentTable,,
			"PriceAfter,AmountAfter,VATAmountAfter,AmountWithVATAfter,VATRateAfter,QuantityAfter,NumberOfPackagesAfter",,
			ColumnStructure1);
	
	PriceManagementSystem.ConvertTableAmountsToCurrency(TemporaryAdjustmentTable, RecalculationParameters);
	
	For Each String In AdjustmentTable Do
		NewData = TemporaryAdjustmentTable[AdjustmentTable.IndexOf(String)];
		String.PriceAfter = NewData.Price;
		String.AmountAfter = NewData.Sum;
		String.VATAmountAfter = NewData.VATAmount;
		String.AmountWithVATAfter = NewData.AmountIncludingVAT;
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", "After");
	BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions, Undefined);
	
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

&AtServer
Procedure ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails()
	
	Object.Goods.Clear();
	Object.Discrepancies.Clear();
	Object.PackageBarcodes.Clear();
	Object.ARAPAdjustment.Clear();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

#EndRegion

#Region FillType

&AtServer
Function FillThePricesByTermsOfSalesServer()
	
	RowsArray = New Array;
	For Each String In Items.AdjustmentTable.SelectedRows Do
		RowsArray.Add(AdjustmentTable.FindByID(String));
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
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		AdjustmentTable,
		RowsArray, // Array of strings
		PriceFillingParameters_,
		StructureOfActions);
		
	If PricesCalculated Then
		Suffix = "After";
		StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSuffixAmount", New Structure ("Suffix, QuantityName", Suffix, "NumberOfPackages"));
		StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
		
		CachedValues = Undefined;
		For Each String In RowsArray Do
			String.PriceAfter = String.Price;
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsArray,
			StructureOfActions,
			AdjustmentTable,
			CachedValues);
	EndIf;
	
	CalculateFinalRevenueFigures(ThisObject);
	
	Return PricesCalculated;

EndFunction

&AtServer
Function FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPricesServer(VendorPriceKind)
	
	RowsArray = New Array;
	For Each String In Items.AdjustmentTable.SelectedRows Do
		RowsArray.Add(AdjustmentTable.FindByID(String));
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
	StructureOfActions.Insert("ClearAmountOfSettlements");
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		AdjustmentTable,
		RowsArray,
		PriceFillingParameters_,
		StructureOfActions);
		
	Suffix = "After";
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSuffixAmount", New Structure ("Suffix, QuantityName", Suffix, "NumberOfPackages"));
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	
	CachedValues = Undefined;
	For Each String In RowsArray Do
		String.PriceAfter = String.Price;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		AdjustmentTable,
		CachedValues);
	
	CalculateFinalRevenueFigures(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(AdjustmentTable, ArrayOfSelectedRows, Warehouse,, "ToExpenseAs");
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters);
	WhenChangingWarehouseInTablePartServer();
	
	Return FilledWithRows;
	
EndFunction

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

// Fills in the terms of sale in the document
//
// Parameters:
//	PurchaseConditions - Structure - Structure to fill in.
//
&AtServer
Procedure FillInTermsOfPurchase(Val PurchaseConditions)
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	Object.Currency = PurchaseConditions.Currency;
	Object.ARAPCurrency = PurchaseConditions.ARAPCurrency;
	
	If ValueIsFilled(PurchaseConditions.Organization) And PurchaseConditions.Organization <> Object.Organization Then
		Object.Organization = PurchaseConditions.Organization;
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Warehouse) Then
		Object.Warehouse = PurchaseConditions.Warehouse;
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Counterparty) And PurchaseConditions.Counterparty <> Object.Counterparty Then
		Object.Counterparty = PurchaseConditions.Counterparty;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	If ValueIsFilled(PurchaseConditions.BusinessOperation) Then
		OperationByAgreement		= Object.BusinessOperation;
		SeparatePurchaseOperations	= PurchasesServer.BusinessOperationsOnMain(PurchaseConditions.BusinessOperation);
		
		If SeparatePurchaseOperations.Find(Object.BusinessOperation) = Undefined
			And Not (OperationByAgreement = Enums.BusinessTransactions.PurchaseViaAdvanceHolder
				And PurchaseConditions.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier) Then
			OperationByAgreement = PurchaseConditions.BusinessOperation;
		EndIf;
		
		Object.BusinessOperation = OperationByAgreement;
	EndIf;
	
	ContractBusinessTransaction = PurchasesServer.BusinessOperationsOnMain(Object.BusinessOperation);
	
	If PurchaseConditions.ContractsAreUsed <> Undefined
		And PurchaseConditions.ContractsAreUsed Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency	= Object.ARAPCurrency;
		AddlParameters.Taxation		= Object.VATTaxation;
		
		Object.Contract = PurchasesServer.GetDefaultContract(Object, ContractBusinessTransaction, AddlParameters);
		
	EndIf;
	
	Object.PaymentMethod = PurchaseConditions.PaymentMethod;
	Object.PriceIncludesVAT = PurchaseConditions.PriceIncludesVAT;
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(Object.CourseNumerator,
					Object.CourseDenominator, Object.Currency, Object.ARAPCurrency, Object.Organization, , Object.Contract);
	
EndProcedure

// Fills in the terms of purchases under a trade agreement with the supplier
//
// Parameters:
//	RecalculatePrices_ - Boolean - True if you need to recalculate prices in the table part of the document.
//
&AtServer
Procedure FillInDefaultPurchaseConditions(RecalculatePrices_ = True)
	
	If ValueIsFilled(Object.Partner) Then
		
		PurchaseTermsKeys			= "ConsiderWarehouseGroups, ExcludeWarehouseGroupsAvailableInOrders, SelectedAgreement";
		SelectionOfProcurementConditions			= New Structure(PurchaseTermsKeys, True, True, Object.Terms);
		DefaultPurchasingConditions	= PurchasesServer.GetDefaultPurchaseTerms(Object.Partner, SelectionOfProcurementConditions);
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Object.Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
				
				Object.Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
				
				FillInVATTaxationPurchases();
				FillInTypeOfActivityVAT();
				
				If RecalculatePrices_
					And ValueIsFilled(Object.Terms) Then
					
					StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
					RecalculateAmountTakingIntoAccountManualDiscount	= New Structure("Clear", False);
					
					FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
					FillParameters.Insert("PopulationFields",		"Price, VATRate, VendorPriceKind");
					FillParameters.Insert("Date",				Object.Date);
					FillParameters.Insert("Currency",				Object.Currency);
					FillParameters.Insert("Terms",			Object.Terms);
					FillParameters.Insert("VATTaxation",	Object.VATTaxation);
					
					StructureOfActions = New Structure;
					StructureOfActions.Insert("RecalculateAmount",		"NumberOfPackages");
					StructureOfActions.Insert("RecalculateAmountWithVAT",	StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateVATAmount",	StructureOfRecalculationOfAmount);
					
					PartnerPricesFillingServer.FillInPrices(AdjustmentTable,
												Undefined, // Array of strings
												FillParameters,
												StructureOfActions);
					
				EndIf;
				
			Else
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
				Object.Terms = DefaultPurchasingConditions.Terms;
			EndIf;
			
		Else
			
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
			Object.Terms = Undefined;
			
			ContractBusinessTransaction = PurchasesServer.BusinessOperationsOnMain(Object.BusinessOperation);
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = Object.ARAPCurrency;
			
			Object.Contract = PurchasesServer.GetDefaultContract(Object, ContractBusinessTransaction, AddlParameters);
			
			FillInVATTaxationPurchases();
			FillInTypeOfActivityVAT();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAdjustmentDataCompletion(Result, AdditionalParameters) Export 
	
	FillInAdjustmentDataServer();

	If AdjustmentTable.Count() = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Không có dữ liệu để điền';
										|ru = 'Нет данных для заполнения';
										|en = 'No data to fill'; fa = 'No data to fill';
										|it = 'Нет данных для заполнения';
										|pl = 'No data to fill';
										|tr = 'Doldurulacak veri yok'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAdjustmentDataServer()
	
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
	
	Object.Goods.Clear();
	Object.Discrepancies.Clear();
	Documents.PurchaseAdjustment.FillInProductsBasedOnSourceData(Object.DocumentBasis, Object.Goods, Object.Ref);
	LoadAdjustmentTableFromDocumentDataOnServer();
	OnReadCreateAtServer();
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInOfficialTraceabilityAttributesInProductLine(CurrentData, ThisIsDiscrepancy = False)
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
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
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
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
	
	Var ThereAreAdjustingEntries;
	
	UseLocal = GetFunctionalOption("UseLocal");
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	LoadAdjustmentTableFromDocumentDataOnServer();
	CheckForAdjustments(Object.Ref, Object.DocumentBasis, ThereAreAdjustingEntries, TypeOfPreviousAdjustment);
	
	SetTypeOfAdjustment();
	Operation = EconomicOperationOfFoundationDocument(Object.AdjustingEntryType);
	SetBusinessOperationOfDocument(Object.DocumentBasis);
	SetPresentationOfFoundationDocument();
	
	AdjustmentOfPurchaseOfOtherAssetServices = 
		Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	
	SetParametersForSelectingProductsWarehouse();
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	
	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	PrepareFillSetSeriesVisibility();
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
		
	WhenChangingWarehouseInTablePartServer();
	Items.AdjustmentTableFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	
	SetSelectionParametersAdjustmentTableWarehouse();
	SetAvailabilityOfItemsByStatusServer();
	
	UpdateTextOfInvoiceReceived();
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	
	UpdateServiceDetailsOfTableParts();
	
	If ValueIsFilled(Object.DocumentBasis) Then
		FoundationDocumentIsOld = Object.DocumentBasis;
		AdjustmentPeriod_ = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		SetPrivilegedMode(True);
		ReferenceDocumentDateForCertificate   = Common.ObjectAttributeValue(Object.DocumentBasis, "Date");
		FoundationAgreement = Common.ObjectAttributeValue(Object.DocumentBasis, "Contract");
		ContractsAreUsed = ValueIsFilled(FoundationAgreement);
		SetPrivilegedMode(False);
		LastPeriodAdjustment = ReferenceDocumentDateForCertificate < BegOfMonth(AdjustmentPeriod_);
		If ValueIsFilled(Object.Contract)
			And Common.ObjectAttributeValue(Object.Contract, "ContractType") = Enums.ContractTypes.TransferToTolling2_5 Then
			AdjustingProcessor = True;
		Else
			AdjustingProcessor = False;
		EndIf;
	Else
		ReferenceDocumentDateForCertificate = Object.Date;
		ContractsAreUsed = Undefined;
		AdjustingProcessor = False;
	EndIf;
	
	ToReturnReusablePackage = False;
	PackageDepositIsRequired 	  = False;
	
	SetVisibilityOfElementsByTypeOfAdjustmentServer();
	SetVisibilityOfElementsByBase();
	FillInRestrictionsWhenChangingContract();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.AdjustmentTable);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(AdjustmentTable);
	
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
	UpdateVHFWarehouseObligation();
	FillInServiceDetailsForPurposeOfVTCH();
	SetVisibilityOfDocumentBeingCorrected();
	UpdatePresentationElementsOfDocumentBeingCorrected();
	SetParametersForSelectingGTDINumberOfHSCode();
	
EndProcedure

&AtServer
Procedure SetPresentationOfFoundationDocument()
	
	If ValueIsFilled(Object.DocumentBasis) Then
		DescriptionOfDocumentOfBasis = New FormattedString(String(Object.DocumentBasis),,,, "OpenDocument");
		ChangeCommand = New FormattedString(NStr("vi = '<Thay đổi>';
												|ru = '<Изменить>';
												|en = '<Change>'; fa = '<تغییر>';
												|it = '<Изменить>';
												|pl = '<Change>';
												|tr = '<Değiştir>'"),,,, "SelectDocument");
		BaseDocumentPresentation = New FormattedString(DescriptionOfDocumentOfBasis, "  ", ChangeCommand);
	Else
		BaseDocumentPresentation = New FormattedString(NStr("vi = 'Hãy chọn chứng từ cơ sở';
															|ru = 'Выберите документ-основание';
															|en = 'Select a base document'; fa = 'Select a base document';
															|it = 'Selezionare documento base';
															|pl = 'Wybierz dokument źródłowy';
															|tr = 'Lütfen, temel belge seçin.'"),, StyleColors.SpecialTextColor,, "SelectDocument");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByBase()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.PurchaseAdjustment.FillInNamesOfDetailsOnBasis(
		Object.DocumentBasis, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails,
		Object.AdjustingEntryType);
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	NumberOfPackagesIsUsed = Items.AdjustmentTableGroupNumberOfPackages.Visible;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableSelectGoods", "Visible", Items.AdjustmentTableProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableFillThePricesByTermsOfSales", "Visible", 
												Items.AdjustmentTableProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableCount", "Visible", Not NumberOfPackagesIsUsed);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableQuantityAfter", "Visible", Not NumberOfPackagesIsUsed);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableProductsUnitOfMeasure", "Visible", 
												Items.AdjustmentTableProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTablePackage", "Visible",
												Items.AdjustmentTableProducts.Visible);
	If AdjustingProcessor Then
		
		ArrayOfElementNames = New Array;
		ArrayOfElementNames.Add("AdjustmentTableCharacteristic");
		ArrayOfElementNames.Add("AdjustmentTableColumnGroupSeries");
		ArrayOfElementNames.Add("AdjustmentTableCCDNumber");
		ArrayOfElementNames.Add("AdjustmentTableCCDNumberCountryOfOrigin");
		ArrayOfElementNames.Add("TableOfAdjustmentsGroupQuantityByRNPT");
		ArrayOfElementNames.Add("Terms");
		ArrayOfElementNames.Add("Warehouse");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ContractGroup", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Contract", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Contract", "Enabled", True);
		
	Else
		PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible);
	EndIf;
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("PictureMultipleWarehouses");
	ArrayOfElementNames.Add("SeveralWarehousesText");
	ArrayOfElementNames.Add("AdjustmentTableFillInTheWarehouseInSelectedLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", Items.AdjustmentTableWarehouse.Visible);
	
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
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableCCDNumberCountryOfOrigin", "Visible", Items.AdjustmentTableCCDNumber.Visible);
	
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.AdjustmentTableProducts);
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.AdjustmentTablePartnerProducts);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	ItemArray.Add(Items.Date.Name);
	ItemArray.Add(Items.Partner.Name);
	ItemArray.Add(Items.Counterparty.Name);
	ItemArray.Add(Items.Terms.Name);
	
	ItemArray.Add(Items.Organization.Name);
	ItemArray.Add(Items.Contract.Name);
	ItemArray.Add(Items.Warehouse.Name);
	ItemArray.Add(Items.AdjustingEntryType.Name);
	
	ItemArray.Add(Items.Department.Name);
	ItemArray.Add(Items.VATTaxation.Name);
	ItemArray.Add(Items.PurchaseForActivity.Name);
	ItemArray.Add(Items.PriceIncludesVAT.Name);
	
	ItemArray.Add(Items.AdjustmentTableInsertRows.Name);
	ItemArray.Add(Items.AdjustmentTableFillInAdjustmentData.Name);
	ItemArray.Add(Items.AdjustmentTableSelectGoods.Name);
	ItemArray.Add(Items.AdjustmentTableFillInTheItemByThePartnerSItem.Name);
	ItemArray.Add(Items.AdjustmentTableFillThePricesByTermsOfSales.Name);
	ItemArray.Add(Items.AdjustmentTableFillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice.Name);
	ItemArray.Add(Items.AdjustmentTableFillInTheWarehouseInSelectedLines.Name);
	
	ItemArray.Add(Items.EditDocumentBeingCorrected.Name);
	
	ItemArray.Add("AdjustmentTable;BeforeAddRow,BeforeDeleteRow,BeforeRowChange");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		Items.AdjustmentTableFillInTheWarehouseInSelectedLines.Name,
		"Enabled",
		WarehouseGroup_);
	
EndProcedure

&AtServer
Procedure ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies(WorkingThroughHandler = False)
	
	AmountTotalVAT = 0;
	TotalSNDSAmount = 0;
	AmountForOtherIncome  = 0;
	AmountForOtherExpenses = 0;
	TotalAmountShovelcharge = 0;
	TotalAmountZhamanshina = 0;
	TotalAmountJavelina = 0;
	TotalAmountOfNDSUReduction = 0;
		
	CalculateTotalsFromDiscrepancyTable();
	RecordInOtherIncomeNew = (AmountForOtherIncome > 0);
	ToExpenseAsNew  = (AmountForOtherExpenses > 0);
	
	If Not WorkingThroughHandler Then
		
		ToExpenseAs = ToExpenseAsNew;
		RecordInOtherIncome = RecordInOtherIncomeNew;
		
		UpdateSelectionOfAccountingItemsServer();
		
	EndIf;
	
	TextAmountForOtherExpensesAssets = Items.TextAmountForOtherExpensesAssets.Title 
		 + " " + String(AmountForOtherExpenses) + " " + String(Object.Currency);
	
	TextAmountForOtherIncomeLiabilities = Items.TextAmountForOtherIncomeLiabilities.Title
		 + " " + String(AmountForOtherIncome) + " " + String(Object.Currency);
	
	Items.TextAmountForOtherExpensesAssets.Enabled = ValueIsFilled(AmountForOtherExpenses);
	Items.TextAmountForOtherIncomeLiabilities.Enabled = ValueIsFilled(AmountForOtherIncome);
	
	Items.ReduceAmountVATDeduction.Visible = Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties
													And (TotalAmountOfNDSUReduction > 0)
													And Object.PurchaseForActivity <> Enums.VATTaxationTypes.ProductionWithLongCycle
													And Object.PurchaseForActivity <> Enums.VATTaxationTypes.SpaceActivity
													And Object.PurchaseForActivity <> Enums.VATTaxationTypes.SaleIsNotSubjectToVAT
													And Object.PurchaseForActivity <> Enums.VATTaxationTypes.SalesByPatent;
	
EndProcedure

&AtClient
Procedure UpdateSelectionOfAccountingItems()
	
	UpdateSelectionOfAccountingItemsServer();
	
EndProcedure

&AtServer
Procedure UpdateSelectionOfAccountingItemsServer()
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", Object.AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", Object.DocumentBasis);
	OptionsForSelection.Insert("RecordInOtherIncome", RecordInOtherIncome);
	OptionsForSelection.Insert("ToExpenseAs", ToExpenseAs);
	OptionsForSelection.Insert("AdjustingEntryType", Object.AdjustingEntryType);
	
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ArticleAndAnalystSelectionParametersAdjustmentBeforeEnteringBalances(OptionsForSelection);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	AccountSelectionParameters_ = Documents.PurchaseAdjustment.AccountSettingsAdjustmentBeforeEnteringBalances(OptionsForSelection);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, AccountSelectionParameters_);
EndProcedure

&AtServer
Procedure CalculateTotalsFromDiscrepancyTable()
	
	For Each LineOfDiscrepancies In AdjustmentTable Do
		
		If LineOfDiscrepancies.VATRate = LineOfDiscrepancies.VATRateAfter
			Or (LineOfDiscrepancies.QuantityAfter = 0
				And LineOfDiscrepancies.AmountWithVATAfter = 0
				And LineOfDiscrepancies.VATAmountAfter = 0) Then
			DiscrepancySumWithVAT = LineOfDiscrepancies.AmountWithVATAfter - LineOfDiscrepancies.AmountIncludingVAT;
			DiscrepancyInAmountOfVAT  = LineOfDiscrepancies.VATAmountAfter - LineOfDiscrepancies.VATAmount;
			RecalculationOfAmountsOfIncreaseAndDecrease(DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
				LineOfDiscrepancies.PostingOption, LineOfDiscrepancies.ToExpenseAs);
		Else
			DiscrepancySumWithVAT = -LineOfDiscrepancies.AmountIncludingVAT;
			DiscrepancyInAmountOfVAT  = -LineOfDiscrepancies.VATAmount;
			RecalculationOfAmountsOfIncreaseAndDecrease(DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
				LineOfDiscrepancies.OptionToReflectWriteOff, LineOfDiscrepancies.ToExpenseAs);
			
			DiscrepancySumWithVAT = LineOfDiscrepancies.AmountWithVATAfter;
			DiscrepancyInAmountOfVAT  = LineOfDiscrepancies.VATAmountAfter;
			RecalculationOfAmountsOfIncreaseAndDecrease(DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
				LineOfDiscrepancies.PostingOption, LineOfDiscrepancies.ToExpenseAs);
		EndIf;
		
		TotalSNDSAmount = TotalSNDSAmount +  LineOfDiscrepancies.AmountWithVATAfter;
		AmountTotalVAT = AmountTotalVAT +  LineOfDiscrepancies.VATAmountAfter;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RecalculationOfAmountsOfIncreaseAndDecrease(DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT, PostingOption, ToExpenseAs)
	
	TotalAmountShovelcharge = TotalAmountShovelcharge + ?(DiscrepancySumWithVAT > 0, DiscrepancySumWithVAT, 0);
	TotalAmountZhamanshina = TotalAmountZhamanshina + ?(DiscrepancySumWithVAT < 0, -DiscrepancySumWithVAT, 0);
	TotalAmountJavelina  = TotalAmountJavelina + ?(DiscrepancyInAmountOfVAT > 0, DiscrepancyInAmountOfVAT, 0);
	TotalAmountOfNDSUReduction  = TotalAmountOfNDSUReduction + ?(DiscrepancyInAmountOfVAT < 0, -DiscrepancyInAmountOfVAT, 0);
	
	If PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome Then
		AmountForOtherIncome = AmountForOtherIncome + ?(DiscrepancySumWithVAT<0, -DiscrepancySumWithVAT, DiscrepancySumWithVAT);
	ElsIf PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs
		And Not ToExpenseAs Then
		AmountForOtherExpenses = AmountForOtherExpenses + ?(DiscrepancySumWithVAT<0, -DiscrepancySumWithVAT, DiscrepancySumWithVAT);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTextOfInvoiceReceived()
	
	RegistrationParameters = Documents.PurchaseAdjustment.ParametersForRegisteringInvoicesReceived(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
	
	TheTextOfTheInvoiceReceived = InvoicesReceivedOnBasisOf.Presentation;
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(AdjustmentTable, WarehouseTable, WarehouseGroup_, False);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
EndProcedure

&AtServer
Procedure UpdateServiceDetailsOfTableParts()
	
	ActionsForFillIn = New Structure;
	ActionsForFillIn.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ActionsForFillIn.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		ActionsForFillIn.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ActionsForFillIn);
	EndIf;
	ActionsForFillIn.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ServiceTableAdjustments = AdjustmentTable.Unload();
	ProductsServer.FillInServiceDetailsForProductInCollection(ServiceTableAdjustments, ActionsForFillIn);
	AdjustmentTable.Load(ServiceTableAdjustments);
	
	FillInServiceDetailsForPurposeOfVTCH();
	WarehouseData_2 = GetDataOnWarehouses();
	
	For Each LineOfDiscrepancies In AdjustmentTable Do
		
		WarehouseData_1 = WarehouseData_2.Find(LineOfDiscrepancies.Warehouse);
		If WarehouseData_1 <> Undefined Then
			LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
		
		If AdjustmentOfPurchaseOfOtherAssetServices Then
			FillInOfficialTraceabilityAttributesInProductLine(LineOfDiscrepancies);
		EndIf;
		
	EndDo;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(AdjustmentTable);
	
EndProcedure

&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtClient
Procedure ProcessingSelectionOfBaseDocumentClient(ValueSelected)
	
	Var ThereAreAdjustingEntries;
	
	CheckForAdjustments(Object.Ref, ValueSelected, ThereAreAdjustingEntries, TypeOfPreviousAdjustment);
	
	If ThereAreAdjustingEntries
		And AdjustmentTable.Count() > 0 Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.OK, NStr("vi = 'Có';
													|ru = 'Да';
													|en = 'Yes'; fa = 'بله';
													|it = 'Sì';
													|pl = 'Tak';
													|tr = 'Evet'"));
		ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Không';
														|ru = 'Нет';
														|en = 'No'; fa = 'خیر';
														|it = 'Non ci sono';
														|pl = 'Nie';
														|tr = 'Hayır'"));
		
		QueryText = NStr("vi = 'Khi thay đổi chứng từ cơ sở, bảng hiện tại với dữ liệu điều chỉnh sẽ được ghi đè theo cơ sở đã chọn có tính đến các điều chỉnh trước đây. Tiếp tục?';
						|ru = 'При изменении документа-основания текущая таблица с данными по корректировке будет перезаполнена по выбранному основанию с учетом предыдущих корректировок. Продолжить?';
						|en = 'If you change the base document, the current table with adjustment data will be refilled by the selected base document, considering the previous adjustments. Continue?'; fa = 'If you change the base document, the current table with adjustment data will be refilled by the selected base document, considering the previous adjustments. Continue?';
						|it = 'При изменении документа-основания текущая таблица с данными по корректировке будет перезаполнена по выбранному основанию с учетом предыдущих корректировок. Продолжить?';
						|pl = 'If you change the base document, the current table with adjustment data will be refilled by the selected base document, considering the previous adjustments. Continue?';
						|tr = 'Temel belge değiştirilirken düzenleme verilerini içeren mevcut tablo, önceki düzenlemeler dikkate alınarak seçilen tabana dayalı olarak yeniden doldurulacaktır. Devam edilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("TypeOfCorrectionWhenChangingPresentationDocumentCompletion", ThisObject, ValueSelected), QueryText, ButtonsList);
	Else
		ProcessingDocumentSelectionViaServer(ValueSelected);
		UpdateServiceFieldsOfValueTable();
	EndIf;

EndProcedure

&AtServer
Procedure ProcessingDocumentSelectionViaServer(ValueSelected)
	
	Modified = True;
	
	If AdjustmentTable.Count() > 0 Then
		UploadAdjustmentTableToDocumentData();
	EndIf;
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(ValueSelected);
	ValueToFormAttribute(DocumentObject, "Object");
	
	Object.DocumentBasis = ValueSelected;
	Object.CorrectedDocument = Undefined;	
	
	ModifiedRows = LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	PurchasesServer.ClearDetailsOfChargeForExpensesWhenSettingDestinationInTablePart(ModifiedRows);
	
	OnReadCreateAtServer();
	EstablishVisibilityOfRNPTQuantity();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
		
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenQuantityChanges(StructureOfActions, Form, Suffix = "")
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	
	If Suffix = "" Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount", "Count");
		StructureOfActions.Insert("ClearAmountOfSettlements");
	Else
		StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
		StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSuffixAmount", New Structure ("Suffix, QuantityName", Suffix, "Count"));
		StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form, Suffix = "")
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	If Suffix = "" Then
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("ClearAmountOfSettlements");
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Form.Object,
			StructureOfActions,
			"Warehouse",
			True);
	Else
		StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
		StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", Suffix);
		StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSuffixAmount", Suffix);
		StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Form.Object,
			StructureOfActions,
			"Warehouse",
			True,
			Suffix);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand,
												Var_URL = Undefined,
												StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

&AtServerNoContext
Procedure CheckForAdjustments(Ref, Basis, ThereAreAdjustingEntries, TypeOfPreviousAdjustment)
	
	PurchasesServer.CheckForAdjustmentsAndInvoices(Ref, Basis, ThereAreAdjustingEntries, Undefined);
	
	If ThereAreAdjustingEntries Then
		TypeOfPreviousAdjustment = PurchasesServer.GetTypeOfLastAdjustment(Ref, Basis);
	Else
		TypeOfPreviousAdjustment = Enums.AdjustingEntryTypes.EmptyRef();
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
										|tr = '""Para Birimi"" alanı doldurulmadı'"), Object.Ref, "Object.Currency",,Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	Suffix = "After";
	
	WarehouseParameters = New Structure;
	WarehouseParameters.Insert("CheckDate", Object.Date);
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.Suffix = Suffix;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
		
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	EndIf;
	
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffix", ParametersFillInVATRate);
	StructureOfActions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True));
		
	StructureOfActions.Insert("FillInOrderWarehouseAttribute", WarehouseParameters);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject, Suffix);
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = AdjustmentTable.Add();
		FillPropertyValues(
			CurrentRow,
			RowOfProduct,
			"PartnerProducts, Products, Characteristic, Package, Warehouse, Price, NumberOfPackages");
		
		CurrentRow.PriceAfter = RowOfProduct.Price;
		CurrentRow.NumberOfPackagesAfter = RowOfProduct.NumberOfPackages;
		
		UpdateRowNumberOfAdjustmentTable(CurrentRow);
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		AdjustmentTable);
		
	For Each CurrentRow In RowsToProcess Do
		
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "AdjustmentTable");
		
		If AdjustmentOfPurchaseOfOtherAssetServices Then
			FillInOfficialTraceabilityAttributesInProductLine(RowOfProduct);
		EndIf;
		
	EndDo;
	
	FillInAttributeForDebitingExpensesForServices();
	
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(AdjustmentTable);
	
	UpdateTitleOfAdjustmentTable();
	
EndProcedure

&AtServer
Function GetDataOnWarehouses()
	
	WarehousesOfDiscrepancies = AdjustmentTable.Unload(,"Warehouse");
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
	
	Items.AdjustmentTableWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	WarehouseSelectionData = WarehouseSelectionData(Object.Warehouse);
	
	TMCommonUseClientServer.AddSelectionParameter(Items.AdjustmentTableWarehouse, "Ref", WarehouseSelectionData);

EndProcedure

&AtServer
Function PlaceGoodsInTemporaryStorageServer(CollectionName)
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(ThisObject[CollectionName]);
	
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	Suffix = "After";
	TableOfGoods = GetFromTempStorage(AddressInTempStorage); // DocumentTabularSection.PurchaseAdjustment.Goods
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	EndIf;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffix", ParametersFillInVATRate);
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSuffixAmount", New Structure ("Suffix", Suffix));
	
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
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
		
		ArrayOfCollectionRows = AdjustmentTable.FindRows(New Structure("LineNumber", CurRow.LineNumber));
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
		AdjustmentTable,
		CachedValues);
			
	WhenChangingWarehouseInTablePartServer();
	CalculateFinalRevenueFigures(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(AdjustmentTable);
	
EndProcedure

&AtServer
Procedure FillInAttributeForDebitingExpensesForServices()
	
	// filling in the write-off attribute for expenses
	FilterStructure1 = New Structure("ItemsType", Enums.ItemsTypes.OperationService);
	FoundRows = AdjustmentTable.FindRows(FilterStructure1);

	StructureOfActions = New Structure;
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.AdjustmentKind,
		Object.Organization,
		Object.Department);
		
	For Each String In FoundRows Do
		String.ToExpenseAs = True;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		FoundRows,
		StructureOfActions,
		AdjustmentTable);
		
	For Each String In FoundRows Do
		IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, String, "AdjustmentTable");
	EndDo;
	
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
	
	AdjustmentTablePartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByTypeOfAdjustmentServer()
	
	ThisIsAdjustmentOfGoodsAndServices = Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices;
	
	Items.Warehouse.Visible = ThisIsAdjustmentOfGoodsAndServices And Not AdjustingProcessor;
	
	Items.AdjustmentTableContent.Visible = AdjustmentOfPurchaseOfOtherAssetServices;
	Items.AdjustmentTableLineOfBusiness.Visible = AdjustmentOfPurchaseOfOtherAssetServices;
	
	Items.AdjustmentTablePartnerProducts.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.AdjustmentTableProducts.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.AdjustmentTableCharacteristic.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.AdjustmentTableSeries.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.AdjustmentTableWarehouse.Visible = ThisIsAdjustmentOfGoodsAndServices And Not AdjustingProcessor;
	Items.AdjustmentTableCCDNumber.Visible = ThisIsAdjustmentOfGoodsAndServices Or AdjustmentOfPurchaseOfOtherAssetServices;
	Items.AdjustmentTableCCDNumberCountryOfOrigin.Visible = ThisIsAdjustmentOfGoodsAndServices Or AdjustmentOfPurchaseOfOtherAssetServices;
	Items.TableOfAdjustmentsGroupQuantityByRNPT.Visible = ThisIsAdjustmentOfGoodsAndServices Or AdjustmentOfPurchaseOfOtherAssetServices;
	
	Items.AdjustmentTableGroupNumberOfPackages.Visible = ThisIsAdjustmentOfGoodsAndServices;
	
	Items.AdjustmentTableProductsCode.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.AdjustmentTableProductItem.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.AdjustmentTablePurpose.Visible = ThisIsAdjustmentOfGoodsAndServices;
	
	Items.AdjustmentTableBatchesIndicationStatus.Visible = ThisIsAdjustmentOfGoodsAndServices;
	
EndProcedure

&AtClient
Procedure SetWhetherWarehouseIsFull()
	
	WarehouseIsRequired = ?(AdjustmentTable.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

&AtServer
Procedure UpdateVHFWarehouseObligation()
	
	FillParameters = New Structure("ThereAreWorks, IsCanceled, ThereIsWriteOffForExpenses", True, False, True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("WhenChangingProductType", FillParameters);
	BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions, Undefined);
	
	WarehouseIsRequired = ?(AdjustmentTable.Total("WarehouseIsRequired") = 0, 0, 1);
	
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

#EndRegion

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - form element.
//
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	
	If Item.Name = Items.Date.Name Then
		DateOnChange(Item);
	ElsIf Item.Name = Items.Partner.Name Then
		PartnerOnChange(Item);
	ElsIf Item.Name = Items.Counterparty.Name Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = Items.Terms.Name Then
		TermsOnChange(Item);
	ElsIf Item.Name = Items.Organization.Name Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = Items.Contract.Name Then
		ContractOnChange(Item);
	ElsIf Item.Name = Items.Warehouse.Name Then
		WarehouseOnChange(Item);
	ElsIf Item.Name = Items.AdjustingEntryType.Name Then
		AdjustingEntryTypeOnChange(Item);
	ElsIf Item.Name = Items.Department.Name Then
		DepartmentOnChange(Item);
	ElsIf Item.Name = Items.VATTaxation.Name Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = Items.PriceIncludesVAT.Name Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTablePartnerProducts.Name Then
		AdjustmentTablePartnerProductsOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableProducts.Name Then
		AdjustmentTableProductsOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableCharacteristic.Name Then
		TableAdjustmentCharacteristicWhenChanging(Item);
	ElsIf Item.Name = Items.AdjustmentTableSeries.Name Then
		AdjustmentTableSeriesOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableNumberOfPackages.Name Then
		AdjustmentTableNumberOfPackagesOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableNumberOfPackagesAfter.Name Then
		AdjustmentTableNumberOfPackagesAfterOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTablePackage.Name Then
		AdjustmentTablePackageOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableCount.Name Then
		AdjustmentTableCountOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableQuantityAfter.Name Then
		AdjustmentTableQuantityAfterOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTablePrice.Name Then
		AdjustmentTablePriceOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTablePriceAfter.Name Then
		AdjustmentTablePriceAfterOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableSum.Name Then
		AdjustmentTableSumOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableAmountAfter.Name Then
		AdjustmentTableAmountAfterOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableVATRate.Name Then
		AdjustmentTableVATRateOnChange(Item);
	ElsIf Item.Name =Items.AdjustmentTableVATRateAfter.Name  Then
		AdjustmentTableVATRateAfterOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableVATAmount.Name Then
		AdjustmentTableVATAmountOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableVATAmountAfter.Name Then
		AdjustmentTableVATAmountAfterOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableWarehouse.Name Then
		AdjustmentTableWarehouseOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableDepartment.Name Then
		
	ElsIf Item.Name = Items.AdjustmentTableToExpenseAs.Name Then
		AdjustmentTableToExpenseAsOnChange(Item);
	ElsIf Item.Name =Items.AdjustmentTableExpenseItem.Name Then
		AdjustmentTableExpenseItemOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableCCDNumber.Name Then
		AdjustmentTableCCDNumberOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTablePurpose.Name Then
		AdjustmentTablePurposeOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Command - FormCommand - form command.
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	
	If Command.Name = Commands.SelectGoods.Name Then
		SelectGoods(Command);
	ElsIf Command.Name = Commands.FillThePricesByTermsOfSales.Name Then
		FillThePricesByTermsOfSales(Command);
	ElsIf Command.Name = Commands.FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice.Name Then
		FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPrices(Command);
	ElsIf Command.Name = Commands.FillInTheWarehouseInSelectedLines.Name Then
		FillInTheWarehouseInSelectedLines(Command);
	ElsIf Command.Name = Commands.FillInTheItemByThePartnerSItem.Name Then
		FillInTheItemByThePartnerSItem(Command);
	ElsIf Command.Name = Commands.FillInAdjustmentData.Name Then
		FillInAdjustmentData(Command);
	ElsIf Command.Name = Commands.EditDocumentBeingCorrected.Name Then
		EditDocumentBeingCorrected(Command);
	ElsIf Command.Name = Commands.InsertRows.Name Then
		InsertRows(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - form element.
//	Cancel - Boolean - indicates termination of the operation.
//
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	
	If Item.Name = Items.AdjustmentTable.Name Then
		AdjustmentTableBeforeRowChange(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - form element.
//	Cancel - Boolean - indicates termination of the operation.
//
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	
	If Item.Name = Items.AdjustmentTable.Name Then
		AdjustmentTableBeforeDeleteRow(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - form element.
//	Cancel - Boolean - indicates termination of the operation.
//	Copy - Boolean - indicates whether the copy is being performed.
//	Parent - AnyRef - reference to the parent element.
//	Var_Group - Boolean - indicates whether a group has been added.
//
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item,
																					Cancel,
																					Copy,
																					Parent,
																					Var_Group)
	
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	
EndProcedure

&AtClient
Function PerformChecksBeforeChangingStatus()
	
	Var ThereAreAdjustingEntries;
	
	PropsCanBeChanged = False;
	
	AdditionalParameters = New Structure;
	Notification = New CallbackDescription("PerformChecksBeforeChangingStatusCompletion",
											ThisObject,
											AdditionalParameters);
	
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
	
	CheckForAdjustments(Object.Ref, Object.DocumentBasis, ThereAreAdjustingEntries, TypeOfPreviousAdjustment);
	
	If ThereAreAdjustingEntries Then
		ButtonsList = New ValueList;
		ButtonsList.Add("EnterTheAdjustment",	NStr("vi = 'Nhập điều chỉnh';
														|ru = 'Ввести корректировку';
														|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
														|it = 'Inserire rettifica';
														|pl = 'Wprowadź korektę';
														|tr = 'Bir düzenleme yapın'"));
		ButtonsList.Add("UndoChanges",		NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Cancel';
													|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Trên cơ sở chứng từ, đã nhập điều chỉnh mua sắm.
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
	Else
		RunCallback(Notification, "ChangeAttribute");
		
		PropsCanBeChanged = True;
	EndIf;
	
	Return PropsCanBeChanged;
	
EndFunction

&AtClient
Procedure PerformChecksBeforeChangingStatusCompletion(ResponseCode, AdditionalParameters) Export
	
	If ResponseCode = "EnterTheAdjustment" Then
		OpeningParameters = New Structure("Basis", Object.DocumentBasis);
		
		OpenForm("Document.PurchaseAdjustment.Form.DocumentFormBeforeBalanceEntry",
					OpeningParameters);
	EndIf;
	
	CalculateFinalRevenueFigures(ThisObject);
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - form element.
//
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If Not PerformChecksBeforeChangingStatus() Then
		TMCommonUseClient.ReturnPreviousPropsValue(ThisObject, Item);
		
		Return;
	Else
		TMCommonUseClient.SaveAttributeValue(ThisObject, Item);
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventOnChange(Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - form element.
//
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
//	Command - FormCommand - form command.
//
&AtClient
Procedure Attachable_Command_SetAvailabilityOfItemsByStatusServer(Command)
	
	If Not PerformChecksBeforeChangingStatus() Then
		Return;
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - form element.
//	Cancel - Boolean - indicates termination of the operation.
//
&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If Item.CurrentData = Undefined
		Or StructureOfActionsControlOfNonAgreedChanges = Undefined Then
		
		Return;
		
	EndIf;
	
	FillPropertyValues(StructureOfActionsControlOfNonAgreedChanges.AttributesValues[Item.Name], Item.CurrentData);
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - form element.
//	Cancel - Boolean - indicates termination of the operation.
//
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
//	Item - FormGroup, FormTable, FormField, FormButton - form element.
//	Cancel - Boolean - indicates termination of the operation.
//	Copy - Boolean - indicates whether the copy is being performed.
//	Parent - AnyRef - reference to the parent element.
//	Var_Group - Boolean - indicates whether a group has been added.
//
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item,
																							Cancel,
																							Copy,
																							Parent,
																							Var_Group)
	
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

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(AdjustmentTable, Items.AdjustmentTable.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	Suffix = "After";
	
	Columns = "Products,Characteristic,Content,Package,NumberOfPackages,Count,Price,CCDNumber,Warehouse,
		|Department,LineOfBusiness,NumberOfPackagesAfter,QuantityAfter,PriceAfter,
		|PostingOption,Series,ToExpenseAs,ItemsType";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	If TableOfGoods.Columns.Find("ItemsType") = Undefined Then
		TableOfGoods.Columns.Add("ItemsType", New TypeDescription("EnumRef.ItemsTypes"));
	EndIf;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffix", ParametersFillInVATRate);
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
			StructureOfActions);
	EndIf;
	
	If NumberOfPackagesIsUsed Then
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject, Suffix);
	Else
		AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisObject);
		AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisObject, Suffix);
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	ThereIsPriceAfter = False;
	ThereIsQuantityAfter = False;
	If TableOfGoods.Columns.Find("PriceAfter") <> Undefined Then
		ThereIsPriceAfter = True;
	EndIf;
	If TableOfGoods.Columns.Find("QuantityAfter") <> Undefined
		And TableOfGoods.Columns.Find("NumberOfPackagesAfter") <> Undefined Then
		ThereIsQuantityAfter = True;
	EndIf;
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		If Not AdjustmentOfPurchaseOfOtherAssetServices Then
			SelectionByTypeOfNomenclature = ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False);
			If SelectionByTypeOfNomenclature.Find(RowOfProduct.ItemsType) = Undefined Then
				Continue;
			EndIf;
		EndIf;
		
		CurrentRow = AdjustmentTable.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		If Not ThereIsPriceAfter Then
			CurrentRow.PriceAfter = CurrentRow.Price;
		EndIf;
		If Not ThereIsQuantityAfter Then
			CurrentRow.NumberOfPackagesAfter = CurrentRow.NumberOfPackages;
			CurrentRow.QuantityAfter = CurrentRow.Count;
		EndIf;
		UpdateRowNumberOfAdjustmentTable(CurrentRow);
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		AdjustmentTable,
		CachedValues);
		
	For Each CurrentRow In RowsToProcess Do
		
		If AdjustmentOfPurchaseOfOtherAssetServices Then
			FillInOfficialTraceabilityAttributesInProductLine(CurrentRow);
		EndIf;
		
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "AdjustmentTable");
		
	EndDo;
	
	ActionsForFillIn = New Structure;
	ActionsForFillIn.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ActionsForFillIn.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	If Not AdjustmentOfPurchaseOfOtherAssetServices Then
		ActionsForFillIn.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ActionsForFillIn);
	EndIf;
	ActionsForFillIn.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(AdjustmentTable, ActionsForFillIn);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(AdjustmentTable);
	FillInAttributeForDebitingExpensesForServices();
	
	WhenChangingWarehouseInTablePartServer();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("AdjustmentTableInsertRows");
	ItemArray.Add("AdjustmentTableContextMenuInsertLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("AdjustmentTableInsertRows");
	ItemArray.Add("AdjustmentTableContextMenuInsertLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

&AtServerNoContext
Function GoodsAreTraceable(CCDNumber)
	
	Return VendorInvoiceServicesAndAssetsLocalization.GoodsAreTraceable(CCDNumber);
	
EndFunction

#EndRegion

#Region WorkingWithCounterparties





&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "")
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,SeriesSpecificationParameters,Text)Then
		ExceptionText = NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - trong chứng từ này để chỉ ra sê-ri không cần gọi ra máy chủ.';
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

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.PurchaseAdjustment);
	SeriesSpecificationParameters.NameTSGoods = "AdjustmentTable";
	SeriesSpecificationParameters.TSSeriesName = "AdjustmentTable";
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.AdjustmentTableBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.AdjustmentTableSeries.Visible               = SeriesSpecificationParameters.UseCostAccountingByBatches;
	
EndProcedure

#EndRegion

#Region CheckingDocumentFilling

&AtServer
Procedure CheckForDuplicateRowsInTableAndDeleteSeries(Cancel)
	
	KeyAttributes = Documents.PurchaseAdjustment.KeyAttributesOFRelationshipOfTableRows(AdjustmentOfPurchaseOfOtherAssetServices);
	
	TMCommonUse.CheckForDuplicatesOfTSStrings(
		ThisObject,
		"AdjustmentTable",
		KeyAttributes,
		Cancel,
		NStr("vi = 'Dữ liệu điều chỉnh';
			|ru = 'Данные корректировки';
			|en = 'Correction data'; fa = 'داده‌های اصلاح';
			|it = 'Dati di correzione';
			|pl = 'Dane korekty';
			|tr = 'Düzeltme verileri'"),
		True);
		
	SeriesSpecificationParameters.NameTSGoods = "AdjustmentTable";
	SeriesSpecificationParameters.TSSeriesName = "AdjustmentTable";
	
	ProductsServer.ClearUnusedSeries(
	ThisObject,
	SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region ReflectionOptions

&AtClientAtServerNoContext
Function GetInformationAboutDiscrepancyInLine(CurrentRow, WriteOff = False)
	
	DataByDiscrepancy = New Structure("ThisIsProductNotWrittenOffForExpenses,
		|DivergenceOfVATRate,
		|NumberOfPackages_Discrepancy,
		|AmountWithVATDiscrepancy,
		|VATAmountDiscrepancy");

	DataByDiscrepancy.ThisIsProductNotWrittenOffForExpenses = (CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
				Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
				And Not CurrentRow.ToExpenseAs;
		
	DataByDiscrepancy.DivergenceOfVATRate = CurrentRow.VATRate <> CurrentRow.VATRateAfter
	And (CurrentRow.QuantityAfter > 0
		Or CurrentRow.AmountWithVATAfter > 0
		Or CurrentRow.VATAmountAfter > 0);
	
	If DataByDiscrepancy.DivergenceOfVATRate Then
		If WriteOff Then
			DataByDiscrepancy.NumberOfPackages_Discrepancy = -CurrentRow.NumberOfPackages;
			DataByDiscrepancy.AmountWithVATDiscrepancy = -CurrentRow.AmountIncludingVAT;
			DataByDiscrepancy.VATAmountDiscrepancy = -CurrentRow.VATAmount;
		Else
			DataByDiscrepancy.NumberOfPackages_Discrepancy = CurrentRow.NumberOfPackagesAfter;
			DataByDiscrepancy.AmountWithVATDiscrepancy = CurrentRow.AmountWithVATAfter;
			DataByDiscrepancy.VATAmountDiscrepancy = CurrentRow.VATAmountAfter;
		EndIf;
	Else
		DataByDiscrepancy.NumberOfPackages_Discrepancy = CurrentRow.NumberOfPackagesAfter - CurrentRow.NumberOfPackages;
		DataByDiscrepancy.AmountWithVATDiscrepancy = CurrentRow.AmountWithVATAfter - CurrentRow.AmountIncludingVAT;
		DataByDiscrepancy.VATAmountDiscrepancy = CurrentRow.VATAmountAfter - CurrentRow.VATAmount;
	EndIf;
	
	Return DataByDiscrepancy;
	
EndFunction

&AtClientAtServerNoContext
Function VariantOfReflectionByLine(CurrentRow)

	PostingOption = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
	
	DataByDiscrepancy = GetInformationAboutDiscrepancyInLine(CurrentRow);
	
	If (CurrentRow.ItemsType <> PredefinedValue("Enum.ItemsTypes.OwnGoods")
		And CurrentRow.ItemsType <> PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
		Or DataByDiscrepancy.NumberOfPackages_Discrepancy = 0 Then
		
		If (DataByDiscrepancy.AmountWithVATDiscrepancy < 0
			Or (DataByDiscrepancy.AmountWithVATDiscrepancy = 0 And DataByDiscrepancy.VATAmountDiscrepancy < 0)) Then
				PostingOption = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost");
		ElsIf (DataByDiscrepancy.AmountWithVATDiscrepancy > 0
			Or (DataByDiscrepancy.AmountWithVATDiscrepancy = 0 And DataByDiscrepancy.VATAmountDiscrepancy > 0))
			Or Not ValueIsFilled(CurrentRow.ItemsType) Then
				PostingOption = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost");
		EndIf;
	EndIf;
	
	Return PostingOption;
	
EndFunction

&AtClientAtServerNoContext
Function GetReflectionOptionsAvailableForString(CurrentRow)
	
	ChoiceList = New Array();
	
	DataByDiscrepancy = GetInformationAboutDiscrepancyInLine(CurrentRow);
	
	If DataByDiscrepancy.NumberOfPackages_Discrepancy > 0 Then
		If Not DataByDiscrepancy.AmountWithVATDiscrepancy = 0 Then
			ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs"));
		EndIf;
		If Not DataByDiscrepancy.ThisIsProductNotWrittenOffForExpenses Then
			ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost"));
		ElsIf CurrentRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
			ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncludeDuringPhysicalInventoryCount"));
		Else
			ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock"));
		EndIf;
	ElsIf DataByDiscrepancy.NumberOfPackages_Discrepancy < 0 Then
		If Not DataByDiscrepancy.AmountWithVATDiscrepancy = 0 Then
			ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome"));
		EndIf;
		If Not DataByDiscrepancy.ThisIsProductNotWrittenOffForExpenses Then
			ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost"));
		ElsIf CurrentRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
			ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseIncludeDuringPhysicalInventoryCount"));
		Else
			ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock"));
		EndIf;
	ElsIf DataByDiscrepancy.NumberOfPackages_Discrepancy = 0 And (DataByDiscrepancy.AmountWithVATDiscrepancy > 0
		Or (DataByDiscrepancy.AmountWithVATDiscrepancy = 0 And DataByDiscrepancy.VATAmountDiscrepancy > 0)) Then
		If Not DataByDiscrepancy.AmountWithVATDiscrepancy = 0 Then
			ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs"));
		EndIf;
		ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost"));
	ElsIf DataByDiscrepancy.NumberOfPackages_Discrepancy = 0 And (DataByDiscrepancy.AmountWithVATDiscrepancy < 0
		Or (DataByDiscrepancy.AmountWithVATDiscrepancy = 0 And DataByDiscrepancy.VATAmountDiscrepancy < 0)) Then
		If Not DataByDiscrepancy.AmountWithVATDiscrepancy = 0 Then
			ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome"));
		EndIf;
		ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost"));
	EndIf;
	
	Return ChoiceList;
	
EndFunction

&AtClientAtServerNoContext
Function GetAvailableOptionsForReflectingWriteOffForLine(CurrentRow)
	
	ChoiceList = New Array();

	DataByDiscrepancy = GetInformationAboutDiscrepancyInLine(CurrentRow, True);
	
	If DataByDiscrepancy.DivergenceOfVATRate Then
		
		If DataByDiscrepancy.NumberOfPackages_Discrepancy < 0 Then
			If Not DataByDiscrepancy.AmountWithVATDiscrepancy = 0 Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome"));
			EndIf;
			If Not DataByDiscrepancy.ThisIsProductNotWrittenOffForExpenses Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost"));
			ElsIf CurrentRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseIncludeDuringPhysicalInventoryCount"));
			Else
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock"));
			EndIf;
		ElsIf DataByDiscrepancy.NumberOfPackages_Discrepancy = 0 And (DataByDiscrepancy.AmountWithVATDiscrepancy < 0
			Or (DataByDiscrepancy.AmountWithVATDiscrepancy = 0 And DataByDiscrepancy.VATAmountDiscrepancy < 0)) Then
			If Not DataByDiscrepancy.AmountWithVATDiscrepancy = 0 Then
				ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome"));
			EndIf;
			ChoiceList.Add(PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost"));
		EndIf;
	
	EndIf;
	
	Return ChoiceList;
	
EndFunction

#EndRegion //ReflectionOptions 

&AtClient
Procedure DateOfChangeAfterVerification(Result, AdditionalParameters) Export
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtServer
Procedure SetSelectionParametersAdjustmentTableWarehouse()
	
	Items.AdjustmentTableWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	WarehouseSelectionData = WarehouseSelectionData(Object.Warehouse);
	
	TMCommonUseClientServer.AddSelectionParameter(Items.AdjustmentTableWarehouse, "Ref", WarehouseSelectionData);
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	AutoTitle = False;
	TitleTemplate1 = NStr("vi = 'Điều chỉnh mua hàng trước khi nhập số dư %1';
							|ru = 'Корректировка приобретения до ввода остатков %1';
							|en = 'Purchase adjustment before balance entry %1'; fa = 'Purchase adjustment before balance entry %1';
							|it = 'Correzione di acquisizione prima dell''inserimento dei saldi %1';
							|pl = 'Korekta zakupu przed wprowadzeniem sald %1';
							|tr = '%1 bakiyeleri girmeden önce satın alma düzeltmesi'");
	
	If ValueIsFilled(Object.Ref) Then
		EndOfTitle = NStr("vi = '%1 ngày %2';
							|ru = '%1 от %2';
							|en = '%1 from %2'; fa = '%1 from %2';
							|it = '%1 del %2';
							|pl = '%1 z dn. %2';
							|tr = '%2tarihli %1'");
		EndOfTitle = StrTemplate(EndOfTitle, Object.Number, Object.Date);
	Else
		EndOfTitle = NStr("vi = '(tạo mới)';
							|ru = '(создание)';
							|en = '(create)'; fa = '(create)';
							|it = '(creazione)';
							|pl = '(tworzenie)';
							|tr = '(oluştur)'");
	EndIf;
	
	Title = StrTemplate(TitleTemplate1, EndOfTitle);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingGTDINumberOfHSCode()
	
	ArrayOfCCDNumberParameters = New Array;
	ArrayOfParametersOfHSCode = New Array;
	
	If AdjustmentOfPurchaseOfOtherAssetServices Then
		
		ArrayOfCCDTypes = New ValueList;
		ArrayOfCCDTypes.Add(Enums.CCDNumberTypes.ProductBatchIDNumber);
		ArrayOfCCDTypes.Add(Enums.CCDNumberTypes.KitRNPT);
		
		ArrayOfCCDNumberParameters.Add(
			New ChoiceParameter(
				"ListOfCCDTypes",
				ArrayOfCCDTypes));
		
		ArrayOfParametersOfHSCode.Add(
			New ChoiceParameter(
				"Filter.TracedGoods",
				True));
		
	EndIf;
	Items.AdjustmentTableCCDNumber.ChoiceParameters = New FixedArray(ArrayOfCCDNumberParameters);
	Items.AdjustmentTableFEACNCode.ChoiceParameters = New FixedArray(ArrayOfParametersOfHSCode);
	
EndProcedure

&AtServer
Procedure SetHeadingIncomeExpenseItem()
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.AdjustmentTableExpenseItem.Title = NStr("vi = 'Ghi giảm vào chi phí';
														|ru = 'Списать на расходы';
														|en = 'Expense as'; fa = 'هزینه به عنوان';
														|it = 'Stornare sulle spese';
														|pl = 'Spisać w koszty';
														|tr = 'Gider olarak kaydet'");
		Items.AdjustmentTableToExpenseAs.Title = NStr("vi = 'Ghi giảm vào chi phí';
														|ru = 'Списать на расходы';
														|en = 'Expense as'; fa = 'هزینه به عنوان';
														|it = 'Stornare sulle spese';
														|pl = 'Spisać w koszty';
														|tr = 'Gider olarak kaydet'");
		Items.TextAmountForOtherExpensesAssets.Title = NStr("vi = 'Đối với chi phí:';
															|ru = 'На расходы:';
															|en = 'To expenses:'; fa = 'To expenses:';
															|it = 'Sulle spese:';
															|pl = 'Na wydatki:';
															|tr = 'Masraflar:'");
		Items.TextAmountForOtherIncomeLiabilities.Title = NStr("vi = 'Đối với thu nhập:';
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
Function EconomicOperationOfFoundationDocument(AdjustingEntryType)
	
	Operation = Enums.BusinessTransactions.EmptyRef();
	
	If AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
		Operation = Enums.BusinessTransactions.PurchaseFromSupplier;
	EndIf;
	
	Return Operation;
	
EndFunction

&AtServer
Procedure SetBusinessOperationOfDocument(DocumentBasis)
	
	BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
	
	If Object.BusinessOperation <> BusinessOperation Then
		Object.BusinessOperation = BusinessOperation;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTypeOfAdjustment()
	
	If Not ValueIsFilled(Object.AdjustingEntryType) Then
		Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices;
	EndIf;
	
	TypeOfAdjustmentIsOld = Object.AdjustingEntryType;
	
	Items.AdjustingEntryType.Enabled = Not ValueIsFilled(TypeOfPreviousAdjustment);
	
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
	
	If Not Items.TableOfAdjustmentsGroupQuantityByRNPT.Visible Then
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Warehouse",
												True);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						AdjustmentTable);
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfRNPTQuantity()
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
																			Object.Date,
																			"TableOfAdjustmentsGroupQuantityByRNPT",
																			AdjustmentOfPurchaseOfOtherAssetServices);
	
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure LoadAdjustmentTableFromDocumentDataOnServer()
	
	ResultTable2 = Documents.PurchaseAdjustment.AdjustmentDataBeforeEnteringBalances(Object, NumberOfPackagesIsUsed);
	
	AdjustmentTable.Load(ResultTable2);
	
EndProcedure

&AtServer
Procedure UploadAdjustmentTableToDocumentData()
	
	Object.Goods.Clear();
	Object.Discrepancies.Clear();
	
	For Each RowOfAdjustmentTable In AdjustmentTable Do
		
		LineProducts_ = Object.Goods.Add();
		FillPropertyValues(LineProducts_, RowOfAdjustmentTable);
		LineProducts_.VATRate = RowOfAdjustmentTable.VATRateAfter;
		LineProducts_.Price = RowOfAdjustmentTable.PriceAfter;
		LineProducts_.NumberOfPackages = RowOfAdjustmentTable.NumberOfPackagesAfter;
		LineProducts_.Count = RowOfAdjustmentTable.QuantityAfter;
		LineProducts_.QuantityByGBRN = RowOfAdjustmentTable.QuantityAccordingToRNPTAfter;
		LineProducts_.Sum = RowOfAdjustmentTable.AmountAfter;
		LineProducts_.VATAmount = RowOfAdjustmentTable.VATAmountAfter;
		LineProducts_.AmountIncludingVAT = RowOfAdjustmentTable.AmountWithVATAfter;
		LineProducts_.AmountARAP = RowOfAdjustmentTable.AmountOfSettlementsAfter;
		
	EndDo;
	
	For Each RowOfAdjustmentTable In AdjustmentTable Do
		
		NumberOfPackages	= RowOfAdjustmentTable.NumberOfPackagesAfter - RowOfAdjustmentTable.NumberOfPackages;
		Count			= RowOfAdjustmentTable.QuantityAfter - RowOfAdjustmentTable.Count;
		QuantityByGBRN	= RowOfAdjustmentTable.QuantityAccordingToRNPTAfter - RowOfAdjustmentTable.QuantityByGBRN;
		Sum				= RowOfAdjustmentTable.AmountAfter - RowOfAdjustmentTable.Sum;
		VATAmount			= RowOfAdjustmentTable.VATAmountAfter - RowOfAdjustmentTable.VATAmount;
		AmountIncludingVAT			= RowOfAdjustmentTable.AmountWithVATAfter - RowOfAdjustmentTable.AmountIncludingVAT;
		AmountARAP	= RowOfAdjustmentTable.AmountOfSettlementsAfter - RowOfAdjustmentTable.AmountARAP;
		
		DifferentVATRates = RowOfAdjustmentTable.VATRate <> RowOfAdjustmentTable.VATRateAfter
			And (RowOfAdjustmentTable.QuantityAfter > 0
				Or RowOfAdjustmentTable.AmountWithVATAfter > 0
				Or RowOfAdjustmentTable.AmountOfSettlementsAfter > 0
				Or RowOfAdjustmentTable.VATAmountAfter > 0);
		
		If NumberOfPackages <> 0 Or Count <> 0 Or QuantityByGBRN <> 0 Or Sum <> 0 Or VATAmount <> 0 Or AmountIncludingVAT <> 0 Or AmountARAP <> 0
			Or DifferentVATRates Then
		
			If RowOfAdjustmentTable.VATRateAfter = RowOfAdjustmentTable.VATRate Then
				DivergenceLine = Object.Discrepancies.Add();
				FillPropertyValues(DivergenceLine, RowOfAdjustmentTable);
				DivergenceLine.NumberOfPackages = NumberOfPackages;
				DivergenceLine.Count = Count;
				DivergenceLine.QuantityByGBRN = QuantityByGBRN;
				DivergenceLine.Sum = Sum;
				DivergenceLine.VATAmount = VATAmount;
				DivergenceLine.AmountIncludingVAT = AmountIncludingVAT;
				DivergenceLine.AmountARAP = AmountARAP;
			Else
				If RowOfAdjustmentTable.NumberOfPackages <> 0
					Or RowOfAdjustmentTable.Count <> 0
					Or RowOfAdjustmentTable.QuantityByGBRN <> 0
					Or RowOfAdjustmentTable.Sum <> 0
					Or RowOfAdjustmentTable.VATAmount <> 0
					Or RowOfAdjustmentTable.AmountIncludingVAT <> 0
					Or RowOfAdjustmentTable.AmountARAP <> 0 Then
					
					DivergenceLine = Object.Discrepancies.Add();
					FillPropertyValues(DivergenceLine, RowOfAdjustmentTable);
					DivergenceLine.NumberOfPackages = -RowOfAdjustmentTable.NumberOfPackages;
					DivergenceLine.Count = -RowOfAdjustmentTable.Count;
					DivergenceLine.QuantityByGBRN = -RowOfAdjustmentTable.QuantityByGBRN;
					DivergenceLine.Sum = -RowOfAdjustmentTable.Sum;
					DivergenceLine.VATAmount = -RowOfAdjustmentTable.VATAmount;
					DivergenceLine.AmountIncludingVAT = -RowOfAdjustmentTable.AmountIncludingVAT;
					DivergenceLine.AmountARAP = -RowOfAdjustmentTable.AmountARAP;
					DivergenceLine.PostingOption = ?(DifferentVATRates, RowOfAdjustmentTable.OptionToReflectWriteOff, RowOfAdjustmentTable.PostingOption);
				EndIf;
				
				If RowOfAdjustmentTable.NumberOfPackagesAfter <> 0
					Or RowOfAdjustmentTable.QuantityAfter <> 0
					Or RowOfAdjustmentTable.QuantityAccordingToRNPTAfter <> 0
					Or RowOfAdjustmentTable.AmountAfter <> 0
					Or RowOfAdjustmentTable.VATAmountAfter <> 0
					Or RowOfAdjustmentTable.AmountWithVATAfter <> 0
					Or RowOfAdjustmentTable.AmountOfSettlementsAfter <> 0 Then
					
					DivergenceLine = Object.Discrepancies.Add();
					FillPropertyValues(DivergenceLine, RowOfAdjustmentTable);
					DivergenceLine.VATRate = RowOfAdjustmentTable.VATRateAfter;
					DivergenceLine.NumberOfPackages = RowOfAdjustmentTable.NumberOfPackagesAfter;
					DivergenceLine.Count = RowOfAdjustmentTable.QuantityAfter;
					DivergenceLine.QuantityByGBRN = RowOfAdjustmentTable.QuantityAccordingToRNPTAfter;
					DivergenceLine.Sum = RowOfAdjustmentTable.AmountAfter;
					DivergenceLine.VATAmount = RowOfAdjustmentTable.VATAmountAfter;
					DivergenceLine.AmountIncludingVAT = RowOfAdjustmentTable.AmountWithVATAfter;
					DivergenceLine.AmountARAP = RowOfAdjustmentTable.AmountOfSettlementsAfter;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateServiceFieldsOfValueTable()
	
	If AdjustmentTable.Count() = 0 Then
		TitleText = NStr("vi = 'Dữ liệu điều chỉnh';
						|ru = 'Данные корректировки';
						|en = 'Correction data'; fa = 'داده‌های اصلاح';
						|it = 'Dati di correzione';
						|pl = 'Dane korekty';
						|tr = 'Düzeltme verileri'");
	Else
		TitleText = StrTemplate(NStr("vi = 'Dữ liệu điều chỉnh (%1)';
									|ru = 'Данные корректировки (%1)';
									|en = 'Adjustment data (%1)'; fa = 'Adjustment data (%1)';
									|it = 'Dati di correzione (%1)';
									|pl = 'Dane korekty (%1)';
									|tr = 'Düzeltme verileri (%1)'"), AdjustmentTable.Count());
	EndIf;
	
	Items.GroupTableAdjustments.Title = TitleText;
	
	For Each CurrentRow In AdjustmentTable Do
		CurrentRow.LineNumber = AdjustmentTable.IndexOf(CurrentRow)+1;
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateTitleOfAdjustmentTable()
	
	If AdjustmentTable.Count() = 0 Then
		TitleText = NStr("vi = 'Dữ liệu điều chỉnh';
						|ru = 'Данные корректировки';
						|en = 'Correction data'; fa = 'داده‌های اصلاح';
						|it = 'Dati di correzione';
						|pl = 'Dane korekty';
						|tr = 'Düzeltme verileri'");
	Else
		TitleText = StrTemplate(NStr("vi = 'Dữ liệu điều chỉnh (%1)';
									|ru = 'Данные корректировки (%1)';
									|en = 'Adjustment data (%1)'; fa = 'Adjustment data (%1)';
									|it = 'Dati di correzione (%1)';
									|pl = 'Dane korekty (%1)';
									|tr = 'Düzeltme verileri (%1)'"), AdjustmentTable.Count());
	EndIf;
	
	Items.GroupTableAdjustments.Title = TitleText;
	
EndProcedure

&AtServer
Procedure UpdateRowNumberOfAdjustmentTable(CurrentRow)
	
	CurrentRow.LineNumber = AdjustmentTable.IndexOf(CurrentRow)+1;
	
EndProcedure

&AtClient
Procedure OpenBaseSelectionForm()
	
	StructureFilter = New Structure;
	StructureFilter.Insert("Posted", True);
	StructureFilter.Insert("SourceDocumentType",
		PredefinedValue("Enum.SourceDocumentTypes.PurchaseFromVendor"));
	StructureFilter.Insert("Counterparty", Object.Counterparty);
	StructureFilter.Insert("Partner", Object.Partner);
	StructureFilter.Insert("VATTaxation", Object.VATTaxation);
	
	OpenForm(
		"Document.SourceDocument.ChoiceForm",
		New Structure("Filter", StructureFilter),
		ThisObject);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForPurposeOfVTCH()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInServiceDetailsForPurpose", New Structure("OnlyDestinationType", True));
	BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions, Undefined);
	
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

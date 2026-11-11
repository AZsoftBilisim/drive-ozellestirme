#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details



&AtClient
Var ParametersForRecording Export;

&AtClient
Var PreviousRowDetails; //used to unlink the receipt line from the order line

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
	
	If Not GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments")
		And Not GetFunctionalOption("UseBusinessUnits") Then
		Items.AdjustmentTableSenderGroup.Visible = False;
	ElsIf Not WarehouseGroup_ Then
		Items.AdjustmentTableSenderGroup.Title = NStr("vi = 'Bộ phận gửi';
														|ru = 'Подразделение-отправитель';
														|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
														|it = 'Reparto-mittente';
														|pl = 'Shipping business unit';
														|tr = 'Gönderen departman'");
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	UsePartnersAsCounterparties	= GetFunctionalOption("UsePartnersAsCounterparties");
	UsePriceManagementSystem25			= PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	OptionsForSelection = OptionsForSelectingArticlesAndAnalytics();
	ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.OptionsForSelectingArticlesAndAnalyticsBeforeEnteringBalances(OptionsForSelection);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	If Not ValueIsFilled(Object.Ref)
		Or (Parameters.Property("CopyingValue")
			And ValueIsFilled(Parameters.CopyingValue.AdjustingEntryType)) Then
		OnReadCreateAtServer();
		PrepareFillSetSeriesVisibility();
		If ValueIsFilled(TypeOfPreviousAdjustment) Then
			Object.AdjustingEntryType = TypeOfPreviousAdjustment;
		EndIf;
	EndIf;
	CalculateFinalImplementationIndicators(ThisObject);
	SetAvailabilityOfClipboardCommands();
	SalesServer.SetBlankContractMark(Items, "Contract");
	
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

	EstablishRelationshipOfSelectionParametersForUnitsOfMeasurement();
		
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording 
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "AdjustmentTableCCDNumber");
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	OnReadCreateAtServer();
	CalculateFinalImplementationIndicators(ThisObject);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	ClearServiceDataOfDebitedImportedGoods();
	CheckForDuplicateRowsInTableAndDeleteSeries(Cancel);
	UploadAdjustmentTableToDocumentData();
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		
		Return;
	EndIf;
	
	CalculateFinalImplementationIndicators(ThisObject);
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	

	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

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
	EstablishCostPresentation();
	SetAvailabilityOfItemsByStatusServer();
	
	CalculateFinalImplementationIndicators(ThisObject);
	UpdateVHFWarehouseObligation();
	UpdateTextDocumentsBasedOn();
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject, CurrentObject.AdditionalProperties);
	

	PurchasesServer.FillInServiceAttributesOfCCDNumber(AdjustmentTable);
	
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, False, ReferenceDocumentDateForCertificate);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
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
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
	EndIf;
	
	If EventName = "EditSet"
		And Parameter.OwnerForm = UUID Then
		
		KitParameters = New Structure;
		KitParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		KitParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		KitParameters.Insert("DialColumns", DialColumns());
		If Items.AdjustmentTable.CurrentItem <> Undefined
			And StrFind(Items.AdjustmentTable.CurrentItem.Name, "After") > 0 Then
			KitParameters.Insert("MatchingColumnNamesForSet", MapNamesOfSetColumns());
		EndIf;
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
		OpeningParameters.Insert("Currency", Object.Currency);
		OpeningParameters.Insert("Partner", Object.Partner);
		OpeningParameters.Insert("Terms", Object.Terms);
		OpeningParameters.Insert("Date", Object.Date);
		OpeningParameters.Insert("Ref", Object.Ref);
		OpeningParameters.Insert("Warehouse", Object.Warehouse);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		OpeningParameters.Insert("Organization", Object.Organization);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
	EndIf;
	
	If EventName = "Write_InvoiceIssued"
		And (Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID
			Or Parameter.Property("ListOfGrounds") And Parameter.ListOfGrounds.FindByValue(Object.Ref) <> Undefined) Then
		UpdateTextDocumentsBasedOn();
	EndIf;
	
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	NotificationProcessingLocalization(EventName, Parameter, Source);
	
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
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.SaleAdjustment.Form.ChoiceFormOfCorrectedDocument" Then
		
		ProcessingSelectionOfDocumentBeingCorrected(ValueSelected);
	
	ElsIf TypeOf(ValueSelected) = Type("DocumentRef.SourceDocument") Then
		
		ProcessingSelectionOfBaseDocumentClient(ValueSelected);
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		
		UpdateTextDocumentsBasedOn();
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		
		UpdateTextDocumentsBasedOn();
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ClearMessages();
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			Modified = True;
			FillPropertyValues(Object, ValueSelected);
			UpdateTextDocumentsBasedOn();
		EndIf;
	
	ElsIf ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SalesClient.ProcessingUnitSelection(AdjustmentTable, Items.AdjustmentTable.SelectedRows, ValueSelected);
		
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
	Notify("Write_AdjustingImplementationBeforeEnteringBalances", WriteParameters, Object.Ref);
	
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
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
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	If Not ValueIsFilled(Object.Ref) Then
		FillInCostAccountingAttribute();
	EndIf;

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	

EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)

	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);

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

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	ClearMessages();
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ClearMessages();
	ContractOnChangeServer();
	UpdateServiceFieldsOfValueTable(ThisObject);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInVATTaxationATServer();

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
Procedure TermsOnChange(Item)

	ClearMessages();
	
	Terms = Object.Terms;
	
	If Not ValueIsFilled (Object.Terms) Then
		Return;
	EndIf;
	
	ContractBeforeModifications = Object.Contract;
	TermsOnChangeServer();
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	FillOperationSelectionList();
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                          = Item;
	AgreementSelectionParameters.Partner                          = Object.Partner;
	AgreementSelectionParameters.Document                         = Object.Terms;
	AgreementSelectionParameters.DocumentDate                    = Object.Date;
	AgreementSelectionParameters.FormDataStructure             = Object;
	AgreementSelectionParameters.ContractsAreUsed = ContractsAreUsed;
		
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);

EndProcedure

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
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
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
Procedure IncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);	
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	ClearMessages();
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure OperationOnChange(Item)
	
	OperationWhenChangingOnServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisObject, Item, StandardProcessing, Notification);
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	RegistrationParameters = InvoiceRegistrationParameters();
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(ThisObject,
																		FormattedStringURL,
																		StandardProcessing,
																		RegistrationParameters.Issued);
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(ThisObject,
																		FormattedStringURL,
																		StandardProcessing,
																		RegistrationParameters.Received);
	
	TextDocumentsBasedOnURLProcessingLocalization(FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject, Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

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

&AtClient
Procedure SubjectToExciseOnChange(Item)
	ExcisableGoodsAccountingClientServer.ConfigureProductionDivisionField(ThisObject);
	Return; // Not used in TM
EndProcedure

&AtClient
Procedure FeaturesOfReflectionONChange(Item)
	FeaturesOfReflectionOnChangeATServer();
EndProcedure

&AtClient
Procedure MoveDocumentToNewOrderOfReflectionInAccountingClick(Item)
	MoveDocumentToNewOrderOfAccountingAtServer();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAdjustmentTable

&AtClient
Procedure AdjustmentTableOnChange(Item)
	
	PostingOption = Undefined;
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	If CurrentData <> Undefined And CurrentData.LineNumber <> AdjustmentTable.IndexOf(CurrentData)+1 Then
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
				Or CurrentData.AmountWithVATAfter > 0
				Or CurrentData.VATAmountAfter > 0);
		
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
			Or (NumberOfPackages_Discrepancy <> 0 And PreviousNumberOfPackagesDiscrepancy = 0)
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
		
		SetReflectionOptionForString(CurrentData,
			OtherAssetServiceAdjustment, LastPeriodAdjustment, Object.SaleAdjustment2_5);
		
	EndIf;
	
	If CurrentData <> Undefined Then
		If ValueIsFilled(CurrentData.CostDefiningMethod) Then
			If (CurrentData.VATRate = CurrentData.VATRateAfter
				And CurrentData.PostingOption = PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"))
				Or (CurrentData.VATRate <> CurrentData.VATRateAfter
				And CurrentData.OptionToReflectWriteOff = PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs")) Then
				CurrentData.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.EmptyRef");
				CurrentData.Cost_ = 0;
				CostExcludingVAT_ = 0;
				CostLocal = 0;
				CDCost = 0;
				TDCost = 0;
				CostPriceKind = PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
				DateOfCostFillingByPriceType = Date('00010101');
			EndIf;
		EndIf;
	EndIf;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure AdjustmentTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If ItemToLock(Field) Then
		
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("OwnerForm",        UUID);
			
			Notify("EditSet", NotificationParameter1, ThisObject);
			
		EndIf;
		
	ElsIf Field = Items.AdjustmentTableProductsInSet Then
		
		ShowValue(Undefined, Items.AdjustmentTable.CurrentData.ProductsInSet);
		
	ElsIf Field = Items.AdjustmentTableMethodForDeterminingTheCostOfALine Then
		
		FillInCostInTable();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentTableOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.AdjustmentTable, ThisObject);
	CurrentRow = Items.AdjustmentTable.CurrentData;
	FillPropertyValues(PreviousRowDetails, CurrentRow);

	SalesClient.ProductItemLineAtBeginningOfEditing(ThisObject, "AdjustmentTable", CurrentRow, NewRow, Copy);
	
	If NewRow And Not Copy Then
		
		If Not WarehouseGroup_ Then
			CurrentRow.Warehouse = Object.Warehouse;
		EndIf;
		
		CurrentRow.Department = Object.Department;
		
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "AdjustmentTable");
		
		If OtherAssetServiceAdjustment 
			And Object.VATTaxation <> PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT") Then
			CurrentRow.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
		EndIf;
		
		CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromCurrentDocument");
		SetCostPresentationInLine(CurrentRow);
		
	EndIf;
	
	If NewRow Or Copy Then
		UpdateServiceFieldsOfValueTable(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentTableAfterDeleteRow(Item)
	
	UpdateServiceFieldsOfValueTable(ThisObject);
	CalculateFinalImplementationIndicators(ThisObject);
	AdjustmentTableAfterDeleteRowServer();
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure AdjustmentTableOnActivateCell(Item)
	
	TableRow = Items.AdjustmentTable.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem = Undefined Then
		
		Return;
		
	ElsIf Item.CurrentItem.Name = "AdjustmentTablePartnerProducts" Then

		CurrentData = Items.AdjustmentTable.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.AdjustmentTablePartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.AdjustmentTablePartnerProducts.ChoiceParameters, CurrentData);
			
	ElsIf Item.CurrentItem.Name = "AdjustmentTableCCDNumber" Then
			PurchasesClient.FillInListOfCCDNumberSelection(
			Items.AdjustmentTable.CurrentData, 
			Items.AdjustmentTableCCDNumber.ChoiceList);
			
	ElsIf Item.CurrentItem = Items.AdjustmentTablePostingOption Then
		
		ChoiceList = GetReflectionOptionsAvailableForString(TableRow,
			OtherAssetServiceAdjustment, LastPeriodAdjustment, Object.SaleAdjustment2_5);
		Items.AdjustmentTablePostingOption.ChoiceList.LoadValues(ChoiceList);
		
	ElsIf Item.CurrentItem <> Undefined
		And Item.CurrentItem = Items.AdjustmentTableOptionToReflectWriteOff Then
		
		ChoiceList = GetAvailableOptionsForReflectingWriteOffForLine(TableRow,
			OtherAssetServiceAdjustment, LastPeriodAdjustment, Object.SaleAdjustment2_5);
		Items.AdjustmentTableOptionToReflectWriteOff.ChoiceList.LoadValues(ChoiceList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentTableBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)

	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "AdjustmentTable", Cancel, True);
	EndIf;

EndProcedure

&AtClient
Procedure AdjustmentTableBeforeDeleteRow(Item, Cancel)
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "AdjustmentTable", Cancel);
	ProcessingOfTabularFormsClient.CacheCurLine(Items.AdjustmentTable, ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateFinalImplementationIndicators(ThisObject);
	CurrentData = Items.AdjustmentTable.CurrentData;
	If Not CancelEdit Then
		
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.AdjustmentTable, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
		
	EndIf;
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.AdjustmentTable, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("TableOfAdjustmentsAtEndOfEditingForServerCall", 0.5, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentTableProductsOnChange(Item)

	ClearMessages();
	
	SeriesSpecificationParameters.NameTSGoods = "Goods";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	Suffix = "After";
	
	WarehouseParameters = New Structure;
	WarehouseParameters.Insert("CheckDate", Object.Date);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.Suffix = Suffix;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.Suffix = Suffix;
	ParametersFillInVATRate.Partner = Object.Partner;
	ParametersFillInVATRate.Terms = Object.Terms;
	ParametersFillInVATRate.FillInPriceView = True;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffixByPriceType", ParametersFillInVATRate);
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	
	StructureOfActions.Insert("FillInVATRateSuffix", ParametersFillInVATRate);
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSuffixAmount", 
			New Structure ("Suffix, QuantityName", 
								Suffix, 
								?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count")));
	
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));
	StructureOfActions.Insert("FillInOrderWarehouseAttribute", WarehouseParameters);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "AdjustmentTable"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
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
		
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
		StructureOfActions,
		ThisObject);
		
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.AdjustmentKind,
		Object.Organization,
		Object.Department);
		
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	SetWhetherWarehouseIsFull();
	CalculateFinalImplementationIndicators(ThisObject);
	
	SeriesSpecificationParameters.NameTSGoods = "AdjustmentTable";
	SeriesSpecificationParameters.TSSeriesName = "AdjustmentTable";

EndProcedure

&AtClient
Procedure AdjustmentTablePartnerProductsOnChange(Item)
	
	SeriesSpecificationParameters.NameTSGoods = "Goods";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	Suffix = "After";
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.Suffix = Suffix;
	
	WarehouseParameters = New Structure;
	WarehouseParameters.Insert("CheckDate", Object.Date);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	If Not OtherAssetServiceAdjustment Then
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", Suffix);
	EndIf;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffix", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSuffixAmount", 
			New Structure("Suffix,QuantityName",
				Suffix,
				?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count")));
				
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));
	StructureOfActions.Insert("FillInOrderWarehouseAttribute", WarehouseParameters);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "AdjustmentTable"));
		
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
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
		
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
		StructureOfActions,
		ThisObject);
		
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.AdjustmentKind,
		Object.Organization,
		Object.Department);
	
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalImplementationIndicators(ThisObject);
	SetWhetherWarehouseIsFull();
	
	SeriesSpecificationParameters.NameTSGoods = "AdjustmentTable";
	SeriesSpecificationParameters.TSSeriesName = "AdjustmentTable";
	
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

&AtClient
Procedure AdjustmentTableCharacteristicOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	Suffix = "After";
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.Suffix = Suffix;
	ParametersFillInVATRate.Partner = Object.Partner;
	ParametersFillInVATRate.Terms = Object.Terms;
	ParametersFillInVATRate.FillInPriceView = True;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffixByPriceType", ParametersFillInVATRate);
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSuffixAmount", 
			New Structure("Suffix,QuantityName",
				Suffix,
				?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count")));
	
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "AdjustmentTable"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalImplementationIndicators(ThisObject);

EndProcedure

&AtClient
Procedure AdjustmentTablePackageOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	Suffix = "After";
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.Suffix = Suffix;
	ParametersFillInVATRate.Partner = Object.Partner;
	ParametersFillInVATRate.Terms = Object.Terms;
	ParametersFillInVATRate.FillInPriceView = True;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffixByPriceType", ParametersFillInVATRate);
	
	If Not OtherAssetServiceAdjustment Then
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", Suffix);
	EndIf;

	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
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
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableNumberOfPackagesOnChange(Item)
	
	ClearMessages();
	
	StructureOfActions = New Structure;
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Warehouse",                       CurrentData.Warehouse);
	CurrentRow.Insert("CCDNumber",                    CurrentData.CCDNumber);
	CurrentRow.Insert("AccountingForTheRNPTIsMaintained",           CurrentData.AccountingForTheRNPTIsMaintained);
	CurrentRow.Insert("Products",                CurrentData.Products);
	CurrentRow.Insert("Package",                    CurrentData.Package);
	If OtherAssetServiceAdjustment Then
		CurrentRow.Insert("Count",              ?(CurrentData.Count <> 0, CurrentData.Count, 1));
		CurrentRow.Insert("NumberOfPackages",      ?(CurrentData.NumberOfPackages <> 0, CurrentData.NumberOfPackages, 1));
		CurrentRow.Insert("QuantityByGBRN",        ?(CurrentData.QuantityByGBRN <> 0, CurrentData.QuantityByGBRN, 1));
	Else
		CurrentRow.Insert("Count",              CurrentData.Count);
		CurrentRow.Insert("NumberOfPackages",      CurrentData.NumberOfPackages);
		CurrentRow.Insert("QuantityByGBRN",        CurrentData.QuantityByGBRN);
		CurrentRow.Insert("QuantityAfter",         CurrentData.QuantityAfter);
		CurrentRow.Insert("NumberOfPackagesAfter", CurrentData.NumberOfPackagesAfter);
		CurrentRow.Insert("QuantityAccordingToRNPTAfter",   CurrentData.QuantityAccordingToRNPTAfter);
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions,
			"Warehouse",
			True,
			"After");
	EndIf;
	CurrentRow.Insert("Price",                        CurrentData.Price);
	CurrentRow.Insert("Sum",                       CurrentData.Sum);
	CurrentRow.Insert("VATRate",                   CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",                    CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",                   CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountARAP",         CurrentData.AmountARAP);
	CurrentRow.Insert("AmountExcludingVATCompl",             CurrentData.AmountExcludingVATCompl);
	CurrentRow.Insert("AmountExcludingVATMan",              CurrentData.AmountExcludingVATMan);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.Partner = Object.Partner;
	ParametersFillInVATRate.Terms = Object.Terms;
	ParametersFillInVATRate.FillInPriceView = True;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If CurrentData.NumberOfPackages = 0 
		And OtherAssetServiceAdjustment Then
		FillPropertyValues(CurrentData, CurrentRow, , "Count,NumberOfPackages");
		CurrentData.Count = 0;
	Else
		FillPropertyValues(CurrentData, CurrentRow);
	EndIf;
	
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableNumberOfPackagesAfterOnChange(Item)
	
	StructureOfActions = New Structure;
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Warehouse",                       CurrentData.Warehouse);
	CurrentRow.Insert("Products",                CurrentData.Products);
	CurrentRow.Insert("Package",                    CurrentData.Package);
	CurrentRow.Insert("AccountingForTheRNPTIsMaintained",           CurrentData.AccountingForTheRNPTIsMaintained);
	CurrentRow.Insert("CCDNumber",                    CurrentData.CCDNumber);
	If OtherAssetServiceAdjustment Then
		CurrentRow.Insert("QuantityAfter",         ?(CurrentData.QuantityAfter <> 0, CurrentData.QuantityAfter, 1));
		CurrentRow.Insert("NumberOfPackagesAfter", ?(CurrentData.NumberOfPackagesAfter <> 0, CurrentData.NumberOfPackagesAfter, 1));
		CurrentRow.Insert("QuantityAccordingToRNPTAfter",   ?(CurrentData.QuantityAccordingToRNPTAfter <> 0, CurrentData.QuantityAccordingToRNPTAfter, 1));
	Else
		CurrentRow.Insert("Count",              CurrentData.Count);
		CurrentRow.Insert("NumberOfPackages",      CurrentData.NumberOfPackages);
		CurrentRow.Insert("QuantityByGBRN",        CurrentData.QuantityByGBRN);
		CurrentRow.Insert("QuantityAfter",         CurrentData.QuantityAfter);
		CurrentRow.Insert("NumberOfPackagesAfter", CurrentData.NumberOfPackagesAfter);
		CurrentRow.Insert("QuantityAccordingToRNPTAfter",   CurrentData.QuantityAccordingToRNPTAfter);
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions,
			"Warehouse",
			True);
	EndIf;
	CurrentRow.Insert("PriceAfter",                   CurrentData.PriceAfter);
	CurrentRow.Insert("AmountAfter",                  CurrentData.AmountAfter);
	CurrentRow.Insert("VATRateAfter",              CurrentData.VATRateAfter);
	CurrentRow.Insert("VATAmountAfter",               CurrentData.VATAmountAfter);
	CurrentRow.Insert("AmountWithVATAfter",              CurrentData.AmountWithVATAfter);
	CurrentRow.Insert("AmountOfSettlementsAfter",    CurrentData.AmountOfSettlementsAfter);
	CurrentRow.Insert("VATExclusiveAmountLocalAfter",        CurrentData.VATExclusiveAmountLocalAfter);
	CurrentRow.Insert("VATExclusiveAmountManAfter",         CurrentData.VATExclusiveAmountManAfter);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject, "After");
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.Suffix = "After";
	ParametersFillInVATRate.Partner = Object.Partner;
	ParametersFillInVATRate.Terms = Object.Terms;
	ParametersFillInVATRate.FillInPriceView = True;
	StructureOfActions.Insert("FillInVATRateSuffixByPriceType", ParametersFillInVATRate);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If CurrentData.NumberOfPackagesAfter = 0
		And OtherAssetServiceAdjustment Then
		FillPropertyValues(CurrentData, CurrentRow, , "QuantityAfter,NumberOfPackagesAfter");
		CurrentData.QuantityAfter = 0;
	Else
		FillPropertyValues(CurrentData, CurrentRow);
	EndIf;
	
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableCountOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",                CurrentData.Products);
	CurrentRow.Insert("Package",                    CurrentData.Package);
	CurrentRow.Insert("Count",                  ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages",          ?(CurrentData.NumberOfPackages <> 0, CurrentData.NumberOfPackages, 1));
	CurrentRow.Insert("Price",                        CurrentData.Price);
	CurrentRow.Insert("Sum",                       CurrentData.Sum);
	CurrentRow.Insert("VATRate",                   CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",                    CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",                   CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountExcludingVATCompl",             CurrentData.AmountExcludingVATCompl);
	CurrentRow.Insert("AmountExcludingVATMan",              CurrentData.AmountExcludingVATMan);
	CurrentRow.Insert("AmountARAP",         CurrentData.AmountARAP);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If CurrentData.Count = 0 Then
		FillPropertyValues(CurrentData, CurrentRow, , "Count,NumberOfPackages");
	ElsIf CurrentData.NumberOfPackages = 0 Then
		FillPropertyValues(CurrentData, CurrentRow, , "NumberOfPackages");
	Else
		FillPropertyValues(CurrentData, CurrentRow);
	EndIf;
	CalculateFinalImplementationIndicators(ThisObject);

EndProcedure

&AtClient
Procedure AdjustmentTableQuantityAfterOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",            CurrentData.Products);
	CurrentRow.Insert("Package",                CurrentData.Package);
	CurrentRow.Insert("QuantityAfter",         ?(CurrentData.QuantityAfter <> 0, CurrentData.QuantityAfter, 1));
	CurrentRow.Insert("NumberOfPackagesAfter", ?(CurrentData.NumberOfPackagesAfter <> 0, CurrentData.NumberOfPackagesAfter, 1));
	CurrentRow.Insert("PriceAfter",               CurrentData.PriceAfter);
	CurrentRow.Insert("AmountAfter",              CurrentData.AmountAfter);
	CurrentRow.Insert("VATRateAfter",          CurrentData.VATRateAfter);
	CurrentRow.Insert("VATAmountAfter",           CurrentData.VATAmountAfter);
	CurrentRow.Insert("AmountWithVATAfter",          CurrentData.AmountWithVATAfter);
	CurrentRow.Insert("AmountOfSettlementsAfter", CurrentData.AmountOfSettlementsAfter);
	CurrentRow.Insert("VATExclusiveAmountLocalAfter",    CurrentData.VATExclusiveAmountLocalAfter);
	CurrentRow.Insert("VATExclusiveAmountManAfter",     CurrentData.VATExclusiveAmountManAfter);

	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisObject, "After");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If CurrentData.QuantityAfter = 0 Then
		FillPropertyValues(CurrentData, CurrentRow, , "QuantityAfter,NumberOfPackagesAfter");
	ElsIf CurrentData.NumberOfPackagesAfter = 0 Then
		FillPropertyValues(CurrentData, CurrentRow, , "NumberOfPackagesAfter");
	Else
		FillPropertyValues(CurrentData, CurrentRow);
	EndIf;
	CalculateFinalImplementationIndicators(ThisObject);

EndProcedure

&AtClient
Procedure AdjustmentTablePriceOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",                CurrentData.Products);
	CurrentRow.Insert("Package",                    CurrentData.Package);
	CurrentRow.Insert("Count",                  ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages",          ?(CurrentData.NumberOfPackages <> 0, CurrentData.NumberOfPackages, 1));
	CurrentRow.Insert("Price",                        CurrentData.Price);
	CurrentRow.Insert("Sum",                       CurrentData.Sum);
	CurrentRow.Insert("VATRate",                   CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",                    CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",                   CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountARAP",         CurrentData.AmountARAP);
	CurrentRow.Insert("AmountExcludingVATCompl",             CurrentData.AmountExcludingVATCompl);
	CurrentRow.Insert("AmountExcludingVATMan",              CurrentData.AmountExcludingVATMan);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	LocalDataForRecalculatingAmount = GetParametersForRecalculatingLocalAmount(ThisObject);
	DataForRecalculatingManSAmount = GetParametersForRecalculatingManSAmount(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("RecalculateAmountWithoutVATLocal", LocalDataForRecalculatingAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVATMan", DataForRecalculatingManSAmount);
	
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	FillPropertyValues(CurrentData, CurrentRow, , "Count,NumberOfPackages");

	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTablePriceAfterOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	Suffix = "After";
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",            CurrentData.Products);
	CurrentRow.Insert("Package",                CurrentData.Package);
	CurrentRow.Insert("QuantityAfter",         ?(CurrentData.QuantityAfter <> 0, CurrentData.QuantityAfter, 1));
	CurrentRow.Insert("NumberOfPackagesAfter", ?(CurrentData.NumberOfPackagesAfter <> 0, CurrentData.NumberOfPackagesAfter, 1));
	CurrentRow.Insert("PriceAfter",               CurrentData.PriceAfter);
	CurrentRow.Insert("AmountAfter",              CurrentData.AmountAfter);
	CurrentRow.Insert("VATRateAfter",          CurrentData.VATRateAfter);
	CurrentRow.Insert("VATAmountAfter",           CurrentData.VATAmountAfter);
	CurrentRow.Insert("AmountWithVATAfter",          CurrentData.AmountWithVATAfter);
	CurrentRow.Insert("AmountOfSettlementsAfter",CurrentData.AmountOfSettlementsAfter);
	CurrentRow.Insert("VATExclusiveAmountLocalAfter",    CurrentData.VATExclusiveAmountLocalAfter);
	CurrentRow.Insert("VATExclusiveAmountManAfter",     CurrentData.VATExclusiveAmountManAfter);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);

	LocalDataForRecalculatingAmount = GetParametersForRecalculatingLocalAmount(ThisObject, Suffix);
	DataForRecalculatingManSAmount = GetParametersForRecalculatingManSAmount(ThisObject, Suffix);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSuffixAmount", 
			New Structure("Suffix,QuantityName",
				Suffix,
				?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count")));
	
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	StructureOfActions.Insert("RecalculateAmountWithoutVATLocalSuffix", LocalDataForRecalculatingAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVATManSuffix", DataForRecalculatingManSAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	FillPropertyValues(CurrentData, CurrentRow, , "QuantityAfter,NumberOfPackagesAfter");

	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableSumOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",        CurrentData.Products);
	CurrentRow.Insert("Package",            CurrentData.Package);
	CurrentRow.Insert("Count",          ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages",  ?(CurrentData.NumberOfPackages <> 0, CurrentData.NumberOfPackages, 1));
	CurrentRow.Insert("Price",                CurrentData.Price);
	CurrentRow.Insert("Sum",               CurrentData.Sum);
	CurrentRow.Insert("VATRate",           CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",            CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",           CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountARAP", CurrentData.AmountARAP);
	CurrentRow.Insert("AmountExcludingVATCompl",     CurrentData.AmountExcludingVATCompl);
	CurrentRow.Insert("AmountExcludingVATMan",      CurrentData.AmountExcludingVATMan);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	LocalDataForRecalculatingAmount = GetParametersForRecalculatingLocalAmount(ThisObject);
	DataForRecalculatingManSAmount = GetParametersForRecalculatingManSAmount(ThisObject);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("RecalculateAmountWithoutVATLocal", LocalDataForRecalculatingAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVATMan", DataForRecalculatingManSAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	FillPropertyValues(CurrentData, CurrentRow, , "Count,NumberOfPackages");
	
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableAmountAfterOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",        CurrentData.Products);
	CurrentRow.Insert("Package",            CurrentData.Package);
	CurrentRow.Insert("Count",          ?(CurrentData.QuantityAfter <> 0, CurrentData.QuantityAfter, 1));
	CurrentRow.Insert("NumberOfPackages",  ?(CurrentData.NumberOfPackagesAfter <> 0, CurrentData.NumberOfPackagesAfter, 1));
	CurrentRow.Insert("Price",                CurrentData.PriceAfter);
	CurrentRow.Insert("Sum",               CurrentData.AmountAfter);
	CurrentRow.Insert("VATRate",           CurrentData.VATRateAfter);
	CurrentRow.Insert("VATAmount",            CurrentData.VATAmountAfter);
	CurrentRow.Insert("AmountIncludingVAT",           CurrentData.AmountWithVATAfter);
	CurrentRow.Insert("AmountARAP", CurrentData.AmountOfSettlementsAfter);
	CurrentRow.Insert("AmountExcludingVATCompl",     CurrentData.VATExclusiveAmountLocalAfter);
	CurrentRow.Insert("AmountExcludingVATMan",      CurrentData.VATExclusiveAmountManAfter);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	LocalDataForRecalculatingAmount = GetParametersForRecalculatingLocalAmount(ThisObject);
	DataForRecalculatingManSAmount = GetParametersForRecalculatingManSAmount(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("RecalculateAmountWithoutVATLocal", LocalDataForRecalculatingAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVATMan", DataForRecalculatingManSAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.PriceAfter = CurrentRow.Price;
	CurrentData.AmountAfter = CurrentRow.Sum;
	CurrentData.VATRateAfter = CurrentRow.VATRate;
	CurrentData.VATAmountAfter = CurrentRow.VATAmount;
	CurrentData.AmountWithVATAfter = CurrentRow.AmountIncludingVAT;
	CurrentData.AmountOfSettlementsAfter = CurrentRow.AmountARAP;
	CurrentData.VATExclusiveAmountLocalAfter = CurrentRow.AmountExcludingVATCompl;
	CurrentData.VATExclusiveAmountManAfter = CurrentRow.AmountExcludingVATMan;
	
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableVATAmountOnChange(Item)
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalImplementationIndicators(ThisObject);
EndProcedure

&AtClient
Procedure AdjustmentTableVATAmountAfterOnChange(Item)
	CurrentRow = Items.AdjustmentTable.CurrentData;
	Suffix = "After";
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalImplementationIndicators(ThisObject);
EndProcedure

&AtClient
Procedure AdjustmentTableVATRateOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",                CurrentData.Products);
	CurrentRow.Insert("Package",                    CurrentData.Package);
	CurrentRow.Insert("Count",                  ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages",          ?(CurrentData.NumberOfPackages <> 0, CurrentData.NumberOfPackages, 1));
	CurrentRow.Insert("Price",                        CurrentData.Price);
	CurrentRow.Insert("Sum",                       CurrentData.Sum);
	CurrentRow.Insert("VATRate",                   CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",                    CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",                   CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountARAP",         CurrentData.AmountARAP);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	FillPropertyValues(CurrentData, CurrentRow, , "Count,NumberOfPackages");
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableVATRateAfterOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",       CurrentData.Products);
	CurrentRow.Insert("Package",           CurrentData.Package);
	CurrentRow.Insert("Count",         ?(CurrentData.QuantityAfter <> 0, CurrentData.QuantityAfter, 1));
	CurrentRow.Insert("NumberOfPackages", ?(CurrentData.NumberOfPackagesAfter <> 0, CurrentData.NumberOfPackagesAfter, 1));
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
	
	CurrentData.PriceAfter = CurrentRow.Price;
	CurrentData.AmountAfter = CurrentRow.Sum;
	CurrentData.VATRateAfter = CurrentRow.VATRate;
	CurrentData.VATAmountAfter = CurrentRow.VATAmount;
	CurrentData.AmountWithVATAfter = CurrentRow.AmountIncludingVAT;
	CurrentData.AmountOfSettlementsAfter = CurrentRow.AmountARAP;
	
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentTableAmountExcludingVATComplOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	If LocalAccountingCurrency = ManagementAccountingCurrency Then
		CurrentData.AmountExcludingVATMan = CurrentData.AmountExcludingVATCompl;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentTableVATExclusiveAmountLocalAfterOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	If LocalAccountingCurrency = ManagementAccountingCurrency Then
		CurrentData.VATExclusiveAmountManAfter = CurrentData.VATExclusiveAmountLocalAfter;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentTableAmountExcludingVATManOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	If LocalAccountingCurrency = ManagementAccountingCurrency Then
		CurrentData.AmountExcludingVATCompl = CurrentData.AmountExcludingVATMan;
	EndIf;
	
EndProcedure


&AtClient
Procedure AdjustmentTableVATExclusiveAmountManAfterOnChange(Item)
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	If LocalAccountingCurrency = ManagementAccountingCurrency Then
		CurrentData.VATExclusiveAmountLocalAfter = CurrentData.VATExclusiveAmountManAfter;
	EndIf;
	
EndProcedure


&AtClient
Procedure AdjustmentTableWarehouseOnChange(Item)
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	SeriesSpecificationParameters.NameTSGoods = "Goods";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	SeriesSpecificationParameters.NameTSGoods = "AdjustmentTable";
	SeriesSpecificationParameters.TSSeriesName = "AdjustmentTable";
	
	WhenChangingWarehouseInTablePartServer();
	
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
Procedure AdjustmentTableOptionToReflectWriteOffChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	If TypeOf(ValueSelected) = Type("EnumRef.CreditNoteRecordingOptions") Then
		
		CurrentRow.OptionToReflectWriteOff = ValueSelected;
		
	Else
		
		CurrentRow.OptionToReflectWriteOff = PredefinedValue("Enum.CreditNoteRecordingOptions.EmptyRef");
		
	EndIf;
	
	If CurrentRow <> Undefined Then
		If ValueIsFilled(CurrentRow.CostDefiningMethod)
			And CurrentRow.VATRate <> CurrentRow.VATRateAfter
			And CurrentRow.OptionToReflectWriteOff = PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs") Then
				CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.EmptyRef");
				CurrentRow.Cost_ = 0;
				CurrentRow.CostExcludingVAT_ = 0;
				CurrentRow.CostLocal = 0;
				CurrentRow.CDCost = 0;
				CurrentRow.TDCost = 0;
				CurrentRow.CostPriceKind = PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
				CurrentRow.DateOfCostFillingByPriceType = Date('00010101');
				CurrentRow.MethodForDeterminingTheCostOfALine = "";
		EndIf;
	EndIf;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtClient
Procedure AdjustmentTablePostingOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.AdjustmentTable.CurrentData;
	
	If TypeOf(ValueSelected) = Type("EnumRef.CreditNoteRecordingOptions") Then
		
		CurrentRow.PostingOption = ValueSelected;
		
	Else
		
		CurrentRow.PostingOption = PredefinedValue("Enum.CreditNoteRecordingOptions.EmptyRef");
		
	EndIf;
	
	If CurrentRow <> Undefined Then
		If ValueIsFilled(CurrentRow.CostDefiningMethod)
			And CurrentRow.VATRate = CurrentRow.VATRateAfter
			And CurrentRow.PostingOption = PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs") Then
				CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.EmptyRef");
				CurrentRow.Cost_ = 0;
				CurrentRow.CostExcludingVAT_ = 0;
				CurrentRow.CostLocal = 0;
				CurrentRow.CDCost = 0;
				CurrentRow.TDCost = 0;
				CurrentRow.CostPriceKind = PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
				CurrentRow.DateOfCostFillingByPriceType = Date('00010101');
				CurrentRow.MethodForDeterminingTheCostOfALine = "";
		EndIf;
	EndIf;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtClient
Procedure AdjustmentTableIncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AdjustmentTableIncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure AdjustmentTableMethodForDeterminingTheCostOfALineOnChange(Item)
	
	UpdateInformationWhenCostPriceChanges();
	
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
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure AdjustmentTableCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.AdjustmentTable.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.DocumentCurrency		= Object.Currency;
	AdditionalParameters.FieldNameQuantity	= ?(NumberOfPackagesIsUsed,
													"NumberOfPackagesAfter",
													"QuantityAfter");
	AdditionalParameters.NameOfVATAmountField_		= "VATAmountAfter";
	AdditionalParameters.NameOfAmountFieldWithVAT	= "AmountWithVATAfter";
	AdditionalParameters.BasisOfCostOfAdmission = False;
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	FormParameters = New Structure("CreationParameters", CreationParameters);
	
	OpenForm("Catalog.CCDNumbers.Form.ItemForm",
				FormParameters,
				ThisObject,
				UUID);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckCounterparties(Command)
	
	
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
Procedure PrintDetails(Item)
	
	OpenPrintDetails();
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	ClearMessages();
	
	NumberOfProductsBeforeInsertion = AdjustmentTable.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = AdjustmentTable.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	SetWhetherWarehouseIsFull();
	UpdateTitleOfAdjustmentTable();
	
EndProcedure

&AtClient
Procedure CopyRows(Command)

	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.AdjustmentTable) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.AdjustmentTable.SelectedRows.Count());
	EndIf;

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure SetComposition(Command)
	
	RowSelected = Items.AdjustmentTable.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = AdjustmentTable.FindByID(RowSelected);
	
	If Not ValueIsFilled(CurrentRow.ProductsInSet) Then
		ShowMessageBox(,NStr("vi = 'Chỉ có thể mở thành phần bộ sản phẩm đối với bộ sản phẩm.';
							|ru = 'Открытие состава набора возможно только для набора.';
							|en = 'You can open a set only for the set.'; fa = 'You can open a set only for the set.';
							|it = 'L''apertura della composizione del kit è possibile solo per il kit.';
							|pl = 'Otwarcie składu zestawu jest możliwe tylko dla zestawu.';
							|tr = 'Set kompozisyonunun açılması sadece bir set için mümkündür.'"));
		Return;
	EndIf;
	
	KitParameters = New Structure;
	KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("DialColumns", DialColumns());
	If Items.AdjustmentTable.CurrentItem <> Undefined
		And StrFind(Items.AdjustmentTable.CurrentItem.Name, "After") > 0 Then
		KitParameters.Insert("MatchingColumnNamesForSet", MapNamesOfSetColumns());
	EndIf;
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
	OpeningParameters.Insert("Currency", Object.Currency);
	OpeningParameters.Insert("Partner", Object.Partner);
	OpeningParameters.Insert("Terms", Object.Terms);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("Warehouse", Object.Warehouse);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	OpeningParameters.Insert("Organization", Object.Organization);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document.SaleAdjustment.DocumentForm.Command.OpenSelection");
	
	SeriesSpecificationParameters.NameTSGoods = "Goods";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	Cancel = False;
	If (ToUseTermsOfSales And Not ValueIsFilled(Object.Terms))
		Or Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'điều chỉnh bán hàng trước khi nhập số dư';
																			|ru = 'корректировку реализации до ввода остатков';
																			|en = 'sales adjustment before balance entry'; fa = 'sales adjustment before balance entry';
																			|it = 'correzione di vendita prima dell''inserimento dei saldi';
																			|pl = 'korektę sprzedaży przed wprowadzeniem sald';
																			|tr = 'bakiyeleri girmeden önce satışların düzeltilmesi '"));
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Terms", Object.Terms);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	FormParameters.Insert("ReturnReusablePackage", ToReturnReusablePackage);
	FormParameters.Insert("Currency", Object.Currency);
	FormParameters.Insert("Title", HeaderParameter_);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders", True);
	FormParameters.Insert("Document", Object.Ref);
	If OtherAssetServiceAdjustment Then
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		FormParameters.Insert("FilterByProductType", ArrayOfProductTypes);
		FormParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
	Else
		FormParameters.Insert("Warehouse", Object.Warehouse);
		FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
		FormParameters.Insert("HideExcisableGoods", Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToUTII"));
		FormParameters.Insert("DisplayTheHideExcisableGoodsFlag", Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToUTII"));
		FormParameters.Insert("HideManualDiscounts", True);
		FormParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	EndIf;
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
	
	SeriesSpecificationParameters.NameTSGoods = "AdjustmentTable";
	SeriesSpecificationParameters.TSSeriesName = "AdjustmentTable";
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)
	
	ClearMessages();
	
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
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(ObjectStructure, "AdjustmentTable", TabularSectionPresentation) Then
		
		PricesCalculated = FillThePricesByTermsOfSalesServer();
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	EndIf;
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceType(Command)

	ClearMessages();
	
	ObjectStructure = New Structure;
	ObjectStructure.Insert("Currency", Object.Currency);
	ObjectStructure.Insert("AdjustmentTable", AdjustmentTable);
	TabularSectionPresentation = NStr("vi = 'Bảng điều chỉnh';
										|ru = 'Таблица корректировки';
										|en = 'Adjustment table'; fa = 'جدول تعدیل';
										|it = 'Tabella di correzione';
										|pl = 'Tabela korekty';
										|tr = 'Düzeltme tablosu'");
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(ObjectStructure, "AdjustmentTable", TabularSectionPresentation) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("FillInPricesOfSelectedRowsByPriceTypeCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseWhileSellingToCustomers = True;
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
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

		OpenForm("Catalog.Warehouses.ChoiceForm", ParametersStructure, ThisObject,,,, New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
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

&AtServer
Procedure AdjustmentTableAfterDeleteRowServer()
	
	WhenChangingWarehouseInTablePartServer();
	FormEvents.WhenChangingElement(ThisObject, "AdjustmentTable");

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//

	VATAccountingERP.EstablishConditionalAppearanceOfHSCodeForTaxationOfSales(ThisObject, "AdjustmentTable");
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableFEACNCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AdjustmentKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.ErrorCorrection;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject,
		"AdjustmentTableVATRate",
		"AdjustmentTableVATAmount",
		"AdjustmentTableAmountIncludingVAT");
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject,
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
	
	WarehousesServer.EstablishConditionalAppearanceOfVTCHDivision(ThisObject, "AdjustmentTable", True, "");

	//
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.NameOfWarehouseInputField = Items.AdjustmentTableWarehouse.Name;
	ConditionalDesignParameters.NameOfItemTypeField = "AdjustmentTable.ItemsType";
	
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTablePostingOption.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
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
	ItemField.Field = New DataCompositionField(Items.AdjustmentTablePostingOption.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter =  FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.QuantityAfter");
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
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
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableOptionToReflectWriteOff.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.OptionToReflectWriteOff");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	SetConditionalRegistrationOfPriceAmounts("Sum","Count","AmountAfter");
	SetConditionalRegistrationOfPriceAmounts("Price","Count","PriceAfter");
	SetConditionalRegistrationOfPriceAmounts("AmountAfter","QuantityAfter", "Sum");
	SetConditionalRegistrationOfPriceAmounts("PriceAfter","QuantityAfter", "Price");
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableVATRate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ToReturnReusablePackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject,
														"SeriesAlwaysWHGoods",
														"AdjustmentTableSeries",
														"AdjustmentTable.BatchesIndicationStatus",
														"AdjustmentTable.ItemsType");

	//
	
	SetsServer.SetConditionalAppearance(ThisObject, "AdjustmentTable");
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableNumberOfPackages.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
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
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
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
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber		= "AdjustmentTableCCDNumber";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToCCD	= "AdjustmentTable.TheRecordsAreKeptByCCD";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "AdjustmentTableCCDNumberCountryOfOrigin";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.PathToDocumentDateField				= "Object.Date";
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber				= "AdjustmentTableCCDNumber";
	ConditionalDesignParameters.NameOfInputFieldCountryOfOrigin	= "AdjustmentTableCCDNumberCountryOfOrigin";
	ConditionalDesignParameters.PathToCCDNumberField					= "AdjustmentTable.CCDNumber";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT			= "AdjustmentTable.AccountingForTheRNPTIsMaintained";
	ConditionalDesignParameters.PathToItemTypeField			= "AdjustmentTable.ItemsType";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableCCDNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableCCDNumberCountryOfOrigin.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableQuantityByGBRN.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableQuantityAccordingToRNPTAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.PostingOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.CreditNoteRecordingOptions.RecordInOtherIncome;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.QuantityAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.Count");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.NumberOfPackagesAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.NumberOfPackages");
	
	VATSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	VATSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = VATSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	
	ItemFilter = VATSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = VATSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT();
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT	= "AdjustmentTableQuantityByGBRN";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA	= "AdjustmentTableItemUnitOfFEA";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT		= "AdjustmentTable.AccountingForTheRNPTIsMaintained";
	ConditionalDesignParameters.PathToItemTypeField		= "AdjustmentTable.ItemsType";
	ConditionalDesignParameters.PathToCCDNumberTypeField			= "AdjustmentTable.CCDNumberType";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
	
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT();
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT	= "AdjustmentTableQuantityAccordingToRNPTAfter";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA	= "AdjustmentTableProductUnitOfMeasurementOfFEAAfter";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT		= "AdjustmentTable.AccountingForTheRNPTIsMaintained";
	ConditionalDesignParameters.PathToItemTypeField		= "AdjustmentTable.ItemsType";
	ConditionalDesignParameters.PathToCCDNumberTypeField			= "AdjustmentTable.CCDNumberType";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableQuantityByGBRN.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
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
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
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
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableItemUnitOfFEA.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableProductUnitOfMeasurementOfFEAAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.QuantityAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.Count");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.NumberOfPackagesAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.NumberOfPackages");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableMethodForDeterminingTheCostOfALine.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.QuantityAfter");
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	
	FilterGroup4 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup4.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	
	ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.PostingOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs");

	FilterGroup5 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup5.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup5.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	
	ItemFilter = FilterGroup5.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.OptionToReflectWriteOff");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs");

	Item.Appearance.SetParameterValue("Enabled", False);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<khi điều chỉnh hàng hóa/công việc trừ số lượng không ghi giảm>';
													|ru = '<при корректировке товара/работы в минус по количеству без списания>';
													|en = '<when adjusting goods/works in minus quantity without write-off>'; fa = '<when adjusting goods/works in minus quantity without write-off>';
													|it = '<alla correzione della merce/lavoro in meno per quantità senza storno>';
													|pl = '<przy korekcie towaru/pracy na minus według ilości bez rozchodu>';
													|tr = '<malların/işin miktar olarak eksik düzenlenmesi durumunda, herhangi bir gider yazma yapılmaksızın>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableContent.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với dịch vụ và công việc>';
													|ru = '<для услуг и работ>';
													|en = '<for services and works>'; fa = '<for services and works>';
													|it = '<per servizi e lavori>';
													|pl = '<dla usług i prac>';
													|tr = '<iş ve hizmetler için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
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
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
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
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
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
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
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
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.VATRateAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
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
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableMethodForDeterminingTheCostOfALine.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseCostAccounting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountARAP.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountARAP");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountOfSettlementsAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.Sum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountOfSettlementsAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountOfSettlementsAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountARAP");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountAfter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountExcludingVATCompl.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountExcludingVATMan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableVATExclusiveAmountLocalAfter.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableVATExclusiveAmountManAfter.Name);
	
	ListOfTaxation = New ValueList();
	ListOfTaxation.LoadValues(VATAccountingERPClientServer.TypesOfTaxationThatHideVATDetails());
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ListOfTaxation;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountExcludingVATCompl.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableVATExclusiveAmountLocalAfter.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LocalAccountingCurrency;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableAmountExcludingVATMan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableVATExclusiveAmountManAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = ManagementAccountingCurrency;

	Item.Appearance.SetParameterValue("Visible", False);
	
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
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
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
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableVATExclusiveAmountLocalAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountExcludingVATCompl");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATExclusiveAmountLocalAfter");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);

	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentTableVATExclusiveAmountManAfter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentTable.AmountExcludingVATMan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("AdjustmentTable.VATExclusiveAmountManAfter");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);
	
EndProcedure

#Region OnChangeAttributes

&AtClient
Procedure TableOfAdjustmentsAtEndOfEditingForServerCall()

	TableOfAdjustmentsAtEndOfEditingOnServer();

EndProcedure

&AtServer
Procedure TableOfAdjustmentsAtEndOfEditingOnServer()

	FormEvents.WhenChangingElement(ThisObject, "AdjustmentTable");

EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()

	Suffix = "After";
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffix", ParametersFillInVATRate);
		
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.Suffix = Suffix;
	ParametersFillInVATRate.Partner = Object.Partner;
	ParametersFillInVATRate.Terms = Object.Terms;
	ParametersFillInVATRate.FillInPriceView = True;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffixByPriceType", ParametersFillInVATRate);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	
	LocalDataForRecalculatingAmount = GetParametersForRecalculatingLocalAmount(ThisObject, Suffix);
	DataForRecalculatingManSAmount = GetParametersForRecalculatingManSAmount(ThisObject, Suffix);
	
	StructureOfActions.Insert("RecalculateAmountWithoutVATLocal", LocalDataForRecalculatingAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVATMan", DataForRecalculatingManSAmount);
	
	StructureOfActions.Insert("RecalculateAmountWithoutVATLocalSuffix", LocalDataForRecalculatingAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVATManSuffix", DataForRecalculatingManSAmount);

	BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions, Undefined);
	
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	If ValueIsFilled(Object.DocumentBasis) Then
		SetPrivilegedMode(True);
		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.SourceDocument") Then
			FillParameters = Documents.SaleAdjustment.ParametersForFillingInSalesVATTaxation(Object);
			If OtherAssetServiceAdjustment Then
				FillParameters.GoodsSales = False;
				FillParameters.ImplementationOfWorksServices = False;
				FillParameters.OtherAssetSale = True;
			EndIf;
		EndIf;
		SetPrivilegedMode(False);
		VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
		VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	EndIf;
	
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
	
	CalculateFinalImplementationIndicators(ThisObject);
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	UseCostAccounting = CalculationOfCostCached.CostCalculationIsPossible(Object.Date);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	AdjustTaxBaseOfPreviousPeriod = Not SaleAdjustmentLocalization.NotAdjustTaxBaseOfPreviousPeriod(Object.Organization, DocumentDate);
	
	AdjustmentOfPreviousPeriodBeforeChange = LastPeriodAdjustment;
	LastPeriodAdjustment = BegOfYear(DocumentDate) > BegOfYear(ReferenceDocumentDateForCertificate);
	
	SetVisibilityOfElementsByBase();
	
	If Object.SaleAdjustment2_5 Then
		
		SaleAdjustmentLocalization.FillInReflectionInAccountingByDefault(ThisObject);
		UpdateReflectionInAccountingByDocumentAttributes();
		SetVisibilityOfItemsByAccountingPolicy();
		UpdateTrackingReflectionHeader();
		
	EndIf;
	
	OptionsForSelection = OptionsForSelectingArticlesAndAnalytics();
	ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.OptionsForSelectingArticlesAndAnalyticsBeforeEnteringBalances(OptionsForSelection);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Date");
	
	SetUpRNPTAccounting();
	
EndProcedure

&AtServer
Procedure OperationWhenChangingOnServer()
	
	UpdateTextDocumentsBasedOn();

	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	If Object.AdjustmentKind <> Enums.BusinessTransactions.ErrorCorrection Then
		Object.CorrectedDocument = Undefined;
	EndIf;
	
	SetPresentationOfFoundationDocument();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	SetVisibilityOfDocumentBeingCorrected();
	UpdatePresentationElementsOfDocumentBeingCorrected();	
		
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
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function GetReflectionOptionsAvailableForString(TableRow, OtherAssetServiceAdjustment, LastPeriodAdjustment, SaleAdjustment2_5)
	
	ChoiceList = New Array();
	
	AddWriteOffToExpenses        = Not SaleAdjustment2_5;
	AddReflectOnOtherIncome = Not SaleAdjustment2_5;
	
	DataByDiscrepancy = GetInformationAboutDiscrepancyInLine(TableRow);
	
	If Not OtherAssetServiceAdjustment And DataByDiscrepancy.NumberOfPackages_Discrepancy > 0 Then
		
		If TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSale"));
		ElsIf TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
			Or TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
			If AddReflectOnOtherIncome Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome"));
			EndIf;
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSale"));
		Else
			If AddReflectOnOtherIncome Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome"));
			EndIf;
			If TableRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount"));
			Else
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock"));
			EndIf;
		EndIf;
		
	ElsIf Not OtherAssetServiceAdjustment And DataByDiscrepancy.NumberOfPackages_Discrepancy < 0 Then
		
		If TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSale"));
		ElsIf TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSale"));
			If AddWriteOffToExpenses Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
			EndIf;
		Else
			If AddWriteOffToExpenses Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
			EndIf;
			
			If TableRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount"));
			Else
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock"));
			EndIf;
		EndIf;
		
	ElsIf OtherAssetServiceAdjustment Then
		
		If LastPeriodAdjustment Then
			
			If DataByDiscrepancy.AmountWithVATDiscrepancy < 0 Or DataByDiscrepancy.VATAmountDiscrepancy < 0 Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
			Else
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome"));
			EndIf;
			
		Else
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome"));
		EndIf;
	
	ElsIf (TableRow.ItemsType <> PredefinedValue("Enum.ItemsTypes.OwnGoods")
		And TableRow.ItemsType <> PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
		Or DataByDiscrepancy.NumberOfPackages_Discrepancy = 0 Then
		
		If DataByDiscrepancy.AmountWithVATDiscrepancy < 0 Or DataByDiscrepancy.VATAmountDiscrepancy < 0 Then
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSale"));
		ElsIf DataByDiscrepancy.AmountWithVATDiscrepancy > 0 Or DataByDiscrepancy.VATAmountDiscrepancy > 0
			Or Not ValueIsFilled(TableRow.ItemsType) Then
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSale"));
		EndIf;
		
	EndIf;
	
	Return ChoiceList;
	
EndFunction

&AtClientAtServerNoContext
Function GetAvailableOptionsForReflectingWriteOffForLine(TableRow, OtherAssetServiceAdjustment,
	LastPeriodAdjustment, SaleAdjustment2_5)
	
	ChoiceList = New Array();
	
	DataByDiscrepancy = GetInformationAboutDiscrepancyInLine(TableRow, True);
	
	If Not OtherAssetServiceAdjustment And DataByDiscrepancy.DivergenceOfVATRate Then
		
		If DataByDiscrepancy.NumberOfPackages_Discrepancy < 0 Then
			
			If TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSale"));
			ElsIf TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSale"));
				If Not SaleAdjustment2_5 Then
					ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
				EndIf;
			Else
				If Not SaleAdjustment2_5 Then
					ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
				EndIf;
				If TableRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
					ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount"));
				Else
					ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock"));
				EndIf;
			EndIf;
			
		EndIf;
	
	ElsIf OtherAssetServiceAdjustment Then
		
		If LastPeriodAdjustment Then
		
			If DataByDiscrepancy.AmountWithVATDiscrepancy < 0 Or DataByDiscrepancy.VATAmountDiscrepancy < 0 Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
			Else
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome"));
			EndIf;
			
		Else
			
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome"));
			
		EndIf;
	
	ElsIf (TableRow.ItemsType <> PredefinedValue("Enum.ItemsTypes.OwnGoods")
		And TableRow.ItemsType <> PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
		Or DataByDiscrepancy.NumberOfPackages_Discrepancy = 0 Then
		
		If DataByDiscrepancy.AmountWithVATDiscrepancy < 0 Or DataByDiscrepancy.VATAmountDiscrepancy < 0 Then
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSale"));
		ElsIf DataByDiscrepancy.AmountWithVATDiscrepancy > 0 Or DataByDiscrepancy.VATAmountDiscrepancy > 0
			Or Not ValueIsFilled(TableRow.ItemsType) Then
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSale"));
		EndIf;
		
	EndIf;
	
	Return ChoiceList;
	
EndFunction

&AtClientAtServerNoContext
Function GetInformationAboutDiscrepancyInLine(CurrentRow, WriteOff = False)
	
	DataByDiscrepancy = New Structure("DivergenceOfVATRate,
		|NumberOfPackages_Discrepancy,
		|AmountWithVATDiscrepancy,
		|VATAmountDiscrepancy");
	
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
Function SetReflectionOptionForString(TableRow, OtherAssetServiceAdjustment, LastPeriodAdjustment, SaleAdjustment2_5)
	
	DivergenceOfVATRate = TableRow.VATRate <> TableRow.VATRateAfter
		And (TableRow.QuantityAfter > 0
			Or TableRow.AmountWithVATAfter > 0
			Or TableRow.VATAmountAfter > 0);
	
	ChoiceList = GetReflectionOptionsAvailableForString(TableRow,
		OtherAssetServiceAdjustment, LastPeriodAdjustment, SaleAdjustment2_5);
	If ChoiceList.Find(TableRow.PostingOption) = Undefined Then
		If ChoiceList.Count() = 1 Then
			TableRow.PostingOption = ChoiceList[0];
		Else
			TableRow.PostingOption = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
		EndIf;
	EndIf;
	
	If DivergenceOfVATRate Then
		ChoiceList = GetAvailableOptionsForReflectingWriteOffForLine(TableRow,
			OtherAssetServiceAdjustment, LastPeriodAdjustment, SaleAdjustment2_5);
		If ChoiceList.Find(TableRow.OptionToReflectWriteOff) = Undefined Then
			If ChoiceList.Count() = 1 Then
				TableRow.OptionToReflectWriteOff = ChoiceList[0];
			Else
				TableRow.OptionToReflectWriteOff = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
			EndIf;
		EndIf;
	Else
		TableRow.OptionToReflectWriteOff = PredefinedValue("Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef");
	EndIf;
	
EndFunction

&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtServer
Procedure FillBaseForPrinting()
	
	If Not BasisChanged Then
		BaseStructure = Documents.SaleAdjustment.StructureOfBaseForPrinting(Object);
		FillPropertyValues(Object, BaseStructure);
	EndIf;
	PrintBasisTable.Load(Documents.SaleAdjustment.PrintBasisTable(Object));
	
EndProcedure

&AtServer
Procedure MoveDocumentToNewOrderOfAccountingAtServer()

	Object.SaleAdjustment2_5 = True;
	
	SetVisibilityOfElementsByAdjustingImplementation2_5();
	UpdateOptionsForReflectingDiscrepancies2_5();
	
	SaleAdjustmentLocalization.FillInReflectionInAccountingByDefault(ThisObject);
	UpdateReflectionInAccountingByDocumentAttributes();
	SetVisibilityOfItemsByAccountingPolicy();
	UpdateTrackingReflectionHeader();

EndProcedure

&AtServer
Procedure FeaturesOfReflectionOnChangeATServer()
	UpdateAttributesOfAccountingDocument();
	UpdateTrackingReflectionHeader();
EndProcedure

#EndRegion

#Region FillType

&AtServer
Function FillThePricesByTermsOfSalesServer()
	
	RowsArray = New Array;
	For Each String In Items.AdjustmentTable.SelectedRows Do
		RowsArray.Add(AdjustmentTable.FindByID(String));
	EndDo;
	
	SetsServerCall.AddToFullSet(AdjustmentTable, RowsArray);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.Partner = Object.Partner;
	ParametersFillInVATRate.Terms = Object.Terms;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Partner", Object.Partner);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("ReturnReusablePackage", ToReturnReusablePackage);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("Organization", Object.Organization);
	
	If Not NumberOfPackagesIsUsed Then
		FillParameters.Insert("ColumnsByValue", New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef()));
	EndIf;
		
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		AdjustmentTable,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
		
	If PricesCalculated Then
		Suffix = "After";
		StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
		
		StructureOfActions = New Structure;
		
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
		ParametersFillInVATRate.Suffix = Suffix;
		ParametersFillInVATRate.Partner = Object.Partner;
		ParametersFillInVATRate.Terms = Object.Terms;
		StructureOfActions.Insert("FillInVATRateSuffixByPriceType", ParametersFillInVATRate);
		
		StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSuffixAmount", 
				New Structure ("Suffix, QuantityName", 
									Suffix, 
									?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count")));
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
	
	CalculateFinalImplementationIndicators(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	For Each String In Items.AdjustmentTable.SelectedRows Do
		RowsArray.Add(AdjustmentTable.FindByID(String));
	EndDo;
	
	SetsServerCall.AddToFullSet(AdjustmentTable, RowsArray);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	If Not NumberOfPackagesIsUsed Then
		FillParameters.Insert("ColumnsByValue", New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef()));
	EndIf;
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		AdjustmentTable,
		RowsArray,
		FillParameters,
		StructureOfActions);
		
	Suffix = "After";
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
		
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.Suffix = Suffix;
	ParametersFillInVATRate.Partner = Object.Partner;
	ParametersFillInVATRate.Terms = Object.Terms;
	ParametersFillInVATRate.PriceKind = PricesKind;
	ParametersFillInVATRate.FillInPriceView = True;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffixByPriceType", ParametersFillInVATRate);
	
	StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSuffixAmount", 
			New Structure ("Suffix, QuantityName", 
								Suffix, 
								?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count")));
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
	
	CalculateFinalImplementationIndicators(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(AdjustmentTable, ArrayOfSelectedRows, Warehouse);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	WhenChangingWarehouseInTablePartServer();
	
	WarehouseData_2 = GetDataOnWarehouses();
	For Each TSRow In AdjustmentTable Do
		WarehouseData_1 = WarehouseData_2.Find(TSRow.Warehouse);
		If WarehouseData_1 <> Undefined Then
			TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
	EndDo;
	
	If Object.SaleAdjustment2_5 Then
		UpdateOptionsForReflectingDiscrepancies2_5();
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

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
	Documents.SaleAdjustment.FillInProductsBasedOnSourceData(Object.DocumentBasis, Object.Goods, Object.Discrepancies, Object.Ref);
	LoadAdjustmentTableFromDocumentDataOnServer();
	OnReadCreateAtServer();
	
EndProcedure

#EndRegion

#Region Sets

&AtClientAtServerNoContext
Function DialColumns()
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Price");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	Columns.Add("VATRate");
	Columns.Add("VATAmount");
	Columns.Add("AmountIncludingVAT");
	Columns.Add("Sum");
	
	Return Columns;
	
EndFunction

&AtClientAtServerNoContext
Function MapNamesOfSetColumns()
	
	Columns = New Map;
	Columns.Insert("Price",				"PriceAfter");
	Columns.Insert("Count",			"QuantityAfter");
	Columns.Insert("NumberOfPackages",	"NumberOfPackagesAfter");
	
	Columns.Insert("VATRate",			"VATRateAfter");
	Columns.Insert("VATAmount",			"VATAmountAfter");
	Columns.Insert("AmountIncludingVAT",			"AmountWithVATAfter");
	Columns.Insert("Sum",				"AmountAfter");
	
	Return Columns;
	
EndFunction

&AtClient
// Called via the description of the message from the general module setclient 
Procedure WhenRemovingComponents(Action, AdditionalParameter) Export
	
	If SetsClient.EditSetAction(Action) Then
		SetsClient.WhenRemovingComponents(ThisObject, "AdjustmentTable", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("AdjustmentTable", AdditionalParameter);
	EndIf;
	
	UpdateServiceFieldsOfValueTable(ThisObject);
	CalculateFinalImplementationIndicators(ThisObject);
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	SetsServer.WhenRemovingComponents(ThisObject, TSName, AdditionalParameter);
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisObject, Var_Parameters, "AdjustmentTable");
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	Suffix = "After";
	
	StructureOfActionsWithModifiedStrings = New Structure;
	// The warehouse will be inserted later
	StructureOfActionsWithModifiedStrings.Insert("CheckSeriesCalculateStatus", New Structure("SeriesSpecificationParameters", SeriesSpecificationParameters));
	StructureOfActionsWithModifiedStrings.Insert("ClearAmountOfSettlements");
	StructureOfActionsWithModifiedStrings.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", New Structure("SeriesSpecificationParameters", SeriesSpecificationParameters));
	StructureOfActionsWithAddedStrings.Insert("CheckCharacteristicsByOwner", Undefined);
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("CheckFillPackageByOwner", Undefined);
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	StructureOfActionsWithAddedStrings.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	StructureOfActionsWithAddedStrings.Insert("ClearAmountOfSettlements");
	StructureOfActionsWithAddedStrings.Insert("ClearAmountOfSettlementsSuffix", Suffix);
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns());
	If Items.AdjustmentTable.CurrentItem <> Undefined
		And StrFind(Items.AdjustmentTable.CurrentItem.Name, "After") > 0 Then
		DataParameters.Insert("MapColumnNames", MapNamesOfSetColumns());
	EndIf;
	
	SeriesSpecificationParameters.NameTSGoods = "Goods";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SetsServer.AtEndOfEditingSet(ThisObject, "AdjustmentTable", DataParameters);
	SeriesSpecificationParameters.NameTSGoods = "AdjustmentTable";
	SeriesSpecificationParameters.TSSeriesName = "AdjustmentTable";

	SetStrings = AdjustmentTable.FindRows(New Structure("ProductsInSet, ItemVariantOfSet",
			DataParameters.Data.ProductsInSet, DataParameters.Data.ItemVariantOfSet));
	For Each String In SetStrings Do
		SetReflectionOptionForString(String, OtherAssetServiceAdjustment, LastPeriodAdjustment, Object.SaleAdjustment2_5);
	EndDo;
	
	UpdateServiceFieldsOfValueTable(ThisObject);
	CalculateFinalImplementationIndicators(ThisObject);
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtClient
Function ItemToLock(Field)
	
	ItemsToLock = SetsClientServer.ItemsToLock();
	
	ItemsToLock.Add("TableOfAdjustmentOfSetIndexAfter");
	ItemsToLock.Add("AdjustmentTableQuantityAfter");
	ItemsToLock.Add("AdjustmentTableNumberOfPackagesAfter");
	ItemsToLock.Add("AdjustmentTablePriceAfter");
	ItemsToLock.Add("AdjustmentTableAmountAfter");
	ItemsToLock.Add("AdjustmentTableVATRateAfter");
	ItemsToLock.Add("AdjustmentTableVATAmountAfter");
	ItemsToLock.Add("AdjustmentTableAmountWithVATAfter");
	
	If ItemsToLock.Find(Field.Name) <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateFinalImplementationIndicators(Form)
	
	Form.AmountTotal = Form.AdjustmentTable.Total("AmountIncludingVAT");
	Form.VATAmount = Form.AdjustmentTable.Total("VATAmount");
	
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
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	UseLinesOfBusiness = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	UseLocal = GetFunctionalOption("UseLocal");
	
	AdjustTaxBaseOfPreviousPeriod = Not SaleAdjustmentLocalization.NotAdjustTaxBaseOfPreviousPeriod(Object.Organization, DocumentDate);
		
	FillInCostAccountingAttribute();
	
	LoadAdjustmentTableFromDocumentDataOnServer();
	CheckForAdjustments(Object.Ref, Object.DocumentBasis, ThereAreAdjustingEntries, TypeOfPreviousAdjustment);

	If ValueIsFilled(Object.DocumentBasis) Then
		SetPrivilegedMode(True);
		FoundationDocumentIsOld = Object.DocumentBasis;
		FoundationDocumentData = Common.ObjectAttributesValues(Object.DocumentBasis, "Date, Contract, DocumentAmount, SumCompl, SumMan");
		ReferenceDocumentDateForCertificate = FoundationDocumentData.Date;
		FoundationAgreement = FoundationDocumentData.Contract;
		
		If FoundationDocumentData.DocumentAmount > 0 Then
			LocalRateByBasisDocument = Round(FoundationDocumentData.SumCompl / FoundationDocumentData.DocumentAmount, 4, 1);
			ManRateByBasisDocument = Round(FoundationDocumentData.SumMan / FoundationDocumentData.DocumentAmount, 4, 1);
		Else
			LocalRateByBasisDocument = 0;
			ManRateByBasisDocument = 0;
		EndIf;
		
		ContractsAreUsed = ValueIsFilled(FoundationAgreement);
		DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		LastPeriodAdjustment = BegOfYear(DocumentDate) > BegOfYear(ReferenceDocumentDateForCertificate);
		OtherAssetServiceAdjustment = 
			Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
		If ValueIsFilled(Object.Contract)
			And Common.ObjectAttributeValue(Object.Contract, "ContractType") = Enums.ContractTypes.ReceiptForTolling2_5 Then
			AdjustingGiver = True;
		Else
			AdjustingGiver = False;
		EndIf;
		SetPrivilegedMode(False);
	Else
		If Parameters.Property("Basis")
			And Not Parameters.Basis = Undefined Then
			Parameters.Property("Basis",Object.DocumentBasis);
		EndIf;
		LastPeriodAdjustment = False;
		OtherAssetServiceAdjustment = False;
		AdjustingGiver = False;
		ReferenceDocumentDateForCertificate = Object.Date;
		ContractsAreUsed = Undefined;
	EndIf;
	
	SetVisibilityOfElementsByAdjustingImplementation2_5();
	If Object.SaleAdjustment2_5 Then
		UpdateReflectionInAccountingByDocumentAttributes();
		SetVisibilityOfItemsByAccountingPolicy();
		UpdateTrackingReflectionHeader();
	EndIf;

	SetTypeOfAdjustment();
	FillInBusinessTransactionOfFoundationDocument();
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
	SetPresentationOfFoundationDocument();
	
	OptionsForSelection = OptionsForSelectingArticlesAndAnalytics();
	ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.OptionsForSelectingArticlesAndAnalyticsBeforeEnteringBalances(OptionsForSelection);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetVisibilityOfElementsByTypeOfAdjustmentServer();
	SetVisibilityOfElementsByBase();
	
	SetAvailabilityOfItemsByStatusServer();
	
	FillOperationSelectionList();
	SetVisibilityOfDocumentBeingCorrected();
	UpdatePresentationElementsOfDocumentBeingCorrected();
		
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(AdjustmentTable);
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
	
	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
	PrepareFillSetSeriesVisibility();

	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
	WhenChangingWarehouseInTablePartServer();
	Items.AdjustmentTableFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	
	FillInRestrictionsWhenChangingContract();
	
	SetSelectionParametersAdjustmentTableWarehouse();
	
	UpdateTextDocumentsBasedOn();
	
	UpdateServiceDetailsOfTableParts();
	EstablishCostPresentation();
	
	BasisChanged = False;
	If AccessRight("Update", Metadata.Documents.SaleAdjustment) And ValueIsFilled(Object.Basis) Then
		If ValueIsFilled(Object.Basis) Then
			BaseStructure = Documents.SaleAdjustment.StructureOfBaseForPrinting(Object);
			BasisChanged = (TrimAll(Object.Basis) <> BaseStructure.Basis) 
				Or (TrimAll(Object.BaseDocumentNumber) <> BaseStructure.BaseDocumentNumber)
				Or (Object.ReferenceDocumentDateForPrintForms <> BaseStructure.ReferenceDocumentDateForPrintForms);
		EndIf;
	EndIf;
	PrintBasisTable.Load(Documents.SaleAdjustment.PrintBasisTable(Object));
	
	CalculateFinalImplementationIndicators(ThisObject);
	UpdateVHFWarehouseObligation();
	UpdateServiceFieldsOfValueTable(ThisObject);
	
	Items.SaleRegistrationOption.Visible = TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoice");
	ProcessingOfTabularForms.InitializeRowCache(Items.AdjustmentTable);
	
	FillParameters = Documents.SaleAdjustment.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	
	CurrentCompany = Object.Organization;
	CurrentCurrency = Object.Currency;
	CurCurrencyOfSettlements = Object.ARAPCurrency;
	CurrentCounterparty = Object.Counterparty;
	CurPartner = Object.Partner;
	
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
												|tr = '<değiştir>'"),,,, "SelectDocument");
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
Procedure SetVisibilityOfDocumentBeingCorrected()
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GroupDocumentBeingCorrected", 
		"Visible", ValueIsFilled(Object.DocumentBasis) And Object.AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByBase()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.SaleAdjustment.FillInNamesOfDetailsOnBasis(
		Object.DocumentBasis, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails,
		Object.AdjustingEntryType);
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	NumberOfPackagesIsUsed = Items.AdjustmentTableNumberOfPackages.Visible;
	UsedPackaging = Items.AdjustmentTablePackage.Visible;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableCount", "Visible", Not UsedPackaging);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableQuantityAfter", "Visible", Not UsedPackaging);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableNumberOfPackages", "Visible", UsedPackaging);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableNumberOfPackagesAfter", "Visible", UsedPackaging);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableProductsUnitOfMeasure", "Visible", 
																				Items.AdjustmentTableProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableOpenSelection", "Visible", 
																				Items.AdjustmentTableProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableFillThePricesByTermsOfSales", "Visible", 
																				ToUseTermsOfSales And Items.AdjustmentTableProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableFillThePricesByTermsOfSales", "Visible", 
																				ToUseTermsOfSales And Items.AdjustmentTableProducts.Visible);
	If AdjustingGiver Then
		ArrayOfElementNames = New Array;
		ArrayOfElementNames.Add("AdjustmentTableCharacteristic");
		ArrayOfElementNames.Add("AdjustmentTableColumnGroupSeries");
		ArrayOfElementNames.Add("AdjustmentTableCCDNumber");
		ArrayOfElementNames.Add("AdjustmentTableCCDNumberCountryOfOrigin");
		ArrayOfElementNames.Add("TableOfAdjustmentsGroupQuantityByRNPT");
		ArrayOfElementNames.Add("AdjustmentTableSenderGroup");
		ArrayOfElementNames.Add("AdjustmentTableMethodForDeterminingTheCostOfALine");
		ArrayOfElementNames.Add("Terms");
		ArrayOfElementNames.Add("Warehouse");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ContractGroup", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Contract", "Visible", True);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Contract", "Enabled", True);
	Else
		SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible);
	EndIf;
	If OtherAssetServiceAdjustment Then
		
		If LastPeriodAdjustment Then
			
			ArrayOfElementNames = New Array;
			ArrayOfElementNames.Add("TextForOtherExpenses");
			TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", True);
			
		Else
			
			ArrayOfElementNames = New Array;
			ArrayOfElementNames.Add("TextForOtherExpenses");
			ArrayOfElementNames.Add("BusinessUnit");
			ArrayOfElementNames.Add("BusinessUnitExpenses");
			TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", False);
			
		EndIf;
		
		ArrayOfElementNames = New Array;
		ArrayOfElementNames.Add("AdjustmentTableSetComposition");
		ArrayOfElementNames.Add("AdjustmentTableSetIndex");
		ArrayOfElementNames.Add("AdjustmentTableProductsInSet");
		ArrayOfElementNames.Add("AdjustmentTableItemVariantOfSet");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", False);
		
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
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible",
		Items.ExpenseItem.Visible);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "AdjustmentTableCCDNumberCountryOfOrigin", "Visible", Items.AdjustmentTableCCDNumber.Visible);
	
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
	ItemArray.Add(Items.PriceIncludesVAT.Name);
	ItemArray.Add(Items.SubjectToExcise.Name);
	
	ItemArray.Add(Items.AdjustmentTableOpenSelection.Name);
	ItemArray.Add(Items.AdjustmentTableFillThePricesByTermsOfSales.Name);
	ItemArray.Add(Items.AdjustmentTableFillInPricesOfSelectedRowsByPriceType.Name);
	ItemArray.Add(Items.AdjustmentTableFillInTheWarehouseInSelectedLines.Name);
	ItemArray.Add(Items.AdjustmentTableFillInAdjustmentData.Name);
	ItemArray.Add(Items.AdjustmentTableInsertRows.Name);
	ItemArray.Add(Items.AdjustmentTableSetComposition.Name);
	ItemArray.Add(Items.EditDocumentBeingCorrected.Name);
	
	ItemArray.Add("AdjustmentTable;BeforeAddRow,BeforeDeleteRow,BeforeRowChange;AdjustmentTableIncomeItem,AdjustmentTableDimensionOfRevenue,AdjustmentTableIncomeItem,AdjustmentTableDimensionOfRevenue");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		Items.AdjustmentTableFillInTheWarehouseInSelectedLines.Name,
		"Enabled",
		WarehouseGroup_);
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	If ValueIsFilled(Object.DocumentBasis)
		And TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets")
		Or Object.SaleAdjustment2_5 Then
			
		ListItem = Items.Operation.ChoiceList.FindByValue(Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods);
		If ListItem <> Undefined Then
			Items.Operation.ChoiceList.Delete(ListItem);
		EndIf;
		ListItem = Items.Operation.ChoiceList.FindByValue(Enums.BusinessTransactions.SaleOfOverdeliveredGoods);
		If ListItem <> Undefined Then
			Items.Operation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function OptionsForSelectingArticlesAndAnalytics()
	
	OptionsForSelection = Documents.SaleAdjustment.ParametersForDeterminingAvailabilityOfSelectionOfArticlesAndAnalytics();
	OptionsForSelection.BusinessOperation	= Object.AdjustmentKind;
	OptionsForSelection.DocumentBasis		= Object.DocumentBasis;
	OptionsForSelection.DocumentDate			= Object.Date;
	OptionsForSelection.AdjustingEntryType			= Object.AdjustingEntryType;

	OptionsForSelection.RecordInOtherIncome	= AmountForOtherIncome > 0;
	OptionsForSelection.ToExpenseAs			= AmountForOtherExpenses > 0;
	
	Return OptionsForSelection;
	
EndFunction

&AtServer
Procedure ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies()
	
	TotalVATAmount = 0;
	TotalAmountWithVAT = 0;
	AmountForOtherIncome  = 0;
	AmountForOtherExpenses = 0;
	TotalAmountShovelcharge = 0;
	TotalAmountZhamanshina = 0;
	TotalAmountJavelina = 0;
	TotalAmountOfNDSUReduction = 0;
	
	CalculateTotalsOnGoodsTable_();
	
	OptionsForSelection = OptionsForSelectingArticlesAndAnalytics();
	ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.OptionsForSelectingArticlesAndAnalyticsBeforeEnteringBalances(OptionsForSelection);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);

	TextForOtherExpenses = StrTemplate(NStr("vi = 'Chi phí khác: %1 %2';
											|ru = 'Прочие расходы: %1 %2';
											|en = 'Other expenses: %1 %2'; fa = 'Other expenses: %1 %2';
											|it = 'Altre spese: %1 %2';
											|pl = 'Inne rozchody: %1 %2';
											|tr = 'Diğer giderler: %1 %2'"), 
		Format(AmountForOtherExpenses, "NFD=2; NZ="), 
		Object.Currency);
		
	TextForOtherIncome = StrTemplate(NStr("vi = 'Thu nhập khác: %1 %2';
											|ru = 'Прочие доходы:  %1 %2';
											|en = 'Income: %1 %2'; fa = 'Income: %1 %2';
											|it = 'Altri ricavi: %1 %2';
											|pl = 'Inne dochody:  %1 %2';
											|tr = 'Diğer gelirler: %1 %2'"), 
		Format(AmountForOtherIncome, "NFD=2; NZ="), 
		Object.Currency);
		
	AvailabilityCosts = ValueIsFilled(AmountForOtherExpenses);
	Items.BusinessUnitExpenses.Enabled = AvailabilityCosts;
	
	AvailabilityOfIncome = ValueIsFilled(AmountForOtherIncome);
	Items.BusinessUnit.Enabled = AvailabilityOfIncome;
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods")
		And TypeOf(Object.DocumentBasis) = Type("DocumentRef.SourceDocument")
		And Operation = Enums.BusinessTransactions.SaleToCustomer;
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, , ReferenceDocumentDateForCertificate);
	
EndProcedure

&AtServer
Procedure CalculateTotalsOnGoodsTable_()
	
	For Each LineOfDiscrepancies In AdjustmentTable Do
		
		If LineOfDiscrepancies.VATRate = LineOfDiscrepancies.VATRateAfter
			Or (LineOfDiscrepancies.QuantityAfter = 0
				And LineOfDiscrepancies.VATAmountAfter = 0
				And LineOfDiscrepancies.VATAmountAfter = 0) Then
			DiscrepancySumWithVAT = LineOfDiscrepancies.AmountWithVATAfter - LineOfDiscrepancies.AmountIncludingVAT;
			DiscrepancyInAmountOfVAT  = LineOfDiscrepancies.VATAmountAfter - LineOfDiscrepancies.VATAmount;
			RecalculationOfAmountsOfIncreaseAndDecrease(DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
				LineOfDiscrepancies.PostingOption);
		Else
			DiscrepancySumWithVAT = -LineOfDiscrepancies.AmountIncludingVAT;
			DiscrepancyInAmountOfVAT  = -LineOfDiscrepancies.VATAmount;
			RecalculationOfAmountsOfIncreaseAndDecrease(DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
				LineOfDiscrepancies.OptionToReflectWriteOff);
			
			DiscrepancySumWithVAT = LineOfDiscrepancies.AmountWithVATAfter;
			DiscrepancyInAmountOfVAT  = LineOfDiscrepancies.VATAmountAfter;
			RecalculationOfAmountsOfIncreaseAndDecrease(DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
				LineOfDiscrepancies.PostingOption);
		EndIf;
		
		TotalAmountWithVAT = TotalAmountWithVAT +  LineOfDiscrepancies.AmountWithVATAfter;
		TotalVATAmount = TotalVATAmount +  LineOfDiscrepancies.VATAmountAfter;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RecalculationOfAmountsOfIncreaseAndDecrease(DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT, PostingOption)
	
	TotalAmountShovelcharge = TotalAmountShovelcharge + ?(DiscrepancySumWithVAT > 0, DiscrepancySumWithVAT, 0);
	TotalAmountZhamanshina = TotalAmountZhamanshina + ?(DiscrepancySumWithVAT < 0, -DiscrepancySumWithVAT, 0);
	TotalAmountJavelina  = TotalAmountJavelina + ?(DiscrepancyInAmountOfVAT > 0, DiscrepancyInAmountOfVAT, 0);
	TotalAmountOfNDSUReduction  = TotalAmountOfNDSUReduction + ?(DiscrepancyInAmountOfVAT < 0, -DiscrepancyInAmountOfVAT, 0);
	
	If PostingOption = Enums.CreditNoteRecordingOptions.RecordInOtherIncome Then
		If OtherAssetServiceAdjustment And Not LastPeriodAdjustment  Then
			AmountForOtherIncome = AmountForOtherIncome + DiscrepancySumWithVAT;
		Else
			AmountForOtherIncome = AmountForOtherIncome + ?(DiscrepancySumWithVAT<0, -DiscrepancySumWithVAT, DiscrepancySumWithVAT);
		EndIf;
	ElsIf PostingOption = Enums.CreditNoteRecordingOptions.ToExpenseAs
		Or PostingOption = Enums.CreditNoteRecordingOptions.ReduceSaleWriteOffForExpenses Then
		AmountForOtherExpenses = AmountForOtherExpenses + ?(DiscrepancySumWithVAT<0, -DiscrepancySumWithVAT, DiscrepancySumWithVAT);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateServiceDetailsOfTableParts()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	ServiceTableAdjustments = AdjustmentTable.Unload();
	ProductsServer.FillInServiceDetailsForProductInCollection(ServiceTableAdjustments, StructureOfActions);
	AdjustmentTable.Load(ServiceTableAdjustments);
	SetsServer.FillInServiceDetails(ThisObject, "AdjustmentTable");
	
	WarehouseData_2 = GetDataOnWarehouses();
	For Each TSRow In AdjustmentTable Do
		
		WarehouseData_1 = WarehouseData_2.Find(TSRow.Warehouse);
		If WarehouseData_1 <> Undefined Then
			TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
		
	EndDo;
	
	If Object.SaleAdjustment2_5 Then
		UpdateOptionsForReflectingDiscrepancies2_5();
	EndIf;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(AdjustmentTable);
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()

	WarehousesServer.WhenChangingWarehouseInTablePart(AdjustmentTable, WarehouseTable, WarehouseGroup_, False);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);

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
		
		ShowQueryBox(New CallbackDescription("TypeOfCorrectionWhenChangingBaseDocumentCompletion", ThisObject, ValueSelected), QueryText, ButtonsList);
	Else
		If AdjustmentTable.Count() > 0 Then
			UploadAdjustmentTableToDocumentData();
		EndIf;
		ProcessingDocumentSelectionViaServer(ValueSelected);
		UpdateServiceFieldsOfValueTable(ThisObject);
	EndIf;

EndProcedure

&AtServer
Procedure ProcessingDocumentSelectionViaServer(ValueSelected)
	
	Modified = True;
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(ValueSelected);
	ValueToFormAttribute(DocumentObject, "Object");
	
	Object.DocumentBasis = ValueSelected;
	Object.CorrectedDocument = Undefined;	
	
	OnReadCreateAtServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenQuantityChanges(StructureOfActions, Form, Suffix = "")
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);

	LocalDataForRecalculatingAmount = New Structure();
	LocalDataForRecalculatingAmount.Insert("PriceIncludesVAT", Form.Object.PriceIncludesVAT);
	LocalDataForRecalculatingAmount.Insert("ByAmountOfDocument", Form.Object.Currency = Form.LocalAccountingCurrency);
	LocalDataForRecalculatingAmount.Insert("ConversionRatioFromDocumentCurrency", Form.LocalRateByBasisDocument);
	LocalDataForRecalculatingAmount.Insert("Suffix", Suffix);
	
	DataForRecalculatingManSAmount = New Structure();
	DataForRecalculatingManSAmount.Insert("PriceIncludesVAT", Form.Object.PriceIncludesVAT);
	DataForRecalculatingManSAmount.Insert("ByAmountOfDocument", Form.Object.Currency = Form.ManagementAccountingCurrency);
	DataForRecalculatingManSAmount.Insert("ConversionRatioFromDocumentCurrency", Form.ManRateByBasisDocument);
	DataForRecalculatingManSAmount.Insert("Suffix", Suffix);

	If Suffix = "" Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount", "Count");
		StructureOfActions.Insert("ClearAmountOfSettlements");
		StructureOfActions.Insert("RecalculateAmountWithoutVATLocal", LocalDataForRecalculatingAmount);
		StructureOfActions.Insert("RecalculateAmountWithoutVATMan", DataForRecalculatingManSAmount);
	Else
		StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
		StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSuffixAmount", New Structure ("Suffix, QuantityName", Suffix, "Count"));
		StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", Suffix);
		StructureOfActions.Insert("RecalculateAmountWithoutVATLocalSuffix", LocalDataForRecalculatingAmount);
		StructureOfActions.Insert("RecalculateAmountWithoutVATManSuffix", DataForRecalculatingManSAmount);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form, Suffix = "")
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Form.Object);
	ParametersFillInVATRate.Date = Form.ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.Insert("Suffix", Suffix);
	
	LocalDataForRecalculatingAmount = New Structure();
	LocalDataForRecalculatingAmount.Insert("PriceIncludesVAT", Form.Object.PriceIncludesVAT);
	LocalDataForRecalculatingAmount.Insert("ByAmountOfDocument", Form.Object.Currency = Form.LocalAccountingCurrency);
	LocalDataForRecalculatingAmount.Insert("ConversionRatioFromDocumentCurrency", Form.LocalRateByBasisDocument);
	LocalDataForRecalculatingAmount.Insert("Suffix", Suffix);
	
	DataForRecalculatingManSAmount = New Structure();
	DataForRecalculatingManSAmount.Insert("PriceIncludesVAT", Form.Object.PriceIncludesVAT);
	DataForRecalculatingManSAmount.Insert("ByAmountOfDocument", Form.Object.Currency = Form.ManagementAccountingCurrency);
	DataForRecalculatingManSAmount.Insert("ConversionRatioFromDocumentCurrency", Form.ManRateByBasisDocument);
	DataForRecalculatingManSAmount.Insert("Suffix", Suffix);
	
	If Suffix = "" Then
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("ClearAmountOfSettlements");
		StructureOfActions.Insert("RecalculateAmountWithoutVATLocal", LocalDataForRecalculatingAmount);
		StructureOfActions.Insert("RecalculateAmountWithoutVATMan", DataForRecalculatingManSAmount);
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		
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
		StructureOfActions.Insert("RecalculateAmountWithoutVATLocalSuffix", LocalDataForRecalculatingAmount);
		StructureOfActions.Insert("RecalculateAmountWithoutVATManSuffix", DataForRecalculatingManSAmount);
		StructureOfActions.Insert("FillInVATRateSuffix", ParametersFillInVATRate);
		
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
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServerNoContext
Procedure CheckForAdjustments(Ref, Basis, ThereAreAdjustingEntries, TypeOfPreviousAdjustment)
	
	TypeOfPreviousAdjustment = SalesServer.CheckForAdjustments(Ref, Basis, ThereAreAdjustingEntries)
	
EndProcedure

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Thỏa thuận""';
										|ru = 'Поле ""Соглашение"" не заполнено';
										|en = '""Terms of sales"" are not filled'; fa = '""Terms of sales"" are not filled';
										|it = 'Il campo ""Accordo"" non è compilato';
										|pl = 'Pole ""Porozumienie"" nie jest wypełnione';
										|tr = '""Anlaşma"" alanı doldurulmamış'"), Object.Ref, "Object.Terms",,Cancel);
	EndIf;
	
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
	Suffix = "After";
	
	WarehouseParameters = New Structure;
	WarehouseParameters.Insert("CheckDate", Object.Date);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.Suffix = Suffix;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffix", ParametersFillInVATRate);
		
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.Suffix = Suffix;
	ParametersFillInVATRate.Partner = Object.Partner;
	ParametersFillInVATRate.Terms = Object.Terms;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffixByPriceType", ParametersFillInVATRate);
	
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));  
	StructureOfActions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));
	StructureOfActions.Insert("FillInOrderWarehouseAttribute", WarehouseParameters);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject, Suffix);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
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
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = AdjustmentTable.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "ProductsInSet, ItemVariantOfSet, Products, Characteristic, Package, Warehouse, Price, NumberOfPackages, Series");
		CurrentRow.PriceAfter = RowOfProduct.Price;
		CurrentRow.NumberOfPackagesAfter = RowOfProduct.NumberOfPackages;
		
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet),1,0);
		UpdateRowNumberOfAdjustmentTable(CurrentRow);
		
		RowsToProcess.Add(CurrentRow);
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		AdjustmentTable);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(AdjustmentTable, StructureCharacteristicsOfProducts);
	
	SetsServer.FillInServiceDetails(ThisObject, "AdjustmentTable");
	
	WhenChangingWarehouseInTablePartServer();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	UpdateTitleOfAdjustmentTable();
	
EndProcedure

&AtClient
Procedure OpenPrintDetails()
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ParametersStructure = New Structure();
	
	ParametersStructure.Insert("DeliveryAddress",                  Object.DeliveryAddress);
	ParametersStructure.Insert("DeliveryAddressValue",          Object.DeliveryAddressValue);
	ParametersStructure.Insert("DeliveryAddressFieldValues",     Object.DeliveryAddressFieldValues);
	ParametersStructure.Insert("ShipperBankAccount", Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("Shipper",               Object.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                Object.GoodsRecipient);
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy",             Object.LetterOfAuthorityIssuedBy);
	ParametersStructure.Insert("PowerOfAttorneyDate",               Object.PowerOfAttorneyDate);
	ParametersStructure.Insert("PowerOfAttorneyPerson",               Object.PowerOfAttorneyPerson);
	ParametersStructure.Insert("PowerOfAttorneyNumber",              Object.PowerOfAttorneyNumber);
	ParametersStructure.Insert("IssuiedBy",                       Object.IssuiedBy);
	ParametersStructure.Insert("IssuiedByJobTitle",              Object.IssuiedByJobTitle);
	ParametersStructure.Insert("ObjectType",                     "SaleAdjustment");
	ParametersStructure.Insert("ShipperBankAccount", Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",      Object.CounterpartyBankAccount);
	ParametersStructure.Insert("Contract",                        Object.Contract);
	ParametersStructure.Insert("Basis",                      Object.Basis);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                  Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",                 Object.BaseDocumentNumber);
	ParametersStructure.Insert("Partner",                        Object.Partner);
	ParametersStructure.Insert("BusinessOperation",          PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
	ParametersStructure.Insert("Counterparty",                     Object.Counterparty);
	ParametersStructure.Insert("ReadOnly",                 ReadOnly);
	ParametersStructure.Insert("SaleByOrders",               Object.SaleByOrders);
	ParametersStructure.Insert("CompanyBankAccount",      Object.CompanyBankAccount);
	ParametersStructure.Insert("Organization",                    Object.Organization);
	ParametersStructure.Insert("Date",                           Object.Date);
	ParametersStructure.Insert("Director",                   Object.Director);
	ParametersStructure.Insert("ChiefAccountant",               Object.ChiefAccountant);
	ParametersStructure.Insert("PrintBasisTable",      PrintBasisTable);
	
	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function GetDataOnWarehouses()
	
	Warehouses = AdjustmentTable.Unload(,"Warehouse");
	Warehouses.GroupBy("Warehouse");
	Warehouses.Columns.Add("UseWarehouseManagemantSystemForGoodsSurplusesShortages",
		New TypeDescription("Boolean"));
	
	For Each Page1 In Warehouses Do
		If ValueIsFilled(Page1.Warehouse) Then
			Page1.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Page1.Warehouse, Object.Date);
		EndIf;
	EndDo;
	
	Return Warehouses;
	
EndFunction

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TextsFieldsDocumentsBasedOn.Clear();
	
	UpdateTextOfInvoiceIssued();
	
	TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	If Object.Organization = CurrentCompany Then
		Return;
	EndIf;
	
	CurrentCompany = Object.Organization;
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	AdjustTaxBaseOfPreviousPeriod = Not SaleAdjustmentLocalization.NotAdjustTaxBaseOfPreviousPeriod(Object.Organization, DocumentDate);
	
	ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If ValueIsFilled(Object.Organization) Then
		
		UpdateTextDocumentsBasedOn();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
	
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
		
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization, Object.CompanyBankAccount, , Object.LineOfBusiness);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	If Object.SaleAdjustment2_5 Then
		SetVisibilityOfItemsByAccountingPolicy();
		UpdateTrackingReflectionHeader();
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyWhenChangesAreMadeOnServer()

	If Object.Counterparty = CurrentCounterparty Then
		Return;
	EndIf;
	
	CurrentCounterparty = Object.Counterparty;
	
	ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();

	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Counterparty) Then
		SalesServer.PartnerOnChange(Object);
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	UpdateTextDocumentsBasedOn();
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	If Object.Partner = CurPartner Then
		Return;
	EndIf;
	
	CurPartner = Object.Partner;
	
	ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();
	
	AttributesArray = New Array;
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(AdjustmentTable, Object.Partner);
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	AttributesArray.Add("Partner");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	SalesServer.PartnerOnChange(Object);
	ResponsiblePersonsServer.FillInManager_(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
	ResponsiblePersonsServer.FillInManager_(Object);
	FillInRestrictionsWhenChangingContract();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	SetPrivilegedMode(True);
	If ValueIsFilled(Object.Contract)
		And Common.ObjectAttributeValue(Object.Contract, "ContractType") = Enums.ContractTypes.ReceiptForTolling2_5 Then
		AdjustingGiver = True;
	Else
		AdjustingGiver = False;
	EndIf;
	SetPrivilegedMode(False);
	
	If AdjustingGiver
		And Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
		ItIsNotPossibleToDeleteRows();
	EndIf;
	SetVisibilityOfElementsByTypeOfAdjustmentServer();
	SetVisibilityOfElementsByBase();
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	FillBaseForPrinting();
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtServer
Procedure FillInRestrictionsWhenChangingContract()

	ListOfProductLISTTypes = New Array();
	ListOfProductLISTTypes.Add(Enums.ItemsTypes.OwnGoods);
	ListOfProductLISTTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ListOfProductLISTTypes.Add(Enums.ItemsTypes.Work_5);
	ListOfProductLISTTypes.Add(Enums.ItemsTypes.OperationService);
		
	ArrayOfContractTypes = New Array();
	ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.WithCustomer"));
	SetPrivilegedMode(True);
	ArrayOfContractTypes.Add(PredefinedValue("Enum.ContractTypes.ReceiptForTolling2_5"));
	
	If ValueIsFilled(Object.Contract)
		And Common.ObjectAttributeValue(Object.Contract,"ContractType") = Enums.ContractTypes.ReceiptForTolling2_5 Then
		
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
														|en = 'Service adjustment by content'; fa = 'Service adjustment by content';
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
	SetPrivilegedMode(False);
	NewArray = New Array();
	NewArray.Add(New ChoiceParameter("Filter.ContractType", New FixedArray(ArrayOfContractTypes)));
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
Procedure TermsOnChangeServer()
	
	FillInTermsOfSalesUnderAgreement();
	ResponsiblePersonsServer.FillInManager_(Object);
	
	FillOperationSelectionList();
	DocumentCurrency = Object.Currency;
	CurrentCompany = Object.Organization;
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
	WarehouseOnChangeServer();
	OperationWhenChangingOnServer();
	SetAvailabilityOfItemsByStatusServer();
	
	UpdateTextDocumentsBasedOn();
	
	UpdateServiceDetailsOfTableParts();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible, Object.Contract);
	
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	CalculateFinalImplementationIndicators(ThisObject);

	SetVisibilityOfElementsByTypeOfAdjustmentServer();
	FillBaseForPrinting();
	
EndProcedure

&AtServer
Procedure AdjustingEntryTypeOnChangeServer()
	
	ThisIsAdjustmentToSaleOfGoodsAndServices = Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices;
	OtherAssetServiceAdjustment = 
		Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	
	For Each CurrentRow In AdjustmentTable Do
		If Not ThisIsAdjustmentToSaleOfGoodsAndServices Then
			CurrentRow.Products = Catalogs.Products.EmptyRef();
			CurrentRow.PartnerProducts = Catalogs.ProductCrossReferences.EmptyRef();
			CurrentRow.Characteristic = Catalogs.ItemsCharacteristics.EmptyRef();
			CurrentRow.Series = Catalogs.ItemsBatches.EmptyRef();
			CurrentRow.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
			CurrentRow.ItemsType = Enums.ItemsTypes.EmptyRef();
			CurrentRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages = False;
			CurrentRow.TheRecordsAreKeptByCCD = False;
			CurrentRow.CCDNumberType = Enums.CCDNumberTypes.EmptyRef();
			CurrentRow.ItemVariantsAreUsed = False;
			CurrentRow.CCDNumber = Catalogs.CCDNumbers.EmptyRef();
			CurrentRow.BatchesIndicationStatus = 0;
			CurrentRow.NumberOfPackages = 0;
		EndIf;
	EndDo;
	
	SetVisibilityOfElementsByTypeOfAdjustmentServer();
	SetVisibilityOfElementsByBase();
	
	OptionsForSelection = OptionsForSelectingArticlesAndAnalytics();
	ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.OptionsForSelectingArticlesAndAnalyticsBeforeEnteringBalances(OptionsForSelection);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetTypeOfAdjustment();
	
EndProcedure

&AtClient
Procedure AdjustingEntryTypeOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.OK Then
		AdjustmentTable.Clear();
		AdjustingEntryTypeOnChangeServer();
		UpdateServiceFieldsOfValueTable(ThisObject);
	Else
		Object.AdjustingEntryType = TypeOfAdjustmentIsOld;
	EndIf;
	
EndProcedure

&AtClient
Procedure TypeOfCorrectionWhenChangingBaseDocumentCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.OK Then
		AdjustmentTable.Clear();
		Object.Goods.Clear();
		Object.Discrepancies.Clear();
		ProcessingDocumentSelectionViaServer(AdditionalParameters);
		UpdateServiceFieldsOfValueTable(ThisObject);
	Else
		Object.DocumentBasis = FoundationDocumentIsOld;
	EndIf;
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
	
	SetSelectionParametersAdjustmentTableWarehouse();

	If Not GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments")
		And Not GetFunctionalOption("UseBusinessUnits") Then
		Items.AdjustmentTableSenderGroup.Visible = False;
	ElsIf Not WarehouseGroup_ Then
		Items.AdjustmentTableSenderGroup.Title = NStr("vi = 'Bộ phận gửi';
														|ru = 'Подразделение-отправитель';
														|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
														|it = 'Подразделение-отправитель';
														|pl = 'Shipping business unit';
														|tr = 'Gönderen departman'");
	Else
		Items.AdjustmentTableSenderGroup.Title = NStr("vi = 'Người gửi';
														|ru = 'Отправитель';
														|en = 'Shipper'; fa = 'فرستنده';
														|it = 'Отправитель';
														|pl = 'Shipper';
														|tr = 'Gönderen'");
	EndIf;
	
	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
	Items.AdjustmentTableFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;

	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, AdjustmentTable, True);
	
	WhenChangingWarehouseInTablePartServer();
	UpdateServiceDetailsOfTableParts();
	PrepareFillSetSeriesVisibility();
	
	For Each TableRow In AdjustmentTable Do
		
		If (TableRow.ItemsType = Enums.ItemsTypes.OwnGoods
			Or TableRow.ItemsType = Enums.ItemsTypes.ReusablePackage)
			And TableRow.Count <> TableRow.QuantityAfter Then
			
			ChoiceList = GetReflectionOptionsAvailableForString(TableRow,
				OtherAssetServiceAdjustment, LastPeriodAdjustment, Object.SaleAdjustment2_5);
			If ChoiceList.Find(TableRow.PostingOption) = Undefined Then
				TableRow.PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.EmptyRef();
			EndIf;
			
			WriteOffSelectionList = GetAvailableOptionsForReflectingWriteOffForLine(TableRow,
				OtherAssetServiceAdjustment, LastPeriodAdjustment, Object.SaleAdjustment2_5);
			If ChoiceList.Find(TableRow.OptionToReflectWriteOff) = Undefined Then
				TableRow.OptionToReflectWriteOff = Enums.OptionsOfPostingReceiptAdjustingEntries.EmptyRef();
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency)
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date,CurrentSessionDate());
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
	
	If Not ValueIsFilled(Object.Terms) Then
		Object.ARAPCurrency = Object.Currency;
	EndIf;

	LocalDataForRecalculatingAmount = GetParametersForRecalculatingLocalAmount(ThisObject, "After");
	DataForRecalculatingManSAmount = GetParametersForRecalculatingManSAmount(ThisObject, "After");

	StructureOfActions = New Structure;
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("ClearAmountOfSettlementsSuffix", "After");
	
	StructureOfActions.Insert("RecalculateAmountWithoutVATLocal", LocalDataForRecalculatingAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVATMan", DataForRecalculatingManSAmount);
	
	StructureOfActions.Insert("RecalculateAmountWithoutVATLocalSuffix", LocalDataForRecalculatingAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVATManSuffix", DataForRecalculatingManSAmount);

	BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions, Undefined);
	
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	AutoTitle = False;
	TitleTemplate1 = NStr("vi = 'Điều chỉnh bán hàng trước khi nhập số dư %1';
							|ru = 'Корректировка реализации до ввода остатков %1';
							|en = 'Sales adjustment before balance entry %1'; fa = 'Sales adjustment before balance entry %1';
							|it = 'Correzione vendita prima dell''inserimento dei saldi %1';
							|pl = 'Korektę sprzedaży przed wprowadzeniem sald %1';
							|tr = '%1 bakiyeleri girmeden önce satış düzeltmesi'");
	
	If ValueIsFilled(Object.Ref) Then
		EndOfTitle = NStr("vi = '%1 ngày %2';
							|ru = '%1 от %2';
							|en = '%1 dated %2'; fa = '%1 dated %2';
							|it = '%1 del %2';
							|pl = '%1 z dn. %2';
							|tr = '%2 tarihli %1'");
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

&AtClient
Procedure SetWhetherWarehouseIsFull()
	
	WarehouseIsRequired = ?(AdjustmentTable.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

&AtServer
Procedure UpdateVHFWarehouseObligation()
	
	FillParameters = New Structure("ThereAreWorks, IsCanceled", True, False);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("WhenChangingProductType", FillParameters);
	BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions, Undefined);
	
	WarehouseIsRequired = ?(AdjustmentTable.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

&AtServer
Procedure EstablishRelationshipOfSelectionParametersForUnitsOfMeasurement()
	
	NewArray = New Array();
	
	If Not OtherAssetServiceAdjustment Then
		NewLink = New ChoiceParameterLink("Products", "Items.AdjustmentTable.CurrentData.Products");
		NewArray.Add(NewLink);
	EndIf;
	
	Items.AdjustmentTablePackage.ChoiceParameterLinks = New FixedArray(NewArray);
	
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

#EndRegion

&AtServer
Procedure UpdateTextOfInvoiceIssued()
	
	ParametersForRegisteringIssuedSF = Documents.SaleAdjustment.ParametersForRegisteringInvoicesIssued(Object);
	ParametersForRegisteringReceivedSF = Documents.SaleAdjustment.ParametersForRegisteringInvoicesReceived(Object);
	InvoiceBasedOn = VATAccountingERP.InvoicesGeneralOnBasisOf(ParametersForRegisteringIssuedSF, ParametersForRegisteringReceivedSF);
	
	TextDocumentsBasedOnFooter = SalesServer.CreatePresentationOfInvoiceGenerationCommandsBasedOn(Object.Ref, InvoiceBasedOn);
	
	TextsFieldsDocumentsBasedOn.Add(TextDocumentsBasedOnFooter);

EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByTypeOfAdjustmentServer()
	
	ThisIsAdjustmentOfGoodsAndServices = Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices;
	
	Items.Warehouse.Visible = ThisIsAdjustmentOfGoodsAndServices And Not AdjustingGiver;
	
	Items.AdjustmentTableProducts.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.AdjustmentTableCharacteristic.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.AdjustmentTableSeries.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.AdjustmentTableWarehouse.Visible = ThisIsAdjustmentOfGoodsAndServices And Not AdjustingGiver;
	Items.AdjustmentTableCCDNumber.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.AdjustmentTableCCDNumberCountryOfOrigin.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.TableOfAdjustmentsGroupQuantityByRNPT.Visible = ThisIsAdjustmentOfGoodsAndServices;
	
	Items.AdjustmentTableProductsCode.Visible = ThisIsAdjustmentOfGoodsAndServices;
	Items.AdjustmentTableProductItem.Visible = ThisIsAdjustmentOfGoodsAndServices;
	
	ConnectionsOfPackagingPolicySelectionParameters = New Array;
	If ThisIsAdjustmentOfGoodsAndServices Then
		ConnectionsOfPackagingPolicySelectionParameters.Add(New ChoiceParameterLink("Products",
				"Items.AdjustmentTable.CurrentData.Products", LinkedValueChangeMode.Clear));
	EndIf;
	Items.AdjustmentTablePackage.ChoiceParameterLinks  = New FixedArray(ConnectionsOfPackagingPolicySelectionParameters);

EndProcedure

&AtServer
Procedure EstablishCostPresentation()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisObject));
	BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure SetCostPresentationInLine(CurrentRow)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisObject));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - form element.
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
	ElsIf Item.Name = Items.AdjustmentTableProducts.Name Then
		AdjustmentTableProductsOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableCharacteristic.Name Then
		AdjustmentTableCharacteristicOnChange(Item);
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
	ElsIf Item.Name = Items.AdjustmentTableVATAmount.Name Then
		AdjustmentTableVATAmountOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableVATAmountAfter.Name Then
		AdjustmentTableVATAmountAfterOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableVATRate.Name Then
		AdjustmentTableVATRateOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableVATRateAfter.Name Then
		AdjustmentTableVATRateAfterOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableWarehouse.Name Then
		AdjustmentTableWarehouseOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableDepartment.Name Then
		
	ElsIf Item.Name = Items.AdjustmentTableCCDNumber.Name Then
		AdjustmentTableCCDNumberOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableAmountExcludingVATCompl.Name Then
		AdjustmentTableAmountExcludingVATComplOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableVATExclusiveAmountLocalAfter.Name Then
		AdjustmentTableVATExclusiveAmountLocalAfterOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableAmountExcludingVATMan.Name Then
		AdjustmentTableAmountExcludingVATManOnChange(Item);
	ElsIf Item.Name = Items.AdjustmentTableVATExclusiveAmountManAfter.Name Then
		AdjustmentTableVATExclusiveAmountManAfterOnChange(Item);
	ElsIf Item.Name = Items.SubjectToExcise.Name Then
		SubjectToExciseOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - form command.
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	
	If Command.Name = Commands.OpenSelection.Name Then
		OpenSelection(Command);
	ElsIf Command.Name = Commands.SetComposition.Name Then
		SetComposition(Command);
	ElsIf Command.Name = Commands.FillThePricesByTermsOfSales.Name Then
		FillThePricesByTermsOfSales(Command);
	ElsIf Command.Name = Commands.FillInPricesOfSelectedRowsByPriceType.Name Then
		FillInPricesOfSelectedRowsByPriceType(Command);
	ElsIf Command.Name = Commands.FillInTheWarehouseInSelectedLines.Name Then
		FillInTheWarehouseInSelectedLines(Command);
	ElsIf Command.Name = Commands.FillInAdjustmentData.Name Then
		FillInAdjustmentData(Command);
	ElsIf Command.Name = Commands.InsertRows.Name Then
		InsertRows(Command);
	ElsIf Command.Name = Commands.SetComposition.Name Then
		SetComposition(Command);
	ElsIf Command.Name = Commands.EditDocumentBeingCorrected.Name Then
		EditDocumentBeingCorrected(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Command);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - form element.
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
	
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	
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
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Item.Name = Items.AdjustmentTable.Name  Then
		AdjustmentTableBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Function PerformChecksBeforeChangingStatus()
	
	Var ThereAreAdjustingEntries;
	
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
	
	CheckForAdjustments(Object.Ref, Object.DocumentBasis, ThereAreAdjustingEntries, TypeOfPreviousAdjustment);
	
	If ThereAreAdjustingEntries Then
		ButtonsList = New ValueList;
		ButtonsList.Add("EnterTheAdjustment", NStr("vi = 'Nhập điều chỉnh';
													|ru = 'Ввести корректировку';
													|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
													|it = 'Inserire rettifica';
													|pl = 'Wprowadź korektę';
													|tr = 'Bir düzeltme yapın'"));
		ButtonsList.Add("UndoChanges", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Trên cơ sở chứng từ đã nhập điều chỉnh giao hàng.
				|Cấm thay đổi chứng từ gốc.';
				|ru = 'На основании документа введена корректировка реализации.
				|Изменение исходного документа запрещено.';
				|en = 'Sales adjustment is generated from base document.
				|Editing the original document is not allowed.'; fa = 'Sales adjustment is generated from base document.
				|Editing the original document is not allowed.';
				|it = 'In base al documento è stata inserita una rettifica di realizzo.
				|La modifica del documento originale non è consentita.';
				|pl = 'Na podstawie dokumentu wprowadzono korektę sprzedaży.
				|Zmiana dokumentu źródłowego jest zabroniona.';
				|tr = 'Temel belgeye bir satış düzeltmesi girilmiştir. 
				|Orijinal belge değiştirilemez.'"),
			ButtonsList,
			,
			"EnterTheAdjustment");
		
	Else
		RunCallback(Notification, "ChangeAttribute");
		
		PropsCanBeChanged = True;
	EndIf;
	
	Return PropsCanBeChanged;
	
EndFunction

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
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
	
	If Not PerformChecksBeforeChangingStatus() Then
		Cancel = True;
		
		Return;
	EndIf;
	
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
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not PerformChecksBeforeChangingStatus() Then
		Cancel = True;
		
		Return;
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeAddRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group, Undefined);
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
	
	If OtherAssetServiceAdjustment Then
		Columns = "Content,NumberOfPackages,Count,Price,Sum,QuantityAfter,PriceAfter,AmountAfter,NumberOfPackagesAfter,
			|AmountARAP,AmountOfSettlementsAfter,OptionToReflectWriteOff,PostingOption,IncomeItem,DimensionOfRevenue,
			|CostExcludingVAT_,CostLocal";
	Else
		Columns = "Products,Characteristic,Content,Package,NumberOfPackages,Count,Price,Warehouse,CCDNumber,
			|Department,ProductsInSet,ItemVariantOfSet,NumberOfPackagesAfter,QuantityAfter,PriceAfter,
			|AmountARAP,AmountOfSettlementsAfter,OptionToReflectWriteOff,PostingOption,IncomeItem,DimensionOfRevenue,
			|MethodForDeterminingTheCostOfALine,CostDefiningMethod,Cost_,CostExcludingVAT_,CostLocal,
			|CDCost,TDCost,CostPriceKind,DateOfCostFillingByPriceType";
	EndIf;
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(, Columns);

	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	ParametersFillInVATRate.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffix", ParametersFillInVATRate);
		
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.Suffix = Suffix;
	ParametersFillInVATRate.Partner = Object.Partner;
	ParametersFillInVATRate.Terms = Object.Terms;
	ParametersFillInVATRate.FillInPriceView = True;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffixByPriceType", ParametersFillInVATRate);
	
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	If NumberOfPackagesIsUsed Then
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject, Suffix);
	Else
		AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisObject);
		AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisObject, Suffix);
	EndIf;
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);

	ParametersForCheckingPriceType = New Structure("PriceIncludesVAT, UseWhileSellingToCustomers, Status", Object.PriceIncludesVAT, True, Enums.StatusesOfPriceTypeValidity.Valid);
	
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

		CurrentRow = AdjustmentTable.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
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
		AdjustmentTable);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(AdjustmentTable, StructureCharacteristicsOfProducts);
	SetsServer.FillInServiceDetails(ThisObject, "AdjustmentTable");
	PurchasesServer.FillInServiceAttributesOfCCDNumber(AdjustmentTable);
	
	WarehouseData_2 = GetDataOnWarehouses();
	For Each TSRow In AdjustmentTable Do
		WarehouseData_1 = WarehouseData_2.Find(TSRow.Warehouse);
		If WarehouseData_1 <> Undefined Then
			TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
	EndDo;
	
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
Procedure PrepareFillSetSeriesVisibility()
	
	ParametersForSpecifyingDocumentSeries = ProductsServer.SeriesSpecificationParameters(Object, Documents.SaleAdjustment);
	
	SeriesSpecificationParameters = ParametersForSpecifyingDocumentSeries.Goods;
	SeriesSpecificationParameters.NameTSGoods = "AdjustmentTable";
	SeriesSpecificationParameters.TSSeriesName = "AdjustmentTable";
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.AdjustmentTableSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties




#EndRegion

#Region CheckingDocumentFilling

&AtServer
Procedure CheckForDuplicateRowsInTableAndDeleteSeries(Cancel)
	
	KeyAttributes = Documents.SaleAdjustment.KeyAttributesOFRelationshipOfTableRows(OtherAssetServiceAdjustment);
	
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

// Fills in the sales conditions in the adjustment of sales
//
// Parameters:
//	SalesTermsAndConditions - Structure - data to fill in.
//
&AtServer
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions)
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	Object.Currency = SalesTermsAndConditions.Currency;
	Object.ARAPCurrency = SalesTermsAndConditions.ARAPCurrency;
	Object.PriceIncludesVAT = SalesTermsAndConditions.PriceIncludesVAT;
	
	OrganizationChanged = ValueIsFilled(SalesTermsAndConditions.Organization) And SalesTermsAndConditions.Organization <> Object.Organization;
	PaymentFormChanged = ValueIsFilled(SalesTermsAndConditions.PaymentMethod) And SalesTermsAndConditions.PaymentMethod <> Object.PaymentMethod;
	
	Object.PaymentMethod = SalesTermsAndConditions.PaymentMethod;
	
	If OrganizationChanged Then
		Object.Organization = SalesTermsAndConditions.Organization;
	EndIf;
	
	If OrganizationChanged Or PaymentFormChanged Then
		
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
			ParametersOfAccount);
		
	EndIf;
	
	Counterparty = Object.Counterparty;
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.Counterparty) And SalesTermsAndConditions.Counterparty<>Object.Counterparty Then
			Object.Counterparty = SalesTermsAndConditions.Counterparty;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	If Counterparty <> Object.Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Object.Counterparty);
		Object.CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(
			ParametersOfAccount);
	EndIf;
	
	If SalesTermsAndConditions.ContractsAreUsed <> Undefined And SalesTermsAndConditions.ContractsAreUsed Then
		
		Object.Contract = SalesServer.GetDefaultContract(
			Object,
			Enums.BusinessTransactions.SaleToCustomer,
			Object.ARAPCurrency);
			
		SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
		
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	If ValueIsFilled(SalesTermsAndConditions.Warehouse) Then
		Object.Warehouse = SalesTermsAndConditions.Warehouse;
		StructureOfResponsible = SalesServer.GetWarehouseManager(Object.Warehouse);
		If StructureOfResponsible <> Undefined Then
			Object.IssuiedBy = StructureOfResponsible.EmployeeResponsible;
			Object.IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
		EndIf;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
		Object.FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
	EndIf;
	
EndProcedure

// Fills in the terms of sales by agreement in the adjustment of sales.
//
&AtServer
Procedure FillInTermsOfSalesUnderAgreement()
	
	Suffix = "After";
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Object.Terms, True, True);
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
	FillParameters = Documents.SaleAdjustment.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters);
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.Suffix = Suffix;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffix", ParametersForFillingInVATRate);
		
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
	ParametersFillInVATRate.Suffix = Suffix;
	ParametersFillInVATRate.Partner = Object.Partner;
	ParametersFillInVATRate.Terms = Object.Terms;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateSuffixByPriceType", ParametersFillInVATRate);
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("ReturnReusablePackage", ToReturnReusablePackage);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, VATRate");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		AdjustmentTable, // Table part
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
		
	If PricesCalculated Then
		StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmountSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSuffixAmount", 
				New Structure ("Suffix, QuantityName", 
									Suffix, 
									?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count")));
		StructureOfActions.Insert("ClearAmountOfSettlements", Suffix);
		
		For Each String In AdjustmentTable Do
			String.PriceAfter = String.Price;
		EndDo;
		BatchProcessingOfTablePartServer.TreatTS(AdjustmentTable, StructureOfActions);

	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Object.Counterparty);
	Object.CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(
		ParametersOfAccount, Object.CounterpartyBankAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		ParametersOfAccount, Object.CompanyBankAccount);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionResultCompletion(ResponseCode, AdditionalParameters) Export
	
	If ResponseCode = "EnterTheAdjustment" Then
		OpeningParameters = New Structure("Basis", Object.DocumentBasis);
		
		OpenForm("Document.SaleAdjustment.Form.DocumentFormBeforeBalanceEntry",
					OpeningParameters);
	EndIf;
	
	CalculateFinalImplementationIndicators(ThisObject);
	
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
Procedure SetSelectionParametersAdjustmentTableWarehouse()
	
	Items.AdjustmentTableWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	WarehouseSelectionData = WarehouseSelectionData(Object.Warehouse);
	
	TMCommonUseClientServer.AddSelectionParameter(Items.AdjustmentTableWarehouse, "Ref", WarehouseSelectionData);
	
EndProcedure

&AtServer
Procedure FillInBusinessTransactionOfFoundationDocument()
	
	Operation = Documents.SaleAdjustment.EconomicOperationOfFoundationDocument(Object.DocumentBasis);
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Function InvoiceRegistrationParameters()
	
	Result = New Structure;
	Result.Insert("Issued", Documents.SaleAdjustment.ParametersForRegisteringInvoicesIssued(Object)); 	
	Result.Insert("Received", Documents.SaleAdjustment.ParametersForRegisteringInvoicesReceived(Object)); 	
	
	Return Result;
EndFunction

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure LoadAdjustmentTableFromDocumentDataOnServer()
	
	ResultTable2 = Documents.SaleAdjustment.AdjustmentDataBeforeEnteringBalances(Object, NumberOfPackagesIsUsed);
	
	AdjustmentTable.Load(ResultTable2);
	
EndProcedure

&AtClient
Procedure UploadAdjustmentTableToDocumentData()
	
	Object.Goods.Clear();
	Object.Discrepancies.Clear();
	
	TaxationWithoutVAT_ = VATAccountingERPClientServer.TypesOfTaxationThatHideVATDetails();
	ClearLocalAndManAmounts = False;
	
	If TaxationWithoutVAT_.Find(Object.VATTaxation) = Undefined Then
		ClearLocalAndManAmounts = True;
	EndIf;
	
	For Each RowOfAdjustmentTable In AdjustmentTable Do
		
		If ClearLocalAndManAmounts Then
			RowOfAdjustmentTable.AmountExcludingVATCompl = 0;
			RowOfAdjustmentTable.AmountExcludingVATMan = 0;
			RowOfAdjustmentTable.VATExclusiveAmountLocalAfter = 0;
			RowOfAdjustmentTable.VATExclusiveAmountManAfter = 0;
		EndIf;
		
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
		LineProducts_.AmountExcludingVATCompl = RowOfAdjustmentTable.VATExclusiveAmountLocalAfter;
		LineProducts_.AmountExcludingVATMan = RowOfAdjustmentTable.VATExclusiveAmountManAfter;
		
		If Object.Currency = Object.ARAPCurrency
			And RowOfAdjustmentTable.AmountOfSettlementsAfter <> 0
			And RowOfAdjustmentTable.AmountARAP = 0
			And RowOfAdjustmentTable.Count <> 0 Then
			RowOfAdjustmentTable.AmountOfSettlementsAfter = 0;
		EndIf;

		LineProducts_.AmountARAP = RowOfAdjustmentTable.AmountOfSettlementsAfter;
				
	EndDo;
	
	For Each RowOfAdjustmentTable In AdjustmentTable Do
		
		NumberOfPackages	= RowOfAdjustmentTable.NumberOfPackagesAfter - RowOfAdjustmentTable.NumberOfPackages;
		Count			= RowOfAdjustmentTable.QuantityAfter - RowOfAdjustmentTable.Count;
		QuantityByGBRN	= RowOfAdjustmentTable.QuantityAccordingToRNPTAfter - RowOfAdjustmentTable.QuantityByGBRN;
		Sum				= RowOfAdjustmentTable.AmountAfter - RowOfAdjustmentTable.Sum;
		VATAmountDiscrepancy	= RowOfAdjustmentTable.VATAmountAfter - RowOfAdjustmentTable.VATAmount;
		AmountIncludingVAT			= RowOfAdjustmentTable.AmountWithVATAfter - RowOfAdjustmentTable.AmountIncludingVAT;
		AmountExcludingVATCompl		= RowOfAdjustmentTable.VATExclusiveAmountLocalAfter - RowOfAdjustmentTable.AmountExcludingVATCompl;
		AmountExcludingVATMan		= RowOfAdjustmentTable.VATExclusiveAmountManAfter - RowOfAdjustmentTable.AmountExcludingVATMan;
		
		If Not UseCostAccounting 
			And Not ValueIsFilled(RowOfAdjustmentTable.CostDefiningMethod) Then
			RowOfAdjustmentTable.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromCurrentDocument");
		EndIf;
		
		If Object.Currency = Object.ARAPCurrency
			And RowOfAdjustmentTable.AmountARAP <> 0
			And RowOfAdjustmentTable.AmountOfSettlementsAfter = 0
			And RowOfAdjustmentTable.QuantityAfter <> 0 Then
				RowOfAdjustmentTable.AmountARAP = 0;
		EndIf;
		
		AmountARAP	= RowOfAdjustmentTable.AmountOfSettlementsAfter - RowOfAdjustmentTable.AmountARAP;
		
		DifferentVATRates = RowOfAdjustmentTable.VATRate <> RowOfAdjustmentTable.VATRateAfter
			And (RowOfAdjustmentTable.QuantityAfter > 0
				Or RowOfAdjustmentTable.AmountWithVATAfter > 0
				Or RowOfAdjustmentTable.AmountOfSettlementsAfter > 0
				Or RowOfAdjustmentTable.VATAmountAfter > 0);
		
		If NumberOfPackages <> 0 
				Or Count <> 0 
				Or QuantityByGBRN <> 0 
				Or Sum <> 0 
				Or VATAmountDiscrepancy <> 0 
				Or AmountIncludingVAT <> 0
				Or AmountARAP <> 0
				Or DifferentVATRates Then
		
			If RowOfAdjustmentTable.VATRateAfter = RowOfAdjustmentTable.VATRate Then
				DivergenceLine = Object.Discrepancies.Add();
				FillPropertyValues(DivergenceLine, RowOfAdjustmentTable);
				DivergenceLine.NumberOfPackages = NumberOfPackages;
				DivergenceLine.Count = Count;
				DivergenceLine.QuantityByGBRN = QuantityByGBRN;
				DivergenceLine.Sum = Sum;
				DivergenceLine.VATAmount = VATAmountDiscrepancy;
				DivergenceLine.AmountIncludingVAT = AmountIncludingVAT;
				DivergenceLine.AmountARAP = AmountARAP;
				DivergenceLine.AmountExcludingVATCompl = AmountExcludingVATCompl;
				DivergenceLine.AmountExcludingVATMan = AmountExcludingVATMan;
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
					DivergenceLine.AmountExcludingVATCompl = -RowOfAdjustmentTable.AmountExcludingVATCompl;
					DivergenceLine.AmountExcludingVATMan = -RowOfAdjustmentTable.AmountExcludingVATMan;
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
					DivergenceLine.AmountExcludingVATCompl = RowOfAdjustmentTable.AmountExcludingVATCompl;
					DivergenceLine.AmountExcludingVATMan = RowOfAdjustmentTable.AmountExcludingVATMan;
					
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearServiceDataOfDebitedImportedGoods()
	
	DefaultValue = New Structure;
	DefaultValue.Insert("CCDNumber",				Undefined);
	DefaultValue.Insert("QuantityByGBRN",		0);
	DefaultValue.Insert("QuantityAccordingToRNPTAfter",	0);
	
	For Each TSRow In AdjustmentTable Do
		If TSRow.PostingOption <> PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome")
			And (TSRow.VATRate = TSRow.VATRateAfter
				Or TSRow.Count = 0)
			And (TSRow.QuantityAfter > TSRow.Count
				Or TSRow.NumberOfPackagesAfter > TSRow.NumberOfPackages) Then
			
			FillPropertyValues(TSRow, DefaultValue);
			
		EndIf;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateServiceFieldsOfValueTable(Form)
	
	If Form.AdjustmentTable.Count() = 0 Then
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
									|tr = 'Düzeltme verileri (%1)'"), Form.AdjustmentTable.Count());
	EndIf;
	
	Form.Items.GroupTableAdjustments.Title = TitleText;
	
	For Each CurrentRow In Form.AdjustmentTable Do
		CurrentRow.LineNumber = Form.AdjustmentTable.IndexOf(CurrentRow)+1;
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
	
	CurrentRow.LineNumber = AdjustmentTable.IndexOf(CurrentRow) + 1;
	
EndProcedure

&AtServer
Procedure SetTypeOfAdjustment()
	
	If Not ValueIsFilled(Object.AdjustingEntryType) Then
		Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices;
	EndIf;
	
	TypeOfAdjustmentIsOld = Object.AdjustingEntryType;
	
	Items.AdjustingEntryType.Enabled = Not ValueIsFilled(TypeOfPreviousAdjustment);
	
EndProcedure

&AtServer
Procedure ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails()
	
	Object.Goods.Clear();
	Object.Discrepancies.Clear();
	Object.PackageBarcodes.Clear();
	Object.ARAPAdjustment.Clear();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtServer
Procedure FillInCostAccountingAttribute()
	
	UseCostAccounting = CalculationOfCostCached.CostCalculationIsPossible(Object.Date);
	
EndProcedure

&AtServer
Procedure UpdateInformationWhenCostPriceChanges()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	EstablishCostPresentation();
	
EndProcedure

&AtClientAtServerNoContext
Function CostDeterminationParameters(Form)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("VATTaxation", Form.Object.VATTaxation);
	ParametersStructure.Insert("ManagementAccountingCurrency", Form.ManagementAccountingCurrency);
	ParametersStructure.Insert("LocalAccountingCurrency", Form.LocalAccountingCurrency);
	ParametersStructure.Insert("UseLocal",  Form.UseLocal);
	
	Return ParametersStructure
	
EndFunction

&AtClient
Procedure FillInCostInTable()
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Counterparty", Object.Counterparty);
	FormParameters.Insert("Contract", Object.Contract);
	FormParameters.Insert("Terms", Object.Terms);
	FormParameters.Insert("DocumentCurrency", Object.Currency);
	FormParameters.Insert("TaxationType", Object.VATTaxation);
		
	SelectedRows = Items.AdjustmentTable.SelectedRows;
	RowsOfProductsTable = New Array();
	
	For Each CurRowId_ In SelectedRows Do
		
		TableRow = AdjustmentTable.FindByID(CurRowId_);
		RowParameters = New Structure();
		If TableRow.VATRate = TableRow.VATRateAfter Then
			NumberOfPackages = TableRow.NumberOfPackages - TableRow.NumberOfPackagesAfter;
		Else
			NumberOfPackages = TableRow.NumberOfPackages;
		EndIf;
		
		RowParameters.Insert("Id", CurRowId_);
		RowParameters.Insert("CostDefiningMethod", TableRow.CostDefiningMethod);
		RowParameters.Insert("PriceKind", TableRow.CostPriceKind);
		RowParameters.Insert("DateOfCostFillingByPriceType", TableRow.DateOfCostFillingByPriceType);
		RowParameters.Insert("NumberOfPackages", NumberOfPackages);
		RowParameters.Insert("Package", TableRow.Package);
		RowParameters.Insert("Products", TableRow.Products);
		RowParameters.Insert("Characteristic", TableRow.Characteristic);
		RowParameters.Insert("VATRate", TableRow.VATRate);
		RowParameters.Insert("AmountIncludingVAT", TableRow.Cost_);
		RowParameters.Insert("AmountExcludingVAT", TableRow.CostExcludingVAT_);
		RowParameters.Insert("SumCompl", TableRow.CostLocal);
		RowParameters.Insert("AmountPermanentDifferences", TableRow.CDCost);
		RowParameters.Insert("AmountTemporaryDifferences", TableRow.TDCost);
		RowsOfProductsTable.Add(RowParameters);
		
	EndDo;
	
	FormParameters.Insert("RowsOfProductsTable", RowsOfProductsTable);
	
	OpenForm("Document.SaleAdjustment.Form.SelectionFormOfCostDefiningMethod",
		FormParameters,
		ThisObject,,,,
		New CallbackDescription("ChoosingMethodForDeterminingCostOfProduction",
				ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

// Parameters:
// 	SelectionResult - Structure - goods row data:
// 		* RowsOfProductsTable - Array of See TMCommonUseClient.NewElementArrayProducts
// 	AdditionalParameters - Undefined - not analyzed
&AtClient
Procedure ChoosingMethodForDeterminingCostOfProduction(SelectionResult, AdditionalParameters) Export
	
	If TypeOf(SelectionResult) = Type("Structure") Then
		Rows = SelectionResult.RowsOfProductsTable;
		For Each String In Rows Do
			TableRow = AdjustmentTable.FindByID(String.Id);
			If TableRow <> Undefined Then
				FillPropertyValues(TableRow, String);
			EndIf;
		EndDo;
		UpdateInformationWhenCostPriceChanges();
		Modified = True;
	EndIf;
	
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
																			"TableOfAdjustmentsGroupQuantityByRNPT");
	
	Items.TableOfAdjustmentsGroupQuantityByRNPT.Visible = Items.TableOfAdjustmentsGroupQuantityByRNPT.Visible
																And Not OtherAssetServiceAdjustment;
	
EndProcedure

&AtClient
Procedure OpenBaseSelectionForm()
	
	StructureFilter = New Structure;
	StructureFilter.Insert("Posted", True);
	StructureFilter.Insert("SourceDocumentType", PredefinedValue("Enum.SourceDocumentTypes.SaleToCustomer"));
	StructureFilter.Insert("Counterparty", Object.Counterparty);
	StructureFilter.Insert("Partner", Object.Partner);
	StructureFilter.Insert("VATTaxation", Object.VATTaxation);
	
	OpenForm(
		"Document.SourceDocument.ChoiceForm",
		New Structure("Filter", StructureFilter),
		ThisObject);
	
EndProcedure

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
		
	OpenForm("Document.SaleAdjustment.Form.ChoiceFormOfCorrectedDocument", ListParameters, ThisObject);
	
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

&AtClientAtServerNoContext
Function GetParametersForRecalculatingLocalAmount(CurrentForm, Suffix = "")
	
	DocumentObject = CurrentForm.Object;
	
	LocalDataForRecalculatingAmount = New Structure();
	LocalDataForRecalculatingAmount.Insert("PriceIncludesVAT", DocumentObject.PriceIncludesVAT);
	LocalDataForRecalculatingAmount.Insert("ByAmountOfDocument", DocumentObject.Currency = CurrentForm.LocalAccountingCurrency);
	LocalDataForRecalculatingAmount.Insert("ConversionRatioFromDocumentCurrency", CurrentForm.LocalRateByBasisDocument);
	LocalDataForRecalculatingAmount.Insert("Suffix", Suffix);
	
	Return LocalDataForRecalculatingAmount;

EndFunction

&AtClientAtServerNoContext
Function GetParametersForRecalculatingManSAmount(CurrentForm, Suffix = "")
	
	DocumentObject = CurrentForm.Object;
	
	DataForRecalculatingManSAmount = New Structure();
	DataForRecalculatingManSAmount.Insert("PriceIncludesVAT", DocumentObject.PriceIncludesVAT);
	DataForRecalculatingManSAmount.Insert("ByAmountOfDocument", DocumentObject.Currency = CurrentForm.ManagementAccountingCurrency);
	DataForRecalculatingManSAmount.Insert("ConversionRatioFromDocumentCurrency", CurrentForm.ManRateByBasisDocument);
	DataForRecalculatingManSAmount.Insert("Suffix", Suffix);

	Return DataForRecalculatingManSAmount;
	
EndFunction

&AtServer
Procedure FillInVATTaxationATServer()
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByAdjustingImplementation2_5()
	
	Items.MoveDocumentToNewOrderOfReflectionInAccounting.Visible = Not Object.SaleAdjustment2_5;
	Items.ReflectionInAccounting_.Visible = Object.SaleAdjustment2_5;
	Items.OtherIncomeExpensesGroup.Visible = Not Object.SaleAdjustment2_5;
	
	Items.AdjustmentTableGroupOfReflectionOptions.Visible = Not Object.SaleAdjustment2_5;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfItemsByAccountingPolicy()
	
	Items.RecordInProfitLossOfPreviousYears.Enabled = LastPeriodAdjustment;
	
	
EndProcedure

&AtServer
Procedure UpdateOptionsForReflectingDiscrepancies2_5()
	ThisIsAdjustmentOfReportToGiver = Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5;
	ItemTypesWithoutTakingIntoAccountOrderScheme = New Array;
	ItemTypesWithoutTakingIntoAccountOrderScheme.Add(Enums.ItemsTypes.OperationService);
	ItemTypesWithoutTakingIntoAccountOrderScheme.Add(Enums.ItemsTypes.Work_5);
	
	For Each CurRow In AdjustmentTable Do
		
		If CurRow.Count < CurRow.QuantityAfter Then
			If ItemTypesWithoutTakingIntoAccountOrderScheme.Find(CurRow.ItemsType) <> Undefined
				Or ThisIsAdjustmentOfReportToGiver
				Or False Then
				CurRow.PostingOption = Enums.CreditNoteRecordingOptions.IncreaseSale;
			Else
				If CurRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
					CurRow.PostingOption = Enums.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount;
				Else
					CurRow.PostingOption = Enums.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock;
				EndIf;
			EndIf;
		ElsIf CurRow.Count > CurRow.QuantityAfter Then
			If ItemTypesWithoutTakingIntoAccountOrderScheme.Find(CurRow.ItemsType) <> Undefined
				Or ThisIsAdjustmentOfReportToGiver
				Or False Then
				CurRow.PostingOption = Enums.CreditNoteRecordingOptions.ReduceSale;
			Else
				If CurRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
					CurRow.PostingOption = Enums.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount;
				Else
					CurRow.PostingOption = Enums.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock;
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateAttributesOfAccountingDocument()
	
	If OrderOfReflection = "Revenue" And Object.RecordInProfitLossOfPreviousYears Then
		Object.RecordInProfitLossOfPreviousYears = False;
	ElsIf OrderOfReflection = "OtherIncome" And Not Object.RecordInProfitLossOfPreviousYears Then
		Object.RecordInProfitLossOfPreviousYears = True;
	EndIf;
	
	
EndProcedure

&AtServer
Procedure UpdateReflectionInAccountingByDocumentAttributes()
	
	If Object.RecordInProfitLossOfPreviousYears Then
		OrderOfReflection = "OtherIncome";
	Else
		OrderOfReflection = "Revenue";
	EndIf;
	
	
EndProcedure

&AtServer
Procedure UpdateTrackingReflectionHeader()
	
	TitleReflectionInAccounting = NStr("ru = 'Отражение в учете: %1%2';
										|vi = 'Accounting attributes: %1%2';
										|en = 'Accounting attributes: %1%2'; fa = 'Accounting attributes: %1%2';
										|it = 'Accounting attributes: %1%2';
										|pl = 'Accounting attributes: %1%2';
										|tr = 'Muhasebeye yansıtma: %1%2'");
	
	If Object.RecordInProfitLossOfPreviousYears Then
		ReflectionOfAC = NStr("ru = 'БУ - прочие доходы';
								|vi = 'LA - other income';
								|en = 'LA - other income'; fa = 'LA - other income';
								|it = 'LA - other income';
								|pl = 'LA - other income';
								|tr = 'Genel Muhasebe - diğer gelirler'");
	Else
		ReflectionOfAC = NStr("ru = 'БУ - выручка';
								|vi = 'LA - revenue';
								|en = 'LA - revenue'; fa = 'LA - revenue';
								|it = 'LA - revenue';
								|pl = 'LA - revenue';
								|tr = 'Genel Muhasebe - gelir'");
	EndIf;
	
	ReflectionTA = "";
	
	
	Items.ReflectionInAccounting_.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TitleReflectionInAccounting,
		ReflectionOfAC,
		ReflectionTA);
	
EndProcedure

#Region Localization

&AtClient
Procedure NotificationProcessingLocalization(EventName, Parameter, Source)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessingLocalization(FormattedStringURL, StandardProcessing)
	

	Return;
	
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

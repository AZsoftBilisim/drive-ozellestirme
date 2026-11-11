#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var ParametersForRecording Export;

&AtClient
Var CurDataId;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	// GLAccountSettings
	SetupParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	// End GLAccountSettings
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	SetAvailabilityOfClipboardCommands(ThisObject, ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
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
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	AddSBPPaymentStatusUpdateCommand();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	// GLAccountSettings
	SetupParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	// End GLAccountSettings
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// The end of the handler of the "Date-change" mechanism
	
	// StandardSubsystems.Properties	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
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
	
	CashClientLocalization.AttachablePaymentVerificationViaServices(ThisObject, Object.Ref, Object.MaterialProvider);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		UpdateInvoiceText();
	ElsIf ChoiceSource <> Undefined
		And TypeOf(ChoiceSource) = Type("ClientApplicationForm") 
		And ChoiceSource.FormName = "CommonForm.EnterCostShare" Then
		
		CurrentData = CurrentItem.CurrentData;
		If CurrentData = Undefined Then
			Return;
		EndIf;
		
		Modified = True;
		ProcessingInputOfFractionOfCost(CurrentItem, CurrentData, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		If ValueSelected <> Undefined Then
			Modified = True;
			FillPropertyValues(Object, ValueSelected);
		EndIf;
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			TSName = "Goods";
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter), TSName);
			
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
		ChangedPaymentServer(EventName, Parameter);
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommands(ThisObject, True);
	EndIf;
	
	If EventName = "SBPStatusHasBeenChanged" Then
		AddSBPPaymentStatusUpdateCommand();
		CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.MaterialProvider);
	EndIf;
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	// GLAccountSettings
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End GLAccountSettings
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInServiceDetails("Goods");
	
	UpdateInvoiceText();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	// The end of the selection of articles and analytics.
	
	// GLAccountSettings
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	// End GLAccountSettings
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject, CurrentObject.AdditionalProperties);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_ConsumptionReportSubcontractingServicesDeliveredIntercompany", WriteParameters, Object.Ref);
	
	ARAPAccountingClient.FormAfterRecording(ThisObject);
	
	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	If Exit Then
		Return;
	EndIf;

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
	CashClientLocalization.DisablePaymentVerificationViaServices(ThisObject);

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
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
			And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure


#Region IsMain

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	If Not ProcessorBeforeChange = Object.Organization Then
		OrganizationWhenChangedOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialProviderOnChange(Item)
	
	If Not GiverBeforeChange = Object.MaterialProvider Then
		GiverWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	AgreementWhenModifiedOnServer();
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisObject, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LabelPaymentMilestonesOfProcessorClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisObject, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure InscriptionPaymentMilestonesGiverClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisObject, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure CalculationsClickSender(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ArrayBuyers = New Array();
	ArrayBuyers.Add(Object.MaterialProvider);
	ArraySuppliers = New Array();
	ArraySuppliers.Add(Object.Organization);
	
	FilterValues = New Structure("Customer, Seller", ArrayBuyers, ArraySuppliers);
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey",            "SalesPayments");
	FormParameters.Insert("PurposeUseKey");
	FormParameters.Insert("Filter",                   FilterValues);
	FormParameters.Insert("GenerateOnOpen", True);
	
	If NewOnlineARAPAccounting Then
		FormParameters.Filter.Insert("ARAPObject", Object.ARAPObject);
		OpenForm("Report.AccountsPayablesAndReceivablesByIntercompany.Form", FormParameters);
	Else
		FormParameters.Filter.Insert("DocumentOfARAPAccounting", Object.ARAPObject);
		OpenForm("Report.IntercompanyARAP.Form", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculationsClickRecipient(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ArrayBuyers = New Array();
	ArrayBuyers.Add(Object.MaterialProvider);
	ArraySuppliers = New Array();
	ArraySuppliers.Add(Object.Organization);
	
	FilterValues = New Structure("Customer, Seller", ArrayBuyers, ArraySuppliers);
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey",            "ProcurementPayments");
	FormParameters.Insert("PurposeUseKey");
	FormParameters.Insert("Filter",                   FilterValues);
	FormParameters.Insert("GenerateOnOpen", True);
	
	If NewOnlineARAPAccounting Then
		FormParameters.Filter.Insert("ARAPObject", Object.ARAPObjectOfRecipient);
		OpenForm("Report.AccountsPayablesAndReceivablesByIntercompany.Form", FormParameters);
	Else
		FormParameters.Filter.Insert("DocumentOfARAPAccounting", Object.ARAPObjectOfRecipient);
		OpenForm("Report.IntercompanyARAP.Form", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure TextInvoiceURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	RegistrationParameters.Ref      = Object.Ref;
	RegistrationParameters.Date        = Object.Date;
	RegistrationParameters.Organization = Object.Organization;
	RegistrationParameters.Counterparty  = Object.MaterialProvider;
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(
		ThisObject, Var_URL, StandardProcessing, RegistrationParameters);
	
EndProcedure

#EndRegion

#Region More

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATWhenChangedOnServer(CachedValues);
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CostsAllocationMethodOnChange(Item)
	
	MethodOfCostAllocationForChangesOnServer();
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Goods.CurrentData;
	
	If (Field = Items.GoodsCostSharePercentage
			Or Field = Items.GoodsThereAreErrorsOfFillingInCostShare)
		And Object.CostsAllocationMethod <> PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
		
		StandardProcessing = False;
		CurrentData = Items.Goods.CurrentData;
		OpenCostShareEntryForm(CurrentData);
		
	ElsIf Field = Items.GoodsPrice And ValueIsFilled(CurrentData.PriceKind) Then
		
		ClearMessages();
		CommonClient.MessageToUser(
			NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
				|ru = 'Для редактирования цены очистите вид цены';
				|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
				|it = 'Для редактирования цены очистите вид цены';
				|pl = 'To edit the price, clear the price type';
				|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"), Object.Ref,
			CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"));
		
	ElsIf Field = Items.GoodsSum And ValueIsFilled(CurrentData.PriceKind) Then
		
		ClearMessages();
		CommonClient.MessageToUser(
			NStr("vi = 'Để soạn số tiền, hãy xóa dạng giá';
				|ru = 'Для редактирования суммы очистите вид цены';
				|en = 'To edit the amount, clear the price type'; fa = 'To edit the amount, clear the price type';
				|it = 'Для редактирования суммы очистите вид цены';
				|pl = 'To edit the amount, clear the price type';
				|tr = 'Tutarı düzenlemek için fiyat türünü temizle'"), Object.Ref,
			CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"));
		
	ElsIf Field = Items.GoodsTransactionRecordingPresentation
		And ValueIsFilled(CurrentData.ExpenseItem) Then
		GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	EndIf;

EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Goods.CurrentData;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.Goods");
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	If ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
			Item, CostAllocationParameters, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject), NewRow) Then
		
		Groups = Undefined;
		
		CurrentData = Items.Goods.CurrentData;
		If Not CurrentData = Undefined Then
			Groups = New Array;
			Groups.Add(ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject).ProductionLot);
			Groups.Add(CurrentData.ProductionLot);
		EndIf;
		
		CalculatePercentageOfCostAllocation(Groups);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingProducts(ThisObject, StructureOfActions, "Goods");
	AddActionsToStructureWhenQuantityChanges(ThisObject, StructureOfActions, "Goods");
	
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	
	StructureOfActions.Insert(
		"FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate(Object));
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	
	StructureOfActions.Insert(
		"FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable",
		New Structure("FormName, TabularSectionName, FieldName", FormName, "Goods", "Characteristic"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsCountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	AddActionsToStructureWhenQuantityChanges(ThisObject, StructureOfActions, "Goods");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsProductionLotReferenceStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization",                    Object.Organization);
	FilterStructure1.Insert("ExcludeProductionByThirdParties", True);
	FilterStructure1.Insert("InternalSubcontracting",          True);
	FilterStructure1.Insert("MaterialProvider",                        Object.MaterialProvider);
	
	FormParameters = New Structure();
	FormParameters.Insert("BeginOfPeriod",    BegOfMonth(Object.Date));
	FormParameters.Insert("PeriodEnding", EndOfMonth(Object.Date));
	FormParameters.Insert("FilterStructure1",  FilterStructure1);
	FormParameters.Insert("SingleChoice",   True);
	
	Notification = New CallbackDescription("GoodsProductionLotReferenceStartChoiceCompletion", ThisObject);
	
	OpenForm("CommonForm.SelectProductionLots",
		FormParameters,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure GoodsProductionLotReferenceOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert(
		"FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("RecalculatePriceByAmount", "Count");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsAmountARAPOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
		CurrentData.AmountVATARAP = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPostingOptionOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentData.ToExpenseAs =
		CurrentData.PostingOption = 1;
	
	If CurrentData.ToExpenseAs Then
		
		CurrentData.PriceKind           = Undefined;
		CurrentData.Price              = 0;
		CurrentData.VATRate         = Undefined;
		CurrentData.ProductCostElement = Undefined;
		
		StructureOfActions = New Structure;
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		
		StructureOfActions.Insert("RecalculateAmount", "Count");
		StructureOfActions.Insert("ClearAmountOfSettlements");
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		
	Else
		
		StructureOfActions = New Structure;
		
		StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate(Object));
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		
	EndIf;
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "Object.Goods");
	
	// GLAccountSettings
	GLAccountSettingsClientServer.WhenChangingAccountAvailabilityDetailsInLine(ThisObject, CurrentData, "Object.Goods");
	// End GLAccountSettings
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductBatchIDOfMaterials


&AtClient
Procedure ProductBatchIDOfMaterialsLotReferenceOfProductionStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsDivisionOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsItemOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsCharacteristicOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsQuantityOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsBatchStartChoice(Item, ChoiceData, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsBatchOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsCCDNumberOnChange(Item)
	
	
	Return;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region ObjectCommands_

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

#EndRegion

#Region Goods

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer("Goods");
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard("Goods");
	
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
	
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	TableData = Object.Goods;
	FormTable  = Items.Goods;
	
	PartitioningParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	PartitioningParameters.FieldNameQuantity = "Count";
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, "Goods");
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, PartitioningParameters);
	
EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
	ClearMessages();
	
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject, "Goods");
	
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure FillInBalanceOfReportsForRegistration(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Form.DocumentForm.FillInBalanceOfReportsForRegistration");
	
	If Object.Goods.Count() = 0 Then
		FillInRestOfReportsForRegistrationOnServer(CachedValues);
	Else
		
		QueryText =
			NStr("vi = 'Sẽ điền lại danh sách ""Hàng hóa"" bằng số dư của các báo cáo dành cho người đặt ký gửi chưa được lập.
					|Tiếp tục?';
					|ru = 'Список ""Товары"" будет перезаполнен остатками неоформленных отчетов давальцу.
					|Продолжить?';
					|en = 'The ""Goods"" list will be refilled with the balances of unregistered consumption reports.
					|Continue?'; fa = 'The ""Goods"" list will be refilled with the balances of unregistered consumption reports.
					|Continue?';
					|it = 'Список ""Товары"" будет перезаполнен остатками неоформленных отчетов давальцу.
					|Продолжить?';
					|pl = 'The ""Goods"" list will be refilled with the balances of unregistered consumption reports.
					|Continue?';
					|tr = '""Ürünler"" listesi, düzenlenmemiş tedarikçi için tüketim raporlarının bakiyeleriyle yeniden doldurulacaktır.
					|Devam edilsin mi?'");
		
		ShowQueryBox(
			New CallbackDescription("FillInBalanceOfReportsForRegistrationCompletion", ThisObject),
			QueryText,
			QuestionDialogMode.YesNo);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(Command)
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Товары';
																									|pl = 'Goods';
																									|tr = 'Ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = New CallbackDescription("FillInPricesByPriceKindCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseForIntercompanySales = True;
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInProducts(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Để điền dịch vụ, bạn phải chọn dòng.';
								|ru = 'Для заполнения услуги необходимо выбрать строки.';
								|en = 'To fill in the service, select lines.'; fa = 'To fill in the service, select lines.';
								|it = 'Per compilare il servizio è necessario selezionare le righe.';
								|pl = 'Aby wypełnić usługę, musisz wybrać wiersz.';
								|tr = 'Hizmetin doldurulması için satırları seçmeniz gerekmektedir.'"));
		Return;
	EndIf;
	
	FilterParameters = New Structure("ItemsType", PredefinedValue("Enum.ItemsTypes.Work_5"));
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInProductsCompletion", ThisObject);
	OpenForm("Catalog.Products.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItem(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các hàng mà muốn điền dạng chi phí';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить статью калькуляции.';
							|en = 'Select the lines for which it is required to populate the product cost element.'; fa = 'Select the lines for which it is required to populate the product cost element.';
							|it = 'È necessario selezionare le righe per le quali si deve compilare la voce di calcolo.';
							|pl = 'Należy wybrać wiersze, dla których trzeba wypełnić pozycję kalkulacji.';
							|tr = 'Ürün maliyet kalemini doldurmanız gereken satırları seçmeniz gerekmektedir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	CostTypes = New Array;
	CostTypes.Add(PredefinedValue("Enum.CostTypes.Other"));
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ExpenseType", CostTypes);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInTheCostingItemCompletion", ThisObject);
	OpenForm("Catalog.ProductCostElements.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInProductionBatch(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng mà cần điền lô hàng sản xuất.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить партию производства.';
							|en = 'Select lines for which a production lot must be populated.'; fa = 'Select lines for which a production lot must be populated.';
							|it = 'Необходимо выбрать строки, для которых необходимо заполнить партию производства.';
							|pl = 'Select lines for which a production lot must be populated.';
							|tr = 'Необходимо выбрать строки, для которых необходимо заполнить партию производства.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization",                    Object.Organization);
	FilterStructure1.Insert("ExcludeProductionByThirdParties", True);
	FilterStructure1.Insert("InternalSubcontracting",          True);
	FilterStructure1.Insert("MaterialProvider",                        Object.MaterialProvider);
	
	FormParameters = New Structure();
	FormParameters.Insert("BeginOfPeriod",    BegOfMonth(Object.Date));
	FormParameters.Insert("PeriodEnding", EndOfMonth(Object.Date));
	FormParameters.Insert("FilterStructure1",  FilterStructure1);
	FormParameters.Insert("SingleChoice",   True);
	
	Notification = New CallbackDescription("FillInProductionBatchCompletion", ThisObject, "Goods");
	
	OpenForm("CommonForm.SelectProductionLots",
		FormParameters,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInQuantity(Command)
	
	Notification = New CallbackDescription("FillInQuantityCompletion", ThisObject);
	
	ShowInputNumber(Notification,,,, 3);
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	
	Return;
	
EndProcedure

#EndRegion

#Region ProductBatchIDOfMaterials

&AtClient
Procedure ProductBatchIDOfMaterialsToSplitString(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsInsertLines(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsCopyLines(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsBarcodeSearch(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsShouldBeFilledInAccordingToBalance(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsSpecifyBatch(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDMaterialsToFillLotReferenceOfProduction(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProductBatchIDOfMaterialsToFillOutDivision(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure FillInCCDNumberOfProductBatchIDMaterials(Command)
	
	
	Return;
	
EndProcedure

#EndRegion

#Region ARAPAccounting

&AtClient
Procedure OffsetOfProcessorSPayment(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisObject, Items.SetOffOfPaymentFormOfProcessor);
	
EndProcedure

&AtClient
Procedure OffsettingGiverSPayment(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisObject, Items.PaymentOffsetFormOfGiver);
	
EndProcedure

#EndRegion

#Region More

&AtClient
Procedure PrintDetails(Command)
	OpenPrintDetails(False);
EndProcedure

&AtClient
Procedure Attachable_UpdateSBPPaymentStatus(Command)

	ClearMessages();
	CashClientLocalization.UpdateStatusOfSBPPaymentByDocument(ThisObject, Object.Ref);

EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FormSettings

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region Goods
	
	#Region StandardAppearance
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	
	#EndRegion
	
	#Region CostShare
	
	// Setting the percentage registration
	DataPaths = New Structure;
	DataPaths.Insert("MethodOfAllocatingFinishedProductCosts", "Object.CostsAllocationMethod");
	
	ProductionServer.SetConditionalAppearanceOfShareCostPercentageField(ThisObject, "Object", "Goods",, DataPaths);
	
	#EndRegion
	
	#Region PostingOption
	
	// Reflection option - Implementation of services
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPostingOption.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PostingOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Bán dịch vụ';
													|ru = 'Реализация услуг';
													|en = 'Sale of services'; fa = 'فروش خدمات';
													|it = 'Реализация услуг';
													|pl = 'Sale of services';
													|tr = 'Hizmet satışı'"));
	
	// Reflection option - Write-off for Expenses
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPostingOption.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PostingOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm vào chi phí';
													|ru = 'Списание на расходы';
													|en = 'Incur as expenses'; fa = 'منظور به‌عنوان هزینه';
													|it = 'Storno sulle spese';
													|pl = 'Spisanie na wydatki';
													|tr = 'Gider yazma'"));
	
	#EndRegion
	
	#Region PricesAmounts
	
	// Price types
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject);
	
	// Only view when writing-off for expenses
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPriceKind.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmount.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountIncludingVAT.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductCostElement.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor",            StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text",                 NStr("vi = '<không sử dụng để ghi giảm vào chi phí>';
																	|ru = '<не используется при списании на расходы>';
																	|en = '<not used while writing off as expenses>'; fa = '<not used while writing off as expenses>';
																	|it = '<non viene usato durante storno sulle spese>';
																	|pl = '<nie używane podczas rozchodu na wydatki>';
																	|tr = '<giderlere yazılırken kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	
	// Only view the price and amount when the prices are filled in
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Price includes VAT
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject);
	
	// VAT amounts
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject);
	
	// Visibility of the amount of settlements
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountARAP.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountVATARAP.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.ARAPCurrency");
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#EndRegion
	
	
	#Region Other
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	#EndRegion
	
EndProcedure

#EndRegion

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	Object = Form.Object;
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	#Region DateChange
	
	If Initialize
		Or AttributesList.Property("Date") Then
		Items.ProductBatchIDGroupOfMaterials.Visible = Form.UseTraceableImportedGoodsAccounting;
	EndIf;
	
	#EndRegion
	
	#Region ChangeOfProcessorGiverOfContract
	
	If Initialize
		Or AttributesList.Property("Organization")
		Or AttributesList.Property("MaterialProvider")
		Or AttributesList.Property("Contract") Then
		
		InfluenceFieldsFilledIn =
			ValueIsFilled(Object.Organization)
			And ValueIsFilled(Object.MaterialProvider);
		
		Items.Contract.Enabled = InfluenceFieldsFilledIn;
		
		If Not InfluenceFieldsFilledIn
			And ValueIsFilled(Object.Contract) Then
			Object.Contract = Undefined;
		EndIf;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(AttributesList = "")
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	#Region ChangeOfHouseholdOfOperationOfProcessor
	
	If Initialize
		Or AttributesList.Property("Organization") Then
		
		GiverSelectionParameters = New Array;
		
		If ValueIsFilled(Object.Organization) Then
			
			CurrencySelectionParameterAccountingReg =
				New ChoiceParameter("Filter.LocalAccountingCurrency", LocalAccountingCurrency);
			
			CountryOfRegistrationSelectionParameter =
				New ChoiceParameter("Filter.RegistrationCountry", Common.ObjectAttributeValue(Object.Organization, "RegistrationCountry"));
			
			GiverSelectionParameters.Add(CurrencySelectionParameterAccountingReg);
			GiverSelectionParameters.Add(CountryOfRegistrationSelectionParameter);
			
			OrganizationChoiceParameter = New ChoiceParameter("ModeForSelectingRelatedOrganizations", "JustNotInterconnected");
			GiverSelectionParameters.Add(OrganizationChoiceParameter);
			
			GiverSelectionParameters.Add(New ChoiceParameter("Organization", Object.Organization));
			
		EndIf;
		
		Items.MaterialProvider.ChoiceParameters = New FixedArray(GiverSelectionParameters);
		
	EndIf;
	
	#EndRegion
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, Enabled)
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		ItemArray,
		"Enabled",
		Enabled);
	
EndProcedure

#EndRegion

#Region FillType

&AtServer
Procedure FillInDefaultContract()
	
	ObjectAttributes = New Structure;
	ObjectAttributes.Insert("Organization",           Object.Organization);
	ObjectAttributes.Insert("CompanyRecipient", Object.MaterialProvider);
	ObjectAttributes.Insert("Contract",               Object.Contract);
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		DefaultContract =
			SalesServer.GetDefaultAgreementBetweenOrganizations(
				ObjectAttributes,
				ContractType,
				Object.ARAPCurrency,
				Object.LineOfBusiness);
	Else
		DefaultContract =
			SalesServer.GetDefaultAgreementBetweenOrganizations(
				ObjectAttributes,
				ContractType,
				Object.ARAPCurrency);
	EndIf;
	
	If ContractBeforeModifications <> DefaultContract
		Or Not ValueIsFilled(Object.Contract) Then
		Object.Contract = DefaultContract;
		AgreementWhenModifiedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckAndClearGivers()
	
	If ValueIsFilled(Object.Organization)
		And ValueIsFilled(Object.MaterialProvider) Then
			
			CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Object.Organization, Object.MaterialProvider);
			CompaniesAreInterconnected = Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.MaterialProvider);
			
			If UseBranchOfficesWithSeparateBalanceSheets
				And CompaniesAreInterconnected
				Or Not CheckStructure.CurrenciesDoNotMatch
				Or Not CheckStructure.CountriesMatch Then
				Object.MaterialProvider = Undefined;
			EndIf;
			
	EndIf
	
EndProcedure

#Region ServiceDetails_

&AtServer
Procedure FillInServiceDetails(TSName)
	
	If TSName = "Goods" Then
		For Each CurrentData In Object.Goods Do
			If CurrentData.ToExpenseAs Then
				CurrentData.PostingOption = 1;
			EndIf;
		EndDo;
	EndIf;
	
	FillInServiceDetailsForProductRange(TSName);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange(TSName)
	
	ParametersForFillingInBankingDetails = New Structure;
	
	FillParameters = New Structure;
	FillParameters.Insert("Products", "ItemsType");
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", FillParameters);
	
	FillParameters = New Structure;
	FillParameters.Insert("Products", "ItemVariantsAreUsed");
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute", FillParameters);
	
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object[TSName], ParametersForFillingInBankingDetails);
	
	If TSName = "Goods" Then
		CalculatePercentageOfCostAllocation();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateInvoiceText()
	
	RegistrationParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForRegisteringInvoicesIssued(Object);
	InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
	TextInvoice = InvoicesIssuedOnBasisOf.Presentation;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	
	Form.AmountTotal = Form.Object.Goods.Total("Sum");
		
	If Not Form.Object.PriceIncludesVAT Then
		Form.AmountTotal = Form.AmountTotal + Form.Object.Goods.Total("VATAmount");
	EndIf;
	
	If Not VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation) Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	EndIf;
	
EndProcedure

#EndRegion

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

#EndRegion

#Region FormEventHandlersInternal

&AtServer
Procedure OnReadCreateAtServer()
	
	ContractBeforeModifications               = Object.Contract;
	ContractType                      = Enums.TypesOfIntercompanyContracts.PurchaseAndSale;
	ProcessorBeforeChange          = Object.Organization;
	GiverBeforeChange               = Object.MaterialProvider;
	
	UseLinesOfBusiness =
		GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness")
		Or GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	UseBranchOfficesWithSeparateBalanceSheets =
		GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets");
	
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	DocumentCurrency = Object.Currency;
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CheckAndClearGivers();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	CostAllocationParameters = New FixedStructure(Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.CostAllocationParameters(Object));
	
	FillInServiceDetails("Goods");
	
	FillParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForFillingInVATTaxation_(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
	ConfigureDependentFormElements(ThisObject);
	ConfigureDependentFormElementsOnServer();
	
	UpdateInvoiceText();
	
	RefreshStatusServer();
	CalculateTotals_(ThisObject);
	
EndProcedure

#EndRegion

#Region ElementEventHandlersInternal

#Region IsMain

&AtServer
Procedure DateOfChangeOnServer()
	
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	
	ConfigureDependentFormElements(ThisObject, "Date");
	ConfigureDependentFormElementsOnServer("Date");
	
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	If ValueIsFilled(Object.Organization) Then
		
		If Object.MaterialProvider = Object.Organization Then
			
			MessageText = NStr("vi = 'Doanh nghiệp-người nhận gia công không thể trùng với doanh nghiệp-người đặt gia công.';
								|ru = 'Организация-переработчик не может совпадать с организацией-давальцем.';
								|en = 'Subcontractor company and the material provider company cannot be the same.'; fa = 'Subcontractor company and the material provider company cannot be the same.';
								|it = 'Организация-переработчик не может совпадать с организацией-давальцем.';
								|pl = 'Subcontractor company and the material provider company cannot be the same.';
								|tr = 'Fason üretici iş yeri ile tedarikçi iş yeri aynı olamaz.'");
			Common.MessageToUser(MessageText,, "Organization", "Object");
			
			Object.Organization = ProcessorBeforeChange;
			
			Return;
			
		EndIf;
		
		If Not Object.MaterialProvider = Object.Organization
			And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.MaterialProvider) Then
			
			MessageText = NStr("vi = 'Doanh nghiệp nhận gia công không được phép có quan hệ với doanh nghiệp đặt gia công theo cấu trúc tổ chức.';
								|ru = 'Организация-переработчик не должна быть взаимосвязана с организацией-давальцем по организационной структуре.';
								|en = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.'; fa = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.';
								|it = 'Организация-переработчик не должна быть взаимосвязана с организацией-давальцем по организационной структуре.';
								|pl = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.';
								|tr = 'Fason üretici iş yeri, iş yeri yapısı bakımından tedarikçi iş yeri ile bağlantılı olmamalıdır.'");
			Common.MessageToUser(MessageText,, "Organization", "Object");
			
			Object.Organization = ProcessorBeforeChange;
			
			Return;
			
		EndIf;
		
	EndIf;
	
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	FillInDefaultContract();
	CompleteVATTaxation();
	UpdateInvoiceText();
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(
		Object.Organization,
		Object.SubcontractorAccount,
		Undefined,
		Object.LineOfBusiness,
		Object.ForeignCurrencyTransaction);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
	ClearPaymentDecryption();
	
	ConfigureDependentFormElements(ThisObject, "Organization, Contract");
	ConfigureDependentFormElementsOnServer("Organization, Contract");
	
	ProcessorBeforeChange = Object.Organization;
	
EndProcedure

&AtServer
Procedure GiverWhenChangingOnServer()
	
	If ValueIsFilled(Object.MaterialProvider) Then
		
		If Object.MaterialProvider = Object.Organization Then
			
			MessageText = NStr("vi = 'Doanh nghiệp-người đặt gia công không thể trùng với doanh nghiệp-người nhận gia công.';
								|ru = 'Организация-давалец не может совпадать с организацией-переработчиком.';
								|en = 'Material provider company and the subcontractor company cannot be the same.'; fa = 'Material provider company and the subcontractor company cannot be the same.';
								|it = 'Организация-давалец не может совпадать с организацией-переработчиком.';
								|pl = 'Material provider company and the subcontractor company cannot be the same.';
								|tr = 'Tedarikçi iş yeri ile fason üretici iş yeri aynı olamaz.'");
			Common.MessageToUser(MessageText,, "MaterialProvider", "Object");
			
			Object.MaterialProvider = GiverBeforeChange;
			
			Return;
			
		EndIf;
		
		If Not Object.MaterialProvider = Object.Organization
			And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.MaterialProvider) Then
			
			MessageText = NStr("vi = 'Doanh nghiệp đặt gia công không được phép có quan hệ với doanh nghiệp nhận gia công theo cấu trúc tổ chức.';
								|ru = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
								|en = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.'; fa = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
								|it = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
								|pl = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
								|tr = 'Tedarikçi iş yeri, iş yeri yapısı bakımından fason üretici iş yeri ile bağlantılı olmamalıdır.'");
			Common.MessageToUser(MessageText,, "MaterialProvider", "Object");
			
			Object.MaterialProvider = GiverBeforeChange;
			
			Return;
			
		EndIf;
		
	EndIf;
	
	FillInDefaultContract();
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(
		Object.MaterialProvider,
		Object.MaterialProviderAccount,
		Undefined,
		Object.LineOfBusiness,
		Object.ForeignCurrencyTransaction);
	
	ClearPaymentDecryption();
	
	ConfigureDependentFormElements(ThisObject, "MaterialProvider, Contract");
	ConfigureDependentFormElementsOnServer("MaterialProvider, Contract");
	
	GiverBeforeChange = Object.MaterialProvider;
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	AttributesToFillIn_ = 
	"ARAPObjectSettings,
	|NameForPrinting,
	|Number,
	|Date,
	|LineOfBusiness,
	|Department,
	|ForeignCurrencyTransaction,
	|FinancialAccountingGroup,
	|FinancialAccountingGroupOfRecipient";
	
	AttributesToExclude = "Number, Date";
	ContractDetails_    = Common.ObjectAttributesValues(Object.Contract, AttributesToFillIn_);
	FillPropertyValues(Object, ContractDetails_, , AttributesToExclude);
	
	Object.Basis                           = ContractDetails_.NameForPrinting;
	Object.BaseDocumentNumber                      = ContractDetails_.Number;
	Object.ReferenceDocumentDateForPrintForms                       = ContractDetails_.Date;
	Object.SubcontractorFinancialAccountingGroup = ContractDetails_.FinancialAccountingGroup;
	Object.MaterialProviderFinancialAccountingGroup      = ContractDetails_.FinancialAccountingGroupOfRecipient;
	
	CompleteVATTaxation();
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.MaterialProviderAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		Object.SubcontractorAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(
		Object.Contract,
		Object.SubcontractorAccount,
		Object.MaterialProviderAccount);
	
	If Not ValueIsFilled(Object.SubcontractorAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = LocalAccountingCurrency;
		Object.SubcontractorAccount =
			CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If Not ValueIsFilled(Object.MaterialProviderAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.MaterialProvider);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = LocalAccountingCurrency;
		Object.MaterialProviderAccount =
			CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(
			Object.LineOfBusiness,
			Undefined,
			Object.Contract);
	EndIf;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
	ClearPaymentDecryption();
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	ConfigureDependentFormElements(ThisObject, "Contract");
	ConfigureDependentFormElementsOnServer("Contract");
	
	ContractBeforeModifications = Object.Contract;
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	RecalculationParameters = PriceManagementSystem.ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(Object.PriceIncludesVAT, DocumentAmount, "Count");
	
	PriceManagementSystem.RecalculateTableAmountsONChangeOfExchangeRate(Object.Goods, RecalculationParameters);
	
EndProcedure

#EndRegion

#Region Goods

&AtClient
Procedure GoodsProductionLotReferenceStartChoiceCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	
	CurrentData = Items.Goods.CurrentData;
	
	Groups = New Array;
	Groups.Add(Result);
	If Groups.Find(CurrentData.ProductionLot) = Undefined Then
		Groups.Add(CurrentData.ProductionLot);
	EndIf;
	
	CurrentData.ProductionLot = Result;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion


#Region More

&AtServer
Procedure PriceIncludesVATWhenChangedOnServer(CachedValues)
	
	StructureOfActions = New Structure;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("AdjustVATRate", ParametersForFillingInVATRate(Object));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesInternal);
	
	StructureOfActions = New Structure;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure MethodOfCostAllocationForChangesOnServer()
	
	CostAllocationParametersStructure = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.CostAllocationParameters(Object);
	CostAllocationParameters = New FixedStructure(CostAllocationParametersStructure);
	
	ProductionServer.CalculateFractionOfCost(Object, CostAllocationParameters);
	CalculatePercentageOfCostAllocation();
	
EndProcedure

#EndRegion

#EndRegion

#Region FormServiceCommandHandlers

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

#Region IsMain

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
		CalculateTotals_(ThisObject);
	EndIf;
	If ChangedBankingDetails.Property("Currency") Then
		DocumentCurrency = Object.Currency;
		FillInSubordinatePropertiesForStatistics("Currency");
	EndIf;
	
	If ChangedBankingDetails.Property("ARAPCurrency") Then
		FillInDefaultContract();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		LabelPaymentStagesClickCompletionServer(ChangedBankingDetails);
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

#EndRegion

#Region CommonTables

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard(TSName)
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductReusablePackagingWork(False));
	
	If TSName = "Goods" Then
		Columns = "Products,Characteristic,Count,PriceKind,VATRate,ProductCostElement,ProductionLot";
	EndIf;
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	RowsToProcess = New Array;
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentData = Object[TSName].Add();
		FillPropertyValues(CurrentData, RowOfProduct);
		RowsToProcess.Add(CurrentData);
		
	EndDo;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(ThisObject, StructureOfActions, TSName);
	AddActionsToStructureWhenQuantityChanges(ThisObject, StructureOfActions, TSName);
	
	If TSName = "Goods" Then
		
		StructureOfActions.Insert(
			"FillInSalePrice",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		
		StructureOfActions.Insert("RecalculateAmount", "Count");
		
		// Selection of articles and analytics.
		IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
		
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TSName],
		CachedValues);
	
	If TSName = "Goods" Then
		CalculateTotals_(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, TSName) Export 
	
	CurrentData = Items[TSName].CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		
		AddActionsToStructureWhenQuantityChanges(ThisObject, StructureOfActions, TSName);
		
		If TSName = "Goods" Then
			
			StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
			
			StructureOfActions.Insert("RecalculateAmount", "Count");
			StructureOfActions.Insert("ClearAmountOfSettlements");
			
		EndIf;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		If TSName = "Goods" Then
			ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(NewRow, CurrentData, CostAllocationParameters.MethodOfAllocatingFinishedProductCosts);
			
			Groups = New Array;
			Groups.Add(CurrentData.ProductionLot);
			CalculatePercentageOfCostAllocation(Groups);
			
			CalculateTotals_(ThisObject);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, TSName) Export
	
	ProcessBarcodes(BarcodeData_2, TSName);
	
EndProcedure

&AtClient
Procedure FillInProductionBatchCompletion(Result, TSName) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Form.DocumentForm.FillInProductionBatch");
	
	FillInProductionBatchEndAtServer(Result, TSName);
	
EndProcedure

&AtServer
Procedure FillInProductionBatchEndAtServer(Result, TSName)

	If TSName = "Goods" Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
		
		Groups = New Array;
		Groups.Add(Result);
		
		RowsToProcess = New Array;
		
	EndIf;
	
	For Each RowID In Items[TSName].SelectedRows Do
		
		CurrentData = Object[TSName].FindByID(RowID);
		CurrentData.ProductionLot = Result;
		
		If TSName = "Goods" Then
			
			If Groups.Find(CurrentData.ProductionLot) = Undefined Then
				Groups.Add(CurrentData.ProductionLot);
			EndIf;
			
			RowsToProcess.Add(CurrentData);
			
		EndIf;
		
	EndDo;
	
	If TSName = "Goods" Then
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object[TSName]);
		
		CalculatePercentageOfCostAllocation(Groups);
	EndIf;
	
EndProcedure

#EndRegion

#Region Goods

&AtClient
Procedure FillInBalanceOfReportsForRegistrationCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		FillInRestOfReportsForRegistrationOnServer(CachedValues);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInRestOfReportsForRegistrationOnServer(CachedValues)
	
	FillParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForRequestingReportBalancesForRegistration();
	FillParameters.Organization = Object.Organization;
	FillParameters.MaterialProvider     = Object.MaterialProvider;
	FillParameters.Recorder = Object.Ref;
	FillParameters.Month       = ?(ValueIsFilled(Object.Date), BegOfMonth(Object.Date), BegOfMonth(CurrentSessionDate()));
	
	Query = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.RequestRemainingReportsToBeProcessed(FillParameters);
	Query = RequestSchemes.ChangeAliasOfSelectionFieldInRequest(Query, "Products",   "MainProductProducts");
	Query = RequestSchemes.ChangeAliasOfSelectionFieldInRequest(Query, "Characteristic", "MainProductCharacteristic");
	
	Object.Goods.Load(Query.Execute().Unload());
	
	FillInServiceDetails("Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.Goods,
		StructureOfActions,
		CachedValues);
	
	CalculatePercentageOfCostAllocation();
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKindCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesByPriceKindServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtServer
Function FillInPricesByPriceKindServer(PricesKind)
	
	// &PerformanceMeasurement
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Form.DocumentForm.FillInPricesByPriceKind");
	
	RowsArray = New Array;
	For Each String In Items.Goods.SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
	EndDo;
	
	FillParameters = EnterprisePricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Date           = Object.Date;
	FillParameters.Organization    = Object.Organization;
	FillParameters.Currency         = Object.Currency;
	FillParameters.PriceKind        = PricesKind;
	FillParameters.PopulationFields = "Price, PriceKind";
	FillParameters.Insert("ColumnNamePackaging", "");
	
	StructureOfActions = New Structure();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, StructureOfActions);
	
	CalculateTotals_(ThisObject);
	
	// &PerformanceMeasurement
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, RowsArray.Count());
	
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure FillInProductsCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	FillInItemEndOnServer(ClosingResult, CachedValues);
	
EndProcedure

&AtServer
Procedure FillInItemEndOnServer(ClosingResult, CachedValues)

	// &PerformanceMeasurement
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Form.DocumentForm.FillInProducts");
	
	Groups = New Array;
	RowsToProcess = New Array;
	For Each RowID In Items.Goods.SelectedRows Do
		
		CurrentData = Object.Goods.FindByID(RowID);
		RowsToProcess.Add(CurrentData);
		
		If Groups.Find(CurrentData.ProductionLot) = Undefined Then
			Groups.Add(CurrentData.ProductionLot);
		EndIf;
		
		CurrentData.Products = ClosingResult;
		
	EndDo;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingProducts(ThisObject, StructureOfActions, "Goods");
	AddActionsToStructureWhenQuantityChanges(ThisObject, StructureOfActions, "Goods");
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert(
		"FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	
	StructureOfActions.Insert(
		"ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName, FieldName", FormName, "Goods", "Products"));
	
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable",
		New Structure("FormName, TabularSectionName, FieldName", FormName, "Goods", "Characteristic"));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	CalculatePercentageOfCostAllocation(Groups);
	CalculateTotals_(ThisObject);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, Items.Goods.SelectedRows.Count());
	
EndProcedure

&AtClient
Procedure FillInTheCostingItemCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Form.DocumentForm.FillInTheCostingItem");
	
	For Each RowID In Items.Goods.SelectedRows Do
		CurrentData = Object.Goods.FindByID(RowID);
		CurrentData.ProductCostElement = Result;
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInQuantityCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Form.DocumentForm.FillInQuantity");
	
	FillInEndCountOnServer(Result, AdditionalParameters)
	
EndProcedure

&AtServer
Procedure FillInEndCountOnServer(Result, AdditionalParameters)

	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	Groups = New Array;
	RowsToProcess = New Array();
	
	For Each RowID In Items.Goods.SelectedRows Do
		
		CurrentData = Object.Goods.FindByID(RowID);
		CurrentData.Count = Result;
		
		If Groups.Find(CurrentData.ProductionLot) = Undefined Then
			Groups.Add(CurrentData.ProductionLot);
		EndIf;
		
		RowsToProcess.Add(CurrentData);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	CalculateTotals_(ThisObject);
	CalculatePercentageOfCostAllocation(Groups);
	
EndProcedure

#EndRegion


#Region AttachableCommands

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
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

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

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

// IntegrationWith1CDocumentManagementSubsystem
#Region IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

#EndRegion
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region More

&AtClient
Procedure OpenPrintDetails(ShowTTNDetails)
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy",             Object.LetterOfAuthorityIssuedBy);
	ParametersStructure.Insert("PowerOfAttorneyDate",               Object.PowerOfAttorneyDate);
	ParametersStructure.Insert("PowerOfAttorneyPerson",               Object.PowerOfAttorneyPerson);
	ParametersStructure.Insert("PowerOfAttorneyNumber",              Object.PowerOfAttorneyNumber);
	ParametersStructure.Insert("BusinessOperation",          Object.BusinessOperation);
	ParametersStructure.Insert("CompanyRecipient",          Object.MaterialProvider);
	ParametersStructure.Insert("RecipientCompanyBankAccount", Object.MaterialProviderAccount);
	ParametersStructure.Insert("ReadOnly",                 ReadOnly);
	ParametersStructure.Insert("ShowTTNDetails",         False);
	ParametersStructure.Insert("ObjectType",                     "ConsumptionReportSubcontractingServicesDeliveredIntercompany");
	ParametersStructure.Insert("AddressOfObjectInTemporaryStorage", AddressOfObjectInTemporaryStorage());
	ParametersStructure.Insert("PaymentsThroughTheOrganization",        True);
	ParametersStructure.Insert("Organization",                    Object.Organization);
	ParametersStructure.Insert("Date",                           Object.Date);
	ParametersStructure.Insert("Director",                   Object.Director);
	ParametersStructure.Insert("ChiefAccountant",               Object.ChiefAccountant);
	ParametersStructure.Insert("CompanyBankAccount",      Object.SubcontractorAccount);
	ParametersStructure.Insert("Basis",                      Object.Basis);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                  Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",                 Object.BaseDocumentNumber);
	
	AttributesArray = New Array;
	AttributesArray.Add("GoodsRecipient");
	AttributesArray.Add("GoodsRecipientBankAccount");
	AttributesArray.Add("DeliveryAddress");
	AttributesArray.Add("Shipper");
	AttributesArray.Add("ShipperBankAccount");
	AttributesArray.Add("IssuiedBy");
	AttributesArray.Add("IssuiedByJobTitle");
	
	ParametersStructure.Insert("DoNotShowBankDetails", AttributesArray);
	
	OpenForm(
		"CommonForm.PrintingDetailsOfSales",
		ParametersStructure,
		ThisObject,,,,
		Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#EndRegion


#Region ARAPAccounting

&AtServer
Procedure LabelPaymentStagesClickCompletionServer(ChangedBankingDetails)
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
	If ChangedBankingDetails.Property("ARAPObjectSettings") Then
		RefreshStatusServer();
	EndIf;
	
	If ChangedBankingDetails.Property("ForeignCurrencyTransaction") Then
		
		FinancialAccountingGroups = GetFinancialAccountingGroups(Object.Organization, Object.ARAPCurrency, Object.BusinessOperation);
		Object.SubcontractorFinancialAccountingGroup = FinancialAccountingGroups.SubcontractorFinancialAccountingGroup;
		Object.MaterialProviderFinancialAccountingGroup      = FinancialAccountingGroups.MaterialProviderFinancialAccountingGroup;
		
	EndIf;
	
	AddSBPPaymentStatusUpdateCommand();
	
EndProcedure

&AtServerNoContext
Function GetFinancialAccountingGroups(Organization, ARAPCurrency, BusinessOperation)
	
	Result = New Structure;
	
	Result.Insert("SubcontractorFinancialAccountingGroup", Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation));
	Result.Insert("MaterialProviderFinancialAccountingGroup",      Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation, True));
	
	Return Result;
	
EndFunction

&AtServer
Procedure ChangedPaymentServer(EventName, Parameter)
	
	RefreshStatusServer();
	ARAPAccountingFormWork.NotificationProcessing(ThisObject, EventName, Parameter);
	
EndProcedure

&AtServer
Procedure RefreshStatusServer()
	
	Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.CalculateRecipientState(
		Object.Ref,
		Object.Contract,
		ThisObject);
		
	Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.CalculateSenderState(
		Object.Ref,
		Object.Contract,
		ThisObject);

EndProcedure

&AtServer
Procedure ClearPaymentDecryption()
	
	Object.ARAPDetailsWithCustomer.Clear();
	Object.ARAPDetailsWithVendor.Clear();
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisObject);
EndProcedure

#EndRegion

#Region VATAccounting

&AtServer
Procedure CompleteVATTaxation()
	
	FillParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForFillingInVATTaxation_(Object);
	
	VATAccountingERP.FillInSalesVATTaxation(
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
	VATAccountingERP.FillInSalesVATTaxSelectionList(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClientAtServerNoContext
Function ParametersForFillingInVATRate(Object)
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate();
	FillPropertyValues(ParametersForFillingInVATRate, Object);
	ParametersForFillingInVATRate.Organization = Object.Organization;
	
	Return ParametersForFillingInVATRate;
	
EndFunction

#EndRegion

#Region CostShares

&AtServer
Procedure CalculatePercentageOfCostAllocation(Groups = Undefined)
	
	ProductionServer.CalculatePercentageOfCostAllocationForOutputProducts(Object, CostAllocationParameters, Groups);
	
EndProcedure

&AtServer
Function ParametersOfCostShareEntryForm_(CurDataId)
	
	FormParameters = ProductionServer.ParametersOfCostShareEntryForm(Object, CostAllocationParameters, CurDataId);
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure OpenCostShareEntryForm(CurrentData)

	NoErrors_ = ProductionClient.CheckFillingBeforeEnteringCostFraction(CurrentData, CostAllocationParameters);
	
	If NoErrors_ Then
		FormParameters = ParametersOfCostShareEntryForm_(CurrentData.GetID());
		OpenForm("CommonForm.EnterCostShare",
			FormParameters,
			ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingInputOfFractionOfCost(Item, CurrentData, ValueSelected)
	
	If CurrentData.CostShare <> ValueSelected.CostShare Then
		
		ProductionClientServer.FillInCostFractionInLine(
			CurrentData,
			ValueSelected);
			
		Groups = New Array;
		Groups.Add(CurrentData.ProductionLot);
		CalculatePercentageOfCostAllocation(Groups);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5, TSName)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	
	AddActionsToStructureWhenChangingProducts(ThisObject, StructureOfActionsWithAddedStrings, TSName);
	AddActionsToStructureWhenQuantityChanges(ThisObject, StructureOfActionsWithAddedStrings, TSName);
	
	If TSName = "Goods" Then
		StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersForFillingInVATRate(Object));
	EndIf;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenQuantityChanges(ThisObject, StructureOfActionsWithModifiedStrings, TSName);
	
	If TSName = "Goods" Then
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfActionsWithModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActionsWithModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		
		StructureOfActionsWithModifiedStrings.Insert("RecalculateAmount", "Count");
		StructureOfActionsWithModifiedStrings.Insert("ClearAmountOfSettlements");
		
	EndIf;
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();

	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.NotUsePackages                 = True;
	StructureOfActions.TSName                                  = TSName;
	StructureOfActions.ColumnNameQuantity                   = "Count";
	
	If TSName = "Goods" Then
		StructureOfActions.OnlyWorks                       = True;
	Else
		StructureOfActions.OnlyGoodsAndWork                = True;
	EndIf;
	
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If TSName = "Goods" Then
		CalculateTotals_(ThisObject);
	EndIf;
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items[TSName].CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
EndProcedure

#EndRegion

#Region AdditionalProperties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

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

#EndRegion

#Region ProcessingActionStructure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(Form, StructureOfActions, TSName)

	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	StructureOfActions.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	
	StructureOfActions.Insert(
		"ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", Form.FormName, TSName));
	
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenQuantityChanges(Form, StructureOfActions, TSName)
	
	
	Return;
	
EndProcedure


#EndRegion

#Region Other

&AtServer
Function AddressOfObjectInTemporaryStorage()
	
	ObjectStructure = New Structure;
	
	For Each Attribute In Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Attributes Do
		ObjectStructure.Insert(Attribute.Name);
	EndDo;
	
	FillPropertyValues(ObjectStructure, Object);
	
	Return PutToTempStorage(ObjectStructure, UUID);
	
EndFunction


&AtServer
Procedure AddSBPPaymentStatusUpdateCommand()

	CommandParameters = CashServerLocalization.NewParametersOfSBPPaymentStatusUpdateCommand();
	CommandParameters.Parent = Items.ProcessorPaymentGroup;
	CashServerLocalization.AddSBPPaymentStatusUpdateCommand(ThisObject, CommandParameters);

EndProcedure

&AtClient
Procedure Attachable_SBPPaymentVerification()

	CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.MaterialProvider);

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

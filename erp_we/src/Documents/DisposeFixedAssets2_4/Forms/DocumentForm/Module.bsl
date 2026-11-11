
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
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		If Object.ExpenseItem = Undefined Then
			Object.ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
		EndIf;
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.DisposeFixedAssets2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AccountSettings_ = Documents.DisposeFixedAssets2_4.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, AccountSettings_);
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations
	
	If UseTraceableImportedGoodsAccounting Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
		AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
			Items.RecordedAsReceivedTangibleAssetsCCDNumber.Name);		
		AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
			Items.TraceableGoodsCCDNumber.Name, True);		
	EndIf;
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject, Object.Date, "IncomingMCGroupQuantityAccordingToRNPT", True);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands


	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.DisposeFixedAssets2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AccountSettings_ = Documents.DisposeFixedAssets2_4.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, AccountSettings_);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = AccountingForTraceableGoodsClientServerLocalization.NameOfFormOfSelectionForRemainsOfTraceableGoodsVos() Then
		
		GetTraceableItemsFromStorage(ValueSelected);
		
	ElsIf Items.Pages.CurrentPage = Items.IncomingMCPage
		And PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	Else
		
		ProcessingSelectionOfProductsOnServer(ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	
	Notify("Write_DisposeFixedAssets2_4", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();

	If ValueIsFilled(Object.DocumentBasis) 
		And TypeOf(Object.DocumentBasis) = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		
		Notify("RecordDocumentBasedOnInventory",, Object.Ref);
	EndIf;
	

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
	

	FillInServiceDetails();
	FillInInformationInBasement();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If WriteParameters.WriteMode = DocumentWriteMode.UndoPosting Then
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	EndIf; 
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting And Not DataOnTraceableGoodsIsCorrect() Then
		Cancel = True;	
	EndIf;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_DisposeFixedAssets2_4" 
		And Source <> Object.Ref Then
		FillInInformationInBasement();
	EndIf;
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If Items.Pages.CurrentPage = Items.IncomingMCPage
		And PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		
		Specification_Parameters = PurchasesClient.ParametersForSpecifyingCCDNumber();
		Specification_Parameters.TSName = "RecordedAsReceivedTangibleAssets";
		
		Actions = New Structure;
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			Actions);
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, Specification_Parameters, , Actions);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationWhenChangingOnServer();

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure AdjustmentModeFromPreviousDateOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("AdjustmentModeFromPreviousDate");

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.PostInAccounting = True;
	EndIf;
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RecordInLocalAccounting,PostInAccounting");

EndProcedure

&AtClient
Procedure RecordInTAOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInTA = True;
	EndIf;

	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RecordInLocalAccounting,RecordInTA");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RecordInManAccounting");

EndProcedure

&AtClient
Procedure DocumentInformationInAnotherAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Object.Ref);
		OpenForm("Document.DisposeFixedAssets2_4.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpensesPostingMethodOnChange(Item)
	
	ChangedBankingDetails = "ExpensesPostingMethod,ExpenseItem,BusinessUnitAndLineOfBusinessMatchAccountingData,DimensionCorrespondsToFAToWriteOff";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpensesPostingMethod, 
		Object.ExpenseItem, 
		Object.DimensionOfExpenses, 
		Object.ExpensesBusinessUnit, 
		Object.ExpenseLineOfBusiness, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingData);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.DimensionCorrespondsToFAToWriteOff = False;
	EndIf;
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod,ExpenseItem");
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod");
	EndIf;
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesBusinessUnitOnChange(Item)

	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject,"ExpensesPostingMethod,ExpensesBusinessUnit");
	
EndProcedure

&AtClient
Procedure ExpenseLineOfBusinessOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject,"ExpensesPostingMethod,ExpenseLineOfBusiness");
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject,"ExpensesPostingMethod,BusinessUnitAndLineOfBusinessMatchAccountingData");

EndProcedure

&AtClient
Procedure PresentationOfRecordingInComplAccountingClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DocumentBasisClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.DocumentBasis)
		And Object.Basis1.Count() = 0 Then
		
		ShowValue(, Object.DocumentBasis);
		
	ElsIf Object.Basis1.Count() > 0 Then
		
		FormParameters = New Structure;
		FormParameters.Insert("ReadOnly", ReadOnly);
		FormParameters.Insert("Basis1", New Array);
		
		For Each RowData In Object.Basis1 Do
			FormParameters.Basis1.Add(RowData.DocumentBasis);
		EndDo;
		
		ClosingNotification1 = New CallbackDescription("OpenListOfBasesEnd", ThisObject);
		OpenForm("Document.DisposeFixedAssets2_4.Form.ListOfGrounds", FormParameters,,,,, ClosingNotification1);
		
	EndIf;

EndProcedure

&AtClient
Procedure DimensionCorrespondsToFAToWriteOffOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod,DimensionCorrespondsToFAToWriteOff");
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.Pages.ChildItems.TraceableProductsPage Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
	EndIf;
	
EndProcedure

#Region Localization

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return; // WE have an empty handler

EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected).Count() <> 0 Then
		WhenChangingFAOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FAOnChange(Item)
	
	WhenChangingFAOnServer();
	
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	WhenChangingFAOnServer();

EndProcedure

&AtClient
Procedure FAChargeAmountAccountingOnChange(Item)
	
	CurrentData = Items.FA.CurrentData;
	
	If CurrentData.AmountPermanentDifference = 0
		And CurrentData.AmountTemporaryDifference = 0
		And Object.RecordInTA Then
			
		CurrentData.AmountTaxAccounting = CurrentData.ChargeAmountAccounting;
	EndIf;
	
	CurrentData.AmountTemporaryDifference = CurrentData.ChargeAmountAccounting - CurrentData.AmountTaxAccounting - CurrentData.AmountPermanentDifference;
	
EndProcedure

&AtClient
Procedure FAAmountTaxAccountingOnChange(Item)
	
	CurrentData = Items.FA.CurrentData;
	CurrentData.AmountTemporaryDifference = CurrentData.ChargeAmountAccounting - CurrentData.AmountTaxAccounting - CurrentData.AmountPermanentDifference;
	
EndProcedure

&AtClient
Procedure FAAmountPermanentDifferenceOnChange(Item)
	
	CurrentData = Items.FA.CurrentData;
	CurrentData.AmountTemporaryDifference = CurrentData.ChargeAmountAccounting - CurrentData.AmountTaxAccounting - CurrentData.AmountPermanentDifference;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecordedAsReceivedTangibleAssets

&AtClient
Procedure RecordedAsReceivedTangibleAssetsProductsOnChange(Item)
	
	CurrentRow = Items.RecordedAsReceivedTangibleAssets.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
								New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute",
								New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordedAsReceivedTangibleAssetsCountOnChange(Item)
	
	CurrentRow = Items.RecordedAsReceivedTangibleAssets.CurrentData;
	
	StructureOfActions = New Structure;
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure IncomingMCCCDNumberOnChange(Item)
	
	CurrentData = Items.RecordedAsReceivedTangibleAssets.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCCDNumberType", FillParameters);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure RecordedAsReceivedTangibleAssetsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.RecordedAsReceivedTangibleAssets.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.FieldNameQuantity = "Count";
	AdditionalParameters.BasisOfCostOfAdmission = False;
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTraceableGoods

&AtClient
Procedure TraceableGoodsOnStartEdit(Item, NewRow, Copy)
	
	DisposeFixedAssetsClientLocalization.TraceableGoodsOnStartEdit(Item, NewRow, Copy);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");
	
	FASelectionParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	OpenForm("Catalog.Assets.ChoiceForm", 
					FASelectionParameters, 
					Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectionOfTheNomenclature(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CloseOnChoice", False);
	ArrayOfProductTypes = New Array();
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	AvailableProductTypes = New FixedArray(ArrayOfProductTypes);
	FormParameters.Insert("Filter", New Structure("ItemsType", AvailableProductTypes));
	
	OpenForm("Catalog.Products.Form.ChoiceForm", 
		FormParameters, 
		ThisObject, 
		UUID,,,, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInAmountDebited(Command)
	
	FillInDebitedAmountOnServer();

EndProcedure

&AtClient
Procedure ShowPD(Command)
	
	Items.FAShowPD.Check = Not Items.FAShowPD.Check;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Command.Name);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure SearchForTraceableProductBalances(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	Notification = New CallbackDescription("SelectionByStockCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure GenerateStatement(Command)
	
	AvailableFixedAssets = AvailableFixedAssets();	
	Filter = New Structure;
    Filter.Insert("Organization", Object.Organization);   
	Filter.Insert("FixedAsset", AvailableFixedAssets);
	ReportPeriod = New StandardPeriod();
	ReportPeriod.StartDate = BegOfDay(Object.Date);
	ReportPeriod.EndDate = EndOfDay(Object.Date);
 	Filter.Insert("Period", ReportPeriod);
	FormParameters = New Structure("Filter, GenerateOnOpen, VariantKey", Filter, True, "Main");	
	AccountingForTraceableGoodsClientLocalization.GenerateStatement(FormParameters);
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ImportDataFromPDT(Command)
	
	LoadDataFromTSD();
	
EndProcedure

#EndRegion

#Region UniversalMechanisms_Commands

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

#EndRegion


#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtServer
Procedure ProcessBarcodes(Val BarcodeData_5)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	ObjectsArray = NonCurrentAssets.FindFixedAssetsByBarcodes(BarcodeData_5, PickingParameters);
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ObjectsArray).Count() <> 0 Then
		WhenChangingFAOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadDataFromTSD()
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, AdditionalParameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region CCDNumbers

&AtClient
Procedure ProcessSelectionOfCCDNumber(CalculationResult1)
	
	CurrentData = Items.RecordedAsReceivedTangibleAssets.CurrentData;
	
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
	PickingParameters.TSName = "RecordedAsReceivedTangibleAssets";
	PickingParameters.FormTableName = "RecordedAsReceivedTangibleAssets";
	PickingParameters.FieldNameNumberOfPackages = "Count";
	
	ProcessingActions = New Structure;
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		ProcessingActions);
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												PickingParameters,
												ProcessingActions);
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		"RecordedAsReceivedTangibleAssetsCharacteristic",
		"Object.RecordedAsReceivedTangibleAssets.ItemVariantsAreUsed");
	
	//
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT();
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT	= "RecordedAsReceivedTangibleAssetsQuantityByGBRN";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA	= "IncomingMCUnits";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT		= "Object.RecordedAsReceivedTangibleAssets.AccountingForTheRNPTIsMaintained";
	ConditionalDesignParameters.PathToItemTypeField		= "Object.RecordedAsReceivedTangibleAssets.ItemsType";
	ConditionalDesignParameters.PathToCCDNumberTypeField			= "Object.RecordedAsReceivedTangibleAssets.CCDNumberType";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
	
	//
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber		= "RecordedAsReceivedTangibleAssetsCCDNumber";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToCCD	= "Object.RecordedAsReceivedTangibleAssets.TheRecordsAreKeptByCCD";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber		= "RecordedAsReceivedTangibleAssetsCCDNumber";
	ConditionalDesignParameters.PathToCCDNumberField			= "Object.RecordedAsReceivedTangibleAssets.CCDNumber";
	ConditionalDesignParameters.PathToFieldIsRecordedAccordingToRNPT	= "Object.RecordedAsReceivedTangibleAssets.AccountingForTheRNPTIsMaintained";
	ConditionalDesignParameters.PathToItemTypeField	= "Object.RecordedAsReceivedTangibleAssets.ItemsType";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializingFormWhenCreatingItOnServer();
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.ExpenseItem.Title = NStr("vi = 'Dạng chi phí';
										|ru = 'Статья расходов';
										|en = 'Expense item'; fa = 'قلم هزینه';
										|it = 'Voce di spese';
										|pl = 'Rodzaj kosztu';
										|tr = 'Gider kalemi'");
	EndIf;
	
	FillInInformationInBasement();
	
	ConfigureDependentFormElementsOnServer();
	
	FillInSelectionParameters();
	
	FillInServiceDetails();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	PresentationOfDetails = FormServiceParameters.PresentationOfDetails; // Map
	Items.FAAmountManagementAccounting.Title = PresentationOfDetails.Get("FA.AmountManagementAccounting");
	Items.FAChargeAmountAccounting.Title = PresentationOfDetails.Get("FA.ChargeAmountAccounting");
	Items.FAAmountTaxAccounting.Title = PresentationOfDetails.Get("FA.AmountTaxAccounting");
	Items.FAAmountPermanentDifference.Title = PresentationOfDetails.Get("FA.AmountPermanentDifference");
	Items.FAAmountTemporaryDifference.Title = PresentationOfDetails.Get("FA.AmountTemporaryDifference");
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("PresentationOfDetails", Documents.DisposeFixedAssets2_4.PresentationOfDetails(Object.Organization, Object.Date));
	NewServiceParametersOfForm.Insert("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, Val ChangedBankingDetails = "")

	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	PresentationOfDetails = FormServiceParameters.PresentationOfDetails; // Map
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = (StructureOfChangedProps.Count() = 0);
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", Form.CurrenciesDoNotMatch);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	AuxiliaryAttributes.Insert("IncomeTaxPayer", False);
	NonCurrentAssetsClientServerLocalization.AddAuxiliaryDetails_WriteOffFA(Form, AuxiliaryAttributes);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesForDependentBankDetails_FADebiting(
										Object, AuxiliaryAttributes, ChangedBankingDetails);
										
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(
			Object, ItemDetailsParameters, "FA,RecordedAsReceivedTangibleAssets,TraceableGoods,Basis1");
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		Items.PostInAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInTA.Visible = FormServiceParameters.ComplianceCAAccountingIsKept;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.PostInAccounting.Visible Or Items.RecordInManAccounting.Visible;
		
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then

			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = False;
		EndIf;
		
	EndIf;

	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		Items.FAFillInAmountDebited.Visible =
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialFixedAssetsDisposal")
			And FormServiceParameters.ComplianceCAAccountingIsKept;	
		
		If Items.FAFillInAmountDebited.Visible Then
			Items.OsgroupFillIn.Type = FormGroupType.Popup;
		Else
			Items.OsgroupFillIn.Type = FormGroupType.ButtonGroup;
		EndIf;	
		
	EndIf;
		
	If StructureOfChangedProps.Property("Basis1")
		Or UpdateAll Then
		
		If Object.Basis1.Count() > 0 Then
			Form.DocumentBasisPresentation = StrTemplate(NStr("vi = 'Cơ sở (%1)';
																|ru = 'Основания (%1)';
																|en = 'Bases (%1)'; fa = 'Bases (%1)';
																|it = 'Base (%1)';
																|pl = 'Podstawy (%1)';
																|tr = 'Esas (%1)'"), Object.Basis1.Count());
			Items.DocumentBasisPresentation.TitleLocation = FormItemTitleLocation.None;
		ElsIf ValueIsFilled(Object.DocumentBasis) Then
			Form.DocumentBasisPresentation = String(Object.DocumentBasis);
			Items.DocumentBasisPresentation.TitleLocation = FormItemTitleLocation.Auto;
		Else
			Form.DocumentBasisPresentation = "";
		EndIf;
		
		Items.DocumentBasisPresentation.Visible = ValueIsFilled(Form.DocumentBasisPresentation);
		
	EndIf;
	
	If StructureOfChangedProps.Property("FixedAsset")
		Or UpdateAll Then
			
		ChoiceList = Items.RecordedAsReceivedTangibleAssetsFixedAsset.ChoiceList;
		ChoiceList.Clear();
		For Each RowData In Object.FA Do
			If ValueIsFilled(RowData.FixedAsset)
				And ChoiceList.FindByValue(RowData.FixedAsset) = Undefined Then
				ChoiceList.Add(RowData.FixedAsset);
			EndIf;
		EndDo;
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then

		Items.FAChargeAmountAccounting.Title = PresentationOfDetails.Get("FA.ChargeAmountAccounting");
		Items.FAAmountTaxAccounting.Title = PresentationOfDetails.Get("FA.AmountTaxAccounting");
		Items.FAAmountPermanentDifference.Title = PresentationOfDetails.Get("FA.AmountPermanentDifference");
		Items.FAAmountTemporaryDifference.Title = PresentationOfDetails.Get("FA.AmountTemporaryDifference");

	EndIf;
		
	If StructureOfChangedProps.Property("ExpensesPostingMethod") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpensesPostingMethod,
			Form, 
			"ExpenseItem,DimensionOfExpenses,ExpensesBusinessUnit,ExpenseLineOfBusiness,BusinessUnitAndLineOfBusinessMatchAccountingData,DimensionCorrespondsToFAToWriteOff");
	
	EndIf;
		
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = (StructureOfChangedProps.Count() = 0);
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
		
		//
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"PresentationOfDetails",
			Documents.DisposeFixedAssets2_4.PresentationOfDetails(Object.Organization, Object.Date),
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrency",
			SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization),
			FormServiceParameters);
		
	EndIf;
	
	If UpdateAll
		Or StructureOfChangedProps.Property("Date") Then
		
		UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
															Object.Date);
		
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(
			ThisObject,
			Object.Date,
			"IncomingMCGroupQuantityAccordingToRNPT",
			True);
		
		If Not Items.IncomingMCGroupQuantityAccordingToRNPT.Visible Then
			RecalculateNumberOfRNPT();
		EndIf;
		
		AccountingForTraceableGoodsLocalization.SetVisibilityOfTraceableGoodsPage(ThisObject, Object.Date);
		
	EndIf;
	
	DisposeFixedAssetsLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()

	ChangedBankingDetails = "BusinessOperation";
	
	If Object.BusinessOperation = Enums.BusinessTransactions.WriteOffSubAssetsComponentsOfDepreciation
		And Object.RecordInTA Then
		
		Object.RecordInTA = False;
		
		ChangedBankingDetails = ChangedBankingDetails + "," + "RecordInLocalAccounting,RecordInTA";
		
	EndIf;
	
	Object.FixedAssetsEvent = Catalogs.FixedAssetsEvents.EmptyRef();
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);

	FillInSelectionParameters();
	DeleteTableRowsWithIncorrectFATypes();
	
EndProcedure

&AtServer
Procedure FillInSelectionParameters()

	ListOfSelectionParameters = New Array;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialFixedAssetsDisposal") Then
		ChoiceParameter = New ChoiceParameter("Filter.EventKindWithFixedAssets", Enums.EventKindsWithFixedAssets.PartialDisposal);
		ListOfSelectionParameters.Add(ChoiceParameter);
	Else
		ChoiceParameter = New ChoiceParameter("Filter.EventKindWithFixedAssets", Enums.EventKindsWithFixedAssets.WriteOff);
		ListOfSelectionParameters.Add(ChoiceParameter);
	EndIf; 
	
	Items.FixedAssetsEvent.ChoiceParameters = New FixedArray(ListOfSelectionParameters);
	
	ListOfSelectionParameters = New Array(Items.FAFixedAsset.ChoiceParameters); // - Array of ChoiceParameter
	
	For IndexOf = 0 To ListOfSelectionParameters.UBound() Do
		If ListOfSelectionParameters[IndexOf].Name = "Filter.OSType" Then
			ListOfSelectionParameters.Delete(IndexOf);
			Break;
		EndIf;
	EndDo;
	
	ArrayOfFATypes = New Array;
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DisposeFixedAssets")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialFixedAssetsDisposal") Then
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.Asset"));
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.GroupFA"));
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets"));
	EndIf;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.WriteOffSubAssetsComponentsOfDepreciation")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialFixedAssetsDisposal") Then
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.Node"));
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.DepreciationComponent"));
	EndIf;
	
	If ArrayOfFATypes.Count() <> 0 Then
		ChoiceParameter = New ChoiceParameter("Filter.OSType", New FixedArray(ArrayOfFATypes));
		ListOfSelectionParameters.Add(ChoiceParameter);
		Items.FAFixedAsset.ChoiceParameters = New FixedArray(ListOfSelectionParameters);
	EndIf;

EndProcedure

&AtServer
Procedure FillInInformationInBasement()

	LabelTitle = New Array;
	
	CommonClientServer.SupplementArray(LabelTitle, NonCurrentAssetsInternal.DocumentInformationInAnotherAccounting(Object));
	
	
	If LabelTitle.Count() <> 0 Then
		Items.Information.Title = New FormattedString(LabelTitle);
		Items.PictureInformation.Visible = True;
		Items.Information.Visible = True;
	Else
		Items.PictureInformation.Visible = False;
		Items.Information.Visible = False;
	EndIf; 

EndProcedure

&AtServer
Procedure ProcessingSelectionOfProductsOnServer(Val ValueSelected)
	
	If TypeOf(ValueSelected) = Type("Array") Then
		GoodsList = ValueSelected;
	Else
		GoodsList = New Array;
		GoodsList.Add(ValueSelected);
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
								New Structure("Products", "ItemsType"));
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);
		
	RowsToProcess = New Array;
	
	For Each RowOfProduct In GoodsList Do
		CurrentRow = Object.RecordedAsReceivedTangibleAssets.Add();
		CurrentRow.Products = RowOfProduct;
		RowsToProcess.Add(CurrentRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.RecordedAsReceivedTangibleAssets);
			
	FillInServiceDetails();
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
								New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute",
								New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.RecordedAsReceivedTangibleAssets, StructureOfActions);
	
	FillParameters = PurchasesServer.ParametersForFillingInServiceAttributesOfCCDNumber();
	FillParameters.FillInCountryOfOrigin = False;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.RecordedAsReceivedTangibleAssets, FillParameters);
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()

	FillInInformationInBasement();
	
	ConfigureDependentFormElementsOnServer("Date");
	
EndProcedure

&AtServer
Procedure WhenChangingFAOnServer()
	
	FillInHeaderForSelectedFA();
	CheckMainMeansForInventory(Object);
	FillInInformationInBasement();
	
	If UseTraceableImportedGoodsAccounting Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
	EndIf;

	ConfigureDependentFormElementsOnServer("FixedAsset");
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedFA()

	ChangedBankingDetails = "FixedAsset";
	
	NonCurrentAssetsInternal.FillInHeaderForSelectedFA(
		"Organization,Department", Object.FA, Object, ChangedBankingDetails);
		
	If Not ValueIsFilled(Object.ExpensesPostingMethod) Then
		
		Object.ExpensesPostingMethod = NonCurrentAssetsInternal.WayToReflectFAExpenses(
			Object,
			NonCurrentAssetsInternal.FirstFilledValueInTable(Object.FA, "FixedAsset"));
		
		If ValueIsFilled(Object.ExpensesPostingMethod) Then
			
			NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
				Object.ExpensesPostingMethod, 
				Object.ExpenseItem, 
				Object.DimensionOfExpenses, 
				Object.ExpensesBusinessUnit, 
				Object.ExpenseLineOfBusiness, 
				Object.BusinessUnitAndLineOfBusinessMatchAccountingData);
				
			IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);
			
			Object.DimensionCorrespondsToFAToWriteOff = False;
			
			ChangedBankingDetails = ChangedBankingDetails + "," + "ExpensesPostingMethod,DimensionCorrespondsToFAToWriteOff,BusinessUnitAndLineOfBusinessMatchAccountingData";
			
		EndIf;
		
	EndIf;
	
	Documents.DisposeFixedAssets2_4.FillInExpenseItemRetirement(
		Object.Organization, Object.Date, Object.FA, Object.RetirementItem);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInDebitedAmountOnServer()
	
	Documents.DisposeFixedAssets2_4.FillInAmountOfWriteOffBasedOnDisposalOfGoodsAndMaterials(Object);
		
EndProcedure

&AtClient
Procedure OpenListOfBasesEnd(Result, AdditionalParameters) Export
	
	If Result <> Undefined 
		And TypeOf(Result) = Type("Array") Then
		
		Object.Basis1.Clear();
		
		If Result.Count() = 1 Then
			
			Object.DocumentBasis = Result[0];
			
		ElsIf Result.Count() > 1 Then
			
			For Each ArrayElement In Result Do
				RowData = Object.Basis1.Add();
				RowData.DocumentBasis = ArrayElement;
			EndDo;
			
		EndIf;
		
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, "Basis1");
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CheckMainMeansForInventory(Object)
	
	If Object.RecordedAsReceivedTangibleAssets.Count() = 0 Then
		Return;
	EndIf;
	
	ListOfFA = New Array;
	For Each RowData In Object.FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;
	
	For Each RowData In Object.RecordedAsReceivedTangibleAssets Do
		If ValueIsFilled(RowData.FixedAsset)
			And ListOfFA.Find(RowData.FixedAsset) = Undefined Then
			RowData.FixedAsset = PredefinedValue("Catalog.Assets.EmptyRef");
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function AvailableFixedAssets()
	
	AvailableFixedAssets = Object.FA.Unload(,"FixedAsset").UnloadColumn("FixedAsset");
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.PartialFixedAssetsDisposal Then
		NodesList = NonCurrentAssets.GetFANodes(AvailableFixedAssets, Object.DateOfDeduction);
	
		While NodesList.Next() Do
			AvailableFixedAssets.Add(NodesList.FixedAsset);
		EndDo;
	EndIf;
	
	Return AvailableFixedAssets;
	
EndFunction

&AtClient
Function DataOnTraceableGoodsIsCorrect()
	
	DataCorrect = True;
	FixedAssets = AvailableFixedAssets();
	For Each Page1 In Object.TraceableGoods Do
		If FixedAssets.Find(Page1.FixedAsset) = Undefined Then
			MessageString = NStr("vi = 'Dữ liệu phần bảng ghi giảm hàng hóa có truy xuất nguồn gốc không tương ứng với dữ liệu về tài sản cố định. 
			|Giá trị %1 không có trong phần bảng ""Tài sản cố định"".';
			|ru = 'Данные табличной части списываемых прослеживаемых товаров не соответствуют данным основных средствах. 
			|Значение %1 отсутствует в табличной части ""Основные средства"".';
			|en = 'Data of the table of traceable goods to write off does not correspond to the data of fixed assets. 
			|The %1 value is missing in the ""Fixed assets"" table.'; fa = 'Data of the table of traceable goods to write off does not correspond to the data of fixed assets. 
			|The %1 value is missing in the ""Fixed assets"" table.';
			|it = 'I dati della parte tabellare degli articoli tracciabili stornabili non corrispondono ai dati delle immobilizzazioni. 
			|Il valore %1 manca nella parte tabellare ""Immobilizzazioni"".';
			|pl = 'Dane sekcji tabelarycznej rozchodowanych towarów identyfikowalnych nie są zgodne z danymi o środkach trwałych. 
			|Brak wartości %1 w sekcji tabelarycznej ""Środki trwałe"".';
			|tr = 'İzlenebilir malların silinmesi tablosunun verileri sabit kıymetlerin verileriyle uyuşmamaktadır. 
			|""Sabit kıymetler"" tablo kısmında %1 değeri eksik.'"); 
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Page1.FixedAsset);
			CommonClient.MessageToUser(MessageString,Object.Ref);
			DataCorrect = False;	
		EndIf;	
	EndDo;

	Return DataCorrect;
EndFunction

&AtServer
Function AddressInStorage()
	
	Tab = New ValueTable();
	
	AddressOfTraceableGoodsBalances = PutToTempStorage(
		Tab,
		UUID);

	Return AddressOfTraceableGoodsBalances; 
	
EndFunction

&AtClient
Procedure SelectionByStockCompletion(Result, AdditionalParameters) Export
	
	PerformanceMonitorClient.TimeMeasurement(
	"Document.DisposeFixedAssets2_4.Form.DocumentForm.SearchForTraceableProductBalances");
	
	AddressOfTraceableGoodsBalances = AddressInStorage();

	PickingParameters = New Structure;
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("AddressOfTraceableGoodsBalances", AddressOfTraceableGoodsBalances);
	FixedAssets = New ValueList();
	FixedAssets.LoadValues(AvailableFixedAssets());
	PickingParameters.Insert("FixedAssets", FixedAssets);
	AccountingForTraceableGoodsClientLocalization.OpenSelectionForm(PickingParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure GetTraceableItemsFromStorage(AddressOfTraceableGoodsBalances)
	
	DisposeFixedAssetsLocalization.GetTraceableItemsFromStorage(Object, AddressOfTraceableGoodsBalances);

EndProcedure

&AtServer
Procedure DeleteTableRowsWithIncorrectFATypes()

	If Object.FA.Count() = 0 Then
		Return;
	EndIf;

	ValueMap = Common.ObjectsAttributeValue(Object.FA.Unload().UnloadColumn("FixedAsset"), "OSType");
	ArrayOfFAToDelete = New Array;
	
	For Each MapRow In ValueMap Do
		If (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DisposeFixedAssets")
				And (MapRow.Value = PredefinedValue("Enum.FATypes.Node")
					Or MapRow.Value = PredefinedValue("Enum.FATypes.DepreciationComponent")))
			Or (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.WriteOffSubAssetsComponentsOfDepreciation")
				And MapRow.Value <> PredefinedValue("Enum.FATypes.Node")
				And MapRow.Value <> PredefinedValue("Enum.FATypes.DepreciationComponent")) Then
			
			ArrayOfFAToDelete.Add(MapRow.Key);

		EndIf;
	EndDo;
	
	For Each FAToRemove In ArrayOfFAToDelete Do
		FilterParameters = New Structure("FixedAsset", FAToRemove);
		
		FoundRows = Object.FA.FindRows(FilterParameters);
		For Each TSRow In FoundRows Do
			Object.FA.Delete(TSRow);
		EndDo;
		
		FoundRows = Object.RecordedAsReceivedTangibleAssets.FindRows(FilterParameters);
		For Each TSRow In FoundRows Do
			Object.RecordedAsReceivedTangibleAssets.Delete(TSRow);
		EndDo;
		
		FoundRows = Object.TraceableGoods.FindRows(FilterParameters);
		For Each TSRow In FoundRows Do
			Object.TraceableGoods.Delete(TSRow);
		EndDo;
		
	EndDo;

EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If ValueIsFilled(Object.Organization) Then
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.RecordedAsReceivedTangibleAssets);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
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

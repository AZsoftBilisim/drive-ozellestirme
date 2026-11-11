
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
	
	ItemsAndDimensionsSelectionParameters = Documents.ReturnAssetsFromLeasee2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	SetupParameters = Documents.ReturnAssetsFromLeasee2_4.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	
	#Region StandardSubsystems
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
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

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion

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
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();

	ItemsAndDimensionsSelectionParameters = Documents.ReturnAssetsFromLeasee2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	SetupParameters = Documents.ReturnAssetsFromLeasee2_4.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ReturnAssetsFromLeasee2_4", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	

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
	
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
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

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure GeneratedDocumentOnChange(Item)
	
	If Object.GeneratedDocument Then
		FilterParameters = New Structure;
		FilterParameters.Insert("Organization", Object.Organization);
		FilterParameters.Insert("Leaseholder", Object.Leaseholder);
		FilterParameters.Insert("Department", Object.Department);
		FilterParameters.Insert("Posted", True);
		FormParameters = New Structure;
		FormParameters.Insert("Filter", FilterParameters);
		
		CallbackDescription = New CallbackDescription("SelectingFoundationDocument", ThisObject);
		OpenForm("Document.ProvideAssetsToLeasee2_4.ChoiceForm", FormParameters, ThisObject, ThisObject,,, CallbackDescription);
	Else
		Object.DocumentBasis = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);

	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure LeaseholderIntercompanyARAPOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	If PreviousValueDivision = Object.ReceivingBusinessUnit Then
		Object.ReceivingBusinessUnit = Object.Department;
	EndIf;
	
	PreviousValueDivision = Object.Department;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return; // WE have an empty handler
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

#EndRegion

#Region LandlordAccountingPage

&AtClient
Procedure LocationAddressOnChange(Item)
	
	WhenChangingAddressPresentation(Item);
	
EndProcedure

&AtClient
Procedure LocationAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NonCurrentAssetsClient.OpenAddressSelectionFormAndProcessResult(
		ThisObject,
		Item,
		Object,, 
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure LocationAddressClearing(Item, StandardProcessing)
	
	WhenChangingAddressPresentation(Item);
	
EndProcedure

&AtClient
Procedure DepreciationAccrualLocalAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure DepreciationAccrualManOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure ExpenseRecordMethodACOnChange(Item)
	
	ChangedBankingDetails = "ExpenseRecordMethodAC,ExpenseItemAccounting,BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpenseRecordMethodAC, 
		Object.ExpenseItemAccounting, 
		Object.ExpensesDimensionAccounting, 
		Object.DepartmentACC, 
		Object.LineOfBusinessBookkeeping, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping);
	
	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemAccounting);
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure ExpenseItemAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		Object.ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("ExpenseRecordMethodAC,ExpenseItemAccounting");
	
EndProcedure

&AtClient
Procedure ExpenseItemAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingOnChange(Item)

	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		Object.ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodAC");
	EndIf;

EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepartmentACCOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		Object.ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("ExpenseRecordMethodAC,DepartmentACC");
	
EndProcedure

&AtClient
Procedure LineOfBusinessBookkeepingOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		Object.ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("ExpenseRecordMethodAC,LineOfBusinessBookkeeping");

EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeepingOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		Object.ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("ExpenseRecordMethodAC,BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping");
	
EndProcedure

&AtClient
Procedure MethodForReflectingMaExpensesOnChange(Item)
	
	ChangedBankingDetails = "MethodForReflectingMaExpenses,ExpenseItemManagementAccounting,BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.MethodForReflectingMaExpenses, 
		Object.ExpenseItemManagementAccounting, 
		Object.ExpensesDimensionManagementAccounting, 
		Object.BusinessUnitManagementAccounting, 
		Object.LineOfBusinessManagementAccounting, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting);
	
	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemManagementAccounting);
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure ExpenseItemManagementAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodForReflectingMaExpenses,ExpenseItemManagementAccounting");
	
EndProcedure

&AtClient
Procedure ExpenseItemManagementAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitManagementAccountingOnChange(Item)
	
	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("MethodForReflectingMaExpenses,BusinessUnitManagementAccounting");
	
EndProcedure

&AtClient
Procedure LineOfBusinessManagementAccountingOnChange(Item)
	
	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodForReflectingMaExpenses,LineOfBusinessManagementAccounting");

EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccountingOnChange(Item)
	
	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodForReflectingMaExpenses,BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting");
	
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
Procedure FASelection(Item, RowSelected, Field, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FAOnStartEdit(Item, NewRow, Copy)
	
	If Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected).Count() <> 0 Then
		WhenChangingFAOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	CurrentData = Items.FA.CurrentData;
	WhenChangingFAOnServer(CurrentData.FixedAsset);

EndProcedure

&AtClient
Procedure FAExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.FA.CurrentData;
	SetParametersForSelectingExpenseItem_(CurrentData.FixedAssetsAccountingProcedure);
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FAExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ExpenseAnalyticsFAStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseAnalyticsFAAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseAnalyticsFATextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FAAccountingProcedureForFAOnChange(Item)
	
	CurrentData = Items.FA.CurrentData;
	FAFAAccountingProcedureForChangesOnServer(CurrentData.FixedAssetsAccountingProcedure);
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "Object.FA");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	FASelectionParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					FASelectionParameters, Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow);
	
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

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ImportDataFromPDT(Command)
	
	LoadDataFromTSD();
	
EndProcedure

#EndRegion

#Region UniversalMechanisms_Commands

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


#EndRegion

#Region AttachableCommands

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

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClient
Procedure WhenChangingAddressPresentation(Item)

	NonCurrentAssetsClient.WhenChangingAddressPresentation(
		Item,
		Object.LocationAddress,
		Object.LocationAddressValue);

EndProcedure

#EndRegion

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

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializeServiceParametersOfForm();
	
	PreviousValueDivision = Object.Department;
	Items.LeaseholderIntercompanyARAP.ReadOnly = Not GetFunctionalOption("UseMultipleCompanies");
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure WhenChangingFAOnServer(FixedAsset = Undefined)
	
	FillInHeaderForSelectedFA();
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedFA()

	NonCurrentAssetsInternal.FillInHeaderForSelectedFA("Organization,Department", Object.FA, Object);
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Val Form, Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	OnChangeAttributes(Form, StructureOfChangedProps);
	
	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	AuxiliaryAttributes.Insert("ReturnFromFinarenda", FormServiceParameters.ReturnFromFinarenda);
	AuxiliaryAttributes.Insert("Sublease", FormServiceParameters.Sublease);
	
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentProps_FARefundFromLease(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters);
	EndIf; 
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		PropertyValue = 
			Items.DepreciationAccrualLocalAccounting.Visible
			And Items.DepreciationAccrualMan.Visible;
		
		Items.GroupDepreciationAndAmortisationBU.ShowTitle = PropertyValue;
		Items.GroupDepreciationAndAmortisationUU.ShowTitle = PropertyValue;
		
	EndIf;
	
	If StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		ChoiceList = Items.FAFixedAssetsAccountingProcedure.ChoiceList;
		If AuxiliaryAttributes.Sublease Then
			ChoiceList.Clear();
			ChoiceList.Add(
				PredefinedValue("Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets"));
		Else
			ChoiceList.Clear();
			ChoiceList.Add(
				PredefinedValue("Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets"));
			ChoiceList.Add(
				PredefinedValue("Enum.OptionsForFAAccountingWhenReturningFromLessee.TakeIntoAccountAsRentalInvestment"));
			ChoiceList.Add(
				PredefinedValue("Enum.OptionsForFAAccountingWhenReturningFromLessee.ToExpenseAs"));
			ChoiceList.Add(
				PredefinedValue("Enum.OptionsForFAAccountingWhenReturningFromLessee.WriteOffToAssetItem"));
		EndIf;

	EndIf;
	
	#Region PageExpenseRecord
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		PropertyValue = 
			Items.DepreciationAccrualLocalAccounting.Visible
			And Items.DepreciationAccrualMan.Visible;
		
		Items.GroupDepreciationAndAmortisationBU.ShowTitle = PropertyValue;
		Items.GroupDepreciationAndAmortisationUU.ShowTitle = PropertyValue;
		
	EndIf;
	
	If StructureOfChangedProps.Property("ExpenseRecordMethodAC") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpenseRecordMethodAC, 
			Form,
			"ExpenseItemAccounting,ExpensesDimensionAccounting,DepartmentACC,LineOfBusinessBookkeeping,BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping");
	
	EndIf;
	
	If StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.MethodForReflectingMaExpenses, 
			Form,
			"ExpenseItemManagementAccounting,ExpensesDimensionManagementAccounting,BusinessUnitManagementAccounting,LineOfBusinessManagementAccounting,BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting");
	
	EndIf;

	#EndRegion
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date),
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"ReturnFromFinarenda",
			ValueIsFilled(Object.Contract),
			FormServiceParameters);
			
		ContractDetails_ = LeasedAssetAccounting.AttributesOfCounterpartySContract(Object.Contract);
		NonCurrentAssetsInternal.SetStructureProperty(
			"Sublease",
			ContractDetails_.ContractType = Enums.ContractTypes.Sublease,
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Contract") Then
		FillWithRentedOnServer();
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	Return StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("Organization");

EndFunction

&AtClientAtServerNoContext
Procedure OnChangeAttributes(Form, StructureOfChangedProps)
	
	Object = Form.Object;

	FormServiceParameters = Form.FormServiceParameters;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date") Then
		
		If FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Object.LeaseholderIntercompanyARAP Then
			Object.Leaseholder = PredefinedValue("Catalog.Counterparties.EmptyRef");
			Object.LeaseholderIntercompanyARAP = False;
			StructureOfChangedProps.Insert("LeaseholderIntercompanyARAP");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", False);
	NewServiceParametersOfForm.Insert("ReturnFromFinarenda", False);
	NewServiceParametersOfForm.Insert("Sublease", False);
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region FairCostFA_Text
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAExpenseItem.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FADimensionOfExpenses.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAAssetsLiabilitiesDimension.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.FixedAssetsAccountingProcedure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure FAFAAccountingProcedureForChangesOnServer(FixedAssetsAccountingProcedure)
	
	SetParametersForSelectingExpenseItem_(FixedAssetsAccountingProcedure);
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.FAExpenseItem);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingExpenseItem_(FixedAssetsAccountingProcedure)
	
	ArticleSelectionParameters = New Array;
	If FixedAssetsAccountingProcedure = Enums.OptionsForFAAccountingWhenReturningFromLessee.TakeIntoAccountAsRentalInvestment Then
		
		ArticleSelectionParameter = New ChoiceParameter(
			"Filter.CostAllocationOption",
			Enums.CostAllocationOptions.ToNonCurrentAssetCost);
		ArticleSelectionParameters.Add(ArticleSelectionParameter);
		
		ArticleSelectionParameter = New ChoiceParameter("Filter.ExpensesOnAssets", True);
		ArticleSelectionParameters.Add(ArticleSelectionParameter);
		
		ArticleSelectionParameter = New ChoiceParameter("AddExpenseItems", True);
		ArticleSelectionParameters.Add(ArticleSelectionParameter);
		ArticleSelectionParameter = New ChoiceParameter("AddIncomeItems", False);
		ArticleSelectionParameters.Add(ArticleSelectionParameter);
		ArticleSelectionParameter = New ChoiceParameter("AddItemsOfAssetsLiabilities", False);
		ArticleSelectionParameters.Add(ArticleSelectionParameter);
		
	ElsIf FixedAssetsAccountingProcedure = Enums.OptionsForFAAccountingWhenReturningFromLessee.ToExpenseAs Then
		
		ArticleSelectionParameter = New ChoiceParameter("AddExpenseItems", True);
		ArticleSelectionParameters.Add(ArticleSelectionParameter);
		ArticleSelectionParameter = New ChoiceParameter("AddIncomeItems", False);
		ArticleSelectionParameters.Add(ArticleSelectionParameter);
		ArticleSelectionParameter = New ChoiceParameter("AddItemsOfAssetsLiabilities", False);
		ArticleSelectionParameters.Add(ArticleSelectionParameter);
		
	ElsIf FixedAssetsAccountingProcedure = Enums.OptionsForFAAccountingWhenReturningFromLessee.WriteOffToAssetItem Then
		
		ArticleSelectionParameter = New ChoiceParameter("AddExpenseItems", False);
		ArticleSelectionParameters.Add(ArticleSelectionParameter);
		ArticleSelectionParameter = New ChoiceParameter("AddIncomeItems", False);
		ArticleSelectionParameters.Add(ArticleSelectionParameter);
		ArticleSelectionParameter = New ChoiceParameter("AddItemsOfAssetsLiabilities", True);
		ArticleSelectionParameters.Add(ArticleSelectionParameter);
		
	EndIf;

	Items.FAExpenseItem.ChoiceParameters = New FixedArray(ArticleSelectionParameters);
	
EndProcedure

&AtServer
Procedure FillWithRentedOnServer()

	If Not ValueIsFilled(Object.Contract) Or Not ValueIsFilled(Object.Organization) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	AssetsLeasedOut.FixedAsset AS FixedAsset,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem
	|FROM
	|	InformationRegister.AssetsLeasedOut.SliceLast(
	|			&Date,
	|			Organization = &Organization) AS AssetsLeasedOut
	|WHERE
	|	AssetsLeasedOut.Contract = &Contract
	|	AND AssetsLeasedOut.State IN (VALUE(Enum.FixedAssetsStates.LeasedOut))
	|";

	Query = New Query(QueryText);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("Date", 
		?(ValueIsFilled(Object.Date), 
			New Boundary(Object.Date, BoundaryType.Excluding),
			CurrentSessionDate()));
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Object.FA.Load(Result.Unload());
	IncomeAndExpensesServer.UpdateServiceDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure SelectingFoundationDocument(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		Object.DocumentBasis = Result;
	Else
		Object.GeneratedDocument = False;
	EndIf;
	
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

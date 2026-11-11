
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
	
	ItemsAndDimensionsSelectionParameters = Documents.ProvideAssetsToLeasee2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
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
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	InterestScheduleUpdated = True;

	ItemsAndDimensionsSelectionParameters = Documents.ProvideAssetsToLeasee2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ProvideAssetsToLeasee2_4", WriteParameters, Object.Ref);
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

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If TransferForLeaseUnderFAS25 Then
		If InterestScheduleUpdated Then
			InterestScheduleUpdated = Object.InterestAccrualSchedule.Count();
		EndIf;
		CurrentObject.AdditionalProperties.Insert("InterestScheduleUpdated", InterestScheduleUpdated);
	EndIf;
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If TransferForLeaseUnderFAS25 Then
		
		ForceCloseTheForm = False;
		If WriteParameters.Property("ForceCloseTheForm", ForceCloseTheForm)
			And Not ForceCloseTheForm 
			Or WriteParameters.WriteMode = DocumentWriteMode.UndoPosting Then
				
			LeasedAssetAccounting.FillInGraphFilledColumn(
				Object.FA,
				Object.ServicePaymentSchedule,
				Object.ServiceAccrualSchedule);
				
			CalculateRateOfReturnOnServer(False, False);
			DisplayGraphOfPercentagesFromRegister = False;
		
		EndIf;
		
	EndIf;

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	

	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
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
Procedure ExpenseItemManagementAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemManagementAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemManagementAccounting);
	
	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodForReflectingMaExpenses,ExpenseItemManagementAccounting");
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingOnChange(Item)

	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("MethodForReflectingMaExpenses");
	EndIf;

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

&AtClient
Procedure IncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
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
Procedure ContractOnChange(Item)
	
	AddContractDetailsToServiceParametersOfForm();
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure AmountOfAdvancePaymentsOnChange(Item)
	
	If FormServiceParameters.ContractDetails_.ARAPCurrency = FormServiceParameters.ComplCurrency Then
		
		Object.AmountOfAdvancePaymentsLocal = Object.AmountOfAdvancePayments;
		
	EndIf;
	
EndProcedure

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

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return; // WE have an empty handler
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected).Count() <> 0 Then
		WhenChangingFAOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FASelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "FAScheduleRef" Then
		OpenFillInSchedule(RowSelected);
		StandardProcessing = False;
	EndIf;
	
	If Field.Name = "FARateOfReturn" Then
		ShowCalculation(Items.FA.CurrentData);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure FABeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.FA.CurrentData;
	
	If CurrentData <> Undefined Then
		
		LeasedAssetAccountingClient.RemoveFAFromCharts(Object, CurrentData.FixedAsset);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FAOnActivateRow(Item)
	SetAvailabilityOfHelpPrinting(Item.CurrentData);
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	WhenChangingFAOnServer();
	
EndProcedure

&AtClient
Procedure FAFairNetInitialCostLocalOnChange(Item)

	CurrentData = Items.FA.CurrentData;
	UpdateAmount(CurrentData.FairValueLocal, CurrentData.FairValueManag, FormServiceParameters.ConversionRateToManCurrency);
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure OSNGLESLocalOnChange(Item)
	
	CurrentData = Items.FA.CurrentData;
	UpdateAmount(CurrentData.NonGuaranteedResidualValueLocal, CurrentData.NonGuaranteedResidualValueManag, FormServiceParameters.ConversionRateToManCurrency);
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure FAFairNetInitialCostCoOnChange(Item)
	
	CurrentData = Items.FA.CurrentData;
	UpdateAmount(CurrentData.FairValueManag, CurrentData.FairValueLocal, FormServiceParameters.FactorOfConversionToCurrencyOfRegul);
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure OSNGLSManOnChange(Item)
	
	CurrentData = Items.FA.CurrentData;
	UpdateAmount(CurrentData.NonGuaranteedResidualValueManag, CurrentData.NonGuaranteedResidualValueLocal, FormServiceParameters.FactorOfConversionToCurrencyOfRegul);
	ConfigureDependentFormElements(Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pickup(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCharts(Command)
	
	SelectedFA = New Array;
	For Each SelectedRow In Items.FA.SelectedRows Do
		RowData = Object.FA.FindByID(SelectedRow);
		SelectedFA.Add(RowData.FixedAsset);
	EndDo;
	
	AddressOfGraphs = PutGraphsInTemporaryStorage(Object, UUID);
	
	LeasedAssetAccountingClient.OpenFillingInRentalIncomeSchedules(
		Object,
		ThisObject,
		SelectedFA,
		AddressOfGraphs,
		New CallbackDescription("FillInScheduleOfPaymentsAndAccrualsEnd", ThisObject));
		
EndProcedure

&AtClient
Procedure FillInAmountOfAdvancePayments(Command)
	
	FillPropertyValues(Object, AmountOfAdvancePayments(Object.Contract, Object.Date));
	
EndProcedure

&AtClient
Procedure CalculateRateOfReturn(Command)
	
	ExecutionResult = CalculateRateOfReturnOnServerInBackground();
		
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);

	TimeConsumingOperationsClient.WaitCompletion(ExecutionResult,
		New CallbackDescription("CalculateRateOfReturnCompletion", ThisObject),
		IdleParameters);
	
EndProcedure

&AtClient
Procedure ReferenceCalculationOfAccrualOfInterest(Command)
	
	LeasedAssetAccountingClient.ReferenceCalculationOfAccrualOfInterest(ThisObject);
	
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

#Region StandardSubsystems_Commands

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

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

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	PreviousValueDivision = Object.Department;
	
	ConfigureDependentFormElementsOnServer();
	
	If TransferForLeaseUnderFAS25 Then
		LeasedAssetAccounting.FillInGraphFilledColumn(
			Object.FA,
			Object.ServicePaymentSchedule,
			Object.ServiceAccrualSchedule); 
		CalculateRateOfReturnOnServer(False, False);
		DisplayGraphOfPercentagesFromRegister = True;
	EndIf
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedDetailsOrElement = "")

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
	AuxiliaryAttributes.Insert("TransferForLeaseUnderFAS25", Form.TransferForLeaseUnderFAS25);
	AuxiliaryAttributes.Insert("ContractInLocalAccountingCurrency",
		FormServiceParameters.ContractDetails_.ARAPCurrency = FormServiceParameters.ComplCurrency);

	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentProps_TransferToOSV(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters);
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
	
	If UpdateAll Then
		Items.LeaseholderIntercompanyARAP.ReadOnly = Not GetFunctionalOption("UseMultipleCompanies");
	EndIf;
	
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
			"TransferToRentalSubleaseBasedOnRussianGAAPFSBU25",
			GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25"),
			FormServiceParameters);
			
		CurrencyOfMan = SettingsValueCached.ManagementAccountingCurrency();
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
		NonCurrentAssetsInternal.SetStructureProperty("CurrencyOfMan", CurrencyOfMan, FormServiceParameters);
		NonCurrentAssetsInternal.SetStructureProperty("ComplCurrency", ComplCurrency, FormServiceParameters);
		NonCurrentAssetsInternal.SetStructureProperty("CurrencyOfManPresentation", String(CurrencyOfMan), FormServiceParameters);
		NonCurrentAssetsInternal.SetStructureProperty("ComplCurrencyPresentation", String(ComplCurrency), FormServiceParameters);

		FactorOfConversionToCurrencyOfRegul = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			CurrencyOfMan,
			ComplCurrency,
			Object.Date);
		ConversionRateToManCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			ComplCurrency,
			CurrencyOfMan,
			Object.Date);
			
		NonCurrentAssetsInternal.SetStructureProperty("ConversionRateToManCurrency", ConversionRateToManCurrency, FormServiceParameters);
		NonCurrentAssetsInternal.SetStructureProperty("FactorOfConversionToCurrencyOfRegul", FactorOfConversionToCurrencyOfRegul, FormServiceParameters);
		
		AddContractDetailsToServiceParametersOfForm();
		
		SetFASelectionParameters();
		
		If TransferForLeaseUnderFAS25 Then
			
			Items.FAFairValueLocal.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
					NStr("vi = 'KTDN';
						|ru = 'БУ';
						|en = 'LA'; fa = 'محلی';
						|it = 'БУ';
						|pl = 'EK';
						|tr = 'Muhasebe'"), 
					FormServiceParameters.ComplCurrencyPresentation);
					
			Items.FAFairValueManag.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
					NStr("vi = 'KTQT';
						|ru = 'УУ';
						|en = 'MA'; fa = 'مدیریت';
						|it = 'УУ';
						|pl = 'EZ';
						|tr = 'Yönetim muhasebesi'"), 
					FormServiceParameters.CurrencyOfManPresentation);
					
			Items.FANonGuaranteedResidualValueLocal.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
					NStr("vi = 'KTDN';
						|ru = 'БУ';
						|en = 'LA'; fa = 'محلی';
						|it = 'БУ';
						|pl = 'EK';
						|tr = 'Muhasebe'"), 
					FormServiceParameters.ComplCurrencyPresentation);
					
			Items.FANonGuaranteedResidualValueManag.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
					NStr("vi = 'KTQT';
						|ru = 'УУ';
						|en = 'MA'; fa = 'مدیریت';
						|it = 'УУ';
						|pl = 'EZ';
						|tr = 'Yönetim muhasebesi'"), 
					FormServiceParameters.CurrencyOfManPresentation);
					
			Items.FARentalPayments.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
					NStr("vi = 'Thanh toán tiền thuê (không gồm thuế GTGT)';
						|ru = 'Арендные платежи (без НДС)';
						|en = 'Rental payments (excluding VAT)'; fa = 'Rental payments (excluding VAT)';
						|it = 'Арендные платежи (без НДС)';
						|pl = 'Rental payments (excluding VAT)';
						|tr = 'Kira ödemeleri (KDV hariç)'"), 
					FormServiceParameters.ContractDetails_.ARAPCurrencyPresentation);
			
			Items.AmountOfAdvancePayments.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
					NStr("vi = 'Số tiền thanh toán
						|trả trước (không gồm thuế GTGT)';
						|ru = 'Сумма предварительных
						|платежей (без НДС)';
						|en = 'Amount of
						|prepayments (excluding VAT)'; fa = 'Amount of
						|prepayments (excluding VAT)';
						|it = 'Сумма предварительных
						|платежей (без НДС)';
						|pl = 'Amount of
						|prepayments (excluding VAT)';
						|tr = 'Ön ödemelerin
						|tutarı (KDV hariç)'"), 
					FormServiceParameters.ContractDetails_.ARAPCurrencyPresentation);
			
			Items.AmountOfAdvancePaymentsLocal.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
					NStr("vi = 'Số tiền thanh toán
						|trả trước (không gồm thuế GTGT)';
						|ru = 'Сумма предварительных
						|платежей (без НДС)';
						|en = 'Amount of
						|prepayments (excluding VAT)'; fa = 'Amount of
						|prepayments (excluding VAT)';
						|it = 'Сумма предварительных
						|платежей (без НДС)';
						|pl = 'Amount of
						|prepayments (excluding VAT)';
						|tr = 'Ön ödemelerin
						|tutarı (KDV hariç)'"), 
					FormServiceParameters.ComplCurrencyPresentation);
			
		EndIf;
		
	EndIf;
	
	SetUpTenantAgreement();
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure SetUpTenantAgreement()
	
	// Leasing of the OS between organizations.
	//   The visibility of the contract field depends on the functional option to use agreements between organizations.
	//   The type of the Tenant Organization field.
	//   The type of the Agreement field is the Agreement between organizations.
	If Object.LeaseholderIntercompanyARAP Then
		FunctionalOptionName = "UseIntercompanyContracts";
		TypeOfTenantField = New TypeDescription("CatalogRef.Companies");
		TypeOfContractField   = New TypeDescription("CatalogRef.IntercompanyContracts");
		CommunicationOrganization = New ChoiceParameterLink("Filter.Organization", "Object.Organization");
		ContactCounterparty  = New ChoiceParameterLink("Filter.CompanyRecipient", "Object.Leaseholder");
		
	// Leasing between an organization and a counterparty.
	//   The visibility of the contract field depends on the functional option to use the contract by customers.
	//   The type of the Tenant Counterparty field.
	//   The type of the field is the Contract of the contractors.
	Else
		FunctionalOptionName = "UseCustomerContracts";
		TypeOfTenantField = New TypeDescription("CatalogRef.Counterparties");
		TypeOfContractField   = New TypeDescription("CatalogRef.CounterpartyContracts");
		CommunicationOrganization = New ChoiceParameterLink("Filter.Organization", "Object.Organization");
		ContactCounterparty  = New ChoiceParameterLink("Filter.Counterparty", "Object.Leaseholder");
	EndIf;
	
	ContractSelectionParameters_ = New Array();
	ContractSelectionParameters_.Add(CommunicationOrganization);
	ContractSelectionParameters_.Add(ContactCounterparty);
	
	ContractParameters = New Array();
	ContractParameters.Add(New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	ContractParameters.Add(New ChoiceParameter("Filter.DeletionMark",False));
	
	Items.Contract.Visible = GetFunctionalOption(FunctionalOptionName);
	
	Items.Leaseholder.TypeRestriction = TypeOfTenantField;
	Items.Contract.TypeRestriction   = TypeOfContractField;
	
	Items.Contract.ChoiceParameterLinks = New FixedArray(ContractSelectionParameters_);
	
	// Prohibition on leasing to the same organization.
	If Object.LeaseholderIntercompanyARAP Then
		TenantSelectionParameters = New Array();
		TenantSelectionParameters.Add(New ChoiceParameter("DoNotSelectOrganization", Object.Organization));
		Items.Leaseholder.ChoiceParameters = New FixedArray(TenantSelectionParameters);
	EndIf;
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	Return StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("LeaseholderIntercompanyARAP");

EndFunction

&AtClientAtServerNoContext
Procedure OnChangeAttributes(Form, StructureOfChangedProps)
	
	Object = Form.Object;

	FormServiceParameters = Form.FormServiceParameters;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date") Then
		
		If Not FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Object.LeaseholderIntercompanyARAP Then
			Object.Leaseholder = PredefinedValue("Catalog.Counterparties.EmptyRef");
			Object.LeaseholderIntercompanyARAP = False;
			StructureOfChangedProps.Insert("LeaseholderIntercompanyARAP");
		EndIf;
		
	EndIf;

	If StructureOfChangedProps.Property("LeaseholderIntercompanyARAP") Then
		Object.Leaseholder = ?(Object.LeaseholderIntercompanyARAP,
			PredefinedValue("Catalog.Companies.EmptyRef"),
			PredefinedValue("Catalog.Counterparties.EmptyRef"));
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingAddressPresentation(Item)

	NonCurrentAssetsClient.WhenChangingAddressPresentation(
		Item,
		Object.LocationAddress,
		Object.LocationAddressValue);

EndProcedure

&AtServer
Procedure WhenChangingFAOnServer()
	
	FillInHeaderForSelectedFA();
	
	If TransferForLeaseUnderFAS25 Then
		LeasedAssetAccounting.FillInGraphFilledColumn(
			Object.FA,
			Object.ServicePaymentSchedule,
			Object.ServiceAccrualSchedule);
		InterestScheduleUpdated = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedFA()

	NonCurrentAssetsInternal.FillInHeaderForSelectedFA("Organization,Department", Object.FA, Object);
	
EndProcedure

&AtServer
Procedure AddContractDetailsToServiceParametersOfForm()
	
	ContractDetails_ = LeasedAssetAccounting.AttributesOfCounterpartySContract(Object.Contract);
	ContractDetails_.Insert("ARAPCurrencyPresentation", String(ContractDetails_.ARAPCurrency));

	NonCurrentAssetsInternal.SetStructureProperty(
		"ContractDetails_",
		ContractDetails_,
		FormServiceParameters);
		
	TransferForLeaseUnderFAS25 = FormServiceParameters.TransferToRentalSubleaseBasedOnRussianGAAPFSBU25
		And (ContractDetails_.ContractType = Enums.ContractTypes.TransferToRental
			Or ContractDetails_.ContractType = Enums.ContractTypes.Sublease);
		
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region FairCostFA_Text
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAFairValueLocal.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.FairValueLocal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tương ứng với bảng cân đối>';
													|ru = '<соответствует балансовой>';
													|en = '<corresponds to balance>'; fa = '<corresponds to balance>';
													|it = '<соответствует балансовой>';
													|pl = '<corresponds to balance>';
													|tr = '<bilançoya karşılık gelir>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAFairValueManag.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.FairValueManag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tương ứng với bảng cân đối>';
													|ru = '<соответствует балансовой>';
													|en = '<corresponds to balance>'; fa = '<corresponds to balance>';
													|it = '<соответствует балансовой>';
													|pl = '<corresponds to balance>';
													|tr = '<bilançoya karşılık gelir>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region FAScheduleRef
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAScheduleRef.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ScheduleIsFull");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Điền...';
													|ru = 'Заполнить...';
													|en = 'Fill...'; fa = 'تکمیل...';
													|it = 'Заполнить...';
													|pl = 'Fill...';
													|tr = 'Doldur...'"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAScheduleRef.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ScheduleIsFull");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Mở...';
													|ru = 'Открыть...';
													|en = 'Open…'; fa = 'باز کردن…';
													|it = 'Открыть...';
													|pl = 'Open…';
													|tr = 'Aç...'"));
	#EndRegion
	
EndProcedure

&AtClient
Procedure OpenFillInSchedule(ValueSelected)

	If ValueSelected = Undefined Then
		Return;
	EndIf;

	RowData = Object.FA.FindByID(ValueSelected);
	
	FixedAsset = RowData.FixedAsset;
	
	If Not ValueIsFilled(FixedAsset) Then
		Return;
	EndIf;
	
	If Not ReadOnly Then
		LockFormDataForEdit();
	EndIf;
	
	AddressOfGraphs = PutGraphsInTemporaryStorage(Object, UUID);
	
	If RowData.ScheduleIsFull Then
		
		LeasedAssetAccountingClient.OpenIncomeRentalCharts(
			Object,
			ThisObject,
			FixedAsset,
			AddressOfGraphs,
			New CallbackDescription("OpenPaymentAndAccrualScheduleCompletion", ThisObject));
			
	Else
			
		SelectedFA = New Array;
		SelectedFA.Add(FixedAsset);
		
		LeasedAssetAccountingClient.OpenFillingInRentalIncomeSchedules(
			Object,
			ThisObject,
			SelectedFA,
			AddressOfGraphs,
			New CallbackDescription("FillInScheduleOfPaymentsAndAccrualsEnd", ThisObject));
		
	EndIf;

EndProcedure

&AtServerNoContext
Function PutGraphsInTemporaryStorage(Val Object, Val UUID)

	ContractSchedules = New Structure;
	ContractSchedules.Insert("ServiceAccrualSchedule", Object.ServiceAccrualSchedule.Unload());
	ContractSchedules.Insert("ServicePaymentSchedule", Object.ServicePaymentSchedule.Unload());
	ContractSchedules.Insert("InterestAccrualSchedule", Object.InterestAccrualSchedule.Unload());
	ContractSchedules.Insert("FATable", Object.FA.Unload());

	Address = PutToTempStorage(ContractSchedules, UUID);
	
	Return Address;
	
EndFunction

&AtClient
Procedure OpenPaymentAndAccrualScheduleCompletion(ClosingResult, AddlParameters) Export

	If Not IsTempStorageURL(ClosingResult) Then
		Return
	EndIf;

	OpenPaymentAndAccrualScheduleDirectlyOnServer(ClosingResult);
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
	SetAvailabilityOfHelpPrinting(Items.FA.CurrentData);

EndProcedure

&AtClient
Procedure FillInScheduleOfPaymentsAndAccrualsEnd(ClosingResult, AddlParameters) Export

	If Not IsTempStorageURL(ClosingResult) Then
		Return
	EndIf;

	OpenPaymentAndAccrualScheduleDirectlyOnServer(ClosingResult);
	AttachableCommandsClient.StartCommandUpdate(ThisObject);

EndProcedure

&AtServer
Procedure OpenPaymentAndAccrualScheduleDirectlyOnServer(Val ClosingResult)
	
	Modified = True;

	ContractSchedules = GetFromTempStorage(ClosingResult);

	Object.ServicePaymentSchedule.Load(ContractSchedules.ServicePaymentSchedule);
	Object.ServiceAccrualSchedule.Load(ContractSchedules.ServiceAccrualSchedule);
	Object.InterestAccrualSchedule.Load(ContractSchedules.InterestAccrualSchedule);
	
	For Each RowData In ContractSchedules.FATable Do
		FAStrings = Object.FA.FindRows(New Structure("FixedAsset", RowData.FixedAsset));
		For Each FAString In FAStrings Do
			FillPropertyValues(FAString, RowData, "TheInterestAccrualScheduleIsEnteredManually, RentalEndDate");
		EndDo;
	EndDo;
	
	LeasedAssetAccounting.FillInGraphFilledColumn(
		Object.FA,
		Object.ServicePaymentSchedule,
		Object.ServiceAccrualSchedule);
	LeasedAssetAccounting.FillInAmountOfRentalPayments(
		Object,
		FormServiceParameters.ContractDetails_.ARAPCurrency);
	InterestScheduleUpdated = False;
	
EndProcedure

&AtServerNoContext
Function AmountOfAdvancePayments(Contract, DocumentDate)
	
	AdvanceData = New Structure;
	AdvanceData.Insert("AmountOfAdvancePayments", 0);
	AdvanceData.Insert("AmountOfAdvancePaymentsLocal", 0);
	
	If Not ValueIsFilled(Contract) Then
		Return AdvanceData;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DimensionByPartners.DimensionKey AS DimensionKey
	|INTO TTAnalyticsKeys
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|WHERE
	|	DimensionByPartners.Contract = &Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomersARAPAccountingBalance.PrepaymentBalance AS AmountOfAdvancePayments,
	|	CustomersARAPAccountingBalance.PrepaymentLocalBalance AS AmountOfAdvancePaymentsLocal,
	|	CustomersARAPAccountingBalance.AccountingDimensionByPartners.Contract.VATRate AS VATRate
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
	|			&DocumentDate,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					T.DimensionKey
	|				FROM
	|					TTAnalyticsKeys AS T)) AS CustomersARAPAccountingBalance
	|WHERE
	|	CustomersARAPAccountingBalance.PrepaymentBalance > 0
	|";
	
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("DocumentDate", New Boundary(BegOfDay(DocumentDate)-1, BoundaryType.Including));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	If Selection.Next() Then
		VATPercentage = VATAccountingERPClientServer.ValueOfVATRate(Selection.VATRate);
		AdvanceData.AmountOfAdvancePayments = Selection.AmountOfAdvancePayments
			- VATAccountingERPClientServer.CalculateVATAmount(Selection.AmountOfAdvancePayments, VATPercentage, True);
		AdvanceData.AmountOfAdvancePaymentsLocal = Selection.AmountOfAdvancePaymentsLocal
			- VATAccountingERPClientServer.CalculateVATAmount(Selection.AmountOfAdvancePaymentsLocal, VATPercentage, True);
	EndIf;
	
	Return AdvanceData;
	
EndFunction

&AtServer
Procedure CalculateRateOfReturnOnServer(RecalculatePercentages = True, OutputMessages = True)
	
	CalculationParameters =
		LeasedAssetAccounting.ParametersForCalculatingInterestRatesOfProfitableLeases(Object, FormServiceParameters.ContractDetails_);
	CalculationParameters.ShouldCalculatePercentage = RecalculatePercentages;
	CalculationParameters.OutputMessages = OutputMessages;
	
	LeasedAssetAccounting.CalculateInterestRatesOfProfitableRent(CalculationParameters);
	LeasedAssetAccounting.FillInRateOfReturnInterestChart(ThisObject, CalculationParameters, RecalculatePercentages);
	
EndProcedure

&AtServer
Function CalculateRateOfReturnOnServerInBackground(RecalculatePercentages = True, OutputMessages = True)
	
	CalculationParameters =
		LeasedAssetAccounting.ParametersForCalculatingInterestRatesOfProfitableLeases(Object, FormServiceParameters.ContractDetails_);
	CalculationParameters.ShouldCalculatePercentage = RecalculatePercentages;
	CalculationParameters.OutputMessages = OutputMessages;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tính lãi suất theo hợp đồng chuyển cho thuê';
														|ru = 'Расчет процентной ставки по договору передачи в аренду';
														|en = 'Calculation of the interest rate under the rental contract'; fa = 'Calculation of the interest rate under the rental contract';
														|it = 'Расчет процентной ставки по договору передачи в аренду';
														|pl = 'Calculation of the interest rate under the rental contract';
														|tr = 'Kira devir sözleşmesi kapsamında faiz oranının hesaplanması'");
	ExecutionParameters.WaitCompletion = 0;
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"LeasedAssetAccounting.CalculateRentalInterestRatesInBackground",
		CalculationParameters);
	
EndFunction

&AtClient
Procedure CalculateRateOfReturnCompletion(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult = Undefined Then
		Return;
	EndIf;
	CalculateRateOfReturnEndOnServer(ExecutionResult);
		
EndProcedure

&AtServer
Procedure CalculateRateOfReturnEndOnServer(ExecutionResult)
	
	CalculationResult2 = GetFromTempStorage(ExecutionResult.ResultAddress);
	
	If CalculationResult2 <> Undefined Then
		LeasedAssetAccounting.FillInRateOfReturnInterestChart(ThisObject, CalculationResult2, True);
	EndIf;
	For Each CollectionItem In ExecutionResult.Messages Do
		CollectionItem.Message();
	EndDo;
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfHelpPrinting(FAString)
	
	If FAString <> Undefined Then
		Items.FAReferenceCalculationOfAccrualOfInterest.Enabled = 
				Not FAString.TheInterestAccrualScheduleIsEnteredManually;
	EndIf;
EndProcedure

&AtClient
Procedure UpdateAmount(Sum, ConversionAmount_, ZoomRatio)
		
	If Sum <> 0 And ConversionAmount_ = 0 Then
		ConversionAmount_ = Sum * ZoomRatio;
	EndIf;
	
EndProcedure
#EndRegion

&AtClient
Procedure ShowCalculation(FAString)
	
	If FAString.SettlementDetails = Undefined Then
		Return;
	EndIf;
	
	PaymentData = New Structure;
	PaymentData.Insert("SettlementDetails", FAString.SettlementDetails);
	If FAString.FairValueLocal > 0 Then
		PaymentData.Insert("DetailsType", "TransferToLeaseFairCost");
	Else
		PaymentData.Insert("DetailsType", "TransferToRental");
	EndIf;
	
	OpenForm("Document.ProvideAssetsToLeasee2_4.Form.DrillDownForm",
				PaymentData,
				ThisObject,
				True,,,,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure SetFASelectionParameters()

	FASelectionOptions = New Array;
	
	ContractDetails_ = FormServiceParameters.ContractDetails_;
	
	If TransferForLeaseUnderFAS25 And ContractDetails_.ContractType = Enums.ContractTypes.Sublease Then
		
		FAArray = LeasedAssetAccounting.FALeasedUnderContract(ContractDetails_.LeaseContracts, Object.Date);

		ChoiceParameterFA = New ChoiceParameter("Filter.Ref", New FixedArray(FAArray));
		FASelectionOptions.Add(ChoiceParameterFA);
		
	Else
		
		If Not Object.LeaseholderIntercompanyARAP Then
			
			ChoiceParameterFA = New ChoiceParameter("DateOfLastEdit", Object.Date);
			FASelectionOptions.Add(ChoiceParameterFA);
			
			List = New Array();
			List.Add(Enums.FATypes.Asset);
			List.Add(Enums.FATypes.CapitalExpenditureInLeasedAssets);
			ChoiceParameterFA = New ChoiceParameter("Filter.OSType", New FixedArray(List));
			FASelectionOptions.Add(ChoiceParameterFA);
			
		EndIf;
		
	EndIf;
	
	Items.FAFixedAsset.ChoiceParameters = New FixedArray(FASelectionOptions);
	
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

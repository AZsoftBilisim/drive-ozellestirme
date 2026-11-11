
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
	
	ItemsAndDimensionsSelectionParameters = Documents.ChangeFixedAssetFinancialDetails2_4.ItemsAndDimensionsSelectionParameters();
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

	ItemsAndDimensionsSelectionParameters = Documents.ChangeFixedAssetFinancialDetails2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ChangeFixedAssetFinancialDetails2_4", WriteParameters, Object.Ref);
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
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInInformationInBasement();
	FillInCurParameterValues();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ChangeFixedAssetFinancialDetails2_4" Then
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

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure AdjustmentModeFromPreviousDateOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.PostInAccounting = True;
	EndIf;

	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,PostInAccounting");

EndProcedure

&AtClient
Procedure RecordInTAOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInTA = True;
	EndIf;

	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,RecordInTA");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElementsOnServer("RecordInManAccounting");

EndProcedure

&AtClient
Procedure DocumentInformationInAnotherAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Object.Ref);
		OpenForm("Document.ChangeFixedAssetFinancialDetails2_4.ObjectForm", FormParameters);
	EndIf; 
	
EndProcedure

#EndRegion

#Region Localization

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	ChangeFixedAssetFinancialDetailsClientLocalization.OnChangeAttribute(Item.Name, ThisObject);

EndProcedure

#EndRegion

#Region TheAccountingPage

&AtClient
Procedure DepreciationAccrualAccountingFlagOnChange(Item)
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);		
EndProcedure

&AtClient
Procedure DepreciationMethodAccountingFlagOnChange(Item)
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);		
EndProcedure

&AtClient
Procedure DepreciationMethodAccountingOnChange(Item)
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);		
EndProcedure

&AtClient
Procedure UsefulLifeAccountingFlagOnChange(Item)
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);		
EndProcedure

&AtClient
Procedure UsefulLifeAccountingOnChange(Item)
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);		
EndProcedure

&AtClient
Procedure AccelerationFactorAccountingFlagOnChange(Item)
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);		
EndProcedure

&AtClient
Procedure UsefulLifeManagementAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);		
	
EndProcedure

&AtClient
Procedure UsefulLifeTaxAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);		
	
EndProcedure

&AtClient
Procedure TheAccountingFlagRupriChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure DepreciationMethodFlagRupriChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ThePeriodOfUseOfTheUUPriFlagIsChanged(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure TheAccelerationFactorFlagRupriChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure FinancialAccountingGroupFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure RunningTimeValueFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ResidualValueLocalFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ResidualValueManFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure EstimatedRunningTimeFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure LineOfBusinessFlagOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

#EndRegion

#Region DepreciationPage

&AtClient
Procedure DepreciationExpenseRecordingIsChangedOnChange(Item)
	
	If Object.DepreciationExpenseRecordingIsChanged
		And Object.Depreciation.Count() <> 1 Then
			
		Object.Depreciation.Clear();
		NewRow = Object.Depreciation.Add();
		NewRow.ZoomRatio = 1;
		
		Items.Depreciation.CurrentRow = NewRow.GetID();
		
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure SwitchDepreciationWithoutSplittingOnChange(Item)
	
	If SwitchDepreciationWithoutSplitting
		And Object.Depreciation.Count() > 1 Then
			
		For IndexOf = -Object.Depreciation.Count() To -2 Do
			Object.Depreciation.Delete(-IndexOf - 1);
		EndDo;
		
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);

EndProcedure

&AtClient
Procedure ExpensesPostingMethodOnChange(Item)
	
	ChangedBankingDetails = "ExpensesPostingMethod,DepreciationIsExpenseItemWithoutDivision,DivisionAndLineOfBusinessCoincideWithAccountingDataWithoutDivision";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpensesPostingMethod, 
		Object.Depreciation[0].ExpenseItem, 
		Object.Depreciation[0].DimensionOfExpenses, 
		Object.Depreciation[0].Department, 
		Object.Depreciation[0].LineOfBusiness, 
		Object.Depreciation[0].BusinessUnitAndLineOfBusinessMatchAccountingData);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.DepreciationIsExpenseItemWithoutDivision);
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure DepreciationIsExpenseItemWithoutDivisionOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod= PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod,DepreciationIsExpenseItemWithoutDivision");
	
EndProcedure

&AtClient
Procedure DepreciationExpenseAnalyticsWithoutPartitioningOnChange(Item)
	
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod= PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod");
	
EndProcedure

&AtClient
Procedure DepreciationDivisionWithoutDivisionOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod");
	
EndProcedure

&AtClient
Procedure DepreciationLineOfBusinessWithoutDivisionOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod");
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	CurrentData = Items.Depreciation.CurrentData;
	If CurrentData <> Undefined 
		And CurrentData.BusinessUnitAndLineOfBusinessMatchAccountingData Then
			
		CurrentData.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		CurrentData.LineOfBusiness = PredefinedValue("Catalog.LinesOfBusiness.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod,DivisionAndLineOfBusinessCoincideWithAccountingDataWithoutDivision");
	
EndProcedure

&AtClient
Procedure DepreciationTransferExpensesToAnotherCompanyWithoutSplittingOnChange(Item)

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
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
Procedure FAFixedAssetOnChange(Item)
	
	WhenChangingFAOnServer();

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDepreciation

&AtClient
Procedure DepreciationExpenseItemOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure DepreciationExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationDimensionOfExpensesOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

EndProcedure

&AtClient
Procedure DepreciationDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationDivisionAndLineOfBusinessCoincideWithAccountingDataOnChange(Item)
	
	CurrentData = Items.Depreciation.CurrentData;
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	If CurrentData.BusinessUnitAndLineOfBusinessMatchAccountingData Then
		CurrentData.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		CurrentData.LineOfBusiness = PredefinedValue("Catalog.LinesOfBusiness.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure DepreciationDepartmentOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

EndProcedure

&AtClient
Procedure DepreciationLineOfBusinessOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

EndProcedure

&AtClient
Procedure DepreciationTransferExpensesToAnotherCompanyOnChange(Item)
	
	CurrentData = Items.Depreciation.CurrentData;
	If Not CurrentData.TransferExpensesToAnotherCompany Then
		CurrentData.CompanyRecipientOfExpenses = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDepreciationAllowance

&AtClient
Procedure DepreciationAllowanceExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure DepreciationAllowanceExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationAllowanceDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationAllowanceDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationAllowanceDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationAllowanceTransferExpensesToAnotherCompanyOnChange(Item)
	
	TableRow = Items.DepreciationAllowance.CurrentData;
	If Not TableRow.TransferExpensesToAnotherCompany Then
		TableRow.CompanyRecipientOfExpenses = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure ShowTheCurrentValues(Command)
	
	ShowCurValuesOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)
	
	ChangeFixedAssetFinancialDetailsClientLocalization.OnExecuteCommand(Command, ThisObject);
	
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

#Region AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
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

#EndRegion

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export

	Var ActionParameters;
	
	If Not NotificationParameters.ServerCallRequired_ Then
		
		If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
			ConfigureDependentFormElementsOnClientOnServer(ThisObject, ActionParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	ConfigureDependentFormElementsOnServer("Organization");
	
	FillInCurParameterValues();
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	FillInInformationInBasement();
	
	NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
	
	ChangeFixedAssetFinancialDetailsLocalization.DateOnChange(ThisObject);
	
	ConfigureDependentFormElementsOnServer("Date");
	FillInCurParameterValues();
	
EndProcedure

&AtServer
Procedure WhenChangingFAOnServer()
	
	FillInHeaderForSelectedFA();
	FillInCurParameterValues();
	
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
	
	InitializingFormWhenCreatingItOnServer();	

	FillInCurParameterValues();
	
	Items.DocumentBasis.Visible = ValueIsFilled(Object.DocumentBasis);

	FillInDetailsOfDocumentBasis();
	
	NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
	
	ChangeFixedAssetFinancialDetailsLocalization.OnReadCreateAtServer(ThisObject);
	
	FillInInformationInBasement();
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FillInDetailsOfDocumentBasis()

	ToIncludeDepreciationAllowanceInExpenses = False;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		
		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.FixedAssetsInitialRecognition2_4") Then
		
			ToIncludeDepreciationAllowanceInExpenses = Common.ObjectAttributeValue(
				Object.DocumentBasis, "ToIncludeDepreciationAllowanceInExpenses");
				
		Else
			
			ChangeFixedAssetFinancialDetailsLocalization.FillInDetailsOfDocumentBasis(ThisObject);
			
		EndIf;
		
	EndIf;

EndProcedure
 
&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();

	SwitchDepreciationWithoutSplitting = Object.Depreciation.Count() < 2;
	
	CurrencyOfMan = String(Constants.ManagementAccountingCurrency.Get());
	ComplCurrency = String(SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
	
	Items.LiquidationValueReglCurrency.Title = ComplCurrency;
	Items.LiquidationValueCurrency.Title = CurrencyOfMan;
	
	If ValueIsFilled(ComplCurrency) Then
		Items.FAResidualValueLocal.Title = StrTemplate(NStr("vi = 'Giá trị thanh lý (%1)';
															|ru = 'Ликвидационная стоимость (%1)';
															|en = 'Residual value (%1)'; fa = 'Residual value (%1)';
															|it = 'Costo di liquidazione (%1)';
															|pl = 'Wartość likwidacyjna (%1)';
															|tr = 'Artık değer (%1)'"), ComplCurrency);
	Else
		Items.FAResidualValueLocal.Title = NStr("vi = 'Giá trị thanh lý';
												|ru = 'Ликвидационная стоимость';
												|en = 'Residual value'; fa = 'ارزش باقی‌مانده';
												|it = 'Prezzo di liquidazione';
												|pl = 'Wartość likwidacyjna';
												|tr = 'Artık değer'");
	EndIf;
	
	Items.FAResidualValueMan.Title = StrTemplate(NStr("vi = 'Giá trị thanh lý (%1)';
														|ru = 'Ликвидационная стоимость (%1)';
														|en = 'Residual value (%1)'; fa = 'Residual value (%1)';
														|it = 'Costo di liquidazione (%1)';
														|pl = 'Wartość likwidacyjna (%1)';
														|tr = 'Artık değer (%1)'"), String(CurrencyOfMan));
	
EndProcedure
 
&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region TransferringExpensesToAnotherOrganization
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepreciationCompanyRecipientOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Depreciation.TransferExpensesToAnotherCompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepreciationAllowanceCompanyRecipientOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DepreciationAllowance.TransferExpensesToAnotherCompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
	#Region DepreciationDepartment
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepreciationDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Depreciation.BusinessUnitAndLineOfBusinessMatchAccountingData");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Vị trí của TSCĐ>';
													|ru = '<Местонахождение ОС>';
													|en = '<Fixed assets location>'; fa = '<مکان دارایی‌های ثابت>';
													|it = '<Ubicazione dei Capitali fissi>';
													|pl = '<Lokalizacja środków trwałych>';
													|tr = '<SV Konumu>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepreciationDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Depreciation.BusinessUnitAndLineOfBusinessMatchAccountingData");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Depreciation.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Vị trí của TSCĐ>';
													|ru = '<Местонахождение ОС>';
													|en = '<Fixed assets location>'; fa = '<مکان دارایی‌های ثابت>';
													|it = '<Ubicazione dei Capitali fissi>';
													|pl = '<Lokalizacja środków trwałych>';
													|tr = '<SV Konumu>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	#EndRegion
	
	#Region DepreciationLineOfBusiness
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepreciationLineOfBusiness.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Depreciation.BusinessUnitAndLineOfBusinessMatchAccountingData");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Lĩnh vực hoạt động TSCĐ>';
													|ru = '<Направление деятельности ОС>';
													|en = '<FA line of business>'; fa = '<خط کسب‌وکار دارایی ثابت>';
													|it = '<Направление деятельности ОС>';
													|pl = '<FA line of business>';
													|tr = '<SV iş kolu>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region FADepreciationSchedule
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FADepreciationSchedule.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.DepreciationSchedule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.RecognizedCompl");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có lịch trình>';
													|ru = '<без графика>';
													|en = '<without schedule>'; fa = '<without schedule>';
													|it = '<senza grafico>';
													|pl = '<bez harmonogramu>';
													|tr = '<Program yok>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	#EndRegion
	
	#Region NotAccepted_Local
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FADepreciationAccrualAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAUsefulLifeAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAAnnualDepreciationRate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FADepreciationSchedule.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAAccelerationFactorAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FADepreciationAccrualTaxAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAUsefulLifeTaxAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FASpecialFactorTaxAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FADepreciationGroup.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FARealEstate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FADepreciationMethodAccounting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.RecognizedCompl");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chấp nhận cho kế toán>';
													|ru = '<не принято к учету>';
													|en = '<not recognized>'; fa = '<not recognized>';
													|it = '<non considerato in contabilità>';
													|pl = '<nie przyjęto do ewidencji>';
													|tr = '<dikkate alınmaz>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	#EndRegion
	
	#Region NotRegistered_Man
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FADepreciationAccrualManagementAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FADepreciationAccrualMethodManagementAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAUsefulLifeManagementAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAAccelerationFactorManagementAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAResidualValueMan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAResidualValueLocal.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.RecognizedManag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chấp nhận cho kế toán>';
													|ru = '<не принято к учету>';
													|en = '<not recognized>'; fa = '<not recognized>';
													|it = '<non considerato in contabilità>';
													|pl = '<nie przyjęto do ewidencji>';
													|tr = '<dikkate alınmaz>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	#EndRegion
	
	#Region NotAccepted__
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAFinancialAccountingGroup.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FALineOfBusiness.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FARunningTimeValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAEstimatedRunningTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.RecognizedManag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.RecognizedCompl");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chấp nhận cho kế toán>';
													|ru = '<не принято к учету>';
													|en = '<not recognized>'; fa = '<not recognized>';
													|it = '<non considerato in contabilità>';
													|pl = '<nie przyjęto do ewidencji>';
													|tr = '<dikkate alınmaz>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	#EndRegion
	
	#Region ExpiredAC
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAThePeriodOfUseForCalculatingTheDepreciationOfTheBU.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ThePeriodOfUseForCalculatingTheDepreciationOfTheBU");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.RecognizedCompl");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hết hạn>';
													|ru = '<истек>';
													|en = '<expired>'; fa = '<expired>';
													|it = '<scaduto>';
													|pl = '<expired>';
													|tr = '<süresi doldu>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	#EndRegion

	#Region ExpiredMa
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAThePeriodOfUseForCalculatingTheDepreciationOfTheUU.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ThePeriodOfUseForCalculatingTheDepreciationOfTheUU");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.RecognizedManag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hết hạn>';
													|ru = '<истек>';
													|en = '<expired>'; fa = '<expired>';
													|it = '<scaduto>';
													|pl = '<expired>';
													|tr = '<süresi doldu>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	#EndRegion
	
EndProcedure

&AtServer
Procedure FillInInformationInBasement()

	LabelTitle = NonCurrentAssetsInternal.DocumentInformationInAnotherAccounting(Object, False);

	ChangeFixedAssetFinancialDetailsLocalization.CompleteInformationInBasement(Object, LabelTitle);
	
	If LabelTitle.Count() <> 0 Then
		Items.Information.Title = New FormattedString(LabelTitle);
		Items.PictureInformation.Visible = True;
		Items.Information.Visible = True;
	Else
		Items.PictureInformation.Visible = False;
		Items.Information.Visible = False;
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, Val ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", Form.CurrenciesDoNotMatch);
	AuxiliaryAttributes.Insert("UseLocal", FormServiceParameters.UseLocal);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	NonCurrentAssetsClientServerLocalization.AddAuxiliaryProps_ChangeFAParameters(Form, AuxiliaryAttributes);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_ChangeFAParameters(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);

	If Not UpdateAll Then
		
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "FA,Depreciation,DepreciationAllowance");
		
		ChangedBankingDetails = NonCurrentAssetsClientServer.FillInDetailsDependingOnProperties_ChangeFAParameters(
				Object, ItemDetailsParameters);
		CommonClientServer.SupplementStructure(StructureOfChangedProps, New Structure(ChangedBankingDetails), True);
						
	EndIf;
	
	#Region PageGeneral
	
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
	
	#EndRegion
	
	#Region Accounting
	
	If StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		ComplCurrency = Form.FormServiceParameters.ComplCurrency;
		Items.LiquidationValueReglCurrency.Title = ComplCurrency;
		
		If ValueIsFilled(ComplCurrency) Then
			Items.FAResidualValueLocal.Title = StrTemplate(NStr("vi = 'Giá trị thanh lý (%1)';
																|ru = 'Ликвидационная стоимость (%1)';
																|en = 'Residual value (%1)'; fa = 'Residual value (%1)';
																|it = 'Costo di liquidazione (%1)';
																|pl = 'Wartość likwidacyjna (%1)';
																|tr = 'Artık değer (%1)'"), String(ComplCurrency));
		Else
			Items.FAResidualValueLocal.Title = NStr("vi = 'Giá trị thanh lý';
													|ru = 'Ликвидационная стоимость';
													|en = 'Residual value'; fa = 'ارزش باقی‌مانده';
													|it = 'Valore diu liquidazione';
													|pl = 'Wartość likwidacyjna';
													|tr = 'Artık değer'");
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrualAccountingFlag")
		Or UpdateAll Then
		
		If Object.DepreciationAccrualAccountingFlag Then
			Items.DepreciationAccrualAccounting.EditFormat = NStr("vi = 'BF=''Đã dừng''; BT=''Đang thực hiện''';
																	|ru = 'БЛ=Остановлено; БИ=Действует';
																	|en = 'BF=Stopped; BT=Valid'; fa = 'BF=متوقف; BT=معتبر';
																	|it = 'BF=fermo; BT=''in funzione''';
																	|pl = 'BF=Zatrzymano; BP=Obowiązuje';
																	|tr = 'BL=Durduruldu; BI=Çalışıyor'");
		Else
			Items.DepreciationAccrualAccounting.EditFormat = NStr("vi = 'BF=; BT=''Đang thực hiện''';
																	|ru = 'БЛ=; БИ=Действует';
																	|en = 'BF=; BT=Valid'; fa = 'BF=; BT=Valid';
																	|it = 'BF=; BT=''in funzione''';
																	|pl = 'BF=; BT=Obowiązuje';
																	|tr = 'BL=; BI=Geçerli'");
		EndIf; 
			
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeAccounting")
		Or StructureOfChangedProps.Property("UsefulLifeAccountingFlag")
		Or UpdateAll Then
		
		Form.ACUsefulLifeExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrualManagementAccountingFlag")
		Or UpdateAll Then
		
		If Object.DepreciationAccrualManagementAccountingFlag Then
			Items.DepreciationAccrualManagementAccounting.EditFormat = NStr("vi = 'BF=''Đã dừng''; BT=''Đang thực hiện''';
																			|ru = 'БЛ=Остановлено; БИ=Действует';
																			|en = 'BF=Stopped; BT=Valid'; fa = 'BF=متوقف; BT=معتبر';
																			|it = 'BF=fermo; BT=''in funzione''';
																			|pl = 'BF=Zatrzymano; BP=Obowiązuje';
																			|tr = 'BL=Durduruldu; BI=Çalışıyor'");
		Else
			Items.DepreciationAccrualManagementAccounting.EditFormat = NStr("vi = 'BF=; BT=''Đang thực hiện''';
																			|ru = 'БЛ=; БИ=Действует';
																			|en = 'BF=; BT=Valid'; fa = 'BF=; BT=Valid';
																			|it = 'BF=; BT=''in funzione''';
																			|pl = 'BF=; BT=Obowiązuje';
																			|tr = 'BL=; BI=Geçerli'");
		EndIf; 
			
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeManagementAccounting")
		Or StructureOfChangedProps.Property("UsefulLifeManagementAccountingFlag")
		Or UpdateAll Then
		
		Form.UsefulLifeMAExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeManagementAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		Items.LiquidationValueCurrency.Visible = Items.ResidualValueMan.Visible;
		Items.LiquidationValueReglCurrency.Visible = Items.ResidualValueLocal.Visible;
	EndIf;
	
	#EndRegion
	
	#Region DepreciationPage
	
	If StructureOfChangedProps.Property("DepreciationExpenseRecordingIsChanged") 
		Or StructureOfChangedProps.Property("ExpensesPostingMethod") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpensesPostingMethod,
			Form, 
			"DepreciationIsExpenseItemWithoutDivision,DepreciationExpenseAnalyticsWithoutPartitioning,DepreciationDivisionWithoutDivision,DepreciationLineOfBusinessWithoutDivision,DivisionAndLineOfBusinessCoincideWithAccountingDataWithoutDivision");
	
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationExpenseRecordingIsChanged")
		Or StructureOfChangedProps.Property("SwitchDepreciationWithoutSplitting")
		Or StructureOfChangedProps.Property("DepreciationTransferExpensesToAnotherCompanyWithoutSplitting")
		Or StructureOfChangedProps.Property("DivisionAndLineOfBusinessCoincideWithAccountingDataWithoutDivision")
		Or UpdateAll Then
			
		Items.PagesReflectingDepreciationExpenses.CurrentPage =
			?(Form.SwitchDepreciationWithoutSplitting, 
			Items.PageReflectionOfDepreciationExpensesWithoutSplitting,
			Items.PageReflectsDepreciationExpensesAsList);
	
		If Form.SwitchDepreciationWithoutSplitting
			And Object.Depreciation.Count() <> 0 Then
			Items.Depreciation.CurrentRow = Object.Depreciation[0].GetID();
		EndIf;
	
		CurrentData = ?(Object.Depreciation.Count() <> 0, Object.Depreciation[0], Undefined);
		If CurrentData <> Undefined 
			And CurrentData.BusinessUnitAndLineOfBusinessMatchAccountingData Then
			Items.DepreciationLineOfBusinessWithoutDivision.InputHint = NStr("vi = '<Lĩnh vực hoạt động TSCĐ>';
																			|ru = '<Направление деятельности ОС>';
																			|en = '<FA line of business>'; fa = '<خط کسب‌وکار دارایی ثابت>';
																			|it = '<Направление деятельности ОС>';
																			|pl = '<FA line of business>';
																			|tr = '<SV iş kolu>'");
		Else
			Items.DepreciationLineOfBusinessWithoutDivision.InputHint = "";
		EndIf;
		
	EndIf;

	#EndRegion
	
	ImpairmentFAClientServer.CGUVisibilityManagement(Form, "CGUFlag");
	
	SetVisibilityOfCurValues(Form, UpdateAll, StructureOfChangedProps);
	
	NonCurrentAssetsClientServerLocalization.ConfigureDependentFormElements_ChangeFASettings(
		Form, StructureOfChangedProps);
	 
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	DateOfParameters = EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));
	
	If UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);

	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrency",
			ComplCurrency,
			FormServiceParameters);
		
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, DateOfParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, DateOfParameters),
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FSB6IsApplied",
			AccountingPoliciesTaxSettingsCached.FSB6IsApplied(Object.Organization, DateOfParameters),
			FormServiceParameters);
		
		
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfCurValues(Form, UpdateAll, StructureOfChangedProps)

	Items = Form.Items;
	Object = Form.Object;
	
	Form.NumberOfChangedProperties = 0;
	
	BUProperties = New Array;
	BUProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("AccelerationFactorAccounting", "AccelerationFactorAccountingFlag"));
	BUProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("UsefulLifeAccounting", "UsefulLifeAccountingFlag"));
	BUProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("DepreciationAccrualAccounting", "DepreciationAccrualAccountingFlag"));
	BUProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("DepreciationMethodAccounting", "DepreciationMethodAccountingFlag"));
	
	PropertiesOfMa = New Array;
	PropertiesOfMa.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("AccelerationFactorManagementAccounting", "AccelerationFactorManagementAccountingFlag"));
	PropertiesOfMa.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("UsefulLifeManagementAccounting", "UsefulLifeManagementAccountingFlag"));
	PropertiesOfMa.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("DepreciationAccrualMethodManagementAccounting", "DepreciationAccrualMethodManagementAccountingFlag"));
	PropertiesOfMa.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("DepreciationAccrualManagementAccounting", "DepreciationAccrualManagementAccountingFlag"));
	
	GeneralProperties = New Array;
	GeneralProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("EstimatedRunningTime", "EstimatedRunningTimeFlag"));
	GeneralProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("RunningTimeValue", "RunningTimeValueFlag"));
	GeneralProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("FinancialAccountingGroup", "FinancialAccountingGroupFlag"));
	GeneralProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("LineOfBusiness","LineOfBusinessFlag"));
	GeneralProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("ResidualValueMan", "ResidualValueManFlag"));
	GeneralProperties.Add(NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("ResidualValueLocal", "ResidualValueLocalFlag"));
	
	PropertiesOther = New Structure;
	PropertiesOther.Insert("FAThePeriodOfUseForCalculatingTheDepreciationOfTheUU", 
	                        NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("UsefulLifeManagementAccounting", "UsefulLifeManagementAccountingFlag"));
	                        
	PropertiesOther.Insert("FAVolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits", 
	                        NonCurrentAssetsClientServer.BankingDetailsNamesDataFlag("EstimatedRunningTime", "EstimatedRunningTimeFlag"));
	
	For Each ArrayElement In BUProperties Do
		
		NonCurrentAssetsClientServer.SetVisibilityOfCurParameterValueWhenParametersChange(
			Form, Undefined, ArrayElement, "FA", StructureOfChangedProps);
			
		Form.NumberOfChangedProperties = Form.NumberOfChangedProperties + ?(Object[ArrayElement.AttributeNameFlag], 1, 0);
		
	EndDo;
	
	For Each ArrayElement In PropertiesOfMa Do
		
		NonCurrentAssetsClientServer.SetVisibilityOfCurParameterValueWhenParametersChange(
			Form, Undefined, ArrayElement, "FA", StructureOfChangedProps);
			
		Form.NumberOfChangedProperties = Form.NumberOfChangedProperties + ?(Object[ArrayElement.AttributeNameFlag], 1, 0);
		
	EndDo;
	
	For Each ArrayElement In GeneralProperties Do
		
		NonCurrentAssetsClientServer.SetVisibilityOfCurParameterValueWhenParametersChange(
			Form, Undefined, ArrayElement, "FA", StructureOfChangedProps);
			
		Form.NumberOfChangedProperties = Form.NumberOfChangedProperties + ?(Object[ArrayElement.AttributeNameFlag], 1, 0);
		
	EndDo;
	
	For Each KeyAndValue In PropertiesOther Do
		
		NonCurrentAssetsClientServer.SetVisibilityOfCurParameterValueWhenParametersChange(
			Form, KeyAndValue.Key, KeyAndValue.Value, "FA", StructureOfChangedProps);
			
	EndDo;
	
	NonCurrentAssetsClientServerLocalization.SetVisibilityOfCurValues_ChangeFASettings(
		Form, Form.NumberOfChangedProperties, StructureOfChangedProps);
	
	If Form.ShowTheCurrentValues 
		And Form.NumberOfChangedProperties > 0
		And Items.FAFixedAsset.FixingInTable <> FixingInTable.Left Then
		
		Items.FAFixedAsset.FixingInTable = FixingInTable.Left;
		
	ElsIf (Not Form.ShowTheCurrentValues 
				Or Form.NumberOfChangedProperties = 0)
		And Items.FAFixedAsset.FixingInTable <> FixingInTable.None Then
		
		Items.FAFixedAsset.FixingInTable = FixingInTable.None;
		
	EndIf; 
	
EndProcedure

&AtServer
Procedure ShowCurValuesOnServer()

	ShowTheCurrentValues = Not ShowTheCurrentValues;
	Items.FAShowTheCurrentValues.Check = ShowTheCurrentValues;
	
	FillInCurParameterValues();
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ShowTheCurrentValues");

EndProcedure

&AtServer
Procedure FillInCurParameterValues()
	
	If Object.FA.Count() = 0 Or Not ShowTheCurrentValues Then
		Return;
	EndIf;

	QueryText = ChangeFixedAssetFinancialDetailsLocalization.RequestTextForFillingInCurParameterValues();
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	Assets.Ref AS FixedAsset,
		|	ISNULL(FixedAssetsAccountingProcedureSliceLast.FinancialAccountingGroup, UNDEFINED) AS FinancialAccountingGroup,
		|	ISNULL(FixedAssetsAccountingProcedureSliceLast.LineOfBusiness, UNDEFINED) AS LineOfBusiness,
		|	ISNULL(FixedAssetsAccountingProcedureSliceLast.RunningTimeValue, UNDEFINED) AS RunningTimeValue,
		|	ISNULL(FixedAssetsAccountingProcedureSliceLast.EstimatedRunningTime, UNDEFINED) AS EstimatedRunningTime,
		|	ISNULL(FixedAssetDepreciationParametersManagementAccountingSliceLast.UsefulLifeMonths, 0) AS UsefulLifeManagementAccounting,
		|	ISNULL(FixedAssetDepreciationParametersManagementAccountingSliceLast.UsefulLifeForCalculatingDepreciationMonth, 0) AS ThePeriodOfUseForCalculatingTheDepreciationOfTheUU,
		|	ISNULL(FixedAssetDepreciationParametersManagementAccountingSliceLast.AccelerationFactor, 0) AS AccelerationFactorManagementAccounting,
		|	ISNULL(FixedAssetDepreciationParametersManagementAccountingSliceLast.DepreciationMethod, UNDEFINED) AS DepreciationAccrualMethodManagementAccounting,
		|	ISNULL(FixedAssetDepreciationParametersManagementAccountingSliceLast.ResidualValueMan, 0) AS ResidualValueMan,
		|	ISNULL(FixedAssetDepreciationParametersManagementAccountingSliceLast.ResidualValueLocal, 0) AS ResidualValueLocal,
		|	ISNULL(FixedAssetsAccountingProcedureManagementAccountingSliceLast.AccrueDepreciationOrAmortization, FALSE) AS DepreciationAccrualManagementAccounting,
		|	ISNULL(InitialFixedAssetsInformationSliceLast.CommissioningDateMA, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecognizedManag,
		|	ISNULL(OSBUDepreciationParametersSliceLast.UsefulLifeMonthsAC, 0) AS UsefulLifeAccounting,
		|	ISNULL(OSBUDepreciationParametersSliceLast.UsefulLifeForCalculatingDepreciationMonth, 0) AS ThePeriodOfUseForCalculatingTheDepreciationOfTheBU,
		|	ISNULL(OSBUDepreciationParametersSliceLast.AnnualDepreciationRate, 0) AS AnnualDepreciationRate,
		|	ISNULL(OSBUDepreciationParametersSliceLast.AccelerationFactor, 0) AS AccelerationFactorAccounting,
		|	ISNULL(OSBUDepreciationParametersSliceLast.SpecialFactor, 0) AS SpecialFactor,
		|	ISNULL(AccountingProcedureForOSBUSliceLast.DepreciationAccrualAccounting, FALSE) AS DepreciationAccrualAccounting,
		|	ISNULL(InitialFixedAssetsInformationSliceLast.DepreciationMethodAccounting, UNDEFINED) AS DepreciationMethodAccounting,
		|	ISNULL(InitialFixedAssetsInformationSliceLast.CommissioningDateAC, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecognizedCompl
		|FROM
		|	Catalog.Assets AS Assets
		|
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
		|				&Period,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetDepreciationParametersManagementAccountingSliceLast
		|		ON (FixedAssetDepreciationParametersManagementAccountingSliceLast.FixedAsset = Assets.Ref)
		|
		|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
		|				&Period,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedureSliceLast
		|		ON (FixedAssetsAccountingProcedureSliceLast.FixedAsset = Assets.Ref)
		|
		|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
		|				&Period,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedureManagementAccountingSliceLast
		|		ON (FixedAssetsAccountingProcedureManagementAccountingSliceLast.FixedAsset = Assets.Ref)
		|
		|		LEFT JOIN InformationRegister.InitialFixedAssetsInformation.SliceLast(
		|				,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS InitialFixedAssetsInformationSliceLast
		|		ON (InitialFixedAssetsInformationSliceLast.FixedAsset = Assets.Ref)
		|
		|		LEFT JOIN InformationRegister.OSBUDepreciationParameters.SliceLast(
		|				&Period,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS OSBUDepreciationParametersSliceLast
		|		ON (OSBUDepreciationParametersSliceLast.FixedAsset = Assets.Ref)
		|
		|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
		|				&Period,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS AccountingProcedureForOSBUSliceLast
		|		ON (AccountingProcedureForOSBUSliceLast.FixedAsset = Assets.Ref)";
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfFA", Object.FA.Unload().UnloadColumn("FixedAsset"));
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", EndOfDay(?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate())));
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	For Each RowData In Object.FA Do
		CurrentValues = Result.Find(RowData.FixedAsset, "FixedAsset");
		If CurrentValues <> Undefined Then
			FillPropertyValues(RowData, CurrentValues);
		Else
			RowData.RecognizedCompl = False;
			RowData.RecognizedManag = False;
		EndIf; 
	EndDo; 
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedFA()

	ChangedBankingDetails = "FixedAsset";
	NonCurrentAssetsInternal.FillInHeaderForSelectedFA(
		"Organization", 
		Object.FA, 
		Object, 
		ChangedBankingDetails);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("UseLocal", LocalAccntingServer.ReglRecordsAreMaintained(Object.Date));
	NewServiceParametersOfForm.Insert("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

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

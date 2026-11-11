
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.FATransfer2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
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

	TMCommonUse.CustomizePeripherals(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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

	ItemsAndDimensionsSelectionParameters = Documents.FATransfer2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
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
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_FATransfer2_4", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	FATransferClientLocalization.AfterWritingInForm(ThisObject, Object);
	
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

	
	FillInCurOfNodeOwner();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
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

&AtClient
Procedure OrganizationOnChange(Item)
	
	DeterminePresenceOfYourOwnFAOnServer();
	
	SetSelectionOfCGUByOrganization();
	
EndProcedure

&AtClient
Procedure DeliveryCompanyOnChange(Item)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice")
		And ValueIsFilled(Object.Organization)
		And ValueIsFilled(Object.CompanyRecipient) Then
		
		If Not NonCurrentAssetsServerCall.OrganizationsAreInterconnectedByOrganizationalStructure(Object.CompanyRecipient, Object.Organization) Then
			Object.CompanyRecipient = PredefinedValue("Catalog.Companies.EmptyRef");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CompanyRecipientOnChange(Item)
	
	SetSelectionOfCGUByOrganization();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);

	DeterminePresenceOfYourOwnFAOnServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)

	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice") Then
		
		If ValueIsFilled(Object.CompanyRecipient)
			And Object.Organization = Object.CompanyRecipient Then
			Object.CompanyRecipient = PredefinedValue("Catalog.Companies.EmptyRef");
		EndIf;
		
		If ValueIsFilled(Object.Organization)
			And Not NonCurrentAssetsServerCall.OrganizationIsInterconnectedWithOtherOrganizations(Object.Organization) Then
			Object.Organization = PredefinedValue("Catalog.Companies.EmptyRef");
		EndIf;
		 
	EndIf;
	
	DeleteUnavailableFixedAssets();
	
	ConfigureDependentFormElements(Item.Name);

EndProcedure

&AtClient
Procedure DepreciationAccrualOnChange(Item)
	
	ConfigureDependentFormElements("DepreciationAccrual,ExpensesPostingMethod");
	
EndProcedure

&AtClient
Procedure ExpensesPostingMethodOnChange(Item)
	
	ChangedBankingDetails = "ExpensesPostingMethod,ExpenseItem,BusinessUnitAndLineOfBusinessMatchAccountingData";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpensesPostingMethod, 
		Object.ExpenseItem, 
		Object.DimensionOfExpenses, 
		Object.ExpensesBusinessUnit, 
		Object.ExpenseLineOfBusiness, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingData);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("ExpensesPostingMethod,ExpenseItem");
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)

	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpensesPostingMethod");
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
	
	ConfigureDependentFormElements("ExpensesPostingMethod,ExpensesBusinessUnit");
	
EndProcedure

&AtClient
Procedure ExpenseLineOfBusinessOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("ExpensesPostingMethod,ExpenseLineOfBusiness");

EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("ExpensesPostingMethod,BusinessUnitAndLineOfBusinessMatchAccountingData");
	
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
		Object,
		"RecipientLocationAddress", 
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure LocationAddressClearing(Item, StandardProcessing)
	
	WhenChangingAddressPresentation(Item);
	
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChange(Item)
	
	If Object.GeneratedDocument Then
		
		ListFilter = New Structure;
		ListFilter.Insert("Posted", True);
		If ValueIsFilled(Object.Organization) Then
			ListFilter.Insert("Organization", Object.Organization);
		EndIf;
		
		CallbackDescription = New CallbackDescription("GeneratedDocumentOnChangeCompletion", ThisObject);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", ListFilter);
		OpenForm("Document.FixedAssetsPhysicalCount.ChoiceForm", FormParameters,,,,, CallbackDescription);
		
	Else
		
		Object.DocumentBasis = Undefined;
		
	EndIf; 
	
EndProcedure

#Region Localization

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	FATransferClientLocalization.OnChangeAttribute(Item, ThisObject);

EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return; // WE have an empty handler
	
EndProcedure

&AtClient
Procedure Attachable_StartChoice(Item, ChoiceData, StandardProcessing)
	
	FATransferClientLocalization.StartChoice(Item, ChoiceData, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	FATransferClientLocalization.AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	FATransferClientLocalization.TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, ThisObject);
	
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
Procedure FAAfterDeleteRow(Item)
	
	DeterminePresenceOfYourOwnFAOnServer();
	
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	WhenChangingFAOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pickup(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
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

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ImportDataFromPDT(Command)
	
	LoadDataFromTSD();
	
EndProcedure

#EndRegion

#Region StandardSubsystems

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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations


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
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export

	Var ActionParameters;
	
	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElements(ActionParameters);
	EndIf; 
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ThereAreOwnFA = Documents.FATransfer2_4.ThereAreOwnFA(Object);
	
	FillInCurOfNodeOwner();
	ConfigureDependentFormElements();
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElements(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = Documents.FATransfer2_4.PropertyValuesOfDependentProps(Object, ThereAreOwnFA, ChangedBankingDetails);
	TMCommonUseClientServer.ConfigureDependentFormElements(ThisObject, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "FA");
	EndIf;
	
	#Region PageGeneral
	
	If UpdateAll Then

		NonCurrentAssetsClientServer.SetVisibilityOfSelectionListValue(
			Items.BusinessOperation.ChoiceList,
			GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets"),
			Enums.BusinessTransactions.TransferOfFixedAssetsToBranchOffice,
			NStr("vi = 'Chuyển đến bộ phận trên bảng cân đối kế toán riêng biệt';
				|ru = 'Передача в подразделение на отдельном балансе';
				|en = 'Transfer to business unit on a separate balance sheet'; fa = 'انتقال به واحد تجاری با ترازنامه جداگانه';
				|it = 'Transfer to business unit on a separate balance sheet';
				|pl = 'Transfer to business unit on a separate balance sheet';
				|tr = 'Ayrı bilançolu bölüme devir'"));
		
		Items.BusinessOperation.Visible = Items.BusinessOperation.ChoiceList.Count() > 1;
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAccrual") Then
		
		If Object.DepreciationAccrual <> 1 Then
			Object.ExpenseItem = Undefined;
			IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);
		EndIf;
		
	EndIf; 
	
	If StructureOfChangedProps.Property("TaxExpenseRecordingIsChanged")  Then
		
		If Not Object.TaxExpenseRecordingIsChanged Then
			Object.ExpenseItemForTax = Undefined;
			IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemForTax);
		EndIf;
		
	EndIf;
	
	ImpairmentFAServer.SetCGUSelectionParameters(Items.CGURecipient, Object);
		
	#EndRegion
	
	#Region FixedAssetsPage
	
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or UpdateAll Then
	
		ParametersArray = New Array(Items.FAFixedAsset.ChoiceParameters);
		
		For IndexOf = 0 To ParametersArray.UBound() Do
			If ParametersArray[IndexOf].Name = "Filter.OSType" Then
				ParametersArray.Delete(IndexOf);
				Break;
			EndIf;
		EndDo;
		
		ThisIsMovingNodes = (Object.BusinessOperation = Enums.BusinessTransactions.TransferSubAssets);
		
		ArrayOfFATypes = AvailableFATypes(Object.BusinessOperation);
		ChoiceParameter = New ChoiceParameter("Filter.OSType", New FixedArray(ArrayOfFATypes));

		ParametersArray.Add(ChoiceParameter);
		Items.FAFixedAsset.ChoiceParameters = New FixedArray(ParametersArray);
		
		//
		Items.FAFixedAsset.Title = 
			?(ThisIsMovingNodes, NStr("vi = 'Thành phần TSCĐ';
										|ru = 'ОС-узел';
										|en = 'Fixed asset sub-asset'; fa = 'Fixed asset sub-asset';
										|it = 'ОС-узел';
										|pl = 'Fixed asset sub-asset';
										|tr = 'Sabit kıymet alt varlığı'"), NStr("vi = 'Tài sản cố định';
																			|ru = 'Основное средство';
																			|en = 'Fixed asset'; fa = 'دارایی ثابت';
																			|it = 'Основное средство';
																			|pl = 'Środek trwały';
																			|tr = 'Sabit kıymet'"));
		
	EndIf;

	#EndRegion
	
	#Region PageExpenseRecord
	
	If StructureOfChangedProps.Property("ExpensesPostingMethod") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpensesPostingMethod, 
			ThisObject,
			"ExpenseItem,DimensionOfExpenses,ExpensesBusinessUnit,ExpenseLineOfBusiness,BusinessUnitAndLineOfBusinessMatchAccountingData");
	
	EndIf;
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure WhenChangingAddressPresentation(Item)

	NonCurrentAssetsClient.WhenChangingAddressPresentation(
		Item,
		Object.RecipientLocationAddress,
		Object.RecipientLocationAddressValue);

EndProcedure

&AtServer
Procedure DeterminePresenceOfYourOwnFAOnServer()

	If Documents.FATransfer2_4.ThereAreOwnFA(Object) <> ThereAreOwnFA Then
		ThereAreOwnFA = Not ThereAreOwnFA;
		ConfigureDependentFormElements("ThereAreOwnFA");
	EndIf; 

EndProcedure

&AtServer
Procedure WhenChangingFAOnServer()
	
	FillInHeaderForSelectedFA();
	DeterminePresenceOfYourOwnFAOnServer();
	FillInCurOfNodeOwner();
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedFA()

	ChangedBankingDetails = "FixedAsset";
	NonCurrentAssetsInternal.FillInHeaderForSelectedFA(
		"Organization,Department,FINANCIALLYLIABLEPERSON", 
		Object.FA, 
		Object, 
		ChangedBankingDetails);
	
	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInCurOfNodeOwner()

	If Object.BusinessOperation <> Enums.BusinessTransactions.TransferSubAssets Then
		Return;
	EndIf;
	
	FilterParameters = New Structure("PrimaryFacilityOwnerCur", Catalogs.Assets.EmptyRef());
	RowsCollection = Object.FA.FindRows(FilterParameters);
	
	NodesArray = New Array();
	For Each FAString In RowsCollection Do
		NodesArray.Add(FAString.FixedAsset);
	EndDo;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	NodesComponents.SubAssetComponent,
		|	NodesComponents.FixedAsset AS PrimaryFacilityOwnerCur
		|FROM
		|	InformationRegister.SubAssetsComponentsOfDepreciation.SliceLast(&Period, SubAssetComponent IN (&NodesArray)) AS NodesComponents";
	
	If ValueIsFilled(Object.Ref) Then
		SliceByDate = New Boundary(Object.Ref.PointInTime(), BoundaryType.Excluding);
	Else
		SliceByDate = Object.Date;
	EndIf;
	
	Query.SetParameter("Period", SliceByDate);
	Query.SetParameter("NodesArray", NodesArray);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		FilterParameters = New Structure("FixedAsset", Selection.SubAssetComponent);
		FoundRows = Object.FA.FindRows(FilterParameters);
		
		For Each FAString In FoundRows Do
			FillPropertyValues(FAString, Selection);
		EndDo;
	
	EndDo;

EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure DeleteUnavailableFixedAssets()
	
	ListOfFA = New Array;
	For Each RowData In Object.FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;
	
	If ListOfFA.Count() = 0 Then
		Return;
	EndIf;
	
	AvailableFATypes = AvailableFATypes(Object.BusinessOperation);
	AvailableFA = FAAvailableByType(ListOfFA, AvailableFATypes);
	
	For IndexOf = -Object.FA.Count() To -1 Do
		RowData = Object.FA[-IndexOf - 1];
		If ValueIsFilled(RowData.FixedAsset)
			And AvailableFA.Find(RowData.FixedAsset) = Undefined Then
			Object.FA.Delete(-IndexOf - 1);
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function FAAvailableByType(Val ListOfFA, Val FATypes)
	
	AvailableFA = New Array;
	
	QueryText =
	"SELECT
	|	ListOfFA.Ref AS Ref
	|FROM
	|	Catalog.Assets AS ListOfFA
	|
	|WHERE
	|	ListOfFA.Ref IN (&ListOfFA)
	|	AND ListOfFA.OSType IN (&FATypes)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfFA", ListOfFA);
	Query.SetParameter("FATypes", FATypes);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		AvailableFA.Add(Selection.Ref);
	EndDo;
	
	Return AvailableFA;
	
EndFunction

&AtClientAtServerNoContext
Function AvailableFATypes(BusinessOperation)
	
	FATypes = New Array;
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferSubAssets") Then
	
		FATypes.Add(PredefinedValue("Enum.FATypes.Node"));
	
	Else
	
		FATypes.Add(PredefinedValue("Enum.FATypes.Asset"));
		FATypes.Add(PredefinedValue("Enum.FATypes.GroupFA"));
		FATypes.Add(PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets"));

	EndIf;

	Return FATypes;
	
EndFunction

&AtServer
Procedure SetSelectionOfCGUByOrganization()
	
	ImpairmentFAServer.SetCGUSelectionParameters(Items.CGURecipient, Object);
	
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChangeCompletion(ClosingResult, AdditionalParameters) Export

	If ValueIsFilled(ClosingResult) Then
		Object.DocumentBasis = ClosingResult;
	Else
		Object.GeneratedDocument = False;
	EndIf;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		QueryText = NStr("vi = 'Điền chứng từ theo kiểm kê?';
						|ru = 'Заполнить документ по инвентаризации?';
						|en = 'Fill in the physical inventory count document?'; fa = 'Fill in the physical inventory count document?';
						|it = 'Fill in the physical inventory count document?';
						|pl = 'Fill in the physical inventory count document?';
						|tr = 'Belge stok sayımına göre doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("FillInAccordingToBaseEnd", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo); 
	EndIf; 
	
EndProcedure

&AtClient
Procedure FillInAccordingToBaseEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInAccordingToBaseDataOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAccordingToBaseDataOnServer()
	
	Object.FA.Clear();
	
	Documents.FATransfer2_4.FillInBasedOnInventory(Object, True);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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

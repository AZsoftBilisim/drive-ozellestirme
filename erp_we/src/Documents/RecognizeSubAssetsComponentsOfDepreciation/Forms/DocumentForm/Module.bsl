
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
	
	ItemsAndDimensionsSelectionParameters = Documents.RecognizeSubAssetsComponentsOfDepreciation.ItemsAndDimensionsSelectionParameters();
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

	ItemsAndDimensionsSelectionParameters = Documents.RecognizeSubAssetsComponentsOfDepreciation.ItemsAndDimensionsSelectionParameters();
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
	Notify("Write_RecognizeSubAssetsComponentsOfDepreciation", WriteParameters, Object.Ref);
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

	FillInInformationInBasement();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	

	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_RecognizeSubAssetsComponentsOfDepreciation" 
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

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	ConfigureDependentFormElements("Date");
	
EndProcedure

&AtClient
Procedure RecordInLocalAccountingOnChange(Item)
	
	If Not Object.RecordInLocalAccounting And Not Object.RecordInManAccounting Then
		Object.RecordInLocalAccounting = True;
	EndIf;
	
	ConfigureDependentFormElements("RecordInLocalAccounting");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.RecordInLocalAccounting And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElements("RecordInManAccounting");

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ConfigureDependentFormElements("Organization,ThereAreRelatedCompanies");
	
EndProcedure

&AtClient
Procedure DocumentInformationInAnotherAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Object.Ref);
		OpenForm("Document.RecognizeSubAssetsComponentsOfDepreciation.ObjectForm", FormParameters);
	EndIf; 
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return; // WE have an empty handler

EndProcedure

#EndRegion

#Region TheAccountingPage

&AtClient
Procedure AccountingProcedureACOnChange(Item)
	
	ChangedBankingDetails = NonCurrentAssetsClientServer.WhenChangingAccountingOrderOfBU_OS(Object, FormServiceParameters, False);
	
	ChangedBankingDetails = Item.Name + ?(Not IsBlankString(ChangedBankingDetails), "," + ChangedBankingDetails, "");
	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure AccountingProcedureMAOnChange(Item)
	
	ChangedBankingDetails = NonCurrentAssetsClientServer.WhenChangingOrderOfAccountingUU_OS(Object, FormServiceParameters, False);
							
	ChangedBankingDetails = Item.Name + ?(Not IsBlankString(ChangedBankingDetails), "," + ChangedBankingDetails, "");
	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure UsefulLifeAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse(Item.Name, True);
	
EndProcedure

&AtClient
Procedure UsefulLifeManagementAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse(Item.Name, False);
	
EndProcedure

&AtClient
Procedure DepreciationMethodAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure DepreciationAccrualMethodManagementAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

#EndRegion

#Region PageExpenseRecord

&AtClient
Procedure ExpenseItemAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemAccounting);
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure ExpenseItemAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
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
Procedure ExpenseItemManagementAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemManagementAccounting);
	
	ConfigureDependentFormElements(Item.Name);
	
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

#Region FormTableItemsEventHandlersDepreciationComponents

&AtClient
Procedure DepreciationComponentsAfterDeleteRow(Item)
	
	ConfigureDependentFormElements("FixedAsset");
	
EndProcedure

&AtClient
Procedure DepreciationComponentsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionOnServer(ValueSelected);
	
EndProcedure

&AtClient
Procedure DepreciationComponentsOnStartEdit(Item, NewRow, Copy)
	
	FillInValuesOfDetailsOfDepreciationComponentsBeforeChange();
	
EndProcedure

&AtClient
Procedure DepreciationComponentsDepreciationComponentOnChange(Item)
	
	DepreciationComponentsDepreciationComponentWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure DepreciationComponentsCostInAccountingOnChange(Item)
	
	DepreciationComponentsCostOfACWhenChangedOnServer();
	
	FillInValuesOfDetailsOfDepreciationComponentsBeforeChange();
	
EndProcedure

&AtClient
Procedure DepreciationComponentsCostInManagementAccountingOnChange(Item)
	
	FillInInformationInBasement();
	
	FillInValuesOfDetailsOfDepreciationComponentsBeforeChange();
	
EndProcedure

&AtClient
Procedure DepreciationComponentsFixedAssetOnChange(Item)
	
	ConfigureDependentFormElements("FixedAsset");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Pick(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.DepreciationComponentsDepreciationComponent, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.DepreciationComponents,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure FillInCost(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.RecognizeSubAssetsComponentsOfDepreciation.Form.DocumentForm.Command.FillInCost");
	
	ClearMessages();
	
	FillInPreliminaryCost();
	
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

#Region AttachableCommands

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

#Region FAFilling

&AtServer
Procedure SelectionOnServer(ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.DepreciationComponents, "DepreciationComponent", ValueSelected);

	If AddedRows.Count() <> 0 Then
		
		ChangedBankingDetails = "DepreciationComponent";
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
		
		FillInPreliminaryCost(AddedRows);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPreliminaryCost(RowsSelected = Undefined)

	ReportErrors = RowsSelected = Undefined;
	
	Cancel = False;
	If Not ValueIsFilled(Object.Date)  Then
		If ReportErrors Then
			MessageText = NStr("vi = 'Chưa điền trường ""Ngày""';
								|ru = 'Поле ""Дата"" не заполнено';
								|en = '""Date"" is required'; fa = '""Date"" is required';
								|it = 'Il campo ""Data"" non è compilato';
								|pl = 'Pole ""Дата"" nie jest wypełnione';
								|tr = '""Tarih"" alanı doldurulmadı'");
			Common.MessageToUser(MessageText, , "Object", "Date", Cancel);
		Else
			Cancel = True;
		EndIf; 
	EndIf;
	If Not ValueIsFilled(Object.Organization) Then
		If ReportErrors Then
			MessageText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
								|ru = 'Поле ""Организация"" не заполнено';
								|en = '""Company"" is required'; fa = '""Company"" is required';
								|it = 'Il campo ""Società"" non è compilato';
								|pl = 'Nie wypełniono pola ""Firma""';
								|tr = '""İş yeri"" alanı doldurulmadı'");
			Common.MessageToUser(MessageText, , "Object", "Organization", Cancel); 
		Else
			Cancel = True;
		EndIf; 
	EndIf;
	
	If Not Cancel Then
		Documents.RecognizeSubAssetsComponentsOfDepreciation.FillInCost(Object, RowsSelected);
	EndIf;
	
	FillInInformationInBasement();
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtServer
Procedure ProcessBarcodes(Val BarcodeData_5)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.DepreciationComponentsDepreciationComponent, ThisObject);
	ObjectsArray = NonCurrentAssets.FindFixedAssetsByBarcodes(BarcodeData_5, PickingParameters);
	SelectionOnServer(ObjectsArray);
	
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

#Region OnChangeAttributes

&AtServer
Procedure DepreciationComponentsDepreciationComponentWhenChangingOnServer()

	ChangedBankingDetails = "DepreciationComponent";
	
	CurrentRow = Items.DepreciationComponents.CurrentRow;
	RowData = Object.DepreciationComponents.FindByID(CurrentRow);
	
	FillInPreliminaryCost(CommonClientServer.ValueInArray(RowData));
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure WhenChangingPeriodOfUse(Var_AttributeName, UpdateIfMatch)

	AttributesList = GetAttributesWhenChangingUsagePeriod(
						Object, Var_AttributeName, UsefulLivesMatch And UpdateIfMatch);
	
	SetTermsOfUseToMatch(ThisObject);
	
	ConfigureDependentFormElements(AttributesList);		

EndProcedure

&AtServer
Procedure DepreciationComponentsCostOfACWhenChangedOnServer()

	CurrentRow = Items.DepreciationComponents.CurrentRow;
	CurrentData = Object.DepreciationComponents.FindByID(CurrentRow);
	
	If ValuesOfDetailsOfComponentsOfDepreciationBeforeChange.CostInAccounting = ValuesOfDetailsOfComponentsOfDepreciationBeforeChange.CostInManagementAccounting 
		And Object.RecordInManAccounting 
		And CurrenciesDoNotMatch
		And FormServiceParameters.ComplianceCAAccountingIsKept Then
		CurrentData.CostInManagementAccounting = CurrentData.CostInAccounting;
	EndIf; 

	FillInInformationInBasement();
	
	ConfigureDependentFormElementsOnServer("CostInAccounting");
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export

	Var ActionParameters;
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, NotificationParameters.ProcessingParameters);
		Return;
	EndIf;

	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ActionParameters);
	EndIf; 
	
EndProcedure

&AtServer
Procedure WhenExecutingEndCommandOnServer(Val CommandName, Val AdditionalParameters)

	If AdditionalParameters.Property("Execute_ConfigureDependentFormElements") Then
		ConfigureDependentFormElementsOnServer(AdditionalParameters.Execute_ConfigureDependentFormElements);
	EndIf; 

EndProcedure
 
&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	InitializingFormWhenCreatingItOnServer();
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	SetTermsOfUseToMatch(ThisObject);
	
	FillInInformationInBasement();
	FillInInformationForReflectingExpenses();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
	PresentationOfDetails = FormServiceParameters.PresentationOfDetails; // Map
	Items.DepreciationComponentsCostInManagementAccounting.Title = PresentationOfDetails.Get("DepreciationComponents.CostInManagementAccounting");
	Items.DepreciationComponentsCostInAccounting.Title = PresentationOfDetails.Get("DepreciationComponents.CostInAccounting");
	Items.DepreciationComponentsResidualValueMan.Title = PresentationOfDetails.Get("DepreciationComponents.ResidualValueMan");
	Items.DepreciationComponentsResidualValueLocal.Title = PresentationOfDetails.Get("DepreciationComponents.ResidualValueLocal");
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("PresentationOfDetails", Documents.RecognizeSubAssetsComponentsOfDepreciation.PresentationOfDetails(Object.Organization, Object.Date));
	NewServiceParametersOfForm.Insert("ThereIsCostAccounting", False);
	NewServiceParametersOfForm.Insert("UseLocal", LocalAccntingServer.ReglRecordsAreMaintained(Object.Date));
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

EndProcedure

&AtServer
Procedure InitializingFormWhenOrganizationChanges()
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
	PresentationOfDetails = Documents.RecognizeSubAssetsComponentsOfDepreciation.PresentationOfDetails(Object.Organization, Object.Date);
	Items.DepreciationComponentsCostInAccounting.Title = PresentationOfDetails.Get("DepreciationComponents.CostInAccounting");
	Items.DepreciationComponentsResidualValueLocal.Title = PresentationOfDetails.Get("DepreciationComponents.ResidualValueLocal");
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails)

	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("UseConstructionObjects", False);
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	AuxiliaryAttributes.Insert("PostInAccounting", Object.RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", Form.CurrenciesDoNotMatch);
	AuxiliaryAttributes.Insert("ThereIsCostAccounting", FormServiceParameters.ThereIsCostAccounting);
	AuxiliaryAttributes.Insert("UseLocal", FormServiceParameters.UseLocal);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	NonCurrentAssetsClientServerLocalization.AddAccountingPolicyParameters(AuxiliaryAttributes, FormServiceParameters);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceOfDepreciationComponentNodesForAccounting(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "FA,TargetFinancing");
		
		ChangedBankingDetails = FillInDetailsDependingOnProperties(Object, ItemDetailsParameters);

		If ValueIsFilled(ChangedBankingDetails) Then
			NonCurrentAssetsClientServer.WhenChangingDetails_AcceptanceOfDepreciationComponentsForAccountingUnits(Object, AuxiliaryAttributes, ChangedBankingDetails);
			ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceOfDepreciationComponentNodesForAccounting(
											Object, AuxiliaryAttributes, ChangedBankingDetails);
		
			TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
		EndIf;
	EndIf;
	
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		Items.RecordInLocalAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.RecordInLocalAccounting.Visible Or Items.RecordInManAccounting.Visible;
		
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then

			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
		EndIf;
		
	EndIf;
	
	#EndRegion
		
	#Region TheAccountingPage
	
	If StructureOfChangedProps.Property("UsefulLifeAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		Form.ACUsefulLifeExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		Form.UsefulLifeMAExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeManagementAccounting);
			
	EndIf;
	
	#EndRegion
	
	#Region PageExpenseRecord
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("ExpenseItemAccounting")
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting")
		Or UpdateAll Then
		
		PropertyValue =
			Form.OwnerSArticlesAreNotDefined
			And (Items.ExpenseItemAccounting.Visible
				Or Items.ExpenseItemManagementAccounting.Visible)
			And (Not ValueIsFilled(Object.ExpenseItemAccounting)
					And Object.RecordInLocalAccounting
				Or Not ValueIsFilled(Object.ExpenseItemManagementAccounting)
					And Object.RecordInManAccounting);
		
		Items.CostReflectionInformationPicture.Visible = PropertyValue;
		Items.CostReflectionInformationText.Visible = PropertyValue;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		InitializingFormWhenOrganizationChanges();
		ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Object.Organization);
		SetFormFunctionalOptionParameters(New Structure("Organization", ParentCompany));
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ThereIsCostAccounting",
			CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(Object.Date),
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"UseLocal",
			LocalAccntingServer.ReglRecordsAreMaintained(Object.Date),
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"FSB6IsApplied",
			AccountingPoliciesTaxSettingsCached.FSB6IsApplied(Object.Organization, Object.Date),
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		FillInInformationForReflectingExpenses();
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("DepreciationComponents") 
		Or StructureOfChangedProps.Property("DepreciationComponent")
		Or StructureOfChangedProps.Property("FixedAsset") Then
			
		Return True;
	EndIf; 
	
	Return False;

EndFunction

&AtClientAtServerNoContext
Function FillInDetailsDependingOnProperties(Object, ItemDetailsParameters)

	ChangedBankingDetails = New Array;
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		If Not ValueIsFilled(AttributeParameters.AttributeName)
			Or StrSplit(AttributeParameters.AttributeName, ".").UBound() <> 0 Then
			Continue;
		EndIf;
		
		Action = NonCurrentAssetsClientServer.ClearOrFill(Object, AttributeParameters);
		
		If Not ValueIsFilled(Action) Then
			Continue;
		EndIf;
		
		#Region TheAccountingPage
		
		If AttributeParameters.AttributeName = "AccountingProcedureAC"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationAccrualAccounting" Then
			Object[AttributeParameters.AttributeName] = ?(Action = "Fill", True, False);
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationMethodAccounting"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		//
		If AttributeParameters.AttributeName = "AccountingProcedureMA"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationAccrualManagementAccounting" Then
			Object[AttributeParameters.AttributeName] = ?(Action = "Fill", True, False);
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationAccrualMethodManagementAccounting"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		#EndRegion
		
	EndDo; 
	
	Return StrConcat(ChangedBankingDetails, ",");
	
EndFunction

&AtClientAtServerNoContext
Procedure SetTermsOfUseToMatch(Form)

	Form.UsefulLivesMatch = Not Form.Object.RecordInManAccounting Or (Form.Object.UsefulLifeAccounting = Form.Object.UsefulLifeManagementAccounting);

EndProcedure

&AtClientAtServerNoContext
Function GetAttributesWhenChangingUsagePeriod(Object, AttributeName, UpdateUsagePeriod)
	
	AttributesList = AttributeName;
	
	If AttributeName <> "UsefulLifeManagementAccounting"
		And Object.RecordInManAccounting
		And (Object.UsefulLifeManagementAccounting = 0
			Or UpdateUsagePeriod) Then
		
		Object.UsefulLifeManagementAccounting = Object[AttributeName];
		AttributesList = AttributesList + ",UsefulLifeManagementAccounting";
		
	EndIf;
	
	If AttributeName <> "UsefulLifeAccounting"
		And Object.RecordInManAccounting
		And (Object.UsefulLifeAccounting = 0
			Or UpdateUsagePeriod) Then
		
		Object.UsefulLifeAccounting = Object[AttributeName];
		AttributesList = AttributesList + ",UsefulLifeAccounting";
		
	EndIf;
	
	Return AttributesList;

EndFunction

&AtServer
Procedure FillInInformationInBasement()

	LabelTitle = NonCurrentAssetsInternal.DocumentInformationInAnotherAccounting(Object);
	If PreliminaryCostDiffersFromActual() Then
		If LabelTitle.Count() <> 0 Then
			LabelTitle.Add(Chars.LF);
		EndIf;
		LabelTitle.Add(NStr("vi = 'Giá trị tạm tính khác với giá trị thực tế.';
							|ru = 'Предварительная стоимость отличается от фактической.';
							|en = 'The preliminary cost differs from the actual cost.'; fa = 'The preliminary cost differs from the actual cost.';
							|it = 'The preliminary cost differs from the actual cost.';
							|pl = 'The preliminary cost differs from the actual cost.';
							|tr = 'Ön maliyet, gerçek maliyetten farklıdır.'"));
	EndIf; 

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
Procedure FillInInformationForReflectingExpenses()
	
	OwnerSArticlesAreNotDefined = False;
	
	QueryText = 
	"SELECT TOP 1
	|	Assets.Ref
	|FROM
	|	Catalog.Assets AS Assets
	|	
	|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&Date,
	|			&RecordInLocalAccounting
	|			AND Organization = &Organization
	|			AND FixedAsset IN (&ListOfFA)) AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.FixedAsset = Assets.Ref
	|		
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&Date,
	|			&RecordInManAccounting
	|			AND Organization = &Organization
	|			AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = Assets.Ref		
	|		
	|WHERE
	|	Assets.Ref IN (&ListOfFA)
	|	AND (&RecordInLocalAccounting 
	|			AND AccountingProcedureForOSBU.ExpenseItemAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		OR &RecordInManAccounting
	|			AND FixedAssetsAccountingProcedureManagementAccounting.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	Query.SetParameter("ListOfFA", Object.DepreciationComponents.Unload(, "FixedAsset"));
	
	Result = Query.Execute();
	
	OwnerSArticlesAreNotDefined = Not Result.IsEmpty();
	
EndProcedure

&AtServer
Function PreliminaryCostDiffersFromActual()

	QueryText = 
	"SELECT
	|	TableOfDepreciationComponents.DepreciationComponent AS DepreciationComponent,
	|	TableOfDepreciationComponents.CostInAccounting AS CostInAccounting,
	|	TableOfDepreciationComponents.CostInManagementAccounting AS CostInManagementAccounting
	|INTO TTTableOfShockAbsorptionComponents
	|FROM
	|	&TableOfDepreciationComponents AS TableOfDepreciationComponents
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TableOfDepreciationComponents.DepreciationComponent AS DepreciationComponent
	|FROM
	|	TTTableOfShockAbsorptionComponents AS TableOfDepreciationComponents
	|		INNER JOIN AccumulationRegister.FACost AS FACost
	|		ON (FACost.Recorder = &Ref)
	|			AND TableOfDepreciationComponents.DepreciationComponent = FACost.FixedAsset
	|			AND (FACost.CostCalculation)
	|			AND (FACost.RecordType = VALUE(AccumulationRecordType.Receipt))
	|
	|GROUP BY
	|	TableOfDepreciationComponents.DepreciationComponent
	|
	|HAVING
	|	(MAX(TableOfDepreciationComponents.CostInAccounting) <> SUM(FACost.LocalCost)
	|		OR MAX(TableOfDepreciationComponents.CostInManagementAccounting) <> SUM(FACost.Cost))";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("TableOfDepreciationComponents", Object.DepreciationComponents.Unload());
	
	Result = Query.Execute();
	Result = Not Result.IsEmpty();
	
	Return Result;

EndFunction

&AtClient
Procedure FillInValuesOfDetailsOfDepreciationComponentsBeforeChange()

	AttributesValuesBeforeChange = New Structure;
	AttributesValuesBeforeChange.Insert("CostInManagementAccounting", 0);
	AttributesValuesBeforeChange.Insert("CostInAccounting", 0);
	
	CurrentData = Items.DepreciationComponents.CurrentData;
	If CurrentData <> Undefined Then
		FillPropertyValues(AttributesValuesBeforeChange, CurrentData);
	EndIf;
	
	ValuesOfDetailsOfComponentsOfDepreciationBeforeChange = New FixedStructure(AttributesValuesBeforeChange);

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

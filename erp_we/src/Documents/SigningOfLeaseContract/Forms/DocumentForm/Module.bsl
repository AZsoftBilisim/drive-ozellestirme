#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		Object.Date = CurrentSessionDate();
		If Object.ExpenseItem = Undefined Then
			Object.ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
		EndIf;
		If Object.IncomeItem = Undefined Then
			Object.IncomeItem = ChartsOfCharacteristicTypes.IncomeItems.EmptyRef();
		EndIf;
		OnReadCreateAtServer();
	EndIf;
	
	AddressOfTheContractSchedule = PutToTempStorage(Undefined, UUID);
	
	ItemsAndDimensionsSelectionParameters = Documents.SigningOfLeaseContract.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AccountSettings_ = Documents.SigningOfLeaseContract.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, AccountSettings_);
	
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

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ItemsAndDimensionsSelectionParameters = Documents.SigningOfLeaseContract.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AccountingAccountSettings_ = Documents.SigningOfLeaseContract.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, AccountingAccountSettings_);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	If EventName = "Recording_NotificationOfSpecialTaxRegimes" Then
		
		UpdateTextDocumentsBasedOn();
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	UpdateTextDocumentsBasedOn();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_SigningOfLeaseContract", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	CurrentObject.CompleteTaxationBeforeWrite();
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SelectedRows = Items.FA.SelectedRows;
		
		For Each SelectedRow In SelectedRows Do
			RowData = Object.FA.FindByID(SelectedRow);
			RowData.Department = ValueSelected;
		EndDo;
		
	ElsIf ChoiceSource.FormName = "ChartOfCharacteristicTypes.ExpenseItems.Form.ChoiceForm" Then
		
		SelectedRows = Items.FA.SelectedRows;
		
		For Each SelectedRow In SelectedRows Do
			RowData = Object.FA.FindByID(SelectedRow);
			RowData.ExpenseItem = ValueSelected;
		EndDo;
		
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);

	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();

EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	
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
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
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
Procedure PresentationOfTheIncomeReflectionInTheReglAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
EndProcedure

#EndRegion

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, Var_URL, StandardProcessing)
	
	ClearMessages();
	StandardProcessing = False;
	DPPSelectionParameters = New Structure();
	DPPSelectionParameters.Insert("Organization", Object.Organization);
	DPPSelectionParameters.Insert("Basis",   Object.Ref);
	DPPSelectionParameters.Insert("Date",        Object.Date);
	
	VATAccountingERPClient.ProcessingOfNavigationLinkDOPP(ThisObject, DPPSelectionParameters, Var_URL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfTheCostReflectionInTheReglAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
EndProcedure

#Region PagePaymentsUnderTheContract

&AtClient
Procedure SecurityDepositAmountOnChange(Item)
	
	RecalculateContractAmountAndVATAmount(Object);
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure DateOfFirstSecurityPaymentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure LeaseServicesAmount(Item)
	
	AmountOfRentalServicesWhenChangedOnServer();

EndProcedure

&AtClient
Procedure DateOfFirstPaymentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure AmountOfLeaseAssetsByuoutOnChange(Item)
	
	AmountOfRedemptionOfRentalItemsWhenChangingOnServer();

EndProcedure

&AtClient
Procedure VATAmountOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure VATRateOnChange(Item)
	
	VATRateForChangesOnServer();

EndProcedure

&AtClient
Procedure RentalPeriodURLProcessing(Item, FormattedStringURL, StandardProcessing)

	StandardProcessing = False;
	
	LeasedAssetAccountingClient.EnterLeaseTerm(
		ThisObject, 
		Object,
		New CallbackDescription("EnterLeaseTermCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure PaymentFrequencyOnChange(Item)
	
	If Not ValueIsFilled(Object.PaymentFrequency) Then
		Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Month");
	EndIf;
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure AccrualFrequencyOnChange(Item)
	
	If Not ValueIsFilled(Object.AccrualFrequency) Then
		Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Month");
	EndIf;
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure PaymentForLeaseServiceOnChange(Item)
	
	ChangedBankingDetails = Item.Name;
	
	If Object.PaymentFrequency = Object.AccrualFrequency
		And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
		And Object.AccrualOfLeaseService = 0
		And Object.PaymentForLeaseService <> 0 Then
			
		Object.AccrualOfLeaseService = Object.PaymentForLeaseService;
		ChangedBankingDetails = ChangedBankingDetails + ",AccrualOfLeaseService";
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);

EndProcedure

&AtClient
Procedure AccrualOfLeaseServiceOnChange(Item)
	
	ChangedBankingDetails = Item.Name;
	
	If Object.PaymentFrequency = Object.AccrualFrequency
		And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
		And Object.PaymentForLeaseService = 0
		And Object.AccrualOfLeaseService <> 0 Then
			
		Object.PaymentForLeaseService = Object.AccrualOfLeaseService;
		ChangedBankingDetails = ChangedBankingDetails + ",PaymentForLeaseService";
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);

EndProcedure

&AtClient
Procedure BasementInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#FillInSchedule" Then
		FillInScheduleAccordingToCalculations();		
	ElsIf FormattedStringURL = "#FillInCalculationsAccordingToSchedule" Then
		FillInCalculationsAccordingToSchedule();		
	ElsIf FormattedStringURL = "#ChangeDocumentVersion" Then
		ChangeDocumentVersion();		
	EndIf;
	
EndProcedure

#EndRegion

#Region AdditionalPage

&AtClient
Procedure VATTaxationOnChange(Item)
	TaxationOfVATWhenChangingOnServer();
EndProcedure

&AtClient
Procedure PurchaseForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected);
	
EndProcedure

&AtClient
Procedure FASelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.FA.CurrentData;
	
	If ReadOnly 
		And Field = Items.FAFixedAsset
		And CurrentData <> Undefined
		And ValueIsFilled(CurrentData.FixedAsset) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.FixedAsset);
	EndIf;

EndProcedure

&AtClient
Procedure FAOnEditEnd(Item, NewRow, CancelEdit)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure FAOnChange(Item)
	
	Object.PresentValue = PresentValue(Object, FormServiceParameters.ContractDetails_);

EndProcedure

&AtClient
Procedure FAFairValueOnChange(Item)
	
	CalculateCostOfFA();
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure FANonGuaranteedFinalCostOnChange(Item)
	
	CalculateCostOfFA();
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure FAFixedAssetStartChoice(Item, ChoiceData, StandardProcessing)

	If Item = Items.FAFixedAsset Then
		FASelectionOptions = New Array(Item.ChoiceParameters);

		For Each ChoiceParameter In FASelectionOptions Do

			If ChoiceParameter.Name = "Filter.Busstate" Then
				FilterByState = New Array(ChoiceParameter.Value);
				SelectionOfDeRegistered = FilterByState.Find(PredefinedValue("Enum.FixedAssetsStates.TakenOffBooks"));

				If CreatedForTransition Then
					If SelectionOfDeRegistered = Undefined Then
						FilterByState.Add(PredefinedValue("Enum.FixedAssetsStates.TakenOffBooks"));
					EndIf;
				Else
					If SelectionOfDeRegistered <> Undefined Then
						FilterByState.Delete(SelectionOfDeRegistered);
					EndIf;
				EndIf;

				Break;

			EndIf;

		EndDo;

		SelectionParameterBasedOnFAStateDuringTransition = New ChoiceParameter("Filter.Busstate",
																		New FixedArray(FilterByState));

		FASelectionOptions.Delete(FASelectionOptions.Find(ChoiceParameter));
		FASelectionOptions.Add(SelectionParameterBasedOnFAStateDuringTransition);

		Item.ChoiceParameters = New FixedArray(FASelectionOptions);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	CalculateTheBidOrCost(Command);
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	CalculateTheBidOrCost(Command);
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure Pick(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	
	If CreatedForTransition Then
		FilterByState = New Array(PickingParameters.Filter.Busstate);
		If FilterByState.Find(PredefinedValue("Enum.FixedAssetsStates.TakenOffBooks")) = Undefined Then 
			FilterByState.Add(PredefinedValue("Enum.FixedAssetsStates.TakenOffBooks"));
		EndIf;
	Else
		FilterByState = New Array(PickingParameters.Filter.Busstate);
		SelectionOfDeRegistered = FilterByState.Find(PredefinedValue("Enum.FixedAssetsStates.TakenOffBooks"));
		If SelectionOfDeRegistered <> Undefined Then 
			FilterByState.Delete(SelectionOfDeRegistered);
		EndIf;
	EndIf;
	
	PickingParameters.Filter.Busstate = New FixedArray(FilterByState);

	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenPaymentSchedule(Command)
	
	OpenPaymentAndAccrualSchedule("ServicePaymentSchedule");
	
EndProcedure

&AtClient
Procedure OpenTheAccrualSchedule(Command)
	
	OpenPaymentAndAccrualSchedule("ServiceAccrualSchedule");

EndProcedure

&AtClient
Procedure OpenTheInterestAccrualSchedule(Command)
	
	OpenPaymentAndAccrualSchedule("InterestAccrualSchedule");

EndProcedure

&AtClient
Procedure CalculateTheBidOrCost(Command)
	
	If LeasedAssetAccountingClient.YouCanCalculateRateOrCost(Object, FormServiceParameters.ContractDetails_, "FA") Then
		CalculateRateCostPercentagesOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure FillInTheDepartment(Command)
	
	SelectedRows = Items.FA.SelectedRows;
	
	If Object.FA.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Không có dòng nào được nhập vào danh sách ""Tài sản cố định hữu hình"".';
								|ru = 'В список ""ОС"" не введено ни одной строки.';
								|en = 'No lines are entered in the Fixed assets list.'; fa = 'No lines are entered in the Fixed assets list.';
								|it = 'В список ""ОС"" не введено ни одной строки.';
								|pl = 'No lines are entered in the Fixed assets list.';
								|tr = '""SV"" listesine herhangi bir satır girilmemiştir.'"));
		Return;
	ElsIf Not SelectedRows.Count() Then
		ShowMessageBox( , NStr("vi = 'Trong danh sách ""Tài sản cố định hữu hình"" chưa chọn dòng nào.';
								|ru = 'В списке ""ОС"" не выбрано ни одной строки.';
								|en = 'No lines are selected in the Fixed assets list.'; fa = 'No lines are selected in the Fixed assets list.';
								|it = 'В списке ""ОС"" не выбрано ни одной строки.';
								|pl = 'No lines are selected in the Fixed assets list.';
								|tr = '""SV"" listesinde herhangi bir satır girilmemiştir.'"));
		Return;
	EndIf;
	
	OpenForm("Catalog.BusinessStructure.ChoiceForm",, ThisObject);

EndProcedure

&AtClient
Procedure FillInExpenseItem(Command)
	
	SelectedRows = Items.FA.SelectedRows;
	
	If Object.FA.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Không có dòng nào được nhập vào danh sách ""Tài sản cố định hữu hình"".';
								|ru = 'В список ""ОС"" не введено ни одной строки.';
								|en = 'No lines are entered in the Fixed assets list.'; fa = 'No lines are entered in the Fixed assets list.';
								|it = 'В список ""ОС"" не введено ни одной строки.';
								|pl = 'No lines are entered in the Fixed assets list.';
								|tr = '""SV"" listesine herhangi bir satır girilmemiştir.'"));
		Return;
	ElsIf SelectedRows.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Trong danh sách ""Tài sản cố định hữu hình"" chưa chọn dòng nào.';
								|ru = 'В списке ""ОС"" не выбрано ни одной строки.';
								|en = 'No lines are selected in the Fixed assets list.'; fa = 'No lines are selected in the Fixed assets list.';
								|it = 'В списке ""ОС"" не выбрано ни одной строки.';
								|pl = 'No lines are selected in the Fixed assets list.';
								|tr = '""SV"" listesinde herhangi bir satır girilmemiştir.'"));
		Return;
	EndIf;
	
	ListFilter = New Structure;
	ListFilter.Insert("ExpensesOnAssets", True);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", ListFilter);
	OpenForm("ChartOfCharacteristicTypes.ExpenseItems.ChoiceForm", FormParameters, ThisObject);
	
EndProcedure

#Region StandardSubsystems

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

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

#EndRegion

#EndRegion

#Region Private

#Region OnChangeAttributes

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
	
	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("VNAManagementIsUsed_2_4", 
											FormServiceParameters.VNAManagementIsUsed_2_4);
											
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", 
											FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed);
											
	AuxiliaryAttributes.Insert("StartOfLeaseAccountingUnderFSB25_2018", 
											FormServiceParameters.StartOfLeaseAccountingUnderFSB25_2018);
											
	AuxiliaryAttributes.Insert("ContractDetails_", FormServiceParameters.ContractDetails_);
	AuxiliaryAttributes.Insert("InsignificantVATRate", FormServiceParameters.InsignificantVATRate);
	
	AuxiliaryAttributes.Insert("SeparateFAAccountingByVATTaxation", 
											FormServiceParameters.SeparateFAAccountingByVATTaxation);
											
	AuxiliaryAttributes.Insert("DocumentVersion24", Object.DocumentVersion24);
	AuxiliaryAttributes.Insert("RecordInOperationalAccounting", True);
	AuxiliaryAttributes.Insert("NameOfFATablePart", "FA");
	AuxiliaryAttributes.Insert("MethodForDeterminingCostOfAssets", 
											FormServiceParameters.ContractDetails_.MethodForDeterminingCostOfAssets);
	AuxiliaryAttributes.Insert("ContractType", FormServiceParameters.ContractDetails_.ContractType);

	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_ConclusionOfLeaseAgreement(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(
			Object, ItemDetailsParameters, "ServicePaymentSchedule,ServiceAccrualSchedule,InterestAccrualSchedule");
	EndIf;
	
	AccountingForBalanceSheet = (FormServiceParameters.ContractDetails_.AssetHolder = 
							PredefinedValue("Enum.LeasedAssetHolder.Lessor"));
	
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		Items.Comment.MaxWidth = 
			?(FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed Or Not AccountingForBalanceSheet, 67, 75);
			
	EndIf;
	
	#EndRegion
	
	#Region PagePaymentsUnderTheContract
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then

		PropertyValue =
			AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed 
			Or Not AccountingForBalanceSheet;
			
		Items.PictureHowToFillOutCalculations.Visible = PropertyValue;
		Items.ExplanationHowToFillOutCalculations.Visible = PropertyValue;	
	EndIf;
	
	#EndRegion
	
	#Region OSPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
			
		If AuxiliaryAttributes.ContractType = 
			PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
			And AuxiliaryAttributes.MethodForDeterminingCostOfAssets = 
			PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Discounting")
			Or AuxiliaryAttributes.MethodForDeterminingCostOfAssets = 
			PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount") Then
			
			Items.FAFairValue.Visible = True;
			
		EndIf;
		
		PropertyValue = 
			(Items.FAFairValue.Visible
			+ Items.FANonGuaranteedFinalCost.Visible
			+ Items.FACost.Visible) > 1;
		
		Items.OsgroupCost.ShowTitle = PropertyValue;
		Items.OsgroupCost.ShowInHeader = PropertyValue;
		
	EndIf;
	
	#EndRegion
	
	#Region FooterGroup
	
	If StructureOfChangedProps.Property("VATTaxation")
		Or UpdateAll Then
		
		PurchaseIsSubjectToVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(Object.VATTaxation);
		
		If PurchaseIsSubjectToVAT Then
			Items.VATPageGroup.CurrentPage   = Items.PageVAT;
			Items.PagesTotalGroup.CurrentPage = Items.TotalSNDSPage;
		Else
			Items.VATPageGroup.CurrentPage   = Items.PageExcludingVAT;
			Items.PagesTotalGroup.CurrentPage = Items.PageTotalWithoutVAT;
		EndIf;
	
	EndIf;
	
	#EndRegion
	
	LeasedAssetAccountingClientServer.ConfigureDependentFormElements__(Form, AuxiliaryAttributes, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	CreatedForTransition = LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Object.Date, Object.Organization);
	
	#Region Other
	
	If UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"UseVATAccounting",
			GetFunctionalOption("UseVATAccounting"),
			FormServiceParameters);
		
		If Not FormServiceParameters.UseVATAccounting Then
			Items.AmountOfPersonalIncomeTax.Visible = False;
		EndIf;
		
	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrencyPresentation",
			String(LocalAccountingCurrency),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrenciesDoNotMatch",
			FormServiceParameters.CurrencyOfManPresentation = FormServiceParameters.ComplCurrencyPresentation,
			FormServiceParameters);
		ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Object.Organization);
		SetFormFunctionalOptionParameters(New Structure("Organization", ParentCompany));
		
	EndIf;
		
	If StructureOfChangedProps.Property("Organization") Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"StartOfLeaseAccountingUnderFSB25_2018",
			LeasedAssetAccounting.StartOfLeaseAccountingUnderFSB25_2018(Object.Organization),
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date") Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"VNAManagementIsUsed_2_4",
			NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date),
			FormServiceParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date, True),
			FormServiceParameters);
		
		AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"VATAccountingSettings", Object.Organization, ?(Object.Date <> '000101010000', EndOfMonth(Object.Date), '000101010000'));

		NonCurrentAssetsInternal.SetStructureProperty(
			"SeparateFAAccountingByVATTaxation",
			AccountingPolicyParameters <> Undefined And AccountingPolicyParameters.SeparateFAAccountingByVATTaxation,
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("VATRate") Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"InsignificantVATRate",
			VATAccountingERP.InsignificantRate(Object.VATRate),
			FormServiceParameters);
		
	EndIf;

	#EndRegion

	#Region ItemsTitles
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		ParametersPresentationOfAttributesOfFA = 
			LeasedAssetAccounting.ParametersPresentationOfAttributesOfFA(Object, FormServiceParameters, CreatedForTransition);
		PresentationOfDetails = LeasedAssetAccounting.PresentationOfFAAttributes(ParametersPresentationOfAttributesOfFA);
			
		Items.FACost.Title = PresentationOfDetails.Get("FA.Cost_Header");
		Items.FACost.ToolTip = PresentationOfDetails.Get("FA.Cost_Hint");
		Items.FAFairValue.Title = PresentationOfDetails.Get("FA.FairCost_Title");
		Items.FAFairValue.ToolTip = PresentationOfDetails.Get("FA.FairCost_Hint");
		Items.OsgroupCost.Title = PresentationOfDetails.Get("FA.CostGroup_Title");
		DocumentCurrencyPresentation = ParametersPresentationOfAttributesOfFA.DocumentCurrencyPresentation;
	
	EndIf;
	
	Items.TransitionLabel.Visible = CreatedForTransition;
	
	#EndRegion

	#Region TabularPartOfFA
	// In the documents created for the transition to FSB, the NET BOOK VALUE column is required to be filled in.
	Items.FANetBookValue.AutoMarkIncomplete = CreatedForTransition;
	#EndRegion
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	Return StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract");

EndFunction

&AtServer
Procedure DateOfChangeOnServer()
	
	UpdatePurchaseForActivity();
	
	ConfigureDependentFormElementsOnServer("Date,PurchaseForActivity");
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	UpdatePurchaseForActivity();
	FillInVATRate();
	
	ConfigureDependentFormElementsOnServer("Organization,Contract,PurchaseForActivity");
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	FillParameters = Documents.SigningOfLeaseContract.ParametersForFillingInVATTaxationPurchases(Object);
	
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);

	VATAccountingERP.FillInVATTaxationPurchases(
		Object.VATTaxation, 
		FillParameters, 
		VATAccountingCachedParameterValues);
		
	Contract = Catalogs.LeaseContract.DefaultContract(
					Object.Organization, Object.Partner, Object.Counterparty, Object.Contract);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		AgreementWhenModifiedOnServer();
	EndIf;
	
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	FillParameters = Documents.SigningOfLeaseContract.ParametersForFillingInVATTaxationPurchases(Object);
	
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);

	VATAccountingERP.FillInVATTaxationPurchases(
		Object.VATTaxation, 
		FillParameters, 
		VATAccountingCachedParameterValues);
		
	UpdatePurchaseForActivity();

	AddContractDetailsToServiceParametersOfForm();
	
	If Not ValueIsFilled(Object.Contract) Then
		Object.ARAPCurrency = Undefined;
		Object.Currency = Undefined;
	EndIf;
	
	ContractDetails_ = FormServiceParameters.ContractDetails_;
	
	Object.ARAPCurrency = ContractDetails_.ARAPCurrency;
	Object.Currency = ContractDetails_.ARAPCurrency;
	DocumentCurrency = Object.Currency;
	
	Object.PresentValue = PresentValue(Object, FormServiceParameters.ContractDetails_);
	
	ConfigureDependentFormElementsOnServer("Contract,VATTaxation,PurchaseForActivity");
	
EndProcedure

&AtServer
Procedure AddContractDetailsToServiceParametersOfForm()
	
	NonCurrentAssetsInternal.SetStructureProperty(
		"ContractDetails_",
		LeasedAssetAccounting.DetailsOfLeaseAgreement(Object.Contract),
		FormServiceParameters);
	
EndProcedure

&AtServer
Procedure AmountOfRentalServicesWhenChangedOnServer()
	
	RecalculateContractAmountAndVATAmount(Object);
	ConfigureDependentFormElementsOnServer("LeaseServicesAmount");
	
EndProcedure

&AtServer
Procedure AmountOfRedemptionOfRentalItemsWhenChangingOnServer()

	RecalculateContractAmountAndVATAmount(Object);
	RecalculateAmountOfVATRepurchaseOfRentalItems(Object);
	
	ConfigureDependentFormElementsOnServer("AmountOfLeaseAssetsByuout");
	
EndProcedure

&AtServer
Procedure VATRateForChangesOnServer()
	
	RecalculateContractAmountAndVATAmount(Object);
	RecalculateAmountOfVATRepurchaseOfRentalItems(Object);

	Object.PresentValue = PresentValue(Object, FormServiceParameters.ContractDetails_);

	ConfigureDependentFormElementsOnServer("VATRate");
	
EndProcedure

&AtClient
Procedure CalculateCostOfFA()
	
	// For lease Contracts with discounting, we reset the cost column when the fair value changes.
	If FormServiceParameters.ContractDetails_.ContractType = 
			PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
		And FormServiceParameters.ContractDetails_.MethodForDeterminingCostOfAssets = 
			PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Discounting") 
		Or FormServiceParameters.ContractDetails_.MethodForDeterminingCostOfAssets = 
			PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount") Then
				For Each FAString In Object.FA Do
					FAString.Cost = 0;
				EndDo;
	Else
		CurrentData = Items.FA.CurrentData;
		CurrentData.Cost = CurrentData.FairValue - CurrentData.NonGuaranteedFinalCost;
	EndIf;
	
EndProcedure

#EndRegion

#Region RecalculationOfAmounts

&AtClientAtServerNoContext
Procedure RecalculateContractAmountAndVATAmount(Object)
	
	LeasedAssetAccountingClientServer.RecalculateAmountOfRentalDocument(Object);
	LeasedAssetAccountingClientServer.RecalculateAmountOfNDSInLeaseDocument(Object);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateAmountOfVATRepurchaseOfRentalItems(Object)
	
	CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(Object.VATRate);
	Object.AmountOfVATRepurchaseOfRentalItems = VATAccountingERPClientServer.CalculateVATAmount(Object.AmountOfLeaseAssetsByuout, CurPercentVAT, True);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region FACost_Text
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FACost.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheCostIsCalculatedAutomatically");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.Cost");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<được tính tự động>';
													|ru = '<рассчитывается автоматически>';
													|en = '<calculated automatically>'; fa = '<calculated automatically>';
													|it = '<viene calcolato automaticamente>';
													|pl = '<oblicza się automatycznie>';
													|tr = '<otomatik olarak hesaplanır>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
		
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("AssetHolder", Undefined);

	ParameterValue = NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date);
	NewServiceParametersOfForm.Insert("VNAManagementIsUsed_2_4", ParameterValue);

	ParameterValue = LeasedAssetAccounting.StartOfLeaseAccountingUnderFSB25_2018(Object.Organization);
	NewServiceParametersOfForm.Insert("StartOfLeaseAccountingUnderFSB25_2018", ParameterValue);

	ParameterValue = LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date, True);
	NewServiceParametersOfForm.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", ParameterValue);

	ParameterValue = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", ParameterValue);
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	NewServiceParametersOfForm.Insert("CurrencyOfManPresentation", String(CurrencyOfMan));
	NewServiceParametersOfForm.Insert("ComplCurrencyPresentation", String(ComplCurrency));
	NewServiceParametersOfForm.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	NewServiceParametersOfForm.Insert("InsignificantVATRate", VATAccountingERP.InsignificantRate(Object.VATRate));
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

	AddContractDetailsToServiceParametersOfForm();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	FillParameters = Documents.SigningOfLeaseContract.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);

	UpdatePurchaseForActivity();

	InitializeServiceParametersOfForm();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializingFormWhenCreatingItOnServer();
	
	DocumentCurrency = Object.Currency;
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	ConfigureDependentFormElementsOnServer();
	UpdateTextDocumentsBasedOn();
	
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure TaxationOfVATWhenChangingOnServer()
	
	FillInVATRate();
	RecalculateContractAmountAndVATAmount(Object);

	ConfigureDependentFormElementsOnServer("VATTaxation,VATRate");	
	
EndProcedure

&AtServer
Procedure UpdatePurchaseForActivity(Fill = True)
	
	FillParameters = Documents.SigningOfLeaseContract.ParametersForFillingInVATActivityType(Object);
	
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.PurchaseForActivity, 
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.PurchaseForActivity,
		Object.PurchaseForActivity,
		FillParameters, 
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure FillInVATRate()
	
	If Object.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT
		Or Object.VATTaxation = Enums.VATTaxationTypes.VATTaxAgent Then
		Object.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
	Else
		Object.VATRate = VATAccountingERP.DefaultVATRate(Object.Organization, Object.Date);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenPaymentAndAccrualSchedule(ChartName)
	
	LeasedAssetAccountingClient.OpenPaymentAndAccrualSchedule(
		Object, 
		ThisObject, 
		PutGraphsInTemporaryStorage(), 
		New CallbackDescription("OpenPaymentAndAccrualScheduleCompletion", ThisObject), 
		ChartName);
	
EndProcedure

&AtServer
Function PutGraphsInTemporaryStorage()

	ContractSchedules = New Structure;
	ContractSchedules.Insert("ServiceAccrualSchedule", Object.ServiceAccrualSchedule.Unload());
	ContractSchedules.Insert("ServicePaymentSchedule", Object.ServicePaymentSchedule.Unload());
	ContractSchedules.Insert("InterestAccrualSchedule", Object.InterestAccrualSchedule.Unload());

	Address = PutToTempStorage(ContractSchedules, AddressOfTheContractSchedule);
		
	Return Address;
	
EndFunction

&AtClient
Procedure OpenPaymentAndAccrualScheduleCompletion(ClosingResult, AddlParameters) Export

	If Not IsTempStorageURL(ClosingResult) Then
		Return;
	EndIf;

	OpenPaymentAndAccrualScheduleDirectlyOnServer(ClosingResult);
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtServer
Procedure OpenPaymentAndAccrualScheduleDirectlyOnServer(Val ClosingResult)
	
	Modified = True;

	ContractSchedules = GetFromTempStorage(ClosingResult);

	Object.TheInterestAccrualScheduleIsEnteredManually = ContractSchedules.TheInterestAccrualScheduleIsEnteredManually;
	Object.InterestAmount = ContractSchedules.InterestAmount;
	Object.ServicePaymentSchedule.Load(ContractSchedules.ServicePaymentSchedule);
	Object.ServiceAccrualSchedule.Load(ContractSchedules.ServiceAccrualSchedule);
	Object.InterestAccrualSchedule.Load(ContractSchedules.InterestAccrualSchedule);
	
	LeasedAssetAccountingClientServer.RecalculateAmountOfNDSInLeaseDocument(Object);

	Object.PresentValue = PresentValue(Object, FormServiceParameters.ContractDetails_);

	ConfigureDependentFormElementsOnServer(
		"ServicePaymentSchedule,ServiceAccrualSchedule,InterestAccrualSchedule,TheInterestAccrualScheduleIsEnteredManually");
	
EndProcedure

&AtServer
Procedure CalculateRateCostPercentagesOnServer()

	Documents.SigningOfLeaseContract.CalculateRateCostInterest(Object, FormServiceParameters.ContractDetails_);
	
	ConfigureDependentFormElementsOnServer("FAFairValue");
			
EndProcedure

&AtClient
Procedure FillInScheduleAccordingToCalculations()
	
	If (Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Custom")
			Or Not ValueIsFilled(Object.PaymentFrequency))
		And (Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Custom")
			Or Not ValueIsFilled(Object.AccrualFrequency)) Then
				
		Return;
	EndIf;
	
	If LeasedAssetAccountingClient.CheckAbilityToFillInScheduleByCalculations(Object, FormServiceParameters.ContractDetails_) Then
		
		CalculateTheBidOrCost = LeasedAssetAccountingClient.YouCanCalculateRateOrCost(
			Object, FormServiceParameters.ContractDetails_, "FA", False);
			
		FillInScheduleForCalculationsOnServer(CalculateTheBidOrCost);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInScheduleForCalculationsOnServer(Val CalculateTheBidOrCost)
	
	Modified = True;
	
	LeasedAssetAccounting.FillInScheduleOfPaymentsAndChargesForSettlements(Object, FormServiceParameters.ContractDetails_);
	
	Object.PresentValue = PresentValue(Object, FormServiceParameters.ContractDetails_);
	
	If CalculateTheBidOrCost Then
		CalculateRateCostPercentagesOnServer();
	EndIf;
	LeaseTermHasBeenChanged = False;
	
	ConfigureDependentFormElementsOnServer("ServicePaymentSchedule,ServiceAccrualSchedule");
	
EndProcedure

&AtServer
Procedure FillInCalculationsAccordingToSchedule()
	
	Modified = True;

	LeasedAssetAccounting.FillInCalculationsAccordingToScheduleOfPaymentsAndAccruals(Object, FormServiceParameters.ContractDetails_);
	
	ChangedBankingDetails = 
	"SecurityDepositAmount,DateOfFirstSecurityPayment,
	|LeaseServicesAmount,DateOfFirstPayment,
	|AmountOfLeaseAssetsByuout,AmountOfVATRepurchaseOfRentalItems,
	|VATAmount,
	|PaymentFrequency,PaymentForLeaseService,
	|AccrualFrequency,AccrualOfLeaseService";

	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure ChangeDocumentVersion()
	
	QueryText = NStr("vi = 'Sau khi thay đổi phiên bản chứng từ, một số mục tin sẽ bắt buộc điền.
						|Không thể quay lại phiên bản cũ của chứng từ. 
						|Tiếp tục?';
						|ru = 'После изменения версии документа некоторые реквизиты будут обязательны для заполнения.
						|Вернуться к старой версии документа будет невозможно. 
						|Продолжить?';
						|en = 'Some attributes will become required after changing the document version.
						|Returning to the old version of the document will not be available.
						|Continue?'; fa = 'Some attributes will become required after changing the document version.
						|Returning to the old version of the document will not be available.
						|Continue?';
						|it = 'Dopo la modifica della versione del documento, alcuni attributi diventeranno obbligatori per la compilazione. 
						|Sarà impossibile tornare alla vecchia versione del documento,
						| continuare?';
						|pl = 'Po zmianie wersji dokumentu niektóre atrybuty będą obowiązkowe do wypełnienia.
						|Powrócić do starej wersji dokumentu będzie niemożliwe. 
						|Kontynuować?';
						|tr = 'Belge sürümünü değiştirdikten sonra bazı öznitelikler zorunlu olacaktır.
						|Belgenin eski sürümüne dönmek mümkün olmayacaktır.
						| Devam edilsin mi?'");
	CallbackDescription = New CallbackDescription("ChangeDocumentVersionCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ChangeDocumentVersionCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Modified = True;
		Object.DocumentVersion24 = False;
		ConfigureDependentFormElements("DocumentVersion24");
	EndIf;
	
EndProcedure

&AtClient
Procedure EnterLeaseTermCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined 
		Or TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;

	ConfigureDependentFormElements("LeaseStartDate,TermYears,TermMonths,TermDays");
	
EndProcedure

&AtClientAtServerNoContext
Function PresentValue(Object, ContractDetails_)

	LeaseItemsCost = LeasedAssetAccountingClientServer.LeaseItemsCost(
		Object, ContractDetails_, "FA");
	
	PresentValue = LeasedAssetAccountingClientServer.PresentValue(
									LeaseItemsCost, 
									Object.ServicePaymentSchedule, 
									Object.LeaseStartDate);
	Return PresentValue;
	
EndFunction

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	If Not ValueIsFilled(Object.Contract) Then
		RegisterImportApplications = False;
	Else
		RegisterImportApplications = Common.ObjectAttributeValue(Object.Contract, "RegisterImportApplications");
	EndIf;
	
	If ValueIsFilled(Object.Ref) And RegisterImportApplications Then
		FAAmount = Object.FA.Total("Cost");
		TextDocumentsBasedOn = VATAccountingLocalization.EventDocumentsOnPreliminaryDeliveries(Object, FAAmount);
		If ValueIsFilled(TextDocumentsBasedOn) Then
			Items.GroupDocumentsAboutUpcomingDelivery.Visible = True;
		Else
			Items.GroupDocumentsAboutUpcomingDelivery.Visible = False;
		EndIf;
	Else
		Items.GroupDocumentsAboutUpcomingDelivery.Visible = False;
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
	ElsIf Item.Name = "sh_ShamsiInput_DateOfFirstSecurityPayment" Then
		DateOfFirstSecurityPaymentOnChange(Items.DateOfFirstSecurityPayment);
	ElsIf Item.Name = "sh_ShamsiInput_DateOfFirstPayment" Then
		DateOfFirstPaymentOnChange(Items.DateOfFirstPayment);
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

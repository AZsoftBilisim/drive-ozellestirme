
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
	
	ItemsAndDimensionsSelectionParameters = Documents.DisposeIntangibleAssets2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AccountSettings_ = Documents.DisposeIntangibleAssets2_4.AccountingAccountSettings_();
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
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.DisposeIntangibleAssets2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AccountSettings_ = Documents.DisposeIntangibleAssets2_4.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, AccountSettings_);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
		
	Notify("Write_DisposeIntangibleAssets2_4", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
	If ValueIsFilled(Object.DocumentBasis) Then
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
	
	FillInInformationInBasement();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
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
	
	If EventName = "Write_DisposeIntangibleAssets2_4" 
		And Source <> Object.Ref Then
		FillInInformationInBasement();
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.IntangibleAssets.Form.ChoiceForm" Then
		If ValueSelected.Count() > 0 Then
			For Each ArrayElement In ValueSelected Do
				Object.IA.Add().IntangibleAsset = ArrayElement;
			EndDo;
		EndIf;
	EndIf;
	
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

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ItemOnChange_(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

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
Procedure ExpensesPostingMethodOnChange(Item)
	
	ChangedBankingDetails = "ExpensesPostingMethod,ExpenseItem,BusinessUnitAndLineOfBusinessMatchAccountingData,DimensionCorrespondsToIAToWriteOff";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpensesPostingMethod, 
		Object.ExpenseItem, 
		Object.DimensionOfExpenses, 
		Object.ExpensesBusinessUnit, 
		Object.ExpenseLineOfBusiness, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingData);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.DimensionCorrespondsToIAToWriteOff = False;
	EndIf;
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod= PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
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
Procedure DocumentInformationInAnotherAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure;
		FormParameters.Insert("Basis", Object.Ref);
		OpenForm("Document.DisposeIntangibleAssets2_4.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure PresentationOfRecordingInComplAccountingClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionCorrespondsToIAToWriteOffOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod");
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod,DimensionCorrespondsToIAToWriteOff");
	
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChange(Item)
	
	If Object.GeneratedDocument Then
		
		ListFilter = New Structure;
		ListFilter.Insert("Posted", True);
		
		If ValueIsFilled(Object.Organization) Then
			ListFilter.Insert("Organization", Object.Organization);
		EndIf;
		
		If ValueIsFilled(Object.Department) Then
			ListFilter.Insert("Department", Object.Department);
		EndIf;
		
		CallbackDescription = New CallbackDescription("GeneratedDocumentOnChangeCompletion", ThisObject);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", ListFilter);
		OpenForm("Document.IntangibleAssetsPhysicalCount.ChoiceForm", FormParameters,,,,, CallbackDescription);
		
	Else
		Object.DocumentBasis = Undefined;
	EndIf; 
	
EndProcedure

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

#Region FormTableItemsEventHandlersIA

&AtClient
Procedure IAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.IA, "IntangibleAsset", ValueSelected).Count() <> 0 Then
		WhenChangingIAOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure IAIntangibleAssetOnChange(Item)
	
	WhenChangingIAOnServer();

EndProcedure

&AtClient
Procedure IAOnChange(Item)

	WhenChangingIAOnServer();
	
EndProcedure

&AtClient
Procedure IAChargeAmountAccountingOnChange(Item)
	
	CurrentData = Items.IA.CurrentData;
	
	If CurrentData.AmountPermanentDifference = 0
		And CurrentData.AmountTemporaryDifference = 0
		And Object.RecordInTA Then
			
		CurrentData.AmountTaxAccounting = CurrentData.ChargeAmountAccounting;
	EndIf;
	
	CurrentData.AmountTemporaryDifference = CurrentData.ChargeAmountAccounting - CurrentData.AmountTaxAccounting - CurrentData.AmountPermanentDifference;

EndProcedure

&AtClient
Procedure IAAmountTaxAccountingOnChange(Item)
	
	CurrentData = Items.IA.CurrentData;
	CurrentData.AmountTemporaryDifference = CurrentData.ChargeAmountAccounting - CurrentData.AmountTaxAccounting - CurrentData.AmountPermanentDifference;

EndProcedure

&AtClient
Procedure IAAmountPermanentDifferenceOnChange(Item)
	
	CurrentData = Items.IA.CurrentData;
	CurrentData.AmountTemporaryDifference = CurrentData.ChargeAmountAccounting - CurrentData.AmountTaxAccounting - CurrentData.AmountPermanentDifference;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure Pick(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.IAIntangibleAsset, ThisObject);
	OpenForm(
		"Catalog.IntangibleAssets.ChoiceForm",
		PickingParameters,
		Items.IA,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ShowPD(Command)
	
	Items.IAShowPD.Check = Not Items.IAShowPD.Check;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Command.Name);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

#Region AttachableCommands

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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

#EndRegion

#EndRegion

#Region Private

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
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
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
	PresentationOfDetails = FormServiceParameters.PresentationOfDetails; // Map
	Items.IAAmountManagementAccounting.Title = PresentationOfDetails.Get("IA.AmountManagementAccounting");
	Items.IAChargeAmountAccounting.Title = PresentationOfDetails.Get("IA.ChargeAmountAccounting");
	Items.IAAmountTaxAccounting.Title = PresentationOfDetails.Get("IA.AmountTaxAccounting");
	Items.IAAmountPermanentDifference.Title = PresentationOfDetails.Get("IA.AmountPermanentDifference");
	Items.IAAmountTemporaryDifference.Title = PresentationOfDetails.Get("IA.AmountTemporaryDifference");
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	NewServiceParametersOfForm.Insert("ComplCurrency", ComplCurrency);
	NewServiceParametersOfForm.Insert("PresentationOfDetails", Documents.DisposeIntangibleAssets2_4.PresentationOfDetails(Object.Organization, Object.Date));
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails = "")
	
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
	NonCurrentAssetsClientServerLocalization.AddAuxiliaryDetails_WriteOffOfIa(Form, AuxiliaryAttributes);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesForDependentDetails_WriteOffIA(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "IA");
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
		
		Items.IAAmountManagementAccounting.Title = PresentationOfDetails.Get("IA.AmountManagementAccounting");
		Items.IAChargeAmountAccounting.Title = PresentationOfDetails.Get("IA.ChargeAmountAccounting");
		Items.IAAmountTaxAccounting.Title = PresentationOfDetails.Get("IA.AmountTaxAccounting");
		Items.IAAmountPermanentDifference.Title = PresentationOfDetails.Get("IA.AmountPermanentDifference");
		Items.IAAmountTemporaryDifference.Title = PresentationOfDetails.Get("IA.AmountTemporaryDifference");
		
	EndIf;

	If StructureOfChangedProps.Property("ExpensesPostingMethod") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpensesPostingMethod, 
			Form,
			"ExpenseItem,DimensionOfExpenses,ExpensesBusinessUnit,ExpenseLineOfBusiness,BusinessUnitAndLineOfBusinessMatchAccountingData,DimensionCorrespondsToIAToWriteOff");
	
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
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"PresentationOfDetails",
			Documents.DisposeIntangibleAssets2_4.PresentationOfDetails(Object.Organization, Object.Date),
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrency",
			ComplCurrency,
			FormServiceParameters);
		
	EndIf;
	
	DisposeIntangibleAssetsLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
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
Procedure WhenChangingIAOnServer()
	
	FillInHeaderForSelectedIA();
	FillInInformationInBasement();
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedIA()

	ChangedBankingDetails = "IntangibleAsset";

	NonCurrentAssetsInternal.FillInHeaderForSelectedIA(
		"Organization,Department", Object.IA, Object, ChangedBankingDetails);
		
	If Not ValueIsFilled(Object.ExpensesPostingMethod) Then
		
		Object.ExpensesPostingMethod = NonCurrentAssetsInternal.WayToReflectIAExpenses(
			Object,
			NonCurrentAssetsInternal.FirstFilledValueInTable(Object.IA, "IntangibleAsset"));
		
		If ValueIsFilled(Object.ExpensesPostingMethod) Then
			
			NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
				Object.ExpensesPostingMethod, 
				Object.ExpenseItem, 
				Object.DimensionOfExpenses, 
				Object.ExpensesBusinessUnit, 
				Object.ExpenseLineOfBusiness, 
				Object.BusinessUnitAndLineOfBusinessMatchAccountingData);
				
			IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);
			
			Object.DimensionCorrespondsToIAToWriteOff = False;
			
			ChangedBankingDetails = ChangedBankingDetails + "," + "ExpensesPostingMethod,DimensionCorrespondsToFAToWriteOff,BusinessUnitAndLineOfBusinessMatchAccountingData";
			
		EndIf;
		
	EndIf;
		
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()

	FillInInformationInBasement();
	
	ConfigureDependentFormElementsOnServer("Date");
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChangeCompletion(ClosingResult, AdditionalParameters) Export

	If ValueIsFilled(ClosingResult) Then
		Object.DocumentBasis = ClosingResult;
	Else
		Object.GeneratedDocument = False;
	EndIf;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		CallbackDescription = New CallbackDescription("FillInAccordingToBaseEnd", ThisObject);
		QueryText = NStr("vi = 'Điền chứng từ theo kiểm kê?';
						|ru = 'Заполнить документ по инвентаризации?';
						|en = 'Fill in the physical inventory count document?'; fa = 'Fill in the physical inventory count document?';
						|it = 'Fill in the physical inventory count document?';
						|pl = 'Fill in the physical inventory count document?';
						|tr = 'Belge stok sayımına göre doldurulsun mu?'");
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

	Object.IA.Clear();

	Documents.DisposeIntangibleAssets2_4.FillInBasedOnInventory(Object, True);
	
	ConfigureDependentFormElementsOnServer("BusinessOperation,RecordInLocalAccounting,RecordInManAccounting,PostInAccounting,RecordInTA");
	
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

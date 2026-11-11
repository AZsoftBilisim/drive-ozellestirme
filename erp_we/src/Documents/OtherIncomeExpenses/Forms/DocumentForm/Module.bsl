#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Control of document creation in a subordinate RIB node with filters
	DataExchangeTMERP.ControlOfCreationOfDocumentsInDistributedInformationSecurity(Object, Cancel);
	
	If ValueIsFilled(Parameters.Basis) And TypeOf(Parameters.Basis) = Type("Structure")
		And Parameters.Basis.Property("BusinessOperation") Then
		Object.BusinessOperation = Parameters.Basis.BusinessOperation;
	EndIf;
	
	FillInHeaderDetails();
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	FactorOfConversionToCurrencyOfRegul = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		?(ValueIsFilled(Object.Currency), Object.Currency, ManagementAccountingCurrency),
		LocalAccountingCurrency,
		Object.Date);
		
	UseAccountingOfOtherIncomeExpensesInLocalAccounting = GetFunctionalOption("UseAccountingOfOtherIncomeExpensesInLocalAccounting");
	Items.DecorationExpensesAmountsRegl.Visible = UseAccountingOfOtherIncomeExpensesInLocalAccounting;
	Items.DecorationRevenueAmountsRegl.Visible = UseAccountingOfOtherIncomeExpensesInLocalAccounting;
	
	FormControlServer();
	SetupParameters = Documents.OtherIncomeExpenses.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	ItemsAndDimensionsSelectionParameters = Documents.OtherIncomeExpenses.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInDetailsInTablePart_();
	RecalculateAmountsTA();
	RefreshFormTitle();
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties

	CalculateTotals_();
	ManagingFormElementsOnClient();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	SetupParameters = Documents.OtherIncomeExpenses.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	ItemsAndDimensionsSelectionParameters = Documents.OtherIncomeExpenses.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If TheseAreExpenses Then
		Object.OtherIncome.Clear();
	Else
		Object.OtherExpenses.Clear();
	EndIf;
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// The "Main" tab

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	TheseAreExpenses = TheseAreExpenses();
		
	If TheseAreExpenses
		And Object.OtherExpenses.Count() = 0 Then
		NewRow = Object.OtherExpenses.Add();
		NewRow.EnteredInTaxAccounting = True;
		Items.OtherExpenses.CurrentRow = NewRow.GetID();
	ElsIf Not TheseAreExpenses
		And Object.OtherIncome.Count() = 0 Then
		NewRow = Object.OtherIncome.Add();
		Items.OtherIncome.CurrentRow = NewRow.GetID();
	EndIf;
	
	BusinessOperationWhenChangingOnServer();
	ManagingFormElementsOnClient();
	
EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	If Not ValueIsFilled(Object.BusinessOperation) Then
		Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
	EndIf; 
	
	If Object.BusinessOperation = Enums.BusinessTransactions.WriteOffOtherExpenses 
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReversalOfOtherExpenses
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReversalOfOtherIncome Then
		Object.Currency = ManagementAccountingCurrency;
		CurrencyWhenChangedOnServer(False);
	EndIf;
	SetupParameters = Documents.OtherIncomeExpenses.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	ItemsAndDimensionsSelectionParameters = Documents.OtherIncomeExpenses.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormControlServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	CalculateTotals_();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	FactorOfConversionToCurrencyOfRegul = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		?(ValueIsFilled(Object.Currency), Object.Currency, ManagementAccountingCurrency),
		LocalAccountingCurrency,
		Object.Date);
		
	For Each TableRow In Object.OtherExpenses Do
		TableRow.SumCompl = TableRow.Sum * FactorOfConversionToCurrencyOfRegul;
		
		If TableRow.EnteredInTaxAccounting Then
			TableRow.CostTD = TableRow.SumCompl - TableRow.AmountFA - TableRow.PermanentDifference;
		Else
			TableRow.CostTD = 0;
			TableRow.PermanentDifference = TableRow.SumCompl - TableRow.AmountFA - TableRow.CostTD;
		EndIf;
	EndDo;
	
	RecordsAreKeptAccordingToAIT = RecordsAreKeptAccordingToAIT(Object.Date, Object.Organization);
	For Each TableRow In Object.OtherExpenses Do
		TableRow.SumCompl = TableRow.Sum * FactorOfConversionToCurrencyOfRegul;
		TableRow.AmountFA = TableRow.SumCompl - TableRow.PermanentDifference - TableRow.CostTD;
		TableRow.AITAmount = ?(RecordsAreKeptAccordingToAIT, TableRow.AmountFA, 0);
	EndDo;
	
	FormControlServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	TSName = ?(TheseAreExpenses,"OtherExpenses","OtherIncome");
	For Each TSRow In Object[TSName] Do
		If TSRow.DateRecord = CacheData Then
			TSRow.DateRecord = Object.Date;
		EndIf;
	EndDo;
	CacheData = BegOfDay(Object.Date);
	FormControlServer();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	CurrencyWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure CurrencyWhenChangedOnServer(UpdateForm=True)
	
	FactorOfConversionToCurrencyOfRegul = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		Object.Currency, LocalAccountingCurrency, Object.Date);
	
	If Object.Currency = LocalAccountingCurrency Then
		For Each String In Object.OtherIncome Do
			String.Sum = String.SumCompl;
		EndDo;
		For Each String In Object.OtherExpenses Do
			If String.Sum = 0 Then
				Multiplier = 1;
			Else
				Multiplier = (String.AmountExcludingVAT / String.Sum);
			EndIf;
			String.Sum = String.SumCompl;
			String.AmountExcludingVAT = String.SumCompl * Multiplier;
		EndDo;
	Else
		
		ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			Currency, Object.Currency, Object.Date);
		For Each String In Object.OtherIncome Do
			String.Sum = String.Sum * ConversionFactor_;
		EndDo;
		For Each String In Object.OtherExpenses Do
			String.Sum = String.Sum * ConversionFactor_;
			String.AmountExcludingVAT = String.AmountExcludingVAT * ConversionFactor_;
		EndDo;
		
	EndIf;
	Currency = Object.Currency;
	
	If UpdateForm Then
		FormControlServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "GroupAdditionalAttributes"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

// Tab "Expenses"

&AtClient
Procedure DecryptionSwitchExpensesOnChange(Item)
	WhenChangingDecryptionSwitchCosts(DecryptionSwitchExpenses);
EndProcedure

&AtClient
Procedure DecryptionSwitchExpensesCorPartOnChange(Item)
	WhenChangingDecryptionSwitchCosts(DecryptionSwitchExpensesCorPart);
EndProcedure

// Tab "Expenses". Expenses "Without splitting", assets/liabilities "Without splitting".

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisForm, Item);
	FillInDetailsInTablePart_(Items.OtherExpenses.CurrentRow);
	OtherExpensesSumComplOnChange(Item);
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisForm, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpensesAssetAndLiabilityItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisForm, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesAssetsLiabilitiesDimensionOnChange(Item)
	IncomeAndExpensesClientServer.AssetsLiabilitiesDimensionOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpensesPresentationOfRecordingInComplAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return; // The UT handler is empty
EndProcedure

&AtClient
Procedure CorExpenditureDimensionOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
EndProcedure

// Tab "Expenses". Expenses "Without splitting"

&AtClient
Procedure TheCostOfTheUnitWithoutBreakingOnChange(Item)
	TSName = "OtherExpenses";
	AttributeName = "Department";
	FillInDetailsInTablePart(TSName, AttributeName, Items[TSName].CurrentData[AttributeName]);
EndProcedure

&AtClient
Procedure ExpensesBusinessLineWithoutDivisionOnChange(Item)
	TSName = "OtherExpenses";
	AttributeName = "LineOfBusiness";
	FillInDetailsInTablePart(TSName, AttributeName, Items[TSName].CurrentData[AttributeName]);
EndProcedure

&AtClient
Procedure ItemOfExpenditureWithoutDivisionOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisForm, Item);
	FillInDetailsInTablePart_(Items.OtherExpenses.CurrentRow);
	OtherExpensesSumComplOnChange(Item);
EndProcedure

&AtClient
Procedure CostAnalysisWithoutSplittingOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisForm, Item);
EndProcedure

// Tab "Expenses". Assets/liabilities "Without splitting"

&AtClient
Procedure ExpensesOfTheCorDivisionWithoutSplittingOnChange(Item)
	TSName = "OtherExpenses";
	AttributeName = "DebitBusinessUnit";
	FillInDetailsInTablePart(TSName, AttributeName, Items[TSName].CurrentData[AttributeName]);
EndProcedure

&AtClient
Procedure ExpensesCorBusinessLineWithoutSplittingOnChange(Item)
	TSName = "OtherExpenses";
	AttributeName = "CorLineOfBusiness";
	FillInDetailsInTablePart(TSName, AttributeName, Items[TSName].CurrentData[AttributeName]);
EndProcedure

&AtClient
Procedure ItemOfExpenditureWithoutDivisionStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisForm, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesItemOfAssetsLiabilitiesWithoutDivisionOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item, Items.OtherExpenses.CurrentRow);
EndProcedure

&AtClient
Procedure ExpensesItemOfAssetsLiabilitiesWithoutDivisionStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisForm, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesAnalysisOfAssetsLiabilitiesWithoutSplittingOnChange(Item)
	IncomeAndExpensesClientServer.AssetsLiabilitiesDimensionOnChange(ThisForm, Item);
EndProcedure

&AtClient
Procedure ExpensesRepresentationOfTheReflectionInTheReglAccountingWithoutSplittingClick(Item, StandardProcessing)
	
	NotificationParameters = New Structure("TSName", "OtherExpenses");
	CallbackDescription = New CallbackDescription("RepresentationOfReflectionInLocalAccountingWithoutSplittingAfterClicking", ThisObject, NotificationParameters);
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing, CallbackDescription);
	
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure CorItemOfExpenditureWithoutDivisionOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisForm, Item);
	RecalculateAITAmount();
EndProcedure

&AtClient
Procedure CorItemOfExpenditureWithoutDivisionStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisForm, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure CorCostAnalysisWithoutSplittingOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisForm, Item);
EndProcedure

// The "Income" tab

&AtClient
Procedure DecryptionSwitchIncomeOnChange(Item)
	WhenDecryptionSwitchIsChangedIncome(DecryptionSwitchIncome);
EndProcedure

&AtClient
Procedure DecryptionSwitchIncomeCorPartOnChange(Item)
	WhenDecryptionSwitchIsChangedIncome(DecryptionSwitchIncomeCorPart);
EndProcedure

// The "Income" tab. Income "Without splitting", assets/liabilities "Without splitting"

&AtClient
Procedure DimensionOfRevenueOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfRevenueOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure IncomeAssetLiabilityAnalysisOnChange(Item)
	IncomeAndExpensesClientServer.AssetsLiabilitiesDimensionOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure IncomeRepresentationOfTheReflectionInTheReglAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisForm, Item, StandardProcessing);
	Return; // The UT handler is empty
EndProcedure

&AtClient
Procedure CorIncomeDimensionOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfRevenueOnChange(ThisForm, Item);
EndProcedure

// The "Income" tab. Income "Without splitting"

&AtClient
Procedure RevenueDivisionWithoutDivisionOnChange(Item)
	TSName = "OtherIncome";
	AttributeName = "Department";
	FillInDetailsInTablePart(TSName, AttributeName, Items[TSName].CurrentData[AttributeName]);
EndProcedure

&AtClient
Procedure IncomeLineOfBusinessWithoutDivisionOnChange(Item)
	TSName = "OtherIncome";
	AttributeName = "LineOfBusiness";
	FillInDetailsInTablePart(TSName, AttributeName, Items[TSName].CurrentData[AttributeName]);
EndProcedure

&AtClient
Procedure IncomeItemWithoutDivisionOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisForm, Item);
	FillInDetailsInTablePart_(Items.OtherIncome.CurrentRow);
	OtherIncomeSumComplOnChange(Item);
EndProcedure

&AtClient
Procedure RevenueAnalyticsWithoutPartitioningOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfRevenueOnChange(ThisForm, Item);
EndProcedure

// The "Income" tab. Assets/liabilities "Without splitting"

&AtClient
Procedure IncomeCorDivisionWithoutDivisionOnChange(Item)
	TSName = "OtherIncome";
	AttributeName = "DebitBusinessUnit";
	FillInDetailsInTablePart(TSName, AttributeName, Items[TSName].CurrentData[AttributeName]);
EndProcedure

&AtClient
Procedure IncomeCorLineOfBusinessWithoutDivisionOnChange(Item)
	TSName = "OtherIncome";
	AttributeName = "CorLineOfBusiness";
	FillInDetailsInTablePart(TSName, AttributeName, Items[TSName].CurrentData[AttributeName]);
EndProcedure

&AtClient
Procedure IncomeItemOfAssetsLiabilitiesWithoutDivisionOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisForm, Item);
EndProcedure

&AtClient
Procedure IncomeAnalysisOfAssetsLiabilitiesWithoutSplittingOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisForm, Item);
EndProcedure

&AtClient
Procedure RevenueRepresentationOfTheReflectionInTheReglAccountingWithoutSplittingClick(Item, StandardProcessing)
	
	NotificationParameters = New Structure("TSName", "OtherIncome");
	CallbackDescription = New CallbackDescription("RepresentationOfReflectionInLocalAccountingWithoutSplittingAfterClicking", ThisObject, NotificationParameters);
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing, CallbackDescription);
	
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure CorIncomeItemWithoutDivisionOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisForm, Item);
EndProcedure

&AtClient
Procedure CorIncomeItemWithoutDivisionStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisForm, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure CorRevenueAnalyticsWithoutPartitioningOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfRevenueOnChange(ThisForm, Item);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOtherExpenses

&AtClient
Procedure OtherExpensesSelection(Item, RowSelected, Field, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure OtherExpensesOnChange(Item)

	CalculateTotals_();

EndProcedure

&AtClient
Procedure OtherExpensesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	CurrentTableRow = Items.OtherExpenses.CurrentRow;
EndProcedure

&AtClient
Procedure OtherExpensesOnStartEdit(Item, NewRow, Copy)
	
	AtBeginningOfEditingTS(Item.Name, NewRow, Copy);
	If NewRow Then
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, Item.CurrentData, "Object.OtherExpenses");
	EndIf;
	
	//Setting up accounting accounts 
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
EndProcedure

&AtClient
Procedure OtherExpensesExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	FillInDetailsInTablePart_(Items.OtherExpenses.CurrentRow);
	OtherExpensesSumComplOnChange(Item);
EndProcedure

&AtClient
Procedure OtherExpensesCorExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	SetExpenseSuggestions();
	RecalculateAITAmount();
EndProcedure

&AtClient
Procedure OtherExpensesCorExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesAssetAndLiabilityItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure OtherExpensesAssetAndLiabilityItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesCorExpenditureDimensionStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	DimensionOfExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesCorExpenditureDimensionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	DimensionOfExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesCorExpenditureDimensionAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesCorExpenditureDimensionTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesSumOnChange(Item)
	
	CurrentData = Items.OtherExpenses.CurrentData;
	If ValueIsFilled(CurrentData.Sum) Then
		CurrentData.AmountExcludingVAT = CurrentData.Sum;
		CurrentData.SumMan = CurrentData.Sum;
		CurrentData.SumCompl = CurrentData.Sum * FactorOfConversionToCurrencyOfRegul;
		OtherExpensesSumComplOnChange(Item);
		CalculateTotals_();
	EndIf;
	
EndProcedure

&AtClient
Procedure OtherExpensesSumComplOnChange(Item)
	TableRow = Items.OtherExpenses.CurrentData;
	If TableRow.EnteredInTaxAccounting Then
		TableRow.AmountFA = TableRow.SumCompl;
		TableRow.PermanentDifference = 0;
		TableRow.CostTD = 0;
	Else
		TableRow.AmountFA = 0;
		TableRow.PermanentDifference = TableRow.SumCompl;
		TableRow.CostTD = 0;
	EndIf;
	RecalculateAITAmount();
EndProcedure

&AtClient
Procedure OtherExpensesAmountFAOnChange(Item)
	TableRow = Items.OtherExpenses.CurrentData;
	TableRow.CostTD = TableRow.SumCompl - TableRow.AmountFA - TableRow.PermanentDifference;
	RecalculateAITAmount();
EndProcedure

&AtClient
Procedure OtherExpensesPermanentDifferenceOnChange(Item)
	TableRow = Items.OtherExpenses.CurrentData;
	TableRow.CostTD = TableRow.SumCompl - TableRow.AmountFA - TableRow.PermanentDifference;
	RecalculateAITAmount();
EndProcedure

&AtClient
Procedure OtherExpensesAmountOfAITOnChange(Item)
	RecalculateAITAmount(True);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOtherIncome

&AtClient
Procedure OtherIncomeOnChange(Item)

	CalculateTotals_();

EndProcedure

&AtClient
Procedure OtherIncomeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	CurrentTableRow = Items.OtherIncome.CurrentRow;
EndProcedure

&AtClient
Procedure OtherIncomeOnStartEdit(Item, NewRow, Copy)
	
	AtBeginningOfEditingTS(Item.Name, NewRow, Copy);
	If NewRow Then
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, Item.CurrentData, "Object.OtherIncome");
	EndIf;
	
	//Setting up accounting accounts 
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
EndProcedure

&AtClient
Procedure OtherIncomeIncomeItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	FillInDetailsInTablePart_(Items.OtherIncome.CurrentRow);
	OtherIncomeSumComplOnChange(Item);
EndProcedure

&AtClient
Procedure OtherIncomeIncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherIncomeCorIncomeItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure OtherIncomeCorIncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherIncomeAssetAndLiabilityItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure OtherIncomeAssetAndLiabilityItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherIncomeSelection(Item, RowSelected, Field, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure OtherIncomeSumOnChange(Item)
	SumOnChange(Item, "OtherIncome");
EndProcedure

&AtClient
Procedure OtherIncomeSumComplOnChange(Item)
	LocalAmountOnChange(Item, "OtherIncome");
EndProcedure

&AtClient
Procedure OtherIncomeAmountFAOnChange(Item)
	AmountIsTAOnChange(Item, "OtherIncome");
EndProcedure

&AtClient
Procedure OtherIncomePermanentDifferenceOnChange(Item)
	PermanentDifferenceOnChange(Item, "OtherIncome");
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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
Procedure SelectOtherExpenses_2(Command)
	
	DescriptionOfTheAlert = New CallbackDescription("SelectionProcessing", ThisObject);
	
	PickingParameters = New Structure;
	PickingParameters.Insert("DocumentRef", Object.Ref);
	PickingParameters.Insert("Organization",	Object.Organization);
	PickingParameters.Insert("Date",			Object.Date);
	
	OpenForm("Document.OtherIncomeExpenses.Form.FormOfSelectionOfOtherExpenses",
					PickingParameters, ThisForm, , , , DescriptionOfTheAlert);
	
EndProcedure

&AtClient
Procedure FillInExpenseItem(Command)
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject, Items.OtherExpensesExpenseItem, Items.OtherExpenses.SelectedRows);
	
EndProcedure

&AtClient
Procedure FillInTheIncomeItem(Command)
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject, Items.OtherIncomeIncomeItem, Items.OtherIncome.SelectedRows);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInTheAssetsLiabilitiesItem(Command)
	
	CurrentTableName = ?(TheseAreExpenses, "OtherExpenses", "OtherIncome");
	
	If CurrentTableName = "OtherExpenses" Then
		ItemNameItemAssetsLiabilities = "OtherExpensesAssetAndLiabilityItem";
	Else
		ItemNameItemAssetsLiabilities = "OtherIncomeAssetAndLiabilityItem";
	EndIf;
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject, Items[ItemNameItemAssetsLiabilities], Items[CurrentTableName].SelectedRows);
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure
// StandardSubsystems.Properties 

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);

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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure


&AtClient
Procedure DisplayPDATDAmounts(Command)
		
	WithdrawAmountOfDifferencesForProfitTaxPayer = Not WithdrawAmountOfDifferencesForProfitTaxPayer;
	FormControlServer();
	Items.FormDisplayPDATDAmounts.Check = WithdrawAmountOfDifferencesForProfitTaxPayer;
	
	Return; // The UT handler is empty
	
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
Procedure OnReadCreateAtServer()
	
	FillInListOfOperations();
	Currency = Object.Currency;
	
	If Parameters.Property("CopyingValue") And ValueIsFilled(Parameters.CopyingValue) Then
		TMCommonUseClientServer.FillInCollectionPropertyValues(Object.OtherIncome, Undefined, "DateRecord");
		TMCommonUseClientServer.FillInCollectionPropertyValues(Object.OtherExpenses, Undefined, "DateRecord");
	EndIf;
	
	FillInDetailsInTablePart_();
	RecalculateAmountsTA();
	
	CacheData = BegOfDay(Object.Date);
	If Not ValueIsFilled(CacheData) Then
		CacheData = BegOfDay(CurrentSessionDate());
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInListOfOperations()
	
	Items.BusinessOperation.ChoiceList.Clear();
	TransactionList = Documents.OtherIncomeExpenses.TransactionList();
	For Each CollectionItem In TransactionList Do
		If Not GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets")
		 And CollectionItem.Value = Enums.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices Then
			Continue;
		EndIf;
		Items.BusinessOperation.ChoiceList.Add(CollectionItem.Value, CollectionItem.Presentation);
	EndDo;
	
EndProcedure

&AtServer
Procedure RecalculateAmountsTA()
	
	For Each String In Object.OtherExpenses Do
		String.AmountFA = String.SumCompl - String.PermanentDifference - String.CostTD;
	EndDo;
	
	For Each String In Object.OtherIncome Do
		String.AmountFA = String.SumCompl - String.PermanentDifference - String.CostTD;
	EndDo;
	
EndProcedure

//AtServer
Function TheseAreRevenues()

	BusinessTransactionsIncome = New Array();
	BusinessTransactionsIncome.Add(PredefinedValue("Enum.BusinessTransactions.OtherIncome"));
	BusinessTransactionsIncome.Add(PredefinedValue("Enum.BusinessTransactions.ReversalOfOtherIncome"));
	BusinessTransactionsIncome.Add(PredefinedValue("Enum.BusinessTransactions.IncomeReclassification"));
	
	Return BusinessTransactionsIncome.Find(Object.BusinessOperation) <> Undefined

EndFunction

//AtServer
Function TheseAreExpenses()

	Return Not TheseAreRevenues()

EndFunction

//AtServer
Function GetSourceOfSettingsTA()
	
	WriteOffOtherExpenses = PredefinedValue("Enum.BusinessTransactions.WriteOffOtherExpenses");
	ExpenseReclassification = PredefinedValue("Enum.BusinessTransactions.ExpenseReclassification");
	TransferOfOtherExpensesBetweenBranchOffices = PredefinedValue("Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices");
	IncomeReclassification = PredefinedValue("Enum.BusinessTransactions.IncomeReclassification");

	SourcesOfSettingsTA = New Map();
	SourcesOfSettingsTA.Insert(WriteOffOtherExpenses, "ExpenseItem");
	SourcesOfSettingsTA.Insert(ExpenseReclassification, "CorExpenseItem");
	SourcesOfSettingsTA.Insert(TransferOfOtherExpensesBetweenBranchOffices, "ExpenseItem");
	SourcesOfSettingsTA.Insert(IncomeReclassification, "IncomeItem");
	
	Return SourcesOfSettingsTA.Get(Object.BusinessOperation)
	
EndFunction

&AtServer
Procedure FillInDetailsInTablePart_(RowID = Undefined)
	
	SourceOfSettingsTA = GetSourceOfSettingsTA();
	
	If TheseAreExpenses Then
		
		DetailsOfExpenditureItem = New Structure;
		DetailsOfExpenditureItem.Insert("DimensionOfExpensesRequired_","ControlDimensionFilling");
		DetailsOfExpenditureItem.Insert("DimensionOfExpensesOrderImplementation","DimensionOfExpensesOrderImplementation");
		DetailsOfExpenditureItem.Insert("CostAllocationOptionManag");
		DetailsOfExpenditureItem.Insert("CostAllocationOptionLocal");
		
		DetailsCorItemsOfExpenditure = New Structure;
		DetailsCorItemsOfExpenditure.Insert("CorExpenditureDimensionRequired_","ControlDimensionFilling");
		DetailsCorItemsOfExpenditure.Insert("CorExpenditureDimensionOrderImplementation","DimensionOfExpensesOrderImplementation");
		
		If SourceOfSettingsTA = "ExpenseItem" Then
			DetailsOfExpenditureItem.Insert("EnteredInTaxAccounting");
		ElsIf SourceOfSettingsTA = "CorExpenseItem" Then
			DetailsCorItemsOfExpenditure.Insert("EnteredInTaxAccounting");
		Else
			DetailsOfExpenditureItem.Insert("EnteredInTaxAccounting", "TRUE");
		EndIf;
		
		TSArticles = New Structure("ExpenseItem,CorExpenseItem", DetailsOfExpenditureItem, DetailsCorItemsOfExpenditure);
		
	Else
		
		AttributesOfIncomeItem = New Structure;

		If SourceOfSettingsTA = "IncomeItem" Then
			AttributesOfIncomeItem.Insert("EnteredInTaxAccounting") 
		Else
			AttributesOfIncomeItem.Insert("EnteredInTaxAccounting", "TRUE");
		EndIf;
		
		TSArticles = New Structure("IncomeItem", AttributesOfIncomeItem);
		
	EndIf;
	
	FillInDependentDetailsOfTS(
		?(TheseAreExpenses, Object.OtherExpenses, Object.OtherIncome),
		TSArticles, 
		RowID);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
	// Conditional design for the field "Analytics of expenses".
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DimensionOfExpenses.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesDimensionOfExpenses.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAnalysisWithoutSplitting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.DimensionOfExpensesRequired_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DimensionOfExpenses.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesDimensionOfExpenses.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostAnalysisWithoutSplitting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.DimensionOfExpensesRequired_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.DimensionOfExpenses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Conditional registration for the field "KorAnalitikrAskhodov".
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorExpenditureDimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesCorExpenditureDimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorCostAnalysisWithoutSplitting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.CorExpenditureDimensionRequired_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorExpenditureDimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesCorExpenditureDimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorCostAnalysisWithoutSplitting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.CorExpenditureDimensionRequired_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.CorExpenditureDimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Conditional design for the "Revenue Analytics" field.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DimensionOfRevenue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherIncomeDimensionOfRevenue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RevenueAnalyticsWithoutPartitioning.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherIncome.DimensionOfRevenueRequired_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DimensionOfRevenue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherIncomeDimensionOfRevenue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RevenueAnalyticsWithoutPartitioning.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherIncome.DimensionOfRevenueRequired_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherIncome.DimensionOfRevenue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Conditional registration for the "KorAnalitikaDohodov" field.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorIncomeDimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherIncomeCorIncomeDimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorRevenueAnalyticsWithoutPartitioning.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherIncome.CorIncomeDimensionRequired_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorIncomeDimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherIncomeCorIncomeDimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorRevenueAnalyticsWithoutPartitioning.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherIncome.CorIncomeDimensionRequired_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherIncome.CorIncomeDimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
		
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesPresentationOfRecordingInComplAccounting.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherIncomePresentationOfRecordingInComplAccounting.Name);
	
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.HyperlinkColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherIncomePresentationOfRecordingInComplAccounting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherIncome.PresentationOfRecordingInComplAccounting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text",  NStr("vi = 'Tùy chỉnh';
													|ru = 'Настроить';
													|en = 'Customize'; fa = 'سفارشی‌سازی';
													|it = 'Impostare';
													|pl = 'Ustaw';
													|tr = 'Ayarla'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesPresentationOfRecordingInComplAccounting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.PresentationOfRecordingInComplAccounting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text",  NStr("vi = 'Tùy chỉnh';
													|ru = 'Настроить';
													|en = 'Customize'; fa = 'سفارشی‌سازی';
													|it = 'Impostare';
													|pl = 'Ustaw';
													|tr = 'Ayarla'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesDebitBusinessUnit.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.DebitBusinessUnit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	If UseBusinessUnits Then
		Item.Appearance.SetParameterValue("Text",  NStr("vi = '<Bộ phận phù hợp>';
														|ru = '<Совпадает с подразделением>';
														|en = '<Matches the business unit>'; fa = '<با واحد تجاری مطابقت دارد>';
														|it = '<Coincide al reparto>';
														|pl = '<Zgodny z działem>';
														|tr = '<Departmanla eşleşiyor>'"));
		Item.Appearance.SetParameterValue("TextColor",  StyleColors.EntryHelpTextColor);
	Else
		Item.Appearance.SetParameterValue("Visible",  False);
	EndIf;
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherIncomeDebitBusinessUnit.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherIncome.DebitBusinessUnit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	If UseBusinessUnits Then
		Item.Appearance.SetParameterValue("Text",  NStr("vi = '<Bộ phận phù hợp>';
														|ru = '<Совпадает с подразделением>';
														|en = '<Matches the business unit>'; fa = '<با واحد تجاری مطابقت دارد>';
														|it = '<Coincide al reparto>';
														|pl = '<Zgodny z działem>';
														|tr = '<Departmanla eşleşiyor>'"));
		Item.Appearance.SetParameterValue("TextColor",  StyleColors.EntryHelpTextColor);
	Else
		Item.Appearance.SetParameterValue("Visible",  False);
	EndIf;
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesCorExpenseItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.CorExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices;
	
	Item.Appearance.SetParameterValue("Text",					NStr("vi = '<Dạng chi phí phù hợp>';
																		|ru = '<Совпадает со статьей расходов>';
																		|en = '<Matches the expense item>'; fa = '<Matches the expense item>';
																		|it = '<Coincide alla voce di spese>';
																		|pl = '<Zgodny z pozycją wydatków>';
																		|tr = '<Gider kalemleriyle eşleşiyor>'"));
	Item.Appearance.SetParameterValue("TextColor",			StyleColors.EntryHelpTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesCorExpenditureDimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorExpenditureDimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorCostAnalysisWithoutSplitting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.CorExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.CorExpenditureDimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices;
	
	Item.Appearance.SetParameterValue("MarkIncomplete",	False);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TableRow = Items.OtherExpenses.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		FillPropertyValues(TableRow, ValueSelected);
		StandardProcessing = False;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateTotals_()
	
	TotalAmount_4 = Object.OtherExpenses.Total("Sum") + Object.OtherIncome.Total("Sum");
	
EndProcedure

&AtClient
Procedure AtBeginningOfEditingTS(TSName, NewRow, Copy)
	
	TableRow = Items[TSName].CurrentData;
	If NewRow And Not Copy Then
		If TSName = "OtherIncome" Then
			If DecryptionSwitchIncome = 0 Then
				InitialString = Items[TSName].RowData(CurrentTableRow);
				If InitialString <> Undefined Then
					FillPropertyValues(TableRow, InitialString,
						"Department, LineOfBusiness, IncomeItem, DimensionOfRevenue,
						|DimensionOfRevenueRequired_, EnteredInTaxAccounting");
				EndIf;
			EndIf;
			If DecryptionSwitchIncomeCorPart = 0 Then
				InitialString = Items[TSName].RowData(CurrentTableRow);
				If InitialString <> Undefined Then
					FillPropertyValues(TableRow, InitialString,
						"DebitBusinessUnit, CorLineOfBusiness, AssetAndLiabilityItem, AssetsLiabilitiesDimension,
						|AssetsLiabilitiesDimensionNotUsed,
						|CorIncomeItem, CorIncomeDimension, CorIncomeDimensionRequired_,
						|GLAccountSettings, PresentationOfRecordingInComplAccounting");
						GLAccountSettingsClient.WhenCopyingString(ThisObject, Items[TSName]);
				EndIf;
			EndIf;
		EndIf;
		If TSName = "OtherExpenses" Then
			If DecryptionSwitchExpenses = 0 Then
				InitialString = Items[TSName].RowData(CurrentTableRow);
				If InitialString <> Undefined Then
					FillPropertyValues(TableRow, InitialString,
						"Department, LineOfBusiness, ExpenseItem, DimensionOfExpenses,
						|DimensionOfExpensesRequired_, DimensionOfExpensesOrderImplementation,
						|CostAllocationOptionManag, CostAllocationOptionLocal, EnteredInTaxAccounting");
				EndIf;
			EndIf;
			If DecryptionSwitchExpensesCorPart = 0 Then
				InitialString = Items[TSName].RowData(CurrentTableRow);
				If InitialString <> Undefined Then
					FillPropertyValues(TableRow, InitialString,
						"DebitBusinessUnit, CorLineOfBusiness, AssetAndLiabilityItem, AssetsLiabilitiesDimension,
						|AssetsLiabilitiesDimensionNotUsed,
						|CorExpenseItem, CorExpenditureDimension, CorExpenditureDimensionRequired_, CorExpenditureDimensionOrderImplementation,
						|GLAccountSettings, PresentationOfRecordingInComplAccounting");
						GLAccountSettingsClient.WhenCopyingString(ThisObject, Items[TSName]);
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(TableRow.Department) Then
			TableRow.Department = DefaultDepartment();
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DefaultDepartment()
	
	Return SettingsValueCached.UserDivision(Users.CurrentUser());
	
EndFunction

&AtServer
Procedure FillInHeaderDetails()
	
	TheseAreExpenses = TheseAreExpenses();
	
	If Not TheseAreExpenses Then
		Query = New Query("
		|SELECT
		|	Income.Department,
		|	Income.LineOfBusiness,
		|	Income.IncomeItem,
		|	Income.DimensionOfRevenue,
		|	Income.DateRecord,
		|	SUM(Income.Sum) AS Sum,
		|	SUM(Income.SumCompl) AS SumCompl,
		|	SUM(Income.PermanentDifference) AS PermanentDifference,
		|	SUM(Income.CostTD) AS CostTD
		|FROM
		|	Document.OtherIncomeExpenses.OtherIncome AS Income
		|WHERE
		|	Income.Ref = &Ref
		|
		|GROUP BY
		|	Income.Department,
		|	Income.LineOfBusiness,
		|	Income.IncomeItem,
		|	Income.DimensionOfRevenue,
		|	Income.DateRecord
		|;
		|SELECT DISTINCT
		|	Income.GLAccountSettings,
		|	Income.DebitBusinessUnit,
		|	Income.CorLineOfBusiness,
		|	Income.AssetAndLiabilityItem,
		|	Income.AssetsLiabilitiesDimension
		|FROM
		|	Document.OtherIncomeExpenses.OtherIncome AS Income
		|WHERE
		|	Income.Ref = &Ref
		|");
		Query.SetParameter("Ref", Object.Ref);
		ResultsArray = Query.ExecuteBatch();
		
		VariousIncomes = ResultsArray[0].Unload();
		VariousIncomeCorPart = ResultsArray[1].Unload();
		
		DecryptionSwitchIncome = ?(VariousIncomes.Count() = 1, 0, 1);
		DecryptionSwitchIncomeCorPart = ?(VariousIncomeCorPart.Count() = 1, 0, 1);
		
		If Object.OtherIncome.Count() > 1
		 And DecryptionSwitchIncome = 0
		 And DecryptionSwitchIncomeCorPart = 0 Then
			DecryptionSwitchIncome = 1;
		EndIf;
		
		If DecryptionSwitchIncomeCorPart = 0
		 And Items.OtherIncome.CurrentRow = Undefined Then
			Items.OtherIncome.CurrentRow = Object.OtherIncome[0].GetID();
			Items.IncomeAssetLiabilityAnalysis.Enabled = ValueIsFilled(Object.OtherIncome[0].AssetAndLiabilityItem)
				And Not TypeOf(Object.OtherIncome[0].AssetsLiabilitiesDimension) = Type("EnumRef.AssetAndLiabilityItemsWithoutDimension");
		EndIf;
		
	Else
		Query = New Query("
		|SELECT
		|	Expenses.Department,
		|	Expenses.LineOfBusiness,
		|	Expenses.ExpenseItem,
		|	Expenses.DimensionOfExpenses,
		|	Expenses.DateRecord,
		|	SUM(Expenses.Sum) AS Sum,
		|	SUM(Expenses.AmountExcludingVAT) AS AmountExcludingVAT,
		|	SUM(Expenses.SumCompl) AS SumCompl,
		|	SUM(Expenses.PermanentDifference) AS PermanentDifference,
		|	SUM(Expenses.CostTD) AS CostTD
		|FROM
		|	Document.OtherIncomeExpenses.OtherExpenses AS Expenses
		|WHERE
		|	Expenses.Ref = &Ref
		|
		|GROUP BY
		|	Expenses.Department,
		|	Expenses.LineOfBusiness,
		|	Expenses.ExpenseItem,
		|	Expenses.DimensionOfExpenses,
		|	Expenses.DateRecord
		|;
		|SELECT DISTINCT
		|	Expenses.GLAccountSettings,
		|	Expenses.DebitBusinessUnit,
		|	Expenses.CorLineOfBusiness,
		|	Expenses.CorExpenseItem,
		|	Expenses.CorExpenditureDimension,
		|	Expenses.AssetAndLiabilityItem,
		|	Expenses.AssetsLiabilitiesDimension
		|FROM
		|	Document.OtherIncomeExpenses.OtherExpenses AS Expenses
		|WHERE
		|	Expenses.Ref = &Ref
		|;
		|");
		Query.SetParameter("Ref", Object.Ref);
		ResultsArray = Query.ExecuteBatch();
		
		VariousExpenses = ResultsArray[0].Unload();
		VariousExpensesCorPart = ResultsArray[1].Unload();
		
		DecryptionSwitchExpenses = ?(VariousExpenses.Count() = 1, 0, 1);
		DecryptionSwitchExpensesCorPart = ?(VariousExpensesCorPart.Count() = 1, 0, 1);
		
		If Object.OtherExpenses.Count() > 1
		 And DecryptionSwitchExpenses = 0
		 And DecryptionSwitchExpensesCorPart = 0 Then
			DecryptionSwitchExpenses = 1;
		EndIf;
		
		If DecryptionSwitchExpensesCorPart = 0
		 And Items.OtherExpenses.CurrentRow = Undefined Then
			Items.OtherExpenses.CurrentRow = Object.OtherExpenses[0].GetID();
			Items.ExpensesAssetsLiabilitiesDimension.Enabled = ValueIsFilled(Object.OtherExpenses[0].AssetAndLiabilityItem)
				And Not TypeOf(Object.OtherExpenses[0].AssetsLiabilitiesDimension) = Type("EnumRef.AssetAndLiabilityItemsWithoutDimension");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FormControlServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.OtherIncomeExpenses.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	Items.OtherExpensesSelectOtherExpenses_2.Visible = TheseAreExpenses
		And Object.BusinessOperation <> Enums.BusinessTransactions.OtherExpenses;
	
	AdjustVisibilityOfCommandToDisplayAmountPDATD();
	
	DifferenceFields = New Map;
	DifferenceFields.Insert(Items.OtherIncomeCostTD,   "TD");
	DifferenceFields.Insert(Items.IncomeTemporaryDifference,         "TD");
	DifferenceFields.Insert(Items.OtherExpensesCostTD,  "TD");
	DifferenceFields.Insert(Items.ExpensesCostTD,        "TD");
	DifferenceFields.Insert(Items.OtherIncomePermanentDifference,  "PD");
	DifferenceFields.Insert(Items.IncomeConstantDifference,        "PD");
	DifferenceFields.Insert(Items.OtherExpensesPermanentDifference, "PD");
	DifferenceFields.Insert(Items.ExpensesPermanentDifference,       "PD");
	LocalAccntingServer.ConfigureVisibilityOfTaxAccountingAndDifferencesFields(
		DifferenceFields, Object.Date, Object.Organization, "", WithdrawAmountOfDifferencesForProfitTaxPayer);
	Items.OtherExpensesPage.Visible	= TheseAreExpenses;
	Items.OtherIncomePage.Visible		= Not TheseAreExpenses;
	Items.GroupTotalExpenses.Visible		= TheseAreExpenses;
	Items.GroupTotalRevenue.Visible		= Not TheseAreExpenses;
	CurrentTableName = ?(TheseAreExpenses, "OtherExpenses", "OtherIncome");
	
	EmptySettings = New FixedArray(New Array);
	Items.OtherExpensesCorLineOfBusiness.ChoiceParameters = EmptySettings;
	Items.OtherExpensesCorLineOfBusiness.ChoiceParameterLinks = EmptySettings;
	
	Items.OtherIncomeCorLineOfBusiness.ChoiceParameters = EmptySettings;
	Items.OtherIncomeCorLineOfBusiness.ChoiceParameterLinks = EmptySettings;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ExpenseReclassification
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices Then
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameter("Filter.CostAccounting", True));
		Items.OtherExpensesCorLineOfBusiness.ChoiceParameters = New FixedArray(ParametersArray);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.IncomeReclassification Then
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
		Items.OtherIncomeCorLineOfBusiness.ChoiceParameters = New FixedArray(ParametersArray);
		
	Else
		ArrayOfLinks = New Array;
		ArrayOfLinks.Add(New ChoiceParameterLink("Ref", "Object.Ref"));
		Items.OtherExpensesCorLineOfBusiness.ChoiceParameterLinks = New FixedArray(ArrayOfLinks);
		Items.OtherIncomeCorLineOfBusiness.ChoiceParameterLinks = New FixedArray(ArrayOfLinks);
		
	EndIf;
	
	CurrencyOfMan = ?(ValueIsFilled(Object.Currency), Object.Currency, ManagementAccountingCurrency);
	
	// Tab "Expenses".
	
	KeepManagementRecordsOfOrganizations = True;
	
	UseVATAccounting = GetFunctionalOption("UseVATAccounting");
	ExpensesAmountHeaderFull = StrTemplate(NStr("vi = 'Số tiền kế toán (%1):';
												|ru = 'Суммы в упр. учете (%1):';
												|en = 'Amounts in management accounting (%1):'; fa = 'Amounts in management accounting (%1):';
												|it = 'Importi in contabilità gestionale (%1):';
												|pl = 'Kwoty w ewidencji zarządczej (%1):';
												|tr = 'Yönetim muhasebesindeki tutarlar (%1):'"), ManagementAccountingCurrency);
	Items.ExpensesSum.Title = ?(UseVATAccounting, NStr("vi = 'Gồm thuế GTGT';
														|ru = 'С НДС';
														|en = 'Including VAT'; fa = 'با احتساب مالیات بر ارزش افزوده';
														|it = 'Con IVA';
														|pl = 'Brutto';
														|tr = 'KDV dahil'"), ExpensesAmountHeaderFull);
	
	Items.DecorationExpensesAmountsUPR.Title =
		StrTemplate(NStr("vi = 'Số tiền chi phí theo tiền tệ chứng từ (%1):';
						|ru = 'Суммы расходов в валюте документа (%1):';
						|en = 'Expense amounts in the document currency (%1):'; fa = 'Expense amounts in the document currency (%1):';
						|it = 'Суммы расходов в валюте документа (%1):';
						|pl = 'Expense amounts in the document currency (%1):';
						|tr = 'Belge para birimi cinsinden gider tutarları (%1):'"), CurrencyOfMan);
	Items.DecorationExpensesAmountsUPR.Visible = UseVATAccounting;
	
	Items.DecorationExpensesAmountsRegl.Title =
		StrTemplate(NStr("vi = 'Số tiền chi phí theo kế toán tài chính (%1):';
						|ru = 'Суммы расходов в регламентированном учете (%1):';
						|en = 'Expense amounts in local accounting (%1):'; fa = 'Expense amounts in local accounting (%1):';
						|it = 'Importi di spese nella contabilità regolamentare (%1):';
						|pl = 'Kwoty wydatków w ewidencji reglamentowanej (%1):';
						|tr = 'Yerel muhasebedeki gider tutarları (%1):'"), LocalAccountingCurrency);
		
	OtherExpensesPaymentAmount = ?(UseVATAccounting, NStr("vi = 'Số tiền gồm thuế GTGT (%1)';
															|ru = 'Сумма с НДС (%1)';
															|en = 'Amount including VAT (%1)'; fa = 'Amount including VAT (%1)';
															|it = 'Сумма с НДС (%1)';
															|pl = 'Amount including VAT (%1)';
															|tr = 'KDV dahil tutar (%1)'"), NStr("vi = 'Số tiền (%1)';
																									|ru = 'Сумма (%1)';
																									|en = 'Amount (%1)'; fa = 'Amount (%1)';
																									|it = 'Totale (%1)';
																									|pl = 'Wartość (%1)';
																									|tr = 'Tutar (%1)'"));
	Items.OtherExpensesSum.Title = StrTemplate(OtherExpensesPaymentAmount, CurrencyOfMan);
		
	Items.OtherExpensesAmountExcludingVAT.Title =
		StrTemplate(NStr("vi = 'Số tiền không gồm thuế GTGT (%1)';
						|ru = 'Сумма без НДС (%1)';
						|en = 'Amount excluding VAT (%1)'; fa = 'Amount excluding VAT (%1)';
						|it = 'Сумма без НДС (%1)';
						|pl = 'Amount excluding VAT (%1)';
						|tr = 'KDV hariç tutar (%1)'"), CurrencyOfMan);
	If KeepManagementRecordsOfOrganizations Then
		Items.OtherExpensesSumMan.Title =
			StrTemplate(NStr("vi = 'Kế toán tài chính quốc tế (%1)';
							|ru = 'Международный фин. учет (%1)';
							|en = 'Financial accounting (%1)'; fa = 'Financial accounting (%1)';
							|it = 'Международный фин. учет (%1)';
							|pl = 'Financial accounting (%1)';
							|tr = 'Uluslararası fin. muhasebe (%1)'"), CurrencyOfMan);
	EndIf;
	Items.OtherExpensesSumCompl.Title =
		StrTemplate(NStr("vi = 'Kế toán (%1):';
						|ru = 'Бухгалтерский учет (%1):';
						|en = 'Local accounting (%1):'; fa = 'Local accounting (%1):';
						|it = 'Contabilità (%1):';
						|pl = 'Ewidencja księgowa (%1):';
						|tr = 'Genel muhasebe (%1):'"), LocalAccountingCurrency);
	Items.OtherExpensesAmountFA.Title =
		StrTemplate(NStr("vi = 'Kế toán thuế (%1):';
						|ru = 'Налоговый учет (%1):';
						|en = 'Tax accounting (%1):'; fa = 'Tax accounting (%1):';
						|it = 'Contabilità fiscale (%1):';
						|pl = 'Ewidencja podatkowa (%1):';
						|tr = 'Vergi muhasebesi (%1):'"), LocalAccountingCurrency);
	Items.OtherExpensesPermanentDifference.Title =
		StrTemplate(NStr("vi = 'Chênh lệch vĩnh viễn (%1):';
						|ru = 'Постоянная разница (%1):';
						|en = 'Permanent difference (%1):'; fa = 'Permanent difference (%1):';
						|it = 'Differenza costante (%1):';
						|pl = 'Stała różnica (%1):';
						|tr = 'Kalıcı fark (%1):'"), LocalAccountingCurrency);
	Items.OtherExpensesCostTD.Title =
		StrTemplate(NStr("vi = 'Chênh lệch tạm thời (%1):';
						|ru = 'Временная разница (%1):';
						|en = 'Temporary difference (%1):'; fa = 'Temporary difference (%1):';
						|it = 'Differenza temporanea (%1):';
						|pl = 'Tymczasowa różnica (%1):';
						|tr = 'Geçici fark (%1):'"), LocalAccountingCurrency);
	RecordsAreKeptAccordingToAIT = RecordsAreKeptAccordingToAIT(Object.Date, Object.Organization);
	Items.OtherExpensesAITAmount.Title =
		StrTemplate(NStr("vi = 'Thuế thu nhập bổ sung (%1):';
						|ru = 'НДД (%1):';
						|en = 'AIT (%1):'; fa = 'AIT (%1):';
						|it = 'НДД (%1):';
						|pl = 'AIT (%1):';
						|tr = 'EGV (%1):'"), LocalAccountingCurrency);
	Items.OtherExpensesAITAmount.Visible = RecordsAreKeptAccordingToAIT;
	Items.ExpensesAmountNDD.Visible       = RecordsAreKeptAccordingToAIT;
	
	// The "Income" tab.	
	Items.DecorationIncomeAmountsUPR.Title =
		StrTemplate(NStr("vi = 'Số tiền thu nhập theo tiền tệ chứng từ (%1):';
						|ru = 'Суммы доходов в валюте документа (%1):';
						|en = 'Income amounts in the document currency (%1):'; fa = 'Income amounts in the document currency (%1):';
						|it = 'Суммы доходов в валюте документа (%1):';
						|pl = 'Income amounts in the document currency (%1):';
						|tr = 'Belge para birimi cinsinden gelir tutarları (%1):'"), CurrencyOfMan);
	Items.DecorationRevenueAmountsRegl.Title =
		StrTemplate(NStr("vi = 'Số tiền thu nhập theo kế toán tài chính (%1):';
						|ru = 'Суммы доходов в регламентированном учете (%1):';
						|en = 'Income amounts in local accounting (%1):'; fa = 'Income amounts in local accounting (%1):';
						|it = 'Importi dei ricavi nella contabilità regolamentare (%1):';
						|pl = 'Kwoty dochodów w ewidencji reglamentowanej (%1):';
						|tr = 'Yerel muhasebedeki gelir tutarları (%1):'"), LocalAccountingCurrency);
		
	Items.OtherIncomeSum.Title =
		StrTemplate(NStr("vi = 'Số tiền gồm thuế GTGT (%1)';
						|ru = 'Сумма с НДС (%1)';
						|en = 'Amount including VAT (%1)'; fa = 'Amount including VAT (%1)';
						|it = 'Сумма с НДС (%1)';
						|pl = 'Amount including VAT (%1)';
						|tr = 'KDV dahil tutar (%1)'"), CurrencyOfMan);
	Items.OtherIncomeSumMan.Title =
		StrTemplate(NStr("vi = 'Số tiền không gồm thuế GTGT (%1)';
						|ru = 'Сумма без НДС (%1)';
						|en = 'Amount excluding VAT (%1)'; fa = 'Amount excluding VAT (%1)';
						|it = 'Сумма без НДС (%1)';
						|pl = 'Amount excluding VAT (%1)';
						|tr = 'KDV hariç tutar (%1)'"), CurrencyOfMan);
	Items.OtherIncomeSumCompl.Title =
		StrTemplate(NStr("vi = 'Kế toán (%1):';
						|ru = 'Бухгалтерский учет (%1):';
						|en = 'Local accounting (%1):'; fa = 'Local accounting (%1):';
						|it = 'Contabilità (%1):';
						|pl = 'Ewidencja księgowa (%1):';
						|tr = 'Genel muhasebe (%1):'"), LocalAccountingCurrency);
	Items.OtherIncomeAmountFA.Title =
		StrTemplate(NStr("vi = 'Kế toán thuế (%1):';
						|ru = 'Налоговый учет (%1):';
						|en = 'Tax accounting (%1):'; fa = 'Tax accounting (%1):';
						|it = 'Contabilità fiscale (%1):';
						|pl = 'Ewidencja podatkowa (%1):';
						|tr = 'Vergi muhasebesi (%1):'"), LocalAccountingCurrency);
	Items.OtherIncomePermanentDifference.Title =
		StrTemplate(NStr("vi = 'Chênh lệch vĩnh viễn (%1):';
						|ru = 'Постоянная разница (%1):';
						|en = 'Permanent difference (%1):'; fa = 'Permanent difference (%1):';
						|it = 'Differenza costante (%1):';
						|pl = 'Stała różnica (%1):';
						|tr = 'Kalıcı fark (%1):'"), LocalAccountingCurrency);
	Items.OtherIncomeCostTD.Title =
		StrTemplate(NStr("vi = 'Chênh lệch tạm thời (%1):';
						|ru = 'Временная разница (%1):';
						|en = 'Temporary difference (%1):'; fa = 'Temporary difference (%1):';
						|it = 'Differenza temporanea (%1):';
						|pl = 'Tymczasowa różnica (%1):';
						|tr = 'Geçici fark (%1):'"), LocalAccountingCurrency);
		
	RefreshFormTitle();
	
	Items.GroupDocumentFoundation.Visible = ValueIsFilled(Object.DocumentBasis);
	
EndProcedure

&AtClient
Procedure ManagingFormElementsOnClient()
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices") Then
		Items.Organization.Title = NStr("vi = 'Doanh nghiệp-người gửi';
										|ru = 'Организация-отправитель';
										|en = 'Shipping company'; fa = 'شرکت ارسال‌کننده';
										|it = 'Azienda-mittente';
										|pl = 'Shipping company';
										|tr = 'Gönderici iş yeri'");
	Else
		Items.Organization.Title = NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'");
	EndIf;
	
	If TheseAreExpenses Then
		ExpensesWithoutSplitting = (DecryptionSwitchExpenses = 0);
		CorPartWithoutPartitioning = (DecryptionSwitchExpensesCorPart = 0);
		If ExpensesWithoutSplitting And CorPartWithoutPartitioning Then
			Items.PagesExpenses.CurrentPage = Items.PageExpensesWithoutSplit;
		Else
			Items.PagesExpenses.CurrentPage = Items.PageExpensesAsAList;
		EndIf;
		ExpenseReclassification =
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ExpenseReclassification")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices");
			
		Items.DecryptionSwitchExpensesCorPart.Title =
			?(ExpenseReclassification, NStr("vi = 'Đối ứng chi phí';
											|ru = 'Кор. расходы';
											|en = 'Cor. expenses'; fa = 'Cor. expenses';
											|it = 'Spese di corrispondenza';
											|pl = 'Wydatki koresp.';
											|tr = 'Düzeltilmiş giderler'"), NStr("vi = 'Tài sản/nguồn vốn';
																			|ru = 'Активы/пассивы';
																			|en = 'Assets/liabilities'; fa = 'دارایی‌ها/بدهی‌ها';
																			|it = 'Attivi/passivi';
																			|pl = 'Assets/liabilities';
																			|tr = 'Aktifler/Pasifler'"));
		Items.DecodingSwitchCostsCorPartOfTheList.Title =
			?(ExpenseReclassification, NStr("vi = 'Đối ứng chi phí';
											|ru = 'Кор. расходы';
											|en = 'Cor. expenses'; fa = 'Cor. expenses';
											|it = 'Spese di corrispondenza';
											|pl = 'Wydatki koresp.';
											|tr = 'Düzeltilmiş giderler'"), NStr("vi = 'Tài sản/nguồn vốn';
																			|ru = 'Активы/пассивы';
																			|en = 'Assets/liabilities'; fa = 'دارایی‌ها/بدهی‌ها';
																			|it = 'Attivi/passivi';
																			|pl = 'Assets/liabilities';
																			|tr = 'Aktifler/Pasifler'"));
			
		Items.GroupBasementExpensesListRight.Visible = CorPartWithoutPartitioning;
		Items.GroupItemCostAnalysisWithoutSplitting.Visible = ExpensesWithoutSplitting;
		
		Items.ExpensesAssetAndLiabilityItem.Visible = Not ExpenseReclassification;
		Items.ExpensesAssetsLiabilitiesDimension.Visible = Not ExpenseReclassification;
		Items.CorExpenseItem.Visible = ExpenseReclassification;
		Items.CorExpenditureDimension.Visible = ExpenseReclassification;
		
		Items.TheCostOfTheUnitWithoutBreaking.Visible = ExpensesWithoutSplitting;
		Items.ExpensesBusinessLineWithoutDivision.Visible = ExpensesWithoutSplitting;
		Items.ItemOfExpenditureWithoutDivision.Visible = ExpensesWithoutSplitting;
		Items.CostAnalysisWithoutSplitting.Visible = ExpensesWithoutSplitting;
		
		Items.ExpensesOfTheCorDivisionWithoutSplitting.Visible = CorPartWithoutPartitioning;
		Items.ExpensesCorBusinessLineWithoutSplitting.Visible = CorPartWithoutPartitioning;
		Items.ExpensesItemOfAssetsLiabilitiesWithoutDivision.Visible = CorPartWithoutPartitioning And Not ExpenseReclassification;
		Items.ExpensesAnalysisOfAssetsLiabilitiesWithoutSplitting.Visible = CorPartWithoutPartitioning And Not ExpenseReclassification;
		Items.ExpensesRepresentationOfTheReflectionInTheReglAccountingWithoutSplitting.Visible = CorPartWithoutPartitioning And Not ExpenseReclassification;
		
		Items.CorItemOfExpenditureWithoutDivision.Visible = CorPartWithoutPartitioning And ExpenseReclassification;
		Items.CorCostAnalysisWithoutSplitting.Visible = CorPartWithoutPartitioning And ExpenseReclassification;
		
		Items.OtherExpensesDepartmentDirection.Visible = Not ExpensesWithoutSplitting;
		Items.OtherExpensesDepartment.Visible = Not ExpensesWithoutSplitting;
		Items.OtherExpensesLineOfBusiness.Visible = Not ExpensesWithoutSplitting;
		
		Items.OtherExpensesExpensesGroup.Visible = Not ExpensesWithoutSplitting;
		Items.OtherExpensesExpenseItem.Visible = Not ExpensesWithoutSplitting;
		Items.OtherExpensesDimensionOfExpenses.Visible = Not ExpensesWithoutSplitting;
		
		Items.OtherExpensesCorDepartmentDirection.Visible = Not CorPartWithoutPartitioning;
		Items.OtherExpensesDebitBusinessUnit.Visible = Not CorPartWithoutPartitioning;
		Items.OtherExpensesCorLineOfBusiness.Visible = Not CorPartWithoutPartitioning;
		
		Items.OtherExpensesAssetsLiabilitiesGroup.Visible = Not CorPartWithoutPartitioning And Not ExpenseReclassification;
		Items.OtherExpensesAssetAndLiabilityItem.Visible = Not CorPartWithoutPartitioning And Not ExpenseReclassification;
		Items.OtherExpensesAssetsLiabilitiesDimension.Visible = Not CorPartWithoutPartitioning And Not ExpenseReclassification;
		
		If CorPartWithoutPartitioning Then
			Items.OtherExpensesPresentationOfRecordingInComplAccounting.Visible = False;
		Else
			ManagingAccountingAccountSettings();
		EndIf;
		
		Items.OtherExpensesGroupCorExpenses.Visible = Not CorPartWithoutPartitioning And ExpenseReclassification;
		Items.OtherExpensesCorExpenseItem.Visible = Not CorPartWithoutPartitioning And ExpenseReclassification;
		Items.OtherExpensesCorExpenditureDimension.Visible = Not CorPartWithoutPartitioning And ExpenseReclassification;
		
		SetExpenseSuggestions();
	Else
		RevenueWithoutSplitting = (DecryptionSwitchIncome = 0);
		CorPartWithoutPartitioning = (DecryptionSwitchIncomeCorPart = 0);
		If RevenueWithoutSplitting And CorPartWithoutPartitioning Then
			Items.PagesIncome.CurrentPage = Items.PageIncomeWithoutSplit;
		Else
			Items.PagesIncome.CurrentPage = Items.PageIncomeAsAList;
		EndIf;
		
		IncomeReclassification =
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IncomeReclassification");
			
		Items.DecryptionSwitchIncomeCorPart.Title =
			?(IncomeReclassification, NStr("vi = 'Đối ứng thu nhập';
											|ru = 'Кор. доходы';
											|en = 'Cor. income'; fa = 'Cor. income';
											|it = 'Ricavi di corrispondenza';
											|pl = 'Dochody koresp.';
											|tr = 'Düzeltilmiş gelirler'"), NStr("vi = 'Tài sản/nguồn vốn';
																		|ru = 'Активы/пассивы';
																		|en = 'Assets/liabilities'; fa = 'دارایی‌ها/بدهی‌ها';
																		|it = 'Attivi/passivi';
																		|pl = 'Assets/liabilities';
																		|tr = 'Aktifler/Pasifler'"));
		Items.TheDecryptionSwitchReturnsTheCorPartOfTheList.Title =
			?(IncomeReclassification, NStr("vi = 'Đối ứng thu nhập';
											|ru = 'Кор. доходы';
											|en = 'Cor. income'; fa = 'Cor. income';
											|it = 'Ricavi di corrispondenza';
											|pl = 'Dochody koresp.';
											|tr = 'Düzeltilmiş gelirler'"), NStr("vi = 'Tài sản/nguồn vốn';
																		|ru = 'Активы/пассивы';
																		|en = 'Assets/liabilities'; fa = 'دارایی‌ها/بدهی‌ها';
																		|it = 'Attivi/passivi';
																		|pl = 'Assets/liabilities';
																		|tr = 'Aktifler/Pasifler'"));
			
		Items.GroupBasementIncomeListRight.Visible = CorPartWithoutPartitioning;
		Items.GroupItemIncomeDimensionWithoutSplit.Visible =  RevenueWithoutSplitting;
		
		Items.IncomeItemOfAssetsLiabilities.Visible = Not IncomeReclassification;
		Items.IncomeAssetLiabilityAnalysis.Visible = Not IncomeReclassification;
		Items.CorIncomeItem.Visible = IncomeReclassification;
		Items.CorIncomeDimension.Visible = IncomeReclassification;
		
		Items.RevenueDivisionWithoutDivision.Visible = RevenueWithoutSplitting;
		Items.IncomeLineOfBusinessWithoutDivision.Visible = RevenueWithoutSplitting;
		
		Items.IncomeItemWithoutDivision.Visible = RevenueWithoutSplitting;
		Items.RevenueAnalyticsWithoutPartitioning.Visible = RevenueWithoutSplitting;
		
		Items.IncomeCorDivisionWithoutDivision.Visible = CorPartWithoutPartitioning;
		Items.IncomeCorLineOfBusinessWithoutDivision.Visible = CorPartWithoutPartitioning;
		Items.IncomeItemOfAssetsLiabilitiesWithoutDivision.Visible = CorPartWithoutPartitioning And Not IncomeReclassification;
		Items.IncomeAnalysisOfAssetsLiabilitiesWithoutSplitting.Visible = CorPartWithoutPartitioning And Not IncomeReclassification;
		Items.RevenueRepresentationOfTheReflectionInTheReglAccountingWithoutSplitting.Visible = CorPartWithoutPartitioning And Not IncomeReclassification;
		
		Items.CorIncomeItemWithoutDivision.Visible = CorPartWithoutPartitioning And IncomeReclassification;
		Items.CorRevenueAnalyticsWithoutPartitioning.Visible = CorPartWithoutPartitioning And IncomeReclassification;
		
		Items.OtherIncomeDepartmentDirection.Visible = Not RevenueWithoutSplitting;
		Items.OtherIncomeDepartment.Visible = Not RevenueWithoutSplitting;
		Items.OtherIncomeLineOfBusiness.Visible = Not RevenueWithoutSplitting;
		
		Items.OtherIncomeIncomeGroup.Visible = Not RevenueWithoutSplitting;
		Items.OtherIncomeIncomeItem.Visible = Not RevenueWithoutSplitting;
		Items.OtherIncomeDimensionOfRevenue.Visible = Not RevenueWithoutSplitting;
		
		Items.OtherIncomeCorDepartmentDirection.Visible = Not CorPartWithoutPartitioning;
		Items.OtherIncomeDebitBusinessUnit.Visible = Not CorPartWithoutPartitioning;
		Items.OtherIncomeCorLineOfBusiness.Visible = Not CorPartWithoutPartitioning;
		
		Items.OtherIncomeGroupAssetsLiabilities.Visible = Not CorPartWithoutPartitioning And Not IncomeReclassification;
		Items.OtherIncomeAssetAndLiabilityItem.Visible = Not CorPartWithoutPartitioning And Not IncomeReclassification;
		Items.OtherIncomeAssetsLiabilitiesDimension.Visible = Not CorPartWithoutPartitioning And Not IncomeReclassification;
		
		If CorPartWithoutPartitioning Then
			Items.OtherIncomePresentationOfRecordingInComplAccounting.Visible = False;
		Else
			ManagingAccountingAccountSettings();
		EndIf;
		
		Items.OtherIncomeGroupCorIncome.Visible = Not CorPartWithoutPartitioning And IncomeReclassification;
		Items.OtherIncomeCorIncomeItem.Visible = Not CorPartWithoutPartitioning And IncomeReclassification;
		Items.OtherIncomeCorIncomeDimension.Visible = Not CorPartWithoutPartitioning And IncomeReclassification;
	EndIf;
	
EndProcedure

&AtServer
Procedure ManagingAccountingAccountSettings()
	
	SetupParameters = Documents.OtherIncomeExpenses.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	
EndProcedure

&AtClient
Procedure RepresentationOfReflectionInLocalAccountingWithoutSplittingAfterClicking(Result, AdditionalParameters) Export
	
	TSName = AdditionalParameters.TSName;
	LineWithSettings = Object[TSName][0];
	
	For Each TSRow In Object[TSName] Do
		If TSRow <> LineWithSettings Then
			TSRow.GLAccountSettings = LineWithSettings.GLAccountSettings;
			TSRow.PresentationOfRecordingInComplAccounting = LineWithSettings.PresentationOfRecordingInComplAccounting;
			GLAccountSettingsClient.WhenCopyingString(ThisObject, Items[TSName], TSRow);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AdjustVisibilityOfCommandToDisplayAmountPDATD()

	
EndProcedure

&AtClient
Procedure SetExpenseSuggestions()
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices") Then
		Items.CorExpenseItem.InputHint					= NStr("vi = '<Dạng chi phí phù hợp>';
																|ru = '<Совпадает со статьей расходов>';
																|en = '<Matches the expense item>'; fa = '<Matches the expense item>';
																|it = '<Coincide alla voce di spese>';
																|pl = '<Zgodny z pozycją wydatków>';
																|tr = '<Gider kalemleriyle eşleşiyor>'");
		Items.CorItemOfExpenditureWithoutDivision.InputHint		= NStr("vi = '<Dạng chi phí phù hợp>';
																			|ru = '<Совпадает со статьей расходов>';
																			|en = '<Matches the expense item>'; fa = '<Matches the expense item>';
																			|it = '<Coincide alla voce di spese>';
																			|pl = '<Zgodny z pozycją wydatków>';
																			|tr = '<Gider kalemleriyle eşleşiyor>'");
	Else
		Items.CorExpenseItem.InputHint					= "";
		Items.CorItemOfExpenditureWithoutDivision.InputHint		= "";
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionProcessing(AddressInTempStorage, AdditionalParameters) Export
	
	If AddressInTempStorage = Undefined Then
		Return;
	EndIf;
	
	SelectionProcessingServer(AddressInTempStorage);
	
EndProcedure

&AtServer
Procedure SelectionProcessingServer(AddressInTempStorage)
	
	CalculationResult1 = GetFromTempStorage(AddressInTempStorage);
	
	If CalculationResult1 = Undefined Then
		Return;
	EndIf;
		
	For Each String In CalculationResult1 Do
		NewRow = Object.OtherExpenses.Add();
		FillPropertyValues(NewRow, String);
		If Object.BusinessOperation = Enums.BusinessTransactions.ExpenseReclassification Then
			NewRow.ExpenseItem = Undefined;
			NewRow.DimensionOfExpenses = Undefined;
			NewRow.CorLineOfBusiness = String.LineOfBusiness;
			NewRow.CorExpenseItem = String.ExpenseItem;
			NewRow.CorExpenditureDimension = String.DimensionOfExpenses;
		EndIf;
		NewRow.AmountFA = NewRow.SumCompl - NewRow.PermanentDifference - NewRow.CostTD;
	EndDo;
	
EndProcedure

// For the passed details of the table part, it gets the values of the details separated by a dot
// and places them in the neighboring details of the table part.
//
// Parameters:
// 		FormTable - FormDataCollection - table part of the document form
// 		TSAttributes - Structure - Description of details tab. parts for which you need to get the values of subordinate details
//					Key-String - name of the table part details
//					The value - Structure - Description of the subordinate details and receivers details in the PM
//							Key-String - name of the subordinate detail
//							Value - String - the name of the props tab. part where you want to place the resulting value.
//
&AtServer
Procedure FillInDependentDetailsOfTS(FormTable, TSAttributes, RowID = Undefined)
	
	If FormTable.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CAST(Table.LineNumber AS NUMBER) AS LineNumber,
	|	&TSFields
	|INTO Table
	|FROM
	|	&Table AS Table;
	|
	|//////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber AS LineNumber,
	|	&BankingDetailsFields
	|FROM
	|	Table AS Table";
	
	// The template of the query field string of the form - "Table.Flight AS A flight"
	TSFieldTemplate = "
	|	Table.%1 AS %1";
	
	// The template of the query field string of the form - "Table.Propittch.A prop source AS A prop receiver".
	PropsTemplate = "
	|	Table.%1.%2 AS %3";
	
	// The request field string template looks like "VALUE AS A DATA receiver".
	FixedValuePattern = "
	|	%1 AS %2";
	
	TSFields = New Array;
	BankingDetailsFields = New Array;
	AllAttributes = New Array;
	AllAttributes.Add("LineNumber");
	For Each TSProps In TSAttributes Do
		TSFields.Add(StrTemplate(TSFieldTemplate, TSProps.Key));
		AllAttributes.Add(TSProps.Key);
		For Each DependentAttribute In TSProps.Value Do
			FieldName = ?(ValueIsFilled(DependentAttribute.Value), DependentAttribute.Value, DependentAttribute.Key);
			BankingDetailsFields.Add(
				?(FieldName = "TRUE", 
					StrTemplate(FixedValuePattern, FieldName, DependentAttribute.Key),
					StrTemplate(PropsTemplate, TSProps.Key, FieldName, DependentAttribute.Key)
				)
			);
			AllAttributes.Add(DependentAttribute.Key);
		EndDo;
	EndDo;
	AllDetailsInString = StrConcat(AllAttributes, ",");
	
	Query.Text = StrReplace(Query.Text, "&TSFields", StrConcat(TSFields, ","));
	Query.Text = StrReplace(Query.Text, "&BankingDetailsFields", StrConcat(BankingDetailsFields, ","));

	Rows = Undefined;
	If RowID <> Undefined Then
		Rows = New Array();
		Rows.Add(FormTable.FindByID(RowID));
	EndIf;
	Query.SetParameter("Table", FormTable.Unload(Rows, AllDetailsInString));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		FillPropertyValues(FormTable[Selection.LineNumber-1], Selection,, "LineNumber");
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInDetailsInTablePart(TSName, Var_AttributeName, Value);
	
	Table = Object[TSName].Unload(,);
	Table.FillValues(Value, Var_AttributeName);
	Object[TSName].Load(Table);
	
EndProcedure

&AtClient
Procedure WhenChangingDecryptionSwitchCosts(SwitchValue)
	If DecryptionSwitchExpenses = 0
	 Or DecryptionSwitchExpensesCorPart = 0 Then
		If Object.OtherExpenses.Count() = 0 Then
			NewRow = Object.OtherExpenses.Add();
			NewRow.EnteredInTaxAccounting = True;
			Items.OtherExpenses.CurrentRow = NewRow.GetID();
			AtBeginningOfEditingTS("OtherExpenses", True, False)
		ElsIf Object.OtherExpenses.Count() = 1 Then
			If Items.OtherExpenses.CurrentRow = Undefined Then
				Items.OtherExpenses.CurrentRow = Object.OtherExpenses[0].GetID();
			EndIf;
		EndIf;
		PresentationOfRecordingInComplAccounting = Items.OtherExpenses.CurrentData.PresentationOfRecordingInComplAccounting;
		If IsBlankString(PresentationOfRecordingInComplAccounting) Then
			PresentationOfRecordingInComplAccounting = NStr("vi = 'Tùy chỉnh';
															|ru = 'Настроить';
															|en = 'Customize'; fa = 'سفارشی‌سازی';
															|it = 'Impostare';
															|pl = 'Ustaw';
															|tr = 'Ayarla'");
		EndIf;
	EndIf;
	
	If DecryptionSwitchExpenses = 0
	 And DecryptionSwitchExpensesCorPart = 0
	 And Object.OtherExpenses.Count() > 1 Then
		MessageText = NStr("vi = 'Không thể chuyển sang chế độ không chia tách nếu đã nhập nhiều hơn một dòng trong phần bảng!';
							|ru = 'Переключение в режим без разбиения невозможно, если в табличной части введено более одной строки!';
							|en = 'Cannot switch to no-split mode if more than one row is entered in the table.'; fa = 'Cannot switch to no-split mode if more than one row is entered in the table.';
							|it = 'Passare alla modalità senza la partizione è impossibile se nella parte tabulare viene inserita più di una riga!';
							|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w części tabelarycznej wprowadzono więcej niż jeden wiersz!';
							|tr = 'Tablolara birden fazla satır girildiyse bölmesiz moda bağlanılamaz!'");
		CommonClientServer.MessageToUser(MessageText);
		SwitchValue = 1;
	EndIf;
	
	If DecryptionSwitchExpenses = 0
	 And DecryptionSwitchExpensesCorPart = 1
	 And Not ExpensesInLinesAreSame()Then
		MessageText = NStr("vi = 'Không thể chuyển sang chế độ không chia tách nếu đã chỉ ra chi phí khác trong các dòng của phần bảng!';
							|ru = 'Переключение в режим без разбиения невозможно, если в строках табличной части указаны разные расходы!';
							|en = 'Cannot switch to no-split mode if different expenses are specified in the table rows.'; fa = 'Cannot switch to no-split mode if different expenses are specified in the table rows.';
							|it = 'Passare alla modalità senza la partizione è impossibile se nelle righe della parte tabulare vengono inserite spese diverse!';
							|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w wierszach części tabelarycznej podano rożne wydatki!';
							|tr = 'Tablo satırlarındaki giderler farklıysa moda kesintisiz bağlanılamaz!'");
		CommonClientServer.MessageToUser(MessageText);
		SwitchValue = 1;
	EndIf;
	
	If DecryptionSwitchExpenses = 1
	 And DecryptionSwitchExpensesCorPart = 0
	 And Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ExpenseReclassification")
	 And Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices")
	 And Not CorPartInLinesIsSame("OtherExpenses") Then
		MessageText = NStr("vi = 'Không thể chuyển sang chế độ không chia tách nếu đã chỉ ra tài sản/nguồn vốn khác trong các dòng của phần bảng!';
							|ru = 'Переключение в режим без разбиения невозможно, если в строках табличной части указаны разные активы/пассивы!';
							|en = 'Cannot switch to no-split mode if different assets/liabilities are specified in the table rows.'; fa = 'Cannot switch to no-split mode if different assets/liabilities are specified in the table rows.';
							|it = 'Passare alla modalità senza la partizione è impossibile se nelle righe della parte tabulare vengono inseriti attivi/passivi diversi!';
							|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w wierszach części tabelarycznej podano rożne aktywa/pasywa!';
							|tr = 'Tablo satırlarındaki aktifler ve pasifler farklıysa moda kesintisiz bağlanılamaz!'");
		CommonClientServer.MessageToUser(MessageText);
		SwitchValue = 1;
	EndIf;
	
	If DecryptionSwitchExpenses = 1
	 And DecryptionSwitchExpensesCorPart = 0
	 And (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ExpenseReclassification")
	 	Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices"))
	 And Not CorExpensesInLinesAreSame() Then
		MessageText = NStr("vi = 'Không thể chuyển sang chế độ không phân chia nếu các hộp khác nhau được chỉ định trong các hàng của phần bảng. Chi phí!';
							|ru = 'Переключение в режим без разбиения невозможно, если в строках табличной части указаны разные кор. расходы!';
							|en = 'Cannot switch to no-split mode if different cor. expenses are specified in the table rows.'; fa = 'Cannot switch to no-split mode if different cor. expenses are specified in the table rows.';
							|it = 'Passare alla modalità senza la partizione è impossibile se nelle righe della parte tabulare vengono inserite spese di corrispondenza diverse!';
							|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w wierszach części tabelarycznej podano rożne wydatki koresp.!';
							|tr = 'Tablo satırlarındaki düzeltilmiş giderler farklıysa moda kesintisiz bağlanılamaz!'");
		CommonClientServer.MessageToUser(MessageText);
		SwitchValue = 1;
	EndIf;
	
	ManagingFormElementsOnClient();
EndProcedure

&AtServer
Function ExpensesInLinesAreSame()
	
	Table = Object.OtherExpenses.Unload(,);
	Table.GroupBy("Department, LineOfBusiness, ExpenseItem, DimensionOfExpenses, DateRecord");
	Return (Table.Count() < 2);
	
EndFunction

&AtServer
Function CorExpensesInLinesAreSame()
	
	Table = Object.OtherExpenses.Unload(,);
	Table.GroupBy("DebitBusinessUnit, CorLineOfBusiness, CorExpenseItem, CorExpenditureDimension");
	Return (Table.Count() < 2);
	
EndFunction

&AtServer
Function CorPartInLinesIsSame(TSName)
	
	ConvolutionColumns = "DebitBusinessUnit,CorLineOfBusiness,AssetAndLiabilityItem,AssetsLiabilitiesDimension";
	
	Table = Object[TSName].Unload(, ConvolutionColumns);
	Table.GroupBy(ConvolutionColumns);
	
	If Table.Count() > 1 Then
		Return False;
	EndIf;
	Table = Object[TSName].Unload(, "GLAccountSettings");
	AccountingAccountSettings = New Array();
	
	For Each TableRow In Table Do
		If ValueIsFilled(TableRow.GLAccountSettings) Then
			AccountingAccountSettings.Add(TableRow.GLAccountSettings);
		EndIf;
	EndDo;
	
	If AccountingAccountSettings.Count() > 0 Then
		Table.Columns.Add("HashAmountSettings", Common.StringTypeDetails(50));
		
		GLAccountSettingsServer.RecordFormSInvoiceSettings(ThisObject);
		HashAmountOfSettings = Common.ObjectsAttributeValue(AccountingAccountSettings, "HashSum");
		
		For Each TableRow In Table Do
			TableRow.HashAmountSettings = HashAmountOfSettings[TableRow.GLAccountSettings];
		EndDo;
		
		Table.GroupBy("HashAmountSettings");
		Return Table.Count() < 2;
	EndIf;
	Return True;
	
EndFunction

&AtClient
Procedure WhenDecryptionSwitchIsChangedIncome(SwitchValue)
	If DecryptionSwitchIncome = 0
	 Or DecryptionSwitchIncomeCorPart = 0 Then
		If Object.OtherIncome.Count() = 0 Then
			NewRow = Object.OtherIncome.Add();
			NewRow.EnteredInTaxAccounting = True;
			Items.OtherIncome.CurrentRow = NewRow.GetID();
			AtBeginningOfEditingTS("OtherIncome", True, False)
		ElsIf Object.OtherIncome.Count() = 1 Then
			If Items.OtherIncome.CurrentRow = Undefined Then
				Items.OtherIncome.CurrentRow = Object.OtherIncome[0].GetID();
			EndIf;
		EndIf;
		PresentationOfRecordingInComplAccounting = Items.OtherIncome.CurrentData.PresentationOfRecordingInComplAccounting;
		If IsBlankString(PresentationOfRecordingInComplAccounting) Then
			PresentationOfRecordingInComplAccounting = NStr("vi = 'Tùy chỉnh';
															|ru = 'Настроить';
															|en = 'Customize'; fa = 'سفارشی‌سازی';
															|it = 'Impostare';
															|pl = 'Ustaw';
															|tr = 'Ayarla'");
		EndIf;
	EndIf;
	
	If DecryptionSwitchIncome = 0
	 And DecryptionSwitchIncomeCorPart = 0
	 And Object.OtherIncome.Count() > 1 Then
		MessageText = NStr("vi = 'Không thể chuyển sang chế độ không chia tách nếu đã nhập nhiều hơn một dòng trong phần bảng!';
							|ru = 'Переключение в режим без разбиения невозможно, если в табличной части введено более одной строки!';
							|en = 'Cannot switch to no-split mode if more than one row is entered in the table.'; fa = 'Cannot switch to no-split mode if more than one row is entered in the table.';
							|it = 'Passare alla modalità senza la partizione è impossibile se nella parte tabulare viene inserita più di una riga!';
							|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w części tabelarycznej wprowadzono więcej niż jeden wiersz!';
							|tr = 'Tablolara birden fazla satır girildiyse bölmesiz moda bağlanılamaz!'");
		CommonClientServer.MessageToUser(MessageText);
		SwitchValue = 1;
	EndIf;
	
	If DecryptionSwitchIncome = 0
	 And DecryptionSwitchIncomeCorPart = 1
	 And Not RevenueLinesAreSame()Then
		MessageText = NStr("vi = 'Không thể chuyển sang chế độ không chia tách nếu đã chỉ ra thu nhập khác nhau trong các dòng của phần bảng!';
							|ru = 'Переключение в режим без разбиения невозможно, если в строках табличной части указаны разные доходы!';
							|en = 'Cannot switch to no-split mode if different income is specified in the table rows.'; fa = 'Cannot switch to no-split mode if different income is specified in the table rows.';
							|it = 'Passare alla modalità senza la partizione è impossibile se nelle righe della parte tabulare vengono inseriti ricavi diversi!';
							|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w wierszach części tabelarycznej podano rożne dochody!';
							|tr = 'Tablo satırlarındaki gelirler farklıysa moda kesintisiz bağlanılamaz!'");
		CommonClientServer.MessageToUser(MessageText);
		SwitchValue = 1;
	EndIf;
	
	If DecryptionSwitchIncome = 1
	 And DecryptionSwitchIncomeCorPart = 0
	 And Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.IncomeReclassification")
	 And Not CorPartInLinesIsSame("OtherIncome") Then
		MessageText = NStr("vi = 'Không thể chuyển sang chế độ không chia tách nếu đã chỉ ra tài sản/nguồn vốn trong các dòng của phần bảng!';
							|ru = 'Переключение в режим без разбиения невозможно, если в строках табличной части указаны разные активы/пассивы!';
							|en = 'Cannot switch to no-split mode if different assets/liabilities are specified in the table rows.'; fa = 'Cannot switch to no-split mode if different assets/liabilities are specified in the table rows.';
							|it = 'Passare alla modalità senza la partizione è impossibile se nelle righe della parte tabulare vengono inseriti attivi/passivi diversi!';
							|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w wierszach części tabelarycznej podano rożne aktywa/pasywa!';
							|tr = 'Tablo satırlarındaki aktifler ve pasifler farklıysa moda kesintisiz bağlanılamaz!'");
		CommonClientServer.MessageToUser(MessageText);
		SwitchValue = 1;
	EndIf;
	
	If DecryptionSwitchIncome = 1
	 And DecryptionSwitchIncomeCorPart = 0
	 And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IncomeReclassification")
	 And Not CorRevenueLinesAreSame() Then
		MessageText = NStr("vi = 'Không thể chuyển sang chế độ không phân chia nếu đã chỉ ra các thu nhập đối ứng khác nhau trong các dòng của phần bảng!';
							|ru = 'Переключение в режим без разбиения невозможно, если в строках табличной части указаны разные кор. доходы!';
							|en = 'Cannot switch to no-split mode if different cor. income is specified in the table rows.'; fa = 'Cannot switch to no-split mode if different cor. income is specified in the table rows.';
							|it = 'Passare alla modalità senza la partizione è impossibile se nelle righe della parte tabulare vengono inseriti i ricavi di corrispondenza diversi!';
							|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w wierszach części tabelarycznej podano rożne dochody koresp.!';
							|tr = 'Tablo satırlarındaki düzeltilmiş gelirler farklıysa moda kesintisiz bağlanılamaz!'");
		CommonClientServer.MessageToUser(MessageText);
		SwitchValue = 1;
	EndIf;
	
	ManagingFormElementsOnClient();
EndProcedure

&AtServer
Function RevenueLinesAreSame()
	
	Table = Object.OtherIncome.Unload(,);
	Table.GroupBy("Department, LineOfBusiness, IncomeItem, DimensionOfRevenue, DateRecord");
	Return (Table.Count() < 2);
	
EndFunction

&AtServer
Function CorRevenueLinesAreSame()
	
	Table = Object.OtherIncome.Unload(,);
	Table.GroupBy("DebitBusinessUnit, CorLineOfBusiness, CorIncomeItem, CorIncomeDimension");
	Return (Table.Count() < 2);
	
EndFunction

// Recalculate AIT amount.
// 
// Parameters:
//  ThisIsAITAmountField - Boolean - AIT amount field flag.
&AtClient
Procedure RecalculateAITAmount(ThisIsAITAmountField = False)
	
	TableRow = Items.OtherExpenses.CurrentData;
	
	// We check the accounting for AIT for the organization.
	RecordsAreKeptAccordingToAIT = RecordsAreKeptAccordingToAIT(Object.Date, Object.Organization);
	If Not RecordsAreKeptAccordingToAIT Then
		TableRow.AITAmount = 0;
		Return;
	EndIf;
	
	// If we edit the AIT amount field, it is not recalculated.
	If ThisIsAITAmountField Then
		Return;
	EndIf;
	
	If ValueIsFilled(TableRow.CorExpenseItem)
	 And ItemOfExpensesIsRecognizedInAITExpenses(TableRow.CorExpenseItem) 
	 And RecordsAreKeptAccordingToAIT Then
		TableRow.AITAmount = TableRow.AmountFA;
	ElsIf Not ValueIsFilled(TableRow.CorExpenseItem)
	 And ItemOfExpensesIsRecognizedInAITExpenses(TableRow.ExpenseItem) 
	 And RecordsAreKeptAccordingToAIT Then
		TableRow.AITAmount = TableRow.AmountFA;
	Else
		TableRow.AITAmount = 0;
	EndIf;
	
EndProcedure

// Checking the item of expenses for recognition in AIT expenses.
// 
// Parameters:
//  ArticleForVerification - ChartOfCharacteristicTypesRef.ExpenseItems
// 
// Returns:
//  Boolean - True if the expense item is recognized in AIT expenses.
&AtServerNoContext
Function ItemOfExpensesIsRecognizedInAITExpenses(ArticleForVerification)
	
	Return CalculationOfCostLocalization.ItemOfExpensesIsRecognizedInAITExpenses(ArticleForVerification);
	
EndFunction

// Checking the accounting for AIT.
// 
// Parameters:
//  Period - Date - document date.
//  Organization - CatalogRef.Companies - auditee.
// 
// Returns:
//  Boolean - a sign of accounting by personal data.
&AtServerNoContext
Function RecordsAreKeptAccordingToAIT(Period, Organization)
	
	Return CalculationOfCostLocalization.RecordsAreKeptAccordingToAIT(Period, Organization);
	
EndFunction

&AtServer
Procedure RefreshFormTitle()
	
	If ValueIsFilled(Object.Ref) Then
		Template = NStr("vi = '%1 %2 ngày %3';
						|ru = '%1 %2 от %3';
						|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
						|it = '%1 %2 del %3';
						|pl = '%1 %2 z dnia %3';
						|tr = '%3 tarihli %1 %2'");
	Else
		Template = NStr("vi = '%1 (tạo mới)';
						|ru = '%1 (создание)';
						|en = '%1 (Create)'; fa = '%1 (Create)';
						|it = '%1 (creazione)';
						|pl = '%1 (utworzenie)';
						|tr = '%1 (oluşturma)'");
	EndIf;
	PresentationOperation = Documents.OtherIncomeExpenses.TransactionList().FindByValue(Object.BusinessOperation);
	If PresentationOperation <> Undefined Then
		PresentationOperation = PresentationOperation.Presentation;
	Else
		PresentationOperation = Object.BusinessOperation;
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
					Template, PresentationOperation, Object.Number, Object.Date);

EndProcedure

&AtClient
Procedure SumOnChange(Item, TSName)
	
	CurrentData = Items[TSName].CurrentData;
	If ValueIsFilled(CurrentData.Sum) Then
		CurrentData.SumMan = CurrentData.Sum;
		CurrentData.SumCompl = CurrentData.Sum * FactorOfConversionToCurrencyOfRegul;
		LocalAmountOnChange(Item, TSName);
		CalculateTotals_();
	EndIf;
	
EndProcedure

&AtClient
Procedure LocalAmountOnChange(Item, TSName)
	TableRow = Items[TSName].CurrentData;
	If TableRow.EnteredInTaxAccounting Then
		TableRow.AmountFA = TableRow.SumCompl;
		TableRow.PermanentDifference = 0;
		TableRow.CostTD = 0;
	Else
		TableRow.AmountFA = 0;
		TableRow.PermanentDifference = TableRow.SumCompl;
		TableRow.CostTD = 0;
	EndIf;
EndProcedure

&AtClient
Procedure AmountIsTAOnChange(Item, TSName)
	TableRow = Items[TSName].CurrentData;
	TableRow.CostTD = TableRow.SumCompl - TableRow.AmountFA - TableRow.PermanentDifference;
EndProcedure

&AtClient
Procedure PermanentDifferenceOnChange(Item, TSName)
	TableRow = Items[TSName].CurrentData;
	TableRow.CostTD = TableRow.SumCompl - TableRow.AmountFA - TableRow.PermanentDifference;
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

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


#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("TypeOfAccrualDeduction", TypeOfAccrualDeduction); 
	Parameters.Property("FilterDate",             FilterDate); 
	Parameters.Property("Department",   Department); 
	Parameters.Property("Employee",       Employee); 
	Parameters.Property("DocumentCalculation", DocumentCalculation); 
	Parameters.Property("SelectionLevel",   SelectionLevel); 
	Parameters.Property("EditingFormIsProhibited",  EditingFormIsProhibited); 
	
	SelectionLevels = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels();
	
	FillingSettings = New Structure("PostingOption");
	
	If SelectionLevel = SelectionLevels.DivisionLevel Then
		
		ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();
		
		Items.GroupTypesOfForms.CurrentPage = Items.GroupFormToFillIn;
		
		ValidityStartDate = BegOfMonth(CurrentSessionDate());
		
		FillParameters = 
			InformationRegisters.SettingOfPostingInAccountingHR.CaseSelectionParameters();
		FillParameters.TypeOfAccrualDeduction = TypeOfAccrualDeduction; 
		FillParameters.Employee =              Employee; 
		FillParameters.Department =          Department; 
		FillParameters.DocumentCalculation =        DocumentCalculation; 
	
		RegisterSelectionData = InformationRegisters.SettingOfPostingInAccountingHR.CaseSensitiveValues(
																					FillParameters, FilterDate);
		
		If RegisterSelectionData.DataReceived Then
			StructureOfData = RegisterSelectionData.StructureOfData;	
			ValidityStartDate = StructureOfData.Period;	
		Else																				
			ValidityStartDate = BegOfMonth(Constants.StartDatePayrollAndHumanResources.Get());
		EndIf;
		
		FillFormAttributes(ValidityStartDate);
		
		PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses;
		// A selection of articles and analyst
		ArticleSelectionAndAnalyticsOptions = ArticleSelectionAndAnalyticsOptionsForDivision();
		If ValueIsFilled(ArticleSelectionAndAnalyticsOptions) Then
			IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ArticleSelectionAndAnalyticsOptions);
		EndIf;
		// End Selection of articles and analysts
		
		SetAutoSelectAnalyticsHint(ExpenseItem, Items.AnalyticsOfFillingCosts.Name);
		SetAutoSelectAnalyticsHint(IncomeItem, Items.RevenueAnalyticsFillIn.Name);
		
	Else	
		
		Items.GroupTypesOfForms.CurrentPage = Items.GroupFormOfReflectionInAccounting;
		
		If SelectionLevel = SelectionLevels.ManualTaxLevel Then
			ItIsADeduction = False;
			
			FillingSettings 
			= SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetSettingsByTaxType(
			TypeOfAccrualDeduction, Employee, Department, DocumentCalculation, FilterDate);		
			
		Else	
			ItIsADeduction = 
			Common.ObjectAttributeValue(TypeOfAccrualDeduction, "ItIsADeduction"); 
			
			FillingSettings 
			= SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetAccrualRetentionSettings(TypeOfAccrualDeduction, FilterDate);		
			
		EndIf;	
		
		If Not ValueIsFilled(FillingSettings.PostingOption) Then
			
			If ItIsADeduction Then
				PostingOption =
				PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome");
			Else	
				PostingOption =
				PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses");
			EndIf;		
		Else     
			PostingOption = FillingSettings.PostingOption;	
		EndIf;	
		
		If ItIsADeduction Then
			ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingDeductions();
		Else
			ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();
		EndIf;	
		
		If ReflectionOptions = Undefined Then
			Cancel = True;
			Return;
		EndIf;
		
		For Each ListItem In ReflectionOptions Do
			ReflectionOptionParameters = ListItem.Value;
			If ReflectionOptionParameters.Used Then
				Items.PostingOption.ChoiceList.Add(ListItem.Key);
			EndIf;
		EndDo;
		
		If SelectionLevel = SelectionLevels.AccrualRetentionLevel Then  
			
			ValidityStartDate = BegOfMonth(CurrentSessionDate());

			FillParameters = 
				InformationRegisters.SettingOfPostingInAccountingHR.CaseSelectionParameters();
			FillParameters.TypeOfAccrualDeduction = TypeOfAccrualDeduction; 
			FillParameters.Employee =              Employee; 
			FillParameters.Department =          Department; 
			FillParameters.DocumentCalculation =        DocumentCalculation; 
			
			RegisterSelectionData = InformationRegisters.SettingOfPostingInAccountingHR.CaseSensitiveValues(
																					FillParameters, FilterDate);
		
			If RegisterSelectionData.DataReceived Then
				StructureOfData = RegisterSelectionData.StructureOfData;	
				ValidityStartDate = StructureOfData.Period;	
			Else																				
				ValidityStartDate = BegOfMonth(Constants.StartDatePayrollAndHumanResources.Get());
			EndIf;
		Else
			ValidityStartDate = FilterDate; 
		EndIf;	
		
		FillFormAttributes(FilterDate);
		
		// A selection of articles and analyst
		ArticleSelectionAndAnalyticsOptions = ArticleSelectionAndAnalyticsOptions();
		If ValueIsFilled(ArticleSelectionAndAnalyticsOptions) Then
			IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ArticleSelectionAndAnalyticsOptions);
		EndIf;
		// End Selection of articles and analysts
		
		// Setting up accounting accounts
		AccountingAccountSettings_ = AccountingAccountSettings_();
		If ValueIsFilled(AccountingAccountSettings_) Then
			GLAccountSettingsServer.OnCreateAtServer(ThisObject, AccountingAccountSettings_);
		EndIf;
		// End Setting Up Accounting Accounts
		
		SetAutoSelectAnalyticsHint(ExpenseItem, Items.DimensionOfExpenses.Name);
		SetAutoSelectAnalyticsHint(IncomeItem, Items.DimensionOfRevenue.Name);

		ManagingFormOfReflectionInAccounting();
		
	EndIf;
		
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	ProcessingSelectionOnServer(ValueSelected);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ValidityStartDatePresentationStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("PresentationOfStartDateOfActionBeginningOfSelectionEnd", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", ValidityStartDate, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ValidityStartDatePresentationTuning(Item, Direction, StandardProcessing)
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		ValidityStartDate,
		ValidityStartDatePresentation);
	
	ValidityStartDatePresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(ValidityStartDate);
	
	UpdateFormDetailsATServer();
	
EndProcedure

&AtClient
Procedure PostingOptionOnChange(Item)
	OptionToReflectWhenChangingOnServer();
EndProcedure

&AtClient
Procedure ItemOfIncomeAndExpensesStartOfSelection(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	SetAutoSelectAnalyticsHint(ExpenseItem, Items.DimensionOfExpenses.Name);
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	SetAutoSelectAnalyticsHint(IncomeItem, Items.DimensionOfRevenue.Name);
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfRevenueOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfRevenueOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure AssetsLiabilitiesDimensionOnChange(Item)
	IncomeAndExpensesClientServer.AssetsLiabilitiesDimensionOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure SettingUpAccountingAccountsViewClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterValues = New Structure;
	FilterValues.Insert("PaymentType_",
		PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"));
	FilterValues.Insert("Counterparty",  Counterparty);
	
	SelectionSettings_ = New Structure;
	SelectionSettings_.Insert("SelectAccountsReceivable", True);
	SelectionSettings_.Insert("Filter", FilterValues);
	SelectionSettings_.Insert("CurrentRow", ARAPObject);
	
	OpenForm("Catalog.ARAPObjects.ChoiceForm", SelectionSettings_, Item);
	
EndProcedure

&AtClient
Procedure ARAPObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Text) Then
		CalculationObjectProcessingOfSelectionDataAcquisition(ChoiceData, Organization, Counterparty, Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPObjectTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Text) Then
		CalculationObjectProcessingOfSelectionDataAcquisition(ChoiceData, Organization, Counterparty, Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure HistoryOfChangeClick(Item)
	
	AdditionalParameters = New Structure;
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfAccrualDeduction", TypeOfAccrualDeduction);
	FormParameters.Insert("Employee",              Employee);
	FormParameters.Insert("Department",          Department);
	FormParameters.Insert("DocumentCalculation",        DocumentCalculation);
	FormParameters.Insert("SelectionLevel",          SelectionLevel);
	
	ClosingNotification1 = New CallbackDescription("EditHistoryCompletion", ThisObject, AdditionalParameters);
	
	OpenForm("InformationRegister.SettingOfPostingInAccountingHR.Form.EditHistory",
		FormParameters, ThisObject, , , , ClosingNotification1);
	
EndProcedure

&AtClient
Procedure ExpenseAssetLiabilityItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	SetAutoSelectAnalyticsHint(ExpenseAssetLiabilityItem, Items.ExpenseAssetLiabilityItem.Name);
	
EndProcedure

&AtClient
Procedure ItemOfExpensesOfFillingOnChange(Item)
	
	PostingOption = PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses");
	ReflectionOptionOnChangeInDivisionAtServer();
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	SetAutoSelectAnalyticsHint(ExpenseItem, Items.AnalyticsOfFillingCosts.Name);
	
EndProcedure

&AtClient
Procedure ItemOfExpensesOfFillingStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure IncomeItemFillingStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	PostingOption = PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome");
	ReflectionOptionOnChangeInDivisionAtServer();
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure IncomeItemFillingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	SetAutoSelectAnalyticsHint(IncomeItem, Items.DimensionOfRevenue.Name);
	
EndProcedure

&AtClient
Procedure RevenueAnalyticsFillInOnChange(Item)
	
	IncomeAndExpensesClientServer.DimensionOfRevenueOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AnalyticsOfFillingCostsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OKButton(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;	
	
	WriteAtServer();
	
	If SelectionLevel <> SelectionLevels.DivisionLevel Then
		ReflectionOptionParameters = ReflectionOptions[PostingOption];
		If Not ReflectionOptionParameters = Undefined Then
			Result = New Structure("PostingOption," + ReflectionOptionParameters.Attributes);
			FillPropertyValues(Result, ThisObject);
		Else
			Result = New Structure("PostingOption", PostingOption);
		EndIf;                                                                                      
	Else		
		Result = New Structure("PostingOption", 
				PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses"));	
	EndIf;
	
	Close(Result);
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ProcessingSelectionOnServer(ValueSelected)
	
	ValidityStartDate = ValueSelected.Period;
	
	FillFormAttributes(ValidityStartDate);
	
	// A selection of articles and analyst
	ArticleSelectionAndAnalyticsOptions = ArticleSelectionAndAnalyticsOptions();
	If ValueIsFilled(ArticleSelectionAndAnalyticsOptions) Then
		IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ArticleSelectionAndAnalyticsOptions);
	EndIf;
	// End Selection of articles and analysts
	
	// Setting up accounting accounts
	AccountingAccountSettings_ = AccountingAccountSettings_();
	If ValueIsFilled(AccountingAccountSettings_) Then
		GLAccountSettingsServer.OnCreateAtServer(ThisObject, AccountingAccountSettings_);
	EndIf;
	// End Setting Up Accounting Accounts
	
	SetAutoSelectAnalyticsHint(ExpenseItem, Items.DimensionOfExpenses.Name);
	SetAutoSelectAnalyticsHint(IncomeItem, Items.DimensionOfRevenue.Name);
	
	ManagingFormOfReflectionInAccounting();
	
EndProcedure	

&AtServer
Procedure WriteAtServer()
	
	If PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities Then
		GLAccountSettingsServer.RecordFormSInvoiceSettings(ThisObject);
	EndIf;
	
	StructureOfData = InformationRegisters.SettingOfPostingInAccountingHR.DataStructureForRecord();
	FillPropertyValues(StructureOfData, ThisObject); 
	StructureOfData.Period = ValidityStartDate;   
	If SelectionLevel = SelectionLevels.DivisionLevel
		Or SelectionLevel = SelectionLevels.AccrualRetentionLevel Then
		StructureOfData.Period = BegOfMonth(StructureOfData.Period);
	EndIf;
	
	If InformationRegisters.SettingOfPostingInAccountingHR.MeasurementDataIsEmpty(StructureOfData) Then
		
		InformationRegisters.SettingOfPostingInAccountingHR.DeleteData(StructureOfData);

	Else	
	
		InformationRegisters.SettingOfPostingInAccountingHR.WriteData(StructureOfData);
	EndIf;	
	
EndProcedure

&AtServer
Procedure OptionToReflectWhenChangingOnServer()
	
	// A selection of articles and analyst
	ArticleSelectionAndAnalyticsOptions = ArticleSelectionAndAnalyticsOptions();
	If ValueIsFilled(ArticleSelectionAndAnalyticsOptions) Then
		IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ArticleSelectionAndAnalyticsOptions);
	EndIf;
	// End Selection of articles and analysts
	
	// Setting up accounting accounts
	AccountingAccountSettings_ = AccountingAccountSettings_();
	If ValueIsFilled(AccountingAccountSettings_) Then
		GLAccountSettingsServer.WhenChangingSettings(ThisObject, AccountingAccountSettings_);
	EndIf;
	// End Setting Up Accounting Accounts
	
	ManagingFormOfReflectionInAccounting();
	
EndProcedure

&AtServer
Procedure ReflectionOptionOnChangeInDivisionAtServer()
	
	If PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome Then
		ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingDeductions();                
	Else
		ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();                
	EndIf;
	
	// A selection of articles and analyst
	ArticleSelectionAndAnalyticsOptions = ArticleSelectionAndAnalyticsOptionsForDivision();
	If ValueIsFilled(ArticleSelectionAndAnalyticsOptions) Then
		IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ArticleSelectionAndAnalyticsOptions);
	EndIf;
	// End Selection of articles and analysts
	
	//Setting up accounting accounts
	//Account Setting parametersaccount = Account Settings parametersaccount();
	//If the value is filled in (Account Setting parametersaccount) Then
	//	customizationcountcountservers.When you change the settings parameters (this is an object, Account Account settings parametersreferences);
	//The end if;
	//End Setting up Accounting Accounts
	
	ManagingFormOfReflectionInAccounting();
	
EndProcedure

&AtServer
Procedure UpdateFormDetailsATServer()
	
	FillFormAttributes(ValidityStartDate);
	ManagingFormOfReflectionInAccounting();
	
	
EndProcedure	

&AtClient
Procedure EditHistoryCompletion(Result, AdditionalParameters) Export

	FillFormAttributes(FilterDate);
	
EndProcedure

&AtServer
Procedure FillFormAttributes(FilterDate)
	
	FillParameters = 
		InformationRegisters.SettingOfPostingInAccountingHR.CaseSelectionParameters();
	FillParameters.TypeOfAccrualDeduction = TypeOfAccrualDeduction; 
	FillParameters.Employee =              Employee; 
	FillParameters.Department =          Department; 
	FillParameters.DocumentCalculation =        DocumentCalculation; 
	
	RegisterSelectionData = InformationRegisters.SettingOfPostingInAccountingHR.CaseSensitiveValues(
																					FillParameters, FilterDate);
	If RegisterSelectionData.DataReceived Then
		FillPropertyValues(ThisObject, RegisterSelectionData.StructureOfData, ,
						"PostingOption,TypeOfAccrualDeduction,Department,Employee,DocumentCalculation" );  
		ExpenseLedgerAccountsSettingsPresentation = ExpenseLedgerAccountsSettings;
		IncomeLedgerAccountsSettingsPresentation =  IncomeLedgerAccountsSettings;
						
	Else
		
		ClearAllFormFields();					
		
		If Not ValueIsFilled(PostingOption) Then
			If ItIsADeduction Then
				PostingOption =
				PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome");
			Else	
				PostingOption =
				PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses");
			EndIf;		
		EndIf;	
		
	EndIf;	
		
	ValidityStartDatePresentation = 
		MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(ValidityStartDate);
		
	Items.LineOfBusinessOfFilling.Visible = 
		GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
EndProcedure

&AtServer
Procedure ClearAllFormFields()
	
	AllocationBaseType = Enums.TypesOfCostAllocatingBase.EmptyRef();
	ProductCostElement = Catalogs.ProductCostElements.EmptyRef();
	LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
	ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	ExpenseAssetLiabilityItem = ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef();
	IncomeItem = ChartsOfCharacteristicTypes.IncomeItems.EmptyRef();
	IncomeAssetLiabilityItem = ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef();
	DimensionOfExpensesAssetsLiabilities = "";
	DimensionOfIncomeAssetsLiabilities = "";
	IncomeLedgerAccountsSettings = Catalogs.OtherTransactionsGLAccountsSettings.EmptyRef();
	ExpenseLedgerAccountsSettings = Catalogs.OtherTransactionsGLAccountsSettings.EmptyRef();
	Counterparty = Catalogs.Counterparties.EmptyRef();
	IssuancePurpose = Catalogs.CashFlowReportItems.EmptyRef();
	ARAPObject = Catalogs.ARAPObjects.EmptyRef(); 
	
EndProcedure	

&AtServer
Procedure ManagingFormOfReflectionInAccounting()
	
	Items.PostingOption.ToolTip = "";
	Items.LineOfBusiness.Visible = False;
	
	Items.AccrualsItemByItemReflection.Visible        = False;
	Items.AccrualsDistributionForProduction.Visible = False;
	Items.AccrualOfAssetsLiabilities.Visible				 = False;
	Items.RetentionLineByLineReflection.Visible         = False;
	Items.DeductionOfRepaymentOfMutual.Visible      = False;
	Items.DeductionsSettlementsWithAccountablePersons.Visible       = False;
	Items.RetentionAssetsLiabilities.Visible   		     = False;
	
	If SelectionLevel <> SelectionLevels.DivisionLevel Then
		
		ReflectionOptionParameters = ReflectionOptions[PostingOption];
		If ReflectionOptionParameters = Undefined Then
			Return;
		EndIf;
		
		Items.PostingOption.ToolTip = ReflectionOptionParameters.OptionDetails;
		
		If ReflectionOptionParameters.AttributeProperties.Property("AllocationBaseType") Then
			Items.AccrualsDistributionForProduction.Visible = True;
		ElsIf ReflectionOptionParameters.AttributeProperties.Property("ExpenseItem") Then
			Items.AccrualsItemByItemReflection.Visible = True;
		ElsIf ReflectionOptionParameters.AttributeProperties.Property("ExpenseAssetLiabilityItem") Then
			Items.AccrualOfAssetsLiabilities.Visible = True;
		ElsIf ReflectionOptionParameters.AttributeProperties.Property("IncomeItem") Then
			Items.RetentionLineByLineReflection.Visible = True;
		ElsIf ReflectionOptionParameters.AttributeProperties.Property("IncomeAssetLiabilityItem") Then
			Items.RetentionAssetsLiabilities.Visible = True;
		ElsIf ReflectionOptionParameters.AttributeProperties.Property("Counterparty") Then
			Items.DeductionOfRepaymentOfMutual.Visible = True;
		ElsIf ReflectionOptionParameters.AttributeProperties.Property("IssuancePurpose") Then
			Items.DeductionsSettlementsWithAccountablePersons.Visible = True;
		EndIf;
		
		Items.LineOfBusiness.Visible =
			ReflectionOptionParameters.AttributeProperties.Property("LineOfBusiness")
			And ReflectionOptionParameters.AttributeProperties.LineOfBusiness.Used;
			
	Else
		Items.LineOfBusiness.Visible =
						GetFunctionalOption("UseCostAccountingByLinesOfBusiness");		
	EndIf;
		
	ThisIsPersonnelDocumentsLevel = SelectionLevel = SelectionLevels.LevelPersonnelDocuments;
	ThisIsOneTimeDocumentsLevel = SelectionLevel = SelectionLevels.LevelOneTimeDocuments;
	ThisIsManualTaxLevel = SelectionLevel = SelectionLevels.ManualTaxLevel;
	
	If ThisIsPersonnelDocumentsLevel Then
		Items.GroupOperatesWith.Visible = False;
		Items.PostingOption.ReadOnly = True;
	ElsIf ThisIsOneTimeDocumentsLevel Then
		Items.GroupOperatesWith.Visible = False;
		Items.PostingOption.ReadOnly = True;
	ElsIf ThisIsManualTaxLevel Then
		Items.GroupOperatesWith.Visible = False;
	EndIf;	
	
	CheckAvailabilityOfFormElements();
	
EndProcedure

&AtServer
Function ArticleSelectionAndAnalyticsOptionsForDivision()
	
	ParametersArray = New Array;
	
	ReflectionOptionParameters = ReflectionOptions[PostingOption];
	If ReflectionOptionParameters = Undefined Then
		Return ParametersArray;
	EndIf;
	
	If ReflectionOptionParameters.AttributeProperties.Property("ExpenseItem") Then
		ChoiceParameters = ParametersForSelectingExpenseItemForDivision();
		ChoiceParameters.ChoosingExpenseItem =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses;
		ChoiceParameters.SelectingItemOfAssetsLiabilities =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities;
		ParametersArray.Add(ChoiceParameters);
	ElsIf ReflectionOptionParameters.AttributeProperties.Property("ExpenseAssetLiabilityItem") Then
		ChoiceParameters = ParametersForSelectingItemOfExpenditureAssetsLiabilitiesForDivision();
		ChoiceParameters.ChoosingExpenseItem =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses;
		ChoiceParameters.SelectingItemOfAssetsLiabilities =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities;
		ParametersArray.Add(ChoiceParameters);
	EndIf;
	
	If ReflectionOptionParameters.AttributeProperties.Property("IncomeItem") Then
		ChoiceParameters = ParametersForSelectingIncomeItemForDivision();
		ChoiceParameters.ChoosingIncomeItem =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome;
		ChoiceParameters.SelectingItemOfAssetsLiabilities =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities;
		ParametersArray.Add(ChoiceParameters);
	ElsIf ReflectionOptionParameters.AttributeProperties.Property("IncomeAssetLiabilityItem") Then
		ChoiceParameters = ParametersForSelectingItemOfIncomeAssetsLiabilitiesForDivision();
		ChoiceParameters.ChoosingIncomeItem =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome;
		ChoiceParameters.SelectingItemOfAssetsLiabilities =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities;
		ParametersArray.Add(ChoiceParameters);
	EndIf;
	
	Return ParametersArray;
	
EndFunction	

&AtServer
Procedure CheckAvailabilityOfFormElements()
	
	If Not EditingFormIsProhibited Then
		Return;
	EndIf;	
	
	For Each FormItem In Items Do
		
		ElementType = TypeOf(FormItem);
		
		If ElementType = Type("FormField") Then 
			FormItem.ReadOnly = True;  

		ElsIf ElementType = Type("FormButton") Then
			FormItem.Enabled = False;
		EndIf; 
		
	EndDo;		
	
	Items.SettingUpAccrualAccountingAccounts.Enabled = False;
	Items.SettingUpDeductionAccountingAccounts.Enabled = False;
	
EndProcedure	

&AtServer
Function ArticleSelectionAndAnalyticsOptions()
	
	ParametersArray = New Array;
	
	ReflectionOptionParameters = ReflectionOptions[PostingOption];
	If ReflectionOptionParameters = Undefined Then
		Return ParametersArray;
	EndIf;
	
	If ReflectionOptionParameters.AttributeProperties.Property("ExpenseItem") Then
		ChoiceParameters = ParametersForSelectingExpenseItem();
		ChoiceParameters.ChoosingExpenseItem =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses;
		ChoiceParameters.SelectingItemOfAssetsLiabilities =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities;
		ParametersArray.Add(ChoiceParameters);
	ElsIf ReflectionOptionParameters.AttributeProperties.Property("ExpenseAssetLiabilityItem") Then
		ChoiceParameters = ParametersForSelectingItemOfExpenditureAssetsLiabilities();
		ChoiceParameters.ChoosingExpenseItem =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses;
		ChoiceParameters.SelectingItemOfAssetsLiabilities =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities;
		ParametersArray.Add(ChoiceParameters);
	EndIf;
	
	If ReflectionOptionParameters.AttributeProperties.Property("IncomeItem") Then
		ChoiceParameters = IncomeItemSelectionParameters();
		ChoiceParameters.ChoosingIncomeItem =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome;
		ChoiceParameters.SelectingItemOfAssetsLiabilities =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities;
		ParametersArray.Add(ChoiceParameters);
	ElsIf ReflectionOptionParameters.AttributeProperties.Property("IncomeAssetLiabilityItem") Then
		ChoiceParameters = ParametersForSelectingItemOfIncomeAssetsLiabilities();
		ChoiceParameters.ChoosingIncomeItem =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome;
		ChoiceParameters.SelectingItemOfAssetsLiabilities =
			PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities;
		ParametersArray.Add(ChoiceParameters);
	EndIf;
	
	Return ParametersArray;
	
EndFunction

&AtServerNoContext
Function ParametersForSelectingExpenseItem()
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionOfExpensesAssetsLiabilities";
	
	ChoiceParameters.ArticleType = "TypeOfExpenditureItem";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionOfAssets");
	
	Return ChoiceParameters;
	
EndFunction

&AtServerNoContext
Function ParametersForSelectingExpenseItemForDivision()
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionOfExpensesAssetsLiabilities";
	
	ChoiceParameters.ArticleType = "TypeOfExpenditureItem";
	
	ChoiceParameters.FormItems.AssetRef.Add("ItemOfExpensesOfFilling");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("AnalyticsOfFillingCosts");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionOfAssets");
	
	Return ChoiceParameters;
	
EndFunction

&AtServer
Function ParametersForSelectingItemOfExpenditureAssetsLiabilitiesForDivision()
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.AssetRef = "ExpenseAssetLiabilityItem";
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionOfExpensesAssetsLiabilities";
	
	ChoiceParameters.ArticleType = "TypeOfExpenditureItem";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseAssetLiabilityItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionOfAssets");
	
	Return ChoiceParameters;
	
EndFunction

&AtServer
Function ParametersForSelectingItemOfExpenditureAssetsLiabilities()
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.AssetRef = "ExpenseAssetLiabilityItem";
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionOfExpensesAssetsLiabilities";
	
	ChoiceParameters.ArticleType = "TypeOfExpenditureItem";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseAssetLiabilityItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionOfAssets");
	
	Return ChoiceParameters;
	
EndFunction

&AtServerNoContext
Function ParametersForSelectingIncomeItemForDivision()
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionOfIncomeAssetsLiabilities";
	
	ChoiceParameters.ArticleType = "TypeOfIncomeItem";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItemFilling");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("RevenueAnalyticsFillIn");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionLiabilities_");
	
	Return ChoiceParameters;
	
EndFunction

&AtServerNoContext
Function IncomeItemSelectionParameters()
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionOfIncomeAssetsLiabilities";
	
	ChoiceParameters.ArticleType = "TypeOfIncomeItem";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionLiabilities_");
	
	Return ChoiceParameters;
	
EndFunction

&AtServerNoContext
Function ParametersForSelectingItemOfIncomeAssetsLiabilitiesForDivision()
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.AssetRef = "ExpenseAssetLiabilityItem";
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionOfIncomeAssetsLiabilities";
	
	ChoiceParameters.ArticleType = "TypeOfIncomeItem";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseAssetLiabilityItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionLiabilities_");
	
	Return ChoiceParameters;
	
EndFunction

&AtServerNoContext
Function ParametersForSelectingItemOfIncomeAssetsLiabilities()
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.AssetRef = "ExpenseAssetLiabilityItem";
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionOfIncomeAssetsLiabilities";
	
	ChoiceParameters.ArticleType = "TypeOfIncomeItem";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseAssetLiabilityItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionLiabilities_");
	
	Return ChoiceParameters;
	
EndFunction

&AtServer
Function AccountingAccountSettings_()
	
	ParametersArray = New Array;
	
	ReflectionOptionParameters = ReflectionOptions[PostingOption];
	If ReflectionOptionParameters = Undefined Then
		Return ParametersArray;
	EndIf;
	
	If ReflectionOptionParameters.AttributeProperties.Property("ExpenseItem")
		Or ReflectionOptionParameters.AttributeProperties.Property("ExpenseAssetLiabilityItem") Then
		
		SetupParameters = GLAccountSettingsServer.SetupParameters();
		SetupParameters.GLAccountSettings = "ExpenseLedgerAccountsSettings"; 
		SetupParameters.AssetsLiabilitiesDimension = "DimensionOfExpensesAssetsLiabilities";
		SetupParameters.AssetAndLiabilityItem = "ExpenseAssetLiabilityItem";
		SetupParameters.Presentation = "ExpenseLedgerAccountsSettingsPresentation";
		SetupParameters.ArticleType = "TypeOfExpenditureItem";
		
		SetupParameters.Organization = "Organization";
		
		SetupParameters.ExtDimensionSelectionSources.Add(Type("CatalogRef.Companies"),          "Organization");
		SetupParameters.ExtDimensionSelectionSources.Add(Type("CatalogRef.BusinessStructure"), "Department");
		SetupParameters.ExtDimensionSelectionSources.Add(Type("CatalogRef.Persons"),       "Individual");
		
		SetupParameters.FormItems.Add("SettingUpAccrualAccountingAccounts");
		ParametersArray.Add(SetupParameters);
		
	EndIf;
	
	If ReflectionOptionParameters.AttributeProperties.Property("IncomeItem")
		Or ReflectionOptionParameters.AttributeProperties.Property("IncomeAssetLiabilityItem") Then
		
		SetupParameters = GLAccountSettingsServer.SetupParameters();
		SetupParameters.GLAccountSettings = "IncomeLedgerAccountsSettings";
		SetupParameters.AssetsLiabilitiesDimension = "DimensionOfIncomeAssetsLiabilities";
		SetupParameters.AssetAndLiabilityItem = "IncomeAssetLiabilityItem";
		SetupParameters.Presentation = "IncomeLedgerAccountsSettingsPresentation";
		SetupParameters.ArticleType = "TypeOfIncomeItem";
		
		SetupParameters.Organization = "Organization";
		
		SetupParameters.ExtDimensionSelectionSources.Add(Type("CatalogRef.Companies"),          "Organization");
		SetupParameters.ExtDimensionSelectionSources.Add(Type("CatalogRef.BusinessStructure"), "Department");
		
		SetupParameters.FormItems.Add("SettingUpDeductionAccountingAccounts");
		ParametersArray.Add(SetupParameters);
		
	EndIf;
	
	Return ParametersArray;
	
EndFunction

&AtServer
Procedure SetAutoSelectAnalyticsHint(AssetRef, AnalyticsElement)
	
	Items[AnalyticsElement].InputHint = "";
	If Not ValueIsFilled(AssetRef) Then
		Return;
	EndIf;
	
	ArticleProperties = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.PropertiesOfReflectionArticle(AssetRef);
	
	If ArticleProperties.AutocompletionIsAvailable Then
		Items[AnalyticsElement].InputHint = NStr("ru = '<подбирается автоматически>';
												|vi = '<picked automatically>';
												|en = '<picked automatically>'; fa = '<picked automatically>';
												|it = '<viene selezionato automaticamente>';
												|pl = '<wybierane automatycznie>';
												|tr = '<otomatik olarak seçilir>'");
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CalculationObjectProcessingOfSelectionDataAcquisition(ChoiceData, Organization, Counterparty, Text)
	
	ParametersStructure = ARAPAccountingClientServer.SelectionDataSelectionStructure();
	ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ParametersStructure.Organization = Organization;
	ParametersStructure.Counterparty  = Counterparty;
	ParametersStructure.Text       = Text;
	
	ARAPAccountingServer.FillInDataOfCalculationObjectSelection(ChoiceData, ParametersStructure);
	
EndProcedure

&AtClient
Procedure PresentationOfStartDateOfActionBeginningOfSelectionEnd(SelectedPeriod, AdditionalParameters) Export
	
	If SelectedPeriod <> Undefined Then
		
		ValidityStartDate = SelectedPeriod;
		ValidityStartDatePresentation = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(ValidityStartDate);
		
		UpdateFormDetailsATServer();
	
	EndIf;
	
EndProcedure

#EndRegion
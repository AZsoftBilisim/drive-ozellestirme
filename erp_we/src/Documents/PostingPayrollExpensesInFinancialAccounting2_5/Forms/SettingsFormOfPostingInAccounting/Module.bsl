
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ReflectionOptions", ReflectionOptions);
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
	
	Parameters.Property("Organization",     Organization);
	Parameters.Property("DocumentDate",   DocumentDate);
	Parameters.Property("DocumentCurrency", DocumentCurrency);
	
	If Parameters.Property("FillingValues") Then
		FillPropertyValues(ThisObject, Parameters.FillingValues);
	EndIf;
	
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
	
	FormControl();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Accept(Command)
	
	AcceptOnServer();
	
	ReflectionOptionParameters = ReflectionOptions[PostingOption];
	If Not ReflectionOptionParameters = Undefined Then
		Result = New Structure("PostingOption," + ReflectionOptionParameters.Attributes);
		FillPropertyValues(Result, ThisObject);
	Else
		Result = New Structure("PostingOption", PostingOption);
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtServer
Procedure AcceptOnServer()
	
	If PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities Then
		GLAccountSettingsServer.RecordFormSInvoiceSettings(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PostingOptionOnChange(Item)
	OptionToReflectWhenChangingOnServer();
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
	
	FormControl();
	
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
	FilterValues.Insert("Organization", Organization);
	FilterValues.Insert("Counterparty",  Counterparty);
	
	SelectionSettings_ = New Structure;
	SelectionSettings_.Insert("SelectAccountsReceivable", True);
	SelectionSettings_.Insert("Currency", DocumentCurrency);
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

#EndRegion

#Region Private

&AtServer
Procedure FormControl()
	
	Items.PostingOption.ToolTip = "";
	Items.LineOfBusiness.Visible = False;
	
	Items.AccrualsItemByItemReflection.Visible        = False;
	Items.AccrualsDistributionForProduction.Visible = False;
	Items.RetentionLineByLineReflection.Visible         = False;
	Items.DeductionOfRepaymentOfMutual.Visible      = False;
	Items.DeductionsSettlementsWithAccountablePersons.Visible       = False;
	
	ReflectionOptionParameters = ReflectionOptions[PostingOption];
	If ReflectionOptionParameters = Undefined Then
		Return;
	EndIf;
	
	Items.PostingOption.ToolTip = ReflectionOptionParameters.OptionDetails;
	
	If ReflectionOptionParameters.AttributeProperties.Property("AllocationBaseType") Then
		Items.AccrualsDistributionForProduction.Visible = True;
	ElsIf ReflectionOptionParameters.AttributeProperties.Property("ExpenseItem") Then
		Items.AccrualsItemByItemReflection.Visible = True;
	ElsIf ReflectionOptionParameters.AttributeProperties.Property("IncomeItem") Then
		Items.RetentionLineByLineReflection.Visible = True;
	ElsIf ReflectionOptionParameters.AttributeProperties.Property("Counterparty") Then
		Items.DeductionOfRepaymentOfMutual.Visible = True;
	ElsIf ReflectionOptionParameters.AttributeProperties.Property("IssuancePurpose") Then
		Items.DeductionsSettlementsWithAccountablePersons.Visible = True;
	EndIf;
	
	Items.LineOfBusiness.Visible =
		ReflectionOptionParameters.AttributeProperties.Property("LineOfBusiness")
		And ReflectionOptionParameters.AttributeProperties.LineOfBusiness.Used;
	
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
	EndIf;
	
	If ReflectionOptionParameters.AttributeProperties.Property("IncomeItem") Then
		ChoiceParameters = IncomeItemSelectionParameters();
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
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.ArticleType = "TypeOfExpenditureItem";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionOfAssets");
	
	Return ChoiceParameters;
	
EndFunction

&AtServerNoContext
Function IncomeItemSelectionParameters()
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.ArticleType = "TypeOfIncomeItem";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
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
	
	If ReflectionOptionParameters.AttributeProperties.Property("ExpenseItem") Then
		
		SetupParameters = GLAccountSettingsServer.SetupParameters();
		SetupParameters.AssetAndLiabilityItem = "ExpenseItem";
		SetupParameters.Presentation = "GLAccountSettingsPresentation";
		SetupParameters.ArticleType = "TypeOfExpenditureItem";
		
		SetupParameters.Organization = "Organization";
		
		SetupParameters.ExtDimensionSelectionSources.Add(Type("CatalogRef.Companies"),          "Organization");
		SetupParameters.ExtDimensionSelectionSources.Add(Type("CatalogRef.BusinessStructure"), "Department");
		SetupParameters.ExtDimensionSelectionSources.Add(Type("CatalogRef.Persons"),       "Individual");
		
		SetupParameters.FormItems.Add("SettingUpAccrualAccountingAccounts");
		ParametersArray.Add(SetupParameters);
		
	EndIf;
	
	If ReflectionOptionParameters.AttributeProperties.Property("IncomeItem") Then
		
		SetupParameters = GLAccountSettingsServer.SetupParameters();
		SetupParameters.AssetAndLiabilityItem = "IncomeItem";
		SetupParameters.Presentation = "GLAccountSettingsPresentation";
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
	
	ArticleProperties = Documents.PostingPayrollExpensesInFinancialAccounting2_5.PropertiesOfReflectionArticle(AssetRef);
	
	If ArticleProperties.AutocompletionIsAvailable Then
		Items[AnalyticsElement].InputHint = NStr("vi = '<được chọn tự động>';
												|ru = '<подбирается автоматически>';
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

#EndRegion
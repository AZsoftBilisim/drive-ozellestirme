#Region Public

// Performs the processing of the form opening navigation link, called from the form event handler of the same name.
//
// Parameters:
//	Form - ClientApplicationForm - the form from which the procedure is called from the event handler.
//	FormattedStringURL - String - navigation link string
//	StandardProcessing - Boolean - a sign of the standard event processing
//
Procedure URLProcessing(Form, FormattedStringURL, StandardProcessing) Export
	
	
EndProcedure

// Processes the closing of the account setup form.
// Called in the object form's callback() handler.
// 
// Parameters:
// 	Form - ClientApplicationForm - object form
// 	EventName - String - Name of the alert event
// 	Parameter - Arbitrary - Notification parameter 
//
Procedure FinishedSettingUpAccountingAccounts(Form, EventName, Parameter) Export
EndProcedure

// Performs the processing of the navigation links to open the form invoice settings.
// 
// Parameters:
// 	Form - ClientApplicationForm - object form
// 	URL - String - Navigation links
// 	StandardProcessing - Boolean - standard event Processing flag
//
Procedure ProcessingNavigationLinkSettingUpAccountingAccounts(Form, URL, StandardProcessing) Export
EndProcedure

// Performs the processing of changing the accounts accounting analysts accounting.
// 
// Parameters:
// 	Item - FormField - Element (input field) of the accounting account settings
// 	Form - ClientApplicationForm - The shape of the object settings
//
Procedure OnChange(Item, Form) Export
EndProcedure

// Performs the processing of the beginning of the selection of the account settings.
// 
// Parameters:
// 	Form - ClientApplicationForm - The shape of the object settings
// 	Item - FormField - Element (input field) of the accounting account settings
// 	ChoiceData - Array of CatalogRef - what is selected
// 	StandardProcessing - Boolean - indicates that standard processing is required
// 	CloseHandler - CallbackDescription - the handler to be called at the End of the selection.
//
Procedure StartChoice(Form, Item, ChoiceData, StandardProcessing, CloseHandler = Undefined) Export
EndProcedure

// Performs the processing of the beginning of the selection of the account settings.
// 
// Parameters:
// 	Form - ClientApplicationForm - The shape of the object settings
// 	Item - FormField - Element (input field) of the accounting account settings
// 	Direction - Number - regulation step
// 	StandardProcessing - Boolean - indicates that standard processing is required
//
Procedure Tuning(Form, Item, Direction, StandardProcessing) Export
EndProcedure

// Performs the processing of clearing the accounting account settings.
// 
// Parameters:
// 	Form - ClientApplicationForm - The shape of the object settings
// 	Item - FormField - Element (input field) of the accounting account settings
// 	StandardProcessing - Boolean - indicates that standard processing is required
//
Procedure Clearing(Form, Item, StandardProcessing) Export
EndProcedure

// Executes the command to display / hide long-term accounting account settings on the form.
//
// Parameters:
//  Form	- ClientApplicationForm - The form where the team is located;
//  Command	- FormCommand - The command you want to execute.
//
Procedure ExecuteOverridableCommand(Form, Command) Export
	
	
EndProcedure

#Region SettingUpAccountsForOtherTransactions

// Returns the parameters passed to the general form of the Account setingcounts of the operation when opening.
// 
// Returns:
//  Structure - LongDesc:
//  * Period - Date - Date of operation being performed
//  * ConfigurationData - See GLAccountSettingsClientServer.CompositionOfAccountingAccountSettings
//  * GLAccountSettings - Undefined, CatalogRef.OtherTransactionsGLAccountsSettings, ChartOfCharacteristicTypesRef.AssetLiabilityItems - editable account setup or default account setup
//  * ReadOnly - Boolean - Indicates that interactive editing of account settings is restricted
//  * SettingContext - See GLAccountSettingsClientServer.SettingContext
//  * ExtDimensionSelectionSources - ValueList of Type - List of sources for automatic matching of sub-accounts
//      Value - Type - The type of the source of automatic selection of sub-content (For example, Type("Reference Link.Physical beauty"))
//      Representation - String - Path to source data, (For example, "Object.Accrual.Physical body").
//  * LedgerAccountsInEntrySettings - Undefined, Boolean - When opening the form for items of assets and liabilities, it contains a sign for specifying MFP accounts in the Entries settings
//
Function ParametersOfInvoiceConfigurationForm() Export
	
	ConfigurationFormParameters = New Structure;
	ConfigurationFormParameters.Insert("Period", CommonClient.SessionDate());
	ConfigurationFormParameters.Insert("ConfigurationData", GLAccountSettingsClientServer.CompositionOfAccountingAccountSettings());
	ConfigurationFormParameters.Insert("GLAccountSettings", Undefined);
	ConfigurationFormParameters.Insert("ReadOnly", False);
	ConfigurationFormParameters.Insert("SettingContext", New Structure());
	ConfigurationFormParameters.Insert("ExtDimensionSelectionSources", New ValueList());
	ConfigurationFormParameters.Insert("LedgerAccountsInEntrySettings", Undefined);
	
	Return ConfigurationFormParameters;
	
EndFunction

// Called in the "Click" handler for the hyperlink of the configuration item.
// 
// Parameters:
// 	Form - ClientApplicationForm - Form of the configuration object.
// 	Item - FormField - Setting item.
// 	StandardProcessing - Boolean - indicates standard event handling.
// 	Notification - CallbackDescription - Description of the notification to be performed after the configuration is complete.
//
Procedure OnClick(Form, Item, StandardProcessing, Notification = Undefined) Export
	
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
	If AccountSettingsData_1 = Undefined Or Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		Return;
	EndIf;
	
	ParameterIndex_ = Undefined;
	If Not AccountSettingsData_1.MatchingSettingsToFormElements.Property(Item.Name, ParameterIndex_) Then
		Return;
	EndIf;
	SetupParameters = AccountSettingsData_1.ArrayOfSettings.Get(ParameterIndex_);
	
	StandardProcessing = False;
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	If FormTable <> Undefined Then
		RowID = FormTable.CurrentRow;
	EndIf;
	
	SettingContext = GLAccountSettingsClientServer.DataAlongWay(Form, SetupParameters.DataPath, RowID);
	If TypeOf(SettingContext) = Type("FormDataCollection") Then
		// Editing the table in the "No partitioning" mode
		SettingContext = SettingContext[0];
		ServiceContext = SettingContext;
		RowID = SettingContext.GetID();
	ElsIf TypeOf(SettingContext) = Type("FormDataStructure")
		Or TypeOf(SettingContext) = Type("ClientApplicationForm") Then
		ServiceContext = Form;
	Else
		ServiceContext = SettingContext;
	EndIf;
	
	If ValueIsFilled(SetupParameters.Presentation)
		And ServiceContext[SetupParameters.Presentation] = GLAccountSettingsClientServer.HyperlinkTextNoInvoiceSetupRequired() Then
		Return;
	EndIf;
	
	SettingIsUnique = True;
	
	DataAlongWay = GLAccountSettingsClientServer.DataAlongWay(Form, SetupParameters.DataPath);
	If TypeOf(DataAlongWay) = Type("FormDataCollection")
		And ValueIsFilled(SettingContext[SetupParameters.GLAccountSettings]) Then
		For Each CollectionItem In DataAlongWay Do
			If CollectionItem[SetupParameters.GLAccountSettings] = SettingContext[SetupParameters.GLAccountSettings]
				And CollectionItem.GetID() <> SettingContext.GetID() Then
				SettingIsUnique = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	ConfigurationFormParameters = ParametersOfInvoiceConfigurationForm();
	ConfigurationFormParameters.ReadOnly = Form.ReadOnly;
	ConfigurationFormParameters.SettingContext = GLAccountSettingsClientServer.SettingContext(Form, SetupParameters, RowID);
	ConfigurationFormParameters.ExtDimensionSelectionSources = SetupParameters.ExtDimensionSelectionSources;
	
	If SettingIsUnique Then
		ConfigurationFormParameters.GLAccountSettings = SettingContext[SetupParameters.GLAccountSettings];
	EndIf;
	
	ConfigurationData = AccountSettingsData_1.AccountingAccountSettings[SettingContext[SetupParameters.GLAccountSettings]];
	If ConfigurationData <> Undefined Then
		ConfigurationFormParameters.ConfigurationData = ConfigurationData;
	EndIf;
	
	If StrStartsWith(SetupParameters.DataPath, "Object")
	And CommonClientServer.HasAttributeOrObjectProperty(Form["Object"], "Date") Then
		ConfigurationFormParameters.Period = Form["Object"]["Date"];
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("RowID", RowID);
	AdditionalParameters.Insert("NameOfSettingElement", Item.Name);
	AdditionalParameters.Insert("SetupParameters", SetupParameters);
	AdditionalParameters.Insert("NotificationAfterCompletion", Notification);
	
	CallbackDescription = New CallbackDescription("SettingUpCompletionOperationReflection", ThisObject, AdditionalParameters);
	
	OpenForm("CommonForm.TransactionGLAccountsSettings", ConfigurationFormParameters, Form, , , , CallbackDescription); 
	
EndProcedure

// Called in the "first Edit" handler for the form table.
// 
// Parameters:
// 	Form - ClientApplicationForm - Form of the configuration object.
// 	FormTable - FormTable - Editable form table.
// 	NewRow - FormDataCollectionItem - A new row in the form table that is being edited. Used for software copying and mismatch with the current table data
// 	DataPath - String - Path to the account setup data. Used when the setting is not displayed on the form and there are no form elements in the settings.
//
Procedure WhenCopyingString(Form, FormTable, NewRow = Undefined, DataPath = Undefined) Export

	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings"); // See GLAccountSettingsClientServer.NewAccountSettingsData
	If AccountSettingsData_1 = Undefined Or Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		Return;
	EndIf;

	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		If DataPath <> Undefined And DataPath = SetupParameters.DataPath Then
			CopyAccountingAccountSettings(AccountSettingsData_1, SetupParameters, FormTable, NewRow);
		Else
			For Each FormItem In SetupParameters.FormItems Do
				If FormTable = TMCommonUseClientServer.ElementShapeTable(Form.Items[FormItem]) Then
					CopyAccountingAccountSettings(AccountSettingsData_1, SetupParameters, FormTable, NewRow);
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

//It is intended for processing a form table that is not related to the tabular part of the object.
// Called in the form handler before recording().
//
// Parameters:
//	Form - ClientApplicationForm - shape.
//
Procedure BeforeWriteAtClient(Form) Export
	
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
	If AccountSettingsData_1 = Undefined Or Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		Return;
	EndIf;
	
	GLAccountSettingsClientServer.ClearOutdatedReflectionSettingsInFormData(Form, AccountSettingsData_1.ArrayOfSettings);
	
EndProcedure

#EndRegion

#Region SettingUpExtdimensionSelection

// Processing transactions when the organization changes.
// 
// Parameters:
//  AccountingEntry - AccountingRegisterRecord - AccountingEntry
//  TypesConnectedWithTheCompany - TypeDescription - Description of types
//  DrCr - String - Dt or Ct
Procedure ProcessingTransactionsWhenOrganizationChanges(AccountingEntry, TypesConnectedWithTheCompany, DrCr = "")  Export
	
	For Indus = 1 To 3 Do
		ExtraDimensionValue = AccountingEntry["ExtDimension" + DrCr + Indus];
		If ValueIsFilled(ExtraDimensionValue)
			And TypesConnectedWithTheCompany.ContainsType(TypeOf(ExtraDimensionValue)) Then
			TypesArray = New Array;
			TypesArray.Add(TypeOf(ExtraDimensionValue));
			DescriptionOfExtdimensionType = New TypeDescription(TypesArray);
			AccountingEntry["ExtDimensionDr" + Indus] = DescriptionOfExtdimensionType.AdjustValue(Undefined);
		EndIf;
	EndDo;
	
	If ValueIsFilled(AccountingEntry["Department" + DrCr]) Then
		AccountingEntry["Department" + DrCr] = Undefined;
	EndIf;
	
EndProcedure

Procedure ChangeExtdimensionFieldSelectionParameters(Form, TableRow, Organization, DrCr = "")  Export
	
	FieldPattern = "ExtDimension" + DrCr + "%IndexOf%";
	DocumentParameters = GLAccountSettingsClientServer.ExtdimensionSelectionOptions(Organization, TableRow, FieldPattern, "Account" + DrCr);
	GLAccountSettingsClientServer.ChangeExtdimensionFieldSelectionParameters(Form, TableRow, FieldPattern, FieldPattern, DocumentParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal


#EndRegion

#Region Private


Procedure SettingUpCompletionOperationReflection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Form = AdditionalParameters.Form;
	SetupParameters = AdditionalParameters.SetupParameters;
	RowID = AdditionalParameters.RowID;
	
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
	AccountSettingsData_1.AccountingAccountSettings.Insert(Result.GLAccountSettings, Result.ConfigurationData);
	
	SettingContext = GLAccountSettingsClientServer.DataAlongWay(Form, SetupParameters.DataPath, RowID);
	If TypeOf(SettingContext) = Type("FormDataCollection") Then
		For Each TableRow In SettingContext Do
			If ValueIsFilled(SetupParameters.AssetAndLiabilityItem) Then
				TableRow[SetupParameters.AssetAndLiabilityItem] = Result.AssetAndLiabilityItem;
			EndIf;
			If ValueIsFilled(SetupParameters.AssetsLiabilitiesDimension) Then
				TableRow[SetupParameters.AssetsLiabilitiesDimension] = Result.AssetsLiabilitiesDimension;
			EndIf;
			TableRow[SetupParameters.GLAccountSettings] = Result.GLAccountSettings;
			Presentation = GLAccountSettingsClientServer.ReflectionSettingPresentation(TableRow, SetupParameters, AccountSettingsData_1);
			TableRow[SetupParameters.Presentation] = Presentation;
		EndDo;
	Else
		If ValueIsFilled(SetupParameters.AssetAndLiabilityItem) Then
			SettingContext[SetupParameters.AssetAndLiabilityItem] = Result.AssetAndLiabilityItem;
		EndIf;
		If ValueIsFilled(SetupParameters.AssetsLiabilitiesDimension) Then
			SettingContext[SetupParameters.AssetsLiabilitiesDimension] = Result.AssetsLiabilitiesDimension;
		EndIf;
		SettingContext[SetupParameters.GLAccountSettings] = Result.GLAccountSettings;
		Presentation = GLAccountSettingsClientServer.ReflectionSettingPresentation(SettingContext, SetupParameters, AccountSettingsData_1);
		If TypeOf(SettingContext) = Type("FormDataCollectionItem") Then
			SettingContext[SetupParameters.Presentation] = Presentation;
		Else
			Form[SetupParameters.Presentation] = Presentation;
		EndIf;
	EndIf;
	
	IncomeAndExpensesClientServer.ArticleAnalyticsOfIncomeExpensesInCaseOfChanges(Form, SetupParameters.DataPath);
	
	Form.Modified = True;
	Form.RefreshDataRepresentation();
	
	If AdditionalParameters.NotificationAfterCompletion <> Undefined Then
		RunCallback(AdditionalParameters.NotificationAfterCompletion);
	EndIf;
	
EndProcedure

Procedure CopyAccountingAccountSettings(AccountSettingsData_1, SetupParameters, FormTable, NewRow)
	
	If NewRow = Undefined Then
		CurrentData = FormTable.CurrentData;
	Else
		CurrentData = NewRow;
	EndIf;
	
	If ValueIsFilled(CurrentData[SetupParameters.GLAccountSettings]) Then
		ConfigurationData = AccountSettingsData_1.AccountingAccountSettings[CurrentData[SetupParameters.GLAccountSettings]];
		NewSetting = GLAccountSettingsInternalServerCall.LinkToNewInvoiceSettingsElement();
		CurrentData[SetupParameters.GLAccountSettings] = NewSetting;
		AccountSettingsData_1.AccountingAccountSettings.Insert(NewSetting, CommonClient.CopyRecursive(ConfigurationData));
	EndIf;
	
EndProcedure

#EndRegion

#Region Public

#Region SettingUpAccountsForOtherTransactions

// Clears the article and Analytics in the table row if they are not available in the PM row.
//
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	TableRow - FormDataCollectionItem - Table row.
// 	PathToTableData - String - The path to the form table data, such as " Object.Goods".
//
Procedure WhenChangingAccountAvailabilityDetailsInLine(Form, TableRow, PathToTableData) Export
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form,
		"GLAccountSettings");

	If AccountSettingsData_1 = Undefined Then
		Return;
	EndIf;

	For Each Parameters In AccountSettingsData_1.ArrayOfSettings Do
		If Parameters.DataPath = PathToTableData Then
			LineAvailability = True;
			For Each KeyAndValue In Parameters.ConditionsForAvailabilityOfAccountingAccountInLines Do
				If TableRow[KeyAndValue.Key] <> KeyAndValue.Value Then
					LineAvailability = False;
					Break;
				EndIf;
			EndDo;
			If Not LineAvailability Then
				If ValueIsFilled(TableRow[Parameters.GLAccountSettings]) Then
					TableRow[Parameters.GLAccountSettings] = Undefined;
					If AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
						TableRow[Parameters.Presentation] = ReflectionSettingPresentation(TableRow,
							Parameters, AccountSettingsData_1);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// Sets the visibility of the accounting accounts settings when changing the type of article, fills in the default article accounting account settings.
// Called from the article and analyst selection mechanism (See IncomeAndExpensesServer)
// .
//
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	DataPath - String - The value of the "Data Path" field of the article and analyst selection parameters (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//                         .
// 	ArticleType - String - The value of the "Article type" field of the article and analyst selection parameters (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//                       .
// 	RowsIDs - Number, Array, Undefined - IDs of table rows where the article type has changed.
//
Procedure WhenChangingArticle(Form, DataPath, ArticleType, RowsIDs = Undefined) Export
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form,
		"GLAccountSettings");

	If AccountSettingsData_1 = Undefined Then
		Return;
	ElsIf Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		Return;
	EndIf;

	If RowsIDs <> Undefined And TypeOf(RowsIDs) <> Type("Array") Then
		RowsIDs = CommonClientServer.ValueInArray(RowsIDs);
	EndIf;

	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		If DataPath = SetupParameters.DataPath Then
			If ValueIsFilled(ArticleType) And ArticleType = SetupParameters.ArticleType Then
				SetVisibilityOfElementsByParameters(Form, SetupParameters, AccountSettingsData_1);
			EndIf;
			FillInTheDefaultAccountSettings(Form, SetupParameters, RowsIDs);
			FillInSettingsPresentationByParameters(Form, SetupParameters, RowsIDs);
		EndIf;
	EndDo;
EndProcedure

// Complements the structure of the actions of the Batch processing mechanism of the individual part by the action of filling in the default account settings
// according to the article of assets and liabilities.
// 
// Parameters:
//  StructureOfActions - Structure - structure of actions
//  FormOrParameters - ClientApplicationForm, Structure, Array - When calling from a Form, the Form Of the object is passed. The cached data of the accounting account settings is obtained From THE Form. 
//                                                             When calling from an object - account settings (See GLAccountSettingsServer.SetupParameters)
//                                                                      .
//  DataPath - String - Path to the data for setting up accounting accounts. The default value is " Object.Goods".
//
Procedure InsertActionFillInDefaultAccountingAccountsSetting(StructureOfActions, FormOrParameters, DataPath = "Object.Goods") Export
	If TypeOf(FormOrParameters) = Type("ClientApplicationForm") Then
		AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(FormOrParameters, "GLAccountSettings");
		ActionInForm = True;
	Else
		AccountSettingsData_1 = NewAccountSettingsData();
		AccountSettingsData_1.YouCanConfigureAccountingAccounts = GLAccountSettingsInternalServerCall.YouCanConfigureAccountingAccounts();
		If TypeOf(FormOrParameters) = Type("Array") Then
			AccountSettingsData_1.ArrayOfSettings = FormOrParameters;
		Else
			AccountSettingsData_1.ArrayOfSettings = CommonClientServer.ValueInArray(FormOrParameters);
		EndIf;
		ActionInForm = False;
	EndIf;

	If AccountSettingsData_1 = Undefined Then
		Return;
	ElsIf Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		Return;
	EndIf;
	
	TabularSectionColumns     = New Array();
	ArrayOfSettings = New Array();
	
	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		If DataPath <> SetupParameters.DataPath Then
			Continue;
		EndIf;
		
		ArrayOfSettings.Add(SetupParameters);
		
		TabularSectionColumns.Add(SetupParameters.GLAccountSettings);
		TabularSectionColumns.Add(SetupParameters.AssetAndLiabilityItem);
		If ValueIsFilled(SetupParameters.ArticleType) Then
			TabularSectionColumns.Add(SetupParameters.ArticleType);
		EndIf;
	EndDo;
	
	ActionParameters = New Structure();
	ActionParameters.Insert("ActionInForm", ActionInForm);
	ActionParameters.Insert("TabularSectionColumns", TabularSectionColumns);
	ActionParameters.Insert("AccountSettingsData_1", NewAccountSettingsData());
	ActionParameters.AccountSettingsData_1.ArrayOfSettings = ArrayOfSettings;
	ActionParameters.AccountSettingsData_1.YouCanConfigureAccountingAccounts = True;
	
	If ActionInForm Then
		ActionParameters.AccountSettingsData_1.AccountingAccountSettings = AccountSettingsData_1.AccountingAccountSettings;
		ActionParameters.AccountSettingsData_1.LocalAccountingIsUsed = AccountSettingsData_1.LocalAccountingIsUsed;
		ActionParameters.AccountSettingsData_1.InternationalAccountingIsUsed = AccountSettingsData_1.InternationalAccountingIsUsed;
	EndIf;
	
	StructureOfActions.Insert("FillInTheDefaultAccountSetting", ActionParameters);
	
	If ActionInForm Then
		InsertActionFillPresentationAccountSettingsAccounting(StructureOfActions, FormOrParameters, DataPath);
	EndIf;
EndProcedure

// Complements the structure of the actions of the Batch processing mechanism of the tabular part with the action of filling in the Presentation of the account settings.
// An action can only be used in a form.
// 
// Parameters:
// 	StructureOfActions - Structure - structure of actions
// 	Form - ClientApplicationForm - The form returns cached parameters for setting up accounting accounts. 
// 	DataPath - String - Path to the data for setting up accounting accounts. The default value is " Object.Goods".
//
Procedure InsertActionFillPresentationAccountSettingsAccounting(StructureOfActions, Form, DataPath = "Object.Goods") Export
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
	
	If AccountSettingsData_1 = Undefined Then
		Return;
	ElsIf Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		Return;
	EndIf;
	
	TabularSectionColumns     = New Array;
	ArrayOfSettings = New Array;
	
	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		
		If DataPath <> SetupParameters.DataPath Then
			Continue;
		EndIf;
		
		ArrayOfSettings.Add(SetupParameters);
		
		TabularSectionColumns.Add(SetupParameters.GLAccountSettings);
		TabularSectionColumns.Add(SetupParameters.Presentation);
		If ValueIsFilled(SetupParameters.ArticleType) Then
			TabularSectionColumns.Add(SetupParameters.ArticleType);
		EndIf;
		
	EndDo;
	
	ActionParameters = New Structure;
	
	ActionParameters.Insert("TabularSectionColumns", TabularSectionColumns);
	ActionParameters.Insert("AccountSettingsData_1", NewAccountSettingsData());
	ActionParameters.AccountSettingsData_1.ArrayOfSettings = ArrayOfSettings;
	ActionParameters.AccountSettingsData_1.AccountingAccountSettings = AccountSettingsData_1.AccountingAccountSettings;
	ActionParameters.AccountSettingsData_1.LocalAccountingIsUsed = AccountSettingsData_1.LocalAccountingIsUsed;
	ActionParameters.AccountSettingsData_1.InternationalAccountingIsUsed = AccountSettingsData_1.InternationalAccountingIsUsed;
	ActionParameters.AccountSettingsData_1.YouCanConfigureAccountingAccounts = True;
	
	StructureOfActions.Insert("FillInInvoiceSettingsPresentation", ActionParameters);
EndProcedure

// Returns the structure of fields for setting up accounts for the operation.
// 
// Returns:
//  Structure - LongDesc:
//  * FinancialAccountingSettings - Array - international accounting account settings, See CompositionOfInternationalAccountingAccounts
//
Function CompositionOfAccountingAccountSettings() Export

	CompositionOfAccountSettings = New Structure();
	CompositionOfAccountSettings.Insert("FinancialAccountingSettings", New Array);
	Return CompositionOfAccountSettings;

EndFunction

// Returns the structure of fields for setting up accounting for an operation on an international accounting account.
// Used to fill in the international accounting Settings property of the operation accounting account settings.
// 
// Returns:
//  Structure - LongDesc:
//  * ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - International accounting Chart of Accounts.
//  * GLAccount - ChartOfAccountsRef.International - international accounting account.
//  * ExtDimension1 - Arbitrary - subconto 1 international accounting accounts
//  * ExtDimension2 - Arbitrary - sub-konto 2 international accounting accounts
//  * ExtDimension3 - Arbitrary - sub-konto 3 international accounting accounts
//
Function CompositionOfInternationalAccountingAccounts() Export

	CompositionOfAccountSettings = New Structure();
	CompositionOfAccountSettings.Insert("ChartOfAccounts", PredefinedValue("Catalog.FinancialAccountingChartsOfAccounts.EmptyRef"));
	CompositionOfAccountSettings.Insert("GLAccount",  PredefinedValue("ChartOfAccounts.International.EmptyRef"));
	CompositionOfAccountSettings.Insert("ExtDimension1",  Undefined);
	CompositionOfAccountSettings.Insert("ExtDimension2",  Undefined);
	CompositionOfAccountSettings.Insert("ExtDimension3",  Undefined);
	Return CompositionOfAccountSettings;

EndFunction

#EndRegion

// Processes changes to accounting Analytics details that affect the setup of accounting accounts.
// 
// Parameters:
// 	Form - ClientApplicationForm - The shape of the object settings
// 	TagName - String - Name of the prop element
//
Procedure OnChangeAttribute(Form, TagName = Undefined) Export
EndProcedure


#Region SettingUpExtdimensionSelection

// Changes the parameters for selecting sub-konto fields.
//
// Parameters:
//	Form - ClientApplicationForm - The form on which the subconto fields are located.
//	Object - FormDataStructure - The object whose shape is displayed.
//	TemplateObjectFieldName - String - Template for the name of the field of the object containing the subconto.
//	TemplateNameOfFormElement - String - Template for the name of the form field that the subconto is output to.
//	ParametersList - Structure - Contains keys with values of the selections.
//
Procedure ChangeExtdimensionFieldSelectionParameters(Form, Object, TemplateObjectFieldName, TemplateNameOfFormElement,
	ParametersList) Export

	TypesOfParameters = New Map;
	TypesOfParameters.Insert(Type("CatalogRef.CompaniesBankAccounts"), "CompanyBankAccount");
	TypesOfParameters.Insert(Type("CatalogRef.CounterpartyBankAccounts"), "CounterpartyBankAccount");
	TypesOfParameters.Insert(Type("CatalogRef.BusinessStructure"), "Department");
	TypesOfParameters.Insert(Type("CatalogRef.CounterpartyContracts"), "Contract");
	TypesOfParameters.Insert(Type("CatalogRef.LeaseContract"), "Contract");
	TypesOfParameters.Insert(Type("CatalogRef.LoanAndDepositContracts"), "Contract");
	TypesOfParameters.Insert(Type("CatalogRef.Partners"), "Partner");
	TypesOfParameters.Insert(Type("CatalogRef.ExtDimension"), "ExtDimension");
	TypesOfParameters.Insert(Type("CatalogRef.CCDNumbers"), "CCDNumbers");
	TypesOfParameters.Insert(Type("CatalogRef.Products"), "Products");
	

	DescriptionOfAllDocumentsType = GLAccountSettingsInternalServerCall.DescriptionOfAllDocumentsType();

	PurifyRelatedExtdimension = False;
	TypesOfRelatedExtdimension    = Undefined;
	If TypeOf(Form.CurrentItem) = Type("FormTable") Then
		CurrentItem = Form.CurrentItem.CurrentItem;
	Else
		CurrentItem = Form.CurrentItem;
	EndIf;
	CurrentItemName = ?(TypeOf(CurrentItem) = Type("FormField"), CurrentItem.Name, "");

	For IndexOf = 1 To 3 Do
		FormItemName = StrReplace(TemplateNameOfFormElement, "%IndexOf%", IndexOf);
		ObjectFieldName   = StrReplace(TemplateObjectFieldName, "%IndexOf%", IndexOf);
		ObjectFieldType   = TypeOf(Object[ObjectFieldName]);

		ParametersArray = New Array;

		ParameterKind = TypesOfParameters[ObjectFieldType];

		If ParameterKind <> Undefined Then

			If ParameterKind = "Contract" Then

				If ParametersList.Property("Organization") Then
					ParametersArray.Add(New ChoiceParameter("Filter.Organization", ParametersList.Organization));
				EndIf;
				If ParametersList.Property("Counterparty") Then
					ParametersArray.Add(New ChoiceParameter("Filter.Counterparty", ParametersList.Counterparty));
				EndIf;
				If ParametersList.Property("Partner") Then
					ParametersArray.Add(New ChoiceParameter("Filter.Partner", ParametersList.Partner));
				EndIf;

			ElsIf ParameterKind = "CompanyBankAccount" Then

				ParametersArray.Add(New ChoiceParameter("Filter.Owner", ParametersList.Organization));

			ElsIf ParameterKind = "CounterpartyBankAccount" Then

				If ParametersList.Property("Counterparty") Then
					ParametersArray.Add(New ChoiceParameter("Filter.Owner", ParametersList.Counterparty));
				ElsIf ParametersList.Property("Individual") Then
					ParametersArray.Add(New ChoiceParameter("Filter.Owner", ParametersList.Individual));
				EndIf;

			ElsIf ParameterKind = "CCDNumbers" Then

				If ParametersList.Property("OriginCountry") Then
					ParametersArray.Add(New ChoiceParameter("Filter.OriginCountry",
						ParametersList.OriginCountry));
				EndIf;

			ElsIf ParameterKind = "Products" Then

				If ParametersList.Property("AnalyticalProductGroup") Then
					ParametersArray.Add(New ChoiceParameter("Filter.AnalyticalGroup",
						ParametersList.AnalyticalProductGroup));
				EndIf;
				If ParametersList.Property("FinancialProductAccountingGroup") Then
					ParametersArray.Add(New ChoiceParameter("Filter.FinancialAccountingGroup",
						ParametersList.FinancialProductAccountingGroup));
				EndIf;
				If ParametersList.Property("ItemsType") Then
					ParametersArray.Add(New ChoiceParameter("Filter.ItemsType",
						ParametersList.ItemsType));
				EndIf;

			ElsIf ParameterKind = "ExtDimension" And ParametersList.Property("GLAccount") Then

				AccountProperties = GLAccountSettingsInternalServerCall.GetAccountProperties(
					ParametersList.GLAccount);
				ParametersArray.Add(New ChoiceParameter("Filter.Owner", AccountProperties["ExtDimensionType" + IndexOf]));
			
			EndIf;

		EndIf;

		If ParametersArray.Count() = 0 And DescriptionOfAllDocumentsType.ContainsType(ObjectFieldType) Then

			If ParametersList.Property("Organization") Then
				ParametersArray.Add(New ChoiceParameter("Filter.Organization", ParametersList.Organization));
			EndIf;
			If ParametersList.Property("Counterparty") Then
				ParametersArray.Add(New ChoiceParameter("Filter.Counterparty", ParametersList.Counterparty));
			EndIf;
			If ParametersList.Property("Partner") Then
				ParametersArray.Add(New ChoiceParameter("Filter.Partner", ParametersList.Partner));
			EndIf;
			If ParametersList.Property("Individual") Then
				ParametersArray.Add(New ChoiceParameter("Filter.AdvanceHolder",
					ParametersList.Individual));
			EndIf;

		EndIf;

		If ParametersArray.Count() > 0 Then
			ChoiceParameters = New FixedArray(ParametersArray);
			Form.Items[FormItemName].ChoiceParameters = ChoiceParameters;
		ElsIf Form.Items[FormItemName].ChoiceParameters.Count() > 0 Then
			Form.Items[FormItemName].ChoiceParameters = New FixedArray(New Array);
		EndIf;

		If PurifyRelatedExtdimension And ValueIsFilled(Object[ObjectFieldName]) Then

			If TypesOfRelatedExtdimension = Undefined Then
				AllTypesOfExtdimensionRelated = GLAccountSettingsInternalServerCall.AllTypesOfExtdimensionRelated();
				TypesOfRelatedExtdimension    = New TypeDescription(New Array);
				For Each Parameter In ParametersList Do
					If AllTypesOfExtdimensionRelated[Parameter.Key] <> Undefined Then
						TypesOfRelatedExtdimension = New TypeDescription(TypesOfRelatedExtdimension,
							AllTypesOfExtdimensionRelated[Parameter.Key].Types());
					EndIf;
				EndDo;
			EndIf;

			If TypesOfRelatedExtdimension.ContainsType(ObjectFieldType) Then
				Object[ObjectFieldName] = New (ObjectFieldType);
			EndIf;

		EndIf;

		If CurrentItemName = FormItemName Then
			PurifyRelatedExtdimension = True; // Only sub-accounts with a number greater than the current one are cleared
		EndIf;

	EndDo;

EndProcedure

// The function forms a key structure with selection values for the sub-konto.
//
// Parameters:
//	Organization - CatalogRef.Companies - The organization that you are configuring the sub-account for.
//	CurrentData - AccountingRegisterRecordAccountingRegisterName - The record for which the selection parameters are configured.
//	TemplateObjectFieldName - String - Template for the name of the field of the object containing the subconto.
//	NameOfInvoiceField_ - String - Template for the name of the form field that the invoice is displayed in.
//
//Returns:
//   Structure - Contains keys with values of the selections.
//
Function ExtdimensionSelectionOptions(Organization, CurrentData, TemplateObjectFieldName, NameOfInvoiceField_) Export

	ParametersList = New Structure;
	ParametersList.Insert("RemainingRevolutions", "Cr");
	ParametersList.Insert("GLAccount", CurrentData[NameOfInvoiceField_]);
	 
	If ValueIsFilled(Organization) Then
		ParametersList.Insert("Organization", Organization);
		If GLAccountSettingsInternalServerCall.ThisIsINVAccount(ParametersList.GLAccount) Then
			Companies = GLAccountSettingsInternalServerCall.ArrayOfInterconnectedOrganizations(Organization);
			Companies.Add(Organization);
			ParametersList.Insert("Organization", New FixedArray(Companies));
		EndIf;
	EndIf;
	
	For IndexOf = 1 To 3 Do
		FieldName = StrReplace(TemplateObjectFieldName, "%IndexOf%", IndexOf);

		If TypeOf(CurrentData[FieldName]) = Type("CatalogRef.Counterparties") Then
			ParametersList.Insert("Counterparty", CurrentData[FieldName]);
		ElsIf TypeOf(CurrentData[FieldName]) = Type("CatalogRef.Partners") Then
			ParametersList.Insert("Partner", CurrentData[FieldName]);
		ElsIf TypeOf(CurrentData[FieldName]) = Type("CatalogRef.Companies") Then
			CompanyArray = New Array();
			If ValueIsFilled(Organization) Then
				CompanyArray.Add(Organization);
			EndIf;
			CompanyArray.Add(CurrentData[FieldName]);
			ParametersList.Insert("Organization", New FixedArray(CompanyArray));
		ElsIf GLAccountSettingsInternalServerCall.DescriptionOfContractTypes(True).ContainsType(TypeOf(
			CurrentData[FieldName])) Then
			ParametersList.Insert("CounterpartyContract", CurrentData[FieldName]);
		ElsIf TypeOf(CurrentData[FieldName]) = Type("CatalogRef.Products") Then
			ParametersList.Insert("Products", CurrentData[FieldName]);
		ElsIf TypeOf(CurrentData[FieldName]) = Type("CatalogRef.Warehouses") Then
			ParametersList.Insert("Warehouse", CurrentData[FieldName]);
		ElsIf TypeOf(CurrentData[FieldName]) = Type("CatalogRef.Persons") Then
			ParametersList.Insert("Individual", CurrentData[FieldName]);
		ElsIf TypeOf(CurrentData[FieldName]) = Type("CatalogRef.WorldCountries") Then
			ParametersList.Insert("OriginCountry", CurrentData[FieldName]);
		ElsIf TypeOf(CurrentData[FieldName]) = Type("CatalogRef.AnalyticalInventoryGroups") Then
			ParametersList.Insert("AnalyticalProductGroup", CurrentData[FieldName]);
		ElsIf TypeOf(CurrentData[FieldName]) = Type("CatalogRef.InventoryAccountingGroups") Then
			ParametersList.Insert("FinancialProductAccountingGroup", CurrentData[FieldName]);
		ElsIf TypeOf(CurrentData[FieldName]) = Type("EnumRef.ItemsTypes") Then
			ParametersList.Insert("ItemsType", CurrentData[FieldName]);
		EndIf;

	EndDo;

	Return ParametersList;

EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region SettingUpAccountsForOtherTransactions

// Returns a string of the names of the ledger account setup Attributes in csv format
//
// Returns:
//  String - comma-separated Attribute names
//
Function AccountSettingsDetails() Export

	Return "GLAccount,ExtDimension1,ExtDimension2,ExtDimension3";

EndFunction

// Returns the Ledger account settings data structure used in the ledger account settings mechanism
//
// Returns:
//  Structure:
//  * ArrayOfSettings - Array of See GLAccountSettingsServer.SetupParameters
//  * MatchingSettingsToFormElements - Structure:
//   ** Key - String - Name of the Form control specified in the settings
//   ** Value - Number - Index of settings in the array of settings
//  * YouCanConfigureAccountingAccounts - Boolean - Indicates whether the settings can be edited by the user
//  * AccountingAccountSettings - Map of KeyAndValue:
//   ** Key - CatalogRef.OtherTransactionsGLAccountsSettings - link to the settings Catalog item
//   ** Value See GLAccountSettingsClientServer.CompositionOfAccountingAccountSettings
//  * LocalAccountingIsUsed - Boolean - An indication of the use of regulated accounting in the information base
//  * InternationalAccountingIsUsed - Boolean - An indication of the use of international accounting in the information base
//
Function NewAccountSettingsData() Export
	
	AccountSettingsData_1 = New Structure();
	AccountSettingsData_1.Insert("ArrayOfSettings", New Array());
	AccountSettingsData_1.Insert("MatchingSettingsToFormElements", New Structure());
	AccountSettingsData_1.Insert("YouCanConfigureAccountingAccounts", False);
	AccountSettingsData_1.Insert("AccountingAccountSettings", New Map());
	AccountSettingsData_1.Insert("LocalAccountingIsUsed", False);
	AccountSettingsData_1.Insert("InternationalAccountingIsUsed", False);
	
	Return AccountSettingsData_1;
	
EndFunction

// Returns the hyperlink text of the Ledger account configuration control when invoice configuration is not required
//
// Returns:
//  String - Hyperlink text
//
Function HyperlinkTextNoInvoiceSetupRequired() Export
	
	Return NStr("vi = 'Không cần';
				|ru = 'Не требуется';
				|en = 'Not required'; fa = 'لازم نیست';
				|it = 'Non richiesta';
				|pl = 'Nie jest wymagane';
				|tr = 'Gerekli değil'");
	
EndFunction

// LongDesc
// 
// Parameters:
// 	FormObject1 - ClientApplicationForm, FormDataStructure -
// 	DataPath - String -
// 	RowID - Undefined, Number -
// Returns:
// 	FormDataCollection, Arbitrary, Undefined - LongDesc
Function DataAlongWay(FormObject1, Val DataPath, Val RowID = Undefined) Export

	DataPathParts = StrSplit(DataPath, ".", False);
	If TypeOf(FormObject1) <> Type("ClientApplicationForm") And DataPathParts[0] = "Object" Then
		DataPathParts.Delete(0);
	EndIf;

	If DataPathParts.Count() > 1 Then
		Data = FormObject1[DataPathParts[0]];
		If RowID <> Undefined And TypeOf(Data) = Type("FormDataCollection") Then
			Data = Data.FindByID(RowID);
			If DataPathParts.Count() = 2 Then
				Data = Data[DataPathParts[1]];
			EndIf;
		Else
			Data = FormObject1[DataPathParts[0]][DataPathParts[1]];
			If RowID <> Undefined And TypeOf(Data) = Type("FormDataCollection") Then
				Data = Data.FindByID(RowID);
				If DataPathParts.Count() = 3 Then
					Data = Data[DataPathParts[2]];
				EndIf;
			EndIf;
		EndIf;
	ElsIf DataPathParts.Count() = 1 Then
		Data = FormObject1[DataPathParts[0]];
		If RowID <> Undefined And TypeOf(Data) = Type("FormDataCollection") Then
			Data = Data.FindByID(RowID);
		EndIf;
	Else
		Data = FormObject1;
	EndIf;

	Return Data;

EndFunction

// Returns a structure with the values of the organization, asset and liability items, and its analytics
// for which accounts are configured.
// 
// Parameters:
//  Form - ClientApplicationForm - The shape of the object settings
//  SetupParameters - See GLAccountSettingsServer.SetupParameters
//  RowSelected - Number - ID of the current row in the form collection
// 
// Returns:
//  Structure - LongDesc:
//  * Organization - CatalogRef.Companies - Current company
//  * AssetAndLiabilityItem - ChartOfCharacteristicTypesRef.AssetLiabilityItems - Current assets and liabilities item
//  * AssetsLiabilitiesDimension - Characteristic.AssetLiabilityItems - Current analytics of asset and liability items
//
Function SettingContext(Form, SetupParameters, RowSelected = Undefined) Export

	Result = New Structure;

	Organization = Undefined;
	If ValueIsFilled(SetupParameters.Organization) Then
		Organization = DataAlongWay(Form, SetupParameters.Organization, RowSelected);
	EndIf;
	Result.Insert("Organization", Organization);

	AssetAndLiabilityItem = Undefined;
	If ValueIsFilled(SetupParameters.AssetAndLiabilityItem) Then
		AssetAndLiabilityItem = DataAlongWay(Form,
			SetupParameters.DataPath + "." + SetupParameters.AssetAndLiabilityItem, RowSelected);
	EndIf;
	Result.Insert("AssetAndLiabilityItem", AssetAndLiabilityItem);

	AssetsLiabilitiesDimension = Undefined;
	If ValueIsFilled(SetupParameters.AssetsLiabilitiesDimension) Then
		AssetsLiabilitiesDimension = DataAlongWay(Form,
			SetupParameters.DataPath + "." + SetupParameters.AssetsLiabilitiesDimension, RowSelected);
	EndIf;
	Result.Insert("AssetsLiabilitiesDimension", AssetsLiabilitiesDimension);

	Return Result;

EndFunction

Function ReflectionSettingPresentation(SettingContext, SetupParameters, AccountSettingsData_1) Export

	Result = NStr("vi = 'Tùy chỉnh';
					|ru = 'Настроить';
					|en = 'Configure'; fa = 'پیکربندی';
					|it = 'Impostare';
					|pl = 'Ustaw';
					|tr = 'Ayarla'");
	
	If SetupParameters <> Undefined Then
		If Not AccountSettingsData_1.LocalAccountingIsUsed
		And (Not ValueIsFilled(SetupParameters.AssetAndLiabilityItem)
			Or ValueIsFilled(SettingContext[SetupParameters.AssetAndLiabilityItem])
			And GLAccountSettingsInternalServerCall.AccountingAccountsAreSpecifiedInTransactionSettings(SettingContext[SetupParameters.AssetAndLiabilityItem])) Then
			Result = HyperlinkTextNoInvoiceSetupRequired();
		EndIf;
		
		If Not ValueIsFilled(SettingContext[SetupParameters.GLAccountSettings]) Then
			Return Result;
		EndIf;
		
		ConfigurationData = AccountSettingsData_1.AccountingAccountSettings[SettingContext[SetupParameters.GLAccountSettings]];
		If ConfigurationData = Undefined Then
			Return Result;
		EndIf;
	Else
		ConfigurationData = SettingContext;
		AccountSettingsData_1 = NewAccountSettingsData();
		AccountSettingsData_1.YouCanConfigureAccountingAccounts = True;
		AccountSettingsData_1.InternationalAccountingIsUsed = True;
	EndIf;
	
	SettingsCount = 0;
	
	
	If AccountSettingsData_1.InternationalAccountingIsUsed Then
		For Each InternationalConfigurationData In ConfigurationData.FinancialAccountingSettings Do
			If ValueIsFilled(InternationalConfigurationData.GLAccount) Then
				SettingsCount = SettingsCount + 1;
			EndIf;
		EndDo;
	EndIf;
	If SettingsCount = 0 Then
		Return Result;
	EndIf;
	
	FieldArray = New Array;
	
	
	If AccountSettingsData_1.InternationalAccountingIsUsed Then
		For Each InternationalConfigurationData In ConfigurationData.FinancialAccountingSettings Do
			If ValueIsFilled(InternationalConfigurationData.GLAccount) Then
				FieldArray.Add(String(InternationalConfigurationData.GLAccount));
				If SettingsCount = 1 Then
					AddExtdimensionToSettingsPresentation(FieldArray, InternationalConfigurationData, SetupParameters);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If FieldArray.Count() > 0 Then
		Result = StrConcat(FieldArray, ", ");
	EndIf;

	Return Result;

EndFunction

Procedure FillInSettingsPresentation(Form, ArrayOfSettings, DataPath = Undefined,
	RowsIDs = Undefined) Export

	If RowsIDs <> Undefined And TypeOf(RowsIDs) <> Type("Array") Then
		RowsIDs = CommonClientServer.ValueInArray(RowsIDs);
	EndIf;

	For Each SetupParameters In ArrayOfSettings Do
		If DataPath <> Undefined And SetupParameters.DataPath <> DataPath Then
			Continue;
		EndIf;
		FillInSettingsPresentationByParameters(Form, SetupParameters, RowsIDs);
	EndDo;

EndProcedure

Procedure FillInSettingsPresentationByParameters(Form, SetupParameters, RowsIDs = Undefined) Export
	
	If Not ValueIsFilled(SetupParameters.Presentation) Then
		Return;
	EndIf;
	
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");

	SettingContext = DataAlongWay(Form, SetupParameters.DataPath);
	If TypeOf(SettingContext) = Type("FormDataCollection") Then
		If RowsIDs <> Undefined Then
			// We will update only on the passed lines
			For Each RowID In RowsIDs Do
				TableRow = SettingContext.FindByID(RowID);
				Presentation = ReflectionSettingPresentation(TableRow, SetupParameters, AccountSettingsData_1);
				TableRow[SetupParameters.Presentation] = Presentation;
			EndDo;
		Else
			// Update all rows of the table
			For Each TableRow In SettingContext Do
				Presentation = ReflectionSettingPresentation(TableRow, SetupParameters, AccountSettingsData_1);
				TableRow[SetupParameters.Presentation] = Presentation;
			EndDo;
		EndIf;
	Else
		Presentation = ReflectionSettingPresentation(SettingContext, SetupParameters, AccountSettingsData_1);
		Form[SetupParameters.Presentation] = Presentation;
	EndIf;

EndProcedure

Procedure SetFormItemsVisibility(Form, AccountSettingsData_1) Export

	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		SetVisibilityOfElementsByParameters(Form, SetupParameters, AccountSettingsData_1);
	EndDo;

EndProcedure

Function YouNeedToFillInDefaultAccountingAccountsSettings(Form, SettingContext, SetupParameters) Export
	
	DefaultPaddingIsRequired = ValueIsFilled(SetupParameters.AssetAndLiabilityItem)
		And ValueIsFilled(SettingContext[SetupParameters.AssetAndLiabilityItem])
		And Not ValueIsFilled(SettingContext[SetupParameters.GLAccountSettings]);
	
	If Not DefaultPaddingIsRequired Then
	ElsIf Not ValueIsFilled(SetupParameters.ArticleType) Then
	ElsIf TypeOf(SettingContext) = Type("Structure")
		Or TypeOf(SettingContext) = Type("FormDataCollectionItem") Then
		DefaultPaddingIsRequired = SettingContext[SetupParameters.ArticleType] = 3;
	ElsIf TypeOf(Form) = Type("FormDataStructure")
		Or TypeOf(Form) = Type("ClientApplicationForm") Then
		DefaultPaddingIsRequired = Form[SetupParameters.ArticleType] = 3;
	Else
		DefaultPaddingIsRequired =
			TypeOf(SettingContext[SetupParameters.AssetAndLiabilityItem]) =
				Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
	EndIf;
	
	Return DefaultPaddingIsRequired;
	
EndFunction

Procedure FillInTheDefaultAccountSetting(SettingContext, SetupParameters, DefaultSettings, AccountSettingsData_1) Export
	
	If ValueIsFilled(SetupParameters.AssetAndLiabilityItem) Then
		DefaultSetting = DefaultSettings[SettingContext[SetupParameters.AssetAndLiabilityItem]];
		If DefaultSetting <> Undefined Then
			SettingContext[SetupParameters.GLAccountSettings] = DefaultSetting.GLAccountSettings;
			AccountSettingsData_1.AccountingAccountSettings.Insert(DefaultSetting.GLAccountSettings, DefaultSetting.ConfigurationData);
		EndIf;
	EndIf;
	
EndProcedure

//Clears out-of-date account settings in the form table.
//
// Parameters:
//	Form - ClientApplicationForm - The form on which the subconto fields are located.
//	ArrayOfSettings - Array of See GLAccountSettingsServer.SetupParameters - Settings.
//
Procedure ClearOutdatedReflectionSettingsInFormData(Form, ArrayOfSettings) Export
	
	For Each SetupParameters In ArrayOfSettings Do
		
		Data = DataAlongWay(Form, SetupParameters.DataPath);
		If TypeOf(Data) = Type("FormDataCollection") Then
			For Each TableRow In Data Do
				ArticleType = ?(ValueIsFilled(SetupParameters.ArticleType), TableRow[SetupParameters.ArticleType], Undefined);
				ClearReflectionSettings(TableRow, SetupParameters, ArticleType);
			EndDo;
		Else
			ArticleType = ?(ValueIsFilled(SetupParameters.ArticleType), Form[SetupParameters.ArticleType], Undefined);
			ClearReflectionSettings(Data, SetupParameters, ArticleType);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion


#EndRegion

#Region Private

// Sets the visibility of ledger account settings controls
//
// Parameters:
//  Form - ClientApplicationForm - The Form of the document being edited
//  SetupParameters - See GLAccountSettingsServer.SetupParameters
//  AccountSettingsData_1 - See GLAccountSettingsClientServer.NewAccountSettingsData
//
Procedure SetVisibilityOfElementsByParameters(Form, SetupParameters, AccountSettingsData_1)

	SettingContext = DataAlongWay(Form, SetupParameters.DataPath);

	For Each TagName In SetupParameters.FormItems Do

		AvailabilityByArticleType = True;
		AccessibilityByArticleValue = True;
		
		FormItem = Form.Items[TagName];
		FormTable = TMCommonUseClientServer.ElementShapeTable(FormItem);
		
		If FormTable = Undefined
			And SetupParameters.AvailabilityByOperation
			And AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
			ServiceContext = Undefined;
			
			If TypeOf(SettingContext) = Type("FormDataCollection") Then
				If SettingContext.Count() > 0 Then
				// Editing the table in the "No partitioning" mode
					SettingContext = SettingContext[0];
					ServiceContext = SettingContext;
				Else
					SettingContext = Undefined;
				EndIf;
			ElsIf TypeOf(SettingContext) = Type("FormDataStructure")
				Or TypeOf(SettingContext) = Type("ClientApplicationForm") Then
				ServiceContext = Form;
			EndIf;
			
			If ServiceContext <> Undefined
				And ValueIsFilled(SetupParameters.ArticleType) Then
				AvailabilityByArticleType = (ServiceContext[SetupParameters.ArticleType] = 3);
			EndIf;
			
			If SettingContext <> Undefined
			And Not AccountSettingsData_1.LocalAccountingIsUsed
			And (Not ValueIsFilled(SetupParameters.AssetAndLiabilityItem)
				Or ValueIsFilled(SettingContext[SetupParameters.AssetAndLiabilityItem])
				And GLAccountSettingsInternalServerCall.AccountingAccountsAreSpecifiedInTransactionSettings(SettingContext[SetupParameters.AssetAndLiabilityItem])) Then
				AccessibilityByArticleValue = False;
				ConfigurationData = AccountSettingsData_1.AccountingAccountSettings[SettingContext[SetupParameters.GLAccountSettings]];
				If ConfigurationData <> Undefined Then
					For Each InternationalConfigurationData In ConfigurationData.FinancialAccountingSettings Do
						If ValueIsFilled(InternationalConfigurationData.GLAccount) Then
							AccessibilityByArticleValue = True;
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;

		FormItem.Visible = AccountSettingsData_1.YouCanConfigureAccountingAccounts
			And SetupParameters.AvailabilityByOperation
			And AccessibilityByArticleValue
			And AvailabilityByArticleType;

	EndDo;

EndProcedure

Procedure AddExtdimensionToSettingsPresentation(FieldArray, ConfigurationData, SetupParameters)
	
	AccountProperties = GLAccountSettingsInternalServerCall.GetAccountProperties(ConfigurationData.GLAccount);
	
	For ExtDimensionNumber = 1 To AccountProperties.ExtDimensionCount Do
		ExtraDimensionValue = ConfigurationData["ExtDimension" + ExtDimensionNumber];

		If ValueIsFilled(ExtraDimensionValue) Then
			FieldArray.Add(String(ExtraDimensionValue));
		ElsIf SetupParameters <> Undefined Then
			DescriptionOfExtdimensionTypes = AccountProperties["ExtDimensionType" + ExtDimensionNumber + "ValueType"];
			PresentationFilled = False;
			For Each Source In SetupParameters.ExtDimensionSelectionSources Do
				If DescriptionOfExtdimensionTypes.ContainsType(Source.Value) Then
					PresentationFilled = True;
					FieldArray.Add(NStr("vi = '<tự động>';
										|ru = '<авто>';
										|en = '<auto>'; fa = '<auto>';
										|it = '<auto>';
										|pl = '<auto>';
										|tr = '<otomatik>'"));
					Break;
				EndIf;
			EndDo;

			If Not PresentationFilled Then
				FieldArray.Add("<...>");
			EndIf;
		Else
			FieldArray.Add("<...>");
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInTheDefaultAccountSettings(Form, SetupParameters, RowsIDs)

	If Not SetupParameters.AvailabilityByOperation Then
		Return;
	EndIf;
	
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
	
	SettingContext = DataAlongWay(Form, SetupParameters.DataPath);
	If TypeOf(SettingContext) = Type("FormDataCollection") Then
		ListOfArticles = New Array();
		If RowsIDs <> Undefined Then
			For Each RowID In RowsIDs Do
				TableRow = SettingContext.FindByID(RowID);
				If YouNeedToFillInDefaultAccountingAccountsSettings(Form, TableRow, SetupParameters) Then
					ListOfArticles.Add(TableRow[SetupParameters.AssetAndLiabilityItem]);
				EndIf;
			EndDo;
		Else
			For Each TableRow In SettingContext Do
				If YouNeedToFillInDefaultAccountingAccountsSettings(Form, TableRow, SetupParameters) Then
					ListOfArticles.Add(TableRow[SetupParameters.AssetAndLiabilityItem]);
				EndIf;
			EndDo;
		EndIf;
		
		DefaultSettings = GLAccountSettingsInternalServerCall.DefaultAccountSettingsData(
			ListOfArticles, AccountSettingsData_1);
		
		If RowsIDs <> Undefined Then
			For Each RowID In RowsIDs Do
				TableRow = SettingContext.FindByID(RowID);
				FillInTheDefaultAccountSetting(TableRow, SetupParameters, DefaultSettings, AccountSettingsData_1);
			EndDo;
		Else
			For Each TableRow In SettingContext Do
				FillInTheDefaultAccountSetting(TableRow, SetupParameters, DefaultSettings, AccountSettingsData_1);
			EndDo;
		EndIf;
	ElsIf YouNeedToFillInDefaultAccountingAccountsSettings(Form, SettingContext, SetupParameters) Then
		DefaultSetting = GLAccountSettingsInternalServerCall.DefaultAccountSettingsData(
			SettingContext[SetupParameters.AssetAndLiabilityItem], AccountSettingsData_1);
		FillInTheDefaultAccountSetting(SettingContext, SetupParameters, DefaultSetting, AccountSettingsData_1);
	EndIf;

EndProcedure


#Region SettingUpAccountsForOtherTransactions

Procedure ClearReflectionSettings(Data, SetupParameters, ArticleType)
	
	If Not SetupParameters.AvailabilityByOperation Or (ArticleType <> Undefined And ArticleType <> 3) Then
		Data[SetupParameters.GLAccountSettings] = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

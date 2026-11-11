#Region Public

#Region SettingUpAccountsForOtherTransactions

// Returns the structure of the operation account settings.
// 
// Returns:
// 	Structure - LongDesc:
// 	* AvailabilityByOperation - Boolean - Indicates whether the document's business operation setting is available.
// 	
// 	* DataPath - String - Path to the regl account setup data. accounting (for Example, " Object "or" Object.Other expenses").
// 	* GLAccountSettings - String - Name of the storage details of the operation accounting account settings. The default value is "account Settings".
//	* AssetAndLiabilityItem - String - Name of the storage detail for the item of other assets and liabilities. The default value of "Stateactivity".
//	* AssetsLiabilitiesDimension - String - Name of the storage details for the analysis of other assets and liabilities. The default value is "asset Analytics".
// 	* LedgerAccountSettingVersion - String - The name of the Attribute for storing the version of the operation account configuration.
//										It is used for the correct operation of the selective registration mechanism for reflection in Local accounting.
//										The default value is an empty string.
// 	* Presentation - String - Name of the form's props (String Type) for storing the settings hyperlink view.
// 	                       The default value of "Predstavlyayushie".
// 	* ArticleType - String - Name of the item type (Number type) that stores the numeric index of the selected article type.
// 	                       Filling in the details is provided by the functions of selecting items and Analytics of the revenue and expense accounting mechanism.
// 	                       See IncomeAndExpensesClientServer.FillInArticleDetails.
// 	                       If this parameter is specified, the setup of accounting accounts is available only for the selected item of other assets and liabilities (item Type = 3).
// 
//	* Organization - String - The full path to the data structure of the document. The default value is "item type".
//
//	* ExtDimensionSelectionSources - ValueList - A list of sources for automatic selection of subconto
//       * Value - Arbitrary - The type of the source of the automatic selection of the subconto (For example, the Type("Reference link.Physical Beauty"))
//       * Title - String - The path to the source data, (for Example, " Object.Charge.Fizicheskaya").
//                                   
//	* FormItems - Array - Names of form elements that are used for setting up accounting accounts.
//	
//	* ConditionsForAvailabilityOfAccountingAccountInLines - Structure - Additional conditions for the availability of settings in the rows of the table. 
//	                                                 If there are several conditions, then availability is determined by "And".
//	                                                 In the elements of the structure:
//	                                                 	* Key - String - Name of the item or table item that determines the availability of the article.
//	                                                 	* Value - Arbitrary - The value of the requisite for which the article selection is available.
//	* HideUnavailableInvoiceInRows - Boolean - If True, then articles and Analytics that are not available in the lines are hidden.
//	                                               If False, then the cells are set to only View. The default value is False.
//	
Function SetupParameters() Export
	
	Parameters = New Structure;
	
	Parameters.Insert("AvailabilityByOperation", True);
	
	// The path to the settings'context' data
	Parameters.Insert("DataPath", "");
	Parameters.Insert("GLAccountSettings",     "GLAccountSettings");
	Parameters.Insert("AssetAndLiabilityItem",    "ExpenseItem");
	Parameters.Insert("AssetsLiabilitiesDimension", "AssetsLiabilitiesDimension");
	Parameters.Insert("LedgerAccountSettingVersion", "");
	
	// Auxiliary details of the form
	Parameters.Insert("ArticleType",     "");
	Parameters.Insert("Presentation", "TransactionRecordingPresentation");
	
	Parameters.Insert("Organization", "Object.Organization");
	
	// Autopodbor subconto
	Parameters.Insert("ExtDimensionSelectionSources", New ValueList());
	
	// Form elements that are used for customization
	Parameters.Insert("FormItems", New Array());
	
	Parameters.Insert("ConditionsForAvailabilityOfAccountingAccountInLines", New Structure);
	Parameters.Insert("HideUnavailableInvoiceInRows", False);
	
	Return Parameters;
	
EndFunction

// Initializes the object form according to the properties of the accounting settings elements.
// Invoked in the handler of the form Precontamination().
// 
// Parameters:
// 	Form - ClientApplicationForm - The shape of the object settings
// 	AccountSettings_1 - Array, Structure - Settings (See GLAccountSettingsServer.SetupParameters)
// 	                                         .
// 	                                         If multiple accounts are configured for an object, an array is passed.
//                                                 Each element of the array is a parameter structure.
//
Procedure OnCreateAtServer(Form, AccountSettings_1) Export
	
	AccountSettingsData_1 = OperationReflectionSettingsData(Form, AccountSettings_1);
	
	If Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
			For Each TagName In SetupParameters.FormItems Do
				Form.Items[TagName].Visible = False;
			EndDo;
		EndDo;
	EndIf;
	
	ConditionalAppearance = Form.ConditionalAppearance;
	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		
		For Each TagName In SetupParameters.FormItems Do
			
			SettingContext = GLAccountSettingsClientServer.DataAlongWay(Form, SetupParameters.DataPath); // FormDataCollection -
			If TypeOf(SettingContext) <> Type("FormDataCollection") Then
				Continue;
			EndIf;
			
			#Region AvailabilityInTableRowsByCondition
			If ValueIsFilled(SetupParameters.ConditionsForAvailabilityOfAccountingAccountInLines) Then
				Item = ConditionalAppearance.Items.Add();
				ItemField = Item.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(TagName);

				ContextTable = SettingContext.Unload(New Array()); // ValueTable -
				ContextColumns = ContextTable.Columns;
				
				Group = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
				Group.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
				For Each FieldAndValue In SetupParameters.ConditionsForAvailabilityOfAccountingAccountInLines Do
					ItemFilter = Group.Items.Add(Type("DataCompositionFilterItem"));
					If ContextColumns.Find(FieldAndValue.Key) <> Undefined Then
						FieldDataPath = SetupParameters.DataPath;
					Else
						FieldDataPath = StrSplit(SetupParameters.DataPath, ".", False)[0];
					EndIf;
					LayoutField = StrTemplate("%1.%2", FieldDataPath, FieldAndValue.Key);
					ItemFilter.LeftValue = New DataCompositionField(LayoutField);
					ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
					ItemFilter.RightValue = FieldAndValue.Value;
				EndDo;
				
				If SetupParameters.HideUnavailableInvoiceInRows Then
					Item.Appearance.SetParameterValue("Visible", False);
				Else
					Item.Appearance.SetParameterValue("ReadOnly", True);
				EndIf;
			EndIf;
			#EndRegion

			#Region ColorOfHyperlink
			Item = ConditionalAppearance.Items.Add();
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(TagName);
			Item.Appearance.SetParameterValue("TextColor",  StyleColors.HyperlinkColor);
			
			Item = ConditionalAppearance.Items.Add();
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(TagName);
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			AttributeOfItem = SetupParameters.DataPath + "." + SetupParameters.Presentation;
			ItemFilter.LeftValue  = New DataCompositionField(AttributeOfItem);
			ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
			
			Item.Appearance.SetParameterValue("TextColor",  StyleColors.HyperlinkColor);
			Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tùy chỉnh';
															|ru = 'Настроить';
															|en = 'Configure'; fa = 'پیکربندی';
															|it = 'Impostare';
															|pl = 'Configure';
															|tr = 'Ayarla'"));
			#EndRegion
			
			// Conditional design by article type
			If SetupParameters.ArticleType = "" Then
				Continue;
			EndIf;
			
			#Region ColorOfHyperlink
			PropsArticleType = SetupParameters.DataPath + "." + SetupParameters.ArticleType;
			
			// The type of article is not defined
			Item = ConditionalAppearance.Items.Add();
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(TagName);
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue  = New DataCompositionField(PropsArticleType);
			ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = 0;
			
			Item.Appearance.SetParameterValue("Text", NStr("vi = '<xác định bởi dạng>';
															|ru = '<определяется статьей>';
															|en = '<defined by item>'; fa = '<defined by item>';
															|it = '<determinato dalla voce>';
															|pl = '<określane pozcycją>';
															|tr = '<kalem ile tanımlanır>'"));
			Item.Appearance.SetParameterValue("Enabled", False);
			Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
			
			// Expense items
			Item = ConditionalAppearance.Items.Add();
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(TagName);
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue  = New DataCompositionField(PropsArticleType);
			ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = 1;
			
			Item.Appearance.SetParameterValue("Text", NStr("vi = '<xác định bởi dạng chi phí>';
															|ru = '<определяется статьей расходов>';
															|en = '<defined by expense item>'; fa = '<defined by expense item>';
															|it = '<determinata dalla voce di spesa>';
															|pl = '<jest określane przez pozycję rozchodów>';
															|tr = '<gider kalemleri ile tanımlanır>'"));
			Item.Appearance.SetParameterValue("Enabled", False);
			Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
			
			// Income items
			Item = ConditionalAppearance.Items.Add();
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(TagName);
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue  = New DataCompositionField(PropsArticleType);
			ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = 2;
			
			Item.Appearance.SetParameterValue("Text", NStr("vi = '<xác định bởi dạng thu nhập>';
															|ru = '<определяется статьей доходов>';
															|en = '<defined by income item>'; fa = '<defined by income item>';
															|it = '<determinato dalla voce di entrate>';
															|pl = '<określa się pozycją dochodów>';
															|tr = '<gelir kalemleri ile tanımlanır>'"));
			Item.Appearance.SetParameterValue("Enabled", False);
			Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
			#EndRegion
			
		EndDo;
		
	EndDo;
	
	If TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings") = Undefined Then
		If ThisIsFormOfProcessing(Form)
		 Or ThisIsArbitraryForm(Form, AccountSettingsData_1) Then
			SaveAccountSettingsDataInMechanismData(Form, AccountSettingsData_1);
		ElsIf (Form.Parameters.Property("CopyingValue") And ValueIsFilled(Form.Parameters.CopyingValue))
		 Or (Form.Parameters.Property("FillingValues") And ValueIsFilled(Form.Parameters.FillingValues))
		 Or (Form.Parameters.Property("Basis") And ValueIsFilled(Form.Parameters.Basis)) Then
			// Opening the form of a new object
			If Form.Parameters.Property("Basis") And ValueIsFilled(Form.Parameters.Basis) 
				And TypeOf(Form.Parameters.Basis) = Type("Structure")
				And Form.Parameters.Basis.Property("AccountSetupCompleted") And Form.Parameters.Basis.AccountSetupCompleted Then 
				SaveAccountSettingsDataInMechanismData(Form, AccountSettingsData_1);
			Else
				SaveAccountSettingsDataInMechanismData(Form, AccountSettingsData_1, True);
			EndIf;
		EndIf;
		
		TMCommonUse.SaveEngineDataToFormCache(Form, "GLAccountSettings", AccountSettingsData_1);
		
		If AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
			GLAccountSettingsClientServer.FillInSettingsPresentation(Form, AccountSettingsData_1.ArrayOfSettings);
			GLAccountSettingsClientServer.SetFormItemsVisibility(Form, AccountSettingsData_1);
		EndIf;
	EndIf;
	
EndProcedure

// Sets the properties of configuration items when reading data from the configuration object.
// Invoked in the handler of the form Pristinematerial().
// 
// Parameters:
// 	Form - ClientApplicationForm - The shape of the object settings
// 	AccountSettings_1 - Array, Structure - Settings (See GLAccountSettingsServer.SetupParameters)
// 	                                         .
// 	                                         If multiple accounts are configured for an object, an array is passed.
//                                                 Each element of the array is a parameter structure.
//
Procedure OnReadAtServer(Form, AccountSettings_1) Export
	
	AccountSettingsData_1 = OperationReflectionSettingsData(Form, AccountSettings_1);
	
	SaveAccountSettingsDataInMechanismData(Form, AccountSettingsData_1);
	TMCommonUse.SaveEngineDataToFormCache(Form, "GLAccountSettings", AccountSettingsData_1);
	
	If Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
			For Each TagName In SetupParameters.FormItems Do
				Form.Items[TagName].Visible = False;
			EndDo;
		EndDo;
		Return;
	EndIf;
	
	GLAccountSettingsClientServer.FillInSettingsPresentation(Form, AccountSettingsData_1.ArrayOfSettings);
	GLAccountSettingsClientServer.SetFormItemsVisibility(Form, AccountSettingsData_1);
	
EndProcedure

// Fills in the value of the subconto by the Sourcepodborasubconto property (if sources are specified).
// Called in the form handler before writing to the Server().
// 
// Parameters:
// 	Form - ClientApplicationForm - object form
// 	CurrentObject - DocumentObject - A recordable object
//
Procedure BeforeWriteAtServer(Form, CurrentObject) Export
	
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
	If AccountSettingsData_1 = Undefined Or Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		Return;
	EndIf;
	
	ClearOutdatedReflectionSettingsInObject(Form, CurrentObject, AccountSettingsData_1.ArrayOfSettings);
	FillInExtdimensionFromSources(CurrentObject, AccountSettingsData_1);
	
	CurrentObject.AdditionalProperties.Insert("AccountingAccountSettings", AccountSettingsData_1.AccountingAccountSettings);
	
EndProcedure

// Sets the properties of the configuration items after writing the data of the configuration object.
// 
// Parameters:
// 	Form - ClientApplicationForm - The shape of the object settings
//
Procedure AfterWriteAtServer(Form) Export
	
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
	If AccountSettingsData_1 = Undefined Or Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		Return;
	EndIf;
	
	GLAccountSettingsClientServer.FillInSettingsPresentation(Form, AccountSettingsData_1.ArrayOfSettings);
	
EndProcedure

// Configures the form for new parameters.
// 
// Parameters:
// 	Form - ClientApplicationForm - The shape of the object settings
// 	AccountSettings_1 - Structure, Array - Settings (See GLAccountSettingsServer.SetupParameters)
// 	                                         .
// 	                                         If multiple accounts are configured for an object, an array is passed.
//                                                 Each element of the array is a parameter structure.
//
Procedure WhenChangingSettings(Form, AccountSettings_1) Export
	
	NewAccountSettingsData = OperationReflectionSettingsData(Form, AccountSettings_1);
	
	CurDataAccountSettings = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
	If CurDataAccountSettings <> Undefined Then
		NewAccountSettingsData.AccountingAccountSettings = Common.CopyRecursive(CurDataAccountSettings.AccountingAccountSettings);
	EndIf;
	
	TMCommonUse.SaveEngineDataToFormCache(Form, "GLAccountSettings", NewAccountSettingsData);
	
	GLAccountSettingsClientServer.ClearOutdatedReflectionSettingsInFormData(Form, NewAccountSettingsData.ArrayOfSettings);
	GLAccountSettingsClientServer.FillInSettingsPresentation(Form, NewAccountSettingsData.ArrayOfSettings);
	GLAccountSettingsClientServer.SetFormItemsVisibility(Form, NewAccountSettingsData);
	
EndProcedure

// Called after software installation of accounting accounts to update the display on the form.
//
// 
// Parameters:
// 	Form - ClientApplicationForm - The shape of the object settings
// 	DataPath - String - Path to account setup data
// 	RowsIDs - Number, Array - IDs of the changed rows. 
// 	                               If the accounting invoice is in the table and the IDs of the changed rows are not passed, the data in the entire table will be updated.
//
Procedure UpdateSettingsPresentation(Form, DataPath = Undefined, RowsIDs = Undefined) Export
	
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
	If AccountSettingsData_1 = Undefined Then
		Return;
	ElsIf Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		Return;
	EndIf;
	
	AccountingAccountSettings = New Array();
	SettingCompliance = New Map();

	If RowsIDs <> Undefined And TypeOf(RowsIDs) <> Type("Array") Then
		RowsIDs = CommonClientServer.ValueInArray(RowsIDs);
	EndIf;
	
	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		If DataPath <> Undefined And SetupParameters.DataPath <> DataPath Then
			Continue;
		EndIf;
		
		SettingContext = GLAccountSettingsClientServer.DataAlongWay(Form, DataPath);
		If TypeOf(SettingContext) = Type("FormDataCollection") Then
			If RowsIDs <> Undefined Then
				// We will update only on the passed lines
				For Each RowID In RowsIDs Do
					TableRow = SettingContext.FindByID(RowID);
					If ValueIsFilled(TableRow[SetupParameters.GLAccountSettings]) Then
						If AccountingAccountSettings.Find(TableRow[SetupParameters.GLAccountSettings]) = Undefined Then
							AccountingAccountSettings.Add(TableRow[SetupParameters.GLAccountSettings]);
						Else
							NewSetting = GLAccountSettingsInternalServerCall.LinkToNewInvoiceSettingsElement();
							SettingCompliance.Insert(NewSetting, TableRow[SetupParameters.GLAccountSettings]);
							TableRow[SetupParameters.GLAccountSettings] = NewSetting;
						EndIf;
					EndIf;
				EndDo;
			Else
				// Update all rows of the table
				For Each TableRow In SettingContext Do
					If ValueIsFilled(TableRow[SetupParameters.GLAccountSettings]) Then
						If AccountingAccountSettings.Find(TableRow[SetupParameters.GLAccountSettings]) = Undefined Then
							AccountingAccountSettings.Add(TableRow[SetupParameters.GLAccountSettings]);
						Else
							NewSetting = GLAccountSettingsInternalServerCall.LinkToNewInvoiceSettingsElement();
							SettingCompliance.Insert(NewSetting, TableRow[SetupParameters.GLAccountSettings]);
							TableRow[SetupParameters.GLAccountSettings] = NewSetting;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		ElsIf ValueIsFilled(SettingContext[SetupParameters.GLAccountSettings]) Then
			AccountingAccountSettings.Add(SettingContext[SetupParameters.GLAccountSettings]);
		EndIf;
	EndDo;
	
	If AccountingAccountSettings.Count() > 0 Then
		AccountSettingsData = AccountSettingsData_(AccountingAccountSettings);
		For Each KeyAndValue In AccountSettingsData Do
			AccountSettingsData_1.AccountingAccountSettings.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
		
		For Each KeyAndValue In SettingCompliance Do
			AccountSettingsData_1.AccountingAccountSettings.Insert(KeyAndValue.Key, AccountSettingsData[KeyAndValue.Value]);
		EndDo;
	EndIf;
	
	GLAccountSettingsClientServer.FillInSettingsPresentation(Form, AccountSettingsData_1.ArrayOfSettings, DataPath, RowsIDs);
	
EndProcedure

// Designed to save changed data format settings, accounts, other transactions of a document or directory
// notes on deleting unused settings, sync notes delete preferences and their owner.
// Called from the event Before writing a document or reference object. Data from accounting settings
// is passed through the mechanism of additional object properties in the "accounting Settings" property.
// 
// Parameters:
//  Object - DocumentObject,
//           Referenceobject - writable object
//  AccountSettings_1 - Array, Structure - Settings (See GLAccountSettingsServer.SetupParameters)
// 	                                         .
// 	                                         If multiple accounts are configured for an object, an array is passed.
//                                                 Each element of the array is a parameter structure.
// 
Procedure BeforeWrite(Object, AccountSettings_1) Export
	
	If Not LocalAccountingAccountsCanBeConfigured() And Not SettingUpInternationalAccountingAccountsIsAvailable() Then
		Return;
	EndIf;
	
	ObjectMetadata1 = Object.Metadata();
	ObjectManager1   = Common.ObjectManagerByFullName(ObjectMetadata1.FullName());
	DeletionMark  = Object.DeletionMark;
	
	If Object.IsNew() Then
		ObjectRef = Object.GetNewObjectRef();
	Else
		ObjectRef = Object.Ref;
	EndIf;
	
	If TypeOf(AccountSettings_1) = Type("Array") Then
		ArrayOfSettings = AccountSettings_1;
	Else
		ArrayOfSettings = CommonClientServer.ValueInArray(AccountSettings_1);
	EndIf;
	
	DocumentSettings  = New Array();
	PathsToSettingsData = New Map();
	PathsToSettingsVersion = New Map();
	
	DuplicateSettings = New ValueTable();
	DuplicateSettings.Columns.Add("Ref", New TypeDescription("CatalogRef.OtherTransactionsGLAccountsSettings"));
	DuplicateSettings.Columns.Add("DataPath");
	DuplicateSettings.Columns.Add("VersionPath");
	
	For Each SetupParameters In ArrayOfSettings Do
		AccountingForVersionsOfAccountingAccountSettings = ValueIsFilled(SetupParameters.LedgerAccountSettingVersion);
		
		DataPathParts = StrSplit(SetupParameters.DataPath, ".", False);
		If DataPathParts[0] = "Object" Then
			DataPathParts.Delete(0);
		EndIf;
		
		If DataPathParts.Count() = 0 Then
			DataPath = SetupParameters.GLAccountSettings;
		ElsIf DataPathParts.Count() = 1 Then
			DataPath = DataPathParts[0];
		Else
			Continue;
		EndIf;
		
		If ObjectMetadata1.TabularSections.Find(DataPath) <> Undefined Then
			TabularSection = Object[DataPath]; // TabularSection -
			For Each TableRow In TabularSection Do
				SettingUpLineAccountingAccounts = TableRow[SetupParameters.GLAccountSettings];
				If ValueIsFilled(SettingUpLineAccountingAccounts) Then
					DataPathParts = New Array();
					DataPathParts.Add(DataPath);
					DataPathParts.Add(TabularSection.IndexOf(TableRow));
					If AccountingForVersionsOfAccountingAccountSettings Then
						PartsOfVersionPath = Common.CopyRecursive(DataPathParts);
						PartsOfVersionPath.Add(SetupParameters.LedgerAccountSettingVersion);
					EndIf;
					DataPathParts.Add(SetupParameters.GLAccountSettings);
					If DocumentSettings.Find(SettingUpLineAccountingAccounts) = Undefined Then
						DocumentSettings.Add(SettingUpLineAccountingAccounts);
						PathsToSettingsData.Insert(SettingUpLineAccountingAccounts, DataPathParts);
						If AccountingForVersionsOfAccountingAccountSettings Then
							PathsToSettingsVersion.Insert(SettingUpLineAccountingAccounts, PartsOfVersionPath);
						EndIf;
					Else
						NewTake = DuplicateSettings.Add();
						NewTake.Ref = SettingUpLineAccountingAccounts;
						NewTake.DataPath = DataPathParts;
						If AccountingForVersionsOfAccountingAccountSettings Then
							NewTake.VersionPath = PartsOfVersionPath;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		ElsIf Not ValueIsFilled(Object[DataPath]) Then
		ElsIf DocumentSettings.Find(Object[DataPath]) = Undefined Then
			DocumentSettings.Add(Object[DataPath]);
			PathsToSettingsData.Insert(Object[DataPath], DataPath);
			If AccountingForVersionsOfAccountingAccountSettings Then
				PathsToSettingsVersion.Insert(Object[DataPath], SetupParameters.LedgerAccountSettingVersion);
			EndIf;
		Else
			NewTake = DuplicateSettings.Add();
			NewTake.Ref = Object[DataPath];
			NewTake.DataPath = DataPath;
			If AccountingForVersionsOfAccountingAccountSettings Then
				NewTake.VersionPath = SetupParameters.LedgerAccountSettingVersion;
			EndIf;
		EndIf;
	EndDo;
	
	Query = New Query();
	Query.SetParameter("ThisLink", ObjectRef);
	Query.SetParameter("DeletionMark", DeletionMark);
	Query.SetParameter("SettingsList", DocumentSettings);
	Query.SetParameter("ListOfTakes", DuplicateSettings.UnloadColumn("Ref"));
	
	QueriesTexts = New Array();
	
	AccountSettingsData_ = Undefined;
	SetPrivilegedMode(True);
	
	If Object.AdditionalProperties.Property("AccountingAccountSettings", AccountSettingsData_)
		And TypeOf(AccountSettingsData_) = Type("Map") Then
		
		QueriesTexts.Add("SELECT
		|	AccountingAccountSettings.Ref            AS Ref,
		|	AccountingAccountSettings.DeletionMark   AS DeletionMark,
		|	AccountingAccountSettings.SettingsOwner AS SettingsOwner
		|	,
		|	AccountingAccountSettings.FinancialAccountingSettings AS FinancialAccountingSettings
		|FROM
		|	Catalog.OtherTransactionsGLAccountsSettings AS AccountingAccountSettings
		|WHERE
		|	AccountingAccountSettings.Ref IN (&SettingsList)");
		
		If Not Object.IsNew() Then
			QueriesTexts.Add("SELECT
			|	AccountingAccountSettings.Ref AS Ref
			|FROM
			|	Catalog.OtherTransactionsGLAccountsSettings AS AccountingAccountSettings
			|WHERE
			|	AccountingAccountSettings.SettingsOwner = &ThisLink
			|	AND NOT AccountingAccountSettings.Ref IN (&SettingsList)
			|	AND NOT AccountingAccountSettings.DeletionMark");
		EndIf;
		
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Result = Query.ExecuteBatch();

		If Not ValueIsFilled(ObjectRef) Then
			ObjectRef = ObjectManager1.GetRef();
			Object.SetNewObjectRef(ObjectRef);
		EndIf;
		
		SelectingSettings = Result[0].Select(); 
		
		For Each SettingUpDocument In DocumentSettings Do
			ConfigurationData = AccountSettingsData_[SettingUpDocument];
			TheStructureOfTheSearch = New Structure("Ref", SettingUpDocument);
			
			SelectingSettings.Reset();
			SettingFoundInSelection = SelectingSettings.FindNext(TheStructureOfTheSearch);
			DocumentSettingsChanged = False;
			
			If SettingFoundInSelection Then
				If Not ValueIsFilled(SelectingSettings.SettingsOwner) Then
					If ConfigurationData <> Undefined Then
						ChangeAccountingAccountSettingsElement(SettingUpDocument, ConfigurationData, DeletionMark, ObjectRef);
						DocumentSettingsChanged = True;
					Else
						ChangeAccountingAccountSettingsElement(SettingUpDocument, SelectingSettings, DeletionMark, ObjectRef);
					EndIf;
				ElsIf SelectingSettings.SettingsOwner <> ObjectRef Then
					If ConfigurationData <> Undefined Then
						NewSetting = NewAccountSettingsElement(ConfigurationData, DeletionMark, ObjectRef);
						DocumentSettingsChanged = True;
					Else
						NewSetting = NewAccountSettingsElement(SelectingSettings, DeletionMark, ObjectRef);
					EndIf;
					SetValueOfItemSProps(Object, PathsToSettingsData[SettingUpDocument], NewSetting);
				ElsIf ConfigurationData <> Undefined
					And AccountSettingsChanged_(ConfigurationData, DeletionMark, SelectingSettings) Then
					ChangeAccountingAccountSettingsElement(SettingUpDocument, ConfigurationData, DeletionMark);
					DocumentSettingsChanged = True;
				EndIf;
			ElsIf ConfigurationData <> Undefined Then
				NewAccountSettingsElement(ConfigurationData, DeletionMark, ObjectRef, SettingUpDocument);
				DocumentSettingsChanged = True;
			Else
				SetValueOfItemSProps(Object, PathsToSettingsData[SettingUpDocument], Undefined);
				DocumentSettingsChanged = True;
			EndIf;
			
			If DocumentSettingsChanged Then
				PathToVersionSettings = PathsToSettingsVersion[SettingUpDocument];
				If PathToVersionSettings <> Undefined Then
					UpdateVersionOfAccountingAccountsSettings(Object, PathToVersionSettings);
				EndIf;
			EndIf;
			
			ArrayOfDuplicates = DuplicateSettings.FindRows(TheStructureOfTheSearch);
			For Each DoubleSettings In ArrayOfDuplicates Do
				DocumentSettingsChanged = False;
				If ConfigurationData <> Undefined Then
					NewSetting = NewAccountSettingsElement(ConfigurationData, DeletionMark, ObjectRef);
					DocumentSettingsChanged = True;
				ElsIf SettingFoundInSelection Then
					NewSetting = NewAccountSettingsElement(SelectingSettings, DeletionMark, ObjectRef);
				Else
					NewSetting = Undefined;
					DocumentSettingsChanged = True;
				EndIf;
				SetValueOfItemSProps(Object, DoubleSettings.DataPath, NewSetting);
				If DocumentSettingsChanged And ValueIsFilled(DoubleSettings.VersionPath) Then
					UpdateVersionOfAccountingAccountsSettings(Object, DoubleSettings.VersionPath);
				EndIf;
			EndDo;
		EndDo;
		
		DeletionMark = True;
		
	Else
		
		QueriesTexts.Add("SELECT
		|	AccountingAccountSettings.Ref            AS Ref,
		|	AccountingAccountSettings.SettingsOwner AS SettingsOwner
		|	,
		|	AccountingAccountSettings.FinancialAccountingSettings AS FinancialAccountingSettings
		|FROM
		|	Catalog.OtherTransactionsGLAccountsSettings AS AccountingAccountSettings
		|WHERE
		|	(AccountingAccountSettings.Ref IN (&SettingsList)
		|	AND AccountingAccountSettings.SettingsOwner <> &ThisLink)
		|	OR AccountingAccountSettings.Ref IN (&ListOfTakes)");
		
		If Not Object.IsNew() Then
			QueryText = "SELECT
			|	AccountingAccountSettings.Ref AS Ref
			|FROM
			|	Catalog.OtherTransactionsGLAccountsSettings AS AccountingAccountSettings
			|WHERE
			|	AccountingAccountSettings.SettingsOwner = &ThisLink
			|	AND AccountingAccountSettings.DeletionMark <> &DeletionMark";
			
			If Not DeletionMark Then
				QueryText = QueryText + "
				|	AND AccountingAccountSettings.Ref IN (&SettingsList)";
			EndIf;
			
			QueriesTexts.Add(QueryText);
		EndIf;

		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Result = Query.ExecuteBatch();
		
		If Not Result[0].IsEmpty() Then
			If Not ValueIsFilled(ObjectRef) Then
				ObjectRef = ObjectManager1.GetRef();
				Object.SetNewObjectRef(ObjectRef);
			EndIf;
			
			SelectingSettings = Result[0].Select();
			While SelectingSettings.Next() Do
				If Not ValueIsFilled(SelectingSettings.SettingsOwner) Then
					ChangeAccountingAccountSettingsElement(SelectingSettings.Ref, SelectingSettings, DeletionMark, ObjectRef);
				ElsIf SelectingSettings.SettingsOwner <> ObjectRef Then
					NewSetting = NewAccountSettingsElement(SelectingSettings, DeletionMark, ObjectRef);
					SetValueOfItemSProps(Object, PathsToSettingsData[SelectingSettings.Ref], NewSetting);
				EndIf;
				
				TheStructureOfTheSearch = New Structure("Ref", SelectingSettings.Ref);
				ArrayOfDuplicates = DuplicateSettings.FindRows(TheStructureOfTheSearch);
				
				For Each DoubleSettings In ArrayOfDuplicates Do
					NewSetting = NewAccountSettingsElement(SelectingSettings, DeletionMark, ObjectRef);
					SetValueOfItemSProps(Object, DoubleSettings.DataPath, NewSetting);
				EndDo;
			EndDo;
		EndIf;
		
	EndIf;
	
	If Result.Count() > 1 Then
		SelectingSettings = Result[1].Select();
		While SelectingSettings.Next() Do
			SettingUpInvoicesObject = SelectingSettings.Ref.GetObject();
			SettingUpInvoicesObject.SetDeletionMark(DeletionMark);
		EndDo;
	EndIf;
	
EndProcedure

// It is intended for copying the composition of other operations accounting account settings from one object accounting account setting to another.
// If the link to setting up the receiver accounts is not filled in, a new element of the account settings directory will be created.
// Otherwise, the receiver account setup will be overwritten if its data differs from the source account setup.
// Limitations of the current implementation: the source and receiver account settings must have the same data path.
// 
// Parameters:
//  Object - DocumentObject,
//           Referenceobject - writable object
//  AccountSettings_1 - Array, Structure - Settings (See GLAccountSettingsServer.SetupParameters)
// 	                                         .
// 	                                         If multiple accounts are configured for an object, an array is passed.
//                                                 Each element of the array is a parameter structure.
//  SettingUpInvoicesSource - String - name of the account details with the copied account settings
//  SettingUpAccounts - String - name of the account setup detail to copy the source settings to
//
Procedure CopyItemInvoiceSettings(Object, AccountSettings_1, SettingUpInvoicesSource, SettingUpAccounts) Export
	
	If Not LocalAccountingAccountsCanBeConfigured() And Not SettingUpInternationalAccountingAccountsIsAvailable() Then
		Return;
	EndIf;
	
	ObjectMetadata1 = Object.Metadata();
	ObjectManager1   = Common.ObjectManagerByFullName(ObjectMetadata1.FullName());
	DeletionMark  = Object.DeletionMark;
	
	If Object.IsNew() Then
		ObjectRef = Object.GetNewObjectRef();
	Else
		ObjectRef = Object.Ref;
	EndIf;
	
	If TypeOf(AccountSettings_1) = Type("Array") Then
		ArrayOfSettings = AccountSettings_1;
	Else
		ArrayOfSettings = CommonClientServer.ValueInArray(AccountSettings_1);
	EndIf;
	
	SettingsSource_   = New Array();
	ReceiverSettings   = New Array();
	DataPathsSource = New Map();
	
	For Each SetupParameters In ArrayOfSettings Do
		If SetupParameters.GLAccountSettings = SettingUpInvoicesSource
		 Or SetupParameters.GLAccountSettings = SettingUpAccounts Then
			DataPathParts = StrSplit(SetupParameters.DataPath, ".", False);
			If DataPathParts[0] = "Object" Then
				DataPathParts.Delete(0);
			EndIf;
			
			If DataPathParts.Count() = 0 Then
				DataPath = SetupParameters.GLAccountSettings;
			ElsIf DataPathParts.Count() = 1 Then
				DataPath = DataPathParts[0];
			Else
				Continue;
			EndIf;
			
			If ObjectMetadata1.TabularSections.Find(DataPath) <> Undefined Then
				TabularSection = Object[DataPath]; // TabularSection -
				For Each TableRow In TabularSection Do
					If Not ValueIsFilled(TableRow[SetupParameters.GLAccountSettings]) Then
					ElsIf SetupParameters.GLAccountSettings = SettingUpInvoicesSource Then
						SettingsSource_.Add(TableRow[SetupParameters.GLAccountSettings]);
						DataPathParts = New Array();
						DataPathParts.Add(DataPath);
						DataPathParts.Add(TabularSection.IndexOf(TableRow));
						DataPathParts.Add(SetupParameters.GLAccountSettings);
						DataPathsSource.Insert(TableRow[SetupParameters.GLAccountSettings], DataPathParts);
					ElsIf SetupParameters.GLAccountSettings = SettingUpAccounts Then
						ReceiverSettings.Add(TableRow[SetupParameters.GLAccountSettings]);
					EndIf;
				EndDo;
			ElsIf Not ValueIsFilled(Object[DataPath]) Then
			ElsIf SetupParameters.GLAccountSettings = SettingUpInvoicesSource Then
				SettingsSource_.Add(Object[DataPath]);
				DataPathsSource.Insert(Object[DataPath], DataPath);
			ElsIf SetupParameters.GLAccountSettings = SettingUpAccounts Then
				ReceiverSettings.Add(Object[DataPath]);
			EndIf;
		EndIf;
	EndDo;
	
	If SettingsSource_.Count() = 0 Then
		Return;
	ElsIf Not ValueIsFilled(ObjectRef) Then
		ObjectRef = ObjectManager1.GetRef();
		Object.SetNewObjectRef(ObjectRef);
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryText = "
	|SELECT
	|	AccountingAccountSettings.Ref    AS Ref
	|	,
	|	AccountingAccountSettings.FinancialAccountingSettings AS FinancialAccountingSettings
	|FROM
	|	Catalog.OtherTransactionsGLAccountsSettings AS AccountingAccountSettings
	|WHERE
	|	AccountingAccountSettings.Ref IN (&SettingsSource_)
	|
	|;
	|
	|SELECT
	|	AccountingAccountSettings.Ref          AS Ref,
	|	AccountingAccountSettings.DeletionMark AS DeletionMark
	|	,
	|	AccountingAccountSettings.FinancialAccountingSettings AS FinancialAccountingSettings
	|FROM
	|	Catalog.OtherTransactionsGLAccountsSettings AS AccountingAccountSettings
	|WHERE
	|	AccountingAccountSettings.Ref IN (&ReceiverSettings)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("SettingsSource_", SettingsSource_);
	Query.SetParameter("ReceiverSettings", ReceiverSettings);
	Results = Query.ExecuteBatch();
	
	SamplingSource = Results[0].Select();
	SamplingReceiver = Results[1].Select();
	
	While SamplingSource.Next() Do
		DataPath = DataPathsSource[SamplingSource.Ref];
		If TypeOf(DataPath) = Type("Array") Then
			SettingUpReceiver = Object[DataPath[0]][DataPath[1]][SettingUpAccounts];
		Else
			SettingUpReceiver = Object[SettingUpAccounts];
		EndIf;
		
		If Not ValueIsFilled(SettingUpReceiver) Then
			NewSetting = NewAccountSettingsElement(SamplingSource, DeletionMark, ObjectRef);
			If TypeOf(DataPath) = Type("Array") Then
				Object[DataPath[0]][DataPath[1]][SettingUpAccounts] = NewSetting;
			Else
				Object[SettingUpAccounts] = NewSetting;
			EndIf;
		Else
			SamplingReceiver.Reset();
			If Not SamplingReceiver.FindNext(SettingUpReceiver, "Ref") Then
				NewAccountSettingsElement(SamplingSource, DeletionMark, ObjectRef, SettingUpReceiver);
			ElsIf AccountSettingsChanged_(SamplingSource, DeletionMark, SamplingReceiver) Then
				ChangeAccountingAccountSettingsElement(SettingUpReceiver, SamplingSource, DeletionMark);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// It is used for saving created and changed other operations account settings in the form.
// It is mainly used in additional forms and processing for changing table parts.
// Called when the beginning of the processing or before running the code the form is closed.
// The newly created settings for accounts are written without an owner, the owner is recorded in the object record,
// which uses established settings.
// 
// Parameters:
//  Form - ClientApplicationForm - form with accounting account settings
// 
Procedure RecordFormSInvoiceSettings(Form) Export
	
	AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
	
	If AccountSettingsData_1 = Undefined Then
		Return;
	ElsIf Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
		Return;
	EndIf;
	
	FormSettings = New Array();
	
	For Each KeyAndValue In AccountSettingsData_1.AccountingAccountSettings Do
		If ValueIsFilled(KeyAndValue.Key) Then
			FormSettings.Add(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	If FormSettings.Count() = 0 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryText = "
	|SELECT
	|	AccountingAccountSettings.Ref          AS Ref,
	|	AccountingAccountSettings.DeletionMark AS DeletionMark
	|	,
	|	AccountingAccountSettings.FinancialAccountingSettings AS FinancialAccountingSettings
	|FROM
	|	Catalog.OtherTransactionsGLAccountsSettings AS AccountingAccountSettings
	|WHERE
	|	AccountingAccountSettings.Ref IN (&SettingsList)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("SettingsList", FormSettings);
	Result = Query.Execute();
	
	SelectingSettings = Result.Select();
	DeletionMark = True;
	Owner = Undefined;
	
	For Each FormSettingsItem In FormSettings Do
		ConfigurationData = AccountSettingsData_1.AccountingAccountSettings[FormSettingsItem];
		TheStructureOfTheSearch = New Structure("Ref", FormSettingsItem);
		
		SelectingSettings.Reset();
		If SelectingSettings.FindNext(TheStructureOfTheSearch) Then
			If ConfigurationData <> Undefined
				And AccountSettingsChanged_(ConfigurationData, SelectingSettings.DeletionMark, SelectingSettings) Then
				ChangeAccountingAccountSettingsElement(FormSettingsItem, ConfigurationData, SelectingSettings.DeletionMark);
			EndIf;
		ElsIf ConfigurationData <> Undefined Then
			NewAccountSettingsElement(ConfigurationData, DeletionMark, Owner, FormSettingsItem);
		EndIf;
	EndDo;
	
EndProcedure

// Fills in the default account settings according to the assets and liabilities item.
// Called from the Batch processing mechanism of the table part.
// 
// Parameters:
//  CurrentRow - Structure - This line.
//  ActionParameters - Structure - the parameters of the action. (See GLAccountSettingsClientServer.InsertActionFillInDefaultAccountingAccountsSetting):
//   *ActionInForm - Boolean - flag for performing an action in the form of an object
//   *AccountSettingsData_1 - Structure of See GLAccountSettingsClientServer.NewAccountSettingsData
//
Procedure FillInTheDefaultAccountSetting(CurrentRow, ActionParameters) Export
	
	AccountSettingsData_1 = ActionParameters.AccountSettingsData_1;
	
	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		If GLAccountSettingsClientServer.YouNeedToFillInDefaultAccountingAccountsSettings(CurrentRow, CurrentRow, SetupParameters) Then
			If ActionParameters.ActionInForm Then
				DefaultSetting = GLAccountSettingsInternalServerCall.DefaultAccountSettingsData(
					CurrentRow[SetupParameters.AssetAndLiabilityItem], AccountSettingsData_1);
				GLAccountSettingsClientServer.FillInTheDefaultAccountSetting(CurrentRow, SetupParameters, DefaultSetting, AccountSettingsData_1);
			Else
				DefaultSetting = GLAccountSettingsInternalServerCall.DefaultAccountSettingsData(CurrentRow[SetupParameters.AssetAndLiabilityItem]);
				If DefaultSetting[CurrentRow[SetupParameters.AssetAndLiabilityItem]] <> Undefined Then
					ConfigurationData = DefaultSetting[CurrentRow[SetupParameters.AssetAndLiabilityItem]].ConfigurationData;
					CurrentRow[SetupParameters.GLAccountSettings] = NewAccountSettings_(ConfigurationData);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Fills in the default account settings according to the assets and liabilities item. Called from the mechanism of batch 
// processing of table parts.
// 
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString.CurrentRow
//  ActionParameters - Structure - the parameters of the action. (See GLAccountSettingsClientServer.InsertActionFillInDefaultAccountingAccountsSetting):
//   *ActionInForm - Boolean - flag for performing an action in the form of an object
//   *AccountSettingsData_1 - See GLAccountSettingsClientServer.NewAccountSettingsData
//   CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure FillInDefaultAccountingAccountSettingsInBatches(CurrentRow, ActionParameters, CachedValues) Export
	
	AccountSettingsData_1 = ActionParameters.AccountSettingsData_1;
	
	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		If GLAccountSettingsClientServer.YouNeedToFillInDefaultAccountingAccountsSettings(CurrentRow, CurrentRow, SetupParameters) Then
			If ActionParameters.ActionInForm Then
				DefaultSetting = AccountSettingsDataIsBatchByDefault(
					CachedValues, SetupParameters.DataPath, AccountSettingsData_1);
					
				GLAccountSettingsClientServer.FillInTheDefaultAccountSetting(
					CurrentRow,
					SetupParameters,
					DefaultSetting,
					AccountSettingsData_1);
			Else
				DefaultSetting = AccountSettingsDataIsBatchByDefault(
					CachedValues, SetupParameters.DataPath);
				
				If DefaultSetting[CurrentRow[SetupParameters.AssetAndLiabilityItem]] <> Undefined Then
					ConfigurationData = DefaultSetting[CurrentRow[SetupParameters.AssetAndLiabilityItem]].ConfigurationData;
					CurrentRow[SetupParameters.GLAccountSettings] = NewAccountSettings_(ConfigurationData);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the default invoice settings
// when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddQueryTextsToDefaultAccountSettings(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInTheDefaultAccountSetting",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		AccountSettingsData_1 = ActionParameters.AccountSettingsData_1;
	
		For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
			
			If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource(
					SetupParameters.AssetAndLiabilityItem,
					CachedValues) Then
			
				QueryText = "SELECT
				|	TTDataSource.IdOfTTRow AS IdOfTTRow,
				|	AssetLiabilityItems.Ref    AS Ref
				|	,
				|	AssetLiabilityItems.LedgerAccountsInEntrySettings AS LedgerAccountsInEntrySettings,
				|	AssetLiabilityItems.FinancialAccountingSettings AS FinancialAccountingSettings
				|FROM
				|	TTDataSource AS TTDataSource
				|	LEFT JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
				|		ON &CostItemField = AssetLiabilityItems.Ref
				|";
				QueryText = StrReplace(QueryText, "&CostItemField", "TTDataSource." + SetupParameters.AssetAndLiabilityItem);
				
				QueryName1 = "SettingUpAccountingAccountsByDefault" + StrReplace(SetupParameters.DataPath, ".", "");
				QueryDetails.QueriesTexts.Add(QueryText, QueryName1);
				
			EndIf;
				
		EndDo;
	EndIf;
	
EndProcedure

// Fills in the Presentation of the accounting account settings.
// Called from the Batch processing mechanism of the table part.
// 
// Parameters:
//  CurrentRow - Structure - This line.
//  ActionParameters - Structure - the parameters of the action. (See GLAccountSettingsClientServer.InsertActionFillPresentationAccountSettingsAccounting):
//   *AccountSettingsData_1 - Structure of See GLAccountSettingsClientServer.NewAccountSettingsData
//
Procedure FillInInvoiceSettingsPresentation(CurrentRow, ActionParameters) Export
	
	AccountSettingsData_1 = ActionParameters.AccountSettingsData_1;
	
	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		CurrentRow[SetupParameters.Presentation] = 
			GLAccountSettingsClientServer.ReflectionSettingPresentation(CurrentRow, SetupParameters, AccountSettingsData_1);
	EndDo;
	
EndProcedure

// It is used to create a new element of the accounting settings directory based on the transmitted data.
// It is used when programmatically filling in the settings of accounting accounts for document objects and reference books,
// based on known values of accounting accounts and sub-accounts.
// 
// If you create an accounting setting for an object that is being edited in the form, you must
// pass the form. In this case, these settings will be saved in the mechanism cache, and the new
// settings element will be written before the form object being edited is written.
// 
// If the accounting setting is filled in for a module variable object, then the new
// settings element is written directly to the function. The newly created account setup is recorded 
// without an owner. the owner is recorded when the object that uses the created setup is recorded.
// 
// Parameters:
//  ConfigurationData - See GLAccountSettingsClientServer.CompositionOfAccountingAccountSettings
//  Form - ClientApplicationForm - form of the document or reference object to edit
// 
// Returns:
//  CatalogRef.OtherTransactionsGLAccountsSettings - a new accounting account setup element with the transferred account setup data.
//   When passing a form to the Form parameter, it is a link to a new (not yet existing) element of the settings directory.
//   If the form is not passed, this is the link of the new element of the settings directory created during the function operation.
// 
Function NewAccountSettings_(ConfigurationData, Form = Undefined) Export
	
	NewSetting = Catalogs.OtherTransactionsGLAccountsSettings.EmptyRef();
	
	If Form <> Undefined Then
			
		AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
		
		If AccountSettingsData_1 = Undefined Then
			Return NewSetting;
		ElsIf Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
			Return NewSetting;
		ElsIf ConfigurationData = Undefined Then
			Return NewSetting;
		EndIf;
		
		NewSetting = GLAccountSettingsInternalServerCall.LinkToNewInvoiceSettingsElement();
		AccountSettingsData_1.AccountingAccountSettings.Insert(NewSetting, Common.CopyRecursive(ConfigurationData));
		
	ElsIf ConfigurationData <> Undefined Then
		
		SetPrivilegedMode(True);
		
		DeletionMark = True;
		Owner = Undefined;
		NewSetting = NewAccountSettingsElement(ConfigurationData, DeletionMark, Owner);
		
	EndIf;
	
	Return NewSetting;
	
EndFunction

// It is used to copy the contents of the accounting account settings to a new element in the settings directory.
// It is used when programmatically filling in the account settings for document and reference objects,
// where simply assigning the account settings link obtained from another object is not allowed.
// 
// If the accounting settings are filled in for an object that is being edited in the form,
// the form must be passed. In this case, these settings will be saved in the mechanism cache, and the new
// settings element will be written before the form object being edited is written.
// 
// If the accounting setting is filled in for a module variable object, then the new
// settings element is written directly to the function. The newly created account setup is recorded 
// without an owner. the owner is recorded when the object that uses the created setup is recorded.
// 
// Parameters:
//  SettingUpInvoicesSource - CatalogRef.OtherTransactionsGLAccountsSettings - setting up accounting accounts that you want to copy to the new setting
//  Form - ClientApplicationForm - form of the document or reference object to edit
// 
// Returns:
//  CatalogRef.OtherTransactionsGLAccountsSettings - a new accounting account setup element with source account setup data.
//   When passing the form to the Form parameter, it is a link to a new (not yet existing) element of the settings directory.
//   If the form is not passed, this is the link of the new element of the settings directory created during the function operation.
// 
Function CopyOfAccountSettings(SettingUpInvoicesSource, Form = Undefined) Export
	
	NewSetting = Catalogs.OtherTransactionsGLAccountsSettings.EmptyRef();
	
	If Form <> Undefined Then
			
		AccountSettingsData_1 = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "GLAccountSettings");
		
		If AccountSettingsData_1 = Undefined Then
			Return NewSetting;
		ElsIf Not AccountSettingsData_1.YouCanConfigureAccountingAccounts Then
			Return NewSetting;
		EndIf;
		
		ConfigurationData = AccountSettingsData_1.AccountingAccountSettings[SettingUpInvoicesSource];
		
		If ConfigurationData <> Undefined Then
			NewSetting = NewAccountSettings_(ConfigurationData, Form);
		ElsIf ValueIsFilled(SettingUpInvoicesSource) Then
			ConfigurationData = AccountSettingsData_(SettingUpInvoicesSource);
			NewSetting = NewAccountSettings_(ConfigurationData[SettingUpInvoicesSource], Form);
		EndIf;
		
	ElsIf ValueIsFilled(SettingUpInvoicesSource) Then
		
		ConfigurationData = AccountSettingsData_(SettingUpInvoicesSource);
		NewSetting = NewAccountSettings_(ConfigurationData[SettingUpInvoicesSource]);
		
	EndIf;
	
	Return NewSetting;
	
EndFunction

#EndRegion

#Region SettingUpProductAccountingAccounts

// Checks whether the object's accounting accounts are filled in.
// 
// Parameters:
// 	Object - Arbitrary - Object for storing account settings
//	Cancel - Boolean - Failure Flag
//	CheckedAttributes - Array - Verified Bank details
//
Procedure ProcessingVerificationOfFillingInProductAccountingInvoices(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

#EndRegion

#Region SettingUpExtdimensionSelection

// The function returns the types of values for which selection by organization makes sense
//
// Returns:
//	TypeDescription - Description of the types of directories that depend on the organization.
//
Function TypesConnectedWithTheCompany() Export
	
	TypeString = 
		"CatalogRef.CompaniesBankAccounts,
		|CatalogRef.CounterpartyContracts,
		|CatalogRef.LoanAndDepositContracts,
		|CatalogRef.LeaseContract,
		|CatalogRef.IntercompanyContracts
		|";

	Return New TypeDescription(Documents.AllRefsType(), TypeString);
	
EndFunction

#EndRegion

// Called from the corresponding form handler with custom accounting accounts
//
// Parameters:
//  Form - ClientApplicationForm - form for which you need to check whether the accounting account settings (and sub-accounts) are filled in)
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Form, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Saves accounting invoices.
// 
// Parameters:
//  Form - ClientApplicationForm - the shape of the object settings;
//  Cancel - Boolean - Whether the recording was refused, see the "Refusal" parameter of the server recording event;
// 	Object - CatalogObject, FormDataStructure, Arbitrary - The object for storing account settings, see the parameter "Current object" of the event when recording the server;
// 	WriteParameters - Structure - contains recording parameters, see the "Recording parameters" parameter of the server recording event.
//
Procedure WhenWritingAccountSettingsObject(Form, Cancel, Object, WriteParameters) Export
EndProcedure

// Loads accounting invoices.
// 
// Parameters:
// Form - ClientApplicationForm - The Form Of the configuration object. in The Form of Attributes:
// 	* Object - FormDataStructure - contains fields:
// 		** Ref - CatalogRef -
//
Procedure WhenReadingCreatingAccountSettingsObject(Form) Export

	AccountingSections = Undefined;
	
	AccountingAccountSettings_ = AccountingAccountSettings_(AccountingSections);
	AccountingAccountSettings_.NameOfAccountingSettingsGroup = "AccountsGroup";
	AccountingAccountSettings_.PrefixOfFormElements = "GLAccountSettings";
	AccountingAccountSettings_.DataPathPrefix = "GLAccountSettings_";
	AccountingAccountSettings_.PrefixOfPathToDetails = "Object.";
	
	GroupOfAccountConfigurationElements = Form.Items.Find(AccountingAccountSettings_.NameOfAccountingSettingsGroup);
	YouCanConfigureAccountingAccounts = AccountingAccountSettings_.YouCanConfigureAccountingAccounts And GroupOfAccountConfigurationElements <> Undefined;
	AnalyticsIsUsedForInvoices = False;
	YouCanConfigureAccountingAccounts = YouCanConfigureAccountingAccounts And AnalyticsIsUsedForInvoices;
	If GroupOfAccountConfigurationElements <> Undefined Then
		GroupOfAccountConfigurationElements.Visible = YouCanConfigureAccountingAccounts;
	EndIf;
	If Not YouCanConfigureAccountingAccounts Then
		Return;
	EndIf;
	
	
EndProcedure

// Returns the structure of account settings.
// 
// Parameters:
// 	AccountingSections - Undefined, Array -
// Returns:
// 	Structure - Parameters for setting up accounting accounts
//
Function AccountingAccountSettings_(AccountingSections = Undefined) Export
	
	SetupParameters = New Structure;
	SetupParameters.Insert("NameOfAccountingSettingsGroup", "");
	SetupParameters.Insert("PrefixOfFormElements", "");
	SetupParameters.Insert("DataPathPrefix", "");
	SetupParameters.Insert("PrefixOfPathToDetails", "");
	SetupParameters.Insert("AccountsWithDynamicSelectionParameters", New Array);
	SetupParameters.Insert("AccountsWithDynamicProperties", New Array);
	SetupParameters.Insert("EditingInList", False);
	SetupParameters.Insert("CreateInCaseOfAbsence", True);
	SetupParameters.Insert("SplitIntoSections", False); // The Attributes on the form will be named based on the section to which it belongs
	SetupParameters.Insert("DivideElementsIntoSections", False); // The element on the form will be named based on the section to which it belongs
	SetupParameters.Insert("SectionsSettings", New Map);
	SetupParameters.Insert("ExceptionSettingIsUsed", False); // The exception settings for the organization and place of accounting are used. It is necessary to display a hyperlink to the form to proceed to setting up exception accounts
	SetupParameters.Insert("ListOfAccountingSections", New ValueList);
	SetupParameters.Insert("AnalyticsDetails_", New Structure);
	SetupParameters.Insert("CollapsibleGroups", False);
	SetupParameters.Insert("CommonAttributes", New Structure);
	SetupParameters.Insert("PathsToAnalyticsDetails", New Structure);
	SetupParameters.Insert("AvailableAccountingAccounts", New Structure);
	SetupParameters.Insert("YouCanConfigureAccountingAccounts", False);
	SetupParameters.Insert("YouCanChangeAccountingAccountSettings", False);
	SetupParameters.Insert("AccountForDefaultInvoices", False);
	SetupParameters.Insert("ConsiderAccountsThatRequireConfiguration", False);
	SetupParameters.Insert("AccountForChangedAccountingAccounts", False);
	SetupParameters.Insert("LongTermAccountingAccountsAreUsed", False);
	SetupParameters.Insert("UseSeparateTables", False); // For each section setting, a separate table of values will be created on the form
	SetupParameters.Insert("LongTermAccountsInSeparateLine", False); // Long-term accounts are displayed in one line along with short-term accounts
	
	Colors = New Structure;
	Colors.Insert("NotFilled", StyleColors.EmptyTableField);
	Colors.Insert("Information", StyleColors.HelpText);
	Colors.Insert("Canceled", StyleColors.TextColorOfCanceledRowOfDocument);
	Colors.Insert("AutoColor", StyleColors.FieldTextColor);
	SetupParameters.Insert("Colors", Colors);
	
	SetupParameters.Insert("Period", CurrentSessionDate());
	SetupParameters.Insert("DefaultAccount", Undefined);
	
	Block = New Structure; // The set of data on blocking Attributes and the period
	Block.Insert("Used", True); // Whether the block is being used
	Block.Insert("PeriodEndClosingDate", '00010101'); // The date when changes were banned at the current moment, if the use of dates when changes were banned is enabled
	Block.Insert("MonthBlockingDate", '00010101'); // Month closing blocking date (maximum)
	Block.Insert("LastReflectionDate", '00010101'); // The last date of reflection of documents in Local accounting
	Block.Insert("EditingAllowed", False); // It is possible to edit the specified accounting accounts
	Block.Insert("DisabledByUser", False); // Blocking the editing of the specified accounting accounts is disabled by the user via the corresponding form
	SetupParameters.Insert("Block", Block);
	
	
	Return SetupParameters;
	
EndFunction
	
#EndRegion

#Region Internal

Function LocalAccountingAccountsCanBeConfigured() Export
	
	YouCanConfigureAccountingAccounts = False;
	
	
	Return YouCanConfigureAccountingAccounts;
	
EndFunction

Function SettingUpInternationalAccountingAccountsIsAvailable() Export
	
	YouCanConfigureAccountingAccounts = False;
	YouCanConfigureAccountingAccounts = GetFunctionalOption("UseFinancialAccounting")
		And GetFunctionalOption("SettingOfPostingByAccountingObjects")
		And AccessRight("View", Metadata.Catalogs.FinancialAccountingChartsOfAccounts)
		And AccessRight("View", Metadata.ChartsOfAccounts.International);
	Return YouCanConfigureAccountingAccounts;
	
EndFunction

Function AccountSettingsData_(AccountingAccountSettings) Export
	
	ReturnValue = New Map();
	
	If TypeOf(AccountingAccountSettings) = Type("Array") Then
		SettingsList = AccountingAccountSettings;
	Else
		SettingsList = CommonClientServer.ValueInArray(AccountingAccountSettings);
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.SetParameter("SettingsList", SettingsList);
	Query.Text = "
	|SELECT
	|	AccountingAccountSettings.Ref    AS Ref
	|	,
	|	AccountingAccountSettings.FinancialAccountingSettings AS FinancialAccountingSettings
	|FROM
	|	Catalog.OtherTransactionsGLAccountsSettings AS AccountingAccountSettings
	|WHERE
	|	AccountingAccountSettings.Ref IN (&SettingsList)
	|";
	
	Result = Query.Execute();
	SelectingSettings = Result.Select(); 
	
	While SelectingSettings.Next() Do
		ConfigurationData = GLAccountSettingsClientServer.CompositionOfAccountingAccountSettings();
		ResultOfSettingUpInternationalAccounting = SelectingSettings.FinancialAccountingSettings; // QueryResultSelection -
		SelectionOfInternationalAccountingSettings = ResultOfSettingUpInternationalAccounting.Select();
		While SelectionOfInternationalAccountingSettings.Next() Do
			InternationalConfigurationData = GLAccountSettingsClientServer.CompositionOfInternationalAccountingAccounts();
			FillPropertyValues(InternationalConfigurationData, SelectionOfInternationalAccountingSettings);
			ConfigurationData.FinancialAccountingSettings.Add(InternationalConfigurationData);
		EndDo;
		ReturnValue.Insert(SelectingSettings.Ref, ConfigurationData);
	EndDo;
	
	Return ReturnValue;
	
EndFunction


// Generates elements of the reference list customizationaccount of other Operations based on the details of the header and table parts
// and fills in the details of the customizationaccount Server.
// 
// Parameters:
// 	Object - DocumentObject - The document in which you need to fill in the account Settings accountserverreferences
// 	Postfix - String - Postfix in the prop name
Procedure FillInAccountingAccountSettings(Object, Postfix = "") Export
	
	
EndProcedure

#EndRegion

#Region Private

#Region SettingUpAccountsForOtherTransactions

Function OperationReflectionSettingsData(Form, AccountSettings_1)
	
	If TypeOf(AccountSettings_1) = Type("Array") Then
		ArrayOfSettings = AccountSettings_1;
	Else
		ArrayOfSettings = CommonClientServer.ValueInArray(AccountSettings_1);
	EndIf;
	
	CheckAccountSettings(Form, ArrayOfSettings);
	
	MatchingSettingsToFormElements = New Structure;
	IndexOf = 0;
	For Each SetupParameters In ArrayOfSettings Do
		For Each TagName In SetupParameters.FormItems Do
			MatchingSettingsToFormElements.Insert(TagName, IndexOf);
		EndDo;
		IndexOf = IndexOf + 1;
	EndDo;
	
	YouCanConfigureAccountingAccounts = LocalAccountingAccountsCanBeConfigured() Or SettingUpInternationalAccountingAccountsIsAvailable();

	AccountSettingsData_1 = GLAccountSettingsClientServer.NewAccountSettingsData();
	AccountSettingsData_1.ArrayOfSettings = New FixedArray(ArrayOfSettings);
	AccountSettingsData_1.MatchingSettingsToFormElements = MatchingSettingsToFormElements;
	AccountSettingsData_1.YouCanConfigureAccountingAccounts = YouCanConfigureAccountingAccounts;
	
	
	AccountSettingsData_1.InternationalAccountingIsUsed = GetFunctionalOption("UseFinancialAccounting");
	Return AccountSettingsData_1;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	Form - ClientApplicationForm - Contains:
// 		* Object - FormDataStructure - 
// 	ArrayOfSettings - Array - LongDesc
Procedure CheckAccountSettings(Form, ArrayOfSettings)
	
	If Not Common.DebugMode() Then
		Return;
	EndIf;
	
	Errors = Undefined;
	
	For Each SettingParameter In ArrayOfSettings Do
		
		If SettingParameter.DataPath = "" Then
			Return;
		EndIf;
	
		ArrayOfVerifiedDetails = New Array();
		ArrayOfVerifiedDetails.Add(SettingParameter["GLAccountSettings"]);
		If ValueIsFilled(SettingParameter["Presentation"]) Then
			ArrayOfVerifiedDetails.Add(SettingParameter["Presentation"]);
		EndIf;
		If ValueIsFilled(SettingParameter["AssetAndLiabilityItem"]) Then
			ArrayOfVerifiedDetails.Add(SettingParameter["AssetAndLiabilityItem"]);
		EndIf;
		If ValueIsFilled(SettingParameter["AssetsLiabilitiesDimension"]) Then
			ArrayOfVerifiedDetails.Add(SettingParameter["AssetsLiabilitiesDimension"]);
		EndIf;
		If ValueIsFilled(SettingParameter["ArticleType"]) Then
			ArrayOfVerifiedDetails.Add(SettingParameter["ArticleType"]);
		EndIf;
	
		If Find(SettingParameter.DataPath, "Object.") > 0 Then
			TSName = StrReplace(SettingParameter.DataPath, "Object.", "");
			SearchByTS = True;
			FormTable = Form.Object[TSName]; // FormDataCollection
			ListOfTSColumns = FormTable.Unload().Columns;
		ElsIf SettingParameter.DataPath = "Object" Then
			SearchByTS = False;
		ElsIf SettingParameter.DataPath = "AdjustmentTable" Then
			TSName = SettingParameter.DataPath;
			SearchByTS = True;
			FormTable = Form[TSName]; // FormDataCollection
			ListOfTSColumns = FormTable.Unload().Columns;
		Else
			CommonClientServer.AddUserError(
						Errors,
						"",
						StrTemplate(NStr("vi = 'Đã chọn sai đường dẫn đến dữ liệu %1 trong tham số tùy chỉnh tài khoản kế toán.';
										|ru = 'Указан неверный путь к данным %1 в параметрах настройки счетов учета.';
										|en = 'Invalid path is specified for data %1 in ledger account settings.'; fa = 'Invalid path is specified for data %1 in ledger account settings.';
										|it = 'Il percorso indicato ai dati %1 nei parametri di impostazione della contabilità è errato.';
										|pl = 'Podano nieprawidłową ścieżkę do danych %1 w parametrach ustawienia kont ewidencji.';
										|tr = 'Defterikebir hesabı ayar parametrelerinde yanlış veri yolu %1 belirtildi.'"), 
									SettingParameter.DataPath),
						"");
						
		EndIf;
		
		If Not SearchByTS And ValueIsFilled(SettingParameter.ConditionsForAvailabilityOfAccountingAccountInLines) Then
			MessageText = StrTemplate(
				                NStr("vi = 'Tùy chỉnh nằm trong phần đầu chứng từ. Không thể sử dụng tham số ""%1"".';
									|ru = 'Настройка располагается в шапке документа. Использование параметра ""%1"" не допускается.';
									|en = 'The setting is located at the document header. The parameter ''%1'' cannot be used.'; fa = 'The setting is located at the document header. The parameter ''%1'' cannot be used.';
									|it = 'L''impostazione si trova nell''intestazione del documento. L''utilizzo del parametro ""%1"" non è consentito.';
									|pl = 'Ustawienie znajduje się w nagłówku dokumentu. Używanie parametru ""%1"" nie jest dopuszczalne.';
									|tr = 'Ayar, belgenin üst bilgisinde bulunur. ""%1"" parametresinin kullanımına izin verilmiyor.'",
				                "ConditionsForAvailabilityOfAccountingAccountInLines"));
			CommonClientServer.AddUserError(
					Errors,
					"",
					MessageText, 
					"");
		EndIf;

		For Each AttributeToCheck In ArrayOfVerifiedDetails Do
			If SearchByTS And Not ThereIsWHColumn(ListOfTSColumns, AttributeToCheck) Then
				CommonClientServer.AddUserError(
						Errors,
						"",
						StrTemplate(NStr("vi = 'Thiếu mục tin %1 trong %2 của mẫu đối tượng.';
										|ru = 'Отсутствует реквизит %1 в %2 формы объекта.';
										|en = 'No attribute %1 in %2 of the item form.'; fa = 'No attribute %1 in %2 of the item form.';
										|it = 'Manca il requisito %1 in %2 del modulo dell''oggetto.';
										|pl = 'Brak rekwizytu %1 w %2 formularzu obiektu.';
										|tr = '%2 nesne formunda %1 özniteliği eksik.'"), 
									AttributeToCheck, 
									?(SearchByTS, StrTemplate(NStr("vi = 'phần bảng %1';
																	|ru = 'табличной части %1';
																	|en = 'table %1'; fa = 'table %1';
																	|it = 'parte tabellare %1';
																	|pl = 'części tabelarycznej %1';
																	|tr = '%1 tablo bölümünde'"), TSName), NStr("vi = 'danh sách mục tin';
																									|ru = 'списке реквизитов';
																									|en = 'list of attributes'; fa = 'list of attributes';
																									|it = 'elenco dei requisiti';
																									|pl = 'liście rekwizytów';
																									|tr = 'öznitelik listesinde'"))),
						"");
			EndIf;
			
			If Not SearchByTS 
				And Not (CommonClientServer.HasAttributeOrObjectProperty(Form.Object, AttributeToCheck)
						Or CommonClientServer.HasAttributeOrObjectProperty(Form, AttributeToCheck)) Then
				CommonClientServer.AddUserError(
						Errors,
						"",
						StrTemplate(NStr("vi = 'Thiếu mục tin %1 trong %2 của mẫu đối tượng.';
										|ru = 'Отсутствует реквизит %1 в %2 формы объекта.';
										|en = 'No attribute %1 in %2 of the item form.'; fa = 'No attribute %1 in %2 of the item form.';
										|it = 'Manca il requisito %1 in %2 del modulo dell''oggetto.';
										|pl = 'Brak rekwizytu %1 w %2 formularzu obiektu.';
										|tr = '%2 nesne formunda %1 özniteliği eksik.'"), 
									AttributeToCheck, 
									?(SearchByTS, StrTemplate(NStr("vi = 'phần bảng %1';
																	|ru = 'табличной части %1';
																	|en = 'table %1'; fa = 'table %1';
																	|it = 'parte tabellare %1';
																	|pl = 'części tabelarycznej %1';
																	|tr = '%1 tablo bölümünde'"), TSName), NStr("vi = 'danh sách mục tin';
																									|ru = 'списке реквизитов';
																									|en = 'list of attributes'; fa = 'list of attributes';
																									|it = 'elenco dei requisiti';
																									|pl = 'liście rekwizytów';
																									|tr = 'öznitelik listesinde'"))),
						"");
			EndIf;
		EndDo;
		
		ArrayOfVerifiedDetails.Clear();
		
		If ValueIsFilled(SettingParameter["Organization"]) Then
			ArrayOfVerifiedDetails.Add(SettingParameter["Organization"]);
		EndIf;
		
		For Each AttributeToCheck In ArrayOfVerifiedDetails Do
				AttributeName = NameOfPropsOnDataPath(AttributeToCheck);
				TSPropsName = NameTSOnDataPath(AttributeToCheck); 
				ThereArePropsInObject = CommonClientServer.HasAttributeOrObjectProperty(Form.Object, AttributeName);
				
				If TSName = Undefined And Not ThereArePropsInObject Then
					CommonClientServer.AddUserError(
							Errors,
							"",
							StrTemplate(NStr("vi = 'Không có mục tin %1 trong đối tượng của biểu mẫu.';
											|ru = 'Отсутствует реквизит %1 в объекте формы.';
											|en = 'Attribute %1 is missing in the form object.'; fa = 'Attribute %1 is missing in the form object.';
											|it = 'L''attributo %1 nell''oggetto del form è assente.';
											|pl = 'Nie ma atrybutu %1 w obiekcie formularza.';
											|tr = 'Form nesnesinde %1 özniteliği eksik.'"), AttributeName),
							"");
							
				ElsIf (ValueIsFilled(TSPropsName) And SearchByTS And Not TSPropsName = TSName) Then
					 CommonClientServer.AddUserError(
							Errors,
							"",
							StrTemplate(NStr("vi = 'Đường dẫn đến mục tin %1 tham chiếu đến phần bảng không đúng %2, dự kiến %3.';
											|ru = 'Путь к реквизиту %1 ссылается на неправильную табличную часть %2, ожидается %3.';
											|en = 'Path to attribute %1 refers to an invalid table %2, expected %3.'; fa = 'Path to attribute %1 refers to an invalid table %2, expected %3.';
											|it = 'Percorso all''attributo %1 rimanda ad una parte tabellare %2 errata, previsto %3.';
											|pl = 'Ścieżka do atrybutu %1 odwołuje się do nieprawidłowej sekcji tabelarycznej %2, oczekuje się %3.';
											|tr = '%1 özniteliğinin yolu, yanlış bir tablo bölümü olan %2''ye atıfta bulunuyor, %3 bekleniyor.'"), 
										AttributeName,
										TSPropsName,
										TSName),
							"");
							
				ElsIf (ValueIsFilled(TSPropsName) 
							And SearchByTS 
							And TSPropsName = TSName
							And Not ThereIsWHColumn(ListOfTSColumns, AttributeName)) Then 
						CommonClientServer.AddUserError(
							Errors,
							"",
							StrTemplate(NStr("vi = 'Không có mục tin %1 trong phần bảng %2.';
											|ru = 'Реквизит %1 отсутствует в табличной части %2.';
											|en = 'Attribute %1 is missing in the table %2.'; fa = 'Attribute %1 is missing in the table %2.';
											|it = 'L''attributo %1 è assente nella parte tabellare %2.';
											|pl = 'Atrybut %1 nie istnieje w sekcji tabelarycznej %2.';
											|tr = '%1 özniteliği %2 tablo bölümünde eksik.'"), 
										AttributeName,
										TSName),
							"");
					
				EndIf;
		EndDo;
		
		For Each TagName In SettingParameter.FormItems Do
			If Not CommonClientServer.HasAttributeOrObjectProperty(Form.Items, TagName) Then
				CommonClientServer.AddUserError(
						Errors,
						"",
						StrTemplate(NStr("vi = 'Thiếu phần tử biểu mẫu %1.';
										|ru = 'Отсутствует элемент формы %1.';
										|en = 'The %1 form item is missing.'; fa = 'The %1 form item is missing.';
										|it = 'Manca l''elemento del modulo %1.';
										|pl = 'Brak elementu formularza %1.';
										|tr = '%1 form öğesi eksik.'"), 
									TagName),
						"");
				
			Else
				FormControl_ = Form.Items[TagName];
				PropsInHeader = TMCommonUseClientServer.ElementShapeTable(FormControl_) = Undefined;
				NameOfPropertyToCheck = ?(PropsInHeader, "Hyperlink", "CellHyperlink");
				
				If Not FormControl_[NameOfPropertyToCheck] Then
					CommonClientServer.AddUserError(
						Errors,
						"",
						StrTemplate(
						NStr("vi = 'Chưa điền giá trị thuộc tính %1 đối với phần tử biểu mẫu %2.';
							|ru = 'Не заполнено значение свойства %1 для элемента формы %2.';
							|en = 'The value of property %1 for form element %2 cannot be blank.'; fa = 'The value of property %1 for form element %2 cannot be blank.';
							|it = 'Il valore della proprietà %1 per l''elemento del form %2 non è compilato.';
							|pl = 'Nie wypełniono wartości właściwości %1 dla elementu formularza %2.';
							|tr = '%1 özellik değeri, %2 form öğesi için doldurulmadı.'"),
							NameOfPropertyToCheck,
							TagName),
						"");
					
				EndIf;
				
				If FormControl_.DataPath <> SettingParameter.Presentation
					And Not StrFind(FormControl_.DataPath, "." + SettingParameter.Presentation) Then 
					CommonClientServer.AddUserError(
						Errors,
						"",
						StrTemplate(
						NStr("vi = 'Phần tử biểu mẫu %1 cần liên kết với mục tin hệ thống %2.';
							|ru = 'Элемент формы %1 должен быть привязан к служебному реквизиту %2.';
							|en = 'Form element %1 must be associated with internal attribute %2.'; fa = 'Form element %1 must be associated with internal attribute %2.';
							|it = 'L''elemento del form %1 deve essere collegato all''attributo di servizio %2.';
							|pl = 'Element formularza %1 powinien być przywiązany do atrybutu serwisowego %2.';
							|tr = '%1 form öğesi, %2 özel özniteliğine bağlı olmalıdır.'"),
							TagName,
							SettingParameter.Presentation),
						"");
					
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors);
	
	If Not Errors = Undefined Then
		ExceptionText = NStr("vi = 'Đã tìm thấy lỗi khi kiểm tra tham số tùy chỉnh tài khoản kế toán';
							|ru = 'Найдены ошибки при проверке параметров настройки счетов учета';
							|en = 'Errors found while validating ledger account settings'; fa = 'Errors found while validating ledger account settings';
							|it = 'Sono stati rilevati errori durante la verifica dei parametri di impostazione della contabilità';
							|pl = 'Wykryto błędy podczas sprawdzenia parametrów ustawienia kont ewidencji';
							|tr = 'Hesaplama parametresi ayarları kontrol edilirken hatalar bulundu'");
		Raise ExceptionText;
	EndIf;

EndProcedure

Procedure FillInExtdimensionFromSources(CurrentObject, AccountSettingsData_1)

	ObjectMetadata1 = CurrentObject.Metadata();
	
	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
			
		If SetupParameters.ExtDimensionSelectionSources.Count() = 0 Then
			Continue;
		EndIf;
		
		Data = GLAccountSettingsClientServer.DataAlongWay(CurrentObject, SetupParameters.DataPath);
		If ObjectMetadata1.TabularSections.Contains(ObjectMetadata1.Parent().FindByType(TypeOf(Data))) Then
			For Each TableRow In Data Do
				FillExtdimensionFromSource(TableRow, CurrentObject, SetupParameters, AccountSettingsData_1.AccountingAccountSettings);
			EndDo;
		Else
			FillExtdimensionFromSource(Data, CurrentObject, SetupParameters, AccountSettingsData_1.AccountingAccountSettings);
		EndIf;
	EndDo;
EndProcedure

Procedure FillExtdimensionFromSource(SettingContext, CurrentObject, SetupParameters, AccountingAccountSettings)
	
	If Not ValueIsFilled(SettingContext[SetupParameters.GLAccountSettings]) Then
		Return;
	EndIf;
	
	ConfigurationData = AccountingAccountSettings[SettingContext[SetupParameters.GLAccountSettings]];
	If ConfigurationData = Undefined Then
		Return;
	EndIf;
	
	
	For Each InternationalConfigurationData In ConfigurationData.FinancialAccountingSettings Do
		If ValueIsFilled(InternationalConfigurationData.GLAccount) Then
			FillExtdimensionInSettingsData(InternationalConfigurationData, SetupParameters, SettingContext, CurrentObject);
		EndIf;
	EndDo;
EndProcedure

Procedure FillExtdimensionInSettingsData(ConfigurationData, SetupParameters, SettingContext, CurrentObject)
	
	AccountProperties = GLAccountSettingsInternalServerCall.GetAccountProperties(ConfigurationData.GLAccount);
	
	For ExtDimensionNumber = 1 To AccountProperties.ExtDimensionCount Do
		DescriptionOfExtdimensionTypes = AccountProperties["ExtDimensionType" + ExtDimensionNumber + "ValueType"];
		For Each Source In SetupParameters.ExtDimensionSelectionSources Do
			If Not ValueIsFilled(Source.Value) 
				Or Not ValueIsFilled(Source.Presentation) Then
				Continue;
			EndIf; 
			If Not DescriptionOfExtdimensionTypes.ContainsType(Source.Value) Then
				Continue;
			EndIf;
			
			DataPathParts = StrSplit(Source.Presentation, ".");
			
			IndexOfPropsName = DataPathParts.Count() - 1;
			InTable = (DataPathParts.Count() = 3);
			If InTable Then
				Value = SettingContext[DataPathParts[IndexOfPropsName]];
			Else
				Value = CurrentObject[DataPathParts[IndexOfPropsName]];
			EndIf;
			If ValueIsFilled(Value) Then
				ConfigurationData["ExtDimension" + ExtDimensionNumber] = Value;
				Break;
			EndIf;
		EndDo;
	EndDo;

EndProcedure

Procedure ClearOutdatedReflectionSettingsInObject(Form, Object, ArrayOfSettings)
	
	For Each SetupParameters In ArrayOfSettings Do
		
		ThisIsFormTable = False;
		
		If Not StrStartsWith(SetupParameters.DataPath, "Object")
			And SetupParameters.FormItems.Count() = 1 Then
			FormItem = Form.Items[SetupParameters.FormItems[0]];
			FormTable = TMCommonUseClientServer.ElementShapeTable(FormItem);
			ThisIsFormTable = FormTable <> Undefined;
		EndIf;
		
		If ThisIsFormTable Then
			Continue; // must be processed before writing the form on the client. See GLAccountSettingsClient.BeforeWriteAtClient
		EndIf;
		
		Data = GLAccountSettingsClientServer.DataAlongWay(Object, SetupParameters.DataPath); // FormDataCollection - 

		// Only in the form data there is a type of article, so we get them
		FormData1 = GLAccountSettingsClientServer.DataAlongWay(Form, SetupParameters.DataPath);
		
		If TypeOf(FormData1) = Type("FormDataCollection") Then
			For Each TableRow In Data Do
				FormDataString = FormData1[Data.IndexOf(TableRow)];
				ArticleType = ?(ValueIsFilled(SetupParameters.ArticleType), FormDataString[SetupParameters.ArticleType], Undefined);
				ClearReflectionSettings(TableRow, SetupParameters, ArticleType);
			EndDo;
		Else
			ArticleType = ?(ValueIsFilled(SetupParameters.ArticleType), Form[SetupParameters.ArticleType], Undefined);
			ClearReflectionSettings(Data, SetupParameters, ArticleType);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ClearReflectionSettings(Data, SetupParameters, ArticleType)
	
	If Not SetupParameters.AvailabilityByOperation Or (ArticleType <> Undefined And ArticleType <> 3) Then
		Data[SetupParameters.GLAccountSettings] = Undefined;
	EndIf;
	
EndProcedure

Function ThereIsWHColumn(ListOfTSColumns, ColumnName)
	
	Return Not ListOfTSColumns.Find(ColumnName) = Undefined;
	
EndFunction

Function NameTSOnDataPath(DataPath)
	
	//We select the PM name from the data path
	SubstringsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataPath, ".");
	If SubstringsArray.Count() = 3 Then
		Return SubstringsArray[1] ;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function NameOfPropsOnDataPath(DataPath)
	
	SubstringsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataPath, ".");
	Return SubstringsArray[SubstringsArray.Count() - 1] ;
	
EndFunction

Procedure SaveAccountSettingsDataInMechanismData(Form, AccountSettingsData_1, Copy = False)
	
	AccountingAccountSettings = New Array();
	SettingCompliance = New Map();
	
	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		SettingContext = GLAccountSettingsClientServer.DataAlongWay(Form, SetupParameters.DataPath);
		If TypeOf(SettingContext) = Type("FormDataCollection") Then
			For Each TableRow In SettingContext Do
				If ValueIsFilled(TableRow[SetupParameters.GLAccountSettings]) Then
					AccountingAccountSettings.Add(TableRow[SetupParameters.GLAccountSettings]);
					If Copy Then
						NewSetting = GLAccountSettingsInternalServerCall.LinkToNewInvoiceSettingsElement();
						SettingCompliance.Insert(TableRow[SetupParameters.GLAccountSettings], NewSetting);
						TableRow[SetupParameters.GLAccountSettings] = NewSetting;
					EndIf;
				EndIf;
			EndDo;
		ElsIf ValueIsFilled(SettingContext[SetupParameters.GLAccountSettings]) Then
			AccountingAccountSettings.Add(SettingContext[SetupParameters.GLAccountSettings]);
			If Copy Then
				NewSetting = GLAccountSettingsInternalServerCall.LinkToNewInvoiceSettingsElement();
				SettingCompliance.Insert(SettingContext[SetupParameters.GLAccountSettings], NewSetting);
				SettingContext[SetupParameters.GLAccountSettings] = NewSetting;
			EndIf;
		EndIf;
	EndDo;
	
	SettingsData = AccountSettingsData_(AccountingAccountSettings);
	
	For Each ConfigureAccounts In AccountingAccountSettings Do
		If Copy Then
			AccountSettingsData_1.AccountingAccountSettings.Insert(SettingCompliance[ConfigureAccounts], SettingsData[ConfigureAccounts]);
		Else
			AccountSettingsData_1.AccountingAccountSettings.Insert(ConfigureAccounts, SettingsData[ConfigureAccounts]);
		EndIf;
	EndDo;
	
EndProcedure

Function NewAccountSettingsElement(ConfigurationData, DeletionMark, Owner, RefToNew = Undefined) Export
	
	SettingUpInvoicesObject = Catalogs.OtherTransactionsGLAccountsSettings.CreateItem();
	
	If ValueIsFilled(RefToNew) Then
		SettingUpInvoicesObject.SetNewObjectRef(RefToNew);
	EndIf;
		
	
	If TypeOf(ConfigurationData) = Type("QueryResultSelection") Then
		ResultOfSettingUpInternationalAccounting = ConfigurationData.FinancialAccountingSettings; // QueryResultSelection -
		SelectionOfInternationalAccountingSettings = ResultOfSettingUpInternationalAccounting.Select();
		While SelectionOfInternationalAccountingSettings.Next() Do
			FillPropertyValues(SettingUpInvoicesObject.FinancialAccountingSettings.Add(), SelectionOfInternationalAccountingSettings);
		EndDo;
	Else
		For Each SettingUpInternationalAccounting In ConfigurationData.FinancialAccountingSettings Do
			FillPropertyValues(SettingUpInvoicesObject.FinancialAccountingSettings.Add(), SettingUpInternationalAccounting);
		EndDo;
	EndIf;
	SettingUpInvoicesObject.SettingsOwner = Owner;
	SettingUpInvoicesObject.DeletionMark = DeletionMark;
	SettingUpInvoicesObject.Write();
	
	Return SettingUpInvoicesObject.Ref;
	
EndFunction

Function AccountSettingsChanged_(ConfigurationData, DeletionMark, SavedSettingsData)
	
	SettingChanged = DeletionMark <> SavedSettingsData.DeletionMark;
	
	
	If Not SettingChanged Then
		ResultSavedInternationalAccountingSettings = SavedSettingsData.FinancialAccountingSettings; // QueryResultSelection -
		SavedInternationalAccountingSettings = ResultSavedInternationalAccountingSettings.Select();
		
		If TypeOf(ConfigurationData) = Type("QueryResultSelection") Then
			ResultOfSettingUpInternationalAccounting = ConfigurationData.FinancialAccountingSettings; // QueryResultSelection -
			SelectionOfInternationalAccountingSettings = ResultOfSettingUpInternationalAccounting.Select();
			If SavedInternationalAccountingSettings.Count() = SelectionOfInternationalAccountingSettings.Count() Then
				While SelectionOfInternationalAccountingSettings.Next() Do
					SavedInternationalAccountingSettings.Reset();
					If SavedInternationalAccountingSettings.FindNext(SelectionOfInternationalAccountingSettings.ChartOfAccounts, "ChartOfAccounts") Then
						SettingChanged = AccountSettingsChanged(SelectionOfInternationalAccountingSettings, SavedInternationalAccountingSettings);
					Else
						SettingChanged = True;
					EndIf;
					If SettingChanged Then
						Break;
					EndIf;
				EndDo;
			Else
				SettingChanged = True;
			EndIf;
		ElsIf SavedInternationalAccountingSettings.Count() = ConfigurationData.FinancialAccountingSettings.Count() Then
			For Each SettingUpInternationalAccounting In ConfigurationData.FinancialAccountingSettings Do
				SavedInternationalAccountingSettings.Reset();
				If SavedInternationalAccountingSettings.FindNext(SettingUpInternationalAccounting.ChartOfAccounts, "ChartOfAccounts") Then
					SettingChanged = AccountSettingsChanged(SettingUpInternationalAccounting, SavedInternationalAccountingSettings);
				Else
					SettingChanged = True;
				EndIf;
				If SettingChanged Then
					Break;
				EndIf;
			EndDo;
		Else
			SettingChanged = True;
		EndIf;
	EndIf;
	Return SettingChanged;
	
EndFunction

Function AccountSettingsChanged(ConfigurationData, SavedSettingsData)
	
	SettingChanged = False;
	
	SettingsDetails_1 = New Structure(GLAccountSettingsClientServer.AccountSettingsDetails());
	For Each SettingsDetails In SettingsDetails_1 Do
		SettingChanged = SettingChanged Or ConfigurationData[SettingsDetails.Key] <> SavedSettingsData[SettingsDetails.Key];
		If SettingChanged Then
			Break;
		EndIf;
	EndDo;
		
	Return SettingChanged;
	
EndFunction

Procedure ChangeAccountingAccountSettingsElement(SettingsLink, ConfigurationData, DeletionMark, Owner = Undefined)
	
	NoExternalTransaction = Not TransactionActive();
	
	If NoExternalTransaction Then
		BeginTransaction();
	EndIf;
	
	Try
		
		Block = New DataLock();
		LockItem = Block.Add("Catalog.OtherTransactionsGLAccountsSettings");
		LockItem.SetValue("Ref", SettingsLink);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		SettingUpInvoicesObject = SettingsLink.GetObject();
		
		
		SettingUpInvoicesObject.FinancialAccountingSettings.Clear();
		If TypeOf(ConfigurationData) = Type("QueryResultSelection") Then
			ResultOfSettingUpInternationalAccounting = ConfigurationData.FinancialAccountingSettings; // QueryResultSelection -
			SelectionOfInternationalAccountingSettings = ResultOfSettingUpInternationalAccounting.Select();
			While SelectionOfInternationalAccountingSettings.Next() Do
				FillPropertyValues(SettingUpInvoicesObject.FinancialAccountingSettings.Add(), SelectionOfInternationalAccountingSettings);
			EndDo;
		Else
			For Each SettingUpInternationalAccounting In ConfigurationData.FinancialAccountingSettings Do
				FillPropertyValues(SettingUpInvoicesObject.FinancialAccountingSettings.Add(), SettingUpInternationalAccounting);
			EndDo;
		EndIf;
		If Owner <> Undefined And Not ValueIsFilled(SettingUpInvoicesObject.SettingsOwner) Then
			SettingUpInvoicesObject.SettingsOwner = Owner;
		EndIf;
		
		SettingUpInvoicesObject.DeletionMark = DeletionMark;
		SettingUpInvoicesObject.Write();
		
		If NoExternalTransaction Then
			CommitTransaction();
		EndIf;
		
	Except
		
		If NoExternalTransaction Then
			RollbackTransaction();
		EndIf;
			
		Raise;
		
	EndTry;
	
EndProcedure

Procedure SetValueOfItemSProps(Object, DataPath, Value)
	
	If TypeOf(DataPath) = Type("Array") Then
		Object[DataPath[0]][DataPath[1]][DataPath[2]] = Value;
	Else
		Object[DataPath] = Value;
	EndIf;
	
EndProcedure

Procedure UpdateVersionOfAccountingAccountsSettings(Object, DataPath)
	
	UUID = New UUID();
	SetValueOfItemSProps(Object, DataPath, UUID);
	
EndProcedure

Function ThisIsArbitraryForm(Form, AccountSettingsData_1)
	
	For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
		If Not IsBlankString(SetupParameters.DataPath) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function ThisIsFormOfProcessing(Form)
	
	Return StrStartsWith(Form.FormName, "DataProcessor.");
	
EndFunction

#EndRegion

Function AccountSettingsDataIsBatchByDefault(CachedValues, DataPath, Val AccountSettingsData_1 = Undefined)
	
	ReturnValue = New Map();
	
	QueryName1 = "SettingUpAccountingAccountsByDefault" + StrReplace(DataPath, ".", "");
	
	DataForProcessing = BatchProcessingOfTablePartServer.DataForStringProcessing(QueryName1, CachedValues);
	
	If Not DataForProcessing = Undefined Then
	
		For Each SelectingSettings In DataForProcessing Do
			ConfigurationData = GLAccountSettingsClientServer.CompositionOfAccountingAccountSettings();
			SettingFilledIn = False;
			If Not SelectingSettings.LedgerAccountsInEntrySettings Then
				For Each SelectionOfInternationalAccountingSettings In SelectingSettings.FinancialAccountingSettings Do
					If ValueIsFilled(SelectionOfInternationalAccountingSettings.GLAccount) Then
						InternationalConfigurationData = GLAccountSettingsClientServer.CompositionOfInternationalAccountingAccounts();
						FillPropertyValues(InternationalConfigurationData, SelectionOfInternationalAccountingSettings);
						ConfigurationData.FinancialAccountingSettings.Add(InternationalConfigurationData);
						SettingFilledIn = True;
					EndIf;
				EndDo;
			EndIf;
			If SettingFilledIn Then
				ReturnValue.Insert(SelectingSettings.Ref,
					New Structure("ConfigurationData,GLAccountSettings",
						ConfigurationData,
						GLAccountSettingsInternalServerCall.LinkToNewInvoiceSettingsElement()));
			EndIf;
		EndDo;
		
	EndIf;
	
	Return ReturnValue;
	
EndFunction


#EndRegion


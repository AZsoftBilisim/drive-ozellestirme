
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ProcessPassedParameters();
	
	If Not LocalAccountingAccountsCanBeConfigured()
		And Not SettingUpInternationalAccountingAccountsIsAvailable() Then
		Cancel = True;
	Else
		ManagingFormDetailsAndElementsWhenCreatingForm();
		DisplaySettingsDataOnForm(Parameters.ConfigurationData);
		
		// Selection of articles and analytics.
		ItemsAndDimensionsSelectionParameters = ItemsAndDimensionsSelectionParameters();
		IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	EndIf;
		
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	If StrStartsWith(CurrentPage.Name, "PageInternational") Then
		ChartOfAccountsNumber = StrReplace(CurrentPage.Name, "PageInternational", "");
		ChangeParametersForSelectingAccountingInvoiceField(ThisObject, ChartOfAccountsNumber);
	EndIf;
	Return; // In KA, the handler is empty
	
EndProcedure

&AtClient
Procedure AssetAndLiabilityItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AssetAndLiabilityItemOnChange(Item)
	
	AssetAndLiabilityItemOnChangeAtServer();
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtServer
Procedure AssetAndLiabilityItemOnChangeAtServer()
	
	If ValueIsFilled(AssetAndLiabilityItem) Then
		LedgerAccountsInEntrySettings = Common.ObjectAttributeValue(AssetAndLiabilityItem, "LedgerAccountsInEntrySettings");
	Else
		LedgerAccountsInEntrySettings = False;
	EndIf;
	
	InternationalSetupIsAvailable = SettingUpInternationalAccountingAccountsIsAvailable();
	
	If InternationalSetupIsAvailable And InternationalAccountPlans.Count() = 0 Then
		AddDetailsElementsOfInternationalAccounting();
	ElsIf Not InternationalSetupIsAvailable And InternationalAccountPlans.Count() > 0 Then
		DeleteAttributesOfInternationalAccountingElements();
	EndIf;
	
EndProcedure


&AtClient
Procedure Attachable_LedgerAccountInternationalAccountingInCaseOfChange(Item)
	ChartOfAccountsNumber = StrReplace(Item.Name, "GLAccount", "");
	
	AccountForChangesInTime(ChartOfAccountsNumber);
EndProcedure

&AtClient
Procedure Attachable_LedgerAccountInternationalAccountingBeginningOfSelection(Item, ChoiceData, StandardProcessing)
	ChartOfAccountsNumber = StrReplace(Item.Name, "GLAccount", "");
EndProcedure

&AtClient
Procedure Attachable_ExtDimensionInternationalInCaseOfChange(Item)
	ChartOfAccountsNumber = StrReplace(Item.Name, "ExtDimension", "");
	ChartOfAccountsNumber = Left(ChartOfAccountsNumber, StrLen(ChartOfAccountsNumber) - 1);
	
	ChangeExtdimensionFieldSelectionParametersInt(ThisObject, ChartOfAccountsNumber);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DownloadInvoiceSettingsFromTheArticle(Command)
	
	LoadInvoiceSettingsFromArticleOnServer();
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	ConfigurationData = GLAccountSettingsClientServer.CompositionOfAccountingAccountSettings();
	
	
	ChartOfAccountsNumber = 1;
	
	For Each ChartOfAccounts In InternationalAccountPlans Do
		If ValueIsFilled(ThisObject["GLAccount" + ChartOfAccountsNumber]) Then
			InternationalConfigurationData = GLAccountSettingsClientServer.CompositionOfInternationalAccountingAccounts();
			InternationalConfigurationData.ChartOfAccounts = ChartOfAccounts;
			InternationalConfigurationData.GLAccount =  ThisObject["GLAccount" + ChartOfAccountsNumber];
			InternationalConfigurationData.ExtDimension1 =  ThisObject["ExtDimension" + ChartOfAccountsNumber + "1"];
			InternationalConfigurationData.ExtDimension2 =  ThisObject["ExtDimension" + ChartOfAccountsNumber + "2"];
			InternationalConfigurationData.ExtDimension3 =  ThisObject["ExtDimension" + ChartOfAccountsNumber + "3"];
			ConfigurationData.FinancialAccountingSettings.Add(InternationalConfigurationData);
		EndIf;
		ChartOfAccountsNumber = ChartOfAccountsNumber + 1;
	EndDo;
	
	For Each UnavailableSetting In UnavailableAccountSettings Do
		If ValueIsFilled(UnavailableSetting.GLAccount) Then
			InternationalConfigurationData = GLAccountSettingsClientServer.CompositionOfInternationalAccountingAccounts();
			FillPropertyValues(InternationalConfigurationData, UnavailableSetting);
			ConfigurationData.FinancialAccountingSettings.Add(InternationalConfigurationData);
		EndIf;
	EndDo;
	ReturnValue = New Structure();
	ReturnValue.Insert("ConfigurationData", ConfigurationData);
	ReturnValue.Insert("AssetAndLiabilityItem", AssetAndLiabilityItem);
	ReturnValue.Insert("AssetsLiabilitiesDimension", AssetsLiabilitiesDimension);
	
	If ValueIsFilled(GLAccountSettings) Then
		ReturnValue.Insert("GLAccountSettings", GLAccountSettings);
	Else
		ReturnValue.Insert("GLAccountSettings", GLAccountSettingsInternalServerCall.LinkToNewInvoiceSettingsElement());
	EndIf;
	
	Close(ReturnValue);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializeForm

&AtServer
Procedure ProcessPassedParameters()
	
	Period = Parameters.Period;
	GLAccountSettings = Parameters.GLAccountSettings;
	
	FillPropertyValues(ThisObject, Parameters.SettingContext);
	ExtDimensionSelectionSources.LoadValues(Parameters.ExtDimensionSelectionSources.UnloadValues());
	
	If TypeOf(Parameters.LedgerAccountsInEntrySettings) = Type("Boolean") Then
		LedgerAccountsInEntrySettings = Parameters.LedgerAccountsInEntrySettings;
	ElsIf ValueIsFilled(AssetAndLiabilityItem) Then
		LedgerAccountsInEntrySettings = Common.ObjectAttributeValue(AssetAndLiabilityItem, "LedgerAccountsInEntrySettings");
	Else
		LedgerAccountsInEntrySettings = False;
	EndIf;
	
EndProcedure

&AtServer
Function LocalAccountingAccountsCanBeConfigured()
	
	SettingIsAvailable = GLAccountSettingsServer.LocalAccountingAccountsCanBeConfigured();
	
	Return SettingIsAvailable;
	
EndFunction

&AtServer
Function SettingUpInternationalAccountingAccountsIsAvailable()
	
	SettingIsAvailable = GLAccountSettingsServer.SettingUpInternationalAccountingAccountsIsAvailable();
	If SettingIsAvailable Then
		SettingIsAvailable = Not LedgerAccountsInEntrySettings;
		If Not SettingIsAvailable And ValueIsFilled(AssetAndLiabilityItem) Then
			ConfigurationData = Undefined;
			If Parameters.Property("ConfigurationData", ConfigurationData) And TypeOf(ConfigurationData) = Type("Structure") Then
				For Each InternationalConfigurationData In ConfigurationData.FinancialAccountingSettings Do
					If ValueIsFilled(InternationalConfigurationData.GLAccount) Then
						SettingIsAvailable = True;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	Return SettingIsAvailable;
	
EndFunction

&AtServer
Procedure ManagingFormDetailsAndElementsWhenCreatingForm()
	
	ReadOnly = Parameters.ReadOnly;
	Items.OKButton.Visible = Not Parameters.ReadOnly;
	
	If Not ValueIsFilled(AssetAndLiabilityItem) Then
		Items.GroupArticleAssetLiabilityAnalysis.Visible = False;
	EndIf;
	
	If LocalAccountingAccountsCanBeConfigured() Then
		Items.ReglAccountingPage.Visible = True;
	Else
		Items.ReglAccountingPage.Visible = False;
	EndIf;
	
	If SettingUpInternationalAccountingAccountsIsAvailable() Then
		AddDetailsElementsOfInternationalAccounting();
	Else
		InternationalAccountPlans = New FixedArray(New Array());
		ManagingInvoiceDisplayElements();
	EndIf;
	If InternationalAccountPlans.Count() > 0 Then
		ChartOfAccountsNumber = 1;
		ChangeParametersForSelectingAccountingInvoiceField(ThisObject, ChartOfAccountsNumber);
	EndIf;
EndProcedure

&AtServer
Procedure ManagingInvoiceDisplayElements()
	
	NumberOfVisibleAccounts = 0;
	
	For Each InvoicePage In Items.GroupPages.ChildItems Do
		NumberOfVisibleAccounts = NumberOfVisibleAccounts + InvoicePage.Visible;
	EndDo;
	
	If NumberOfVisibleAccounts = 0 Then
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
		Items.DownloadArticleSettings.Visible = False;
		Title = NStr("vi = 'Không cần thiết lập tài khoản kế toán';
					|ru = 'Настройка счетов учета не требуется';
					|en = 'Ledger account setup is not required'; fa = 'Ledger account setup is not required';
					|it = 'Настройка счетов учета не требуется';
					|pl = 'Ledger account setup is not required';
					|tr = 'Defterikebir hesabı ayarı gerekmiyor'");
	ElsIf NumberOfVisibleAccounts = 1 Then
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
		Items.DownloadArticleSettings.Visible = True;
		Items.DownloadArticleSettings.Title = NStr("vi = 'Kết nhập tài khoản từ dạng';
													|ru = 'Загрузить счет из статьи';
													|en = 'Import an account from an item'; fa = 'Import an account from an item';
													|it = 'Загрузить счет из статьи';
													|pl = 'Import an account from an item';
													|tr = 'Kalemden hesap yükle'");
		If TypeOf(GLAccountSettings) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
			Title = NStr("vi = 'Thiết lập tài khoản kế toán trong các chứng từ mặc định';
						|ru = 'Настройка счета учета в документах по умолчанию';
						|en = 'Set up a ledger account in default documents'; fa = 'Set up a ledger account in default documents';
						|it = 'Настройка счета учета в документах по умолчанию';
						|pl = 'Set up a ledger account in default documents';
						|tr = 'Varsayılan belgelerde defterikebir hesabı ayarlama'");
		Else
			Title = NStr("vi = 'Thiết lập tài khoản kế toán giao dịch';
						|ru = 'Настройка счета учета операции';
						|en = 'Set up a transaction ledger account'; fa = 'Set up a transaction ledger account';
						|it = 'Настройка счета учета операции';
						|pl = 'Set up a transaction ledger account';
						|tr = 'İşlemin defterikebir hesabını ayarlama'");
		EndIf;
	Else
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		Items.DownloadArticleSettings.Visible = True;
		Items.DownloadArticleSettings.Title = NStr("vi = 'Kết nhập tài khoản từ dạng';
													|ru = 'Загрузить счета из статьи';
													|en = 'Import accounts from item'; fa = 'ورود حساب‌ها از قلم';
													|it = 'Importare conto da voce';
													|pl = 'Pobierz konta z pozycji';
													|tr = 'Kalemden hesapları yükle'");
		If TypeOf(GLAccountSettings) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
			Title = NStr("vi = 'Tùy chỉnh tài khoản kế toán trong các chứng từ mặc định';
						|ru = 'Настройка счетов учета в документах по умолчанию';
						|en = 'Set up ledger accounts in default documents'; fa = 'Set up ledger accounts in default documents';
						|it = 'Настройка счетов учета в документах по умолчанию';
						|pl = 'Set up ledger accounts in default documents';
						|tr = 'Varsayılan olarak belgelerde defterikebir hesabı ayarlama'");
		Else
			Title = NStr("vi = 'Tên tài khoản kế toán';
						|ru = 'Настройка счетов учета операции';
						|en = 'Transaction ledger accounts settings'; fa = 'تنظیمات حساب‌های دفتر کل تراکنش';
						|it = 'Impostazione dei conti contabili operazioni';
						|pl = 'Ustawienie kont ewidencji operacji';
						|tr = 'İşlemin defterikebir hesabını ayarlama'");
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AddDetailsElementsOfInternationalAccounting()
	
	ArrayOfAccountPlans = New Array();
	
	Query = New Query();
	Query.Text = "
	|SELECT ALLOWED
	|	ChartsOfAccounts.Ref AS Ref,
	|	REFPRESENTATION(ChartsOfAccounts.Ref) AS RefPresentation
	|FROM
	|	Catalog.FinancialAccountingChartsOfAccounts AS ChartsOfAccounts
	|WHERE
	|	NOT ChartsOfAccounts.DeletionMark";
	
	If ValueIsFilled(Organization) Then
		Query.Text = Query.Text + "
		|	AND ChartsOfAccounts.Ref IN (
		|		SELECT
		|			BusinessAccountPlans.ChartOfAccounts
		|		FROM
		|			InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(
		|				&Period,
		|				Organization = &Organization
		|			) AS BusinessAccountPlans
		|		WHERE
		|			BusinessAccountPlans.PostingGenerationSetting <> VALUE(Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef)
		|	)
		|";
		Query.SetParameter("Period", Period);
		Query.SetParameter("Organization", Organization);
	EndIf;
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	AttributesToBeAdded = New Array();
	
	For ChartOfAccountsNumber = 1 To Selection.Count() Do
		AttributesToBeAdded.Add(New FormAttribute("GLAccount" + ChartOfAccountsNumber,
			New TypeDescription("ChartOfAccountsRef.International")));
		
		For ExtDimensionNumber = 1 To 3 Do
			AttributesToBeAdded.Add(New FormAttribute("ExtDimension" + ChartOfAccountsNumber + ExtDimensionNumber,
				New TypeDescription("Undefined")));
			AttributesToBeAdded.Add(New FormAttribute("ExtdimensionHeader" + ChartOfAccountsNumber + ExtDimensionNumber,
				Common.StringTypeDetails(0)));
		EndDo;
	EndDo;
	
	If AttributesToBeAdded.Count() > 0 Then
		ChangeAttributes(AttributesToBeAdded);
		
		ChartOfAccountsNumber = 1;
		
		While Selection.Next() Do
			ArrayOfAccountPlans.Add(Selection.Ref);
			
			NewPage = Items.Add("PageInternational" + ChartOfAccountsNumber, Type("FormGroup"), Items.GroupPages);
			NewPage.Type = FormGroupType.Page;
			NewPage.Title = Selection.RefPresentation;
			NewPage.Group = ChildFormItemsGroup.AlwaysHorizontal;
			
			NewHeadlines = Items.Add("GroupHeaders" + ChartOfAccountsNumber, Type("FormGroup"), NewPage);
			NewHeadlines.Type = FormGroupType.UsualGroup;
			NewHeadlines.Representation = UsualGroupRepresentation.None;
			NewHeadlines.Group = ChildFormItemsGroup.Vertical;
			NewHeadlines.United = False;
			NewHeadlines.ShowTitle = False;
			
			NewScenery = Items.Add("DecorationOfTheAccountingAccount" + ChartOfAccountsNumber, Type("FormDecoration"), NewHeadlines);
			NewScenery.Type = FormDecorationType.Label;
			NewScenery.Title = NStr("vi = 'Tài khoản kế toán';
									|ru = 'Счет учета';
									|en = 'Ledger account'; fa = 'حساب دفتر کل';
									|it = 'Conto di bilancio';
									|pl = 'Rachunek ewidencji';
									|tr = 'Defterikebir hesabı'");
			NewScenery.HorizontalStretch = True;
			NewScenery.AutoMaxWidth = False;
			NewScenery.MaxWidth = 60;
			
			For ExtDimensionNumber = 1 To 3 Do
				NewTitle = Items.Add("ExtdimensionHeader" + ChartOfAccountsNumber + ExtDimensionNumber, Type("FormField"), NewHeadlines);
				NewTitle.Type = FormFieldType.LabelField;
				NewTitle.DataPath = "ExtdimensionHeader" + ChartOfAccountsNumber + ExtDimensionNumber;
				NewTitle.TitleLocation = FormItemTitleLocation.None;
				NewTitle.HorizontalStretch = True;
				NewTitle.AutoMaxWidth = False;
				NewTitle.MaxWidth = 60;
				NewTitle.Visible = False;
			EndDo;
			
			NewExtdimensionAccount = Items.Add("ExtDimensionAccountGroup" + ChartOfAccountsNumber, Type("FormGroup"), NewPage);
			NewExtdimensionAccount.Type = FormGroupType.UsualGroup;
			NewExtdimensionAccount.Representation = UsualGroupRepresentation.None;
			NewExtdimensionAccount.Group = ChildFormItemsGroup.Vertical;
			NewExtdimensionAccount.United = False;
			NewExtdimensionAccount.ShowTitle = False;
			
			NewAccountName_ = Items.Add("GroupAccountingAccountName" + ChartOfAccountsNumber, Type("FormGroup"), NewExtdimensionAccount);
			NewAccountName_.Type = FormGroupType.UsualGroup;
			NewAccountName_.Representation = UsualGroupRepresentation.None;
			NewAccountName_.Group = ChildFormItemsGroup.AlwaysHorizontal;
			NewAccountName_.United = True;
			NewAccountName_.ShowTitle = False;
			
			NewAccount_ = Items.Add("GLAccount" + ChartOfAccountsNumber, Type("FormField"), NewAccountName_);
			NewAccount_.Type = FormFieldType.InputField;
			NewAccount_.DataPath = "GLAccount" + ChartOfAccountsNumber;
			NewAccount_.SetAction("StartChoice", "Attachable_LedgerAccountInternationalAccountingBeginningOfSelection");
			NewAccount_.SetAction("OnChange", "Attachable_LedgerAccountInternationalAccountingInCaseOfChange");
			NewAccount_.TitleLocation = FormItemTitleLocation.None;
			NewAccount_.HorizontalStretch = False;
			NewAccount_.Width = 9;
			
			NewDescription = Items.Add("GLAccountDescription" + ChartOfAccountsNumber, Type("FormField"), NewAccountName_);
			NewDescription.Type = FormFieldType.LabelField;
			NewDescription.DataPath = "GLAccount" + ChartOfAccountsNumber + ".Description";
			NewDescription.TitleLocation = FormItemTitleLocation.None;
			
			For ExtDimensionNumber = 1 To 3 Do
				NewExtdimension = Items.Add("ExtDimension" + ChartOfAccountsNumber + ExtDimensionNumber, Type("FormField"), NewExtdimensionAccount);
				NewExtdimension.Type = FormFieldType.InputField;
				NewExtdimension.DataPath = "ExtDimension" + ChartOfAccountsNumber + ExtDimensionNumber;
				NewExtdimension.SetAction("OnChange", "Attachable_ExtDimensionInternationalInCaseOfChange");
				NewExtdimension.TitleLocation = FormItemTitleLocation.None;
				NewExtdimension.Visible = False;
			EndDo;
			
			ChartOfAccountsNumber = ChartOfAccountsNumber + 1;
		EndDo;
	EndIf;
	
	InternationalAccountPlans = New FixedArray(ArrayOfAccountPlans);
	
	ManagingInvoiceDisplayElements();
	
EndProcedure

&AtServer
Procedure DeleteAttributesOfInternationalAccountingElements()
	AttributesToBeDeleted = New Array();
	
	For ChartOfAccountsNumber = 1 To InternationalAccountPlans.Count() Do
		PageToDelete = Items["PageInternational" + ChartOfAccountsNumber];
		Items.Delete(PageToDelete);
		
		AttributesToBeDeleted.Add("GLAccount" + ChartOfAccountsNumber);
		For ExtDimensionNumber = 1 To 3 Do
			AttributesToBeDeleted.Add("ExtDimension" + ChartOfAccountsNumber + ExtDimensionNumber);
			AttributesToBeDeleted.Add("ExtdimensionHeader" + ChartOfAccountsNumber + ExtDimensionNumber);
		EndDo;
	EndDo;
	
	If AttributesToBeDeleted.Count() > 0 Then
		ChangeAttributes(, AttributesToBeDeleted);
	EndIf;
	InternationalAccountPlans = New FixedArray(New Array());
	UnavailableAccountSettings = New FixedArray(New Array());
	
	ManagingInvoiceDisplayElements();
	
EndProcedure

&AtServer
Procedure DisplaySettingsDataOnForm(ConfigurationData, LoadingFromArticle = False)
	
	
	UnavailableSettings = New Array();
	
	For Each SettingUpInternationalAccounting In ConfigurationData.FinancialAccountingSettings Do
		ChartOfAccountsIndex = InternationalAccountPlans.Find(SettingUpInternationalAccounting.ChartOfAccounts);
		
		If ChartOfAccountsIndex <> Undefined Then
			ChartOfAccountsNumber = ChartOfAccountsIndex + 1;
			ThisObject["GLAccount" + ChartOfAccountsNumber] = SettingUpInternationalAccounting.GLAccount;
			ThisObject["ExtDimension" + ChartOfAccountsNumber + "1"] = SettingUpInternationalAccounting.ExtDimension1;
			ThisObject["ExtDimension" + ChartOfAccountsNumber + "2"] = SettingUpInternationalAccounting.ExtDimension2;
			ThisObject["ExtDimension" + ChartOfAccountsNumber + "3"] = SettingUpInternationalAccounting.ExtDimension3;
			ManagingElementsOfInternationalAccountingForm(ChartOfAccountsNumber);
		ElsIf Not LoadingFromArticle Then
			UnavailableSetting = GLAccountSettingsClientServer.CompositionOfInternationalAccountingAccounts();
			FillPropertyValues(UnavailableSetting, SettingUpInternationalAccounting);
			UnavailableSettings.Add(UnavailableSetting);
		EndIf;
	EndDo;
	
	If Not LoadingFromArticle Then
		UnavailableAccountSettings = New FixedArray(UnavailableSettings);
	EndIf;
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure LoadInvoiceSettingsFromArticleOnServer()
	
	Query = New Query();
	Query.SetParameter("AssetAndLiabilityItem", AssetAndLiabilityItem);
	Query.Text = "
	|SELECT ALLOWED
	|	AssetLiabilityItems.Ref    AS Ref
	|	,
	|	AssetLiabilityItems.FinancialAccountingSettings AS FinancialAccountingSettings
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|WHERE
	|	AssetLiabilityItems.Ref = &AssetAndLiabilityItem
	|";
	
	Result = Query.Execute();
	SelectingSettings = Result.Select();
	ConfigurationData = GLAccountSettingsClientServer.CompositionOfAccountingAccountSettings();
	
	While SelectingSettings.Next() Do
		ResultOfSettingUpInternationalAccounting = SelectingSettings.FinancialAccountingSettings; // QueryResultSelection - 
		SelectionOfInternationalAccountingSettings = ResultOfSettingUpInternationalAccounting.Select();
		While SelectionOfInternationalAccountingSettings.Next() Do
			InternationalConfigurationData = GLAccountSettingsClientServer.CompositionOfInternationalAccountingAccounts();
			FillPropertyValues(InternationalConfigurationData, SelectionOfInternationalAccountingSettings);
			ConfigurationData.FinancialAccountingSettings.Add(InternationalConfigurationData);
		EndDo;
	EndDo;
	
	DisplaySettingsDataOnForm(ConfigurationData, True);
	
EndProcedure


&AtServer
Procedure ManagingElementsOfInternationalAccountingForm(ChartOfAccountsNumber)
	
	FormFields = New Structure(
		"ExtDimension1, ExtDimension2, ExtDimension3",
		"ExtDimension" + ChartOfAccountsNumber + "1",
		"ExtDimension" + ChartOfAccountsNumber + "2",
		"ExtDimension" + ChartOfAccountsNumber + "3");
	
	FieldHeaders = New Structure(
		"ExtDimension1, ExtDimension2, ExtDimension3",
		"ExtdimensionHeader" + ChartOfAccountsNumber + "1",
		"ExtdimensionHeader" + ChartOfAccountsNumber + "2",
		"ExtdimensionHeader" + ChartOfAccountsNumber + "3");
	
	AccountProperties = FinancialAccountingServerCached.AccountProperties(ThisObject["GLAccount" + ChartOfAccountsNumber]);
	
	For ExtDimensionNumber = 1 To 3 Do
		ExtdimensionValueType = AccountProperties["ExtDimensionType" + ExtDimensionNumber + "ValueType"];
		If ExtDimensionNumber <= AccountProperties.ExtDimensionCount Then
			ThisObject[FieldHeaders["ExtDimension" + ExtDimensionNumber]] = AccountProperties["ExtDimensionType" + ExtDimensionNumber + "Description"] + ":";
			Items[FieldHeaders["ExtDimension" + ExtDimensionNumber]].Visible  = True;
			Items[FormFields["ExtDimension" + ExtDimensionNumber]].Visible       = True;
			Items[FormFields["ExtDimension" + ExtDimensionNumber]].TypeRestriction = ExtdimensionValueType;
		Else 
			ThisObject[FieldHeaders["ExtDimension" + ExtDimensionNumber]] = "";
			Items[FieldHeaders["ExtDimension" + ExtDimensionNumber]].Visible  = False;
			Items[FormFields["ExtDimension" + ExtDimensionNumber]].Visible       = False;
			Items[FormFields["ExtDimension" + ExtDimensionNumber]].TypeRestriction = New TypeDescription("Undefined");
		EndIf;
	EndDo;
	
	If ExtDimensionSelectionSources.Count() > 0 Then
		For ExtDimensionNumber = 1 To AccountProperties.ExtDimensionCount Do
			Items[FormFields["ExtDimension" + ExtDimensionNumber]].InputHint = "";
			ExtdimensionValueType = AccountProperties["ExtDimensionType" + ExtDimensionNumber + "ValueType"];
			
			For Each Dimension In ExtDimensionSelectionSources Do
				If ExtdimensionValueType.ContainsType(Dimension.Value) Then
					Items[FormFields["ExtDimension" + ExtDimensionNumber]].InputHint = NStr("vi = '<được chọn tự động>';
																							|ru = '<подбирается автоматически>';
																							|en = '<picked automatically>'; fa = '<picked automatically>';
																							|it = '<viene selezionato automaticamente>';
																							|pl = '<wybierane automatycznie>';
																							|tr = '<otomatik olarak seçilir>'");
					Break;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure AccountForChangesInTime(ChartOfAccountsNumber)
	
	ObjectFields = New Structure(
		"ExtDimension1, ExtDimension2, ExtDimension3",
		"ExtDimension" + ChartOfAccountsNumber + "1",
		"ExtDimension" + ChartOfAccountsNumber + "2",
		"ExtDimension" + ChartOfAccountsNumber + "3");
		
	AccountProperties = FinancialAccountingServerCached.AccountProperties(ThisObject["GLAccount" + ChartOfAccountsNumber]);
	
	For ExtDimensionNumber = 1 To 3 Do
		If ExtDimensionNumber <= AccountProperties.ExtDimensionCount Then
			ExtdimensionValueType = AccountProperties["ExtDimensionType" + ExtDimensionNumber + "ValueType"];
			ExtraDimensionValue = ExtdimensionValueType.AdjustValue(ThisObject[ObjectFields["ExtDimension" + ExtDimensionNumber]]);
			ThisObject[ObjectFields["ExtDimension" + ExtDimensionNumber]] = ExtraDimensionValue;
		Else 
			ThisObject[ObjectFields["ExtDimension" + ExtDimensionNumber]] = Undefined;
		EndIf;
	EndDo;
	
	If ValueIsFilled(AssetsLiabilitiesDimension) Then
		For ExtDimensionNumber = 1 To AccountProperties.ExtDimensionCount Do
			ExtdimensionValueType = AccountProperties["ExtDimensionType" + ExtDimensionNumber + "ValueType"];
			If ExtdimensionValueType.ContainsType(TypeOf(AssetsLiabilitiesDimension)) Then
				ThisObject[ObjectFields["ExtDimension" + ExtDimensionNumber]] = AssetsLiabilitiesDimension;
			EndIf;
		EndDo;
	EndIf;
	
	ChangeExtdimensionFieldSelectionParametersInt(ThisObject, ChartOfAccountsNumber);
	ManagingElementsOfInternationalAccountingForm(ChartOfAccountsNumber);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ChangeExtdimensionFieldSelectionParametersInt(ThisForm, ChartOfAccountsNumber)
	
	WriteParameters = GLAccountSettingsClientServer.ExtdimensionSelectionOptions(
		ThisForm.Organization,
		ThisForm,
		"ExtDimension" + ChartOfAccountsNumber + "%IndexOf%",
		"GLAccount" + ChartOfAccountsNumber);
		
	GLAccountSettingsClientServer.ChangeExtdimensionFieldSelectionParameters(
		ThisForm,
		ThisForm,
		"ExtDimension" + ChartOfAccountsNumber + "%IndexOf%",
		"ExtDimension" + ChartOfAccountsNumber + "%IndexOf%",
		WriteParameters); 
	
EndProcedure

&AtClientAtServerNoContext
Procedure ChangeParametersForSelectingAccountingInvoiceField(ThisForm, ChartOfAccountsNumber)
	
	InternationalChartOfAccounts = ThisForm.InternationalAccountPlans[ChartOfAccountsNumber - 1];
	InvoiceElement_ = ThisForm.Items["GLAccount" + ChartOfAccountsNumber];
	
	ChoiceParameter = New ChoiceParameter("Filter.ChartOfAccounts", InternationalChartOfAccounts);
	ChoiceParameters = CommonClientServer.ValueInArray(ChoiceParameter);
	InvoiceElement_.ChoiceParameters = New FixedArray(ChoiceParameters);
	
EndProcedure

&AtServer
Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "ThisObject";
	ChoiceParameters.AssetRef = "AssetAndLiabilityItem";
	ChoiceParameters.ArticleType = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem = False;
	ChoiceParameters.DimensionOfExpenses = "";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("AssetAndLiabilityItem");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	
	Return ChoiceParameters;
	
EndFunction


#EndRegion

#EndRegion

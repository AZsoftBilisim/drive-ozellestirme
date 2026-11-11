#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ChartOfAccounts = Parameters.ChartOfAccounts;
	AccountingObject = Parameters.AccountingObject;
	PostingGenerationSetting = Parameters.PostingGenerationSetting;
	DataSource = Parameters.DataSource;
	
	AccumulationRegister = Metadata.AccumulationRegisters.Find(DataSource);
	If AccumulationRegister <> Undefined Then
		DataSourcePresentation = AccumulationRegister.Synonym;
	Else
		Items.GroupAvailableRegisterFields.Visible = False;
	EndIf;
	
	ChartsOfCharacteristicTypes.AssetLiabilityItems.InitializeSettingsComposerWithDataSource(
		SettingsComposer,
		DataSource,,
		UUID);
	
	FilterOfSettings = 
		DataProcessors.SettingUpFinancialAccountingAccounts.SelectingExtdimensionFillingSettings(
			ChartOfAccounts, 
			PostingGenerationSetting,
			AccountingObject);
				
	StateOfExtdimensionFillingSetting.Load(
		DataProcessors.SettingUpFinancialAccountingAccounts.ExtraDimensionFillingSettings(
			FilterOfSettings,
			SettingsComposer));
			
	For Each ConfigurationStateBar In StateOfExtdimensionFillingSetting Do
		FillInPresentationInStateBarOfSetting(ConfigurationStateBar);
	EndDo;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure AccountsAccountingSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StateOfExtdimensionFillingSettingGLAccount Then
		CurrentData = StateOfExtdimensionFillingSetting.FindByID(RowSelected);
		ShowValue(, CurrentData.GLAccount);
	
	ElsIf Field = Items.StateOfExtdimensionFillingSettingPresentation Then
		
		SameData = StateOfExtdimensionFillingSetting.FindByID(Items.StateOfExtdimensionFillingSetting.CurrentRow);
		
		FormOpenParameters = New Structure();
		FormOpenParameters.Insert("ChartOfAccounts", ChartOfAccounts);
		FormOpenParameters.Insert("PostingGenerationSetting", PostingGenerationSetting);
		FormOpenParameters.Insert("AccountingObject", AccountingObject);
		FormOpenParameters.Insert("GLAccount",  SameData.GLAccount);
		FormOpenParameters.Insert("DataSource",  DataSource);
		
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RowID", Items.StateOfExtdimensionFillingSetting.CurrentRow);
		NotificationProcessing = New CallbackDescription("AtEndOfExtdimensionFillingConfiguration", ThisObject, AdditionalParameters);
		
		OpenForm("DataProcessor.SettingUpFinancialAccountingAccounts.Form.FormOfFillingInExtraDimensionOfLedgerAccount", 
			FormOpenParameters,
			ThisObject,
			,,,
			NotificationProcessing);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AtEndOfExtdimensionFillingConfiguration(Result, AdditionalParameters) Export
	
	UpdateStateOfExtdimensionFillSettingInLine(AdditionalParameters.RowID);
	
EndProcedure

&AtServer
Procedure UpdateStateOfExtdimensionFillSettingInLine(RowID = Undefined)
	
	StateLineData  = StateOfExtdimensionFillingSetting.FindByID(RowID);
	
	FilterOfSettings = 
		DataProcessors.SettingUpFinancialAccountingAccounts.SelectingExtdimensionFillingSettings(
			ChartOfAccounts, 
			PostingGenerationSetting,
			AccountingObject,
			StateLineData.GLAccount);
	SettingsTable =
		DataProcessors.SettingUpFinancialAccountingAccounts.ExtraDimensionFillingSettings(
			FilterOfSettings,
			SettingsComposer);
	RowTableOfSettings = SettingsTable[0];
	
	FillPropertyValues(StateLineData, RowTableOfSettings);
	FillInPresentationInStateBarOfSetting(StateLineData);
	
EndProcedure

&AtServer
Procedure FillInPresentationInStateBarOfSetting(ConfigurationStateBar)
	If ConfigurationStateBar.UserSetting Then
		If ConfigurationStateBar.ThereAreExtdimensionFillingIssues Then
			ConfigurationStateBar.Presentation = NStr("vi = 'Tùy chỉnh người dùng (có lỗi)';
														|ru = 'Пользовательская настройка (есть ошибки)';
														|en = 'User setting (there are errors)'; fa = 'User setting (there are errors)';
														|it = 'Impostazione personalizzata (errori rilevati)';
														|pl = 'Ustawienie użytkownika (są błędy)';
														|tr = 'Kullanıcı ayarları (hatalar var)'");
		Else
			ConfigurationStateBar.Presentation = NStr("vi = 'Tùy chỉnh người sử dụng';
														|ru = 'Пользовательская настройка';
														|en = 'User setting'; fa = 'تنظیم کاربر';
														|it = 'Impostazioni personalizzate';
														|pl = 'Ustawienie użytkownika';
														|tr = 'Kullanıcı ayarı'");
		EndIf;
	Else
		If ConfigurationStateBar.ThereAreExtdimensionFillingIssues Then
			ConfigurationStateBar.Presentation = NStr("vi = 'Yêu cầu tùy chỉnh người sử dụng';
														|ru = 'Требуется пользовательская настройка';
														|en = 'User setting is required'; fa = 'User setting is required';
														|it = 'Richieste impostazioni personalizzate';
														|pl = 'Wymagane jest ustawienie użytkownika';
														|tr = 'Kullanıcı ayarları gerekiyor'");
		Else
			ConfigurationStateBar.Presentation = NStr("vi = 'Tự động từ nguồn ghi';
														|ru = 'Автоматически из регистра';
														|en = 'Automatically from register'; fa = 'Automatically from register';
														|it = 'Automaticamente dal registro';
														|pl = 'Automatycznie z rejestru';
														|tr = 'Kayıttan otomatik'");
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StateOfExtdimensionFillingSettingPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StateOfExtdimensionFillingSetting.ThereAreExtdimensionFillingIssues");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StateOfExtdimensionFillingSettingPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StateOfExtdimensionFillingSetting.ThereAreExtdimensionFillingIssues");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//
	
EndProcedure

#EndRegion

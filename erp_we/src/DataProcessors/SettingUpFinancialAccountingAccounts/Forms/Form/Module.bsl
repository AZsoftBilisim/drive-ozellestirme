#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SettingTypeGeneralByAccountingObject = Enums.TypesOfPostingsSettingsInFinancialAccounting.TotalByAccountingObject;
	SettingTypeExceptionByAccountingObject = Enums.TypesOfPostingsSettingsInFinancialAccounting.ExceptionForTheAccountingObject;
	
	Organization = Parameters.Organization;
	ChartOfAccounts = Parameters.ChartOfAccounts;
	PostingGenerationSetting = Parameters.PostingGenerationSetting;

	If Not ValueIsFilled(Organization) Then
		Organization = Catalogs.Companies.GetDefaultOrganization();
	EndIf;
	
	If Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	
	If Not ValueIsFilled(PostingGenerationSetting) Then
		PostingGenerationSetting = 
			Catalogs.FinancialAccountingPostingGenerationSetting.ConfiguringDefaultPostingGeneration(ChartOfAccounts);
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		CorrespondenceReflectionSettings, "CurrentAccountingObject", CurrentAccountingObject);
	CommonClientServer.SetDynamicListParameter(
		CorrespondenceReflectionSettings, "AlignDrCr", NStr("vi = 'Nợ/Có';
															|ru = 'Дт/Кт';
															|en = 'Dr/Cr'; fa = 'بد/بس';
															|it = 'Debito/Credito';
															|pl = 'Dr/Cr';
															|tr = 'Borç/Alacak'"));
	CommonClientServer.SetDynamicListParameter(
		CorrespondenceReflectionSettings, "AlignDr", NStr("vi = 'Nợ';
															|ru = 'Дт';
															|en = 'Dr'; fa = 'بد';
															|it = 'Debito';
															|pl = 'Wn';
															|tr = 'Borç'"));
	CommonClientServer.SetDynamicListParameter(
		CorrespondenceReflectionSettings, "AlignCr", NStr("vi = 'Có';
															|ru = 'Кт';
															|en = 'Cr'; fa = 'بس';
															|it = 'Credito';
															|pl = 'Ma';
															|tr = 'Alacak'"));
		
	CurrentMonth = BegOfMonth(CurrentSessionDate());
	
	PostingGenerationSettingOnChangeServer();
	
	CommonClientServer.SetDynamicListFilterItem(
		InternationalChartOfAccounts, 
		"ChartOfAccounts",
		ChartOfAccounts,
		,
		,
		True,
		DataCompositionSettingsItemViewMode.Inaccessible);
	
	ModeForViewingCorrespondenceReflectionSettings = "SharedList";
	CommonClientServer.SetDynamicListParameter(CorrespondenceReflectionSettings, "SharedList", True);
	
	If ModeForViewingCorrespondenceReflectionSettings = "SharedList" Then
		Items.TreeOfFinancialAccountingObjectsByCorrespondence.Visible = False;
		Items.OptionForSelectingAccountingObjectsCorrespondence.Visible = False;
		CommonClientServer.SetDynamicListParameter(CorrespondenceReflectionSettings, "SharedListm", True);
	ElsIf ModeForViewingCorrespondenceReflectionSettings = "SelectingAccountingItems" Then
		Items.TreeOfFinancialAccountingObjectsByCorrespondence.Visible = True;
		Items.OptionForSelectingAccountingObjectsCorrespondence.Visible = True;
		CommonClientServer.SetDynamicListParameter(CorrespondenceReflectionSettings, "SharedListm", False);
	EndIf;
	
	If ValueIsFilled(Parameters.AccountingObject) Then
		OptionForSelectingAccountingObjects = 1;
		CurLineIsSet = False;
		For Each TreeGroup In TreeOfFinancialAccountingObjects.GetItems() Do
			For Each TreeRow In TreeGroup.GetItems() Do
				If TreeRow.AccountingObject = Parameters.AccountingObject Then
					Items.TreeOfFinancialAccountingObjects.CurrentRow = TreeRow.GetID();
					CurLineIsSet = True;
				EndIf;
				If CurLineIsSet Then
					Break;
				EndIf;
			EndDo;
			If CurLineIsSet Then
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(Parameters.SettingObject1) Then
		TheCurrentConfigurationObjectWhenOpened = Parameters.SettingObject1;
	EndIf;
	
	NotifyAboutUnprocessedSettingsForFillingInInvoicesAndExtDimension();
	NotifyAboutUnprocessedSettingsForReflectingCorrespondence();
	NotifyAboutUnprocessedInternationalAccountingSettings();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Settings["ChartOfAccounts"] <> Undefined Then
		CommonClientServer.SetDynamicListFilterItem(
			InternationalChartOfAccounts, 
			"ChartOfAccounts",
			ChartOfAccounts,
			,
			,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
	EndIf;
	
	If Settings["PostingGenerationSetting"] <> Undefined Then
		PostingGenerationSettingOnChangeServer();
	EndIf;
	
	If Settings["Organization"] <> Undefined Then
		OrganizationOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If ValueIsFilled(Organization) And Settings["Organization"] <> Undefined Then
		Settings.Delete("Organization");
	EndIf;
	
	If ValueIsFilled(ChartOfAccounts) And Settings["ChartOfAccounts"] <> Undefined Then
		Settings.Delete("ChartOfAccounts");
	EndIf;
	
	If ValueIsFilled(PostingGenerationSetting) And Settings["PostingGenerationSetting"] <> Undefined Then
		Settings.Delete("PostingGenerationSetting");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		Notify("SettingUpInternationalAccountingAccountsCompleted");
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SettingsOfFinancialAccountingAccountsByObject" Then
		FillInInformationOnSettings(True);
	ElsIf EventName = "Write_SettingsForReflectingCorrespondenceInFinancialAccounting" Then
		FillInInformationOnSettings();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationOnChangeServer();
EndProcedure

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	SetCurSettingsPageForAccountingObjects();
	SetCurPageOfCorrespondenceSettings();
	ChartOfAccountsOnChangeServer();
EndProcedure

&AtClient
Procedure PostingGenerationSettingOnChange(Item)
	SetCurSettingsPageForAccountingObjects();
	SetCurPageOfCorrespondenceSettings();
	PostingGenerationSettingOnChangeServer();
EndProcedure

&AtClient
Procedure ConfigurationStatusURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	Filter = New Structure;
	Filter.Insert("Organization", Organization);
	Filter.Insert("ChartOfAccounts",   ChartOfAccounts);
	
	If FormattedStringURL = "CreateBusinessAccountPlansEntry" Then
		NotificationProcessing = New CallbackDescription("SelectingRecordingPeriodBusinessAccountPlans", ThisObject);
		ShowInputDate(NotificationProcessing, CurrentMonth, NStr("vi = 'Bật thiết lập từ';
																|ru = 'Включить настройку с';
																|en = 'Enable setting since'; fa = 'Enable setting since';
																|it = 'Includere impostazione con';
																|pl = 'Włącz ustawienie od';
																|tr = 'Bununla ayarları etkinleştir'"), DateFractions.Date);
		StandardProcessing = False;
	ElsIf FormattedStringURL = "OpenHistoryBusinessAccountPlans" Then
		StandardProcessing = False;
		FormParameters = New Structure;
		FormParameters.Insert("Filter", Filter);
		OpenForm("InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.Form.ListForm", 
			FormParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelHasNotProcessedSettingsForFillingInInvoicesAndExtDimensionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = HyperlinkOpenRawAccountSettings()
	 Or FormattedStringURL = HyperlinkOpenRawSettingsExtDimension() Then
		FullFormName = ?(
			FormattedStringURL = HyperlinkOpenRawAccountSettings(),
			"InformationRegister.DeleteSettingsOfFinancialAccountingAccountsByObject.ListForm",
			"InformationRegister.DeleteSettingsForFillingExtraDimensionOnFinancialAccountingAccounts.ListForm");
		FormParameters = New Structure();
		FormParameters.Insert("Filter", New Structure("NotProcessedAutomatically", True));
		OpenForm(FullFormName, FormParameters, ThisObject);
	ElsIf FormattedStringURL = HyperlinkHideNotificationAccountSettings() Then
		HideNotificationThereAreRawSettings(FormattedStringURL);
		Items.GroupHasRawAccountFillingSettingsAndExtDimension.Visible = False;
		Items.GroupHasRawInternationalAccountingSettings.Visible =
			Items.GroupHasRawSettingsForReflectingCorrespondence.Visible;
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelHasNotProcessedSettingsForReflectingCorrespondenceURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = HyperlinkOpenRawCorrespondenceSettings() Then
		FullFormName = "InformationRegister.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting.ListForm";
		FormParameters = New Structure();
		FormParameters.Insert("Filter", New Structure("NotProcessedAutomatically", True));
		OpenForm(FullFormName, FormParameters, ThisObject);
	ElsIf FormattedStringURL = HyperlinkHideNotificationCorrespondenceSettings() Then
		HideNotificationThereAreRawSettings(FormattedStringURL);
		Items.GroupHasRawSettingsForReflectingCorrespondence.Visible = False;
		Items.GroupHasRawInternationalAccountingSettings.Visible =
			Items.GroupHasRawAccountFillingSettingsAndExtDimension.Visible;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForSettingsElementsForAccountingObjects

&AtClient
Procedure SetupModeOnChange(Item)
	ConfigureFormWhenChangingConfigurationMode();
	ClearSelectionOfListOfExceptionsForConfigurationObject();
EndProcedure

&AtClient
Procedure TreeOfFinancialAccountingObjectsOnActivateRow(Item)
	
	SetCurSettingsPageForAccountingObjects();
	AttachIdleHandler("HandlerTreeOfFinancialAccountingObjectsOnActivateRow", 0.1 ,True);
	
EndProcedure

&AtClient
Procedure TreeOfFinancialAccountingObjectsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.TreeOfFinancialAccountingObjects.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.AccountingObject) Then
		ShowValue(, CurrentData.AccountingObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure GeneralSettingsTableGLAccountOnChange(Item)
	
	TheCurrentDataRow = Items.GeneralSettingsTable.CurrentData;
	
	RecordGeneralSettingsAccount(TheCurrentDataRow);
	
EndProcedure

&AtClient
Procedure GeneralSettingsTableLedgerAccountLongTermOnChange(Item)
	
	TheCurrentDataRow = Items.GeneralSettingsTable.CurrentData;
	
	RecordGeneralSettingsAccount(TheCurrentDataRow);
	
EndProcedure

&AtClient
Procedure GeneralSettingsTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.GeneralSettingsTable.CurrentData;
	If Field = Items.GeneralSettingsTableExceptions Then
		SetupMode = 1;
		ConfigureFormWhenChangingConfigurationMode();
		SetSelectionOfExceptionsForConfigurationObject(CurrentData.SettingObject1);
		If CurrentData.NumberOfExceptions = 0 Then
			Filter = SelectingInvoiceSettingsForAccountingItem(CurrentAccountingObject, SelectionObjectSettingsValue, SettingTypeExceptionByAccountingObject);
			OpenExceptionEntryForm(Filter, True);
		EndIf;
	ElsIf Field = Items.GeneralSettingsTableSettingObject1 Then
		If ValueIsFilled(CurrentData.SettingObject1) Then
			ShowValue(, CurrentData.SettingObject1);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectingTheObjectSettingsProcessingTheNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	If FormattedStringURL = "ClearSelectionByConfigurationObject" Then
		ClearSelectionOfListOfExceptionsForConfigurationObject();
	EndIf;
	
EndProcedure

&AtClient
Procedure OptionForSelectingAccountingObjectsOnChange(Item)
	
	If OptionForSelectingAccountingObjects = 1 Then // Required settings
		
		CurrentData = Items.TreeOfFinancialAccountingObjects.CurrentData;
		TreeRows  = TreeOfFinancialAccountingObjects.GetItems();
		
		If CurrentData = Undefined Or CurrentData.YouNeedToSetUpQuantityAccountingAccounts = 0 Then
			For Each TreeRow In TreeRows Do
				If TreeRow.YouNeedToSetUpQuantityAccountingAccounts > 0 Then
					Items.TreeOfFinancialAccountingObjects.CurrentRow = TreeRow.GetID();
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		CurrentData = Items.GeneralSettingsTable.CurrentData;
		If CurrentData = Undefined Or Not CurrentData.ConfigurationIsRequired Then
			For Each TableRow In GeneralSettingsTable Do
				If TableRow.ConfigurationIsRequired Then
					Items.GeneralSettingsTable.CurrentRow = TableRow.GetID();
					Break;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExclusionListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	CurrentData = Items.ExclusionList.CurrentData;
	
	Filter = SelectingInvoiceSettingsForAccountingItem(CurrentAccountingObject, SelectionObjectSettingsValue, SettingTypeExceptionByAccountingObject);
	If Copy Then
		Filter.Insert("GLAccount");
		FillPropertyValues(Filter, CurrentData);
	EndIf;
	OpenExceptionEntryForm(Filter, True);
	
EndProcedure

&AtClient
Procedure ExclusionListSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;
	Filter = SelectingInvoiceSettingsForAccountingItem(CurrentAccountingObject, SelectionObjectSettingsValue, SettingTypeExceptionByAccountingObject);
	FillPropertyValues(Filter, Items.ExclusionList.CurrentData );
	OpenExceptionEntryForm(Filter);
	
EndProcedure

&AtClient
Procedure ExclusionListAfterDeleteRow(Item)
	FillInInformationOnSettings(True);
EndProcedure

&AtClient
Procedure SettingUpExtdimensionFillingURLProcessing(Item, Var_URL, StandardProcessing)
	
	If Var_URL = "OpenExtdimensionFillSetting" Then
		
		StandardProcessing = False;
		CurrentRow = Items.TreeOfFinancialAccountingObjects.CurrentRow;
		If CurrentRow = Undefined Then
			Return;
		EndIf;
		
		CurrentData = TreeOfFinancialAccountingObjects.FindByID(CurrentRow);
		
		FormOpenParameters = New Structure();
		FormOpenParameters.Insert("ChartOfAccounts", ChartOfAccounts);
		FormOpenParameters.Insert("AccountingObject", CurrentData.AccountingObject);
		FormOpenParameters.Insert("PostingGenerationSetting", PostingGenerationSetting);
		FormOpenParameters.Insert("DataSource", CurrentData.DataSource);
		
		AdditionalParameters = New Structure();
		CallbackDescription = New CallbackDescription("AfterYouFinishSettingUpExtdimension", ThisObject, AdditionalParameters);
		
		OpenForm("DataProcessor.SettingUpFinancialAccountingAccounts.Form.FormOfFillingInExtraDimensionOfLedgerAccounts", 
			FormOpenParameters,
			ThisObject, 
			,,,
			CallbackDescription);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForCorrespondenceSettingsElements

&AtClient
Procedure TreeOfFinancialAccountingObjectsByCorrespondenceOnActivateRow(Item)
	
	SetCurPageOfCorrespondenceSettings();
	AttachIdleHandler("HandlerTreeOfFinancialAccountingObjectsByCorrespondenceOnActivateRow", 0.1 ,True);
	
EndProcedure

&AtClient
Procedure TreeOfFinancialAccountingObjectsByCorrespondenceSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.TreeOfFinancialAccountingObjectsByCorrespondence.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.AccountingObject) Then
		ShowValue(, CurrentData.AccountingObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ModeForViewingCorrespondenceReflectionSettingsOnChange(Item)
	
	If ModeForViewingCorrespondenceReflectionSettings = "SharedList" Then
		Items.TreeOfFinancialAccountingObjectsByCorrespondence.Visible = False;
		Items.OptionForSelectingAccountingObjectsCorrespondence.Visible = False;
		Items.CorrespondenceReflectionSettingsAlign.Visible = False;
		CommonClientServer.SetDynamicListParameter(CorrespondenceReflectionSettings, "SharedList", True);
	ElsIf ModeForViewingCorrespondenceReflectionSettings = "SelectingAccountingItems" Then
		Items.TreeOfFinancialAccountingObjectsByCorrespondence.Visible = True;
		Items.OptionForSelectingAccountingObjectsCorrespondence.Visible = True;
		Items.CorrespondenceReflectionSettingsAlign.Visible = True;
		CommonClientServer.SetDynamicListParameter(CorrespondenceReflectionSettings, "SharedList", False);
	EndIf;
	
	SetCurPageOfCorrespondenceSettings();
	
EndProcedure

&AtServerNoContext
Procedure CorrespondenceReflectionSettingsOnGetDataAtServer(TagName, Settings, Rows)
	
	PostingGenerationSetting = Undefined;
	
	For Each FilterElement In Settings.Filter.Items Do
		If FilterElement.LeftValue = New DataCompositionField("PostingGenerationSetting") Then
			PostingGenerationSetting = FilterElement.RightValue;
			Break;
		EndIf;
	EndDo;
	
	If PostingGenerationSetting = Undefined Then
		Return;
	EndIf;
	
	DivisionIntoShortTermLongTermAssetsAndLiabilities = Common.ObjectAttributeValue(
		PostingGenerationSetting, "DivisionIntoShortTermLongTermAssetsAndLiabilities");
	
	If Not DivisionIntoShortTermLongTermAssetsAndLiabilities Then
		Return;
	EndIf;
	
	TransactionSettings = Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings(
		PostingGenerationSetting);
	
	AccountingSettings = FinancialAccountingByFinancialRegisterData.AccountingSettingsByTransactionGenerationSettings(
		TransactionSettings);
	
	DescriptionOfAccountingObjects = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObjects(
		AccountingSettings);
	
	CacheOfAccountingObjects = New Map();
	
	FillInPresentationOfTermsInList(Rows, DescriptionOfAccountingObjects, CacheOfAccountingObjects, "Dr");
	FillInPresentationOfTermsInList(Rows, DescriptionOfAccountingObjects, CacheOfAccountingObjects, "Cr");
	
EndProcedure

&AtClient
Procedure CorrespondenceReflectionSettingsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.CorrespondenceReflectionSettingsApplicationProcedure Then
		
		StandardProcessing = False;
		RowData = Items.CorrespondenceReflectionSettings.RowData(RowSelected);
		
		Filter = New Structure;
		Filter.Insert("ChartOfAccounts", ChartOfAccounts);
		Filter.Insert("PostingGenerationSetting", PostingGenerationSetting);
		Filter.Insert("AccountingObjectDr", RowData.AccountingObjectDr);
		Filter.Insert("AccountingObjectCr", RowData.AccountingObjectCr);
		Filter.Insert("LongTermDr", RowData.LongTermDr);
		Filter.Insert("LongTermCr", RowData.LongTermCr);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", Filter);
		
		OpenForm("InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting.ListForm", 
			FormParameters,
			ThisObject,
			,
			,
			,
			,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CorrespondenceReflectionSettingsAfterDeleteRow(Item)
	FillInInformationOnSettings();
EndProcedure

&AtClient
Procedure CorrespondenceReflectionSettingsNewWriteProcessing(Item, NewObject, Source, StandardProcessing)
	FillInInformationOnSettings();
EndProcedure

&AtClient
Procedure OptionForSelectingAccountingObjectsCorrespondenceOnChange(Item)
	
	If OptionForSelectingAccountingObjectsCorrespondence = 1 Then // With settings
		CurrentData = Items.TreeOfFinancialAccountingObjectsByCorrespondence.CurrentData;
		TreeRows  = TreeOfFinancialAccountingObjects.GetItems();
		If CurrentData = Undefined Or CurrentData.CorrespondenceReflectionSettingsQuantity = 0 Then
			For Each TreeRow In TreeRows Do
				If TreeRow.CorrespondenceReflectionSettingsQuantity > 0 Then
					Items.TreeOfFinancialAccountingObjectsByCorrespondence.CurrentRow = TreeRow.GetID();
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForElementsThatViewInvoiceSettings

&AtClient
Procedure InternationalChartOfAccountsOnActivateRow(Item)
	AttachIdleHandler("ChartOfAccountsHandlerIsActiveWhenRowIsActivated", 0.1 ,True);
EndProcedure

&AtClient
Procedure SettingsByAccountSelection(Item, RowSelected, Field, StandardProcessing)
	
	Open_SettingsForm(RowSelected);
	
EndProcedure

&AtClient
Procedure OptionForSelectingAccountingAccountsOnChange(Item)
	
	If OptionForSelectingAccountingAccounts = 0 Then
		Items.InternationalChartOfAccounts.Representation = TableRepresentation.Tree;
	Else
		Items.InternationalChartOfAccounts.Representation = TableRepresentation.List;
	EndIf;
	
	ListSelectionsClientServer.ChangeListSelectionElement(
		InternationalChartOfAccounts, 
		"HasSettings", 
		True, 
		OptionForSelectingAccountingAccounts = 1);
	
EndProcedure

#EndRegion

#Region FormCommandHandler_

&AtClient
Procedure PostingGenerationSetting(Command)
	If CheckFilling() Then
		FormParameters = New Structure();
		FormParameters.Insert("Key", PostingGenerationSetting);
		OpenForm("Catalog.FinancialAccountingPostingGenerationSetting.ObjectForm", 
			FormParameters, ThisObject);
	EndIf;
EndProcedure


&AtClient
Procedure FillInTheAccountingInvoice(Command)
	
	CurrentRow = Items.TreeOfFinancialAccountingObjects.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentData = TreeOfFinancialAccountingObjects.FindByID(CurrentRow);

	FormParameters = New Structure();
	FormParameters.Insert("ChartOfAccounts", ChartOfAccounts);
	FormParameters.Insert("ObjectOfAccountingForImproperValues", CurrentData.ImproperValues);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", Items.GeneralSettingsTable.SelectedRows);
	DescriptionOfAlerts = New CallbackDescription("WhenYouFinishSelectingAccountingAccountToFillIn", ThisObject, AdditionalParameters);
	
	OpenForm("DataProcessor.SettingUpFinancialAccountingAccounts.Form.SelectionFormOfLedgerAccount", 
		FormParameters,
		ThisObject, , , ,
		DescriptionOfAlerts, 
		FormWindowOpeningMode.LockOwnerWindow );
	
EndProcedure

&AtClient
Procedure OpenSettingsItem(Command)
	
	If Items.SettingsByAccount.CurrentRow = Undefined Then
		Return;
	EndIf;
	Open_SettingsForm(Items.SettingsByAccount.CurrentRow)
	
EndProcedure

&AtClient
Procedure CorrespondenceAnalysis(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", "CorrespondenceAnalysisChessBulletin");
	FormParameters.Insert("GenerateOnOpen", True);
	
	SelectionParameter = New Structure();
	If ValueIsFilled(ChartOfAccounts) Then
		SelectionParameter.Insert("ChartOfAccounts", ChartOfAccounts);
	EndIf;
	If ValueIsFilled(PostingGenerationSetting) Then
		SelectionParameter.Insert("PostingGenerationSetting", PostingGenerationSetting);
	EndIf;
	FormParameters.Insert("Filter", SelectionParameter);
	
	OpenForm("Report.AnalysisOfOperationalAccountingCorrespondence.ObjectForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	PostingGenerationSettingOnChangeServer();
EndProcedure

&AtClient
Procedure OpenOutdatedInvoiceSettingsForAccountingObjects(Command)
	
	FullFormName = "InformationRegister.DeleteSettingsOfFinancialAccountingAccountsByObject.ListForm";
	OpenForm(FullFormName,, ThisObject, "All");
	
EndProcedure

&AtClient
Procedure OpenOutdatedExtDimensionSettingsForFillingInSubAccount(Command)
	
	FullFormName = "InformationRegister.DeleteSettingsForFillingExtraDimensionOnFinancialAccountingAccounts.ListForm";
	OpenForm(FullFormName,, ThisObject, "All");
	
EndProcedure

&AtClient
Procedure OpenOutdatedSettingsForCorrespondenceReflection(Command)
	
	FullFormName = "InformationRegister.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting.ListForm";
	OpenForm(FullFormName,, ThisObject, "All");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GeneralSettingsTableGLAccount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneralSettingsTable.GLAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneralSettingsTable.ConfigurationIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneralSettingsTable.LongTermSetupIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GeneralSettingsTableLedgerAccountLongTerm.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneralSettingsTable.LedgerAccountLongTerm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneralSettingsTable.ConfigurationIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneralSettingsTable.LongTermSetupIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjects.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsIsFolder.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsPresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsYouNeedToSetUpQuantityAccountingAccounts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeOfFinancialAccountingObjects.Visible");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeOfFinancialAccountingObjects.YouNeedToSetUpQuantityAccountingAccounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeOfFinancialAccountingObjects.GeneralSettingsQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeOfFinancialAccountingObjects.ExceptionSettingsNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Visible",  False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjects.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsIsFolder.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsPresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsYouNeedToSetUpQuantityAccountingAccounts.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
 	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeOfFinancialAccountingObjects.YouNeedToSetUpQuantityAccountingAccounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OptionForSelectingAccountingObjects");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1; // Required settings
	
	Item.Appearance.SetParameterValue("Visible",  False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GeneralSettingsTable.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GeneralSettingsTableSettingObject1.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GeneralSettingsTableExceptions.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableGeneralSettingsAccountingAccountGroup.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneralSettingsTable.ConfigurationIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OptionForSelectingAccountingObjects");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1; // Required settings
	
	Item.Appearance.SetParameterValue("Visible",  False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExclusionListOrganization.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExclusionList.Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tất cả';
													|ru = 'Все';
													|en = 'All'; fa = 'همه';
													|it = 'Tutti';
													|pl = 'All';
													|tr = 'Tümü'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExclusionListPlaceOfRegistration.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExclusionList.PlaceOfRegistration");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tất cả';
													|ru = 'Все';
													|en = 'All'; fa = 'همه';
													|it = 'Tutti';
													|pl = 'All';
													|tr = 'Tümü'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GeneralSettingsTableSettingObject1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneralSettingsTable.SettingObject1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Undefined;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chung';
													|ru = 'Общая';
													|en = 'General'; fa = 'عمومی';
													|it = 'Generale';
													|pl = 'General';
													|tr = 'Ortak'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GeneralSettingsTableSettingObject1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GeneralSettingsTable.SettingObject1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa chỉ ra';
													|ru = 'Не указан(а)';
													|en = 'Not specified'; fa = 'مشخص نشده';
													|it = 'Non specificato(a)';
													|pl = 'Nie określono';
													|tr = 'Belirtilmedi'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExclusionListSettingObject1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExclusionList.SettingObject1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa chỉ ra';
													|ru = 'Не указан(а)';
													|en = 'Not specified'; fa = 'مشخص نشده';
													|it = 'Non specificato(a)';
													|pl = 'Nie określono';
													|tr = 'Belirtilmedi'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrespondenceReflectionSettingsApplySubsequentSettings.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CorrespondenceReflectionSettings.ApplySubsequentSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không áp dụng';
													|ru = 'Не применять';
													|en = 'Do not apply'; fa = 'عدم اعمال';
													|it = 'Non applicare';
													|pl = 'Nie stosować';
													|tr = 'Uygulanmasın'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrespondenceReflectionSettingsApplySubsequentSettings.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CorrespondenceReflectionSettings.ApplySubsequentSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Áp dụng';
													|ru = 'Применять';
													|en = 'Apply'; fa = 'اعمال';
													|it = 'Applicare';
													|pl = 'Zastosuj';
													|tr = 'Uygula'"));
		
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrespondenceReflectionSettingsGLAccountDr.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrespondenceReflectionSettingsGLAccountCr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CorrespondenceReflectionSettings.ItIsNotReflectedInTheAccounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không phản ánh>';
													|ru = '<не отражается>';
													|en = '<not recorded>'; fa = '<not recorded>';
													|it = '<non si rileva>';
													|pl = '<nie wyświetla się>';
													|tr = '<yansıtılmıyor>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableData);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrespondenceReflectionSettingsGLAccountDr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CorrespondenceReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thay đổi>';
													|ru = '<не изменен>';
													|en = '<not changed>'; fa = '<not changed>';
													|it = '<non modificato>';
													|pl = '<nie zmieniony>';
													|tr = '<değiştirilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableData);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrespondenceReflectionSettingsGLAccountCr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CorrespondenceReflectionSettings.LedgerAccountIsDeterminedByAccountingObjectSetupCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thay đổi>';
													|ru = '<не изменен>';
													|en = '<not changed>'; fa = '<not changed>';
													|it = '<non modificato>';
													|pl = '<nie zmieniony>';
													|tr = '<değiştirilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableData);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsByCorrespondence.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsByCorrespondenceIsGroup.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsByCorrespondencePresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsByCorrespondenceNumber.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeOfFinancialAccountingObjects.CorrespondenceReflectionSettingsQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OptionForSelectingAccountingObjectsCorrespondence");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1; // With settings
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsByCorrespondence.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsByCorrespondenceIsGroup.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsByCorrespondencePresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfFinancialAccountingObjectsByCorrespondenceNumber.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeOfFinancialAccountingObjects.ImproperValues");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#Region SettingsByAccount
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsByAccountAccountingObject.Name);
	
	ItemFilter =  Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingsByAccount.SettingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ListOfConfigurationTypes = New ValueList();
	ListOfConfigurationTypes.Add(Enums.TypesOfPostingsSettingsInFinancialAccounting.TotalByAccountingObject);
	ListOfConfigurationTypes.Add(Enums.TypesOfPostingsSettingsInFinancialAccounting.ExceptionForTheAccountingObject);
	ItemFilter.RightValue = ListOfConfigurationTypes;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsByAccountThereIsAdditionalSelectionDr.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsByAccountAccountingObjectDr.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsByAccountThereIsAdditionalSelectionCr.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsByAccountAccountingObjectCr.Name);
	
	ItemFilter =  Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingsByAccount.SettingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfPostingsSettingsInFinancialAccounting.ByCorrespondence;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure NotifyAboutUnprocessedSettingsForFillingInInvoicesAndExtDimension()
	
	Query = New Query();
	Query.Text = "
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.DeleteSettingsOfFinancialAccountingAccountsByObject AS AccountingAccountSettings
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.DeleteSettingsForFillingExtraDimensionOnFinancialAccountingAccounts AS ExtraDimensionFillingSettings
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.DeleteSettingsOfFinancialAccountingAccountsByObject AS AccountingAccountSettings
	|WHERE
	|	AccountingAccountSettings.NotProcessedAutomatically
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.DeleteSettingsForFillingExtraDimensionOnFinancialAccountingAccounts AS ExtraDimensionFillingSettings
	|WHERE
	|	ExtraDimensionFillingSettings.NotProcessedAutomatically
	|";
	
	Result = Query.ExecuteBatch();
	ThereAreOutdatedAccountSettings = Not Result[0].IsEmpty();
	ThereAreOutdatedExtDimensionSettings = Not Result[1].IsEmpty();
	ThereAreRawAccountSettings = Not Result[2].IsEmpty();
	ThereAreRawExtDimensionSettings = Not Result[3].IsEmpty();
	
	Items.OpenOutdatedInvoiceSettingsForAccountingObjects.Visible = ThereAreOutdatedAccountSettings;
	Items.OpenOutdatedExtDimensionSettingsForFillingInSubAccount.Visible = ThereAreOutdatedExtDimensionSettings;
	
	If Not Constants.DeleteNotificationThereAreUnprocessedInternationalAccountingSettings.DisplayAlertThereAreRawAccountSettingsAndExtDimension() Then
		Items.GroupHasRawAccountFillingSettingsAndExtDimension.Visible = False;
		Return;
	EndIf;
	
	If ThereAreRawAccountSettings Or ThereAreRawExtDimensionSettings Then
		TitleLines = New Array();
		TitleLines.Add(NStr(
			"vi = '<span style=""color: %1"">Khi cập nhật chương trình sang phiên bản mới
			|không phải tất cả tùy chỉnh đã được tự động chuyển đổi.</span>';
			|ru = '<span style=""color: %1"">При обновлении программы на новую версию
			|не все настройки были автоматически сконвертированны.</span>';
			|en = '<span style=""color: %1"">When updating the program to a new version,
			|not all settings were automatically converted.</span>'; fa = '<span style=""color: %1"">When updating the program to a new version,
			|not all settings were automatically converted.</span>';
			|it = '<span style=""color: %1"">При обновлении программы на новую версию
			|не все настройки были автоматически сконвертированны.</span>';
			|pl = '<span style=""color: %1"">When updating the program to a new version,
			|not all settings were automatically converted.</span>';
			|tr = '<span style=""color: %1"">Programın yeni sürüme güncellenmesi sırasında
			|tüm ayarlar otomatik olarak dönüştürülmedi.</span>'"));
		
		If ThereAreRawAccountSettings And ThereAreRawExtDimensionSettings Then
			TitleLines.Add(NStr(
				"vi = '<span style=""color: %1"">Chưa được xử lý</span>
				|<a style=""color: %1; font: %2"" href=""%3"">tùy chỉnh tài khoản kế toán</a>
				|<span style=""color: %1"">và</span>
				|<a style=""color: %1; font: %2"" href=""%4"">tùy chỉnh điền khoản mục</a>
				|<span style=""color: %1"">không được hiển thị trong danh sách và không tham gia tạo bút toán.</span>';
				|ru = '<span style=""color: %1"">Необработанные</span>
				|<a style=""color: %1; font: %2"" href=""%3"">настройки счетов учета</a>
				|<span style=""color: %1"">и</span>
				|<a style=""color: %1; font: %2"" href=""%4"">настройки заполнения субконто</a>
				|<span style=""color: %1"">не отображаются в списке и не участвуют в формировании проводок.</span>';
				|en = '<span style=""color: %1"">Unprocessed</span>
				|<a style=""color: %1; font: %2"" href=""%3"">ledger account settings</a>
				|<span style=""color: %1"">and</span>
				|<a style=""color: %1; font: %2"" href=""%4"">extra dimension filling settings</a>
				|<span style=""color: %1"">are not displayed in the list and do not generate entries.</span>'; fa = '<span style=""color: %1"">Unprocessed</span>
				|<a style=""color: %1; font: %2"" href=""%3"">ledger account settings</a>
				|<span style=""color: %1"">and</span>
				|<a style=""color: %1; font: %2"" href=""%4"">extra dimension filling settings</a>
				|<span style=""color: %1"">are not displayed in the list and do not generate entries.</span>';
				|it = '<span style=""color: %1"">Необработанные</span>
				|<a style=""color: %1; font: %2"" href=""%3"">настройки счетов учета</a>
				|<span style=""color: %1"">и</span>
				|<a style=""color: %1; font: %2"" href=""%4"">настройки заполнения субконто</a>
				|<span style=""color: %1"">не отображаются в списке и не участвуют в формировании проводок.</span>';
				|pl = '<span style=""color: %1"">Unprocessed</span>
				|<a style=""color: %1; font: %2"" href=""%3"">ledger account settings</a>
				|<span style=""color: %1"">and</span>
				|<a style=""color: %1; font: %2"" href=""%4"">extra dimension filling settings</a>
				|<span style=""color: %1"">are not displayed in the list and do not generate entries.</span>';
				|tr = '<span style=""color: %1"">İşlenmemiş</span>
				|<a style=""color: %1; font: %2"" href=""%3"">defterikebir hesabı ayarları</a>
				|<span style=""color: %1"">ve</span>
				|<a style=""color: %1; font: %2"" href=""%4"">ek boyutlar doldurma ayarları </a>
				|<span style=""color: %1"">listede görüntülenmez ve girişleri oluşturmaz.</span>'"));
		ElsIf ThereAreRawAccountSettings Then
			TitleLines.Add(NStr(
				"vi = '<span style=""color: %1"">Không được xử lý</span>
				|<a style=""color: %1; font: %2"" href=""%3"">tùy chỉnh tài khoản kế toán</a>
				|<span style=""color: %1"">không được hiển thị trong danh sách và không tham gia tạo bút toán.</span>';
				|ru = '<span style=""color: %1"">Необработанные</span>
				|<a style=""color: %1; font: %2"" href=""%3"">настройки счетов учета</a>
				|<span style=""color: %1"">не отображаются в списке и не участвуют в формировании проводок.</span>';
				|en = '<span style=""color: %1"">Unprocessed</span>
				|<a style=""color: %1; font: %2"" href=""%3"">ledger account settings</a>
				|<span style=""color: %1"">are not displayed in the list and do not generate entries.</span>'; fa = '<span style=""color: %1"">Unprocessed</span>
				|<a style=""color: %1; font: %2"" href=""%3"">ledger account settings</a>
				|<span style=""color: %1"">are not displayed in the list and do not generate entries.</span>';
				|it = '<span style=""color: %1"">Необработанные</span>
				|<a style=""color: %1; font: %2"" href=""%3"">настройки счетов учета</a>
				|<span style=""color: %1"">не отображаются в списке и не участвуют в формировании проводок.</span>';
				|pl = '<span style=""color: %1"">Unprocessed</span>
				|<a style=""color: %1; font: %2"" href=""%3"">ledger account settings</a>
				|<span style=""color: %1"">are not displayed in the list and do not generate entries.</span>';
				|tr = '<span style=""color: %1"">İşlenmemiş</span>
				|<a style=""color: %1; font: %2"" href=""%3"">defterikebir hesabı ayarları</a>
				|<span style=""color: %1"">listede görüntülenmez ve girişleri oluşturmaz.</span>'"));
		ElsIf ThereAreRawExtDimensionSettings Then
			TitleLines.Add(NStr(
				"vi = '<span style=""color: %1"">Không được xử lý</span>
				|<a style=""color: %1; font: %2"" href=""%4"">tùy chỉnh điền khoản mục</a>
				|<span style=""color: %1"">không được hiển thị trong danh sách và không tham gia tạo bút toán.</span>';
				|ru = '<span style=""color: %1"">Необработанные</span>
				|<a style=""color: %1; font: %2"" href=""%4"">настройки заполнения субконто</a>
				|<span style=""color: %1"">не отображаются в списке и не участвуют в формировании проводок.</span>';
				|en = '<span style=""color: %1"">Unprocessed</span>
				|<a style=""color: %1; font: %2"" href=""%4"">extra dimension filling settings</a>
				|<span style=""color: %1"">are not displayed in the list and do not generate entries.</span>'; fa = '<span style=""color: %1"">Unprocessed</span>
				|<a style=""color: %1; font: %2"" href=""%4"">extra dimension filling settings</a>
				|<span style=""color: %1"">are not displayed in the list and do not generate entries.</span>';
				|it = '<span style=""color: %1"">Необработанные</span>
				|<a style=""color: %1; font: %2"" href=""%4"">настройки заполнения субконто</a>
				|<span style=""color: %1"">не отображаются в списке и не участвуют в формировании проводок.</span>';
				|pl = '<span style=""color: %1"">Unprocessed</span>
				|<a style=""color: %1; font: %2"" href=""%4"">extra dimension filling settings</a>
				|<span style=""color: %1"">are not displayed in the list and do not generate entries.</span>';
				|tr = '<span style=""color: %1"">İşlenmemiş</span>
				|<a style=""color: %1; font: %2"" href=""%4"">ek boyutlar doldurma ayarları</a>
				|<span style=""color: %1"">listede görüntülenmez ve girişleri oluşturmaz.</span>'"));
		EndIf;
		
		TitleLines.Add(NStr(
			"vi = '<span style=""color: %1"">Cần thực hiện thủ công các cài đặt cho các đối tượng ghi nhận.</span>
			|<a style=""color: %1; font: %2"" href=""%5"">Không hiển thị thông báo này nữa.</a>';
			|ru = '<span style=""color: %1"">Настройки для этих объектов учета необходимо выполнить вручную.</span>
			|<a style=""color: %1; font: %2"" href=""%5"">Больше не показывать это сообщение.</a>';
			|en = '<span style=""color: %1"">Set up these accounting objects manually.</span>
			|<a style=""color: %1; font: %2"" href=""%5"">Do not show this message again.</a>'; fa = '<span style=""color: %1"">Set up these accounting objects manually.</span>
			|<a style=""color: %1; font: %2"" href=""%5"">Do not show this message again.</a>';
			|it = '<span style=""color: %1"">Настройки для этих объектов учета необходимо выполнить вручную.</span>
			|<a style=""color: %1; font: %2"" href=""%5"">Больше не показывать это сообщение.</a>';
			|pl = '<span style=""color: %1"">Set up these accounting objects manually.</span>
			|<a style=""color: %1; font: %2"" href=""%5"">Do not show this message again.</a>';
			|tr = '<span style=""color: %1"">Bu muhasebe nesneleri manuel olarak ayarlanmalı.</span>
			|<a style=""color: %1; font: %2"" href=""%5"">Bu mesajı bir daha gösterme.</a>'"));
		
		TitleTemplate1 = StrConcat(TitleLines, " ");
		TitleLine = StringFunctions.FormattedString(
			StrReplace(TitleTemplate1, Chars.LF, " "),
			Metadata.StyleItems.HelpText.Name,
			Metadata.StyleItems.UnderlinedFont.Name,
			HyperlinkOpenRawAccountSettings(),
			HyperlinkOpenRawSettingsExtDimension(),
			HyperlinkHideNotificationAccountSettings());
		
		Items.LabelHasNotProcessedSettingsForFillingInInvoicesAndExtDimension.Title = TitleLine;
		Items.GroupHasRawAccountFillingSettingsAndExtDimension.Visible = True;
	Else
		Items.GroupHasRawAccountFillingSettingsAndExtDimension.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure NotifyAboutUnprocessedSettingsForReflectingCorrespondence()
	
	Query = New Query();
	Query.Text = "
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting AS CorrespondenceReflectionSettings
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting AS CorrespondenceReflectionSettings
	|WHERE
	|	CorrespondenceReflectionSettings.NotProcessedAutomatically
	|";
	
	Result = Query.ExecuteBatch();
	ThereAreOutdatedCorrespondenceSettings = Not Result[0].IsEmpty();
	ThereAreRawCorrespondenceSettings = Not Result[1].IsEmpty();

	Items.OpenOutdatedSettingsForDisplayingCorrespondence.Visible = ThereAreOutdatedCorrespondenceSettings;
	
	If Not Constants.DeleteNotificationThereAreUnprocessedInternationalAccountingSettings.DisplayAlertThereAreUnprocessedCorrespondenceSettings() Then
		Items.GroupHasRawSettingsForReflectingCorrespondence.Visible = False;
		Return;
	EndIf;
	
	If ThereAreRawCorrespondenceSettings Then
		TitleTemplate1 = NStr("vi = '<span style=""color: %1"">Khi cập nhật chương trình sang phiên bản mới
			|không phải tất cả tùy chỉnh phản ánh đối ứng đều được chuyển đổi tự động. Không được xử lý</span>
			|<a style=""color: %1; font: %2"" href=""%3"">tùy chỉnh phản ánh đối ứng</a>
			|<span style=""color: %1"">không được hiển thị trong danh sách và không tham gia vào tạo bút toán.
			|Cần thực hiện tùy chỉnh thủ công đối với các đối ứng này.</span>
			|<a style=""color: %1; font: %2"" href=""%4"">Không hiển thị lại thông báo này.</a>';
			|ru = '<span style=""color: %1"">При обновлении программы на новую версию
			|не все настройки отражения корреспонденций были автоматически сконвертированны. Необработанные</span>
			|<a style=""color: %1; font: %2"" href=""%3"">настройки отражения корреспонденций</a>
			|<span style=""color: %1"">не отображаются в списке и не участвуют в формировании проводок.
			|Настройки для этих корреспонденций необходимо выполнить вручную.</span>
			|<a style=""color: %1; font: %2"" href=""%4"">Больше не показывать это сообщение.</a>';
			|en = '<span style=""color: %1"">When updating the program to a new version,
			|not all correspondence recording settings were automatically converted. Unprocessed</span>
			|<a style=""color: %1; font: %2"" href=""%3"">correspondence recording settings</a>
			|<span style=""color: %1"">are not displayed in the list and do not generate entries.
			|Set up these correspondences manually.</span>
			|<a style=""color: %1; font: %2"" href=""%4"">Do not show this message again.</a>'; fa = '<span style=""color: %1"">When updating the program to a new version,
			|not all correspondence recording settings were automatically converted. Unprocessed</span>
			|<a style=""color: %1; font: %2"" href=""%3"">correspondence recording settings</a>
			|<span style=""color: %1"">are not displayed in the list and do not generate entries.
			|Set up these correspondences manually.</span>
			|<a style=""color: %1; font: %2"" href=""%4"">Do not show this message again.</a>';
			|it = '<span style=""color: %1"">При обновлении программы на новую версию
			|не все настройки отражения корреспонденций были автоматически сконвертированны. Необработанные</span>
			|<a style=""color: %1; font: %2"" href=""%3"">настройки отражения корреспонденций</a>
			|<span style=""color: %1"">не отображаются в списке и не участвуют в формировании проводок.
			|Настройки для этих корреспонденций необходимо выполнить вручную.</span>
			|<a style=""color: %1; font: %2"" href=""%4"">Больше не показывать это сообщение.</a>';
			|pl = '<span style=""color: %1"">When updating the program to a new version,
			|not all correspondence recording settings were automatically converted. Unprocessed</span>
			|<a style=""color: %1; font: %2"" href=""%3"">correspondence recording settings</a>
			|<span style=""color: %1"">are not displayed in the list and do not generate entries.
			|Set up these correspondences manually.</span>
			|<a style=""color: %1; font: %2"" href=""%4"">Do not show this message again.</a>';
			|tr = '<span style=""color: %1"">Programın yeni sürüme güncellenmesi sırasında
			|tüm ayarlar otomatik olarak dönüştürülmedi. İşlenmemiş</span>
			|<a style=""color: %1; font: %2"" href=""%3"">çift taraflı kayıt kaydetme ayarları</a>
			|<span style=""color: %1"">listede görüntülenmez ve girişleri oluşturmaz.
			|Bu çıft taraflı kayıtlar manuel olarak ayarlanmalı.</span>
			|<a style=""color: %1; font: %2"" href=""%4"">Bu mesajı bir daha gösterme.</a>'");
		
		TitleLine = StringFunctions.FormattedString(
			StrReplace(TitleTemplate1, Chars.LF, " "),
			Metadata.StyleItems.HelpText.Name,
			Metadata.StyleItems.UnderlinedFont.Name,
			HyperlinkOpenRawCorrespondenceSettings(),
			HyperlinkHideNotificationCorrespondenceSettings());
		
		Items.LabelHasNotProcessedSettingsForReflectingCorrespondence.Title = TitleLine;
		Items.GroupHasRawSettingsForReflectingCorrespondence.Visible = True;
	Else
		Items.GroupHasRawSettingsForReflectingCorrespondence.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure NotifyAboutUnprocessedInternationalAccountingSettings()
	
	NotifyAboutUnprocessedAccountSettingsAndExtDimension = Constants.DeleteNotificationThereAreUnprocessedInternationalAccountingSettings.DisplayAlertThereAreRawAccountSettingsAndExtDimension();
	NotifyAboutUnprocessedCorrespondenceSettings = Constants.DeleteNotificationThereAreUnprocessedInternationalAccountingSettings.DisplayAlertThereAreUnprocessedCorrespondenceSettings();
	
	If Not NotifyAboutUnprocessedAccountSettingsAndExtDimension And Not NotifyAboutUnprocessedCorrespondenceSettings Then
		Items.GroupHasRawInternationalAccountingSettings.Visible = False;
		Return;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("NotifyAboutUnprocessedAccountSettingsAndExtDimension", NotifyAboutUnprocessedAccountSettingsAndExtDimension);
	Query.SetParameter("NotifyAboutUnprocessedCorrespondenceSettings", NotifyAboutUnprocessedCorrespondenceSettings);
	
	Query.Text = "
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.DeleteSettingsOfFinancialAccountingAccountsByObject AS AccountingAccountSettings
	|WHERE
	|	&NotifyAboutUnprocessedAccountSettingsAndExtDimension
	|	AND AccountingAccountSettings.NotProcessedAutomatically
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.DeleteSettingsForFillingExtraDimensionOnFinancialAccountingAccounts AS ExtraDimensionFillingSettings
	|WHERE
	|	&NotifyAboutUnprocessedAccountSettingsAndExtDimension
	|	AND ExtraDimensionFillingSettings.NotProcessedAutomatically
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting AS CorrespondenceReflectionSettings
	|WHERE
	|	&NotifyAboutUnprocessedCorrespondenceSettings
	|	AND CorrespondenceReflectionSettings.NotProcessedAutomatically
	|";
	
	Result = Query.Execute();
	ThereAreRawSettings = Not Result.IsEmpty();
	
	If ThereAreRawSettings Then
		TitleTemplate1 = NStr("vi = '<span style=""color: %1"">Khi cập nhật chương trình sang phiên bản mới
			|không phải tất cả tùy chỉnh đều được chuyển đổi tự động. Các tùy chỉnh chưa được xử lý không được hiển thị
			|trong danh sách và không tham gia vào tạo bút toán. Mở danh sách các tùy chỉnh chưa được xử lý
			|và có thể chuyển thủ công chúng trên các trang khác của biểu mẫu này.</span>';
			|ru = '<span style=""color: %1"">При обновлении программы на новую версию
			|не все настройки были автоматически сконвертированны. Необработанные настройки не отображаются
			|в списке и не участвуют в формировании проводок. Открыть список необработанных настроек
			|и выполнить их ручной перенос можно на других страницах этой формы.</span>';
			|en = '<span style=""color: %1"">When updating the program to a new version,
			|not all settings were automatically converted. Unprocessed settings are not displayed
			|in the list and do not generate entries. You can open the list of unprocessed settings
			|and transfer them manually on other pages of this form.</span>'; fa = '<span style=""color: %1"">When updating the program to a new version,
			|not all settings were automatically converted. Unprocessed settings are not displayed
			|in the list and do not generate entries. You can open the list of unprocessed settings
			|and transfer them manually on other pages of this form.</span>';
			|it = '<span style=""color: %1"">При обновлении программы на новую версию
			|не все настройки были автоматически сконвертированны. Необработанные настройки не отображаются
			|в списке и не участвуют в формировании проводок. Открыть список необработанных настроек
			|и выполнить их ручной перенос можно на других страницах этой формы.</span>';
			|pl = '<span style=""color: %1"">When updating the program to a new version,
			|not all settings were automatically converted. Unprocessed settings are not displayed
			|in the list and do not generate entries. You can open the list of unprocessed settings
			|and transfer them manually on other pages of this form.</span>';
			|tr = '<span style=""color: %1"">Programın yeni sürüme güncellenmesi sırasında
			|tüm ayarlar otomatik olarak dönüştürülmedi. İşlenmemiş ayarlar
			|listede görüntülenmez ve girişleri oluşturmaz. İşlenmemiş ayarlar listesini açmak
			|ve ayarları manuel olarak aktarmak için bu formun diğer sayfalarını kullanabilirsiniz.</span>'");
		
		TitleLine = StringFunctions.FormattedString(
			StrReplace(TitleTemplate1, Chars.LF, " "),
			Metadata.StyleItems.HelpText.Name);
		
		Items.InscriptionHasNotProcessedSettingsOfInternationalAccounting.Title = TitleLine;
		Items.GroupHasRawInternationalAccountingSettings.Visible = True;
	Else
		Items.GroupHasRawInternationalAccountingSettings.Visible = False;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure HideNotificationThereAreRawSettings(URL)
	
	If URL = HyperlinkHideNotificationAccountSettings() Then
		Constants.DeleteNotificationThereAreUnprocessedInternationalAccountingSettings.HideAlertThereAreRawAccountSettingsAndExtDimension();
	ElsIf URL = HyperlinkHideNotificationCorrespondenceSettings() Then
		Constants.DeleteNotificationThereAreUnprocessedInternationalAccountingSettings.HideNotificationThereAreUnprocessedCorrespondenceSettings();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function HyperlinkOpenRawAccountSettings()
	
	Return "OpenRawAccountSettingsList";
	
EndFunction

&AtClientAtServerNoContext
Function HyperlinkOpenRawSettingsExtDimension()
	
	Return "OpenExtDimensionListOfRawSettings";
	
EndFunction

&AtClientAtServerNoContext
Function HyperlinkOpenRawCorrespondenceSettings()
	
	Return "OpenListOfUnprocessedCorrespondenceSettings";
	
EndFunction

&AtClientAtServerNoContext
Function HyperlinkHideNotificationAccountSettings()
	
	Return "HideAlertThereAreRawAccountSettingsAndExtDimension";
	
EndFunction

&AtClientAtServerNoContext
Function HyperlinkHideNotificationCorrespondenceSettings()
	
	Return "HideNotificationThereAreUnprocessedCorrespondenceSettings";
	
EndFunction

#Region ServerHandlersForFormHeaderElement

&AtServer
Procedure OrganizationOnChangeServer()
	
	GetSetupStatus();
	SetMainSelectionOfExceptionList(ExclusionList, Organization, ChartOfAccounts, PostingGenerationSetting);
	SetMainSelectionOfCorrespondenceReflectionSettings(CorrespondenceReflectionSettings, ChartOfAccounts, PostingGenerationSetting);
	
EndProcedure

&AtServer
Procedure ChartOfAccountsOnChangeServer()
	
	PostingGenerationSetting = 
		Catalogs.FinancialAccountingPostingGenerationSetting.ConfiguringDefaultPostingGeneration(ChartOfAccounts);
	PostingGenerationSettingOnChangeServer();
	SetMainSelectionOfExceptionList(ExclusionList, Organization, ChartOfAccounts, PostingGenerationSetting);
	SetMainSelectionOfCorrespondenceReflectionSettings(CorrespondenceReflectionSettings, ChartOfAccounts, PostingGenerationSetting);
	
	CommonClientServer.SetDynamicListFilterItem(
		InternationalChartOfAccounts, 
		"ChartOfAccounts",
		ChartOfAccounts,
		,
		,
		True,
		DataCompositionSettingsItemViewMode.Inaccessible);
		
EndProcedure

&AtServer
Procedure PostingGenerationSettingOnChangeServer()
	
	FillInTreeOfFinancialAccountingObjects();
	
	DivisionIntoShortTermLongTermAssetsAndLiabilities = Common.ObjectAttributeValue(
		PostingGenerationSetting, "DivisionIntoShortTermLongTermAssetsAndLiabilities");
	
	Items.CorrespondenceReflectionSettingsPresentationDueDateDr.Visible = DivisionIntoShortTermLongTermAssetsAndLiabilities;
	Items.CorrespondenceReflectionSettingsPresentationDueDateCr.Visible = DivisionIntoShortTermLongTermAssetsAndLiabilities;
	
	CommonClientServer.SetDynamicListParameter(
		InternationalChartOfAccounts, 
		"PostingGenerationSetting",
		PostingGenerationSetting);
	
	FillInSetupTables();
	GetSetupStatus();
	FillInInformationOnSettings();
	SetMainSelectionOfExceptionList(ExclusionList, Organization, ChartOfAccounts, PostingGenerationSetting);
	SetMainSelectionOfCorrespondenceReflectionSettings(CorrespondenceReflectionSettings, ChartOfAccounts, PostingGenerationSetting);
	
	If Items.InternationalChartOfAccounts.CurrentRow <> Undefined Then
		GetAccountSettings(Items.InternationalChartOfAccounts.CurrentRow);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetSetupStatus()
	
	If Not ValueIsFilled(ChartOfAccounts) 
			Or Not ValueIsFilled(Organization)
			Or Not ValueIsFilled(PostingGenerationSetting) Then
		ConfigurationStatus = Undefined;
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MAX(FinancialAccountingChartsOfAccounts.Period) AS Period
	|INTO TTIsAppliedWith
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccounts
	|WHERE
	|	FinancialAccountingChartsOfAccounts.Organization = &Organization
	|	AND FinancialAccountingChartsOfAccounts.ChartOfAccounts = &ChartOfAccounts
	|	AND FinancialAccountingChartsOfAccounts.PostingGenerationSetting = &PostingGenerationSetting
	|;
	|
	|/////////////////////////////////////////////////////////////
	|SELECT
	|	AppliedFrom.Period AS PeriodFrom,
	|	MIN(ISNULL(FinancialAccountingChartsOfAccounts.Period, &DateEmpty)) AS PeriodFor
	|FROM
	|	TTIsAppliedWith AS AppliedFrom
	|	LEFT JOIN 
	|		InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccounts
	|	ON
	|		FinancialAccountingChartsOfAccounts.Organization = &Organization
	|		AND FinancialAccountingChartsOfAccounts.ChartOfAccounts = &ChartOfAccounts
	|		AND FinancialAccountingChartsOfAccounts.PostingGenerationSetting <> &PostingGenerationSetting
	|		AND FinancialAccountingChartsOfAccounts.Period >AppliedFrom.Period
	|WHERE
	|	AppliedFrom.Period <>&DateEmpty
	|
	|GROUP BY
	|	AppliedFrom.Period";
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("PostingGenerationSetting", PostingGenerationSetting);
	Query.SetParameter("DateEmpty", Date(1,1,1));
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		If ValueIsFilled(Selection.PeriodFor) Then
			Presentation = StrTemplate(NStr("vi = 'Áp dụng từ %1 đến %2';
											|ru = 'Применялась с %1 по %2';
											|en = 'Has been applied since %1 till %2'; fa = 'Has been applied since %1 till %2';
											|it = 'Applicata da %1 per %2';
											|pl = 'Było stosowane od %1 do %2';
											|tr = '%1 ile %2 arasında uygulandı'"), 
													Format(Selection.PeriodFrom, "DLF=D"), Format(Selection.PeriodFor, "DLF=D"));
			ConfigurationStatus = New FormattedString(
													Presentation, , , , "OpenHistoryBusinessAccountPlans");
		Else
			Presentation = StrTemplate(NStr("vi = 'Áp dụng từ %1';
											|ru = 'Применяется с %1';
											|en = 'Applied since %1'; fa = 'Applied since %1';
											|it = 'Si applica dal %1';
											|pl = 'Jest stosowana od %1';
											|tr = '%1 itibarıyla uygulanıyor'"), Format(Selection.PeriodFrom, "DLF=D"));
			ConfigurationStatus = New FormattedString(
													Presentation, , , , "OpenHistoryBusinessAccountPlans");
		EndIf;
		
	ElsIf AccessRight("Update", Metadata.InformationRegisters.FinancialAccountingChartsOfAccountsForCompanies) Then 
		Presentation = StrTemplate(NStr("vi = 'Bật cho doanh nghiệp từ %1';
										|ru = 'Включить для организации с %1';
										|en = 'Enable for company since %1'; fa = 'Enable for company since %1';
										|it = 'Attivare per organizzazione da %1';
										|pl = 'Włącz dla firm od %1';
										|tr = '%1 itibaren iş yeri için etkinleştir'"), Format(CurrentMonth, "DLF=D"));
		ConfigurationStatus = New FormattedString(Presentation, , StyleColors.HyperlinkColor , , "CreateBusinessAccountPlansEntry");
	Else
		Presentation = StrTemplate(NStr("vi = 'Không áp dụng cho doanh nghiệp';
										|ru = 'Не применяется для организации';
										|en = 'Not applied for the company'; fa = 'Not applied for the company';
										|it = 'Non si applica per azienda';
										|pl = 'Nie jest stosowane dla firmy';
										|tr = 'İş yerleri için uygulanmıyor'"));
		ConfigurationStatus = New FormattedString(Presentation, , StyleColors.WarningTextColor);
	EndIf;

EndProcedure

&AtClient
Procedure SelectingRecordingPeriodBusinessAccountPlans(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	CreateBusinessAccountPlansEntry(Result);
	
EndProcedure

&AtServer
Procedure CreateBusinessAccountPlansEntry(Period)
	
	RecordManager = InformationRegisters.FinancialAccountingChartsOfAccountsForCompanies.CreateRecordManager();
	RecordManager.Period = Period;
	RecordManager.ChartOfAccounts = ChartOfAccounts;
	RecordManager.Organization = Organization;
	RecordManager.PostingGenerationSetting = PostingGenerationSetting;
	RecordManager.Write();
	GetSetupStatus();
	
EndProcedure


#EndRegion

#Region SettingsForAccountingObjects

&AtServer
Procedure FillInTreeOfFinancialAccountingObjects()
	
	TreeOfFinancialAccountingObjects.GetItems().Clear();
	
	TransactionSettings = Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings(
		PostingGenerationSetting);
	
	If TransactionSettings.RevenueExcludingVAT = Undefined Then
		TransactionSettings.RevenueExcludingVAT = True;
	EndIf;
	
	AccountingSettings = FinancialAccountingByFinancialRegisterData.AccountingSettingsByTransactionGenerationSettings(
		TransactionSettings);
		
	Filter_Settings = ChartsOfCharacteristicTypes.AssetLiabilityItems.SettingsForSelectingItemsOfAssetsLiabilities();
	Filter_Settings.LedgerAccountsInEntrySettings = True;
	
	Common.FillFormDataTreeItemCollection(
		TreeOfFinancialAccountingObjects.GetItems(),
		ChartsOfCharacteristicTypes.AssetLiabilityItems.TreeOfFinancialAccountingObjects(AccountingSettings, Filter_Settings));
	
EndProcedure

&AtServer
Procedure FillInInformationOnSettings(OnlyCurAccountingObject = False)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	FinancialAccountingAccountsThatRequireSettings.AccountingObject AS AccountingObject,
	|	COUNT(DISTINCT FinancialAccountingAccountsThatRequireSettings.SettingObject1) AS Count
	|FROM
	|	InformationRegister.FinancialAccountingAccountsThatRequireSettings AS FinancialAccountingAccountsThatRequireSettings
	|WHERE
	|	FinancialAccountingAccountsThatRequireSettings.ChartOfAccounts = &ChartOfAccounts
	|	AND FinancialAccountingAccountsThatRequireSettings.PostingGenerationSetting = &PostingGenerationSetting
	|	AND (FinancialAccountingAccountsThatRequireSettings.AccountingObject = &CurrentAccountingObject OR &AllAccountingObjects) 
	|GROUP BY
	|	FinancialAccountingAccountsThatRequireSettings.AccountingObject
	|;
	|
	|///////////////////////////////////////////////////////////
	|SELECT
	|	SettingsOfFinancialAccountingAccountsByObject.AccountingObject AS AccountingObject,
	|	SUM(1) AS Count
	|FROM
	|	InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS SettingsOfFinancialAccountingAccountsByObject
	|WHERE
	|	SettingsOfFinancialAccountingAccountsByObject.ChartOfAccounts = &ChartOfAccounts
	|	AND SettingsOfFinancialAccountingAccountsByObject.PostingGenerationSetting = &PostingGenerationSetting
	|	AND SettingsOfFinancialAccountingAccountsByObject.SettingType = &SettingTypeGeneral
	|	AND (SettingsOfFinancialAccountingAccountsByObject.AccountingObject = &CurrentAccountingObject OR &AllAccountingObjects) 
	|
	|GROUP BY
	|	SettingsOfFinancialAccountingAccountsByObject.AccountingObject
	|;
	|
	|///////////////////////////////////////////////////////////
	|SELECT
	|	SettingsOfFinancialAccountingAccountsByObject.AccountingObject AS AccountingObject,
	|	SettingsOfFinancialAccountingAccountsByObject.SettingObject1 AS SettingObject1,
	|	SUM(1) AS Count
	|FROM
	|	InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS SettingsOfFinancialAccountingAccountsByObject
	|WHERE
	|	SettingsOfFinancialAccountingAccountsByObject.ChartOfAccounts = &ChartOfAccounts
	|	AND SettingsOfFinancialAccountingAccountsByObject.PostingGenerationSetting = &PostingGenerationSetting
	|	AND SettingsOfFinancialAccountingAccountsByObject.SettingType = &SettingTypeException
	|	AND (SettingsOfFinancialAccountingAccountsByObject.AccountingObject = &CurrentAccountingObject OR &AllAccountingObjects) 
	|
	|GROUP BY
	|	SettingsOfFinancialAccountingAccountsByObject.AccountingObject,
	|	SettingsOfFinancialAccountingAccountsByObject.SettingObject1
	|
	|TOTALS 
	|	SUM(Count)
	|BY
	|	AccountingObject
	|;
	|
	|///////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.AccountingObject AS AccountingObject,
	|	SUM(NestedQuery.Count) AS Count
	|FROM
	|	(SELECT
	|		SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectDr AS AccountingObject,
	|		1 AS Count
	|	FROM
	|		InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS SettingsForReflectingCorrespondenceInFinancialAccounting
	|	WHERE
	|		SettingsForReflectingCorrespondenceInFinancialAccounting.ChartOfAccounts = &ChartOfAccounts
	|		AND SettingsForReflectingCorrespondenceInFinancialAccounting.PostingGenerationSetting = &PostingGenerationSetting
	|		AND (SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectDr = &CurrentAccountingObject OR &AllAccountingObjects)
	|		AND (NOT (SettingsForReflectingCorrespondenceInFinancialAccounting.LongTermCr OR SettingsForReflectingCorrespondenceInFinancialAccounting.LongTermDr)
	|			OR SettingsForReflectingCorrespondenceInFinancialAccounting.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities)
	|		AND SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectCr <> SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectDr
	|
	|	UNION ALL
	|
	|	SELECT
	|		SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectCr AS AccountingObject,
	|		1 AS Count
	|	FROM
	|		InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS SettingsForReflectingCorrespondenceInFinancialAccounting
	|	WHERE
	|		SettingsForReflectingCorrespondenceInFinancialAccounting.ChartOfAccounts = &ChartOfAccounts
	|		AND SettingsForReflectingCorrespondenceInFinancialAccounting.PostingGenerationSetting = &PostingGenerationSetting
	|		AND (SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectCr = &CurrentAccountingObject OR &AllAccountingObjects)
	|		AND (NOT (SettingsForReflectingCorrespondenceInFinancialAccounting.LongTermCr OR SettingsForReflectingCorrespondenceInFinancialAccounting.LongTermDr)
	|			OR SettingsForReflectingCorrespondenceInFinancialAccounting.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities)
	|		AND SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectDr <> SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectCr 
	|	
	|	UNION ALL
	|
	|	SELECT
	|		SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectDr AS AccountingObject,
	|		1 AS Count
	|	FROM
	|		InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS SettingsForReflectingCorrespondenceInFinancialAccounting
	|	WHERE
	|		SettingsForReflectingCorrespondenceInFinancialAccounting.ChartOfAccounts = &ChartOfAccounts
	|		AND SettingsForReflectingCorrespondenceInFinancialAccounting.PostingGenerationSetting = &PostingGenerationSetting
	|		AND (SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectDr = &CurrentAccountingObject OR &AllAccountingObjects)
	|		AND (NOT (SettingsForReflectingCorrespondenceInFinancialAccounting.LongTermCr OR SettingsForReflectingCorrespondenceInFinancialAccounting.LongTermDr)
	|			OR SettingsForReflectingCorrespondenceInFinancialAccounting.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities)
	|		AND SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectDr = SettingsForReflectingCorrespondenceInFinancialAccounting.AccountingObjectCr) NestedQuery
	|
	|GROUP BY
	|	NestedQuery.AccountingObject
	|";
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("PostingGenerationSetting", PostingGenerationSetting);
	Query.SetParameter("SettingTypeGeneral", SettingTypeGeneralByAccountingObject);
	Query.SetParameter("SettingTypeException", SettingTypeExceptionByAccountingObject);
	Query.SetParameter("CurrentAccountingObject", CurrentAccountingObject);
	Query.SetParameter("AllAccountingObjects", Not OnlyCurAccountingObject);
	
	QueryResult = Query.ExecuteBatch();
	
	ObjectsRequireSettingUpAccountingAccounts = New Map();
	SelectionRequiresSettingUpAccountingAccounts = QueryResult[0].Select();
	While SelectionRequiresSettingUpAccountingAccounts.Next() Do
		ObjectsRequireSettingUpAccountingAccounts.Insert(SelectionRequiresSettingUpAccountingAccounts.AccountingObject, SelectionRequiresSettingUpAccountingAccounts.Count);
	EndDo;
	
	ObjectsHaveCommonSettings = New Map();
	SelectionThereAreGeneralSettings = QueryResult[1].Select();
	While SelectionThereAreGeneralSettings.Next() Do
		ObjectsHaveCommonSettings.Insert(
			SelectionThereAreGeneralSettings.AccountingObject,
			SelectionThereAreGeneralSettings.Count);
	EndDo;
	
	SamplingAndExceptionSettings = QueryResult[2].Select(QueryResultIteration.ByGroups);

	ObjectsAreSettingsForReflectingCorrespondences = New Map();
	SelectionThereAreSettingsForReflectingCorrespondence = QueryResult[3].Select();
	While SelectionThereAreSettingsForReflectingCorrespondence.Next() Do
		ObjectsAreSettingsForReflectingCorrespondences.Insert(
			SelectionThereAreSettingsForReflectingCorrespondence.AccountingObject, 
			SelectionThereAreSettingsForReflectingCorrespondence.Count);
	EndDo;
	
	If OnlyCurAccountingObject Then
		
		TreeRow = TreeOfFinancialAccountingObjects.FindByID(Items.TreeOfFinancialAccountingObjects.CurrentRow);
		YouNeedToSetUpQuantityAccountingAccounts = ObjectsRequireSettingUpAccountingAccounts.Get(TreeRow.AccountingObject) ;
		If YouNeedToSetUpQuantityAccountingAccounts  <> Undefined Then
			TreeRow.YouNeedToSetUpQuantityAccountingAccounts = YouNeedToSetUpQuantityAccountingAccounts;
		Else
			TreeRow.YouNeedToSetUpQuantityAccountingAccounts = 0;
		EndIf;
		
		GeneralSettingsQuantity = ObjectsHaveCommonSettings.Get(TreeRow.AccountingObject);
		If GeneralSettingsQuantity <> Undefined Then
			TreeRow.GeneralSettingsQuantity = GeneralSettingsQuantity;
		Else
			TreeRow.GeneralSettingsQuantity = 0;
		EndIf;
		
		SamplingAndExceptionSettings.Reset();
		If SamplingAndExceptionSettings.FindNext(New Structure("AccountingObject", TreeRow.AccountingObject)) Then
			TreeRow.ExceptionSettingsNumber = SamplingAndExceptionSettings.Count;
			
			SelectingExceptionsForConfigurationObjects = SamplingAndExceptionSettings.Select();
			NumberOfExceptionsForConfigurationObjects = New Map();
			While SelectingExceptionsForConfigurationObjects.Next() Do
				NumberOfExceptionsForConfigurationObjects.Insert(
					SelectingExceptionsForConfigurationObjects.SettingObject1,
					SelectingExceptionsForConfigurationObjects.Count);
			EndDo;
			
			For Each RowOfGeneralSettingsTable In GeneralSettingsTable Do
				NumberOfExceptions = NumberOfExceptionsForConfigurationObjects[RowOfGeneralSettingsTable.SettingObject1];
				If NumberOfExceptions = Undefined Then
					RowOfGeneralSettingsTable.Exceptions  =   NStr("vi = 'Tùy chỉnh';
																	|ru = 'Настроить';
																	|en = 'Set up'; fa = 'تنظیم';
																	|it = 'Impostare';
																	|pl = 'Set up';
																	|tr = 'Ayarla'");
					RowOfGeneralSettingsTable.NumberOfExceptions = 0;
				Else
					RowOfGeneralSettingsTable.Exceptions = StrTemplate(NStr("vi = 'Tùy chỉnh (%1)';
																			|ru = 'Настроить (%1)';
																			|en = 'Set up (%1)'; fa = 'Set up (%1)';
																			|it = 'Impostare (%1)';
																			|pl = 'Ustaw (%1)';
																			|tr = 'Ayarlama (%1)'"), NumberOfExceptions);
					RowOfGeneralSettingsTable.NumberOfExceptions = NumberOfExceptions;
				EndIf;
			EndDo; 
			
		Else
			TreeRow.ExceptionSettingsNumber = 0;
			For Each RowOfGeneralSettingsTable In GeneralSettingsTable Do
				RowOfGeneralSettingsTable.Exceptions = NStr("vi = 'Tùy chỉnh';
															|ru = 'Настроить';
															|en = 'Set up'; fa = 'تنظیم';
															|it = 'Impostare';
															|pl = 'Set up';
															|tr = 'Ayarla'");
				RowOfGeneralSettingsTable.NumberOfExceptions = 0;
			EndDo; 
		EndIf;
		
		ExceptionElement =  Items.SetupMode.ChoiceList.FindByValue(1);
		ExceptionElement.Presentation = StrTemplate(NStr("vi = 'Loại trừ (%1)';
														|ru = 'Исключения (%1)';
														|en = 'Exceptions (%1)'; fa = 'Exceptions (%1)';
														|it = 'Eccezioni (%1)';
														|pl = 'Wyjątki (%1)';
														|tr = 'İstisnalar (%1)'"), TreeRow.ExceptionSettingsNumber);
		
		CorrespondenceReflectionSettingsQuantity = ObjectsAreSettingsForReflectingCorrespondences.Get(TreeRow.AccountingObject);
		If CorrespondenceReflectionSettingsQuantity <> Undefined Then
			TreeRow.CorrespondenceReflectionSettingsQuantity = CorrespondenceReflectionSettingsQuantity;
		Else
			TreeRow.CorrespondenceReflectionSettingsQuantity = 0;
		EndIf;
		
		If TreeRow.GetParent() = Undefined Then
			UpdateTotalsForTreeGroup(TreeRow);
		Else
			UpdateTotalsForTreeGroup(TreeRow.GetParent());
		EndIf;
		
	Else
		For Each TreeGroup In TreeOfFinancialAccountingObjects.GetItems() Do
			
			For Each TreeRow In TreeGroup.GetItems() Do 
				
				YouNeedToSetUpQuantityAccountingAccounts = ObjectsRequireSettingUpAccountingAccounts.Get(TreeRow.AccountingObject) ;
				If YouNeedToSetUpQuantityAccountingAccounts  <> Undefined Then
					TreeRow.YouNeedToSetUpQuantityAccountingAccounts = YouNeedToSetUpQuantityAccountingAccounts;
				Else
					TreeRow.YouNeedToSetUpQuantityAccountingAccounts = 0;
				EndIf;
				
				GeneralSettingsQuantity = ObjectsHaveCommonSettings.Get(TreeRow.AccountingObject);
				If GeneralSettingsQuantity <> Undefined Then
					TreeRow.GeneralSettingsQuantity = GeneralSettingsQuantity;
				Else
					TreeRow.GeneralSettingsQuantity = 0;
				EndIf;
				
				SamplingAndExceptionSettings.Reset();
				If SamplingAndExceptionSettings.FindNext(New Structure("AccountingObject", TreeRow.AccountingObject)) Then
					TreeRow.ExceptionSettingsNumber = SamplingAndExceptionSettings.Count;
				Else
					TreeRow.ExceptionSettingsNumber = 0;
				EndIf;
				
				CorrespondenceReflectionSettingsQuantity = ObjectsAreSettingsForReflectingCorrespondences.Get(TreeRow.AccountingObject);
				If CorrespondenceReflectionSettingsQuantity <> Undefined Then
					TreeRow.CorrespondenceReflectionSettingsQuantity = CorrespondenceReflectionSettingsQuantity;
				Else
					TreeRow.CorrespondenceReflectionSettingsQuantity = 0;
				EndIf;
		
			EndDo;
			
			UpdateTotalsForTreeGroup(TreeGroup)
			
		EndDo;
	
	EndIf;
	
	GenerateLinkSettingUpExtdimension();
	
EndProcedure

&AtServer
Procedure UpdateTotalsForTreeGroup(TreeGroup)
	
	YouNeedToSetUpQuantityAccountingAccounts = 0;
	ExceptionSettingsNumber = 0;
	GeneralSettingsQuantity = 0;
	CorrespondenceReflectionSettingsQuantity = 0;
	
	For Each TreeRow In TreeGroup.GetItems() Do
		YouNeedToSetUpQuantityAccountingAccounts = 
			YouNeedToSetUpQuantityAccountingAccounts 
			+ TreeRow.YouNeedToSetUpQuantityAccountingAccounts;
			
		GeneralSettingsQuantity = 
			GeneralSettingsQuantity
			+ TreeRow.GeneralSettingsQuantity;
			
		ExceptionSettingsNumber = 
			ExceptionSettingsNumber
			+ TreeRow.ExceptionSettingsNumber;
			
		CorrespondenceReflectionSettingsQuantity =
			CorrespondenceReflectionSettingsQuantity
			+ TreeRow.CorrespondenceReflectionSettingsQuantity;
			
	EndDo;
	
	TreeGroup.YouNeedToSetUpQuantityAccountingAccounts = YouNeedToSetUpQuantityAccountingAccounts;
	TreeGroup.GeneralSettingsQuantity = GeneralSettingsQuantity;
	TreeGroup.ExceptionSettingsNumber = ExceptionSettingsNumber;
	TreeGroup.CorrespondenceReflectionSettingsQuantity = CorrespondenceReflectionSettingsQuantity;
	
EndProcedure

&AtServer
Procedure FillInSetupTables()
	
	GeneralSettingsTable.Clear();
	
	If Items.TreeOfFinancialAccountingObjects.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentTreeRow = TreeOfFinancialAccountingObjects.FindByID(Items.TreeOfFinancialAccountingObjects.CurrentRow);

	If CurrentTreeRow = Undefined
	 Or CurrentTreeRow.IsFolder Then
		Return;
	EndIf;
	
	Query = New Query;
	RequestTextsTTTableConfigurationObject = New Array;
	RequestTextsTTTableConfigurationObject.Add(
		"SELECT
		|	UNDEFINED AS Ref
		|INTO TTTableSettingObject
		|WHERE FALSE");
	
	If Not ValueIsFilled(CurrentTreeRow.DescriptionOfTheConfigurationObjectTypes) Then
		RequestTextsTTTableConfigurationObject.Add(
			"SELECT
			|	UNDEFINED AS Ref
			|");
	Else
		QueryText = 
			"SELECT 
			|	UNDEFINED AS Ref
			|
			|UNION ALL
			|
			|SELECT
			|	ConfigurationObjects_.Ref AS Ref
			|FROM
			|	&ConfigurationObjectTable AS ConfigurationObjects_
			|WHERE
			|	&AdditionalSelection
			|";
		TypeOfConfigurationObject = CurrentTreeRow.DescriptionOfTheConfigurationObjectTypes.Types()[0];
		MetadataConfigurationObject = Metadata.FindByType(TypeOfConfigurationObject);
		
		FullMetadataObjectName = MetadataConfigurationObject.FullName();
		QueryText = StrReplace(QueryText, "&ConfigurationObjectTable", FullMetadataObjectName);
		Query.SetParameter("EmptyRef", New (TypeOfConfigurationObject));
		
		If CurrentTreeRow.SelectingConfigurationObjects.Items.Count() > 0 Then
			AdditionalSelection = FinancialAccountingByBalanceSheetRegisterData.DataSelectionConditionString(
				CurrentTreeRow.SelectingConfigurationObjects, Query.Parameters, "ConfigurationObjects_");
			QueryText = StrReplace(QueryText, "&AdditionalSelection", AdditionalSelection);
		Else
			QueryText = StrReplace(QueryText, "&AdditionalSelection", "TRUE");
		EndIf;
	
		RequestTextsTTTableConfigurationObject.Add(QueryText);
	EndIf;
	
	QueryTextTTTableSettingObject = 
		StrConcat(RequestTextsTTTableConfigurationObject, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTextTTTableSettingObject = QueryTextTTTableSettingObject + "
		|INDEX BY
		|	Ref"; // @query-part
	
	Query.Text =
		QueryTextTTTableSettingObject
		+ Common.QueryBatchSeparator()
		+ "SELECT
		|	ConfigurationObjects_.Ref AS SettingObject1,
		|	OrderOfReflectionGeneral.GLAccount AS GLAccount,
		|	OrderOfReflectionGeneral.LedgerAccountLongTerm AS LedgerAccountLongTerm,
		|	COUNT(OrderOfReflectionOfException.GLAccount) AS NumberOfExceptions
		|INTO SettingsTable1
		|FROM
		|	TTTableSettingObject AS ConfigurationObjects_
		|	
		|	LEFT JOIN
		|		InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS OrderOfReflectionGeneral
		|	ON
		|		OrderOfReflectionGeneral.ChartOfAccounts = &ChartOfAccounts
		|		AND OrderOfReflectionGeneral.PostingGenerationSetting = &PostingGenerationSetting
		|		AND OrderOfReflectionGeneral.SettingType = &SettingTypeGeneral
		|		AND OrderOfReflectionGeneral.AccountingObject = &AccountingObject
		|		AND ConfigurationObjects_.Ref = OrderOfReflectionGeneral.SettingObject1
		|	
		|	LEFT JOIN 
		|		InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS OrderOfReflectionOfException
		|	ON
		|		OrderOfReflectionOfException.ChartOfAccounts = &ChartOfAccounts
		|		AND OrderOfReflectionOfException.PostingGenerationSetting = &PostingGenerationSetting
		|		AND OrderOfReflectionOfException.SettingType = &SettingTypeException
		|		AND OrderOfReflectionOfException.AccountingObject = &AccountingObject
		|		AND ConfigurationObjects_.Ref = OrderOfReflectionOfException.SettingObject1
		|
		|GROUP BY
		|	ConfigurationObjects_.Ref,
		|	OrderOfReflectionGeneral.GLAccount,
		|	OrderOfReflectionGeneral.LedgerAccountLongTerm
		|;
		|
		|SELECT
		|	SettingsTable1.SettingObject1 AS SettingObject1,
		|	SettingsTable1.GLAccount AS GLAccount,
		|	SettingsTable1.LedgerAccountLongTerm AS LedgerAccountLongTerm,
		|	SettingsTable1.NumberOfExceptions AS NumberOfExceptions,
		|	TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.FinancialAccountingAccountsThatRequireSettings AS FinancialAccountingAccountsThatRequireSettings
		|		WHERE
		|			FinancialAccountingAccountsThatRequireSettings.ChartOfAccounts = &ChartOfAccounts
		|			AND FinancialAccountingAccountsThatRequireSettings.PostingGenerationSetting = &PostingGenerationSetting
		|			AND FinancialAccountingAccountsThatRequireSettings.AccountingObject = &AccountingObject
		|			AND FinancialAccountingAccountsThatRequireSettings.SettingObject1 = SettingsTable1.SettingObject1
		|	) AS ConfigurationIsRequired,
		|	TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.FinancialAccountingAccountsThatRequireSettings AS FinancialAccountingAccountsThatRequireSettings
		|		WHERE
		|			FinancialAccountingAccountsThatRequireSettings.ChartOfAccounts = &ChartOfAccounts
		|			AND FinancialAccountingAccountsThatRequireSettings.PostingGenerationSetting = &PostingGenerationSetting
		|			AND FinancialAccountingAccountsThatRequireSettings.AccountingObject = &AccountingObject
		|			AND FinancialAccountingAccountsThatRequireSettings.SettingObject1 = SettingsTable1.SettingObject1
		|			AND FinancialAccountingAccountsThatRequireSettings.LongTerm
		|	) AS LongTermSetupIsRequired
		|FROM
		|	SettingsTable1 AS SettingsTable1
		|";
	
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("PostingGenerationSetting", PostingGenerationSetting);
	Query.SetParameter("SettingTypeGeneral", SettingTypeGeneralByAccountingObject);
	Query.SetParameter("SettingTypeException", SettingTypeExceptionByAccountingObject);
	Query.SetParameter("AccountingObject", CurrentTreeRow.AccountingObject);
	
	GeneralSettingsTable.Load(Query.Execute().Unload());
	For Each TableRow In GeneralSettingsTable Do
		If TableRow.NumberOfExceptions = 0 Then
			TableRow.Exceptions  =   NStr("vi = 'Tùy chỉnh';
											|ru = 'Настроить';
											|en = 'Set up'; fa = 'تنظیم';
											|it = 'Impostare';
											|pl = 'Set up';
											|tr = 'Ayarla'");
		Else
			TableRow.Exceptions = StrTemplate(NStr("vi = 'Tùy chỉnh (%1)';
													|ru = 'Настроить (%1)';
													|en = 'Set up (%1)'; fa = 'Set up (%1)';
													|it = 'Impostare (%1)';
													|pl = 'Ustaw (%1)';
													|tr = 'Ayarlama (%1)'"), TableRow.NumberOfExceptions);
		EndIf;
	EndDo;
	
	If TheCurrentConfigurationObjectWhenOpened <> Undefined Then
		RowsArray = GeneralSettingsTable.FindRows(New Structure("SettingObject1", TheCurrentConfigurationObjectWhenOpened));
		If RowsArray.Count() > 0 Then
			Items.GeneralSettingsTable.CurrentRow = RowsArray[0].GetID();
		EndIf;
		TheCurrentConfigurationObjectWhenOpened = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureFormElementsWhenAccountingObjectChanges()
	
	CurrentTreeRow = TreeOfFinancialAccountingObjects.FindByID(Items.TreeOfFinancialAccountingObjects.CurrentRow);

	ExceptionElement =  Items.SetupMode.ChoiceList.FindByValue(1);
	ExceptionElement.Presentation = StrTemplate(NStr("vi = 'Loại trừ (%1)';
													|ru = 'Исключения (%1)';
													|en = 'Exceptions (%1)'; fa = 'Exceptions (%1)';
													|it = 'Eccezioni (%1)';
													|pl = 'Wyjątki (%1)';
													|tr = 'İstisnalar (%1)'"), CurrentTreeRow.ExceptionSettingsNumber);
	
	Items.GeneralSettingsTableExceptions.Visible = ValueIsFilled(CurrentTreeRow.DescriptionOfTheConfigurationObjectTypes);
	Items.ExclusionListSettingObject1.Visible = ValueIsFilled(CurrentTreeRow.DescriptionOfTheConfigurationObjectTypes);
	
	Items.GeneralSettingsTableSettingObject1.TypeRestriction = CurrentTreeRow.DescriptionOfTheConfigurationObjectTypes;
	Items.ExclusionListSettingObject1.TypeRestriction = CurrentTreeRow.DescriptionOfTheConfigurationObjectTypes;

	TitleSettingObject = ChartsOfCharacteristicTypes.AssetLiabilityItems.ItemTitleByTypeDescription(
		CurrentTreeRow.DescriptionOfTheConfigurationObjectTypes);
	Items.GeneralSettingsTableSettingObject1.Title = TitleSettingObject;
	Items.ExclusionListSettingObject1.Title = TitleSettingObject;
	
	Items.ExclusionListPlaceOfRegistration.Visible = CurrentTreeRow.DescriptionOfTypesOfDetailedSettings.Types().Count() > 0;
	Items.ExclusionListPlaceOfRegistration.TypeRestriction = CurrentTreeRow.DescriptionOfTypesOfDetailedSettings;
	Items.ExclusionListPlaceOfRegistration.Title = ChartsOfCharacteristicTypes.AssetLiabilityItems.ItemTitleByTypeDescription(
		CurrentTreeRow.DescriptionOfTypesOfDetailedSettings);
	
	If DivisionIntoShortTermLongTermAssetsAndLiabilities
		And CurrentTreeRow.AllocationOfLongTermAssetsAndLiabilities Then
		Items.TableGeneralSettingsAccountingAccountGroup.ShowInHeader = True;
		Items.GeneralSettingsTableLedgerAccountLongTerm.Visible = True;
		Items.GeneralSettingsTableGLAccount.Title = NStr("vi = 'Ngắn hạn';
														|ru = 'Краткосрочный';
														|en = 'Short-term'; fa = 'کوتاه‌مدت';
														|it = 'A breve termine';
														|pl = 'Short-term';
														|tr = 'Kısa vadeli'");

		Items.ExclusionListAccountingAccountGroup.ShowInHeader = True;
		Items.ExclusionListLedgerAccountLongTerm.Visible = True;
		Items.ExclusionListGLAccount.Title = NStr("vi = 'Ngắn hạn';
													|ru = 'Краткосрочный';
													|en = 'Short-term'; fa = 'کوتاه‌مدت';
													|it = 'A breve termine';
													|pl = 'Short-term';
													|tr = 'Kısa vadeli'");
	Else
		Items.TableGeneralSettingsAccountingAccountGroup.ShowInHeader = False;
		Items.GeneralSettingsTableLedgerAccountLongTerm.Visible = False;
		Items.GeneralSettingsTableGLAccount.Title = "";

		Items.ExclusionListAccountingAccountGroup.ShowInHeader = False;
		Items.ExclusionListLedgerAccountLongTerm.Visible = False;
		Items.ExclusionListGLAccount.Title = "";
	EndIf;
	
	ChartsOfCharacteristicTypes.AssetLiabilityItems.InitializeSettingsComposerWithDataSource(
		SettingsComposer,
		CurrentTreeRow.DataSource,,
		UUID);
	
	GenerateLinkSettingUpExtdimension();
	
EndProcedure

&AtServer
Procedure GenerateLinkSettingUpExtdimension()
	
	FilterOfSettings = 
		DataProcessors.SettingUpFinancialAccountingAccounts.SelectingExtdimensionFillingSettings(
			ChartOfAccounts, 
			PostingGenerationSetting,
			CurrentAccountingObject);
	ExtraDimensionFillingSettings = 
		DataProcessors.SettingUpFinancialAccountingAccounts.ExtraDimensionFillingSettings(
			FilterOfSettings,
			SettingsComposer);
	
	ArrayOfAccountsWithExtdimensionFillingIssues =  
		ExtraDimensionFillingSettings.FindRows(New Structure("ThereAreExtdimensionFillingIssues", True));
	
	URL = "OpenExtdimensionFillSetting";
	If ArrayOfAccountsWithExtdimensionFillingIssues.Count() > 0 Then
		TextLink = StrTemplate(
			NStr("vi = 'Tùy chỉnh điền khoản mục (%1)';
				|ru = 'Настройка заполнения субконто (%1)';
				|en = 'Set up extra dimensions (%1)'; fa = 'Set up extra dimensions (%1)';
				|it = 'Impostazione di compilazione del subconto (%1)';
				|pl = 'Ustawienie wypełniania subkonto (%1)';
				|tr = 'Ekstra boyut doldurma ayar (%1)'"),
			ArrayOfAccountsWithExtdimensionFillingIssues.Count());
		SettingUpExtdimensionFilling = 
			New FormattedString(TextLink, , StyleColors.OverdueDataColor, , URL);
	Else
		TextLink = NStr("vi = 'Tùy chỉnh điền khoản mục';
						|ru = 'Настройка заполнения субконто';
						|en = 'Set up extra dimensions'; fa = 'تنظیم ابعاد اضافی';
						|it = 'Impostazione di compilazione del subconto';
						|pl = 'Ustawienie wypełniania subkonto';
						|tr = 'Ekstra boyut doldurma ayar'");
		SettingUpExtdimensionFilling = 
			New FormattedString(TextLink, , StyleColors.HyperlinkColor, , URL);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterYouFinishSettingUpExtdimension(Result, AdditionalParmeters) Export
	GenerateLinkSettingUpExtdimension();
EndProcedure

&AtClient
Procedure HandlerTreeOfFinancialAccountingObjectsOnActivateRow()

	CurrentData = Items.TreeOfFinancialAccountingObjects.CurrentData;
	
	If CurrentData = Undefined Then
		CurrentAccountingObject = Undefined;
		Return;
	EndIf;
	
	If CurrentData.IsFolder Then
		CurrentAccountingObject = Undefined;
		Return;
	EndIf;
	
	If CurrentData.AccountingObject = CurrentAccountingObject Then
		Return;
	EndIf;
	
	CurrentAccountingObject = CurrentData.AccountingObject;
	SetCurSettingsPageForAccountingObjects();
	WhenActivatingRowInTreeOfAccountingObjectsServer();
	
	If OptionForSelectingAccountingObjects = 1 Then
		For Each SettingString In GeneralSettingsTable Do
			If SettingString.ConfigurationIsRequired Then
				RowID = SettingString.GetID();
				Break;
			EndIf;
		EndDo;
		Items.GeneralSettingsTable.CurrentRow = RowID;
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenActivatingRowInTreeOfAccountingObjectsServer()
	
	FillInSetupTables();
	ConfigureFormElementsWhenAccountingObjectChanges();
	
	ListFilter = TMCommonUseClientServer.GetDynamicListSelection(ExclusionList);
	CommonClientServer.SetFilterItem(ListFilter, "AccountingObject", CurrentAccountingObject);
	
EndProcedure

&AtServer
Procedure ShouldSaveSettingsServer(SaveSettings_)
	
	RecordManagerReflectionOrder = InformationRegisters.SettingsOfFinancialAccountingAccountsByObject.CreateRecordManager();
	FillPropertyValues(RecordManagerReflectionOrder, SaveSettings_);
	If RecordManagerReflectionOrder.SettingType = Enums.TypesOfPostingsSettingsInFinancialAccounting.TotalByAccountingObject Then
		RecordManagerReflectionOrder.Organization = Undefined;
		RecordManagerReflectionOrder.PlaceOfRegistration = Undefined;
	ElsIf Not ValueIsFilled(RecordManagerReflectionOrder.PlaceOfRegistration) Then
		RecordManagerReflectionOrder.PlaceOfRegistration = Undefined;
	EndIf;
	If Not ValueIsFilled(RecordManagerReflectionOrder.SettingObject1) Then
		RecordManagerReflectionOrder.SettingObject1 = Undefined;
	EndIf;
	If ValueIsFilled(SaveSettings_.GLAccount)
	 Or ValueIsFilled(SaveSettings_.LedgerAccountLongTerm) Then
		RecordManagerReflectionOrder.Write();
	Else
		RecordManagerReflectionOrder.Delete();
	EndIf;
	
	FillInInformationOnSettings(True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetMainSelectionOfExceptionList(ExclusionList, Organization, ChartOfAccounts, PostingGenerationSetting)
	
	ListFilter = TMCommonUseClientServer.GetDynamicListSelection(ExclusionList);
	CommonClientServer.SetFilterItem(ListFilter, "ChartOfAccounts", ChartOfAccounts);
	CommonClientServer.SetFilterItem(ListFilter, "PostingGenerationSetting", PostingGenerationSetting);
	
	CompaniesList = New ValueList();
	CompaniesList.Add(PredefinedValue("Catalog.Companies.EmptyRef"));
	If ValueIsFilled(Organization) Then
		CompaniesList.Add(Organization);
	EndIf;
	CommonClientServer.SetFilterItem(ListFilter, "Organization", CompaniesList, , , ValueIsFilled(Organization));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetMainSelectionOfCorrespondenceReflectionSettings(ListOfCorrespondenceReflectionSettings, ChartOfAccounts, PostingGenerationSetting)
	
	ListFilter = TMCommonUseClientServer.GetDynamicListSelection(ListOfCorrespondenceReflectionSettings);
	CommonClientServer.SetFilterItem(ListFilter, "ChartOfAccounts", ChartOfAccounts);
	CommonClientServer.SetFilterItem(ListFilter, "PostingGenerationSetting", PostingGenerationSetting);
	
EndProcedure

&AtClient
Procedure ConfigureFormWhenChangingConfigurationMode()
	If SetupMode = 1 Then
		NameOfTheSettingsPage = Items.ExceptionsPage.Name;
		NameOfTheCommandPanelPage = Items.TheExceptionsCommandPanelPage.Name;
	Else
		NameOfTheSettingsPage = Items.GeneralSettingsPage.Name;
		NameOfTheCommandPanelPage = Items.TheCommandPanelGeneralSettingsPage.Name;
	EndIf;
	SetCurSettingsPageForAccountingObjects();
EndProcedure

&AtClient
Procedure SetSelectionOfExceptionsForConfigurationObject(SettingObject1)
	
	SelectionObjectSettingsValue = SettingObject1;
	
	ListFilter = TMCommonUseClientServer.GetDynamicListSelection(ExclusionList);
	CommonClientServer.SetFilterItem(
		ListFilter,
		"SettingObject1", 
		SelectionObjectSettingsValue);
	
	If ValueIsFilled(SettingObject1) Then
		StringSelection_ = StrTemplate("%1: %2", Items.ExclusionListSettingObject1.Title, SelectionObjectSettingsValue);
	Else
		StringSelection_ = StrTemplate(NStr("vi = '%1: Chưa chỉ ra';
											|ru = '%1: Не указана';
											|en = '%1: Not specified'; fa = '%1: Not specified';
											|it = '%1: Non specificato';
											|pl = '%1: Nie określono';
											|tr = '%1: Belirtilmedi'"), Items.ExclusionListSettingObject1.Title);
	EndIf;
	
	FilterSettingObject1Presentation = StringFunctionsClient.FormattedString(
		"%1 <a href=""ClearSelectionByConfigurationObject""><img src='ClearFilter9x9'></a>", StringSelection_);
	Items.FilterSettingObject1Presentation.Visible = True;
	
EndProcedure

&AtClient
Procedure ClearSelectionOfListOfExceptionsForConfigurationObject()
	SelectionObjectSettingsValue = Undefined;
	ListFilter = TMCommonUseClientServer.GetDynamicListSelection(ExclusionList);
	CommonClientServer.DeleteFilterItems(ListFilter, "SettingObject1");
	FilterSettingObject1Presentation = "";
	Items.FilterSettingObject1Presentation.Visible = False;
EndProcedure

&AtClient
Procedure OpenExceptionEntryForm(Filter, NewRecord = False)
	
	FormParameters = New Structure;
	If NewRecord Then
		FormParameters.Insert("FillingValues", Filter);
	Else
		ArrayFilter = New Array;
		ArrayFilter.Add(Filter);
		RecordKey = New("InformationRegisterRecordKey.SettingsOfFinancialAccountingAccountsByObject", ArrayFilter);
		FormParameters.Insert("Key", RecordKey);
	EndIf;
	
	FormParameters.Insert("DoNotChangeTheSettingType", True);
	FormParameters.Insert("DoNotChangeTheAccountingObject", True);
	OpenForm("InformationRegister.SettingsOfFinancialAccountingAccountsByObject.Form.RecordForm", 
			FormParameters, ThisObject,, , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Function SelectingInvoiceSettingsForAccountingItem(AccountingObject, SettingObject1, SettingType)

	Filter = New Structure;
	Filter.Insert("ChartOfAccounts", ChartOfAccounts);
	Filter.Insert("PostingGenerationSetting", PostingGenerationSetting);
	Filter.Insert("SettingType", SettingType);
	Filter.Insert("AccountingObject", AccountingObject);
	Filter.Insert("SettingObject1", SettingObject1);
	Filter.Insert("Organization");
	Filter.Insert("PlaceOfRegistration");
	Return Filter;
	
EndFunction

&AtClient
Function FilterCorrespondenceSettings()

	Filter = New Structure;
	Filter.Insert("ChartOfAccounts", ChartOfAccounts);
	Filter.Insert("PostingGenerationSetting", PostingGenerationSetting);
	Filter.Insert("AccountingObjectDr");
	Filter.Insert("AccountingObjectCr");
	Filter.Insert("LongTermDr");
	Filter.Insert("LongTermCr");
	Filter.Insert("ApplicationProcedure");
	Return Filter;
	
EndFunction

&AtClient
Procedure RecordGeneralSettingsAccount(CurrentData)
	
	SaveSettings_ = New Structure;
	SaveSettings_.Insert("ChartOfAccounts", ChartOfAccounts);
	SaveSettings_.Insert("PostingGenerationSetting", PostingGenerationSetting);
	SaveSettings_.Insert("SettingType", SettingTypeGeneralByAccountingObject);
	SaveSettings_.Insert("AccountingObject", CurrentAccountingObject);
	SaveSettings_.Insert("SettingObject1", CurrentData.SettingObject1);
	SaveSettings_.Insert("Organization", Undefined);
	SaveSettings_.Insert("PlaceOfRegistration", Undefined);
	SaveSettings_.Insert("GLAccount", CurrentData.GLAccount);
	SaveSettings_.Insert("ConfigurationIsRequired", CurrentData.ConfigurationIsRequired);
	SaveSettings_.Insert("LedgerAccountLongTerm", CurrentData.LedgerAccountLongTerm);
	
	ShouldSaveSettingsServer(SaveSettings_);
	
EndProcedure


&AtClient
Procedure WhenYouFinishSelectingAccountingAccountToFillIn(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	FillInAccountForGeneralSettingsOnServer(Result, AdditionalParameters.SelectedRows);
	
EndProcedure

&AtServer
Procedure FillInAccountForGeneralSettingsOnServer(GLAccount, SelectedRows)
	
	For Each RowID In SelectedRows Do
		
		RowData = GeneralSettingsTable.FindByID(RowID);
		RowData.GLAccount = GLAccount;
	
		SaveSettings_ = New Structure;
		SaveSettings_.Insert("ChartOfAccounts", ChartOfAccounts);
		SaveSettings_.Insert("PostingGenerationSetting", PostingGenerationSetting);
		SaveSettings_.Insert("SettingType", Enums.TypesOfPostingsSettingsInFinancialAccounting.TotalByAccountingObject);
		SaveSettings_.Insert("AccountingObject", CurrentAccountingObject);
		SaveSettings_.Insert("SettingObject1", RowData.SettingObject1);
		SaveSettings_.Insert("Organization", Undefined);
		SaveSettings_.Insert("PlaceOfRegistration", Undefined);
		SaveSettings_.Insert("GLAccount", RowData.GLAccount);
		SaveSettings_.Insert("ConfigurationIsRequired", RowData.ConfigurationIsRequired);
		SaveSettings_.Insert("LedgerAccountLongTerm", RowData.LedgerAccountLongTerm);
		
		ShouldSaveSettingsServer(SaveSettings_);
	EndDo;
		
EndProcedure

&AtClient
Procedure SetCurSettingsPageForAccountingObjects()
	
	If Not ValueIsFilled(ChartOfAccounts) Or Not ValueIsFilled(PostingGenerationSetting) Then
		CurSettingsPage = Items.SetupPagesByAccountingObjectsNoSetupSelected;
		CurPageOfConfigurationCommandPanel = Items.TheCommandPanelPageIsEmpty;
	ElsIf Items.TreeOfFinancialAccountingObjects.CurrentData <> Undefined
		And Items.TreeOfFinancialAccountingObjects.CurrentData.IsFolder Then
		CurSettingsPage = Items.PageSettingsForAccountingObjectsSelectedGroup;
		CurPageOfConfigurationCommandPanel = Items.TheCommandPanelPageIsEmpty;
	ElsIf NameOfTheSettingsPage <> "" Then
			CurSettingsPage = Items[NameOfTheSettingsPage];
			CurPageOfConfigurationCommandPanel = Items[NameOfTheCommandPanelPage];
		Else
			CurSettingsPage = Items.GeneralSettingsPage;
			CurPageOfConfigurationCommandPanel = Items.TheCommandPanelGeneralSettingsPage;
		EndIf;
		
		If Items.ConfigurationPagesForAccountingObjects.CurrentPage <> CurSettingsPage Then
			Items.ConfigurationPagesForAccountingObjects.CurrentPage = CurSettingsPage;
			Items.PagesCommandPanelsSettings.CurrentPage = CurPageOfConfigurationCommandPanel;
		EndIf;
		
EndProcedure

#EndRegion

#Region CorrespondenceSettings_

&AtServerNoContext
Procedure FillInPresentationOfTermsInList(LinesInSettingsList, DescriptionOfAccountingObjects, CacheOfAccountingObjects, DrCr)
	
	For Each ListLine In LinesInSettingsList Do
		RowData = ListLine.Value.Data;
		FillInPresentationOfDueDateInLine(RowData, DescriptionOfAccountingObjects, CacheOfAccountingObjects, DrCr);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetCurPageOfCorrespondenceSettings()
		
		If Not ValueIsFilled(ChartOfAccounts) Or Not ValueIsFilled(PostingGenerationSetting) Then
			CurSettingsPage = Items.TheCorrespondenceReflectionSettingsPageIsNotSelected;
		ElsIf (Items.TreeOfFinancialAccountingObjectsByCorrespondence.CurrentData <> Undefined
				And Items.TreeOfFinancialAccountingObjectsByCorrespondence.CurrentData.IsFolder)
				And ModeForViewingCorrespondenceReflectionSettings = "SelectingAccountingItems" Then
		CurSettingsPage = Items.TheCorrespondenceReflectionSettingsPageGroupSelected;
	Else
		CurSettingsPage = Items.CorrespondenceReflectionSettingsPage;
	EndIf;
	
	If Items.CorrespondenceReflectionSettingsPages.CurrentPage <> CurSettingsPage Then
		Items.CorrespondenceReflectionSettingsPages.CurrentPage = CurSettingsPage;
	EndIf;
	
EndProcedure

&AtClient
Procedure HandlerTreeOfFinancialAccountingObjectsByCorrespondenceOnActivateRow()

	CurrentData = Items.TreeOfFinancialAccountingObjectsByCorrespondence.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.AccountingObject = CurrentAccountingObject Then
		Return;
	EndIf;
	
	If CurrentData.IsFolder Then
		Return;
	EndIf;
	
	CurrentAccountingObject = CurrentData.AccountingObject;
	CommonClientServer.SetDynamicListParameter(CorrespondenceReflectionSettings, "CurrentAccountingObject", CurrentAccountingObject);
	SetCurPageOfCorrespondenceSettings();
	
EndProcedure

&AtClient
Procedure Open_SettingsForm(AccountSettingsLine)

	RowData = SettingsByAccount.FindByID(AccountSettingsLine);
	
	If RowData.SettingType = PredefinedValue("Enum.TypesOfPostingsSettingsInFinancialAccounting.ByCorrespondence") Then
		
		Filter = FilterCorrespondenceSettings();
		FillPropertyValues(Filter, RowData);
		
		FormParameters = New Structure;
		ArrayFilter = New Array;
		ArrayFilter.Add(Filter);
		RecordKey = New("InformationRegisterRecordKey.SettingsForReflectingCorrespondenceInFinancialAccounting", ArrayFilter);
		FormParameters.Insert("Key", RecordKey);
		OpenForm("InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting.Form.RecordForm", 
				FormParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		Filter = SelectingInvoiceSettingsForAccountingItem(RowData.AccountingObject, RowData.SettingObject1, RowData.SettingType);
		FillPropertyValues(Filter, RowData);
		
		FormParameters = New Structure;
		ArrayFilter = New Array;
		ArrayFilter.Add(Filter);
		RecordKey = New("InformationRegisterRecordKey.SettingsOfFinancialAccountingAccountsByObject", ArrayFilter);
		FormParameters.Insert("Key", RecordKey);
	
		OpenForm("InformationRegister.SettingsOfFinancialAccountingAccountsByObject.RecordForm", 
				FormParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			
	EndIf;
EndProcedure

#EndRegion

#Region ViewingAccountPlanSettings

&AtClient
Procedure ChartOfAccountsHandlerIsActiveWhenRowIsActivated()
	
	CurrentData = Items.InternationalChartOfAccounts.CurrentData;
	If CurrentData = Undefined Then
		SettingsByAccount.Clear();
	Else
		GetAccountSettings(Items.InternationalChartOfAccounts.CurrentRow);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetAccountSettings(GLAccount)
	
	SettingsByAccount.Clear();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Settings.SettingType AS SettingType,
	|	Settings.AccountingObject AS AccountingObject,
	|	FALSE AS LongTerm,
	|	&AlignDrCr AS Align,
	|	Settings.SettingObject1  AS SettingObject1,
	|	Settings.Organization  AS Organization,
	|	Settings.PlaceOfRegistration  AS PlaceOfRegistration
	|FROM
	|	InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS Settings
	|WHERE
	|	Settings.ChartOfAccounts = &ChartOfAccounts
	|	AND Settings.PostingGenerationSetting = &PostingGenerationSetting
	|	AND Settings.GLAccount = &GLAccount
	|
	|UNION ALL
	|
	|SELECT
	|	Settings.SettingType AS SettingType,
	|	Settings.AccountingObject AS AccountingObject,
	|	TRUE AS LongTerm,
	|	&AlignDrCr AS Align,
	|	Settings.SettingObject1  AS SettingObject1,
	|	Settings.Organization  AS Organization,
	|	Settings.PlaceOfRegistration  AS PlaceOfRegistration
	|FROM
	|	InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS Settings
	|WHERE
	|	Settings.ChartOfAccounts = &ChartOfAccounts
	|	AND Settings.PostingGenerationSetting = &PostingGenerationSetting
	|	AND Settings.LedgerAccountLongTerm = &GLAccount
	|	AND Settings.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities
	|;
	|
	|////////////////////////////////////
	|SELECT
	|	VALUE(Enum.TypesOfPostingsSettingsInFinancialAccounting.ByCorrespondence) AS SettingType,
	|	Settings.AccountingObjectDr AS AccountingObjectDr,
	|	Settings.AccountingObjectCr AS AccountingObjectCr,
	|	Settings.LongTermDr AS LongTermDr,
	|	Settings.LongTermCr AS LongTermCr,
	|	CASE 
	|		WHEN Settings.GLAccountDr = &GLAccount AND Settings.GLAccountCr = &GLAccount
	|			THEN &AlignDrCr
	|		ELSE &AlignDr
	|	END AS Align,
	|	Settings.ApplicationProcedure AS ApplicationProcedure,
	|	Settings.ThereIsAdditionalSelectionDr AS ThereIsAdditionalSelectionDr,
	|	Settings.ThereIsAdditionalSelectionCr AS ThereIsAdditionalSelectionCr,
	|	CAST(Settings.LongDesc AS STRING(1000)) AS LongDesc
	|FROM
	|	InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS Settings
	|WHERE
	|	Settings.ChartOfAccounts = &ChartOfAccounts
	|	AND Settings.PostingGenerationSetting = &PostingGenerationSetting
	|	AND Settings.GLAccountDr = &GLAccount
	|	AND NOT Settings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|	AND (NOT (Settings.LongTermCr OR Settings.LongTermDr)
	|		OR Settings.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.TypesOfPostingsSettingsInFinancialAccounting.ByCorrespondence) AS SettingType,
	|	Settings.AccountingObjectDr AS AccountingObjectDr,
	|	Settings.AccountingObjectCr AS AccountingObjectCr,
	|	Settings.LongTermDr AS LongTermDr,
	|	Settings.LongTermCr AS LongTermCr,
	|	&AlignCr AS Align,
	|	Settings.ApplicationProcedure AS ApplicationProcedure,
	|	Settings.ThereIsAdditionalSelectionDr AS ThereIsAdditionalSelectionDr,
	|	Settings.ThereIsAdditionalSelectionCr AS ThereIsAdditionalSelectionCr,
	|	CAST(Settings.LongDesc AS STRING(1000)) AS LongDesc
	|FROM
	|	InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS Settings
	|WHERE
	|	Settings.ChartOfAccounts = &ChartOfAccounts
	|	AND Settings.PostingGenerationSetting = &PostingGenerationSetting
	|	AND Settings.GLAccountCr = &GLAccount
	|	AND NOT Settings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|	AND NOT Settings.GLAccountDr = &GLAccount
	|	AND (NOT (Settings.LongTermCr OR Settings.LongTermDr)
	|		OR Settings.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VALUE(Enum.TypesOfPostingsSettingsInFinancialAccounting.ByCorrespondence) AS SettingType,
	|	Settings.AccountingObjectDr AS AccountingObjectDr,
	|	Settings.AccountingObjectCr AS AccountingObjectCr,
	|	Settings.LongTermDr AS LongTermDr,
	|	Settings.LongTermCr AS LongTermCr,
	|	&AlignDr AS Align,
	|	Settings.ApplicationProcedure AS ApplicationProcedure,
	|	Settings.ThereIsAdditionalSelectionDr AS ThereIsAdditionalSelectionDr,
	|	Settings.ThereIsAdditionalSelectionCr AS ThereIsAdditionalSelectionCr,
	|	CAST(Settings.LongDesc AS STRING(1000)) AS LongDesc
	|FROM
	|	InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS Settings
	|	INNER JOIN InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS SettingsByObjects
	|		ON Settings.ChartOfAccounts = SettingsByObjects.ChartOfAccounts
	|		 AND Settings.PostingGenerationSetting = SettingsByObjects.PostingGenerationSetting
	|		 AND Settings.AccountingObjectDr = SettingsByObjects.AccountingObject
	|		 AND Settings.LedgerAccountIsDeterminedByAccountingObjectSetupDr
	|WHERE
	|	Settings.ChartOfAccounts = &ChartOfAccounts
	|	AND Settings.PostingGenerationSetting = &PostingGenerationSetting
	|	AND ((SettingsByObjects.GLAccount = &GLAccount AND NOT Settings.LongTermDr)
	|		OR (SettingsByObjects.LedgerAccountLongTerm = &GLAccount AND Settings.LongTermDr
	|			AND SettingsByObjects.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VALUE(Enum.TypesOfPostingsSettingsInFinancialAccounting.ByCorrespondence) AS SettingType,
	|	Settings.AccountingObjectDr AS AccountingObjectDr,
	|	Settings.AccountingObjectCr AS AccountingObjectCr,
	|	Settings.LongTermDr AS LongTermDr,
	|	Settings.LongTermCr AS LongTermCr,
	|	&AlignCr AS Align,
	|	Settings.ApplicationProcedure AS ApplicationProcedure,
	|	Settings.ThereIsAdditionalSelectionDr AS ThereIsAdditionalSelectionDr,
	|	Settings.ThereIsAdditionalSelectionCr AS ThereIsAdditionalSelectionCr,
	|	CAST(Settings.LongDesc AS STRING(1000)) AS LongDesc
	|FROM
	|	InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting AS Settings
	|	INNER JOIN InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS SettingsByObjects
	|		ON Settings.ChartOfAccounts = SettingsByObjects.ChartOfAccounts
	|		 AND Settings.PostingGenerationSetting = SettingsByObjects.PostingGenerationSetting
	|		 AND Settings.AccountingObjectCr = SettingsByObjects.AccountingObject
	|		 AND Settings.LedgerAccountIsDeterminedByAccountingObjectSetupCr
	|WHERE
	|	Settings.ChartOfAccounts = &ChartOfAccounts
	|	AND Settings.PostingGenerationSetting = &PostingGenerationSetting
	|	AND ((SettingsByObjects.GLAccount = &GLAccount AND NOT Settings.LongTermCr)
	|		OR (SettingsByObjects.LedgerAccountLongTerm = &GLAccount AND Settings.LongTermCr
	|			AND SettingsByObjects.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities))
	|";
	Query.SetParameter("GLAccount", GLAccount);
	Query.SetParameter("AlignDrCr", NStr("vi = 'Nợ/Có';
										|ru = 'Дт/Кт';
										|en = 'Dr/Cr'; fa = 'بد/بس';
										|it = 'Debito/Credito';
										|pl = 'Dr/Cr';
										|tr = 'Borç/Alacak'"));
	Query.SetParameter("AlignDr", NStr("vi = 'Nợ';
										|ru = 'Дт';
										|en = 'Dr'; fa = 'بد';
										|it = 'Debito';
										|pl = 'Wn';
										|tr = 'Borç'"));
	Query.SetParameter("AlignCr", NStr("vi = 'Có';
										|ru = 'Кт';
										|en = 'Cr'; fa = 'بس';
										|it = 'Credito';
										|pl = 'Ma';
										|tr = 'Alacak'"));
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("PostingGenerationSetting", PostingGenerationSetting);
	
	QueryResults = Query.ExecuteBatch();
	SelectingSettingsForAccountingObjects = QueryResults[0].Select();
	SelectionOfSettingsByCorrespondence = QueryResults[1].Select();
	
	DescriptionOfAccountingObjects = FormAttributeToValue("TreeOfFinancialAccountingObjects");
	CacheOfAccountingObjects = New Map();
	
	While SelectionOfSettingsByCorrespondence.Next() Do
		NewRow = SettingsByAccount.Add();
		FillPropertyValues(NewRow, SelectionOfSettingsByCorrespondence);
		If DivisionIntoShortTermLongTermAssetsAndLiabilities Then
			FillInPresentationOfDueDateInLine(NewRow, DescriptionOfAccountingObjects, CacheOfAccountingObjects, "Dr");
			FillInPresentationOfDueDateInLine(NewRow, DescriptionOfAccountingObjects, CacheOfAccountingObjects, "Cr");
		EndIf;	
	EndDo;
	
	While SelectingSettingsForAccountingObjects.Next() Do
		If DescriptionOfAccountingObjects.Rows.Find(SelectingSettingsForAccountingObjects.AccountingObject, "AccountingObject", True) <> Undefined Then
			NewRow = SettingsByAccount.Add();
			FillPropertyValues(NewRow, SelectingSettingsForAccountingObjects);
			If DivisionIntoShortTermLongTermAssetsAndLiabilities Then
				FillInPresentationOfDueDateInLine(NewRow, DescriptionOfAccountingObjects, CacheOfAccountingObjects, "");
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure FillInPresentationOfDueDateInLine(SettingsString, DescriptionOfAccountingObjects, CacheOfAccountingObjects, DrCr)
	
	AllocationOfLongTermAssetsAndLiabilities = CacheOfAccountingObjects[SettingsString["AccountingObject" + DrCr]];
	
	If AllocationOfLongTermAssetsAndLiabilities = Undefined Then
		If TypeOf(DescriptionOfAccountingObjects) = Type("ValueTree") Then
			DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Rows.Find(SettingsString["AccountingObject" + DrCr], "AccountingObject", True);
		Else
			DescriptionOfAccountingObject_ = DescriptionOfAccountingObjects.Find(SettingsString["AccountingObject" + DrCr], "AccountingObject");
		EndIf;
		If DescriptionOfAccountingObject_ = Undefined Then
			AllocationOfLongTermAssetsAndLiabilities = False;
		Else
			AllocationOfLongTermAssetsAndLiabilities = DescriptionOfAccountingObject_.AllocationOfLongTermAssetsAndLiabilities;
		EndIf;
		CacheOfAccountingObjects.Insert(SettingsString["AccountingObject" + DrCr], AllocationOfLongTermAssetsAndLiabilities);
	EndIf;
	
	If Not AllocationOfLongTermAssetsAndLiabilities Then
		SettingsString["PresentationDueDate" + DrCr] = "";
	ElsIf SettingsString["LongTerm" + DrCr] Then
		SettingsString["PresentationDueDate" + DrCr] = NStr("vi = 'Dài hạn';
															|ru = 'Долгосрочный';
															|en = 'Long-term'; fa = 'بلندمدت';
															|it = 'A lungo termine';
															|pl = 'Długoterminowy';
															|tr = 'Uzun vadeli'");
	Else
		SettingsString["PresentationDueDate" + DrCr] = NStr("vi = 'Ngắn hạn';
															|ru = 'Краткосрочный';
															|en = 'Short-term'; fa = 'کوتاه‌مدت';
															|it = 'A breve termine';
															|pl = 'Krótkoterminowy';
															|tr = 'Kısa vadeli'");
	EndIf;	
	
EndProcedure

#EndRegion

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ChartOfAccounts = Parameters.ChartOfAccounts;
	Organization = Parameters.Organization;
	
	CurrentDate = CurrentSessionDate();
	
	ConfigurePostingsForBusinessTransactions = GetFunctionalOption("ConfigurePostingsForBusinessTransactions");
	SettingOfPostingByAccountingObjects = GetFunctionalOption("SettingOfPostingByAccountingObjects");
	GenerateFinancialAccountingEntriesByLocalAccountingData = GetFunctionalOption("GenerateFinancialAccountingEntriesByLocalAccountingData");
	
	InitializeConfigurationTable();
	FillInTransactionGenerationSettings();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SettingUpInternationalAccountingAccountsCompleted"
		Or EventName = "CompletedConfigurationOfInternationalAccountingTransactionTemplates"
		Or EventName = "AdjustmentOfComplianceOfAccountsAndTurnsOfInternationalAccountingIsFinished"
		Or EventName = "Write_FinancialAccountingChartsOfAccountsForCompanies"
		Or	EventName = "ClosedListForms_PlansOfAccountsForInternationalAccountingOfOrganizations"
		Or EventName = "ClosedSettingsForm" Then
		FillInTransactionGenerationSettings();
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

	&AtClient
Procedure ChartOfAccountsOnChange(Item)
	
	ChartOfAccountsWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure BusinessAccountPlansSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentItemName = Field.Name;
	If StrFind(CurrentItemName, "SettingUsed_") <> 0 Then
		
		CurrentData = Items.BusinessAccountPlans.CurrentData;
		
		FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
		FormParameters.Organization = CurrentData.Organization;
		LinesAccountPlans = FinancialAccountingChartsOfAccounts.FindRows(
								New Structure("TheNameOfThePropSettingIsUsed", CurrentItemName));
		LineOfAccountPlans = LinesAccountPlans[0];
		FormParameters.ChartOfAccounts = LineOfAccountPlans.Ref;
		FormParameters.PostingGenerationSetting = CurrentData[LineOfAccountPlans.AttributeNameSetting];
		
		If ConfigurePostingsForBusinessTransactions Then
			FinancialAccountingUponOperationalAccountingDataClient.OpenSettingsForTransactionTemplates(FormParameters, ThisObject);
		ElsIf SettingOfPostingByAccountingObjects Then
			FinancialAccountingByFinancialRegisterDataClient.OpenInvoiceSettingsForAccountingObjects(FormParameters, ThisObject);
		ElsIf GenerateFinancialAccountingEntriesByLocalAccountingData Then
			FinancialAccountingUponLocalAccountingClient.OpenAccountsAndTurnoverMatchingSettings(FormParameters, ThisObject);
		EndIf;
		
	EndIf;
	
EndProcedure


// Parameters:
// 	Item - FormField -
&AtClient
Procedure Attachable_FlagOnChange(Item) 
	
	CurrentData = Items.BusinessAccountPlans.CurrentData;
	
	If CurrentData[Item.Name] Then
	
		FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
		FormParameters.Organization = CurrentData.Organization;
		
		LinesAccountPlans = FinancialAccountingChartsOfAccounts.FindRows(New Structure("AttributeNameFlag", Item.Name));
		LineOfAccountPlans = LinesAccountPlans[0];
		FormParameters.ChartOfAccounts = LinesAccountPlans[0].Ref;
		FormParameters.PostingGenerationSetting = CurrentData[LineOfAccountPlans.AttributeNameSetting];
		
		If ConfigurePostingsForBusinessTransactions Then
			FinancialAccountingUponOperationalAccountingDataClient.OpenSettingsForTransactionTemplates(FormParameters, ThisObject);
		ElsIf SettingOfPostingByAccountingObjects Then
			FinancialAccountingByFinancialRegisterDataClient.OpenInvoiceSettingsForAccountingObjects(FormParameters, ThisObject);
		ElsIf GenerateFinancialAccountingEntriesByLocalAccountingData Then
			FinancialAccountingUponLocalAccountingClient.OpenAccountsAndTurnoverMatchingSettings(FormParameters, ThisObject);
		EndIf;
		
	Else
		
		LinesAccountPlans = FinancialAccountingChartsOfAccounts.FindRows(New Structure("AttributeNameFlag", Item.Name));
		LineOfAccountPlans = LinesAccountPlans[0];
		If ValueIsFilled(CurrentData[LineOfAccountPlans.AttributeNameSetting]) Then
			
			Organization = CurrentData.Organization;
			SelectedChartOfAccounts = LineOfAccountPlans.Ref;
			
			AdditionalParameters = New Structure();
			AdditionalParameters.Insert("Organization", Organization);
			AdditionalParameters.Insert("ChartOfAccounts", SelectedChartOfAccounts);
			AdditionalParameters.Insert("RowID", CurrentData.GetID());
			AdditionalParameters.Insert("AttributeNameFlag", LineOfAccountPlans.AttributeNameFlag);
			AdditionalParameters.Insert("AttributeNameSetting", LineOfAccountPlans.AttributeNameSetting);
			AdditionalParameters.Insert("AttributeNameSettingNotUsed", LineOfAccountPlans.AttributeNameSettingNotUsed);
			AdditionalParameters.Insert("TheNameOfThePropSettingIsUsed", LineOfAccountPlans.TheNameOfThePropSettingIsUsed);
				
			CallbackDescription = New CallbackDescription("WhenAnsweringQuestionAboutDisablingTransactionGeneration", ThisObject, AdditionalParameters);
			QueryText = 
				StrTemplate(NStr("vi = 'Sẽ ngắt tạo bút toán theo doanh nghiệp ""%1"" trong hệ thống tài khoản ""%2"". Tiếp tục?';
								|ru = 'Будет отключено формирование проводок по организации ""%1"" на плане счетов ""%2"". Продолжить?';
								|en = 'Generation of entries for company ""%1"" based on chart of accounts ""%2"" will be disabled. Continue?'; fa = 'Generation of entries for company ""%1"" based on chart of accounts ""%2"" will be disabled. Continue?';
								|it = 'Sarà disattivata la creazione di transazioni per l''organizzazione ""%1"" nel piano dei conti ""%2"". Continuare?';
								|pl = 'Zostanie odłączono tworzenie rejestracji wg firmy ""%1"" na planie kont ""%2"". Kontynuować?';
								|tr = '""%2"" hesap planında ""%1"" iş yeri için hareket oluşturma devre dışı bırakılacak. Devam edilsin mi?'"),
					Organization,
					SelectedChartOfAccounts);
			
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	For Each ChartOfAccountsLine In FinancialAccountingChartsOfAccounts Do
		
		Item = ConditionalAppearance.Items.Add();
		
		FormField = Items[ChartOfAccountsLine.AttributeNameSettingNotUsed]; // FormField - 
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FormField.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessAccountPlans." + ChartOfAccountsLine.AttributeNameFlag);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;

		Item.Appearance.SetParameterValue("Visible", False);

		EmptySetting = New ValueList();
		EmptySetting.Add(Undefined);
		EmptySetting.Add(Catalogs.FinancialAccountingPostingGenerationSetting.EmptyRef());
		
		Item = ConditionalAppearance.Items.Add();
		
		FormField = Items[ChartOfAccountsLine.AttributeNameSettingNotUsed]; // FormField - 
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FormField.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessAccountPlans." + ChartOfAccountsLine.AttributeNameFlag);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessAccountPlans." + ChartOfAccountsLine.AttributeNameSetting);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
		ItemFilter.RightValue = EmptySetting;

		Item.Appearance.SetParameterValue("Visible", False);
		
		//
		Item = ConditionalAppearance.Items.Add();
		
		FormField = Items[ChartOfAccountsLine.AttributeNameSettingNotUsed]; // FormField - 
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FormField.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessAccountPlans." + ChartOfAccountsLine.AttributeNameFlag);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessAccountPlans." + ChartOfAccountsLine.AttributeNameSetting);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Undefined;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không sử dụng ';
														|ru = 'Не используется';
														|en = 'Not used'; fa = 'استفاده نمی‌شود';
														|it = 'Non viene utilizzato';
														|pl = 'Nie używane';
														|tr = 'Kullanılmaz'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("ReadOnly", True);
		Item.Appearance.SetParameterValue("Visible", True);

		//
		Item = ConditionalAppearance.Items.Add();
		
		FormField = Items[ChartOfAccountsLine.AttributeNameSettingNotUsed]; // FormField - 
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FormField.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessAccountPlans." + ChartOfAccountsLine.AttributeNameFlag);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessAccountPlans." + ChartOfAccountsLine.AttributeNameSetting);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Catalogs.FinancialAccountingPostingGenerationSetting.EmptyRef();;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("ReadOnly", True);
		Item.Appearance.SetParameterValue("Visible", True);
		
		//
		
		
		Item = ConditionalAppearance.Items.Add();
		
		FormField = Items[ChartOfAccountsLine.TheNameOfThePropSettingIsUsed]; // FormField - 
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FormField.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessAccountPlans." + ChartOfAccountsLine.AttributeNameFlag);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("BusinessAccountPlans." + ChartOfAccountsLine.AttributeNameSetting);
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = EmptySetting;
		
		Item.Appearance.SetParameterValue("Visible", False);
	
	EndDo;
	
EndProcedure

&AtClient
Procedure ChangeHistory(Command)
	
	CurrentCompany = Items.BusinessAccountPlans.CurrentData.Organization;
	DedicatedChartOfAccounts = Undefined;
	SelectingAndSearchingForChartOfAccounts = New Structure();
	SelectingAndSearchingForChartOfAccounts.Insert("AttributeNameSetting", "Setting_" + Right(Items.BusinessAccountPlans.CurrentItem.Name, 1));
	FoundChartOfAccounts = FinancialAccountingChartsOfAccounts.FindRows(SelectingAndSearchingForChartOfAccounts);
	If FoundChartOfAccounts.Count() Then
		DedicatedChartOfAccounts = FoundChartOfAccounts[0].Ref;
	EndIf;
	
	If ValueIsFilled(CurrentCompany) Then
		FormParameters = New Structure();
		Filter = New Structure("Organization", CurrentCompany);
		If ValueIsFilled(DedicatedChartOfAccounts) Then
			Filter.Insert("ChartOfAccounts", DedicatedChartOfAccounts);
		EndIf;
		FormParameters.Insert("Filter", Filter);
		OpenForm("InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.Form.ListForm", FormParameters, ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtServer
Procedure ChartOfAccountsWhenChangedOnServer()
	InitializeConfigurationTable();
	FillInTransactionGenerationSettings();
EndProcedure

&AtServer
Procedure InitializeConfigurationTable()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	FinancialAccountingChartsOfAccounts.Ref
	|FROM
	|	Catalog.FinancialAccountingChartsOfAccounts AS FinancialAccountingChartsOfAccounts
	|WHERE
	|	(FinancialAccountingChartsOfAccounts.Ref = &ChartOfAccounts
	|		OR &AllAccountPlans)
	|	AND NOT FinancialAccountingChartsOfAccounts.DeletionMark";
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("AllAccountPlans", Not ValueIsFilled(ChartOfAccounts));
	
	FinancialAccountingChartsOfAccounts.Load(Query.Execute().Unload());
	
	IndexOf = 0;
	For Each TableRow In FinancialAccountingChartsOfAccounts Do
		TableRow.AttributeNameSetting = "Setting_" + IndexOf;
		TableRow.AttributeNameFlag = "Flag_" + IndexOf;
		TableRow.AttributeNameSettingNotUsed = "SettingNotUsed_" + IndexOf;
		TableRow.TheNameOfThePropSettingIsUsed = "SettingUsed_" + IndexOf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	DeleteDetailsForAccountPlans();
	AddDetailsForAccountPlans();
	
	CreateFormElements_();
	SetConditionalAppearance();
	
	FillOutOrganizations();
	
EndProcedure

&AtServer
Procedure FillOutOrganizations()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Companies.Ref AS Organization
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.DeletionMark
	|	AND Companies.Ref <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND (&AnyOrganization OR Companies.Ref = &Organization)
	|";
	
	Query.SetParameter("AnyOrganization", Not ValueIsFilled(Organization));
	Query.SetParameter("Organization", Organization);
	BusinessAccountPlans.Load(Query.Execute().Unload());
EndProcedure

&AtServer
Procedure CreateFormElements_()
	
	For Each TableRow In FinancialAccountingChartsOfAccounts Do
			
			
			NewFormGroup = ThisObject.Items.Add(
													"Group_" + TableRow.GetID(),
													Type("FormGroup"),
													Items.BusinessAccountPlans);
			NewFormGroup.Title = String(TableRow.Ref);
			NewFormGroup.ShowInHeader = True;
			NewFormGroup.ShowTitle = True;
			NewFormGroup.Type = FormGroupType.ColumnGroup;
			NewFormGroup.Group = ColumnsGroup.Horizontal;
			
			NewItemFlag = ThisObject.Items.Add(
													TableRow.AttributeNameFlag,
													Type("FormField"),
													NewFormGroup);
			NewItemFlag.Type = FormFieldType.CheckBoxField;
			NewItemFlag.DataPath = "BusinessAccountPlans." + TableRow.AttributeNameFlag;
			NewItemFlag.ShowInHeader = False;
			NewItemFlag.SetAction("OnChange", "Attachable_FlagOnChange");
			NewItemFlag.ItemWidth = 1;
			
			NewSettingItemIsUsed = ThisObject.Items.Add(
													TableRow.TheNameOfThePropSettingIsUsed,
													Type("FormField"),
													NewFormGroup);
			NewSettingItemIsUsed.Type = FormFieldType.InputField;
			NewSettingItemIsUsed.DataPath = "BusinessAccountPlans." + TableRow.TheNameOfThePropSettingIsUsed;
			NewSettingItemIsUsed.ShowInHeader = False;
			NewSettingItemIsUsed.CellHyperlink = True;
			NewSettingItemIsUsed.ReadOnly = True;
			NewSettingItemIsUsed.TextColor = StyleColors.TabularFormHyperlink;
		
			NewSettingItemIsNotUsed = ThisObject.Items.Add(
													TableRow.AttributeNameSettingNotUsed,
													Type("FormField"),
													NewFormGroup);
			NewSettingItemIsNotUsed.Type = FormFieldType.InputField;
			NewSettingItemIsNotUsed.ShowInHeader = False;
			NewSettingItemIsNotUsed.DataPath = "BusinessAccountPlans." + TableRow.AttributeNameSettingNotUsed;
			NewSettingItemIsNotUsed.CellHyperlink = False;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddDetailsForAccountPlans()
	
	AttributesToBeAdded = New Array();
	For Each TableRow In FinancialAccountingChartsOfAccounts Do
		
		AttributeFlag = New FormAttribute(
											TableRow.AttributeNameFlag,
											New TypeDescription("Boolean") , 
											"BusinessAccountPlans", 
											NStr("vi = 'Có tùy chỉnh';
												|ru = 'Есть настройка';
												|en = 'Setting exists'; fa = 'Setting exists';
												|it = 'Vi è un''impostazione';
												|pl = 'Istnieje ustawienie';
												|tr = 'Ayar mevcut'"));
		AttributesToBeAdded.Add(AttributeFlag);
		
		TypesOfSetting = New Array();
		TypesOfSetting.Add(Undefined);
		TypesOfSetting.Add("CatalogRef.FinancialAccountingPostingGenerationSetting");
		
		PropsSetup = New FormAttribute(
											TableRow.AttributeNameSetting,
											New TypeDescription(TypesOfSetting) , 
											"BusinessAccountPlans", 
											String(TableRow.Ref));
		AttributesToBeAdded.Add(PropsSetup);
		
		PropsSetupNotUsed = New FormAttribute(
											TableRow.AttributeNameSettingNotUsed,
											New TypeDescription("String") , 
											"BusinessAccountPlans", 
											NStr("vi = 'Không sử dụng tùy chỉnh';
												|ru = 'Настройка не используется';
												|en = 'Setting is not used'; fa = 'Setting is not used';
												|it = 'L''impostazione non è utilizzata';
												|pl = 'Ustawienie nie jest używane';
												|tr = 'Ayar kullanılmıyor'"));
		AttributesToBeAdded.Add(PropsSetupNotUsed);
		
		SettingDetailsAreUsed = New FormAttribute(
											TableRow.TheNameOfThePropSettingIsUsed,
											New TypeDescription("String") , 
											"BusinessAccountPlans", 
											NStr("vi = 'Sử dụng tùy chỉnh';
												|ru = 'Настройка используется';
												|en = 'Setting is used'; fa = 'Setting is used';
												|it = 'L''impostazione è utilizzata';
												|pl = 'Ustawienie jest używane';
												|tr = 'Ayar kullanılıyor'"));
											
		AttributesToBeAdded.Add(SettingDetailsAreUsed);
		
	EndDo;
	
	ThisObject.ChangeAttributes(AttributesToBeAdded);
	
EndProcedure

&AtServer
Procedure DeleteDetailsForAccountPlans()

	AttributesToBeDeleted = New Array();
	TableChartsOfAccountsOfOrganizations = BusinessAccountPlans.Unload(New Array);
	For Each Column In TableChartsOfAccountsOfOrganizations.Columns Do
		If StrFind(Column.Name, "Setting_") <> 0 
				Or StrFind(Column.Name, "Flag_") <> 0 
				Or StrFind(Column.Name, "Group_") <> 0 
				Or StrFind(Column.Name, "SettingNotUsed_") <> 0
				Or StrFind(Column.Name, "SettingUsed_") <> 0 Then
			
			AttributesToBeDeleted.Add("BusinessAccountPlans." + Column.Name);
			
			FormItem = Items.Find(Column.Name);
			If FormItem <> Undefined Then
				Items.Delete(FormItem);
			EndIf;
			
		EndIf;
	EndDo;
	
	ThisObject.ChangeAttributes(, AttributesToBeDeleted);
EndProcedure

&AtServer
Procedure FillInTransactionGenerationSettings()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Companies.Organization
	|INTO TTOrganizations
	|FROM
	|	&Companies AS Companies
	|;
	|
	|////////////////////////////
	|SELECT
	|	Companies.Organization AS Organization,
	|	SliceRegister.ChartOfAccounts AS ChartOfAccounts,
	|	SliceRegister.PostingGenerationSetting AS PostingGenerationSetting,
	|	PRESENTATION(SliceRegister.PostingGenerationSetting) AS PostingGenerationSettingPresentation,
	|	SliceRegister.Period AS SettingUpTransactionGeneration
	|FROM
	|	TTOrganizations AS Companies
	|	LEFT JOIN
	|		InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(, ChartOfAccounts = &ChartOfAccounts OR &AllAccountPlans) AS SliceRegister
	|	ON
	|		Companies.Organization = SliceRegister.Organization
	|
	|TOTALS BY
	|	Organization";
	
	Query.SetParameter("Companies", BusinessAccountPlans.Unload());
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("AllAccountPlans", Not ValueIsFilled(ChartOfAccounts));
	
	SampleOrganization = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	For Each SettingsTableRow In BusinessAccountPlans Do
		
		If SampleOrganization.FindNext(SettingsTableRow.Organization, "Organization") Then
			
			Selection = SampleOrganization.Select(QueryResultIteration.ByGroups);
			
			For Each LineOfAccountPlans In FinancialAccountingChartsOfAccounts Do
				
				If Selection.FindNext(New Structure("ChartOfAccounts", LineOfAccountPlans.Ref)) Then
					If Selection.PostingGenerationSetting = Catalogs.FinancialAccountingPostingGenerationSetting.EmptyRef() Then
						HyperlinkAnchorText = 
						StrTemplate(NStr("vi = 'Không sử dụng từ %1';
										|ru = 'Не используется с %1';
										|en = 'Not used since %1'; fa = 'Not used since %1';
										|it = 'Non si utilizza con %1';
										|pl = 'Nie używany z %1';
										|tr = '%1 ile kullanılmıyor'"), 
							Format(Selection.SettingUpTransactionGeneration, "DLF=D;"));
						SettingsTableRow[LineOfAccountPlans.AttributeNameFlag] = False;
						SettingsTableRow[LineOfAccountPlans.AttributeNameSettingNotUsed] = HyperlinkAnchorText;
					Else
						HyperlinkAnchorText = 
							StrTemplate(NStr("vi = 'Tùy chỉnh: %1, áp dụng từ %2';
											|ru = 'Настройка: %1, применяется с %2';
											|en = 'Setting: %1, applied since %2'; fa = 'Setting: %1, applied since %2';
											|it = 'Impostazione: %1, si applica con %2';
											|pl = 'Ustawienie: %1, jest stosowna od %2';
											|tr = 'Ayar: %1, %2 itibarıyla uygulanıyor'"), 
								Selection.PostingGenerationSettingPresentation,
								Format(Selection.SettingUpTransactionGeneration, "DLF=D;"));
						SettingsTableRow[LineOfAccountPlans.AttributeNameFlag] = True;
						SettingsTableRow[LineOfAccountPlans.TheNameOfThePropSettingIsUsed] = HyperlinkAnchorText;
					EndIf;	
					SettingsTableRow[LineOfAccountPlans.AttributeNameSetting] = Selection.PostingGenerationSetting;
				Else
					SettingsTableRow[LineOfAccountPlans.AttributeNameSetting] = Undefined;
					SettingsTableRow[LineOfAccountPlans.TheNameOfThePropSettingIsUsed] = "";
					SettingsTableRow[LineOfAccountPlans.AttributeNameFlag] = False;
				EndIf;
				Selection.Reset();
				
			EndDo;
			
		EndIf;
		
		SampleOrganization.Reset();
		
	EndDo;
	
EndProcedure

&AtClient
Procedure WhenAnsweringQuestionAboutDisablingTransactionGeneration(QuestionResult, AdditionalParameters) Export
	
	CurrentData = BusinessAccountPlans.FindByID(AdditionalParameters.RowID);
	If QuestionResult = DialogReturnCode.OK Then
		ToolTipText = NStr("vi = 'Hãy nhập ngày ngừng hoạt động.';
							|ru = 'Введите дату отключения.';
							|en = 'Enter date of disabling.'; fa = 'Enter date of disabling.';
							|it = 'Inserire data di disattivazione.';
							|pl = 'Wprowadź datę odłączenia.';
							|tr = 'Ret tarihini giriniz'");
		CallbackDescription = New CallbackDescription("WhenEnteringOrDisablingTransactionGeneration", ThisObject, AdditionalParameters);
		ShowInputDate(CallbackDescription, CurrentDate, ToolTipText, DateFractions.Date);
	Else
		CurrentData[AdditionalParameters.AttributeNameFlag] = True;
	EndIf;

EndProcedure

&AtClient
Procedure WhenEnteringOrDisablingTransactionGeneration(DateOfExpiration, AdditionalParameters) Export
	
	CurrentData = BusinessAccountPlans.FindByID(AdditionalParameters.RowID);
	If ValueIsFilled(DateOfExpiration) Then
		DateOfExpiration = BegOfMonth(DateOfExpiration);
		EnteredDateOfDisconnection = DateOfExpiration;
		SettingDisabled = False;
		DisableGeneratingTransactions(AdditionalParameters.ChartOfAccounts, AdditionalParameters.Organization, DateOfExpiration, SettingDisabled);
		If DateOfExpiration = EnteredDateOfDisconnection Or SettingDisabled Then
			CurrentData[AdditionalParameters.AttributeNameSetting] = PredefinedValue("Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef");
			HyperlinkAnchorText = StrTemplate(NStr("vi = 'Không sử dụng từ %1';
													|ru = 'Не используется с %1';
													|en = 'Not used since %1'; fa = 'Not used since %1';
													|it = 'Non si utilizza con %1';
													|pl = 'Nie używany z %1';
													|tr = '%1 ile kullanılmıyor'"), Format(DateOfExpiration, "DLF=D;"));
			CurrentData[AdditionalParameters.TheNameOfThePropSettingIsUsed] = HyperlinkAnchorText;
		Else
			CurrentData[AdditionalParameters.AttributeNameFlag] = True;
		EndIf;
	Else
		CurrentData[AdditionalParameters.AttributeNameFlag] = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure DisableGeneratingTransactions(ChartOfAccounts, Organization, DateOfExpiration, SettingDisabled)
	
	DatePrevious = AddMonth(BegOfMonth(DateOfExpiration), -1);
	PreviosLine = InformationRegisters.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(DatePrevious, New Structure("ChartOfAccounts, Organization", ChartOfAccounts, Organization));
	
	RecordSet = InformationRegisters.FinancialAccountingChartsOfAccountsForCompanies.CreateRecordSet();
	RecordSet.Filter.ChartOfAccounts.Set(ChartOfAccounts);
	RecordSet.Filter.Organization.Set(Organization);
	RecordSet.Filter.Period.Set(DateOfExpiration);
	
	DisabledEarlier = PreviosLine.Count() And Not ValueIsFilled(PreviosLine[0].PostingGenerationSetting);
	
	If Not DisabledEarlier Then
		EmptySetting = RecordSet.Add();
		EmptySetting.Organization = Organization;
		EmptySetting.ChartOfAccounts = ChartOfAccounts;
		EmptySetting.Period = DateOfExpiration;
	Else
		RecordSet.Read();
		SettingDisabled = RecordSet.Count();
		If Not SettingDisabled Then
			MessageText = StrTemplate(NStr("vi = 'Tại ngày %1 chưa bật tiến hành kế toán theo hệ thống tài khoản %2. Tùy chỉnh đã bị ngắt trước đó %3.';
											|ru = 'На дату %1 ведние учета по плану счетов %2 не было включено. Настройка была отключена ранее %3.';
											|en = 'As of %1, accounting based on chart of accounts %2 was not enabled. The setting was disabled previously %3.'; fa = 'As of %1, accounting based on chart of accounts %2 was not enabled. The setting was disabled previously %3.';
											|it = 'In data %1 l''esecuzione del calcolo pe ril piano dei conti %2 non è stata attivata. L''impostazione è stata precedentemente disattivata %3.';
											|pl = 'Na datę %1 prowadzenie ewidencji wg planu kont %2 nie było włączone. Ustawienie zostało wyłączone wcześniej %3.';
											|tr = '%1 tarihi itibariyle, %2 hesap planının muhasebeleştirilmesi etkinleştirilmedi. Ayar, %3''ten önce devre dışı bırakıldı.'"), 
							Format(DateOfExpiration, "DLF=DD;"),
							ChartOfAccounts,
							Format(PreviosLine[0].Period, "DLF=DD;"));
		Else
			MessageText = StrTemplate(NStr("vi = 'Trong kỳ này đã bật tiến hành kế toán theo hệ thống tài khoản %2. Tùy chỉnh trong kỳ %1 đã bị xóa.';
											|ru = 'В этом периоде уже было введено включение ведение учета по плану счетов %2. Настройка за период %1 удалена.';
											|en = 'In this period, enabling of the accounting based on chart of accounts %2 has already been introduced. Setting for period %1 has been deleted.'; fa = 'In this period, enabling of the accounting based on chart of accounts %2 has already been introduced. Setting for period %1 has been deleted.';
											|it = 'In tale periodo era già stata inserita l''attivazione dell''esecuzione del calcolo per il piano dei conti %2. L''impostazione per il periodo %1 è cancellata.';
											|pl = 'W tym okresie już zostało włączone prowadzenie ewidencji wg planu kont %2. Konfiguracja za okres %1 została usunięta.';
											|tr = 'Bu dönemde, %2 hesap planına göre muhasebenin dahil edilmesi çoktan başlatılmıştır. %1 dönemi için ayar silindi.'"), 
								Format(DateOfExpiration, "DLF=DD;"),
								ChartOfAccounts);
		EndIf;
		
		DateOfExpiration = PreviosLine[0].Period;
		RecordSet.Clear();
		Common.MessageToUser(MessageText);
	EndIf;
	RecordSet.Write(True);
	
EndProcedure

#EndRegion
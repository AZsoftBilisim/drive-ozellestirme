#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Record.SourceRecordKey)
		Or Record.SourceRecordKey.IsEmpty() Then
		
		OnReadCreateAtServer();
		
		FillInProcedureForApplyingSetting();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If CurrentObject.ThereIsAdditionalSelectionDr Then
		SettingsComposerSelectsDrAccountingObject.LoadSettings(CurrentObject.AdditionalSelectionDr.Get());
	EndIf;
	If CurrentObject.ThereIsAdditionalSelectionCr Then
		SettingsComposerSelectsCRAccountingObject.LoadSettings(CurrentObject.AdditionalSelectionCr.Get());
	EndIf;
	
	OnReadCreateAtServer();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	SetDefinitionOfAccountingAccountBySettingObject("Dr");
	SetDefinitionOfAccountingAccountBySettingObject("Cr");
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	SettingsOfSelectionsInRegisterEntry(CurrentObject, "Dr");
	SettingsOfSelectionsInRegisterEntry(CurrentObject, "Cr");
	ExtdimensionFillSettingsInRegisterEntry(CurrentObject, "Dr");
	ExtdimensionFillSettingsInRegisterEntry(CurrentObject, "Cr");
	
	SetValueToLongTerm(CurrentObject, "Dr");
	SetValueToLongTerm(CurrentObject, "Cr");
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	GenerateCorrespondenceSettingsLink();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	ChartOfAccountsWhenChangedOnServer();
EndProcedure

&AtClient
Procedure PostingGenerationSettingOnChange(Item)
	ConfiguringGenerationOfTransactionsWhenChangesAreMadeOnServer();
EndProcedure

&AtClient
Procedure OptionForApplyingSubsequentSettingsOnChange(Item)
	Record.ApplySubsequentSettings = ?(OptionForApplyingSubsequentSettings = 1, True, False);
EndProcedure

&AtClient
Procedure ItIsNotReflectedInTheAccountsOnChange(Item)
	IsNotReflectedInAccountingAccountsWhenChangesAreMadeOnServer();
EndProcedure

&AtClient
Procedure InvertTheResourceSignOnChange(Item)
	InvertResourceSignWhenChangingOnServer();
EndProcedure

&AtClient
Procedure TheObjectOfAccountingForDtAdditionalSelectionOnEditEnd(Item, NewRow, CancelEdit)
	SetGroupTitleAdditionalSelectionAccountingObject(ThisObject, "Dr");
EndProcedure

&AtClient
Procedure TheObjectOfAccountingForDtAdditionalSelectionAfterDeleteRow(Item)
	SetGroupTitleAdditionalSelectionAccountingObject(ThisObject, "Dr");
EndProcedure

&AtClient
Procedure TheObjectOfAccountingForCtAdditionalSelectionOnEditEnd(Item, NewRow, CancelEdit)
	SetGroupTitleAdditionalSelectionAccountingObject(ThisObject, "Cr");
EndProcedure

&AtClient
Procedure TheObjectOfAccountingForCtAdditionalSelectionAfterDeleteRow(Item)
	SetGroupTitleAdditionalSelectionAccountingObject(ThisObject, "Cr");
EndProcedure

&AtClient
Procedure AccountingObjectDrOnChange(Item)
	AccountingObjectOnChangeServer("Dr");
EndProcedure

&AtClient
Procedure AccountingObjectDrStartChoice(Item, ChoiceData, StandardProcessing)
	AccountingObjectStartOfSelection(Item, ChoiceData, StandardProcessing, "Dr");
EndProcedure

&AtClient
Procedure AccountingObjectCrOnChange(Item)
	AccountingObjectOnChangeServer("Cr");
EndProcedure

&AtClient
Procedure AccountingObjectCrStartChoice(Item, ChoiceData, StandardProcessing)
	AccountingObjectStartOfSelection(Item, ChoiceData, StandardProcessing, "Cr");
EndProcedure

&AtClient
Procedure LongTermDrOnChange(Item)
	LongTermWhenChangingOnServer("Dr");
EndProcedure

&AtClient
Procedure LongTermCrOnChange(Item)
	LongTermWhenChangingOnServer("Cr");
EndProcedure

&AtClient
Procedure AccountingAccountFromDrObjectSettingsOnChange(Item)
	InvoiceFromObjectSettingsWhenChangedOnServer("Dr");
EndProcedure

&AtClient
Procedure AccountingAccountFromCrObjectSettingsOnChange(Item)
	InvoiceFromObjectSettingsWhenChangedOnServer("Cr");
EndProcedure

&AtClient
Procedure GLAccountDrOnChange(Item)
	AccountForChangesToServer("Dr");
EndProcedure

&AtClient
Procedure GLAccountCrOnChange(Item)
	AccountForChangesToServer("Cr");
EndProcedure

&AtClient
Procedure CustomSettingOfExtdimensionFillingDrOnChange(Item)
	CustomSettingOfExtdimensionFillingWhenServerChanges("Dr");
EndProcedure

&AtClient
Procedure CustomSettingOfExtdimensionFillingCrOnChange(Item)
	CustomSettingOfExtdimensionFillingWhenServerChanges("Cr");
EndProcedure

&AtClient
Procedure AccountingObjectStartOfSelection(Item, ChoiceData, StandardProcessing, DrCr)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("CurrentRow", Record["AccountingObject" + DrCr]);
	FormParameters.Insert("HideInappropriateValues", True);
	FormParameters.Insert("PostingGenerationSetting", Record.PostingGenerationSetting);
	
	OpenForm("Enum.DeleteFinancialAccountingObjects.ChoiceForm", FormParameters, Item);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFillInExtraDimensionDr

&AtClient
Procedure FillInExtraDimensionDrOnActivateRow(Item)
	FillingExtdimensionWhenLineIsActivated(Item, "Dr");
EndProcedure

&AtClient
Procedure FillInExtraDimensionDrOnEditEnd(Item, NewRow, CancelEdit)
	SetGroupHeaderExtdimensionSettings("Dr");
EndProcedure

&AtClient
Procedure FillInExtraDimensionDrRepresentationOfTheExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	PresentationOfExpressionStartOfSelection(Item, ChoiceData, StandardProcessing, "Dr");
EndProcedure

&AtClient
Procedure FillInExtraDimensionDrRepresentationOfTheExpressionClearing(Item, StandardProcessing)
	PresentationOfExpression(Item, StandardProcessing, "Dr");
EndProcedure

&AtClient
Procedure FillInExtraDimensionDrRepresentationOfTheExpressionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ExpressionPresentationSelectionProcessing(Item, ValueSelected, StandardProcessing, "Dr");
EndProcedure

&AtClient
Procedure FillInExtraDimensionDrMethodOfFillingExtdimensionOnChange(Item)
	FillingMethodOnChange(Item,  "Dr");
EndProcedure

&AtClient
Procedure FillingInTheSubcontoDtTheSpecifiedSubcontoValueWhenChanging(Item)
	TheSpecifiedValueWhenChanging(Item, "Dr");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFillInExtraDimensionCr

&AtClient
Procedure FillingInTheSubcontextWhenTheLineIsActivated(Item)
	FillingExtdimensionWhenLineIsActivated(Item, "Cr");
EndProcedure

&AtClient
Procedure FillInExtraDimensionCrOnEditEnd(Item, NewRow, CancelEdit)
	SetGroupHeaderExtdimensionSettings("Cr");
EndProcedure

&AtClient
Procedure FillInExtraDimensionCrRepresentationOfTheExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	PresentationOfExpressionStartOfSelection(Item, ChoiceData, StandardProcessing, "Cr");
EndProcedure

&AtClient
Procedure FillInExtraDimensionCrRepresentationOfTheExpressionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ExpressionPresentationSelectionProcessing(Item, ValueSelected, StandardProcessing, "Cr");
EndProcedure

&AtClient
Procedure FillInExtraDimensionCrRepresentationOfTheExpressionClearing(Item, StandardProcessing)
	PresentationOfExpression(Item, StandardProcessing, "Cr");
EndProcedure

&AtClient
Procedure FillInExtraDimensionCrSpecifiedValueIsExtdimensionOnChange(Item)
	TheSpecifiedValueWhenChanging(Item, "Cr");
EndProcedure

&AtClient
Procedure FillInExtraDimensionCrMethodOfFillingExtdimensionOnChange(Item)
	FillingMethodOnChange(Item, "Cr");
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AnalysisOfCorrespondence(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", "AnalysisOfCorrespondenceOnDocuments");
	FormParameters.Insert("GenerateOnOpen", True);
	
	SelectionParameter = New Structure();
	SelectionParameter.Insert("LongTermDr", False);
	SelectionParameter.Insert("LongTermCr", False);
	SetValueToLongTerm(SelectionParameter, "Dr");
	SetValueToLongTerm(SelectionParameter, "Cr");
	If ValueIsFilled(Record.ChartOfAccounts) Then
		SelectionParameter.Insert("ChartOfAccounts", Record.ChartOfAccounts);
	EndIf;
	If ValueIsFilled(Record.PostingGenerationSetting) Then
		SelectionParameter.Insert("PostingGenerationSetting", Record.PostingGenerationSetting);
	EndIf;
	
	FormParameters.Insert("Filter", SelectionParameter);
	
	UserSettingsValues = New Structure();
	If ValueIsFilled(Record.AccountingObjectDr) Then
		UserSettingsValues.Insert("AccountingObjectDr", Record.AccountingObjectDr);
	EndIf;
	If ValueIsFilled(Record.AccountingObjectCr) Then
		UserSettingsValues.Insert("AccountingObjectCr", Record.AccountingObjectCr);
	EndIf;
	If UserSettingsValues.Count() > 0 Then
		UserSettings = CustomSettingsForCorrespondenceAnalysisReport(
			"AnalysisOfOperationalAccountingCorrespondence", UserSettingsValues);
		FormParameters.Insert("UserSettings", UserSettings);
	EndIf;
	
	SettingsForAdditionalSelections = SettingsForAdditionalSelectionsOfAccountingObjects();
	If SettingsForAdditionalSelections.Filter.Items.Count() > 0 Then
		FormParameters.Insert("FixedSettings", SettingsForAdditionalSelections);
	EndIf;
	
	OpenForm("Report.AnalysisOfOperationalAccountingCorrespondence.ObjectForm", FormParameters, ThisForm);
	
EndProcedure

&AtServerNoContext
Function CustomSettingsForCorrespondenceAnalysisReport(ReportName, UserSettingsValues)
	
	Return FinancialAccountingByFinancialRegisterDataServerCall.CustomSettingsForAnalysisOfOperationalAccounting(
		ReportName, UserSettingsValues);
	
EndFunction

&AtServer
Function SettingsForAdditionalSelectionsOfAccountingObjects()
	
	SettingsForAdditionalSelections = New DataCompositionSettings();
	
	FinancialAccountingByBalanceSheetRegisterData.CopyDataCompositionFilter(
		SettingsForAdditionalSelections.Filter, SettingsComposerSelectsDrAccountingObject.Settings.Filter,, "Dr");
	FinancialAccountingByBalanceSheetRegisterData.CopyDataCompositionFilter(
		SettingsForAdditionalSelections.Filter, SettingsComposerSelectsCRAccountingObject.Settings.Filter,, "Cr");
	
	Return SettingsForAdditionalSelections;
	
EndFunction

&AtClient
Procedure CorrespondenceSettings(Command)
	
	Filter = New Structure;
	Filter.Insert("ChartOfAccounts", Record.ChartOfAccounts);
	Filter.Insert("PostingGenerationSetting", Record.PostingGenerationSetting);
	Filter.Insert("AccountingObjectDr", Record.AccountingObjectDr);
	Filter.Insert("AccountingObjectCr", Record.AccountingObjectCr);
	Filter.Insert("LongTermDr", False);
	Filter.Insert("LongTermCr", False);
	
	SetValueToLongTerm(Filter, "Dr");
	SetValueToLongTerm(Filter, "Cr");
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("RecordKey", Record.SourceRecordKey);
	
	OpenForm("InformationRegister.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting.ListForm", 
		FormParameters,
		ThisObject,
		,
		,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure


#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ExtdimensionSetupTables = New Array;
	ExtdimensionSetupTables.Add(Items.FillInExtraDimensionDr.Name);
	ExtdimensionSetupTables.Add(Items.FillInExtraDimensionCr.Name);
	
	FlagsCustomSetting = New Structure();
	FlagsCustomSetting.Insert(Items.FillInExtraDimensionDr.Name, Items.CustomSettingOfExtdimensionFillingDr.DataPath);
	FlagsCustomSetting.Insert(Items.FillInExtraDimensionCr.Name, Items.CustomSettingOfExtdimensionFillingCr.DataPath);
	
	ConfigurationTableFields = New Structure;
	
	TableFieldNamesFillingExtdimensionDr = New Structure;
	TableFieldNamesFillingExtdimensionDr.Insert("MethodOfFillingExtdimension", Items.FillInExtraDimensionDrMethodOfFillingExtdimension.Name);
	TableFieldNamesFillingExtdimensionDr.Insert("SpecifiedValueIsExtdimension", Items.FillInExtraDimensionDrSpecifiedValueIsExtdimension.Name);
	TableFieldNamesFillingExtdimensionDr.Insert("ThereAreProblemsOfSpecifiedExtdimensionValue", Items.FillingInTheSubcontoDtSpecifiedValueThereAreProblemsFillingInTheSubconto.Name);
	TableFieldNamesFillingExtdimensionDr.Insert("RepresentationOfTheExpression", Items.FillInExtraDimensionDrRepresentationOfTheExpression.Name);
	TableFieldNamesFillingExtdimensionDr.Insert("ThereAreProblemsFillingExtdimensionFromRegister", Items.FillingInExtDimensionOfDrFromRegisterThereAreProblemsFillingInExtDimension.Name);
	ConfigurationTableFields.Insert(Items.FillInExtraDimensionDr.Name, TableFieldNamesFillingExtdimensionDr);
	
	TableFieldNamesFillingExtdimensionCr = New Structure;
	TableFieldNamesFillingExtdimensionCr.Insert("MethodOfFillingExtdimension", Items.FillInExtraDimensionCrMethodOfFillingExtdimension.Name);
	TableFieldNamesFillingExtdimensionCr.Insert("SpecifiedValueIsExtdimension", Items.FillInExtraDimensionCrSpecifiedValueIsExtdimension.Name);
	TableFieldNamesFillingExtdimensionCr.Insert("ThereAreProblemsOfSpecifiedExtdimensionValue", Items.FillingInTheSubcontoCtTheSpecifiedValueThereAreProblemsFillingInTheSubconto.Name);
	TableFieldNamesFillingExtdimensionCr.Insert("RepresentationOfTheExpression", Items.FillInExtraDimensionCrRepresentationOfTheExpression.Name);
	TableFieldNamesFillingExtdimensionCr.Insert("ThereAreProblemsFillingExtdimensionFromRegister", Items.FillingInExtDimensionOfCrFromRegisterThereAreProblemsFillingInExtDimension.Name);
	ConfigurationTableFields.Insert(Items.FillInExtraDimensionCr.Name, TableFieldNamesFillingExtdimensionCr);
	
	For Each ExtdimensionSetupTable In ExtdimensionSetupTables Do
		
		FieldNamesOfSettingsTable = ConfigurationTableFields[ExtdimensionSetupTable];
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldNamesOfSettingsTable.SpecifiedValueIsExtdimension);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ExtdimensionSetupTable + ".MethodOfFillingExtdimension");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldNamesOfSettingsTable.SpecifiedValueIsExtdimension);
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldNamesOfSettingsTable.ThereAreProblemsOfSpecifiedExtdimensionValue);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ExtdimensionSetupTable + ".MethodOfFillingExtdimension");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
		ListOfMethods = New ValueList;
		ListOfMethods.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue);
		ListOfMethods.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill);
		ItemFilter.RightValue = ListOfMethods;
		
		Item.Appearance.SetParameterValue("Visible", False);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldNamesOfSettingsTable.RepresentationOfTheExpression);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ExtdimensionSetupTable + ".MethodOfFillingExtdimension");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ExtdimensionSetupTable + ".ExpressionOfExtdimensionFilling");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("MarkIncomplete", True);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldNamesOfSettingsTable.ThereAreProblemsFillingExtdimensionFromRegister);
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldNamesOfSettingsTable.RepresentationOfTheExpression);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ExtdimensionSetupTable + ".MethodOfFillingExtdimension");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister;
		
		Item.Appearance.SetParameterValue("Visible", False);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldNamesOfSettingsTable.SpecifiedValueIsExtdimension);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ExtdimensionSetupTable + ".MethodOfFillingExtdimension");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ExtdimensionSetupTable + ".SpecifiedValueIsExtdimension");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("MarkIncomplete", True);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldNamesOfSettingsTable.ThereAreProblemsFillingExtdimensionFromRegister);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ExtdimensionSetupTable + ".ExpressionOfExtdimensionFilling");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("Visible", False);
		
		//

		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldNamesOfSettingsTable.ThereAreProblemsOfSpecifiedExtdimensionValue);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ExtdimensionSetupTable + ".SpecifiedValueIsExtdimension");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("Visible", False);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		For Each KeyAndValue In FieldNamesOfSettingsTable Do
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(KeyAndValue.Value);
		EndDo;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue =  New DataCompositionField(FlagsCustomSetting[ExtdimensionSetupTable]);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("ReadOnly",  True);
		
	EndDo;
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsOfAccountingObjectSettingObjectDr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountsOfAccountingObjectDr.SettingObject1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Undefined;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chung';
													|ru = 'Общая';
													|en = 'General'; fa = 'عمومی';
													|it = 'Общая';
													|pl = 'General';
													|tr = 'Ortak'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsOfAccountingObjectSettingObjectDr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountsOfAccountingObjectDr.SettingObject1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa chỉ ra';
													|ru = 'Не указан(а)';
													|en = 'Not specified'; fa = 'مشخص نشده';
													|it = 'Не указан(а)';
													|pl = 'Nie określono';
													|tr = 'Belirtilmedi'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsOfAccountingObjectCompanyDr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountsOfAccountingObjectDr.Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tất cả';
													|ru = 'Все';
													|en = 'All'; fa = 'همه';
													|it = 'Все';
													|pl = 'All';
													|tr = 'Tümü'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsOfAccountingObjectPlaceOfRegistrationDr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountsOfAccountingObjectDr.PlaceOfRegistration");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tất cả';
													|ru = 'Все';
													|en = 'All'; fa = 'همه';
													|it = 'Все';
													|pl = 'All';
													|tr = 'Tümü'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsOfAccountingObjectSettingObjectCr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountsOfAccountingObjectCr.SettingObject1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Undefined;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chung';
													|ru = 'Общая';
													|en = 'General'; fa = 'عمومی';
													|it = 'Общая';
													|pl = 'General';
													|tr = 'Ortak'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsOfAccountingObjectSettingObjectCr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountsOfAccountingObjectCr.SettingObject1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa chỉ ra';
													|ru = 'Не указан(а)';
													|en = 'Not specified'; fa = 'مشخص نشده';
													|it = 'Не указан(а)';
													|pl = 'Nie określono';
													|tr = 'Belirtilmedi'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsOfAccountingObjectCompanyCr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountsOfAccountingObjectCr.Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tất cả';
													|ru = 'Все';
													|en = 'All'; fa = 'همه';
													|it = 'Все';
													|pl = 'All';
													|tr = 'Tümü'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsOfAccountingObjectPlaceOfRegistrationCr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountsOfAccountingObjectCr.PlaceOfRegistration");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tất cả';
													|ru = 'Все';
													|en = 'All'; fa = 'همه';
													|it = 'Все';
													|pl = 'All';
													|tr = 'Tümü'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	If Not ValueIsFilled(Record.ChartOfAccounts)
	 Or Not ValueIsFilled(Record.PostingGenerationSetting) Then
		Items.TheGroupOfDimensions.Visible = True;
		
		ChoiceParameterLinks = New Array();
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Filter.Owner", "Record.ChartOfAccounts", LinkedValueChangeMode.Clear));
		Items.PostingGenerationSetting.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
	Else
		Items.TheGroupOfDimensions.Visible = False;
	EndIf;
	
	GLAccountDr = Record.GLAccountDr;
	GLAccountCr = Record.GLAccountCr;
	
	DescriptionOfAccountingObject_Dr = Enums.DeleteFinancialAccountingObjects.DescriptionOfFinancialAccountingObject(Record.AccountingObjectDr, True);
	DescriptionOfAccountingObject_Cr = Enums.DeleteFinancialAccountingObjects.DescriptionOfFinancialAccountingObject(Record.AccountingObjectCr, True);
	
	DivisionIntoShortTermLongTermAssetsAndLiabilities = Common.ObjectAttributeValue(
		Record.PostingGenerationSetting, "DivisionIntoShortTermLongTermAssetsAndLiabilities");
	
	InitializeOptionToApplySubsequentSettings();
	GenerateCorrespondenceSettingsLink();

	InitializeNumericAttributesByBooleanFields("Dr");
	InitializeNumericAttributesByBooleanFields("Cr");
	
	FillInInvoicesOfAccountingObject("Dr");
	FillInInvoicesOfAccountingObject("Cr");
	
	InitializeSelectionComposersByAccountingObject("Dr");
	InitializeSelectionComposersByAccountingObject("Cr");
	SetGroupTitleAdditionalSelectionAccountingObject(ThisObject, "Dr");
	SetGroupTitleAdditionalSelectionAccountingObject(ThisObject, "Cr");
	
	FillInExtdimensionFillSettings("Dr");
	FillInExtdimensionFillSettings("Cr");
	InitializeComposerForExtdimensionFillSettings();
	
	EstablishAvailableWaysToFillExtdimension("Dr");
	EstablishAvailableWaysToFillExtdimension("Cr");
	
	FormControl(ThisObject);
	
EndProcedure

&AtServer
Procedure EstablishAvailableWaysToFillExtdimension(DrCr)
	
	If DrCr = "Dr" Then
		ChoiceList = Items.FillInExtraDimensionDrMethodOfFillingExtdimension.ChoiceList;
	Else
		ChoiceList = Items.FillInExtraDimensionCrMethodOfFillingExtdimension.ChoiceList;
	EndIf;
	
	ChoiceList.Clear();
	ChoiceList.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister);
	ChoiceList.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue);
	ChoiceList.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill);
	
EndProcedure

&AtServer
Procedure SetValueToLongTerm(CurrentObject, DrCr)
	
	If DivisionIntoShortTermLongTermAssetsAndLiabilities Then
		CurrentObject["LongTerm" + DrCr] = Boolean(ThisObject["LongTerm" + DrCr]);
	Else
		CurrentObject["LongTerm" + DrCr] = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDefinitionOfAccountingAccountBySettingObject(DrCr)
	
	If Record.ItIsNotReflectedInTheAccounts Then
		Record["LedgerAccountIsDeterminedByAccountingObjectSetup" + DrCr] = False;
	Else
		Record["LedgerAccountIsDeterminedByAccountingObjectSetup" + DrCr] = Boolean(ThisObject["InvoiceFromObjectSettings" + DrCr]);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items = Form.Items;
	Record = Form.Record;
	
	OtherAssetsLiabilitiesDr = TheseAreOtherAssetsLiabilities(Record, "Dr");
	OtherAssetsLiabilitiesCr = TheseAreOtherAssetsLiabilities(Record, "Cr");
	
	InvoiceIsDeterminedByObjectSettings = NStr("vi = 'Được xác định bởi tùy chỉnh theo đối tượng';
												|ru = 'Определяется настройкой по объектам';
												|en = 'Determined by object setup'; fa = 'تعیین‌شده بر اساس تنظیم شیء';
												|it = 'Определяется настройкой по объектам';
												|pl = 'Jest określane ustawieniem według obiektów';
												|tr = 'Nesnelere göre ayarlanarak tanımlanır'");
	InvoiceIsDeterminedByDocumentSettings = NStr("vi = 'Được xác định bởi tùy chỉnh trong các chứng từ';
												|ru = 'Определяется настройками в документах';
												|en = 'Depends on the document settings'; fa = 'Depends on the document settings';
												|it = 'Определяется настройками в документах';
												|pl = 'Depends on the document settings';
												|tr = 'Belgelerdeki ayarlarla tanımlanmaktadır'");
	
	Items.InvoiceFromObjectSettingsDr.ChoiceList[1].Presentation = ?(
		OtherAssetsLiabilitiesDr,
		InvoiceIsDeterminedByDocumentSettings,
		InvoiceIsDeterminedByObjectSettings);
	
	Items.InvoiceFromObjectSettingsCr.ChoiceList[1].Presentation = ?(
		OtherAssetsLiabilitiesCr,
		InvoiceIsDeterminedByDocumentSettings,
		InvoiceIsDeterminedByObjectSettings);
	
	Items.ApplicationProcedure.Enabled = ValueIsFilled(Record.AccountingObjectDr) And ValueIsFilled(Record.AccountingObjectCr);
	
	Items.InvoiceFromObjectSettingsDr.Enabled = Not Record.ItIsNotReflectedInTheAccounts;
	Items.InvoiceFromObjectSettingsCr.Enabled = Not Record.ItIsNotReflectedInTheAccounts;
	
	Items.DrAccountingSetupGroup.Enabled = Not Record.ItIsNotReflectedInTheAccounts;
	Items.CrAccountingSetupGroup.Enabled = Not Record.ItIsNotReflectedInTheAccounts;
	
	Items.ManualSpecificationOfEntry.Enabled = Not Record.ItIsNotReflectedInTheAccounts;
	Items.InvertTheResourceSign.Enabled = Not Record.ItIsNotReflectedInTheAccounts;
	
	Items.GroupGLAccountDr.Visible = Not Form.InvoiceFromObjectSettingsDr;
	Items.GroupGLAccountCr.Visible = Not Form.InvoiceFromObjectSettingsCr;
	
	Items.AccountGroupOfAccountingObjectDr.Visible = Form.InvoiceFromObjectSettingsDr And Not OtherAssetsLiabilitiesDr;
	Items.AccountGroupOfAccountingObjectCr.Visible = Form.InvoiceFromObjectSettingsCr And Not OtherAssetsLiabilitiesCr;
	
	Items.AccountsOfOtherTransactionsDr.Visible = Form.InvoiceFromObjectSettingsDr And OtherAssetsLiabilitiesDr;
	Items.AccountsOfOtherTransactionsCr.Visible = Form.InvoiceFromObjectSettingsCr And OtherAssetsLiabilitiesCr;
	
	Items.GroupLongTermDr.Visible = Form.DivisionIntoShortTermLongTermAssetsAndLiabilities;
	Items.GroupLongTermCR.Visible = Form.DivisionIntoShortTermLongTermAssetsAndLiabilities;
	
	If Form.DivisionIntoShortTermLongTermAssetsAndLiabilities Then
		If TypeOf(Form.DescriptionOfAccountingObject_Dr) = Type("Structure") Then
			AllocationOfLongTermAssetsAndLiabilitiesDr = Form.DescriptionOfAccountingObject_Dr.AllocationOfLongTermAssetsAndLiabilities;
		Else
			AllocationOfLongTermAssetsAndLiabilitiesDr = False;
		EndIf;
		
		Items.LongTermDr.Visible = AllocationOfLongTermAssetsAndLiabilitiesDr;
		Items.DecorationNoDivisionIntoLongTermDr.Visible = Not AllocationOfLongTermAssetsAndLiabilitiesDr;
		
		If TypeOf(Form.DescriptionOfAccountingObject_Cr) = Type("Structure") Then
			AllocationOfLongTermAssetsAndLiabilitiesCr = Form.DescriptionOfAccountingObject_Cr.AllocationOfLongTermAssetsAndLiabilities;
		Else
			AllocationOfLongTermAssetsAndLiabilitiesCr = False;
		EndIf;
		
		Items.LongTermCr.Visible = AllocationOfLongTermAssetsAndLiabilitiesCr;
		Items.SceneryNoDivisionIntoLongTermCR.Visible = Not AllocationOfLongTermAssetsAndLiabilitiesCr;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function TheseAreOtherAssetsLiabilities(Record, DrCr)
	
	Return Record["AccountingObject" + DrCr] = PredefinedValue("Enum.DeleteFinancialAccountingObjects.OtherAssetsLiabilities");
	
EndFunction

&AtServer
Procedure InitializeOptionToApplySubsequentSettings()
	
	OptionForApplyingSubsequentSettings = ?(Record.ApplySubsequentSettings, 1, 0);
	
EndProcedure

&AtServer
Procedure InitializeNumericAttributesByBooleanFields(DrCr)
	
	MatchingAttributesToFields = New Structure();
	MatchingAttributesToFields.Insert("LongTerm" + DrCr, "LongTerm" + DrCr);
	MatchingAttributesToFields.Insert("InvoiceFromObjectSettings" + DrCr, "LedgerAccountIsDeterminedByAccountingObjectSetup" + DrCr);
	
	For Each AttributesAndField In MatchingAttributesToFields Do
		ThisObject[AttributesAndField.Key] = Number(Record[AttributesAndField.Value]);
	EndDo;
	
EndProcedure

&AtServer
Procedure GenerateCorrespondenceSettingsLink()
	
	DataGetParameters = InformationRegisters.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting.ParametersForReceivingConfigurationData();
	
	FillPropertyValues(DataGetParameters, Record,, "LongTermDr,LongTermCr");
	
	SetValueToLongTerm(DataGetParameters, "Dr");
	SetValueToLongTerm(DataGetParameters, "Cr");
	
	NumberOfSettingsByCorrespondence = InformationRegisters.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting.NumberOfCorrenspondencySettings(DataGetParameters);
	
	If NumberOfSettingsByCorrespondence = 0 Then
		Items.CorrespondenceSettings.Title = NStr("vi = 'Tất cả tùy chỉnh đối ứng';
													|ru = 'Все настройки по корреспонденции';
													|en = 'All correspondence settings'; fa = 'همه تنظیمات حساب مقابل';
													|it = 'Все настройки по корреспонденции';
													|pl = 'Wszystkie ustawienia według korespondencji';
													|tr = 'Tüm ayarlar muhabire göre'");
		Items.CorrespondenceSettings.Visible = False;
	Else
		Items.CorrespondenceSettings.Title = StrTemplate(NStr("vi = 'Tất cả tùy chỉnh đối ứng (%1)';
																|ru = 'Все настройки по корреспонденции (%1)';
																|en = 'All settings for correspondence (%1)'; fa = 'All settings for correspondence (%1)';
																|it = 'Все настройки по корреспонденции (%1)';
																|pl = 'Wszystkie ustawienia według korespondencji (%1)';
																|tr = 'Tüm ayarlar muhabire göre (%1)'"), NumberOfSettingsByCorrespondence);
		Items.CorrespondenceSettings.Visible = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInProcedureForApplyingSetting()
	
	DataGetParameters = InformationRegisters.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting.ParametersForReceivingConfigurationData();
	
	FillPropertyValues(DataGetParameters, Record,, "LongTermDr,LongTermCr");
	
	SetValueToLongTerm(DataGetParameters, "Dr");
	SetValueToLongTerm(DataGetParameters, "Cr");
	
	Record.ApplicationProcedure = InformationRegisters.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting.ProcedureForApplyingSetting(DataGetParameters);
	
EndProcedure

&AtServer
Procedure FillInInvoicesOfAccountingObject(DrCr)
	
	AccountingObject = Record["AccountingObject" + DrCr];
	LongTerm = ThisObject["LongTerm" + DrCr];
	AccountsOfAccountingObject = ThisObject["AccountsOfAccountingObject" + DrCr];
	
	AccountsOfAccountingObject.Clear();
	
	If ValueIsFilled(AccountingObject) Then
		QueryText = "SELECT
		|	InvoiceSettingsByMapItem.SettingType AS SettingType,
		|	InvoiceSettingsByMapItem.SettingObject1 AS SettingObject1,
		|	InvoiceSettingsByMapItem.Organization AS Organization,
		|	InvoiceSettingsByMapItem.PlaceOfRegistration AS PlaceOfRegistration,
		|	CASE
		|		WHEN &LongTerm
		|			THEN InvoiceSettingsByMapItem.LedgerAccountLongTerm
		|		ELSE InvoiceSettingsByMapItem.GLAccount
		|	END AS GLAccount
		|FROM
		|	InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS InvoiceSettingsByMapItem
		|WHERE
		|	InvoiceSettingsByMapItem.ChartOfAccounts = &ChartOfAccounts
		|	AND InvoiceSettingsByMapItem.PostingGenerationSetting = &PostingGenerationSetting
		|	AND InvoiceSettingsByMapItem.AccountingObject = &AccountingObject
		|ORDER BY
		|	SettingType,
		|	SettingObject1
		|";
		
		Query = New Query(QueryText);
		Query.SetParameter("ChartOfAccounts", Record.ChartOfAccounts);
		Query.SetParameter("PostingGenerationSetting", Record.PostingGenerationSetting);
		Query.SetParameter("AccountingObject", AccountingObject);
		Query.SetParameter("LongTerm", LongTerm);
		Result = Query.Execute();
		
		AccountsOfAccountingObject.Load(Result.Unload());
	EndIf;
	
	ManagingElementsOfAccountingObjectSInvoiceForm(DrCr);
	
EndProcedure

&AtServer
Procedure ManagingElementsOfAccountingObjectSInvoiceForm(DrCr)
	
	AccountingObject = Record["AccountingObject" + DrCr];
	DescriptionOfAccountingObject_ = ThisObject["DescriptionOfAccountingObject_" + DrCr];
	
	AccountGroupOfAccountingObject = Items["AccountGroupOfAccountingObject" + DrCr];
	AccountsOfAccountingObjectPlaceOfRegistration = Items["AccountsOfAccountingObjectPlaceOfRegistration" + DrCr];
	AccountsOfAccountingObjectSettingObject = Items["AccountsOfAccountingObjectSettingObject" + DrCr];
	
	AccountsOfAccountingObject = ThisObject["AccountsOfAccountingObject" + DrCr].Unload(, "GLAccount");
	AccountsOfAccountingObject.GroupBy("GLAccount");
	AccountsOfAccountingObject.Sort("GLAccount");
	
	If Not ValueIsFilled(AccountingObject) Then
		AccountsOfAccountingObjectPlaceOfRegistration.Visible = True;
		AccountsOfAccountingObjectPlaceOfRegistration.Title = "";
		
		AccountsOfAccountingObjectSettingObject.Visible = True;
		AccountsOfAccountingObjectSettingObject.Title = "";
		
		AccountGroupOfAccountingObject.Enabled = False;
		AccountGroupOfAccountingObject.Title = NStr("vi = 'Chưa chỉ ra đối tượng kế toán';
													|ru = 'Не выбран объект учета';
													|en = 'Accounting object is not selected'; fa = 'Accounting object is not selected';
													|it = 'Не выбран объект учета';
													|pl = 'Nie wybrano obiektu ewidencji';
													|tr = 'Muhasebe nesnesi seçilmemiş'");
		AccountGroupOfAccountingObject.TitleTextColor = StyleColors.TextColorWarning;
	Else
		AccountsOfAccountingObjectPlaceOfRegistration.Visible = DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes.Types().Count() > 0;
		AccountsOfAccountingObjectPlaceOfRegistration.Title = Enums.DeleteFinancialAccountingObjects.TitleOfAccountingLocation(
			DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes);
		
		AccountsOfAccountingObjectSettingObject.Visible = DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes.Types().Count() > 0;
		AccountsOfAccountingObjectSettingObject.Title = Enums.DeleteFinancialAccountingObjects.TitleOfTypeDescriptionConfigurationObject(
			DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes);
		
		AccountGroupOfAccountingObject.Enabled = True;
		
		If AccountsOfAccountingObject.Count() = 0 Then
			AccountGroupOfAccountingObject.Title = NStr("vi = 'Chưa tùy chỉnh tài khoản kế toán theo đối tượng';
														|ru = 'Не настроены счета учета по объекту';
														|en = 'Object ledger accounts are not set up'; fa = 'Object ledger accounts are not set up';
														|it = 'Не настроены счета учета по объекту';
														|pl = 'Nie ustawiono konta księgowego dla obiektu';
														|tr = 'Nesneye ilişkin defterikebir hesabı ayarlanmamış'");
			AccountGroupOfAccountingObject.TitleTextColor = StyleColors.TextColorWarning;
		Else
			TitleLines = New Array();
			NumberOfAccounts = AccountsOfAccountingObject.Count();
			AccountsInHeader = 3;
			AccountIndex = 0;
			
			While AccountIndex < AccountsInHeader Do
				If AccountIndex = NumberOfAccounts Then
					Break;
				EndIf;
				If AccountIndex > 0 Then
					TitleLines.Add(", ");
				EndIf;
				TitleLines.Add(AccountsOfAccountingObject[AccountIndex]["GLAccount"]["Code"]);
				AccountIndex = AccountIndex + 1;
			EndDo;
			
			If NumberOfAccounts > AccountsInHeader Then
				MoreBills = New Array();
				MoreBills.Add("");
				MoreBills.Add(NStr("vi = 'và hơn thế nữa';
									|ru = 'и еще';
									|en = 'and'; fa = 'و';
									|it = 'и еще';
									|pl = 'i jeszcze';
									|tr = 've daha'"));
				If CurrentLanguage().LanguageCode = "ru" Then
					MoreBills.Add(GetStringDeclensionsByNumber(NStr("vi = 'tài khoản';
																	|ru = 'счет';
																	|en = 'account'; fa = 'account';
																	|it = 'счет';
																	|pl = 'account';
																	|tr = 'hesap'", "ru"), NumberOfAccounts - AccountsInHeader,, "L=ru_RU")[0]);
				Else
					MoreBills.Add(String(NumberOfAccounts - AccountsInHeader));
				EndIf;
				TitleLines.Add(StrConcat(MoreBills, " "));
			EndIf;
			
			AccountGroupOfAccountingObject.Title = StrConcat(TitleLines);
			AccountGroupOfAccountingObject.TitleTextColor = StyleColors.HyperlinkColor;
		EndIf;
	EndIf;
	
EndProcedure

#Region ServerSideEventHandlersForFormElements

&AtServer
Procedure ChartOfAccountsWhenChangedOnServer()
	
	FillInInvoicesOfAccountingObject("Dr");
	FillInInvoicesOfAccountingObject("Cr");
	
	FillInProcedureForApplyingSetting();
		
	GenerateCorrespondenceSettingsLink();
	
EndProcedure

&AtServer
Procedure ConfiguringGenerationOfTransactionsWhenChangesAreMadeOnServer()
	
	DivisionIntoShortTermLongTermAssetsAndLiabilities = Common.ObjectAttributeValue(
		Record.PostingGenerationSetting, "DivisionIntoShortTermLongTermAssetsAndLiabilities");
		
	If Not DivisionIntoShortTermLongTermAssetsAndLiabilities Then
		LongTermDr = False;
		LongTermCr = False;
	EndIf;
	
	FillInInvoicesOfAccountingObject("Dr");
	FillInInvoicesOfAccountingObject("Cr");
	
	FillInProcedureForApplyingSetting();
		
	GenerateCorrespondenceSettingsLink();
	
	FormControl(ThisObject);
	
EndProcedure

&AtServer
Procedure AccountingObjectOnChangeServer(DrCr)
	
	ThisObject["DescriptionOfAccountingObject_" + DrCr] = Enums.DeleteFinancialAccountingObjects.DescriptionOfFinancialAccountingObject(
		Record["AccountingObject" + DrCr], True);
	
	If Not DivisionIntoShortTermLongTermAssetsAndLiabilities
	 Or Not ValueIsFilled(ThisObject["DescriptionOfAccountingObject_" + DrCr])
	 Or Not ThisObject["DescriptionOfAccountingObject_" + DrCr].AllocationOfLongTermAssetsAndLiabilities Then
		ThisObject["LongTerm" + DrCr] = False;
	EndIf;
	
	If Not ValueIsFilled(Record["AccountingObject" + DrCr])
	   And ThisObject["InvoiceFromObjectSettings" + DrCr] Then
		ThisObject["InvoiceFromObjectSettings" + DrCr] = False;
	EndIf;
	
	FillInInvoicesOfAccountingObject(DrCr);
	FillInProcedureForApplyingSetting();
	
	GenerateCorrespondenceSettingsLink();
	InitializeSelectionComposersByAccountingObject(DrCr);
	InitializeComposerForExtdimensionFillSettings();
	
	FormControl(ThisObject);
	
EndProcedure

&AtServer
Procedure LongTermWhenChangingOnServer(DrCr)
	
	FillInInvoicesOfAccountingObject(DrCr);
	FillInProcedureForApplyingSetting();
		
	GenerateCorrespondenceSettingsLink();

EndProcedure

&AtServer
Procedure InvoiceFromObjectSettingsWhenChangedOnServer(DrCr)
	
	If ThisObject["InvoiceFromObjectSettings" + DrCr] Then
		Record["GLAccount" + DrCr] = Undefined;
		AccountForChangesToServer(DrCr);
	EndIf;
	
	FormControl(ThisObject);
	
EndProcedure

&AtServer
Procedure AccountForChangesToServer(DrCr)
	
	UpdateExtdimensionFillingSettings = False;
	If DrCr = "Dr" Then
		If Record.GLAccountDr <> GLAccountDr Then
			Record.CustomSettingOfExtdimensionFillingDr = False;
			UpdateExtdimensionFillingSettings = True;
			GLAccountDr = Record.GLAccountDr;
		EndIf;
	Else
		If Record.GLAccountCr <> GLAccountCr Then
			Record.CustomSettingOfExtdimensionFillingCr = False;
			UpdateExtdimensionFillingSettings = True;
			GLAccountCr = Record.GLAccountCr;
		EndIf;
	EndIf;
	
	If UpdateExtdimensionFillingSettings Then
		FillInExtdimensionFillSettings(DrCr);
		FillInStateOfExtdimensionFillSettings(DrCr);
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomSettingOfExtdimensionFillingWhenServerChanges(DrCr)
	FillInStateOfExtdimensionFillSettings(DrCr);
EndProcedure

&AtServer
Procedure IsNotReflectedInAccountingAccountsWhenChangesAreMadeOnServer()
	
	If Record.ItIsNotReflectedInTheAccounts Then
		InvoiceFromObjectSettingsDr = 0;
		InvoiceFromObjectSettingsCr = 0;
		Record.GLAccountDr = Undefined;
		Record.GLAccountCr = Undefined;
		AccountForChangesToServer("Dr");
		AccountForChangesToServer("Cr");
		Record.ManualSpecificationOfEntry = False;
		Record.InvertTheResourceSign = False;
	EndIf;
	
	FormControl(ThisObject);
EndProcedure

&AtServer
Procedure InvertResourceSignWhenChangingOnServer()
	FillInStateOfExtdimensionFillSettings("Dr");
	FillInStateOfExtdimensionFillSettings("Cr");
	
EndProcedure

#EndRegion

#Region GeneralMethodsOfAdditionalSelection

&AtServer
Procedure SettingsOfSelectionsInRegisterEntry(RegisterRecord, DrCr)
	
	If DrCr = "Dr" Then
		SettingsComposer = SettingsComposerSelectsDrAccountingObject;
	Else
		SettingsComposer = SettingsComposerSelectsCRAccountingObject;
	EndIf;
	
	RegisterRecord["ThereIsAdditionalSelection" + DrCr] = SettingsComposer.Settings.Filter.Items.Count() > 0;
	If RegisterRecord["ThereIsAdditionalSelection" + DrCr] Then
		RegisterRecord["AdditionalSelection" + DrCr] = New ValueStorage(SettingsComposer.Settings);
	Else
		RegisterRecord["AdditionalSelection" + DrCr] = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeSelectionComposersByAccountingObject(DrCr)
	
	If DrCr = "Dr" Then
		AccountingObject = Record.AccountingObjectDr;
		SettingsComposer = SettingsComposerSelectsDrAccountingObject;
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObject_Dr;
	Else
		AccountingObject = Record.AccountingObjectCr;
		SettingsComposer = SettingsComposerSelectsCRAccountingObject;
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObject_Cr;
	EndIf;
	
	If Not ValueIsFilled(AccountingObject) Then
		Return;
	EndIf;
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	
	MotionSelectionFields = MotionSelectionFields(DescriptionOfAccountingObject_.DataSource);
	
	If ValueIsFilled(DescriptionOfAccountingObject_.DataSource) Then
		QueryText = RequestTextForRegisterData(DescriptionOfAccountingObject_.DataSource, MotionSelectionFields);
		DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema);
		DataSet.Query = QueryText;
	EndIf;
	
	For Each KeyAndValue In MotionSelectionFields Do
		FieldDetails = KeyAndValue.Value; // See FinancialAccountingByBalanceSheetRegisterData.DescriptionOfDataSourceField
		NewField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewField.Field = KeyAndValue.Key;
		NewField.DataPath = FieldDetails.DataPath;
		NewField.Title = FieldDetails.Title;
	EndDo;
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema));
	
	Filter = SettingsComposer.FixedSettings.Filter;
	Filter.Items.Clear();
	
	If TypeOf(DescriptionOfAccountingObject_.Filterdata_) = Type("Array") Then
		
		OrGroup = DataCompositionClientServer.AddSelectionGroup(
					Filter.Items,
					DataCompositionFilterItemsGroupType.OrGroup);
		
		For Each SelectionElementOR In DescriptionOfAccountingObject_.Filterdata_ Do
			
			If SelectionElementOR.Count() > 1 Then
				GroupForAddingSelections = DataCompositionClientServer.AddSelectionGroup(
					OrGroup.Items,
					DataCompositionFilterItemsGroupType.AndGroup);
			Else
				GroupForAddingSelections = OrGroup;
			EndIf;
			
			For Each FilterElement In SelectionElementOR Do
				DataCompositionClientServer.AddFilter(
					GroupForAddingSelections, 
					FilterElement.Key,
					FilterElement.Value);
			EndDo;
		EndDo;
	ElsIf TypeOf(DescriptionOfAccountingObject_.Filterdata_) = Type("Map") Then
		For Each FilterElement In DescriptionOfAccountingObject_.Filterdata_ Do
			DataCompositionClientServer.AddFilter(
				Filter, 
				FilterElement.Key,
				FilterElement.Value);
		EndDo;
	EndIf;
	
	If DrCr = "Dr" Then
		DataSourceDrAccountingObject = "";
		PresentationOfFixedSelectionObjectOfAccountingDr = "";
		MetadataObject = Metadata.AccumulationRegisters.Find(DescriptionOfAccountingObject_.DataSource);
		If MetadataObject <> Undefined Then
			DataSourceDrAccountingObject = MetadataObject.Synonym;
			PresentationOfFixedSelectionObjectOfAccountingDr = String(SettingsComposer.FixedSettings.Filter);
		EndIf;
	Else
		DataSourceCrAccountingObject = "";
		PresentationOfFixedSelectionCrAccountingObject = "";
		MetadataObject = Metadata.AccumulationRegisters.Find(DescriptionOfAccountingObject_.DataSource);
		If MetadataObject <> Undefined Then
			DataSourceCrAccountingObject = MetadataObject.Synonym;
			PresentationOfFixedSelectionCrAccountingObject = String(SettingsComposer.FixedSettings.Filter);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function SourcesOfExtdimension(RegisterName) 
	
	If Not ValueIsFilled(RegisterName) Then
		Return New Structure();
	Else
		Return FinancialAccountingByFinancialRegisterData.SourcesOfFinancialRegisterAnalytics(RegisterName);
	EndIf;
	
EndFunction

&AtServer
Function MotionSelectionFields(RegisterName)
	
	If Not ValueIsFilled(RegisterName) Then
		Return New Structure();
	Else
		Return FinancialAccountingByFinancialRegisterData.DescriptionOfFinancialRegisterFields(RegisterName);
	EndIf;
	
EndFunction

&AtServer
Function RequestTextForRegisterData(RegisterName, MotionSelectionFields = Undefined)
	
	RegisterMetadata = Metadata.AccumulationRegisters.Find(RegisterName);
	
	If RegisterMetadata = Undefined Then
		Return "";
	EndIf;
	
	If MotionSelectionFields = Undefined Then
		MotionSelectionFields = MotionSelectionFields(RegisterName);
	EndIf;
	
	FullRegisterName = RegisterMetadata.FullName();
	
	QueryText = 
	"SELECT
	|	&SelectionFields1
	|FROM
	|	&RegisterTableName AS RegisterTable
	|{WHERE
	|	&FilterFields
	|}";
	
	SelectionFields1 = New Array();
	FilterFields = New Array;
	PrimitiveTypes = New TypeDescription("String, Number, Date, Boolean, Type, Undefined, UUID");
	
	For Each KeyAndValue In MotionSelectionFields Do
		FieldName = KeyAndValue.Key;
		FieldDetails = KeyAndValue.Value; 
		TypePrimitive = PrimitiveTypes.ContainsType(FieldDetails.Type.Types()[0]);
		SelectionFields1.Add(FieldDetails.DataPath + " AS " + FieldName); //@query-part
		FilterFields.Add(FieldDetails.DataPath + ?(TypePrimitive, "", ".*") + " AS " + FieldName); //@query-part
		If FieldName = "Recorder" Then
			SelectionFields1.Add("VALUETYPE(" + FieldDetails.DataPath + ") AS TypeOfRegistrar"); //@query-part
		EndIf;
	EndDo;
	
	Separator = "," + Chars.LF +Chars.Tab;
	
	QueryText = StrReplace(QueryText, "&SelectionFields1", StrConcat(SelectionFields1, Separator));
	QueryText = StrReplace(QueryText, "&FilterFields", StrConcat(FilterFields, Separator));
	QueryText = StrReplace(QueryText, "&RegisterTableName", FullRegisterName);
	
	Return QueryText;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetGroupTitleAdditionalSelectionAccountingObject(Form, DrCr)
	
	If DrCr = "Dr" Then
		Item = Form.Items.AdditionalSelectionGroupDtAccountingObject;
		SettingsComposer = Form.SettingsComposerSelectsDrAccountingObject;
	Else
		Item = Form.Items.AdditionalSelectionGroupKtAccountingObject;
		SettingsComposer = Form.SettingsComposerSelectsCRAccountingObject;
	EndIf;
	
	FilterPresentation = String(SettingsComposer.Settings.Filter);
	If FilterPresentation = "" Then
		Item.Title = NStr("vi = 'Không có lọc bổ sung';
							|ru = 'Без дополнительного отбора';
							|en = 'Without additional filter'; fa = 'بدون فیلتر تکمیلی';
							|it = 'Без дополнительного отбора';
							|pl = 'Bez dodatkowego filtru';
							|tr = 'Ek filtre olmadan'");
	Else
		Item.Title = FilterPresentation;
	EndIf;
	
EndProcedure

#EndRegion

#Region ExtdimensionFillTableHandlers

&AtClient
Procedure FillingExtdimensionWhenLineIsActivated(Item, DrCr)
	
	If DrCr = "Dr" Then
		CurrentData = Items.FillInExtraDimensionDr.CurrentData;
		SpecifiedValueIsExtdimension = Items.FillInExtraDimensionDrSpecifiedValueIsExtdimension;
	Else
		CurrentData = Items.FillInExtraDimensionCr.CurrentData;
		SpecifiedValueIsExtdimension = Items.FillInExtraDimensionCrSpecifiedValueIsExtdimension;
	EndIf;
	
	If CurrentData <> Undefined Then
		SpecifiedValueIsExtdimension.TypeRestriction = CurrentData.ExtdimensionValueType;
	EndIf;
	
EndProcedure

&AtClient
Procedure PresentationOfExpressionStartOfSelection(Item, ChoiceData, StandardProcessing, DrCr)
	
	If DrCr = "Dr" Then
		CurrentData = Items.FillInExtraDimensionDr.CurrentData;
	Else
		CurrentData = Items.FillInExtraDimensionCr.CurrentData;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExtDimensionType", CurrentData.ExtDimensionType);
	FormParameters.Insert("AddressOfDataCompositionSchema", ExtdimensionDataLayoutAddress);
	FormParameters.Insert("CurrentExpression", CurrentData.ExpressionOfExtdimensionFilling);
	
	OpenForm("CommonForm.SelectExtraDimensionFillingField", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure PresentationOfExpression(Item, StandardProcessing, DrCr)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ExpressionPresentationSelectionProcessing(Item, ValueSelected, StandardProcessing, DrCr)
	
	If DrCr = "Dr" Then
		SettingsTableElement = Items.FillInExtraDimensionDr;
	Else
		SettingsTableElement = Items.FillInExtraDimensionCr;
	EndIf;
	
	CurrentData = SettingsTableElement.CurrentData;
	
	StandardProcessing = False;
	Modified = True;
	CurrentData.ExpressionOfExtdimensionFilling = ValueSelected;
	CurrentData.ThereAreExtdimensionFillingIssues = False;
	
	FillInPresentationOfExpressionInLineOnClient(CurrentData);
	
	SettingsTableElement.EndEditRow(False);
	
EndProcedure

&AtClient
Procedure TheSpecifiedValueWhenChanging(Item, DrCr)
	
	If DrCr = "Dr" Then
		CurrentData = Items.FillInExtraDimensionDr.CurrentData;
	Else
		CurrentData = Items.FillInExtraDimensionCr.CurrentData;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.SpecifiedValueIsExtdimension) Then
		CurrentData.ThereAreExtdimensionFillingIssues = True;
	ElsIf Not CurrentData.ExtdimensionValueType.ContainsType(TypeOf(CurrentData.SpecifiedValueIsExtdimension)) Then
		CurrentData.ThereAreExtdimensionFillingIssues = True;
	Else
		CurrentData.ThereAreExtdimensionFillingIssues = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillingMethodOnChange(Item, DrCr)
	
	If DrCr = "Dr" Then
		CurrentData = Items.FillInExtraDimensionDr.CurrentData;
	Else
		CurrentData = Items.FillInExtraDimensionCr.CurrentData;
	EndIf;
	
	If CurrentData.MethodOfFillingExtdimension 
			= PredefinedValue("Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister") Then
		CurrentData.ThereAreExtdimensionFillingIssues = Not ValueIsFilled(CurrentData.ExpressionOfExtdimensionFilling);
		CurrentData.SpecifiedValueIsExtdimension = Undefined;
	ElsIf CurrentData.MethodOfFillingExtdimension 
			= PredefinedValue("Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue") Then
		CurrentData.ThereAreExtdimensionFillingIssues = Not ValueIsFilled(CurrentData.SpecifiedValueIsExtdimension);
		CurrentData.ExpressionOfExtdimensionFilling = "";
		CurrentData.RepresentationOfTheExpression = "";
	ElsIf CurrentData.MethodOfFillingExtdimension
			= PredefinedValue("Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill") Then
		CurrentData.ThereAreExtdimensionFillingIssues = False;
		CurrentData.SpecifiedValueIsExtdimension = Undefined;
		CurrentData.ExpressionOfExtdimensionFilling = "";
		CurrentData.RepresentationOfTheExpression = "";
	EndIf;
	
EndProcedure

#EndRegion

#Region CommonMethodsForSettingUpExtdimensionFilling

&AtServer
Procedure ExtdimensionFillSettingsInRegisterEntry(RegisterRecord, DrCr)
	
	If DrCr = "Dr" Then
		SettingsTable = FillInExtraDimensionDr;
		CustomSettingOfExtdimensionFilling = RegisterRecord.CustomSettingOfExtdimensionFillingDr;
	Else
		SettingsTable = FillInExtraDimensionCr;
		CustomSettingOfExtdimensionFilling = RegisterRecord.CustomSettingOfExtdimensionFillingCr;
	EndIf;
	
	ExtDimensionNumber = 1;
	If CustomSettingOfExtdimensionFilling Then
		For Each TableRow In SettingsTable Do
			RegisterRecord["ExtDimensionType" + DrCr + ExtDimensionNumber] = TableRow.ExtDimensionType;
			RegisterRecord["MethodOfFillingExtdimension" + DrCr + ExtDimensionNumber] = TableRow.MethodOfFillingExtdimension;
			If TableRow.MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister Then
				RegisterRecord["ExpressionOfExtdimensionFilling" + DrCr + ExtDimensionNumber] = TableRow.ExpressionOfExtdimensionFilling;
			EndIf;
			If TableRow.MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue Then
				RegisterRecord["SpecifiedValueIsExtdimension" + DrCr + ExtDimensionNumber] = TableRow.SpecifiedValueIsExtdimension;
			EndIf;
			ExtDimensionNumber = ExtDimensionNumber + 1;
		EndDo;
	EndIf;
	
	For ExtdimensionRoomsForCleaning = ExtDimensionNumber To 3 Do
		RegisterRecord["ExtDimensionType" + DrCr + ExtDimensionNumber] = Undefined;
		RegisterRecord["MethodOfFillingExtdimension" + DrCr + ExtDimensionNumber] = Undefined;
		RegisterRecord["ExpressionOfExtdimensionFilling"+ DrCr + ExtDimensionNumber] = Undefined;
		RegisterRecord["SpecifiedValueIsExtdimension"+ DrCr + ExtDimensionNumber] = Undefined;
		ExtdimensionRoomsForCleaning = ExtdimensionRoomsForCleaning + 1;
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeComposerForExtdimensionFillSettings()
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	
	If ValueIsFilled(DescriptionOfAccountingObject_Dr) Then
		SourcesOfExtdimensionObjectOfDrAccounting = SourcesOfExtdimension(DescriptionOfAccountingObject_Dr.DataSource);
		DataSetDrAccountingObject = DataCompositionServer.AddEmptyDataSet(
			                          DataCompositionSchema,
			                          Type("DataCompositionSchemaDataSetObject"),
			                          "AccountingObjectDr");
		
		DrAccountingObjectFolder = DataSetDrAccountingObject.Fields.Add(Type("DataCompositionSchemaDataSetFieldFolder"));
		DrAccountingObjectFolder.DataPath = "AccountingObjectDr";
		DrAccountingObjectFolder.Title = NStr("vi = 'Đối tượng kế toán Nợ';
												|ru = 'Объект учета Дт';
												|en = 'Dr accounting object'; fa = 'شیء حسابداری بدهکار';
												|it = 'Объект учета Дт';
												|pl = 'Obiekt ewidencji Wn';
												|tr = 'Borç muhasebe nesnesi'");
		For Each KeyAndValue In SourcesOfExtdimensionObjectOfDrAccounting Do
			DescriptionOfSourceOfExtdimension = KeyAndValue.Value;
			Field = DataSetDrAccountingObject.Fields.Add(Type("DataCompositionSchemaDataSetField"));
			Field.Field = KeyAndValue.Key;
			Field.DataPath = "AccountingObjectDr." + KeyAndValue.Key;
			Field.Title = DrAccountingObjectFolder.Title + "." + DescriptionOfSourceOfExtdimension.Title;
			Field.ValueType = DescriptionOfSourceOfExtdimension.Type;
		EndDo;
	EndIf;
	
	If ValueIsFilled(DescriptionOfAccountingObject_Cr) Then
		SourcesOfExtdimensionObjectOfCrAccounting = SourcesOfExtdimension(DescriptionOfAccountingObject_Cr.DataSource);
		DataSetCrAccountingObject = DataCompositionServer.AddEmptyDataSet(
			                           DataCompositionSchema, 
			                           Type("DataCompositionSchemaDataSetObject"),
			                           "AccountingObjectCr");
		CrAccountingObjectFolder = DataSetCrAccountingObject.Fields.Add(Type("DataCompositionSchemaDataSetFieldFolder"));
		CrAccountingObjectFolder.DataPath = "AccountingObjectCr";
		CrAccountingObjectFolder.Title = NStr("vi = 'Đối tượng kế toán Có';
												|ru = 'Объект учета Кт';
												|en = 'Cr accounting object'; fa = 'شیء حسابداری بستانکار';
												|it = 'Объект учета Кт';
												|pl = 'Obiekt ewidencji Ma';
												|tr = 'Alacak muhasebe nesnesi'");
		For Each KeyAndValue In SourcesOfExtdimensionObjectOfCrAccounting Do
			DescriptionOfSourceOfExtdimension = KeyAndValue.Value;
			Field = DataSetCrAccountingObject.Fields.Add(Type("DataCompositionSchemaDataSetField"));
			Field.Field = KeyAndValue.Key;
			Field.DataPath = "AccountingObjectCr." + KeyAndValue.Key;
			Field.Title = CrAccountingObjectFolder.Title + "." + DescriptionOfSourceOfExtdimension.Title;
			Field.ValueType = DescriptionOfSourceOfExtdimension.Type;
		EndDo;
	EndIf;
	
	ExtdimensionDataLayoutAddress = PutToTempStorage(DataCompositionSchema, UUID);
	SettingsComposerExtdimensionFilling.Initialize(New DataCompositionAvailableSettingsSource(ExtdimensionDataLayoutAddress));
	
	FillInStateOfExtdimensionFillSettings("Dr");
	FillInStateOfExtdimensionFillSettings("Cr");
	
EndProcedure

&AtServer
Procedure FillInExtdimensionFillSettings(DrCr)
	
	If DrCr = "Dr" Then
		TableFillingExtdimension = FillInExtraDimensionDr;
		CustomSettingOfExtdimensionFilling = Record.CustomSettingOfExtdimensionFillingDr;
		GLAccount = Record.GLAccountDr;
	Else
		TableFillingExtdimension = FillInExtraDimensionCr;
		CustomSettingOfExtdimensionFilling = Record.CustomSettingOfExtdimensionFillingCr;
		GLAccount = Record.GLAccountCr;
	EndIf;
	
	TableFillingExtdimension.Clear();
	
	AccountProperties = FinancialAccountingServerCached.AccountProperties(GLAccount);
	
	If CustomSettingOfExtdimensionFilling Then
	
		For ExtDimensionNumber = 1 To 3 Do
			
			If Not ValueIsFilled(Record["ExtDimensionType" + DrCr + ExtDimensionNumber]) Then
				Continue;
			EndIf;
			
			NewSettingsRow = TableFillingExtdimension.Add();
			NewSettingsRow.ExtDimensionType = Record["ExtDimensionType" + DrCr + ExtDimensionNumber];
			NewSettingsRow.ExtdimensionValueType = AccountProperties["ExtDimensionType" + ExtDimensionNumber + "ValueType"];
			NewSettingsRow.MethodOfFillingExtdimension = Record["MethodOfFillingExtdimension" + DrCr + ExtDimensionNumber];
			NewSettingsRow.ExpressionOfExtdimensionFilling = Record["ExpressionOfExtdimensionFilling" + DrCr + ExtDimensionNumber];
			NewSettingsRow.SpecifiedValueIsExtdimension = Record["SpecifiedValueIsExtdimension" + DrCr + ExtDimensionNumber];
			
		EndDo;
	
	Else
		
		For ExtDimensionNumber = 1 To AccountProperties.ExtDimensionCount Do
			
			NewSettingsRow = TableFillingExtdimension.Add();
			NewSettingsRow.ExtDimensionType = AccountProperties["ExtDimensionType" + ExtDimensionNumber];
			NewSettingsRow.ExtdimensionValueType = AccountProperties["ExtDimensionType" + ExtDimensionNumber + "ValueType"];
			NewSettingsRow.MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInStateOfExtdimensionFillSettings(DrCr)
	
	If DrCr = "Dr" Then
		TableOfExtdimensionFillingSettings = FillInExtraDimensionDr;
		CustomSettingOfExtdimensionFilling = Record.CustomSettingOfExtdimensionFillingDr;
	Else
		TableOfExtdimensionFillingSettings = FillInExtraDimensionCr;
		CustomSettingOfExtdimensionFilling = Record.CustomSettingOfExtdimensionFillingCr;
	EndIf;
	
	For Each SettingsString In TableOfExtdimensionFillingSettings Do
		If CustomSettingOfExtdimensionFilling Then
			FillStateOfManualExtdimensionFillSetting(SettingsString);
		Else
			FillInAutoFillStateOfExtdimension(SettingsString, DrCr);
		EndIf;
		FillInPresentationOfExpressionInRowOnServer(SettingsString);
	EndDo;
	
	SetGroupHeaderExtdimensionSettings(DrCr);
	
EndProcedure

&AtServer
Procedure FillInAutoFillStateOfExtdimension(SettingsString, DrCr)
	
	SettingsString.ExpressionOfExtdimensionFilling = "";
	SettingsString.MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister;
	
	DescriptionsOfAccountingObjects = New ValueList;
	If DrCr = "Dr" Then
		If ValueIsFilled(DescriptionOfAccountingObject_Dr) And Not IsBlankString(DescriptionOfAccountingObject_Dr.DataSource) Then
			DescriptionsOfAccountingObjects.Add(DescriptionOfAccountingObject_Dr, "AccountingObjectDr");
		ElsIf ValueIsFilled(DescriptionOfAccountingObject_Cr) Then
			DescriptionsOfAccountingObjects.Add(DescriptionOfAccountingObject_Cr, "AccountingObjectCr");
		EndIf;
	ElsIf ValueIsFilled(DescriptionOfAccountingObject_Cr) And Not IsBlankString(DescriptionOfAccountingObject_Cr.DataSource) Then
		DescriptionsOfAccountingObjects.Add(DescriptionOfAccountingObject_Cr, "AccountingObjectCr");
	ElsIf ValueIsFilled(DescriptionOfAccountingObject_Dr) Then
		DescriptionsOfAccountingObjects.Add(DescriptionOfAccountingObject_Dr, "AccountingObjectDr");
	EndIf;
	
	For Each ListItem In DescriptionsOfAccountingObjects Do
		PossibleFields = FinancialAccountingByFinancialRegisterData.PossibleExtdimensionFields(
			               SettingsString.ExtdimensionValueType, ListItem.Value, ListItem.Presentation);
		If PossibleFields.Count() > 0 Then
			SettingsString.ExpressionOfExtdimensionFilling = PossibleFields[0].Value;
			Break;
		EndIf;
	EndDo;
	
	SettingsString.ThereAreExtdimensionFillingIssues = Not ValueIsFilled(SettingsString.ExpressionOfExtdimensionFilling);
	
EndProcedure

&AtServer
Procedure FillStateOfManualExtdimensionFillSetting(SettingsString)
	
	ExpressionOfExtdimensionFilling = SettingsString.ExpressionOfExtdimensionFilling;
	SpecifiedValueIsExtdimension = SettingsString.SpecifiedValueIsExtdimension;
	
	If SettingsString.MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister Then
		DataCompositionField = New DataCompositionField(ExpressionOfExtdimensionFilling);
		AvailableSelectionField = SettingsComposerExtdimensionFilling.Settings.SelectionAvailableFields.FindField(DataCompositionField);
		If AvailableSelectionField = Undefined Then
			SettingsString.ThereAreExtdimensionFillingIssues = True;
		EndIf;
	ElsIf SettingsString.MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue Then
		DescriptionOfExtdimensionTypes = SettingsString.ExtdimensionValueType; // TypeDescription - 
		If Not ValueIsFilled(SettingsString.SpecifiedValueIsExtdimension) Then
			SettingsString.ThereAreExtdimensionFillingIssues = True;
		ElsIf  Not DescriptionOfExtdimensionTypes.ContainsType(TypeOf(SpecifiedValueIsExtdimension)) Then
			SettingsString.ThereAreExtdimensionFillingIssues = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPresentationOfExpressionInLineOnClient(SettingString)
	
	DataCompositionField = New DataCompositionField(SettingString.ExpressionOfExtdimensionFilling);
	AvailableField = SettingsComposerExtdimensionFilling.Settings.SelectionAvailableFields.FindField(DataCompositionField);
	If AvailableField = Undefined Then
		SettingString.RepresentationOfTheExpression = SettingString.ExpressionOfExtdimensionFilling;
	Else
		SettingString.RepresentationOfTheExpression = AvailableField.Title;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPresentationOfExpressionInRowOnServer(SettingString)
	
	DataCompositionField = New DataCompositionField(SettingString.ExpressionOfExtdimensionFilling);
	AvailableField = SettingsComposerExtdimensionFilling.Settings.SelectionAvailableFields.FindField(DataCompositionField);
	If AvailableField = Undefined Then
		SettingString.RepresentationOfTheExpression = SettingString.ExpressionOfExtdimensionFilling;
	Else
		SettingString.RepresentationOfTheExpression = AvailableField.Title;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetGroupHeaderExtdimensionSettings(DrCr)
	
	If DrCr = "Dr" Then
		SettingsTable1 = FillInExtraDimensionDr;
		CustomSettingOfExtdimensionFilling = Record.CustomSettingOfExtdimensionFillingDr;
		ExtdimensionFillingSettingsGroup = Items.ExtdimensionFillingSettingsGroupDr;
	Else
		SettingsTable1 = FillInExtraDimensionCr;
		CustomSettingOfExtdimensionFilling = Record.CustomSettingOfExtdimensionFillingCr;
		ExtdimensionFillingSettingsGroup = Items.ExtdimensionFillingSettingsGroupCr;
	EndIf;
	
	SearchResult = SettingsTable1.FindRows(New Structure("ThereAreExtdimensionFillingIssues", True));
	ThereAreExtdimensionFillingIssues = (SearchResult.Count() > 0);
	
	If CustomSettingOfExtdimensionFilling Then
		If ThereAreExtdimensionFillingIssues Then
			ExtdimensionFillingSettingsGroup.Title = NStr("vi = 'Tùy chỉnh tự tạo khoản mục (có lỗi)';
															|ru = 'Пользовательская настройка субконто (есть ошибки)';
															|en = 'Extra dimension user setting (there are errors)'; fa = 'Extra dimension user setting (there are errors)';
															|it = 'Пользовательская настройка субконто (есть ошибки)';
															|pl = 'Ustawienie użytkownika subkonto (są błędy)';
															|tr = 'Kullanıcı ayarları ekstra boyut (hatalar var)'");
			ExtdimensionFillingSettingsGroup.TitleTextColor = StyleColors.OverdueDataColor;
		Else
			ExtdimensionFillingSettingsGroup.Title = NStr("vi = 'Tùy chỉnh tự tạo khoản mục';
															|ru = 'Пользовательская настройка субконто';
															|en = 'Extra dimension user setting'; fa = 'Extra dimension user setting';
															|it = 'Пользовательская настройка субконто';
															|pl = 'Ustawienie użytkownika subkonto';
															|tr = 'Kullanıcı ayarları ekstra boyut'");
			ExtdimensionFillingSettingsGroup.TitleTextColor = StyleColors.HyperlinkColor;
		EndIf;
	Else
		If ThereAreExtdimensionFillingIssues Then
			ExtdimensionFillingSettingsGroup.Title = NStr("vi = 'Yêu cầu tùy chỉnh tự tạo';
															|ru = 'Требуется пользовательская настройка';
															|en = 'User setting is required'; fa = 'User setting is required';
															|it = 'Требуется пользовательская настройка';
															|pl = 'Wymagane jest ustawienie użytkownika';
															|tr = 'Kullanıcı ayarları gerekiyor'");
			ExtdimensionFillingSettingsGroup.TitleTextColor = StyleColors.OverdueDataColor;
		Else
			ExtdimensionFillingSettingsGroup.Title = NStr("vi = 'Khoản mục được điền tự động';
															|ru = 'Субконто заполняются автоматически';
															|en = 'Extra dimensions are populated automatically'; fa = 'ابعاد اضافی به‌طور خودکار تکمیل می‌شوند';
															|it = 'Субконто заполняются автоматически';
															|pl = 'Subkonto jest wypełniane automatycznie';
															|tr = 'Ekstra boyut otomatik doldurulur'");
			ExtdimensionFillingSettingsGroup.TitleTextColor = StyleColors.HyperlinkColor;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#EndRegion


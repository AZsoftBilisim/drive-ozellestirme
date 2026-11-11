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
	GLAccount = Parameters.GLAccount;
	
	AddressOfDataCompositionSchema = PutToTempStorage(Undefined, UUID);
	
	ChartsOfCharacteristicTypes.AssetLiabilityItems.InitializeSettingsComposerWithDataSource(
		SettingsComposer,
		Parameters.DataSource,,
		AddressOfDataCompositionSchema);
	
	FilterOfSettings = 
		DataProcessors.SettingUpFinancialAccountingAccounts.SelectingExtdimensionFillingSettings(
			ChartOfAccounts, 
			PostingGenerationSetting,
			AccountingObject,
			GLAccount);
	
	SettingsTable =
		DataProcessors.SettingUpFinancialAccountingAccounts.ExtraDimensionFillingSettings(
			FilterOfSettings,
			SettingsComposer);
			
	UserSetting = SettingsTable[0].UserSetting;
	
	FillInExtdimensionFillSettings(SettingsTable);
	
	EstablishAvailableWaysToFillExtdimension();
	
	ManagingAccessibility();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not UserSetting Then
		Return;
	EndIf;
	
	For Each TableRow In ExtraDimensionFillingSettings Do
		
		If TableRow.MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister
			And Not ValueIsFilled(TableRow.ExpressionOfExtdimensionFilling) Then
			Common.MessageToUser(
				StrTemplate(NStr("vi = 'Chưa điền hiển thị điền khoản mục ""%1"".';
								|ru = 'Не заполнено выражение заполнения субконто ""%1"".';
								|en = 'Population expression is required for the ""%1"" extra dimension.'; fa = 'Population expression is required for the ""%1"" extra dimension.';
								|it = 'L''espressione di compilazione del subconto ""%1"" non compilata.';
								|pl = 'Nie wypełniono wyrażenia wypełnienia subkonta ""%1"".';
								|tr = '""%1"" ekstra boyut değer ifadesi doldurulmadı'"), TableRow.ExtDimensionType), , 
				"ExtraDimensionFillingSettings", , Cancel);
		EndIf;
		
		If TableRow.MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue
			And Not ValueIsFilled(TableRow.SpecifiedValueIsExtdimension) Then
			Common.MessageToUser(
				StrTemplate(NStr("vi = 'Chưa điền giá trị khoản mục ""%1"".';
								|ru = 'Не заполнено значение субконто ""%1"".';
								|en = 'Value is required for the ""%1"" extra dimension.'; fa = 'Value is required for the ""%1"" extra dimension.';
								|it = 'Valore del subconto ""%1"" non compilato.';
								|pl = 'Nie wypełniono wartości subkonta ""%1"".';
								|tr = '""%1"" ekstra boyut değeri doldurulmadı'"), TableRow.ExtDimensionType), , 
				"ExtraDimensionFillingSettings", , Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure GLAccountClick(Item, StandardProcessing)
	
	ShowValue(, GLAccount);
	
EndProcedure

&AtClient
Procedure UserSettingOnChange(Item)
	
	UserSettingOnChangeServer();
	
EndProcedure

&AtClient
Procedure ExtraDimensionFillingSettingsOnActivateRow(Item)
	
	If Items.ExtraDimensionFillingSettings.CurrentData <> Undefined Then
		Items.SpecifiedValueIsExtdimension.TypeRestriction = Items.ExtraDimensionFillingSettings.CurrentData.ExtdimensionValueType;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsForFillingInTheSubcontoRepresentationOfTheExpressionStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.ExtraDimensionFillingSettings.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExtDimensionType", CurrentData.ExtDimensionType);
	FormParameters.Insert("AddressOfDataCompositionSchema", AddressOfDataCompositionSchema);
	FormParameters.Insert("CurrentExpression", CurrentData.ExpressionOfExtdimensionFilling);
	FormParameters.Insert("HideAdditionalAttributes", True);
	
	OpenForm("CommonForm.SelectExtraDimensionFillingField", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure SettingsForFillingInTheSubcontoRepresentationOfTheExpressionClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure SettingsForFillingInTheSubcontoExpressionRepresentationSelectionProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	Modified = True;
	CurrentData = Items.ExtraDimensionFillingSettings.CurrentData;
	CurrentData.ExpressionOfExtdimensionFilling = ValueSelected;
	CurrentData.ThereAreExtdimensionFillingIssues = False;
	FillInPresentationOfExpressionInLine(Items.ExtraDimensionFillingSettings.CurrentRow);
	Items.ExtraDimensionFillingSettings.EndEditRow(False);
	
EndProcedure

&AtClient
Procedure TheSpecifiedValueWhenChanging(Item)
	
	CurrentData = Items.ExtraDimensionFillingSettings.CurrentData;
	If ValueIsFilled(CurrentData.SpecifiedValueIsExtdimension) 
			And CurrentData.ExtdimensionValueType.ContainsType(TypeOf(CurrentData.SpecifiedValueIsExtdimension)) Then
		CurrentData.ThereAreExtdimensionFillingIssues = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillingMethodOnChange(Item)
	
	CurrentData = Items.ExtraDimensionFillingSettings.CurrentData;
	
	If CurrentData.MethodOfFillingExtdimension 
			= PredefinedValue("Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister") Then
		CurrentData.ThereAreExtdimensionFillingIssues = False;
		CurrentData.SpecifiedValueIsExtdimension = Undefined;
	ElsIf CurrentData.MethodOfFillingExtdimension 
			= PredefinedValue("Enum.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue") Then
		CurrentData.ThereAreExtdimensionFillingIssues = False;
		CurrentData.ExpressionOfExtdimensionFilling = "";
		CurrentData.RepresentationOfTheExpression = "";
	ElsIf CurrentData.MethodOfFillingExtdimension
			= PredefinedValue("Enum.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill")
		Or CurrentData.MethodOfFillingExtdimension
			= PredefinedValue("Enum.MethodsOfFinancialAccountingExtraDimensionFilling.FromCorrespondence") Then
		CurrentData.ThereAreExtdimensionFillingIssues = False;
		CurrentData.SpecifiedValueIsExtdimension = Undefined;
		CurrentData.ExpressionOfExtdimensionFilling = "";
		CurrentData.RepresentationOfTheExpression = "";
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	If CheckFilling() Then
		ShouldSaveSettingsServer();
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure Write(Command)
	If CheckFilling() Then
		ShouldSaveSettingsServer();
		Modified = False;
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInExtdimensionFillSettings(SettingsStateTable)

	SettingsStateBar = SettingsStateTable[0];
	
	ExtraDimensionFillingSettings.Clear();
	For ExtDimensionNumber = 1 To 3 Do
		If Not ValueIsFilled(SettingsStateBar["ExtDimensionType" + ExtDimensionNumber]) Then
			Continue;
		EndIf;
		NewSettingsRow = ExtraDimensionFillingSettings.Add();
		NewSettingsRow.ExtDimensionType = SettingsStateBar["ExtDimensionType" + ExtDimensionNumber];
		NewSettingsRow.ExtdimensionValueType = SettingsStateBar["ExtdimensionValueType" + ExtDimensionNumber];
		NewSettingsRow.MethodOfFillingExtdimension = SettingsStateBar["MethodOfFillingExtdimension" + ExtDimensionNumber];
		NewSettingsRow.ExpressionOfExtdimensionFilling = SettingsStateBar["ExpressionOfExtdimensionFilling" + ExtDimensionNumber];
		NewSettingsRow.SpecifiedValueIsExtdimension = SettingsStateBar["SpecifiedValueIsExtdimension" + ExtDimensionNumber];
		NewSettingsRow.ThereAreExtdimensionFillingIssues = SettingsStateBar["ThereAreExtdimensionFillingIssues" + ExtDimensionNumber];
	EndDo;
	
	FillPresentationOfExtdimensionFillExpressions();
	
EndProcedure

&AtServer
Procedure ShouldSaveSettingsServer()
	
	RecordManager = InformationRegisters.SettingsForFillingExtraDimensionOnFinancialAccountingAccounts.CreateRecordManager();
	RecordManager.ChartOfAccounts =  ChartOfAccounts;
	RecordManager.PostingGenerationSetting = PostingGenerationSetting;
	RecordManager.AccountingObject = AccountingObject;
	RecordManager.GLAccount = GLAccount;
	If Not UserSetting Then
		RecordManager.Delete();
	Else
		ExtDimensionNumber = 1;
		For Each TableRow In ExtraDimensionFillingSettings Do
			RecordManager["ExtDimensionType" + ExtDimensionNumber] = TableRow.ExtDimensionType;
			RecordManager["MethodOfFillingExtdimension" + ExtDimensionNumber] = TableRow.MethodOfFillingExtdimension;
			If TableRow.MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister Then
				RecordManager["ExpressionOfExtdimensionFilling" + ExtDimensionNumber] = TableRow.ExpressionOfExtdimensionFilling;
			EndIf;
			If TableRow.MethodOfFillingExtdimension = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue Then
				RecordManager["SpecifiedValueIsExtdimension" + ExtDimensionNumber] = TableRow.SpecifiedValueIsExtdimension;
			EndIf;
			ExtDimensionNumber = ExtDimensionNumber + 1;
		EndDo;
		For ExtdimensionRoomsForCleaning = ExtDimensionNumber To 3 Do
			RecordManager["ExtDimensionType" + ExtDimensionNumber] = Undefined;
			RecordManager["MethodOfFillingExtdimension" + ExtDimensionNumber] = Undefined;
			RecordManager["ExpressionOfExtdimensionFilling" + ExtDimensionNumber] = Undefined;
			RecordManager["SpecifiedValueIsExtdimension" + ExtDimensionNumber] = Undefined;
			ExtdimensionRoomsForCleaning = ExtdimensionRoomsForCleaning + 1;
		EndDo;
		RecordManager.Write();
	EndIf;
	
EndProcedure


&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SpecifiedValueIsExtdimension.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RepresentationOfTheExpression.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtraDimensionFillingSettings.MethodOfFillingExtdimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	FillingMethods = New ValueList();
	FillingMethods.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill);
	FillingMethods.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromCorrespondence);
	ItemFilter.RightValue = FillingMethods;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SpecifiedValueIsExtdimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ThereAreExtdimensionFillingIssues.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtraDimensionFillingSettings.MethodOfFillingExtdimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RepresentationOfTheExpression.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtraDimensionFillingSettings.MethodOfFillingExtdimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtraDimensionFillingSettings.RepresentationOfTheExpression");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheExpressionRepresentationHasProblemsFillingTheSubconto.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RepresentationOfTheExpression.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtraDimensionFillingSettings.MethodOfFillingExtdimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheExpressionRepresentationHasProblemsFillingTheSubconto.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RepresentationOfTheExpression.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtraDimensionFillingSettings.MethodOfFillingExtdimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	FillingMethods = New ValueList();
	FillingMethods.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill);
	FillingMethods.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromCorrespondence);
	ItemFilter.RightValue = FillingMethods;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SpecifiedValueIsExtdimension.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtraDimensionFillingSettings.MethodOfFillingExtdimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtraDimensionFillingSettings.SpecifiedValueIsExtdimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue =  New DataCompositionField("UserSetting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheExpressionRepresentationHasProblemsFillingTheSubconto.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RepresentationOfTheExpression.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtraDimensionFillingSettings.MethodOfFillingExtdimension");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtraDimensionFillingSettings.ExpressionOfExtdimensionFilling");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingMethod.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ThereAreExtdimensionFillingIssues.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SpecifiedValueIsExtdimension.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheExpressionRepresentationHasProblemsFillingTheSubconto.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RepresentationOfTheExpression.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue =  New DataCompositionField("UserSetting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly",  True);
	//
	
EndProcedure

&AtServer
Procedure EstablishAvailableWaysToFillExtdimension()
	
	ChoiceList = Items.FillingMethod.ChoiceList;
	ChoiceList.Clear();
	
	DescriptionOfAccountingObject_ = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObject(AccountingObject);
	
	If Not IsBlankString(DescriptionOfAccountingObject_.DataSource) Then
		ChoiceList.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromRegister);
		ChoiceList.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue);
		ChoiceList.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill);
	Else
		ChoiceList.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.FromCorrespondence);
		ChoiceList.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.SpecifiedValue);
		ChoiceList.Add(Enums.MethodsOfFinancialAccountingExtraDimensionFilling.DontFill);
	EndIf;
	
EndProcedure

&AtServer
Procedure ManagingAccessibility()
	
	Items.FormSave.Visible = UserSetting Or Items.FormSave.Visible;
	
EndProcedure

&AtServer
Procedure FillPresentationOfExtdimensionFillExpressions() 
	
	For Each TableRow In ExtraDimensionFillingSettings Do
		FillInPresentationOfExpressionInLine(TableRow.GetID());
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInPresentationOfExpressionInLine(RowID)
	
	TableRow = ExtraDimensionFillingSettings.FindByID(RowID);
	
	DataCompositionField = New DataCompositionField(TableRow.ExpressionOfExtdimensionFilling);
	AvailableField = SettingsComposer.Settings.SelectionAvailableFields.FindField(DataCompositionField);
	If AvailableField = Undefined Then
		TableRow.RepresentationOfTheExpression = TableRow.ExpressionOfExtdimensionFilling;
	Else
		TableRow.RepresentationOfTheExpression = AvailableField.Title;
	EndIf;
	
EndProcedure

&AtServer
Procedure UserSettingOnChangeServer()
	
	If Not UserSetting Then
		FilterOfSettings = 
			DataProcessors.SettingUpFinancialAccountingAccounts.SelectingExtdimensionFillingSettings(
				ChartOfAccounts, 
				PostingGenerationSetting,
				AccountingObject,
				GLAccount);
		SettingsTable = 
			DataProcessors.SettingUpFinancialAccountingAccounts.ExtraDimensionFillingSettings(
				FilterOfSettings,
				SettingsComposer,
				False);
		FillInExtdimensionFillSettings(SettingsTable);
	EndIf;
	
	ManagingAccessibility();
	
EndProcedure

#EndRegion

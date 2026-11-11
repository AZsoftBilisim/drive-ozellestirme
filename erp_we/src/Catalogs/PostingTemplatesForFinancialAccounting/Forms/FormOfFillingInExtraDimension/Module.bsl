
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	Account = Parameters.Account;
	BusinessOperation = Parameters.BusinessOperation;
	InvoiceData = FinancialAccountingServerCached.AccountProperties(Account);
	
	MaxExtDimensionCount = Metadata.ChartsOfAccounts.International.MaxExtDimensionCount;
	For ExtDimensionIndex = 1 To MaxExtDimensionCount Do
		
		ExtDimensionType = InvoiceData["ExtDimensionType"+ExtDimensionIndex];
		If ExtDimensionType = Undefined Then
			Continue;
		EndIf;
		
		NewRow = FillInExtraDimension.Add();
		NewRow.ExtDimensionType = InvoiceData["ExtDimensionType"+ExtDimensionIndex];
		NewRow.FillInFromSource = True;
	EndDo;
	
	CompositionSetup = Undefined;
	InitializeSettingsComposerServer(CompositionSetup);
	
	//Elements.The Filling configuration group.Visibility = Fillingconformity;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure FillInExtraDimensionRepresentationOfTheExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.FillInExtraDimension.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExtDimensionType", CurrentData.ExtDimensionType);
	FormParameters.Insert("AddressOfDataCompositionSchema", AddressOfDataCompositionSchema);
	FormParameters.Insert("CurrentExpression", CurrentData.Expression);
	
	OpenForm("CommonForm.SelectExtraDimensionFillingField", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure FillInExtraDimensionRepresentationOfTheExpressionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure FillInExtraDimensionRepresentationOfTheExpressionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.FillInExtraDimension.CurrentData;
	CurrentData.Expression = ValueSelected;
	Modified = True;
	RowID = Items.FillInExtraDimension.CurrentRow;
	FillingExtdimensionPresentationOfExpressionProcessingOfSelectionOnServer(RowID);
	Items.FillInExtraDimension.EndEditRow(False);
	
EndProcedure

&AtServer
Procedure FillingExtdimensionPresentationOfExpressionProcessingOfSelectionOnServer(RowID)
	
	CurrentData = FillInExtraDimension.FindByID(RowID);
	CheckExpression(CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveAndLoad(Command)
	
	Settings = New Structure("PopulateByCorrespondence", PopulateByCorrespondence);
	For Each Setting In FillInExtraDimension Do
		If ValueIsFilled(Setting.Expression) Or ValueIsFilled(Setting.SpecifiedValue) Then
			Settings.PopulateByCorrespondence = True;
			Break;
		EndIf;
	EndDo;
	Close(Settings);
	
EndProcedure

&AtClient
Procedure ChangeTheModeOfExtraDimensionPopulationSetting(Command)
	
	PopulateByCorrespondence = Not PopulateByCorrespondence;
	Items.FillInSettingsGroup.Visible = PopulateByCorrespondence;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("FillInExtraDimension.FillInFromSource");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Visible");
	Appearance.Use = True;
	Appearance.Value = False;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionSpecifiedValue");
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("FillInExtraDimension.FillInFromSource");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Visible");
	Appearance.Use = True;
	Appearance.Value = False;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionMissingInAvailableFields");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionRepresentationOfTheExpression");

	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("FillInExtraDimension.FillInFromSource");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	Appearance.Use = True;
	Appearance.Value = NStr("vi = 'Giá trị đã chỉ ra';
							|ru = 'Указанное значение';
							|en = 'Specified value'; fa = 'مقدار مشخص‌شده';
							|it = 'Valore indicato';
							|pl = 'Wskazana wartość';
							|tr = 'Belirtilen değer'");
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionFillInFromSource");
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("FillInExtraDimension.FillInFromSource");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	Appearance.Use = True;
	Appearance.Value = NStr("vi = 'Từ kế toán giao dịch';
							|ru = 'Из оперативного учета';
							|en = 'From operational accounting'; fa = 'از حسابداری عملیاتی';
							|it = 'Dalla contabilità operativa';
							|pl = 'Z ewidencji operacyjnej';
							|tr = 'Operasyonel muhasebeden'");
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionFillInFromSource");
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("FillInExtraDimension.ExtDimensionType");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Show");
	Appearance.Use = True;
	Appearance.Value = False;
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("MarkIncomplete");
	Appearance.Use = True;
	Appearance.Value = False;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionFillInFromSource");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionRepresentationOfTheExpression");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionSpecifiedValue");
	
	// 
	
EndProcedure

&AtServer
Procedure InitializeSettingsComposerServer(CompositionSetup = Undefined)
	
	DataCompositionSchema = DataSourcesCached.DataAcquisitionScheme(BusinessOperation);
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema));
	If CompositionSetup <> Undefined Then
		SettingsComposer.LoadSettings(CompositionSetup);
	EndIf;
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
EndProcedure

&AtServer
Procedure CheckExpression(SetupStrings)
	
	FinancialAccountingOfGeneralPurpose.CheckExtdimensionFillingExpression(SetupStrings, SettingsComposer);
	
EndProcedure

#EndRegion
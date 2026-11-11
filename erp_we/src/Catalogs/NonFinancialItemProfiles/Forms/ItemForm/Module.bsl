
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Object.Ref.IsEmpty() Then
		If Parameters.Property("FillingIndicator")
			And ValueIsFilled(Parameters.FillingIndicator) Then
			AddItemOnServer(Parameters.FillingIndicator, Undefined)
		EndIf;
	EndIf;
	
	If Parameters.Property("DocumentSource") Then
		DocumentSource = Parameters.DocumentSource;
	EndIf;
	
	AddingElements = ColumnTree.GetItems();
	NewRow = AddingElements.Add();
	NewRow.DimensionName  = "TabularSection";
	NewRow.Presentation = NStr("vi = 'Phần bảng';
								|ru = 'Табличная часть';
								|en = 'Table'; fa = 'جدول';
								|it = 'Parte di tabella';
								|pl = 'Sekcja tabelaryczna';
								|tr = 'Tablo bölümü'");
	NewRow.PictureIndex = 21;
	
	AddingElements = NewRow.GetItems();
	Columns = AddingElements.Add();
	Columns.DimensionName  = "Columns";
	Columns.Presentation = NStr("vi = 'Cột';
								|ru = 'Колонки';
								|en = 'Columns'; fa = 'ستون‌ها';
								|it = 'Colonne';
								|pl = 'Columns';
								|tr = 'Sütunlar'");
	Columns.PictureIndex = 24;
	
	AddingElements = NewRow.GetItems();
	Rows = AddingElements.Add();
	Rows.DimensionName  = "Rows";
	Rows.Presentation = NStr("vi = 'Dòng';
							|ru = 'Строки';
							|en = 'Rows'; fa = 'سطرها';
							|it = 'Righe';
							|pl = 'Rows';
							|tr = 'Satırlar'");
	Rows.PictureIndex = 27;
	
	Items.OnlyCompatible.Check = True;
	Items.HierarchicalView.Check = True;
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	FormControl();
	
	Templates = Catalogs.NonFinancialItemsOfBudgets.DataLayoutSchemaTemplates();
	ConditionalAppearanceItems = ConditionalAppearance.Items;
	
	ItemPresentation = NStr("vi = 'Chưa điền';
							|ru = 'Не заполнять';
							|en = 'Do not fill in'; fa = 'پر نشود';
							|it = 'Non compilare';
							|pl = 'Nie wypełniaj';
							|tr = 'Doldurma'");
	Items.PopulationTableDataCompositionSchema.ChoiceList.Add("DontFill", ItemPresentation);
	
	Item = ConditionalAppearanceItems.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PopulationTable.DataCompositionSchema");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "DontFill";
	
	ParameterValue = NStr("vi = 'Chưa điền';
							|ru = 'Не заполнять';
							|en = 'Do not fill in'; fa = 'پر نشود';
							|it = 'Non compilare';
							|pl = 'Nie wypełniaj';
							|tr = 'Doldurma'");
	Item.Appearance.SetParameterValue("Text", ParameterValue);
	FormattedField = Item.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("PopulationTableDataCompositionSchema");
	Item.Use = True;
	
	For Each Template In Templates Do
		
		Items.PopulationTableDataCompositionSchema.ChoiceList.Add(Template.Name, Template.Synonym);
		
		Item = ConditionalAppearanceItems.Add();
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField("PopulationTable.DataCompositionSchema");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Template.Name;
		
		Item.Appearance.SetParameterValue("Text", Template.Synonym);
		FormattedField = Item.Fields.Items.Add();
		FormattedField.Field = New DataCompositionField("PopulationTableDataCompositionSchema");
		Item.Use = True;
		
	EndDo;
	
	PresentationOfScheme = NStr("vi = 'Tùy ý';
								|ru = 'Произвольная';
								|en = 'Arbitrary'; fa = 'دلخواه';
								|it = 'Casuale';
								|pl = 'Dowolna';
								|tr = 'İsteğe bağlı'");
	Items.PopulationTableDataCompositionSchema.ChoiceList.Add("", PresentationOfScheme);
	
	Item = ConditionalAppearanceItems.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PopulationTable.DataCompositionSchema");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "";
	
	ParameterValue = NStr("vi = 'Tùy ý';
							|ru = 'Произвольная';
							|en = 'Arbitrary'; fa = 'دلخواه';
							|it = 'Casuale';
							|pl = 'Dowolna';
							|tr = 'İsteğe bağlı'");
	Item.Appearance.SetParameterValue("Text", ParameterValue);
	FormattedField = Item.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("PopulationTableDataCompositionSchema");
	Item.Use = True;
	
	BudgetingDimensions = StrSplit("Scenario,Department,Organization", ",");
	
	For Each BudgetingMeasurement In BudgetingDimensions Do

		Item = ConditionalAppearanceItems.Add();

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField("Object.EditInHeader.DimensionName");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = BudgetingMeasurement;

		Item.Appearance.SetParameterValue("Text",
			BudgetReportingClientServer.PresentationOfBudgetingDimension(BudgetingMeasurement));
		FormattedField = Item.Fields.Items.Add();
		FormattedField.Field = New DataCompositionField(Items.EditInHeaderDimensionName.Name);
		Item.Use = True;

		Item = ConditionalAppearanceItems.Add();

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField("Object.EditInRows.DimensionName");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = BudgetingMeasurement;

		Item.Appearance.SetParameterValue("Text",
			BudgetReportingClientServer.PresentationOfBudgetingDimension(BudgetingMeasurement));
		FormattedField = Item.Fields.Items.Add();
		FormattedField.Field = New DataCompositionField(Items.EditInRowsDimensionName.Name);
		Item.Use = True;

	EndDo;
	
	IndicatorsInTabularForm = Object.IndicatorsInTabularForm;
	
	UpdateListOfAvailableFields();
	UpdateListOfPlaceholders();
	
	AccessibilityOfNextBackButtons(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	For Each IndicatorLine_ In CurrentObject.TemplateIndicators Do
		
		NewRow = PopulationTable.Add();
		FillPropertyValues(NewRow, IndicatorLine_, "Factor, FillIn, DataCompositionSchema");
		NewRow.StorageOfDataCompositionSchema = PutToTempStorage(
			IndicatorLine_.StorageOfDataCompositionSchema.Get(), UUID);
		NewRow.StorageOfDataCompositionSettings = PutToTempStorage(
			IndicatorLine_.StorageOfDataCompositionSettings.Get(), UUID);
		
		NewRow.Picture = PictureLib.DataCompositionSettingsWizard;
		NewRow.Customize = "Customize";
		
	EndDo;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	Errors = Undefined;
	
	ReflectLocationOfFieldsInObjectData(CurrentObject);
	
	CheckIfThereIsSubPeriodInHeader(CurrentObject, Errors);
	
	If CurrentObject.EditInHeader.Find("SubperiodNumber") <> Undefined Then
		ErrorText = NStr("vi = 'Số thời gian phải được chỉnh sửa trong các hàng hoặc cột';
						|ru = 'Номер периода должен редактироваться в строках или колонках';
						|en = 'Period number should be edited in lines or columns'; fa = 'Period number should be edited in lines or columns';
						|it = 'Il numero di periodo deve essere modificato nelle righe o nelle colonne';
						|pl = 'Numer okresu musi być edytowany w wierszach lub kolumnach';
						|tr = 'Satırlardaki veya sütunlardaki dönem numaraları düzenlenmelidir'");
		CommonClientServer.AddUserError(Errors,
			"EditInHeader",
			ErrorText, "");
	EndIf;
	
	For Each FillString In PopulationTable Do
		
		FoundRow = CurrentObject.TemplateIndicators.Find(FillString.Factor, "Factor");
		If FoundRow = Undefined Then
			Continue;
		EndIf;
		
		FillPropertyValues(FoundRow, FillString, "Factor, DataCompositionSchema");
		FoundRow.FillIn = FoundRow.DataCompositionSchema <> "DontFill";
		
		If Not IsBlankString(FillString.StorageOfDataCompositionSchema) Then
			StorageOfDataCompositionSchema = GetFromTempStorage(FillString.StorageOfDataCompositionSchema);
			If StorageOfDataCompositionSchema <> Undefined
				And TypeOf(StorageOfDataCompositionSchema) <> Type("ValueStorage") Then
				StorageOfDataCompositionSchema = New ValueStorage(StorageOfDataCompositionSchema);
			EndIf;
		Else
			StorageOfDataCompositionSchema = Undefined;
		EndIf;
		FoundRow.StorageOfDataCompositionSchema = StorageOfDataCompositionSchema;
		
		If Not IsBlankString(FillString.StorageOfDataCompositionSettings) Then
			StorageOfDataCompositionSettings = GetFromTempStorage(FillString.StorageOfDataCompositionSettings);
			If StorageOfDataCompositionSettings <> Undefined
				And TypeOf(StorageOfDataCompositionSettings) <> Type("ValueStorage") Then
				StorageOfDataCompositionSettings = New ValueStorage(StorageOfDataCompositionSettings);
			EndIf;
		Else
			StorageOfDataCompositionSettings = Undefined;
		EndIf;
		FoundRow.StorageOfDataCompositionSettings = StorageOfDataCompositionSettings;
		
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("RecordedNFPInputTemplate", Object.Ref, DocumentSource);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AllInHeaderOnChange(Item)
	
	TypeOfMetricsEntryFormWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure SimpleTableOnChange(Item)
	
	TypeOfMetricsEntryFormWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure TableComplex_OnChange(Item)
	
	TypeOfMetricsEntryFormWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure InputPagesOnCurrentPageChange(Item, CurrentPage)
	
	If RecordTreeChanges Then
		ReflectLocationOfFieldsInObjectData();
	EndIf;
	
	If CurrentPage = Items.FieldLayoutPage Then
		UpdateListOfAvailableFields();
	ElsIf CurrentPage = Items.FillInSettingsPage Then
		UpdateListOfPlaceholders();
	EndIf;
	
	AccessibilityOfNextBackButtons(ThisObject);
	
EndProcedure

&AtClient
Procedure IndicatorPositionOnChange(Item)
	
	Object.IndicatorsInTabularForm = IndicatorsInTabularForm;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEditInHeader

&AtClient
Procedure EditInHeaderBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure HierarchicalViewOfIndicatorsToSelect(Command)
	
	Items.HierarchicalView.Check = 
		Not Items.HierarchicalView.Check;
		
	FormControl();
	
EndProcedure

&AtClient
Procedure IndicatorTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	If Not Allowed1Update Then
		Return;
	EndIf;
	AddToSelectedMetrics(RowSelected);
	
EndProcedure

&AtClient
Procedure TemplateIndicatorsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Not Allowed1Update Then
		StandardProcessing = False;
		Return;
	EndIf;
	MoveLeft(Undefined);
	
EndProcedure

&AtClient
Procedure TemplateIndicatorsAfterDeleteRow(Item)
	
	FormControl();
	AccessibilityOfNextBackButtons(ThisObject);
	
EndProcedure

&AtClient
Procedure EditInRowsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure EditInRowsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	MoveToTable(Item, DragParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure EditInHeaderDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	Array = DragParameters.Value;
	If TypeOf(Array[0]) = Type("FormDataTreeItem") Then
		PointOfReference = Array[0].GetItems();
		While PointOfReference.Count() Do
			Array.Add(PointOfReference[0]);
			PointOfReference = PointOfReference[0].GetItems();
		EndDo;
	EndIf;

	MoveToTable(Item, DragParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure EditInRowsDragEnd(Item, DragParameters, StandardProcessing)
	
	MoveFromTable(Item, DragParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure EditInHeaderDragEnd(Item, DragParameters, StandardProcessing)
	
	MoveFromTable(Item, DragParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ColumnTreeDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	Array = DragParameters.Value;
	If TypeOf(Array[0]) = Type("Number") Then
		PortableString = ColumnTree.FindByID(Array[0]);
		PointOfReference = PortableString.GetItems();
		While PointOfReference.Count() Do
			Array.Add(PointOfReference[0]);
			PointOfReference = PointOfReference[0].GetItems();
		EndDo;
	EndIf;

	MoveToTree(DragParameters, StandardProcessing, String);
	
EndProcedure

&AtClient
Procedure ColumnTreeDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	Cancel = False;
	
	If String = Undefined Then
		Cancel = True;
	Else
		WhereLine = ColumnTree.FindByID(String);
		If WhereLine.GetParent() = Undefined Then
			Cancel = True;
		EndIf;
	EndIf;
	
	If Not Cancel Then
		For Each Value In DragParameters.Value Do
			
			If TypeOf(Value) <> Type("Number") Then
				Continue;
			EndIf;
			
			DraggableLine = ColumnTree.FindByID(Value);
			
			If DraggableLine.GetParent() = Undefined Then
				Cancel = True;
				Break;
			EndIf;
			
			If DraggableLine.DimensionName = "Rows" Or
				DraggableLine.DimensionName = "Columns" Then
				Cancel = True;
				Break;
			EndIf;
			
		EndDo;
	EndIf;
	
	If Cancel Then
		DragParameters.AllowedActions = DragAllowedActions.DontProcess;
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	DragParameters.AllowedActions = DragAllowedActions.Move;
	
EndProcedure

&AtClient
Procedure ColumnTreeDragEnd(Item, DragParameters, StandardProcessing)
	
	TransferFromWood(DragParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure EditInHeaderSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	If RowSelected = Undefined Then
		Return;
	EndIf;
	If Not Allowed1Update Then
		Return;
	EndIf;
	
	String = Object.EditInHeader.FindByID(RowSelected);
	DragParameters = DragParameters(String);
	
	If Object.TypeOfIndicatorInputForm = 
			PredefinedValue("Enum.TemplateFormTypesOfNonFinancialItems.SimpleTable") Then
			
		MoveToTable(Items.EditInRows, DragParameters);
		MoveFromTable(Items.EditInHeader, DragParameters);
		
	ElsIf Object.TypeOfIndicatorInputForm = 
			PredefinedValue("Enum.TemplateFormTypesOfNonFinancialItems.TableComplex_") Then
			
		AddLine = FinancialReportingClient.SubordinateElementOfFormElement(ColumnTree,
			"DimensionName", "Rows");
		MoveToTree(DragParameters, False, AddLine.GetID());
		MoveFromTable(Items.EditInHeader, DragParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EditInRowsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	If RowSelected = Undefined Then
		Return;
	EndIf;
	If Not Allowed1Update Then
		Return;
	EndIf;
	
	String = Object.EditInRows.FindByID(RowSelected);
	DragParameters = DragParameters(String);
	
	MoveToTable(Items.EditInHeader, DragParameters);
	MoveFromTable(Items.EditInRows, DragParameters);
	
EndProcedure

&AtClient
Procedure ColumnTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	If RowSelected = Undefined Then
		Return;
	EndIf;
	If Not Allowed1Update Then
		Return;
	EndIf;
	
	String = ColumnTree.FindByID(RowSelected);
	
	If Field <> Undefined And Field.Name = "ColumnTreeValues" Then
		
		If String.Values = "" Then
			Return;
		EndIf;
		
		CallbackDescription = New CallbackDescription("ChangingDefaultValues", ThisObject);
		FormParameters = New Structure;
		If String.DimensionName = "Currency" Then
			FormParameters.Insert("ValueType", New TypeDescription("CatalogRef.Currencies"));
		ElsIf String.DimensionName = "Department" Then
			FormParameters.Insert("ValueType", New TypeDescription("CatalogRef.BusinessStructure"));
		ElsIf String.DimensionName = "Organization" Then
			FormParameters.Insert("ValueType", New TypeDescription("CatalogRef.Companies"));
		ElsIf String.DimensionName = "Scenario" Then
			FormParameters.Insert("ValueType", New TypeDescription("CatalogRef.BudgetingScenarios"));
		ElsIf String.DimensionName = "Dimension" Then
			ValueType = GeneralPurposeTMServerCall.ObjectAttributeValue(String.Dimension, "ValueType");
			FormParameters.Insert("ValueType", ValueType);
		EndIf;
		FormParameters.Insert("Title", NStr("vi = 'Giá trị theo mặc định';
											|ru = 'Значения по-умолчанию';
											|en = 'Default values'; fa = 'مقادیر پیش‌فرض';
											|it = 'Valore predefinito';
											|pl = 'Wartości domyślne';
											|tr = 'Varsayılan değerler'"));
		
		Values = New Array;
		ValueSearchStructure = New Structure("Dimension, DimensionName");
		FillPropertyValues(ValueSearchStructure, String);
		DefaultElements = Object.DefaultComplexTableValues.FindRows(ValueSearchStructure);
		For Each Item In DefaultElements Do
			Values.Add(Item.Value);
		EndDo;
		FormParameters.Insert("Values", Values);
		OpenForm("CommonForm.EditValueList", FormParameters, , , , , CallbackDescription, 
																FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
	EndIf;
	
	If String.GetParent() = Undefined Then
		Return;
	EndIf;
	
	If String.DimensionName = "Rows"
		Or String.DimensionName = "Columns" Then
		Return;
	EndIf;
	
	DragParameters = DragParameters(String);
	PointOfReference = String.GetItems();
	While PointOfReference.Count() Do
		DragParameters.Value.Add(PointOfReference[0]);
		PointOfReference = PointOfReference[0].GetItems();
	EndDo;
	
	MoveToTable(Items.EditInHeader, DragParameters);
	TransferFromWood(DragParameters, False);
	
EndProcedure

&AtClient
Procedure IndicatorTreeDragEnd(Item, DragParameters, StandardProcessing)
	
	StandardProcessing = False;
	For Each Value In DragParameters.Value Do
		//@skip-check query-in-loop
		AddToSelectedMetrics(Value);
	EndDo;
	
	FormControl();
	
EndProcedure

&AtClient
Procedure IndicatorTreeDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	For Each Value In DragParameters.Value Do
		Object.TemplateIndicators.Delete(Value.GetID());
	EndDo;
	
	FormControl();
	
EndProcedure

&AtClient
Procedure PopulationTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name <> "PopulationTableCustomize" Then
		Return;
	EndIf;
	If Not Allowed1Update Then
		StandardProcessing = False;
		Return;
	EndIf;
	StandardProcessing = False;
	CurrentData = Item.CurrentData;
	
	If CurrentData.DataCompositionSchema = "DontFill" Then
		WarningText = NStr("vi = 'Chọn sơ đồ thành phần dữ liệu để điền';
							|ru = 'Выберите схему компоновки данных для заполнения';
							|en = 'Select a data composition schema to populate'; fa = 'Select a data composition schema to populate';
							|it = 'Seleziona uno schema di composizione dei dati da riempire.';
							|pl = 'Wybierz schemat układu danych do wypełnienia';
							|tr = 'Doldurulması için Veri Oluşturma Sistemi''ni seçiniz'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	// Open the Data Layout Schema Settings Editor
	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Thiết lập lược đồ thành phần dữ liệu cho số liệu phi tài chính ""%1""';
													|ru = 'Настройка схемы компоновки данных для нефинансового показателя ""%1""';
													|en = 'Set up data composition schema for the ""%1"" non-financial item'; fa = 'Set up data composition schema for the ""%1"" non-financial item';
													|it = 'Impostazione dello schema di composizione dei dati per gli indicatori non finanziari ""%1""';
													|pl = 'Ustawienia schematu układu danych dla wskaźnika niefinansowego ""%1""';
													|tr = '""%1"" finansal olmayan öğesi için veri inşa edilme şeması ayarı'");
	HeaderOfDataLayoutSchemaConfigurationForm = StrReplace(HeaderOfDataLayoutSchemaConfigurationForm, "%1", CurrentData.Factor);
	
	Addresses = BudgetingServerCall.GetAddressesOfDataLayoutSchemeInTemporaryStorage(
		CurrentData.DataCompositionSchema, 
		CurrentData.StorageOfDataCompositionSchema, 
		CurrentData.StorageOfDataCompositionSettings,
		UUID);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowIndex", CurrentData.GetID());
	AdditionalParameters.Insert("Addresses",       Addresses);
	CallbackDescription = New CallbackDescription("WhenChangingDataLayout", ThisObject, AdditionalParameters);
	
	ParametersOfFormToOpen = New Structure;
	ParametersOfFormToOpen.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	ParametersOfFormToOpen.Insert("NotEditDataCompositionSchema",      False);
	ParametersOfFormToOpen.Insert("DoNotLoadADataLayoutDiagramFromAFile",   False);
	ParametersOfFormToOpen.Insert("DoNotConfigureConditionalFormatting",           True);
	ParametersOfFormToOpen.Insert("DoNotConfigureSettings",                    True);
	ParametersOfFormToOpen.Insert("DoNotConfigureTheSelection",                        True);
	ParametersOfFormToOpen.Insert("DonTAdjustTheOrder",                      True);
	ParametersOfFormToOpen.Insert("UUID",                   UUID);
	ParametersOfFormToOpen.Insert("AddressOfDataCompositionSchema",                Addresses.DataCompositionSchema);
	ParametersOfFormToOpen.Insert("AddressOfDataCompositionSettings",             Addresses.DataCompositionSettings);
	ParametersOfFormToOpen.Insert("Title",                                 HeaderOfDataLayoutSchemaConfigurationForm);
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		ParametersOfFormToOpen, ,,,,CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenIndicator(Command)
	
	CurrentRef = Items.TemplateIndicators.CurrentData;
	If CurrentRef = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Key", CurrentRef.Factor);
	OpenForm("Catalog.NonFinancialItemsOfBudgets.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	Pages = Items.InputPages.ChildItems;
	IndexOf = Pages.IndexOf(Items.InputPages.CurrentPage);
	
	If IndexOf = 0
	   And Not ValueIsFilled(Object.Description) Then
		Object.Description = DefaultDescription();
	EndIf;
	
	IndexOf = Min(IndexOf + 1, Pages.Count() - 1);
	Items.InputPages.CurrentPage = Items.InputPages.ChildItems[IndexOf];
	
	If RecordTreeChanges Then
		ReflectLocationOfFieldsInObjectData();
	EndIf;
	
	If Items.InputPages.CurrentPage.Name = "FieldLayoutPage" Then
		UpdateListOfAvailableFields();
	ElsIf Items.InputPages.CurrentPage.Name = "FillInSettingsPage" Then
		UpdateListOfPlaceholders();
	EndIf;
	
	AccessibilityOfNextBackButtons(ThisObject);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Pages = Items.InputPages.ChildItems;
	IndexOf = Pages.IndexOf(Items.InputPages.CurrentPage);
	IndexOf = Max(IndexOf - 1, 0);
	Items.InputPages.CurrentPage = Items.InputPages.ChildItems[IndexOf];
	
	If RecordTreeChanges Then
		ReflectLocationOfFieldsInObjectData();
	EndIf;
	
	If Items.InputPages.CurrentPage.Name = "FieldLayoutPage" Then
		UpdateListOfAvailableFields();
	EndIf;
	
	AccessibilityOfNextBackButtons(ThisObject);
	
EndProcedure

&AtClient
Procedure MoveToRight(Command)
	
	If Items.InputPages.CurrentPage = 
				Items.FieldLayoutPage Then
		
		EditInHeaderSelection(Items.EditInHeader,
		                         Items.EditInHeader.CurrentRow,
		                         Undefined,
		                         Undefined);
		
	ElsIf Items.InputPages.CurrentPage = 
						Items.MetricsPage Then
		
		AddToSelectedMetrics(Items.IndicatorTree.CurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveLeft(Command)
	
	If Items.InputPages.CurrentPage = 
				Items.FieldLayoutPage Then
				
		If Object.TypeOfIndicatorInputForm = PredefinedValue(
						"Enum.TemplateFormTypesOfNonFinancialItems.SimpleTable") Then
						
			EditInRowsSelection(Items.EditInRows,
			                           Items.EditInRows.CurrentRow,
			                           Undefined,
			                           Undefined);
			
		ElsIf Object.TypeOfIndicatorInputForm = PredefinedValue(
						"Enum.TemplateFormTypesOfNonFinancialItems.TableComplex_") Then
						
			ColumnTreeSelection(Items.ColumnTree,
			                   Items.ColumnTree.CurrentRow,
			                   Undefined,
			                   Undefined);
						
		EndIf;
		
	ElsIf Items.InputPages.CurrentPage = 
						Items.MetricsPage Then
	
		CurrentRow = Items.TemplateIndicators.CurrentRow;
		If CurrentRow = Undefined Then
			Return;
		EndIf;
		
		Object.TemplateIndicators.Delete(Object.TemplateIndicators.FindByID(CurrentRow));
		FormControl();
		AccessibilityOfNextBackButtons(ThisObject);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure OnlyCompatible(Command)
	
	Items.OnlyCompatible.Check = Not Items.OnlyCompatible.Check;
		
	FormControl();
	
EndProcedure

&AtClient
Procedure ViewTheDocumentForm(Command)
	Errors = Undefined;
	
	UpdateListOfAvailableFields();
	
	Cancel = False;
	CheckIfThereIsSubPeriodInHeader(Object, Errors);
	If Object.TemplateIndicators.Count() = 0 Then
		ErrorText = NStr("vi = 'Ít nhất một số liệu phải được chọn.';
						|ru = 'Должен быть выбран хотя бы один показатель';
						|en = 'At least one indicator is to be selected'; fa = 'At least one indicator is to be selected';
						|it = 'Deve essere selezionato almeno un indicatore';
						|pl = 'Musi być wybrany chociażby jeden wskaźnik';
						|tr = 'En az bir gösterge seçilmeli'");
		CommonClientServer.AddUserError(Errors,
			"Object.TemplateIndicators",
			ErrorText, "");
	EndIf;
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Template, Description", TemplateDescriptionStructure(), Object.Description);
	OpenForm("Catalog.NonFinancialItemProfiles.Form.DemonstrationForm", FormParameters);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, ProcedureParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		Allowed1Update = Result;
		FormControl();
		AccessibilityOfNextBackButtons(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure TypeOfMetricsEntryFormWhenChangingOnServer()
	
	If Not Object.TypeOfIndicatorInputForm = Enums.TemplateFormTypesOfNonFinancialItems.TableComplex_ Then
		Object.EditInColumns.Clear();
	EndIf;
	If Not Object.TypeOfIndicatorInputForm = Enums.TemplateFormTypesOfNonFinancialItems.SimpleTable Then
		Object.EditInRows.Clear();
	EndIf;
	
	FormControl();
EndProcedure

&AtClientAtServerNoContext
Procedure CheckIfThereIsSubPeriodInHeader(Val Object, Errors)
	
	TheStructureOfTheSearch = New Structure("DimensionName", "SubperiodNumber");
	If Object.EditInHeader.FindRows(TheStructureOfTheSearch).Count() Then
		ErrorText = NStr("vi = 'Số thời gian phải được chỉnh sửa trong các hàng hoặc cột.';
						|ru = 'Номер периода должен редактироваться в строках или колонках';
						|en = 'Period number should be edited in lines or columns'; fa = 'Period number should be edited in lines or columns';
						|it = 'Il numero di periodo deve essere modificato nelle righe o nelle colonne';
						|pl = 'Numer okresu musi być edytowany w wierszach lub kolumnach';
						|tr = 'Satırlardaki veya sütunlardaki dönem numaraları düzenlenmelidir'");
		CommonClientServer.AddUserError(Errors,
			"EditInHeader",
			ErrorText, "");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AccessibilityOfNextBackButtons(Form)
	
	Items = Form.Items;
	
	CurrentPage = Items.InputPages.CurrentPage;
	Pages = Items.InputPages.ChildItems;
	CurPageIndex = Pages.IndexOf(CurrentPage);
	FirstPage = CurPageIndex = 0;
	LastPage = CurPageIndex = (Pages.Count() - 1);
	
	ChecksCompleted = StepChecksPerformed(Form);
	
	Items.Next.Enabled = Not LastPage And ChecksCompleted;
	Items.Back.Enabled = Not FirstPage;
	Items.WriteAndClose.Enabled = ChecksCompleted And Form.Allowed1Update;
	
	Items.Next.DefaultButton = Not LastPage;
	Items.WriteAndClose.DefaultButton = LastPage;
	
EndProcedure

&AtClientAtServerNoContext
Function StepChecksPerformed(Form)
	ChecksCompleted_ = True;
	Object = Form.Object;
	
	If Object.TemplateIndicators.Count() = 0 Then
		ChecksCompleted_ = False;
	EndIf;
	
	Return ChecksCompleted_;
EndFunction

&AtServer
Function DefaultDescription()
	
	Result = "";
	For Each IndicatorLine_1 In Object.TemplateIndicators Do
		Result = Result + ?(IsBlankString(Result), "", ", ") + String(IndicatorLine_1.Factor);
	EndDo;
	If Object.TemplateIndicators.Count() = 1 Then
		Description = NStr("vi = 'Nhập chỉ tiêu: %1';
							|ru = 'Ввод показателя: %1';
							|en = 'Enter an indicator: %1'; fa = 'Enter an indicator: %1';
							|it = 'Inserimento dell''indicatore:%1';
							|pl = 'Wprowadzanie wskaźnika: %1';
							|tr = 'Gösterge girişi: %1'");
	Else
		Description = NStr("vi = 'Nhập chỉ tiêu: %1';
							|ru = 'Ввод показателей: %1';
							|en = 'Enter indicators: %1'; fa = 'Enter indicators: %1';
							|it = 'Inserimento degli indicatori: %1';
							|pl = 'Wprowadzanie wskaźników: %1';
							|tr = 'Göstergelerin girişi: %1'");
	EndIf;
	Description = StringFunctionsClientServer.SubstituteParametersToString(Description, Result);
	
	Return Description;
	
EndFunction

&AtServer
Function ListOfCompatible()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	NonFinancialItemsOfBudgets.Ref AS Ref
	|FROM
	|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
	|WHERE
	|	NOT NonFinancialItemsOfBudgets.IsFolder
	|	AND (NonFinancialItemsOfBudgets.ByScenarios
	|			OR NOT NonFinancialItemsOfBudgets.ImportFromOtherSubsystems)";
	
	If Object.TemplateIndicators.Count() Then
		
		Benchmark = Object.TemplateIndicators[0].Factor;
		Required_Fields = "IndicatorKind, Periodicity, SubperiodFrequency,
						|ByCompanies, ByPeriods, ByBusinessUnits, 
						|ByScenarios, ImportFromOtherSubsystems, 
						|SetAValueForEachPeriod";
		
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			Required_Fields = Required_Fields + ", DimensionKind" + DimensionNumber;
		EndDo;
		
		Fields = Common.ObjectAttributesValues(Benchmark, Required_Fields);
		
		Query.Text = Query.Text + "
		|	AND NonFinancialItemsOfBudgets.IndicatorKind = &IndicatorKind
		|	AND &TextConditionTypesOfAnalytics
		|	AND NonFinancialItemsOfBudgets.Periodicity = &Periodicity
		|	AND CASE
		|			WHEN NonFinancialItemsOfBudgets.ByPeriods
		|				THEN NonFinancialItemsOfBudgets.SubperiodFrequency = &SubperiodFrequency
		|			ELSE TRUE
		|		END
		|	AND NonFinancialItemsOfBudgets.ByCompanies = &ByCompanies
		|	AND NonFinancialItemsOfBudgets.ByPeriods = &ByPeriods
		|	AND NonFinancialItemsOfBudgets.ByBusinessUnits = &ByBusinessUnits
		|	AND NonFinancialItemsOfBudgets.ByScenarios = &ByScenarios
		|	AND NonFinancialItemsOfBudgets.ImportFromOtherSubsystems = &ImportFromOtherSubsystems
		|	AND NonFinancialItemsOfBudgets.SetAValueForEachPeriod = &SetAValueForEachPeriod
		|	AND NOT NonFinancialItemsOfBudgets.Ref IN (&Ref)";
		
		TextConditionTypesOfAnalytics = "";
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			TextConditionTypesOfAnalytics = TextConditionTypesOfAnalytics
				+ ?(TextConditionTypesOfAnalytics = "", "", Chars.LF + Chars.Tab + "And ")
				+ StringFunctionsClientServer.SubstituteParametersToString(
					" NonFinancialItemsOfBudgets.DimensionKind%1 = &DimensionKind%1",
					DimensionNumber);
		EndDo;
		Query.Text = StrReplace(Query.Text, "&TextConditionTypesOfAnalytics", TextConditionTypesOfAnalytics);
		
		For Each KeyAndValue In Fields Do
			Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
		
		List = New ValueList;
		For Each IndicatorLine_1 In Object.TemplateIndicators Do
			List.Add(IndicatorLine_1.Factor);
		EndDo;
		
		Query.SetParameter("Ref", List);
		
	EndIf;
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	List = New ValueList;
	While SelectionDetailRecords.Next() Do
		List.Add(SelectionDetailRecords.Ref);
	EndDo;
	
	Return List;
	
EndFunction

&AtServer
Procedure FormControl()
	
	// Blocked elements
	Allowed1Update = Not Items.AllInHeader.ReadOnly;
	Items.IndicatorTree.ReadOnly = Not Allowed1Update;
	Items.TemplateIndicators.ReadOnly = Not Allowed1Update;
	Items.IndicatorPosition.ReadOnly = Not Allowed1Update;
	Items.EditInHeader.ReadOnly = Not Allowed1Update;
	Items.EditInRows.ReadOnly = Not Allowed1Update;
	Items.ColumnTree.ReadOnly = Not Allowed1Update;
	Items.PopulationTable.ReadOnly = Not Allowed1Update;
	Items.WriteAndClose.Enabled = Allowed1Update;
	Items.MoveRightStep1.Enabled = Allowed1Update;
	Items.MoveRightStep3.Enabled = Allowed1Update;
	Items.MoveLeftStep1.Enabled = Allowed1Update;
	Items.MoveLeftStep3.Enabled = Allowed1Update;
	
	Items.Description.ChoiceList.Clear();
	Items.Description.ChoiceList.Add(DefaultDescription());
		
	ListOfCompatible = ListOfCompatible();
	ListSelectionsClientServer.DeleteListSelectionItem(IndicatorTree, "Ref");
	
	ConditionalAppearanceItems = ConditionalAppearance.Items;
	
	ConditionalAppearanceForDeletion = New Array;
	For Each UOElement In ConditionalAppearanceItems Do
		If StrFind(UOElement.Presentation, "AddedUOOfMetricsTree") Then
			ConditionalAppearanceForDeletion.Add(UOElement);
		EndIf;
	EndDo;
	
	For Each UOElement In ConditionalAppearanceForDeletion Do
		ConditionalAppearance.Items.Delete(UOElement);
	EndDo;
	
	If Items.OnlyCompatible.Check Then
		
		ListSelectionsClientServer.SetListSelectionElement(IndicatorTree,
			"Ref",
			ListOfCompatible,
			DataCompositionComparisonType.InList);
		
	Else
		
		Item = ConditionalAppearanceItems.Add();
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue 	= New DataCompositionField("IndicatorTree.Ref");
		ItemFilter.ComparisonType 		= DataCompositionComparisonType.NotInList;
		ItemFilter.RightValue 	= ListOfCompatible;
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue 	= New DataCompositionField("IndicatorTree.IsFolder");
		ItemFilter.ComparisonType 		= DataCompositionComparisonType.Equal;
		ItemFilter.RightValue 	= False;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		FormattedField = Item.Fields.Items.Add();
		FormattedField.Field = New DataCompositionField("IndicatorTreeDescription");
		Item.Use = True;
		Item.Presentation = "AddedUOOfMetricsTree";
		
	EndIf;
	
	If Items.HierarchicalView.Check Then
		Items.IndicatorTree.Representation = TableRepresentation.Tree;
	Else
		Items.IndicatorTree.Representation = TableRepresentation.List;
	EndIf;
	
	ByPeriods = False;
	If Object.TemplateIndicators.Count() Then
		ByPeriods = Common.ObjectAttributeValue(Object.TemplateIndicators[0].Factor, "ByPeriods");
		Items.IndicatorPosition.Enabled = Not ByPeriods;
	EndIf;
	
	Items.IndicatorPosition.Visible = Not ByPeriods;
	
	If Object.TypeOfIndicatorInputForm = Enums.TemplateFormTypesOfNonFinancialItems.SimpleTable Then
		Items.IndicatorPosition.Enabled = True;
	Else
		Items.IndicatorPosition.Enabled = False;
	EndIf;
	
	If Object.TypeOfIndicatorInputForm = Enums.TemplateFormTypesOfNonFinancialItems.SimpleTable Then
		Items.TabularSectionPages.CurrentPage = Items.TabularSectionSimpleTable;
	ElsIf Object.TypeOfIndicatorInputForm = Enums.TemplateFormTypesOfNonFinancialItems.TableComplex_ Then
		Items.TabularSectionPages.CurrentPage = Items.TabularSectionComplexTable;
	Else
		Items.TabularSectionPages.CurrentPage = Items.NoTable;
	EndIf;
	
EndProcedure

&AtServer
Function AddItemOnServer(ItemRef, Error)
	
	Attributes = Common.ObjectAttributesValues(ItemRef, "IsFolder, Ref, ByPeriods");
	
	If Attributes.IsFolder Then
		Error = NStr("vi = 'Các nhóm không thể được chọn trong mẫu.';
					|ru = 'Группы не могут быть выбраны в шаблоне';
					|en = 'Groups cannot be selected in the template'; fa = 'Groups cannot be selected in the template';
					|it = 'I gruppi non possono essere selezionati nel modello';
					|pl = 'Grupy nie mogą zostać wybrane w szablonie';
					|tr = 'Gruplar şablonda seçilemez'");
		Return False;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("Factor", Attributes.Ref);
	If Object.TemplateIndicators.FindRows(TheStructureOfTheSearch).Count() Then
		Return True;
	EndIf;
	
	List = ListOfCompatible();
	If List.FindByValue(ItemRef) = Undefined Then
		Error = NStr("vi = 'Không thể chọn phần tử';
					|ru = 'Элемент не может быть выбран';
					|en = 'Item cannot be selected'; fa = 'Item cannot be selected';
					|it = 'L''elemento non può essere selezionato';
					|pl = 'Element nie może zostać wybrany';
					|tr = 'Öğe seçilemez'");
		Return False;
	EndIf;
	
	NewRow = Object.TemplateIndicators.Add();
	NewRow.Factor = Attributes.Ref;
	
	If Attributes.ByPeriods Then
		IndicatorsInTabularForm = True;
	EndIf;
	
	FormControl();
	AccessibilityOfNextBackButtons(ThisObject);
	
	Return True;
	
EndFunction

&AtClient
Procedure AddToSelectedMetrics(RowSelected)
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	Error = "";
	If Not AddItemOnServer(RowSelected, Error) Then
	
		ShowMessageBox(, Error);
	
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateListOfPlaceholders()
	
	For Each IndicatorLine_1 In Object.TemplateIndicators Do
		TheStructureOfTheSearch = New Structure("Factor", IndicatorLine_1.Factor);
		If PopulationTable.FindRows(TheStructureOfTheSearch).Count() Then
			Continue;
		EndIf;
		NewRow = PopulationTable.Add();
		FillPropertyValues(NewRow, IndicatorLine_1);
		NewRow.DataCompositionSchema = "DontFill";
		
		NewRow.Picture = PictureLib.DataCompositionSettingsWizard;
		NewRow.Customize = NStr("vi = 'Tùy chỉnh';
								|ru = 'Настроить';
								|en = 'Set up'; fa = 'تنظیم';
								|it = 'Impostare';
								|pl = 'Set up';
								|tr = 'Ayarla'");
	EndDo;
	
	ForDeletion = New Array;
	For Each IndicatorLine_1 In PopulationTable Do
		TheStructureOfTheSearch = New Structure("Factor", IndicatorLine_1.Factor);
		If Object.TemplateIndicators.FindRows(TheStructureOfTheSearch).Count() Then
			Continue;
		EndIf;
		ForDeletion.Add(IndicatorLine_1);
	EndDo;
	
	For Each Delete In ForDeletion Do
		PopulationTable.Delete(Delete);
	EndDo;
	
EndProcedure

&AtServer
Procedure ReflectLocationOfFieldsInObjectData(RoomObject = Undefined)
	
	If RoomObject = Undefined Then
		RoomObject = Object;
	EndIf;
	
	If RoomObject.TypeOfIndicatorInputForm <> Enums.TemplateFormTypesOfNonFinancialItems.TableComplex_ Then
		Attributes = TemplateMetricDetails();
	EndIf;
	
	If RoomObject.TypeOfIndicatorInputForm = Enums.TemplateFormTypesOfNonFinancialItems.SimpleTable Then
		
		RoomObject.EditInColumns.Clear();
		If RoomObject.IndicatorsInTabularForm Then
			If Attributes.SetAValueForEachPeriod Then
				RoomObject.EditInColumns.Add().DimensionName = "Period";
			EndIf;
		EndIf;
		If Attributes.ByPeriods Then
			RoomObject.EditInRows.Add().DimensionName = "SubperiodNumber";
		EndIf;
		
		Return;
	EndIf;
	
	RoomObject.EditInColumns.Clear();
	RoomObject.EditInRows.Clear();
	
	If RoomObject.TypeOfIndicatorInputForm = Enums.TemplateFormTypesOfNonFinancialItems.AllInHeader Then
		
		If Attributes.ByPeriods Then
			RoomObject.EditInRows.Add().DimensionName = "SubperiodNumber";
		EndIf;
		
		Return;
	EndIf;
	
	Rows = FinancialReportingServer.SubordinateItem(ColumnTree, "DimensionName", "Rows");
	
	RowsArray = New Array;
	PointOfReference = Rows.GetItems();
	While PointOfReference.Count() Do
		RowsArray.Add(PointOfReference[0]);
		PointOfReference = PointOfReference[0].GetItems();
	EndDo;
	
	Columns = FinancialReportingServer.SubordinateItem(ColumnTree, "DimensionName", "Columns");
	
	ColumnsArray1 = New Array;
	PointOfReference = Columns.GetItems();
	While PointOfReference.Count() Do
		ColumnsArray1.Add(PointOfReference[0]);
		PointOfReference = PointOfReference[0].GetItems();
	EndDo;
	
	For Each String In RowsArray Do
		FillPropertyValues(RoomObject.EditInRows.Add(), String);
	EndDo;
	
	For Each Column In ColumnsArray1 Do
		FillPropertyValues(RoomObject.EditInColumns.Add(), Column);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetHyperlinkValues(TableRow)
	
	If TableRow.DimensionName = "Period"
		Or TableRow.DimensionName = "SubperiodNumber" Then
		TableRow.Values = "";
		Return;
	EndIf;
	
	ValueSearchStructure = New Structure("Dimension, DimensionName");
	FillPropertyValues(ValueSearchStructure, TableRow);
	Elements = Object.DefaultComplexTableValues.FindRows(ValueSearchStructure);
	If Elements.Count() Then
		CellText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Mặc định (%1)';
				|ru = 'По-умолчанию (%1)';
				|en = 'Default (%1)'; fa = 'Default (%1)';
				|it = 'Predefinito (%1)';
				|pl = 'Domyślnie (%1)';
				|tr = 'Varsayılan (%1)'"),
			Elements.Count());
	Else
		CellText = NStr("vi = 'Chọn';
						|ru = 'Выбрать';
						|en = 'Select'; fa = 'انتخاب';
						|it = 'Selezionare';
						|pl = 'Wybierz';
						|tr = 'Seç'");
	EndIf;
	TableRow.Values = CellText;
	
EndProcedure

&AtServer
Procedure SetHyperlinksOfValuesInAddedRows(Array)
	
	For Each Value In Array Do
		
		SetHyperlinkValues(ColumnTree.FindByID(Value));
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RestoreTreeByFields()
	
	Rows = FinancialReportingServer.SubordinateItem(ColumnTree, "DimensionName", "Rows");
	Var_To = Rows.GetItems();
	Var_To.Clear();
	
	For Each String In Object.EditInRows Do
		NewRow = Var_To.Add();
		FillPropertyValues(NewRow, String);
		If Not ValueIsFilled(NewRow.Dimension) Then
			NewRow.Presentation = BudgetReportingClientServer.PresentationOfBudgetingDimension(NewRow.DimensionName);
		EndIf;
		NewRow.PictureIndex = 30;
		SetHyperlinkValues(NewRow);
		Var_To = NewRow.GetItems();
	EndDo;
	
	Columns = FinancialReportingServer.SubordinateItem(ColumnTree, "DimensionName", "Columns");
	Var_To = Columns.GetItems();
	Var_To.Clear();
	
	For Each String In Object.EditInColumns Do
		NewRow = Var_To.Add();
		FillPropertyValues(NewRow, String);
		If Not ValueIsFilled(NewRow.Dimension) Then
			NewRow.Presentation = BudgetReportingClientServer.PresentationOfBudgetingDimension(NewRow.DimensionName);
		EndIf;
		NewRow.PictureIndex = 30;
		SetHyperlinkValues(NewRow);
		Var_To = NewRow.GetItems();
	EndDo;
	
EndProcedure

&AtServer
Function TemplateMetricDetails()
	
	Benchmark = Object.TemplateIndicators[0].Factor;
	
	Required_Fields = "IndicatorKind, ByCompanies, ByPeriods, ByBusinessUnits, 
					|ByScenarios, SetAValueForEachPeriod";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		Required_Fields = Required_Fields + ", DimensionKind" + DimensionNumber;
	EndDo;
	
	Attributes = Common.ObjectAttributesValues(Benchmark, Required_Fields);
	
	Return Attributes;
	
EndFunction

&AtServer
Procedure UpdateListOfAvailableFields()
	
	AvailableFields = Object.EditInHeader.Unload(New Array);
	
	If Object.TemplateIndicators.Count() Then
		
		Attributes = TemplateMetricDetails();
		
		If Object.TypeOfIndicatorInputForm = Enums.TemplateFormTypesOfNonFinancialItems.TableComplex_ Then
			If Attributes.SetAValueForEachPeriod Then
				AvailableFields.Add().DimensionName = "Period";
			EndIf;
			If Attributes.ByPeriods Then
				AvailableFields.Add().DimensionName = "SubperiodNumber";
			EndIf;
		EndIf;
		
		If Attributes.ByCompanies Then
			AvailableFields.Add().DimensionName = "Organization";
		EndIf;
		
		If Attributes.ByBusinessUnits Then
			AvailableFields.Add().DimensionName = "Department";
		EndIf;
		
		If Attributes.ByScenarios Then
			AvailableFields.Add().DimensionName = "Scenario";
		EndIf;
		
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			If ValueIsFilled(Attributes["DimensionKind" + DimensionNumber]) Then
				NewRow = AvailableFields.Add();
				NewRow.DimensionName = "Dimension";
				NewRow.Dimension = Attributes["DimensionKind" + DimensionNumber];
			EndIf;
		EndDo;
		
	EndIf;
	
	WhereToFind = New Structure("Header", Object.EditInHeader);
	
	If RecordTreeChanges = True Then
		RecordTreeChanges = False;
		ReflectLocationOfFieldsInObjectData();
	EndIf;
	
	If Object.TypeOfIndicatorInputForm = Enums.TemplateFormTypesOfNonFinancialItems.TableComplex_ Then
		WhereToFind.Insert("Rows", Object.EditInRows);
		WhereToFind.Insert("Columns", Object.EditInColumns);
	ElsIf Object.TypeOfIndicatorInputForm = Enums.TemplateFormTypesOfNonFinancialItems.SimpleTable Then
		WhereToFind.Insert("Rows", Object.EditInRows);
	EndIf;
	TheStructureOfTheSearch = New Structure("DimensionName, Dimension");
	
	For Each AvailableField In AvailableFields Do
		
		Found4 = False;
		For Each KeyAndValue In WhereToFind Do
			FillPropertyValues(TheStructureOfTheSearch, AvailableField);
			String = KeyAndValue.Value.FindRows(TheStructureOfTheSearch);
			If String.Count() Then
				Found4 = True;
				Break;
			EndIf;
		EndDo;
		
		If Not Found4 Then
			FillPropertyValues(Object.EditInHeader.Add(), AvailableField);
		EndIf;
		
	EndDo;
	
	For Each KeyAndValue In WhereToFind Do
		ForDeletion = New Array;
		For Each String In KeyAndValue.Value Do
			FillPropertyValues(TheStructureOfTheSearch, String);
			If Not AvailableFields.FindRows(TheStructureOfTheSearch).Count() Then
				ForDeletion.Add(String);
			EndIf;
		EndDo;
		For Each String In ForDeletion Do
			KeyAndValue.Value.Delete(String);
		EndDo;
	EndDo;
	
	RestoreTreeByFields();
	
EndProcedure

&AtClient
Procedure MoveToTable(WhereElement, DragParameters, StandardProcessing = False)
	
	StandardProcessing = False;
	
	If DragParameters.Action = DragAction.Cancel Then
		Return;
	EndIf;
	
	For Each Value In DragParameters.Value Do
		If TypeOf(Value) = Type("Number") Then
			// dragging inside a table
			String = Object[WhereElement.Name].FindByID(Value);
		Else
			String = Value;
		EndIf;
		FillPropertyValues(Object[WhereElement.Name].Add(), String);
	EndDo;
	
EndProcedure

&AtClient
Procedure MoveFromTable(ElementFromWhere, DragParameters, StandardProcessing = False)
	
	StandardProcessing = False;
	
	If DragParameters.Action = DragAction.Cancel Then
		Return;
	EndIf;
	
	For Each Value In DragParameters.Value Do
		Object[ElementFromWhere.Name].Delete(Value);
	EndDo;
	
EndProcedure

&AtClient
Procedure MoveToTree(DragParameters, StandardProcessing, String)
	
	StandardProcessing = False;
	
	If DragParameters.Action = DragAction.Cancel Then
		Return;
	EndIf;
	
	If String = Undefined Then
		DragParameters.Action = DragAction.Cancel;
		Return;
	EndIf;
	
	TreeRow = ColumnTree.FindByID(String);
	Var_To = TreeRow.GetItems();
	AddLine = TreeRow;
	While Var_To.Count() Do
		AddLine = Var_To[0];
		Var_To = Var_To[0].GetItems();
	EndDo;
	
	AddedRows = New Array;
	
	For Each Value In DragParameters.Value Do
		If TypeOf(Value) = Type("Number") Then
			// dragging inside a table
			String = ColumnTree.FindByID(Value);
			PointOfReference = AddLine;
			While PointOfReference <> Undefined Do
				If String.GetID() = 
						PointOfReference.GetID() Then
					DragParameters.Action = DragAction.Cancel;
					Return;
				EndIf;
				PointOfReference = PointOfReference.GetParent();
			EndDo;
		Else
			String = Value;
		EndIf;
		NewRow = Var_To.Add();
		AddedRows.Add(NewRow.GetID());
		FillPropertyValues(NewRow, String);
		If Not ValueIsFilled(NewRow.Dimension) Then
			NewRow.Presentation = BudgetReportingClientServer.PresentationOfBudgetingDimension(
				NewRow.DimensionName);
		EndIf;
		NewRow.PictureIndex = 30;
		Var_To = NewRow.GetItems();
	EndDo;
	
	Parent = NewRow.GetParent();
	While Parent <> Undefined Do
		Items.ColumnTree.Expand(Parent.GetID());
		Parent = Parent.GetParent();
	EndDo;
	
	Items.ColumnTree.CurrentRow = NewRow.GetID();
	
	SetHyperlinksOfValuesInAddedRows(AddedRows);
	RecordTreeChanges = True;
	
EndProcedure

&AtClient
Procedure TransferFromWood(DragParameters, StandardProcessing)
	
	StandardProcessing = False;
	
	If DragParameters.Action = DragAction.Cancel Then
		Return;
	EndIf;
	
	For Each Value In DragParameters.Value Do
		Parent = Value.GetParent();
		If Parent = Undefined Then
			Continue;
		EndIf;
		ValueCollection_ = Parent.GetItems();
		ValueCollection_.Delete(Value);
		RecordTreeChanges = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ChangingDefaultValues(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	String = Items.ColumnTree.CurrentRow;
	String = ColumnTree.FindByID(String);
	
	ValueSearchStructure = New Structure("Dimension, DimensionName");
	FillPropertyValues(ValueSearchStructure, String);
	
	DefaultElements = Object.DefaultComplexTableValues.FindRows(ValueSearchStructure);
	For Each Item In DefaultElements Do
		Object.DefaultComplexTableValues.Delete(Item);
	EndDo;
	
	ValueSearchStructure.Insert("Value");
	For Each Item In Result Do
		ValueSearchStructure.Value = Item;
		If Object.DefaultComplexTableValues.FindRows(ValueSearchStructure).Count() Then
			Continue;
		EndIf;
		NewRow = Object.DefaultComplexTableValues.Add();
		FillPropertyValues(NewRow, String);
		NewRow.Value = Item;
	EndDo;
	
	If Result.Count() Then
		String.Values = NStr("vi = 'Mặc định (%1)';
							|ru = 'По-умолчанию (%1)';
							|en = 'Default (%1)'; fa = 'Default (%1)';
							|it = 'Predefinito (%1)';
							|pl = 'Domyślnie (%1)';
							|tr = 'Varsayılan (%1)'");
		String.Values = StringFunctionsClientServer.SubstituteParametersToString(String.Values,
			Result.Count());
	Else
		String.Values = NStr("vi = 'Chọn';
							|ru = 'Выбрать';
							|en = 'Select'; fa = 'انتخاب';
							|it = 'Selezionare';
							|pl = 'Wybierz';
							|tr = 'Seç'");
	EndIf;
	
EndProcedure

&AtClient
Function DragParameters(Value)
	
	Result = New Structure;
	Result.Insert("Action", DragAction.Move);
	ValueResult = New Array;
	ValueResult.Add(Value);
	Result.Insert("Value", ValueResult);
	
	Return Result;
	
EndFunction

&AtClient
Procedure WhenChangingDataLayout(AddressOfComposerConfigurationStore, AdditionalParameters) Export
	
	If ValueIsFilled(AddressOfComposerConfigurationStore) Then
		
		Addresses = AdditionalParameters.Addresses;
		
		CurrentData = PopulationTable.FindByID(AdditionalParameters.RowIndex);
		
		ReflectionResult = 
			BudgetingServerCall.ApplyChangesToDataLayoutScheme(CurrentData.DataCompositionSchema, 
				Addresses.DataCompositionSchema,
				AddressOfComposerConfigurationStore,
				True,
				UUID);
		
		CurrentData.DataCompositionSchema = ReflectionResult.DataCompositionSchema;
		CurrentData.StorageOfDataCompositionSchema = ReflectionResult.StorageOfDataCompositionSchema;
		CurrentData.StorageOfDataCompositionSettings = ReflectionResult.StorageOfDataCompositionSettings;
		
	EndIf;
	
EndProcedure

&AtServer
Function TemplateDescriptionStructure()
	
	DetailsStructure1 = New Structure;
	For Each Attribute In Metadata.Catalogs.NonFinancialItemProfiles.Attributes Do
		DetailsStructure1.Insert(Attribute.Name, Object[Attribute.Name]);
	EndDo;
	
	For Each Attribute In Metadata.Catalogs.NonFinancialItemProfiles.TabularSections Do
		DetailsStructure1.Insert(Attribute.Name, Object[Attribute.Name].Unload());
	EndDo;
	
	Return PutToTempStorage(DetailsStructure1, UUID);
	
EndFunction

#EndRegion

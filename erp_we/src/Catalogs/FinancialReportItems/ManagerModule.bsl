
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure sets the text of a cell in the settings table
//
// Parameters:
//  Form - ClientApplicationForm - The form where the cell settings are displayed.
//  Address - String - Address of the settings structure.
//
Procedure SetCellText(Form, Address) Export
	
	SetAuxiliaryText = False;
	If Form.Parameters.Property("CheckTableView") Then
		TableType = Undefined;
		Form.Parameters.Property("TableType", TableType);
		If TableType = Enums.FinancialReportItemKinds.TableIndicatorsInColumns
			Or TableType = Enums.FinancialReportItemKinds.TableIndicatorsInRows Then
			SetAuxiliaryText = True;
		EndIf;
	EndIf;
	
	FinReports = FinancialReportingServerCall;
	CurrentArea = Form.ReportPresentation.Area(Address);
	
	If Not SetAuxiliaryText Then
		Details = CurrentArea.Details;
	EndIf;

	If SetAuxiliaryText Then
		
		CurrentArea.Text = NStr("vi = '<giá trị số liệu báo cáo>';
								|ru = '<значение показателя отчета>';
								|en = '<report indicator value>'; fa = '<report indicator value>';
								|it = '<valore dell''indicatore del report>';
								|pl = '<wartość wskaźnika raportu>';
								|tr = '<rapor göstergesinin değeri>'");
		
	ElsIf Not ValueIsFilled(Details.ReportItem)
		And Not ValueIsFilled(Details.ItemKind) Then
		
		CurrentArea.Text = NStr("vi = '<chọn loại ô>';
								|ru = '<выберите тип ячейки>';
								|en = '<select a cell type>'; fa = '<select a cell type>';
								|it = '<selezionare tipo di cella>';
								|pl = '<wybierz typ komórki>';
								|tr = '<hücre türünü seçiniz>'");
		
	Else
		
		CurrentArea.Text = String(Details.ItemKind);
		
		If Details.ItemKind = ItemKind("BudgetBalanceItem")
			Or Details.ItemKind = ItemKind("AllBudgetBalanceItems") Then
			
			If Details.ItemKind <> ItemKind("AllBudgetBalanceItems") Then
				BudgetIndicator = FinReports.ValueOfAdditionalProps(Details.ReportItem,
					"BudgetBalanceItem");
				CurrentArea.Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 ""%2""';
						|ru = '%1 ""%2""';
						|en = '%1 ""%2""'; fa = '%1 ""%2""';
						|it = '%1 ""%2""';
						|pl = '%1 ""%2""';
						|tr = '%1 ""%2""'"),
					CurrentArea.Text,
					BudgetIndicator);
			EndIf;
			
			Factor = FinancialReportingServerCall.ValueOfAdditionalProps(Details.ReportItem,
				"DisplayedIndicators");
			IndicatorType = FinancialReportingServerCall.ValueOfAdditionalProps(Details.ReportItem,
				"IndicatorValueType");
			CurrentArea.Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 (%2, 3)';
						|ru = '%1 (%2, 3)';
						|en = '%1 (%2, 3)'; fa = '%1 (%2, 3)';
						|it = '%1 (%2, 3)';
						|pl = '%1 (%2, 3)';
						|tr = '%1 (%2, 3)'"),
					CurrentArea.Text,
					Factor,
					IndicatorType);
			
			PeriodOfShift = FinancialReportingServerCall.ValueOfAdditionalProps(Details.ReportItem, "PeriodOfShift");
			HasSettings = FinancialReportingServerCall.ObjectAttributeValue(Details.ReportItem, "HasSettings");
			If HasSettings = True
				Or ValueIsFilled(PeriodOfShift) Then
				CurrentArea.Text = CurrentArea.Text + Chars.LF
					+ NStr("vi = '<cài đặt được đặt>';
							|ru = '<установлены настройки>';
							|en = '<settings are set>'; fa = '<settings are set>';
							|it = '<impostazioni installate>';
							|pl = '<skonfigurowano ustawienia>';
							|tr = '<kurulan ayarlar>'");
			EndIf;
		ElsIf Details.ItemKind = ItemKind("BudgetFlowItem")
			Or Details.ItemKind = ItemKind("AllBudgetFlowItems") Then
			
			If Details.ItemKind <> ItemKind("AllBudgetFlowItems") Then
				BudgetFlowOrBalanceItem = FinReports.ValueOfAdditionalProps(Details.ReportItem, "BudgetFlowItem");
				CurrentArea.Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 ""%2""';
						|ru = '%1 ""%2""';
						|en = '%1 ""%2""'; fa = '%1 ""%2""';
						|it = '%1 ""%2""';
						|pl = '%1 ""%2""';
						|tr = '%1 ""%2""'"),
					CurrentArea.Text,
					BudgetFlowOrBalanceItem);
			EndIf;
			
			Factor = FinancialReportingServerCall.ValueOfAdditionalProps(Details.ReportItem,
				"DisplayedIndicators");
			CurrentArea.Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 (%2)';
						|ru = '%1 (%2)';
						|en = '%1 (%2)'; fa = '%1 (%2)';
						|it = '%1 (%2)';
						|pl = '%1 (%2)';
						|tr = '%1 (%2)'"),
					CurrentArea.Text,
					Factor);
			
			If Form.UseToEnterPlan Then
				AutocompletionFormula = FinReports.ValueOfAdditionalProps(Details.ReportItem,
					"Formula");
				If ValueIsFilled(AutocompletionFormula) Then
					CurrentArea.Text = CurrentArea.Text + Chars.LF
						+ NStr("vi = '<cấu hình tự động điền>';
								|ru = '<настроено автозаполнение>';
								|en = '<autofilling is configured>'; fa = '<autofilling is configured>';
								|it = '<compilazione automatica impostata>';
								|pl = '<ustawiono automatyczne wypełnienie>';
								|tr = '<otomatik doldurma ayarlandı>'");
				EndIf;
			Else
				PeriodOfShift = FinReports.ValueOfAdditionalProps(Details.ReportItem, "PeriodOfShift");
				HasSettings = FinReports.ObjectAttributeValue(Details.ReportItem, "HasSettings");
				If HasSettings = True
					Or ValueIsFilled(PeriodOfShift) Then
					CurrentArea.Text = CurrentArea.Text + Chars.LF
						+ NStr("vi = '<cài đặt được đặt>';
								|ru = '<установлены настройки>';
								|en = '<settings are set>'; fa = '<settings are set>';
								|it = '<impostazioni installate>';
								|pl = '<skonfigurowano ustawienia>';
								|tr = '<kurulan ayarlar>'");
				EndIf;
			EndIf;
			
		ElsIf Details.ItemKind = ItemKind("NonFinancialItem") Then
			
			NonFinancialItem = FinReports.ValueOfAdditionalProps(Details.ReportItem,
				"NonFinancialItem");
			CurrentArea.Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 ""%2""';
						|ru = '%1 ""%2""';
						|en = '%1 ""%2""'; fa = '%1 ""%2""';
						|it = '%1 ""%2""';
						|pl = '%1 ""%2""';
						|tr = '%1 ""%2""'"),
					CurrentArea.Text,
					NonFinancialItem);
			
			PeriodOfShift = FinReports.ValueOfAdditionalProps(Details.ReportItem, "PeriodOfShift");
			HasSettings = FinReports.ObjectAttributeValue(Details.ReportItem, "HasSettings");
			If HasSettings = True
				Or ValueIsFilled(PeriodOfShift) Then
				CurrentArea.Text = CurrentArea.Text + Chars.LF
					+ NStr("vi = '<cài đặt được đặt>';
							|ru = '<установлены настройки>';
							|en = '<settings are set>'; fa = '<settings are set>';
							|it = '<impostazioni installate>';
							|pl = '<skonfigurowano ustawienia>';
							|tr = '<kurulan ayarlar>'");
			EndIf;
			
		ElsIf Details.ItemKind = ItemKind("GroupFormula") Then
			
			TypeOfFormula = FinReports.ValueOfAdditionalProps(Details.ReportItem, "GroupFormula");
			CurrentArea.Text = NStr("vi = 'Công thức nhóm (%1)';
									|ru = 'Формула по группе (%1)';
									|en = 'Group formula (%1)'; fa = 'Group formula (%1)';
									|it = 'Formula per gruppo (%1)';
									|pl = 'Formuła wg grupy (%1)';
									|tr = '(%1) grubuna göre formül'");
			CurrentArea.Text = StringFunctionsClientServer.SubstituteParametersToString(CurrentArea.Text, TypeOfFormula);
			
		ElsIf Details.ItemKind = ItemKind("Group")
			Or Details.ItemKind = ItemKind("Dimension")
			Then
			
			CurrentArea.Text = "";
			
		ElsIf Details.ItemKind = ItemKind("TotalByGroup") Then
			
			CurrentArea.Text = NStr("vi = 'Tổng kết';
									|ru = 'Итог';
									|en = 'Total'; fa = 'جمع کل';
									|it = 'Totale';
									|pl = 'Total';
									|tr = 'Toplam'");
			
		ElsIf Details.ItemKind = ItemKind("EditedValue") Then
			
			CurrentArea.Text = GetFromTempStorage(Details.ReportItem).NameForPrinting;
			
		ElsIf Details.ItemKind = ItemKind("MonetaryIndicator")
			Or Details.ItemKind = ItemKind("NonMonetaryItem")
			Or Details.ItemKind = ItemKind("DerivedItem") Then
			
			CurrentArea.Text = FinReports.ObjectAttributeValue(Details.ReportItem, "NameForPrinting");
			
		Else
			
			CurrentArea.Text = CurrentArea.Text + Chars.LF + 
				FinReports.ValueOfAdditionalProps(Details.ReportItem, "Formula")
				
		EndIf;
			
	EndIf;
	
EndProcedure

// This function displays the configuration of a complex table
//
// Parameters:
//  Form - ClientApplicationForm - The form where the cell settings are located.
//  CurTableTree  - ValueTree - The tree of elements displayed in the settings table.
//
// Returns:
//   Structure - the size structure.
//
Function OutputComplexTableSetupTable(Form, CurTableTree) Export
	
	MergeDepth = BudgetReportingCacheCalculationServer.CalculateDepthOfLevels(CurTableTree);
	
	If Form.ThisIsASimpleTable Then
		FirstRow = 2;
	Else
		FirstRow = 4;
	EndIf;
	
	Form.FirstRow = FirstRow;
	Form.ReportPresentation.Area(,1,,1).ColumnWidth = 3;
	
	TableColumnTree = FinancialReportingServer.SubordinateItem(CurTableTree,
		"ItemKind", ItemKind("Columns"));
	HeaderHeight = BudgetReportingDisplayServer.TreeDepth(TableColumnTree.Rows);
	HeaderWidth = OutputTreeToMetrics(Form, FirstRow, TableColumnTree.Rows, 0, HeaderHeight, 2 + MergeDepth);
	
	MWidthOfTemplate = HeaderWidth;
	MCapHeight = HeaderHeight;
	
	SectionHeader = Form.ReportPresentation.Area(FirstRow, 2, FirstRow + HeaderHeight, 2 + MergeDepth - 1); // SpreadsheetDocumentRange 
	SectionHeader.Merge();
	SectionHeader.ColumnWidth = 30;
	SectionHeader.Text = "";
	ApplyAppearance(SectionHeader, "TableHeading");
	
	Area = Form.ReportPresentation.Area(FirstRow, 2, FirstRow + HeaderHeight, 2 + MergeDepth -1 + HeaderWidth);
	ApplyAppearance(Area, "Header");
	
	TableItems = FormDataToValue(Form.TableItems, Type("ValueTable")); // ValueTable
	TableItems.Indexes.Add("String, Column");
	
	TotalRows = 0;
	TableRowTree = FinancialReportingServer.SubordinateItem(CurTableTree, "ItemKind", ItemKind("Rows"));
	OutputParameters = New Structure;
	OutputParameters.Insert("TableItems",				TableItems);
	OutputParameters.Insert("ColumnTree",				TableColumnTree.Rows);
	OutputParameters.Insert("FirstRow",				FirstRow + HeaderHeight);
	OutputParameters.Insert("MergeDepth",			MergeDepth);
	
	OutputTreeInLines(Form,
			TableRowTree.Rows,
			OutputParameters,
			TotalRows);
	
	MTemplateHeight = HeaderHeight + TotalRows;
	
	// let's circle the entire table
	Area = Form.ReportPresentation.Area(
		FirstRow, 2, FirstRow + HeaderHeight + TotalRows, 2 + MergeDepth - 1 + HeaderWidth); // SpreadsheetDocumentRange
	ApplyAppearance(Area, "Header");
	
	Return New Structure("MWidthOfTemplate, MTemplateHeight, MCapHeight", MWidthOfTemplate, MTemplateHeight, MCapHeight);
	
EndFunction

// Called from the form creation event handler on the server.
//
// Parameters:
//  Form  - ClientApplicationForm - the form being created.
//
// Returns:
//   See FinancialReportingClientServer.ReportElementStructure
//
Function FormWhenCreatedOnServer(Form) Export
	Var ObjectData;
	
	If Form.Parameters.Property("AutoTest_2") Then
		Return Form.FormAttributeToValue("Object");
	EndIf;
	
	Form.ItemAddressInStorage = Form.Parameters.ItemAddressInStorage;
	Write = Not ValueIsFilled(Form.ItemAddressInStorage);
	Form.Items.FormWrite.Visible   = Write;
	Form.Items.FormReread.Visible = Write;
	If Form.Items.Find("FormCopy") <> Undefined Then
		Form.Items.FormCopy.Visible               = Write;
	EndIf;
	If Form.Items.Find("FormSetDeletionMark") <> Undefined Then
		Form.Items.FormSetDeletionMark.Visible = Write;
	EndIf;
	
	Form.Items.FormWriteAndClose.Visible                = Write;
	Form.Items.FormWriteAndClose.DefaultButton        = Write;
	Form.Items.FormCompleteEditing.Visible         = Not Write;
	Form.Items.FormCompleteEditing.DefaultButton = Not Write;
	Form.Items.FormCompleteEditing.Enabled       = Not Form.ReadOnly;
	If Not Write Then
		Form.Items.FormWriteAndClose.Title = NStr("vi = 'Kết thúc soạn';
													|ru = 'Завершить редактирование';
													|en = 'Finish editing'; fa = 'پایان ویرایش';
													|it = 'Terminare la modifica';
													|pl = 'Zakończ edycję';
													|tr = 'Düzenlemeyi bitir'");
	EndIf;
	
	If Not Write Then
		
		ObjectData = GetFromTempStorage(Form.ItemAddressInStorage);
		ElementTables = "FormulaOperands, ItemKindAttributes, TableItems, AdditionalFields, CalculationsRules,
		                  |AppearanceItems, RegisteredRows, DesigningColumns, DrillDownOfAppearanceItemFilterFields, ValueSources";
		FillPropertyValues(Form.Object, ObjectData,,ElementTables);
		TableStructure = New Structure(ElementTables);
		
		For Each KeyAndValue In TableStructure Do
			
			If KeyAndValue.Key = "RegisteredRows"
				Or KeyAndValue.Key = "DesigningColumns" Then
				Form.Object[KeyAndValue.Key].Clear();
				Continue;
			EndIf;
			
			If TypeOf(ObjectData[KeyAndValue.Key]) = Type("ValueTable") Then
				Form.Object[KeyAndValue.Key].Load(ObjectData[KeyAndValue.Key]);
			EndIf;
			
		EndDo;
		
	Else
		
		ObjectData = Form.FormAttributeToValue("Object");
		
	EndIf;
	
	ItemKindAttributes = New Structure; 
	For Each AdditionalAttribute In Form.Object.ItemKindAttributes Do
		ItemKindAttributes.Insert(AdditionalAttribute.Attribute.PredefinedDataName, AdditionalAttribute.Value);
	EndDo;
	FillPropertyValues(Form, ItemKindAttributes);
	
	Attributes = Form.GetAttributes();
	ThereIsComposer = False;
	For Each Attribute In Attributes Do
		If Attribute.Name = "Composer" Then
			ThereIsComposer = True;
			Break;
		EndIf;
	EndDo;
	
	If ThereIsComposer Then
		SetFilterSettings(Form, Form.Composer, ObjectData.ItemKind, ObjectData.AdditionalSelection);
	EndIf;
	
	Return ObjectData;
	
EndFunction

// Called before writing an object in the form
//
// Parameters:
//  Form  - ClientApplicationForm - The Form in which the recording takes place. Contains including:
//  	* Composer - DataCompositionSettingsComposer - 
//  Object - CatalogObject.FinancialReportItems - the object being recorded.
//  Cancel  - Boolean - Indicates that the program is being processed.
//  AdditionalMode  - EnumRef.AdditionalModesOfReportItems, Undefined - indicates whether the form is in an additional mode.
//
Procedure FormBeforeWritingToServer(Form, Object, Cancel, AdditionalMode = Undefined) Export
	
	AdditionalAttributes = FinancialReportingServerCall.FormUsageParameters(Object.ItemKind, Object, AdditionalMode).Attributes;
	Object.ItemKindAttributes.Clear();
	
	For Each Attribute In AdditionalAttributes Do
		FinancialReportingServerCall.SetValueOfAdditionalProps(
													Object, Attribute.Key, Form[Attribute.Key])
	EndDo;
	
	Object.HasSettings = False;
	Form.Object.HasSettings = False;
	For Each Attribute In Form.GetAttributes() Do
		If Attribute.Name = "Composer" Then
			
			Settings = Form.Composer.GetSettings();
			For Each FilterElement In Settings.Filter.Items Do
				If FilterElement.Use Then
					Object.HasSettings = True;
					Form.Object.HasSettings = True;
					Break;
				EndIf;
			EndDo;
			Object.AdditionalSelection = New ValueStorage(Settings);
			Break;
			
		EndIf;
	EndDo;
		
	If ValueIsFilled(Form.ItemAddressInStorage) Then
		Cancel = True;
		FinancialReportingServerCall.PlaceItemInStorage(Object, Form.ItemAddressInStorage);
	EndIf;
	
EndProcedure

// Sets the selection field settings in the form
//
// Parameters:
//  Attributes - Array - Array of form details.
//  ReceiverComposer - DataCompositionSettingsComposer - The field in the form Builder where the selection is set.
//  ItemKind  - EnumRef.FinancialReportItemKinds - View of part of the financial report.
//  AdditionalSelection  - ValueStorage - Saved selection settings.
//
Procedure SetFilterSettings(Attributes, ReceiverComposer = Undefined, ItemKind, AdditionalSelection) Export
	
	#Region DefiningAvailableFields
	If ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
		Or ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
		Or ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem
		Or ItemKind = Enums.FinancialReportItemKinds.SetUpCalculationRules Then
		
		FilterFields = New Structure();
		
		If ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
			Or ItemKind = Enums.FinancialReportItemKinds.SetUpCalculationRules Then
			Selection = GetSelectionOfElementAnalytics(Attributes.BudgetFlowItem);
			
		ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
			Selection = GetSelectionOfElementAnalytics(Attributes.BudgetBalanceItem);
			
		Else
			Selection = GetSelectionOfElementAnalytics(Attributes.NonFinancialItem);
		EndIf;
		
		While Selection.Next() Do
			Var_Key = FinancialReportingCached.NameOfBudgetReportField(Selection.Ref);
			FilterFields.Insert(Var_Key, Selection.Ref)
		EndDo;
		
	ElsIf ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems
		Or ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
		
		FilterFields = New Structure();
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	BudgetFlowItemDimensions.Ref,
		|	BudgetFlowItemDimensions.PredefinedDataName
		|FROM
		|	ChartOfCharacteristicTypes.BudgetFlowItemDimensions AS BudgetFlowItemDimensions
		|WHERE
		|	NOT BudgetFlowItemDimensions.DeletionMark
		|
		|ORDER BY
		|	BudgetFlowItemDimensions.Description";
		
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			Var_Key = FinancialReportingCached.NameOfBudgetReportField(Selection.Ref);
			FilterFields.Insert(Var_Key, Selection.Ref)
		EndDo;
		
	ElsIf ItemKind = Enums.FinancialReportItemKinds.Dimension
		And Attributes.DimensionType = Enums.TypesOfBudgetReportDimensions.AccountingRegisterDimension Then
		FilterFields = New Structure(Attributes.DimensionName);
		ConfigurationScheme = AccountingMeasurementSelectionScheme(Attributes.DimensionName);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.Dimension
		And Attributes.DimensionType = Enums.TypesOfBudgetReportDimensions.ExtDimension Then
		FilterFields = New Structure("ExtDimension1", Attributes.ExtDimensionType);
		ConfigurationScheme = ExtDimensionSelectionScheme(Attributes.ExtDimensionType);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.Dimension
		And (Attributes.DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension
		Or Attributes.DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension)
		And Attributes.ShowItemHierarchy Then
		FilterFields = New Structure("Parent", New (BudgetingCached.TypesOfAnalyticsType(Attributes.DimensionKind)[0]));
		ConfigurationScheme = GroupSelectionScheme(Attributes.DimensionKind);
	ElsIf ItemKind = Enums.FinancialReportItemKinds.MonetaryIndicator Then
		FilterFields = New Structure("Account", Attributes.GLAccount_);
		ConfigurationScheme = SchemeOfSelectionOfMonetaryIndicator(Attributes.GLAccount_, Attributes.TotalType);
	Else
		Return;
	EndIf;
	
	#EndRegion
	
	MatchingSelectionElements = New Map;
	MatchingSelectionElements.Insert("UseFilterByCompany", "Organization");
	MatchingSelectionElements.Insert("UseFilterByDepartment", "Department");
	MatchingSelectionElements.Insert("UseFilterScenario", "Scenario");
	If ItemKind <> Enums.FinancialReportItemKinds.NonFinancialItem Then
		MatchingSelectionElements.Insert("UseStatusFilter", "Status");
	EndIf;
	
	#Region AddingSelections
	
	If ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems
		Or ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems
		Or ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
		Or ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
		Or ItemKind = Enums.FinancialReportItemKinds.SetUpCalculationRules Then
		
		For Each KeyAndValue In MatchingSelectionElements Do
			If Attributes[KeyAndValue.Key] Then
				FilterFields.Insert(KeyAndValue.Value);
			EndIf;
		EndDo;
		
	EndIf;
	
	If ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
		
		NFPDetails = Common.ObjectAttributesValues(Attributes.NonFinancialItem, "ByCompanies, ByScenarios, ByBusinessUnits");
		If Attributes.UseFilterByCompany
			And NFPDetails.ByCompanies Then
			FilterFields.Insert("Organization");
		EndIf;
	
		If Attributes.UseFilterByDepartment
			And NFPDetails.ByBusinessUnits Then
			FilterFields.Insert("Department");
		EndIf;
		
		If Attributes.UseFilterScenario
			And NFPDetails.ByScenarios Then
			FilterFields.Insert("Scenario");
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	If ConfigurationScheme = Undefined Then
		ConfigurationScheme = MeasurementSelectionScheme(FilterFields);
	EndIf;
	
	SchemaURL = PutToTempStorage(ConfigurationScheme.Schema, Attributes.UUID);
	
	LoadingSettingsIntoComposerIsRequired = False;
	If ReceiverComposer = Undefined Then
		ReceiverComposer = FinancialReportingServer.SchemaComposer(ConfigurationScheme.Schema);
		
		LoadingSettingsIntoComposerIsRequired = True;
	EndIf;
	
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(SchemaURL);
	ReceiverComposer.Initialize(AvailableSettingsSource);
	
	If LoadingSettingsIntoComposerIsRequired Then
		ReceiverComposer.LoadSettings(ConfigurationScheme.Settings);
	EndIf;
	
	If AdditionalSelection <> Undefined Then
		If TypeOf(AdditionalSelection) = Type("ValueStorage") Then
			MetricSettings = AdditionalSelection.Get();
		Else
			MetricSettings = AdditionalSelection;
		EndIf;
		If MetricSettings <> Undefined Then
			ReceiverComposer.LoadSettings(MetricSettings);
		EndIf;
	EndIf;
	
	ReceiverComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	Dimensions = New Structure();
	Dimensions.Insert("Scenario");
	Dimensions.Insert("Organization");
	Dimensions.Insert("Department");
	Dimensions.Insert("LineOfBusiness");
	
	For Each Field In FilterFields Do
		If Dimensions.Property(Field.Key)
			And FinancialReportingServer.FindSelectionElement(ReceiverComposer.Settings.Filter, Field.Key) = Undefined Then
			Item = FinancialReportingServer.NewFilter(ReceiverComposer.Settings.Filter, Field.Key);
			Item.Use = False;
		EndIf;
	EndDo;
	
	ListToDelete = New Array;
	BudgetReportingDisplayServer.GetCustomizableSelectionItems(ReceiverComposer.Settings.Filter, ListToDelete, "");
	For Each ElementToDelete In ListToDelete Do
		ReceiverComposer.Settings.Filter.Items.Delete(ElementToDelete);
	EndDo;
	
	#Region RemovingUnusedItems
	
	If ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems
		Or ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems
		Or ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
		Or ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
		Or ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem
		Or ItemKind = Enums.FinancialReportItemKinds.SetUpCalculationRules Then
		
		For Each KeyAndValue In MatchingSelectionElements Do
			If Not Attributes[KeyAndValue.Key] Then
				Filter = ReceiverComposer.Settings.Filter;
				Item = FinancialReportingServer.FindSelectionElement(Filter, KeyAndValue.Value);
				If Item <> Undefined Then
					Filter.Items.Delete(Item);
				EndIf;
			EndIf;
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	ReceiverComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
EndProcedure

// The procedure saves the configured report view structure.
//
// Parameters:
//  ReportKind - CatalogRef.FinancialReportTypes, CatalogRef.BudgetProfiles - Link to the reference list element
//  					whose structure we are saving.
//  ReportViewElements - ValueTree - Tree of elements of the report type or budget type.
//  DeletionMark - Boolean - Indicates whether the deletion is marked.
//
Procedure WriteStructureOfReportView(ReportKind, ReportViewElements, DeletionMark) Export
	
	ReportViewElementsUsed = New ValueList;
	ParametersForWritingToStructure = GetRecordParametersInReportStructure();
	ParametersForWritingToStructure.ReportKind       = ReportKind;
	ParametersForWritingToStructure.DeletionMark = DeletionMark;
	FillMeasurementsWithChangesInFillSources(ReportViewElements, ParametersForWritingToStructure.ReadyForRewriting);
	
	HowToWriteReportViewStructure(ReportViewElements, ParametersForWritingToStructure, ReportViewElementsUsed);

	Query = New Query;
	Query.Text = 
	"SELECT
	|	FinancialReportItems.Ref AS Ref,
	|	FinancialReportItems.Description AS Description
	|FROM
	|	Catalog.FinancialReportItems AS FinancialReportItems
	|WHERE
	|	FinancialReportItems.Owner = &Owner
	|	AND NOT FinancialReportItems.Ref IN (&Ref)";

	Query.SetParameter("Owner", ReportKind);
	Query.SetParameter("Ref", ReportViewElementsUsed);

	QueryResult = Query.Execute();
	Selection = QueryResult.Select();

	SetPrivilegedMode(True);
	While Selection.Next() Do
		Object = Selection.Ref.GetObject(); // CatalogObject
		If Object <> Undefined Then
			Try
				Object.Delete();
			Except
				LanguageCode = Common.DefaultLanguageCode();
				If TypeOf(ReportKind) = Type("CatalogRef.BudgetProfiles") Then
					LogEventName = NStr("vi = 'Bản ghi loại ngân sách';
										|ru = 'Запись вида бюджета';
										|en = 'Save budget profile'; fa = 'Save budget profile';
										|it = 'Registrazione del tipo di bilancio';
										|pl = 'Zapis rodzaju budżetu';
										|tr = 'Bütçe türünün kaydı'", LanguageCode);
					ErrorText = NStr("vi = 'Khi ghi loại ngân sách %1, không thể xóa mục báo cáo tài chính: %2 do: %3';
									|ru = 'При записи вида бюджета %1 не удалось удалить элемент финансового отчета: %2 по причине: %3';
									|en = 'Cannot delete financial report item: %2 while saving the budget profile %1. Reason: %3'; fa = 'Cannot delete financial report item: %2 while saving the budget profile %1. Reason: %3';
									|it = 'Durante la registrazione del tipo di bilancio %1non è stato possibile eliminare l''elemento del report finanziario:%2 a causa di:%3';
									|pl = 'Podczas zapisywania rodzaju budżetu %1 usuwanie elementu raportu finansowego: %2 nie powiodło się z powodu: %3';
									|tr = '%1 bütçe profilinin kaydedilmesi için finansal rapor öğesi silinemedi: %2 şu sebeple: %3'",
						LanguageCode);
				Else
					LogEventName = NStr("vi = 'Bản ghi loại báo cáo tài chính';
										|ru = 'Запись вида финансового отчета';
										|en = 'Save financial report type'; fa = 'Save financial report type';
										|it = 'Registrazione del tipo di report finanziario';
										|pl = 'Zapis rodzaju raportu finansowego';
										|tr = 'Finansal rapor türünün kaydedilmesi'", LanguageCode);
					ErrorText = NStr("vi = 'Khi lập loại báo cáo tài chính%1, không thể xóa phần tử của báo cáo tài chính:%2 do:%3';
									|ru = 'При записи вида финансового отчета %1 не удалось удалить элемент финансового отчета: %2 по причине: %3';
									|en = 'Cannot delete financial report item: %2 while saving the financial report type %1. Reason: %3'; fa = 'Cannot delete financial report item: %2 while saving the financial report type %1. Reason: %3';
									|it = 'Durante la registrazione del tipo di report finanziario %1non è stato possibile eliminare l''elemento del report finanziario:%2 a causa di:%3';
									|pl = 'Podczas zapisywania rodzaju raportu finansowego %1 usuwanie elementu raportu finansowego: %2 nie powiodło się z powodu: %3';
									|tr = '%1 finansal rapor türünün kaydedilmesi için finansal rapor öğesi silinemedi: %2 şu sebeple: %3'",
						LanguageCode);
				EndIf;
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, ReportKind,
					Selection.Description, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(LogEventName,
						EventLogLevel.Error,
						Metadata.Catalogs.FinancialReportItems,
						Selection.Ref,
						ErrorText);
			EndTry;
		EndIf;
	EndDo;
	SetPrivilegedMode(False);
	
EndProcedure

// The procedure updates the names for printing items of all types of budgets.
//
// Parameters:
//  AttributeValue - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems, CatalogRef.NonFinancialItemsOfBudgets - 
//   A budget item, Budget Balance Item, or a Non-financial Item with A changed name.
//  Description - String - updated name for printing
//
Procedure UpdateTitlesForPrinting(AttributeValue, Description) Export
	
	If TypeOf(AttributeValue) = Type("CatalogRef.BudgetFlowItems") Then
		Attribute = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.BudgetFlowItem;
	ElsIf TypeOf(AttributeValue) = Type("CatalogRef.BudgetBalanceItems") Then
		Attribute = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.BudgetBalanceItem;
	ElsIf TypeOf(AttributeValue) = Type("CatalogRef.NonFinancialItemsOfBudgets") Then
		Attribute = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.NonFinancialItem;
	Else
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Attribute", Attribute);
	Query.SetParameter("Value", AttributeValue);
	Query.Text = 
	"SELECT
	|	FinancialReportItemsItemKindAttributes.Ref AS Ref,
	|	FinancialReportItemsItemKindAttributes.Ref.Owner AS BudgetProfile,
	|	FinancialReportItemsItemKindAttributes.Ref.NameForPrinting AS NameForPrinting,
	|	ISNULL(ItemKindAttributes_PresentationExpression.Value, """") AS PresentationExpression
	|FROM
	|	Catalog.FinancialReportItems.ItemKindAttributes AS FinancialReportItemsItemKindAttributes
	|		LEFT JOIN Catalog.FinancialReportItems.ItemKindAttributes AS ItemKindAttributes_PresentationExpression
	|		ON FinancialReportItemsItemKindAttributes.Ref = ItemKindAttributes_PresentationExpression.Ref
	|			AND (ItemKindAttributes_PresentationExpression.Attribute = VALUE(ChartOfCharacteristicTypes.ItemAttributesOfFinancialReports.PresentationExpression))
	|WHERE
	|	FinancialReportItemsItemKindAttributes.Attribute = &Attribute
	|	AND FinancialReportItemsItemKindAttributes.Value = &Value
	|TOTALS BY
	|	BudgetProfile";
	Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While Selection.Next() Do
		
		DetailedSampling = Selection.Select();
		While DetailedSampling.Next() Do
			FOItemElement = DetailedSampling.Ref.GetObject();
			FOItemElement.Lock();
			If IsBlankString(DetailedSampling.PresentationExpression) Then
				FOItemElement.NameForPrinting = Description;
			Else
				NameForPrinting = DetailedSampling.NameForPrinting;
				ErrorText = FinancialReportingServerCall.ErrorTextOfExpressionOfSortRepresentation(DetailedSampling.PresentationExpression, AttributeValue, NameForPrinting);
				If IsBlankString(ErrorText) Then
					FOItemElement.NameForPrinting = NameForPrinting;
				EndIf;
			EndIf;
			FOItemElement.Write();
		EndDo;
		
		RecordSet = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.CreateRecordSet();
		RecordSet.Filter.BudgetProfile.Set(Selection.BudgetProfile);
		RecordSet.Filter.CacheKind.Set(Enums.BudgetCacheKinds.ItemTreeWithoutAdditionalItems);
		RecordSet.Write();
		
		RecordSet.Filter.CacheKind.Set(Enums.BudgetCacheKinds.ItemTreeWithAdditionalItems);
		RecordSet.Write();
		
		RecordSet.Filter.CacheKind.Set(Enums.BudgetCacheKinds.OutputTree);
		RecordSet.Write();
		
	EndDo;
	
EndProcedure
#Region InternationalReporting

// Generates and configures the data layout scheme to get the values of the financial statement indicator.
// Parameters:
//  Factor - ValueTree, ValueTreeRow - this is the result of a request for the Catalog Template.Types of financial reports.Derevoelementovot report, has the following properties:
//  	* HasSettings - Boolean -
//  	* AdditionalSelection - ValueStorage -
//  	* Comment - String -
//  	* ReverseSign - Boolean -
//  	* LinkedItem1 - CatalogRef.FinancialReportItems -
//  	* ReportItemIsAnAssociatedItem - CatalogRef.FinancialReportItems -
//  	* NameForPrinting - String -
//  	* ItemKind - EnumRef.FinancialReportItemKinds -
//  	* ReportKind - CatalogRef.FinancialReportTypes, CatalogRef.BudgetProfiles -
//  	* Code - Number -
//  	* Description - String -
//  	* Parent - CatalogRef.FinancialReportItems -
//  	* ReportItem - CatalogRef.FinancialReportItems -
//  	* Note - String -
//  Dimensions - ValueList - A list of dimensions for the current position of the metric in the report tree, if any.
//  ExtDimension - Structure - Description of the ExtDimension type for the Cur position of the indicator in the report tree. Description:
//  	* Value - Structure - Contains:
//  		** Kind - Arbitrary -
//  		** HasSettings - Boolean -
//  		** Description - String -
//  		** Filter - ValueStorage - contains a structure with a value of the type selectioncomposed Data
//  Resource - String - Name of the accounting resource from which to get the indicator value.
//
// Returns:
//   Structure - Structure Fields:
//     *Schema - DataCompositionSchema - the scheme for obtaining values of this indicator report
//     *Settings - DataCompositionSettings - settings schemes for obtaining values of the indicator report.
//
Function IndicatorScheme(Factor, Dimensions = Undefined, ExtDimension = Undefined, Resource = "Sum") Export
	
	If Factor.ItemKind = Enums.FinancialReportItemKinds.MonetaryIndicator Then
		IndicatorScheme = MonetaryIndicatorScheme(Factor, Dimensions, ExtDimension, Resource);
	ElsIf Factor.ItemKind = Enums.FinancialReportItemKinds.DerivedItem Then
		IndicatorScheme = SchemeOfDerivedIndicator(Factor, Dimensions, ExtDimension);
	Else
		IndicatorScheme = SchemeOfNonMonetaryIndicator(Factor, Dimensions);
	EndIf;
	Return IndicatorScheme;

EndFunction

#EndRegion
#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Or Not Parameters.Property("ItemKind") Then
		Raise NStr("vi = 'Nội dung của danh mục hệ thống ""Phần tử báo cáo tài chính"" 
									|đang soạn trong danh sách đối tượng chủ 
									|""Dạng ngân sách"" và ""Dạng báo cáo tài chính"".';
									|ru = 'Содержимое служебного справочника ""Элементы финансовых отчетов"" 
									|редактируется в справочниках-владельцах 
									|""Виды бюджетов"" и ""Виды финансовых отчетов"".';
									|en = 'To edit content of the ""Financial report items"" service catalog 
									|, use 
									|""Budget profiles"" or ""Financial report types"" owner catalogs.'; fa = 'To edit content of the ""Financial report items"" service catalog 
									|, use 
									|""Budget profiles"" or ""Financial report types"" owner catalogs.';
									|it = 'I contenuti della directory di servizio ""Elementi di report finanziario"" 
									|sono modificati nelle directory-proprietario 
									| ""Tipi di bilancio"" e ""Tipi di report finanziari"".';
									|pl = 'Zawartość katalogu serwisowego ""Elementy raportów finansowych"" 
									|jest edytowana w katalogach właścicielach 
									|""Rodzaje budżetów"" i ""Rodzaje raportów finansowych"".';
									|tr = 'Hizmet kataloğunun içindeki ""Finansal rapor öğeleri"" 
									|sahip dizinlerinde düzenlenir 
									| ""Bütçe profili"" ve ""Finansal rapor türleri"".'");
	EndIf;
	
	If FormType <> "ObjectForm" Then
		Return;
	EndIf;
	
	AdditionalMode = Undefined;
	Parameters.Property("AdditionalFormMode", AdditionalMode);
	
	OpeningBudgetReportElementForm = Parameters.Property("BudgetingModel");
	
	If Parameters.Property("ItemKind") Then
		
		StandardProcessing = False;
		SelectedForm = FinancialReportingServerCall.FormUsageParameters(
			Parameters.ItemKind,
			Parameters.ItemAddressInStorage,
			AdditionalMode,
			OpeningBudgetReportElementForm).FormName;
		
	ElsIf Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
		
		StandardProcessing = False;
		SelectedForm = FinancialReportingServerCall.FormUsageParameters(
			Parameters.Key.ItemKind,
			Parameters.Key,
			AdditionalMode,
			OpeningBudgetReportElementForm).FormName;
		
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function MeasurementSelectionScheme(StructureOfDimensionNames)
	
	FinReports = FinancialReportingServer;
	DCSchema = DataCompositionServer.EmptyCircuit();
	DataSet = DataCompositionServer.AddEmptyDataSet(DCSchema);
	
	DimensionName = "";
	AddSuffix = False;
	For Each KeyAndValue In StructureOfDimensionNames Do
		
		DimensionName = DimensionName + ?(IsBlankString(DimensionName), "", ",
			|");
		
		If TypeOf(KeyAndValue.Value) = Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions") Then
			
			NameOfAnalyticsViewParameter_ = "DimensionKind" + KeyAndValue.Key;
			
			ExpressionParameters = BudgetingServer.TemplateForParametersForGettingTextOfFieldWithConditionForTypeOfAnalytics();
			ExpressionParameters.ExpressionNumberOfAnalyticsUsed = "BudgetFlowItem.NumberOfUsedDimensions";
			ExpressionParameters.ExpressionViewAnalyticsWithoutIndex = "BudgetFlowItem.DimensionKind";
			ExpressionParameters.ExpressingAnalyticsValueWithoutIndex = "Dimension";
			ExpressionParameters.NameOfAnalyticsViewParameter = NameOfAnalyticsViewParameter_;
			
			ExpressionAnalytics = BudgetingServer.TextOfFieldWithConditionByTypeOfAnalytics(ExpressionParameters);
			
			DimensionName = DimensionName + "(" + ExpressionAnalytics + ")" + ?(AddSuffix, ".*", "") + " AS " + KeyAndValue.Key;
			
			Parameter = DCSchema.Parameters.Add();
			Parameter.Name = NameOfAnalyticsViewParameter_;
			Parameter.Value = KeyAndValue.Value;
			Parameter.IncludeInAvailableFields = False;
			Parameter.UseRestriction = True;
			
			SetField = FinReports.NewSetField(DataSet, KeyAndValue.Key,,KeyAndValue.Value.Description);
			SetField.ValueType = KeyAndValue.Value.ValueType;
			
		Else
			
			CollectionOfMDObjects = Metadata.AccumulationRegisters.BudgetTurnovers.Dimensions; // MetadataObjectCollection -
			Dimension = CollectionOfMDObjects.Find(KeyAndValue.Key);
			Title = KeyAndValue.Key;
			If Dimension <> Undefined Then
				Title = Dimension.Synonym;
			EndIf;
			SetField = FinReports.NewSetField(DataSet, KeyAndValue.Key,,Title);
			DimensionName = DimensionName + KeyAndValue.Key + ?(AddSuffix, ".*", "") + " AS " + KeyAndValue.Key;
			
		EndIf;
	EndDo;
	
	QueryText = "
	|SELECT
	|	TurnoversAndTurnovers.CountTurnover,
	|	TurnoversAndTurnovers.SumManTurnover,
	|	TurnoversAndTurnovers.SumComplTurnover
	|FROM
	|	&SourceTable2 AS TurnoversAndTurnovers";
	SourceTable2 = "AccumulationRegister.BudgetTurnovers.Turnovers(, , , %1)";
	If StructureOfDimensionNames.Count() Then
		SourceTable2 = StringFunctionsClientServer.SubstituteParametersToString(SourceTable2, "{" + DimensionName + "}");
	Else
		SourceTable2 = StringFunctionsClientServer.SubstituteParametersToString(SourceTable2, "");
	EndIf;
	QueryText = StrReplace(QueryText, "&SourceTable2", SourceTable2);
	
	DataSet.AutoFillAvailableFields = False;
	DataSet.Query = QueryText;
	Composer = FinReports.SchemaComposer(DCSchema);
	IndicatorScheme = New Structure("Schema, Settings",DCSchema, Composer.GetSettings());
	Return IndicatorScheme;
	
EndFunction

Function SchemeOfSelectionOfMonetaryIndicator(GLAccount, TotalType)
	
	FinReports = FinancialReportingServer;
	DCSchema = DataCompositionServer.EmptyCircuit();
	DataSet = DataCompositionServer.AddEmptyDataSet(DCSchema);
	
	DimensionName = "";
	SelectingBuilder = "";
	LocalAccounting = (TypeOf(GLAccount) = LocalAccntingClientServer.TypeChartOfAccounts());
	HasCorrespondence = True;
	If TypeOf(GLAccount) = FinancialAccountingClientServer.TypeChartOfAccounts() Then
		OptionForGeneratingTransactions = FinancialAccountingOfGeneralPurpose.OptionForGeneratingTransactionsByAccount(GLAccount);
		If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
			HasCorrespondence = False;
		EndIf;
	EndIf;
	ThisTurnover = TotalType = Enums.TypesOfTotals.Turnover
			Or TotalType = Enums.TypesOfTotals.TurnoverDr
			Or TotalType = Enums.TypesOfTotals.TurnoverCr;
	
	If GLAccount.Currency1 Then
		DimensionName = DimensionName + "(Currency).* AS Currency";
	EndIf;
	
	ExtDimensionNumber = 1;
	For Each ExtdimensionAccounts In GLAccount.ExtDimensionTypes Do
		NameExtdimension = "ExtDimension" + String(ExtDimensionNumber);
		ExtdimensionHeader = ExtdimensionAccounts.ExtDimensionType.Description;
		SetField = FinReports.NewSetField(DataSet,NameExtdimension,,ExtdimensionHeader);
		SetField.ValueType = ExtdimensionAccounts.ExtDimensionType.ValueType;
		DimensionName = DimensionName + ?(IsBlankString(DimensionName), "", "," + Chars.LF);
		DimensionName = DimensionName + "("+NameExtdimension + ").* AS " + NameExtdimension;
		SelectingBuilder = SelectingBuilder + ?(IsBlankString(SelectingBuilder), "", "," + Chars.LF);
		SelectingBuilder = SelectingBuilder + "RegisterData."+NameExtdimension + ".*";
		ExtDimensionNumber = ExtDimensionNumber + 1;
	EndDo;
	
	If ThisTurnover And HasCorrespondence Then
		DimensionName = DimensionName + ?(IsBlankString(DimensionName), "", "," + Chars.LF);
		DimensionName = DimensionName + "(CurrencyBalanced).* AS CurrencyBalanced";
		SetHeader_ = NStr("vi = 'Tiền tệ đối ứng';
							|ru = 'Кор. валюта';
							|en = 'Cor. currency'; fa = 'ارز مقابل';
							|it = 'Valuta corrispondente';
							|pl = 'Kor. waluta';
							|tr = 'Muhabir para birimi'");
		SetField = FinReports.NewSetField(DataSet,"CurrencyBalanced",,SetHeader_);
		SelectionByCorAccount = "{(BalancedAccount).* AS BalancedAccount}";
		FieldTitle = NStr("vi = 'Tài khoản đối ứng';
							|ru = 'Кор. счет';
							|en = 'Corr.account'; fa = 'حساب مقابل';
							|it = 'Conto corrispondente';
							|pl = 'Rachunek koresp.';
							|tr = 'Muhabir hesap'");
		SetField = FinReports.NewSetField(DataSet,"BalancedAccount",,FieldTitle);
		For ExtDimensionNumber = 1 To 3 Do
			NameCorExtdimension = "BalancedExtDimension" + String(ExtDimensionNumber);
			FieldTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khoản mục đối ứng%1';
					|ru = 'Кор. Субконто%1';
					|en = 'Corr. Extra dimension%1'; fa = 'Corr. Extra dimension%1';
					|it = 'Cor. Subconto%1';
					|pl = 'Kor. Subkonto%1';
					|tr = 'Muhabir ekstra boyut%1'"),
				ExtDimensionNumber);
			SetField = FinReports.NewSetField(DataSet,NameCorExtdimension,,FieldTitle);
			DimensionName = DimensionName + ?(IsBlankString(DimensionName), "", "," + Chars.LF);
			DimensionName = DimensionName + "("+NameCorExtdimension + ").* AS " + NameCorExtdimension;
			SelectingBuilder = SelectingBuilder + ?(IsBlankString(SelectingBuilder), "", "," + Chars.LF);
			SelectingBuilder = SelectingBuilder + "RegisterData."+NameCorExtdimension + ".*";
		EndDo;
	EndIf;
	
	DimensionName = ?(IsBlankString(DimensionName),"","{" + DimensionName + "}");
	SelectingBuilder = ?(IsBlankString(SelectingBuilder),"","{WHERE" + Chars.LF + SelectingBuilder + "}");

	Source = LocalAccntingClientServer.ChartOfAccountsName();
	If Not LocalAccounting Then
		Source =  FinancialAccountingOfGeneralPurpose.NameOfAccountingRegisterForTransactionsOnAccountingAccount(GLAccount);
	EndIf;
	If ThisTurnover Then
		If HasCorrespondence Then
			QueryText = 
			"SELECT
			|	RegisterData.ExtDimension1,
			|	RegisterData.ExtDimension2,
			|	RegisterData.ExtDimension3,
			|	RegisterData.BalancedAccount,
			|	RegisterData.BalancedExtDimension1,
			|	RegisterData.BalancedExtDimension2,
			|	RegisterData.BalancedExtDimension3
			|FROM
			|	&SourceTable2 AS RegisterData";
			SourceTable2 = StrTemplate("AccountingRegister.%1.Turnovers(, , , , , %2, %3, )", Source, DimensionName, SelectionByCorAccount);
			QueryText = StrReplace(QueryText, "&SourceTable2", SourceTable2);
		Else
			QueryText = 
			"SELECT
			|	RegisterData.ExtDimension1,
			|	RegisterData.ExtDimension2,
			|	RegisterData.ExtDimension3
			|FROM
			|	&SourceTable2 AS RegisterData";
			SourceTable2 = StrTemplate("AccountingRegister.%1.Turnovers(, , , , , %2)", Source, DimensionName);
			QueryText = StrReplace(QueryText, "&SourceTable2", SourceTable2);
		EndIf;
	Else
		QueryText = 
		"SELECT
		|	RegisterData.ExtDimension1,
		|	RegisterData.ExtDimension2,
		|	RegisterData.ExtDimension3,
		|	RegisterData.SumBalance AS Value
		|FROM
		|	&SourceTable2 AS RegisterData";
		SourceTable2 = StrTemplate("AccountingRegister.%1.Balance(, , , %2)", Source, DimensionName);
		QueryText = StrReplace(QueryText, "&SourceTable2", SourceTable2);
	EndIf;
	QueryText = QueryText + Chars.LF + SelectingBuilder;
	
	DataSet.AutoFillAvailableFields = False;
	DataSet.Query = QueryText;
	Composer = FinReports.SchemaComposer(DCSchema);
	IndicatorScheme = New Structure("Schema, Settings",DCSchema, Composer.GetSettings());
	Return IndicatorScheme;
	
EndFunction

Function ExtDimensionSelectionScheme(ExtDimensionType)
	
	FinReports = FinancialReportingServer;
	DCSchema = DataCompositionServer.EmptyCircuit();
	DataSet = DataCompositionServer.AddEmptyDataSet(DCSchema);
	
	LocalAccounting = TypeOf(ExtDimensionType) = LocalAccntingClientServer.TypeSpeciesExtdimension() ;
	
	SelectionByTypeOfExtdimension = "{(&ExtDimensionType)}";
	Parameter = DCSchema.Parameters.Add();
	Parameter.Name = "ExtDimensionType";
	Parameter.Value = ExtDimensionType;
	Parameter.IncludeInAvailableFields = False;
	Parameter.UseRestriction = True;
	
	AttributesOfExtDimensionType = Common.ObjectAttributesValues(ExtDimensionType, "Description, ValueType");
	FinReports.NewSetField(DataSet, "ExtDimension1", , AttributesOfExtDimensionType.Description, AttributesOfExtDimensionType.ValueType);
	SelectionAccordingToExtDimension = "{(ExtDimension1).* AS ExtDimension1}";

	Source = LocalAccntingClientServer.ChartOfAccountsName();
	If Not LocalAccounting Then
		Source = FinancialAccountingClientServer.ChartOfAccountsName();
	EndIf;
	QueryText = 
	"SELECT
	|	RegisterData.ExtDimension1,
	|	RegisterData.ExtDimension2,
	|	RegisterData.ExtDimension3,
	|	RegisterData.SumBalance AS Value
	|FROM
	|	&SourceTable2 AS RegisterData";
	SourceTable2 = StrTemplate("AccountingRegister.%1.Balance(, , %2, %3)", Source, SelectionByTypeOfExtdimension, SelectionAccordingToExtDimension);
	QueryText = StrReplace(QueryText, "&SourceTable2", SourceTable2);
	
	DataSet.AutoFillAvailableFields = False;
	DataSet.Query = QueryText;
	Composer = FinReports.SchemaComposer(DCSchema);
	IndicatorScheme = New Structure("Schema, Settings",DCSchema, Composer.GetSettings());
	Return IndicatorScheme;
	
EndFunction

Function AccountingMeasurementSelectionScheme(DimensionName)

	FinReports = FinancialReportingServer;
	DCSchema = DataCompositionServer.EmptyCircuit();
	DataSet = DataCompositionServer.AddEmptyDataSet(DCSchema);
	
	LocalAccounting = False;
	
	CollectionOfMDObjects = Metadata.AccumulationRegisters.BudgetTurnovers.Dimensions; // MetadataObjectCollection -
	Dimension = CollectionOfMDObjects.Find(DimensionName);
	Title = DimensionName;
	If Dimension <> Undefined Then
		Title = Dimension.Synonym;
	EndIf;
	FinReports.NewSetField(DataSet, DimensionName,,Title);
	
	FilterByDimension = "{("+ DimensionName + ").* AS " + DimensionName + "}";

	Source = LocalAccntingClientServer.ChartOfAccountsName();
	If Not LocalAccounting Then
		Source =  FinancialAccountingClientServer.ChartOfAccountsName();
	EndIf;
	QueryText = 
	"SELECT
	|	RegisterData.ExtDimension1,
	|	RegisterData.ExtDimension2,
	|	RegisterData.ExtDimension3,
	|	RegisterData.SumBalance AS Value
	|FROM
	|	&SourceTable2 AS RegisterData";
	SourceTable2 = StrTemplate("AccountingRegister.%1.Balance(, , , %2)", Source, FilterByDimension);
	QueryText = StrReplace(QueryText, "&SourceTable2", SourceTable2);
	
	DataSet.AutoFillAvailableFields = False;
	DataSet.Query = QueryText;
	Composer = FinReports.SchemaComposer(DCSchema);
	IndicatorScheme = New Structure("Schema, Settings",DCSchema, Composer.GetSettings());
	Return IndicatorScheme;
	
EndFunction

Function GroupSelectionScheme(DimensionKind)

	FinReports = FinancialReportingServer;
	DCSchema = DataCompositionServer.EmptyCircuit();
	DataSet = DataCompositionServer.AddEmptyDataSet(DCSchema);
	
	SetField = FinReports.NewSetField(DataSet, "Parent",,"Group");
	SetField.ValueType = DimensionKind.ValueType;
	
	QueryText = 
	"SELECT
	|	TableData.Parent
	|FROM
	|	&SourceTable2 AS TableData
	|{WHERE
	|	TableData.Parent AS Parent
	|}";
	QueryText = StrReplace(QueryText, "&SourceTable2", Metadata.FindByType(
		DimensionKind.ValueType.Types()[0]).FullName());
	
	DataSet.AutoFillAvailableFields = False;
	DataSet.Query = QueryText;
	Composer = FinReports.SchemaComposer(DCSchema);
	IndicatorScheme = New Structure("Schema, Settings",DCSchema, Composer.GetSettings());
	Return IndicatorScheme;
	
EndFunction

Function GetSelectionOfElementAnalytics(Ref)
	
	TableName = "";
	If TypeOf(Ref) = Type("CatalogRef.BudgetFlowItems") Then
		TableName = "BudgetFlowItems";
	ElsIf TypeOf(Ref) = Type("CatalogRef.BudgetBalanceItems") Then
		TableName = "BudgetBalanceItems";
	ElsIf TypeOf(Ref) = Type("CatalogRef.NonFinancialItemsOfBudgets") Then
		TableName = "NonFinancialItemsOfBudgets";
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	TemplateSubqueryText =
	"			SELECT
	|				&AnalyticsViewField
	|			FROM
	|				TableOfTypesOfAnalytics AS Catalog";
	SubqueryTexts = New Array;
	SubquerySeparator = "
	|
	|			UNION ALL
	|
	|";
	TextSelectionOfAnalyticsTypes = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextSelectionOfAnalyticsTypes = TextSelectionOfAnalyticsTypes + ?(TextSelectionOfAnalyticsTypes = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"Catalog.DimensionKind%1 AS DimensionKind%1",
				DimensionNumber);
		
		SubqueryText = StrReplace(TemplateSubqueryText, "&AnalyticsViewField", "Catalog.DimensionKind" + DimensionNumber);
		SubqueryTexts.Add(SubqueryText);
	EndDo;
	SubqueryText = TrimAll(StrConcat(SubqueryTexts, SubquerySeparator));
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	&TextSelectionOfAnalyticsTypes
	|INTO TableOfTypesOfAnalytics
	|FROM
	|	&Catalog_TableName AS Catalog
	|WHERE
	|	Catalog.Ref = &Ref";
	QueryText = StrReplace(QueryText, "&Catalog_TableName", "Catalog." + TableName);
	QueryText = StrReplace(QueryText, "&TextSelectionOfAnalyticsTypes", TextSelectionOfAnalyticsTypes);
	
	QueryText = QueryText + ";
	|
	|////////////////////////////////////////////////////////////////////////////////
	|"
	+ "SELECT
	|	BudgetFlowItemDimensions.Ref,
	|	BudgetFlowItemDimensions.PredefinedDataName
	|FROM
	|	ChartOfCharacteristicTypes.BudgetFlowItemDimensions AS BudgetFlowItemDimensions
	|WHERE
	|	BudgetFlowItemDimensions.Ref IN
	|			(&SubqueryText)
	|
	|ORDER BY
	|	BudgetFlowItemDimensions.Description";
	
	QueryText = StrReplace(QueryText, "&SubqueryText", SubqueryText);
	Query.Text = QueryText;
	
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	Return QueryResult.Select();
	
EndFunction

Function ThereIsPeriodInParents(Val TreeRow, Periodicity)
	
	While TreeRow <> Undefined
		And TreeRow.ItemKind <> Enums.FinancialReportItemKinds.Rows
		And TreeRow.ItemKind <> Enums.FinancialReportItemKinds.Columns Do
		
		If TreeRow.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
			
			DimensionType = Undefined;
			If ValueIsFilled(TreeRow.AddressOfItemStructure) Then
				DimensionType = FinancialReportingServerCall.ValueOfAdditionalProps(
					TreeRow.AddressOfItemStructure, "DimensionType");
			ElsIf ValueIsFilled(TreeRow.ReportItem) Then
				DimensionType = FinancialReportingServerCall.ValueOfAdditionalProps(
					TreeRow.ReportItem, "DimensionType");
			Else
				If TypeOf(TreeRow.ItemIndicatorDimensionType) = Type("EnumRef.Periodicity") Then
					DimensionType = Enums.TypesOfBudgetReportDimensions.Period;
				EndIf;
			EndIf;
			
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
				If ValueIsFilled(TreeRow.AddressOfItemStructure) Then
					Periodicity = FinancialReportingServerCall.ValueOfAdditionalProps(
						TreeRow.AddressOfItemStructure, "Periodicity");
				ElsIf ValueIsFilled(TreeRow.ReportItem) Then
					Periodicity = FinancialReportingServerCall.ValueOfAdditionalProps(
						TreeRow.ReportItem, "Periodicity");
				Else
					Periodicity = TreeRow.ItemIndicatorDimensionType
				EndIf;
				Return True;
			EndIf;
			
		EndIf;
		
		TreeRow = TreeRow.Parent;
		
	EndDo;
	
	Return False;
	
EndFunction

Function ThereIsPeriodInSubordinates(Val TreeRow, Periodicity)
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		If SubordinateRow.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
			
			DimensionType = Undefined;
			If ValueIsFilled(SubordinateRow.AddressOfItemStructure) Then
				DimensionType = FinancialReportingServerCall.ValueOfAdditionalProps(
					SubordinateRow.AddressOfItemStructure, "DimensionType");
			ElsIf ValueIsFilled(SubordinateRow.ReportItem) Then
				DimensionType = FinancialReportingServerCall.ValueOfAdditionalProps(
					SubordinateRow.ReportItem, "DimensionType");
			Else
				If TypeOf(SubordinateRow.ItemIndicatorDimensionType) = Type("EnumRef.Periodicity") Then
					DimensionType = Enums.TypesOfBudgetReportDimensions.Period;
				EndIf;
			EndIf;
			
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
				If ValueIsFilled(SubordinateRow.AddressOfItemStructure) Then
					Periodicity = FinancialReportingServerCall.ValueOfAdditionalProps(
						SubordinateRow.AddressOfItemStructure, "Periodicity");
				ElsIf ValueIsFilled(SubordinateRow.ReportItem) Then
					Periodicity = FinancialReportingServerCall.ValueOfAdditionalProps(
						SubordinateRow.ReportItem, "Periodicity");
				Else
					Periodicity = SubordinateRow.ItemIndicatorDimensionType
				EndIf;
				Return True;
			EndIf;
			
		EndIf;
		
		If ThereIsPeriodInSubordinates(SubordinateRow, Periodicity) Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

#If Server Then

Function ElementExpandedByPeriod(Parameters, GroupingFrequency = Undefined) Export
	
	ItemsTree = GetFromTempStorage(Parameters.AddressOfReportItems);
	If ValueIsFilled(Parameters.ItemTableAddress) Then
		TableOfElements = GetFromTempStorage(Parameters.ItemTableAddress); // See BudgetReportingCacheCalculationServer.NewTableOfElements
	Else
		TableOfElements = Undefined;
	EndIf;
	
	If TableOfElements = Undefined Then
		
		TreeRow = ItemsTree.Rows.Find(Parameters.AddressOfEditedItem, "AddressOfItemStructure", True);
		RootItem = FinancialReportingServer.RootItem(TreeRow,
			Enums.FinancialReportItemKinds.TableIndicatorsInRows);
		SourceOfSubordinates = Undefined;
		If RootItem <> Undefined Then
			SourceOfSubordinates = FinancialReportingServer.SubordinateItem(RootItem,
				"ItemKind", Enums.FinancialReportItemKinds.Columns);
		EndIf;
		RootItem = FinancialReportingServer.RootItem(TreeRow,
			Enums.FinancialReportItemKinds.TableIndicatorsInColumns);
		If RootItem <> Undefined Then
			SourceOfSubordinates = FinancialReportingServer.SubordinateItem(RootItem,
				"ItemKind", Enums.FinancialReportItemKinds.Rows);
		EndIf;
		
		ThereIsPeriod = ThereIsPeriodInParents(TreeRow, GroupingFrequency)
					Or ThereIsPeriodInSubordinates(TreeRow, GroupingFrequency)
					Or ?(SourceOfSubordinates = Undefined, False, ThereIsPeriodInSubordinates(SourceOfSubordinates, GroupingFrequency));
		
	Else
		
		MatrixCell = TableOfElements.Find(Parameters.AddressOfEditedItem, "Item");
		
		TreeRow = ItemsTree.Rows.Find(MatrixCell.String, "AddressOfItemStructure", True);
		TreeColumn = ItemsTree.Rows.Find(MatrixCell.Column, "AddressOfItemStructure", True);
		
		ThereIsPeriod = ThereIsPeriodInParents(TreeRow, GroupingFrequency)
					Or ThereIsPeriodInSubordinates(TreeRow, GroupingFrequency)
					Or ThereIsPeriodInParents(TreeColumn, GroupingFrequency)
					Or ThereIsPeriodInSubordinates(TreeColumn, GroupingFrequency);
		
	EndIf;
	
	Return ThereIsPeriod;
	
EndFunction

#EndIf

Function ParseOperandNameIntoComponents(OperandName) Export
	
	SeparatorPosition = StrFind(OperandName, ";");
	If SeparatorPosition Then
		String = Left(OperandName, SeparatorPosition - 1);
		Column = Mid(OperandName, SeparatorPosition + 1);
		String = TrimL(String);
		Column = TrimL(Column);
	Else
		String = TrimL(OperandName);
		Column = "";
	EndIf;
	
	StringIsFixed = BudgetReportingClientServer.LeftPartOfNameMatches(String, "$");
	If StringIsFixed Then
		String = Mid(String, 2);
	EndIf;
	
	If Not ValueIsFilled(Column) Then
		FixedColumn = StringIsFixed;
	Else
		FixedColumn = BudgetReportingClientServer.LeftPartOfNameMatches(Column, "$");
		If FixedColumn Then
			Column = Mid(Column, 2);
		EndIf;
	EndIf;
	
	Result = New Structure();
	Result.Insert("String", String);
	Result.Insert("Column", Column);
	Result.Insert("StringIsFixed", StringIsFixed);
	Result.Insert("FixedColumn", FixedColumn);
	
	Return Result;
	
EndFunction

#Region OutputOfCellSetupTree


// Outputs of the cell.
// 
// Parameters:
// 	Form - ClientApplicationForm -
// 	Group - ValueTreeRow -:
// 	 *NameForPrinting - String -
// 	 *AddressOfItemStructure - String - 
// 	TableItems - ValueTable -:
// 	 *String - CatalogRef.FinancialReportItems, String -
// 	 *Column - CatalogRef.FinancialReportItems, String -
// 	 *Item - CatalogRef.FinancialReportItems, String -
// 	StringTree - ValueTreeRowCollection -:
// 	 *NameForPrinting - String -
// 	 *AddressOfItemStructure - String - 
// 	LineNumber - Number -
// 	PreviousColumnNumber - Number -
// 	Depth - Number -
// Returns:
// 	Number - The number of output elements.
Function OutputCells(Form, Group, TableItems,
						StringTree, LineNumber, PreviousColumnNumber = 3, Val Depth = 0)
	
	
	Elements = 0;
	ThisIsReportView = False;
	AdditionalFormMode_ = Undefined;
	If Form.Parameters.Property("AdditionalFormMode", AdditionalFormMode_) Then
		ThisIsReportView = AdditionalFormMode_ = Enums.AdditionalModesOfReportItems.ReportKind;
	EndIf;
	
	For Each IndicatorLine_1 In StringTree Do
		
		ColumnNumber = PreviousColumnNumber + Elements;
		
		SubordinateElements = OutputCells(Form, Group, TableItems,
											IndicatorLine_1.Rows, LineNumber, ColumnNumber, Depth);
		
		If SubordinateElements Then
			Elements = Elements + SubordinateElements;
			Continue; // the decryption was set in a recursive call
		Else
			Elements = Elements + 1;
		EndIf;
		
		// setting the decryption area
		Area = Form.ReportPresentation.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
		
		DetailsStructure2 = New Structure("String, Column, ItemKind, ReportItem, ThisIsReference");
		DetailsStructure2.ThisIsReference = False;

		DetailsStructure2.String = New Structure("Description, ReportItem", 
										Group.NameForPrinting, Group.AddressOfItemStructure);
		DetailsStructure2.Column = New Structure("Description, ReportItem",
										IndicatorLine_1.NameForPrinting, IndicatorLine_1.AddressOfItemStructure);
		
		ThisIsPredefinedFormula = False;
		ElementData = GetFromTempStorage(IndicatorLine_1.AddressOfItemStructure);
		If ElementData.ItemKind = ItemKind("GroupFormula")
			Or ElementData.ItemKind = ItemKind("Group")
			Or ElementData.ItemKind = ItemKind("TotalByGroup") Then
			FormulaElement = IndicatorLine_1.AddressOfItemStructure;
			ThisIsPredefinedFormula = True;
		Else
			ElementData = GetFromTempStorage(Group.AddressOfItemStructure);
			If ElementData.ItemKind = ItemKind("GroupFormula")
				Or ElementData.ItemKind = ItemKind("Group")
				//OR (Given elements.Element Type = Element type("Measurement") And this Video report)
				Or ElementData.ItemKind = ItemKind("TotalByGroup") Then
				FormulaElement = Group.AddressOfItemStructure;
				ThisIsPredefinedFormula = True;
			EndIf;
		EndIf;
		
		OutputElementByIntersectionOfColumnRows = True;
		TableType = Undefined;
		If Form.Parameters.Property("CheckTableView") Then
			Form.Parameters.Property("TableType", TableType);
			If TableType = Enums.FinancialReportItemKinds.TableIndicatorsInColumns
				Or TableType = Enums.FinancialReportItemKinds.TableIndicatorsInRows Then
				OutputElementByIntersectionOfColumnRows = False;
			EndIf;
		EndIf;
		
		If OutputElementByIntersectionOfColumnRows Then
			
			If Not ThisIsPredefinedFormula Then
				
				TheStructureOfTheSearch = New Structure("String, Column");
				TheStructureOfTheSearch.String = Group.AddressOfItemStructure;
				TheStructureOfTheSearch.Column = IndicatorLine_1.AddressOfItemStructure;
				
				ElementStrings = TableItems.FindRows(TheStructureOfTheSearch);
				If ElementStrings.Count() Then
					ElementString = ElementStrings[0];
					If TypeOf(ElementString.Item) = Type("CatalogRef.FinancialReportItems")
						And ValueIsFilled(ElementString.Item) Then
						ElementString.Item = FinancialReportingServerCall.PlaceItemInStorage(
									ElementString.Item, 
									Form.MainStorageID);
					EndIf;
					ElementData = GetFromTempStorage(ElementString.Item);
					DetailsStructure2.ItemKind = ElementData.ItemKind;
					DetailsStructure2.ReportItem = ElementString.Item;
				EndIf;
				
			Else
				
				DetailsStructure2.ItemKind = ElementData.ItemKind;
				DetailsStructure2.ReportItem = FormulaElement;
			
			EndIf;
		
		EndIf;
		
		If ThisIsReportView And ElementData.ItemKind = ItemKind("Dimension") Then
			DetailsStructure2.ItemKind = ElementData.ItemKind;
			DetailsStructure2.ReportItem = Undefined;
		EndIf;
		
		Area.Details = DetailsStructure2;
		SetCellText(Form, Area.Name);
		ApplyAppearance(Area, "Cell");
		
	EndDo;
	
	Return Elements;
	
EndFunction

Function OutputTreeToMetrics(Form, FirstRow, Rows, Val Depth, DepthOfEverything, Val PreviousColumnNumber = 3)
	
	Elements = 0;
	
	For Each IndicatorLine_1 In Rows Do
		
		ColumnNumber = PreviousColumnNumber + Elements;
		
		Output = True;
		If IndicatorLine_1.ItemKind = ItemKind("Group") Then
			Output = FinancialReportingServerCall.ValueOfAdditionalProps(
						IndicatorLine_1.AddressOfItemStructure, "DisplayItemTitle") = True;
		EndIf;
		
		NewDepth = Depth;
		If Output Then
		
			LineNumber = FirstRow + Depth;
			Area = Form.ReportPresentation.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber); // SpreadsheetDocumentRange
			Area.Text = IndicatorLine_1.NameForPrinting;
			Area.Details = IndicatorLine_1.AddressOfItemStructure;
			Area.ColumnWidth = 15;
			
			NewDepth = Depth + 1;
			
		EndIf;
		
		SubordinateElements = OutputTreeToMetrics(Form,
					FirstRow,
					IndicatorLine_1.Rows,
					NewDepth,
					DepthOfEverything,
					ColumnNumber);
		
		If SubordinateElements Then
			Elements = Elements + SubordinateElements;
			Area = Form.ReportPresentation.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber + SubordinateElements - 1); // SpreadsheetDocumentRange
		Else
			Area = Form.ReportPresentation.Area(LineNumber, ColumnNumber, FirstRow + DepthOfEverything); // SpreadsheetDocumentRange
			Elements = Elements + 1;
		EndIf;
		
		If Output Then
			
			Area.Merge();
			ApplyAppearance(Area, "CellHeader_");
			
		EndIf;
		
	EndDo;
	
	Return Elements;
	
EndFunction

Procedure ApplyAppearance(Area, Mode)
	
	BoldLine = New Line(SpreadsheetDocumentCellLineType.Solid, 2);
	ThinLine = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Wrap;
	
	If Mode = "String" Then
		Area.HorizontalAlign = HorizontalAlign.Left;
		Area.VerticalAlign = VerticalAlign.Center;
		Area.Font = New Font(, 10, False, False);
		Area.Outline(BoldLine, ThinLine, ThinLine, ThinLine);
	ElsIf Mode = "StringCombined" Then
		Area.HorizontalAlign = HorizontalAlign.Left;
		Area.VerticalAlign = VerticalAlign.Center;
		Area.Font = New Font(, 10, False, False);
		Area.Outline(ThinLine, ThinLine, ThinLine, ThinLine);
	ElsIf Mode = "LineTotal" Then
		Area.VerticalAlign = VerticalAlign.Center;
		Area.Font = New Font(, 10, True, False);
		Area.Outline(BoldLine, ThinLine, ThinLine, ThinLine);
	ElsIf Mode = "CellHeader_" Then
		Area.Outline(ThinLine, ThinLine, ThinLine, ThinLine);
		Area.Font = New Font(, 10, True, False);
		Area.VerticalAlign = VerticalAlign.Center;
		Area.BackColor = StyleColors.ReportGroup1BackColor;
	ElsIf Mode = "TableHeading" Then
		Area.Outline(ThinLine, ThinLine, ThinLine, ThinLine);
		Area.Font = New Font(, 10, True, False);
		Area.VerticalAlign = VerticalAlign.Center;
		Area.BackColor = StyleColors.ReportGroup1BackColor;
	ElsIf Mode = "Header" Then
		Area.Outline(BoldLine, BoldLine, BoldLine, BoldLine);
	ElsIf Mode = "Cell" Then
		Area.Outline(ThinLine, ThinLine, ThinLine, ThinLine);
		Area.Font = New Font(, 8);
	ElsIf Mode = "CellTotal" Then
		Area.Outline(ThinLine, ThinLine, ThinLine, ThinLine);
		Area.Font = New Font(, 10, True, False);
	EndIf;
	
EndProcedure

Function SubsequentLineIsMergedWithCur(IndicatorLine_1)
	
	If IndicatorLine_1.Rows.Count() = 1 And
		IndicatorLine_1.Rows[0].DisplayWithParent Then
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

Procedure OutputTreeInLines(Form, StringTree, OutputParameters, TotalRows,
							Val Depth = 0, Val ColumnNumber = 0)
	
	TableItems = OutputParameters.TableItems;
	ColumnTree = OutputParameters.ColumnTree;
	FirstRow = OutputParameters.FirstRow;
	MergeDepth = OutputParameters.MergeDepth;
	
	Begin = FirstRow + TotalRows + 1;
	
	ThereWereElementsToOutput = False;
	For Each IndicatorLine_1 In StringTree Do
		
		Output = True;
		If IndicatorLine_1.ItemKind = ItemKind("Group") Then
			Output = FinancialReportingServerCall.ValueOfAdditionalProps(
					IndicatorLine_1.AddressOfItemStructure, "DisplayItemTitle");
		EndIf;
		
		NewDepth = Depth;
		If Output Then
			ThereWereElementsToOutput = True;
			
			If IndicatorLine_1.DisplayWithParent = True Then
				CurColumnNumber = ColumnNumber + 1;
				DesignMode = "StringCombined";
			Else
				CurColumnNumber = 0;
				TotalRows = TotalRows + 1;
				DesignMode = "String";
			EndIf;
			LineNumber 	= FirstRow + TotalRows;
			
			SubsequentLineIsMerged = SubsequentLineIsMergedWithCur(IndicatorLine_1);
			If SubsequentLineIsMerged Then
				EndOfColumn = 2 + CurColumnNumber;
			Else
				EndOfColumn = 2 + MergeDepth - 1;
			EndIf;
			
			Area = Form.ReportPresentation.Area(LineNumber, 2 + CurColumnNumber, LineNumber, EndOfColumn); // SpreadsheetDocumentRange
			Area.Merge();
			Area.Text = IndicatorLine_1.NameForPrinting;
			Area.Details = IndicatorLine_1.AddressOfItemStructure;
			
			If IndicatorLine_1.DisplayWithParent = False Then
				Area.Indent 	= Depth * 2;
			EndIf;
			
			ApplyAppearance(Area, DesignMode);
			
			If Not SubsequentLineIsMerged Then
				OutputCells(Form, IndicatorLine_1, TableItems, ColumnTree, LineNumber, 3 + MergeDepth - 1);
			EndIf;
			
			NewDepth = Depth + 1;
		EndIf;
		
		OutputTreeInLines(Form,
				IndicatorLine_1.Rows,
				OutputParameters,
				TotalRows,
				NewDepth,
				CurColumnNumber);
		
	EndDo;
	
	End = FirstRow + TotalRows;
	
	If Depth > 0 And Begin <= End And ThereWereElementsToOutput Then
	
		Form.ReportPresentation.Area(Begin, , End).Group(Depth);
	
	EndIf;
	
EndProcedure

Function ItemKind(ElementTypeName)
	
	Return Enums.FinancialReportItemKinds[ElementTypeName];
	
EndFunction

#EndRegion

#Region SetUpAdditionalFields


// Fills in the additional fields view
// 
// Parameters:
// 	Object - FormDataStructure -
// 	AdditionalFields_1 - FormField, FormGroup, FormCommand, FormTable - 
Procedure FillInPresentationOfAdditionalFields(Object, AdditionalFields_1) Export
	
	FieldArray = Object.AdditionalFields.Unload(,"Description").UnloadColumn("Description");
	If FieldArray.Count() Then
		Presentation = StrConcat(FieldArray, ", ");
		TitleText = NStr("vi = 'Trường bổ sung: %1';
						|ru = 'Дополнительные поля: %1';
						|en = 'Additional fields: %1'; fa = 'Additional fields: %1';
						|it = 'Campi aggiuntivi: %1';
						|pl = 'Pola dodatkowe: %1';
						|tr = 'Ek alanlar: %1'");
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(TitleText, Presentation);
		AdditionalFields_1.Title = TitleText;
	Else
		TitleText = NStr("vi = '<cấu hình hiển thị các trường bổ sung>';
						|ru = '<настроить отображение дополнительных полей>';
						|en = '<configure additional field display>'; fa = '<configure additional field display>';
						|it = '<impostare visualizzazione dei campi aggiuntivi>';
						|pl = '<ustaw odzwierciedlenie pól dodatkowych>';
						|tr = '<gösterilen ek alanları ayarla>'");
		AdditionalFields_1.Title = TitleText;
	EndIf;
	
EndProcedure

#EndRegion

#Region RecordReportType

// Recursively writes the structure of the type of financial report from the transferred tree to the subordinate directory of the elements of financial reports.
//
// Parameters:
//  ReportViewElements	- ValueTree - structure (composition and order) of the report type
//  ParametersForWritingToStructure - Structure - Contains keys:
//  	* ReportKind 		- CatalogRef.BudgetProfiles, CatalogRef.FinancialReportTypes - owner of elements of report types
//  	* DeletionMark	- Boolean - Flag for marking the deletion of the report type
//  	* ReadyForRewriting - Array - An array of already existing measurement elements that need to be updated to update the filling sources
//  ReportViewElementsUsed - Array - array of report view elements
//  Parent  			- CatalogRef.FinancialReportItems - parent of the current element
//  AdditionalProcedure  		- Number - the number is in order starting from the topmost element of the tree in the direction from top to bottom and from left to right
//  Cache					- Undefined
//  					- ValueTable - cache of report item properties.
//
Procedure HowToWriteReportViewStructure(ReportViewElements, ParametersForWritingToStructure, ReportViewElementsUsed,
											Parent = Undefined, AdditionalProcedure = 0, Cache = Undefined)
	
	If Parent = Undefined Then
		Parent = Catalogs.FinancialReportItems.EmptyRef();
		Items = ReportViewElements.Rows[0].Rows;
	Else
		Items = ReportViewElements.Rows;
	EndIf;
	
	For Each Item In Items Do
		
		RefToNew = MakeChangesToObject(Item, Parent, ParametersForWritingToStructure, AdditionalProcedure, ReportViewElementsUsed, Cache);
		HowToWriteReportViewStructure(Item, ParametersForWritingToStructure, ReportViewElementsUsed, RefToNew, AdditionalProcedure, Cache);
		
	EndDo;
	
EndProcedure

Function GetRecordParametersInReportStructure()
	Parameters = New Structure;
	Parameters.Insert("ReportKind", Undefined);
	Parameters.Insert("DeletionMark", False);
	Parameters.Insert("ReadyForRewriting", New Array);
	
	Return Parameters;
EndFunction

// Fills the array with links to elements of financial reports - dimensions for which the sources of filling have been changed.
// The array contains only unchanged elements of financial statements (Element structure address = empty string).
// 
// Parameters:
//  Item - ValueTree - tree of values of report elements
//  		- ValueTreeRow - row of the tree of values - report elements
//  SourceChanges - Array - the filled array of elements of the reference link.Elements of financial reports
//  Cache - see the description of the oboitrecording the structure of the report.
//
Procedure FillMeasurementsWithChangesInFillSources(Val Item, SourceChanges, Cache = Undefined)
	
	If TypeOf(Item) = Type("ValueTree") Then
		
		String = Item.Rows[0];
		
	Else
		
		String = Item;
		
		If String.ItemKind = Enums.FinancialReportItemKinds.Dimension
			And IsBlankString(String.AddressOfItemStructure)
			And ValueIsFilled(String.ReportItem) Then
			
			YouNeedToFillInSources = False;
			ThereAreModifiedSources = False;
			ThisIsFilling = False;
			DimensionType = FinancialReportingServerCall.ValueOfAdditionalProps(
						String.ReportItem, "DimensionType");
			
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension
				Or DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
				YouNeedToFillInSources = True;
			EndIf;
			
			If DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
				If FinancialReportingServerCall.ValueOfAdditionalProps(
							String.ReportItem, "EnableEdit") = True Then
					
					YouNeedToFillInSources = True;
					ThisIsFilling = True;
				EndIf;
			EndIf;
			
			If YouNeedToFillInSources Then
				ListOfAvailableItems = BudgetReportingCacheCalculationServer.SourcesOfElementValues(Cache,
					String, ThisIsFilling);
				RecordedSources = New Array;
				For Each SourceRow1 In ListOfAvailableItems Do
					If TypeOf(SourceRow1.Item) = Type("String") Then
						ThereAreModifiedSources = True;
						Break;
					Else
						RecordedSources.Add(SourceRow1.Item);
					EndIf;
				EndDo;
				If Not ThereAreModifiedSources Then
					
					Query = New Query;
					Query.Text = 
					"SELECT TOP 1
						|	Sources.Source AS Source
						|FROM
						|	Catalog.FinancialReportItems.ValueSources AS Sources
						|WHERE
						|	Sources.Ref = &Dimension
						|	AND NOT Sources.Source IN (&RecordedSources)";
					Query.SetParameter("Dimension", String.ReportItem);
					Query.SetParameter("RecordedSources", RecordedSources);
					ThereAreModifiedSources = Not Query.Execute().IsEmpty();
					
				EndIf;
			EndIf;
			If ThereAreModifiedSources Then
				If SourceChanges.Find(String.ReportItem) = Undefined Then
					SourceChanges.Add(String.ReportItem);
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	TreeRows = String.Rows;
	For Each TreeRow In TreeRows Do
		FillMeasurementsWithChangesInFillSources(TreeRow, SourceChanges, Cache);
	EndDo;
	
EndProcedure

Function GetItemObject(ItemDetails, ObjectData)
	
	If ValueIsFilled(ItemDetails) Then
		ElementObject = ItemDetails.GetObject();
	EndIf;
	
	If ElementObject = Undefined Then
		ElementObject = Catalogs.FinancialReportItems.CreateItem();
		If ValueIsFilled(ItemDetails) Then
			ElementObject.SetNewObjectRef(ItemDetails);
		ElsIf ValueIsFilled(ObjectData.Ref) Then
			ElementObject.SetNewObjectRef(ObjectData.Ref);
		EndIf;
	EndIf;
	
	Return ElementObject;
	
EndFunction

Procedure PopulateObjectBasedOnTemporaryStorageData(Object, ObjectData, Code, Owner, Parent)
	
	Object.Code = Code;
	Object.Owner = Owner;
	Object.Parent = Parent;
	
	If ObjectData.Property("Parent") Then
		Suffix = ", Parent";
	EndIf;
	
	TabularSectionNames = "ItemKindAttributes, FormulaOperands, TableItems, AdditionalFields, AppearanceItems, RegisteredRows, DesigningColumns, DrillDownOfAppearanceItemFilterFields, ValueSources, CalculationsRules";
	
	FillPropertyValues(Object, ObjectData, , "Code, Owner" + Suffix + ", " + TabularSectionNames);
	
	ArrayOfNamesOfTableParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(TabularSectionNames, ",", , True);
	For Each TabularSectionName In ArrayOfNamesOfTableParts Do
		Object[TabularSectionName].Load(ObjectData[TabularSectionName]);
	EndDo;
	
	If Object.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.TableCell") Then
		
		ItemRef = FinancialReportingServerCall.ValueOfAdditionalProps(
					Object,
					"CellRow");
		If TypeOf(ItemRef) = Type("String") Then
			ItemRef = GetFromTempStorage(
							ItemRef); // See FinancialReportingServerCall.ReportElementData
			If ItemRef <> Undefined Then
				ItemRef = ItemRef.Ref;
			EndIf;
			FinancialReportingServerCall.SetValueOfAdditionalProps(
						Object,
						"CellRow",
						ItemRef);
		EndIf;
		
		ItemRef = FinancialReportingServerCall.ValueOfAdditionalProps(
					Object,
					"CellColumn");
		If TypeOf(ItemRef) = Type("String") Then
			ItemRef = GetFromTempStorage(
								ItemRef); // See FinancialReportingServerCall.ReportElementData
			If ItemRef <> Undefined Then
				ItemRef = ItemRef.Ref;
			EndIf;
			FinancialReportingServerCall.SetValueOfAdditionalProps(
						Object,
						"CellColumn",
						ItemRef);
		EndIf;
		
	EndIf;
	
EndProcedure


// Value of the cache element field
// 
// Parameters:
// 	Item - CatalogRef.FinancialReportItems -
// 	FieldName - String -
// 	Cache - Undefined, ValueTable - Contains:
// 	 * Ref - CatalogRef.FinancialReportItems -
// 	ReportKind - Undefined - LongDesc
// Returns:
// 	Arbitrary -
Function FieldValueOfElementFromCache(Item, FieldName, Cache, ReportKind = Undefined) Export
	
	If Cache = Undefined Then
		Cache = NewCacheOfFinancialReportItems(ReportKind, Item);
	EndIf;
	
	FoundRow = Cache.Find(Item, "Ref");
	If FoundRow = Undefined Then
		// newly recorded element
		Cache = Undefined;
		Return FieldValueOfElementFromCache(Item, FieldName, Cache, ReportKind);
	EndIf;
	Return FoundRow[FieldName];
	
EndFunction

// Returns a cached table of elements
// 
// Returns:
// 	ValueTable - LongDesc:
// * ValueSources - ValueTable - LongDesc:
// 		** Source - CatalogRef.FinancialReportItems -
// 		** AddedDocumentValues - Boolean -
// * DrillDownOfAppearanceItemFilterFields - ValueTable - LongDesc:
// 		** ReportItem - CatalogRef.FinancialReportItems -
// 		** AppearanceItemKey - UUID -
// 		** FilterFieldName - String -
// 		** ResourceName - String -
// * DesigningColumns - ValueTable - LongDesc:
// 		** ReportItem - CatalogRef.FinancialReportItems -
// 		** AppearanceItemKey - UUID -
// * RegisteredRows - ValueTable - LongDesc:
// 		** ReportItem - CatalogRef.FinancialReportItems -
// 		** AppearanceItemKey - UUID -
// * AppearanceItems - ValueTable - LongDesc:
// 		** Appearance - ValueStorage -
// 		** Condition - ValueStorage -
// 		** CreatedAreaType - EnumRef.DesignedAreaTypesOfBudgetReports -
// 		** AppearanceItemKey - UUID - 
// * AdditionalFields - ValueTable - LongDesc:
// 		** Attribute - String -
// 		** Description - String -
// 		** TitleOutput - Boolean -
// 		** InSeparateColumn - Boolean -
// * TableItems - ValueTable - LongDesc:
// 		** String - CatalogRef.FinancialReportItems -
// 		** Column - CatalogRef.FinancialReportItems -
// 		** Item - CatalogRef.FinancialReportItems -
// * FormulaOperands - ValueTable - LongDesc:
// 		** Id - String -
// 		** Operand - CatalogRef.FinancialReportItems -
// * ItemKindAttributes - ValueTable - LongDesc:
// 		** Attribute - ChartOfCharacteristicTypesRef.ItemAttributesOfFinancialReports -
// 		** Value - Characteristic.ItemAttributesOfFinancialReports -
// * LinkedItem1 - CatalogRef.FinancialReportItems -
// * DimensionValue -Characteristic.BudgetFlowItemDimensions -
// * HasSettings - Boolean -
// * AdditionalSelection - ValueStorage -
// * Comment - String -
// * ReverseSign - Boolean -
// * NameForPrinting - String -
// * ItemKind - EnumRef.FinancialReportItemKinds -
// * Code - Number -
// * Description - String -
// * Owner - CatalogRef.FinancialReportTypes, CatalogRef.BudgetProfiles -
// * Ref - CatalogRef.FinancialReportItems -
Function NewCacheOfFinancialReportItems(ReportKind, Item) Export
	
	Query = New Query;
	If ReportKind = Undefined Then
		Query.Text = 
		"SELECT
		|	*
		|FROM
		|	Catalog.FinancialReportItems AS FinancialReportItems
		|WHERE
		|	FinancialReportItems.Owner IN
		|			(SELECT TOP 1
		|				FinancialReportItems.Owner
		|			FROM
		|				Catalog.FinancialReportItems AS FinancialReportItems
		|			WHERE
		|				FinancialReportItems.Ref = &Ref)";
		Query.SetParameter("Ref", Item);
	Else
		Query.Text = 
		"SELECT
		|	*
		|FROM
		|	Catalog.FinancialReportItems AS FinancialReportItems
		|WHERE
		|	FinancialReportItems.Owner = &Owner";
		Query.SetParameter("Owner", ReportKind);
	EndIf;
	Cache = Query.Execute().Unload();
	Cache.Indexes.Add("Ref");
	
	Return Cache;
	
EndFunction

// Updates the cache value
//
// Parameters:
// 	ItemRef - CatalogRef.FinancialReportItems -
// 	Cache - See NewCacheOfFinancialReportItems
// 	ElementStructure - Undefined, ValueTableRow -
//
Procedure UpdateCacheValue(ItemRef, Cache, ElementStructure = Undefined)
	FoundRow = Cache.Find(ItemRef, "Ref");
	If FoundRow = Undefined Then
		FoundRow = Cache.Add();
		FoundRow.Ref = ItemRef;
	EndIf;
	If ElementStructure = Undefined Then
		Query = New Query;
		Query.Text = 
		"SELECT
			|	*
			|FROM
			|	Catalog.FinancialReportItems AS FinancialReportItems
			|WHERE
			|	FinancialReportItems.Ref = &Ref";
		Query.SetParameter("Ref", ItemRef);
		Result = Query.Execute().Unload();
		If Result.Count() > 0 Then
			ElementStructure = Result[0];
		EndIf;
	EndIf;
	If Not ElementStructure = Undefined Then
		FillPropertyValues(FoundRow, ElementStructure);
	EndIf;
EndProcedure

Function UpdateCreateItemBasedOnTemporaryStorageData(ItemRef, AddressOfItemStructure, 
															AdditionalProcedure, ReportKind, Parent,
															ReportViewElementsUsed)
	
	If Not IsBlankString(AddressOfItemStructure) Then
		ElementData = GetFromTempStorage(
						AddressOfItemStructure); // See FinancialReportingServerCall.ReportElementData
		If ItemRef = Undefined Then
			If ValueIsFilled(ElementData.Ref) Then
				ItemRef = ElementData.Ref;
			EndIf;
		EndIf;
	Else
		ElementData = GetFromTempStorage(
						FinancialReportingServerCall.PlaceItemInStorage(
							ItemRef)); // See FinancialReportingServerCall.ReportElementData
	EndIf;
	
	// getting an object to record and defining a reference
	ElementObject = GetItemObject(ItemRef, ElementData);
	If ElementObject = Undefined Then
		Return Undefined;
	EndIf;

	If ElementObject.IsNew()
		And (ElementData.FormulaOperands.Count()
			Or ElementData.TableItems.Count()) Then
		
		ElementObject.Owner = ReportKind;
		ElementObject.ItemKind = ElementData.ItemKind;
		ElementObject.ItemKindAttributes.Load(ElementData.ItemKindAttributes);
		ElementObject.Write();
		
	EndIf;
	
	// writing data from tabular parts
	For Each Operand In ElementData.FormulaOperands Do
		If ValueIsFilled(Operand.AddressOfItemStructure) Then
			NewOperand = UpdateCreateItemBasedOnTemporaryStorageData(Operand.Operand,
					Operand.AddressOfItemStructure,
					AdditionalProcedure,
					ReportKind,
					ElementObject.Ref,
					ReportViewElementsUsed);
			Operand.Operand = NewOperand;
		EndIf;
		ReportViewElementsUsed.Add(Operand.Operand);
	EndDo;
	
	For Each RowColumn In ElementData.TableItems Do
		
		ColumnStructure1 = New Structure("String, Column");
		
		For Each KeyAndValue In ColumnStructure1 Do
			
			If TypeOf(RowColumn[KeyAndValue.Key]) = Type("String") Then
				
				TableElementData = GetFromTempStorage(RowColumn[KeyAndValue.Key]); // See FinancialReportingServerCall.ReportElementData
				If Not ValueIsFilled(TableElementData) Then
					RowColumn[KeyAndValue.Key] = Undefined;
				Else
					RowColumn[KeyAndValue.Key] = TableElementData.Ref;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If ValueIsFilled(RowColumn.String)
			And ValueIsFilled(RowColumn.Column) Then
			
			If TypeOf(RowColumn.Item) = Type("String") Then
			
				NewItem = UpdateCreateItemBasedOnTemporaryStorageData(Undefined,
						RowColumn.Item,
						AdditionalProcedure,
						ReportKind,
						ElementObject.Ref,
						ReportViewElementsUsed);
				RowColumn.Item = NewItem;
			
			EndIf;
			
		EndIf;
			
	EndDo;
	
	For Each RowColumn In ElementData.RegisteredRows Do
		
		If TypeOf(RowColumn.ReportItem) = Type("String") Then
			
			If ValueIsFilled(RowColumn.ReportItem) Then
				TableElementData = GetFromTempStorage(
					RowColumn.ReportItem); // See FinancialReportingServerCall.ReportElementData
			Else
				TableElementData = Undefined;
			EndIf;
			If Not ValueIsFilled(TableElementData) Then
				RowColumn.ReportItem = Undefined;
			Else
				RowColumn.ReportItem = TableElementData.Ref;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each RowColumn In ElementData.DesigningColumns Do
		
		If TypeOf(RowColumn.ReportItem) = Type("String") Then
			
			If ValueIsFilled(RowColumn.ReportItem) Then
				TableElementData =
					GetFromTempStorage(
						RowColumn.ReportItem); // See FinancialReportingServerCall.ReportElementData
			Else
				TableElementData = Undefined;
			EndIf;
			If Not ValueIsFilled(TableElementData) Then
				RowColumn.ReportItem = Undefined;
			Else
				RowColumn.ReportItem = TableElementData.Ref;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each RowColumn In ElementData.DrillDownOfAppearanceItemFilterFields Do
		
		If TypeOf(RowColumn.ReportItem) = Type("String") Then
			
			TableElementData =
				GetFromTempStorage(
						RowColumn.ReportItem); // See FinancialReportingServerCall.ReportElementData
			If Not ValueIsFilled(TableElementData) Then
				RowColumn.ReportItem = Undefined;
			Else
				RowColumn.ReportItem = TableElementData.Ref;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	TotalRows = ElementData.TableItems.Count();
	For Cnt = 1 To TotalRows Do
		
		RowColumn = ElementData.TableItems[TotalRows - Cnt];
		If Not ValueIsFilled(RowColumn.String)
			Or Not ValueIsFilled(RowColumn.Column)
			Or Not ValueIsFilled(RowColumn.Item) Then
			
			ElementData.TableItems.Delete(RowColumn);
			Continue;
			
		EndIf;
		
		ReportViewElementsUsed.Add(RowColumn.String);
		ReportViewElementsUsed.Add(RowColumn.Column);
		ReportViewElementsUsed.Add(RowColumn.Item);
		Operands = Common.ObjectAttributeValue(RowColumn.Item, "FormulaOperands.Operand").Unload();
		For Each Operand In Operands Do
			ReportViewElementsUsed.Add(Operand.Operand);
		EndDo;
		
	EndDo;
	
	// recording object data
	PopulateObjectBasedOnTemporaryStorageData(ElementObject, ElementData, AdditionalProcedure, ReportKind, Parent);
	
	ElementObject.Write();
	
	If ValueIsFilled(AddressOfItemStructure) Then
		// We will place the item in the repository, for later use by links to the repository.
		FinancialReportingServerCall.PlaceItemInStorage(ElementObject, AddressOfItemStructure);
	EndIf;
	
	Return ElementObject.Ref;
	
EndFunction

// Making changes to an object/
// 
// Parameters:
// 	Item - ValueTreeRow -
// 	Parent - Undefined, CatalogRef.FinancialReportItems -
// 	ParametersForWritingToStructure - Structure -:
// * ReadyForRewriting - Array -
// * DeletionMark - Boolean -
// * ReportKind - Undefined -
// 	AdditionalProcedure - Number -
// 	ReportViewElementsUsed - ValueList -
// 	Cache - See NewCacheOfFinancialReportItems
// Returns:
// 	Undefined, CatalogRef.FinancialReportItems - LongDesc
Function MakeChangesToObject(Item, Parent, ParametersForWritingToStructure, AdditionalProcedure, ReportViewElementsUsed, Cache)
	
	DeletionMark = ParametersForWritingToStructure.DeletionMark;
	ReportKind = ParametersForWritingToStructure.ReportKind;
	ReadyForRewriting = ParametersForWritingToStructure.ReadyForRewriting;
	
	AdditionalProcedure = AdditionalProcedure + 1;
	
	If IsBlankString(Item.AddressOfItemStructure)
		And Not Item.ReportItem.IsEmpty()
		And ReadyForRewriting.Find(Item.ReportItem) = Undefined
		And FieldValueOfElementFromCache(Item.ReportItem, "Code", Cache, ReportKind) = AdditionalProcedure
		And FieldValueOfElementFromCache(Item.ReportItem, "Parent", Cache, ReportKind) = Parent 
		And FieldValueOfElementFromCache(Item.ReportItem, "DeletionMark", Cache, ReportKind) = DeletionMark Then
		
		// writing data from tabular parts
		Operands = FieldValueOfElementFromCache(Item.ReportItem, "FormulaOperands", Cache, ReportKind);
		For Each Operand In Operands Do
			ReportViewElementsUsed.Add(Operand.Operand);
		EndDo;
		TableItems = FieldValueOfElementFromCache(
			Item.ReportItem,
			"TableItems",
			Cache,
			ReportKind); // See BudgetReportingCacheCalculationServer.NewTableOfElements 
			
		For Each RowColumn In TableItems Do
			ReportViewElementsUsed.Add(RowColumn.String);
			ReportViewElementsUsed.Add(RowColumn.Column);
			ReportViewElementsUsed.Add(RowColumn.Item);
			Operands = FieldValueOfElementFromCache(RowColumn.Item, "FormulaOperands", Cache, ReportKind);
			For Each Operand In Operands Do
				ReportViewElementsUsed.Add(Operand.Operand);
			EndDo;
		EndDo;
		
		ReportViewElementsUsed.Add(Item.ReportItem);
		
		Return Item.ReportItem;
		
	EndIf;
	
	// if there is a new element, we will save the row data in temporary storage
	ElementData = Item.AddressOfItemStructure;
	
	FormStorageIsUsed = True;
	UID = New UUID;
	If Not ValueIsFilled(Item.ReportItem) 
		And Not ValueIsFilled(ElementData) Then
		If TypeOf(ReportKind) = Type("CatalogRef.FinancialReportTypes") Then
			ElementData = InternationalReportingClientServer.PlaceItemInStorage(Item, UID);
		EndIf;
		If TypeOf(ReportKind) = Type("CatalogRef.BudgetProfiles") Then
			ElementData = BudgetReportingClientServer.PlaceItemInStorage(Item, UID);
		EndIf;
		FormStorageIsUsed = False;
	EndIf;
	If Not ValueIsFilled(ElementData)
	   And Not ReadyForRewriting.Find(Item.ReportItem) = Undefined Then
		ElementData = BudgetReportingClientServer.PlaceItemInStorage(Item, UID);
		FormStorageIsUsed = False;
	EndIf;
	
	ElementStructure = Undefined;
	
	If TypeOf(ReportKind) = Type("CatalogRef.BudgetProfiles") And ElementData <> "" Then
		
		ElementStructure = GetFromTempStorage(ElementData);
		If ElementStructure.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
		
			FinancialReportingServerCall.SetValueOfAdditionalProps(
						ElementData,
						"DisplayWithParent",
						Item.DisplayWithParent);
		EndIf;
		
	EndIf;
	
	If TypeOf(ReportKind) = Type("CatalogRef.BudgetProfiles") And ElementData <> "" Then
		
		YouNeedToFillInSources = False; ThisIsFilling = False;
		If Item.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
			DimensionType = FinancialReportingServerCall.ValueOfAdditionalProps(ElementData, "DimensionType");
			
			If DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension
				Or DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
				YouNeedToFillInSources = True;
			EndIf;
			
			If DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
				If FinancialReportingServerCall.ValueOfAdditionalProps(ElementData, "EnableEdit") = True Then
					YouNeedToFillInSources = True;
					ThisIsFilling = True;
				EndIf;
			EndIf;
			
		EndIf;
		
		If YouNeedToFillInSources Then
			
			ElementStructure = GetFromTempStorage(
								ElementData); // See FinancialReportingServerCall.ReportElementData
			
			If FinancialReportingServerCall.ValueOfAdditionalProps(ElementData, "SelectedValueSources") = True Then
				
				// 1. Check the selected sources
				If ElementStructure.ValueSources.Count() Then
					
					ListOfAvailableItems = BudgetReportingCacheCalculationServer.SourcesOfElementValues(Cache, Item, ThisIsFilling);
					ToDelete_ = New Array;
					
					For Each SourceRow1 In ElementStructure.ValueSources Do
						If TypeOf(SourceRow1.Source) = Type("String") Then
							// 1.1. Let's try to find at
							If ListOfAvailableItems.Find(SourceRow1.Source) <> Undefined Then
								Continue;
							EndIf;
							// 1.2. If not found, then follow the link from the repository
							SourceStructure_ = 
								GetFromTempStorage(
								SourceRow1.Source); // See FinancialReportingServerCall.ReportElementData
							If ValueIsFilled(SourceStructure_.Ref) Then
								If ListOfAvailableItems.Find(SourceStructure_.Ref) <> Undefined Then
									Continue;
								EndIf;
							EndIf;
						EndIf;
						If TypeOf(SourceRow1.Source) = Type("CatalogRef.FinancialReportItems") Then
							If ListOfAvailableItems.Find(SourceRow1.Source) <> Undefined Then
								Continue;
							EndIf;
						EndIf;
						ToDelete_.Add(SourceRow1);
					EndDo;
					
					For Each ArrayElement In ToDelete_ Do
						ElementStructure.ValueSources.Delete(ArrayElement);
					EndDo;
					
				EndIf;
				
			Else
				
				// 2. Just fill in the available sources
				ElementStructure.ValueSources.Clear();
				ListOfAvailableItems = BudgetReportingCacheCalculationServer.SourcesOfDefaultValues(Cache, Item, , ThisIsFilling);
				CommonClientServer.SupplementTable(ListOfAvailableItems, ElementStructure.ValueSources);
				
			EndIf;
			
			// 3. For expandable measurements, we will add sources
			If ThisIsFilling Then
				FoundRows = ElementStructure.ValueSources.FindRows(New Structure("AddedDocumentValues", True));
				For Each FoundRow In FoundRows Do
					ElementStructure.ValueSources.Delete(FoundRow);
				EndDo;
				ListOfAvailableItems = BudgetReportingCacheCalculationServer.SourcesOfDefaultValues(Cache, Item); 
				For Each RowOfAvailableItems In ListOfAvailableItems Do
					If RowOfAvailableItems.ItemKind <> Enums.FinancialReportItemKinds.DerivedItem Then
						NewRow = ElementStructure.ValueSources.Add();
						NewRow.Source = RowOfAvailableItems.Source;
						NewRow.AddedDocumentValues = True;
					EndIf;
				EndDo;
			EndIf;
			
			// 4. Check if the source has not been recorded yet - convert the source to a link
			For Each SourceRow1 In ElementStructure.ValueSources Do
				
				If TypeOf(SourceRow1.Source) = Type("String") Then
					SourceStructure_ = 
						GetFromTempStorage(
							SourceRow1.Source); // See FinancialReportingServerCall.ReportElementData
					If Not ValueIsFilled(SourceStructure_.Ref) Then
						SourceStructure_.Ref = Catalogs.FinancialReportItems.GetRef(New UUID);
					EndIf;
					
					PutToTempStorage(SourceStructure_, SourceRow1.Source);
					SourceRow1.Source = SourceStructure_.Ref;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	ItemRef = UpdateCreateItemBasedOnTemporaryStorageData(Item.ReportItem,
				ElementData, AdditionalProcedure, ReportKind,
				Parent, ReportViewElementsUsed);
	
	If TypeOf(Cache) = Type("ValueTable") Then
		UpdateCacheValue(ItemRef, Cache, ElementStructure);
	EndIf;
	
	If ItemRef = Undefined Then
		Item.ReportItem = ItemRef;
	ElsIf Not ValueIsFilled(Item.ReportItem) Then
		Item.ReportItem = ItemRef;
	EndIf;
	If Not FormStorageIsUsed Then
		DeleteFromTempStorage(ElementData);
	EndIf;
	Item.AddressOfItemStructure = "";
	ReportViewElementsUsed.Add(Item.ReportItem);
	
	Return ItemRef;
	
EndFunction

#EndRegion
#Region InternationalReporting

Function MonetaryIndicatorScheme(Factor, Dimensions = Undefined, ExtDimension = Undefined, Resource = "Sum")
	
	FinReports = FinancialReportingServer;
	
	If TypeOf(Factor.GLAccount_) = LocalAccntingClientServer.TypeChartOfAccounts() Then
		Source = LocalAccntingClientServer.ChartOfAccountsName();
	Else
		Source = FinancialAccountingOfGeneralPurpose.NameOfAccountingRegisterForTransactionsOnAccountingAccount(Factor.GLAccount_);
	EndIf;
	
	ThisIsRemainder = Factor.TotalType = Enums.TypesOfTotals.Balance_
			Or Factor.TotalType = Enums.TypesOfTotals.Balance_Dr
			Or Factor.TotalType = Enums.TypesOfTotals.Balance_Cr;
		
	ExpressionsOpeningBalance = New Map();
	ExpressionsClosingBalance = New Map();
	ExpressionsTurnover = New Map();
	
	If Resource = "Sum" Then
		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_, "SumOpeningBalance");
		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_Dr, "SumOpeningBalanceDr");
		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_Cr, "SumOpeningBalanceCr");
		
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_, "SumClosingBalance");
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_Dr, "SumClosingBalanceDr");
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_Cr, "SumClosingBalanceCr");
		
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.Turnover, "SumTurnover");
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.TurnoverDr, "SumTurnoverDr");
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.TurnoverCr, "SumTurnoverCr");
		
	ElsIf Resource = "PresentationAmount" Then
		
		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_, "PresentationAmountOpeningBalance");
		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_Dr, "PresentationAmountOpeningBalanceDr");
		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_Cr, "PresentationAmountOpeningBalanceCr");
		
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_, "PresentationAmountClosingBalance");
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_Dr, "PresentationAmountClosingBalanceDr");
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_Cr, "PresentationAmountClosingBalanceCr");
		
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.Turnover, "PresentationAmountTurnover");
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.TurnoverDr, "PresentationAmountTurnoverDr");
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.TurnoverCr, "PresentationAmountTurnoverCr");
		
	ElsIf Resource = "CurrencyAmount" Then
		
		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_, "CurrencyAmountOpeningBalance");
		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_Dr, "CurrencyAmountOpeningBalanceDr");
		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_Cr, "CurrencyAmountOpeningBalanceCr");
		
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_, "CurrencyAmountClosingBalance");
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_Dr, "CurrencyAmountClosingBalanceDr");
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_Cr, "CurrencyAmountClosingBalanceCr");
		
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.Turnover, "CurrencyAmountTurnover");
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.TurnoverDr, "CurrencyAmountTurnoverDr");
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.TurnoverCr, "CurrencyAmountTurnoverCr");
	ElsIf Resource = "Count" Then

		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_, "CountOpeningBalance");
		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_Dr, "CountOpeningBalanceDr");
		ExpressionsOpeningBalance.Insert(Enums.TypesOfTotals.Balance_Cr, "CountOpeningBalanceCr");
		
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_, "CountClosingBalance");
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_Dr, "CountClosingBalanceDr");
		ExpressionsClosingBalance.Insert(Enums.TypesOfTotals.Balance_Cr, "CountClosingBalanceCr");
		
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.Turnover, "CountTurnover");
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.TurnoverDr, "CountTurnoverDr");
		ExpressionsTurnover.Insert(Enums.TypesOfTotals.TurnoverCr, "CountTurnoverCr");
	
	Else
		Raise StrTemplate(NStr("vi = 'Chưa xác định biểu thức nhận tài nguyên ""%1""';
								|ru = 'Не определено выражение получение ресурса ""%1""';
								|en = 'Expression of the ""%1"" resource receiving is not defined'; fa = 'Expression of the ""%1"" resource receiving is not defined';
								|it = 'Non è indicata l''espressione di ricezione della risorsa ""%1""';
								|pl = 'Nie określono wyrażenie otrzymanie zasobu ""%1""';
								|tr = '""%1"" kaynağının alımını sağlayan ifade tanımlanmamış'"));
	EndIf;
	
	If ThisIsRemainder Then
		DCSchema = GetTemplate("MonetaryIndicatorBalance");
		QueryText = DCSchema.DataSets.IndicatorValues_2.Query;
		QueryText = StrReplace(QueryText, "SumOpeningBalance", ExpressionsOpeningBalance[Factor.TotalType]);
		QueryText = StrReplace(QueryText, "SumClosingBalance", ExpressionsClosingBalance[Factor.TotalType]);
		If Factor.OpeningBalance Then
			QueryText = StrReplace(QueryText, "BalanceField", "temp");
			QueryText = StrReplace(QueryText, "Value", "BalanceField");
			QueryText = StrReplace(QueryText, "temp", "Value");
		EndIf;
	Else
		DCSchema = GetTemplate("MonetaryIndicatorTurnover");
		QueryText = DCSchema.DataSets.IndicatorValues_2.Query;
		QueryText = StrReplace(QueryText, "SumTurnover", ExpressionsTurnover[Factor.TotalType]);
	EndIf;
	
	AddDimensionFields(QueryText, Dimensions);

	QueryText = StrReplace(QueryText, "International", Source);
	DCSchema.DataSets.IndicatorValues_2.Query = QueryText;
	
	AddDimensionFields(DCSchema.DefaultSettings, Dimensions);

	ListOfExtdimensionSpecies = New ValueList;
	ExtDimensionNumber = 1;
	If ExtDimension <> Undefined Then
		For Each ExtdimensionAccounts In ExtDimension Do
			CurExtdimension = ExtdimensionAccounts.Value; // See IndicatorScheme.ExtDimension
			
			If Source = "International" Or Source = "InternationalWithoutCorrespondence" Then
				If TypeOf(CurExtdimension.Kind) <> FinancialAccountingClientServer.TypeSpeciesExtdimension() Then
					Continue;
				EndIf;
			Else
				If TypeOf(CurExtdimension.Kind) <> LocalAccntingClientServer.TypeSpeciesExtdimension() Then
					Continue;
				EndIf;
			EndIf;
			
			ListOfExtdimensionSpecies.Add(CurExtdimension.Kind);
			If CurExtdimension.HasSettings Then
				SelectionRepository = CurExtdimension.Filter; // ValueStorage
				ExtdimensionSelectionSettings = SelectionRepository.Get();
				InternationalReportingServer.ReplaceNameExtdimensionInSelection(ExtdimensionSelectionSettings.Filter, ExtdimensionAccounts.Key);
				FinReports.CopyFilter(ExtdimensionSelectionSettings.Filter,DCSchema.DefaultSettings.Filter);
			EndIf; 
			
			Field = "RegisterTable.ExtDimension" + ExtDimensionNumber; 
			DCSchema.DataSets.IndicatorValues_2.Query = StrReplace(DCSchema.DataSets.IndicatorValues_2.Query, "&ExtDimension" + ExtDimensionNumber, Field + " AS " + ExtdimensionAccounts.Key);
			CalculatedExtdimension = DCSchema.CalculatedFields.Add();
			CalculatedExtdimension.DataPath = ExtdimensionAccounts.Key;
			CalculatedExtdimension.Expression = StrTemplate("CASE WHEN %1 IS NULL OR PRESENTATION(%1) ="""" THEN UNDEFINED ELSE %1 END", ExtdimensionAccounts.Key);
			FinReports.NewSelectionField(DCSchema.DefaultSettings,ExtdimensionAccounts.Key, CurExtdimension.Description);
			
			ExtDimensionNumber = ExtDimensionNumber + 1;
		EndDo;
		FinReports.SetLayoutParameter(DCSchema.DefaultSettings,"ExtDimensionTurnoverType",ListOfExtdimensionSpecies);
	EndIf;
	
	If ThisIsRemainder Then
		RoleOfRemainder = FinReports.NewDataSetFieldRole();
		RoleOfRemainder.BalanceGroup = "Balance";
		RoleOfRemainder.Balance = True;
		RoleOfRemainder.AccountField = "Account";
		If Factor.OpeningBalance Then
			RoleOfRemainder.BalanceType = DataCompositionBalanceType.OpeningBalance;
			FinReports.SetRoleOfSetField(DCSchema.DataSets.IndicatorValues_2, "Value", RoleOfRemainder);
			
			RoleOfRemainder.BalanceType = DataCompositionBalanceType.ClosingBalance;
			FinReports.SetRoleOfSetField(DCSchema.DataSets.IndicatorValues_2, "BalanceField", RoleOfRemainder);
			
		Else
			RoleOfRemainder.BalanceType = DataCompositionBalanceType.ClosingBalance;
			FinReports.SetRoleOfSetField(DCSchema.DataSets.IndicatorValues_2, "Value", RoleOfRemainder);
			
			RoleOfRemainder.BalanceType = DataCompositionBalanceType.OpeningBalance;
			FinReports.SetRoleOfSetField(DCSchema.DataSets.IndicatorValues_2, "BalanceField", RoleOfRemainder);
			
		EndIf;
	Else
		FinReports.SetRoleOfSetField(DCSchema.DataSets.IndicatorValues_2, "Value");
	EndIf;
	
	FinReports.SetFilter(DCSchema.DefaultSettings.Filter, "Account", Factor.GLAccount_);
	
	Composer = FinReports.SchemaComposer(DCSchema, False);
	If Factor.HasSettings Then
		AdditionalSelectionRepository = Factor.AdditionalSelection; // ValueStorage
		IndicatorSelectionSettings = AdditionalSelectionRepository.Get();
		If IndicatorSelectionSettings <> Undefined Then
			
			FilterIndicator_ = RenameExtdimensionFromDoPSelection(IndicatorSelectionSettings.Filter, Factor, ListOfExtdimensionSpecies); 
			FinReports.CopyFilter(FilterIndicator_, Composer.Settings.Filter);
		EndIf;
	EndIf;
	
	FinReports.SetLayoutParameter(Composer.Settings, "ReportItem", Factor.ReportItem);
	FinReports.SetLayoutParameter(Composer.Settings, "ReverseSign" , Factor.ReverseSign);
	FinReports.SetLayoutParameter(Composer.Settings, "RowCode"    , Factor.ReportRowCode);
	FinReports.SetLayoutParameter(Composer.Settings, "Note"   , Factor.Note);
	
	If ValueIsFilled(ListOfExtdimensionSpecies) Then
		FinReports.SetLayoutParameter(Composer.Settings,"ExtDimensionTurnoverType", ListOfExtdimensionSpecies);
	EndIf;
	
	IndicatorScheme = New Structure("Schema, Settings",DCSchema, Composer.GetSettings());
	Return IndicatorScheme;
	
EndFunction

Function SchemeOfNonMonetaryIndicator(Factor, Dimensions = Undefined, Filter = Undefined)
	
	FinReports = FinancialReportingServer;
	DCSchema = GetTemplate("NonMonetaryItem");
	QueryText = DCSchema.DataSets.IndicatorValues_2.Query;
	AddDimensionFields(QueryText, Dimensions);
	
	DCSchema.DataSets.IndicatorValues_2.Query = QueryText;
	
	AddDimensionFields(DCSchema.DefaultSettings, Dimensions);
	
	Composer = FinReports.SchemaComposer(DCSchema);
	FinReports.SetLayoutParameter(Composer.Settings, "Factor", Factor.NonMonetaryItem);
	
	IndicatorScheme = New Structure("Schema, Settings",DCSchema, Composer.GetSettings());
	Return IndicatorScheme;
	
EndFunction

Function SchemeOfDerivedIndicator(Factor, Dimensions = Undefined, ExtDimension = Undefined, Filter = Undefined)
	
	FinReports = FinancialReportingServer;
	DCSchema = GetTemplate("DerivedItem");
	NumberType = TMCommonUse.MoneyFieldTypeDescription();
	If Factor.ThisIsReference Then
		FormulaOperands = Common.ObjectAttributeValue(Factor.LinkedItem1, "FormulaOperands.Id").Unload();
	Else
		FormulaOperands = Common.ObjectAttributeValue(Factor.ReportItem, "FormulaOperands.Id").Unload();
	EndIf;
	For Each Operand In FormulaOperands Do
		FinReports.NewSetField(DCSchema.DataSets.OperandValues, Operand["Id"],,, NumberType);
	EndDo;
	For Each Dimension In Dimensions Do
		FinReports.NewSetField(DCSchema.DataSets.OperandValues, Dimension.Value);
		FinReports.NewSelectionField(DCSchema.DefaultSettings,Dimension.Value);
	EndDo;
	
	If ExtDimension <> Undefined Then
		For Each ExtdimensionAccounts In ExtDimension Do
			FinReports.NewSetField(DCSchema.DataSets.OperandValues, ExtdimensionAccounts.Key);
			FinReports.NewSelectionField(DCSchema.DefaultSettings, ExtdimensionAccounts.Key);
		EndDo;
	EndIf;
	
	ValueField = DCSchema.CalculatedFields[0];
	If Not IsBlankString(Factor.Formula) Then
		ValueField.Expression = "(" + Factor.Formula + ") * CASE WHEN &ReverseSign = TRUE THEN -1 ELSE 1 END";
	EndIf;
	Composer = FinReports.SchemaComposer(DCSchema);
	
	IndicatorScheme = New Structure("Schema, Settings", DCSchema, Composer.GetSettings());
	Return IndicatorScheme;
	
EndFunction

Procedure AddDimensionFields(TextSet, Dimensions)
	
	FinReports = FinancialReportingServer;
	ThisIsRequestText = TypeOf(TextSet) = Type("String");
	For Each Dimension In Dimensions Do
		If ThisIsRequestText Then
			Field = "RegisterTable." + Dimension.Value;
			TextSet = StrReplace(TextSet, "&" + Dimension.Value, Field);
		Else
			FinReports.NewSelectionField(TextSet, Dimension.Value, Dimension.Presentation);
			If Dimension.Filter <> Undefined Then
				FinReports.CopyFilter(Dimension.Filter, TextSet.Filter, True);
			EndIf;
			If StrFind(Dimension.Value,"ExtDimension")  > 0 Then
				FinReports.NewSelectionField(TextSet, "ExtDimensionType", "ExtDimensionType");
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Function RenameExtdimensionFromDoPSelection(Setting, Factor, ListOfExtdimensionSpecies, AccountExtDimensionTypes = Undefined)  Export
	
	NewSetting = New DataCompositionFilter;
	FinancialReportingServer.CopyFilter(Setting, NewSetting);
	If ListOfExtdimensionSpecies = Undefined Then
		ListOfExtdimensionSpecies = New ValueList;
	EndIf;
	If AccountExtDimensionTypes = Undefined Then
		AccountExtDimensionTypes = Factor.GLAccount_.ExtDimensionTypes;
	EndIf;
	
	For Each FilterSettings In Setting.Items Do
		
		If TypeOf(FilterSettings) = Type("DataCompositionFilterItemGroup") Then
			FilterSettings = RenameExtdimensionFromDoPSelection(FilterSettings, Factor, ListOfExtdimensionSpecies, AccountExtDimensionTypes);
		ElsIf StrFind(FilterSettings.LeftValue, "ExtDimension") <> 0 Then
			
			For ExtDimensionNumber = 1 To Min(FinancialAccountingServerCached.MaxExtDimensionCount(), 
				AccountExtDimensionTypes.Count()) Do
				If StrFind(FilterSettings.LeftValue, "ExtDimension" + ExtDimensionNumber) <> 0 Then
					ExtDimensionType = AccountExtDimensionTypes[ExtDimensionNumber-1].ExtDimensionType;
					ExtdimensionInParameter = ListOfExtdimensionSpecies.FindByValue(ExtDimensionType);
					If ExtdimensionInParameter <> Undefined Then
						ExtdimensionNumberOfSelection = ListOfExtdimensionSpecies.IndexOf(ExtdimensionInParameter)+1;
					Else
						ListOfExtdimensionSpecies.Add(ExtDimensionType);
						ExtdimensionNumberOfSelection = ListOfExtdimensionSpecies.Count();
					EndIf;
					
					If ExtDimensionNumber <> ExtdimensionNumberOfSelection Then
						CurrentFilter = NewSetting.Items[Setting.Items.IndexOf(FilterSettings)];
						CurrentFilter.LeftValue = New DataCompositionField(StrReplace(FilterSettings.LeftValue, "ExtDimension"+ExtDimensionNumber, "ExtDimension"+ExtdimensionNumberOfSelection));
					EndIf;
					
				EndIf;
			EndDo; 
		EndIf;
		
	EndDo; 
	
	Return NewSetting;
	
EndFunction

#EndRegion
#EndRegion

#EndIf

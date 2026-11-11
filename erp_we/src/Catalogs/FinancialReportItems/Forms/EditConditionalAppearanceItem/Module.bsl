

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("CreatedAreaType", CreatedAreaType)
		Or Not Parameters.Property("AddressOfReportItems")
		Or Not Parameters.Property("RegisteredRows")
		Or Not Parameters.Property("DesigningColumns") Then
		
		MessageText = NStr("vi = 'Mở trực tiếp của hình thức này không được cung cấp.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено.';
							|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
							|it = 'L''apertura diretta di questo modulo non è prevista.';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane.';
							|tr = 'Bu formun doğrudan açılması sağlanamadı.'");
		Raise MessageText;
	EndIf;
	
	If Parameters.Property("CellsSettings") Then
		RegisteredRows.Clear();
		DesigningColumns.Clear();
		For Each String In Parameters.RegisteredRows Do
			NewRow = RegisteredRows.Add();
			NewRow.ReportItem = String;
		EndDo;
		For Each Column In Parameters.DesigningColumns Do
			NewRow = DesigningColumns.Add();
			NewRow.ReportItem = Column;
		EndDo;
	Else
		RegisteredRows.Load(GetFromTempStorage(Parameters.RegisteredRows));
		DesigningColumns.Load(GetFromTempStorage(Parameters.DesigningColumns));
	EndIf;
	
	For Each String In RegisteredRows Do
		If ValueIsFilled(String.ReportItem) Then
			String.NameForPrinting = GetFromTempStorage(String.ReportItem).NameForPrinting;
		Else
			String.NameForPrinting = NStr("vi = 'Tiêu đề bảng';
											|ru = 'Заголовок таблицы';
											|en = 'Table header'; fa = 'سرعنوان جدول';
											|it = 'Intestazione della tabella';
											|pl = 'Nagłówek tabeli';
											|tr = 'Tablo başlıkları'");
		EndIf;
	EndDo;
	For Each Column In DesigningColumns Do
		If ValueIsFilled(Column.ReportItem) Then
			Column.NameForPrinting = GetFromTempStorage(Column.ReportItem).NameForPrinting;
		Else
			Column.NameForPrinting = NStr("vi = 'Tiêu đề bảng';
											|ru = 'Заголовок таблицы';
											|en = 'Table header'; fa = 'سرعنوان جدول';
											|it = 'Intestazione della tabella';
											|pl = 'Nagłówek tabeli';
											|tr = 'Tablo başlıkları'");
		EndIf;
	EndDo;
	
	If Parameters.Property("AppearanceItemKey") Then
		AppearanceItemKey = Parameters.AppearanceItemKey;
	EndIf;
	
	If Not ValueIsFilled(AppearanceItemKey) Then
		AppearanceItemKey = New UUID;
	EndIf;
	
	DCS = FinancialReportingServer.NewScheme();
	Set = DataCompositionServer.AddEmptyDataSet(DCS, Type("DataCompositionSchemaDataSetObject"));
	For Each Field In Parameters.FilterFields Do
		ElementStructure = GetFromTempStorage(Field);
		If Not (ElementStructure.ItemKind = Enums.FinancialReportItemKinds.Dimension) Then
			Continue;
		EndIf;
		DimensionType = FinancialReportingServerCall.ValueOfAdditionalProps(ElementStructure, "DimensionType");
		If DimensionType <> Enums.TypesOfBudgetReportDimensions.Dimension
			And DimensionType <> Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
			Continue;
		EndIf;
		If DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
			DimensionName = FinancialReportingServerCall.ValueOfAdditionalProps(ElementStructure, "DimensionName");
			If DimensionName = "Organization" Then
				ValueType = New TypeDescription("CatalogRef.Companies");
			ElsIf DimensionName = "Department" Then
				ValueType = New TypeDescription("CatalogRef.BusinessStructure");
			ElsIf DimensionName = "Scenario" Then
				ValueType = New TypeDescription("CatalogRef.BudgetingScenarios");
			ElsIf DimensionName = "Currency" Then
				ValueType = New TypeDescription("CatalogRef.Currencies");
			EndIf;
		Else
			DimensionKind = FinancialReportingServerCall.ValueOfAdditionalProps(ElementStructure, "DimensionKind");
			ValueType = Common.ObjectAttributeValue(DimensionKind, "ValueType");
			DimensionName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		EndIf;
		
		SetField = FinancialReportingServer.NewSetField(Set,
			DimensionName,
			DimensionName,
			ElementStructure.NameForPrinting,
			ValueType);
		SetField.AttributeUseRestriction.Condition = True;
		
	EndDo;
	
	ReportItems = GetFromTempStorage(Parameters.AddressOfReportItems);
	ArrayOfIndicators = New ValueList;
	If Not Parameters.ThisIsASimpleTable Then
		
		IndicatorPresentation = NStr("vi = 'Giá trị ô';
									|ru = 'Значение ячейки';
									|en = 'Cell value'; fa = 'Cell value';
									|it = 'Valore della cella';
									|pl = 'Wartość komórki';
									|tr = 'Hücre değeri'");
		ArrayOfIndicators.Add("CellValue", IndicatorPresentation);
		
	Else
		
		Table = FinancialReportingServer.ElementTable(ReportItems, Parameters.ItemAddressInStorage);
		
		FoundRows = Table.Rows.FindRows(New Structure("ItemKind", Enums.FinancialReportItemKinds.NonFinancialItem));
		If FoundRows.Count() Then
			IndicatorPresentation = NStr("vi = 'Giá trị (NFP)';
										|ru = 'Значение (НФП)';
										|en = 'Value (NFI)'; fa = 'Value (NFI)';
										|it = 'Valore (NFP)';
										|pl = 'Wartość (NFE)';
										|tr = 'Değer (MOG)'");
			ArrayOfIndicators.Add("Value", IndicatorPresentation);
		EndIf;
		
		Search = New Structure("ItemKind", Enums.FinancialReportItemKinds.BudgetFlowItem);
		BudgetItems = Table.Rows.FindRows(Search, True);
		Search = New Structure("ItemKind", Enums.FinancialReportItemKinds.BudgetBalanceItem);
		FoundRows = Table.Rows.FindRows(Search, True);
		CommonClientServer.SupplementArray(FoundRows, BudgetItems);
		
		ThereIsSum = False;
		ThereIsQuantity = False;
		For Each FoundRow In FoundRows Do
			TypeOfIndicators = FinancialReportingServerCall.ValueOfAdditionalProps(FoundRow.AddressOfItemStructure, "DisplayedIndicators");
			If TypeOfIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.Count
				Or TypeOfIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.QuantityAndAmount Then
				ThereIsQuantity = True;
			EndIf;
			If TypeOfIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.Sum
				Or TypeOfIndicators = Enums.TypesOfDisplayedBudgetReportIndicators.QuantityAndAmount Then
				ThereIsSum = True;
			EndIf;
			If ThereIsQuantity And ThereIsSum Then
				Break;
			EndIf;
		EndDo;
		
		If ThereIsQuantity Then
			IndicatorPresentation = NStr("vi = 'Số lượng';
										|ru = 'Количество';
										|en = 'Quantity'; fa = 'مقدار';
										|it = 'Quantità';
										|pl = 'Ilość';
										|tr = 'Miktar'");
			ArrayOfIndicators.Add("Count", IndicatorPresentation);
		EndIf;
		
		If ThereIsSum Then
			IndicatorPresentation = NStr("vi = 'Tổng số';
										|ru = 'Сумма';
										|en = 'Amount'; fa = 'مبلغ';
										|it = 'Importo';
										|pl = 'Wartość';
										|tr = 'Tutar'");
			ArrayOfIndicators.Add("Sum", IndicatorPresentation);
		EndIf;
		
	EndIf;
	
	If CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.CellsAtIntersectionOfRowsAndColumns Then
		
		For Each Factor In ArrayOfIndicators Do
		
			SetField = FinancialReportingServer.NewSetField(Set,
				Factor.Value,
				Factor.Value, 
				Factor.Presentation,
				TMCommonUse.MoneyFieldTypeDescription());
		
		EndDo;
		
	Else
		
		For Each Field In Parameters.ValueSelectionFields Do
			
			Item = GetFromTempStorage(Field);
			CellName = StrReplace(Item.NameForPrinting, ".", " ");
			
			For Each Factor In ArrayOfIndicators Do
			
				FieldName = "Filter_" + CellName + " " + Factor.Value;
				
				SetField = FinancialReportingServer.NewSetField(Set, FieldName, FieldName, 
									"[" + CellName + "] " + Factor.Value, TMCommonUse.MoneyFieldTypeDescription());
				
				If Not DrillDownOfAppearanceItemFilterFields.FindRows(
							New Structure("ReportItem, ResourceName", Field, Factor)).Count() Then
					NewRow = DrillDownOfAppearanceItemFilterFields.Add();
					NewRow.ReportItem = Field;
					NewRow.FilterFieldName = FieldName;
					NewRow.ResourceName = Factor.Value;
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	SchemaURL = PutToTempStorage(DCS, UUID);
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(SchemaURL);
	Conditions.Initialize(AvailableSettingsSource);
	ParameterName = "Condition";
	If Parameters.Property(ParameterName) Then
		Conditions.LoadSettings(GetFromTempStorage(Parameters[ParameterName]));
	Else
		Conditions.LoadSettings(DCS.DefaultSettings);
	EndIf;
	
	BackColor = New Structure;
	BackColor.Insert("Name",				"BackColor");
	BackColor.Insert("Default",		StyleColors.FieldBackColor);
	BackColor.Insert("Type",				"Color");
	BackColor.Insert("Order",			1);
	
	TextColor = New Structure;
	TextColor.Insert("Name",				"TextColor");
	TextColor.Insert("Default",		StyleColors.FieldTextColor);
	TextColor.Insert("Type",				"Color");
	TextColor.Insert("Order",			2);
	
	BorderColor = New Structure;
	BorderColor.Insert("Name",				"BorderColor");
	BorderColor.Insert("Default",		StyleColors.ReportLineColor);
	BorderColor.Insert("Type",				"Color");
	BorderColor.Insert("Order",			3);
	
	Font = New Structure;
	Font.Insert("Name",					"Font");
	Font.Insert("Default",			StyleFonts.TextFont);
	Font.Insert("Type",					"Font");
	Font.Insert("Order",				4);
	
	HorizontalPositionProperties = New Structure;
	HorizontalPositionProperties.Insert("Name",				"HorizontalAlign");
	HorizontalPositionProperties.Insert("Default",		HorizontalAlign.Auto);
	HorizontalPositionProperties.Insert("Type",				"HorizontalAlign");
	HorizontalPositionProperties.Insert("Order",			5);
	
	VerticalPositionProperties = New Structure;
	VerticalPositionProperties.Insert("Name",					"VerticalAlign");
	VerticalPositionProperties.Insert("Default",			VerticalAlign.Center);
	VerticalPositionProperties.Insert("Type",					"VerticalAlign");
	VerticalPositionProperties.Insert("Order",				6);
	
	TextOrientation = New Structure;
	TextOrientation.Insert("Name",				"TextOrientation");
	TextOrientation.Insert("Default",		0);
	TextOrientation.Insert("Type",				"TextOrientation");
	TextOrientation.Insert("Order",			7);
	
	StringFormatProperties = New Structure;
	StringFormatProperties.Insert("Name",				"Format");
	StringFormatProperties.Insert("Default",		"");
	StringFormatProperties.Insert("Type",				"Format");
	StringFormatProperties.Insert("Order",			8);
	
	ParametersMap = New Map;
	ParametersMap.Insert("BackColor",							BackColor);
	ParametersMap.Insert("TextColor",						TextColor);
	ParametersMap.Insert("BorderColor",						BorderColor);
	ParametersMap.Insert("Font",							Font);
	ParametersMap.Insert("HorizontalAlign",			HorizontalPositionProperties);
	ParametersMap.Insert("VerticalAlign",			VerticalPositionProperties);
	ParametersMap.Insert("TextOrientation",					TextOrientation);
	ParametersMap.Insert("Format",							StringFormatProperties);
	
	PresentationOfMAParameters = New Map();
	PresentationOfMAParameters.Insert("BackColor",						NStr("vi = 'Màu nền';
																				|ru = 'Цвет фона';
																				|en = 'Background color'; fa = 'رنگ پس‌زمینه';
																				|it = 'Colore di sfondo';
																				|pl = 'Kolor tła';
																				|tr = 'Arka plan rengi'"));
	PresentationOfMAParameters.Insert("TextColor",					NStr("vi = 'Màu nội dung';
																			|ru = 'Цвет текста';
																			|en = 'Text color'; fa = 'رنگ متن';
																			|it = 'Colore testo';
																			|pl = 'Kolor tekstu';
																			|tr = 'Metin rengi'"));
	PresentationOfMAParameters.Insert("BorderColor",					NStr("vi = 'Màu viền';
																			|ru = 'Цвет границы';
																			|en = 'Border color'; fa = 'رنگ کادر';
																			|it = 'Colore del bordo';
																			|pl = 'Kolor granicy';
																			|tr = 'Uzaklık rengi'"));
	PresentationOfMAParameters.Insert("Font",							NStr("vi = 'Cỡ chữ';
																				|ru = 'Шрифт';
																				|en = 'Font'; fa = 'فونت';
																				|it = 'Font';
																				|pl = 'Font';
																				|tr = 'Yazı tipi'"));
	PresentationOfMAParameters.Insert("HorizontalAlign",		NStr("vi = 'Vị trí nằm ngang';
																	|ru = 'Горизонтальное положение';
																	|en = 'Horizontal position'; fa = 'موقعیت افقی';
																	|it = 'Posizione orizzontale';
																	|pl = 'Pozycja pozioma';
																	|tr = 'Yatay konum'"));
	PresentationOfMAParameters.Insert("VerticalAlign",			NStr("vi = 'Vị trí thẳng đứng';
																		|ru = 'Вертикальное положение';
																		|en = 'Vertical position'; fa = 'موقعیت عمودی';
																		|it = 'Posizione verticale';
																		|pl = 'Pozycja pionowa';
																		|tr = 'Dikey konum'"));
	PresentationOfMAParameters.Insert("TextOrientation",				NStr("vi = 'Định hướng văn bản';
																			|ru = 'Ориентация текста';
																			|en = 'Text orientation'; fa = 'جهت متن';
																			|it = 'Orientamento del testo';
																			|pl = 'Orientacja tekstu';
																			|tr = 'Metin yönü'"));
	PresentationOfMAParameters.Insert("Format",						NStr("vi = 'Định dạng';
																			|ru = 'Формат';
																			|en = 'Format'; fa = 'قالب';
																			|it = 'Formato';
																			|pl = 'Format';
																			|tr = 'Format'"));
	
	AddressOfParameterCompliance = PutToTempStorage(ParametersMap, UUID);
	
	PreviousDesign = Undefined;
	If Parameters.Property("Appearance") Then
		PreviousDesign = GetFromTempStorage(Parameters.Appearance);
	EndIf;
	
	For Each KeyAndValue In ParametersMap Do
		
		NewRow = Appearance.Add();
		NewRow.Parameter = KeyAndValue.Key;
		NewRow.Order = KeyAndValue.Value.Order;
		NewRow.ParameterPresentation = PresentationOfMAParameters.Get(NewRow.Parameter);
		If PreviousDesign <> Undefined Then
			DesignValue = PreviousDesign.Find(KeyAndValue.Key, "Parameter");
			If DesignValue <> Undefined Then
				NewRow.Use = DesignValue.Use;
				NewRow[KeyAndValue.Value.Type] = DesignValue.Appearance;
				Continue;
			EndIf;
		EndIf;
		NewRow[KeyAndValue.Value.Type] = KeyAndValue.Value.Default;
		
	EndDo;
	
	Appearance.Sort("Order");
	ThisForm.WindowOptionsKey = "WindowOption_" + Common.EnumerationValueName(CreatedAreaType);
	FormControl();
	
EndProcedure

#EndRegion

#Region TableEventHandlersForms

&AtClient
Procedure DesignTreeFormatStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	Designer = New FormatStringWizard;
	Designer.Text = Items.RegistrationTree.CurrentData.Format;
	Designer.AvailableTypes = New TypeDescription("Number, Date");
	DescriptionOfTheAlert = New CallbackDescription("WhenSelectingFormat", ThisForm);
	Designer.Show(DescriptionOfTheAlert);
	
EndProcedure

&AtClient
Procedure DesignTreeColorOnChange(Item)
	
	SetCurLineFlag();
	
EndProcedure

&AtClient
Procedure DesignTreeFontOnChange(Item)
	
	SetCurLineFlag();
	
EndProcedure

&AtClient
Procedure DesignTreeFormatOnChange(Item)
	
	SetCurLineFlag();
	
EndProcedure

&AtClient
Procedure DesignTreeHorizontalPositionOnChange(Item)
	
	SetCurLineFlag();
	
EndProcedure

&AtClient
Procedure DesignTreeVerticalPositionOnChange(Item)
	
	SetCurLineFlag();
	
EndProcedure

&AtClient
Procedure DesignTreeTextOrientationOnChange(Item)
	
	SetCurLineFlag();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	Close(GetResultAddress());
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WhenSelectingFormat(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Items.RegistrationTree.CurrentData.Format = Result;
	SetCurLineFlag();
	
EndProcedure

&AtClient
Procedure SetCurLineFlag()
	
	CurrentData = Items.RegistrationTree.CurrentData;
	CurrentData.Use = True;
	
EndProcedure

&AtServer
Procedure FormControl()
	
	LineVisibility = True;
	ColumnsVisibility = True;
	YouCanImposeSelection = True;
	
	If CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.EntireTable Then
		LineVisibility = False;
		ColumnsVisibility = False;
		YouCanImposeSelection = False;
	ElsIf CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.EntireColumn Then
		LineVisibility = False;
	ElsIf CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.EntireRow Then
		ColumnsVisibility = False;
	ElsIf CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.ColumnHeaders Then
		LineVisibility = False;
	ElsIf CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.RowsHeaders Then
		ColumnsVisibility = False;
	EndIf;
	
	Items.DesigningColumns.Visible 	= ColumnsVisibility;
	Items.RegisteredRows.Visible 	= LineVisibility;
	Items.ConditionPage.Visible 		= YouCanImposeSelection;
	
EndProcedure

&AtServer
Function GetResultAddress()
	
	DesignResult_ = Appearance.Unload();
	FoundRows = DesignResult_.FindRows(New Structure("Use", False));
	For Each TableRow In FoundRows Do
		DesignResult_.Delete(TableRow);
	EndDo;
	
	ParametersMap = GetFromTempStorage(AddressOfParameterCompliance);
	ResultingResult = DesignResult_.CopyColumns("Use, Parameter");
	ResultingResult.Columns.Add("Appearance");
	For Each ResultString1 In DesignResult_ Do
		NewRow = ResultingResult.Add();
		FillPropertyValues(NewRow, ResultString1);
		NewRow.Appearance = ResultString1[ParametersMap[ResultString1.Parameter].Type];
	EndDo;
	
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Appearance", ResultingResult);
	ResultingStructure.Insert("Condition", Conditions.GetSettings());
	ResultingStructure.Insert("CreatedAreaType", CreatedAreaType);
	ResultingStructure.Insert("AppearanceItemKey", AppearanceItemKey);
	ResultingStructure.Insert("RegisteredRows", RegisteredRows.Unload());
	ResultingStructure.Insert("DesigningColumns", DesigningColumns.Unload());
	ResultingStructure.Insert("DrillDownOfAppearanceItemFilterFields", DrillDownOfAppearanceItemFilterFields.Unload());
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

#EndRegion


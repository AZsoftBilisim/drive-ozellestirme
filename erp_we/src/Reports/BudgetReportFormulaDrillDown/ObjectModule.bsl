#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnCreateAtServer = True;
	
	// For direct report generation
	Settings.Insert("External", True);
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.OnCreateAtServer
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Try
		FormParameters = Form.Parameters; // Structure
		ReportParametersToStore = FormParameters.ReportParametersToStore;
	Except
		Raise NStr("vi = 'Mở báo cáo chỉ có thể khi giải mã từ báo cáo ngân sách';
					|ru = 'Открытие отчета возможно только при расшифровке из бюджетных отчетов';
					|en = 'This report can only be opened with the drill-down from budget reports'; fa = 'This report can only be opened with the drill-down from budget reports';
					|it = 'È possibile aprire il report solo durante la trascrizione dai report di budget';
					|pl = 'Otwieranie raportu jest możliwe tylko przy dekodowaniu z raportów budżetowych';
					|tr = 'Raporlar sadece bütçe raporlarından deşifre için açılabilir'");
	EndTry;
	
	AdditionalProperties = New Structure();
	For Each KeyAndValue In ReportParametersToStore Do
		AdditionalProperties.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	ReportParametersAddress = PutToTempStorage(AdditionalProperties, Form.UUID);
	
	FormAttribute = New FormAttribute("ReportParametersAddress", New TypeDescription("String"));
	AddingArray = New Array;
	AddingArray.Add(FormAttribute);
	Form.ChangeAttributes(AddingArray);
	
	Form.ReportParametersAddress = ReportParametersAddress;
	
	If TypeOf(Form.ReportSettings) = Type("Structure") Then
		Form.ReportSettings.Insert("External", True);
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   NewDCSettings - DataCompositionSettings - Settings to upload to The Settings Composer.
// 		Learn more See ReportsOverridable.BeforeLoadVariantAtServer.
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	NewDCSettings.AdditionalProperties.Insert("ReportParametersAddress", ThisForm.ReportParametersAddress);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	AdditionalProperties = SettingsComposer.Settings.AdditionalProperties;
	
	FinReports = FinancialReportingServer;
	
	ReportData = New ValueTable;
	ReportData.Columns.Add("OperandName");
	ReportData.Columns.Add("OperandValue");
	ReportData.Columns.Add("OperandDescription");
	ReportData.Columns.Add("AdditionalInformation_3");
	ReportData.Columns.Add("ReportParametersAddress");
	ReportData.Columns.Add("DataLineIndex");
	ReportData.Columns.Add("IndicatorName");
	ReportData.Columns.Add("NumberOfTheFirstCharacter");
	ReportData.Columns.Add("CalculationProcedure");
	
	StoredAdditionalProperties = Undefined;
	If AdditionalProperties.Property("ReportParametersAddress") Then
		ReportParametersAddress = AdditionalProperties.ReportParametersAddress;
		If IsTempStorageURL(ReportParametersAddress) Then
			StoredAdditionalProperties = GetFromTempStorage(ReportParametersAddress);
		EndIf;
	EndIf;
	
	If StoredAdditionalProperties = Undefined Then
		Raise NStr("vi = 'Một báo cáo chỉ có thể được gọi để giải mã giá trị của báo cáo ngân sách hoặc ví dụ ngân sách.';
					|ru = 'Отчет может быть вызван только для расшифровки значения бюджетного отчета или экземпляра бюджета';
					|en = 'This report can only be called to drill down a budget report value or a Budget entry form'; fa = 'This report can only be called to drill down a budget report value or a Budget entry form';
					|it = 'Il report può essere richiesto solo per la trascrizione del valore del report di budget o del documento di inserimento del budget';
					|pl = 'Raport można wywołać tylko w celu odszyfrowania wartości raportu budżetu lub egzemplarza budżetu';
					|tr = 'Rapor yalnızca bütçe raporunun veya bütçe giriş formunun değerini deşifre etmek için çağrılabilir'");
	EndIf;
	
	CellData_ = GetFromTempStorage(StoredAdditionalProperties.AddressOfCellData);
	CellDataString = CellData_[StoredAdditionalProperties.DataLineIndex];
	
	BudgetProfile = StoredAdditionalProperties.BudgetProfile;
	ColumnStructureOfDataTable = BudgetReportingCacheCalculationServer.ColumnsOfDataTable_(BudgetProfile);
	StructureOfReportDescription = BudgetReportingCacheCalculationServer.DescriptionOfReport(BudgetProfile,
			ColumnStructureOfDataTable,
			StoredAdditionalProperties.GenerationMode);
	
	CellStructure = StructureOfReportDescription.CellStructure;
	CellParameters = StructureOfReportDescription.CellParameters;
	
	StoredAdditionalProperties.Insert("CellStructure", CellStructure);
	StoredAdditionalProperties.Insert("CellParameters", CellParameters);
	StoredAdditionalProperties.Insert("ReportParametersAddress", ReportParametersAddress);
	
	FinReports.SetLayoutParameter(ReportSettings,
			"DerivedExponentName",
			DerivedExponentName(CellDataString, CellParameters));
	
	HeaderData_ = New ValueTable;
	HeaderData_.Columns.Add("Group");
	HeaderData_.Columns.Add("Value");
	
	NewRow = HeaderData_.Add();
	NewRow.Group = NStr("vi = 'Tham số báo cáo:';
						|ru = 'Параметры отчета:';
						|en = 'Report parameters:'; fa = 'Report parameters:';
						|it = 'Parametri del report:';
						|pl = 'Parametry raportu:';
						|tr = 'Rapor parametreleri:'");
	NewRow.Value = ReportParameters(StoredAdditionalProperties);
	
	NewRow = HeaderData_.Add();
	NewRow.Group = NStr("vi = 'Lọc:';
						|ru = 'Отбор:';
						|en = 'Filter:'; fa = 'فیلتر:';
						|it = 'Selezione:';
						|pl = 'Filter:';
						|tr = 'Filtre:'");
	NewRow.Value = SelectionAndGrouping(CellDataString, StoredAdditionalProperties);
	
	Formula = Formula(CellDataString, CellParameters);
	
	NewRow = HeaderData_.Add();
	NewRow.Group = NStr("vi = 'Công thức:';
						|ru = 'Формула:';
						|en = 'Formula:'; fa = 'Formula:';
						|it = 'Formula:';
						|pl = 'Formula:';
						|tr = 'Formül:'");
	NewRow.Value = Formula;
	
	NewRow = HeaderData_.Add();
	NewRow.Group = NStr("vi = 'Ghi chú:';
						|ru = 'Примечание:';
						|en = 'Note:'; fa = 'Note:';
						|it = 'Nota:';
						|pl = 'Note:';
						|tr = 'Not:'");
	NewRow.Value = Note(CellDataString, CellParameters);
	
	FormulaDetails = FormulaDetails(CellDataString, CellData_, Formula, StoredAdditionalProperties, ReportData, ColumnStructureOfDataTable);
	
	NewRow = HeaderData_.Add();
	NewRow.Group = NStr("vi = 'Tính toán:';
						|ru = 'Вычисления:';
						|en = 'Calculations:'; fa = 'Calculations:';
						|it = 'Calcoli:';
						|pl = 'Calculations:';
						|tr = 'Hesaplamalar:'");
	NewRow.Value = FormulaDetails.Calculation;
	
	NewRow = HeaderData_.Add();
	NewRow.Group = NStr("vi = 'Kết quả:';
						|ru = 'Результат:';
						|en = 'Result:'; fa = 'Result:';
						|it = 'Risultato:';
						|pl = 'Result:';
						|tr = 'Sonuç:'");
	NewRow.Value = FormulaDetails.Result;
	
	ExternalSets = New Structure;
	ExternalSets.Insert("ReportData", ReportData);
	ExternalSets.Insert("HeaderData_", HeaderData_);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalSets, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Private

Function Note(CellDataString, CellParameters)
	
	CellParameters_ = CellParameters.Find(CellDataString.RowIndex, "RowIndex");
	
	Note = "";
	Template = Enums.BudgetingFormulaKinds.GetTemplate("FunctionDescription");
	For Each Value In Metadata.Enums.BudgetingFormulaKinds.EnumValues Do
		EnumerationValue = Enums.BudgetingFormulaKinds[Value.Name];
		FormulaName = Enums.BudgetingFormulaKinds.FunctionName(EnumerationValue);
		If StrFind(CellParameters_.Formula, FormulaName) Then
			Try
				Area = Template.GetArea(FormulaName);
			Except
				Continue;
			EndTry;
			Note = Note + Area.Area(1, 1).Text + Chars.LF;
		EndIf;
	EndDo;
	
	Note = TrimAll(Note);
	If IsBlankString(Note) Then
		Note = "-";
	EndIf;
	
	Return Note;
	
EndFunction

Procedure AddValueString(CellData_, CellDataString, ReportData, LogString, AdditionalProperties)
	
	CellParameters = AdditionalProperties.CellParameters;
	CellParameters_ = CellParameters.Find(CellDataString.RowIndex, "RowIndex");
	
	OperandName = LogString.OperandName;
	
	If LogString.StringBase = -1 Then
		
		// an undiscovered operand
		TheStructureOfTheSearch = New Structure("String, Column");
		FillPropertyValues(TheStructureOfTheSearch, CellDataString);
		
		StringsBase = AdditionalProperties.CellStructure.FindRows(TheStructureOfTheSearch);
		For Each StringBase In StringsBase Do
			CellParameter = AdditionalProperties.CellParameters.Find(StringBase.RowIndex, "RowIndex");
			If LogString.OperandName = CellParameter.OperandName Then
				Break;
			EndIf;
		EndDo;
		
		ItemKind = StringBase.OperandType;
		
		// the table cells are displayed in square brackets
		If ItemKind = Enums.FinancialReportItemKinds.TableCell Then
			OperandName = "[" + OperandName + "]";
		EndIf;
		
	Else
		
		StringBase = CellData_[LogString.StringBase];
		ItemKind = LogString.ItemKind;
		
	EndIf;
	
	If ItemKind = Enums.FinancialReportItemKinds.TableCell Then //cell reference
		OperandDescription = NStr("vi = 'Tham chiếu ô bảng';
									|ru = 'Ссылка на ячейку таблицы';
									|en = 'Reference to the table cell'; fa = 'Reference to the table cell';
									|it = 'Riferimento alla cella della tabella';
									|pl = 'Odnośnik do komórki tabeli';
									|tr = 'Hücre tablosuna bağlantı'");
		If Not ValueIsFilled(CellParameters_.OperandString) And Not ValueIsFilled(CellParameters_.OperandColumn_) Then
			AdditionalInformation_3 = "";
		Else
			AdditionalInformation_3 = "[" + 
			CellParameters_.OperandString.NameForPrinting + 
			?(ValueIsFilled(CellParameters_.OperandColumn_), "; " + 
			CellParameters_.OperandColumn_.NameForPrinting, "") + "]";
		EndIf;
	Else
		OperandDescription = String(ItemKind);
		DefiningElement = ElementThatDefinesStringValue(StringBase,
				AdditionalProperties.CellParameters,
				ItemKind);
		
		Indicators = Undefined;
		If ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem Then
			OperandDescription = OperandDescription + " """ + StringBase.BudgetBalanceItem + """";
			Indicators = FinancialReportingServerCall.ValueOfAdditionalProps(DefiningElement,
					"IndicatorValueType");
		ElsIf ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
			OperandDescription = OperandDescription + " """ + StringBase.BudgetFlowItem + """";
		Else
			OperandDescription = OperandDescription + " """ + Common.ObjectAttributeValue(
				DefiningElement, "NameForPrinting") + """";
		EndIf;
		
		If LogString.IndicatorName = "Count" Then
			IndicatorName = NStr("vi = 'Số lượng';
								|ru = 'Количество';
								|en = 'Quantity'; fa = 'مقدار';
								|it = 'Quantità';
								|pl = 'Ilość';
								|tr = 'Miktar'");
		ElsIf LogString.IndicatorName = "Value" Then
			IndicatorName = NStr("vi = 'Giá trị';
								|ru = 'Значение';
								|en = 'Value'; fa = 'مقدار';
								|it = 'Valore';
								|pl = 'Wartość';
								|tr = 'Değer'");
		ElsIf LogString.IndicatorName = "Sum" Then
			IndicatorName = NStr("vi = 'Tổng số';
								|ru = 'Сумма';
								|en = 'Amount'; fa = 'مبلغ';
								|it = 'Importo';
								|pl = 'Wartość';
								|tr = 'Tutar'");
		ElsIf CellParameters_.FlagCount Then
			IndicatorName = NStr("vi = 'Số lượng';
								|ru = 'Количество';
								|en = 'Quantity'; fa = 'مقدار';
								|it = 'Quantità';
								|pl = 'Ilość';
								|tr = 'Miktar'");
		ElsIf CellParameters_.FlagValue Then
			IndicatorName = NStr("vi = 'Giá trị';
								|ru = 'Значение';
								|en = 'Value'; fa = 'مقدار';
								|it = 'Valore';
								|pl = 'Wartość';
								|tr = 'Değer'");
		ElsIf CellParameters_.FlagSum Then
			IndicatorName = NStr("vi = 'Tổng số';
								|ru = 'Сумма';
								|en = 'Amount'; fa = 'مبلغ';
								|it = 'Importo';
								|pl = 'Wartość';
								|tr = 'Tutar'");
		Else
			Raise NStr("vi = 'Không xác định chỉ tiêu giải mã';
						|ru = 'Не определен показатель расшифровки';
						|en = 'Drill-down indicator is not defined'; fa = 'Drill-down indicator is not defined';
						|it = 'Non è stato definito l''indice della trascrizione';
						|pl = 'Nie określono odszyfrowania wskaźnika';
						|tr = 'Deşifre göstergesi belirtilmemiş'");
		EndIf;
		
		AdditionalInformation_3 = IndicatorName + ?(CellParameters_.ReverseSign, ", (-)", "");
		If Indicators <> Undefined Then
			AdditionalInformation_3 = AdditionalInformation_3 + ", " + Indicators;
		EndIf;
	EndIf;
	
	NewRow = ReportData.Add();
	NewRow.OperandName = OperandName;
	NewRow.OperandValue = LogString.Value;
	NewRow.OperandDescription = OperandDescription;
	NewRow.AdditionalInformation_3 = AdditionalInformation_3;
	
	NameOfOperandToSearch = OperandName;
	EnumerationSymbols = StrFind(NameOfOperandToSearch, " #");
	If EnumerationSymbols Then
		NameOfOperandToSearch = Mid(NameOfOperandToSearch, 1, EnumerationSymbols - 1);
	EndIf;
	
	NewRow.NumberOfTheFirstCharacter = StrFind(CellParameters_.Formula, NameOfOperandToSearch);
	NewRow.CalculationProcedure = ReportData.Count();
	
	If LogString.StringBase <> -1 Then
		NewRow.ReportParametersAddress = AdditionalProperties.ReportParametersAddress;
		NewRow.DataLineIndex = LogString.StringBase;
		NewRow.IndicatorName = LogString.IndicatorName;
	EndIf;
	
EndProcedure

Function FormulaDetails(CellDataString, CellData_, Formula, AdditionalProperties, ReportData, ColumnStructure1)
	
	CalculationLog = New Array;
	ParametersForCalculatingValue = BudgetReportingDisplayServer.TemplateForCellValueCalculationParameters();
	ParametersForCalculatingValue.CellData_ = CellData_;
	ParametersForCalculatingValue.CellParameters = AdditionalProperties.CellParameters;
	ParametersForCalculatingValue.PeriodParameters_1 =
		BudgetReportingDisplayServer.ConvertDataParametersToPeriodData(ColumnStructure1, AdditionalProperties);
	ParametersForCalculatingValue.DataString1 = CellDataString;
	ParametersForCalculatingValue.Prefix = AdditionalProperties.IndicatorName;
	ParametersForCalculatingValue.CalculatingChanges = False;
	ParametersForCalculatingValue.CacheOfBudgetItemDetails = Undefined;
	CalculationValue = BudgetReportingDisplayServer.CalculateCellValue(ParametersForCalculatingValue, CalculationLog);
	
	CalculatedFormula = Formula;
	
	CheckingUniquenessOfOperands = New ValueTable;
	CheckingUniquenessOfOperands.Columns.Add("ItemKind");
	CheckingUniquenessOfOperands.Columns.Add("OperandName");
	CheckingUniquenessOfOperands.Columns.Add("IndicatorName");
	CheckingUniquenessOfOperands.Columns.Add("StringBase");
	CheckingUniquenessOfOperands.Columns.Add("Value");
	
	SearchForUniqueness = New Structure("ItemKind, OperandName, IndicatorName, StringBase, Value");
	
	ArrayOfValues = New Array;
	For Each LogString In CalculationLog Do
		FillPropertyValues(SearchForUniqueness, LogString);
		If CheckingUniquenessOfOperands.FindRows(SearchForUniqueness).Count() > 0 Then
			// The same operand can be calculated when calculating the derived exponent and when calculating the aggregate function
			Continue;
		Else
			UniquenessString = CheckingUniquenessOfOperands.Add();
			FillPropertyValues(UniquenessString, SearchForUniqueness);
		EndIf;
		ArrayOfValues.Add(LogString.Value);
		If Not TypeOf(LogString.Value) = Type("Array") Then //the value is taken into account in other records
			AddValueString(CellData_, CellDataString, ReportData, LogString, AdditionalProperties);
			ValueForFormula = LogString.Value;
		Else
			ValueForFormula = StrConcat(LogString.Value, "; ");
		EndIf;
		OperandName = "[" + LogString.OperandName + "]";
		CalculatedFormula = StrReplace(CalculatedFormula, OperandName, ValueForFormula);
	EndDo;
	
	If StrFind(CalculatedFormula, "ArrayOfValues") Then
		Presentation = StrConcat(ArrayOfValues, "; ");
		CalculatedFormula = StrReplace(CalculatedFormula, "ArrayOfValues", Presentation);
	EndIf;
	
	Return New Structure("Calculation, Result", CalculatedFormula, CalculationValue);
	
EndFunction

Function ReportParameters(ReportParameters)
	
	Result = NStr("vi = 'Đầu kỳ: %1%2 Cuối kỳ: %3%4Ngày thiết thực: %5';
					|ru = 'Начало периода: %1%2Окончание периода: %3%4Дата актуальности: %5';
					|en = 'Period start: %1%2Period end: %3%4Relevance date: %5'; fa = 'Period start: %1%2Period end: %3%4Relevance date: %5';
					|it = 'Inizio del periodo: %1%2 Fine del periodo: %3%4Data di rilevanza: %5';
					|pl = 'Początek okresu: %1%2Koniec okresu: %3%4Data przydatności do użycia: %5';
					|tr = 'Dönem başı: %1%2Dönem sonu: %3%4Geçerlilik tarihi: %5'");
	Result = StringFunctionsClientServer.SubstituteParametersToString(Result, 
			Format(ReportParameters.BeginOfPeriod, "DLF=D"), Chars.LF, 
			Format(ReportParameters.EndOfPeriod, "DLF=D"), Chars.LF,
			Format(ReportParameters.UpdateDate, "DLF=D"));
		
	Return Result;
	
EndFunction

Function Formula(CellDataString, CellParameters)
	
	CellParameters_ = CellParameters.Find(CellDataString.RowIndex, "RowIndex");
	Result = CellParameters_.FormulaPresentation;
	If IsBlankString(Result) Then
		Result = CellParameters_.Formula;
	EndIf;
	ReplacementValue = NStr("vi = '[Ячейки группы]';
							|ru = '[Ячейки группы]';
							|en = '[Group cells]'; fa = '[Group cells]';
							|it = '[Cella del gruppo]';
							|pl = '[Komórki grupy]';
							|tr = '[Hücre grubu]'");
	ReplacementValue = " " + ReplacementValue + " ";
	Result = StrReplace(Result, "ArrayOfValues", ReplacementValue);
	
	ConvertedFormula = "";
	ReplaceSquareBrackets = False;
	For Cnt = 1 To StrLen(Result) Do
		If StrFind(Result, "TOTAL",, Cnt) = Cnt Then
			ReplaceSquareBrackets = True;
		EndIf;
		Char = Mid(Result, Cnt, 1);
		If ReplaceSquareBrackets Then
			If Char = "[" Or Char = "]" Then
				Char = """";
			EndIf;
			If Char = "," Then
				ReplaceSquareBrackets = False;
			EndIf;
		EndIf;
		ConvertedFormula = ConvertedFormula + Char;
	EndDo;
	
	Return ConvertedFormula;
	
EndFunction

Function SelectionAndGrouping(CellData_, AdditionalProperties)
	
	StructureOfReportDescription = BudgetReportingCacheCalculationServer.ColumnsOfDataTable_(
		AdditionalProperties.BudgetProfile);
	
	Groups = "";
	For Each Dimension In StructureOfReportDescription.Dimensions Do
		If ValueIsFilled(CellData_[Dimension]) Then
			Groups = Groups + Dimension + ": " + CellData_[Dimension] + Chars.LF;
		EndIf;
	EndDo;
	
	For Each Dimension In StructureOfReportDescription.DimensionKinds Do
		KindName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		If ValueIsFilled(CellData_[KindName]) Then
			Groups = Groups + Dimension + ": " + CellData_[KindName] + Chars.LF;
		EndIf;
	EndDo;
	
	OrderedPeriodicities = Enums.Periodicity.OrderedPeriodicities();
	For Each Periodicity In OrderedPeriodicities Do
		If StructureOfReportDescription.Periodicity_.Find(Periodicity) <> Undefined Then
			PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
			Value = CellData_[PeriodName];
			If ValueIsFilled(Value) Then
				PeriodPresentation = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(Value, Periodicity);
				GroupingPeriod = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Kỳ: %1';
						|ru = 'Период: %1';
						|en = 'Period: %1'; fa = 'Period: %1';
						|it = 'Periodo:%1';
						|pl = 'Okres: %1';
						|tr = 'Dönem: %1'"),
					PeriodPresentation);
				Groups = Groups + GroupingPeriod + Chars.LF;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Groups = TrimAll(Groups);
	
	Return TrimAll(Groups);
	
EndFunction


// LongDesc
// 
// Parameters:
// 	CellDataString - ValueTableRow -:
// 	 *String - CatalogRef.FinancialReportItems - Budget line.
// 	 *Column - CatalogRef.FinancialReportItems - Column of the budget.
// 	CellParameters - ValueTable - LongDesc
// 	ItemKind - EnumRef.FinancialReportItemKinds - LongDesc
// Returns:
// 	CatalogRef.FinancialReportItems -
Function ElementThatDefinesStringValue(CellDataString, CellParameters, ItemKind)
	
	CellParameters_ = CellParameters.Find(CellDataString.RowIndex, "RowIndex");
	
	If Not CellParameters_.TableComplex_ Then
		
		If Common.ObjectAttributeValue(CellDataString.String, "ItemKind") = ItemKind Then
			Return CellDataString.String;
		Else
			Return CellDataString.Column;
		EndIf;
		
	Else
		
		TypeOfElementString = Common.ObjectAttributeValue(CellDataString.String, "ItemKind");
		TypeOfColumnElement = Common.ObjectAttributeValue(CellDataString.Column, "ItemKind");
		If TypeOfElementString = Enums.FinancialReportItemKinds.GroupFormula Then
			Return CellDataString.String;
		ElsIf TypeOfColumnElement = Enums.FinancialReportItemKinds.GroupFormula Then
			Return CellDataString.Column;
		EndIf;
		
		If TypeOfElementString = Enums.FinancialReportItemKinds.Group Then
			Return CellDataString.String;
		ElsIf TypeOfColumnElement = Enums.FinancialReportItemKinds.Group Then
			Return CellDataString.Column;
		EndIf;
		
		Query = New Query;
		Query.Text = "SELECT
		|	CAST(&String AS Catalog.FinancialReportItems).Owner AS BudgetProfile,
		|	&String AS String,
		|	&Column AS Column
		|INTO Filter
		|
		|INDEX BY
		|	BudgetProfile,
		|	String,
		|	Column
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FinancialReportItemsTableItems.Item AS Item,
		|	FinancialReportItems.NameForPrinting AS NameForPrinting
		|FROM
		|	Catalog.FinancialReportItems AS FinancialReportItems
		|		INNER JOIN Catalog.FinancialReportItems.TableItems AS FinancialReportItemsTableItems
		|		ON FinancialReportItems.Ref = FinancialReportItemsTableItems.Ref
		|		INNER JOIN Filter AS Filter
		|		ON FinancialReportItems.Owner = Filter.BudgetProfile
		|			AND (FinancialReportItemsTableItems.String = Filter.String)
		|			AND (FinancialReportItemsTableItems.Column = Filter.Column)";
		
		Query.SetParameter("String", CellDataString.String);
		Query.SetParameter("Column", CellDataString.Column);
		Selection = Query.Execute().Select();
		Selection.Next();
		
		Return Selection.Item;
	EndIf;
	
EndFunction

Function DerivedExponentName(CellDataString, CellParameters)
	
	Item = ElementThatDefinesStringValue(
		CellDataString,
		CellParameters, 
		Enums.FinancialReportItemKinds.DerivedItem);
	
	Return Common.ObjectAttributeValue(Item, "NameForPrinting");
	
EndFunction

#EndRegion

#EndIf


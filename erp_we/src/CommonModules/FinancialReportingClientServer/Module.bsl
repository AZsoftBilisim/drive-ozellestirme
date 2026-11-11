

#Region Public

// Returns the structure of parameter values for substitution in text fields used in financial reports.
//
// Parameters:
//  ExcludingBrackets - Boolean - If true, the parameter name and representation will be omitted from the bounding square brackets.
//  		The default value is False. 
//  LanguageCode - String - Language code. By default, an empty string corresponds to the language of the current user.
//  		Set if you need to get a view for a specific language, for example, for the main configuration language.
//
// Returns:
//  Structure - Structure of parameters used in financial statements:
//   * ReportSet - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     ** Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     ** Presentation - String - The representation of a variable can be enclosed in square brackets.
//   * ReportKind - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     ** Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     ** Presentation - String - The representation of a variable can be enclosed in square brackets.
//   * CurrentDateAndTime - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     ** Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     ** Presentation - String - The representation of a variable can be enclosed in square brackets.
//   * ReportingPeriod - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     ** Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     ** Presentation - String - The representation of a variable can be enclosed in square brackets.
//   * EndDateOfReportPeriod - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     ** Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     ** Presentation - String - The representation of a variable can be enclosed in square brackets.
//   * Organization - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     ** Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     ** Presentation - String - The representation of a variable can be enclosed in square brackets./
//
Function FinancialStatementVariables(ExcludingBrackets = False, LanguageCode = "") Export
	
	Result = New Structure;
	
	VariableTemplate = ?(ExcludingBrackets, "%1", "[%1]");
	
	
	VariableName = "ReportSet";
	Name = StrTemplate(VariableTemplate, VariableName);
	VariablePresentation = NStr("vi = 'Tập hợp báo cáo';
								|ru = 'Комплект отчетов';
								|en = 'Report set'; fa = 'Report set';
								|it = 'Set di report';
								|pl = 'Komplet raportów';
								|tr = 'Rapor seti'", LanguageCode);
	MeaningAndPresentation = VariableDescription(Name, VariablePresentation);
	Result.Insert(VariableName, MeaningAndPresentation);
	
	
	VariableName = "ReportKind";
	Name = StrTemplate(VariableTemplate, VariableName);
	VariablePresentation = NStr("vi = 'Dạng báo cáo';
								|ru = 'Вид отчета';
								|en = 'Report kind'; fa = 'نوع گزارش';
								|it = 'Tipo di report';
								|pl = 'Rodzaj raportu';
								|tr = 'Rapor türü'", LanguageCode);
	MeaningAndPresentation = VariableDescription(Name, VariablePresentation);
	Result.Insert(VariableName, MeaningAndPresentation);
	
	
	VariableName = "CurrentDateAndTime";
	Name = StrTemplate(VariableTemplate, VariableName);
	VariablePresentation = NStr("vi = 'Ngày giờ hiện tại';
								|ru = 'Текущая дата и время';
								|en = 'Current date and time'; fa = 'Current date and time';
								|it = 'Data e ora correnti';
								|pl = 'Bieżąca data i godzina';
								|tr = 'Mevcut tarih ve zaman'", LanguageCode);
	MeaningAndPresentation = VariableDescription(Name, VariablePresentation);
	Result.Insert(VariableName, MeaningAndPresentation);
	
	
	VariableName = "ReportingPeriod";
	Name = StrTemplate(VariableTemplate, VariableName);
	VariablePresentation = NStr("vi = 'Kỳ báo cáo';
								|ru = 'Период отчетности';
								|en = 'Reporting period'; fa = 'Reporting period';
								|it = 'Periodo di rendicontazione';
								|pl = 'Okres rozliczeniowy';
								|tr = 'Hesap dönemi'", LanguageCode);
	MeaningAndPresentation = VariableDescription(Name, VariablePresentation);
	Result.Insert(VariableName, MeaningAndPresentation);
	
	
	VariableName = "EndDateOfReportPeriod";
	Name = StrTemplate(VariableTemplate, VariableName);
	VariablePresentation = NStr("vi = 'Ngày kết thúc kỳ báo cáo';
								|ru = 'Конечная дата периода отчета';
								|en = 'End date of report period'; fa = 'End date of report period';
								|it = 'Data conclusiva del periodo del report';
								|pl = 'Data końcowa okresu raportu';
								|tr = 'Rapor döneminin son tarihi'", LanguageCode);
	MeaningAndPresentation = VariableDescription(Name, VariablePresentation);
	Result.Insert(VariableName, MeaningAndPresentation);
	
	
	VariableName = "Organization";
	Name = StrTemplate(VariableTemplate, VariableName);
	VariablePresentation = NStr("vi = 'Doanh nghiệp';
								|ru = 'Организация';
								|en = 'Company'; fa = 'Company';
								|it = 'Azienda';
								|pl = 'Firma';
								|tr = 'İş yeri'", LanguageCode);
	MeaningAndPresentation = VariableDescription(Name, VariablePresentation);
	Result.Insert(VariableName, MeaningAndPresentation);
	
	
	Return Result;
	
EndFunction

// Returns:
//  Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//  * Name   - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//  * Presentation - String - representation of the argument.
// 
Function VariableDescription(Name = "", Presentation = "")
	Return New Structure("Name, Presentation", Name, Presentation);
EndFunction

// Returns an ordered array of values to substitute variables into text fields that are used in the financial statements.
//
// Parameters:
//  LanguageCode         - String       - Language code. By default, an empty string corresponds to the language of the current user.
//                                    Set if you need to get a view for a specific language, for example, for the main configuration language.
//
// Returns:
//  Array of Structure - An ordered array of parameters used in financial reports for substitution in text fields:
//   *Name - String - Parameter ID. Not localized, stored in a database.
//   *Presentation - String - representation of the argument.
//
Function OrderedVariablesOfFinancialStatements(LanguageCode = "") Export
	
	Result = New Array;
	
	ReportVariables = FinancialStatementVariables(True, LanguageCode);
	
	MeaningAndPresentation = VariableDescription(ReportVariables.ReportSet.Name,
		ReportVariables.ReportSet.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = VariableDescription(ReportVariables.ReportKind.Name,
		ReportVariables.ReportKind.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = VariableDescription(ReportVariables.CurrentDateAndTime.Name,
		ReportVariables.CurrentDateAndTime.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = VariableDescription(ReportVariables.ReportingPeriod.Name,
		ReportVariables.ReportingPeriod.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = VariableDescription(ReportVariables.EndDateOfReportPeriod.Name,
		ReportVariables.EndDateOfReportPeriod.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = VariableDescription(ReportVariables.Organization.Name,
		ReportVariables.Organization.Presentation);
	Result.Add(MeaningAndPresentation);
	
	Return Result;
	
EndFunction

// Retrieves the period rows by the enumeration value.
// 
// Parameters:
// 	Period - EnumRef.Periodicity
// Returns:
// 	Structure - various Presentations period string, contains fields:
// 	 * Period - String - "Period" + period
// 	 * PeriodExpression - String - "Period Expression" + period
// 	 * FlagPeriod - String - "FlagPeriod" + period.
// 	 * ReportPeriod_ - String - "Period" + period + " Report"
// 	 * PeriodConnection - String - "Period" + period + " Connection"
//
Function PeriodStrings(Period) Export
	
	ReturnStructure = New Structure("Period, ReportPeriod_, PeriodConnection, PeriodExpression, FlagPeriod");
	
	If Not ValueIsFilled(Period) Then
		ReturnStructure.Period = "Period";
		ReturnStructure.ReportPeriod_ = "ReportPeriod_";
		ReturnStructure.PeriodConnection = "PeriodConnection";
		ReturnStructure.PeriodExpression = "PeriodExpression";
		ReturnStructure.FlagPeriod = "FlagPeriod";
	ElsIf Period = PredefinedValue("Enum.Periodicity.Day") Then
		ReturnStructure.Period = "DayPeriod";
		ReturnStructure.ReportPeriod_ = "PeriodDayReport";
		ReturnStructure.PeriodConnection = "PeriodDayConnection";
		ReturnStructure.PeriodExpression = "DayPeriodExpression";
		ReturnStructure.FlagPeriod = "FlagDayPeriod";
	ElsIf Period = PredefinedValue("Enum.Periodicity.Week") Then
		ReturnStructure.Period = "WeekPeriod";
		ReturnStructure.ReportPeriod_ = "PeriodicReport";
		ReturnStructure.PeriodConnection = "PeriodWeekConnection";
		ReturnStructure.PeriodExpression = "WeekPeriodExpression";
		ReturnStructure.FlagPeriod = "FlagWeekPeriod";
	ElsIf Period = PredefinedValue("Enum.Periodicity.TenDays") Then
		ReturnStructure.Period = "TenDaysPeriod";
		ReturnStructure.ReportPeriod_ = "PeriodDecadeReport";
		ReturnStructure.PeriodConnection = "PeriodDecadeConnection";
		ReturnStructure.PeriodExpression = "DecadePeriodExpression";
		ReturnStructure.FlagPeriod = "FlagTenDaysPeriod";
	ElsIf Period = PredefinedValue("Enum.Periodicity.Month") Then
		ReturnStructure.Period = "MonthPeriod";
		ReturnStructure.ReportPeriod_ = "PeriodMonthReport";
		ReturnStructure.PeriodConnection = "PeriodMonthConnection";
		ReturnStructure.PeriodExpression = "PeriodExpressionMonth";
		ReturnStructure.FlagPeriod = "FlagMonthPeriod";
	ElsIf Period = PredefinedValue("Enum.Periodicity.Quarter") Then
		ReturnStructure.Period = "QuarterPeriod";
		ReturnStructure.ReportPeriod_ = "PeriodQuarterReport";
		ReturnStructure.PeriodConnection = "PeriodicConnection";
		ReturnStructure.PeriodExpression = "PeriodExpressionQuarter";
		ReturnStructure.FlagPeriod = "FlagQuarterPeriod";
	ElsIf Period = PredefinedValue("Enum.Periodicity.HalfYear") Then
		ReturnStructure.Period = "HalfYearPeriod";
		ReturnStructure.ReportPeriod_ = "PeriodHalfYearReport";
		ReturnStructure.PeriodConnection = "PeriodHalfYear";
		ReturnStructure.PeriodExpression = "ExpressionOfPeriodHalfYear";
		ReturnStructure.FlagPeriod = "FlagHalfYearPeriod";
	ElsIf Period = PredefinedValue("Enum.Periodicity.Year") Then
		ReturnStructure.Period = "YearPeriod";
		ReturnStructure.ReportPeriod_ = "PeriodYearReport";
		ReturnStructure.PeriodConnection = "AnnualPeriod";
		ReturnStructure.PeriodExpression = "ExpressionOfPeriodYear";
		ReturnStructure.FlagPeriod = "FlagYearPeriod";
	Else
		Raise NStr("vi = 'Giá trị liệt kê không xác định:';
					|ru = 'Неизвестное значение перечисления:';
					|en = 'Unknown enumeration value:'; fa = 'Unknown enumeration value:';
					|it = 'Valore enumerazione sconosciuto:';
					|pl = 'Nieznana wartość przelewu:';
					|tr = 'Bilinmeyen transfer değeri:'") + " " + Period
	EndIf;
	
	Return ReturnStructure;
		
EndFunction

// Returns the periodicity of the string expression of the period
//
// Parameters:
//  PeriodString - String - String expression of the period
//
// Returns:
//    EnumRef.Periodicity - Periodicity
//
Function PeriodicityByPeriodString(PeriodString) Export
	
	Periodicity = PredefinedValue("Enum.Periodicity.EmptyRef");
	
	If PeriodString = "DayPeriod" Then
		Periodicity = PredefinedValue("Enum.Periodicity.Day");
	ElsIf PeriodString = "WeekPeriod" Then
		Periodicity = PredefinedValue("Enum.Periodicity.Week");
	ElsIf PeriodString = "TenDaysPeriod" Then
		Periodicity = PredefinedValue("Enum.Periodicity.TenDays");
	ElsIf PeriodString = "MonthPeriod" Then
		Periodicity = PredefinedValue("Enum.Periodicity.Month");
	ElsIf PeriodString = "QuarterPeriod" Then
		Periodicity = PredefinedValue("Enum.Periodicity.Quarter");
	ElsIf PeriodString = "HalfYearPeriod" Then
		Periodicity = PredefinedValue("Enum.Periodicity.HalfYear");
	ElsIf PeriodString = "YearPeriod" Then
		Periodicity = PredefinedValue("Enum.Periodicity.Year");
	EndIf;
	
	Return Periodicity;
	
EndFunction

// Returns the index of the new row based on the presence of the Totalgroup report item in the collection.
//
//	Parameters:
//		TreeRows - FormDataTreeItemCollection - a collection of rows where you need to define the index for inserting a new row.
//
//	Returns:
//		Number - index for inserting a new line.
//
Function IndexOfNewRow(TreeRows) Export
	
	IndexOf = -1;
	For Each TreeRow In TreeRows Do
		
		If TreeRow.ItemKind = ItemKind("TotalByGroup")
			And Not TreeRow.ThisIsReference Then
			IndexOf = TreeRows.IndexOf(TreeRow);
			Break;
		EndIf;
		
	EndDo;
	
	If IndexOf = -1 Or IndexOf = 0 And TreeRows.Count() > 1 Then
		IndexOf = TreeRows.Count();
	EndIf;
	
	Return IndexOf;
	
EndFunction

// The procedure fills in a row in the list or tree of report elements
// with additional details.
//
// Parameters:
//  Parameters - Structure - structure fields:
//		Source - structure - source of filling 
//		The receiver string is the data form of the tree string - the string that we fill in
//		Addresselement Storage - string - address of the element storage
//		The Data FormCollection field is used to search for a string if the receiver is the string ID.
//
Procedure FillInTreeLine(Parameters) Export
	
	Source = Parameters.Source;
	DestinationRow = Parameters.DestinationRow;
	ItemAddressInStorage = Parameters.ItemAddressInStorage;
	AdditionalLineDetails_ = Parameters.AdditionalLineDetails_;
	Field = Parameters.Field;
	
	If Source = Undefined Then
		Return;
	EndIf;
	
	// The form returns the current details
	If TypeOf(DestinationRow) = Type("Number") Then
		DestinationRow = Field.FindByID(DestinationRow);
	EndIf;
	
	FillPropertyValues(DestinationRow, Source);
	
	If Not ValueIsFilled(ItemAddressInStorage) Then
		AddAttributes = FinancialReportingServerCall.AdditionalAttributesValues(
							Source,
							AdditionalLineDetails_);
	Else
		// But the actual values of the additional details are generated on the server
		// in the pre-recording server, respectively, they are in the storage.
		AddAttributes = FinancialReportingServerCall.AdditionalAttributesValues(
							ItemAddressInStorage,
							AdditionalLineDetails_);
	EndIf;
	
	FillPropertyValues(DestinationRow, AddAttributes);
	If ValueIsFilled(Source.LinkedItem1) Then
		AddAttributes = FinancialReportingServerCall.AdditionalAttributesValues(
							Source.LinkedItem1,
							Parameters.AdditionalLineDetails_);
		FillPropertyValues(DestinationRow, AddAttributes,,"ReportRowCode,Note");
		
	ElsIf DestinationRow.ItemKind = ItemKind("MonetaryIndicator") Then
		DestinationRow.AccountIndicatorDimension = DestinationRow.GLAccount_;
		
	ElsIf DestinationRow.ItemKind = ItemKind("NonMonetaryItem") Then
		DestinationRow.AccountIndicatorDimension = AddAttributes.NonMonetaryItem;
		
	EndIf;
	
EndProcedure

// The function returns the structure of details for placing in temporary storage
// 
// Returns:
// 	Structure - structure with properties:
// 	*ValueSources - ValueTable -:
// 	  **Source - CatalogRef.FinancialReportItems -
// 	  **AddedDocumentValues - Boolean -
// 	*DrillDownOfAppearanceItemFilterFields - ValueTable -:
// 	  **ReportItem - CatalogRef.FinancialReportItems -
// 	  **AppearanceItemKey - UUID - 
// 	  **FilterFieldName - String - 
// 	  **ResourceName - String -
// 	*DesigningColumns - ValueTable -:
// 	  **ReportItem - CatalogRef.FinancialReportItems -
// 	  **AppearanceItemKey - UUID -
// 	*RegisteredRows  - ValueTable -:
// 	  **ReportItem - CatalogRef.FinancialReportItems -
// 	  **AppearanceItemKey - UUID - 
// 	*AppearanceItems - ValueTable -:
// 	  **Appearance - ValueStorage -
// 	  **Condition - ValueStorage -
// 	  **CreatedAreaType - EnumRef.DesignedAreaTypesOfBudgetReports -
// 	  **AppearanceItemKey - UUID - 
// 	*AdditionalFields - ValueTable -:
// 	  **Attribute - String -
// 	  **Description - String - 
// 	  **TitleOutput - Boolean - 
// 	  **InSeparateColumn - Boolean -
// 	*TableItems - ValueTable -:
// 	  **String - CatalogRef.FinancialReportItems -
// 	  **Column - CatalogRef.FinancialReportItems -
// 	  **Item - CatalogRef.FinancialReportItems -
// 	*FormulaOperands - ValueTable - table of operands of the formula:
// 	  **Id - String - 
// 	  **Operand - CatalogRef.FinancialReportItems -
// 	*ItemKindAttributes - ValueTable -:
// 	  **Attribute - ChartOfCharacteristicTypesRef.ItemAttributesOfFinancialReports -
// 	  **Value - Characteristic.ItemAttributesOfFinancialReports -
// 	*LinkedItem1 - CatalogRef.FinancialReportItems -
// 	*DimensionValue - Characteristic.BudgetFlowItemDimensions -
// 	*HasSettings - Boolean -
// 	*AdditionalSelection - ValueStorage -
// 	*Comment - String -
// 	*ReverseSign - Boolean -
// 	*NameForPrinting - String -
// 	*ItemKind - EnumRef.FinancialReportItemKinds -
// 	*Code - Number -
// 	*Description - Undefined -
// 	*Owner - CatalogRef.BudgetProfiles -
// 				- CatalogRef.FinancialReportTypes - 
// 	*Ref - CatalogRef.FinancialReportItems -
//  * Accuracy - Number -
//
Function ReportElementStructure() Export
	
	Result = New Structure;
	// Standard banking details
	Result.Insert("Ref");
	Result.Insert("Owner");
	Result.Insert("Description");
	Result.Insert("Code");
	
	//Attributes
	Result.Insert("ItemKind");
	Result.Insert("NameForPrinting");
	Result.Insert("ReverseSign");
	Result.Insert("Comment");
	Result.Insert("AdditionalSelection");
	Result.Insert("HasSettings");
	Result.Insert("DimensionValue");
	Result.Insert("LinkedItem1");
	
	// Table parts
	Result.Insert("ItemKindAttributes");
	Result.Insert("FormulaOperands");
	Result.Insert("TableItems");
	Result.Insert("AdditionalFields");
	Result.Insert("CalculationsRules");
	Result.Insert("AppearanceItems");
	Result.Insert("RegisteredRows");
	Result.Insert("DesigningColumns");
	Result.Insert("DrillDownOfAppearanceItemFilterFields");
	Result.Insert("ValueSources");
	
	Return Result;
	
EndFunction

// Returns the parent of the passed string, depending on the type.
//
//	Parameters:
//		TreeRow - FormDataTreeItem, ValueTreeRow - a row in the report item tree.
//
//	Returns:
//		FormDataTreeItem - Parent of the string,
//		The assignment string is the parent of the string.
//
Function RowParent(TreeRow) Export
	
	If TypeOf(TreeRow) = Type("FormDataTreeItem")
		Or TypeOf(TreeRow) = Type("FormDataTree") Then
		RowParent = TreeRow.GetParent();
	Else
		RowParent = TreeRow.Parent;
	EndIf;
	
	Return RowParent;
	
EndFunction

#EndRegion

#Region Private

Function ItemKind(ElementTypeName)
	
	Return PredefinedValue("Enum.FinancialReportItemKinds."+ElementTypeName);
	
EndFunction

#EndRegion

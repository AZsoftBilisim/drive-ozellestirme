#Region Public

// Creates a repository with the standard structure
// of a budget report element based on a link or line
// in the budget view.
//
// Parameters:
//  Item  - FormDataTreeItem, CatalogRef.FinancialReportItems - value to put
//  StorageAddress - UUID - MIA in the form of the budget.
//
// Returns:
//  String - Address in the store
//
Function PlaceItemInStorage(Item, StorageAddress) Export
	
	PeriodVariables = VariablesOfBudgetingPeriods(); // See VariablesOfBudgetingPeriods
	
	// If we form a repository based on a string 
	// , then we form it by element, if there is, otherwise by the string itself.
	If TypeOf(Item) = Type("FormDataTreeItem")
		Or TypeOf(Item) = Type("FormDataCollectionItem")
		Or TypeOf(Item) = Type("ValueTreeRow") Then
		
		If ValueIsFilled(Item.ReportItem) Then
			
			Return FinancialReportingServerCall.PlaceItemInStorage(Item.ReportItem, StorageAddress);
			
		Else
			
			Prefix = "AdditionalAttribute_";
			
			ElementStructure = FinancialReportingClientServer.ReportElementStructure();
			FillPropertyValues(ElementStructure, Item);
			
			If ElementStructure.ItemKind = ItemKind("BudgetFlowItem")
				Or ElementStructure.ItemKind = ItemKind("AllBudgetFlowItems") Then
				
				ElementStructure.Insert(Prefix + "BudgetFlowItem", Item.ItemIndicatorDimensionType);
				ElementStructure.Insert(Prefix + "DisplayedIndicators", Item.DisplayedIndicators);
				
				ElementStructure.Insert(Prefix + "OffsetFrequency", PredefinedValue("Enum.Periodicity.Year"));
				ElementStructure.Insert(Prefix + "LowerBoundOfData", PeriodVariables.DataPeriodStart.Name);
				ElementStructure.Insert(Prefix + "UpperBoundOfData", PeriodVariables.DataPeriodEnd.Name);
				ElementStructure.Insert(Prefix + "GroupingPeriodStart", PeriodVariables.PeriodOfGrouping.Name);
				ElementStructure.Insert(Prefix + "GroupingPeriodEnd", PeriodVariables.PeriodOfGrouping.Name);
				
			ElsIf ElementStructure.ItemKind = ItemKind("BudgetBalanceItem")
				Or ElementStructure.ItemKind = ItemKind("AllBudgetBalanceItems") Then
				
				ElementStructure.Insert(Prefix + "BudgetBalanceItem", Item.ItemIndicatorDimensionType);
				ElementStructure.Insert(Prefix + "DisplayedIndicators", Item.DisplayedIndicators);
				ElementStructure.Insert(Prefix + "IndicatorValueType", Item.IndicatorValueType);
				
				ElementStructure.Insert(Prefix + "OffsetFrequency", PredefinedValue("Enum.Periodicity.Year"));
				ElementStructure.Insert(Prefix + "LowerBoundOfData", PeriodVariables.DataPeriodStart.Name);
				ElementStructure.Insert(Prefix + "UpperBoundOfData", PeriodVariables.DataPeriodEnd.Name);
				ElementStructure.Insert(Prefix + "GroupingPeriodStart", PeriodVariables.PeriodOfGrouping.Name);
				ElementStructure.Insert(Prefix + "GroupingPeriodEnd", PeriodVariables.PeriodOfGrouping.Name);
				
			ElsIf ElementStructure.ItemKind = ItemKind("NonFinancialItem") Then
				
				ElementStructure.Insert(Prefix + "NonFinancialItem", Item.ItemIndicatorDimensionType);
				ElementStructure.Insert(Prefix + "OffsetFrequency", PredefinedValue("Enum.Periodicity.Year"));
				
			ElsIf ElementStructure.ItemKind = ItemKind("EditedValue") Then
				
				ElementStructure.Insert(Prefix + "EditedValueType", "Number");
				
			ElsIf ElementStructure.ItemKind = ItemKind("GroupFormula") Then
				
				ElementStructure.Insert(Prefix + "GroupFormula", PredefinedValue("Enum.BudgetingFormulaKinds.Sum"));
				
			ElsIf ElementStructure.ItemKind = ItemKind("Group") Then
				
				ElementStructure.Insert(Prefix + "DisplayItemTitle", True);
				
			ElsIf ElementStructure.ItemKind = ItemKind("DerivedItem") Then
				
				ElementStructure.Insert(Prefix + "Formula", "");
				
			ElsIf ElementStructure.ItemKind = ItemKind("Dimension") Then
				
				DimensionType = DetermineMeasurementTypeByValueType(Item.ItemIndicatorDimensionType, Item);
				ElementStructure.Insert(Prefix + "DimensionType", DimensionType);
				If DimensionType = DimensionType("RegisterDimension") Then
					ElementStructure.Insert(Prefix + "DimensionName", Item.ItemIndicatorDimensionType);
				ElsIf DimensionType = DimensionType("Period") Then
					ElementStructure.Insert(Prefix + "Periodicity", Item.ItemIndicatorDimensionType);
					ElementStructure.Insert(Prefix + "PeriodValue", Item.DimensionValue);
				ElsIf DimensionType = DimensionType("FixedDimension") Then
					ElementStructure.Insert(Prefix + "DimensionKind", Item.ItemIndicatorDimensionType);
					ElementStructure.Insert(Prefix + "ThisIsDimensionOther", Item.ThisIsDimensionOther);
				ElsIf DimensionType = DimensionType("Dimension") Then
					ElementStructure.Insert(Prefix + "DimensionKind", Item.ItemIndicatorDimensionType);
				ElsIf DimensionType = DimensionType("Scenario") Then
					ElementStructure.Insert(Prefix + "Scenario", Item.ItemIndicatorDimensionType);
				ElsIf DimensionType = DimensionType("Currency") Then
					ElementStructure.Insert(Prefix + "Currency", Item.ItemIndicatorDimensionType);
				ElsIf DimensionType = DimensionType("Organization") Then
					ElementStructure.Insert(Prefix + "Organization", Item.ItemIndicatorDimensionType);
				ElsIf DimensionType = DimensionType("Department") Then
					ElementStructure.Insert(Prefix + "Department", Item.ItemIndicatorDimensionType);
				EndIf;
				
			EndIf;
			
			Return FinancialReportingServerCall.PlaceItemInStorage(ElementStructure, StorageAddress);
			
		EndIf;
	Else
		Return FinancialReportingServerCall.PlaceItemInStorage(Item, StorageAddress);
	EndIf;
	
EndFunction

#Region Localization

// Returns a string representation of an empty dimension (Analytics view).
//
// Parameters:
//  MeasurementViewAnalytics - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//  						- String - Measurement. For example, "Organization" or "Division".
//  Mode - String - Mode for getting an analytics view.
//  				The values:
//  					"Other" are available - For example, <other organizations>.
//  					"All" - For example, <all organizations>.
//  					"Addable and other" - For example, <addable and other organizations>.
//  PresentationOfAnalyticsViewDimension - String - String representation of the type of analysis or dimension.
//  			For a dimension, a representation in a localized format.
//  			For the type of analysis - the name of the type of analysis.
//  										- Undefined - The default value. The view is determined by accessing the database.
//  CacheOfSubmittedInformation - Map of KeyAndValue - Match, where the key is the type of analysis or the string is the name of the dimension. Value-representation of an empty value, for example <other organizations>.
//  					- Undefined - The view cache is not set.
//  LanguageCode - String - Language code. By default, an empty string corresponds to the language of the current user.
//  			Set if you need to get a view for a specific language, for example, for the main configuration language.
//
// Returns:
//  String - representation of an empty dimension (type of analytics), for example, "<other DDS articles>".
//
Function PresentationOfOtherBudgetingAnalytics(MeasurementViewAnalytics, Mode, PresentationOfAnalyticsViewDimension = Undefined, CacheOfSubmittedInformation = Undefined, LanguageCode = "") Export
	PresentationOfEmptyValue = Undefined;
	
	If MeasurementViewAnalytics = Undefined Then
		PresentationOfEmptyValue = "";
		Return PresentationOfEmptyValue;
	EndIf;
	If Not CacheOfSubmittedInformation = Undefined Then
		PresentationOfEmptyValue = CacheOfSubmittedInformation.Get(MeasurementViewAnalytics);
	EndIf;
	
	If PresentationOfEmptyValue = Undefined Then
		ThisIsNumberedAnalytics = False;
		If PresentationOfAnalyticsViewDimension = Undefined Then
			If TypeOf(MeasurementViewAnalytics) = Type("String") Then
				PresentationsOfNumberedAnalytics = PresentationsOfNumberedAnalytics(LanguageCode);
				PresentationOfNumberedAnalytics = PresentationsOfNumberedAnalytics.Get(MeasurementViewAnalytics);
				
				If MeasurementViewAnalytics = "Organization" Then
					PresentationOfAnalyticsViewDimension = NStr("vi = 'Doanh nghiệp';
																|ru = 'Организации';
																|en = 'Companies'; fa = 'شرکت‌ها';
																|it = 'Aziende';
																|pl = 'Organizacje';
																|tr = 'İş yerleri'", LanguageCode);
				ElsIf MeasurementViewAnalytics = "Department" Then
					PresentationOfAnalyticsViewDimension = NStr("vi = 'Bộ phận';
																|ru = 'Подразделения';
																|en = 'Business units'; fa = 'واحدهای تجاری';
																|it = 'Reparti';
																|pl = 'Działu';
																|tr = 'Departmanlar'", LanguageCode);
				ElsIf MeasurementViewAnalytics = "Scenario" Then
					PresentationOfAnalyticsViewDimension = NStr("vi = 'Kịch bản';
																|ru = 'Сценарии';
																|en = 'Scenarios'; fa = 'سناریوها';
																|it = 'Scenari';
																|pl = 'Scenariusze';
																|tr = 'Senaryolar'", LanguageCode);
				ElsIf MeasurementViewAnalytics = "Currency" Then
					PresentationOfAnalyticsViewDimension = NStr("vi = 'Tiền tệ';
																|ru = 'Валюты';
																|en = 'Currencies'; fa = 'ارزها';
																|it = 'Valute';
																|pl = 'Waluty';
																|tr = 'Para birimleri'", LanguageCode);
				ElsIf PresentationOfNumberedAnalytics <> Undefined Then
					PresentationOfAnalyticsViewDimension = PresentationOfNumberedAnalytics;
					ThisIsNumberedAnalytics = True;
				Else
					PresentationOfAnalyticsViewDimension = MeasurementViewAnalytics;
				EndIf;
			Else
				PresentationOfAnalyticsViewDimension = BudgetReportingServerCall.PresentationOfAnalyticsView(MeasurementViewAnalytics);
			EndIf;
		EndIf;
		If MeasurementViewAnalytics = "" Or ThisIsNumberedAnalytics Then
			If Mode = "All" Then
				PresentationOfEmptyValue = NStr("vi = '<tất cả>';
												|ru = '<все>';
												|en = '<all>'; fa = '<همه>';
												|it = '<tutti>';
												|pl = '<wszystkie>';
												|tr = '<tümü>'", LanguageCode);
			ElsIf Mode = "AddedAndOther" Then
				PresentationOfEmptyValue = NStr("vi = '<đã thêm và  khác>';
												|ru = '<добавляемые и прочие>';
												|en = '<added and other>'; fa = '<added and other>';
												|it = '<da aggiungere e altri >';
												|pl = '<dodawane i pozostałe>';
												|tr = '<eklemeler ve diğerleri>'", LanguageCode);
			Else
				PresentationOfEmptyValue = NStr("vi = '<khác>';
												|ru = '<прочие>';
												|en = '<other>'; fa = '<سایر>';
												|it = '<altri>';
												|pl = '<pozostałe>';
												|tr = '<diğer>'", LanguageCode);
			EndIf;
		Else
			If Mode = "All" Then
				Template = NStr("vi = '<tất cả %1>';
								|ru = '<все %1>';
								|en = '<all %1>'; fa = '<all %1>';
								|it = '<tutti %1>';
								|pl = '<wszystkie %1>';
								|tr = '<tüm %1>'", LanguageCode);
			ElsIf Mode = "AllHierarchy" Then
				Template = NStr("vi = '<tất cả %1 Phân nhánh>';
								|ru = '<все %1 Иерархия>';
								|en = '<all %1 Hierarchy>'; fa = '<all %1 Hierarchy>';
								|it = '<все %1 Иерархия>';
								|pl = '<all %1 Hierarchy>';
								|tr = '<tüm %1 Hiyerarşisi>'", LanguageCode);
			ElsIf Mode = "AddedAndOther" Then
				Template = NStr("vi = '<thêm và khác %1>';
								|ru = '<добавляемые и прочие %1>';
								|en = '<added and other %1>'; fa = '<added and other %1>';
								|it = '<da aggiungere e altri %1>';
								|pl = '<dodawane i inne %1>';
								|tr = '<%1 eklemeleri ve diğerleri>'", LanguageCode);
			Else
				Template = NStr("vi = '<khác %1>';
								|ru = '<прочие %1>';
								|en = '<other %1>'; fa = '<other %1>';
								|it = '<altri %1>';
								|pl = '<inne %1>';
								|tr = '<diğer %1>'", LanguageCode);
			EndIf;
			PresentationOfEmptyValue = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				PresentationOfAnalyticsViewDimension);
		EndIf;
		If Not CacheOfSubmittedInformation = Undefined Then
			CacheOfSubmittedInformation.Insert(MeasurementViewAnalytics, PresentationOfEmptyValue);
		EndIf;
	EndIf;
	
	Return PresentationOfEmptyValue;
EndFunction

// Returns a string representation of the dimension.
//
// Parameters:
//  DimensionName - String - The predefined name of the dimension.
//  LanguageCode - String - Language code. By default, an empty string corresponds to the language of the current user.
//  				Set if you need to get a view for a specific language, for example, for the main configuration language.
//
// Returns:
//  String - String representation of the dimension.
//
Function PresentationOfBudgetingDimension(DimensionName, LanguageCode = "") Export
	
	PresentationsOfNumberedAnalytics = PresentationsOfNumberedAnalytics(LanguageCode);
	PresentationOfNumberedAnalytics = PresentationsOfNumberedAnalytics.Get(DimensionName);
	
	If DimensionName = "Organization" Then
		MeasurementView = NStr("vi = 'Doanh nghiệp';
								|ru = 'Организация';
								|en = 'Company'; fa = 'Company';
								|it = 'Azienda';
								|pl = 'Firma';
								|tr = 'İş yeri'", LanguageCode);
	ElsIf DimensionName = "Department" Then
		MeasurementView = NStr("vi = 'Bộ phận';
								|ru = 'Подразделение';
								|en = 'Business unit'; fa = 'Business unit';
								|it = 'Reparto';
								|pl = 'Dział';
								|tr = 'Departman'", LanguageCode);
	ElsIf DimensionName = "Scenario" Then
		MeasurementView = NStr("vi = 'Kịch bản';
								|ru = 'Сценарий';
								|en = 'Scenario'; fa = 'سناریو';
								|it = 'Scenario';
								|pl = 'Scenariusz';
								|tr = 'Senaryo'", LanguageCode);
	ElsIf DimensionName = "Currency" Then
		MeasurementView = NStr("vi = 'Tiền tệ';
								|ru = 'Валюта';
								|en = 'Currency'; fa = 'ارز';
								|it = 'Valuta';
								|pl = 'Waluta';
								|tr = 'Para birimi'", LanguageCode);
	ElsIf DimensionName = "Period" Then
		MeasurementView = NStr("vi = 'Kỳ';
								|ru = 'Период';
								|en = 'Period'; fa = 'دوره';
								|it = 'Periodo';
								|pl = 'Okres';
								|tr = 'Dönem'", LanguageCode);
	ElsIf DimensionName = "SubperiodNumber" Then
		MeasurementView = NStr("vi = 'Số giai đoạn phụ';
								|ru = '№ подпериода';
								|en = 'Subperiod No.'; fa = 'شماره زیردوره';
								|it = '№ del sottoperiodo';
								|pl = 'Nr podokresu';
								|tr = 'Alt dönem No''su'", LanguageCode);
	ElsIf PresentationOfNumberedAnalytics <> Undefined Then
		MeasurementView = PresentationOfNumberedAnalytics;	
	Else
		MeasurementView = "";
	EndIf;
	
	Return MeasurementView;
EndFunction

#Region VariablesInFormulas

// Returns the structure of values for variable periods used in budgeting.
//
// Parameters:
//  ExcludingBrackets - Boolean - If true, the bounding square brackets will be excluded from the variable name and representation.
//  			The default value is False. 
//  LanguageCode - String - Language code. By default, an empty string corresponds to the language of the current user.
//  			Set if you need to get a view for a specific language, for example, for the main configuration language.
//
// Returns:
//  Structure  - Structure of variable periods used in budgeting:
//   * DataPeriodStart - Structure - Contains:
//   	** Name - String - Variable value. Not localized, stored in the database. For Example, "[Factdata Boundaries]".
//   	** Presentation - String - The representation of a variable can be enclosed in square brackets.
//   * DataPeriodEnd - Structure - Contains:
//   	** Name - String - Variable value. Not localized, stored in the database. For Example, "[Factdata Boundaries]".
//   	** Presentation - String - The representation of a variable can be enclosed in square brackets.
//   * ActualDataLimit - Structure - Contains:
//   	** Name - String - Variable value. Not localized, stored in the database. For Example, "[Factdata Boundaries]".
//   	** Presentation - String - The representation of a variable can be enclosed in square brackets.
//   * PeriodOfGrouping - Structure - Contains:
//   	** Name - String - Variable value. Not localized, stored in the database. For Example, "[Factdata Boundaries]".
//   	** Presentation - String - The representation of a variable can be enclosed in square brackets.
//
Function VariablesOfBudgetingPeriods(ExcludingBrackets = False, LanguageCode = "") Export
	
	Result = New Structure;
		
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name",
		StringFunctionsClientServer.SubstituteParametersToString(
			?(ExcludingBrackets, "%1", "[%1]"),
			"DataPeriodStart"));
	MeaningAndPresentation.Insert("Presentation", 
		StringFunctionsClientServer.SubstituteParametersToString(
			?(ExcludingBrackets, "%1", "[%1]"),
			NStr("vi = 'Đầu kỳ dữ liệu';
				|ru = 'Начало периода данных';
				|en = 'Data period start'; fa = 'شروع دوره داده';
				|it = 'Inizio del periodo dei dati';
				|pl = 'Początek okresu danych';
				|tr = 'Veri döneminin başlangıcı'", LanguageCode)));
	Result.Insert("DataPeriodStart", MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name",
		StringFunctionsClientServer.SubstituteParametersToString(
			?(ExcludingBrackets, "%1", "[%1]"),
			"DataPeriodEnd"));
	MeaningAndPresentation.Insert("Presentation", 
		StringFunctionsClientServer.SubstituteParametersToString(
			?(ExcludingBrackets, "%1", "[%1]"),
			NStr("vi = 'Cuối kỳ dữ liệu';
				|ru = 'Конец периода данных';
				|en = 'Data period end'; fa = 'پایان دوره داده';
				|it = 'Fine del periodo dei dati';
				|pl = 'Koniec okresu danych';
				|tr = 'Veri döneminin sonu'", LanguageCode)));
	Result.Insert("DataPeriodEnd", MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name",
		StringFunctionsClientServer.SubstituteParametersToString(
			?(ExcludingBrackets, "%1", "[%1]"),
			"ActualDataLimit"));
	MeaningAndPresentation.Insert("Presentation", 
		StringFunctionsClientServer.SubstituteParametersToString(
			?(ExcludingBrackets, "%1", "[%1]"),
			NStr("vi = 'Ranh giới dữ liệu thực tế';
				|ru = 'Граница факт.данных';
				|en = 'Act. data limit'; fa = 'Act. data limit';
				|it = 'Limiti dei dati attuali';
				|pl = 'Granica danych fakt.';
				|tr = 'Gerçek veri limiti'", LanguageCode)));
	Result.Insert("ActualDataLimit", MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name",
		StringFunctionsClientServer.SubstituteParametersToString(
			?(ExcludingBrackets, "%1", "[%1]"),
			"PeriodOfGrouping"));
	MeaningAndPresentation.Insert("Presentation", 
		StringFunctionsClientServer.SubstituteParametersToString(
			?(ExcludingBrackets, "%1", "[%1]"),
			NStr("vi = 'Kỳ gom nhóm';
				|ru = 'Период группировки';
				|en = 'Grouping period'; fa = 'دوره گروه‌بندی';
				|it = 'Periodo del raggruppamento';
				|pl = 'Okres grupowania';
				|tr = 'Gruplama dönemi'", LanguageCode)));
	Result.Insert("PeriodOfGrouping", MeaningAndPresentation);
	
	Return Result;
EndFunction

// Returns the correspondence of representations of variable periods and their values.
//
// Parameters:
//  ExcludingBrackets - Boolean - If true, the bounding square brackets will be excluded from the variable name and representation.
//  			The default value is False. 
//  LanguageCode - String - Language code. By default, an empty string corresponds to the language of the current user.
//  			Set if you need to get a view for a specific language, for example, for the main configuration language.
//
// Returns:
//  Map of KeyAndValue - Correspondence of representations of variable periods and their values:
//   *Key - String - custom representation of a variable.
//   *Value - String - the stored non-localizable value of the variable.
//
Function ValuesOfVariablePeriodsByPresentation(ExcludingBrackets = False, LanguageCode = "") Export
	Result = New Map;
	
	PeriodVariables = VariablesOfBudgetingPeriods(ExcludingBrackets, LanguageCode);
	For Each KeyAndValue In PeriodVariables Do
		VariableName = KeyAndValue.Value.Name;
		Presentation = KeyAndValue.Value.Presentation;
		Result.Insert(Presentation, VariableName);
	EndDo;
	
	Return Result;
EndFunction

// Returns the correspondence between the values of period variables and their representations.
//
// Parameters:
//  ExcludingBrackets - Boolean - If true, the bounding square brackets will be excluded from the variable name and representation.
//  			The default value is False. 
//  LanguageCode - String - Language code. By default, an empty string corresponds to the language of the current user.
//  			Set if you need to get a view for a specific language, for example, for the main configuration language.
//
// Returns:
//  Map of KeyAndValue - Matching the values of variable periods and their representations:
//   *Key - String - the stored non-localizable value of the variable.
//   *Value - String - custom representation of a variable.
//
Function PresentationOfVariablePeriodsByValue(ExcludingBrackets = False, LanguageCode = "") Export
	Result = New Map;
	
	PeriodVariables = VariablesOfBudgetingPeriods(ExcludingBrackets, LanguageCode);
	For Each KeyAndValue In PeriodVariables Do
		VariableName = KeyAndValue.Value.Name;
		Presentation = KeyAndValue.Value.Presentation;
		Result.Insert(VariableName, Presentation);
	EndDo;
	
	Return Result;
EndFunction

// Returns the structure of parameter values for substitution in text fields used in budget reports.
//
// Parameters:
//  ExcludingBrackets - Boolean - If true, the parameter name and representation will be omitted from the bounding square brackets.
//  			The default value is False. 
//  LanguageCode - String - Language code. By default, an empty string corresponds to the language of the current user.
//  			Set if you need to get a view for a specific language, for example, for the main configuration language.
//
// Returns:
//  Structure - Structure of parameters used in budgeting:
//   *ReportKind - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     **Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     **Presentation - String - The representation of a variable can be enclosed in square brackets.
//   *CurrentDateAndTime - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     **Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     **Presentation - String - The representation of a variable can be enclosed in square brackets.
//   *ReportingPeriod - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     **Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     **Presentation - String - The representation of a variable can be enclosed in square brackets.
//   *EndDateOfReportPeriod - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     **Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     **Presentation - String - The representation of a variable can be enclosed in square brackets.
//   *LimitOfActualData - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     **Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     **Presentation - String - The representation of a variable can be enclosed in square brackets.
//   *Organization - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     **Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     **Presentation - String - The representation of a variable can be enclosed in square brackets.
//   *Department - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     **Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     **Presentation - String - The representation of a variable can be enclosed in square brackets.
//   *Scenario - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     **Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     **Presentation - String - The representation of a variable can be enclosed in square brackets.
//   *DocumentStatus - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     **Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     **Presentation - String - The representation of a variable can be enclosed in square brackets.
//   *EmployeeResponsible - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     **Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     **Presentation - String - The representation of a variable can be enclosed in square brackets.
//   *Approving - Structure - A structure that stores a non-localized value stored in a database and a localized Presentation:
//     **Name - String - ID of the parameter. Not localized, stored in the database. For Example, "[Current DateTime]".
//     **Presentation - String - The representation of a variable can be enclosed in square brackets.
//
Function BudgetReportVariables(ExcludingBrackets = False, LanguageCode = "") Export
	
	Result = New Structure;
	
	VariableTemplate = ?(ExcludingBrackets, "%1", "[%1]");
	
	ParameterName = "ReportKind";
	Name = StrTemplate(VariableTemplate, ParameterName);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", Name);
	MeaningAndPresentation.Insert("Presentation", NStr("vi = 'Dạng báo cáo';
														|ru = 'Вид отчета';
														|en = 'Report kind'; fa = 'نوع گزارش';
														|it = 'Tipo di report';
														|pl = 'Rodzaj raportu';
														|tr = 'Rapor türü'", LanguageCode));
	Result.Insert(ParameterName, MeaningAndPresentation);
	
	ParameterName = "CurrentDateAndTime";
	Name = StrTemplate(VariableTemplate, ParameterName);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", Name);
	MeaningAndPresentation.Insert("Presentation", NStr("vi = 'Ngày giờ hiện tại';
														|ru = 'Текущая дата и время';
														|en = 'Current date and time'; fa = 'Current date and time';
														|it = 'Data e ora correnti';
														|pl = 'Bieżąca data i godzina';
														|tr = 'Mevcut tarih ve zaman'", LanguageCode));
	Result.Insert(ParameterName, MeaningAndPresentation);
	
	ParameterName = "ReportingPeriod";
	Name = StrTemplate(VariableTemplate, ParameterName);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", Name);
	MeaningAndPresentation.Insert("Presentation", NStr("vi = 'Kỳ báo cáo';
														|ru = 'Период отчетности';
														|en = 'Reporting period'; fa = 'Reporting period';
														|it = 'Periodo di rendicontazione';
														|pl = 'Okres rozliczeniowy';
														|tr = 'Hesap dönemi'", LanguageCode));
	Result.Insert(ParameterName, MeaningAndPresentation);
	
	ParameterName = "EndDateOfReportPeriod";
	Name = StrTemplate(VariableTemplate, ParameterName);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", Name);
	MeaningAndPresentation.Insert("Presentation", NStr("vi = 'Ngày kết thúc kỳ báo cáo';
														|ru = 'Конечная дата периода отчета';
														|en = 'End date of report period'; fa = 'End date of report period';
														|it = 'Data conclusiva del periodo del report';
														|pl = 'Data końcowa okresu raportu';
														|tr = 'Rapor döneminin son tarihi'", LanguageCode));
	Result.Insert(ParameterName, MeaningAndPresentation);
	
	ParameterName = "LimitOfActualData";
	Name = StrTemplate(VariableTemplate, ParameterName);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", Name);
	MeaningAndPresentation.Insert("Presentation", NStr("vi = 'Ranh giới dữ liệu thực tế';
														|ru = 'Граница фактических данных';
														|en = 'Actual data limit'; fa = 'مرز داده‌های واقعی';
														|it = 'Limite dei dati effettivi';
														|pl = 'Granica faktycznych danych';
														|tr = 'Gerçek veri uzaklığı'", LanguageCode));
	Result.Insert(ParameterName, MeaningAndPresentation);
	
	ParameterName = "Organization";
	Name = StrTemplate(VariableTemplate, ParameterName);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", Name);
	MeaningAndPresentation.Insert("Presentation", NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Azienda';
														|pl = 'Organizacja';
														|tr = 'İş yeri'", LanguageCode));
	Result.Insert(ParameterName, MeaningAndPresentation);
	
	ParameterName = "Department";
	Name = StrTemplate(VariableTemplate, ParameterName);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", Name);
	MeaningAndPresentation.Insert("Presentation", NStr("vi = 'Bộ phận';
														|ru = 'Подразделение';
														|en = 'Business unit'; fa = 'Business unit';
														|it = 'Reparto';
														|pl = 'Dział';
														|tr = 'Departman'", LanguageCode));
	Result.Insert(ParameterName, MeaningAndPresentation);
	
	ParameterName = "Scenario";
	Name = StrTemplate(VariableTemplate, ParameterName);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", Name);
	MeaningAndPresentation.Insert("Presentation", NStr("vi = 'Kịch bản';
														|ru = 'Сценарий';
														|en = 'Scenario'; fa = 'سناریو';
														|it = 'Scenario';
														|pl = 'Scenariusz';
														|tr = 'Senaryo'", LanguageCode));
	Result.Insert(ParameterName, MeaningAndPresentation);
	
	ParameterName = "DocumentStatus";
	Name = StrTemplate(VariableTemplate, ParameterName);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", Name);
	MeaningAndPresentation.Insert("Presentation", NStr("vi = 'Trạng thái chứng từ';
														|ru = 'Статус документа';
														|en = 'Document status'; fa = 'وضعیت سند';
														|it = 'Stato del documento';
														|pl = 'Status dokumentu';
														|tr = 'Belge durumu'", LanguageCode));
	Result.Insert(ParameterName, MeaningAndPresentation);
	
	ParameterName = "EmployeeResponsible";
	Name = StrTemplate(VariableTemplate, ParameterName);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", Name);
	MeaningAndPresentation.Insert("Presentation", NStr("vi = 'Người chịu trách nhiệm';
														|ru = 'Ответственный';
														|en = 'Person responsible'; fa = 'شخص مسئول';
														|it = 'Responsabile';
														|pl = 'Osoba odpowiedzialna';
														|tr = 'Sorumlu'", LanguageCode));
	Result.Insert(ParameterName, MeaningAndPresentation);
	ParameterName = "Approving";
	Name = StrTemplate(VariableTemplate, ParameterName);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", Name);
	MeaningAndPresentation.Insert("Presentation", NStr("vi = 'Người duyệt';
														|ru = 'Утверждающий';
														|en = 'Approver'; fa = 'تأییدکننده';
														|it = 'Approvatore';
														|pl = 'Approver';
														|tr = 'Onaylayan'", LanguageCode));
	Result.Insert(ParameterName, MeaningAndPresentation);
	Return Result;
	
EndFunction

// Returns an ordered array of parameter values for substituting into text fields used in budget reports.
//
// Parameters:
//  LanguageCode - String - Language code. By default, an empty string corresponds to the language of the current user.
//  		Set if you need to get a view for a specific language, for example, for the main configuration language.
//
// Returns:
//  Array of Structure -  An ordered array of parameters, the parameter represents a structure with columns:
//  	*Name - String - Variable identifier.
//  	*Presentation - String - Representation of a variable.
//
Function OrderedVariablesOfBudgetReports(LanguageCode = "") Export
	
	Result = New Array;
	
	BudgetReportVariables = BudgetReportVariables(True, LanguageCode);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", BudgetReportVariables.ReportKind.Name);
	MeaningAndPresentation.Insert("Presentation", BudgetReportVariables.ReportKind.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", BudgetReportVariables.CurrentDateAndTime.Name);
	MeaningAndPresentation.Insert("Presentation", BudgetReportVariables.CurrentDateAndTime.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", BudgetReportVariables.ReportingPeriod.Name);
	MeaningAndPresentation.Insert("Presentation", BudgetReportVariables.ReportingPeriod.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", BudgetReportVariables.EndDateOfReportPeriod.Name);
	MeaningAndPresentation.Insert("Presentation", BudgetReportVariables.EndDateOfReportPeriod.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", BudgetReportVariables.LimitOfActualData.Name);
	MeaningAndPresentation.Insert("Presentation", BudgetReportVariables.LimitOfActualData.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", BudgetReportVariables.Organization.Name);
	MeaningAndPresentation.Insert("Presentation", BudgetReportVariables.Organization.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", BudgetReportVariables.Department.Name);
	MeaningAndPresentation.Insert("Presentation", BudgetReportVariables.Department.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", BudgetReportVariables.Scenario.Name);
	MeaningAndPresentation.Insert("Presentation", BudgetReportVariables.Scenario.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", BudgetReportVariables.DocumentStatus.Name);
	MeaningAndPresentation.Insert("Presentation", BudgetReportVariables.DocumentStatus.Presentation);
	Result.Add(MeaningAndPresentation);
	
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", BudgetReportVariables.EmployeeResponsible.Name);
	MeaningAndPresentation.Insert("Presentation", BudgetReportVariables.EmployeeResponsible.Presentation);
	Result.Add(MeaningAndPresentation);
	MeaningAndPresentation = New Structure;
	MeaningAndPresentation.Insert("Name", BudgetReportVariables.Approving.Name);
	MeaningAndPresentation.Insert("Presentation", BudgetReportVariables.Approving.Presentation);
	Result.Add(MeaningAndPresentation);
	Return Result;
	
EndFunction

// Calculates the ID value from a string according to the variable naming rules.
// 
// Parameters:
//  RwName - String - name of the string to get the ID from. 
//
// Returns:
//  String - An identifier that conforms to the rules for naming identifiers.
//
Function GetID(RwName) Export
	
	Id = TMCommonUseClientServer.GetID(RwName); 
	
	Digits = New Array();
	For Cnt = 0 To 9 Do
		Digits.Add(String(Cnt));
	EndDo;
	
	FirstCharacterIsNotDigit = False;
	
	IDLength = StrLen(Id);
	If Not IsBlankString(Id) Then
		For CharacterNumber = 1 To IDLength Do
			If Digits.Find(Mid(Id, 1, 1)) = Undefined Then
				FirstCharacterIsNotDigit = True;
			EndIf;
			If FirstCharacterIsNotDigit Then
				Break;
			Else
				Id = Mid(Id, 2);
			EndIf;
		EndDo;
	EndIf;
	
	Return Id;
	
EndFunction

#EndRegion

#EndRegion

#Region CellDesign

// Sets the specified shift format in the format string
//
// Parameters:
//  ShiftFormat - String - the format of the shift to be set
//  FormatString - String - format string for which the shift format is set
//
// Returns:
//  String - installed format string
//
Function SetFormatOfShiftInFormatString(ShiftFormat, FormatString) Export
	
	Move = StrFind(Upper(FormatString), "EMERGENCY");
	If Move Then
		BalanceOfShiftLine = Mid(FormatString, Move);
		Separator = StrFind(BalanceOfShiftLine, ";");
		If Separator Then
			BalanceOfShiftLine = Left(BalanceOfShiftLine, Separator - 1);
		EndIf;
		NewFormatString = StrReplace(FormatString, BalanceOfShiftLine, ShiftFormat);
	Else
		NewFormatString = ?(IsBlankString(FormatString), "", FormatString + "; ") + ShiftFormat;
	EndIf;
	
	Return NewFormatString;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function PresentationsOfNumberedAnalytics(LanguageCode = "")
	PresentationsOfNumberedAnalytics = New Map;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		PresentationOfNumberedAnalytics = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chỉ số%1';
				|ru = 'Аналитика%1';
				|en = 'Dimension%1'; fa = 'Dimension%1';
				|it = 'Analitica%1';
				|pl = 'Analityka%1';
				|tr = 'Boyut%1'", LanguageCode), 
			DimensionNumber);
		PresentationsOfNumberedAnalytics.Insert("Dimension" + DimensionNumber, PresentationOfNumberedAnalytics);
	EndDo;
	Return PresentationsOfNumberedAnalytics;
EndFunction

// This function defines the type of budget report dimension
//
// Parameters:
//  Value  - Arbitrary - the value of the budget report dimension that is used to determine the dimension type.
//  AdditionalParameters  - Structure - more information.
//
// Returns:
//   EnumRef.TypesOfBudgetReportDimensions - type of measurement.
//
Function DetermineMeasurementTypeByValueType(Value, AdditionalParameters = Undefined) Export
	
	If TypeOf(Value) = Type("EnumRef.Periodicity") Then
		
		Return DimensionType("Period");
		
	ElsIf TypeOf(Value) = Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions") Then
		
		If AdditionalParameters <> Undefined
			And (ValueIsFilled(AdditionalParameters.DimensionValue) 
			Or AdditionalParameters.ThisIsDimensionOther) Then
			Return DimensionType("FixedDimension");
		Else
			Return DimensionType("Dimension");
		EndIf;
		
	ElsIf TypeOf(Value) = Type("CatalogRef.BudgetingScenarios") Then
		
		Return DimensionType("Scenario");
		
	ElsIf TypeOf(Value) = Type("CatalogRef.Companies") Then
		
		Return DimensionType("Organization");
		
	ElsIf TypeOf(Value) = Type("CatalogRef.BusinessStructure") Then
		
		Return DimensionType("Department");
		
	ElsIf TypeOf(Value) = Type("CatalogRef.Currencies") Then
		
		Return DimensionType("Currency");
		
	ElsIf TypeOf(Value) = Type("CatalogRef.PackagesAndUnitsOfMeasure") Then
		
		Return DimensionType("UnitOfMeasure");
		
	ElsIf TypeOf(Value) = Type("String") Then
		
		Return DimensionType("RegisterDimension");
		
	Else
		
		Raise NStr("vi = 'Dạng chiều đo không xác định của báo cáo ngân sách';
					|ru = 'Неизвестный тип измерения бюджетного отчета';
					|en = 'Unknown budget report dimension type'; fa = 'Unknown budget report dimension type';
					|it = 'Tipo sconosciuto della misura del rapporto di bilancio';
					|pl = 'Nieznany typ wymiaru raportu budżetowego';
					|tr = 'Bütçe raporu ölçüm türü bilinmiyor'");
		
	EndIf;
	
EndFunction

// The procedure fills in a row in the list or tree of report elements
// with additional details.
//
// Parameters:
//  Result - Structure - the seeding source
//  DestinationRow - FormDataTreeItem - the line to fill in
//  ItemAddressInStorage - String - address of the item storage
//  Field - FormDataCollection - to search for a string, if the receiver is the string ID.
//
Procedure FillInLineInListOfReportElements(Val Result, Val DestinationRow, ItemAddressInStorage = Undefined, Field = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	// The form returns the current details
	If TypeOf(DestinationRow) = Type("Number") Then
		DestinationRow = Field.FindByID(DestinationRow);
	EndIf;
	
	FillPropertyValues(DestinationRow, Result);
	AdditionalListDetails = "DisplayedIndicators, IndicatorValueType, DisplayItemTitle, PrivilegedMode";
	If Not ValueIsFilled(ItemAddressInStorage) Then
		AdditionalAttributes = 
				FinancialReportingServerCall.AdditionalAttributesValues(
													Result,
													AdditionalListDetails);
	Else
		// But the actual values of the additional details are generated on the server
		// in the pre-recording server, respectively, they are in the storage.
		AdditionalAttributes = 
				FinancialReportingServerCall.AdditionalAttributesValues(
													ItemAddressInStorage,
													AdditionalListDetails);
	EndIf;
	
	FillPropertyValues(DestinationRow, AdditionalAttributes);
	
EndProcedure

// The function returns a representation of the offset
//
// Parameters:
//  Form  - ClientApplicationForm -
//  ValueIsEmpty - Boolean -
//
// Returns:
//   String   - representation of the offset.
//
Function OffsetPresentation(Form, ValueIsEmpty = False) Export
	
	ValueIsEmpty = False;
	
	PeriodVariables = VariablesOfBudgetingPeriods();
	Periodicity = Form.OffsetFrequency;
	Period = Form.PeriodOfShift;
	
	If Period = 0 Then
		PresentationPeriod = "";
	Else
		Presentation = NStr("vi = 'Dữ liệu đã chuyển %1 trở lại';
							|ru = 'Данные смещены на %1 назад';
							|en = 'Data is shifted %1 back'; fa = 'Data is shifted %1 back';
							|it = 'Dati spostati di %1 indietro';
							|pl = 'Dane przesunięte na %1 dotyłu';
							|tr = '%1 kısmının öncesindeki kayan veriler'");
		PresentationPeriod = WorkingWithClientServerPeriods.PeriodInNumbersPeriodicityInWords(Period, Periodicity);
		PresentationPeriod = StringFunctionsClientServer.SubstituteParametersToString(Presentation, PresentationPeriod);
	EndIf;
	
	ThereAreBoundaryChanges = False;
	If Not StrFind(Form.FormName, "NonFinancialItem") Then
		If ValueIsFilled(Form.LowerBoundOfData)
			And Form.LowerBoundOfData <> PeriodVariables.DataPeriodStart.Name Then
			
			ThereAreBoundaryChanges = True;
			
		ElsIf ValueIsFilled(Form.UpperBoundOfData)
			And Form.UpperBoundOfData <> PeriodVariables.DataPeriodEnd.Name Then
			
			ThereAreBoundaryChanges = True;
			
		ElsIf ValueIsFilled(Form.GroupingPeriodStart)
			And Form.GroupingPeriodStart <> PeriodVariables.PeriodOfGrouping.Name Then
			
			ThereAreBoundaryChanges = True;
			
		ElsIf ValueIsFilled(Form.GroupingPeriodEnd)
			And Form.GroupingPeriodEnd <> PeriodVariables.PeriodOfGrouping.Name Then
			
			ThereAreBoundaryChanges = True;
			
		EndIf;
	EndIf;
	
	PresentationOfBoundaries = "";
	If ThereAreBoundaryChanges Then
		PresentationOfBoundaries = NStr("vi = 'Ranh giới thời gian được đặt';
										|ru = 'Установлены границы периода';
										|en = 'Period boundaries are set'; fa = 'Period boundaries are set';
										|it = 'Impostate i limiti del periodo';
										|pl = 'Ustawione granicy okresu';
										|tr = 'Dönem limitleri ayarlandı'");
	EndIf;
	
	If PresentationOfBoundaries = ""
		And PresentationPeriod = "" Then
		
		Result = NStr("vi = 'Ranh giới dữ liệu và dữ liệu không được đặt';
						|ru = 'Смещение и границы данных не заданы';
						|en = 'Offset and limits of data are not specified'; fa = 'Offset and limits of data are not specified';
						|it = 'Offset e limiti dei dati non specificati';
						|pl = 'Nie zadano przesunięcia i granic danych';
						|tr = 'Kaymalar ve veri sınırları ayarlanmamış'");
		ValueIsEmpty = True;
		
	ElsIf PresentationPeriod <> ""
		And PresentationOfBoundaries <> "" Then
		
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1, %2';
				|ru = '%1, %2';
				|en = '%1, %2'; fa = '%1, %2';
				|it = '%1, %2';
				|pl = '%1, %2';
				|tr = '%1, %2'"),
			PresentationPeriod,
			Lower(PresentationOfBoundaries));
		
	ElsIf PresentationPeriod <> "" Then
		
		Result = PresentationPeriod;
		
	ElsIf PresentationOfBoundaries <> "" Then
		
		Result = PresentationOfBoundaries;
		
	EndIf;
	
	Return Result;

EndFunction

// The function returns the style color
//
// Parameters:
//  LocalCache  - Map - local cache for storing matching names and colors, so that you don't need to access
//  					 the server in case of a client call.
//  ColorName  - String - color name.
//
// Returns:
//   Color - The color of the style by name.
//
Function GetStyleColor(LocalCache, ColorName) Export
	Var Color;
	
	If LocalCache = Undefined Then
		LocalCache = New Structure;
	EndIf;
	
	If LocalCache.Property(ColorName, Color) Then
		Return Color;
	EndIf;
	
	Color = BudgetReportingServerCall.GetColor(ColorName);
	LocalCache.Insert(ColorName, Color);
	
	Return Color;
	
EndFunction

// The function adds operands to the operand table
//
// Parameters:
//  Form  - ClientApplicationForm - formula constructor form
//  NewOperands  - Array of FormDataTreeItem - Strings of the operand tree. Contains including:
//  	* Description - String -
//  OperandsTable - ValueTable - Table of operands selected in the formula. Contains including:
//  	* Id - String -
//  Unique - Boolean - a sign of the uniqueness of the operands (add operands, if any).
//
// Returns:
//   Array of FormDataCollectionItem - array of added rows of the operand table.
//
Function AddFormulaOperands(Form, NewOperands, OperandsTable, Unique) Export
	
	ArrayOfAdded = New Array;
	For Each Operand In NewOperands Do
		
		If Not ElementIsAvailableAsOperand(Operand) Then
			Continue;
		EndIf;
		
		Id = OperandName(Operand.Description, Operand, OperandsTable, Unique);
		
		FoundOperand = Undefined;
		If ThereIsIndicator(Id, Operand, OperandsTable, FoundOperand) Then
			ArrayOfAdded.Add(FoundOperand);
		Else
			NewRow = OperandsTable.Add();
			FillPropertyValues(NewRow, Operand);
			NewRow.Id = Id;
			NewRow.NameForPrinting = Operand.Description;
			NewRow.ItemIndicatorDimensionType = Operand.ReportingKindItem;
			NewRow.PrivilegedModePicture = Not Number(NewRow.PrivilegedMode);
			If NewRow.ItemKind <> PredefinedValue("Enum.FinancialReportItemKinds.NonFinancialItem") Then
				NewRow.DisplayedIndicators = PredefinedValue("Enum.TypesOfDisplayedBudgetReportIndicators.Sum");
				If NewRow.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.BudgetBalanceItem") Then
					NewRow.IndicatorValueType = PredefinedValue("Enum.ValueTypesOfBudgetReportIndicators.Turnover");
				EndIf;
			EndIf;
			ArrayOfAdded.Add(NewRow);
		EndIf;
		
		If Not Form.Modified Then
			Form.Modified = True;
		EndIf;
		
	EndDo;
	
	Return ArrayOfAdded;
	
EndFunction

// Determines whether a financial report element can be used as an operand for a derived metric
// Used when adding operands in a derived exponent.
//
// Parameters:
//  ReportItem - FormDataTreeItem - the report element to check.
//
// Returns:
//   Boolean -
//
Function ElementIsAvailableAsOperand(ReportItem) Export
	ItemNotAvailable = 
			ReportItem = Undefined
			Or ReportItem.IsFolder
			Or Not ValueIsFilled(ReportItem.ItemKind)
			Or ReportItem.ItemKind.IsEmpty()
			Or ReportItem.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.AllBudgetBalanceItems")
			Or ReportItem.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.AllBudgetFlowItems");
	
	Return Not ItemNotAvailable;
EndFunction
		
Function OperandName(Description, Operand, OperandsTable, Unique) Export
	
	CellSeparator = CellSeparatorForComplexTable();
	
	PreparedName = StringFunctionsClientServer.ReplaceCharsWithOther(":+-*/=@№%()", Description, "");
	Array = StrSplit(PreparedName, " ", False);
	
	Result = "";
	For Each Item In Array Do
		ThereIsCellSeparator = (Right(Item, 1) = CellSeparator);
		Result = Result + Title(TrimAll(Left(Item, 7))) + ?(ThereIsCellSeparator, CellSeparator, "");
	EndDo;
	
	Id = Result;
	
	If Unique Then
	
		Cnt = 0;
		While ThereIsIndicator(Id, Operand, OperandsTable) Do
			Cnt = Cnt + 1;
			Id = Result + "_" + Format(Cnt, "NG=");
		EndDo;
		
	Else
		
		If TypeOf(Operand) = Type("FormDataCollectionItem") Then // Interactive addition of an operand
			OperandID = Operand.GetID();
			If OperandsTable.FindByID(OperandID) = Undefined Then
				ComparisonStructure = New Structure("ItemKind, ReportingKindItem");
				FillPropertyValues(ComparisonStructure, Operand);
				Id = BudgetReportingServerCall.IncreaseIDNumerator(Id, ComparisonStructure, OperandsTable);
			Else
				Id = BudgetReportingServerCall.IncreaseIDNumerator(Id, OperandID, OperandsTable);
			EndIf;
		EndIf;
		
	EndIf;
	
	Return Id;
	
EndFunction

Function CellSeparatorForComplexTable() Export
	Return ";";
EndFunction

// Checking whether the indicator is available
// 
// Parameters:
// 	Id - String -
// 	Operand - FormDataTreeItem - contains including:
// * Description - String -
// 	OperandsTable - ValueTable - contains including:
// * Id - String -
// 	FoundOperand - Undefined, ValueTableRow -
// Returns:
// 	Boolean -
Function ThereIsIndicator(Id, Operand, OperandsTable, FoundOperand = Undefined)
	
	For Each OperandString_ In OperandsTable Do
		If OperandString_.Id = Id Then
			
			FoundOperand = OperandString_;
			Return True;
			
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ItemKind(ElementTypeName) Export
	
	Return PredefinedValue("Enum.FinancialReportItemKinds."+ElementTypeName);
	
EndFunction

Function DimensionType(ElementTypeName)
	
	Return PredefinedValue("Enum.TypesOfBudgetReportDimensions."+ElementTypeName);
	
EndFunction

Function LeftPartOfNameMatches(Name, SearchRow) Export
	
	Return Left(Name, StrLen(SearchRow)) = SearchRow;
	
EndFunction

// Determines whether the passed field is a field containing a period
//
// Parameters:
//    Name - String - field name
//
// Returns:
//    Boolean - Indicates that the field is a field containing a period
//
Function ThisIsPeriodField(Name) Export
	
	PeriodFields = New Array;
	PeriodFields.Add("Period");
	PeriodFields.Add("DayPeriod");
	PeriodFields.Add("WeekPeriod");
	PeriodFields.Add("TenDaysPeriod");
	PeriodFields.Add("MonthPeriod");
	PeriodFields.Add("QuarterPeriod");
	PeriodFields.Add("HalfYearPeriod");
	PeriodFields.Add("YearPeriod");
	
	Return PeriodFields.Find(Name) <> Undefined;
	
EndFunction

Function ParametersForOpeningPeriodSettingsForm(Form, AddReportElements = True) Export
	
	Parameters = New Structure;
	Parameters.Insert("PeriodOfShift");
	Parameters.Insert("OffsetFrequency");
	Parameters.Insert("LowerBoundOfData");
	Parameters.Insert("UpperBoundOfData");
	Parameters.Insert("GroupingPeriodStart");
	Parameters.Insert("GroupingPeriodEnd");
	If AddReportElements Then
		Parameters.Insert("ItemTableAddress");
		Parameters.Insert("AddressOfEditedItem");
		Parameters.Insert("AddressOfReportItems");
		Parameters.Insert("LocationOptionOfActualDataOffset");
	EndIf;
	
	FillPropertyValues(Parameters, Form);
	
	Return Parameters;
	
EndFunction

Function ParametersForOpeningSchedulingFrequencySettingsForm(FormObject1) Export
	
	Parameters = New Structure;
	Parameters.Insert("Periodicity");
	Parameters.Insert("PlanningMethod");
	Parameters.Insert("LocationOptionOfActualDataOffset");
	Parameters.Insert("NumberOfPeriodsOfRollingBudget");
	Parameters.Insert("ActualDataLimitOffset");
	Parameters.Insert("ActualDataLimitTimeFence");
	
	FillPropertyValues(Parameters, FormObject1);
	
	Return Parameters;
	
EndFunction

Function NameOfBudgetValueToEdit(ArrayOfNamesOfEditableValues) Export
	
	DefaultName = NStr("vi = 'Giá trị có thể chỉnh sửa';
						|ru = 'Редактируемое значение';
						|en = 'Edited value'; fa = 'مقدار ویرایش‌شده';
						|it = 'Valore modificato';
						|pl = 'Edytowana wartość';
						|tr = 'Düzenlenebilir değer'");
	
	If ArrayOfNamesOfEditableValues.Count() Then
		
		ArrayOfOriginalNames = New Array;
		For Each ArrayElement In ArrayOfNamesOfEditableValues Do
			If StrFind(ArrayElement, DefaultName) > 0 Then
				ArrayOfOriginalNames.Add(ArrayElement);
			EndIf;
		EndDo;
		
		If Not ArrayOfOriginalNames.Count() Then
			
			Return DefaultName;
			
		EndIf;
		
		MaximumName = ArrayOfOriginalNames[ArrayOfOriginalNames.UBound()];
		StartOfIssue = StrFind(MaximumName, "#");
		If StartOfIssue Then
			NameWithoutNumber = TrimAll(Left(MaximumName, StartOfIssue - 1));
		Else
			NameWithoutNumber = TrimAll(MaximumName);
		EndIf;
		
		Cnt = 0;
		NameWithNumber = NameWithoutNumber;
		While ArrayOfOriginalNames.Find(NameWithNumber) <> Undefined Do
			Cnt = Cnt + 1;
			NameWithNumber = NameWithoutNumber + " #" + Cnt;
		EndDo;
		
		Return NameWithNumber;
		
	Else
		
		Return DefaultName;
		
	EndIf;
	
EndFunction

// Returns an array of ascending time fences
//
// Returns:
//  Array of EnumRef.Periodicity
//
Function OrderedPeriodicities() Export
	
	Periodicity_ = New Array;
	
	Periodicity_.Add(PredefinedValue("Enum.Periodicity.EmptyRef"));
	Periodicity_.Add(PredefinedValue("Enum.Periodicity.Day"));
	Periodicity_.Add(PredefinedValue("Enum.Periodicity.Week"));
	Periodicity_.Add(PredefinedValue("Enum.Periodicity.TenDays"));
	Periodicity_.Add(PredefinedValue("Enum.Periodicity.Month"));
	Periodicity_.Add(PredefinedValue("Enum.Periodicity.Quarter"));
	Periodicity_.Add(PredefinedValue("Enum.Periodicity.HalfYear"));
	Periodicity_.Add(PredefinedValue("Enum.Periodicity.Year"));
	
	Return Periodicity_;
	
EndFunction

// Returns the minimum periodicity of the transmitted data
//
// Parameters:
// 	Periodicity_ - Array of EnumRef.Periodicity - Periodicity, of which you need to find the minimum.
// 
// Returns:
// 	EnumRef.Periodicity - The minimum periodicity found.
//
Function MinimumPeriodicity(Periodicity_) Export
	
	Result = Undefined;
	
	OrderedPeriodicities = OrderedPeriodicities();
	For Each Periodicity In OrderedPeriodicities Do 
		If ValueIsFilled(Periodicity) And Periodicity_.Find(Periodicity) <> Undefined Then
			Result = Periodicity;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#Region BudgetEntryForm

Function MaximumNumberInOrder(Object) Export
	
	MaxNumber = 0;
	For Each RowOfRevolutions In Object.BudgetFlowItemTurnovers Do
		MaxNumber = Max(RowOfRevolutions.SerialNumber, MaxNumber);
	EndDo;
	
	Return MaxNumber;
	
EndFunction

Function IDOfBudgetItemAnalytics(ObjectAndCalculationParameters, SearchData_, Add = True) Export
	Var RowID;
	
	Object = ObjectAndCalculationParameters.Object;
	ScenarioCurrency = ObjectAndCalculationParameters.ScenarioCurrency;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	TheStructureOfTheSearch = New Structure;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TheStructureOfTheSearch.Insert("Dimension" + DimensionNumber);
	EndDo;
	
	If SearchData_.Property("BudgetFlowItem") Then
		TheStructureOfTheSearch.Insert("BudgetFlowItem");
		TheStructureOfTheSearch.Insert("Currency");
		TabularSectionName = "BudgetFlowItemsDimension";
	Else
		TheStructureOfTheSearch.Insert("EditedValue");
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			TheStructureOfTheSearch.Insert("DimensionKind" + Cnt);
		EndDo;
		TabularSectionName = "DimensionValues_";
	EndIf;
	
	FillPropertyValues(TheStructureOfTheSearch, SearchData_);
	
	If SearchData_.Property("BudgetFlowItem") Then
		If TypeOf(SearchData_) = Type("Structure") Then
			If SearchData_.Property("Currency") Then
				If SearchData_.Currency = Undefined Then
					TheStructureOfTheSearch.Delete("Currency");
				Else
					TheStructureOfTheSearch.Currency = SearchData_.Currency;
				EndIf;
			Else
				TheStructureOfTheSearch.Currency = ScenarioCurrency;
			EndIf;
		Else
			TheStructureOfTheSearch.Currency = ScenarioCurrency;
		EndIf;
	Else
		MaximumNumberOfAnalytics = 0;
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			If ValueIsFilled(TheStructureOfTheSearch["DimensionKind" + Cnt]) Then
				MaximumNumberOfAnalytics = Cnt;
			EndIf;
		EndDo;
		TheStructureOfTheSearch.Insert("NumberOfUsedDimensions", MaximumNumberOfAnalytics);
	EndIf;
	
	SearchResult = Object[TabularSectionName].FindRows(TheStructureOfTheSearch);
	If SearchResult.Count() = 0 Then
		If Add Then
			AnalyticsLineForBudgetItems = Object[TabularSectionName].Add();
			FillPropertyValues(AnalyticsLineForBudgetItems, TheStructureOfTheSearch);
			AnalyticsLineForBudgetItems.RowID = New UUID;
			RowID = AnalyticsLineForBudgetItems.RowID;
		EndIf;
	Else
		RowID = SearchResult[0].RowID;
	EndIf;
	
	Return RowID;
	
EndFunction

// Transcript conversion
// 
// Parameters:
// 	ObjectAndCalculationParameters - See BudgetReportingClientServer.ObjectStructureForCellCalculation
// 	Details - Map, Undefined - LongDesc
// 	SearchMode_ - Boolean - LongDesc
// 	IndicatorName - Undefined, String - LongDesc
// Returns:
// 	Undefined, Structure - 
Function ConvertDecryption(ObjectAndCalculationParameters, Details, SearchMode_ = False, IndicatorName = Undefined) Export
	Var BudgetFlowItem, ResultingStructure;
	
	ItemParameterCache = ObjectAndCalculationParameters.ItemParameterCache;
	Object = ObjectAndCalculationParameters.Object;
	
	If Details.Property("BudgetFlowItem", BudgetFlowItem)
		And ValueIsFilled(BudgetFlowItem) Then
		ResultingStructure = New Structure("BudgetFlowItem", BudgetFlowItem);
	ElsIf Details.Property("BudgetBalanceItem", BudgetFlowItem)
		And ValueIsFilled(BudgetFlowItem) Then
		ResultingStructure = New Structure("BudgetBalanceItem", BudgetFlowItem);
	ElsIf Details.Property("EditedValue", BudgetFlowItem)
		And ValueIsFilled(BudgetFlowItem) Then
		ResultingStructure = New Structure("EditedValue", BudgetFlowItem);
	EndIf;
	
	If ResultingStructure = Undefined Then
		If Not SearchMode_ Then
			Raise NStr("vi = 'Lỗi trong cấu trúc dạng ngân sách: kiểu ô giá trị không xác định';
						|ru = 'Ошибка в структуре вида бюджета: не определен тип ячейки значения';
						|en = 'Error in the budget profile structure: value cell type is not determined'; fa = 'Error in the budget profile structure: value cell type is not determined';
						|it = 'Errore nella struttura del tipo di bilancio: valore del tipo di cella non definito';
						|pl = 'Błąd w strukturze rodzaju budżetu: nie określono typu komórki wartości';
						|tr = 'Bütçe profili yapısında hata: değer hücrelerinin türleri tanımlanmamış'");
		Else
			Return Undefined;
		EndIf;
	EndIf;
	
	PeriodsUsed = New Array;
	For Each KeyAndValue In Details Do
		If ThisIsPeriodField(KeyAndValue.Key) Then
			Periodicity = FinancialReportingClientServer.PeriodicityByPeriodString(KeyAndValue.Key);
			If ValueIsFilled(Periodicity) Then
				PeriodsUsed.Add(Periodicity);
			EndIf;
		EndIf;
	EndDo;
	
	If PeriodsUsed.Count() Then
		MinimumPeriodicity = MinimumPeriodicity(PeriodsUsed);
		ColumnPeriod = FinancialReportingClientServer.PeriodStrings(MinimumPeriodicity).Period;
		ResultingStructure.Insert("PlanningPeriod", Details[ColumnPeriod]);
	Else
		ResultingStructure.Insert("PlanningPeriod", Object.BeginOfPeriod);
	EndIf;
	
	DecryptionRate = Undefined;
	If Details.Property("IndicatorName", DecryptionRate) Then
		IndicatorName = DecryptionRate;
	Else
		IndicatorName = "Sum";
	EndIf;
	
	Currency = Undefined;
	If Details.Property("Currency", Currency) Then
		ResultingStructure.Insert("Currency", Currency);
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	EmptyDimensionValue = BudgetingClientServer.EmptyDimensionValue();
	If ResultingStructure.Property("BudgetFlowItem") And ItemParameterCache[BudgetFlowItem] <> Undefined Then
		
		ArticleDetails_1 = ItemParameterCache[BudgetFlowItem];
		
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			
			DimensionKind = ArticleDetails_1["DimensionKind" + Cnt];
			TypeOfAnalyticsType = ArticleDetails_1["DimensionKind" + Cnt + "ValueType"];
			DimensionValue = EmptyDimensionValue;
			If ValueIsFilled(DimensionKind) Then
				DimensionValue = Details.AnalystValues[DimensionKind];
				If TypeOf(DimensionValue) = Type("String") Then
					DimensionValue = EmptyDimensionValue;
				EndIf;
			EndIf;
			If ValueIsFilled(TypeOfAnalyticsType) Then
				DimensionValue = BudgetingClientServer.ReducedAnalyticsValue(DimensionValue, TypeOfAnalyticsType);
			EndIf;
			ResultingStructure.Insert("Dimension" + Cnt, DimensionValue);
			
		EndDo;
		
	Else
		
		ReportAnalystProperties = BudgetReportingServerCall.ReportAnalystProperties(ObjectAndCalculationParameters.BudgetProfileDisplayParameters);
		TypeValues = ReportAnalystProperties.TypeValues;
		TypesOfReportAnalysts = ReportAnalystProperties.TypesOfReportAnalysts;
		
		For ExtensionCounter_ = 1 To MaximumNumberOfAnalysts Do
			EmptyLinkToAnalytics = PredefinedValue("ChartOfCharacteristicTypes.BudgetFlowItemDimensions.EmptyRef");
			ResultingStructure.Insert("DimensionKind" + ExtensionCounter_, EmptyLinkToAnalytics);
			ResultingStructure.Insert("Dimension" + ExtensionCounter_, EmptyDimensionValue);
		EndDo;
		
		// We get the values of the types of analytics from the decryption, arrange the collection by the number of analytics in the report as a whole.
		NumbersOfAnalyticsTypes = New ValueList;
		AnalysisOfDecryptionByNumberInReport = New Map;
		For Each KeyAndValue In Details.AnalystValues Do
			DimensionKind           = KeyAndValue.Key;
			AnalyticsIndexInReport = TypesOfReportAnalysts.Find(DimensionKind);
			If AnalyticsIndexInReport = Undefined Then
				Continue;
			EndIf;
			NumberOfAnalyticsInReport = AnalyticsIndexInReport + 1;
			DimensionValue     = KeyAndValue.Value;
			NumbersOfAnalyticsTypes.Add(NumberOfAnalyticsInReport);
			AnalysisOfDecryptionByNumberInReport.Insert(NumberOfAnalyticsInReport,
				New Structure("DimensionKind, DimensionValue", DimensionKind, DimensionValue));
		EndDo;
		NumbersOfAnalyticsTypes.SortByValue(SortDirection.Asc);
		
		// We set the numbers of the types of analytics in c 1 for this article / indicator, but in the order corresponding to the general order
		// of analytics in the report.
		Cnt = 1;
		For Each ListItem In NumbersOfAnalyticsTypes Do
			
			NumberOfAnalyticsInReport = ListItem.Value;
			DimensionKind = AnalysisOfDecryptionByNumberInReport.Get(NumberOfAnalyticsInReport).DimensionKind;
			DimensionValue = EmptyDimensionValue;
			If ValueIsFilled(DimensionKind) Then
				DimensionValue = AnalysisOfDecryptionByNumberInReport.Get(NumberOfAnalyticsInReport).DimensionValue;
				If TypeOf(DimensionValue) = Type("String") Then
					DimensionValue = EmptyDimensionValue;
				EndIf;
			EndIf;
			
			TypeOfAnalyticsValue = TypeValues[DimensionKind].ValueType;
			DimensionValue = BudgetingClientServer.ReducedAnalyticsValue(DimensionValue, TypeOfAnalyticsValue);
			ResultingStructure.Insert("Dimension" + Cnt, DimensionValue);
			ResultingStructure.Insert("DimensionKind" + Cnt, DimensionKind);
			Cnt = Cnt + 1;
			
		EndDo;
		
	EndIf;
	
	Return ResultingStructure;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	ObjectAndCalculationParameters - See BudgetReportingClientServer.ObjectStructureForCellCalculation
// 	Details - Map, Undefined -
// 	IndicatorName - String, Undefined -
// 	DecryptionOfAnalyst - Structure, Undefined -
// 	OnlyFind - Boolean - LongDesc
// Returns:
// 	FormDataCollectionItem - the line of the tabular part "Turnover of budget items". Contains including:
// 		* Note - String -
//
Function FindTurnoverStringByDecryption(ObjectAndCalculationParameters, Details, IndicatorName = Undefined, 
											DecryptionOfAnalyst = Undefined, OnlyFind = False) Export
	
	Object = ObjectAndCalculationParameters.Object;
	DecryptionOfAnalyst = ConvertDecryption(ObjectAndCalculationParameters, Details, , IndicatorName);
	PlanningPeriod   = DecryptionOfAnalyst.PlanningPeriod;
	
	RowID  = IDOfBudgetItemAnalytics(ObjectAndCalculationParameters, DecryptionOfAnalyst);
	
	Filter = New Structure();
	Filter.Insert("RowID", RowID);
	Filter.Insert("PlanningPeriod", PlanningPeriod);
	SearchResult = Object.BudgetFlowItemTurnovers.FindRows(Filter);
	
	If SearchResult.Count() = 0 Then
		
		If OnlyFind Then
			Return Undefined;
		EndIf;
		
		StringTurnover = Object.BudgetFlowItemTurnovers.Add(); // FormDataCollectionItem
		FillPropertyValues(StringTurnover, Filter);
		If ObjectAndCalculationParameters.Property("MaximumNumberInOrder") Then
			MaxNumber = ObjectAndCalculationParameters.MaximumNumberInOrder;
		ElsIf ObjectAndCalculationParameters.Property("CurCurrentNumberInOrder")
			And ValueIsFilled(ObjectAndCalculationParameters.CurCurrentNumberInOrder) Then
			MaxNumber = ObjectAndCalculationParameters.CurCurrentNumberInOrder;
		Else
			MaxNumber = MaximumNumberInOrder(Object);
		EndIf;
		StringTurnover.SerialNumber = MaxNumber + 1;
		If ObjectAndCalculationParameters.Property("MaximumNumberInOrder") Then
			ObjectAndCalculationParameters.MaximumNumberInOrder = StringTurnover.SerialNumber;
		ElsIf ObjectAndCalculationParameters.Property("CurCurrentNumberInOrder") Then
			ObjectAndCalculationParameters.CurCurrentNumberInOrder = StringTurnover.SerialNumber;
		EndIf;
		
	Else
		
		StringTurnover = SearchResult[0]; // FormDataCollectionItem
		
	EndIf;
	
	Return StringTurnover;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	ObjectAndCalculationParameters - See BudgetReportingClientServer.ObjectStructureForCellCalculation
// 	Details - See BudgetReportingServerCall.DetailsValue
// 	ValueText - String -
// 	Note - String, Undefined -
// 	FillMode - Boolean -
// Returns:
// 	Structure - LongDesc:
// * Note - String, Undefined -
// * Sum - Number -
// * AmountInCurrency - Number -
// * Count - Number -
// * Value - Number -
//
Function ReflectCellChange(ObjectAndCalculationParameters, Details, ValueText, Note = Undefined, FillMode = False) Export
	Var IndicatorName, DecryptionOfAnalyst;
	
	Object = ObjectAndCalculationParameters.Object;
	ScenarioCurrency = ObjectAndCalculationParameters.ScenarioCurrency;
	
	StringTurnover = FindTurnoverStringByDecryption(ObjectAndCalculationParameters, Details, IndicatorName, DecryptionOfAnalyst);
	If DecryptionOfAnalyst.Property("BudgetBalanceItem")
		And ValueIsFilled(DecryptionOfAnalyst.BudgetBalanceItem) Then
		// Budget estimates are calculated automatically and are not edited
		ValueText = 0;
	EndIf;
	If TypeOf(ValueText) = Type("Number") Then
		Value = ValueText;
	ElsIf IndicatorName = "Value" Then
		Value = ValueText;
	ElsIf ValueText = "#Val_" Then
		Value = 0;
	Else
		Try
			ValueAsString = StrReplace(ValueText, Chars.NBSp, "");
			ValueAsString = StrReplace(ValueText, " ", "");
			If Left(ValueAsString, 1) = "("
			   And Right(ValueAsString, 1) = ")" Then
				ValueAsString = Mid(ValueAsString, 2, StrLen(ValueAsString) - 2);
				Value = -Number(ValueAsString);
			Else
				Value = Number(ValueAsString);
			EndIf;
		Except
			Value = 0;
		EndTry;
	EndIf;
	
	PlanningPeriod = DecryptionOfAnalyst.PlanningPeriod;
	
	If Note <> Undefined Then
		StringTurnover.Note = Note;
	EndIf;
	
	If IndicatorName = "Sum" Then
		
		Currency = Undefined;
		If DecryptionOfAnalyst.Property("Currency", Currency) And Currency <> ScenarioCurrency Then
			
			StringTurnover.Sum = BudgetReportingServerCall.RecalculateAccordingToCourseTable(ObjectAndCalculationParameters,
				Value,
				PlanningPeriod,
				Currency,
				ScenarioCurrency);
			StringTurnover.AmountInCurrency = Value;
			
		Else
			
			StringTurnover.Sum = Value;
			StringTurnover.AmountInCurrency = Value;
			
		EndIf;
		
	Else
		
		StringTurnover[IndicatorName] = Value;
		
	EndIf;
	
	Result = New Structure();
	Result.Insert("Sum", StringTurnover.Sum);
	Result.Insert("AmountInCurrency", StringTurnover.AmountInCurrency);
	Result.Insert("Count", StringTurnover.Count);
	Result.Insert("Value", StringTurnover.Value);
	If Not Note = Undefined Then
		Result.Insert("Note", Note);
	EndIf;
	
	If Not FillMode And Not Object.Action = PredefinedValue(
		"Enum.TypesOfBudgetEntryFormActions.CorrectBudgetEntryForm") Then
		If StringTurnover.Sum = 0 And StringTurnover.AmountInCurrency = 0
			And StringTurnover.Count = 0
			And Not ValueIsFilled(StringTurnover.Value)
			And IsBlankString(StringTurnover.Note) Then
			
			Object.BudgetFlowItemTurnovers.Delete(StringTurnover);
			RowID = IDOfBudgetItemAnalytics(ObjectAndCalculationParameters, DecryptionOfAnalyst);
			
			Filter = New Structure();
			Filter.Insert("RowID", RowID);
			SearchResult = Object.BudgetFlowItemTurnovers.FindRows(Filter);
			If Not SearchResult.Count() Then
				FoundRow = Object.BudgetFlowItemsDimension.FindRows(New Structure("RowID", RowID));
				If FoundRow.Count() Then
					Object.BudgetFlowItemsDimension.Delete(FoundRow[0]);
				EndIf;
				FoundRow = Object.DimensionValues_.FindRows(New Structure("RowID", RowID));
				If FoundRow.Count() Then
					Object.DimensionValues_.Delete(FoundRow[0]);
				EndIf;
			EndIf;
			
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Constructor of the object structure for cell calculation
// 
// Returns:
// 	Structure - LongDesc:
// * DetailsDataAddress - String, Undefined -
// * BudgetProfileDisplayParameters - String, Undefined -
// * AddressOfExchangeRateTable - String, Undefined -
// * RequireExchangeRatesSpecificationForEachPeriod - Boolean -
// * ItemParameterCache - See BudgetingServer.FillCacheOfArticleParameters
// * ScenarioCurrency - CatalogRef.Currencies, Undefined -  
// * Object - FormDataStructure, Undefined -
Function ObjectStructureForCellCalculation() Export
	
	Result = New Structure;
	Result.Insert("Object");
	Result.Insert("ScenarioCurrency");
	Result.Insert("ItemParameterCache");
	Result.Insert("RequireExchangeRatesSpecificationForEachPeriod");
	Result.Insert("AddressOfExchangeRateTable");
	Result.Insert("BudgetProfileDisplayParameters");
	Result.Insert("DetailsDataAddress");
	
	Return Result;
	
EndFunction

// Returns the object structure for calculating a cell based on form data
// 
// Parameters:
// 	Form - ClientApplicationForm - 
// Returns:
// 	See BudgetReportingClientServer.ObjectStructureForCellCalculation
Function StructureByBudgetInstanceObject(Form) Export
	
	ObjectAndCalculationParameters = ObjectStructureForCellCalculation();
	ObjectAndCalculationParameters.Object = Form.Object;
	ObjectAndCalculationParameters.ScenarioCurrency = Form.ScenarioCurrency;
	ObjectAndCalculationParameters.ItemParameterCache = Form.ItemParameterCache;
	ObjectAndCalculationParameters.RequireExchangeRatesSpecificationForEachPeriod = Form.RequireExchangeRatesSpecificationForEachPeriod;
	ObjectAndCalculationParameters.AddressOfExchangeRateTable = Form.AddressOfExchangeRateTable;
	ObjectAndCalculationParameters.BudgetProfileDisplayParameters = Form.BudgetProfileDisplayParameters;
	ObjectAndCalculationParameters.DetailsDataAddress = Form.DetailsDataAddress;
	
	Return ObjectAndCalculationParameters;
	
EndFunction

Function PeriodParameters_(Object, DataParameters = Undefined) Export
	
	If DataParameters = Undefined Then
		DataParameters = New Structure;
	EndIf;
	
	DataParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	DataParameters.Insert("EndOfPeriod", Object.PeriodEnding);
	DataParameters.Insert("ActualDataLimit", Object.ActualDataLimit);
	
	Return DataParameters;
	
EndFunction

#EndRegion

#EndRegion


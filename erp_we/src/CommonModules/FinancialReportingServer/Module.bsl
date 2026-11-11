
#Region Public

// The function returns a table of image indexes
// 
// Returns:
//   ValueTable - Columns:
//   	* ItemKind - EnumRef.FinancialReportItemKinds - item type
//   	* NameOfAuxiliaryElement - String, CatalogRef - The element instance
//   	* PictureIndex - Number - The index of the image
//
Function ImageIndexTable() Export
	
	TableOfPictures = New ValueTable;
	TableOfPictures.Columns.Add("ItemKind", 
							New TypeDescription("EnumRef.FinancialReportItemKinds"));
	AllAccountPlans = New Array;
	If AccessRight("Read", Metadata.Catalogs.FinancialAccountingChartsOfAccounts) Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	FinancialAccountingChartsOfAccounts.Ref
		|FROM
		|	Catalog.FinancialAccountingChartsOfAccounts AS FinancialAccountingChartsOfAccounts
		|WHERE
		|	NOT FinancialAccountingChartsOfAccounts.DeletionMark
		|
		|AUTOORDER
		|";
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			AllAccountPlans.Add(Selection.Ref);
		EndDo;
	EndIf;
	For Each MetadataObject In Metadata.ChartsOfAccounts Do
		IDOfTheChartOfAccounts = Common.MetadataObjectID(MetadataObject);
		AllAccountPlans.Add(IDOfTheChartOfAccounts);
	EndDo;
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypesArray.Add(Type("CatalogRef.MetadataObjectIDs"));
	TypesArray.Add(Type("CatalogRef.FinancialAccountingChartsOfAccounts"));
	TableOfPictures.Columns.Add("NameOfAuxiliaryElement", 
							New TypeDescription(TypesArray,,New StringQualifiers(10)));
	TableOfPictures.Columns.Add("PictureIndex", 
							New TypeDescription("Number",New NumberQualifiers(3, 0)));
							
	// basic elements
	AddImageMatchingString(TableOfPictures, "ReportHeader",				"", 		0);
	AddImageMatchingString(TableOfPictures, "UneditedText",		"", 		3);
	AddImageMatchingString(TableOfPictures, "EditedText",			"", 		6);
	// indicators budgeting
	AddImageMatchingString(TableOfPictures, "BudgetFlowItem", 				"", 		9);
	AddImageMatchingString(TableOfPictures, "BudgetFlowItem", 				"SpecialPurpose", 	39);
	AddImageMatchingString(TableOfPictures, "BudgetBalanceItem",			"", 		39);
	AddImageMatchingString(TableOfPictures, "AllBudgetFlowItems", 			"", 		9);
	AddImageMatchingString(TableOfPictures, "AllBudgetBalanceItems",		"", 		39);
	AddImageMatchingString(TableOfPictures, "EditedValue", 		"", 		51);
	AddImageMatchingString(TableOfPictures, "NonFinancialItem", 		"", 		50);
	AddImageMatchingString(TableOfPictures, "DerivedItem", 		"", 		15);
	// MFP indicators
	AddImageMatchingString(TableOfPictures, "MonetaryIndicator", 		"", 		9);
	StartPosition = 52;
	Offset = 3;
	ChartOfAccountsIndex = 0;
	For Each ChartOfAccounts In AllAccountPlans Do
		IndexOf = StartPosition + ChartOfAccountsIndex * Offset;
		AddImageMatchingString(TableOfPictures, "MonetaryIndicator", ChartOfAccounts, IndexOf);
		ChartOfAccountsIndex = ChartOfAccountsIndex + 1;
	EndDo;
	AddImageMatchingString(TableOfPictures, "NonMonetaryItem", 		"", 		12);
	//Tables
	AddImageMatchingString(TableOfPictures, "TableIndicatorsInRows", 	"", 		21);
	AddImageMatchingString(TableOfPictures, "TableIndicatorsInColumns", 	"", 		21);
	AddImageMatchingString(TableOfPictures, "ComplexTable", 				"", 		21);
	AddImageMatchingString(TableOfPictures, "Columns", 					"", 		24);
	AddImageMatchingString(TableOfPictures, "Rows", 						"", 		27);
	AddImageMatchingString(TableOfPictures, "Columns", 					"Return",		46);
	AddImageMatchingString(TableOfPictures, "Rows", 						"Return", 	47);
	AddImageMatchingString(TableOfPictures, "CellsSettings", 				"", 		48);
	AddImageMatchingString(TableOfPictures, "TableCell", 				"", 		49);
	// other elements
	AddImageMatchingString(TableOfPictures, "GroupFormula", 			"", 		18);
	AddImageMatchingString(TableOfPictures, "TotalByGroup", 				"", 		18);
	AddImageMatchingString(TableOfPictures, "Dimension", 					"", 		30);
	AddImageMatchingString(TableOfPictures, "Group", 						"", 		36);
	AddImageMatchingString(TableOfPictures, "", 							"Group", 	42);
	AddImageMatchingString(TableOfPictures, "RowColumn", 				"", 		45);
	
	Return TableOfPictures;
	
EndFunction

// Temporary table Manager function that contains a table of indexes for financial report elements
// 
// Returns:
//   TempTablesManager - temporary table Manager
//
Function TemporaryTableOfImageIndexes() Export
	
	TableOfPictures = ImageIndexTable();
	
	QueryText = 
	"SELECT
	|	ImageIndexTable.ItemKind,
	|	ImageIndexTable.NameOfAuxiliaryElement,
	|	ImageIndexTable.PictureIndex
	|INTO ImageIndexTable
	|FROM
	|	&ImageIndexTable AS ImageIndexTable
	|";
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ImageIndexTable", TableOfPictures);
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

// A function of a parameter value by name
//
// Parameters:
//   Parameters - Structure - parameter structure
//   ParameterName - String - the key is in the parameter structure
//   DefaultValue - Arbitrary - (Optional)the key value of the structure,
//                                        if the value of the transmitted key is not found.
//
// Returns:
//   Arbitrary - The value of the key.
//
Function GetParameter(Parameters,ParameterName,DefaultValue = Undefined) Export
	
	ParameterValue = DefaultValue;
	// if a parameter with the same name was not found
	If Not Parameters.Property(ParameterName,ParameterValue) Then//return the default value
		Return DefaultValue;
	EndIf;
	
	Return ParameterValue;
	
EndFunction

// The procedure converts the query result to a tree of values
//
// Parameters:
//  QueryResult  - QueryResult - result of the request to be converted
//  Tree  - ValueTree - tree where the query result should be loaded.
//
Procedure QueryResultInTree(QueryResult, Tree) Export
	
	QueryTree = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	AddRowsToTree(QueryTree.Rows, Tree.Rows);
	
EndProcedure

// Returns a cache of additional details
// for budget view elements.
//
// Parameters:
//  ReportKind  - CatalogRef.BudgetProfiles - link to the report view.
//
// Returns:
//   ValueTable   - table of additional Attributes and their values:
//     * ReportItem - CatalogRef.FinancialReportItems - link to the report element
//     * Attribute       - ChartOfCharacteristicTypesRef.ItemAttributesOfFinancialReports - Attribute
//     * Value       - Characteristic.ItemAttributesOfFinancialReports - the value of the props
//
Function CacheAdditionalDetails(ReportKind) Export
	
	Query = New Query();
	QueryText = 
	"SELECT
	|	CatalogTabularSection.Ref AS ReportItem,
	|	CatalogTabularSection.Attribute,
	|	CatalogTabularSection.Value
	|FROM
	|	Catalog.FinancialReportItems.ItemKindAttributes AS CatalogTabularSection
	|		LEFT JOIN Catalog.FinancialReportItems AS Catalog
	|		ON (Catalog.Ref = CatalogTabularSection.Ref)
	|WHERE
	|	Catalog.Owner = &ReportKind";
	
	If TypeOf(ReportKind) <> Type("CatalogRef.BudgetProfiles") Then
		QueryText = QueryText + AddDetailsOfRelatedElements();
	EndIf;
	Query.Text = QueryText;
	Query.SetParameter("ReportKind", ReportKind);
	
	Table = Query.Execute().Unload();
	Table.Indexes.Add("ReportItem, Attribute");
	Return Table;
	
EndFunction

// Returns a cache of additional details for report view elements.
//
// Parameters:
//  ReportKind  - CatalogRef.BudgetProfiles, CatalogRef.FinancialReportTypes - link to the report view.
//
// Returns:
//   ValueTable   - table of additional Attributes and their values:
//    *ReportItem - CatalogRef.FinancialReportItems - 
//    *Description - String -
//
Function CacheAdditionalElementFields(ReportKind) Export
	
	Query = New Query();
	QueryText = 
	"SELECT
	|	FinancialReportItemsAdditionalFields.Ref AS ReportItem,
	|	FinancialReportItemsAdditionalFields.Description AS Description
	|FROM
	|	Catalog.FinancialReportItems.AdditionalFields AS FinancialReportItemsAdditionalFields
	|		LEFT JOIN Catalog.FinancialReportItems AS Catalog
	|		ON (Catalog.Ref = FinancialReportItemsAdditionalFields.Ref)
	|WHERE
	|	Catalog.Owner = &ReportKind
	|";
	
	Query.Text = QueryText;
	Query.SetParameter("ReportKind", ReportKind);
	
	Table = Query.Execute().Unload();
	Table.Indexes.Add("ReportItem");
	Return Table;
	
EndFunction

// Returns a cache of account plans that are used in report elements
//
// Parameters:
//  ReportKind  - CatalogRef.FinancialReportTypes - link to the report view.
//
// Returns:
//   ValueTable   - table of additional Attributes and their values:
//    * ReportItem - CatalogRef.FinancialReportItems - 
//    * ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - 
//                 - CatalogRef.MetadataObjectIDs - 
//
Function CacheAccountPlansForReportElements(ReportKind) Export
	
	Query = New Query();
	QueryText = 
	"SELECT
	|	CatalogTabularSection.Ref AS ReportItem,
	|	CatalogTabularSection.Attribute,
	|	&ChartOfAccounts AS ChartOfAccounts
	|FROM
	|	Catalog.FinancialReportItems.ItemKindAttributes AS CatalogTabularSection
	|		LEFT JOIN Catalog.FinancialReportItems AS Catalog
	|		ON (Catalog.Ref = CatalogTabularSection.Ref)
	|WHERE
	|	&FilterReportKind
	|	AND CatalogTabularSection.Attribute = VALUE(ChartOfCharacteristicTypes.ItemAttributesOfFinancialReports.GLAccount_)
	|
	|UNION ALL
	|
	|SELECT
	|	CatalogTabularSection.Ref AS ReportItem,
	|	CatalogTabularSection.Attribute,
	|	&ChartOfAccounts AS ChartOfAccounts
	|FROM
	|	Catalog.FinancialReportItems.ItemKindAttributes AS CatalogTabularSection
	|		INNER JOIN Catalog.FinancialReportItems AS Catalog
	|		ON Catalog.LinkedItem1 = CatalogTabularSection.Ref
	|			AND &FilterReportKind
	|			AND Catalog.LinkedItem1 <> VALUE(Catalog.FinancialReportItems.EmptyRef)";
	If ValueIsFilled(ReportKind) Then
		FilterReportKind = "Catalog.Owner = &ReportKind";
	Else
		FilterReportKind = "TRUE";
	EndIf;
	QueryText = StrReplace(QueryText, "&FilterReportKind", FilterReportKind);
	
	ExpressionChartOfAccounts = 
	"CASE WHEN VALUETYPE(CatalogTabularSection.Value) = &TypeInternational THEN CatalogTabularSection.Value.ChartOfAccounts";
	Query.SetParameter("TypeInternational", FinancialAccountingClientServer.TypeChartOfAccounts());
	
	TemplateForSelectingChartOfAccounts = 
	"WHEN VALUETYPE(CatalogTabularSection.Value) = &TypeChartOfAccounts THEN &ChartOfAccountsID";
	
	For Each MetadataObject In Metadata.ChartsOfAccounts Do
		
		ChartOfAccountsTypeParameter = "Type" + MetadataObject.Name;
		Query.SetParameter(ChartOfAccountsTypeParameter, Type("ChartOfAccountsRef." + MetadataObject.Name));
		
		ChartOfAccountsIDParameter = "Id" + MetadataObject.Name;
		Query.SetParameter(ChartOfAccountsIDParameter, Common.MetadataObjectID(MetadataObject));
		
		ChartOfAccountsCondition = StrReplace(TemplateForSelectingChartOfAccounts, "&TypeChartOfAccounts", "&" + ChartOfAccountsTypeParameter);
		ChartOfAccountsCondition = StrReplace(ChartOfAccountsCondition, "&ChartOfAccountsID", "&" + ChartOfAccountsIDParameter);
		
		ExpressionChartOfAccounts = ExpressionChartOfAccounts + Chars.LF + ChartOfAccountsCondition;
		
	EndDo;
	ExpressionChartOfAccounts = ExpressionChartOfAccounts + Chars.LF + "ELSE UNDEFINED END";
	QueryText = StrReplace(QueryText, "&ChartOfAccounts", ExpressionChartOfAccounts);   
	
	Query.SetParameter("ReportKind", ReportKind);
	
	Query.Text = QueryText;
	
	Table = Query.Execute().Unload();
	Table.Indexes.Add("ReportItem, ChartOfAccounts");
	Return Table;
	
EndFunction

// Returns the value of the additional details
// of the report element (from the table part "additional details").
//
// Parameters:
//  ObjectReference  - CatalogRef.FinancialReportItems - link
//                    to the element for which we get an additional element.
//  Attribute  - String - The name of the props
//            - ChartOfCharacteristicTypesRef.ItemAttributesOfFinancialReports - link to the props.
//  AttributeCache - See CacheAdditionalDetails
//  
// Returns:
//   Arbitrary, Undefined - the value of the props.
//
Function ValueOfAdditionalProps(Val ObjectReference, Val Attribute, AttributeCache) Export
	
	If TypeOf(Attribute) = Type("String") Then
		Attribute = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports[Attribute];
	EndIf;
	
	TheStructureOfTheSearch = New Structure();
	If ValueIsFilled(ObjectReference) Then
		TheStructureOfTheSearch.Insert("ReportItem", ObjectReference);
	EndIf;
	TheStructureOfTheSearch.Insert("Attribute", Attribute);
	FoundRows = AttributeCache.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() Then
		Return FoundRows[0].Value;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns the chart of accounts that the report item belongs to.
// If the report element does not refer to an accounting report account, it is returned Undefined.
// 
// Parameters:
//  ObjectReference  - CatalogRef.FinancialReportItems - link
//                    to the element for which we get an additional element.
//  CacheAccountPlansForReportElements - See CacheAccountPlansForReportElements
//
// Returns:
//   CatalogRef.FinancialAccountingChartsOfAccounts, CatalogRef.MetadataObjectIDs, Undefined - 
//
Function ChartOfAccountsValueOfReportElement(Val ObjectReference, CacheAccountPlansForReportElements) Export
	
	TheStructureOfTheSearch = New Structure("ReportItem", ObjectReference);
	FoundRows = CacheAccountPlansForReportElements.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() Then
		Return FoundRows[0].ChartOfAccounts;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns a view of the report item
//
// Parameters:
//  ItemKind  - EnumRef.FinancialReportItemKinds - item type
//  ReportItem - CatalogRef.FinancialReportItems - link to an element
//  DimensionValue - Arbitrary - additional Analytics value
//  Description - String - the name of the element
//  AttributeCache - ValueTable - cache of additional details of the budget type.
//
// Returns:
//   String   - the value of analytics.
//
Function GetElementPresentation(ItemKind, ReportItem, DimensionValue, Description, AttributeCache) Export
	
	AddAttributes = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports;
	
	If ItemKind = Enums.FinancialReportItemKinds.Dimension Then
		
		DimensionType = ValueOfAdditionalProps(ReportItem,
			AddAttributes.DimensionType,
			AttributeCache);
		
		If DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
			If ValueIsFilled(DimensionValue) Then
				Return DimensionValue;
			EndIf;
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Organization Then
			Return ValueOfAdditionalProps(ReportItem, AddAttributes.Organization, AttributeCache);
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Department Then
			Return ValueOfAdditionalProps(ReportItem, AddAttributes.Department, AttributeCache);
		ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
			Return ValueOfAdditionalProps(ReportItem, AddAttributes.Scenario, AttributeCache);
		EndIf;
		
	EndIf;
	
	Return Description;
	
EndFunction

// Returns a view of additional report fields
//
// Parameters:
//  ReportItem - CatalogRef.FinancialReportItems - link to an element
//  CacheOfAdditionalFields - ValueTable - cache of additional Attributes of the budget type:
//   *ReportItem - CatalogRef.FinancialReportItems - Report item.
//   *Description - String - name of the element.
//
// Returns:
//   String - the value of analytics.
//
Function GetPresentationOfAdditionalFields(ReportItem, CacheOfAdditionalFields) Export
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("ReportItem", ReportItem);
	FoundRows = CacheOfAdditionalFields.FindRows(TheStructureOfTheSearch); // ValueTable - 
	
	Result = "";
	For Each AdditionalField In FoundRows Do
		Result = Result + ?(IsBlankString(Result), "", ", ") + AdditionalField.Description;
	EndDo;
	
	Return Result;
	
EndFunction

// Gets the type description based on the passed value
// Parameters:
//  Value - AnyRef - the value for which you want to get a type description.
//
// Returns:
//   TypeDescription - description of the type of the transmitted value.
//
Function TypeDescriptionByValue(Value) Export
	
	TypesArray = New Array;
	TypesArray.Add(TypeOf(Value));
	Return New TypeDescription(TypesArray);
	
EndFunction

// Fills in the field selection tree based on the available fields in the data layout schema
// Called from the forms :
// 		- settings for filling in the budgeting analysis
// 		- settings for filling in the international accounting sub-account.
// 
// Parameters:
// 	Form - ClientApplicationForm - Form for selecting a fill-in field:
// 	  * ValueType - TypeDescription - operands with types included in the specified type description can be selected.
// 	  * AdditionalPropertyID - String - id of the additional Attribute/information added from the form.
// 	  * AddressOfDataCompositionSchema - String - The address of the temporary storage containing the address of the layout scheme by which the operand tree is populated.
// 	  * MaximumRowExpansionLevel - Number - Maximum line sweep level. If the value is not set, then the scan level is not limited.
// 	  * SelectionTree - FormDataTree - The tree on the form into which the operand tree is loaded.
// 	  * CurrentExpression - String - the Cur expression of the selected operand.
// 
Procedure FillInAvailableFieldsAccordingToDataLayoutScheme(Form) Export
	
	CompositionSchema = GetFromTempStorage(Form.AddressOfDataCompositionSchema);
	
	OperandsTree = ProcessingOfFormulas.GetEmptyOperandTree();
	SweepRestrictions = ProcessingOfFormulas.LimitationsOfOperandSweep();
	SweepRestrictions.MaximumRowExpansionLevel = Form.MaximumRowExpansionLevel;
	ProcessingOfFormulas.AddAvailableFieldsToTreeUsingLayoutScheme(OperandsTree, CompositionSchema);
	
	ProcessingOfFormulas.LoadOperandTreeIntoTreeOfForm(Form.SelectionTree, OperandsTree);
	
	If ValueIsFilled(Form.CurrentExpression) Then
		OperandParts = ProcessingOfFormulasClientServer.OperandParts(Form.CurrentExpression);
		ExpandRowsOfOperandTreeByCurExpression(Form, Form.SelectionTree, OperandParts, SweepRestrictions);
	EndIf;
	
	// Processing restrictions by value type or identifier add.the props on the form.
	For Each AddedRow In Form.SelectionTree.GetItems() Do
		CheckWhetherAddedRowsCanBeSelectedByTypeRecursively(AddedRow, Form);
	EndDo;
	
EndProcedure

// Returns a flag indicating that the field is suitable for selection by value type.
// 
// Parameters:
// 	ValueTreeRow - FormDataTreeItem - Operand Tree String:
// 	 *Id - String - ID of the current part of the operand.
// 	SpecialPurposeType - TypeDescription - target type (strings of this type can be selected).
// 	AdditionalPropertyID - String - ID of the added additional banking details.
// Returns:
// 	Boolean - True if the field is suitable for selection.
//
Function SuitableSelectionField(ValueTreeRow, SpecialPurposeType, AdditionalPropertyID = "") Export
	
	Result = False;
	
	If ValueTreeRow.TreeItemType = "TabularSection" Then
		Return Result;
	EndIf;
	
	If ValueIsFilled(AdditionalPropertyID) Then
		Result = (ValueTreeRow.Id = AdditionalPropertyID);
	Else
		For Each Type In ValueTreeRow.ValueType.Types() Do
			If SpecialPurposeType.ContainsType(Type) Then
				Result = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

// Generates a string representation of the specified interval for the specified date
//
// Parameters:
//  PeriodDate_  - Date - the date for which you want to create a string representation of the interval
//  Periodicity  - EnumRef.Periodicity, Number - interval to form a representation of
//  LanguageCode - String - language code for applying the desired date formatting.
//
// Returns:
//  String - string representation of the interval.
//
Function IntervalPresentation(PeriodDate_, Val Periodicity, LanguageCode = "") Export
	
	If TypeOf(PeriodDate_) <> Type("Date") Then
		Return PeriodDate_;
	EndIf;
	
	If Periodicity = 6 Then
		Periodicity = Enums.Periodicity.Day;
	ElsIf Periodicity = 7 Then
		Periodicity = Enums.Periodicity.Week;
	ElsIf Periodicity = 8 Then
		Periodicity = Enums.Periodicity.TenDays;
	ElsIf Periodicity = 9 Then
		Periodicity = Enums.Periodicity.Month;
	ElsIf Periodicity = 10 Then
		Periodicity = Enums.Periodicity.Quarter;
	ElsIf Periodicity = 11 Then
		Periodicity = Enums.Periodicity.HalfYear;
	ElsIf Periodicity = 12 Then
		Periodicity = Enums.Periodicity.Year;
	EndIf;
	
	StartDate = BeginOfPeriod(PeriodDate_, Periodicity);
	EndDate = EndOfPeriod(PeriodDate_, Periodicity);
	If Periodicity = Enums.Periodicity.HalfYear And Month(StartDate) = 7 
			And (LanguageCode = "" Or LanguageCode = "ru") Then
		Return "2 " + NStr("vi = 'nửa năm';
							|ru = 'полугодие';
							|en = 'half-year'; fa = 'نیم‌سال';
							|it = 'semestre';
							|pl = 'half-year';
							|tr = 'yarıyıl'") + " " + Format(Year(StartDate), "NG=0") + " g.";
	EndIf;
	
	FormatString = ?(ValueIsFilled(LanguageCode), "L="+LanguageCode+";", "") + "FP = True";   
	Return PeriodPresentation(StartDate, EndDate, FormatString);
	
EndFunction

// Returns the start date of the interval
//
// Parameters:
//  PeriodDate_  - Date - date included in the interval
//  Periodicity  - EnumRef.Periodicity - the interval to form a representation of.
//
// Returns:
//   Date - the start date of the transmitted interval.
//
Function BeginOfPeriod(Val PeriodDate_, Periodicity) Export
	
	BeginOfPeriod = PeriodDate_;
	If Periodicity = Enums.Periodicity.Day Then
		BeginOfPeriod = BegOfDay(PeriodDate_);
		
	ElsIf Periodicity = Enums.Periodicity.Week Then
		BeginOfPeriod = BegOfWeek(PeriodDate_);
		
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		If Day(PeriodDate_) <= 10 Then
			BeginOfPeriod = Date(Year(PeriodDate_), Month(PeriodDate_), 1);
		ElsIf Day(PeriodDate_) <= 20 Then
			BeginOfPeriod = Date(Year(PeriodDate_), Month(PeriodDate_), 11);
		Else
			BeginOfPeriod = Date(Year(PeriodDate_), Month(PeriodDate_), 21);
		EndIf;
		
	ElsIf Periodicity = Enums.Periodicity.Month Then
		BeginOfPeriod = BegOfMonth(PeriodDate_);
		
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		BeginOfPeriod = BegOfQuarter(PeriodDate_);
		
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		If Month(BeginOfPeriod) <= 6 Then
			BeginOfPeriod = Date(Year(PeriodDate_),1,1);
		Else
			BeginOfPeriod = Date(Year(PeriodDate_),7,1);
		EndIf;
		
	ElsIf Periodicity = Enums.Periodicity.Year Then
		BeginOfPeriod = BegOfYear(PeriodDate_);
		
	EndIf;
	
	Return BeginOfPeriod;
	
EndFunction // The beginning of the period()

// Returns the end date of the interval
//
// Parameters:
//  PeriodDate_  - Date - date included in the interval
//  Periodicity  - EnumRef.Periodicity - the interval to form a representation of.
//
// Returns:
//   Date - the end date of the transmitted interval.
//
Function EndOfPeriod(Val PeriodDate_, Periodicity) Export
	
	EndOfPeriod = PeriodDate_;
	If Periodicity = Enums.Periodicity.Day Then
		EndOfPeriod = EndOfDay(PeriodDate_);
		
	ElsIf Periodicity = Enums.Periodicity.Week Then
		EndOfPeriod = EndOfWeek(PeriodDate_);
		
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		If Day(PeriodDate_) <= 10 Then
			EndOfPeriod = EndOfDay(Date(Year(PeriodDate_), Month(PeriodDate_), 10));
		ElsIf Day(PeriodDate_) <= 20 Then
			EndOfPeriod = EndOfDay(Date(Year(PeriodDate_), Month(PeriodDate_), 20));
		Else
			EndOfPeriod = EndOfMonth(PeriodDate_);
		EndIf;
		
	ElsIf Periodicity = Enums.Periodicity.Month Then
		EndOfPeriod = EndOfMonth(PeriodDate_);
		
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		EndOfPeriod = EndOfQuarter(PeriodDate_);
		
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		If Month(EndOfPeriod) <= 6 Then
			EndOfPeriod = Date(Year(PeriodDate_),6,30,23,59,59);
		Else
			EndOfPeriod = Date(Year(PeriodDate_),12,31,23,59,59);
		EndIf;
		
	ElsIf Periodicity = Enums.Periodicity.Year Then
		EndOfPeriod = EndOfYear(PeriodDate_);
		
	EndIf;
	
	Return EndOfPeriod;
	
EndFunction // End of the period()

#Region ProceduresAndFunctionsForOperationOfSSCD
// Deprecated. You should use a new one (See DataCompositionServer.EmptyCircuit)
// Returns a new DCS schema.
//
// Parameters:
//  SourceName  - String - name of the data source for the new layout schema (optional by default " data Source1")
//  SourceType  - String - the data source type defines the data layout scheme (optional by default "Local").
//
// Returns:
//  DataCompositionSchema - new data layout scheme.
//
Function NewScheme(SourceName = "DataSource1", SourceType = "Local") Export
	
	Return DataCompositionServer.EmptyCircuit(SourceName, SourceType);
	
EndFunction

// Deprecated. You should use a new one (See DataCompositionServer.AddEmptyDataSet)
// Returns a reference to a new data set of the specified type in the transmitted data layout schema.
//
// Parameters:
//  DCSchema   - DataCompositionSchema - data layout diagram in which to create a new set
//  SetType - Type - The type of the new set (optional by default, "set of new data schemas")
//                   The type("Set of new data schemas") The type("Set of new data schemas")
//                   The type ("Set of New data schemas").
//  SetName - String - name of the new set (optional by default, "Typeset1").
//
// Returns:
//   DataCompositionSchemaDataSetQuery - a new set of data
//   of a given type, a set of data combinations of a given type, a new set of data of a given type, a set of data objects of a given type, a new set of data of a
//   given type.
//
Function NewSet(DCSchema, SetType = Undefined, SetName = "DataSet1") Export
	
	If DCSchema = Undefined Then
		DCSchema = DataCompositionServer.EmptyCircuit();
	EndIf;
	
	NewSet = DataCompositionServer.AddEmptyDataSet(DCSchema, SetType, SetName);
	
	Return NewSet;
	
EndFunction

// Returns a new data layout schema with a new data set of the type "set of data setedobjectscomposedata".
//
// Parameters:
//  ObjectName  - String - name of the new set
//  SchemaSet  - DataCompositionSchemaDataSetObject - variable that will contain a reference to the new
//                                                         data set (optional).
//
// Returns:
//  DataCompositionSchema - new data layout scheme.
//
Function NewSchemaSetObject(ObjectName, SchemaSet = Undefined) Export
	
	DCSchema = DataCompositionServer.EmptyCircuit();
	
	SchemaSet = DataCompositionServer.AddEmptyDataSet(DCSchema, Type("DataCompositionSchemaDataSetObject"), ObjectName);
	
	SchemaSet.ObjectName = ObjectName;
	
	Return DCSchema;
	
EndFunction

// Returns a reference to a new field in the passed dataset
//
// Parameters:
//  DataSet  - DataCompositionSchemaDataSetQuery, DataCompositionSchemaDataSetObject - the data set
//      to create a new field in.
//  Field         - String - name of the new data layout schema field
//  DataPath  - String - the data path of the new field configuration data (optional, defaults to "")
//  Title    - String - the title of the new field configuration data (optional, defaults to "")
//  ValueType  - TypeDescription - data type of the new data layout schema field (optional, Undefined by default).
//
// Returns:
//  DataCompositionSchemaDataSetField - description of the return value.
//
Function NewSetField(DataSet, Field, DataPath = "", Title = "", ValueType = Undefined) Export
	
	If IsBlankString(DataPath) Then
		DataPath = Field;
	EndIf;
	
	If IsBlankString(Title) Then
		Title = Field;
	EndIf;
	
	NewField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	NewField.Field = Field;
	NewField.DataPath = DataPath;
	NewField.Title = Title;
	If ValueType <> Undefined Then
		NewField.ValueType = ValueType;
	EndIf;
	
	Return NewField;
	
EndFunction

// Returns a reference to the new resource in the passed data layout scheme.
//
// Parameters:
//  DCSchema  - DataCompositionSchema - data layout diagram where you need to create a new resource.
//  DataPath  - String - the data path of the new data layout schema resource.
//  Aggregate  - String - aggregate function of the new resource (optional by default "sum").
//  ResourceExpression - String - expression for calculating a new resource (optional).
//
// Returns:
//   DataCompositionSchemaTotalField - a link to a new data layout schema resource.
//
Function NewResource(DCSchema, DataPath, Aggregate = "Sum", ResourceExpression = "") Export
	
	NewResource = DCSchema.TotalFields.Add();
	NewResource.DataPath = DataPath;
	NewResource.Expression = Aggregate + "("+ NewResource.DataPath +")";
	If Not IsBlankString(ResourceExpression) Then
		NewResource.Expression = ResourceExpression;
	EndIf;
	
	Return NewResource;
	
EndFunction

// Returns a reference to the new calculated field in the passed data layout scheme.
//
// Parameters:
//  DataCompositionSchema - DataCompositionSchema - data layout diagram where you need to create a new
//                                                  calculated field.
//  DataPath           - String - the data path of the calculated field of the data layout diagram.
//  FieldExpression         - String - expression for calculating a new calculated field.
//  Title             - String - header of the new calculated field (optional).
//  SearchAndReFill  - Boolean - True - add a new one and fill in or re-fill the found field, 
//                                   False - add a new one and fill it in without searching for duplicates, 
//                                   Undefined - add a new one and fill in or leave the found field unchanged. 
//                                   The default value is False.
//  ValueType           - TypeDescription - Description of the types of the calculated field.
//                        - Undefined - The value type will not be set, it is Undefined by default.
//
// Returns:
//  DataCompositionSchemaCalculatedField - a reference to the new calculated field of the data layout scheme.
//
Function NewCalculatedField(DataCompositionSchema, DataPath, FieldExpression, Title = "", SearchAndReFill = False, ValueType = Undefined) Export
	
	// Search or create
	FieldAdded = False;
	If SearchAndReFill = False Then
		FieldToEval = DataCompositionSchema.CalculatedFields.Add();
		FieldAdded = True;
	Else
		FieldToEval = DataCompositionSchema.CalculatedFields.Find(DataPath);
		FieldExists = FieldToEval <> Undefined;
		
		If Not FieldExists Then
			FieldToEval = DataCompositionSchema.CalculatedFields.Add();
			FieldAdded = True;
		EndIf;
	EndIf;
	
	// FillType
	If FieldAdded Or Not SearchAndReFill = Undefined Then
		FieldToEval.DataPath = DataPath;
		FieldToEval.Expression = FieldExpression;
		If Not IsBlankString(Title) Then
			FieldToEval.Title = Title;
		EndIf;
		
		If Not ValueType = Undefined Then
			FieldToEval.ValueType = ValueType;
		EndIf;
	EndIf;
	
	Return FieldToEval;
	
EndFunction

// Returns a reference to the new resource by the new calculated field in the passed data layout scheme.
//
// Parameters:
//  Schema  - DataCompositionSchema - data layout diagram where you need to create a new resource
//  DataPath  - String - data path of the new calculated field and data layout schema resource
//  FieldExpression  - String - expression for calculating a new calculated field (optional by default " Undefined")
//  Aggregate  - String - aggregate function of the new resource (optional by default " Maximum")
//  ResourceExpression  - String - expression for calculating a new resource (optional).
//
// Returns:
//   DataCompositionSchemaTotalField - a link to a new data layout schema resource.
//
Function NewCalculatedResource(Schema, DataPath, FieldExpression = "Undefined", Aggregate = "Max", ResourceExpression = "") Export
	
	NewCalculatedField = NewCalculatedField(Schema, DataPath, FieldExpression);
	Resource = NewResource(Schema, DataPath, Aggregate, ResourceExpression);
	
	Return Resource;
	
EndFunction

// Returns a reference to the new selection field in the passed data layout schema structure.
//
// Parameters:
//  DCStructure - DataCompositionGroup - the structure of the layout in which you want to add a new selection field.
//                Table of data components - the structure of the layout scheme to which you want to add a new selection field.
//                Groupingtablecomposedata-structure of the layout scheme to which you want to add a new selection field.
//  Field  - String - the data path of the new selection field.
//  Title  - String - title of the new selection field (optional by default "Field").
//
// Returns:
//   DataCompositionSelectedField - a link to the new data layout scheme selection field.
//
Function NewSelectionField(DCStructure, Field, Title = "") Export
	
	NewSelectionField = DCStructure.Selection.Items.Add(Type("DataCompositionSelectedField"));
	NewSelectionField.Use = True;
	NewSelectionField.Field = New DataCompositionField(Field);
	NewSelectionField.Title = ?(IsBlankString(Title),Field,Title);
	
	Return NewSelectionField;
	
EndFunction

// Returns a reference to the new grouping in the passed data layout schema structure.
//
// Parameters:
//  DCStructure  - DataCompositionGroup - structure of the layout diagram to add a new grouping to.
//                 Groupingtablecomposedata-the structure of the layout diagram to which you want to add a new grouping.
//                 Collection of elements structuresconfigurationcomposed data-the structure of the layout diagram to which you want to add a new grouping.
//                 Collectionelementsstructure tableComposition data - the structure of the layout diagram to which you want to add a new grouping.
//  NameOfDimensionField  - String - name of the grouping field.
//  GroupType  - DataCompositionGroupType - type of grouping Elements (non-Hierarchies), Hierarchy, only Hierarchy.
//  AddDimensionsWithSameName - Boolean - Flag for adding a nested grouping field of the same name. The default value is True.
//
// Returns:
//   DataCompositionGroup - a link to the new grouping of the data layout scheme.
//
Function NewGrouping(DCStructure, NameOfDimensionField = "", GroupType = Undefined, AddDimensionsWithSameName = True) Export
	
	If TypeOf(DCStructure) = Type("DataCompositionGroup") Then
		Group = DCStructure.Structure.Add(Type("DataCompositionGroup"));
		
	ElsIf TypeOf(DCStructure) = Type("DataCompositionSettingStructureItemCollection") Then
		Group = DCStructure.Add(Type("DataCompositionGroup"));
		
	ElsIf TypeOf(DCStructure) = Type("DataCompositionTableStructureItemCollection") Then
		Group = DCStructure.Add();
		
	ElsIf TypeOf(DCStructure) = Type("DataCompositionTableGroup") Then
		Group = DCStructure.Structure.Add();
		
	Else
		Return Undefined;
	EndIf;
	
	If AddDimensionsWithSameName Then
		NewDimensionField(Group, NameOfDimensionField, GroupType);
	EndIf;
	
	Group.Use = True;
	Group.Name = NameOfDimensionField;
	Group.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	
	Return Group;
	
EndFunction

// Returns a reference to the new grouping field in the passed data layout schema grouping.
//
// Parameters:
//  Group  - DataCompositionGroup - structure of the layout diagram to add a new grouping to.
//  NameOfDimensionField  - String - name of the grouping field.
//  GroupType  - DataCompositionGroupType - type of grouping (optional, Undefined by default).
//
// Returns:
//   DataCompositionGroupField - a link to the new data layout schema grouping field.
//
Function NewDimensionField(Group, NameOfDimensionField = "", GroupType = Undefined) Export
	
	GroupingField = Group.GroupFields.Items.Add(Type("DataCompositionGroupField"));
	GroupingField.Use = True;
	If Not IsBlankString(NameOfDimensionField) Then
		GroupingField.Field = New DataCompositionField(NameOfDimensionField);
	EndIf;
	If ValueIsFilled(GroupType) Then
		GroupingField.GroupType = GroupType;
	EndIf;
	
	Return GroupingField;
	
EndFunction

// Returns a reference to the new order element in the passed data layout schema setting.
//
// Parameters:
//  ComposerSettings - DataCompositionSettingsComposer -
//                          Customizationcomposedata - settings of the layout scheme to which you want to add a new order.
//  FieldName - String -
//            Precompounding - field layout on which you want to set sorting (optional).
//  Sort  - String - the sort direction is "ASCENDING", "DESCENDING" (optional, defaults to "ASC").
//
// Returns:
//   DataCompositionOrderItem - a link to a new element of the data layout scheme settings order.
//
Function NewOrder(ComposerSettings, FieldName = "", Sort = "ASC") Export
	
	DCSettings = ComposerSettings;
	If TypeOf(ComposerSettings) = Type("DataCompositionSettingsComposer") Then
		DCSettings = ComposerSettings.Settings;
	EndIf;
	
	NewOrder = DCSettings.Order.Items.Add(Type("DataCompositionOrderItem"));
	NewOrder.Use = True;
	If Not IsBlankString(FieldName) Then
		NewOrder.Field = New DataCompositionField(FieldName);
	EndIf;
	NewOrder.OrderType = DataCompositionSortDirection[Sort];
	
	Return NewOrder;
	
EndFunction

// Sets the output parameter in the passed data layout scheme settings
//
// Parameters:
//  ComposerSettings - DataCompositionSettingsComposer -
//                          Customizationcomposedata - settings of the layout scheme.
//  ParameterName - String - parameter name.
//  Value  - Arbitrary - value of the output parameter (optional).
//  Use  - Boolean - using the output parameter (optional, True by default).
//
Procedure SetOutputParameter(ComposerSettings, ParameterName, Value = Undefined, Use = True) Export
	
	DCSettings = ComposerSettings;
	If TypeOf(ComposerSettings) = Type("DataCompositionSettingsComposer") Then
		DCSettings = ComposerSettings.Settings;
	EndIf;
	SetParameter(DCSettings.OutputParameters, ParameterName, Value, Use);
	
EndProcedure

// Sets the limits of the dataset field of the pattern layout data
//
// Parameters:
//  DCSchema - DataCompositionSchema - the circuit layout data.
//  FieldsNames - String - comma-separated field names for which restrictions must be set.
//  FieldRestriction - String - restriction of the "Grouping", "field", "Order", "Condition" fields.
//
Procedure SetFieldLimit(DCSchema, FieldsNames, FieldRestriction) Export
	
	FieldRestrictionValue = True;
	ValueOfPropsRestriction = Undefined;
	RestrictingProps = Undefined;
	If RestrictingProps = Undefined Then
		RestrictingProps = FieldRestriction;
	EndIf;
	
	If ValueOfPropsRestriction = Undefined Then
		ValueOfPropsRestriction = FieldRestrictionValue;
	EndIf;
	
	FieldArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FieldsNames);
	For Each DataSet In DCSchema.DataSets Do
		For Each DataPath In FieldArray Do
			Field = DataSet.Fields.Find(DataPath);
			If Field <> Undefined Then
				Field.UseRestriction[FieldRestriction] = FieldRestrictionValue;
				Field.AttributeUseRestriction[RestrictingProps] = ValueOfPropsRestriction;
			EndIf;
		EndDo;// by data set fields
	EndDo;// by data sets of the SCD
	
EndProcedure

// Sets the role of the data set field of the data layout schema
//
// Parameters:
//  DataSet - DataCompositionSchemaDataSetQuery -
//                A set of data layout schemas is a data set of the data layout scheme.
//  DataPath - String - name of the field to set the layout schema role for.
//  RoleOfField  - Structure - keys - the key value of the structure:
//		The expression of the type of count is "".
//		GruppaOstatka - "".
//		Ignore Null values - False.
//		The Measurement Is A Lie.
//		The period number is 0.
//		Mandatory - A Lie.
//		The Balance Is a Lie.
//		Half of the account - "".
//		Requisitioning measurements is A Lie.
//		Parental measurement - "".
//		The Bill Is A Lie.
//		Type Bookgalterskooostatka - Type bookgalterskooostatkomponovkid.No, it's not.
//		Typostat - Typostat of the combined data.No.
//		Tipperiod - tipperiod of compounded data.The main one.
//
Procedure SetRoleOfSetField(DataSet, DataPath, RoleOfField = Undefined) Export
	
	If RoleOfField = Undefined Then
		RoleOfField = NewDataSetFieldRole();
	EndIf;
	
	SetField = DataSet.Fields.Find(DataPath);
	FillPropertyValues(SetField.Role, RoleOfField);
	
EndProcedure

// Returns the role structure of the data layout schema dataset field
// with empty default values filled in.
//
// Returns: 
//	Structure - Keys:
//		* AccountTypeExpression - String - 
//		* BalanceGroup - String - 
//		* IgnoreNULLValues - Boolean
//		* Dimension - Boolean
//		* PeriodNumber - Number
//		* Required - Boolean
//		* Balance - Boolean
//		* AccountField - String
//		* DimensionAttribute - Boolean
//		* ParentDimension - String
//		* Account - Boolean
//		* AccountingBalanceType - DataCompositionAccountingBalanceType -
//		* BalanceType - DataCompositionBalanceType - 
//		* PeriodType - DataCompositionPeriodType- 
//
Function NewDataSetFieldRole() Export
	
	NewRole = New Structure;
	NewRole.Insert("AccountTypeExpression"      , "");
	NewRole.Insert("BalanceGroup"           , "");
	NewRole.Insert("IgnoreNULLValues", False);
	NewRole.Insert("Dimension"               , False);
	NewRole.Insert("PeriodNumber"            , 0);
	NewRole.Insert("Required"            , False);
	NewRole.Insert("Balance"                 , False);
	NewRole.Insert("AccountField"               , "");
	NewRole.Insert("DimensionAttribute"       , False);
	NewRole.Insert("ParentDimension"   , "");
	NewRole.Insert("Account"                    , False);
	NewRole.Insert("AccountingBalanceType", DataCompositionAccountingBalanceType.None);
	NewRole.Insert("BalanceType"              , DataCompositionBalanceType.None);
	NewRole.Insert("PeriodType"              , DataCompositionPeriodType.Main);
	Return NewRole;
	
EndFunction

// Returns a link to the new area layout
//
// Parameters:
//  Schema - DataCompositionSchema - the circuit layout data.
//  AreaTemplate - DataCompositionSchemaTemplateDescription - parameter description.
//  TemplateName - String - name of the layout.
//
// Returns:
//   DataCompositionSchemaTemplateDescription - description of the layout of the data layout scheme.
//
Function AddSchemaTemplate(Schema, AreaTemplate, TemplateName) Export
	
	TemplateDetails = Schema.Templates.Add(); // DataCompositionSchemaTemplateDescription -
	TemplateDetails.Template = AreaTemplate;
	TemplateDetails.Name = TemplateName;
	Return TemplateDetails;
	
EndFunction

// Returns a reference to the new data set Association of the data layout schema.
//
// Parameters:
//  DCS  - DataCompositionSchema - a data layout diagram in which you want to add a set relationship.
//  SourceDataSet  - DataCompositionSchemaDataSetQuery -
//  						- DataCompositionSchemaDataSetObject - the data set is the communication source.
//  DestinationDataSet  - DataCompositionSchemaDataSetQuery -
//  						- DataCompositionSchemaDataSetObject - communication receiver data set.
//  SourceExpression - String - Expression that will be used to determine the value of the source link.
//  DestinationExpression - String - Expression that will be used to determine the value of the receiver connection (optional).
//
// Returns:
//   DataCompositionSchemaDataSetLink - a link to a new data set relationship.
//
Function NewConnection(DCS, SourceDataSet, DestinationDataSet, SourceExpression, DestinationExpression = "") Export
	
	Link = DCS.DataSetLinks.Add();
	Link.SourceDataSet = 	SourceDataSet;
	Link.DestinationDataSet = 	DestinationDataSet;
	Link.SourceExpression = 		SourceExpression;
	If DestinationExpression = "" Then
		Link.DestinationExpression = 		SourceExpression;
	Else
		Link.DestinationExpression = 		DestinationExpression;
	EndIf;
	
	Return Link;
	
EndFunction

// Copies the elements of the selection from one collection to another selection
//
// Parameters:
//  FilterSource - DataCompositionFilter - where to copy from.
//  FilterReceiver - DataCompositionFilter - where to copy.
//  UsedOnly - Boolean - copy only used ones.
//  ExceptionFields - Structure - the structure keys list fields that should not be included in the receiver selection.
//  Postfix - String - any string that will be added to the name of the left field.
//  CheckFieldsAvailability - Boolean - To check the availability of fields for the selection when copying. False by default.
//
Procedure CopyFilter(FilterSource, FilterReceiver, UsedOnly = False, ExceptionFields = Undefined, Postfix = "", CheckFieldsAvailability = False) Export
	
	ParametersForCheckingAvailabilityOfFields = New Structure;
	ParametersForCheckingAvailabilityOfFields.Insert("CheckFieldsAvailability", CheckFieldsAvailability);
	
	FilterAvailableFields = New ValueTable;
	FilterAvailableFields.Columns.Add("LayoutField");
	FilterAvailableFields.Columns.Add("FieldName");
	If CheckFieldsAvailability Then
		FillAvailableFieldsRecursively(FilterAvailableFields, FilterReceiver.FilterAvailableFields.Items);
	EndIf;
	FilterAvailableFields.Indexes.Add("LayoutField");
	FilterAvailableFields.Indexes.Add("FieldName");
	
	ParametersForCheckingAvailabilityOfFields.Insert("FilterAvailableFields", FilterAvailableFields);
	
	CopySelectionRecursively(FilterSource, FilterReceiver, UsedOnly, ExceptionFields, Postfix, ParametersForCheckingAvailabilityOfFields);
	
EndProcedure

// Returns a reference to the layout grouping in the passed data layout schema structure.
//
// Parameters:
//  DCStructure - DataCompositionSettingStructureItemCollection - the selection of the layout in which you want to add a new item.
//  TagName - String - name of the layout field that you want to find grouping by.
//
// Returns:
//   DataCompositionGroup - a reference to the found grouping element of the data layout scheme.
//
Function FindGroup1(DCStructure, TagName) Export
	
	Result = Undefined;
	For Each Item In DCStructure Do
		If Item.Name = TagName Then
			Result = Item;
			Break;
		ElsIf TypeOf(Item) = Type("DataCompositionTable") Then
			Result = FindGroup1(Item.Rows, TagName);
			If Result = Undefined Then
				Result = FindGroup1(Item.Columns, TagName);	
			EndIf;
			Break;
		Else
			Result = FindGroup1(Item.Structure, TagName);
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Returns a reference to the selection element in the passed selection of the data layout schema.
//
// Parameters:
//  FilterDQ - DataCompositionFilter - the selection of the layout in which you want to add a new item.
//  TagName - String - name of the layout field to use to find the selection element.
//  FilterValue - Arbitrary - set the selection value to use to find the selection element.
//  Var_ComparisonType - DataCompositionComparisonType - set the type of comparison for which you need to find the selection element.
//
// Returns:
//   DataCompositionFilterItem - a link to the found selection element of the data layout scheme.
//
Function FindSelectionElement(FilterDQ, TagName, FilterValue = "#DontConsider#", Var_ComparisonType = Undefined) Export
	
	Result = Undefined;
	For Each FilterElement In FilterDQ.Items Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			Result = FindSelectionElement(FilterElement, TagName);
			If Result <> Undefined Then
				Break;
			EndIf;
		ElsIf FilterElement.LeftValue = New DataCompositionField(TagName) Then
			If FilterElement.RightValue = FilterValue Or FilterValue = "#DontConsider#" Then
				If FilterElement.ComparisonType = Var_ComparisonType Or Var_ComparisonType = Undefined Then
					Result = FilterElement;
					Break;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Adds a new parameter to the passed collection of data layout schema settings.
//
// Parameters:
//  Parameters - DataCompositionSettingsComposer, DataCompositionSettings - layout scheme settings.
//  ParameterName - DataCompositionDataParameterValues, DataCompositionOutputParameterValues - collection of data layout parameters.
//  Value  - Arbitrary - the value of the layout parameter (optional).
//  Use  - Boolean - using the data parameter (optional, True by default).
//
Procedure SetParameter(Parameters, ParameterName, Value = Undefined, Use = True) Export
	
	Parameter = Parameters.Items.Find(ParameterName);
	If Parameter = Undefined Then
		Return;
	EndIf;
	
	Parameter.Use = Use;
	If Use Then
		Parameter.Value = Value;
	EndIf;
	
EndProcedure

// Executes the data layout schema and returns the result table.
//
// Parameters:
//  DataCompositionSchema  - DataCompositionSchema - executable data layout scheme.
//  ComposerSettings  - DataCompositionSettingsComposer - linker for settings of the executable data layout scheme.
//  ExternalDataSets  - Structure - external data layout sets-key - name of the external set,
//                                       value-table of values of the external set.
//  OutputToTree - Boolean - if True, output to the value tree.
//  TempTablesManager - TempTablesManager - temporary tables for querying the DCS dataset
//  						Undefined - if the temporary table manager is not specified
//
// Returns:
//   ValueTable, ValueTree - the result of executing the data layout scheme.
//
Function UploadDCSResults(DataCompositionSchema, ComposerSettings, ExternalDataSets = Undefined,
	OutputToTree = False, TempTablesManager = Undefined) Export
	
	ComposerTemplate = PrepareLayoutTemplateForUploadingDCS(DataCompositionSchema, ComposerSettings);
	Return UploadDCSResultsFromTemplate(ComposerTemplate, ExternalDataSets, OutputToTree, TempTablesManager);
	
EndFunction

// Returns a reference to the new selection element in the passed selection of the data layout schema.
//
// Parameters:
//  Filter - DataCompositionFilter - the selection of the layout to which you want to add a new item
//  LeftValue - String, DataCompositionField - field layout that you want to set the selection (optional)
//  RightValue  - Arbitrary, String, DataCompositionField - the value of the selection (optional) or field layout
//  FilterType  - DataCompositionFilterItem, DataCompositionFilterItemGroup - type of new selection element (optional)
//  Var_ComparisonType  - DataCompositionComparisonType - comparison view of the left and right values
//  RightFieldValue  - Boolean - specifies whether to use the data layout field as the right value.
//
// Returns:
//  DataCompositionFilterItem - a link to a new selection element of the data layout scheme.
//
Function NewFilter(Filter, LeftValue, RightValue = Undefined, FilterType = Undefined, Var_ComparisonType = Undefined, RightFieldValue = False) Export
	
	If FilterType = Undefined Then
		FilterType = Type("DataCompositionFilterItem");
	EndIf;
	
	NewFilter = Filter.Items.Add(FilterType);
	If LeftValue <> Undefined Then
		If TypeOf(LeftValue) = Type("DataCompositionField") Then
			NewFilter.LeftValue = LeftValue;
		Else
			NewFilter.LeftValue = New DataCompositionField(LeftValue);
		EndIf;
	EndIf;
	
	If RightValue <> Undefined Then
		If RightFieldValue Then
			If TypeOf(RightValue) = Type("DataCompositionField") Then
				NewFilter.RightValue = RightValue;
			Else
				NewFilter.RightValue = New DataCompositionField(RightValue);
			EndIf;
		Else
			NewFilter.RightValue = RightValue;
		EndIf;
	EndIf;
	
	If FilterType = Type("DataCompositionFilterItem") Then
		If Var_ComparisonType = Undefined Then
			NewFilter.ComparisonType = DataCompositionComparisonType.Equal;
			If TypeOf(RightValue) = Type("Array") Or TypeOf(RightValue) = Type("ValueList") Then
				NewFilter.ComparisonType = DataCompositionComparisonType.InList;
			EndIf;
		Else
			NewFilter.ComparisonType = Var_ComparisonType;
		EndIf;
	EndIf;
	
	Return NewFilter;
	
EndFunction

// Sets a new selection in the passed selection of the data layout scheme.
//
// Parameters:
//  FilterDQ - DataCompositionFilter - the selection of the layout in which you want to add a new item.
//  LeftValue - String, DataCompositionField - the layout field for which you want to set the selection.
//  RightValue  - Arbitrary - the value of the selection (optional).
//  Var_ComparisonType  - DataCompositionComparisonType - data layout comparison view (optional).
//  Use  - Boolean - using a new selection element (optional, True by default).
//
Procedure SetFilter(FilterDQ, LeftValue, RightValue = Undefined, Var_ComparisonType = Undefined, Use = True) Export
	
	FilterElement = FindSelectionElement(FilterDQ, LeftValue);
	If FilterElement = Undefined Then
		FilterElement = NewFilter(FilterDQ, LeftValue, RightValue);
	EndIf;
	FilterElement.Use = Use;
	If Var_ComparisonType <> Undefined Then
		FilterElement.ComparisonType = Var_ComparisonType;
	EndIf;
	If Use Then
		FilterElement.RightValue = RightValue;
	EndIf;
	
EndProcedure

// Sets the data parameter in the passed data layout scheme settings.
//
// Parameters:
//  ComposerSettings - DataCompositionSettingsComposer, DataCompositionSettings - layout scheme settings.
//  ParameterName - String - name of the data layout parameter.
//  Value  - Arbitrary - the value of the layout parameter (optional).
//  Use  - Boolean - using the data parameter (optional, True by default).
//
Procedure SetLayoutParameter(ComposerSettings, ParameterName, Value = Undefined, Use = True) Export
	
	DCSettings = ComposerSettings;
	If TypeOf(ComposerSettings) = Type("DataCompositionSettingsComposer") Then
		DCSettings = ComposerSettings.Settings;
	EndIf;
	SetParameter(DCSettings.DataParameters, ParameterName, Value, Use);
	
EndProcedure

// Returns the settings linker for the passed data layout scheme
//
// Parameters:
//  Schema                    - DataCompositionSchema - the data layout scheme for which you need to create
//                                                     the settings Builder.
//  RestoreSettings_ - Boolean - indicates whether you need to restore settings.
//
// Returns:
//   DataCompositionSettingsComposer - the configuration builder for the default option.
//
Function SchemaComposer(Schema, RestoreSettings_ = True) Export
	
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(Schema);
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(AvailableSettingsSource);
	Composer.LoadSettings(Schema.DefaultSettings);
	
	If RestoreSettings_ Then
		Composer.Refresh(DataCompositionSettingsRefreshMethod.Full);
	EndIf;
	
	Return Composer;
	
EndFunction

// Returns the layout of the data layout.
//
// Parameters:
//  DataCompositionSchema  - DataCompositionSchema - executable data layout scheme.
//  ComposerSettings  - DataCompositionSettingsComposer, DataCompositionSettings - settings for the executable
//      data layout scheme.
//
// Returns:
//   DataCompositionTemplate - the layout of the layout data.
//
Function PrepareLayoutTemplateForUploadingDCS(DataCompositionSchema, ComposerSettings) Export
	
	DCSettings = ComposerSettings;
	If TypeOf(ComposerSettings) = Type("DataCompositionSettingsComposer") Then
		DCSettings = ComposerSettings.GetSettings();
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, DCSettings,,,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	Return CompositionTemplate;
	
EndFunction

// Executes the data layout schema and returns the result table.
//
// Parameters:
//  CompositionTemplate  - DataCompositionTemplate - the layout of the layout data.
//  ExternalDataSets  - Structure - external data layout sets-key - name of the external set,
//                                       value-table of values of the external set.
//  OutputToTree - Boolean - if True, output to the value tree.
//  TempTablesManager - TempTablesManager - temporary tables for querying the DCS dataset
//  						Undefined - if the temporary table manager is not specified
//
// Returns:
//   ValueTable, ValueTree - the result of executing the data layout scheme.
//
Function UploadDCSResultsFromTemplate(CompositionTemplate, ExternalDataSets = Undefined, OutputToTree = False,
	TempTablesManager = Undefined) Export
	
	Result = New ValueTable;
	If OutputToTree Then
		Result = New ValueTree;
	EndIf;
	
	// Creating a layout processor
	CompositionProcessor = New DataCompositionProcessor;
	If ExternalDataSets = Undefined Then
		CompositionProcessor.Initialize(CompositionTemplate,,,True, , TempTablesManager);
	Else
		CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets,,True, , TempTablesManager);
	EndIf;
	
	// Output to the table of values
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(Result);
	Result = OutputProcessor.Output(CompositionProcessor, True);
	Return Result;
	
EndFunction

// Returns a reference to a new group of fields in the passed dataset.
//
// Parameters:
//  DataSet  - DataCompositionSchemaDataSetQuery,DataCompositionSchemaDataSetObject - the data set
//      to create a new field in.
//  String field - name of the new field in the data layout schema.
//  DataPath  - String - the data path of the new data layout schema field (optional by default is"").
//  Title    - String - title of the new data layout schema field (optional by default is"").
//
// Returns:
//  DataCompositionSchemaDataSetFieldFolder - description of the return value.
//
Function NewSetGroup(DataSet, DataPath, Title = "") Export
	
	If IsBlankString(Title) Then
		Title = DataPath;
	EndIf;
	
	NewFolder = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetFieldFolder"));
	NewFolder.DataPath = DataPath;
	NewFolder.Title = Title;
	
	Return NewFolder;
	
EndFunction

// Returns the parent element of the table view that contains the elements passed in the parameters.
// 
// Parameters:
//	ReportItems - ValueTree, FormDataTree - elements or elements for which you need to define the table in which they are placed.
//	AddressOfItemStructure - String - the address in the temporary storage.
//
// Returns:
//	ValueTable -
//	DataForm
//	Tree - DataForm Tree element is a tree element or a tree row of the "Table" type in which the passed element is located.
// 
Function ElementTable(ReportItems, AddressOfItemStructure = Undefined) Export
	
	If (TypeOf(ReportItems) = Type("ValueTree")
			Or TypeOf(ReportItems) = Type("FormDataTree"))
		And AddressOfItemStructure = Undefined Then
		
		Raise NStr("vi = 'Các tham số chức năng của bảng mục không hợp lệ';
					|ru = 'Неверные параметры функции ""Таблица элемента""';
					|en = 'Incorrect parameters of the ""Item table"" function'; fa = 'Incorrect parameters of the ""Item table"" function';
					|it = 'Parametri della funzione ""Tabella dell''elemento"" errati';
					|pl = 'Nieprawidłowe parametry funkcji ""Element tabeli""';
					|tr = '""Öğe tablosu"" işlevinin geçersiz parametreleri'");
	EndIf;
	
	If TypeOf(ReportItems) = Type("ValueTree")
		Or TypeOf(ReportItems) = Type("FormDataTree") Then
		CurElementString = SubordinateItem(ReportItems, "AddressOfItemStructure", AddressOfItemStructure);
	Else
		CurElementString = ReportItems;
	EndIf;
	
	If CurElementString.ItemKind = ItemKind("TableIndicatorsInColumns")
		Or CurElementString.ItemKind = ItemKind("TableIndicatorsInRows")
		Or CurElementString.ItemKind = ItemKind("ComplexTable") Then
		
		Return CurElementString;
		
	EndIf;
	
	Table = RootItem(CurElementString, ItemKind("TableIndicatorsInColumns"));
	
	If Table = Undefined Then
		Table = RootItem(CurElementString, ItemKind("TableIndicatorsInRows"));
		If Table = Undefined Then
			Table = RootItem(CurElementString, ItemKind("ComplexTable"));
		EndIf;
	EndIf;
	
	Return Table;
	
EndFunction

// The procedure adds rows to the tree.
//
// Parameters:
//  SourceRows  - FormDataTreeItem - source tree rows.
//  DestinationRows  - FormDataTreeItem - rows in the receiver tree.
//
Procedure AddRowsToTree(SourceRows, DestinationRows)
	
	SourceStringsToAdd = SubordinateRows(SourceRows);
	AugmentedReceiverStrings = SubordinateRows(DestinationRows);
	FieldControl = New Structure("CustomPicture,ThisIsReference");
	For Each SourceRow1 In SourceStringsToAdd Do
		
		NewRow = AugmentedReceiverStrings.Add();
		FillPropertyValues(NewRow, SourceRow1);
		FillPropertyValues(FieldControl, NewRow);
		
		If FieldControl.CustomPicture <> Undefined
			And FieldControl.ThisIsReference <> Undefined Then
			NewRow.CustomPicture = NewRow.CustomPicture + Number(NewRow.ThisIsReference);
		EndIf;
		
		AddRowsToTree(SourceRow1, NewRow);
		
	EndDo;
	
EndProcedure

// Returns the structure of parameters for setting the new parent.
//
// Returns:
// 	Structure - The structure of the installation parameters of the new parent.
//
Function TemplateForNewParentInstallationOptions() Export
	
	ParameterTemplate = New Structure;
	ParameterTemplate.Insert("TheseAreSavedOnes", False);
	ParameterTemplate.Insert("LoopControl", True);
	ParameterTemplate.Insert("FormIdentifier", Undefined);
	ParameterTemplate.Insert("Copy", False);
	ParameterTemplate.Insert("IDParameters_", Undefined);
	
	Return ParameterTemplate;
	
EndFunction

// Moves a string and all its subordinate elements to a new branch of the tree.
//
//	Parameters:
//		CurrentRow - FormDataTreeItem, ValueTreeRow, ValueTree - row in the report item tree
//		NewParent - FormDataTreeItem, ValueTreeRow, ValueTree - a new parent branch of a tree of report elements
//		ParentInstallationOptions - Structure - Structure of parameters with properties:
//			*TheseAreSavedOnes - Boolean - flag indicating that these are rows in the tree of saved elements
//			*LoopControl - Boolean - flag that specifies whether string looping control is performed
//			*FormIdentifier - UUID - unique ID of the form in the temporary storage 
//			                                               of which you want to place the element data.
//			*Copy - Boolean - Flag for copying an element.
//			*IDParameters_ - Structure - Structure containing the parameters of the IDs.
//
Procedure SetNewParent(CurrentRow, NewParent, ParentInstallationOptions) Export
	
	TheseAreSavedOnes = ParentInstallationOptions.TheseAreSavedOnes;
	LoopControl = ParentInstallationOptions.LoopControl;
	FormIdentifier = ParentInstallationOptions.FormIdentifier;
	Copy = ParentInstallationOptions.Copy;
	IDParameters_ = ParentInstallationOptions.IDParameters_;
	
	If LoopControl Then
		Parent = FinancialReportingClientServer.RowParent(NewParent);
		While Parent <> Undefined Do
			If TypeOf(Parent) = Type("FormDataTreeItem") And Parent.GetID() = CurrentRow.GetID()
				Or ValueIsFilled(Parent.ReportItem) And Parent.ReportItem = CurrentRow.ReportItem
				Or ValueIsFilled(Parent.AddressOfItemStructure) And Parent.AddressOfItemStructure = CurrentRow.AddressOfItemStructure Then
				Return;
			EndIf;
			Parent = FinancialReportingClientServer.RowParent(Parent);
		EndDo;
	EndIf;
	
	ParentRows = SubordinateRows(NewParent);
	If TheseAreSavedOnes Then
		NewRow = ParentRows.Add();
	Else
		IndexOf = FinancialReportingClientServer.IndexOfNewRow(ParentRows);//if there is a total for the group at the end of the group, then a new line should appear in front of it
		NewRow = ParentRows.Insert(IndexOf);
	EndIf;
	
	FillPropertyValues(NewRow, CurrentRow);
	
	If IDParameters_ <> Undefined Then
		IDsMap = IDParameters_.IDsMap;
		If IDParameters_.Mode = "Remember" Then
			IDsMap.Insert(CurrentRow.GetID(), NewRow.GetID());
		ElsIf IDParameters_.Mode = "Refresh" Then
			NewRow.LineIndexOfReportItems = IDsMap[NewRow.LineIndexOfReportItems];
			For Cnt = 2 To IDParameters_.NumberOfIDs Do
				If NewRow["LineIndexOfReportItems" + Cnt] = Undefined Then
					Continue;
				EndIf;
				NewRow["LineIndexOfReportItems" + Cnt] = 
					IDsMap[NewRow["LineIndexOfReportItems" + Cnt]];
			EndDo;
		EndIf;
	EndIf;
	
	If FormIdentifier <> Undefined Then
		If Copy Then
			
			If ValueIsFilled(NewRow.AddressOfItemStructure) Then
				NewRow.AddressOfItemStructure = 
					FinancialReportingServerCall.CopyElementTo(
						NewRow.AddressOfItemStructure, FormIdentifier);
						
			ElsIf Not ValueIsFilled(NewRow.AddressOfItemStructure)
					And ValueIsFilled(NewRow.ReportItem) Then
			
				NewRow.AddressOfItemStructure = 
					FinancialReportingServerCall.PlaceItemInStorage(
						NewRow.ReportItem, FormIdentifier, True);
			EndIf;
			
			NewRow.ReportItem = Undefined;
		
		ElsIf Not ValueIsFilled(NewRow.AddressOfItemStructure)
			And ValueIsFilled(NewRow.ReportItem) Then
			
			NewRow.AddressOfItemStructure = 
				FinancialReportingServerCall.PlaceItemInStorage(
					NewRow.ReportItem, FormIdentifier);
		
		EndIf;
	EndIf;
	
	LinesOfCurLine = SubordinateRows(CurrentRow);
	Cnt = LinesOfCurLine.Count();
	
	While Cnt > 0 Do
		
		LineNumber = LinesOfCurLine.Count() - Cnt;
		Substring = LinesOfCurLine[LineNumber];
		ParentInstallationOptions = TemplateForNewParentInstallationOptions();
		ParentInstallationOptions.TheseAreSavedOnes = TheseAreSavedOnes;
		ParentInstallationOptions.LoopControl = False;
		ParentInstallationOptions.FormIdentifier = FormIdentifier;
		ParentInstallationOptions.Copy = Copy;
		ParentInstallationOptions.IDParameters_ = IDParameters_;
		SetNewParent(Substring, NewRow, ParentInstallationOptions);
		Cnt = Cnt - 1;
		
	EndDo;
	
	If Not Copy Then
		CurrentParent = FinancialReportingClientServer.RowParent(CurrentRow);
		If CurrentParent <> Undefined Then
			CurCollectionOfStrings = SubordinateRows(CurrentParent);
			CurCollectionOfStrings.Delete(CurrentRow);
		EndIf;
	EndIf;
	
EndProcedure

// Finds the parent element of the specified type that is closest to the top of the hierarchy.
//
// Parameters:
//	Tree - FormDataTree, FormDataTreeItem - tree element to define the parent element
//														for if a tree is specified, the result will be determined among the subordinate rows of the first level.
//	RootElementView - EnumRef.FinancialReportItemKinds - type of parent.
//
//	Returns:
//		FormDataTreeItem -
//		The assignment string is the parent of the string.
//
Function RootItem(Tree, RootElementView = Undefined) Export
	
	If RootElementView = Undefined Then
		RootElementView = PredefinedValue("Enum.FinancialReportItemKinds.EmptyRef");
	EndIf;
	
	RootItem = Undefined;
	If TypeOf(Tree) = Type("FormDataTree") Then
		SubordinateRows = SubordinateRows(Tree);
		For Each TreeRow In SubordinateRows Do
			If TreeRow.ItemKind = RootElementView Then
				RootItem = TreeRow;
				Break;
			EndIf;
		EndDo;
	Else
		RootItem = FinancialReportingClientServer.RowParent(Tree);
		While RootItem <> Undefined Do
			If RootItem.ItemKind = RootElementView Then
				Break;
			EndIf;
			RootItem = FinancialReportingClientServer.RowParent(RootItem);
		EndDo;
	EndIf;
	
	Return RootItem;
	
EndFunction

// Returns, depending on the type, a collection of subordinate elements of the first level of the passed row in the report element tree.
//
//	Parameters:
//		TreeRow - FormDataTreeItem, ValueTreeRow, ValueTreeRowCollection, FormDataTree - a row in the report item tree.
//
//	Returns:
//		FormDataTreeItemCollection -
//		A collection of String Tree assignments - Subordinate strings.
//
Function SubordinateRows(TreeRow) Export
	
	TreeRowType = TypeOf(TreeRow);
	ThisIsCollectionOfStrings = TreeRowType = Type("FormDataTreeItemCollection")
	                Or TreeRowType = Type("ValueTreeRowCollection");
	
	If ThisIsCollectionOfStrings Then
		SubordinateRows = TreeRow;
	Else
		If TypeOf(TreeRow) = Type("FormDataTreeItem")
			Or TypeOf(TreeRow) = Type("FormDataTree") Then
			SubordinateRows = TreeRow.GetItems();
		Else
			SubordinateRows = TreeRow.Rows;
		EndIf;
	EndIf;
	
	Return SubordinateRows;
	
EndFunction

// Finds the element closest to the bottom of the hierarchy by the value of the specified props.
//
// Parameters:
//	Tree - FormDataTree, FormDataTreeItem - the element of wood or string of the tree in which to search
//	AttributeName - String - name of the tree attribute whose value is compared with the one set for the search
//	AttributeValue - Arbitrary - the value of the tree's props to find.
//
// Returns:
//	FormDataTreeItem, ValueTreeRow - a subordinate element.
//
Function SubordinateItem(Tree, AttributeName, AttributeValue) Export
	
	If TypeOf(Tree) = Type("ValueTree")
		Or TypeOf(Tree) = Type("ValueTreeRow") Then
		
		TreeRows = Tree.Rows;
		Return TreeRows.Find(AttributeValue, AttributeName, True);
		
	EndIf;
	
	SubordinateItem = Undefined;
	SubordinateRows = SubordinateRows(Tree);
	For Each TreeRow In SubordinateRows Do
		If TreeRow[AttributeName] = AttributeValue Then
			SubordinateItem = TreeRow;
			Break;
		EndIf;
		SubordinateItem = SubordinateItem(TreeRow, AttributeName, AttributeValue);
		If SubordinateItem <> Undefined Then
			Break;
		EndIf;
	EndDo;
	
	Return SubordinateItem;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Overrides the resolves to select Operand flag for added layout schema lines.
// 
// Parameters:
// 	AddedRow - FormDataTreeItem - LongDesc:
// 	  * OperandSelectionAllowed - Boolean - Flag for string selection.
// 	Form - ClientApplicationForm - The Form for setting up the filling of budgeting analytics or the Form for Setting Up the Filling of THE ExtDimension of International Accounting:
// 	  * ValueType - TypeDescription - operands with types included in the specified type description can be selected.
// 	  * AdditionalPropertyID - String - id of the additional Attribute/information added from the form.
Procedure CheckWhetherAddedRowsCanBeSelectedByTypeRecursively(AddedRow, Form)
	
	AddedRow.OperandSelectionAllowed = Min(AddedRow.OperandSelectionAllowed,
		SuitableSelectionField(AddedRow, Form.ValueType, Form.AdditionalPropertyID));
	
	For Each SubordinateGroupLine In AddedRow.GetItems() Do
		CheckWhetherAddedRowsCanBeSelectedByTypeRecursively(SubordinateGroupLine, Form);
	EndDo;

EndProcedure

// Returns a collection of form tree elements.
// 
// Parameters:
// 	WhereToSearchForStrings - FormDataTreeItem, FormDataTree - place to search for strings.
// Returns:
// 	FormDataTreeItemCollection of FormDataTreeItem - collection of tree elements:
// 	 *Id - String - ID of the current part of the operand.
Function SubordinateLinesForSweep(WhereToSearchForStrings)
	Return WhereToSearchForStrings.GetItems();
EndFunction

Procedure ExpandRowsOfOperandTreeByCurExpression(Form, WhereToSearchForStrings, RemainingPartsOfOperand, SweepRestrictions)
	If RemainingPartsOfOperand.Count() > 0 Then
		TreeRow = Undefined;
		SubordinateRows = SubordinateLinesForSweep(WhereToSearchForStrings);
		For Each SubordinateRow In SubordinateRows Do
			If SubordinateRow.Id = RemainingPartsOfOperand[0] Then
				TreeRow = SubordinateRow;
				Break;
			EndIf;
		EndDo;
		If Not TreeRow = Undefined Then
			RemainingPartsOfOperand.Delete(0);
			If RemainingPartsOfOperand.Count() > 0 Then
				If Not TreeRow.SubordinateRowsExpanded Then
					RowID = TreeRow.GetID();
					ProcessingOfFormulas.ExpandOperandStringOfFormTree(Form.SelectionTree,
						RowID,
						SweepRestrictions.MaximumRowExpansionLevel);
				EndIf;
				ExpandRowsOfOperandTreeByCurExpression(Form, TreeRow, RemainingPartsOfOperand, SweepRestrictions);
			Else
				SelectionTree = Form.Items.SelectionTree; // FormTable -
				SelectionTree.CurrentRow = TreeRow.GetID();
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// Copies the elements of the selection from one collection to another selection.
//
// Parameters:
//  FilterSource - DataCompositionFilter - where to copy from.
//  FilterReceiver - DataCompositionFilter - where to copy.
//  UsedOnly - Boolean - copy only used ones.
//  ExceptionFields - Structure - the structure keys list fields that should not be included in the receiver selection.
//  Postfix - String - any string that will be added to the name of the left field.
//  ParametersForCheckingAvailabilityOfFields - Structure - Parameters for checking the availability of fields. If you need to check the availability of fields:
//   *CheckFieldsAvailability - Boolean - To check the availability of fields for the selection when copying. False by default.
//   *FilterAvailableFields - ValueTable - Cache of available fields to check for hierarchical copying selection:
//     **LayoutField - DataCompositionField  - data layout field.
//     **FieldName        - String          - The name of the field for checks separated by a dot.
//
Procedure CopySelectionRecursively(FilterSource, FilterReceiver, UsedOnly = False, ExceptionFields = Undefined, Postfix = "", ParametersForCheckingAvailabilityOfFields = Undefined)
	
	CheckFieldsAvailability = ParametersForCheckingAvailabilityOfFields.CheckFieldsAvailability;
	FilterAvailableFields = ParametersForCheckingAvailabilityOfFields.FilterAvailableFields;
	
	For Each Item In FilterSource.Items Do
		
		If Not (UsedOnly And Item.Use Or Not UsedOnly) Then
			Continue;
		EndIf;
		
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
			NewItem = NewFilter(FilterReceiver, Undefined,,Type("DataCompositionFilterItemGroup"));
			FillPropertyValues(NewItem, Item);
			CopySelectionRecursively(Item, NewItem, UsedOnly, ExceptionFields, Postfix, ParametersForCheckingAvailabilityOfFields);
		Else
			
			If Not ValueIsFilled(Item.LeftValue) Then
				Continue;
			EndIf;
			
			If ValueIsFilled(ExceptionFields) Then
				Field = DataCompositionClientServer.SeparateFieldNameAndProps(String(Item.LeftValue));
				If ExceptionFields.Property(Field.Name) Then
					Continue;
				EndIf;
			EndIf;
			
			If CheckFieldsAvailability Then
				FieldEnabled = False;
				If Not FilterAvailableFields.Find(Item.LeftValue, "LayoutField") = Undefined Then
					FieldEnabled = True;
				EndIf;
				If Not FieldEnabled Then
					FieldNameAndDetails = DataCompositionClientServer.SeparateFieldNameAndProps(String(Item.LeftValue));
					If Not FilterAvailableFields.Find(FieldNameAndDetails.Name, "FieldName") = Undefined Then
						FieldEnabled = True;
					EndIf;
				EndIf;
				If Not FieldEnabled Then
					Continue;
				EndIf;
			EndIf;
			
			NewItem = NewFilter(FilterReceiver, Undefined,,Type("DataCompositionFilterItem"));
			FillPropertyValues(NewItem, Item);
			
			If Postfix <> "" Then
				Field = DataCompositionClientServer.SeparateFieldNameAndProps(String(NewItem.LeftValue));
				NewFieldName = Field.Name + Postfix + "." + Field.Attribute;
				If StrFind(Field.Name, "ExtDimension") And StrFind("DRCR", Upper(Postfix))Then
					Number = Right(Field.Name, 1);
					If StrFind("12345", Number) Then
						Template = StrReplace(Field.Name, Number, "%1");
						NewFieldName = StrTemplate(Template, Postfix + Number) + "." + Field.Attribute;
					EndIf;
				EndIf;
				NewItem.LeftValue = New DataCompositionField(NewFieldName);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillAvailableFieldsRecursively(AvailableFields, ElementsOfAvailableFields)
	For Each ElementOfAvailableFields In ElementsOfAvailableFields Do
		If ElementOfAvailableFields.Folder Then
			FillAvailableFieldsRecursively(AvailableFields, ElementOfAvailableFields.Items);
		Else
			NewRow = AvailableFields.Add();
			NewRow.LayoutField = ElementOfAvailableFields.Field;
			NewRow.FieldName = String(ElementOfAvailableFields.Field);
		EndIf;
	EndDo;
EndProcedure

Function ItemKind(ElementTypeName)
	
	Return Enums.FinancialReportItemKinds[ElementTypeName];
	
EndFunction

Procedure AddImageMatchingString(TableOfPictures, ItemKind, NameOfAuxiliaryData, PictureIndex)
	
	NewRow = TableOfPictures.Add();
	If Not IsBlankString(ItemKind) Then
		NewRow.ItemKind = Enums.FinancialReportItemKinds[ItemKind];
	EndIf;
	NewRow.NameOfAuxiliaryElement = NameOfAuxiliaryData;
	NewRow.PictureIndex = PictureIndex;
	
EndProcedure

Function AddDetailsOfRelatedElements()
	
	Return 
	"
	|
	|UNION ALL
	|"
	+
	"
	|SELECT
	|	AddAttributes.Ref AS ReportItem,
	|	AddAttributes.Attribute,
	|	AddAttributes.Value
	|FROM
	|	Catalog.FinancialReportItems.ItemKindAttributes AS AddAttributes
	|		INNER JOIN Catalog.FinancialReportItems AS Catalog
	|		ON Catalog.LinkedItem1 = AddAttributes.Ref
	|			AND Catalog.Owner = &ReportKind
	|			AND Catalog.LinkedItem1 <> VALUE(Catalog.FinancialReportItems.EmptyRef)";
	
EndFunction

// Returns a reference to the new selection field in the passed data layout schema structure.
//
// Parameters:
//  ComposerSettings - DataCompositionSettingsComposer,DataCompositionSettings - layout scheme settings
//      to add a new parameter to.
//  ParameterName - String - name of the new parameter.
//  Value  - Arbitrary - value of the new parameter.
//
// Returns:
//   DataCompositionParameterValue - a link to the new data layout settings parameter.
//
Function NewParameter1(ComposerSettings, ParameterName, Value = Undefined) Export
	
	DCSettings = ComposerSettings;
	If TypeOf(ComposerSettings) = Type("DataCompositionSettingsComposer") Then
		DCSettings = ComposerSettings.Settings;
	EndIf;
	
	NewParameter1 = DCSettings.DataParameters.Items.Add();
	NewParameter1.Parameter = New DataCompositionParameter(ParameterName);
	NewParameter1.Use = True;
	
	If ValueIsFilled(Value) Then
		NewParameter1.Value = Value;
	EndIf;
	
	Return NewParameter1;
	
EndFunction
#EndRegion

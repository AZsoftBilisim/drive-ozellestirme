#Region Public

// The function returns the name of the type of budgeting analysis.
//
// Parameters:
//  DimensionKind  - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//
// Returns:
//   String - Name of the type of analysis.
//
Function PresentationOfAnalyticsView(DimensionKind) Export
	If Not ValueIsFilled(DimensionKind) Then
		Return "";
	Else
		Return Common.ObjectAttributeValue(DimensionKind, "Description");
	EndIf;
EndFunction

// The procedure starts the background task of reflecting documents in budgeting.
//
// Parameters:
//  BeginOfPeriod - Date - beginning of the document period
//  EndOfPeriod - Date - end of the document period
//
Procedure StartBackgroundTaskOfReflectionInBudgeting(BeginOfPeriod, EndOfPeriod) Export
	ActualBudgetingDataServer.ReflectDocumentsAsBackgroundTask(BeginOfPeriod, EndOfPeriod);
EndProcedure

#EndRegion

#Region Private

// This procedure complements the operator tree for
// the financial and budget reporting formula constructor.
//
// Parameters:
//  Tree  - ValueTree - tree of operators in the formula constructor.
//
Procedure AugmentOperatorTree(Tree) Export
	
	GroupPresentation = NStr("vi = 'Chức năng';
							|ru = 'Функции';
							|en = 'Functions'; fa = 'توابع';
							|it = 'Funzioni';
							|pl = 'Funkcje';
							|tr = 'İşlevler'");
	GroupID = "Functions";
	FoundRows = Tree.Rows.FindRows(New Structure("IsFolder, Id", True, GroupID));
	If FoundRows.Count() = 0 Then
		Group = ProcessingOfFormulas.AddOperatorsGroup(Tree, GroupID, GroupPresentation);
	Else
		Group = FoundRows[0];
	EndIf;
	For Each EnumerationValue In Metadata.Enums.BudgetingFormulaKinds.EnumValues Do
		
		ProcessingOfFormulas.AddOperator(Group,
			Enums.BudgetingFormulaKinds.FunctionText(EnumerationValue.Name),
			Enums.BudgetingFormulaKinds.FunctionText(EnumerationValue.Name),
			EnumerationValue.Synonym);
		
	EndDo;
	
EndProcedure

// The function returns the color value of the style
// called from the budget Reportsclientserver.
//
// Parameters:
//  Name  - String - Name of the style color.
//
// Returns:
//   Color - The color of the style obtained by name.
//
Function GetColor(Name) Export
	
	Return StyleColors[Name];
	
EndFunction

Function OperandTreeForEditingExpressionOfSortingRepresentation(Source, FormID) Export
	
	OperandsTree = ProcessingOfFormulas.GetEmptyOperandTree();
	
	If TypeOf(Source) = Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions") Then
		SourceData = Common.ObjectAttributesValues(Source,
			"Description, Id, ValueType");
	Else
		SourceData = Common.ObjectAttributesValues(Source, "Description, Code");
		SourceData.Insert("Id", Source.Code);
		SourceData.Insert("ValueType", New TypeDescription(CommonClientServer.ValueInArray(
			TypeOf(Source))));
	EndIf;
	
	RootRowOfTree = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	RootRowOfTree.Id = SourceData.Id;
	RootRowOfTree.Presentation = SourceData.Description;
	RootRowOfTree.ValueType = SourceData.ValueType;
	RootRowOfTree.OperandSelectionAllowed = False;
	RootRowOfTree.IncludedInID = False;
	RootRowOfTree.ExpandToAttributes = True;
	
	SweepRestrictions = ProcessingOfFormulas.LimitationsOfOperandSweep();
	SweepRestrictions.DisplayCharacteristics = False;
	ProcessingOfFormulas.ExpandOperandString(RootRowOfTree, SweepRestrictions);
	
	StorageAddress = PutToTempStorage(OperandsTree, FormID);
	Return StorageAddress;
	
EndFunction

// Returns a tree of form elements.
// 
// Parameters:
// 	Form - ClientApplicationForm - the form for which elements are filled in.
// 	NameOfTreeElement - String - Name of the tree element on the form.
// Returns:
// 	ValueTree - a tree with columns:
// 	 *ItemKind - EnumRef.FinancialReportItemKinds - View of the report element.
// 	 *CustomPicture - Number - index of the image.
// 	 *Description - String - Representation of the element.
// 	 *IsFolder - Boolean - The flag group.
// 	 *ReportingKindItem - CatalogRef.BudgetFlowItems -
// 	 						- CatalogRef.BudgetBalanceItems -
// 	 						- CatalogRef.NonFinancialItemsOfBudgets -
// 	 						- String -
// 	 						- EnumRef.Periodicity -
// 	 						- ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	 						- CatalogRef.BudgetingScenarios -
// 	 						- CatalogRef.Companies - 
// 	 						- CatalogRef.BusinessStructure - An element of the reporting type.
// 	
Function TreeOfFormElements(Form, NameOfTreeElement)
	ItemsTree = Form.FormAttributeToValue(NameOfTreeElement);
	Return ItemsTree;
EndFunction

// The procedure fills in the palette of new items that are available
// for selection in the budget instance in the formula designer form.
//
// Parameters:
//  Form - ClientApplicationForm - the form for which elements are filled in.
//  Parameters - Structure - additional parameters of the tree.
//
Procedure UpdateTreeOfNewElements(Form, Parameters) Export
	
	QuickSearch = Undefined;
	NameOfTreeElement = FinancialReportingServer.GetParameter(Parameters,"NameOfTreeElement");
	QuickSearch = FinancialReportingServer.GetParameter(Parameters,"QuickSearch");
	
	Query = New Query;
	TempTablesManager = FinancialReportingServer.TemporaryTableOfImageIndexes();
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryTextNewReportElements();
	
	AvailableItemKinds = GetTypesOfFinancialReportElementsUsed(
									Parameters.TreeMode,
									FinancialReportingServer.GetParameter(Parameters,"UseToEnterPlan", False));
	Query.SetParameter("AvailableItemKinds", AvailableItemKinds);
	Query.SetParameter("TreeMode", Parameters.TreeMode);
	
	ResultsArray = Query.ExecuteBatch();
	
	ItemsTree = TreeOfFormElements(Form, NameOfTreeElement);
	ItemsTree.Rows.Clear();
	
	// Let's create a basic structure
	FinancialReportingServer.QueryResultInTree(ResultsArray[0], ItemsTree);
	
	// Add articles
	IndicatorLine = ItemsTree.Rows.Find(Enums.FinancialReportItemKinds.BudgetFlowItem);
	If IndicatorLine <> Undefined Then
		IndicatorLine.Description = NStr("vi = 'Khoản mục ngân sách';
										|ru = 'Статьи бюджетов';
										|en = 'Budget flow items'; fa = 'اقلام جریان بودجه';
										|it = 'Voci dei bilanci';
										|pl = 'Pozycje budżetowe';
										|tr = 'Bütçe kalemleri'");
		IndicatorLine.ReportingKindItem = Catalogs.BudgetFlowItems.EmptyRef();
		FinancialReportingServer.QueryResultInTree(ResultsArray[1], IndicatorLine);
		If FinancialReportingServer.GetParameter(Parameters, "UseToEnterPlan", False)
			Or Parameters.TreeMode = Enums.ModesOfNewItemTreeDisplay.SelectAComplexTableCellKind Then
			IndicatorLine.ItemKind = Undefined;
		Else
			IndicatorLine.ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems;
		EndIf;
	EndIf;
	
	IndicatorLine = ItemsTree.Rows.Find(Enums.FinancialReportItemKinds.BudgetBalanceItem);
	If IndicatorLine <> Undefined Then
		IndicatorLine.Description = NStr("vi = 'Chỉ tiêu ngân sách';
										|ru = 'Показатели бюджетов';
										|en = 'Budget balance items'; fa = 'اقلام مانده بودجه';
										|it = 'Indici dei bilanci';
										|pl = 'Wskaźniki budżetowe';
										|tr = 'Bütçe dengesi kalemleri'");
		IndicatorLine.ReportingKindItem = Catalogs.BudgetBalanceItems.EmptyRef();
		FinancialReportingServer.QueryResultInTree(ResultsArray[2], IndicatorLine);
		If FinancialReportingServer.GetParameter(Parameters, "UseToEnterPlan", False)
			Or Parameters.TreeMode = Enums.ModesOfNewItemTreeDisplay.SelectAComplexTableCellKind Then
			IndicatorLine.ItemKind = Undefined;
		Else
			// Let's add indicators
			IndicatorLine.ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems;
		EndIf;
	EndIf;
	
	IndicatorLine = ItemsTree.Rows.Find(Enums.FinancialReportItemKinds.NonFinancialItem);
	If IndicatorLine <> Undefined Then
		IndicatorLine.Description = NStr("vi = 'Các chỉ tiêu phi tài chính';
										|ru = 'Нефинансовые показатели';
										|en = 'Non-financial items'; fa = 'اقلام غیرمالی';
										|it = 'Indicatori non finanziari';
										|pl = 'Wskaźniki niefinansowane';
										|tr = 'Finansal olmayan öğeler'");
		IndicatorLine.ReportingKindItem = Catalogs.NonFinancialItemsOfBudgets.EmptyRef();
		IndicatorLine.ItemKind = Undefined;
		FinancialReportingServer.QueryResultInTree(ResultsArray[3], IndicatorLine);
	EndIf;
	
	// Adding groupings
	If Parameters.TreeMode = Enums.ModesOfNewItemTreeDisplay.ConfigureBudgetProfile Then
		DimensionString = ItemsTree.Rows.Find(Enums.FinancialReportItemKinds.Dimension);
		If Parameters.Property("HeaderDimensions") Then
			HeaderDimensions = Parameters.HeaderDimensions;
		Else
			HeaderDimensions = New Array;
		EndIf;
		AddDimensionsToTreeOfNewItems(ItemsTree, DimensionString, 
						Parameters.BudgetingModel, Parameters.UseToEnterPlan, HeaderDimensions);
	EndIf;
	
	If ValueIsFilled(QuickSearch) Then
		CopyOfTree = ItemsTree.Copy();
		CopyOfTree.Rows.Clear();
		// Let's sort the report elements inside the views
		// and keep the order of the types of elements.
		For Each TreeRow In ItemsTree.Rows Do
			TreeRow.Rows.Sort("Description", True);
		EndDo;
		SelectItemsByQuickSearch(ItemsTree, CopyOfTree, QuickSearch);
		ItemsTree = CopyOfTree;
	EndIf;
	
	Form.ValueToFormAttribute(ItemsTree, NameOfTreeElement);
	
EndProcedure

Function QueryTextNewReportElements()
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|// 1. BASIC STRUCTURE
	|"
	+
	"SELECT
	|	ReportItemKinds.Ref AS ItemKind,
	|	PRESENTATION(ReportItemKinds.Ref) AS Description,
	|	ImageIndexTable.PictureIndex AS CustomPicture
	|FROM
	|	Enum.FinancialReportItemKinds AS ReportItemKinds
	|		LEFT JOIN ImageIndexTable AS ImageIndexTable
	|		ON ReportItemKinds.Ref = ImageIndexTable.ItemKind
	|			AND (ImageIndexTable.NameOfAuxiliaryElement = """")
	|WHERE
	|	ReportItemKinds.Ref IN(&AvailableItemKinds)
	|
	|ORDER BY
	|	ReportItemKinds.Order"
	+"
	|;";
	
	QueryText = QueryText + "
	|////////////////////////////////////////////////////////////////////////////////
	|// 2.1.1 BASIC INDICATORS ON ARTICLES_ OFBUDGETS
	|"
	+
	"SELECT ALLOWED
	|	CASE
	|		WHEN ReportElements.IsFolder
	|				AND VALUE(Enum.ModesOfNewItemTreeDisplay.ConfigureBudgetProfile) <> &TreeMode
	|			THEN UNDEFINED
	|		ELSE VALUE(Enum.FinancialReportItemKinds.BudgetFlowItem)
	|	END AS ItemKind,
	|	ReportElements.Description AS Description,
	|	"""" AS Comment,
	|	ReportElements.Ref AS ReportingKindItem,
	|	ImageIndexTable.PictureIndex AS CustomPicture,
	|	ReportElements.IsFolder
	|FROM
	|	Catalog.BudgetFlowItems AS ReportElements
	|		LEFT JOIN ImageIndexTable AS ImageIndexTable
	|		ON (CASE
	|				WHEN ReportElements.IsFolder
	|					THEN ImageIndexTable.NameOfAuxiliaryElement = ""Group""
	|				ELSE ImageIndexTable.ItemKind = VALUE(Enum.FinancialReportItemKinds.BudgetFlowItem)
	|						AND ImageIndexTable.NameOfAuxiliaryElement = """"
	|			END)
	|WHERE
	|	ReportElements.DeletionMark = FALSE
	|AUTOORDER"
	+"
	|;";
	
	QueryText = QueryText + "
	|////////////////////////////////////////////////////////////////////////////////
	|// 2.1.2 BASIC INDICATORS ON INDICATORS_ OFBUDGETING
	|"
	+
	"SELECT ALLOWED
	|	CASE
	|		WHEN ReportElements.IsFolder
	|				AND VALUE(Enum.ModesOfNewItemTreeDisplay.ConfigureBudgetProfile) <> &TreeMode
	|			THEN UNDEFINED
	|		ELSE CASE
	|				WHEN ReportElements.IndicatorType = VALUE(Enum.BudgetBalanceItemType.SpecialPurpose)
	|					THEN VALUE(Enum.FinancialReportItemKinds.BudgetFlowItem)
	|				ELSE VALUE(Enum.FinancialReportItemKinds.BudgetBalanceItem)
	|			END
	|	END AS ItemKind,
	|	ReportElements.Description AS Description,
	|	"""" AS Comment,
	|	ReportElements.Ref AS ReportingKindItem,
	|	ImageIndexTable.PictureIndex AS CustomPicture,
	|	ReportElements.IsFolder
	|FROM
	|	Catalog.BudgetBalanceItems AS ReportElements
	|		LEFT JOIN ImageIndexTable AS ImageIndexTable
	|		ON (CASE
	|				WHEN ReportElements.IsFolder
	|					THEN ImageIndexTable.NameOfAuxiliaryElement = ""Group""
	|				ELSE ImageIndexTable.ItemKind = VALUE(Enum.FinancialReportItemKinds.BudgetBalanceItem)
	|						AND ImageIndexTable.NameOfAuxiliaryElement = """"
	|			END)
	|WHERE
	|	ReportElements.DeletionMark = FALSE
	|AUTOORDER"
	+"
	|;";
	
	QueryText = QueryText + "
	|////////////////////////////////////////////////////////////////////////////////
	|// 2.1.3 BASIC INDICATORS ON NONFINANCIAL_ INDICATORS_ OFBUDGETING
	|"
	+
	"SELECT ALLOWED
	|	CASE
	|		WHEN ReportElements.IsFolder
	|				AND VALUE(Enum.ModesOfNewItemTreeDisplay.ConfigureBudgetProfile) <> &TreeMode
	|			THEN UNDEFINED
	|		ELSE VALUE(Enum.FinancialReportItemKinds.NonFinancialItem)
	|	END AS ItemKind,
	|	ReportElements.Description AS Description,
	|	"""" AS Comment,
	|	ReportElements.Ref AS ReportingKindItem,
	|	ImageIndexTable.PictureIndex AS CustomPicture,
	|	ReportElements.IsFolder
	|FROM
	|	Catalog.NonFinancialItemsOfBudgets AS ReportElements
	|		LEFT JOIN ImageIndexTable AS ImageIndexTable
	|		ON (CASE
	|				WHEN ReportElements.IsFolder
	|					THEN ImageIndexTable.NameOfAuxiliaryElement = ""Group""
	|				ELSE ImageIndexTable.ItemKind = VALUE(Enum.FinancialReportItemKinds.NonFinancialItem)
	|						AND ImageIndexTable.NameOfAuxiliaryElement = """"
	|			END)
	|WHERE
	|	ReportElements.DeletionMark = FALSE
	|AUTOORDER"
	+"
	|;";
	
	Return QueryText;
	
EndFunction

Function GetTypesOfFinancialReportElementsUsed(WorkMode, UseToEnterPlan)
	
	List = New ValueList;
	
	If WorkMode <> Enums.ModesOfNewItemTreeDisplay.SetUpAutomaticCalculationOfComplexTable Then
		List.Add(Enums.FinancialReportItemKinds.BudgetFlowItem);
		List.Add(Enums.FinancialReportItemKinds.BudgetBalanceItem);
		List.Add(Enums.FinancialReportItemKinds.NonFinancialItem);

		If WorkMode = Enums.ModesOfNewItemTreeDisplay.ConfigureBudgetProfile
			Or WorkMode = Enums.ModesOfNewItemTreeDisplay.SelectAComplexTableCellKind Then
			List.Add(Enums.FinancialReportItemKinds.DerivedItem);
		EndIf;
	EndIf;
	
	If WorkMode = Enums.ModesOfNewItemTreeDisplay.DerivedItemOfComplexTable
		Or WorkMode = Enums.ModesOfNewItemTreeDisplay.SetUpAutomaticCalculationOfComplexTable Then
		List.Add(Enums.FinancialReportItemKinds.TableCell);
	EndIf;
	
	If WorkMode = Enums.ModesOfNewItemTreeDisplay.ConfigureBudgetProfile Then
		List.Add(Enums.FinancialReportItemKinds.ReportHeader);
		List.Add(Enums.FinancialReportItemKinds.UneditedText);
		List.Add(Enums.FinancialReportItemKinds.ComplexTable);
		List.Add(Enums.FinancialReportItemKinds.Dimension);
		List.Add(Enums.FinancialReportItemKinds.Group);
		List.Add(Enums.FinancialReportItemKinds.GroupFormula);
	EndIf;
	
	If UseToEnterPlan
		And (WorkMode = Enums.ModesOfNewItemTreeDisplay.ConfigureBudgetProfile
		Or WorkMode = Enums.ModesOfNewItemTreeDisplay.SelectAComplexTableCellKind) Then
		List.Add(Enums.FinancialReportItemKinds.EditedValue);
	EndIf;
	
	Return List;
	
EndFunction

Procedure SelectItemsByQuickSearch(ItemsTree, CopyOfTree, QuickSearch)
	
	For Each TreeRow In ItemsTree.Rows Do
		If StrFind(Lower(TreeRow.Description), Lower(QuickSearch))
			And ValueIsFilled(TreeRow.ItemKind)
			And TreeRow.IsFolder = False Then
			
			FillPropertyValues(CopyOfTree.Rows.Add(), TreeRow);
			
		EndIf;
		SelectItemsByQuickSearch(TreeRow, CopyOfTree, QuickSearch);
	EndDo;
	
EndProcedure

Function AddDimensionLine(WhereToAddLine, Description, ReportItem = Undefined)
	
	NewRow = WhereToAddLine.Rows.Add();
	Dimension = Enums.FinancialReportItemKinds.Dimension;
	NewRow.ItemKind = Dimension;
	NewRow.CustomPicture = FinancialReportingCached.CustomPicture(Dimension);
	NewRow.Description = Description;
	NewRow.ReportingKindItem = ?(ReportItem = Undefined, Description, ReportItem);
	
	Return NewRow;
	
EndFunction

Procedure AddDimensionsToTreeOfNewItems(ItemsTree, DimensionString, BudgetingModel, UseToEnterPlan, HeaderDimensions)
	
	// Adding table elements
	MeasurementString_ = ItemsTree.Rows.Find(Enums.FinancialReportItemKinds.ComplexTable);
	StringElement = MeasurementString_.Rows.Add();
	RowColumn = Enums.FinancialReportItemKinds.RowColumn;
	StringElement.CustomPicture = FinancialReportingCached.CustomPicture(RowColumn);
	StringElement.Description = String(Enums.FinancialReportItemKinds.RowColumn);
	StringElement.ItemKind = Enums.FinancialReportItemKinds.RowColumn;

	MeasurementString_ = ItemsTree.Rows.Find(Enums.FinancialReportItemKinds.Dimension);
	MeasurementString_.ItemKind = Undefined; //the dimension grouping record 
	                                            // cannot be transferred to budget items
	
	// Adding a period
	
	MeasurementView = NStr("vi = 'Kỳ';
							|ru = 'Период';
							|en = 'Period'; fa = 'دوره';
							|it = 'Periodo';
							|pl = 'Okres';
							|tr = 'Dönem'");
	StringPeriod = AddDimensionLine(MeasurementString_, MeasurementView);
	StringPeriod.ItemKind = Undefined; //dimension grouping record 
	StringPeriod.IsFolder = True;         //cannot be transferred to budget items
	StringPeriod.CustomPicture = FinancialReportingServerCall.CustomPicture(Undefined, "Group");
	
	MeasurementView = String(Enums.Periodicity.Year);
	AddDimensionLine(StringPeriod, MeasurementView, Enums.Periodicity.Year);
	MeasurementView = String(Enums.Periodicity.HalfYear);
	AddDimensionLine(StringPeriod, MeasurementView, Enums.Periodicity.HalfYear);
	MeasurementView = String(Enums.Periodicity.Quarter);
	AddDimensionLine(StringPeriod, MeasurementView, Enums.Periodicity.Quarter);
	MeasurementView = String(Enums.Periodicity.Month);
	AddDimensionLine(StringPeriod, MeasurementView, Enums.Periodicity.Month);
	MeasurementView = String(Enums.Periodicity.TenDays);
	AddDimensionLine(StringPeriod, MeasurementView, Enums.Periodicity.TenDays);
	MeasurementView = String(Enums.Periodicity.Week);
	AddDimensionLine(StringPeriod, MeasurementView, Enums.Periodicity.Week);
	MeasurementView = String(Enums.Periodicity.Day);
	AddDimensionLine(StringPeriod, MeasurementView, Enums.Periodicity.Day);
	
	// adding analytics
	
	MeasurementView = NStr("vi = 'Chỉ số';
							|ru = 'Аналитика';
							|en = 'Dimension'; fa = 'بُعد';
							|it = 'Analitica';
							|pl = 'Analityka';
							|tr = 'Boyut'");
	AnalyticsLine = AddDimensionLine(MeasurementString_, MeasurementView);
	AnalyticsLine.ItemKind = Undefined; //dimension grouping record 
	AnalyticsLine.IsFolder = True;         //cannot be transferred to budget items
	AnalyticsLine.CustomPicture = FinancialReportingServerCall.CustomPicture(Undefined, "Group");
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	If Not UseToEnterPlan Then
		
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			Dimension = "Dimension" + DimensionNumber;
			MeasurementView = BudgetReportingClientServer.PresentationOfBudgetingDimension(
				Dimension);
			AddDimensionLine(AnalyticsLine, MeasurementView, Dimension);
		EndDo;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Dimension.Ref,
	|	Dimension.Description AS Description
	|FROM
	|	ChartOfCharacteristicTypes.BudgetFlowItemDimensions AS Dimension
	|WHERE
	|	NOT Dimension.DeletionMark
	|	AND NOT Dimension.Ref IN (&HeaderDimensions)
	|
	|ORDER BY
	|	Description";
	
	Query.SetParameter("UseToEnterPlan", UseToEnterPlan);
	Query.SetParameter("HeaderDimensions", HeaderDimensions);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Selection.Ref = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.Projects
			And Not GetFunctionalOption("UseProjects") Then
			Continue;
		EndIf;
		AddDimensionLine(AnalyticsLine, Selection.Description, Selection.Ref);
	EndDo;
	
	// Adding an organization
	
	If GetFunctionalOption("GenerateBudgetsByCompanies", 
			New Structure("BudgetingModel", BudgetingModel))
			And Not UseToEnterPlan Then
		Dimension = "Organization";
		MeasurementView = BudgetReportingClientServer.PresentationOfBudgetingDimension(
			Dimension);
		AddDimensionLine(MeasurementString_, MeasurementView, Dimension);
	EndIf;
	
	// Adding a division
	
	If GetFunctionalOption("GenerateBudgetsByBusinessUnits", 
			New Structure("BudgetingModel", BudgetingModel))
			And Not UseToEnterPlan Then
		Dimension = "Department";
		MeasurementView = BudgetReportingClientServer.PresentationOfBudgetingDimension(
			Dimension);
		AddDimensionLine(MeasurementString_, MeasurementView, Dimension);
	EndIf;
	
	// adding a script
	
	If Not UseToEnterPlan Then
		Dimension = "Scenario";
		MeasurementView = BudgetReportingClientServer.PresentationOfBudgetingDimension(
			Dimension);
		AddDimensionLine(MeasurementString_, MeasurementView, Dimension);
	EndIf;
	
	// adding currency
	
	If Not GetFunctionalOption("NotUseMultipleCurrencies") Then
		Dimension = "Currency";
		MeasurementView = BudgetReportingClientServer.PresentationOfBudgetingDimension(
			Dimension);
		AddDimensionLine(MeasurementString_, MeasurementView, Dimension);
	EndIf;
	
EndProcedure

Function DimensionValueIsSetBySelection(FilterElement)
	
	If FilterElement = Undefined Then
		Return False;
	EndIf;
	
	If FilterElement.Parent <> Undefined Then
		Return False;
	EndIf;
	
	If Not (FilterElement.Use And FilterElement.ComparisonType = DataCompositionComparisonType.Equal)
		And Not (FilterElement.Use And FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled) Then
		
		If FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
			If Not (TypeOf(FilterElement.RightValue) = Type("ValueList")
			   And FilterElement.RightValue.Count() = 1) Then
				
				Return False;
				
			EndIf;
		Else
			
			Return False;
			
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

Function ConvertPeriodBySourceRule(Parameters, SourceRule)
	
	Query = New Query;
	Query.Text = "SELECT &PeriodExpression";
	Query.Text = StrReplace(Query.Text, "&PeriodExpression", SourceRule);
	Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", Parameters.EndOfPeriod);
	Query.SetParameter("ActualDataLimit", Parameters.ActualDataLimit);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	Return Selection[0];
	
EndFunction

Function OffsetGroupingPeriod(Period, OffsetFrequency, PeriodOfShift)
	
	If Not ValueIsFilled(OffsetFrequency)
		Or Not ValueIsFilled(PeriodOfShift) Then
		
		Return Period;
		
	EndIf;
	
	PeriodExpression = StringFunctionsClientServer.SubstituteParametersToString(
		"AddToDate(&Period, %1, -%2)",
		FinancialReportingClientServerCached.PeriodicityByString(OffsetFrequency),
		PeriodOfShift);
	Query = New Query();
	Query.Text = "SELECT &PeriodExpression";
	Query.Text = StrReplace(Query.Text, "&PeriodExpression", PeriodExpression);
	Query.SetParameter("Period", Period);
	
	Return Query.Execute().Unload()[0][0];
	
EndFunction

Function GetReportParameters(ReportParameters, CellData_, RelatedDataString, TypeOfDecryption, IndicatorName)
	
	FixedSettings = New DataCompositionSettings();
	ColumnStructure1 = BudgetReportingCacheCalculationServer.ColumnsOfDataTable_(ReportParameters.BudgetProfile);
	
	DataSources = BudgetReportingCacheCalculationServer.GetDescriptionOfDataSources(
		ReportParameters.BudgetProfile,
		ColumnStructure1,
		ReportParameters.GenerationMode);
	
	StructureOfReportDescription = BudgetReportingCacheCalculationServer.DescriptionOfReport(
		ReportParameters.BudgetProfile,
		ColumnStructure1,
		ReportParameters.GenerationMode);
	
	CellStructure = StructureOfReportDescription.CellStructure;
	CellStructureString = CellStructure.Find(RelatedDataString.RowIndex, "RowIndex");
	
	ElementViewParameters = Undefined;
	AttributesNames = "";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AttributesNames = AttributesNames + ?(AttributesNames = "", "", ",")+ "DimensionKind" + DimensionNumber;
	EndDo;
	// For articles and indicators, the available analytics should be indicated.
	If TypeOfDecryption = "NonFinancialItem" Then
		ReportItem = RelatedDataString.NonFinancialItem;
		AttributesNames = AttributesNames + "," + "ByCompanies" + "," + "ByBusinessUnits" + "," + "ByScenarios";
		If ValueIsFilled(ReportItem) Then
			ElementViewParameters = Common.ObjectAttributesValues(ReportItem, AttributesNames);
		Else
			ElementViewParameters = New Structure(AttributesNames);
			ElementViewParameters.ByCompanies = False;
			ElementViewParameters.ByBusinessUnits = False;
			ElementViewParameters.ByScenarios = False;
		EndIf;
	EndIf;
	
	For Each Dimension In ColumnStructure1.Dimensions Do
		
		If Dimension = "UnitOfMeasure" Then
			Continue;
		EndIf;
		
		If CellStructureString["Flag" + Dimension] = "fill"
			Or CellStructureString["Flag" + Dimension] = "pick" Then
			
			If Not ElementViewParameters = Undefined Then
				If Dimension = "Organization" Then
					If Not ElementViewParameters.ByCompanies Then
						Continue;
					EndIf;
				ElsIf Dimension = "Department" Then
					If Not ElementViewParameters.ByBusinessUnits Then
						Continue;
					EndIf;
				ElsIf Dimension = "Scenario" Then
					If Not ElementViewParameters.ByScenarios Then
						Continue;
					EndIf;
				EndIf;
			EndIf;
			
			Filter = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			Filter.LeftValue = New DataCompositionField(Dimension);
			If ValueIsFilled(RelatedDataString[Dimension]) Then
				Filter.ComparisonType = DataCompositionComparisonType.Equal;
				Filter.RightValue = RelatedDataString[Dimension];
			Else
				Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
			EndIf;
			Filter.Use = True;
			
		EndIf;
		
	EndDo;
	
	ArrayOfAnalyticsWithHierarchy = New Array;
	
	For Each DimensionKind In ColumnStructure1.DimensionKinds Do
		Dimension = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		
		If Not ElementViewParameters = Undefined Then
			ThereIsAnalytics = False;
			For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
				If ElementViewParameters["DimensionKind" + DimensionNumber] = DimensionKind Then
					ThereIsAnalytics = True;
					Break;
				EndIf;
			EndDo;
			If Not ThereIsAnalytics Then
				Continue;
			EndIf;
		EndIf;
		
		If CellStructureString["Flag" + Dimension] = "fill"
			Or CellStructureString["Flag" + Dimension] = "pick" Then
			
			Filter = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			Filter.LeftValue = New DataCompositionField(Dimension);
			If RelatedDataString[Dimension] = Undefined Then
				Filter.ComparisonType = DataCompositionComparisonType.InList;
				Filter.RightValue = BudgetingCached.EmptyAnalyticsValues();
				StringPresentation  = NStr("vi = 'Chỉ số ""%1"" trống';
											|ru = 'Аналитика ""%1"" не заполнена';
											|en = 'Dimension ""%1"" is required'; fa = 'Dimension ""%1"" is required';
											|it = 'Analitica ""%1"" non compilata';
											|pl = 'Analityka ""%1"" nie jest wypełniona';
											|tr = '""%1"" boyutu doldurulmamış'");
				Filter.Presentation  = StringFunctionsClientServer.SubstituteParametersToString(StringPresentation, DimensionKind);
			Else
				// If a hierarchical grouping is displayed on this line, then the type of Comparison should be In the hierarchy
				If RelatedDataString.HierarchyOutput Then
					Filter.ComparisonType = DataCompositionComparisonType.InHierarchy;
					ArrayOfAnalyticsWithHierarchy.Add(DimensionKind);
				Else
					Filter.ComparisonType = DataCompositionComparisonType.Equal;
				EndIf;
				Filter.RightValue = RelatedDataString[Dimension];
			EndIf;
			Filter.Use = True;
			
		ElsIf CellStructureString["Flag" + Dimension] = "otheritems"
			Or CellStructureString["Flag" + Dimension] = "document" Then
			
			Filter = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			Filter.LeftValue = New DataCompositionField(Dimension);
			Filter.ComparisonType = DataCompositionComparisonType.NotInList;
			
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("Parent" + Dimension, CellStructureString["Parent" + Dimension]);
			TheStructureOfTheSearch.Insert("Flag" + Dimension, "pick");
			
			CopyOfTableForList = CellStructure.Copy(TheStructureOfTheSearch);
			CopyOfTableForList.GroupBy(Dimension);
			Array = CopyOfTableForList.UnloadColumn(Dimension);
			ValueList = New ValueList;
			ValueList.LoadValues(Array);
			
			Filter.ComparisonType = DataCompositionComparisonType.NotInList;
			Filter.RightValue = ValueList;
			Filter.Use = True;
			
		EndIf;
	EndDo;
	
	For Each KeyAndValue In ReportParameters.AdditionalFiltersForAnalytics Do
		
		Dimension = KeyAndValue.Key;
		Value = Undefined;
		Used = ReportParameters.Property(KeyAndValue.Key, Value);
		Filter = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField(Dimension);
		Filter.ComparisonType = DataCompositionComparisonType.InList;
		Filter.RightValue = Value;
		Filter.Use = Used;
		
	EndDo;
	
	For Each Source In DataSources Do
		If Source.Id = CellStructureString.ID_Source1 Then
			Break;
		EndIf;
	EndDo;
	
	AnalyticsSettings = Undefined;
	If ValueIsFilled(RelatedDataString.BudgetBalanceItem) Then
		Filter = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField("BudgetBalanceItem");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = RelatedDataString.BudgetBalanceItem;
		Filter.Use = True;
		AnalyticsSettings = RelatedDataString.BudgetBalanceItem;
	EndIf;
	
	If ValueIsFilled(RelatedDataString.BudgetFlowItem) Then
		Filter = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField("BudgetFlowItem");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = RelatedDataString.BudgetFlowItem;
		Filter.Use = True;
		If AnalyticsSettings = Undefined Then
			AnalyticsSettings = RelatedDataString.BudgetFlowItem;
		EndIf;
	EndIf;
	
	If ValueIsFilled(RelatedDataString.NonFinancialItem) Then
		Filter = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField("NonFinancialItem");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = RelatedDataString.NonFinancialItem;
		Filter.Use = True;
		If AnalyticsSettings = Undefined Then
			AnalyticsSettings = RelatedDataString.NonFinancialItem;
		EndIf;
	EndIf;
	
	BeginOfPeriod = ConvertPeriodBySourceRule(ReportParameters, Source.ExpressionStartOfPeriod);
	EndOfPeriod = ConvertPeriodBySourceRule(ReportParameters, Source.ExpressionEndOfPeriod);
	
	MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(ColumnStructure1.Periodicity_);
	If MinimumPeriodicity <> Undefined Then
		PeriodValue = RelatedDataString[FinancialReportingClientServer.PeriodStrings(MinimumPeriodicity).Period];
		If ValueIsFilled(PeriodValue) Then
			
			For Each SourceOfGroupingPeriods In StructureOfReportDescription.SourcesOfGroupingPeriods Do
				If SourceOfGroupingPeriods.Id = CellStructureString.Id_OfSource Then
					Break;
				EndIf;
			EndDo;
			
			BeginOfPeriod = PeriodValue;
			EndOfPeriod  = WorkingWithClientServerPeriods.PeriodEndDate_(BeginOfPeriod, MinimumPeriodicity);
			
			If ValueIsFilled(Source.OffsetFrequency)
			   And ValueIsFilled(Source.PeriodOfShift) Then
				
				BeginOfPeriod = OffsetGroupingPeriod(BeginOfPeriod, Source.OffsetFrequency, Source.PeriodOfShift);
				EndOfPeriod  = OffsetGroupingPeriod(EndOfPeriod,  Source.OffsetFrequency, Source.PeriodOfShift);
				
			EndIf;
			
		EndIf;
	EndIf;
	
	Period = New StandardPeriod(BeginOfPeriod, EndOfPeriod);
	
	Parameter = FixedSettings.DataParameters.Items.Add();
	Parameter.Parameter = New DataCompositionParameter("Period");
	Parameter.Value = Period;
	Parameter.Use = True;
	
	If Not TypeOfDecryption = "NonFinancialItem" Then
	
		Parameter = FixedSettings.DataParameters.Items.Add();
		Parameter.Parameter = New DataCompositionParameter("DateWhenTheDataIsUpToDate");
		Parameter.Value = EndOfDay(ReportParameters.UpdateDate);
		Parameter.Use = True;
		
		Parameter = FixedSettings.DataParameters.Items.Add();
		Parameter.Parameter = New DataCompositionParameter("Currency");
	
		ThereIsCurrency = ColumnStructure1.Dimensions.Find("Currency") <> Undefined And ValueIsFilled(RelatedDataString.Currency);
		
		If ThereIsCurrency Then
			Parameter.Value = RelatedDataString.Currency;
		Else
			Parameter.Value = ReportParameters.ReportCurrency;
		EndIf;
		Parameter.Use = True;
		
		If ReportParameters.Property("FunctionalCurrency") And ValueIsFilled(ReportParameters.FunctionalCurrency) Then
			Parameter = FixedSettings.DataParameters.Items.Add();
			Parameter.Parameter = New DataCompositionParameter("FunctionalCurrency");
			Parameter.Value = ReportParameters.FunctionalCurrency;
			Parameter.Use = True;
		EndIf;
		
		Parameter = FixedSettings.DataParameters.Items.Add();
		Parameter.Parameter = New DataCompositionParameter("TurnoversInStatuses");
		Parameter.Value = ReportParameters.Status;
		Parameter.Use = True;
		
		FinancialReportingServer.CopyFilter(Source.AdditionalSelection.Filter, FixedSettings.Filter);
		BudgetReportingDisplayServer.AddDCSSettingsBeforeOutput(FixedSettings, ReportParameters);
		
	Else
		
		Parameter = FixedSettings.DataParameters.Items.Add();
		Parameter.Parameter = New DataCompositionParameter("Periodicity");
		If MinimumPeriodicity <> Undefined Then
			PeriodicityValue_ = MinimumPeriodicity
		Else
			PeriodicityValue_ = ReportParameters.BudgetProfile.Periodicity;
		EndIf;
		Parameter.Value = PeriodicityValue_;
		Parameter.Use = True;
		
	EndIf;
	
	SignsOfMeasurements = New Structure;
	Parameters = New Structure("BudgetingModel", ReportParameters.BudgetProfile.Owner);
	SignsOfMeasurements.Insert("ByCompanies", GetFunctionalOption("GenerateBudgetsByCompanies", Parameters));
	SignsOfMeasurements.Insert("ByBusinessUnits", GetFunctionalOption("GenerateBudgetsByBusinessUnits", Parameters));
	SignsOfMeasurements.Insert("ByScenarios", True);
	
	If ValueIsFilled(AnalyticsSettings) Then
		
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		AttributesStructure1 = New Structure();
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			AttributesStructure1.Insert("Dimension" + DimensionNumber, "DimensionKind" + DimensionNumber);
		EndDo;
		
		If TypeOf(AnalyticsSettings) = Type("CatalogRef.NonFinancialItemsOfBudgets") Then
			AttributesStructure1.Insert("ByCompanies");
			AttributesStructure1.Insert("ByBusinessUnits");
			AttributesStructure1.Insert("ByScenarios");
		EndIf;
		
		AnalyticsSettings = Common.ObjectAttributesValues(AnalyticsSettings, AttributesStructure1);
		
		If AnalyticsSettings.Property("ByCompanies") Then
			FillPropertyValues(SignsOfMeasurements, AnalyticsSettings, "ByCompanies, ByBusinessUnits");
			SignsOfMeasurements.Insert("ByScenarios", False);
		EndIf;
		
	EndIf;
	
	ArrayOfDimensionsToAdd = New Array;
	
	ArrayOfDimensionsToAdd.Add(TypeOfDecryption);
	If SignsOfMeasurements.ByScenarios Then
		ArrayOfDimensionsToAdd.Add("Scenario");
	EndIf;
	If SignsOfMeasurements.ByCompanies Then
		ArrayOfDimensionsToAdd.Add("Organization");
	EndIf;
	If SignsOfMeasurements.ByBusinessUnits Then
		ArrayOfDimensionsToAdd.Add("Department");
	EndIf;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		ArrayOfDimensionsToAdd.Add("Dimension" + Cnt);
	EndDo;
	
	If MinimumPeriodicity <> Undefined Then
		If TypeOfDecryption = "NonFinancialItem" Then
			ArrayOfDimensionsToAdd.Add("Period");
		Else
			ArrayOfDimensionsToAdd.Add(FinancialReportingClientServer.PeriodStrings(MinimumPeriodicity).Period);
		EndIf;
	EndIf;
	
	ArrayOfReportDimensions = New Array;
	
	If TypeOfDecryption <> "NonFinancialItem" Then
		
		For Each Item In ArrayOfDimensionsToAdd Do
			
			FilterElement = FinancialReportingServer.FindSelectionElement(FixedSettings.Filter, Item);
			
			If DimensionValueIsSetBySelection(FilterElement) Then
				Continue;
			EndIf;
			
			If ValueIsFilled(AnalyticsSettings) Then
				
				If StrFind(Item, "Dimension") Then
					DimensionKind = AnalyticsSettings[Item];
					If ValueIsFilled(DimensionKind) Then
						FieldName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
						FilterElement = FinancialReportingServer.FindSelectionElement(FixedSettings.Filter, FieldName);
						If DimensionValueIsSetBySelection(FilterElement) Then
							Continue;
						EndIf;
					Else
						Continue;
					EndIf;
				EndIf;
				
			EndIf;
			
			ArrayOfReportDimensions.Add(Item);
			
		EndDo;
		
	EndIf;
	
	If Not ArrayOfReportDimensions.Count() Then
		If TypeOfDecryption = "BudgetBalanceItem" Then
			ArrayOfReportDimensions.Add("BudgetBalanceItem");
		ElsIf TypeOfDecryption = "BudgetFlowItem" Then
			ArrayOfReportDimensions.Add("BudgetFlowItem");
		ElsIf TypeOfDecryption = "NonFinancialItem" Then
			ArrayOfReportDimensions.Add("NonFinancialItem");
		EndIf;
		
		ArrayOfReportDimensions.Add("Recorder");
	EndIf;
	
	NewGrouping = Undefined;
	For Each ArrayElement In ArrayOfReportDimensions Do
		DimensionKind = Undefined;
		If AnalyticsSettings.Property(ArrayElement, DimensionKind)
			And ArrayOfAnalyticsWithHierarchy.Find(DimensionKind) <> Undefined Then
			GroupType = DataCompositionGroupType.Hierarchy;
		Else
			GroupType = DataCompositionGroupType.Items;
		EndIf;
		If NewGrouping = Undefined Then
			NewGrouping = FinancialReportingServer.NewGrouping(FixedSettings.Structure, ArrayElement, GroupType);
		Else
			NewGrouping = FinancialReportingServer.NewGrouping(NewGrouping, ArrayElement, GroupType);
		EndIf;
	EndDo;
	
	If TypeOfDecryption = "BudgetBalanceItem" Then
		
		SelectionField_ = FixedSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectionField_.Field = New DataCompositionField(IndicatorName + "InitialScriptRemainder");
		SelectionField_.Use = True;
		SelectionField_.Title = NStr("vi = 'Số dư đầu';
									|ru = 'Начальный остаток';
									|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
									|it = 'Saldo iniziale';
									|pl = 'Saldo początkowe';
									|tr = 'Açılış bakiyesi'");
		
		SelectionField_ = FixedSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectionField_.Field = New DataCompositionField(IndicatorName + "ArrivalOfScript");
		SelectionField_.Use = True;
		SelectionField_.Title = NStr("vi = 'Nhập';
									|ru = 'Приход';
									|en = 'Receipt'; fa = 'دریافت';
									|it = 'Entrata';
									|pl = 'Wpłynięcie';
									|tr = 'Giriş'");
		
		SelectionField_ = FixedSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectionField_.Field = New DataCompositionField(IndicatorName + "ScriptConsumption");
		SelectionField_.Use = True;
		SelectionField_.Title = NStr("vi = 'Chi phí';
									|ru = 'Расход';
									|en = 'Expense'; fa = 'هزینه';
									|it = 'Uscita';
									|pl = 'Rozchód';
									|tr = 'Çıkış'");
		
		SelectionField_ = FixedSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectionField_.Field = New DataCompositionField(IndicatorName + "ScriptTurnover");
		SelectionField_.Use = True;
		SelectionField_.Title = NStr("vi = 'Phát sinh ( Thu- Chi)';
									|ru = 'Оборот (Приход - Расход)';
									|en = 'Turnover (Inflow - Outflow)'; fa = 'Turnover (Inflow - Outflow)';
									|it = 'Movimento (Entrata  - Spesa)';
									|pl = 'Obrót (Wpłata - Rozchód)';
									|tr = 'Ciro (Gelir - Gider)'");
		
		SelectionField_ = FixedSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectionField_.Field = New DataCompositionField(IndicatorName + "FinalRemainderOfScript");
		SelectionField_.Use = True;
		SelectionField_.Title = NStr("vi = 'Số dư cuối';
									|ru = 'Конечный остаток';
									|en = 'Closing balance'; fa = 'مانده پایان دوره';
									|it = 'Saldo finale';
									|pl = 'Saldo końcowe';
									|tr = 'Kapanış bakiyesi'");
		
	ElsIf TypeOfDecryption = "BudgetFlowItem" Then
		
		SelectionField_ = FixedSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectionField_.Field = New DataCompositionField(IndicatorName + "Script_");
		SelectionField_.Use = True;
		If IndicatorName = "Sum" Then
			SelectionField_.Title = NStr("vi = 'Số tiền kịch bản';
										|ru = 'Сумма сценария';
										|en = 'Scenario amount'; fa = 'مبلغ سناریو';
										|it = 'Importo di scenario';
										|pl = 'Wartość scenariusza';
										|tr = 'Senaryo tutarı'");
		ElsIf IndicatorName = "Count" Then
			SelectionField_.Title = NStr("vi = 'Số lượng kịch bản';
										|ru = 'Количество сценария';
										|en = 'Number of scenario'; fa = 'تعداد سناریو';
										|it = 'Numero di script';
										|pl = 'Ilość scenariusza';
										|tr = 'Senaryo sayısı'");
		Else
			SelectionField_.Title = NStr("vi = 'Giá trị kịch bản';
										|ru = 'Значение сценария';
										|en = 'Value of scenario'; fa = 'Value of scenario';
										|it = 'Valore di scenario';
										|pl = 'Wartość scenariusza';
										|tr = 'Senaryo değeri'");
		EndIf;
		
	ElsIf TypeOfDecryption = "NonFinancialItem" Then
		
		SelectionField_ = FixedSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectionField_.Field = New DataCompositionField("IndicatorValue");
		SelectionField_.Use = True;
		SelectionField_.Title = NStr("vi = 'Giá trị';
									|ru = 'Значение';
									|en = 'Value'; fa = 'مقدار';
									|it = 'Valore';
									|pl = 'Value';
									|tr = 'Değer'");
		
	EndIf;
	
	Return FixedSettings;
	
EndFunction

Function ParametersForOpeningDecryptionReport(GenerationParameters, Details, AddressOfCellData) Export
	
	CellData_ = GetFromTempStorage(AddressOfCellData); // ValueTable -
	RelatedDataString = CellData_[Details.DataLineIndex];
	IndicatorName = Details.IndicatorName;
	
	ColumnStructure1 = BudgetReportingCacheCalculationServer.ColumnsOfDataTable_(GenerationParameters.BudgetProfile);
	StructureOfReportDescription = BudgetReportingCacheCalculationServer.DescriptionOfReport(
		GenerationParameters.BudgetProfile,
		ColumnStructure1,
		GenerationParameters.GenerationMode);
	
	CellParameters = StructureOfReportDescription.CellParameters;
	
	If RelatedDataString.MainItem Then
		TypeOfElementToDecrypt = RelatedDataString.ItemKind;
	Else
		TypeOfElementToDecrypt = RelatedDataString.OperandType;
	EndIf;
	
	DetailsParameters = New Structure;
	If TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.BudgetFlowItem
		Or TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.AllBudgetFlowItems
		Or TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.BudgetBalanceItem
		Or TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.AllBudgetBalanceItems
		Or TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.NonFinancialItem Then
		
		If TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.BudgetFlowItem
			Or TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.AllBudgetFlowItems Then
			DetailsParameters.Insert("FormName", "Report.BudgetingTurnoverBalanceReport.Form");
			TypeOfDecryption = "BudgetFlowItem";
		ElsIf TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.BudgetBalanceItem
			Or TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
			DetailsParameters.Insert("FormName", "Report.TrialBalanceForBudgetBalanceItems.Form");
			TypeOfDecryption = "BudgetBalanceItem";
		ElsIf TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.NonFinancialItem Then
			DetailsParameters.Insert("FormName", "Report.NonFinancialItemValues.Form");
			TypeOfDecryption = "NonFinancialItem";
		EndIf;
		
		FixedSettings = GetReportParameters(GenerationParameters, CellData_, RelatedDataString, TypeOfDecryption, IndicatorName);
		ReportParameters = New Structure();
		ReportParameters.Insert("FixedSettings", FixedSettings);
		ReportParameters.Insert("VariantKey", "Details");
		ReportParameters.Insert("GenerateOnOpen", True);
		ReportParameters.Insert("ReportOptionsCommandsVisibility", False);
		
		ReportParametersToStore = New Structure;
		IndexRelatedDataRow = CellData_.IndexOf(RelatedDataString);
		ReportParametersToStore.Insert("DataLineIndex", IndexRelatedDataRow);
		ReportParameters.Insert("ReportParametersToStore", ReportParametersToStore);
		
		DetailsParameters.Insert("ReportParameters", ReportParameters);
		
	ElsIf TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.DerivedItem
		Or TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.GroupFormula
		Or TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.Group Then
		
		If RelatedDataString.ItemKind = Enums.FinancialReportItemKinds.Group Then
			CalculationLog = New Array;
			PeriodParameters_1 = BudgetReportingDisplayServer.ConvertDataParametersToPeriodData(ColumnStructure1, GenerationParameters);
			
			ParametersForCalculatingValue = BudgetReportingDisplayServer.TemplateForCellValueCalculationParameters();
			ParametersForCalculatingValue.CellData_       = CellData_;
			ParametersForCalculatingValue.CellParameters    = CellParameters;
			ParametersForCalculatingValue.PeriodParameters_1 = PeriodParameters_1;
			ParametersForCalculatingValue.DataString1      = RelatedDataString;
			ParametersForCalculatingValue.Prefix           = IndicatorName;
			ParametersForCalculatingValue.CalculatingChanges   = False;
			ParametersForCalculatingValue.CacheOfBudgetItemDetails = Undefined;
			BudgetReportingDisplayServer.CalculateCellValue(ParametersForCalculatingValue, CalculationLog);
			
			IndexRelatedDataRow = CalculationLog[0].StringBase;
		Else
			IndexRelatedDataRow = CellData_.IndexOf(RelatedDataString);
		EndIf;
		
		ReportParametersToStore = New Structure;
		For Each KeyAndValue In GenerationParameters Do
			// Skip the auxiliary parameters to fill
			// in the budget instance.
			If TypeOf(KeyAndValue.Value) = Type("ValueTable")
				Or TypeOf(KeyAndValue.Value) = Type("Structure") Then
				Continue;
			EndIf;
			
			ReportParametersToStore.Insert(KeyAndValue.Key, KeyAndValue.Value);
			
		EndDo;
		ReportParametersToStore.Insert("AdditionalFiltersForAnalytics", 	GenerationParameters.AdditionalFiltersForAnalytics);
		ReportParametersToStore.Insert("AddressOfCellData", 	AddressOfCellData);
		ReportParametersToStore.Insert("DataLineIndex", 	IndexRelatedDataRow);
		ReportParametersToStore.Insert("IndicatorName", 		IndicatorName);
		
		ReportParameters = New Structure();
		ReportParameters.Insert("VariantKey", "BudgetReportFormulaDrillDown");
		ReportParameters.Insert("GenerateOnOpen", True);
		ReportParameters.Insert("CloseOnOwnerClose", True);
		ReportParameters.Insert("ReportParametersToStore", ReportParametersToStore);
		
		DetailsParameters.Insert("FormName", "Report.BudgetReportFormulaDrillDown.Form");
		DetailsParameters.Insert("ReportParameters", ReportParameters);
		
	Else
		
		Raise NStr("vi = 'Mục không rõ để giải thích';
					|ru = 'Неизвестный элемент для расшифровки';
					|en = 'Unknown item for drill-down'; fa = 'Unknown item for drill-down';
					|it = 'Elemento sconosciuto per la decodifica';
					|pl = 'Nieznany element do rozszyfrowania';
					|tr = 'Deşifre için bilinmeyen öğe'") 
		
	EndIf;
	
	Return DetailsParameters;
	
EndFunction

// Returns the structure of decryption parameters.
// 
// Parameters:
// 	ExplanationAddress - String - the address of the temporary storage.
// Returns:
// 	Structure - Structure of decryption parameters:
// 	 *Items - Structure -
Function DecryptionDataAtTemporaryStorageAddress(ExplanationAddress)
	DetailsData = GetFromTempStorage(ExplanationAddress);
	Return DetailsData;
EndFunction

Function DecryptionFormParametersForDecryptionReport(Details, ExplanationAddress) Export
	
	DetailsData = DecryptionDataAtTemporaryStorageAddress(ExplanationAddress);
	Fields = DetailsData.Items[Details].GetFields();
	AddressOfDecryptionParameters = Fields.Find("ReportParametersAddress").Value;
	If AddressOfDecryptionParameters = Undefined Then
		Return Undefined;
	EndIf;
	ReportParameters = GetFromTempStorage(AddressOfDecryptionParameters);
	DataLineIndex = Fields.Find("DataLineIndex").Value;
	IndicatorName = Fields.Find("IndicatorName").Value;
	
	DataParameters = New Structure("DataLineIndex, IndicatorName", DataLineIndex, IndicatorName);
	
	Return ParametersForOpeningDecryptionReport(ReportParameters, DataParameters, ReportParameters.AddressOfCellData);
	
EndFunction

Function SettingsForAdditionalFields(Val Object, Val DimensionKind, Val TheseAreLines) Export
	
	FormParameters = New Structure();
	FormParameters.Insert("ValueType", GeneralPurposeTMServerCall.ObjectAttributeValue(DimensionKind, "ValueType"));
	FormParameters.Insert("AdditionalFields", PutToTempStorage(Object.AdditionalFields.Unload()));
	FormParameters.Insert("TheseAreLines", TheseAreLines);
	Return FormParameters;
	
EndFunction

Procedure ReflectDocumentsAsBackgroundTaskOnFormWithMaximumPeriod(TimeIntervals) Export
	
	BeginOfPeriod = Date(3999, 12, 31);
	EndOfPeriod = Date(1, 1, 1);
	
	For Each Period In TimeIntervals Do
		
		BeginOfPeriod = Min(BeginOfPeriod, Period);
		EndOfPeriod = Max(EndOfPeriod, Period);
		
	EndDo;
	
	ActualBudgetingDataServer.ReflectDocumentsAsBackgroundTask(BeginOfPeriod, EndOfPeriod);
	
EndProcedure

Function NeedToIncreaseNumber(Id, OperandIndex, OperandsTable)
	
	If TypeOf(OperandIndex) = Type("Number") Then
		Operand = OperandsTable.FindByID(OperandIndex);
	Else
		Operand = OperandIndex;
	EndIf;
		
	For Each OperandString_ In OperandsTable Do
		If OperandString_.Id = Id Then
			
			If Operand.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.TableCell") Then
				
				If FinancialReportingServerCall.ValueOfAdditionalProps(Operand.AddressOfItemStructure, "CellRow")
					<> FinancialReportingServerCall.ValueOfAdditionalProps(OperandString_.AddressOfItemStructure, "CellRow")
					Or FinancialReportingServerCall.ValueOfAdditionalProps(Operand.AddressOfItemStructure, "CellColumn")
					<> FinancialReportingServerCall.ValueOfAdditionalProps(OperandString_.AddressOfItemStructure, "CellColumn") Then
					
					Return True;
					
				EndIf;
				
			ElsIf Operand.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.BudgetFlowItem") Then
				
				If ValueIsFilled(OperandString_.AddressOfItemStructure) Then
					BudgetFlowItem = FinancialReportingServerCall.ValueOfAdditionalProps(
															OperandString_.AddressOfItemStructure, "BudgetFlowItem");
				Else
					BudgetFlowItem = OperandString_.ItemIndicatorDimensionType;
				EndIf;
				
				If Operand.ReportingKindItem <> BudgetFlowItem Then
					Return True;
				EndIf;
				
			ElsIf Operand.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.BudgetBalanceItem") Then
				
				If ValueIsFilled(OperandString_.AddressOfItemStructure) Then
					BudgetBalanceItem = FinancialReportingServerCall.ValueOfAdditionalProps(
														OperandString_.AddressOfItemStructure, "BudgetBalanceItem");
				Else
					BudgetBalanceItem = OperandString_.ItemIndicatorDimensionType;
				EndIf;
				
				If Operand.ReportingKindItem <> BudgetBalanceItem Then
					Return True;
				EndIf;
				
			ElsIf Operand.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.NonFinancialItem") Then
				
				If ValueIsFilled(OperandString_.AddressOfItemStructure) Then
					NonFinancialItem = FinancialReportingServerCall.ValueOfAdditionalProps(
														OperandString_.AddressOfItemStructure, "NonFinancialItem");
				Else
					NonFinancialItem = OperandString_.ItemIndicatorDimensionType;
				EndIf;
				
				If Operand.ReportingKindItem <> NonFinancialItem Then
					Return True;
				EndIf;
				
			EndIf;
			
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Returns the ID of the operand with the increased ID number.
// 
// Parameters:
// 	Id - String - ID.
// 	OperandID - Number - ID of the operand string in the operand table.
// 							- Structure - structure with properties:
// 							  *ItemKind - EnumRef.FinancialReportItemKinds - The type of the operand.
// 							  *ReportingKindItem - CatalogRef.BudgetFlowItems -
// 	 						  							- CatalogRef.BudgetBalanceItems -
// 	 						  							- CatalogRef.NonFinancialItemsOfBudgets -
// 	 						  							- String -
// 	 						  							- EnumRef.Periodicity -
// 	 						  							- ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions -
// 	 						  							- CatalogRef.BudgetingScenarios -
// 	 						  							- CatalogRef.Companies - 
// 	 						  							- CatalogRef.BusinessStructure - An element of the reporting type.
// 	OperandsTable - ValueTable - Table of operands with columns:
// 	 *Id - String - ID of the operand.
// Returns:
// 	String - The new ID value.
// 	
Function IncreaseIDNumerator(Val Id, Val OperandID, Val OperandsTable) Export
	
	Result = Id;
	Cnt = 0;
	While NeedToIncreaseNumber(Id, OperandID, OperandsTable) Do
		Cnt = Cnt + 1;
		Id = Result + "_" + Format(Cnt, "NG=");
	EndDo;
	
	Return Id;
	
EndFunction

Function BudgetingModelsWithSelectionByDate(Date) Export
	
	Query = New Query("SELECT
	|	BudgetingModels.Ref AS Value,
	|	BudgetingModels.Presentation AS Presentation
	|FROM
	|	Catalog.BudgetingModels AS BudgetingModels
	|WHERE
	|	BudgetingModels.Status = &Status
	|	AND BudgetingModels.ValidOnDate <= &Date
	|	AND (BudgetingModels.ValidToDate = &DateEmpty
	|			OR BudgetingModels.ValidToDate >= &Date)
	|	AND NOT BudgetingModels.DeletionMark");
	
	Query.SetParameter("Status", Enums.BudgetingModelStatuses.Valid);
	Query.SetParameter("Date",   Date);
	Query.SetParameter("DateEmpty", '00010101000000');
	
	Selection = Query.Execute().Select();
	
	ChoiceData = New ValueList;
	
	While Selection.Next() Do
		FillPropertyValues(ChoiceData.Add(), Selection);
	EndDo;
	
	Return ChoiceData;
	
EndFunction

Function BudgetingModelsWithSelectionByPeriod(BeginOfPeriod, PeriodEnding) Export
	
	Query = New Query("SELECT
	|	BudgetingModels.Ref AS Value,
	|	BudgetingModels.Presentation AS Presentation
	|FROM
	|	Catalog.BudgetingModels AS BudgetingModels
	|WHERE
	|	BudgetingModels.Status = &Status
	|	AND BudgetingModels.ValidOnDate <= &BeginOfPeriod
	|	AND (BudgetingModels.ValidToDate = &DateEmpty
	|			OR BudgetingModels.ValidToDate >= &PeriodEnding)
	|	AND NOT BudgetingModels.DeletionMark
	|
	|ORDER BY
	|	DeletionMark");
	
	Query.SetParameter("Status", Enums.BudgetingModelStatuses.Valid);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("DateEmpty", '00010101000000');
	
	Selection = Query.Execute().Select();
	
	ChoiceData = New ValueList;
	
	While Selection.Next() Do
		FillPropertyValues(ChoiceData.Add(), Selection);
	EndDo;
	
	Return ChoiceData;
	
EndFunction

Procedure ScenariosWithFilter(ChoiceData, Parameters, StandardProcessing) Export
	If Parameters.Property("NotThisScenario") Then
		Filter = Parameters.NotThisScenario;
		ChoiceFoldersAndItems = (Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.FoldersAndItems);
		
		Query = New Query("SELECT
		|	BudgetingScenarios.Ref AS Value,
		|	BudgetingScenarios.Presentation AS Presentation,
		|	BudgetingScenarios.DeletionMark AS Check
		|FROM
		|	Catalog.BudgetingScenarios AS BudgetingScenarios
		|WHERE
		|	NOT BudgetingScenarios.Ref IN (&ToExclude)
		|	AND (NOT BudgetingScenarios.IsFolder OR &ChoiceFoldersAndItems)
		|
		|ORDER BY
		|	Presentation");
		
		LinkToThisScript = New ValueList;
		If TypeOf(Filter) = Type("FixedArray") Then
			LinkToThisScript.LoadValues(New Array(Filter));
		Else
			LinkToThisScript.Add(Filter);
		EndIf;
		
		Query.SetParameter("ChoiceFoldersAndItems", ChoiceFoldersAndItems);
		Query.SetParameter("ToExclude", LinkToThisScript);
		Selection = Query.Execute().Select();
		
		ChoiceData = New ValueList;
		
		While Selection.Next() Do
			FillPropertyValues(ChoiceData.Add(), Selection);
		EndDo;
	EndIf;
EndProcedure

Function TypesOfAnalyticsTypes(ObjectsArray) Export
	
	Return Common.ObjectsAttributesValues(ObjectsArray, "ValueType");
	
EndFunction

Function ReportAnalystProperties(AddressBudgetViewOutputParameters) Export
	
	OutputParameters = GetFromTempStorage(AddressBudgetViewOutputParameters);
	
	AnalystProperties = New Structure;
	
	// An ordered array of all report analytics to determine the order of analytics by decryption and types of analytics.
	AnalystProperties.Insert("TypesOfReportAnalysts", OutputParameters.ColumnStructureOfDataTable.DimensionKinds);
	AnalystProperties.Insert("TypeValues", TypesOfAnalyticsTypes(AnalystProperties.TypesOfReportAnalysts));
	
	Return AnalystProperties;
	
EndFunction

#Region BudgetEntryForm

Function NearestPlannedCourseToDate(CourseLines, PlanningPeriod)
	
	Rate = CourseLines[0].Rate;
	For Each CourseLine In CourseLines Do
		If CourseLine.Period > PlanningPeriod Then
			Return Rate;
		EndIf;
		Rate = CourseLine.Rate;
	EndDo;
	
	Return Rate;
	
EndFunction

Function RateTable(ObjectAndCalculationParameters, ParametersStructure, Currency, Cancel, MessageText) Export
	
	RequireExchangeRatesSpecificationForEachPeriod = ObjectAndCalculationParameters.RequireExchangeRatesSpecificationForEachPeriod;
	Object = ObjectAndCalculationParameters.Object;
	
	CellStructure = ParametersStructure.StructureOfReportDescription.CellStructure;
	
	CopyOfCellStructure = CellStructure.Copy(,"Currency");
	CopyOfCellStructure.GroupBy("Currency");
	ArrayOfCurrencies = CopyOfCellStructure.UnloadColumn("Currency");
	
	ArrayOfDocumentCurrencies = TMCommonUse.ExportValuesTable(Object.BudgetFlowItemsDimension, ,
		"Currency").UnloadColumn("Currency"); // Array
	If ValueIsFilled(Currency) Then
		ArrayOfDocumentCurrencies.Add(Currency);
	EndIf;
	
	CommonClientServer.SupplementArray(ArrayOfCurrencies, ArrayOfDocumentCurrencies, True);
	
	ArrayOfAdditionalCurrencies = New Array;
	ArrayOfAdditionalCurrencies.Add(Common.ObjectAttributeValue(Object.Scenario, "Currency"));
	ArrayOfAdditionalCurrencies.Add(Constants.ManagementAccountingCurrency.Get());
	
	CommonClientServer.SupplementArray(ArrayOfCurrencies, ArrayOfAdditionalCurrencies, True);
	
	CurrencyOfComplianceAccounting = Constants.LocalAccountingCurrency.Get();
	UBound = ArrayOfCurrencies.UBound();
	Deleted = 0;
	
	For Cnt = 0 To UBound Do
		
		CurrentIndex = Cnt - Deleted;
		If Not ValueIsFilled(ArrayOfCurrencies[CurrentIndex])
			Or ArrayOfCurrencies[CurrentIndex] = CurrencyOfComplianceAccounting Then
			
			Deleted = Deleted + 1;
			ArrayOfCurrencies.Delete(CurrentIndex);
			
		EndIf;
		
	EndDo;
	
	RateTable = Catalogs.BudgetingScenarios.ScenarioCourseTable(Object.Scenario, ArrayOfCurrencies, Object.BeginOfPeriod, Object.PeriodEnding);
	
	If Not RequireExchangeRatesSpecificationForEachPeriod Then
		
		NewRow = RateTable.Add();
		NewRow.Period = Object.BeginOfPeriod;
		NewRow.Currency = CurrencyOfComplianceAccounting;
		NewRow.Rate = 1;
		
		RateTable.Sort("Currency, Period");
		RateTable.Indexes.Add("Currency");
		RateTable.Indexes.Add("Currency, Period");
		
		CurrenciesNotFound = New Array;
		For Each Currency In ArrayOfCurrencies Do
			
			TheStructureOfTheSearch = New Structure("Currency, Period", Currency, Object.BeginOfPeriod);
			FoundRows = RateTable.FindRows(TheStructureOfTheSearch);
			
			If Not FoundRows.Count() Then
				CurrenciesNotFound.Add(Currency);
			EndIf;
			
		EndDo;
		
		If CurrenciesNotFound.Count() Then
			
			MessageText = NStr("vi = 'Chưa tìm thấy tỷ giá hối đoái dự báo cho các loại tiền tệ kể từ đầu kỳ: %1';
								|ru = 'Не найдены прогнозные курсы на начало периода для валют: %1';
								|en = 'Forecasted exchange rates for currencies as of the period start are not found: %1'; fa = 'Forecasted exchange rates for currencies as of the period start are not found: %1';
								|it = 'Non sono stati trovati i tassi di cambio previsti per l''inizio del periodo per le valute: %1';
								|pl = 'Nie znaleziono kursów prognozowych na początek okresu dla walut: %1';
								|tr = 'Şu para birimi için dönemin başlangıcında tahmin edilen kurlar bulunamadı: %1'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, 
								StrConcat(CurrenciesNotFound, ", "));
			Cancel = True;
			
		EndIf;
		
	Else
		
		Periodicity_ = New Array;
		CommonClientServer.SupplementArray(Periodicity_, ParametersStructure.ColumnStructureOfDataTable.Periodicity_);
		Periodicity_.Add(Object.BudgetProfile.Periodicity);
		FrequencyOfCourseVerification = BudgetReportingClientServer.MinimumPeriodicity(Periodicity_);
		ArrayOfPeriods = BudgetReportingDisplayServer.BudgetReportPeriods(Object.BeginOfPeriod, Object.PeriodEnding, FrequencyOfCourseVerification);
		CoursesNotFound = RateTable.CopyColumns("Period, Currency");
		
		For Each Period In ArrayOfPeriods Do
			For Each Currency In ArrayOfCurrencies Do
				TheStructureOfTheSearch = New Structure("Currency, Period", Currency, Period);
				If Not RateTable.FindRows(TheStructureOfTheSearch).Count() Then
					NewRow = CoursesNotFound.Add();
					FillPropertyValues(NewRow, TheStructureOfTheSearch);
				EndIf;
			EndDo;
		EndDo;
		
		If CoursesNotFound.Count() Then
			
			CoursesNotFound.GroupBy("Currency");
			ArrayOfCurrencies = CoursesNotFound.UnloadColumn("Currency");
			MessageText = NStr("vi = 'Chưa tìm thấy tỷ giá hối đoái dự báo cho các loại tiền tệ kể từ đầu kỳ:%1; cần chỉ ra tỷ giá hối đoái vào %2';
								|ru = 'Не найдены прогнозные курсы для валют: %1; курсы должны быть указаны на %2';
								|en = 'Forecasted exchange rates are not found for currencies: %1; exchange rates should be specified for %2'; fa = 'Forecasted exchange rates are not found for currencies: %1; exchange rates should be specified for %2';
								|it = 'Nono sono stati trovati i tassi di cambio previsti per le valute: %1; i tassi devono essere indicati in %2';
								|pl = 'Nie znaleziono kursów prognozowych dla walut: %1; kursy powinny być podane na %2';
								|tr = 'Şu para birimi için tahmin edilen kurlar bulunamadı: %1; kurlar %2 kısmında belirtilmeli'");
			
			If FrequencyOfCourseVerification = Enums.Periodicity.TenDays Then
				DeclinationOfEach = NStr("vi = 'mỗi mười ngày';
										|ru = 'каждую декаду';
										|en = 'every ten-day period'; fa = 'every ten-day period';
										|it = 'ogni decade';
										|pl = 'co dziesięć dni';
										|tr = 'her on gün'");
			ElsIf FrequencyOfCourseVerification = Enums.Periodicity.Week Then
				DeclinationOfEach = NStr("vi = 'mỗi tuần';
										|ru = 'каждую неделю';
										|en = 'every week'; fa = 'every week';
										|it = 'ogni settimana';
										|pl = 'co tydzień';
										|tr = 'her hafta'");
			Else
				DeclinationOfEach = NStr("vi = 'mỗi %1';
										|ru = 'каждый %1';
										|en = 'each %1'; fa = 'each %1';
										|it = 'ogni %1';
										|pl = 'każdy %1';
										|tr = 'her %1'");
				DeclinationOfEach = StringFunctionsClientServer.SubstituteParametersToString(DeclinationOfEach, Lower(FrequencyOfCourseVerification));
			EndIf;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, 
				StrConcat(ArrayOfCurrencies, ", "),
				DeclinationOfEach);
			Cancel = True;
			
		Else
			
			For Each Period In ArrayOfPeriods Do
				NewRow = RateTable.Add();
				NewRow.Period = Period;
				NewRow.Currency = CurrencyOfComplianceAccounting;
				NewRow.Rate = 1;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return RateTable;
	
EndFunction

Function UpdateCourseTable(ObjectAndCalculationParameters, PreviousCourseTable, Currency)
	Var Cancel, MessageText;
	
	ParametersStructure = GetFromTempStorage(ObjectAndCalculationParameters.BudgetProfileDisplayParameters);
	If ParametersStructure = Undefined Then
		Return PreviousCourseTable;
	EndIf;
	
	RateTable = RateTable(ObjectAndCalculationParameters, ParametersStructure, Currency, Cancel, MessageText);
	
	Return RateTable;
	
EndFunction

Function RecalculateAccordingToCourseTable(ObjectAndCalculationParameters, Sum, PlanningPeriod, StartingCurrency, EndCurrency) Export
	
	AddressOfExchangeRateTable = ObjectAndCalculationParameters.AddressOfExchangeRateTable;
	RequireExchangeRatesSpecificationForEachPeriod = ObjectAndCalculationParameters.RequireExchangeRatesSpecificationForEachPeriod;
	
	RateTable = GetFromTempStorage(AddressOfExchangeRateTable);
	
	If RequireExchangeRatesSpecificationForEachPeriod Then
		TheStructureOfTheSearch = New Structure("Currency, Period", StartingCurrency, PlanningPeriod);
	Else
		TheStructureOfTheSearch = New Structure("Currency", StartingCurrency);
	EndIf;
	
	CourseLines = RateTable.FindRows(TheStructureOfTheSearch);
	If Not CourseLines.Count() Then
		RateTable = UpdateCourseTable(ObjectAndCalculationParameters, RateTable, StartingCurrency);
		PutToTempStorage(RateTable, AddressOfExchangeRateTable);
		CourseLines = RateTable.FindRows(TheStructureOfTheSearch);
		If Not CourseLines.Count() Then
			Return Sum;
		EndIf;
	EndIf;
	
	If RequireExchangeRatesSpecificationForEachPeriod Then
		TheStructureOfTheSearch = New Structure("Currency, Period", EndCurrency, PlanningPeriod);
		CourseNach = CourseLines[0].Rate;
		CourseLines = RateTable.FindRows(TheStructureOfTheSearch);
		If Not CourseLines.Count() Then
			RateTable = UpdateCourseTable(ObjectAndCalculationParameters, RateTable, EndCurrency);
			PutToTempStorage(RateTable, AddressOfExchangeRateTable);
			CourseLines = RateTable.FindRows(TheStructureOfTheSearch);
			If Not CourseLines.Count() Then
				Return Sum;
			EndIf;
		EndIf;
		CourseCon = CourseLines[0].Rate;
	Else
		TheStructureOfTheSearch = New Structure("Currency", EndCurrency);
		CourseNach = NearestPlannedCourseToDate(CourseLines, PlanningPeriod);
		CourseLines = RateTable.FindRows(TheStructureOfTheSearch);
		If Not CourseLines.Count() Then
			RateTable = UpdateCourseTable(ObjectAndCalculationParameters, RateTable, EndCurrency);
			PutToTempStorage(RateTable, AddressOfExchangeRateTable);
			CourseLines = RateTable.FindRows(TheStructureOfTheSearch);
			If Not CourseLines.Count() Then
				Return Sum;
			EndIf;
		EndIf;
		CourseCon = NearestPlannedCourseToDate(CourseLines, PlanningPeriod);
	EndIf;
	
	Return Sum * CourseNach / CourseCon;
	
EndFunction

// The value of the decoding
// 
// Parameters:
// 	DecryptionNumber - Number, DataCompositionDetailsID, Undefined -
// 	DetailsDataAddress - String -
// Returns:
// 	 - Undefined - 
// 	 - Map of KeyAndValue - LongDesc:
// 		* Key - Number, DataCompositionDetailsID -
// 		* Value - DataCompositionFieldDetailsItem, DataCompositionGroupDetailsItem - 
// 	 - Structure - structure with properties:
// 		* String - CatalogRef.FinancialReportItems - Budget line.
//
Function DetailsValue(DecryptionNumber, DetailsDataAddress) Export
	
	If DecryptionNumber = Undefined // The cursor is not set in the data cell. For example, in the header
		Or TypeOf(DecryptionNumber) = Type("DataCompositionDetailsID") Then // The cursor is set in a cell in which the view is not configured
		Return Undefined;
	EndIf;
	
	DetailsData = GetFromTempStorage(DetailsDataAddress);
	
	If DetailsData = Undefined Then
		Return Undefined;
	EndIf;
	
	If TypeOf(DecryptionNumber) = Type("Number") Then
		Return DetailsData[DecryptionNumber];
	EndIf;
	
	Result = New Map;
	For Each DetailsIndex In DecryptionNumber Do
		Result.Insert(DetailsIndex, DetailsData[DetailsIndex]);
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion


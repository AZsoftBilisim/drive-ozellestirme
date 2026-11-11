
#Region Internal

// The function returns the index of the image based on the type of element and clarifying information
//
// Parameters:
//  ItemKind  - EnumRef.FinancialReportItemKinds - Type of element for which we get the parameter
//  NameOfAuxiliaryData  - String - clarifying value.
//
// Returns:
//   Number   - index of a picture from a collection of collectionsevidents of financial reporting.
//
Function CustomPicture(ItemKind, NameOfAuxiliaryData = Undefined) Export
	
	TempTablesManager = FinancialReportingServer.TemporaryTableOfImageIndexes();
	
	Query = New Query("SELECT TOP 1 * FROM ImageIndexTable WHERE ItemKind = &ItemKind");
	Query.TempTablesManager = TempTablesManager;
	If Not ValueIsFilled(ItemKind) Then
		Query.SetParameter("ItemKind", Enums.FinancialReportItemKinds.EmptyRef());
	Else
		Query.SetParameter("ItemKind", ItemKind);
	EndIf;
	If ValueIsFilled(NameOfAuxiliaryData) Then
		Query.Text = Query.Text + " AND NameOfAuxiliaryElement = &NameOfAuxiliaryData";
		Query.SetParameter("NameOfAuxiliaryData", NameOfAuxiliaryData);
	EndIf;
	ImageIndexTable = Query.Execute().Unload();
	
	If ImageIndexTable.Count() Then
		Return ImageIndexTable[0].PictureIndex;
	EndIf;
	
	Return 0;
	
EndFunction

// This function returns a table of acceptable combinations of financial report elements
//
// Returns:
//   ValueTable   - table of acceptable combinations.
//
Function AcceptableCombinationsOfBudgetElements() Export
	
	TableOfCombinations = CommonValidCombinationsOfElements();
	
	// Upper level (parent is empty)
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("BudgetFlowItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("NonFinancialItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("EditedValue"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("BudgetBalanceItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("AllBudgetFlowItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("AllBudgetBalanceItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("Group"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("Dimension"));
	
	//A SIMPLE TABLE OF INDICATORS IN ROWS
	TableType = ItemKind("TableIndicatorsInRows");
	//Rows
	AddStringOfCombinations(TableOfCombinations, ItemKind("Rows"), ItemKind("BudgetFlowItem")       ,, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Rows"), ItemKind("NonFinancialItem"),, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Rows"), ItemKind("EditedValue"),, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Rows"), ItemKind("BudgetBalanceItem")   ,, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Rows"), ItemKind("AllBudgetFlowItems")    ,, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Rows"), ItemKind("AllBudgetBalanceItems"),, TableType);
	ColumnRows = ItemKind("Rows");
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("BudgetFlowItem")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("NonFinancialItem") , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("EditedValue")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("BudgetBalanceItem")     , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("AllBudgetFlowItems")      , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("AllBudgetBalanceItems")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")             , ItemKind("BudgetFlowItem")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")             , ItemKind("NonFinancialItem") , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")             , ItemKind("EditedValue")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")             , ItemKind("BudgetBalanceItem")     , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")             , ItemKind("AllBudgetFlowItems")      , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")             , ItemKind("AllBudgetBalanceItems")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem")    , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem") , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem")        , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem"), ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue") , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems")     , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetBalanceItems") , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")        , ItemKind("BudgetFlowItem")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")        , ItemKind("NonFinancialItem") , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")        , ItemKind("EditedValue")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")        , ItemKind("BudgetBalanceItem")     , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")        , ItemKind("DerivedItem")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")        , ItemKind("AllBudgetFlowItems")      , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")        , ItemKind("AllBudgetBalanceItems")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem")    , ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem") , ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem")        , ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem"), ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue") , ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems")     , ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetBalanceItems") , ItemKind("RowColumn")         , ColumnRows, TableType);
	
	//A SIMPLE TABLE OF INDICATORS IN COLUMNS
	TableType = ItemKind("TableIndicatorsInColumns");
	//Columns
	ColumnRows = ItemKind("Columns");
	AddStringOfCombinations(TableOfCombinations, ColumnRows, ItemKind("BudgetFlowItem")        ,, TableType);
	AddStringOfCombinations(TableOfCombinations, ColumnRows, ItemKind("NonFinancialItem"),, TableType);
	AddStringOfCombinations(TableOfCombinations, ColumnRows, ItemKind("EditedValue") ,, TableType);
	AddStringOfCombinations(TableOfCombinations, ColumnRows, ItemKind("BudgetBalanceItem")    ,, TableType);
	AddStringOfCombinations(TableOfCombinations, ColumnRows, ItemKind("AllBudgetFlowItems")     ,, TableType);
	AddStringOfCombinations(TableOfCombinations, ColumnRows, ItemKind("AllBudgetBalanceItems") ,, TableType);
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group")                 , ItemKind("BudgetFlowItem")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group")                 , ItemKind("NonFinancialItem") , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group")                 , ItemKind("EditedValue")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group")                 , ItemKind("BudgetBalanceItem")     , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group")                 , ItemKind("AllBudgetFlowItems")      , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group")                 , ItemKind("AllBudgetBalanceItems")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")              , ItemKind("BudgetFlowItem")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")              , ItemKind("NonFinancialItem") , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")              , ItemKind("EditedValue")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")              , ItemKind("BudgetBalanceItem")     , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")              , ItemKind("AllBudgetFlowItems")      , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")              , ItemKind("AllBudgetBalanceItems")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem")     , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem")  , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem")         , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem") , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue")  , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems")      , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetBalanceItems")  , ItemKind("Dimension")              , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")         , ItemKind("BudgetFlowItem")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")         , ItemKind("NonFinancialItem") , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")         , ItemKind("EditedValue")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")         , ItemKind("BudgetBalanceItem")     , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")         , ItemKind("DerivedItem")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")         , ItemKind("AllBudgetFlowItems")      , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn")         , ItemKind("AllBudgetBalanceItems")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem")     , ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem")  , ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem")         , ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem") , ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue")  , ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems")      , ItemKind("RowColumn")         , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetBalanceItems")  , ItemKind("RowColumn")         , ColumnRows, TableType);
	
	
	//Other RELATIONSHIPS of elements that are always characteristic
	// of entering into dimensions
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("BudgetFlowItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("NonFinancialItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("EditedValue"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("BudgetBalanceItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Group"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("AllBudgetFlowItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("AllBudgetBalanceItems"));
	// entry of measurements and articles
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"),  ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem")       ,  ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem"), ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue"),  ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem")   ,  ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems")    ,  ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetBalanceItems"),  ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem")       ,  ItemKind("Group"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem")   ,  ItemKind("Group"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems")    ,  ItemKind("Group"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetBalanceItems"),  ItemKind("Group"));
	
	// joining groups
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Group"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("GroupFormula"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("BudgetFlowItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("NonFinancialItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("EditedValue"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("BudgetBalanceItem"));
	
	ArrayTableView = New Array();
	ArrayTableView.Add(ItemKind("TableIndicatorsInRows"));
	ArrayTableView.Add(ItemKind("TableIndicatorsInColumns"));
	
	RowColumnArray = New Array();
	RowColumnArray.Add(ItemKind("Rows"));
	RowColumnArray.Add(ItemKind("Columns"));
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem")     , ItemKind("Group")           , RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem")         , ItemKind("Group")           , RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem") , ItemKind("Group")           , RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue")  , ItemKind("Group")           , RowColumnArray, ArrayTableView);
	
	ArrayTableView.Add(ItemKind("ComplexTable"));
	// dimensions, groups and elements - in any table
	AddStringOfCombinations(TableOfCombinations, RowColumnArray, ItemKind("Dimension")     ,, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, RowColumnArray, ItemKind("Group")        ,, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, RowColumnArray, ItemKind("RowColumn"),, ArrayTableView);
	// relationships of groups, articles and indicators
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Dimension"), RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Group")   , RowColumnArray, ArrayTableView);
	// interrelations of groups among themselves
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Group")         , RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("GroupFormula"), RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Dimension")      , RowColumnArray, ArrayTableView);
	// table element
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn"), ItemKind("RowColumn"), RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group")        , ItemKind("RowColumn"), RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")     , ItemKind("RowColumn"), RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn"), ItemKind("Group")        , RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn"), ItemKind("Dimension")     , RowColumnArray, ArrayTableView);
	
	//INDEXES FOR QUICK SEARCH
	TableOfCombinations.Indexes.Add("Item, Parent");
	TableOfCombinations.Indexes.Add("Item, Parent, ColumnRows, TableType");
	
	Return TableOfCombinations;
	
EndFunction

// This function returns a table of invalid combinations of budget report elements
//
// Returns:
//   ValueTable   - table of acceptable combinations.
//
Function InvalidCombinationsOfBudgetElements() Export

	Type = New TypeDescription("EnumRef.FinancialReportItemKinds");
	
	TableOfCombinations = New ValueTable;
	TableOfCombinations.Columns.Add("Item", Type);
	TableOfCombinations.Columns.Add("Parent", Type);
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem"), ItemKind("BudgetBalanceItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem"), ItemKind("AllBudgetBalanceItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem"), ItemKind("NonFinancialItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetBalanceItem"), ItemKind("EditedValue"));
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetBalanceItems"), ItemKind("BudgetBalanceItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetBalanceItems"), ItemKind("AllBudgetBalanceItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetBalanceItems"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetBalanceItems"), ItemKind("NonFinancialItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetBalanceItems"), ItemKind("EditedValue"));
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem"), ItemKind("BudgetBalanceItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem"), ItemKind("AllBudgetBalanceItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem"), ItemKind("BudgetFlowItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem"), ItemKind("AllBudgetFlowItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem"), ItemKind("NonFinancialItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("BudgetFlowItem"), ItemKind("EditedValue"));
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem"), ItemKind("BudgetBalanceItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem"), ItemKind("AllBudgetBalanceItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem"), ItemKind("BudgetFlowItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem"), ItemKind("AllBudgetFlowItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem"), ItemKind("NonFinancialItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonFinancialItem"), ItemKind("EditedValue"));
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue"), ItemKind("BudgetBalanceItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue"), ItemKind("AllBudgetBalanceItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue"), ItemKind("BudgetFlowItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue"), ItemKind("AllBudgetFlowItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue"), ItemKind("NonFinancialItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EditedValue"), ItemKind("EditedValue"));
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("BudgetBalanceItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("AllBudgetBalanceItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("BudgetFlowItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("AllBudgetFlowItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("NonFinancialItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("EditedValue"));
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems"), ItemKind("BudgetBalanceItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems"), ItemKind("AllBudgetBalanceItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems"), ItemKind("BudgetFlowItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems"), ItemKind("AllBudgetFlowItems"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems"), ItemKind("NonFinancialItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("AllBudgetFlowItems"), ItemKind("EditedValue"));
	
	//INDEXES FOR QUICK SEARCH
	
	TableOfCombinations.Indexes.Add("Item");
	
	Return TableOfCombinations;

EndFunction

// This function returns a table of acceptable combinations of financial report elements
//
// Returns:
//   ValueTable   - table of acceptable combinations.
//
Function AcceptableCombinationsOfReportElements() Export
	
	TableOfCombinations = CommonValidCombinationsOfElements();
	
	// Upper level (parent is empty)
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("MonetaryIndicator"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("NonMonetaryItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("DerivedItem"));
	
	//Table
	Array = New Array();
	Array.Add(ItemKind("ComplexTable"));
	Array.Add(ItemKind("TableIndicatorsInRows"));
	Array.Add(ItemKind("TableIndicatorsInColumns"));
	AddStringOfCombinations(TableOfCombinations, Array, ItemKind("Rows"));
	AddStringOfCombinations(TableOfCombinations, Array, ItemKind("Columns"));
	
	//A SIMPLE TABLE OF INDICATORS IN ROWS
	TableType = ItemKind("TableIndicatorsInRows");
	//Rows
	ColumnRows = ItemKind("Rows");
	AddStringOfCombinations(TableOfCombinations, ColumnRows, ItemKind("MonetaryIndicator"), 	, TableType);
	AddStringOfCombinations(TableOfCombinations, ColumnRows, ItemKind("NonMonetaryItem"), , TableType);
	AddStringOfCombinations(TableOfCombinations, ColumnRows, ItemKind("DerivedItem"), 	, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("MonetaryIndicator"), 	  ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("NonMonetaryItem"),   ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("MonetaryIndicator"),  ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("NonMonetaryItem"),ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("MonetaryIndicator"), ItemKind("Dimension"),  ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("Dimension"),  ColumnRows, TableType);
	//Columns
	ColumnRows = ItemKind("Columns");
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Group"), ColumnRows, TableType);
	
	//A SIMPLE TABLE OF INDICATORS IN COLUMNS
	TableType = ItemKind("TableIndicatorsInColumns");
	//Columns
	ColumnRows = ItemKind("Columns");
	AddStringOfCombinations(TableOfCombinations, ColumnRows                        , ItemKind("MonetaryIndicator")  ,, TableType);
	AddStringOfCombinations(TableOfCombinations, ColumnRows                        , ItemKind("NonMonetaryItem"),, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group")                , ItemKind("MonetaryIndicator")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group")                , ItemKind("NonMonetaryItem"), ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")             , ItemKind("MonetaryIndicator")  , ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")             , ItemKind("NonMonetaryItem"), ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("MonetaryIndicator"),  ItemKind("Dimension"), ColumnRows, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"),  ItemKind("Dimension"), ColumnRows, TableType);
	//Rows
	ColumnRows = ItemKind("Rows");
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Group"), ColumnRows, TableType);
	
	//Other RELATIONSHIPS of elements that are always characteristic
	// of entering into dimensions
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("MonetaryIndicator"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("NonMonetaryItem"));
	
	// joining groups
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Group"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("TotalByGroup"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("MonetaryIndicator"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("NonMonetaryItem"));
	
	RowColumnArray = New Array();
	RowColumnArray.Add(ItemKind("Rows"));
	RowColumnArray.Add(ItemKind("Columns"));
	
	ArrayTableView = New Array();
	ArrayTableView.Add(ItemKind("ComplexTable"));
	TableType = ItemKind("ComplexTable");
	
	// table element
	AddStringOfCombinations(TableOfCombinations, RowColumnArray          , ItemKind("RowColumn"),,TableType);
	AddStringOfCombinations(TableOfCombinations, RowColumnArray          , ItemKind("Group")        ,,TableType);
	AddStringOfCombinations(TableOfCombinations, RowColumnArray          , ItemKind("Dimension")     ,,TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("RowColumn"), ItemKind("RowColumn"), RowColumnArray, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group")        , ItemKind("RowColumn"), RowColumnArray, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group")        , ItemKind("TotalByGroup")  , RowColumnArray, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")     , ItemKind("RowColumn"), RowColumnArray, TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension")     , ItemKind("Group"), RowColumnArray, TableType);
	
	
	ArrayTableView = New Array();
	ArrayTableView.Add(ItemKind("TableIndicatorsInRows"));
	ArrayTableView.Add(ItemKind("TableIndicatorsInColumns"));
	// dimensions, groups and elements - in any table
	AddStringOfCombinations(TableOfCombinations, RowColumnArray, ItemKind("Dimension")     ,, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, RowColumnArray, ItemKind("Group")        ,, ArrayTableView);
	// relationships between groups and dimensions
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Dimension"), RowColumnArray, ArrayTableView);
	// interrelations of groups among themselves
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Group")      , RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("TotalByGroup"), RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Dimension")   , RowColumnArray, ArrayTableView);
	
	
	//INDEXES FOR QUICK SEARCH
	TableOfCombinations.Indexes.Add("Item, Parent");
	TableOfCombinations.Indexes.Add("Item, Parent, ColumnRows, TableType");
	
	Return TableOfCombinations;
	
EndFunction

// This function returns a table of invalid combinations of budget report elements
//
// Returns:
//   ValueTable   - table of acceptable combinations.
//
Function InvalidCombinationsOfReportElements() Export
	
	Type = New TypeDescription("EnumRef.FinancialReportItemKinds");
	
	TableOfCombinations = New ValueTable;
	TableOfCombinations.Columns.Add("Item", Type);
	TableOfCombinations.Columns.Add("Parent", Type);
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("MonetaryIndicator"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("NonMonetaryItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("DerivedItem"), ItemKind("RowColumn"));
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("MonetaryIndicator"), ItemKind("MonetaryIndicator"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("MonetaryIndicator"), ItemKind("NonMonetaryItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("MonetaryIndicator"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("MonetaryIndicator"), ItemKind("RowColumn"));
	
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonMonetaryItem"), ItemKind("MonetaryIndicator"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonMonetaryItem"), ItemKind("NonMonetaryItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonMonetaryItem"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("NonMonetaryItem"), ItemKind("RowColumn"));
	
	//INDEXES FOR QUICK SEARCH
	
	TableOfCombinations.Indexes.Add("Item");
	
	Return TableOfCombinations;
	
EndFunction

// Returns sub-account types
//
// Parameters:
// 	Account - ChartOfAccountsRef- The sub-account that needs to be returned.
//
// Returns:
// 	ValueTable - Types of sub-account.
//
Function AccountExtDimensionTypes(Account) Export
	
	QueryText =
	"SELECT
	|	ExtDimensionTypes.LineNumber AS ExtDimensionNumber,
	|	ExtDimensionTypes.ExtDimensionType AS ExtDimensionType,
	|	ExtDimensionTypes.ExtDimensionType.ValueType AS ValueType
	|FROM
	|	&ChartOfAccountsTable AS ExtDimensionTypes
	|WHERE
	|	ExtDimensionTypes.Ref = &Account";
	
	If TypeOf(Account) = LocalAccntingClientServer.TypeChartOfAccounts() Then
		ChartOfAccountsName = LocalAccntingClientServer.ChartOfAccountsName()
	ElsIf  TypeOf(Account) = FinancialAccountingClientServer.TypeChartOfAccounts() Then
		ChartOfAccountsName = FinancialAccountingClientServer.ChartOfAccountsName()
	Else
		Raise NStr("vi = 'Loại hệ thống tài khoản không được xác định';
					|ru = 'Тип плана счетов не определен';
					|en = 'Type of account plan is not specified'; fa = 'Type of account plan is not specified';
					|it = 'Il tipo di piano dei conti non è definito';
					|pl = 'Rodzaj planu rachunków nie został zdefiniowany';
					|tr = 'Hesap planı türü tanımlanmamış'");
	EndIf;
	ChartOfAccountsTable = StrTemplate("ChartOfAccounts.%1.ExtDimensionTypes", ChartOfAccountsName);
	QueryText = StrReplace(QueryText, "&ChartOfAccountsTable", ChartOfAccountsTable);
	
	Query = New Query(QueryText); 
	Query.SetParameter("Account", Account);
	
	Return Query.Execute().Unload();
	
EndFunction

Function NameOfBudgetReportField(BudgetReportField) Export
	
	Var_Key = BudgetReportField.PredefinedDataName;
	If IsBlankString(Var_Key) Then
		Var_Key = "Key_" + StrReplace(BudgetReportField.UUID(), "-", "_");
	EndIf;
	
	Return Var_Key;
	
EndFunction

Function BudgetReportFieldByName(Val NameOfBudgetReportField) Export
	
	Field = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.EmptyRef();
	If StrStartsWith(NameOfBudgetReportField, "Key_") Then
		NameOfBudgetReportField = StrReplace(NameOfBudgetReportField, "Key_", "");
		UUID = New UUID(StrReplace(NameOfBudgetReportField, "_", "-"));
		Field = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.GetRef(UUID);
	Else
		Field = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions[NameOfBudgetReportField];
	EndIf;
	
	Return Field;
	
EndFunction

Function TypeOfAnalyticsTypeValue(DimensionName, DimensionKind) Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	NumberedAnalysts = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		NumberedAnalysts.Add("Dimension" + DimensionNumber);
	EndDo;
	
	If DimensionName = "Organization" Then
		Return New TypeDescription("CatalogRef.Companies");
	ElsIf DimensionName = "Department" Then
		Return New TypeDescription("CatalogRef.BusinessStructure");
	ElsIf DimensionName = "Scenario" Then
		Return New TypeDescription("CatalogRef.BudgetingScenarios");
	ElsIf DimensionName = "Currency" Then
		Return New TypeDescription("CatalogRef.Currencies");
	ElsIf NumberedAnalysts.Find(DimensionName) <> Undefined Then
		Return BudgetingServer.AllTypesOfAnalytics();
	EndIf;
	
	Return Common.ObjectAttributeValue(DimensionKind, "ValueType");
	
EndFunction

Function TypesOfBudgetInstanceAnalytics(Ref) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PRESENTATION(BudgetProfilesHeaderDimensions.DimensionKind) AS Description,
	|	BudgetProfilesHeaderDimensions.LineNumber AS LineNumber
	|FROM
	|	Document.BudgetEntryForm AS BudgetEntryForm
	|		INNER JOIN Catalog.BudgetProfiles.HeaderDimensions AS BudgetProfilesHeaderDimensions
	|		ON BudgetEntryForm.BudgetProfile = BudgetProfilesHeaderDimensions.Ref
	|WHERE
	|	BudgetEntryForm.Ref = &Ref
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("Ref", Ref);
	QueryResult = Query.Execute();
	TypesOfBudgetViewAnalytics = QueryResult.Unload();
	
	Return TypesOfBudgetViewAnalytics;
	
EndFunction

// Returns the text of the budget report Analytics presentation or sorting expression, which is substituted as an expression of the calculated DCS field.
//
// Parameters:
//  ExpressionText - String - the source text of the expression generated by the formula constructor
//  DimensionName - String - name of the budget report analytics
//
// Returns:
//  String - the given text expresses the presentation or sorting of the analytics of the budget report
// 
Function TextOfSortRepresentationExpressionWithDimensionName(Val ExpressionText, DimensionName) Export
	
	FormulaOperands = ProcessingOfFormulasClientServer.OperandsOfTextFormula(ExpressionText, True);
	For Each Operand In FormulaOperands Do
		OperandField = "Presentation(" + DimensionName + "." + Operand + ")";
		ExpressionText = StrReplace(ExpressionText, ProcessingOfFormulasClientServer.GetOperandTextToInsert(
			Operand), OperandField);
	EndDo;
	
	Return ExpressionText;
	
EndFunction

#EndRegion

#Region Private

Function CommonValidCombinationsOfElements()
	
	Type = New TypeDescription("EnumRef.FinancialReportItemKinds");
	
	TableOfCombinations = New ValueTable;
	TableOfCombinations.Columns.Add("Item",       Type);
	TableOfCombinations.Columns.Add("Parent",      Type);
	TableOfCombinations.Columns.Add("ColumnRows", Type);
	TableOfCombinations.Columns.Add("TableType",    Type);
	
	// Upper level (parent is empty)
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("ReportHeader"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("UneditedText"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("EditedText"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("ComplexTable"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("TableIndicatorsInRows"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("EmptyRef"), ItemKind("TableIndicatorsInColumns"));
	
	//Table
	Array = New Array();
	Array.Add(ItemKind("ComplexTable"));
	Array.Add(ItemKind("TableIndicatorsInRows"));
	Array.Add(ItemKind("TableIndicatorsInColumns"));
	AddStringOfCombinations(TableOfCombinations, Array, ItemKind("Rows"));
	AddStringOfCombinations(TableOfCombinations, Array, ItemKind("Columns"));
	
	//A SIMPLE TABLE OF INDICATORS IN ROWS
	TableType = ItemKind("TableIndicatorsInRows");
	//Rows
	ColumnRows = ItemKind("Rows");
	AddStringOfCombinations(TableOfCombinations, ColumnRows,           ItemKind("DerivedItem"),,             TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"),   ItemKind("DerivedItem"),ColumnRows,TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"),ItemKind("DerivedItem"),ColumnRows,TableType);
	
	//A SIMPLE TABLE OF INDICATORS IN COLUMNS
	TableType = ItemKind("TableIndicatorsInColumns");
	//Columns
	ColumnRows = ItemKind("Columns");
	AddStringOfCombinations(TableOfCombinations, ColumnRows,           ItemKind("DerivedItem"),,              TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"),   ItemKind("DerivedItem"), ColumnRows,TableType);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"),ItemKind("DerivedItem"),ColumnRows, TableType);
	
	//COMPLEX TABLE
	TableType = ItemKind("ComplexTable");
	
	//Other RELATIONSHIPS of elements that are always characteristic
	// of entering into dimensions
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("DerivedItem"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Group"));
	
	// joining groups
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Group"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Dimension"));
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("DerivedItem"));
		
	ArrayTableView = New Array();
	ArrayTableView.Add(ItemKind("ComplexTable"));
	
	RowColumnArray = New Array();
	RowColumnArray.Add(ItemKind("Rows"));
	RowColumnArray.Add(ItemKind("Columns"));
	
	// Elements of the "all"
	// dimensions, groups and elements type are in any table.
	AddStringOfCombinations(TableOfCombinations, RowColumnArray, ItemKind("Dimension"),, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, RowColumnArray, ItemKind("Group"),,    ArrayTableView);
	// relationships of groups, articles and indicators
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Dimension"), RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Dimension"), ItemKind("Group"),    RowColumnArray, ArrayTableView);
	// interrelations of groups among themselves
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Group"),    RowColumnArray, ArrayTableView);
	AddStringOfCombinations(TableOfCombinations, ItemKind("Group"), ItemKind("Dimension"), RowColumnArray, ArrayTableView);
	
	Return TableOfCombinations;
	
EndFunction

Procedure AddStringOfCombinations(TableOfAcceptableCombinations, Parent, Item, 
								ColumnRows = Undefined, 
								TableType = Undefined)
	
	If TypeOf(Parent) = Type("Array") Then
		For Each ParentElement In Parent Do
			AddStringOfCombinations(TableOfAcceptableCombinations, ParentElement, Item, ColumnRows, TableType)
		EndDo;
	ElsIf TypeOf(Item) = Type("Array") Then
		For Each ElementElement In Item Do
			AddStringOfCombinations(TableOfAcceptableCombinations, Parent, ElementElement, ColumnRows, TableType)
		EndDo;
	ElsIf TypeOf(ColumnRows) = Type("Array") Then
		For Each ColumnRowElement In ColumnRows Do
			AddStringOfCombinations(TableOfAcceptableCombinations, Parent, Item, ColumnRowElement, TableType)
		EndDo;
	ElsIf TypeOf(TableType) = Type("Array") Then
		For Each TableViewElement In TableType Do
			AddStringOfCombinations(TableOfAcceptableCombinations, Parent, Item, ColumnRows, TableViewElement)
		EndDo;
	Else
		
		Structure = New Structure;
		Structure.Insert("Parent",      Parent);
		Structure.Insert("Item",       Item);
		Structure.Insert("ColumnRows", ColumnRows);
		Structure.Insert("TableType",    TableType);
		
		NewRow = TableOfAcceptableCombinations.Add();
		FillPropertyValues(NewRow, Structure);
		
	EndIf;
	
EndProcedure

Function ItemKind(ElementTypeName)
	
	Return PredefinedValue("Enum.FinancialReportItemKinds."+ElementTypeName);
	
EndFunction

Procedure AddSelectionByOwner(MatchingSelections, Type, Attribute, FilterType)
	
	ArrayOfOwners = MatchingSelections[Type];
	If ArrayOfOwners = Undefined Then
		ArrayOfOwners = New ValueTable;
		ArrayOfOwners.Columns.Add("Attribute", New TypeDescription("String"));
		ArrayOfOwners.Columns.Add("Type", New TypeDescription("Type"));
		MatchingSelections.Insert(Type, ArrayOfOwners);
	EndIf;
	
	NewRow = ArrayOfOwners.Add();
	NewRow.Attribute = Attribute;
	NewRow.Type = FilterType;
	
EndProcedure

// Returns a match between the value type of the subordinate object and the value type of the owner
//
// Returns:
//  Map of KeyAndValue:
//   *Key - Type - the value type of the subordinate object
//   *Value - ValueTable - data table of the link with the owner:
//    **Attribute - String - the Attribute value of the subordinate object that is a reference to the owner
//    **Type - Type - owner value type
//
Function MatchingSelectionsByOwner() Export
	
	Result = New Map;
	
	AddSelectionByOwner(Result, Type("CatalogRef.CounterpartyContracts"), "Counterparty", Type("CatalogRef.Counterparties"));
	AddSelectionByOwner(Result, Type("CatalogRef.CounterpartyContracts"), "Partner", Type("CatalogRef.Partners"));
	AddSelectionByOwner(Result, Type("CatalogRef.LoanAndDepositContracts"), "Counterparty", Type("CatalogRef.Counterparties"));
	AddSelectionByOwner(Result, Type("CatalogRef.LoanAndDepositContracts"), "Partner", Type("CatalogRef.Partners"));
	AddSelectionByOwner(Result, Type("CatalogRef.Counterparties"), "Partner", Type("CatalogRef.Partners"));
	AddSelectionByOwner(Result, Type("CatalogRef.Products"), "ProductKind", Type("CatalogRef.ItemKinds"));
	AddSelectionByOwner(Result, Type("CatalogRef.Products"), "ItemsCollection", Type("CatalogRef.ItemsCollections"));
	AddSelectionByOwner(Result, Type("CatalogRef.Assets"), "Class", Type("CatalogRef.MaintenanceSchemes"));
	AddSelectionByOwner(Result, Type("CatalogRef.IntangibleAssets"), "IntangibleAssetGroup", Type("CatalogRef.IntangibleAssetsGroups"));
	AddSelectionByOwner(Result, Type("CatalogRef.ItemsCharacteristics"), "Owner", Type("CatalogRef.ItemKinds"));
	AddSelectionByOwner(Result, Type("CatalogRef.ItemsCharacteristics"), "Owner", Type("CatalogRef.Products"));
	
	Return Result;
	
EndFunction

#EndRegion
#Region Public

// Gets the structure of optional parameters for the Getselectcells function
// Returns:
//	Structure - Structure of parameters with keys:
//	  * Column - ValueList of CatalogRef.FinancialReportItems, Undefined - list of columns to output
//	  * String - ValueList of CatalogRef.FinancialReportItems, Undefined - list of output strings
//	  * SearchIndexes - Map of KeyAndValue, Undefined - parameter description:
//	    ** Key - String - the column names of the index separated by commas
//	    ** Value - Boolean -
//	  *AddFlag - Boolean - flag for adding a column in the format Flag + <dimension Name>.
//	  *GenerationMode - EnumRef.ModesOfBudgetReportGeneration - formation mode
//	  *ShowItemHierarchy - Boolean - indicates output in the hierarchy
//	  *PresentationExpression - String - expression of the analytics view
//	  *SortingExpression - String - expression for sorting analytics
//
Function OptionalParametersForGettingSelectionOfCells() Export
	Parameters = New Structure("Column, String, SearchIndexes, AddFlag, ShowItemHierarchy,
			| AdditionalSelection, GenerationMode, PresentationExpression, SortingExpression");
	Parameters.AddFlag = False;
	Parameters.ShowItemHierarchy = False;
	
	Return Parameters;
EndFunction

// Gets the cell of the budget in accordance with the passed parameters.
// 
// Parameters:
//	CellData_ - ValueTable - parameter description.
//	AccumulatedSelection - Structure - description of the composition of accumulated selections:
//	* Key - String - Dimension name.
//	* Value - Arbitrary - the value of the selection applied.
//	OptionalParameters - Structure, Undefined - structure of optional parameters with keys:
//	  * Column - ValueList of CatalogRef.FinancialReportItems, Undefined - list of columns to output.
//	  * String - ValueList of CatalogRef.FinancialReportItems, Undefined - a list of strings to the output.
//	  * SearchIndexes - Map of KeyAndValue, Undefined - parameter description:
//	    ** Key - String - the names of the index columns, separated by commas.
//	    ** Value - Boolean -
//	  *AddFlag - Boolean - flag for adding a column in the format Flag + <dimension Name>. False by default.
//
// Returns:
//	Array of ValueTableRow - array of rows found in the data cell table.
//
Function GetSelectionOfCells(CellData_, AccumulatedSelection, OptionalParameters = Undefined)
	
	// Getting optional parameters
	Column = Undefined;
	String = Undefined;
	SearchIndexes = Undefined;
	AddFlag = False;
	If OptionalParameters <> Undefined Then
		OptionalParameters.Property("Column",       Column);
		OptionalParameters.Property("String",        String);
		OptionalParameters.Property("SearchIndexes", SearchIndexes);
		OptionalParameters.Property("AddFlag", AddFlag);
		If AddFlag = Undefined Then
			AddFlag = False;
		EndIf;
	EndIf;
	
	FilterStructure1 = Undefined;
	FoundRows = FindRowsGivenIndexes(CellData_, Column, String, AccumulatedSelection, SearchIndexes, FilterStructure1);
	
	FilterCells = SelectingCellBySearchStructure(FilterStructure1);
	For Each FoundRow In FoundRows Do
		FoundRow.FilterCells = FilterCells;
	EndDo;
	
	Return FoundRows;
	
EndFunction

// Gets the cell of the budget in accordance with the passed parameters.
// 
// Parameters:
//	CellData_ - ValueTable - contains including (See CellData_):
// 		*String - CatalogRef.FinancialReportItems - Budget line.
// 		*Column - CatalogRef.FinancialReportItems - Budget line.
// 		*RowIndex - Number - Row index.
// 		*BudgetFlowItem - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems - Budget item or target.
// 		*BudgetBalanceItem - CatalogRef.BudgetBalanceItems - Budget indicator (calculated or target).
// 		*NonFinancialItem - CatalogRef.NonFinancialItemsOfBudgets - Non-financial indicator.
// 		*EditedValue - String - Name of the cell of the value to edit.
// 		*MainItem - Boolean - If true, it is output to the budget, if false, it is used to calculate the values in the main cells.
// 		*ItemKind - EnumRef.FinancialReportItemKinds - Type of element.
// 		*CalculationFilling - String - Option for calculating / filling the cell.
// 		*OperandType - EnumRef.FinancialReportItemKinds - The type of the operand.
// 		*OperandCalculationProcedure - Number - the calculation of the operand.
// 		*MinimumNumberInOrder - Number - minimum number in order.
// 		*Note - String - Note.
// 		*Period - Date - Period of cell data.
// 		*Currency - CatalogRef.Currencies - Currency of the sum values.
// 		*UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - Unit of measurement for quantitative values.
// 		*Count - Number - Quantity.
// 		*CountTurnover - Number - Number of revolutions.
// 		*Sum - Number - The amount.
// 		*SumTurnover - Number - The amount of turnover.
// 		*SumCurr - Number - The value of the currency.
// 		*SumCurrTurnover - Number - The amount of currency turnover.
// 		*Value - Number - Value of the non-financial indicator.
// 		*AreaNameCount - String - Name of the area in the table document.
// 		*AreaNameSum - String - Name of the area in the table document.
// 		*CalculatedCount - Boolean - flag for calculating the quantity using the formula.
// 		*CalculatedSum - Boolean - flag for calculating the amount using the formula.
// 		*CalculatedValue - Boolean - flag for calculating the value for a non-financial indicator using the formula.
// 		*DataStringIsMatched - Boolean - Flag for matching a table row and a row in a table budget document.
//	Dimensions - Array of String, String - a collection of dimension names or the name of a single dimension.
//	AccumulatedSelection - Structure - description of the composition of accumulated selections:
//	* Key - String - Dimension name.
//	* Value - Arbitrary - the value of the selection applied.
//	OptionalParameters - Structure, Undefined - structure of optional parameters with keys:
//	  * Column - ValueList of String, Undefined - list of columns to output.
//	  * String - ValueList of String, Undefined - a list of strings to the output.
//	  * SearchIndexes - Map of KeyAndValue, Undefined - parameter description:
//	    ** Key - String - the names of the index columns, separated by commas.
//	    ** Value - Boolean -
//	  *AddFlag - Boolean - flag for adding a column in the format Flag + <dimension Name>. False by default.
//
// Returns:
//	ValueTable, ValueTree - the result of executing the layout scheme (table or tree, depending on the output of the hierarchy).
//
Function GetSelectionOfCellsHierarchically(CellData_, Dimensions, AccumulatedSelection,
	OptionalParameters = Undefined) Export
	
	// Getting optional parameters
	Column = Undefined;
	String = Undefined;
	SearchIndexes = Undefined;
	AddFlag = False;
	ShowItemHierarchy = False;
	AdditionalSelection = Undefined;
	GenerationMode = Undefined;
	SortingExpression = Undefined;
	If OptionalParameters <> Undefined Then
		OptionalParameters.Property("Column", Column);
		OptionalParameters.Property("String", String);
		OptionalParameters.Property("SearchIndexes", SearchIndexes);
		OptionalParameters.Property("AddFlag", AddFlag);
		OptionalParameters.Property("ShowItemHierarchy", ShowItemHierarchy);
		OptionalParameters.Property("AdditionalSelection", AdditionalSelection);
		OptionalParameters.Delete("AdditionalSelection");
		OptionalParameters.Property("GenerationMode", GenerationMode);
		OptionalParameters.Property("SortingExpression", SortingExpression);
		If SortingExpression = Undefined Then
			OptionalParameters.Property("PresentationExpression", SortingExpression);
		EndIf;
		If AddFlag = Undefined Then
			AddFlag = False;
		EndIf;
	EndIf;
	
	FinReports = FinancialReportingServer;
	Set = Undefined;
	DCS = FinReports.NewSchemaSetObject("CellData_", Set);
	FinReports.NewSetField(Set, "MainItem");
	FinReports.NewSetField(Set, "String");
	FinReports.NewSetField(Set, "Column");
	
	ResourcesColumnNames = New Array;
	For Each ColumnCellData In CellData_.Columns Do
		If StrFind(ColumnCellData.Name, "Sum") > 0 Or StrFind(ColumnCellData.Name, "Count") > 0 Then
			ResourcesColumnNames.Add(ColumnCellData.Name);
		EndIf;
	EndDo;
	If ResourcesColumnNames.Count() = 0 Then
		ResourcesColumnNames.Add("IndicatorValue");
	EndIf;
	
	If TypeOf(Dimensions) = Type("Array") Then
		
		MeasurementList = Dimensions;
		FinReports.NewSetField(Set, "MinimumNumberInOrder");
		For Each ColumnName In ResourcesColumnNames Do
			FinReports.NewSetField(Set, ColumnName);
		EndDo;
		If MeasurementList.Count() > 1 Then
			ShowItemHierarchy = False;
		EndIf;
		
	Else
		
		MeasurementList = New Array;
		MeasurementList.Add(Dimensions);
		
	EndIf;
	
	For Each DimensionName In MeasurementList Do
	
		If ShowItemHierarchy Or ValueIsFilled(SortingExpression) Then
			DimensionKind = FinancialReportingCached.BudgetReportFieldByName(DimensionName);
			DescriptionOfMeasurementTypes = FinancialReportingCached.TypeOfAnalyticsTypeValue(DimensionName, DimensionKind);
		Else
			DescriptionOfMeasurementTypes = Undefined;
		EndIf;
		Field = FinReports.NewSetField(Set, DimensionName, , , DescriptionOfMeasurementTypes);
		If ShowItemHierarchy Then
			// The hierarchy is available when using the hierarchy for all types of values,
			// so it is enough to check one type of values
			MetadataObjectName = Metadata.FindByType(DescriptionOfMeasurementTypes.Types()[0]).FullName();
			FinReports.NewCalculatedField(DCS, "IsFolder", 
				?(TMCommonUseCached.HasObjectAttribute(MetadataObjectName, "IsFolder"),
				DimensionName + ".IsFolder", "FALSE"), , , New TypeDescription("Boolean"));
			FinReports.NewResource(DCS, "IsFolder", , "IsFolder");
		EndIf;
		OrderField = Field.OrderExpressions.Add();
		OrderField.Expression = 
		"CASE
		|	WHEN ValueIsFilled(" + DimensionName + ") THEN
		|	0 ELSE 1 END";
		OrderField.OrderType = DataCompositionSortDirection.Asc;
		
		If ValueIsFilled(SortingExpression) Then
			If MeasurementList.Find(DimensionName) = 0 Then
				OrderField = Field.OrderExpressions.Add();
				OrderField.Expression = FinancialReportingCached.TextOfSortRepresentationExpressionWithDimensionName(
					SortingExpression, DimensionName);
				OrderField.OrderType = DataCompositionSortDirection.Asc;
			EndIf;
		Else
			OrderField = Field.OrderExpressions.Add();
			OrderField.Expression = DimensionName;
			OrderField.OrderType = DataCompositionSortDirection.Asc;
			OrderField.AutoOrder = True;
		EndIf;
	
	EndDo;
	
	If MeasurementList.Count() > 1
		And GenerationMode <> Enums.ModesOfBudgetReportGeneration.Report Then
		TextOfExpressionYes = " AND (ValueIsFilled (" + StrConcat(MeasurementList, ") OR ValueIsFilled(") + "))";
		TextOfExpressionNo = " AND (NOT ValueIsFilled (" + StrConcat(MeasurementList, ") OR NOT ValueIsFilled(")
			+ "))";
		ConditionText = StrConcat(ResourcesColumnNames, " = 0 OR ") + " = 0";
		FinReports.NewCalculatedField(DCS, "ThereIsEmptyAnalytics", "CASE WHEN (" + ConditionText + ") " + TextOfExpressionYes
			+ TextOfExpressionNo + " AND MinimumNumberInOrder IS NULL THEN TRUE ELSE FALSE END", , ,
			New TypeDescription("Boolean"));
	EndIf;
	
	Composer = FinReports.SchemaComposer(DCS);
	
	If Column <> Undefined
		And ValueIsFilled(Column) Then
		
		ReportComparisonView = DataCompositionComparisonType.InList;
		Filter = FinReports.NewFilter(Composer.Settings.Filter, "Column", Column);
		Filter.ComparisonType = ReportComparisonView;
		
	EndIf;
	
	If String <> Undefined
		And ValueIsFilled(String) Then
		
		ReportComparisonView = DataCompositionComparisonType.InList;
		Filter = FinReports.NewFilter(Composer.Settings.Filter, "String", String);
		Filter.ComparisonType = ReportComparisonView;
		
	EndIf;
	
	If ShowItemHierarchy Then
		
		FinReports.NewSelectionField(Composer.Settings, "IsFolder");
		
		If Not ValueIsFilled(GenerationMode)
			Or GenerationMode <> Enums.ModesOfBudgetReportGeneration.Report Then
			ReportComparisonView = DataCompositionComparisonType.Filled;
			FinReports.NewFilter(Composer.Settings.Filter, DimensionName, , , ReportComparisonView);
		EndIf;
		
		If TypeOf(AdditionalSelection) = Type("ValueStorage") Then
			Filter_Settings = AdditionalSelection.Get();
			If TypeOf(Filter_Settings) = Type("DataCompositionSettings")
				And Filter_Settings.Filter.Items.Count() > 0 Then
				ProcessSelectionSettingsByAnalyticsHierarchy(Filter_Settings.Filter, DimensionName);
				Settings = Composer.GetSettings();
				DataCompositionClientServer.CopyDataCompositionFilter(DCS, Settings, Filter_Settings);
				Composer.LoadSettings(Settings);
				OptionalParameters.Insert("AdditionalSelection", AdditionalSelection);
			EndIf;
		EndIf;
		
	EndIf;
	
	FinReports.NewFilter(Composer.Settings.Filter, "MainItem", True);
	
	If MeasurementList.Count() > 1
		And GenerationMode <> Enums.ModesOfBudgetReportGeneration.Report Then
		FinReports.NewFilter(Composer.Settings.Filter, "ThereIsEmptyAnalytics", False);
	EndIf;
	
	// Index-based search
	LinesInWhichToSearch = FindRowsGivenIndexes(CellData_, Undefined, Undefined,
		AccumulatedSelection, SearchIndexes);
	LinesInWhichToSearch = CellData_.Copy(LinesInWhichToSearch);
	
	Group = Undefined;
	
	For Each DimensionName In MeasurementList Do
		
		Order = Composer.Settings.Order.Items.Add(Type("DataCompositionOrderItem"));
		Order.Field = New DataCompositionField(DimensionName);
		
		If Group = Undefined Then
			Group = FinReports.NewGrouping(Composer.Settings.Structure, DimensionName, ?(
				ShowItemHierarchy, DataCompositionGroupType.Hierarchy, Undefined));
		Else
			FinReports.NewDimensionField(Group, DimensionName);
		EndIf;
		
		If AddFlag Then
			FinReports.NewSetField(Set, "Flag" + DimensionName);
			FinReports.NewDimensionField(Group, "Flag" + DimensionName);
		EndIf;
		
	EndDo;
		
	If ShowItemHierarchy Then
		FinReports.NewSelectionField(Group, "IsFolder");
	EndIf;
	
	FinReports.SetOutputParameter(Composer.Settings,
			"HorizontalOverallPlacement",
			DataCompositionTotalPlacement.None);
	FinReports.SetOutputParameter(Composer.Settings,
			"VerticalOverallPlacement",
			DataCompositionTotalPlacement.None);
	
	Result = FinReports.UploadDCSResults(DCS, Composer, New Structure("CellData_",
		LinesInWhichToSearch), ShowItemHierarchy);
	
	Return Result;
	
EndFunction

#Region BudgetGenerationProceduresAndFunctions

// Returns the data cell for the budget and the parameters of their output
//
// Parameters:
//	Parameters - See Documents.BudgetEntryForm.ParametersForDisplayingBudgetViewInTableDocument
//
// Returns:
//	Structure - cell data and output parameters:
//		* CellData_ - See BudgetReportingDisplayServer.CellData_
//		* DetailsData - See AddOutputParameter.OutputParameters
//		* Result - SpreadsheetDocument -
//		* BudgetProfileDisplayParameters - See BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView
//		* LevelStyle - Structure - Contains:
// 	 		** Value - See GetCacheOfEditingListLineStyles
//		* TreeOfEditListRows - ValueTree -
//		* Remarks - String, Arbitrary, Structure -
//
Function BudgetInstanceData(Parameters) Export
	
	StructureOfOutputParameters = Parameters.BudgetProfileDisplayParameters;
	GenerationMode = Parameters.GenerationMode;
	
	Result = GetDataForBudgetReport(Parameters, GenerationMode, StructureOfOutputParameters);
	
	CalculationResult2 = New Structure;
	CalculationResult2.Insert("CellData_", Result.CellData_);
	
	If GenerationMode = Enums.ModesOfBudgetReportGeneration.Document
		Or GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget Then
		
		StructureOfOutputParameters.Insert("TableColumns", Result.TableColumns);
		
		CalculationResult2.Insert("DetailsData", Result.DetailsData);
		CalculationResult2.Insert("Result", Result.SpreadsheetDocument);
		CalculationResult2.Insert("BudgetProfileDisplayParameters", StructureOfOutputParameters);
		CalculationResult2.Insert("LevelStyle", Result.LevelStyle);
		CalculationResult2.Insert("TreeOfEditListRows", Result.TreeOfEditListRows);
		If Result.Property("ConsiderAdditionalSelectionByHierarchy")
			And Parameters.ConsiderAdditionalSelectionByHierarchy Then
			CalculationResult2.Insert("ConsiderAdditionalSelectionByHierarchy", True);
		EndIf;
		If Result.Property("CellTotalsNeedToBeRecalculated") Then
			CalculationResult2.Insert("CellTotalsNeedToBeRecalculated", True);
		EndIf;
		
		If GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget Then
			CalculationResult2.Insert("Remarks", Result.Remarks);
		ElsIf Result.Property("CellDataSortingString") Then
			CalculationResult2.Insert("CellDataSortingString", Result.CellDataSortingString);
		EndIf;
		
	ElsIf GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType Then
		
		If Result.Property("BudgetFlowItemTurnovers") Then
			CalculationResult2.Insert("BudgetFlowItemTurnovers", Result.BudgetFlowItemTurnovers);
		EndIf;
		If Result.Property("BudgetFlowItemsDimension") Then
			CalculationResult2.Insert("BudgetFlowItemsDimension", Result.BudgetFlowItemsDimension);
		EndIf;
		
	EndIf;
	
	Return CalculationResult2;
	
EndFunction

#EndRegion 

#EndRegion 

#Region Private

#Region BudgetGenerationProceduresAndFunctions

#Region GettingBudgetReportData

Function DataForBudgetReport(Parameters) Export
	
	Result = GetDataForBudgetReport(Parameters, Enums.ModesOfBudgetReportGeneration.Report);
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("Result", Result.SpreadsheetDocument);
	ExecutionResult.Insert("CellData_", Result.CellData_);
	ExecutionResult.Insert("DetailsData", Result.DetailsData);
	
	If Parameters.Property("CompareOnDifferentRelevanceDates")
		And Parameters.CompareOnDifferentRelevanceDates
		And Parameters.Property("DateOfRelevanceComparison") Then
		Parameters.Insert("UpdateDate", Parameters.DateOfRelevanceComparison);
		
		ResultComparison = GetDataForBudgetReport(Parameters, Enums.ModesOfBudgetReportGeneration.Report);
		
		ExecutionResult.Insert("ResultComparison", ResultComparison.SpreadsheetDocument);
		ExecutionResult.Insert("CellDataComparison", ResultComparison.CellData_);
		ExecutionResult.Insert("DecryptionDataComparison", ResultComparison.DetailsData);
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

Procedure PutDataForBudgetReportInStorage(Parameters, StorageAddress) Export
	
	ExecutionResult = DataForBudgetReport(Parameters);
	PutToTempStorage(ExecutionResult, StorageAddress);
	
EndProcedure

// Performs actions to build a budget (preparation of auxiliary cached data, getting data from
// the database, mapping data to the report structure, data output to a tabular document)
// and a tabular document with the output budget.
// Key operation: "Budgeting.The conclusion of the received data for the budget report".
//
// Parameters:
// 	DataParameters - See Documents.BudgetEntryForm.ParametersForDisplayingBudgetViewInTableDocument
// 	GenerationMode - EnumRef.ModesOfBudgetReportGeneration - Budget formation mode.
// 	LinkToBudgetViewOutputParameters - See BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView
//
// Returns:
// 	Structure - Structure with data for building a budget:
// 	 *CellData_ - See BudgetReportingDisplayServer.CellData_
//
Function GetDataForBudgetReport(DataParameters, GenerationMode, LinkToBudgetViewOutputParameters = Undefined)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Budgeting.OutputGettingDataForBudgetReport");
	
	BudgetProfile = DataParameters.BudgetProfile;
	Action = Undefined;
	DataParameters.Property("Action", Action);
	
	ParametersOfCalculationStages = New Structure;
	Result = New Structure;
	Result.Insert("CellData_", Undefined);
	ContinueCalculation = True;
	
	#Region ControlOfFillingInBudgetType
	If ContinueCalculation Then
		ParametersOfCalculationStages.Insert("DataParameters", DataParameters);
		ParametersOfCalculationStages.Insert("BudgetProfile", BudgetProfile);
		
		OutputGettingDataForBudgetReportControllingHowBudgetViewIsFilledIn(ParametersOfCalculationStages, ContinueCalculation);
	EndIf;
	#EndRegion 
	
	#Region GettingControlOverBudgetViewOutputParameters
	If ContinueCalculation Then
		ParametersOfCalculationStages.Insert("GenerationMode", GenerationMode);
		ParametersOfCalculationStages.Insert("LinkToBudgetViewOutputParameters", LinkToBudgetViewOutputParameters);
		ParametersOfCalculationStages.Insert("BudgetProfileDisplayParameters", Undefined);
		ParametersOfCalculationStages.Insert("ColumnStructureOfDataTable", Undefined);
		ParametersOfCalculationStages.Insert("StructureOfReportDescription", Undefined);
		
		OutputGettingDataForBudgetReportGettingControlOfBudgetViewOutputParameters(ParametersOfCalculationStages, Result, ContinueCalculation);
	EndIf;
	#EndRegion 
	
	#Region GettingUpToDateBudgetDataToCorrectInstanceOfBudget
	If ContinueCalculation And Action = Enums.TypesOfBudgetEntryFormActions.CorrectBudgetEntryForm Then
		
		OutputGettingDataForBudgetReportGettingUpToDateBudgetData(ParametersOfCalculationStages, Result, ContinueCalculation);
	EndIf;
	#EndRegion
	
	#Region GettingDataBySource
	If ContinueCalculation Then
		ParametersOfCalculationStages.Insert("DataDCS", Undefined);
		ParametersOfCalculationStages.Insert("OutputTree", Undefined);
		ParametersOfCalculationStages.Insert("DataCache", Undefined);
		ParametersOfCalculationStages.Insert("SourceData_", Undefined);
		
		OutputGettingDataForBudgetReportGettingDataBySource(ParametersOfCalculationStages, Result, ContinueCalculation);
	EndIf;
	#EndRegion 
	
	#Region GettingControlOfStructureOfCellsWithData
	If ContinueCalculation Then
		ParametersOfCalculationStages.Insert("CellData_", Undefined);
		
		OutputGettingDataForBudgetReportGettingControlOverStructureOfDataCells(ParametersOfCalculationStages, Result, ContinueCalculation);
	EndIf;
	#EndRegion 
	
	#Region PreparingOutputParameters
	If ContinueCalculation Then
		ParametersOfCalculationStages.Insert("OutputParameters", Undefined);
		ParametersOfCalculationStages.Insert("TreeOfEditListRows", Undefined);
		
		OutputGettingDataForBudgetReportPreparingOutputParameters(ParametersOfCalculationStages, ContinueCalculation);
	EndIf;
	#EndRegion 
	
	#Region OutputOfBudgetReport
	If ContinueCalculation Then
		ParametersOfCalculationStages.Insert("TabularDocumentResult", Undefined);
		
		OutputGettingDataForBudgetReportOutputOfBudgetReport(ParametersOfCalculationStages, Result, ContinueCalculation);
		
		TableHeight = ParametersOfCalculationStages.TabularDocumentResult.TableHeight;
		TableWidth = ParametersOfCalculationStages.TabularDocumentResult.TableWidth;
	EndIf;
	#EndRegion 
	
	#Region Budgeting_
	If ContinueCalculation Then
		OutputGettingDataForBudgetReportCreatingBudget(ParametersOfCalculationStages, Result, ContinueCalculation);
		
		TableHeight = ParametersOfCalculationStages.TabularDocumentResult.TableHeight;
		TableWidth = ParametersOfCalculationStages.TabularDocumentResult.TableWidth;
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, TableHeight * TableWidth / 10); // Specific calculation time of 10 cells, to reduce the error
	EndIf;
	#EndRegion 
	
	Return Result;
	
EndFunction

Procedure OutputGettingDataForBudgetReportControllingHowBudgetViewIsFilledIn(ParametersOfCalculationStages, ContinueCalculation)
	
	If Not ValueIsFilled(ParametersOfCalculationStages.BudgetProfile) Then
		ContinueCalculation = False;
	EndIf;

EndProcedure

Procedure OutputGettingDataForBudgetReportGettingControlOfBudgetViewOutputParameters(ParametersOfCalculationStages, Result, ContinueCalculation)
	
	GenerationMode = ParametersOfCalculationStages.GenerationMode;
	BudgetProfile = ParametersOfCalculationStages.BudgetProfile;
	LinkToBudgetViewOutputParameters = ParametersOfCalculationStages.LinkToBudgetViewOutputParameters;
	
	If GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType Then
		BudgetProfileDisplayParameters = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(BudgetProfile, GenerationMode);
	Else
		If LinkToBudgetViewOutputParameters = Undefined Then
			BudgetProfileDisplayParameters = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(BudgetProfile, GenerationMode);
		Else
			BudgetProfileDisplayParameters = LinkToBudgetViewOutputParameters;
		EndIf;
	EndIf;
	
	// Report description - the composition of the columns of the data table.
	ColumnStructureOfDataTable    = BudgetProfileDisplayParameters.ColumnStructureOfDataTable;
	
	// The structure of the report description contains:
	// The structure of the source cells is a table with a description of the structure of the report. in fact, the matrix of the report is expanded into a list.
	// Data sources are segments of selected articles and indicators, broken down by selection and bias.
	StructureOfReportDescription          = BudgetProfileDisplayParameters.StructureOfReportDescription;
	
	If Not StructureOfReportDescription.DataSources.Count() Then
		
		CalculationResult2 = New Structure;
		CalculationResult2.Insert("DetailsData", Undefined);
		CalculationResult2.Insert("TableColumns", Undefined);
		CalculationResult2.Insert("DetailsData", Undefined);
		CalculationResult2.Insert("CellData_", Undefined);
		CalculationResult2.Insert("SpreadsheetDocument", New SpreadsheetDocument);
		CalculationResult2.Insert("BudgetProfileDisplayParameters", Undefined);
		CalculationResult2.Insert("LevelStyle", Undefined);
		CalculationResult2.Insert("TreeOfEditListRows", Undefined);
		
		Result = CalculationResult2;
		ContinueCalculation = False;
		
	EndIf;
	
	ParametersOfCalculationStages.Insert("BudgetProfile", BudgetProfile);
	ParametersOfCalculationStages.Insert("GenerationMode", GenerationMode);
	ParametersOfCalculationStages.Insert("LinkToBudgetViewOutputParameters", LinkToBudgetViewOutputParameters);
	ParametersOfCalculationStages.Insert("BudgetProfileDisplayParameters", BudgetProfileDisplayParameters);
	ParametersOfCalculationStages.Insert("ColumnStructureOfDataTable", ColumnStructureOfDataTable);
	ParametersOfCalculationStages.Insert("StructureOfReportDescription", StructureOfReportDescription);
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	ParametersOfCalculationStages - Structure - LongDesc:
// * LinkToBudgetViewOutputParameters - See BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView
// * BudgetProfileDisplayParameters - See BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView
// * GenerationMode - EnumRef.ModesOfBudgetReportGeneration -
// * StructureOfReportDescription - See BudgetReportingCacheCalculationServer.DescriptionOfReport
// * BudgetProfile - CatalogRef.BudgetProfiles -
// * DataParameters - Structure -
// 	Result - Structure - LongDesc:
// * CellData_ - ValueTable, Undefined -
// 	ContinueCalculation - Boolean - LongDesc
Procedure OutputGettingDataForBudgetReportGettingDataBySource(ParametersOfCalculationStages, Result, ContinueCalculation)
	
	DataParameters = ParametersOfCalculationStages.DataParameters;
	BudgetProfile = ParametersOfCalculationStages.BudgetProfile;
	BudgetProfileDisplayParameters =
		ParametersOfCalculationStages.BudgetProfileDisplayParameters; // See BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView
	StructureOfReportDescription =
		ParametersOfCalculationStages.StructureOfReportDescription; // See BudgetReportingCacheCalculationServer.DescriptionOfReport
	
	// SKD by sources - a generated SKD for obtaining data according to the plan and from the actual tables.
	DataDCS = BudgetProfileDisplayParameters.DataDCS;
	
	// Output tree - a tree for the output of the report, built on the basis of the structure of the report.
	OutputTree = BudgetProfileDisplayParameters.OutputTree;
	DataCache = BudgetProfileDisplayParameters.DataCache;
	
	// We get the data from the sources for the SKD.
	SourceData_ = GetDataOnSources(BudgetProfile,
		DataDCS,
		DataParameters,
		StructureOfReportDescription.DataSources,
		StructureOfReportDescription.CellStructure,
		DataCache);
	
	ContinueCalculation = True;
	
	ParametersOfCalculationStages.Insert("DataParameters", DataParameters);
	ParametersOfCalculationStages.Insert("BudgetProfile", BudgetProfile);
	ParametersOfCalculationStages.Insert("BudgetProfileDisplayParameters", BudgetProfileDisplayParameters);
	ParametersOfCalculationStages.Insert("StructureOfReportDescription", StructureOfReportDescription);
	ParametersOfCalculationStages.Insert("DataDCS", DataDCS);
	ParametersOfCalculationStages.Insert("OutputTree", OutputTree);
	ParametersOfCalculationStages.Insert("DataCache", DataCache);
	ParametersOfCalculationStages.Insert("SourceData_", SourceData_);
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	ParametersOfCalculationStages - Structure - LongDesc:
// 	*ColumnStructureOfDataTable - See BudgetReportingCacheCalculationServer.ColumnsOfDataTable_
// 	*StructureOfReportDescription - See BudgetReportingCacheCalculationServer.DescriptionOfReport
// 	*GenerationMode - EnumRef.ModesOfBudgetReportGeneration -
// 	*BudgetProfile - CatalogRef.BudgetProfiles -
// 	*DataParameters - Structure -
// 	Result - Structure - LongDesc:
// 	*CellData_ - See BudgetReportingDisplayServer.CellData_
// 	ContinueCalculation - Boolean - Flag for continuing the calculation.
Procedure OutputGettingDataForBudgetReportGettingControlOverStructureOfDataCells(ParametersOfCalculationStages, Result, ContinueCalculation)
	
	ColumnStructureOfDataTable = ParametersOfCalculationStages.ColumnStructureOfDataTable;
	DataParameters = ParametersOfCalculationStages.DataParameters;
	StructureOfReportDescription = ParametersOfCalculationStages.StructureOfReportDescription;
	SourceData_ = ParametersOfCalculationStages.SourceData_;
	GenerationMode = ParametersOfCalculationStages.GenerationMode;
	DataCache = ParametersOfCalculationStages.DataCache;
	
	// We get cell data by source.
	CellData_ = CellData_(ColumnStructureOfDataTable,
		DataParameters,
		StructureOfReportDescription,
		SourceData_,
		GenerationMode,
		DataCache);
	
	If GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType Then
		Result = New Structure("CellData_", CellData_);
		ContinueCalculation = False;
	EndIf;
	
	ParametersOfCalculationStages.Insert("ColumnStructureOfDataTable", ColumnStructureOfDataTable);
	ParametersOfCalculationStages.Insert("DataParameters", DataParameters);
	ParametersOfCalculationStages.Insert("StructureOfReportDescription", StructureOfReportDescription);
	ParametersOfCalculationStages.Insert("SourceData_", SourceData_);
	ParametersOfCalculationStages.Insert("GenerationMode", GenerationMode);
	ParametersOfCalculationStages.Insert("DataCache", DataCache);
	ParametersOfCalculationStages.Insert("CellData_", CellData_);
	
EndProcedure

Procedure OutputGettingDataForBudgetReportPreparingOutputParameters(ParametersOfCalculationStages, ContinueCalculation)
	
	OutputTree = ParametersOfCalculationStages.OutputTree;
	CellData_ = ParametersOfCalculationStages.CellData_; // See CellData_
	BudgetProfile = ParametersOfCalculationStages.BudgetProfile;
	DataParameters = ParametersOfCalculationStages.DataParameters;
	GenerationMode = ParametersOfCalculationStages.GenerationMode;
	ColumnStructureOfDataTable = ParametersOfCalculationStages.ColumnStructureOfDataTable;
	DataCache = ParametersOfCalculationStages.DataCache;
	StructureOfReportDescription = ParametersOfCalculationStages.StructureOfReportDescription;
	
	// We output the tree to the report.
	OutputParameters = New Structure();
	AddOutputParameter(OutputParameters, "OutputTree", OutputTree);
	AddOutputParameter(OutputParameters, "CellData_", CellData_);
	AddOutputParameter(OutputParameters, "BudgetProfile", BudgetProfile);
	AddOutputParameter(OutputParameters, "BeginOfPeriod", DataParameters.BeginOfPeriod);
	AddOutputParameter(OutputParameters, "EndOfPeriod", DataParameters.EndOfPeriod);
	AddOutputParameter(OutputParameters, "GenerationMode", GenerationMode);
	
	AddOutputParameter(OutputParameters, "MeasurementPresentations", PresentationOfReportDimensions(OutputTree,
		CellData_, ColumnStructureOfDataTable, DataCache.CacheOfBudgetItemDetails.CacheOfAdditionalBankingDetails));
	AddOutputParameter(OutputParameters, "DetailsData", New Map);
	AddOutputParameter(OutputParameters, "CacheAnalystValues", DataCache.CacheAnalystValues);
	AddOutputParameter(OutputParameters, "DimensionSearchIndexes", New Map);
	AddOutputParameter(OutputParameters, "CellParameters", StructureOfReportDescription.CellParameters);
	AddOutputParameter(OutputParameters, "CellStructure", StructureOfReportDescription.CellStructure);
	AddOutputParameter(OutputParameters, "ColumnStructureOfDataTable", ColumnStructureOfDataTable);
	AddOutputParameter(OutputParameters, "PeriodParameters_1", ConvertDataParametersToPeriodData(ColumnStructureOfDataTable, DataParameters));
	AddOutputParameter(OutputParameters, "SubordinateElementsOfBudgetView", StructureOfReportDescription.TableOfSubordinationOfElements);
	AddOutputParameter(OutputParameters, "SubstitutionValues", GetSubstitutionValuesForDataParameters(GenerationMode, DataParameters));
	AddOutputParameter(OutputParameters, "DisplayNotes_", False);
	AddOutputParameter(OutputParameters, "DisplayTableNumbers", False);
	
	CacheOfUnitParameters = GetCacheOfUnitParameters(CellData_, StructureOfReportDescription.CellParameters);
	AddOutputParameter(OutputParameters, "CacheOfUnitParameters", CacheOfUnitParameters);
	
	CacheOfCurrencyParameters = GetCacheOfCurrencyParameters(CellData_,
			StructureOfReportDescription.CellParameters,
			OutputParameters.SubordinateElementsOfBudgetView);
	AddOutputParameter(OutputParameters, "CacheOfCurrencyParameters", CacheOfCurrencyParameters);
	
	If (GenerationMode = Enums.ModesOfBudgetReportGeneration.Document
		Or GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget) Then
		
		TreeOfEditListRows = New ValueTree;
		TreeOfEditListRows.Columns.Add("String");
		TreeOfEditListRows.Columns.Add("Presentation");
		TreeOfEditListRows.Columns.Add("Picture");
		TreeOfEditListRows.Columns.Add("Level");
		TreeOfEditListRows.Columns.Add("TableID");
		TreeOfEditListRows.Columns.Add("GroupingID");
		TreeOfEditListRows.Columns.Add("DimensionName");
		TreeOfEditListRows.Columns.Add("FixedValue");
		TreeOfEditListRows.Columns.Add("ThisIsDimensionOther");
		TreeOfEditListRows.Columns.Add("EditedValues");
		TreeOfEditListRows.Columns.Add("Details");
		TreeOfEditListRows.Columns.Add("ThisIsACombinedDimension");
		
		AddOutputParameter(OutputParameters, "TreeOfEditListRows", TreeOfEditListRows);
		AddOutputParameter(OutputParameters, "LevelStyle", New Map);
		
		If GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget Then
			
			NoteOutputParameters = GetNoteOutputParameters(ColumnStructureOfDataTable, CellData_, OutputTree);
			CommonClientServer.SupplementStructure(OutputParameters, NoteOutputParameters, True);
			
		EndIf;
		
	EndIf;
	
	ContinueCalculation = True;
	
	ParametersOfCalculationStages.Insert("OutputTree", OutputTree);
	ParametersOfCalculationStages.Insert("CellData_", CellData_);
	ParametersOfCalculationStages.Insert("BudgetProfile", BudgetProfile);
	ParametersOfCalculationStages.Insert("DataParameters", DataParameters);
	ParametersOfCalculationStages.Insert("GenerationMode", GenerationMode);
	ParametersOfCalculationStages.Insert("ColumnStructureOfDataTable", ColumnStructureOfDataTable);
	ParametersOfCalculationStages.Insert("DataCache", DataCache);
	ParametersOfCalculationStages.Insert("StructureOfReportDescription", StructureOfReportDescription);
	ParametersOfCalculationStages.Insert("OutputParameters", OutputParameters);
	ParametersOfCalculationStages.Insert("TreeOfEditListRows", TreeOfEditListRows);
	
EndProcedure

Procedure OutputGettingDataForBudgetReportOutputOfBudgetReport(ParametersOfCalculationStages, Result, ContinueCalculation)
	
	OutputParameters = ParametersOfCalculationStages.OutputParameters; // See AddOutputParameter.OutputParameters
	BudgetProfileDisplayParameters = ParametersOfCalculationStages.BudgetProfileDisplayParameters;
	
	OutputParameters.Insert("CacheOfBudgetItemDetails", ParametersOfCalculationStages.DataCache.CacheOfBudgetItemDetails);
	OutputParameters.Insert("CacheOfEmptyAnalyticsPresentations", New Map);
	
	// Adding rows to a table without indexes for optimization purposes.
	CellDataAddedRows = OutputParameters.CellData_.CopyColumns(); // ValueTable - cell data table.
	OutputParameters.Insert("CellDataAddedRows", CellDataAddedRows);
	OutputParameters.Insert("TableColumnsByReportElements", New Map); // Cache of trees of columns of cells by elements of the "Table" report.
	
	OutputParameters.Insert("ShowItemHierarchy", ParametersOfCalculationStages.DataParameters.ShowItemHierarchy);
	OutputParameters.Insert("ConsiderAdditionalSelectionByHierarchy", ParametersOfCalculationStages.DataParameters.ConsiderAdditionalSelectionByHierarchy);
	If ParametersOfCalculationStages.DataParameters.Property("ReportCurrency") Then
		OutputParameters.Insert("ReportCurrency", ParametersOfCalculationStages.DataParameters.ReportCurrency);
	EndIf;
	If ParametersOfCalculationStages.DataParameters.Property("SumShiftFormat") Then
		OutputParameters.Insert("SumShiftFormat", ParametersOfCalculationStages.DataParameters.SumShiftFormat);
		// The amount shift format should also be used for monetary NFP
		NFPReport = OutputParameters.CacheOfBudgetItemDetails.CacheOfAdditionalBankingDetails.Copy(
			New Structure("Attribute",
			ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.NonFinancialItem)).UnloadColumn(
			"Value");
		OutputParameters.Insert("TypesOfNFPReport", Common.ObjectsAttributeValue(NFPReport,
			"IndicatorKind"));
	EndIf;
	CrawlingReportData(OutputParameters);
	
	If CellDataAddedRows.Count() Then
		CellTableIndexColumns = New Array;
		For Each TableIndex In OutputParameters.CellData_.Indexes Do
			IndexColumns = "";
			For Each IndexColumnName In TableIndex Do
				IndexColumns = IndexColumns + ?(IndexColumns = "", "", ", ") + IndexColumnName;
			EndDo;
			CellTableIndexColumns.Add(IndexColumns);
		EndDo;
		OutputParameters.CellData_.Indexes.Clear();
		
		// For the added rows, the values in the columns are not filled in.
		NotCopiedColumns = New Array;
		NotCopiedColumns.Add("FilterCells");
		NotCopiedColumns.Add("CalculatedSum");
		NotCopiedColumns.Add("CalculatedSumCurr");
		NotCopiedColumns.Add("CalculatedCount");
		NotCopiedColumns.Add("CalculatedValue");
		NotCopiedColumns.Add("SumCurrTurnover");
		NotCopiedColumns.Add("SumTurnover");
		NotCopiedColumns.Add("Sum");
		NotCopiedColumns.Add("SumCurr");
		NotCopiedColumns.Add("Count");
		NotCopiedColumns.Add("Value");
		NotCopiedColumns.Add("AreaNameSum");
		NotCopiedColumns.Add("AreaNameCount");
		NotCopiedColumns.Add("AreaNameValue");
		NotCopiedColumns.Add("AreaNameSumHierarchy");
		NotCopiedColumns.Add("AreaNameQuantityHierarchy");
		NotCopiedColumns.Add("AreaNameValueHierarchy");
		
		DefaultValues = New Structure;
		DefaultValues.Insert("CalculatedSum", False);
		DefaultValues.Insert("CalculatedSumCurr", False);
		DefaultValues.Insert("CalculatedCount", False);
		DefaultValues.Insert("CalculatedValue", False);
		
		ListOfConvolutionColumns = "";
		For Each Column In CellDataAddedRows.Columns Do
			If NotCopiedColumns.Find(Column.Name) <> Undefined Then
				Continue;
			EndIf;
			ListOfConvolutionColumns = ListOfConvolutionColumns + ?(ListOfConvolutionColumns = "", "", ", ") + Column.Name;
		EndDo;
		
		CellDataAddedRowsConvolution = CellDataAddedRows.Copy(, ListOfConvolutionColumns);
		
		CellDataAddedRowsConvolution.GroupBy(ListOfConvolutionColumns);
		CellDataAddedRows.Indexes.Add(ListOfConvolutionColumns);
		
		For Each LineToAdd__ In CellDataAddedRowsConvolution Do
			NewRow = OutputParameters.CellData_.Add();
			FillPropertyValues(NewRow, LineToAdd__);
			FillPropertyValues(NewRow, DefaultValues);
			StringSearch = New Structure(ListOfConvolutionColumns);
			FillPropertyValues(StringSearch, NewRow);
			// In the "Selection cells" column, the column names can be listed in different order, so we fill them in separately.
			OriginalLines = CellDataAddedRows.FindRows(StringSearch);
			If OriginalLines.Count() > 0 Then
				NewRow.FilterCells = OriginalLines[0].FilterCells;
			EndIf;
		EndDo;
		
		CellDataAddedRowsConvolution = Undefined;
		
		For Each ColumnsNames In CellTableIndexColumns Do
			OutputParameters.CellData_.Indexes.Add(ColumnsNames);
		EndDo;
	EndIf;
	
	CellDataAddedRows = Undefined;
	OutputParameters.Delete("CellDataAddedRows");
	
	If ParametersOfCalculationStages.GenerationMode = Enums.ModesOfBudgetReportGeneration.Document Then
		SortingCellData = StrSplit("String,Column,MainItem,OperandType,RowIndex", ",");
		If OutputParameters.PeriodParameters_1.OrderedReportPeriodicities.Count() Then
			CommonClientServer.SupplementArray(SortingCellData,
				OutputParameters.PeriodParameters_1.OrderedReportPeriodicities);
		EndIf;
		CellDataSortingString = StrConcat(SortingCellData, ",");
		OutputParameters.CellData_.Sort(CellDataSortingString);
	EndIf;
	
	// Output of the budget report.
	TabularDocumentResult = OutputDataToReport(OutputParameters);
	
	OutputParameters.Delete("TableColumnsByReportElements");
	
	BudgetProfileDisplayParameters.Insert("CellDataTableIndexes", OutputParameters.DimensionSearchIndexes);
	
	Result = New Structure;
	Result.Insert("CellData_", ParametersOfCalculationStages.CellData_);
	Result.Insert("SpreadsheetDocument", TabularDocumentResult);
	Result.Insert("DetailsData", OutputParameters.DetailsData);
	
	If (ParametersOfCalculationStages.GenerationMode = Enums.ModesOfBudgetReportGeneration.Document
		Or ParametersOfCalculationStages.GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget) Then
		
		Result.Insert("TreeOfEditListRows", ParametersOfCalculationStages.TreeOfEditListRows);
		Result.Insert("LevelStyle", OutputParameters.LevelStyle);
		Result.Insert("TableColumns", OutputParameters.TableColumns);
		If OutputParameters.Property("ConsiderAdditionalSelectionByHierarchy") Then
			Result.Insert("ConsiderAdditionalSelectionByHierarchy", True);
		EndIf;
		If OutputParameters.Property("CellTotalsNeedToBeRecalculated") Then
			Result.Insert("CellTotalsNeedToBeRecalculated", True);
		EndIf;
		
		If ParametersOfCalculationStages.GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget Then
			
			Result.Insert("Remarks", OutputParameters.Remarks);
			
		Else
			
			Result.Insert("CellDataSortingString", CellDataSortingString);
			
		EndIf;
		
	EndIf;
	
	ContinueCalculation = True;
	
	ParametersOfCalculationStages.Insert("OutputParameters", OutputParameters);
	ParametersOfCalculationStages.Insert("BudgetProfileDisplayParameters", BudgetProfileDisplayParameters);
	ParametersOfCalculationStages.Insert("TabularDocumentResult", TabularDocumentResult);
	
EndProcedure

Procedure OutputGettingDataForBudgetReportCreatingBudget(ParametersOfCalculationStages, Result, ContinueCalculation)
	
	TabularDocumentResult = ParametersOfCalculationStages.TabularDocumentResult;
	OutputParameters = ParametersOfCalculationStages.OutputParameters;
	OutputTree = ParametersOfCalculationStages.OutputTree;
	
	CreateBudget(TabularDocumentResult, OutputParameters, OutputTree);
	
	ContinueCalculation = True;
	
	ParametersOfCalculationStages.Insert("TabularDocumentResult", TabularDocumentResult);
	ParametersOfCalculationStages.Insert("OutputParameters", OutputParameters);
	ParametersOfCalculationStages.Insert("OutputTree", OutputTree);
	
EndProcedure

Procedure OutputGettingDataForBudgetReportGettingUpToDateBudgetData(ParametersOfCalculationStages, Result,
	ContinueCalculation)
	
	GenerationMode = ParametersOfCalculationStages.GenerationMode;
	If GenerationMode <> Enums.ModesOfBudgetReportGeneration.FillType Then
		Return;
	EndIf;
	
	DataParameters = ParametersOfCalculationStages.DataParameters;
	ItemParameterCache = BudgetingServer.FillCacheOfArticleParameters(DataParameters.BudgetProfileDisplayParameters);
	Result.Insert("BudgetFlowItemTurnovers", DataParameters.BudgetFlowItemTurnovers.CopyColumns());
	Result.Insert("BudgetFlowItemsDimension", DataParameters.BudgetFlowItemsDimension.CopyColumns());
	
	QueryText = 
	"SELECT
	|	TurnoversAndTurnovers.PlanningPeriod AS PlanningPeriod,
	|	TurnoversAndTurnovers.BudgetFlowItem AS BudgetFlowItem,
	|	TurnoversAndTurnovers.Currency AS Currency,
	|	&TextOfDimensionsFields,
	|	TurnoversAndTurnovers.CountTurnover AS Count,
	|	TurnoversAndTurnovers.ScenarioAmountTurnover AS Sum,
	|	TurnoversAndTurnovers.AmountInCurrencyTurnover AS AmountInCurrency
	|FROM
	|	AccumulationRegister.BudgetTurnovers.Turnovers(
	|			,
	|			&UpdateDate,
	|			,
	|			&FilterByOrganization
	|				AND &FilterByDivision
	|				AND (PlanningPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|				AND Status = VALUE(Enum.PlanStatuses.Upholded)
	|				AND Scenario = &Scenario
	|				AND BudgetFlowItem IN (&ArrayOfArticles)) AS TurnoversAndTurnovers";
	
	SearchData_ = New Structure("BudgetFlowItem, Currency");
	ObjectAndCalculationParameters = New Structure("Object, ScenarioCurrency", Result, DataParameters.ScenarioCurrency);
	
	TextOfDimensionsFields = "";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextOfDimensionsFields = TextOfDimensionsFields + ?(TextOfDimensionsFields = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"TurnoversAndTurnovers.Dimension%1 AS Dimension%1",
				DimensionNumber);
		SearchData_.Insert(StringFunctionsClientServer.SubstituteParametersToString("Dimension%1", DimensionNumber));
	EndDo;
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", TextOfDimensionsFields);
	
	Query = New Query;
	Query.SetParameter("UpdateDate", DataParameters.UpdateDate);
	If DataParameters.Property("Organization") Then
		QueryText = StrReplace(QueryText, "&FilterByOrganization", "Organization = &Organization"); // Query-part
		Query.SetParameter("Organization", DataParameters.Organization);
	Else
		QueryText = StrReplace(QueryText, "&FilterByOrganization", "TRUE"); // Query-part
	EndIf;
	If DataParameters.Property("Department") Then
		QueryText = StrReplace(QueryText, "&FilterByDivision", "Department = &Department"); // Query-part
		Query.SetParameter("Department", DataParameters.Department);
	Else
		QueryText = StrReplace(QueryText, "&FilterByDivision", "TRUE"); // Query-part
	EndIf;
	Query.SetParameter("BeginOfPeriod", DataParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", DataParameters.EndOfPeriod);
	Query.SetParameter("Scenario", DataParameters.Scenario);
	Query.SetParameter("ArrayOfArticles",
		TMCommonUseClientServer.ConvertMatchOrStructureToArray(ItemParameterCache));
	Query.Text = QueryText;
	
	QueryResult = Query.Execute().Unload();
	
	SerialNumber = ParametersOfCalculationStages.DataParameters.MaximumNumberInOrder;
	For Each TableRow In QueryResult Do
		SerialNumber = SerialNumber + 1;
		FillPropertyValues(SearchData_, TableRow);
		RowID = BudgetReportingClientServer.IDOfBudgetItemAnalytics(
			ObjectAndCalculationParameters, SearchData_);
		StringRevolutions = ObjectAndCalculationParameters.Object.BudgetFlowItemTurnovers.Add();
		FillPropertyValues(StringRevolutions, TableRow);
		StringRevolutions.RowID = RowID;
		StringRevolutions.SerialNumber = SerialNumber;
	EndDo;
	ParametersOfCalculationStages.DataParameters.MaximumNumberInOrder = SerialNumber;
	
	ContinueCalculation = False;
	
EndProcedure

#EndRegion 

Procedure PlaceBudgetInstanceDataInStorage(Parameters, StorageAddress) Export
	
	CalculationResult2 = BudgetInstanceData(Parameters);
	PutToTempStorage(CalculationResult2, StorageAddress);
	
EndProcedure

Procedure PutBudgetTurnoverDataInVault(Parameters, StorageAddress) Export
	
	DataCompositionSchema = Reports.BudgetingTurnoverBalanceReport.GetTemplate("TurnoversPlan");
	BudgetingServer.AddDCSAnalyticsByType(DataCompositionSchema, "BudgetFlowItem");

	Settings = DataCompositionSchema.DefaultSettings;
	DataCompositionClientServer.SetParameter(Settings, "DateWhenTheDataIsUpToDate", Parameters.UpdateDate);
	DataCompositionClientServer.SetParameter(Settings, "Currency", Parameters.ReportCurrency);
	DataCompositionClientServer.SetParameter(Settings, "Period", New StandardPeriod(Parameters.BeginOfPeriod, Parameters.EndOfPeriod));
	DataCompositionClientServer.AddFilter(Settings, "BudgetFlowItem", Parameters.BudgetProfile);
	DataCompositionClientServer.AddFilter(Settings, "Scenario", Parameters.Scenario);
	If Parameters.Property("Organization") Then
		DataCompositionClientServer.AddFilter(Settings, "Organization", Parameters.Organization, DataCompositionComparisonType.InList);
	EndIf;
	If Parameters.Property("Department") Then
		DataCompositionClientServer.AddFilter(Settings, "Department", Parameters.Department, DataCompositionComparisonType.InList);
	EndIf;
	
	LayoutTemplateParameter = Settings.OutputParameters.Items.Find("AppearanceTemplate");
	If LayoutTemplateParameter.Value = "Main" 
		Or LayoutTemplateParameter.Value = "Main" Then
		LayoutTemplateParameter.Value = "ReportingBeige";
		LayoutTemplateParameter.Use = True;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer();
	
	Template = TemplateComposer.Execute(DataCompositionSchema, Settings);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ResultDocument = New SpreadsheetDocument;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	PutToTempStorage(ResultDocument, StorageAddress);
	
EndProcedure

// Calculates changes in cells in the table document of the budget instance
// Key operation: "Budgeting.Deductionreceiving changes to an instance of the budget".
// 
// Parameters:
//  Parameters - See Documents.BudgetEntryForm.ParametersForDisplayingBudgetViewInTableDocument
// Returns:
// 	Structure - LongDesc:
// 	*CellData_ - See BudgetReportingDisplayServer.CellData_
// 	*Result - ValueTable -
// 	*StructureOfOutputParameters - Structure -
//
Function BudgetInstanceChanges(Parameters) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Budgeting.OutputGettingBudgetInstanceChanges");
	
	StructureOfOutputParameters = Parameters.BudgetProfileDisplayParameters;
	
	CalculatedChanges = GetChangesToCellsRecursively(Parameters.BudgetProfile,
		Parameters.BeginOfPeriod,
		Parameters.EndOfPeriod,
		StructureOfOutputParameters,
		Parameters,
		Parameters.CellData_);
	
	CalculationResult2 = New Structure;
	CalculationResult2.Insert("Result", CalculatedChanges.Result);
	CalculationResult2.Insert("BudgetProfileDisplayParameters", StructureOfOutputParameters);
	CalculationResult2.Insert("CellData_", CalculatedChanges.CellData_);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
	Return CalculationResult2;
	
EndFunction

Procedure PlaceBudgetInstanceChangesInStorage(Parameters, StorageAddress) Export
	
	CalculationResult2 = BudgetInstanceChanges(Parameters);
	PutToTempStorage(CalculationResult2, StorageAddress);
	If Parameters.Property("Object") Then
		Parameters.Delete("Object");
	EndIf;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles -
// 	BeginOfPeriod - Date -
// 	EndOfPeriod  - Date -
// 	BudgetProfileDisplayParameters - See BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView
// 	DataParameters - Structure - LongDesc:
// 	*Organization - CatalogRef.Companies -
// 	*Department - CatalogRef.BusinessStructure -
// 	*Currency - CatalogRef.Currencies -
// 	*Scenario - CatalogRef.BudgetingScenarios -
// 	*Document - DocumentRef.BudgetEntryForm -
// 	*BudgetFlowItemsDimension - ValueTable -
// 	*BudgetFlowItemTurnovers - ValueTable -
// 	*DimensionValues_ - ValueTable -
// 	*UpdateDate - Date -
// 	*ScenarioCurrency - CatalogRef.Currencies -
// 	*Status - ValueList of EnumRef.PlanStatuses -
// 	*BudgetProfile - CatalogRef.BudgetProfiles -
// 	*BudgetProfileDisplayParameters - Structure - 
// 	*CellData_ - ValueTable -
// 	*Key_GUID - Arbitrary -
// 	*AdditionalFiltersForAnalytics - Structure -
// 	*UseToEnterPlan - Boolean -
// 	*Details - Undefined, Map -
// 	*ItemParameterCache - Undefined, Map -
// 	*GenerationMode - EnumRef.ModesOfBudgetReportGeneration -
// 	PreviousCellData - ValueTable - Table of previous cell data:
// 	 *String - CatalogRef.FinancialReportItems - Budget line.
// 	 *Column - CatalogRef.FinancialReportItems - Column of the budget.
//
// Returns:
// 	Structure - LongDesc:
// 	*Result - Map of KeyAndValue - Contains:
// 		**Key - String - Name of the area with the value
// 		**Value - Arbitrary - value in this area
// 	*CellData_ - ValueTable -
// 	*ChangesToLinkedCells - Array of ValueTableRow - array of rows with columns:
// 		**String - CatalogRef.FinancialReportItems - Budget line.
// 		**Column - CatalogRef.FinancialReportItems - Column of the budget.
//
Function GetChangesToCells(BudgetProfile,
						BeginOfPeriod,
						EndOfPeriod,
						BudgetProfileDisplayParameters,
						DataParameters,
						PreviousCellData)
	
	CellDataTableIndexes = BudgetProfileDisplayParameters.CellDataTableIndexes;
	
	// Report Description - composition of data table columns
	ColumnStructureOfDataTable =
		BudgetProfileDisplayParameters.ColumnStructureOfDataTable; // See BudgetReportingCacheCalculationServer.ColumnsOfDataTable_
	
	// The structure of the report description contains:
	// The structure of the source cells is a table with a description of the structure of the report. in fact, the report matrix expanded into a list
	// Data sources are segments of selected articles and indicators, broken down by selection and bias.
	StructureOfReportDescription = BudgetProfileDisplayParameters.StructureOfReportDescription;
	
	// SKD by sources - a generated SKD for obtaining data according to the plan and from the actual tables.
	DataDCS = BudgetProfileDisplayParameters.DataDCS;
	
	// Output tree - a tree for the output of the report, built on the basis of the structure of the report.
	DataCache = BudgetProfileDisplayParameters.DataCache;
	
	// Getting cell data by source
	GenerationMode = Enums.ModesOfBudgetReportGeneration.Document;
	
	PeriodParameters_1 = ConvertDataParametersToPeriodData(ColumnStructureOfDataTable, DataParameters);
	
	BaseLines = Undefined;
	RowsToRecalculate_ = New Map;
	CalculationFillingTotal = Lower("Total");
	
	If Not StructureOfReportDescription.DoesNotRequireCalculationOfCellData Then
		
		// We get data from sources on the SKD
		SourceData_ = GetDataOnSources(BudgetProfile,
			DataDCS,
			DataParameters,
			StructureOfReportDescription.DataSources,
			StructureOfReportDescription.CellStructure,
			DataCache);
		
		// A table with expanded data cells goes through iterative cycles of formula calculation.
		CellData_ = CellData_(ColumnStructureOfDataTable,
			DataParameters,
			StructureOfReportDescription,
			SourceData_,
			GenerationMode,
			DataCache);
		
		If DataParameters.Property("BaseLines", BaseLines) And DataParameters.Property("OnlyCalculated") Then
			PreviousCellData.Indexes.Clear();
			PreviousCellData.Indexes.Add("CalculationFilling");
			PreviousCellData.Indexes.Add("String");
			NewCellData = PreviousCellData.Copy();
			
			TheStructureOfTheSearch = New Structure("CalculationFilling", CalculationFillingTotal);
			MoveRowOfCellsToCalculation(NewCellData, PreviousCellData, TheStructureOfTheSearch, RowsToRecalculate_);
			
			For Each ReportRow In BaseLines Do
				TheStructureOfTheSearch = New Structure("String", ReportRow);
				MoveRowOfCellsToCalculation(NewCellData, PreviousCellData, TheStructureOfTheSearch, RowsToRecalculate_);
			EndDo;
		ElsIf DataParameters.Property("BaseLines") Then
			PreviousCellData.Indexes.Clear();
			PreviousCellData.Indexes.Add("String");
			NewCellData = PreviousCellData.Copy();
			For Each ReportRow In BaseLines Do
				TheStructureOfTheSearch = New Structure("String", ReportRow);
				MoveRowOfCellsToCalculation(NewCellData, PreviousCellData, TheStructureOfTheSearch, RowsToRecalculate_);
			EndDo;
		ElsIf DataParameters.Property("OnlyCalculated") Then
			PreviousCellData.Indexes.Clear();
			PreviousCellData.Indexes.Add("CalculationFilling");
			NewCellData = PreviousCellData.Copy();
			TheStructureOfTheSearch = New Structure("CalculationFilling", CalculationFillingTotal);
			MoveRowOfCellsToCalculation(NewCellData, PreviousCellData, TheStructureOfTheSearch, RowsToRecalculate_);
		Else
			NewCellData = CellData_;
		EndIf;
		
		If DataParameters.Property("OnlyCalculated")
			Or DataParameters.Property("BaseLines") Then
			LinesToCalculate = New Array;
			For Each DataString1 In CellData_ Do
				NewRow = NewCellData.Add();
				FillPropertyValues(NewRow, DataString1);
				
				If NewRow.MainItem Then
					LinesToCalculate.Add(NewRow);
				EndIf;
			EndDo;
		Else
			LinesToCalculate = NewCellData.FindRows(New Structure("MainItem", True));
		EndIf;
		
	Else
		
		StructureOfReportDescription.CellParameters.Columns.Add("Processed", New TypeDescription("Boolean"));
		PreviousCellData.Indexes.Clear();
		PreviousCellData.Indexes.Add("RowIndex");
		PreviousCellData.Indexes.Add("MainItem, String, Column");
		AddedIndex = Undefined;
		If Not IndexExists(StructureOfReportDescription.CellParameters,
			"OperandString, OperandColumn_") Then
			AddedIndex = StructureOfReportDescription.CellParameters.Indexes.Add("OperandString, OperandColumn_");
		EndIf;
		NewCellData = PreviousCellData.Copy();
		Details = Undefined; // See NewDecryptionStructure
		LinesToCalculate = New Array;
		
		If DataParameters.Property("Details", Details) Then
			ResetCalculationFlagForLinkedCells(PreviousCellData,
				NewCellData,
				StructureOfReportDescription.CellParameters,
				Details.String,
				Details.Column,
				RowsToRecalculate_);
		Else
			For Each CellDataString In PreviousCellData Do
				If Not CellDataString.MainItem Then
					Continue;
				EndIf;
				CellParameters_ = StructureOfReportDescription.CellParameters.Find(CellDataString.RowIndex, "RowIndex");
				If CellParameters_.CalculationFilling <> "Total"
					And Not CellDataString.HierarchyOutput Then
					Continue;
				EndIf;
				RowIndex = PreviousCellData.IndexOf(CellDataString);
				NewCellData[RowIndex].CalculatedSum = False;
				NewCellData[RowIndex].CalculatedCount = False;
				NewCellData[RowIndex].CalculatedValue = False;
				RowsToRecalculate_.Insert(CellDataString);
				ResetCalculationFlagForLinkedCells(PreviousCellData,
					NewCellData,
					StructureOfReportDescription.CellParameters,
					CellDataString.String,
					CellDataString.Column,
					RowsToRecalculate_);
			EndDo;
		EndIf;
		If Not AddedIndex = Undefined Then
			StructureOfReportDescription.CellParameters.Indexes.Delete(AddedIndex);
		EndIf;
		StructureOfReportDescription.CellParameters.Columns.Delete("Processed");
		
	EndIf;
	
	CacheOfBudgetItemDetails = Undefined;
	If Not DataParameters.BudgetProfileDisplayParameters.DataCache.Property("CacheOfBudgetItemDetails", CacheOfBudgetItemDetails) Then
		CacheOfBudgetItemDetails = BudgetReportingCacheCalculationServer.CacheOfBudgetItemDetails(BudgetProfile);
		DataParameters.BudgetProfileDisplayParameters.DataCache.Insert("CacheOfBudgetItemDetails", CacheOfBudgetItemDetails);
	EndIf;
	
	ParametersForCalculatingChanges = New Structure;
	ParametersForCalculatingChanges.Insert("CellParameters", StructureOfReportDescription.CellParameters);
	ParametersForCalculatingChanges.Insert("PeriodParameters_1", PeriodParameters_1);
	ParametersForCalculatingChanges.Insert("CacheOfBudgetItemDetails", DataParameters.BudgetProfileDisplayParameters.DataCache.CacheOfBudgetItemDetails);
	ParametersForCalculatingChanges.Insert("CellDataTableIndexes", CellDataTableIndexes);
	ParametersForCalculatingChanges.Insert("NewCellData", NewCellData);
	ParametersForCalculatingChanges.Insert("PreviousCellData", PreviousCellData);
	ParametersForCalculatingChanges.Insert("LinesToCalculate", LinesToCalculate);
	ParametersForCalculatingChanges.Insert("SourceLinesToRecalculate", RowsToRecalculate_);
	
	ResultOfChanges = CalculateChangesInReport(ParametersForCalculatingChanges);
	
	If Not StructureOfReportDescription.DoesNotRequireCalculationOfCellData
		And DataParameters.Property("CellDataSortingString") Then
		NewCellData.Sort(DataParameters.CellDataSortingString);
	EndIf;
	
	ChangesTable = ResultOfChanges.ChangesTable;
	ChangesToLinkedCells = ResultOfChanges.ChangesToLinkedCells;
	
	Result = New Structure("Result, CellData_, ChangesToLinkedCells", ChangesTable, NewCellData, ChangesToLinkedCells);
	
	Return Result;
	
EndFunction

Function GetChangesToCellsRecursively(BudgetProfile, BeginOfPeriod, EndOfPeriod,
						BudgetProfileDisplayParameters, DataParameters, PreviousCellData)
	
	Result = GetChangesToCells(BudgetProfile,
			BeginOfPeriod,
			EndOfPeriod,
			BudgetProfileDisplayParameters,
			DataParameters,
			PreviousCellData);
	
	DataParameters.Insert("Object", DataParameters);
	ChangesTableTotal = Result.Result;
	CellData_ = Result.CellData_;
	ChangesToLinkedCells = Result.ChangesToLinkedCells;
	ChangesTable = ChangesTableTotal; 
	
	ScopeNames = New Map;
	ScopeNames.Insert("AreaNameSum", "Sum");
	ScopeNames.Insert("AreaNameCount", "Count");
	ScopeNames.Insert("AreaNameValue", "Value");
	
	NumberOfCellRecalculations = New Map;
	
	MaximumCellRecalculations = 0;
	Cnt = 0;
	
	While ChangesToLinkedCells.Count() > 0 Do
		
		Cnt = Cnt + 1;
		If MaximumCellRecalculations > 10 Or Cnt > 10000 Then // Protection against looping.
			ErrorText = NStr("vi = 'Vượt quá số lần cho phép khởi động thủ tục tính toán thay đổi trong ô hàng.
				|Đã ngắt thực hiện để tránh lặp lại, dữ liệu được điền theo ô hàng liên quan có thể không chính xác.';
				|ru = 'Превышено допустимое количество запусков процедуры расчета изменений в ячейках.
				|Выполнение прервано для предотвращения зацикливания, данные заполненные по связанным ячейкам могут быть некорректными.';
				|en = 'The maximum number of available starts of change calculation in bins has been exceeded.
				|Execution is aborted to prevent looping, data filled in by linked bins might be incorrect.'; fa = 'The maximum number of available starts of change calculation in bins has been exceeded.
				|Execution is aborted to prevent looping, data filled in by linked bins might be incorrect.';
				|it = 'Superata la quantità massima di avvi della procedura di calcolo delle modifiche nelle celle.
				|L''esecuzione è stata interrotta per prevenire la creazione di cicli, i dati compilati tramite le celle connesse potrebbero essere incorretti.';
				|pl = 'Przekroczono dopuszczalną ilość uruchomień procedury rozliczenia zmian w komórkach. 
				|Wykonanie jest przerwano w celu zapobiegania zapętlenia, dane wypełnione według związanych komórek mogą być niepoprawne.';
				|tr = 'Hücrelerde değiştirilen hesaplama prosedürün izin verilen giriş sayısı aşıldı.
				|Gerçekleştirme işlemi döngü önlemleri için kesintiye uğradı, bağlı hücrelere göre verilerin doldurulması yanlış olabilir.'");
			Raise ErrorText;
		EndIf;
		
		// Reflect the changed cells in the data parameters
		For Each ReflectionString In ChangesToLinkedCells Do
			For Each NameAreaIndicator In ScopeNames Do
				Area = ReflectionString[NameAreaIndicator.Key];
				If ValueIsFilled(Area) Then
					MeaningOfChanges = ChangesTable.Get(Area);
					NumberOfCellRecalculations_ = NumberOfCellRecalculations.Get(Area);
					NumberOfCellRecalculations_ = ?(NumberOfCellRecalculations_ = Undefined, 0, NumberOfCellRecalculations_) + 1;
					NumberOfCellRecalculations.Insert(Area, NumberOfCellRecalculations_);
					MaximumCellRecalculations = Max(MaximumCellRecalculations, NumberOfCellRecalculations_);
					If Not MeaningOfChanges = Undefined Then
						Details = New Structure;
						Details.Insert("Value", MeaningOfChanges);
						Details.Insert("IndicatorName", NameAreaIndicator.Value);
						Details.Insert("String", ReflectionString.String);
						Details.Insert("Column", ReflectionString.Column); 
						If ValueIsFilled(ReflectionString.BudgetFlowItem) Then
							Details.Insert("BudgetFlowItem", ReflectionString.BudgetFlowItem);
						EndIf;
						If ValueIsFilled(ReflectionString.EditedValue) Then
							Details.Insert("EditedValue",ReflectionString.EditedValue);
						EndIf;
						If ValueIsFilled(ReflectionString.Currency) Then
							Details.Insert("Currency", ReflectionString.Currency);
						EndIf;
						For Each Periodicity In Enums.Periodicity Do
							PeriodAsString = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
							If Not CellData_.Columns.Find(PeriodAsString) = Undefined And ValueIsFilled(ReflectionString[PeriodAsString]) Then
								Details.Insert(PeriodAsString, ReflectionString[PeriodAsString]);	
							EndIf;
						EndDo;
						MatchingAnalystValues = New Map;
						For Each DimensionKind In BudgetProfileDisplayParameters.ColumnStructureOfDataTable.DimensionKinds Do
							NameKey = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
							Value = BudgetingClientServer.EmptyDimensionValue();
							If Not CellData_.Columns.Find(NameKey) = Undefined And ValueIsFilled(ReflectionString[NameKey]) Then
								Value = ReflectionString[NameKey];
							EndIf;
							ValueType = FinancialReportingCached.TypeOfAnalyticsTypeValue(NameKey, DimensionKind);
							Value = BudgetingClientServer.ReducedAnalyticsValue(Value, ValueType);
							MatchingAnalystValues.Insert(DimensionKind, Value);
						EndDo;
						Details.Insert("AnalystValues", MatchingAnalystValues); 
						
						BudgetReportingClientServer.ReflectCellChange(DataParameters, Details, MeaningOfChanges);
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	
		Result = GetChangesToCells(BudgetProfile,
				BeginOfPeriod,
				EndOfPeriod,
				BudgetProfileDisplayParameters,
				DataParameters,
				CellData_);
		
		ChangesTable = Result.Result;
		For Each KeyAndValue In ChangesTable Do
			ChangesTableTotal.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
		CellData_ = Result.CellData_;
		ChangesToLinkedCells = Result.ChangesToLinkedCells;
	
	EndDo;
	
	ChangesTable = New ValueTable;
	ChangesTable.Columns.Add("AreaName");
	ChangesTable.Columns.Add("Value");
	
	For Each KeyValue In ChangesTableTotal Do
		NewRow = ChangesTable.Add();
		NewRow.AreaName = KeyValue.Key;
		NewRow.Value = KeyValue.Value;
	EndDo;
	
	Result = New Structure("Result, CellData_", ChangesTable, CellData_);
	
	Return Result;
	
EndFunction

#EndRegion

#Region GettingDataBySource

Procedure GetCustomizableSelectionItems(Filter, List, Name) Export
	
	For Each FilterElement In Filter.Items Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			
			GetCustomizableSelectionItems(FilterElement, List, Name);
			Continue;
			
		EndIf;
		
		If StrFind(Lower(FilterElement.RightValue), Lower("<fill"))
			And StrFind(Lower(FilterElement.LeftValue), Name) Then
			
			List.Add(FilterElement);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure GetNonCustomizableSelectionItems(Filter, List, Name) Export
	
	For Each FilterElement In Filter.Items Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			
			GetNonCustomizableSelectionItems(FilterElement, List, Name);
			Continue;
			
		EndIf;
		
		If StrFind(FilterElement.RightValue, "<fill") = 0
			And StrFind(Lower(FilterElement.LeftValue), Name) Then
			
			List.Add(FilterElement);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Complements the configuration of SKD.
// 
// Parameters:
// 	Settings - DataCompositionSettings -
// 	DataParameters - See DataSourcesServer.TemplateForGettingFactParameters
Procedure AddDCSSettingsBeforeOutput(Settings, DataParameters) Export
	Value = Undefined;
	
	Structure = Common.CopyRecursive(DataParameters.AdditionalFiltersForAnalytics);
	Structure.Insert("Organization");
	Structure.Insert("Scenario");
	Structure.Insert("Department");
	Structure.Insert("StorageCurrency");
	
	For Each KeyAndValue In Structure Do
		
		Used = DataParameters.Property(KeyAndValue.Key, Value);
		If Used Then
			If KeyAndValue.Key = "Department" Then
				If TypeOf(Value) = Type("ValueList") Then
					TypeOfSelectionComparison = DataCompositionComparisonType.InListByHierarchy;
				Else
					TypeOfSelectionComparison = DataCompositionComparisonType.InHierarchy;
				EndIf;
			Else
				If TypeOf(Value) = Type("ValueList") Then
					TypeOfSelectionComparison = DataCompositionComparisonType.InList;
				Else
					TypeOfSelectionComparison = DataCompositionComparisonType.Equal;
				EndIf;
			EndIf;
		EndIf;
		
		Filters = New Array;
		GetCustomizableSelectionItems(Settings.Filter, Filters, Lower(KeyAndValue.Key));
		If KeyAndValue.Key = "Organization"
			Or KeyAndValue.Key = "Scenario"
			Or KeyAndValue.Key = "Department"
			Or KeyAndValue.Key = "StorageCurrency" Then
			NonCustomizableSelections = New Array;
		Else
			NonCustomizableSelections = New Array;
			GetNonCustomizableSelectionItems(Settings.Filter, NonCustomizableSelections, Lower(KeyAndValue.Key));
		EndIf;
		For Each FilterElement In Filters Do
			FilterElement.Use = Used;
			If Used Then
				SimilarElement = SimilarElementOfSelection(NonCustomizableSelections,
					FilterElement.LeftValue,
					FilterElement.Parent,
					TypeOfSelectionComparison,
					Value);
				
				If SimilarElement = Undefined Then
					FilterElement.RightValue = Value;
					FilterElement.ComparisonType = TypeOfSelectionComparison;
				Else
					If FilterElement.Parent = Undefined Then
						ParentElementsSelections = Settings.Filter.Items;
					Else
						SelectionElementParent = FilterElement.Parent; // DataCompositionFilterItemGroup -
						ParentElementsSelections = SelectionElementParent.Items;
					EndIf;
					ParentElementsSelections.Delete(FilterElement);
				EndIf;
			EndIf;
		EndDo;
		
		If KeyAndValue.Key = "Organization"
			Or KeyAndValue.Key = "Scenario"
			Or KeyAndValue.Key = "Department"
			Or KeyAndValue.Key = "StorageCurrency" Then
			Continue;
		EndIf;
		
		If Used Then
			NonCustomizableSelections = New Array;
			GetNonCustomizableSelectionItems(Settings.Filter, NonCustomizableSelections, Lower(KeyAndValue.Key));
			For Each FilterElement In NonCustomizableSelections Do
				SimilarElement = SimilarElementOfSelection(NonCustomizableSelections,
					FilterElement.LeftValue,
					FilterElement.Parent,
					TypeOfSelectionComparison,
					Value);
					
				If SimilarElement <> Undefined Then
					Continue;
				EndIf;
				
				If FilterElement.Parent = Undefined Then
					NewElementOfSelection = Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
				Else
					SelectionElementParent = FilterElement.Parent; // DataCompositionFilterItemGroup -
					NewElementOfSelection = SelectionElementParent.Items.Add(Type("DataCompositionFilterItem"));
				EndIf;
				NewElementOfSelection.LeftValue = FilterElement.LeftValue;
				NewElementOfSelection.Use = True;
				NewElementOfSelection.ComparisonType = TypeOfSelectionComparison;
				NewElementOfSelection.RightValue = Value;
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

// Complements the configuration of SKD.
// 
// Parameters:
// 	Settings - DataCompositionSettings -
// 	DataParameters - See DataSourcesServer.TemplateForGettingFactParameters
// 	ExcludeScenario - Boolean - Script exception flag.
Procedure AddDCSSettingsBeforeDisplayingAlternative(Settings, DataParameters, ExcludeScenario = False) Export
	
	Structure = New Structure;
	
	CommonClientServer.SupplementStructure(Structure, DataParameters.AdditionalFiltersForMeasurements, True);
	CommonClientServer.SupplementStructure(Structure, DataParameters.AdditionalFiltersForAnalytics, True);
	
	If ExcludeScenario Then
		Structure.Insert("Scenario", Undefined);
	EndIf;
		
	For Each KeyAndValue In Structure Do
		
		Used = (Not KeyAndValue.Value = Undefined);
		If Used Then
			If KeyAndValue.Key = "Department" Then
				If TypeOf(KeyAndValue.Value) = Type("ValueList") Then
					TypeOfSelectionComparison = DataCompositionComparisonType.InListByHierarchy;
				Else
					TypeOfSelectionComparison = DataCompositionComparisonType.InHierarchy;
				EndIf;
			Else
				If TypeOf(KeyAndValue.Value) = Type("ValueList") Then
					TypeOfSelectionComparison = DataCompositionComparisonType.InList;
				Else
					TypeOfSelectionComparison = DataCompositionComparisonType.Equal;
				EndIf;
			EndIf;
		EndIf;
		
		Filters = New Array;
		GetCustomizableSelectionItems(Settings.Filter, Filters, Lower(KeyAndValue.Key));
		For Each FilterElement In Filters Do
			FilterElement.Use = Used;
			If Used Then
				FilterElement.RightValue = KeyAndValue.Value;
				FilterElement.ComparisonType = TypeOfSelectionComparison;
			EndIf;
		EndDo;
		
		If KeyAndValue.Key = "Organization"
			Or KeyAndValue.Key = "Scenario"
			Or KeyAndValue.Key = "Department"
			Or KeyAndValue.Key = "StorageCurrency" Then
			Continue;
		EndIf;
		
		If Used Then
			NonCustomizableSelections = New Array;
			GetNonCustomizableSelectionItems(Settings.Filter, NonCustomizableSelections, Lower(KeyAndValue.Key));
			For Each FilterElement In NonCustomizableSelections Do
				SimilarElement = SimilarElementOfSelection(NonCustomizableSelections,
					FilterElement.LeftValue,
					FilterElement.Parent,
					TypeOfSelectionComparison,
					KeyAndValue.Value);
				
				If SimilarElement <> Undefined Then
					Continue;
				EndIf;
				
				If FilterElement.Parent = Undefined Then
					NewElementOfSelection = Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
				Else
					SelectionElementParent = FilterElement.Parent; // DataCompositionFilterItemGroup -
					NewElementOfSelection = SelectionElementParent.Items.Add(Type("DataCompositionFilterItem"));
				EndIf;
				NewElementOfSelection.LeftValue = FilterElement.LeftValue;
				NewElementOfSelection.Use = True;
				NewElementOfSelection.ComparisonType = TypeOfSelectionComparison;
				NewElementOfSelection.RightValue = KeyAndValue.Value;
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

Function SimilarElementOfSelection(ArrayOfItemsToSearch, LeftValue, Parent, TypeOfSelectionComparison, RightValue)
	
	SimilarElementOfSelection = Undefined;
	
	For Each VerificationSelectionElement In ArrayOfItemsToSearch Do
		If VerificationSelectionElement.LeftValue = LeftValue
			And VerificationSelectionElement.Parent = Parent
			And VerificationSelectionElement.Use = True
			And VerificationSelectionElement.ComparisonType = TypeOfSelectionComparison
			And SelectionValuesAreEqual(VerificationSelectionElement.RightValue, RightValue) Then
			SimilarElementOfSelection = VerificationSelectionElement;
			Break;
		EndIf;
	EndDo;
	
	Return SimilarElementOfSelection;
	
EndFunction

Function SelectionValuesAreEqual(FilterValue, SignificanceOfComparisonSelection)
	ValuesAreEqual = True;
	
	ValueTypeFilter = TypeOf(FilterValue);
	If ValueTypeFilter = TypeOf(SignificanceOfComparisonSelection) Then
		If ValueTypeFilter = Type("Array") Then
			If FilterValue.Count()
					<> SignificanceOfComparisonSelection.Count() Then
				ValuesAreEqual = False;
			Else
				ElementIndex = 0;
				For ElementIndex = 0 To FilterValue.Count() - 1 Do
					If FilterValue[ElementIndex] <> SignificanceOfComparisonSelection[ElementIndex] Then
						ValuesAreEqual = False;
						Break;
					EndIf;
					ElementIndex = ElementIndex + 1;
				EndDo;
			EndIf;
		ElsIf ValueTypeFilter = Type("ValueList") Then
			If FilterValue.Count()
					<> SignificanceOfComparisonSelection.Count() Then
				ValuesAreEqual = False;
			Else
				ElementIndex = 0;
				For ElementIndex = 0 To FilterValue.Count() - 1 Do
					Value1 = FilterValue.Get(ElementIndex).Value;
					Value2 = SignificanceOfComparisonSelection.Get(ElementIndex).Value;
					If Value1 <> Value2 Then
						ValuesAreEqual = False;
						Break;
					EndIf;
					ElementIndex = ElementIndex + 1;
				EndDo;
			EndIf;
		Else
			ValuesAreEqual = (FilterValue = SignificanceOfComparisonSelection);
		EndIf;
	Else
		ValuesAreEqual = False;
	EndIf;
	
	Return ValuesAreEqual;
EndFunction

Function GetDataOnSources(BudgetProfile, DataDCS, DataParameters, DataSources, CellStructure, DataCache)
	
	FinReports = FinancialReportingServer;
	
	BeginOfPeriod = DataParameters.BeginOfPeriod;
	EndOfPeriod = DataParameters.EndOfPeriod;
	ActualDataLimit = DataParameters.ActualDataLimit;
	
	TempTablesManager = Undefined;
	If Not IsBlankString(DataParameters.QueryTextDocumentTables) Then
		TempTablesManager = New TempTablesManager;
		Query = New Query(DataParameters.QueryTextDocumentTables);
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("BudgetFlowItemsDimension", DataParameters.BudgetFlowItemsDimension);
		Query.SetParameter("BudgetFlowItemTurnovers", DataParameters.BudgetFlowItemTurnovers);
		Query.SetParameter("DimensionValues_", DataParameters.DimensionValues_);
		Query.Execute();
	EndIf;
	
	ExternalSets = New Structure;
	
	If DataCache.Property("FunctionalCurrency") Then
		FunctionalCurrency = DataCache.FunctionalCurrency;
	Else
		FunctionalCurrency = Common.ObjectAttributeValue(BudgetProfile, "Owner.FunctionalCurrency");
		DataCache.Insert("FunctionalCurrency", FunctionalCurrency);
	EndIf;
	
	If DataCache.Property("CacheAnalystValues") Then
		CacheAnalystValues = DataCache.CacheAnalystValues;
	Else
		CacheAnalystValues = New Map;
		DataCache.Insert("CacheAnalystValues", CacheAnalystValues);
	EndIf;
	
	If Not DataCache.Property("CacheOfBudgetItemDetails") Then
		CacheOfBudgetItemDetails = BudgetReportingCacheCalculationServer.CacheOfBudgetItemDetails(BudgetProfile);
		DataCache.Insert("CacheOfBudgetItemDetails", CacheOfBudgetItemDetails);
	EndIf;
	
	If DataCache.Property("CacheOfScheduledCourses") Then
		
		CacheOfScheduledCourses = DataCache.CacheOfScheduledCourses;
		
	Else
		
		CacheOfScheduledCourses = Catalogs.BudgetingScenarios.ScenarioCourseTable(,,BeginOfPeriod, EndOfPeriod);
		CacheOfScheduledCourses.Sort("Currency, Scenario, Period");
		CacheOfScheduledCourses.Indexes.Add("Currency, Scenario, Period");
		CacheOfScheduledCourses.Indexes.Add("Currency, Scenario");
		
		DataCache.Insert("CacheOfScheduledCourses", CacheOfScheduledCourses);
		
	EndIf;
	
	RequestsForPlannedBalances = New Map;
	RequestTemplateForPlannedBalances =
		"SELECT ALLOWED TOP 1
		|	&Id AS Id
		|FROM
		|	InformationRegister.OpeningBalanceOfEstimates AS OpeningBalanceOfEstimates
		|WHERE
		|	OpeningBalanceOfEstimates.DateOfRemainingGoods = &BeginOfPeriod
		|	AND OpeningBalanceOfEstimates.BudgetBalanceItem IN(&SelectedBudgetIndicatorsIDNumber)";
	
	For Each DataSource In DataSources Do
		If DataSource.SourceType = Enums.BudgetingDataSourceTypes.Balance Then
			QueryTextBasedOnPlannedBalances = StrReplace(RequestTemplateForPlannedBalances, "IDNumber", DataSource.Id);
			QueryTextBasedOnPlannedBalances = StrReplace(QueryTextBasedOnPlannedBalances, "&Id", """" + DataSource.Id + """");
			RequestsForPlannedBalances.Insert(DataSource.Id, QueryTextBasedOnPlannedBalances);
		EndIf;
	EndDo;
	
	// 1 - Planned data
	// 2 - Plan data is privileged
	For IterationNumber = 1 To 2 Do
		
		DataKey = ?(IterationNumber = 1, "ScheduledData", "PlanDataPrivileged");
		NameOfDataDCS = ?(IterationNumber = 1, "DCSPlanningData", "DCSPlanningDataPrivileged");
		
		DCSPlanningData = Undefined;
		
		If DataCache.Property(DataKey) Then
			
			ScheduledData = DataCache[DataKey];
			
		ElsIf DataDCS.Property(NameOfDataDCS, DCSPlanningData)
			And TypeOf(DCSPlanningData) = Type("DataCompositionSchema")
			And DCSPlanningData.DataSets[0].Items.Count() Then
			
			If IterationNumber = 2 Then
				SetPrivilegedMode(True);
			EndIf;
			
			Composer = FinReports.SchemaComposer(DCSPlanningData);
			
			AddDCSSettingsBeforeOutput(Composer.Settings, DataParameters);
			
			For Each KeyAndValue In DataDCS.Parameters Do
				FinReports.SetLayoutParameter(Composer, KeyAndValue.Key, KeyAndValue.Value);
			EndDo;
			
			If DataParameters.Property("Document") Then
				FinReports.SetLayoutParameter(Composer, "Document", DataParameters.Document);
			EndIf;
			If DataParameters.Property("Action") Then
				FinReports.SetLayoutParameter(Composer, "Action", DataParameters.Action);
			EndIf;
			
			FinReports.SetLayoutParameter(Composer, "UpdateDate", DataParameters.UpdateDate);
			FinReports.SetLayoutParameter(Composer, "ActualDataLimit", ActualDataLimit);
			
			FinReports.SetLayoutParameter(Composer, "CacheAnalystValues", CacheAnalystValues);
			FinReports.SetLayoutParameter(Composer, "CacheOfScheduledCourses", CacheOfScheduledCourses);
			FinReports.SetLayoutParameter(Composer, "BeginOfPeriod", BeginOfPeriod);
			FinReports.SetLayoutParameter(Composer, "EndOfPeriod", EndOfPeriod);
			
			If DataParameters.Property("Status") Then
				FinReports.SetFilter(Composer.Settings.Filter, "Status", DataParameters.Status, DataCompositionComparisonType.InList);
			EndIf;
			
			If RequestsForPlannedBalances.Count() Then
				RequestForPlannedBalances = New Query;
				RequestForPlannedBalances.SetParameter("BeginOfPeriod", BeginOfPeriod);
				For Each KeyAndValue In RequestsForPlannedBalances Do
					If IsBlankString(RequestForPlannedBalances.Text) Then
						RequestForPlannedBalances.Text = KeyAndValue.Value;
					Else
						RequestForPlannedBalances.Text = RequestForPlannedBalances.Text +
						TMCommonUse.QuerySeparatorInJoin() + StrReplace(KeyAndValue.Value, "ALLOWED", "");
					EndIf;
					NameOfBudgetMetricsParameter = "SelectedBudgetIndicators" + KeyAndValue.Key;
					RequestForPlannedBalances.SetParameter(NameOfBudgetMetricsParameter,
						DataDCS.Parameters[NameOfBudgetMetricsParameter]);
				EndDo;
				//@skip-check query-in-loop
				Result = RequestForPlannedBalances.Execute();
				If Result.IsEmpty() Then
					IdsWithPlannedBalances = New Array;
				Else
					IdsWithPlannedBalances = Result.Unload().UnloadColumn("Id");
				EndIf;
				For Each KeyAndValue In RequestsForPlannedBalances Do
					If IdsWithPlannedBalances.Find(KeyAndValue.Key) = Undefined Then
						DatasetOpeningBalances = DCSPlanningData.DataSets[0].Items.Find(
							"Set_Plan_OpeningBalances_" + KeyAndValue.Key);
						If DatasetOpeningBalances <> Undefined Then
							DCSPlanningData.DataSets[0].Items.Delete(DatasetOpeningBalances);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			
			ScheduledData = FinReports.UploadDCSResults(DCSPlanningData, Composer);
			
			RecalculationFields = New Array;
			If ScheduledData.Columns.Find("SumCurrReceipt") <> Undefined Then
				RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
					"SumCurrReceipt", "SumReceipt", "SumReceipt", "SumCurrReceipt"));
			EndIf;
			If ScheduledData.Columns.Find("SumCurrExpense") <> Undefined Then
				RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
					"SumCurrExpense", "SumExpense", "SumExpense", "SumCurrExpense"));
			EndIf;
			If ScheduledData.Columns.Find("SumCurrOpeningBalance") <> Undefined Then
				RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
					"SumCurrOpeningBalance", "SumOpeningBalance", "SumOpeningBalance", "SumCurrOpeningBalance"));
			EndIf;
			
			If RecalculationFields.Count() Then
				DataTableParameters = BudgetingServer.ParametersForConvertingDataTableToCurrency(ScheduledData);
				BudgetingServer.ConvertDataTableToCurrency(DataTableParameters, DataParameters.ReportCurrency,
					FunctionalCurrency, RecalculationFields);
				ScheduledData = DataTableParameters.DataTable;
			EndIf;
			
			DataCache.Insert(DataKey, ScheduledData);
		
			If IterationNumber = 2 Then
				SetPrivilegedMode(False);
			EndIf;
		
		Else
			
			ScheduledData = New ValueTable;
			
		EndIf;
		
		ExternalSets.Insert(DataKey, ScheduledData);
	
	EndDo;
	
	DCSDocumentData = Undefined;
	
	If DataDCS.Property("DCSDocumentData", DCSDocumentData) And DCSDocumentData <> Undefined Then
		
		#Region PreparingCachesForDocumentData
		
		If TempTablesManager.Tables.Find("RelationshipSettings") = Undefined Then
			
			CalculationsRules = New Array;
			For Counter = 0 To DataSources.UBound() Do
				CommonClientServer.SupplementArray(CalculationsRules, DataSources[Counter].CalculationsRules, True);
			EndDo;
			MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
			QueryText =
			"SELECT DISTINCT
			|	CalculationsRules.Source AS BudgetFlowItem,
			|	CalculationsRules.Receiver AS BudgetBalanceItem,
			|	&TextTypesOfMetricsAnalytics,
			|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).NumberOfUsedDimensions AS IndicatorNumberOfAnalyticsUsed,
			|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).RecordByCurrency AS RecordByCurrency,
			|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).CurrencyIsDeterminedByDimension AS CurrencyIsDeterminedByDimension,
			|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).DimensionAddressCurrency AS DimensionAddressCurrency,
			|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).DimensionCurrencies.CurrencyFilling AS CurrencyPopulationSource,
			|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).RecordByQuantity AS IndicatorIsTakenIntoAccountByQuantity,
			|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).UnitOfMeasureIsDeterminedByDimension AS IndicatorUnitOfMeasurementIsDeterminedByAnalytics,
			|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).QuantityDimensionAddress AS AnalyticsAddressQuantityIndicator,
			|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).DimensionUnitsOfMeasurement.UnitOfMeasureFilling AS IndicatorSourceFillingInUnitOfMeasurement,
			|	CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).UnitOfMeasure AS IndicatorUnitOfMeasurement
			|INTO RelationshipSettings
			|FROM
			|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
			|WHERE
			|	CalculationsRules.Ref IN (&CalculationsRules)";
			TextTypesOfMetricsAnalytics = "";
			
			For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
				
				TextTypesOfMetricsAnalytics = TextTypesOfMetricsAnalytics + ?(TextTypesOfMetricsAnalytics = "", "", "," + Chars.LF + Chars.Tab)
					+ StringFunctionsClientServer.SubstituteParametersToString(
						"CAST(CalculationsRules.Receiver AS Catalog.BudgetBalanceItems).DimensionKind%1 AS IndicatorTypeOfAnalytics%1",
						DimensionNumber);
				
			EndDo;
			
			Query = New Query;
			QueryText = StrReplace(QueryText, "&TextTypesOfMetricsAnalytics", TextTypesOfMetricsAnalytics);
			Query.TempTablesManager = TempTablesManager;
			Query.Text = QueryText;
			Query.SetParameter("CalculationsRules", CalculationsRules);
			
			SetPrivilegedMode(True);
			Query.Execute();
			SetPrivilegedMode(False);
			
		EndIf;
		
		If TempTablesManager.Tables.Find("ItemParameterCache") = Undefined Then
			
			MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
			TextOfArticleAnalyst = "";
			IndicatorAnalystText = "";
			For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
				TextOfArticleAnalyst = TextOfArticleAnalyst + ?(TextOfArticleAnalyst = "", "", "," + Chars.LF + Chars.Tab)
					+ StringFunctionsClientServer.SubstituteParametersToString(
						"BudgetFlowItems.DimensionKind%1 AS DimensionKind%1",
						DimensionNumber);
				
				IndicatorAnalystText = IndicatorAnalystText + ?(IndicatorAnalystText = "", "", "," + Chars.LF + Chars.Tab)
					+ StringFunctionsClientServer.SubstituteParametersToString(
						"BudgetBalanceItems.DimensionKind%1",
						DimensionNumber);
			EndDo;
			QueryText =
			"SELECT
			|	BudgetFlowItems.Ref AS BudgetFlowItem,
			|	BudgetFlowItems.NumberOfUsedDimensions AS NumberOfUsedDimensions,
			|	&TextOfArticleAnalyst,
			|	BudgetFlowItems.RecordByQuantity AS Article2ByQuantity,
			|	BudgetFlowItems.UnitOfMeasureIsDeterminedByDimension AS ArticleUnitOfMeasurementIsDeterminedByAnalytics,
			|	BudgetFlowItems.QuantityDimensionAddress AS ArticleAddressAndQuantity,
			|	BudgetFlowItems.DimensionUnitsOfMeasurement.UnitOfMeasureFilling AS ArticleSourceFillingInUnitOfMeasurement,
			|	BudgetFlowItems.UnitOfMeasure AS ArticleUnitOfMeasurement
			|INTO ItemParameterCache
			|FROM
			|	Catalog.BudgetFlowItems AS BudgetFlowItems
			|WHERE
			|	&SelectionOfArticles
			|
			|UNION ALL
			|
			|SELECT
			|	BudgetBalanceItems.Ref,
			|	BudgetBalanceItems.NumberOfUsedDimensions,
			|	&IndicatorAnalystText,
			|	BudgetBalanceItems.RecordByQuantity,
			|	BudgetBalanceItems.UnitOfMeasureIsDeterminedByDimension,
			|	BudgetBalanceItems.QuantityDimensionAddress,
			|	BudgetBalanceItems.DimensionUnitsOfMeasurement.UnitOfMeasureFilling,
			|	BudgetBalanceItems.UnitOfMeasure
			|FROM
			|	Catalog.BudgetBalanceItems AS BudgetBalanceItems
			|WHERE
			|	IndicatorType = &IndicatorType
			|	AND &SelectingIndicators
			|";
			QueryText = StrReplace(QueryText, "&TextOfArticleAnalyst", TextOfArticleAnalyst);
			QueryText = StrReplace(QueryText, "&IndicatorAnalystText", IndicatorAnalystText);
			Query.Text = QueryText;
			Query.TempTablesManager = TempTablesManager;
			
			TheStructureOfTheSearch = New Structure("ItemKind", Enums.FinancialReportItemKinds.BudgetFlowItem);
			BudgetItems = CellStructure.Copy(TheStructureOfTheSearch).UnloadColumn("BudgetFlowItem");
			BudgetItems = CommonClientServer.CollapseArray(BudgetItems);
			
			ThereIsEmptyValue = False;
			For Each BudgetFlowItem In BudgetItems Do
				If Not ValueIsFilled(BudgetFlowItem) Then
					ThereIsEmptyValue = True;
					Break;
				EndIf;
			EndDo;
			
			If Not ThereIsEmptyValue Then
				Query.Text = StrReplace(Query.Text, "&SelectionOfArticles", "Ref IN (&ListOfArticles)");
				Query.Text = StrReplace(Query.Text, "&SelectingIndicators", "Ref IN (&ListOfArticles)");
				ListOfArticles = New ValueList;
				ListOfArticles.LoadValues(BudgetItems);
				Query.SetParameter("ListOfArticles", ListOfArticles);
			Else
				Query.Text = StrReplace(Query.Text, "&SelectionOfArticles", "TRUE");
				Query.Text = StrReplace(Query.Text, "&SelectingIndicators", "TRUE");
			EndIf;
			
			Query.SetParameter("IndicatorType", Enums.BudgetBalanceItemType.SpecialPurpose);
			SetPrivilegedMode(True);
			Query.Execute();
			SetPrivilegedMode(False);
			
		EndIf;
		
		#EndRegion
		
		For Each KeyAndValue In DCSDocumentData Do
			
			If DataCache.Property(KeyAndValue.Key) Then
				
				CompositionTemplate = DataCache[KeyAndValue.Key];
				
			Else
				
				Composer = FinReports.SchemaComposer(KeyAndValue.Value);
				
				AddDCSSettingsBeforeOutput(Composer.Settings, DataParameters);
				
				For Each Parameter In DataDCS.Parameters Do
					FinReports.SetLayoutParameter(Composer, Parameter.Key, Parameter.Value);
				EndDo;
				
				Value = Undefined;
				If DataParameters.Property("Organization", Value) Then
					FinReports.SetLayoutParameter(Composer, "Document_Organization", Value);
				EndIf;
				If DataParameters.Property("Department", Value) Then
					FinReports.SetLayoutParameter(Composer, "Document_Department", Value);
				EndIf;
				For Each FieldToEval In DataParameters.AdditionalFiltersForAnalytics Do
					FinReports.SetLayoutParameter(Composer, "Document_" + FieldToEval.Key, DataParameters[FieldToEval.Key]);
				EndDo;
				
				FinReports.SetLayoutParameter(Composer, "Document_Currency",      DataParameters.Currency);
				FinReports.SetLayoutParameter(Composer, "Document_Scenario",    DataParameters.Scenario);
				FinReports.SetLayoutParameter(Composer, "BeginOfPeriod",        BeginOfPeriod);
				FinReports.SetLayoutParameter(Composer, "EndOfPeriod",         EndOfPeriod);
				FinReports.SetLayoutParameter(Composer, "ActualDataLimit",    ActualDataLimit);
				FinReports.SetLayoutParameter(Composer, "Status",               DataParameters.Status);
				
				FinReports.SetLayoutParameter(Composer, "CacheAnalystValues",  CacheAnalystValues);
				FinReports.SetLayoutParameter(Composer, "CacheOfScheduledCourses",    CacheOfScheduledCourses);
				
				CompositionTemplate = FinReports.PrepareLayoutTemplateForUploadingDCS(KeyAndValue.Value, Composer);
				
				// If, after executing the set builder, the number of sets has decreased, then
				// we assume that there is no access to one of the sets of the layout scheme.
				If KeyAndValue.Value.DataSets.Count() > CompositionTemplate.DataSets.Count() Then
					Raise NStr("vi = 'Vi phạm quyền truy cập.';
								|ru = 'Нарушение прав доступа.';
								|en = 'Access violation.'; fa = 'Access violation.';
								|it = 'Violazione dei diritti di accesso.';
								|pl = 'Naruszenie praw dostępu.';
								|tr = 'Erişim hakkı ihlali.'");
				EndIf;
				
				DataCache.Insert(KeyAndValue.Key, CompositionTemplate);
				
			EndIf;
			
			DocumentTableData = FinReports.UploadDCSResultsFromTemplate(CompositionTemplate, , , TempTablesManager);
			DocumentTableData.Columns.Add("AlwaysOutputFlag", Common.TypeDescriptionNumber(1));
			DocumentTableData.FillValues(1, "AlwaysOutputFlag");
			ExternalSets.Insert(KeyAndValue.Key, DocumentTableData);
			
		EndDo;
		
	EndIf;
	
	If DataCache.Property("ActualData") Then
		ActualData = DataCache.ActualData;
	Else
		Currency = DataParameters.ReportCurrency;
		DataReceiptMode = Common.ObjectAttributeValue(BudgetProfile, "DataReceiptMode");
		If Not ValueIsFilled(DataReceiptMode) Then
			DataReceiptMode = Enums.BudgetingDataReceiptMode.Allowed;
		EndIf;
		ActualData = BudgetingServer.FactByBudgetType(DataParameters, DataSources, Currency, DataReceiptMode);
		DataCache.Insert("ActualData", ActualData);
	EndIf;
	
	ExternalSets.Insert("ActualData", ActualData);
	
	// 1 - Stored actual data
	// 2 - Stored actual data privileged
	For IterationNumber = 1 To 2 Do
		
		DataKey = ?(IterationNumber = 1, "StoredActualData", "StoredActualDataPrivileged");
		NameOfDataDCS = ?(IterationNumber = 1, "DCSActualData", "DCSActualDataPrivileged");
		
		DCSActualData = Undefined;
		
		If DataCache.Property(DataKey) Then
			
			StoredActualData = DataCache[DataKey];
			
		ElsIf DataDCS.Property(NameOfDataDCS, DCSActualData)
			And TypeOf(DCSActualData) = Type("DataCompositionSchema")
			And DCSActualData.DataSets[0].Items.Count() Then
			
			If IterationNumber = 2 Then
				SetPrivilegedMode(True);
			EndIf;
			
			Composer = FinReports.SchemaComposer(DCSActualData);
			
			AddDCSSettingsBeforeOutput(Composer.Settings, DataParameters);
			
			For Each KeyAndValue In DataDCS.Parameters Do
				FinReports.SetLayoutParameter(Composer, KeyAndValue.Key, KeyAndValue.Value);
			EndDo;
			
			FinReports.SetLayoutParameter(Composer, "UpdateDate", DataParameters.UpdateDate);
			FinReports.SetLayoutParameter(Composer, "ActualDataLimit", ActualDataLimit);
			
			FinReports.SetLayoutParameter(Composer, "CacheAnalystValues", CacheAnalystValues);
			FinReports.SetLayoutParameter(Composer, "BeginOfPeriod", BeginOfPeriod);
			FinReports.SetLayoutParameter(Composer, "EndOfPeriod", EndOfPeriod);
			
			StoredActualData = FinReports.UploadDCSResults(DCSActualData, Composer);
			
			RecalculationFields = New Array;
			If StoredActualData.Columns.Find("SumCurrReceipt") <> Undefined Then
				RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
					"SumCurrReceipt", "SumReceipt", "SumReceipt", "SumCurrReceipt"));
			EndIf;
			If StoredActualData.Columns.Find("SumCurrExpense") <> Undefined Then
				RecalculationFields.Add(New Structure("RecalculationField, FunctionalCurrencyField, OutputDataField, OutputDataFieldInCurrency",
					"SumCurrExpense", "SumExpense", "SumExpense", "SumCurrExpense"));
			EndIf;
			
			If RecalculationFields.Count() Then
				DataTableParameters = BudgetingServer.ParametersForConvertingDataTableToCurrency(StoredActualData);
				BudgetingServer.ConvertDataTableToCurrency(DataTableParameters, DataParameters.ReportCurrency,
					FunctionalCurrency, RecalculationFields);
				StoredActualData = DataTableParameters.DataTable;
			EndIf;
			
			DataCache.Insert(DataKey, StoredActualData);
		
			If IterationNumber = 2 Then
				SetPrivilegedMode(False);
			EndIf;
			
		Else
			
			StoredActualData = New ValueTable;
			
		EndIf;
		
		ExternalSets.Insert(DataKey, StoredActualData);
	
	EndDo;
	
	If DataCache.Property("PreliminaryDCSTemplate") Then
		PreliminaryDCSTemplate = DataCache.PreliminaryDCSTemplate;
	Else
		DCSPreliminary = DataDCS.DCSPreliminaryCalculation;
		If DCSPreliminary <> Undefined Then
			Composer = FinReports.SchemaComposer(DCSPreliminary);
			FinReports.SetLayoutParameter(Composer, "BeginOfPeriod", BeginOfPeriod);
			FinReports.SetLayoutParameter(Composer, "EndOfPeriod", EndOfPeriod);
			PreliminaryDCSTemplate = FinReports.PrepareLayoutTemplateForUploadingDCS(DCSPreliminary, Composer);
			
			// If, after executing the set builder, the number of sets has decreased, then
			// we assume that there is no access to one of the sets of the layout scheme.
			If DCSPreliminary.DataSets.Count() > PreliminaryDCSTemplate.DataSets.Count() Then
				Raise NStr("vi = 'Vi phạm quyền truy cập.';
							|ru = 'Нарушение прав доступа.';
							|en = 'Access violation.'; fa = 'Access violation.';
							|it = 'Violazione dei diritti di accesso.';
							|pl = 'Naruszenie praw dostępu.';
							|tr = 'Erişim hakkı ihlali.'"); 
			EndIf;
				
			DataCache.Insert("PreliminaryDCSTemplate", PreliminaryDCSTemplate);
		EndIf;
	EndIf;
	
	If PreliminaryDCSTemplate <> Undefined Then
		TableOfPreliminaryResults = FinReports.UploadDCSResultsFromTemplate(PreliminaryDCSTemplate, ExternalSets, ,
			TempTablesManager);
		ExternalSets.Insert("PreliminaryCalculation", TableOfPreliminaryResults);
	EndIf;
	
	If DataCache.Property("FinalDCSTemplate") Then
		FinalDCSTemplate = DataCache.FinalDCSTemplate;
	Else
		DCSSummary = DataDCS.DCSSummary;
		Composer = FinReports.SchemaComposer(DCSSummary);
		FinReports.SetLayoutParameter(Composer, "BeginOfPeriod", BeginOfPeriod);
		FinReports.SetLayoutParameter(Composer, "EndOfPeriod", EndOfPeriod);
		FinalDCSTemplate = FinReports.PrepareLayoutTemplateForUploadingDCS(DCSSummary, Composer);
		
		// If, after executing the set builder, the number of sets has decreased, then
		// we assume that there is no access to one of the sets of the layout scheme.
		If DCSSummary.DataSets.Count() > FinalDCSTemplate.DataSets.Count() Then
			Raise NStr("vi = 'Vi phạm quyền truy cập.';
						|ru = 'Нарушение прав доступа.';
						|en = 'Access violation.'; fa = 'Access violation.';
						|it = 'Violazione dei diritti di accesso.';
						|pl = 'Naruszenie praw dostępu.';
						|tr = 'Erişim hakkı ihlali.'");
		EndIf;
		
		DataCache.Insert("FinalDCSTemplate", FinalDCSTemplate);
	EndIf;
	
	ResultTable1 = FinReports.UploadDCSResultsFromTemplate(FinalDCSTemplate, ExternalSets);
	If ResultTable1.Columns.Find("EditedValue") = Undefined Then
		// for compatibility
		ResultTable1.Columns.Add("EditedValue", New TypeDescription("String", , New StringQualifiers(150)));
	EndIf;
	
	Return ResultTable1;
	
EndFunction

#EndRegion

#Region CalculationOfCellStructureData

// The function returns an array of periods
//
// Parameters:
//  BeginOfPeriod  - Date - Beginning of the period
//  EndOfPeriod  - Date - end of the period
//  Periodicity  - EnumRef.Periodicity - the frequency step.
//
// Returns:
//   Array of Date - array of periods
//
Function BudgetReportPeriods(Val BeginOfPeriod, Val EndOfPeriod, Periodicity) Export
	
	Result = New Array;
	BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(BeginOfPeriod, Periodicity);
	While BeginOfPeriod <= EndOfPeriod Do
		Result.Add(BeginOfPeriod);
		BeginOfPeriod = WorkingWithClientServerPeriods.AddInterval(BeginOfPeriod, Periodicity, 1);
	EndDo;
	
	Return Result;
	
EndFunction

// Generates a table of values with columns Periodnnn,
// where NNN is the name of the standard period (year, quarter, etc.).
// the table rows contain the start dates of all periods, taking into account the periodicity of the corresponding column.
//
// Parameters:
//   Periodicity_ - Array of EnumRef.Periodicity - periodicity values to be added to the table
//   BeginOfPeriod - Date - Beginning of the period
//   EndOfPeriod - Date - End of the period
//
// Returns:
//  ValueTable -
//
Function PeriodsTable(Periodicity_, BeginOfPeriod, EndOfPeriod) Export
	
	PeriodsTable = New ValueTable;
	For Each Periodicity In Periodicity_ Do
		PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		PeriodsTable.Columns.Add(PeriodName, New TypeDescription("Date"));
	EndDo;
	
	MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(Periodicity_);
	ArrayOfPeriods = BudgetReportPeriods(BeginOfPeriod, EndOfPeriod, MinimumPeriodicity);
	
	For Each Period In ArrayOfPeriods Do
		NewRow = PeriodsTable.Add();
		For Each Periodicity In Periodicity_ Do
			PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
			NewRow[PeriodName] = WorkingWithClientServerPeriods.BeginningDateOfPeriod(Period, Periodicity);
		EndDo;
	EndDo;
	
	Return PeriodsTable;
	
EndFunction

Function TableOfPeriodsByDataSource(DescriptionOfReport, SourcesOfGroupingPeriods, BeginOfPeriod, EndOfPeriod, ActualDataLimit, TextOfPeriods)
	
	Periodicity_ = DescriptionOfReport.Periodicity_;
	PeriodsTable = PeriodsTable(Periodicity_, BeginOfPeriod, EndOfPeriod);
	MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(Periodicity_);
	
	FirstRequestPeriods = TrimAll(StrReplace(TextOfPeriods, "<TableName>", "PeriodsTable"));
	QueryText =
	"SELECT
	|	&SelectionFieldNames
	|
	|INTO PeriodsTable
	|
	|FROM &PeriodsTable AS PeriodsTable";
	
	SelectionFieldNames = Left(FirstRequestPeriods, StrLen(FirstRequestPeriods) - 1);
	QueryText = StrReplace(QueryText, "&SelectionFieldNames", SelectionFieldNames);
	QueryText = QueryText + ";";
	
	// We will form our own period table for each source, if it differs from the Period table.
	SourcePeriodTables = New Map();

	If SourcesOfGroupingPeriods.Count() > 0 Then
		
		For Each Source In SourcesOfGroupingPeriods Do
			
			QueryTextPeriods =
			"SELECT
			|	&ExpressionStartOfPeriod AS BeginOfPeriod,
			|	&ExpressionEndOfPeriod AS EndOfPeriod";
			
			ExpressionStartOfPeriod = StrReplace(Source.ExpressionBeginningOfGroupingPeriod,
					"LeftTableOfPeriods." + FinancialReportingClientServer.PeriodStrings(MinimumPeriodicity).Period,
					"&BeginOfPeriod");
			ExpressionEndOfPeriod = StrReplace(Source.EndOfGroupingPeriodExpression,
					"LeftTableOfPeriods." + FinancialReportingClientServer.PeriodStrings(MinimumPeriodicity).Period,
					"&EndOfPeriod");
			QueryTextPeriods = StrReplace(QueryTextPeriods, "&ExpressionStartOfPeriod", ExpressionStartOfPeriod);
			QueryTextPeriods = StrReplace(QueryTextPeriods, "&ExpressionEndOfPeriod", ExpressionEndOfPeriod);
			
			Query = New Query;
			Query.Text = QueryTextPeriods;
			Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
			Query.SetParameter("EndOfPeriod", EndOfPeriod);
			Query.SetParameter("ActualDataLimit", ActualDataLimit);
			
			//@skip-check query-in-loop
			Selection = Query.Execute().Select();
			
			If Selection.Next() Then
				
				If Selection.BeginOfPeriod = BeginOfPeriod And Selection.EndOfPeriod = EndOfPeriod Then
					Continue;
				EndIf;
				
				TableOfSourcePeriods = PeriodsTable(Periodicity_, Selection.BeginOfPeriod, Selection.EndOfPeriod);
				SourcePeriodTables.Insert(Source.Id, TableOfSourcePeriods);
				
				FirstRequestPeriods = TrimAll(StrReplace(TextOfPeriods, "<TableName>", "TableOfSourcePeriods"));
				PackageRequest = 
				"SELECT
				|
				|	&SelectedFields
				|
				|INTO ReplacementTemporaryTableName
				|
				|FROM &TableOfIDSourcePeriods AS TableOfSourcePeriods";
				
				SelectedFields = Left(FirstRequestPeriods, StrLen(FirstRequestPeriods) - 1);
				ReplacementTemporaryTableName = "TableOfSourcePeriods"+Source.Id;
				TableOfIDSourcePeriods = "&TableOfSourcePeriods" + Source.Id;
				
				PackageRequest = StrReplace(PackageRequest, "&SelectedFields", SelectedFields);
				PackageRequest = StrReplace(PackageRequest, "ReplacementTemporaryTableName", ReplacementTemporaryTableName);
				PackageRequest = StrReplace(PackageRequest, "&TableOfIDSourcePeriods", TableOfIDSourcePeriods);
				
				QueryText = QueryText + Chars.LF + PackageRequest + ";";
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	PackageRequest =
	"SELECT
	|	&SelectedFields,
	|	"""" AS Id_OfSourceOfGroupingPeriods
	|FROM PeriodsTable";
	
	SelectedFields = "";
	For Each Periodicity In DescriptionOfReport.Periodicity_ Do
		SelectedFields = SelectedFields + ?(SelectedFields = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				" PeriodsTable.%1 AS %2,
				| PeriodsTable.%1 AS %3",
				FinancialReportingClientServer.PeriodStrings(Periodicity).Period,
				FinancialReportingClientServer.PeriodStrings(Periodicity).ReportPeriod_,
				FinancialReportingClientServer.PeriodStrings(Periodicity).PeriodConnection);
	EndDo;
	
	PackageRequest = StrReplace(PackageRequest, "&SelectedFields", SelectedFields);
	
	QueryText = QueryText + Chars.LF + Chars.LF + PackageRequest;
		
	For Each Source In SourcesOfGroupingPeriods Do
		
		TextAssociation = "
		|
		|UNION ALL
		|
		|";
		
		PackageRequest =
		"SELECT DISTINCT
		|	&SelectedFields,
		|	&SourceIDExpression AS Id_OfSourceOfGroupingPeriods
		|FROM
		|	PeriodsTable AS LeftTableOfPeriods
		|LEFT JOIN
		|	#ConnectionTable AS RightTableOfPeriods
		|ON
		|	&ConnectionConditions";
		
		SelectedFields = "";
		For Each Periodicity In DescriptionOfReport.Periodicity_ Do
			SelectedFields = SelectedFields + ?(SelectedFields = "", "", "," + Chars.LF + Chars.Tab)
				+ StringFunctionsClientServer.SubstituteParametersToString(
					" LeftTableOfPeriods.%1 AS %2,
					| RightTableOfPeriods.%1 AS %3",
					FinancialReportingClientServer.PeriodStrings(Periodicity).Period,
					FinancialReportingClientServer.PeriodStrings(Periodicity).ReportPeriod_,
					FinancialReportingClientServer.PeriodStrings(Periodicity).PeriodConnection);
		EndDo;
		
		If SourcePeriodTables.Get(Source.Id) = Undefined Then
			ConnectionTable = "PeriodsTable";
		Else
			ConnectionTable = "TableOfSourcePeriods" + Source.Id;
		EndIf;
		ConnectionConditions = StringFunctionsClientServer.SubstituteParametersToString(
			"RightTableOfPeriods.%1 BETWEEN %2 AND %3",
			FinancialReportingClientServer.PeriodStrings(MinimumPeriodicity).Period,
			Source.ExpressionBeginningOfGroupingPeriod,
			Source.EndOfGroupingPeriodExpression);
		
		PackageRequest = StrReplace(PackageRequest, "&SelectedFields", SelectedFields);
		PackageRequest = StrReplace(PackageRequest, "&SourceIDExpression", """" + Source.Id + """");
		PackageRequest = StrReplace(PackageRequest, "#ConnectionTable", ConnectionTable);
		PackageRequest = StrReplace(PackageRequest, "&ConnectionConditions", ConnectionConditions);
		
		QueryText = QueryText + TextAssociation + PackageRequest;
		
	EndDo;
	
	Query = New Query(QueryText);
	Query.SetParameter("PeriodsTable", PeriodsTable);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("ActualDataLimit", ActualDataLimit);
	For Each Page1 In SourcePeriodTables Do
		Query.SetParameter("TableOfSourcePeriods" + Page1.Key, Page1.Value);
	EndDo;
	
	Return Query.Execute().Unload();
	
EndFunction

Function AuxiliaryCellDataCalculationData(DataParameters, DescriptionOfReport,
						CellStructureSettings, DataCache, GenerationMode)
	Var AuxiliaryCellCalculationData, BaseLines;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	BeginOfPeriod = DataParameters.BeginOfPeriod;
	EndOfPeriod = DataParameters.EndOfPeriod;
	ActualDataLimit = DataParameters.ActualDataLimit;
	
	CachePostfix = "";
	
	If DataParameters.Property("BaseLines", BaseLines) And ValueIsFilled(BaseLines) Then
		CachePostfix = "_FilterForRows";
	EndIf;
	
	OnlyCalculated = DataParameters.Property("OnlyCalculated");
	If OnlyCalculated Then
		CachePostfix = CachePostfix + "_OnlyCalculated";
	EndIf;
	
	If DataCache.Property("AuxiliaryDataJoinsStructuresWithData" + CachePostfix, AuxiliaryCellCalculationData) Then
		Return AuxiliaryCellCalculationData;
	EndIf;
	
	BasicElements = 
	"<TableName>.RowIndex,
	|<TableName>.MainItem,
	|<TableName>.String,
	|<TableName>.Column,
	|<TableName>.OperandCalculationProcedure,
	|<TableName>.ItemKind,
	|<TableName>.CalculationFilling,
	|<TableName>.OperandType,
	|<TableName>.BudgetFlowItem,
	|<TableName>.BudgetBalanceItem,
	|<TableName>.NonFinancialItem,
	|<TableName>.EditedValue,";
	
	BasicFlags = 
	"<TableName>.FlagBudgetFlowItem,
	|<TableName>.FlagBudgetBalanceItem,
	|<TableName>.FlagNonFinancialItem,
	|<TableName>.FlagEditedValue,";
	
	MeasurementText_ = "";
	TextDimensionFlags = "";
	
	AllDimensions = New Array;
	
	For Each Dimension In DescriptionOfReport.Dimensions Do
		MeasurementText_ = MeasurementText_ + "
		|" + "<TableName>." + Dimension + " AS " + Dimension + ",
		|";
		TextDimensionFlags = TextDimensionFlags + "
		|" + "<TableName>.Flag" + Dimension + " AS Flag" + Dimension + ",
		|";
		If Dimension <> "Currency" Then //service dimension
			AllDimensions.Add(Dimension);
		EndIf;
	EndDo;
	
	AnalyticsText = "";
	TextAnalyticsFlags = "";
	TextAnalyst_3 = "";
	For Each Dimension In DescriptionOfReport.DimensionKinds Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		AnalyticsText = AnalyticsText + "
		|" + "<TableName>." + FieldName + " AS " + FieldName + ",
		|";
		TextAnalyticsFlags = TextAnalyticsFlags + "
		|" + "<TableName>.Flag" + FieldName + " AS Flag" + FieldName + ",
		|";
		TextAnalyst_3 = TextAnalyst_3 + "<TableName>.Parent" + FieldName + " AS Parent" + FieldName + ",
		|";
		AllDimensions.Add(FieldName);
	EndDo;
	
	TextOfPeriods = "";
	TextConnection = "";
	TextFlagsPeriods = "";
	TextOfPeriodsExpression = "";
	For Each Periodicity In DescriptionOfReport.Periodicity_ Do
		PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		
		TextOfPeriods = TextOfPeriods + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"<TableName>.%1 AS %1,",
				PeriodName)
			+ Chars.LF;
		
		PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).PeriodConnection;
		
		TextConnection = TextConnection + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"<TableName>.%1 AS %1,",
				PeriodName)
			+ Chars.LF;
			
		PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).FlagPeriod;
		
		TextFlagsPeriods = TextFlagsPeriods + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"<TableName>.%1 AS %1,",
				PeriodName)
			+ Chars.LF;
			
		PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).PeriodExpression;
		
		TextOfPeriodsExpression = TextOfPeriodsExpression + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"<TableName>.%1 AS %1,",
				PeriodName)
			+ Chars.LF;
		
	EndDo;
	
	ThereIsPeriodicity = DescriptionOfReport.Periodicity_.Count();
	SourcesOfGroupingPeriods =
		CellStructureSettings.SourcesOfGroupingPeriods; // See BudgetReportingCacheCalculationServer.SourcesOfGroupingPeriods
	
	PeriodsTable = Undefined;
	If ThereIsPeriodicity Then
		
		PeriodsTable = TableOfPeriodsByDataSource(DescriptionOfReport,
				SourcesOfGroupingPeriods,
				BeginOfPeriod,
				EndOfPeriod,
				ActualDataLimit,
				TextOfPeriods);
		
	EndIf;
	
	NFPMeasurementTable = New ValueTable;
	NFPMeasurementTable.Columns.Add("NonFinancialItem");
	NFPMeasurementTable.Columns.Add("DimensionName");
	
	TextAnalyst_ = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextAnalyst_ = TextAnalyst_ + ?(TextAnalyst_ = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"NonFinancialItemsOfBudgets.DimensionKind%1 AS DimensionKind%1",
				DimensionNumber);
	EndDo;
	Query = New Query;
	QueryText =
	"SELECT
		|	NonFinancialItemsOfBudgets.Ref AS NonFinancialItem,
		|	&TextAnalyst_
		|FROM
		|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
		|WHERE Ref IN (&ObjectsArray)";
	QueryText = StrReplace(QueryText, "&TextAnalyst_", TextAnalyst_);
	Query.Text = QueryText;
		
	CellStructure = CellStructureSettings.CellStructure;
	ListOfObjects = CommonClientServer.CollapseArray(CellStructure.UnloadColumn("NonFinancialItem"));
	Query.SetParameter("ObjectsArray", ListOfObjects);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			DimensionKind = Selection["DimensionKind" + Cnt];
			If Not ValueIsFilled(DimensionKind) Then
				Continue;
			EndIf;
			FieldName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
			NewRow = NFPMeasurementTable.Add();
			NewRow.NonFinancialItem = Selection.NonFinancialItem;
			NewRow.DimensionName = FieldName;
		EndDo;
	EndDo;
	
	NFPMeasurementTable.Indexes.Add("NonFinancialItem, DimensionName");
	
	AuxiliaryData = New Structure;
	AuxiliaryData.Insert("BasicElements", BasicElements);
	AuxiliaryData.Insert("BasicFlags", BasicFlags);
	AuxiliaryData.Insert("MeasurementText_", MeasurementText_);
	AuxiliaryData.Insert("TextDimensionFlags", TextDimensionFlags);
	AuxiliaryData.Insert("AnalyticsText", AnalyticsText);
	AuxiliaryData.Insert("TextAnalyticsFlags", TextAnalyticsFlags);
	AuxiliaryData.Insert("TextAnalyst_3", TextAnalyst_3);
	AuxiliaryData.Insert("TextOfPeriods", TextOfPeriods);
	AuxiliaryData.Insert("TextConnection", TextConnection);
	AuxiliaryData.Insert("TextFlagsPeriods", TextFlagsPeriods);
	AuxiliaryData.Insert("TextOfPeriodsExpression", TextOfPeriodsExpression);
	AuxiliaryData.Insert("GenerationMode", GenerationMode);
	AuxiliaryData.Insert("AllDimensions", AllDimensions);
	AuxiliaryData.Insert("NFPMeasurementTable", NFPMeasurementTable);
	AuxiliaryData.Insert("QueryOptions", New Structure);
	AuxiliaryData.Insert("PeriodsTable", PeriodsTable);
	
	CellStructure = CellStructureSettings.CellStructure;
	SourceFields_2 = CellStructureSettings.SourceFields_2;
	SourcesOfMeasurementValues = CellStructureSettings.SourcesOfMeasurementValues;
	FillingInMissingNFPMeasurements = CellStructureSettings.FillingInMissingNFPMeasurements;
	SelectionOfNFPMeasurements = CellStructureSettings.SelectionOfNFPMeasurements;
	RequiredResources = SourceFields_2.FindRows(New Structure("Auxiliary_", False));
	
	QueryText = 
	"SELECT
	|	&SelectedFields,
	|	CellStructure.Id_OfSource, CellStructure.ID_Source1,
	|	CellStructure.ExcludeEnteredDocumentDataDuringCalculation AS ExcludeDocumentData
	|
	|INTO CellStructure
	|
	|FROM &CellStructure AS CellStructure
	|WHERE
	|	&FilterConditions";
	
	SelectedFields = StrReplace(BasicElements, "<TableName>", "CellStructure")
			+ StrReplace(BasicFlags, "<TableName>", "CellStructure")
			+ StrReplace(MeasurementText_, "<TableName>", "CellStructure")
			+ StrReplace(TextOfPeriods, "<TableName>", "CellStructure")
			+ StrReplace(AnalyticsText, "<TableName>", "CellStructure")
			+ StrReplace(TextDimensionFlags, "<TableName>", "CellStructure")
			+ StrReplace(TextFlagsPeriods, "<TableName>", "CellStructure")
			+ StrReplace(TextOfPeriodsExpression, "<TableName>", "CellStructure")
			+ StrReplace(TextAnalyticsFlags, "<TableName>", "CellStructure")
			+ StrReplace(TextAnalyst_3, "<TableName>", "CellStructure");
	SelectedFields = TrimAll(SelectedFields);
	If StrEndsWith(SelectedFields, ",") Then
		SelectedFields = Mid(SelectedFields, 1, StrLen(SelectedFields) - 1);
	EndIf;
	
	FilterConditions = "";
	If ValueIsFilled(BaseLines) Then
		FilterConditions = "CellStructure.String IN (&BaseLines)";
	EndIf;
	If OnlyCalculated Then
		FilterConditions = FilterConditions + ?(FilterConditions = "", "", Chars.LF + Chars.Tab + "OR" + " ")
			+ "(CellStructure.CalculationFilling = ""total"")";
	EndIf;
	If FilterConditions = "" Then
		FilterConditions = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SelectedFields", SelectedFields);
	QueryText = StrReplace(QueryText, "&FilterConditions", FilterConditions);
	
	If Not DescriptionOfReport.Periodicity_.Count() Then
		QueryText = QueryText + "
		|INDEX BY STRING, Column
		|
		|;
		|";
	Else
		QueryText = QueryText + "
		|INDEX BY Id_OfSource
		|
		|;
		|";
	EndIf;
	
	// Preparing the data table
	PackageRequest = 
	"SELECT
	|	DataTable.ID_Source1,
	|	DataTable.BudgetFlowItem,
	|	DataTable.BudgetBalanceItem,
	|	CAST(DataTable.NonFinancialItem AS Catalog.NonFinancialItemsOfBudgets) AS NonFinancialItem,
	|	CAST(DataTable.EditedValue AS STRING(150)) AS EditedValue,
	|	&SelectedFields,
	|	DataTable.NFPIndex,
	|	DataTable.SerialNumber,
	|	DataTable.Note,
	|	ISNULL(DataTable.DocumentData, FALSE) AS DocumentData
	|
	|INTO DataTablePreliminary
	|
	|FROM &DataTable AS DataTable"
	+ Common.QueryBatchSeparator() +
	"SELECT
	|	DataTable.ID_Source1,
	|	DataTable.BudgetFlowItem,
	|	DataTable.BudgetBalanceItem,
	|	DataTable.NonFinancialItem,
	|	ISNULL(DataTable.NonFinancialItem.ByCompanies, TRUE) AS NFP_SelectionCompany,
	|	ISNULL(DataTable.NonFinancialItem.ByBusinessUnits, TRUE) AS NFP_SelectionDivision,
	|	ISNULL(DataTable.NonFinancialItem.ByScenarios, TRUE) AS NFP_SelectionScenario,
	|	DataTable.EditedValue,
	|	&SelectedFields,
	|	DataTable.NFPIndex,
	|	DataTable.SerialNumber,
	|	DataTable.Note,
	|	DataTable.DocumentData AS DocumentData
	|
	|INTO DataTable
	|
	|FROM DataTablePreliminary AS DataTable";
	
	SelectedFields = StrReplace(MeasurementText_, "<TableName>", "DataTable")
			+ StrReplace(TextOfPeriods, "<TableName>", "DataTable")
			+ StrReplace(AnalyticsText, "<TableName>", "DataTable");
	SelectedFields = TrimAll(SelectedFields);
	If StrEndsWith(SelectedFields, ",") Then
		SelectedFields = Mid(SelectedFields, 1, StrLen(SelectedFields) - 1);
	EndIf;
	For Each ResourceField In RequiredResources Do
		SelectedFields = SelectedFields + "," + Chars.LF + Chars.Tab
			+ "DataTable." + ResourceField.ResourceName;
	EndDo;
	
	PackageRequest = StrReplace(PackageRequest, "&SelectedFields", SelectedFields);
	PackageRequest = PackageRequest + "
	|
	|INDEX BY NonFinancialItem"
	+ Common.QueryBatchSeparator() +
	"DROP DataTablePreliminary"
	+ Common.QueryBatchSeparator();
	
	QueryText = QueryText + Chars.LF + PackageRequest;
	
	// Preparing the data table
	QueryText = QueryText + "
	|SELECT DISTINCT
	|	TableOfSources.ID_Source1,
	|	TableOfSources.String,
	|	TableOfSources.Column
	|
	|INTO TableOfMeasurementSources
	|
	|FROM &TableOfMeasurements AS TableOfSources
	|
	|WHERE
	|	TableOfSources.ID_Source1 <> ""AllItems""
	|
	|INDEX BY String, Column
	|;
	|";
	
	QueryText = QueryText + "
	|SELECT
	|	TableOfSources.ID_Source1,
	|	TableOfSources.Dimension,
	|	TableOfSources.BudgetFlowItem,
	|	TableOfSources.BudgetBalanceItem,
	|	TableOfSources.NonFinancialItem,
	|	TableOfSources.EditedValue,
	|	TableOfSources.String,
	|	TableOfSources.Column,
		// Additional fields for the source analyst filter when filling in derived indicators and groups
	|	TableOfSources.SourceKind,				// Article or Indicator or non-financial indicator or editable value or Undefined (i.e. all or all indicators)
	|	TableOfSources.BudgetBalanceItemType		// Calculated or Target
	|
	|INTO TableOfMeasurementSourcesWithDimensionName
	|
	|FROM &TableOfMeasurements AS TableOfSources
	|
	|INDEX BY Dimension
	|;
	|";
	
	DataTableName = "DataTable";
	TableName = "CellStructure";
	
	AddSelectionOfEntriesByNFPToRequest(QueryText, AuxiliaryData, CellStructure, SelectionOfNFPMeasurements, RequiredResources, DataTableName);
	
	SupplementMissingGNFPAnalytics(QueryText, AuxiliaryData, FillingInMissingNFPMeasurements, SourcesOfMeasurementValues, RequiredResources, DataTableName);
	
	SplitCellsByPeriods(QueryText, DescriptionOfReport, AuxiliaryData, TableName);
	
	ParametersOfOtherConnections = PrepareTableOfMeasurementValuesForParents(QueryText, CellStructure, AuxiliaryData);
	
	If DataParameters.Property("BudgetProfileDisplayParameters") Then
		CheckingPossibilityOfFillingMeasurementsInCellStructure(DescriptionOfReport, SourcesOfMeasurementValues,
			DataParameters.BudgetProfileDisplayParameters.OutputTree);
	EndIf;
	
	NameOfTableWithDimensions = TableName;
	
	ParametersForFillingMeasurements = New Structure;
	ParametersForFillingMeasurements.Insert("DescriptionOfReport", DescriptionOfReport);
	ParametersForFillingMeasurements.Insert("AuxiliaryData", AuxiliaryData);
	ParametersForFillingMeasurements.Insert("DataTableName", DataTableName);
	ParametersForFillingMeasurements.Insert("SourcesOfMeasurementValues", SourcesOfMeasurementValues);
	ParametersForFillingMeasurements.Insert("ParametersOfOtherConnections", ParametersOfOtherConnections);
	ParametersForFillingMeasurements.Insert("GenerationMode", GenerationMode);
	FillInDimensionsInCellStructureBySource(QueryText, ParametersForFillingMeasurements, NameOfTableWithDimensions);
	
	AddSourceToCellStructure(QueryText, DescriptionOfReport, AuxiliaryData, TableName, NameOfTableWithDimensions);
	
	ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators = Undefined;
	If GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType Then
		BudgetItemsAndIndicators_ = New Structure();
		BudgetItemsAndIndicators_.Insert("BudgetFlowItems", SourcesOfMeasurementValues.UnloadColumn("BudgetFlowItem"));
		BudgetItemsAndIndicators_.Insert("BudgetBalanceItems", SourcesOfMeasurementValues.UnloadColumn("BudgetBalanceItem"));
		BudgetItemsAndIndicators_.Insert("NonFinancialIndicators", SourcesOfMeasurementValues.UnloadColumn("NonFinancialItem"));
		ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators = 
			PrepareCorrespondenceOfTypesOfAnalyticsToBudgetItemsAndIndicators(DescriptionOfReport.DimensionKinds, BudgetItemsAndIndicators_);
	EndIf;
	
	AuxiliaryParameters = New Structure;
	AuxiliaryParameters.Insert("SourcesOfMeasurementValues", SourcesOfMeasurementValues);
	AuxiliaryParameters.Insert("DataTableName", DataTableName);
	AuxiliaryParameters.Insert("SourceFields_2", SourceFields_2);
	AuxiliaryParameters.Insert("ParametersOfOtherConnections", ParametersOfOtherConnections);
	AuxiliaryParameters.Insert("ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators", ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators);
	
	ConnectStructureToData(QueryText, DescriptionOfReport, AuxiliaryData, TableName, AuxiliaryParameters, GenerationMode);
	
	PerformMeasurementFilterByValueSources(QueryText, SourcesOfMeasurementValues, TableName, DataTableName);
	
	AuxiliaryCellCalculationData = New Structure;
	AuxiliaryCellCalculationData.Insert("QueryText", QueryText);
	AuxiliaryCellCalculationData.Insert("PeriodsTable", PeriodsTable);
	AuxiliaryCellCalculationData.Insert("QueryOptions", AuxiliaryData.QueryOptions);
	
	DataCache.Insert("AuxiliaryDataJoinsStructuresWithData" + CachePostfix, AuxiliaryCellCalculationData);
	
	Return AuxiliaryCellCalculationData;
	
EndFunction

Procedure SplitCellsByPeriods(QueryText, DescriptionOfReport, AuxiliaryData, TableName)
	
	If Not DescriptionOfReport.Periodicity_.Count() Then
		Return
	EndIf;
	
	BasicElements = AuxiliaryData.BasicElements;
	BasicFlags = AuxiliaryData.BasicFlags;
	MeasurementText_ = AuxiliaryData.MeasurementText_;
	TextDimensionFlags = AuxiliaryData.TextDimensionFlags;
	AnalyticsText = AuxiliaryData.AnalyticsText;
	TextAnalyticsFlags = AuxiliaryData.TextAnalyticsFlags;
	TextAnalyst_3 = AuxiliaryData.TextAnalyst_3;
	
	PeriodicityText_ = "";
	For Each Periodicity In DescriptionOfReport.Periodicity_ Do
		PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		FlagPeriod = FinancialReportingClientServer.PeriodStrings(Periodicity).FlagPeriod;
		ReportPeriod_ = FinancialReportingClientServer.PeriodStrings(Periodicity).ReportPeriod_;
		PeriodConnection = FinancialReportingClientServer.PeriodStrings(Periodicity).PeriodConnection;
		
		PeriodicityText_ = PeriodicityText_ + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"	CASE WHEN CellStructure.%1 = ""Fill""
				|		THEN PeriodsTable.%2
				|		ELSE UNDEFINED
				|	END AS %3,",
				FlagPeriod,
				ReportPeriod_,
				PeriodName)
			+ Chars.LF;
		
		PeriodicityText_ = PeriodicityText_ + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"	CASE WHEN CellStructure.%1 = ""Fill""
				|		THEN PeriodsTable.%2
				|		ELSE UNDEFINED
				|	END AS %2,",
				FlagPeriod,
				PeriodConnection,
				PeriodName)
			+ Chars.LF;
		
		PeriodicityText_ = PeriodicityText_ + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"	CASE WHEN CellStructure.%1 = ""Fill""
				|		THEN ""Pick""
				|		ELSE """"
				|	END AS %1,",
				FlagPeriod)
			+ Chars.LF;
		
	EndDo;
	
	TextOfConnectionOfPeriodicities = "";
	For Each Dimension In DescriptionOfReport.Periodicity_ Do
		FlagPeriod = FinancialReportingClientServer.PeriodStrings(Dimension).FlagPeriod;
		PeriodExpression = FinancialReportingClientServer.PeriodStrings(Dimension).PeriodExpression;
		ReportPeriod_ = FinancialReportingClientServer.PeriodStrings(Dimension).ReportPeriod_;
		DimensionName = FinancialReportingClientServerCached.PeriodicityByString(Dimension);
		If Dimension = Enums.Periodicity.Week Then
			TextOfConnectionOfPeriodicities = TextOfConnectionOfPeriodicities
				+ ?(TextOfConnectionOfPeriodicities = "", "", Chars.LF + Chars.Tab + "And" + " ")
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"(CellStructure.%2 = """"
					|			OR
					|			CellStructure.%3 = -1
					|			OR
					|			(CellStructure.%3 = 0
					|				AND DATEADD(&BeginOfPeriod, %1, CellStructure.%3) = 
					|					PeriodsTable.%4)
					|			OR
					|			(CellStructure.%3 > 0
					|				AND DATEADD(BEGINOFPERIOD(&BeginOfPeriod, %1), %1, CellStructure.%3) = 
					|					PeriodsTable.%4)
					|		)",
					DimensionName,
					FlagPeriod,
					PeriodExpression,
					ReportPeriod_);
		Else
			TextOfConnectionOfPeriodicities = TextOfConnectionOfPeriodicities
				+ ?(TextOfConnectionOfPeriodicities = "", "", Chars.LF + Chars.Tab + "And" + " ")
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"(CellStructure.%2 = """"
					|			OR
					|			CellStructure.%3 = -1
					|			OR
					|			(CellStructure.%3 > -1
					|				AND DATEADD(&BeginOfPeriod, %1, CellStructure.%3) = 
					|					PeriodsTable.%4)
					|		)",
					DimensionName,
					FlagPeriod,
					PeriodExpression,
					ReportPeriod_);
		EndIf;
	EndDo;
	
	PackageRequest =
	"SELECT
	|	&SelectionFields1,
	|	PeriodsTable.Id_OfSourceOfGroupingPeriods
	|
	|INTO PeriodsTable
	|
	|FROM &PeriodsTable AS PeriodsTable
	|
	|INDEX BY Id_OfSourceOfGroupingPeriods
	|;
	|
	|";
	
	SelectionFields1 = "";
	For Each Periodicity In DescriptionOfReport.Periodicity_ Do
		SelectionFields1 = SelectionFields1 + ?(SelectionFields1 = "", "", "," + Chars.LF)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"	PeriodsTable.%1,
				|	PeriodsTable.%2",
				FinancialReportingClientServer.PeriodStrings(Periodicity).ReportPeriod_,
				FinancialReportingClientServer.PeriodStrings(Periodicity).PeriodConnection);
	EndDo;
	PackageRequest = StrReplace(PackageRequest, "&SelectionFields1", SelectionFields1);
	
	QueryText = QueryText + Chars.LF + PackageRequest
		+	"SELECT DISTINCT 
			|
			|	CellStructure.String, CellStructure.Column, CellStructure.Id_OfSource
			|
			|INTO SourcesOfPeriodIncludingSubordinates 
			|FROM CellStructure
			|
			|INDEX BY CellStructure.String, CellStructure.Column
			|
			|;
			|";
	
	PackageRequest = 
	"SELECT DISTINCT
	|	&SelectionFields1,
	|	CellStructure.ID_Source1 AS ID_Source1,
	|	CellStructure.ExcludeDocumentData AS ExcludeDocumentData
	|
	|INTO StructureOfCellsWithPeriods
	|
	|FROM &TableNameCellStructure AS CellStructure
	|
	|LEFT JOIN SourcesOfPeriodIncludingSubordinates
	|	
	|ON CellStructure.String = SourcesOfPeriodIncludingSubordinates.String
	|AND CellStructure.Column = SourcesOfPeriodIncludingSubordinates.Column
	|
	|LEFT JOIN PeriodsTable
	|	
	|ON SourcesOfPeriodIncludingSubordinates.Id_OfSource = PeriodsTable.Id_OfSourceOfGroupingPeriods
	|	AND &TextOfConnectionOfPeriodicities
	|
	|WHERE CellStructure.MainItem AND
	|	CellStructure.ItemKind IN
	|		(	
	|		VALUE(Enum.FinancialReportItemKinds.DerivedItem),
	|		VALUE(Enum.FinancialReportItemKinds.GroupFormula),
	|		VALUE(Enum.FinancialReportItemKinds.Group)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&SelectionFields1,
	|	CellStructure.ID_Source1,
	|	CellStructure.ExcludeDocumentData
	|
	|FROM &TableNameCellStructure AS CellStructure
	|
	|LEFT JOIN PeriodsTable
	|	
	|ON CellStructure.Id_OfSource = PeriodsTable.Id_OfSourceOfGroupingPeriods
	|	AND &TextOfConnectionOfPeriodicities
	|
	|WHERE (CellStructure.MainItem
	|			AND NOT CellStructure.ItemKind IN
	|			(	
	|			VALUE(Enum.FinancialReportItemKinds.DerivedItem),
	|			VALUE(Enum.FinancialReportItemKinds.GroupFormula),
	|			VALUE(Enum.FinancialReportItemKinds.Group)
	|			)
	|	)
	|	OR NOT CellStructure.MainItem";
	
	SelectionFields1 = StrReplace(BasicElements, "<TableName>", "CellStructure")
			+ StrReplace(BasicFlags, "<TableName>", "CellStructure")
			+ StrReplace(MeasurementText_, "<TableName>", "CellStructure")
			+ StrReplace(TextDimensionFlags, "<TableName>", "CellStructure")
			+ PeriodicityText_
			+ StrReplace(TextAnalyst_3, "<TableName>", "CellStructure")
			+ StrReplace(AnalyticsText, "<TableName>", "CellStructure")
			+ StrReplace(TextAnalyticsFlags, "<TableName>", "CellStructure");
	SelectionFields1 = TrimAll(SelectionFields1);
	If StrEndsWith(SelectionFields1, ",") Then
		SelectionFields1 = Mid(SelectionFields1, 1, StrLen(SelectionFields1) - 1);
	EndIf;
	
	PackageRequest = StrReplace(PackageRequest, "&SelectionFields1", SelectionFields1);
	PackageRequest = StrReplace(PackageRequest, "&TableNameCellStructure", TableName);
	PackageRequest = StrReplace(PackageRequest, "&TextOfConnectionOfPeriodicities", TextOfConnectionOfPeriodicities);
	
	TextIndexes = "
	|
	|INDEX BY CellStructure.String, CellStructure.Column";
	QueryText = QueryText + Chars.LF + PackageRequest + TextIndexes + ";" + Chars.LF + Chars.LF;
	
	TableName = "StructureOfCellsWithPeriods";
	
EndProcedure

Procedure AddSelectionOfEntriesByNFPToRequest(QueryText, AuxiliaryData, CellStructure, SelectionOfNFPMeasurements, RequiredResources, DataTableName)
	
	If SelectionOfNFPMeasurements = Undefined
		Or Not SelectionOfNFPMeasurements.Count() Then
		Return;
	EndIf;
	
	MeasurementText_ = AuxiliaryData.MeasurementText_;
	AnalyticsText = AuxiliaryData.AnalyticsText;
	TextOfPeriods  = AuxiliaryData.TextOfPeriods;
	
	// Primary filter of measurement values
	SourceNames = SelectionOfNFPMeasurements.Copy(,"DimensionName");
	SourceNames.GroupBy("DimensionName");
	For Each NameString In SourceNames Do
		
		QueryingTemporaryTable =
		"SELECT DISTINCT
		|	&DimensionName
		|INTO ReplacementTemporaryTableName
		|FROM DataTable AS DataTable
		|WHERE &SourceId_Conditions";
		SourceId_Conditions = "ID_Source1 IN (&ListOfSources" + NameString.DimensionName + ")";
		ReplacementTemporaryTableName = "List" + NameString.DimensionName;
		
		QueryingTemporaryTable = StrReplace(QueryingTemporaryTable, "&DimensionName", NameString.DimensionName);
		QueryingTemporaryTable = StrReplace(QueryingTemporaryTable, "ReplacementTemporaryTableName", ReplacementTemporaryTableName);
		QueryingTemporaryTable = StrReplace(QueryingTemporaryTable, "&SourceId_Conditions", SourceId_Conditions);
		
		QueryText = QueryText + Chars.LF + QueryingTemporaryTable + ";" + Chars.LF + Chars.LF;
		
		FoundRows = SelectionOfNFPMeasurements.FindRows(New Structure("DimensionName", NameString.DimensionName));
		List = New ValueList;
		For Each FoundRow In FoundRows Do
			If List.FindByValue(FoundRow.AddressForFillingInValues) = Undefined Then
				List.Add(FoundRow.AddressForFillingInValues);
			EndIf;
		EndDo;
		AuxiliaryData.QueryOptions.Insert("ListOfSources" + NameString.DimensionName, List);
		
	EndDo;
	
	PackageRequest =
	"SELECT
	|	DataTable.ID_Source1,
	|	DataTable.BudgetFlowItem,
	|	DataTable.BudgetBalanceItem,
	|	DataTable.EditedValue,
	|	DataTable.NonFinancialItem,
	|	DataTable.NFP_SelectionCompany,
	|	DataTable.NFP_SelectionDivision,
	|	DataTable.NFP_SelectionScenario,
	|	&SelectedFields,
	|	DataTable.NFPIndex,
	|	DataTable.SerialNumber,
	|	DataTable.Note,
	|	DataTable.DocumentData
	|INTO DataTableWithoutUnnecessaryAnalytics
	|FROM
	|	&DataTableName AS DataTable
	|
	|WHERE DataTable.NonFinancialItem IN (&NonFinancialIndicatorsWithoutSelectionAndEvaluation)";
	
	SelectedFields = StrReplace(MeasurementText_, "<TableName>", "DataTable")
			+ StrReplace(TextOfPeriods, "<TableName>", "DataTable")
			+ StrReplace(AnalyticsText, "<TableName>", "DataTable");
	SelectedFields = TrimAll(SelectedFields);
	If StrEndsWith(SelectedFields, ",") Then
		SelectedFields = Mid(SelectedFields, 1, StrLen(SelectedFields) - 1);
	EndIf;
		
	For Each ResourceField In RequiredResources Do
		SelectedFields = SelectedFields + "," + Chars.LF + Chars.Tab
			+ "DataTable." + ResourceField.ResourceName;
	EndDo;
	
	PackageRequest = StrReplace(PackageRequest, "&SelectedFields", SelectedFields);
	PackageRequest = StrReplace(PackageRequest, "&DataTableName", DataTableName);
	QueryText = QueryText + Chars.LF + PackageRequest;
	
	SourceNames = SelectionOfNFPMeasurements.Copy(,"NonFinancialItem");
	SourceNames.GroupBy("NonFinancialItem");
	
	NonFinancialIndicators = CommonClientServer.CollapseArray(CellStructure.UnloadColumn("NonFinancialItem"));
	NonFinancialIndicators = CommonClientServer.ArraysDifference(NonFinancialIndicators, SourceNames.UnloadColumn("NonFinancialItem"));
	
	AuxiliaryData.QueryOptions.Insert("NonFinancialIndicatorsWithoutSelectionAndEvaluation", NonFinancialIndicators);
	
	DimensionsNames = SelectionOfNFPMeasurements.Copy(,"NonFinancialItem, DimensionName");
	DimensionsNames.GroupBy("NonFinancialItem, DimensionName");
	
	For Each NameString In SourceNames Do
		
		TextAssociation = "
		|
		|UNION ALL
		|
		|";
		
		PackageRequest =
		"SELECT
		|	DataTable.ID_Source1,
		|	DataTable.BudgetFlowItem,
		|	DataTable.BudgetBalanceItem,
		|	DataTable.EditedValue,
		|	DataTable.NonFinancialItem,
		|	DataTable.NFP_SelectionCompany,
		|	DataTable.NFP_SelectionDivision,
		|	DataTable.NFP_SelectionScenario,
		|	&SelectedFields,
		|	DataTable.NFPIndex,
		|	DataTable.SerialNumber,
		|	DataTable.Note,
		|	DataTable.DocumentData
		|
		|FROM &DataTableName AS DataTable
		|
		|WHERE
		|	&ExpressionOfNFPSelection";
		
		SelectedFields = StrReplace(MeasurementText_, "<TableName>", "DataTable")
				+ StrReplace(TextOfPeriods, "<TableName>", "DataTable")
				+ StrReplace(AnalyticsText, "<TableName>", "DataTable");
		SelectedFields = TrimAll(SelectedFields);
		If StrEndsWith(SelectedFields, ",") Then
			SelectedFields = Mid(SelectedFields, 1, StrLen(SelectedFields) - 1);
		EndIf;
		
		For Each ResourceField In RequiredResources Do
			SelectedFields = SelectedFields + "," + Chars.LF + Chars.Tab
				+ "DataTable." + ResourceField.ResourceName;
		EndDo;
			
		ExpressionOfNFPSelection = "DataTable.NonFinancialItem = &NFP_"
			+ FinancialReportingCached.NameOfBudgetReportField(NameString.NonFinancialItem);
		
		AuxiliaryData.QueryOptions.Insert("NFP_" + FinancialReportingCached.NameOfBudgetReportField(NameString.NonFinancialItem), NameString.NonFinancialItem);
		Records = DimensionsNames.FindRows(New Structure("NonFinancialItem", NameString.NonFinancialItem));
		
		For Each Record In Records Do
			ExpressionOfNFPSelection = ExpressionOfNFPSelection + Chars.LF + Chars.Tab
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"AND DataTable.%1 IN (SELECT %1 FROM List%1)",
				Record.DimensionName);
		EndDo;
		
		PackageRequest = StrReplace(PackageRequest, "&SelectedFields", SelectedFields);
		PackageRequest = StrReplace(PackageRequest, "&DataTableName", DataTableName);
		PackageRequest = StrReplace(PackageRequest, "&ExpressionOfNFPSelection", ExpressionOfNFPSelection);
		
		QueryText = QueryText + TextAssociation + PackageRequest;
		
	EndDo;
	
	QueryText = QueryText + "
	|
	|INDEX BY NonFinancialItem
	|;
	|";
	
	DataTableName = "DataTableWithoutUnnecessaryAnalytics";
	
EndProcedure

Procedure SupplementMissingGNFPAnalytics(QueryText, AuxiliaryData, FillingInMissingNFPMeasurements,
                                            SourcesOfMeasurementValues, RequiredResources, DataTableName)
	
	If FillingInMissingNFPMeasurements = Undefined
		Or Not FillingInMissingNFPMeasurements.Count() Then
		Return;
	EndIf;
	
	MeasurementText_      = AuxiliaryData.MeasurementText_;
	AnalyticsText      = AuxiliaryData.AnalyticsText;
	TextOfPeriods       = AuxiliaryData.TextOfPeriods;
	
	SourceNames = FillingInMissingNFPMeasurements.Copy(,"NonFinancialItem");
	SourceNames.GroupBy("NonFinancialItem");
	SourceNames.Columns.Add("NameOfDataPaddingTable");
	SourceNames.Columns.Add("TableMeasurements");
	
	DimensionsNames = FillingInMissingNFPMeasurements.Copy(,"NonFinancialItem, DimensionName");
	DimensionsNames.GroupBy("NonFinancialItem, DimensionName");
	
	TablesCache = New Map;
	
	For Each NameString In SourceNames Do
		
		AllDimensions = AuxiliaryData.AllDimensions;
		ArrayOfDimensions_ = New Array;
		
		For Each Dimension In AllDimensions Do
			// If this dimension is filled in, then it does not participate in the connection
			FoundRows = FillingInMissingNFPMeasurements.FindRows(New Structure("DimensionName", Dimension));
			Required2 = True;
			For Each FoundRow In FoundRows Do
				If FoundRow.NonFinancialItem = NameString.NonFinancialItem Then
					Required2 = True;
					Break;
				EndIf;
				If FoundRow.NonFinancialItem <> NameString.NonFinancialItem Then
					Required2 = False;
				EndIf;
			EndDo;
			// If the NFP can be a supplier of measurement values, then we use all the values of the NFP.
			Search = New Structure("NonFinancialItem, Dimension", NameString.NonFinancialItem, Dimension);
			If Required2 And SourcesOfMeasurementValues.FindRows(Search).Count() Then
				Required2 = False;
			EndIf;
			If Not Required2 Then
				Continue;
			EndIf;
			ArrayOfDimensions_.Add(Dimension);
		EndDo;
		
		DimensionNamesCurrency = DimensionsNames.FindRows(New Structure("NonFinancialItem, DimensionName", NameString.NonFinancialItem, "Currency"));
		If DimensionNamesCurrency.Count() > 0 
			And ArrayOfDimensions_.Find("Currency") = Undefined Then
			// The "Currency" dimension is not included in the values of all measurements
			ArrayOfDimensions_.Add("Currency");
		EndIf;
		
		StringDimensionNames = StrConcat(ArrayOfDimensions_, ",");
		SourceAddresses = FillingInMissingNFPMeasurements.Copy(New Structure("NonFinancialItem", NameString.NonFinancialItem));
		NecessarySources = CommonClientServer.CollapseArray(SourceAddresses.UnloadColumn("AddressOfValueFillingSource"));
		
		SearchKey = StringDimensionNames + StrConcat(NecessarySources, ",");
		
		TableParameters = TablesCache[SearchKey];
		If TableParameters = Undefined Then
			
			ParameterName = "List" + FinancialReportingCached.NameOfBudgetReportField(NameString.NonFinancialItem);
			AuxiliaryData.QueryOptions.Insert(ParameterName, NecessarySources);
			
			TableName = "TableOfSelectedMeasurements" + FinancialReportingCached.NameOfBudgetReportField(NameString.NonFinancialItem);
			QueryTextSource1 = 
			"SELECT DISTINCT
			|	&StringDimensionNames
			|INTO ReplacementTemporaryTableName
			|FROM &DataTableName
			|WHERE &SourceIDCondition";
			
			SourceIDCondition = StrReplace("ID_Source1 IN (&ParameterName)", "&ParameterName", "&" + ParameterName);
			QueryTextSource1 = StrReplace(QueryTextSource1, "ReplacementTemporaryTableName", TableName);
			QueryTextSource1 = StrReplace(QueryTextSource1, "&StringDimensionNames", ?(IsBlankString(StringDimensionNames), "UNDEFINED", StringDimensionNames));
			QueryTextSource1 = StrReplace(QueryTextSource1, "&DataTableName", DataTableName);
			QueryTextSource1 = StrReplace(QueryTextSource1, "&SourceIDCondition", SourceIDCondition);
			
			QueryText = QueryText + Chars.LF + QueryTextSource1 + Chars.LF + ";";
			
			TableParameters = New Structure("TableName, ArrayOfDimensions_", TableName, ArrayOfDimensions_);
			TablesCache.Insert(SearchKey, TableParameters);
			
		EndIf;
		
		NameString.NameOfDataPaddingTable = TableParameters.TableName;
		NameString.TableMeasurements = TableParameters.ArrayOfDimensions_;
		
	EndDo;
	
	PackageRequest =
	"SELECT
	|	DataTable.ID_Source1,
	|	DataTable.BudgetFlowItem,
	|	DataTable.BudgetBalanceItem,
	|	DataTable.EditedValue,
	|	DataTable.NonFinancialItem,
	|	DataTable.NFPIndex, 
	|	DataTable.DocumentData,
	|	&SelectedFields,
	|	DataTable.SerialNumber,
	|	DataTable.Note
	|
	|INTO DataTableWithCompletedAnalytics
	|
	|FROM &DataTableName AS DataTable
	|
	|WHERE DataTable.NonFinancialItem = VALUE(Catalog.NonFinancialItemsOfBudgets.EmptyRef)";
	
	SelectedFields = StrReplace(MeasurementText_, "<TableName>", "DataTable")
			+ StrReplace(TextOfPeriods, "<TableName>", "DataTable")
			+ StrReplace(AnalyticsText, "<TableName>", "DataTable");
	SelectedFields = TrimAll(SelectedFields);
	If StrEndsWith(SelectedFields, ",") Then
		SelectedFields = Mid(SelectedFields, 1, StrLen(SelectedFields) - 1);
	EndIf;
		
	For Each ResourceField In RequiredResources Do
		SelectedFields = SelectedFields + "," + Chars.LF + Chars.Tab
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"DataTable.%1 AS %1",
				ResourceField.ResourceName);
	EndDo;
	
	PackageRequest = StrReplace(PackageRequest, "&SelectedFields", SelectedFields);
	PackageRequest = StrReplace(PackageRequest, "&DataTableName", DataTableName);
	
	QueryText = QueryText + Chars.LF + PackageRequest;
	
	For Each NameString In SourceNames Do
		
		MergeText = "
		|
		|UNION ALL
		|
		|";
		
		PackageRequest =
		"SELECT
		|	DataTable.ID_Source1,
		|	DataTable.BudgetFlowItem,
		|	DataTable.BudgetBalanceItem,
		|	DataTable.EditedValue,
		|	DataTable.NonFinancialItem,
		|	DataTable.NFPIndex, 
		|	DataTable.DocumentData,
		|	&SelectedFields,
		|	DataTable.SerialNumber,
		|	DataTable.Note
		|
		|FROM &DataTableName AS DataTable
		|LEFT JOIN #NameOfDataPaddingTable AS PopulationTable
		|ON
		|	&ConnectionConditions
		|WHERE
		|	&FilterConditions";
		
		SelectedFields = StrReplace(MeasurementText_, "<TableName>", "DataTable")
				+ StrReplace(TextOfPeriods, "<TableName>", "DataTable")
				+ StrReplace(AnalyticsText, "<TableName>", "DataTable");
		
		ArrayOfDimensions_ = New Array;
		FillableNames = DimensionsNames.FindRows(New Structure("NonFinancialItem", NameString.NonFinancialItem));
		For Each FillString In FillableNames Do
			If NameString.TableMeasurements.Find(FillString.DimensionName) = Undefined Then
				Continue;
			EndIf;
			SelectedFields = StrReplace(SelectedFields,
			                                  "DataTable." + FillString.DimensionName,
			                                  "PopulationTable." + FillString.DimensionName);
			ArrayOfDimensions_.Add(FillString.DimensionName);
		EndDo;
		SelectedFields = TrimAll(SelectedFields);
		If StrEndsWith(SelectedFields, ",") Then
			SelectedFields = Mid(SelectedFields, 1, StrLen(SelectedFields) - 1);
		EndIf;
		For Each ResourceField In RequiredResources Do
			SelectedFields = SelectedFields + "," + Chars.LF + Chars.Tab
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"DataTable.%1",
					ResourceField.ResourceName);
		EndDo;
		
		PackageRequest = StrReplace(PackageRequest, "&SelectedFields", SelectedFields);
		PackageRequest = StrReplace(PackageRequest, "&DataTableName", DataTableName);
		PackageRequest = StrReplace(PackageRequest, "#NameOfDataPaddingTable", NameString.NameOfDataPaddingTable);
		
		ConnectionConditions = "";
		RemainingMeasurements = CommonClientServer.ArraysDifference(NameString.TableMeasurements, ArrayOfDimensions_);
		If Not RemainingMeasurements.Count() Then
			ConnectionConditions = "TRUE";
		Else
			First = True;
			For Each Dimension In RemainingMeasurements Do
				If Not First Then
					ConnectionConditions = ConnectionConditions + " " + "And" + " ";
				EndIf;
				If Dimension = "Currency" Then
					ConnectionConditions = ConnectionConditions + "CASE WHEN CAST(DataTable.NonFinancialItem AS Catalog.NonFinancialItemsOfBudgets).IndicatorKind = VALUE(Enum.NonFinancialItemKinds.Cash_)
					|		THEN DataTable." + Dimension + " = PopulationTable." + Dimension + "
					|		ELSE TRUE
					|	END
					|";
				ElsIf Dimension = "UnitOfMeasure" Then
					ConnectionConditions = ConnectionConditions + "CASE WHEN CAST(DataTable.NonFinancialItem AS Catalog.NonFinancialItemsOfBudgets).IndicatorKind = VALUE(Enum.NonFinancialItemKinds.Quantitative)
					|		THEN DataTable." + Dimension + " = PopulationTable." + Dimension + "
					|		ELSE TRUE
					|	END
					|";
				Else
					ConnectionConditions = ConnectionConditions + "DataTable." + Dimension + " = PopulationTable." + Dimension + "
					|";
				EndIf;
				First = False;
			EndDo;
		EndIf;
		
		FilterConditions = "DataTable.NonFinancialItem = &NFP_" + FinancialReportingCached.NameOfBudgetReportField(NameString.NonFinancialItem);
		PackageRequest = StrReplace(PackageRequest, "&ConnectionConditions", ConnectionConditions);
		PackageRequest = StrReplace(PackageRequest, "&FilterConditions", FilterConditions);
		
		QueryText = QueryText + MergeText + PackageRequest;
		
		NFPName = "NFP_" + FinancialReportingCached.NameOfBudgetReportField(NameString.NonFinancialItem);
		AuxiliaryData.QueryOptions.Insert(NFPName, NameString.NonFinancialItem);
		
	EndDo;
	
	QueryText = QueryText + "
	|
	|INDEX BY NonFinancialItem
	|;
	|";
	
	DataTableName = "DataTableWithCompletedAnalytics";
	
EndProcedure

Function Attachable_TableFromManager(Query, TableName, Order = "MinimumNumberInOrder, OperandCalculationProcedure") Export
	
	QueryText = 
	"SELECT * FROM &TableName";
	QueryText = StrReplace(QueryText, "&TableName", TableName);
	
	If Order <> Undefined Then
		QueryText = QueryText + "
		|ORDER BY 
		|	" + Order;
	EndIf;
	
	Query.Text = QueryText;
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure AddSourceToCellStructure(QueryText, DescriptionOfReport, AuxiliaryData, TableName, NameOfTableWithDimensions)
	
	BasicElements        = AuxiliaryData.BasicElements;
	BasicFlags           = AuxiliaryData.BasicFlags;
	MeasurementText_          = AuxiliaryData.MeasurementText_;
	TextDimensionFlags     = AuxiliaryData.TextDimensionFlags;
	AnalyticsText          = AuxiliaryData.AnalyticsText;
	TextAnalyticsFlags     = AuxiliaryData.TextAnalyticsFlags;
	TextAnalyst_3   = AuxiliaryData.TextAnalyst_3;
	TextOfPeriods           = AuxiliaryData.TextOfPeriods;
	TextFlagsPeriods      = AuxiliaryData.TextFlagsPeriods;
	TextConnection = AuxiliaryData.TextConnection;
	
	PackageRequest = 
	"SELECT 
	|	&SelectedFields,
	|	TableOfMeasurementSources.ID_Source1 AS ID_Source1,
	|	CellStructure.ExcludeDocumentData AS ExcludeDocumentData
	|
	|INTO StructureOfCellsWithSources
	|
	|FROM &NameOfTableWithDimensions AS CellStructure
	|
	|LEFT JOIN TableOfMeasurementSources
	|
	|ON CellStructure.String = TableOfMeasurementSources.String
	|	AND CellStructure.Column = TableOfMeasurementSources.Column
	|
	|WHERE CellStructure.MainItem AND
	|	CellStructure.ItemKind IN
	|		(	
	|		VALUE(Enum.FinancialReportItemKinds.DerivedItem),
	|		VALUE(Enum.FinancialReportItemKinds.GroupFormula),
	|		VALUE(Enum.FinancialReportItemKinds.Group)
	|		)
	|
	|UNION ALL
	|
	|SELECT 
	|	&SelectedFields,
	|	CellStructure.ID_Source1,
	|	CellStructure.ExcludeDocumentData
	|
	|FROM &TableName AS CellStructure
	|
	|WHERE (CellStructure.MainItem
	|			AND NOT CellStructure.ItemKind IN
	|			(	
	|			VALUE(Enum.FinancialReportItemKinds.DerivedItem),
	|			VALUE(Enum.FinancialReportItemKinds.GroupFormula),
	|			VALUE(Enum.FinancialReportItemKinds.Group)
	|			)
	|	)
	|	OR NOT CellStructure.MainItem
	|
	|INDEX BY ID_Source1";
	
	SelectedFields = StrReplace(BasicElements, "<TableName>", "CellStructure")
			+ StrReplace(BasicFlags, "<TableName>", "CellStructure")
			+ StrReplace(MeasurementText_, "<TableName>", "CellStructure")
			+ StrReplace(TextOfPeriods, "<TableName>", "CellStructure")
			+ StrReplace(AnalyticsText, "<TableName>", "CellStructure")
			+ StrReplace(TextDimensionFlags, "<TableName>", "CellStructure")
			+ StrReplace(TextFlagsPeriods, "<TableName>", "CellStructure")
			+ StrReplace(TextConnection, "<TableName>", "CellStructure")
			+ StrReplace(TextAnalyticsFlags, "<TableName>", "CellStructure")
			+ StrReplace(TextAnalyst_3, "<TableName>", "CellStructure");
	SelectedFields = TrimAll(SelectedFields);
	If StrEndsWith(SelectedFields, ",") Then
		SelectedFields = Mid(SelectedFields, 1, StrLen(SelectedFields) - 1);
	EndIf;
		
	PackageRequest = StrReplace(PackageRequest, "&SelectedFields", SelectedFields);
	PackageRequest = StrReplace(PackageRequest, "&NameOfTableWithDimensions", NameOfTableWithDimensions);
	PackageRequest = StrReplace(PackageRequest, "&TableName", TableName);
	
	QueryText = QueryText + Chars.LF + Chars.LF + PackageRequest + ";" + Chars.LF + Chars.LF;
	TableName = "StructureOfCellsWithSources";
	
EndProcedure

Function PrepareTableOfMeasurementValuesForParents(QueryText, CellStructure, AuxiliaryData)
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	ParametersOfOtherConnections = New Structure("Document, OtherItems", New Array, New Array);
	For Each Column In AuxiliaryData.AllDimensions Do
		
		If CellStructure.Find("otheritems", "Flag" + Column) <> Undefined Then
			ParametersOfOtherConnections.OtherItems.Add(Column);
		EndIf;
		
		If CellStructure.Find("document", "Flag" + Column) <> Undefined Then
			ParametersOfOtherConnections.Document.Add(Column);
		EndIf;
		
		SkippedColumns = New Array;
		SkippedColumns.Add("Organization");
		SkippedColumns.Add("Department");
		SkippedColumns.Add("Scenario");
		SkippedColumns.Add("Currency");
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			SkippedColumns.Add("Dimension" + Cnt);
		EndDo;
		
		If SkippedColumns.Find(Column) = Undefined Then
			If CellStructure.Find("fill", "Flag" + Column) <> Undefined Then
				ParametersOfOtherConnections.Document.Add(Column);
			EndIf;
		EndIf;
		
	EndDo;
	
	If Not ParametersOfOtherConnections.OtherItems.Count()
		And Not  ParametersOfOtherConnections.Document.Count() Then
		Return ParametersOfOtherConnections;
	EndIf;
	
	First = True;
	For Each Dimension In ParametersOfOtherConnections.OtherItems Do
		
		QueryText = QueryText + ?(First, "", " UNION ALL ") + "
		|SELECT DISTINCT Parent" + Dimension + " AS Parent, " + Dimension + " AS VALUE
		|" + ?(First, "INTO TableOfValuesByParent", "") + "
		|
		|FROM CellStructure
		|
		|WHERE NOT Parent" + Dimension + " = Value(Catalog.FinancialReportItems.EmptyRef) And
		|	CellStructure.Flag" + Dimension + " = ""pick""
		|
		|" + ?(ParametersOfOtherConnections.Document.Find("Dimension") <> Undefined, "
		|UNION ALL 
		|
		|SELECT DISTINCT CellStructure.Parent" + Dimension + ", DataTable." + Dimension + " FROM
		|
		| CellStructure
		|	LEFT JOIN DataTable ON CellStructure.ID_Source1 = DataTable.ID_Source1
		|
		| WHERE NOT Parent" + Dimension + " = VALUE(Catalog.FinancialReportItems.EmptyRef) AND
		|	CellStructure.ID_Source1 = ""Document"" AND CellStructure.Flag" + Dimension + " = ""document""
		|
		|", "");
		
		First = False;
		
	EndDo;
	
	If Not First Then
		QueryText = QueryText + " INDEX BY Parent
		|;";
	EndIf;
	
	First = True;
	For Each Dimension In ParametersOfOtherConnections.Document Do
		
		QueryText = QueryText + ?(First, "", " UNION ALL ") + "
		|SELECT DISTINCT Parent" + Dimension + " AS Parent, " + Dimension + " AS VALUE
		|" + ?(First, "INTO TableOfValuesByParentDocument", "") + "
		|
		|FROM CellStructure
		|
		|WHERE NOT Parent" + Dimension + " = Value(Catalog.FinancialReportItems.EmptyRef) And
		|	CellStructure.Flag" + Dimension + " = ""pick""
		|
		|";
		
		First = False;
		
	EndDo;
	
	If Not First Then
		QueryText = QueryText + " INDEX BY Parent
		|;";
	EndIf;
	
	Return ParametersOfOtherConnections;
	
EndFunction

Function PrepareCorrespondenceOfTypesOfAnalyticsToBudgetItemsAndIndicators(DimensionKinds, BudgetItemsAndIndicators_ = Undefined)
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators = New Map();
	
	BudgetFlowItems = Undefined;
	BudgetBalanceItems = Undefined;
	NonFinancialIndicators = Undefined;
	
	If Not BudgetItemsAndIndicators_ = Undefined Then
		BudgetItemsAndIndicators_.Property("BudgetFlowItems", BudgetFlowItems);
		BudgetItemsAndIndicators_.Property("BudgetBalanceItems", BudgetBalanceItems);
		BudgetItemsAndIndicators_.Property("NonFinancialIndicators", NonFinancialIndicators);
	EndIf;
	
	Query = New Query;
	RequestTemplateForArticles =
	"SELECT
		|	BudgetFlowItems.Ref AS BudgetFlowItem,
		|	BudgetFlowItems.DimensionKind1 AS DimensionKind,
		|	VALUE(Catalog.BudgetBalanceItems.EmptyRef) AS BudgetBalanceItem,
		|	VALUE(Catalog.NonFinancialItemsOfBudgets.EmptyRef) AS NonFinancialIndicatorOfBudgets
		|FROM
		|	Catalog.BudgetFlowItems AS BudgetFlowItems
		|WHERE
		|	BudgetFlowItems.Ref IN(&BudgetFlowItems)
		|	AND BudgetFlowItems.DimensionKind1 <> VALUE(ChartOfCharacteristicTypes.BudgetFlowItemDimensions.EmptyRef) " 
		+ ?(BudgetFlowItems = Undefined, "", " AND BudgetFlowItems.DimensionKind1 IN(&DimensionKinds)");
	
	QueryTemplateForIndicators =
	"SELECT
		|	VALUE(Catalog.BudgetBalanceItems.EmptyRef) AS Field1,
		|	BudgetBalanceItems.DimensionKind1,
		|	BudgetBalanceItems.Ref,
		|	VALUE(Catalog.NonFinancialItemsOfBudgets.EmptyRef) AS Field2
		|FROM
		|	Catalog.BudgetBalanceItems AS BudgetBalanceItems
		|WHERE
		|	BudgetBalanceItems.Ref IN(&BudgetBalanceItems)
		|	AND BudgetBalanceItems.DimensionKind1 <> VALUE(ChartOfCharacteristicTypes.BudgetFlowItemDimensions.EmptyRef) "
		+ ?(BudgetBalanceItems = Undefined, "", " AND BudgetBalanceItems.DimensionKind1 IN(&DimensionKinds)");
	
	RequestTemplateForNFP =
	"SELECT
		|	VALUE(Catalog.BudgetFlowItems.EmptyRef) AS Field1,
		|	NonFinancialItemsOfBudgets.DimensionKind1,
		|	VALUE(Catalog.BudgetBalanceItems.EmptyRef) AS Field2,
		|	NonFinancialItemsOfBudgets.Ref
		|FROM
		|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
		|WHERE
		|	NonFinancialItemsOfBudgets.Ref IN(&NonFinancialItemsOfBudgets)
		|	AND NonFinancialItemsOfBudgets.DimensionKind1 <> VALUE(ChartOfCharacteristicTypes.BudgetFlowItemDimensions.EmptyRef) "
		+ ?(NonFinancialIndicators = Undefined, "", " AND NonFinancialItemsOfBudgets.DimensionKind1 IN(&DimensionKinds)");
		
	QueryText = "";
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		QueryText = QueryText + StrReplace(RequestTemplateForArticles, "DimensionKind1", "DimensionKind" + Cnt) + " UNION ALL ";
	EndDo;
	
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		QueryText = QueryText + StrReplace(QueryTemplateForIndicators, "DimensionKind1", "DimensionKind" + Cnt) + " UNION ALL ";
	EndDo;
	
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		QueryText = QueryText + StrReplace(RequestTemplateForNFP, "DimensionKind1", "DimensionKind" + Cnt)
			+ ?(Cnt = MaximumNumberOfAnalysts, "", " UNION ALL ");
	EndDo;
	
	Query.Text = QueryText;
	
	Query.SetParameter("BudgetFlowItems", BudgetFlowItems);
	Query.SetParameter("BudgetBalanceItems", BudgetBalanceItems);
	Query.SetParameter("NonFinancialItemsOfBudgets", NonFinancialIndicators);
	Query.SetParameter("DimensionKinds" , DimensionKinds);
	
	Result = Query.Execute().Unload();
	
	For Each DimensionKind In DimensionKinds Do
		ArrayOfBudgetItems = New Array();
		ArrayOfBudgetIndicators = New Array();
		NFPArray = New Array();
		FilterParameters = New Structure();
		FilterParameters.Insert("DimensionKind",DimensionKind);
		Rows = Result.FindRows(FilterParameters);
		If Rows.Count() > 0 Then
			For Each Page1 In Rows Do
				If ValueIsFilled(Page1.BudgetFlowItem) Then
					ArrayOfBudgetItems.Add(Page1.BudgetFlowItem);
				EndIf;
				If ValueIsFilled(Page1.BudgetBalanceItem) Then
					ArrayOfBudgetIndicators.Add(Page1.BudgetBalanceItem);
				EndIf;
				If ValueIsFilled(Page1.NonFinancialIndicatorOfBudgets) Then
					NFPArray.Add(Page1.NonFinancialIndicatorOfBudgets);
				EndIf;
			EndDo;
		EndIf;
		
		ValuesOfKeyIndicators = New Structure();
		ValuesOfKeyIndicators.Insert("BudgetFlowItems", ArrayOfBudgetItems);
		ValuesOfKeyIndicators.Insert("BudgetBalanceItems", ArrayOfBudgetIndicators);
		ValuesOfKeyIndicators.Insert("NonFinancialIndicators", ArrayOfBudgetIndicators);
		
		ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators.Insert(DimensionKind, ValuesOfKeyIndicators);
	EndDo;
	
	Return ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators;
	
EndFunction

Procedure ConnectStructureToData(QueryText, DescriptionOfReport, AuxiliaryData, TableName, AuxiliaryParameters, GenerationMode)
	
	SourcesOfMeasurementValues = AuxiliaryParameters.SourcesOfMeasurementValues;
	DataTableName = AuxiliaryParameters.DataTableName;
	SourceFields_2 = AuxiliaryParameters.SourceFields_2;
	ParametersOfOtherConnections = AuxiliaryParameters.ParametersOfOtherConnections;
	ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators = AuxiliaryParameters.ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators;
	
	QueryText = StrReplace(QueryText, "//%IndexText_1%", "INDEX BY ID_Source1");
	TextOfPeriods = AuxiliaryData.TextOfPeriods;
	
	// Preparing the structure of cells with data
	PackageRequest =
	"SELECT 
	|	CASE WHEN CellStructure.FlagBudgetFlowItem = ""Fill"" THEN
	|		DataTable.BudgetFlowItem
	|	ELSE
	|		CellStructure.BudgetFlowItem
	|	END AS BudgetFlowItem,
	|	CASE WHEN CellStructure.FlagBudgetBalanceItem = ""Fill"" THEN
	|		DataTable.BudgetBalanceItem
	|	ELSE
	|		CellStructure.BudgetBalanceItem
	|	END AS BudgetBalanceItem,
	|	CellStructure.RowIndex,
	|	CellStructure.NonFinancialItem,
	|	CellStructure.EditedValue,
	|	CellStructure.MainItem,
	|	CellStructure.ItemKind,
	|	CellStructure.CalculationFilling,
	|	CellStructure.OperandType,
	|	CellStructure.String,
	|	CellStructure.Column,
	|	CellStructure.OperandCalculationProcedure,
	|	&SelectingFields
	|FROM
	|	&TableNameCellStructure AS CellStructure
	|
	|LEFT JOIN
	|	#DataTableName AS DataTable
	|
	|	ON CellStructure.ID_Source1 = DataTable.ID_Source1
	|	AND CASE
	|		WHEN CellStructure.ExcludeDocumentData
	|			THEN NOT DataTable.DocumentData
	|		ELSE TRUE
	|	END
	|	AND &ConditionsForJoiningTables
	|
	|WHERE
	|	&SelectionExpression
	|";
	
	FieldSelectionText = "";
	For Each Dimension In DescriptionOfReport.Dimensions Do
		If Dimension = "UnitOfMeasure" Then
			FieldSelectionText = FieldSelectionText + ?(FieldSelectionText = "", "", "," + " " + Chars.LF)
					+ 	"	CASE WHEN COUNT(DISTINCT
						|			ISNULL(DataTable.UnitOfMeasure, CellStructure.UnitOfMeasure)
						|		) > 1 THEN UNDEFINED ELSE 
						|		MAX(ISNULL(DataTable.UnitOfMeasure, CellStructure.UnitOfMeasure))
						|	END AS UnitOfMeasure";
		ElsIf Dimension = "Currency" Then
			FieldSelectionText = FieldSelectionText + ?(FieldSelectionText = "", "", "," + " " + Chars.LF)
					+ 	"	CASE 
						|	WHEN CellStructure.Currency = VALUE(Catalog.Currencies.EmptyRef) AND
						|		CellStructure.CalculationFilling <> ""Total"" AND
						|		COUNT(DISTINCT
						|			CASE 
						|				WHEN ISNULL(DataTable.ID_Source1, """") = ""Document""
						|						OR (CellStructure.FlagCurrency = ""Fill"" AND NOT DataTable.Currency IS NULL)
						|				THEN DataTable.Currency 
						|			END
						|		) = 1 THEN 
						|			MAX(CASE 
						|				WHEN ISNULL(DataTable.ID_Source1, """") = ""Document""
						|						OR (CellStructure.FlagCurrency = ""Fill"" AND NOT DataTable.Currency IS NULL)
						|				THEN DataTable.Currency 
						|			END)
						|	ELSE
						|		CellStructure.Currency
						|	END AS Currency";
		Else
			TemplateTextMeasurement = 
			"	CASE WHEN (CellStructure.Flag%1 = ""Fill"")
			|			AND NOT DataTable.%1 IS NULL THEN
			|		DataTable.%1
			|	ELSE
			|		CellStructure.%1
			|	END AS %1";
			FieldSelectionText = FieldSelectionText + ?(FieldSelectionText = "", "", "," + " " + Chars.LF)
					+ StringFunctionsClientServer.SubstituteParametersToString(TemplateTextMeasurement, Dimension);
		EndIf;
	EndDo;
	
	FieldSelectionText = StrReplace(TextOfPeriods, "<TableName>", "CellStructure") + Chars.LF + FieldSelectionText;
	
	For Each Dimension In DescriptionOfReport.DimensionKinds Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		TemplateTextMeasurement =
		"	CASE WHEN (CellStructure.Flag%1 = ""Fill""
		|		OR CellStructure.Flag%1 = ""Document"")
		|			AND NOT DataTable.%1 IS NULL THEN
		|		DataTable.%1
		|	ELSE
		|		CellStructure.%1
		|	END AS %1";
		FieldSelectionText = FieldSelectionText + ?(FieldSelectionText = "", "", "," + " " + Chars.LF)
					+ StringFunctionsClientServer.SubstituteParametersToString(TemplateTextMeasurement, FieldName);
	EndDo;
	
	For Each ResourceField In SourceFields_2.FindRows(New Structure("Auxiliary_", False)) Do
		If StrFind(ResourceField.ResourceName, "Sum") Then
			ResourceTemplateText =
			"	SUM(ISNULL(DataTable.%1, 0)) AS %1";
			FieldSelectionText = FieldSelectionText + ?(FieldSelectionText = "", "", "," + " " + Chars.LF)
					+ StringFunctionsClientServer.SubstituteParametersToString(ResourceTemplateText, ResourceField.ResourceName);
		ElsIf StrFind(ResourceField.ResourceName, "Count") Then
			ResourceTemplateText =
			"	CASE WHEN COUNT(DISTINCT CellStructure.UnitOfMeasure) = 1 THEN
			|		SUM(ISNULL(DataTable.%1, 0)) ELSE 0 END AS %1";
			FieldSelectionText = FieldSelectionText + ?(FieldSelectionText = "", "", "," + " " + Chars.LF)
					+ StringFunctionsClientServer.SubstituteParametersToString(ResourceTemplateText, ResourceField.ResourceName);
		ElsIf StrFind(ResourceField.ResourceName, "IndicatorValue") Then
			FieldSelectionText = FieldSelectionText + ?(FieldSelectionText = "", "", "," + " " + Chars.LF)
					+ 	"	CASE WHEN CellStructure.MainItem THEN
						|		CASE
						|			WHEN COUNT(DISTINCT DataTable.NFPIndex) <= 1 THEN
						|				MAX(ISNULL(DataTable.IndicatorValue, 0))
						|			ELSE
						|				""#Val_"" 
						|		END
						|	ELSE
						|		MAX(ISNULL(DataTable.IndicatorValue, 0))
						|	END AS IndicatorValue";
		EndIf;
	EndDo;
	
	FieldSelectionText = FieldSelectionText + ?(FieldSelectionText = "", "", "," + " " + Chars.LF)
		+ 	"	MIN(DataTable.SerialNumber) AS MinimumNumberInOrder,
			|	MAX(DataTable.Note),
			|	FALSE AS CalculatedSum,
			|	FALSE AS CalculatedSumCurr,
			|	FALSE AS CalculatedCount,
			|	FALSE AS CalculatedValue,
			|	MAX(CASE WHEN DataTable.ID_Source1 IS NULL THEN 
			|		FALSE
			|	ELSE
			|		TRUE
			|	END) AS DataStringIsMatched";
	
	PackageRequest = StrReplace(PackageRequest, "&SelectingFields", FieldSelectionText);
	PackageRequest = StrReplace(PackageRequest, "&TableNameCellStructure", TableName);
	PackageRequest = StrReplace(PackageRequest, "#DataTableName", DataTableName);
	
	ConditionsForJoiningTables = "";
	
	For Each Periodicity In DescriptionOfReport.Periodicity_ Do
		
		PeriodStrings = FinancialReportingClientServer.PeriodStrings(Periodicity);
		
		ConditionsForJoiningTables = ConditionsForJoiningTables + ?(ConditionsForJoiningTables = "", "", " " + Chars.LF + Chars.LF + "And" + " ")
			+ StrTemplate(
				"	(CellStructure.%1 = ""Pick""
				|		AND CellStructure.%2 = DataTable.%3
				|		OR
				|		CellStructure.%1 <> ""Pick""
				|			AND DataTable.%3 = UNDEFINED)",
				PeriodStrings.FlagPeriod, PeriodStrings.PeriodConnection, PeriodStrings.Period);
	EndDo;
	
	ConditionsForJoiningTables = ConditionsForJoiningTables + ?(ConditionsForJoiningTables = "", "", " " + Chars.LF + Chars.LF + "And" + " ")
		+ 	"(NOT CellStructure.FlagBudgetFlowItem = ""Pick""
			|		OR CellStructure.BudgetFlowItem = DataTable.BudgetFlowItem)
			|
			|	AND (NOT CellStructure.FlagBudgetBalanceItem = ""Pick""
			|		OR CellStructure.BudgetBalanceItem = DataTable.BudgetBalanceItem)
			|	
			|	AND (NOT CellStructure.FlagNonFinancialItem = ""Pick""
			|		OR CellStructure.NonFinancialItem = DataTable.NonFinancialItem)
			|
			|	AND (NOT CellStructure.FlagEditedValue = ""Pick""
			|		OR CellStructure.EditedValue = DataTable.EditedValue)";
		
	For Each Dimension In DescriptionOfReport.Dimensions Do
		If Dimension = "UnitOfMeasure" Then
			Continue;
		EndIf;
		
		// NPOs may not be accounted for by organizations, divisions, scenarios
		If Dimension = "Scenario" 
			And GenerationMode = Enums.ModesOfBudgetReportGeneration.Report Then
			ConnectionStringPattern =
			"(CellStructure.Flag%1 = ""Fill""
			|		OR CellStructure.Flag%1 = ""Pick"" AND (CellStructure.%1 = DataTable.%1 OR NOT DataTable.NFP_SelectionScenario))";
			
			ConditionsForJoiningTables = ConditionsForJoiningTables + ?(ConditionsForJoiningTables = "", "", " " + Chars.LF + Chars.LF + "And" + " ")
				+ StringFunctionsClientServer.SubstituteParametersToString(
					ConnectionStringPattern,
					Dimension);
		Else
			If Dimension = "Organization" Then
				ConnectionStringPattern =
				"(NOT CellStructure.Flag%1 = ""Pick""
				|		OR (CellStructure.%1 = DataTable.%1 OR NOT DataTable.NFP_SelectionCompany))";
			ElsIf Dimension = "Department" Then
				ConnectionStringPattern =
				"(NOT CellStructure.Flag%1 = ""Pick""
				|		OR (CellStructure.%1 = DataTable.%1 OR NOT DataTable.NFP_SelectionDivision))";
			Else
				ConnectionStringPattern =
				"(NOT CellStructure.Flag%1 = ""Pick""
				|		OR CellStructure.%1 = DataTable.%1)";
			EndIf;
			
			ConditionsForJoiningTables = ConditionsForJoiningTables + ?(ConditionsForJoiningTables = "", "", " " + Chars.LF + Chars.LF + "And" + " ")
				+ StringFunctionsClientServer.SubstituteParametersToString(
					ConnectionStringPattern,
					Dimension);
		EndIf;
	EndDo;
	
	For Each Dimension In DescriptionOfReport.DimensionKinds Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		
		ConnectionStringByDimension = "";
		If ParametersOfOtherConnections.Document.Find(FieldName) <> Undefined Then
			ConnectionStringPattern =
			"	
			|	AND ( (CellStructure.Flag%1 = ""Fill"" 
			|		AND NOT DataTable.%1 IN 
			|							(SELECT TableOfValuesByParentDocument.Value FROM TableOfValuesByParentDocument
			|							WHERE TableOfValuesByParentDocument.Parent = CellStructure.Parent%1)
			|		)
			|";
			
			ConnectionStringByDimension = ConnectionStringByDimension
				+ StringFunctionsClientServer.SubstituteParametersToString(
					ConnectionStringPattern,
					FieldName);
		Else
			ConnectionStringByDimension = ConnectionStringByDimension
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"
					|	AND (	CellStructure.Flag%1 = ""Fill""
					|",
					FieldName);
		EndIf;
		
		If ParametersOfOtherConnections.Document.Find(FieldName) <> Undefined Then
			ConnectionStringByDimension = ConnectionStringByDimension
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"
					|		OR	(CellStructure.Flag%1 = ""Document""
					|				AND NOT DataTable.%1 IN 
					|							(SELECT TableOfValuesByParentDocument.Value FROM TableOfValuesByParentDocument
					|							WHERE TableOfValuesByParentDocument.Parent = CellStructure.Parent%1)
					|	)
					|",
					FieldName);
		EndIf;
		
		If GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType Then
			ConnectionStringByDimension = ConnectionStringByDimension
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"
					|	OR (CellStructure.Flag%1 = ""Pick"" AND
					|				(CellStructure.%1 = DataTable.%1
					|					OR ((CellStructure.CalculationFilling = ""FillType""
					|						OR CellStructure.FlagNonFinancialItem = ""Pick""
					|						AND CellStructure.NonFinancialItem = DataTable.NonFinancialItem)
					|						AND DataTable.%1 = UNDEFINED
					|						AND NOT DataTable.BudgetFlowItem IN (&BudgetItemsBy_%1)
					|						AND NOT DataTable.BudgetBalanceItem IN (&BudgetIndicatorsFor_%1)
					|						AND NOT DataTable.NonFinancialItem IN (&NFPSoftware_%1))))
					|",
					FieldName);
		Else
			ConnectionStringByDimension = ConnectionStringByDimension
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"
					|	OR (CellStructure.Flag%1 = ""Pick"" AND
					|				(CellStructure.%1 = DataTable.%1
					|				OR CellStructure.FlagNonFinancialItem = ""Pick""
					|				AND CellStructure.NonFinancialItem = DataTable.NonFinancialItem
					|				AND DataTable.%1 = UNDEFINED))
					|",
					FieldName);
		EndIf;
		
		If GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType 
			And Not ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators = Undefined Then
			
			AuxiliaryData.QueryOptions.Insert("BudgetItemsBy_" + FieldName, 
				ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators.Get(Dimension)["BudgetFlowItems"]);
			AuxiliaryData.QueryOptions.Insert("BudgetIndicatorsFor_" + FieldName, 
				ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators.Get(Dimension)["BudgetBalanceItems"]);
			AuxiliaryData.QueryOptions.Insert("NFPSoftware_" + FieldName, 
				ComplianceOfTypesOfAnalyticsWithBudgetItemsAndIndicators.Get(Dimension)["NonFinancialIndicators"]);
		EndIf;
		If ParametersOfOtherConnections.OtherItems.Find(FieldName) <> Undefined Then
			ConnectionStringByDimension = ConnectionStringByDimension
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"
					|		OR ( CellStructure.Flag%1 = ""OtherItems"" 
					|				AND NOT DataTable.%1 IN 
					|							(SELECT TableOfValuesByParent.Value 
					|							 FROM TableOfValuesByParent 
					|							 WHERE TableOfValuesByParent.Parent = CellStructure.Parent%1)
					|			)
					|",
					FieldName);
		EndIf;
		ConnectionStringByDimension = ConnectionStringByDimension
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"
					|		OR CellStructure.Flag%1 = """")
					|",
					FieldName);
					
		ConditionsForJoiningTables = ConditionsForJoiningTables + ConnectionStringByDimension;
	EndDo;
	
	PackageRequest = StrReplace(PackageRequest, "&ConditionsForJoiningTables", ConditionsForJoiningTables);
	SelectionExpression = "";
	If GenerationMode = Enums.ModesOfBudgetReportGeneration.Report Then
		ArrayOfStringsForConditionsToAdd = New Array;
		TemplateForTextOfConditionsForHidingEmptyAnalytics = " 
		|	CASE WHEN CellStructure.MainItem AND DataTable.ID_Source1 IS NULL 
		|	THEN %ConditionsToAdd%
		|	ELSE TRUE 
		|	END";
		
		For Each Dimension In DescriptionOfReport.DimensionKinds Do
			FieldName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
			ConditionToAdd = "(NOT CellStructure.Flag" + FieldName + " = ""Fill"" OR CellStructure." + FieldName + " <> %EmptyValue%)";
				
			EmptyValueString = BudgetingServer.ExpressingEmptyValue();
			
			ConditionToAdd = StrReplace(ConditionToAdd, "%EmptyValue%", EmptyValueString);
			ArrayOfStringsForConditionsToAdd.Add(ConditionToAdd);
		EndDo;
		
		If ArrayOfStringsForConditionsToAdd.Count() > 0 Then
			StringOfConditionsToAdd = StrConcat(ArrayOfStringsForConditionsToAdd, Chars.LF + "And ");
			StringOfConditionsToAdd = "(" + StringOfConditionsToAdd + ") OR (&ReportGenerationMode AND &EmptyDataTable_)";
			
			SelectionExpression = StrReplace(TemplateForTextOfConditionsForHidingEmptyAnalytics, "%ConditionsToAdd%", StringOfConditionsToAdd);
		EndIf;
	EndIf;
	If IsBlankString(SelectionExpression) Then
		SelectionExpression = "TRUE";
	EndIf;
	PackageRequest = StrReplace(PackageRequest, "&SelectionExpression", SelectionExpression);
	
	PackageRequest = PackageRequest + "
	|
	|GROUP BY
	|	CASE WHEN CellStructure.FlagBudgetFlowItem = ""Fill"" THEN
	|		DataTable.BudgetFlowItem
	|	ELSE
	|		CellStructure.BudgetFlowItem
	|	END,
	|	CASE WHEN CellStructure.FlagBudgetBalanceItem = ""Fill"" THEN
	|		DataTable.BudgetBalanceItem
	|	ELSE
	|		CellStructure.BudgetBalanceItem
	|	END,
	|	CellStructure.NonFinancialItem,
	|	CellStructure.EditedValue,
	|	CellStructure.MainItem,
	|	CellStructure.RowIndex,
	|	CellStructure.ItemKind,
	|	CellStructure.OperandType,
	|	CellStructure.CalculationFilling,
	|	CellStructure.String,
	|	CellStructure.Column,
	|	CellStructure.OperandCalculationProcedure," + ?(SourceFields_2.Find("IndicatorValue") <> Undefined, "
	|	CASE WHEN NOT CellStructure.MainItem
	|		AND CellStructure.OperandType = VALUE(Enum.FinancialReportItemKinds.NonFinancialItem) THEN
	|		DataTable.NFPIndex
	|	END,", "");
	
	For Each Dimension In DescriptionOfReport.Dimensions Do
		If Dimension = "UnitOfMeasure" Then
			Continue;
		ElsIf Dimension = "Currency" Then
			PackageRequest = PackageRequest + "CellStructure.Currency, ";
		Else
			PackageRequest = PackageRequest + "
			|	CASE WHEN CellStructure.Flag" + Dimension + " = ""Fill""
			|		AND NOT DataTable." + Dimension + " IS NULL THEN
			|		DataTable." + Dimension + "
			|	ELSE
			|		CellStructure." + Dimension + "
			|	END,
			|";
		EndIf;
	EndDo;
	
	For Each Dimension In DescriptionOfReport.DimensionKinds Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		PackageRequest = PackageRequest + "
		|	CASE WHEN (CellStructure.Flag" + FieldName + " = ""Fill""
		|		OR CellStructure.Flag" + FieldName + " = ""Document"")
		|		AND NOT DataTable." + FieldName + " IS NULL THEN
		|		DataTable." + FieldName + "
		|	ELSE
		|		CellStructure." + FieldName + "
		|	END,
		|";
	EndDo;
	
	For Each Periodicity In DescriptionOfReport.Periodicity_ Do
		PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		PackageRequest = PackageRequest + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"	CellStructure.%1,",
				PeriodName);
	EndDo;
	
	QueryText = QueryText + Chars.LF + Chars.LF + PackageRequest;
	QueryText = TrimAll(QueryText);
	QueryText = Left(QueryText, StrLen(QueryText) - 1);
	
	If SourcesOfMeasurementValues.Count() Then
		QueryText = RequestSchemes.SetRoomToTemporaryTable(QueryText, "StructureOfDataCells");
	EndIf;
	
	If SourcesOfMeasurementValues.Count() Then
		
		QueryText = QueryText + "
		| INDEX BY STRING, Column" + ?(AuxiliaryData.AllDimensions.Count(), ", ", "") + 
			StrConcat(AuxiliaryData.AllDimensions, ",");
			
		TableName = "StructureOfDataCells";
		
	Else
		
		QueryText = QueryText + "
			|ORDER BY RowIndex";
		
	EndIf;
	
EndProcedure

Procedure PerformMeasurementFilterByValueSources(QueryText, SourcesOfMeasurementValues, TableName, DataTableName)
	
	If Not SourcesOfMeasurementValues.Count() Then
		Return;
	EndIf;
	
	FinalRequestText = 
	"SELECT * FROM &SourceTableName AS Table
	| WHERE Table.MainItem = FALSE
	|
	|UNION ALL
	|
	|SELECT * FROM &SourceTableName AS Table
	|WHERE Table.MainItem = TRUE
	|	AND &FinalTableConditionText
	|";
	FinalRequestText = StrReplace(FinalRequestText, "&SourceTableName", TableName);
	FinalTableConditionText = "(NOT DataStringIsMatched OR EditedValue <> """" OR (
	|		TRUE";
	
	ArrayOfDimensions_ = CommonClientServer.CollapseArray(SourcesOfMeasurementValues.UnloadColumn("Dimension"));
	FilterTextsByDimensions = New Array;
	TextUnion = "
	|
	|UNION ALL
	|
	|";
	For Each Dimension In ArrayOfDimensions_ Do
		
		If SourcesOfMeasurementValues.FindRows(New Structure("ID_Source1, Dimension", "AllItems", Dimension)).Count() Then
			Continue;
		EndIf;
		
		FilterTextByDimensions = 
		"SELECT DISTINCT
		|	TableOfSources.String AS String,
		|	TableOfSources.Column AS Column,
		|	&MeasurementColumn AS Value
		|FROM
		|	TableOfMeasurementSourcesWithDimensionName AS TableOfSources
		|LEFT JOIN #DataTableName AS DataTable
		|ON
		|	TableOfSources.ID_Source1 = DataTable.ID_Source1
		|	AND (TableOfSources.BudgetBalanceItem = DataTable.BudgetBalanceItem
		|		OR (CAST(DataTable.BudgetBalanceItem AS Catalog.BudgetBalanceItems).IndicatorType = VALUE(Enum.BudgetBalanceItemType.SpecialPurpose)
		|			AND TableOfSources.BudgetFlowItem = DataTable.BudgetBalanceItem))
		|	AND (TableOfSources.BudgetFlowItem = DataTable.BudgetFlowItem
		|		OR TableOfSources.BudgetBalanceItem <> VALUE(Catalog.BudgetBalanceItems.EmptyRef))
		|	AND TableOfSources.NonFinancialItem = DataTable.NonFinancialItem
		|	AND TableOfSources.EditedValue = DataTable.EditedValue
		|
		|WHERE
		|	&IserizationCondition";
		IserizationCondition = StringFunctionsClientServer.SubstituteParametersToString(
			"TableOfSources.Dimension = ""%1""",
			Dimension);
		FilterTextByDimensions = StrReplace(FilterTextByDimensions, "&MeasurementColumn", "DataTable." + Dimension);
		FilterTextByDimensions = StrReplace(FilterTextByDimensions, "#DataTableName", DataTableName);
		FilterTextByDimensions = StrReplace(FilterTextByDimensions, "&IserizationCondition", IserizationCondition);
		
		FilterTextsByDimensions.Add(FilterTextByDimensions);
		
		FinalTableConditionText = FinalTableConditionText + " "
				+ StringFunctionsClientServer.SubstituteParametersToString("AND (
						|NOT (STRING, Column, """ + Dimension + """" + ") IN (SELECT STRING, Column, Dimension FROM TableOfMeasurementSourcesWithDimensionName)
						|OR (STRING, Column, " + Dimension + ") IN (SELECT STRING, Column, VALUE FROM MeasurementFilterTable)
						| )",
						Dimension)
				+ " ";
		
	EndDo;
	
	FilterText = StrConcat(FilterTextsByDimensions, TextUnion);
	If FilterText <> "" Then
		
		QuerySchema = New QuerySchema();
		QuerySchema.SetQueryText(FilterText);
		Package = QuerySchema.QueryBatch.Get(0);
		Package.PlacementTable = "MeasurementFilterTable";
		Package.Index.Add("String");
		Package.Index.Add("Column");
		Package.Index.Add("Value");
		
		FilterText = QuerySchema.GetQueryText();
		
		QueryText = QueryText + ";
		|
		|" + FilterText;
	EndIf;
	
	FinalRequestText = StrReplace(FinalRequestText, "&FinalTableConditionText", FinalTableConditionText);
	
	QueryText = QueryText + ";
		|
		|" + FinalRequestText + ") )";
	
EndProcedure

// Returns a table of budget cell data.
// 
// Parameters:
// 	DescriptionOfReport - See BudgetReportingCacheCalculationServer.ColumnsOfDataTable_
// 	DataParameters - Structure - LongDesc:
// 	*Organization - CatalogRef.Companies -
// 	*Department - CatalogRef.BusinessStructure -
// 	*Currency - CatalogRef.Currencies -
// 	*Scenario - CatalogRef.BudgetingScenarios -
// 	*Document - DocumentRef.BudgetEntryForm -
// 	*BudgetFlowItemsDimension - ValueTable -
// 	*BudgetFlowItemTurnovers - ValueTable -
// 	*DimensionValues_ - ValueTable -
// 	*UpdateDate - Date -
// 	*ScenarioCurrency - CatalogRef.Currencies -
// 	*Status - ValueList of EnumRef.PlanStatuses -
// 	*BudgetProfile - CatalogRef.BudgetProfiles -
// 	*BudgetProfileDisplayParameters - Structure -
// 	*CellData_ - ValueTable -
// 	*Key_GUID - Arbitrary -
// 	*AdditionalFiltersForAnalytics - Structure -
// 	*UseToEnterPlan - Boolean -
// 	*Details - Undefined, Map -
// 	*ItemParameterCache - Undefined, Map -
// 	*GenerationMode - EnumRef.ModesOfBudgetReportGeneration -
// 	CellStructureSettings - See BudgetReportingCacheCalculationServer.DescriptionOfReport
// 	SourceData_ - ValueTable - Planned and actual data, as well as data entered in the Cur document:
// 	*BudgetFlowItem - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems - Budget item or target.
// 	*BudgetBalanceItem - CatalogRef.BudgetBalanceItems - Budget indicator (calculated or target).
// 	*NonFinancialItem - CatalogRef.NonFinancialItemsOfBudgets - Non-financial indicator.
// 	*EditedValue - String - Name of the cell of the value to edit.
// 	*DocumentData - Boolean - True if these are strings entered in the current document.
// 	GenerationMode - EnumRef.ModesOfBudgetReportGeneration - LongDesc
// 	DataCache - Undefined - LongDesc
// Returns:
// 	ValueTable - contains including:
// 		*String - CatalogRef.FinancialReportItems - Budget line.
// 		*Column - CatalogRef.FinancialReportItems - Budget line.
// 		*RowIndex - Number - Row index.
// 		*BudgetFlowItem - CatalogRef.BudgetFlowItems, CatalogRef.BudgetBalanceItems - Budget item or target.
// 		*BudgetBalanceItem - CatalogRef.BudgetBalanceItems - Budget indicator (calculated or target).
// 		*NonFinancialItem - CatalogRef.NonFinancialItemsOfBudgets - Non-financial indicator.
// 		*EditedValue - String - Name of the cell of the value to edit.
// 		*MainItem - Boolean - If true, it is output to the budget, if false, it is used to calculate the values in the main cells.
// 		*ItemKind - EnumRef.FinancialReportItemKinds - Type of element.
// 		*CalculationFilling - String - Option for calculating / filling the cell.
// 		*OperandType - EnumRef.FinancialReportItemKinds - The type of the operand.
// 		*OperandCalculationProcedure - Number - the calculation of the operand.
// 		*MinimumNumberInOrder - Number - minimum number in order.
// 		*Note - String - Note.
// 		*Period - Date - Period of cell data.
// 		*Currency - CatalogRef.Currencies - Currency of the sum values.
// 		*UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - Unit of measurement for quantitative values.
// 		*Count - Number - Quantity.
// 		*CountTurnover - Number - Number of revolutions.
// 		*Sum - Number - The amount.
// 		*SumTurnover - Number - The amount of turnover.
// 		*SumCurr - Number - The value of the currency.
// 		*SumCurrTurnover - Number - The amount of currency turnover.
// 		*Value - Number - Value of the non-financial indicator.
// 		*AreaNameCount - String - Name of the area in the table document.
// 		*AreaNameSum - String - Name of the area in the table document.
// 		*CalculatedCount - Boolean - flag for calculating the quantity using the formula.
// 		*CalculatedSum - Boolean - flag for calculating the amount using the formula.
// 		*CalculatedValue - Boolean - flag for calculating the value for a non-financial indicator using the formula.
// 		*DataStringIsMatched - Boolean - Flag for matching a table row and a row in a table budget document.
//
Function CellData_(DescriptionOfReport,
					DataParameters,
					CellStructureSettings,
					SourceData_,
					GenerationMode,
					DataCache) Export
	
	BeginOfPeriod = DataParameters.BeginOfPeriod;
	EndOfPeriod = DataParameters.EndOfPeriod;
	ActualDataLimit = DataParameters.ActualDataLimit;
	
	AuxiliaryData = AuxiliaryCellDataCalculationData(DataParameters,
			DescriptionOfReport,
			CellStructureSettings,
			DataCache,
			GenerationMode);
	
	SourcesOfMeasurementValues = CellStructureSettings.SourcesOfMeasurementValues;
	CellStructure = CellStructureSettings.CellStructure; // ValueTable -
	PeriodsTable = AuxiliaryData.PeriodsTable;
	QueryOptions = AuxiliaryData.QueryOptions;
	QueryText = AuxiliaryData.QueryText;
	
	Query = New Query();
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	If CellStructure.Columns.Find("ExcludeEnteredDocumentDataDuringCalculation") = Undefined Then
		CellStructure.Columns.Add("ExcludeEnteredDocumentDataDuringCalculation", New TypeDescription("Boolean"));
	EndIf;
	If SourceData_.Columns.Find("DocumentData") = Undefined Then
		SourceData_.Columns.Add("DocumentData", New TypeDescription("Boolean"));
	EndIf;
	
	Query.SetParameter("CellStructure", CellStructure);
	Query.SetParameter("DataTable", SourceData_);
	Query.SetParameter("PeriodsTable", PeriodsTable);
	Query.SetParameter("TableOfMeasurements", SourcesOfMeasurementValues);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("ActualDataLimit", ActualDataLimit);
	Query.SetParameter("ReportGenerationMode", GenerationMode = Enums.ModesOfBudgetReportGeneration.Report);
	Query.SetParameter("EmptyDataTable_", SourceData_.Count() = 0);
	If DataParameters.Property("BaseLines") Then
		Query.SetParameter("BaseLines", DataParameters.BaseLines);
	EndIf;
	For Each KeyAndValue In QueryOptions Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	Table = QueryResult.Unload();
	
	Table.Columns.Add("Sum", CurrencyRateOperations.MoneyFieldTypeDescription());
	Table.Columns.Add("SumCurr", CurrencyRateOperations.MoneyFieldTypeDescription());
	Table.Columns.Add("Count", Common.TypeDescriptionNumber(15,3));
	Table.Columns.Add("Value");
	
	Table.Columns.Add("AreaNameSum");
	Table.Columns.Add("AreaNameCount");
	Table.Columns.Add("AreaNameValue");
	
	Table.Columns.Add("AreaNameSumHierarchy");
	Table.Columns.Add("AreaNameQuantityHierarchy");
	Table.Columns.Add("AreaNameValueHierarchy");
	Table.Columns.Add("HierarchyOutput", New TypeDescription("Boolean"));
	
	Table.Indexes.Add("String, Column, MainItem, OperandType");
	Table.Indexes.Add("String, Column, MainItem");
	
	Table.Sort("String, Column, MainItem, OperandType, RowIndex");
	
	Table.Columns.Add("FilterCells");
	
	For Each IndexOf In CellStructureSettings.CellStructureIndexes Do
		Table.Indexes.Add(IndexOf + ", String, Column, MainItem");
	EndDo;
	
	Return Table;
	
EndFunction

#EndRegion

#Region OutputDataToReport_

Function PlannedCourseAccordingToCourseTable(RateTable, Currency, Period, Scenario)
	
	If Period = Undefined Then
		TheStructureOfTheSearch = New Structure("Currency, Scenario", Currency, Scenario);
	Else
		TheStructureOfTheSearch = New Structure("Currency, Scenario, Period", Currency, Scenario, Period);
	EndIf;
	
	ExRates = RateTable.FindRows(TheStructureOfTheSearch);
	
	If Not ExRates.Count() And Period = Undefined Then
		Return 0;
	ElsIf Not ExRates.Count() Then
		
		TheStructureOfTheSearch = New Structure("Currency, Scenario", Currency, Scenario);
		FoundRows = RateTable.FindRows(TheStructureOfTheSearch);
		
		If Not FoundRows.Count() Then
			Return 0;
		EndIf;
		
		For Cnt = 1 To FoundRows.Count() Do
			RowIndex = FoundRows.Count() - Cnt;
			If FoundRows[RowIndex].Period < Period Then
				Return FoundRows[RowIndex].Rate;
			EndIf;
		EndDo;
		
	Else
		Return ExRates[0].Rate;
	EndIf;
	
EndFunction

Function Attachable_ConvertAtRate(Sum, Period, StorageCurrency, Scenario,
											CacheOfScheduledCourses,
											CacheAnalystValues,
											DimensionValue,
											AddressInAnalytics) Export
	
	Currency = Attachable_ValueFromAnalytics(CacheAnalystValues, DimensionValue, AddressInAnalytics, StorageCurrency);
	
	If Currency = StorageCurrency Then
		Return Sum;
	EndIf;
	
	StorageCurrencyRate = PlannedCourseAccordingToCourseTable(CacheOfScheduledCourses, StorageCurrency, Period, Scenario);
	CurrencyExchangeRate = PlannedCourseAccordingToCourseTable(CacheOfScheduledCourses, Currency, Period, Scenario);
	
	If CurrencyExchangeRate = 0 Then
		Return 0;
	EndIf;
	
	Return Sum * StorageCurrencyRate / CurrencyExchangeRate;
	
EndFunction

Function Attachable_ValueFromAnalytics(CacheAnalystValues,
						DimensionValue,
						AddressInAnalytics,
						DefaultValue = Undefined) Export
	
	If Not ValueIsFilled(DimensionValue)
		Or TypeOf(DimensionValue) = Type("String") Then
		
		Return DefaultValue;
		
	EndIf;
	
	AttributesStructure1 = CacheAnalystValues[DimensionValue];
	If AttributesStructure1 = Undefined Then
		Try
			// If they change the order or composition of the analysts in the article
			// , there may be a link in the data to an element of the directory type
			// that does not have a specified field.
			ValueResult = DimensionValue[AddressInAnalytics];
		Except
			
			Return DefaultValue;
			
		EndTry;
		AttributesStructure1 = New Map;
		AttributesStructure1.Insert(AddressInAnalytics, ValueResult);
		CacheAnalystValues.Insert(DimensionValue, AttributesStructure1);
		Return ValueResult;
	EndIf;
	
	ValueResult = AttributesStructure1[AddressInAnalytics];
	If ValueResult = Undefined Then
		ValueResult = DimensionValue[AddressInAnalytics];
		AttributesStructure1.Insert(AddressInAnalytics, ValueResult);
	EndIf;
	
	Return ValueResult;
	
EndFunction

Procedure SetParametersInNameForPrinting(NameForPrinting, SubstitutionValues)
	
	For Each CurRow In SubstitutionValues Do
		NameForPrinting = StrReplace(NameForPrinting, CurRow.WhatToChange, String(CurRow.WhatReplaceWith));
	EndDo;
	
EndProcedure

// Returns a table of report dimension views
// 
// Parameters:
// 	OutputTree - See BudgetReportingCacheCalculationServer.CacheCalculationGettingTreeForReportOutput
// 	CellData_ - See BudgetReportingDisplayServer.CellData_
// 	DescriptionOfReport - See BudgetReportingCacheCalculationServer.ColumnsOfDataTable_
// 	AttributeCache - ValueTable - 
// Returns:
// 	ValueTable, ValueTree - contains including:
// 	* String - Arbitrary -
// 	* Column- Arbitrary -
//
Function PresentationOfReportDimensions(OutputTree, CellData_, DescriptionOfReport, AttributeCache) Export
	
	FinReports = FinancialReportingServer;
	
	CalculationOfPresentations = DataCompositionServer.EmptyCircuit();
	Set = DataCompositionServer.AddEmptyDataSet(
		CalculationOfPresentations,
		Type("DataCompositionSchemaDataSetObject"),
		"CellData_");
	Set.ObjectName = "CellData_";
	
	FinReports.NewSetField(Set, "String");
	FinReports.NewSetField(Set, "Column");
	
	FinReports.NewSelectionField(CalculationOfPresentations.DefaultSettings, "String");
	FinReports.NewSelectionField(CalculationOfPresentations.DefaultSettings, "Column");
	
	RepresentationExpressionPattern = "
		|	WHEN FinancialReportingServer.ValueOfAdditionalProps(Column, VALUE(ChartOfCharacteristicTypes.ItemAttributesOfFinancialReports.DimensionKind), &AttributeCache) = &%1
		|		AND FinancialReportingServer.ValueOfAdditionalProps(Column, VALUE(ChartOfCharacteristicTypes.ItemAttributesOfFinancialReports.PresentationExpression), &AttributeCache) = ""%2""
		|		THEN %3
		|	WHEN FinancialReportingServer.ValueOfAdditionalProps(STRING, VALUE(ChartOfCharacteristicTypes.ItemAttributesOfFinancialReports.DimensionKind), &AttributeCache) = &%1
		|		AND FinancialReportingServer.ValueOfAdditionalProps(STRING, VALUE(ChartOfCharacteristicTypes.ItemAttributesOfFinancialReports.PresentationExpression), &AttributeCache) = ""%2""
		|		THEN %3
		|";
	CacheOfAttributesIsUsed = False;
	
	TraversedFields = New Map;
	For Each Dimension In DescriptionOfReport.Dimensions Do
		
		If Dimension = "UnitOfMeasure" Then
			Continue;
		EndIf;
		
		FinReports.NewSetField(Set, Dimension,,, BudgetReportingCacheCalculationServer.ColumnTypeOfCellStructure(Dimension));
		FinReports.NewSelectionField(CalculationOfPresentations.DefaultSettings, Dimension);
	
		FinReports.NewCalculatedField(CalculationOfPresentations, Dimension + "Presentation", "Presentation(" + Dimension + ")");
		FinReports.NewSelectionField(CalculationOfPresentations.DefaultSettings, Dimension + "Presentation");
		
		FoundRows = OutputTree.Rows.FindRows(New Structure("DimensionName", Dimension), True);
		For Each FoundRow In FoundRows Do
			For Each AdditionalAttribute5 In FoundRow.AdditionalFields Do
				NameOfAdditionalProps = Dimension + "." + AdditionalAttribute5.Attribute;
				If TraversedFields[NameOfAdditionalProps] = True Then
					Continue;
				EndIf;
				TraversedFields.Insert(NameOfAdditionalProps, True);
				FinReports.NewSelectionField(CalculationOfPresentations.DefaultSettings, NameOfAdditionalProps);
			EndDo;
		EndDo;
		
	EndDo;
	
	For Each DimensionKind In DescriptionOfReport.DimensionKinds Do
		Dimension = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		
		ExpressionsOfMeasurementRepresentations = New Map;
		
		FinReports.NewSetField(Set, Dimension,,,Common.ObjectAttributeValue(DimensionKind, "ValueType"));
		FinReports.NewSelectionField(CalculationOfPresentations.DefaultSettings, Dimension);
	
		DCSViewField = FinReports.NewCalculatedField(CalculationOfPresentations, Dimension + "Presentation", "Presentation(" + Dimension + ")");
		FinReports.NewSelectionField(CalculationOfPresentations.DefaultSettings, Dimension + "Presentation");
		
		FoundRows = OutputTree.Rows.FindRows(New Structure("DimensionName", Dimension), True);
		For Each FoundRow In FoundRows Do
			If Not IsBlankString(FoundRow.PresentationExpression)
				And ExpressionsOfMeasurementRepresentations.Get(FoundRow.PresentationExpression) = Undefined Then
				ExpressionText = StringFunctionsClientServer.SubstituteParametersToString(RepresentationExpressionPattern,
					Dimension, StrReplace(FoundRow.PresentationExpression, """", """"""),
					FinancialReportingCached.TextOfSortRepresentationExpressionWithDimensionName(
					FoundRow.PresentationExpression, Dimension));
				ExpressionsOfMeasurementRepresentations.Insert(FoundRow.PresentationExpression, ExpressionText);
			EndIf;
			For Each AdditionalAttribute5 In FoundRow.AdditionalFields Do
				NameOfAdditionalProps = Dimension + "." + AdditionalAttribute5.Attribute;
				If TraversedFields[NameOfAdditionalProps] = True Then
					Continue;
				EndIf;
				TraversedFields.Insert(NameOfAdditionalProps, True);
				FinReports.NewSelectionField(CalculationOfPresentations.DefaultSettings, NameOfAdditionalProps);
			EndDo;
		EndDo;
		If ExpressionsOfMeasurementRepresentations.Count() > 0 Then
			ExpressionsOfMeasurementRepresentations = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
				ExpressionsOfMeasurementRepresentations, False);
			OriginalRepresentationExpression = DCSViewField.Expression;
			DCSViewField.Expression = "SELECTION " + StrConcat(ExpressionsOfMeasurementRepresentations, Chars.LF) + Chars.LF
				+ "ELSE " + OriginalRepresentationExpression + " END";
			DataCompositionServer.AddParameter(CalculationOfPresentations, Dimension,
				New TypeDescription("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions"), DimensionKind);
			If Not CacheOfAttributesIsUsed Then
				DataCompositionServer.AddParameter(CalculationOfPresentations, "AttributeCache", , AttributeCache);
				CacheOfAttributesIsUsed = True;
			EndIf;
		EndIf;
		
	EndDo;
	
	Group = FinReports.NewGrouping(CalculationOfPresentations.DefaultSettings.Structure);
	Group.GroupFields.Items.Clear();
	
	Composer = FinReports.SchemaComposer(CalculationOfPresentations);
	Result = FinReports.UploadDCSResults(CalculationOfPresentations, Composer, New Structure("CellData_", CellData_));
	Return Result;
	
EndFunction

Procedure AddEditListTreeLine(Value, ReportRow, GroupingText, OutputParameters, AreaBegin, ThisIsACombinedDimension=False)
	
	If Not OutputParameters.ForEditing Then
		Return;
	EndIf;
	
	PlaceAdded = OutputParameters.AddressForAddingLinesToEditList;
	
	NewRow = PlaceAdded.Rows.Add();
	NewRow.String = ReportRow.ReportItem;
	NewRow.Presentation = GroupingText;
	NewRow.Picture = FinancialReportingCached.CustomPicture(ReportRow.ItemKind);
	NewRow.Level = NewRow.Level();
	If Not AreaBegin.Details = Undefined Then
		NewRow.GroupingID = OutputParameters.DetailsData[AreaBegin.Details].GroupingID;
	Else
		Return;
	EndIf;
	NewRow.TableID = PlaceAdded.TableID;
	NewRow.Details = AreaBegin.Details;
	NewRow.ThisIsACombinedDimension = ThisIsACombinedDimension;
	NewRow.FixedValue = Value;
	NewRow.DimensionName = ReportRow.DimensionName;
	If ValueIsFilled(Value) Then
		NewRow.ThisIsDimensionOther = False;
	Else
		NewRow.ThisIsDimensionOther = ReportRow.ThisIsDimensionOther;
	EndIf;
	NewRow.EditedValues = ReportRow.EditedValues;
	
	StyleStructure = New Structure("Font, BackColor", AreaBegin.Font, AreaBegin.BackColor);
	StyleCache = OutputParameters.LevelStyle[PlaceAdded.TableID];
	If StyleCache = Undefined Then
		StyleCache = New Map;
	EndIf;
	StyleCache.Insert(NewRow.Level, StyleStructure);
	
	ParametersForGettingStyleCache = New Structure;
	ParametersForGettingStyleCache.Insert("LevelStyle", OutputParameters.LevelStyle);
	ParametersForGettingStyleCache.Insert("Font", AreaBegin.Font);
	ParametersForGettingStyleCache.Insert("BackColor", AreaBegin.BackColor);
	ParametersForGettingStyleCache.Insert("TableID", PlaceAdded.TableID);
	ParametersForGettingStyleCache.Insert("Level", NewRow.Level);
	
	StyleCache = GetCacheOfEditingListLineStyles(ParametersForGettingStyleCache);
	
	OutputParameters.LevelStyle.Insert(PlaceAdded.TableID, StyleCache);
	
	OutputParameters.Insert("AddressForAddingLinesToEditList", NewRow);
	
EndProcedure

// Gets / adds a cache of edit list row styles
// 
// Parameters:
// 	Parameters - Structure - Contains:
// 		*LevelStyle - Structure, Map -
//		*Font        - Font -
//		*BackColor     - Color, -
//		*TableID    - String -
//		*Level      - Number -
// Returns:
// 	Map of KeyAndValue - cache of styles. contains:
// 		*Key - Number - Level.
// 		*Value - Structure - Contains:
// 			** Font    - Font - font.
// 			** BackColor - Color - color.
//
Function GetCacheOfEditingListLineStyles(Parameters) Export
	
	StyleStructure = New Structure;
	
	Font = Undefined;
	If Parameters.Property("Font", Font) Then
		StyleStructure.Insert("Font", Font);
	EndIf;
	
	BackColor = Undefined;
	If Parameters.Property("BackColor", BackColor) Then
		StyleStructure.Insert("BackColor", BackColor);
	EndIf;
	
	StyleCache = Parameters.LevelStyle[Parameters.TableID];
	If StyleCache = Undefined Then
		StyleCache = New Map;
	EndIf;
	StyleCache.Insert(Parameters.Level, StyleStructure);
	
	Return StyleCache;
	
EndFunction

Procedure SetParentOfEditListRow(OutputParameters)
	
	If Not OutputParameters.ForEditing Then
		Return;
	EndIf;
	
	String_Output = OutputParameters.AddressForAddingLinesToEditList;
	If Not ValueIsFilled(String_Output.Parent) Then
		OutputParameters.Insert("AddressForAddingLinesToEditList", String_Output.Owner());
	Else
		OutputParameters.Insert("AddressForAddingLinesToEditList", String_Output.Parent);
	EndIf;
	
EndProcedure

Function ParametersForColumnDimensions(OutputParameters, DimensionSearchIndexes, OutputTree,
									TreeResult = Undefined,
									AccumulatedSelection = Undefined,
									RowOfAnalyticsHierarchy = Undefined) Export
	
	CellData_ = OutputParameters.CellData_;
	SubordinateElementsOfBudgetView = OutputParameters.SubordinateElementsOfBudgetView;
	
	If TreeResult = Undefined Then
		TreeResult = New ValueTree;
		TreeResult.Columns.Add("ReportItem");
		TreeResult.Columns.Add("NameForPrinting");
		TreeResult.Columns.Add("DimensionName");
		TreeResult.Columns.Add("FixedValue");
		TreeResult.Columns.Add("ItemKind");
		TreeResult.Columns.Add("ValueType");
	EndIf;
	
	If AccumulatedSelection = Undefined Then
		AccumulatedSelection = New Structure;
	EndIf;
	
	If RowOfAnalyticsHierarchy <> Undefined Then
		IndexOfTreeColumn = OutputTree.Parent.Rows.IndexOf(OutputTree);
		CollectionOfReportColumns = OutputTree.Parent.Rows;
	Else
		CollectionOfReportColumns = OutputTree.Rows;
	EndIf;
	
	For Each Column In CollectionOfReportColumns Do
		
		If RowOfAnalyticsHierarchy <> Undefined
			And CollectionOfReportColumns.IndexOf(Column) <> IndexOfTreeColumn Then
			Continue;
		EndIf;
		
		ThisIsIndicatorColumn = StrFind(Column.DimensionName, "#Factor");
		ThisIsFixColumn = 
			Column.ItemKind = Enums.FinancialReportItemKinds.RowColumn 
			Or Column.ItemKind = Enums.FinancialReportItemKinds.Group
			Or Column.ItemKind = Enums.FinancialReportItemKinds.GroupFormula
			Or Column.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
		
		If ValueIsFilled(Column.FixedValue)
			Or ThisIsIndicatorColumn
			Or ThisIsFixColumn Then
			
			NewRow = TreeResult.Rows.Add();
			FillPropertyValues(NewRow, Column);
			
			NewRow.NameForPrinting = GroupingText(Column.FixedValue, Column, OutputParameters, True);
			
			AddedSelection = False;
			If Not ThisIsFixColumn
				And Not ThisIsIndicatorColumn Then
				AccumulatedSelection.Insert(Column.DimensionName, Column.FixedValue);
				AddedSelection = True;
			EndIf;
			
			ParametersForColumnDimensions(OutputParameters, DimensionSearchIndexes, Column, NewRow, AccumulatedSelection);
			
			If AddedSelection Then
				AccumulatedSelection.Delete(Column.DimensionName);
			EndIf;
			
		Else
			
			If RowOfAnalyticsHierarchy <> Undefined Then
				
				Result = RowOfAnalyticsHierarchy.Rows;
				
			Else
				
				ListOfItemsWithSubordinates = ListOfSubordinateElements(Column.ReportItem, SubordinateElementsOfBudgetView);
				
				OptionalParameters = OptionalParametersForGettingSelectionOfCells();
				OptionalParameters.Column = ListOfItemsWithSubordinates;
				OptionalParameters.String = Undefined;
				OptionalParameters.SearchIndexes = DimensionSearchIndexes;
				OptionalParameters.AddFlag = False;
				OptionalParameters.GenerationMode = OutputParameters.GenerationMode;
				If Column.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
					FillPropertyValues(OptionalParameters, Column,
						"ShowItemHierarchy, PresentationExpression, SortingExpression");
					If Column.ShowItemHierarchy And OutputParameters.ConsiderAdditionalSelectionByHierarchy Then
						OptionalParameters.Insert("AdditionalSelection",
							BudgetReportingCacheCalculationServer.ValueOfBudgetViewElementSProps(
							Column.ReportItem, "AdditionalSelection",
							OutputParameters.CacheOfBudgetItemDetails.AttributeCache));
					EndIf;
				EndIf;
				Result = GetSelectionOfCellsHierarchically(CellData_, Column.DimensionName, AccumulatedSelection,
					OptionalParameters);
				
				If OptionalParameters.Property("AdditionalSelection") Then
					OutputParameters.Insert("ConsiderAdditionalSelectionByHierarchy", True);
				EndIf;
				
			EndIf;
			
			If TypeOf(Result) = Type("ValueTree") Then
				Result = Result.Rows;
			EndIf;
			
			SelectionFromHierarchy = (TypeOf(Result) = Type("ValueTreeRowCollection"));
			
			For Each Selection In Result Do
				
				Value = Selection[Column.DimensionName];
				If Value = NULL
					And Not TypeOf(Column.DimensionKind) = Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions") Then
					Continue; //null groupings are not displayed
				EndIf;
				
				If BudgetReportingClientServer.ThisIsPeriodField(Column.DimensionName)
					And Not ValueIsFilled(Value) Then
					Continue;
				ElsIf SelectionFromHierarchy
					And Selection.Parent <> Undefined
					And Not Selection.Parent.IsFolder
					And Value = Selection.Parent[Column.DimensionName] Then
					// for Catalogs with a hierarchy of elements, the parent row is present among the subordinates
					Continue;
				EndIf;
				
				NewRow = TreeResult.Rows.Add();
				FillPropertyValues(NewRow, Column);
				NewRow.FixedValue = Value;
				NewRow.NameForPrinting = GroupingText(Value, Column, OutputParameters, True);
				
				AccumulatedSelection.Insert(Column.DimensionName, Value);
				ParametersForColumnDimensions(OutputParameters, DimensionSearchIndexes, Column, NewRow,
					AccumulatedSelection);
				If SelectionFromHierarchy Then
					ParametersForColumnDimensions(OutputParameters, DimensionSearchIndexes, Column, NewRow,
						AccumulatedSelection, Selection);
				EndIf;
				AccumulatedSelection.Delete(Column.DimensionName);
				
			EndDo;
			
		EndIf;
	EndDo;
	
	Return TreeResult;
	
EndFunction

Function FindRowsGivenIndexes(CellData_, Column, String, AccumulatedSelection, SearchIndexes, FilterStructure1 = Undefined)
	
	FilterStructure1 = New Structure();
	
	FilterFields = "";
	
	If Column <> Undefined
		And ValueIsFilled(Column) Then
		
		FilterStructure1.Insert("Column", Column);
		FilterFields = "Column";
		
	EndIf;
	
	If String <> Undefined Then
		
		FilterStructure1.Insert("String", String);
		FilterFields = FilterFields + ?(IsBlankString(FilterFields), "", ",") + "String";
		
	EndIf;
	
	FilterStructure1.Insert("MainItem", True);
	FilterFields = FilterFields + ?(IsBlankString(FilterFields), "", ",") + "MainItem";
	
	For Each KeyAndValue In AccumulatedSelection Do
		FilterStructure1.Insert(KeyAndValue.Key, KeyAndValue.Value);
		FilterFields = FilterFields + ?(IsBlankString(FilterFields), "", ",") + KeyAndValue.Key;
	EndDo;
	
	If SearchIndexes <> Undefined Then
		If SearchIndexes[FilterFields] <> True Then
			SearchIndexes.Insert(FilterFields, True);
			CellData_.Indexes.Add(FilterFields);
		EndIf;
	EndIf;
	
	Return CellData_.FindRows(FilterStructure1);
	
EndFunction

Function SelectingCellBySearchStructure(FilterStructure1, FilterCells = "")
	
	For Each KeyAndValue In FilterStructure1 Do
		FilterCells = FilterCells + ?(IsBlankString(FilterCells), "", ",") + KeyAndValue.Key;
	EndDo;
	
	Return FilterCells;
	
EndFunction

Function TreeDepth(Rows, Val Depth = 0, DepthOfEverything = 0) Export
	
	If Rows.Count() Then
		DepthOfEverything = Max(DepthOfEverything, Depth);
	EndIf;
	
	For Each IndicatorLine_1 In Rows Do
		
		TreeDepth(IndicatorLine_1.Rows, Depth + 1, DepthOfEverything);
		
	EndDo;
	
	Return DepthOfEverything
	
EndFunction

Procedure DistributeItemsByLevels(Rows, DepthOfEverything, MatchingRowsToLevels, DepthCur = 0) Export
	
	If DepthCur > DepthOfEverything Then
		Return;
	EndIf;
	
	StringsList = MatchingRowsToLevels[DepthCur + 1];
	If StringsList = Undefined Then
		StringsList = New Array;
	EndIf;
	MatchingRowsToLevels.Insert(DepthCur + 1, StringsList);
	
	If Rows = Undefined Or Not Rows.Count() Then
		
		StringsList.Add(Undefined);
		DistributeItemsByLevels(Undefined, DepthOfEverything, MatchingRowsToLevels, DepthCur + 1);
		
	Else
		
		For Each IndicatorLine_1 In Rows Do
			
			StringsList.Add(IndicatorLine_1);
			DistributeItemsByLevels(IndicatorLine_1.Rows, DepthOfEverything, MatchingRowsToLevels, DepthCur + 1);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function GetNumberOfTreeLeaves(LevelElement, Count = 0)
	
	For Each Item In LevelElement.Rows Do
		If Not Item.Rows.Count() Then
			Count = Count + 1;
		Else
			GetNumberOfTreeLeaves(Item, Count);
		EndIf;
	EndDo;
	
	Return Max(1, Count);
	
EndFunction

Procedure DisplayTableHeaderInReport(OutputParameters, ResultDocument, StructureOfAreas, ColumnStructure1, TableRow, TableNumber)
	
	MatchingElementsByLevels = New Map;
	LevelCount = TreeDepth(ColumnStructure1.Rows) + 1;
	DistributeItemsByLevels(ColumnStructure1.Rows, LevelCount, MatchingElementsByLevels);
	WithNote = ?(OutputParameters.DisplayNotes_, "WithNote", "");
	
	If TableRow.TableParameters.DisplayRowsNumbering Then
		HeaderAreaStartOfTable = "HeaderStartOfTableRowNumbering";
		ColumnNumberingAreaStartOfTable = "ColumnNumberingStartOfTableRowNumbering";
	Else
		HeaderAreaStartOfTable = "HeaderStartOfTable";
		ColumnNumberingAreaStartOfTable = "ColumnNumberingStartOfTable";
	EndIf;
	
	If OutputParameters.DisplayNotes_ And OutputParameters.DisplayTableNumbers Then
		RowTableNumber = NStr("vi = 'Bảng %1';
								|ru = 'Таблица %1';
								|en = 'Table %1'; fa = 'Table %1';
								|it = 'Tabella %1';
								|pl = 'Tabela %1';
								|tr = '%1 Tablosu'");
		RowTableNumber = StringFunctionsClientServer.SubstituteParametersToString(RowTableNumber, TableNumber);
		AreaTableNumber = StructureOfAreas["TableNumber"]; // SpreadsheetDocument, SpreadsheetDocumentField -
		AreaTableNumber.Parameters.Text = RowTableNumber;
		ResultDocument.Put(AreaTableNumber, 0);
	EndIf;
	
	DisplayHeadersVertically = OutputParameters.TableParameters.Property("DisplayHeadersVertically")
			And OutputParameters.TableParameters.DisplayHeadersVertically = True;
	
	StartOfOutput = Undefined;
	ColumnsCounter = 1;
	For Cnt = 1 To LevelCount Do
		
		DerivedArea = ResultDocument.Put(StructureOfAreas[HeaderAreaStartOfTable], 0);
		DerivedArea.Details = Undefined;
		If StartOfOutput = Undefined Then
			StartOfOutput = DerivedArea;
		EndIf;
		
		AdditionalArea = StructureOfAreas["HeaderAdditionalSection"];
		For AdditionalColumn_ = 1 To TableRow.TableParameters.NumberOfAdditionalColumns Do
			ResultDocument.Join(AdditionalArea);
		EndDo;
		
		If MatchingElementsByLevels.Count() Then // checking for column values
			
			LevelElements = MatchingElementsByLevels[Cnt];
			For Each LevelElement In LevelElements Do
				Section3 = StructureOfAreas["HeaderColumnsGroup" + Min(Cnt, 3) + WithNote];
				
				If LevelElement = Undefined Then
					Section3.Parameters.Group = "";
				ElsIf ValueIsFilled(LevelElement.NameForPrinting) Then
					Section3.Parameters.Group = LevelElement.NameForPrinting;
					Details = GetDimensionDecryption(OutputParameters, LevelElement.FixedValue);
					Section3.Parameters.Details = Details;
				Else
					Section3.Parameters.Group = LevelElement.FixedValue;
					Details = GetDimensionDecryption(OutputParameters, LevelElement.FixedValue);
					Section3.Parameters.Details = Details;
				EndIf;
				
				DerivedArea = ResultDocument.Join(Section3);
				
				If LevelElement = Undefined Then
					If Cnt > 1 Then // combine with the previous level, if there is a previous level
						JoinStartLine = ResultDocument.Area(DerivedArea.Top - 1,
								DerivedArea.Left).Top;
						
						Area = ResultDocument.Area(JoinStartLine,
								DerivedArea.Left,
								DerivedArea.Top,
								DerivedArea.Right);
						Area.Merge();
					EndIf;
					Continue;
				EndIf;
				
				SubordinateElements = GetNumberOfTreeLeaves(LevelElement);
				If SubordinateElements > 1 Then
					For SectionNumber_ = 1 To SubordinateElements - 1 Do
						ResultDocument.Join(Section3);
					EndDo;
					Area = ResultDocument.Area(DerivedArea.Top,
							DerivedArea.Left,
							DerivedArea.Top,
							DerivedArea.Right + (SubordinateElements - 1)*Section3.TableWidth);
					Area.Merge();
					
					ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
					ParametersSet.OutputParameters = OutputParameters;
					ParametersSet.ReportItem = Undefined;
					ParametersSet.Column = LevelElement.ReportItem;
					AddDesignArea(ParametersSet, Area, Undefined, TableNumber, 0, Undefined);
				ElsIf Cnt < LevelCount Then
					ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
					ParametersSet.OutputParameters = OutputParameters;
					ParametersSet.ReportItem = Undefined;
					ParametersSet.Column = LevelElement.ReportItem;
					AddDesignArea(ParametersSet, DerivedArea, Undefined, TableNumber, 0, Undefined);
				EndIf;
				
				If Cnt = LevelCount Then
					ColumnsCounter = ColumnsCounter + 1;
					ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
					ParametersSet.OutputParameters = OutputParameters;
					ParametersSet.ReportItem = Undefined;
					ParametersSet.Column = LevelElement.ReportItem;
					AddDesignArea(ParametersSet, DerivedArea, Undefined, TableNumber, 0, ColumnsCounter);
				EndIf;
				
				If DisplayHeadersVertically Then
					DerivedArea.ColumnWidth = 3;
					DerivedArea.TextOrientation = 90;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	If TableRow.TableParameters.DisplayRowsNumbering Then
		
		Area = ResultDocument.Area(StartOfOutput.Top,
				1,
				StartOfOutput.Top + (LevelCount - 1),
				1);
		Area.Merge();
		
		ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
		ParametersSet.OutputParameters = OutputParameters;
		ParametersSet.ReportItem   = Catalogs.FinancialReportItems.EmptyRef();
		ParametersSet.Column         = Catalogs.FinancialReportItems.EmptyRef();
		AddDesignArea(ParametersSet, Area, Undefined, TableNumber, 0, 1);
		
		Area = ResultDocument.Area(StartOfOutput.Top,
				2,
				StartOfOutput.Top + (LevelCount - 1),
				2 + TableRow.TableParameters.NumberOfAdditionalColumns);
		Area.Merge();
		
		ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
		ParametersSet.OutputParameters = OutputParameters;
		ParametersSet.ReportItem = Catalogs.FinancialReportItems.EmptyRef();
		ParametersSet.Column = Catalogs.FinancialReportItems.EmptyRef();
		AddDesignArea(ParametersSet, Area, Undefined, TableNumber, 0, 1);
		
		TextArea_ = Area;
		
	Else
		
		Area = ResultDocument.Area(StartOfOutput.Top, 
				1,
				StartOfOutput.Top + (LevelCount - 1),
				2 + TableRow.TableParameters.NumberOfAdditionalColumns);
		Area.Merge();
		
		ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
		ParametersSet.OutputParameters = OutputParameters;
		ParametersSet.ReportItem = Catalogs.FinancialReportItems.EmptyRef();
		ParametersSet.Column = Catalogs.FinancialReportItems.EmptyRef();
		AddDesignArea(ParametersSet, Area, Undefined, TableNumber, 0, 1);
		
		TextArea_ = Area;
		
	EndIf;
	
	DisplayGroupingTitle = OutputParameters.TableParameters.Property("DisplayGroupingTitle")
			And OutputParameters.TableParameters.DisplayGroupingTitle = True;
	
	If Not DisplayGroupingTitle Then
	
		Text = "";
		If TableRow.Rows.Find("BudgetBalanceItem", "DimensionName", True) <> Undefined Then
			Text = NStr("vi = 'Chỉ tiêu ngân sách';
						|ru = 'Показатель бюджетов';
						|en = 'Budget balance item'; fa = 'قلم مانده بودجه';
						|it = 'Indice dei bilanci';
						|pl = 'Wskaźnik budżetowy';
						|tr = 'Bütçe kalemi'");
		EndIf;
		
		If TableRow.Rows.Find("BudgetFlowItem", "DimensionName", True) <> Undefined Then
			Text = Text + ?(IsBlankString(Text), "", " / " + Chars.LF) + NStr("vi = 'Khoản mục ngân sách';
																				|ru = 'Статья бюджетов';
																				|en = 'Budget flow item'; fa = 'قلم جریان بودجه';
																				|it = 'Voce di bilanci';
																				|pl = 'Pozycja budżetowa';
																				|tr = 'Bütçe kalemi'");
		EndIf;
		
		Text = Text + ?(IsBlankString(Text), "", " / " + Chars.LF) + NStr("vi = 'Chỉ số';
																			|ru = 'Аналитика';
																			|en = 'Dimension'; fa = 'بُعد';
																			|it = 'Analitica';
																			|pl = 'Analityka';
																			|tr = 'Boyut'");
		
	Else
		
		Text = OutputParameters.TableParameters.GroupHeader;
		
	EndIf;
	
	TextArea_.Text = Text;
	
	If TableRow.TableParameters.DisplayColumnNumbering Then
		StartOfOutput = ResultDocument.Put(StructureOfAreas[ColumnNumberingAreaStartOfTable], 0);
		
		ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
		ParametersSet.OutputParameters = OutputParameters;
		ParametersSet.ReportItem = Catalogs.FinancialReportItems.EmptyRef();
		ParametersSet.Column = Catalogs.FinancialReportItems.EmptyRef();
		AddDesignArea(ParametersSet, StartOfOutput, Undefined, TableNumber, 0, 1);
		
		AdditionalArea = StructureOfAreas["ColumnNumberingAdditionalSection"];
		For AdditionalColumn_ = 1 To TableRow.TableParameters.NumberOfAdditionalColumns Do
			ResultDocument.Join(AdditionalArea);
		EndDo;
		If TableRow.TableParameters.DisplayRowsNumbering Then
			
			Area = ResultDocument.Area(StartOfOutput.Top,
					2,
					StartOfOutput.Top,
					2 + TableRow.TableParameters.NumberOfAdditionalColumns);
			Area.Merge();
			
		Else
			
			Area = ResultDocument.Area(StartOfOutput.Top,
					1,
					StartOfOutput.Top,
					2 + TableRow.TableParameters.NumberOfAdditionalColumns);
			Area.Merge();
			
		EndIf;
		
		ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
		ParametersSet.OutputParameters = OutputParameters;
		ParametersSet.ReportItem = Catalogs.FinancialReportItems.EmptyRef();
		ParametersSet.Column = Catalogs.FinancialReportItems.EmptyRef();
		AddDesignArea(ParametersSet, Area, Undefined, TableNumber, 0, 1);
		
		ReportItems = MatchingElementsByLevels[LevelCount];
		For Cnt = 1 To ReportItems.Count() Do
			Area = StructureOfAreas["ColumnNumberingGroupingOfColumns"
										+ Min(LevelCount, 3)
										+ WithNote]; // SpreadsheetDocument
			Area["Parameters"].ColumnNumber = 1 + Cnt;
			DerivedArea = ResultDocument.Join(Area);
			DesignedElement = ?(ReportItems[Cnt-1] = Undefined, 
									Catalogs.FinancialReportItems.EmptyRef(), ReportItems[Cnt-1].ReportItem);
			
			ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
			ParametersSet.OutputParameters = OutputParameters;
			ParametersSet.ReportItem = Undefined;
			ParametersSet.Column = DesignedElement;
			AddDesignArea(ParametersSet, DerivedArea, Undefined, TableNumber, 0, ColumnsCounter);
		EndDo;
	EndIf;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	CellData_ - See CellData_
// 	CellParameters - ValueTable -
// 	PeriodParameters_1 - Structure -
// 	CalculationParameters - Structure - LongDesc:
// * CacheOfBudgetItemDetails - Undefined, Structure -
// * Postfix - String -
// * Prefix - String -
// * DataString1 - ValueTableRow - See CellData_. Contains:
//	   ** String  - CatalogRef.FinancialReportItems, Arbitrary -
//	   ** Column - Arbitrary -
//	   and the other columns from the data Cells
// 	ItemKind - Undefined - LongDesc
// 	CalculationLog - Undefined, Array - LongDesc
// Returns:
// 	String - LongDesc
Function GetOperandValue(CellData_, CellParameters, PeriodParameters_1, CalculationParameters,
						ItemKind = Undefined,
						CalculationLog = Undefined)
	
	DataString1 = CalculationParameters.DataString1;
	Prefix = CalculationParameters.Prefix;
	Postfix = CalculationParameters.Postfix;
	CalculatingChanges = CalculationParameters.CalculatingChanges;
	CacheOfBudgetItemDetails = CalculationParameters.CacheOfBudgetItemDetails; // Undefined or calculated cache of Attributes of budget view items.
	
	If ItemKind = Undefined Then
		ItemKind = DataString1.ItemKind;
	EndIf;
	
	If CalculatingChanges
		And ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		
		CellParameters_ = CellParameters.Find(DataString1.RowIndex, "RowIndex");
		
		If ValueIsFilled(CellParameters_.Formula) Then
			
			ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
			
		EndIf;
		
	EndIf;
	
	If Not DataString1["Calculated" + Prefix + Postfix] Then
		
		CellParameters_ = CellParameters.Find(DataString1.RowIndex, "RowIndex");
		ReverseSign = CellParameters_.ReverseSign;
		
		If ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem
			Or ItemKind = Enums.FinancialReportItemKinds.BudgetBalanceItem
			Or ItemKind = Enums.FinancialReportItemKinds.AllBudgetFlowItems
			Or ItemKind = Enums.FinancialReportItemKinds.AllBudgetBalanceItems Then
			
			ValueInDataLine = DataString1[Prefix + Postfix + CellParameters_.SourceField];
			If TypeOf(ValueInDataLine) = Type("Number") Then
				DataString1[Prefix + Postfix] = ?(ReverseSign, -1, 1) * ValueInDataLine;
			Else
				DataString1[Prefix + Postfix] = ValueInDataLine;
			EndIf;
			
		ElsIf ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem
			Or ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
			
			DataString1[Prefix + Postfix] = DataString1.IndicatorValue;
			
		ElsIf ItemKind = Enums.FinancialReportItemKinds.DerivedItem
			Or ItemKind = Enums.FinancialReportItemKinds.GroupFormula
			Or ItemKind = Enums.FinancialReportItemKinds.Group Then
			
			Formula = CellParameters_.Formula;
			ArrayOfValues = New Array;
			
			// Indicators and articles
			OperandAnalysis_ = CellParameters_.OperandAnalysis_;
			ListOfOperands = CellParameters_.ListOfOperands;
			
			// The key is a set of operand search dimensions, the value is an Array of operand names or Undefined (any operands).
			MeasurementSets = New Map;
			If OperandAnalysis_ = Undefined Then
				MeasurementSets.Insert(CellParameters_.GeneralMeasurements, Undefined);
			Else
				For Each OperandNameAndSearchFields In OperandAnalysis_ Do
					ArrayOfOperands = MeasurementSets.Get(OperandNameAndSearchFields.Value);
					If ArrayOfOperands = Undefined Then
						ArrayOfOperands = New Array;
					EndIf;
					ArrayOfOperands.Add(OperandNameAndSearchFields.Key);
					
					MeasurementSets.Insert(OperandNameAndSearchFields.Value, ArrayOfOperands);
				EndDo;
			EndIf;
			
			For Each SetOfMeasurements In MeasurementSets Do
				
				ArrayOfDimensionSetOperands = SetOfMeasurements.Value;
				GeneralMeasurements = SetOfMeasurements.Key;
				
				TheStructureOfTheSearch = New Structure(GeneralMeasurements);
				
				FillPropertyValues(TheStructureOfTheSearch, DataString1);
				CalculationByColumn = False;
				If CacheOfBudgetItemDetails = Undefined Then
					TypeOfRowElement = Common.ObjectAttributeValue(DataString1.String, "ItemKind");
				Else
					TypeOfRowElement = BudgetReportingCacheCalculationServer.ValueOfBudgetViewElementSProps(DataString1.String,
						"ItemKind", CacheOfBudgetItemDetails.AttributeCache);
				EndIf;
				If TypeOfRowElement = Enums.FinancialReportItemKinds.GroupFormula Then
					If CacheOfBudgetItemDetails = Undefined And ValueIsFilled(DataString1.Column) Then
						ColumnElementView = Common.ObjectAttributeValue(DataString1.Column, "ItemKind");
					ElsIf ValueIsFilled(DataString1.Column) Then
						ColumnElementView = BudgetReportingCacheCalculationServer.ValueOfBudgetViewElementSProps(DataString1.Column,
							"ItemKind", CacheOfBudgetItemDetails.AttributeCache);
					Else
						ColumnElementView = Undefined;
					EndIf;
					If ColumnElementView = Enums.FinancialReportItemKinds.GroupFormula Then
						CalculationByColumn = True;
					EndIf;
				EndIf;
				
				If Not CalculationByColumn Then
					TheStructureOfTheSearch.Insert("String", DataString1.String);
				EndIf;
				TheStructureOfTheSearch.Insert("Column", DataString1.Column);
				TheStructureOfTheSearch.Insert("MainItem", False);
				
				FoundRows = CellData_.FindRows(TheStructureOfTheSearch);
				
				MatchingPassedOperands = New Map;
				
				For Each FoundRow In FoundRows Do
					
					If FoundRow.OperandType = Enums.FinancialReportItemKinds.TableCell Then
						Continue; //the cells are processed separately
					EndIf;
					
					ParametersOfFoundCell = CellParameters.Find(FoundRow.RowIndex, "RowIndex");
					
					If Not ValueIsFilled(ParametersOfFoundCell.OperandName) Then
						Raise NStr("vi = 'Đã xảy ra lỗi khi tạo báo cáo: Toán hạng công thức không chính xác';
									|ru = 'Ошибка формирования отчета: Неверный операнд формулы';
									|en = 'An error occurred while generating the report: Incorrect formula operand'; fa = 'An error occurred while generating the report: Incorrect formula operand';
									|it = 'Errore nella creazione del rapporto: Operando della formula incorretto';
									|pl = 'Błąd utworzenia raportu: Nieprawidłowy operand formuły';
									|tr = 'Raporun oluşturulmasında hata: Geçersiz formül işleneni'");
					EndIf;
					
					If Not ArrayOfDimensionSetOperands = Undefined
						And ArrayOfDimensionSetOperands.Find(ParametersOfFoundCell.OperandName) = Undefined Then
						Continue;
					EndIf;
					
					If ValueIsFilled(DataString1.NonFinancialItem) Then
						LinkPrefix = Prefix;
						PostFixLinks = Postfix;
						
					// Only quantity or sum can be selected in the operands of the derived exponent
					// (except when the original indicator has the type "Quantity, Amount").
					// 
					ElsIf ParametersOfFoundCell.FlagCount
						And ParametersOfFoundCell.FlagSum
						And Prefix = "Sum" Then
						LinkPrefix = Prefix;
						PostFixLinks = Postfix;
					ElsIf ParametersOfFoundCell.FlagCount
						And ParametersOfFoundCell.FlagSum
						And Prefix = "Count" Then
						LinkPrefix = Prefix;
						PostFixLinks = "";
					ElsIf ParametersOfFoundCell.FlagCount Then
						LinkPrefix = "Count";
						PostFixLinks = "";
					Else
						LinkPrefix = "Sum";
						PostFixLinks = Postfix;
					EndIf;
					If ValueIsFilled(FoundRow.NonFinancialItem) Then
						LinkPrefix = "Value";
						PostFixLinks = "";
					EndIf;
					
					CalculationParameters = New Structure;
					CalculationParameters.Insert("DataString1",	FoundRow);
					CalculationParameters.Insert("Prefix",	LinkPrefix);
					CalculationParameters.Insert("Postfix",	PostFixLinks);
					CalculationParameters.Insert("CalculatingChanges", CalculatingChanges);
					CalculationParameters.Insert("CacheOfBudgetItemDetails", CacheOfBudgetItemDetails);
					Value = GetOperandValue(CellData_, CellParameters, PeriodParameters_1, CalculationParameters,
						FoundRow.OperandType);
					
					OperandName = "[" + ParametersOfFoundCell.OperandName + "]";
					PerformFullMatchReplacement(ListOfOperands, OperandName, "");
					
					PassedValue = MatchingPassedOperands[OperandName]; // See NewStructureOfTraversedOperand
					If PassedValue <> Undefined Then
						ArrayOfLocalValues = PassedValue.Value;
						If TypeOf(ArrayOfLocalValues) <> Type("Array") Then
							ArrayOfLocalValues = CommonClientServer.ValueInArray(ArrayOfLocalValues);
						EndIf;
						ArrayOfLocalValues.Add(Value);
						Value = ArrayOfLocalValues;
						ArrayOfValues[PassedValue["IndexOf"]] = ArrayOfLocalValues;
					Else
						ArrayOfValues.Add(Value);
					EndIf;
					
					PerformFullMatchReplacement(Formula, OperandName, "ArrayOfValues[" + ArrayOfValues.UBound() + "]");
					MatchingPassedOperands.Insert(OperandName, NewStructureOfTraversedOperand(Value, ArrayOfValues.UBound()));
					
					If CalculationLog <> Undefined Then
						ValueForLog = New Structure();
						ValueForLog.Insert("IndicatorName", LinkPrefix);
						ValueForLog.Insert("ItemKind", FoundRow.OperandType);
						ValueForLog.Insert("OperandName", ParametersOfFoundCell.OperandName);
						ValueForLog.Insert("StringBase", CellData_.IndexOf(FoundRow));
						ValueForLog.Insert("Value", Value);
						CalculationLog.Add(ValueForLog);
					EndIf;
					
				EndDo;
				
			EndDo;
			
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("String", DataString1.String);
			TheStructureOfTheSearch.Insert("Column", DataString1.Column);
			TheStructureOfTheSearch.Insert("MainItem", False);
			TheStructureOfTheSearch.Insert("OperandType", Enums.FinancialReportItemKinds.TableCell);
			
			FoundRows = CellData_.FindRows(TheStructureOfTheSearch);
			
			For Each FoundRow In FoundRows Do
				
				ParametersOfFoundCell = CellParameters.Find(FoundRow.RowIndex, "RowIndex");
				
				If Not ValueIsFilled(ParametersOfFoundCell.OperandName) Then
					Raise NStr("vi = 'Đã xảy ra lỗi khi tạo báo cáo: Toán hạng công thức không chính xác';
								|ru = 'Ошибка формирования отчета: Неверный операнд формулы';
								|en = 'An error occurred while generating the report: Incorrect formula operand'; fa = 'An error occurred while generating the report: Incorrect formula operand';
								|it = 'Errore nella creazione del rapporto: Operando della formula incorretto';
								|pl = 'Błąd utworzenia raportu: Nieprawidłowy operand formuły';
								|tr = 'Raporun oluşturulmasında hata: Geçersiz formül işleneni'");
				EndIf;
				
				OperandName = "[" + ParametersOfFoundCell.OperandName + "]";
				ArrayOfLocalValues = New Array;
				
				TheStructureOfTheSearch = New Structure(ParametersOfFoundCell.GeneralMeasurements);
				AddedPeriodicities = New Array;
				For Each Periodicity In PeriodParameters_1.OrderedReportPeriodicities Do
					If Not TheStructureOfTheSearch.Property(Periodicity) Then
						TheStructureOfTheSearch.Insert(Periodicity);
						AddedPeriodicities.Add(Periodicity);
					EndIf;
				EndDo;
				FillPropertyValues(TheStructureOfTheSearch, DataString1);
				TheStructureOfTheSearch.Insert("String", ParametersOfFoundCell.OperandString);
				TheStructureOfTheSearch.Insert("Column", ParametersOfFoundCell.OperandColumn_);
				TheStructureOfTheSearch.Insert("MainItem", True);
				
				LinkStrings = CellData_.FindRows(TheStructureOfTheSearch);
				
				// If no rows are found, then additional selection by periodicity is not required.
				If Not LinkStrings.Count() Then
					For Each Periodicity In AddedPeriodicities Do
						TheStructureOfTheSearch.Delete(Periodicity);
					EndDo;
					LinkStrings = CellData_.FindRows(TheStructureOfTheSearch);
				EndIf;
				
				If LinkStrings.Count() Then
					
					If ItemKind = Enums.FinancialReportItemKinds.GroupFormula
						And AddedPeriodicities.Count() Then
						// It is necessary to sort the array of rows by the values of the minimum periodicity
						For Counter = 0 To LinkStrings.UBound() Do
							For ReturnCounter = 0 To LinkStrings.UBound() - Counter - 1 Do
								If LinkStrings[ReturnCounter][AddedPeriodicities[0]] = Undefined
									Or LinkStrings[ReturnCounter+1][AddedPeriodicities[0]] = Undefined Then
									Continue;
								EndIf;
								If LinkStrings[ReturnCounter][AddedPeriodicities[0]]
									> LinkStrings[ReturnCounter+1][AddedPeriodicities[0]] Then
									LineBeingShifted = LinkStrings[ReturnCounter];
									LinkStrings[ReturnCounter] = LinkStrings[ReturnCounter+1];
									LinkStrings[ReturnCounter+1] = LineBeingShifted;
								EndIf;
							EndDo;
						EndDo;
					EndIf;
					
					For Each RefRow In LinkStrings Do
						
						LinkParameters_ = CellParameters.Find(RefRow.RowIndex, "RowIndex");
						
						// Rows with hierarchical analyst values (groups) do not participate in the calculation of the operand value
						If RefRow.HierarchyOutput And RefRow.CalculationFilling = "Total" Then
							Continue;
						EndIf;
						
						ContainsValueForResource = True;
						If Not LinkParameters_.TableComplex_ Then
							If Prefix = "Sum" And Not LinkParameters_.FlagSum Then
								ContainsValueForResource = False;
							EndIf;
							If Prefix = "Count" And Not LinkParameters_.FlagCount Then
								ContainsValueForResource = False;
							EndIf;
							If Prefix = "Value" And Not LinkParameters_.FlagValue Then
								ContainsValueForResource = False;
							EndIf;
						EndIf;
						
						If Not ContainsValueForResource Then
							ResultOfSubordinateReference = 0;
						Else
							// In a complex table of cells, we select the first
							// thing that is filled in - quantity or amount.
							If LinkParameters_.TableComplex_ Then
								If LinkParameters_.FlagCount Then
									LinkPrefix = "Count";
									PostFixLinks = "";
								ElsIf LinkParameters_.FlagValue Then
									LinkPrefix = "Value";
									PostFixLinks = "";
								Else
									LinkPrefix = "Sum";
									PostFixLinks = Postfix;
								EndIf;
							Else
								LinkPrefix = Prefix;
								PostFixLinks = Postfix;
							EndIf;
							CalculationParameters = New Structure;
							CalculationParameters.Insert("DataString1", RefRow);
							CalculationParameters.Insert("Prefix", LinkPrefix);
							CalculationParameters.Insert("Postfix", PostFixLinks);
							CalculationParameters.Insert("CalculatingChanges", CalculatingChanges);
							CalculationParameters.Insert("CacheOfBudgetItemDetails", CacheOfBudgetItemDetails);
							ResultOfSubordinateReference = GetOperandValue(CellData_, CellParameters, PeriodParameters_1, CalculationParameters);
						EndIf;
						
						If ItemKind = Enums.FinancialReportItemKinds.GroupFormula Then
							IgnoreValue = False;
							If RefRow.ItemKind
								= Enums.FinancialReportItemKinds.BudgetBalanceItem Then
								SourceField = CellParameters.Find(RefRow.RowIndex,
									"RowIndex").SourceField;
								If SourceField = "OpeningBalance" And LinkStrings.Find(RefRow) > 0 Then
									IgnoreValue = True;
								ElsIf SourceField = "ClosingBalance" And LinkStrings.Find(RefRow)
									< LinkStrings.UBound() Then
									IgnoreValue = True;
								EndIf;
							EndIf;
							If Not IgnoreValue Then
								ArrayOfValues.Add(ResultOfSubordinateReference);
							EndIf;
						EndIf;
						ArrayOfLocalValues.Add(ResultOfSubordinateReference);
						If CalculationLog <> Undefined Then
							CellPresentation = OperandName;
							ArraySize = ArrayOfLocalValues.Count();
							If ArraySize > 1 Then
								CellPresentation = CellPresentation + " #" + ArraySize;
							EndIf;
							ValueForLog = New Structure();
							ValueForLog.Insert("IndicatorName", LinkPrefix);
							ValueForLog.Insert("ItemKind", RefRow.ItemKind);
							ValueForLog.Insert("OperandName", CellPresentation);
							ValueForLog.Insert("StringBase", CellData_.IndexOf(RefRow));
							ValueForLog.Insert("Value", ResultOfSubordinateReference);
							CalculationLog.Add(ValueForLog);
						EndIf;
					EndDo;
					
				Else
					If CalculationLog <> Undefined Then
						ValueForLog = New Structure();
						ValueForLog.Insert("IndicatorName", "Sum");
						ValueForLog.Insert("OperandName", ParametersOfFoundCell.OperandName);
						ValueForLog.Insert("StringBase", -1);
						ValueForLog.Insert("Value", 0);
						CalculationLog.Add(ValueForLog);
					EndIf;
				EndIf;
				
				If ItemKind = Enums.FinancialReportItemKinds.DerivedItem
					Or ItemKind = Enums.FinancialReportItemKinds.Group Then
					If CalculationLog <> Undefined Then
						ValueForLog = New Structure();
						ValueForLog.Insert("IndicatorName", "Sum");
						ValueForLog.Insert("ItemKind", FoundRow.ItemKind);
						ValueForLog.Insert("OperandName", ParametersOfFoundCell.OperandName);
						ValueForLog.Insert("StringBase", CellData_.IndexOf(FoundRow));
						ValueForLog.Insert("Value", ArrayOfLocalValues);
						CalculationLog.Add(ValueForLog);
					EndIf;
					
					PerformFullMatchReplacement(ListOfOperands, OperandName, "");
					If ArrayOfLocalValues.Count() = 1 Then
						ArrayOfLocalValues = ArrayOfLocalValues[0];
					ElsIf ArrayOfLocalValues.Count() = 0 Then
						ArrayOfLocalValues = 0;
					EndIf;
					ArrayOfValues.Add(ArrayOfLocalValues);
					PerformFullMatchReplacement(Formula, OperandName, "ArrayOfValues[" + ArrayOfValues.UBound() + "]");
				EndIf;
				
			EndDo;
			
			If Not IsBlankString(ListOfOperands) Then
				ListOfOperandsNotFound = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ListOfOperands, " ", True);
				For Each OperandName In ListOfOperandsNotFound Do
					PerformFullMatchReplacement(Formula, OperandName, "0");
					If CalculationLog <> Undefined Then
						If Left(OperandName, 1) = "[" Then
							OperandName = Mid(OperandName, 2);
						EndIf;
						If Right(OperandName, 1) = "]" Then
							OperandName = Left(OperandName, StrLen(OperandName) - 1);
						EndIf;
						ValueForLog = New Structure();
						ValueForLog.Insert("IndicatorName", "Sum");
						ValueForLog.Insert("OperandName", OperandName);
						ValueForLog.Insert("StringBase", -1);
						ValueForLog.Insert("Value", 0);
						CalculationLog.Add(ValueForLog);
					EndIf;
				EndDo;
			EndIf;
			
			If StrFind(Upper(Formula), Upper("DateDiff")) Then
				BeginOfPeriod = PeriodParameters_1.BeginOfPeriod;
				EndOfPeriod = PeriodParameters_1.EndOfPeriod;
				ActualDataLimit = PeriodParameters_1.ActualDataLimit;
				PeriodOfGrouping = Undefined;
				For Each PeriodName In PeriodParameters_1.OrderedReportPeriodicities Do
					If ValueIsFilled(DataString1[PeriodName]) Then
						PeriodOfGrouping = DataString1[PeriodName];
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			Try
				If ArrayOfValues.Find("#Val_") <> Undefined Then
					Return "#Val_";
				EndIf;
				
				AdditionalParameters = New Structure();
				AdditionalParameters.Insert("CellData_",       CellData_);
				AdditionalParameters.Insert("CellParameters", 	  CellParameters);
				AdditionalParameters.Insert("PeriodParameters_1", PeriodParameters_1);
				AdditionalParameters.Insert("Prefix", 		  Prefix);  
				AdditionalParameters.Insert("Postfix",		  Postfix);
				AdditionalParameters.Insert("DataString1", 	  DataString1);
				AdditionalParameters.Insert("CalculationLog", 		  CalculationLog);
				AdditionalParameters.Insert("BeginOfPeriod", 	  BeginOfPeriod);
				AdditionalParameters.Insert("EndOfPeriod", 	  EndOfPeriod);
				AdditionalParameters.Insert("ActualDataLimit", ActualDataLimit);
				AdditionalParameters.Insert("PeriodOfGrouping", PeriodOfGrouping);
				AdditionalParameters.Insert("CacheOfBudgetItemDetails", CacheOfBudgetItemDetails);
				
				CalculationResult = CalculateFormulaInSafeMode(Formula, ArrayOfValues, AdditionalParameters);
				
				If TypeOf(CalculationResult) = Type("Array") Then
					If ReverseSign Then
						For Each ArrayElement In CalculationResult Do
							ArrayElement = -ArrayElement;
						EndDo;
					EndIf;
							
					ResultOfCalculationIsResult = 0;
					For Each ArrayElement In CalculationResult Do
						ResultOfCalculationIsResult = ResultOfCalculationIsResult + ArrayElement;
					EndDo;
					CalculationResult = ResultOfCalculationIsResult;
				Else
					If ReverseSign Then 
						CalculationResult = -CalculationResult;
					EndIf;
				EndIf;
				
				DataString1[Prefix + Postfix] = CalculationResult;
			Except
				Return "#Val_";
			EndTry;
			
		Else
			
			Raise NStr("vi = 'Đã xảy ra lỗi trong khi tạo báo cáo: Loại mục chỉ báo không chính xác';
						|ru = 'Ошибка формирования отчета: Неверный вид элемента показателя';
						|en = 'An error occurred while generating the report: Incorrect indicator item kind'; fa = 'An error occurred while generating the report: Incorrect indicator item kind';
						|it = 'Errore nella creazione del rapporto: Tipo incorretto dell''elemento dell''indicatore';
						|pl = 'Błąd utworzenia raportu: Nieprawidłowy rodzaj elementu wskaźnika';
						|tr = 'Raporun oluşturulmasında hata: Geçersiz gösterge öğesi türü'");
		
		EndIf;
		
		DataString1["Calculated" + Prefix + Postfix] = True;
		
	EndIf;
	
	Return DataString1[Prefix + Postfix];
	
EndFunction

// The constructor function of the structure of the passed operands
// 
// Parameters:
// 	Value - Array, Arbitrary -
// 	IndexOf - Number -
// 
// Returns:
// 	Structure - Contains:
// 	* Value - Array, Arbitrary -
// 	* IndexOf - Number -
//
Function NewStructureOfTraversedOperand(Value, IndexOf)
	
	PassedOperand = New Structure("Value, IndexOf", Value, IndexOf);
	
	Return PassedOperand;
	
EndFunction

Procedure PerformFullMatchReplacement(Text, SearchString, ReplacementString)
	
	If SearchString = ReplacementString Then
		Return;
	EndIf; 
	
	TextLength = StrLen(Text);
	SearchStringLength = StrLen(SearchString);
	
	SearchStringPosition = 1;
	StartingSearchPosition = 1;
	
	CompletedReplacements = New Map;
	
	While SearchStringPosition <> 0 Do
		
		SearchStringPosition = StrFind(Text, SearchString, , StartingSearchPosition);
		If SearchStringPosition = 0 Then
			Continue;
		EndIf;
		
		PerformReplacement = True;
		
		PreviousChar = "";
		If SearchStringPosition > 1 Then
			PreviousChar = Mid(Text, SearchStringPosition -1 , 1);
			If Not ServiceSymbol(PreviousChar) Then
				PerformReplacement = False;
			EndIf;
		EndIf;
		
		If PerformReplacement Then
			NextChar = "";
			If SearchStringPosition < TextLength Then
				NextChar = Mid(Text, SearchStringPosition + SearchStringLength, 1);
				If Not ServiceSymbol(NextChar) Then
					PerformReplacement = False;
				EndIf;
			EndIf;
		EndIf;
		
		If PerformReplacement Then
			FullSearchString = StrTemplate("%1%2%3", PreviousChar,SearchString, NextChar);
			If CompletedReplacements[FullSearchString] = Undefined Then
				FullReplacementString = StrTemplate("%1%2%3", PreviousChar,ReplacementString, NextChar);
				Text = StrReplace(Text, FullSearchString, FullReplacementString);
				TextLength = StrLen(Text);
				CompletedReplacements.Insert(FullSearchString, True);
			EndIf;
			
		EndIf;
		
		StartingSearchPosition = SearchStringPosition + StrLen(FullReplacementString);
		If PerformReplacement And PreviousChar <> "" Then
			StartingSearchPosition = StartingSearchPosition - 1;
		EndIf;
		
		If StartingSearchPosition >= TextLength Then
			SearchStringPosition = 0;
		EndIf;
		
	EndDo;
	
EndProcedure

Function ServiceSymbol(Char)
	
	If Char = " "
		Or Char = Chars.CR
		Or Char = Chars.LF
		Or Char = "."
		Or Char = "	"
		Or Char = ","
		Or Char = "("
		Or Char = ")"
		Or Char = "["
		Or Char = "]"
		Or Char = "+"
		Or Char = "-"
		Or Char = "*"
		Or Char = "/"
		Or Char = "="
		Or Char = "<"
		Or Char = ">"
		Or Char = "" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Returns a template of parameters for calculating cell values.
//
// Returns:
//	Structure - The structure of the parameters. See the description of the Calculate Cell Value function.
//
Function TemplateForCellValueCalculationParameters() Export
	
	// Required properties.
	ParameterTemplate = New Structure("CellData_, CellParameters, PeriodParameters_1, DataString1, Prefix");
	
	// Optional properties.
	ParameterTemplate.Insert("CacheOfBudgetItemDetails", Undefined);
	ParameterTemplate.Insert("CalculatingChanges", False);
	
	Return ParameterTemplate;
	
EndFunction

// Returns the calculated cell value for the specified indicator.
//
// Parameters:
//	ParametersForCalculatingValue - Structure - The structure of the parameters required to calculate the values:
//	 * CellData_ - See CellData_
//	 * CellParameters - ValueTable - Table of cell parameters.
//	 * PeriodParameters_1 - Structure       - The structure parameters of the periods.
//	 * DataString1 - ValueTableRow - Calculated data row (cell data tables). Contains:
//	   ** String - CatalogRef.FinancialReportItems, Arbitrary -
//	   ** Column - Arbitrary -
//	   and the other columns from the data Cells
//	 * Prefix - String - Name of the metric to calculate. It can contain the following values:" Quantity"," Amount","Value".
//	 * CalculatingChanges - Boolean - Flag for calculating changes for budget items.
//	 * CacheOfBudgetItemDetails - Structure, Undefined - Cache of settings for budget view elements.
//	CalculationLog - Array, Undefined - Array for recording the calculation log.
//
// Returns:
//	Number, Boolean, Date, String, Undefined - arbitrary calculated values.
//
Function CalculateCellValue(ParametersForCalculatingValue, CalculationLog = Undefined) Export
	
	Prefix = ParametersForCalculatingValue.Prefix;
	DataString1 = ParametersForCalculatingValue.DataString1;
	If Prefix = "Sum" Then
		Postfix = ?(ValueIsFilled(DataString1.Currency), "Curr", "");
	Else
		Postfix = "";
	EndIf;
	
	If CalculationLog <> Undefined Then
		DataString1["Calculated" + Prefix + Postfix] = False;
	EndIf;
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("DataString1",    DataString1);
	CalculationParameters.Insert("Prefix",         Prefix);
	CalculationParameters.Insert("Postfix",        Postfix);
	CalculationParameters.Insert("CalculatingChanges", ParametersForCalculatingValue.CalculatingChanges);
	CalculationParameters.Insert("CacheOfBudgetItemDetails", ParametersForCalculatingValue.CacheOfBudgetItemDetails);
	Value = GetOperandValue(ParametersForCalculatingValue.CellData_,
			ParametersForCalculatingValue.CellParameters,
			ParametersForCalculatingValue.PeriodParameters_1,
			CalculationParameters,,
			CalculationLog);
	Return Value;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	OutputParameters - See AddOutputParameter.OutputParameters
// 	AccumulatedSelection - Structure - LongDesc:
// * SuccessfulReplacements - Map -
// * ReplacementPairs - Map -
// * TakeAppliedRulesIntoAccount - Boolean -
// * WriteInPrivilegedMode - Boolean -
// * IncludeBusinessLogic - Boolean -
// * MarkForDeletion - Boolean -
// * ShouldDeleteDirectly - Boolean -
// 	CellRow - ValueTableRow - See the data:
// 		* String  - CatalogRef.FinancialReportItems, Arbitrary -
// 		* Column - Arbitrary -
// 	ParametersString1 - Structure -
// 	IndicatorName - String - LongDesc
// 	DataLineIndex - Number - LongDesc
// 	ForEditing - Boolean - LongDesc
// Returns:
// 	Number - uid transcripts
//
Function GetDecryption(OutputParameters, AccumulatedSelection, CellRow, ParametersString1, IndicatorName, DataLineIndex, ForEditing) Export
	
	DetailsData = OutputParameters.DetailsData;
	
	Details = NewDecryptionStructure(OutputParameters, AccumulatedSelection, CellRow, ParametersString1, IndicatorName, DataLineIndex, ForEditing);
	
	UIDDecryption = DetailsData.Count() + 1;
	DetailsData.Insert(UIDDecryption, Details);
	
	Return UIDDecryption;
	
EndFunction

Function GetDimensionDecryption(OutputParameters, Value, AccumulatedSelection = Undefined, Group = Undefined)
	Var Details;
	
	DetailsData = OutputParameters.DetailsData;
	
	Details = NewStructureOfGroupingDecryption(OutputParameters, Value, AccumulatedSelection, Group);
	
	UIDDecryption = DetailsData.Count() + 1;
	
	If Details.Count() Then
		DetailsData.Insert(UIDDecryption, Details);
	Else
		DetailsData.Insert(UIDDecryption, Undefined);
	EndIf;
	
	Return UIDDecryption;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	OutputParameters - See AddOutputParameter.OutputParameters
// 	AccumulatedSelection - Structure - LongDesc:
// * SuccessfulReplacements - Map -
// * ReplacementPairs - Map -
// * TakeAppliedRulesIntoAccount - Boolean -
// * WriteInPrivilegedMode - Boolean -
// * IncludeBusinessLogic - Boolean -
// * MarkForDeletion - Boolean -
// * ShouldDeleteDirectly - Boolean -
// 	CellRow - ValueTableRow - See the data:
// 		* String  - CatalogRef.FinancialReportItems, Arbitrary -
// 		* Column - Arbitrary -
// 	ParametersString1 - Structure -
// 	IndicatorName - String - LongDesc
// 	DataLineIndex - Number - LongDesc
// 	ForEditing - Boolean - LongDesc
//
// Returns:
// 	Structure - Possible Values:
//	* String  - CatalogRef.FinancialReportItems, Arbitrary -
//	* Column - Arbitrary -
//	* Currency  - CatalogRef.Currencies - 
//	* BudgetFlowItem - CatalogRef.BudgetFlowItems - 
//	* EditedValue - Arbitrary -
//	* AnalystValues - Map - Contains:
//		** Key - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - 
//		** Value - Arbitrary -
//	* IndicatorName - String -
//	* DataLineIndex - Number -
//
Function NewDecryptionStructure(OutputParameters, AccumulatedSelection, CellRow, ParametersString1, IndicatorName, DataLineIndex, ForEditing)
	
	Details = New Structure;
	If ForEditing Then
		
		Details.Insert("String",  CellRow.String);
		Details.Insert("Column", CellRow.Column);
		
		If ValueIsFilled(CellRow.Currency) Then
			Details.Insert("Currency", CellRow.Currency);
		Else
			TheStructureOfTheSearch = New Structure("String, Column, CurrencyIsDeterminedByDimension", CellRow.String, CellRow.Column, True);
			FoundRows = OutputParameters.CacheOfCurrencyParameters.FindRows(TheStructureOfTheSearch);
			If FoundRows.Count() Then
				
				NameKey = FinancialReportingCached.NameOfBudgetReportField(FoundRows[0].DimensionCurrencies);
				CurrencyAnalyticsValue = Undefined;
				
				If AccumulatedSelection.Property(NameKey, CurrencyAnalyticsValue) Then
					WithdrawalCurrency = Attachable_ValueFromAnalytics(
						OutputParameters.CacheAnalystValues,
						CurrencyAnalyticsValue,
						FoundRows[0].UnitOfMeasureFilling);
					
					If ValueIsFilled(WithdrawalCurrency) Then
						Details.Insert("Currency", WithdrawalCurrency);
					EndIf;
				EndIf;
				
			EndIf;
		EndIf;
		
		If ValueIsFilled(CellRow.BudgetFlowItem) Then
			Details.Insert("BudgetFlowItem", CellRow.BudgetFlowItem);
		ElsIf ValueIsFilled(CellRow.EditedValue) Then
			Details.Insert("EditedValue", CellRow.EditedValue);
		EndIf;
		
		MatchingAnalystValues = New Map;
		For Each DimensionKind In OutputParameters.ColumnStructureOfDataTable.DimensionKinds Do
			NameKey = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
			Value = BudgetingClientServer.EmptyDimensionValue();
			AccumulatedSelection.Property(NameKey, Value);
			MatchingAnalystValues.Insert(DimensionKind, Value);
		EndDo;
		
		Details.Insert("AnalystValues", MatchingAnalystValues);
		
		For Each KeyAndValue In AccumulatedSelection Do
			If BudgetReportingClientServer.ThisIsPeriodField(KeyAndValue.Key) Then
				Details.Insert(KeyAndValue.Key, KeyAndValue.Value);
			EndIf;
		EndDo;
		
	EndIf;
	
	Details.Insert("IndicatorName", IndicatorName);
	If IndicatorName = "Sum" Then
		Postfix = ?(ValueIsFilled(CellRow.Currency), "Curr", "");
	Else
		Postfix = "";
	EndIf;
	If DataLineIndex = Undefined Then
		Details.Insert("Value", Undefined);
	Else
		Details.Insert("Value", CellRow[IndicatorName + Postfix]);
		Details.Insert("DataLineIndex", DataLineIndex);
	EndIf;
	
	Return Details;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	OutputParameters - See AddOutputParameter.OutputParameters
// 	Value - Arbitrary, Undefined -
// 	AccumulatedSelection - Structure, Undefined - LongDesc:
// * SuccessfulReplacements - Map -
// * ReplacementPairs - Map -
// * TakeAppliedRulesIntoAccount - Boolean -
// * WriteInPrivilegedMode - Boolean -
// * IncludeBusinessLogic - Boolean -
// * MarkForDeletion - Boolean -
// * ShouldDeleteDirectly - Boolean -
// 	Group - Arbitrary, Undefined -
//
// Returns:
//  Structure - Possible Values:
//   * String   - CatalogRef.FinancialReportItems, Arbitrary -
//   * Value - Arbitrary -
//   * AnalystValues - Map - Contains:
//      ** Key - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - 
//      ** Value - Arbitrary -
//   * GroupingID - UUID - 
//
Function NewStructureOfGroupingDecryption(OutputParameters, Value, AccumulatedSelection = Undefined, Group = Undefined)
	
	Details = New Structure;
	
	If Group <> Undefined Then
		Details.Insert("String", Group.ReportItem);
	EndIf;
	
	Details.Insert("Value", Value);
	
	If AccumulatedSelection <> Undefined Then
		MatchingAnalystValues = New Map;
		For Each DimensionKind In OutputParameters.ColumnStructureOfDataTable.DimensionKinds Do
			NameKey = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
			DimensionValue = Undefined;
			AccumulatedSelection.Property(NameKey, DimensionValue);
			MatchingAnalystValues.Insert(DimensionKind, DimensionValue);
		EndDo;
		If OutputParameters.PeriodParameters_1.Property("OrderedReportPeriodicities")
			And TypeOf(OutputParameters.PeriodParameters_1.OrderedReportPeriodicities) = Type("Array") Then
			For Each StringPeriod In OutputParameters.PeriodParameters_1.OrderedReportPeriodicities Do
				If OutputParameters.ColumnStructure1.Rows.Find(StringPeriod, "DimensionName", True) = Undefined
					And AccumulatedSelection.Property(StringPeriod) Then
					Details.Insert(StringPeriod, AccumulatedSelection[StringPeriod]);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Details.Insert("AnalystValues", MatchingAnalystValues);
	Details.Insert("GroupingID", New UUID);
	
	Return Details;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	Value - Arbitrary, Undefined - LongDesc
// 	ReportRow - Arbitrary - the tree string contains, among other things:
// 		*AdditionalFields - ValueTable - contains including:
// 			**Attribute - Arbitrary -
// 			**Description - String -
// 			**AttributeName - String -
// 			**Title - String -
// 			**TitleOutput - Boolean -
// 			**InSeparateColumn - Boolean -
// 	OutputParameters - Structure - LongDesc:
// * ForEditing - Boolean -
// * StructureOfAreas - Structure -:
// ** TableNumber - SpreadsheetDocument -
// ** ColumnNumberingStartOfTableRowNumbering - SpreadsheetDocument -
// ** HeaderStartOfTableRowNumbering - SpreadsheetDocument -
// ** IsBlankString - SpreadsheetDocument -
// ** TableHeading - SpreadsheetDocument -
// ** Text - SpreadsheetDocument -
// ** ReportHeader - SpreadsheetDocument -
// * ResultDocument - SpreadsheetDocument -
// * CellDataAddedRows - ValueTable -
// * CacheOfEmptyAnalyticsPresentations - Map -
// 	TheseAreColumns - Boolean - LongDesc
// Returns:
// 	Arbitrary, String, Undefined - LongDesc
Function GroupingText(Value, ReportRow, OutputParameters, TheseAreColumns = False)
	
	Presentation = ReportRow.NameForPrinting;
	DimensionKind = ReportRow.DimensionKind;
	
	If Not ValueIsFilled(Value) Then
		If ValueIsFilled(DimensionKind) Then
			Return BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
				DimensionKind, "OtherItems",, OutputParameters.CacheOfEmptyAnalyticsPresentations);
		ElsIf Not ValueIsFilled(DimensionKind)
			And ReportRow.ItemKind = Enums.FinancialReportItemKinds.Dimension
			And ValueIsFilled(ReportRow.DimensionName) Then
			Return BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
				ReportRow.DimensionName, "OtherItems",, OutputParameters.CacheOfEmptyAnalyticsPresentations);
		ElsIf Not IsBlankString(Presentation) Then
			Return Presentation;
		Else
			Return BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
				"", "OtherItems",, OutputParameters.CacheOfEmptyAnalyticsPresentations);
		EndIf;
	EndIf;
	
	ItemKind = ReportRow.ItemKind;
	ReportItem = ReportRow.ReportItem;
	DimensionName = ReportRow.DimensionName;
	
	ItemsKinds = Enums.FinancialReportItemKinds;
	
	If ItemKind = ItemsKinds.Dimension And StrFind(DimensionName, "Period") Then
		
		Periodicity = Enums.Periodicity[StrReplace(DimensionName, "Period", "")];
		Return WorkingWithClientServerPeriods.PresentationOfPeriodByDate(Value, Periodicity);
		
	EndIf;
	
	If ItemKind = ItemsKinds.Dimension Then
		
		IndexName = "";
		TheStructureOfTheSearch = New Structure();
		If TheseAreColumns Then
			TheStructureOfTheSearch.Insert("Column", ReportItem);
			IndexName = "Column";
		Else
			TheStructureOfTheSearch.Insert("String", ReportItem);
			IndexName = "String";
		EndIf;
		TheStructureOfTheSearch.Insert(DimensionName, Value);
		IndexName = IndexName + "," + DimensionName;
		
		If OutputParameters.DimensionSearchIndexes[IndexName] = Undefined Then
			
			MeasurementPresentations = OutputParameters.MeasurementPresentations; // See PresentationOfReportDimensions
			MeasurementPresentations.Indexes.Add(IndexName);
			OutputParameters.DimensionSearchIndexes.Insert(IndexName, True);
		EndIf;
		
		DataRows = OutputParameters.MeasurementPresentations.FindRows(TheStructureOfTheSearch);
		
		If Not DataRows.Count() Then //if the reference type in the columns is not at the last level
			NameOfGrouping = String(Value);
		Else
			PresentationRow = DataRows[0];
			NameOfGrouping = PresentationRow[DimensionName + "Presentation"];
			For Each AdditionalAttribute In ReportRow.AdditionalFields Do
				If AdditionalAttribute.InSeparateColumn Then
					Continue;
				EndIf;
				NameOfGrouping = NameOfGrouping + ", ";
				If Not IsBlankString(AdditionalAttribute.Title) Then
					NameOfGrouping = NameOfGrouping + AdditionalAttribute.Title + ": ";
				EndIf;
				NameOfGrouping = NameOfGrouping + PresentationRow[DimensionName + AdditionalAttribute.AttributeName];
			EndDo;
		EndIf;
	
	Else
		
		If ValueIsFilled(Presentation) Then
			NameOfGrouping = Presentation;
		Else
			NameOfGrouping = String(Value);
		EndIf;
		
	EndIf;
	
	If ItemKind = ItemsKinds.AllBudgetFlowItems
		Or ItemKind = ItemsKinds.AllBudgetBalanceItems
		Or ItemKind = ItemsKinds.BudgetFlowItem
		Or ItemKind = ItemsKinds.BudgetBalanceItem
		Or ItemKind = ItemsKinds.NonFinancialItem Then
		
		UnitParameterCache = OutputParameters.CacheOfUnitParameters;
		TheStructureOfTheSearch = New Structure;
		If TheseAreColumns Then
			TheStructureOfTheSearch.Insert("Column", ReportItem);
		Else
			TheStructureOfTheSearch.Insert("String", ReportItem);
		EndIf;
		TheStructureOfTheSearch.Insert("AccountingObject", Value);
		TheStructureOfTheSearch.Insert("UnitOfMeasureIsDeterminedByDimension", False);
		
		UnitOutputParameters = UnitParameterCache.FindRows(TheStructureOfTheSearch);
		
		If UnitOutputParameters.Count() Then
			
			UnitOfMeasure = UnitOutputParameters[0].UnitOfMeasure;
			
			If ValueIsFilled(UnitOfMeasure) Then
				NameOfGrouping = NameOfGrouping + ", " + UnitOfMeasure;
			EndIf;
			
		EndIf;
		
	ElsIf ValueIsFilled(DimensionKind) Then
		
		UnitParameterCache = OutputParameters.CacheOfUnitParameters;
		TheStructureOfTheSearch = New Structure;
		If TheseAreColumns Then
			TheStructureOfTheSearch.Insert("Column", ReportItem);
		Else
			TheStructureOfTheSearch.Insert("String", ReportItem);
		EndIf;
		TheStructureOfTheSearch.Insert("UnitOfMeasureIsDeterminedByDimension", True);
		TheStructureOfTheSearch.Insert("DimensionUnitsOfMeasurement", DimensionKind);
		
		UnitOutputParameters = UnitParameterCache.FindRows(TheStructureOfTheSearch);
		
		If UnitOutputParameters.Count() Then
			
			UnitOfMeasure = Attachable_ValueFromAnalytics(
				OutputParameters.CacheAnalystValues, Value,
				UnitOutputParameters[0].UnitOfMeasureFilling);
			If ValueIsFilled(UnitOfMeasure) Then
				NameOfGrouping = NameOfGrouping + ", " + UnitOfMeasure;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return NameOfGrouping;
	
EndFunction

Function AddDesignArea(Parameters, DerivedArea, AccumulatedSelection,
									TableNumber, LineNumber, ColumnNumber)
	
	OutputParameters = Parameters.OutputParameters;
	String = Parameters.ReportItem;
	Column = Parameters.Column;
	
	ReportDataForFormatting =
		OutputParameters.ReportDataForFormatting; // See BudgetReportingCacheCalculationServer.ReportDataForFormatting
	If ReportDataForFormatting = Undefined Then
		Return Undefined;
	EndIf;
	
	NewLayoutLine = ReportDataForFormatting.Add();
	NewLayoutLine.AreaName = DerivedArea.Name;
	NewLayoutLine.String = String;
	NewLayoutLine.Column = Column;
	NewLayoutLine.LineNumber = LineNumber;
	NewLayoutLine.ColumnNumber = ColumnNumber;
	NewLayoutLine.TableNumber = TableNumber;
	
	If AccumulatedSelection <> Undefined Then
		FillPropertyValues(NewLayoutLine, AccumulatedSelection);
	EndIf;
	
	Return NewLayoutLine;
	
EndFunction

Procedure MergeUnusedCells(ResultDocument, MergeParameters, OutputParameters, CurrentFilter,
											TablesCounter, LineCounter)
	
	OutputArea2    = MergeParameters.OutputArea2;
	ScopeOfAdmission = MergeParameters.ScopeOfAdmission;
	Union       = MergeParameters.Union;
	ReportItem    = MergeParameters.ReportItem;
	
	If Not Union Then
		Return;
	EndIf;
	
	ScopeOfAdmission.Parameters.Group = Undefined;
	ScopeOfAdmission.Parameters.Details = Undefined;
	For Cnt = 1 To Union Do
		Dummy = ResultDocument.Join(ScopeOfAdmission);
		
		ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
		ParametersSet.OutputParameters = OutputParameters;
		ParametersSet.ReportItem = ReportItem;
		ParametersSet.Column = Undefined;
		AddDesignArea(ParametersSet,
				Dummy,
				CurrentFilter,
				TablesCounter,
				LineCounter,
				Undefined);
		
	EndDo;
	Dummy = ResultDocument.Area(OutputArea2.Top,
			OutputArea2.Left + Number(OutputParameters.TableParameters.DisplayRowsNumbering),
			OutputArea2.Top,
			OutputArea2.Right + Union);
	Dummy.Merge();
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	ResultDocument - Structure, SpreadsheetDocument - LongDesc
// 	Parameters - Structure - LongDesc:
// 	*ReportRow - ValueTreeRow - A line in the budget settings tree:
// 	  **AdditionalFields - ValueTable - Table of additional fields:
// 		***Attribute - Arbitrary -
// 		***Description - String -
// 		***AttributeName - String -
// 		***Title - String -
// 		***TitleOutput - Boolean -
// 		***InSeparateColumn - Boolean -
// 	*Value - Undefined -
// 	*Area - Undefined -
// 	*Column - Undefined -
// 	*ReportItem - Undefined -
// 	*OutputParameters - Undefined -
// 	OutputArea2 - SpreadsheetDocumentRange - LongDesc
// 	CurrentFilter - Structure - LongDesc
// 	LineCounter - Number - LongDesc
// 	TablesCounter - Number - LongDesc
//
Procedure OutputAdditionalFields(ResultDocument, Parameters, OutputArea2, CurrentFilter, LineCounter, TablesCounter)
	
	OutputParameters = Parameters.OutputParameters; // See AddOutputParameter.OutputParameters
	Area = Parameters.Area; // SpreadsheetDocument - 
	Value = Parameters.Value;
	ReportRow = Parameters.ReportRow;
	ReportItem = Parameters.ReportItem;
	
	MeasurementPresentations = OutputParameters.MeasurementPresentations;
	
	If ReportRow.ItemKind <> Enums.FinancialReportItemKinds.Dimension Then
		Return;
	EndIf;
	
	If StrFind(ReportRow.DimensionName, "Period") Then
		Return;
	EndIf;
	
	If Not ReportRow.AdditionalFields.Count() Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("String", ReportItem);
	IndexName = "String";
	TheStructureOfTheSearch.Insert(ReportRow.DimensionName, Value);
	IndexName = IndexName + "," + ReportRow.DimensionName;
	DimensionName = ReportRow.DimensionName;
	
	If OutputParameters.DimensionSearchIndexes[IndexName] = Undefined Then
		MeasurementPresentations.Indexes.Add(IndexName);
		OutputParameters.DimensionSearchIndexes.Insert(IndexName, True);
	EndIf;
	
	DataRows = OutputParameters.MeasurementPresentations.FindRows(TheStructureOfTheSearch);
	
	PresentationRow = Undefined;
	If DataRows.Count() Then
		PresentationRow = DataRows[0];
	EndIf;
	
	For Each AdditionalAttribute In ReportRow.AdditionalFields Do
		If Not AdditionalAttribute.InSeparateColumn Then
			Continue;
		EndIf;
		NameOfGrouping = "";
		If PresentationRow <> Undefined Then
			If Not IsBlankString(AdditionalAttribute.Title) Then
				NameOfGrouping = NameOfGrouping + AdditionalAttribute.Title + ": ";
			EndIf;
			NameOfGrouping = NameOfGrouping + PresentationRow[DimensionName + AdditionalAttribute.AttributeName];
		EndIf;
		Area["Parameters"].Group = NameOfGrouping;
		Area["Parameters"].Details = OutputArea2.Details;
		OutputArea2 = ResultDocument.Join(Area);
		
		ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
		ParametersSet.OutputParameters = OutputParameters;
		ParametersSet.ReportItem = ReportItem;
		ParametersSet.Column = Undefined;
		AddDesignArea(ParametersSet, OutputArea2, CurrentFilter,
			TablesCounter, LineCounter, Undefined);
	EndDo;
	
EndProcedure

Function CalculateRelatedBudgetItems(BudgetProfileDisplayParameters, AddressOfCellData, DataParameters,
								AreaName, ReflectionResult, AllRows = False, ThereAreChangesInRelatedCells = False) Export
	
	If TypeOf(BudgetProfileDisplayParameters) = Type("String") Then
		BudgetViewParameters = GetFromTempStorage(BudgetProfileDisplayParameters);
	Else
		BudgetViewParameters = BudgetProfileDisplayParameters;
	EndIf;
	
	If TypeOf(AddressOfCellData) = Type("String") Then
		CellData_ = GetFromTempStorage(AddressOfCellData); // See CellData_
	Else
		CellData_ = AddressOfCellData; // See CellData_
	EndIf;
	
	StructureOfReportDescription = BudgetViewParameters.StructureOfReportDescription;
	CellStructure = StructureOfReportDescription.CellStructure;
	CellParameters = StructureOfReportDescription.CellParameters;
	ColumnStructure1 = BudgetViewParameters.ColumnStructureOfDataTable;
	PeriodParameters_1 = ConvertDataParametersToPeriodData(BudgetViewParameters.ColumnStructureOfDataTable, DataParameters);
	CacheOfBudgetItemDetails = Undefined;
	If BudgetViewParameters.Property("CacheOfBudgetItemDetails") Then
		CacheOfBudgetItemDetails = BudgetProfileDisplayParameters.CacheOfBudgetItemDetails;
	ElsIf BudgetViewParameters.Property("DataCache")
		And BudgetViewParameters.DataCache.Property("CacheOfBudgetItemDetails") Then
		CacheOfBudgetItemDetails = BudgetViewParameters.DataCache.CacheOfBudgetItemDetails;
	EndIf;
	
	If AllRows = True Then
		
		TheStructureOfTheSearch = New Structure("MainItem", True);
		FoundRows = CellData_.FindRows(TheStructureOfTheSearch);
		
		LinesToCalculate = New Array;
		For Each TableRow In FoundRows Do
			
			If CellParameters.Find(TableRow.RowIndex, "RowIndex").CalculationFilling <> "recalculate" Then
				Continue;
			EndIf;
			
			TableRow.CalculatedSum = False;
			TableRow.CalculatedCount = False;
			TableRow.CalculatedSumCurr = False;
			LinesToCalculate.Add(TableRow);
			
		EndDo;
		
	Else
		
		If TypeOf(AreaName) = Type("String") Then
			
			CalculationLine = CellData_.Find(AreaName, "AreaNameSum");
			If CalculationLine <> Undefined Then
				CellParameters_ = CellParameters.Find(CalculationLine.RowIndex, "RowIndex");
				CurrencyPrefix_ = ?(ValueIsFilled(CalculationLine.Currency), "Curr", "");
				CalculationLine["Sum" + CurrencyPrefix_ + CellParameters_.SourceField] = ReflectionResult.AmountInCurrency;
				CalculationLine["Sum" + CellParameters_.SourceField] = ReflectionResult.Sum;	
				If TypeOf(ReflectionResult.Sum) = Type("Number") Then
					CalculationLine.Sum = ?(CellParameters_.ReverseSign, -1, 1) * ReflectionResult.Sum;
				Else
					CalculationLine.Sum = ReflectionResult.Sum;
				EndIf;
				If TypeOf(ReflectionResult.AmountInCurrency) = Type("Number") Then
					CalculationLine.SumCurr = ?(CellParameters_.ReverseSign, -1, 1) * ReflectionResult.AmountInCurrency;
				Else
					CalculationLine.SumCurr = ReflectionResult.AmountInCurrency;
				EndIf;
			EndIf;
			
			If CalculationLine = Undefined Then
				CalculationLine = CellData_.Find(AreaName, "AreaNameCount");
				If CalculationLine <> Undefined Then
					CellParameters_ = CellParameters.Find(CalculationLine.RowIndex, "RowIndex");
					CalculationLine["Count" + CellParameters_.SourceField] = ReflectionResult.Count;
					If TypeOf(ReflectionResult.Count) = Type("Number") Then
						CalculationLine.Count = ?(CellParameters_.ReverseSign, -1, 1) * ReflectionResult.Count;
					Else
						CalculationLine.Count = ReflectionResult.Count;
					EndIf;
				EndIf;
			EndIf;
			
			If CalculationLine = Undefined Then
				CalculationLine = CellData_.Find(AreaName, "AreaNameValue");
				If CalculationLine <> Undefined Then
					CalculationLine.Value = ReflectionResult.Value;
				EndIf;
			EndIf;
			
			If Not CalculationLine = Undefined Then
				PropertyNameNote = "Note";
				If ReflectionResult.Property(PropertyNameNote) Then
					CalculationLine[PropertyNameNote] = ReflectionResult[PropertyNameNote];
				EndIf;
			EndIf;
			
		ElsIf TypeOf(AreaName) = Type("Structure") Then
			
			IndicatorName = Undefined;
			If AreaName.Property("IndicatorName", IndicatorName) Then
				AreaName.Delete("IndicatorName");
			Else
				IndicatorName = "Sum";
			EndIf;
			
			BaseLines = Undefined;
			If AreaName.Property("BaseLines", BaseLines) Then
				AreaName.Delete("BaseLines");
			Else
				If TypeOf(AreaName.String) = Type("Array") Then
					BaseLines = AreaName.String;
				Else
					BaseLines = CommonClientServer.ValueInArray(AreaName.String);
				EndIf;
				AreaName.Delete("String");
			EndIf;
			
			AreaName.Insert("MainItem", True);
			For Each String In BaseLines Do
				AreaName.Insert("String", String);
				CalculationLines = CellData_.FindRows(AreaName);
				If Not CalculationLines.Count() Then
					CellSearchStructure_ = New Structure("String, Column, MainItem", String, AreaName.Column, True);
					CellStructureString = BudgetViewParameters.StructureOfReportDescription.CellStructure.FindRows(CellSearchStructure_);
					FillingStructure = Common.CopyRecursive(AreaName);
					NewRow = AddRowOfCellData(CellData_, CellStructureString[0], FillingStructure, AreaName.Column);
					CalculationLines.Add(NewRow);
				EndIf;
			EndDo;
			
			For Each StringSearch In CalculationLines Do
				
				CellParameters_ = CellParameters.Find(StringSearch.RowIndex, "RowIndex");
				If CellParameters_.FlagSum And IndicatorName = "Sum" Then
					CalculationLine = StringSearch;
					Break;
				ElsIf CellParameters_.FlagCount And IndicatorName = "Count" Then
					CalculationLine = StringSearch;
					Break;
				ElsIf CellParameters_.FlagValue And IndicatorName = "Value" Then
					CalculationLine = StringSearch;
					Break;
				EndIf;
				
			EndDo;
			
			If CalculationLine = Undefined Then
				// The case when there is no row in the cell data
				// , for example, when it is a row added through a list.
				Return Undefined;
			EndIf;
			
			CellParameters_ = CellParameters.Find(CalculationLine.RowIndex, "RowIndex");
			
			If IndicatorName = "Sum" Then
				CurrencyPrefix_ = ?(ValueIsFilled(CalculationLine.Currency), "Curr", "");
				CalculationLine["Sum" + CurrencyPrefix_ + CellParameters_.SourceField] = ReflectionResult.AmountInCurrency;
				CalculationLine["Sum" + CellParameters_.SourceField] = ReflectionResult.Sum;
				If TypeOf(ReflectionResult.Sum) = Type("Number") Then
					CalculationLine.Sum = ?(CellParameters_.ReverseSign, -1, 1) * ReflectionResult.Sum;
				Else
					CalculationLine.Sum = ReflectionResult.Sum;
				EndIf;
				If TypeOf(ReflectionResult.AmountInCurrency) = Type("Number") Then
					CalculationLine.SumCurr = ?(CellParameters_.ReverseSign, -1, 1) * ReflectionResult.AmountInCurrency;
				Else
					CalculationLine.SumCurr = ReflectionResult.AmountInCurrency;
				EndIf;
				CalculationLine.CalculatedSum = True;
			EndIf;
			If IndicatorName = "Count" Then
				CalculationLine["Count" + CellParameters_.SourceField] = ReflectionResult.Count;
				If TypeOf(ReflectionResult.Count) = Type("Number") Then
					CalculationLine.Count = ?(CellParameters_.ReverseSign, -1, 1) * ReflectionResult.Count;
				Else
					CalculationLine.Count = ReflectionResult.Count;
				EndIf;
				CalculationLine.CalculatedCount = True;
			EndIf;
			If IndicatorName = "Value" Then
				CalculationLine.Value = ReflectionResult.Value;
				CalculationLine.CalculatedValue = True;
			EndIf;
			PropertyNameNote = "Note";
			If ReflectionResult.Property(PropertyNameNote)
				And Not CalculationLine = Undefined Then 
				CalculationLine[PropertyNameNote] = ReflectionResult[PropertyNameNote];
			EndIf;
		
		EndIf;
		
		// only related to the current
		TheStructureOfTheSearch = New Structure("MainItem, String, Column", True, CalculationLine.String, CalculationLine.Column);
		CellStructureString = CellStructure.FindRows(TheStructureOfTheSearch)[0];
		CellParameters_ = CellParameters.Find(CellStructureString.RowIndex, "RowIndex");
		
		LinesToCalculate = New Array;
		
		RelatedCells = CellParameters_.RelatedCells; // See CellData_
		For Each LinkedCell In RelatedCells Do
			
			TheStructureOfTheSearch = New Structure(LinkedCell.GeneralMeasurements);
			FillPropertyValues(TheStructureOfTheSearch, CalculationLine);
			TheStructureOfTheSearch.Insert("String", LinkedCell.String);
			TheStructureOfTheSearch.Insert("Column", LinkedCell.Column);
			TheStructureOfTheSearch.Insert("MainItem", True);
			
			FoundRows = CellData_.FindRows(TheStructureOfTheSearch);
			If Not FoundRows.Count() Then
				CellSearchStructure_ = New Structure("String, Column, MainItem", TheStructureOfTheSearch.String, TheStructureOfTheSearch.Column, True);
				CellStructureString = BudgetViewParameters.StructureOfReportDescription.CellStructure.FindRows(CellSearchStructure_);
				NewRow = AddRowOfCellData(CellData_, CellStructureString[0], TheStructureOfTheSearch, LinkedCell.Column);
				FoundRows = CellData_.FindRows(CellSearchStructure_);
				If FoundRows.Count() Then
					FillPropertyValues(NewRow, FoundRows[0], , LinkedCell.GeneralMeasurements);
				EndIf;
				LinesToCalculate.Add(NewRow);
			Else
				For Each TableRow In FoundRows Do
					TableRow.CalculatedSum = False;
					TableRow.CalculatedCount = False;
					TableRow.CalculatedSumCurr = False;
					LinesToCalculate.Add(TableRow);
				EndDo;
			EndIf;
			
		EndDo;
	EndIf;
	
	ChangesTable = New ValueTable;
	ChangesTable.Columns.Add("AreaName");
	ChangesTable.Columns.Add("Value");
	ChangesTable.Columns.Add("Details");
	
	For Each TableRow In LinesToCalculate Do
		
		ThereAreChangesInRelatedCells = True;
		
		Details = New Structure;
		For Each Periodicity In ColumnStructure1.Periodicity_ Do
			PeriodAsString = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
			If ValueIsFilled(TableRow[PeriodAsString]) Then
				Details.Insert(PeriodAsString, TableRow[PeriodAsString]);
			EndIf;
		EndDo;
		For Each Dimension In ColumnStructure1.Dimensions Do
			If ValueIsFilled(TableRow[Dimension]) Then
				Details.Insert(Dimension, TableRow[Dimension]);
			EndIf;
		EndDo;
		MatchingAnalystValues = New Map;
		For Each Field In ColumnStructure1.DimensionKinds Do
			Dimension = FinancialReportingCached.NameOfBudgetReportField(Field);
			If ValueIsFilled(TableRow[Dimension]) Then
				MatchingAnalystValues.Insert(Field, TableRow[Dimension]);
			EndIf;
		EndDo;
		Details.Insert("AnalystValues", MatchingAnalystValues);
		If ValueIsFilled(TableRow.Currency) Then
			Details.Insert("Currency", TableRow.Currency);
		EndIf;
		Details.Insert("BudgetFlowItem", TableRow.BudgetFlowItem);
		
		DecryptionAmount = Details;
		DecryptionQuantity = Common.CopyRecursive(DecryptionAmount);
		
		CellParameters_ = CellParameters.Find(TableRow.RowIndex, "RowIndex");
		If CellParameters_.ReverseSign = Undefined Then
			CellParameters_.ReverseSign = False;
		EndIf;
		
		If CellParameters_.FlagCount Then
			DecryptionQuantity.Insert("IndicatorName", "Count");
			
			ParametersForCalculatingValue = TemplateForCellValueCalculationParameters();
			ParametersForCalculatingValue.CellData_ = CellData_;
			ParametersForCalculatingValue.CellParameters = CellParameters;
			ParametersForCalculatingValue.PeriodParameters_1 = PeriodParameters_1;
			ParametersForCalculatingValue.DataString1 = TableRow;
			ParametersForCalculatingValue.Prefix = "Count";
			ParametersForCalculatingValue.CalculatingChanges = True;
			ParametersForCalculatingValue.CacheOfBudgetItemDetails = CacheOfBudgetItemDetails;
			Count = CalculateCellValue(ParametersForCalculatingValue);
			
			NewUpdate = ChangesTable.Add();
			NewUpdate.AreaName = TableRow.AreaNameCount;
			// In the document data for input, the value of the associated cell must be entered
			// with a positive sign.
			If Count = "#Val_" Then
				NewUpdate.Value = Count;
			Else
				If TypeOf(Count) <> Type("Number") Then
					NewUpdate.Value = "#Val_";
				Else
					NewUpdate.Value = Count * ?(CellParameters_.ReverseSign, -1, 1);
				EndIf;
			EndIf;
			NewUpdate.Details = DecryptionQuantity;
		EndIf;
		
		If CellParameters_.FlagSum Then
			DecryptionAmount.Insert("IndicatorName", "Sum");
			
			ParametersForCalculatingValue = TemplateForCellValueCalculationParameters();
			ParametersForCalculatingValue.CellData_ = CellData_;
			ParametersForCalculatingValue.CellParameters = CellParameters;
			ParametersForCalculatingValue.PeriodParameters_1 = PeriodParameters_1;
			ParametersForCalculatingValue.DataString1 = TableRow;
			ParametersForCalculatingValue.Prefix = "Sum";
			ParametersForCalculatingValue.CalculatingChanges = True;
			ParametersForCalculatingValue.CacheOfBudgetItemDetails = CacheOfBudgetItemDetails;
			Sum = CalculateCellValue(ParametersForCalculatingValue);
			
			NewUpdate = ChangesTable.Add();
			NewUpdate.AreaName = TableRow.AreaNameSum;
			// In the document data for input, the value of the associated cell must be entered
			// with a positive sign.
			If Sum = "#Val_" Then
				NewUpdate.Value = Sum;
			Else
				If TypeOf(Sum) <> Type("Number") Then
					NewUpdate.Value = "#Val_";
				Else
					NewUpdate.Value = Sum * ?(CellParameters_.ReverseSign, -1, 1);
				EndIf;
			EndIf;
			NewUpdate.Details = DecryptionAmount;
		EndIf;
		
	EndDo;
	
	Result = New Structure("Result, BudgetProfileDisplayParameters, CellData_", ChangesTable, BudgetViewParameters, CellData_);
	Return Result;
	
EndFunction

Function CalculateChangesInReport(ParametersForCalculatingChanges)
	
	CellParameters = ParametersForCalculatingChanges.CellParameters;
	PeriodParameters_1 = ParametersForCalculatingChanges.PeriodParameters_1;
	PreviousCellData = ParametersForCalculatingChanges.PreviousCellData;
	NewCellData = ParametersForCalculatingChanges.NewCellData;
	LinesToCalculate = ParametersForCalculatingChanges.LinesToCalculate;
	SourceLinesToRecalculate = ParametersForCalculatingChanges.SourceLinesToRecalculate;
	SearchIndexes = ParametersForCalculatingChanges.CellDataTableIndexes;
	CacheOfBudgetItemDetails = ParametersForCalculatingChanges.CacheOfBudgetItemDetails;
	
	ChangesTable = New Map;
	
	NewCellData.Indexes.Clear();
	PreviousCellData.Indexes.Clear();
	For Each IndexOf In SearchIndexes Do
		NewCellData.Indexes.Add(IndexOf.Key);
		PreviousCellData.Indexes.Add(IndexOf.Key);
	EndDo;
	
	ParametersForCalculatingValue = TemplateForCellValueCalculationParameters();
	ParametersForCalculatingValue.CellData_ = NewCellData;
	ParametersForCalculatingValue.CellParameters = CellParameters;
	ParametersForCalculatingValue.PeriodParameters_1 = PeriodParameters_1;
	ParametersForCalculatingValue.CalculatingChanges = False;
	ParametersForCalculatingValue.CacheOfBudgetItemDetails = CacheOfBudgetItemDetails;
	
	For Each RowOfNewData In LinesToCalculate Do
		CellParameters_ = CellParameters.Find(RowOfNewData.RowIndex, "RowIndex");
		ParametersForCalculatingValue.DataString1 = RowOfNewData;
		If CellParameters_.FlagSum Then
			ParametersForCalculatingValue.Prefix = "Sum";
			CalculateCellValue(ParametersForCalculatingValue);
		EndIf;
		If CellParameters_.FlagCount Then
			ParametersForCalculatingValue.Prefix = "Count";
			CalculateCellValue(ParametersForCalculatingValue);
		EndIf;
		If CellParameters_.FlagValue Then
			ParametersForCalculatingValue.Prefix = "Value";
			CalculateCellValue(ParametersForCalculatingValue);
		EndIf;
	EndDo;
	
	RowsToRecalculateChangesInHierarchy = New Map;
	
	// Iteration = 1 - calculation of the final cells, 
	// Iteration = 2 - calculation of connected cells.
	Iteration = 1;
	LinesToRecalculateChanges = New Map;
	RelatedRowsToRecalculate = New Map;
	UniqueChangeStrings = New Map;
	ChangesToLinkedCells = New Array;
	CalculationFillingTotal = Lower("Total");
	
	ReverseColumnNames = "";
	If NewCellData.Columns.Find("CountTurnover") <> Undefined Then
		ReverseColumnNames = ReverseColumnNames + ", " + "CountTurnover";
	EndIf;
	If NewCellData.Columns.Find("SumTurnover") <> Undefined Then
		ReverseColumnNames = ReverseColumnNames + ", " + "SumTurnover";
	EndIf;
	If NewCellData.Columns.Find("SumCurrTurnover") <> Undefined Then
		ReverseColumnNames = ReverseColumnNames + ", " + "SumCurrTurnover";
	EndIf;
	
	While Iteration <= 2 Do
		
		If Iteration = 1 Then
			RowsToRecalculate_ = SourceLinesToRecalculate;
		Else
			RowsToRecalculate_ = RelatedRowsToRecalculate;
		EndIf;
		
		For Each KeyRowsToRecalculate In RowsToRecalculate_ Do
			ReportCell = KeyRowsToRecalculate.Key;
			
			If ReportCell.FilterCells = Undefined Then
				Continue;
			EndIf;
			
			FilterArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ReportCell.FilterCells);
			FilterCells = New Structure;
			For Each Dimension In FilterArray Do
				FilterCells.Insert(Dimension, ReportCell[Dimension]);
			EndDo;
			
			NewLinesFound = NewCellData.FindRows(FilterCells);
			If Not NewLinesFound.Count() Then
				NewRow = NewCellData.Add();
				If ReportCell.CalculationFilling = CalculationFillingTotal Then
					FillPropertyValues(NewRow, ReportCell,, "Value, Sum, SumCurr, Count" + ReverseColumnNames);
				Else
					FillPropertyValues(NewRow, ReportCell,, "Value, Sum, SumCurr, Count");
				EndIf;
				RowOfNewData = NewRow;
			Else
				RowOfNewData = NewLinesFound[0];
			EndIf;
			
			FieldsToFillIn = "FilterCells, AreaNameValue, AreaNameCount, AreaNameSum, AreaNameValueHierarchy, AreaNameQuantityHierarchy, AreaNameSumHierarchy, HierarchyOutput";
			FillPropertyValues(RowOfNewData, ReportCell, FieldsToFillIn);
			If ValueIsFilled(ReportCell.Currency)
				And Not ValueIsFilled(RowOfNewData.Currency) Then
				RowOfNewData.Currency = ReportCell.Currency;
			EndIf;
			
			CellParameters_ = CellParameters.Find(ReportCell.RowIndex, "RowIndex");
			
			If Iteration = 1 Then
				If ReportCell.CalculationFilling = CalculationFillingTotal
					And RowOfNewData.HierarchyOutput Then
					Row_Cell = RowsToRecalculateChangesInHierarchy.Get(ReportCell.RowIndex);
					If Row_Cell = Undefined Then
						RowsToRecalculateChangesInHierarchy.Insert(ReportCell.RowIndex, New Map);
					EndIf;
					RowsToRecalculateChangesInHierarchy[ReportCell.RowIndex].Insert(RowOfNewData, FilterCells);
					Continue;
				ElsIf CellParameters_.CalculationFilling <> CalculationFillingTotal Then
					Continue;
				EndIf;
			ElsIf Iteration = 2 And CellParameters_.CalculationFilling <> "recalculate" Then
				Continue;
			EndIf;
			
			If CellParameters_.FlagCount
				And ValueIsFilled(ReportCell.AreaNameCount) Then
				
				RowOfNewData.CalculatedCount = False;
				
				ParametersForCalculatingValue = TemplateForCellValueCalculationParameters();
				ParametersForCalculatingValue.CellParameters = CellParameters;
				ParametersForCalculatingValue.PeriodParameters_1 = PeriodParameters_1;
				ParametersForCalculatingValue.Prefix = "Count";
				ParametersForCalculatingValue.CalculatingChanges = True;
				ParametersForCalculatingValue.CacheOfBudgetItemDetails = CacheOfBudgetItemDetails;
				
				ParametersForCalculatingValue.CellData_ = NewCellData;
				ParametersForCalculatingValue.DataString1 = RowOfNewData;
				NewCount = CalculateCellValue(ParametersForCalculatingValue);
				
				ParametersForCalculatingValue.CellData_ = PreviousCellData;
				ParametersForCalculatingValue.DataString1 = ReportCell;
				OldQuantity = CalculateCellValue(ParametersForCalculatingValue);
				
				If NewCount <> OldQuantity Then
					ChangesTable.Insert(ReportCell.AreaNameCount, NewCount);
					If Iteration = 1 Then
						LinesToRecalculateChanges.Insert(ReportCell);
					ElsIf Iteration = 2 Then
						UniqueChangeStrings.Insert(RowOfNewData);
					EndIf;
				EndIf;
				
			EndIf;
			
			If CellParameters_.FlagSum
				And ValueIsFilled(ReportCell.AreaNameSum) Then
				
				RowOfNewData.CalculatedSum = False;
				RowOfNewData.CalculatedSumCurr = False;
				
				ParametersForCalculatingValue = TemplateForCellValueCalculationParameters();
				ParametersForCalculatingValue.CellParameters = CellParameters;
				ParametersForCalculatingValue.PeriodParameters_1 = PeriodParameters_1;
				ParametersForCalculatingValue.Prefix = "Sum";
				ParametersForCalculatingValue.CacheOfBudgetItemDetails = CacheOfBudgetItemDetails;
				ParametersForCalculatingValue.CalculatingChanges = True;
				
				ParametersForCalculatingValue.CellData_ = NewCellData;
				ParametersForCalculatingValue.DataString1 = RowOfNewData;
				NewAmount = CalculateCellValue(ParametersForCalculatingValue);
				
				ParametersForCalculatingValue.CellData_ = PreviousCellData;
				ParametersForCalculatingValue.DataString1 = ReportCell;
				OldAmount = CalculateCellValue(ParametersForCalculatingValue);
				
				If NewAmount <> OldAmount Then
					ChangesTable.Insert(ReportCell.AreaNameSum, NewAmount);
					If Iteration = 1 Then
						LinesToRecalculateChanges.Insert(ReportCell);
					ElsIf Iteration = 2 Then
						UniqueChangeStrings.Insert(RowOfNewData);
					EndIf;
				EndIf;
				
			EndIf;
			
			If CellParameters_.FlagValue
				And ValueIsFilled(ReportCell.AreaNameValue) Then
				
				RowOfNewData.CalculatedValue = False;
				
				ParametersForCalculatingValue = TemplateForCellValueCalculationParameters();
				ParametersForCalculatingValue.CellParameters = CellParameters;
				ParametersForCalculatingValue.PeriodParameters_1 = PeriodParameters_1;
				ParametersForCalculatingValue.Prefix = "Value";
				ParametersForCalculatingValue.CalculatingChanges = True;
				ParametersForCalculatingValue.CacheOfBudgetItemDetails = CacheOfBudgetItemDetails;
				
				ParametersForCalculatingValue.CellData_ = NewCellData;
				ParametersForCalculatingValue.DataString1 = RowOfNewData;
				NewValue  = CalculateCellValue(ParametersForCalculatingValue);
				
				ParametersForCalculatingValue.CellData_ = PreviousCellData;
				ParametersForCalculatingValue.DataString1 = ReportCell;
				PreviousValue2 = CalculateCellValue(ParametersForCalculatingValue);
				
				If NewValue <> PreviousValue2 Then
					ChangesTable.Insert(ReportCell.AreaNameValue, NewValue);
					If Iteration = 1 Then
						LinesToRecalculateChanges.Insert(ReportCell);
					ElsIf Iteration = 2 Then
						UniqueChangeStrings.Insert(RowOfNewData);
					EndIf;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If Iteration = 1 Then 
			For Each RowKeyToRecalculate In LinesToRecalculateChanges Do
				RowToRecalculate = RowKeyToRecalculate.Key;
				
				If Not RowToRecalculate.CalculationFilling = CalculationFillingTotal Then
					Continue;
				EndIf;
				
				// only related to the current
				CellParameters_ = CellParameters.Find(RowToRecalculate.RowIndex, "RowIndex");
				
				If Not CellParameters_ = Undefined And Not CellParameters_.RelatedCells = Undefined Then
					RelatedCells = CellParameters_.RelatedCells; // See CellData_
					For Each LinkedCell In RelatedCells Do
						
						TheStructureOfTheSearch = New Structure(LinkedCell.GeneralMeasurements);
						FillPropertyValues(TheStructureOfTheSearch, RowToRecalculate);
						TheStructureOfTheSearch.Insert("String", LinkedCell.String);
						TheStructureOfTheSearch.Insert("Column", LinkedCell.Column);
						TheStructureOfTheSearch.Insert("MainItem", True);
						
						FoundRows = PreviousCellData.FindRows(TheStructureOfTheSearch);
						If FoundRows.Count() Then
							For Each TableRow In FoundRows Do
								If Not TableRow.CalculationFilling = "recalculate" Then
									Continue;
								EndIf;
								RelatedRowsToRecalculate.Insert(TableRow);
							EndDo;
						EndIf;
						
					EndDo;
				EndIf;
				
			EndDo;
		EndIf;
		
		Iteration = Iteration + 1;
		
	EndDo;
	
	TheStructureOfTheSearch = New Structure("MainItem", True);
	
	For Each RowsToRecalculate_ In RowsToRecalculateChangesInHierarchy Do
		
		CellParameters_ = CellParameters.Find(RowsToRecalculate_.Key, "RowIndex");
		TheStructureOfTheSearch.Insert("RowIndex", RowsToRecalculate_.Key);
		
		DataRows = NewCellData.FindRows(TheStructureOfTheSearch);
		
		If CellParameters_.FlagCount Then
			
			OriginalDataOfLines = New Map;
			CellsToRecalculate = New Map;
			For Each RowToRecalculate In RowsToRecalculate_.Value Do
				CellsToRecalculate.Insert(RowToRecalculate.Key.AreaNameCount, RowToRecalculate.Key);
				ReportCell = PreviousCellData.FindRows(RowToRecalculate.Value)[0];
				OriginalDataOfLines.Insert(RowToRecalculate.Key, ReportCell.Count);
				RowToRecalculate.Key.Count = 0;
			EndDo;
			
			ProcessedRows = New Map;
			While CellsToRecalculate.Count() > 0 Do
				CellsToDelete = New Array;
				CellsForFurtherProcessing = New Array;
				For Each DataString1 In DataRows Do
					If ProcessedRows.Get(DataString1) <> Undefined Then
						Continue;
					EndIf;
					AreaCellHierarchy = DataString1.AreaNameQuantityHierarchy;
					If Not ValueIsFilled(AreaCellHierarchy) Then
						Continue;
					ElsIf CellsToRecalculate.Get(DataString1.AreaNameCount) <> Undefined Then
						If CellsForFurtherProcessing.Find(AreaCellHierarchy) = Undefined Then
							CellsForFurtherProcessing.Add(AreaCellHierarchy);
						EndIf;
						Continue;
					EndIf;
					RowToRecalculate = CellsToRecalculate.Get(AreaCellHierarchy);
					If RowToRecalculate <> Undefined Then
						RowToRecalculate.Count = RowToRecalculate.Count + DataString1.Count;
					EndIf;
					ProcessedRows.Insert(DataString1, True);
					If CellsToDelete.Find(AreaCellHierarchy) = Undefined Then
						CellsToDelete.Add(AreaCellHierarchy);
					EndIf;
				EndDo;
				DeletedCells = 0;
				For Each CellToDelete In CellsToDelete Do
					If CellsForFurtherProcessing.Find(CellToDelete) = Undefined Then
						CellsToRecalculate.Delete(CellToDelete);
						DeletedCells = DeletedCells + 1;
					EndIf;
				EndDo;
				If DeletedCells = 0 Then
					Raise NStr("vi = 'Lỗi khi tính toán giá trị ô theo gom nhóm phân nhánh';
								|ru = 'Ошибка при расчете значений ячеек по иерархическим группировкам';
								|en = 'An error occurred when calculating cell values by hierarchy groupings'; fa = 'An error occurred when calculating cell values by hierarchy groupings';
								|it = 'Ошибка при расчете значений ячеек по иерархическим группировкам';
								|pl = 'An error occurred when calculating cell values by hierarchy groupings';
								|tr = 'Hiyerarşik gruplamalara göre hücre değer hesaplamasında hata'");
				EndIf;
			EndDo;
			
			For Each RowToRecalculate In OriginalDataOfLines Do
				If RowToRecalculate.Key.Count <> RowToRecalculate.Value Then
					ChangesTable.Insert(RowToRecalculate.Key.AreaNameCount, RowToRecalculate.Key.Count);
				EndIf;
			EndDo;
			
		EndIf;
		
		If CellParameters_.FlagSum Then
			
			OriginalDataOfLines = New Map;
			CellsToRecalculate = New Map;
			For Each RowToRecalculate In RowsToRecalculate_.Value Do
				CellsToRecalculate.Insert(RowToRecalculate.Key.AreaNameSum, RowToRecalculate.Key);
				ReportCell = PreviousCellData.FindRows(RowToRecalculate.Value)[0];
				OriginalDataOfLines.Insert(RowToRecalculate.Key, ReportCell.Sum);
				RowToRecalculate.Key.Sum = 0;
			EndDo;
			
			ProcessedRows = New Map;
			While CellsToRecalculate.Count() > 0 Do
				InitialQuantity_ = CellsToRecalculate.Count();
				CellsToDelete = New Array;
				CellsForFurtherProcessing = New Array;
				For Each DataString1 In DataRows Do
					If ProcessedRows.Get(DataString1) <> Undefined Then
						Continue;
					EndIf;
					AreaCellHierarchy = DataString1.AreaNameSumHierarchy;
					If Not ValueIsFilled(AreaCellHierarchy) Then
						Continue;
					ElsIf CellsToRecalculate.Get(DataString1.AreaNameSum) <> Undefined Then
						If CellsForFurtherProcessing.Find(AreaCellHierarchy) = Undefined Then
							CellsForFurtherProcessing.Add(AreaCellHierarchy);
						EndIf;
						Continue;
					EndIf;
					RowToRecalculate = CellsToRecalculate.Get(AreaCellHierarchy);
					If RowToRecalculate <> Undefined Then
						Sum = ?(Not ValueIsFilled(DataString1.Currency), DataString1.Sum, DataString1.SumCurr);
						RowToRecalculate.Sum = RowToRecalculate.Sum + Sum;
					EndIf;
					ProcessedRows.Insert(DataString1, True);
					If CellsToDelete.Find(AreaCellHierarchy) = Undefined Then
						CellsToDelete.Add(AreaCellHierarchy);
					EndIf;
				EndDo;
				DeletedCells = 0;
				For Each CellToDelete In CellsToDelete Do
					If CellsForFurtherProcessing.Find(CellToDelete) = Undefined Then
						CellsToRecalculate.Delete(CellToDelete);
						DeletedCells = DeletedCells + 1;
					EndIf;
				EndDo;
				If DeletedCells = 0
					Or InitialQuantity_ = CellsToRecalculate.Count() Then
					Raise NStr("vi = 'Lỗi khi tính toán giá trị ô theo gom nhóm phân nhánh';
								|ru = 'Ошибка при расчете значений ячеек по иерархическим группировкам';
								|en = 'An error occurred when calculating cell values by hierarchy groupings'; fa = 'An error occurred when calculating cell values by hierarchy groupings';
								|it = 'Ошибка при расчете значений ячеек по иерархическим группировкам';
								|pl = 'An error occurred when calculating cell values by hierarchy groupings';
								|tr = 'Hiyerarşik gruplamalara göre hücre değer hesaplamasında hata'");
				EndIf;
			EndDo;
			
			For Each RowToRecalculate In OriginalDataOfLines Do
				If RowToRecalculate.Key.Sum <> RowToRecalculate.Value Then
					ChangesTable.Insert(RowToRecalculate.Key.AreaNameSum, RowToRecalculate.Key.Sum);
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	For Each ChangeLineKey In UniqueChangeStrings Do
		ChangesToLinkedCells.Add(ChangeLineKey.Key);
	EndDo;
	Result = New Structure("ChangesTable, ChangesToLinkedCells", ChangesTable, ChangesToLinkedCells);
	
	Return Result;
	
EndFunction

#Region CrawlingAndOutputtingDataToReport

Procedure CrawlingReportData(OutputParameters)
	OutputTree = OutputParameters.OutputTree;
	
	TableColumnsByReportElements = OutputParameters.TableColumnsByReportElements;
	ForEditing = OutputParameters.GenerationMode = Enums.ModesOfBudgetReportGeneration.Document;
	OutputParameters.Insert("ForEditing", ForEditing);
	
	For Each OutputItem In OutputTree.Rows Do
		
		If OutputItem.DimensionName = "Table" Then
			
			ColumnStructure1 = ParametersForColumnDimensions(OutputParameters,
					OutputParameters.DimensionSearchIndexes,
					OutputItem.Rows.Find("Columns"));
			
			TableColumnsByReportElements.Insert(OutputItem, ColumnStructure1);
			
			ReportLines = OutputItem.Rows.Find("Rows");
			TableComplex_ = OutputItem.ItemKind = Enums.FinancialReportItemKinds.ComplexTable;
			TableParameters = OutputItem.TableParameters;
			
			OutputParameters.Insert("TableComplex_", TableComplex_);
			OutputParameters.Insert("ColumnStructure1", ColumnStructure1);
			OutputParameters.Insert("TableParameters", TableParameters);
			
			CrawlingReportTableData(OutputParameters, ReportLines);
			
		EndIf;
		
	EndDo;
EndProcedure

Function OutputDataToReport(OutputParameters)
	
	OutputTree = OutputParameters.OutputTree;
	ForEditing = OutputParameters.GenerationMode = Enums.ModesOfBudgetReportGeneration.Document;
	TableColumnsByReportElements = OutputParameters.TableColumnsByReportElements;
	
	ResultDocument = New SpreadsheetDocument;
	
	ResultDocument.StartRowAutoGrouping();
	
	NumberOfTables = 0;
	RowsAboveCount = 0;
	
	StructureOfAreas = StructureOfTemplateAreas(OutputParameters);
	
	OutputParameters.Insert("ResultDocument", ResultDocument);
	OutputParameters.Insert("StructureOfAreas", StructureOfAreas);
	OutputParameters.Insert("ForEditing", ForEditing);
	
	PreviousDimensionName = "";
	PreviousTitle = "";
	TableParameters = Undefined;
	
	For Each OutputItem In OutputTree.Rows Do
		
		If OutputItem.DimensionName = "TextBlock" Then
			
			TitleOutput = Not (OutputItem.OnlyForPrinting = 1
					And OutputParameters.GenerationMode = Enums.ModesOfBudgetReportGeneration.Document)
					And Not (OutputItem.OnlyForPrinting = 2
					And OutputParameters.GenerationMode <> Enums.ModesOfBudgetReportGeneration.Document);
			
			If TitleOutput Then
				SetParametersInNameForPrinting(OutputItem.NameForPrinting, OutputParameters.SubstitutionValues);
				OutputTextBlockToReport(ResultDocument, StructureOfAreas, OutputItem);
				If NumberOfTables = 0 Then
					RowsAboveCount = RowsAboveCount + 3;
				EndIf;
				PreviousTitle = OutputItem.NameForPrinting;
			EndIf;
			
		ElsIf OutputItem.DimensionName = "Table" Then
			
			If OutputItem.DisplayTitleInReport = True Then
				OutputTextBlockToReport(ResultDocument, StructureOfAreas, OutputItem);
				RowsAboveCount = RowsAboveCount + 3;
				PreviousTitle = OutputItem.NameForPrinting;
			ElsIf PreviousDimensionName = "Table" Then
				ResultDocument.Put(StructureOfAreas.IsBlankString, 0);
				RowsAboveCount = RowsAboveCount + 1;
			EndIf;
			NumberOfTables = NumberOfTables + 1;
			
			ColumnStructure1 = TableColumnsByReportElements.Get(OutputItem);
			If ColumnStructure1 = Undefined Then
				ColumnStructure1 = ParametersForColumnDimensions(OutputParameters,
						OutputParameters.DimensionSearchIndexes,
						OutputItem.Rows.Find("Columns"));
			EndIf;
			
			RowsAboveCount = RowsAboveCount + TreeDepth(ColumnStructure1.Rows) + 1;
			
			ReportLines = OutputItem.Rows.Find("Rows");
			TableComplex_ = OutputItem.ItemKind = Enums.FinancialReportItemKinds.ComplexTable;
			TableParameters = OutputItem.TableParameters;
			
			OutputParameters.Insert("TableComplex_", TableComplex_);
			OutputParameters.Insert("ColumnStructure1", ColumnStructure1);
			OutputParameters.Insert("TableParameters", TableParameters);
			If TableParameters.Property("ReportDataForFormatting") Then
				ExistingTable = Undefined; // See BudgetReportingCacheCalculationServer.ReportDataForFormatting
				If OutputParameters.Property("ReportDataForFormatting", ExistingTable)
					And ExistingTable <> Undefined Then
					For Each Column In TableParameters.ReportDataForFormatting.Columns Do
						If ExistingTable.Columns.Find(Column.Name) = Undefined Then
							ExistingTable.Columns.Add(Column.Name, Column.ValueType);
						EndIf;
					EndDo;
					OutputParameters.Insert("ReportDataForFormatting", ExistingTable);
				Else
					OutputParameters.Insert("ReportDataForFormatting", TableParameters.ReportDataForFormatting.CopyColumns());
				EndIf;
			Else
				OutputParameters.Insert("ReportDataForFormatting", Undefined);
			EndIf;
			
			DisplayTableHeaderInReport(OutputParameters, ResultDocument, StructureOfAreas, ColumnStructure1, OutputItem, NumberOfTables);
			
			If ForEditing
				Or OutputParameters.GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget Then
				
				RootRow = OutputParameters.TreeOfEditListRows.Rows.Add();
				If IsBlankString(PreviousTitle) Then
					RootRow.Presentation = NStr("vi = 'Khoản mục ngân sách';
												|ru = 'Статьи бюджета';
												|en = 'Budget flow items'; fa = 'اقلام جریان بودجه';
												|it = 'Voci di bilancio';
												|pl = 'Pozycje budżetowe';
												|tr = 'Bütçe kalemleri'");
				Else
					RootRow.Presentation = PreviousTitle;
				EndIf;
				If Not ValueIsFilled(OutputItem.ItemKind) Then
					RootRow.Picture = 9;
				Else
					RootRow.Picture = 21;
				EndIf;
				RootRow.Level = 1;
				RootRow.TableID = New UUID;
				OutputParameters.Insert("AddressForAddingLinesToEditList", RootRow);
				TableColumns = Undefined;
				If Not OutputParameters.Property("TableColumns", TableColumns) Then
					TableColumns = New Map;
				EndIf;
				TableColumns.Insert(RootRow.TableID, ColumnStructure1);
				OutputParameters.Insert("TableColumns", TableColumns);
				
				If OutputParameters.DisplayNotes_ Then
					OutputParameters.Remarks.TableNumber = ?(OutputParameters.DisplayTableNumbers, NumberOfTables, 0);
					OutputParameters.Remarks.NoteNumber = 0;
				EndIf;
				
			EndIf;
			
			OutputTableToReport(OutputParameters, ReportLines, NumberOfTables);
			
			PreviousTitle = "";
			
		EndIf;
		PreviousDimensionName = OutputItem.DimensionName;
		
	EndDo;
	
	ResultDocument.EndRowAutoGrouping();
	
	If NumberOfTables = 1 Then
		ResultDocument.FixedTop = RowsAboveCount;
		ResultDocument.FixedLeft = 2 + TableParameters.NumberOfAdditionalColumns;
	EndIf;
	
	Return ResultDocument;
	
EndFunction

Procedure CrawlingReportTableData(OutputParameters, ReportLines, AccumulatedSelection = Undefined, Level = 1, RowOfAnalyticsHierarchy = Undefined)
	
	ColumnStructure1 = OutputParameters.ColumnStructure1;
	CellData_ = OutputParameters.CellData_;
	SearchIndexes = OutputParameters.DimensionSearchIndexes;
	ForEditing = OutputParameters.ForEditing;
	SubordinateElementsOfBudgetView = OutputParameters.SubordinateElementsOfBudgetView;
	
	OutputEmptyLinesOfAnalytics = True;
	DoNotOutputEmptyAnalyticsLinesUpToLevelOf = 0;
	If OutputParameters.Property("DoNotOutputEmptyAnalyticsLinesUpToLevelOf")
		And Not OutputParameters.DoNotOutputEmptyAnalyticsLinesUpToLevelOf = Undefined Then
		OutputEmptyLinesOfAnalytics = False;
		DoNotOutputEmptyAnalyticsLinesUpToLevelOf = OutputParameters.DoNotOutputEmptyAnalyticsLinesUpToLevelOf
	EndIf;
	
	If AccumulatedSelection = Undefined Then
		AccumulatedSelection = New Structure;
	EndIf;
	
	If Not OutputParameters.Property("OutputOfHierarchyOfElements") Then
		OutputParameters.Insert("OutputOfHierarchyOfElements", New Map);
	EndIf;
	
	CurCurrentHierarchyLevel = False;
	If RowOfAnalyticsHierarchy <> Undefined
		And RowOfAnalyticsHierarchy.Rows.Count() > 0 Then
		CurCurrentHierarchyLevel = True;
	EndIf;
	If CurCurrentHierarchyLevel Then
		TreeRowIndex = ReportLines.Parent.Rows.IndexOf(ReportLines);
		CollectionOfReportLines = ReportLines.Parent.Rows;
	Else
		CollectionOfReportLines = ReportLines.Rows;
	EndIf;
	
	For Each ReportRow In CollectionOfReportLines Do
		
		If CurCurrentHierarchyLevel
			And CollectionOfReportLines.IndexOf(ReportRow) <> TreeRowIndex Then
			Continue;
		EndIf;
		
		If ReportRow.OutputTogetherWithSubordinate Then
			
			AddedSelection = False;
			If ValueIsFilled(ReportRow.FixedValue) Then
				AccumulatedSelection.Insert(ReportRow.DimensionName, ReportRow.FixedValue);
				AddedSelection = True;
			EndIf;
			
			CrawlingReportTableData(OutputParameters, ReportRow, AccumulatedSelection, Level);
			
			If AddedSelection Then
				AccumulatedSelection.Delete(ReportRow.DimensionName);
			EndIf;
			
		ElsIf ReportRow.DisplayWithParent Then
			
			ArrayOfDimensions_ = New Array;
			ListToOutput = New Array;
			
			LineToCalculateUnion = ReportRow;
			
			// A match where the key is the name of the dimension and the value is the type of analytics (if the type of analytics = undefined, then this is the dimension).
			// Dimension names cannot match analyst names, even if they have the same data type
			// (for example, "Division" - dimension, "Divisions" - analytics". Arbitrary analytics has the name "Key_<ID_X>").
			ViewAnalyticsByDimensionNames = New Map;
			MapTypes = New Map;
			
			FirstIteration = True;
			While FirstIteration Or LineToCalculateUnion.OutputTogetherWithSubordinate Do
				
				ArrayOfDimensions_.Insert(0, LineToCalculateUnion.DimensionName);
				ViewAnalyticsByDimensionNames.Insert(LineToCalculateUnion.DimensionName, LineToCalculateUnion.DimensionKind);
				
				If StrStartsWith(LineToCalculateUnion.DimensionName, "Period") Then
					TypeOfAnalyticsTypeValue = Common.DateTypeDetails(DateFractions.Date);
				Else
					TypeOfAnalyticsTypeValue = FinancialReportingCached.TypeOfAnalyticsTypeValue(
						LineToCalculateUnion.DimensionName,
						LineToCalculateUnion.DimensionKind);
				EndIf;
				
				MapTypes.Insert(LineToCalculateUnion.DimensionName, TypeOfAnalyticsTypeValue);
				ListToOutput.Insert(0, LineToCalculateUnion);
				LineToCalculateUnion = LineToCalculateUnion.Parent;
				
				FirstIteration = False;
				
			EndDo;
			
			ArrayOfDimensions_ = CommonClientServer.CollapseArray(ArrayOfDimensions_);
			
			ListOfItemsWithSubordinates = ListOfSubordinateElements(ListToOutput[ListToOutput.UBound()].ReportItem,
					SubordinateElementsOfBudgetView);
			
			OptionalParameters = OptionalParametersForGettingSelectionOfCells();
			OptionalParameters.Column = Undefined;
			OptionalParameters.String = ListOfItemsWithSubordinates;
			OptionalParameters.SearchIndexes = SearchIndexes;
			OptionalParameters.AddFlag = False;
			OptionalParameters.GenerationMode = OutputParameters.GenerationMode;
			If ReportRow.ItemKind = Enums.FinancialReportItemKinds.Dimension
				And OutputParameters.ShowItemHierarchy Then
				FillPropertyValues(OptionalParameters, ReportRow,
					"ShowItemHierarchy");
				FillPropertyValues(OptionalParameters, ListToOutput[0],
					"PresentationExpression, SortingExpression");
				OptionalParameters.GenerationMode = OutputParameters.GenerationMode;
				If ReportRow.ShowItemHierarchy And OutputParameters.ConsiderAdditionalSelectionByHierarchy Then
					OptionalParameters.Insert("AdditionalSelection",
						BudgetReportingCacheCalculationServer.ValueOfBudgetViewElementSProps(
						ReportRow.ReportItem, "AdditionalSelection",
						OutputParameters.CacheOfBudgetItemDetails.AttributeCache));
				EndIf;
			EndIf;
			Result = GetSelectionOfCellsHierarchically(CellData_, ArrayOfDimensions_, AccumulatedSelection,
				OptionalParameters);
			
			If OptionalParameters.Property("AdditionalSelection") Then
				OutputParameters.Insert("ConsiderAdditionalSelectionByHierarchy", True);
			EndIf;
			
			If ForEditing Then
				EditableItemsAreInGrouping = False;
				For Each Dimension In ListToOutput Do
					If Dimension.EditedValues Then
						EditableItemsAreInGrouping = True;
						Break;
					EndIf;
				EndDo;
				If EditableItemsAreInGrouping Then
					ThereIsLineWithEmptyValues = False;
					For Each ResultString1 In Result Do
						InLineThereAreFilled = False;
						For Each Dimension In ListToOutput Do
							If Not Dimension.EditedValues Then
								Continue;
							EndIf;
							If ValueIsFilled(ResultString1[Dimension.DimensionName]) Then
								InLineThereAreFilled = True;
								Break;
							EndIf;
						EndDo;
						If Not InLineThereAreFilled Then
							ThereIsLineWithEmptyValues = True;
							Break;
						EndIf;
					EndDo;
					If Not ThereIsLineWithEmptyValues
						And (OutputEmptyLinesOfAnalytics Or DoNotOutputEmptyAnalyticsLinesUpToLevelOf < Level) Then
						NewRow = Result.Add();
						FillPropertyValues(NewRow, AccumulatedSelection);
					EndIf;
				EndIf;
			EndIf;
				
			If Not Result.Count() Then
				Result.Add();
			EndIf;
			
			For Each Selection In Result Do
				
				CurrentFilter = Common.CopyRecursive(AccumulatedSelection);
				For Each Dimension In ArrayOfDimensions_ Do
					Value = Selection[Dimension];
					If Not ValueIsFilled(Value) Then
						DimensionType = MapTypes[Dimension];
						DimensionKind = ViewAnalyticsByDimensionNames.Get(Dimension);
						If BudgetingServer.ThisIsAnalyticsDimension(DimensionType, DimensionKind) Then
							BudgetingClientServer.ReducedAnalyticsValue(Value, DimensionType);
						Else
							Value = DimensionType.AdjustValue(Value);
						EndIf;
					EndIf;
					CurrentFilter.Insert(Dimension, Value);
				EndDo;
				
				TraversingReportTableCells(OutputParameters, ReportRow, ColumnStructure1, CurrentFilter);
				
				CrawlingReportTableData(OutputParameters, ReportRow, CurrentFilter, Level + 1);
				
			EndDo;
			
		Else
		
			ValueIsPredefined = False;
			If ReportRow.EditedValues = False Then
			
				ThisIsFixColumn = 
					ReportRow.ItemKind = Enums.FinancialReportItemKinds.RowColumn
					Or ReportRow.ItemKind = Enums.FinancialReportItemKinds.Group
					Or ReportRow.ItemKind = Enums.FinancialReportItemKinds.GroupFormula
					Or ReportRow.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
					
					ValueIsPredefined = ReportRow.ThisIsDimensionOther
						Or ThisIsFixColumn Or ValueIsFilled(ReportRow.FixedValue);
			EndIf;
				
			// Output of the area.
			If ValueIsPredefined Then
				
				AddedSelection = False;
				If Not ThisIsFixColumn Then
					AccumulatedSelection.Insert(ReportRow.DimensionName, ReportRow.FixedValue);
					AddedSelection = True;
				EndIf;
				
				OutputToReport = True;
				// If the formula is the first in the group, then we do not output the formula, we output the sum opposite the group.
				If ReportRow.ItemKind = Enums.FinancialReportItemKinds.GroupFormula Then
					If ReportRow.Parent.Rows[0] = ReportRow Then
						OutputToReport = False;
					EndIf;
				EndIf;
				
				If OutputToReport Then
					
					TraversingReportTableCells(OutputParameters, ReportRow, ColumnStructure1, AccumulatedSelection,
						RowOfAnalyticsHierarchy);
					
				EndIf;
				
				CrawlingReportTableData(OutputParameters, ReportRow, AccumulatedSelection, Level + 1, RowOfAnalyticsHierarchy);
				
				If AddedSelection Then
					AccumulatedSelection.Delete(ReportRow.DimensionName);
				EndIf;
				
			Else
				
				If CurCurrentHierarchyLevel Then
					
					Result = RowOfAnalyticsHierarchy.Rows;
					ForEditing = False;
					
				Else
					
					ListOfItemsWithSubordinates = ListOfSubordinateElements(ReportRow.ReportItem, SubordinateElementsOfBudgetView);
					
					OptionalParameters = OptionalParametersForGettingSelectionOfCells();
					OptionalParameters.Column = Undefined;
					OptionalParameters.String = ListOfItemsWithSubordinates;
					OptionalParameters.SearchIndexes = SearchIndexes;
					OptionalParameters.AddFlag = False;
					OptionalParameters.GenerationMode = OutputParameters.GenerationMode;
					If ReportRow.ItemKind = Enums.FinancialReportItemKinds.Dimension
						And OutputParameters.ShowItemHierarchy Then
						FillPropertyValues(OptionalParameters, ReportRow,
							"ShowItemHierarchy, PresentationExpression, SortingExpression");
						OptionalParameters.GenerationMode = OutputParameters.GenerationMode;
						If ReportRow.ShowItemHierarchy And OutputParameters.ConsiderAdditionalSelectionByHierarchy Then
							OptionalParameters.Insert("AdditionalSelection",
								BudgetReportingCacheCalculationServer.ValueOfBudgetViewElementSProps(
								ReportRow.ReportItem, "AdditionalSelection",
								OutputParameters.CacheOfBudgetItemDetails.AttributeCache));
						EndIf;
					EndIf;
					Result = GetSelectionOfCellsHierarchically(CellData_, ReportRow.DimensionName,
						AccumulatedSelection, OptionalParameters);
					
					If TypeOf(Result) = Type("ValueTree") Then
						Result = Result.Rows;
						ForEditing = False;
					EndIf;
					
				EndIf;
				
				If ForEditing Then
					If ReportRow.EditedValues Then
						ThereIsLineWithEmptyValues = False;
						For Each ResultString1 In Result Do
							If ValueIsFilled(ResultString1[ReportRow.DimensionName]) Then
								Continue;
							EndIf;
							ThereIsLineWithEmptyValues = True;
							Break;
						EndDo;
						If Not ThereIsLineWithEmptyValues
							And (OutputEmptyLinesOfAnalytics Or DoNotOutputEmptyAnalyticsLinesUpToLevelOf < Level) Then
							Result.Add();
						EndIf;
					EndIf;
				EndIf;
					
				SelectionFromHierarchy = (TypeOf(Result) = Type("ValueTreeRowCollection"));
			
				If Not Result.Count() Then
					If Not SelectionFromHierarchy Then
						Result.Add();
					ElsIf Result.Parent = Undefined Then
						Result.Add();
						Result[0].IsFolder = False;
					EndIf;
				EndIf;
				
				For Each Selection In Result Do
					
					Value = Selection[ReportRow.DimensionName];
					
					If Not ValueIsFilled(Value) Then
						If BudgetReportingClientServer.ThisIsPeriodField(ReportRow.DimensionName) Then
							Continue;
						EndIf;
						If ReportRow.DimensionName = "BudgetBalanceItem" Then
							Continue;
						EndIf;
						If ReportRow.DimensionName = "BudgetFlowItem" Then
							Continue;
						EndIf;
						ValueType = FinancialReportingCached.TypeOfAnalyticsTypeValue(
							ReportRow.DimensionName, ReportRow.DimensionKind);
						If BudgetingServer.ThisIsAnalyticsDimension(ValueType, ReportRow.DimensionKind) Then
							Value = BudgetingClientServer.ReducedAnalyticsValue(Value, ValueType);
						Else
							Value = ValueType.AdjustValue(Value);
						EndIf;
						If SelectionFromHierarchy Then
							Selection.IsFolder = False;
						EndIf;
					ElsIf SelectionFromHierarchy
						And Selection.Parent <> Undefined
						And Not Selection.Parent.IsFolder
						And Value = Selection.Parent[ReportRow.DimensionName] Then
						// for Catalogs with a hierarchy of elements, the parent row is present among the subordinates
						Continue;
					EndIf;
					
					AccumulatedSelection.Insert(ReportRow.DimensionName, Value);
					
					TraversingReportTableCells(OutputParameters, ReportRow, ColumnStructure1, AccumulatedSelection, ?(
						SelectionFromHierarchy, Selection, Undefined));

					CrawlingReportTableData(OutputParameters, ReportRow, AccumulatedSelection, Level + 1, ?(
						SelectionFromHierarchy And Selection.IsFolder, Selection, Undefined));
						
					If SelectionFromHierarchy And Not Selection.IsFolder And Selection.Rows.Count() > 0 Then
						CrawlingReportTableData(OutputParameters, ReportRow, AccumulatedSelection, Level + 1, Selection);
					EndIf;

					AccumulatedSelection.Delete(ReportRow.DimensionName);
					
				EndDo;
				
				If ReportRow.ShowItemHierarchy
					And OutputParameters.ShowItemHierarchy
					And RowOfAnalyticsHierarchy = Undefined Then
					
					If OptionalParameters.Property("AdditionalSelection") Then
						// Rows with analyst values that were not included in the selection will be deleted from the data cells
						OptionalParameters.String = ReportRow.ReportItem;
						CellDataRows = GetSelectionOfCells(CellData_, AccumulatedSelection, OptionalParameters);
						CellTotalsNeedToBeRecalculated = False;
						For Each CellDataString In CellDataRows Do
							If Result.Find(CellDataString[ReportRow.DimensionName], ReportRow.DimensionName, True) = Undefined Then
								If Not CellTotalsNeedToBeRecalculated
									And (ValueIsFilled(CellDataString.SumTurnover)
									Or ValueIsFilled(CellDataString.SumCurrTurnover)
									Or ValueIsFilled(CellDataString.Count)) Then
									CellTotalsNeedToBeRecalculated = True;
								EndIf;
								CellData_.Delete(CellDataString);
							EndIf;
						EndDo;
						If (AccumulatedSelection.Property("BudgetFlowItem") Or AccumulatedSelection.Property("BudgetBalanceItem"))
							And CellTotalsNeedToBeRecalculated Then
							OutputParameters.Insert("CellTotalsNeedToBeRecalculated", True);
						EndIf;
					EndIf;
					
					OutputParameters.OutputOfHierarchyOfElements.Insert(ReportRow.ReportItem, Result);
				EndIf;
				
			EndIf; // The value is defined then
			
		EndIf;// If the output is not subordinate
		
	EndDo;
	
EndProcedure

Function StructureOfTemplateAreasForTableOutput(OutputParameters, Level)
	
	StructureOfAreas = OutputParameters.StructureOfAreas;
	DisplayRowsNumbering = OutputParameters.TableParameters.DisplayRowsNumbering;
	DisplayNotes_ = OutputParameters.DisplayNotes_;
	
	LevelsAreBeingWorkedOut = 8;
	
	DimensionLevel = Min(Level, LevelsAreBeingWorkedOut);
	
	If DisplayRowsNumbering Then
		AreaNameBegin = StringFunctionsClientServer.SubstituteParametersToString("Group%1НачалоТаблицыНумерацияСтрок", DimensionLevel);
		AreaNameBeginningIsFinal = StringFunctionsClientServer.SubstituteParametersToString("Group%1ФиналНачалоТаблицыНумерацияСтрок", DimensionLevel);
	Else
		AreaNameBegin = StringFunctionsClientServer.SubstituteParametersToString("Group%1StartOfTable", DimensionLevel);
		AreaNameBeginningIsFinal = StringFunctionsClientServer.SubstituteParametersToString("Group%1FinalStartOfTable", DimensionLevel);
	EndIf;
	AreaNameValue = StringFunctionsClientServer.SubstituteParametersToString("Group%1Value", DimensionLevel);
	AreaNameMeaningFinal = StringFunctionsClientServer.SubstituteParametersToString("Group%1FinalValue", DimensionLevel);
	AreaNameAdditionalSection = StringFunctionsClientServer.SubstituteParametersToString("Group%1AdditionalSection", DimensionLevel);
	AreaNameAdditionalSectionFinal = StringFunctionsClientServer.SubstituteParametersToString("Group%1FinalAdditionalSection", DimensionLevel);
	AreaNameNote = StringFunctionsClientServer.SubstituteParametersToString("Group%1Note", DimensionLevel);
	AreaNameNoteFinal = StringFunctionsClientServer.SubstituteParametersToString("Group%1FinalNote", DimensionLevel);
	
	StructureOfTemplateAreas = New Structure;
	
	If DimensionLevel = LevelsAreBeingWorkedOut Then
		StructureOfTemplateAreas.Insert("Begin", StructureOfAreas[AreaNameBeginningIsFinal]);
		StructureOfTemplateAreas.Insert("Value", StructureOfAreas[AreaNameMeaningFinal]);
		StructureOfTemplateAreas.Insert("AdditionalSection", StructureOfAreas[AreaNameAdditionalSectionFinal]);
		StructureOfTemplateAreas.Insert("Note", ?(DisplayNotes_, StructureOfAreas[AreaNameNoteFinal],
			Undefined));
	Else
		StructureOfTemplateAreas.Insert("Begin", StructureOfAreas[AreaNameBegin]);
		StructureOfTemplateAreas.Insert("Value", StructureOfAreas[AreaNameValue]);
		StructureOfTemplateAreas.Insert("AdditionalSection", StructureOfAreas[AreaNameAdditionalSection]);
		StructureOfTemplateAreas.Insert("Note", ?(DisplayNotes_, StructureOfAreas[AreaNameNote],
			Undefined));
	EndIf;
	StructureOfTemplateAreas.Insert("BeginningIsFinal", StructureOfAreas[AreaNameBeginningIsFinal]);
	StructureOfTemplateAreas.Insert("MeaningFinal", StructureOfAreas[AreaNameMeaningFinal]);
	StructureOfTemplateAreas.Insert("AdditionalSectionFinal", StructureOfAreas[AreaNameAdditionalSectionFinal]);
	StructureOfTemplateAreas.Insert("NoteFinal", ?(DisplayNotes_, StructureOfAreas[AreaNameNoteFinal],
		Undefined));
	
	Return StructureOfTemplateAreas;

EndFunction

// LongDesc
// 
// Parameters:
// 	OutputParameters - See AddOutputParameter.OutputParameters
// 	ReportLines - Structure - LongDesc:
// 	* Rows - Array of See BudgetReportingCacheCalculationServer.NewOutputTree - in fact, a row in the value tree
// 	TablesCounter - Number - LongDesc
// 	AccumulatedSelection - Structure - LongDesc:
// * SuccessfulReplacements - Map -
// * ReplacementPairs - Map -
// * TakeAppliedRulesIntoAccount - Boolean -
// * WriteInPrivilegedMode - Boolean -
// * IncludeBusinessLogic - Boolean -
// * MarkForDeletion - Boolean -
// * ShouldDeleteDirectly - Boolean -
// 	Level - Number - LongDesc
// 	LineCounter - Number - LongDesc
//  RowOfAnalyticsHierarchy - ValueTreeRow - LongDesc
Procedure OutputTableToReport(OutputParameters, ReportLines, TablesCounter, AccumulatedSelection = Undefined, Level = 1, LineCounter = 0, RowOfAnalyticsHierarchy = Undefined) Export
	
	ResultDocument = OutputParameters.ResultDocument;
	ColumnStructure1 = OutputParameters.ColumnStructure1;
	CellData_ = OutputParameters.CellData_;
	SearchIndexes = OutputParameters.DimensionSearchIndexes;
	ForEditing = OutputParameters.ForEditing;
	TableParameters = OutputParameters.TableParameters;
	SubordinateElementsOfBudgetView = OutputParameters.SubordinateElementsOfBudgetView;
	
	OutputEmptyLinesOfAnalytics = True;
	DoNotOutputEmptyAnalyticsLinesUpToLevelOf = 0;
	If OutputParameters.Property("DoNotOutputEmptyAnalyticsLinesUpToLevelOf")
		And Not OutputParameters.DoNotOutputEmptyAnalyticsLinesUpToLevelOf = Undefined Then
		OutputEmptyLinesOfAnalytics = False;
		DoNotOutputEmptyAnalyticsLinesUpToLevelOf = OutputParameters.DoNotOutputEmptyAnalyticsLinesUpToLevelOf
	EndIf;
	
	If AccumulatedSelection = Undefined Then
		AccumulatedSelection = New Structure;
	EndIf;
	
	StructureOfAreas = StructureOfTemplateAreasForTableOutput(OutputParameters, Level);
	
	CurCurrentHierarchyLevel = False;
	If RowOfAnalyticsHierarchy <> Undefined
		And RowOfAnalyticsHierarchy.Rows.Count() > 0 Then
		CurCurrentHierarchyLevel = True;
	EndIf;
	If CurCurrentHierarchyLevel Then
		TreeRowIndex = ReportLines.Parent.Rows.IndexOf(ReportLines);
		CollectionOfReportLines = ReportLines.Parent.Rows;
	Else
		CollectionOfReportLines = ReportLines.Rows;
	EndIf;
	
	For Each ReportRow In CollectionOfReportLines Do
		
		If CurCurrentHierarchyLevel
			And CollectionOfReportLines.IndexOf(ReportRow) <> TreeRowIndex Then
			Continue;
		EndIf;
		
		If Not ReportRow.Rows.Count() Then
			AreaBegin = StructureOfAreas.BeginningIsFinal; // SpreadsheetDocument
			AreaValue = StructureOfAreas.MeaningFinal; // SpreadsheetDocument
			ScopeOfAdmission = StructureOfAreas.AdditionalSectionFinal; // SpreadsheetDocument
			AreaNote = StructureOfAreas.NoteFinal; // SpreadsheetDocument
		Else
			AreaBegin = StructureOfAreas.Begin; // SpreadsheetDocument
			AreaValue = StructureOfAreas.Value; // SpreadsheetDocument
			ScopeOfAdmission = StructureOfAreas.AdditionalSection; // SpreadsheetDocument
			AreaNote = StructureOfAreas.Note; // SpreadsheetDocument
		EndIf;
		
		If ReportRow.OutputTogetherWithSubordinate Then
			
			AddedSelection = False;
			If ValueIsFilled(ReportRow.FixedValue) Then
				AccumulatedSelection.Insert(ReportRow.DimensionName, ReportRow.FixedValue);
				AddedSelection = True;
			EndIf;
			
			OutputTableToReport(OutputParameters, ReportRow, TablesCounter, AccumulatedSelection, Level, LineCounter);
			
			If AddedSelection Then
				AccumulatedSelection.Delete(ReportRow.DimensionName);
			EndIf;
			
		ElsIf ReportRow.DisplayWithParent Then
			
			ArrayOfDimensions_ = New Array;
			ListToOutput = New Array;
			
			LineToCalculateUnion = ReportRow;
			
			References_1 = -1;
			
			// A match where the key is the name of the dimension and the value is the type of analytics (if the type of analytics = undefined, then this is the dimension).
			// Dimension names cannot match analyst names, even if they have the same data type
			// (for example, "Division" - dimension, "Divisions" - analytics". Arbitrary analytics has the name "Key_<ID_X>").
			ViewAnalyticsByDimensionNames = New Map;
			MapTypes = New Map;
			
			FirstIteration = True;
			While FirstIteration Or LineToCalculateUnion.OutputTogetherWithSubordinate Do
				
				ArrayOfDimensions_.Insert(0, LineToCalculateUnion.DimensionName);
				ViewAnalyticsByDimensionNames.Insert(LineToCalculateUnion.DimensionName, LineToCalculateUnion.DimensionKind);
				
				If StrStartsWith(LineToCalculateUnion.DimensionName, "Period") Then
					TypeOfAnalyticsTypeValue = Common.DateTypeDetails(DateFractions.Date);
				Else
					TypeOfAnalyticsTypeValue = FinancialReportingCached.TypeOfAnalyticsTypeValue(
						LineToCalculateUnion.DimensionName,
						LineToCalculateUnion.DimensionKind);
				EndIf;
				
				MapTypes.Insert(LineToCalculateUnion.DimensionName, TypeOfAnalyticsTypeValue);
				ListToOutput.Insert(0, LineToCalculateUnion);
				References_1 = References_1 + 1
					+ BudgetReportingCacheCalculationServer.NumberOfAdditionalFieldsToCalculateTreeDepth(LineToCalculateUnion);
				LineToCalculateUnion = LineToCalculateUnion.Parent;
				
				FirstIteration = False;
				
			EndDo;
			Union = TableParameters.NumberOfAdditionalColumns - References_1;
			
			ArrayOfDimensions_ = CommonClientServer.CollapseArray(ArrayOfDimensions_);
			
			ListOfItemsWithSubordinates = ListOfSubordinateElements(ListToOutput[ListToOutput.UBound()].ReportItem,
					SubordinateElementsOfBudgetView);
			
			OptionalParameters = OptionalParametersForGettingSelectionOfCells();
			OptionalParameters.Column = Undefined;
			OptionalParameters.String = ListOfItemsWithSubordinates;
			OptionalParameters.SearchIndexes = SearchIndexes;
			OptionalParameters.AddFlag = False;
			OptionalParameters.GenerationMode = OutputParameters.GenerationMode;
			If ReportRow.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
				FillPropertyValues(OptionalParameters, ListToOutput[0], "PresentationExpression, SortingExpression");
			EndIf;
			Result = GetSelectionOfCellsHierarchically(CellData_, ArrayOfDimensions_, AccumulatedSelection, OptionalParameters);
			
			If ForEditing Then
				EditableItemsAreInGrouping = False;
				For Each Dimension In ListToOutput Do
					If Dimension.EditedValues Then
						EditableItemsAreInGrouping = True;
						Break;
					EndIf;
				EndDo;
				If EditableItemsAreInGrouping Then
					ThereIsLineWithEmptyValues = False;
					For Each ResultString1 In Result Do
						InLineThereAreFilled = False;
						For Each Dimension In ListToOutput Do
							If Not Dimension.EditedValues Then
								Continue;
							EndIf;
							If ValueIsFilled(ResultString1[Dimension.DimensionName]) Then
								InLineThereAreFilled = True;
								Break;
							EndIf;
						EndDo;
						If Not InLineThereAreFilled Then
							ThereIsLineWithEmptyValues = True;
							Break;
						EndIf;
					EndDo;
					If Not ThereIsLineWithEmptyValues
						And (OutputEmptyLinesOfAnalytics Or DoNotOutputEmptyAnalyticsLinesUpToLevelOf < Level) Then
						NewRow = Result.Add();
						FillPropertyValues(NewRow, AccumulatedSelection);
					EndIf;
				EndIf;
			EndIf;
				
			If Not Result.Count()
				And RowOfAnalyticsHierarchy = Undefined Then
				Result.Add();
			EndIf;
			
			For Each Selection In Result Do
				
				CurrentFilter = Common.CopyRecursive(AccumulatedSelection);
				For Each Dimension In ArrayOfDimensions_ Do
					Value = Selection[Dimension];
					If Not ValueIsFilled(Value) Then
						DimensionType = MapTypes[Dimension];
						DimensionKind = ViewAnalyticsByDimensionNames.Get(Dimension);
						If BudgetingServer.ThisIsAnalyticsDimension(DimensionType, DimensionKind) Then
							BudgetingClientServer.ReducedAnalyticsValue(Value, DimensionType);
						Else
							Value = DimensionType.AdjustValue(Value);
						EndIf;
					EndIf;
					CurrentFilter.Insert(Dimension, Value);
				EndDo;
				
				TheFirstControl = True;
				LineCounter = LineCounter + 1;
				OutputParameters.Insert("LineCounter", LineCounter);
				AccumulatedGroupingText = "";
				
				For Each Output_String In ListToOutput Do
					
					If TheFirstControl Then
						Area = AreaBegin; // SpreadsheetDocument
					Else
						Area = ScopeOfAdmission; // SpreadsheetDocument
					EndIf;
					
					Value = Selection[Output_String.DimensionName];
					If Not ValueIsFilled(Value) Then
						DimensionType = MapTypes[Output_String.DimensionName];
						DimensionKind = Output_String.DimensionKind;
						If BudgetingServer.ThisIsAnalyticsDimension(DimensionType, DimensionKind) Then
							BudgetingClientServer.ReducedAnalyticsValue(Value, DimensionType);
						Else
							Value = DimensionType.AdjustValue(Value);
						EndIf;
					EndIf;
					
					GroupingText = GroupingText(Value,
							Output_String,
							OutputParameters);
					
					AccumulatedGroupingText = AccumulatedGroupingText + ?(TheFirstControl,"",";") + GroupingText;
					
					Area.Parameters.Group = GroupingText;
					
					Details = GetDimensionDecryption(OutputParameters,
							Value,
							CurrentFilter,
							ReportRow);
					
					If TheFirstControl Then
						IDOfFirstGrouping = OutputParameters.DetailsData[Details].GroupingID;
					Else
						OutputParameters.DetailsData[Details].Insert("GroupingID", IDOfFirstGrouping);
					EndIf;
					
					Area.Parameters.Details = Details;
					
					If TheFirstControl Then
						If OutputParameters.TableParameters.DisplayRowsNumbering Then
							Area.Parameters["LineNumber"] = LineCounter;
						EndIf;
						OutputArea2 = ResultDocument.Put(Area, Level - 1);
					Else
						OutputArea2 = ResultDocument.Join(Area, Level - 1);
					EndIf;
					
					ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
					ParametersSet.OutputParameters = OutputParameters;
					ParametersSet.Area = ScopeOfAdmission;
					ParametersSet.Value = Value;
					ParametersSet.ReportRow = Output_String;
					ParametersSet.ReportItem = ListToOutput[ListToOutput.UBound()].ReportItem;
					ParametersSet.Column = Undefined;
					
					AddDesignArea(ParametersSet,
							OutputArea2,
							CurrentFilter,
							TablesCounter,
							LineCounter,
							Undefined);
					
					OutputAdditionalFields(ResultDocument,
							ParametersSet,
							OutputArea2,
							CurrentFilter,
							LineCounter,
							TablesCounter);
					
					TheFirstControl = False;
					
				EndDo;
				
				MergeParameters = New Structure;
				MergeParameters.Insert("OutputArea2", OutputArea2);
				MergeParameters.Insert("ScopeOfAdmission", ScopeOfAdmission);
				MergeParameters.Insert("Union", Union);
				MergeParameters.Insert("ReportItem", ListToOutput[ListToOutput.UBound()].ReportItem);
				MergeUnusedCells(ResultDocument,
						MergeParameters,
						OutputParameters,
						CurrentFilter,
						TablesCounter,
						LineCounter);
				
				OutputCellsToReport(OutputParameters, TablesCounter, AreaValue, AreaNote, ReportRow, ColumnStructure1, CurrentFilter);
				AddEditListTreeLine(Value, ReportRow, AccumulatedGroupingText, OutputParameters, OutputArea2,
					?(ListToOutput.Count() > 1, True, False));
				
				OutputTableToReport(OutputParameters, ReportRow, TablesCounter, CurrentFilter, Level + 1, LineCounter);
				SetParentOfEditListRow(OutputParameters);
				
			EndDo;
			
		Else
		
			ValueIsPredefined = False;
			If ReportRow.EditedValues = False Then
			
				ThisIsFixColumn = 
					ReportRow.ItemKind = Enums.FinancialReportItemKinds.RowColumn
					Or ReportRow.ItemKind = Enums.FinancialReportItemKinds.Group
					Or ReportRow.ItemKind = Enums.FinancialReportItemKinds.GroupFormula
					Or ReportRow.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
					
					ValueIsPredefined = ReportRow.ThisIsDimensionOther
						Or ThisIsFixColumn Or ValueIsFilled(ReportRow.FixedValue);
			EndIf;
				
			// Output of the area.
			If ValueIsPredefined Then
				
				AddedSelection = False;
				If Not ThisIsFixColumn Then
					AccumulatedSelection.Insert(ReportRow.DimensionName, ReportRow.FixedValue);
					AddedSelection = True;
				EndIf;
				
				OutputToReport = True;
				// If the formula is the first in the group, then we do not output the formula, we output the sum opposite the group.
				If ReportRow.ItemKind = Enums.FinancialReportItemKinds.GroupFormula Then
					If ReportRow.Parent.Rows[0] = ReportRow Then
						OutputToReport = False;
					EndIf;
				EndIf;
				
				If OutputToReport Then
					
					GroupingText = GroupingText(ReportRow.FixedValue,
							ReportRow,
							OutputParameters);
					
					AreaBegin.Parameters.Group = GroupingText;
					Details = GetDimensionDecryption(OutputParameters,
							ReportRow.FixedValue,
							AccumulatedSelection,
							ReportRow);
					
					AreaBegin.Parameters.Details = Details;
					LineCounter = LineCounter + 1;
					OutputParameters.Insert("LineCounter", LineCounter);
					
					If OutputParameters.TableParameters.DisplayRowsNumbering Then
						AreaBegin.Parameters["LineNumber"] = LineCounter;
					EndIf;
					
					OutputArea2 = ResultDocument.Put(AreaBegin, Level - 1);
					
					ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
					ParametersSet.OutputParameters = OutputParameters;
					ParametersSet.Area = ScopeOfAdmission;
					ParametersSet.Value = ReportRow.FixedValue;
					ParametersSet.ReportRow = ReportRow;
					ParametersSet.ReportItem = ReportRow.ReportItem;
					ParametersSet.Column = Undefined;
					
					AddDesignArea(ParametersSet,
							OutputArea2,
							AccumulatedSelection, 
							TablesCounter,
							LineCounter,
							Undefined);
					
					OutputAdditionalFields(ResultDocument,
							ParametersSet,
							OutputArea2,
							CurrentFilter,
							LineCounter,
							TablesCounter);
					
					Union = TableParameters.NumberOfAdditionalColumns
						- BudgetReportingCacheCalculationServer.NumberOfAdditionalFieldsToCalculateTreeDepth(ReportRow);
					
					MergeParameters = New Structure;
					MergeParameters.Insert("OutputArea2", OutputArea2);
					MergeParameters.Insert("ScopeOfAdmission", ScopeOfAdmission);
					MergeParameters.Insert("Union", Union);
					MergeParameters.Insert("ReportItem", ReportRow.ReportItem);
					MergeUnusedCells(ResultDocument, MergeParameters, OutputParameters, CurrentFilter,
						TablesCounter, LineCounter);
					
					OutputCellsToReport(OutputParameters, TablesCounter, AreaValue, AreaNote,
						ReportRow, ColumnStructure1, AccumulatedSelection, , ?(ReportRow.ShowItemHierarchy, RowOfAnalyticsHierarchy, Undefined));
					AddEditListTreeLine(ReportRow.FixedValue, ReportRow, GroupingText, OutputParameters, OutputArea2);
					
				EndIf;
				
				OutputTableToReport(OutputParameters, ReportRow, TablesCounter, AccumulatedSelection, Level + 1, LineCounter,
						RowOfAnalyticsHierarchy);
				
				If OutputToReport Then
					SetParentOfEditListRow(OutputParameters);
				EndIf;
				
				If AddedSelection Then
					AccumulatedSelection.Delete(ReportRow.DimensionName);
				EndIf;
				
			Else
				
				OutputOfHierarchyOfElements = Undefined;
				If CurCurrentHierarchyLevel Then
					Result = RowOfAnalyticsHierarchy.Rows;
					ForEditing = False;
				ElsIf ReportRow.ShowItemHierarchy
					And OutputParameters.Property("OutputOfHierarchyOfElements", OutputOfHierarchyOfElements) Then
					Result = OutputOfHierarchyOfElements.Get(ReportRow.ReportItem);
					If Result = Undefined Then
						OutputOfHierarchyOfElements = Undefined;
					Else
						ForEditing = False;
					EndIf;
				EndIf;
				
				If RowOfAnalyticsHierarchy = Undefined
					And OutputOfHierarchyOfElements = Undefined Then
					
					ListOfItemsWithSubordinates = ListOfSubordinateElements(ReportRow.ReportItem, SubordinateElementsOfBudgetView);
					
					OptionalParameters = OptionalParametersForGettingSelectionOfCells();
					OptionalParameters.Column = Undefined;
					OptionalParameters.String = ListOfItemsWithSubordinates;
					OptionalParameters.SearchIndexes = SearchIndexes;
					OptionalParameters.AddFlag = False;
					OptionalParameters.GenerationMode = OutputParameters.GenerationMode;
					If ReportRow.ItemKind = Enums.FinancialReportItemKinds.Dimension Then
						FillPropertyValues(OptionalParameters, ReportRow, "PresentationExpression, SortingExpression");
					EndIf;
					Result = GetSelectionOfCellsHierarchically(CellData_, ReportRow.DimensionName, AccumulatedSelection, OptionalParameters);
					
				EndIf;
				
				If ForEditing Then
					If ReportRow.EditedValues Then
						ThereIsLineWithEmptyValues = False;
						For Each ResultString1 In Result Do
							If ValueIsFilled(ResultString1[ReportRow.DimensionName]) Then
								Continue;
							EndIf;
							ThereIsLineWithEmptyValues = True;
							Break;
						EndDo;
						If Not ThereIsLineWithEmptyValues
							And (OutputEmptyLinesOfAnalytics Or DoNotOutputEmptyAnalyticsLinesUpToLevelOf < Level) Then
							Result.Add();
						EndIf;
					EndIf;
				EndIf;
				
				If Not Result.Count()
					And RowOfAnalyticsHierarchy = Undefined Then
					Result.Add();
				EndIf;
				
				SelectionFromHierarchy = (TypeOf(Result) = Type("ValueTreeRowCollection"));
				
				For Each Selection In Result Do
					
					Value = Selection[ReportRow.DimensionName];
					
					If Not ValueIsFilled(Value) Then
						If BudgetReportingClientServer.ThisIsPeriodField(ReportRow.DimensionName) Then
							Continue;
						EndIf;
						If ReportRow.DimensionName = "BudgetBalanceItem" Then
							Continue;
						EndIf;
						If ReportRow.DimensionName = "BudgetFlowItem" Then
							Continue;
						EndIf;
						ValueType = FinancialReportingCached.TypeOfAnalyticsTypeValue(
							ReportRow.DimensionName, ReportRow.DimensionKind);
						If BudgetingServer.ThisIsAnalyticsDimension(ValueType, ReportRow.DimensionKind) Then
							Value = BudgetingClientServer.ReducedAnalyticsValue(Value, ValueType);
						Else
							Value = ValueType.AdjustValue(Value);
						EndIf;
					ElsIf SelectionFromHierarchy
						And Selection.Parent <> Undefined
						And Not Selection.Parent.IsFolder
						And Value = Selection.Parent[ReportRow.DimensionName] Then
						// for Catalogs with a hierarchy of elements, the parent row is present among the subordinates
						Continue;
					EndIf;
					
					AccumulatedSelection.Insert(ReportRow.DimensionName, Value);
					
					GroupingText = GroupingText(Value,
						ReportRow,
						OutputParameters);
					
					AreaBegin.Parameters.Group = GroupingText;
					Details = GetDimensionDecryption(OutputParameters, Value, AccumulatedSelection, ReportRow);
					LineCounter = LineCounter + 1;
					OutputParameters.Insert("LineCounter", LineCounter);
					
					AreaBegin.Parameters.Details = Details;
					If OutputParameters.TableParameters.DisplayRowsNumbering Then
						AreaBegin.Parameters.LineNumber = LineCounter;
					EndIf;
					
					OutputArea2 = ResultDocument.Put(AreaBegin, Level - 1);
					
					ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
					ParametersSet.OutputParameters = OutputParameters;
					ParametersSet.Area = ScopeOfAdmission;
					ParametersSet.Value = Value;
					ParametersSet.ReportRow = ReportRow;
					ParametersSet.ReportItem = ReportRow.ReportItem;
					ParametersSet.Column = Undefined;
					
					AddDesignArea(ParametersSet, OutputArea2, AccumulatedSelection,
						TablesCounter, LineCounter, Undefined);
					
					OutputAdditionalFields(ResultDocument, ParametersSet, OutputArea2, CurrentFilter,
						LineCounter, TablesCounter);
					
					Union = TableParameters.NumberOfAdditionalColumns - 
							BudgetReportingCacheCalculationServer.NumberOfAdditionalFieldsToCalculateTreeDepth(ReportRow);
					
					MergeParameters = New Structure;
					MergeParameters.Insert("OutputArea2", OutputArea2);
					MergeParameters.Insert("ScopeOfAdmission", ScopeOfAdmission);
					MergeParameters.Insert("Union", Union);
					MergeParameters.Insert("ReportItem", ReportRow.ReportItem);
					MergeUnusedCells(ResultDocument, MergeParameters, OutputParameters, CurrentFilter,
						TablesCounter, LineCounter);
					
					OutputCellsToReport(OutputParameters, TablesCounter, AreaValue, AreaNote,
						ReportRow, ColumnStructure1, AccumulatedSelection, , ?(SelectionFromHierarchy, Selection, Undefined));
					
					AddEditListTreeLine(Value, ReportRow, GroupingText, OutputParameters,
						OutputArea2);

					OutputTableToReport(OutputParameters, ReportRow, TablesCounter, AccumulatedSelection, Level + 1,
						LineCounter, ?(SelectionFromHierarchy And Selection.IsFolder, Selection, Undefined));
						
					If SelectionFromHierarchy And Not Selection.IsFolder And Selection.Rows.Count() > 0 Then
						OutputTableToReport(OutputParameters, ReportRow, TablesCounter, AccumulatedSelection, Level
							+ 1, LineCounter, Selection);
					EndIf;
					
					SetParentOfEditListRow(OutputParameters);

					AccumulatedSelection.Delete(ReportRow.DimensionName);
					
				EndDo;
				
			EndIf; // The value is defined then
			
		EndIf;// If the output is not subordinate
		
	EndDo;
	
EndProcedure

Procedure TraversingReportTableCells(OutputParameters, ReportRow, ColumnStructure1, AccumulatedSelection, RowOfAnalyticsHierarchy = Undefined)
	
	CellData_ = OutputParameters.CellData_;
	SearchIndexes = OutputParameters.DimensionSearchIndexes;
	CellStructure = OutputParameters.CellStructure;
	TableComplex_ = OutputParameters.TableComplex_;
	CellDataAddedRows = OutputParameters.CellDataAddedRows;
	PeriodParameters_1 = OutputParameters.PeriodParameters_1;
	
	ThisIsHierarchyOfAnalyticsGroup = TypeOf(RowOfAnalyticsHierarchy) = Type("ValueTreeRow")
								And RowOfAnalyticsHierarchy.IsFolder;
	
	For Each Column In ColumnStructure1.Rows Do
		
		AddedSelection = False;
		ThisIsIndicator = StrFind(Column.DimensionName, "#Factor");
		ThisIsFixColumn =
			Column.ItemKind = Enums.FinancialReportItemKinds.RowColumn
			Or Column.ItemKind = Enums.FinancialReportItemKinds.Group
			Or Column.ItemKind = Enums.FinancialReportItemKinds.GroupFormula
			Or Column.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
		
		If Not ThisIsFixColumn
			And Not ThisIsIndicator Then
			AccumulatedSelection.Insert(Column.DimensionName, Column.FixedValue);
			AddedSelection = True;
		EndIf;
		
		If Column.Rows.Count() Then
			TraversingReportTableCells(OutputParameters, ReportRow, Column, AccumulatedSelection, RowOfAnalyticsHierarchy);
		Else
			
			OutputValue = True;
			If ReportRow.ItemKind = Enums.FinancialReportItemKinds.Group Then
				If ReportRow.Rows.Count()
					And ReportRow.Rows[0].ItemKind <> Enums.FinancialReportItemKinds.GroupFormula Then
					OutputValue = False;
				EndIf;
			EndIf;
			
			FilterColumn = Column;
			If Not TableComplex_ Then
				If ThisIsIndicator Then
					FilterColumn = FilterColumn.Parent;
				EndIf;
			EndIf;
			
			If FilterColumn <> Undefined Then
				FilterColumn = FilterColumn.ReportItem;
			EndIf;
				
			TheStructureOfTheSearch = New Structure("MainItem, String", True, ReportRow.ReportItem);
			If ValueIsFilled(FilterColumn) Then
				TheStructureOfTheSearch.Insert("Column", FilterColumn);
			EndIf;
			
			StructureStrings = CellStructure.FindRows(TheStructureOfTheSearch);
			If StructureStrings.Count() Then
				ReportCell = StructureStrings[0];
			Else
				OutputValue = False;
			EndIf;
			
			If OutputValue Then
				
				OptionalParameters = OptionalParametersForGettingSelectionOfCells();
				OptionalParameters.Column = FilterColumn;
				OptionalParameters.String = ReportRow.ReportItem;
				OptionalParameters.SearchIndexes = SearchIndexes;
				OptionalParameters.AddFlag = False;
				Rows = GetSelectionOfCells(CellData_, AccumulatedSelection, OptionalParameters);
				
				If Rows.Count() = 0 Then
					NewRow = AddRowOfCellData(CellDataAddedRows, ReportCell, AccumulatedSelection, FilterColumn);
					For Each Periodicity In PeriodParameters_1.OrderedReportPeriodicities Do
						If Not ValueIsFilled(NewRow[Periodicity]) Then
							NewRow[Periodicity] = Undefined;
						EndIf;
					EndDo;
					Rows.Add(NewRow);
				EndIf;
				If RowOfAnalyticsHierarchy <> Undefined And RowOfAnalyticsHierarchy.Rows.Count() > 0 Then
					Rows[0].HierarchyOutput = True;
					If ThisIsHierarchyOfAnalyticsGroup Then
						Rows[0].CalculationFilling = "Total";
					EndIf;
				EndIf;
				
				// Checking for currency matching
				TheStructureOfTheSearch = New Structure("String, Column, CurrencyIsDeterminedByDimension", Rows[0].String, Rows[0].Column, True);
				FoundRows = OutputParameters.CacheOfCurrencyParameters.FindRows(TheStructureOfTheSearch);
				If FoundRows.Count() Then
					
					NameKey = FinancialReportingCached.NameOfBudgetReportField(FoundRows[0].DimensionCurrencies);
					CurrencyAnalyticsValue = Undefined;
					
					If AccumulatedSelection.Property(NameKey, CurrencyAnalyticsValue) Then
						WithdrawalCurrency = Attachable_ValueFromAnalytics(
						OutputParameters.CacheAnalystValues,
						CurrencyAnalyticsValue,
						FoundRows[0].UnitOfMeasureFilling);
						
						If ValueIsFilled(WithdrawalCurrency) Then
							If Not ValueIsFilled(Rows[0].Currency) Then
								Rows[0].Currency = WithdrawalCurrency;
							EndIf;
							If OutputParameters.Property("ReportCurrency") And OutputParameters.ReportCurrency <> WithdrawalCurrency Then
								Rows[0].Currency = Undefined;
							EndIf;
						EndIf;
					EndIf;
					
				EndIf;
				
			EndIf;
		EndIf;
		
		If AddedSelection Then
			AccumulatedSelection.Delete(Column.DimensionName);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure OutputCellsToReport(OutputParameters, TablesCounter, AreaValue, AreaNote, ReportRow, ColumnStructure1, AccumulatedSelection, ColumnsCounter = 1, RowOfAnalyticsHierarchy = Undefined)
	
	ResultDocument = OutputParameters.ResultDocument;
	CellData_ = OutputParameters.CellData_;
	SearchIndexes = OutputParameters.DimensionSearchIndexes;
	ForEditing = OutputParameters.ForEditing;
	CellParameters = OutputParameters.CellParameters;
	CellStructure = OutputParameters.CellStructure;
	TableComplex_ = OutputParameters.TableComplex_;
	PeriodParameters_1 = OutputParameters.PeriodParameters_1;
	LineCounter = OutputParameters.LineCounter;
	CacheOfBudgetItemDetails = OutputParameters.CacheOfBudgetItemDetails;
	
	ThisIsHierarchyOfAnalyticsGroup = TypeOf(RowOfAnalyticsHierarchy) = Type("ValueTreeRow")
								And RowOfAnalyticsHierarchy.IsFolder;
	
	DisplayHeadersVertically = OutputParameters.TableParameters.Property("DisplayHeadersVertically")
			And OutputParameters.TableParameters.DisplayHeadersVertically = True;
	
	For Each Column In ColumnStructure1.Rows Do
		
		AddedSelection = False;
		ThisIsIndicator = StrFind(Column.DimensionName, "#Factor");
		ThisIsFixColumn =
			Column.ItemKind = Enums.FinancialReportItemKinds.RowColumn
			Or Column.ItemKind = Enums.FinancialReportItemKinds.Group
			Or Column.ItemKind = Enums.FinancialReportItemKinds.GroupFormula
			Or Column.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
		
		If Not ThisIsFixColumn
			And Not ThisIsIndicator Then
			AccumulatedSelection.Insert(Column.DimensionName, Column.FixedValue);
			AddedSelection = True;
		EndIf;
		
		If Column.Rows.Count() Then
			OutputCellsToReport(OutputParameters, TablesCounter, AreaValue, AreaNote, ReportRow,
				Column, AccumulatedSelection, ColumnsCounter, RowOfAnalyticsHierarchy);
		Else
			
			ColumnsCounter = ColumnsCounter + 1;
			OutputValue = True;
			If ReportRow.ItemKind = Enums.FinancialReportItemKinds.Group Then
				If ReportRow.Rows.Count()
					And ReportRow.Rows[0].ItemKind <> Enums.FinancialReportItemKinds.GroupFormula Then
					OutputValue = False;
				EndIf;
			ElsIf ReportRow.ItemKind = Enums.FinancialReportItemKinds.EditedValue
				And OutputParameters.GenerationMode = Enums.ModesOfBudgetReportGeneration.Report Then
				OutputValue = False;
				ForEditing = True; // to mark a cell in gray
			EndIf;
			
			FilterColumn = Column;
			If Not TableComplex_ Then
				If ThisIsIndicator Then
					IndicatorName = StrReplace(Column.DimensionName, "#Factor_", "");
					FilterColumn = FilterColumn.Parent;
				Else
					IndicatorName = "Sum";
				EndIf;
			EndIf;
			
			If FilterColumn <> Undefined Then
				FilterColumn = FilterColumn.ReportItem;
			EndIf;
				
			TheStructureOfTheSearch = New Structure("MainItem, String", True, ReportRow.ReportItem);
			If ValueIsFilled(FilterColumn) Then
				TheStructureOfTheSearch.Insert("Column", FilterColumn);
			EndIf;
			
			StructureStrings = CellStructure.FindRows(TheStructureOfTheSearch);
			If StructureStrings.Count() Then
				ReportCell = StructureStrings[0];
			Else
				OutputValue = False;
			EndIf;
			
			If Not OutputValue Then
				AreaValue.Parameters.Value = Undefined;
				AreaValue.Parameters.Details = Undefined;
				Area = ResultDocument.Join(AreaValue);
				If ForEditing And
					Not ReportRow.Rows.Count() Then
					Area.BackColor = New Color(237, 237, 237);
				EndIf;
			Else
				
				OptionalParameters = OptionalParametersForGettingSelectionOfCells();
				OptionalParameters.Column = FilterColumn;
				OptionalParameters.String = ReportRow.ReportItem;
				OptionalParameters.SearchIndexes = SearchIndexes;
				OptionalParameters.AddFlag = False;
				Rows = GetSelectionOfCells(CellData_, AccumulatedSelection, OptionalParameters);
				
				If Rows.Count() > 1 Then
					Raise NStr("vi = 'Đã xảy ra lỗi khi tạo báo cáo: Đã xảy ra lỗi khi tính toán cấu trúc ô';
								|ru = 'Ошибка формирования отчета: Ошибка расчета структуры ячеек';
								|en = 'An error occurred while generating the report: An error occurred while calculating the cell structure'; fa = 'An error occurred while generating the report: An error occurred while calculating the cell structure';
								|it = 'Errore nella creazione del rapporto: Errore nel calcolo della struttura delle celle';
								|pl = 'Błąd utworzenia raportu: Błąd rozliczenia struktury komórek';
								|tr = 'Raporun oluşturulmasında hata: Hücre yapı hesaplamasında hata'");
				Else
					
					Value = Undefined;
					Details = Undefined;
					Note = Undefined;
					
					FlagParameters = CellParameters.Find(ReportCell.RowIndex, "RowIndex");
					
					// If the formula is the first in the group, then we do not output the formula, we output the sum opposite the group.
					If TableComplex_ Then
						OutputValue = True;
						TotalFlags = Number(FlagParameters.FlagCount) + 
										Number(FlagParameters.FlagSum) + 
										Number(FlagParameters.FlagValue);
						If TotalFlags > 1 Then
							Raise NStr("vi = 'Đã xảy ra lỗi khi tạo báo cáo: Đã xảy ra lỗi khi tạo cấu trúc ô';
										|ru = 'Ошибка формирования отчета: Ошибка формирования структуры ячеек';
										|en = 'An error occurred while generating the report: An error occurred while generating the cell structure'; fa = 'An error occurred while generating the report: An error occurred while generating the cell structure';
										|it = 'Errore nella creazione del rapporto: Errore nella creazione della struttura delle celle';
										|pl = 'Błąd utworzenia raportu: Błąd utworzenia struktury komórek';
										|tr = 'Raporun oluşturulmasında hata: Hücre yapısının oluşturulmasında hata'");
						ElsIf FlagParameters.FlagCount Then
							IndicatorName = "Count";
						ElsIf FlagParameters.FlagValue Then
							IndicatorName = "Value";
						ElsIf FlagParameters.FlagSum Then
							IndicatorName = "Sum";
						Else
							OutputValue = False;
						EndIf;
					Else
						OutputValue = False;
						If FlagParameters.FlagCount Then
							OutputValue = IndicatorName = "Count";
						EndIf;
						If Not OutputValue And FlagParameters.FlagValue Then
							OutputValue = IndicatorName = "Value";
						EndIf;
						If Not OutputValue And FlagParameters.FlagSum Then
							OutputValue = IndicatorName = "Sum";
						EndIf;
					EndIf;
					
					If Not Rows.Count() Then
						NewRow = AddRowOfCellData(CellData_, ReportCell, AccumulatedSelection, FilterColumn);
						Rows.Add(NewRow);
					EndIf;
					
					AreaName = "AreaName" + IndicatorName;
					InputCurrencyIsDifferentFromCurrency = False;
					
					If OutputValue Then
						
						// Checking for currency matching
						TheStructureOfTheSearch = New Structure("String, Column, CurrencyIsDeterminedByDimension", Rows[0].String, Rows[0].Column, True);
						FoundRows = OutputParameters.CacheOfCurrencyParameters.FindRows(TheStructureOfTheSearch);
						If FoundRows.Count() Then
							
							NameKey = FinancialReportingCached.NameOfBudgetReportField(FoundRows[0].DimensionCurrencies);
							CurrencyAnalyticsValue = Undefined;
							
							If AccumulatedSelection.Property(NameKey, CurrencyAnalyticsValue) Then
								WithdrawalCurrency = Attachable_ValueFromAnalytics(
									OutputParameters.CacheAnalystValues,
									CurrencyAnalyticsValue,
									FoundRows[0].UnitOfMeasureFilling);
								
								If ValueIsFilled(WithdrawalCurrency) Then
									If Not ValueIsFilled(Rows[0].Currency) Then
										Rows[0].Currency = WithdrawalCurrency;
										If OutputParameters.Property("ReportCurrency") And OutputParameters.ReportCurrency
											<> WithdrawalCurrency Then
											Rows[0].Currency = Undefined;
										EndIf;
									Else
										If WithdrawalCurrency <> Rows[0].Currency Then
											InputCurrencyIsDifferentFromCurrency = True;
										EndIf;
									EndIf;
								EndIf;
							EndIf;
							
						EndIf;
						
						ParametersForCalculatingValue = TemplateForCellValueCalculationParameters();
						ParametersForCalculatingValue.CellData_ = CellData_;
						ParametersForCalculatingValue.CellParameters = CellParameters;
						ParametersForCalculatingValue.PeriodParameters_1 = PeriodParameters_1;
						ParametersForCalculatingValue.DataString1 = Rows[0];
						ParametersForCalculatingValue.Prefix = IndicatorName;
						ParametersForCalculatingValue.CalculatingChanges = False;
						ParametersForCalculatingValue.CacheOfBudgetItemDetails = CacheOfBudgetItemDetails;
						Value = CalculateCellValue(ParametersForCalculatingValue);
						
						Details = GetDecryption(OutputParameters,
								AccumulatedSelection,
								Rows[0],
								FlagParameters,
								IndicatorName,
								CellData_.IndexOf(Rows[0]),
								ForEditing);
						Value = ?(ValueIsFilled(Value), Value, Undefined);
						
					EndIf;
					
					Note = Rows[0].Note;
					
					If IndicatorName = "Value" Then
						If ReportRow.Rows.Count() Then
							// For non-financial indicators, the values 
							// are displayed at the lower level of the budget.
							Value = Undefined;
						EndIf;
					EndIf;
					
					AreaValue.Parameters.Value = Value;
					AreaValue.Parameters.Details = Details;
					
					Area = ResultDocument.Join(AreaValue);
					If OutputParameters.Property("SumShiftFormat") Then
						ValueOfFormula = Undefined;
						ItemKind_FormulaByGroup = Undefined;
						If ReportRow.ItemKind = Enums.FinancialReportItemKinds.GroupFormula Then
							ItemKind_FormulaByGroup = ReportRow.ReportItem;
						ElsIf ReportRow.ItemKind = Enums.FinancialReportItemKinds.Group
							And ReportRow.Rows.Count() And ReportRow.Rows[0].ItemKind
							= Enums.FinancialReportItemKinds.GroupFormula Then
							ItemKind_FormulaByGroup = ReportRow.Rows[0].ReportItem;
						ElsIf ReportRow.ItemKind = Undefined And ReportRow.Parent.ItemKind
							= Enums.FinancialReportItemKinds.GroupFormula Then
							ItemKind_FormulaByGroup = ReportRow.Parent.ReportItem;
						ElsIf Column.ItemKind = Enums.FinancialReportItemKinds.GroupFormula Then
							ItemKind_FormulaByGroup = Column.ReportItem;
						ElsIf Column.ItemKind = Enums.FinancialReportItemKinds.Group
							And Column.Rows.Count() And Column.Rows[0].ItemKind
							= Enums.FinancialReportItemKinds.GroupFormula Then
							ItemKind_FormulaByGroup = Column.Rows[0].ReportItem;
						ElsIf Column.ItemKind = Undefined And Column.Parent.ItemKind
							= Enums.FinancialReportItemKinds.GroupFormula Then
							ItemKind_FormulaByGroup = Column.Parent.ReportItem;
						EndIf;
						If ItemKind_FormulaByGroup <> Undefined Then
							PropsSearchStructure = New Structure("ReportItem, Attribute",
								ItemKind_FormulaByGroup,
								ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.GroupFormula);
							ValueOfFormula = CacheOfBudgetItemDetails.CacheOfAdditionalBankingDetails.FindRows(
								PropsSearchStructure)[0].Value;
						EndIf;
						If (IndicatorName = "Sum" Or IndicatorName = "Value") And ValueOfFormula
							<> Enums.BudgetingFormulaKinds.VariancePercent And ValueOfFormula
							<> Enums.BudgetingFormulaKinds.PerformancePercentage Then
							Area.Format = BudgetReportingClientServer.SetFormatOfShiftInFormatString(
								OutputParameters.SumShiftFormat, Area.Format);
							Area.Text = Format(Value, Area.Format);
						EndIf;
					EndIf;
					If DisplayHeadersVertically Then
						Area.ColumnWidth = Min(16, Area.Indent + StrLen(TrimAll(Area.Text)) + 3);
					EndIf;
					
					ParametersSet = ParametersForAddingDesignAreaAndDisplayingAdditionalFields();
					ParametersSet.OutputParameters = OutputParameters;
					ParametersSet.ReportItem = ReportRow.ReportItem;
					ParametersSet.Column = FilterColumn;
					LayoutString = AddDesignArea(ParametersSet, Area, AccumulatedSelection,
						TablesCounter, LineCounter, ColumnsCounter);
						
					If LayoutString <> Undefined Then
						LayoutString[IndicatorName] = Value;
						LayoutString["Flag" + IndicatorName] = True;
					EndIf;
					
					If Not OutputParameters.Property("DonTAssignNamesToAreas") Or Not ValueIsFilled(Rows[0][AreaName]) Then
						Rows[0][AreaName] = Area.Name;
						If RowOfAnalyticsHierarchy <> Undefined Then
							
							RowOfParentAnalyticsHierarchy = RowOfAnalyticsHierarchy.Parent;
							
							While RowOfParentAnalyticsHierarchy <> Undefined Do
								AccumulatedSelection.Insert(ReportRow.DimensionName, RowOfParentAnalyticsHierarchy[ReportRow.DimensionName]);
								Rows_Hierarchy = GetSelectionOfCells(OutputParameters.CellData_, AccumulatedSelection, OptionalParameters);
								AreaNameHierarchy = AreaName + "Hierarchy";
								If Not ValueIsFilled(Rows[0][AreaNameHierarchy]) Then
									Rows[0][AreaNameHierarchy] = Rows_Hierarchy[0][AreaName];
								EndIf;
								If RowOfAnalyticsHierarchy.Rows.Count() = 0
									And RowOfParentAnalyticsHierarchy.IsFolder Then
									IndicatorNameTurnover = ?(IndicatorName = "Sum" And Rows[0].CalculationFilling <> "Total", "SumTurnover", IndicatorName);
									If ValueIsFilled(Rows[0][IndicatorNameTurnover]) Then
										Rows_Hierarchy[0][IndicatorName] = Rows_Hierarchy[0][IndicatorName] + Rows[0][IndicatorNameTurnover];
										ParentArea = ResultDocument.Area(Rows_Hierarchy[0][AreaName]); 
										DecryptionOfParent = OutputParameters.DetailsData.Get(ParentArea.Details);
										DecryptionOfParent.Value = Rows_Hierarchy[0][IndicatorName];
										ParentArea.Text = Format(Rows_Hierarchy[0][IndicatorName], ParentArea.Format);
									EndIf;
								Else
									Break;
								EndIf;

								RowOfParentAnalyticsHierarchy = RowOfParentAnalyticsHierarchy.Parent;
								
							EndDo;
							
							AccumulatedSelection.Insert(ReportRow.DimensionName, RowOfAnalyticsHierarchy[ReportRow.DimensionName]);
							
						EndIf;
					EndIf;
					
					CanBeEdited = False;
					If (OutputParameters.ForEditing 
						Or OutputParameters.DisplayNotes_)
						And Not ThisIsHierarchyOfAnalyticsGroup Then
						
						If ReportCell.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
							If ReportCell.ID_Source1 = "Document" Then
								CanBeEdited = FlagParameters["Flag" + IndicatorName];
							EndIf;
							
						ElsIf ReportCell.ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
							If ReportCell.ID_Source1 = "Document_Values" Then
								CanBeEdited = FlagParameters["Flag" + IndicatorName];
							EndIf;
							
						EndIf;
						
					EndIf;
					
					If OutputParameters.ForEditing Then
						
						If CanBeEdited And OutputParameters.Property("AddedLinesDecryption") And Details <> Undefined Then
							OutputParameters.AddedLinesDecryption.Add(OutputParameters.DetailsData[Details]);
						EndIf;
						
						If CanBeEdited And Not InputCurrencyIsDifferentFromCurrency Then
							
							If Not ReportRow.Rows.Count() Then
								If FlagParameters.ReverseSign Then // to enter, change the sign
									Area.TextColor = WebColors.Red;
									If TypeOf(Value) = Type("Number") Then
										Value = -Value;
									EndIf;
								EndIf;
								Area.ContainsValue = True;
								If Rows[0].ItemKind = Enums.FinancialReportItemKinds.EditedValue
									And FlagParameters.EditedValueType <> "Number" Then
									If FlagParameters.EditedValueType = "String" Then
										Area.ValueType = New TypeDescription("String");
										Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Wrap;
									ElsIf FlagParameters.EditedValueType = "Boolean" Then
										Area.ValueType = New TypeDescription("Boolean");
									ElsIf FlagParameters.EditedValueType = "Date" Then
										Area.ValueType = New TypeDescription("Date");
									ElsIf FlagParameters.EditedValueType = "VATRate" Then
										Area.ValueType = New TypeDescription("CatalogRef.VATRates");
									EndIf;
								Else
									If IndicatorName = "Count" Then
										Area.ValueType = Metadata.Documents.BudgetEntryForm.TabularSections.BudgetFlowItemTurnovers.Attributes["Count"].Type;
									Else
										Area.ValueType = TMCommonUse.MoneyFieldTypeDescription();
									EndIf;
								EndIf;
								Area.Value = Value;
								Area.Protection = False;
								
								Area.Comment.Text = Note;
							EndIf;
							
						ElsIf Not ReportRow.Rows.Count() Then
							
							Area.BackColor = New Color(237, 237, 237);
							
						EndIf;
						
					ElsIf OutputParameters.DisplayNotes_ 
						And CanBeEdited
						And Not ReportRow.Rows.Count()
						And Not IsBlankString(Note) Then
						
						If Rows[0].ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
							
							CurTableNumber = OutputParameters.Remarks.TableNumber;
							
							CurNoteNumber = OutputParameters.Remarks.NoteNumber + 1;
							OutputParameters.Remarks.NoteNumber = CurNoteNumber;
							
							Area.UndoMerge();
							
							NoteCell = ResultDocument.Area(Area.Top,Area.Right, Area.Top, Area.Right);
							
							AreaNote.Parameters.Text = Format(CurNoteNumber, "NG=");
							
							ResultDocument.InsertArea(AreaNote.Area(),NoteCell,,True);
							
							NewDataLine = OutputParameters.Remarks.DataTable.Add();
							FillPropertyValues(NewDataLine, Rows[0]);
							NewDataLine.TableNumber = CurTableNumber;
							NewDataLine.NoteNumber = CurNoteNumber;
							
						EndIf;
						
					EndIf;
					
				EndIf;
			EndIf;
		EndIf;
		
		If AddedSelection Then
			AccumulatedSelection.Delete(Column.DimensionName);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

// Displays text in the area of the budget table document.
// 
// Parameters:
// 	ResultDocument - SpreadsheetDocument - A tabular document that displays the budget.
// 	StructureOfAreas - See BudgetReportingDisplayServer.StructureOfTemplateAreas
// 	OutputItem - ValueTreeRow - A line in the budget tree.
//
Procedure OutputTextBlockToReport(ResultDocument, StructureOfAreas, OutputItem)
	
	If OutputItem.ItemKind = Enums.FinancialReportItemKinds.ReportHeader Then
		Area = StructureOfAreas.ReportHeader;
		Area.Parameters.ReportHeader = OutputItem.NameForPrinting;
	ElsIf OutputItem.ItemKind = Enums.FinancialReportItemKinds.ComplexTable
		Or OutputItem.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInColumns
		Or OutputItem.ItemKind = Enums.FinancialReportItemKinds.TableIndicatorsInRows Then
		Area = StructureOfAreas.TableHeading;
		Area.Parameters.TableHeading = OutputItem.NameForPrinting;
	Else
		Area = StructureOfAreas.Text;
		Area.Parameters.Text  = OutputItem.NameForPrinting;
	EndIf;
	
	ResultDocument.Put(Area, 0);
	
EndProcedure

#EndRegion

#Region Budgeting_

Procedure ArrangeAreasBasedOnLayoutResults(ResultDocument, OutputParameters, DesignTable, AppearanceItems)
	
	For Each LayoutString In DesignTable Do
		
		FoundRow = AppearanceItems.Find(LayoutString.AppearanceItemKey, "AppearanceItemKey");
		Areas = LayoutString.AreaName;
		DesignRepository = FoundRow.Appearance; // ValueStorage
		Appearance = DesignRepository.Get();
		
		For Each AreaName In Areas Do
			If Not ValueIsFilled(AreaName) Then
				Continue;
			EndIf;
			DocumentArea = ResultDocument.Area(AreaName);
			For Each AppearanceItem In Appearance Do
				If AppearanceItem.Parameter = "BackColor" Then
					DocumentArea.BackColor = AppearanceItem.Appearance;
				ElsIf AppearanceItem.Parameter = "TextColor" Then
					DocumentArea.TextColor = AppearanceItem.Appearance;
				ElsIf AppearanceItem.Parameter = "BorderColor" Then
					DocumentArea.BorderColor = AppearanceItem.Appearance;
				ElsIf AppearanceItem.Parameter = "Font" Then
					DocumentArea.Font = AppearanceItem.Appearance;
				ElsIf AppearanceItem.Parameter = "HorizontalAlign" Then
					DocumentArea.HorizontalAlign = AppearanceItem.Appearance;
				ElsIf AppearanceItem.Parameter = "VerticalAlign" Then
					DocumentArea.VerticalAlign = AppearanceItem.Appearance;
				ElsIf AppearanceItem.Parameter = "TextOrientation" Then
					DocumentArea.TextOrientation = AppearanceItem.Appearance;
				ElsIf AppearanceItem.Parameter = "Format" Then
					If Not DocumentArea.ContainsValue Then
						DocumentArea.Format = AppearanceItem.Appearance;
						Details = DocumentArea.Details;
						Details = OutputParameters.DetailsData[Details];
						If TypeOf(Details) = Type("Structure")
							And Details.Property("Value") Then
							If OutputParameters.Property("SumShiftFormat") Then
								Format = BudgetReportingClientServer.SetFormatOfShiftInFormatString(
									OutputParameters.SumShiftFormat, AppearanceItem.Appearance);
								DocumentArea.Text = Format(Details.Value, Format);
							Else
								DocumentArea.Text = Format(Details.Value, AppearanceItem.Appearance);
							EndIf;
						EndIf;
					Else
						DocumentArea.Format = AppearanceItem.Appearance;
						Begin = StrFind(Upper(DocumentArea.Format), "EMERGENCY");
						If Begin Then
							RowBalance = Mid(DocumentArea.Format, Begin);
							Separator = StrFind(RowBalance, ";");
							If Separator Then
								RowBalance = Left(RowBalance, Separator);
							EndIf;
							DocumentArea.Format = StrReplace(DocumentArea.Format, RowBalance, "");
							RowBalance = Mid(RowBalance, StrFind(RowBalance, "=")+1);
							RowBalance = StrReplace(RowBalance, "'", "");
							RowBalance = TrimAll(RowBalance);
							If Left(RowBalance, 1) = "-" Then
								Character = -1;
								RowBalance = Mid(RowBalance, 2);
							Else
								Character = 1;
							EndIf;
							If Not IsBlankString(RowBalance) And 
								StringFunctionsClientServer.OnlyNumbersInString(RowBalance, False, False) Then
								
								RowBalance = Character * Number(RowBalance);
								OutputParameters.DetailsData[DocumentArea.Details].Insert("AbbreviatedDigits", RowBalance);
								DocumentArea.Value = DocumentArea.Value / Pow(10, RowBalance);
								
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndDo;
		
	EndDo;
	
EndProcedure

Function DesignAreasFromTable(Table, AppearanceItemKey) Export
	
	Array = New Array;
	FoundRows = Table.FindRows(New Structure("AppearanceItemKey", AppearanceItemKey));
	For Each FoundRow In FoundRows Do
		Array.Add(FoundRow.AreaName);
	EndDo;
	
	Return Array;
	
EndFunction

Function GetPreliminaryLayoutForDesignCalculation()
	
	FinReports = FinancialReportingServer;
	
	CellsByKey = DataCompositionServer.EmptyCircuit();
	
	Set = DataCompositionServer.AddEmptyDataSet(CellsByKey,
		Type("DataCompositionSchemaDataSetObject"), "AppearanceItems");
	Set.ObjectName = "AppearanceItems";
	FinReports.NewSetField(Set, "AppearanceItemKey", "AppearanceItemKey", , New TypeDescription("UUID"));
	FinReports.NewSetField(Set, "CreatedAreaType");
	FinReports.NewSetField(Set, "SequenceNumber");
	FinReports.NewSetField(Set, "TableNumber");
	
	Set = DataCompositionServer.AddEmptyDataSet(CellsByKey,
		Type("DataCompositionSchemaDataSetObject"), "RegisteredRows");
	Set.ObjectName = "RegisteredRows";
	FinReports.NewSetField(Set, "ReportItem", "String");
	FinReports.NewSetField(Set, "AppearanceItemKey", "AppearanceItemKey", , New TypeDescription("UUID"));
	
	Set = DataCompositionServer.AddEmptyDataSet(CellsByKey,
		Type("DataCompositionSchemaDataSetObject"), "DesigningColumns");
	Set.ObjectName = "DesigningColumns";
	FinReports.NewSetField(Set, "ReportItem", "Column");
	FinReports.NewSetField(Set, "AppearanceItemKey", "AppearanceItemKey", , New TypeDescription("UUID"));
	
	FinReports.NewConnection(CellsByKey, "AppearanceItems", "RegisteredRows", "AppearanceItemKey");
	FinReports.NewConnection(CellsByKey, "AppearanceItems", "DesigningColumns", "AppearanceItemKey");
	
	Group = CellsByKey.DefaultSettings.Structure.Add(Type("DataCompositionGroup"));
	Group.GroupFields.Items.Add(Type("DataCompositionAutoGroupField"));
	Group.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	
	FinReports.NewSelectionField(CellsByKey.DefaultSettings, "AppearanceItemKey");
	FinReports.NewSelectionField(CellsByKey.DefaultSettings, "CreatedAreaType");
	FinReports.NewSelectionField(CellsByKey.DefaultSettings, "String");
	FinReports.NewSelectionField(CellsByKey.DefaultSettings, "Column");
	FinReports.NewSelectionField(CellsByKey.DefaultSettings, "SequenceNumber");
	FinReports.NewSelectionField(CellsByKey.DefaultSettings, "TableNumber");
	
	FinReports.SetOutputParameter(CellsByKey.DefaultSettings,
			"HorizontalOverallPlacement",
			DataCompositionTotalPlacement.None);
	FinReports.SetOutputParameter(CellsByKey.DefaultSettings,
			"VerticalOverallPlacement",
			DataCompositionTotalPlacement.None);
	
	Return CellsByKey;
	
EndFunction

Function GetBasicLayoutForCalculatingLayout(AppearanceItems, CreatedAreaType, ReportDataForFormatting)
	
	FinReports = FinancialReportingServer;
	
	LayoutByCells = DataCompositionServer.EmptyCircuit();
	Set = DataCompositionServer.AddEmptyDataSet(LayoutByCells,
		Type("DataCompositionSchemaDataSetObject"), "DataTable");
	Set.ObjectName = "DataTable";
	
	For Each Column In ReportDataForFormatting.Columns Do
		FinReports.NewSetField(Set, Column.Name, Column.Name);
	EndDo;
	
	FinReports.NewCalculatedField(LayoutByCells,
		"CellValue",
		"
		|CASE 
		|	WHEN FlagValue = TRUE THEN VALUE
		|	WHEN FlagSum = TRUE THEN Sum
		|	WHEN FlagCount = TRUE THEN Count
		|END");
	
	Set = DataCompositionServer.AddEmptyDataSet(LayoutByCells,
		Type("DataCompositionSchemaDataSetObject"), "CellsByKey");
	Set.ObjectName = "CellsByKey";
	FinReports.NewSetField(Set, "CreatedAreaType");
	FinReports.NewSetField(Set, "AppearanceItemKey");
	FinReports.NewSetField(Set, "String", "RowOfCells");
	FinReports.NewSetField(Set, "Column", "ColumnOfCells");
	FinReports.NewSetField(Set, "SequenceNumber");
	FinReports.NewSetField(Set, "TableNumber");
	
	Group = FinReports.NewGrouping(LayoutByCells.DefaultSettings.Structure, "AppearanceItemKey");
	FinReports.NewDimensionField(Group, "SequenceNumber");
	
	FinReports.NewFilter(LayoutByCells.DefaultSettings.Filter, "CreatedAreaType", CreatedAreaType);
	
	OrGroup = LayoutByCells.DefaultSettings.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	TableOfElements = AppearanceItems.Copy(New Structure("CreatedAreaType", CreatedAreaType));
	
	For Each AppearanceItem In TableOfElements Do
		AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
		FinReports.NewFilter(AndGroup, "AppearanceItemKey", AppearanceItem.AppearanceItemKey);
		Condition = AppearanceItem.Condition; // ValueStorage
		FinReports.CopyFilter(Condition.Get().Filter, AndGroup, True);
	EndDo;
	
	FinReports.SetOutputParameter(LayoutByCells.DefaultSettings,
			"HorizontalOverallPlacement",
			DataCompositionTotalPlacement.None);
	FinReports.SetOutputParameter(LayoutByCells.DefaultSettings,
			"VerticalOverallPlacement",
			DataCompositionTotalPlacement.None);
	
	Return LayoutByCells;
	
EndFunction

Function GetBasicLayoutOfEntireRowColumnLayout(ReportDataForFormatting)
	
	FinReports = FinancialReportingServer;
	
	LayoutByCells = DataCompositionServer.EmptyCircuit();
	Set = DataCompositionServer.AddEmptyDataSet(LayoutByCells,
		Type("DataCompositionSchemaDataSetObject"), "DataTable");
	Set.ObjectName = "DataTable";
	For Each Column In ReportDataForFormatting.Columns Do
		FinReports.NewSetField(Set, Column.Name, Column.Name);
	EndDo;
	
	Set = DataCompositionServer.AddEmptyDataSet(LayoutByCells,
		Type("DataCompositionSchemaDataSetObject"), "AvailableKeys");
	Set.ObjectName = "AvailableKeys";
	FinReports.NewSetField(Set, "AppearanceItemKey");
	FinReports.NewSetField(Set, "SequenceNumber");
	FinReports.NewSetField(Set, "String");
	FinReports.NewSetField(Set, "Column");
	FinReports.NewSetField(Set, "TableNumber");
	
	Group = FinReports.NewGrouping(LayoutByCells.DefaultSettings.Structure, "AppearanceItemKey");
	FinReports.NewDimensionField(Group, "SequenceNumber");
	
	FinReports.SetOutputParameter(LayoutByCells.DefaultSettings,
			"HorizontalOverallPlacement",
			DataCompositionTotalPlacement.None);
	FinReports.SetOutputParameter(LayoutByCells.DefaultSettings,
			"VerticalOverallPlacement",
			DataCompositionTotalPlacement.None);
	
	Return LayoutByCells;
	
EndFunction

Function CalculateRenderedCellsByRowColumn(CreatedAreaType, AppearanceItems,
							ReportDataForFormatting, DrillDownOfAppearanceItemFilterFields, CellsByKey)
	
	FinReports = FinancialReportingServer;
	
	LayoutByCells = GetBasicLayoutForCalculatingLayout(AppearanceItems,
			CreatedAreaType,
			ReportDataForFormatting);
	
	ConnectionFieldOfFinalSets = ?(CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.EntireRow, "String", "Column");
	FinReports.NewDimensionField(LayoutByCells.DefaultSettings.Structure[0], ConnectionFieldOfFinalSets);
	FinReports.NewDimensionField(LayoutByCells.DefaultSettings.Structure[0], "TableNumber");
	
	If CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.EntireRow Then
		FinReports.NewConnection(LayoutByCells, "CellsByKey", "DataTable", "RowOfCells", "String");
	Else
		FinReports.NewConnection(LayoutByCells, "CellsByKey", "DataTable", "ColumnOfCells", "Column");
	EndIf;
	FinReports.NewConnection(LayoutByCells, "CellsByKey", "DataTable", "TableNumber", "TableNumber");
	
	TableOfElements = AppearanceItems.Copy(New Structure("CreatedAreaType", CreatedAreaType));
	
	For Each AppearanceItem In TableOfElements Do
		
		ReplacementElements = DrillDownOfAppearanceItemFilterFields.FindRows(New Structure("AppearanceItemKey", AppearanceItem.AppearanceItemKey));
		
		For Each ReplacementElement In ReplacementElements Do
			
			If LayoutByCells.CalculatedFields.Find("[" + ReplacementElement.FilterFieldName + "]") <> Undefined Then
				Continue;
			EndIf;
			
			ItemTypeName = ?(CreatedAreaType = Enums.DesignedAreaTypesOfBudgetReports.EntireRow, "Column", "String");
			NameOfFilterParameter = ItemTypeName + "_" + StrReplace(New UUID, "-", "_");
			FinancialReportingServer.NewCalculatedField(LayoutByCells,
					ReplacementElement.FilterFieldName,
					"CASE WHEN " + ItemTypeName + " = &" + NameOfFilterParameter + " THEN
					|				" + ReplacementElement.ResourceName + " ELSE NULL END");
			
			FinReports.NewSelectionField(LayoutByCells.DefaultSettings, ReplacementElement.FilterFieldName);
			Parameter = LayoutByCells.Parameters.Add();
			Parameter.Name = NameOfFilterParameter;
			Parameter.Value = ReplacementElement.ReportItem;
			
		EndDo;
		
	EndDo;
	
	ExternalSets = New Structure;
	ExternalSets.Insert("CellsByKey", CellsByKey);
	ExternalSets.Insert("DataTable", ReportDataForFormatting);
	
	SettingsComposer = FinReports.SchemaComposer(LayoutByCells);
	For Each Parameter In LayoutByCells.Parameters Do
		FinReports.SetParameter(SettingsComposer.Settings.DataParameters, Parameter.Name, Parameter.Value, True);
	EndDo;
	AvailableKeys = FinReports.UploadDCSResults(LayoutByCells, SettingsComposer, ExternalSets);
	
	LayoutByCells = GetBasicLayoutOfEntireRowColumnLayout(ReportDataForFormatting);
	
	FinReports.NewConnection(LayoutByCells, "AvailableKeys", "DataTable", "TableNumber", "TableNumber");
	FinReports.NewConnection(LayoutByCells, "AvailableKeys", "DataTable", ConnectionFieldOfFinalSets);
	
	FinReports.NewResource(LayoutByCells, "AreaName",,"ARRAY(AreaName)");
	FinReports.NewSelectionField(LayoutByCells.DefaultSettings, "AreaName");
	
	ExternalSets = New Structure;
	ExternalSets.Insert("AvailableKeys", AvailableKeys);
	ExternalSets.Insert("DataTable", ReportDataForFormatting);
	
	SettingsComposer = FinReports.SchemaComposer(LayoutByCells);
	Result = FinReports.UploadDCSResults(LayoutByCells, SettingsComposer, ExternalSets);
	
	Return Result;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	TabularDocumentResult - SpreadsheetDocument -
// 	OutputParameters - See AddOutputParameter.OutputParameters
// 	OutputTree - See BudgetReportingCacheCalculationServer.NewOutputTree
Procedure CreateBudget(TabularDocumentResult, OutputParameters, OutputTree) Export
	
	ReportDataForFormatting =
		OutputParameters.ReportDataForFormatting; // See BudgetReportingCacheCalculationServer.ReportDataForFormatting
	
	If ReportDataForFormatting = Undefined Then
		// Measurements and indicators without a table
		Return;
	EndIf;
	
	DesignTable = Undefined;
	
	AppearanceItems = New ValueTable;
	AppearanceItems.Columns.Add("SequenceNumber");
	AppearanceItems.Columns.Add("Appearance");
	AppearanceItems.Columns.Add("Condition");
	AppearanceItems.Columns.Add("CreatedAreaType");
	AppearanceItems.Columns.Add("AppearanceItemKey");
	AppearanceItems.Columns.Add("TableNumber");
	
	RegisteredRows = New ValueTable;
	RegisteredRows.Columns.Add("ReportItem");
	RegisteredRows.Columns.Add("AppearanceItemKey");
	
	DesigningColumns = New ValueTable;
	DesigningColumns.Columns.Add("ReportItem");
	DesigningColumns.Columns.Add("AppearanceItemKey");
	
	DrillDownOfAppearanceItemFilterFields = New ValueTable;
	DrillDownOfAppearanceItemFilterFields.Columns.Add("ReportItem");
	DrillDownOfAppearanceItemFilterFields.Columns.Add("AppearanceItemKey");
	DrillDownOfAppearanceItemFilterFields.Columns.Add("FilterFieldName");
	DrillDownOfAppearanceItemFilterFields.Columns.Add("ResourceName");
	
	TableStructure = New Structure("AppearanceItems, RegisteredRows, DesigningColumns, DrillDownOfAppearanceItemFilterFields");
	
	TableRows_ = OutputTree.Rows.FindRows(New Structure("DimensionName", "Table"));
	TableNumber = 1;
	For Each TableRow In TableRows_ Do
		
		For Each KeyAndValue In TableStructure Do
			Table = Undefined;
			
			TableName = KeyAndValue.Key;
			
			If TableRow.TableParameters.Property(TableName, Table) Then
				If TableName = "AppearanceItems" Then
					If Table.Columns.Find("TableNumber") = Undefined Then
						Table.Columns.Add("TableNumber");	
					EndIf;
					Table.FillValues(TableNumber, "TableNumber");
				EndIf;
				
				If TableName = "AppearanceItems" Then
					CommonClientServer.SupplementTable(Table, AppearanceItems);
				ElsIf TableName = "RegisteredRows" Then
					CommonClientServer.SupplementTable(Table, RegisteredRows);
				ElsIf TableName = "DesigningColumns" Then
					CommonClientServer.SupplementTable(Table, DesigningColumns);
				ElsIf TableName = "DrillDownOfAppearanceItemFilterFields" Then
					CommonClientServer.SupplementTable(Table, DrillDownOfAppearanceItemFilterFields);
				EndIf;
			EndIf;
		EndDo;
		TableNumber = TableNumber + 1;
	EndDo;
	
	If Not AppearanceItems.Count() Then
		Return;
	EndIf;
	
	For Each String In AppearanceItems Do
		String.SequenceNumber = AppearanceItems.IndexOf(String);
	EndDo;
	
	FinReports = FinancialReportingServer;
	
	CellLayoutByKey = GetPreliminaryLayoutForDesignCalculation();
	
	ExternalSets = New Structure;
	ExternalSets.Insert("AppearanceItems", AppearanceItems);
	ExternalSets.Insert("RegisteredRows", RegisteredRows);
	ExternalSets.Insert("DesigningColumns", DesigningColumns);
	
	SettingsComposer = FinReports.SchemaComposer(CellLayoutByKey);
	CellsByKey = FinReports.UploadDCSResults(CellLayoutByKey, SettingsComposer, ExternalSets);
	
	DesignTable = New ValueTable;
	DesignTable.Columns.Add("AppearanceItemKey");
	DesignTable.Columns.Add("AreaName");
	DesignTable.Columns.Add("SequenceNumber");
	
	ExternalSets = New Structure;
	ExternalSets.Insert("CellsByKey", CellsByKey);
	ExternalSets.Insert("DataTable", ReportDataForFormatting);
	
	// Getting areas for registration. Cells
	
	FormalizedType = Enums.DesignedAreaTypesOfBudgetReports.CellsAtIntersectionOfRowsAndColumns;
	If AppearanceItems.Find(FormalizedType, "CreatedAreaType") <> Undefined Then
		
		LayoutByCells = GetBasicLayoutForCalculatingLayout(AppearanceItems, FormalizedType, ReportDataForFormatting);
		
		FinReports.NewConnection(LayoutByCells, "CellsByKey", "DataTable", "RowOfCells", "String");
		FinReports.NewConnection(LayoutByCells, "CellsByKey", "DataTable", "ColumnOfCells", "Column");
		
		FinReports.NewResource(LayoutByCells, "AreaName",,"ARRAY(AreaName)");
		FinReports.NewSelectionField(LayoutByCells.DefaultSettings, "AreaName");
		
		SettingsComposer = FinReports.SchemaComposer(LayoutByCells);
		Result = FinReports.UploadDCSResults(LayoutByCells, SettingsComposer, ExternalSets);
		
		CommonClientServer.SupplementTable(Result, DesignTable);
		
	EndIf;
	
	FormalizedType = Enums.DesignedAreaTypesOfBudgetReports.EntireRow;
	If AppearanceItems.Find(FormalizedType, "CreatedAreaType") <> Undefined Then
		
		// Getting areas for registration. Lines
		Result = CalculateRenderedCellsByRowColumn(FormalizedType,
				AppearanceItems, ReportDataForFormatting,
				DrillDownOfAppearanceItemFilterFields,
				CellsByKey);
		
		CommonClientServer.SupplementTable(Result, DesignTable);
		
	EndIf;
	
	FormalizedType = Enums.DesignedAreaTypesOfBudgetReports.EntireColumn;
	If AppearanceItems.Find(FormalizedType, "CreatedAreaType") <> Undefined Then
		
		// Getting areas for registration. Columns
		
		Result = CalculateRenderedCellsByRowColumn(FormalizedType,
				AppearanceItems, ReportDataForFormatting,
				DrillDownOfAppearanceItemFilterFields,
				CellsByKey);
		
		CommonClientServer.SupplementTable(Result, DesignTable);
		
	EndIf;
	
	FormalizedType = Enums.DesignedAreaTypesOfBudgetReports.RowsHeaders;
	If AppearanceItems.Find(FormalizedType, "CreatedAreaType") <> Undefined Then
		
		// Getting areas for registration. Headingstroke
		
		LayoutByCells = GetBasicLayoutForCalculatingLayout(AppearanceItems,
				FormalizedType,
				ReportDataForFormatting);
		
		FinReports.NewConnection(LayoutByCells, "CellsByKey", "DataTable", "RowOfCells", "String");
		
		FinReports.NewResource(LayoutByCells, "AreaName",,"ARRAY(AreaName)");
		FinReports.NewSelectionField(LayoutByCells.DefaultSettings, "AreaName");
		
		FilterElement = FinReports.NewFilter(LayoutByCells.DefaultSettings.Filter, "Column");
		FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		SettingsComposer = FinReports.SchemaComposer(LayoutByCells);
		Result = FinReports.UploadDCSResults(LayoutByCells, SettingsComposer, ExternalSets);
		
		CommonClientServer.SupplementTable(Result, DesignTable);
	
	EndIf;
	
	FormalizedType = Enums.DesignedAreaTypesOfBudgetReports.ColumnHeaders;
	If AppearanceItems.Find(FormalizedType, "CreatedAreaType") <> Undefined Then
		
		// Getting areas for registration. Column Headings
		
		LayoutByCells = GetBasicLayoutForCalculatingLayout(AppearanceItems,
				FormalizedType,
				ReportDataForFormatting);
		
		FinReports.NewConnection(LayoutByCells, "CellsByKey", "DataTable", "ColumnOfCells", "Column");
		
		FinReports.NewResource(LayoutByCells, "AreaName",,"ARRAY(AreaName)");
		FinReports.NewSelectionField(LayoutByCells.DefaultSettings, "AreaName");
		FilterElement = FinReports.NewFilter(LayoutByCells.DefaultSettings.Filter, "String");
		FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		SettingsComposer = FinReports.SchemaComposer(LayoutByCells);
		Result = FinReports.UploadDCSResults(LayoutByCells, SettingsComposer, ExternalSets);
		
		CommonClientServer.SupplementTable(Result, DesignTable);
		
	EndIf;
	
	FormalizedType = Enums.DesignedAreaTypesOfBudgetReports.EntireTable;
	If AppearanceItems.Find(FormalizedType, "CreatedAreaType") <> Undefined Then
	
		// Getting areas for registration. The whole table
		
		LayoutByCells = GetBasicLayoutForCalculatingLayout(AppearanceItems,
				FormalizedType,
				ReportDataForFormatting);
		
		FinReports.NewConnection(LayoutByCells, "CellsByKey", "DataTable", "TableNumber", "TableNumber");
		
		FinReports.NewResource(LayoutByCells, "AreaName",,"ARRAY(AreaName)");
		FinReports.NewSelectionField(LayoutByCells.DefaultSettings, "AreaName");
		
		SettingsComposer = FinReports.SchemaComposer(LayoutByCells);
		Result = FinReports.UploadDCSResults(LayoutByCells, SettingsComposer, ExternalSets);
		
		CommonClientServer.SupplementTable(Result, DesignTable);
	
	EndIf;
	
	DesignTable.Sort("SequenceNumber");
	
	ArrangeAreasBasedOnLayoutResults(TabularDocumentResult, OutputParameters, DesignTable, AppearanceItems);
	
EndProcedure

#EndRegion

#Region FunctionsOfBudgetReportFormulas

Function CheckFunctionArgument(Argument) Export
	
	If Argument = Undefined Then
		Return False;
	EndIf;
	
	Try
		Argument = Number(Argument);
	Except
		Argument = Undefined;
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function Maximum(Value1, Value2 = Undefined, Value3 = Undefined, Value4 = Undefined,
	Value5 = Undefined, Value6 = Undefined, Value7 = Undefined, Value8 = Undefined,
	Value9 = Undefined, Value10 = Undefined, Value11 = Undefined, Value12 = Undefined,
	Value13 = Undefined, Value14 = Undefined, Value15 = Undefined, Value16 = Undefined,
	Value17 = Undefined, Value18 = Undefined, Value19 = Undefined, Value20 = Undefined) Export
	
	ArrayOfValues = New Array;
	ArrayOfValues.Add(Value1);
	ArrayOfValues.Add(Value2);
	ArrayOfValues.Add(Value3);
	ArrayOfValues.Add(Value4);
	ArrayOfValues.Add(Value5);
	ArrayOfValues.Add(Value6);
	ArrayOfValues.Add(Value7);
	ArrayOfValues.Add(Value8);
	ArrayOfValues.Add(Value9);
	ArrayOfValues.Add(Value10);
	ArrayOfValues.Add(Value11);
	ArrayOfValues.Add(Value12);
	ArrayOfValues.Add(Value13);
	ArrayOfValues.Add(Value14);
	ArrayOfValues.Add(Value15);
	ArrayOfValues.Add(Value16);
	ArrayOfValues.Add(Value17);
	ArrayOfValues.Add(Value18);
	ArrayOfValues.Add(Value19);
	ArrayOfValues.Add(Value20);
	
	Result = Undefined;
	For Each FunctionValue In ArrayOfValues Do
		
		CountAttachments = 0;
		BypassedEverything = False;
		While Not BypassedEverything Do
			If TypeOf(FunctionValue) = Type("Array") Then
				If CountAttachments = FunctionValue.Count() Then
					BypassedEverything = True;
					Continue;
				EndIf;
				Value = FunctionValue[CountAttachments];
				CountAttachments = CountAttachments + 1;
			Else
				Value = FunctionValue;
				BypassedEverything = True;
			EndIf;
			
			If Not CheckFunctionArgument(Value) Then
				Continue;
			EndIf;
			
			If Result = Undefined Then
				Result = Value;
			Else
				Result = Max(Result, Value);
			EndIf;
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function Minimum(Value1, Value2 = Undefined, Value3 = Undefined, Value4 = Undefined,
	Value5 = Undefined, Value6 = Undefined, Value7 = Undefined, Value8 = Undefined,
	Value9 = Undefined, Value10 = Undefined, Value11 = Undefined, Value12 = Undefined,
	Value13 = Undefined, Value14 = Undefined, Value15 = Undefined, Value16 = Undefined,
	Value17 = Undefined, Value18 = Undefined, Value19 = Undefined, Value20 = Undefined) Export
	
	ArrayOfValues = New Array;
	ArrayOfValues.Add(Value1);
	ArrayOfValues.Add(Value2);
	ArrayOfValues.Add(Value3);
	ArrayOfValues.Add(Value4);
	ArrayOfValues.Add(Value5);
	ArrayOfValues.Add(Value6);
	ArrayOfValues.Add(Value7);
	ArrayOfValues.Add(Value8);
	ArrayOfValues.Add(Value9);
	ArrayOfValues.Add(Value10);
	ArrayOfValues.Add(Value11);
	ArrayOfValues.Add(Value12);
	ArrayOfValues.Add(Value13);
	ArrayOfValues.Add(Value14);
	ArrayOfValues.Add(Value15);
	ArrayOfValues.Add(Value16);
	ArrayOfValues.Add(Value17);
	ArrayOfValues.Add(Value18);
	ArrayOfValues.Add(Value19);
	ArrayOfValues.Add(Value20);
	
	Result = Undefined;
	For Each FunctionValue In ArrayOfValues Do
		
		CountAttachments = 0;
		BypassedEverything = False;
		While Not BypassedEverything Do
			If TypeOf(FunctionValue) = Type("Array") Then
				If CountAttachments = FunctionValue.Count() Then
					BypassedEverything = True;
					Continue;
				EndIf;
				Value = FunctionValue[CountAttachments];
				CountAttachments = CountAttachments + 1;
			Else
				Value = FunctionValue;
				BypassedEverything = True;
			EndIf;
			
			If Not CheckFunctionArgument(Value) Then
				Continue;
			EndIf;
			
			If Result = Undefined Then
				Result = Value;
			Else
				Result = Min(Result, Value);
			EndIf;
			
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

Function Sum(Value1, Value2 = Undefined, Value3 = Undefined, Value4 = Undefined,
	Value5 = Undefined, Value6 = Undefined, Value7 = Undefined, Value8 = Undefined,
	Value9 = Undefined, Value10 = Undefined, Value11 = Undefined, Value12 = Undefined,
	Value13 = Undefined, Value14 = Undefined, Value15 = Undefined, Value16 = Undefined,
	Value17 = Undefined, Value18 = Undefined, Value19 = Undefined, Value20 = Undefined) Export
	
	ArrayOfValues = New Array;
	ArrayOfValues.Add(Value1);
	ArrayOfValues.Add(Value2);
	ArrayOfValues.Add(Value3);
	ArrayOfValues.Add(Value4);
	ArrayOfValues.Add(Value5);
	ArrayOfValues.Add(Value6);
	ArrayOfValues.Add(Value7);
	ArrayOfValues.Add(Value8);
	ArrayOfValues.Add(Value9);
	ArrayOfValues.Add(Value10);
	ArrayOfValues.Add(Value11);
	ArrayOfValues.Add(Value12);
	ArrayOfValues.Add(Value13);
	ArrayOfValues.Add(Value14);
	ArrayOfValues.Add(Value15);
	ArrayOfValues.Add(Value16);
	ArrayOfValues.Add(Value17);
	ArrayOfValues.Add(Value18);
	ArrayOfValues.Add(Value19);
	ArrayOfValues.Add(Value20);
	
	Result = Undefined;
	For Each FunctionValue In ArrayOfValues Do
		
		CountAttachments = 0;
		BypassedEverything = False;
		While Not BypassedEverything Do
			If TypeOf(FunctionValue) = Type("Array") Then
				If CountAttachments = FunctionValue.Count() Then
					BypassedEverything = True;
					Continue;
				EndIf;
				Value = FunctionValue[CountAttachments];
				CountAttachments = CountAttachments + 1;
			Else
				Value = FunctionValue;
				BypassedEverything = True;
			EndIf;
			
			If Not CheckFunctionArgument(Value) Then
				Continue;
			EndIf;
			
			If Result = Undefined Then
				Result = Value;
			Else
				Result = Result + Value;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// if there were no values for calculations, we return 0
	Return ?(Result = Undefined, 0, Result);
	
EndFunction

Function AVG(Value1, Value2 = Undefined, Value3 = Undefined, Value4 = Undefined,
	Value5 = Undefined, Value6 = Undefined, Value7 = Undefined, Value8 = Undefined,
	Value9 = Undefined, Value10 = Undefined, Value11 = Undefined, Value12 = Undefined,
	Value13 = Undefined, Value14 = Undefined, Value15 = Undefined, Value16 = Undefined,
	Value17 = Undefined, Value18 = Undefined, Value19 = Undefined, Value20 = Undefined) Export
	
	ArrayOfValues = New Array;
	ArrayOfValues.Add(Value1);
	ArrayOfValues.Add(Value2);
	ArrayOfValues.Add(Value3);
	ArrayOfValues.Add(Value4);
	ArrayOfValues.Add(Value5);
	ArrayOfValues.Add(Value6);
	ArrayOfValues.Add(Value7);
	ArrayOfValues.Add(Value8);
	ArrayOfValues.Add(Value9);
	ArrayOfValues.Add(Value10);
	ArrayOfValues.Add(Value11);
	ArrayOfValues.Add(Value12);
	ArrayOfValues.Add(Value13);
	ArrayOfValues.Add(Value14);
	ArrayOfValues.Add(Value15);
	ArrayOfValues.Add(Value16);
	ArrayOfValues.Add(Value17);
	ArrayOfValues.Add(Value18);
	ArrayOfValues.Add(Value19);
	ArrayOfValues.Add(Value20);
	
	Result = Undefined;
	Total = 0;
	For Each FunctionValue In ArrayOfValues Do
		
		CountAttachments = 0;
		BypassedEverything = False;
		While Not BypassedEverything Do
			If TypeOf(FunctionValue) = Type("Array") Then
				If CountAttachments = FunctionValue.Count() Then
					BypassedEverything = True;
					Continue;
				EndIf;
				Value = FunctionValue[CountAttachments];
				CountAttachments = CountAttachments + 1;
			Else
				Value = FunctionValue;
				BypassedEverything = True;
			EndIf;
			
			If Not CheckFunctionArgument(Value) Then
				Continue;
			EndIf;
			
			Total = Total + 1;
			If Result = Undefined Then
				Result = Value;
			Else
				Result = Result + Value;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If Total = 0 Then
		Return "#Val_";
	EndIf;
	
	Return Result / Total;
	
EndFunction

Function CalculateValueOfFirstAndSubsequentColumns(Value1, Value2 = Undefined, Value3 = Undefined, Value4 = Undefined,
	Value5 = Undefined, Value6 = Undefined, Value7 = Undefined, Value8 = Undefined,
	Value9 = Undefined, Value10 = Undefined, Value11 = Undefined, Value12 = Undefined,
	Value13 = Undefined, Value14 = Undefined, Value15 = Undefined, Value16 = Undefined,
	Value17 = Undefined, Value18 = Undefined, Value19 = Undefined, Value20 = Undefined) Export
	
	ArrayOfValues = New Array;
	ArrayOfValues.Add(Value1);
	ArrayOfValues.Add(Value2);
	ArrayOfValues.Add(Value3);
	ArrayOfValues.Add(Value4);
	ArrayOfValues.Add(Value5);
	ArrayOfValues.Add(Value6);
	ArrayOfValues.Add(Value7);
	ArrayOfValues.Add(Value8);
	ArrayOfValues.Add(Value9);
	ArrayOfValues.Add(Value10);
	ArrayOfValues.Add(Value11);
	ArrayOfValues.Add(Value12);
	ArrayOfValues.Add(Value13);
	ArrayOfValues.Add(Value14);
	ArrayOfValues.Add(Value15);
	ArrayOfValues.Add(Value16);
	ArrayOfValues.Add(Value17);
	ArrayOfValues.Add(Value18);
	ArrayOfValues.Add(Value19);
	ArrayOfValues.Add(Value20);
	
	Result = 0;
	FlagLeadingValue = True;
	LeadingValue = 0;
	
	For Each FunctionValue In ArrayOfValues Do
		
		CountAttachments = 0;
		BypassedEverything = False;
		While Not BypassedEverything Do
			If TypeOf(FunctionValue) = Type("Array") Then
				If CountAttachments = FunctionValue.Count() Then
					BypassedEverything = True;
					Continue;
				EndIf;
				Value = FunctionValue[CountAttachments];
				CountAttachments = CountAttachments + 1;
			Else
				Value = FunctionValue;
				BypassedEverything = True;
			EndIf;
			
			If FlagLeadingValue Then
				FlagLeadingValue = False;
				If CheckFunctionArgument(Value) Then
					LeadingValue = Value;
				EndIf;
				Continue;
			EndIf;
			
			If Not CheckFunctionArgument(Value) Then
				Continue;
			EndIf;
			
			Result = Result + Value;
			
		EndDo;
		
	EndDo;
	
	Return New Structure("Result, LeadingValue", Result, LeadingValue);
	
EndFunction

Function Deviation(Value1, Value2 = Undefined, Value3 = Undefined, Value4 = Undefined,
	Value5 = Undefined, Value6 = Undefined, Value7 = Undefined, Value8 = Undefined,
	Value9 = Undefined, Value10 = Undefined, Value11 = Undefined, Value12 = Undefined,
	Value13 = Undefined, Value14 = Undefined, Value15 = Undefined, Value16 = Undefined,
	Value17 = Undefined, Value18 = Undefined, Value19 = Undefined, Value20 = Undefined) Export
	
	StructureOfValues = CalculateValueOfFirstAndSubsequentColumns(Value1, Value2, Value3, Value4,
		Value5, Value6, Value7, Value8,
		Value9, Value10, Value11, Value12,
		Value13, Value14, Value15, Value16,
		Value17, Value18, Value19, Value20);
	
	Result = StructureOfValues.Result;
	LeadingValue = StructureOfValues.LeadingValue;
	
	Return Result - LeadingValue;
	
EndFunction

Function VariancePercentage(Value1, Value2 = Undefined, Value3 = Undefined, Value4 = Undefined,
	Value5 = Undefined, Value6 = Undefined, Value7 = Undefined, Value8 = Undefined,
	Value9 = Undefined, Value10 = Undefined, Value11 = Undefined, Value12 = Undefined,
	Value13 = Undefined, Value14 = Undefined, Value15 = Undefined, Value16 = Undefined,
	Value17 = Undefined, Value18 = Undefined, Value19 = Undefined, Value20 = Undefined) Export
	
	StructureOfValues = CalculateValueOfFirstAndSubsequentColumns(Value1, Value2, Value3, Value4,
		Value5, Value6, Value7, Value8,
		Value9, Value10, Value11, Value12,
		Value13, Value14, Value15, Value16,
		Value17, Value18, Value19, Value20);
	
	Result = StructureOfValues.Result;
	LeadingValue = StructureOfValues.LeadingValue;
	
	If Result = 0 And LeadingValue = 0 Then
		Return 0;
	ElsIf LeadingValue = 0 Then
		Return 100;
	EndIf;
	
	Return Round(100 * (Result - LeadingValue) / LeadingValue, 2)
	
EndFunction

Function ProgressPercent(Value1, Value2 = Undefined, Value3 = Undefined, Value4 = Undefined,
	Value5 = Undefined, Value6 = Undefined, Value7 = Undefined, Value8 = Undefined,
	Value9 = Undefined, Value10 = Undefined, Value11 = Undefined, Value12 = Undefined,
	Value13 = Undefined, Value14 = Undefined, Value15 = Undefined, Value16 = Undefined,
	Value17 = Undefined, Value18 = Undefined, Value19 = Undefined, Value20 = Undefined) Export
	
	StructureOfValues = CalculateValueOfFirstAndSubsequentColumns(Value1, Value2, Value3, Value4,
		Value5, Value6, Value7, Value8,
		Value9, Value10, Value11, Value12,
		Value13, Value14, Value15, Value16,
		Value17, Value18, Value19, Value20);
	
	Result = StructureOfValues.Result;
	LeadingValue = StructureOfValues.LeadingValue;
	
	If LeadingValue = 0 Then
		Return 0;
	EndIf;
	
	Return Round(100 * Result / LeadingValue, 2)
	
EndFunction

Function RoundOff(Value, NumberOfCharacters_) Export
	
	Return Round(Value, NumberOfCharacters_)
	
EndFunction

// LongDesc
// 
// Parameters:
// 	CellData_ - See CellData_
// 	CellParameters - ValueTable -
// 	PeriodParameters_1 - Structure -
// 	Prefix - String -
// 	Postfix - String -
// 	DataString1 - ValueTableRow - Cell Data String:
// 	 *String - CatalogRef.FinancialReportItems - Budget line.
// 	 *Column - CatalogRef.FinancialReportItems - Column of the budget.
// 	 *MainItem - Boolean - Flag of an element that is directly output to a table document.
// 	CalculationLog - Array of Structure -
// 	CacheOfBudgetItemDetails - See BudgetReportingCacheCalculationServer.CacheOfBudgetItemDetails
// 	OperandName - String -
// 	DimensionsNames - String - LongDesc
// Returns:
// 	Number, Undefined, Arbitrary - LongDesc
Function Total(CellData_, CellParameters, PeriodParameters_1, Prefix,
				Postfix, DataString1, CalculationLog, CacheOfBudgetItemDetails = Undefined, OperandName, DimensionsNames = "") Export
	
	CellParameters_ = CellParameters.Find(DataString1.RowIndex, "RowIndex");
	ArrayOfValues = New Array;
	
	ArrayOfCommonDimensions = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Upper(CellParameters_.GeneralMeasurements));
	ArrayOfUncountable  = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Upper(DimensionsNames),,True, True);
	ArrayOfCommonDimensions = CommonClientServer.ArraysDifference(ArrayOfCommonDimensions, ArrayOfUncountable);
	GeneralMeasurements = StrConcat(ArrayOfCommonDimensions, ",");
	
	// Indicators and articles
	TheStructureOfTheSearch = New Structure(GeneralMeasurements);
	FillPropertyValues(TheStructureOfTheSearch, DataString1);
	TheStructureOfTheSearch.Insert("String", DataString1.String);
	TheStructureOfTheSearch.Insert("Column", DataString1.Column);
	TheStructureOfTheSearch.Insert("MainItem", False);
	
	FoundRows = CellData_.FindRows(TheStructureOfTheSearch);
	
	For Each FoundRow In FoundRows Do
		
		If FoundRow.OperandType = Enums.FinancialReportItemKinds.TableCell Then
			Continue; //the cells are processed separately
		EndIf;
		
		CellParameters_ = CellParameters.Find(FoundRow.RowIndex, "RowIndex");
		
		If Upper(CellParameters_.OperandName) <> Upper(OperandName) Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(CellParameters_.OperandName) Then
			Raise NStr("vi = 'Đã xảy ra lỗi khi tạo báo cáo: Toán hạng công thức không chính xác';
						|ru = 'Ошибка формирования отчета: Неверный операнд формулы';
						|en = 'An error occurred while generating the report: Incorrect formula operand'; fa = 'An error occurred while generating the report: Incorrect formula operand';
						|it = 'Errore nella creazione del rapporto: Operando della formula incorretto';
						|pl = 'Błąd utworzenia raportu: Nieprawidłowy operand formuły';
						|tr = 'Raporun oluşturulmasında hata: Geçersiz formül işleneni'");
		EndIf;
		
		If ValueIsFilled(DataString1.NonFinancialItem) Then
			LinkPrefix = Prefix;
			PostFixLinks = Postfix;
			
			// 
			// Only quantity or sum can be selected in the operands of the derived exponent.
		ElsIf CellParameters_.FlagCount Then
			LinkPrefix = "Count";
			PostFixLinks = "";
		Else
			LinkPrefix = "Sum";
			PostFixLinks = Postfix;
		EndIf;
		
		CalculationParameters = New Structure;
		CalculationParameters.Insert("DataString1", FoundRow);
		CalculationParameters.Insert("Prefix", LinkPrefix);
		CalculationParameters.Insert("Postfix", PostFixLinks);
		CalculationParameters.Insert("CalculatingChanges", False);
		CalculationParameters.Insert("CacheOfBudgetItemDetails", CacheOfBudgetItemDetails);
		Value = GetOperandValue(CellData_, CellParameters, PeriodParameters_1, CalculationParameters,
			FoundRow.OperandType);
		
		If CalculationLog <> Undefined Then
			
			ValueForLog = New Structure();
			ValueForLog.Insert("IndicatorName", "Sum");
			ValueForLog.Insert("ItemKind", FoundRow.OperandType);
			ValueForLog.Insert("OperandName", StrReplace(CellParameters_.OperandName, "_", " "));
			ValueForLog.Insert("StringBase", CellData_.IndexOf(FoundRow));
			ValueForLog.Insert("Value", Value);
			CalculationLog.Add(ValueForLog);
			
		EndIf;
		
		ArrayOfValues.Add(Value);
		
	EndDo;
	
	If Not ArrayOfValues.Count() Then
		If CalculationLog <> Undefined Then
				
			ValueForLog = New Structure();
			ValueForLog.Insert("IndicatorName", "Sum");
			ValueForLog.Insert("ItemKind", "");
			ValueForLog.Insert("OperandName", CellParameters_.OperandName);
			ValueForLog.Insert("StringBase", -1);
			ValueForLog.Insert("Value", 0);
			CalculationLog.Add(ValueForLog);
			
		EndIf;
	EndIf;
	
	Return Sum(ArrayOfValues);
	
EndFunction

Function DateDiff(PeriodParameters_1, BeginOfPeriod, EndOfPeriod, Periodicity) Export
	
	If Not ValueIsFilled(BeginOfPeriod) Then
		Return "#Val_";
	EndIf;
	
	If Not ValueIsFilled(EndOfPeriod) Then
		Return "#Val_";
	EndIf;
	
	If Not ValueIsFilled(Periodicity) Then
		Return "#Val_";
	EndIf;
	
	CacheForAddingPeriods = PeriodParameters_1.CacheForAddingPeriods;
	CacheOfDateDifferences = PeriodParameters_1.CacheOfDateDifferences;
	
	KeyDifferences = New Structure("BeginOfPeriod, EndOfPeriod, Periodicity", BeginOfPeriod, EndOfPeriod, Periodicity);
	FoundRows = CacheOfDateDifferences.FindRows(KeyDifferences);
	If FoundRows.Count() Then
		Return FoundRows[0].TotalPeriods;
	EndIf;
	
	TotalPeriods = 0;
	CurEndOfPeriod = BeginOfPeriod;
	Try
		IntervalPeriodicity = Enums.Periodicity[Periodicity];
	Except
		Return "#Val_";
	EndTry;
	
	While CurEndOfPeriod <= EndOfPeriod Do
		CurEndOfPeriod = WorkingWithClientServerPeriods.AddInterval(CurEndOfPeriod, IntervalPeriodicity, 1, CacheForAddingPeriods);
		TotalPeriods = TotalPeriods + 1;
	EndDo;
	
	NewCacheEntry = CacheOfDateDifferences.Add();
	NewCacheEntry.BeginOfPeriod = BeginOfPeriod;
	NewCacheEntry.EndOfPeriod = EndOfPeriod;
	NewCacheEntry.Periodicity = Periodicity;
	NewCacheEntry.TotalPeriods = TotalPeriods;
	
	Return TotalPeriods;
	
EndFunction

Function CalculateFormulaInSafeMode(Val Formula, Val ArrayOfValues, Val AdditionalParameters = Undefined)
	
	Parameters = New Structure;
	Parameters.Insert("ArrayOfValues", ArrayOfValues);
	If Not AdditionalParameters = Undefined And TypeOf(AdditionalParameters) = Type("Structure") Then
		For Each KeyValue In AdditionalParameters Do
			Parameters.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	Formula = Upper(Formula);
	SearchByExpression = True;
	
	For Each KeyValue In Parameters Do
		If SearchByExpression Then
			If KeyValue.Key = "ArrayOfValues" Then
				Expression = StrFindByRegularExpression(Formula, "^" + KeyValue.Key + "\[\d+\]$", , , ,
					True).Value;
			Else
				Expression = StrFindByRegularExpression(Formula, "^" + KeyValue.Key + "$", , , ,
					True).Value;
			EndIf;
			If Not IsBlankString(Expression) Then
				If KeyValue.Key = "ArrayOfValues" Then
					IndexExpression = Number(StrFindByRegularExpression(Expression, "\d+").Value);
					Return ArrayOfValues[IndexExpression];
				Else
					Return Parameters[Expression];
				EndIf;
			Else
				LengthOfFormula = StrLen(Formula);
				Formula = StrReplace(Formula, Upper(KeyValue.Key), "Parameters." + KeyValue.Key);
				If LengthOfFormula <> StrLen(Formula) Then
					SearchByExpression = False;
				EndIf;
			EndIf;
		Else
			Formula = StrReplace(Formula, Upper(KeyValue.Key), "Parameters." + KeyValue.Key);
		EndIf;
	EndDo;
	
	CommonModuleName = "BudgetReportingDisplayServer";
	FormulaFunctions = New Structure();
	FormulaFunctions.Insert("CheckFunctionArgument", CommonModuleName + "." + "CheckFunctionArgument");
	FormulaFunctions.Insert("Max", CommonModuleName + "." + "Maximum");
	FormulaFunctions.Insert("Min", CommonModuleName + "." + "Minimum");
	FormulaFunctions.Insert("Sum", CommonModuleName + "." + "Sum");
	FormulaFunctions.Insert("AVG", CommonModuleName + "." + "AVG");
	FormulaFunctions.Insert("CalculateValueOfFirstAndSubsequentColumns", CommonModuleName + "." + "CalculateValueOfFirstAndSubsequentColumns");
	FormulaFunctions.Insert("Deviation", CommonModuleName + "." + "Deviation");
	FormulaFunctions.Insert("VariancePercentage", CommonModuleName + "." + "VariancePercentage");
	FormulaFunctions.Insert("ProgressPercent", CommonModuleName + "." + "ProgressPercent");
	FormulaFunctions.Insert("RoundOff", CommonModuleName + "." + "RoundOff");
	FormulaFunctions.Insert("Total", CommonModuleName + "." + "Total");
	FormulaFunctions.Insert("DateDiff", CommonModuleName + "." + "DateDiff");
	
	SearchByExpression = True;
	
	For Each KeyValue In FormulaFunctions Do
		If SearchByExpression Then
			Expression = StrFindByRegularExpression(Formula, "^" + KeyValue.Key + "\(Parameters\.\w+\)$", , , ,
				True).Value;
			If Not IsBlankString(Expression) Then
				ParameterName = StrReplace(StrFindByRegularExpression(Expression, "Parameters\.\w+").Value,
					"Parameters.", "");
				If KeyValue.Key = "Maximum" Then
					Return Maximum(Parameters[ParameterName]);
				ElsIf KeyValue.Key = "Minimum" Then
					Return Minimum(Parameters[ParameterName]);
				ElsIf KeyValue.Key = "Sum" Then
					Return Sum(Parameters[ParameterName]);
				ElsIf KeyValue.Key = "AVG" Then
					Return AVG(Parameters[ParameterName]);
				ElsIf KeyValue.Key = "Deviation" Then
					Return Deviation(Parameters[ParameterName]);
				ElsIf KeyValue.Key = "VariancePercentage" Then
					Return VariancePercentage(Parameters[ParameterName]);
				ElsIf KeyValue.Key = "ProgressPercent" Then
					Return ProgressPercent(Parameters[ParameterName]);
				Else
					Formula = StrReplace(Formula, Upper(KeyValue.Key) + "(", KeyValue.Value + "(");
					SearchByExpression = False;
				EndIf;
			Else
				LengthOfFormula = StrLen(Formula);
				Formula = StrReplace(Formula, Upper(KeyValue.Key) + "(", KeyValue.Value + "(");
				If LengthOfFormula <> StrLen(Formula) Then
					SearchByExpression = False;
				EndIf;
			EndIf;
		Else
			Formula = StrReplace(Formula, Upper(KeyValue.Key) + "(", KeyValue.Value + "(");
		EndIf;
	EndDo;
	
	Formula = StrReplace(Formula, """" + CommonModuleName + ".", """");
	If IsBlankString(Formula) Then
		CalculationResult = "#Val_";
	Else
		CalculationResult = Common.CalculateInSafeMode(Formula, Parameters);
	EndIf;
	
	Return CalculationResult;
	
EndFunction

#EndRegion

#Region OtherItems

// Returns whether the index exists in the value table.
// 
// Parameters:
// 	ValueTable - ValueTable - An arbitrary table of values that is checked for an index.
// 	IndexFields - String - Index fields in any order, separated by commas.
// Returns:
// 	Boolean - A sign of the existence of an index in a table of values
Function IndexExists(ValueTable, IndexFields)
	
	IndexExists = False;
	If ValueTable.Indexes.Count() > 0 Then
		FieldArray = StrSplit(StrReplace(IndexFields, " ", ""), ",", False);
		List = New ValueList;
		List.LoadValues(FieldArray);
		List.SortByValue();
		OrderedArray = List.UnloadValues();
		OrderedIndex = StrConcat(OrderedArray, ",");
		
		For Each TableIndex In ValueTable.Indexes Do
			FieldArray = StrSplit(StrReplace(TableIndex, " ", ""), ",", False);
			List = New ValueList;
			List.LoadValues(FieldArray);
			List.SortByValue();
			OrderedArray = List.UnloadValues();
			OrderedTableIndex = StrConcat(OrderedArray, ",");
			If OrderedIndex = OrderedTableIndex Then
				IndexExists = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return IndexExists;
	
EndFunction

Procedure ResetCalculationFlagForLinkedCells(CellData_, NewCellData, CellParameters, String, Column, RowsToRecalculate_)
	
	TheStructureOfTheSearch = New Structure("OperandString, OperandColumn_", String, Column);
	FoundRows = CellParameters.FindRows(TheStructureOfTheSearch);
	For Each ParametersString1 In FoundRows Do
		If ParametersString1.Processed Then
			Continue;
		EndIf;
		TheStructureOfTheSearch = New Structure("RowIndex", ParametersString1.RowIndex);
		CellDataRows = CellData_.FindRows(TheStructureOfTheSearch);
		For Each FoundRow In CellDataRows Do
			TheStructureOfTheSearch = New Structure("MainItem, String, Column", True, FoundRow.String, FoundRow.Column);
			RowsOfMainElement = CellData_.FindRows(TheStructureOfTheSearch);
			For Each StringMainElement In RowsOfMainElement Do
				RowIndex = CellData_.IndexOf(StringMainElement);
				NewCellData[RowIndex].CalculatedSum = False;
				NewCellData[RowIndex].CalculatedCount = False;
				NewCellData[RowIndex].CalculatedValue = False;
				RowsToRecalculate_.Insert(StringMainElement);
				ResetCalculationFlagForLinkedCells(CellData_, NewCellData, CellParameters,
					StringMainElement.String, StringMainElement.Column, RowsToRecalculate_);
			EndDo;
		EndDo;
		ParametersString1.Processed = True;
	EndDo;
	
EndProcedure

Procedure MoveRowOfCellsToCalculation(NewCellData, PreviousCellData, TheStructureOfTheSearch, RowsToRecalculate_)
	
	FoundRows = NewCellData.FindRows(TheStructureOfTheSearch);
	For Each FoundRow In FoundRows Do
		NewCellData.Delete(FoundRow);
	EndDo;
	FoundRows = PreviousCellData.FindRows(TheStructureOfTheSearch);
	For Each FoundRow In FoundRows Do
		RowsToRecalculate_.Insert(FoundRow);
	EndDo;
	
EndProcedure

Function ConvertDataParametersToPeriodData(ColumnStructureOfDataTable, DataParameters) Export
	
	Result = New Structure("ActualDataLimit, BeginOfPeriod, EndOfPeriod");
	FillPropertyValues(Result, DataParameters);
	Result.Insert("OrderedReportPeriodicities", New Array);
	
	OrderedPeriodicities = Enums.Periodicity.OrderedPeriodicities();
	For Each Periodicity In OrderedPeriodicities Do
		PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		If ColumnStructureOfDataTable.Periodicity_.Find(Periodicity) <> Undefined Then
			Result.OrderedReportPeriodicities.Add(PeriodName);
		EndIf;
	EndDo;
	
	Result.Insert("CacheForAddingPeriods", New Map);
	
	AddCache = New ValueTable;
	AddCache.Columns.Add("BeginOfPeriod", New TypeDescription("Date"));
	AddCache.Columns.Add("EndOfPeriod", New TypeDescription("Date"));
	AddCache.Columns.Add("Periodicity", New TypeDescription("String"));
	AddCache.Columns.Add("TotalPeriods", New TypeDescription("Number"));
	AddCache.Indexes.Add("BeginOfPeriod, EndOfPeriod, Periodicity");
	
	Result.Insert("CacheOfDateDifferences", AddCache);
	
	Return Result;
	
EndFunction

Function GetCacheOfUnitParameters(CellData_, CellParameters) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	CellData_.BudgetFlowItem,
	|	CellData_.BudgetBalanceItem,
	|	CellData_.NonFinancialItem,
	|	CellData_.String,
	|	CellData_.Column,
	|	CellData_.RowIndex AS RowIndex
	|INTO CellData_
	|FROM
	|	&CellData_ AS CellData_
	|
	|INDEX BY
	|	RowIndex
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CellParameters.RowIndex AS RowIndex,
	|	CellParameters.FlagCount,
	|	CellParameters.FlagValue
	|INTO CellParameters
	|FROM
	|	&CellParameters AS CellParameters
	|
	|INDEX BY
	|	RowIndex
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CellData_.BudgetFlowItem AS BudgetFlowItem,
	|	CellData_.BudgetBalanceItem,
	|	CellData_.NonFinancialItem,
	|	CellData_.String,
	|	CellData_.Column,
	|	CellParameters.FlagCount,
	|	CellParameters.FlagValue
	|INTO KeyIndicators
	|FROM
	|	CellData_ AS CellData_
	|		INNER JOIN CellParameters AS CellParameters
	|		ON CellData_.RowIndex = CellParameters.RowIndex
	|
	|INDEX BY
	|	BudgetFlowItem
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Catalog.Ref AS AccountingObject,
	|	KeyIndicators.String,
	|	KeyIndicators.Column,
	|	Catalog.DimensionUnitsOfMeasurement,
	|	Catalog.UnitOfMeasureIsDeterminedByDimension,
	|	CAST(Catalog.DimensionUnitsOfMeasurement.UnitOfMeasureFilling AS STRING(1000)) AS UnitOfMeasureFilling,
	|	PRESENTATION(Catalog.UnitOfMeasure) AS UnitOfMeasure
	|FROM
	|	Catalog.BudgetFlowItems AS Catalog
	|		INNER JOIN KeyIndicators AS KeyIndicators
	|		ON Catalog.Ref = KeyIndicators.BudgetFlowItem
	|			AND (KeyIndicators.BudgetBalanceItem = VALUE(Catalog.BudgetBalanceItems.EmptyRef))
	|WHERE
	|	Catalog.RecordByQuantity
	|	AND KeyIndicators.FlagCount
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Catalog.Ref,
	|	KeyIndicators.String,
	|	KeyIndicators.Column,
	|	Catalog.DimensionUnitsOfMeasurement,
	|	Catalog.UnitOfMeasureIsDeterminedByDimension,
	|	CAST(Catalog.DimensionUnitsOfMeasurement.UnitOfMeasureFilling AS STRING(1000)),
	|	PRESENTATION(Catalog.UnitOfMeasure)
	|FROM
	|	Catalog.BudgetBalanceItems AS Catalog
	|		INNER JOIN KeyIndicators AS KeyIndicators
	|		ON Catalog.Ref = KeyIndicators.BudgetBalanceItem
	|WHERE
	|	Catalog.RecordByQuantity
	|	AND KeyIndicators.FlagCount
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Catalog.Ref,
	|	KeyIndicators.String,
	|	KeyIndicators.Column,
	|	Catalog.DimensionUnitsOfMeasurement,
	|	Catalog.UnitOfMeasureIsDeterminedByDimension,
	|	CAST(Catalog.DimensionUnitsOfMeasurement.UnitOfMeasureFilling AS STRING(1000)),
	|	PRESENTATION(Catalog.UnitOfMeasure)
	|FROM
	|	Catalog.NonFinancialItemsOfBudgets AS Catalog
	|		INNER JOIN KeyIndicators AS KeyIndicators
	|		ON Catalog.Ref = KeyIndicators.NonFinancialItem
	|WHERE
	|	Catalog.IndicatorKind = VALUE(Enum.NonFinancialItemKinds.Quantitative)
	|	AND KeyIndicators.FlagValue";
	
	Query.SetParameter("CellData_", CellData_);
	Query.SetParameter("CellParameters", CellParameters);
	QuantitativeAccountingTable = Query.Execute().Unload();
	
	QuantitativeAccountingTable.Indexes.Add("String, AccountingObject, UnitOfMeasureIsDeterminedByDimension");
	QuantitativeAccountingTable.Indexes.Add("String, AccountingObject, UnitOfMeasureIsDeterminedByDimension, DimensionUnitsOfMeasurement");
	
	QuantitativeAccountingTable.Indexes.Add("Column, UnitOfMeasureIsDeterminedByDimension");
	QuantitativeAccountingTable.Indexes.Add("Column, UnitOfMeasureIsDeterminedByDimension, DimensionUnitsOfMeasurement");
	
	SetPrivilegedMode(False);
	
	Return QuantitativeAccountingTable;
	
EndFunction

Function GetCacheOfCurrencyParameters(CellData_, CellParameters, TableOfSubordinationOfElements) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	CellData_.BudgetFlowItem,
	|	CellData_.BudgetBalanceItem,
	|	CellData_.NonFinancialItem,
	|	CellData_.String,
	|	CellData_.Column,
	|	CellData_.RowIndex AS RowIndex
	|INTO CellData_
	|FROM
	|	&CellData_ AS CellData_
	|
	|INDEX BY
	|	RowIndex
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CellParameters.RowIndex AS RowIndex,
	|	CellParameters.FlagSum,
	|	CellParameters.FlagValue
	|INTO CellParameters
	|FROM
	|	&CellParameters AS CellParameters
	|
	|INDEX BY
	|	RowIndex
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfSubordinationOfElements.Ref,
	|	TableOfSubordinationOfElements.Parent
	|INTO TableOfSubordinationOfElements
	|FROM
	|	&TableOfSubordinationOfElements AS TableOfSubordinationOfElements
	|
	|INDEX BY
	|	TableOfSubordinationOfElements.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CellData_.BudgetFlowItem AS BudgetFlowItem,
	|	CellData_.BudgetBalanceItem,
	|	CellData_.NonFinancialItem,
	|	CellData_.String,
	|	CellData_.Column,
	|	CellParameters.FlagSum,
	|	CellParameters.FlagValue
	|INTO KeyIndicators
	|FROM
	|	CellData_ AS CellData_
	|		INNER JOIN CellParameters AS CellParameters
	|		ON CellData_.RowIndex = CellParameters.RowIndex
	|
	|INDEX BY
	|	BudgetFlowItem
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Catalog.Ref AS AccountingObject,
	|	KeyIndicators.String,
	|	KeyIndicators.Column,
	|	Catalog.DimensionCurrencies,
	|	Catalog.CurrencyIsDeterminedByDimension,
	|	CAST(Catalog.DimensionCurrencies.CurrencyFilling AS STRING(1000)) AS UnitOfMeasureFilling
	|INTO RowData_
	|FROM
	|	Catalog.BudgetFlowItems AS Catalog
	|		INNER JOIN KeyIndicators AS KeyIndicators
	|		ON Catalog.Ref = KeyIndicators.BudgetFlowItem
	|			AND (KeyIndicators.BudgetBalanceItem = VALUE(Catalog.BudgetBalanceItems.EmptyRef))
	|WHERE
	|	Catalog.RecordByCurrency
	|	AND Catalog.CurrencyIsDeterminedByDimension
	|	AND KeyIndicators.FlagSum
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Catalog.Ref,
	|	KeyIndicators.String,
	|	KeyIndicators.Column,
	|	Catalog.DimensionCurrencies,
	|	Catalog.CurrencyIsDeterminedByDimension,
	|	CAST(Catalog.DimensionCurrencies.CurrencyFilling AS STRING(1000))
	|FROM
	|	Catalog.BudgetBalanceItems AS Catalog
	|		INNER JOIN KeyIndicators AS KeyIndicators
	|		ON Catalog.Ref = KeyIndicators.BudgetBalanceItem
	|WHERE
	|	Catalog.RecordByCurrency
	|	AND Catalog.CurrencyIsDeterminedByDimension
	|	AND KeyIndicators.FlagSum
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Catalog.Ref,
	|	KeyIndicators.String,
	|	KeyIndicators.Column,
	|	Catalog.DimensionCurrencies,
	|	Catalog.CurrencyIsDeterminedByDimension,
	|	CAST(Catalog.DimensionCurrencies.CurrencyFilling AS STRING(1000))
	|FROM
	|	Catalog.NonFinancialItemsOfBudgets AS Catalog
	|		INNER JOIN KeyIndicators AS KeyIndicators
	|		ON Catalog.Ref = KeyIndicators.NonFinancialItem
	|WHERE
	|	Catalog.IndicatorKind = VALUE(Enum.NonFinancialItemKinds.Cash_)
	|	AND Catalog.CurrencyIsDeterminedByDimension
	|	AND KeyIndicators.FlagValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSubordinationOfElements.Ref,
	|	TableOfSubordinationOfElements.Parent
	|INTO RowParents
	|FROM
	|	TableOfSubordinationOfElements AS TableOfSubordinationOfElements
	|		LEFT JOIN RowData_ AS RowData_
	|		ON TableOfSubordinationOfElements.Parent = RowData_.String
	|WHERE
	|	RowData_.String IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RowData_.AccountingObject,
	|	RowData_.String,
	|	RowData_.Column,
	|	RowData_.DimensionCurrencies,
	|	RowData_.CurrencyIsDeterminedByDimension,
	|	RowData_.UnitOfMeasureFilling
	|FROM
	|	RowData_ AS RowData_
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED,
	|	RowParents.Parent,
	|	RowData_.Column,
	|	MAX(RowData_.DimensionCurrencies),
	|	MAX(RowData_.CurrencyIsDeterminedByDimension),
	|	MAX(RowData_.UnitOfMeasureFilling)
	|FROM
	|	RowData_ AS RowData_
	|		INNER JOIN RowParents AS RowParents
	|		ON RowData_.String = RowParents.Ref
	|
	|GROUP BY
	|	RowData_.Column,
	|	RowParents.Parent
	|
	|HAVING
	|	COUNT(DISTINCT RowData_.DimensionCurrencies) = 1 AND
	|	COUNT(DISTINCT RowData_.CurrencyIsDeterminedByDimension) = 1";
	
	Query.SetParameter("CellData_", CellData_);
	Query.SetParameter("CellParameters", CellParameters);
	Query.SetParameter("TableOfSubordinationOfElements", TableOfSubordinationOfElements);
	
	QuantitativeAccountingTable = Query.Execute().Unload();
	
	QuantitativeAccountingTable.Indexes.Add("String, Column, CurrencyIsDeterminedByDimension");
	
	SetPrivilegedMode(False);
	
	Return QuantitativeAccountingTable;
	
EndFunction

// Returns a list of subordinate elements.
// 
// Parameters:
// 	ReportItem - CatalogRef.FinancialReportItems - Report item.
// 	TableOfSubordinates - ValueTable - Table of subordinate elements:
// 	 *Parent - CatalogRef.FinancialReportItems - Report item.
// 	 *Ref - CatalogRef.FinancialReportItems - subordinate element of the report.
// Returns:
// 	ValueList of CatalogRef.FinancialReportItems - A list of subordinate report items.
//
Function ListOfSubordinateElements(ReportItem, TableOfSubordinates) Export
	
	ValueList = New ValueList;
	FoundRows = TableOfSubordinates.FindRows(New Structure("Parent", ReportItem));
	For Each StringOfElements In FoundRows Do
		ValueList.Add(StringOfElements.Ref);
	EndDo;
	ValueList.Add(ReportItem);
	Return ValueList;
	
EndFunction

Function GetSubstitutionValuesForDataParameters(GenerationMode, DataParameters)
	
	SetPrivilegedMode(True);
	
	SubstitutionVariables = BudgetReportingClientServer.BudgetReportVariables();
	
	DocumentAttributes = Undefined;
	If DataParameters.Property("Document") Then
		DocumentAttributes = Common.ObjectAttributesValues(DataParameters.Document, "Status, EmployeeResponsible");
	EndIf;
	
	SubstitutionValues = New ValueTable;
	SubstitutionValues.Columns.Add("WhatToChange");
	SubstitutionValues.Columns.Add("WhatReplaceWith");
	
	NewRow = SubstitutionValues.Add();
	NewRow.WhatToChange = SubstitutionVariables.ReportKind.Name;
	NewRow.WhatReplaceWith = DataParameters.BudgetProfile;
	
	NewRow = SubstitutionValues.Add();
	NewRow.WhatToChange = SubstitutionVariables.CurrentDateAndTime.Name;
	NewRow.WhatReplaceWith = Format(CurrentSessionDate(), "DLF=DT");
	
	NewRow = SubstitutionValues.Add();
	NewRow.WhatToChange = SubstitutionVariables.ReportingPeriod.Name;
	NewRow.WhatReplaceWith = TMReportFunctionsClientServer.GetPeriodPresentation(
		DataParameters.BeginOfPeriod,
		DataParameters.EndOfPeriod);
	
	NewRow = SubstitutionValues.Add();
	NewRow.WhatToChange = SubstitutionVariables.EndDateOfReportPeriod.Name;
	NewRow.WhatReplaceWith = Format(DataParameters.EndOfPeriod, "DLF=DD");
	
	NewRow = SubstitutionValues.Add();
	NewRow.WhatToChange = SubstitutionVariables.LimitOfActualData.Name;
	NewRow.WhatReplaceWith = Format(DataParameters.ActualDataLimit, "DLF=DD");
	
	NewRow = SubstitutionValues.Add();
	NewRow.WhatToChange = SubstitutionVariables.Organization.Name;
	DataParameters.Property("Organization", NewRow.WhatReplaceWith);
	
	NewRow = SubstitutionValues.Add();
	NewRow.WhatToChange = SubstitutionVariables.Department.Name;
	DataParameters.Property("Department", NewRow.WhatReplaceWith);
	
	NewRow = SubstitutionValues.Add();
	NewRow.WhatToChange = SubstitutionVariables.DocumentStatus.Name;
	If DataParameters.Property("Document") Then
		NewRow.WhatReplaceWith = DocumentAttributes.Status;
	Else
		NewRow.WhatReplaceWith = String(DataParameters.Status);
	EndIf;
	
	NewRow = SubstitutionValues.Add();
	NewRow.WhatToChange = SubstitutionVariables.Scenario.Name;
	DataParameters.Property("Scenario", NewRow.WhatReplaceWith);
		
	NewRow = SubstitutionValues.Add();
	NewRow.WhatToChange = SubstitutionVariables.EmployeeResponsible.Name;
	If DataParameters.Property("Document") Then
		NewRow.WhatReplaceWith = DocumentAttributes.EmployeeResponsible;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("Ref", ?(DataParameters.Property("Document"), DataParameters.Document, Undefined));
	Query.SetParameter("BudgetProfile", DataParameters.BudgetProfile);
	Query.Text = "SELECT TOP 1
	|	BudgetTask.BudgetingStep AS Ref
	|FROM
	|	Task.BudgetTask AS BudgetTask
	|WHERE
	|	CAST(BudgetTask.DocumentsList.Document AS Document.BudgetEntryForm) = &Ref
	|	AND NOT BudgetTask.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BudgetingSteps.Ref,
	|	BudgetingSteps.SettingOfAction,
	|	BudgetingSteps.EmployeeResponsible.Presentation AS EmployeeResponsible
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Action = &ActionType
	|	AND NOT BudgetingSteps.DeletionMark";
		
	Query.SetParameter("ActionType", Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets);
	
	QueryResult = Query.ExecuteBatch();
	QueryResult0 = QueryResult[0]; // QueryResult
	
	StepOfStagesOfPreparationOfBudgets = QueryResult0.Select();
	
	NewRow = SubstitutionValues.Add();
	NewRow.WhatToChange = SubstitutionVariables.Approving.Name;
	If StepOfStagesOfPreparationOfBudgets.Next() Then
		QueryResult1 = QueryResult[1]; // QueryResult - 
		AllStepsOfStagesOfPreparationOfBudgets = QueryResult1.Select();
		While AllStepsOfStagesOfPreparationOfBudgets.Next() Do
			SettingOfAction = AllStepsOfStagesOfPreparationOfBudgets.SettingOfAction; // ValueStorage
			Settings = SettingOfAction.Get();
			SettingsString = Settings.Find("ApprovedStagesOfBudgetPreparation", "Name");
			If SettingsString <> Undefined Then
				ApprovedSteps = SettingsString.Value;
				If ApprovedSteps.FindByValue(StepOfStagesOfPreparationOfBudgets.Ref) <> Undefined Then
					NewRow.WhatReplaceWith = AllStepsOfStagesOfPreparationOfBudgets.EmployeeResponsible;
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Query.Text = 
	"SELECT
	|	BudgetProfilesHeaderDimensions.DimensionKind AS Ref,
	|	BudgetProfilesHeaderDimensions.LineNumber AS LineNumber,
	|	BudgetProfilesHeaderDimensions.DimensionKind.Id AS Id,
	|	BudgetProfilesHeaderDimensions.DimensionKind.Presentation AS Presentation
	|FROM
	|	Catalog.BudgetProfiles.HeaderDimensions AS BudgetProfilesHeaderDimensions
	|WHERE
	|	BudgetProfilesHeaderDimensions.Ref = &BudgetProfile";
	
	SamplingAnalystPresentations = Query.Execute().Select();
	While SamplingAnalystPresentations.Next() Do
		NewRow = SubstitutionValues.Add();
		NewRow.WhatToChange = "[" + SamplingAnalystPresentations.Id + "]";
		If DataParameters.Property("Document") And ValueIsFilled(DataParameters.Document) Then
			NewRow.WhatReplaceWith = DataParameters.Document["Dimension"+SamplingAnalystPresentations.LineNumber];
		Else
			NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(SamplingAnalystPresentations.Ref);
			DataParameters.Property(NameOfAnalytics, NewRow.WhatReplaceWith);
		EndIf;
	EndDo;
	
	Return SubstitutionValues;
	
EndFunction

Function GetNoteOutputParameters(ColumnStructureOfDataTable, CellData_, OutputTree)
	
	Result = New Structure;
	
	For Each CurRow In CellData_ Do
		If Not IsBlankString(CurRow.Note) Then
			Result.Insert("DisplayNotes_", True);
			Break;
		EndIf
	EndDo;
	
	Result.Insert("DisplayTableNumbers", 
		OutputTree.Rows.FindRows(New Structure("DimensionName","Table")).Count() > 1);
	
	ColumnsList = "BudgetFlowItem";
	For Each Periodicity In ColumnStructureOfDataTable.Periodicity_ Do
		PeriodAsString = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		ColumnsList = ColumnsList + "," + PeriodAsString;
	EndDo;
	
	For Each Dimension In ColumnStructureOfDataTable.Dimensions Do
		ColumnsList = ColumnsList + "," + Dimension;
	EndDo;
	
	For Each DimensionKind In ColumnStructureOfDataTable.DimensionKinds Do
		ColumnsList = ColumnsList + "," + FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
	EndDo;
	ColumnsList = ColumnsList + ",Count,Sum,SumCurr,Note";
	
	Result.Insert("Remarks", NewNoteStructure(CellData_, ColumnsList));
	
	Return Result;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	CellData_ - See CellData_
// 	ColumnsList - String -
// 	
// Returns:
// 	Structure - contains the specified list of columns from the data cell table, as well as:
// 	* TableNumber    - Number -
// 	* NoteNumber - Number -
// 	* DataTable   - See CellData_
// 	* DataTable   - ValueTable - Contains:
// 		** TableNumber    - Number -
// 		** NoteNumber - Number -
//
Function NewNoteStructure(CellData_, ColumnsList)
	
	DataTable = CellData_.CopyColumns(ColumnsList); // Tables of assignments, see data cells
	ColumnsOfDataTable_ = DataTable.Columns; // ValueTableColumnCollection
	ColumnsOfDataTable_.Add("TableNumber",New TypeDescription("Number",,,New NumberQualifiers(3)));
	ColumnsOfDataTable_.Add("NoteNumber",New TypeDescription("Number",,,New NumberQualifiers(5)));
	
	Result = New Structure("TableNumber, NoteNumber, DataTable", 0, 0, DataTable);
	
	Return Result;
	
EndFunction

// Checks the budgeting formula.
// 
// Parameters:
// 	Formula - String - formula.
// 	Operands - ValueTable - Table of operands from the form of the budget report element:
// 	 *Id - String - ID of the operand.
// 	Cancel - Boolean - Flag for failure due to an error.
Procedure CheckFormula(Val Formula, Operands, Cancel) Export
	Var BeginningOfFormula, EndOfFormula;
	
	LimitingLengthOfFormula = Common.ObjectAttributeValue(
		ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.Formula, "ValueType").StringQualifiers.Length;
	If StrLen(Formula) > LimitingLengthOfFormula Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Vượt quá độ dài công thức tối đa, đã nhập %1 ký tự, cho phép %2 ký tự.';
				|ru = 'Превышена максимальная длина формулы, введено %1 символов, доступно %2 символов.';
				|en = 'Maximum formula length exceeded: %1 characters entered, %2 characters available.'; fa = 'Maximum formula length exceeded: %1 characters entered, %2 characters available.';
				|it = 'Superata la lunghezza massima della formula, immessi %1 caratteri, disponibili %2 caratteri.';
				|pl = 'Przekroczono maksymalną długość formuły, wprowadzono %1 symboli, jest dostępne %2 symboli.';
				|tr = 'Aşılan maksimum formül uzunluğu, %1 sembolünde tanımlandı, %2 sembolü mevcut.'"),
			StrLen(Formula),
			LimitingLengthOfFormula);
		Common.MessageToUser(MessageText);
	EndIf;
	
	ArrayOfValues = New Array;
	RNG = New RandomNumberGenerator(CurrentSessionDate() - Date(1, 1, 1));
	For Each Operand In Operands Do
		
		If Not ValueIsFilled(Operand.Id) Then
			MessageText = NStr("vi = 'Đã xảy ra lỗi khi tạo báo cáo: Toán hạng công thức không chính xác';
								|ru = 'Ошибка формирования отчета: Неверный операнд формулы';
								|en = 'An error occurred while generating the report: Incorrect formula operand'; fa = 'An error occurred while generating the report: Incorrect formula operand';
								|it = 'Errore nella creazione del rapporto: Operando della formula incorretto';
								|pl = 'Błąd utworzenia raportu: Nieprawidłowy operand formuły';
								|tr = 'Raporun oluşturulmasında hata: Geçersiz formül işleneni'");
			Common.MessageToUser(MessageText);
		ElsIf StrFind(Formula, "["+Operand.Id+"]") = 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Toán tử %1 không có trong công thức.';
					|ru = 'Операнд %1 отсутствует в формуле.';
					|en = 'The %1 operand is missing in the formula.'; fa = 'The %1 operand is missing in the formula.';
					|it = 'Операнд %1 отсутствует в формуле.';
					|pl = 'The %1 operand is missing in the formula.';
					|tr = 'Formülde %1 işleneni eksik.'"), Operand.Id + " " + Operand.NameForPrinting);
			Common.MessageToUser(MessageText);
		EndIf;
		
		Value = RNG.RandomNumber(1000, 10000000);
		ArrayOfValues.Add(Value);
		
		While StrFind(Upper(Formula), "TOTAL(") Do
			PartOfFormula = BudgetReportingCacheCalculationServer.PartOfFormulaWithTotalAndOperand(Formula, "[" + Operand.Id + "]", BeginningOfFormula, EndOfFormula);
			If PartOfFormula = Undefined Then
				// the operand with the total function is not used
				Break;
			EndIf;
			EndOfFormula = BudgetReportingCacheCalculationServer.EndOfFormula(Formula, EndOfFormula) + ")";
			Formula = StrReplace(Formula, PartOfFormula + EndOfFormula, "ArrayOfValues[" + ArrayOfValues.UBound() + "]");
			Value = RNG.RandomNumber(1000, 10000000);
			ArrayOfValues.Add(Value);
		EndDo;
		
		Formula = StrReplace(Formula, "[" + Operand.Id + "]", "ArrayOfValues[" + ArrayOfValues.UBound() + "]");
		
	EndDo;
	
	If StrFind(Upper(Formula), "DATEDIFF(") Then
		BudgetReportingCacheCalculationServer.AddTechnicalInformationToDateDifferenceFunction(Formula);
		
		Formula = BudgetReportingCacheCalculationServer.RowReplaceCaseInsensitive(Formula, "DateDiff(PeriodParameters_1", "DateDiff(Parameters");	
	EndIf;
	
	CurrentSessionDate = CurrentSessionDate();
	BeginOfPeriod = CurrentSessionDate;
	EndOfPeriod = CurrentSessionDate;
	PeriodOfGrouping = CurrentSessionDate;
	ActualDataLimit = CurrentSessionDate;
	
	CacheTable = New ValueTable;
	CacheTable.Columns.Add("BeginOfPeriod");
	CacheTable.Columns.Add("EndOfPeriod");
	CacheTable.Columns.Add("Periodicity");
	CacheTable.Columns.Add("TotalPeriods");
	
	PeriodParameters_1 = New Structure("CacheForAddingPeriods, CacheOfDateDifferences", New Map, CacheTable);
	PeriodParameters_1.Insert("BeginOfPeriod", BeginOfPeriod);
	PeriodParameters_1.Insert("EndOfPeriod", EndOfPeriod);
	PeriodParameters_1.Insert("ActualDataLimit", ActualDataLimit);
	PeriodParameters_1.Insert("PeriodOfGrouping", PeriodOfGrouping);
	
	Try
		CalculateFormulaInSafeMode(Formula, ArrayOfValues, PeriodParameters_1);
	Except
		MessageText = NStr("vi = 'Trong công thức tìm thấy lỗi';
							|ru = 'В формуле обнаружены ошибки';
							|en = 'Errors were found in the formula.'; fa = 'Errors were found in the formula.';
							|it = 'Nella formula sono stati rilevati errori';
							|pl = 'W formule zostały wykryte błędy';
							|tr = 'Hatalar bulundu formülünde'");
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
	EndTry;
	
EndProcedure

Function AddRowOfCellData(CellData_, ReportCell, DimensionValues, ReportColumn) Export
	
	NewRow = CellData_.Add();
	FillPropertyValues(NewRow, ReportCell);
	FillPropertyValues(NewRow, DimensionValues);
	
	NewRow.CalculatedSum = False;
	NewRow.CalculatedSumCurr = False;
	NewRow.CalculatedCount = False;
	NewRow.CalculatedValue = False;
	
	FilterCells = "String,";
	If ValueIsFilled(ReportColumn) Then
		FilterCells = FilterCells + "Column,";
	EndIf;
	FilterCells = FilterCells + "MainItem";
	NewRow.FilterCells = SelectingCellBySearchStructure(DimensionValues, FilterCells);
	
	Return NewRow;
	
EndFunction

// Returns the area name structure - the area of the table document for displaying the budget
// in a table document.
// 
// Parameters:
// 	OutputParameters - Structure - Structure Of Output Parameters:
// 	 *DisplayNotes_ - Boolean - Flag for displaying notes.
// 	 *DisplayTableNumbers - Boolean - Flag for displaying table numbers.
// Returns:
// 	Structure - Budget areas by area names:
// * TableNumber - SpreadsheetDocument - Budget Template Area.
// * ColumnNumberingStartOfTableRowNumbering - SpreadsheetDocument - Budget Template Area.
// * HeaderStartOfTableRowNumbering - SpreadsheetDocument - Budget Template Area.
// * IsBlankString - SpreadsheetDocument - Budget Template Area.
// * TableHeading - SpreadsheetDocument - Budget Template Area.
// * Text - SpreadsheetDocument - Budget Template Area.
// * ReportHeader - SpreadsheetDocument - Budget Template Area.
// * HeaderStartOfTable - SpreadsheetDocument - Budget Template Area.
// * HeaderAdditionalSection - SpreadsheetDocument - Budget Template Area.
// * HeaderColumnsGroup1WithNote - SpreadsheetDocument - Budget Template Area.
// * HeaderColumnsGroup2WithNote - SpreadsheetDocument - Budget Template Area.
// * HeaderColumnsGroup3WithNote - SpreadsheetDocument - Budget Template Area.
// * HeaderColumnsGroup1 - SpreadsheetDocument - Budget Template Area.
// * HeaderColumnsGroup2 - SpreadsheetDocument - Budget Template Area.
// * HeaderColumnsGroup3 - SpreadsheetDocument - Budget Template Area.
// * ColumnNumberingStartOfTable - SpreadsheetDocument - Budget Template Area.
// * ColumnNumberingAdditionalSection - SpreadsheetDocument - Budget Template Area.
// * ColumnNumberingHeaderColumnsGroup1WithNote - SpreadsheetDocument - Budget Template Area.
// * ColumnNumberingHeaderColumnsGroup2WithNote - SpreadsheetDocument - Budget Template Area.
// * ColumnNumberingHeaderColumnsGroup3WithNote - SpreadsheetDocument - Budget Template Area.
// * ColumnNumberingGroupingOfColumns1 - SpreadsheetDocument - Budget Template Area.
// * ColumnNumberingGroupingOfColumns2 - SpreadsheetDocument - Budget Template Area.
// * ColumnNumberingGroupingOfColumns3 - SpreadsheetDocument - Budget Template Area.
//
Function StructureOfTemplateAreas(OutputParameters) Export
	
	AreasNamesMap = New Map;
	
	AreasNamesMap.Insert("ReportHeader", "ReportHeader|HeadersArea");
	AreasNamesMap.Insert("Text", "Text|HeadersArea");
	AreasNamesMap.Insert("TableHeading", "TableHeading|HeadersArea");
	AreasNamesMap.Insert("IsBlankString", "IsBlankString");
	
	AreasNamesMap.Insert("HeaderStartOfTable", "Header|StartOfTable");
	AreasNamesMap.Insert("HeaderAdditionalSection", "Header|AdditionalSection");
	AreasNamesMap.Insert("ColumnNumberingStartOfTable", "ColumnNumbering|StartOfTable");
	AreasNamesMap.Insert("ColumnNumberingAdditionalSection", "ColumnNumbering|AdditionalSection");
	
	If OutputParameters.DisplayNotes_ Then
		AreasNamesMap.Insert("HeaderColumnsGroup1WithNote", "Header|GroupingColumns1CNote");
		AreasNamesMap.Insert("HeaderColumnsGroup2WithNote", "Header|GroupingColumns2WithNote");
		AreasNamesMap.Insert("HeaderColumnsGroup3WithNote", "Header|GroupingColumns3WithNote");
		AreasNamesMap.Insert("ColumnNumberingHeaderColumnsGroup1WithNote",
			"ColumnNumbering|GroupingColumns1CNote");
		AreasNamesMap.Insert("ColumnNumberingHeaderColumnsGroup2WithNote",
			"ColumnNumbering|GroupingColumns2WithNote");
		AreasNamesMap.Insert("ColumnNumberingHeaderColumnsGroup3WithNote",
			"ColumnNumbering|GroupingColumns3WithNote");
	Else
		AreasNamesMap.Insert("HeaderColumnsGroup1", "Header|ColumnsGroup1");
		AreasNamesMap.Insert("HeaderColumnsGroup2", "Header|ColumnsGroup2");
		AreasNamesMap.Insert("HeaderColumnsGroup3", "Header|ColumnsGroup3");
		AreasNamesMap.Insert("ColumnNumberingGroupingOfColumns1", "ColumnNumbering|ColumnsGroup1");
		AreasNamesMap.Insert("ColumnNumberingGroupingOfColumns2", "ColumnNumbering|ColumnsGroup2");
		AreasNamesMap.Insert("ColumnNumberingGroupingOfColumns3", "ColumnNumbering|ColumnsGroup3");
	EndIf;
	
	AreasNamesMap.Insert("HeaderStartOfTableRowNumbering", "LineNumberingHeader|StartOfTable");
	AreasNamesMap.Insert("ColumnNumberingStartOfTableRowNumbering",
		"ColumnNumberingRowNumbering|StartOfTable");
	
	AreasNamesMap.Insert("Group1StartOfTable", "Group1|StartOfTable");
	AreasNamesMap.Insert("Group2StartOfTable", "Group2|StartOfTable");
	AreasNamesMap.Insert("Group3StartOfTable", "Group3|StartOfTable");
	AreasNamesMap.Insert("Group4StartOfTable", "Group4|StartOfTable");
	AreasNamesMap.Insert("Group5StartOfTable", "Group5|StartOfTable");
	AreasNamesMap.Insert("Group6StartOfTable", "Group6|StartOfTable");
	AreasNamesMap.Insert("Group7StartOfTable", "Group7|StartOfTable");
	
	AreasNamesMap.Insert("Grouping1BeginningOfTableRowNumbering",
		"Group1LineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping2BeginningOfTableRowNumbering",
		"Group2LineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping3BeginningOfTableRowNumbering",
		"Group3LineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping4BeginningOfTableRowNumbering",
		"Group4LineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping5BeginningOfTableRowNumbering",
		"Group5LineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping6BeginningOfTableRowNumbering",
		"Group6LineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping7BeginningOfTableRowNumbering",
		"Group7LineNumbering|StartOfTable");
	
	AreasNamesMap.Insert("Group1FinalStartOfTable", "Group1Final_|StartOfTable");
	AreasNamesMap.Insert("Group2FinalStartOfTable", "Group2Final_|StartOfTable");
	AreasNamesMap.Insert("Group3FinalStartOfTable", "Group3Final_|StartOfTable");
	AreasNamesMap.Insert("Group4FinalStartOfTable", "Group4Final_|StartOfTable");
	AreasNamesMap.Insert("Group5FinalStartOfTable", "Group5Final_|StartOfTable");
	AreasNamesMap.Insert("Group6FinalStartOfTable", "Group6Final_|StartOfTable");
	AreasNamesMap.Insert("Group7FinalStartOfTable", "Group7Final_|StartOfTable");
	AreasNamesMap.Insert("Group8FinalStartOfTable", "Group8Final_|StartOfTable");
	
	AreasNamesMap.Insert("Grouping1FinalBeginningOfTableRowNumbering",
		"Group1FinalLineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping2FinalBeginningOfTableRowNumbering",
		"Group2FinalLineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping3FinalStartOfTableRowNumbering",
		"Group3FinalLineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping4FinalBeginningOfTableRowNumbering",
		"Group4FinalLineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping5FinalBeginningOfTableRowNumbering",
		"Group5FinalLineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping6FinalBeginningOfTableRowNumbering",
		"Group6FinalLineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping7FinalBeginningOfTableRowNumbering",
		"Group7FinalLineNumbering|StartOfTable");
	AreasNamesMap.Insert("Grouping8FinalBeginningOfTableRowNumbering",
		"Group8FinalLineNumbering|StartOfTable");
	
	AreasNamesMap.Insert("Group1AdditionalSection", "Group1|AdditionalSection");
	AreasNamesMap.Insert("Group2AdditionalSection", "Group2|AdditionalSection");
	AreasNamesMap.Insert("Group3AdditionalSection", "Group3|AdditionalSection");
	AreasNamesMap.Insert("Group4AdditionalSection", "Group4|AdditionalSection");
	AreasNamesMap.Insert("Group5AdditionalSection", "Group5|AdditionalSection");
	AreasNamesMap.Insert("Group6AdditionalSection", "Group6|AdditionalSection");
	AreasNamesMap.Insert("Group7AdditionalSection", "Group7|AdditionalSection");
	
	AreasNamesMap.Insert("Group1FinalAdditionalSection", "Group1Final_|AdditionalSection");
	AreasNamesMap.Insert("Group2FinalAdditionalSection", "Group2Final_|AdditionalSection");
	AreasNamesMap.Insert("Group3FinalAdditionalSection", "Group3Final_|AdditionalSection");
	AreasNamesMap.Insert("Group4FinalAdditionalSection", "Group4Final_|AdditionalSection");
	AreasNamesMap.Insert("Group5FinalAdditionalSection", "Group5Final_|AdditionalSection");
	AreasNamesMap.Insert("Group6FinalAdditionalSection", "Group6Final_|AdditionalSection");
	AreasNamesMap.Insert("Group7FinalAdditionalSection", "Group7Final_|AdditionalSection");
	AreasNamesMap.Insert("Group8FinalAdditionalSection", "Group8Final_|AdditionalSection");

	If OutputParameters.DisplayNotes_ Then
		
		AreasNamesMap.Insert("Group1Value", "Group1|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group2Value", "Group2|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group3Value", "Group3|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group4Value", "Group4|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group5Value", "Group5|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group6Value", "Group6|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group7Value", "Group7|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group1Note", "Group1|NoteColumn");
		AreasNamesMap.Insert("Group2Note", "Group2|NoteColumn");
		AreasNamesMap.Insert("Group3Note", "Group3|NoteColumn");
		AreasNamesMap.Insert("Group4Note", "Group4|NoteColumn");
		AreasNamesMap.Insert("Group5Note", "Group5|NoteColumn");
		AreasNamesMap.Insert("Group6Note", "Group6|NoteColumn");
		AreasNamesMap.Insert("Group7Note", "Group7|NoteColumn");
		
		AreasNamesMap.Insert("Group1FinalValue", "Group1Final_|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group2FinalValue", "Group2Final_|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group3FinalValue", "Group3Final_|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group4FinalValue", "Group4Final_|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group5FinalValue", "Group5Final_|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group6FinalValue", "Group6Final_|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group7FinalValue", "Group7Final_|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group8FinalValue", "Group8Final_|GroupingColumns1CNote");
		AreasNamesMap.Insert("Group1FinalNote", "Group1Final_|NoteColumn");
		AreasNamesMap.Insert("Group2FinalNote", "Group2Final_|NoteColumn");
		AreasNamesMap.Insert("Group3FinalNote", "Group3Final_|NoteColumn");
		AreasNamesMap.Insert("Group4FinalNote", "Group4Final_|NoteColumn");
		AreasNamesMap.Insert("Group5FinalNote", "Group5Final_|NoteColumn");
		AreasNamesMap.Insert("Group6FinalNote", "Group6Final_|NoteColumn");
		AreasNamesMap.Insert("Group7FinalNote", "Group7Final_|NoteColumn");
		AreasNamesMap.Insert("Group8FinalNote", "Group8Final_|NoteColumn");
		
	Else
		
		AreasNamesMap.Insert("Group1Value", "Group1|ColumnsGroup1");
		AreasNamesMap.Insert("Group2Value", "Group2|ColumnsGroup1");
		AreasNamesMap.Insert("Group3Value", "Group3|ColumnsGroup1");
		AreasNamesMap.Insert("Group4Value", "Group4|ColumnsGroup1");
		AreasNamesMap.Insert("Group5Value", "Group5|ColumnsGroup1");
		AreasNamesMap.Insert("Group6Value", "Group6|ColumnsGroup1");
		AreasNamesMap.Insert("Group7Value", "Group7|ColumnsGroup1");
		
		AreasNamesMap.Insert("Group1FinalValue", "Group1Final_|ColumnsGroup1");
		AreasNamesMap.Insert("Group2FinalValue", "Group2Final_|ColumnsGroup1");
		AreasNamesMap.Insert("Group3FinalValue", "Group3Final_|ColumnsGroup1");
		AreasNamesMap.Insert("Group4FinalValue", "Group4Final_|ColumnsGroup1");
		AreasNamesMap.Insert("Group5FinalValue", "Group5Final_|ColumnsGroup1");
		AreasNamesMap.Insert("Group6FinalValue", "Group6Final_|ColumnsGroup1");
		AreasNamesMap.Insert("Group7FinalValue", "Group7Final_|ColumnsGroup1");
		AreasNamesMap.Insert("Group8FinalValue", "Group8Final_|ColumnsGroup1");
		
	EndIf;
	
	If OutputParameters.DisplayNotes_ And OutputParameters.DisplayTableNumbers Then
		AreasNamesMap.Insert("TableNumber", "TableNumber");
	EndIf;
	
	AppearanceTemplate 	= GetCommonTemplate("BudgetReport");
	StructureOfAreas 	= New Structure;
	
	For Each AreaName In AreasNamesMap Do
		StructureOfAreas.Insert(AreaName.Key, AppearanceTemplate.GetArea(AreaName.Value));
	EndDo;
	
	Return StructureOfAreas;
	
EndFunction

Procedure CheckingPossibilityOfFillingMeasurementsInCellStructure(DescriptionOfReport, SourcesOfMeasurementValues, OutputTree)
	
	If SourcesOfMeasurementValues.FindRows(New Structure("ID_Source1", "Document")).Count() = SourcesOfMeasurementValues.Count() Then
		Return;
	EndIf;
	
	Cnt = 1;
	QueryText = "";
	
	MeasurementReportElements = New Map;
	
	TypesOfAnalystValues = Common.ObjectsAttributeValue(DescriptionOfReport.DimensionKinds, "ValueType");
	For Each Dimension In DescriptionOfReport.DimensionKinds Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		
		FoundSourcesOfMeasurementValues = SourcesOfMeasurementValues.FindRows(New Structure("ID_Source1, Dimension", "AllItems", FieldName));
		If FoundSourcesOfMeasurementValues.Count() = 0 Then
			Continue;
		EndIf;
		
		TypeOfAnalytics = TypesOfAnalystValues.Get(Dimension).Types()[0];
		AnalyticsMetadata = Metadata.FindByType(TypeOfAnalytics);
		FullName = AnalyticsMetadata.FullName();
		IsDeletionMark = Common.IsStandardAttribute(AnalyticsMetadata.StandardAttributes, "DeletionMark");
		ThereIsThisGroup = Common.IsStandardAttribute(AnalyticsMetadata.StandardAttributes, "IsFolder");
		ShowItemHierarchy = False;
		For Each FoundSource In FoundSourcesOfMeasurementValues Do
			OutputTreeLines = OutputTree.Rows.FindRows(New Structure("ReportItem, DimensionName", FoundSource.String, FieldName), True);
			If OutputTreeLines.Count() = 0 Then
				OutputTreeLines = OutputTree.Rows.FindRows(New Structure("ReportItem, DimensionName", FoundSource.Column, FieldName), True);
			EndIf;
			If OutputTreeLines.Count() = 0 Then
				Continue;
			EndIf;
			OutputTreeLine = OutputTreeLines[0];
			If Not ShowItemHierarchy Then
				ShowItemHierarchy = OutputTreeLine.ShowItemHierarchy;
			EndIf;
			MeasurementReportElements.Insert(OutputTreeLine.ReportItem, FieldName);
		EndDo;
		
		If Cnt > 1 Then
			QueryText = QueryText + "
			|
			|UNION ALL
			| ";
		EndIf;
		
		SelectionText = "SELECT
			|	&DimensionName AS Dimension,
			|	&ShowItemHierarchy AS ShowItemHierarchy,
			|	SUM(1) AS Count
			|FROM
			|	&SourceTable1 AS Data
			|WHERE
			|	&SelectionConditions_";
		SelectionText = StrReplace(SelectionText, "&DimensionName", """" + FieldName + """");
		SelectionText = StrReplace(SelectionText, "&ShowItemHierarchy", ?(ShowItemHierarchy, "TRUE", "FALSE"));
		SelectionText = StrReplace(SelectionText, "&SourceTable1", FullName);
		
		If IsDeletionMark Then
			SelectionConditions_ = "NOT Data.DeletionMark";
		Else
			SelectionConditions_ = "True";
		EndIf;
		
		If ThereIsThisGroup Then
			SelectionConditions_ = SelectionConditions_ + "
			|	AND NOT Data.IsFolder";
		EndIf;
		SelectionText = StrReplace(SelectionText, "&SelectionConditions_", SelectionConditions_);
		
		QueryText = QueryText + Chars.LF + Chars.LF + SelectionText + " ";
		
		Cnt = Cnt + 1;
	EndDo;
		
	If QueryText = "" Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	
	Result = Query.Execute().Unload();
	For Each ResultRow In Result Do
		If Not ValueIsFilled(ResultRow.Count) Then
			ResultRow.Count = 1;
		EndIf;
		// for analysts with hierarchy output, the allowable amount is 3 times more due to the fact
		// that additional selection is probably used and the amount output to the budget will be significantly less
		If ResultRow.ShowItemHierarchy Then
			ResultRow.Count = Int(ResultRow.Count / 3);
		EndIf;
	EndDo;
	
	AnalystCombinations = New Map;
	
	For Each KeyAndValue In MeasurementReportElements Do
		ReportItem = KeyAndValue.Key;
		FieldName = KeyAndValue.Value;
		OutputTreeLine = OutputTree.Rows.Find(ReportItem, "ReportItem", True);
		For Each KeyAndValue In MeasurementReportElements Do
			If KeyAndValue.Key = ReportItem Or KeyAndValue.Value = FieldName Then
				Continue;
			EndIf;
			SubordinateRow = OutputTreeLine.Rows.Find(KeyAndValue.Key, "ReportItem", True);
			If SubordinateRow <> Undefined Then
				If AnalystCombinations.Get(FieldName) = Undefined Then
					AnalystCombinations.Insert(FieldName, New Array);
				EndIf;
				If AnalystCombinations[FieldName].Find(KeyAndValue.Value) = Undefined Then
					AnalystCombinations[FieldName].Add(KeyAndValue.Value);
				EndIf;
				If AnalystCombinations.Get(KeyAndValue.Value) = Undefined Then
					AnalystCombinations.Insert(KeyAndValue.Value, New Array);
				EndIf;
				If AnalystCombinations[KeyAndValue.Value].Find(FieldName) = Undefined Then
					AnalystCombinations[KeyAndValue.Value].Add(FieldName);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	NumberOfCombinationsOfAnalytics = 0;
	
	ProcessedAnalytics = New Array;
	For Each ResultRow In Result Do
		If ProcessedAnalytics.Find(ResultRow.Dimension) <> Undefined Then
			Continue;
		EndIf;
		ProcessedAnalytics.Add(ResultRow.Dimension);
		ProductAnalyst = ResultRow.Count;
		CombinationOfAnalytics = AnalystCombinations.Get(ResultRow.Dimension);
		If CombinationOfAnalytics <> Undefined Then
			For Each NameOfAnalytics In CombinationOfAnalytics Do
				ResultRow1 = Result.Find(NameOfAnalytics, "Dimension");
				If ProcessedAnalytics.Find(ResultRow1.Dimension) <> Undefined Then
					Continue;
				EndIf;
				ProcessedAnalytics.Add(ResultRow1.Dimension);
				ProductAnalyst = ProductAnalyst * ResultRow1.Count;
			EndDo;
		EndIf;
		NumberOfCombinationsOfAnalytics = NumberOfCombinationsOfAnalytics + ProductAnalyst;
		If NumberOfCombinationsOfAnalytics > 3000 Then
			Raise NStr("vi = 'Vượt quá số dòng tối đa để thêm kích thước. Bộ xử lý dữ liệu bị hủy bỏ.';
						|ru = 'Превышено максимальное количество строк для добавления аналитик. Обработка прервана.';
						|en = 'Exceeded maximum number of lines to add dimensions. Data processor aborted.'; fa = 'Exceeded maximum number of lines to add dimensions. Data processor aborted.';
						|it = 'Superata la quantità massima di righe per l''aggiunta di analitiche. Elaborazione interrotta.';
						|pl = 'Przekroczona maksymalna ilość wierszy dla dodania analityk. Przetwarzanie zostało przerwane.';
						|tr = 'Boyutun eklenmesinde maksimum satır sayısı aşıldı. Veri işlemcisi kesintiye uğradı.'");
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInDimensionsInCellStructureBySource(QueryText, ParametersForFillingMeasurements, NameOfTableWithDimensions)
	
	DescriptionOfReport = ParametersForFillingMeasurements.DescriptionOfReport;
	AuxiliaryData = ParametersForFillingMeasurements.AuxiliaryData;
	DataTableName = ParametersForFillingMeasurements.DataTableName;
	SourcesOfMeasurementValues = ParametersForFillingMeasurements.SourcesOfMeasurementValues;
	ParametersOfOtherConnections = ParametersForFillingMeasurements.ParametersOfOtherConnections;
	GenerationMode = ParametersForFillingMeasurements.GenerationMode;
	
	If SourcesOfMeasurementValues.FindRows(New Structure("ID_Source1", "Document")).Count() = SourcesOfMeasurementValues.Count() Then
		Return;
	EndIf;
	
	BasicElements        = AuxiliaryData.BasicElements;
	BasicFlags           = AuxiliaryData.BasicFlags;
	MeasurementText_          = AuxiliaryData.MeasurementText_;
	TextDimensionFlags     = AuxiliaryData.TextDimensionFlags;
	AnalyticsText          = AuxiliaryData.AnalyticsText;
	TextAnalyticsFlags     = AuxiliaryData.TextAnalyticsFlags;
	TextAnalyst_3   = AuxiliaryData.TextAnalyst_3;
	TextOfPeriods           = AuxiliaryData.TextOfPeriods;
	TextFlagsPeriods      = AuxiliaryData.TextFlagsPeriods;
	TextConnection = AuxiliaryData.TextConnection;
	
	Cnt = 1;
	CurTableName_ = NameOfTableWithDimensions;
	TemplateForTableNameWithDimensions = "CellStructureFillingDimensions";	
	
	TypesOfAnalystValues = Common.ObjectsAttributeValue(DescriptionOfReport.DimensionKinds, "ValueType");
	For Each DimensionKind In DescriptionOfReport.DimensionKinds Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		
		SourceAllElements = False;
		If SourcesOfMeasurementValues.FindRows(New Structure("ID_Source1, Dimension", "AllItems", FieldName)).Count() Then
			SourceAllElements = True;
		EndIf;
		
		NameOfTableWithDimensions = TemplateForTableNameWithDimensions + "_" + Cnt;
		
		If SourceAllElements Then
			AnalyticsTextCur = StrReplace(AnalyticsText, "<TableName>." + FieldName + " AS " + FieldName, 
				"CASE WHEN (CellStructure.Flag" + FieldName + " = ""Fill""
				|		OR CellStructure.Flag" + FieldName + " = ""Document"")
				|			AND NOT AllAnalyticsValues.Ref IS NULL THEN
				|		AllAnalyticsValues.Ref
				|	ELSE
				|		CellStructure." + FieldName + "
				|	END AS " + FieldName);
				
			TextAnalyticsFlagsCur = StrReplace(TextAnalyticsFlags, "<TableName>.Flag" + FieldName + " AS Flag" + FieldName,
				"CASE WHEN (CellStructure.Flag" + FieldName + " = ""Fill""
				|		OR CellStructure.Flag" + FieldName + " = ""Document"")
				|			AND NOT AllAnalyticsValues.Ref IS NULL THEN
				|		""Pick""
				|	ELSE
				|		CellStructure.Flag" + FieldName + "
				|	END AS Flag" + FieldName);
				
		Else
			AnalyticsTextCur = StrReplace(AnalyticsText, "<TableName>." + FieldName + " AS " + FieldName, 
				"CASE WHEN (CellStructure.Flag" + FieldName + " = ""Fill""
				|		OR CellStructure.Flag" + FieldName + " = ""Document"")
				|			AND NOT DataTable." + FieldName + " IS NULL THEN
				|		DataTable." + FieldName + "
				|	ELSE
				|		CellStructure." + FieldName + "
				|	END AS " + FieldName);
				
			TextAnalyticsFlagsCur = StrReplace(TextAnalyticsFlags, "<TableName>.Flag" + FieldName + " AS Flag" + FieldName,
				"CASE WHEN (CellStructure.Flag" + FieldName + " = ""Fill""
				|		OR CellStructure.Flag" + FieldName + " = ""Document"")
				|			AND NOT DataTable." + FieldName + " IS NULL THEN
				|		""Pick""
				|	ELSE
				|		CellStructure.Flag" + FieldName + "
				|	END AS Flag" + FieldName);
		EndIf;
			
		QueryTextSupplement = "SELECT DISTINCT
		|	&SelectionFields1
		|
		|INTO ReplacementNameOfTemporaryDimensionTable
		|FROM
		|	&SourceTable2 AS CellStructure";
		SelectionFields1 = StrReplace(BasicElements, "<TableName>", "CellStructure")
				+ StrReplace(BasicFlags, "<TableName>", "CellStructure")
				+ StrReplace(MeasurementText_, "<TableName>", "CellStructure")
				+ StrReplace(TextOfPeriods, "<TableName>", "CellStructure")
				+ StrReplace(AnalyticsTextCur, "<TableName>", "CellStructure")
				+ StrReplace(TextDimensionFlags, "<TableName>", "CellStructure")
				+ StrReplace(TextFlagsPeriods, "<TableName>", "CellStructure")
				+ StrReplace(TextConnection, "<TableName>", "CellStructure")
				+ StrReplace(TextAnalyticsFlagsCur, "<TableName>", "CellStructure")
				+ StrReplace(TextAnalyst_3, "<TableName>", "CellStructure")
				+ "
				|	CellStructure.ID_Source1 AS ID_Source1,
				|	CellStructure.ExcludeDocumentData AS ExcludeDocumentData";
		
		QueryTextSupplement = StrReplace(QueryTextSupplement, "ReplacementNameOfTemporaryDimensionTable", NameOfTableWithDimensions);
		QueryTextSupplement = StrReplace(QueryTextSupplement, "&SelectionFields1", SelectionFields1);
		QueryTextSupplement = StrReplace(QueryTextSupplement, "&SourceTable2", CurTableName_);
		
		If Not SourceAllElements Then
			
			QueryTextSupplement = QueryTextSupplement + "
			|
			| LEFT JOIN TableOfMeasurementSourcesWithDimensionName
			|
			| ON CellStructure.String = TableOfMeasurementSourcesWithDimensionName.String
			|	AND CellStructure.Column = TableOfMeasurementSourcesWithDimensionName.Column
			|   AND (TableOfMeasurementSourcesWithDimensionName.Dimension = """+FieldName+ """)";
		
			QueryTextSupplement = QueryTextSupplement + "
			|   AND (CellStructure.MainItem)
			|	AND (CellStructure.ItemKind IN (VALUE(Enum.FinancialReportItemKinds.DerivedItem), VALUE(Enum.FinancialReportItemKinds.GroupFormula), VALUE(Enum.FinancialReportItemKinds.Group)))";
		
			QueryTextSupplement = QueryTextSupplement + "
				| LEFT JOIN "  + DataTableName + " AS DataTable
				| On (ISNULL(TableOfMeasurementSourcesWithDimensionName.ID_Source1, CellStructure.ID_Source1) = DataTable.ID_Source1)";
			
			For Each Periodicity In DescriptionOfReport.Periodicity_ Do
				PeriodStrings = FinancialReportingClientServer.PeriodStrings(Periodicity);
				QueryTextSupplement = QueryTextSupplement + "
				|	AND (	(CellStructure." + PeriodStrings.FlagPeriod + " = ""Pick""
				|			AND CellStructure." + PeriodStrings.PeriodConnection + " = DataTable." + PeriodStrings.Period + ")
				|		OR
				|		(CellStructure." + PeriodStrings.FlagPeriod + " <> ""Pick""
				|			AND DataTable." + PeriodStrings.Period + " = UNDEFINED)	)
				|";
			EndDo;
			
			SothebySLinkTextBySource = "
			|			AND CASE WHEN TableOfMeasurementSourcesWithDimensionName.ID_Source1 IS NULL
			|				// Source all articles or all indicators 
			|				THEN &ConnectionConditionsAllObjects
			|			ELSE
			|				// Filling in by operand type, taking into account selections for additional fields
			|				&ConnectionConditionsByObjectType
			|			END";
			
			ConnectionConditionsAllObjects = "TRUE
			|					AND (NOT CellStructure.FlagBudgetFlowItem = ""Pick""
			|						OR CellStructure.BudgetFlowItem = DataTable.BudgetFlowItem)
			|					AND (NOT CellStructure.FlagBudgetBalanceItem = ""Pick""
			|						OR CellStructure.BudgetBalanceItem = DataTable.BudgetBalanceItem)
			|					AND (NOT CellStructure.FlagNonFinancialItem = ""Pick""
			|						OR CellStructure.NonFinancialItem = DataTable.NonFinancialItem)
			|					AND (NOT CellStructure.FlagEditedValue = ""Pick""
			|						OR CellStructure.EditedValue = DataTable.EditedValue)";
			
			// There may be data with a filled quantity, but not a filled amount, and vice versa.
			// Also, since the data tables for the calculated indicators do not indicate the influencing article, it is necessary to make a selection by resources.
			ConnectionConditionsByObjectType =
			"				CASE
			|					WHEN TableOfMeasurementSourcesWithDimensionName.SourceKind <> VALUE(Enum.FinancialReportItemKinds.BudgetBalanceItem)
			|						// If the operand is a non-financial indicator or an editable value, it must be fully consistent with the table of measurement sources
			|						THEN TableOfMeasurementSourcesWithDimensionName.BudgetFlowItem = DataTable.BudgetFlowItem
			|							AND TableOfMeasurementSourcesWithDimensionName.BudgetBalanceItem = DataTable.BudgetBalanceItem
			|							AND TableOfMeasurementSourcesWithDimensionName.NonFinancialItem = DataTable.NonFinancialItem
			|							AND TableOfMeasurementSourcesWithDimensionName.EditedValue = DataTable.EditedValue
			|					WHEN TableOfMeasurementSourcesWithDimensionName.BudgetBalanceItemType = VALUE(Enum.BudgetBalanceItemType.SpecialPurpose)
			|						// In the data table as an article and the indicator specified the target and source table target column of the article
			|						THEN TableOfMeasurementSourcesWithDimensionName.BudgetFlowItem = DataTable.BudgetFlowItem
			|							AND TableOfMeasurementSourcesWithDimensionName.BudgetFlowItem = DataTable.BudgetBalanceItem
			|							AND TableOfMeasurementSourcesWithDimensionName.BudgetBalanceItem = VALUE(Catalog.BudgetBalanceItems.EmptyRef)
			|							AND TableOfMeasurementSourcesWithDimensionName.NonFinancialItem = DataTable.NonFinancialItem
			|							AND TableOfMeasurementSourcesWithDimensionName.EditedValue = DataTable.EditedValue
			|					WHEN TableOfMeasurementSourcesWithDimensionName.BudgetBalanceItemType = VALUE(Enum.BudgetBalanceItemType.Estimated_)
			|						// Calculated indicator without data on influencing items
			|						THEN TableOfMeasurementSourcesWithDimensionName.BudgetFlowItem = DataTable.BudgetFlowItem
			|							AND TableOfMeasurementSourcesWithDimensionName.BudgetBalanceItem = DataTable.BudgetBalanceItem
			|							AND TableOfMeasurementSourcesWithDimensionName.NonFinancialItem = DataTable.NonFinancialItem
			|							AND TableOfMeasurementSourcesWithDimensionName.EditedValue = DataTable.EditedValue
			|					ELSE FALSE
			|				END";
			
			SothebySLinkTextBySource = StrReplace(SothebySLinkTextBySource,
					"&ConnectionConditionsAllObjects",
					ConnectionConditionsAllObjects);
			SothebySLinkTextBySource = StrReplace(SothebySLinkTextBySource,
					"&ConnectionConditionsByObjectType",
					ConnectionConditionsByObjectType);
			
			QueryTextSupplement = QueryTextSupplement + SothebySLinkTextBySource;
			
			For Each Dimension In DescriptionOfReport.Dimensions Do
				If Dimension = "UnitOfMeasure" Then
					Continue;
				EndIf;
				
				If Dimension = "Scenario" 
					And GenerationMode = Enums.ModesOfBudgetReportGeneration.Report Then
					QueryTextSupplement = QueryTextSupplement + "
					|	AND (CellStructure.Flag" + Dimension + " = ""Fill""
					|		OR CellStructure.Flag" + Dimension + " = ""Pick"" AND CellStructure." + Dimension + " = DataTable." + Dimension + ")
					|";
				Else
					QueryTextSupplement = QueryTextSupplement + "
					|	AND (NOT CellStructure.Flag" + Dimension + " = ""Pick""
					|		OR CellStructure." + Dimension + " = DataTable." + Dimension + ")
					|";
				EndIf;
			EndDo;
			
			QueryTextSupplement = QueryTextSupplement + "
				|			AND (CellStructure.Flag" + FieldName + " = ""fill""";
			
			If ParametersOfOtherConnections.Document.Find(FieldName) <> Undefined Then
				QueryTextSupplement = QueryTextSupplement + "
					|					AND NOT DataTable."+FieldName+" IN
					|							(SELECT
					|								TableOfValuesByParentDocument.Value
					|							FROM
					|								TableOfValuesByParentDocument
					|							WHERE
					|								TableOfValuesByParentDocument.Parent = CellStructure.Parent"+FieldName+")
					|				OR CellStructure.Flag"+FieldName+" = ""Document""
					|					AND NOT DataTable."+FieldName+" IN
					|							(SELECT
					|								TableOfValuesByParentDocument.Value
					|							FROM
					|								TableOfValuesByParentDocument
					|							WHERE
					|								TableOfValuesByParentDocument.Parent = CellStructure.Parent"+FieldName+"))";
			Else
				QueryTextSupplement = QueryTextSupplement + ")";	
			EndIf;
				
			// Let's clarify the possible aggregates of analysts according to the available data
			CurAnalyticsFailed = True;
			For Each TypeOfAnalyticsRefined In DescriptionOfReport.DimensionKinds Do
				If TypeOfAnalyticsRefined = DimensionKind Then
					CurAnalyticsFailed = False;
					Continue;
				EndIf;
				
				NameOfAnalyticsField = FinancialReportingCached.NameOfBudgetReportField(TypeOfAnalyticsRefined);
				
				If CurAnalyticsFailed Then
					ConditionTextForFollowingAnalytics = "
					|			AND CellStructure." + NameOfAnalyticsField + " = DataTable." + NameOfAnalyticsField;
				Else
					
					ConditionTextForFollowingAnalytics = "
					|			AND CASE
					|					WHEN CellStructure.Flag"+NameOfAnalyticsField+" = ""Pick""
					|						THEN CellStructure." + NameOfAnalyticsField + " = DataTable." + NameOfAnalyticsField;
					If ParametersOfOtherConnections.Document.Find(NameOfAnalyticsField) <> Undefined Then
						ConditionTextForFollowingAnalytics = ConditionTextForFollowingAnalytics + "
						|					WHEN CellStructure.Flag"+NameOfAnalyticsField+" = ""Document""
						|						THEN (CellStructure." + NameOfAnalyticsField + " = DataTable." + NameOfAnalyticsField + " OR CellStructure." + NameOfAnalyticsField + " = UNDEFINED)";
					EndIf;
					ConditionTextForFollowingAnalytics = ConditionTextForFollowingAnalytics + "
					|					ELSE TRUE
					|				END";
					
				EndIf;
				QueryTextSupplement = QueryTextSupplement + ConditionTextForFollowingAnalytics;
			EndDo;
				
		Else
				
			TypesOfAnalytics_ = TypesOfAnalystValues.Get(DimensionKind).Types();
			SubqueryTextsOnAnalytics = New Array;
			RequestSeparator = "
			|
			|UNION ALL
			|
			|";
			
			For Each TypeOfAnalytics In TypesOfAnalytics_ Do
				AnalyticsMetadata = Metadata.FindByType(TypeOfAnalytics);
				FullName = AnalyticsMetadata.FullName();
				IsDeletionMark = Common.IsStandardAttribute(AnalyticsMetadata.StandardAttributes, "DeletionMark");
				ThereIsThisGroup = Common.IsStandardAttribute(AnalyticsMetadata.StandardAttributes, "IsFolder");
				
				TextOfAnalyticsSubquery =
				"SELECT
				|	Table.Ref
				|FROM
				|	&FullTableName AS Table
				|WHERE
				|	TRUE";
				
				If IsDeletionMark Then
					TextOfAnalyticsSubquery = TextOfAnalyticsSubquery + "
					|	AND NOT Table.DeletionMark";
				EndIf;
				
				If ThereIsThisGroup Then
					TextOfAnalyticsSubquery = TextOfAnalyticsSubquery + "
					|	AND NOT Table.IsFolder";
				EndIf;
				
				If TypeOfAnalytics = Type("CatalogRef.ObjectsPropertiesValues") Or TypeOfAnalytics = Type(
					"CatalogRef.ObjectPropertyValueHierarchy") Then
					TextOfAnalyticsSubquery = TextOfAnalyticsSubquery + "
																			  |	AND Table.Owner.IDForFormulas = &IDForFormulas";
					TextOfAnalyticsSubquery = StrReplace(TextOfAnalyticsSubquery, "&IDForFormulas",
						"""" + Common.ObjectAttributeValue(DimensionKind,
						"AdditionalProperty.IDForFormulas") + """");
				EndIf;
				
				TextOfAnalyticsSubquery = StrReplace(TextOfAnalyticsSubquery, "&FullTableName", FullName);
				
				SubqueryTextsOnAnalytics.Add(TextOfAnalyticsSubquery);
				
			EndDo;
			
			If ParametersForFillingMeasurements.GenerationMode
				<> Enums.ModesOfBudgetReportGeneration.FillType Then

				EmptyDimensionValue = BudgetingServer.ExpressingEmptyValue();

				If ParametersForFillingMeasurements.GenerationMode
					= Enums.ModesOfBudgetReportGeneration.Document Then
					TextOfAnalyticsSubquery =
					"SELECT
					|	&EmptyDimensionValue AS Ref";
				Else
					TextOfAnalyticsSubquery =
					"SELECT TOP 1
					|	&EmptyDimensionValue AS Ref
					|FROM
					|	DataTable AS DataTable
					|WHERE
					|	&NameOfDataTableField = &EmptyDimensionValue";

				EndIf;

				TextOfAnalyticsSubquery = StrReplace(TextOfAnalyticsSubquery, "&EmptyDimensionValue",
					EmptyDimensionValue);
				TextOfAnalyticsSubquery = StrReplace(TextOfAnalyticsSubquery, "&NameOfDataTableField",
					"DataTable." + FieldName);

				SubqueryTextsOnAnalytics.Add(TextOfAnalyticsSubquery);

			EndIf;
			
			TextOfAnalyticsSubquery = Chars.LF + StrConcat(SubqueryTextsOnAnalytics, RequestSeparator) + Chars.LF;
			
			QueryTextSupplement = QueryTextSupplement + "
			| LEFT JOIN (" + TextOfAnalyticsSubquery + ") AS AllAnalyticsValues
			| On TRUE";
			
			QueryTextSupplement = QueryTextSupplement + "
			|   AND (CellStructure.MainItem)
			|	AND (CellStructure.ItemKind IN (VALUE(Enum.FinancialReportItemKinds.DerivedItem), VALUE(Enum.FinancialReportItemKinds.GroupFormula), VALUE(Enum.FinancialReportItemKinds.Group)))";
			
			QueryTextSupplement = QueryTextSupplement + "
			|			AND (CellStructure.Flag"+FieldName+" = ""fill""";
			
			If ParametersOfOtherConnections.Document.Find(FieldName) <> Undefined Then
				QueryTextSupplement = QueryTextSupplement + "
				|					AND NOT AllAnalyticsValues.Ref IN
				|							(SELECT
				|								TableOfValuesByParentDocument.Value
				|							FROM
				|								TableOfValuesByParentDocument
				|							WHERE
				|								TableOfValuesByParentDocument.Parent = CellStructure.Parent"+FieldName+")
				|				OR CellStructure.Flag"+FieldName+" = ""Document""
				|					AND NOT AllAnalyticsValues.Ref IN
				|							(SELECT
				|								TableOfValuesByParentDocument.Value
				|							FROM
				|								TableOfValuesByParentDocument
				|							WHERE
				|								TableOfValuesByParentDocument.Parent = CellStructure.Parent"+FieldName+"))";
				
			Else
				QueryTextSupplement = QueryTextSupplement + ")";
			EndIf;
			
		EndIf;
		
		QueryTextSupplement = QueryTextSupplement + "
		|
		|WHERE CellStructure.MainItem AND
		|	CellStructure.ItemKind IN
		|		(	
		|		VALUE(Enum.FinancialReportItemKinds.DerivedItem),
		|		VALUE(Enum.FinancialReportItemKinds.GroupFormula),
		|		VALUE(Enum.FinancialReportItemKinds.Group)
		|		)";
			
		If Cnt = DescriptionOfReport.DimensionKinds.Count() Then
			QueryTextSupplement = QueryTextSupplement + "
				|
				|INDEX BY CellStructure.String, CellStructure.Column
				|
				|;
				|";
		Else
			QueryTextSupplement = QueryTextSupplement + "
				|
				|INDEX BY ID_Source1
				|
				|;
				|";
		EndIf;
		
		QueryText = QueryText + Chars.LF + Chars.LF + QueryTextSupplement;
		
		CurTableName_ = NameOfTableWithDimensions;
		Cnt = Cnt + 1;
	EndDo;
	
EndProcedure

Function ParametersForAddingDesignAreaAndDisplayingAdditionalFields()
	ParametersSet = New Structure;
	// To add a design area and output additional fields.
	ParametersSet.Insert("OutputParameters", Undefined);
	ParametersSet.Insert("ReportItem", Undefined);
	ParametersSet.Insert("Column", Undefined);
	
	// To output additional fields.
	ParametersSet.Insert("Area", Undefined);
	ParametersSet.Insert("Value", Undefined);
	ParametersSet.Insert("ReportRow", Undefined);
	
	Return ParametersSet;
EndFunction

// Adds an output parameter to the structure. The comment also contains a list of possible parameters within the module.
// 
// Parameters:
// 	OutputParameters - Structure - Possible Values:
// 	* ResultDocument - SpreadsheetDocument - Tabular document that displays the budget
// 	* ColumnStructure1  - See BudgetReportingCacheCalculationServer.ColumnsOfDataTable_
// 	* CellData_       - See BudgetReportingDisplayServer.CellData_
// 	* OutputTree      - See BudgetReportingCacheCalculationServer.NewOutputTree
// 	* OutputTogetherWithSubordinate - Boolean -
// 	* DisplayWithParent - Boolean -
// 	* AdditionalFields - ValueTable - possible content:
// 		* Attribute     - Arbitrary -
// 		* Description - String -
// 		* AttributeName - String -
// 		* Title    - String -
// 		* TitleOutput - Boolean -
// 		* InSeparateColumn - Boolean -
// 	* TableParameters - Structure - Contains:
// 		** DisplayGroupingTitle - Boolean -
// 		** GroupHeader - String -
// 		** DisplayHeadersVertically - Boolean -
// 		** DisplayColumnNumbering - Boolean -
// 		** DisplayRowsNumbering - Boolean -
// 		** AppearanceItems - ValueTable -
// 		** RegisteredRows - ValueTable -
// 		** DesigningColumns - ValueTable -
// 		** DrillDownOfAppearanceItemFilterFields - ValueTable -
// 		** ReportDataForFormatting - See BudgetReportingCacheCalculationServer.ReportDataForFormatting
// 	* SearchIndexes - Map, Undefined - parameter description:
//	    ** Key - String - the column names of the index separated by commas
//	    ** Value - Boolean - -
// 	* ForEditing - Boolean - 
// 	* SubordinateElementsOfBudgetView - ValueTable -
// 	* LevelStyle - Structure - Contains:
// 		** Value - See GetCacheOfEditingListLineStyles
// 	* AddressForAddingLinesToEditList - String, ValueTree - a tree with a form (a string of a tree). Contains:
// 		** Presentation - String -
// 		** String - CatalogRef.FinancialReportItems -
// 		** Picture - Number -
// 		** Level  - Number -
// 		** TableID - UUID -
// 		** GroupingID - UUID -
// 		** DimensionName  - String -
// 		** FixedValue - Arbitrary -
// 		** ThisIsDimensionOther - Boolean -
// 		** EditedValues - Boolean -
// 		** Details - Number -
// 		** ThisIsACombinedDimension - Boolean -
// 	* BudgetProfile    - CatalogRef.BudgetProfiles - 
// 	* BeginOfPeriod - Date -
// 	* EndOfPeriod  - Date -
// 	* GenerationMode - EnumRef.ModesOfBudgetReportGeneration - 
// 	* MeasurementPresentations - See PresentationOfReportDimensions
// 	* ReportDataForFormatting - See BudgetReportingCacheCalculationServer.ReportDataForFormatting
// 	* TreeOfEditListRows - ValueTree - Contains:
// 		** Presentation - String -
// 		** String - CatalogRef.FinancialReportItems -
// 		** Picture - Number -
// 		** Level  - Number -
// 		** TableID - UUID -
// 		** GroupingID - UUID -
// 		** DimensionName  - String -
// 		** FixedValue - Arbitrary -
// 		** ThisIsDimensionOther - Boolean -
// 		** EditedValues - Boolean -
// 		** Details - Number -
// 		** ThisIsACombinedDimension - Boolean -
// 	* DetailsData - Map of KeyAndValue - Contains:
// 		** Key - Number - uid transcripts
// 		** Value - See NewDecryptionStructure
// 	* Remarks - See NewNoteStructure
// 	Var_Key - String -
// 	Value - Arbitrary -
Procedure AddOutputParameter(OutputParameters, Var_Key, Value)
	
	OutputParameters.Insert(Var_Key, Value);
	
EndProcedure

Procedure ProcessSelectionSettingsByAnalyticsHierarchy(Filter, NameOfAnalytics)
	
	For Each FilterElement In Filter.Items Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			ProcessSelectionSettingsByAnalyticsHierarchy(FilterElement, NameOfAnalytics);
		Else
			FilterElement.LeftValue = New DataCompositionField(NameOfAnalytics + ".Parent");
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion 

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region DistributionByParty

// Returns the result of distributing the remaining costs by production batch.
//
//	Parameters:
//		Ref - DocumentRef.InitialWIPBalancesByBusinessUnits - link to the document whose costs should be allocated.
//		ResultAddress - String - address of the temporary storage for placing the distribution result.
//
//	Returns:
//		Structure - the result of the distribution of the remaining costs by production batches.
//
Function DistributeInitialBalancesAmongProductionBatches(Ref, ResultAddress = Undefined) Export
	
	// StandardSubsystems.PerformanceMeasurement
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.InitialWIPBalancesByBusinessUnits.ManagerModule.DistributeInitialBalancesAmongProductionBatches");
	// End StandardSubsystems.PerformanceMeasurement
	
	AttributesList =
		"CostsAccountingProcedure, Date, Department,
		|Organization, PriceKind, LineOfBusiness";
	
	DocumentAttributes = Common.ObjectAttributesValues(Ref, AttributesList);
	DocumentAttributes.Insert("DocumentBasis", Ref);
	
	Query = New Query;
	TempTableManager = New TempTablesManager;
	Query.TempTablesManager = TempTableManager;
	Query.Text = StrConcat(CostAllocationRequestTexts(DocumentAttributes.Date), Common.QueryBatchSeparator());
	
	Query.SetParameter("Ref",						Ref);
	Query.SetParameter("DateOfRemainingGoods",				DocumentAttributes.Date);
	Query.SetParameter("Organization",				DocumentAttributes.Organization);
	Query.SetParameter("Department",				DocumentAttributes.Department);
	Query.SetParameter("CostsAccountingProcedure",			DocumentAttributes.CostsAccountingProcedure);
	Query.SetParameter("LineOfBusiness",	DocumentAttributes.LineOfBusiness);
	Query.SetParameter("PriceKind",					DocumentAttributes.PriceKind);
	Query.SetParameter("CurrencyOfTypesOfWork",			Constants.CurrencyOfActivityKindRates.Get());
	Query.SetParameter("CurrencyOfManAccounting",				Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentAttributes.Organization));
	
	
	QueryResult	= Query.ExecuteBatch();
	UBound			= QueryResult.UBound();
	
	AmountsOfMaterials			= QueryResult[1].Select();
	AmountsOfLaborCosts		= QueryResult[2].Select();
	OtherExpenses			= QueryResult[3].Unload();
	OtherExpensesNew		= OtherExpenses.CopyColumns();
	
	MaterialsAndWorks		= Undefined;
	LaborCosts			= Undefined;
	
	#Region DistributionOfMaterialCosts
	While AmountsOfMaterials.Next() Do
		
		MaterialsAndWorks = QueryResult[UBound - 2].Unload();
		Coefficients = MaterialsAndWorks.UnloadColumn("AllocationBase");
		
		AllocationResult		=
			DistributeAmountInProportionToCoefficients(AmountsOfMaterials.Sum, Coefficients);
		ResultOfLocalDistribution	=
			DistributeAmountInProportionToCoefficients(AmountsOfMaterials.SumCompl, Coefficients);
		PDDistributionResult	=
			DistributeAmountInProportionToCoefficients(AmountsOfMaterials.AmountPermanentDifferences, Coefficients);
		ResultOfTDDistribution	=
			DistributeAmountInProportionToCoefficients(AmountsOfMaterials.AmountTemporaryDifferences, Coefficients);
		
		MaxIndex = Coefficients.Count() - 1;
		For IndexOf = 0 To MaxIndex Do
			
			If Not AllocationResult = Undefined Then
				
				MaterialsAndWorks[IndexOf].Sum	= MaterialsAndWorks[IndexOf].Sum + AllocationResult[IndexOf];
				
				If ValueIsFilled(MaterialsAndWorks[IndexOf].NumberOfPackages) Then
					MaterialsAndWorks[IndexOf].Price = MaterialsAndWorks[IndexOf].Sum / MaterialsAndWorks[IndexOf].NumberOfPackages;
				Else
					MaterialsAndWorks[IndexOf].Price = 0;
				EndIf;
				
			EndIf;
			
			If Not ResultOfLocalDistribution = Undefined Then
				MaterialsAndWorks[IndexOf].SumCompl = MaterialsAndWorks[IndexOf].SumCompl + ResultOfLocalDistribution[IndexOf];
			EndIf;
			
			If Not PDDistributionResult = Undefined Then
				MaterialsAndWorks[IndexOf].AmountPermanentDifferences = MaterialsAndWorks[IndexOf].AmountPermanentDifferences + PDDistributionResult[IndexOf];
			EndIf;
			
			If Not ResultOfTDDistribution = Undefined Then
				MaterialsAndWorks[IndexOf].AmountTemporaryDifferences = MaterialsAndWorks[IndexOf].AmountTemporaryDifferences + ResultOfTDDistribution[IndexOf];
			EndIf;
			
		EndDo;
		
	EndDo;
	#EndRegion
	
	#Region DistributionOfLaborCosts
	While AmountsOfLaborCosts.Next() Do
		
		LaborCosts = QueryResult[UBound - 1].Unload();
		Coefficients = LaborCosts.UnloadColumn("AllocationBase");
		
		AllocationResult		=
			DistributeAmountInProportionToCoefficients(AmountsOfLaborCosts.Sum, Coefficients);
		ResultOfLocalDistribution	=
			DistributeAmountInProportionToCoefficients(AmountsOfLaborCosts.SumCompl, Coefficients);
		PDDistributionResult	=
			DistributeAmountInProportionToCoefficients(AmountsOfLaborCosts.AmountPermanentDifferences, Coefficients);
		ResultOfTDDistribution	=
			DistributeAmountInProportionToCoefficients(AmountsOfLaborCosts.AmountTemporaryDifferences, Coefficients);
		
		MaxIndex = Coefficients.Count() - 1;
		For IndexOf = 0 To MaxIndex Do
			
			If Not AllocationResult = Undefined Then
				
				LaborCosts[IndexOf].Sum = LaborCosts[IndexOf].Sum + AllocationResult[IndexOf];
				
				If ValueIsFilled(LaborCosts[IndexOf].Count) Then
					LaborCosts[IndexOf].Price = LaborCosts[IndexOf].Sum / LaborCosts[IndexOf].Count;
				Else
					LaborCosts[IndexOf].Price = 0;
				EndIf;
				
			EndIf;
			
			If Not ResultOfLocalDistribution = Undefined Then
				LaborCosts[IndexOf].SumCompl = LaborCosts[IndexOf].SumCompl + ResultOfLocalDistribution[IndexOf];
			EndIf;
			
			If Not PDDistributionResult = Undefined Then
				LaborCosts[IndexOf].AmountPermanentDifferences = LaborCosts[IndexOf].AmountPermanentDifferences + PDDistributionResult[IndexOf];
			EndIf;
			
			If Not ResultOfTDDistribution = Undefined Then
				LaborCosts[IndexOf].AmountTemporaryDifferences = LaborCosts[IndexOf].AmountTemporaryDifferences + ResultOfTDDistribution[IndexOf];
			EndIf;
			
		EndDo;
		
	EndDo;
	#EndRegion
	
	#Region OtherExpenseAllocation
	AllocationBase = QueryResult[UBound].Unload();
	
	BaseColumns = New Map;
	BaseColumns.Insert(Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts, "UsedMaterials");
	BaseColumns.Insert(Enums.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts, "MaterialsLaborCosts");
	BaseColumns.Insert(Enums.RulesOfCostAllocationToProductCost.ByLaborCosts, "LaborCosts");
	
	For Each CurConsumption In OtherExpenses Do
		
		NameOfColumnWithManDatabase = BaseColumns.Get(CurConsumption.RuleOfCostAllocatingToProductionLotsMan);
		If NameOfColumnWithManDatabase = Undefined Then
			NameOfColumnWithManDatabase = "MaterialsLaborCosts";
		EndIf;
		
		NameOfColumnWithLocalDatabase = BaseColumns.Get(CurConsumption.RuleOfCostAllocatingToProductionLotsLocal);
		If NameOfColumnWithLocalDatabase = Undefined Then
			NameOfColumnWithLocalDatabase = "MaterialsLaborCosts";
		EndIf;
		
		ManCoefficients = AllocationBase.UnloadColumn(NameOfColumnWithManDatabase);
		LocalCoefficients = AllocationBase.UnloadColumn(NameOfColumnWithLocalDatabase);
		
		AllocationResult		=
			DistributeAmountInProportionToCoefficients(CurConsumption.Sum, ManCoefficients);
		ResultOfLocalDistribution	=
			DistributeAmountInProportionToCoefficients(CurConsumption.SumCompl, LocalCoefficients);
		PDDistributionResult	=
			DistributeAmountInProportionToCoefficients(CurConsumption.AmountPermanentDifferences, LocalCoefficients);
		ResultOfTDDistribution	=
			DistributeAmountInProportionToCoefficients(CurConsumption.AmountTemporaryDifferences, LocalCoefficients);
			
		MaxIndex = AllocationBase.Count() - 1;
		For IndexOf = 0 To MaxIndex Do
			
			NewRow = OtherExpensesNew.Add();
			FillPropertyValues(NewRow, CurConsumption,, "Sum,SumCompl,AmountPermanentDifferences,AmountTemporaryDifferences");
			
			NewRow.ProductionLot	= AllocationBase[IndexOf].ProductionLot;
			
			If Not AllocationResult = Undefined Then
				NewRow.Sum = AllocationResult[IndexOf];
			EndIf;
			
			If Not ResultOfLocalDistribution = Undefined Then
				NewRow.SumCompl = ResultOfLocalDistribution[IndexOf];
			EndIf;
			
			If Not PDDistributionResult = Undefined Then
				NewRow.AmountPermanentDifferences = PDDistributionResult[IndexOf];
			EndIf;
			
			If Not ResultOfTDDistribution = Undefined Then
				NewRow.AmountTemporaryDifferences = ResultOfTDDistribution[IndexOf];
			EndIf;
			
		EndDo;
		
	EndDo;
	
	#EndRegion
	
	// StandardSubsystems.PerformanceMeasurement
	OperationsCount = MaterialsAndWorks.Count() + LaborCosts.Count() + OtherExpensesNew.Count();
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, OperationsCount / 10000);
	// End StandardSubsystems.PerformanceMeasurement
	
	Result = New Structure;
	Result.Insert("HeaderAttributes",		DocumentAttributes);
	Result.Insert("MaterialsAndWorks",		MaterialsAndWorks);
	Result.Insert("LaborCosts",			LaborCosts);
	Result.Insert("OtherExpenses",			OtherExpensesNew);
	
	If ResultAddress = Undefined Then
		Return Result;
	Else
		PutToTempStorage(Result, ResultAddress);
		Return Undefined;
	EndIf;
	
EndFunction

// Returns errors in the distribution of cost balances by production batch.
//
//	Parameters:
//		Ref - DocumentRef.InitialWIPBalancesByBusinessUnits - link to the document whose costs should be allocated.
//
//	Returns:
//		Structure - errors in the distribution of cost balances by production batches.
//
Function ErrorsInAllocatioOfWIPCostBalances(Ref) Export
	
	AttributesList =
		"CostsAccountingProcedure, Date, Department,
		|Organization, PriceKind, LineOfBusiness";
	
	DocumentAttributes = Common.ObjectAttributesValues(Ref, AttributesList);
	
	Query = New Query;
	Query.Text = StrConcat(ErrorRequestTextsInUnfinishedProductionBalanceDistributionData(DocumentAttributes.Date), Common.QueryBatchSeparator());
	
	Query.SetParameter("Ref",						Ref);
	Query.SetParameter("DateOfRemainingGoods",				DocumentAttributes.Date);
	Query.SetParameter("Organization",				DocumentAttributes.Organization);
	Query.SetParameter("Department",				DocumentAttributes.Department);
	Query.SetParameter("CostsAccountingProcedure",			DocumentAttributes.CostsAccountingProcedure);
	Query.SetParameter("LineOfBusiness",	DocumentAttributes.LineOfBusiness);
	Query.SetParameter("PriceKind",					DocumentAttributes.PriceKind);
	Query.SetParameter("CurrencyOfTypesOfWork",			Constants.CurrencyOfActivityKindRates.Get());
	Query.SetParameter("CurrencyOfManAccounting",				Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentAttributes.Organization));
	QueryResult = Query.Execute();
	
	Result = New Structure;
	Result.Insert("ErrorsInDistributionOfUnfinishedProductionResidues", QueryResult.Unload());
	
	Return Result;
	
EndFunction

// Returns the amount distributed over the transmitted coefficients.
// Distribution uses a method that recalculates the distribution base at each step,
// which results in a distribution with no remainder.
//
//	Parameters:
//		AmountToDistribute	- Number - amount to be distributed.
//		Coefficients		- Array - array of coefficients.
//		Accuracy			- Number - bit depth of the distribution result.
//
//	Returns:
//		Array - the result of the distribution.
//
Function DistributeAmountInProportionToCoefficients(Val AmountToDistribute, Val Coefficients, Val Accuracy = 2) Export
	
	If Not ValueIsFilled(AmountToDistribute) Then
		Return Undefined;
	EndIf;
	
	RowsCount = Coefficients.Count();
	
	If RowsCount = 0 Then
		// The value of the Coefficients parameter is invalid
		// Expected: at least one coefficient will be set.
		Return Undefined;
	EndIf;
	
	CoefficientsSum = 0;
	
	For IndexOf = 0 To RowsCount - 1 Do
		ZoomRatio = Coefficients[IndexOf];
		CoefficientsSum = CoefficientsSum + ZoomRatio;
	EndDo;
	
	If CoefficientsSum = 0 Then
		// The value of the Coefficients parameter is invalid
		// Expected: The sum of the coefficients is different from zero.
		Return Undefined;
	EndIf;
	
	Result = New Array(RowsCount);
	RemainsToAllocate = AmountToDistribute;
	
	For IndexOf = 0 To RowsCount - 1 Do
		Result[IndexOf] = Round(RemainsToAllocate * Coefficients[IndexOf] / CoefficientsSum, Accuracy, 1);
		RemainsToAllocate = RemainsToAllocate - Result[IndexOf];
		CoefficientsSum = CoefficientsSum - Coefficients[IndexOf];
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("DocumentsRegistry");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.InitialWIPBalancesByBusinessUnits") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region ArticleSelectionAndAnalytics

Function ItemsAndDimensionsSelectionParameters() Export
	
	// Output items
	ArticleSelectionOptions = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ArticleSelectionOptions.DataPath					= "Object.Costs";
	ArticleSelectionOptions.AssetRef						= "ExpenseItem";
	ArticleSelectionOptions.ArticleType					= "ArticleType";
	
	ArticleSelectionOptions.ChoosingExpenseItem			= True;
	ArticleSelectionOptions.DimensionOfExpenses			= "DimensionOfExpenses";
	
	FormItems = ArticleSelectionOptions.FormItems;
	FormItems.AssetRef.Add("CostsExpenseItem");
	FormItems.DimensionOfExpenses.Add("CostsDimensionOfExpenses");
	
	CostTypes = New Array;
	CostTypes.Add(Enums.CostTypes.Depreciation);
	CostTypes.Add(Enums.CostTypes.Other);
	
	AttributesAvailability = New Structure;
	AttributesAvailability.Insert("ExpenseType", CostTypes);
	
	ArticleSelectionOptions.ArticleAvailabilityCriteriaInLines = AttributesAvailability;
	
	Return ArticleSelectionOptions;
	
EndFunction

#EndRegion

#Region StandardCommandSubsystems

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.WIPOpeningBalancesByProductionLots.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command to create the document "Initial WIP balances by Department".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.InitialWIPOpeningBalancesAllocationAnalysis.AddReportCommand(ReportsCommands);
	Reports.ErrorsInAllocatioOfWIPCostBalances.AddReportCommand(ReportsCommands);
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)";
	
EndProcedure


#Region DownloadingFromVHFFile

// Sets the download parameters.
//
// Parameters:
//   Parameters - Structure - download parameters from a file.
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
	
	ColumnDataType = Parameters.ColumnDataType;
	
	ColumnDataType.Insert("CodeExternal",						New TypeDescription("String",,	New StringQualifiers(11)));
	ColumnDataType.Insert("NameExternal",			New TypeDescription("String",,	New StringQualifiers(1024)));
	ColumnDataType.Insert("ExpenseType",						New TypeDescription("String",,	New StringQualifiers(20)));
	ColumnDataType.Insert("NameOfCalculationArticle",	New TypeDescription("String",,	New StringQualifiers(100)));
	ColumnDataType.Insert("Sum",							New TypeDescription("Number",,	New NumberQualifiers(15, 2)));
	
EndProcedure

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
// 	AddressOfUploadedData- String - address of the temporary storage with a table of values that
//                                   contains the downloaded data from the file.
// 	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                       which is a copy of the table part of the document 
//                                       that needs to be filled in from the addressable Data table.
// 	ConflictsList - ValueTable - consists of:
//  * Id - Number - Id
//  * Column - String - column name
// 	FullTabularSectionName - String - full name of the table part
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	Costs				= GetFromTempStorage(AddressOfMappingTable); // ValueTable
	DataToImport	= GetFromTempStorage(AddressOfUploadedData);
	
	QueryText =
	"SELECT
	|	DataToImport.CodeExternal					AS CodeExternal,
	|	DataToImport.NameExternal			AS NameExternal,
	|	CASE
	|		WHEN DataToImport.ExpenseType = &MaterialCosts
	|			THEN VALUE(Enum.CostTypes.Material_)
	|		WHEN DataToImport.ExpenseType = &RecyclableWaste
	|			THEN VALUE(Enum.CostTypes.RecyclableWaste)
	|		WHEN DataToImport.ExpenseType = &LaborCosts
	|			THEN VALUE(Enum.CostTypes.Payroll)
	|		WHEN DataToImport.ExpenseType = &Depreciation
	|			THEN VALUE(Enum.CostTypes.Depreciation)
	|		WHEN DataToImport.ExpenseType = &OtherItems
	|			THEN VALUE(Enum.CostTypes.Other)
	|		ELSE VALUE(Enum.CostTypes.EmptyRef)
	|	END											AS ExpenseType,
	|	DataToImport.NameOfCalculationArticle	AS NameOfCalculationArticle,
	|	DataToImport.Sum							AS Sum,
	|	DataToImport.Id					AS Id
	|INTO DataToImport
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpenseItems.Id						AS Id,
	|	MAX(ExpenseItems.ExpenseItem)				AS ExpenseItem,
	|	MAX(ExpenseItems.ProductCostElement)			AS ProductCostElement,
	|	COUNT(DISTINCT ExpenseItems.ExpenseItem)	AS NumberOfArticles
	|INTO ExpenseItems
	|FROM
	|	(SELECT
	|		DataToImport.Id				AS Id,
	|		ExpenseItems.Ref						AS ExpenseItem,
	|		ExpenseItems.ProductCostElement			AS ProductCostElement
	|	FROM
	|		DataToImport AS DataToImport
	|		
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Code = DataToImport.CodeExternal
	|
	|	WHERE
	|		DataToImport.ExpenseType IN (VALUE(Enum.CostTypes.Depreciation),
	|										VALUE(Enum.CostTypes.Other))
	|		AND NOT DataToImport.CodeExternal = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id				AS Id,
	|		ExpenseItems.Ref						AS ExpenseItem,
	|		ExpenseItems.ProductCostElement			AS ProductCostElement
	|	FROM
	|		DataToImport AS DataToImport
	|		
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Description = DataToImport.NameExternal
	|
	|	WHERE
	|		DataToImport.ExpenseType IN (VALUE(Enum.CostTypes.Depreciation),
	|										VALUE(Enum.CostTypes.Other))
	|		AND NOT DataToImport.NameExternal = """"
	|	) AS ExpenseItems
	|
	|GROUP BY
	|	ExpenseItems.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id					AS Id,
	|	MAX(ProductCostElements.Ref)				AS ProductCostElement,
	|	COUNT(DISTINCT ProductCostElements.Ref)	AS NumberOfArticles
	|INTO ProductCostElements
	|FROM
	|	DataToImport AS DataToImport
	|	
	|	LEFT JOIN Catalog.ProductCostElements AS ProductCostElements
	|	ON ProductCostElements.Description = DataToImport.NameOfCalculationArticle
	|
	|WHERE
	|	DataToImport.ExpenseType IN (VALUE(Enum.CostTypes.Depreciation),
	|									VALUE(Enum.CostTypes.Other))
	|	AND NOT DataToImport.NameOfCalculationArticle = """"
	|
	|GROUP BY
	|	DataToImport.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id					AS Id,
	|	DataToImport.CodeExternal					AS CodeExternal,
	|	DataToImport.NameExternal			AS NameExternal,
	|	DataToImport.ExpenseType						AS ExpenseType,
	|	CASE
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			THEN ExpenseItems.ExpenseItem
	|		ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	END											AS ExpenseItem,
	|	CASE
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			AND ExpenseItems.ExpenseItem.CostAllocationRuleManag.BaseOfAllocationByLots IN
	|				(VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount),
	|				VALUE(Enum.TypesOfCostAllocatingBase.StandardMaterialConsumption),
	|				VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials),
	|				VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials),
	|				VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials))
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts)
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			AND ExpenseItems.ExpenseItem.CostAllocationRuleManag.BaseOfAllocationByLots IN
	|				(VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses),
	|				VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds),
	|				VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel),
	|				VALUE(Enum.TypesOfCostAllocatingBase.WorkPerformanceDuration))
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts)
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			AND ExpenseItems.ExpenseItem.CostAllocationRuleManag.BaseOfAllocationByLots =
	|				VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts)
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			AND ExpenseItems.ExpenseItem.CostAllocationRuleManag.BaseOfAllocationByLots IN
	|				(VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases),
	|				VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases),
	|				VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases),
	|				VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases))
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases)
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByProducts)
	|		ELSE VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef)
	|	END											AS RuleOfCostAllocatingToProductionLotsMan,
	|	CASE
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			AND ExpenseItems.ExpenseItem.CostAllocationRuleLocal.BaseOfAllocationByLots IN
	|				(VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount),
	|				VALUE(Enum.TypesOfCostAllocatingBase.StandardMaterialConsumption),
	|				VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials),
	|				VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials),
	|				VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials))
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts)
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			AND ExpenseItems.ExpenseItem.CostAllocationRuleLocal.BaseOfAllocationByLots IN
	|				(VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses),
	|				VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds),
	|				VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel),
	|				VALUE(Enum.TypesOfCostAllocatingBase.WorkPerformanceDuration))
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts)
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			AND ExpenseItems.ExpenseItem.CostAllocationRuleLocal.BaseOfAllocationByLots =
	|				VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts)
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			AND ExpenseItems.ExpenseItem.CostAllocationRuleLocal.BaseOfAllocationByLots IN
	|				(VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases),
	|				VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases),
	|				VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases),
	|				VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases))
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases)
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByProducts)
	|		ELSE VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef)
	|	END											AS RuleOfCostAllocatingToProductionLotsLocal,
	|	CASE
	|		WHEN ISNULL(ProductCostElements.NumberOfArticles, 0) = 1
	|			THEN ProductCostElements.ProductCostElement
	|		WHEN ISNULL(ExpenseItems.NumberOfArticles, 0) = 1
	|			THEN ExpenseItems.ProductCostElement
	|		ELSE VALUE(Catalog.ProductCostElements.EmptyRef)
	|	END											AS ProductCostElement,
	|	ISNULL(ExpenseItems.NumberOfArticles, 0)	AS NumberOfExpenditureItems,
	|	ISNULL(ProductCostElements.NumberOfArticles, 0)	AS NumberOfCalculationArticles,
	|	DataToImport.Sum							AS Sum
	|FROM
	|	DataToImport AS DataToImport
	|	
	|	LEFT JOIN ExpenseItems AS ExpenseItems
	|	ON ExpenseItems.Id = DataToImport.Id
	|	
	|	LEFT JOIN ProductCostElements AS ProductCostElements
	|	ON ProductCostElements.Id = DataToImport.Id
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataToImport",		DataToImport);
	Query.SetParameter("MaterialCosts",	NStr("vi = 'Nguyên vật liệu';
												|ru = 'Материальные';
												|en = 'Material'; fa = 'ماده';
												|it = 'Materiali';
												|pl = 'Material';
												|tr = 'Malzeme'"));
	Query.SetParameter("RecyclableWaste",		NStr("vi = 'Phế liệu thu hồi';
														|ru = 'Возвратные отходы';
														|en = 'Recyclable waste'; fa = 'ضایعات قابل بازیافت';
														|it = 'Scarti riciclabili';
														|pl = 'Odpady i półprodukty';
														|tr = 'Geri dönüştürülebilir atık'"));
	Query.SetParameter("LaborCosts",			NStr("vi = 'Công lao động';
													|ru = 'Трудозатраты';
													|en = 'Labor costs'; fa = 'هزینه‌های دستمزد';
													|it = 'Costi di manodopera';
													|pl = 'Labor costs';
													|tr = 'İş gücü maliyetleri'"));
	Query.SetParameter("Depreciation",			NStr("vi = 'Khấu hao';
														|ru = 'Амортизация';
														|en = 'Depreciation'; fa = 'استهلاک';
														|it = 'Ammortamento';
														|pl = 'Depreciation';
														|tr = 'Amortisman'"));
	Query.SetParameter("OtherItems",					NStr("vi = 'Phần khác';
															|ru = 'Прочие';
															|en = 'Other'; fa = 'سایر';
															|it = 'Altri';
															|pl = 'Other';
															|tr = 'Diğer'"));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = Costs.Add();
		FillPropertyValues(NewRow, Selection,, "Sum");
		NewRow.Sum = Number(Selection.Sum);
		
		If Selection.NumberOfExpenditureItems > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "ExpenseItem";
		EndIf;
		
		If Selection.NumberOfCalculationArticles > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "ProductCostElement";
		EndIf;
		
	EndDo;
	
	PutToTempStorage(Costs, AddressOfMappingTable);
	
EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
// 
// Parameters:
// 	FullTabularSectionName- String - full name of the table part where data is loaded.
// 	ConflictsList - Array - list of ambiguities.
// 	ColumnName - String - name of the column where the ambiguity occurs.
// 	LoadedValuesString - String - Loaded data based on which the ambiguity occurred.
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export 
	
	If ColumnName = "ExpenseItem" Then
		
		QueryText =
		"SELECT
		|	ExpenseItems.Ref AS Ref
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|WHERE
		|	&MatchingCondition";
		
		MatchingCondition = New Array;
		MatchingCondition.Add("FALSE");
		
		If ValueIsFilled(LoadedValuesString.CodeExternal) Then
			MatchingCondition.Add("ExpenseItems.Code = &CodeExternal");
		EndIf;
		
		If ValueIsFilled(LoadedValuesString.NameExternal) Then
			MatchingCondition.Add("ExpenseItems.Description = &NameExternal");
		EndIf;
		
		ConditionText = StrConcat(MatchingCondition, Chars.LF + "OR ");
		QueryText = StrReplace(QueryText, "&MatchingCondition", ConditionText);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Query.SetParameter("CodeExternal",				LoadedValuesString.CodeExternal);
		Query.SetParameter("NameExternal",	LoadedValuesString.NameExternal);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
		
	EndIf;
	
	If ColumnName = "ProductCostElement" Then
		
		QueryText =
		"SELECT DISTINCT
		|	ProductCostElements.Ref AS Ref
		|FROM
		|	Catalog.ProductCostElements AS ProductCostElements
		|WHERE
		|	&MatchingCondition
		|";
		
		MatchingCondition = New Array;
		MatchingCondition.Add("FALSE");
		
		If ValueIsFilled(LoadedValuesString.NameOfCalculationArticle) Then
			MatchingCondition.Add("ProductCostElements.Description = &NameOfCalculationArticle");
		EndIf;
		
		ConditionText = StrConcat(MatchingCondition, Chars.LF + "OR ");
		QueryText = StrReplace(QueryText, "&MatchingCondition", ConditionText);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Query.SetParameter("NameOfCalculationArticle", LoadedValuesString.NameOfCalculationArticle);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region Posting

#Region Initialize

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)

	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);

	Query.Text =
	"SELECT
	|	Attributes.Date						AS Date,
	|	Attributes.Number						AS Number,
	|	Attributes.Ref					AS Ref,
	|	Attributes.Posted					AS Posted,
	|	Attributes.DeletionMark			AS DeletionMark,
	|	Attributes.Organization				AS Organization,
	|	Attributes.Department				AS Department,
	|	Attributes.LineOfBusiness	AS LineOfBusiness,
	|	Attributes.DocumentAmount			AS DocumentAmount,
	|	Attributes.EmployeeResponsible				AS EmployeeResponsible,
	|	Attributes.Comment				AS Comment
	|FROM
	|	Document.InitialWIPBalancesByBusinessUnits AS Attributes
	|WHERE
	|	Attributes.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("MetadataIdentifier",
							Common.MetadataObjectID(Type("DocumentRef.InitialWIPBalancesByBusinessUnits")));
								
	Query.SetParameter("NumberForPrinting",	ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("CurrencyOfMan",		Constants.ManagementAccountingCurrency.Get());
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.InitialWIPBalancesByBusinessUnits";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Undefined, QueryTexts, Undefined);
		RequestHasSource	= False;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện điều chỉnh nội dung truy vấn 
								|tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
								|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса 
								|формирования движений по регистру %RegisterName%.';
								|en = 'In the %FullDocumentName% document, adaptation of request for generating records 
								|of the %RegisterName% register is not implemented.'; fa = 'In the %FullDocumentName% document, adaptation of request for generating records 
								|of the %RegisterName% register is not implemented.';
								|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento del testo di richiesta 
								|della generazione dei movimenti sul registro%RegisterName%.';
								|pl = 'W dokumencie %FullDocumentName%nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów 
								| w rejestrze %RegisterName%.';
								|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi 
								|talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region TextsOfRequestsForHolding

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref									AS Ref,
	|	UNDEFINED							AS RecordSeparator,
	|	&Date									AS IBDocumentDate,
	|	&Number									AS IBDocumentNumber,
	|	&MetadataIdentifier				AS RefType,
	|	&Organization							AS Organization,
	|	VALUE(Enum.BusinessTransactions.OBEntryProductionLotCosts) AS BusinessOperation,
	|	&LineOfBusiness				AS LineOfBusiness,
	|	&Department							AS Department,
	|	&EmployeeResponsible							AS EmployeeResponsible,
	|	CAST(&Comment AS STRING(100))	AS Comment,
	|	&CurrencyOfMan								AS Currency,
	|	&DocumentAmount							AS Sum,
	|	&Posted								AS Posted,
	|	&DeletionMark						AS DeletionMark,
	|	FALSE									AS AdditionalRecord,
	|	""""									AS More,
	|	&Date									AS SourceDocumentDate,
	|	&NumberForPrinting							AS SourceDocumentNumber,
	|	&Department							AS StorageLocation,
	|	FALSE									AS ReverseTransactionCorrection,
	|	UNDEFINED							AS ReversedDocument,
	|	UNDEFINED							AS CorrectedDocument,
	|	&Date									AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region DistributionByParty

Function CostAllocationRequestTexts(PriceDate)
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(PriceDate);

	QueryTexts = New Array;
	
	// Document data
	QueryTexts.Add(QueryTextTableTTCosts());
	QueryTexts.Add(RequestTextTableMaterialCostsOfDocument());
	QueryTexts.Add(RequestTextTableDocumentLaborCosts());
	QueryTexts.Add(RequestTextTableOtherDocumentExpenses());
	
	// Data of rolling batches
	QueryTexts.Add(QueryTextTableUnfinishedBatches());
	QueryTexts.Add(QueryTextTableTransferringParties());
	
	// Data for the cost accounting procedure "By current location"
	QueryTexts.Add(QueryTextTableTransitionalStages());
	QueryTexts.Add(QueryTextTableDatesOfExtremeCompletedStages());
	QueryTexts.Add(QueryTextTableExtremeCompletedStages());
	QueryTexts.Add(QueryTextTableStepsByCurProcessingLocation());
	QueryTexts.Add(QueryTextTTErrorsOfParallelismOfStages());
	
	// Data for the cost accounting procedure "At the place of issue"
	QueryTexts.Add(QueryTextTableReleasingStages());
	
	// The final list of stages included in the distribution database
	QueryTexts.Add(QueryTextTableDistributionBaseStages());
	
	// Distribution database data
	QueryTexts.Add(QueryTextTableMaterialsOfPreparatoryStages(UsePriceManagementSystem25));
	If UsePriceManagementSystem25 Then
		QueryTexts.Add(QueryTextTableMaterialsOfStagesPreparatoryTSO25());
	EndIf;
	QueryTexts.Add(QueryTextTableTTStageMaterials(UsePriceManagementSystem25));
	QueryTexts.Add(QueryTextTableTTLaborCostsOfStages());
	QueryTexts.Add(QueryTextTableStageMaterials_());
	QueryTexts.Add(QueryTextTableLaborCostsOfStages());
	QueryTexts.Add(RequestTextTableMaterialsLaborCostsStages());
	
	Return QueryTexts;
	
EndFunction

Function ErrorRequestTextsInUnfinishedProductionBalanceDistributionData(PriceDate)
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(PriceDate);

	QueryTexts = New Array;
	
	// Data of rolling batches
	QueryTexts.Add(QueryTextTableUnfinishedBatches());
	QueryTexts.Add(QueryTextTableTransferringParties());
	
	// Data for the cost accounting procedure "By current location"
	QueryTexts.Add(QueryTextTableTransitionalStages());
	QueryTexts.Add(QueryTextTableDatesOfExtremeCompletedStages());
	QueryTexts.Add(QueryTextTableExtremeCompletedStages());
	QueryTexts.Add(QueryTextTableStepsByCurProcessingLocation());
	QueryTexts.Add(QueryTextTTErrorsOfParallelismOfStages());
	
	// Data for the cost accounting procedure "At the place of issue"
	QueryTexts.Add(QueryTextTableReleasingStages());
	
	// The final list of stages included in the distribution database
	QueryTexts.Add(QueryTextTableDistributionBaseStages());
	
	// Distribution database data
	QueryTexts.Add(QueryTextTableMaterialsOfPreparatoryStages(UsePriceManagementSystem25));
	If UsePriceManagementSystem25 Then
		QueryTexts.Add(QueryTextTableMaterialsOfStagesPreparatoryTSO25());
	EndIf;
	QueryTexts.Add(QueryTextTableTTStageMaterials(UsePriceManagementSystem25));
	QueryTexts.Add(QueryTextTableTTLaborCostsOfStages());
	
	// Errors in the data the distribution of the residuals WIP
	QueryTexts.Add(QueryTextErrorsInAllocatioOfWIPCostBalances());
	
	Return QueryTexts;
	
EndFunction

Function QueryTextTableTTCosts()
	
	QueryText =
	"SELECT
	|	Costs.Ref						AS Ref,
	|	Costs.LineNumber					AS LineNumber,
	|	Costs.CodeExternal					AS CodeExternal,
	|	Costs.NameExternal			AS NameExternal,
	|	Costs.ExpenseType					AS ExpenseType,
	|	Costs.Ref.Department		AS Department,
	|	Costs.ExpenseItem				AS ExpenseItem,
	|	Costs.DimensionOfExpenses			AS DimensionOfExpenses,
	|	Costs.ProductCostElement			AS ProductCostElement,
	|	Costs.RuleOfCostAllocatingToProductionLotsMan	AS RuleOfCostAllocatingToProductionLotsMan,
	|	Costs.RuleOfCostAllocatingToProductionLotsLocal AS RuleOfCostAllocatingToProductionLotsLocal,
	|	Costs.Sum						AS Sum,
	|	Costs.SumCompl					AS SumCompl,
	|	Costs.AmountPermanentDifferences						AS AmountPermanentDifferences,
	|	Costs.AmountTemporaryDifferences						AS AmountTemporaryDifferences
	|INTO TTCosts
	|FROM
	|	Document.InitialWIPBalancesByBusinessUnits.Costs AS Costs
	|WHERE
	|	Costs.Ref = &Ref
	|
	|INDEX BY
	|	Costs.ExpenseType
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextTableMaterialCostsOfDocument()
	
	QueryText =
	"SELECT
	|	SUM(Costs.Sum)		AS Sum,
	|	SUM(Costs.SumCompl)	AS SumCompl,
	|	SUM(Costs.AmountPermanentDifferences)		AS AmountPermanentDifferences,
	|	SUM(Costs.AmountTemporaryDifferences)		AS AmountTemporaryDifferences
	|FROM
	|	TTCosts AS Costs
	|WHERE
	|	Costs.ExpenseType IN (VALUE(Enum.CostTypes.Material_),
	|						VALUE(Enum.CostTypes.RecyclableWaste))
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextTableDocumentLaborCosts()
	
	QueryText =
	"SELECT
	|	SUM(Costs.Sum)		AS Sum,
	|	SUM(Costs.SumCompl)	AS SumCompl,
	|	SUM(Costs.AmountPermanentDifferences)		AS AmountPermanentDifferences,
	|	SUM(Costs.AmountTemporaryDifferences)		AS AmountTemporaryDifferences
	|FROM
	|	TTCosts AS Costs
	|WHERE
	|	Costs.ExpenseType = VALUE(Enum.CostTypes.Payroll)
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextTableOtherDocumentExpenses()
	
	QueryText =
	"SELECT
	|	""OtherItems""							AS ExpenseType,
	|	VALUE(Catalog.ProductionLots.EmptyRef) AS ProductionLot,
	|	Costs.LineNumber					AS LineNumber,
	|	Costs.Department				AS Department,
	|	Costs.ExpenseItem				AS ExpenseItem,
	|	Costs.ExpenseItem				AS Cost_,
	|	Costs.DimensionOfExpenses			AS DimensionOfExpenses,
	|	Costs.ProductCostElement			AS ProductCostElement,
	|	Costs.RuleOfCostAllocatingToProductionLotsMan	AS RuleOfCostAllocatingToProductionLotsMan,
	|	Costs.RuleOfCostAllocatingToProductionLotsLocal AS RuleOfCostAllocatingToProductionLotsLocal,
	|	Costs.Sum						AS Sum,
	|	0									AS Base,
	|	Costs.SumCompl					AS SumCompl,
	|	0									AS AmountFA,
	|	Costs.AmountPermanentDifferences						AS AmountPermanentDifferences,
	|	Costs.AmountTemporaryDifferences						AS AmountTemporaryDifferences
	|FROM
	|	TTCosts AS Costs
	|WHERE
	|	Costs.ExpenseType IN (VALUE(Enum.CostTypes.Depreciation),
	|						VALUE(Enum.CostTypes.Other))
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableUnfinishedBatches()
	
	QueryText =
	"SELECT
	|	ProductionLots.ProductionLot AS ProductionLot
	|INTO UnfinishedBatches
	|FROM
	|	(SELECT
	|		StageDetails.ProductionLot AS ProductionLot
	|	FROM
	|		Document.ProductionStage2_2 AS StageDetails
	|	WHERE
	|		StageDetails.Posted
	|		AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|		AND NOT StageDetails.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|		AND StageDetails.Organization = &Organization
	|		AND (&LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			OR StageDetails.LineOfBusiness = &LineOfBusiness)
	|		AND StageDetails.ActualStageEnd = DATETIME(1, 1, 1)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		StageDetails.ProductionLot AS ProductionLot
	|	FROM
	|		Document.ProductionStage2_2 AS StageDetails
	|	WHERE
	|		StageDetails.Posted
	|		AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|		AND NOT StageDetails.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|		AND StageDetails.Organization = &Organization
	|		AND (&LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			OR StageDetails.LineOfBusiness = &LineOfBusiness)
	|		AND StageDetails.ActualStageEnd > ENDOFPERIOD(&DateOfRemainingGoods, MONTH)
	|	) AS ProductionLots
	|
	|GROUP BY
	|	ProductionLots.ProductionLot
	|
	|INDEX BY
	|	ProductionLot
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTransferringParties()
	
	QueryText =
	"SELECT
	|	UnfinishedBatches.ProductionLot AS ProductionLot
	|INTO TransferringParties
	|FROM
	|	UnfinishedBatches AS UnfinishedBatches
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|	ON StageDetails.ProductionLot = UnfinishedBatches.ProductionLot
	|	AND NOT StageDetails.ActualStageStart = DATETIME(1, 1, 1)
	|	AND StageDetails.ActualStageStart <= ENDOFPERIOD(&DateOfRemainingGoods, MONTH)
	|
	|WHERE
	|	StageDetails.Posted
	|	AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|
	|GROUP BY
	|	UnfinishedBatches.ProductionLot
	|
	|INDEX BY
	|	ProductionLot
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTransitionalStages()
	
	QueryText =
	"SELECT
	|	TransferringParties.ProductionLot	AS ProductionLot,
	|	TransferringParties.Stage					AS Stage,
	|	TransferringParties.Department			AS Department
	|INTO TransitionalStages
	|FROM
	|	(SELECT
	|		TransferringParties.ProductionLot	AS ProductionLot,
	|		StageDetails.Ref					AS Stage,
	|		StageDetails.Department			AS Department
	|	FROM
	|		TransferringParties AS TransferringParties
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|		ON StageDetails.ProductionLot = TransferringParties.ProductionLot
	|
	|	WHERE
	|		&CostsAccountingProcedure =
	|			VALUE(Enum.CostsAccountingProcedureInExternalSystem.ByCurrentLotLocation)
	|		AND StageDetails.Posted
	|		AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|		AND NOT StageDetails.ActualStageStart = DATETIME(1, 1, 1)
	|		AND StageDetails.ActualStageStart <= ENDOFPERIOD(&DateOfRemainingGoods, MONTH)
	|		AND StageDetails.ActualStageEnd >= ENDOFPERIOD(&DateOfRemainingGoods, MONTH)
	|
	|	UNION ALL
	|
	|	SELECT
	|		TransferringParties.ProductionLot	AS ProductionLot,
	|		StageDetails.Ref					AS Stage,
	|		StageDetails.Department			AS Department
	|	FROM
	|		TransferringParties AS TransferringParties
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|		ON StageDetails.ProductionLot = TransferringParties.ProductionLot
	|
	|	WHERE
	|		&CostsAccountingProcedure =
	|			VALUE(Enum.CostsAccountingProcedureInExternalSystem.ByCurrentLotLocation)
	|		AND StageDetails.Posted
	|		AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|		AND NOT StageDetails.ActualStageStart = DATETIME(1, 1, 1)
	|		AND StageDetails.ActualStageStart <= ENDOFPERIOD(&DateOfRemainingGoods, MONTH)
	|		AND StageDetails.ActualStageEnd = DATETIME(1, 1, 1)
	|	) AS TransferringParties
	|
	|GROUP BY
	|	TransferringParties.ProductionLot,
	|	TransferringParties.Stage,
	|	TransferringParties.Department
	|
	|INDEX BY
	|	ProductionLot
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfExtremeCompletedStages()
	
	QueryText =
	"SELECT
	|	TransferringParties.ProductionLot				AS ProductionLot,
	|	MAX(StageDetails.ActualStageEnd)	AS ExecutionDate
	|INTO DatesOfExtremeCompletedStages
	|FROM
	|	TransferringParties AS TransferringParties
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|	ON StageDetails.ProductionLot = TransferringParties.ProductionLot
	|	
	|	LEFT JOIN TransitionalStages AS TransitionalStages
	|	ON TransitionalStages.ProductionLot = TransferringParties.ProductionLot
	|
	|WHERE
	|	&CostsAccountingProcedure =
	|		VALUE(Enum.CostsAccountingProcedureInExternalSystem.ByCurrentLotLocation)
	|	AND StageDetails.Posted
	|	AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|	AND StageDetails.ActualStageEnd < ENDOFPERIOD(&DateOfRemainingGoods, MONTH)
	|	AND TransitionalStages.ProductionLot IS NULL
	|
	|GROUP BY
	|	TransferringParties.ProductionLot
	|
	|INDEX BY
	|	ProductionLot,
	|	ExecutionDate
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableExtremeCompletedStages()
	
	QueryText =
	"SELECT
	|	StageDetails.Ref AS Stage
	|INTO ExtremeCompletedStages
	|FROM
	|	DatesOfExtremeCompletedStages AS DatesOfExtremeCompletedStages
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|	ON StageDetails.ProductionLot = DatesOfExtremeCompletedStages.ProductionLot
	|	AND StageDetails.ActualStageEnd = DatesOfExtremeCompletedStages.ExecutionDate
	|
	|WHERE
	|	StageDetails.Posted
	|	AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|
	|GROUP BY
	|	StageDetails.Ref
	|
	|INDEX BY
	|	Stage
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableStepsByCurProcessingLocation()
	
	QueryText =
	"SELECT
	|	StepsByCurProcessingLocation.ProductionLot	AS ProductionLot,
	|	StepsByCurProcessingLocation.Stage					AS Stage,
	|	StepsByCurProcessingLocation.Department			AS Department
	|INTO StepsByCurProcessingLocation
	|FROM
	|	(SELECT
	|		TransitionalStages.ProductionLot	AS ProductionLot,
	|		TransitionalStages.Stage				AS Stage,
	|		TransitionalStages.Department		AS Department
	|	FROM
	|		TransitionalStages AS TransitionalStages
	|
	|	UNION ALL
	|
	|	SELECT
	|		StageDetails.ProductionLot	AS ProductionLot,
	|		StageDetails.Ref				AS Stage,
	|		StageDetails.Department		AS Department
	|	FROM
	|		ExtremeCompletedStages AS ExtremeCompletedStages
	|	
	|		INNER JOIN Document.ProductionStage2_2.Successors AS NextSteps_
	|		ON NextSteps_.Ref = ExtremeCompletedStages.Stage
	|	
	|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|		ON StageDetails.Ref = NextSteps_.Stage
	|
	|	WHERE
	|		StageDetails.Posted
	|		AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|	) AS StepsByCurProcessingLocation
	|
	|GROUP BY
	|	StepsByCurProcessingLocation.ProductionLot,
	|	StepsByCurProcessingLocation.Stage,
	|	StepsByCurProcessingLocation.Department
	|
	|INDEX BY
	|	ProductionLot,
	|	Stage
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTErrorsOfParallelismOfStages()
	
	QueryText =
	"SELECT
	|	StepsByCurProcessingLocation.ProductionLot AS ProductionLot
	|INTO TTErrorsOfParallelismOfStages
	|FROM
	|	StepsByCurProcessingLocation AS StepsByCurProcessingLocation
	|
	|GROUP BY
	|	StepsByCurProcessingLocation.ProductionLot
	|
	|HAVING
	|	COUNT(StepsByCurProcessingLocation.Stage) > 1
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableReleasingStages()
	
	QueryText =
	"SELECT DISTINCT
	|	TransferringParties.ProductionLot	AS ProductionLot,
	|	StageDetails.Ref					AS Stage,
	|	StageDetails.Department			AS Department
	|INTO ReleasingStages
	|FROM
	|	TransferringParties AS TransferringParties
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|	ON StageDetails.ProductionLot = TransferringParties.ProductionLot
	|	
	|	INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS TableProduction
	|	ON TableProduction.Ref = StageDetails.Ref
	|
	|WHERE
	|	&CostsAccountingProcedure =
	|		VALUE(Enum.CostsAccountingProcedureInExternalSystem.ByPlaceOfIssue)
	|	AND StageDetails.Posted
	|	AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|	AND StageDetails.Department = &Department
	|	AND NOT TableProduction.Canceled
	|
	|GROUP BY
	|	TransferringParties.ProductionLot,
	|	StageDetails.Ref,
	|	StageDetails.Department
	|
	|INDEX BY
	|	ProductionLot,
	|	Stage
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDistributionBaseStages()
	
	QueryText =
	"SELECT
	|	DistributionBaseStages.ProductionLot	AS ProductionLot,
	|	DistributionBaseStages.Department		AS Department,
	|	DistributionBaseStages.Stage					AS Stage,
	|	DistributionBaseStages.Purpose			AS Purpose
	|INTO DistributionBaseStages
	|FROM
	|	(
	// Stages by place of origin
	|	SELECT
	|		StageDetails.ProductionLot	AS ProductionLot,
	|		StageDetails.Ref				AS Stage,
	|		StageDetails.Department		AS Department,
	|		StageDetails.Purpose			AS Purpose
	|	FROM
	|		TransferringParties AS TransferringParties
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|		ON StageDetails.ProductionLot = TransferringParties.ProductionLot
	|
	|	WHERE
	|		&CostsAccountingProcedure =
	|			VALUE(Enum.CostsAccountingProcedureInExternalSystem.ByOrigin)
	|		AND StageDetails.Department = &Department
	|		AND StageDetails.Posted
	|		AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|
	|	UNION ALL
	|
	// Stages by the current location of the party
	|	SELECT
	|		StageDetails.ProductionLot			AS ProductionLot,
	|		StageDetails.Ref						AS Stage,
	|		StepsByCurProcessingLocation.Department	AS Department,
	|		StageDetails.Purpose					AS Purpose
	|	FROM
	|		StepsByCurProcessingLocation AS StepsByCurProcessingLocation
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS StageDetailsForCurProcessingLocation
	|		ON StageDetailsForCurProcessingLocation.Ref = StepsByCurProcessingLocation.Stage
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|		ON StageDetails.ProductionLot = StepsByCurProcessingLocation.ProductionLot
	|		AND StageDetails.ActualStageStart <= ENDOFPERIOD(&DateOfRemainingGoods, MONTH)
	|		
	|		LEFT JOIN TTErrorsOfParallelismOfStages AS StageConcurrencyErrors
	|		ON StageConcurrencyErrors.ProductionLot = StepsByCurProcessingLocation.ProductionLot
	|
	|	WHERE
	|		&CostsAccountingProcedure =
	|			VALUE(Enum.CostsAccountingProcedureInExternalSystem.ByCurrentLotLocation)
	|		AND StageDetails.Posted
	|		AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|		AND StepsByCurProcessingLocation.Department = &Department
	|		AND StageConcurrencyErrors.ProductionLot IS NULL
	|
	|	UNION ALL
	|
	// Stages at the place of release
	|	SELECT
	|		StageDetails.ProductionLot	AS ProductionLot,
	|		StageDetails.Ref				AS Stage,
	|		ReleasingStages.Department		AS Department,
	|		StageDetails.Purpose			AS Purpose
	|	FROM
	|		ReleasingStages AS ReleasingStages
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS DetailsOfIssuingStage
	|		ON DetailsOfIssuingStage.Ref = ReleasingStages.Stage
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|		ON StageDetails.ProductionLot = ReleasingStages.ProductionLot
	|		AND StageDetails.ActualStageStart <= ENDOFPERIOD(&DateOfRemainingGoods, MONTH)
	|
	|	WHERE
	|		&CostsAccountingProcedure =
	|			VALUE(Enum.CostsAccountingProcedureInExternalSystem.ByPlaceOfIssue)
	|		AND StageDetails.Posted
	|		AND NOT StageDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|	) AS DistributionBaseStages
	|	
	|GROUP BY
	|	DistributionBaseStages.ProductionLot,
	|	DistributionBaseStages.Stage,
	|	DistributionBaseStages.Department,
	|	DistributionBaseStages.Purpose
	|
	|INDEX BY
	|	ProductionLot,
	|	Stage
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableMaterialsOfPreparatoryStages(UsePriceManagementSystem25 = False)
	
	QueryText =
	"SELECT
	|	TableMaterials.ProductionLot							AS ProductionLot,
	|	TableMaterials.Department								AS Department,
	|	TableMaterials.InventoryOwnerAttribute									AS InventoryOwnerAttribute,
	|	TableMaterials.Products								AS Products,
	|	TableMaterials.Characteristic								AS Characteristic,
	|	TableMaterials.Series										AS Series,
	|	TableMaterials.ProductCostElement							AS ProductCostElement,
	|	TableMaterials.Purpose									AS Purpose,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)	AS Package,
	|	SUM(TableMaterials.Count)							AS Count,
	|	SUM(TableMaterials.Count)							AS NumberOfPackages
	|INTO MaterialsOfPreparatoryStages
	|FROM
	|	(
	// UsedMaterials
	|	SELECT
	|		DistributionBaseStages.ProductionLot							AS ProductionLot,
	|		DistributionBaseStages.Department								AS Department,
	|		CompanyGoods.CorInventoryOwnerAttribute										AS InventoryOwnerAttribute,
	|		CompanyGoods.CorItemsLocationAttributes.Products		AS Products,
	|		CompanyGoods.CorItemsLocationAttributes.Characteristic		AS Characteristic,
	|		CompanyGoods.CorItemsLocationAttributes.Series				AS Series,
	|		CompanyGoods.CorItemsLocationAttributes.Purpose			AS Purpose,
	|		CompanyGoods.CorItemsLocationAttributes.ProductCostElement	AS ProductCostElement,
	|		CompanyGoods.Count										AS Count
	|	FROM
	|		DistributionBaseStages AS DistributionBaseStages
	|	
	|		INNER JOIN AccumulationRegister.CompanyGoods AS CompanyGoods
	|		ON CompanyGoods.Recorder = DistributionBaseStages.Stage
	|		AND CompanyGoods.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND CompanyGoods.BusinessOperation =
	|			VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|		AND CompanyGoods.Period <= ENDOFPERIOD(&DateOfRemainingGoods, MONTH)
	|	
	|	WHERE
	|		NOT CompanyGoods.CorInventoryOwnerAttribute.InventoryType IN (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|														VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|														VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|
	|	UNION ALL
	|
	// Returnable waste
	|	SELECT
	|		DistributionBaseStages.ProductionLot					AS ProductionLot,
	|		DistributionBaseStages.Department						AS Department,
	|		VALUE(Catalog.InventoryKinds.EmptyRef)				AS InventoryOwnerAttribute,
	|		TableMaterials.ItemsLocationAttributes.Products	AS Products,
	|		TableMaterials.ItemsLocationAttributes.Characteristic	AS Characteristic,
	|		TableMaterials.ItemsLocationAttributes.Series			AS Series,
	|		DistributionBaseStages.Purpose							AS Purpose,
	|		TableMaterials.ProductCostElement							AS ProductCostElement,
	|		-TableMaterials.Count								AS Count
	|	FROM
	|		DistributionBaseStages AS DistributionBaseStages
	|	
	|		INNER JOIN Document.ProductionStage2_2.InventoryOwnerAttributesProducts AS TableMaterials
	|		ON TableMaterials.Ref = DistributionBaseStages.Stage
	|		AND TableMaterials.DateOfTransaction <= ENDOFPERIOD(&DateOfRemainingGoods, MONTH)
	|
	|	WHERE
	|		TableMaterials.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		AND NOT TableMaterials.InventoryOwnerAttribute.InventoryType IN (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|														VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|														VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|	) AS TableMaterials
	|	
	|GROUP BY
	|	TableMaterials.ProductionLot,
	|	TableMaterials.InventoryOwnerAttribute,
	|	TableMaterials.Products,
	|	TableMaterials.ProductCostElement,
	|	TableMaterials.Characteristic,
	|	TableMaterials.Series,
	|	TableMaterials.Department,
	|	TableMaterials.Purpose
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|";

	If UsePriceManagementSystem25 Then
		QueryText = StrReplace(QueryText, "MaterialsOfPreparatoryStages", "MaterialsOfBasicStages");
	EndIf;

	Return QueryText;
	
EndFunction

Function QueryTextTableMaterialsOfStagesPreparatoryTSO25()

	QueryText =
	"SELECT
	|	TableMaterials.ProductionLot AS ProductionLot,
	|	TableMaterials.Department AS Department,
	|	TableMaterials.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableMaterials.Products AS Products,
	|	TableMaterials.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		WHEN ItemsCharacteristics.Ref = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		ELSE ISNULL(ItemsCharacteristics.ItemsCharacteristicForPricing, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef))
	|	END AS PricingVariant,
	|	TableMaterials.Series AS Series,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|		WHEN TableMaterials.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|		ELSE ISNULL(TableMaterials.Series.ItemsBatchForPricing, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef))
	|	END AS PricingBatch,
	|	TableMaterials.ProductCostElement AS ProductCostElement,
	|	TableMaterials.Purpose AS Purpose,
	|	TableMaterials.Package AS Package,
	|	TableMaterials.Count AS Count,
	|	TableMaterials.Count AS NumberOfPackages
	|INTO MaterialsOfPreparatoryStages
	|FROM
	|	MaterialsOfBasicStages AS TableMaterials
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON TableMaterials.Products = CatalogProducts.Ref
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON (ItemKinds.Ref = CatalogProducts.ProductKind)
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON (CASE
	|				WHEN CatalogProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					THEN CatalogProducts.Ref
	|				WHEN CatalogProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					THEN CatalogProducts.ProductKind
	|				WHEN CatalogProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					THEN CatalogProducts.ItemVariantsOwner
	|				ELSE UNDEFINED
	|			END = ItemsCharacteristics.Owner)
	|			AND (CatalogProducts.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse))
	|
	|INDEX BY
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	Package
	|";

	Return QueryText;
	
EndFunction

Function QueryTextTableTTStageMaterials(UsePriceManagementSystem25 = False)
	
	QueryText =
	"SELECT
	|	""Material_""								AS ExpenseType,
	|	TableMaterials.ProductionLot				AS ProductionLot,
	|	TableMaterials.Department					AS Department,
	|	TableMaterials.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableMaterials.Products					AS Products,
	|	TableMaterials.Products					AS Cost_,
	|	TableMaterials.Characteristic					AS Characteristic,
	|	TableMaterials.Series							AS Series,
	|	TableMaterials.ProductCostElement				AS ProductCostElement,
	|	TableMaterials.Purpose						AS Purpose,
	|	TableMaterials.Package						AS Package,
	|	TableMaterials.NumberOfPackages				AS NumberOfPackages,
	|	TableMaterials.Count						AS Count,
	|	TableMaterials.NumberOfPackages
	|	* ISNULL(&QueryTextPackagingFactor1, 1)
	|	* ISNULL(ItemsPrices.Price,0)
	|	* CASE
	|		WHEN &CurrencyOfManAccounting <> ItemsPrices.Currency
	|			THEN
	|				CASE
	|					WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|						AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN 
	|						(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|						/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END
	|	/ ISNULL(&QueryTextPackagingFactor2,1)	AS AllocationBase,
	|	0												AS Price,
	|	0												AS Sum,
	|	0												AS SumCompl,
	|	0												AS AmountFA,
	|	0												AS AmountPermanentDifferences,
	|	0												AS AmountTemporaryDifferences
	|INTO TTStageMaterials
	|FROM
	|	MaterialsOfPreparatoryStages AS TableMaterials
	|
	|	LEFT JOIN ItemsPrices AS ItemsPrices ON TRUE
	|
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(ENDOFPERIOD(&DateOfRemainingGoods, MONTH), BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|	ON CurrencyRatesPrices.Currency = ItemsPrices.Currency
	|	
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(ENDOFPERIOD(&DateOfRemainingGoods, MONTH), Currency = &CurrencyOfManAccounting AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON TRUE
	|	
	|";

	If UsePriceManagementSystem25 Then
		LinkTextWithPrices =
		"LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&DateOfRemainingGoods, MONTH), (Products, PricingVariant,
		|		PricingBatch, PricingPackage, PriceKind) IN
		|		(SELECT
		|			T.Products,
		|			T.PricingVariant,
		|			T.PricingBatch,
		|			T.Package,
		|			&PriceKind
		|		FROM
		|			MaterialsOfPreparatoryStages AS T)) AS ItemsPrices
		|	ON ItemsPrices.Products = TableMaterials.Products
		|	AND ItemsPrices.PricingVariant = TableMaterials.PricingVariant
		|	AND ItemsPrices.PricingBatch = TableMaterials.PricingBatch
		|	AND ItemsPrices.PricingPackage = TableMaterials.Package";
	Else
		LinkTextWithPrices =
		"LEFT JOIN InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&DateOfRemainingGoods, MONTH), PriceKind = &PriceKind) AS ItemsPrices
		|	ON ItemsPrices.Products = TableMaterials.Products
		|	AND ItemsPrices.Characteristic = TableMaterials.Characteristic";
	EndIf;
	ReplaceSubstring = "LEFT JOIN ItemsPrices AS ItemsPrices ON TRUE";
	QueryText = StrReplace(QueryText, ReplaceSubstring, LinkTextWithPrices);

	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TableMaterials.Package",
			"TableMaterials.Products"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsPrices.Package",
			"ItemsPrices.Products"));
		
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLaborCostsOfStages()
	
	QueryText =
	"SELECT
	|	""LaborCosts""								AS ExpenseType,
	|	DistributionBaseStages.ProductionLot		AS ProductionLot,
	|	DistributionBaseStages.Department			AS Department,
	|	TableLaborCosts.WorkKind					AS WorkKind,
	|	TableLaborCosts.WorkKind					AS Cost_,
	|	TableLaborCosts.ProductCostElement			AS ProductCostElement,
	|	SUM(TableLaborCosts.Count)			AS Count,
	|	SUM(TableLaborCosts.Count)			AS NumberOfPackages,
	|	MAX(CASE
	|				WHEN NOT PricesOfTypesOfWorks.Rate_ IS NULL
	|					THEN PricesOfTypesOfWorks.Rate_
	|				ELSE 0
	|			END)									AS StandardRate,
	|	SUM(TableLaborCosts.Count
	|	* CASE
	|		WHEN NOT PricesOfTypesOfWorks.Rate_ IS NULL
	|			THEN PricesOfTypesOfWorks.Rate_
	|		ELSE 0
	|	END)											AS StandardAmount,
	|	SUM(TableLaborCosts.Count
	|	* CASE
	|		WHEN NOT PricesOfTypesOfWorks.Rate_ IS NULL
	|			THEN PricesOfTypesOfWorks.Rate_
	|		ELSE 0
	|	END
	|	* CASE
	|		WHEN &CurrencyOfManAccounting <> &CurrencyOfTypesOfWork
	|			THEN
	|				CASE
	|					WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|						AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN 
	|						(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|						/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END)											AS AllocationBase,
	|	0												AS Price,
	|	0												AS Sum,
	|	0												AS SumCompl,
	|	0												AS AmountFA,
	|	0												AS AmountPermanentDifferences,
	|	0												AS AmountTemporaryDifferences
	|INTO TTLaborCostsOfStages
	|FROM
	|	DistributionBaseStages AS DistributionBaseStages
	|	
	|	INNER JOIN Document.ProductionStage2_2.LaborCosts AS TableLaborCosts
	|	ON TableLaborCosts.Ref = DistributionBaseStages.Stage
	|	AND TableLaborCosts.Completed2
	|	AND TableLaborCosts.ExecutionDate <= ENDOFPERIOD(&DateOfRemainingGoods, MONTH)
	|	AND NOT TableLaborCosts.Canceled
	|	
	|	LEFT JOIN Catalog.EmployeeWorkKinds AS ActivityKinds
	|	ON TableLaborCosts.WorkKind = ActivityKinds.Ref
	|	
	|	LEFT JOIN InformationRegister.EmployeeActivityRates.SliceLast(ENDOFPERIOD(&DateOfRemainingGoods, MONTH)) AS PricesOfTypesOfWorks
	|	ON PricesOfTypesOfWorks.WorkKind = TableLaborCosts.WorkKind
	|	AND NOT ActivityKinds.RateAccordingToPayScale
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(ENDOFPERIOD(&DateOfRemainingGoods, MONTH), Currency = &CurrencyOfTypesOfWork AND BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|	ON TRUE
	|	
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(ENDOFPERIOD(&DateOfRemainingGoods, MONTH), Currency = &CurrencyOfManAccounting AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON TRUE
	|	
	|GROUP BY
	|	DistributionBaseStages.ProductionLot,
	|	DistributionBaseStages.Department,
	|	TableLaborCosts.WorkKind,
	|	TableLaborCosts.ProductCostElement
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableStageMaterials_()
	
	QueryText =
	"SELECT
	|	StageMaterials_.ExpenseType			AS ExpenseType,
	|	StageMaterials_.ProductionLot	AS ProductionLot,
	|	StageMaterials_.Department		AS Department,
	|	StageMaterials_.InventoryOwnerAttribute			AS InventoryOwnerAttribute,
	|	StageMaterials_.Products		AS Products,
	|	StageMaterials_.Cost_				AS Cost_,
	|	StageMaterials_.Characteristic		AS Characteristic,
	|	StageMaterials_.Series				AS Series,
	|	StageMaterials_.ProductCostElement	AS ProductCostElement,
	|	StageMaterials_.Purpose			AS Purpose,
	|	StageMaterials_.Package			AS Package,
	|	StageMaterials_.NumberOfPackages	AS NumberOfPackages,
	|	StageMaterials_.Count			AS Count,
	|	StageMaterials_.AllocationBase	AS AllocationBase,
	|	StageMaterials_.Price				AS Price,
	|	StageMaterials_.Sum				AS Sum,
	|	StageMaterials_.SumCompl			AS SumCompl,
	|	StageMaterials_.AmountFA				AS AmountFA,
	|	StageMaterials_.AmountPermanentDifferences				AS AmountPermanentDifferences,
	|	StageMaterials_.AmountTemporaryDifferences				AS AmountTemporaryDifferences
	|FROM
	|	TTStageMaterials AS StageMaterials_
	|
	|WHERE
	|	NOT StageMaterials_.AllocationBase = 0
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLaborCostsOfStages()
	
	QueryText =
	"SELECT
	|	LaborCostsOfStages.ExpenseType			AS ExpenseType,
	|	LaborCostsOfStages.ProductionLot	AS ProductionLot,
	|	LaborCostsOfStages.Department		AS Department,
	|	LaborCostsOfStages.WorkKind				AS WorkKind,
	|	LaborCostsOfStages.Cost_				AS Cost_,
	|	LaborCostsOfStages.ProductCostElement	AS ProductCostElement,
	|	LaborCostsOfStages.Count			AS Count,
	|	LaborCostsOfStages.NumberOfPackages	AS NumberOfPackages,
	|	LaborCostsOfStages.StandardRate	AS StandardRate,
	|	LaborCostsOfStages.StandardAmount		AS StandardAmount,
	|	LaborCostsOfStages.AllocationBase	AS AllocationBase,
	|	LaborCostsOfStages.Price					AS Price,
	|	LaborCostsOfStages.Sum				AS Sum,
	|	LaborCostsOfStages.SumCompl			AS SumCompl,
	|	LaborCostsOfStages.AmountFA				AS AmountFA,
	|	LaborCostsOfStages.AmountPermanentDifferences				AS AmountPermanentDifferences,
	|	LaborCostsOfStages.AmountTemporaryDifferences				AS AmountTemporaryDifferences
	|FROM
	|	TTLaborCostsOfStages AS LaborCostsOfStages
	|
	|WHERE
	|	NOT LaborCostsOfStages.AllocationBase = 0
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextTableMaterialsLaborCostsStages()
	
	QueryText =
	"SELECT
	|	MaterialsLaborCosts.ProductionLot	AS ProductionLot,
	|	SUM(MaterialsLaborCosts.UsedMaterials
	|		+ MaterialsLaborCosts.LaborCosts)	AS MaterialsLaborCosts,
	|	SUM(MaterialsLaborCosts.UsedMaterials)		AS UsedMaterials,
	|	SUM(MaterialsLaborCosts.LaborCosts)	AS LaborCosts
	|FROM
	|	(SELECT
	|		StageMaterials_.ProductionLot	AS ProductionLot,
	|		StageMaterials_.AllocationBase	AS UsedMaterials,
	|		0									AS LaborCosts
	|	FROM
	|		TTStageMaterials AS StageMaterials_
	|
	|	WHERE
	|		NOT StageMaterials_.AllocationBase = 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		LaborCostsOfStages.ProductionLot	AS ProductionLot,
	|		0										AS UsedMaterials,
	|		LaborCostsOfStages.AllocationBase	AS LaborCosts
	|	FROM
	|		TTLaborCostsOfStages AS LaborCostsOfStages
	|
	|	WHERE
	|		NOT LaborCostsOfStages.AllocationBase = 0
	|	) AS MaterialsLaborCosts
	|	
	|GROUP BY
	|	MaterialsLaborCosts.ProductionLot
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextErrorsInAllocatioOfWIPCostBalances()
	
	QueryText =
	"SELECT
	|	""PriceNotSpecified_""										AS ErrorType,
	|	VALUE(Catalog.ProductionLots.EmptyRef)	AS ProductionLot,
	|	VALUE(Document.ProductionStage2_2.EmptyRef)		AS Stage,
	|	TTStageMaterials.Cost_								AS Cost_,
	|	TTStageMaterials.Characteristic						AS Characteristic
	|FROM
	|	TTStageMaterials AS TTStageMaterials
	|
	|WHERE
	|	TTStageMaterials.AllocationBase = 0
	|
	|GROUP BY
	|	TTStageMaterials.Cost_,
	|	TTStageMaterials.Characteristic
	|
	|UNION ALL
	|
	|SELECT
	|	""PriceNotSpecified""											AS ErrorType,
	|	VALUE(Catalog.ProductionLots.EmptyRef)			AS ProductionLot,
	|	VALUE(Document.ProductionStage2_2.EmptyRef)				AS Stage,
	|	TTLaborCostsOfStages.Cost_									AS Cost_,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef)	AS Characteristic
	|FROM
	|	TTLaborCostsOfStages AS TTLaborCostsOfStages
	|
	|WHERE
	|	TTLaborCostsOfStages.AllocationBase = 0
	|
	|GROUP BY
	|	TTLaborCostsOfStages.Cost_
	|
	|UNION ALL
	|
	|SELECT
	|	""ParallelStages""											AS ErrorType,
	|	ConcurrencyErrors.ProductionLot							AS ProductionLot,
	|	StepsByCurProcessingLocation.Stage								AS Stage,
	|	UNDEFINED													AS Cost_,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef)	AS Characteristic
	|FROM
	|	TTErrorsOfParallelismOfStages AS ConcurrencyErrors
	|	
	|	LEFT JOIN StepsByCurProcessingLocation AS StepsByCurProcessingLocation
	|	ON StepsByCurProcessingLocation.ProductionLot = ConcurrencyErrors.ProductionLot
	|
	|GROUP BY
	|	ConcurrencyErrors.ProductionLot,
	|	StepsByCurProcessingLocation.Stage
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
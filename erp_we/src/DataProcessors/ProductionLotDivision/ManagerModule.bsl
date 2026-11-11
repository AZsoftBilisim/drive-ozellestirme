
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Performs the specified action with the production batch (division, reduction, increase, cancel).
// 
// Parameters:
// 	Parameters - Structure - the composition of the fields is similar to the details and tabular parts of processing the division of production Parties.
// 	StorageAddress - String - address of the storage where the result will be placed.
//
Procedure PerformActionInBackground(Parameters, StorageAddress) Export
	
	Result = Undefined;
	Actions = Actions();
	
	Try
		
		If Parameters.Action = Actions.Reduce Then
			
			AbbreviationParameters = New Structure;
			AbbreviationParameters.Insert("Stage");
			AbbreviationParameters.Insert("ReserveMaterials");
			AbbreviationParameters.Insert("ReplaceMaterialsWithAnalogs");
			FillPropertyValues(AbbreviationParameters, Parameters);
			
			AbbreviationParameters.Insert("RecalculateByFactor",
				Not Parameters.FillInByBOM Or Parameters.BillOfMaterials.IsEmpty());
			
			AbbreviationParameters.Insert("CancelChangeFinishedProductInOrder", Parameters.Lots[0].CancelChangeFinishedProductInOrder);
			AbbreviationParameters.Insert("ReasonForCancelingFinishedProduct", Parameters.Lots[0].ReasonForCancelingFinishedProduct);
			
			BatchSize = Documents.ProductionStage2_2.NewBatchSize(
				Parameters.Lots[0].LotQuantity,
				Parameters.Lots[0].LotNumberOfPackages,
				Parameters.Lots[0].PackageOfLot);
			
			Assignments = New Structure;
			Assignments.Insert("ManufacturedProductAssignments", Parameters.Lots[0].ManufacturedProductAssignments);
			Assignments.Insert("AssignmentsOfMaterials", Parameters.Lots[0].AssignmentsOfMaterials);
			
			Result = Documents.ProductionStage2_2.ChangeBatchSize(
				Parameters,
				AbbreviationParameters,
				BatchSize,
				Assignments,
				Parameters.FormIdentifier);
			
		ElsIf Parameters.Action = Actions.DefectiveGoods And Parameters.ThisIsLastStageAndOperation Then
			
			ChangeParameters = New Structure;
			ChangeParameters.Insert("Stage", Parameters.Stage);
			ChangeParameters.Insert("NumberOfPackagingUnitsNonconformity", Parameters.NumberOfPackagingUnitsNonconformity);
			ChangeParameters.Insert("PackagingDefectiveGoods", Parameters.Package);
			ChangeParameters.Insert("FillInCOSTShares", Not Parameters.CostSharesAreFilledInStage);
			ChangeParameters.Insert("SetOfSeries", Parameters.SetOfSeries);
			
			Result = Documents.ProductionStage2_2.AddNonconformity(
				Parameters,
				ChangeParameters,
				Parameters.Lots[0],
				Parameters.FormIdentifier);
			
		ElsIf Parameters.Action = Actions.Cancel
			Or (Parameters.Action = Actions.DefectiveGoods And Parameters.Lots.Count() = 1) Then
			
			CancellationOptions = New Structure;
			CancellationOptions.Insert("FromBeginningOfParty");
			CancellationOptions.Insert("Stage");
			CancellationOptions.Insert("Operation");
			CancellationOptions.Insert("OperationID");
			CancellationOptions.Insert("MethodOfAllocatingFinishedProductCosts");
			FillPropertyValues(CancellationOptions, Parameters);
			
			If Parameters.Action = Actions.DefectiveGoods Then
				CancellationOptions.Insert("ItSNonconformityMarriage", True);
				CancellationOptions.Insert("NumberOfPackagingUnitsNonconformity", Parameters.NumberOfPackagingUnitsNonconformity);
				CancellationOptions.Insert("PackagingDefectiveGoods", Parameters.Package);
			Else
				CancellationOptions.Insert("ItSNonconformityMarriage", False);
				CancellationOptions.Insert("NumberOfPackagingUnitsNonconformity", 0);
				CancellationOptions.Insert("PackagingDefectiveGoods", Undefined);
			EndIf;
			
			CancellationOptions.Insert("CancelChangeFinishedProductInOrder", Parameters.Lots[0].CancelChangeFinishedProductInOrder);
			CancellationOptions.Insert("ReasonForCancelingFinishedProduct", Parameters.Lots[0].ReasonForCancelingFinishedProduct);
			
			Result = Documents.ProductionStage2_2.CancelParty(
				Parameters,
				CancellationOptions,
				Parameters.Lots,
				Parameters.SetOfSeries,
				Parameters.FormIdentifier);
			
		ElsIf Parameters.Action = Actions.Split
			And Parameters.FromBeginningOfParty Then // Split (from the beginning of the chain)
			
			Lots = New Array;
			Assignments = New Array;
			For Each String In Parameters.Lots Do
				Lots.Add(
					Documents.ProductionStage2_2.NewBatchSize(
						String.LotQuantity,
						String.LotNumberOfPackages,
						String.PackageOfLot));
				Assignments.Add(
					New Structure("ManufacturedProductAssignments, AssignmentsOfMaterials",
						String.ManufacturedProductAssignments, String.AssignmentsOfMaterials));
			EndDo;
			
			ParametersOfDivision = New Structure;
			ParametersOfDivision.Insert("ReserveMaterials");
			ParametersOfDivision.Insert("ReplaceMaterialsWithAnalogs");
			FillPropertyValues(ParametersOfDivision, Parameters);
			
			ParametersOfDivision.Insert("FillInByBOM",
				Parameters.FillInByBOM And Not Parameters.BillOfMaterials.IsEmpty());
			
			Result = Documents.ProductionStage2_2.SplitParty(
				Parameters,
				Lots,
				Assignments,
				ParametersOfDivision,
				Parameters.FormIdentifier);
			
		ElsIf Parameters.Action = Actions.Fill Then
			
			FillParameters = New Structure;
			FillParameters.Insert("Stage");
			FillParameters.Insert("BOMStage");
			FillParameters.Insert("ReserveMaterials");
			FillParameters.Insert("ReplaceMaterialsWithAnalogs");
			FillPropertyValues(FillParameters, Parameters);
			
			Result = Documents.ProductionStage2_2.ReFillBatch(
				Parameters.ProductionLot,
				FillParameters,
				Parameters.FormIdentifier);
			
		Else // Split (from the stage) / Continue / Nonconformity (partial)
			
			ParametersOfDivision = New Structure;
			ParametersOfDivision.Insert("Stage");
			ParametersOfDivision.Insert("Operation");
			ParametersOfDivision.Insert("OperationID");
			ParametersOfDivision.Insert("MethodOfAllocatingFinishedProductCosts");
			ParametersOfDivision.Insert("ReserveMaterials");
			ParametersOfDivision.Insert("ReplaceMaterialsWithAnalogs");
			FillPropertyValues(ParametersOfDivision, Parameters);
			
			ParametersOfDivision.Insert("FillInByBOM",
				Parameters.FillInByBOM And Not Parameters.BillOfMaterials.IsEmpty());
			
			If Parameters.Action = Actions.DefectiveGoods Then
				ParametersOfDivision.Insert("ItSNonconformityMarriage", True);
				ParametersOfDivision.Insert("NumberOfPackagingUnitsNonconformity", Parameters.NumberOfPackagingUnitsNonconformity);
				ParametersOfDivision.Insert("PackagingDefectiveGoods", Parameters.Package);
			Else
				ParametersOfDivision.Insert("ItSNonconformityMarriage", False);
				ParametersOfDivision.Insert("NumberOfPackagingUnitsNonconformity", 0);
				ParametersOfDivision.Insert("PackagingDefectiveGoods", Undefined);
			EndIf;
			
			Result = Documents.ProductionStage2_2.SplitLotReferenceFromStage(
				Parameters,
				ParametersOfDivision,
				Parameters.Lots,
				Parameters.SetOfSeries,
				Parameters.FormIdentifier);
			
		EndIf;
		
	Except
		
		WriteLogEvent(
			NStr("vi = 'Chia lô sản xuất';
				|ru = 'Деление партии производства';
				|en = 'Production lot division'; fa = 'تقسیم لات تولید';
				|it = 'Divisione del lotto di produzione';
				|pl = 'Podział partii produkcji';
				|tr = 'Üretim lotunun bölünmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		
		Messages = New Array;
		Messages.Add(BriefErrorDescription(ErrorInfo()));
		
		Result = New Structure("Cancel, Messages", True, Messages);
		
	EndTry;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	Return "";
	
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
// 
// Returns:
//  Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	ProductionSettings = ProductionServer.UseOfSeriesInProduction22();
		
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "DataProcessor.ProductionLotDivision";
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("Recipient");
	SeriesSpecificationParameters.LinkFields.Add("Manufactured");
	SeriesSpecificationParameters.LinkFields.Add("ProductionDate");
	SeriesSpecificationParameters.LinkFields.Add("LotIndex");
	SeriesSpecificationParameters.LinkFields.Add("Department");
	
	SeriesSpecificationParameters.WarehouseFieldName = "Recipient";
	SeriesSpecificationParameters.NameTSGoods = "Lots";
	SeriesSpecificationParameters.TSSeriesName = "SetOfSeries";
	
	SeriesSpecificationParameters.UseCostAccountingByBatches =
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure())
		Or ProductionSettings.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.UseItemsBatch  =
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure())
		Or ProductionSettings.UseItemsBatch;
	
	SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ProductReceivingFromManufacturing);
	
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Manufactured");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Canceled");
	
	SeriesSpecificationParameters.NameOfValueSourceInObjectForm = "CurrentData";
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusSender");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusRecipient");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	Return
		"SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Series AS Series,
		|	Goods.Recipient AS Recipient,
		|	Goods.Manufactured AS Manufactured,
		|	Goods.ProductionDate AS ProductionDate,
		|	Goods.LotIndex AS LotIndex,
		|	Goods.Department AS Department,
		|	Goods.Count AS Count,
		|	Goods.Canceled AS Canceled,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
		|	Goods.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
		|	Goods.LineNumber AS LineNumber
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Series AS Series,
		|	Goods.Recipient AS Recipient,
		|	Goods.Manufactured AS Manufactured,
		|	Goods.ProductionDate AS ProductionDate,
		|	Goods.LotIndex AS LotIndex,
		|	Goods.Department AS Department,
		|	SUM(Goods.Count) AS Count
		|INTO ProductsToRequest
		|FROM
		|	Goods AS Goods
		|WHERE
		|	NOT Goods.Canceled
		|
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.Series,
		|	Goods.Recipient,
		|	Goods.Manufactured,
		|	Goods.ProductionDate,
		|	Goods.LotIndex,
		|	Goods.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.Products AS Products,
		|	SetOfSeries.Characteristic AS Characteristic,
		|	SetOfSeries.Purpose AS Purpose,
		|	SetOfSeries.Recipient AS Recipient,
		|	SetOfSeries.Manufactured AS Manufactured,
		|	SetOfSeries.ProductionDate AS ProductionDate,
		|	SetOfSeries.LotIndex AS LotIndex,
		|	SetOfSeries.Department AS Department,
		|	SetOfSeries.Count AS Count
		|INTO SetOfSeries
		|FROM
		|	&SetOfSeries AS SetOfSeries
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.Products AS Products,
		|	SetOfSeries.Characteristic AS Characteristic,
		|	SetOfSeries.Purpose AS Purpose,
		|	SetOfSeries.Recipient AS Recipient,
		|	SetOfSeries.Manufactured AS Manufactured,
		|	SetOfSeries.ProductionDate AS ProductionDate,
		|	SetOfSeries.LotIndex AS LotIndex,
		|	SetOfSeries.Department AS Department,
		|	SUM(SetOfSeries.Count) AS Count
		|INTO SeriesToRequest
		|FROM
		|	SetOfSeries AS SetOfSeries
		|
		|GROUP BY
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	SetOfSeries.Purpose,
		|	SetOfSeries.Recipient,
		|	SetOfSeries.Manufactured,
		|	SetOfSeries.ProductionDate,
		|	SetOfSeries.LotIndex,
		|	SetOfSeries.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber AS LineNumber,
		|	CASE
		|		WHEN Goods.Canceled
		|				OR ItemKinds.BatchAccountingPolicy IS NULL
		|			THEN 0
		|		WHEN ItemKinds.BatchAccountingPolicy.UseCostAccountingByBatches
		|			THEN CASE
		|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|						THEN 14
		|					WHEN NOT Goods.Manufactured
		|						THEN 15
		|					ELSE 13
		|				END
		|		WHEN ItemKinds.BatchAccountingPolicy.SpecifyDuringProduction
		|			THEN CASE
		|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|							AND ProductsToRequest.Count > 0
		|						THEN 2
		|					WHEN NOT ProductsToRequest.Manufactured
		|							AND ISNULL(SeriesToRequest.Count, 0) = 0
		|						THEN 21
		|					ELSE 1
		|				END
		|		ELSE 0
		|	END AS BatchesIndicationStatus
		|INTO SenderStatuses
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN ProductsToRequest AS ProductsToRequest
		|		ON Goods.Products = ProductsToRequest.Products
		|			AND Goods.Characteristic = ProductsToRequest.Characteristic
		|			AND Goods.Purpose = ProductsToRequest.Purpose
		|			AND Goods.Recipient = ProductsToRequest.Recipient
		|			AND Goods.Manufactured = ProductsToRequest.Manufactured
		|			AND Goods.ProductionDate = ProductsToRequest.ProductionDate
		|			AND Goods.LotIndex = ProductsToRequest.LotIndex
		|			AND Goods.Department = ProductsToRequest.Department
		|		LEFT JOIN SeriesToRequest AS SeriesToRequest
		|		ON Goods.Products = SeriesToRequest.Products
		|			AND Goods.Characteristic = SeriesToRequest.Characteristic
		|			AND Goods.Purpose = SeriesToRequest.Purpose
		|			AND Goods.Recipient = SeriesToRequest.Recipient
		|			AND Goods.Manufactured = SeriesToRequest.Manufactured
		|			AND Goods.ProductionDate = SeriesToRequest.ProductionDate
		|			AND Goods.LotIndex = SeriesToRequest.LotIndex
		|			AND Goods.Department = SeriesToRequest.Department
		|		LEFT JOIN Catalog.Products AS CatalogProducts
		|		ON Goods.Products = CatalogProducts.Ref
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON (CatalogProducts.ProductKind = ItemKinds.Ref)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber AS LineNumber,
		|	CASE
		|		WHEN Goods.Canceled
		|				OR BatchAccountingPolicies.BatchAccountingPolicy IS NULL
		|				OR NOT Warehouses.ShopFloorStockroom
		|				OR Warehouses.Department <> Goods.Department
		|			THEN 0
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
		|			THEN CASE
		|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|						THEN 14
		|					WHEN NOT Goods.Manufactured
		|						THEN 15
		|					ELSE 13
		|				END
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
		|			THEN CASE
		|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|							AND ProductsToRequest.Count > 0
		|						THEN 10
		|					WHEN NOT ProductsToRequest.Manufactured
		|							AND ISNULL(SeriesToRequest.Count, 0) = 0
		|						THEN 11
		|					ELSE 9
		|				END
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
		|			THEN CASE
		|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|							AND ProductsToRequest.Count > 0
		|						THEN 8
		|					WHEN NOT ProductsToRequest.Manufactured
		|							AND ISNULL(SeriesToRequest.Count, 0) = 0
		|						THEN 27
		|					ELSE 7
		|				END
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
		|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenReceivingProductsFromManufacturing
		|			THEN CASE
		|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
		|						THEN CASE
		|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|										AND ProductsToRequest.Count > 0
		|									THEN 4
		|								WHEN NOT ProductsToRequest.Manufactured
		|										AND ISNULL(SeriesToRequest.Count, 0) = 0
		|									THEN 23
		|								ELSE 3
		|							END
		|					ELSE CASE
		|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|									AND ProductsToRequest.Count > 0
		|								THEN 2
		|							WHEN NOT ProductsToRequest.Manufactured
		|									AND ISNULL(SeriesToRequest.Count, 0) = 0
		|								THEN 21
		|							ELSE 1
		|						END
		|				END
		|		ELSE 0
		|	END AS BatchesIndicationStatus
		|INTO RecipientStatuses
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN ProductsToRequest AS ProductsToRequest
		|		ON Goods.Products = ProductsToRequest.Products
		|			AND Goods.Characteristic = ProductsToRequest.Characteristic
		|			AND Goods.Purpose = ProductsToRequest.Purpose
		|			AND Goods.Recipient = ProductsToRequest.Recipient
		|			AND Goods.Manufactured = ProductsToRequest.Manufactured
		|			AND Goods.ProductionDate = ProductsToRequest.ProductionDate
		|			AND Goods.LotIndex = ProductsToRequest.LotIndex
		|			AND Goods.Department = ProductsToRequest.Department
		|		LEFT JOIN SeriesToRequest AS SeriesToRequest
		|		ON Goods.Products = SeriesToRequest.Products
		|			AND Goods.Characteristic = SeriesToRequest.Characteristic
		|			AND Goods.Purpose = SeriesToRequest.Purpose
		|			AND Goods.Recipient = SeriesToRequest.Recipient
		|			AND Goods.Manufactured = SeriesToRequest.Manufactured
		|			AND Goods.ProductionDate = SeriesToRequest.ProductionDate
		|			AND Goods.LotIndex = SeriesToRequest.LotIndex
		|			AND Goods.Department = SeriesToRequest.Department
		|		LEFT JOIN Catalog.Warehouses AS Warehouses
		|		ON Goods.Recipient = Warehouses.Ref
		|		LEFT JOIN Catalog.Products AS CatalogProducts
		|		ON Goods.Products = CatalogProducts.Ref
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
		|		ON Goods.Recipient = BatchAccountingPolicies.Warehouse
		|			AND (CatalogProducts.ProductKind = BatchAccountingPolicies.Ref)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber AS LineNumber,
		|	SenderStatuses.BatchesIndicationStatus AS BatchesIndicationStatusSender,
		|	RecipientStatuses.BatchesIndicationStatus AS BatchesIndicationStatusRecipient,
		|	CASE
		|		WHEN SenderStatuses.BatchesIndicationStatus IN (13, 14, 15)
		|			THEN SenderStatuses.BatchesIndicationStatus
		|		WHEN RecipientStatuses.BatchesIndicationStatus <> 0
		|			THEN RecipientStatuses.BatchesIndicationStatus
		|		ELSE SenderStatuses.BatchesIndicationStatus
		|	END AS BatchesIndicationStatus
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN SenderStatuses AS SenderStatuses
		|		ON Goods.LineNumber = SenderStatuses.LineNumber
		|		LEFT JOIN RecipientStatuses AS RecipientStatuses
		|		ON Goods.LineNumber = RecipientStatuses.LineNumber
		|WHERE
		|	(SenderStatuses.BatchesIndicationStatus <> Goods.BatchesIndicationStatusSender
		|			OR RecipientStatuses.BatchesIndicationStatus <> Goods.BatchesIndicationStatusRecipient
		|			OR CASE
		|				WHEN SenderStatuses.BatchesIndicationStatus IN (13, 14, 15)
		|					THEN SenderStatuses.BatchesIndicationStatus
		|				WHEN RecipientStatuses.BatchesIndicationStatus <> 0
		|					THEN RecipientStatuses.BatchesIndicationStatus
		|				ELSE SenderStatuses.BatchesIndicationStatus
		|			END <> Goods.BatchesIndicationStatus)
		|
		|ORDER BY
		|	Goods.LineNumber";
	
EndFunction

// Returns the parameters of the distribution of the costs of the output product.
//
// Parameters:
//  MethodOfAllocatingFinishedProductCosts	 - EnumRef.MethodsOfCostAllocatingOnProductCosts - method for allocating costs for output items.
// 
// Returns:
//  Structure - parameters specifying the specifics of the distribution of costs for output products.
//
Function CostAllocationParameters(MethodOfAllocatingFinishedProductCosts) Export
	
	CostAllocationParameters = ProductionClientServer.CostAllocationParametersForOutputProducts(
		"Lots",
		MethodOfAllocatingFinishedProductCosts);
	
	CostAllocationParameters.CalculateShareCostPercentageField = True;
	CostAllocationParameters.ThisFlagIndicatesThatThereAreFillInErrors = True;
	CostAllocationParameters.CalculateShareOfCostAttributeRequired = True;
	
	CostAllocationParameters.LinkFields = "Products,Characteristic,LotIndex";
	
	Return CostAllocationParameters;
	
EndFunction

Function StageEditingParameters() Export

	StageEditingParameters = ProductionManagement.StageEditingParameters("DataProcessor");
	Return StageEditingParameters;

EndFunction

// Returns parameters for selecting articles in the document.
// 
// Returns:
//  Array, Structure - See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(Object) Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath         = "Object.Lots";
	ChoiceParameters.AssetRef              = "ExpenseItem";
	ChoiceParameters.ArticleType           = "ArticleType";
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	
	ChoiceParameters.AvailabilityByOperation =
		Not Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		And True;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	ProductionManagement.CompleteSelectionOfExpenditureItems(ChoiceParameters.SelectionOfExpenditureItems);
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("LotsExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("SimpleModeNonconformityExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("SimpleModeCancelExpenseItem");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("LotsDimensionOfExpenses");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("SimpleNonconformityModeExpenseAnalytics");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("EasyModeCancelAnalyticsOfExpenses");
	
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("LotsAssetsLiabilitiesDimension");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("SimpleModeNonconformityAnalyticsOfAssetsLiabilities");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("SimpleModeCancelAnalyticsOfAssetsLiabilities");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	Return CommonClientServer.ValueInArray(ChoiceParameters);
	
EndFunction

// Returns parameters for setting up accounting accounts in the document.
//  
// Returns:
//  Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.AvailabilityByOperation	= True;
	SetupParameters.DataPath				= "Object.Lots";
	SetupParameters.ArticleType				= "ArticleType";
	
	SetupParameters.FormItems.Add("LotsTransactionRecordingPresentation");
	
	Return CommonClientServer.ValueInArray(SetupParameters);
	
EndFunction

// Initializes parameters that serve the selection of assignments in processing forms.
// 
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.Lots.Purpose");
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ đến ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Sadece ""%1"" iş kolunun atamaları'"));
	
	// The needs for manufactured products in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Lots.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Lots.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Lots.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Lots.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Lots.Recipient";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.Stage";
	
	// The needs for the work performed in the recipient unit.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.Lots.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Lots.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Lots.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Lots.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Lots.Recipient";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.Stage";
	
	// Product needs in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.Lots.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Lots.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Lots.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Lots.Characteristic";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.Stage";
	
	Return FormTemplate;
	
EndFunction

// Names of the details that the specification selection parameters depend on.
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	Return "ProductionProcessType";
	
EndFunction

// Returns the parameters of the choice of specifications for the formation of parties.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of the choice specs.
//
// Returns:
//   Structure - A structure that overrides the defaults set in the management function of the Client Server's data items.Parameterselectionspecifications().
//
Function BOMSelectionParameters(Object) Export
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	BOMSelectionParameters.AvailableTypes.Add(Object.ProductionProcessType);
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	ChoiceParameterLinks.Products   = "Object.Lots.ContinueItem";
	ChoiceParameterLinks.Characteristic = "Object.Lots.ContinueVariant";
	ChoiceParameterLinks.ProductionDispatcherBusinessUnit = "Object.ProductionDispatcherBusinessUnit";
	ChoiceParameterLinks.UnderRepairProduct   = "Object.UnderRepairProduct";
	ChoiceParameterLinks.UnderRepairVariant = "Object.UnderRepairVariant";
	
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Items.Lots.CurrentData.ContinueBOM", ChoiceParameterLinks);
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Object.Lots.ContinueBOM", ChoiceParameterLinks);
	
	Return BOMSelectionParameters;
	
EndFunction

// The Attributes of the division constructor.
// 
// Returns:
//  Structure:
//   * FirstOperationID - Number
//   * LastOperationID - Number
//   * CanceledLastOperation - Number
//   * Predecessor - Undefined,DocumentRef.ProductionStage2_2
Function DivisionAttributesConstructor() Export
	
	Result = InformationRegisters.TechnologicalProcessesOfProductionStages.LimitationsOfConstructorProcess();
	Result.Insert("Predecessor", Undefined);
	
	Return Result;
	
EndFunction

// Changes the Attributes of the division of the stage, taking into account the specifics of their storage
// 
// Parameters:
//  Stage - DocumentRef.ProductionStage2_2
//  DivisionAttributes - See DivisionAttributesConstructor
//  Mode - Number - operating mode (0 - all, 1 - only the register of division Attributes, 2 - only the register of process data)
Procedure ChangeStageDivisionAttributes(Stage, DivisionAttributes, Mode = 0) Export
	
	SetPrivilegedMode(True);
	
	If Mode = 0 Or Mode = 1 Then
	
		Set = InformationRegisters.AttributesOfProductionStageDivision.CreateRecordSet();
		Set.Filter.Stage.Set(Stage);
		Record = Set.Add();
		FillPropertyValues(Record, DivisionAttributes);
		Record.Stage = Stage;
		Set.Write();
	
	EndIf;
	
	If Mode = 0 Or Mode = 2 Then
	
		Set = InformationRegisters.TechnologicalProcessesOfProductionStages.CreateRecordSet();
		Set.Filter.Stage.Set(Stage);
		Set.Read();
		If Set.Count() > 0 Then
			Record = Set[0];
		Else
			Record = Set.Add();
			FillPropertyValues(Record, ProductionProcessEditorServerCall.ParametersOfTechnicalProcessOfStage(Stage));
		EndIf;
		FillPropertyValues(Record, DivisionAttributes);
		Record.Stage = Stage;
		Set.Write();
	
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Constructor of the result of the action (division, cancellation, reduction, etc.).
// 
// Returns:
//  Structure - Result Of Processing Constructor:
// * StageCreated - Array of DocumentRef.ProductionStage2_2 - 
// * ChangedStage - Array of DocumentRef.ProductionStage2_2 -
// * StageRemoved - Array of DocumentRef.ProductionStage2_2 -
// * StageIsNotRecorded - Array of DocumentRef.ProductionStage2_2 -
// * AdjustmentCreated - Array of DocumentRef.InventoryAssignmentAdjustment -
// * OrderChanged - Array of DocumentRef.ProductionOrder2_2 -
// * Cancel - Boolean - 
// * Messages - Array of String-
// 
Function ResultOfProcessingConstructor() Export
	
	Result = New Structure;
	Result.Insert("StageCreated", New Array);
	Result.Insert("ChangedStage", New Array);
	Result.Insert("StageRemoved", New Array);
	Result.Insert("StageIsNotRecorded", New Array);
	Result.Insert("AdjustmentCreated", New Array);
	Result.Insert("OrderChanged", New Array);
	Result.Insert("Cancel", False);
	Result.Insert("Messages", New Array);
	
	Return Result
	
EndFunction

#EndRegion

#Region Private

// A production process tree consisting of stage documents and their operation queues (conditionally).
// 
// Parameters:
//  ProductionLot - CatalogRef.ProductionLots - Production batch
//  GetOperations - Boolean - if True, then the tree will contain stages and operations, if False, then only stages
// 
// Returns:
//  ValueTree - Production Process Tree:
// * ItemKind - String -
// * OperationID - Number -
// * Picture - Picture -
// * Description - String -
// * Number - Number -
// * TheNumberOfTheNextOne - Number -
// * Department - CatalogRef.BusinessStructure -
// * ProductionByThirdParty - Boolean -
// * WorkCenter - CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes -
// * Ref - DocumentRef.ProductionStage2_2, CatalogRef.ManufacturingOperations -
// * TechnologicalProcess - CatalogRef.TechnologicalProcesses -
// * ReadOnly - Boolean -
// * ThisIsAStep - Boolean -
// * Status - String -
// * DocumentNumber - String -
// * OperationsTotal - Number -
// * OperationsToDestination - Number -
// * OperationsToDestinationPresentation - String -
//
Function TreeProductionProcess(ProductionLot, GetOperations) Export
	
	Tree = New ValueTree();
	Tree.Columns.Add("ItemKind", New TypeDescription("String",, New StringQualifiers()));
	Tree.Columns.Add("OperationID", New TypeDescription("Number", New NumberQualifiers()));
	Tree.Columns.Add("Picture", New TypeDescription("Picture"));
	Tree.Columns.Add("Description", New TypeDescription("String",, New StringQualifiers()));
	Tree.Columns.Add("Number", New TypeDescription("Number", New NumberQualifiers()));
	Tree.Columns.Add("TheNumberOfTheNextOne", New TypeDescription("Number", New NumberQualifiers()));
	Tree.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	Tree.Columns.Add("ProductionByThirdParty", New TypeDescription("Boolean"));
	Tree.Columns.Add("WorkPlanning", New TypeDescription("Boolean"));
	Tree.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes"));
	Tree.Columns.Add("Ref", New TypeDescription("DocumentRef.ProductionStage2_2, CatalogRef.ManufacturingOperations"));
	Tree.Columns.Add("ProductionOperation", New TypeDescription("DocumentRef.ProductionOperation2_2"));
	Tree.Columns.Add("TechnologicalProcess", New TypeDescription("CatalogRef.TechnologicalProcesses"));
	Tree.Columns.Add("ReadOnly", New TypeDescription("Boolean"));
	
	// Specific workplace columns
	Tree.Columns.Add("ThisIsAStep", New TypeDescription("Boolean"));
	Tree.Columns.Add("Status", New TypeDescription("String",, New StringQualifiers()));
	Tree.Columns.Add("DocumentNumber", New TypeDescription("String",, New StringQualifiers()));
	Tree.Columns.Add("OperationsTotal", New TypeDescription("Number", New NumberQualifiers()));
	Tree.Columns.Add("OperationsToDestination", New TypeDescription("Number", New NumberQualifiers()));
	Tree.Columns.Add("OperationsToDestinationPresentation", New TypeDescription("String",, New StringQualifiers()));
	
	SamplingStages = Undefined;
	Operations = Undefined;
	
	Query = New Query();
	Query.SetParameter("ProductionLot", ProductionLot);
	Query.SetParameter("TypeOfStageElement", ProductionProcessEditorClientServer.TypeOfStageElement());
	Query.SetParameter("TypeOfElementOfOperation", ProductionProcessEditorClientServer.TypeOfElementOfOperation());
	
	QueryTexts = New Array;
	QueryTexts.Add(
		"SELECT
		|	Stages.Ref               AS Ref,
		|	Stages.StageName    AS Description,
		|	Stages.Number                AS DocumentNumber,
		|	Stages.StageNumber           AS Number,
		|	Stages.NextStageNo AS TheNumberOfTheNextOne,
		|	Stages.Status               AS Status,
		|	Stages.Department        AS Department,
		|	Stages.ProductionByThirdParty
		|		OR Stages.ProductionByThirdParty2_5 AS ProductionByThirdParty,
		|	Stages.WorkPlanning    AS WorkPlanning
		|INTO TTStages
		|FROM
		|	Document.ProductionStage2_2 AS Stages
		|WHERE
		|	Stages.ProductionLot = &ProductionLot
		|	AND Stages.Posted
		|
		|INDEX BY
		|	Ref");
	
	If GetOperations Then
		QueryTexts.Add(
			TextOfRequestTTQueueOfOperationsForDivision(
				"SELECT
				|	Stages.Ref AS Stage
				|FROM
				|	TTStages AS Stages"));
	
		QueryTexts.Add(
			"SELECT
			|	Operations.Stage                                AS Stage,
			|	Operations.OperationID               AS OperationID,
			|	MAX(Operations.Number)                     AS DocumentNumber,
			|	MAX(Operations.Status)                    AS Status,
			|	MAX(Operations.WorkCenter)              AS WorkCenter,
			|	COUNT(DISTINCT(Operations.Ref))       AS DocumentsCount,
			|	COUNT(DISTINCT(Operations.Status))       AS NumberOfStatuses,
			|	COUNT(DISTINCT(Operations.WorkCenter)) AS NumberOfWorkCenters
			|INTO TTOperations
			|FROM
			|	Document.ProductionOperation2_2 AS Operations
			|WHERE
			|	Operations.Stage IN
			|		(SELECT
			|			Stages.Ref AS Stage
			|		FROM
			|			TTStages AS Stages)
			|	AND Operations.Posted
			|
			|GROUP BY
			|	Operations.Stage,
			|	Operations.OperationID
			|
			|INDEX BY
			|	Stage, OperationID
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	&TypeOfStageElement            AS ItemKind,
			|	Stages.Ref                AS Stage,
			|	Stages.Ref                AS Ref,
			|	Stages.Description          AS Description,
			|	Stages.DocumentNumber        AS DocumentNumber,
			|	Stages.Number                 AS Number,
			|	Stages.TheNumberOfTheNextOne       AS TheNumberOfTheNextOne,
			|	Stages.Status                AS Status,
			|	Stages.Department         AS Department,
			|	UNDEFINED                AS WorkCenter,
			|	Stages.ProductionByThirdParty AS ProductionByThirdParty,
			|	Stages.WorkPlanning     AS WorkPlanning,
			|	0                           AS OperationID,
			|	TRUE                      AS ThisIsAStep,
			|	1                           AS DocumentsCount,
			|	FALSE                        AS MultipleStatuses,
			|	0                           AS OperationsTotal,
			|	0                           AS OperationsToDestination
			|FROM
			|	TTStages AS Stages
			|
			|ORDER BY
			|	Number,
			|	TheNumberOfTheNextOne,
			|	Ref
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	&TypeOfElementOfOperation                               AS ItemKind,
			|	Queue.Stage                                       AS Stage,
			|	Queue.Operation                                   AS Ref,
			|	Queue.Description                               AS Description,
			|	ISNULL(Documents.DocumentNumber, """")           AS DocumentNumber,
			|	Queue.OperationNumber                              AS Number,
			|	Queue.NextOperation                     AS TheNumberOfTheNextOne,
			|	ISNULL(Documents.Status, """")                   AS Status,
			|	UNDEFINED                                       AS Department,
			|	CASE
			|		WHEN Documents.WorkCenter IS NULL
			|			THEN CAST(Queue.Operation AS Catalog.ManufacturingOperations).WorkCenter
			|		WHEN Documents.NumberOfWorkCenters > 1
			|			THEN UNDEFINED
			|		ELSE Documents.WorkCenter
			|	END                                              AS WorkCenter,
			|	FALSE                                               AS ProductionByThirdParty,
			|	FALSE                                               AS WorkPlanning,
			|	Queue.OperationID                      AS OperationID,
			|	Queue.ProductionOperation                   AS ProductionOperation,
			|	FALSE                                               AS ThisIsAStep,
			|	ISNULL(Documents.DocumentsCount, 0)        AS DocumentsCount,
			|	ISNULL(Documents.NumberOfStatuses, 0) > 1      AS MultipleStatuses,
			|	Queue.OperationsTotal                              AS OperationsTotal,
			|	Queue.OperationsToDestination                        AS OperationsToDestination
			|FROM
			|	TTOperationQueue AS Queue
			|	
			|	LEFT JOIN TTOperations AS Documents
			|	ON Queue.Stage = Documents.Stage
			|		AND Queue.OperationID = Documents.OperationID
			|
			|ORDER BY
			|	Number,
			|	TheNumberOfTheNextOne,
			|	Description,
			|	Ref");
		Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		SetPrivilegedMode(True);
		ResultsArray = Query.ExecuteBatch();
		SetPrivilegedMode(False);
		SamplingStages = ResultsArray[ResultsArray.UBound()-1].Select();
		Operations = ResultsArray[ResultsArray.UBound()].Unload();
		Operations.Indexes.Add("Stage");
	Else
		QueryTexts.Add(
			"SELECT
			|	&TypeOfStageElement            AS ItemKind,
			|	Stages.Ref                AS Stage,
			|	Stages.Ref                AS Ref,
			|	Stages.Description          AS Description,
			|	Stages.DocumentNumber        AS DocumentNumber,
			|	Stages.Number                 AS Number,
			|	Stages.TheNumberOfTheNextOne       AS TheNumberOfTheNextOne,
			|	Stages.Status                AS Status,
			|	Stages.Department         AS Department,
			|	UNDEFINED                AS WorkCenter,
			|	Stages.ProductionByThirdParty AS ProductionByThirdParty,
			|	Stages.WorkPlanning     AS WorkPlanning,
			|	0                           AS OperationID,
			|	TRUE                      AS ThisIsAStep,
			|	1                           AS DocumentsCount,
			|	FALSE                        AS MultipleStatuses,
			|	0                           AS OperationsTotal,
			|	0                           AS OperationsToDestination
			|FROM
			|	TTStages AS Stages
			|
			|ORDER BY
			|	Number,
			|	TheNumberOfTheNextOne,
			|	Description,
			|	Ref");
		Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		SamplingStages = Query.Execute().Select();
	EndIf;
	
	TheStructureOfTheSearch = New Structure("Stage");
	While SamplingStages.Next() Do
		StageString = Tree.Rows.Add();
		FillPropertyValues(StageString, SamplingStages);
		ProductionProcessEditorClientServer.SetItemImage(StageString);
		
		StageString.OperationsToDestinationPresentation = "-";
		If Operations <> Undefined Then
			TheStructureOfTheSearch.Stage = SamplingStages.Stage;
			For Each FoundRow In Operations.FindRows(TheStructureOfTheSearch) Do
				LineOperation = StageString.Rows.Add();
				FillPropertyValues(LineOperation, FoundRow);
				ProductionProcessEditorClientServer.SetItemImage(LineOperation);
				If FoundRow.DocumentsCount = 0 Then
					LineOperation.DocumentNumber = "-";
					LineOperation.Status = NStr("vi = 'Đã lập kế hoạch';
												|ru = 'Запланирована';
												|en = 'Scheduled'; fa = 'برنامه‌ریزی‌شده';
												|it = 'Запланирована';
												|pl = 'Scheduled';
												|tr = 'Planlandı'");
				ElsIf FoundRow.DocumentsCount > 1 Then
					LineOperation.DocumentNumber = NStr("vi = '<nhiều chứng từ>';
														|ru = '<несколько документов>';
														|en = '<multiple documents>'; fa = '<multiple documents>';
														|it = '<несколько документов>';
														|pl = '<multiple documents>';
														|tr = '<birden fazla belge>'");
				EndIf;
				
				If FoundRow.MultipleStatuses Then
					LineOperation.Status = NStr("vi = '<trạng thái khác nhau>';
												|ru = '<разные статусы>';
												|en = '<different statuses>'; fa = '<different statuses>';
												|it = '<разные статусы>';
												|pl = '<different statuses>';
												|tr = '<farklı durumlar>'");
				EndIf;
				
				LineOperation.OperationsToDestinationPresentation = ?(FoundRow.OperationsToDestination > 0,
					StrTemplate("%1 from %2", FoundRow.OperationsToDestination, FoundRow.OperationsTotal),
					"-");
			EndDo;
		EndIf;
	EndDo;
	
	Return Tree;
	
EndFunction

Procedure CreateTTQueueOfOperationsForDivision(TempTablesManager, Stage) Export
	
	QueryText = TextOfRequestTTQueueOfOperationsForDivision("&Stage");
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Stage", Stage);
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
EndProcedure

Function Actions() Export
	
	Result = New Structure;
	Result.Insert("Reduce", 0);
	Result.Insert("Cancel", 1);
	Result.Insert("Split", 2);
	Result.Insert("Continue", 3);
	Result.Insert("Fill", 4);
	Result.Insert("DefectiveGoods", 5);
	
	Return Result;
	
EndFunction

Function TextOfRequestTTQueueOfOperationsForDivision(TextSelectionStages)
	
	RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
	RequestTextParameters.ExecutionIndicators = True;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add("Queue.Stage IN (&TextSelectionStages)");
	
	QueryText = InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters) + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Shifts.Stage AS Stage,
		|	Shifts.OperationID AS OperationID,
		|	SUM(Shifts.Count) AS Assigned_
		|INTO TTShifts
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS Shifts
		|WHERE
		|	Shifts.Stage IN (&TextSelectionStages)
		|	AND Shifts.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|
		|GROUP BY
		|	Shifts.Stage,
		|	Shifts.OperationID
		|
		|HAVING
		|	SUM(Shifts.Count) > 0
		|
		|INDEX BY
		|	Stage, OperationID
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Queue.Stage AS Stage,
		|	Queue.OperationID AS OperationID
		|INTO IndividualTT
		|FROM
		|	TTQueue AS Queue
		|WHERE
		|	Queue.Stage IN (&TextSelectionStages)
		|	AND Queue.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef)
		|	AND Queue.ProductionOperation <> VALUE(Document.ProductionOperation2_2.EmptyRef)
		|
		|INDEX BY
		|	Stage, OperationID
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Queue.Stage                                      AS Stage,
		|	Queue.Operation                                  AS Operation,
		|	Queue.Description                              AS Description,
		|	Queue.OperationID                     AS OperationID,
		|	Queue.ControlOperationID          AS ControlOperationID,
		|	Queue.ProductionOperation                  AS ProductionOperation,
		|	Queue.OperationNumber                             AS OperationNumber,
		|	Queue.NextOperation                    AS NextOperation,
		|	Queue.Scheduled - Queue.RepetitionIsRequired AS OperationsTotal,
		|	CASE
		|		WHEN Queue.Scheduled > (Queue.CreatedOn + ISNULL(Shifts.Assigned_, 0))
		|				AND SpecialTerms.OperationID IS NULL
		|			THEN Queue.Scheduled - (Queue.CreatedOn + ISNULL(Shifts.Assigned_, 0))
		|		ELSE 0
		|	END                                             AS OperationsToDestination,
		|	Queue.CreatedOn <> 0
		|		OR Shifts.Assigned_ IS NOT NULL              AS IsStarted,
		|	Queue.DefectiveGoods > 0                                  AS ThereIsDefectiveGoods,
		|	SpecialTerms.OperationID IS NOT NULL AS ThisIsIndividualOperation
		|INTO TTOperationQueue
		|FROM
		|	TTQueue AS Queue
		|	
		|	LEFT JOIN TTShifts AS Shifts
		|	ON Queue.Stage = Shifts.Stage
		|		AND Queue.OperationID = Shifts.OperationID
		|
		|	LEFT JOIN IndividualTT AS SpecialTerms
		|	ON Queue.Stage = SpecialTerms.Stage
		|		AND Queue.OperationID = SpecialTerms.OperationID
		|
		|WHERE
		|	Queue.Stage IN (&TextSelectionStages)
		|
		|INDEX BY
		|	Stage, OperationID
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTShifts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTQueue
		|
		|";
	
	QueryText = StrReplace(QueryText, "&TextSelectionStages", TextSelectionStages);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf

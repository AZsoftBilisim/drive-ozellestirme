#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Generates data for the workplace.
// 
// Parameters:
//  Parameters - Structure - Contains:
//  	* Organization - CatalogRef.Companies -
//  	* Department - CatalogRef.BusinessStructure -
//  	* FixedAsset - CatalogRef.Assets -
//  	* BeginOfPeriod - Date -
//  	* EndOfPeriod - Date -
// 
// Returns:
//  Structure - The data of the workplace:
//  	* List - ValueTable -
//  	* List_Expenses - ValueTable -
//  	* LocalCurrencyList - ValueTable -
//
Function WorkplaceData(Parameters) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DataProcessor.RecognizeAndIncludeExpensesInFixedAssetCost.WorkplaceData");

	ListOfRequests = New Array;
	
	#Region PreparationOfTables
	
	QueryText = 
	"SELECT ALLOWED
	|	AvailableArticles.Ref AS Ref
	|
	|INTO AvailableArticles
	|
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS AvailableArticles
	|
	|WHERE
	|	AvailableArticles.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|
	|	AND (AvailableArticles.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR AvailableArticles.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR AvailableArticles.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|	AND (AvailableArticles.ExpensesOnAssets
	|		OR AvailableArticles.ExpensesOnConstructionObjects)
	|	
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OtherExpenses.Recorder AS Recorder,
	|	OtherExpenses.Period AS Period,
	|	OtherExpenses.DimensionOfExpenses AS FixedAsset,
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.VariancePeriod AS VariancePeriod,
	|	
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|			AND OtherExpenses.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN CASE 
	|					WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN OtherExpenses.SumMan
	|					ELSE -OtherExpenses.SumMan
	|				END
	|		ELSE 0
	|	END AS AmountOfUU,
	|	
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|			AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		THEN CASE 
	|				WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN OtherExpenses.SumCompl
	|					ELSE -OtherExpenses.SumCompl
	|				END
	|		ELSE 0
	|	END AS AmountAccounting,
	|	
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|			AND OtherExpenses.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN CASE 
	|					WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN OtherExpenses.SumCompl - OtherExpenses.PermanentDifference - OtherExpenses.CostTD
	|					ELSE -OtherExpenses.SumCompl - OtherExpenses.PermanentDifference - OtherExpenses.CostTD
	|				END
	|		ELSE 0
	|	END AS AmountFA
	|
	|INTO OtherExpensesOf_RegisterRecorded
	|
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|
	|WHERE
	|	OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND OtherExpenses.Active
	|
	|	AND (OtherExpenses.Organization = &Organization
	|			OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|	AND (OtherExpenses.Department = &Department
	|			OR &Department = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|	AND (OtherExpenses.DimensionOfExpenses = &FixedAsset
	|			OR &FixedAsset = VALUE(Catalog.Assets.EmptyRef))
	|
	|	AND OtherExpenses.ExpenseItem IN (
	|				SELECT
	|					AvailableArticles.Ref
	|				FROM
	|			 		AvailableArticles)
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OtherExpenses.Period AS Period,
	|	OtherExpenses.FixedAsset AS FixedAsset,
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.VariancePeriod AS VariancePeriod,
	|	
	|	OtherExpenses.AmountOfUU AS AmountOfUU,
	|	OtherExpenses.AmountAccounting AS AmountAccounting,
	|	OtherExpenses.AmountFA AS AmountFA
	|
	|INTO OtherExpenses
	|
	|FROM
	|	(SELECT
	|		&BeginOfPeriod AS Period,
	|		OtherExpenses.DimensionOfExpenses AS FixedAsset,
	|		OtherExpenses.Organization AS Organization,
	|		DATETIME(1,1,1) AS VariancePeriod,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN OtherExpenses.SumManBalance
	|			ELSE 0
	|		END AS AmountOfUU,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN OtherExpenses.SumComplBalance
	|			ELSE 0
	|		END AS AmountAccounting,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN OtherExpenses.SumComplBalance - OtherExpenses.PermanentDifferenceBalance - OtherExpenses.CostTDBalance
	|			ELSE 0
	|		END AS AmountFA
	|
	|	FROM
	|		AccumulationRegister.OtherExpenses.Balance(
	|			&BeginOfPeriod,
	|			(Organization = &Organization
	|					OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|				AND (Department = &Department
	|					OR &Department = VALUE(Catalog.BusinessStructure.EmptyRef))
	|				AND (DimensionOfExpenses = &FixedAsset
	|					OR &FixedAsset = VALUE(Catalog.Assets.EmptyRef))
	|				AND ExpenseItem IN (
	|					SELECT
	|						AvailableArticles.Ref
	|					FROM
	|				 		AvailableArticles)
	|			) AS OtherExpenses
	|
	|	UNION ALL
	|
	|	SELECT
	|		OtherExpenses.Period AS Period,
	|		OtherExpenses.FixedAsset AS FixedAsset,
	|		OtherExpenses.Organization AS Organization,
	|		OtherExpenses.VariancePeriod AS VariancePeriod,
	|	
	|		OtherExpenses.AmountOfUU AS AmountOfUU,
	|		OtherExpenses.AmountAccounting AS AmountAccounting,
	|		OtherExpenses.AmountFA AS AmountFA
	|
	|	FROM
	|		OtherExpensesOf_RegisterRecorded AS OtherExpenses
	|
	|	WHERE
	|		NOT VALUETYPE(OtherExpenses.Recorder) IN (&TypesOfDocumentsForWhichCostIsCalculated)
	|
	|	UNION ALL
	|
	|	SELECT 
	|		DocumentData.Date AS Period,
	|		GoodsTable.DimensionOfExpenses AS FixedAsset,
	|		DocumentData.Organization AS Organization,
	|		DATETIME(1,1,1) AS VariancePeriod,
	|	
	|		0 AS AmountOfUU,
	|		0 AS AmountAccounting,
	|		0 AS AmountFA
	|
	|	FROM
	|		Document.InventoryConsumption AS DocumentData
	|
	|			INNER JOIN Document.InventoryConsumption.Goods GoodsTable
	|			ON GoodsTable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND DocumentData.Posted
	|
	|		AND (DocumentData.Organization = &Organization
	|				OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|		AND (DocumentData.Department = &Department
	|			OR &Department = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|		AND (GoodsTable.DimensionOfExpenses = &FixedAsset
	|			OR &FixedAsset = VALUE(Catalog.Assets.EmptyRef))
	|
	|		AND GoodsTable.ExpenseItem IN (
	|					SELECT
	|						AvailableArticles.Ref
	|					FROM
	|				 		AvailableArticles)
	|
	|	) AS OtherExpenses
	|
	|WHERE
	|	VALUETYPE(OtherExpenses.FixedAsset) IN (
	|		TYPE(Catalog.Assets),
	|		TYPE(Catalog.ConstructionObjects))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.FixedAsset AS FixedAsset
	|
	|INTO ListOfFA
	|
	|FROM
	|	OtherExpenses AS OtherExpenses
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.FixedAsset AS FixedAsset,
	|	MAX(ISNULL(InitialFixedAssetsInformation.CommissioningDateAC, DATETIME(1,1,1))) AS DateOfRecognitionAccounting,
	|	MAX(ISNULL(InitialFixedAssetsInformation.CommissioningDateTA, DATETIME(1,1,1))) AS DateOfRecognitionInTaxAccounting,
	|	MAX(ISNULL(InitialFixedAssetsInformation.CommissioningDateMA, DATETIME(1,1,1))) AS DateOfRecognitionManagementAccounting,
	|	MAX(ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_))) AS BUState,
	|	MAX(ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_))) AS StateTa,
	|	MAX(ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_))) AS StateOfTheUU
	|
	|INTO StateOfFA
	|
	|FROM
	|	OtherExpenses AS OtherExpenses
	|
	|		LEFT JOIN InformationRegister.InitialFixedAssetsInformation.SliceLast(
	|			&EndOfPeriod, 
	|			(Organization, FixedAsset) IN
	|				(SELECT
	|					ListOfFA.Organization,
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfFA AS ListOfFA)) AS InitialFixedAssetsInformation
	|		ON InitialFixedAssetsInformation.Organization = OtherExpenses.Organization
	|			AND InitialFixedAssetsInformation.FixedAsset = OtherExpenses.FixedAsset
	|
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&EndOfPeriod, 
	|			(Organization, FixedAsset) IN
	|				(SELECT
	|					ListOfFA.Organization,
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfFA AS ListOfFA)) AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.Organization = OtherExpenses.Organization
	|			AND FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = OtherExpenses.FixedAsset
	|
	|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&EndOfPeriod, 
	|			(Organization, FixedAsset) IN
	|				(SELECT
	|					ListOfFA.Organization,
	|					ListOfFA.FixedAsset
	|				FROM
	|					ListOfFA AS ListOfFA)) AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Organization = OtherExpenses.Organization
	|			AND AccountingProcedureForOSBU.FixedAsset = OtherExpenses.FixedAsset
	|
	|GROUP BY
	|	OtherExpenses.Organization,
	|	OtherExpenses.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CurrentDocuments.Period AS Period,
	|	CurrentDocuments.ExpensesCapitalizationDimension AS ExpensesCapitalizationDimension,
	|
	|	CurrentDocuments.RecordInManAccounting AS RecordInManAccounting,
	|
	|	ISNULL(FixedAssetsInitialRecognition.PostInAccounting, 
	|		ISNULL(FixedAssetsCostAdditions.PostInAccounting, 
	|			ISNULL(AllocateVariancesToFixedAssetCost.PostInAccounting, CurrentDocuments.RecordInLocalAccounting))) AS PostInAccounting,
	|
	|	ISNULL(FixedAssetsInitialRecognition.RecordInTA, 
	|		ISNULL(FixedAssetsCostAdditions.RecordInTA, 
	|			ISNULL(AllocateVariancesToFixedAssetCost.RecordInTA, CurrentDocuments.RecordInLocalAccounting))) AS RecordInTA
	|
	|INTO CostAccountingDocuments
	|
	|FROM
	|	AccumulationRegister.FACost AS CurrentDocuments
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4 AS FixedAssetsInitialRecognition
	|		ON FixedAssetsInitialRecognition.Ref = CurrentDocuments.Recorder
	|
	|		LEFT JOIN Document.FixedAssetsCostAdditions2_4 AS FixedAssetsCostAdditions
	|		ON FixedAssetsCostAdditions.Ref = CurrentDocuments.Recorder
	|
	|		LEFT JOIN Document.AllocateVariancesToFixedAssetCost AS AllocateVariancesToFixedAssetCost
	|		ON AllocateVariancesToFixedAssetCost.Ref = CurrentDocuments.Recorder
	|
	|WHERE
	|	CurrentDocuments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VALUETYPE(CurrentDocuments.Recorder) IN (&TypesOfDocumentsForWhichCostIsCalculated)
	|
	|	AND CurrentDocuments.FixedAsset IN (
	|		SELECT
	|			OtherExpenses.FixedAsset
	|		FROM
	|			OtherExpenses AS OtherExpenses)
	|
	|INDEX BY
	|	ExpensesCapitalizationDimension,
	|	Period
	|";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region DataSelection
	
	QueryText =
	"SELECT DISTINCT
	|	OtherExpenses.Organization.LocalAccountingCurrency AS ComplCurrency
	|FROM
	|	OtherExpenses AS OtherExpenses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherExpenses.Recorder AS Document,
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.FixedAsset AS FixedAsset,
	|	OtherExpenses.VariancePeriod AS VariancePeriod,
	|	ISNULL(CAST(OtherExpenses.FixedAsset AS Catalog.Assets).OSType, VALUE(Enum.FATypes.EmptyRef)) AS OSType,
	|
	|	CASE
	|		WHEN OtherExpenses.FixedAsset REFS Catalog.Assets
	|			THEN ISNULL(StateOfFA.StateOfTheUU, VALUE(Enum.FixedAssetsStates.NotRecognized_)) 
	|		ELSE ISNULL(ConstructionObjects.ConstructionStatus, VALUE(Enum.FixedAssetsStates.EmptyRef))
	|	END AS StateOfTheUU,
	|
	|	CASE
	|		WHEN OtherExpenses.FixedAsset REFS Catalog.Assets
	|			THEN ISNULL(StateOfFA.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) 
	|		ELSE ISNULL(ConstructionObjects.ConstructionStatus, VALUE(Enum.FixedAssetsStates.EmptyRef))
	|	END AS BUState,
	|
	|	CASE
	|		WHEN OtherExpenses.FixedAsset REFS Catalog.Assets
	|			THEN ISNULL(StateOfFA.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_)) 
	|		ELSE ISNULL(ConstructionObjects.ConstructionStatus, VALUE(Enum.FixedAssetsStates.EmptyRef))
	|	END AS StateTa,
	|
	|	OtherExpenses.AmountOfUU AS AmountOfUU,
	|	OtherExpenses.AmountAccounting AS AmountAccounting,
	|	OtherExpenses.AmountFA AS AmountFA,
	|
	|	OtherExpenses.ACTakenIntoAccount AS ACTakenIntoAccount,
	|	OtherExpenses.TakenIntoAccountTA AS TakenIntoAccountTA,
	|	OtherExpenses.TakenIntoAccountMA AS TakenIntoAccountMA,
	|
	|	OtherExpenses.ACTakenIntoAccount 
	|		AND OtherExpenses.TakenIntoAccountTA 
	|		AND OtherExpenses.TakenIntoAccountMA AS Considered_3
	|
	|FROM
	|	(SELECT
	|		OtherExpenses.Recorder AS Recorder,
	|		OtherExpenses.Organization AS Organization,
	|		OtherExpenses.FixedAsset AS FixedAsset,
	|		OtherExpenses.VariancePeriod AS VariancePeriod,
	|	
	|		SUM(OtherExpenses.AmountOfUU) AS AmountOfUU,
	|		SUM(OtherExpenses.AmountAccounting) AS AmountAccounting,
	|		SUM(OtherExpenses.AmountFA) AS AmountFA,
	|
	|		MIN(OtherExpenses.ACTakenIntoAccount) AS ACTakenIntoAccount,
	|		MIN(OtherExpenses.TakenIntoAccountTA) AS TakenIntoAccountTA,
	|		MIN(OtherExpenses.TakenIntoAccountMA) AS TakenIntoAccountMA
	|
	|	FROM
	|		(SELECT
	|			OtherExpenses.Recorder AS Recorder,
	|			OtherExpenses.Organization AS Organization,
	|			OtherExpenses.FixedAsset AS FixedAsset,
	|			OtherExpenses.VariancePeriod AS VariancePeriod,
	|	
	|			OtherExpenses.AmountOfUU AS AmountOfUU,
	|			OtherExpenses.AmountAccounting AS AmountAccounting,
	|			OtherExpenses.AmountFA AS AmountFA,
	|
	|			CASE
	|				WHEN TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							CostAccountingDocuments AS CostAccountingDocuments
	|						WHERE
	|							CostAccountingDocuments.ExpensesCapitalizationDimension = OtherExpenses.FixedAsset
	|							AND CostAccountingDocuments.Period >= OtherExpenses.Period
	|							AND (OtherExpenses.AmountAccounting = 0 OR CostAccountingDocuments.PostInAccounting))
	|					THEN TRUE
	|				ELSE FALSE
	|			END AS ACTakenIntoAccount,
	|
	|			CASE
	|				WHEN TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							CostAccountingDocuments AS CostAccountingDocuments
	|						WHERE
	|							CostAccountingDocuments.ExpensesCapitalizationDimension = OtherExpenses.FixedAsset
	|							AND CostAccountingDocuments.Period >= OtherExpenses.Period
	|							AND (OtherExpenses.AmountFA = 0 OR CostAccountingDocuments.RecordInTA))
	|					THEN TRUE
	|				ELSE FALSE
	|			END AS TakenIntoAccountTA,
	|
	|			CASE
	|				WHEN TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							CostAccountingDocuments AS CostAccountingDocuments
	|						WHERE
	|							CostAccountingDocuments.ExpensesCapitalizationDimension = OtherExpenses.FixedAsset
	|							AND CostAccountingDocuments.Period >= OtherExpenses.Period
	|							AND (OtherExpenses.AmountOfUU = 0 OR CostAccountingDocuments.RecordInManAccounting))
	|					THEN TRUE
	|				ELSE FALSE
	|			END AS TakenIntoAccountMA
	|
	|		FROM
	|			OtherExpensesOf_RegisterRecorded AS OtherExpenses
	|
	|		WHERE
	|			OtherExpenses.VariancePeriod <> DATETIME(1,1,1)
	|			AND NOT VALUETYPE(OtherExpenses.Recorder) IN (&TypesOfDocumentsForWhichCostIsCalculated)
	|
	|		) AS OtherExpenses
	|
	|	GROUP BY
	|		OtherExpenses.Recorder,
	|		OtherExpenses.Organization,
	|		OtherExpenses.FixedAsset,
	|		OtherExpenses.VariancePeriod
	|
	|	) AS OtherExpenses
	|
	|		LEFT JOIN StateOfFA AS StateOfFA
	|		ON StateOfFA.Organization = OtherExpenses.Organization
	|			AND StateOfFA.FixedAsset = OtherExpenses.FixedAsset
	|
	|		LEFT JOIN Catalog.ConstructionObjects AS ConstructionObjects
	|		ON ConstructionObjects.Ref = OtherExpenses.FixedAsset
	|
	|ORDER BY
	|	VariancePeriod,
	|	Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherExpenses.FixedAsset AS FixedAsset,
	|	ISNULL(Assets.Description, ConstructionObjects.Description) AS RefPresentation,
	|	ISNULL(Assets.AssetID, """") AS AssetID,
	|	ISNULL(Assets.Code, ConstructionObjects.Code) AS Code,
	|	OtherExpenses.Organization AS Organization,
	|
	|	CASE
	|		WHEN VALUETYPE(OtherExpenses.FixedAsset) = TYPE(Catalog.ConstructionObjects)
	|			THEN &PresentationOfConstructionSites
	|		WHEN ISNULL(Assets.OSType, UNDEFINED) = VALUE(Enum.FATypes.GroupFA)
	|			THEN &PresentationGroupFA
	|		WHEN ISNULL(Assets.OSType, UNDEFINED) = VALUE(Enum.FATypes.DepreciationComponent)
	|			THEN &PresentationOfDepreciationComponent
	|		WHEN ISNULL(Assets.OSType, UNDEFINED) = VALUE(Enum.FATypes.Node)
	|			THEN &PresentationNode
	|		WHEN ISNULL(Assets.OSType, UNDEFINED) = VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets)
	|			THEN &PresentationCapitalInvestment
	|		ELSE &PresentationOfObjectOfOperation
	|	END AS PresentationOfFAType,
	|
	|	ISNULL(Assets.OSType, VALUE(Enum.FATypes.EmptyRef)) AS OSType,
	|	
	|	ISNULL(StateOfFA.DateOfRecognitionAccounting, DATETIME(1,1,1)) AS DateOfRecognitionAccounting,
	|	ISNULL(StateOfFA.DateOfRecognitionInTaxAccounting, DATETIME(1,1,1)) AS DateOfRecognitionInTaxAccounting,
	|	ISNULL(StateOfFA.DateOfRecognitionManagementAccounting, DATETIME(1,1,1)) AS DateOfRecognitionManagementAccounting,
	|
	|	CASE
	|		WHEN OtherExpenses.FixedAsset REFS Catalog.Assets
	|			THEN ISNULL(StateOfFA.StateOfTheUU, VALUE(Enum.FixedAssetsStates.NotRecognized_)) 
	|		ELSE ISNULL(ConstructionObjects.ConstructionStatus, VALUE(Enum.FixedAssetsStates.NotRecognized_))
	|	END AS StateOfTheUU,
	|
	|	CASE
	|		WHEN OtherExpenses.FixedAsset REFS Catalog.Assets
	|			THEN ISNULL(StateOfFA.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) 
	|		ELSE ISNULL(ConstructionObjects.ConstructionStatus, VALUE(Enum.FixedAssetsStates.NotRecognized_))
	|	END AS BUState,
	|
	|	CASE
	|		WHEN OtherExpenses.FixedAsset REFS Catalog.Assets
	|			THEN ISNULL(StateOfFA.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_)) 
	|		ELSE ISNULL(ConstructionObjects.ConstructionStatus, VALUE(Enum.FixedAssetsStates.NotRecognized_))
	|	END AS StateTa,
	|
	|	OtherExpenses.AmountOfUU AS AmountOfUU,
	|	OtherExpenses.AmountAccounting AS AmountAccounting,
	|	OtherExpenses.AmountFA AS AmountFA,
	|
	|	OtherExpenses.ThereAreVariances AS ThereAreVariances,
	|
	|	OtherExpenses.ACTakenIntoAccount AS ACTakenIntoAccount,
	|	OtherExpenses.TakenIntoAccountTA AS TakenIntoAccountTA,
	|	OtherExpenses.TakenIntoAccountMA AS TakenIntoAccountMA,
	|
	|	OtherExpenses.ACTakenIntoAccount 
	|		AND OtherExpenses.TakenIntoAccountTA 
	|		AND OtherExpenses.TakenIntoAccountMA AS Considered_3
	|
	|FROM
	|	(SELECT
	|		OtherExpenses.FixedAsset AS FixedAsset,
	|		OtherExpenses.Organization AS Organization,
	|
	|		SUM(OtherExpenses.AmountOfUU) AS AmountOfUU,
	|		SUM(OtherExpenses.AmountAccounting) AS AmountAccounting,
	|		SUM(OtherExpenses.AmountFA) AS AmountFA,
	|
	|		MAX(OtherExpenses.ThereAreVariances) AS ThereAreVariances,
	|		MIN(OtherExpenses.ACTakenIntoAccount) AS ACTakenIntoAccount,
	|		MIN(OtherExpenses.TakenIntoAccountTA) AS TakenIntoAccountTA,
	|		MIN(OtherExpenses.TakenIntoAccountMA) AS TakenIntoAccountMA
	|
	|	FROM
	|		(SELECT
	|			OtherExpenses.FixedAsset AS FixedAsset,
	|			OtherExpenses.Organization AS Organization,
	|
	|			OtherExpenses.AmountOfUU AS AmountOfUU,
	|			OtherExpenses.AmountAccounting AS AmountAccounting,
	|			OtherExpenses.AmountFA AS AmountFA,
	|
	|			CASE
	|				WHEN OtherExpenses.VariancePeriod <> DATETIME(1,1,1)
	|					THEN TRUE
	|				ELSE FALSE
	|			END AS ThereAreVariances,
	|
	|			CASE
	|				WHEN TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							CostAccountingDocuments AS CostAccountingDocuments
	|						WHERE
	|							CostAccountingDocuments.ExpensesCapitalizationDimension = OtherExpenses.FixedAsset
	|							AND CostAccountingDocuments.Period >= OtherExpenses.Period
	|							AND (OtherExpenses.AmountAccounting = 0 OR CostAccountingDocuments.PostInAccounting))
	|					THEN TRUE
	|				ELSE FALSE
	|			END AS ACTakenIntoAccount,
	|
	|			CASE
	|				WHEN TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							CostAccountingDocuments AS CostAccountingDocuments
	|						WHERE
	|							CostAccountingDocuments.ExpensesCapitalizationDimension = OtherExpenses.FixedAsset
	|							AND CostAccountingDocuments.Period >= OtherExpenses.Period
	|							AND (OtherExpenses.AmountFA = 0 OR CostAccountingDocuments.RecordInTA))
	|					THEN TRUE
	|				ELSE FALSE
	|			END AS TakenIntoAccountTA,
	|
	|			CASE
	|				WHEN TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							CostAccountingDocuments AS CostAccountingDocuments
	|						WHERE
	|							CostAccountingDocuments.ExpensesCapitalizationDimension = OtherExpenses.FixedAsset
	|							AND CostAccountingDocuments.Period >= OtherExpenses.Period
	|							AND (OtherExpenses.AmountOfUU = 0 OR CostAccountingDocuments.RecordInManAccounting))
	|					THEN TRUE
	|				ELSE FALSE
	|			END AS TakenIntoAccountMA
	|
	|		FROM
	|			OtherExpenses AS OtherExpenses
	|
	|		) AS OtherExpenses
	|
	|	GROUP BY
	|		OtherExpenses.FixedAsset,
	|		OtherExpenses.Organization
	|
	|	) AS OtherExpenses
	|
	|		LEFT JOIN Catalog.Assets AS Assets
	|		ON Assets.Ref = OtherExpenses.FixedAsset
	|
	|		LEFT JOIN Catalog.ConstructionObjects AS ConstructionObjects
	|		ON ConstructionObjects.Ref = OtherExpenses.FixedAsset
	|
	|		LEFT JOIN StateOfFA AS StateOfFA
	|		ON StateOfFA.Organization = OtherExpenses.Organization
	|			AND StateOfFA.FixedAsset = OtherExpenses.FixedAsset
	|
	|ORDER BY
	|	RefPresentation,
	|	AssetID
	|";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	BeginOfPeriod = ?(Parameters.BeginOfPeriod <> '000101010000', Parameters.BeginOfPeriod, BegOfMonth(CurrentSessionDate()));
	EndOfPeriod = ?(Parameters.EndOfPeriod <> '000101010000', Parameters.EndOfPeriod, CurrentSessionDate());
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("Department", Parameters.Department);
	Query.SetParameter("FixedAsset", Parameters.FixedAsset);
	Query.SetParameter("PresentationOfConstructionSites", NStr("vi = 'Đối tượng xây dựng cơ bản';
																|ru = 'Объект строительства';
																|en = 'Assets under construction'; fa = 'دارایی‌های در جریان ساخت';
																|it = 'Oggetto di costruzione';
																|pl = 'Obiekt budownictwa';
																|tr = 'İnşaat nesnesi'"));
	Query.SetParameter("PresentationGroupFA", String(Enums.FATypes.GroupFA));
	Query.SetParameter("PresentationOfDepreciationComponent", String(Enums.FATypes.DepreciationComponent));
	Query.SetParameter("PresentationNode", String(Enums.FATypes.Node));
	Query.SetParameter("PresentationCapitalInvestment", String(Enums.FATypes.CapitalExpenditureInLeasedAssets));
	Query.SetParameter("PresentationOfObjectOfOperation", NStr("vi = 'Tài sản cố định hữu hình';
																|ru = 'Основное средство';
																|en = 'Fixed asset'; fa = 'دارایی ثابت';
																|it = 'Capitale fisso';
																|pl = 'Środek trwały';
																|tr = 'Sabit kıymetler'"));
	Query.SetParameter("TypesOfDocumentsForWhichCostIsCalculated", FACostCalculation.TypesOfDocumentsForWhichCostIsCalculated());
	
	Result = Query.ExecuteBatch();
	
	WorkplaceData = New Structure();
	WorkplaceData.Insert("List", Result[Result.UBound()].Unload());
	WorkplaceData.Insert("List_Expenses", Result[Result.UBound()-1].Unload());
	WorkplaceData.Insert("LocalCurrencyList", Result[Result.UBound()-2].Unload());
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, WorkplaceData.List.Count());

	Return WorkplaceData;
	
EndFunction

// 
// Parameters:
//	BeginOfPeriod - Date - Beginning of the period
//	EndOfPeriod - Date - End of the period
//  Organization - CatalogRef.Companies - Organization
//  OnlyDeviations - Boolean - Only Deviations
// 
// Returns:
//  Boolean - There is data
Function HasData(BeginOfPeriod, EndOfPeriod, Organization, OnlyDeviations = False) Export

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DataProcessor.RecognizeAndIncludeExpensesInFixedAssetCost.HasData");

	QueryText = 
	"SELECT ALLOWED
	|	AvailableArticles.Ref AS Ref
	|INTO AvailableArticles
	|
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS AvailableArticles
	|
	|WHERE
	|	AvailableArticles.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|
	|	AND (AvailableArticles.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR AvailableArticles.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR AvailableArticles.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|	AND (AvailableArticles.ExpensesOnAssets
	|		OR AvailableArticles.ExpensesOnConstructionObjects)
	|	
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OtherExpenses.Recorder AS Recorder,
	|	OtherExpenses.Period AS Period,
	|	OtherExpenses.DimensionOfExpenses AS FixedAsset,
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.VariancePeriod AS VariancePeriod,
	|	
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|			AND OtherExpenses.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN CASE 
	|					WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN OtherExpenses.SumMan
	|					ELSE -OtherExpenses.SumMan
	|				END
	|		ELSE 0
	|	END AS AmountOfUU,
	|	
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|			AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		THEN CASE 
	|				WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN OtherExpenses.SumCompl
	|					ELSE -OtherExpenses.SumCompl
	|				END
	|		ELSE 0
	|	END AS AmountAccounting,
	|	
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|			AND OtherExpenses.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN CASE 
	|					WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN OtherExpenses.SumCompl
	|					ELSE -OtherExpenses.SumCompl
	|				END
	|		ELSE 0
	|	END AS AmountFA
	|
	|INTO OtherExpensesOf_RegisterRecorded
	|
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|
	|WHERE
	|	OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND NOT VALUETYPE(OtherExpenses.Recorder) IN (&TypesOfDocumentsForWhichCostIsCalculated)
	|	AND OtherExpenses.Active
	|
	|	AND (OtherExpenses.Organization = &Organization
	|			OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|	AND (NOT &OnlyDeviations
	|			OR OtherExpenses.VariancePeriod <> DATETIME(1,1,1))
	|
	|	AND OtherExpenses.ExpenseItem IN (
	|				SELECT
	|					AvailableArticles.Ref
	|				FROM
	|			 		AvailableArticles)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OtherExpenses.Period AS Period,
	|	OtherExpenses.FixedAsset AS FixedAsset,
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.VariancePeriod AS VariancePeriod,
	|	
	|	OtherExpenses.AmountOfUU AS AmountOfUU,
	|	OtherExpenses.AmountAccounting AS AmountAccounting,
	|	OtherExpenses.AmountFA AS AmountFA
	|
	|INTO OtherExpenses
	|
	|FROM
	|	(SELECT
	|		&BeginOfPeriod AS Period,
	|		OtherExpenses.DimensionOfExpenses AS FixedAsset,
	|		OtherExpenses.Organization AS Organization,
	|		DATETIME(1,1,1) AS VariancePeriod,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN OtherExpenses.SumManBalance
	|			ELSE 0
	|		END AS AmountOfUU,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN OtherExpenses.SumComplBalance
	|			ELSE 0
	|		END AS AmountAccounting,
	|	
	|		CASE
	|			WHEN OtherExpenses.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|				AND OtherExpenses.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN OtherExpenses.SumComplBalance - OtherExpenses.PermanentDifferenceBalance - OtherExpenses.CostTDBalance
	|			ELSE 0
	|		END AS AmountFA
	|
	|	FROM
	|		AccumulationRegister.OtherExpenses.Balance(
	|			&BeginOfPeriod,
	|			NOT &OnlyDeviations
	|			AND (Organization = &Organization
	|					OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|				AND ExpenseItem IN (
	|					SELECT
	|						AvailableArticles.Ref
	|					FROM
	|				 		AvailableArticles)
	|			) AS OtherExpenses
	|
	|	UNION ALL
	|
	|	SELECT
	|		OtherExpenses.Period AS Period,
	|		OtherExpenses.FixedAsset AS FixedAsset,
	|		OtherExpenses.Organization AS Organization,
	|		OtherExpenses.VariancePeriod AS VariancePeriod,
	|	
	|		OtherExpenses.AmountOfUU AS AmountOfUU,
	|		OtherExpenses.AmountAccounting AS AmountAccounting,
	|		OtherExpenses.AmountFA AS AmountFA
	|
	|	FROM
	|		OtherExpensesOf_RegisterRecorded AS OtherExpenses
	|
	|	UNION ALL
	|
	|	SELECT 
	|		DocumentData.Date AS Period,
	|		GoodsTable.DimensionOfExpenses AS FixedAsset,
	|		DocumentData.Organization AS Organization,
	|		DATETIME(1,1,1) AS VariancePeriod,
	|	
	|		0 AS AmountOfUU,
	|		0 AS AmountAccounting,
	|		0 AS AmountFA
	|
	|	FROM
	|		Document.InventoryConsumption AS DocumentData
	|
	|			INNER JOIN Document.InventoryConsumption.Goods GoodsTable
	|			ON GoodsTable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND DocumentData.Posted
	|
	|		AND (DocumentData.Organization = &Organization
	|				OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|		AND NOT &OnlyDeviations
	|
	|		AND GoodsTable.ExpenseItem IN (
	|					SELECT
	|						AvailableArticles.Ref
	|					FROM
	|				 		AvailableArticles)
	|
	|	) AS OtherExpenses
	|
	|WHERE
	|	VALUETYPE(OtherExpenses.FixedAsset) IN (
	|		TYPE(Catalog.Assets),
	|		TYPE(Catalog.ConstructionObjects))
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CurrentDocuments.Period AS Period,
	|	CurrentDocuments.ExpensesCapitalizationDimension AS ExpensesCapitalizationDimension,
	|
	|	CurrentDocuments.RecordInManAccounting AS RecordInManAccounting,
	|
	|	ISNULL(FixedAssetsInitialRecognition.PostInAccounting, 
	|		ISNULL(FixedAssetsCostAdditions.PostInAccounting, 
	|			ISNULL(AllocateVariancesToFixedAssetCost.PostInAccounting, CurrentDocuments.RecordInLocalAccounting))) AS PostInAccounting,
	|
	|	ISNULL(FixedAssetsInitialRecognition.RecordInTA, 
	|		ISNULL(FixedAssetsCostAdditions.RecordInTA, 
	|			ISNULL(AllocateVariancesToFixedAssetCost.RecordInTA, CurrentDocuments.RecordInLocalAccounting))) AS RecordInTA
	|
	|INTO CostAccountingDocuments
	|
	|FROM
	|	AccumulationRegister.FACost AS CurrentDocuments
	|
	|		LEFT JOIN Document.FixedAssetsInitialRecognition2_4 AS FixedAssetsInitialRecognition
	|		ON FixedAssetsInitialRecognition.Ref = CurrentDocuments.Recorder
	|
	|		LEFT JOIN Document.FixedAssetsCostAdditions2_4 AS FixedAssetsCostAdditions
	|		ON FixedAssetsCostAdditions.Ref = CurrentDocuments.Recorder
	|
	|		LEFT JOIN Document.AllocateVariancesToFixedAssetCost AS AllocateVariancesToFixedAssetCost
	|		ON AllocateVariancesToFixedAssetCost.Ref = CurrentDocuments.Recorder
	|
	|WHERE
	|	CurrentDocuments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VALUETYPE(CurrentDocuments.Recorder) IN (&TypesOfDocumentsForWhichCostIsCalculated)
	|
	|	AND CurrentDocuments.FixedAsset IN (
	|		SELECT
	|			OtherExpenses.FixedAsset
	|		FROM
	|			OtherExpenses AS OtherExpenses)
	|
	|INDEX BY
	|	ExpensesCapitalizationDimension,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	OtherExpenses.FixedAsset AS FixedAsset,
	|	OtherExpenses.Organization AS Organization,
	|
	|	ISNULL(MIN(OtherExpenses.ACTakenIntoAccount), TRUE) AS ACTakenIntoAccount,
	|	ISNULL(MIN(OtherExpenses.TakenIntoAccountTA), TRUE) AS TakenIntoAccountTA,
	|	ISNULL(MIN(OtherExpenses.TakenIntoAccountMA), TRUE) AS TakenIntoAccountMA
	|
	|FROM
	|	(SELECT
	|		OtherExpenses.FixedAsset AS FixedAsset,
	|		OtherExpenses.Organization AS Organization,
	|
	|		OtherExpenses.AmountOfUU AS AmountOfUU,
	|		OtherExpenses.AmountAccounting AS AmountAccounting,
	|		OtherExpenses.AmountFA AS AmountFA,
	|
	|		CASE
	|			WHEN TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						CostAccountingDocuments AS CostAccountingDocuments
	|					WHERE
	|						CostAccountingDocuments.ExpensesCapitalizationDimension = OtherExpenses.FixedAsset
	|						AND CostAccountingDocuments.Period >= OtherExpenses.Period
	|						AND (OtherExpenses.AmountAccounting = 0 OR CostAccountingDocuments.PostInAccounting))
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS ACTakenIntoAccount,
	|
	|		CASE
	|			WHEN TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						CostAccountingDocuments AS CostAccountingDocuments
	|					WHERE
	|						CostAccountingDocuments.ExpensesCapitalizationDimension = OtherExpenses.FixedAsset
	|						AND CostAccountingDocuments.Period >= OtherExpenses.Period
	|						AND (OtherExpenses.AmountFA = 0 OR CostAccountingDocuments.RecordInTA))
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS TakenIntoAccountTA,
	|
	|		CASE
	|			WHEN TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						CostAccountingDocuments AS CostAccountingDocuments
	|					WHERE
	|						CostAccountingDocuments.ExpensesCapitalizationDimension = OtherExpenses.FixedAsset
	|						AND CostAccountingDocuments.Period >= OtherExpenses.Period
	|						AND (OtherExpenses.AmountOfUU = 0 OR CostAccountingDocuments.RecordInManAccounting))
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS TakenIntoAccountMA
	|
	|	FROM
	|		OtherExpenses AS OtherExpenses
	|
	|	) AS OtherExpenses
	|
	|GROUP BY
	|	OtherExpenses.FixedAsset,
	|	OtherExpenses.Organization
	|
	|HAVING
	|	(ISNULL(MIN(OtherExpenses.ACTakenIntoAccount), TRUE) = FALSE
	|		OR &ComplianceCAAccountingIsKept
	|				AND ISNULL(MIN(OtherExpenses.TakenIntoAccountTA), TRUE) = FALSE
	|		OR ISNULL(MIN(OtherExpenses.TakenIntoAccountMA), TRUE) = FALSE)
	|";	
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("OnlyDeviations", OnlyDeviations);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	Query.SetParameter("TypesOfDocumentsForWhichCostIsCalculated", FACostCalculation.TypesOfDocumentsForWhichCostIsCalculated());
	
	Result = Query.Execute();

	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);

	Return Not Result.IsEmpty();
		
EndFunction

#EndRegion

#EndIf
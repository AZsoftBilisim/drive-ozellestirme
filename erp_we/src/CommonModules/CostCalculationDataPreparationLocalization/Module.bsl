
#Region Public

// Stage of preparation for calculation
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfInitialDataForCalculation(CalculationParameters) Export

	// We will adjust the initial Balances of the Accumulation registers.
	AdjustingInitialRegisterBalances(CalculationParameters);
	
EndProcedure

#Region SystemStateAnalysis

// Fills in checks that are performed as part of the batch and cost calculation.
//
// Parameters:
//	TableOfChecks - See AuditOfSystemStateOverridable.FillOutChecksForRegistration.
//
Procedure FillOutChecksForRegistration(TableOfChecks) Export
EndProcedure

#EndRegion

// Fixes problems in document movements and in the documents themselves in the calculated period.
//
// There are errors that "spoil" the original data for the calculation,
// but the update handler is not written to correct their consequences.
// For example, due to some old error, in some cases the document movements were incorrect.
// - if you write an update handler to fix this error,
// it will change the data of past "closed" periods, which means that these periods will no longer be "closed".
// You will have to re-close these periods, which may change their cost and, as a result,
// regulated reporting. This is bad, because for these periods, reports may already be submitted.
// - on the other hand, in the periods that the user will recalculate, this error in movements should be corrected
// so that in these recalculated periods, the cost price is based on the correct source data.
//
// This procedure is intended to correct such errors.
// In fact, it is an analog of the update handler that corrects document movements in the period specified by the user.
//
// This procedure is also used to adjust the period movements when recalculating it in batch accounting version 2.2.
//
// Parameters:
//	CalculationParameters - Structure -
//
Procedure FixProblemsInRegisteredRecordsAndDocuments(CalculationParameters) Export
EndProcedure

// Complements the array with document types with "non-standard" logic for forming movements.
//
// Parameters:
//	TypesOfLoggers - Array of Type - array of logger types
//
Procedure ToSupplementTypesOfRecordersWithNonStandardLogicOfFormationOfRegisteredRecords(TypesOfLoggers) Export
EndProcedure

#EndRegion

#Region Private

#Region StageProcedures_PreparationForCalculation

#Region AdjustmentsToInitialRegisterBalances

// Performs all necessary adjustments to the maintained registers.
//
Procedure AdjustingInitialRegisterBalances(CalculationParameters)
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	AdjustmentOfInitialBalancesOfRegisterInventoryCosts(CalculationParameters);
	
	
	CostCalculationAppliedAlgorithms.CompleteBalanceAdjustments(CalculationParameters);
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters, ExistingTT);
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
EndProcedure

#Region InventoryCost

// Performs all necessary adjustments to the register of cost of goods.
//
Procedure AdjustmentOfInitialBalancesOfRegisterInventoryCosts(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "AdjustmentOfInitialBalancesOfRegisterInventoryCosts");
	
	AdjustmentParameters = CostCalculationAppliedAlgorithms.InitializeAdjustmentOfRegisterBalances(
		CalculationParameters,
		Metadata.AccumulationRegisters.InventoryCost.FullName());
	
	DeviationCorrectionParameters = CostCalculationAppliedAlgorithms.InitializeAdjustmentOfRegisterBalances(
		CalculationParameters,
		Metadata.AccumulationRegisters.GoodsCostVariances.FullName());
	
	
	If CalculationOfCostCached.CostOfGoodsForPurposes(CalculationParameters.PayrollPeriod.BeginOfPeriod) Then
		If CalculationOfCostCached.CostAccountingByAssignmentValidFrom() = CalculationParameters.PayrollPeriod.BeginOfPeriod Then
			AdjustmentToIncludeAccountingByDestinationInventoryCost(CalculationParameters, AdjustmentParameters);
		EndIf;
	Else
		AdjustmentDisableAccountingByDestinationInventoryCost(CalculationParameters, AdjustmentParameters);
	EndIf;
		
	
	If CalculationParameters.CompanyManagementAccounting Then
		If CalculationOfCostCached.StartDateOfManagementAccountingOfOrganizations() = CalculationParameters.PayrollPeriod.BeginOfPeriod Then
			AdjustmentFillInAmountOfManAccountingInventoryCost(CalculationParameters, AdjustmentParameters);
		EndIf;
	Else
		AdjustmentToClearAmountOfManAccountingInventoryCost(CalculationParameters, AdjustmentParameters);
	EndIf;
	
	ToGenerateAdjustmentRegisterRecordedCostONChangeOfAccountingPolicy(CalculationParameters, AdjustmentParameters, DeviationCorrectionParameters);
	
	CostCalculationAppliedAlgorithms.CompleteAdjustmentOfRegisterBalances(CalculationParameters, AdjustmentParameters);
	CostCalculationAppliedAlgorithms.CompleteAdjustmentOfRegisterBalances(CalculationParameters, DeviationCorrectionParameters);
	
EndProcedure


// Performs the inclusion of accounting by appointment - fills in appointments in the analytics of the nomenclature.
//
Procedure AdjustmentToIncludeAccountingByDestinationInventoryCost(CalculationParameters, AdjustmentParameters)
	
	CostCalculationAppliedAlgorithms.StartNextAdjustmentOfRegisterBalances(
		CalculationParameters,
		AdjustmentParameters,
		Enums.LotRecordTypes.ServiceEnableAccountingByPurposes);
	
	If Not AdjustmentParameters.AdjustmentRequired Then
		Return;
	EndIf;
	
	#Region DataPreparation
	
	DimDetails = GenerateDescriptionOfInventoryLocationAttributeKeysOfItemSAccountingAnalyst(, "Purpose");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	Query.SetParameter("OrganizationsToAdjust", AdjustmentParameters.OrganizationsToAdjust);
	
	// Let's select the data for distribution
	Query.Text =
	"SELECT
	|	&RegisterDimensions,
	|	&RegisterResources,
	|	&NamedAnalyticsFields
	|INTO TTCostBalancesWithoutAssignments
	|FROM
	|	TTEstimatedInitialBalancesOfInventoryCosts AS T
	|WHERE
	|	T.ItemsLocationAttributes.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)";
	
	Query.Text = StrReplace(Query.Text, "&RegisterDimensions",
		StringFunctionsClientServer.SubstituteParametersToString(AdjustmentParameters.RegisterDescription.RegisterDimensions, "T."));
	Query.Text = StrReplace(Query.Text, "&RegisterResources",
		StringFunctionsClientServer.SubstituteParametersToString(AdjustmentParameters.RegisterDescription.RegisterResources, "T."));
	Query.Text = StrReplace(Query.Text, "&NamedAnalyticsFields",
		StringFunctionsClientServer.SubstituteParametersToString(DimDetails.NamedFields, "T."));
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	If CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "TTCostBalancesWithoutAssignments") = 0 Then
		Return; // there is no distributed data
	EndIf;
	
	Query.Text =
	"SELECT
	|	Keys.Ref AS Ref
	|INTO AnalyticsTTWithAppointments
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS Keys
	|WHERE
	|	Keys.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	AND Keys.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization						AS Organization,
	|	T.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|		WHEN T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		WHEN T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		WHEN T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|		WHEN ISNULL(T.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		  AND CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).ContractType
	|			  = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END								AS AccountingSection,
	|	T.CountBalance					AS Count
	|INTO TTBalancesWithAppointmentsPreliminary
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(&BorderEndOfPreviousPeriod,
	|		Organization IN (&OrganizationsToAdjust)
	|		AND ItemsLocationAttributes IN (SELECT T.Ref FROM AnalyticsTTWithAppointments AS T)
	|	) AS T
	|WHERE
	|	T.CountBalance > 0
	|	OR T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|
	|UNION ALL
	|
	|SELECT
	|	T.Organization						AS Organization,
	|	T.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	END								AS AccountingSection,
	|	T.CountBalance					AS Count
	|FROM
	|	AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(&BorderEndOfPreviousPeriod,
	|		Organization IN (&OrganizationsToAdjust)
	|		AND ItemsLocationAttributes IN (SELECT T.Ref FROM AnalyticsTTWithAppointments AS T)
	|	) AS T
	|WHERE
	|	T.CountBalance > 0
	|
	|
	|UNION ALL
	|
	|SELECT
	|	T.InventoryOwnerAttribute.Organization			AS Organization,
	|	T.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|		WHEN ISNULL(T.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END								AS AccountingSection,
	|	T.CountBalance					AS Count
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(&BorderEndOfPreviousPeriod,
	|		InventoryOwnerAttribute.Organization IN (&OrganizationsToAdjust)
	|		AND ItemsLocationAttributes IN (SELECT T.Ref FROM AnalyticsTTWithAppointments AS T)
	|		AND ImportDocumentType = &ImportDocumentType
	|	) AS T
	|WHERE
	|	T.CountBalance > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.AccountingSection,
	|	&NamedAnalyticsFields,
	|	SUM(T.Count) AS Count
	|INTO TTBalancesWithAppointments
	|FROM
	|	TTBalancesWithAppointmentsPreliminary AS T
	|GROUP BY
	|	T.Organization,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.AccountingSection,
	|	&AnalyticsFieldsAreNotNamed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization,
	|	T.Products AS InventoryingLocationAttribute_Items,
	|	T.Characteristic AS InventoryLocationAttributeOfItemSAccountingIs_Characteristic,
	|	T.Series AS InventoryLocationAttributeAccountingSystem_Batch,
	|	T.Purpose AS ItemInventoryLocationAttributeAnalysis_Purpose,
	|	T.Department AS ItemInventoryLocationAttribute_StorageLocation,
	|	&EmptyProductCostElementsArticle AS InventoryingLocationAttribute_ProductCostingElements,
	|	T.CountBalance AS Count
	|INTO TTLeftoversMaterialsAndWorksWithoutAnalytics
	|FROM
	|	AccumulationRegister.MaterialsAndWorksInProduction.Balance(&BorderEndOfPreviousPeriod,
	|		Organization IN (&CompanyArray)
	|		AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	) AS T
	|WHERE
	|	T.CountBalance > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTBalancesWithAppointmentsPreliminary";
	
	Query.Text = StrReplace(Query.Text, "&NamedAnalyticsFields",
		StringFunctionsClientServer.SubstituteParametersToString(DimDetails.NamedFields, "T."));
	Query.Text = StrReplace(Query.Text, "&AnalyticsFieldsAreNotNamed",
		StringFunctionsClientServer.SubstituteParametersToString(DimDetails.FieldsNotNamed, "T."));
	
	Query.SetParameter("EmptyProductCostElementsArticle", "");
	Query.SetParameter("EmptyProductCostElementsArticle", Catalogs.ProductCostElements.EmptyRef());
	Query.SetParameter("ImportDocumentType", Common.MetadataObjectID("Document.CCDImport"));
		
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	#EndRegion 
	
	#Region DataDistribution
	
	// Initializing the distribution
	DistributionParameters = CostCalculationUniversalAlgorithms.InitializeDistributionParametersUsingReducedRemainderMethod(
		"TTCostBalancesWithoutAssignments",
		"TTBalancesWithAppointments",
		CostCalculationUniversalAlgorithms.ConnectLines("Organization, AccountingSection, InventoryOwnerAttribute", DimDetails.ListOfFields));
		
	CostCalculationUniversalAlgorithms.InitializeDistributionResultTables(
		DistributionParameters,
		"TTDistributionResult",
		"UnallocatedCostBalances");
		
	AllocatedResources = CostCalculationUniversalAlgorithms.RemoveElementsFromTemplateString(
		AdjustmentParameters.RegisterDescription.RegisterResources,
		"%1Count");
	
	CostCalculationUniversalAlgorithms.InitializeNumericalDistributionFieldsUsingReducedRemainderMethod(
		DistributionParameters,
		StringFunctionsClientServer.SubstituteParametersToString(AllocatedResources, ""));
		
	CostCalculationUniversalAlgorithms.InitializeOtherDistributionFieldsUsingReducedRemainderMethod(
		DistributionParameters,
		StringFunctionsClientServer.SubstituteParametersToString(AdjustmentParameters.RegisterDescription.RegisterDimensions, ""),
		"ItemsLocationAttributes");
	
	// We distribute
	CostCalculationAppliedAlgorithms.DistributeByMethodOfReducedResidueWithTimeMeasurement(
		CalculationParameters,
		DistributionParameters,
		"DistributeUsingReducedRemainderMethod",
		"AdjustmentToIncludeAccountingByAppointmentInventoryCosts_OperationalAccounting");
	
	MaterialAndLaborAllocationIsRequired =
		CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "TTLeftoversMaterialsAndWorksWithoutAnalytics") > 0
		And CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "UnallocatedCostBalances") > 0;
	
	// Adding the results of the distribution to the correction RegisterRecorded
	CostCalculationAppliedAlgorithms.AddRegisterAdjustmentRegisteredRecords(
		CalculationParameters,
		AdjustmentParameters,
		"TTDistributionResult" + ?(MaterialAndLaborAllocationIsRequired, "", ", UnallocatedCostBalances"),
		"TTCostBalancesWithoutAssignments",
		True,
		True);
		
	If Not MaterialAndLaborAllocationIsRequired Then
		Return;
	EndIf;
	
	#EndRegion
	
	#Region DataPreparationMaterialsAndWorks
	
	GenerateItemAnalyticsBasedOnFieldValues(
		CalculationParameters,
		"TTLeftoversMaterialsAndWorksWithoutAnalytics",
		"TTLeftoversMaterialsAndWorkWithAnalytics",
		"ItemsLocationAttributes");
	
	#EndRegion
	
	#Region DistributionOfDataDataMaterialsAndWorks
	
	// Initializing the distribution
	DistributionParameters = CostCalculationUniversalAlgorithms.InitializeDistributionParametersUsingReducedRemainderMethod(
		"UnallocatedCostBalances",
		"TTLeftoversMaterialsAndWorkWithAnalytics",
		CostCalculationUniversalAlgorithms.ConnectLines("Organization", DimDetails.ListOfFields));
		
	CostCalculationUniversalAlgorithms.InitializeNumericalDistributionFieldsUsingReducedRemainderMethod(
		DistributionParameters,
		StringFunctionsClientServer.SubstituteParametersToString(AllocatedResources, ""));
		
	CostCalculationUniversalAlgorithms.InitializeOtherDistributionFieldsUsingReducedRemainderMethod(
		DistributionParameters,
		StringFunctionsClientServer.SubstituteParametersToString(AdjustmentParameters.RegisterDescription.RegisterDimensions, ""),
		"ItemsLocationAttributes");
		
	// We distribute
	CostCalculationAppliedAlgorithms.DistributeByMethodOfReducedResidueWithTimeMeasurement(
		CalculationParameters,
		DistributionParameters,
		"DistributeUsingReducedRemainderMethod",
		"AdjustmentToIncludeAccountingByPurposeInventoryCost_Production");
	
	// Adding the results of the distribution to the correction RegisterRecorded
	CostCalculationAppliedAlgorithms.AddRegisterAdjustmentRegisteredRecords(
		CalculationParameters,
		AdjustmentParameters,
		"TTDistributionResult, TTUnallocatedSourceData",
		,
		True);
	
	#EndRegion
	
EndProcedure

// Performs deactivation of accounting by appointment - clears appointments in the analytics of the item.
//
Procedure AdjustmentDisableAccountingByDestinationInventoryCost(CalculationParameters, AdjustmentParameters)
	
	CostCalculationAppliedAlgorithms.StartNextAdjustmentOfRegisterBalances(
		CalculationParameters,
		AdjustmentParameters,
		Enums.LotRecordTypes.ServiceDisableGoodsAccountingByAssignments);
	
	If Not AdjustmentParameters.AdjustmentRequired Then
		Return;
	EndIf;
	
	#Region DataPreparation
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	Query.SetParameter("OrganizationsToAdjust", AdjustmentParameters.OrganizationsToAdjust);
	
	// Let's select the data for correction
	Query.Text =
	"SELECT
	|	&RegisterDimensions,
	|	&RegisterResources
	|INTO TTCostBalancesWithDestination
	|FROM
	|	TTEstimatedInitialBalancesOfInventoryCosts AS T
	|WHERE
	|	T.ItemsLocationAttributes.Purpose <> VALUE(Catalog.Assignments.EmptyRef)";
	
	Query.Text = StrReplace(Query.Text, "&RegisterDimensions",
		StringFunctionsClientServer.SubstituteParametersToString(AdjustmentParameters.RegisterDescription.RegisterDimensions, "T."));
	Query.Text = StrReplace(Query.Text, "&RegisterResources",
		StringFunctionsClientServer.SubstituteParametersToString(AdjustmentParameters.RegisterDescription.RegisterResources, "T."));
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	ThereAreAdjustingEntries = GenerateItemAnalyticsWithoutAssignment(
		CalculationParameters,
		"TTCostBalancesWithDestination",
		"TTCostBalancesWithoutAssignment");
	
	If Not ThereAreAdjustingEntries Then
		Return;
	EndIf;
	
	#EndRegion 
	
	// Adding the results of the distribution to the correction RegisterRecorded
	CostCalculationAppliedAlgorithms.AddRegisterAdjustmentRegisteredRecords(
		CalculationParameters,
		AdjustmentParameters,
		"TTCostBalancesWithoutAssignment",
		"TTCostBalancesWithDestination",
		True,
		True);
	
EndProcedure

// Performs the inclusion of Man. accounting - fills in the register's Man resources.
//
Procedure AdjustmentFillInAmountOfManAccountingInventoryCost(CalculationParameters, AdjustmentParameters)
	
	CostCalculationAppliedAlgorithms.StartNextAdjustmentOfRegisterBalances(
		CalculationParameters,
		AdjustmentParameters,
		Enums.LotRecordTypes.ServiceEnableManagementAccountingByFinancialAccountingRules);
	
	If Not AdjustmentParameters.AdjustmentRequired Then
		Return;
	EndIf;
	
	#Region DataPreparation
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	Query.SetParameter("OrganizationsToAdjust", AdjustmentParameters.OrganizationsToAdjust);
	
	// Let's select the data for the formation of the initial Balances
	Query.Text =
	"SELECT
	|	&RegisterDimensions,
	|	- T.CostMan + T.CostExcludingVAT 						 AS CostMan,
	|	- T.AddExpensesMan + T.AdditionalExpensesExcludingVAT 						 AS AddExpensesMan,
	|	- T.LaborCostsMan + T.LaborCosts 						 AS LaborCostsMan,
	|	- T.ItemizedFixedCostsManag + T.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsManag,
	|	- T.ItemizedVariableCostsManag + T.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsManag
	|INTO TTBalanceOfManSSum
	|FROM
	|	TTEstimatedInitialBalancesOfInventoryCosts AS T
	|WHERE
	|	- T.CostMan + T.CostExcludingVAT <> 0
	|	OR - T.AddExpensesMan + T.AdditionalExpensesExcludingVAT <> 0
	|	OR - T.LaborCostsMan + T.LaborCosts <> 0
	|	OR - T.ItemizedFixedCostsManag + T.ItemizedFixedCostsExcludingVAT <> 0
	|	OR - T.ItemizedVariableCostsManag + T.ItemizedVariableCostsExcludingVAT <> 0";
	
	Query.Text = StrReplace(Query.Text, "&RegisterDimensions",
		StringFunctionsClientServer.SubstituteParametersToString(AdjustmentParameters.RegisterDescription.RegisterDimensions, "T."));
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	#EndRegion 
	
	// Adding data to the correction RegisterRecorded
	CostCalculationAppliedAlgorithms.AddRegisterAdjustmentRegisteredRecords(
		CalculationParameters,
		AdjustmentParameters,
		"TTBalanceOfManSSum",
		,
		True);
	
EndProcedure

// Performs shutdown of Man. accounting - clears Man. register resources.
//
Procedure AdjustmentToClearAmountOfManAccountingInventoryCost(CalculationParameters, AdjustmentParameters)
	
	CostCalculationAppliedAlgorithms.StartNextAdjustmentOfRegisterBalances(
		CalculationParameters,
		AdjustmentParameters,
		Enums.LotRecordTypes.ServiceDisableManagementAccountingByFinancialAccountingRules);
	
	If Not AdjustmentParameters.AdjustmentRequired Then
		Return;
	EndIf;
	
	#Region DataPreparation
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	Query.SetParameter("OrganizationsToAdjust", AdjustmentParameters.OrganizationsToAdjust);
	
	// Let's select the data for clearing the Balances of Man's accounting amounts
	Query.Text =
	"SELECT
	|	&RegisterDimensions,
	|	- T.CostMan 			 AS CostMan,
	|	- T.AddExpensesMan 			 AS AddExpensesMan,
	|	- T.LaborCostsMan 		 AS LaborCostsMan,
	|	- T.ItemizedFixedCostsManag AS ItemizedFixedCostsManag,
	|	- T.ItemizedVariableCostsManag AS ItemizedVariableCostsManag
	|INTO TTBalancesClearingManAmounts
	|FROM
	|	TTEstimatedInitialBalancesOfInventoryCosts AS T
	|WHERE
	|	- T.CostMan <> 0
	|	OR - T.AddExpensesMan <> 0
	|	OR - T.LaborCostsMan <> 0
	|	OR - T.ItemizedFixedCostsManag <> 0
	|	OR - T.ItemizedVariableCostsManag <> 0";
	
	Query.Text = StrReplace(Query.Text, "&RegisterDimensions",
		StringFunctionsClientServer.SubstituteParametersToString(AdjustmentParameters.RegisterDescription.RegisterDimensions, "T."));
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	#EndRegion 
	
	// Adding data to the correction RegisterRecorded
	CostCalculationAppliedAlgorithms.AddRegisterAdjustmentRegisteredRecords(
		CalculationParameters,
		AdjustmentParameters,
		"TTBalancesClearingManAmounts",
		,
		True);
	
EndProcedure

// Performs filling/cleaning of batches in the Inventory Cost register on change of the valuation method. 
// Switching from/to Fifo-weighted is not supported.
//
Procedure ToGenerateAdjustmentRegisterRecordedCostONChangeOfAccountingPolicy(CalculationParameters, AdjustmentParameters, DeviationCorrectionParameters)
	
	CostCalculationAppliedAlgorithms.StartNextAdjustmentOfRegisterBalances(
		CalculationParameters,
		AdjustmentParameters,
		Enums.LotRecordTypes.InternalChangingPriceEvaluationMethod);
	
	CostCalculationAppliedAlgorithms.StartNextAdjustmentOfRegisterBalances(
		CalculationParameters,
		DeviationCorrectionParameters,
		Enums.LotRecordTypes.InternalChangingPriceEvaluationMethod);
	
	If Not AdjustmentParameters.AdjustmentRequired Then
		Return;
	EndIf;
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text =
	"SELECT
	|	T.Ref AS Organization
	|INTO TTOfOrganizationWith22_24Transition
	|FROM
	|	Catalog.Companies AS T
	|WHERE
	|	(T.Ref IN(&OrganizationsMonthlyAverageInPreviousPeriod)
	|		OR T.Ref IN(&SFIFOOrganizationsWeightedInLastPeriod))
	|	AND T.Ref IN(&SFIFOOrganizationsSliding)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Ref AS Organization
	|INTO CompanySTTWith24_22Transition
	|FROM
	|	Catalog.Companies AS T
	|WHERE
	|	T.Ref IN(&SFIFOOrganizationsMovingAverageInPreviousPeriod)
	|	AND (T.Ref IN(&OrganizationsMonthlyAverage)
	|		OR T.Ref IN(&SFIFOOrganizationsWeighted))
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Ref AS Organization
	|INTO CompanySTTWithTransitionToMediumSlip
	|FROM
	|	Catalog.Companies AS T
	|WHERE
	|	T.Ref IN(&MediumSlipOrganizations)
	|	AND NOT T.Ref IN(&OrganizationsAverageMovingAverageInLastPeriod)
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	If CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "TTOfOrganizationWith22_24Transition") = 0
	 And CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "CompanySTTWith24_22Transition") = 0
	 And CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "CompanySTTWithTransitionToMediumSlip") = 0 Then
		Return; // there is no data for distribution
	EndIf;
	

	If CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "CompanySTTWith24_22Transition") > 0 Then
	
		#Region DataPreparation
		
		Query.Text =
		"SELECT
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.VATActivityType,
		|	&IDOfUnusedFinRecord AS FinRecordID,
		|	&RegisterResources
		|INTO TTRemainingBatchesOfCostOfFIFO
		|FROM
		|	TTEstimatedInitialBalancesOfInventoryCosts AS T
		|	INNER JOIN CompanySTTWith24_22Transition AS Filter
		|		ON T.Organization = Filter.Organization
		|WHERE
		|	T.Lot <> UNDEFINED
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.VATActivityType,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	&IDOfUnusedFinRecord AS FinRecordID,
		|	&RegisterResources
		|INTO TTStornoRestOfBatchesOfCostOfFIFO
		|FROM
		|	TTEstimatedInitialBalancesOfInventoryCosts AS T
		|	INNER JOIN CompanySTTWith24_22Transition AS Filter
		|		ON T.Organization = Filter.Organization
		|WHERE
		|	T.Lot <> UNDEFINED
		|";
		
		Query.Text = StrReplace(Query.Text, "&RegisterResources",
			StringFunctionsClientServer.SubstituteParametersToString(AdjustmentParameters.RegisterDescription.RegisterResources, "T."));
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		
		CostCalculationAppliedAlgorithms.AddRegisterAdjustmentRegisteredRecords(
			CalculationParameters,
			AdjustmentParameters,
			"TTRemainingBatchesOfCostOfFIFO",
			"TTStornoRestOfBatchesOfCostOfFIFO",
			True,
			True);
		
		#EndRegion
		
	EndIf;

	If CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "CompanySTTWithTransitionToMediumSlip") > 0 Then
	
		#Region DataPreparation
		
		Query.Text =
		"SELECT DISTINCT
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute
		|INTO TTOfRegisteredRecordedCostOfMediumSlip
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|	INNER JOIN CompanySTTWithTransitionToMediumSlip AS Filter
		|		ON T.Organization = Filter.Organization
		|WHERE
		|	T.Organization IN(&CompanyArray)
		|	AND T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND T.Active
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RECORDAUTONUMBER() AS RecNo,
		|	T.Organization,
		|	T.AccountingSection,
		|	CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.VATActivityType,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|
		|	CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products AS Products,
		|	CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Characteristic AS Characteristic,
		|	CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		// If there are already expenditure RegisteredRecords in the current period, then the average moving average has already been calculated for them, taking into account VAT, and it is too late to exclude VAT from the cost
		|	 AND RegisterRecords.Organization IS NULL
		|		THEN 1
		|		ELSE 0
		|	END AS VATRate_2,
		|	CASE WHEN T.Organization IN(&OrganizationsWithVATBatchesOfVersion24InPreviousPeriod)
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS TransitionSFIFOSliding,
        |
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS LineOfBusiness,
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).StorageLocation
		|		WHEN CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).StorageLocation AS Catalog.Warehouses).Department
		|		WHEN CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).StorageLocation
		|		ELSE UNDEFINED
		|	END AS StorageLocation,
		|	&RegisterResources
		|INTO TTRestOfBatchesOfPrimeCostUpToAverageSlidingWithoutIdentifiers
		|FROM
		|	TTEstimatedInitialBalancesOfInventoryCosts AS T
		|	INNER JOIN CompanySTTWithTransitionToMediumSlip AS Filter
		|		ON T.Organization = Filter.Organization
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|	LEFT JOIN TTOfRegisteredRecordedCostOfMediumSlip AS RegisterRecords
		|		ON T.Organization = RegisterRecords.Organization
		|		AND T.AccountingSection = RegisterRecords.AccountingSection
		|		AND T.ItemsLocationAttributes = RegisterRecords.ItemsLocationAttributes
		|		AND T.InventoryOwnerAttribute = RegisterRecords.InventoryOwnerAttribute
		|WHERE
		|	T.Lot <> UNDEFINED
		|	OR T.LotVendorAttributes <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|	OR T.FinancialAccountingDimension <> UNDEFINED
		|	OR T.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|INDEX BY
		|	RecNo
		|";
		
		Query.Text = StrReplace(Query.Text, "&RegisterResources",
			StringFunctionsClientServer.SubstituteParametersToString(AdjustmentParameters.RegisterDescription.RegisterResources, "T."));
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		
		CostCalculationAppliedAlgorithms.FillInIdsInTemporaryTable(
			CalculationParameters,
			"TTRestOfBatchesOfPrimeCostUpToAverageSlidingWithoutIdentifiers",
			"TTRestOfBatchesOfPrimeCostToAverageSliding",
			"RecNo");
		
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, "TTRestOfBatchesOfPrimeCostUpToAverageSlidingWithoutIdentifiers");
		
		Query.Text =
		"SELECT
		|	T.RecNo,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.Organization,
		|	T.InventoryOwnerAttribute,
		|	T.Products,
		|	T.Characteristic
		|INTO TTSelectionDetailingFIFOConstant
		|FROM
		|	TTRestOfBatchesOfPrimeCostToAverageSliding AS T
		|WHERE
		|	T.Lot <> UNDEFINED
		|	AND T.Organization IN(&OrganizationsWithVATBatchesOfVersion24InPreviousPeriod)
		|INDEX BY
		|	Lot,
		|	Organization,
		|	Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.RecNo,
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.VATActivityType,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension
		|INTO TTSelectionDetailingFIFOVariables
		|FROM
		|	TTRestOfBatchesOfPrimeCostToAverageSliding AS T
		|WHERE
		|	T.Lot <> UNDEFINED
		|	AND T.Organization IN(&OrganizationsWithVATBatchesOfVersion24InPreviousPeriod)
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.RecNo,
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.VATActivityType,
		|	T.FinancialAccountingDimension
		|INTO TTSelectionDetailIsAverage
		|FROM
		|	TTRestOfBatchesOfPrimeCostToAverageSliding AS T
		|WHERE
		|	T.Lot = UNDEFINED
		|	AND T.Organization IN(&OrganizationsTakingIntoAccountBatchesOfVATVersion22INLastPeriod)
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.RecNo,
		|	SUM(T.VATLocal) AS VATLocal,
		|	SUM(T.VATManag) AS VATManag
		|INTO TTPricesOfVATBatchesForMediumSlip
		|FROM
		|(SELECT
		|	Filter.RecNo,
		|	T.VATLocal,
		|	T.VATManag
		|FROM
		|	InformationRegister.ItemizeGoodsLotCost AS T
		|	INNER JOIN TTSelectionDetailingFIFOConstant AS Filter
		|		ON T.Lot = Filter.Lot
		|		AND T.LotVendorAttributes = Filter.LotVendorAttributes
		|		AND T.Organization = Filter.Organization
		|		AND T.Products = Filter.Products
		|		AND T.Characteristic = Filter.Characteristic
		|WHERE
		|	T.RegistrationPeriod < &BeginOfPeriod
		|
		|UNION ALL
		|
		|SELECT
		|	Filter.RecNo,
		|	T.VATLocal,
		|	T.VATManag
		|FROM
		|	InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS T
		|	INNER JOIN TTSelectionDetailingFIFOConstant AS Filter
		|		ON T.Lot = Filter.Lot
		|		AND T.LotVendorAttributes = Filter.LotVendorAttributes
		|		AND T.Organization = Filter.Organization
		|		AND T.Products = Filter.Products
		|		AND T.Characteristic = Filter.Characteristic
		|WHERE
		|	T.RegistrationPeriod < &BeginOfPeriod
		|
		|UNION ALL
		|
		|SELECT
		|	Filter.RecNo,
		|	T.VATLocal,
		|	T.VATManag
		|FROM
		|	InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts AS T
		|	INNER JOIN TTSelectionDetailingFIFOVariables AS Filter
		|		ON T.Organization = Filter.Organization
		|		AND T.AccountingSection = Filter.AccountingSection
		|		AND T.ItemsLocationAttributes = Filter.ItemsLocationAttributes
		|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
		|		AND T.Lot = Filter.Lot
		|		AND T.LotVendorAttributes = Filter.LotVendorAttributes
		|		AND T.VATActivityType = Filter.VATActivityType
		|		AND T.FinancialAccountingDimension = Filter.FinancialAccountingDimension
		|WHERE
		|	T.Period = &BeginningOfPreviousPeriod
		|) AS T
		|GROUP BY
		|	T.RecNo
		|
		|INDEX BY
		|	RecNo
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		// The fields "Party" and "Analyticaccounting of parties" in the Accounting section "Unfactated deliveries" are always filled in.
		|	CASE
		|		WHEN T.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			THEN T.Lot
		|		ELSE UNDEFINED
		|	END AS Lot,
		|	CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|			THEN T.LotVendorAttributes
		|		ELSE UNDEFINED
		|	END AS LotVendorAttributes,
		|
		|	T.Products AS DeviationItem,
		|	T.Characteristic AS DeviationCharacteristic,
		|	T.LineOfBusiness AS LineOfBusinessDeviations,
		|	T.Department AS DeviationDivision,
		|	T.StorageLocation AS StorageLocationOfDeviation,
		|	VALUE(Enum.BusinessTransactions.InternalChangingPriceEvaluationMethod) AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.InternalChangingPriceEvaluationMethod) AS BusinessTransactionSetting,
		|	T.FinRecordID,
		|
		|	SUM(T.Count) AS Count,
		|	SUM(T.Cost) AS Cost,
		|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(T.LocalCost
		|		- CAST(CASE WHEN T.TransitionSFIFOSliding
		|			THEN ISNULL(Prices.VATLocal, 0) * T.Count
		|			ELSE ISNULL(Prices.VATLocal, 0)
		|		  END * T.VATRate_2 AS NUMBER (31,2))) AS LocalCost,
		|	SUM(T.CostMan
		|		- CAST(CASE WHEN T.TransitionSFIFOSliding
		|			THEN ISNULL(Prices.VATManag, 0) * T.Count
		|			ELSE ISNULL(Prices.VATManag, 0)
		|		  END * T.VATRate_2 AS NUMBER (31,2))) AS CostMan,
		|	SUM(T.OffBalanceCost) AS OffBalanceCost,
		|	SUM(T.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	SUM(T.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
		|	SUM(T.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
		|	SUM(T.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|
		|	SUM(CAST(CASE WHEN T.TransitionSFIFOSliding
		|		THEN ISNULL(Prices.VATLocal, 0) * T.Count
		|		ELSE ISNULL(Prices.VATLocal, 0)
		|	END AS NUMBER (31,2))) AS VATLocal,
		|	SUM(CAST(CASE WHEN T.TransitionSFIFOSliding
		|		THEN ISNULL(Prices.VATLocal, 0) * T.Count
		|		ELSE ISNULL(Prices.VATLocal, 0)
		|	END * T.VATRate_2 AS NUMBER (31,2))) AS VATLocalDeviations,
		|
		|	SUM(CAST(CASE WHEN T.TransitionSFIFOSliding
		|		THEN ISNULL(Prices.VATManag, 0) * T.Count
		|		ELSE ISNULL(Prices.VATManag, 0)
		|	END AS NUMBER (31,2))) AS VATManag,
		|	SUM(CAST(CASE WHEN T.TransitionSFIFOSliding
		|		THEN ISNULL(Prices.VATManag, 0) * T.Count
		|		ELSE ISNULL(Prices.VATManag, 0)
		|	END * T.VATRate_2 AS NUMBER (31,2))) AS VATManDeviations
		|INTO TTOfBatchOfCostOfMediumSlip
		|FROM
		|	TTRestOfBatchesOfPrimeCostToAverageSliding AS T
		|	LEFT JOIN TTPricesOfVATBatchesForMediumSlip AS Prices
		|		ON T.RecNo = Prices.RecNo
		|WHERE
		|	T.Count <> 0
		|GROUP BY
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	CASE
		|		WHEN T.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			THEN T.Lot
		|		ELSE UNDEFINED
		|	END,
		|	CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|			THEN T.LotVendorAttributes
		|		ELSE UNDEFINED
		|	END,
		|
		|	T.Products,
		|	T.Characteristic,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		|	T.FinRecordID
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.VATActivityType,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	VALUE(Enum.BusinessTransactions.InternalChangingPriceEvaluationMethod) AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.InternalChangingPriceEvaluationMethod) AS BusinessTransactionSetting,
		|	T.FinRecordID AS FinRecordID,
		|	T.Count,
		|	T.Cost,
		|	T.CostExcludingVAT,
		|	T.LocalCost,
		|	T.CostMan,
		|	T.OffBalanceCost,
		|	T.OffBalanceCostLocal,
		|	T.AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.LaborCosts,
		|	T.ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVAT,
		|	T.ItemizedVariableCostsExcludingVAT,
		|	T.AddExpensesLocal,
		|	T.LaborCostsLocal,
		|	T.ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsCompl,
		|	T.PermanentDifference,
		|	T.CostTD,
		|	T.AddExpensesMan,
		|	T.LaborCostsMan,
		|	T.ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManag,
		|	T.ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentMan,
		|	T.CostOfPersonalIncomeTax
		|INTO TTStornoRestOfBatchesOfPrimeCostUpToAverageSliding
		|FROM
		|	TTRestOfBatchesOfPrimeCostToAverageSliding AS T
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		|	T.VariancePeriod,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|
		|	SUM(T.CostVariancesIncludingVAT) AS CostVariancesIncludingVAT,
		|	SUM(T.CostVariancesExcludingVAT) AS CostVariancesExcludingVAT,
		|	SUM(T.CostVariancesLocal) AS CostVariancesLocal,
		|	SUM(T.CostVariancesMgmt) AS CostVariancesMgmt,
		|	SUM(T.AdditionalExpensesIncludingVAT) AS AdditionalExpensesIncludingVAT,
		|	SUM(T.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(T.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(T.AddExpensesMan) AS AddExpensesMan,
		|	SUM(T.PermanentDifference) AS PermanentDifference,
		|	SUM(T.CostTD) AS CostTD,
		|	SUM(T.VATLocal) AS VATLocal,
		|	SUM(T.VATManag) AS VATManag
		|INTO TTTransferOfAdditionalExpenseAmountINDSVDeviation
		|FROM
		|(SELECT
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		|	&BeginOfPeriod AS VariancePeriod,
		|	VALUE(Enum.BusinessTransactions.InternalChangingPriceEvaluationMethod) AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.InternalChangingPriceEvaluationMethod) AS BusinessTransactionSetting,
		|	T.FinRecordID AS FinRecordID,
		|
		|	SUM(T.LaborCosts + T.ItemizedFixedCostsIncludingVAT + T.ItemizedVariableCostsIncludingVAT) AS CostVariancesIncludingVAT,
		|	SUM(T.ItemizedFixedCostsExcludingVAT + T.ItemizedVariableCostsExcludingVAT) AS CostVariancesExcludingVAT,
		|	SUM(T.LaborCostsLocal + T.ItemizedFixedCostsCompl + T.ItemizedVariableCostsCompl) AS CostVariancesLocal,
		|	SUM(T.LaborCostsMan + T.ItemizedFixedCostsManag + T.ItemizedVariableCostsManag) AS CostVariancesMgmt,
		|	SUM(T.AddExpensesForGoods) AS AdditionalExpensesIncludingVAT,
		|	SUM(T.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(T.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(T.AddExpensesMan) AS AddExpensesMan,
		|	SUM(T.PermanentDifference) AS PermanentDifference,
		|	SUM(T.CostTD) AS CostTD,
		|	0 AS VATLocal,
		|	0 AS VATManag
		|FROM
		|	TTRestOfBatchesOfPrimeCostToAverageSliding AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|GROUP BY
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		|	T.FinRecordID
		|HAVING
		|	SUM(T.LaborCosts + T.ItemizedFixedCostsIncludingVAT + T.ItemizedVariableCostsIncludingVAT) <> 0
		|	OR SUM(T.ItemizedFixedCostsExcludingVAT + T.ItemizedVariableCostsExcludingVAT) <> 0
		|	OR SUM(T.LaborCostsLocal + T.ItemizedFixedCostsCompl + T.ItemizedVariableCostsCompl) <> 0
		|	OR SUM(T.LaborCostsMan + T.ItemizedFixedCostsManag + T.ItemizedVariableCostsManag) <> 0
		|	OR SUM(T.AddExpensesForGoods) <> 0
		|	OR SUM(T.AdditionalExpensesExcludingVAT) <> 0
		|	OR SUM(T.AddExpensesLocal) <> 0
		|	OR SUM(T.AddExpensesMan) <> 0
		|	OR SUM(T.PermanentDifference) <> 0
		|	OR SUM(T.CostTD) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	T.Organization,
		|	T.DeviationItem AS Products,
		|	T.DeviationCharacteristic AS Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusinessDeviations AS LineOfBusiness,
		|	T.DeviationDivision AS Department,
		|	T.StorageLocationOfDeviation AS StorageLocation,
		|	&BeginOfPeriod AS VariancePeriod,
		|	VALUE(Enum.BusinessTransactions.InternalChangingPriceEvaluationMethod) AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.InternalChangingPriceEvaluationMethod) AS BusinessTransactionSetting,
		|	T.FinRecordID AS FinRecordID,
		|
		|	0 AS CostVariancesIncludingVAT,
		|	0 AS CostVariancesExcludingVAT,
		|	0 AS CostVariancesLocal,
		|	0 AS CostVariancesMgmt,
		|	0 AS AdditionalExpensesIncludingVAT,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS AddExpensesLocal,
		|	0 AS AddExpensesMan,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	SUM(T.VATLocalDeviations) AS VATLocal,
		|	SUM(T.VATManDeviations) AS VATManag
		|FROM
		|	TTOfBatchOfCostOfMediumSlip AS T
		|GROUP BY
		|	T.Organization,
		|	T.DeviationItem,
		|	T.DeviationCharacteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusinessDeviations,
		|	T.DeviationDivision,
		|	T.StorageLocationOfDeviation,
		|	T.FinRecordID
		|HAVING
		|	SUM(T.VATLocalDeviations) <> 0
		|	OR SUM(T.VATLocalDeviations) <> 0
		|)AS T
		|GROUP BY
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		|	T.VariancePeriod,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID
		|";
		
		Query.Text = StrReplace(Query.Text, "&RegisterResources",
			StringFunctionsClientServer.SubstituteParametersToString(AdjustmentParameters.RegisterDescription.RegisterResources, "T."));
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		
		CostCalculationAppliedAlgorithms.AddRegisterAdjustmentRegisteredRecords(
			CalculationParameters,
			AdjustmentParameters,
			"TTOfBatchOfCostOfMediumSlip",
			"TTStornoRestOfBatchesOfPrimeCostUpToAverageSliding",
			True,
			True);
		
		CostCalculationAppliedAlgorithms.AddRegisterAdjustmentRegisteredRecords(
			CalculationParameters,
			DeviationCorrectionParameters,
			"TTTransferOfAdditionalExpenseAmountINDSVDeviation",
			,
			True);
		
		#EndRegion
		
	EndIf;
	
EndProcedure

#EndRegion


#Region OperationsOfOperationsWithAnalyticsKeys


// Generates a description of the fields of the analytics key for substitution in query texts.
//
Function GenerateDescriptionOfInventoryLocationAttributeKeysOfItemSAccountingAnalyst(NameOfAnalyticsProps = "ItemsLocationAttributes",
			ExcludeFields = "", ExcludeStorageLocationDetailFields = True)
	
	KeysDetails = New Structure("NamedFields, FieldsNotNamed, ListOfFields");
	StructureOfExcludedFields = New Structure(
		CostCalculationUniversalAlgorithms.ConnectLines(
			ExcludeFields,
			?(ExcludeStorageLocationDetailFields, "StorageType, WarehouseArea, Department, Partner, Counterparty, Contract, Organization", "")));
	
	For Each MetaAttributes In Metadata.Catalogs.InventoryLocationAttributeKeys.Attributes Do
		
		If StructureOfExcludedFields.Property(MetaAttributes.Name) Then
			Continue;
		EndIf;
		
		CostCalculationUniversalAlgorithms.SupplementString(
			KeysDetails.NamedFields,
			"%1" + NameOfAnalyticsProps + "." + MetaAttributes.Name + " AS " + NameOfAnalyticsProps + "_" + MetaAttributes.Name,,,,
			"," + Chars.LF + "	");
		
		CostCalculationUniversalAlgorithms.SupplementString(
			KeysDetails.FieldsNotNamed,
			"%1" + NameOfAnalyticsProps + "." + MetaAttributes.Name,,,,
			"," + Chars.LF + "	");
		
		CostCalculationUniversalAlgorithms.SupplementString(
			KeysDetails.ListOfFields,
			NameOfAnalyticsProps + "_" + MetaAttributes.Name);
		
	EndDo;
	
	Return KeysDetails;
	
EndFunction

// Selects or creates item accounting analytics keys without assignment and creates a temporary table with the name <Receiver tablename>.
//
Function GenerateItemAnalyticsWithoutAssignment(CalculationParameters,
			SourceTableName_, DestinationTableName, NameOfAnalyticsField = "ItemsLocationAttributes")
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text =
	"SELECT DISTINCT
	|	T.NameOfAnalyticsField AS ItemsLocationAttributes
	|INTO TTAnalyticsKeysForItemsWithAssignments
	|FROM
	|	SourceTableName_ AS T
	|WHERE
	|	T.NameOfAnalyticsField <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|	AND T.NameOfAnalyticsField.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	T.ItemsLocationAttributes
	|FROM
	|	TTAnalyticsKeysForItemsWithAssignments AS T
	|";
	
	Query.Text = StrReplace(Query.Text, "SourceTableName_", SourceTableName_);
	Query.Text = StrReplace(Query.Text, "NameOfAnalyticsField",   NameOfAnalyticsField);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, "TTAnalyticsKeysForItemsWithAssignments");
		Return False; // adjustment of analytics is not required
	EndIf;
	
	Query.Text =
	"SELECT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	T.ItemsLocationAttributes.Series AS Series,
	|	T.ItemsLocationAttributes.StorageLocation AS StorageLocation,
	|	T.ItemsLocationAttributes.ProductCostElement AS ProductCostElement,
	|	ISNULL(Keys.Ref, UNDEFINED) AS AnalysisOfAccountingForProductsWithoutAssignment
	|INTO TTKeysForAnalyticsOfItemsWithoutAssignment
	|FROM
	|	TTAnalyticsKeysForItemsWithAssignments AS T
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON T.ItemsLocationAttributes.Products = Keys.Products
	|			AND T.ItemsLocationAttributes.CHARACTERISTIC = Keys.Characteristic
	|			AND T.ItemsLocationAttributes.Series = Keys.Series
	|			AND T.ItemsLocationAttributes.StorageLocation = Keys.StorageLocation
	|			AND T.ItemsLocationAttributes.ProductCostElement = Keys.ProductCostElement
	|			AND (Keys.Purpose = VALUE(Catalog.Assignments.EmptyRef))
	|			AND (Keys.DeletionMark = FALSE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	T.Series AS Series,
	|	T.StorageLocation AS StorageLocation,
	|	T.ProductCostElement AS ProductCostElement,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|FROM
	|	TTKeysForAnalyticsOfItemsWithoutAssignment AS T
	|WHERE
	|	T.AnalysisOfAccountingForProductsWithoutAssignment = UNDEFINED";
	
	Selection = Query.Execute().Select();
	
	AnalystTable = New ValueTable;
	AnalystTable.Columns.Add("ItemsLocationAttributes", New TypeDescription("CatalogRef.InventoryLocationAttributeKeys"));
	AnalystTable.Columns.Add("AnalysisOfAccountingForProductsWithoutAssignment", New TypeDescription("CatalogRef.InventoryLocationAttributeKeys"));
	
	While Selection.Next() Do
		
		NewRow = AnalystTable.Add();
		NewRow.ItemsLocationAttributes = Selection.ItemsLocationAttributes;
		
		Try
			NewRow.AnalysisOfAccountingForProductsWithoutAssignment = InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
		Except
			
			NewRow.AnalysisOfAccountingForProductsWithoutAssignment = NewRow.ItemsLocationAttributes;
			
			ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể tạo khóa đối tượng phân tích mà không có ấn định cho đối tượng phân tích kế toán mặt hàng ""%1"":
					|%2';
					|ru = 'Не удалось создать ключ аналитики без назначения для аналитики учета номенклатуры ""%1"":
					|%2';
					|en = 'Cannot generate the dimension key without the assignment for the ""%1"" inventory location attributes:
					|%2'; fa = 'Cannot generate the dimension key without the assignment for the ""%1"" inventory location attributes:
					|%2';
					|it = 'Cannot generate the dimension key without the assignment for the ""%1"" inventory location attributes:
					|%2';
					|pl = 'Cannot generate the dimension key without the assignment for the ""%1"" inventory location attributes:
					|%2';
					|tr = '""%1"" öğesi için atama yapılmadan boyut anahtarı oluşturulamadı:
					|%2'", Common.DefaultLanguageCode()),
				NewRow.ItemsLocationAttributes,
				DetailErrorDescription(ErrorInfo()));
			
			CostCalculationProtocol.FixCalculationError(
				CalculationParameters,
				Enums.TypesOfLotAccountingAndCostErrors.ErrorOccurredDuringLotAlocation,
				ProtocolText_);
			
		EndTry;
		
	EndDo;
	
	Query.SetParameter("AnalystTable", AnalystTable);
	
	Query.Text =
	"SELECT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.AnalysisOfAccountingForProductsWithoutAssignment AS AnalysisOfAccountingForProductsWithoutAssignment
	|INTO NewAnalyticsKeysForItemTTWithoutAssignment
	|FROM
	|	&AnalystTable AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN T.AnalysisOfAccountingForProductsWithoutAssignment = UNDEFINED
	|			THEN NewKeys.AnalysisOfAccountingForProductsWithoutAssignment
	|		ELSE T.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS AnalysisOfAccountingForProductsWithoutAssignment
	|INTO TTReplacementKeys
	|FROM
	|	TTKeysForAnalyticsOfItemsWithoutAssignment AS T
	|		LEFT JOIN NewAnalyticsKeysForItemTTWithoutAssignment AS NewKeys
	|		ON T.ItemsLocationAttributes = NewKeys.ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&FieldsOfSourceTable
	|INTO DestinationTableName
	|FROM
	|	SourceTableName_ AS T
	|		LEFT JOIN TTReplacementKeys AS NewKeys
	|		ON T.NameOfAnalyticsField = NewKeys.ItemsLocationAttributes
	|";
	
	FieldsOfSourceTable    = "";
	ColumnsFromSourceTable = CostCalculationAppliedAlgorithms.UnloadTemporaryTable(
		CalculationParameters,
		SourceTableName_,
		0).Columns;
	
	For Each CurrentColumn In ColumnsFromSourceTable Do
		
		If Lower(CurrentColumn.Name) = Lower(NameOfAnalyticsField) Then
			CostCalculationUniversalAlgorithms.SupplementString(
				FieldsOfSourceTable,
				"ISNULL(NewKeys.AnalysisOfAccountingForProductsWithoutAssignment, T." + NameOfAnalyticsField + ") AS " + NameOfAnalyticsField,,,,
				"," + Chars.LF + "	");
		Else
			CostCalculationUniversalAlgorithms.SupplementString(
				FieldsOfSourceTable,
				"T." + CurrentColumn.Name,,,,
				"," + Chars.LF + "	");
		EndIf;
		
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "SourceTableName_",  SourceTableName_);
	Query.Text = StrReplace(Query.Text, "DestinationTableName", DestinationTableName);
	Query.Text = StrReplace(Query.Text, "NameOfAnalyticsField",    NameOfAnalyticsField);
	Query.Text = StrReplace(Query.Text, "&FieldsOfSourceTable", FieldsOfSourceTable);
	
	Query.Execute();
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"TTAnalyticsKeysForItemsWithAssignments, TTKeysForAnalyticsOfItemsWithoutAssignment,
		|NewAnalyticsKeysForItemTTWithoutAssignment, TTReplacementKeys");
	
	Return True;
	
EndFunction

// Selects or creates item accounting analytics keys based on the values of the key fields and creates a temporary table with the name <Receiver tablename>.
//
Function GenerateItemAnalyticsBasedOnFieldValues(CalculationParameters,
			SourceTableName_, DestinationTableName, NameOfAnalyticsField = "ItemsLocationAttributes")
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text =
	"SELECT
	|	T.InventoryingLocationAttribute_Items AS Products,
	|	T.InventoryLocationAttributeOfItemSAccountingIs_Characteristic AS Characteristic,
	|	T.InventoryLocationAttributeAccountingSystem_Batch AS Series,
	|	T.ItemInventoryLocationAttribute_StorageLocation AS StorageLocation,
	|	T.ItemInventoryLocationAttributeAnalysis_Purpose AS Purpose,
	|	T.InventoryingLocationAttribute_ProductCostingElements AS ProductCostElement,
	|	ISNULL(Keys.Ref, UNDEFINED) AS ItemsLocationAttributes
	|INTO AnalyticsItemKeyTTFields
	|FROM
	|	SourceTableName_ AS T
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON T.InventoryingLocationAttribute_Items = Keys.Products
	|			AND T.InventoryLocationAttributeOfItemSAccountingIs_Characteristic = Keys.Characteristic
	|			AND T.InventoryLocationAttributeAccountingSystem_Batch = Keys.Series
	|			AND T.ItemInventoryLocationAttribute_StorageLocation = Keys.StorageLocation
	|			AND T.ItemInventoryLocationAttributeAnalysis_Purpose = Keys.Purpose
	|			AND T.InventoryingLocationAttribute_ProductCostingElements = Keys.ProductCostElement
	|			AND (Keys.DeletionMark = FALSE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Products,
	|	T.Characteristic,
	|	T.Series,
	|	T.StorageLocation,
	|	T.Purpose,
	|	T.ProductCostElement
	|FROM
	|	AnalyticsItemKeyTTFields AS T
	|WHERE
	|	T.ItemsLocationAttributes = UNDEFINED";
	
	Query.Text = StrReplace(Query.Text, "SourceTableName_", SourceTableName_);
	
	Selection = Query.Execute().Select();
	
	MetaAttributes = Metadata.Catalogs.InventoryLocationAttributeKeys.Attributes;
	
	AnalystTable = New ValueTable;
	AnalystTable.Columns.Add("Products", 	  MetaAttributes.Products.Type);
	AnalystTable.Columns.Add("Characteristic", 	  MetaAttributes.Characteristic.Type);
	AnalystTable.Columns.Add("Series", 			  MetaAttributes.Series.Type);
	AnalystTable.Columns.Add("StorageLocation", 	  MetaAttributes.StorageLocation.Type);
	AnalystTable.Columns.Add("Purpose", 		  MetaAttributes.Purpose.Type);
	AnalystTable.Columns.Add("ProductCostElement", MetaAttributes.ProductCostElement.Type);
	AnalystTable.Columns.Add("ItemsLocationAttributes", New TypeDescription("CatalogRef.InventoryLocationAttributeKeys"));
	
	While Selection.Next() Do
		
		NewRow = AnalystTable.Add();
		FillPropertyValues(NewRow, Selection);
		
		Try
			NewRow.ItemsLocationAttributes = InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
		Except
			
			ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể tạo khóa đối tượng phân tích cho mặt hàng ""%1"":
					|%2';
					|ru = 'Не удалось создать ключ аналитики для номенклатуры ""%1"":
					|%2';
					|en = 'Cannot generate the dimension key for the ""%1"" item:
					|%2'; fa = 'Cannot generate the dimension key for the ""%1"" item:
					|%2';
					|it = 'Cannot generate the dimension key for the ""%1"" item:
					|%2';
					|pl = 'Cannot generate the dimension key for the ""%1"" item:
					|%2';
					|tr = '""%1"" öğesi için boyut anahtarı oluşturulamadı:
					|%2'", Common.DefaultLanguageCode()),
				Selection.Products,
				DetailErrorDescription(ErrorInfo()));
			
			CostCalculationProtocol.FixCalculationError(
				CalculationParameters,
				Enums.TypesOfLotAccountingAndCostErrors.ErrorOccurredDuringLotAlocation,
				ProtocolText_);
			
			Raise CostCalculationAppliedAlgorithms.TextExceptionToLogProblem(ProtocolText_);
			
		EndTry;
		
	EndDo;
	
	Query.SetParameter("AnalystTable", AnalystTable);
	
	Query.Text =
	"SELECT
	|	T.ItemsLocationAttributes,
	|	T.Products,
	|	T.Characteristic,
	|	T.Series,
	|	T.StorageLocation,
	|	T.Purpose,
	|	T.ProductCostElement
	|INTO NewItemAnalyticsTTKeys
	|FROM
	|	&AnalystTable AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&FieldsOfSourceTable
	|INTO DestinationTableName
	|FROM
	|	SourceTableName_ AS T
	|		LEFT JOIN NewItemAnalyticsTTKeys AS NewKeys
	|		ON T.InventoryingLocationAttribute_Items = NewKeys.Products
	|			AND T.InventoryLocationAttributeOfItemSAccountingIs_Characteristic = NewKeys.Characteristic
	|			AND T.InventoryLocationAttributeAccountingSystem_Batch = NewKeys.Series
	|			AND T.ItemInventoryLocationAttribute_StorageLocation = NewKeys.StorageLocation
	|			AND T.ItemInventoryLocationAttributeAnalysis_Purpose = NewKeys.Purpose
	|			AND T.InventoryingLocationAttribute_ProductCostingElements = NewKeys.ProductCostElement
	|";
	
	FieldsOfSourceTable    = "";
	ColumnsFromSourceTable = CostCalculationAppliedAlgorithms.UnloadTemporaryTable(
		CalculationParameters,
		SourceTableName_,
		0).Columns;
	
	CostCalculationUniversalAlgorithms.SupplementString(
		FieldsOfSourceTable,
		"ISNULL(NewKeys.ItemsLocationAttributes, VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)) AS " + NameOfAnalyticsField,,,,
		"," + Chars.LF + "	");
	
	For Each CurrentColumn In ColumnsFromSourceTable Do
		
		CostCalculationUniversalAlgorithms.SupplementString(
				FieldsOfSourceTable,
				"T." + CurrentColumn.Name,,,,
				"," + Chars.LF + "	");
		
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "SourceTableName_",  SourceTableName_);
	Query.Text = StrReplace(Query.Text, "DestinationTableName", DestinationTableName);
	Query.Text = StrReplace(Query.Text, "&FieldsOfSourceTable", FieldsOfSourceTable);
	
	Query.Execute();
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"AnalyticsItemKeyTTFields, NewItemAnalyticsTTKeys");
	
	Return True;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndRegion

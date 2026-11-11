#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure GetItemPlanOnHold(Parameters, StorageAddress) Export

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Generation1 oflots ofproduction: transition k nomenclature by_plan");
	
	DataVolume = PositionsOfPlanForLaunchingIntoProductionInsideTimeMeasurement(Parameters, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

// Parameters:
//  Parameters - Structure - From:
//  *Groups - ValueTable
//  *Products_1 - ValueTable
//  StorageAddress - String
Procedure CreateDocumentsDeferred(Parameters, StorageAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Generation1 oflots ofproduction: creating documents");
	
	DataVolume = CreateDocumentsDeferredInsideTimeMeasurement(Parameters, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

// Parameters:
//  Parameters  - Structure - From:
//  *References - Array of CatalogRef.ProductionLots, DocumentRef.ProductionStage2_2
//  StorageAddress  - String
Procedure DeleteObjectsOnHold(Parameters, StorageAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Generation1 oflots ofproduction: delete created_ objects_");
	
	DeleteObjectsDeferredInsideTimeMeasurement(Parameters, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, Parameters.References.Count());
	
EndProcedure

// Default Stage formation parameters
// 
// Returns:
//   Structure - The structure that defines the default stage formation parameters.
//
Function DefaultDocumentCreationOptions() Export
	
	DocumentCreationOptions = New Structure();
	
	Replace_WithAnalogues = GetFunctionalOption("UseAlternativeMaterials");

	DocumentCreationOptions.Insert("ReserveMaterials",                     True);
	DocumentCreationOptions.Insert("ReplaceMaterialsWithAnalogs",      Replace_WithAnalogues);
	DocumentCreationOptions.Insert("OptionForTransferringStagesToExecution",           "All");
	DocumentCreationOptions.Insert("OptionToFillInScheduleOfStages", "CalculateFromCurDate");
	DocumentCreationOptions.Insert("ConsolidateBatchesBetweenOrders",               True);
	DocumentCreationOptions.Insert("ConsolidatePartiesByAppointment",               False);
	DocumentCreationOptions.Insert("SeparateProductionOfSemiFinishedProducts",              False);
	
	Return DocumentCreationOptions;
	
EndFunction

// The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "";
	Return AttributesNames;
	
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
	
	ChoiceParameterLinks = New Structure(
		ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	ChoiceParameterLinks.Products = "Object.PlanResults.Products";
	ChoiceParameterLinks.Characteristic = "Object.PlanResults.Characteristic";
	ChoiceParameterLinks.ProductionDispatcherBusinessUnit = "Object.PlanResults.ProductionDispatcherBusinessUnit";
	ChoiceParameterLinks.LineOfBusiness = "Object.PlanResults.LineOfBusiness";
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Object.PlanResults.BillOfMaterials", ChoiceParameterLinks);
	BOMSelectionParameters.SideOutputSpecificationsAreAvailable = True;
	
	Return BOMSelectionParameters;
	
EndFunction

#EndRegion

#Region Private

Function PositionsOfPlanForLaunchingIntoProductionInsideTimeMeasurement(Parameters, StorageAddress)
	
	Result = New Structure;
	Result.Insert("PlanResults", Undefined);
	Result.Insert("ColumnsPeriods", Undefined);
	Result.Insert("CustomFilters", Undefined);
	
	If Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		PutToTempStorage(Result, StorageAddress);
		Return 0;
	EndIf;
	
	TempTablesManager = New TempTablesManager();
	NomenclaturePlanInTemporaryTableManager(TempTablesManager, Parameters.Settings, Result.CustomFilters);
	
	CrossTable = Parameters.CrossTable;
	Periodicity = Parameters.Periodicity;
	NameOfPeriodDateField = Parameters.NameOfPeriodDateField;
	NumberOfPeriods = Parameters.NumberOfPeriods;
	
	QueryText =
		"SELECT
		|	Plan.BillOfMaterials                               AS BillOfMaterials,
		|	Plan.Organization                                AS Organization,
		|	Plan.Partner                                    AS Partner,
		|	Plan.Contract                                    AS Contract,
		|	Plan.LineOfBusiness                    AS LineOfBusiness,
		|	Plan.ProductionDispatcherBusinessUnit                     AS ProductionDispatcherBusinessUnit,
		|	Plan.OrderForActivity                       AS OrderForActivity,
		|	Plan.BusinessOperation                      AS BusinessOperation,
		|	Plan.ProductionProcessType               AS ProductionProcessType,
		|	Plan.Products.ProductKind               AS ProductKind,
		|	Plan.Products                               AS Products,
		|	Plan.Characteristic                             AS Characteristic,
		|	Plan.ProductionOrder                        AS ProductionOrder,
		|	Plan.KeyLot                                 AS KeyLot,
		|	Plan.StartDate2                                AS StartDate2,
		|	Plan.DateOfProduction                                AS DateOfProduction,
		|	MAX(Plan.QuantityForLaunchLotUnit) AS QuantityForLaunchLotUnit,
		|	MAX(Plan.MainProduct)                  AS MainProduct,
		|	SUM(Plan.Required2)                           AS Required2
		|INTO NomenclaturePlanWithoutDetails
		|FROM
		|	ItemPlan AS Plan
		|
		|GROUP BY
		|	Plan.BillOfMaterials,
		|	Plan.Organization,
		|	Plan.Partner,
		|	Plan.Contract,
		|	Plan.LineOfBusiness,
		|	Plan.ProductionDispatcherBusinessUnit,
		|	Plan.OrderForActivity,
		|	Plan.BusinessOperation,
		|	Plan.ProductionProcessType,
		|	Plan.Products.ProductKind,
		|	Plan.Products,
		|	Plan.Characteristic,
		|	Plan.ProductionOrder,
		|	Plan.KeyLot,
		|	Plan.StartDate2,
		|	Plan.DateOfProduction
		|
		|INDEX BY
		|	BillOfMaterials,
		|	Organization,
		|	Partner,
		|	Contract,
		|	LineOfBusiness,
		|	ProductionDispatcherBusinessUnit,
		|	OrderForActivity,
		|	BusinessOperation
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT DISTINCT
		|	Plan.BillOfMaterials        AS BillOfMaterials,
		|	Plan.ProductionOrder AS ProductionOrder
		|INTO MainAndByProductsAreOrdered
		|FROM
		|	NomenclaturePlanWithoutDetails AS Plan
		|WHERE
		|	TRUE IN (
		|		SELECT TOP 1
		|			TRUE	
		|		FROM
		|			NomenclaturePlanWithoutDetails AS T
		|		WHERE
		|			T.BillOfMaterials = Plan.BillOfMaterials
		|			AND T.ProductionOrder = Plan.ProductionOrder
		|			AND T.MainProduct <> Plan.MainProduct)
		|
		|INDEX BY
		|	BillOfMaterials, ProductionOrder
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	OrderStructure.PermissionToReplace AS PermissionToReplace
		|INTO AppliedPermissionsInBatches
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	&UseAlternativeMaterials
		|	AND OrderStructure.KeyLot IN
		|			(SELECT
		|				DD.KeyLot
		|			FROM
		|				NomenclaturePlanWithoutDetails AS DD)
		|
		|INDEX BY
		|	PermissionToReplace
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AlternativeMaterials.Recorder AS Resolution,
		|	AlternativeMaterials.Products AS Products,
		|	AlternativeMaterials.Characteristic AS Characteristic,
		|	AlternativeMaterials.ProductsRole AS ProductsRole,
		|	SUM(AlternativeMaterials.Count) AS Count
		|INTO CoefficientsOfNomenclatureOfReplacementPermits
		|FROM
		|	InformationRegister.AlternativeMaterials AS AlternativeMaterials
		|WHERE
		|	&UseAlternativeMaterials
		|	AND TRUE IN
		|			(SELECT
		|				TRUE
		|			FROM
		|				AppliedPermissionsInBatches AS Table
		|			WHERE
		|				Table.PermissionToReplace = AlternativeMaterials.Recorder)
		|
		|GROUP BY
		|	AlternativeMaterials.Recorder,
		|	AlternativeMaterials.Products,
		|	AlternativeMaterials.Characteristic,
		|	AlternativeMaterials.ProductsRole
		|
		|INDEX BY
		|	Resolution,
		|	Products,
		|	Characteristic,
		|	ProductsRole
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AnalogCoefficients.Resolution AS Resolution,
		|	AnalogCoefficients.Products AS Products,
		|	AnalogCoefficients.Characteristic AS Characteristic,
		|	AnalogCoefficients.Count AS Denominator,
		|	MIN(MaterialCoefficients.Count) AS Numerator
		|INTO CoefficientOfPermissionsByAnalogy
		|FROM
		|	CoefficientsOfNomenclatureOfReplacementPermits AS AnalogCoefficients
		|		INNER JOIN CoefficientsOfNomenclatureOfReplacementPermits AS MaterialCoefficients
		|		ON (AnalogCoefficients.Resolution = MaterialCoefficients.Resolution)
		|			AND (NOT(AnalogCoefficients.Products = MaterialCoefficients.Products
		|					AND AnalogCoefficients.Characteristic = MaterialCoefficients.Characteristic))
		|			AND (MaterialCoefficients.ProductsRole IN (VALUE(Enum.SubstituteRoles.Material), VALUE(Enum.SubstituteRoles.InterchangeableSubstitute)))
		|WHERE
		|	&UseAlternativeMaterials
		|	AND AnalogCoefficients.ProductsRole IN (VALUE(Enum.SubstituteRoles.Substitute), VALUE(Enum.SubstituteRoles.InterchangeableSubstitute))
		|	AND AnalogCoefficients.Count <> 0
		|
		|GROUP BY
		|	AnalogCoefficients.Resolution,
		|	AnalogCoefficients.Products,
		|	AnalogCoefficients.Characteristic,
		|	AnalogCoefficients.Count
		|
		|INDEX BY
		|	Resolution,
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	NestedQuery.KeyLot AS KeyLot,
		|	MIN(NestedQuery.Allocated/NestedQuery.QuantityForLaunchLotUnit) AS NumberOfPartiesIsProvided,
		|	MIN(NestedQuery.ToSupply = NestedQuery.Allocated) AS ThereIsFullProvision,
		|	MIN(NestedQuery.ToSupply = NestedQuery.Allocated) = FALSE
		|	AND MAX(NestedQuery.Allocated/NestedQuery.QuantityForLaunchLotUnit)
		|		> MIN(NestedQuery.Allocated/NestedQuery.QuantityForLaunchLotUnit) AS PartialSupplyIsAvailable
		|INTO TTSoftware
		|FROM
		|	(
		|	SELECT
		|		SupplyWithAnalogues.KeyLot AS KeyLot,
		|		SupplyWithAnalogues.KeyProducts AS KeyProducts,
		|		SUM(SupplyWithAnalogues.Allocated) AS Allocated,
		|		SUM(SupplyWithAnalogues.ToSupply) AS ToSupply,
		|		MAX(SupplyWithAnalogues.QuantityForLaunchLotUnit) AS QuantityForLaunchLotUnit
		|	FROM
		|		(SELECT
		|			OrderStructure.KeyLot AS KeyLot,
		|			OrderStructure.KeyProducts AS KeyProducts,
		|			OrderStructure.ProductionOrder AS ProductionOrder,
		|			OrderStructure.PermissionToReplace AS PermissionToReplace,
		|			SUM(CASE
		|					WHEN OrderStructure.ReceiptOrder = UNDEFINED
		|						THEN OrderStructure.AllocatedFromAvailableInventory + OrderStructure.AllocatedFromAvailableInventoryWithAssignment
		|					ELSE 0
		|				END) AS Allocated,
		|			SUM(CASE
		|					WHEN OrderStructure.ConnectionKeyTransfer = &EmptyKey
		|						THEN OrderStructure.ToSupply
		|					ELSE 0
		|				END) AS ToSupply,
		|			MAX(OrderStructure.QuantityForLaunchLotUnit) AS QuantityForLaunchLotUnit
		|		FROM
		|			InformationRegister.OrderStructure AS OrderStructure
		|		WHERE
		|			OrderStructure.KeyLot IN
		|					(SELECT
		|						DD.KeyLot
		|					FROM
		|						NomenclaturePlanWithoutDetails AS DD)
		|			AND OrderStructure.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption), VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved))
		|		
		|		GROUP BY
		|			OrderStructure.KeyLot,
		|			OrderStructure.KeyProducts,
		|			OrderStructure.ProductionOrder,
		|			OrderStructure.PermissionToReplace
		|		
		|		HAVING
		|			MAX(OrderStructure.QuantityForLaunchLotUnit) > 0 AND
		|			SUM(CASE
		|					WHEN OrderStructure.ConnectionKeyTransfer = &EmptyKey
		|						THEN OrderStructure.ToSupply
		|					ELSE 0
		|				END) > 0
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			OrderStructure.KeyLot,
		|			MAX(CASE
		|				WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|					AND OrderStructure.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|					THEN OrderStructure.ConnectionKeyTransfer
		|			END),
		|			OrderStructure.ProductionOrder,
		|			OrderStructure.PermissionToReplace,
		|			SUM(CASE
		|					WHEN OrderStructure.ReceiptOrder = UNDEFINED
		|						THEN (OrderStructure.AllocatedFromAvailableInventory + OrderStructure.AllocatedFromAvailableInventoryWithAssignment) / AlternativeMaterials.Denominator * AlternativeMaterials.Numerator
		|					ELSE 0
		|				END),
		|			0,
		|			0
		|		FROM
		|			InformationRegister.OrderStructure AS OrderStructure
		|				INNER JOIN CoefficientOfPermissionsByAnalogy AS AlternativeMaterials
		|				ON OrderStructure.Products = AlternativeMaterials.Products
		|					AND OrderStructure.Characteristic = AlternativeMaterials.Characteristic
		|					AND OrderStructure.PermissionToReplace = AlternativeMaterials.Resolution
		|		WHERE
		|			&UseAlternativeMaterials
		|			AND OrderStructure.KeyLot IN
		|					(SELECT
		|						DD.KeyLot
		|					FROM
		|						NomenclaturePlanWithoutDetails AS DD)
		|			AND OrderStructure.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption), VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved))
		|		
		|		GROUP BY
		|			OrderStructure.KeyLot,
		|			OrderStructure.ProductionOrder,
		|			OrderStructure.PermissionToReplace
		|		
		|		HAVING
		|			SUM(CASE
		|					WHEN OrderStructure.ReceiptOrder = UNDEFINED
		|						THEN (OrderStructure.AllocatedFromAvailableInventory + OrderStructure.AllocatedFromAvailableInventoryWithAssignment) / AlternativeMaterials.Denominator * AlternativeMaterials.Numerator
		|					ELSE 0
		|				END) > 0) AS SupplyWithAnalogues
		|	GROUP BY
		|		SupplyWithAnalogues.KeyLot,
		|		SupplyWithAnalogues.KeyProducts
		|
		|	HAVING
		|		MAX(SupplyWithAnalogues.QuantityForLaunchLotUnit) <> 0
		|) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.KeyLot
		|
		|INDEX BY
		|	KeyLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT TOP 10000000
		|
		|	RECORDAUTONUMBER()                               AS NumberOfGroup,
		|
		|	Groups.BillOfMaterials                             AS BillOfMaterials,
		|	Groups.Organization                              AS Organization,
		|	Groups.Partner                                  AS Partner,
		|	Groups.Contract                                  AS Contract,
		|	Groups.LineOfBusiness                  AS LineOfBusiness,
		|	Groups.ProductionDispatcherBusinessUnit                   AS ProductionDispatcherBusinessUnit,
		|	Groups.OrderForActivity                     AS OrderForActivity,
		|	Groups.BusinessOperation                    AS BusinessOperation,
		|
		|	Groups.GroupingByProductType                AS GroupingByProductType,
		|	Groups.ProductItemsAndGroupings                  AS ProductItemsAndGroupings,
		|	Groups.CharacteristicGrouping                AS CharacteristicGrouping,
		|
		|	Groups.MinimumLaunchDate                       AS MinimumLaunchDate,
		|	Groups.MinimumReleaseDate                       AS MinimumReleaseDate
		|
		|INTO Groups
		|FROM
		|	(SELECT
		|		Plan.BillOfMaterials            AS BillOfMaterials,
		|		Plan.Organization             AS Organization,
		|		Plan.Partner                 AS Partner,
		|		Plan.Contract                 AS Contract,
		|		Plan.LineOfBusiness AS LineOfBusiness,
		|		Plan.ProductionDispatcherBusinessUnit  AS ProductionDispatcherBusinessUnit,
		|		Plan.OrderForActivity    AS OrderForActivity,
		|		Plan.BusinessOperation   AS BusinessOperation,
		|	
		|		Plan.BillOfMaterials.ThereIsSpecifiedMainProduct AS GroupingByProductType,
		|		CASE
		|			WHEN Plan.BillOfMaterials.ThereIsSpecifiedMainProduct
		|				THEN Plan.Products
		|			ELSE VALUE(Catalog.Products.EmptyRef)
		|		END                                         AS ProductItemsAndGroupings,
		|		CASE
		|			WHEN Plan.BillOfMaterials.ThereIsSpecifiedMainProduct
		|				THEN Plan.Characteristic
		|			ELSE VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		END                                         AS CharacteristicGrouping,
		|	
		|		MIN(CASE
		|					WHEN Plan.StartDate2 <> DATETIME(1,1,1)
		|						THEN Plan.StartDate2
		|				END)                                AS MinimumLaunchDate,
		|		MIN(CASE
		|					WHEN Plan.DateOfProduction <> DATETIME(1,1,1)
		|						THEN Plan.DateOfProduction
		|				END)                                AS MinimumReleaseDate
		|	
		|	FROM
		|		NomenclaturePlanWithoutDetails AS Plan
		|	
		|	GROUP BY
		|		Plan.BillOfMaterials,
		|		Plan.Organization,
		|		Plan.Partner,
		|		Plan.Contract,
		|		Plan.LineOfBusiness,
		|		Plan.ProductionDispatcherBusinessUnit,
		|		Plan.OrderForActivity,
		|		Plan.BusinessOperation,
		|		Plan.BillOfMaterials.ThereIsSpecifiedMainProduct,
		|		CASE
		|			WHEN Plan.BillOfMaterials.ThereIsSpecifiedMainProduct
		|				THEN Plan.Products
		|			ELSE VALUE(Catalog.Products.EmptyRef)
		|		END,
		|		CASE
		|			WHEN Plan.BillOfMaterials.ThereIsSpecifiedMainProduct
		|				THEN Plan.Characteristic
		|			ELSE VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		END
		|	) AS Groups
		|
		|ORDER BY
		|	&TextOfGroupSortingOrderField,
		|	Groups.BillOfMaterials
		|
		|INDEX BY
		|	Groups.BillOfMaterials,
		|	Groups.Organization,
		|	Groups.Partner,
		|	Groups.Contract,
		|	Groups.LineOfBusiness,
		|	Groups.ProductionDispatcherBusinessUnit,
		|	Groups.OrderForActivity,
		|	Groups.BusinessOperation
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Groups.NumberOfGroup                              AS NumberOfGroup,
		|	Groups.BillOfMaterials                             AS BillOfMaterials,
		|	Groups.BillOfMaterials                             AS BillOfMaterialsPlan,
		|	Groups.Organization                              AS Organization,
		|	Groups.Partner                                  AS Partner,
		|	Groups.Contract                                  AS Contract,
		|	Groups.LineOfBusiness                  AS LineOfBusiness,
		|	Groups.ProductionDispatcherBusinessUnit                   AS ProductionDispatcherBusinessUnit,
		|	Groups.OrderForActivity                     AS OrderForActivity,
		|	Groups.BusinessOperation                    AS BusinessOperation,
		|	Plan.ProductionProcessType               AS ProductionProcessType,
		|
		|	Groups.GroupingByProductType                AS GroupingByProductType,
		|	Plan.MainProduct                            AS MainProduct,
		|
		|	Plan.Products                               AS Products,
		|	Plan.Products.ItemsType               AS ItemsType,
		|	Plan.Products.ProductKind               AS ProductKind,
		|	Plan.Characteristic                             AS Characteristic,
		|
		|	PRESENTATION(Plan.Products)                  AS ProductsPresentation,
		|	PRESENTATION(Plan.Products.UnitOfMeasure) AS ProductsUnitOfMeasurePresentation,
		|	PRESENTATION(Plan.Characteristic)                AS CharacteristicPresentation,
		|
		|	&TextOfPeriodField                                AS Period,
		|	&TextOfPeriodField = DATETIME(1,1,1)             AS ThereIsEmptyPeriod,
		|	CASE
		|		WHEN &TextOfPeriodField <> DATETIME(1,1,1)
		|			THEN &TextOfPeriodField
		|	END                                           AS PeriodMinimum,
		|
		|	MIN(CASE
		|				WHEN ISNULL(Groups.MinimumLaunchDate, DATETIME(1,1,1)) <> DATETIME(1,1,1)
		|					THEN Groups.MinimumLaunchDate
		|			END)                                  AS LaunchDateMinimumByGroup,
		|
		|	MIN(CASE
		|				WHEN ISNULL(Groups.MinimumReleaseDate, DATETIME(1,1,1)) <> DATETIME(1,1,1)
		|					THEN Groups.MinimumReleaseDate
		|			END)                                  AS ReleaseDateMinimumByGroup,
		|
		|	MAX(Groups.GroupingByProductType
		|				AND MainAndByProductsAreOrdered.BillOfMaterials IS NOT NULL) AS Regroup,
		|	MAX((Groups.GroupingByProductType
		|				AND MainAndByProductsAreOrdered.BillOfMaterials IS NOT NULL)
		|			OR Plan.BillOfMaterials.AssignmentOption = VALUE(
		|					Enum.BillOfMaterialsAssignmentOptions.ItemList)) AS MultipleLaunch,
		|
		|	TRUE                                          AS AutoRecalculation,
		|
		|	SUM(Plan.Required2)                           AS Required2,
		|	SUM(Plan.Required2)                           AS Launch,
		|
		|	MAX(Supply.KeyLot IS NOT NULL) AS SupplyIsRequired,
		|	SUM(CASE
		|		WHEN Supply.NumberOfPartiesIsProvided IS NULL OR Supply.NumberOfPartiesIsProvided = 0
		|			THEN 0
		|		WHEN Supply.ThereIsFullProvision
		|			THEN Plan.Required2
		|		WHEN Plan.BillOfMaterials.ProductionIssueByCustomPortions
		|			THEN CASE
		|				WHEN Supply.NumberOfPartiesIsProvided * Plan.QuantityForLaunchLotUnit >= Plan.Required2
		|					THEN Plan.Required2
		|				WHEN Plan.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|					THEN CAST(Supply.NumberOfPartiesIsProvided * Plan.QuantityForLaunchLotUnit - 0.5 AS NUMBER(15, 0))
		|				ELSE Supply.NumberOfPartiesIsProvided * Plan.QuantityForLaunchLotUnit
		|			END
		|		ELSE CASE
		|			WHEN CAST(Supply.NumberOfPartiesIsProvided - 0.5 AS NUMBER(15, 0)) * Plan.QuantityForLaunchLotUnit >= Plan.Required2
		|				THEN Plan.Required2
		|			WHEN Plan.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|				THEN CAST(CAST(Supply.NumberOfPartiesIsProvided - 0.5 AS NUMBER(15, 0)) * Plan.QuantityForLaunchLotUnit - 0.5 AS NUMBER(15, 0))
		|			ELSE CAST(Supply.NumberOfPartiesIsProvided - 0.5 AS NUMBER(15, 0)) * Plan.QuantityForLaunchLotUnit
		|		END
		|	END) AS Supplied,
		|	MAX(Supply.PartialSupplyIsAvailable)  AS PartialSupplyIsAvailable,
		|	MAX(Plan.BillOfMaterials.EconomicReleaseLot <> 0) AS ThereIsOptimalLotReference,
		|	MAX(Plan.QuantityForLaunchLotUnit) AS QuantityPerBatch
		|FROM
		|	NomenclaturePlanWithoutDetails AS Plan
		|	
		|	INNER JOIN Groups AS Groups
		|	ON Plan.BillOfMaterials = Groups.BillOfMaterials
		|		AND Plan.Organization = Groups.Organization
		|		AND Plan.Partner = Groups.Partner
		|		AND Plan.Contract = Groups.Contract
		|		AND Plan.LineOfBusiness = Groups.LineOfBusiness
		|		AND Plan.ProductionDispatcherBusinessUnit = Groups.ProductionDispatcherBusinessUnit
		|		AND Plan.OrderForActivity = Groups.OrderForActivity
		|		AND Plan.BusinessOperation = Groups.BusinessOperation
		|		AND (NOT Groups.GroupingByProductType
		|			OR Plan.Products = Groups.ProductItemsAndGroupings
		|				AND Plan.Characteristic = Groups.CharacteristicGrouping)
		|	
		|	LEFT JOIN TTSoftware AS Supply
		|	ON Plan.KeyLot = Supply.KeyLot
		|
		|	LEFT JOIN MainAndByProductsAreOrdered AS MainAndByProductsAreOrdered
		|	ON Plan.BillOfMaterials = MainAndByProductsAreOrdered.BillOfMaterials
		|		AND Plan.ProductionOrder = MainAndByProductsAreOrdered.ProductionOrder
		|
		|GROUP BY
		|	Groups.NumberOfGroup,
		|	Groups.BillOfMaterials,
		|	Groups.Organization,
		|	Groups.Partner,
		|	Groups.Contract,
		|	Groups.LineOfBusiness,
		|	Groups.ProductionDispatcherBusinessUnit,
		|	Groups.OrderForActivity,
		|	Groups.BusinessOperation,
		|	Plan.ProductionProcessType,
		|	Groups.GroupingByProductType,
		|	Plan.MainProduct,
		|	Plan.Products,
		|	Plan.Products.ItemsType,
		|	Plan.Products.ProductKind,
		|	Plan.Products.UnitOfMeasure,
		|	Plan.Products.UnitOfMeasure.MeasuredValueType,
		|	Plan.Characteristic,
		|	&TextOfPeriodField,
		|	&TextOfPeriodField = DATETIME(1,1,1),
		|	CASE
		|		WHEN &TextOfPeriodField <> DATETIME(1,1,1)
		|			THEN &TextOfPeriodField
		|	END
		|
		|ORDER BY
		|	Groups.NumberOfGroup,
		|	Plan.Products,
		|	Plan.Characteristic
		|AUTOORDER
		|
		|TOTALS
		|	MAX(Period),
		|	MAX(ThereIsEmptyPeriod),
		|	MIN(PeriodMinimum)
		|BY
		|	OVERALL";
	
	If Not CrossTable Then
		QueryText = StrReplace(QueryText, "&TextOfPeriodField", "UNDEFINED");
	Else
		PeriodType = ?(Periodicity = Enums.Periodicity.Day,
			"DAY",
			?(Periodicity = Enums.Periodicity.Week, "WEEK", "MONTH"));
		PathToPeriod = ?(NameOfPeriodDateField = "StartDate2",
			"Plan.StartDate2",
			"Plan.DateOfProduction");
		QueryText = StrReplace(QueryText,
			"&TextOfPeriodField",
			StrTemplate("BEGINOFPERIOD(%1, %2)", PathToPeriod, PeriodType));
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TextOfGroupSortingOrderField",
		?(Not CrossTable Or NameOfPeriodDateField = "StartDate2", "Groups.MinimumLaunchDate","Groups.MinimumReleaseDate"));
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("EmptyKey", CommonClientServer.BlankUUID());
	Query.SetParameter("UseAlternativeMaterials", GetFunctionalOption("UseAlternativeMaterials"));
	SampleResults = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	// Initializing the totals table
	ColumnsToAdd = New Structure();
	ColumnsToAdd.Insert("SupplyIsAvailable", New TypeDescription("Boolean"));
	PlanResults = OrderStructure.CopyColumns(SampleResults.Owner().Columns,,, ColumnsToAdd);
	
	If Not SampleResults.Next() Then
		Result.PlanResults = PlanResults;
		PutToTempStorage(Result, StorageAddress);
		Return 0;
	EndIf;
	
	// Filling in the totals table
	Selection = SampleResults.Select();
	
	If Not CrossTable Then
		While Selection.Next() Do
			NewRow = PlanResults.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.SupplyIsAvailable = Selection.Supplied > 0 Or Not Selection.SupplyIsRequired;
		EndDo;
	Else
		
		// Adding columns with periods
		If Not ValueIsFilled(SampleResults.PeriodMinimum) Then
			PeriodBoundary = '00010101';
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Day") Then 
			PeriodBoundary = SampleResults.PeriodMinimum + 86400 * NumberOfPeriods;
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
			PeriodBoundary = SampleResults.PeriodMinimum + 86400 * 7 * NumberOfPeriods;
		ElsIf (Periodicity= PredefinedValue("Enum.Periodicity.Month")) Then
			PeriodBoundary = AddMonth(SampleResults.PeriodMinimum, NumberOfPeriods);
		Else
			Raise StrTemplate(NStr("vi = 'Không hỗ trợ định kỳ ""%1""';
									|ru = 'Периодичность ""%1"" не поддерживается';
									|en = 'The ""%1"" frequency is not supported'; fa = 'The ""%1"" frequency is not supported';
									|it = 'Периодичность ""%1"" не поддерживается';
									|pl = 'Okresowość ""%1"" nie jest obsługiwana';
									|tr = '""%1"" sıklığı desteklenmemektedir'"), Periodicity);
		EndIf;
		PeriodBoundary = Max(SampleResults.Period, PeriodBoundary);
		
		If SampleResults.ThereIsEmptyPeriod Then
			Period = '00010101';
			NumberOfPeriods = NumberOfPeriods + 1;
		Else
			Period = SampleResults.PeriodMinimum;
		EndIf;
		
		Cnt = 0;
		ColumnsNames = New Map;
		ColumnsPeriods = New Array;
		TypeDescription = New TypeDescription("Number", New NumberQualifiers(15,3));
		While Period <= PeriodBoundary Do
			If Cnt < NumberOfPeriods - 1 Then
				Name = StrTemplate("_%1_%2_%3_%4",
					Format(Day(Period), "ND=2; NLZ="),
					Format(Month(Period),  "ND=2; NLZ="),
					Format(Year(Period), "ND=4; NLZ=; NG="),
					?(Periodicity = Enums.Periodicity.Day, 1, ?(Periodicity = Enums.Periodicity.Week, 2, 3)));
				If Not ValueIsFilled(Period) Then
					Title = NStr("vi = 'Ngày chưa được đặt';
								|ru = 'Дата не определена';
								|en = 'The date is not defined'; fa = 'The date is not defined';
								|it = 'Дата не определена';
								|pl = 'Data nie jest określona';
								|tr = 'Tarih belirlenmedi'");
				ElsIf Periodicity = Enums.Periodicity.Day Then
					Title = Format(Period, "DF='dd.MM'");
				ElsIf Periodicity = Enums.Periodicity.Week Then
					Title = StrTemplate(
						"%1 - %2",
						Format(Period, "DF='dd.MM'"),
						Format(EndOfWeek(Period), "DF='dd.MM'"));
				Else
					Title = Format(Period, NStr("vi = 'DF=''MMMM yyyy''';
												|ru = 'ДФ=''MMMM yyyy''';
												|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
												|it = 'DF=''MMMM yyyy''';
												|pl = 'DF=''MMMM yyyy''';
												|tr = 'DF=''MMMM yyyy'''"));
				EndIf;
				PlanResults.Columns.Add(Name, TypeDescription, Title);
				ColumnsPeriods.Add(Name);
				ColumnsNames.Insert(Period, Name);
				Cnt = Cnt + 1;
			Else
				If Cnt = NumberOfPeriods - 1 Then
					// A column that includes all subsequent periods
					Name = StrTemplate("_%1_%2_%3_%4",
						Format(Day(Period), "ND=2; NLZ="),
						Format(Month(Period),  "ND=2; NLZ="),
						Format(Year(Period), "ND=4; NLZ=; NG="),
						?(Periodicity = Enums.Periodicity.Day, 1, ?(Periodicity = Enums.Periodicity.Week, 2, 3)));
					If Not ValueIsFilled(Period) Then
						Title = NStr("vi = 'Ngày chưa được đặt';
									|ru = 'Дата не определена';
									|en = 'The date is not defined'; fa = 'The date is not defined';
									|it = 'Дата не определена';
									|pl = 'Data nie jest określona';
									|tr = 'Tarih belirlenmedi'");
					ElsIf Periodicity = Enums.Periodicity.Day
						Or Periodicity = Enums.Periodicity.Week Then
						Title = StrTemplate(NStr("vi = '%1 và tiếp theo';
												|ru = '%1 и далее';
												|en = '%1 and further'; fa = '%1 and further';
												|it = '%1 и далее';
												|pl = '%1 and further';
												|tr = '%1 ve dahası'"),
							Format(Period, "DF='dd.MM'"));
					Else
						Title = StrTemplate(NStr("vi = '%1 và tiếp theo';
												|ru = '%1 и далее';
												|en = '%1 and further'; fa = '%1 and further';
												|it = '%1 и далее';
												|pl = '%1 and further';
												|tr = '%1 ve dahası'"),
							Format(Period, NStr("vi = 'DF=''MMMM yyyy''';
												|ru = 'ДФ=''MMMM yyyy''';
												|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
												|it = 'DF=''MMMM yyyy''';
												|pl = 'DF=''MMMM yyyy''';
												|tr = 'DF=''MMMM yyyy'''")));
					EndIf;
					PlanResults.Columns.Add(Name, TypeDescription, Title);
					ColumnsPeriods.Add(Name);
					Cnt = Cnt + 1;
				EndIf;
				ColumnsNames.Insert(Period, ColumnsPeriods[Cnt-1]);
			EndIf;
			If Period = '00010101' And Not ValueIsFilled(SampleResults.PeriodMinimum) Then
				Break;
			ElsIf Period = '00010101' Then
				Period = SampleResults.PeriodMinimum;
			ElsIf Periodicity = Enums.Periodicity.Day Then
				Period = EndOfDay(Period) + 1;
			ElsIf Periodicity = Enums.Periodicity.Week Then
				Period = EndOfWeek(Period) + 1;
			Else
				Period = EndOfMonth(Period) + 1;
			EndIf;
		EndDo;
		Result.ColumnsPeriods = ColumnsPeriods;
		
		// Adding rows
		Group = New Structure("NumberOfGroup,Products,Characteristic");
		NewRow = Undefined;
		
		While Selection.Next() Do
			If Selection.NumberOfGroup <> Group.NumberOfGroup
					Or Selection.Products <> Group.Products
					Or Selection.Characteristic <> Group.Characteristic Then
				NewRow = PlanResults.Add();
				NewRow.Required2  = 0;
				NewRow.Supplied = 0;
				NewRow.Launch   = 0;
				FillPropertyValues(NewRow, Selection,, "Required2, Supplied, Launch");
				FillPropertyValues(Group, Selection);
			EndIf;
			NewRow.Required2 = NewRow.Required2 + Selection.Required2;
			NewRow.Supplied = NewRow.Supplied + Selection.Supplied;
			NewRow.Launch = NewRow.Launch + Selection.Launch;
			NewRow.SupplyIsAvailable = NewRow.Supplied > 0 Or Not NewRow.SupplyIsRequired;
			NewRow.PartialSupplyIsAvailable = NewRow.PartialSupplyIsAvailable Or NewRow.PartialSupplyIsAvailable;
			NewRow[ColumnsNames[Selection.Period]] = NewRow[ColumnsNames[Selection.Period]] + Selection.Required2;
		EndDo;
		
	EndIf;
	
	// Additional PlanItoga columns
	PlanResults.Columns.Add("Route", New TypeDescription("String"));
	
	Query.Text =
		"SELECT
		|	Stages.Owner          AS BillOfMaterials,
		|	Stages.Department     AS Department,
		|	Stages.Department.Code AS DivisionID
		|FROM
		|	Catalog.ProductionStages AS Stages
		|WHERE
		|	Stages.Owner IN (
		|		SELECT
		|			Plan.BillOfMaterials AS Owner
		|		FROM
		|			NomenclaturePlanWithoutDetails AS Plan)
		|	AND NOT Stages.DeletionMark
		|
		|ORDER BY
		|	Stages.Owner,
		|	Stages.StageNumber,
		|	Stages.Department
		|
		|TOTALS BY
		|	Stages.Owner";
	SelectionRoute = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	TemporaryIndex = PlanResults.Indexes.Add("BillOfMaterials");
	TheStructureOfTheSearch = New Structure("BillOfMaterials");
	Order = New Array();
	
	While SelectionRoute.Next() Do
		
		SamplingStages = SelectionRoute.Select();
		While SamplingStages.Next() Do
		 	Order.Add(
				ObjectsPrefixesClientServer.NumberForPrinting(
					TrimAll(SamplingStages.DivisionID), True, True));
		EndDo;
		Route = StrConcat(Order, " - ");
		
		TheStructureOfTheSearch.BillOfMaterials = SelectionRoute.BillOfMaterials;
		For Each String In PlanResults.FindRows(TheStructureOfTheSearch) Do
			String.Route = Route;
		EndDo;
		
		Order.Clear();
		
	EndDo;
	
	PlanResults.Indexes.Delete(TemporaryIndex);
	
	Result.PlanResults = PlanResults;
	PutToTempStorage(Result, StorageAddress);
	
	Return PlanResults.Count();
	
EndFunction

Procedure NomenclaturePlanInTemporaryTableManager(TempTablesManager, SettingsForSelections, CustomFilters)
	
	DataCompositionSchema = DataProcessors.GeneratingProductionStages.GetTemplate("ItemPlan");
	
	// Disabling the selection of Presentations of links
	ReferencesFields = StrSplit(
		"Products,Characteristic,Warehouse,Purpose,ProductionOrder,BillOfMaterials,Organization,Partner,Contract,LineOfBusiness,ProductionDispatcherBusinessUnit",
		",");
	For Each FieldName In ReferencesFields Do
		Field = DataCompositionSchema.DataSets[0].Fields.Find(FieldName);
		If Field <> Undefined Then
			Field.PresentationExpression = """-""";
		EndIf;
	EndDo;
	
	// Calculation of R&M availability
	Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	Document.ProductionOrder2_2 AS Orders
		|WHERE
		|	Orders.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|	AND Orders.Posted
		|	AND Orders.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)");
	RAndMRepairsAreUsed = Not Query.Execute().IsEmpty();
	
	// Request text layout
	SettingsSource = New DataCompositionAvailableSettingsSource(
		PutToTempStorage(DataCompositionSchema));
	
	SettingsComposer = New DataCompositionSettingsComposer();
	SettingsComposer.Initialize(SettingsSource);
	SettingsComposer.LoadSettings(SettingsForSelections);
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	If RAndMRepairsAreUsed Then
		// Only the order-manufactured products or the work of the stages started
		NewFilter = SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		NewFilter.LeftValue = New DataCompositionField("LaunchIsPossible");
		NewFilter.ComparisonType = DataCompositionComparisonType.Equal;
		NewFilter.RightValue = True;
		NewFilter.Use = True;
		
		// Selection for the FINISHED product to be repaired
		ProductsField = New DataCompositionField("Products");
		CharacteristicField = New DataCompositionField("Characteristic");
		For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
			If Not FilterElement.Use 
				Or TypeOf(FilterElement) <> Type("DataCompositionFilterItem") Then
				Continue;
			EndIf;
			
			If FilterElement.LeftValue = ProductsField
				Or StrFind(String(FilterElement.LeftValue), "Products.") <> 0 Then
				FilterGroup = SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
				FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
				FilterGroup.Use = True;
				
				NewElementOfSelection = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
				FillPropertyValues(NewElementOfSelection, FilterElement, "LeftValue, ComparisonType, RightValue, Use");
				
				NewElementOfSelection = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
				FillPropertyValues(NewElementOfSelection, FilterElement, "ComparisonType, RightValue, Use");
				NewElementOfSelection.LeftValue = ?(FilterElement.LeftValue = ProductsField,
					New DataCompositionField("UnderRepairProduct"),
					New DataCompositionField(StrReplace(String(FilterElement.LeftValue), "Products.", "UnderRepairProduct.")));
				
				FilterElement.Use = False;
			EndIf;
			
			If FilterElement.LeftValue = CharacteristicField
				Or StrFind(String(FilterElement.LeftValue), "Characteristic.") <> 0 Then
				FilterGroup = SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
				FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
				FilterGroup.Use = True;
				
				NewElementOfSelection = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
				FillPropertyValues(NewElementOfSelection, FilterElement, "LeftValue, ComparisonType, RightValue, Use");
				
				NewElementOfSelection = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
				FillPropertyValues(NewElementOfSelection, FilterElement, "ComparisonType, RightValue, Use");
				NewElementOfSelection.LeftValue = ?(FilterElement.LeftValue = CharacteristicField,
					New DataCompositionField("UnderRepairVariant"),
					New DataCompositionField(StrReplace(String(FilterElement.LeftValue), "Characteristic.", "UnderRepairVariant.")));
				
				FilterElement.Use = False;
			EndIf;
		EndDo;
	EndIf;
	
	CompositionSettings = SettingsComposer.GetSettings();
	
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(
		DataCompositionSchema, CompositionSettings,,,, False);
	
	QueryText = DataCompositionTemplate.DataSets.DataSet.Query;
	
	// REQUEST EXECUTION
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		QueryText = StrReplace(QueryText, "UNDEFINED AS Organization2", "&DefaultCompany AS Organization");
		Query.SetParameter("DefaultCompany", SettingsValueCached.GetDefaultOrganization());
	EndIf;
	
	If Not GetFunctionalOption("UseCostAccountingByLinesOfBusiness")
		Or Not GetFunctionalOption("GenerateFinancialResult") Then
		QueryText = StrReplace(QueryText, "LineOfBusiness2", "LineOfBusiness");
	EndIf;
	
	If Not GetFunctionalOption("UseItemVariants") Then
		QueryText = StrReplace(QueryText, "Characteristic2", "Characteristic");
	EndIf;
	
	If Not GetFunctionalOption("UseBusinessUnits")
		And StrFind(QueryText, "AS ProductionDispatcherBusinessUnit,") = 0 Then
		QueryText = StrReplace(QueryText,
			"UNDEFINED AS ProductionDispatcherBusinessUnit2",
			"Plan.ProductionOrder.Department AS ProductionDispatcherBusinessUnit");
	EndIf;
	
	If Not GetFunctionalOption("UseSeparateAccountingByTaxation")
		And Not GetFunctionalOption("UseVATAccounting")
		And StrFind(QueryText, "AS OrderForActivity,") = 0 Then
		QueryText = StrReplace(QueryText,
			"UNDEFINED AS OrderForActivity2",
			"Plan.ProductionOrder.OrderForActivity AS OrderForActivity");
	EndIf;
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	QuerySchema.QueryBatch[0].PlacementTable = "ItemPlan";
	
	IndexesByList = StrSplit("BillOfMaterials,Organization,Partner,Contract,LineOfBusiness,ProductionDispatcherBusinessUnit,OrderForActivity,BusinessOperation", ",");
	For Each Field In IndexesByList Do
		QuerySchema.QueryBatch[0].Index.Add(Field);
	EndDo;
	
	Query.Text = QuerySchema.GetQueryText();
	
	SelectionTexts = New Array;
	For Each SchemaExpression In QuerySchema.QueryBatch[0].Operators[0].Filter Do
		SelectionTexts.Add("" + SchemaExpression);
	EndDo;
	
	Filters = New ValueTable;
	Filters.Columns.Add("Name", New TypeDescription("String"));
	Filters.Columns.Add("Value");
	Filters.Columns.Add("Text", New TypeDescription("String"));
	
	For IndexOf = -DataCompositionTemplate.ParameterValues.Count() + 1 To 0 Do
		
		LayoutParameter = DataCompositionTemplate.ParameterValues[-IndexOf];
		Query.SetParameter(LayoutParameter.Name, LayoutParameter.Value);
		
		// Caching selections for later reading of detailed records
		For IndexText = 0 To SelectionTexts.UBound() Do
			If StrFind(SelectionTexts[IndexText], "&" + LayoutParameter.Name) Then
				NewRow = Filters.Add();
				FillPropertyValues(NewRow, LayoutParameter, "Name, Value");
				NewRow.Text = SelectionTexts[IndexText];
				SelectionTexts.Delete(IndexText);
				Break;
			EndIf;
		EndDo;
		
	EndDo;
	
	ConnectionsWithAdditionalAttributes = New ValueTable;
	ConnectionsWithAdditionalAttributes.Columns.Add("TableName", New TypeDescription("String"));
	ConnectionsWithAdditionalAttributes.Columns.Add("Alias", New TypeDescription("String"));
	ConnectionsWithAdditionalAttributes.Columns.Add("Condition", New TypeDescription("String"));
	
	ConnectionParametersWithAdditionalAttributes = New Map;
	
	For Each Source In QuerySchema.QueryBatch[0].Operators[0].Sources Do
		If TypeOf(Source.Source) <> Type("QuerySchemaTable")
			Or Source.Source.TableName <> "InformationRegister.OrderStructure" Then
			Continue;
		EndIf;
		
		For Each Join In Source.Joins Do
			If TypeOf(Join.Source.Source) <> Type("QuerySchemaTable")
				Or StrFind(Join.Source.Source.TableName, "AdditionalAttributes") = 0 Then
				Continue;
			EndIf;
			
			NewRow = ConnectionsWithAdditionalAttributes.Add();
			NewRow.TableName = Join.Source.Source.TableName;
			NewRow.Alias = Join.Source.Source.Alias;
			NewRow.Condition = Join.Condition;
			
			CharacterNumber = StrFind(Join.Condition, "&");
			If CharacterNumber <> 0 Then
				ParameterName = Right(Join.Condition, StrLen(Join.Condition) - CharacterNumber);
				For Each Parameter In DataCompositionTemplate.ParameterValues Do
					If Parameter.Name = ParameterName Then
						ConnectionParametersWithAdditionalAttributes.Insert(Parameter.Name, Parameter.Value);
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
		Break;
	EndDo;
	
	CustomFilters = New Structure;
	CustomFilters.Insert("Filters", Filters);
	CustomFilters.Insert("ConnectionsWithAdditionalAttributes", ConnectionsWithAdditionalAttributes);
	CustomFilters.Insert("ConnectionParametersWithAdditionalAttributes", ConnectionParametersWithAdditionalAttributes);
	
	Query.ExecuteBatch();
	
EndProcedure

Function CreateDocumentsDeferredInsideTimeMeasurement(Parameters, StorageAddress)
	
	GeneratingProductionStages.CreateStagesForLaunching(
		Parameters.Groups, Parameters.Products_1, Parameters.PartyKeys, Parameters, StorageAddress);
	
	DataVolume = 0;
	Result = GetFromTempStorage(StorageAddress);
	If TypeOf(Result) = Type("Structure")
		And Result.Property("ResultOfFormation") Then
		DataVolume = Result.ResultOfFormation.Count();
	EndIf;
	
	Return DataVolume;
	
EndFunction

Procedure DeleteObjectsDeferredInsideTimeMeasurement(Parameters, StorageAddress)
	
	For Cnt = 1 To 2 Do
		
		For Each Ref In Parameters.References Do
			
			If Cnt = 1 And TypeOf(Ref) = Type("DocumentRef.ProductionOrder2_2")
				Or Cnt = 2 And TypeOf(Ref) <> Type("DocumentRef.ProductionOrder2_2") Then
				Continue; // Production orders are deleted on the second pass
			EndIf;
			
			Object = Ref.GetObject();
			
			If Object = Undefined Or Object.DeletionMark Then
				Continue;
			EndIf;
			
			Object.Lock();
			
			SetPrivilegedMode(True);
			Object.SetDeletionMark(True);
			SetPrivilegedMode(False);
			
		EndDo;
		
	EndDo;
	
	OrderStructure.StartCalculation();
	
EndProcedure

#EndRegion

#EndIf

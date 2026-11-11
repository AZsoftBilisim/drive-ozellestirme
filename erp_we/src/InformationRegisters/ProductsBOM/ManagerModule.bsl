
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Writes data about products in the specification to the register
//
// Parameters:
//  Specifications  - CatalogRef.BillsOfMaterials, Array - the specification for which items are recorded.
//  ClearingRegisterEntries - Boolean - specifies whether to write data, or only clear existing data in the register
//  CallingFromUpdateHandler - Boolean - call mode from the update handler
//
Procedure WriteProductsAccordingToSpecification(Specifications, ClearingRegisterEntries = False, CallingFromUpdateHandler = False) Export
	
	Var RecordingOfMainFinishedProduct;
	
	Query = New Query;
	Query.Text = QueryTextProductSpecifications(CallingFromUpdateHandler);
	Query.SetParameter("Specifications",     Specifications);
	Query.SetParameter("ReadProducts", Not ClearingRegisterEntries);  
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		SampleSpecification = QueryResult.Select(QueryResultIteration.ByGroups, "BillOfMaterials");
		While SampleSpecification.Next() Do
			
			RecordSet = InformationRegisters.ProductsBOM.CreateRecordSet();
			RecordSet.Filter.BillOfMaterials.Set(SampleSpecification.BillOfMaterials);
			
			Order = 1;
			
			Selection = SampleSpecification.Select(QueryResultIteration.Linear);
			While Selection.Next() And Selection.LineNumber <> Null Do
				
				NewRow = RecordSet.Add();
				FillPropertyValues(NewRow, Selection);
				NewRow.Order = Order;
				
				If Order = 1 Then
					NewRow.NumberOfPackagingUnitsPerStartingLotUnit = Selection.NumberOfPackagesPerStartingLotUnit;
					NewRow.MainProductPackagingUnit = Selection.Package;
					RecordingOfMainFinishedProduct = NewRow;
				Else
					FillPropertyValues(NewRow, RecordingOfMainFinishedProduct, 
						"NumberOfPackagingUnitsPerStartingLotUnit,MainProductPackagingUnit"); // we take from the record of the main finishedproduct
				EndIf;
				
				Order = Order + 1;
				
			EndDo;
			
			If CallingFromUpdateHandler Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				RecordSet.Write();
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure
	
#EndRegion

#Region Private

#Region Other

Function QueryTextProductSpecifications(CallingFromUpdateHandler = False)
	
	QueryText = "
	|// Kittings, R&M, performing Repair work
	|SELECT
	|	T.Ref                                  AS BillOfMaterials,
	|	CASE
	|		WHEN T.Ref.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ProductKind)
	|			THEN T.ProductKind
	|		ELSE ISNULL(T.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef))
	|	END                                     AS ProductKind,
	|	T.Products                            AS Products,
	|	T.Characteristic                          AS Characteristic,
	|	T.NumberOfPackages                      AS NumberOfPackagesPerStartingLotUnit,
	|	T.Package                                AS Package,
	|	T.Ref.ProductionProcessType     AS ProductionProcessType,
	|	T.Ref.Status                           AS Status,
	|	T.Ref.ValidOnDate                   AS ValidOnDate,
	|	T.Ref.ValidToDate                    AS ValidToDate,
	|	T.LineNumber                             AS LineNumber,
	|	T.ConnectionKey                               AS ConnectionKey,
	|	FALSE                                      AS SideExit
	|INTO
	|	TTWares
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS T
	|WHERE
	|	T.Ref IN (&Specifications)
	|	AND T.Ref.ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.Assembly),
	|													VALUE(Enum.ProductionProcessTypes.PerformRM),
	|													VALUE(Enum.ProductionProcessTypes.Repair))
	|	AND T.Ref.Status IN (VALUE(Enum.BOMStatuses.Valid), VALUE(Enum.BOMStatuses.UnderDevelopment))
	|	AND T.MethodOfProductsAutoselection IN (VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData),
	|											VALUE(Enum.MethodsOfProductAutoSelection.EmptyRef))
	|	AND T.MethodOfItemVariantAutoselection IN (VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData),
	|											VALUE(Enum.MethodsOfItemVariantAutoselection.EmptyRef))
	|	AND (CAST(T.QuantityCalculationAlgorithm AS STRING(100))) = """"
	|	AND CASE
	|		WHEN T.Ref.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ProductKind)
	|			THEN T.ProductKind
	|		ELSE ISNULL(T.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef))
	|	END <> VALUE(Catalog.ItemKinds.EmptyRef)
	|	AND (T.LineNumber = 1
	|			OR &SubstitutionTextAttributeCalculationIsResourceParameterization = FALSE)
	|	AND &ReadProducts
	|
	|UNION ALL
	|
	|// Side issue
	|SELECT
	|	SideRelease.BillOfMaterials,
	|	SideRelease.ProductKind,
	|	SideRelease.Products,
	|	SideRelease.Characteristic,
	|	SUM(SideRelease.Count),
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|	SideRelease.ProductionProcessType,
	|	SideRelease.Status,
	|	SideRelease.ValidOnDate,
	|	SideRelease.ValidToDate,
	|	MIN(SideRelease.LineNumber),
	|	MIN(SideRelease.ConnectionKey),
	|	TRUE
	|FROM
	|	(SELECT
	|		T.Ref                              AS BillOfMaterials,
	|		T.Ref.ProductionProcessType AS ProductionProcessType,
	|		T.Ref.Status                       AS Status,
	|		T.Ref.ValidOnDate               AS ValidOnDate,
	|		T.Ref.ValidToDate                AS ValidToDate,
	|		T.Products.ProductKind        AS ProductKind,
	|		T.Products                        AS Products,
	|		T.Characteristic                      AS Characteristic,
	|		T.LineNumber                         AS LineNumber,
	|		T.ConnectionKey                           AS ConnectionKey,
	|		CAST(T.NumberOfPackages * ISNULL(&QueryTextPackagingFactor, 1) AS NUMBER(15, 3)) AS Count
	|	FROM
	|		Catalog.BillsOfMaterials.RecyclableWaste AS T
	|	WHERE
	|		T.Ref IN (&Specifications)
	|		AND T.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Assembly)
	|		AND T.MethodOfProductsAutoselection = VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
	|		AND T.MethodOfItemVariantAutoselection = VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData)
	|		AND (CAST(T.QuantityCalculationAlgorithm AS STRING(100))) = """"
	|		AND &ReadProducts
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.Ref,
	|		T.Ref.ProductionProcessType,
	|		T.Ref.Status,
	|		T.Ref.ValidOnDate,
	|		T.Ref.ValidToDate,
	|		T.Products.ProductKind,
	|		T.Products,
	|		T.Characteristic,
	|		10000,
	|		T.ConnectionKey,
	|		-(CAST(T.NumberOfPackages * ISNULL(&QueryTextPackagingFactor, 1) AS NUMBER(15, 3)))
	|	FROM
	|		Catalog.BillsOfMaterials.MaterialsAndServices AS T
	|	WHERE
	|		T.Ref IN (&Specifications)
	|		AND T.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Assembly)
	|		AND T.MethodOfReceivingMaterial = VALUE(Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage)
	|		AND T.MethodOfProductsAutoselection = VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
	|		AND T.MethodOfItemVariantAutoselection = VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData)
	|		AND (CAST(T.QuantityCalculationAlgorithm AS STRING(100))) = """"
	|		AND &ReadProducts) AS SideRelease
	|
	|GROUP BY
	|	SideRelease.BillOfMaterials,
	|	SideRelease.ProductKind,
	|	SideRelease.Products,
	|	SideRelease.Characteristic,
	|	SideRelease.ProductionProcessType,
	|	SideRelease.Status,
	|	SideRelease.ValidOnDate,
	|	SideRelease.ValidToDate
	|	
	|HAVING
	|	SUM(SideRelease.Count) > 0
	|
	|UNION ALL
	|
	|// Disassembly
	|SELECT
	|	T.Ref,
	|	CASE
	|		WHEN T.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ProductKind)
	|			THEN T.MainProductProductKind
	|		ELSE ISNULL(T.MainProductProducts.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef))
	|	END,
	|	T.MainProductProducts,
	|	T.MainProductCharacteristic,
	|	T.MainProductNumberOfPackages,
	|	T.MainProductPackage,
	|	T.ProductionProcessType,
	|	T.Status,
	|	T.ValidOnDate,
	|	T.ValidToDate,
	|	1,
	|	NULL,
	|	FALSE
	|FROM
	|	Catalog.BillsOfMaterials AS T
	|WHERE
	|	T.Ref IN (&Specifications)
	|	AND T.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|	AND T.Status IN (VALUE(Enum.BOMStatuses.Valid), VALUE(Enum.BOMStatuses.UnderDevelopment))
	|	AND CASE
	|		WHEN T.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ProductKind)
	|			THEN T.MainProductProductKind
	|		ELSE ISNULL(T.MainProductProducts.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef))
	|	END <> VALUE(Catalog.ItemKinds.EmptyRef)
	|	AND &ReadProducts
	|
	|INDEX BY
	|	BillOfMaterials
	|
	|;
	|
	|SELECT
	|	Specifications.Ref AS BillOfMaterials,
	|	Products_1.*
	|FROM
	|	Catalog.BillsOfMaterials AS Specifications
	|
	|		LEFT JOIN TTWares AS Products_1
	|		ON Specifications.Ref = Products_1.BillOfMaterials
	|WHERE
	|	Specifications.Ref IN (&Specifications)
	|	AND NOT TRUE IN (SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTWares AS T
	|				WHERE
	|					Products_1.BillOfMaterials = T.BillOfMaterials
	|					AND Products_1.Products = T.Products
	|					AND Products_1.Characteristic = T.Characteristic
	|					AND CASE
	|						WHEN Products_1.SideExit = T.SideExit
	|							THEN T.LineNumber < Products_1.LineNumber
	|						ELSE T.SideExit < Products_1.SideExit
	|					END)
	|
	|ORDER BY
	|	Products_1.SideExit,
	|	Products_1.LineNumber
	|
	|TOTALS BY
	|	Specifications.Ref
	|
	|";
	
	QueryText = StrReplace(QueryText, "&RequestTextPackingFactorMainProduct",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"T.MainProductPackage",
			"T.MainProductProducts"));
		
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"T.Package",
			"T.Products"));
			
	If CallingFromUpdateHandler Then
		QueryText = StrReplace(QueryText,
			"&SubstitutionTextAttributeCalculationIsResourceParameterization",
			Catalogs.BillsOfMaterials.SubstitutionTextAttributeCalculationIsResourceParameterization("T.Ref"));
	Else
		QueryText = StrReplace(QueryText,
			"&SubstitutionTextAttributeCalculationIsResourceParameterization",
			"T.Ref.ContainsResourcesParametrization");
	EndIf;
			
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

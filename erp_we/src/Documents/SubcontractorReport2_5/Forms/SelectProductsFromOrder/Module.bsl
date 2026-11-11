
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillInTheGoodsTable();
	
	If Not Parameters.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		Items.TableOfGoodsProductionStage.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocumentExecute()
	
	TheStructureOfTheSearch = New Structure("Check", True);
 	StringsList = TableOfGoods.FindRows(TheStructureOfTheSearch);
	
	If StringsList.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn sản phẩm.';
								|ru = 'Необходимо выбрать продукцию.';
								|en = 'Select products.'; fa = 'Select products.';
								|it = 'È necessario selezionare i prodotti.';
								|pl = 'Należy wybrać produkcję.';
								|tr = 'İmal edilen ürünü seçmeniz gerekmektedir.'"));
		Return;
	EndIf;
	
	MoveProductsToDocument();
	
EndProcedure

&AtClient
Procedure ToChooseTheProductsExecute()
	
	SelectAllProductsOnServer(True);
	
EndProcedure

&AtClient
Procedure ExcludeGoodsExecute()
	
	SelectAllProductsOnServer(False);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	#Region StandardAppearance
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisForm, 
		"TableOfGoodsCharacteristic",
		"TableOfGoods.ItemVariantsAreUsed");
																			 
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "TableOfGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "TableOfGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
		
	#EndRegion

	#Region Department

	//Only Review, Text, Text color
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("TableOfGoods.ItemsType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Item.Appearance.SetParameterValue("Text"      , NStr("vi = '<dành cho công việc>';
														|ru = '<для работ>';
														|en = '<for works>'; fa = '<for works>';
														|it = '<per i lavori>';
														|pl = '<dla robót>';
														|tr = '<iş için>'"));
	Item.Appearance.SetParameterValue("TextColor" , StyleColors.InaccessibleCellTextColor);

	#EndRegion
	
	#Region DimensionOfExpenses
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfGoods.ArticleType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region AssetsLiabilitiesDimension
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfGoodsAssetsLiabilitiesDimension.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableOfGoods.ArticleType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 3;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure SelectAllProductsOnServer(SelectionValue)
	
	For Each TableRow In TableOfGoods.FindRows(New Structure("Check", Not SelectionValue)) Do
		
		TableRow.Check = SelectionValue;
		
	EndDo;
	
EndProcedure

&AtClient
Function GetSelectedProducts()
	
	FillingData = New Array;
	
	For Each CurrentData In TableOfGoods Do
		
		If Not CurrentData.Check Then
			Continue;
		EndIf;
		
		ProductionData = New Structure(
			"Products,
			|Characteristic,
			|Purpose,
			|Recipient,
			|RowCode,
			|Package,
			|CostType,
			|CostGroupNumber,
			|ProductionStage,
			|Count,
			|Price,
			|Sum,
			|ProductCostElement,
			|BillOfMaterials,
			|CostShare,
			|CostSharePerUnit,
			|ToExpenseAs,
			|ExpenseItem,
			|ArticleType,
			|DimensionOfExpenses,
			|AssetsLiabilitiesDimension");
			
		FillPropertyValues(ProductionData, CurrentData);
		FillingData.Add(ProductionData);
		
	EndDo; 
	
	Return FillingData;
	
EndFunction

&AtServer
Procedure FillInTheGoodsTable()
	
	QueryTexts = New Array;
	
	Filter = New Map;
	TMCommonUse.AddSelectionItemToCollection(Filter, "PurchaseOrder", "&OrderDocument");
	TMCommonUse.AddSelectionItemToCollection(Filter, "NOT RowCode = 0", "TRUE", "=");
	
	QueryTexts.Add(
		AccumulationRegisters.PurchaseOrders.QueryTextBalance("ProductsToBeProcessedByOrder", Filter, "ToRegister > 0"));
	
	Filter = New Map;
	TMCommonUse.AddSelectionItemToCollection(Filter, "PurchaseOrder", "&OrderDocument");
	QueryTexts.Add(
		Documents.SubcontractorReport2_5.TextOfRequestProductsOverOrderToCheckout("ProductsToBePlacedInExcessOfOrder", Filter));
	
	QueryText =
	"SELECT
	|	TabularSection.SubcontractOrder AS SubcontractOrder,
	|	TabularSection.RowCode          AS RowCode,
	|	TabularSection.Products       AS Products,
	|	TabularSection.Characteristic     AS Characteristic,
	|	TabularSection.Count         AS Count
	|INTO ManufacturedProducts
	|FROM
	|	&ManufacturedProducts AS TabularSection";
	QueryTexts.Add(QueryText);
	
	QueryText =
	"SELECT
	|	TabularSection.SubcontractOrder AS SubcontractOrder,
	|	TabularSection.RowCode          AS RowCode,
	|	TabularSection.Products       AS Products,
	|	TabularSection.Characteristic     AS Characteristic,
	|	TabularSection.Count         AS Count
	|INTO SideAndIntermediateRelease
	|FROM
	|	&SideAndIntermediateRelease AS TabularSection";
	QueryTexts.Add(QueryText);
	
	QueryText =
	"SELECT
	|	PurchaseOrders.ReferenceOrder       AS ReferenceOrder,
	|	PurchaseOrders.RowCode          AS RowCode,
	|	PurchaseOrders.Products       AS Products,
	|	PurchaseOrders.Characteristic     AS Characteristic,
	|	SUM(PurchaseOrders.Ordered)    AS Ordered,
	|	SUM(PurchaseOrders.ToRegister) AS ToRegister
	|INTO RequirementsForRegistration__
	|FROM 
	|	(SELECT
	|		ProductsToBeProcessedByOrder.PurchaseOrder      AS ReferenceOrder,
	|		ProductsToBeProcessedByOrder.RowCode            AS RowCode,
	|		ProductsToBeProcessedByOrder.Products         AS Products,
	|		ProductsToBeProcessedByOrder.Characteristic       AS Characteristic,
	|		0                                              AS Ordered,
	|		ProductsToBeProcessedByOrder.ToRegister          AS ToRegister
	|	FROM
	|		ProductsToBeProcessedByOrder AS ProductsToBeProcessedByOrder
	|		
	|		LEFT JOIN Document.SubcontractOrder2_5.Services AS OrderingServices
	|		ON OrderingServices.Ref = ProductsToBeProcessedByOrder.PurchaseOrder
	|		AND OrderingServices.RowCode = ProductsToBeProcessedByOrder.RowCode
	|		
	|	WHERE
	|		OrderingServices.Ref IS NULL
	|
	|	UNION ALL
	|	
	|	SELECT
	|		ProductsToBePlacedInExcessOfOrder.PurchaseOrder AS ReferenceOrder,
	|		0                                            AS RowCode,
	|		ProductsToBePlacedInExcessOfOrder.Products    AS Products,
	|		ProductsToBePlacedInExcessOfOrder.Characteristic  AS Characteristic,
	|		0                                            AS Ordered,
	|		ProductsToBePlacedInExcessOfOrder.ToRegister     AS ToRegister
	|	FROM
	|		ProductsToBePlacedInExcessOfOrder AS ProductsToBePlacedInExcessOfOrder
	|
	|	UNION ALL
	|
	|	SELECT
	|		ProductsOrdered_.PurchaseOrder                 AS ReferenceOrder,
	|		ProductsOrdered_.RowCode                       AS RowCode,
	|		ProductsOrdered_.Products                    AS Products,
	|		ProductsOrdered_.Characteristic                  AS Characteristic,
	|		ProductsOrdered_.OrderedReceipt                  AS Ordered,
	|		0                                              AS ToRegister
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Turnovers(,,,
	|			(PurchaseOrder, RowCode) IN
	|				(SELECT
	|					ProductsToBeProcessedByOrder.PurchaseOrder,
	|					ProductsToBeProcessedByOrder.RowCode
	|				FROM
	|					ProductsToBeProcessedByOrder)) AS ProductsOrdered_
	|		
	|		LEFT JOIN Document.SubcontractOrder2_5.Services AS OrderingServices
	|		ON OrderingServices.Ref = ProductsOrdered_.PurchaseOrder
	|		AND OrderingServices.RowCode = ProductsOrdered_.RowCode
	|		
	|	WHERE
	|		OrderingServices.Ref IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TabularSection.SubcontractOrder              AS ReferenceOrder,
	|		TabularSection.RowCode                       AS RowCode,
	|		TabularSection.Products                    AS Products,
	|		TabularSection.Characteristic                  AS Characteristic,
	|		0                                              AS Ordered,
	|		-TabularSection.Count                     AS ToRegister
	|	FROM
	|		ManufacturedProducts AS TabularSection
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TabularSection.SubcontractOrder              AS ReferenceOrder,
	|		TabularSection.RowCode                       AS RowCode,
	|		TabularSection.Products                    AS Products,
	|		TabularSection.Characteristic                  AS Characteristic,
	|		0                                              AS Ordered,
	|		-TabularSection.Count                     AS ToRegister
	|	FROM
	|		SideAndIntermediateRelease AS TabularSection
	|
	|	) AS PurchaseOrders
	|
	|GROUP BY
	|	PurchaseOrders.ReferenceOrder,
	|	PurchaseOrders.RowCode,
	|	PurchaseOrders.Products,
	|	PurchaseOrders.Characteristic
	|
	|HAVING
	|	SUM(PurchaseOrders.ToRegister) > 0
	|
	|INDEX BY
	|	ReferenceOrder,
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Output products of the order to the processor
	|SELECT ALLOWED
	|	ProductItemTable.LineNumber                                         AS Order,
	|	VALUE(Document.ProductionStage2_2.EmptyRef)                AS ReferenceOrder,
	|	RequirementsForRegistration__.RowCode                                       AS RowCode,
	|	RequirementsForRegistration__.Products                                    AS Products,
	|	RequirementsForRegistration__.Characteristic                                  AS Characteristic,
	|	RequirementsForRegistration__.Products.ItemsType                    AS ItemsType,
	|	ProductItemTable.Purpose                                          AS Purpose,
	|	ProductItemTable.Recipient                                          AS Recipient,
	|	ProductItemTable.BillOfMaterials                                        AS BillOfMaterials,
	|	ProductItemTable.Package                                            AS Package,
	|	CASE
	|		WHEN ProductItemTable.Count > 0
	|			AND CAST(RequirementsForRegistration__.ReferenceOrder AS Document.SubcontractOrder2_5).MethodOfAllocatingFinishedProductCosts
	|				= VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares)
	|			THEN RequirementsForRegistration__.Ordered
	|					* ProductItemTable.CostShare
	|					/ ProductItemTable.Count
	|		ELSE RequirementsForRegistration__.Ordered
	|				* ISNULL(ProductItemTable.CostSharePerUnit, 0)
	|	END                                                              AS CostShare,
	|	ProductItemTable.CostSharePerUnit                              AS CostSharePerUnit,
	|	ProductItemTable.CostGroupNumber                                   AS CostGroupNumber,
	|	VALUE(Catalog.ProductCostElements.EmptyRef)                AS ProductCostElement,
	|	VALUE(Document.ProductionStage2_2.EmptyRef)                AS ProductionStage,
	|	VALUE(Enum.CostTypesOfFinishedProducts.Calculating) AS CostType,
	|	0                                                                  AS Price,
	|	0                                                                  AS Sum,
	|	RequirementsForRegistration__.ToRegister                                     AS Count,
	|	RequirementsForRegistration__.Ordered                                        AS Ordered,
	|	RequirementsForRegistration__.ToRegister
	|		/ ISNULL(&QueryTextPackagingFactor, 1)                AS NumberOfPackages,
	|	RequirementsForRegistration__.Ordered
	|		/ ISNULL(&QueryTextPackagingFactor, 1)                AS PackagesOrdered,
	|	CASE
	|		WHEN RequirementsForRegistration__.Products.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), 
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), 
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                              AS ItemVariantsAreUsed,
	|	CAST(RequirementsForRegistration__.ReferenceOrder AS Document.SubcontractOrder2_5).Number   AS TheNumberOfTheOrder,
	|	CAST(RequirementsForRegistration__.ReferenceOrder AS Document.SubcontractOrder2_5).Date    AS ReferenceDate,
	|	ProductItemTable.ToExpenseAs                                    AS ToExpenseAs,
	|	ProductItemTable.ExpenseItem                                      AS ExpenseItem,
	|	CASE
	|		WHEN VALUETYPE(ProductItemTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN 1
	|		WHEN VALUETYPE(ProductItemTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN 3
	|		ELSE 0
	|	END                                                              AS ArticleType,
	|	ProductItemTable.DimensionOfExpenses                                   AS DimensionOfExpenses,
	|	ProductItemTable.AssetsLiabilitiesDimension                            AS AssetsLiabilitiesDimension
	|FROM
	|	RequirementsForRegistration__ AS RequirementsForRegistration__
	|
	|	INNER JOIN Document.SubcontractOrder2_5.ManufacturedProducts AS ProductItemTable
	|	ON ProductItemTable.Ref = RequirementsForRegistration__.ReferenceOrder
	|	AND ProductItemTable.RowCode = RequirementsForRegistration__.RowCode
	|
	|WHERE
	|	NOT &OnlyByProducts
	|
	|UNION ALL
	|
	// By-products of the order to the processor
	|SELECT
	|	ProductItemTable.LineNumber                                        AS Order,
	|	VALUE(Document.ProductionStage2_2.EmptyRef)               AS ReferenceOrder,
	|	RequirementsForRegistration__.RowCode                                      AS RowCode,
	|	RequirementsForRegistration__.Products                                   AS Products,
	|	RequirementsForRegistration__.Characteristic                                 AS Characteristic,
	|	RequirementsForRegistration__.Products.ItemsType                   AS ItemsType,
	|	ProductItemTable.Purpose                                         AS Purpose,
	|	ProductItemTable.Recipient                                         AS Recipient,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)           AS BillOfMaterials,
	|	ProductItemTable.Package                                           AS Package,
	|	0                                                                 AS CostShare,
	|	0                                                                 AS CostSharePerUnit,
	|	ProductItemTable.CostGroupNumber                                  AS CostGroupNumber,
	|	ProductItemTable.ProductCostElement                                  AS ProductCostElement,
	|	VALUE(Document.ProductionStage2_2.EmptyRef)               AS ProductionStage,
	|	VALUE(Enum.CostTypesOfFinishedProducts.Fixed) AS CostType,
	|	ProductItemTable.Price                                               AS Price,
	|	ProductItemTable.Sum                                              AS Sum,
	|	RequirementsForRegistration__.ToRegister                                    AS Count,
	|	RequirementsForRegistration__.Ordered                                       AS Ordered,
	|	RequirementsForRegistration__.ToRegister
	|		/ ISNULL(&QueryTextPackagingFactor, 1)               AS NumberOfPackages,
	|	RequirementsForRegistration__.Ordered
	|		/ ISNULL(&QueryTextPackagingFactor, 1)               AS PackagesOrdered,
	|	CASE
	|		WHEN RequirementsForRegistration__.Products.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), 
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), 
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                             AS ItemVariantsAreUsed,
	|	CAST(RequirementsForRegistration__.ReferenceOrder AS Document.SubcontractOrder2_5).Number   AS TheNumberOfTheOrder,
	|	CAST(RequirementsForRegistration__.ReferenceOrder AS Document.SubcontractOrder2_5).Date    AS ReferenceDate,
	|	ProductItemTable.ToExpenseAs                                   AS ToExpenseAs,
	|	ProductItemTable.ExpenseItem                                     AS ExpenseItem,
	|	CASE
	|		WHEN VALUETYPE(ProductItemTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN 1
	|		WHEN VALUETYPE(ProductItemTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN 3
	|		ELSE 0
	|	END                                                             AS ArticleType,
	|	ProductItemTable.DimensionOfExpenses                                  AS DimensionOfExpenses,
	|	ProductItemTable.AssetsLiabilitiesDimension                           AS AssetsLiabilitiesDimension
	|FROM
	|	RequirementsForRegistration__ AS RequirementsForRegistration__
	|
	|	INNER JOIN Document.SubcontractOrder2_5.SideAndIntermediateRelease AS ProductItemTable
	|	ON ProductItemTable.Ref = RequirementsForRegistration__.ReferenceOrder
	|	AND ProductItemTable.RowCode = RequirementsForRegistration__.RowCode
	|
	|UNION ALL
	|
	// Output products of the production stages
	|SELECT
	|	ProductItemTable.LineNumber                                         AS Order,
	|	ProductItemTable.Ref                                              AS ReferenceOrder,
	|	RequirementsForRegistration__.RowCode                                       AS RowCode,
	|	RequirementsForRegistration__.Products                                    AS Products,
	|	RequirementsForRegistration__.Characteristic                                  AS Characteristic,
	|	RequirementsForRegistration__.Products.ItemsType                    AS ItemsType,
	|	ProductItemTable.Purpose                                          AS Purpose,
	|	ProductItemTable.Recipient                                          AS Recipient,
	|	ProductItemTable.Ref.BillOfMaterials                                 AS BillOfMaterials,
	|	ProductItemTable.Package                                            AS Package,
	|	CASE
	|		WHEN ProductItemTable.Count > 0
	|			AND ProductItemTable.Ref.MethodOfAllocatingFinishedProductCosts
	|				= VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares) 
	|			THEN RequirementsForRegistration__.Ordered
	|					* ProductItemTable.CostShare
	|					/ ProductItemTable.Count
	|		ELSE RequirementsForRegistration__.Ordered
	|				* ISNULL(ProductItemTable.CostSharePerUnit, 0)
	|	END                                                              AS CostShare,
	|	ProductItemTable.CostSharePerUnit                              AS CostSharePerUnit,
	|	DisposalTable.CostGroupNumber                              AS CostGroupNumber,
	|	VALUE(Catalog.ProductCostElements.EmptyRef)                AS ProductCostElement,
	|	ProductItemTable.Ref                                              AS ProductionStage,
	|	VALUE(Enum.CostTypesOfFinishedProducts.Calculating) AS CostType,
	|	0                                                                  AS Price,
	|	0                                                                  AS Sum,
	|	RequirementsForRegistration__.ToRegister                                     AS Count,
	|	RequirementsForRegistration__.Ordered                                        AS Ordered,
	|	RequirementsForRegistration__.ToRegister
	|		/ ISNULL(&QueryTextPackagingFactor, 1)                AS NumberOfPackages,
	|	RequirementsForRegistration__.Ordered
	|		/ ISNULL(&QueryTextPackagingFactor, 1)                AS PackagesOrdered,
	|	CASE
	|		WHEN RequirementsForRegistration__.Products.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                              AS ItemVariantsAreUsed,
	|	CAST(RequirementsForRegistration__.ReferenceOrder AS Document.SubcontractOrder2_5).Number AS TheNumberOfTheOrder,
	|	CAST(RequirementsForRegistration__.ReferenceOrder AS Document.SubcontractOrder2_5).Date AS ReferenceDate,
	|	ProductItemTable.ToExpenseAs                                    AS ToExpenseAs,
	|	ProductItemTable.ExpenseItem                                      AS ExpenseItem,
	|	CASE
	|		WHEN VALUETYPE(ProductItemTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN 1
	|		WHEN VALUETYPE(ProductItemTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN 3
	|		ELSE 0
	|	END                                                              AS ArticleType,
	|	ProductItemTable.DimensionOfExpenses                                   AS DimensionOfExpenses,
	|	ProductItemTable.AssetsLiabilitiesDimension                            AS AssetsLiabilitiesDimension
	|FROM
	|	RequirementsForRegistration__ AS RequirementsForRegistration__
	|
	|	INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS ProductItemTable
	|	ON ProductItemTable.Ref.SubcontractOrder = RequirementsForRegistration__.ReferenceOrder
	|	AND ProductItemTable.RowCode = RequirementsForRegistration__.RowCode
	|
	|	INNER JOIN Document.SubcontractOrder2_5.References AS DisposalTable
	|	ON DisposalTable.Ref = RequirementsForRegistration__.ReferenceOrder
	|	AND DisposalTable.ReferenceOrder = ProductItemTable.Ref
	|
	|WHERE
	|	NOT &OnlyByProducts
	|
	|UNION ALL
	|
	// By-products of the production stage
	|SELECT
	|	ProductItemTable.LineNumber                                        AS Order,
	|	ProductItemTable.Ref                                             AS ReferenceOrder,
	|	RequirementsForRegistration__.RowCode                                      AS RowCode,
	|	RequirementsForRegistration__.Products                                   AS Products,
	|	RequirementsForRegistration__.Characteristic                                 AS Characteristic,
	|	RequirementsForRegistration__.Products.ItemsType                   AS ItemsType,
	|	ProductItemTable.Purpose                                         AS Purpose,
	|	ProductItemTable.Recipient                                         AS Recipient,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)           AS BillOfMaterials,
	|	ProductItemTable.Package                                           AS Package,
	|	0                                                                 AS CostShare,
	|	0                                                                 AS CostSharePerUnit,
	|	DisposalTable.CostGroupNumber                             AS CostGroupNumber,
	|	ProductItemTable.ProductCostElement                                  AS ProductCostElement,
	|	ProductItemTable.Ref                                             AS ProductionStage,
	|	VALUE(Enum.CostTypesOfFinishedProducts.Fixed) AS CostType,
	|	ProductItemTable.Price                                               AS Price,
	|	ProductItemTable.Sum                                              AS Sum,
	|	RequirementsForRegistration__.ToRegister                                    AS Count,
	|	RequirementsForRegistration__.Ordered                                       AS Ordered,
	|	RequirementsForRegistration__.ToRegister
	|		/ ISNULL(&QueryTextPackagingFactor, 1)               AS NumberOfPackages,
	|	RequirementsForRegistration__.Ordered
	|		/ ISNULL(&QueryTextPackagingFactor, 1)               AS PackagesOrdered,
	|	CASE
	|		WHEN RequirementsForRegistration__.Products.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), 
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), 
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                             AS ItemVariantsAreUsed,
	|	CAST(RequirementsForRegistration__.ReferenceOrder AS Document.SubcontractOrder2_5).Number   AS TheNumberOfTheOrder,
	|	CAST(RequirementsForRegistration__.ReferenceOrder AS Document.SubcontractOrder2_5).Date    AS ReferenceDate,
	|	ProductItemTable.ToExpenseAs                                   AS ToExpenseAs,
	|	ProductItemTable.ExpenseItem                                     AS ExpenseItem,
	|	CASE
	|		WHEN VALUETYPE(ProductItemTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN 1
	|		WHEN VALUETYPE(ProductItemTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN 3
	|		ELSE 0
	|	END                                                             AS ArticleType,
	|	ProductItemTable.DimensionOfExpenses                                  AS DimensionOfExpenses,
	|	ProductItemTable.AssetsLiabilitiesDimension                           AS AssetsLiabilitiesDimension
	|FROM
	|	RequirementsForRegistration__ AS RequirementsForRegistration__
	|
	|	INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS ProductItemTable
	|	ON ProductItemTable.Ref.SubcontractOrder = RequirementsForRegistration__.ReferenceOrder
	|	AND ProductItemTable.RowCode = RequirementsForRegistration__.RowCode
	|
	|	INNER JOIN Document.SubcontractOrder2_5.References AS DisposalTable
	|	ON DisposalTable.Ref = RequirementsForRegistration__.ReferenceOrder
	|	AND DisposalTable.ReferenceOrder = ProductItemTable.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED                                                      AS Order,
	|	RequirementsForRegistration__.ReferenceOrder                                   AS ReferenceOrder,
	|	RequirementsForRegistration__.RowCode                                      AS RowCode,
	|	RequirementsForRegistration__.Products                                   AS Products,
	|	RequirementsForRegistration__.Characteristic                                 AS Characteristic,
	|	RequirementsForRegistration__.Products.ItemsType                   AS ItemsType,
	|	VALUE(Catalog.Assignments.EmptyRef)                      AS Purpose,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)            AS Recipient,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)           AS BillOfMaterials,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)        AS Package,
	|	0                                                                 AS CostShare,
	|	0                                                                 AS CostSharePerUnit,
	|	0                                                                 AS CostGroupNumber,
	|	VALUE(Catalog.ProductCostElements.EmptyRef)               AS ProductCostElement,
	|	UNDEFINED                                                      AS ProductionStage,
	|	VALUE(Enum.CostTypesOfFinishedProducts.Fixed) AS CostType,
	|	0                                                                 AS Price,
	|	0                                                                 AS Sum,
	|	RequirementsForRegistration__.ToRegister                                    AS Count,
	|	RequirementsForRegistration__.Ordered                                       AS Ordered,
	|	RequirementsForRegistration__.ToRegister                                    AS NumberOfPackages,
	|	RequirementsForRegistration__.Ordered                                       AS PackagesOrdered,
	|	CASE
	|		WHEN RequirementsForRegistration__.Products.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), 
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), 
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                             AS ItemVariantsAreUsed,
	|	CAST(RequirementsForRegistration__.ReferenceOrder AS Document.SubcontractOrder2_5).Number AS TheNumberOfTheOrder,
	|	CAST(RequirementsForRegistration__.ReferenceOrder AS Document.SubcontractOrder2_5).Date  AS ReferenceDate,
	|	FALSE                                                              AS ToExpenseAs,
	|	UNDEFINED                                                      AS ExpenseItem,
	|	0                                                                 AS ArticleType,
	|	UNDEFINED                                                      AS DimensionOfExpenses,
	|	UNDEFINED                                                      AS AssetsLiabilitiesDimension
	|FROM
	|	RequirementsForRegistration__ AS RequirementsForRegistration__
	|WHERE
	|	RequirementsForRegistration__.RowCode = 0
	|
	|ORDER BY
	|	ReferenceDate,
	|	TheNumberOfTheOrder,
	|	ReferenceOrder,
	|	Order";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductItemTable.Package",
		"ProductItemTable.Products"));
	
	QueryTexts.Add(QueryText);
	
	Query = New Query;
	If TMCommonUse.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("OrderDocument" ,                Parameters.OrderDocument);
	Query.SetParameter("Recorder",           Parameters.SubcontractorReport);
	Query.SetParameter("ManufacturedProducts",       GetFromTempStorage(Parameters.TabularSections.ManufacturedProducts));
	Query.SetParameter("SideAndIntermediateRelease",       GetFromTempStorage(Parameters.TabularSections.SideAndIntermediateRelease));
	Query.SetParameter("OnlyByProducts", Parameters.OnlyByProducts);
	
	TableOfGoods.Load(Query.Execute().Unload());
	
EndProcedure

&AtClient
Procedure MoveProductsToDocument()
	
	FillingData = GetSelectedProducts();
	
	Close(FillingData);
	
EndProcedure

#EndRegion

#EndRegion

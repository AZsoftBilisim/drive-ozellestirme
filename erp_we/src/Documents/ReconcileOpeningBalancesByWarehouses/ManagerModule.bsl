#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region FillingInTabularPartsOfReconciliationDocument

// Fills in the "reconciliation Results" table part of the passed object.
//
//	Parameters:
//		Object - DocumentObject.ReconcileOpeningBalancesByWarehouses - object to fill in the table part of.
//
Procedure FillInResultsTable(Object) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("EndOfPeriod",			New Boundary(EndOfMonth(Object.Date), BoundaryType.Including));
	Query.SetParameter("Organization",			Object.Organization);
	Query.SetParameter("Warehouse",					Object.Warehouse);
	Query.SetParameter("SpecifyTargets",	Object.SpecifyTargets);
	Query.SetParameter("Table",				Object.ExternalSystemData.Unload());
	
	Query.Text =
	"SELECT
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	T.ItemsLocationAttributes.Series AS Series,
	|	CASE WHEN &SpecifyTargets
	|		THEN T.ItemsLocationAttributes.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.CCDNumber AS CCDNumber,
	|	T.CountBalance AS Count
	|INTO TTBalance
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|			&EndOfPeriod,
	|			Organization = &Organization
	|				AND ItemsLocationAttributes.StorageLocation = &Warehouse) AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	T.Series AS Series,
	|	CASE WHEN &SpecifyTargets
	|		THEN T.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	T.Package AS Package,
	|	T.QuantityExternal AS QuantityExternal,
	|	T.ExternalCostMan AS ExternalCostMan,
	|	T.ExternalCostLocal AS ExternalCostLocal,
	|	T.ExternalCostTA AS ExternalCostTA,
	|	T.ExternalCostPD AS ExternalCostPD,
	|	T.ExternalCostTD AS ExternalCostTD
	|INTO TTBalancesExternal
	|FROM
	|	&Table AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ExternalData AS ExternalData,
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	T.Series AS Series,
	|	T.Purpose AS Purpose,
	|	T.Package AS Package,
	|	T.PackagingFactor AS PackagingFactor,
	|	SUM(T.Count) AS Count,
	|	SUM(T.CostMan) AS CostMan,
	|	SUM(T.LocalCost) AS LocalCost,
	|	SUM(T.CostInTaxAccounting) AS CostInTaxAccounting,
	|	SUM(T.CostPermanentDifference) AS CostPermanentDifference,
	|	SUM(T.CostTemporaryDifference) AS CostTemporaryDifference,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.CCDNumber AS CCDNumber
	|FROM
	|	(SELECT
	|		TRUE AS ExternalData,
	|		T.Products AS Products,
	|		T.Characteristic AS Characteristic,
	|		T.Series AS Series,
	|		T.Purpose AS Purpose,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		ISNULL(Packages.Numerator, 1) / ISNULL(Packages.Denominator, 1) AS PackagingFactor,
	|		CAST(T.QuantityExternal * ISNULL(Packages.Numerator, 1) / ISNULL(Packages.Denominator, 1) AS NUMBER (15, 3)) AS Count,
	|		T.ExternalCostMan AS CostMan,
	|		T.ExternalCostLocal AS LocalCost,
	|		T.ExternalCostTA AS CostInTaxAccounting,
	|		T.ExternalCostPD AS CostPermanentDifference,
	|		T.ExternalCostTD AS CostTemporaryDifference,
	|		VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|		VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|		VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber
	|	FROM
	|		TTBalancesExternal AS T
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|			ON T.Package = Packages.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		FALSE,
	|		T.Products,
	|		T.Characteristic,
	|		T.Series,
	|		T.Purpose,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|		1,
	|		T.Count,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		T.ItemsLocationAttributes,
	|		T.InventoryOwnerAttribute,
	|		T.CCDNumber
	|	FROM
	|		TTBalance AS T) AS T
	|
	|GROUP BY
	|	T.ExternalData,
	|	T.Products,
	|	T.Characteristic,
	|	T.Series,
	|	T.Purpose,
	|	T.Package,
	|	T.PackagingFactor,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.CCDNumber
	|
	|ORDER BY
	|	T.Products,
	|	T.Characteristic,
	|	T.Series,
	|	T.Purpose,
	|	T.ExternalData DESC,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.CCDNumber";
	
	Selection = Query.Execute().Select();
	
	MappingFields = New Structure("Products, Characteristic, Series, Purpose");
	DistributionFields = New Structure("CostMan, LocalCost, CostInTaxAccounting, CostPermanentDifference, CostTemporaryDifference");
	PriceFields 		  = New Structure("CostMan, LocalCost, CostInTaxAccounting, CostPermanentDifference, CostTemporaryDifference, Count");
	CountBalance = 0;
	
	Object.ReconciliationResults.Clear();
	
	While Selection.Next() Do
		
		If MappingFields.Products <> Selection.Products
		 Or MappingFields.Characteristic <> Selection.Characteristic
		 Or MappingFields.Series <> Selection.Series
		 Or MappingFields.Purpose <> Selection.Purpose Then
			
			If CountBalance <> 0 Then
				
				// Let's add the unallocated remnants of the external system to the results table.
				NewRow = Object.ReconciliationResults.Add();
				FillPropertyValues(NewRow, MappingFields);
				FillPropertyValues(NewRow, DistributionFields);
				
				FillInQuantitiesInResultTableRow(Object, NewRow, CountBalance, 0);
				
			EndIf;
			
			// This is a new distribution.
			FillPropertyValues(MappingFields, Selection);
			FillPropertyValues(DistributionFields, Selection);
			FillPropertyValues(PriceFields, 			Selection);
			CountBalance = Selection.Count;
			
			If Not Selection.ExternalData Then
				
				// Let's add the leftovers of the organizations' goods (without any leftovers in the external system).
				NewRow = Object.ReconciliationResults.Add();
				FillPropertyValues(NewRow, Selection);
				
				FillInQuantitiesInResultTableRow(Object, NewRow, 0, Selection.Count);
				
				MappingFields.Products = Undefined; // the next row of the selection must not match this row
				CountBalance = 0;
				
			EndIf;
			
			Continue;
			
		EndIf;
		
		If CountBalance = 0 Then
			
			// There are more organizations in the remaining goods than in the external system.
			NewRow = Object.ReconciliationResults.Add();
			FillPropertyValues(NewRow, Selection);
			
			If Object.QuantityFromOM Then
				
				// Fill in the amounts for the price from the external system.
				For Each KeyAndValue In DistributionFields Do
					NewRow[KeyAndValue.Key] = Round(Selection.Count * PriceFields[KeyAndValue.Key] / PriceFields.Count, 2);
				EndDo;
				
			EndIf;
			
			FillInQuantitiesInResultTableRow(Object, NewRow, 0, Selection.Count);
			
		Else
			
			// There is a residue both in the external system and in the goods of organizations.
			NumberOfDebits = Min(CountBalance, Selection.Count);
			
			NewRow = Object.ReconciliationResults.Add();
			FillPropertyValues(NewRow, Selection);
			
			For Each KeyAndValue In DistributionFields Do
				
				DebitedAmount = Round(DistributionFields[KeyAndValue.Key] * NumberOfDebits / CountBalance, 2);
				DistributionFields[KeyAndValue.Key] = DistributionFields[KeyAndValue.Key] - DebitedAmount;
				
				If Object.QuantityFromOM And NumberOfDebits <> Selection.Count Then
					// If the balance of the organizations' goods is greater than in the external system, then we will fill in the amounts at the price from the external system.
					NewRow[KeyAndValue.Key] = Round(Selection.Count * PriceFields[KeyAndValue.Key] / PriceFields.Count, 2);
				Else
					NewRow[KeyAndValue.Key] = DebitedAmount;
				EndIf;
				
			EndDo;
			
			FillInQuantitiesInResultTableRow(Object, NewRow, NumberOfDebits, Selection.Count);
			
			CountBalance = CountBalance - NumberOfDebits;
			
		EndIf;
		
	EndDo;
	
	If CountBalance <> 0 Then
		
		// Let's add the unallocated remnants of the external system to the results table.
		NewRow = Object.ReconciliationResults.Add();
		FillPropertyValues(NewRow, MappingFields);
		FillPropertyValues(NewRow, DistributionFields);
		
		FillInQuantitiesInResultTableRow(Object, NewRow, CountBalance, 0);
		
	EndIf;
	
	FillInProductTrackingForm(Object);
	FillStockTypes(Object);
	FillInStatusesForSpecifyingSeries(Object);
	
	ResultsTable = Object.ReconciliationResults.Unload();
	ResultsTable.GroupBy(
		"Products, Characteristic, Series, BatchesIndicationStatus, Purpose, Package, ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber",
		"QuantityExternal, NumberOfPackages, Count, NumberOfPackagesDiscrepancy, DeviationInStorageUnits,
			|CostMan, LocalCost, CostInTaxAccounting, CostPermanentDifference, CostTemporaryDifference");
	
	ResultsTable.Sort(
		"Products, Characteristic, Series, BatchesIndicationStatus, Purpose, Package, ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber");
	
	Object.ReconciliationResults.Load(ResultsTable);
	
	Object.RefillResults = False;
	
EndProcedure

// Maps external system IDs to internal object references in the external system Data tabular section.
//
//	Parameters:
//		Object - DocumentObject.ReconcileOpeningBalancesByWarehouses - the object for which you want to perform the mapping.
//
Procedure CompareExternalSystemProducts(Object) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("Ref",					Object.Ref);
	Query.SetParameter("SpecifyTargets",	Object.SpecifyTargets);
	Query.SetParameter("Table",
		Object.ExternalSystemData.Unload(,
			"LineNumber, ExternalCode, ExternalItemID, ExternalName, ExternalUnitOfMeasure, ExternalAssignment, Products"));
	
	Query.Text =
	"SELECT
	|	T.LineNumber AS LineNumber,
	|	T.ExternalCode AS ExternalCode,
	|	T.ExternalItemID AS ExternalItemID,
	|	T.ExternalName AS ExternalName,
	|	T.ExternalUnitOfMeasure AS ExternalUnitOfMeasure,
	|	CASE WHEN &SpecifyTargets
	|		THEN T.ExternalAssignment
	|		ELSE """"
	|	END AS ExternalAssignment
	|INTO TTCurDocument
	|FROM
	|	&Table AS T
	|WHERE
	|	T.Products = VALUE(Catalog.Products.EmptyRef)
	|
	|INDEX BY
	|	ExternalCode,
	|	ExternalItemID,
	|	ExternalName,
	|	ExternalUnitOfMeasure,
	|	ExternalAssignment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.ExternalCode AS ExternalCode,
	|	T.ExternalItemID AS ExternalItemID,
	|	T.ExternalName AS ExternalName,
	|	T.ExternalUnitOfMeasure AS ExternalUnitOfMeasure,
	|	CASE WHEN &SpecifyTargets
	|		THEN T.ExternalAssignment
	|		ELSE """"
	|	END AS ExternalAssignment,
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	T.Series AS Series,
	|	T.Purpose AS Purpose,
	|	T.Package AS Package,
	|	1 AS Count
	|INTO TTOtherDocuments
	|FROM
	|	Document.ReconcileOpeningBalancesByWarehouses.ExternalSystemData AS T
	|WHERE
	|	T.Ref <> &Ref
	|	AND T.Products <> VALUE(Catalog.Products.EmptyRef)
	|
	|INDEX BY
	|	ExternalCode,
	|	ExternalItemID,
	|	ExternalName,
	|	ExternalUnitOfMeasure,
	|	ExternalAssignment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrentDocument.LineNumber AS LineNumber,
	|	OtherDocuments.Products AS Products,
	|	OtherDocuments.Characteristic AS Characteristic,
	|	OtherDocuments.Series AS Series,
	|	OtherDocuments.Purpose AS Purpose,
	|	OtherDocuments.Package AS Package
	|FROM
	|	TTCurDocument AS CurrentDocument
	|		LEFT JOIN TTOtherDocuments AS OtherDocuments
	|		ON CurrentDocument.ExternalCode = OtherDocuments.ExternalCode
	|			AND CurrentDocument.ExternalItemID = OtherDocuments.ExternalItemID
	|			AND CurrentDocument.ExternalName = OtherDocuments.ExternalName
	|			AND CurrentDocument.ExternalUnitOfMeasure = OtherDocuments.ExternalUnitOfMeasure
	|			AND CurrentDocument.ExternalAssignment = OtherDocuments.ExternalAssignment
	|WHERE
	|	OtherDocuments.ExternalCode IS NOT NULL 
	|
	|GROUP BY
	|	CurrentDocument.LineNumber,
	|	OtherDocuments.Products,
	|	OtherDocuments.Characteristic,
	|	OtherDocuments.Series,
	|	OtherDocuments.Purpose,
	|	OtherDocuments.Package
	|
	|HAVING
	|	SUM(ISNULL(OtherDocuments.Count, 0)) = 1";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		FillPropertyValues(Object.ExternalSystemData[Selection.LineNumber - 1], Selection,, "LineNumber");
	EndDo;
	
EndProcedure

#EndRegion

#Region FillingInSubordinateDocuments

// Returns whether the initial product balances were successfully filled in.
//
//	Parameters:
//		DocumentToFillIn - DocumentObject.OBEntry - the object to fill in.
//		FillingData - Structure - Data for filling out the document.
//		InteractiveFilling - Boolean - indicates whether the field is interactive.
//
//	Returns:
//		Boolean - a sign of successful completion of the document.
//
Function FillInBalanceOfGoodsBasedOnReconciliation(DocumentToFillIn, FillingData, InteractiveFilling = False) Export
	
	If Not (TypeOf(FillingData) = Type("Structure") And FillingData.Property("ReconciliationDocument")) Then
		Return False;
	EndIf;
	
	QueryResult = ReconciliationDocumentData(FillingData);
	
	// Fill in the header of the document.
	RequestResultHeaderData = QueryResult[0]; // QueryResult
	HeaderData_ = RequestResultHeaderData.Select();
	HeaderData_.Next();
	
	LocalAccountingCurrency       = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(HeaderData_.Organization);
	ManagementAccountingCurrency           = Constants.ManagementAccountingCurrency.Get();
	FactorOfConversionFromManCurrencyToRegulCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(ManagementAccountingCurrency, LocalAccountingCurrency, EndOfMonth(HeaderData_.Date), LocalAccountingCurrency);
	ConversionFactorFromLocalToManCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(LocalAccountingCurrency, ManagementAccountingCurrency, EndOfMonth(HeaderData_.Date), LocalAccountingCurrency);
	
	FillInGeneralDetailsOfSubordinateDocumentsHeader(FillingData, HeaderData_, DocumentToFillIn);
	
	DocumentToFillIn.BusinessOperation     = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse;
	DocumentToFillIn.RecordInOperationalAccounting = Not FillingData.EnteringCostBalances;
	DocumentToFillIn.PostInCostAccounting     = FillingData.EnteringCostBalances;
	DocumentToFillIn.PostInFinancialAndTaxAccounting            = FillingData.EnteringCostBalances;
	DocumentToFillIn.RecordInMA               = FillingData.EnteringCostBalances;
	
	DocumentToFillIn.PriceIncludesVAT = HeaderData_.AmountIncludesVAT;
	If HeaderData_.AmountInManAccountingCurrency Then
		DocumentToFillIn.Currency = ManagementAccountingCurrency;
	Else
		DocumentToFillIn.Currency = LocalAccountingCurrency;
	EndIf;
	
	// Fill in the tabular part of the document.
	DocumentToFillIn.Goods.Clear();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(DocumentToFillIn);
	
	RequestResultReconciliationData = QueryResult[1]; // QueryResult
	TableReconciliation = RequestResultReconciliationData.Unload();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculatePriceByAmount");
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	RowsToProcess = New Array;
	
	For Each ReconciliationData In TableReconciliation Do
		
		If FillingData.EnteringCostBalances Then
			
			If ReconciliationData.QuantityExternal = 0 Then
				Continue;
			EndIf;
			
			CurrentRow = DocumentToFillIn.Goods.Add();
			FillPropertyValues(CurrentRow, ReconciliationData);
			
			CurrentRow.Count = ReconciliationData.QuantityExternal;
			
			If HeaderData_.QuantityFromOM And ReconciliationData.Count > ReconciliationData.QuantityExternal Then
				
				CurrentRow.Sum 	= ReconciliationData.Sum * ReconciliationData.QuantityExternal / ReconciliationData.Count;
				CurrentRow.SumCompl = ReconciliationData.SumCompl * ReconciliationData.QuantityExternal / ReconciliationData.Count;
				CurrentRow.AmountPermanentDifferences 	= ReconciliationData.AmountPermanentDifferences * ReconciliationData.QuantityExternal / ReconciliationData.Count;
				CurrentRow.AmountTemporaryDifferences 	= ReconciliationData.AmountTemporaryDifferences * ReconciliationData.QuantityExternal / ReconciliationData.Count;
				
			EndIf;
			
			If Not HeaderData_.AmountInManAccountingCurrency Then
				CurrentRow.Sum = Round(CurrentRow.SumCompl * ConversionFactorFromLocalToManCurrency, 2, 1);
				CurrentRow.AmountExcludingVAT = CurrentRow.Sum;
			EndIf;
			
		Else
			
			If ReconciliationData.DeviationInStorageUnits = 0 Then
				Continue;
			EndIf;
			
			CurrentRow = DocumentToFillIn.Goods.Add();
			FillPropertyValues(CurrentRow, ReconciliationData);
			
			CurrentRow.Count  = ?(HeaderData_.QuantityFromOM, -1, 1) * ReconciliationData.DeviationInStorageUnits;
			CurrentRow.Sum 	  = 0;
			CurrentRow.AmountExcludingVAT = 0;
			CurrentRow.SumCompl   = 0;
			CurrentRow.AmountPermanentDifferences 	  = 0;
			CurrentRow.AmountTemporaryDifferences 	  = 0;
			
		EndIf;
		
		CurrentRow.NumberOfPackages = CurrentRow.Count;
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		DocumentToFillIn.Goods);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	If DocumentToFillIn.PriceIncludesVAT Then
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	If HeaderData_.AmountInManAccountingCurrency Then
		StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	EndIf;
	
	For Each CurrentRow In DocumentToFillIn.Goods Do

		If Not DocumentToFillIn.PriceIncludesVAT Then
			CurrentRow.AmountExcludingVAT = CurrentRow.Sum;
		EndIf;
		
	EndDo;
		
	BatchProcessingOfTablePartServer.TreatTS(DocumentToFillIn.Goods, StructureOfActions);
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(DocumentToFillIn, Documents.OBEntry));
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentToFillIn, SeriesSpecificationParameters);
	
	Return True;
	
EndFunction

// Returns a flag indicating that the excess goods were successfully credited.
//
//	Parameters:
//		DocumentToFillIn - DocumentObject.InventorySurplusRecognition - the object to fill in.
//		FillingData - Structure - Data for filling out the document.
//		InteractiveFilling - Boolean - indicates whether the field is interactive.
//
//	Returns:
//		Boolean - a sign of successful completion of the document.
//
Function FillInRegistrationOfSurplusGoodsBasedOnReconciliation(DocumentToFillIn, FillingData, InteractiveFilling = False) Export
	
	If Not (TypeOf(FillingData) = Type("Structure") And FillingData.Property("ReconciliationDocument")) Then
		Return False;
	EndIf;
	
	QueryResult = ReconciliationDocumentData(FillingData);
	
	// Fill in the header of the document.
	RequestResultHeaderData = QueryResult[0]; // QueryResult 
	HeaderData_ = RequestResultHeaderData.Select();
	HeaderData_.Next();
	
	FillInGeneralDetailsOfSubordinateDocumentsHeader(FillingData, HeaderData_, DocumentToFillIn);
	
	If HeaderData_.AmountInManAccountingCurrency Then
		DocumentToFillIn.Currency = Constants.ManagementAccountingCurrency.Get();
	Else
		DocumentToFillIn.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(HeaderData_.Organization);
	EndIf;
	
	// Fill in the tabular part of the document.
	DocumentToFillIn.Goods.Clear();
	
	RequestResultReconciliationData = QueryResult[1]; // QueryResult 
	ReconciliationData = RequestResultReconciliationData.Select();
	While ReconciliationData.Next() Do
		
		AddRow = False;
		
		If Not HeaderData_.QuantityFromOM Then
			If ReconciliationData.DeviationInStorageUnits > 0 Then
				AddRow = Not FillingData.NextPeriodDocument;
			EndIf;
		Else
			If ReconciliationData.DeviationInStorageUnits > 0 Then
				AddRow = FillingData.NextPeriodDocument;
			ElsIf ReconciliationData.DeviationInStorageUnits < 0 Then
				AddRow = Not FillingData.NextPeriodDocument;
			EndIf;
		EndIf;
		
		If Not AddRow Then
			Continue;
		EndIf;
		
		CurrentRow = DocumentToFillIn.Goods.Add();
		FillPropertyValues(CurrentRow, ReconciliationData);
		
		CurrentRow.Count = Max(ReconciliationData.DeviationInStorageUnits, -ReconciliationData.DeviationInStorageUnits);
		CurrentRow.Sum 	 = Max(ReconciliationData.AmountDeviation_, -ReconciliationData.AmountDeviation_);
		CurrentRow.Price 		 = CurrentRow.Sum / CurrentRow.Count;
		
	EndDo;
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(DocumentToFillIn, Documents.InventorySurplusRecognition));
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentToFillIn, SeriesSpecificationParameters);
	
	Return True;
	
EndFunction

// Returns a flag indicating that the product shortage write-off was completed successfully.
//
//	Parameters:
//		DocumentToFillIn - DocumentObject.WriteOffOfGoodsShortages - the object to fill in.
//		FillingData - Structure - Data for filling out the document.
//		InteractiveFilling - Boolean - indicates whether the field is interactive.
//
//	Returns:
//		Boolean - a sign of successful completion of the document.
//
Function FillInWriteOffOfShortageOfGoodsBasedOnReconciliation(DocumentToFillIn, FillingData, InteractiveFilling = False) Export
	
	If Not (TypeOf(FillingData) = Type("Structure") And FillingData.Property("ReconciliationDocument")) Then
		Return False;
	EndIf;
	
	QueryResult = ReconciliationDocumentData(FillingData);
	
	// Fill in the header of the document.
	RequestResultHeaderData = QueryResult[0]; // QueryResult
	HeaderData_ = RequestResultHeaderData.Select();
	HeaderData_.Next();
	
	FillInGeneralDetailsOfSubordinateDocumentsHeader(FillingData, HeaderData_, DocumentToFillIn);
	
	DocumentToFillIn.InventoryOwnerAttributesAreSpecifiedManually = True;
	
	// Fill in the tabular part of the document.
	DocumentToFillIn.Goods.Clear();
	DocumentToFillIn.InventoryKinds.Clear();
	
	RequestResultReconciliationData = QueryResult[1]; // QueryResult
	ReconciliationData = RequestResultReconciliationData.Select();
	While ReconciliationData.Next() Do
		
		AddRow = False;
		
		If Not HeaderData_.QuantityFromOM Then
			If ReconciliationData.DeviationInStorageUnits < 0 Then
				AddRow = Not FillingData.NextPeriodDocument;
			EndIf;
		Else
			If ReconciliationData.DeviationInStorageUnits > 0 Then
				AddRow = Not FillingData.NextPeriodDocument;
			ElsIf ReconciliationData.DeviationInStorageUnits < 0 Then
				AddRow = FillingData.NextPeriodDocument;
			EndIf;
		EndIf;
		
		If Not AddRow Then
			Continue;
		EndIf;
		
		CurrentRow = DocumentToFillIn.Goods.Add();
		FillPropertyValues(CurrentRow, ReconciliationData);
		
		CurrentRow.Count = Max(ReconciliationData.DeviationInStorageUnits, -ReconciliationData.DeviationInStorageUnits);
		
		CurRowOfStockTypes = DocumentToFillIn.InventoryKinds.Add();
		FillPropertyValues(CurRowOfStockTypes, ReconciliationData);
		
		CurRowOfStockTypes.Count = CurrentRow.Count;
		
	EndDo;
	
	DocumentToFillIn.Goods.GroupBy("Products, Characteristic, Purpose, Series, ItemsLocationAttributes, BatchesIndicationStatus", "Count");
	DocumentToFillIn.InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber", "Count");
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(DocumentToFillIn, Documents.WriteOffOfGoodsShortages));
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentToFillIn, SeriesSpecificationParameters);
	
	Return True;
	
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
	Return;	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * Table_RegisterName - ValueTable - the data table to be reflected in the register (instead of the _register name, the name of the register itself is substituted).
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ReconcileOpeningBalancesByWarehouses") Then
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
		ReconcileOpeningBalancesByWarehousesLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region StandardCommandSubsystems

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
	Return;
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReconcileOpeningBalancesByWarehousesLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ReconcileOpeningBalancesByWarehousesLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Warehouse)";

EndProcedure

#Region _DownloadingFromVHFFile

// Sets the download parameters.
//
// Parameters:
//   Parameters - Structure - download parameters from a file.
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
	
	ColumnDataType = Parameters.ColumnDataType;
	
	ColumnDataType.Insert("ExternalCode",				 New TypeDescription("String",,	New StringQualifiers(11)));
	ColumnDataType.Insert("ExternalItemID",			 New TypeDescription("String",,	New StringQualifiers(50)));
	ColumnDataType.Insert("ExternalName",	 New TypeDescription("String",,	New StringQualifiers(255)));
	ColumnDataType.Insert("ExternalUnitOfMeasure", New TypeDescription("String",,	New StringQualifiers(50)));
	ColumnDataType.Insert("ExternalAssignment",		 New TypeDescription("String",,	New StringQualifiers(255)));
	ColumnDataType.Insert("QuantityExternal",		 New TypeDescription("Number",,	New NumberQualifiers(15, 3)));
	ColumnDataType.Insert("ExternalCostMan",	 New TypeDescription("Number",,	New NumberQualifiers(15, 2)));
	ColumnDataType.Insert("ExternalCostLocal",	 New TypeDescription("Number",,	New NumberQualifiers(15, 2)));
	ColumnDataType.Insert("ExternalCostTA",	 	 New TypeDescription("Number",,	New NumberQualifiers(15, 2)));
	ColumnDataType.Insert("ExternalCostPD",	 	 New TypeDescription("Number",,	New NumberQualifiers(15, 2)));
	ColumnDataType.Insert("ExternalCostTD",	 	 New TypeDescription("Number",,	New NumberQualifiers(15, 2)));
	
EndProcedure

// Compares data loaded into the table part of
// the data of the external System with data in the information system, and fills in the parameters of the addressable Comparison and list of one-digit Values.
//
// Parameters:
//	AddressOfUploadedData - String - the address of the temporary storage with the table of values in which
//                                        the downloaded data from the file is located. Composition of columns:
//     * Id - Number - the ordinal number of the line.
//     * _OtherColumns_ - Undefined - the remaining columns correspond to the columns in the File Upload layout.
//	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                        which is a copy of the table part of the document 
//                                        that needs to be filled in from the addressable Data table.
//	ConflictsList - ValueTable - a list of ambiguous values for which there are several suitable options in the information security:
//     * Column       - String - name of the column where the ambiguity was detected.
//     * Id - Number  - ID of the string where the ambiguity was detected.
//	FullTabularSectionName - String - full name of the table part where data is loaded.
//	AdditionalParameters - Structure - additional parameters passed from the source form.
//
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	Balance				= GetFromTempStorage(AddressOfMappingTable); // ValueTable
	DataToImport	= GetFromTempStorage(AddressOfUploadedData);
	
	ArrayExternalCode 			  = DataToImport.UnloadColumn("ExternalCode");
	ArrayExternalArticle 		  = DataToImport.UnloadColumn("ExternalItemID");
	ArrayExternalName 	  = DataToImport.UnloadColumn("ExternalName");
	ArrayExternalUnitOfMeasurement = DataToImport.UnloadColumn("ExternalUnitOfMeasure");
	ArrayExternalAssignment 	  = DataToImport.UnloadColumn("ExternalAssignment");
	
	DataToImport.Columns.Delete("ExternalCode");
	DataToImport.Columns.Delete("ExternalItemID");
	DataToImport.Columns.Delete("ExternalName");
	DataToImport.Columns.Delete("ExternalUnitOfMeasure");
	DataToImport.Columns.Delete("ExternalAssignment");
	
	DataToImport.Columns.Add("ExternalCode",		  	  New TypeDescription("String",, New StringQualifiers(11)));
	DataToImport.Columns.Add("ExternalItemID", 		  New TypeDescription("String",, New StringQualifiers(50)));
	DataToImport.Columns.Add("ExternalName", 	  New TypeDescription("String",, New StringQualifiers(255)));
	DataToImport.Columns.Add("ExternalUnitOfMeasure", New TypeDescription("String",, New StringQualifiers(50)));
	DataToImport.Columns.Add("ExternalAssignment", 	  New TypeDescription("String",, New StringQualifiers(255)));
	
	DataToImport.LoadColumn(ArrayExternalCode, 			  "ExternalCode");
	DataToImport.LoadColumn(ArrayExternalArticle, 		  "ExternalItemID");
	DataToImport.LoadColumn(ArrayExternalName, 	  "ExternalName");
	DataToImport.LoadColumn(ArrayExternalUnitOfMeasurement, "ExternalUnitOfMeasure");
	DataToImport.LoadColumn(ArrayExternalAssignment, 	  "ExternalAssignment");
	
	QueryText =
	"SELECT
	|	DataToImport.ExternalCode				AS ExternalCode,
	|	DataToImport.ExternalItemID			AS ExternalItemID,
	|	DataToImport.ExternalName		AS ExternalName,
	|	DataToImport.ExternalUnitOfMeasure	AS ExternalUnitOfMeasure,
	|	DataToImport.ExternalAssignment			AS ExternalAssignment,
	|	DataToImport.QuantityExternal			AS QuantityExternal,
	|	DataToImport.ExternalCostMan		AS ExternalCostMan,
	|	DataToImport.ExternalCostLocal		AS ExternalCostLocal,
	|	DataToImport.ExternalCostTA		AS ExternalCostTA,
	|	DataToImport.ExternalCostPD		AS ExternalCostPD,
	|	DataToImport.ExternalCostTD		AS ExternalCostTD,
	|	DataToImport.Id				AS Id
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
	|	Goods.Id						AS Id,
	|	MAX(Goods.Products)				AS Products,
	|	COUNT(DISTINCT Goods.Products)	AS QuantityOfProducts
	|INTO TTProductData
	|FROM
	|	(SELECT
	|		DataToImport.Id		AS Id,
	|		Goods.Ref						AS Products
	|	FROM
	|		DataToImport AS DataToImport
	|		INNER JOIN Catalog.Products AS Goods
	|		ON Goods.Code = DataToImport.ExternalCode
	|
	|	WHERE
	|		DataToImport.ExternalCode <> """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id		AS Id,
	|		Goods.Ref						AS Products
	|	FROM
	|		DataToImport AS DataToImport
	|		INNER JOIN Catalog.Products AS Goods
	|		ON Goods.SKU = DataToImport.ExternalItemID
	|
	|	WHERE
	|		DataToImport.ExternalItemID <> """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id		AS Id,
	|		Goods.Ref						AS Products
	|	FROM
	|		DataToImport AS DataToImport
	|		INNER JOIN Catalog.Products AS Goods
	|		ON Goods.Description = DataToImport.ExternalName
	|
	|	WHERE
	|		DataToImport.ExternalName <> """"
	|	) AS Goods
	|
	|GROUP BY
	|	Goods.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id				AS Id,
	|	MAX(CatAssignments.Ref)				AS Purpose,
	|	COUNT(DISTINCT CatAssignments.Ref)	AS NumberOfAppointments
	|INTO TTDestinationData
	|FROM
	|	DataToImport AS DataToImport
	|	INNER JOIN Catalog.Assignments AS CatAssignments
	|	ON CatAssignments.Description = DataToImport.ExternalAssignment
	|
	|WHERE
	|	DataToImport.ExternalAssignment <> """"
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
	|	Packages.Id					AS Id,
	|	MAX(Packages.Package)				AS Package,
	|	COUNT(DISTINCT Packages.Package)	AS PackingQuantity
	|INTO TTPackingData
	|FROM
	|	(SELECT
	|		DataToImport.Id	AS Id,
	|		Packages.Ref					AS Package
	|	FROM
	|		DataToImport AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products
	|		AND Packages.Description = DataToImport.ExternalUnitOfMeasure
	|
	|	WHERE
	|		DataToImport.ExternalUnitOfMeasure <> """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id	AS Id,
	|		Packages.Ref					AS Package
	|	FROM
	|		DataToImport AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products.PackagingGroup
	|		AND Packages.Description = DataToImport.ExternalUnitOfMeasure
	|		
	|	WHERE
	|		DataToImport.ExternalUnitOfMeasure <> """"
	|
	|	) AS Packages
	|
	|GROUP BY
	|	Packages.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id						AS Id,
	|	DataToImport.ExternalCode						AS ExternalCode,
	|	DataToImport.ExternalItemID					AS ExternalItemID,
	|	DataToImport.ExternalName				AS ExternalName,
	|	DataToImport.ExternalUnitOfMeasure			AS ExternalUnitOfMeasure,
	|	DataToImport.ExternalAssignment					AS ExternalAssignment,
	|	DataToImport.QuantityExternal					AS QuantityExternal,
	|	DataToImport.ExternalCostMan				AS ExternalCostMan,
	|	DataToImport.ExternalCostLocal				AS ExternalCostLocal,
	|	DataToImport.ExternalCostTA				AS ExternalCostTA,
	|	DataToImport.ExternalCostPD				AS ExternalCostPD,
	|	DataToImport.ExternalCostTD				AS ExternalCostTD,
	|	CASE
	|		WHEN ISNULL(Goods.QuantityOfProducts, 0) = 1
	|			THEN Goods.Products
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|	END												AS Products,
	|	CASE
	|		WHEN ISNULL(DestinationData.NumberOfAppointments, 0) = 1
	|			THEN DestinationData.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END												AS Purpose,
	|	CASE
	|		WHEN ISNULL(PackageData_.PackingQuantity, 0) = 1
	|			THEN PackageData_.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END												AS Package,
	|	ISNULL(Goods.QuantityOfProducts, 0)			AS QuantityOfProducts,
	|	ISNULL(DestinationData.NumberOfAppointments, 0)	AS NumberOfAppointments,
	|	ISNULL(PackageData_.PackingQuantity, 0)		AS PackingQuantity
	|FROM
	|	DataToImport AS DataToImport
	|	LEFT JOIN TTProductData AS Goods
	|	ON Goods.Id = DataToImport.Id
	|
	|	LEFT JOIN TTDestinationData AS DestinationData
	|	ON DestinationData.Id = DataToImport.Id
	|
	|	LEFT JOIN TTPackingData AS PackageData_
	|	ON PackageData_.Id = DataToImport.Id
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataToImport", DataToImport);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		NewRow = Balance.Add();
		FillPropertyValues(NewRow, Selection);
		
		If Selection.QuantityOfProducts > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "Products";
		EndIf;
		
		If Selection.NumberOfAppointments > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "Purpose";
		EndIf;
		
		If Selection.PackingQuantity > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "Package";
		EndIf;
		
	EndDo;
	
	PutToTempStorage(Balance, AddressOfMappingTable);
	
EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
// 
// Parameters:
//	FullTabularSectionName  - String - full name of the table part where data is loaded.
//	ConflictsList    - Array - Array to fill in with ambiguous data
//	ColumnName                - String - name of the column where the ambiguity occurs
//	LoadedValuesString - String - Loaded data based on which the ambiguity occurred.
//	AdditionalParameters   - Structure - additional parameters passed from the source form.
//
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export 
	
	Query = New Query;
	
	If ColumnName = "Products" Then
		
		Query.Text =
		"SELECT
		|	CatProducts.Ref AS Ref
		|FROM
		|	Catalog.Products AS CatProducts
		|WHERE
		|	(&ExternalCode <> """"
		|		AND CatProducts.Code = &ExternalCode)
		|	OR (&ExternalName <> """"
		|		AND CatProducts.Description = &ExternalName)
		|";
		
		Query.SetParameter("ExternalCode",			 LoadedValuesString.ExternalCode);
		Query.SetParameter("ExternalName", LoadedValuesString.ExternalName);
		
	ElsIf ColumnName = "Purpose" Then
		
		Query.Text =
		"SELECT
		|	CatAssignments.Ref AS Ref
		|FROM
		|	Catalog.Assignments AS CatAssignments
		|
		|WHERE
		|	&ExternalAssignment <> """"
		|	AND CatAssignments.Description = &ExternalAssignment
		|";
		
		Query.SetParameter("ExternalAssignment",	LoadedValuesString.ExternalAssignment);
		
	ElsIf ColumnName = "Package" Then
		
		Query.Text =
		"SELECT
		|	Packages.Ref AS Ref
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS Packages
		|WHERE
		|	&ExternalUnitOfMeasure <> """"
		|	AND Packages.Description = &ExternalUnitOfMeasure
		|";
		
		Query.SetParameter("ExternalUnitOfMeasure", LoadedValuesString.ExternalUnitOfMeasure);
		
	EndIf;
	
	If ValueIsFilled(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,Date";
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName 			  = "Document.ReconcileOpeningBalancesByWarehouses";
	SeriesSpecificationParameters.NameTSGoods 					  = "ExternalSystemData";
	SeriesSpecificationParameters.TSSeriesName 	 				  = "ExternalSystemData";
	SeriesSpecificationParameters.FieldNameQuantity 			  = "QuantityExternal";	
	SeriesSpecificationParameters.Date 						  = Object.Date;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.ThisIsAnInvoice 				  = True;            
	SeriesSpecificationParameters.SeriesOnlyForCostPrice 	  = True;
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.OBEntry);
	
	If WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, , Object.Date) Then 
			
		SeriesSpecificationParameters.UseBinLocationWarehousing = True;
		SeriesSpecificationParameters.LinkFields.Add("Package");
		
	EndIf;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.QuantityExternal AS Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		ELSE CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 14
	|							ELSE 13
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|			AND (CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

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

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query = New Query;
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	Query.Text =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date                     AS Period,
	|	DocumentData.Number                    AS Number,
	|	DocumentData.Organization 			 AS Organization,
	|	DocumentData.Warehouse 					 AS Warehouse,
	|	DocumentData.AmountInManAccountingCurrency 		 AS AmountInManAccountingCurrency,
	|	DocumentData.AmountIncludesVAT 		 AS AmountIncludesVAT,
	|	DocumentData.SpecifyTargets 	 AS SpecifyTargets,
	|	DocumentData.QuantityFromOM 			 AS QuantityFromOM,
	|	DocumentData.EmployeeResponsible            AS EmployeeResponsible,
	|	DocumentData.Comment              AS Comment,
	|	DocumentData.DeletionMark          AS DeletionMark,
	|	DocumentData.Posted                 AS Posted
	|FROM
	|	Document.ReconcileOpeningBalancesByWarehouses AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	For Each CurColumn In Attributes.Owner().Columns Do
		Query.SetParameter(CurColumn.Name, Attributes[CurColumn.Name]);
	EndDo;
	
	Query.SetParameter("MetadataIdentifier",
		Common.MetadataObjectID("Document.ReconcileOpeningBalancesByWarehouses"));
	
EndProcedure

#EndRegion

#Region FillingInFieldsRelatedToProducts

Procedure FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters = Undefined) Export
	
	If SeriesSpecificationParameters = Undefined Then
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.ReconcileOpeningBalancesByWarehouses);
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

Procedure FillInProductTrackingForm(Object) Export
	
	If Object.ReconciliationResults.Find(Catalogs.InventoryLocationAttributeKeys.EmptyRef(), "ItemsLocationAttributes") = Undefined Then
		// All inventory accounting analysts are filled in.
		Return;
	EndIf;
	
	Analysts = Object.ReconciliationResults.UnloadColumn("ItemsLocationAttributes");
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
		Enums.BusinessTransactions.GoodsRecordingAsReceived,
		Object.Warehouse,
		Undefined,
		Undefined);
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(Object.ReconciliationResults, PlacesOfAccounting);
	
	For LineNumber = 0 To Analysts.Count() - 1 Do
		
		If ValueIsFilled(Analysts[LineNumber]) Then
			// Filling in the analytics could pick up a duplicate of the analytics - we will return the original analytics.
			Object.ReconciliationResults[LineNumber].ItemsLocationAttributes = Analysts[LineNumber];
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillStockTypes(Object) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTOriginalProductTable
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|	OR &RefillInventoryKinds
	|;
	|///////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS TaxationOfOrganization,
	|	UNDEFINED AS GoodsOwner,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef) AS PriceKind
	|INTO OriginalProductTable
	|FROM
	|	TTOriginalProductTable AS TableOfGoods
	|;
	|///////////////////////////////////////////////////
	|DROP TTOriginalProductTable";
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("TableOfGoods", Object.ReconciliationResults.Unload(, "LineNumber, Products, InventoryOwnerAttribute"));
	Query.SetParameter("Organization", 	Object.Organization);
	Query.SetParameter("Posted", 		Object.Posted);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(Object, Query);
	
	Query.Execute();
	
	InventoriesServer.FillStockTypesByDefault(Query.TempTablesManager, Object.ReconciliationResults);
	
EndProcedure

#EndRegion

#Region PopulatingResultsTable

Procedure FillInQuantitiesInResultTableRow(Object, NewRow, QuantityExternal, AccountingQuantity)
	
	NewRow.QuantityExternal = QuantityExternal;
	
	NewRow.NumberOfPackages = AccountingQuantity;
	NewRow.Count = NewRow.NumberOfPackages;
	
	If Object.QuantityFromOM Then
		NewRow.NumberOfPackagesDiscrepancy = AccountingQuantity - QuantityExternal;
	Else
		NewRow.NumberOfPackagesDiscrepancy = QuantityExternal - AccountingQuantity;
	EndIf;
	
	NewRow.DeviationInStorageUnits = NewRow.NumberOfPackagesDiscrepancy;
	
EndProcedure

#EndRegion

#Region FillingInSubordinateDocuments

Function ReconciliationDocumentData(FillingData)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	T.Date AS Date,
	|	T.Organization AS Organization,
	|	T.Warehouse AS Warehouse,
	|	T.AmountInManAccountingCurrency AS AmountInManAccountingCurrency,
	|	T.AmountIncludesVAT AS AmountIncludesVAT,
	|	T.SpecifyTargets AS SpecifyTargets,
	|	T.QuantityFromOM AS QuantityFromOM
	|FROM
	|	Document.ReconcileOpeningBalancesByWarehouses AS T
	|WHERE
	|	T.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	T.Series AS Series,
	|	CASE WHEN Header.SpecifyTargets
	|		THEN T.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.CCDNumber AS CCDNumber,
	|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
	|		VALUE(Catalog.VATRates.EmptyRef))) AS VATRate,
	|	T.Package AS Package,
	|	CASE WHEN Header.QuantityFromOM
	|		THEN T.NumberOfPackages
	|		ELSE T.QuantityExternal
	|	END AS NumberOfPackages,
	|	CASE WHEN Header.QuantityFromOM
	|		THEN T.Count
	|		ELSE T.QuantityExternal
	|	END AS Count,
	|	T.QuantityExternal AS QuantityExternal,
	|	T.NumberOfPackagesDiscrepancy AS NumberOfPackagesDiscrepancy,
	|	T.DeviationInStorageUnits AS DeviationInStorageUnits,
	|	CASE WHEN Header.AmountInManAccountingCurrency
	|		THEN T.CostMan
	|		ELSE 0
	|	END AS Sum,
	|	CASE WHEN Header.AmountInManAccountingCurrency
	|		THEN 0
	|		ELSE T.LocalCost
	|	END AS SumCompl,
	|	T.CostPermanentDifference AS AmountPermanentDifferences,
	|	T.CostTemporaryDifference AS AmountTemporaryDifferences,
	|	CAST(T.DeviationInStorageUnits
	|		* CASE WHEN Header.AmountInManAccountingCurrency
	|			THEN T.CostMan
	|			ELSE T.LocalCost
	|	  	END
	|		/ CASE
	|			WHEN T.QuantityExternal = 0
	|				THEN T.Count
	|			WHEN T.Count = 0
	|				THEN T.QuantityExternal
	|			WHEN T.Count > T.QuantityExternal
	|				THEN T.Count
	|				ELSE T.QuantityExternal
	|	  	END
	|	  AS NUMBER(31,2)) AS AmountDeviation_
	|FROM
	|	Document.ReconcileOpeningBalancesByWarehouses.ReconciliationResults AS T
	|	INNER JOIN Document.ReconcileOpeningBalancesByWarehouses AS Header
	|	ON T.Ref = Header.Ref
	|	LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Period,
	|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|		ON T.Products = ProductsVATRates.Products
	|	LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Period, Country = &RegistrationCountry) AS BasicVATRates
	|		ON (TRUE)
	|WHERE
	|	T.Ref = &Ref
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose";
	
	Query.SetParameter("Ref", FillingData.ReconciliationDocument);
	Query.SetParameter("Period", Common.ObjectAttributeValue(FillingData.ReconciliationDocument, "Date"));
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(
		Common.ObjectAttributeValue(FillingData.ReconciliationDocument, "Organization")));
		
	Return Query.ExecuteBatch();
	
EndFunction

Procedure FillInGeneralDetailsOfSubordinateDocumentsHeader(FillingData, HeaderData_, DocumentToFillIn)
	
	DocumentToFillIn.Date		= EndOfMonth(HeaderData_.Date) + ?(FillingData.NextPeriodDocument, 1, 0);
	DocumentToFillIn.Organization = HeaderData_.Organization;
	DocumentToFillIn.Warehouse		= HeaderData_.Warehouse;
	DocumentToFillIn.Basis	= FillingData.ReconciliationDocument;
	DocumentToFillIn.Comment	= TrimAll(FillingData.ReconciliationDocument);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

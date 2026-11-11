#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public
	
// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	Result = New Array;
	Result.Add("Numerator");
	Result.Add("Denominator");
	Result.Add("UnitOfMeasure");
	Result.Add("Parent");
	Result.Add("NumberOfPackages");
	Result.Add("PackageType");
	Result.Add("MeasuredValueType");
	Return Result;
EndFunction

// Looking for packing identical to the transmitted package, if you can not find, creates the packaging for the passed item.
//
// Parameters:
//  ProductsOfOriginalQuality	 - CatalogRef.Products - nomenclature to search among packages
//  Products					 - CatalogRef.Products - owner of the new package
//  PackagingInDocument_				 - CatalogRef.PackagesAndUnitsOfMeasure - high-quality product packaging that is used to search for identical packaging
//  	defective goods.
// 
// Returns:
//  CatalogRef.PackagesAndUnitsOfMeasure - link to identical packaging.
//
Function IdenticalPackaging(ProductsOfOriginalQuality, Products, PackagingInDocument_) Export
	
	If ValueIsFilled(PackagingInDocument_) Then
		RequestForPackaging = New Query;
		RequestForPackaging.SetParameter("Ref", PackagingInDocument_);
		RequestForPackaging.SetParameter("Products", Products);
		RequestForPackaging.Text =
		"SELECT TOP 1
		|	PackagingOfLowQualityGoods.Ref AS PackagingOfLowQualityGoods
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS PackagingOfQualityGoods
		|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagingOfLowQualityGoods
		|		ON &QueryTextPackagingFactor1 = &QueryTextPackagingFactor2
		|			AND PackagingOfQualityGoods.UnitOfMeasure = PackagingOfLowQualityGoods.UnitOfMeasure
		|			AND PackagingOfQualityGoods.WarehouseGroup = PackagingOfLowQualityGoods.WarehouseGroup
		|WHERE
		|	PackagingOfQualityGoods.Ref = &Ref
		|	AND PackagingOfLowQualityGoods.Owner = CASE
		|			WHEN CAST(&Products AS Catalog.Products).PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
		|				THEN &Products
		|			ELSE CAST(&Products AS Catalog.Products).PackagingGroup
		|		END
		|
		|ORDER BY
		|	PackagingOfLowQualityGoods.Description,
		|	PackagingOfLowQualityGoods.Ref";
		
		RequestForPackaging.Text = StrReplace(RequestForPackaging.Text,
			"&QueryTextPackagingFactor1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PackagingOfQualityGoods", Undefined));
			
		RequestForPackaging.Text = StrReplace(RequestForPackaging.Text,
			"&QueryTextPackagingFactor2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PackagingOfLowQualityGoods", Undefined));
			
		SampleByPackage_ = RequestForPackaging.Execute().Select();
		If SampleByPackage_.Next() Then
			FoundPackaging = SampleByPackage_.PackagingOfLowQualityGoods;
		Else
			FoundPackaging = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		EndIf;
		
		If ValueIsFilled(FoundPackaging)
			// If the low-quality nomenclature does not have individual packages, then we will not create them automatically.
			Or Common.ObjectAttributeValue(Products,"PackagingGroup") <> Catalogs.PackagingGroups.SpecialForItem Then
			
			Return FoundPackaging;
		EndIf;
	Else
		Return Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	EndIf;	
	
	SetPrivilegedMode(True);
	NewPackaging = PackagingInDocument_.Copy();
	
	// Packaging can only be individual
	NewPackaging.Owner = Products;
	NewPackaging.Parent = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	NewPackaging.Write();
	
	Return NewPackaging.Ref;
	
EndFunction

// Fills the selection list of packages on the selection parameters, a pre-list is cleared.
//  Example of calling from form handlers:
//  Guides.Opakowaniowej.Fill In The Selection List(Elements.Packaging.Listselection,
//  New Structure ("Item, Add Empty Package", Object.Item, The Truth));
//
// Parameters:
//  ChoiceList	 - ValueList - list to fill in
//  ChoiceParameters	 - Structure - the selection parameters.
//
Procedure FillChoiceList(ChoiceList, ChoiceParameters) Export
	ChoiceList.Clear();
	For Each ChoiceItem In Catalogs.PackagesAndUnitsOfMeasure.GetChoiceData(ChoiceParameters) Do
		ChoiceList.Add(ChoiceItem.Value, ChoiceItem.Presentation, ChoiceItem.Check, ChoiceItem.Picture);
	EndDo;
EndProcedure

// Displays the item's unit of measurement as an input prompt in the packaging field.
//
// Parameters:
//	Products      - CatalogRef.Products - item reference,
//	PackagingInputField - FormField - a field in the form that contains information about the item's packaging / unit of measurement.
//
Procedure DisplayInformationAboutStorageUnit(Products, PackagingInputField) Export
	
	PackagingInputField.InputHint = Common.ObjectAttributeValue(Products, "UnitOfMeasure");
	
EndProcedure

// Returns the item's storage unit.
//
// Parameters:
//  Products - CatalogRef.Products - the link of the item.
//
// Returns:
//  CatalogRef.PackagesAndUnitsOfMeasure - the item storage unit.
//
Function ProductStorageUnit(Val Products) Export
	
	Return Common.ObjectAttributeValue(Products, "UnitOfMeasure");
	
EndFunction

// Function - text of the packing coefficient request
//
// Parameters:
//  SourceOfPackaging	 - 	String - Table with packaging. For example, " EXPRESS(&) as a reference.Packagingunits of measurement)" or " table of Goods.Packaging"
//  SourceOfProducts - 	String - Table with the nomenclature. If this parameter is omitted, the packaging 
//							Source must be guaranteed to refer to a package / unit of measurement of the "Package" type.
//							For Example, " Tableau Goods.Nomenclature " or " EXPRESS (&Nomenclature as a reference.Nomenclature)".
// 
// Returns:
//  String - Query text
//
Function RequestTextForPackingCoefficient(SourceOfPackaging, SourceOfProducts = Undefined) Export 
	
	If Not ValueIsFilled(SourceOfProducts)  Then 
		
		QueryText = 
		"CASE WHEN ISNULL(GoodsTable.Package.Denominator,1) <> 0
		|			 AND ISNULL(GoodsTable.Package.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	THEN CAST(ISNULL(GoodsTable.Package.Numerator, 1) / ISNULL(GoodsTable.Package.Denominator, 1) AS NUMBER(27, 11))
		|	ELSE NULL
		|END";
		
	Else		
		
		QueryText = 
		"CASE
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
		|				AND GoodsTable.Products.WeightUse
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Numerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.WeightNumerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|			THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
		|				AND GoodsTable.Products.VolumeUse
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Numerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.VolumeNumerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|			THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
		|				AND GoodsTable.Products.AreaUse
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Numerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.AreaNumerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|			THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
		|				AND GoodsTable.Products.LengthUse
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Numerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.LengthNumerator, 0) <> 0
		|				AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|			THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|		WHEN (GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
		|					OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
		|					OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
		|					OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time))
		|				AND GoodsTable.Products.UnitOfMeasure.MeasuredValueType = GoodsTable.Package.MeasuredValueType
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|			THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|					/ (CAST(GoodsTable.Products.UnitOfMeasure.Numerator / GoodsTable.Products.UnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|				AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|			THEN CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))
		|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|			THEN 1
		|		ELSE NULL
		|	END";
		
		QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "GoodsTable.Package", 	SourceOfPackaging);
	
	Return QueryText;	 
	
EndFunction

// Function - text of the packing coefficient request for the selection form
//
// Parameters:
//  SourceOfPackaging	 - 	String - Table with packaging. For example, " EXPRESS(&) as a reference.Packagingunits of measurement)" or " table of Goods.Packaging"
//  SourceOfProducts - 	String - Table with the nomenclature. If this parameter is omitted, the packaging 
//							Source must be guaranteed to refer to a package / unit of measurement of the "Package" type.
//							For Example, " Tableau Goods.Nomenclature " or " EXPRESS (&Nomenclature as a reference.Nomenclature)".
// 
// Returns:
//  String - A string of the request text.
//
Function RequestTextForPackingFactorToSelect(SourceOfPackaging, SourceOfProducts = Undefined) Export 
	
	If Not ValueIsFilled(SourceOfProducts)  Then 
		
		QueryText = 
		"CASE WHEN ISNULL(GoodsTable.Package.Denominator,1) <> 0
		|		AND ISNULL(GoodsTable.Package.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	THEN CAST(ISNULL(GoodsTable.Package.Numerator, 1) / ISNULL(GoodsTable.Package.Denominator, 1) AS NUMBER(27, 11))
		|	ELSE NULL
		|END";
		
	Else		
		
		QueryText = 
		"CASE
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
		|		AND GoodsTable.Products.WeightUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|		THEN 
		|			CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
		|		AND GoodsTable.Products.VolumeUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|		THEN
		|			CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
		|		AND GoodsTable.Products.AreaUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|		THEN
		|			CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
		|		AND GoodsTable.Products.LengthUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|		THEN
		|			CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|	WHEN (GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time))
		|		AND GoodsTable.Products.UnitOfMeasure.MeasuredValueType = GoodsTable.Package.MeasuredValueType
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		THEN
		|			CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.UnitOfMeasure.Numerator / GoodsTable.Products.UnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		THEN CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		THEN 1
		|	ELSE NULL
		|END";
		
		QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "GoodsTable.Package", 	SourceOfPackaging);
	
	Return QueryText;	 
	
EndFunction

// Function - text of the request for availability of the packing coefficient for the selection form
//
// Parameters:
//  SourceOfPackaging	 - 	String - Table with packaging. For example, " EXPRESS(&) as a reference.Packagingunits of measurement)" or " table of Goods.Packaging"
//  SourceOfProducts - 	String - Table with the nomenclature. If this parameter is omitted, the packaging 
//							Source must be guaranteed to refer to a package / unit of measurement of the "Package" type.
//							For Example, " Tableau Goods.Nomenclature " or " EXPRESS (&Nomenclature as a reference.Nomenclature)".
// 
// Returns:
//  String - A string of the request text.
//
Function RequestTextAvailabilityFactorForPackageSelection(SourceOfPackaging, SourceOfProducts = Undefined) Export 
	
	If Not ValueIsFilled(SourceOfProducts)  Then 
		
		QueryText = 
		"CASE WHEN ISNULL(GoodsTable.Package.Denominator,1) <> 0
		|		AND ISNULL(GoodsTable.Package.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	THEN TRUE
		|	ELSE FALSE
		|END";
		
	Else		
		
		QueryText = 
		"CASE
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
		|		AND GoodsTable.Products.WeightUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|		THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|			AND CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
		|		AND GoodsTable.Products.VolumeUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|		THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|			AND CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
		|		AND GoodsTable.Products.AreaUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|		THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|			AND CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
		|		AND GoodsTable.Products.LengthUse
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthNumerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|		THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|			AND CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|	WHEN (GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
		|         OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time))
		|		AND GoodsTable.Products.UnitOfMeasure.MeasuredValueType = GoodsTable.Package.MeasuredValueType
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.UnitOfMeasure.Numerator, 0) <> 0
		|		AND ISNULL(GoodsTable.Products.UnitOfMeasure.Denominator, 0) <> 0
		|		THEN CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.UnitOfMeasure.Numerator / GoodsTable.Products.UnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|			AND CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|				/ (CAST(GoodsTable.Products.UnitOfMeasure.Numerator / GoodsTable.Products.UnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))
		|			BETWEEN 0.0000001 AND 99999999
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|		AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|		THEN TRUE
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		THEN TRUE
		|	ELSE TRUE
		|END";
		
		QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "GoodsTable.Package", 	SourceOfPackaging);
	
	Return QueryText;	 
	
EndFunction

// Function - text of the packing coefficient request
//
// Parameters:
//  SourceOfPackaging	 - String	 - Table with packaging. For example, " EXPRESS(&) as a reference.Opakowaniowej)"
//  SourceOfProducts - String	 - Table with the nomenclature. If this parameter is omitted, the packaging
//  	Source must be guaranteed to refer to a package / unit of measurement of the "Package" type.
//  	For Example, " Tableau Goods.Nomenclature"
//  PackageWeightInUnitConstants	 - 	Boolean	- if FALSE, the query text returns the weight in kg, otherwise-in the constant-the unit of weight measurement . 
// 
// Returns:
//  String - a string of the query text that returns the weight either in the unit of a constant or in kg (see the weightpackage parameterunitsconstants).
//
Function QueryTextPackageWeight(SourceOfPackaging, SourceOfProducts, PackageWeightInUnitConstants = True) Export 
	
	If SourceOfProducts = Undefined Then 
		
		QueryText = 
		"CAST(ISNULL(GoodsTable.Package.Weight, 0) 
		|	* CAST(ISNULL(GoodsTable.Package.WeightUnitOfMeasure.Numerator, 0) / ISNULL(GoodsTable.Package.WeightUnitOfMeasure.Denominator, 1) AS NUMBER(27, 11)) 
		|	/ CAST(&NumberOfKgPerUnitOfWeight AS NUMBER(27, 11)) AS NUMBER(27, 11))";
		
	Else		
		
		QueryText = 
		"CAST(CASE
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
		|					AND GoodsTable.Products.WeightUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				THEN CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
		|					AND GoodsTable.Products.WeightUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
		|					AND GoodsTable.Products.WeightUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
		|					AND GoodsTable.Products.WeightUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|					AND ISNULL(GoodsTable.Package.WeightUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST(GoodsTable.Package.Weight 
		|						* CAST(GoodsTable.Package.WeightUnitOfMeasure.Numerator / GoodsTable.Package.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN (GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|					OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.EmptyRef)
		|					OR ISNULL(GoodsTable.Package.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
		|					AND GoodsTable.Products.WeightUse
		|					AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST(CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11))
		|						* CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			ELSE 0
		|		END / (CAST(&NumberOfKgPerUnitOfWeight AS NUMBER(27, 11))) AS NUMBER(27, 11))";
				
		QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
		
	EndIf;
	
	If PackageWeightInUnitConstants Then
		UnitOfMeasureForWeight = Constants.UnitOfMeasureForWeight.Get();
		If Not ValueIsFilled(UnitOfMeasureForWeight) Then
			Raise NStr("vi = 'Chưa đặt giá trị hằng ""Đơn vị tính trọng lượng"". Hãy liên hệ với người quản trị.';
						|ru = 'Не задано значение константы ""Единица измерения веса"". Обратитесь к администратору.';
						|en = '""Unit of weight"" constant not specified. Please contact the administrator.'; fa = '""Unit of weight"" constant not specified. Please contact the administrator.';
						|it = 'Il valore della costante ""Unità di misura del peso"" non è specificato. Contattare l''amministratore.';
						|pl = 'Nie określono wartości konstanty ""Jednostka miary wagi"". Skontaktuj się z administratorem.';
						|tr = '""Ağırlık ölçü birimi"" sabitinin değeri ayarlanmadı. Yönetici ile iletişime geç.'");
		EndIf;
		ResultingStructure = Common.ObjectAttributesValues(UnitOfMeasureForWeight, "Numerator, Denominator");
		NumberOfKgPerUnitOfWeight = ResultingStructure.Numerator / ResultingStructure.Denominator;		
	Else
		NumberOfKgPerUnitOfWeight = 1; 		
	EndIf;
	QueryText = StrReplace(QueryText, "&NumberOfKgPerUnitOfWeight", Format(NumberOfKgPerUnitOfWeight, "NDS=.; NG=0"));
	
	QueryText = StrReplace(QueryText, "GoodsTable.Package", 	SourceOfPackaging);
	
	Return QueryText;	 
	
EndFunction

// Function - text of the packing coefficient request
//
// Parameters:
//  SourceOfPackaging	 - 	String - Table with packaging. For example, " EXPRESS(&) as a reference.Opakowaniowej)"
//  SourceOfProducts - 	String - Table with the nomenclature. If this parameter is omitted, the packaging 
//							Source must be guaranteed to refer to a package / unit of measurement of the "Package" type.
//							For Example, " Tableau Goods.Nomenclature"
//  PackingVolumePerUnitConstant	 - 	Boolean	- if FALSE, the query text returns the volume in m3, otherwise-in a constant-the unit of measurement of volume. 
// 
// Returns:
//  String - a string of the query text that returns the volume either in the unit of a constant or in m3 (see the parameter Volume packagingunitsconstants).
//
Function QueryTextPackageVolume(SourceOfPackaging, SourceOfProducts, PackingVolumePerUnitConstant = True) Export 
	
	If SourceOfProducts = Undefined Then
		
		QueryText = 
		"CAST(ISNULL(GoodsTable.Package.VolumeM3, 0) 
		|	* CAST(ISNULL(GoodsTable.Package.VolumeUnitOfMeasure.Numerator, 0) / ISNULL(GoodsTable.Package.VolumeUnitOfMeasure.Denominator, 1) AS NUMBER(27, 11)) 
		|	/ CAST(&NumberOfCubicMetersPerUnitOfVolume AS NUMBER(27, 11)) AS NUMBER(27, 11))";
		
	Else		
		
		QueryText = 
		"CAST(CASE
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
		|					AND GoodsTable.Products.VolumeUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				THEN CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
		|					AND GoodsTable.Products.VolumeUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
		|					AND GoodsTable.Products.VolumeUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
		|					AND GoodsTable.Products.VolumeUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|					AND ISNULL(GoodsTable.Package.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST(GoodsTable.Package.VolumeM3 
		|						* CAST(GoodsTable.Package.VolumeUnitOfMeasure.Numerator / GoodsTable.Package.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN (GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|					OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.EmptyRef)
		|					OR ISNULL(GoodsTable.Package.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
		|					AND GoodsTable.Products.VolumeUse
		|					AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST(CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			ELSE 0
		|		END / (CAST(&NumberOfCubicMetersPerUnitOfVolume AS NUMBER(27, 11))) AS NUMBER(27, 11))";
		
		
		QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
		
	EndIf;
	
	If PackingVolumePerUnitConstant Then
		UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
		If Not ValueIsFilled(UnitOfMeasureForVolume) Then
			Raise NStr("vi = 'Giá trị không đổi ""Đơn vị đo khối lượng"" không được đặt. Liên hệ với quản trị viên.';
						|ru = 'Не задано значение константы ""Единица измерения объема"". Обратитесь к администратору.';
						|en = '""Unit of volume"" constant not specified. Please contact the administrator.'; fa = '""Unit of volume"" constant not specified. Please contact the administrator.';
						|it = 'Il valore della costante ""Unità di misura del volume"" non è specificato. Contattare l''amministratore.';
						|pl = 'Nie określono wartości konstanty ""Jednostka miary objętości"". Skontaktuj się z administratorem.';
						|tr = '""Hacim ölçü birimi"" sabitinin değeri ayarlanmadı. Yönetici ile iletişime geç.'");
		EndIf;
		ResultingStructure = Common.ObjectAttributesValues(UnitOfMeasureForVolume, "Numerator, Denominator");
		NumberOfCubicMetersPerUnitOfVolume = ResultingStructure.Numerator / ResultingStructure.Denominator;	 
	Else
		NumberOfCubicMetersPerUnitOfVolume = 1;
	EndIf;
	QueryText = StrReplace(QueryText, "&NumberOfCubicMetersPerUnitOfVolume", Format(NumberOfCubicMetersPerUnitOfVolume, "NDS=.; NG=0"));
	
	QueryText = StrReplace(QueryText, "GoodsTable.Package", 	SourceOfPackaging);
	
	Return QueryText;	 
	
EndFunction

// Function - text of the packing coefficient request
//
// Parameters:
//  SourceOfPackaging	 - 	String - Table with packaging. For example, " EXPRESS(&) as a reference.Opakowaniowej)"
//  SourceOfProducts - 	String - Table with the nomenclature. If this parameter is omitted, the packaging 
//							Source must be guaranteed to refer to a package / unit of measurement of the "Package" type.
//							For Example, " Tableau Goods.Nomenclature"
//  PackingAreaPerUnitConstant	 - 	Boolean	- if FALSE, the query text returns the area in m2, otherwise-in a constant-the unit of area measurement. 
// 
// Returns:
//  String - a string of the query text that returns the area either in the unit of the constant or in m2 (see the parameter Area packagingunitsconstants).
//
Function RequestTextPackingArea(SourceOfPackaging, SourceOfProducts, PackingAreaPerUnitConstant = True) Export 
	
	If SourceOfProducts = Undefined Then
		
		QueryText = 
		"CAST(ISNULL(GoodsTable.Package.AreaTypeOfMeasurement, 0) 
		|	* CAST(ISNULL(GoodsTable.Package.AreaUnitOfMeasure.Numerator, 0) / ISNULL(GoodsTable.Package.AreaUnitOfMeasure.Denominator,1) AS NUMBER(27, 11)) 
		|	/ CAST(&QuantityM2PerUnitArea AS NUMBER(27, 11)) AS NUMBER(27, 11))";
		
	Else		
		
		QueryText = 
		"CAST(CASE
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
		|					AND GoodsTable.Products.AreaUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				THEN CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
		|					AND GoodsTable.Products.AreaUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
		|					AND GoodsTable.Products.AreaUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
		|					AND GoodsTable.Products.AreaUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN (GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|					OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.EmptyRef)
		|					OR ISNULL(GoodsTable.Package.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
		|					AND GoodsTable.Products.AreaUse
		|					AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator 
		|						* (GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator) AS NUMBER(27, 11))
		|			ELSE 0
		|		END / (CAST(&QuantityM2PerUnitArea AS NUMBER(27, 11))) AS NUMBER(27, 11))";
		
		
		QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
		
	EndIf;
	
	If PackingAreaPerUnitConstant Then
		UnitOfMeasureForArea = Constants.UnitOfMeasureForArea.Get();
		If Not ValueIsFilled(UnitOfMeasureForArea) Then
			Raise NStr("vi = 'Chưa xác định giá trị hằng ""Đơn vị diện tích"". Liên hệ với quản trị viên.';
						|ru = 'Не задано значение константы ""Единица измерения площади"". Обратитесь к администратору.';
						|en = 'The ""Unit of area"" constant value is not specified. Please contact the administrator.'; fa = 'The ""Unit of area"" constant value is not specified. Please contact the administrator.';
						|it = 'Il valore della costante ""Unità di misura dell''area"" non è specificato. Contattare l''amministratore.';
						|pl = 'Nie określono wartości konstanty ""Jednostka miary powierzchni"". Skontaktuj się z administratorem.';
						|tr = '""Alan ölçü birimi"" sabitinin değeri ayarlanmadı. Yönetici ile iletişime geç.'");
		EndIf;
		ResultingStructure = Common.ObjectAttributesValues(UnitOfMeasureForArea, "Numerator, Denominator");
		QuantityM2PerUnitArea = ResultingStructure.Numerator / ResultingStructure.Denominator;	 
	Else
		QuantityM2PerUnitArea = 1;
	EndIf;
	QueryText = StrReplace(QueryText, "&QuantityM2PerUnitArea", Format(QuantityM2PerUnitArea, "NDS=.; NG=0"));
	
	QueryText = StrReplace(QueryText, "GoodsTable.Package", 	SourceOfPackaging);
	
	Return QueryText;	 
	
EndFunction

// Function - text of the packing coefficient request
//
// Parameters:
//  SourceOfPackaging	 - 	String - Table with packaging. For example, " EXPRESS(&) as a reference.Opakowaniowej)"
//  SourceOfProducts - 	String - Table with the nomenclature. If this parameter is omitted, the packaging 
//							Source must be guaranteed to refer to a package / unit of measurement of the "Package" type.
//							For Example, " Tableau Goods.Nomenclature"
//  PackingLengthInUnitConstants	 - 	Boolean	- if FALSE, the query text returns the volume in m, otherwise-in a constant-the unit of length measurement. 
// 
// Returns:
//  String - a string of the query text that returns the length either in the unit of a constant or in m (see the parameter packagingunitsconstants).
//
Function RequestTextPackageLength(SourceOfPackaging, SourceOfProducts, PackingLengthInUnitConstants = True) Export 
	
	If SourceOfProducts = Undefined Then
		
		QueryText = 
		"CAST(ISNULL(GoodsTable.Package.Length, 0) 
		|	* CAST(ISNULL(GoodsTable.Package.LengthUnitOfMeasure.Numerator, 0) / ISNULL(GoodsTable.Package.LengthUnitOfMeasure.Denominator, 1) AS NUMBER(27, 11)) 
		|	/ CAST(&NumberOfMetersPerUnitOfLength AS NUMBER(27, 11)) AS NUMBER(27, 11))";
		
	Else		
		
		QueryText = 
		"CAST(CASE
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
		|					AND GoodsTable.Products.LengthUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|				THEN CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
		|					AND GoodsTable.Products.LengthUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.WeightDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.WeightUnitOfMeasure.Numerator / GoodsTable.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.WeightNumerator / GoodsTable.Products.WeightDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
		|					AND GoodsTable.Products.AreaUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.VolumeDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.VolumeUnitOfMeasure.Numerator / GoodsTable.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.VolumeNumerator / GoodsTable.Products.VolumeDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
		|					AND GoodsTable.Products.LengthUse
		|					AND ISNULL(GoodsTable.Package.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Numerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaUnitOfMeasure.Denominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaNumerator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.AreaDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST((CAST((CAST(GoodsTable.Package.Numerator / GoodsTable.Package.Denominator AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.AreaUnitOfMeasure.Numerator / GoodsTable.Products.AreaUnitOfMeasure.Denominator AS NUMBER(27, 11))) AS NUMBER(27, 11))) 
		|						/ (CAST(GoodsTable.Products.AreaNumerator / GoodsTable.Products.AreaDenominator AS NUMBER(27, 11))) 
		|						* CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator AS NUMBER(27, 11)) 
		|						* CAST(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator AS NUMBER(27, 11)) AS NUMBER(27, 11))
		|			WHEN (GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|					OR GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.EmptyRef)
		|					OR ISNULL(GoodsTable.Package.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
		|					AND GoodsTable.Products.LengthUse
		|					AND ISNULL(GoodsTable.Products.LengthDenominator, 0) <> 0
		|					AND ISNULL(GoodsTable.Products.LengthUnitOfMeasure.Denominator, 0) <> 0
		|				THEN CAST(GoodsTable.Products.LengthNumerator / GoodsTable.Products.LengthDenominator * 
		|						(GoodsTable.Products.LengthUnitOfMeasure.Numerator / GoodsTable.Products.LengthUnitOfMeasure.Denominator) AS NUMBER(27, 11))
		|			ELSE 0
		|		END / (CAST(&NumberOfMetersPerUnitOfLength AS NUMBER(27, 11))) AS NUMBER(27, 11))";
		
		
		QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
		
	EndIf;
	
	If PackingLengthInUnitConstants Then
		UnitOfMeasureForLength = Constants.UnitOfMeasureForLength.Get();
		If Not ValueIsFilled(UnitOfMeasureForLength) Then
			Raise NStr("vi = 'Chưa đặt giá trị hằng ""Đơn vị tính chiều dài"". Hãy liên hệ với người quản trị.';
						|ru = 'Не задано значение константы ""Единица измерения Длины"". Обратитесь к администратору.';
						|en = '""Unit of length"" constant value is not specified. Please contact the administrator.'; fa = '""Unit of length"" constant value is not specified. Please contact the administrator.';
						|it = 'Il valore della costante ""Unità di misura della lunghezza"" non è specificato. Contattare l''amministratore.';
						|pl = 'Nie określono wartości konstanty ""Jednostka miary długości"". Skontaktuj się z administratorem.';
						|tr = '""Uzunluk ölçü birimi"" sabitinin değeri ayarlanmadı. Yönetici ile iletişime geç.'");
		EndIf;
		ResultingStructure = Common.ObjectAttributesValues(UnitOfMeasureForLength, "Numerator, Denominator");
		NumberOfMetersPerUnitOfLength = ResultingStructure.Numerator / ResultingStructure.Denominator;	 
	Else
		NumberOfMetersPerUnitOfLength = 1;
	EndIf;
	QueryText = StrReplace(QueryText, "&NumberOfMetersPerUnitOfLength", Format(NumberOfMetersPerUnitOfLength, "NDS=.; NG=0"));
	
	QueryText = StrReplace(QueryText, "GoodsTable.Package", 	SourceOfPackaging);
	
	Return QueryText;	 
	
EndFunction

// Function-request Text value of the unit of measurement details
//
// Parameters:
//	AttributeName		 -	String - Name of the unit of measurement detail to get the value for.
//							To get a reference to a unit of measurement, pass the value "Reference".
//  SourceOfPackaging	 - 	String - Table with packaging. For Example, " Tableau Goods.Packaging"
//  SourceOfProducts - 	String - Table with the nomenclature. If this parameter is omitted, the packaging 
//							Source must be guaranteed to refer to a package / unit of measurement of the "Package" type.
//							For Example, " Tableau Goods.Nomenclature".
// 
// Returns:
//  String - the text to be substituted into the query.
//
Function RequestTextValueOfUnitDetails(AttributeName, SourceOfPackaging, SourceOfProducts) Export
	
	If Not ValueIsFilled(SourceOfProducts) Then
		
		QueryText = 
		"CASE
		|	WHEN ISNULL(GoodsTable.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		THEN NULL
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|		THEN GoodsTable.Package.UnitOfMeasure#AttributeName
		|	ELSE GoodsTable.Package#AttributeName
		|END";
		
	Else		
		
		QueryText = 
		"CASE
		|	WHEN ISNULL(GoodsTable.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		THEN GoodsTable.Products.UnitOfMeasure#AttributeName
		|	WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|		THEN GoodsTable.Package.UnitOfMeasure#AttributeName
		|	ELSE GoodsTable.Package#AttributeName
		|END";
		
		QueryText = StrReplace(QueryText, "GoodsTable.Products", SourceOfProducts);
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "GoodsTable.Package", 	SourceOfPackaging);
	
	If AttributeName = "Ref" Then
		QueryText = StrReplace(QueryText, "#AttributeName", "");
	Else
		
		Attributes = DetailsOfUnitOfMeasurement();
		If Attributes.Find(AttributeName) <> Undefined Then
			QueryText = StrReplace(QueryText, "#AttributeName", "." + AttributeName);
		Else
			ReplacementString = "Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails";
			ErrorMessage_ = StrTemplate(NStr("vi = 'Sai giá trị tham số [1] của phương thức %1.';
											|ru = 'Некорректное значение параметра [1] метода %1.';
											|en = 'Method %1 parameter [1] contains invalid value.'; fa = 'Method %1 parameter [1] contains invalid value.';
											|it = 'Valore errato del parametro [1] del metodo %1.';
											|pl = 'Niepoprawna wartość parametru [1] metody %1.';
											|tr = '%1 yönteminin [1] parametresi için yanlış değer.'"), ReplacementString);
			Raise ErrorMessage_;
		EndIf;
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Function-Values of the weight volume and other packaging details
//
// Parameters:
//  Package							 - CatalogRef.PackagesAndUnitsOfMeasure - packing, particulars of which need to
//  Products						 - CatalogRef.Products			 - required to specify if the package is NOT of the "Package" type"
//  OtherAttributes						 - String									 - the names of the other details, separated by commas. Nested access is not allowed (for example, " Parent.Name" - not allowed).
//  WeightPackingVolumeInUnitConstants	 - Boolean 									 - if FALSE, the query text returns the volume in m3 and the weight in kg, otherwise - in a constant-the unit of measurement of weight / volume.
// 
// Returns:
//  Structure - a structure with the values of the coefficient, weight in the constant - unit of measurement of weight, volume in the constant -
//      unit of measurement of volume and other packaging details.
//
Function CoefficientWeightVolumeOtherPackingDetails(Package, Products, OtherAttributes = "", WeightPackingVolumeInUnitConstants = True) Export 
	
	Result = New Structure("Weight, Net_Weight, VolumeM3, ZoomRatio" + ?(ValueIsFilled(OtherAttributes), "," + OtherAttributes, ""), 0, 0, 0, 0);
	StringOfOtherDetails = "";
	
	Result.Insert("NeedToRoundUpQuantity", False);
	If Not ValueIsFilled(Package) Then
		If Not ValueIsFilled(Products) Then
			Result.ZoomRatio = 1;
			Return Result;
		Else
			QueryText = 
			"SELECT TOP 1
			|	1 AS ZoomRatio,
			|	Products.UnitOfMeasure.MeasuredValueType AS TypeOfMeasuredValueToCheck,
			|	&QueryTextPackageWeight AS Weight,
			|	CASE
			|		WHEN Products.WeightUse
			|			THEN CASE
			|				WHEN Products.WeightDenominator = 0
			|					THEN 0
			|				ELSE Products.WeightNumerator / Products.WeightDenominator
			|			END * CASE
			|				WHEN Products.WeightUnitOfMeasure.Denominator = 0
			|					THEN 0
			|				ELSE Products.WeightUnitOfMeasure.Numerator / Products.WeightUnitOfMeasure.Denominator
			|			END
			|		ELSE 0
			|	END AS Net_Weight,
			|	&QueryTextPackageVolume AS VolumeM3
			|FROM
			|	Catalog.Products AS Products
			|WHERE
			|	Products.Ref = &Products";
			SourceOfProducts = "Products";
			SourceOfPackaging = "Products.UnitOfMeasure"
		EndIf;
	Else
		Attributes = StringFunctionsClientServer.SplitStringIntoSubstringsArray(OtherAttributes, ",",,True);
		
		If Attributes.Find("MeasuredValueType") = Undefined Then
			Attributes.Add("MeasuredValueType");
		EndIf;
		
		For Each Attribute In Attributes Do
			StringOfOtherDetails = StringOfOtherDetails + "Package." + Attribute + " AS " + Attribute;
			If Attributes.Find(Attribute) <> Attributes.UBound() Then
				StringOfOtherDetails = StringOfOtherDetails + ",";
			EndIf;
			StringOfOtherDetails = StringOfOtherDetails + Chars.LF + Chars.Tab;
		EndDo;
		
		If Not ValueIsFilled(Products) Then
			QueryText = 
			"SELECT TOP 1
			|	Package.MeasuredValueType AS TypeOfMeasuredValueToCheck,
			|	&OtherAttributes,
			|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
			|	&QueryTextPackageWeight AS Weight,
			|	0 AS Net_Weight,
			|	&QueryTextPackageVolume AS VolumeM3
			|FROM
			|	Catalog.PackagesAndUnitsOfMeasure AS Package
			|WHERE
			|	Package.Ref = &PackagingUnitOfMeasure";
			
			SourceOfProducts = Undefined;
			SourceOfPackaging = "Package";
		Else
			QueryText = 
			"SELECT TOP 1
			|	Package.MeasuredValueType AS TypeOfMeasuredValueToCheck,
			|	&OtherAttributes,
			|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
			|	&QueryTextPackageWeight AS Weight,
			|	CASE
			|		WHEN Products.WeightUse
			|			THEN CASE
			|				WHEN Products.WeightDenominator = 0
			|					THEN 0
			|				ELSE Products.WeightNumerator / Products.WeightDenominator
			|			END * CASE
			|				WHEN Products.WeightUnitOfMeasure.Denominator = 0
			|					THEN 0
			|				ELSE Products.WeightUnitOfMeasure.Numerator / Products.WeightUnitOfMeasure.Denominator
			|			END
			|		ELSE 0
			|	END * ISNULL(&QueryTextPackagingFactor, 1) AS Net_Weight,
			|	&QueryTextPackageVolume AS VolumeM3
			|FROM
			|	Catalog.PackagesAndUnitsOfMeasure AS Package
			|		INNER JOIN Catalog.Products AS Products
			|		ON (Package.Ref = &PackagingUnitOfMeasure)
			|		AND (Products.Ref = &Products)";
			
			SourceOfProducts = "Products";
			SourceOfPackaging = "Package";
		EndIf;
	EndIf;
		
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(SourceOfPackaging,
																										SourceOfProducts));
	QueryText = StrReplace(QueryText,
								"&QueryTextPackageWeight",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(SourceOfPackaging,
																							SourceOfProducts, 
																							WeightPackingVolumeInUnitConstants));
	QueryText = StrReplace(QueryText,
								"&QueryTextPackageVolume",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(SourceOfPackaging,
																								SourceOfProducts, 
																								WeightPackingVolumeInUnitConstants));
	QueryText = StrReplace(QueryText, "&OtherAttributes", 		StringOfOtherDetails);
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("PackagingUnitOfMeasure", Package);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		FillPropertyValues(Result, Selection);
		MustBeRoundOff = ValueIsFilled(Products) 
			And Common.ObjectAttributeValue(Products, "UnitOfMeasure.MeasuredValueType") = Enums.TypesOfMeasuredValues.NumberOfPieces
			And (Selection.TypeOfMeasuredValueToCheck = Enums.TypesOfMeasuredValues.Weight
			Or Selection.TypeOfMeasuredValueToCheck = Enums.TypesOfMeasuredValues.Length
			Or Selection.TypeOfMeasuredValueToCheck = Enums.TypesOfMeasuredValues.VolumeM3
			Or Selection.TypeOfMeasuredValueToCheck = Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement);
		Result.NeedToRoundUpQuantity = MustBeRoundOff;
	EndIf;
	
	Return Result;
	
EndFunction

// Function-packing Coefficient
//
// Parameters:
//  Package	 - 	CatalogRef.PackagesAndUnitsOfMeasure - packaging to get the coefficient of
//  Products - 	CatalogRef.Products - required to specify if the package is NOT of the "package" type.
// 
// Returns:
//  Number - packing ratio
//
Function PackagingFactor(Package, Products) Export 
	
	If Not ValueIsFilled(Package) Then
		Return 1;
	EndIf;
	
	If Not ValueIsFilled(Products) Then
		QueryText = 
		"SELECT TOP 1
		|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
		|	Package.MeasuredValueType AS MeasuredValueType
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS Package
		|WHERE
		|	Package.Ref = &PackagingUnitOfMeasure";
		
		SourceOfProducts = Undefined;
	Else
		QueryText = 
		"SELECT TOP 1
		|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
		|	Package.MeasuredValueType AS MeasuredValueType
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS Package
		|		INNER JOIN Catalog.Products AS Products
		|		ON (Products.Ref = &Products)
		|			AND (Package.Ref = &PackagingUnitOfMeasure)";
		SourceOfProducts =  "Products";
	EndIf;
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("Package",SourceOfProducts));

	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("PackagingUnitOfMeasure", Package);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		If Selection.MeasuredValueType <> Enums.TypesOfMeasuredValues.Package
			And Products = Undefined Then
			ExceptionText = NStr("vi = 'Để tính tỷ lệ đóng gói, bạn cần chuyển hàng.';
								|ru = 'Для расчета коэффициента упаковки нужно передать номенклатуру.';
								|en = 'Transfer products to calculate the packaging unit factor.'; fa = 'Transfer products to calculate the packaging unit factor.';
								|it = 'Per calcolare il coefficiente di imballaggio, è necessario trasferire l''articolo.';
								|pl = 'Aby obliczyć współczynnik opakowania, należy przekazać towary.';
								|tr = 'Paketleme ünitesi katsayısını hesaplamak için öğenin aktarılması gerekir.'");
			Raise ExceptionText;
		EndIf;
		
		ZoomRatio = Selection.ZoomRatio;
		
	EndIf;
	
	Return ZoomRatio;
	
EndFunction

// Returns coefficients for multiple packages
//
// Parameters:
//  PackageData_	 - Array - the array elements must contain the Item and Packaging properties.
// 
// Returns:
//   - Map - the key is a reference to the item, the value of compliance with packaging and its coefficient.
//
Function PackingFactors(PackageData_) Export

	If PackageData_.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	PackingDataTable = New ValueTable;
	PackingDataTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	PackingDataTable.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TMCommonUse.AddRowsToTable(PackingDataTable, PackageData_);
	
	QueryText =
	"SELECT 
	|	PackageData_.Products,
	|	PackageData_.Package
	|INTO PackageData_
	|FROM
	|	&PackageData_ AS PackageData_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	PackageData_.Products,
	|	PackageData_.Package,
	|	&QueryTextPackagingFactor AS ZoomRatio
	|FROM
	|	PackageData_ AS PackageData_";
	
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor",
								RequestTextForPackingCoefficient("PackageData_.Package", "PackageData_.Products"));
								
	Query = New Query(QueryText);
	Query.SetParameter("PackageData_", PackingDataTable);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	PackingFactors = New Map;
	
	While Selection.Next() Do
		
		CoefficientsOfProductPackages = PackingFactors.Get(Selection.Products);
		If CoefficientsOfProductPackages = Undefined Then
			CoefficientsOfProductPackages = New Map;
		EndIf;
		CoefficientsOfProductPackages.Insert(Selection.Package, Selection.ZoomRatio);
		
		PackingFactors.Insert(Selection.Products, CoefficientsOfProductPackages);
	
	EndDo;

	Return PackingFactors;
	
EndFunction

// The function Is a dimensional packing
//
// Parameters:
//  UnitOfMeasure -  CatalogRef.PackagesAndUnitsOfMeasure
//  ReturnParameterTypeOfMeasuredValue - String - return parameter, type of measured value.
// 
// Returns:
//  Boolean - indicates whether the Package is dimensional.
//
Function ThisIsADimensionalUnit(UnitOfMeasure, ReturnParameterTypeOfMeasuredValue = "") Export 
	
	If Not ValueIsFilled(UnitOfMeasure) Then
		UnitTypeValue = Undefined;
	Else
		UnitTypeValue = Common.ObjectAttributeValue(UnitOfMeasure, "MeasuredValueType");
	EndIf;
	
	If ValueIsFilled(UnitTypeValue) Then
		ReturnParameterTypeOfMeasuredValue = Common.EnumerationValueName(UnitTypeValue);
	Else
		ReturnParameterTypeOfMeasuredValue = "";
	EndIf;
	
	If ReturnParameterTypeOfMeasuredValue = "Weight"
		Or ReturnParameterTypeOfMeasuredValue = "VolumeM3"
		Or ReturnParameterTypeOfMeasuredValue = "AreaTypeOfMeasurement"
		Or ReturnParameterTypeOfMeasuredValue = "Length" Then
		
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// The function gets a list of unit codes and uses these codes to search for units in the reference list.
// If there are none, it creates directory elements according to the OKEI classifier.
//
// Parameters:
//	StringOfCodes		 - String	 - String with comma-separated unit codes,
//	UpdateMode	 - Boolean	 - True-indicates that the object was recorded using the update information Database method.Write an object().
//
// Returns:
//	Map of KeyAndValue - list of unit codes and their references:
//		* Key - String- code of the unit of measurement for the ocean.
//		* Value - Undefined, CatalogRef.PackagesAndUnitsOfMeasure - reference to the unit of measurement or Undefined if there is no such code in the OKEI.
//
Function FillInUnitsFromClassifier(StringOfCodes, UpdateMode = False) Export
	
	Map = New Map;
	Tree = GetClassifierData();
	
	ArrayOfCodes = StrSplit(StringOfCodes, ",", False);
	
	For Each Code In ArrayOfCodes Do
		
		ExistingElement = Catalogs.PackagesAndUnitsOfMeasure.FindByCode(Code);
		If Not ValueIsFilled(ExistingElement) Then
			
			TheStructureOfTheSearch = New Structure("NumericCode", Code);
			TreeRow = Tree.Rows.FindRows(TheStructureOfTheSearch, True);
			
			If TreeRow.Count() > 0 Then
				PropertiesAndMeasurements = TreeRow[0];
				
				CatalogObject = Catalogs.PackagesAndUnitsOfMeasure.CreateItem();
				
				If ValueIsFilled(PropertiesAndMeasurements.SymbolNational) Then
					Description = PropertiesAndMeasurements.SymbolNational;
				ElsIf ValueIsFilled(PropertiesAndMeasurements.InternationalSymbol) Then
					Description = PropertiesAndMeasurements.InternationalSymbol;
				ElsIf ValueIsFilled(PropertiesAndMeasurements.CodeLetterDesignationNational) Then
					Description = PropertiesAndMeasurements.CodeLetterDesignationNational;
				ElsIf ValueIsFilled(PropertiesAndMeasurements.CodeLetterDesignationInternational) Then
					Description = PropertiesAndMeasurements.CodeLetterDesignationInternational;
				Else
					Description = PropertiesAndMeasurements.Description;
				EndIf;
				
				CatalogObject.Description            = StrReplace(Description,Chars.LF,"/");
				CatalogObject.InternationalAbbreviation = StrReplace(PropertiesAndMeasurements.CodeLetterDesignationInternational,Chars.LF,"/");
				CatalogObject.DescriptionFull      = StrReplace(PropertiesAndMeasurements.Description,Chars.LF,"/");
				CatalogObject.Code                     = PropertiesAndMeasurements.NumericCode;
				CatalogObject.Numerator               = PropertiesAndMeasurements.Numerator;
				CatalogObject.Denominator             = PropertiesAndMeasurements.Denominator;
				CatalogObject.Owner				 = Catalogs.PackagingGroups.BasicUnitsOfMeasure;
				
				If ValueIsFilled(PropertiesAndMeasurements.MeasuredValueType) Then
					CatalogObject.MeasuredValueType = Enums.TypesOfMeasuredValues[PropertiesAndMeasurements.MeasuredValueType];
				EndIf;
				If UpdateMode Then
					InfobaseUpdate.WriteObject(CatalogObject);
				Else
					CatalogObject.Write();
				EndIf;
				
				Map.Insert(Code, CatalogObject.Ref);
			Else
				Map.Insert(Code, Undefined);
			EndIf;
		Else
			Map.Insert(Code, ExistingElement);	
		EndIf;
		
	EndDo;
	
	Return Map;
	
EndFunction

// Sets the default values of the details depending on the type of package / unit of measurement and other parameters.
//
// Parameters:
//  Package - FormDataStructure, CatalogObject.PackagesAndUnitsOfMeasure - packaging / unit of measurement, where
//      you need to configure the values of the details depending on the type and other parameters.
//
Procedure WorkOutLogicOfConnectionDetails(Package) Export
	
	If Package.MeasuredValueType <> Enums.TypesOfMeasuredValues.Package Then
		Package.Dimensionless  = False;
		Package.Height  = 0;
		Package.Width  = 0;
		Package.Depth = 0;
		Package.VolumeM3   = 0;
		Package.LinearDimensionsPresentation = "";
		Package.WeightUnitOfMeasure = Undefined;
		Package.HeightUnitOfMeasure = Undefined;
		Package.DepthUnitOfMeasure = Undefined;
		Package.UnitOfMeasure = Undefined;
		Package.VolumeUnitOfMeasure = Undefined;
		Package.WarehouseGroup = Undefined;
		Package.WarehouseGroup = Undefined;
		Package.StandardSize = Undefined;
		Package.WidthUnitOfMeasure = Undefined;
		Package.NumberOfPackages = 0;
		Package.SuppliedInReusablePackage = False;
		Package.ReusablePackageItems = Undefined;
		Package.ReusablePackageVariant = Undefined;
		Package.MinimumNumberOfReusablePackages = 0;
		Package.PackageType = Undefined;
	Else	
		Package.Code = "";
		Package.DescriptionFull = "";
		Package.InternationalAbbreviation = "";
		
		If Package.Dimensionless Then
			Package.Height  = 0;
			Package.Width  = 0;
			Package.Depth = 0;
			Package.VolumeM3   = 0;
			
			Package.LinearDimensionsPresentation = NStr("vi = 'Không có kích thước';
														|ru = 'Безразмерная';
														|en = 'No size specification'; fa = 'بدون تعیین اندازه';
														|it = 'Adimensionale ';
														|pl = 'No size specification';
														|tr = 'Boyutsuz'");
		Else
			Package.LinearDimensionsPresentation = String(Package.Height) + " X " + String(Package.Width) + " X " + String(Package.Depth);
		EndIf;
		
		If Package.PackageType = Enums.TypesOfItemsPackages.Complex Then
			If ValueIsFilled(Package.Parent) Then 
				Result   = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(Package.Parent,
					Undefined,
					"Numerator, PackageType");
				Package.Numerator   = Result.Numerator * Package.NumberOfPackages;
				Package.Denominator = 1;
			EndIf;
		ElsIf Package.PackageType = Enums.TypesOfItemsPackages.Unpacking Then
			Package.Parent           = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
			Package.NumberOfPackages = 0;
			Package.Numerator          = 1;
			
			Package.SuppliedInReusablePackage   = False;
			Package.ReusablePackageItems    = Undefined;
			Package.ReusablePackageVariant  = Undefined;
		ElsIf Package.PackageType = Enums.TypesOfItemsPackages.Final Then
			Package.Parent           = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
			Package.NumberOfPackages = 0;
			Package.Denominator        = 1;
		ElsIf Package.PackageType = Enums.TypesOfItemsPackages.CargoItem Then
			Package.Parent           = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
			Package.Numerator 			= 1;
			Package.Denominator        = Package.NumberOfPackages;
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns an array of dimensional types of units of measured quantities.
// 
// Returns:
//	Array of EnumRef.TypesOfMeasuredValues - dimensional types of units of measured quantities.
//
Function DimensionalTypesOfUnits() Export
	
	DimensionalTypes = New Array;
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.Weight);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.Length);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.VolumeM3);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement);
	
	Return DimensionalTypes;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Owner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ProductsServer.PackingUnitsProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	ProductsServerCall.PackagingUnitsOfMeasurementFormReceiptProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing);
	
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure
#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Other

Function GenerateName(PackageType, UnitOfMeasure, Numerator, Denominator, OwnerUnitOfMeasure) Export
	
	If PackageType = Enums.TypesOfItemsPackages.Final 
		And Numerator / Denominator = 1 Then
		Return TrimAll(UnitOfMeasure);
	ElsIf PackageType = Enums.TypesOfItemsPackages.Unpacking Then
		Return TrimAll(TrimAll(UnitOfMeasure) + " (" + Format(Numerator, "NDS=.") + "/" + Format(Denominator, "NDS=.") + " " + TrimAll(OwnerUnitOfMeasure) + ")");
	ElsIf PackageType = Enums.TypesOfItemsPackages.CargoItem Then
		Return "";		
	ElsIf Numerator <> 0 And Denominator <> 0 Then 
		Return TrimAll(TrimAll(UnitOfMeasure) + " (" + Format(Numerator / Denominator,"NDS=.") + " " + TrimAll(OwnerUnitOfMeasure) + ")");
	Else 
		Return "";
	EndIf;

EndFunction

Procedure CopyPackingHierarchy(NewOwner, OldOwner, MatchesCopiedObjects) Export
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	PackagesAndUnitsOfMeasure.Description,
	|	PackagesAndUnitsOfMeasure.Dimensionless,
	|	PackagesAndUnitsOfMeasure.Weight,
	|	PackagesAndUnitsOfMeasure.WeightUnitOfMeasure,
	|	PackagesAndUnitsOfMeasure.Height,
	|	PackagesAndUnitsOfMeasure.HeightUnitOfMeasure,
	|	PackagesAndUnitsOfMeasure.Depth,
	|	PackagesAndUnitsOfMeasure.DepthUnitOfMeasure,
	|	PackagesAndUnitsOfMeasure.UnitOfMeasure,
	|	PackagesAndUnitsOfMeasure.Numerator AS Numerator,
	|	PackagesAndUnitsOfMeasure.Denominator AS Denominator,
	|	PackagesAndUnitsOfMeasure.LinearDimensionsPresentation,
	|	PackagesAndUnitsOfMeasure.VolumeM3,
	|	PackagesAndUnitsOfMeasure.VolumeUnitOfMeasure,
	|	PackagesAndUnitsOfMeasure.WarehouseGroup,
	|	PackagesAndUnitsOfMeasure.StandardSize,
	|	PackagesAndUnitsOfMeasure.Width,
	|	PackagesAndUnitsOfMeasure.WidthUnitOfMeasure,
	|	PackagesAndUnitsOfMeasure.Presentation,
	|	PackagesAndUnitsOfMeasure.NumberOfPackages,
	|	PackagesAndUnitsOfMeasure.PackageType AS PackageType,
	|	PackagesAndUnitsOfMeasure.Ref AS ReferenceForControl,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS ReferenceForTreeLeaves,
	|	PackagesAndUnitsOfMeasure.SuppliedInReusablePackage,
	|	PackagesAndUnitsOfMeasure.ReusablePackageItems,
	|	PackagesAndUnitsOfMeasure.ReusablePackageVariant,
	|	PackagesAndUnitsOfMeasure.MinimumNumberOfReusablePackages,
	|	PackagesAndUnitsOfMeasure.MeasuredValueType,
	|	PackagesAndUnitsOfMeasure.DescriptionFull,
	|	PackagesAndUnitsOfMeasure.InternationalAbbreviation
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|WHERE
	|	PackagesAndUnitsOfMeasure.Owner = &Owner
	|	AND NOT PackagesAndUnitsOfMeasure.DeletionMark
	|TOTALS BY
	|	ReferenceForControl ONLY HIERARCHY";
	
	Query.SetParameter("Owner", OldOwner);
	
	PackingTree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	ConformityOfPackages = New Map;
	
	For Each RowDrv In PackingTree.Rows Do
		
		If RowDrv.DescriptionFull <> Null Then
			
			PackingObject_ = Catalogs.PackagesAndUnitsOfMeasure.CreateItem();
			FillPropertyValues(PackingObject_, RowDrv);
			
			PackingObject_.Owner = NewOwner;
			PackingObject_.Write();
			
			ConformityOfPackages.Insert(RowDrv.ReferenceForControl, PackingObject_.Ref);
			
			RowDrv.ReferenceForTreeLeaves = PackingObject_.Ref;	
			
		EndIf;
		
		WritePackingHierarchy(RowDrv.Rows, NewOwner, ConformityOfPackages);

	EndDo;
	
	MatchesCopiedObjects.Insert("Packages", ConformityOfPackages); 
	
EndProcedure

Procedure WritePackingHierarchy(CurLevelLines, PackageOwner_, ConformityOfPackages, ReferenceForTreeLeaves = Undefined)
	For Each RowDrv In CurLevelLines Do
		
		If RowDrv.ReferenceForControl = RowDrv.Parent.ReferenceForControl Then
			If ValueIsFilled(RowDrv.ReferenceForControl.Parent) Then 
				Continue;
			Else
				// Checking if the package has 2 levels of rows without rows of the next levels of the hierarchy (level 3 and so on).
				// For example, the package "pack" has 2 lines: "pack" and "pack (5 pcs)".
				If RowDrv.Rows.Count() > 1 Then
					WritePackingHierarchy(RowDrv.Rows, PackageOwner_, ConformityOfPackages,
						RowDrv.Parent.ReferenceForTreeLeaves);
				EndIf;
				Continue;
			EndIf;
		EndIf;
		
		PackingObject_ = Catalogs.PackagesAndUnitsOfMeasure.CreateItem();
		FillPropertyValues(PackingObject_,RowDrv);
		
		PackingObject_.Owner = PackageOwner_;
		
		If RowDrv.Parent <> Undefined Then
			PackingObject_.Parent = ?(ValueIsFilled(ReferenceForTreeLeaves),
				ReferenceForTreeLeaves,
				RowDrv.Parent.ReferenceForTreeLeaves);
		EndIf;
			
		PackingObject_.Write();
		
		ConformityOfPackages.Insert(RowDrv.ReferenceForControl, PackingObject_.Ref);
		RowDrv.ReferenceForTreeLeaves = PackingObject_.Ref;
		
		WritePackingHierarchy(RowDrv.Rows, PackageOwner_, ConformityOfPackages);
	EndDo;	
EndProcedure

Function BasicUnitsOfMeasure() Export
	
	UnitsOfMeasurement = New Structure;
	UnitOfMeasureForLength = Constants.UnitOfMeasureForLength.Get();
	UnitsOfMeasurement.Insert("HeightUnitOfMeasure",  UnitOfMeasureForLength);
	UnitsOfMeasurement.Insert("WidthUnitOfMeasure",  UnitOfMeasureForLength);
	UnitsOfMeasurement.Insert("DepthUnitOfMeasure", UnitOfMeasureForLength);
	UnitsOfMeasurement.Insert("VolumeUnitOfMeasure",   Constants.UnitOfMeasureForVolume.Get());
	UnitsOfMeasurement.Insert("WeightUnitOfMeasure",   Constants.UnitOfMeasureForWeight.Get());
	Return UnitsOfMeasurement;
	
EndFunction

Function DetailsOfUnitOfMeasurement()
	
	Result = New Array;
	
	Result.Add("Code");
	Result.Add("Description");
	Result.Add("DescriptionFull");
	Result.Add("InternationalAbbreviation");
	Result.Add("Presentation");
	Result.Add("MeasuredValueType");
	Result.Add("Denominator");
	Result.Add("Numerator");
	
	Return Result;
	
EndFunction

// Returns:
// 	ValueTable:
// 		* Source - CatalogRef.PackagesAndUnitsOfMeasure
// 		* Package - CatalogRef.PackagesAndUnitsOfMeasure
// 		* Count - Number
// 		* MaximumPackageInABranch - Number
//
Function CreateTableOfRepackagingOptionsOnServer(Owner) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	PackagesAndUnitsOfMeasure.Ref AS Source,
	|	PackagesAndUnitsOfMeasure.Parent AS Package,
	|	CASE
	|		WHEN PackagesAndUnitsOfMeasure.NumberOfPackages = 0
	|			THEN PackagesAndUnitsOfMeasure.Numerator / PackagesAndUnitsOfMeasure.Denominator
	|		ELSE PackagesAndUnitsOfMeasure.NumberOfPackages
	|	END AS Count,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS MaximumPackageInABranch
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|WHERE
	|	PackagesAndUnitsOfMeasure.Owner = &Owner
	|	AND NOT PackagesAndUnitsOfMeasure.DeletionMark
	|AUTOORDER";
	
	Query.SetParameter("Owner", Owner);
	PackingTable_ = Query.Execute().Unload();
	TableOfRepackagingOptions = PackingTable_.CopyColumns();
	CurHierarchy = PackingTable_.CopyColumns();
	
	FillRepackagingOptions(PackingTable_, TableOfRepackagingOptions, CurHierarchy, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	
	// Repackaging in an empty package is used only for dimensional storage units
	TypeOfMeasuredValueOfOwner = Common.ObjectAttributeValue(Owner,"UnitOfMeasure.MeasuredValueType");
	
	If Not (TypeOfMeasuredValueOfOwner = Enums.TypesOfMeasuredValues.Weight
		Or TypeOfMeasuredValueOfOwner = Enums.TypesOfMeasuredValues.VolumeM3
		Or TypeOfMeasuredValueOfOwner = Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement
		Or TypeOfMeasuredValueOfOwner = Enums.TypesOfMeasuredValues.Length) Then
		
		Filter = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		LinesToDelete = TableOfRepackagingOptions.FindRows(Filter);
		For Each RowToDelete In LinesToDelete Do
			TableOfRepackagingOptions.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	Return TableOfRepackagingOptions;
	
EndFunction

// Parameters:
// 	PackingTable_ 				- See CreateTableOfRepackagingOptionsOnServer
// 	TableOfRepackagingOptions 	- See CreateTableOfRepackagingOptionsOnServer
// 	CurHierarchy 				- See CreateTableOfRepackagingOptionsOnServer
// 	Package 						- CatalogRef.PackagesAndUnitsOfMeasure - See CreateTableOfRepackagingOptionsOnServer
//
Procedure FillRepackagingOptions(PackingTable_, TableOfRepackagingOptions, CurHierarchy, Package)
	
	Filter = New Structure("Package", Package);
	Rows = PackingTable_.FindRows(Filter);
	If Rows.Count() = 0 Then
		If Not ValueIsFilled(Package) Then
			Return;
		EndIf;
		
		// The final element in the tree, you can fill the maximum packing in the branches
		For Each HierarchyLine In CurHierarchy Do
			NewRow = TableOfRepackagingOptions.Add();
			FillPropertyValues(NewRow, HierarchyLine);
			NewRow.MaximumPackageInABranch = Package;
		EndDo;
		
		NewRow = TableOfRepackagingOptions.Add();
		NewRow.Package = Package;
		NewRow.MaximumPackageInABranch = Package;
		NewRow.Count = 1;
	Else
		For Each String In Rows Do
			
			HierarchyOfPackages = CurHierarchy.Copy();
			
			Filter = New Structure("Source", String.Package);
			RepackagingStrings = CurHierarchy.FindRows(Filter);
			// Repackaging from source packaging to smaller packages
			For Each RepackagingString In RepackagingStrings Do
				NewRow = HierarchyOfPackages.Add();
				NewRow.Package = RepackagingString.Package;
				NewRow.Source = String.Source;
				NewRow.Count = RepackagingString.Count * String.Count;
			EndDo;
			
			// Repackaging from source packaging to current packaging
			NewRow = HierarchyOfPackages.Add();
			FillPropertyValues(NewRow,String);
			
			// Repackaging from more source packages
			FillRepackagingOptions(PackingTable_, TableOfRepackagingOptions, HierarchyOfPackages, String.Source);
			
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

Function GetClassifierData() Export
	
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	ValueTree = New ValueTree;
	ValueTree.Columns.Add("NumericCode");
	ValueTree.Columns.Add("Description");
	ValueTree.Columns.Add("SymbolNational");
	ValueTree.Columns.Add("InternationalSymbol");
	ValueTree.Columns.Add("CodeLetterDesignationNational");
	ValueTree.Columns.Add("CodeLetterDesignationInternational");
	ValueTree.Columns.Add("Numerator");
	ValueTree.Columns.Add("Denominator");
	ValueTree.Columns.Add("MeasuredValueType");
	Level1 = ValueTree.Rows.Add();
	Level1.NumericCode = "";
	If LocalizationRFService Then
		Level1.Description = NStr(
			"vi = 'Đơn vị đo lường quốc tế';
			|ru = 'Международные единицы измерения, включенные в ОКЕИ';
			|en = 'International units of measure included in OKEI'; fa = 'International units of measure included in OKEI';
			|it = 'Unità di misura internazionali, incluse nel Classificatore panrusso di unità di misura';
			|pl = 'Międzynarodowe jednostki miary, zawarte w klasyfikatorze jednostek miary';
			|tr = 'RÖBS''e dahil olan uluslararası ölçü birimleri'", Common.DefaultLanguageCode());
	Else
		Level1.Description = NStr(
			"vi = 'Đơn vị đo lường quốc tế chính';
			|ru = 'Основные международные единицы измерения';
			|en = 'Basic international units of measure'; fa = 'Basic international units of measure';
			|it = 'Principali unità di misure internazionali';
			|pl = 'Podstawowe międzynarodowe jednostki miary';
			|tr = 'Uluslararası ana ölçü birimleri'", Common.DefaultLanguageCode());
	EndIf;
	Level1.SymbolNational = "";
	Level1.InternationalSymbol = "";
	Level1.CodeLetterDesignationNational = "";
	Level1.CodeLetterDesignationInternational = "";
	Level1.Numerator = 0;
	Level1.Denominator = 0;
	Level1.MeasuredValueType = "";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị chiều dài';
								|ru = 'Единицы длины';
								|en = 'Units of length'; fa = 'Units of length';
								|it = 'Unità di lunghezza';
								|pl = 'Jednostki długości';
								|tr = 'Uzunluk birimleri'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "003";
	Level3.Description = NStr("vi = 'Millimeter';
								|ru = 'Миллиметр';
								|en = 'Millimeter'; fa = 'Millimeter';
								|it = 'Millimetro';
								|pl = 'Millimeter';
								|tr = 'Milimetre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'MM';
										|ru = 'мм';
										|en = 'MM'; fa = 'MM';
										|it = 'мм';
										|pl = 'MM';
										|tr = 'MM'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "mm"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MM';
														|ru = 'ММ';
														|en = 'MM'; fa = 'MM';
														|it = 'ММ';
														|pl = 'MM';
														|tr = 'MM'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MMT"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "Length";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "004";
	Level3.Description = NStr("vi = 'Centimet';
								|ru = 'Сантиметр';
								|en = 'Centimeter'; fa = 'سانتی‌متر';
								|it = 'Centimetro';
								|pl = 'Centimeter';
								|tr = 'Santimetre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'cm';
										|ru = 'См';
										|en = 'S'; fa = 'S';
										|it = 'См';
										|pl = 'S';
										|tr = 'Cm'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "cm"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'cm';
														|ru = 'СМ';
														|en = 'S'; fa = 'S';
														|it = 'СМ';
														|pl = 'S';
														|tr = 'Cm'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CMT"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 100;
	Level3.MeasuredValueType = "Length";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "005";
	Level3.Description = NStr("vi = 'Decimet';
								|ru = 'Дециметр';
								|en = 'Decimeter'; fa = 'دسی‌متر';
								|it = 'Decimetro';
								|pl = 'Decimeter';
								|tr = 'Desimetre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'dm';
										|ru = 'дм';
										|en = 'dm'; fa = 'dm';
										|it = 'дм';
										|pl = 'dm';
										|tr = 'дм'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "dm"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'dm';
														|ru = 'ДМ';
														|en = 'DMT'; fa = 'DMT';
														|it = 'ДМ';
														|pl = 'DMT';
														|tr = 'ДМ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DMT"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 10;
	Level3.MeasuredValueType = "Length";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "006";
	Level3.Description = NStr("vi = 'Mét';
								|ru = 'Метр';
								|en = 'Meter'; fa = 'متر';
								|it = 'Metro';
								|pl = 'Meter';
								|tr = 'Metre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'M';
										|ru = 'м';
										|en = 'M'; fa = 'M';
										|it = 'm';
										|pl = 'M';
										|tr = 'M'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "m"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M';
														|ru = 'М';
														|en = 'M'; fa = 'M';
														|it = 'm';
														|pl = 'M';
														|tr = 'M'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MTR"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Length";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "008";
	Level3.Description = NStr("vi = 'Kilomet (1000 mét)';
								|ru = 'Километр (Тысяча метров)';
								|en = 'Kilometer (One thousand meters)'; fa = 'Kilometer (One thousand meters)';
								|it = 'Kilometro (Mille metri)';
								|pl = 'Kilometr (Tysiąc metrów)';
								|tr = 'Kilometre (Bin metre)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = NStr("vi = 'km
		|1000 m';
		|ru = 'км
		|1000 м';
		|en = 'km
		|1,000 m'; fa = 'km
		|1,000 m';
		|it = 'km
		|1000 m';
		|pl = 'km
		|1000 m';
		|tr = 'km
		| 1000 m'", Common.DefaultLanguageCode());
	Level3.InternationalSymbol = "km"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KM (NGÀN M)';
														|ru = 'КМ (ТЫС М)';
														|en = 'KMT'; fa = 'KMT';
														|it = 'Km (mille m)';
														|pl = 'KM (TYS M)';
														|tr = 'KM (BİN M)'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KMT"; //@NON-NLS-1
	Level3.Numerator = 1000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Length";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "009";
	Level3.Description = NStr("vi = 'Megamet (1 triệu mét)';
								|ru = 'Мегаметр (Миллион метров)';
								|en = 'Megameter (One million meters)'; fa = 'Megameter (One million meters)';
								|it = 'Megametro (Un milione di metri)';
								|pl = 'Megametr (Milion metrów)';
								|tr = 'Megametre (milyon metre)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Mm (10^6 m)';
										|ru = 'Мм (10^6 м)';
										|en = 'Mm (10^6 m)'; fa = 'Mm (10^6 m)';
										|it = 'Mm (10^6 m)';
										|pl = 'Mm (10^6 m)';
										|tr = 'Mm (10^6 metre)'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "Mm"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MEGAM (TRIỆU M)';
														|ru = 'МЕГАМ (МЛН М)';
														|en = 'MAM'; fa = 'MAM';
														|it = 'Megam (mln m)';
														|pl = 'MEGAM (MLN M)';
														|tr = 'MEGAM (MİLYON M)'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MAM"; //@NON-NLS-1
	Level3.Numerator = 1000000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Length";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "039";
	Level3.Description = NStr("vi = 'Inch (25,4 mm)';
								|ru = 'Дюйм (25,4 мм)';
								|en = 'Inch (25.4 mm)'; fa = 'Inch (25.4 mm)';
								|it = 'Pollice (25,4 mm)';
								|pl = 'Cal (25,4 mm)';
								|tr = 'İnç (25,4 mm)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'INCH';
										|ru = 'дюйм';
										|en = 'INH'; fa = 'INH';
										|it = 'дюйм';
										|pl = 'INH';
										|tr = 'İNÇ'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "in"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'INCH';
														|ru = 'ДЮЙМ';
														|en = 'INH'; fa = 'INH';
														|it = 'ДЮЙМ';
														|pl = 'INH';
														|tr = 'İNÇ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "INH"; //@NON-NLS-1
	Level3.Numerator = 254;
	Level3.Denominator = 10000;
	Level3.MeasuredValueType = "Length";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "041";
	Level3.Description = NStr("vi = 'Foot (0.3048 m)';
								|ru = 'Фут (0,3048 м)';
								|en = 'Foot (0.3048 m)'; fa = 'Foot (0.3048 m)';
								|it = 'Piede (0,3045 m)';
								|pl = 'Stopa (0,3048 m)';
								|tr = 'Fit (0,3048 m)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'FOOT';
										|ru = 'фут';
										|en = 'FT'; fa = 'FT';
										|it = 'фут';
										|pl = 'FT';
										|tr = 'FİT'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "ft"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'FOOT';
														|ru = 'ФУТ';
														|en = 'FT'; fa = 'FT';
														|it = 'ФУТ';
														|pl = 'FT';
														|tr = 'FİT'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "FOT"; //@NON-NLS-1
	Level3.Numerator = 3048;
	Level3.Denominator = 10000;
	Level3.MeasuredValueType = "Length";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "043";
	Level3.Description = NStr("vi = 'Yard (0.9144 m)';
								|ru = 'Ярд (0,9144 м)';
								|en = 'Yard (0.9144 m)'; fa = 'Yard (0.9144 m)';
								|it = 'Yard (0,9144 m)';
								|pl = 'Jard (0,9144 m)';
								|tr = 'Yarda (0,9144 m)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Yard';
										|ru = 'ярд';
										|en = 'YRD'; fa = 'YRD';
										|it = 'ярд';
										|pl = 'YRD';
										|tr = 'YARD'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "yd"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Yard';
														|ru = 'ЯРД';
														|en = 'YRD'; fa = 'YRD';
														|it = 'ЯРД';
														|pl = 'YRD';
														|tr = 'YARD'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "YRD"; //@NON-NLS-1
	Level3.Numerator = 9144;
	Level3.Denominator = 10000;
	Level3.MeasuredValueType = "Length";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "047";
	Level3.Description = NStr("vi = 'Hải lý (1,852 m)';
								|ru = 'Морская миля (1852 м)';
								|en = 'Nautical mile (1,852 m)'; fa = 'Nautical mile (1,852 m)';
								|it = 'Miglio nautico (1852 m)';
								|pl = 'Mila morska (1852 m)';
								|tr = 'Deniz mili (1852 m)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'hải lý';
										|ru = 'миля';
										|en = 'n mile'; fa = 'n mile';
										|it = 'miglio';
										|pl = 'n mile';
										|tr = 'mil'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "n mile"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'HẢI LÝ';
														|ru = 'МИЛЬ';
														|en = 'NMI'; fa = 'NMI';
														|it = 'Miglio';
														|pl = 'NMI';
														|tr = 'MİL'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "NMI"; //@NON-NLS-1
	Level3.Numerator = 1852;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Length";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị diện tích';
								|ru = 'Единицы площади';
								|en = 'Units of area'; fa = 'Units of area';
								|it = 'Unità di area';
								|pl = 'Jednostki powierzchni';
								|tr = 'Alan birimleri'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "050";
	Level3.Description = NStr("vi = 'Milimét vuông';
								|ru = 'Квадратный миллиметр';
								|en = 'Square millimeter'; fa = 'Square millimeter';
								|it = 'Millimetro quadrato';
								|pl = 'Milimetr kwadratowy';
								|tr = 'Milimetre kare'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'mm2';
										|ru = 'мм2';
										|en = 'mm2'; fa = 'mm2';
										|it = 'мм2';
										|pl = 'mm2';
										|tr = 'mm2'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "mm2"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'mm2';
														|ru = 'ММ2';
														|en = 'mm2'; fa = 'mm2';
														|it = 'ММ2';
														|pl = 'mm2';
														|tr = 'mm2'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MMK"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "051";
	Level3.Description = NStr("vi = 'Centimet vuông';
								|ru = 'Квадратный сантиметр';
								|en = 'Square centimeter'; fa = 'سانتی‌متر مربع';
								|it = 'Centimetro quadrato';
								|pl = 'Centymetr kwadratowy';
								|tr = 'Santimetrekare'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'cm2';
										|ru = 'см2';
										|en = 'cm2'; fa = 'cm2';
										|it = 'см2';
										|pl = 'cm2';
										|tr = 'sm2'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "cm2"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'cm2';
														|ru = 'СМ2';
														|en = 'cm2'; fa = 'cm2';
														|it = 'СМ2';
														|pl = 'cm2';
														|tr = 'sm2'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CMK"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 10000;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "053";
	Level3.Description = NStr("vi = 'Decimet vuông';
								|ru = 'Квадратный дециметр';
								|en = 'Square decimeter'; fa = 'دسی‌متر مربع';
								|it = 'Decimetro quadrato';
								|pl = 'Decymetr kwadratowy';
								|tr = 'Desimetrekare'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'dm2';
										|ru = 'дм2';
										|en = 'dm2'; fa = 'dm2';
										|it = 'дм2';
										|pl = 'dm2';
										|tr = 'dm2'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "dm2"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'dm2';
														|ru = 'ДМ2';
														|en = 'dm2'; fa = 'dm2';
														|it = 'ДМ2';
														|pl = 'dm2';
														|tr = 'dm2'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DMK"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 100;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "055";
	Level3.Description = NStr("vi = 'Mét vuông';
								|ru = 'Квадратный метр';
								|en = 'Square meter'; fa = 'متر مربع';
								|it = 'Metro quadrato';
								|pl = 'Metr kwadratowy';
								|tr = 'Metrekare'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'm2';
										|ru = 'м2';
										|en = 'm2'; fa = 'm2';
										|it = 'м2';
										|pl = 'm2';
										|tr = 'm2'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "m2"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'm2';
														|ru = 'М2';
														|en = 'm2'; fa = 'm2';
														|it = 'М2';
														|pl = 'm2';
														|tr = 'm2'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MTK"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "058";
	Level3.Description = NStr("vi = '1000 mét vuông';
								|ru = 'Тысяча квадратных метров';
								|en = 'Decare'; fa = 'Decare';
								|it = 'Mille metri quadrati';
								|pl = 'Tysiąc metrów kwadratowych';
								|tr = 'Bin metrekare'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '1000 m2';
										|ru = '1000 м2';
										|en = 'daa.'; fa = 'daa.';
										|it = '1000 m2';
										|pl = '1000 m2';
										|tr = '1000 m2'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "daa"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGÀN M2';
														|ru = 'ТЫС М2';
														|en = 'DAA'; fa = 'DAA';
														|it = 'Mille m2';
														|pl = 'TYS M2';
														|tr = 'MİN M2'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DAA"; //@NON-NLS-1
	Level3.Numerator = 1000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "059";
	Level3.Description = NStr("vi = 'Hécta';
								|ru = 'Гектар';
								|en = 'Hectare'; fa = 'Hectare';
								|it = 'Ettaro';
								|pl = 'Hectare';
								|tr = 'Hektar'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'ha';
										|ru = 'га';
										|en = 'ha'; fa = 'ha';
										|it = 'га';
										|pl = 'ha';
										|tr = 'ha'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "ha"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ha';
														|ru = 'ГА';
														|en = 'ha'; fa = 'ha';
														|it = 'ГА';
														|pl = 'ha';
														|tr = 'ha'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "HAR"; //@NON-NLS-1
	Level3.Numerator = 10000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "061";
	Level3.Description = NStr("vi = 'Kilomet vuông';
								|ru = 'Квадратный километр';
								|en = 'Square kilometer'; fa = 'Square kilometer';
								|it = 'Kilometro quadrato';
								|pl = 'Kilometr kwadratowy';
								|tr = 'Kilometrekare'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'km2';
										|ru = 'км2';
										|en = 'km2'; fa = 'km2';
										|it = 'км2';
										|pl = 'km2';
										|tr = 'km2'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "km2"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'km2';
														|ru = 'КМ2';
														|en = 'km2'; fa = 'km2';
														|it = 'КМ2';
														|pl = 'km2';
														|tr = 'km2'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KMK"; //@NON-NLS-1
	Level3.Numerator = 1000000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "071";
	Level3.Description = NStr("vi = 'Inch vuông (645,16 mm2)';
								|ru = 'Квадратный дюйм (645,16 мм2)';
								|en = 'Square inch (645.16 mm2)'; fa = 'Square inch (645.16 mm2)';
								|it = 'Pollice quadrato (645,16 mm2)';
								|pl = 'Cal kwadratowy (645,16 mm2)';
								|tr = 'İnç kare (645,16 mm2)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'INCH2';
										|ru = 'дюйм2';
										|en = 'INK'; fa = 'INK';
										|it = 'дюйм2';
										|pl = 'INK';
										|tr = 'İNÇ2'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "in2"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'INCH2';
														|ru = 'ДЮЙМ2';
														|en = 'INK'; fa = 'INK';
														|it = 'ДЮЙМ2';
														|pl = 'INK';
														|tr = 'İNÇ2'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "INK"; //@NON-NLS-1
	Level3.Numerator = 64.516;
	Level3.Denominator = 100000;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "073";
	Level3.Description = NStr("vi = 'Foot vuông (0,092903 m2)';
								|ru = 'Квадратный фут (0,092903 м2)';
								|en = 'Square foot (0.092903 m2)'; fa = 'Square foot (0.092903 m2)';
								|it = 'Piede quadrato (0,092903 m2)';
								|pl = 'Stopa kwadratowa (0,092903 m2)';
								|tr = 'Kare fut (0,092903 m2)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'foot2';
										|ru = 'фут2';
										|en = 'ft2'; fa = 'ft2';
										|it = 'фут2';
										|pl = 'ft2';
										|tr = 'fit2'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "ft2"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'foot2';
														|ru = 'ФУТ2';
														|en = 'ft2'; fa = 'ft2';
														|it = 'ФУТ2';
														|pl = 'ft2';
														|tr = 'fit2'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "FTK"; //@NON-NLS-1
	Level3.Numerator = 929.03;
	Level3.Denominator = 10000;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "075";
	Level3.Description = NStr("vi = 'Yard vuông (0,8361274 m2)';
								|ru = 'Квадратный ярд (0,8361274 м2)';
								|en = 'Square yard (0.8361274 m2)'; fa = 'Square yard (0.8361274 m2)';
								|it = 'Yard quadrato (0,8361274 m2)';
								|pl = 'Jard kwadratowy (0,8361274 m2)';
								|tr = 'Yarda kare (0,8361274 m2)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'yard2';
										|ru = 'ярд2';
										|en = 'yard2'; fa = 'yard2';
										|it = 'ярд2';
										|pl = 'yard2';
										|tr = 'yarda2'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "yd2"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'yard2';
														|ru = 'ЯРД2';
														|en = 'yard2'; fa = 'yard2';
														|it = 'ЯРД2';
														|pl = 'yard2';
														|tr = 'yarda2'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "YDK"; //@NON-NLS-1
	Level3.Numerator = 8361.274;
	Level3.Denominator = 10000;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "109";
	Level3.Description = NStr("vi = 'Are (100 m2)';
								|ru = 'Ар (100 м2)';
								|en = 'Are (100 m2)'; fa = 'Are (100 m2)';
								|it = 'Ara (100 m2)';
								|pl = 'Ar (100 m2)';
								|tr = 'Ar (100 m2)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'A';
										|ru = 'А';
										|en = 'A'; fa = 'A';
										|it = 'A';
										|pl = 'A';
										|tr = 'A'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "a"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ARE';
														|ru = 'АР';
														|en = 'ARE'; fa = 'ARE';
														|it = 'AR';
														|pl = 'ARE';
														|tr = 'AR'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "ARE"; //@NON-NLS-1
	Level3.Numerator = 100;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị thể tích';
								|ru = 'Единицы объема';
								|en = 'Units of volume'; fa = 'Units of volume';
								|it = 'Unità di volume';
								|pl = 'Jednostki objętości';
								|tr = 'Hacim birimleri'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "110";
	Level3.Description = NStr("vi = 'Milimét khối';
								|ru = 'Кубический миллиметр';
								|en = 'Cubic millimeter'; fa = 'Cubic millimeter';
								|it = 'Millimetro cubo';
								|pl = 'Milimetr sześcienny';
								|tr = 'Metreküp'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'mm3';
										|ru = 'мм3';
										|en = 'mm3'; fa = 'mm3';
										|it = 'mm3';
										|pl = 'mm3';
										|tr = 'mm3'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "mm3"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'mm3';
														|ru = 'ММ3';
														|en = 'mm3'; fa = 'mm3';
														|it = 'mm3';
														|pl = 'mm3';
														|tr = 'mm3'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MMQ"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "111";
	Level3.Description = NStr("vi = 'Centimet khối (Mililit)';
								|ru = 'Кубический сантиметр (Миллилитр)';
								|en = 'Cubic centimeter (milliliter)'; fa = 'Cubic centimeter (milliliter)';
								|it = 'Centimetro cubo (Millilitro)';
								|pl = 'Centymetr sześcienny (Milimetr)';
								|tr = 'Santimetre küp (Mililitre)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'cm3 (ml)';
										|ru = 'см3 (мл)';
										|en = 'cm3 (ml)'; fa = 'cm3 (ml)';
										|it = 'cm3 (ml)';
										|pl = 'cm3 (ml)';
										|tr = 'cm3 (ml)'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "cm3 (ml)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'cm3 (ml)';
														|ru = 'СМ3 (МЛ)';
														|en = 'cm3 (ml)'; fa = 'cm3 (ml)';
														|it = 'cm3 (ml)';
														|pl = 'cm3 (ml)';
														|tr = 'cm3 (ml)'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CMQ (MLT)"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "112";
	Level3.Description = NStr("vi = 'Lít (Decimet khối)';
								|ru = 'Литр (Кубический дециметр)';
								|en = 'Liter (Cubic decimeter)'; fa = 'Liter (Cubic decimeter)';
								|it = 'Litro (Decimetro cubo)';
								|pl = 'Litr (Decymetr sześcienny)';
								|tr = 'Litre (Desimetreküp)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'l (dm3)';
										|ru = 'л (дм3)';
										|en = 'l (dm3)'; fa = 'لیتر (dm3)';
										|it = 'l (dm3)';
										|pl = 'l (dm3)';
										|tr = 'lt (dm3)'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "l (L)
		|dm3"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'L (DM3)';
														|ru = 'Л (ДМЗ)';
														|en = 'LTR (DMQ)'; fa = 'LTR (DMQ)';
														|it = 'L (dm3)';
														|pl = 'L (DMЗ)';
														|tr = 'L (DM3)'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "LTR (DMQ)"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "113";
	Level3.Description = NStr("vi = 'Mét khối';
								|ru = 'Кубический метр';
								|en = 'Cubic meter'; fa = 'متر مکعب';
								|it = 'Metro cubo';
								|pl = 'Metr sześcienny';
								|tr = 'Metreküp'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'M3';
										|ru = 'м3';
										|en = 'MTQ'; fa = 'MTQ';
										|it = 'm3';
										|pl = 'MTQ';
										|tr = 'M3'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "m3"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M3';
														|ru = 'М3';
														|en = 'MTQ'; fa = 'MTQ';
														|it = 'm3';
														|pl = 'MTQ';
														|tr = 'M3'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MTQ"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "118";
	Level3.Description = NStr("vi = 'Decilit';
								|ru = 'Децилитр';
								|en = 'Deciliter'; fa = 'Deciliter';
								|it = 'Decilitro';
								|pl = 'Deciliter';
								|tr = 'Desilitre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'dl';
										|ru = 'дл';
										|en = 'dl'; fa = 'dl';
										|it = 'дл';
										|pl = 'dl';
										|tr = 'дл'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "dl"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'dl';
														|ru = 'ДЛ';
														|en = 'DLT'; fa = 'DLT';
														|it = 'ДЛ';
														|pl = 'DLT';
														|tr = 'ДЛ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DLT"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 10000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "122";
	Level3.Description = NStr("vi = 'Hectolit';
								|ru = 'Гектолитр';
								|en = 'Hectoliter'; fa = 'Hectoliter';
								|it = 'Ettolitro';
								|pl = 'Hectoliter';
								|tr = 'Hektolitre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Hl';
										|ru = 'гл';
										|en = 'HLT'; fa = 'HLT';
										|it = 'hl';
										|pl = 'HLT';
										|tr = 'GL'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "hl"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Hl';
														|ru = 'ГЛ';
														|en = 'HLT'; fa = 'HLT';
														|it = 'hl';
														|pl = 'HLT';
														|tr = 'GL'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "HLT"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 10;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "126";
	Level3.Description = NStr("vi = 'Megalit';
								|ru = 'Мегалитр';
								|en = 'Megaliter'; fa = 'Megaliter';
								|it = 'Megalitro';
								|pl = 'Megaliter';
								|tr = 'Megalitre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Ml';
										|ru = 'Мл';
										|en = 'Ml'; fa = 'Ml';
										|it = 'Ml';
										|pl = 'Ml';
										|tr = 'Ml'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "Ml"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MEGAL';
														|ru = 'МЕГАЛ';
														|en = 'MAL'; fa = 'MAL';
														|it = 'Megal';
														|pl = 'MAL';
														|tr = 'MEGALİTRE'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MAL"; //@NON-NLS-1
	Level3.Numerator = 1000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "131";
	Level3.Description = NStr("vi = 'Inch khối (16387,1 mm3)';
								|ru = 'Кубический дюйм (16387,1 мм3)';
								|en = 'Cubic inch (16,387.1 mm3)'; fa = 'Cubic inch (16,387.1 mm3)';
								|it = 'Pollice cubo (16387,1 mm3)';
								|pl = 'Cal sześcienny (16387,1 mm3)';
								|tr = 'İnç küp (16387,1 mm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'inch3';
										|ru = 'дюйм3';
										|en = 'in3'; fa = 'in3';
										|it = 'дюйм3';
										|pl = 'in3';
										|tr = 'inç3'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "in3"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'inch3';
														|ru = 'ДЮЙМ3';
														|en = 'in3'; fa = 'in3';
														|it = 'ДЮЙМ3';
														|pl = 'in3';
														|tr = 'inç3'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "INQ"; //@NON-NLS-1
	Level3.Numerator = 163.871;
	Level3.Denominator = 10000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "132";
	Level3.Description = NStr("vi = 'Foot khối (0,02831685 m3)';
								|ru = 'Кубический фут (0,02831685 м3)';
								|en = 'Cubic foot (0.02831685 m3)'; fa = 'Cubic foot (0.02831685 m3)';
								|it = 'Piede cubo (0,02831685 m3)';
								|pl = 'Stopa sześcienna (0,02831685 m3)';
								|tr = 'Fit küp (0,02831685 m3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'foot3';
										|ru = 'фут3';
										|en = 'ft3'; fa = 'ft3';
										|it = 'piede3';
										|pl = 'ft3';
										|tr = 'fit3'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "ft3"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'foot3';
														|ru = 'ФУТ3';
														|en = 'ft3'; fa = 'ft3';
														|it = 'piede3';
														|pl = 'ft3';
														|tr = 'fit3'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "FTQ"; //@NON-NLS-1
	Level3.Numerator = 2831.685;
	Level3.Denominator = 100000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "133";
	Level3.Description = NStr("vi = 'Yard khối (0,764555 m3)';
								|ru = 'Кубический ярд (0,764555 м3)';
								|en = 'Cubic yard (0.764555 m3)'; fa = 'Cubic yard (0.764555 m3)';
								|it = 'Yard cubo (0,764555 m3)';
								|pl = 'Jard sześcienny (0,764555 m3)';
								|tr = 'Yarda küp (0,764555 m3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'yard3';
										|ru = 'ярд3';
										|en = 'yd3'; fa = 'yd3';
										|it = 'yard3';
										|pl = 'yd3';
										|tr = 'yarda3'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "yd3"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'YARD3';
														|ru = 'ЯРДЗ';
														|en = 'YDQ'; fa = 'YDQ';
														|it = 'Yard3';
														|pl = 'YDQ';
														|tr = 'YARDA3'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "YDQ"; //@NON-NLS-1
	Level3.Numerator = 764.555;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "159";
	Level3.Description = NStr("vi = 'Triệu mét khối';
								|ru = 'Миллион кубических метров';
								|en = 'Million cubic meters'; fa = 'Million cubic meters';
								|it = 'Un milione di metri cubi';
								|pl = 'Milion metrów sześciennych';
								|tr = 'Milyon metreküp'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '10^6 m3';
										|ru = '10^6 м3';
										|en = '10^6 m3'; fa = '10^6 m3';
										|it = '10^6 m3';
										|pl = '10^6 m3';
										|tr = '10^6 m3'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "10^6 m3"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU M3';
														|ru = 'МЛН МЗ';
														|en = 'HMQ'; fa = 'HMQ';
														|it = 'Mln m3';
														|pl = 'MLN M3';
														|tr = 'MİLYON M3'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "HMQ"; //@NON-NLS-1
	Level3.Numerator = 1000000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "VolumeM3";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị trọng lượng';
								|ru = 'Единицы массы';
								|en = 'Units of mass'; fa = 'Units of mass';
								|it = 'Unità di massa';
								|pl = 'Jednostki masy';
								|tr = 'Ağırlık birimleri'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "160";
	Level3.Description = NStr("vi = 'Hectogram';
								|ru = 'Гектограмм';
								|en = 'Hectogram'; fa = 'Hectogram';
								|it = 'Ettogrammo';
								|pl = 'Hectogram';
								|tr = 'Hektogram'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'GG';
										|ru = 'гг';
										|en = 'HGM'; fa = 'HGM';
										|it = 'hg';
										|pl = 'HGM';
										|tr = 'HG'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "hg"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'GG';
														|ru = 'ГГ';
														|en = 'HGM'; fa = 'HGM';
														|it = 'hg';
														|pl = 'HGM';
														|tr = 'HG'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "HGM"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 10;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "161";
	Level3.Description = NStr("vi = 'Milligram';
								|ru = 'Миллиграмм';
								|en = 'Milligram'; fa = 'Milligram';
								|it = 'Milligrammo';
								|pl = 'Milligram';
								|tr = 'Miligram'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'MG';
										|ru = 'мг';
										|en = 'MGM'; fa = 'MGM';
										|it = 'мг';
										|pl = 'MGM';
										|tr = 'MG'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "mg"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MG';
														|ru = 'МГ';
														|en = 'MGM'; fa = 'MGM';
														|it = 'МГ';
														|pl = 'MGM';
														|tr = 'MG'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MGM"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "162";
	Level3.Description = NStr("vi = 'Carat theo hệ mét (1 carat = 200 mg = 2*0,0001 kg)';
								|ru = 'Метрический карат (1 карат = 200 мг = 2*0,0001 кг)';
								|en = 'Metric carat (1 carat = 200 mg = 2*0.0001 kg)'; fa = 'Metric carat (1 carat = 200 mg = 2*0.0001 kg)';
								|it = 'Carato metrico (1 carato = 200 mg = 2*0,0001 kg)';
								|pl = 'Karat metryczny (1 karat = 200 mg = 2*0,0001 kg)';
								|tr = 'Metrik karat (1 karat = 200 mg = 2*0.0001kg)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'car';
										|ru = 'кар';
										|en = 'ct'; fa = 'ct';
										|it = 'кар';
										|pl = 'ct';
										|tr = 'кар'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "МС"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'car';
														|ru = 'КАР';
														|en = 'CTM'; fa = 'CTM';
														|it = 'КАР';
														|pl = 'CTM';
														|tr = 'КАР'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CTM"; //@NON-NLS-1
	Level3.Numerator = 2;
	Level3.Denominator = 10000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "163";
	Level3.Description = NStr("vi = 'Gram';
								|ru = 'Грамм';
								|en = 'Gram'; fa = 'گرم';
								|it = 'Grammo';
								|pl = 'Gram';
								|tr = 'Gram'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'G';
										|ru = 'г';
										|en = 'G'; fa = 'G';
										|it = 'г';
										|pl = 'G';
										|tr = 'G'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "g"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'G';
														|ru = 'Г';
														|en = 'G'; fa = 'G';
														|it = 'Г';
														|pl = 'G';
														|tr = 'G'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "GRM"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "166";
	Level3.Description = NStr("vi = 'Kilogam';
								|ru = 'Килограмм';
								|en = 'Kilogram'; fa = 'کیلوگرم';
								|it = 'Kilogrammo';
								|pl = 'Kilogram';
								|tr = 'Kilogram'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kg';
										|ru = 'кг';
										|en = 'kg'; fa = 'kg';
										|it = 'кг';
										|pl = 'kg';
										|tr = 'kg'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kg"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'kg';
														|ru = 'КГ';
														|en = 'kg'; fa = 'kg';
														|it = 'КГ';
														|pl = 'kg';
														|tr = 'kg'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KGM"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "168";
	Level3.Description = NStr("vi = 'Tấn (1000 kg)';
								|ru = 'Тонна (Метрическая тонна) (1000 кг)';
								|en = 'Ton (metric ton) (1,000 kg)'; fa = 'Ton (metric ton) (1,000 kg)';
								|it = 'Tonnellata (Tonnellata metrica) (1000 kg)';
								|pl = 'Tona (Tona metryczna) (1000 kg)';
								|tr = 'Ton (Metrik ton) (1000 kg)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 't';
										|ru = 'т';
										|en = 't'; fa = 't';
										|it = 'т';
										|pl = 't';
										|tr = 't'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "t"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Tl';
														|ru = 'ТЛ';
														|en = 't'; fa = 't';
														|it = 'ТЛ';
														|pl = 't';
														|tr = 'Tl'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "TNE"; //@NON-NLS-1
	Level3.Numerator = 1000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "170";
	Level3.Description = NStr("vi = 'Kiloton';
								|ru = 'Килотонна';
								|en = 'Kiloton'; fa = 'Kiloton';
								|it = 'Kiloton';
								|pl = 'Kiloton';
								|tr = 'Kiloton'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '10^3 t';
										|ru = '10^3 т';
										|en = '10^3 t'; fa = '10^3 t';
										|it = '10^3 т';
										|pl = '10^3 t';
										|tr = '10^3 ton'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kt"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KT';
														|ru = 'КТ';
														|en = 'KTN'; fa = 'KTN';
														|it = 'KT';
														|pl = 'KTN';
														|tr = 'Alacak'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KTN"; //@NON-NLS-1
	Level3.Numerator = 1000000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "173";
	Level3.Description = NStr("vi = 'Santigram';
								|ru = 'Сантиграмм';
								|en = 'Centigram'; fa = 'Centigram';
								|it = 'Centigrammo';
								|pl = 'Centigram';
								|tr = 'Santigram'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'SG';
										|ru = 'сг';
										|en = 'CGM'; fa = 'CGM';
										|it = 'сг';
										|pl = 'CGM';
										|tr = 'SG'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "cg"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'SG';
														|ru = 'СГ';
														|en = 'CGM'; fa = 'CGM';
														|it = 'СГ';
														|pl = 'CGM';
														|tr = 'SG'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CGM"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 100000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "181";
	Level3.Description = NStr("vi = 'Tấn đăng ký (2,8316 m3)';
								|ru = 'Брутто - регистровая тонна (2,8316 м3)';
								|en = 'Gross register tonnage (2.8316 m3)'; fa = 'Gross register tonnage (2.8316 m3)';
								|it = 'Tonnellata di stazza lorda (2,8316 m3)';
								|pl = 'Brutto - tona rejestrowa (2,8316 m3)';
								|tr = 'Brüt - kayıtlı ton (2.8316 m3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'tấn đăng ký';
										|ru = 'БРТ';
										|en = 'GR T'; fa = 'GR T';
										|it = 'TSL';
										|pl = 'GR T';
										|tr = 'BRÜT'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TẤN ĐĂNG KÝ';
														|ru = 'БРУТТ. РЕГИСТР Т';
														|en = 'GRT'; fa = 'GRT';
														|it = 'TONNELLATA DI STAZZA LORDA';
														|pl = 'BRUTT. T REJESTR';
														|tr = 'BRÜT. KAYITLI TON'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "GRT"; //@NON-NLS-1
	Level3.Numerator = 283.16;
	Level3.Denominator = 100;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "185";
	Level3.Description = NStr("vi = 'Công suất nâng tính bằng tấn';
								|ru = 'Грузоподъемность в метрических тоннах';
								|en = 'Carrying capacity in metric ton'; fa = 'Carrying capacity in metric ton';
								|it = 'Capacità di carico in tonnellate metriche';
								|pl = 'Ładowność w tonach metrycznych';
								|tr = 'Metrik ton cinsinden kapasite'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Công suất nâng tính bằng tấn';
										|ru = 'т грп';
										|en = 'cct'; fa = 'cct';
										|it = 'TPL';
										|pl = 't nośn';
										|tr = 'ton kapasite'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Công suất nâng tính bằng tấn';
														|ru = 'Т ГРУЗОПОД';
														|en = 'CCT S'; fa = 'CCT S';
														|it = 'T DI CARICO';
														|pl = 'T NOŚN';
														|tr = 'TON KAPASİTE'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CCT"; //@NON-NLS-1
	Level3.Numerator = 1000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "206";
	Level3.Description = NStr("vi = 'Centner (100 kg, Hectokilogram, Quintal, Deciton)';
								|ru = 'Центнер (метрический) (100 кг, Гектокилограмм, Квинтал (метрический), Децитонна)';
								|en = 'Decitonne'; fa = 'Decitonne';
								|it = 'Quintale (metrico) (100 kg, Decitonnellata)';
								|pl = 'Kwintal (metryczny) (100 kg, Hektokilogram, Kwintal (metryczny), Decytona)';
								|tr = 'Centner (metrik) (100 kg, Hektokilogram, Kental (metrik), Ondalık ton)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'c';
										|ru = 'ц';
										|en = '10^2kg'; fa = '10^2kg';
										|it = 'ц';
										|pl = '10^2kg';
										|tr = 's'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "q (100 kg)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'c';
														|ru = 'Ц';
														|en = '10^2kg'; fa = '10^2kg';
														|it = 'Ц';
														|pl = '10^2kg';
														|tr = 's'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DTN"; //@NON-NLS-1
	Level3.Numerator = 100;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Weight";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị kỹ thuật';
								|ru = 'Технические единицы';
								|en = 'Engineering units'; fa = 'Engineering units';
								|it = 'Unità di misura tecniche';
								|pl = 'Jednostki techniczne';
								|tr = 'Teknik birimler'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "212";
	Level3.Description = NStr("vi = 'Watt';
								|ru = 'Ватт';
								|en = 'Watt'; fa = 'Watt';
								|it = 'Watt';
								|pl = 'Watt';
								|tr = 'Watt'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'W';
										|ru = 'Вт';
										|en = 'W'; fa = 'W';
										|it = 'Вт';
										|pl = 'W';
										|tr = 'W'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "W"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'W';
														|ru = 'ВТ';
														|en = 'W'; fa = 'W';
														|it = 'ВТ';
														|pl = 'W';
														|tr = 'W'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "WTT"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Capacity";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "214";
	Level3.Description = NStr("vi = 'Kilowatt';
								|ru = 'Киловатт';
								|en = 'Kilowatt'; fa = 'Kilowatt';
								|it = 'Kilowatt';
								|pl = 'Kilowatt';
								|tr = 'Kilovat'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kW';
										|ru = 'кВт';
										|en = 'kW'; fa = 'kW';
										|it = 'кВт';
										|pl = 'kW';
										|tr = 'kW'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kW"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'kW';
														|ru = 'КВТ';
														|en = 'kW'; fa = 'kW';
														|it = 'КВТ';
														|pl = 'kW';
														|tr = 'kW'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KWT"; //@NON-NLS-1
	Level3.Numerator = 1000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Capacity";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "215";
	Level3.Description = NStr("vi = 'Megawatt (Ngàn kilowatt)';
								|ru = 'Мегаватт (Тысяча киловатт)';
								|en = 'Megawatt (One thousand kilowatts)'; fa = 'Megawatt (One thousand kilowatts)';
								|it = 'Megawatt (Mille kilowatt)';
								|pl = 'Megawat (tysiąc kilowat)';
								|tr = 'Megawatt (Bin kilowatt)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'MW (1000 kw)';
										|ru = 'МВт (1000 кВт)';
										|en = 'MW (1,000 kW)'; fa = 'MW (1,000 kW)';
										|it = 'MW (1000 kW)';
										|pl = 'MW (1000 kW)';
										|tr = 'MWt (1000 kWt)'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "MW"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MEGAWATT (NGHÌN KWh)';
														|ru = 'МЕГАВТ (ТЫС КВТ)';
														|en = 'MAW (THOUS KWT)'; fa = 'MAW (THOUS KWT)';
														|it = 'MW (mille kW)';
														|pl = 'MEGAW (TYS kW)';
														|tr = 'MEGAWT (BIN KWT)'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MAW"; //@NON-NLS-1
	Level3.Numerator = 1000000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Capacity";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "222";
	Level3.Description = NStr("vi = 'Vôn';
								|ru = 'Вольт';
								|en = 'Volt'; fa = 'Volt';
								|it = 'Volt';
								|pl = 'Volt';
								|tr = 'Volt'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'V';
										|ru = 'В';
										|en = 'V'; fa = 'V';
										|it = 'V';
										|pl = 'V';
										|tr = 'İçinde'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "V"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'V';
														|ru = 'В';
														|en = 'V'; fa = 'V';
														|it = 'V';
														|pl = 'V';
														|tr = 'İçinde'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "VLT"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "223";
	Level3.Description = NStr("vi = 'Kilovôn';
								|ru = 'Киловольт';
								|en = 'Kilovolt'; fa = 'Kilovolt';
								|it = 'Kilovolt';
								|pl = 'Kilovolt';
								|tr = 'Kilovolt'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'KW';
										|ru = 'кВ';
										|en = 'KVT'; fa = 'KVT';
										|it = 'кВ';
										|pl = 'KVT';
										|tr = 'ÇY'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kV"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KW';
														|ru = 'КВ';
														|en = 'KVT'; fa = 'KVT';
														|it = 'КВ';
														|pl = 'KVT';
														|tr = 'ÇY'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KVT"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "227";
	Level3.Description = NStr("vi = 'Kilovolt - ampe';
								|ru = 'Киловольт - ампер';
								|en = 'Kilovolt-ampere'; fa = 'Kilovolt-ampere';
								|it = 'Kilovolt - ampere';
								|pl = 'Kilowatoamper';
								|tr = 'Kilovolt - amper'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kV.A';
										|ru = 'кВ.А';
										|en = 'KVA'; fa = 'KVA';
										|it = 'кВ.А';
										|pl = 'KVA';
										|tr = 'KB.A'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kV.A"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'kV.A';
														|ru = 'КВ.А';
														|en = 'KVA'; fa = 'KVA';
														|it = 'КВ.А';
														|pl = 'KVA';
														|tr = 'KB.A'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KVA"; //@NON-NLS-1
	Level3.Numerator = 1000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Capacity";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "228";
	Level3.Description = NStr("vi = 'Megavolt-ampe (1,000 kilovolt-ampe)';
								|ru = 'Мегавольт - ампер (тысяча киловольт - ампер)';
								|en = 'Megavolt-ampere (thousand kilovolt-ampere)'; fa = 'Megavolt-ampere (thousand kilovolt-ampere)';
								|it = 'Megavolt - ampere (mille kilovolt - ampere)';
								|pl = 'Megawoltoamper (tysiąc kilowoltoamper)';
								|tr = 'Megavolt - amper (bin kilovolt - amper)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'MV.A';
										|ru = 'МВ.А';
										|en = 'MV.A'; fa = 'MV.A';
										|it = 'MVA';
										|pl = 'MV.A';
										|tr = 'MV.A'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "MV.A"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MEGAW.A';
														|ru = 'МЕГАВ.А';
														|en = 'MVA'; fa = 'MVA';
														|it = 'MWA';
														|pl = 'MVA';
														|tr = 'MEGAV.A'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MVA"; //@NON-NLS-1
	Level3.Numerator = 10000000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Capacity";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "230";
	Level3.Description = NStr("vi = 'Kilovar';
								|ru = 'Киловар';
								|en = 'Kilovar'; fa = 'Kilovar';
								|it = 'KiloVoltAmpere reattivo';
								|pl = 'Kilovar';
								|tr = 'Kilovar'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kvar';
										|ru = 'квар';
										|en = 'kVAR'; fa = 'kVAR';
										|it = 'квар';
										|pl = 'kVAR';
										|tr = 'çeyrek'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kVAR"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'kvar';
														|ru = 'КВАР';
														|en = 'kVAR'; fa = 'kVAR';
														|it = 'КВАР';
														|pl = 'kVAR';
														|tr = 'çeyrek'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KVR"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "243";
	Level3.Description = NStr("vi = 'Watt - giờ';
								|ru = 'Ватт - час';
								|en = 'Watt-hour'; fa = 'Watt-hour';
								|it = 'Wattora';
								|pl = 'Watogodzina';
								|tr = 'Watt - saat'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'W.H';
										|ru = 'Вт.ч';
										|en = 'WHR'; fa = 'WHR';
										|it = 'Вт.ч';
										|pl = 'WHR';
										|tr = 'Wt.Saat'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "W.h"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'W.H';
														|ru = 'ВТ.Ч';
														|en = 'WHR'; fa = 'WHR';
														|it = 'ВТ.Ч';
														|pl = 'WHR';
														|tr = 'Wt.Saat'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "WHR"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Energy";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "245";
	Level3.Description = NStr("vi = 'Kilowatt - giờ';
								|ru = 'Киловатт - час';
								|en = 'Kilowatt-hour'; fa = 'کیلووات‌ساعت';
								|it = 'Kilowattora';
								|pl = 'Kilowatogodzina';
								|tr = 'Kilowatt saat'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'KW.H';
										|ru = 'кВт.ч';
										|en = 'KWH'; fa = 'KWH';
										|it = 'кВт.ч';
										|pl = 'KWH';
										|tr = 'kWt.Saat'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kW.h"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KW.H';
														|ru = 'КВТ.Ч';
														|en = 'KWH'; fa = 'KWH';
														|it = 'КВТ.Ч';
														|pl = 'KWH';
														|tr = 'kWt.Saat'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KWH"; //@NON-NLS-1
	Level3.Numerator = 1000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Energy";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "246";
	Level3.Description = NStr("vi = 'Megawatt - giờ (1000 kilowatt - giờ)';
								|ru = 'Мегаватт - час (1000 киловатт - часов)';
								|en = 'Megawatt-hour (1,000 kilowatt-hours)'; fa = 'Megawatt-hour (1,000 kilowatt-hours)';
								|it = 'Megawattora (1000 kilowattora)';
								|pl = 'MWh (1000 kilowatogodzin)';
								|tr = 'Megawatt - saat (1000 kilowatt - saat)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Mw.h (1000 kW.h)';
										|ru = 'МВт.ч (1000 кВт.ч)';
										|en = 'MW.h (1,000 kW.h)'; fa = 'MW.h (1,000 kW.h)';
										|it = 'MWh (1000 kWh)';
										|pl = 'MWh (1000 kWh)';
										|tr = 'MWt.s (1000 kWs)'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "МW.h"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MEGAW.H (NGHÌN KW.H)';
														|ru = 'МЕГАВТ.Ч (ТЫС КВТ.Ч)';
														|en = 'MWH (THOUS KWH)'; fa = 'MWH (THOUS KWH)';
														|it = 'MWh (mille kWh)';
														|pl = 'MEGAWh (TYS kWh)';
														|tr = 'MEGAWT. (BIN KWT.S)'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MWH"; //@NON-NLS-1
	Level3.Numerator = 1000000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Energy";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "247";
	Level3.Description = NStr("vi = 'Gigawatt - giờ (million kilowatt - giờ)';
								|ru = 'Гигаватт - час (миллион киловатт - часов)';
								|en = 'Gigawatt-hour (million kilowatt-hours)'; fa = 'Gigawatt-hour (million kilowatt-hours)';
								|it = 'Gigawattora (un milione di kilowattora)';
								|pl = 'Gigawatogodzina (milion kilowatogodzin)';
								|tr = 'Gigawatt - saat (milyon kilowatt - saat)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'GW.h';
										|ru = 'ГВт.ч';
										|en = 'GW.h'; fa = 'GW.h';
										|it = 'GWh';
										|pl = 'GW.h';
										|tr = 'GWt.s'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "GW.h"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'GIGAW.H';
														|ru = 'ГИГАВТ.Ч';
														|en = 'GWH'; fa = 'GWH';
														|it = 'GWh';
														|pl = 'GWH';
														|tr = 'GİGAWT.S'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "GWH"; //@NON-NLS-1
	Level3.Numerator = 1000000000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Energy";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "260";
	Level3.Description = NStr("vi = 'Ampe';
								|ru = 'Ампер';
								|en = 'Ampere'; fa = 'Ampere';
								|it = 'Ampere';
								|pl = 'Ampere';
								|tr = 'Amper'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'A';
										|ru = 'А';
										|en = 'A'; fa = 'A';
										|it = 'A';
										|pl = 'A';
										|tr = 'A'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "A"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'A';
														|ru = 'А';
														|en = 'A'; fa = 'A';
														|it = 'А';
														|pl = 'A';
														|tr = 'A'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "AMP"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "263";
	Level3.Description = NStr("vi = 'Ampe - giờ (3.6 kC)';
								|ru = 'Ампер - час (3,6 кКл)';
								|en = 'Ampere-hour (3.6 kC)'; fa = 'Ampere-hour (3.6 kC)';
								|it = 'Ampere-ora (3,6 kC)';
								|pl = 'Amperogodzina (3,6 kC)';
								|tr = 'Amper -saat (3,6 kKl)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'A.h';
										|ru = 'А.ч';
										|en = 'A.h'; fa = 'A.h';
										|it = 'Ah';
										|pl = 'A.h';
										|tr = 'Ah'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "A.h"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'A.h';
														|ru = 'А.Ч';
														|en = 'A.h'; fa = 'A.h';
														|it = 'Ah';
														|pl = 'A.h';
														|tr = 'Ah'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "AMH"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "ElectricCharge";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "264";
	Level3.Description = NStr("vi = '1000 ampe - giờ';
								|ru = 'Тысяча ампер - часов';
								|en = 'Thousand ampere-hours'; fa = 'Thousand ampere-hours';
								|it = 'Mille ampere-ora';
								|pl = 'Tysiąc amperogodzin';
								|tr = 'Bin amper - saat'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '1000 A.h';
										|ru = '1000 А.ч';
										|en = '1,000 A.h'; fa = '1,000 A.h';
										|it = '1000 Ah';
										|pl = '1000 Ah';
										|tr = '1000 A.s'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "1000 A.h"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN A.H';
														|ru = 'ТЫС А.Ч';
														|en = 'TAH'; fa = 'TAH';
														|it = 'Mille ah';
														|pl = 'TYS. Ah';
														|tr = 'BİN A.S'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "TAH"; //@NON-NLS-1
	Level3.Numerator = 1000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "ElectricCharge";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "270";
	Level3.Description = NStr("vi = 'Coulomb';
								|ru = 'Кулон';
								|en = 'Coulomb'; fa = 'Coulomb';
								|it = 'Coulomb';
								|pl = 'Coulomb';
								|tr = 'Kulon'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'C';
										|ru = 'Кл';
										|en = 'C'; fa = 'C';
										|it = 'Кл';
										|pl = 'C';
										|tr = 'KL'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "C"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'C';
														|ru = 'КЛ';
														|en = 'C'; fa = 'C';
														|it = 'КЛ';
														|pl = 'C';
														|tr = 'KL'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "COU"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "271";
	Level3.Description = NStr("vi = 'Joule';
								|ru = 'Джоуль';
								|en = 'Joule'; fa = 'Joule';
								|it = 'Joule';
								|pl = 'Joule';
								|tr = 'Jul'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'J';
										|ru = 'Дж';
										|en = 'J'; fa = 'J';
										|it = 'Дж';
										|pl = 'J';
										|tr = 'JL'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "J"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'J';
														|ru = 'ДЖ';
														|en = 'J'; fa = 'J';
														|it = 'ДЖ';
														|pl = 'J';
														|tr = 'JL'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "JOU"; //@NON-NLS-1
	Level3.Numerator = 3600;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Energy";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "273";
	Level3.Description = NStr("vi = 'Kilojoule';
								|ru = 'Килоджоуль';
								|en = 'Kilojoule'; fa = 'Kilojoule';
								|it = 'Kilojoule';
								|pl = 'Kilojoule';
								|tr = 'Kilojul'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kJ';
										|ru = 'кДж';
										|en = 'kJ'; fa = 'kJ';
										|it = 'кДж';
										|pl = 'kJ';
										|tr = 'kJ'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kJ"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'kJ';
														|ru = 'КДЖ';
														|en = 'kJ'; fa = 'kJ';
														|it = 'КДЖ';
														|pl = 'kJ';
														|tr = 'kJ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KJO"; //@NON-NLS-1
	Level3.Numerator = 3600000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Energy";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "274";
	Level3.Description = NStr("vi = 'OM';
								|ru = 'Ом';
								|en = 'Ohm'; fa = 'Ohm';
								|it = 'Ом';
								|pl = 'Ohm';
								|tr = 'Ом'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'OM';
										|ru = 'Ом';
										|en = 'Ohm'; fa = 'Ohm';
										|it = 'Ом';
										|pl = 'Ohm';
										|tr = 'Ом'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "Омега"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'OM';
														|ru = 'ОМ';
														|en = 'OHM'; fa = 'OHM';
														|it = 'ОМ';
														|pl = 'OHM';
														|tr = 'ОМ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "OHM"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "280";
	Level3.Description = NStr("vi = 'Độ C';
								|ru = 'Градус Цельсия';
								|en = 'Degree Celsius'; fa = 'Degree Celsius';
								|it = 'Grado Celsius';
								|pl = 'Stopień Celsjusza';
								|tr = 'Santigrat derecesi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '°С';
										|ru = '°С';
										|en = '°C'; fa = '°C';
										|it = '°C';
										|pl = '°C';
										|tr = '°C'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "°С"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ĐỘ C';
														|ru = 'ГРАД ЦЕЛЬС';
														|en = 'CEL'; fa = 'CEL';
														|it = 'Grado Celsius';
														|pl = 'STOPNI CELSJUSZA';
														|tr = 'SANTİGRAT DERECESİ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CEL"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "281";
	Level3.Description = NStr("vi = 'Độ F';
								|ru = 'Градус Фаренгейта';
								|en = 'Degree Fahrenheit'; fa = 'Degree Fahrenheit';
								|it = 'Grado Fahrenheit';
								|pl = 'Stopień Fahrenheita';
								|tr = 'Fahrenhayt derecesi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '°F';
										|ru = '°F';
										|en = '°F'; fa = '°F';
										|it = '°F';
										|pl = '°F';
										|tr = '°F'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "°F"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Độ F';
														|ru = 'ГРАД ФАРЕНГ';
														|en = 'FAN'; fa = 'FAN';
														|it = 'Grado Fahrenheit';
														|pl = 'STOPNI FAHRENHEITA';
														|tr = 'FAHRENHAYT DERECESİ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "FAN"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "282";
	Level3.Description = NStr("vi = 'Candela';
								|ru = 'Кандела';
								|en = 'Candela'; fa = 'Candela';
								|it = 'Candela';
								|pl = 'Candela';
								|tr = 'Kandela'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'cd';
										|ru = 'кд';
										|en = 'CD'; fa = 'CD';
										|it = 'кд';
										|pl = 'CD';
										|tr = 'CD'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "cd"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'cd';
														|ru = 'КД';
														|en = 'CD'; fa = 'CD';
														|it = 'КД';
														|pl = 'CD';
														|tr = 'CD'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CDL"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "283";
	Level3.Description = NStr("vi = 'Lux';
								|ru = 'Люкс';
								|en = 'Lux'; fa = 'Lux';
								|it = 'Lux';
								|pl = 'Lux';
								|tr = 'Lüks'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'lx';
										|ru = 'лк';
										|en = 'lx'; fa = 'lx';
										|it = 'лк';
										|pl = 'lx';
										|tr = 'lk'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "lx"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'lx';
														|ru = 'ЛК';
														|en = 'lx'; fa = 'lx';
														|it = 'ЛК';
														|pl = 'lx';
														|tr = 'lk'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "LUX"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "284";
	Level3.Description = NStr("vi = 'Lumen';
								|ru = 'Люмен';
								|en = 'Lumen'; fa = 'Lumen';
								|it = 'Lumen';
								|pl = 'Lumen';
								|tr = 'Lümen'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'lm';
										|ru = 'лм';
										|en = 'lm'; fa = 'lm';
										|it = 'лм';
										|pl = 'lm';
										|tr = 'lm'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "lm"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'lm';
														|ru = 'ЛМ';
														|en = 'lm'; fa = 'lm';
														|it = 'ЛМ';
														|pl = 'lm';
														|tr = 'lm'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "LUM"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "288";
	Level3.Description = NStr("vi = 'Kelvin';
								|ru = 'Кельвин';
								|en = 'Kelvin'; fa = 'Kelvin';
								|it = 'Kelvin';
								|pl = 'Kelvin';
								|tr = 'Kelvin'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'K';
										|ru = 'K';
										|en = 'K'; fa = 'K';
										|it = 'K';
										|pl = 'K';
										|tr = 'K'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "K"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'K';
														|ru = 'К';
														|en = 'K'; fa = 'K';
														|it = 'A';
														|pl = 'K';
														|tr = 'K'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KEL"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "289";
	Level3.Description = NStr("vi = 'Newton';
								|ru = 'Ньютон';
								|en = 'Newton'; fa = 'Newton';
								|it = 'Newton';
								|pl = 'Newton';
								|tr = 'Newton'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'N';
										|ru = 'Н';
										|en = 'N'; fa = 'ش';
										|it = 'N';
										|pl = 'N';
										|tr = 'N'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "N"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'N';
														|ru = 'Н';
														|en = 'N'; fa = 'ش';
														|it = 'N';
														|pl = 'N';
														|tr = 'N'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "NEW"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "290";
	Level3.Description = NStr("vi = 'Hertz';
								|ru = 'Герц';
								|en = 'Hertz'; fa = 'Hertz';
								|it = 'Hertz';
								|pl = 'Hertz';
								|tr = 'Hertz'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'HZ';
										|ru = 'Гц';
										|en = 'HTZ'; fa = 'HTZ';
										|it = 'Гц';
										|pl = 'HTZ';
										|tr = 'Hz'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "Hz"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'HZ';
														|ru = 'ГЦ';
														|en = 'HTZ'; fa = 'HTZ';
														|it = 'ГЦ';
														|pl = 'HTZ';
														|tr = 'Hz'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "HTZ"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "291";
	Level3.Description = NStr("vi = 'Kilohertz';
								|ru = 'Килогерц';
								|en = 'Kilohertz'; fa = 'Kilohertz';
								|it = 'Kilohertz';
								|pl = 'Kilohertz';
								|tr = 'Kilohertz'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'KHZ';
										|ru = 'кГц';
										|en = 'KHZ'; fa = 'KHZ';
										|it = 'кГц';
										|pl = 'KHZ';
										|tr = 'kHz'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kHz"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KHZ';
														|ru = 'КГЦ';
														|en = 'KHZ'; fa = 'KHZ';
														|it = 'КГЦ';
														|pl = 'KHZ';
														|tr = 'kHz'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KHZ"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "292";
	Level3.Description = NStr("vi = 'Megahertz';
								|ru = 'Мегагерц';
								|en = 'Megahertz'; fa = 'Megahertz';
								|it = 'Megahertz';
								|pl = 'Megahertz';
								|tr = 'Megahertz'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'MHz';
										|ru = 'МГц';
										|en = 'MHz'; fa = 'MHz';
										|it = 'MHz';
										|pl = 'MHz';
										|tr = 'MHz'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "MHz"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MEGAHZ';
														|ru = 'МЕГАГЦ';
														|en = 'M HZ'; fa = 'M HZ';
														|it = 'MHz';
														|pl = 'M HZ';
														|tr = 'MEGAHZ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MHZ"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "294";
	Level3.Description = NStr("vi = 'Pascal';
								|ru = 'Паскаль';
								|en = 'Pascal'; fa = 'Pascal';
								|it = 'Pascal';
								|pl = 'Pascal';
								|tr = 'Paskal'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Pa';
										|ru = 'Па';
										|en = 'Pa'; fa = 'Pa';
										|it = 'Па';
										|pl = 'Pa';
										|tr = 'Pa'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "Pa"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Pa';
														|ru = 'ПА';
														|en = 'Pa'; fa = 'Pa';
														|it = 'ПА';
														|pl = 'Pa';
														|tr = 'Pa'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "PAL"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "296";
	Level3.Description = NStr("vi = 'Siemens';
								|ru = 'Сименс';
								|en = 'Siemens'; fa = 'Siemens';
								|it = 'Siemens';
								|pl = 'Siemens';
								|tr = 'Siemens'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'cm';
										|ru = 'См';
										|en = 'S'; fa = 'S';
										|it = 'См';
										|pl = 'S';
										|tr = 'Cm'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "S"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'SI';
														|ru = 'СИ';
														|en = 'SIE'; fa = 'SIE';
														|it = 'Si';
														|pl = 'SIE';
														|tr = 'Sİ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "SIE"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "297";
	Level3.Description = NStr("vi = 'Kilopascal';
								|ru = 'Килопаскаль';
								|en = 'Kilopascal'; fa = 'Kilopascal';
								|it = 'Kilopascal';
								|pl = 'Kilopascal';
								|tr = 'Kilopaskal'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'KPA';
										|ru = 'кПа';
										|en = 'KPA'; fa = 'KPA';
										|it = 'кПа';
										|pl = 'KPA';
										|tr = 'kPa'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kPa"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KPA';
														|ru = 'КПА';
														|en = 'KPA'; fa = 'KPA';
														|it = 'КПА';
														|pl = 'KPA';
														|tr = 'kPa'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KPA"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "298";
	Level3.Description = NStr("vi = 'Megapascal';
								|ru = 'Мегапаскаль';
								|en = 'Megapascal'; fa = 'Megapascal';
								|it = 'Megapascal';
								|pl = 'Megapascal';
								|tr = 'Megapaskal'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'MPa';
										|ru = 'МПа';
										|en = 'MPa'; fa = 'MPa';
										|it = 'MPa';
										|pl = 'MPa';
										|tr = 'MPa'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "MPa"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MEGAPA';
														|ru = 'МЕГАПА';
														|en = 'M PA'; fa = 'M PA';
														|it = 'MPa';
														|pl = 'M PA';
														|tr = 'MEGAPA'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MPA"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "300";
	Level3.Description = NStr("vi = 'Khí quyển vật lý (101325 Pa)';
								|ru = 'Физическая атмосфера (101325 Па)';
								|en = 'Standard atmosphere (101,325 Pa)'; fa = 'Standard atmosphere (101,325 Pa)';
								|it = 'Atmosfera fisica (101325 Pa)';
								|pl = 'Atmosfera fizyczna (101325 Pa)';
								|tr = 'Fiziksel atmosfer (101325 Pa)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'atm';
										|ru = 'атм';
										|en = 'atm'; fa = 'atm';
										|it = 'атм';
										|pl = 'atm';
										|tr = 'atm'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "atm"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'atm';
														|ru = 'АТМ';
														|en = 'atm'; fa = 'atm';
														|it = 'АТМ';
														|pl = 'atm';
														|tr = 'atm'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "ATM"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "301";
	Level3.Description = NStr("vi = 'Khí quyển kỹ thuật (98066,5 Pa)';
								|ru = 'Техническая атмосфера (98066,5 Па)';
								|en = 'Technical atmosphere (98,066.5 Pa)'; fa = 'Technical atmosphere (98,066.5 Pa)';
								|it = 'Atmosfera tecnica (98066,5 Pa)';
								|pl = 'Atmosfera techniczna (98066,5 Pa)';
								|tr = 'Teknik atmosfer (98066,5 Pa)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'at';
										|ru = 'ат';
										|en = 'at'; fa = 'at';
										|it = 'at';
										|pl = 'at';
										|tr = 'at'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "at"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ATT';
														|ru = 'АТТ';
														|en = 'ATT'; fa = 'ATT';
														|it = 'ATT';
														|pl = 'ATT';
														|tr = 'TEKNİK ATMOSFER'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "ATT"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "302";
	Level3.Description = NStr("vi = 'Gigabecquerel';
								|ru = 'Гигабеккерель';
								|en = 'Gigabecquerel'; fa = 'Gigabecquerel';
								|it = 'Gigabecquerel';
								|pl = 'Gigabecquerel';
								|tr = 'Gigabekerel'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'GBq';
										|ru = 'ГБк';
										|en = 'GBq'; fa = 'GBq';
										|it = 'Gbq';
										|pl = 'GBq';
										|tr = 'GBk'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "GBq"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'GBQ';
														|ru = 'ГИГАБК';
														|en = 'GB Q'; fa = 'GB Q';
														|it = 'Gbq';
														|pl = 'GB Q';
														|tr = 'GİGABK'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "GBQ"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "304";
	Level3.Description = NStr("vi = 'Millicury';
								|ru = 'Милликюри';
								|en = 'Millicurie'; fa = 'Millicurie';
								|it = 'Millicurie';
								|pl = 'Millicurie';
								|tr = 'Millicurie'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'mCi';
										|ru = 'мКи';
										|en = 'mCi'; fa = 'mCi';
										|it = 'mCi';
										|pl = 'mCi';
										|tr = 'mCr'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "mCi"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'mCi';
														|ru = 'МКИ';
														|en = 'mCi'; fa = 'mCi';
														|it = 'mCi';
														|pl = 'mCi';
														|tr = 'mCr'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MCU"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "305";
	Level3.Description = NStr("vi = 'Curie';
								|ru = 'Кюри';
								|en = 'Curie'; fa = 'Curie';
								|it = 'Curie';
								|pl = 'Curie';
								|tr = 'Curie'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Ci';
										|ru = 'Ки';
										|en = 'CUR'; fa = 'CUR';
										|it = 'Ки';
										|pl = 'CUR';
										|tr = 'İB'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "Ci"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Ci';
														|ru = 'КИ';
														|en = 'CUR'; fa = 'CUR';
														|it = 'КИ';
														|pl = 'CUR';
														|tr = 'İB'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CUR"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "306";
	Level3.Description = NStr("vi = 'Gram đồng vị phân hạch';
								|ru = 'Грамм делящихся изотопов';
								|en = 'Gram of fissile isotopes'; fa = 'Gram of fissile isotopes';
								|it = 'Grammo di isotopi fissili';
								|pl = 'Gram izotopów rozczepialnych';
								|tr = 'Bölünebilir izotopların gramı'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'g đồng vị phân hạch';
										|ru = 'г Д/И';
										|en = 'g fissile isotopes'; fa = 'g fissile isotopes';
										|it = 'GRAMMO DI ISOTOPI FISSILI';
										|pl = 'g I/R';
										|tr = 'B/İ gr'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "g fissile isotopes"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'GFI';
														|ru = 'Г ДЕЛЯЩ ИЗОТОП';
														|en = 'GFI'; fa = 'GFI';
														|it = 'G Isotopo fissile';
														|pl = 'G IZOTOP ROZCZEP';
														|tr = 'BÖLÜNEBİLİR İZOTOPLARIN GR '", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "GFI"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "308";
	Level3.Description = NStr("vi = 'Millibar';
								|ru = 'Миллибар';
								|en = 'Millibar'; fa = 'Millibar';
								|it = 'Millibar';
								|pl = 'Millibar';
								|tr = 'Milibar'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'mb';
										|ru = 'мб';
										|en = 'mbar'; fa = 'mbar';
										|it = 'mBar';
										|pl = 'mbar';
										|tr = 'mb'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "mbar"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MBAR';
														|ru = 'МБАР';
														|en = 'MBR'; fa = 'MBR';
														|it = 'mBar';
														|pl = 'MBR';
														|tr = 'MBAR'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MBR"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "309";
	Level3.Description = NStr("vi = 'bar';
								|ru = 'Бар';
								|en = 'Bar'; fa = 'Bar';
								|it = 'Бар';
								|pl = 'Bar';
								|tr = 'Bar'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'bar';
										|ru = 'бар';
										|en = 'Bar'; fa = 'Bar';
										|it = 'бар';
										|pl = 'Bar';
										|tr = 'Bar'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "bar"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'bar';
														|ru = 'БАР';
														|en = 'Bar'; fa = 'Bar';
														|it = 'БАР';
														|pl = 'Bar';
														|tr = 'Bar'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "BAR"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "310";
	Level3.Description = NStr("vi = 'Gectobar';
								|ru = 'Гектобар';
								|en = 'Hectobar'; fa = 'Hectobar';
								|it = 'Ettobar';
								|pl = 'Hectobar';
								|tr = 'Hektobar'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'gb';
										|ru = 'гб';
										|en = 'hbar'; fa = 'hbar';
										|it = 'hbar';
										|pl = 'hbar';
										|tr = 'hb'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "hbar"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'HBA';
														|ru = 'ГБАР';
														|en = 'HBA'; fa = 'HBA';
														|it = 'Gbar';
														|pl = 'HBA';
														|tr = 'GBAR'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "HBA"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "312";
	Level3.Description = NStr("vi = 'Kilobar';
								|ru = 'Килобар';
								|en = 'Kilobar'; fa = 'Kilobar';
								|it = 'Kilobar';
								|pl = 'Kilobar';
								|tr = 'Kilobar'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kb';
										|ru = 'кб';
										|en = 'kbar'; fa = 'kbar';
										|it = 'Kbar';
										|pl = 'kbar';
										|tr = 'kb'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kbar"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KBAR';
														|ru = 'КБАР';
														|en = 'KBA'; fa = 'KBA';
														|it = 'Kbar';
														|pl = 'KBA';
														|tr = 'KBAR'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KBA"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "314";
	Level3.Description = NStr("vi = 'Farad';
								|ru = 'Фарад';
								|en = 'Farad'; fa = 'Farad';
								|it = 'Farad';
								|pl = 'Farad';
								|tr = 'Farad'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'F';
										|ru = 'Ф';
										|en = 'F'; fa = 'F';
										|it = 'F';
										|pl = 'F';
										|tr = 'F'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "F"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'F';
														|ru = 'Ф';
														|en = 'F'; fa = 'F';
														|it = 'F';
														|pl = 'F';
														|tr = 'F'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "FAR"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "316";
	Level3.Description = NStr("vi = 'Kilogam trên Mét khối';
								|ru = 'Килограмм на кубический метр';
								|en = 'Kilogram per cubic meter'; fa = 'Kilogram per cubic meter';
								|it = 'Kilogrammo per metro cubo';
								|pl = 'Kilogram na metr sześcienny';
								|tr = 'Metreküp başına kilogram'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kg/m3';
										|ru = 'кг/м3';
										|en = 'kg/m3'; fa = 'kg/m3';
										|it = 'kg/m3';
										|pl = 'kg/m3';
										|tr = 'kg/m3'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kg/m3"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KG/M3';
														|ru = 'КГ/МЗ';
														|en = 'KMQ'; fa = 'KMQ';
														|it = 'Kg/ m3';
														|pl = 'KMQ';
														|tr = 'KG/M3'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KMQ"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "323";
	Level3.Description = NStr("vi = 'Becquerel';
								|ru = 'Беккерель';
								|en = 'Becquerel'; fa = 'Becquerel';
								|it = 'Becquerel';
								|pl = 'Becquerel';
								|tr = 'Bekerel'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Bk';
										|ru = 'Бк';
										|en = 'Bq'; fa = 'Bq';
										|it = 'Бк';
										|pl = 'Bq';
										|tr = 'Бк'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "Bq"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Bk';
														|ru = 'БК';
														|en = 'BQL'; fa = 'BQL';
														|it = 'БК';
														|pl = 'BQL';
														|tr = 'БК'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "BQL"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "324";
	Level3.Description = NStr("vi = 'Weber';
								|ru = 'Вебер';
								|en = 'Weber'; fa = 'Weber';
								|it = 'Weber';
								|pl = 'Weber';
								|tr = 'Weber'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Wb';
										|ru = 'Вб';
										|en = 'Wb'; fa = 'Wb';
										|it = 'Вб';
										|pl = 'Wb';
										|tr = 'Wb'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "Wb"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Wb';
														|ru = 'ВБ';
														|en = 'Wb'; fa = 'Wb';
														|it = 'ВБ';
														|pl = 'Wb';
														|tr = 'Wb'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "WEB"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "327";
	Level3.Description = NStr("vi = 'Nút (mph)';
								|ru = 'Узел (миля/ч)';
								|en = 'Knot (mph)'; fa = 'Knot (mph)';
								|it = 'Nodo (miglio l''ora)';
								|pl = 'Węzeł (mila morska/h)';
								|tr = 'Düğüm (mil/saat)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Nút';
										|ru = 'уз';
										|en = 'KNT'; fa = 'KNT';
										|it = 'уз';
										|pl = 'KNT';
										|tr = 'Hesap'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "kn"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nút';
														|ru = 'УЗ';
														|en = 'KNT'; fa = 'KNT';
														|it = 'УЗ';
														|pl = 'KNT';
														|tr = 'Hesap'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KNT"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "328";
	Level3.Description = NStr("vi = 'Mét trên giây';
								|ru = 'Метр в секунду';
								|en = 'Meter per second'; fa = 'Meter per second';
								|it = 'Metro al secondo';
								|pl = 'Metr na sekundę';
								|tr = 'Saniyede metre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'M/s';
										|ru = 'м/с';
										|en = 'M/S'; fa = 'M/S';
										|it = 'm/s';
										|pl = 'M/S';
										|tr = 'M/S'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "m/s"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M/s';
														|ru = 'М/С';
														|en = 'M/S'; fa = 'M/S';
														|it = 'm/s';
														|pl = 'M/S';
														|tr = 'M/S'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MTS"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "330";
	Level3.Description = NStr("vi = 'Phát sinh trên giây';
								|ru = 'Оборот в секунду';
								|en = 'Revolutions per second'; fa = 'Revolutions per second';
								|it = 'Giri al secondo';
								|pl = 'Obrotów na sekundę';
								|tr = 'Saniyede ciro'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'phát sinh/giây';
										|ru = 'об/с';
										|en = 'r/s'; fa = 'r/s';
										|it = 'об/с';
										|pl = 'r/s';
										|tr = 'devir/saniye'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "r/s"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'phát sinh/giây';
														|ru = 'ОБ/С';
														|en = 'r/s'; fa = 'r/s';
														|it = 'ОБ/С';
														|pl = 'r/s';
														|tr = 'devir/saniye'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "RPS"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "331";
	Level3.Description = NStr("vi = 'Phát sinh trên phút';
								|ru = 'Оборот в минуту';
								|en = 'Revolutions per minute'; fa = 'Revolutions per minute';
								|it = 'Giri al minuto';
								|pl = 'Obrotów na minutę';
								|tr = 'Dakikada ciro'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'vòng quay/phút';
										|ru = 'об/мин';
										|en = 'r/min'; fa = 'r/min';
										|it = 'giri/min';
										|pl = 'r/min';
										|tr = 'devir/dk'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "r/min"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'vòng quay/phút';
														|ru = 'ОБ/МИН';
														|en = 'r/min'; fa = 'r/min';
														|it = 'giri/min';
														|pl = 'r/min';
														|tr = 'devir/dk'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "RPM"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "333";
	Level3.Description = NStr("vi = 'Kilômet trên giờ';
								|ru = 'Километр в час';
								|en = 'Kilometer per hour'; fa = 'Kilometer per hour';
								|it = 'Kilometri all''ora';
								|pl = 'Kilometr na godzinę';
								|tr = 'Saatte kilometre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'km/h';
										|ru = 'км/ч';
										|en = 'km/h'; fa = 'km/h';
										|it = 'km/h';
										|pl = 'km/h';
										|tr = 'km/s'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "km/h"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'km/h';
														|ru = 'КМ/Ч';
														|en = 'km/h'; fa = 'km/h';
														|it = 'km/h';
														|pl = 'km/h';
														|tr = 'km/s'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KMH"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "335";
	Level3.Description = NStr("vi = 'Mét trên giây bình phương';
								|ru = 'Метр на секунду в квадрате';
								|en = 'Meter per second squared'; fa = 'Meter per second squared';
								|it = 'Metro al secondo quadrato';
								|pl = 'Metr na sekundę do kwadratu';
								|tr = 'Kare saniyede metre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'm/s2';
										|ru = 'м/с2';
										|en = 'm/s2'; fa = 'm/s2';
										|it = 'm/s2';
										|pl = 'm/s2';
										|tr = 'm/s²'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "m/s2"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'm/s2';
														|ru = 'М/С2';
														|en = 'm/s2'; fa = 'm/s2';
														|it = 'm/s2';
														|pl = 'm/s2';
														|tr = 'm/s²'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MSK"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "349";
	Level3.Description = NStr("vi = 'Coulomb trên kilogam';
								|ru = 'Кулон на килограмм';
								|en = 'Coulomb per kilogram'; fa = 'Coulomb per kilogram';
								|it = 'Coulomb per kilogrammo';
								|pl = 'Kulon na kilogram';
								|tr = 'Kilogram başına kulon'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'C/kg';
										|ru = 'Кл/кг';
										|en = 'C​/kg'; fa = 'C​/kg';
										|it = 'Кл/кг';
										|pl = 'C​/kg';
										|tr = 'Kl/kg'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "C/kg"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'C/kg';
														|ru = 'КЛ/КГ';
														|en = 'C​/kg'; fa = 'C​/kg';
														|it = 'КЛ/КГ';
														|pl = 'C​/kg';
														|tr = 'Kl/kg'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CKG"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị thời gian';
								|ru = 'Единицы времени';
								|en = 'Units of time'; fa = 'Units of time';
								|it = 'Unità di tempo';
								|pl = 'Jednostki czasu';
								|tr = 'Zaman birimleri'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "354";
	Level3.Description = NStr("vi = 'Giây';
								|ru = 'Секунда';
								|en = 'Second'; fa = 'ثانیه';
								|it = 'Secondo';
								|pl = 'Second';
								|tr = 'Saniye'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'cm';
										|ru = 'См';
										|en = 's'; fa = 's';
										|it = 'См';
										|pl = 's';
										|tr = 'Cm'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "s"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'cm';
														|ru = 'СМ';
														|en = 's'; fa = 's';
														|it = 'СМ';
														|pl = 's';
														|tr = 'Cm'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "SEC"; //@NON-NLS-1
	Level3.Numerator = 1;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Time";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "355";
	Level3.Description = NStr("vi = 'Phút';
								|ru = 'Минута';
								|en = 'Minute'; fa = 'دقیقه';
								|it = 'Minuto';
								|pl = 'Minute';
								|tr = 'Dakika'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'PHÚT';
										|ru = 'мин';
										|en = 'MIN'; fa = 'MIN';
										|it = 'min';
										|pl = 'MIN';
										|tr = 'dk.'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "min"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'PHÚT';
														|ru = 'МИН';
														|en = 'MIN'; fa = 'MIN';
														|it = 'min';
														|pl = 'MIN';
														|tr = 'dk.'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MIN"; //@NON-NLS-1
	Level3.Numerator = 60;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Time";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "356";
	Level3.Description = NStr("vi = 'Giờ';
								|ru = 'Час';
								|en = 'Hour'; fa = 'ساعت';
								|it = 'Ora';
								|pl = 'Hour';
								|tr = 'Saat'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'h';
										|ru = 'ч';
										|en = 'h'; fa = 'ساعت';
										|it = 'ч';
										|pl = 'h';
										|tr = 'saat'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "h"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'h';
														|ru = 'Ч';
														|en = 'h'; fa = 'ساعت';
														|it = 'Ч';
														|pl = 'h';
														|tr = 'saat'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "HUR"; //@NON-NLS-1
	Level3.Numerator = 3600;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Time";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "359";
	Level3.Description = NStr("vi = 'Ngày đêm';
								|ru = 'Сутки';
								|en = 'Day'; fa = 'روز';
								|it = 'Giorno';
								|pl = 'Day';
								|tr = 'Gün'", Common.DefaultLanguageCode());
	Level3.SymbolNational = NStr("vi = 'ngày
		|ngày';
		|ru = 'сут
		|дн';
		|en = 'd
		|'; fa = 'd
		|';
		|it = 'g
		|gg';
		|pl = 'd
		|';
		|tr = 'gün
		|gün'", Common.DefaultLanguageCode());
	Level3.InternationalSymbol = "d"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = NStr("vi = 'ngày
		|ngày';
		|ru = 'СУТ
		|ДН';
		|en = 'd
		|'; fa = 'd
		|';
		|it = 'g
		|gg';
		|pl = 'd
		|';
		|tr = 'gün
		|gün'", Common.DefaultLanguageCode());
	Level3.CodeLetterDesignationInternational = "DAY"; //@NON-NLS-1
	Level3.Numerator = 86400;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Time";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "360";
	Level3.Description = NStr("vi = 'Tuần';
								|ru = 'Неделя';
								|en = 'Week'; fa = 'هفته';
								|it = 'Settimana';
								|pl = 'Week';
								|tr = 'Hafta'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'TUẦN';
										|ru = 'нед';
										|en = 'WEE'; fa = 'WEE';
										|it = 'нед';
										|pl = 'WEE';
										|tr = 'HAFTA'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TUẦN';
														|ru = 'НЕД';
														|en = 'WEE'; fa = 'WEE';
														|it = 'НЕД';
														|pl = 'WEE';
														|tr = 'HAFTA'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "WEE"; //@NON-NLS-1
	Level3.Numerator = 604800;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Time";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "361";
	Level3.Description = NStr("vi = 'Mười ngày';
								|ru = 'Декада';
								|en = 'Ten-day period'; fa = 'دوره ده‌روزه';
								|it = 'Decade';
								|pl = 'Ten-day period';
								|tr = '10 günlük süre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'MƯỜI NGÀY';
										|ru = 'дек';
										|en = 'TEN-DAY PD'; fa = 'TEN-DAY PD';
										|it = 'дек';
										|pl = 'TEN-DAY PD';
										|tr = '10 GÜNLÜK SÜRE'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MƯỜI NGÀY';
														|ru = 'ДЕК';
														|en = 'TEN-DAY PD'; fa = 'TEN-DAY PD';
														|it = 'ДЕК';
														|pl = 'TEN-DAY PD';
														|tr = '10 GÜNLÜK SÜRE'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DAD"; //@NON-NLS-1
	Level3.Numerator = 6048000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Time";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "362";
	Level3.Description = NStr("vi = 'Tháng';
								|ru = 'Месяц';
								|en = 'Month'; fa = 'ماه';
								|it = 'Mese';
								|pl = 'Month';
								|tr = 'Ay'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'tháng';
										|ru = 'мес';
										|en = 'mo'; fa = 'ماه';
										|it = 'мес';
										|pl = 'mo';
										|tr = 'мес'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'tháng';
														|ru = 'МЕС';
														|en = 'MON'; fa = 'MON';
														|it = 'МЕС';
														|pl = 'MON';
														|tr = 'МЕС'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MON"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "364";
	Level3.Description = NStr("vi = 'Quý';
								|ru = 'Квартал';
								|en = 'Quarter'; fa = 'فصل';
								|it = 'Trimestre';
								|pl = 'Kwartał';
								|tr = 'Çeyrek'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'CĂN HỘ';
										|ru = 'кварт';
										|en = 'apt'; fa = 'apt';
										|it = 'кварт';
										|pl = 'apt';
										|tr = 'кварт'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'CĂN HỘ';
														|ru = 'КВАРТ';
														|en = 'QUART'; fa = 'QUART';
														|it = 'КВАРТ';
														|pl = 'QUART';
														|tr = 'КВАРТ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "QAN"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "365";
	Level3.Description = NStr("vi = 'Nửa năm';
								|ru = 'Полугодие';
								|en = 'Half-year'; fa = 'نیم‌سال';
								|it = 'Semestre';
								|pl = 'Half-year';
								|tr = 'Yarıyıl'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'nửa năm';
										|ru = 'полгода';
										|en = 'six months'; fa = 'six months';
										|it = 'semestre';
										|pl = 'six months';
										|tr = 'yarıyıl'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NỬA NĂM';
														|ru = 'ПОЛГОД';
														|en = 'SAN'; fa = 'SAN';
														|it = 'SEMESTRE';
														|pl = 'SAN';
														|tr = 'YARIYIL'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "SAN"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "366";
	Level3.Description = NStr("vi = 'Năm';
								|ru = 'Год';
								|en = 'Year'; fa = 'سال';
								|it = 'Anno';
								|pl = 'Year';
								|tr = 'yıl'", Common.DefaultLanguageCode());
	Level3.SymbolNational = NStr("vi = 'n
		|năm';
		|ru = 'г
		|лет';
		|en = 'a
		|'; fa = 'a
		|';
		|it = 'a.
		|aa.';
		|pl = 'a
		|';
		|tr = 'sene
		|yıl'", Common.DefaultLanguageCode());
	Level3.InternationalSymbol = "a"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = NStr("vi = 'NĂM
		|NĂM';
		|ru = 'ГОД
		|ЛЕТ';
		|en = 'ANN
		|'; fa = 'ANN
		|';
		|it = 'Anno
		|anni';
		|pl = 'ANN
		|';
		|tr = 'SENE
		|YIL'", Common.DefaultLanguageCode());
	Level3.CodeLetterDesignationInternational = "ANN"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "368";
	Level3.Description = NStr("vi = 'Thập kỷ';
								|ru = 'Десятилетие';
								|en = 'Decade'; fa = 'Decade';
								|it = 'Decennio';
								|pl = 'Decade';
								|tr = 'On yıl'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Thập kỷ';
										|ru = 'деслет';
										|en = 'DEC'; fa = 'DEC';
										|it = 'деслет';
										|pl = 'DEC';
										|tr = 'ON YIL'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Thập kỷ';
														|ru = 'ДЕСЛЕТ';
														|en = 'DEC'; fa = 'DEC';
														|it = 'ДЕСЛЕТ';
														|pl = 'DEC';
														|tr = 'ON YIL'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DEC"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị kinh tế';
								|ru = 'Экономические единицы';
								|en = 'Economic units'; fa = 'Economic units';
								|it = 'Unità di misura economiche';
								|pl = 'Jednostki ekonomiczne';
								|tr = 'Ekonomik birimler'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "499";
	Level3.Description = NStr("vi = 'Kilôgam trên giây';
								|ru = 'Килограмм в секунду';
								|en = 'Kilogram per second'; fa = 'Kilogram per second';
								|it = 'Kilogrammi al secondo';
								|pl = 'Kilogram na sekundę';
								|tr = 'Saniyede kilogram'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kg/s';
										|ru = 'кг/с';
										|en = 'kg/s'; fa = 'kg/s';
										|it = 'кг/с';
										|pl = 'kg/s';
										|tr = 'kg/s'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'kg/s';
														|ru = 'КГ/С';
														|en = 'kg/s'; fa = 'kg/s';
														|it = 'КГ/С';
														|pl = 'kg/s';
														|tr = 'kg/s'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KGS"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "533";
	Level3.Description = NStr("vi = 'Tấn hơi trên giờ';
								|ru = 'Тонна пара в час';
								|en = 'Ton of steam per hour'; fa = 'Ton of steam per hour';
								|it = 'Tonnellate di vapore all''ora';
								|pl = 'Tona pary na godzinę';
								|tr = 'Saatte buhar tonu'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'T hơi/h';
										|ru = 'т пар/ч';
										|en = 't steam/h'; fa = 't steam/h';
										|it = 't/h di vapore';
										|pl = 't par/g';
										|tr = 't çift/sa.'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'T hơi/h';
														|ru = 'Т ПАР/Ч';
														|en = 't steam/h'; fa = 't steam/h';
														|it = 't/h di vapore';
														|pl = 't steam/h';
														|tr = 't çift/sa.'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "TSH"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "596";
	Level3.Description = NStr("vi = 'Mét khối trên giây';
								|ru = 'Кубический метр в секунду';
								|en = 'Cubic meter per second'; fa = 'Cubic meter per second';
								|it = 'Metro cubo al secondo';
								|pl = 'Metr sześcienny na sekundę';
								|tr = 'Saniyede metreküp'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'M3/S';
										|ru = 'м3/с';
										|en = 'MQS'; fa = 'MQS';
										|it = 'м3/с';
										|pl = 'MQS';
										|tr = 'M3/S'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "m3/s"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M3/S';
														|ru = 'М3/С';
														|en = 'MQS'; fa = 'MQS';
														|it = 'М3/С';
														|pl = 'MQS';
														|tr = 'M3/S'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MQS"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "598";
	Level3.Description = NStr("vi = 'Mét khối trên giờ';
								|ru = 'Кубический метр в час';
								|en = 'Cubic meter per hour'; fa = 'Cubic meter per hour';
								|it = 'Metro cubo all''ora';
								|pl = 'Metr sześcienny na godzinę';
								|tr = 'Saatte metreküp'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'M3/H';
										|ru = 'м3/ч';
										|en = 'MQH'; fa = 'MQH';
										|it = 'м3/ч';
										|pl = 'MQH';
										|tr = 'M3/S'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "m3/h"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M3/H';
														|ru = 'М3/Ч';
														|en = 'MQH'; fa = 'MQH';
														|it = 'М3/Ч';
														|pl = 'MQH';
														|tr = 'M3/S'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MQH"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "599";
	Level3.Description = NStr("vi = 'Ngàn mét khối trên ngày';
								|ru = 'Тысяча кубических метров в сутки';
								|en = 'Thousand cubic meters per day'; fa = 'Thousand cubic meters per day';
								|it = 'Mille metri cubi al giorno';
								|pl = 'Tysiąc metrów sześciennych na dobę';
								|tr = 'Günlük bin metreküp'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '1000 m3/ngày';
										|ru = '1000 м3/сут';
										|en = '1,000 m3/day'; fa = '1,000 m3/day';
										|it = '1000 m3/g';
										|pl = '1000 m3/doba';
										|tr = '1000 m3/günlük'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 M3/NGÀY';
														|ru = 'ТЫС М3/СУТ';
														|en = 'TQD'; fa = 'TQD';
														|it = 'MIL. M3/G';
														|pl = 'TYS M3/DOBA';
														|tr = 'BİN M3/GÜNLÜK'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "TQD"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "616";
	Level3.Description = NStr("vi = 'Spool';
								|ru = 'Бобина';
								|en = 'Bobbin'; fa = 'Bobbin';
								|it = 'Bobina';
								|pl = 'Bobbin';
								|tr = 'Masura'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Spool';
										|ru = 'боб';
										|en = 'NBB'; fa = 'NBB';
										|it = 'боб';
										|pl = 'NBB';
										|tr = 'MASURA'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Spool';
														|ru = 'БОБ';
														|en = 'NBB'; fa = 'NBB';
														|it = 'БОБ';
														|pl = 'NBB';
														|tr = 'MASURA'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "NBB"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "625";
	Level3.Description = NStr("vi = 'Tờ';
								|ru = 'Лист';
								|en = 'LEF'; fa = 'LEF';
								|it = 'Лист';
								|pl = 'LEF';
								|tr = 'YAPRAK'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'tờ';
										|ru = 'л.';
										|en = 'sht'; fa = 'sht';
										|it = 'l.';
										|pl = 'sht';
										|tr = 'y.'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Tờ';
														|ru = 'ЛИСТ';
														|en = 'LEF'; fa = 'LEF';
														|it = 'ЛИСТ';
														|pl = 'LEF';
														|tr = 'YAPRAK'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "LEF"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "626";
	Level3.Description = NStr("vi = '100 tờ';
								|ru = 'Сто листов';
								|en = 'Hundred leave'; fa = 'Hundred leave';
								|it = 'Cento lastre';
								|pl = 'Sto arkuszy';
								|tr = 'Yüz yaprak'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '100 tờ';
										|ru = '100 л.';
										|en = '100 sht'; fa = '100 sht';
										|it = '100 l.';
										|pl = '100 l.';
										|tr = '100 yaprak.'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = '100 TỜ';
														|ru = '100 ЛИСТ';
														|en = 'CLF'; fa = 'CLF';
														|it = '100 LASTRE';
														|pl = '100 ARKUSZ';
														|tr = '100 YAPRAK'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CLF"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "630";
	Level3.Description = NStr("vi = '1000 viên gạch tiêu chuẩn';
								|ru = 'Тысяча стандартных условных кирпичей';
								|en = 'Thousand standard conventional bricks'; fa = 'Thousand standard conventional bricks';
								|it = 'Mille mattoni standard convenzionali';
								|pl = 'Tysiąc standardowych cegieł umownych';
								|tr = 'Bin standart koşullu tuğla'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '1000 viên gạch tiêu chuẩn';
										|ru = 'тыс станд. усл. кирп';
										|en = 'thous standard convl. bricks'; fa = 'thous standard convl. bricks';
										|it = 'mil. mat. stand. conv.';
										|pl = 'tys stand ceg. war.';
										|tr = 'bin standart koşullu tuğla'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 viên gạch tiêu chuẩn';
														|ru = 'ТЫС СТАНД УСЛ КИРП';
														|en = 'MBE'; fa = 'MBE';
														|it = 'MIL. MAT. STAND. CONV.';
														|pl = 'TYS STAND CEG WAR';
														|tr = 'BİN STANDART KOŞULLU TUĞLA'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MBE"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "641";
	Level3.Description = NStr("vi = 'Tá (12 chiếc)';
								|ru = 'Дюжина (12 шт.)';
								|en = 'Dozen'; fa = 'Dozen';
								|it = 'Dozzina (12 pz.)';
								|pl = 'Tuzin (12 szt.)';
								|tr = 'Düzine (12 tanesi)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'DZN';
										|ru = 'дюжина';
										|en = 'DZN'; fa = 'DZN';
										|it = 'дюжина';
										|pl = 'DZN';
										|tr = 'DÜZİNE'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "Doz
		|12"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'DZN';
														|ru = 'ДЮЖИНА';
														|en = 'DZN'; fa = 'DZN';
														|it = 'ДЮЖИНА';
														|pl = 'DZN';
														|tr = 'DÜZİNE'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DZN"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "657";
	Level3.Description = NStr("vi = 'Sản phẩm';
								|ru = 'Изделие';
								|en = 'Item'; fa = 'قلم';
								|it = 'Prodotto';
								|pl = 'Item';
								|tr = 'Nihai ürün'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'sp';
										|ru = 'изд';
										|en = 'item'; fa = 'item';
										|it = 'изд';
										|pl = 'item';
										|tr = 'nihai ürün'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'sp';
														|ru = 'ИЗД';
														|en = 'item'; fa = 'item';
														|it = 'ИЗД';
														|pl = 'item';
														|tr = 'nihai ürün'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "NAR"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "683";
	Level3.Description = NStr("vi = '100 thùng';
								|ru = 'Сто ящиков';
								|en = 'Hundred boxes'; fa = 'Hundred boxes';
								|it = 'Cento casse';
								|pl = 'Sto pudeł';
								|tr = 'Yüz kutu'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '100 thùng';
										|ru = '100 ящ.';
										|en = 'Hbx.'; fa = 'Hbx.';
										|it = '100 cas.';
										|pl = '100 skrz.';
										|tr = '100 kutu.'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "Hbx"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = '100 THÙNG';
														|ru = '100 ЯЩ';
														|en = 'HBX'; fa = 'HBX';
														|it = '100 cas.';
														|pl = '100 SKRZ';
														|tr = '100 KUTU'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "HBX"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "704";
	Level3.Description = NStr("vi = 'Bộ';
								|ru = 'Набор';
								|en = 'SET'; fa = 'SET';
								|it = 'Набор';
								|pl = 'SET';
								|tr = 'FİLTRE'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Bộ';
										|ru = 'набор';
										|en = 'SET'; fa = 'SET';
										|it = 'набор';
										|pl = 'SET';
										|tr = 'FİLTRE'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Bộ';
														|ru = 'НАБОР';
														|en = 'SET'; fa = 'SET';
														|it = 'НАБОР';
														|pl = 'SET';
														|tr = 'FİLTRE'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "SET"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "715";
	Level3.Description = NStr("vi = 'Đôi (2 chiếc)';
								|ru = 'Пара (2 шт.)';
								|en = 'Pair (2 pcs)'; fa = 'Pair (2 pcs)';
								|it = 'Un paio (2 pz.)';
								|pl = 'Para (2 szt.)';
								|tr = 'Çift (2 tanesi)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'ĐÔI';
										|ru = 'пар';
										|en = 'NPR'; fa = 'NPR';
										|it = 'paia';
										|pl = 'NPR';
										|tr = 'ÇİFT'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "pr
		|2"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ĐÔI';
														|ru = 'ПАР';
														|en = 'NPR'; fa = 'NPR';
														|it = 'paia';
														|pl = 'NPR';
														|tr = 'ÇİFT'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "NPR"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "730";
	Level3.Description = NStr("vi = 'Hai chục';
								|ru = 'Два десятка';
								|en = 'Score'; fa = 'امتیاز';
								|it = 'Due decine';
								|pl = 'Dwa dziesiątka';
								|tr = 'İki ondalık'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '20';
										|ru = '20';
										|en = '20'; fa = '20';
										|it = '20';
										|pl = '20';
										|tr = '20'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "20"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = '2 CHỤC';
														|ru = '2 ДЕС';
														|en = 'SCO'; fa = 'SCO';
														|it = '2 dec';
														|pl = '2 DZIES';
														|tr = '2 ONDALIK'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "SCO"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "732";
	Level3.Description = NStr("vi = 'Mười đôi';
								|ru = 'Десять пар';
								|en = 'Ten pairs'; fa = 'Ten pairs';
								|it = 'Dieci paia';
								|pl = 'Dziesięć par';
								|tr = 'On çift'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '10 đôi';
										|ru = '10 пар';
										|en = '10 pairs'; fa = '10 pairs';
										|it = '10 paia';
										|pl = '10 par';
										|tr = '10 çift'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = '10 ĐÔI';
														|ru = 'ДЕС ПАР';
														|en = 'TPR'; fa = 'TPR';
														|it = 'DIECI PAIA';
														|pl = 'DZIES PAR';
														|tr = 'ON ÇİFT'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "TPR"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "733";
	Level3.Description = NStr("vi = '12 đôi';
								|ru = 'Дюжина пар';
								|en = 'DPR'; fa = 'DPR';
								|it = 'Дюжина пар';
								|pl = 'DPR';
								|tr = 'DÜZİNE ÇİFT'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '12 đôi';
										|ru = 'дюжина пар';
										|en = 'DPR'; fa = 'DPR';
										|it = 'дюжина пар';
										|pl = 'DPR';
										|tr = 'DÜZİNE ÇİFT'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = '12 đôi';
														|ru = 'ДЮЖИНА ПАР';
														|en = 'DPR'; fa = 'DPR';
														|it = 'ДЮЖИНА ПАР';
														|pl = 'tuzin par';
														|tr = 'DÜZİNE ÇİFT'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DPR"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "734";
	Level3.Description = NStr("vi = 'Gói';
								|ru = 'Посылка';
								|en = 'Parcel'; fa = 'Parcel';
								|it = 'Pacco';
								|pl = 'Parcel';
								|tr = 'Paket'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'gói';
										|ru = 'посыл';
										|en = 'pcl'; fa = 'pcl';
										|it = 'посыл';
										|pl = 'pcl';
										|tr = 'parsel'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'gói';
														|ru = 'ПОСЫЛ';
														|en = 'pcl'; fa = 'pcl';
														|it = 'ПОСЫЛ';
														|pl = 'pcl';
														|tr = 'parsel'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "NPL"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "735";
	Level3.Description = NStr("vi = 'phần';
								|ru = 'Часть';
								|en = 'Part'; fa = 'Part';
								|it = 'Часть';
								|pl = 'Part';
								|tr = 'Bölüm'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'phần';
										|ru = 'часть';
										|en = 'Part'; fa = 'Part';
										|it = 'часть';
										|pl = 'Part';
										|tr = 'Bölüm'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'phần';
														|ru = 'ЧАСТЬ';
														|en = 'Part'; fa = 'Part';
														|it = 'ЧАСТЬ';
														|pl = 'Part';
														|tr = 'Bölüm'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "NPT"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "736";
	Level3.Description = NStr("vi = 'Cuộn';
								|ru = 'Рулон';
								|en = 'Roll'; fa = 'Roll';
								|it = 'Rotolo';
								|pl = 'Roll';
								|tr = 'Rulo'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'cuộn';
										|ru = 'рул';
										|en = 'rl'; fa = 'rl';
										|it = 'рул';
										|pl = 'rl';
										|tr = 'rulo'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'cuộn';
														|ru = 'РУЛ';
														|en = 'rl'; fa = 'rl';
														|it = 'РУЛ';
														|pl = 'rl';
														|tr = 'rulo'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "NRL"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "737";
	Level3.Description = NStr("vi = '12 cuộn';
								|ru = 'Дюжина рулонов';
								|en = 'Dozen rolls'; fa = 'Dozen rolls';
								|it = 'Una dozzina di rotoli';
								|pl = 'Tuzin rulonów';
								|tr = 'Rulo düzinesi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '12 cuộn';
										|ru = 'дюжина рул';
										|en = 'DRL'; fa = 'DRL';
										|it = 'дюжина рул';
										|pl = 'tuzin rul';
										|tr = 'DÜZİNE RULO'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = '12 cuộn';
														|ru = 'ДЮЖИНА РУЛ';
														|en = 'DRL'; fa = 'DRL';
														|it = 'ДЮЖИНА РУЛ';
														|pl = 'DRL';
														|tr = 'DÜZİNE RULO'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DRL"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "740";
	Level3.Description = NStr("vi = '12 chiếc';
								|ru = 'Дюжина штук';
								|en = 'Dozen pieces'; fa = 'Dozen pieces';
								|it = 'Una dozzina di pezzi';
								|pl = 'Tuzin sztuk';
								|tr = 'Düzine tanesi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Tá C';
										|ru = 'дюжина шт';
										|en = 'DPC'; fa = 'DPC';
										|it = 'una dozzina di pz.';
										|pl = 'DPC';
										|tr = 'DÜZİNE ADET'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Tá C';
														|ru = 'ДЮЖИНА ШТ';
														|en = 'DPC'; fa = 'DPC';
														|it = 'una dozzina di pz.';
														|pl = 'tuzin szt';
														|tr = 'DÜZİNE ADET'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DPC"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "745";
	Level3.Description = NStr("vi = 'Phần tử';
								|ru = 'Элемент';
								|en = 'Cell'; fa = 'Cell';
								|it = 'Elemento';
								|pl = 'Cell';
								|tr = 'Öğe'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'NCL';
										|ru = 'элем';
										|en = 'NCL'; fa = 'NCL';
										|it = 'элем';
										|pl = 'NCL';
										|tr = 'ÖĞE'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "CI"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NCL';
														|ru = 'ЭЛЕМ';
														|en = 'NCL'; fa = 'NCL';
														|it = 'ЭЛЕМ';
														|pl = 'NCL';
														|tr = 'ÖĞE'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "NCL"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "778";
	Level3.Description = NStr("vi = 'Hộp';
								|ru = 'Упаковка';
								|en = 'Packaging unit'; fa = 'واحد بسته‌بندی';
								|it = 'Confezione';
								|pl = 'Packaging unit';
								|tr = 'Paket'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Gói';
										|ru = 'упак';
										|en = 'NMP'; fa = 'NMP';
										|it = 'упак';
										|pl = 'NMP';
										|tr = 'PAKETLEME ÜNİTESİ'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Gói';
														|ru = 'УПАК';
														|en = 'NMP'; fa = 'NMP';
														|it = 'УПАК';
														|pl = 'NMP';
														|tr = 'PAKETLEME ÜNİTESİ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "NMP"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "780";
	Level3.Description = NStr("vi = 'Tá gói';
								|ru = 'Дюжина упаковок';
								|en = 'Dozen packaging units'; fa = 'Dozen packaging units';
								|it = 'Una dozzina di confezioni';
								|pl = 'Tuzin opakowań';
								|tr = 'Paketleme ünitesi düzinesi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'DZP';
										|ru = 'дюжина упак';
										|en = 'dozen pkg'; fa = 'dozen pkg';
										|it = 'дюжина упак';
										|pl = 'tuzin opak';
										|tr = 'DÜZİNE PAKET'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'DZP';
														|ru = 'ДЮЖИНА УПАК';
														|en = 'dozen pkg'; fa = 'dozen pkg';
														|it = 'ДЮЖИНА УПАК';
														|pl = 'dozen pkg';
														|tr = 'DÜZİNE PAKET'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "DZP"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "781";
	Level3.Description = NStr("vi = '100 gói';
								|ru = 'Сто упаковок';
								|en = 'Hundred packaging units'; fa = 'Hundred packaging units';
								|it = 'Cento confezioni';
								|pl = 'Sto opakowań';
								|tr = 'Yüz paketleme ünitesi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '100 gói';
										|ru = '100 упак';
										|en = '100 PKG'; fa = '100 PKG';
										|it = '100 упак';
										|pl = '100 opak';
										|tr = '100 PAKET'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = '100 gói';
														|ru = '100 УПАК';
														|en = '100 PKG'; fa = '100 PKG';
														|it = '100 УПАК';
														|pl = '100 PKG';
														|tr = '100 PAKET'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CNP"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "796";
	Level3.Description = NStr("vi = 'Chiếc';
								|ru = 'Штука';
								|en = 'Piece'; fa = 'قطعه';
								|it = 'Pezzo';
								|pl = 'Piece';
								|tr = 'Tanesi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'C';
										|ru = 'шт';
										|en = 'PCE'; fa = 'PCE';
										|it = 'pz.';
										|pl = 'PCE';
										|tr = 'parça'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "pc
		|1"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'C';
														|ru = 'ШТ';
														|en = 'PCE'; fa = 'PCE';
														|it = 'pz.';
														|pl = 'PCE';
														|tr = 'parça'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "PCE
		|NMB"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "797";
	Level3.Description = NStr("vi = '100 chiếc';
								|ru = 'Сто штук';
								|en = 'Hundred pieces'; fa = 'Hundred pieces';
								|it = 'Cento pezzi';
								|pl = 'Sto sztuk';
								|tr = 'Yüz tane'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '100 c';
										|ru = '100 шт';
										|en = 'CEN'; fa = 'CEN';
										|it = '100 шт';
										|pl = '100 szt';
										|tr = '100 parça'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "100"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = '100 c';
														|ru = '100 ШТ';
														|en = 'CEN'; fa = 'CEN';
														|it = '100 ШТ';
														|pl = 'CEN';
														|tr = '100 parça'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "CEN"; //@NON-NLS-1
	Level3.Numerator = 100;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "NumberOfPieces";
	
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "798";
	Level3.Description = NStr("vi = '1000 chiếc';
								|ru = 'Тысяча штук';
								|en = 'Thousand pieces'; fa = 'Thousand pieces';
								|it = 'Mille pezzi';
								|pl = 'Tysiąc sztuk';
								|tr = 'Bin tanesi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = NStr("vi = 'nghìn c
		|1000 c';
		|ru = 'тыс. шт
		|1000 шт';
		|en = 'thous pcs
		|1,000 pcs'; fa = 'thous pcs
		|1,000 pcs';
		|it = 'mil. pz.
		|1000 pz.';
		|pl = 'tys. szt
		|1000 szt';
		|tr = 'bin tane
		|1000 tane'", Common.DefaultLanguageCode());
	Level3.InternationalSymbol = "1000"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN CHIẾC';
														|ru = 'ТЫС ШТ';
														|en = 'MIL'; fa = 'MIL';
														|it = 'Mille pz.';
														|pl = 'TYS SZT';
														|tr = 'BİN TANESİ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MIL"; //@NON-NLS-1
	Level3.Numerator = 1000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "NumberOfPieces";
	
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "799";
	Level3.Description = NStr("vi = '1 triệu chiếc';
								|ru = 'Миллион штук';
								|en = 'Million pieces'; fa = 'Million pieces';
								|it = 'Un milione di pezzi';
								|pl = 'Milion sztuk';
								|tr = 'MİLYON TANESİ'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '10^6 c';
										|ru = '10^6 шт';
										|en = '10^6 pcs'; fa = '10^6 pcs';
										|it = '10^6 pz.';
										|pl = '10^6 szt';
										|tr = '10^6 tanesi'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "10^6"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU CHIẾC';
														|ru = 'МЛН ШТ';
														|en = 'MIO'; fa = 'MIO';
														|it = 'Mln pz.';
														|pl = 'MLN SZT';
														|tr = 'MİLYON TANESİ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MIO"; //@NON-NLS-1
	Level3.Numerator = Pow(10, 6);
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "NumberOfPieces";
	
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "800";
	Level3.Description = NStr("vi = '1 tỷ chiếc';
								|ru = 'Миллиард штук';
								|en = 'Billion pieces'; fa = 'Billion pieces';
								|it = 'Un miliardo di pezzi';
								|pl = 'Miliard sztuk';
								|tr = 'MİLYAR TANESİ'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '10^9 c';
										|ru = '10^9 шт';
										|en = '10^9 pcs'; fa = '10^9 pcs';
										|it = '10^9 pz.';
										|pl = '10^9 szt';
										|tr = '10^9 tanesi'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "10^9"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'HÀNG TRIỆU CHIẾC';
														|ru = 'МЛРД ШТ';
														|en = 'MLD'; fa = 'MLD';
														|it = 'Mld pz.';
														|pl = 'MLD SZT';
														|tr = 'MİLYAR TANESİ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "MLD"; //@NON-NLS-1
	Level3.Numerator = Pow(10, 9);
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "NumberOfPieces";
	
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "801";
	Level3.Description = NStr("vi = '1 tỷ tỷ chiếc (Châu Âu)';
								|ru = 'Биллион штук (Европа) (Триллион штук)';
								|en = 'Billion pieces (Europe) (Trillion pieces)'; fa = 'Billion pieces (Europe) (Trillion pieces)';
								|it = 'Un bilione di pezzi (Europa) (Un trilione di pezzi)';
								|pl = 'Bilion sztuk (Europa) (Trylion sztuk)';
								|tr = 'Milyar tanesi (Avrupa) (Trilyon tanesi)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '10^12 c';
										|ru = '10^12 шт';
										|en = '10^12 pcs'; fa = '10^12 pcs';
										|it = '10^12 pz.';
										|pl = '10^12 szt';
										|tr = '10^12 tanesi'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "10^12"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TỶ CHIẾC (NGHÌN TỶ CHIẾC)';
														|ru = 'БИЛЛ ШТ (ЕВР) (ТРИЛЛ ШТ)';
														|en = 'BIL'; fa = 'BIL';
														|it = 'Trl pz. (eur)(trl pz.)';
														|pl = 'BILION SZT (EUR) (TRYLION SZT)';
														|tr = 'MİLYAR TANESİ (AVRUPA) (TRİLYON TANESİ)'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "BIL"; //@NON-NLS-1
	Level3.Numerator = Pow(10, 12);
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "NumberOfPieces";
	
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "802";
	Level3.Description = NStr("vi = '1 tỷ tỷ tỷ chiếc (Châu Âu)';
								|ru = 'Квинтильон штук (Европа)';
								|en = 'Quintillion pieces (Europe)'; fa = 'Quintillion pieces (Europe)';
								|it = 'Un quintilione di pezzi (Europa)';
								|pl = 'Kwintylion sztuk (Europa)';
								|tr = 'Kentilyon tanesi (Avrupa)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = '10^18 c';
										|ru = '10^18 шт';
										|en = '10^18 pcs'; fa = '10^18 pcs';
										|it = '10^18 pz.';
										|pl = '10^18 szt';
										|tr = '10^18 tanesi'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "10^18"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TỶ TỶ CHIẾC';
														|ru = 'КВИНТ ШТ';
														|en = 'TRL'; fa = 'TRL';
														|it = 'Qln pz.';
														|pl = 'KWINT SZT';
														|tr = 'KENTİLYON TANESİ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "TRL"; //@NON-NLS-1
	Level3.Numerator = Pow(10, 18);
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "NumberOfPieces";
	
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "820";
	Level3.Description = NStr("vi = 'Độ cồn theo trọng lượng';
								|ru = 'Крепость спирта по массе';
								|en = 'Alcoholic strength by mass'; fa = 'Alcoholic strength by mass';
								|it = 'Gradazione alcolica in base al peso';
								|pl = 'Koncentracja alkoholu pod względem masy';
								|tr = 'Ağırlığa göre alkol derecesi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Độ cồn theo trọng lượng';
										|ru = 'креп. спирта по массе';
										|en = '% mds'; fa = '% mds';
										|it = 'gradazione alcolica in base al peso';
										|pl = 'koncentr. alkoholu pod względem masy';
										|tr = 'ağırlığa göre alkol gücü'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "% mds"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ASM';
														|ru = 'КРЕП СПИРТ ПО МАСС';
														|en = 'ASM'; fa = 'ASM';
														|it = 'Gradazione alcolica in base al peso';
														|pl = 'KONCENTR. ALKOHOLU POD WZGLĘDEM MASY';
														|tr = 'AĞIRLIĞA GÖRE ALKOL GÜCÜ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "ASM"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "821";
	Level3.Description = NStr("vi = 'Độ cồn theo thể tích';
								|ru = 'Крепость спирта по объему';
								|en = 'Alcoholic strength by volume'; fa = 'Alcoholic strength by volume';
								|it = 'Gradazione alcolica in base al volume';
								|pl = 'Koncentracja alkoholu pod względem objętości';
								|tr = 'Hacime göre alkol derecesi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Độ cồn theo thể tích';
										|ru = 'креп. спирта по объему';
										|en = '% vol'; fa = '% vol';
										|it = 'gradazione alcolica in base al volume';
										|pl = 'konc. alkoholu pod względem objętości';
										|tr = 'hacme göre alkol gücü'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "% vol"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ASV';
														|ru = 'КРЕП СПИРТ ПО ОБЪЕМ';
														|en = 'ASV'; fa = 'ASV';
														|it = 'Gradazione alcolica in base al volume';
														|pl = 'KONCENTR. ALKOHOLU POD WZGLĘDEM OBJĘTOŚCI';
														|tr = 'HACİME GÖRE ALKOL GÜCÜ'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "ASV"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "831";
	Level3.Description = NStr("vi = 'Lít rượu nguyên chất (100%)';
								|ru = 'Литр чистого (100%) спирта';
								|en = 'Liter of pure (100%) alcohol'; fa = 'Liter of pure (100%) alcohol';
								|it = 'Un litro di alcool puro (100%)';
								|pl = 'Litr czystego (100%) spirytusu';
								|tr = '(100%) saf alkol litresi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'l 100% cồn';
										|ru = 'л 100% спирта';
										|en = 'l 100% alcohol'; fa = 'l 100% alcohol';
										|it = 'l di alcool 100%';
										|pl = 'l 100% alkoholu';
										|tr = '100% saf alkol lt'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Lít rượu nguyên chất';
														|ru = 'Л ЧИСТ СПИРТ';
														|en = 'LPA'; fa = 'LPA';
														|it = 'L DI ALCOOL PURO';
														|pl = 'L ALKOHOLU CZYSTEGO';
														|tr = 'SAF ALKOL LT'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "LPA"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "833";
	Level3.Description = NStr("vi = 'Hectolit rượu nguyên chất (100%)';
								|ru = 'Гектолитр чистого (100%) спирта';
								|en = 'Hectoliter of pure (100%) alcohol'; fa = 'Hectoliter of pure (100%) alcohol';
								|it = 'Un ettolitro di alcool puro (100%)';
								|pl = 'Hektolitr czystego (100%) alkoholu';
								|tr = '(100%) saf alkol hektolitresi'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Hectolit rượu nguyên chất (100%)';
										|ru = 'Гл 100% спирта';
										|en = 'Hl 100% alcohol'; fa = 'Hl 100% alcohol';
										|it = 'Hl di alcool 100%';
										|pl = 'Hl 100% alkoholu';
										|tr = '100% saf alkol hlt'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Hectolit của rượu nguyên chất';
														|ru = 'ГЛ ЧИСТ СПИРТ';
														|en = 'HPA'; fa = 'HPA';
														|it = 'HL DI ALCOOL PURO';
														|pl = 'HL ALKOHOLU CZYSTEGO';
														|tr = 'SAF ALKOL HLT'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "HPA"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "841";
	Level3.Description = NStr("vi = 'Kilogam hydro peroxit';
								|ru = 'Килограмм пероксида водорода';
								|en = 'Kilogram of hydrogen peroxide'; fa = 'Kilogram of hydrogen peroxide';
								|it = 'Kilogrammo di perossido di idrogeno';
								|pl = 'Kilogram nadtlenku wodoru';
								|tr = 'Kilogram hidrojen peroksit '", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kg H(2)O(2)';
										|ru = 'кг H(2)0(2)';
										|en = 'kg H(2)0(2)'; fa = 'kg H(2)0(2)';
										|it = 'kg di H(2)0(2)';
										|pl = 'kg H(2)0(2)';
										|tr = 'kg H(2)0(2)'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KG HYDROGEN PEROXIDE';
														|ru = 'КГ ПЕРОКСИД ВОДОРОДА';
														|en = 'KHP'; fa = 'KHP';
														|it = 'KG DI PEROSSIDO DI IDROGENO';
														|pl = 'KG NADTLENKU WODORU';
														|tr = 'KİLOGRAM HİDROJEN PEROKSİT'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "";
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "845";
	Level3.Description = NStr("vi = 'Kilogam 90% chất khô';
								|ru = 'Килограмм 90%-го сухого вещества';
								|en = 'Kilogram of substance 90% dry'; fa = 'Kilogram of substance 90% dry';
								|it = 'Kilogrammo di sostanza secca al 90%';
								|pl = 'Kilogram 90% substancji suchej';
								|tr = 'Kuru maddenin 90%-nın kilogramı'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Kilogam 90% chất khô';
										|ru = 'кг 90% с/в';
										|en = 'kg 90 % sdt'; fa = 'kg 90 % sdt';
										|it = 'kg di sostanza secca 90%';
										|pl = 'kg 90% sub/such';
										|tr = '90% k/m kg'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Kg 90% chất khô';
														|ru = 'КГ 90 ПРОЦ СУХ ВЕЩ';
														|en = 'KSD'; fa = 'KSD';
														|it = 'KG DI SOSTANZA SECCA AL 90%';
														|pl = 'KG 90 PROC SUB SUCH';
														|tr = 'KURU MADDENİN YÜZDE 90''nın KİLOGRAMI'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KSD"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "847";
	Level3.Description = NStr("vi = 'Tấn 90% chất khô';
								|ru = 'Тонна 90%-го сухого вещества';
								|en = 'Ton of substance 90% dry'; fa = 'Ton of substance 90% dry';
								|it = 'Tonnellata di sostanza secca al 90%';
								|pl = 'Tona 90% substancji suchej';
								|tr = 'Kuru maddenin 90%-nın tonu'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Tấn 90% chất khô';
										|ru = 'т 90% с/в';
										|en = 't 90% sdt'; fa = 't 90% sdt';
										|it = 't di sostanza secca 90%';
										|pl = 't 90% sub/such';
										|tr = '90% k/m tonu'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Tấn 90% chất khô';
														|ru = 'Т 90 ПРОЦ СУХ ВЕЩ';
														|en = 'TSD'; fa = 'TSD';
														|it = 'T DI SOSTANZA SECCA AL 90%';
														|pl = 'T 90 PROC SUB SUCH';
														|tr = 'KURU MADDENİN YÜZDE 90''nın TONU'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "TSD"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "852";
	Level3.Description = NStr("vi = 'Kilogam kali oxit';
								|ru = 'Килограмм оксида калия';
								|en = 'Kilogram of potassium oxide'; fa = 'Kilogram of potassium oxide';
								|it = 'Kilogrammo di ossido di potassio';
								|pl = 'Kilogram tlenku potasu';
								|tr = 'Kilogram potasyum oksit'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kg K(2)O';
										|ru = 'кг К(2)О';
										|en = 'kg K(2)O'; fa = 'kg K(2)O';
										|it = 'kg К(2)О';
										|pl = 'kg К(2)О';
										|tr = 'kg K(2)O'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Kg kali oxit';
														|ru = 'КГ ОКСИД КАЛИЯ';
														|en = 'KPO'; fa = 'KPO';
														|it = 'KG DI OSSIDO DI POTASSIO';
														|pl = 'KG TLENKU POTASU';
														|tr = 'KİLOGRAM POTASYUM OKSİT'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KPO"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "859";
	Level3.Description = NStr("vi = 'Kilogam kali hydroxit';
								|ru = 'Килограмм гидроксида калия';
								|en = 'Kilogram of potassium hydroxide'; fa = 'Kilogram of potassium hydroxide';
								|it = 'Kilogrammo di idrossido di potassio';
								|pl = 'Kilogram wodorotlenku potasu';
								|tr = 'Kilogram potasyum hidroksit'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'Kg KOH';
										|ru = 'кг КОН';
										|en = 'kg KPH'; fa = 'kg KPH';
										|it = 'kg КОН';
										|pl = 'kg КОН';
										|tr = 'kg KOH'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Kg kali hydroxit';
														|ru = 'КГ ГИДРОКСИД КАЛИЯ';
														|en = 'KPH'; fa = 'KPH';
														|it = 'KG IDROSSIDO DI POTASSIO';
														|pl = 'KG WODOROTLENEK POTASU';
														|tr = 'KİLOGRAM POTASYUM HİDROKSİT'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KPH"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "861";
	Level3.Description = NStr("vi = 'Kg nitơ';
								|ru = 'Килограмм азота';
								|en = 'Kilogram of nitrogen'; fa = 'Kilogram of nitrogen';
								|it = 'Kilogrammo di azoto';
								|pl = 'Kilogram azotu';
								|tr = 'Kilogram nitrojen'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kg N';
										|ru = 'кг N';
										|en = 'kg N'; fa = 'kg N';
										|it = 'kg N';
										|pl = 'kg N';
										|tr = 'kg N'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Kg nitơ';
														|ru = 'КГ АЗОТ';
														|en = 'KNI'; fa = 'KNI';
														|it = 'KG DI AZOTO';
														|pl = 'KG AZOT';
														|tr = 'KG NİTROJEN'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KNI"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "863";
	Level3.Description = NStr("vi = 'Kilogam natri hydroxit';
								|ru = 'Килограмм гидроксида натрия';
								|en = 'Kilogram of sodium hydroxide'; fa = 'Kilogram of sodium hydroxide';
								|it = 'Kilogrammo di idrossido di sodio';
								|pl = 'Kilogram wodorotlenku sodu';
								|tr = 'Kilogram sodyum hidroksit'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kg NaOH';
										|ru = 'кг NaOH';
										|en = 'kg NaOH'; fa = 'kg NaOH';
										|it = 'kg NaOH';
										|pl = 'kg NaOH';
										|tr = 'kg NaOH'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KG NATRI HYDROXIT';
														|ru = 'КГ ГИДРОКСИД НАТРИЯ';
														|en = 'KSH'; fa = 'KSH';
														|it = 'KG DI IDROSSIDO DI SODIO';
														|pl = 'KG WODOROTLENEK SODU';
														|tr = 'KG SODYUM HİDROKSİT'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KSH"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "865";
	Level3.Description = NStr("vi = 'Kilogram photpho pentoxit';
								|ru = 'Килограмм пятиокиси фосфора';
								|en = 'Kilogram of phosphorus pentoxide'; fa = 'Kilogram of phosphorus pentoxide';
								|it = 'Kilogrammo di pentossido di fosforo';
								|pl = 'Kilogram pięciotlenku fosforu';
								|tr = 'Kilogram fosfor pentoksit'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kg Р(2)О(5)';
										|ru = 'кг Р(2)О(5)';
										|en = 'kg P(2)O(5)'; fa = 'kg P(2)O(5)';
										|it = 'kg Р(2)О(5)';
										|pl = 'kg Р(2)О(5)';
										|tr = 'kg P(2)O(5)'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Kg photpho pentoxit';
														|ru = 'КГ ПЯТИОКИСЬ ФОСФОРА';
														|en = 'KPP'; fa = 'KPP';
														|it = 'KG DI PENTOSSIDO DI FOSFORO';
														|pl = 'KG PIĘCIOTLENEK FOSFORU';
														|tr = 'KG FOSFOR PENTOKSİT'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KPP"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "867";
	Level3.Description = NStr("vi = 'Kilogram uranium';
								|ru = 'Килограмм урана';
								|en = 'Kilogram of uranium'; fa = 'Kilogram of uranium';
								|it = 'Kilogrammo di uranio';
								|pl = 'Kilogram uranu';
								|tr = 'Kilogram uranyum'", Common.DefaultLanguageCode());
	Level3.SymbolNational = Lower(NStr("vi = 'kg U';
										|ru = 'кг U';
										|en = 'kg U'; fa = 'kg U';
										|it = 'kg U';
										|pl = 'kg U';
										|tr = 'kg U'", Common.DefaultLanguageCode()));
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KG URAN';
														|ru = 'КГ УРАН';
														|en = 'KUR'; fa = 'KUR';
														|it = 'KG DI URANIO';
														|pl = 'KG URAN';
														|tr = 'KG URANYUM'", Common.DefaultLanguageCode()));
	Level3.CodeLetterDesignationInternational = "KUR"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	If LocalizationRFService Then
		Level1 = ValueTree.Rows.Add();
		Level1.NumericCode = "";
		Level1.Description = NStr("vi = 'Đơn vị đo lường quốc gia';
									|ru = 'Национальные единицы измерения, включенные в ОКЕИ';
									|en = 'National units of measure included in Russian National Classifier of Measurement Units'; fa = 'National units of measure included in Russian National Classifier of Measurement Units';
									|it = 'Unità di misura nazionali incluse nel Classificatore panrusso di unità di misura';
									|pl = 'Krajowe jednostki miary, zawarte w klasyfikatorze jednostek miary';
									|tr = 'RÖBS''e dahil olan ulusal ölçü birimleri'", Common.DefaultLanguageCode());
		Level1.SymbolNational = "";
		Level1.InternationalSymbol = "";
		Level1.CodeLetterDesignationNational = "";
		Level1.CodeLetterDesignationInternational = "";
		Level1.Numerator = 0;
		Level1.Denominator = 0;
		Level1.MeasuredValueType = "";
		Level2 = Level1.Rows.Add();
		Level2.NumericCode = "";
		Level2.Description = NStr("vi = 'Đơn vị chiều dài';
									|ru = 'Единицы длины';
									|en = 'Units of length'; fa = 'Units of length';
									|it = 'Unità di lunghezza';
									|pl = 'Jednostki długości';
									|tr = 'Uzunluk birimleri'", Common.DefaultLanguageCode());
		Level2.SymbolNational = "";
		Level2.InternationalSymbol = "";
		Level2.CodeLetterDesignationNational = "";
		Level2.CodeLetterDesignationInternational = "";
		Level2.Numerator = 0;
		Level2.Denominator = 0;
		Level2.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "018";
		Level3.Description = NStr("vi = 'Mét chạy';
									|ru = 'Погонный метр';
									|en = 'Linear meter'; fa = 'Linear meter';
									|it = 'Metro lineare';
									|pl = 'Metr bieżący';
									|tr = 'Doğrusal metre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'm chạy';
											|ru = 'пог. м';
											|en = 'lin. m'; fa = 'lin. m';
											|it = 'm lin.';
											|pl = 'm. bież';
											|tr = 'doğrusal. m'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M chạy';
															|ru = 'ПОГ М';
															|en = 'LIN M'; fa = 'LIN M';
															|it = 'M LIN.';
															|pl = 'M. BIEŻ';
															|tr = 'DOĞRUSAL M'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Length";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "019";
		Level3.Description = NStr("vi = '1000 mét chạy';
									|ru = 'Тысяча погонных метров';
									|en = 'Thousand linear meters'; fa = 'Thousand linear meters';
									|it = 'Mille metri lineare';
									|pl = 'Tysiąc metrów bieżących';
									|tr = 'Bin doğrusal metre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 m chạy';
											|ru = '1000 пог. м';
											|en = '1,000 lin. m'; fa = '1,000 lin. m';
											|it = '1000 m lin.';
											|pl = '1000 m. bież';
											|tr = '1000 doğrusal. m'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 m chạy';
															|ru = 'ТЫС ПОГ М';
															|en = 'THOUS LIN M'; fa = 'THOUS LIN M';
															|it = 'MILLE M LIN.';
															|pl = 'TYS M BIEŻ';
															|tr = 'BİN DOĞRUSAL METRE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Length";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "020";
		Level3.Description = NStr("vi = 'Mét điều kiện';
									|ru = 'Условный метр';
									|en = 'Conventional meter'; fa = 'Conventional meter';
									|it = 'Metro convenzionale';
									|pl = 'Metr umowny';
									|tr = 'Konvansiyonel metre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'm điều kiện';
											|ru = 'усл. м';
											|en = 'convl. m'; fa = 'convl. m';
											|it = 'm conv.';
											|pl = 'м war';
											|tr = 'konvansiyonel. m'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M ĐIỀU KIỆN';
															|ru = 'УСЛ М';
															|en = 'CONVL M'; fa = 'CONVL M';
															|it = 'M CONV.';
															|pl = 'M WAR';
															|tr = 'KONVANSİYONEL M'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Length";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "048";
		Level3.Description = NStr("vi = '1000 mét điều kiện';
									|ru = 'Тысяча условных метров';
									|en = 'Thousand conventional meters'; fa = 'Thousand conventional meters';
									|it = 'Mille metri convenzionali';
									|pl = 'Tysiąc metrów umownych';
									|tr = 'Bin konvansiyonel metre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 mét điều kiện';
											|ru = '1000 усл. м';
											|en = '1,000 convl. m'; fa = '1,000 convl. m';
											|it = '1000 m conv.';
											|pl = '1000 m. war';
											|tr = '1000 konvansiyonel. metre'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 mét điều kiện';
															|ru = 'ТЫС УСЛ М';
															|en = 'THOUS CONVL M'; fa = 'THOUS CONVL M';
															|it = 'MILLE M CONV.';
															|pl = 'TYS M WAR';
															|tr = 'BİN KONVANSİYONEL M'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Length";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "049";
		Level3.Description = NStr("vi = 'Kilomet đường ống quy ước';
									|ru = 'Километр условных труб';
									|en = 'Kilometer of conventional pipes'; fa = 'Kilometer of conventional pipes';
									|it = 'Un kilometro di tubi convenzionali';
									|pl = 'Kilometr rur umownych';
									|tr = 'Konvansiyonel boruların kilometresi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Kilomet đường ống quy ước';
											|ru = 'км усл. труб';
											|en = 'km convl. pipes'; fa = 'km convl. pipes';
											|it = 'km di tubi conv.';
											|pl = 'km rur war';
											|tr = 'km konvansiyonel. boru'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KM ĐƯỜNG ỐNG QUY ƯỚC';
															|ru = 'КМ УСЛ ТРУБ';
															|en = 'KM CONVL PIPES'; fa = 'KM CONVL PIPES';
															|it = 'KM DI TUBI CONV.';
															|pl = 'KM RUR WAR';
															|tr = 'KM KONVANSİYONEL BORU'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level2 = Level1.Rows.Add();
		Level2.NumericCode = "";
		Level2.Description = NStr("vi = 'Đơn vị diện tích';
									|ru = 'Единицы площади';
									|en = 'Units of area'; fa = 'Units of area';
									|it = 'Unità di area';
									|pl = 'Jednostki powierzchni';
									|tr = 'Alan birimleri'", Common.DefaultLanguageCode());
		Level2.SymbolNational = "";
		Level2.InternationalSymbol = "";
		Level2.CodeLetterDesignationNational = "";
		Level2.CodeLetterDesignationInternational = "";
		Level2.Numerator = 0;
		Level2.Denominator = 0;
		Level2.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "054";
		Level3.Description = NStr("vi = 'Nghìn decimet vuông';
									|ru = 'Тысяча квадратных дециметров';
									|en = 'Thousand square decimeters'; fa = 'Thousand square decimeters';
									|it = 'Mille decimetri quadrati';
									|pl = 'Tysiąc decymetrów kwadratowych';
									|tr = 'Bin desimetre kare'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 dm2';
											|ru = '1000 дм2';
											|en = '1,000 dm2'; fa = '1,000 dm2';
											|it = '1000 dm2';
											|pl = '1000 dm2';
											|tr = '1000 dm2'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 DM2';
															|ru = 'ТЫС ДМ2';
															|en = 'THOUS DM2'; fa = 'THOUS DM2';
															|it = 'MILLE DM2';
															|pl = 'TYS DM2';
															|tr = 'BİN DM2'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 10;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "056";
		Level3.Description = NStr("vi = 'Triệu decimet vuông';
									|ru = 'Миллион квадратных дециметров';
									|en = 'Million square decimeters'; fa = 'Million square decimeters';
									|it = 'Un milione di decimetri quadrati';
									|pl = 'Milion decymetrów kwadratowych';
									|tr = 'Milyon desimetre kare'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 dm2';
											|ru = '10^6 дм2';
											|en = '10^6 dm2'; fa = '10^6 dm2';
											|it = '10^6 dm22';
											|pl = '10^6 dm2';
											|tr = '10^6 dm2'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu dm2';
															|ru = 'МЛН ДМ2';
															|en = 'MIL DM2'; fa = 'MIL DM2';
															|it = 'MLN DM2';
															|pl = 'MLN DM2';
															|tr = 'MİLYON DM2'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 10000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "057";
		Level3.Description = NStr("vi = 'Triệu mét vuông';
									|ru = 'Миллион квадратных метров';
									|en = 'Million square meters'; fa = 'Million square meters';
									|it = 'Un milione di metri quadrati';
									|pl = 'Milion metrów kwadratowych';
									|tr = 'Milyon metre kare'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 m2';
											|ru = '10^6 м2';
											|en = '10^6 m2'; fa = '10^6 m2';
											|it = '10^6 m2';
											|pl = '10^6 m2';
											|tr = '10^6 m2'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU M2';
															|ru = 'МЛН М2';
															|en = 'MIL M2'; fa = 'MIL M2';
															|it = 'MLN M2';
															|pl = 'MLN M2';
															|tr = 'MLN M2'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "060";
		Level3.Description = NStr("vi = 'Nghìn hecta';
									|ru = 'Тысяча гектаров';
									|en = 'Thousand hectares'; fa = 'Thousand hectares';
									|it = 'Mille ettari';
									|pl = 'Tysiąc hektarów';
									|tr = 'Bin hektar'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 ha';
											|ru = '1000 га';
											|en = '1,000 ha'; fa = '1,000 ha';
											|it = '1000 ha';
											|pl = '1000 ha';
											|tr = '1000 ha'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN HA';
															|ru = 'ТЫС ГА';
															|en = 'THOUS HA'; fa = 'THOUS HA';
															|it = 'MILLE HA';
															|pl = 'TYS HA';
															|tr = 'BİN HA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 10000000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "062";
		Level3.Description = NStr("vi = 'Mét vuông quy ước';
									|ru = 'Условный квадратный метр';
									|en = 'Conventional square meter'; fa = 'Conventional square meter';
									|it = 'Un metro quadrato convenzionale';
									|pl = 'Umowny metr kwadratowy';
									|tr = 'Koşullu metre kare'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'm2 quy ước';
											|ru = 'усл. м2';
											|en = 'convl. m2'; fa = 'convl. m2';
											|it = 'm2 conv.';
											|pl = 'м2 war';
											|tr = 'koşullu. m2'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M2 QUY ƯỚC';
															|ru = 'УСЛ М2';
															|en = 'CONVL M2'; fa = 'CONVL M2';
															|it = 'M2 CONV.';
															|pl = 'M2 WAR';
															|tr = 'KOŞULLU M2'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "063";
		Level3.Description = NStr("vi = 'Nghìn mét vuông quy ước';
									|ru = 'Тысяча условных квадратных метров';
									|en = 'Thousand conventional square meters'; fa = 'Thousand conventional square meters';
									|it = 'Mille metri quadrati convenzionali';
									|pl = 'Tysiąc umownych metrów kwadratowych';
									|tr = 'Koşullu bin metre kare'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 m2 quy ước';
											|ru = '1000 усл. м2';
											|en = '1,000 convl. m2'; fa = '1,000 convl. m2';
											|it = '1000 m2 conv.';
											|pl = '1000 м2 war';
											|tr = '1000 koşullu. m2'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn m2 quy ước';
															|ru = 'ТЫС УСЛ М2';
															|en = 'THOUS CONVL M2'; fa = 'THOUS CONVL M2';
															|it = 'MILLE M2 CONV.';
															|pl = 'TYS M2 WAR';
															|tr = 'KOŞULLU BİN M2'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "064";
		Level3.Description = NStr("vi = 'Triệu mét vuông quy ước';
									|ru = 'Миллион условных квадратных метров';
									|en = 'Million conventional square meters'; fa = 'Million conventional square meters';
									|it = 'Un milione di metri quadrati convenzionali';
									|pl = 'Milion umownych metrów kwadratowych';
									|tr = 'Koşullu milyon metre kare'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 m2 quy ước';
											|ru = '10^6 усл. м2';
											|en = '10^6 convl. m2'; fa = '10^6 convl. m2';
											|it = '10^6 m2 conv.';
											|pl = '10^6 m2 war';
											|tr = '10^6 koşullu. m2'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu m2 quy ước';
															|ru = 'МЛН УСЛ М2';
															|en = 'MIL CONVL M2'; fa = 'MIL CONVL M2';
															|it = 'MLN M2 CONV.';
															|pl = 'MLN М2 WAR';
															|tr = 'KOŞULLU MİLYON M2'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "081";
		Level3.Description = NStr("vi = 'Mét vuông tổng diện tích';
									|ru = 'Квадратный метр общей площади';
									|en = 'Square meter of the total area'; fa = 'Square meter of the total area';
									|it = 'Un metro quadrato di superficie comune';
									|pl = 'Metr kwadratowy powierzchni ogólnej';
									|tr = 'Genel alanın metrekaresi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'm2 tổng diện tích';
											|ru = 'м2 общ. пл';
											|en = 'm2 ttl area'; fa = 'm2 ttl area';
											|it = 'm2 di sup. com.';
											|pl = 'm2 pow. ogóln';
											|tr = 'genel. alan m2'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M2 TỔNG DIỆN TÍCH CHUNG';
															|ru = 'М2 ОБЩ ПЛ';
															|en = 'M2 TOTAL AREA'; fa = 'M2 TOTAL AREA';
															|it = 'M2 SUP. COM.';
															|pl = 'M2 POW OGÓLN';
															|tr = 'GENEL ALAN M2'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "082";
		Level3.Description = NStr("vi = 'Nghìn mét vuông tổng diện tích';
									|ru = 'Тысяча квадратных метров общей площади';
									|en = 'Thousand square meters of the total area'; fa = 'Thousand square meters of the total area';
									|it = 'Mille metri quadrati di superficie comune';
									|pl = 'Tysiąc metrów kwadratowych powierzchni ogólnej';
									|tr = 'Bin metrekare genel alan'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 m2 tổng diện tích';
											|ru = '1000 м2 общ. пл';
											|en = '1,000 m2 total area'; fa = '1,000 m2 total area';
											|it = '1000 m2 di sup. com.';
											|pl = '1000 m2 pow. ogóln';
											|tr = '1000 m2 genel. alan'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN M2 TỔNG DIỆN TÍCH';
															|ru = 'ТЫС М2 ОБЩ ПЛ';
															|en = 'THOUS M2 TOTAL AREA'; fa = 'THOUS M2 TOTAL AREA';
															|it = 'MILLE M2 DI SUP. COM.';
															|pl = 'TYS M2 POW. OGÓLN';
															|tr = 'BİN M2 GENEL ALAN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "083";
		Level3.Description = NStr("vi = 'Triệu mét vuông tổng diện tích';
									|ru = 'Миллион квадратных метров общей площади';
									|en = 'Million square meters of the total area'; fa = 'Million square meters of the total area';
									|it = 'Un milione di metri quadrati di superficie comune';
									|pl = 'Milion metrów kwadratowych powierzchni ogólnej';
									|tr = 'Milyon metrekare genel alan'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 m2 tổng diện tích';
											|ru = '10^6 м2 общ. пл';
											|en = '10^6 m2 total area'; fa = '10^6 m2 total area';
											|it = '10^6 m2 di sup. com.';
											|pl = '10^6 m2 pow. ogóln';
											|tr = '10^6 m2 genel. alan'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu M2 tổng diện tích';
															|ru = 'МЛН М2. ОБЩ ПЛ';
															|en = 'MIL M2 TOTAL AREA'; fa = 'MIL M2 TOTAL AREA';
															|it = 'MLN M2 DI SUP. COM.';
															|pl = 'MLN M2 POW. OGÓLN';
															|tr = 'MİLYON M2. GENEL ALAN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "084";
		Level3.Description = NStr("vi = 'Mét vuông diện tích nhà ở';
									|ru = 'Квадратный метр жилой площади';
									|en = 'Square meter of living space'; fa = 'Square meter of living space';
									|it = 'Un metro quadrato di superficie abitabile';
									|pl = 'Metr kwadratowy powierzchni mieszkalnej';
									|tr = 'Metrekare yaşam alanı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'm2 diện tích nhà ở';
											|ru = 'м2 жил. пл';
											|en = 'm2 lvng space'; fa = 'm2 lvng space';
											|it = 'm2 di sup. abit.';
											|pl = 'm2 pow. miesz';
											|tr = 'm2 yaşam. alanı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M2 DIỆN TÍCH NHÀ Ở';
															|ru = 'М2 ЖИЛ ПЛ';
															|en = 'M2 LIVING SPACE'; fa = 'M2 LIVING SPACE';
															|it = 'M2 SUP. ABIT.';
															|pl = 'M2 POW MIESZ';
															|tr = 'M2 YAŞAM ALANI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "085";
		Level3.Description = NStr("vi = 'Nghìn mét vuông diện tích nhà ở';
									|ru = 'Тысяча квадратных метров жилой площади';
									|en = 'Thousand square meters of living space'; fa = 'Thousand square meters of living space';
									|it = 'Mille metri quadrati di superficie abitabile';
									|pl = 'Tysiąc metrów kwadratowych powierzchni mieszkalnej';
									|tr = 'Bin metrekare yaşam alanı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 m2 diện tích nhà ở';
											|ru = '1000 м2 жил. пл';
											|en = '1,000 m2 living space'; fa = '1,000 m2 living space';
											|it = '1000 m2 di sup. abit.';
											|pl = '1000 M2 POW. MIESZ';
											|tr = '1000 m2 yaşam. alanı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN M2 DIỆN ÍCH NHÀ Ở';
															|ru = 'ТЫС М2 ЖИЛ ПЛ';
															|en = 'THOUS M2 LIVING SPACE'; fa = 'THOUS M2 LIVING SPACE';
															|it = 'MILLE M2 DI SUP. ABIT.';
															|pl = 'TYS M2 POW MIESZ';
															|tr = 'BİN M2 YAŞAM ALANI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "086";
		Level3.Description = NStr("vi = 'Triệu mét vuông diện tích nhà ở';
									|ru = 'Миллион квадратных метров жилой площади';
									|en = 'Million square meters of living space'; fa = 'Million square meters of living space';
									|it = 'Un milione di metri quadrati di superficie abitabile';
									|pl = 'Milion metrów kwadratowych powierzchni mieszkalnej';
									|tr = 'Milyon metrekare yaşam alanı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 m2 diện tích nhà ở';
											|ru = '10^6 м2 жил. пл';
											|en = '10^6 m2 living space'; fa = '10^6 m2 living space';
											|it = '10^6 m2 di sup. abit.';
											|pl = '10^6 m2 pow. miesz';
											|tr = '10^6 m2 yaşam. alanı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu M2 diện tích nhà ở';
															|ru = 'МЛН М2 ЖИЛ ПЛ';
															|en = 'MIL M2 LIVING SPACE'; fa = 'MIL M2 LIVING SPACE';
															|it = 'MLN M2 DI SUP. ABIT.';
															|pl = 'MLN M2 POW MIESZ';
															|tr = 'MİLYON M2 YAŞAM ALANI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "087";
		Level3.Description = NStr("vi = 'Mét vuông tòa nhà thí nghiệm giáo dục';
									|ru = 'Квадратный метр учебно - лабораторных зданий';
									|en = 'Square meter of educational and laboratory buildings'; fa = 'Square meter of educational and laboratory buildings';
									|it = 'Un metro quadrato di edifici scolatici e laboratoriali';
									|pl = 'Metr kwadratowy budynków edukacyjnych i laboratoryjnych';
									|tr = 'Eğitim - laboratuvar binası metrekare'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'm2 tòa nhà thí nghiệm giáo dục';
											|ru = 'м2 уч. лаб. здан';
											|en = 'm2 ed. lab. bldg'; fa = 'm2 ed. lab. bldg';
											|it = 'm2 di edif. scol. lab.';
											|pl = 'm2 bud. eduk. i laborat';
											|tr = 'm2 eğitim. laboratuvar. binası'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M2 TÒA NHÀ THÍ NGHIỆM GIÁO DỤC';
															|ru = 'М2 УЧ.ЛАБ ЗДАН';
															|en = 'M2 ED LAB BLDG'; fa = 'M2 ED LAB BLDG';
															|it = 'M2 ED. SCOL. LAB.';
															|pl = 'M2 BUD. EDUK. I LABORAT';
															|tr = 'M2 EĞİTİM.LABORATUVAR BİNASI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "088";
		Level3.Description = NStr("vi = 'Nghìn mét vuông tòa nhà thí nghiệm giáo dục';
									|ru = 'Тысяча квадратных метров учебно - лабораторных зданий';
									|en = 'Thousand square meters of educational and laboratory buildings'; fa = 'Thousand square meters of educational and laboratory buildings';
									|it = 'Mille metri quadrati di edifici scolastici e laboratoriali';
									|pl = 'Tysiąc metrów kwadratowych budynków edukacyjnych i laboratoryjnych';
									|tr = 'Bin metrekare eğitim - laboratuvar binası'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 m2 tòa nhà thí nghiệm giáo dục';
											|ru = '1000 м2 уч. лаб. здан';
											|en = '1,000 m2 ed. lab. bldg'; fa = '1,000 m2 ed. lab. bldg';
											|it = '1000 m2 di ed. scol. lab.';
											|pl = '1000 m2 bud. eduk. i laborat';
											|tr = '1000 m2 eğitim. laboratuvar. binası'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn M2 TOÀN NHÀ THÍ NGHIỆM GIÁO DỤC';
															|ru = 'ТЫС М2 УЧ.ЛАБ ЗДАН';
															|en = 'THOUS M2 ED LAB BLDG'; fa = 'THOUS M2 ED LAB BLDG';
															|it = 'MILLE M2 DI ED. SCOL. LAB.';
															|pl = 'TYS М2 BUD ED. I LAB';
															|tr = 'BİN M2 EĞİTİM.LABORATUVAR BİNASI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "AreaTypeOfMeasurement";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "089";
		Level3.Description = NStr("vi = 'Triệu mét vuông trong hai milimét';
									|ru = 'Миллион квадратных метров в двухмиллиметровом исчислении';
									|en = 'Million square meters in two millimeters calculation'; fa = 'Million square meters in two millimeters calculation';
									|it = 'Un milione di metri quadrati in unità da due millimetri';
									|pl = 'Milion metrów kwadratowych w obliczeniu dwóch-milimetrowym';
									|tr = 'İki milimetre cinsinden milyon metrekare'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 m2 2 mm';
											|ru = '10^6 м2 2 мм исч';
											|en = '10^6 m2 2 mm calc'; fa = '10^6 m2 2 mm calc';
											|it = '10^6 m2 2 mm per unità';
											|pl = '10^6 m2 w obl 2 mm';
											|tr = '10^6 m2 2 mm cinsinden'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu M2 2MM';
															|ru = 'МЛН М2 2ММ ИСЧ';
															|en = 'MIL M2 2 MM CALC'; fa = 'MIL M2 2 MM CALC';
															|it = 'MLN M2 2MM PER UNITÀ';
															|pl = 'MLN M2 W OBL 2MM';
															|tr = '2MM CİNSİNDEN MİLYON METREKARE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level2 = Level1.Rows.Add();
		Level2.NumericCode = "";
		Level2.Description = NStr("vi = 'Đơn vị thể tích';
									|ru = 'Единицы объема';
									|en = 'Units of volume'; fa = 'Units of volume';
									|it = 'Unità di volume';
									|pl = 'Jednostki objętości';
									|tr = 'Hacim birimleri'", Common.DefaultLanguageCode());
		Level2.SymbolNational = "";
		Level2.InternationalSymbol = "";
		Level2.CodeLetterDesignationNational = "";
		Level2.CodeLetterDesignationInternational = "";
		Level2.Numerator = 0;
		Level2.Denominator = 0;
		Level2.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "114";
		Level3.Description = NStr("vi = 'Nghìn mét khối';
									|ru = 'Тысяча кубических метров';
									|en = 'Thousand cubic meters'; fa = 'Thousand cubic meters';
									|it = 'Mille metri cubi';
									|pl = 'Tysiąc metrów sześciennych';
									|tr = 'Bin metreküp'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 m3';
											|ru = '1000 м3';
											|en = '1,000 m3'; fa = '1,000 m3';
											|it = '1000 m3';
											|pl = '1000 m3';
											|tr = '1000 m3'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn m3';
															|ru = 'ТЫС МЗ';
															|en = 'THOUS M3'; fa = 'THOUS M3';
															|it = 'MILLE M3';
															|pl = 'TYS MЗ';
															|tr = 'BİN M3'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "VolumeM3";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "115";
		Level3.Description = NStr("vi = 'Tỷ mét khối';
									|ru = 'Миллиард кубических метров';
									|en = 'Billion cubic meters'; fa = 'Billion cubic meters';
									|it = 'Un miliardo di metri cubi';
									|pl = 'Miliard metrów sześciennych';
									|tr = 'Milyar metreküp'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^9 m3';
											|ru = '10^9 м3';
											|en = '10^9 m3'; fa = '10^9 m3';
											|it = '10^9 m3';
											|pl = '10^9 m3';
											|tr = '10^9 m3'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Tỷ M3';
															|ru = 'МЛРД М3';
															|en = 'BN M3'; fa = 'BN M3';
															|it = 'MLD M3';
															|pl = 'MLD M3';
															|tr = 'MİLYAR M3'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "116";
		Level3.Description = NStr("vi = 'Decalit';
									|ru = 'Декалитр';
									|en = 'Decaliter'; fa = 'Decaliter';
									|it = 'Decalitro';
									|pl = 'Decaliter';
									|tr = 'Dekalitre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'DCL';
											|ru = 'дкл';
											|en = 'DAL'; fa = 'DAL';
											|it = 'дкл';
											|pl = 'DAL';
											|tr = 'DKL'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'DCL';
															|ru = 'ДКЛ';
															|en = 'DAL'; fa = 'DAL';
															|it = 'ДКЛ';
															|pl = 'DAL';
															|tr = 'DKL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 100;
		Level3.MeasuredValueType = "VolumeM3";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "119";
		Level3.Description = NStr("vi = '1000 decalit';
									|ru = 'Тысяча декалитров';
									|en = 'Thousand decaliters'; fa = 'Thousand decaliters';
									|it = 'Mille decalitri';
									|pl = 'Tysiąc dekalitrów';
									|tr = 'Bin dekalitre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 dcl';
											|ru = '1000 дкл';
											|en = '1,000 dal'; fa = '1,000 dal';
											|it = '1000 dal';
											|pl = '1000 dal';
											|tr = '1000 dkl'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 DCL';
															|ru = 'ТЫС ДКЛ';
															|en = 'THOUS DAL'; fa = 'THOUS DAL';
															|it = 'MILLE DAL';
															|pl = 'TYS DAL';
															|tr = 'BİN DKL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 10;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "VolumeM3";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "120";
		Level3.Description = NStr("vi = '1 triệu decalit';
									|ru = 'Миллион декалитров';
									|en = 'Million decaliters'; fa = 'Million decaliters';
									|it = 'Un milione di decalitri';
									|pl = 'Milion dekalitrów';
									|tr = 'Milyon dekalitre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 dcl';
											|ru = '10^6 дкл';
											|en = '10^6 dal'; fa = '10^6 dal';
											|it = '10^6 dal';
											|pl = '10^6 dal';
											|tr = '10^6 dkl'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1 triệu DCL';
															|ru = 'МЛН ДКЛ';
															|en = 'MIL DAL'; fa = 'MIL DAL';
															|it = 'MLN DAL';
															|pl = 'MLN DAL';
															|tr = 'MİLYON DKL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 10000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "VolumeM3";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "121";
		Level3.Description = NStr("vi = 'Mét khối đậm đặc';
									|ru = 'Плотный кубический метр';
									|en = 'Solid cubic meter'; fa = 'Solid cubic meter';
									|it = 'Metro cubo pieno';
									|pl = 'Metr sześcienny';
									|tr = 'Yoğun metreküp'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'm3 đậm đặc';
											|ru = 'плотн. м3';
											|en = 'solid m3 s'; fa = 'solid m3 s';
											|it = 'm3 pieno';
											|pl = 'm3';
											|tr = 'yoğun. m3'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M3 ĐẬM ĐẶC';
															|ru = 'ПЛОТН МЗ';
															|en = 'SOLID M3'; fa = 'SOLID M3';
															|it = 'M3 PIENO';
															|pl = 'M3';
															|tr = 'YOĞUN M3'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "123";
		Level3.Description = NStr("vi = 'Mét khối quy ước';
									|ru = 'Условный кубический метр';
									|en = 'Conventional cubic meter'; fa = 'Conventional cubic meter';
									|it = 'Metro cubo convenzionale';
									|pl = 'Umowny metr sześcienny';
									|tr = 'Koşullu metreküp'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'm3 quy ước';
											|ru = 'усл. м3';
											|en = 'convl. m3'; fa = 'convl. m3';
											|it = 'm3 conv.';
											|pl = 'м3 war';
											|tr = 'koşullu. m3'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'm3 quy ước';
															|ru = 'УСЛ М3';
															|en = 'CONVL M3'; fa = 'CONVL M3';
															|it = 'M3 CONV.';
															|pl = 'M3 WAR';
															|tr = 'KOŞULLU M3'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "VolumeM3";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "124";
		Level3.Description = NStr("vi = '1000 mét khối quy ước';
									|ru = 'Тысяча условных кубических метров';
									|en = 'Thousand conventional cubic meters'; fa = 'Thousand conventional cubic meters';
									|it = 'Mille metri cubi convenzionali';
									|pl = 'Tysiąc umownych metrów sześciennych';
									|tr = 'Koşullu bin metreküp'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 m3 quy ước';
											|ru = '1000 усл. м3';
											|en = '1,000 convl. m3'; fa = '1,000 convl. m3';
											|it = '1000 m3 conv.';
											|pl = '1000 war. m3';
											|tr = '1000 koşullu metreküp'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN M3 QUY ƯỚC';
															|ru = 'ТЫС УСЛ МЗ';
															|en = 'THOUS CONVL M3'; fa = 'THOUS CONVL M3';
															|it = 'MILLE M2 CONV.';
															|pl = 'TYS WAR M3';
															|tr = 'BİN KOŞULLU M3'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "VolumeM3";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "125";
		Level3.Description = NStr("vi = 'Triệu mét khối chế biến khí';
									|ru = 'Миллион кубических метров переработки газа';
									|en = 'Million cubic meters of gas processing'; fa = 'Million cubic meters of gas processing';
									|it = 'Un milione di metri cubi di lavorazione di gas';
									|pl = 'Milion metrów sześciennych przetwarzania gazu';
									|tr = 'Milyon metreküp gaz işleme'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 m3 chế biến khí';
											|ru = '10^6 м3 перераб. газа';
											|en = '10^6 m3 gas processing'; fa = '10^6 m3 gas processing';
											|it = '10^6 m3 lavorazione di gas';
											|pl = '10^6 m3 przetworz gazu';
											|tr = '10^6 m3 gaz işleme'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU M3 CHẾ BIẾN KHÍ';
															|ru = 'МЛН МЗ ПЕРЕРАБ ГАЗА';
															|en = 'MIL M3 GAS PROCESSING'; fa = 'MIL M3 GAS PROCESSING';
															|it = 'MLN M3 LAVORAZIONE DI GAS';
															|pl = 'MLN MЗ PRZETWORZ GAZU';
															|tr = 'MİLYON M3 GAZ İŞLEME'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "127";
		Level3.Description = NStr("vi = 'Nghìn mét khối đậm đặc';
									|ru = 'Тысяча плотных кубических метров';
									|en = 'Thousand solid cubic meters'; fa = 'Thousand solid cubic meters';
									|it = 'Mille metri cubi pieni';
									|pl = 'Tysiąc metrów sześciennych';
									|tr = 'Yoğun bin metreküp'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 m3 đậm đặc';
											|ru = '1000 плотн. м3';
											|en = '1,000 solid m3'; fa = '1,000 solid m3';
											|it = '1000 m3 pieni';
											|pl = '1000 m3';
											|tr = '1000 yoğun. m3'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 M3 ĐẬM ĐẶC';
															|ru = 'ТЫС ПЛОТН МЗ';
															|en = 'THOUS SOLID M3'; fa = 'THOUS SOLID M3';
															|it = 'MILLE M3 PIENI';
															|pl = 'TYS MЗ';
															|tr = 'YOĞUN BİN M3'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "128";
		Level3.Description = NStr("vi = '1000 nửa lít';
									|ru = 'Тысяча полулитров';
									|en = 'Thousand half liters'; fa = 'Thousand half liters';
									|it = 'Mille mezzo litri';
									|pl = 'Tysiąc półlitrów';
									|tr = 'Bin yarım litre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 nửa lít';
											|ru = '1000 пол. л';
											|en = '1,000 half l'; fa = '1,000 half l';
											|it = '1000 mezzo l';
											|pl = '1000 półlitrów';
											|tr = '1000 yarım. lt'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 NỬA LÍT';
															|ru = 'ТЫС ПОЛ Л';
															|en = 'THOUS HALF L'; fa = 'THOUS HALF L';
															|it = 'MILLE MEZZO L';
															|pl = 'TYS PÓŁLITRÓW';
															|tr = 'BİN YARIM LT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "129";
		Level3.Description = NStr("vi = '1 triệu nửa lít';
									|ru = 'Миллион полулитров';
									|en = 'Million half liters'; fa = 'Million half liters';
									|it = 'Un milione di mezzo litri';
									|pl = 'Milion półlitrów';
									|tr = 'Milyon yarım litre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 nửa lít';
											|ru = '10^6 пол. л';
											|en = '10^6 half l'; fa = '10^6 half l';
											|it = '10^6 di mezzo litri';
											|pl = '10^6 półlitrów';
											|tr = '10^6 yarım. lt'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1 triệu NỬA LÍT';
															|ru = 'МЛН ПОЛ Л';
															|en = 'MIL HALF L'; fa = 'MIL HALF L';
															|it = 'MLN DI MEZZO L';
															|pl = 'MLN PÓŁLITRÓW';
															|tr = 'MİLYON YARIM LT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "130";
		Level3.Description = NStr("vi = '1000 lít';
									|ru = 'Тысяча литров';
									|en = 'Thousand liters'; fa = 'Thousand liters';
									|it = 'Mille litri';
									|pl = 'Tysiąc litrów';
									|tr = 'Bin litre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 l';
											|ru = '1000 л';
											|en = '1,000 l'; fa = '1,000 l';
											|it = '1000 l';
											|pl = '1000 l';
											|tr = '1000 lt'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 l';
															|ru = 'ТЫС Л';
															|en = 'THOUS L'; fa = 'THOUS L';
															|it = 'MILLE L';
															|pl = 'TYS L';
															|tr = 'BİN LT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "VolumeM3";
		Level2 = Level1.Rows.Add();
		Level2.NumericCode = "";
		Level2.Description = NStr("vi = 'Đơn vị trọng lượng';
									|ru = 'Единицы массы';
									|en = 'Units of mass'; fa = 'Units of mass';
									|it = 'Unità di massa';
									|pl = 'Jednostki masy';
									|tr = 'Ağırlık birimleri'", Common.DefaultLanguageCode());
		Level2.SymbolNational = "";
		Level2.InternationalSymbol = "";
		Level2.CodeLetterDesignationNational = "";
		Level2.CodeLetterDesignationInternational = "";
		Level2.Numerator = 0;
		Level2.Denominator = 0;
		Level2.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "165";
		Level3.Description = NStr("vi = '1000 carat';
									|ru = 'Тысяча каратов метрических';
									|en = 'Thousand metric carats'; fa = 'Thousand metric carats';
									|it = 'Mille carati metrici';
									|pl = 'Tysiąc karatów metrycznych';
									|tr = 'Bin metrik karat'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 car';
											|ru = '1000 кар';
											|en = '1,000 ct'; fa = '1,000 ct';
											|it = '1000 kt (ct)';
											|pl = '1000 kar';
											|tr = '1000 karat'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 car';
															|ru = 'ТЫС КАР';
															|en = 'THOUS CT'; fa = 'THOUS CT';
															|it = 'MILLE KT (CT)';
															|pl = 'TYS KAR';
															|tr = 'BİN KARAT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 2;
		Level3.Denominator = 10;
		Level3.MeasuredValueType = "Weight";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "167";
		Level3.Description = NStr("vi = '1 triệu carat';
									|ru = 'Миллион каратов метрических';
									|en = 'Million metric carats'; fa = 'Million metric carats';
									|it = 'Un milione di carati metrici';
									|pl = 'Milion karatów metrycznych';
									|tr = 'Milyon metrik karat'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 car';
											|ru = '10^6 кар';
											|en = '10^6 ct'; fa = '10^6 ct';
											|it = '10^6 kt (ct)';
											|pl = '10^6 kar';
											|tr = '10^6 karat'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1 TRIỆU CAR';
															|ru = 'МЛН КАР';
															|en = 'MIL CT'; fa = 'MIL CT';
															|it = 'MLN KT (CT)';
															|pl = 'MLN KAR';
															|tr = 'MİLYON KARAT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 200;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Weight";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "169";
		Level3.Description = NStr("vi = '1000 tấn';
									|ru = 'Тысяча тонн';
									|en = 'Thousand tons'; fa = 'Thousand tons';
									|it = 'Mille tonnellate';
									|pl = 'Tysiąc ton';
									|tr = 'BİN TON'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 t';
											|ru = '1000 т';
											|en = '1,000 t'; fa = '1,000 t';
											|it = '1000 t';
											|pl = '1000 t';
											|tr = '1000 t'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 T';
															|ru = 'ТЫС Т';
															|en = 'THOUS T'; fa = 'THOUS T';
															|it = 'MILLE  T';
															|pl = 'TYS T';
															|tr = 'BİN T'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Weight";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "171";
		Level3.Description = NStr("vi = '1 triệu tấn';
									|ru = 'Миллион тонн';
									|en = 'Million tons'; fa = 'Million tons';
									|it = 'Un milione di tonnellate';
									|pl = 'Milion ton';
									|tr = 'Milyon ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 t';
											|ru = '10^6 т';
											|en = '10^6 t'; fa = '10^6 t';
											|it = '10^6 t';
											|pl = '10^6 t';
											|tr = '10^6 t'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1 TRIỆU T';
															|ru = 'МЛН Т';
															|en = 'MIL T'; fa = 'MIL T';
															|it = 'MLN T';
															|pl = 'MLN T';
															|tr = 'MİLYON T'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "172";
		Level3.Description = NStr("vi = 'Tấn nhiên liệu quy ước';
									|ru = 'Тонна условного топлива';
									|en = 'Ton of oil equivalent'; fa = 'Ton of oil equivalent';
									|it = 'Una tonnellata di carburante convenzionale';
									|pl = 'Tona paliwa umownego';
									|tr = 'Koşullu yakıt tonu'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Tấn nhiên liệu quy ước';
											|ru = 'т усл. топл';
											|en = 'toe'; fa = 'toe';
											|it = 't di carb. conv.';
											|pl = 't pal. umownego';
											|tr = 't koşullu. yakıt'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'T nhiên liệu quy ước';
															|ru = 'Т УСЛ ТОПЛ';
															|en = 'TOE S'; fa = 'TOE S';
															|it = 'T DI CARB. CONV.';
															|pl = 'T PAL UMOWNEGO';
															|tr = 'T KOŞULLU YAKIT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "175";
		Level3.Description = NStr("vi = 'Nghìn tấn nhiên liệu quy ước';
									|ru = 'Тысяча тонн условного топлива';
									|en = 'Thousand tons of oil equivalent'; fa = 'Thousand tons of oil equivalent';
									|it = 'Mille tonnellate di carburante convenzionale';
									|pl = 'Tysiąc ton paliwa umownego';
									|tr = 'Binlerce ton koşullu yakıt'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 t nhiên liệu quy ước';
											|ru = '1000 т усл. топл';
											|en = '1,000 toe'; fa = '1,000 toe';
											|it = '1000 t di carb. conv.';
											|pl = '1000 t pal. umown';
											|tr = '1000 t koşullu yakıt'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn t nhiên liệu quy ước';
															|ru = 'ТЫС Т УСЛ ТОПЛ';
															|en = 'THOUS TOE'; fa = 'THOUS TOE';
															|it = 'MILLE T DI CARB. CONV.';
															|pl = 'TYS T PAL UMOWN';
															|tr = 'BİNLERCE T KOŞULLU YAKIT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "176";
		Level3.Description = NStr("vi = 'Triệu tấn nhiên liệu quy ước';
									|ru = 'Миллион тонн условного топлива';
									|en = 'Million tons of oil equivalent'; fa = 'Million tons of oil equivalent';
									|it = 'Un milione di tonnellate di carburante convenzionale';
									|pl = 'Milion ton paliwa umownego';
									|tr = 'Milyon ton koşullu yakıt'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 t nhiên liệu quy ước';
											|ru = '10^6 т усл. топл';
											|en = '10^6 toe'; fa = '10^6 toe';
											|it = '10^6 t di carb. conv.';
											|pl = '10^6 t pal. umown';
											|tr = '10^6 t koşullu. yakıt'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu t nhiên liệu quy ước';
															|ru = 'МЛН Т УСЛ ТОПЛ';
															|en = 'MIL TOE'; fa = 'MIL TOE';
															|it = 'MLN T DI CARB. CONV.';
															|pl = 'MLN T PAL UMOWN';
															|tr = 'MİLYON T KOŞULLU YAKIT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "177";
		Level3.Description = NStr("vi = 'Nghìn tấn lưu trữ một lần';
									|ru = 'Тысяча тонн единовременного хранения';
									|en = 'Thousand tons of one-time storage'; fa = 'Thousand tons of one-time storage';
									|it = 'Mille tonnellate di stoccaggio simultaneo';
									|pl = 'Tys ton jednorazowego przechowywania';
									|tr = 'Binlerce ton tek seferlik depolama'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 t lưu trữ một lần';
											|ru = '1000 т единовр. хран';
											|en = '1,000 t one-time storage'; fa = '1,000 t one-time storage';
											|it = '1000 t di stocc. sim.';
											|pl = '1000 t jednoraz. przech';
											|tr = '1000 t tek seferlik. depolama'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn t lưu trữ một lần';
															|ru = 'ТЫС Т ЕДИНОВР ХРАН';
															|en = 'TOUS T ONE-TIME STORAGE'; fa = 'TOUS T ONE-TIME STORAGE';
															|it = 'MILLE T DI STOCC. SIM';
															|pl = 'TYS T JEDNORAZ PRZECH';
															|tr = 'BİNLERCE T TEK SEFERLİK DEPOLAMA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "178";
		Level3.Description = NStr("vi = 'Nghìn tấn chế biến';
									|ru = 'Тысяча тонн переработки';
									|en = 'Thousand tons of processing'; fa = 'Thousand tons of processing';
									|it = 'Mille tonnellate di riciclaggio';
									|pl = 'Tysiąc ton przetwarzania';
									|tr = 'İşlenen bin ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 t chế biến';
											|ru = '1000 т перераб';
											|en = '1,000 t processing'; fa = '1,000 t processing';
											|it = '100o t di ricicl.';
											|pl = '1000 t przetwarz';
											|tr = '1000 t işlemeler'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN TẤN CHẾ BIẾN';
															|ru = 'ТЫС Т ПЕРЕРАБ';
															|en = 'THOUS T PROCESSING'; fa = 'THOUS T PROCESSING';
															|it = 'MILLE T DI RICICL.';
															|pl = 'TYS T PRZETWARZ';
															|tr = 'BİNLERCE T İŞLEMELER'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "179";
		Level3.Description = NStr("vi = 'Tấn quy ước T';
									|ru = 'Условная тонна Т';
									|en = 'Conventional ton T'; fa = 'Conventional ton T';
									|it = 'Tonnellata convenzionale T';
									|pl = 'Tona umowna T';
									|tr = 'Koşullu Yakıt tonu'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 't quy ước';
											|ru = 'усл. т';
											|en = 'convl. t'; fa = 'convl. t';
											|it = 't conv.';
											|pl = 't. umow';
											|tr = 'koşullu. yakıt'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'T quy ước';
															|ru = 'УСЛ Т';
															|en = 'CONVL T'; fa = 'CONVL T';
															|it = 'T CONV.';
															|pl = 'T UMOW';
															|tr = 'KOŞULLU YAKIT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "VolumeM3";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "207";
		Level3.Description = NStr("vi = 'Nghìn tạ';
									|ru = 'Тысяча центнеров';
									|en = 'Thousand centners'; fa = 'Thousand centners';
									|it = 'Mille quintali';
									|pl = 'Tysiąc kwintalów';
									|tr = 'Binlerce sentner'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 tạ';
											|ru = '10^3 ц';
											|en = '10^3 c'; fa = '10^3 c';
											|it = '10^3 q';
											|pl = '10^3 k';
											|tr = '10^3 s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn tạ';
															|ru = 'ТЫС Ц';
															|en = 'THOUS C'; fa = 'THOUS C';
															|it = 'MILLE Q';
															|pl = 'TYS K';
															|tr = 'BİNLERCE S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 100000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Weight";
		Level2 = Level1.Rows.Add();
		Level2.NumericCode = "";
		Level2.Description = NStr("vi = 'Đơn vị kỹ thuật';
									|ru = 'Технические единицы';
									|en = 'Engineering units'; fa = 'Engineering units';
									|it = 'Unità di misura tecniche';
									|pl = 'Jednostki techniczne';
									|tr = 'Teknik birimler'", Common.DefaultLanguageCode());
		Level2.SymbolNational = "";
		Level2.InternationalSymbol = "";
		Level2.CodeLetterDesignationNational = "";
		Level2.CodeLetterDesignationInternational = "";
		Level2.Numerator = 0;
		Level2.Denominator = 0;
		Level2.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "226";
		Level3.Description = NStr("vi = 'Vôn - ampe';
									|ru = 'Вольт - ампер';
									|en = 'Volt-ampere'; fa = 'Volt-ampere';
									|it = 'Voltampere';
									|pl = 'Woltoamper';
									|tr = 'Volt - amper'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'V.A';
											|ru = 'В.А';
											|en = 'VA'; fa = 'VA';
											|it = 'VA';
											|pl = 'VA';
											|tr = 'V.A'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'V.A';
															|ru = 'В.А';
															|en = 'VA'; fa = 'VA';
															|it = 'VA';
															|pl = 'VA';
															|tr = 'V.A'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Capacity";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "231";
		Level3.Description = NStr("vi = 'Mét trên giờ';
									|ru = 'Метр в час';
									|en = 'Meter per hour'; fa = 'Meter per hour';
									|it = 'Metri all''ora';
									|pl = 'Metr na godzinę';
									|tr = 'Saatte metre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'M/H';
											|ru = 'м/ч';
											|en = 'M/H'; fa = 'M/H';
											|it = 'м/ч';
											|pl = 'M/H';
											|tr = 'M/S'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M/H';
															|ru = 'М/Ч';
															|en = 'M/H'; fa = 'M/H';
															|it = 'М/Ч';
															|pl = 'M/H';
															|tr = 'M/S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "232";
		Level3.Description = NStr("vi = 'Kilocalo';
									|ru = 'Килокалория';
									|en = 'Kilocalorie'; fa = 'Kilocalorie';
									|it = 'Kilocaloria';
									|pl = 'Kilocalorie';
									|tr = 'Kilokalori'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Kkal';
											|ru = 'ккал';
											|en = 'KCAL'; fa = 'KCAL';
											|it = 'ккал';
											|pl = 'KCAL';
											|tr = 'KKAL'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Kkal';
															|ru = 'ККАЛ';
															|en = 'KCAL'; fa = 'KCAL';
															|it = 'ККАЛ';
															|pl = 'KCAL';
															|tr = 'KKAL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1.163;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Energy";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "233";
		Level3.Description = NStr("vi = 'Gigacalo';
									|ru = 'Гигакалория';
									|en = 'Gigacalorie'; fa = 'گیگاکالری';
									|it = 'Gigacaloria';
									|pl = 'Gigacalorie';
									|tr = 'Gigakalori'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Gkal';
											|ru = 'Гкал';
											|en = 'Gcal'; fa = 'Gcal';
											|it = 'Gcal';
											|pl = 'Gcal';
											|tr = 'Gkal'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'GIGAKAL';
															|ru = 'ГИГАКАЛ';
															|en = 'GIGACAL'; fa = 'GIGACAL';
															|it = 'GIGACALORIA';
															|pl = 'GIGACAL';
															|tr = 'GİGAKAL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1163000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Energy";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "234";
		Level3.Description = NStr("vi = 'Nghìn gigacalo';
									|ru = 'Тысяча гигакалорий';
									|en = 'Thousand gigacalories'; fa = 'Thousand gigacalories';
									|it = 'Mille gigacalorie';
									|pl = 'Tysiąc gigakalorii';
									|tr = 'Binlerce gigakalori'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 Gkal';
											|ru = '1000 Гкал';
											|en = '1,000 Gcal'; fa = '1,000 Gcal';
											|it = '1000 Gcal';
											|pl = '1000 Gcal';
											|tr = '1000 Gkal'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN GIGAKAL';
															|ru = 'ТЫС ГИГАКАЛ';
															|en = 'THOUS GIGACAL'; fa = 'THOUS GIGACAL';
															|it = 'MILLE GIGACALORIE';
															|pl = 'TYS GIGAKAL';
															|tr = 'BİNLERCE GİGAKAL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1163000000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Energy";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "235";
		Level3.Description = NStr("vi = 'Triệu gigacalo';
									|ru = 'Миллион гигакалорий';
									|en = 'Million gigacalories'; fa = 'Million gigacalories';
									|it = 'Un milione di gigacalorie';
									|pl = 'Milion gigakalorii';
									|tr = 'Milyon gigakalori'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 Gkal';
											|ru = '10^6 Гкал';
											|en = '10^6 Gcal'; fa = '10^6 Gcal';
											|it = '10^6 Gcal';
											|pl = '10^6 Gcal';
											|tr = '10^6 Gkal'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU GIGAKAL';
															|ru = 'МЛН ГИГАКАЛ';
															|en = 'MIL GIGACAL'; fa = 'MIL GIGACAL';
															|it = 'MLN DI GIGACALORIE';
															|pl = 'MLN GIGAKAL';
															|tr = 'MİLYON GİGAKAL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1163000000;
		Level3.Denominator = 0.001;
		Level3.MeasuredValueType = "Energy";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "236";
		Level3.Description = NStr("vi = 'Calo mỗi giờ';
									|ru = 'Калория в час';
									|en = 'Calorie per hour'; fa = 'Calorie per hour';
									|it = 'Calorie all''ora';
									|pl = 'Kaloria na godz';
									|tr = 'Saatte kalori'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'kal/h';
											|ru = 'кал/ч';
											|en = 'cal/h'; fa = 'cal/h';
											|it = 'кал/ч';
											|pl = 'cal/h';
											|tr = 'kal/s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'kal/h';
															|ru = 'КАЛ/Ч';
															|en = 'cal/h'; fa = 'cal/h';
															|it = 'КАЛ/Ч';
															|pl = 'cal/h';
															|tr = 'kal/s'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "237";
		Level3.Description = NStr("vi = 'Kilocalo trên giờ';
									|ru = 'Килокалория в час';
									|en = 'Kilocalorie per hour'; fa = 'Kilocalorie per hour';
									|it = 'Kilocalorie all''ora';
									|pl = 'Kilokaloria na godz';
									|tr = 'Saatte kilokalori'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'KKAL/H';
											|ru = 'ккал/ч';
											|en = 'KCAL/H'; fa = 'KCAL/H';
											|it = 'ккал/ч';
											|pl = 'KCAL/H';
											|tr = 'KKAL/SA'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KKAL/H';
															|ru = 'ККАЛ/Ч';
															|en = 'KCAL/H'; fa = 'KCAL/H';
															|it = 'ККАЛ/Ч';
															|pl = 'KCAL/H';
															|tr = 'KKAL/SA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "238";
		Level3.Description = NStr("vi = 'Gigiakalo trên giờ';
									|ru = 'Гигакалория в час';
									|en = 'Gigacalorie per hour'; fa = 'Gigacalorie per hour';
									|it = 'Gigacalorie all''ora';
									|pl = 'Gigakaloria na godz';
									|tr = 'Saatte gigakalori'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Gkal/h';
											|ru = 'Гкал/ч';
											|en = 'Gcal/h'; fa = 'Gcal/h';
											|it = 'Gcal/h';
											|pl = 'Gcal/h';
											|tr = 'Gkal/s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Gigakal/h';
															|ru = 'ГИГАКАЛ/Ч';
															|en = 'GIGACAL/H'; fa = 'GIGACAL/H';
															|it = 'GIGACALORIE/H';
															|pl = 'GIGACAL/H';
															|tr = 'GİGAKAL/S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "239";
		Level3.Description = NStr("vi = 'Nghìn gigakalo trên giờ';
									|ru = 'Тысяча гигакалорий в час';
									|en = 'Thousand gigacalories per hour'; fa = 'Thousand gigacalories per hour';
									|it = 'Mille gigacalorie all''ora';
									|pl = 'Tysiąc gigakalorii na godzinę';
									|tr = 'Saatte binlerce gigakalori'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 Gkal/h';
											|ru = '1000 Гкал/ч';
											|en = '1,000 Gcal/h'; fa = '1,000 Gcal/h';
											|it = '1000 Gcal/h';
											|pl = '1000 Gcal/h';
											|tr = '1000 Gkal/s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN GIGAKAL/H';
															|ru = 'ТЫС ГИГАКАЛ/Ч';
															|en = 'THOUS GIGACAL/H'; fa = 'THOUS GIGACAL/H';
															|it = 'MILLE GIGACALORIE/H';
															|pl = 'TYS GIGAKAL/H';
															|tr = 'BİNLERCE GİGAKALORİ/S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "241";
		Level3.Description = NStr("vi = 'Triệu ampe - giờ';
									|ru = 'Миллион ампер - часов';
									|en = 'Million ampere-hours'; fa = 'Million ampere-hours';
									|it = 'Un milione di ampre-ora';
									|pl = 'Milion amperogodzin';
									|tr = 'Milyon amper - saat'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 A.h';
											|ru = '10^6 А.ч';
											|en = '10^6 A.h'; fa = '10^6 A.h';
											|it = '10^6 Ah';
											|pl = '10^6 Ah';
											|tr = '10^6 A.s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu A.h';
															|ru = 'МЛН А.Ч';
															|en = 'MIL A.H'; fa = 'MIL A.H';
															|it = 'MLN AH';
															|pl = 'MLN AH';
															|tr = 'MİLYON A.S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "242";
		Level3.Description = NStr("vi = 'Triệu kilovolt - ampe';
									|ru = 'Миллион киловольт - ампер';
									|en = 'Million kilovolt-ampere'; fa = 'Million kilovolt-ampere';
									|it = 'Un milione di kilovolt ampere';
									|pl = 'Milion kilowoltoamperów ';
									|tr = 'Milyon kilovolt - amper'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 kV.A';
											|ru = '10^6 кВ.А';
											|en = '10^6 kVA'; fa = '10^6 kVA';
											|it = '10^6 kVA';
											|pl = '10^6 kVA';
											|tr = '10^6 kV.A'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu KV.A';
															|ru = 'МЛН КВ.А';
															|en = 'MIL KVA'; fa = 'MIL KVA';
															|it = 'MLN KVA';
															|pl = 'MLN KVA';
															|tr = 'MİLYON KV.A'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "248";
		Level3.Description = NStr("vi = 'Kilovolt - ampe phản ứng';
									|ru = 'Киловольт - ампер реактивный';
									|en = 'Kilovolt-ampere reactive'; fa = 'Kilovolt-ampere reactive';
									|it = 'kilovoltampere reattivo';
									|pl = 'Kilowoltoamper reaktywny';
									|tr = 'Kilovolt - amper reaktif'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'kvar';
											|ru = 'квар';
											|en = 'kVAr'; fa = 'kVAr';
											|it = 'квар';
											|pl = 'kVAr';
											|tr = 'çeyrek'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'kvar';
															|ru = 'КВАР';
															|en = 'kVAr'; fa = 'kVAr';
															|it = 'КВАР';
															|pl = 'kVAr';
															|tr = 'çeyrek'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "249";
		Level3.Description = NStr("vi = 'Tỷ kilowatt - giờ';
									|ru = 'Миллиард киловатт - часов';
									|en = 'Billion kilowatt-hours'; fa = 'Billion kilowatt-hours';
									|it = 'Un miliardo di kilowattora';
									|pl = 'Miliard kilowatogodzin';
									|tr = 'Milyar kilowatt - saat'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^9 kW.h';
											|ru = '10^9 кВт.ч';
											|en = '10^9 kW⋅h'; fa = '10^9 kW⋅h';
											|it = '10^9 kWh';
											|pl = '10^9 kWh';
											|tr = '10^9 kWt.s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1 tỷ KWH';
															|ru = 'МЛРД КВТ.Ч';
															|en = 'BN KWH'; fa = 'BN KWH';
															|it = 'MLD KWH';
															|pl = 'MLD kWh';
															|tr = 'MILYAR KWT.S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "250";
		Level3.Description = NStr("vi = 'Nghìn kilovolt - ampe phản ứng';
									|ru = 'Тысяча киловольт - ампер реактивных';
									|en = 'Thousand kilovolt-amperes reactive'; fa = 'Thousand kilovolt-amperes reactive';
									|it = 'Mille kilovoltampere reattivi';
									|pl = 'Tysiąc kilowoltoamperów reaktywnych';
									|tr = 'Bin kilowatt - amper reaktif'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 kV.A R';
											|ru = '1000 кВ.А Р';
											|en = '1,000 kVAr'; fa = '1,000 kVAr';
											|it = '1000 kVAR';
											|pl = '1000 kVA R';
											|tr = '1000 kV.A R'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 kV.A R';
															|ru = 'ТЫС КВ.А Р';
															|en = 'THOUS KVAR'; fa = 'THOUS KVAR';
															|it = 'MILLE KVAR';
															|pl = 'TYS KVA R';
															|tr = 'BİN KV.A R'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "251";
		Level3.Description = NStr("vi = 'Mã lực';
									|ru = 'Лошадиная сила';
									|en = 'Horsepower'; fa = 'Horsepower';
									|it = 'Cavallo vapore';
									|pl = 'Koń mechaniczny';
									|tr = 'At gücü'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'mã lực';
											|ru = 'л. с';
											|en = 'hps'; fa = 'hps';
											|it = 'CV';
											|pl = 'k. m.';
											|tr = 'a. g'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Mã lực';
															|ru = 'ЛС';
															|en = 'HP'; fa = 'HP';
															|it = 'CV';
															|pl = 'HP';
															|tr = 'AG'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "252";
		Level3.Description = NStr("vi = 'Nghìn mã lực';
									|ru = 'Тысяча лошадиных сил';
									|en = 'Thousand horsepower'; fa = 'Thousand horsepower';
									|it = 'Mille cavalli vapore';
									|pl = 'Tysiąc koni mechanicznych';
									|tr = 'Bin at gücü'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 mã lực';
											|ru = '1000 л. с';
											|en = '1,000 hp'; fa = '1,000 hp';
											|it = '1000 CV';
											|pl = '1000 k.m.';
											|tr = '1000 a. g'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn mã lực';
															|ru = 'ТЫС ЛС';
															|en = 'THOUS HP'; fa = 'THOUS HP';
															|it = 'MILLE CV';
															|pl = 'TYS KM';
															|tr = 'BİN AG'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "253";
		Level3.Description = NStr("vi = 'Triệu mã lực';
									|ru = 'Миллион лошадиных сил';
									|en = 'Million horsepower'; fa = 'Million horsepower';
									|it = 'Un milione di cavalli vapore';
									|pl = 'Milion koni mechanicznych';
									|tr = 'Milyon at gücü'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 mã lực';
											|ru = '10^6 л. с';
											|en = '10^6 hp'; fa = '10^6 hp';
											|it = '10^6 CV';
											|pl = '10^6 k. m.';
											|tr = '10^6 a. g'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu mã lực';
															|ru = 'МЛН ЛС';
															|en = 'MIL HP'; fa = 'MIL HP';
															|it = 'MLN CV';
															|pl = 'MLN KM';
															|tr = 'MİLYON AG'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "254";
		Level3.Description = NStr("vi = 'bit';
									|ru = 'Бит';
									|en = 'bit'; fa = 'bit';
									|it = 'Бит';
									|pl = 'bit';
									|tr = 'bit'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'bit';
											|ru = 'бит';
											|en = 'bit'; fa = 'bit';
											|it = 'бит';
											|pl = 'bit';
											|tr = 'bit'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'bit';
															|ru = 'БИТ';
															|en = 'bit'; fa = 'bit';
															|it = 'БИТ';
															|pl = 'bit';
															|tr = 'bit'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "255";
		Level3.Description = NStr("vi = 'Byte';
									|ru = 'Байт';
									|en = 'BYTE'; fa = 'BYTE';
									|it = 'Байт';
									|pl = 'BYTE';
									|tr = 'BAYT'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Byte';
											|ru = 'байт';
											|en = 'BYTE'; fa = 'BYTE';
											|it = 'байт';
											|pl = 'BYTE';
											|tr = 'BAYT'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Byte';
															|ru = 'БАЙТ';
															|en = 'BYTE'; fa = 'BYTE';
															|it = 'БАЙТ';
															|pl = 'BYTE';
															|tr = 'BAYT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "256";
		Level3.Description = NStr("vi = 'Kilobyte';
									|ru = 'Килобайт';
									|en = 'Kilobyte'; fa = 'کیلوبایت';
									|it = 'Kilobyte';
									|pl = 'Kilobyte';
									|tr = 'Kilobayt'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'kbyte';
											|ru = 'кбайт';
											|en = 'KB'; fa = 'KB';
											|it = 'kbyte';
											|pl = 'KB';
											|tr = 'Kbayt'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'kbyte';
															|ru = 'КБАЙТ';
															|en = 'KB'; fa = 'KB';
															|it = 'kbyte';
															|pl = 'KB';
															|tr = 'Kbayt'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "257";
		Level3.Description = NStr("vi = 'Megabyte';
									|ru = 'Мегабайт';
									|en = 'Megabyte'; fa = 'مگابایت';
									|it = 'Megabyte';
									|pl = 'Megabyte';
									|tr = 'Megabayt'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'MBYTE';
											|ru = 'Мбайт';
											|en = 'MB'; fa = 'MB';
											|it = 'Мбайт';
											|pl = 'MB';
											|tr = 'Мбайт'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MBYTE';
															|ru = 'МБАЙТ';
															|en = 'MB'; fa = 'MB';
															|it = 'МБАЙТ';
															|pl = 'MB';
															|tr = 'МБАЙТ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "258";
		Level3.Description = NStr("vi = 'baud';
									|ru = 'Бод';
									|en = 'bod'; fa = 'bod';
									|it = 'Бод';
									|pl = 'bod';
									|tr = 'bd'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'baud';
											|ru = 'бод';
											|en = 'bod'; fa = 'bod';
											|it = 'бод';
											|pl = 'bod';
											|tr = 'bd'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'baud';
															|ru = 'БОД';
															|en = 'bod'; fa = 'bod';
															|it = 'БОД';
															|pl = 'bod';
															|tr = 'bd'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "287";
		Level3.Description = NStr("vi = 'Henry';
									|ru = 'Генри';
									|en = 'Henry'; fa = 'Henry';
									|it = 'Henry';
									|pl = 'Henry';
									|tr = 'Henri'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'h';
											|ru = 'ч';
											|en = 'H'; fa = 'H';
											|it = 'ч';
											|pl = 'H';
											|tr = 'saat'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'h';
															|ru = 'Ч';
															|en = 'H'; fa = 'H';
															|it = 'Ч';
															|pl = 'H';
															|tr = 'saat'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "313";
		Level3.Description = NStr("vi = 'Tesla';
									|ru = 'Тесла';
									|en = 'Tesla'; fa = 'Tesla';
									|it = 'Tesla';
									|pl = 'Tesla';
									|tr = 'Tesla'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 't';
											|ru = 'т';
											|en = 'T'; fa = 'T';
											|it = 'т';
											|pl = 'T';
											|tr = 't'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Tl';
															|ru = 'ТЛ';
															|en = 'T'; fa = 'T';
															|it = 'ТЛ';
															|pl = 'T';
															|tr = 'Tl'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "317";
		Level3.Description = NStr("vi = 'Kilogam trên centimet vuông';
									|ru = 'Килограмм на квадратный сантиметр';
									|en = 'Kilogram per square centimeter'; fa = 'Kilogram per square centimeter';
									|it = 'Kilogrammo per un centimetro quadrato';
									|pl = 'Kilogram na centymetr kwadratowy';
									|tr = 'Santimetre karede kilogram'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'kg/cm^2';
											|ru = 'кг/см^2';
											|en = 'kg/cm^2'; fa = 'kg/cm^2';
											|it = 'kg/cm2';
											|pl = 'kg/cm^2';
											|tr = 'kg/sm^2'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Kg/cm2';
															|ru = 'КГ/СМ2';
															|en = 'KG/CM2'; fa = 'KG/CM2';
															|it = 'KG/CM2';
															|pl = 'KG/CM2';
															|tr = 'KG/SM2'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "337";
		Level3.Description = NStr("vi = 'Milimet cột nước';
									|ru = 'Миллиметр водяного столба';
									|en = 'Millimeter of water'; fa = 'Millimeter of water';
									|it = 'Millimetro di colonna d''acqua';
									|pl = 'Milimetr słupa wodnego';
									|tr = 'Su sütunu milimetresi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'mm cột nước';
											|ru = 'мм вод. ст';
											|en = 'mmH2O'; fa = 'mmH2O';
											|it = 'mmca';
											|pl = 'mm sł. wod.';
											|tr = 'mm su. sütunu'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MM cột nước';
															|ru = 'ММ ВОД СТ';
															|en = 'MM H2O'; fa = 'MM H2O';
															|it = 'MMCA';
															|pl = 'MM SŁ WOD';
															|tr = 'MM SU SÜTUNU'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "338";
		Level3.Description = NStr("vi = 'Milimet thủy ngân';
									|ru = 'Миллиметр ртутного столба';
									|en = 'Millimeter of mercury'; fa = 'Millimeter of mercury';
									|it = 'Millimetro di mercurio';
									|pl = 'Milimetr słupa rtęci';
									|tr = 'Cıva sütunu milimetresi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'mm thủy ngân';
											|ru = 'мм рт. ст';
											|en = 'mmHg'; fa = 'mmHg';
											|it = 'mmHg';
											|pl = 'mm sł. rt';
											|tr = 'mm cıva. sütunu'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Mm thủy ngân';
															|ru = 'ММ РТ СТ';
															|en = 'MM Hg'; fa = 'MM Hg';
															|it = 'MMHG';
															|pl = 'MM SŁ RT';
															|tr = 'MM CIVA SÜTUNU'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "339";
		Level3.Description = NStr("vi = 'Centimet cột nước';
									|ru = 'Сантиметр водяного столба';
									|en = 'Centimeter of water'; fa = 'Centimeter of water';
									|it = 'Centimetro di colonna d''acqua';
									|pl = 'Centymetr słupa wodnego';
									|tr = 'Su sütunu santimetresi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'cm cột nước';
											|ru = 'см вод. ст';
											|en = 'cmH2O'; fa = 'cmH2O';
											|it = 'cmca';
											|pl = 'cm sł. wod';
											|tr = 'su sütunu santimetresi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Cm cột nước';
															|ru = 'СМ ВОД СТ';
															|en = 'CM H2O'; fa = 'CM H2O';
															|it = 'CMCA';
															|pl = 'CM SŁ WOD';
															|tr = 'SU SÜTUNU SANTİMETRESİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level2 = Level1.Rows.Add();
		Level2.NumericCode = "";
		Level2.Description = NStr("vi = 'Đơn vị thời gian';
									|ru = 'Единицы времени';
									|en = 'Units of time'; fa = 'Units of time';
									|it = 'Unità di tempo';
									|pl = 'Jednostki czasu';
									|tr = 'Zaman birimleri'", Common.DefaultLanguageCode());
		Level2.SymbolNational = "";
		Level2.InternationalSymbol = "";
		Level2.CodeLetterDesignationNational = "";
		Level2.CodeLetterDesignationInternational = "";
		Level2.Numerator = 0;
		Level2.Denominator = 0;
		Level2.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "352";
		Level3.Description = NStr("vi = 'Micro giây';
									|ru = 'Микросекунда';
									|en = 'Microsecond'; fa = 'Microsecond';
									|it = 'Microsecondo';
									|pl = 'Microsecond';
									|tr = 'Mikrosaniye'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'mcs';
											|ru = 'мкс';
											|en = 'μs'; fa = 'μs';
											|it = 'мкс';
											|pl = 'μs';
											|tr = 'mks'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'mcs';
															|ru = 'МКС';
															|en = 'μs'; fa = 'μs';
															|it = 'МКС';
															|pl = 'μs';
															|tr = 'mks'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 1000000;
		Level3.MeasuredValueType = "Time";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "353";
		Level3.Description = NStr("vi = 'Mili giây Ek';
									|ru = 'Миллисекунда Эк';
									|en = 'Millisecond'; fa = 'میلی‌ثانیه';
									|it = 'Millisecondo u.e.';
									|pl = 'Milisekunda Ek';
									|tr = 'Milisaniye'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'mls';
											|ru = 'млс';
											|en = 'ms'; fa = 'ms';
											|it = 'млс';
											|pl = 'ms';
											|tr = 'mls'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'mls';
															|ru = 'МЛС';
															|en = 'ms'; fa = 'ms';
															|it = 'МЛС';
															|pl = 'ms';
															|tr = 'mls'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 1;
		Level3.Denominator = 1000;
		Level3.MeasuredValueType = "Time";
		Level2 = Level1.Rows.Add();
		Level2.NumericCode = "";
		Level2.Description = NStr("vi = 'Đơn vị kinh tế';
									|ru = 'Экономические единицы';
									|en = 'Economic units'; fa = 'Economic units';
									|it = 'Unità di misura economiche';
									|pl = 'Jednostki ekonomiczne';
									|tr = 'Ekonomik birimler'", Common.DefaultLanguageCode());
		Level2.SymbolNational = "";
		Level2.InternationalSymbol = "";
		Level2.CodeLetterDesignationNational = "";
		Level2.CodeLetterDesignationInternational = "";
		Level2.Numerator = 0;
		Level2.Denominator = 0;
		Level2.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "383";
		Level3.Description = NStr("vi = 'Rúp';
									|ru = 'Рубль';
									|en = 'Ruble'; fa = 'Ruble';
									|it = 'Rublo';
									|pl = 'Ruble';
									|tr = 'Ruble'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'RUB';
											|ru = 'руб';
											|en = 'RUB'; fa = 'RUB';
											|it = 'руб';
											|pl = 'RUB';
											|tr = 'RUB'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'RUB';
															|ru = 'РУБ';
															|en = 'RUB'; fa = 'RUB';
															|it = 'РУБ';
															|pl = 'RUB';
															|tr = 'RUB'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "384";
		Level3.Description = NStr("vi = 'Nghìn rúp';
									|ru = 'Тысяча рублей';
									|en = 'Thousand rubles'; fa = 'Thousand rubles';
									|it = 'Mille rubli';
									|pl = 'Tysiąc rubli';
									|tr = 'Bin ruble'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 rúp';
											|ru = '1000 руб';
											|en = '1000 rub'; fa = '1000 rub';
											|it = '1000 rub';
											|pl = '1000 rub';
											|tr = '1000 ruble'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN RÚP';
															|ru = 'ТЫС РУБ';
															|en = 'THOUS RUB'; fa = 'THOUS RUB';
															|it = 'MILLE RUB';
															|pl = 'TYS RUB';
															|tr = 'BİN RUBLE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "385";
		Level3.Description = NStr("vi = 'Triệu rúp';
									|ru = 'Миллион рублей';
									|en = 'Million rubles'; fa = 'Million rubles';
									|it = 'Un milione di rubli';
									|pl = 'Milion rubli';
									|tr = 'Milyon ruble'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 rúp';
											|ru = '10^6 руб';
											|en = '10^6 rub'; fa = '10^6 rub';
											|it = '10^6 rub';
											|pl = '10^6 rub';
											|tr = '10^6 ruble'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu rúp';
															|ru = 'МЛН РУБ';
															|en = 'MIL RUB'; fa = 'MIL RUB';
															|it = 'MLN RUB';
															|pl = 'MLN RUB';
															|tr = 'MİLYON RUBLE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "386";
		Level3.Description = NStr("vi = 'Tỷ rúp';
									|ru = 'Миллиард рублей';
									|en = 'Billion rubles'; fa = 'Billion rubles';
									|it = 'Un miliardo di rubli';
									|pl = 'Miliard rubli';
									|tr = 'Milyar ruble'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^9 rúp';
											|ru = '10^9 руб';
											|en = '10^9 rub'; fa = '10^9 rub';
											|it = '10^9 rub';
											|pl = '10^9 rub';
											|tr = '10^9 ruble'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Tỷ rúp';
															|ru = 'МЛРД РУБ';
															|en = 'BN RUB'; fa = 'BN RUB';
															|it = 'MLD RUB';
															|pl = 'MLD RUB';
															|tr = 'MİLYAR RUBLE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "387";
		Level3.Description = NStr("vi = 'Nghìn tỷ rúp';
									|ru = 'Триллион рублей';
									|en = 'Trillion rubles'; fa = 'Trillion rubles';
									|it = 'Bilione di rubli';
									|pl = 'Trylion rubli';
									|tr = 'Trilyon ruble'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^12 rúp';
											|ru = '10^12 руб';
											|en = '10^12 rub'; fa = '10^12 rub';
											|it = '10^12 rub';
											|pl = '10^12 rub';
											|tr = '10^12 ruble'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn tỷ rúp';
															|ru = 'ТРИЛЛ РУБ';
															|en = 'TRL RUB'; fa = 'TRL RUB';
															|it = 'TRILIONE RUB';
															|pl = 'TRYL RUB';
															|tr = 'TRİLYON RUBLE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "388";
		Level3.Description = NStr("vi = 'Triệu tỷ rúp';
									|ru = 'Квадрильон рублей';
									|en = 'Quadrillion rubles'; fa = 'Quadrillion rubles';
									|it = 'Un biliardo di rubli';
									|pl = 'Kwadrilion rubli';
									|tr = 'Katrilyon ruble'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^15 rúp';
											|ru = '10^15 руб';
											|en = '10^15 rub'; fa = '10^15 rub';
											|it = '10^15 rub';
											|pl = '10^15 rub';
											|tr = '10^15 ruble'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu tỷ rúp';
															|ru = 'КВАДР РУБ';
															|en = 'QUAD RUB'; fa = 'QUAD RUB';
															|it = 'BILIARDO RUB';
															|pl = 'KWADR RUB';
															|tr = 'KATRİLYON RUBLE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "414";
		Level3.Description = NStr("vi = 'Hành khách - kilomet';
									|ru = 'Пассажиро - километр';
									|en = 'Passenger-kilometer'; fa = 'Passenger-kilometer';
									|it = 'Passeggero-kilometro';
									|pl = 'Pasażerokilometr';
									|tr = 'Yolcu - kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'hành khách. km';
											|ru = 'пасс. км';
											|en = 'pkm'; fa = 'pkm';
											|it = 'pass. km';
											|pl = 'pas-km';
											|tr = 'yolcu. km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Hành khách.km';
															|ru = 'ПАСС.КМ';
															|en = 'PKM pass'; fa = 'PKM pass';
															|it = 'PASS. KM';
															|pl = 'PKM pass';
															|tr = 'YOLCU.KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "421";
		Level3.Description = NStr("vi = 'Ghế hành khách';
									|ru = 'Пассажирское место (пассажирских мест)';
									|en = 'Passenger seat (passenger seats)'; fa = 'Passenger seat (passenger seats)';
									|it = 'Sedile passeggero (sedili passeggero)';
									|pl = 'Miejsce pasażerskie (miejsc pasażerskich)';
									|tr = 'Yolcu koltuğu (yolcu koltuklarının)'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'ghế hành khách';
											|ru = 'пасс. мест';
											|en = 'pax seats'; fa = 'pax seats';
											|it = 'sed. pass.';
											|pl = 'miejsc pas';
											|tr = 'yolcu.koltuğu'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Chỗ hành khách';
															|ru = 'ПАСС МЕСТ';
															|en = 'PAX SEAT'; fa = 'PAX SEAT';
															|it = 'SED. PASS.';
															|pl = 'MIEJSC PAS';
															|tr = 'YOLCU KOLTUĞU'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "423";
		Level3.Description = NStr("vi = 'Nghìn kilomet chở khách';
									|ru = 'Тысяча пассажиро - километров';
									|en = 'Thousand passenger-kilometers'; fa = 'Thousand passenger-kilometers';
									|it = 'Mille passeggero-kilometri';
									|pl = 'Tysiąc pasażerokilometrów';
									|tr = 'Bin yolcu - kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 km chở khách';
											|ru = '1000 пасс. км';
											|en = '1,000 pkm'; fa = '1,000 pkm';
											|it = '1000 pass. km';
											|pl = '1000 pas-km';
											|tr = '1000 yolcu. km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn km chở khách';
															|ru = 'ТЫС ПАСС.КМ';
															|en = 'THOUS PKM'; fa = 'THOUS PKM';
															|it = 'MILLE PASS. KM';
															|pl = 'TYS PAS-KM';
															|tr = 'BİN YOLCU.KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "424";
		Level3.Description = NStr("vi = 'Triệu kilomet chở khách';
									|ru = 'Миллион пассажиро - километров';
									|en = 'Million passenger-kilometers'; fa = 'Million passenger-kilometers';
									|it = 'Un milione di passeggero-kilometri';
									|pl = 'Milion pasażerokilometrów';
									|tr = 'Milyon yolcu - kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 km chở khách';
											|ru = '10^6 пасс. км';
											|en = '10^6 pkm'; fa = '10^6 pkm';
											|it = '10^6 pass. km';
											|pl = '10^6 pas-km';
											|tr = '10^6 yolcu. km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu KM chở khách';
															|ru = 'МЛН ПАСС.КМ';
															|en = 'MIL PKM'; fa = 'MIL PKM';
															|it = 'MLN PASS. KM';
															|pl = 'MLN PAS-KM';
															|tr = 'MİLYON YOLCU.KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "426";
		Level3.Description = NStr("vi = 'Cặp tàu chở hàng mỗi ngày';
									|ru = 'Пар грузовых поездов в сутки';
									|en = 'Pairs of freight trains per day'; fa = 'Pairs of freight trains per day';
									|it = 'Pairs of freight trains per day';
									|pl = 'Pairs of freight trains per day';
									|tr = 'Yük taşımanın günlük parametresi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'số đôi tàu hàng/mỗi ngày';
											|ru = 'пар груз поезд/сут';
											|en = 'pairs of freight trains/D'; fa = 'pairs of freight trains/D';
											|it = 'pairs of freight trains/D';
											|pl = 'pairs of freight trains/D';
											|tr = 'kargo gidişi/gün parametresi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Hai Tàu Chở Hàng/Mỗi Ngày';
															|ru = 'Пар Груз Поезд/Сут';
															|en = 'Pairs of Freight Trains/D'; fa = 'Pairs of Freight Trains/D';
															|it = 'Pairs of Freight Trains/D';
															|pl = 'Pairs of Freight Trains/D';
															|tr = 'Kargo Gidişi/Gün Parametresi'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "427";
		Level3.Description = NStr("vi = 'Lưu lượng hành khách';
									|ru = 'Пассажиропоток';
									|en = 'Passengers per hour per direction'; fa = 'Passengers per hour per direction';
									|it = 'Traffico passeggeri';
									|pl = 'Passengers per hour per direction';
									|tr = 'Yolcu akışı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'lưu lượng hành khách';
											|ru = 'пасс. поток';
											|en = 'pphpd'; fa = 'pphpd';
											|it = 'пасс. поток';
											|pl = 'pphpd';
											|tr = 'g/KVt.s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'lưu lượng hành khách';
															|ru = 'ПАСС. ПОТОК';
															|en = 'pphpd'; fa = 'pphpd';
															|it = 'ПАСС. ПОТОК';
															|pl = 'potok pasażerów';
															|tr = 'g/KVt.s'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "428";
		Level3.Description = NStr("vi = 'Mét khối-kilomet';
									|ru = 'Кубический метр - километр';
									|en = 'Cubic meter - kilometer'; fa = 'Cubic meter - kilometer';
									|it = 'Cubic meter - kilometer';
									|pl = 'Cubic meter - kilometer';
									|tr = 'Kübik metre - kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'm3.km';
											|ru = 'м3. км';
											|en = 'm3 KM'; fa = 'm3 KM';
											|it = 'm3 KM';
											|pl = 'm3 KM';
											|tr = 'm3 km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M3.KM';
															|ru = 'М3.КМ';
															|en = 'M3 KM'; fa = 'M3 KM';
															|it = 'M3 KM';
															|pl = 'M3 KM';
															|tr = 'M3 KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "430";
		Level3.Description = NStr("vi = 'Triệu mét khối - kilomet';
									|ru = 'Миллион кубических метров - километров';
									|en = 'Million cubic meters - kilometers'; fa = 'Million cubic meters - kilometers';
									|it = 'Million cubic meters - kilometers';
									|pl = 'Million cubic meters - kilometers';
									|tr = 'Milyon kübik metre - kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 m3. km';
											|ru = '10^6 м3. км';
											|en = '10^6 m3 km'; fa = '10^6 m3 km';
											|it = '10^6 m3 km';
											|pl = '10^6 m3 km';
											|tr = '10^6 m 3 km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU M3.KM';
															|ru = 'МЛН М3.КМ';
															|en = 'MIL M3 KM'; fa = 'MIL M3 KM';
															|it = 'MIL M3 KM';
															|pl = 'MIL M3 KM';
															|tr = 'MLN M3 KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "431";
		Level3.Description = NStr("vi = 'Cất cánh và hạ cánh mỗi giờ';
									|ru = 'Взлетов - посадок в час';
									|en = 'Take-offs and landings per hour'; fa = 'Take-offs and landings per hour';
									|it = 'Take-offs and landings per hour';
									|pl = 'Take-offs and landings per hour';
									|tr = 'Saatte kalkış/iniş sayısı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Cất cánh và hạ cánh mỗi giờ';
											|ru = 'взлет. посадок/час';
											|en = 'take-offs and landings/h'; fa = 'take-offs and landings/h';
											|it = 'take-offs and landings/h';
											|pl = 'take-offs and landings/h';
											|tr = 'saatte kalkış/iniş sayısı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'CẤT CÁNH VÀ HẠ CÁNH MỖI GIỜ';
															|ru = 'ВЗЛЕТ. ПОСАДОК/ЧАС';
															|en = 'TAKE-OFFS AND LANDINGS/H'; fa = 'TAKE-OFFS AND LANDINGS/H';
															|it = 'TAKE-OFFS AND LANDINGS/H';
															|pl = 'TAKE-OFFS AND LANDINGS/H';
															|tr = 'SAATTE KALKIŞ/İNİŞ SAYISI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "435";
		Level3.Description = NStr("vi = 'Triệu kilomet';
									|ru = 'Миллион километров';
									|en = 'Million kilometers'; fa = 'Million kilometers';
									|it = 'Million kilometers';
									|pl = 'Million kilometers';
									|tr = 'Milyon kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 km';
											|ru = '10^6 км';
											|en = '10^6 km'; fa = '10^6 km';
											|it = '10^6 km';
											|pl = '10^6 km';
											|tr = '10^6 km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU KM';
															|ru = 'МЛН КМ';
															|en = 'MIL KM'; fa = 'MIL KM';
															|it = 'MIL KM';
															|pl = 'MIL KM';
															|tr = 'MLN KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "449";
		Level3.Description = NStr("vi = 'Tấn - kilomet';
									|ru = 'Тонно - километр';
									|en = 'Ton-kilometer'; fa = 'Ton-kilometer';
									|it = 'Tonnellata-kilometro';
									|pl = 'Tonokilometr';
									|tr = 'Ton - kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 't. km';
											|ru = 'т. км';
											|en = 'tkm'; fa = 'tkm';
											|it = 't km';
											|pl = 't-km';
											|tr = 't. km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'T.KM';
															|ru = 'Т.КМ';
															|en = 'TKM S'; fa = 'TKM S';
															|it = 'T KM';
															|pl = 'TKM S';
															|tr = 'T.KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "450";
		Level3.Description = NStr("vi = 'Nghìn tấn - kilomet';
									|ru = 'Тысяча тонно - километров';
									|en = 'Thousand ton-kilometers'; fa = 'Thousand ton-kilometers';
									|it = 'Mille tonnellata-kilometri';
									|pl = 'Tysiąc tonokilometrów';
									|tr = 'Bin ton - kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 t. km';
											|ru = '1000 т. км';
											|en = '1,000 tkm'; fa = '1,000 tkm';
											|it = '1000 t km';
											|pl = '1000 t-km';
											|tr = '1000 t. km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN T.KM';
															|ru = 'ТЫС Т.КМ';
															|en = 'THOUS TKM'; fa = 'THOUS TKM';
															|it = 'MILLE T KM';
															|pl = 'TYS T-KM';
															|tr = 'BİN T.KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "451";
		Level3.Description = NStr("vi = 'Triệu tấn - kilomet';
									|ru = 'Миллион тонно - километров';
									|en = 'Million ton-kilometers'; fa = 'Million ton-kilometers';
									|it = 'Un milione di tonnellata-kilometri';
									|pl = 'Milion tono-kilometrów';
									|tr = 'Milyon ton - kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 t. km';
											|ru = '10^6 т. км';
											|en = '10^6 tkm'; fa = '10^6 tkm';
											|it = '10^6 t km';
											|pl = '10^6 t-km';
											|tr = '10^6 t. km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu t.km';
															|ru = 'МЛН Т.КМ';
															|en = 'MIL TKM'; fa = 'MIL TKM';
															|it = 'MLN T KM';
															|pl = 'MLN T-KM';
															|tr = 'MİLYON T.KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "452";
		Level3.Description = NStr("vi = 'Tỷ tấn - kilomet';
									|ru = 'Миллиард тонно - километр';
									|en = 'Billion ton - kilometer'; fa = 'Billion ton - kilometer';
									|it = 'Billion ton - kilometer';
									|pl = 'Billion ton - kilometer';
									|tr = 'Milyar ton - kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^9 tấn km';
											|ru = '10^9 т. км';
											|en = '10^9 tkm'; fa = '10^9 tkm';
											|it = '10^9 tkm';
											|pl = '10^9 tkm';
											|tr = '10^9 t. km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TỶ T.KM';
															|ru = 'МЛРД Т.КМ';
															|en = 'BN TKM'; fa = 'BN TKM';
															|it = 'BN TKM';
															|pl = 'BN TKM';
															|tr = 'MLYR T. KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "479";
		Level3.Description = NStr("vi = 'Nghìn bộ';
									|ru = 'Тысяча наборов';
									|en = 'Thousand sets'; fa = 'Thousand sets';
									|it = 'Mille set';
									|pl = 'Tysiąc zestawów';
									|tr = 'Bin tane küme'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 bộ';
											|ru = '10^3 набор';
											|en = '10^3 sets'; fa = '10^3 sets';
											|it = '10^3 set';
											|pl = '10^3 zestaw';
											|tr = '10^3 küme'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN BỘ';
															|ru = 'ТЫС НАБОР';
															|en = 'THOUS SETS'; fa = 'THOUS SETS';
															|it = 'MILLE SET';
															|pl = 'TYS ZESTAW';
															|tr = 'BİN TANE KÜME'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "508";
		Level3.Description = NStr("vi = 'Một nghìn mét khối một giờ';
									|ru = 'Тысяча метров кубических в час';
									|en = 'Thousand cubic meters per hour'; fa = 'Thousand cubic meters per hour';
									|it = 'Thousand cubic meters per hour';
									|pl = 'Thousand cubic meters per hour';
									|tr = 'Saatte bin kübik metre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 m3/g';
											|ru = '10^3 м3/ч';
											|en = '10^3 m3/h'; fa = '10^3 m3/h';
											|it = '10^3 m3/h';
											|pl = '10^3 m3/h';
											|tr = '10^3 m3/s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN M3/NGÀY';
															|ru = 'ТЫС М3/Ч';
															|en = 'THOUS M3/H'; fa = 'THOUS M3/H';
															|it = 'THOUS M3/H';
															|pl = 'THOUS M3/H';
															|tr = 'BİN M3/S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "509";
		Level3.Description = NStr("vi = 'Kilomet trong ngày';
									|ru = 'Километр в сутки';
									|en = 'Kilometer per day'; fa = 'Kilometer per day';
									|it = 'Kilometer per day';
									|pl = 'Kilometer per day';
									|tr = 'Günlük kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'km/ngày';
											|ru = 'км/сут';
											|en = 'km/d'; fa = 'km/d';
											|it = 'km/d';
											|pl = 'km/d';
											|tr = 'km/gün'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KM/NGÀY';
															|ru = 'КМ/СУТ';
															|en = 'KM/D'; fa = 'KM/D';
															|it = 'KM/D';
															|pl = 'KM/D';
															|tr = 'KM/GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "510";
		Level3.Description = NStr("vi = 'Gram trên kilowatt - giờ';
									|ru = 'Грамм на киловатт - час';
									|en = 'Gram per kilowatt-hour'; fa = 'Gram per kilowatt-hour';
									|it = 'Grammi per kilowattora';
									|pl = 'Gram na kilowatogodzinę';
									|tr = 'Kilowatt - saatde gram'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'g/kW.h';
											|ru = 'г/кВт.ч';
											|en = 'g/kWh'; fa = 'g/kWh';
											|it = 'г/кВт.ч';
											|pl = 'g/kWh';
											|tr = 'g/KVt.s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'g/kW.h';
															|ru = 'Г/КВТ.Ч';
															|en = 'g/kWh'; fa = 'g/kWh';
															|it = 'Г/КВТ.Ч';
															|pl = 'g/kWh';
															|tr = 'g/KVt.s'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "511";
		Level3.Description = NStr("vi = 'Kilogam trên Gigacalorie';
									|ru = 'Килограмм на гигакалорию';
									|en = 'Kilogram per gigacalorie'; fa = 'Kilogram per gigacalorie';
									|it = 'Kilogrammo per gigacaloria';
									|pl = 'Kilogram na gigakalorie';
									|tr = 'Gigakalori başına kilogram'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'kg/Gkal';
											|ru = 'кг/Гкал';
											|en = 'kg/Gcal'; fa = 'kg/Gcal';
											|it = 'kg/Gcal';
											|pl = 'kg/Gcal';
											|tr = 'kg/kg/Gkal'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'KG/GIGAKAL';
															|ru = 'КГ/ГИГАКАЛ';
															|en = 'KG/GIGACAL'; fa = 'KG/GIGACAL';
															|it = 'KG/GCAL';
															|pl = 'KG/GIGACAL';
															|tr = 'KG/GİGAKAL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "512";
		Level3.Description = NStr("vi = 'Tấn - số';
									|ru = 'Тонно - номер';
									|en = 'Ton-number'; fa = 'Ton-number';
									|it = 'Tonnellata-numero';
									|pl = 'Tono-numer';
									|tr = 'Ton - numara'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 't. chuẩn';
											|ru = 'т. ном';
											|en = 't num'; fa = 't num';
											|it = 't num.';
											|pl = 't. num';
											|tr = 't. numara'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'T.CHUẨN';
															|ru = 'Т.НОМ';
															|en = 'T NUM S'; fa = 'T NUM S';
															|it = 'T NUM.';
															|pl = 'T NUM S';
															|tr = 'T,NUMARA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "513";
		Level3.Description = NStr("vi = 'Tấn tự động';
									|ru = 'Автотонна';
									|en = 'Auto ton'; fa = 'Auto ton';
									|it = 'Tonnellata veicolo';
									|pl = 'Auto ton';
									|tr = 'Oto ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'T tự động';
											|ru = 'авто т';
											|en = 'AUTO T'; fa = 'AUTO T';
											|it = 'авто т';
											|pl = 'Tona sam';
											|tr = 'OTO T'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'T tự động';
															|ru = 'АВТО Т';
															|en = 'AUTO T'; fa = 'AUTO T';
															|it = 'АВТО Т';
															|pl = 'AUTO T';
															|tr = 'OTO T'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "514";
		Level3.Description = NStr("vi = 'Tấn lực đẩy';
									|ru = 'Тонна тяги';
									|en = 'Ton of thrust'; fa = 'Ton of thrust';
									|it = 'Tonnellata di trazione';
									|pl = 'Tona ciągu';
									|tr = 'İtme tonu'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 't lực đẩy';
											|ru = 'т.тяги';
											|en = 't thrust'; fa = 't thrust';
											|it = 't di trazione';
											|pl = 't thrust';
											|tr = 'itme.tonu'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'T LỰC ĐẨY';
															|ru = 'Т ТЯГИ';
															|en = 'T THRUST S'; fa = 'T THRUST S';
															|it = 'T DI TRAZIONE';
															|pl = 'T CIĄGU';
															|tr = 'İTME TONU'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "515";
		Level3.Description = NStr("vi = 'Tấn trọng lượng';
									|ru = 'Дедвейт-тонна';
									|en = 'Deadweight tonnage'; fa = 'Deadweight tonnage';
									|it = 'Tonnellaggio di portata lorda';
									|pl = 'Deadweight tonnage';
									|tr = 'Ölü ağırlık - ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 't trọng lượng';
											|ru = 'дедвейт.т';
											|en = 'dwt'; fa = 'dwt';
											|it = 'дедвейт.т';
											|pl = 'dwt';
											|tr = 'detveyt t'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 't trọng lượng';
															|ru = 'ДЕДВЕЙТ.Т';
															|en = 'dwt'; fa = 'dwt';
															|it = 'ДЕДВЕЙТ.Т';
															|pl = 'dwt';
															|tr = 'detveyt t'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "516";
		Level3.Description = NStr("vi = 'Tấn-tannid';
									|ru = 'Тонно-танид';
									|en = 'Ton-tannin'; fa = 'Ton-tannin';
									|it = 'Tonnellata-tanid';
									|pl = 'Ton-tannin';
									|tr = 'Ton-tanin'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 't-tannid';
											|ru = 'т.танид';
											|en = 't tannin'; fa = 't tannin';
											|it = 't-tanid';
											|pl = 't tannin';
											|tr = 't.tanin'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 't-tannid';
															|ru = 'т.танид';
															|en = 't tannin'; fa = 't tannin';
															|it = 't-tanid';
															|pl = 't tannin';
															|tr = 't.tanin'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "518";
		Level3.Description = NStr("vi = 'Mét vuông trên một người';
									|ru = 'Квадратных метров на человека';
									|en = 'Square meters per person'; fa = 'Square meters per person';
									|it = 'Square meters per person';
									|pl = 'Square meters per person';
									|tr = 'Kişi başı metrekare'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'm2/người';
											|ru = 'м2/чел';
											|en = 'm2/person'; fa = 'm2/person';
											|it = 'm2/person';
											|pl = 'm2/person';
											|tr = 'm2/kişi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'M2/NGƯỜI';
															|ru = 'М2/ЧЕЛ';
															|en = 'M2/PERSON'; fa = 'M2/PERSON';
															|it = 'M2/PERSON';
															|pl = 'M2/PERSON';
															|tr = 'M2/KİŞİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "521";
		Level3.Description = NStr("vi = 'Người trên mét vuông';
									|ru = 'Человек на квадратный метр';
									|en = 'People per square meter'; fa = 'People per square meter';
									|it = 'Persone per metro quadrato';
									|pl = 'Człowiek na metr kwadratowy';
									|tr = 'Metrekare başına kişi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'người/m2';
											|ru = 'чел/м2';
											|en = 'people/m2'; fa = 'people/m2';
											|it = 'pers/m2';
											|pl = 'people/m2';
											|tr = 'kişi/m2'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'người/m2';
															|ru = 'ЧЕЛ/М2';
															|en = 'people/m2'; fa = 'people/m2';
															|it = 'pers/m2';
															|pl = 'people/m2';
															|tr = 'kişi/m2'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "522";
		Level3.Description = NStr("vi = 'Người trên kilomet vuông';
									|ru = 'Человек на квадратный километр';
									|en = 'People per square kilometer'; fa = 'People per square kilometer';
									|it = 'Persone per kilometro quadrato';
									|pl = 'Człowiek na kilometr kwadratowy';
									|tr = 'Kilometre kare başına kişi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'NGƯỜI/KM2';
											|ru = 'чел/км2';
											|en = 'PEOPLE/KM2'; fa = 'PEOPLE/KM2';
											|it = 'чел/км2';
											|pl = 'PEOPLE/KM2';
											|tr = 'KİŞİ/KM2'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGƯỜI/KM2';
															|ru = 'ЧЕЛ/КМ2';
															|en = 'PEOPLE/KM2'; fa = 'PEOPLE/KM2';
															|it = 'ЧЕЛ/КМ2';
															|pl = 'PEOPLE/KM2';
															|tr = 'KİŞİ/KM2'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "534";
		Level3.Description = NStr("vi = 'Tấn trên giờ';
									|ru = 'Тонна в час';
									|en = 'Ton per hour'; fa = 'Ton per hour';
									|it = 'Tonnellate all''ora';
									|pl = 'Tona na godzinę';
									|tr = 'Saatte ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'T/H';
											|ru = 'т/ч';
											|en = 'T/H'; fa = 'T/H';
											|it = 'т/ч';
											|pl = 'T/H';
											|tr = 'T/S'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'T/H';
															|ru = 'Т/Ч';
															|en = 'T/H'; fa = 'T/H';
															|it = 'Т/Ч';
															|pl = 'T/H';
															|tr = 'T/S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "535";
		Level3.Description = NStr("vi = 'Tấn trong ngày';
									|ru = 'Тонна в сутки';
									|en = 'Ton per day'; fa = 'Ton per day';
									|it = 'Tonnellate al giorno';
									|pl = 'Tona na dobę';
									|tr = 'Günlük ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'T/NGÀY';
											|ru = 'т/сут';
											|en = 'T/DAY'; fa = 'T/DAY';
											|it = 'т/сут';
											|pl = 'T/DAY';
											|tr = 'T/GÜNLÜK'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'T/NGÀY';
															|ru = 'Т/СУТ';
															|en = 'T/DAY'; fa = 'T/DAY';
															|it = 'Т/СУТ';
															|pl = 'T/DAY';
															|tr = 'T/GÜNLÜK'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "536";
		Level3.Description = NStr("vi = 'Tấn trong ca';
									|ru = 'Тонна в смену';
									|en = 'Ton per shift'; fa = 'Ton per shift';
									|it = 'Tonnellate per turno';
									|pl = 'Tona na zmianę';
									|tr = 'Vardiya başına ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'T/CA';
											|ru = 'т/смен';
											|en = 'T/SHIFT'; fa = 'T/SHIFT';
											|it = 'т/смен';
											|pl = 'T/SHIFT';
											|tr = 'T/GÜNLÜK'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'T/CA';
															|ru = 'Т/СМЕН';
															|en = 'T/SHIFT'; fa = 'T/SHIFT';
															|it = 'Т/СМЕН';
															|pl = 'T/SHIFT';
															|tr = 'T/GÜNLÜK'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "537";
		Level3.Description = NStr("vi = 'Nghìn tấn trong mùa';
									|ru = 'Тысяча тонн в сезон';
									|en = 'Thousand tons per season'; fa = 'Thousand tons per season';
									|it = 'Mille tonnellate per stagione';
									|pl = 'Tysiąc ton na sezon';
									|tr = 'Mevsim başına bin ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 t/mùa';
											|ru = '1000 т/сез';
											|en = '1,000 t/season'; fa = '1,000 t/season';
											|it = '1000 t/stag.';
											|pl = '1000 t/sez';
											|tr = '1000 t/mevsim'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 t/mùa';
															|ru = 'ТЫС Т/СЕЗ';
															|en = 'THOUS T/SEASON'; fa = 'THOUS T/SEASON';
															|it = 'MILLE T/STAG.';
															|pl = 'TYS T/SEZ';
															|tr = 'BİN T/MEVSİM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "538";
		Level3.Description = NStr("vi = 'Nghìn tấn trong năm';
									|ru = 'Тысяча тонн в год';
									|en = 'Thousand tons per year'; fa = 'Thousand tons per year';
									|it = 'Mille tonnellate all''anno';
									|pl = 'Tysiąc ton rocznie';
									|tr = 'Yıllık bin ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 t/năm';
											|ru = '1000 т/год';
											|en = '1,000 t/year'; fa = '1,000 t/year';
											|it = '1000 t/anno';
											|pl = '1000 t/rok';
											|tr = '1000 t/yıl'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = '1000 t/năm';
															|ru = 'ТЫС Т/ГОД';
															|en = 'THOUS T/YEAR'; fa = 'THOUS T/YEAR';
															|it = 'MILLE T/ANNO';
															|pl = 'TYS T/ROK';
															|tr = 'BİN T/YIL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "539";
		Level3.Description = NStr("vi = 'Giờ công';
									|ru = 'Человеко - час';
									|en = 'Man-hour'; fa = 'نفر-ساعت';
									|it = 'Ore-uomo';
									|pl = 'Osobogodzina';
									|tr = 'Kişi - saat'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'giờ công';
											|ru = 'чел. ч';
											|en = 'mhrs'; fa = 'mhrs';
											|it = 'ore-uomo';
											|pl = 'os/h';
											|tr = 'kişi. s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'GIỜ CÔNG';
															|ru = 'ЧЕЛ.Ч';
															|en = 'MHR S'; fa = 'MHR S';
															|it = 'ORE-UOMO';
															|pl = 'MHR S';
															|tr = 'KİŞİ.S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "540";
		Level3.Description = NStr("vi = 'Ngày công';
									|ru = 'Человеко - день';
									|en = 'Man-day'; fa = 'Man-day';
									|it = 'Giorni-uomo';
									|pl = 'Osobodzień';
									|tr = 'Kişi - gün'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'ngày công';
											|ru = 'чел. дн';
											|en = 'm/d'; fa = 'm/d';
											|it = 'giorni-uomo';
											|pl = 'os/dz';
											|tr = 'kişi. gün'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Ngày công';
															|ru = 'ЧЕЛ.ДН';
															|en = 'M/D S'; fa = 'M/D S';
															|it = 'GIORNI-UOMO';
															|pl = 'M/D S';
															|tr = 'KİŞİ.GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "541";
		Level3.Description = NStr("vi = 'Nghìn ngày công';
									|ru = 'Тысяча человеко - дней';
									|en = 'Thousand man-days'; fa = 'Thousand man-days';
									|it = 'Mille giorni-uomo';
									|pl = 'Tysiąc osobogodzin';
									|tr = 'Bin kişi - gün'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 ngày công';
											|ru = '1000 чел. дн';
											|en = '1,000 m/d'; fa = '1,000 m/d';
											|it = '1000 giorni-uomo';
											|pl = '1000 osobogodzin';
											|tr = '1000 kişi. gün'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn ngày công';
															|ru = 'ТЫС ЧЕЛ.ДН';
															|en = 'THOUS M/D'; fa = 'THOUS M/D';
															|it = 'MILLE GIORNI-UOMO';
															|pl = 'TYS OSOBODNI';
															|tr = 'BİN KİŞİ.GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "542";
		Level3.Description = NStr("vi = 'Nghìn giờ công';
									|ru = 'Тысяча человеко - часов';
									|en = 'Thousand man-hours'; fa = 'Thousand man-hours';
									|it = 'Mille giorni-uomo';
									|pl = 'Tysiąc osobogodzin';
									|tr = 'Bin kişi - saat'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 giờ công';
											|ru = '1000 чел. ч';
											|en = '1,000 mhrs'; fa = '1,000 mhrs';
											|it = '1000 giorni-uomo';
											|pl = '1000 os/h';
											|tr = '1000 kişi. s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN GIỜ CÔNG';
															|ru = 'ТЫС ЧЕЛ.Ч';
															|en = 'THOUS MHRS'; fa = 'THOUS MHRS';
															|it = 'MILLE GIORNI-UOMO';
															|pl = 'TYS OS/H';
															|tr = 'BİN KİŞİ.S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "543";
		Level3.Description = NStr("vi = 'Nghìn lon quy ước trong ca';
									|ru = 'Тысяча условных банок в смену';
									|en = 'Thousand conventional cans per shift'; fa = 'Thousand conventional cans per shift';
									|it = 'Mille barattoli convenzionali per turno';
									|pl = 'Tysiąc słoików umownych na zmianę';
									|tr = 'Vardiya başına bin koşullu kavanoz'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 lon quy ước/ca';
											|ru = '1000 усл. банк/смен';
											|en = '1,000 convl. cans/shift'; fa = '1,000 convl. cans/shift';
											|it = '1000 barattoli/turno convenzionali';
											|pl = '1000 war. słoików/zm';
											|tr = '1000 koşullu kavanoz/vardiya'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn lon quy ước/ca';
															|ru = 'ТЫС УСЛ БАНК/СМЕН';
															|en = 'THOUS CONVL CANS/SHIFT'; fa = 'THOUS CONVL CANS/SHIFT';
															|it = 'MILLE BARATTOLI/TURNO CONVENZIONALI';
															|pl = 'TYS UMOWNYCH SŁOIK/ZMIANA';
															|tr = 'BİN KOŞULLU KAVANOZ/VARDİYA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "544";
		Level3.Description = NStr("vi = 'Triệu đơn vị trong năm';
									|ru = 'Миллион единиц в год';
									|en = 'Million units per year'; fa = 'Million units per year';
									|it = 'Un milione di unità all''anno';
									|pl = 'Milion jednostek rocznie';
									|tr = 'Yıllık milyon birim'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 đv/năm';
											|ru = '10^6 ед/год';
											|en = '10^6 units/year'; fa = '10^6 units/year';
											|it = '10^6 un/anno';
											|pl = '10^6 j./rocznie';
											|tr = '10^6 birim/yıllık'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu đv/năm';
															|ru = 'МЛН ЕД/ГОД';
															|en = 'MIL UNITS/YEAR'; fa = 'MIL UNITS/YEAR';
															|it = 'MLN UN/ANNO';
															|pl = 'MLN J./ROCZNIE';
															|tr = 'MİLYON BİRİM/YILLIK'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "545";
		Level3.Description = NStr("vi = 'Lần ghé thăm trong ca';
									|ru = 'Посещение в смену';
									|en = 'Visit per shift'; fa = 'Visit per shift';
									|it = 'Visite per turno';
									|pl = 'Wizyta na zmianę';
									|tr = 'Vardiya başına ziyaret'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Lần ghé thăm/ca';
											|ru = 'посещ/смен';
											|en = 'VISITS/SHIFT'; fa = 'VISITS/SHIFT';
											|it = 'посещ/смен';
											|pl = 'VISITS/SHIFT';
											|tr = 'ZİYARET/VARDİYA'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Lần ghé thăm/ca';
															|ru = 'ПОСЕЩ/СМЕН';
															|en = 'VISITS/SHIFT'; fa = 'VISITS/SHIFT';
															|it = 'ПОСЕЩ/СМЕН';
															|pl = 'VISITS/SHIFT';
															|tr = 'ZİYARET/VARDİYA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "546";
		Level3.Description = NStr("vi = 'Nghìn lần ghé thăm trong ca';
									|ru = 'Тысяча посещений в смену';
									|en = 'Thousand visits per shift'; fa = 'Thousand visits per shift';
									|it = 'Mille visite per turno';
									|pl = 'Tysiąc wizyt na zmianę';
									|tr = 'Binlerce vardiya başına ziyaret'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 lần ghé thăm/ca';
											|ru = '1000 посещ/смен';
											|en = '1,000 visits/shift'; fa = '1,000 visits/shift';
											|it = '1000 visite/turno';
											|pl = '1000 wiz./zmian';
											|tr = '1000 ziyaret/vardiya'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn lần ghé thăm/ca';
															|ru = 'ТЫС ПОСЕЩ/СМЕН';
															|en = 'THOUS VISITS/SHIFT'; fa = 'THOUS VISITS/SHIFT';
															|it = 'MILLE VISITE/TURNO';
															|pl = 'TYS WIZ./ZMIAN';
															|tr = 'BİN ZİYARET/VARDİYA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "547";
		Level3.Description = NStr("vi = 'Đôi trong ca';
									|ru = 'Пара в смену';
									|en = 'Pair per shift'; fa = 'Pair per shift';
									|it = 'Paia per turno';
									|pl = 'Para na zmianę';
									|tr = 'Vardiya başına çift'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'đôi/ca';
											|ru = 'пар/смен';
											|en = 'pairs/shift'; fa = 'pairs/shift';
											|it = 'пар/смен';
											|pl = 'pairs/shift';
											|tr = 'çift/günlük'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'đôi/ca';
															|ru = 'ПАР/СМЕН';
															|en = 'pairs/shift'; fa = 'pairs/shift';
															|it = 'ПАР/СМЕН';
															|pl = 'pairs/shift';
															|tr = 'çift/günlük'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "548";
		Level3.Description = NStr("vi = 'Nghìn đôi trong ca';
									|ru = 'Тысяча пар в смену';
									|en = 'Thousand pairs per shift'; fa = 'Thousand pairs per shift';
									|it = 'Mille paia per turno';
									|pl = 'Tysiąc par na zmianę';
									|tr = 'Vardiya başına bin çift'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 đôi/ca';
											|ru = '1000 пар/смен';
											|en = '1,000 pairs/shift'; fa = '1,000 pairs/shift';
											|it = '1000 paia/turno';
											|pl = '1000 par/zm';
											|tr = '1000 çift/vardiya'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn đôi/ca';
															|ru = 'ТЫС ПАР/СМЕН';
															|en = 'THOUS PAIRS/SHIFT'; fa = 'THOUS PAIRS/SHIFT';
															|it = 'MILLE PAIA/TURNO';
															|pl = 'TYS PAR/ZM';
															|tr = 'BİN ÇİFT/VARDİYA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "550";
		Level3.Description = NStr("vi = 'Triệu tấn trong năm';
									|ru = 'Миллион тонн в год';
									|en = 'Million tons per year'; fa = 'Million tons per year';
									|it = 'Un milione di tonnellate all''anno';
									|pl = 'Milion ton rocznie';
									|tr = 'Yıllık milyon ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 t/năm';
											|ru = '10^6 т/год';
											|en = '10^6 t/year'; fa = '10^6 t/year';
											|it = '10^6 t/anno';
											|pl = '10^6 t/rok';
											|tr = '10^6 t/yıllık'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU T/NĂM';
															|ru = 'МЛН Т/ГОД';
															|en = 'MIL T/YEAR'; fa = 'MIL T/YEAR';
															|it = 'MLN T/ANNO';
															|pl = 'MLN T/ROK';
															|tr = 'MİLYON T/YIL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "552";
		Level3.Description = NStr("vi = 'Tấn xử lý trong ngày';
									|ru = 'Тонна переработки в сутки';
									|en = 'Ton of processing per day'; fa = 'Ton of processing per day';
									|it = 'Tonnellata di riciclaggio al giorno';
									|pl = 'Tona przetwarzania na dobę';
									|tr = 'Günlük işlenen ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'T CHẾ BIẾN/NGÀY';
											|ru = 'т перераб/сут';
											|en = 'T PROCESSING/DAY'; fa = 'T PROCESSING/DAY';
											|it = 't di riciclaggio/g';
											|pl = 'T PROCESSING/DAY';
											|tr = 'T İŞLENEN/GÜNLÜK'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'T CHẾ BIẾN/NGÀY';
															|ru = 'Т ПЕРЕРАБ/СУТ';
															|en = 'T PROCESSING/DAY'; fa = 'T PROCESSING/DAY';
															|it = 't di riciclaggio/g';
															|pl = 't przetwarz/doba';
															|tr = 'T İŞLENEN/GÜNLÜK'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "553";
		Level3.Description = NStr("vi = 'Nghìn tấn chế biến trong ngày';
									|ru = 'Тысяча тонн переработки в сутки';
									|en = 'Thousand tons of processing per day'; fa = 'Thousand tons of processing per day';
									|it = 'Mille tonnellate di riciclaggio al giorno';
									|pl = 'Tysiąc ton przetworzenia na dobę';
									|tr = 'Günlük işlenen bin ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 t chế biến/ngày';
											|ru = '1000 т перераб/сут';
											|en = '1,000 t processing/day'; fa = '1,000 t processing/day';
											|it = '1000 t di riciclaggio/g';
											|pl = '1000 t przetw/doba';
											|tr = '1000 t işlenen/gün'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN T CHẾ BIẾN/NGÀY';
															|ru = 'ТЫС Т ПЕРЕРАБ/СУТ';
															|en = 'THOUS T PROCESSING/DAY'; fa = 'THOUS T PROCESSING/DAY';
															|it = 'MILLE T RICICLAGGIO/G';
															|pl = 'TYS T PRZETW/DOBA';
															|tr = 'BİN T İŞLENEN/GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "554";
		Level3.Description = NStr("vi = 'Centner xử lý trong ngày';
									|ru = 'Центнер переработки в сутки';
									|en = 'Centner of processing per day'; fa = 'Centner of processing per day';
									|it = 'Quintale di riciclaggio al giorno';
									|pl = 'Kwintal przetwarzania na dobę';
									|tr = 'Günlük işlenen sentner'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'C chế biến/ngày';
											|ru = 'ц перераб/сут';
											|en = 'C PROCESSING/DAY'; fa = 'C PROCESSING/DAY';
											|it = 'ц перераб/сут';
											|pl = 'kw przetw/doba';
											|tr = 'S İŞLENEN/GÜNLÜK'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'C chế biến/ngày';
															|ru = 'Ц ПЕРЕРАБ/СУТ';
															|en = 'C PROCESSING/DAY'; fa = 'C PROCESSING/DAY';
															|it = 'Ц ПЕРЕРАБ/СУТ';
															|pl = 'C PROCESSING/DAY';
															|tr = 'S İŞLENEN/GÜNLÜK'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "555";
		Level3.Description = NStr("vi = 'Nghìn Centner chế biến trong ngày';
									|ru = 'Тысяча центнеров переработки в сутки';
									|en = 'Thousand centners of processing per day'; fa = 'Thousand centners of processing per day';
									|it = 'Mille quintali di riciclaggio al giorno';
									|pl = 'Tysiąc kwintali przetwarzania na dobę';
									|tr = 'Günlük işlenen bin sentner'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 c chế biến/ngày';
											|ru = '1000 ц перераб/сут';
											|en = '1,000 c processing/day'; fa = '1,000 c processing/day';
											|it = '1000 q di riciclaggio/g';
											|pl = '1000 kw przetw/doba';
											|tr = '1000 s işlenen/gün'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn c chế biến/ngày';
															|ru = 'ТЫС Ц ПЕРЕРАБ/СУТ';
															|en = 'THOUS C PROCESSING/DAY'; fa = 'THOUS C PROCESSING/DAY';
															|it = 'MILLE Q RICICLAGGIO/G';
															|pl = 'TYS KW PRZETW/DOBA';
															|tr = 'BİN S İŞLENEN/GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "556";
		Level3.Description = NStr("vi = 'Nghìn đầu trong năm';
									|ru = 'Тысяча голов в год';
									|en = 'Thousand heads per year'; fa = 'Thousand heads per year';
									|it = 'Mille capi all''anno';
									|pl = 'Tysiąc głów rocznie';
									|tr = 'Yıllık binlerce baş'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 đầu/năm';
											|ru = '1000 гол/год';
											|en = '1,000 heads/year'; fa = '1,000 heads/year';
											|it = '1000 capi/anno';
											|pl = '1000 głów/rok';
											|tr = '1000 baş/yıl'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn đầu/năm';
															|ru = 'ТЫС ГОЛ/ГОД';
															|en = 'THOUS HEADS/YEAR'; fa = 'THOUS HEADS/YEAR';
															|it = 'MILLE CAPI/ANNO';
															|pl = 'TYS GŁ/ROK';
															|tr = 'BİN BAŞ/YIL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "557";
		Level3.Description = NStr("vi = 'Triệu đầu trong năm';
									|ru = 'Миллион голов в год';
									|en = 'Million heads per year'; fa = 'Million heads per year';
									|it = 'Un milione di capi all''anno';
									|pl = 'Milion głów rocznie';
									|tr = 'Yıllık milyon baş'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 đầu/năm';
											|ru = '10^6 гол/год';
											|en = '10^6 heads/year'; fa = '10^6 heads/year';
											|it = '10^6 capi/anno';
											|pl = '10^6 głów/rocznie';
											|tr = '10^6 baş/yıl'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu đầu/năm';
															|ru = 'МЛН ГОЛ/ГОД';
															|en = 'MIL HEADS/YEAR'; fa = 'MIL HEADS/YEAR';
															|it = 'MLN CAPI/ANNO';
															|pl = 'MLN GŁ/ROK';
															|tr = 'MİLYON BAŞ/YIL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "558";
		Level3.Description = NStr("vi = 'Nghìn pticemest';
									|ru = 'Тысяча птицемест';
									|en = 'Thousand bird places'; fa = 'Thousand bird places';
									|it = 'Mille posti avicoli';
									|pl = 'Tysiąc miejsc drobiu';
									|tr = 'Bin tane kuş yeri'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 pticemest';
											|ru = '1000 птицемест';
											|en = '1,000 bird places'; fa = '1,000 bird places';
											|it = '1000 posti avicoli';
											|pl = '1000 miejsc drobiu';
											|tr = '1000 tane kuş yeri'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn pticemest';
															|ru = 'ТЫС ПТИЦЕМЕСТ';
															|en = 'THOUS BIRD PLACES'; fa = 'THOUS BIRD PLACES';
															|it = 'MILLE POSTI AVICOLI';
															|pl = 'TYS MIEJSC DROBIU';
															|tr = 'BİN KUŞ YERİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "559";
		Level3.Description = NStr("vi = 'Nghìn gà mái đẻ';
									|ru = 'Тысяча кур - несушек';
									|en = 'Thousand laying hens'; fa = 'Thousand laying hens';
									|it = 'Mille galline ovaiole';
									|pl = 'Tysiąc kur niosek';
									|tr = 'Bin tane yumurtlayan tavuk'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 gà mái đẻ';
											|ru = '1000 кур. несуш';
											|en = '1,000 laying hens'; fa = '1,000 laying hens';
											|it = '1000 galline ovaiole';
											|pl = '1000 kur nios';
											|tr = '1000 tane yumurtlayan tavuk'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn gà mái đẻ';
															|ru = 'ТЫС КУР. НЕСУШ';
															|en = 'THOUS LAYING HENS'; fa = 'THOUS LAYING HENS';
															|it = 'MILLE GALLINE OVAIOLE';
															|pl = 'TYS KUR NIOS';
															|tr = 'BİN TANE YUMURTLAYAN TAVUK'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "560";
		Level3.Description = NStr("vi = 'Tiền lương tối thiểu';
									|ru = 'Минимальная заработная плата';
									|en = 'Minimum wage'; fa = 'Minimum wage';
									|it = 'Salario minimo';
									|pl = 'Minimalne wynagrodzenie';
									|tr = 'Asgari ücret'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'tiền lương tối thiểu';
											|ru = 'мин. заработн. плат';
											|en = 'min wg'; fa = 'min wg';
											|it = 'salario minimo';
											|pl = 'min wynagrodzenie';
											|tr = 'asgari ücret'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Tiền lương tối thiểu';
															|ru = 'МИН ЗАРАБОТН ПЛАТ';
															|en = 'MIN WAGE'; fa = 'MIN WAGE';
															|it = 'SALARIO MINIMO';
															|pl = 'MIN WYNAGRODZENIE';
															|tr = 'ASGARİ ÜCRET'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "561";
		Level3.Description = NStr("vi = 'Nghìn tấn đôi trên giờ';
									|ru = 'Тысяча тонн пара в час';
									|en = 'Thousand tons of steam per hour'; fa = 'Thousand tons of steam per hour';
									|it = 'Mille tonnellate vapore all''ora';
									|pl = 'Tysiąc ton pary na godzinę';
									|tr = 'Saatte bin ton çift'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 t đôi/h';
											|ru = '1000 т пар/ч';
											|en = '1,000 t steam/h'; fa = '1,000 t steam/h';
											|it = '1000 t vapore/h';
											|pl = '1000 t par/h';
											|tr = '1000 t çift/s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn t đôi/h';
															|ru = 'ТЫС Т ПАР/Ч';
															|en = 'THOUS T STEAM/H'; fa = 'THOUS T STEAM/H';
															|it = 'MILLE T VAPORE/H';
															|pl = 'TYS T PAR/H';
															|tr = 'BİN T ÇİFT/S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "562";
		Level3.Description = NStr("vi = 'Nghìn trục quay';
									|ru = 'Тысяча прядильных веретен';
									|en = 'Thousand spinning spindles'; fa = 'Thousand spinning spindles';
									|it = 'Mille fusi per filatura';
									|pl = 'Tysiąc wrzecion przędzalniczych';
									|tr = 'Binlerce dönen mil'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 trục quay';
											|ru = '10^3 пряд.верет';
											|en = '10^3 spinning spindles'; fa = '10^3 spinning spindles';
											|it = '10^3 fusi fil.';
											|pl = '10^3 wrzecion przędz';
											|tr = '10^3 dönen mil'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn trục quay';
															|ru = 'ТЫС ПРЯД ВЕРЕТ';
															|en = 'THOUS SPINNING SPINDLES'; fa = 'THOUS SPINNING SPINDLES';
															|it = 'MILLE FUSI PER FILATURA';
															|pl = 'TYS WRZECION PRZĘDZ';
															|tr = 'BİNLERCE DÖNEN MİL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "563";
		Level3.Description = NStr("vi = 'Nghìn chỗ quay';
									|ru = 'Тысяча прядильных мест';
									|en = 'Thousand spinning positions'; fa = 'Thousand spinning positions';
									|it = 'Mille postazione per filatura';
									|pl = 'Tysiąc wrzecion przędz';
									|tr = 'Binlerce dönen yer'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 chỗ quay';
											|ru = '10^3 пряд.мест';
											|en = '10^3 spinning positions'; fa = '10^3 spinning positions';
											|it = '10^3 postazioni fil.';
											|pl = '10^3 wrzecion przędz';
											|tr = '10^3 dönen yer'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn chỗ quay';
															|ru = 'ТЫС ПРЯД МЕСТ';
															|en = 'THOUS SPINNING POSITIONS'; fa = 'THOUS SPINNING POSITIONS';
															|it = 'MILLE POSTAZIONI PER FILATURA';
															|pl = 'TYS MIEJSC PRZĘDZ';
															|tr = 'BİNLERCE DÖNEN YER'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "639";
		Level3.Description = NStr("vi = 'Liều';
									|ru = 'Доза';
									|en = 'Dose'; fa = 'Dose';
									|it = 'Dose';
									|pl = 'Dose';
									|tr = 'Doz'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Liều';
											|ru = 'доз';
											|en = 'DOSE'; fa = 'DOSE';
											|it = 'доз';
											|pl = 'DOSE';
											|tr = 'HANE HALKI'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Liều';
															|ru = 'ДОЗ';
															|en = 'DOSE'; fa = 'DOSE';
															|it = 'ДОЗ';
															|pl = 'DOSE';
															|tr = 'HANE HALKI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "640";
		Level3.Description = NStr("vi = 'Nghìn liều';
									|ru = 'Тысяча доз';
									|en = 'Thousand doses'; fa = 'Thousand doses';
									|it = 'Mille dosi';
									|pl = 'Tysiąc dóz';
									|tr = 'Binlerce doz'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 liều';
											|ru = '1000 доз';
											|en = '1,000 doses'; fa = '1,000 doses';
											|it = '1000 dosi';
											|pl = '1000 dóz';
											|tr = '1000 doz'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn liều';
															|ru = 'ТЫС ДОЗ';
															|en = 'THOUS DOSES'; fa = 'THOUS DOSES';
															|it = 'MILLE DOSI';
															|pl = 'TYS DÓZ';
															|tr = 'BİNLERCE DOZ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "642";
		Level3.Description = NStr("vi = 'Đơn vị';
									|ru = 'Единица';
									|en = 'Unit'; fa = 'واحد';
									|it = 'Unità';
									|pl = 'Unit';
									|tr = 'Birim'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'đv';
											|ru = 'ед';
											|en = 'unit'; fa = 'واحد';
											|it = 'ед';
											|pl = 'unit';
											|tr = 'birim'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'đv';
															|ru = 'ЕД';
															|en = 'unit'; fa = 'واحد';
															|it = 'ЕД';
															|pl = 'unit';
															|tr = 'birim'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "643";
		Level3.Description = NStr("vi = 'Nghìn đơn vị';
									|ru = 'Тысяча единиц';
									|en = 'Thousand units'; fa = 'Thousand units';
									|it = 'Mille unità';
									|pl = 'Tysiąc jednostek';
									|tr = 'Binlerce birim'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 đv';
											|ru = '1000 ед';
											|en = '1,000 U'; fa = '1,000 U';
											|it = '1000 un.';
											|pl = '1000 jedn';
											|tr = '1000 birim'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn đv';
															|ru = 'ТЫС ЕД';
															|en = 'THOUS U'; fa = 'THOUS U';
															|it = 'MILLE UN.';
															|pl = 'TYS JEDN';
															|tr = 'BİNLERCE BİRİM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "644";
		Level3.Description = NStr("vi = 'Triệu đơn vị';
									|ru = 'Миллион единиц';
									|en = 'Million units'; fa = 'Million units';
									|it = 'Un milione di unità';
									|pl = 'Milion jednostek';
									|tr = 'Milyon birim'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 đv';
											|ru = '10^6 ед';
											|en = '10^6 U'; fa = '10^6 U';
											|it = '10^6 un.';
											|pl = '10^6 jedn';
											|tr = '10^6 birim'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu đv';
															|ru = 'МЛН ЕД';
															|en = 'MIL U'; fa = 'MIL U';
															|it = 'MLN UN.';
															|pl = 'MLN JEDN';
															|tr = 'MİLYON BİRİM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "661";
		Level3.Description = NStr("vi = 'Kênh';
									|ru = 'Канал';
									|en = 'Channel'; fa = 'کانال';
									|it = 'Канал';
									|pl = 'Channel';
									|tr = 'KANAL'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Kênh';
											|ru = 'канал';
											|en = 'channel'; fa = 'channel';
											|it = 'канал';
											|pl = 'channel';
											|tr = 'KANAL'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Kênh';
															|ru = 'КАНАЛ';
															|en = 'CHANNEL'; fa = 'CHANNEL';
															|it = 'КАНАЛ';
															|pl = 'CHANNEL';
															|tr = 'KANAL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "673";
		Level3.Description = NStr("vi = 'Nghìn tập hợp';
									|ru = 'Тысяча комплектов';
									|en = 'Thousand set s'; fa = 'Thousand set s';
									|it = 'Mille kit';
									|pl = 'Tysiąc zestawów';
									|tr = 'Binlerce set'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 tập hợp';
											|ru = '10^3 компл';
											|en = '10^3  sets'; fa = '10^3  sets';
											|it = '10^3 kit';
											|pl = '10^3 zest';
											|tr = '10^3 set'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn tập hợp';
															|ru = 'ТЫС КОМПЛ';
															|en = 'THOU SETS'; fa = 'THOU SETS';
															|it = 'MILLE KIT';
															|pl = 'TYS ZEST';
															|tr = 'BİNLERCE SET'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "698";
		Level3.Description = NStr("vi = 'Chỗ';
									|ru = 'Место';
									|en = 'Seat'; fa = 'Seat';
									|it = 'Posto';
									|pl = 'Seat';
									|tr = 'Yer'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'chỗ ngồi';
											|ru = 'посад. мест';
											|en = 'SEATS'; fa = 'SEATS';
											|it = 'posto a sedere';
											|pl = 'miejsc siedzących';
											|tr = 'iniş. yeri'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Chỗ';
															|ru = 'МЕСТ';
															|en = 'SEATS'; fa = 'SEATS';
															|it = 'МЕСТ';
															|pl = 'SEATS';
															|tr = 'YER'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "699";
		Level3.Description = NStr("vi = 'Nghìn chỗ';
									|ru = 'Тысяча мест';
									|en = 'Thousand seats'; fa = 'Thousand seats';
									|it = 'Mille posti';
									|pl = 'Tysiąc miejsc';
									|tr = 'Binlerce yer'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 chỗ';
											|ru = '1000 мест';
											|en = '1,000 seats'; fa = '1,000 seats';
											|it = '1000 posti';
											|pl = '1000 miejsc';
											|tr = '1000 yer'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn chỗ';
															|ru = 'ТЫС МЕСТ';
															|en = 'THOUS SEATS'; fa = 'THOUS SEATS';
															|it = 'MILLE POSTI';
															|pl = 'TYS MIEJSC';
															|tr = 'BİNLERCE YER'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "709";
		Level3.Description = NStr("vi = 'Nghìn số';
									|ru = 'Тысяча номеров';
									|en = 'Thousand rooms'; fa = 'Thousand rooms';
									|it = 'Mille numeri';
									|pl = 'Tysiąc numerów';
									|tr = 'Binlerce numara'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 số';
											|ru = '10^3 ном';
											|en = '10^3 rooms'; fa = '10^3 rooms';
											|it = '10^3 num';
											|pl = '10^3 num';
											|tr = '10^3 numara'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN SỐ';
															|ru = 'ТЫС НОМ';
															|en = 'THOUS ROOMS'; fa = 'THOUS ROOMS';
															|it = 'MILLE NUM';
															|pl = 'TYS NUM';
															|tr = 'BİNLERCE NUMARA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "724";
		Level3.Description = NStr("vi = 'Nghìn hecta các phần';
									|ru = 'Тысяча гектаров порций';
									|en = 'Thousand hectares of portions'; fa = 'Thousand hectares of portions';
									|it = 'Mille ettari di porzioni';
									|pl = 'Tysiąc hektarów porcji';
									|tr = 'Binlerce hektar porsiyon'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 ha các phần';
											|ru = '10^3 га порц';
											|en = '10^3 ha ptn'; fa = '10^3 ha ptn';
											|it = '10^3 ha di porzioni';
											|pl = '10^3 ha porc';
											|tr = '10^3 ha porsiyon'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn hecta các phần';
															|ru = 'ТЫС ГА ПОРЦ';
															|en = 'THOUS HA PTN'; fa = 'THOUS HA PTN';
															|it = 'MILLE HA DI PORZIONI';
															|pl = 'TYS HA PORC';
															|tr = 'BİNLERCE HA PORSİYON'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "728";
		Level3.Description = NStr("vi = 'Đóng gói';
									|ru = 'Пачка';
									|en = 'Pack'; fa = 'بسته‌بندی';
									|it = 'Pack';
									|pl = 'Pack';
									|tr = 'Paket'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'gói';
											|ru = 'пач';
											|en = 'pack'; fa = 'pack';
											|it = 'pack';
											|pl = 'pack';
											|tr = 'pak'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'GÓI';
															|ru = 'ПАЧ';
															|en = 'PACK'; fa = 'PACK';
															|it = 'PACK';
															|pl = 'PACK';
															|tr = 'PAK'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "729";
		Level3.Description = NStr("vi = 'Nghìn gói';
									|ru = 'Тысяча пачек';
									|en = 'Thousand packs'; fa = 'Thousand packs';
									|it = 'Mille pacchetti';
									|pl = 'Tysiąc paczek';
									|tr = 'Binlerce paket'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 gói';
											|ru = '10^3 пач';
											|en = '10^3 packs'; fa = '10^3 packs';
											|it = '10^3 pacch.';
											|pl = '10^3 pacz';
											|tr = '10^3 paket'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN GÓI';
															|ru = 'ТЫС ПАЧ';
															|en = 'THOUS PACKS'; fa = 'THOUS PACKS';
															|it = 'MILLE PACCH.';
															|pl = 'TYS PACZ';
															|tr = 'BİNLERCE PAKET'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "744";
		Level3.Description = NStr("vi = 'Phần trăm';
									|ru = 'Процент';
									|en = 'Percent'; fa = 'درصد';
									|it = 'Percentuale';
									|pl = 'Percent';
									|tr = 'Yüzde'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '%';
											|ru = '%';
											|en = '%'; fa = 'درصد';
											|it = '%';
											|pl = '%';
											|tr = '%'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'PHẦN TRĂM';
															|ru = 'ПРОЦ';
															|en = 'PERCENT S'; fa = 'PERCENT S';
															|it = 'PERC';
															|pl = 'PERCENT S';
															|tr = 'YÜZDE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "746";
		Level3.Description = NStr("vi = 'PPm (0,1 phần trăm)';
									|ru = 'Промилле (0,1 процента)';
									|en = 'Per mil (0.1 percent)'; fa = 'Per mil (0.1 percent)';
									|it = 'Per mille (0,1 percento)';
									|pl = 'Promille (0,1 procentu)';
									|tr = 'Binde bir (yüzde 0,1)'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'ppm';
											|ru = 'промилле';
											|en = 'per mil'; fa = 'per mil';
											|it = 'промилле';
											|pl = 'per mil';
											|tr = 'binde'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ppm';
															|ru = 'ПРОМИЛЛЕ';
															|en = 'per mil'; fa = 'per mil';
															|it = 'ПРОМИЛЛЕ';
															|pl = 'per mil';
															|tr = 'binde'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "747";
		Level3.Description = NStr("vi = 'Điểm cơ sở';
									|ru = 'Базисный пункт';
									|en = 'Basis point'; fa = 'Basis point';
									|it = 'Basis point';
									|pl = 'Basis point';
									|tr = 'Baz puan'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'điểm cơ sở';
											|ru = 'б. п.';
											|en = 'b. p.'; fa = 'b. p.';
											|it = 'b. p.';
											|pl = 'b. p.';
											|tr = 'b. p.'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ĐIỂMCƠSỞ';
															|ru = 'БП';
															|en = 'BP'; fa = 'BP';
															|it = 'BP';
															|pl = 'BP';
															|tr = 'BP'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "751";
		Level3.Description = NStr("vi = 'Nghìn cuộn';
									|ru = 'Тысяча рулонов';
									|en = 'Thousand rolls'; fa = 'Thousand rolls';
									|it = 'Mille rotoli';
									|pl = 'Tysiąc rulonów';
									|tr = 'Binlerce rulo'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 cuộn';
											|ru = '1000 рул';
											|en = '1,000 rl'; fa = '1,000 rl';
											|it = '1000 rot';
											|pl = '1000 rul';
											|tr = '1000 rulo'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn cuộn';
															|ru = 'ТЫС РУЛ';
															|en = 'THOUS RL'; fa = 'THOUS RL';
															|it = 'MILLE ROT';
															|pl = 'TYS RUL';
															|tr = 'BİNLERCE RULO'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "761";
		Level3.Description = NStr("vi = 'Nghìn cây';
									|ru = 'Тысяча станов';
									|en = 'Thousand mills'; fa = 'Thousand mills';
									|it = 'Mille laminatoi';
									|pl = 'Tysiąc kompletów';
									|tr = 'Binlerce arazi birimi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 cây';
											|ru = '10^3 стан';
											|en = '10^3 mills'; fa = '10^3 mills';
											|it = '10^3 laminatoi';
											|pl = '10^3 kompl';
											|tr = '10^3 arazi birimi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn cây';
															|ru = 'ТЫС СТАН';
															|en = 'THOUS MILLS'; fa = 'THOUS MILLS';
															|it = 'MILLE LAMINATOI';
															|pl = 'TYS KOMPL';
															|tr = 'BİNLERCE ARAZİ BİRİMİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "762";
		Level3.Description = NStr("vi = 'Trạm';
									|ru = 'Станция';
									|en = 'Station'; fa = 'Station';
									|it = 'Stazione';
									|pl = 'Station';
									|tr = 'İstasyon'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Trạm';
											|ru = 'станц';
											|en = 'STATION'; fa = 'STATION';
											|it = 'станц';
											|pl = 'STATION';
											|tr = 'İSTASYON'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Trạm';
															|ru = 'СТАНЦ';
															|en = 'STATION'; fa = 'STATION';
															|it = 'СТАНЦ';
															|pl = 'STATION';
															|tr = 'İSTASYON'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "775";
		Level3.Description = NStr("vi = 'Nghìn ống';
									|ru = 'Тысяча тюбиков';
									|en = 'Thousand squeeze tubes'; fa = 'Thousand squeeze tubes';
									|it = 'Mille tubetti';
									|pl = 'Tysiąc tubek';
									|tr = 'Binlerce tüp'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 ống';
											|ru = '10^3 тюбик';
											|en = '10^3 squeeze tubes'; fa = '10^3 squeeze tubes';
											|it = '10^3 tubetti';
											|pl = '10^3 tubek';
											|tr = '10^3 tüp'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn ống';
															|ru = 'ТЫС ТЮБИК';
															|en = 'THOUS SQUEEZE TUBES'; fa = 'THOUS SQUEEZE TUBES';
															|it = 'MILLE TUBETTI';
															|pl = 'TYS TUBEK';
															|tr = 'BİN TÜP'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "776";
		Level3.Description = NStr("vi = 'Nghìn ống quy ước';
									|ru = 'Тысяча условных тубов';
									|en = 'Thousand conventional tubes'; fa = 'Thousand conventional tubes';
									|it = 'Mille cubi convenzionali';
									|pl = 'Tysiąc tubek umownych';
									|tr = 'Bin koşullu tüp'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 ống quy ước';
											|ru = '10^3 усл.туб';
											|en = '10^3 convl. tubes'; fa = '10^3 convl. tubes';
											|it = '10^3 tubi conv.';
											|pl = '10^3 tub. war';
											|tr = '10^3 koşullu.tüp'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn ống quy ước';
															|ru = 'ТЫС УСЛ ТУБ';
															|en = 'THOUS CONVL TUBES'; fa = 'THOUS CONVL TUBES';
															|it = 'MILLE TUBI CONV.';
															|pl = 'TYS TUB WAR';
															|tr = 'BİN KOŞULLU TÜP'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "779";
		Level3.Description = NStr("vi = 'Triệu gói';
									|ru = 'Миллион упаковок';
									|en = 'Million packaging units'; fa = 'Million packaging units';
									|it = 'Un milione di confezioni';
									|pl = 'Milion opakowań';
									|tr = 'Milyon paketleme ünitesi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 gói';
											|ru = '10^6 упак';
											|en = '10^6 pkg'; fa = '10^6 pkg';
											|it = '10^6 confezioni';
											|pl = '10^6 opak';
											|tr = '10^6 paketleme ünitesi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu gói';
															|ru = 'МЛН УПАК';
															|en = 'MIL PKG'; fa = 'MIL PKG';
															|it = 'MILN DI CONFEZIONI';
															|pl = 'MLN OPAK';
															|tr = 'MİLYON PAKETLEME ÜNİTESİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "782";
		Level3.Description = NStr("vi = 'Nghìn gói';
									|ru = 'Тысяча упаковок';
									|en = 'Thousand packaging units'; fa = 'Thousand packaging units';
									|it = 'Mille confezioni';
									|pl = 'Tysiąc opakowań';
									|tr = 'Bin paketleme ünitesi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 gói';
											|ru = '10^3 упак';
											|en = '10^3 pkg'; fa = '10^3 pkg';
											|it = '10^3 confezioni';
											|pl = '10^3 opak';
											|tr = '10^3 paketleme ünitesi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn gói';
															|ru = 'ТЫС УПАК';
															|en = 'THOUS PKG'; fa = 'THOUS PKG';
															|it = 'MILLE CONFEZIONI';
															|pl = 'TYS OPAK';
															|tr = 'BİN PAKETLEME ÜNİTESİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "792";
		Level3.Description = NStr("vi = 'Người';
									|ru = 'Человек';
									|en = 'People'; fa = 'People';
									|it = 'Persona';
									|pl = 'People';
									|tr = 'Kişi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Người';
											|ru = 'чел';
											|en = 'PPL'; fa = 'PPL';
											|it = 'ЧЕЛ';
											|pl = 'PPL';
											|tr = 'KİŞİ'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Người';
															|ru = 'ЧЕЛ';
															|en = 'PPL'; fa = 'PPL';
															|it = 'ЧЕЛ';
															|pl = 'PPL';
															|tr = 'KİŞİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "793";
		Level3.Description = NStr("vi = 'Nghìn người';
									|ru = 'Тысяча человек';
									|en = 'Thousand people'; fa = 'Thousand people';
									|it = 'Mille persone';
									|pl = 'Tysiąc osób';
									|tr = 'Bin kişi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 người';
											|ru = '1000 чел';
											|en = '1,000 people'; fa = '1,000 people';
											|it = '1000 pers';
											|pl = '1000 os';
											|tr = '1000 kişi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn người';
															|ru = 'ТЫС ЧЕЛ';
															|en = 'THOUS PEOPLE'; fa = 'THOUS PEOPLE';
															|it = 'MILLE PERS';
															|pl = 'TYS OSÓB';
															|tr = 'BİN KİŞİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "794";
		Level3.Description = NStr("vi = 'Triệu người';
									|ru = 'Миллион человек';
									|en = 'Million people'; fa = 'Million people';
									|it = 'Un milione di persone';
									|pl = 'Milion człowiek';
									|tr = 'Milyon kişi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 người';
											|ru = '10^6 чел';
											|en = '10^6 people'; fa = '10^6 people';
											|it = '10^6 pers';
											|pl = '10^6 czł';
											|tr = '10^6 kişi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu người';
															|ru = 'МЛН ЧЕЛ';
															|en = 'MIL PEOPLE'; fa = 'MIL PEOPLE';
															|it = 'MLN PERS';
															|pl = 'MLN CZŁ';
															|tr = 'MİLYON KİŞİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "808";
		Level3.Description = NStr("vi = 'Triệu bản';
									|ru = 'Миллион экземпляров';
									|en = 'Million copies'; fa = 'Million copies';
									|it = 'Un milione di copie';
									|pl = 'Milion egzemplarzy';
									|tr = 'Milyon örnek'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 bản';
											|ru = '10^6 экз';
											|en = '10^6 copies'; fa = '10^6 copies';
											|it = '10^6 copie';
											|pl = '10^6 egz';
											|tr = '10^6 örnek'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu bản';
															|ru = 'МЛН ЭКЗ';
															|en = 'MIL COPIES'; fa = 'MIL COPIES';
															|it = 'MLN COPIE';
															|pl = 'MLN EGZ';
															|tr = 'MİLYON ÖRNEK'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "810";
		Level3.Description = NStr("vi = 'Ô hàng';
									|ru = 'Ячейка';
									|en = 'Storage bin'; fa = 'محل نگهداری';
									|it = 'Cella';
									|pl = 'Storage bin';
									|tr = 'Hücre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'ô';
											|ru = 'яч';
											|en = 'storage bins'; fa = 'storage bins';
											|it = 'яч';
											|pl = 'storage bins';
											|tr = 'hücre'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ô';
															|ru = 'ЯЧ';
															|en = 'storage bins'; fa = 'storage bins';
															|it = 'ЯЧ';
															|pl = 'storage bins';
															|tr = 'hücre'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "812";
		Level3.Description = NStr("vi = 'Thùng';
									|ru = 'Ящик';
									|en = 'Case'; fa = 'پرونده';
									|it = 'Cassa';
									|pl = 'Case';
									|tr = 'Kutu'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Thùng';
											|ru = 'ящ';
											|en = 'CASE'; fa = 'CASE';
											|it = 'ящ';
											|pl = 'CASE';
											|tr = 'KUTU'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Thùng';
															|ru = 'ЯЩ';
															|en = 'CASE'; fa = 'CASE';
															|it = 'ЯЩ';
															|pl = 'CASE';
															|tr = 'KUTU'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "836";
		Level3.Description = NStr("vi = 'Đầu';
									|ru = 'Голова';
									|en = 'Head'; fa = 'Head';
									|it = 'Testa';
									|pl = 'Head';
									|tr = 'Baş'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Đầu';
											|ru = 'гол';
											|en = 'HEA'; fa = 'HEA';
											|it = 'гол';
											|pl = 'HEA';
											|tr = 'BAŞ'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Đầu';
															|ru = 'ГОЛ';
															|en = 'HEA'; fa = 'HEA';
															|it = 'ГОЛ';
															|pl = 'HEA';
															|tr = 'BAŞ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "837";
		Level3.Description = NStr("vi = 'Nghìn đôi';
									|ru = 'Тысяча пар';
									|en = 'Thousand pairs'; fa = 'Thousand pairs';
									|it = 'Mille paia';
									|pl = 'Tysiąc par';
									|tr = 'Bin çift'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 đôi';
											|ru = '1000 пар';
											|en = '1,000 pairs'; fa = '1,000 pairs';
											|it = '1000 paia';
											|pl = '1000 par';
											|tr = '1000 çift'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn đôi';
															|ru = 'ТЫС ПАР';
															|en = 'THOUS PAIRS'; fa = 'THOUS PAIRS';
															|it = 'MILLE PAIA';
															|pl = 'TYS PAR';
															|tr = 'BİN ÇİFT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "838";
		Level3.Description = NStr("vi = 'Triệu đôi';
									|ru = 'Миллион пар';
									|en = 'Million pairs'; fa = 'Million pairs';
									|it = 'Un milione di paia';
									|pl = 'Milion par';
									|tr = 'Milyon çift'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 đôi';
											|ru = '10^6 пар';
											|en = '10^6 pairs'; fa = '10^6 pairs';
											|it = '10^6 paia';
											|pl = '10^6 par';
											|tr = '10^6 çift'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu đôi';
															|ru = 'МЛН ПАР';
															|en = 'MIL PAIRS'; fa = 'MIL PAIRS';
															|it = 'MLN PAIA';
															|pl = 'MLN PAR';
															|tr = 'MİLYON ÇİFT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "839";
		Level3.Description = NStr("vi = 'Bộ';
									|ru = 'Комплект';
									|en = 'Kit'; fa = 'کیت';
									|it = 'Kit';
									|pl = 'Kit';
									|tr = 'Set'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'bộ';
											|ru = 'компл';
											|en = 'sets'; fa = 'sets';
											|it = 'компл';
											|pl = 'sets';
											|tr = 'set'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'bộ';
															|ru = 'КОМПЛ';
															|en = 'sets'; fa = 'sets';
															|it = 'КОМПЛ';
															|pl = 'sets';
															|tr = 'set'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "840";
		Level3.Description = NStr("vi = 'Phiên';
									|ru = 'Секция';
									|en = 'Section'; fa = 'بخش';
									|it = 'Sezione';
									|pl = 'Section';
									|tr = 'Bölüm'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'PHIÊN';
											|ru = 'секц';
											|en = 'SECT'; fa = 'SECT';
											|it = 'sezione';
											|pl = 'SECT';
											|tr = 'BÖLÜM'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'PHIÊN';
															|ru = 'СЕКЦ';
															|en = 'SECT'; fa = 'SECT';
															|it = 'sezione';
															|pl = 'SECT';
															|tr = 'BÖLÜM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "868";
		Level3.Description = NStr("vi = 'Chai';
									|ru = 'Бутылка';
									|en = 'Bottle'; fa = 'Bottle';
									|it = 'Bottiglia';
									|pl = 'Bottle';
									|tr = 'Şişe'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'chai';
											|ru = 'бут';
											|en = 'btl'; fa = 'btl';
											|it = 'бут';
											|pl = 'btl';
											|tr = 'şişe'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'chai';
															|ru = 'БУТ';
															|en = 'btl'; fa = 'btl';
															|it = 'БУТ';
															|pl = 'btl';
															|tr = 'şişe'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "869";
		Level3.Description = NStr("vi = 'Nghìn chai';
									|ru = 'Тысяча бутылок';
									|en = 'Thousand bottles'; fa = 'Thousand bottles';
									|it = 'Mille bottiglie';
									|pl = 'Tysiąc butelek';
									|tr = 'Bin şişe'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 chai';
											|ru = '1000 бут';
											|en = '1,000 btl'; fa = '1,000 btl';
											|it = '1000 bott';
											|pl = '1000 but';
											|tr = '1000 şişe'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn chai';
															|ru = 'ТЫС БУТ';
															|en = 'THOUS BTL'; fa = 'THOUS BTL';
															|it = 'MILLE BOTT';
															|pl = 'TYS BUT';
															|tr = 'BİN ŞİŞE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "870";
		Level3.Description = NStr("vi = 'Ống thuốc';
									|ru = 'Ампула';
									|en = 'Ampoule'; fa = 'Ampoule';
									|it = 'Fiala';
									|pl = 'Ampoule';
									|tr = 'Ampul'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'ống thuốc';
											|ru = 'ампул';
											|en = 'amp'; fa = 'amp';
											|it = 'ампул';
											|pl = 'amp';
											|tr = 'ampul'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ống thuốc';
															|ru = 'АМПУЛ';
															|en = 'amp'; fa = 'amp';
															|it = 'АМПУЛ';
															|pl = 'amp';
															|tr = 'ampul'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "871";
		Level3.Description = NStr("vi = 'Nghìn ống thuốc';
									|ru = 'Тысяча ампул';
									|en = 'Thousand ampoules'; fa = 'Thousand ampoules';
									|it = 'Mille fiale';
									|pl = 'Tysiąc ampułek';
									|tr = 'Bin ampul'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 ống thuốc';
											|ru = '1000 ампул';
											|en = '1,000 amp'; fa = '1,000 amp';
											|it = '1000 fiale';
											|pl = '1000 ampułek';
											|tr = '1000 ampul'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN ỐNG THUỐC';
															|ru = 'ТЫС АМПУЛ';
															|en = 'THOUS AMP'; fa = 'THOUS AMP';
															|it = 'MILLE FIALE';
															|pl = 'TYS AMPUŁEK';
															|tr = 'BİN AMPUL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "872";
		Level3.Description = NStr("vi = 'Lọ nhỏ';
									|ru = 'Флакон';
									|en = 'Vial'; fa = 'Vial';
									|it = 'Flacone';
									|pl = 'Vial';
									|tr = 'Kapaklı şişe'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Lọ nhỏ';
											|ru = 'флак';
											|en = 'VIALS'; fa = 'VIALS';
											|it = 'флак';
											|pl = 'VIALS';
											|tr = 'KAPAKLI ŞİŞE'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Lọ nhỏ';
															|ru = 'ФЛАК';
															|en = 'VIALS'; fa = 'VIALS';
															|it = 'ФЛАК';
															|pl = 'VIALS';
															|tr = 'KAPAKLI ŞİŞE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "873";
		Level3.Description = NStr("vi = 'Nghìn lọ nhỏ';
									|ru = 'Тысяча флаконов';
									|en = 'Thousand vials'; fa = 'Thousand vials';
									|it = 'Mille flaconi';
									|pl = 'Tysiąc flakoników';
									|tr = 'Bin kapaklı şişe'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 lọ nhỏ';
											|ru = '1000 флак';
											|en = '1,000 vials'; fa = '1,000 vials';
											|it = '1000 flaconi';
											|pl = '1000 flak';
											|tr = '1000 kapaklı şişe'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN LỌ NHỎ';
															|ru = 'ТЫС ФЛАК';
															|en = 'THOUS VIALS'; fa = 'THOUS VIALS';
															|it = 'MILLE FLACONI';
															|pl = 'TYS FLAK';
															|tr = 'BİN KAPAKLI ŞİŞE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "874";
		Level3.Description = NStr("vi = 'Nghìn ống';
									|ru = 'Тысяча тубов';
									|en = 'Thousand tubes'; fa = 'Thousand tubes';
									|it = 'Mille tubi';
									|pl = 'Tysiąc tub';
									|tr = 'Bin tüp'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 ống';
											|ru = '1000 туб';
											|en = '1,000 tubes'; fa = '1,000 tubes';
											|it = '1000 tubi';
											|pl = '1000 tub';
											|tr = '1000 tüp'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN ỐNG';
															|ru = 'ТЫС ТУБ';
															|en = 'THOUS TUBES'; fa = 'THOUS TUBES';
															|it = 'MILLE TUBI';
															|pl = 'TYS TUB';
															|tr = 'BİN TÜP'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "875";
		Level3.Description = NStr("vi = 'Nghìn hộp';
									|ru = 'Тысяча коробок';
									|en = 'Thousand boxes'; fa = 'Thousand boxes';
									|it = 'Mille scatole';
									|pl = 'Tysiąc pudeł';
									|tr = 'Bin kutu'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 hộp';
											|ru = '1000 кор';
											|en = '1,000 boxes'; fa = '1,000 boxes';
											|it = '1000 scat';
											|pl = '1000 pud';
											|tr = '1000 kutu'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN HỘP';
															|ru = 'ТЫС КОР';
															|en = 'THOUS BOXES'; fa = 'THOUS BOXES';
															|it = 'MILLE SCAT';
															|pl = 'TYS PUD';
															|tr = 'BİN KUTU'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "876";
		Level3.Description = NStr("vi = 'Đơn vị quy ước';
									|ru = 'Условная единица';
									|en = 'Conventional unit'; fa = 'Conventional unit';
									|it = 'Unità convenzionale';
									|pl = 'Jednostka umowna';
									|tr = 'Koşullu birim'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'đv qư';
											|ru = 'усл. ед';
											|en = 'cu'; fa = 'cu';
											|it = 'un. conv.';
											|pl = 'jed. war';
											|tr = 'koşullu. birim'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ĐV QƯ';
															|ru = 'УСЛ ЕД';
															|en = 'CU S'; fa = 'CU S';
															|it = 'UN. CONV.';
															|pl = 'JEDN WARUN';
															|tr = 'KOŞULLU BİRİM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "877";
		Level3.Description = NStr("vi = 'Nghìn đơn vị quy ước';
									|ru = 'Тысяча условных единиц';
									|en = 'Thousand conventional units'; fa = 'Thousand conventional units';
									|it = 'Mille unità convenzionali';
									|pl = 'Tysiąc jednostek umownych';
									|tr = 'Bin koşullu birim'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 đv qư';
											|ru = '1000 усл. ед';
											|en = '1,000 cu'; fa = '1,000 cu';
											|it = '1000 un. conv.';
											|pl = '1000 jedn. war';
											|tr = '1000 koşullu. birim'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN ĐV QƯ';
															|ru = 'ТЫС УСЛ ЕД';
															|en = 'THOUS CU'; fa = 'THOUS CU';
															|it = 'MILLE UN.CONV.';
															|pl = 'TYS JED WAR';
															|tr = 'BİN KOŞULLU BİRİM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "878";
		Level3.Description = NStr("vi = 'Triệu đơn vị quy ước';
									|ru = 'Миллион условных единиц';
									|en = 'Million conventional units'; fa = 'Million conventional units';
									|it = 'Un milione di unità convenzionali';
									|pl = 'Milion jednostek umownych';
									|tr = 'Milyon koşullu birim'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 đv qư';
											|ru = '10^6 усл. ед';
											|en = '10^6 cu'; fa = '10^6 cu';
											|it = '10^6 un. conv.';
											|pl = '10^6 jedn. umown';
											|tr = '10^6 koşullu. birim'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU ĐV QƯ';
															|ru = 'МЛН УСЛ ЕД';
															|en = 'MIL CU'; fa = 'MIL CU';
															|it = 'MLN UN. CONV:';
															|pl = 'MLN JEDN UMOWN';
															|tr = 'MİLYON KOŞULLU BİRİM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "879";
		Level3.Description = NStr("vi = 'Cái quy ước';
									|ru = 'Условная штука';
									|en = 'Conventional piece'; fa = 'Conventional piece';
									|it = 'Pezzo convenzionale';
									|pl = 'Sztuka umowna';
									|tr = 'Koşullu parça'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'c qư';
											|ru = 'усл. шт';
											|en = 'convl. pcs'; fa = 'convl. pcs';
											|it = 'pz. conv.';
											|pl = 'jedn. war';
											|tr = 'koşullu. parça'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'C QUY ƯỚC';
															|ru = 'УСЛ ШТ';
															|en = 'CONVL PCS'; fa = 'CONVL PCS';
															|it = 'PZ. CONV.';
															|pl = 'JED WAR';
															|tr = 'KOŞULLU PARÇA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "880";
		Level3.Description = NStr("vi = 'Nghìn cái quy ước';
									|ru = 'Тысяча условных штук';
									|en = 'Thousand conventional pieces'; fa = 'Thousand conventional pieces';
									|it = 'Mille pezzi convenzionali';
									|pl = 'Tysiąc sztuk umownych';
									|tr = 'Bin koşullu parça'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 chiếc quy ước';
											|ru = '1000 усл. шт';
											|en = '1,000 convl. pcs'; fa = '1,000 convl. pcs';
											|it = '1000 pz. conv.';
											|pl = '1000 szt. war';
											|tr = '1000 koşullu. parça'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN CHIẾC QUY ƯỚC';
															|ru = 'ТЫС УСЛ ШТ';
															|en = 'THOUS CONVL PCS'; fa = 'THOUS CONVL PCS';
															|it = 'MILLE PZ. CONV.';
															|pl = 'TYS SZT WAR';
															|tr = 'BİN KOŞULLU PARÇA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "881";
		Level3.Description = NStr("vi = 'Lọ quy ước';
									|ru = 'Условная банка';
									|en = 'Conventional can'; fa = 'Conventional can';
									|it = 'Barattolo convenzionale';
									|pl = 'Słoik umowny';
									|tr = 'Koşullu kap'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'lọ quy ước';
											|ru = 'усл. банк';
											|en = 'convl. cans'; fa = 'convl. cans';
											|it = 'barattolo conv.';
											|pl = 'słoików war';
											|tr = 'koşullu. kap'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'LỌ QUY ƯỚC';
															|ru = 'УСЛ БАНК';
															|en = 'CONVL CANS'; fa = 'CONVL CANS';
															|it = 'BARATTOLO CONV.';
															|pl = 'SŁOIKÓW WAR';
															|tr = 'KOŞULLU KAP'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "882";
		Level3.Description = NStr("vi = 'Nghìn lọ quy ước';
									|ru = 'Тысяча условных банок';
									|en = 'Thousand conventional cans'; fa = 'Thousand conventional cans';
									|it = 'Mille barattoli convenzionali';
									|pl = 'Tysiąc słoików umownych';
									|tr = 'Bin koşullu kap'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 lọ quy ước';
											|ru = '1000 усл. банк';
											|en = '1,000 convl. cans'; fa = '1,000 convl. cans';
											|it = '1000 barattoli conv.';
											|pl = '1000 słoików war';
											|tr = '1000 koşullu. kap'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN LỌ QUY ƯỚC';
															|ru = 'ТЫС УСЛ БАНК';
															|en = 'THOUS CONVL CANS'; fa = 'THOUS CONVL CANS';
															|it = 'MILLE BARATTOLI CONV.';
															|pl = 'TYS SŁOIKÓW WAR';
															|tr = 'BİN KOŞULLU KAP'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "883";
		Level3.Description = NStr("vi = 'Triệu lọ quy ước';
									|ru = 'Миллион условных банок';
									|en = 'Million conventional cans'; fa = 'Million conventional cans';
									|it = 'Un milione di barattoli convenzionali';
									|pl = 'Milion słoików umownych';
									|tr = 'Milyon koşullu kap'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 lọ quy ước';
											|ru = '10^6 усл. банк';
											|en = '10^6 convl. cans'; fa = '10^6 convl. cans';
											|it = '10^6 barattoli conv.';
											|pl = '10^6 słoików war';
											|tr = '10^6 koşullu. kap'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU LỌ QUY ƯỚC';
															|ru = 'МЛН УСЛ БАНК';
															|en = 'MIL CONVL CANS'; fa = 'MIL CONVL CANS';
															|it = 'MLN BARATTOLI CONV.';
															|pl = 'MLN SŁOIKÓW WAR';
															|tr = 'MİLYON KOŞULLU KAP'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "884";
		Level3.Description = NStr("vi = 'MẢNH QUY ƯỚC';
									|ru = 'Условный кусок';
									|en = 'Conventional chunk'; fa = 'Conventional chunk';
									|it = 'Fetta convenzionale';
									|pl = 'Kawałek umowny';
									|tr = 'Koşullu parça'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'mảnh quy ước';
											|ru = 'усл. кус';
											|en = 'convl. chunks'; fa = 'convl. chunks';
											|it = 'fetta conv.';
											|pl = 'kaw. war';
											|tr = 'koşullu. parça'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'MẢNH QUY ƯỚC';
															|ru = 'УСЛ КУС';
															|en = 'CONVL CHUNKS'; fa = 'CONVL CHUNKS';
															|it = 'FETTA CONV.';
															|pl = 'KAW WAR';
															|tr = 'KOŞULLU PARÇA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "885";
		Level3.Description = NStr("vi = 'Nghìn mảnh quy ước';
									|ru = 'Тысяча условных кусков';
									|en = 'Thousand conventional chunks'; fa = 'Thousand conventional chunks';
									|it = 'Mille fette convenzionali';
									|pl = 'Tysiąc kawałków umownych';
									|tr = 'Bin koşullu parça'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 mảnh quy ước';
											|ru = '1000 усл. кус';
											|en = '1,000 convl. chunks'; fa = '1,000 convl. chunks';
											|it = '1000 fette conv.';
											|pl = '1000 kaw. war';
											|tr = '1000 koşullu. parça'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn mảnh quy ước';
															|ru = 'ТЫС УСЛ КУС';
															|en = 'THOUS CONVL CHUNKS'; fa = 'THOUS CONVL CHUNKS';
															|it = 'MILLE FETTE CONV.';
															|pl = 'TYS KAW WAR';
															|tr = 'BİN KOŞULLU PARÇA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "886";
		Level3.Description = NStr("vi = 'Triệu mảnh quy ước';
									|ru = 'Миллион условных кусков';
									|en = 'Million conventional chunks'; fa = 'Million conventional chunks';
									|it = 'Un milione di fette convenzionali';
									|pl = 'Milion kawałków umownych';
									|tr = 'Milyon koşullu parça'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 mảnh quy ước';
											|ru = '10^6 усл. кус';
											|en = '10^6 convl. chunks'; fa = '10^6 convl. chunks';
											|it = '10^6 di fette conv.';
											|pl = '10^6 kaw. war';
											|tr = '10^6 koşullu. parça'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu mảnh quy ước';
															|ru = 'МЛН УСЛ КУС';
															|en = 'MIL CONVL CHUNKS'; fa = 'MIL CONVL CHUNKS';
															|it = 'MLN DI FETTE CONV.';
															|pl = 'MLN KAW WAR';
															|tr = 'MİLYON KOŞULLU PARÇA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "887";
		Level3.Description = NStr("vi = 'Hòm quy ước';
									|ru = 'Условный ящик';
									|en = 'Unit case'; fa = 'Unit case';
									|it = 'Cassa convenzionale';
									|pl = 'Skrzynia umowna';
									|tr = 'Koşullu kutu'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'hòm quy ước';
											|ru = 'усл. ящ';
											|en = 'unit cases'; fa = 'unit cases';
											|it = 'cassa conv.';
											|pl = 'skrz. war';
											|tr = 'koşullu. kutu'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'HÒM QUY ƯỚC';
															|ru = 'УСЛ ЯЩ';
															|en = 'UNIT CASE S'; fa = 'UNIT CASE S';
															|it = 'CASSA CONV.';
															|pl = 'SKRZ WAR';
															|tr = 'KOŞULLU KUTU'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "888";
		Level3.Description = NStr("vi = 'Nghìn hòm quy ước';
									|ru = 'Тысяча условных ящиков';
									|en = 'Thousand unit cases'; fa = 'Thousand unit cases';
									|it = 'Mille casse convenzionali';
									|pl = 'Tysiąc skrzyń umownych';
									|tr = 'Bin koşullu kutu'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 hòm quy ước';
											|ru = '1000 усл. ящ';
											|en = '1,000 unit cases'; fa = '1,000 unit cases';
											|it = '1000 casse conv.';
											|pl = '1000 skrz. war';
											|tr = '1000 koşullu. kutu'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN HÒM QUY ƯỚC';
															|ru = 'ТЫС УСЛ ЯЩ';
															|en = 'THOUS UNIT CASES'; fa = 'THOUS UNIT CASES';
															|it = 'MILLE CASSE CONV.';
															|pl = 'TYS SKSZ WAR';
															|tr = 'BİN KOŞULLU KUTU'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "889";
		Level3.Description = NStr("vi = 'Cuộn dây quy ước';
									|ru = 'Условная катушка';
									|en = 'Conventional coil'; fa = 'Conventional coil';
									|it = 'Rocchetto convenzionale';
									|pl = 'Szpula umowna';
									|tr = 'Koşullu bobin'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'cuộn dây quy ước';
											|ru = 'усл. кат';
											|en = 'convl. coils'; fa = 'convl. coils';
											|it = 'rocc. conv.';
											|pl = 'szp. war';
											|tr = 'koşullu. bobin'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'CUỘN DÂY QUY ƯỚC';
															|ru = 'УСЛ КАТ';
															|en = 'CONVL COILS'; fa = 'CONVL COILS';
															|it = 'ROCC. CONV.';
															|pl = 'SZP WAR';
															|tr = 'KOŞULLU BOBİN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "890";
		Level3.Description = NStr("vi = 'Nghìn cuộn dây quy ước';
									|ru = 'Тысяча условных катушек';
									|en = 'Thousand conventional coils'; fa = 'Thousand conventional coils';
									|it = 'Mille rocchetti convenzionali';
									|pl = 'Tysiąc szpul umownych';
									|tr = 'Bin koşullu bobin'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 cuộn dây quy ước';
											|ru = '1000 усл. кат';
											|en = '1,000 convl. coils'; fa = '1,000 convl. coils';
											|it = '1000 rocc. conv.';
											|pl = '1000 szp. war';
											|tr = '1000 koşullu. bobin'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN CUỘN DÂY QUY ƯỚC';
															|ru = 'ТЫС УСЛ КАТ';
															|en = 'THOUS CONVL COILS'; fa = 'THOUS CONVL COILS';
															|it = 'MILLE ROCC. CONV.';
															|pl = 'TYS SZP WAR';
															|tr = 'BİN KOŞULLU BOBİN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "891";
		Level3.Description = NStr("vi = 'Tấm lát quy ước';
									|ru = 'Условная плитка';
									|en = 'Conventional tile'; fa = 'Conventional tile';
									|it = 'Mattonella convenzionale';
									|pl = 'Płytka umowna';
									|tr = 'Koşullu levha'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'tấm lát quy ước';
											|ru = 'усл. плит';
											|en = 'convl. tiles'; fa = 'convl. tiles';
											|it = 'mattonella conv.';
											|pl = 'płyt. war';
											|tr = 'koşullu. levha'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TẤM LÁT QUY ƯỚC';
															|ru = 'УСЛ ПЛИТ';
															|en = 'CONVL TILES'; fa = 'CONVL TILES';
															|it = 'MATTOINELLA CONV.';
															|pl = 'PŁYT WAR';
															|tr = 'KOŞULLU LEVHA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "892";
		Level3.Description = NStr("vi = 'Nghìn tấm lát quy ước';
									|ru = 'Тысяча условных плиток';
									|en = 'Thousand conventional tiles'; fa = 'Thousand conventional tiles';
									|it = 'Mille mattonelle convenzionali';
									|pl = 'Tysiąc płytek umownych';
									|tr = 'Bin koşullu levha'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 tấm lát quy ước';
											|ru = '1000 усл. плит';
											|en = '1,000 convl. tiles'; fa = '1,000 convl. tiles';
											|it = '1000 mattonelle conv.';
											|pl = '1000 płytek umownych';
											|tr = '1000 koşullu. levha'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN TẤM LÁT QUY ƯỚC';
															|ru = 'ТЫС УСЛ ПЛИТ';
															|en = 'THOUS CONVL TILES'; fa = 'THOUS CONVL TILES';
															|it = 'MILLE MATTONELLE CONV.';
															|pl = 'TYS PŁYT WAR';
															|tr = 'BİN KOŞULLU LEVHA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "893";
		Level3.Description = NStr("vi = 'Viên gạch quy ước';
									|ru = 'Условный кирпич';
									|en = 'Conventional brick'; fa = 'Conventional brick';
									|it = 'Mattone convenzionale';
									|pl = 'Cegła umowna';
									|tr = 'Koşullu tuğla'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'viên gạch quy ước';
											|ru = 'усл. кирп';
											|en = 'convl. brk'; fa = 'convl. brk';
											|it = 'matt. conv.';
											|pl = 'cegł. war';
											|tr = 'koşullu. tuğla'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'VIÊN GẠCH QUY ƯỚC';
															|ru = 'УСЛ КИРП';
															|en = 'CONVL BRK'; fa = 'CONVL BRK';
															|it = 'MATT. CONV.';
															|pl = 'CEGŁ WAR';
															|tr = 'KOŞULLU TUĞLA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "894";
		Level3.Description = NStr("vi = 'Nghìn viên gạch quy ước';
									|ru = 'Тысяча условных кирпичей';
									|en = 'Thousand conventional bricks'; fa = 'Thousand conventional bricks';
									|it = 'Mille mattoni convenzionali';
									|pl = 'Tysiąc cegieł umownych';
									|tr = 'Bin koşullu tuğla'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 viên gạch quy ước';
											|ru = '1000 усл. кирп';
											|en = '1,000 convl. brk'; fa = '1,000 convl. brk';
											|it = '1000 matt. conv.';
											|pl = '1000 ceg. war';
											|tr = '1000 koşullu. tuğla'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn viên gạch quy ước';
															|ru = 'ТЫС УСЛ КИРП';
															|en = 'THOUS CONVL BRK'; fa = 'THOUS CONVL BRK';
															|it = 'MILLE MATT. CONV.';
															|pl = 'TYS CEG WAR';
															|tr = 'BİN KOŞULLU TUĞLA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "895";
		Level3.Description = NStr("vi = 'Triệu viên gạch quy ước';
									|ru = 'Миллион условных кирпичей';
									|en = 'Million conventional bricks'; fa = 'Million conventional bricks';
									|it = 'Un milione di mattoni convenzionali';
									|pl = 'Milion cegieł umownych';
									|tr = 'Milyon koşullu tuğla'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 viên gạch quy ước';
											|ru = '10^6 усл. кирп';
											|en = '10^6 convl. brk'; fa = '10^6 convl. brk';
											|it = '10^6 matt. conv.';
											|pl = '10^6 ceg. war';
											|tr = '10^6 koşullu. tuğla'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu viên gạch quy ước';
															|ru = 'МЛН УСЛ КИРП';
															|en = 'MIL CONVL BRK'; fa = 'MIL CONVL BRK';
															|it = 'MLN MATT. CONV.';
															|pl = 'MLN CEG WAR';
															|tr = 'MİLYON KOŞULLU TUĞLA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "896";
		Level3.Description = NStr("vi = 'Gia đình';
									|ru = 'Семья';
									|en = 'Family'; fa = 'Family';
									|it = 'Famiglia';
									|pl = 'Family';
									|tr = 'Aile'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Gia đình';
											|ru = 'семей';
											|en = 'FAMILIES'; fa = 'FAMILIES';
											|it = 'Famiglie';
											|pl = 'FAMILIES';
											|tr = 'AİLE'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Gia đình';
															|ru = 'СЕМЕЙ';
															|en = 'FAMILIES'; fa = 'FAMILIES';
															|it = 'Famiglie';
															|pl = 'FAMILIES';
															|tr = 'AİLE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "897";
		Level3.Description = NStr("vi = 'Nghìn gia đình';
									|ru = 'Тысяча семей';
									|en = 'Thousand families'; fa = 'Thousand families';
									|it = 'Mille famiglie';
									|pl = 'Tysiąc rodzin';
									|tr = 'Bin aile'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 gia đình';
											|ru = '1000 семей';
											|en = '1,000 families'; fa = '1,000 families';
											|it = '1000 famiglie';
											|pl = '1000 rodzin';
											|tr = '1000 aile'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn gia đình';
															|ru = 'ТЫС СЕМЕЙ';
															|en = 'THOUS FAMILIES'; fa = 'THOUS FAMILIES';
															|it = 'MILLE FAMIGLIE';
															|pl = 'TYS RODZIN';
															|tr = 'BİN AİLE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "898";
		Level3.Description = NStr("vi = 'Triệu gia đình';
									|ru = 'Миллион семей';
									|en = 'Million families'; fa = 'Million families';
									|it = 'Un milione di famiglie';
									|pl = 'Milion rodzin';
									|tr = 'Milyon aile'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 gia đình';
											|ru = '10^6 семей';
											|en = '10^6 families'; fa = '10^6 families';
											|it = '10^6 famiglie';
											|pl = '10^6 rodzin';
											|tr = '10^6 aile'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU GIA ĐÌNH';
															|ru = 'МЛН СЕМЕЙ';
															|en = 'MIL FAMILIES'; fa = 'MIL FAMILIES';
															|it = 'MLN DI FAMIGLIE';
															|pl = 'MLN RODZIN';
															|tr = 'MİLYON AİLE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "899";
		Level3.Description = NStr("vi = 'Hộ gia đình';
									|ru = 'Домохозяйство';
									|en = 'Household'; fa = 'Household';
									|it = 'Nucleo familiare';
									|pl = 'Household';
									|tr = 'Hane halkı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'hộ gia đình';
											|ru = 'домхоз';
											|en = 'hh'; fa = 'hh';
											|it = 'домхоз';
											|pl = 'hh';
											|tr = 'hane halkı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'hộ gia đình';
															|ru = 'ДОМХОЗ';
															|en = 'hh'; fa = 'hh';
															|it = 'ДОМХОЗ';
															|pl = 'hh';
															|tr = 'hane halkı'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "900";
		Level3.Description = NStr("vi = 'Nghìn hộ gia đình';
									|ru = 'Тысяча домохозяйств';
									|en = 'Thousand households'; fa = 'Thousand households';
									|it = 'Mille nuclei familiari';
									|pl = 'Tysiąc gospodarstw domowych';
									|tr = 'Binlerce hane halkı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 hộ gia đình';
											|ru = '1000 домхоз';
											|en = '1,000 hh'; fa = '1,000 hh';
											|it = '1000 nuclei familiari';
											|pl = '1000 gosp. dom';
											|tr = '1000 hane halkı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN HỘ GIA ĐÌNH';
															|ru = 'ТЫС ДОМХОЗ';
															|en = 'THOUS HH'; fa = 'THOUS HH';
															|it = 'MILLE NUCLEI FAMILIARI';
															|pl = 'TYS DOM GOSP';
															|tr = 'BİNLERCE HANE HALKI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "901";
		Level3.Description = NStr("vi = 'Triệu hộ gia đình';
									|ru = 'Миллион домохозяйств';
									|en = 'Million households'; fa = 'Million households';
									|it = 'Un milione di nuclei familiari';
									|pl = 'Milion gospodarstw domowych';
									|tr = 'Milyon hane halkı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 hộ gia đình';
											|ru = '10^6 домхоз';
											|en = '10^6 hh'; fa = '10^6 hh';
											|it = '10^6 di nuclei familiari';
											|pl = '10^6 gosp. dom';
											|tr = '10^6 hane halkı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu hộ gia đình';
															|ru = 'МЛН ДОМХОЗ';
															|en = 'MIL HH'; fa = 'MIL HH';
															|it = 'MLN DI NUCLEI FAMILIARI';
															|pl = 'MLN GOSP. DOM';
															|tr = 'MİLYON HANE HALKI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "902";
		Level3.Description = NStr("vi = 'Chỗ học tập';
									|ru = 'Ученическое место';
									|en = 'Student place'; fa = 'Student place';
									|it = 'Posto studente';
									|pl = 'Miejsce ucznia';
									|tr = 'Öğrenci yeri'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'chỗ học tập';
											|ru = 'учен. мест';
											|en = 's. pl'; fa = 's. pl';
											|it = 'posto studente';
											|pl = 'miej. ucz';
											|tr = 'öğrenci. yeri'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'CHỖ HỌC TẬP';
															|ru = 'УЧЕН МЕСТ';
															|en = 'S PL'; fa = 'S PL';
															|it = 'POSTO STUDENTE';
															|pl = 'MIEJ UCZN';
															|tr = 'ÖĞRENCİ YERİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "903";
		Level3.Description = NStr("vi = 'Nghìn chỗ học tập';
									|ru = 'Тысяча ученических мест';
									|en = 'Thousand student places'; fa = 'Thousand student places';
									|it = 'Mille posti studente';
									|pl = 'Tysiąc miejsc uczniów';
									|tr = 'Bin öğrenci yeri'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 chỗ học tập';
											|ru = '1000 учен. мест';
											|en = '1,000 s. pl'; fa = '1,000 s. pl';
											|it = '1000 posti studente';
											|pl = '1000 miej. uczn';
											|tr = '1000 öğrenci yeri'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN CHỖ HỌC TẬP';
															|ru = 'ТЫС УЧЕН МЕСТ';
															|en = 'THOUS S PL'; fa = 'THOUS S PL';
															|it = 'MILLE POSTI STUDENTE';
															|pl = 'TYSIĄC MIEJSC UCZN';
															|tr = 'BİN ÖĞRENCİ YERİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "904";
		Level3.Description = NStr("vi = 'Chỗ làm việc';
									|ru = 'Рабочее место';
									|en = 'Workplace'; fa = 'میز کار';
									|it = 'Posto di lavoro';
									|pl = 'Miejsce pracy';
									|tr = 'Çalışma alanı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'chỗ làm việc';
											|ru = 'раб. мест';
											|en = 'wplc'; fa = 'wplc';
											|it = 'posto di lavoro';
											|pl = 'miejsc rob';
											|tr = 'iş. yeri'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Chỗ làm việc';
															|ru = 'РАБ МЕСТ';
															|en = 'WPLC S'; fa = 'WPLC S';
															|it = 'POSTO DI LAVORO';
															|pl = 'MIEJSC ROB';
															|tr = 'İŞ YERİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "905";
		Level3.Description = NStr("vi = 'Nghìn chỗ làm việc';
									|ru = 'Тысяча рабочих мест';
									|en = 'Thousand workplaces'; fa = 'Thousand workplaces';
									|it = 'Mille posti di lavoro';
									|pl = 'Tysiąc miejsc roboczych';
									|tr = 'Binlerce çalışma alanı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 chỗ làm việc';
											|ru = '1000 раб. мест';
											|en = '1,000 wplc'; fa = '1,000 wplc';
											|it = '1000 posti di lavoro';
											|pl = '1000 miejsc rob.';
											|tr = '1000 iş. yeri'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn chỗ làm việc';
															|ru = 'ТЫС РАБ МЕСТ';
															|en = 'THOUS WPLC'; fa = 'THOUS WPLC';
															|it = 'MILLE POSTI DI LAVORO';
															|pl = 'TYS MIEJSC ROBOCZYCH';
															|tr = 'BİNLERCE İŞ YERİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "906";
		Level3.Description = NStr("vi = 'Chỗ ngồi';
									|ru = 'Посадочное место';
									|en = 'Seat psg'; fa = 'Seat psg';
									|it = 'Posto a sedere';
									|pl = 'Miejsce siedzące';
									|tr = 'İniş yeri'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'chỗ ngồi';
											|ru = 'посад. мест';
											|en = 'seats'; fa = 'seats';
											|it = 'posto a sedere';
											|pl = 'miejsc siedzących';
											|tr = 'iniş. yeri'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Chỗ ngồi';
															|ru = 'ПОСАД МЕСТ';
															|en = 'SEAT'; fa = 'SEAT';
															|it = 'POSTO A SEDERE';
															|pl = 'MIEJSC SIEDZĄCYCH';
															|tr = 'İNİŞ YERİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "907";
		Level3.Description = NStr("vi = 'Nghìn Chỗ ngồi';
									|ru = 'Тысяча посадочных мест';
									|en = 'Thousand seats psg'; fa = 'Thousand seats psg';
									|it = 'Mille posti a sedere';
									|pl = 'Tysiąc miejsc siedzących';
									|tr = 'Binlerce iniş yeri'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 chỗ ngồi';
											|ru = '1000 посад. мест';
											|en = '1,000 st'; fa = '1,000 st';
											|it = '1000 posti a sedere';
											|pl = '1000 miejsc siedzących';
											|tr = '1000 iniş. yeri'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn chỗ ngồi';
															|ru = 'ТЫС ПОСАД МЕСТ';
															|en = 'THOUS SEATS psg'; fa = 'THOUS SEATS psg';
															|it = 'MILLE POSTI A SEDERE';
															|pl = 'TYS MIEJSC SIEDZĄCYCH';
															|tr = 'BİNLERCE İNİŞ YERİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "908";
		Level3.Description = NStr("vi = 'Số';
									|ru = 'Номер';
									|en = 'Room'; fa = 'Room';
									|it = 'Numero';
									|pl = 'Room';
									|tr = 'Numara'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'SỐ';
											|ru = 'ном';
											|en = 'ROOM S'; fa = 'ROOM S';
											|it = 'ном';
											|pl = 'ROOM S';
											|tr = 'NUMARA'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'SỐ';
															|ru = 'НОМ';
															|en = 'ROOM S'; fa = 'ROOM S';
															|it = 'НОМ';
															|pl = 'ROOM S';
															|tr = 'NUMARA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "909";
		Level3.Description = NStr("vi = 'Căn hộ';
									|ru = 'Квартира';
									|en = 'Apartment'; fa = 'Apartment';
									|it = 'Appartamento';
									|pl = 'Apartment';
									|tr = 'Daire'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'CĂN HỘ';
											|ru = 'кварт';
											|en = 'apt'; fa = 'apt';
											|it = 'кварт';
											|pl = 'apt';
											|tr = 'кварт'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'CĂN HỘ';
															|ru = 'КВАРТ';
															|en = 'QUART'; fa = 'QUART';
															|it = 'КВАРТ';
															|pl = 'QUART';
															|tr = 'КВАРТ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "910";
		Level3.Description = NStr("vi = 'Nghìn căn hộ';
									|ru = 'Тысяча квартир';
									|en = 'Thousand apartments'; fa = 'Thousand apartments';
									|it = 'Mille appartamenti';
									|pl = 'Tysiąc mieszkań';
									|tr = 'Bin daire'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 căn hộ';
											|ru = '1000 кварт';
											|en = '1,000 apt'; fa = '1,000 apt';
											|it = '1000 apt';
											|pl = '1000 miesz';
											|tr = '1000 daire'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN CĂN HỘ';
															|ru = 'ТЫС КВАРТ';
															|en = 'THOUS APT'; fa = 'THOUS APT';
															|it = 'MILLE APT';
															|pl = 'TYS MIES';
															|tr = 'BİN DAİRE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "911";
		Level3.Description = NStr("vi = 'Giường';
									|ru = 'Койка';
									|en = 'Bed'; fa = 'Bed';
									|it = 'Posto letto';
									|pl = 'Bed';
									|tr = 'Yatak'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'GIƯỜNG';
											|ru = 'коек';
											|en = 'BEDS'; fa = 'BEDS';
											|it = 'коек';
											|pl = 'BEDS';
											|tr = 'YATAK'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'GIƯỜNG';
															|ru = 'КОЕК';
															|en = 'BEDS'; fa = 'BEDS';
															|it = 'КОЕК';
															|pl = 'BEDS';
															|tr = 'YATAK'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "912";
		Level3.Description = NStr("vi = 'Nghìn giường';
									|ru = 'Тысяча коек';
									|en = 'Thousand beds'; fa = 'Thousand beds';
									|it = 'Mille posti letto';
									|pl = 'Tysiąc łóżek szpitalnych';
									|tr = 'Bin yatak'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 giường';
											|ru = '1000 коек';
											|en = '1,000 beds'; fa = '1,000 beds';
											|it = '1000 posti letto';
											|pl = '1000 łóżek szpitalnych';
											|tr = '1000 yatak'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN GIƯỜNG';
															|ru = 'ТЫС КОЕК';
															|en = 'THOUS BEDS'; fa = 'THOUS BEDS';
															|it = 'MILLE POSTI LETTO';
															|pl = 'TYS ŁÓŻEK SZPITALNYCH';
															|tr = 'BİN YATAK'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "913";
		Level3.Description = NStr("vi = 'Quyển quỹ sách';
									|ru = 'Том книжного фонда';
									|en = 'Books fund volume'; fa = 'Books fund volume';
									|it = 'Volume del fondo librario';
									|pl = 'Wolumin funduszu księgowego';
									|tr = 'Kitap fonu hacmi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'quyển quỹ sách';
											|ru = 'том книжн. фонд';
											|en = 'book fund vlm'; fa = 'book fund vlm';
											|it = 'volume del fondo librario';
											|pl = 'wolumin funduszu księgowego';
											|tr = 'kitap fonu hacmi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'QUYỂN QUỸ SÁCH';
															|ru = 'ТОМ КНИЖН ФОНД';
															|en = 'BOOK FUND VOLUME'; fa = 'BOOK FUND VOLUME';
															|it = 'VOLUME DEL FONDO LIBRARIO';
															|pl = 'WOLUMIN FUNDUSZU KSIĘGOWEGO';
															|tr = 'KİTAP FONU HACMİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "914";
		Level3.Description = NStr("vi = 'Nghìn quyển quỹ sách';
									|ru = 'Тысяча томов книжного фонда';
									|en = 'Thousand book fund volumes'; fa = 'Thousand book fund volumes';
									|it = 'Mille volumi del fondo librario';
									|pl = 'Tysiąc woluminów funduszu księgowego';
									|tr = 'Binlerce kitap fonu hacmi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '1000 quyển quỹ sách';
											|ru = '1000 том. книжн. фонд';
											|en = '1,000 book fund volumes'; fa = '1,000 book fund volumes';
											|it = '1000 volumi del fondo librario';
											|pl = '1000 woluminów funduszu księgowego';
											|tr = '1000 kitap fonu. hacmı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN QUYỂN QUỸ SÁCH';
															|ru = 'ТЫС ТОМ КНИЖН ФОНД';
															|en = 'THOUS BOOK FUND VOLUMES'; fa = 'THOUS BOOK FUND VOLUMES';
															|it = 'MILLE VOLUMI DI FONDO LIBRARIO';
															|pl = 'TYS WOL FUNDUSZU KSIĘGOWEGO';
															|tr = 'BİNLERCE KİTAP FONU HACMİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "915";
		Level3.Description = NStr("vi = 'Sửa chữa quy ước';
									|ru = 'Условный ремонт';
									|en = 'Conventional repair'; fa = 'Conventional repair';
									|it = 'Riparazione convenzionale';
									|pl = 'Remont umowny';
									|tr = 'Koşullu onarım'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'lần sửa chữa quy ước';
											|ru = 'усл. рем';
											|en = 'convl. repair'; fa = 'convl. repair';
											|it = 'riparazione conv.';
											|pl = 'rem. war';
											|tr = 'koşullu. onarım'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'LẦN SỬA CHỮA QUY ƯỚC';
															|ru = 'УСЛ РЕМ';
															|en = 'CONVL REPAIR'; fa = 'CONVL REPAIR';
															|it = 'RIPARAZIONE CONV.';
															|pl = 'REM WAR';
															|tr = 'KOŞULLU ONARIM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "916";
		Level3.Description = NStr("vi = 'Lần sửa chữa quy ước trong năm';
									|ru = 'Условный ремонт в год';
									|en = 'Conventional repair per year'; fa = 'Conventional repair per year';
									|it = 'Riparazione convenzionale all''anno';
									|pl = 'Remont umowny rocznie';
									|tr = 'Yıllık koşullu onarım'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'lần sửa chữa quy ước/năm';
											|ru = 'усл. рем/год';
											|en = 'convl. repair/year'; fa = 'convl. repair/year';
											|it = 'riparazione conv/anno';
											|pl = 'rem. war/rocznie';
											|tr = 'koşullu. onarım/yıl'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'LẦN SỬA CHỮA CÓ ĐIỀU KIỆN/NĂM';
															|ru = 'УСЛ РЕМ/ГОД';
															|en = 'CONVL REPAIR/YEAR'; fa = 'CONVL REPAIR/YEAR';
															|it = 'RIPARAZIONE CONV/ANNO';
															|pl = 'REM WAR/ROCZNIE';
															|tr = 'KOŞULLU ONARIM/YIL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "917";
		Level3.Description = NStr("vi = 'Ca làm việc';
									|ru = 'Смена';
									|en = 'Shift'; fa = 'شیفت';
									|it = 'Turno';
									|pl = 'Shift';
									|tr = 'Vardiya'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Ca';
											|ru = 'смен';
											|en = 'SHIFTS'; fa = 'SHIFTS';
											|it = 'смен';
											|pl = 'SHIFTS';
											|tr = 'VARDİYA'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Ca';
															|ru = 'СМЕН';
															|en = 'SHIFTS'; fa = 'SHIFTS';
															|it = 'СМЕН';
															|pl = 'SHIFTS';
															|tr = 'VARDİYA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "918";
		Level3.Description = NStr("vi = 'Tờ bản quyền';
									|ru = 'Лист авторский';
									|en = 'Author''s sheet'; fa = 'Author''s sheet';
									|it = 'Foglio d''autore';
									|pl = 'Arkusz autorski';
									|tr = 'Yazar yaprağı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'tờ bản quyền';
											|ru = 'л. авт';
											|en = 'author''s sheets'; fa = 'author''s sheets';
											|it = 'foglio d''autore';
											|pl = 'ark. aut';
											|tr = 'l. yazar'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TỜ BẢN QUYỀN';
															|ru = 'ЛИСТ АВТ';
															|en = 'AUTHOR''S SHEET S'; fa = 'AUTHOR''S SHEET S';
															|it = 'FOGLIO D''AUTORE';
															|pl = 'ARK AUT';
															|tr = 'YAZAR YAPRAĞI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "920";
		Level3.Description = NStr("vi = 'Tờ in';
									|ru = 'Лист печатный';
									|en = 'Printer''s sheet'; fa = 'Printer''s sheet';
									|it = 'Foglio di stampa tipografica';
									|pl = 'Arkusz drukarski';
									|tr = 'Yazdırma yaprağı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'tờ in';
											|ru = 'л. печ';
											|en = 'printer''s sheets'; fa = 'printer''s sheets';
											|it = 'foglio di stampa tipografica';
											|pl = 'ark. druk';
											|tr = 'l. yazdırma'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TỜ IN';
															|ru = 'ЛИСТ ПЕЧ';
															|en = 'PRINTER''S SHEET S'; fa = 'PRINTER''S SHEET S';
															|it = 'FOGLIO DI STAMPA TIPOGRAFICA';
															|pl = 'ARK DRUK';
															|tr = 'YAZDIRMA YAPRAĞI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "921";
		Level3.Description = NStr("vi = 'Tờ kế toán xuất bản';
									|ru = 'Лист учетно - издательский';
									|en = 'Publisher''s sheet'; fa = 'Publisher''s sheet';
									|it = 'Foglio contabile-editoriale';
									|pl = 'Arkusz ewidencyjno-wydawniczy';
									|tr = 'Muhasebe - yayın yaprağı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'tờ kế toán xuất bản';
											|ru = 'л. уч.-изд';
											|en = 'publisher''s sheets'; fa = 'publisher''s sheets';
											|it = 'foglio contabile editoriale';
											|pl = 'A. EW-WYD';
											|tr = 'l. muhasebe - yayın'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TỜ KẾ TOÁN XUẤT BẢN';
															|ru = 'ЛИСТ УЧ.ИЗД';
															|en = 'PUBLISHER''S SHEET S'; fa = 'PUBLISHER''S SHEET S';
															|it = 'FOGLIO CONTABILE EDITORIALE';
															|pl = 'ARK EW-WYD';
															|tr = 'MUHASEBE YAYIN YAPRAĞI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "922";
		Level3.Description = NStr("vi = 'DẤU';
									|ru = 'Знак';
									|en = 'Digit'; fa = 'رقم';
									|it = 'Знак';
									|pl = 'Digit';
									|tr = 'Karakter'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'DẤU';
											|ru = 'знак';
											|en = 'Digit'; fa = 'رقم';
											|it = 'знак';
											|pl = 'Digit';
											|tr = 'Karakter'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'DẤU';
															|ru = 'ЗНАК';
															|en = 'Digit'; fa = 'رقم';
															|it = 'ЗНАК';
															|pl = 'Digit';
															|tr = 'Karakter'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "923";
		Level3.Description = NStr("vi = 'Từ';
									|ru = 'Слово';
									|en = 'Word'; fa = 'Word';
									|it = 'Слово';
									|pl = 'Word';
									|tr = 'Слово'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Từ';
											|ru = 'слово';
											|en = 'word'; fa = 'word';
											|it = 'слово';
											|pl = 'word';
											|tr = 'слово'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Từ';
															|ru = 'СЛОВО';
															|en = 'WORD'; fa = 'WORD';
															|it = 'СЛОВО';
															|pl = 'WORD';
															|tr = 'СЛОВО'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "924";
		Level3.Description = NStr("vi = 'Ký hiệu';
									|ru = 'Символ';
									|en = 'Character'; fa = 'Character';
									|it = 'Символ';
									|pl = 'Character';
									|tr = 'Символ'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Ký hiệu';
											|ru = 'символ';
											|en = 'character'; fa = 'character';
											|it = 'символ';
											|pl = 'character';
											|tr = 'символ'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Ký hiệu';
															|ru = 'СИМВОЛ';
															|en = 'CHARACTER'; fa = 'CHARACTER';
															|it = 'СИМВОЛ';
															|pl = 'CHARACTER';
															|tr = 'СИМВОЛ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "925";
		Level3.Description = NStr("vi = 'Ống quy ước';
									|ru = 'Условная труба';
									|en = 'Conventional pipe'; fa = 'Conventional pipe';
									|it = 'Tubo convenzionale';
									|pl = 'Rura umowna';
									|tr = 'Koşullu boru'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'ống quy ước';
											|ru = 'усл. труб';
											|en = 'convl. pipes'; fa = 'convl. pipes';
											|it = 'tubo conv.';
											|pl = 'rura war';
											|tr = 'koşullu. boru'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ỐNG QUY ƯỚC';
															|ru = 'УСЛ ТРУБ';
															|en = 'CONVL PIPES'; fa = 'CONVL PIPES';
															|it = 'TUBO CONV.';
															|pl = 'RUR WAR';
															|tr = 'KOŞULLU BORU'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "930";
		Level3.Description = NStr("vi = 'Nghìn tấm';
									|ru = 'Тысяча пластин';
									|en = 'Thousand plates'; fa = 'Thousand plates';
									|it = 'Mille lamiere';
									|pl = 'Tysiąc plyt';
									|tr = 'Bin plaka'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 tấm';
											|ru = '10^3 пласт';
											|en = '10^3 plates'; fa = '10^3 plates';
											|it = '10^3 lamiere';
											|pl = '10^3 płyt';
											|tr = '10^3 plaka'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn tấm';
															|ru = 'ТЫС ПЛАСТ';
															|en = 'THOUS PLATES'; fa = 'THOUS PLATES';
															|it = 'MILLE LAMIERE';
															|pl = 'TYS PŁYT';
															|tr = 'BİN PLAKA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "937";
		Level3.Description = NStr("vi = 'Triệu liều';
									|ru = 'Миллион доз';
									|en = 'Million doses'; fa = 'Million doses';
									|it = 'Un milione di dosi';
									|pl = 'Milion doz';
									|tr = 'Milyon doz'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 liều';
											|ru = '10^6 доз';
											|en = '10^6 doses'; fa = '10^6 doses';
											|it = '10^6 di dosi';
											|pl = '10^6 doz';
											|tr = '10^6 doz'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu liều';
															|ru = 'МЛН ДОЗ';
															|en = 'MIL DOSES'; fa = 'MIL DOSES';
															|it = 'MLN DI DOSI';
															|pl = 'MLN DOZ';
															|tr = 'MİLYON DOZ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "949";
		Level3.Description = NStr("vi = 'Triệu tờ in';
									|ru = 'Миллион листов-оттисков';
									|en = 'Million printed sheets'; fa = 'Million printed sheets';
									|it = 'Un milione di fogli con impronta di stampa';
									|pl = 'Milion arkuszy odcisków';
									|tr = 'Milyon baskılı yaprak'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 tờ in';
											|ru = '10^6 лист.оттиск';
											|en = '10^6 printed sheets'; fa = '10^6 printed sheets';
											|it = '10^6 fogli con impronta di stampa';
											|pl = '10^6 arkuszy odcisków';
											|tr = '10^6 yaprak.baskı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu tờ in';
															|ru = 'МЛН ЛИСТ.ОТТИСК';
															|en = 'MIL PRINTED SHEETS'; fa = 'MIL PRINTED SHEETS';
															|it = 'MLN FOGLI CON IMPRONTA DI STAMPA';
															|pl = 'MLN ARKUSZY ODCISKÓW';
															|tr = 'MİLYON YAPRAK.BASKI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "950";
		Level3.Description = NStr("vi = 'Ngày đứng máy';
									|ru = 'Вагоно(машино)-день';
									|en = 'Freight(car)-day'; fa = 'Freight(car)-day';
									|it = 'Giorni treno(macchina)';
									|pl = 'Freight(car)-day';
									|tr = 'Tren (makine)-gün'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Ngày đứng máy';
											|ru = 'ваг (маш).дн';
											|en = 'FREIGHT (CAR) DAYS'; fa = 'FREIGHT (CAR) DAYS';
											|it = 'ваг (маш).дн';
											|pl = 'wag (masz).dz';
											|tr = 'TREN (MAKİNE).GÜN'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Ngày đứng máy';
															|ru = 'ВАГ (МАШ).ДН';
															|en = 'FREIGHT (CAR) DAYS'; fa = 'FREIGHT (CAR) DAYS';
															|it = 'ВАГ (МАШ).ДН';
															|pl = 'FREIGHT (CAR) DAYS';
															|tr = 'TREN (MAKİNE).GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "951";
		Level3.Description = NStr("vi = 'Nghìn giờ đứng máy';
									|ru = 'Тысяча вагоно-(машино)-часов';
									|en = 'Thousand freight-(car)-hours'; fa = 'Thousand freight-(car)-hours';
									|it = 'Mille ore treno(macchina)';
									|pl = 'Tysiąc wagono-(maszyno)-godzin';
									|tr = 'Bin tren-(makine)-saat'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 giờ đứng máy';
											|ru = '10^3 ваг (маш).ч';
											|en = '10^3 freight (car) h'; fa = '10^3 freight (car) h';
											|it = '10^3 h treno(macchina)';
											|pl = '10^3 wag (masz).h';
											|tr = '10^3 tren (makine). s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn giờ đứng máy';
															|ru = 'ТЫС ВАГ (МАШ).Ч';
															|en = 'THOUS FREIGHT (CAR) H'; fa = 'THOUS FREIGHT (CAR) H';
															|it = 'MILLE H TRENO(MACCHINA)';
															|pl = 'TYS WAG (MASZ).H';
															|tr = 'BİN TREN (MAKİNE).S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "952";
		Level3.Description = NStr("vi = 'Nghìn kilomet đứng máy';
									|ru = 'Тысяча вагоно-(машино)-километров';
									|en = 'Thousand freight-(car)-kilometers'; fa = 'Thousand freight-(car)-kilometers';
									|it = 'Mille kilometri treno(macchina)';
									|pl = 'Tysiąc wagono-(maszyno)-kilometrów';
									|tr = 'Bin tren-(makine)-kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 km đứng máy';
											|ru = '10^3 ваг (маш).км';
											|en = '10^3 freight (car) km'; fa = '10^3 freight (car) km';
											|it = '10^3 km treno(macchina)';
											|pl = '10^3 wag (masz).km';
											|tr = '10^3 tren (makine).km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN KILOMET ĐỨNG MÁY';
															|ru = 'ТЫС ВАГ (МАШ).КМ';
															|en = 'THOUS FREIGHT (CAR) KM'; fa = 'THOUS FREIGHT (CAR) KM';
															|it = 'MILLE KM TRENO(MACCHINA)';
															|pl = 'TYS WAG (MASZ).KM';
															|tr = 'BİN TREN (MAKİNE).KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "953";
		Level3.Description = NStr("vi = 'Nghìn kilomet địa điểm';
									|ru = 'Тысяча место-километров';
									|en = 'Thousand seat-kilometers'; fa = 'Thousand seat-kilometers';
									|it = 'Mille posti-kilometro';
									|pl = 'Tysiąc miejscokilometrów';
									|tr = 'Binlerce yer-kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 kilomet địa điểm';
											|ru = '10^3 мест.км';
											|en = '10^3 skm'; fa = '10^3 skm';
											|it = '10^3 posti-km';
											|pl = '10^3 miejsc. km';
											|tr = '10^3 yer.km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn KILOMET ĐỊA ĐIỂM';
															|ru = 'ТЫС МЕСТ.КМ';
															|en = 'THOUS SKM'; fa = 'THOUS SKM';
															|it = 'MILLE POSTI-KM';
															|pl = 'TYS MIEJSC KM';
															|tr = 'BİN YER.KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "954";
		Level3.Description = NStr("vi = 'Ngày trên tàu';
									|ru = 'Вагоно-сутки';
									|en = 'Wagon-day'; fa = 'Wagon-day';
									|it = 'Giorni-treno';
									|pl = 'Wagon-day';
									|tr = 'Tren-günler'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'ngày trên tàu';
											|ru = 'ваг.сут';
											|en = 'wagon days'; fa = 'wagon days';
											|it = 'giorni-treno';
											|pl = 'wagon days';
											|tr = 'tren.gün'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'ngày trên tàu';
															|ru = 'ВАГ.СУТ';
															|en = 'wagon days'; fa = 'wagon days';
															|it = 'giorni-treno';
															|pl = 'wagon days';
															|tr = 'tren.gün'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "955";
		Level3.Description = NStr("vi = 'Nghìn giờ trên tàu';
									|ru = 'Тысяча поездо-часов';
									|en = 'Thousand train-hours'; fa = 'Thousand train-hours';
									|it = 'Mille ore-treno';
									|pl = 'Tysiąc pociągogodzin';
									|tr = 'Binlerce tren-saat'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 giờ trên tàu';
											|ru = '10^3 поезд.ч';
											|en = '10^3 train h'; fa = '10^3 train h';
											|it = '10^3 h-treno';
											|pl = '10^3 pociągogodz';
											|tr = '10^3 tren.s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN GIỜ TRÊN TẦU';
															|ru = 'ТЫС ПОЕЗД.Ч';
															|en = 'THOUS TRAIN H'; fa = 'THOUS TRAIN H';
															|it = 'MILLE H TRENO';
															|pl = 'TYS POCIĄGOGODZ';
															|tr = 'BİN TREN.S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "956";
		Level3.Description = NStr("vi = 'Nghìn kilomet trên tàu';
									|ru = 'Тысяча поездо-километров';
									|en = 'Thousand train-kilometers'; fa = 'Thousand train-kilometers';
									|it = 'Mille kilometri-treno';
									|pl = 'Tysiąc pociągokilometrów';
									|tr = 'Bin tren-kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 km trên tàu';
											|ru = '10^3 поезд.км';
											|en = '10^3 train km'; fa = '10^3 train km';
											|it = '10^3 km treno';
											|pl = '10^3 pociągogodz';
											|tr = '10^3 tren.km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN KM TRÊN TẦU';
															|ru = 'ТЫС ПОЕЗД.КМ';
															|en = 'THOUS TRAIN KM'; fa = 'THOUS TRAIN KM';
															|it = 'MILLE KM TRENO';
															|pl = 'TYS POCIĄGOKM';
															|tr = 'BİN TREN.KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "957";
		Level3.Description = NStr("vi = 'Nghìn tấn-dặm';
									|ru = 'Тысяча тонно-миль';
									|en = 'Thousand ton-miles'; fa = 'Thousand ton-miles';
									|it = 'Mille tonnellate-miglia';
									|pl = 'Tysiąc tonomil';
									|tr = 'Bin ton-mil'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 t dặm';
											|ru = '10^3 т.миль';
											|en = '10^3 tm'; fa = '10^3 tm';
											|it = '10^3 t miglia';
											|pl = '10^3 t. mil';
											|tr = '10^3 t.mil'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN T DẶM';
															|ru = 'ТЫС Т.МИЛЬ';
															|en = 'THOUS TM'; fa = 'THOUS TM';
															|it = 'MILLE T MIGLIA';
															|pl = 'TYS T.MIL';
															|tr = 'BİN T.MİL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "958";
		Level3.Description = NStr("vi = 'Nghìn dặm chở khách';
									|ru = 'Тысяча пассажиро-миль';
									|en = 'Thousand passenger-miles'; fa = 'Thousand passenger-miles';
									|it = 'Mille passeggeri-miglia';
									|pl = 'Tysiąc pasażeromil';
									|tr = 'Bin yolcu-mil'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 dặm chở khách';
											|ru = '10^3 пасс.миль';
											|en = '10^3 pmi'; fa = '10^3 pmi';
											|it = '10^3 pass-miglia';
											|pl = '10^3 pasażeromil';
											|tr = '10^3 yolcu.mil'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN DẶM CHỞ KHÁCH';
															|ru = 'ТЫС ПАСС.МИЛЬ';
															|en = 'THOUS PMI'; fa = 'THOUS PMI';
															|it = 'MILLE PASS-MIGLIA';
															|pl = 'TYS PASS. MIL';
															|tr = 'BİN YOLCU.MİL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "959";
		Level3.Description = NStr("vi = 'Ngày xe';
									|ru = 'Автомобиле-день';
									|en = 'Automobile-day'; fa = 'Automobile-day';
									|it = 'Giorni-automobile';
									|pl = 'Automobile-day';
									|tr = 'Otomobil-gün'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Ngày xe';
											|ru = 'автомоб.дн';
											|en = 'AUTO DAYS'; fa = 'AUTO DAYS';
											|it = 'автомоб.дн';
											|pl = 'AUTO DAYS';
											|tr = 'OTOMOBİL.GÜN'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Ngày xe';
															|ru = 'АВТОМОБ.ДН';
															|en = 'AUTO DAYS'; fa = 'AUTO DAYS';
															|it = 'АВТОМОБ.ДН';
															|pl = 'AUTO DAYS';
															|tr = 'OTOMOBİL.GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "960";
		Level3.Description = NStr("vi = 'Nghìn xe-tấn-ngày';
									|ru = 'Тысяча автомобиле-тонно-дней';
									|en = 'Thousand automobile-ton-days'; fa = 'Thousand automobile-ton-days';
									|it = 'Mille giorni-automobile-tonnelata';
									|pl = 'Tysiąc samochodo-tono-godzin';
									|tr = 'Bin otomobil-ton-gün'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 xe.t.ngày';
											|ru = '10^3 автомоб.т.дн';
											|en = '10^3 auto t days'; fa = '10^3 auto t days';
											|it = '10^3 giorni-automobile-tonnellata';
											|pl = '10^3 samochodo t. dn';
											|tr = '10^3 otomobil.t.gün'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn xe.t.ngày';
															|ru = 'ТЫС АВТОМОБ.Т.ДН';
															|en = 'THOUS AUTO T DAYS'; fa = 'THOUS AUTO T DAYS';
															|it = 'MILLE GIORNI-AUTOMOBILE-TONNELLATA';
															|pl = 'TYS SAMOCHODO T. DN';
															|tr = 'BİN OTOMOBİL.T.GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "961";
		Level3.Description = NStr("vi = 'Nghìn xe-giờ';
									|ru = 'Тысяча автомобиле-часов';
									|en = 'Thousand automobile-hours'; fa = 'Thousand automobile-hours';
									|it = 'Mille ore-automobile';
									|pl = 'Tysiąc samochodogodzin';
									|tr = 'Bin otomobil-saat'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 xe.h';
											|ru = '10^3 автомоб.ч';
											|en = '10^3 auto h'; fa = '10^3 auto h';
											|it = '10^3 h-automobile';
											|pl = '10^3 samochodogodz';
											|tr = '10^3 otomobil.s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn xe.h';
															|ru = 'ТЫС АВТОМОБ.Ч';
															|en = 'THOUS AUTO H'; fa = 'THOUS AUTO H';
															|it = 'MILLE H-AUTOMOBILE';
															|pl = 'TYS SAMOCHODOGODZ';
															|tr = 'BİN OTOMOBİL.S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "962";
		Level3.Description = NStr("vi = 'Nghìn xe-chỗ-ngày';
									|ru = 'Тысяча автомобиле-место-дней';
									|en = 'Thousand automobile-seat-days'; fa = 'Thousand automobile-seat-days';
									|it = 'Mille giorni-posti-automobile';
									|pl = 'Tysiąc samochodo-miejsco-dni';
									|tr = 'Bin otomobil-yer-gün'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 xe.chỗ. ngày';
											|ru = '10^3 автомоб.мест. дн';
											|en = '10^3 auto seat days'; fa = '10^3 auto seat days';
											|it = '10^3 giorni-posti-automobile';
											|pl = '10^3 samochodomiejsc dn';
											|tr = '10^3 otomobil.yer. gün'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN XE.CHỖ. NGÀY';
															|ru = 'ТЫС АВТОМОБ.МЕСТ. ДН';
															|en = 'THOUS AUTO SEAT DAYS'; fa = 'THOUS AUTO SEAT DAYS';
															|it = 'MILLE GIORNI-POSTI-AUTOMOBILE';
															|pl = 'TYSIĄC MIEJSC SAMOCHOD. DN';
															|tr = 'BİN OTOMOBİL.YER. GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "963";
		Level3.Description = NStr("vi = 'Giờ giảm';
									|ru = 'Приведенный час';
									|en = 'Reduced hour'; fa = 'Reduced hour';
									|it = 'Ore riportate';
									|pl = 'Podana godzina';
									|tr = 'Azaltılmış saat'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'giờ giảm';
											|ru = 'привед.ч';
											|en = 'reduced h'; fa = 'reduced h';
											|it = 'привед.ч';
											|pl = 'reduced h';
											|tr = 'indirgenmiş saat'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'giờ giảm';
															|ru = 'ПРИВЕД.Ч';
															|en = 'reduced h'; fa = 'reduced h';
															|it = 'ПРИВЕД.Ч';
															|pl = 'reduced h';
															|tr = 'indirgenmiş saat'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 162000;
		Level3.Denominator = 1;
		Level3.MeasuredValueType = "Time";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "964";
		Level3.Description = NStr("vi = 'Km máy bay';
									|ru = 'Самолето-километр';
									|en = 'Aircraft-kilometer'; fa = 'Aircraft-kilometer';
									|it = 'Kilometri-aereo';
									|pl = 'Aircraft-kilometer';
									|tr = 'Uçak-kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Km máy bay';
											|ru = 'самолет.км';
											|en = 'AIRCRAFT KM'; fa = 'AIRCRAFT KM';
											|it = 'самолет.км';
											|pl = 'AIRCRAFT KM';
											|tr = 'UÇAK.KM'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Km máy bay';
															|ru = 'САМОЛЕТ.КМ';
															|en = 'AIRCRAFT KM'; fa = 'AIRCRAFT KM';
															|it = 'САМОЛЕТ.КМ';
															|pl = 'AIRCRAFT KM';
															|tr = 'UÇAK.KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "965";
		Level3.Description = NStr("vi = 'Nghìn kilomet';
									|ru = 'Тысяча километров';
									|en = 'Thousand kilometers'; fa = 'Thousand kilometers';
									|it = 'Mille kilometri';
									|pl = 'Tysiąc kilometrów';
									|tr = 'Bin kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 km';
											|ru = '10^3 км';
											|en = '10^3 km'; fa = '10^3 km';
											|it = '10^3 km';
											|pl = '10^3 km';
											|tr = '10^3 km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN KM';
															|ru = 'ТЫС КМ';
															|en = 'THOUS KM'; fa = 'THOUS KM';
															|it = 'MILLE KM';
															|pl = 'TYS KM';
															|tr = 'BİN KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "966";
		Level3.Description = NStr("vi = 'Nghìn chuyến bay trọng tải';
									|ru = 'Тысяча тоннаже-рейсов';
									|en = 'Thousand tonnage-trips'; fa = 'Thousand tonnage-trips';
									|it = 'Mille voli-tonnellaggio';
									|pl = 'Tysiąc lotów tonażowych';
									|tr = 'Bin tonluk seferler'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 chuyến bay trọng tải';
											|ru = '10^3 тоннаж. рейс';
											|en = '10^3 tonn trips'; fa = '10^3 tonn trips';
											|it = '10^3 voli-tonnellaggio';
											|pl = '10^3 lotów tonaż';
											|tr = '10^3 tonluk. sefer'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN CHUYẾN BAY TRỌNG TẢI';
															|ru = 'ТЫС ТОННАЖ. РЕЙС';
															|en = 'THOUS TONN TRIPS'; fa = 'THOUS TONN TRIPS';
															|it = 'MILLE VOLI TONNELLAGGIO';
															|pl = 'TYS LOTÓW TONAŻ';
															|tr = 'BİN TONLUK. SEFER'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "967";
		Level3.Description = NStr("vi = 'Triệu tấn-dặm';
									|ru = 'Миллион тонно-миль';
									|en = 'Million ton-miles'; fa = 'Million ton-miles';
									|it = 'Un milione di miglia-tonnellate';
									|pl = 'Milion mil tonażowych';
									|tr = 'Milyon ton-mil'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 t dặm';
											|ru = '10^6 т. миль';
											|en = '10^6 t miles'; fa = '10^6 t miles';
											|it = '10^6 miglia-t';
											|pl = '10^6 mil ton';
											|tr = '10^6 t. mil'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU TẤN DẶM';
															|ru = 'МЛН Т. МИЛЬ';
															|en = 'MIL T MILES'; fa = 'MIL T MILES';
															|it = 'MLN DI MIGLIA-T';
															|pl = 'MLN MIL TON';
															|tr = 'MİLYON T. MİL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "968";
		Level3.Description = NStr("vi = 'Triệu dặm chở khách';
									|ru = 'Миллион пассажиро-миль';
									|en = 'Million passenger-miles'; fa = 'Million passenger-miles';
									|it = 'Un milione di miglia-passeggeri';
									|pl = 'Milion mil pasażerskich';
									|tr = 'Milyon yolcu-mil'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 dặm chở khách';
											|ru = '10^6 пасс. миль';
											|en = '10^6 pmi'; fa = '10^6 pmi';
											|it = '10^6 miglia-passeggeri';
											|pl = '10^6 mil pas';
											|tr = '10^6 yolcu. mil'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu dặm chở khách';
															|ru = 'МЛН ПАСС. МИЛЬ';
															|en = 'MIL PMI'; fa = 'MIL PMI';
															|it = 'MLN DI MIGLIA PASSEGGERI';
															|pl = 'MLN MIL PAS';
															|tr = 'MİLYON YOLCU. MİL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "969";
		Level3.Description = NStr("vi = 'Triệu dặm trọng tải';
									|ru = 'Миллион тоннаже-миль';
									|en = 'Million tonnage-miles'; fa = 'Million tonnage-miles';
									|it = 'Un milione di miglia-tonnellaggio';
									|pl = 'Milion mil tonażowych';
									|tr = 'Milyon tonluk-mil'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 dặm trọng tải';
											|ru = '10^6 тоннаж. миль';
											|en = '10^6 tonn miles'; fa = '10^6 tonn miles';
											|it = '10^6 di miglia-tonnellaggio';
											|pl = '10^6 mil tonaż';
											|tr = '10^6 tonluk. mil'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu dặm trọng tải';
															|ru = 'МЛН ТОННАЖ. МИЛЬ';
															|en = 'MIL TONN MILES'; fa = 'MIL TONN MILES';
															|it = 'MLN DI MIGLIA TONNELLAGGIO';
															|pl = 'MLN MIL TONAŻ';
															|tr = 'MİLYON TONLUK. MİL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "970";
		Level3.Description = NStr("vi = 'Triệu hành khách-chỗ-dặm';
									|ru = 'Миллион пассажиро-место-миль';
									|en = 'Million passenger-seat-miles'; fa = 'Million passenger-seat-miles';
									|it = 'Un milione di miglia-posti-passeggeri';
									|pl = 'Milion mil pasażeromiejsc';
									|tr = 'Milyon yolcu-yer-mil'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 hành khách. chỗ. dặm';
											|ru = '10^6 пасс. мест. миль';
											|en = '10^6 pax seat miles'; fa = '10^6 pax seat miles';
											|it = '10^6 di miglia-posti-passeggeri';
											|pl = '10^6 mil pasażeromiejsc';
											|tr = '10^6 yolcu. yer. mil'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Triệu hành khách. chỗ. dặm';
															|ru = 'МЛН ПАСС. МЕСТ. МИЛЬ';
															|en = 'MIL PAX SEAT MILES'; fa = 'MIL PAX SEAT MILES';
															|it = 'MLN DI MIGLIA POSTI PASSEGGERI';
															|pl = 'MLN MIEJSC PASAŻERSKICH MIL';
															|tr = 'MİLYON YOLCU. YER. MİL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "971";
		Level3.Description = NStr("vi = 'Gia súc-ngày';
									|ru = 'Кормо-день';
									|en = 'Feed day'; fa = 'Feed day';
									|it = 'Mangime per giorno';
									|pl = 'Feed day';
									|tr = 'Besleme-günü'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'gia súc. ngày';
											|ru = 'корм. дн';
											|en = 'FEED DAYS'; fa = 'FEED DAYS';
											|it = 'корм. дн';
											|pl = 'dn. pasz';
											|tr = 'BESLEME. GÜN'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'gia súc. ngày';
															|ru = 'КОРМ. ДН';
															|en = 'FEED DAYS'; fa = 'FEED DAYS';
															|it = 'КОРМ. ДН';
															|pl = 'FEED DAYS';
															|tr = 'BESLEME. GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "972";
		Level3.Description = NStr("vi = 'Trung tâm đơn vị thức ăn chăn nuôi';
									|ru = 'Центнер кормовых единиц';
									|en = 'Centner of feed units'; fa = 'Centner of feed units';
									|it = 'Un quintale di unità di razione di mangime';
									|pl = 'Kwintal jednostek paszowych';
									|tr = 'Besleme birimleri sentneri'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'c đv thức ăn chăn nuôi';
											|ru = 'ц корм ед';
											|en = 'c feed units'; fa = 'c feed units';
											|it = 'ц корм ед';
											|pl = 'c feed units';
											|tr = 's besleme birimi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'c đv thức ăn chăn nuôi';
															|ru = 'Ц КОРМ ЕД';
															|en = 'c feed units'; fa = 'c feed units';
															|it = 'Ц КОРМ ЕД';
															|pl = 'kwin jedn. paszowych';
															|tr = 's besleme birimi'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "973";
		Level3.Description = NStr("vi = 'Nghìn kilomet đường bộ';
									|ru = 'Тысяча автомобиле-километров';
									|en = 'Thousand automobile-kilometers'; fa = 'Thousand automobile-kilometers';
									|it = 'Mille kilometri-automobile';
									|pl = 'Tysiąc samochodo-kilometrów';
									|tr = 'Bin otomobil-kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 km đường bộ';
											|ru = '10^3 автомоб. км';
											|en = '10^3 auto km'; fa = '10^3 auto km';
											|it = '10^3 kilometri-automobile';
											|pl = '10^3 km samochodowych';
											|tr = '10^3 otomobil. km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN KM ĐƯỜNG BỘ';
															|ru = 'ТЫС АВТОМОБ. КМ';
															|en = 'THOUS AUTO KM'; fa = 'THOUS AUTO KM';
															|it = 'MILLE KILOMETRI AUTOMOBILE';
															|pl = 'TYS KM SAMOCHODOWYCH';
															|tr = 'BİN OTOMOBİL. KM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "974";
		Level3.Description = NStr("vi = 'Nghìn tấn-ngày';
									|ru = 'Тысяча тоннаже-сут';
									|en = 'Thousand tonnage-days'; fa = 'Thousand tonnage-days';
									|it = 'Mille giorni-tonnellaggio';
									|pl = 'Tysiąc dób tonażowych';
									|tr = 'Bin tonluk-gün'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 tấn-ngày';
											|ru = '10^3 тоннаж. сут';
											|en = '10^3 tonn days'; fa = '10^3 tonn days';
											|it = '10^3 giorni-tonnellaggio';
											|pl = '10^3 dób tonaż';
											|tr = '10^3 tonluk. gün'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN TẤN-NGÀY';
															|ru = 'ТЫС ТОННАЖ. СУТ';
															|en = 'TOUS TONN DAYS'; fa = 'TOUS TONN DAYS';
															|it = 'MILLE GIORNI TONNELLAGGIO';
															|pl = 'TYS DÓB TONAŻ';
															|tr = 'BİN TONLUK. GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "975";
		Level3.Description = NStr("vi = 'Sugo-ngày';
									|ru = 'Суго-сутки';
									|en = 'Cargo reinforcement equipment-day'; fa = 'Cargo reinforcement equipment-day';
									|it = 'Giorni- mezzi di ampliamento del carico';
									|pl = 'Cargo reinforcement equipment-day';
									|tr = 'Yük konsolidasyon araçları-günler'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'sugo. ngày';
											|ru = 'суго. сут.';
											|en = 'cargo reinf. eqpt. days'; fa = 'cargo reinf. eqpt. days';
											|it = 'gg-mezzi di ampliamento del carico';
											|pl = 'dób gaz. płyn.';
											|tr = 'yük konsolidasyon araçları. gün.'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'SUGO. NGÀY';
															|ru = 'СУГО. СУТ';
															|en = 'CARGO REINF EQUIPT DAYS'; fa = 'CARGO REINF EQUIPT DAYS';
															|it = 'GG-MEZZI DI AMPLIAMENTO DEL CARICO';
															|pl = 'DÓB GAZ. PŁYN.';
															|tr = 'YÜK KONSOLİDASYON ARAÇLARI. GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "976";
		Level3.Description = NStr("vi = 'Chiếc tương đương 20 foot (TEU)';
									|ru = 'Штук в 20-футовом эквиваленте (ДФЭ)';
									|en = 'Twenty-foot equivalent unit​s'; fa = 'Twenty-foot equivalent unit​s';
									|it = 'Pezzi in unità equivalente a venti piedi';
									|pl = 'Sztuk w ekwiwalencie 20 stóp (TEU)';
									|tr = '20 fit eşdeğerindeki parçalar (İyirmi Fit Eşdeğerinde)'", Common.DefaultLanguageCode());
		Level3.SymbolNational = NStr("vi = 'Chiếc tương
			|đương 20 foot';
			|ru = 'штук в 20-футовом
			|эквиваленте';
			|en = 'teu
			|'; fa = 'teu
			|';
			|it = 'pezzi in unità equivalente
			|a venti piedi';
			|pl = 'sztuk w ekwiwalencie 
			|20 stóp';
			|tr = '20 fit eşdeğerindeki
			|parçalar'", Common.DefaultLanguageCode());
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'CHIẾC TƯƠNG ĐƯƠNG 20 FOOT';
															|ru = 'ШТ В 20 ФУТ ЭКВИВ';
															|en = 'TEU'; fa = 'TEU';
															|it = 'PZ IN UNITÀ EQUIVALENTE A 20 PIEDI';
															|pl = 'SZT W EKWIW 20 STÓP';
															|tr = '20 FİT EŞDEĞERİNDEKİ PARÇALAR'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "977";
		Level3.Description = NStr("vi = 'Kênh-kilomet';
									|ru = 'Канало-километр';
									|en = 'Circuit-kilometer'; fa = 'Circuit-kilometer';
									|it = 'Kilometri-canale';
									|pl = 'Circuit-kilometer';
									|tr = 'Kanal-kilometre'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'kênh. km';
											|ru = 'канал. км';
											|en = 'circuit km'; fa = 'circuit km';
											|it = 'km-kanale';
											|pl = 'kanałokm';
											|tr = 'kanal. km'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'kênh. km';
															|ru = 'КАНАЛ. КМ';
															|en = 'circuit km'; fa = 'circuit km';
															|it = 'km-kanale';
															|pl = 'circuit km';
															|tr = 'kanal. km'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "978";
		Level3.Description = NStr("vi = 'Kênh cuối';
									|ru = 'Канало-концы';
									|en = 'Circuit-ends'; fa = 'Circuit-ends';
									|it = 'Estremità-canale';
									|pl = 'Circuit-ends';
									|tr = 'Kanal-son'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'kênh cuối';
											|ru = 'канал. конц';
											|en = 'CIRCUIT ENDS'; fa = 'CIRCUIT ENDS';
											|it = 'канал. конц';
											|pl = 'kanałokoń';
											|tr = 'KANAL. SON'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'kênh cuối';
															|ru = 'КАНАЛ. КОНЦ';
															|en = 'CIRCUIT ENDS'; fa = 'CIRCUIT ENDS';
															|it = 'КАНАЛ. КОНЦ';
															|pl = 'CIRCUIT ENDS';
															|tr = 'KANAL. SON'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "979";
		Level3.Description = NStr("vi = 'Nghìn bản';
									|ru = 'Тысяча экземпляров';
									|en = 'Thousand copies'; fa = 'Thousand copies';
									|it = 'Mille copie';
									|pl = 'Tysiąc egzemplarzy';
									|tr = 'Bin örnek'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 bản';
											|ru = '10^3 экз';
											|en = '10^3 copies'; fa = '10^3 copies';
											|it = '10^3 copie';
											|pl = '10^3 egz';
											|tr = '10^3 örnek'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN BẢN';
															|ru = 'ТЫС ЭКЗ';
															|en = 'THOUS COPIES'; fa = 'THOUS COPIES';
															|it = 'MILLE COPIE';
															|pl = 'TYS EGZ';
															|tr = 'BİN ÖRNEK'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "980";
		Level3.Description = NStr("vi = 'Nghìn đô la';
									|ru = 'Тысяча долларов';
									|en = 'Thousand dollars'; fa = 'Thousand dollars';
									|it = 'Mille dollari';
									|pl = 'Tysiąc dolarów';
									|tr = 'Bin dolar'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 đô la';
											|ru = '10^3 доллар';
											|en = '10^3 USD'; fa = '10^3 USD';
											|it = '10^3 dollari';
											|pl = '10^3 dolar';
											|tr = '10^3 dolar'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN ĐÔ LA';
															|ru = 'ТЫС ДОЛЛАР';
															|en = 'THOUS USD'; fa = 'THOUS USD';
															|it = 'MILLE DOLLARI';
															|pl = 'TYS DOLLAR';
															|tr = 'BİN DOLAR'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "981";
		Level3.Description = NStr("vi = 'Ngàn tấn đơn vị thức ăn chăn nuôi';
									|ru = 'Тысяча тонн кормовых единиц';
									|en = 'Thousand tons of feed units'; fa = 'Thousand tons of feed units';
									|it = 'Mille tonnellate di unità di razione di mangime';
									|pl = 'Tysiąc ton jednostek paszowych';
									|tr = 'Bin tonluk besleme birimi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 đơn vị thức ăn chăn nuôi';
											|ru = '10^3 корм ед';
											|en = '10^3 feed units'; fa = '10^3 feed units';
											|it = '10^3 unità di razione di mangime';
											|pl = '10^3 jedn pasz';
											|tr = '10^3 besleme birimi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Ngàn tấn đơn vị thức ăn chăn nuôi';
															|ru = 'ТЫС Т КОРМ ЕД';
															|en = 'THOUS FEED UNITS'; fa = 'THOUS FEED UNITS';
															|it = 'MILLE T DI UNITÀ DI RAZIONE DI MANGIME';
															|pl = 'TYS T JEDN PASZ';
															|tr = 'BİN T BESLEME BİRİMİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "982";
		Level3.Description = NStr("vi = 'Triệu tấn đơn vị thức ăn chăn nuôi';
									|ru = 'Миллион тонн кормовых единиц';
									|en = 'Million tons of feed units'; fa = 'Million tons of feed units';
									|it = 'Un milione di tonnellate di unità di razione di mangime';
									|pl = 'Milion ton jednostek paszowych';
									|tr = 'Milyon ton besleme birimi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 đơn vị thức ăn chăn nuôi';
											|ru = '10^6 корм ед';
											|en = '10^6 feed units'; fa = '10^6 feed units';
											|it = '10^6 unità di razione di mangime';
											|pl = '10^6 jedn pasz';
											|tr = '10^6 besleme birimi'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU TẤN ĐƠN VỊ THỨC ĂN CHĂN NUÔI';
															|ru = 'МЛН Т КОРМ ЕД';
															|en = 'MIL FEED UNITS'; fa = 'MIL FEED UNITS';
															|it = 'MLN T DI UNITÀ DI RAZIONE DI MANGIME';
															|pl = 'MLN T JEDN PASZ';
															|tr = 'MİLYON T BESLEME BİRİMİ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "983";
		Level3.Description = NStr("vi = 'Sudo-ngày';
									|ru = 'Судо-сутки';
									|en = 'Vessel-day'; fa = 'Vessel-day';
									|it = 'Giorno-imbarcazione';
									|pl = 'Vessel-day';
									|tr = 'Gemi-günü'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'TÀU.NGÀY';
											|ru = 'суд.сут';
											|en = 'VESSEL DAYS'; fa = 'VESSEL DAYS';
											|it = 'суд.сут';
											|pl = 'VESSEL DAYS';
											|tr = 'GEMİ.GÜN'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TÀU.NGÀY';
															|ru = 'СУД.СУТ';
															|en = 'VESSEL DAYS'; fa = 'VESSEL DAYS';
															|it = 'СУД.СУТ';
															|pl = 'VESSEL DAYS';
															|tr = 'GEMİ.GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "984";
		Level3.Description = NStr("vi = 'Centers trên hecta';
									|ru = 'Центнеров с гектара';
									|en = 'Centners per hectare'; fa = 'Centners per hectare';
									|it = 'Quintali per ettaro';
									|pl = 'Kwintali z hektara';
									|tr = 'Hektardan sentner'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'c/ha';
											|ru = 'ц/га';
											|en = 'c/ha'; fa = 'c/ha';
											|it = 'ц/га';
											|pl = 'c/ha';
											|tr = 's/ha'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'c/ha';
															|ru = 'Ц/ГА';
															|en = 'c/ha'; fa = 'c/ha';
															|it = 'Ц/ГА';
															|pl = 'c/ha';
															|tr = 's/ha'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "985";
		Level3.Description = NStr("vi = 'Nghìn đầu';
									|ru = 'Тысяча голов';
									|en = 'Thousand heads'; fa = 'Thousand heads';
									|it = 'Mille capi';
									|pl = 'Tysiąc głów';
									|tr = 'Bin baş'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 đầu';
											|ru = '10^3 гол';
											|en = '10^3 heads'; fa = '10^3 heads';
											|it = '10^3 capi';
											|pl = '10^3 gł';
											|tr = '10^3 baş'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Nghìn đầu';
															|ru = 'ТЫС ГОЛ';
															|en = 'THOUS HEADS'; fa = 'THOUS HEADS';
															|it = 'MILLE CAPI';
															|pl = 'TYS GŁ';
															|tr = 'BİN BAŞ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "986";
		Level3.Description = NStr("vi = 'Nghìn bản in màu';
									|ru = 'Тысяча краско-оттисков';
									|en = 'Thousand color printed sheets'; fa = 'Thousand color printed sheets';
									|it = 'Mille impronte di stampa di tintura';
									|pl = 'Tysiąc odbitek kolorowych';
									|tr = 'Bin renk-baskılı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 bản in màu';
											|ru = '10^3 краск. оттиск';
											|en = '10^3 color printed sheets'; fa = '10^3 color printed sheets';
											|it = '10^3 impronte di stampa di tintura';
											|pl = '10^3 odbitek kolorowych';
											|tr = '10^3 renk. baskı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN BẢN IN MÀU';
															|ru = 'ТЫС КРАСК ОТТИСК';
															|en = 'THOUS COLOR PRINTED SHEETS'; fa = 'THOUS COLOR PRINTED SHEETS';
															|it = 'MILLE IMPRONTE DI STAMPA DI TINTURA';
															|pl = 'TYS ODBITEK KOLOROWYCH';
															|tr = 'BİN RENK BASKI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "987";
		Level3.Description = NStr("vi = 'Triệu bản in màu';
									|ru = 'Миллион краско-оттисков';
									|en = 'Million color printed sheets'; fa = 'Million color printed sheets';
									|it = 'Un milione di impronte di stampa di tintura';
									|pl = 'Milion odbitek kolorowych';
									|tr = 'Milyon renk-baskılı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 bản in màu';
											|ru = '10^6 краск. оттиск';
											|en = '10^6 color printed sheets'; fa = '10^6 color printed sheets';
											|it = '10^6 di impronte di stampa di tintura';
											|pl = '10^6 odbitek kolorowych';
											|tr = '10^6 renk. baskı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU BẢN IN MÀU';
															|ru = 'МЛН КРАСК ОТТИСК';
															|en = 'MIL COLOR PRINTED SHEETS'; fa = 'MIL COLOR PRINTED SHEETS';
															|it = 'MLN DI IMPRONTE DI STAMPA DI TINTURA';
															|pl = 'MLN ODBITEK KOLOROWYCH';
															|tr = 'MİLYON RENK BASKI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "988";
		Level3.Description = NStr("vi = 'Triệu viên gạch quy ước';
									|ru = 'Миллион условных плиток';
									|en = 'Million conventional tiles'; fa = 'Million conventional tiles';
									|it = 'Un milione di mattonelle convenzionali';
									|pl = 'Milion płytek umownych';
									|tr = 'Milyon koşullu levha'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^6 viên gạch quy ước';
											|ru = '10^6 усл. плит';
											|en = '10^6 convl. tiles'; fa = '10^6 convl. tiles';
											|it = '10^6 di mattonelle conv.';
											|pl = '10^6 płyt umownych';
											|tr = '10^6 koşullu. levha'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRIỆU VIÊN GẠCH QUY ƯỚC';
															|ru = 'МЛН УСЛ ПЛИТ';
															|en = 'MIL CONVL TILES'; fa = 'MIL CONVL TILES';
															|it = 'MLN DI MATTONELLE CONV.';
															|pl = 'MLN PŁYT WAR';
															|tr = 'MİLYON KOŞULLU LEVHA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "989";
		Level3.Description = NStr("vi = 'Người mỗi giờ';
									|ru = 'Человек в час';
									|en = 'People per hour'; fa = 'People per hour';
									|it = 'Persone all''ora';
									|pl = 'Osób na godzinę';
									|tr = 'Saatte kişi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Người/h';
											|ru = 'чел/ч';
											|en = 'people/h'; fa = 'people/h';
											|it = 'чел/ч';
											|pl = 'people/h';
											|tr = 'KİŞİ/SA'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Người/h';
															|ru = 'ЧЕЛ/Ч';
															|en = 'people/h'; fa = 'people/h';
															|it = 'ЧЕЛ/Ч';
															|pl = 'people/h';
															|tr = 'KİŞİ/SA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "990";
		Level3.Description = NStr("vi = 'Hành khách mỗi giờ';
									|ru = 'Пассажиров в час';
									|en = 'Passengers per hour'; fa = 'Passengers per hour';
									|it = 'Passeggeri all''ora';
									|pl = 'Pasażerów na godzinę';
									|tr = 'Saatte yolcu'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'hành khách/h';
											|ru = 'пасс/ч';
											|en = 'p/h'; fa = 'p/h';
											|it = 'пасс/ч';
											|pl = 'p/h';
											|tr = 'yolcu/s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'hành khách/h';
															|ru = 'ПАСС/Ч';
															|en = 'p/h'; fa = 'p/h';
															|it = 'ПАСС/Ч';
															|pl = 'p/h';
															|tr = 'yolcu/s'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "991";
		Level3.Description = NStr("vi = 'Hành khách-dặm';
									|ru = 'Пассажиро-миля';
									|en = 'Passenger-mile'; fa = 'Passenger-mile';
									|it = 'Miglio-passeggero';
									|pl = 'Passenger-mile';
									|tr = 'Yolcu-mil'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'hành khách-dặm';
											|ru = 'пасс. миля';
											|en = 'pmi'; fa = 'pmi';
											|it = 'miglio-pass';
											|pl = 'pas-mila';
											|tr = 'yolcu. mil'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Hành khách dặm';
															|ru = 'ПАСС МИЛЯ';
															|en = 'PMI pass'; fa = 'PMI pass';
															|it = 'MIGLIO PASS';
															|pl = 'PAS-MILA';
															|tr = 'YOLCU MİL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level1 = ValueTree.Rows.Add();
		Level1.NumericCode = "";
		Level1.Description = NStr("vi = 'Các đơn vị đo lường quốc gia gồm 4 ký tự';
									|ru = 'Четырехзначные национальные единицы измерения, включенные в ОКЕИ';
									|en = 'Four-digit national units of measure included in Russian National Classifier of Measurement Units'; fa = 'Four-digit national units of measure included in Russian National Classifier of Measurement Units';
									|it = 'Unità di misura nazionali a quattro cifre incluse in Classificatore panrusso di unità di misure';
									|pl = 'Czteroznaczne krajowe jednostki miary; zawarte w klasyfikatorze jednostek miary';
									|tr = 'RÖBS''e dahil olan dört basamaklı ulusal ölçü birimleri'", Common.DefaultLanguageCode());
		Level1.SymbolNational = "";
		Level1.InternationalSymbol = "";
		Level1.CodeLetterDesignationNational = "";
		Level1.CodeLetterDesignationInternational = "";
		Level1.Numerator = 0;
		Level1.Denominator = 0;
		Level1.MeasuredValueType = "";
		Level2 = Level1.Rows.Add();
		Level2.NumericCode = "";
		Level2.Description = NStr("vi = 'Đơn vị kỹ thuật';
									|ru = 'Технические единицы';
									|en = 'Engineering units'; fa = 'Engineering units';
									|it = 'Unità di misura tecniche';
									|pl = 'Jednostki techniczne';
									|tr = 'Teknik birimler'", Common.DefaultLanguageCode());
		Level2.SymbolNational = "";
		Level2.InternationalSymbol = "";
		Level2.CodeLetterDesignationNational = "";
		Level2.CodeLetterDesignationInternational = "";
		Level2.Numerator = 0;
		Level2.Denominator = 0;
		Level2.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "2553";
		Level3.Description = NStr("vi = 'Gigabyte';
									|ru = 'Гигабайт';
									|en = 'Gigabyte'; fa = 'گیگابایت';
									|it = 'Gigabyte';
									|pl = 'Gigabyte';
									|tr = 'Gigabayt'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Gbyte';
											|ru = 'Гбайт';
											|en = 'GB'; fa = 'GB';
											|it = 'Гбайт';
											|pl = 'GB';
											|tr = 'Gbayt'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Gbyte';
															|ru = 'ГБАЙТ';
															|en = 'GB'; fa = 'GB';
															|it = 'ГБАЙТ';
															|pl = 'GB';
															|tr = 'Gbayt'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "2554";
		Level3.Description = NStr("vi = 'Terabyte';
									|ru = 'Терабайт';
									|en = 'Terabyte'; fa = 'ترابایت';
									|it = 'Terabyte';
									|pl = 'Terabyte';
									|tr = 'Terabayt'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'TBYTE';
											|ru = 'Тбайт';
											|en = 'TB'; fa = 'TB';
											|it = 'Тбайт';
											|pl = 'TB';
											|tr = 'TBAYT'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TBYTE';
															|ru = 'ТБАЙТ';
															|en = 'TB'; fa = 'TB';
															|it = 'ТБАЙТ';
															|pl = 'TB';
															|tr = 'TBAYT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "2555";
		Level3.Description = NStr("vi = 'Petabyte';
									|ru = 'Петабайт';
									|en = 'Petabyte'; fa = 'Petabyte';
									|it = 'Petabyte';
									|pl = 'Petabyte';
									|tr = 'Petabayt'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'PBYTE';
											|ru = 'Пбайт';
											|en = 'PB'; fa = 'PB';
											|it = 'Пбайт';
											|pl = 'PB';
											|tr = 'PBAYT'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'PBYTE';
															|ru = 'ПБАЙТ';
															|en = 'PB'; fa = 'PB';
															|it = 'ПБАЙТ';
															|pl = 'PB';
															|tr = 'PBAYT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "2556";
		Level3.Description = NStr("vi = 'Exabyte';
									|ru = 'Эксабайт';
									|en = 'Exabyte'; fa = 'Exabyte';
									|it = 'Exabyte';
									|pl = 'Exabyte';
									|tr = 'Eksabayt'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Ebyte';
											|ru = 'Эбайт';
											|en = 'EB'; fa = 'EB';
											|it = 'EB';
											|pl = 'EB';
											|tr = 'Ebayt'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Ebyte';
															|ru = 'ЭБАЙТ';
															|en = 'EB'; fa = 'EB';
															|it = 'EB';
															|pl = 'EB';
															|tr = 'Ebayt'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "2557";
		Level3.Description = NStr("vi = 'Zettabyte';
									|ru = 'Зеттабайт';
									|en = 'Zettabyte'; fa = 'Zettabyte';
									|it = 'Zettabyte';
									|pl = 'Zettabyte';
									|tr = 'Zettabayt'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Zbyte';
											|ru = 'Збайт';
											|en = 'ZB'; fa = 'ZB';
											|it = 'Збайт';
											|pl = 'ZB';
											|tr = 'Zbayt'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Zbyte';
															|ru = 'ЗБАЙТ';
															|en = 'ZB'; fa = 'ZB';
															|it = 'ЗБАЙТ';
															|pl = 'ZB';
															|tr = 'Zbayt'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "2558";
		Level3.Description = NStr("vi = 'Yottabyte';
									|ru = 'Йоттабайт';
									|en = 'Yottabyte'; fa = 'Yottabyte';
									|it = 'Yottabyte';
									|pl = 'Yottabyte';
									|tr = 'Yottabayt'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Ybyte';
											|ru = 'Йбайт';
											|en = 'YB'; fa = 'YB';
											|it = 'Йбайт';
											|pl = 'YB';
											|tr = 'YBAYT'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Ybyte';
															|ru = 'ЙБАЙТ';
															|en = 'YB'; fa = 'YB';
															|it = 'ЙБАЙТ';
															|pl = 'YB';
															|tr = 'YBAYT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level2 = Level1.Rows.Add();
		Level2.NumericCode = "";
		Level2.Description = NStr("vi = 'Đơn vị kinh tế';
									|ru = 'Экономические единицы';
									|en = 'Economic units'; fa = 'Economic units';
									|it = 'Unità di misura economiche';
									|pl = 'Jednostki ekonomiczne';
									|tr = 'Ekonomik birimler'", Common.DefaultLanguageCode());
		Level2.SymbolNational = "";
		Level2.InternationalSymbol = "";
		Level2.CodeLetterDesignationNational = "";
		Level2.CodeLetterDesignationInternational = "";
		Level2.Numerator = 0;
		Level2.Denominator = 0;
		Level2.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "3831";
		Level3.Description = NStr("vi = 'Rúp tấn';
									|ru = 'Рубль тонна';
									|en = 'Ruble ton'; fa = 'Ruble ton';
									|it = 'Rublo tonnellata';
									|pl = 'Rubel tona';
									|tr = 'Ruble ton'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'rúp tấn';
											|ru = 'руб. тонна';
											|en = 'rub t.'; fa = 'rub t.';
											|it = 'rub. tonnellata';
											|pl = 'rub. tona';
											|tr = 'ruble. ton'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'RÚP TẤN';
															|ru = 'РУБ ТОННА';
															|en = 'RUB T'; fa = 'RUB T';
															|it = 'RUB. TONNELLATA';
															|pl = 'RUB TONA';
															|tr = 'RUBLE TON'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "5401";
		Level3.Description = NStr("vi = 'Trẻ em-ngày';
									|ru = 'Дето-день';
									|en = 'Baby-day'; fa = 'Baby-day';
									|it = 'Giorno/bambino alla scuola dell''infanzia';
									|pl = 'Baby-day';
									|tr = 'Çoçuk-günü'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'trẻ em. ngày';
											|ru = 'дет. дн';
											|en = 'baby day.'; fa = 'baby day.';
											|it = 'g/bamb. alla scuola dell''infanzia';
											|pl = 'dz. dzień';
											|tr = 'çoçuk. günü'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TRẺ EM NGÀY';
															|ru = 'ДЕТ ДН';
															|en = 'BABY DAY'; fa = 'BABY DAY';
															|it = 'G/BAMB. ALLA SCUOLA DELL''INFANZIA';
															|pl = 'DZIECKODZ';
															|tr = 'ÇOÇUK GÜNÜ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "5423";
		Level3.Description = NStr("vi = 'Người trên năm';
									|ru = 'Человек в год';
									|en = 'People per year'; fa = 'People per year';
									|it = 'Persone all''anno';
									|pl = 'Osób rocznie';
									|tr = 'Yılda kişi'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Người/năm';
											|ru = 'чел/год';
											|en = 'PEOPLE/YEAR'; fa = 'PEOPLE/YEAR';
											|it = 'чел/год';
											|pl = 'PEOPLE/YEAR';
											|tr = 'KİŞİ/YIL'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Người/năm';
															|ru = 'ЧЕЛ/ГОД';
															|en = 'PEOPLE/YEAR'; fa = 'PEOPLE/YEAR';
															|it = 'ЧЕЛ/ГОД';
															|pl = 'PEOPLE/YEAR';
															|tr = 'KİŞİ/YIL'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "5451";
		Level3.Description = NStr("vi = 'Lần ghé thăm';
									|ru = 'Посещение';
									|en = 'Visit'; fa = 'بازدید';
									|it = 'Frequenze';
									|pl = 'Visit';
									|tr = 'Ziyaret'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Lần ghé thăm';
											|ru = 'посещ';
											|en = 'VISITS'; fa = 'VISITS';
											|it = 'посещ';
											|pl = 'VISITS';
											|tr = 'ZİYARET'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Lần ghé thăm';
															|ru = 'ПОСЕЩ';
															|en = 'VISITS'; fa = 'VISITS';
															|it = 'ПОСЕЩ';
															|pl = 'VISITS';
															|tr = 'ZİYARET'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "5562";
		Level3.Description = NStr("vi = 'Nghìn tổ';
									|ru = 'Тысяча гнезд';
									|en = 'Thousand nests'; fa = 'Thousand nests';
									|it = 'Mille nidi';
									|pl = 'Tysiąc gniazd';
									|tr = 'Bin yuva'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^3 tổ';
											|ru = '10^3 гнезд';
											|en = '10^3 nests'; fa = '10^3 nests';
											|it = '10^3 nidi';
											|pl = '10^3 gniazd';
											|tr = '10^3 yuva'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'NGHÌN TỔ';
															|ru = 'ТЫС ГНЕЗД';
															|en = 'THOUS NESTS'; fa = 'THOUS NESTS';
															|it = 'MILLE NIDI';
															|pl = 'TYS GNIAZD';
															|tr = 'BİN YUVA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "6421";
		Level3.Description = NStr("vi = 'Đơn vị trong năm';
									|ru = 'Единиц в год';
									|en = 'Units per year'; fa = 'Units per year';
									|it = 'Unità all''anno';
									|pl = 'Jednostek rocznie';
									|tr = 'Yıllık birim'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'đv/năm';
											|ru = 'ед/год';
											|en = 'U/year'; fa = 'U/year';
											|it = 'ед/год';
											|pl = 'U/year';
											|tr = 'birim/yıl'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'đv/năm';
															|ru = 'ЕД/ГОД';
															|en = 'U/year'; fa = 'U/year';
															|it = 'ЕД/ГОД';
															|pl = 'U/year';
															|tr = 'birim/yıl'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "6422";
		Level3.Description = NStr("vi = 'LẦN GỌI';
									|ru = 'Вызов';
									|en = 'Call'; fa = 'تماس';
									|it = 'Вызов';
									|pl = 'Call';
									|tr = 'Вызов'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'LẦN GỌI';
											|ru = 'вызов';
											|en = 'call'; fa = 'call';
											|it = 'вызов';
											|pl = 'call';
											|tr = 'вызов'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'LẦN GỌI';
															|ru = 'ВЫЗОВ';
															|en = 'CALL'; fa = 'CALL';
															|it = 'ВЫЗОВ';
															|pl = 'CALL';
															|tr = 'ВЫЗОВ'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "6424";
		Level3.Description = NStr("vi = 'Giống';
									|ru = 'Штамм';
									|en = 'STRAIN'; fa = 'STRAIN';
									|it = 'Штамм';
									|pl = 'STRAIN';
									|tr = 'STAMM'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Giống';
											|ru = 'штамм';
											|en = 'STRAIN'; fa = 'STRAIN';
											|it = 'штамм';
											|pl = 'STRAIN';
											|tr = 'STAMM'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Giống';
															|ru = 'ШТАММ';
															|en = 'STRAIN'; fa = 'STRAIN';
															|it = 'ШТАММ';
															|pl = 'STRAIN';
															|tr = 'STAMM'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "8361";
		Level3.Description = NStr("vi = 'LOÀI';
									|ru = 'Особь';
									|en = 'SPECIMEN'; fa = 'SPECIMEN';
									|it = 'Esemplare';
									|pl = 'SPECIMEN';
									|tr = 'NUMUNE'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'loài';
											|ru = 'ос';
											|en = 'sp'; fa = 'sp';
											|it = 'es.';
											|pl = 'sp';
											|tr = 'numune'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'LOÀI';
															|ru = 'ОСОБЬ';
															|en = 'SPECIMEN'; fa = 'SPECIMEN';
															|it = 'Esemplare';
															|pl = 'SPECIMEN';
															|tr = 'NUMUNE'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "8751";
		Level3.Description = NStr("vi = 'Hộp';
									|ru = 'Коробка';
									|en = 'Box'; fa = 'Box';
									|it = 'Scatola';
									|pl = 'Box';
									|tr = 'Kutu'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'hộp';
											|ru = 'кор';
											|en = 'boxes'; fa = 'boxes';
											|it = 'кор';
											|pl = 'boxes';
											|tr = 'kutu'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'hộp';
															|ru = 'КОР';
															|en = 'boxes'; fa = 'boxes';
															|it = 'КОР';
															|pl = 'boxes';
															|tr = 'kutu'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "9111";
		Level3.Description = NStr("vi = 'Giường-ngày';
									|ru = 'Койко-день';
									|en = 'Bed-day'; fa = 'Bed-day';
									|it = 'Giorni-posto letto';
									|pl = 'Bed-day';
									|tr = 'Yatak-gün'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'giường. ngày';
											|ru = 'койк. дн';
											|en = 'bed days'; fa = 'bed days';
											|it = 'gg-posto letto';
											|pl = 'łużkodz';
											|tr = 'yatak. gün'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'GIƯỜNG NGÀY';
															|ru = 'КОЙК ДН';
															|en = 'BED DAY S'; fa = 'BED DAY S';
															|it = 'GG-POSTO LETTO';
															|pl = 'ŁUŻKODZ';
															|tr = 'YATAK GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "9113";
		Level3.Description = NStr("vi = 'Bệnh nhân-ngày';
									|ru = 'Пациенто-день';
									|en = 'Patient-day'; fa = 'Patient-day';
									|it = 'Giorni di ricovero';
									|pl = 'Patient-day';
									|tr = 'Hasta-gün'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'bệnh nhân. ngày';
											|ru = 'пациент. дн';
											|en = 'patient days'; fa = 'patient days';
											|it = 'gg di ricovero';
											|pl = 'pacjentodni';
											|tr = 'hasta. gün'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'BÊNH NHÂN NGÀY';
															|ru = 'ПАЦИЕНТ ДН';
															|en = 'PATIENT DAY S'; fa = 'PATIENT DAY S';
															|it = 'GG DI RICOVERO';
															|pl = 'PACJENTODNI';
															|tr = 'HASTA GÜN'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "9245";
		Level3.Description = NStr("vi = 'Bản ghi';
									|ru = 'Запись';
									|en = 'RECORD'; fa = 'RECORD';
									|it = 'Запись';
									|pl = 'RECORD';
									|tr = 'KAYIT'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Bản ghi';
											|ru = 'запись';
											|en = 'RECORD'; fa = 'RECORD';
											|it = 'запись';
											|pl = 'RECORD';
											|tr = 'KAYIT'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Bản ghi';
															|ru = 'ЗАПИСЬ';
															|en = 'RECORD'; fa = 'RECORD';
															|it = 'ЗАПИСЬ';
															|pl = 'RECORD';
															|tr = 'KAYIT'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "9246";
		Level3.Description = NStr("vi = 'Chứng từ';
									|ru = 'Документ';
									|en = 'Document'; fa = 'سند';
									|it = 'Documento';
									|pl = 'Document';
									|tr = 'Belge'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'chứng từ';
											|ru = 'докум';
											|en = 'docum'; fa = 'docum';
											|it = 'докум';
											|pl = 'docum';
											|tr = 'belge'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'chứng từ';
															|ru = 'ДОКУМ';
															|en = 'docum'; fa = 'docum';
															|it = 'ДОКУМ';
															|pl = 'docum';
															|tr = 'belge'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "NumberOfPieces";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "9491";
		Level3.Description = NStr("vi = 'Tờ in';
									|ru = 'Лист-оттиск';
									|en = 'Sheet-copy'; fa = 'Sheet-copy';
									|it = 'Foglio impronta di stampa';
									|pl = 'Sheet-copy';
									|tr = 'Yaprak-baskı'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'tờ in';
											|ru = 'лист. оттиск';
											|en = 'sheet copy'; fa = 'sheet copy';
											|it = 'foglio impronta di stampa';
											|pl = 'arkusz odbitek';
											|tr = 'yaprak. baskı'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'TỜ IN';
															|ru = 'ЛИСТ ОТТИСК';
															|en = 'SHEET COPY S'; fa = 'SHEET COPY S';
															|it = 'FOGLIO IMPRONTA DI STAMPA';
															|pl = 'ARKUSZ ODBITEK';
															|tr = 'YAPRAK BASKI'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "9501";
		Level3.Description = NStr("vi = 'Giờ đứng máy (toa tàu)';
									|ru = 'Вагоно (машино)-час';
									|en = 'Freight (car)-hour'; fa = 'Freight (car)-hour';
									|it = 'Ore di treno (macchina)';
									|pl = 'Wagono(maszyno) godzina';
									|tr = 'Tren (makine)-saat'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'GIỜ ĐỨNG MÁY (TOA TẦU)';
											|ru = 'ваг (маш) ч';
											|en = 'FREIGHT (CAR) H'; fa = 'FREIGHT (CAR) H';
											|it = 'h di treno(macchina)';
											|pl = 'FREIGHT (CAR) H';
											|tr = 'TREN (MAKİNE) SA'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'GIỜ ĐỨNG MÁY (TOA TẦU)';
															|ru = 'ВАГ (МАШ) Ч';
															|en = 'FREIGHT (CAR) H'; fa = 'FREIGHT (CAR) H';
															|it = 'h di treno(macchina)';
															|pl = 'wag (masz) h';
															|tr = 'TREN (MAKİNE) SA'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "9641";
		Level3.Description = NStr("vi = 'Giờ bay';
									|ru = 'Летный час';
									|en = 'Flight hour'; fa = 'Flight hour';
									|it = 'Ore di volo';
									|pl = 'Godzina lotu';
									|tr = 'Uçuş saati'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'giờ bay';
											|ru = 'летн. ч';
											|en = 'fhs'; fa = 'fhs';
											|it = 'h di volo';
											|pl = 'godz. lotu';
											|tr = 'uçuş. s'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'GIỜ BAY';
															|ru = 'ЛЕТН Ч';
															|en = 'FH'; fa = 'FH';
															|it = 'H DI VOLO';
															|pl = 'GODZ LOTU';
															|tr = 'UÇUŞ S'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "9803";
		Level3.Description = NStr("vi = 'Tỷ đô la';
									|ru = 'Миллиард долларов';
									|en = 'Billion dollars'; fa = 'Billion dollars';
									|it = 'Un miliardo di dollari';
									|pl = 'Miliard dolarów';
									|tr = 'Milyar dolar'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = '10^9 đô la';
											|ru = '10^9 доллар';
											|en = '10^9 USD'; fa = '10^9 USD';
											|it = '10^9 di dollari';
											|pl = '10^9 dolar';
											|tr = '10^9 dolar'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Tỷ đô la';
															|ru = 'МЛРД ДОЛЛАР';
															|en = 'BN USD'; fa = 'BN USD';
															|it = 'MLD DOLL';
															|pl = 'MLD DOLAR';
															|tr = 'MİLYAR DOLAR'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
		Level3 = Level2.Rows.Add();
		Level3.NumericCode = "9805";
		Level3.Description = NStr("vi = 'Đô la trên tấn';
									|ru = 'Доллар за тонну';
									|en = 'USD PER TON'; fa = 'USD PER TON';
									|it = 'Доллар за тонну';
									|pl = 'USD PER TON';
									|tr = 'TON BAŞINA DOLAR'", Common.DefaultLanguageCode());
		Level3.SymbolNational = Lower(NStr("vi = 'Đô la trên tấn';
											|ru = 'доллар за тонну';
											|en = 'USD PER TON'; fa = 'USD PER TON';
											|it = 'доллар за тонну';
											|pl = 'dolar za tonę';
											|tr = 'TON BAŞINA DOLAR'", Common.DefaultLanguageCode()));
		Level3.InternationalSymbol = "";
		Level3.CodeLetterDesignationNational = Upper(NStr("vi = 'Đô la trên tấn';
															|ru = 'ДОЛЛАР ЗА ТОННУ';
															|en = 'USD PER TON'; fa = 'USD PER TON';
															|it = 'ДОЛЛАР ЗА ТОННУ';
															|pl = 'USD PER TON';
															|tr = 'TON BAŞINA DOLAR'", Common.DefaultLanguageCode()));
		Level3.CodeLetterDesignationInternational = "";
		Level3.Numerator = 0;
		Level3.Denominator = 0;
		Level3.MeasuredValueType = "";
	EndIf;
	Level1 = ValueTree.Rows.Add();
	Level1.NumericCode = "";
	If LocalizationRFService Then
		Level1.Description = NStr(
			"vi = 'Đơn vị đo lường quốc tế không có trong bảng mã hiệu đơn vị đo lường';
			|ru = 'Международные единицы измерения, не включенные в ОКЕИ';
			|en = 'International units of measure not included in OKEI'; fa = 'International units of measure not included in OKEI';
			|it = 'Unità di misura internazionali non incluse nel Classificatore panrusso di unità di misura';
			|pl = 'Międzynarodowe jednostki miary, nie zawarte w klasyfikatorze jednostek miary';
			|tr = 'RÖBS''e dahil olmayan uluslararası ölçü birimleri'", Common.DefaultLanguageCode());
	Else
		Level1.Description = NStr(
			"vi = 'Đơn vị đo lường quốc tế khác';
			|ru = 'Прочие международные единицы измерения';
			|en = 'Other international units of measure'; fa = 'Other international units of measure';
			|it = 'Altre unità di misura internazionali';
			|pl = 'Pozostałe międzynarodowe jednostki miary';
			|tr = 'Diğer uluslararası ölçü birimleri'", Common.DefaultLanguageCode());
	EndIf;
	Level1.SymbolNational = "";
	Level1.InternationalSymbol = "";
	Level1.CodeLetterDesignationNational = "";
	Level1.CodeLetterDesignationInternational = "";
	Level1.Numerator = 0;
	Level1.Denominator = 0;
	Level1.MeasuredValueType = "";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị chiều dài';
								|ru = 'Единицы длины';
								|en = 'Units of length'; fa = 'Units of length';
								|it = 'Unità di lunghezza';
								|pl = 'Jednostki długości';
								|tr = 'Uzunluk birimleri'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "017";
	Level3.Description = NStr("vi = 'Hectomet';
								|ru = 'Гектометр';
								|en = 'Hectometer'; fa = 'Hectometer';
								|it = 'Ettometro';
								|pl = 'Hectometer';
								|tr = 'Hektometre'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "hm"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "HMT"; //@NON-NLS-1
	Level3.Numerator = 100;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Length";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "045";
	Level3.Description = NStr("vi = 'Dặm (cũ) (1609.344 m)';
								|ru = 'Миля (уставная) (1609,344 м)';
								|en = 'Statute mile (1,609.344 m)'; fa = 'Statute mile (1,609.344 m)';
								|it = 'Miglio (terrestre) (1609,344 m)';
								|pl = 'Mila (1609,344 m)';
								|tr = 'Mil (yasal) (1609.344 m)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "mile"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "SMI"; //@NON-NLS-1
	Level3.Numerator = 1609.344;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Length";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị diện tích';
								|ru = 'Единицы площади';
								|en = 'Units of area'; fa = 'Units of area';
								|it = 'Unità di area';
								|pl = 'Jednostki powierzchni';
								|tr = 'Alan birimleri'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "077";
	Level3.Description = NStr("vi = 'Mẫu Anh (4,840 thước vuông)';
								|ru = 'Акр (4840 квадратных ярдов)';
								|en = 'Acre (4,840 square yards)'; fa = 'Acre (4,840 square yards)';
								|it = 'Acro (4840 yard quadrati)';
								|pl = 'Akr (4840 jardów kwadratowych)';
								|tr = 'Dönüm (4840 metrekare)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "acre"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "ACR"; //@NON-NLS-1
	Level3.Numerator = 4046.86;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "079";
	Level3.Description = NStr("vi = 'Dặm vuông';
								|ru = 'Квадратная миля';
								|en = 'Square mile'; fa = 'Square mile';
								|it = 'Miglio quadrato';
								|pl = 'Mila kwadratowa';
								|tr = 'Mil kare'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "mile2"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "MIK"; //@NON-NLS-1
	Level3.Numerator = 2589988.11;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "AreaTypeOfMeasurement";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị thể tích';
								|ru = 'Единицы объема';
								|en = 'Units of volume'; fa = 'Units of volume';
								|it = 'Unità di volume';
								|pl = 'Jednostki objętości';
								|tr = 'Hacim birimleri'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "135";
	Level3.Description = NStr("vi = 'Ounce chất lỏng CK 3 (28,413 cm3)';
								|ru = 'Жидкостная унция СК 3 (28,413 см3)';
								|en = 'UK liquid ounce (28.413 cm3)'; fa = 'UK liquid ounce (28.413 cm3)';
								|it = 'Oncia liquida RU 3 (28,413 cm3)';
								|pl = 'Uncja objętości fl oz (28,413 cm3)';
								|tr = 'Sıvı ons BCC 3 (28,413 sm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "fl oz (UK)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "OZI"; //@NON-NLS-1
	Level3.Numerator = 28.413;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "136";
	Level3.Description = NStr("vi = 'Jill CK (0,142065 dm3)';
								|ru = 'Джилл СК (0,142065 дм3)';
								|en = 'UK gill (0.142065 dm3)'; fa = 'UK gill (0.142065 dm3)';
								|it = 'Gill RU (0,142065 dm3)';
								|pl = 'Gill (0,142065 dm3)';
								|tr = 'Gill BCC (0,142065 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "gill (UK)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "GII"; //@NON-NLS-1
	Level3.Numerator = 142.065;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "137";
	Level3.Description = NStr("vi = 'Pint CK (0,568262 dm3)';
								|ru = 'Пинта СК (0,568262 дм3)';
								|en = 'UK pint (0.568262 dm3)'; fa = 'UK pint (0.568262 dm3)';
								|it = 'Pinta RU (0,568262 dm3)';
								|pl = 'Pinta imperialna (0,568262 dm3)';
								|tr = 'Pint BCC (0,568262 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "pt (UK)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "PTI"; //@NON-NLS-1
	Level3.Numerator = 568.262;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "138";
	Level3.Description = NStr("vi = 'Góc tư CK (1,136523 dm3)';
								|ru = 'Кварта СК (1,136523 дм3)';
								|en = 'UK quart (1.136523 dm3)'; fa = 'UK quart (1.136523 dm3)';
								|it = 'Quarta RU (1,136523 dm3)';
								|pl = 'Kwarta (1,136523 dm3)';
								|tr = 'Kuart BCC (1,136523 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "qt (UK)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "QTI"; //@NON-NLS-1
	Level3.Numerator = 1136.523;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "139";
	Level3.Description = NStr("vi = 'Gallon CK (4,546092 dm3)';
								|ru = 'Галлон СК (4,546092 дм3)';
								|en = 'UK gallon (4.546092 dm3)'; fa = 'UK gallon (4.546092 dm3)';
								|it = 'Gallone RU (4,546092 dm3)';
								|pl = 'Galon angielski (4,546092 dm3)';
								|tr = 'Galon BCC (4,546092 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "gal (UK)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "GLI"; //@NON-NLS-1
	Level3.Numerator = 4546.092;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "140";
	Level3.Description = NStr("vi = 'Bushel CK (36,36874 dm3)';
								|ru = 'Бушель СК (36,36874 дм3)';
								|en = 'UK bushel (36.36874 dm3)'; fa = 'UK bushel (36.36874 dm3)';
								|it = 'Bushel RU (36,36874 dm3)';
								|pl = 'Buszel angielski (36,36874 dm3)';
								|tr = 'Buşel BCC (36,36874 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "bu (UK)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "BUI"; //@NON-NLS-1
	Level3.Numerator = 36368.74;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "141";
	Level3.Description = NStr("vi = 'Ounce chất lỏng Mỹ (29,5735 cm3)';
								|ru = 'Жидкостная унция США (29,5735 см3)';
								|en = 'US liquid ounce (29.5735 cm3)'; fa = 'US liquid ounce (29.5735 cm3)';
								|it = 'Oncia liquida USA (29,5735 cm3)';
								|pl = 'Uncja objętości USA (29,5735 cm3)';
								|tr = 'ABD sıvı onsu (29,5735 sm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "fl oz (US)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "OZA"; //@NON-NLS-1
	Level3.Numerator = 295.735;
	Level3.Denominator = 10000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "142";
	Level3.Description = NStr("vi = 'Jill Mỹ (0,118294 dm3)';
								|ru = 'Джилл США (0,118294 дм3)';
								|en = 'US gill (0.118294 dm3)'; fa = 'US gill (0.118294 dm3)';
								|it = 'Gill USA (0,118294 dm3)';
								|pl = 'Gill USA (0,118294 dm3)';
								|tr = 'Gill ABD (0,118294 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "gill (US)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "GIA"; //@NON-NLS-1
	Level3.Numerator = 118.294;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "143";
	Level3.Description = NStr("vi = 'Pint lỏng của Mỹ (0,473176 dm3)';
								|ru = 'Жидкостная пинта США (0,473176 дм3)';
								|en = 'US liquid pint (0.473176 dm3)'; fa = 'US liquid pint (0.473176 dm3)';
								|it = 'Pinta liquida USA (0,473176 dm3)';
								|pl = 'Kwarta amerykańska płynna (0,473176 dm3)';
								|tr = 'Sıvı pint ABD (0,473176 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "liq pt (US)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "PTL"; //@NON-NLS-1
	Level3.Numerator = 473.176;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "144";
	Level3.Description = NStr("vi = 'Quart chất lỏng Mỹ (0,946353 dm3)';
								|ru = 'Жидкостная кварта США (0,946353 дм3)';
								|en = 'US liquid quart (0.946353 dm3)'; fa = 'US liquid quart (0.946353 dm3)';
								|it = 'Quarta liquida USA (0,946353 dm3)';
								|pl = 'Kwarta amerykańska płynna (0,946353 dm3)';
								|tr = 'Sıvı kuart ABD (0,946353 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "liq qt (US)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "QTL"; //@NON-NLS-1
	Level3.Numerator = 946.353;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "145";
	Level3.Description = NStr("vi = 'Gallon chất lỏng Mỹ (3,78541 dm3)';
								|ru = 'Жидкостный галлон США (3,78541 дм3)';
								|en = 'US liquid gallon (3.8541 dm3)'; fa = 'US liquid gallon (3.8541 dm3)';
								|it = 'Gallone liquido USA (3,78541 dm3)';
								|pl = 'Galon płynny USA (3,78541 dm3)';
								|tr = 'Sıvı galon ABD (3,78541 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "gal (US)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "GLL"; //@NON-NLS-1
	Level3.Numerator = 3785.41;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "146";
	Level3.Description = NStr("vi = 'Thùng (dầu mỏ) Mỹ (158,987 dm3)';
								|ru = 'Баррель (нефтяной) США (158,987 дм3)';
								|en = 'US (oil) barrel (158.987 dm3)'; fa = 'US (oil) barrel (158.987 dm3)';
								|it = 'Barile (petrolio) USA (158,987 dm3)';
								|pl = 'Amerykańska baryłka (ropy) (158,987 dm3)';
								|tr = 'ABD varil (petrol) (158,987 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "barrel (US)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "BLL"; //@NON-NLS-1
	Level3.Numerator = 158.987;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "147";
	Level3.Description = NStr("vi = 'Pint chất khô Mỹ (0,55061 dm3)';
								|ru = 'Сухая пинта США (0,55061 дм3)';
								|en = 'US dry pint (0.55061 dm3)'; fa = 'US dry pint (0.55061 dm3)';
								|it = 'Pinta secca USA (0,55061 dm3)';
								|pl = 'Amerykańska pinta dla ciał sypkich (0,55061 dm3)';
								|tr = 'ABD kuru pint (0,55061 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "dry pt (US)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "PTD"; //@NON-NLS-1
	Level3.Numerator = 550.61;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "148";
	Level3.Description = NStr("vi = 'Quart chất khô Mỹ (1.101221 dm3)';
								|ru = 'Сухая кварта США (1,101221 дм3)';
								|en = 'US dry quart (1.101221 dm3)'; fa = 'US dry quart (1.101221 dm3)';
								|it = 'Quarta secca USA (1,101221 dm3)';
								|pl = 'Kwarta amerykańska dla ciał sypkich (1,101221 dm3)';
								|tr = 'ABD kuru pint (1,101221 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "dry qt (US)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "QTD"; //@NON-NLS-1
	Level3.Numerator = 1101.221;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "149";
	Level3.Description = NStr("vi = 'Gallon khô Mỹ (4,404884 dm3)';
								|ru = 'Сухой галлон США (4,404884 дм3)';
								|en = 'US dry gallon (4.404884 dm3)'; fa = 'US dry gallon (4.404884 dm3)';
								|it = 'Gallone secco USA (4,404884 dm3)';
								|pl = 'Galon amerykański dla ciał sypkich (4,404884 dm3)';
								|tr = 'Kuru galon ABD (4,404884 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "dry gal (US)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "GLD"; //@NON-NLS-1
	Level3.Numerator = 4404.884;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "150";
	Level3.Description = NStr("vi = 'Giạ Mỹ (35,2391 dm3)';
								|ru = 'Бушель США (35,2391 дм3)';
								|en = 'US bushel (35.2391 dm3)'; fa = 'US bushel (35.2391 dm3)';
								|it = 'Bushel USA (35,2391 dm3)';
								|pl = 'Buszel amerykański (35,2391 dm3)';
								|tr = 'Buşel ABD (35,2391 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "bu (US)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "BUA"; //@NON-NLS-1
	Level3.Numerator = 35239.1;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "151";
	Level3.Description = NStr("vi = 'Thùng chất khô của Mỹ (115,627 dm3)';
								|ru = 'Сухой баррель США (115,627 дм3)';
								|en = 'US dry barrel (115.627 dm3)'; fa = 'US dry barrel (115.627 dm3)';
								|it = 'Barile secco USA (115,627 dm3)';
								|pl = 'Amerykańska baryłka dla ciał sypkich (115,627 dm3)';
								|tr = 'ABD kuru varil (115,627 dm3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "bbl (US)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "BLD"; //@NON-NLS-1
	Level3.Numerator = 115.627;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "152";
	Level3.Description = NStr("vi = 'Tiêu chuẩn';
								|ru = 'Стандарт';
								|en = 'Standard'; fa = 'استاندارد';
								|it = 'Standard';
								|pl = 'Standard';
								|tr = 'Standart'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "WSD"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "153";
	Level3.Description = NStr("vi = 'Dây (3,63 m3)';
								|ru = 'Корд (3,63 м3)';
								|en = 'Cord (3.63 m3)'; fa = 'Cord (3.63 m3)';
								|it = 'Cord (3,63m3)';
								|pl = 'Kord (3,63 m3)';
								|tr = 'Kord (3,63 m3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "WCD"; //@NON-NLS-1
	Level3.Numerator = 3.63;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "VolumeM3";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "154";
	Level3.Description = NStr("vi = 'Nghìn feet (2,36 m3)';
								|ru = 'Тысячи бордфутов (2,36 м3)';
								|en = 'Thousand board feet (2.36 m3)'; fa = 'Thousand board feet (2.36 m3)';
								|it = 'Mille BFM (2,36 m3)';
								|pl = 'Tysiące stóp deskowych (2,36 m3)';
								|tr = 'Bin bord fit (2,36 m3)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "MBF"; //@NON-NLS-1
	Level3.Numerator = 2.36;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "VolumeM3";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị trọng lượng';
								|ru = 'Единицы массы';
								|en = 'Units of mass'; fa = 'Units of mass';
								|it = 'Unità di massa';
								|pl = 'Jednostki masy';
								|tr = 'Ağırlık birimleri'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "182";
	Level3.Description = NStr("vi = 'Net - tấn đăng ký';
								|ru = 'Нетто - регистровая тонна';
								|en = 'Net register tonnage'; fa = 'Net register tonnage';
								|it = 'Netto - tonnellata di registro';
								|pl = 'Tona rejestrowa netto';
								|tr = 'Net - kayıt tonu'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "NTT"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "183";
	Level3.Description = NStr("vi = 'Tấn đo (vận chuyển)';
								|ru = 'Обмерная (фрахтовая) тонна';
								|en = 'Freight ton'; fa = 'Freight ton';
								|it = 'Tonnellata d''ingombro';
								|pl = 'Tona mierzona (frachtowa)';
								|tr = 'Ölçülen (navlun) ton'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "SHT"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "184";
	Level3.Description = NStr("vi = 'Đo lường nước';
								|ru = 'Водоизмещение';
								|en = 'Displacement'; fa = 'Displacement';
								|it = 'Dislocamento';
								|pl = 'Displacement';
								|tr = 'Su itme'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "DPT"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "186";
	Level3.Description = NStr("vi = 'Foot Anh, Mỹ (0,45359237 kg)';
								|ru = 'Фунт СК, США (0,45359237 кг)';
								|en = 'Pound (0.45359237 kg)'; fa = 'Pound (0.45359237 kg)';
								|it = 'Libbra RU, USA (0,45359237 kg)';
								|pl = 'Funt USA (0,45359237 kg)';
								|tr = 'Pound BCC (0,45359237 kg)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "lb"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "LBR"; //@NON-NLS-1
	Level3.Numerator = 45359.237;
	Level3.Denominator = 100000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "187";
	Level3.Description = NStr("vi = 'Ounce CK, Mỹ (28,349523 g)';
								|ru = 'Унция СК, США (28,349523 г)';
								|en = 'Ounce (28.349523 g)'; fa = 'Ounce (28.349523 g)';
								|it = 'Oncia RU, USA (28,349523 g)';
								|pl = 'Uncja USA (28,349523 g)';
								|tr = 'Ons BCC, ABD (28,349523 gr)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "oz"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "ONZ"; //@NON-NLS-1
	Level3.Numerator = 28349.523;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "188";
	Level3.Description = NStr("vi = 'Drachma CK (1,771745 g)';
								|ru = 'Драхма СК (1,771745 г)';
								|en = 'UK drachma (1.771745 g)'; fa = 'UK drachma (1.771745 g)';
								|it = 'Dracma RU (1,771745 g)';
								|pl = 'Drachma (1,771745 g)';
								|tr = 'Drahmi BCC (1,771745 gr)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "dr"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "DRI"; //@NON-NLS-1
	Level3.Numerator = 1771.745;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "189";
	Level3.Description = NStr("vi = 'Grand CK, Hoa Kỳ (64,798910 mg)';
								|ru = 'Гран СК, США (64,798910 мг)';
								|en = 'Gran (64.798910 mg)'; fa = 'Gran (64.798910 mg)';
								|it = 'Grano RU, USA (64,798910 mg)';
								|pl = 'Gran USA(64,798910 mg)';
								|tr = 'Gren BCC, ABD (64,798910 gr)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "gn"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "GRN"; //@NON-NLS-1
	Level3.Numerator = 6479.891;
	Level3.Denominator = 100000000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "190";
	Level3.Description = NStr("vi = 'Đá CK (6,350293 kg)';
								|ru = 'Стоун СК (6,350293 кг)';
								|en = 'UK stone (6.350293 kg)'; fa = 'UK stone (6.350293 kg)';
								|it = 'Stone RU (6,350293 kg)';
								|pl = 'Kamień (6,350293 kg)';
								|tr = 'Taş BCC (6,350293 kg)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "st"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "STI"; //@NON-NLS-1
	Level3.Numerator = 6350.293;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "191";
	Level3.Description = NStr("vi = 'Cvarter CK (12,700586 kg)';
								|ru = 'Квартер СК (12,700586 кг)';
								|en = 'UK quarter (12.700586 kg)'; fa = 'UK quarter (12.700586 kg)';
								|it = 'Quarter RU (12,700586 kg)';
								|pl = 'Kwarter (12,700586 kg)';
								|tr = 'Çeyrek BCC (12,700586 kg)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "qtr"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "QTR"; //@NON-NLS-1
	Level3.Numerator = 12700.586;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "192";
	Level3.Description = NStr("vi = 'Cental CK (45.359237 kg)';
								|ru = 'Центал СК (45,359237 кг)';
								|en = 'UK cental (45.359237 kg)'; fa = 'UK cental (45.359237 kg)';
								|it = 'Cental RU (45,359237 kg)';
								|pl = 'Cetnar amerykański (45,359237 kg)';
								|tr = 'Sentner BCC (45,359237 kg)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "CNT"; //@NON-NLS-1
	Level3.Numerator = 45359.237;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "193";
	Level3.Description = NStr("vi = 'Centner Mỹ (45.3592 kg)';
								|ru = 'Центнер США (45,3592 кг)';
								|en = 'US centner (45.3592 kg)'; fa = 'US centner (45.3592 kg)';
								|it = 'Quintale USA (45,3592 kg)';
								|pl = 'Cetnar USA (45,3592 kg)';
								|tr = 'Sentner ABD (45,3592 kg)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "cwt"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "CWA"; //@NON-NLS-1
	Level3.Numerator = 45359.2;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "194";
	Level3.Description = NStr("vi = 'Centner dài CK (50,802345 kg)';
								|ru = 'Длинный центнер СК (50,802345 кг)';
								|en = 'Long hundredweight (50.802345 kg)'; fa = 'Long hundredweight (50.802345 kg)';
								|it = 'Quintale lungo RU (50,802345 kg)';
								|pl = 'Cetnar angielski (50,802345 kg)';
								|tr = 'Uzun sentner BCC (50,802345 kg)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "cwt (UK)"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "CWI"; //@NON-NLS-1
	Level3.Numerator = 50802.345;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "195";
	Level3.Description = NStr("vi = 'Tấn ngắn CK, Mỹ (0,90718474 t)';
								|ru = 'Короткая тонна СК, США (0,90718474 т)';
								|en = 'Short ton (0.90718474 t)'; fa = 'Short ton (0.90718474 t)';
								|it = 'Tonnellata corta RU, USA (0,90718474 t)';
								|pl = 'Krótka tona, USA (0,90718474 t)';
								|tr = 'Kısa ton BCC, ABD (0,90718474 t)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "sht"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "STN"; //@NON-NLS-1
	Level3.Numerator = 90718.474;
	Level3.Denominator = 100;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "196";
	Level3.Description = NStr("vi = 'Tấn dài CK, Mỹ (1,0160469 t)';
								|ru = 'Длинная тонна СК, США (1,0160469 т)';
								|en = 'Long ton (1.0160469 t)'; fa = 'Long ton (1.0160469 t)';
								|it = 'Tonnellata lunga RU, USA (1,0160469 t)';
								|pl = 'Długa tona, USA (1,0160469 t)';
								|tr = 'Uzun ton BCC, ABD (1,0160469 t)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "lt"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "LTN"; //@NON-NLS-1
	Level3.Numerator = 101604.69;
	Level3.Denominator = 100;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "197";
	Level3.Description = NStr("vi = 'Scrupole CK, Mỹ (1.295982 g)';
								|ru = 'Скрупул СК, США (1,295982 г)';
								|en = 'Scrupole (1.295982 g)'; fa = 'Scrupole (1.295982 g)';
								|it = 'Scrupul RU, USA (1,295982 g)';
								|pl = 'Skrupuł, USA (1,295982 g)';
								|tr = 'Scrupulum BCC, ABD (1,295982 gr)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "scr"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "SCR"; //@NON-NLS-1
	Level3.Numerator = 1295.982;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "198";
	Level3.Description = NStr("vi = 'Pennyweight CK, Mỹ (1.555174 g)';
								|ru = 'Пеннивейт СК, США (1,555174 г)';
								|en = 'Pennyweight (1.555174 g)'; fa = 'Pennyweight (1.555174 g)';
								|it = 'Pennyweight Ru, USA (1,555174 g)';
								|pl = 'Pennyweight, USA (1,555174 g)';
								|tr = 'Pennyweight BCC, ABD (1,555174 gr)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "dwt"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "DWT"; //@NON-NLS-1
	Level3.Numerator = 1555.174;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "199";
	Level3.Description = NStr("vi = 'Drachma СК (3,887935 g)';
								|ru = 'Драхма СК (3,887935 г)';
								|en = 'UK drachma (3.887935 g)'; fa = 'UK drachma (3.887935 g)';
								|it = 'Dracma RU (3,887935 g)';
								|pl = 'Drachma (3,887935 g)';
								|tr = 'Drahmi BCC (3,887935 gr)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "drm"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "DRM"; //@NON-NLS-1
	Level3.Numerator = 3887.935;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "200";
	Level3.Description = NStr("vi = 'Drachma Mỹ (3,887935 g)';
								|ru = 'Драхма США (3,887935 г)';
								|en = 'US drachma (3.887935 g)'; fa = 'US drachma (3.887935 g)';
								|it = 'Dracma USA (3,887935 g)';
								|pl = 'Drachma USA (3,887935 g)';
								|tr = 'Drahma ABD (3,887935 gr)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "DRA"; //@NON-NLS-1
	Level3.Numerator = 3887.935;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "201";
	Level3.Description = NStr("vi = 'Ounce CK, Mỹ (31.10348 g)
		|Troy ounce';
		|ru = 'Унция СК, США (31,10348 г)
		|Тройская унция';
		|en = 'Ounce (31.10348 g)
		|Troy ounce'; fa = 'Ounce (31.10348 g)
		|Troy ounce';
		|it = 'Oncia RU, USA (31,10348 g)
		|Oncia troy';
		|pl = 'Uncja, USA (31,10348 gr)
		|Uncja trojańska';
		|tr = 'Ons BCC, ABD (31,10348 gr)
		|Troy onsu'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "apoz"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "APZ"; //@NON-NLS-1
	Level3.Numerator = 31103.48;
	Level3.Denominator = 1000000;
	Level3.MeasuredValueType = "Weight";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "202";
	Level3.Description = NStr("vi = 'Bảng Troy Mỹ (373,242 g)';
								|ru = 'Тройский фунт США (373,242 г)';
								|en = 'US troy pound (373.242 g)'; fa = 'US troy pound (373.242 g)';
								|it = 'Libbra troy USA (373,242 g)';
								|pl = 'Funt trojański USA (373,242 g)';
								|tr = 'Troy poundu ABD (373,242 gr)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "LBT"; //@NON-NLS-1
	Level3.Numerator = 373.242;
	Level3.Denominator = 1000;
	Level3.MeasuredValueType = "Weight";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị kỹ thuật';
								|ru = 'Технические единицы';
								|en = 'Engineering units'; fa = 'Engineering units';
								|it = 'Unità di misura tecniche';
								|pl = 'Jednostki techniczne';
								|tr = 'Teknik birimler'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "213";
	Level3.Description = NStr("vi = 'Công suất hiệu dụng (245,7 watt)';
								|ru = 'Эффективная мощность (245,7 ватт)';
								|en = 'Effective power (245.7 W)'; fa = 'Effective power (245.7 W)';
								|it = 'Potenza effettiva (245,7 watt)';
								|pl = 'Moc użyteczna (245,7 wat)';
								|tr = 'Etkili güç (245,7 watt)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "B.h.p."; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "BHP"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "275";
	Level3.Description = NStr("vi = 'Đơn vị nhiệt của Anh (1.055 kJ)';
								|ru = 'Британская тепловая единица (1,055 кДж)';
								|en = 'British thermal unit (1.055 kJ)'; fa = 'British thermal unit (1.055 kJ)';
								|it = 'Unità termica britannica (1,055 kJ)';
								|pl = 'Brytyjska jednostka cieplna (1,055 kJ)';
								|tr = 'İngiliz ısı birimi (1.055 kJ)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "Btu"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "BTU"; //@NON-NLS-1
	Level3.Numerator = 3798000;
	Level3.Denominator = 1;
	Level3.MeasuredValueType = "Energy";
	Level2 = Level1.Rows.Add();
	Level2.NumericCode = "";
	Level2.Description = NStr("vi = 'Đơn vị kinh tế';
								|ru = 'Экономические единицы';
								|en = 'Economic units'; fa = 'Economic units';
								|it = 'Unità di misura economiche';
								|pl = 'Jednostki ekonomiczne';
								|tr = 'Ekonomik birimler'", Common.DefaultLanguageCode());
	Level2.SymbolNational = "";
	Level2.InternationalSymbol = "";
	Level2.CodeLetterDesignationNational = "";
	Level2.CodeLetterDesignationInternational = "";
	Level2.Numerator = 0;
	Level2.Denominator = 0;
	Level2.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "638";
	Level3.Description = NStr("vi = 'Tổng (144 chiếc.)';
								|ru = 'Гросс (144 шт.)';
								|en = 'Gross (144 pcs)'; fa = 'Gross (144 pcs)';
								|it = 'Grossa (144 pz.)';
								|pl = 'Gros (144 szt.)';
								|tr = 'Brüt (144 tane.)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "gr
		|144"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "GRO"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "731";
	Level3.Description = NStr("vi = 'Tổng lớn (12)';
								|ru = 'Большой гросс (12 гроссов)';
								|en = 'Great gross (12 gross)'; fa = 'Great gross (12 gross)';
								|it = 'Grande grossa (12 grosse)';
								|pl = 'Duży gros (12 grosów)';
								|tr = 'Büyük brüt (12 brüt)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "1728"; //@NON-NLS-1
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "GGR"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "738";
	Level3.Description = NStr("vi = 'Tiêu chuẩn ngắn (7200 đơn vị)';
								|ru = 'Короткий стандарт (7200 единиц)';
								|en = 'Short standard (7,200 matches)'; fa = 'Short standard (7,200 matches)';
								|it = 'Standard corto (7200 unità)';
								|pl = 'Krótki standard (7200 jednostek)';
								|tr = 'Kısa standart (7200 birim)'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "SST"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "NumberOfPieces";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "835";
	Level3.Description = NStr("vi = 'Gallon rượu có độ mạnh quy định';
								|ru = 'Галлон спирта установленной крепости';
								|en = 'Gallon of alcohol of specified strength'; fa = 'Gallon of alcohol of specified strength';
								|it = 'Un gallone di alcool di determinata gradazione';
								|pl = 'Galon alkoholu ustalonej koncentracji';
								|tr = 'Ayarlanmış alkol galonun gücü'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "PGL"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "851";
	Level3.Description = NStr("vi = 'Đơn vị quốc tế';
								|ru = 'Международная единица';
								|en = 'International unit'; fa = 'International unit';
								|it = 'Unità internazionale';
								|pl = 'Jednostka międzynarodowa';
								|tr = 'Uluslararası birim'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "NIU"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Level3 = Level2.Rows.Add();
	Level3.NumericCode = "853";
	Level3.Description = NStr("vi = 'Một trăm đơn vị quốc tế';
								|ru = 'Сто международных единиц';
								|en = 'Hundred international units'; fa = 'Hundred international units';
								|it = 'Cento unità internazionali';
								|pl = 'Sto jednostek międzynarodowych';
								|tr = 'Yüz uluslararası birim'", Common.DefaultLanguageCode());
	Level3.SymbolNational = "";
	Level3.InternationalSymbol = "";
	Level3.CodeLetterDesignationNational = "";
	Level3.CodeLetterDesignationInternational = "HIU"; //@NON-NLS-1
	Level3.Numerator = 0;
	Level3.Denominator = 0;
	Level3.MeasuredValueType = "";
	Return ValueTree;

EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf

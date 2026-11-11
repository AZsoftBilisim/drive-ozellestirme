
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Warehouse = Undefined;
	Premise = Undefined;
	Parameters.Property("Products", Products);
	If Parameters.Property("Warehouse",Warehouse) Then
		Parameters.Property("Premise",Premise);
		AddStorageUnit = Not WarehousesServer.UseBinLocationWarehousing(Warehouse,Premise)
	Else
		AddStorageUnit = True;
	EndIf;
	
	ShowMeasuredUnitsOfMeasure = Undefined;
	If Not Parameters.Property("ShowMeasuredUnitsOfMeasure", ShowMeasuredUnitsOfMeasure) Then
		ShowMeasuredUnitsOfMeasure = True;
	EndIf;
	
	If Not Parameters.Property("ShowCargoItems", ShowCargoItems) Then
		ShowCargoItems = False;
	EndIf;
	
	FillInTreeOfUnitsOfMeasurementOfPackages();
	
	StorageUnit = Common.ObjectAttributeValue(Products, "UnitOfMeasure");
	
	Items.GroupCreate.Visible = AccessRight("Insert", Metadata.Catalogs.PackagesAndUnitsOfMeasure);
	
	If Not Items.GroupCreate.Visible Then
		Return;
	EndIf;

	YouCanAddPackages = False;
	If ValueIsFilled(Products) Then
		ProductAttributes = Common.ObjectAttributesValues(Products, "UsePackages");
		YouCanAddPackages = ProductAttributes.UsePackages;
	EndIf;
	MeasuredValueType = Common.ObjectAttributeValue(StorageUnit, "MeasuredValueType");
	DimensionalTypesOfUnits = Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits();
	AddUnitsOfMeasurement = DimensionalTypesOfUnits.Find(MeasuredValueType) <> Undefined;
	Items.FormCreatePackaging.Visible = YouCanAddPackages;
	If Not (AddUnitsOfMeasurement
		Or ShowMeasuredUnitsOfMeasure
			And UnitsOfMeasureOfProductMeasure.Count() > 0) Then

		Items.GroupCreate.Visible = False;
		Items.CreatePackaging.Visible = YouCanAddPackages;

	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	If Items.PackagesAndUnitsOfMeasure.CurrentRow = Undefined Then
		Return;
	EndIf;
	SelectedTreeRow = PackagesAndUnitsOfMeasure.FindByID(Items.PackagesAndUnitsOfMeasure.CurrentRow);	
	If TypeOf(SelectedTreeRow.Ref) = Type("CatalogRef.PackagesAndUnitsOfMeasure") Then 
		If Not SelectedTreeRow.AcceptableFactor Then
			WarningText = 
				NStr("vi = 'Không hỗ trợ kiểm đếm ""[Ed1]"" trong ""[Ed2]"" đối với mặt hàng ""[Products]"" –
				|hệ số kiểm đếm quá cao.';
				|ru = 'Пересчет ""[Ed1]"" в ""[Ed2]"" для номенклатуры ""[Products]"" не поддерживается –
				|слишком большой коэффициент пересчета.';
				|en = 'Cannot convert [Ed1] to [Ed2] for [Products].
				|The conversion ratio is too big.'; fa = 'Cannot convert [Ed1] to [Ed2] for [Products].
				|The conversion ratio is too big.';
				|it = 'Il ricalcolo di ""[Ed1]"" in ""[Ed2]"" per l''articolo ""[Products]"" non è supportato -
				| coefficiente di ricalcolo troppo grande.';
				|pl = 'Przeliczenie ""[Ed1]"" na ""[Ed2]"" dla towaru ""[Products]"" nie jest obsługiwane -
				|współczynnik przeliczenia jest za wysoki.';
				|tr = 'Öğe için ""[Ed1]"" yeniden ""[Ed2]"" hesaplama ""[Products]"" desteklenmiyor - 
				|dönüştürme oranı çok yüksek.'");
			WarningText = StringFunctionsClientServer.InsertParametersIntoString(WarningText, 
				New Structure("Ed1, Ed2, Products", 
					String(SelectedTreeRow.Ref), String(StorageUnit), String(Products)));
			ShowMessageBox(, WarningText);
			Return;
		ElsIf StorageUnit = SelectedTreeRow.Ref Then
			NotifyChoice(PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
		Else
			NotifyChoice(SelectedTreeRow.Ref);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure CreatePackaging(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("Owner", Products);
	FillingValues.Insert("MeasuredValueType", PredefinedValue("Enum.TypesOfMeasuredValues.Package"));
	
	If Items.PackagesAndUnitsOfMeasure.CurrentData <> Undefined 
		And Items.PackagesAndUnitsOfMeasure.CurrentData.MeasuredValueType = PredefinedValue("Enum.TypesOfMeasuredValues.Package") Then
		
		FillingValues.Insert("Parent", Items.PackagesAndUnitsOfMeasure.CurrentData.Ref);
		
	EndIf;
	
	CreationParameters = New Structure("FillingValues", FillingValues);
	
	CallbackDescription = New CallbackDescription("CreatePackagingUnitMeasurementCompletion", ThisForm);
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.Form.PackageItemForm", CreationParameters, ThisForm,,,,CallbackDescription);
	
EndProcedure

&AtClient
Procedure CreateUnitOfMeasure(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("Owner", PredefinedValue("Catalog.PackagingGroups.BasicUnitsOfMeasure"));
	
	If Items.PackagesAndUnitsOfMeasure.CurrentData <> Undefined 
		And Items.PackagesAndUnitsOfMeasure.CurrentData.MeasuredValueType <> PredefinedValue("Enum.TypesOfMeasuredValues.Package") Then
		
		FillingValues.Insert("MeasuredValueType", Items.PackagesAndUnitsOfMeasure.CurrentData.MeasuredValueType);
		
	EndIf;
			
	CreationParameters = New Structure("FillingValues", FillingValues);
	
	CallbackDescription = New CallbackDescription("CreatePackagingUnitMeasurementCompletion", ThisForm);
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.Form.ItemFormUnitsOfMeasure", CreationParameters, ThisForm,,,,CallbackDescription);
	
EndProcedure

&AtClient
Procedure CreateAUnitOfMeasureFromClassifier(Command)
	
	FilterParameters = New Array;
	If Items.PackagesAndUnitsOfMeasure.CurrentData <> Undefined
		And ValueIsFilled(Items.PackagesAndUnitsOfMeasure.CurrentData.MeasuredValueType)
		And Items.PackagesAndUnitsOfMeasure.CurrentData.MeasuredValueType <> PredefinedValue("Enum.TypesOfMeasuredValues.Package") Then
		
		FilterParameters.Add(Items.PackagesAndUnitsOfMeasure.CurrentData.MeasuredValueType);
		
	ElsIf UnitsOfMeasureOfProductMeasure.Count() > 0 Then
		FilterParameters = UnitsOfMeasureOfProductMeasure.UnloadValues();
	EndIf;
	
	
	OpenBuiltInSelection(Undefined, FilterParameters);
	
EndProcedure

#EndRegion

#Region EventHandlersFormTablesAndUnitsOfMeasurement

&AtClient
Procedure UnitsOfMeasurementSelection(Item, RowSelected, Field, StandardProcessing)
	SelectedTreeRow = PackagesAndUnitsOfMeasure.FindByID(RowSelected);
	If TypeOf(SelectedTreeRow.Ref) = Type("CatalogRef.PackagesAndUnitsOfMeasure") Then 
		If Not SelectedTreeRow.AcceptableFactor Then
			WarningText = 
				NStr("vi = 'Không hỗ trợ kiểm đếm ""[Ed1]"" trong ""[Ed2]"" đối với mặt hàng ""[Products]"" –
				|hệ số chuyển đổi quá cao.';
				|ru = 'Пересчет ""[Ed1]"" в ""[Ed2]"" для номенклатуры ""[Products]"" не поддерживается –
				|слишком большой коэффициент пересчета.';
				|en = 'Cannot convert [Ed1] to [Ed2] for [Products].
				|The conversion ratio is too big.'; fa = 'Cannot convert [Ed1] to [Ed2] for [Products].
				|The conversion ratio is too big.';
				|it = 'Il ricalcolo di ""[Ed1]"" in ""[Ed2]"" per l''articolo ""[Products]"" non è supportato -
				| coefficiente di ricalcolo troppo grande.';
				|pl = 'Przeliczenie ""[Ed1]"" na ""[Ed2]"" dla towaru ""[Products]"" nie jest obsługiwane -
				|współczynnik przeliczenia jest za wysoki.';
				|tr = 'Öğe için ""[Ed1]"" yeniden ""[Ed2]"" hesaplama ""[Products]"" desteklenmiyor - 
				|dönüştürme oranı çok yüksek.'");
			WarningText = StringFunctionsClientServer.InsertParametersIntoString(WarningText, 
				New Structure("Ed1, Ed2, Products", 
					String(SelectedTreeRow.Ref), String(StorageUnit), String(Products)));
			ShowMessageBox(, WarningText);
			StandardProcessing = False;
		ElsIf StorageUnit = SelectedTreeRow.Ref Then
			NotifyChoice(PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
		Else
			NotifyChoice(SelectedTreeRow.Ref);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInTreeOfUnitsOfMeasurementOfPackages()
	
	UnitsOfMeasureOfProductMeasure.Clear();
	PackagesAndUnitsOfMeasure.GetItems().Clear();
	
	Query = New Query;
	QueryText = 	
	"SELECT
	|	InternalQuery.Ref AS Ref,
	|	InternalQuery.MeasuredValueType AS MeasuredValueType,
	|	InternalQuery.Order AS Order,
	|	TRUE AS AcceptableFactor
	|FROM
	|	(SELECT
	|		Products.UnitOfMeasure AS Ref,
	|		UNDEFINED AS MeasuredValueType,
	|		1 AS Order
	|	FROM
	|		Catalog.Products AS Products
	|	WHERE
	|		Products.Ref = &Products
	|		AND (&AddStorageUnit
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time))
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		PRESENTATION(VALUE(Enum.TypesOfMeasuredValues.Package)),
	|		VALUE(Enum.TypesOfMeasuredValues.Package),
	|		2
	|	FROM
	|		Catalog.Products AS Products
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.UsePackages
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		PRESENTATION(VALUE(Enum.TypesOfMeasuredValues.Weight)),
	|		VALUE(Enum.TypesOfMeasuredValues.Weight),
	|		3
	|	FROM
	|		Catalog.Products AS Products
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.WeightUse
	|		AND Products.YouCanSpecifyWeightInDocuments
	|		AND (&ShowMeasuredUnitsOfMeasure
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight))
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		PRESENTATION(VALUE(Enum.TypesOfMeasuredValues.VolumeM3)),
	|		VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
	|		4
	|	FROM
	|		Catalog.Products AS Products
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.VolumeUse
	|		AND Products.VolumeCanBeSpecifiedInDocuments
	|		AND (&ShowMeasuredUnitsOfMeasure
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3))
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		PRESENTATION(VALUE(Enum.TypesOfMeasuredValues.Length)),
	|		VALUE(Enum.TypesOfMeasuredValues.Length),
	|		5
	|	FROM
	|		Catalog.Products AS Products
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.LengthUse
	|		AND Products.YouCanSpecifyLengthInDocuments
	|		AND (&ShowMeasuredUnitsOfMeasure
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length))
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		PRESENTATION(VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)),
	|		VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement),
	|		6
	|	FROM
	|		Catalog.Products AS Products
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.AreaUse
	|		AND Products.AreaCanBeSpecifiedInDocuments
	|		AND (&ShowMeasuredUnitsOfMeasure
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement))
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		PRESENTATION(VALUE(Enum.TypesOfMeasuredValues.Capacity)),
	|		VALUE(Enum.TypesOfMeasuredValues.Capacity),
	|		7
	|	FROM
	|		Catalog.Products AS Products
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		PRESENTATION(VALUE(Enum.TypesOfMeasuredValues.Energy)),
	|		VALUE(Enum.TypesOfMeasuredValues.Energy),
	|		8
	|	FROM
	|		Catalog.Products AS Products
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		PRESENTATION(VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)),
	|		VALUE(Enum.TypesOfMeasuredValues.ElectricCharge),
	|		9
	|	FROM
	|		Catalog.Products AS Products
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		PRESENTATION(VALUE(Enum.TypesOfMeasuredValues.Time)),
	|		VALUE(Enum.TypesOfMeasuredValues.Time),
	|		10
	|	FROM
	|		Catalog.Products AS Products
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time)) AS InternalQuery
	|
	|ORDER BY
	|	InternalQuery.Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InternalQuery.Ref AS Ref,
	|	InternalQuery.Order AS Order,
	|	InternalQuery.ZoomRatio AS ZoomRatio,
	|	InternalQuery.AcceptableFactor AS AcceptableFactor
	|FROM
	|	(SELECT
	|		ProductPackages.Ref AS Ref,
	|		3 AS Order,
	|		&QueryTextPackagingFactor AS ZoomRatio,
	|		&RequestTextAvailabilityPackingFactor AS AcceptableFactor
	|	FROM
	|		Catalog.Products AS Products
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|			ON (Products.WeightUse)
	|				AND (Products.YouCanSpecifyWeightInDocuments)
	|				AND (ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight))
	|	WHERE
	|		Products.Ref = &Products
	|		AND (&ShowMeasuredUnitsOfMeasure
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductPackages.Ref,
	|		4,
	|		&QueryTextPackagingFactor,
	|		&RequestTextAvailabilityPackingFactor
	|	FROM
	|		Catalog.Products AS Products
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|			ON (Products.VolumeUse)
	|				AND (Products.VolumeCanBeSpecifiedInDocuments)
	|				AND (ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3))
	|	WHERE
	|		Products.Ref = &Products
	|		AND (&ShowMeasuredUnitsOfMeasure
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductPackages.Ref,
	|		5,
	|		&QueryTextPackagingFactor,
	|		&RequestTextAvailabilityPackingFactor
	|	FROM
	|		Catalog.Products AS Products
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|			ON (Products.LengthUse)
	|				AND (Products.YouCanSpecifyLengthInDocuments)
	|				AND (ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length))
	|	WHERE
	|		Products.Ref = &Products
	|		AND (&ShowMeasuredUnitsOfMeasure
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductPackages.Ref,
	|		6,
	|		&QueryTextPackagingFactor,
	|		&RequestTextAvailabilityPackingFactor
	|	FROM
	|		Catalog.Products AS Products
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|			ON (Products.AreaUse)
	|				AND (Products.AreaCanBeSpecifiedInDocuments)
	|				AND (ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement))
	|	WHERE
	|		Products.Ref = &Products
	|		AND (&ShowMeasuredUnitsOfMeasure
	|				OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductPackages.Ref,
	|		7,
	|		&QueryTextPackagingFactor,
	|		&RequestTextAvailabilityPackingFactor
	|	FROM
	|		Catalog.Products AS Products
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|			ON (ProductPackages.MeasuredValueType = Products.UnitOfMeasure.MeasuredValueType)
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductPackages.Ref,
	|		8,
	|		&QueryTextPackagingFactor,
	|		&RequestTextAvailabilityPackingFactor
	|	FROM
	|		Catalog.Products AS Products
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|			ON (ProductPackages.MeasuredValueType = Products.UnitOfMeasure.MeasuredValueType)
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductPackages.Ref,
	|		9,
	|		&QueryTextPackagingFactor,
	|		&RequestTextAvailabilityPackingFactor
	|	FROM
	|		Catalog.Products AS Products
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|			ON (ProductPackages.MeasuredValueType = Products.UnitOfMeasure.MeasuredValueType)
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
	|	UNION ALL
	|	
	|	SELECT
	|		ProductPackages.Ref,
	|		10,
	|		&QueryTextPackagingFactor,
	|		&RequestTextAvailabilityPackingFactor
	|	FROM
	|		Catalog.Products AS Products
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|			ON (ProductPackages.MeasuredValueType = Products.UnitOfMeasure.MeasuredValueType)
	|	WHERE
	|		Products.Ref = &Products
	|		AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time)) AS InternalQuery
	|
	|ORDER BY
	|	InternalQuery.Order,
	|	InternalQuery.AcceptableFactor DESC,
	|	InternalQuery.ZoomRatio DESC,
	|	InternalQuery.Ref.Description
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatPackages.Ref AS Ref,
	|	CatPackages.Numerator / CatPackages.Denominator AS ZoomRatio,
	|	TRUE AS AcceptableFactor
	|FROM
	|	Catalog.Products AS CatProducts
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS CatPackages
	|		ON (CASE
	|				WHEN CatProducts.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|					THEN CatPackages.Owner = CatProducts.Ref
	|				WHEN CatProducts.PackagingGroup <> VALUE(Catalog.PackagingGroups.EmptyRef)
	|					THEN CatPackages.Owner = CatProducts.PackagingGroup
	|				ELSE FALSE
	|			END)
	|WHERE
	|	CatProducts.Ref = &Products
	|	AND NOT CatPackages.DeletionMark
	|	AND CatPackages.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	CatPackages.Ref,
	|	CatPackages.Numerator / CatPackages.Denominator,
	|	TRUE
	|FROM
	|	Catalog.Products AS CatProducts
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS CatPackages
	|		ON (CASE
	|				WHEN CatProducts.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|					THEN CatPackages.Owner = CatProducts.Ref
	|				WHEN CatProducts.PackagingGroup <> VALUE(Catalog.PackagingGroups.EmptyRef)
	|					THEN CatPackages.Owner = CatProducts.PackagingGroup
	|				ELSE FALSE
	|			END)
	|WHERE
	|	CatProducts.Ref = &Products
	|	AND NOT CatPackages.DeletionMark
	|	AND &ShowCargoItems
	|	AND CatPackages.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|ORDER BY
	|	Ref HIERARCHY";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor", Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingFactorToSelect("ProductPackages", "Products"));
	QueryText = StrReplace(QueryText, "&RequestTextAvailabilityPackingFactor", Catalogs.PackagesAndUnitsOfMeasure.RequestTextAvailabilityFactorForPackageSelection("ProductPackages", "Products"));
	
	Query.Text = QueryText;
	                    
	Query.SetParameter("Products", Products);
	Query.SetParameter("ShowMeasuredUnitsOfMeasure", ShowMeasuredUnitsOfMeasure);
	Query.SetParameter("AddStorageUnit", AddStorageUnit);
	Query.SetParameter("ShowCargoItems", ShowCargoItems);

	Result = Query.ExecuteBatch();
	Roots = Result[0].Select();
	UnitsOfMeasurement = Result[1].Select();
	Packages = Result[2].Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	While Roots.Next() Do
		
		NewRowType = PackagesAndUnitsOfMeasure.GetItems().Add();
		FillPropertyValues(NewRowType, Roots); 
		
		If Roots.MeasuredValueType = Enums.TypesOfMeasuredValues.Package Then
			If Packages.Rows.Count() = 0 Then
				PackagesAndUnitsOfMeasure.GetItems().Delete(NewRowType);
			Else
				Packages.Rows.Sort("ZoomRatio", True);
				BypassTree(NewRowType, Packages.Rows);
			EndIf;
		ElsIf Roots.MeasuredValueType = Enums.TypesOfMeasuredValues.Weight
			Or Roots.MeasuredValueType = Enums.TypesOfMeasuredValues.VolumeM3
			Or Roots.MeasuredValueType = Enums.TypesOfMeasuredValues.Length
			Or Roots.MeasuredValueType = Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement
			Or Roots.MeasuredValueType = Enums.TypesOfMeasuredValues.Capacity
			Or Roots.MeasuredValueType = Enums.TypesOfMeasuredValues.Energy
			Or Roots.MeasuredValueType = Enums.TypesOfMeasuredValues.ElectricCharge
			Or Roots.MeasuredValueType = Enums.TypesOfMeasuredValues.Time Then
			
			While UnitsOfMeasurement.FindNext(New Structure("Order", Roots.Order)) Do
				NewLineUnitOfMeasurement = NewRowType.GetItems().Add();
				FillPropertyValues(NewLineUnitOfMeasurement, UnitsOfMeasurement);
				NewLineUnitOfMeasurement.MeasuredValueType = Roots.MeasuredValueType;
				
				If UnitsOfMeasureOfProductMeasure.FindByValue(Roots.MeasuredValueType) = Undefined Then
					UnitsOfMeasureOfProductMeasure.Add(Roots.MeasuredValueType);
				EndIf;
			EndDo;
			 
		EndIf;
		
	EndDo;
		
EndProcedure

&AtServer
Procedure BypassTree(Parent, Rows)
	
	If Rows.Count() = 0 Then
		Return;
	EndIf;
	
	For Each String In Rows Do
		NewRow = Parent.GetItems().Add();
		FillPropertyValues(NewRow, String);
		NewRow.MeasuredValueType = Enums.TypesOfMeasuredValues.Package;
		BypassTree(NewRow, String.Rows);
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenBuiltInSelection(Result, AdditionalParameters) Export
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter", AdditionalParameters);
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.Form.UnitOfMeasureClassifier",
		OpeningParameters,
		ThisObject,
		,
		,
		,
		New CallbackDescription("CreatePackagingUnitMeasurementCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure CreatePackagingUnitMeasurementCompletion(ReturnCode, Var_Parameters) Export
	
	FillInTreeOfUnitsOfMeasurementOfPackages();
	
	For Each String In PackagesAndUnitsOfMeasure.GetItems() Do 
		Items.PackagesAndUnitsOfMeasure.Expand(String.GetID(), True);
	EndDo;
	
	If TypeOf(ReturnCode) = Type("Structure")
		And ReturnCode.Property("NumberOfNewItems_") Then
		
		ProductsClient.NotifyAboutChangesInUnitSelectionList(ReturnCode.NumberOfNewItems_,
			ReturnCode.NewItems);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Không thể thay đổi màu văn bản cho các hệ số';
							|ru = 'Изменение цвета текста единиц измерения с недопустимым коэффициентом';
							|en = 'Text color for units with unsupported conversion ratio'; fa = 'Text color for units with unsupported conversion ratio';
							|it = 'Modifica del colore del testo delle unità di misura con un coefficiente non disponibile';
							|pl = 'Zmiana koloru tekstu jednostek miary z niedozwolonym klientem';
							|tr = 'Ölçü birimlerin metin rengini geçersiz bir faktörle değiştirme'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("PackagesAndUnitsOfMeasure");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PackagesAndUnitsOfMeasure.AcceptableFactor");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
EndProcedure

#EndRegion
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// It is intended for deleting product restriction groupings if these groupings do not contain detailed entries
// for products in the "Product restrictions"RS.
//
// Parameters:
//		ReferencesArrray - Array - contains links to elements in the list of product restrictions
//								that Need to be deleted.
//
Procedure DeleteUnusedDimensions(ReferencesArrray) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.Text =
		"SELECT
		|	CatGroups.Ref AS Ref
		|FROM
		|	Catalog.GoodsRestrictionGrouping AS CatGroups
		|		LEFT JOIN InformationRegister.ProductRestrictions AS TableProductRestrictions
		|		ON (TableProductRestrictions.Products <> VALUE(Catalog.Products.EmptyRef))
		|			AND (TableProductRestrictions.GroupingProductRestrictions = CatGroups.Ref)
		|WHERE
		|	CatGroups.Ref IN(&ReferencesArrray)
		|	AND TableProductRestrictions.GroupingProductRestrictions IS NULL";
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Selection = Query.Execute().Select();
	
	Set = InformationRegisters.ProductRestrictions.CreateRecordSet();
	Set.Filter.Products.Set(Catalogs.Products.EmptyRef());
	While Selection.Next() Do
		Set.Filter.GroupingProductRestrictions.Set(Selection.Ref);
		Set.Write();
		CatalogItem = Selection.Ref.GetObject(); // CatalogObject.GoodsRestrictionGrouping
		CatalogItem.Delete();
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

#Region Internal

// Returns the structure name of the new dimension
// Parameters:
//  SettingsKey - Structure - structure with fields:
//   *Format - CatalogRef.StoreFormats - 
//   *Warehouse - CatalogRef.Warehouses - 
//   *Category - CatalogRef.ProductCategories - 
//   *Products - CatalogRef.Products - 
// Returns:
//  Structure - structure with fields:
//   *Products - CatalogRef.Products -
//   *Warehouse - CatalogRef.Warehouses - 
//   *Description - String -
Function NameOfNewDefaultGrouping(SettingsKey) Export
	
	DimensionsTable = New ValueTable();
	DimensionsTable.Columns.Add("Products",
		New TypeDescription("CatalogRef.ProductCategories, CatalogRef.Products"));
	DimensionsTable.Columns.Add("Warehouse",
		New TypeDescription("CatalogRef.Warehouses, CatalogRef.StoreFormats"));
	DimensionsTable.Columns.Add("Order", New TypeDescription("Number"));
	
	If ValueIsFilled(SettingsKey.Warehouse)
		And Not GetFunctionalOption("UseProductCategories")
		And GetFunctionalOption("UseSeveralWarehouses") Then
		
		NewRow = DimensionsTable.Add();
		NewRow.Products  = Undefined;
		NewRow.Warehouse         = SettingsKey.Warehouse;
		NewRow.Order = 0;
		
	EndIf;
	
	If ValueIsFilled(SettingsKey.Format) And Not GetFunctionalOption("UseProductCategories") Then
		
		NewRow = DimensionsTable.Add();
		NewRow.Products  = Undefined;
		NewRow.Warehouse         = SettingsKey.Format;
		NewRow.Order = 1;
		
	EndIf;
	
	If ValueIsFilled(SettingsKey.Category) And Not GetFunctionalOption("UseStoreFormats") Then
		
		NewRow = DimensionsTable.Add();
		NewRow.Products  = SettingsKey.Category;
		NewRow.Warehouse         = Undefined;
		NewRow.Order = 2;
		
	EndIf;
	
	If ValueIsFilled(SettingsKey.Category) And ValueIsFilled(SettingsKey.Format) Then
		
		NewRow = DimensionsTable.Add();
		NewRow.Products  = SettingsKey.Category;
		NewRow.Warehouse         = SettingsKey.Format;
		NewRow.Order = 3;
		
	EndIf;
	
	If ValueIsFilled(SettingsKey.Category) And ValueIsFilled(SettingsKey.Warehouse) Then
		
		NewRow = DimensionsTable.Add();
		NewRow.Products  = SettingsKey.Category;
		NewRow.Warehouse         = SettingsKey.Warehouse;
		NewRow.Order = 4;
		
	EndIf;
	
	If ValueIsFilled(SettingsKey.Products)
		And (Not GetFunctionalOption("UseStoreFormats")
			Or Common.ObjectAttributeValue(SettingsKey.Products, "ItemsType")
				= Enums.ItemsTypes.Work_5) Then
		
		NewRow = DimensionsTable.Add();
		NewRow.Products  = SettingsKey.Products;
		NewRow.Warehouse         = Undefined;
		NewRow.Order = 5;
		
	EndIf;
	
	If ValueIsFilled(SettingsKey.Products) And ValueIsFilled(SettingsKey.Format) Then
		
		NewRow = DimensionsTable.Add();
		NewRow.Products  = SettingsKey.Products;
		NewRow.Warehouse         = SettingsKey.Format;
		NewRow.Order = 6;
		
	EndIf;
	
	DimensionsTable.Sort("Order");
	Products = Undefined;
	Warehouse        = Undefined;
	If DimensionsTable.Count() > 0 Then
		
		TableRow = DimensionsTable[DimensionsTable.Count() - 1];
		Products = TableRow.Products;
		Warehouse        = TableRow.Warehouse;
		NameTemplate = PerformanceGroup(Products, Warehouse);
		
	Else
		NameTemplate = NStr("vi = 'Mới';
							|ru = 'Новый';
							|en = 'New'; fa = 'جدید';
							|it = 'Nuovo';
							|pl = 'Nowy';
							|tr = 'Yeni'");
	EndIf;
	
	Query = New Query();
	Query.SetParameter("NameTemplate", NameTemplate + "%");
	Query.Text =
		"SELECT
		|	CatSettingsGroups.Description AS Description
		|FROM
		|	Catalog.GoodsRestrictionGrouping AS CatSettingsGroups
		|WHERE
		|	CatSettingsGroups.Description LIKE &NameTemplate";
	
	Number = -1;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NumberInDatabase = StringFunctionsClientServer.StringToNumber(StrReplace(Selection.Description, NameTemplate, ""));
		Number = Max(NumberInDatabase, Number);
		
	EndDo;
	ResultStructure1 = New Structure("Products, Warehouse, Description", Products, Warehouse,
		?(Number = -1, NameTemplate, NameTemplate + " " + String(Number + 1)));
	Return ResultStructure1;
	
EndFunction

#EndRegion

Function PerformanceGroup(Products, Warehouse)
	
	If Not ValueIsFilled(Products) And TypeOf(Warehouse) = Type("CatalogRef.StoreFormats") Then
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàng hóa bất kỳ trong kho có dạng ""%1""';
				|ru = 'Любые товары на складах формата ""%1""';
				|en = 'Any goods in warehouses of format ""%1""'; fa = 'Any goods in warehouses of format ""%1""';
				|it = 'Qualunque merce ai magazzini del formato ""%1""';
				|pl = 'Dowolne wiersze pozycji w magazynach w formacie ""%1""';
				|tr = 'Biçim ambarlarında bulunan herhangi bir ürün ""%1""'"), Warehouse);
		
	ElsIf Not ValueIsFilled(Products) And TypeOf(Warehouse) = Type("CatalogRef.Warehouses") Then
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàng hóa bất kỳ trong kho ""%1""';
				|ru = 'Любые товары на складе ""%1""';
				|en = 'Any goods in warehouse ""%1""'; fa = 'Any goods in warehouse ""%1""';
				|it = 'Qualunque merce al magazzino ""%1""';
				|pl = 'Dowolne wiersze pozycji w magazynie ""%1""';
				|tr = 'Ambardaki herhangi bir ürün ""%1""'"), Warehouse);
		
	ElsIf TypeOf(Products) = Type("CatalogRef.Products")
		And TypeOf(Warehouse) = Type("CatalogRef.StoreFormats") Then
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '""%1"" trong kho có dạng ""%2""';
				|ru = '""%1"" на складах формата ""%2""';
				|en = '""%1"" in warehouses of format ""%2""'; fa = '""%1"" in warehouses of format ""%2""';
				|it = '""%1"" ai magazzini del formato ""%2""';
				|pl = '""%1"" w magazynach w formacie ""%2""';
				|tr = '""%1"" biçim ambarlarında ""%2""'"), Products, Warehouse);
		
	ElsIf TypeOf(Products) = Type("CatalogRef.Products")
		And Not ValueIsFilled(Warehouse) Then
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '""%1"" trong kho bất kỳ';
				|ru = '""%1"" на любом складе';
				|en = '""%1"" in any warehouse'; fa = '""%1"" in any warehouse';
				|it = '""%1"" a qualunque magazzino';
				|pl = '""%1"" w dowolnym magazynie';
				|tr = '""%1"" herhangi bir ambarda'"), Products);
		
	ElsIf TypeOf(Products) = Type("CatalogRef.Products")
		And TypeOf(Warehouse) = Type("CatalogRef.StoreFormats") Then
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '""%1"" trong kho có dạng ""%2""';
				|ru = '""%1"" на складах формата ""%2""';
				|en = '""%1"" in warehouses of format ""%2""'; fa = '""%1"" in warehouses of format ""%2""';
				|it = '""%1"" ai magazzini del formato ""%2""';
				|pl = '""%1"" w magazynach w formacie ""%2""';
				|tr = '""%1"" biçim ambarlarında ""%2""'"), Products, Warehouse);
		
	ElsIf TypeOf(Products) = Type("CatalogRef.Products")
		And TypeOf(Warehouse) = Type("CatalogRef.Warehouses") Then
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '""%1"" với đặc tính bất kỳ trong kho ""%2""';
				|ru = '""%1"" с любой характеристикой на складе ""%2""';
				|en = '""%1"" with any variant in warehouse ""%2""'; fa = '""%1"" with any variant in warehouse ""%2""';
				|it = '""%1"" con qualsiasi caratteristica al magazzino ""%2""';
				|pl = '""%1"" z dowolną charakterystyką w magazynie ""%2""';
				|tr = '""%1"" ambardaki herhangi bir özellik ile ""%2""'"), Products, Warehouse);
		
	ElsIf TypeOf(Products) = Type("CatalogRef.ProductCategories")
		And Not ValueIsFilled(Warehouse) Then
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàng hóa có thể loại ""%1"" trong kho bất kỳ';
				|ru = 'Товары категории ""%1"" на любом складе';
				|en = 'Goods of category ""%1"" in any warehouse'; fa = 'Goods of category ""%1"" in any warehouse';
				|it = 'Le merci di categoria ""%1"" a qualunque magazzino';
				|pl = 'Wiersze pozycji kategorii ""%1"" w dowolnym magazynie';
				|tr = 'Herhangi bir ambarda ""%1"" ürün kategorileri'"), Products);
		
	ElsIf TypeOf(Products) = Type("CatalogRef.ProductCategories")
		And TypeOf(Warehouse) = Type("CatalogRef.StoreFormats") Then
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàng hóa có thể loại ""%1"" trong kho có khuôn dạng ""%2""';
				|ru = 'Товары категории ""%1"" на складах формата ""%2""';
				|en = 'Goods of category ""%1"" in warehouses of format ""%2""'; fa = 'Goods of category ""%1"" in warehouses of format ""%2""';
				|it = 'Le merci di categoria ""%1"" ai magazzini del formato ""%2""';
				|pl = 'Wiersze pozycji kategorii ""%1"" w magazynach formatu ""%2""';
				|tr = 'Biçim ""%1"" ambarlarında ürün kategorileri ""%2""'"), Products, Warehouse);
		
	ElsIf TypeOf(Products) = Type("CatalogRef.ProductCategories")
		And TypeOf(Warehouse) = Type("CatalogRef.Warehouses") Then
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàng hóa có thể loại ""%1"" trong kho ""%2""';
				|ru = 'Товары категории ""%1"" на складе ""%2""';
				|en = 'Goods of category ""%1"" in warehouse ""%2""'; fa = 'Goods of category ""%1"" in warehouse ""%2""';
				|it = 'Le merci di categoria ""%1"" al magazzino ""%2""';
				|pl = 'Wiersze pozycji kategorii ""%1"" w magazynie ""%2""';
				|tr = 'Ambarda ""%1"" ürün kategorileri ""%2""'"), Products, Warehouse);
		
	Else
		
		Presentation = NStr("vi = 'Mới';
							|ru = 'Новый';
							|en = 'New'; fa = 'جدید';
							|it = 'Nuovo';
							|pl = 'Nowy';
							|tr = 'Yeni'");
		
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		Presentation = StrReplace(Presentation, NStr("vi = 'trong kho bất kỳ';
													|ru = 'на любом складе';
													|en = 'in any warehouse'; fa = 'in any warehouse';
													|it = 'a qualunque magazzino';
													|pl = 'w dowolnym magazynie';
													|tr = 'herhangi bir ambarda'"), "");
		Presentation = TrimR(Presentation);
	EndIf;
	
	Return Presentation;
	
EndFunction

#EndRegion

#EndIf
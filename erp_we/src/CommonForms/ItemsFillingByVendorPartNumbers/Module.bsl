#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	CalledFormID = Parameters.UUID;
	PartnerSNomenclatureTable = GetFromTempStorage(Parameters.GoodsAddressInStorage);
	
	If Parameters.Property("FilterItemsType") Then
		FilterItemsType = Parameters.FilterItemsType;
		NewArray = New Array();
		NewParameter1 = New ChoiceParameter("Filter.ItemsType", FilterItemsType);
		NewArray.Add(NewParameter1);
		Items.GoodsProducts.ChoiceParameters = New FixedArray(NewArray);
	Else
		FilterItemsType = Undefined;
	EndIf;
	
	// Preparing the supplier's nomenclature for matching
	
	Query = New Query("
		|SELECT
		|	Goods.PartnerProducts AS Ref,
		|	Goods.LineNumber            AS LineNumber
		|INTO
		|	Goods
		|FROM
		|	&Goods AS Goods
		|;
		|SELECT
		|	Goods.Ref.SKU      AS ProductIDSearch,
		|	Goods.Ref.Description AS NameSearch,
		|	Goods.Ref              AS Ref,
		|	Goods.LineNumber         AS LineNumber
		|FROM
		|	Goods AS Goods
		|");
		
	Query.SetParameter("Goods", PartnerSNomenclatureTable);
	PartnerSNomenclatureTable = Query.Execute().Unload();
	
	For Each CurRow In PartnerSNomenclatureTable Do
		
		CurRow.ProductIDSearch = StrReplace(CurRow.ProductIDSearch, " ", "");
		CurRow.NameSearch = StrReplace(CurRow.NameSearch, " ", "");
		
	EndDo;
	
	// Preparing the nomenclature for comparison
	Query = New Query("
		|SELECT
		|	Products.SKU        AS ProductIDSearch,
		|	Products.Description   AS NameSearch,
		|	Products.Ref         AS Ref
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	NOT Products.IsFolder
		|	AND NOT Products.DeletionMark
		|	AND (&ThereIsOneTypeOfProduct = FALSE
		|		OR Products.ItemsType IN (&FilterItemsType))
		|");
		
	Query.SetParameter("FilterItemsType", FilterItemsType);
	Query.SetParameter("ThereIsOneTypeOfProduct", ValueIsFilled(FilterItemsType));
	ProductsTable = Query.Execute().Unload();
	
	For Each CurRow In ProductsTable Do
		
		CurRow.ProductIDSearch = StrReplace(CurRow.ProductIDSearch, " ", "");
		CurRow.NameSearch = StrReplace(CurRow.NameSearch, " ", "");
		
	EndDo;
	
	Query = New Query("
		|SELECT
		|	PartnerProducts.LineNumber         AS LineNumber,
		|	PartnerProducts.ProductIDSearch        AS ProductIDSearch,
		|	PartnerProducts.NameSearch   AS NameSearch,
		|	PartnerProducts.Ref              AS Ref
		|INTO PartnerProducts
		|FROM
		|	&PartnerProducts AS PartnerProducts
		|
		|INDEX BY
		|	NameSearch,
		|	ProductIDSearch
		|;
		|SELECT
		|	Products.ProductIDSearch        AS ProductIDSearch,
		|	Products.NameSearch   AS NameSearch,
		|	Products.Ref              AS Ref
		|INTO Products
		|FROM
		|	&Products AS Products
		|
		|INDEX BY
		|	NameSearch,
		|	ProductIDSearch
		|;
		|SELECT
		|	PartnerProducts.LineNumber           AS LineNumber,
		|	PartnerProducts.Ref                AS PartnerProducts,
		|	PartnerProducts.Ref.Products   AS PartnerProductsProducts,
		|	PartnerProducts.Ref.Characteristic AS ProductsAndCharacteristics_,
		|	PartnerProducts.Ref.Package       AS ProductsAndPackaging_,
		|	Products.Ref                          AS Products
		|FROM
		|	PartnerProducts AS PartnerProducts
		|LEFT JOIN
		|	Products
		|ON
		|	(PartnerProducts.ProductIDSearch = Products.ProductIDSearch AND PartnerProducts.ProductIDSearch <> """")
		|	OR (PartnerProducts.NameSearch = Products.NameSearch)
		|ORDER BY
		|	LineNumber
		|TOTALS BY
		|	LineNumber
		|");
		
	Query.SetParameter("PartnerProducts", PartnerSNomenclatureTable);
	Query.SetParameter("Products", ProductsTable);
	
	Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While Selection.Next() Do
		
		NewRow = Goods.Add();
		NewRow.LineNumber = Selection.LineNumber;
		SelectionOfProducts = Selection.Select();
		
		If SelectionOfProducts.Count() = 1 Then
			SelectionOfProducts.Next();
			NewRow.PartnerProducts = SelectionOfProducts.PartnerProducts;
			If ValueIsFilled(SelectionOfProducts.PartnerProductsProducts) Then
				NewRow.Products = SelectionOfProducts.PartnerProductsProducts;
				NewRow.Characteristic = SelectionOfProducts.ProductsAndCharacteristics_;
				NewRow.Package = SelectionOfProducts.ProductsAndPackaging_;
			ElsIf ValueIsFilled(SelectionOfProducts.Products) Then
				NewRow.Products = SelectionOfProducts.Products;
				NewRow.ProductsQuantityForSelection = NewRow.ProductsQuantityForSelection + 1;
				AddProductsForSelection(SelectionOfProducts.PartnerProducts, SelectionOfProducts.Products);
			EndIf;
		Else
			While SelectionOfProducts.Next() Do
				
				If Not ValueIsFilled(NewRow.PartnerProducts) Then
					NewRow.PartnerProducts = SelectionOfProducts.PartnerProducts;
					If ValueIsFilled(SelectionOfProducts.PartnerProductsProducts) Then
						NewRow.Products = SelectionOfProducts.PartnerProductsProducts;
						NewRow.Characteristic = SelectionOfProducts.ProductsAndCharacteristics_;
						NewRow.Package = SelectionOfProducts.ProductsAndPackaging_;
					EndIf;
				EndIf;
				
				If ValueIsFilled(SelectionOfProducts.Products) Then
					NewRow.ProductsQuantityForSelection = NewRow.ProductsQuantityForSelection + 1;
					AddProductsForSelection(SelectionOfProducts.PartnerProducts, SelectionOfProducts.Products);
				EndIf;
				
			EndDo;
		EndIf;
		
	EndDo;
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Goods,
		New Structure("FillInFeatureAttribute",
			FillInFeatureAttribute));
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit 
		 Or ForceCloseTheForm Then
		Return;
	EndIf;
	
	If Not MoveToDocument And Goods.Count() > 0 Then
		
		Cancel = True;
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
			NStr("vi = 'Mặt hàng chưa chuyển vào chứng từ. Chuyển?';
				|ru = 'Номенклатура не перенесена в документ. Перенести?';
				|en = 'Items are not transferred to the document. Transfer?'; fa = 'Items are not transferred to the document. Transfer?';
				|it = 'Articolo non trasferito nel documento. Trasferire?';
				|pl = 'Towar nie został przeniesiony do dokumentu. Przenieść?';
				|tr = 'Öğe belgeye aktarılmadı. Transfer et?'"),
			QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		
		If CheckFilling() Then
			
			MoveToDocument = True;
			GoodsAddressInStorage = PutItInTemporaryStorageOnServer();
			Close(GoodsAddressInStorage);
			
		EndIf;
		
	ElsIf UserAnswer = DialogReturnCode.No Then
		ForceCloseTheForm = True;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	MessageTemplate = NStr("vi = 'Chưa điền cột ""Đặc tính"" trong dòng %LineNumber% danh sách ""Hàng hóa"".';
							|ru = 'Не заполнена колонка ""Характеристика"" в строке %LineNumber% списка ""Товары"".';
							|en = 'Column ""Variant"" in line %LineNumber% of the ""Goods"" list is not filled in'; fa = 'Column ""Variant"" in line %LineNumber% of the ""Goods"" list is not filled in';
							|it = 'Colonna ""Caratteristica"" nella riga %LineNumber% dell''elenco ""Merce"" non compilata.';
							|pl = 'Nie wypełniono kolumny ""Характеристика"" w wierszu %LineNumber% listy ""Товары"".';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında  ""Varyant"" sütunu doldurulmadı.'");
	
	CurRowNumber = 1;
	For Each CurRow In Goods Do
		If ValueIsFilled(CurRow.Products) And CurRow.ItemVariantsAreUsed And Not ValueIsFilled(CurRow.Characteristic) Then
			MessageText = StrReplace(MessageTemplate, "%LineNumber%", CurRowNumber);
			CommonClientServer.MessageToUser(
				MessageText,
				,
				CommonClientServer.PathToTabularSection("Goods", CurRowNumber, "Characteristic"),
				,
				Cancel);
		EndIf;
		CurRowNumber = CurRowNumber + 1;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If Item.CurrentItem.Name = "GoodsProducts" And CurrentRow <> Undefined Then 
		ProductSelectionList = Items.GoodsProducts.ChoiceList;
		ProductSelectionList.Clear();
		
		CurPartnerProducts = Items.Goods.CurrentData.PartnerProducts;
		FoundRows = ProductsForSelection.FindRows(New Structure("PartnerProducts", CurPartnerProducts));
		For Each CurRow In FoundRows Do
			ProductSelectionList.Add(CurRow.Products, CurRow.PartnerProducts);
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	
	MoveToDocument = True;
	Close();
	
EndProcedure

&AtClient
Procedure MoveToDocument(Command)
	
	If CheckFilling() Then
		MoveToDocument = True;
		GoodsAddressInStorage = PutItInTemporaryStorageOnServer();
		Close(GoodsAddressInStorage);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, , 
																		     "Goods.ItemVariantsAreUsed");

EndProcedure

&AtServer
Procedure AddProductsForSelection(PartnerProducts, Products)
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("PartnerProducts", PartnerProducts);
	TheStructureOfTheSearch.Insert("Products", Products);
	FoundRows = ProductsForSelection.FindRows(TheStructureOfTheSearch);
	
	If FoundRows.Count() = 0 Then
		NewRow = ProductsForSelection.Add();
		NewRow.PartnerProducts = PartnerProducts;
		NewRow.Products = Products;
	EndIf;
	
EndProcedure

&AtServer
Function PutItInTemporaryStorageOnServer()
	
	RowsArray = New Array();
	For Each CurRow In Goods Do
		If ValueIsFilled(CurRow.Products) Then
			RowsArray.Add(CurRow);
		EndIf;
	EndDo;
	
	Return PutToTempStorage(Goods.Unload(RowsArray, "LineNumber,Products,Characteristic,Package"), CalledFormID);
	
EndFunction

#EndRegion

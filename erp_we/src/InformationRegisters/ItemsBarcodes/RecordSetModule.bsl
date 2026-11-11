#If Not MobileStandaloneServer Then

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	PreparingMeasurementsBeforeRecording(Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckFillingOfCharacteristic(NotCheckedAttributeArray, Cancel);
	CheckBatchCompletion(Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

Procedure PreparingMeasurementsBeforeRecording(Cancel)
	
	InsignificantCharacters = New Array;
	InsignificantCharacters.Add(Char(32));
	InsignificantCharacters.Add(Char(182));
	InsignificantCharacters.Add(Chars.NBSp);
	InsignificantCharacters.Add(Chars.CR);
	InsignificantCharacters.Add(Chars.VTab);
	InsignificantCharacters.Add(Chars.LF);
	InsignificantCharacters.Add(Chars.FF);
	InsignificantCharacters.Add(Chars.Tab);
	
	For Each SetRow In ThisObject Do
		If Not InsignificantCharacters.Find(Right(SetRow.Barcode, 1)) = Undefined Then
			SetRow.Barcode = TrimR(SetRow.Barcode);
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckFillingOfCharacteristic(NotCheckedAttributeArray, Cancel)
	
	If Not GetFunctionalOption("UseItemVariants") Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray.Add("Characteristic");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.Products AS Products
	|INTO LinesWithErrors
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	CASE
	|		WHEN CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|				OR CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|				OR CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CharacteristicNotFilledIn
	|FROM
	|	LinesWithErrors AS LinesWithErrors
	|WHERE
	|	CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)";
	
	Query.SetParameter("TableOfGoods", Unload(, "Products, Characteristic"));
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	MessageText	= NStr("vi = 'Chưa điền trường ""Đặc tính""';
							|ru = 'Поле ""Характеристика"" не заполнено';
							|en = '""Variant"" is not filled in'; fa = '""Variant"" is not filled in';
							|it = 'Il campo ""Caratteristica"" non è compilato';
							|pl = 'Pole ""Charakterystyka"" nie jest wypełnione';
							|tr = '""Varyant"" alanı doldurulmadı'");
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		If Not Selection.CharacteristicNotFilledIn Then
			Continue;
		EndIf;
		
		Common.MessageToUser(MessageText, Undefined, "Characteristic", "Record", Cancel);
	EndDo;
	
EndProcedure

Procedure CheckBatchCompletion(Cancel)
	
	If Not GetFunctionalOption("UseItemsBatchWarehouse") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.Products		AS Products,
	|	TableOfGoods.Characteristic	AS Characteristic,
	|	TableOfGoods.Series			AS Series,
	|	TableOfGoods.Package			AS Package
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND TableOfGoods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	TableOfGoods.Products		AS Products,
	|	TableOfGoods.Characteristic	AS Characteristic
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON TableOfGoods.Package = Packages.Ref
	|			AND Packages.Denominator <> 0
	|			AND Packages.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|WHERE
	|	CatalogProducts.ProductKind.SpecifyQuantityWhenRegisteringBatch = FALSE
	|	AND Packages.Numerator / Packages.Denominator <> 1";
	
	Query.SetParameter("TableOfGoods", Unload(, "Products, Characteristic, Series, Package"));
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	MessageTemplate = NStr("ru = 'Политика учета серий номенклатуры ""%1"" предусматривает, что серии указываются для каждого экземпляра. Укажите единичную упаковку.';
							|vi = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit.';
							|en = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit.'; fa = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit.';
							|it = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit.';
							|pl = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit.';
							|tr = '"" %1 "" öğesinin parti kayıt politikası, partilerin her birim için belirtilmesini öngörür. Lütfen tekli ambalaj belirtin.'");
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		ProductPresentation = ProductsClientServer.ProductPresentation(
									TrimAll(String(Selection.Products)),
									TrimAll(String(Selection.Characteristic)));
		
		MessageText = StrTemplate(MessageTemplate, ProductPresentation);
		
		Common.MessageToUser(MessageText, Undefined, "Package", "Record", Cancel);
	EndDo;
	
EndProcedure

#EndRegion

#EndIf

#EndIf
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Checks whether there is a match for a quality product with a low-quality product.
//
// Parameters:
//   Products - CatalogRef.Products - quality nomenclature;
//   LowQualityProduct - CatalogRef.Products - low-quality nomenclature.
//
// Returns:
//   Boolean - returns true if the corresponding is found.
//
Function CheckForGradation(Products, LowQualityProduct) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	AnotherQualityGoods.OtherQualityGoods AS LowQualityProduct
	|FROM
	|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|WHERE
	|	AnotherQualityGoods.Products = &Products
	|			AND AnotherQualityGoods.OtherQualityGoods = &OtherQualityGoods
	|			AND AnotherQualityGoods.QualityGradation = &QualityGradation";
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("OtherQualityGoods", LowQualityProduct);
	Query.SetParameter("QualityGradation", Common.ObjectAttributeValue(LowQualityProduct, "Quality"));
	Result = Query.Execute();
	ThereIsMatch = Not Result.IsEmpty();
	Return ThereIsMatch;
EndFunction

// Records the relationship between high-quality and low-quality nomenclature in the product information register.
//
// Parameters:
//   QualityGoods - CatalogRef.Products - quality nomenclature;
//   LowQualityProduct - CatalogRef.Products - low-quality nomenclature.
//
Procedure RecordLinkToProductOfDifferentQuality(QualityGoods, LowQualityProduct) Export
	
	MessageText = "";
	If Common.ObjectAttributeValue(LowQualityProduct, "Quality") = Enums.QualityLevels.New Then
		MessageText = NStr("vi = 'Không thể thiết lập tương ứng. Hàng hóa kém chất lượng không thể có chất lượng ""Mới""';
							|ru = 'Невозможно установить соответствие. Некачественный товар не может иметь качество ""Новый""';
							|en = 'Cannot set correspondence. Low-quality goods cannot have the ""New"" quality'; fa = 'Cannot set correspondence. Low-quality goods cannot have the ""New"" quality';
							|it = 'Impossibile impostare la corrispondenza. La merce di bassa qualità non può avere la qualità ""Nuovo""';
							|pl = 'Nie można ustanowić wartości. Towar o niskiej jakości nie może mieć jakość ""Nowy""';
							|tr = 'Uygunluğu tespit etmek mümkün değildir. Kalitesiz ürün ""Yeni"" kalitesine sahip olamaz'");
	ElsIf Common.ObjectAttributeValue(LowQualityProduct, "ItemsType") = Enums.ItemsTypes.OperationService Then
		MessageText = NStr("vi = 'Không thể thiết lập tương ứng. Hàng hóa không có chất lượng không thể có kiểu mặt hàng ""Dịch vụ""';
							|ru = 'Невозможно установить соответствие. Некачественный товар не может иметь тип номенклатуры ""Услуга""';
							|en = 'Cannot set correspondence. Low-quality goods cannot have item type ""Service""'; fa = 'Cannot set correspondence. Low-quality goods cannot have item type ""Service""';
							|it = 'Impossibile impostare la corrispondenza. La merce di bassa qualità non può avere il tipo di articoli ""Servizio""';
							|pl = 'Nie można ustanowić wartości. Towar o niskiej jakości nie może mieć typu pozycji ""Usługa""';
							|tr = 'Uygunluk tespiti mümkün değildir. Kalitesiz ürün ""Hizmet"" tipinde bir öğeye sahip olamaz'");
	ElsIf Common.ObjectAttributeValue(LowQualityProduct, "ItemsType") = Enums.ItemsTypes.Work_5 Then
		MessageText = NStr("vi = 'Không thể thiết lập tương ứng. Hàng hóa không có chất lượng không thể có kiểu mặt hàng ""Công việc""';
							|ru = 'Невозможно установить соответствие. Некачественный товар не может иметь тип номенклатуры ""Работа""';
							|en = 'Cannot set correspondence. Low-quality goods cannot have item type ""Work""'; fa = 'Cannot set correspondence. Low-quality goods cannot have item type ""Work""';
							|it = 'Impossibile impostare la corrispondenza. La merce di bassa qualità non può avere il tipo di articoli ""Lavoro""';
							|pl = 'Nie można ustawić zgodności. Towar o niskiej jakości nie może mieć typu nomenklatury ""Praca""';
							|tr = 'Eşleştirme yapmak mümkün değildir. Kalitesiz ürün ""İş"" öğe tipine sahip olamaz'");
	EndIf;
	
	If ValueIsFilled(MessageText) Then
		CommonClientServer.MessageToUser(MessageText);
		Return
	EndIf;
		
	If Common.ObjectAttributeValue(QualityGoods, "Quality") <> Enums.QualityLevels.New Then
		RequestForMatchingProducts = New Query;
		RequestForMatchingProducts.SetParameter("OtherQualityGoods", QualityGoods);
		RequestForMatchingProducts.Text = 
		"SELECT
		|	AnotherQualityGoods.Products AS Products
		|FROM
		|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
		|WHERE
		|	AnotherQualityGoods.OtherQualityGoods = &OtherQualityGoods";
		Result = RequestForMatchingProducts.Execute();
		If Result.IsEmpty() Then
			ErrorMessageTextTemplate = NStr("vi = 'Không thể tìm thấy hàng hóa chất lượng tương ứng với hàng hóa %LowQualityProduct%';
											|ru = 'Невозможно найти качественный товар соответствующий товару %LowQualityProduct%';
											|en = 'Cannot find high-quality goods which correspond to goods %LowQualityProduct%'; fa = 'Cannot find high-quality goods which correspond to goods %LowQualityProduct%';
											|it = 'Impossibile trovare una merce di qualità corrispondente alla merce %LowQualityProduct%';
											|pl = 'Nie można znaleźć produktu jakościowego, odpowiadającego produktowi %LowQualityProduct%';
											|tr = 'Ürün %LowQualityProduct%% ile eşleşen kaliteli ürün bulunamıyor'");
			MessageText = StrReplace(ErrorMessageTextTemplate, "%LowQualityProduct%", Common.ObjectAttributeValue(LowQualityProduct, "Description"));
			CommonClientServer.MessageToUser(MessageText);
			Return;
		Else
			Selection = Result.Select();
			Selection.Next();
			QualityGoods = Selection.Products;
		EndIf;
	EndIf;
	
	InformationRegisterEntry = InformationRegisters.AnotherQualityGoods.CreateRecordManager();
	InformationRegisterEntry.Products 	= QualityGoods;
	InformationRegisterEntry.OtherQualityGoods = LowQualityProduct;
	InformationRegisterEntry.QualityGradation = Common.ObjectAttributeValue(LowQualityProduct, "Quality");
	InformationRegisterEntry.Write();
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CatProducts.ThereAreGoodsOfOtherQuality AS ThereAreProductsOfDifferentQualityInDatabase,
	|	CASE
	|		WHEN AnotherQualityGoods.OtherQualityGoods IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreGoodsOfDifferentQualityInFact
	|FROM
	|	Catalog.Products AS CatProducts
	|		LEFT JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|		ON CatProducts.Ref = AnotherQualityGoods.Products
	|WHERE
	|	CatProducts.Ref = &Products
	|	AND CatProducts.ThereAreGoodsOfOtherQuality <> CASE
	|			WHEN AnotherQualityGoods.OtherQualityGoods IS NULL 
	|				THEN FALSE
	|			ELSE TRUE
	|		END";
	
	Query.SetParameter("Products",QualityGoods);	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Object = QualityGoods.GetObject();
		Object.ThereAreGoodsOfOtherQuality = Selection.ThereAreGoodsOfDifferentQualityInFact;		
		Object.Write();
	EndIf;
	
EndProcedure

// Returns a new item for a low-quality item.
//
// Parameters:
//   OwnGoods - CatalogRef.Products - low-quality nomenclature.
//
// Returns:
//   CatalogRef.Products - the nomenclature of the new quality.
//
Function GetOriginalQualityGoods(OwnGoods) Export
	If Common.ObjectAttributeValue(OwnGoods, "Quality") <> Enums.QualityLevels.New Then
		QualityGoods = Undefined;
		RequestForQualityProduct = New Query;
		RequestForQualityProduct.SetParameter("Products", OwnGoods);
		RequestForQualityProduct.Text =
		"SELECT
		|	AnotherQualityGoods.Products AS QualityGoods
		|FROM
		|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
		|WHERE
		|	AnotherQualityGoods.Products.Quality = VALUE(Enum.QualityLevels.New)
		|	AND AnotherQualityGoods.OtherQualityGoods = &Products";
		Selection = RequestForQualityProduct.Execute().Select();
		While Selection.Next() Do
			QualityGoods = Selection.QualityGoods;
		EndDo;
		Return QualityGoods;
	Else 
		Return OwnGoods;
	EndIf;
EndFunction

#EndRegion
	
#EndIf
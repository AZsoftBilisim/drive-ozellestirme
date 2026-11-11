#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then 
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Goods = ThisObject.Unload();
	DefectiveGoodsColumn = Goods.Columns.OtherQualityGoods; // ValueTableColumn
	DefectiveGoodsColumn.Name = "ProductsRecordingAsReceived";
	Goods.Columns.Add("LineNumber", New TypeDescription("Number"));
	
	ProductsServer.CheckTypeOfProductDescription(ThisObject, Cancel,, Goods);
	
	If Not GetFunctionalOption("UseSummaryAccountingOfLowQualityGoods") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	Goods.Products AS Products,
		|	Goods.ProductsRecordingAsReceived AS OtherQualityGoods
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.OtherQualityGoods,
		|	COUNT(DISTINCT NestedQuery.Products) AS Products
		|FROM
		|	(SELECT
		|		Goods.OtherQualityGoods AS OtherQualityGoods,
		|		Goods.Products AS Products
		|	FROM
		|		Goods AS Goods
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		AnotherQualityGoods.OtherQualityGoods,
		|		AnotherQualityGoods.Products
		|	FROM
		|		Goods AS Goods
		|			INNER JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
		|			ON Goods.OtherQualityGoods = AnotherQualityGoods.OtherQualityGoods) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.OtherQualityGoods
		|
		|HAVING
		|	COUNT(DISTINCT NestedQuery.Products) > 1";
		
		Query.SetParameter("Goods", Goods); 
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			MessageText = NStr("vi = 'Không nên gán mặt hàng ""%OtherQualityGoods%"" với hơn một mặt hàng có chất lượng gốc.';
								|ru = 'Нельзя связывать номенклатуру ""%OtherQualityGoods%"" более чем с одной номенклатурой исходного качества.';
								|en = 'Cannot link items ""%OtherQualityGoods%"" to more than one products of original quality.'; fa = 'Cannot link items ""%OtherQualityGoods%"" to more than one products of original quality.';
								|it = 'Impossibile associare l''articolo ""%OtherQualityGoods%"" a più di un articolo di qualità originale.';
								|pl = 'Nie można powiązać nomenklatury ""%OtherQualityGoods%"" z więcej, niż jedną nomenklaturą oryginalnej jakości.';
								|tr = '""%OtherQualityGoods%"" öğesini orijinal kalitede birden fazla öğe ile ilişkilendirilmemeli.'");	
			MessageText = StrReplace(MessageText, "%OtherQualityGoods%", Selection.OtherQualityGoods);
			Cancel = True;
			CommonClientServer.MessageToUser(MessageText);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
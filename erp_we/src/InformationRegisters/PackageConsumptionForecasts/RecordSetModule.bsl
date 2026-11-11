#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray.Add("Characteristic");
	NotCheckedAttributeArray.Add("Series");
	NotCheckedAttributeArray.Add("Premise");
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	Query = New Query;
	QueryText =
	"SELECT
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Premise AS Premise,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO LinesWithErrors
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	(TableOfGoods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|			OR TableOfGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			OR TableOfGoods.Premise = VALUE(Catalog.Warerooms.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN LinesWithErrors.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				AND (CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					OR CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					OR CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CharacteristicNotFilledIn,
	|	CASE
	|		WHEN LinesWithErrors.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|				AND LinesWithErrors.BatchesIndicationStatus <> 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SeriesNotFilledIn,
	|	CASE
	|		WHEN LinesWithErrors.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|				AND CAST(LinesWithErrors.Warehouse AS Catalog.Warehouses).UseWarerooms
	|				AND &Date >= CAST(LinesWithErrors.Warehouse AS Catalog.Warehouses).StartDateOfWareroomUse
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS RoomIsNotFilled
	|FROM
	|	LinesWithErrors AS LinesWithErrors
	|WHERE
	|	(CASE
	|				WHEN LinesWithErrors.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|						AND (CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|							OR CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|							OR CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|			OR CASE
	|				WHEN LinesWithErrors.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|						AND LinesWithErrors.BatchesIndicationStatus <> 0
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|			OR CASE
	|				WHEN LinesWithErrors.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|						AND CAST(LinesWithErrors.Warehouse AS Catalog.Warehouses).UseWarerooms
	|						AND &Date >= CAST(LinesWithErrors.Warehouse AS Catalog.Warehouses).StartDateOfWareroomUse
	|					THEN TRUE
	|				ELSE FALSE
	|			END)";
	
	Query.Text = QueryText;
	
	Query.SetParameter("TableOfGoods", ThisObject.Unload(,"LineNumber,Products,Characteristic,Series,BatchesIndicationStatus,Warehouse,Premise"));
	Query.SetParameter("Date", CurrentSessionDate());
	MessageTextCharacteristics = NStr("vi = 'Chưa điền trường ""Đặc tính""';
										|ru = 'Поле ""Характеристика"" не заполнено';
										|en = '""Variant"" is not filled in'; fa = '""Variant"" is not filled in';
										|it = 'Il campo ""Caratteristica"" non è compilato';
										|pl = 'Pole ""Charakterystyka"" nie jest wypełnione';
										|tr = '""Özellik"" alanı doldurulmadı'");
	MessageTextSeries          = NStr("vi = 'Chưa điền trường ""Sê-ri""';
										|ru = 'Поле ""Серия"" не заполнено';
										|en = '""Batch"" is required'; fa = '""Batch"" is required';
										|it = 'Il campo ""Serie"" non è compilato';
										|pl = 'Pole ""Seria"" nie jest wypełnione';
										|tr = '""Parti"" alanı doldurulmadı'");
	TextOfMessageRoom      = NStr("vi = 'Chưa điền trường ""Nhà kho""';
									|ru = 'Поле ""Помещение"" не заполнено';
									|en = '""Wareroom"" is not filled in'; fa = '""Wareroom"" is not filled in';
									|it = 'Il campo ""collocamento"" non è compilato';
									|pl = 'Pole ""Pomieszczenie"" nie jest wypełnione';
									|tr = '""Alan"" alanı doldurulmadı'");
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If Selection.CharacteristicNotFilledIn Then
			CommonClientServer.MessageToUser(MessageTextCharacteristics,,"Characteristic","Record",Cancel);
		EndIf;
		
		If Selection.SeriesNotFilledIn Then
			CommonClientServer.MessageToUser(MessageTextSeries,,"Series","Record",Cancel);
		EndIf;
		
		If Selection.RoomIsNotFilled Then
			CommonClientServer.MessageToUser(TextOfMessageRoom,,"Premise","Record",Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
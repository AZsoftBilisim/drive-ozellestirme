#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	AttributesNotToCheck.Add("Goods.QuantityAccordingToAccountingData");
	AttributesNotToCheck.Add("Goods.Quantity_Actual");
		
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, AttributesNotToCheck, Cancel);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.PhysicalCountOfInventoryInOperation);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, AttributesNotToCheck);

	PerformAFillInCheck(CheckedAttributes, AttributesNotToCheck, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Users.CurrentUser();
	
	Documents.PhysicalCountOfInventoryInOperation.FillInAccountingData(ThisObject, Goods);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocumentBeforeFillingItOut()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

Procedure PerformAFillInCheck(CheckedAttributes, AttributesNotToCheck, Cancel)
	
	CheckAbsenceOfDuplicatesInTablePart(Cancel);
	
	If StartDateOfInventory > EndDateOfInventory
		And EndDateOfInventory <> '000101010000' Then
		
		MessageText = NStr("vi = 'Ngày bắt đầu kiểm kê không được muộn hơn ngày kết thúc kiểm kê';
							|ru = 'Начало инвентаризации должно быть не позже окончания';
							|en = 'The physical inventory count start must not be later than the end'; fa = 'The physical inventory count start must not be later than the end';
							|it = 'L''avvio dell''inventariazione non deve essere successivo alla fine';
							|pl = 'Rozpoczęcie inwentaryzacji powinno być nie później niż zakończenie';
							|tr = 'Envanterin başlangıcı sondan daha geç olmamalıdır'");
		Common.MessageToUser(MessageText, Ref, "Object.StartDateOfInventory",, Cancel);
	EndIf;
	
	MessageTemplate = NStr("vi = 'Trong dòng %1 đã chỉ ra số kiểm kê. Nếu tiến hành kế toán kiểm kê thì số lượng cần hơn 1.';
							|ru = 'В строке %1 указан инвентарный номер. Если ведется инвентарный учет, то количество должно быть 1.';
							|en = 'Inventory number is specified in line %1. If inventory accounting is kept, the quantity must be 1.'; fa = 'Inventory number is specified in line %1. If inventory accounting is kept, the quantity must be 1.';
							|it = 'В строке %1 указан инвентарный номер. Если ведется инвентарный учет, то количество должно быть 1.';
							|pl = 'Inventory number is specified in line %1. If inventory accounting is kept, the quantity must be 1.';
							|tr = '%1 satırında envanter numarasını belirtilmiştir. Envanter kayıtları tutuluyorsa miktar 1 olmalıdır.'");
	
	For Each RowData In Goods Do
		
		If ValueIsFilled(RowData.AssetID)
			And RowData.Quantity_Actual <> 1
			And RowData.Quantity_Actual <> 0 Then
			
			MessageText = StrTemplate(MessageTemplate, Format(RowData.LineNumber, "NG="));
			Field = CommonClientServer.PathToTabularSection("Goods", RowData.LineNumber, "Quantity_Actual");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckAbsenceOfDuplicatesInTablePart(Cancel)
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.AssetID AS AssetID,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.Individual AS Individual
	|
	|INTO TTProducts_1
	|
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Products,
	|	AssetID,
	|	Series,
	|	Characteristic,
	|	Individual,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.LineNumber AS LineNumber,
	|	CAST(TTProducts_1.Products AS Catalog.Products).Presentation AS ProductsPresentation,
	|	CAST(TTProducts_1.Characteristic AS Catalog.ItemsCharacteristics).Presentation AS CharacteristicPresentation,
	|	MIN(DoubleProducts.LineNumber) AS LineNumberDouble
	|FROM
	|	(SELECT
	|		TTProducts_1.AssetID AS AssetID,
	|		TTProducts_1.Products AS Products,
	|		TTProducts_1.Characteristic AS Characteristic,
	|		TTProducts_1.Series AS Series,
	|		CASE
	|			WHEN &CheckIndividual
	|				THEN TTProducts_1.Individual
	|			ELSE UNDEFINED
	|		END AS Individual,
	|		MIN(TTProducts_1.LineNumber) AS LineNumber
	|	FROM
	|		TTProducts_1 AS TTProducts_1
	|
	|	WHERE
	|		TTProducts_1.Products <> VALUE(Catalog.Products.EmptyRef)
	|
	|	GROUP BY
	|		TTProducts_1.AssetID,
	|		TTProducts_1.Products,
	|		TTProducts_1.Characteristic,
	|		TTProducts_1.Series,
	|		CASE
	|			WHEN &CheckIndividual
	|				THEN TTProducts_1.Individual
	|			ELSE UNDEFINED
	|		END
	|
	|	) AS TTProducts_1
	|
	|		INNER JOIN TTProducts_1 AS DoubleProducts
	|		ON (DoubleProducts.AssetID = TTProducts_1.AssetID)
	|			AND (DoubleProducts.Products = TTProducts_1.Products)
	|			AND (DoubleProducts.Characteristic = TTProducts_1.Characteristic)
	|			AND (DoubleProducts.Series = TTProducts_1.Series)
	|			AND (NOT &CheckIndividual OR DoubleProducts.Individual = TTProducts_1.Individual)
	|			AND (DoubleProducts.LineNumber <> TTProducts_1.LineNumber)
	|
	|GROUP BY
	|	TTProducts_1.LineNumber,
	|	CAST(TTProducts_1.Products AS Catalog.Products).Presentation,
	|	CAST(TTProducts_1.Characteristic AS Catalog.ItemsCharacteristics).Presentation
	|
	|ORDER BY
	|	LineNumber
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Goods", Goods.Unload());
	Query.SetParameter("CheckIndividual", Not ValueIsFilled(Individual));
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	MessageTemplate = NStr("vi = 'Vật tư ""%1"" đã được chọn trong dòng %2.';
							|ru = 'ТМЦ ""%1"" уже выбран в строке %2.';
							|en = 'The ""%1"" inventory is already selected in line %2.'; fa = 'The ""%1"" inventory is already selected in line %2.';
							|it = 'Bene materiale ""%1"" già selezionato nella riga %2.';
							|pl = 'Towar ""%1"" jest już wybrany w wierszu %2.';
							|tr = '""%1"" stokları %2 satırında zaten seçilidir.'");
	
	While Selection.Next() Do
	
		ProductPresentation = ProductsClientServer.ProductPresentation(Selection.ProductsPresentation, Selection.CharacteristicPresentation);
				
		MessageText = StrTemplate(MessageTemplate, ProductPresentation, Format(Selection.LineNumberDouble, "NG="));
		Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "Products");
		Common.MessageToUser(MessageText,, Field, "Object", Cancel);
	
	EndDo;
		
EndProcedure

#EndRegion

#EndIf

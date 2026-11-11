#Region Private

// Sets the Status for the specified item research cards.
//
// Parameters:
//   HighlightedLinks - Array of CatalogRef.GoodsResearchSheets	 - links to research maps of items for which the Status needs to be changed
//   StatusValue - String - new Status value for item research cards
//
// Returns:
//   Number - number of processed item research cards
Function SetStatusOfGoodsResearchCards(HighlightedLinks, StatusValue) Export

	NewStatus = Enums.StatusesOfGoodsResearchSheet[StatusValue];
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	GoodsResearchSheets.Ref,
	|	GoodsResearchSheets.Description,
	|	GoodsResearchSheets.DeletionMark,
	|	GoodsResearchSheets.Status,
	|	COUNT(GoodsResearchSheetsGoods.LineNumber) AS Count
	|FROM
	|	Catalog.GoodsResearchSheets AS GoodsResearchSheets
	|		LEFT JOIN Catalog.GoodsResearchSheets.Goods AS GoodsResearchSheetsGoods
	|		ON GoodsResearchSheets.Ref = GoodsResearchSheetsGoods.Ref
	|WHERE
	|	GoodsResearchSheets.Status <> &NewStatus
	|	AND GoodsResearchSheets.Ref IN (&HighlightedLinks)
	|GROUP BY
	|	GoodsResearchSheets.Ref,
	|	GoodsResearchSheets.Description,
	|	GoodsResearchSheets.DeletionMark,
	|	GoodsResearchSheets.Status";
	
	Query.SetParameter("HighlightedLinks", HighlightedLinks);
	Query.SetParameter("NewStatus",      NewStatus);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ProcessedItemsCount = 0;
	
	If NewStatus = Enums.StatusesOfGoodsResearchSheet.Draft Then
		StorageAddress = PutToTempStorage(Undefined);
	EndIf;
	
	While Selection.Next() Do
		
		If Selection.DeletionMark Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr(
				"ru = 'Нельзя изменить статус помеченной на удаление карты исследования товаров ""%1"".';
				|vi = 'Cannot change status of the ""%1"" goods research sheet because it is marked for deletion.';
				|en = 'Cannot change status of the ""%1"" goods research sheet because it is marked for deletion.'; fa = 'Cannot change status of the ""%1"" goods research sheet because it is marked for deletion.';
				|it = 'Cannot change status of the ""%1"" goods research sheet because it is marked for deletion.';
				|pl = 'Cannot change status of the ""%1"" goods research sheet because it is marked for deletion.';
				|tr = 'Silinmek üzere işaretlenmiş ürün inceleme kartının ""%1"" durumu değiştirilemez.'"),
				Selection.Description);

			Common.MessageToUser(MessageText, Selection.Ref);
			Continue;
		EndIf;

		If NewStatus = Enums.StatusesOfGoodsResearchSheet.Valid Then

			If Selection.Count = 0 Then

				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr(
				"ru = 'Нельзя изменить статус на ""Действует"" с незаданной областью применения для карты исследования товаров ""%1"".';
				|vi = 'Cannot change the status to ""Valid"" with an unspecified scope for the ""%1"" goods research sheet.';
				|en = 'Cannot change the status to ""Valid"" with an unspecified scope for the ""%1"" goods research sheet.'; fa = 'Cannot change the status to ""Valid"" with an unspecified scope for the ""%1"" goods research sheet.';
				|it = 'Cannot change the status to ""Valid"" with an unspecified scope for the ""%1"" goods research sheet.';
				|pl = 'Cannot change the status to ""Valid"" with an unspecified scope for the ""%1"" goods research sheet.';
				|tr = 'Uygulama alanı belirtilmemiş ürün inceleme kartı  ""%1"" için statü ""Geçerli"" olarak değiştirilemez.'"),
					Selection.Description);

				Common.MessageToUser(MessageText, Selection.Ref);
				Continue;
			EndIf;

		EndIf;
		
		BeginTransaction();
		
		Try

			Block = New DataLock;
			LockItem = Block.Add("Catalog.GoodsResearchSheets");
			LockItem.SetValue("Ref", Selection.Ref);
			Block.Lock();

			CatObject = Selection.Ref.GetObject();

			If NewStatus = Enums.StatusesOfGoodsResearchSheet.Draft Then
				CheckParameters = New Structure("Object", Selection.Ref);
				Catalogs.GoodsResearchSheets.CheckObjectUsage(CheckParameters, StorageAddress);
				ThereAreRefs = GetFromTempStorage(StorageAddress);
				If ThereAreRefs Then
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Карта исследования товаров ""%1"" используется. Установка статуса ""Действует"" допускается только в форме карты исследования товаров.';
							|vi = 'The ""%1"" goods research sheet is in use. You can set the ""Valid"" status only in the goods research sheet form.';
							|en = 'The ""%1"" goods research sheet is in use. You can set the ""Valid"" status only in the goods research sheet form.'; fa = 'The ""%1"" goods research sheet is in use. You can set the ""Valid"" status only in the goods research sheet form.';
							|it = 'The ""%1"" goods research sheet is in use. You can set the ""Valid"" status only in the goods research sheet form.';
							|pl = 'The ""%1"" goods research sheet is in use. You can set the ""Valid"" status only in the goods research sheet form.';
							|tr = 'Ürün inceleme kartı ""%1"" kullanılıyor. ""Geçerli"" statüsü atanması sadece ürün inceleme kartı formunda yapılabilir.'"),
						CatObject.Description);

					Common.MessageToUser(MessageText, Selection.Ref);
					RollbackTransaction();
					Continue;
				EndIf;
			EndIf;

			CatObject.Status = NewStatus;
			If CatObject.CheckFilling() Then
				CatObject.Write();
				ProcessedItemsCount = ProcessedItemsCount + 1;
			EndIf;
			CommitTransaction();

		Except
			RollbackTransaction();
		EndTry;
		
	EndDo;
	
	Return ProcessedItemsCount;

EndFunction

#EndRegion

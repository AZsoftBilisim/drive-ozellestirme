
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Records data on quality control requirements in the register
//
// Parameters:
//  GoodsResearchSheet  - CatalogRef.GoodsResearchSheets
//  ClearingRegisterEntries - Boolean - specifies whether to write data, or only clear existing data in the register
//  CallingFromUpdateHandler - Boolean - call mode from the update handler
//
Procedure RecordQualityControlCards(GoodsResearchSheet, ClearingRegisterEntries = False, CallingFromUpdateHandler = False) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = QueryTextGoodsResearchSheets(CallingFromUpdateHandler);
	Query.SetParameter("GoodsResearchSheet", GoodsResearchSheet);
	Query.SetParameter("ReadRequirements", Not ClearingRegisterEntries);

	RecordBlocking = New DataLock;
	LockItem = RecordBlocking.Add("InformationRegister.GoodsResearchSheets");
	LockItem.SetValue("GoodsResearchSheet", GoodsResearchSheet);

	BeginTransaction();

	Try

		RecordBlocking.Lock();

		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then

			SelectionOfRequirements = QueryResult.Select(QueryResultIteration.ByGroups,
				"GoodsResearchSheet");
			While SelectionOfRequirements.Next() Do

				RecordSet = InformationRegisters.GoodsResearchSheets.CreateRecordSet();
				RecordSet.Filter.GoodsResearchSheet.Set(SelectionOfRequirements.GoodsResearchSheet);

				Selection = SelectionOfRequirements.Select(QueryResultIteration.Linear);
				While Selection.Next() Do

					If ValueIsFilled(Selection.ProductKind) Then
						NewRow = RecordSet.Add();
						FillPropertyValues(NewRow, Selection);
					EndIf;

				EndDo;

				If CallingFromUpdateHandler Then
					InfobaseUpdate.WriteData(RecordSet);
				Else
					RecordSet.Fill(Undefined);
					RecordSet.Write();
				EndIf;

			EndDo;

		EndIf;

		CommitTransaction();

	Except

		RollbackTransaction();

		MessageText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Common.MessageToUser(MessageText);

		Raise;

	EndTry;

EndProcedure
	
// Returns a list of available survey maps for the specified item and feature.
//
// Parameters:
//   Products - CatalogRef.Products - Link to the item item
//   Characteristic - CatalogRef.ItemsCharacteristics - Link to the item description
//
// Returns:
//   Array of CatalogRef.GoodsResearchSheets - List of available study maps
Function AvailableListOfItemResearchCards(Products, Characteristic) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	GoodsResearchSheets.GoodsResearchSheet AS Ref
		|FROM
		|	InformationRegister.GoodsResearchSheets AS GoodsResearchSheets
		|WHERE
		|	GoodsResearchSheets.ProductKind = &ProductKind
		|	AND GoodsResearchSheets.Products = &Products
		|	AND GoodsResearchSheets.Characteristic = &Characteristic";
	
	Query.SetParameter("ProductKind", Common.ObjectAttributeValue(Products, "ProductKind"));
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	
	QueryResult = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return QueryResult;
	
EndFunction

#EndRegion

#Region Private

#Region Other

Function QueryTextGoodsResearchSheets(CallingFromUpdateHandler = False)
	
	QueryText = "SELECT
	|	T.Ref AS GoodsResearchSheet,
	|	CASE
	|		WHEN T.ProductKind IS NULL
	|			THEN ISNULL(T.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef))
	|		WHEN T.ProductKind = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN ISNULL(T.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef))
	|		ELSE T.ProductKind
	|	END AS ProductKind,
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	T.Ref.Status AS Status
	|INTO TTProducts_1
	|FROM
	|	Catalog.GoodsResearchSheets.Goods AS T
	|WHERE
	|	T.Ref IN (&GoodsResearchSheet)
	|	AND T.Ref.Status = VALUE(Enum.StatusesOfGoodsResearchSheet.Valid)
	|	AND &ReadRequirements
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsResearchSheets.Ref                AS GoodsResearchSheet,
	|	GoodsResearchSheets.Control           AS Control,
	|	GoodsResearchSheets.TemplatesFilterOption AS TemplatesFilterOption,
	|	GoodsResearchSheets.TamplatesNumber    AS TamplatesNumber,
	|	GoodsResearchSheets.TemplatesPercentage       AS TemplatesPercentage,
	|	ItemsT.*
	|FROM
	|	Catalog.GoodsResearchSheets AS GoodsResearchSheets
	|		LEFT JOIN TTProducts_1 AS ItemsT
	|		ON GoodsResearchSheets.Ref = ItemsT.GoodsResearchSheet
	|WHERE
	|	GoodsResearchSheets.Ref IN (&GoodsResearchSheet)
	|TOTALS
	|BY
	|	GoodsResearchSheets.Ref";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

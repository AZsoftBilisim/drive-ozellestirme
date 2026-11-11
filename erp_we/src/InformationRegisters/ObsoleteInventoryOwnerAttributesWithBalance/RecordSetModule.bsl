#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure UpdateRecords(SelectionByStockType = Undefined,  ResultStorageAddress_ = "") Export
	
	If SelectionByStockType <> Undefined
		And TypeOf(SelectionByStockType) = Type("Array")
		And SelectionByStockType.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory
	|INTO TTObsoleteInventoryTypes
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	(InventoryKinds.Obsolete1
	|			OR InventoryKinds.IsDuplicate)
	|	AND (&ForAllTypesOfStocks
	|			OR InventoryKinds.Ref IN (&SelectionByStockType))
	|	AND NOT InventoryKinds.SaleOfAnotherCompanyInventory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTObsoleteInventoryTypesWithBalances
	|FROM
	|	(SELECT
	|		CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		CompanyGoodsBalance.Organization AS Organization,
	|		CompanyGoodsBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		CompanyGoodsBalance.CCDNumber AS CCDNumber
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(
	|				,
	|				InventoryOwnerAttribute IN
	|					(SELECT
	|						TT.Ref
	|					FROM
	|						TTObsoleteInventoryTypes AS TT)) AS CompanyGoodsBalance) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	SUM(NestedQuery.Control) > 0 AS Add
	|FROM
	|	(SELECT
	|		TTObsoleteInventoryTypesWithBalances.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		1 AS Control
	|	FROM
	|		TTObsoleteInventoryTypesWithBalances AS TTObsoleteInventoryTypesWithBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ObsoleteInventoryOwnerAttributesWithBalance.InventoryOwnerAttribute,
	|		-1
	|	FROM
	|		InformationRegister.ObsoleteInventoryOwnerAttributesWithBalance AS ObsoleteInventoryOwnerAttributesWithBalance
	|			LEFT JOIN TTObsoleteInventoryTypes AS TTObsoleteInventoryTypes
	|			ON ObsoleteInventoryOwnerAttributesWithBalance.InventoryOwnerAttribute = TTObsoleteInventoryTypes.Ref
	|	WHERE
	|		(NOT TTObsoleteInventoryTypes.Ref IS NULL
	|				OR NOT(ObsoleteInventoryOwnerAttributesWithBalance.InventoryOwnerAttribute.Obsolete1
	|						OR ObsoleteInventoryOwnerAttributesWithBalance.InventoryOwnerAttribute.IsDuplicate)
	|				OR ObsoleteInventoryOwnerAttributesWithBalance.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory)) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.InventoryOwnerAttribute
	|
	|HAVING
	|	SUM(NestedQuery.Control) <> 0";
	
	If SelectionByStockType <> Undefined 
		And TypeOf(SelectionByStockType) = Type("Array") Then
		
		Query.SetParameter("ForAllTypesOfStocks", False);
		Query.SetParameter("SelectionByStockType", SelectionByStockType);
	Else
		Query.SetParameter("ForAllTypesOfStocks", True);
		Query.SetParameter("SelectionByStockType", New Array);
	EndIf;		
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		Set = InformationRegisters.ObsoleteInventoryOwnerAttributesWithBalance.CreateRecordSet();
		Set.Filter.InventoryOwnerAttribute.Set(Selection.InventoryOwnerAttribute);
		
		If Selection.Add Then
			SetRow = Set.Add();
			SetRow.InventoryOwnerAttribute = Selection.InventoryOwnerAttribute;
		EndIf;
		
		Set.Write();
		
	EndDo;
	
EndProcedure

#Region InfobaseUpdate

#EndRegion

#EndRegion
	
#EndIf
////////////////////////////////////////////////////////////////////////////////////////
// Comparison of the nomenclature of the Counteragent Service Provider: 
// a mechanism for comparing the nomenclature of counterparties with the nomenclature of the information base.
//
////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns a list of the current item of the counterparty, taking into account the filter by owner, item, characteristic, and package.
//
// Parameters:
//  ItemOwner - DefinedType.ItemOwnerEDL       - the owner for which you want to create a list of choices.
//  Products         - DefinedType.EDLProducts               - the range of the company to filter items of the company.
//  Characteristic       - DefinedType.ItemsCharacteristicEDL - characteristics of the company's nomenclature
//                                                                         for filtering the counterparty's nomenclature.
//  Package             - DefinedType.PackageEDLItems       - packaging an enterprise item
//                                                                         to filter the counterparty item.
//
// Returns:
//   Array of CatalogRef.ProductCrossReferences - the counterparty's nomenclature suitable for filtering conditions.
//
Function CreateListForSelectingCounterpartyProducts(Val ItemOwner, Val Products, Val Characteristic, Val Package) Export
	
	Query = New Query;
	Query.SetParameter("ItemOwner", ItemOwner);
	Query.SetParameter("Products"        , Products);
	Query.SetParameter("Characteristic"      , Characteristic);
	Query.SetParameter("Package"            , Package);

	ProductCrossReferencesMappingOverridable.RequestTextForCounterpartyProductSelectionList(Query);
	
	If IsBlankString(Query.Text) Then
		Query.Text = 
		"SELECT ALLOWED
		|	ProductCrossReferences.Ref AS Ref
		|FROM
		|	Catalog.ProductCrossReferences AS ProductCrossReferences
		|WHERE
		|	ProductCrossReferences.ItemOwner = &ItemOwner
		|	AND ProductCrossReferences.Products = &Products
		|	AND ProductCrossReferences.Characteristic = &Characteristic
		|	AND ProductCrossReferences.Package = &Package
		|	AND NOT ProductCrossReferences.DeletionMark
		|	AND NOT ProductCrossReferences.Invalid";
	EndIf;
	
	QueryResult = Query.Execute();
	ChoiceArray = New Array();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			ChoiceArray.Add(Selection.Ref);
		EndDo;
		
	EndIf;
	
	Return ChoiceArray;
	
EndFunction


#EndRegion

#Region Private


#EndRegion

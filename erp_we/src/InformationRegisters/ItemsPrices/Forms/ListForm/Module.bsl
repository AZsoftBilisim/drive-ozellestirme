
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("TypesOfPrices") Then
		ListOfPriceTypes = New ValueList;
		ListOfPriceTypes.LoadValues(Parameters.TypesOfPrices);

		CommonClientServer.SetDynamicListFilterItem(List, "PriceKind", ListOfPriceTypes, DataCompositionComparisonType.InList,, True, DataCompositionSettingsItemViewMode.Normal);
	Else	
		ListOfPriceTypes = New ValueList;
		ListOfPriceTypes.LoadValues(Catalogs.TypesOfPrices.AvailableTypesOfPrices());
		CommonClientServer.SetDynamicListFilterItem(List, "PriceKind", ListOfPriceTypes, DataCompositionComparisonType.InList,, True, DataCompositionSettingsItemViewMode.Normal);
	EndIf;
	
	If Parameters.Property("Products") Then
		ProductTitle = NStr("vi = '%Title% (%ItemName%)';
							|ru = '%Title% (%ItemName%)';
							|en = '%Title% (%ItemName%)'; fa = '%Title% (%ItemName%)';
							|it = '%Title% (%ItemName%)';
							|pl = '%Title% (%ItemName%)';
							|tr = '%Title% (%ItemName%)'");
		ItemName = Common.ObjectAttributeValue(Parameters.Products, "Description");
		
		ProductTitle = StrReplace(ProductTitle, "%Title%", Title);
		ProductTitle = StrReplace(ProductTitle, "%ItemName%",
			ItemName);
		
		Title = ProductTitle;
		
		Items.Products.Visible = False;
		
		FilterProducts = Parameters.Products;
		CommonClientServer.SetDynamicListFilterItem(List, "Products", 
			Parameters.Products, DataCompositionComparisonType.Equal, , True);
	EndIf;
	
EndProcedure

#EndRegion
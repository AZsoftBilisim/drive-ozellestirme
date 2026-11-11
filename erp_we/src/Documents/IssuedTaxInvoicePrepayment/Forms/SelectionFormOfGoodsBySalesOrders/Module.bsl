
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillInProductTree(Parameters.PaymentDocument); 
	
EndProcedure

#EndRegion

#Region FormElementHandlers

&AtClient
Procedure GoodsCheckOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	For Each SubordinateRow In CurrentRow.GetItems() Do
		SubordinateRow.Check = CurrentRow.Check;
	EndDo;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	MoveProductsToDocument();
	
EndProcedure

&AtClient
Procedure SelectCheckBoxes(Command)
	
	ChangeTaggingForAllRows(True);
	
EndProcedure

&AtClient
Procedure ClearCheckBoxes(Command)
	
	ChangeTaggingForAllRows(False);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInProductTree(PaymentDocument)
	
	TableOfGoods = Documents.IssuedTaxInvoicePrepayment.CustomerOrderProducts(PaymentDocument);
	
	CustomerOrdersTable = TableOfGoods.Copy();
	CustomerOrdersTable.GroupBy("SalesOrder, Currency", "AmountIncludingVAT, VATAmount");
	
	For Each OrderRow In CustomerOrdersTable Do
		NewLineOrder = Goods.GetItems().Add();
		NewLineOrder.Check = True;
		FillPropertyValues(NewLineOrder, OrderRow);
		
		Filter = New Structure("SalesOrder", OrderRow.SalesOrder);
		ProductLines_3 = TableOfGoods.FindRows(Filter);
		For Each RowGoods In ProductLines_3 Do
			NewLineProducts = NewLineOrder.GetItems().Add();
			NewLineProducts.Check = True;
			FillPropertyValues(NewLineProducts, RowGoods, , "SalesOrder");
			NewLineProducts.SetIndex = ?(ValueIsFilled(NewLineProducts.ProductsInSet), 1, 0);
		EndDo;
	EndDo;
	
EndProcedure

&AtClient
Procedure MoveProductsToDocument()
	
	// Removal of modification, because before closing, the attribute is checked.
	Modified = False;
	GoodsAddressInStorage = PutProductsInStorage();
	Close(GoodsAddressInStorage);
	
EndProcedure

&AtServer
Function PutProductsInStorage()
	
	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("Products",            New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("Characteristic",          New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfGoods.Columns.Add("ProductsInSet",      New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("ItemVariantOfSet",    New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfGoods.Columns.Add("Content",              Common.StringTypeDetails(1000));
	TableOfGoods.Columns.Add("Currency",                  New TypeDescription("CatalogRef.Currencies"));
	TableOfGoods.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
	TableOfGoods.Columns.Add("ARAPObject",          New TypeDescription("CatalogRef.ARAPObjects"));
	TableOfGoods.Columns.Add("AmountIncludingVAT",               TMCommonUse.MoneyFieldTypeDescription());
	TableOfGoods.Columns.Add("VATRate",               New TypeDescription("CatalogRef.VATRates"));
	TableOfGoods.Columns.Add("VATAmount",                TMCommonUse.MoneyFieldTypeDescription());
	
	For Each OrderRow In Goods.GetItems() Do
		For Each LineProducts_ In OrderRow.GetItems() Do
			If Not LineProducts_.Check Then
				Continue;
			EndIf;
			NewRow = TableOfGoods.Add();
			FillPropertyValues(NewRow, LineProducts_);
		EndDo;
	EndDo;
	
	GoodsAddressInStorage = PutToTempStorage(TableOfGoods);
	
	Return GoodsAddressInStorage;
	
EndFunction

&AtClient
Procedure ChangeTaggingForAllRows(Check)
	
	For Each OrderLine In Goods.GetItems() Do
		OrderLine.Check = Check;
		For Each StringProducts_ In OrderLine.GetItems() Do
			StringProducts_.Check = Check;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion
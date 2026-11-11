#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure
 
Procedure OnWrite(Cancel, Replacing)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Count() = 0 Then
		Return;
	EndIf;
	
	// The main cell should be one
	// If the set writes another main cell, an error is returned.
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PlaceProductsInStorageBins.Products,
	|	PlaceProductsInStorageBins.Warehouse,
	|	PlaceProductsInStorageBins.Premise,
	|	COUNT(DISTINCT PlaceProductsInStorageBins.Cell) AS Cell
	|FROM
	|	InformationRegister.PlaceProductsInStorageBins AS PlaceProductsInStorageBins
	|WHERE
	|	PlaceProductsInStorageBins.MainStorageBin
	|	AND PlaceProductsInStorageBins.Products IN(&Products)
	|	AND PlaceProductsInStorageBins.Warehouse IN(&Warehouse)
	|	AND PlaceProductsInStorageBins.Premise IN(&Premise)
	|
	|GROUP BY
	|	PlaceProductsInStorageBins.Warehouse,
	|	PlaceProductsInStorageBins.Products,
	|	PlaceProductsInStorageBins.Premise
	|
	|HAVING
	|	COUNT(DISTINCT PlaceProductsInStorageBins.Cell) > 1";
	
	SetTable = Unload();
	
	Query.SetParameter("Products", SetTable.UnloadColumn("Products"));
	Query.SetParameter("Warehouse", SetTable.UnloadColumn("Warehouse"));
	Query.SetParameter("Premise", SetTable.UnloadColumn("Premise"));
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		MessageText = NStr("vi = 'Theo mặt hàng ""%Products%"" trong kho ""%Warehouse%""
		| có ấn định hai ô hàng chính!';
		|ru = 'По номенклатуре ""%Products%"" на складе ""%Warehouse%""
		| назначаются две основные ячейки!';
		|en = 'Two main bins are assigned for the ""%Products%"" items in the ""%Warehouse%""
		|warehouse.'; fa = 'Two main bins are assigned for the ""%Products%"" items in the ""%Warehouse%""
		|warehouse.';
		|it = 'Per la nomenclatura ""%Products%"" nel magazzino ""%Warehouse%""
		| sono impostate due celle principali!';
		|pl = 'Zgodnie z nomenklaturą ""%Products%"" w magazynie ""%Warehouse%""
		| przypisane są dwie główne komórki!';
		|tr = '""%Warehouse%""
		| ambarındaki ""%Products%"" öğesine göre iki ana hücre atanıyor!'");
		
		MessageText = StrReplace(MessageText,"%Products%",Selection.Products);
		MessageText = StrReplace(MessageText,"%Warehouse%",WarehousesServer.GetWarehousePresentation(Selection.Warehouse,Selection.Premise));
		
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
		
	EndDo;
EndProcedure

#EndRegion

#EndIf
#EndIf
#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ControlledLotReference = Undefined;
	ThereIsControlledLotReference = Parameters.Property("ControlledLotReference", ControlledLotReference);
	ThereIs_Warehouse = Parameters.Property("Warehouse") And ValueIsFilled(Parameters.Warehouse);
	StandardProcessing = False;
	ChoiceData = New ValueList();
	ActionsOnGoods = Enums.ActionsOnGoodsInQualityControlCertificate;
	For IndexOf = 0 To ActionsOnGoods.Count() - 1 Do
		ChoiceItem = Enums.ActionsOnGoodsInQualityControlCertificate.Get(IndexOf);
		ChoiceData.Add(ChoiceItem, ChoiceItem);
	EndDo;
	
	// Limiting the list of actions.
	ItemsToRemove = New Array();
	
	If Not GetFunctionalOption("UseGoodsTransfer") Then
		ItemsToRemove.Add(ActionsOnGoods.RegisterGoodsTransfer);
	EndIf;
	
	If Not GetFunctionalOption("UseGoodsQuality") Then
		ItemsToRemove.Add(ActionsOnGoods.ChangeQuality);
		ItemsToRemove.Add(ActionsOnGoods.RegisterStockQualityChange);
	EndIf;
	
	If ThereIsControlledLotReference Then
		QualityControl.RestrictActionSelectionDataByLotReference(ControlledLotReference, ItemsToRemove);
	EndIf;
	
	If Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt")
			Or ThereIs_Warehouse And Not WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Parameters.Warehouse, Parameters.Date) Then
		ItemsToRemove.Add(ActionsOnGoods.ChangeQuality);
	EndIf;
	
	For Each SelectionValue In ItemsToRemove Do
		ChoiceItem = ChoiceData.FindByValue(SelectionValue);
		If ChoiceItem <> Undefined Then
			ChoiceData.Delete(ChoiceItem);
		EndIf;
	EndDo;
	
EndProcedure

#EndIf

#EndRegion

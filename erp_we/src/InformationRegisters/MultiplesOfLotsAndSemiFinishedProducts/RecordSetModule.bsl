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
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	MultiplesOfLotsAndSemiFinishedProducts.Period AS DemandDate,
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariant,
		|	MultiplesOfLotsAndSemiFinishedProducts.Purpose,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.KeyLot AS KeyLot,
		|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.Order,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct
		|FROM
		|	InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|WHERE
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|	AND NOT MultiplesOfLotsAndSemiFinishedProducts.CalculationIsCompleted
		|";
	
	Query.SetParameter("StandardCostEstimate", Filter.StandardCostEstimate.Value);
	
	QueueTable = Query.Execute().Unload();
	If QueueTable.Count() > 0 Then
		InformationRegisters.CalculationQueueOfStandardCostEstimates.WriteQueue(QueueTable, Filter.StandardCostEstimate.Value);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

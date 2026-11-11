#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;

	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "InventoryInOperation";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, AttributesNotToCheck, Cancel, CheckParameters);
	
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, DataProcessors.PrintLabelsOfInventoryInOperation),
		Cancel,
		AttributesNotToCheck);
	
	CheckParameters = InventoryInOperationServer.InventoryControlParameters();
	CheckParameters.TSName = "InventoryInOperation";
	InventoryInOperationServer.CheckInventoryRecords(ThisObject, AttributesNotToCheck, Cancel, CheckParameters);
	
	CheckParameters = InventoryInOperationServer.ParametersForCheckingAccountingForIndividuals();
	CheckParameters.TSName = "InventoryInOperation";
	InventoryInOperationServer.CheckAccountingForIndividuals(ThisObject, AttributesNotToCheck, Cancel, CheckParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);

EndProcedure

#EndRegion

#EndIf
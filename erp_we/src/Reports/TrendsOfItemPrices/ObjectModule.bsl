#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	QueryText = DataCompositionSchema.DataSets.Query.Query;
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemsPrices.Package",
		"ItemsPrices.Products"));
	DataCompositionSchema.DataSets[0].Query = QueryText;
	
EndProcedure

#EndRegion

#EndIf
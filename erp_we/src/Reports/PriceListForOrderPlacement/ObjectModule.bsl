#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	TypesOfPrices = New ValueList;
	TypesOfPrices.LoadValues(Catalogs.TypesOfPrices.AvailableTypesOfPrices());
	DataCompositionClientServer.SetParameter(SettingsComposer, "TypesOfPrices", TypesOfPrices);
	
	PriceManagementSystem.SetVSKDPricingOption(SettingsComposer);
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
EndProcedure

#EndRegion

#EndIf
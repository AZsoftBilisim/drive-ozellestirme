#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function MetadataStructure() Export
	
	Result = OrderStructureCached.RegisterMetadataStructure("OrderStructureLaborCosts");
	Return Result;
	
EndFunction

#EndRegion

#EndIf
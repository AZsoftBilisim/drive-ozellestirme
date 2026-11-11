#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function ObjectsWithSourceDocumentsOriginalsAccounting() Export
	
	TypesToExclude = New Array;
	
	
	Return New TypeDescription(
		Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type,
		,
		TypesToExclude);
	
EndFunction

#EndRegion

#EndIf

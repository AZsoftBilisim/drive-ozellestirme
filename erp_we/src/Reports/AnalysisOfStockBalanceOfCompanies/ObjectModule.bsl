#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);	
		
EndProcedure

#EndRegion

#EndIf
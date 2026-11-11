#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);

EndProcedure

#EndRegion
	
#EndIf
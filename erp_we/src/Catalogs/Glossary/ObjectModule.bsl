#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure OnReadPresentationsAtServer() Export
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
	
EndProcedure

#EndRegion

#EndIf

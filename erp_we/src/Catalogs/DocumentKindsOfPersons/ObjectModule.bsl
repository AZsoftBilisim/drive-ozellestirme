
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers
Procedure OnReadPresentationsAtServer() Export
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
EndProcedure
#EndRegion

#EndIf
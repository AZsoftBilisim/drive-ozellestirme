
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
		
		RegistrationDocumentDescription = "";
		RegistrationDocumentNumber = "";
		RegistrationDocumentDate = '000101010000';
		
	EndIf;
	
	IntangibleAssetsLocalization.BeforeWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#EndIf


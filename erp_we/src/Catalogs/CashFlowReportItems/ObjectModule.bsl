#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder Then
	
		If Not IsBlankString(OffsettingAccount) Then
			If IsBlankString(StrReplace(OffsettingAccount, ".", "")) Then
				OffsettingAccount = "";
			ElsIf Right(TrimAll(OffsettingAccount), 1) = "." Then
				OffsettingAccount = Left(TrimAll(OffsettingAccount), StrLen(TrimAll(OffsettingAccount)) - 1);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("BusinessOperation") Then
			
			If BusinessTransactions.Find(FillingData.BusinessOperation) = Undefined Then
				
				BusinessTransactions.Add().BusinessOperation = FillingData.BusinessOperation;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#EndIf
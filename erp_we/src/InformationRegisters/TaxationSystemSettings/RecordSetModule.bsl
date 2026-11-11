#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	For Each SetRow In ThisObject Do
		SetRow.STSIsApplied =
			SetRow.TaxationSystem = Enums.TaxationSystems.Simplified;
			
		
		If Not SetRow.STSIsApplied Then
			SetRow.DateOfTransferToSTS = Undefined;
			SetRow.STSTransitionNotificationNo = Undefined;
			SetRow.NotificationDateSTS = Undefined;
			SetRow.IncomeTaxPayer = True;
		Else
			SetRow.IncomeTaxPayer = False;
		EndIf;
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

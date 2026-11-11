#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	InterestTotal = 0; FeeTotal = 0;
	For Each SetRow In ThisObject Do
		
		InterestTotal = InterestTotal + SetRow.Interests;
		SetRow.InterestTotal = InterestTotal;
		
		FeeTotal = FeeTotal + SetRow.Fee;
		SetRow.FeeTotal = FeeTotal;
	EndDo;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		For Each SetRow In ThisObject Do
			FillPropertyValues(SetRow,FillingData);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ChoiceData = New ValueList;
	For Each SettlementSubjectFlag In Enums.SettlementSubjectFlags Do 
		If SettlementSubjectFlag <> Enums.SettlementSubjectFlags.ResortFee Then
			ChoiceData.Add(SettlementSubjectFlag);
		EndIf;
	EndDo;
	
	StandardProcessing = False;
	
EndProcedure

#EndIf

#EndRegion
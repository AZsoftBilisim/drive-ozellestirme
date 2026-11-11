
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Filter.Property("Contract") Then
		
		StandardProcessing = False;
		
		ChoiceData = New ValueList;
		ChoiceData.Add(Enums.LoanAndDepositScheduleAmountTypes.PrincipalDebt);
		ChoiceData.Add(Enums.LoanAndDepositScheduleAmountTypes.Interests);
		
		If Common.ObjectAttributeValue(Parameters.Filter.Contract, "FeeType")
			<> Enums.LoanAndDepositFeeTypes.None Then
			ChoiceData.Add(Enums.LoanAndDepositScheduleAmountTypes.Fee);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CalculationDetails = GetCalculation(Parameters.SettlementDetails, Parameters.DetailsType);
	SpreadsheetDocument.Put(CalculationDetails);
	
EndProcedure

&AtServerNoContext
Function GetCalculation(SettlementDetails, DetailsType)
	
	CalculationTemplate = Documents.ProvideAssetsToLeasee2_4.GetTemplate("SettlementDetails");
	CalculationDetails = CalculationTemplate.GetArea(DetailsType);
	CalculationDetails.Parameters.Fill(SettlementDetails);
	
	If SettlementDetails.Property("RevaluationOfIncome") Then
		Revaluation = CalculationTemplate.GetArea("RevaluationOfIncome");
	ElsIf SettlementDetails.Property("RevaluationExpenses") Then
		Revaluation = CalculationTemplate.GetArea("RevaluationExpenses");
	Else
		Return CalculationDetails;
	EndIf;
	
	Revaluation.Parameters.Fill(SettlementDetails);
	CalculationDetails.Join(Revaluation);
	
	Return CalculationDetails;
	
EndFunction

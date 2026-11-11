#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	
	If Parameters.Property("InstancesCheckMethod") Then
		If Parameters.InstancesCheckMethod <> Enums.CheckOptionsOfResearchCopies.WithVariances Then
			ChoiceData.Add(Enums.GoodsResearchResult.IsPassed);
		EndIf;
	EndIf;
	ChoiceData.Add(Enums.GoodsResearchResult.PassedWithOtherQuality);
	ChoiceData.Add(Enums.GoodsResearchResult.NotPassed);
	
EndProcedure

#EndRegion

#EndIf
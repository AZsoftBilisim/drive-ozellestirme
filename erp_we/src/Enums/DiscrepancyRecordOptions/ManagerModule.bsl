
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("VariantOfDiscrepancies") Then
	
		StandardProcessing = False;
		ChoiceData = New ValueList();
		
		If Parameters.VariantOfDiscrepancies = Enums.DiscrepancyOptions.Surpluses Then
			
			ChoiceData.Add(Enums.DiscrepancyRecordOptions.RecogniseGoodsSurplusAsVendorsIncome);
			ChoiceData.Add(Enums.DiscrepancyRecordOptions.RecogniseGoodsSurplusAsOurIncome);
			
		ElsIf Parameters.VariantOfDiscrepancies = Enums.DiscrepancyOptions.Shortages Then
			
			ChoiceData.Add(Enums.DiscrepancyRecordOptions.GoodsShortageRecognisedAsVendorExpenses);
			ChoiceData.Add(Enums.DiscrepancyRecordOptions.GoodsShortageRecognisedAsThirdPartyExpenses);
			ChoiceData.Add(Enums.DiscrepancyRecordOptions.GoodsShortageRecognisedAsOtherExpenses);
			
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("LocalFAAccounting")
		And Not Parameters.LocalFAAccounting Then
		
		StandardProcessing = False;
		
		ChoiceData = New ValueList();
		
		For Each ValueDescription In Metadata.Enums.FixedAssetsStates.EnumValues Do
			Value = Enums.FixedAssetsStates[ValueDescription.Name];
			If Value <> Enums.FixedAssetsStates.EnteredInOffBalanceAccounting Then
				ChoiceData.Add(Value);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
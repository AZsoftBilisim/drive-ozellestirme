#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList();
	For Each CurItem In Enums.IntangibleAssetsStates Do
		If CurItem <> Enums.IntangibleAssetsStates.Received Then
			ChoiceData.Add(CurItem);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion
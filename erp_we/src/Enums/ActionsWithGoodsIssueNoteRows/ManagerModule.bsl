
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("Warehouse") Then
		
		If Not GetFunctionalOption("UseGoodsIssueNoteStatuses", New Structure("Warehouse", Parameters.Warehouse)) Then
			StandardProcessing = False;
			ChoiceData = New ValueList;
			ChoiceData.Add(PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.Ship"));
			ChoiceData.Add(PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.DoNotShip"));
		EndIf;
	EndIf;
		
EndProcedure

#EndRegion


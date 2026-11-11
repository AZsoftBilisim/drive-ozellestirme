
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	ChoiceData.Add(Enums.GoodsTransferStatuses.Shipped);
	ChoiceData.Add(Enums.GoodsTransferStatuses.Accepted);
	
EndProcedure

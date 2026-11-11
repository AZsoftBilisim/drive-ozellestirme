
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	ChoiceData.Add(Enums.GoodsAssemblyStatuses.InProgress);
	ChoiceData.Add(Enums.GoodsAssemblyStatuses.AssembledDisassembled);
	
EndProcedure

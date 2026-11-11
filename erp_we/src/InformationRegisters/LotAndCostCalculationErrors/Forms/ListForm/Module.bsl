
#Region FormEventHandlers

&AtClient
Procedure OnReopen()
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenProtocol(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenProtocol(Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Result = GetProtocol(CurrentData);
	
	Result.Protocol.Show(Result.Title);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function GetProtocol(CurrentData)
	
	Title = CostCalculationProtocol.OutputProtocolHeader(
		CurrentData.Period);
	
	Protocol  = InformationRegisters.LotAndCostCalculationProtocols.GetProtocolText(
		CurrentData.UniqueProtocolID,
		, // protocol recording period
		CurrentData.Period); // the calculation period
	
	Return New Structure("Protocol, Title", Protocol, Title);
	
EndFunction

#EndRegion

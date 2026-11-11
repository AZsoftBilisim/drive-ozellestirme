#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	VariantList.Add(Enums.SupplyOptions.Ship);
	VariantList.Add(Enums.SupplyOptions.FromWarehouse);
	VariantList.Add(Enums.SupplyOptions.ToSupply);
	VariantList.Add(Enums.SupplyOptions.ReserveAsReceived);
	VariantList.Add(Enums.SupplyOptions.NotRequired);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure SupplyOptionsSelection(Item, RowSelected, Field, StandardProcessing)

	SelectClient();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	SelectClient();

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectClient()

	CurRow = Items.SupplyOptions.CurrentData;
	If CurRow <> Undefined Then
		NotifyChoice(CurRow.Value);
	EndIf;

EndProcedure

#EndRegion

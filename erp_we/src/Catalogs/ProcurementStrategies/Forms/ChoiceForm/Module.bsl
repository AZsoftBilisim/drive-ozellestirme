
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("Warehouse", Warehouse) And ValueIsFilled(Warehouse) Then

		If GetFunctionalOption("UseSeveralWarehouses") Then
			SelectByWarehouse = True;
		EndIf;

	EndIf;

	UpdateListSelection(List, SelectByWarehouse, Warehouse, Parameters.Filter);

	Items.GroupFilter.Visible = GetFunctionalOption("UseSeveralWarehouses") And Parameters.Property("Warehouse");

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure SelectByWarehouseOnChange(Item)

	If Parameters.Property("Filter") Then
		SelectionParameters_1 = Parameters.Filter;
	Else
		SelectionParameters_1 = Undefined;
	EndIf;
	UpdateListSelection(List, SelectByWarehouse, Warehouse, SelectionParameters_1);

EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)

	UpdateListSelection(List, SelectByWarehouse, Warehouse, Parameters.Filter);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure UpdateListSelection(List, SelectByWarehouse, Warehouse, Filter)

	If Filter <> Undefined And Filter.Property("SupplyType") Then

		ListOfCollateralTypes = New ValueList();
		For Each Item In Filter.SupplyType Do
			ListOfCollateralTypes.Add(Item);
		EndDo;

		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref.SupplyType", ListOfCollateralTypes, DataCompositionComparisonType.InList);

	EndIf;

	CommonClientServer.SetDynamicListParameter(List, "SelectByWarehouse", SelectByWarehouse);
	CommonClientServer.SetDynamicListParameter(List, "Warehouse", Warehouse);

EndProcedure

#EndRegion

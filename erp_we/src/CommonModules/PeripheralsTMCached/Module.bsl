
#Region Public

// Get the types of connected hardware.
// 
// Returns:
//  Array - Types of connected equipment.
//
Function TypesOfConnectedEquipment() Export
	
	SetPrivilegedMode(True);
	
	Workplace = EquipmentManagerServerCall.GetClientSWorkplace();
	
	If ValueIsFilled(Workplace) Then
		
		Query = New Query;
		
		QueryText =
		"SELECT
		|	Peripherals.EquipmentType AS EquipmentType
		|FROM
		|	Catalog.Peripherals AS Peripherals
		|WHERE
		|	Peripherals.DeviceIsInUse
		|	AND Peripherals.Workplace = &Workplace";
		
		
		
		Query.Text = QueryText;
		Query.SetParameter("Workplace", Workplace);
		
		Result = Query.Execute();
		
		Return Result.Unload().UnloadColumn("EquipmentType");
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction

#EndRegion

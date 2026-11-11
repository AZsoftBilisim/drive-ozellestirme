
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Workplace = SessionParameters.CustomerWorkplace;
	
	RegisterShiftsOverridable.ListFormOnCreateAtServer(ThisObject);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetListFilter();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure WorkplaceOnChange(Item)
	
	SetListFilter();
	
EndProcedure

&AtClient
Procedure FiscalDeviceCapOnChange(Item)
	
	SetListFilter();
	
	If ValueIsFilled(FiscalDevice) Then
		ShiftIsNotClosedOnTheFiscalDevice = Not CashRegisterShiftsServerCall.LastShiftClosed(FiscalDevice);
		FiscalDeviceType = FiscalDeviceType(FiscalDevice);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetListFilter()
	
	List.Filter.Items.Clear();
	
	If ValueIsFilled(Workplace) Then
		
		FilterElement = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue    = New DataCompositionField("Workplace");
		FilterElement.ComparisonType     = DataCompositionComparisonType.Equal;
		FilterElement.Use    = True;
		FilterElement.RightValue   = Workplace;
		
	EndIf;
	
	If ValueIsFilled(FiscalDevice) Then
		
		FilterElement = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue    = New DataCompositionField("FiscalDevice");
		FilterElement.ComparisonType     = DataCompositionComparisonType.Equal;
		FilterElement.Use    = True;
		FilterElement.RightValue   = FiscalDevice;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function FiscalDeviceType(FiscalDevice)
	
	Return Common.ObjectAttributeValue(FiscalDevice, "EquipmentType");
	
EndFunction

#EndRegion

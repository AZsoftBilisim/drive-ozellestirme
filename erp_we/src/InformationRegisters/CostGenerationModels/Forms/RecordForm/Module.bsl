
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillPropertyValues(Record, Parameters);
	
	OnReadCreateAtServer();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductsOnChange(Item)
	
	ProductsWhenChangedOnServer();
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	AvailabilityControl();
	
EndProcedure

&AtServer
Procedure AvailabilityControl()
	
	ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Record.Products);
	
	Items.Characteristic.Enabled = ItemVariantsAreUsed
		Or ValueIsFilled(Record.Characteristic);
	
EndProcedure

&AtServer
Procedure ProductsWhenChangedOnServer()
	
	If ValueIsFilled(Record.Characteristic) Then
		
		CheckResult = Catalogs.Products.CharacteristicAndPackagingBelongToOwner(
			Record.Products, Record.Characteristic, Undefined);
		
		Record.Characteristic = CheckResult.Characteristic;
		
	EndIf;
	
	AvailabilityControl();
	
EndProcedure

#EndRegion

#EndRegion
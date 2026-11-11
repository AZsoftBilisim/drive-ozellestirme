// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RowSelected = Parameters.RowSelected;
	
	VariantsTable = GetFromTempStorage(Parameters.AddressOfOptionsTable); // ValueTable
	ParametersVariants.Load(VariantsTable);
	DeleteFromTempStorage(Parameters.AddressOfOptionsTable);
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.ParametersVariantsProducts.Name);
	ItemsNames.Add(Items.ParametersVariantsCharacteristic.Name);
	ItemsNames.Add(Items.ParametersVariantsSeries.Name);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemsNames,
		"Visible",
		Parameters.ForListByItem);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersParametersVariants

&AtClient
Procedure ParametersVariantsSelection(Item, RowSelected, Field, StandardProcessing)
	
	SelectOptionsAndClose();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PickUpLine(Command)
	
	SelectOptionsAndClose();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectOptionsAndClose()
	
	ParametersString1 = Items.ParametersVariants.CurrentData;
	If ParametersString1 = Undefined Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("RowSelected", RowSelected);
	
	Result.Insert("Recipient", ParametersString1.DeliveryTo);
	Result.Insert("RecipientPoint", ParametersString1.DeliveryPoint);
	Result.Insert("Recipient_Area", ParametersString1.DeliveryZone);
	
	Close(Result);
	
EndProcedure

#EndRegion

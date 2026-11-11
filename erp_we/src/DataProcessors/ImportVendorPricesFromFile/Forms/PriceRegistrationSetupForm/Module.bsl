#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RegisterChangedPrices   					= Parameters.RegisterChangedPrices;
	RegisterOnlyTheRecognizedItem	= Parameters.RegisterOnlyTheRecognizedItem;
	
	RegisterOnlyTheRecognizedRadioButtonNomenclature	= RegisterOnlyTheRecognizedItem;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)

	ReturnStructure = New Structure();
	ReturnStructure.Insert("RegisterChangedPrices",					RegisterChangedPrices);
	ReturnStructure.Insert("RegisterOnlyTheRecognizedItem",	RegisterOnlyTheRecognizedItem);

	Close(ReturnStructure);
	
EndProcedure

&AtClient
Procedure RegisterOnlyTheRecognizedRadioButtonNomenclatureOnChange(Item)
	RegisterOnlyTheRecognizedItem = RegisterOnlyTheRecognizedRadioButtonNomenclature;
EndProcedure

#EndRegion
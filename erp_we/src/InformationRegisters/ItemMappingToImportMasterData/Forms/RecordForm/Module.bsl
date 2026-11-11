#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CustomizeFormElements();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductsOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Record.Characteristic);
	
	FillPropertyValues(ThisObject, Record);
	BatchProcessingOfTablePartClient.ProcessTSString(ThisObject, StructureOfActions, CachedValues);
	FillPropertyValues(Record, ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Products,Characteristic");
	
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "Characteristic");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	FillPropertyValues(ThisObject, Record);
	BatchProcessingOfTablePartServer.ProcessTSString(ThisObject, StructureOfActions, Undefined);
	FillPropertyValues(Record, ThisObject);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Products")
		Or Initialize Then
			
		Items.Characteristic.ReadOnly = Not Form.ItemVariantsAreUsed;
		Items.Characteristic.InputHint = ?(Form.ItemVariantsAreUsed, "", NStr("vi = '<không sử dụng đặc tính>';
																				|ru = '<характеристики не используются>';
																				|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
																				|it = '<le caratteristiche non vengono usate>';
																				|pl = '<charakterystyki nie dotyczą>';
																				|tr = '<varyantlar kullanılmamaktadır>'"));
			
	EndIf;
	
	If AttributesStructure1.Property("Characteristic")
		Or Initialize Then
			
		Items.Characteristic.MarkIncomplete = Form.ItemVariantsAreUsed And Not ValueIsFilled(Form.Record.Characteristic);
			
	EndIf;
	
EndProcedure

#EndRegion
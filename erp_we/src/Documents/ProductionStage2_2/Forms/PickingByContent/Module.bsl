
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Department", Department)
		And Not Department.IsEmpty() Then
		
		EstablishSelectionParameterRelationship("WorkCenterType", "Filter.Department", "Department");
		EstablishSelectionParameterRelationship("Performer", "Filter.Department", "Department");
		
	EndIf;
	
	FilterStructureByStageData = Undefined;
	If Parameters.Property("FilterStructureByStageData", FilterStructureByStageData)
		And FilterStructureByStageData <> Undefined Then
		
		FilterStructureByStageData.Property("ProductRange_2", ProductRange_2);
		FilterStructureByStageData.Property("ItemVariantOfProduct", ItemVariantOfProduct);
		FilterStructureByStageData.Property("MaterialNomenclature", MaterialNomenclature);
		FilterStructureByStageData.Property("ItemVariantOfMaterial", ItemVariantOfMaterial);
		FilterStructureByStageData.Property("WorkCenterType", WorkCenterType);
		FilterStructureByStageData.Property("Performer", Performer);
		
	EndIf;
	
	ConfigureDependentFormElements(ThisForm);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Result = EstablishedSelections();
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region FormElementHandlers

&AtClient
Procedure ProductRange_2OnChange(Item)
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClient
Procedure MaterialNomenclatureOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

#Region FormMaintenance

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize Or AttributesStructure1.Property("ProductRange_2") Then
		
		Items.ItemVariantOfProduct.Enabled = ItemVariantsAreUsed(Form.ProductRange_2);
		
	EndIf;
	
	If Initialize Or AttributesStructure1.Property("MaterialNomenclature") Then
		
		Items.ItemVariantOfMaterial.Enabled = ItemVariantsAreUsed(Form.MaterialNomenclature);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServerNoContext
Function ItemVariantsAreUsed(Products)
	
	Return Catalogs.Products.ItemVariantsAreUsed(Products)

EndFunction

&AtServer
Function EstablishedSelections()
	
	Result = New Structure;
	
	Result.Insert("ProductSelectionIsUsed", Not ProductRange_2.IsEmpty());
	Result.Insert("ProductRange_2", ProductRange_2);
	Result.Insert("ItemVariantOfProduct", ItemVariantOfProduct);
	
	Result.Insert("MaterialSelectionIsUsed", Not MaterialNomenclature.IsEmpty());
	Result.Insert("MaterialNomenclature", MaterialNomenclature);
	Result.Insert("ItemVariantOfMaterial", ItemVariantOfMaterial);
	
	Result.Insert("VRCSelectionIsUsed", Not WorkCenterType.IsEmpty());
	Result.Insert("WorkCenterType", WorkCenterType);
	
	Result.Insert("SelectionByPerformerIsUsed", ValueIsFilled(Performer));
	Result.Insert("Performer", Performer);
	
	Return Result;
	
EndFunction

&AtServer
Procedure EstablishSelectionParameterRelationship(Attribute, ParameterName, DataPath)
	
	NewLink = New ChoiceParameterLink(ParameterName, DataPath);
	
	NewArray = New Array();
	NewArray.Add(NewLink);
	
	NewLinks = New FixedArray(NewArray);
	
	Items[Attribute].ChoiceParameterLinks = NewLinks;

EndProcedure

#EndRegion

#EndRegion

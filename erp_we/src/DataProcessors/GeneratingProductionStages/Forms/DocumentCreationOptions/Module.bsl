
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.SeparateProductionOfSemiFinishedProducts.Visible = Not Parameters.SemiFinishedProductsAreProducedSeparately;
	Items.ReplaceMaterialsWithAnalogs.Visible = Parameters.UseAlternativeMaterials;
	
	DocumentCreationOptions = DataProcessors.GeneratingProductionStages.DefaultDocumentCreationOptions();
	
	FillPropertyValues(DocumentCreationOptions, Parameters.DocumentCreationOptions);	
	FillPropertyValues(ThisObject, DocumentCreationOptions);	
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReserveMaterialsOnChange(Item)
	
	ReplaceMaterialsWithAnalogs = ReserveMaterials;
	
	ConfigureDependentFormElements(ThisObject, "ReserveMaterials");

EndProcedure
 
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	FillPropertyValues(DocumentCreationOptions, ThisObject);
	
	Close(DocumentCreationOptions);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
EndProcedure 

#EndRegion


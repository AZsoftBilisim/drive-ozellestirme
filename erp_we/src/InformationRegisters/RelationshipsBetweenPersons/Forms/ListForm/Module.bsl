
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	// set the selection by individual.
	If Parameters.Property("Filter") And Parameters.Filter.Property("Person1") Then

		StandardProcessing = False;
		Person       = Parameters.Filter.Person1;
		
		FilterGroup	  = List.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue  = New DataCompositionField("Person1");
        FilterElement.RightValue = Person;
		
		FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue  = New DataCompositionField("Person2");
        FilterElement.RightValue = Person;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy Then
		Cancel = True;
		 OpenForm("InformationRegister.RelationshipsBetweenPersons.RecordForm",
		New Structure("Person", Person),,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

#EndRegion


#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SetUnavailableSelectionsFromParameters(Parameters.Filter);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

// The procedure sets the selections passed in the structure. Selections cannot be changed.
//
// Parameters:
//	FilterStructure1 - Structure - Key: name of the data layout field, Value: selection value.
//
&AtServer
Procedure SetUnavailableSelectionsFromParameters(FilterStructure1)
	
	For Each FilterElement In FilterStructure1 Do
		
		If FilterElement.Key = "ControlEndDate" Then
			
			OrGroup = CommonClientServer.CreateFilterItemGroup(
			    List.SettingsComposer.FixedSettings.Filter.Items, "ValidityEndDate",
			    DataCompositionFilterItemsGroupType.OrGroup);
			
			CommonClientServer.SetFilterItem(
			    OrGroup,
			    "ValidityEndDate", 
			    CurrentSessionDate(),
			    DataCompositionComparisonType.Greater);
			   
			CommonClientServer.SetFilterItem(
			    OrGroup,
			    "ValidityEndDate", 
			    Date(1, 1, 1),
			    DataCompositionComparisonType.Equal);
			
			Continue;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

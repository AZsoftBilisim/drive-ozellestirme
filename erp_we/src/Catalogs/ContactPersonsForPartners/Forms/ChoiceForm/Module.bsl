
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	RequestConditionByOwner = "";
	Query = New Query;
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner") Then
		If TypeOf( Parameters.Filter.Owner) = Type("Array") Then
			If Parameters.Filter.Owner.Count() > 0 Then
				Partner = Parameters.Filter.Owner[0];
				CommonClientServer.SetDynamicListFilterItem(List,"Owner",Parameters.Filter.Owner, DataCompositionComparisonType.InList,, True);
			EndIf;
		Else
			Partner = Parameters.Filter.Owner;
		EndIf;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List,"DeletionMark",False,DataCompositionComparisonType.Equal,, True);
	GroupTermination = CommonClientServer.CreateFilterItemGroup(
		TMCommonUseClientServer.GetDynamicListSelection(List).Items,"TerminationOfCommunication",DataCompositionFilterItemsGroupType.OrGroup);
	CommonClientServer.AddCompositionItem(GroupTermination,"RelationEndDate",DataCompositionComparisonType.Equal,Date(1,1,1),,True);
	CommonClientServer.AddCompositionItem(GroupTermination,"RelationEndDate",DataCompositionComparisonType.Greater,CurrentSessionDate(),,True);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(Partner) Then
		CommonClientServer.DeleteDynamicListFilterGroupItems(List, "Owner");
	EndIf;
	
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion


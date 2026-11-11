#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Filter.Property("Organization") Then
		FilterOrganization = Parameters.Filter.Organization;
		SelectionElementOrganization = ListSelectionsClientServer.ListSelectionElementByName(List, "Organization");
		If SelectionElementOrganization <> Undefined Then
			SelectionElementOrganization.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
		Items.FilterOrganization.Visible = True;
	Else
	
	
	EndIf;
	
	ChoiceMode = (Parameters.ChoiceMode = True);
	Items.List.ChoiceMode = ChoiceMode;
	Items.List.MultipleChoice = (Parameters.MultipleChoice = True);
	
	ReconciliationMode = False;
	If Parameters.Property("ReconciliationMode") Then
		ReconciliationMode = Parameters.ReconciliationMode;
	EndIf;
	
	SetQueryText();
	
	Items.Select.Visible = ChoiceMode;
	Items.ObjectIsNotInList.Visible = ChoiceMode And ReconciliationMode;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "FAInformationHasBeenChanged" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If Value = Undefined Or Not ReconciliationMode Then
		// Standard treatment
		Return;
	EndIf;	
	
	StandardProcessing = False;
	
	CurrentData = Items.List.CurrentData;
	ValueSelected = New Structure;
	ValueSelected.Insert("FixedAsset", CurrentData.Ref);
	ValueSelected.Insert("Description", CurrentData.Description);
	ValueSelected.Insert("CadastralNumber", CurrentData.CadastralNumber);
	ValueSelected.Insert("Supplied_2", CurrentData.Supplied_2);
	ValueSelected.Insert("TakenOff", CurrentData.TakenOff);
	NotifyChoice(ValueSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData <> Undefined And Not CurrentData.IsFolder Then
		ValueSelected = New Structure;
		ValueSelected.Insert("FixedAsset", CurrentData.Ref);
		ValueSelected.Insert("Description", CurrentData.Description);
		ValueSelected.Insert("CadastralNumber", CurrentData.CadastralNumber);
		ValueSelected.Insert("Supplied_2", CurrentData.Supplied_2);
		ValueSelected.Insert("TakenOff", CurrentData.TakenOff);
		NotifyChoice(ValueSelected);
	EndIf;

EndProcedure

&AtClient
Procedure ObjectIsNotInList(Command)
	NotifyChoice(New Structure);
EndProcedure

#Region StandardSubsystems

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure SetQueryText()
	
		
	List.Parameters.SetParameterValue("BeginOfPeriod",Date(1,1,1));
	List.Parameters.SetParameterValue("EndOfPeriod",Date(1,1,1));
	If Parameters.Property("Period") Then
		List.Parameters.SetParameterValue("DocumentDate", EndOfYear(Parameters.Period));
		List.Parameters.SetParameterValue("Date", EndOfYear(Parameters.Period));
	Else
		List.Parameters.SetParameterValue("DocumentDate", Common.CurrentUserDate());
		List.Parameters.SetParameterValue("Date", Common.CurrentUserDate());
	EndIf;
	
	List.Parameters.SetParameterValue("ListOfFA", Undefined);
	List.Parameters.SetParameterValue("WithoutFASelection", True);
	
	If Parameters.Filter.Property("Organization") Then
		List.Parameters.SetParameterValue("Organization", Parameters.Filter.Organization);
	Else
		List.Parameters.SetParameterValue("Organization", Catalogs.Companies.EmptyRef());
	EndIf;
	
EndProcedure

#EndRegion
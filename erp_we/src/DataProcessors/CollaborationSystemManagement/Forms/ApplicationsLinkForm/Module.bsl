#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Applications = CollaborationSystem.GetSubscriberApplications();
	For Each Application In Applications Do
		ApplicationsList.Add(Application.ID, Application.Description);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ApplicationsMarkListOnChange(Item)
	
	SetButtonsAvailability();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	LinkApps();
	
	Close(True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Initialize(EditableElement) Export
	
	For Each AppListItem In ApplicationsList Do
		If AppListItem.Value = EditableElement.AppID1 Or
		   AppListItem.Value = EditableElement.AppID2
		Then
			AppListItem.Check = True;
		EndIf;
	EndDo;
	
	UserMatching = EditableElement.UserMatching;
	ConversationsMapping = EditableElement.ContextConversationsMapping;
	
	ApplicationToEditID1 = EditableElement.AppID1;
	ApplicationToEditID2 = EditableElement.AppID2;
	
	SetButtonsAvailability();
	
EndProcedure

&AtServer
Procedure LinkApps()
	
	Link = New(IntegrationWithCollaborationSystem.TypeAppSharing());
	
	For Each AppListItem In ApplicationsList Do
		If Not AppListItem.Check Then
			Continue;
		EndIf;
		
		Link.Applications.Add(AppListItem.Value);
	EndDo;
	
	If Link.Applications.Count() < 2 Then
		Return;
	EndIf;
	
	If ApplicationToEditID1 <> Undefined Then
		If Not Link.Applications.Contains(ApplicationToEditID1) Or
	   	   Not Link.Applications.Contains(ApplicationToEditID2) 
		Then
			BreakingTies = New(IntegrationWithCollaborationSystem.TypeCollectionOfApplicationIds()); // CollaborationSystemApplicationIDCollection
			BreakingTies.Add(ApplicationToEditID1);
			BreakingTies.Add(ApplicationToEditID2);
			CollaborationSystem.CancelSubscriberApplicationLinks(BreakingTies);
		EndIf;
	EndIf;

	Link.UserMatching = UserMatching;
	Link.ConversationContextMatching = ConversationsMapping;
	
	CollaborationSystem.SetSubscriberApplicationLinks(Link);
	
EndProcedure

&AtClient
Procedure SetButtonsAvailability()
	
	NumberOfMarks = 0;
	For Each AppListItem In ApplicationsList Do
		If AppListItem.Check Then
			NumberOfMarks = NumberOfMarks + 1;
		EndIf;
	EndDo;
	
	Items.SaveCommand.Enabled = NumberOfMarks >= 2;
	
EndProcedure

#EndRegion

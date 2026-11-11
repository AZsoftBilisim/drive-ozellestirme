///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("SubjectOf", CommandParameter);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterStructure1);
	FormParameters.Insert("InteractionType", "");

	If InteractionsClientServer.IsSubject(CommandParameter) Then
		FormParameters.InteractionType = "SubjectOf";
		
	ElsIf InteractionsClientServer.IsInteraction(CommandParameter) Then
		FormParameters.InteractionType = "Interaction";
	Else
		Return;
	EndIf;

	OpenForm("DocumentJournal.Interactions.Form.ParametricListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Source.UniqueKey,
		CommandExecuteParameters.Window);

EndProcedure

#EndRegion
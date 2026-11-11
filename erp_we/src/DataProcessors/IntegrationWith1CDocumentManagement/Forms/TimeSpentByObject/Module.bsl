#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ExternalObject") Then
		If TypeOf(Parameters.ExternalObject) = Type("Structure") Then
			SubjectOfID = Parameters.ExternalObject.ID;
			SubjectOfType = Parameters.ExternalObject.type;
		Else
			ExternalObject = Parameters.ExternalObject;
		EndIf;
	EndIf;
	
	// Timing.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP")
			And Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
		DisplayListOfLaborCosts();
	Else
		DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
		Items.Works.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	Modified = False;
	DisplayListOfLaborCosts();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DisplayListOfLaborCosts()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = ListOfConditions.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "source";
	
	If ValueIsFilled(SubjectOfID) Then
		Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			SubjectOfID,
			SubjectOfType);
	Else
		Condition.value = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
			Proxy,
			ExternalObject);
	EndIf;
	
	FilterConditions.Add(Condition);
	
	Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMActualWork",
		ListOfConditions);
	
	Works.Clear();
	
	For Each ResponseString In Response.items Do
		
		String = ResponseString.object;
		
		NewRow = Works.Add();
		NewRow.AddedOn = String.addDate;
		NewRow.Begin = String.begin;
		NewRow.Ending = String.end;
		NewRow.Work_5 = String.description;
		NewRow.Duration = String.duration / 3600;
		NewRow.DurationOfRow = IntegrationWith1CDocumentManagementClientServer.NumberPerLine(NewRow.Duration);
		
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(NewRow, String.workType, "WorkKind", False);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(NewRow, String.project,"Project", False);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(NewRow, String.projectTask,"TaskOfTheProject", False);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(NewRow, String.source, "Source", False);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(NewRow, String.user, "User", False);
		
		NewRow.ProjectTask = IntegrationWith1CDocumentManagementClientServer.PresentationOfTaskProject(
			NewRow.Project, NewRow.TaskOfTheProject);
		
	EndDo;
	
	Works.Sort("AddedOn");
	
EndProcedure

#EndRegion

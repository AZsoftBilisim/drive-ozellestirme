#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	HTMLPresentation = GetHTMLPresentationOfTaskForm(Parameters.Type, Parameters.ID)
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HTMLPresentationOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	
	If EventData.Anchor <> Undefined And ValueIsFilled(EventData.Anchor.href) Then
		
		SubstringsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(EventData.Anchor.href, "/");
		
		LinkString_ = SubstringsArray[SubstringsArray.Count() - 1];
		
		ParametersArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(LinkString_, "$");
		
		ObjectType = ParametersArray[0];
		ObjectID = ParametersArray[1];
		
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(ObjectType, ObjectID, Item);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

&AtClient
Procedure OpenBusinessProcess(Command)
	
	BPParameters = GetBusinessProcessParameters();
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(BPParameters.type, BPParameters.ID, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetHTMLPresentationOfTaskForm(Type, Var_ID)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Task_Data_ = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		Type,
		Var_ID,
		"HTMLView");
	ID = Task_Data_.objectID.ID;
	Type = Task_Data_.objectID.type;
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Nhiệm vụ ""%1""';
			|ru = 'Задача ""%1""';
			|en = 'Task ""%1""'; fa = 'Task ""%1""';
			|it = 'Compito ""%1""';
			|pl = 'Zadanie ""%1""';
			|tr = 'Görev ""%1""'"), Task_Data_.name);
	Return Task_Data_.htmlView;
	
EndFunction

&AtServer
Function GetBusinessProcessParameters()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Task_Data_ = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		"DMBusinessProcessTask",
		ID);
	
	BusinessProcessParameters = New Structure;
	BusinessProcessParameters.Insert("ID", Task_Data_.parentBusinessProcess.objectID.ID);
	BusinessProcessParameters.Insert("type", Task_Data_.parentBusinessProcess.objectID.type);
	
	Return BusinessProcessParameters;
	
EndFunction

#EndRegion

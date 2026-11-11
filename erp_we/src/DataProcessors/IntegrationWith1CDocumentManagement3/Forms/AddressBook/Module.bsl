#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UseCommunicationRules = ValueIsFilled(Parameters.ContextOfCommunicationRules)
		And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.15.41");
	FillInDivisionTree(Tree.GetItems(), "DMSubdivision", "");
	AllUsersElement = Tree.GetItems().Insert(0);
	AllUsersElement.Description = NStr("vi = 'Tất cả nhân viên';
										|ru = 'Все сотрудники';
										|en = 'All employees'; fa = 'All employees';
										|it = 'Все сотрудники';
										|pl = 'All employees';
										|tr = 'Tüm çalışanlar'");
	AllUsersElement.ID = "";
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TreeBeforeExpand(Item, String, Cancel)
	
	Leaf = Tree.FindByID(String);
	
	If Leaf = Undefined Then
		Return;
	EndIf;
	
	If Not Leaf.SubfoldersRead Then
		PopulateFolderTreeById(String, Leaf.ID);
		Leaf.SubfoldersRead = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure TreeOnActivateRow(Item)
	
	AttachIdleHandler("IdleHandler", 0.2, True);
	
EndProcedure

&AtClient
Procedure GroupUsersRolesOnCurrentPageChange(Item, CurrentPage)
	
	If Roles.Count() = 0 Then
		FillInListOfAvailableRoles();
	EndIf;
	
EndProcedure

&AtClient
Procedure RolesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	SelectExecute();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsersTable

&AtClient
Procedure UsersTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	SelectExecute();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	SelectExecute();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInDivisionTree(TreeBranch1, TypeOfSelectionObject, FolderID_ = Undefined,
		SearchString = Undefined)
	
	TreeBranch1.Clear();
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Conditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	ListOfSelectionConditions = Conditions.conditions; // XDTOList
	
	If FolderID_ <> Undefined Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "Parent";
		Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			FolderID_,
			TypeOfSelectionObject);
		
		ListOfSelectionConditions.Add(Condition);
	EndIf;
	
	If SearchString <> Undefined Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "Name";
		Condition.value = SearchString;
		
		ListOfSelectionConditions.Add(Condition);
	EndIf;
	
	If UseCommunicationRules Then
		IntegrationWith1CDocumentManagement3.ToSupplementSelectionWithContextOfCommunicationRules(
			Proxy,
			Parameters.ContextOfCommunicationRules,
			ListOfSelectionConditions);
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		TypeOfSelectionObject,
		Conditions);
	
	For Each Item In Result.Items Do
		
		NewRow = TreeBranch1.Add();
		NewRow.Description = Item.object.name;
		NewRow.ID = Item.object.objectID.ID;
		NewRow.Type = Item.object.objectID.type;
		
		If TypeOfSelectionObject = "DMFileFolder" Then
			NewRow.Picture = 0;
		Else
			If Item.isFolder Then
				NewRow.Picture = 0;
			Else
				NewRow.Picture = 0;
			EndIf;
		EndIf;
		
		If Item.canHaveChildren And (SearchString = Undefined) Then
			NewRow.SubfoldersRead = False;
			NewRow.GetItems().Add(); // To get a plus sign.
		Else
			NewRow.SubfoldersRead = True;
		EndIf;
		
		If UseCommunicationRules Then
			NewRow.UnavailableAccordingToRulesOfCommunications = Item.object.isNotAvailableAccordingCommunicationRules;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInUserTable(IDDivision)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	// Getting the head of the current department
	If ValueIsFilled(IDDivision) Then
		Department = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			"DMSubdivision",
			IDDivision);
		If IntegrationWith1CDocumentManagementCore.PropertySet(Department, "head") Then
			SupervisorSID = Department.head.objectID.ID;
		EndIf;
	EndIf;
	
	// Filling in the list of employees.
	Conditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	Conditions.limit = 1000;
	ListOfSelectionConditions = Conditions.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "isActual";
	Condition.value = True;
	ListOfSelectionConditions.Add(Condition);
	
	If ValueIsFilled(IDDivision) Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "Subdivision";
		Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			IDDivision,
			"DMSubdivision");
		ListOfSelectionConditions.Add(Condition);
	EndIf;
	
	If UseCommunicationRules Then
		IntegrationWith1CDocumentManagement3.ToSupplementSelectionWithContextOfCommunicationRules(
			Proxy,
			Parameters.ContextOfCommunicationRules,
			ListOfSelectionConditions);
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMEmployee",
		Conditions);
	
	UsersTable.Clear();
	For Each UserInList In Result.Items Do
		NewRow = UsersTable.Add();
		NewRow.User = UserInList.object.name;
		NewRow.UserID = UserInList.object.objectID.ID;
		NewRow.UserType = UserInList.object.objectID.type;
		NewRow.Director = (SupervisorSID = UserInList.object.objectID.ID);
		
		If UseCommunicationRules Then
			NewRow.UnavailableAccordingToRulesOfCommunications = UserInList.object.isNotAvailableAccordingCommunicationRules;
		EndIf;
	EndDo;
	
	UsersTable.Sort("User Asc");
	
	Items.InformationGroup.Visible = (UsersTable.Count() = Conditions.limit);
	
EndProcedure

&AtServer
Procedure PopulateFolderTreeById(IDOfTreeElement, FolderID_)
	
	Leaf = Tree.FindByID(IDOfTreeElement);
	
	If Leaf = Undefined Then
		Return;
	EndIf;
	
	FillInDivisionTree(Leaf.GetItems(), "DMSubdivision", Leaf.ID);
	
EndProcedure

&AtClient
Procedure IdleHandler()
	
	FillInUserTable(Items.Tree.CurrentData.ID);
	
EndProcedure

&AtServer
Procedure FillInListOfAvailableRoles()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ObjectSelectionCriteria = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMObjectListQuery");
	ListOfSelectionConditions = ObjectSelectionCriteria.conditions; // XDTOList
	
	If UseCommunicationRules Then
		IntegrationWith1CDocumentManagement3.ToSupplementSelectionWithContextOfCommunicationRules(
			Proxy,
			Parameters.ContextOfCommunicationRules,
			ListOfSelectionConditions);
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMBusinessProcessExecutorRole",
		ObjectSelectionCriteria);
	
	Roles.Clear();
	For Each Item In Result.Items Do
		NewRow = Roles.Add();
		NewRow.Role = Item.object.name;
		NewRow.RoleID = Item.object.objectID.ID;
		NewRow.RoleType = Item.object.objectID.type;
		NewRow.Picture = IntegrationWith1CDocumentManagementCore.IndexOfImageOfCatalogElement();
		
		If UseCommunicationRules Then
			NewRow.UnavailableAccordingToRulesOfCommunications = Item.object.isNotAvailableAccordingCommunicationRules;
		EndIf;
	EndDo;
	
	Roles.Sort("Role Asc");
	
EndProcedure

&AtClient
Procedure SelectExecute()
	
	If Items.GroupUsersRoles.CurrentPage = Items.UsersGroup2 Then
		
		If Items.UsersTable.CurrentData = Undefined Then
			Return;
		EndIf;
		
		If ValueIsFilled(Parameters.ContextOfCommunicationRules)
				And Items.UsersTable.CurrentData.UnavailableAccordingToRulesOfCommunications Then
			IntegrationWith1CDocumentManagement3Client.ShowViolationOfRulesOfCommunication();
			Return;
		EndIf;
		
		ReturnData = New Structure;
		ReturnData.Insert("Performer", Items.UsersTable.CurrentData.User);
		ReturnData.Insert("PerformerID", Items.UsersTable.CurrentData.UserID);
		ReturnData.Insert("PerformerType", Items.UsersTable.CurrentData.UserType);
		
		Close(ReturnData);
		
	ElsIf Items.GroupUsersRoles.CurrentPage = Items.RoleGroup Then
		
		If Items.Roles.CurrentData = Undefined Then
			Return;
		EndIf;
		
		If ValueIsFilled(Parameters.ContextOfCommunicationRules)
				And Items.Roles.CurrentData.UnavailableAccordingToRulesOfCommunications Then
			IntegrationWith1CDocumentManagement3Client.ShowViolationOfRulesOfCommunication();
			Return;
		EndIf;
		
		Notification = New CallbackDescription("SelectExecuteCompletion", ThisObject);
		
		IntegrationWith1CDocumentManagementCoreClient.ShowGettingAddressingObjectsOfRole(
			Notification,
			Items.Roles.CurrentData.Role,
			Items.Roles.CurrentData.RoleType,
			Items.Roles.CurrentData.RoleID,
			ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectExecuteCompletion(ReturnData, NotificationParameters) Export
	
	If ReturnData = Undefined Then
		Return;
	EndIf;
	
	Close(ReturnData);
	
EndProcedure

#EndRegion
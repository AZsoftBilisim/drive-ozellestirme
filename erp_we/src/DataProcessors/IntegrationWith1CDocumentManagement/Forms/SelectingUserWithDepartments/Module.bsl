#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillInDivisionTree(Tree.GetItems(), "DMSubdivision", "");
	AllUsersElement = Tree.GetItems().Insert(0);
	AllUsersElement.Description = NStr("vi = 'Tất cả người sử dụng';
										|ru = 'Все пользователи';
										|en = 'All users'; fa = 'همه کاربران';
										|it = 'Tutti gli utenti';
										|pl = 'Wszyscy użytkownicy';
										|tr = 'Tüm kullanıcılar'");
	AllUsersElement.ID = "";
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTree

&AtClient
Procedure TreeBeforeExpand(Item, String, Cancel)
	
	Leaf = Tree.FindByID(String);
	
	If Leaf = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(Leaf.ID) And Not Leaf.SubfoldersRead Then
		PopulateFolderTreeById(String, Leaf.ID);
		Leaf.SubfoldersRead = True;
	EndIf;

EndProcedure

&AtClient
Procedure TreeOnActivateRow(Item)
	
	AttachIdleHandler("IdleHandler", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsersList

&AtClient
Procedure UsersListSelection(Item, RowSelected, Field, StandardProcessing)
	
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
Procedure FillInDivisionTree(TreeBranch1, TypeOfSelectionObject, FolderID_ = Undefined, SearchString = Undefined)
	
	TreeBranch1.Clear();
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Conditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	ListOfSelectionConditions = Conditions.conditions; // XDTOList
	
	If FolderID_ <> Undefined Then
		ParentID__ = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			FolderID_,
			TypeOfSelectionObject);
		
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "parent";
		Condition.value = ParentID__;
		ListOfSelectionConditions.Add(Condition);
	EndIf;
	
	If SearchString <> Undefined Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "name";
		Condition.value = SearchString;
		ListOfSelectionConditions.Add(Condition);
	EndIf;
	
	If TypeOf(Filter) = Type("Structure") Then
		For Each FIlterRow In Filter Do
			Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
			Condition.property = FIlterRow.Key;
			
			If TypeOf(FIlterRow.Value) = Type("Structure") Then
				Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
					Proxy,
					FIlterRow.Value.ID,
					FIlterRow.Value.type);
			Else
				Condition.value = FIlterRow.Value;
			EndIf;
		
			ListOfSelectionConditions.Add(Condition);
		EndDo;
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		TypeOfSelectionObject,
		Conditions);
	
	For Each Item In Result.items Do
		
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
		
		If Item.CanHaveChildren And (SearchString = Undefined) Then
			NewRow.SubfoldersRead = False;
			NewRow.GetItems().Add(); // to get a plus sign
		Else
			NewRow.SubfoldersRead = True;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillUserList(IDDivision)
	
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
	
	// Filling in the list of users
	Conditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	ListOfSelectionConditions = Conditions.conditions; // XDTOList
	
	If ValueIsFilled(IDDivision) Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "Subdivision";
		Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			IDDivision,
			"DMSubdivision");
		ListOfSelectionConditions.Add(Condition);
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMUser",
		Conditions);
	
	UsersList.Clear();
	For Each UserInList In Result.Items Do
		NewRow = UsersList.Add();
		NewRow.Description = UserInList.object.name;
		NewRow.ID = UserInList.object.objectID.ID;
		NewRow.Type = UserInList.object.objectID.type;
		NewRow.Director = (SupervisorSID = UserInList.object.objectID.ID);
	EndDo;
	
	UsersList.Sort("Description Asc");
	
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
	
	FillUserList(Items.Tree.CurrentData.ID);
	
EndProcedure

&AtClient
Procedure SelectExecute()
	
	CurrentData = Items.UsersList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("AttributeID",  CurrentData.ID);
	Result.Insert("AttributeType", CurrentData.Type);
	Result.Insert("AttributePresentation", CurrentData.Description);
	
	Close(Result);
	
EndProcedure

#EndRegion
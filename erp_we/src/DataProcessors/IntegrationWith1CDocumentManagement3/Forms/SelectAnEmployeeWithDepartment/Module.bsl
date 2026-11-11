#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillInDivisionTree(Tree.GetItems(), "DMSubdivision", "");
	ElementAllEmployees = Tree.GetItems().Insert(0);
	ElementAllEmployees.Description = NStr("vi = 'Tất cả nhân viên';
											|ru = 'Все сотрудники';
											|en = 'All employees'; fa = 'All employees';
											|it = 'Все сотрудники';
											|pl = 'All employees';
											|tr = 'Tüm çalışanlar'");
	ElementAllEmployees.ID = "";
	
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

#Region FormTableItemsEventHandlersListOfEmployees

&AtClient
Procedure ListOfEmployeesSelection(Item, RowSelected, Field, StandardProcessing)
	
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
Procedure FillInListOfEmployees(IDDivision)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	// Getting the head of the Cur division.
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
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMEmployee",
		Conditions);
	
	ListOfEmployees.Clear();
	For Each EmployeeInList In Result.Items Do
		NewRow = ListOfEmployees.Add();
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow,
			EmployeeInList.object,
			"Employee",
			True);
		NewRow.Director = (SupervisorSID = EmployeeInList.object.objectID.ID);
	EndDo;
	
	ListOfEmployees.Sort("EmployeePresentation Asc");
	
	Items.InformationGroup.Visible = (ListOfEmployees.Count() = Conditions.limit);
	
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
	
	FillInListOfEmployees(Items.Tree.CurrentData.ID);
	
EndProcedure

&AtClient
Procedure SelectExecute()
	
	CurrentData = Items.ListOfEmployees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Attribute",  CurrentData.Employee);
	Result.Insert("AttributeID",  CurrentData.EmployeeID);
	Result.Insert("AttributeType", CurrentData.EmployeeType);
	Result.Insert("AttributePresentation", CurrentData.EmployeePresentation);
	
	Close(Result);
	
EndProcedure

#EndRegion
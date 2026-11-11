#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
	ModuleIntegrationWith1CDocumentManagement3.ToEstablishConditionalAppearanceOfHoldingSSUBAssets(ThisObject);
	
	AddressOfCentralSUBAsset = Parameters.AddressOfCentralSUBAsset;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TestConnection();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AuthorizationSettingsDecorationClick(Item)
	
	Notification = New CallbackDescription("AuthorizationSettingsDecorationClickCompletion", ThisObject);
	NameOfParameterForm = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement";
	
	FormParameters = New Structure;
	FormParameters.Insert("ConnectingToCentralSubAsset", True);
	
	OpenForm(
		NameOfParameterForm,
		FormParameters,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AuthorizationSettingsDecorationClickCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		FillInSubAssetsAndUsers();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCODESUBAssets

&AtClient
Procedure CODESUBAssetsOnActivateRow(Item)
	
	CurrentData = Items.CODESUBAssets.CurrentData;
	If CurrentData = Undefined Then
		Items.UsersOfSubAssets.RowFilter = Undefined;
		Return;
	EndIf;
	
	Items.UsersOfSubAssets.RowFilter = New FixedStructure(
		"NodeID", CurrentData.NodeID);
	
	CanActivate = False;
	CanBeDeactivated = False;
	If Not CurrentData.CentralNode And ValueIsFilled(CurrentData.NodeID) Then
		CanActivate = (CurrentData.Running = 1);
		CanBeDeactivated = Not CanActivate;
	EndIf;
	Items.SubAssetsOfCODEAreActivated.Enabled = CanActivate;
	Items.DeactivateCODESUBAssets.Enabled = CanBeDeactivated;
	
	Items.CODESUBAssetsContextMenuExternalURLHostAddress.Enabled =
		Not IsBlankString(CurrentData.WebServiceAddress);
	Items.CODESUBAssetsContextMenuOpenSubAsset.Enabled = Not IsBlankString(CurrentData.WebServiceAddress);
	Items.SUBAssetsCODEContextMenuChangeSubAssets.Enabled = Not CurrentData.CentralNode
		And Not IsBlankString(CurrentData.WebServiceAddress);
	
	Items.UsersChangeSUBAsset.Enabled = CurrentData.CentralNode
		Or Not ValueIsFilled(CurrentData.NodeID)
		Or CanBeDeactivated;
	Items.UsersOfSubAssetsContextMenuGroupSubAssets.Enabled = Items.UsersChangeSUBAsset.Enabled;
	
EndProcedure

&AtClient
Procedure CODESUBAssetsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.WebServiceAddress) Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagement3Client.OpenDMObject(
		"e1cib/command/DataProcessor.SeamlessIntegrationAdministrationPanel.Command.IntegrationSettings",
		CurrentData.WebServiceAddress);
	
EndProcedure

&AtClient
Procedure CODESUBAssetsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	If TypeOf(DragParameters.Value) <> Type("Array")
			Or DragParameters.Value.Count() = 0
			Or TypeOf(DragParameters.Value[0]) <> Type("FormDataCollectionItem") Then
		Return;
	EndIf;
	
	If String = Undefined Then
		Return;
	EndIf;
	
	CurrentData = CODESUBAssets.FindByID(String);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	DragParameters.AllowedActions = DragAllowedActions.Move;
	
	If Not ValueIsFilled(CurrentData.WebServiceAddress) Then
		DragParameters.Action = DragAction.Cancel;
	EndIf;
	
EndProcedure

&AtClient
Procedure CODESUBAssetsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	If String = Undefined Then
		Return;
	EndIf;
	
	CurrentData = CODESUBAssets.FindByID(String);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(DragParameters.Value) <> Type("Array") Then
		Return;
	EndIf;
	
	UsersArray = New Array;
	For Each SubAssetUsersLine In DragParameters.Value Do
		StructureToFill = New Structure("User");
		If TypeOf(SubAssetUsersLine) = Type("FormDataCollectionItem") Then
			FillPropertyValues(StructureToFill, SubAssetUsersLine);
		EndIf;
		If Not ValueIsFilled(StructureToFill.User) Then
			Return;
		EndIf;
		UsersArray.Add(StructureToFill.User);
	EndDo;
	
	SetUpSubAssetOfUsers(UsersArray, CurrentData.NodeID);
	
	UpdateData1();
	
EndProcedure

&AtClient
Procedure CODESUBAssetsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	If Items.SUBAssetsCODEContextMenuChangeSubAssets.Enabled Then
		ToActivateCurrentSUBAsset();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsersOfSubAssets

&AtClient
Procedure UsersOfSubAssetsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "UsersOfSubAssetsUser" Then
		ShowValue(, CurrentData.User);
		
	ElsIf Field.Name = "UsersOfSubAssetsNodeName" Then
		RowID = 0;
		CommonClientServer.GetTreeRowIDByFieldValue(
			"NodeID",
			RowID,
			CODESUBAssets.GetItems(),
			CurrentData.NodeID,
			False);
		Items.CODESUBAssets.CurrentRow = RowID;
		
	ElsIf Field.Name = "UsersOfSubAssetsIsFixed" Then
		If CurrentData.IsFixed = 0 Then
			HadChanges = UnpinSubAssetAtServer();
		Else
			HadChanges = PinSubAssetATServer();
		EndIf;
		If HadChanges Then
			UpdateData1();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExternalURLHostAddress(Command)
	
	CurrentData = Items.CODESUBAssets.CurrentData;
	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.WebServiceAddress) Then
		Return;
	EndIf;
	
	If CurrentData.CentralNode Then
		NodeID = "";
	Else
		NodeID = CurrentData.NodeID;
	EndIf;
	
	ClosingNotification1 = New CallbackDescription(
		"HostAddressOfExternalNavigationLinksONChange",
		ThisObject,
		NodeID);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExternalURLHostAddress",
		DataOfSUBAsset(NodeID),,,,,
		ClosingNotification1);
	
EndProcedure

&AtClient
Procedure HostAddressOfExternalNavigationLinksONChange(Result, NodeID) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	DataOfSUBAsset = DataOfSUBAsset(NodeID);
	DataOfSUBAsset.ExternalURLHostAddress = Result.ExternalURLHostAddress;
	DataOfSUBAsset.LocationTypeOfExternalURLHostAddress = Result.LocationTypeOfExternalURLHostAddress;
	
	ToSetDataOfSUBAsset(NodeID, DataOfSUBAsset);
	
EndProcedure

&AtClient
Procedure ActivateSUBAsset(Command)
	
	ToActivateCurrentSUBAsset();
	
EndProcedure

&AtClient
Procedure DeactivateSUBAsset(Command)
	
	CurrentData = Items.CODESUBAssets.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DeactivateSubAssetATServer(CurrentData.NodeID);
	
	UpdateData1();
	
EndProcedure

&AtClient
Procedure PinNode(Command)
	
	If PinSubAssetATServer() Then
		UpdateData1();
	EndIf;
	
EndProcedure

&AtClient
Procedure UnpinNode(Command)
	
	If UnpinSubAssetAtServer() Then
		UpdateData1();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSubAsset(Command)
	
	CurrentData = Items.CODESUBAssets.CurrentData;
	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.WebServiceAddress) Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagement3Client.OpenDMObject(
		"e1cib/command/DataProcessor.SeamlessIntegrationAdministrationPanel.Command.IntegrationSettings",
		CurrentData.WebServiceAddress);
	
EndProcedure

&AtClient
Procedure ChangeANode(Command)
	
	Notification = New CallbackDescription("ChangeANodeCompletion", ThisObject);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.NodeSelection",
		New Structure("CODESUBAssets", CODESUBAssets),
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateData1();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ToActivateCurrentSUBAsset()
	
	CurrentData = Items.CODESUBAssets.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("ToActivateCurrentSUBAssetCompletion", ThisObject);
	
	FormParameters = New Structure("NodeID, WebServiceAddress, NodeName",
		CurrentData.NodeID, CurrentData.WebServiceAddress, CurrentData.NodeName);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.ConnectToNode",
		FormParameters,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ToActivateCurrentSUBAssetCompletion(DataOfSUBAsset, NotificationParameters) Export
	
	If Not ValueIsFilled(DataOfSUBAsset) Or DataOfSUBAsset = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	UpdateData1();
	
EndProcedure

&AtServerNoContext
Function DataOfSUBAsset(Val NodeID)
	
	Return InformationRegisters.DataOf1CDocumentManagementNodes.DataOfSUBAsset(NodeID);
	
EndFunction

&AtServer
Procedure DeactivateSubAssetATServer(Val NodeID)
	
	InformationRegisters.DataOf1CDocumentManagementNodes.DeactivateSUBAsset(NodeID);
	
EndProcedure

&AtServer
Procedure FillInSUBAssetLine(StringTreeSubAssetsCODE, StringDataOfSUBAssetsCODE, WebServiceAddress)
	
	StringDataOfSUBAssetsCODE.NodeName = StringTreeSubAssetsCODE.NodeName;
	StringDataOfSUBAssetsCODE.NodeID = StringTreeSubAssetsCODE.NodeID;
	
	If IsBlankString(WebServiceAddress) Then
		StringTreeSubAssetsCODE.Running = 1;
		StringTreeSubAssetsCODE.PresentationOfNode = StringTreeSubAssetsCODE.NodeName;
	Else
		StringDataOfSUBAssetsCODE.WebServiceAddress = WebServiceAddress;
		
		StringTreeSubAssetsCODE.Running = 2;
		StringTreeSubAssetsCODE.WebServiceAddress = WebServiceAddress;
		StringTreeSubAssetsCODE.PresentationOfNode = StrTemplate("%1 (%2)", StringTreeSubAssetsCODE.NodeName, WebServiceAddress);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSubAssetsAndUsers()
	
	Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy(
		False,
		AddressOfCentralSUBAsset);
	If Proxy = Undefined Then
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
		Return;
	EndIf;
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = ListOfConditions.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "getAllData";
	Condition.value = True;
	FilterConditions.Add(Condition);
	
	ResponseIsListOfObjects = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMDataExchangeNode",
		ListOfConditions);
	XDTOSUBAssets = ResponseIsListOfObjects.items; // XDTOList
	
	ReFillTreeWithSUBAssetsCODE(XDTOSUBAssets);
	
	MatchingUsersOfSUBAssets = New Map;
	
	RowsCount = XDTOSUBAssets.Count();
	For LineNumber = 1 To RowsCount Do
		TreeRow = XDTOSUBAssets[RowsCount - LineNumber];
		XDTOSubAsset = TreeRow.object;
		For Each UserBefore In XDTOSubAsset.users Do
			IPUser =
				IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
					IntegrationWith1CDocumentManagementCoreCached.TypeUsers(),
					IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(UserBefore),,
					False);
			If ValueIsFilled(IPUser) Then
				If MatchingUsersOfSUBAssets[IPUser] = Undefined Then
					MatchingUsersOfSUBAssets[IPUser] = New Array;
					MatchingUsersOfSUBAssets[IPUser].Add(XDTOSubAsset);
				Else
					MatchingUsersOfSUBAssets[IPUser].Add(XDTOSubAsset);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	Query = New Query(
		"SELECT
		|	Users.Ref AS User,
		|	Users.Department AS Department,
		|	Users.IBUserID AS IBUserID
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	NOT Users.IsInternal
		|	AND NOT Users.Invalid
		|	AND NOT Users.DeletionMark
		|
		|ORDER BY
		|	Users.Description");
	Selection = Query.Execute().Select();
	
	ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
	
	UsersOfSubAssets.Clear();
	
	AssignedSUBAssets = InformationRegisters.MapUsersTo1CDocumentManagementNodes.UserSubAssets();
	
	While Selection.Next() Do
		SubAssetUsersLine = UsersOfSubAssets.Add();
		FillPropertyValues(SubAssetUsersLine, Selection, "User, Department");
		
		UserSSubAsset = Undefined;
		
		SubAssetUsersLine.IsFixed = 1;
		IdOfAssignedSubAsset = AssignedSUBAssets[Selection.User];
		If IdOfAssignedSubAsset <> Undefined Then
			FoundRows = DataOfSUBAssetsCODE.FindRows(New Structure("NodeID", IdOfAssignedSubAsset));
			If FoundRows.Count() > 0 And ValueIsFilled(FoundRows[0].WebServiceAddress) Then
				SubAssetUsersLine.IsFixed = 0;
				UserSSubAsset = FoundRows[0];
			Else
				// If the fixed sub-asset is not active or it is not in the holding at all, we will delete the outdated PC entry.
				InformationRegisters.MapUsersTo1CDocumentManagementNodes.ClearBinding(Selection.User);
			EndIf;
		EndIf;
		
		If UserSSubAsset = Undefined Then
			UserSXDTOSUBAssets = MatchingUsersOfSUBAssets[Selection.User];
			If UserSXDTOSUBAssets = Undefined Then
				UserSSubAsset = DataOfSUBAssetsCODE[0]; // The central sub-asset.
			Else
				PrioritySubAsset = ModuleIntegrationWith1CDocumentManagement3.PrioritySubAsset(
					Selection.User,
					UserSXDTOSUBAssets);
				If PrioritySubAsset = "" Then
					UserSSubAsset = DataOfSUBAssetsCODE[0]; // The central sub-asset.
				Else
					FoundRows = DataOfSUBAssetsCODE.FindRows(New Structure("NodeID", PrioritySubAsset));
					UserSSubAsset = FoundRows[0];
				EndIf;
			EndIf;
		EndIf;
		
		SubAssetUsersLine.NodeName = UserSSubAsset.NodeName;
		SubAssetUsersLine.NodeID = UserSSubAsset.NodeID;
	EndDo;
	
	Users.FillUserPictureNumbers(UsersOfSubAssets, "User", "PictureNumber");
	
EndProcedure

&AtServer
Procedure ReFillTreeWithSUBAssetsCODE(XDTOSUBAssets)
	
	DataOfSUBAssetsCODE.Clear();
	
	NodesData = InformationRegisters.DataOf1CDocumentManagementNodes.NodesData();
	
	CentralSubAssetXDTOString = Undefined;
	NonOutputLines = New Array;
	RowsCount = XDTOSUBAssets.Count();
	For LineNumber = 1 To RowsCount Do
		TreeRow = XDTOSUBAssets[RowsCount - LineNumber];
		If TreeRow.object.isCentral Then
			CentralSubAssetXDTOString = TreeRow;
		Else
			NonOutputLines.Add(TreeRow);
		EndIf;
	EndDo;
	
	TreeOfSubAssetsIsCODE = FormAttributeToValue("CODESUBAssets");
	
	TreeOfSubAssetsIsCODE.Rows.Clear();
	TreeOfSubAssetsIsCODE.Rows.Add().PresentationOfNode = NStr("vi = 'Tất cả người sử dụng';
																|ru = 'Все пользователи';
																|en = 'All users'; fa = 'همه کاربران';
																|it = 'Все пользователи';
																|pl = 'Wszyscy użytkownicy';
																|tr = 'Tüm kullanıcılar'");
	
	StringTreeSubAssetsCODE = TreeOfSubAssetsIsCODE.Rows.Add();
	StringTreeSubAssetsCODE.NodeName = CentralSubAssetXDTOString.object.name;
	StringTreeSubAssetsCODE.NodeID = CentralSubAssetXDTOString.object.objectID.ID;
	StringTreeSubAssetsCODE.CentralNode = True;
	FillInSUBAssetLine(StringTreeSubAssetsCODE, DataOfSUBAssetsCODE.Add(), AddressOfCentralSUBAsset);
	
	While NonOutputLines.Count() > 0 Do
		RowsCount = NonOutputLines.Count();
		For LineNumber = 1 To RowsCount Do
			IndexOf = RowsCount - LineNumber;
			TreeRow = NonOutputLines[IndexOf];
			FilterParameters = New Structure("NodeID", TreeRow.parentID.ID);
			FoundRows = TreeOfSubAssetsIsCODE.Rows.FindRows(FilterParameters, True);
			If FoundRows.Count() > 0 Then
				ParentRow = FoundRows[0];
			Else
				Continue;
			EndIf;
			StringTreeSubAssetsCODE = ParentRow.Rows.Add();
			XDTOSubAsset = TreeRow.object;
			StringTreeSubAssetsCODE.NodeName = XDTOSubAsset.name;
			StringTreeSubAssetsCODE.NodeID = XDTOSubAsset.objectID.ID;
			WebServiceAddress = "";
			DataOfSUBAsset = NodesData[StringTreeSubAssetsCODE.NodeID];
			If DataOfSUBAsset <> Undefined Then
				WebServiceAddress = DataOfSUBAsset.WebServiceAddress;
			EndIf;
			FillInSUBAssetLine(StringTreeSubAssetsCODE, DataOfSUBAssetsCODE.Add(), WebServiceAddress);
			NonOutputLines.Delete(IndexOf);
		EndDo;
	EndDo;
	
	ValueToFormAttribute(TreeOfSubAssetsIsCODE, "CODESUBAssets");
	
EndProcedure

// Checks the connection to the DO by displaying the authorization window, if necessary, and changing the form according to the result.
//
&AtClient
Procedure TestConnection()
	
	CallbackDescription = New CallbackDescription("TestConnectionCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,,
		False,
		True,
		AddressOfCentralSUBAsset);
	
EndProcedure

&AtClient
Procedure TestConnectionCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		FillInSubAssetsAndUsers();
	Else // Couldn't connect to BEFORE.
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
	EndIf;
	
EndProcedure

&AtServer
Function PinSubAssetATServer()
	
	HadChanges = False;
	
	BeginTransaction();
	
	Try
		
		For Each RowID In Items.UsersOfSubAssets.SelectedRows Do
			String = UsersOfSubAssets.FindByID(RowID);
			If String = Undefined Or String.IsFixed <> 1 Then
				Continue;
			EndIf;
			
			HadChanges = True;
			InformationRegisters.MapUsersTo1CDocumentManagementNodes.InstallUserSubAsset(
				String.User,
				String.NodeID)
		EndDo;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return HadChanges;
	
EndFunction

&AtClient
Procedure UpdateData1()
	
	CurrentUser = Undefined;
	If Items.UsersOfSubAssets.CurrentData <> Undefined Then
		CurrentUser = Items.UsersOfSubAssets.CurrentData.User;
	EndIf;
	
	TreeType = IntegrationWith1CDocumentManagement3Client.TreeType();
	TreeType.ThisIsTreeOfCODESUBAssets = True;
	StateOfTreeIsCODESUBAssets = IntegrationWith1CDocumentManagement3Client.CurCurrentStateOfTree(
		TreeType,
		CODESUBAssets.GetItems(),
		Items.CODESUBAssets);
	
	FillInSubAssetsAndUsers();
	
	IntegrationWith1CDocumentManagement3Client.ExpandTheTree(
		TreeType,
		CODESUBAssets.GetItems(),
		Items.CODESUBAssets,
		StateOfTreeIsCODESUBAssets);
	
	If ValueIsFilled(CurrentUser) Then
		UsersOfSelectionSUBAssets = New Structure("User", CurrentUser);
		If Not IsBlankString(Items.UsersOfSubAssets.RowFilter.NodeID) Then
			UsersOfSelectionSUBAssets.Insert("NodeID", Items.UsersOfSubAssets.RowFilter.NodeID);
		EndIf;
		FoundRows = UsersOfSubAssets.FindRows(UsersOfSelectionSUBAssets);
		If FoundRows.Count() > 0 Then
			Items.UsersOfSubAssets.CurrentRow = FoundRows[0].GetID();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function UnpinSubAssetAtServer()
	
	HadChanges = False;
	
	BeginTransaction();
	
	Try
		
		For Each RowID In Items.UsersOfSubAssets.SelectedRows Do
			String = UsersOfSubAssets.FindByID(RowID);
			If String = Undefined Or String.IsFixed <> 0 Then
				Continue;
			EndIf;
			
			HadChanges = True;
			InformationRegisters.MapUsersTo1CDocumentManagementNodes.ClearBinding(String.User);
		EndDo;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return HadChanges;
	
EndFunction

&AtClient
Procedure ChangeANodeCompletion(SelectedNode, NotificationParameters) Export
	
	If Not StringFunctionsClientServer.IsUUID(SelectedNode) Then
		Return;
	EndIf;
	
	UsersArray = New Array;
	For Each RowID In Items.UsersOfSubAssets.SelectedRows Do
		String = UsersOfSubAssets.FindByID(RowID);
		If String = Undefined Then
			Continue;
		EndIf;
		UsersArray.Add(String.User);
	EndDo;
	
	If UsersArray.Count() = 0 Then
		Return;
	EndIf;
	
	SetUpSubAssetOfUsers(UsersArray, SelectedNode);
	
	UpdateData1();
	
EndProcedure

&AtServerNoContext
Procedure ToSetDataOfSUBAsset(Val NodeID, Val DataOfSUBAsset)
	
	InformationRegisters.DataOf1CDocumentManagementNodes.ToSetDataOfSUBAsset(NodeID, DataOfSUBAsset);
	
EndProcedure

&AtClient
Procedure SetUpSubAssetOfUsers(UsersArray, NodeID)
	
	SetUpSubAssetOfUsersATServer(UsersArray, NodeID);
	
	StringsDataSUBAssetsCODE = DataOfSUBAssetsCODE.FindRows(New Structure("NodeID", NodeID));
	NodeName = StringsDataSUBAssetsCODE[0].NodeName;
	
	If UsersArray.Count() = 1 Then
		Explanation = StrTemplate(
			NStr("vi = 'Người sử dụng ""%1"" được chuyển vào nút ""%2""';
				|ru = 'Пользователь ""%1"" перемещен в узел ""%2""';
				|en = 'The ""%1"" user is moved to the ""%2"" node'; fa = 'The ""%1"" user is moved to the ""%2"" node';
				|it = 'Пользователь ""%1"" перемещен в узел ""%2""';
				|pl = 'The ""%1"" user is moved to the ""%2"" node';
				|tr = '""%1"" kullanıcısı, ""%2"" düğümüne aktarıldı'"),
			UsersArray[0],
			NodeName);
	Else
		Explanation = StrTemplate(
			NStr("vi = 'Người sử dụng được chuyển vào nút ""%1""';
				|ru = 'Пользователи перемещены в узел ""%1""';
				|en = 'The users are moved to the ""%1"" node'; fa = 'The users are moved to the ""%1"" node';
				|it = 'Пользователи перемещены в узел ""%1""';
				|pl = 'The users are moved to the ""%1"" node';
				|tr = 'Kullanıcılar ""%1"" düğümünde yer değiştirdi'"),
			NodeName);
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Đã ghim nút';
								|ru = 'Узел закреплен';
								|en = 'Node is pinned'; fa = 'Node is pinned';
								|it = 'Узел закреплен';
								|pl = 'Node is pinned';
								|tr = 'Düğüm sabitlendi'"),, Explanation);
	
EndProcedure

&AtServerNoContext
Procedure SetUpSubAssetOfUsersATServer(Val UsersArray, Val NodeID)
	
	InformationRegisters.MapUsersTo1CDocumentManagementNodes.SetUpSubAssetOfUsers(
		UsersArray,
		NodeID);
	
EndProcedure

#EndRegion
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Clears the user's binding to a specific 1C sub-asset:Document management.
//
// Parameters:
//   User - DefinedType.User - user.
//
Procedure ClearBinding(User) Export
	
	Record = CreateRecordManager();
	Record.User = User;
	Record.Delete();
	
EndProcedure

// Receives a 1C sub-asset:The workflow to which the user is assigned.
//
// Parameters:
//   User - DefinedType.User - user.
//
// Returns:
//   String - ID of the sub-asset.
//
Function UserSSubAsset(User) Export
	
	NodeID = UserSubAssets()[User];
	If NodeID = Undefined Then
		NodeID = "";
	EndIf;
	
	Return NodeID;
	
EndFunction

// Gets all the matches of users to 1C sub-assets:Document management, set manually.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - DefinedType.User - user.
//     * Value - String - ID of the sub-asset.
//
Function UserSubAssets() Export
	
	Result = New Map;
	
	Query = New Query(
		"SELECT
		|	MapUsersTo1CDocumentManagementNodes.User,
		|	MapUsersTo1CDocumentManagementNodes.NodeID
		|FROM
		|	InformationRegister.MapUsersTo1CDocumentManagementNodes AS MapUsersTo1CDocumentManagementNodes");
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Result.Insert(Selection.User, Selection.NodeID);
	EndDo;
	
	Return Result;
	
EndFunction

// Establishes the user's compliance with a specific 1C sub-asset:Document management.
//
// Parameters:
//   User - DefinedType.User - user.
//   NodeID - String - ID of the sub-asset.
//
Procedure InstallUserSubAsset(User, NodeID) Export
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.User.Set(User);
	
	Record = RecordSet.Add();
	Record.User = User;
	Record.NodeID = NodeID;
	
	RecordSet.Write();
	
	If Users.CurrentUser() = User Then
		SessionParameters.IntegrationWith1CDocumentManagementNode = NodeID;
	EndIf;
	
EndProcedure

// Establishes the correspondence of a user group to a specific 1C sub-asset:Document management.
//
// Parameters:
//   UsersArray - Array of DefinedType.User - list of users.
//   NodeID - String - ID of the sub-asset.
//
Procedure SetUpSubAssetOfUsers(UsersArray, NodeID) Export
	
	BeginTransaction();
	Try
		For Each User In UsersArray Do
			InstallUserSubAsset(User, NodeID);
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf
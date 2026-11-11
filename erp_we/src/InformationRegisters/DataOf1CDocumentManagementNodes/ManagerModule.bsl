#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Retrieves data from a specific 1C sub-asset:Document management.
//
// Parameters:
//   NodeID - String - ID of the sub-asset.
//
// Returns:
//   See InformationRegisters.DataOf1CDocumentManagementNodes.NewDataOfSUBAsset
//
Function DataOfSUBAsset(NodeID) Export
	
	DataOfSUBAsset = NodesData()[NodeID];
	If DataOfSUBAsset = Undefined Then
		DataOfSUBAsset = NewDataOfSUBAsset();
	EndIf;
	
	Return DataOfSUBAsset;
	
EndFunction

// Retrieves data from all 1C sub-assets:Document management.
//
// Parameters:
//   IncludingCentralNode - Boolean - it is required to obtain data including the central node.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - String - ID of the sub-asset.
//     * Value - See InformationRegisters.DataOf1CDocumentManagementNodes.NewDataOfSUBAsset
//
Function NodesData(IncludingCentralNode = True) Export
	
	Result = New Map;
	
	Query = New Query(
		"SELECT
		|	DataOf1CDocumentManagementNodes.NodeID AS NodeID,
		|	DataOf1CDocumentManagementNodes.WebServiceAddress AS WebServiceAddress,
		|	DataOf1CDocumentManagementNodes.ExternalURLHostAddress AS ExternalURLHostAddress,
		|	DataOf1CDocumentManagementNodes.LocationTypeOfExternalURLHostAddress AS LocationTypeOfExternalURLHostAddress
		|FROM
		|	InformationRegister.DataOf1CDocumentManagementNodes AS DataOf1CDocumentManagementNodes
		|WHERE
		|	DataOf1CDocumentManagementNodes.NodeID <> """"");
	If IncludingCentralNode Then
		Query.Text = StrReplace(Query.Text, "DataOf1CDocumentManagementNodes.NodeID <> """"", "TRUE");
	EndIf;
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		DataOfSUBAsset = NewDataOfSUBAsset();
		DataOfSUBAsset.WebServiceAddress = Selection.WebServiceAddress;
		DataOfSUBAsset.ExternalURLHostAddress = Selection.ExternalURLHostAddress;
		DataOfSUBAsset.LocationTypeOfExternalURLHostAddress =
			Selection.LocationTypeOfExternalURLHostAddress;
		Result.Insert(Selection.NodeID, DataOfSUBAsset);
	EndDo;
	
	Return Result;
	
EndFunction

// Deletes all data of the sub-asset, and also clears all established user correspondences to this sub-asset.
//
// Parameters:
//   NodeID - String - ID of the sub-asset.
//
Procedure DeactivateSUBAsset(NodeID) Export
	
	BeginTransaction();
	
	Try
		
		Record = CreateRecordManager();
		Record.NodeID = NodeID;
		Record.Delete();
		
		Query = New Query(
			"SELECT
			|	MapUsersTo1CDocumentManagementNodes.User AS User
			|FROM
			|	InformationRegister.MapUsersTo1CDocumentManagementNodes AS MapUsersTo1CDocumentManagementNodes
			|WHERE
			|	MapUsersTo1CDocumentManagementNodes.NodeID = &NodeID");
		Query.SetParameter("NodeID", NodeID);
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			InformationRegisters.MapUsersTo1CDocumentManagementNodes.ClearBinding(Selection.User);
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		IntegrationWith1CDocumentManagementCore.WriteError(
			ErrorProcessing.DetailErrorDescription(ErrorInfo()),
			NStr("vi = 'Vô hiệu hóa nút';
				|ru = 'Деактивация узла';
				|en = 'Deactivate the node'; fa = 'Deactivate the node';
				|it = 'Деактивация узла';
				|pl = 'Deactivate the node';
				|tr = 'Düğüm deaktivasyonu'"));
		
		Raise ErrorProcessing.BriefErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

// Determines whether the use of 1C sub-assets is configured:Document management of the editorial office of the Holding.
//
// Returns:
//   Boolean
//
Function SUBAssetsOfHoldingAreUsed() Export
	
	Return (NodesData(False).Count() > 0);
	
EndFunction

// The constructor of the structure describing the data of the 1C sub-asset:Document management.
//
// Returns:
//   Structure:
//     * WebServiceAddress - String - the publication address of the sub-asset.
//     * ExternalURLHostAddress - String - the information security address on the local computer or at server that
//         will be used as a host for clicking on external navigation links to objects BEFORE.
//     * LocationTypeOfExternalURLHostAddress - EnumRef.InfobaseLocationType - the type
//         of information security location used for clicking on external navigation links to objects BEFORE.
//
Function NewDataOfSUBAsset() Export
	
	DataOfSUBAsset = New Structure;
	DataOfSUBAsset.Insert("WebServiceAddress", "");
	DataOfSUBAsset.Insert("ExternalURLHostAddress", "");
	DataOfSUBAsset.Insert("LocationTypeOfExternalURLHostAddress",
		Enums.InfobaseLocationType.EmptyRef());
	
	Return DataOfSUBAsset;
	
EndFunction

// Records the data of the 1C sub-asset:Document management in the information base.
//
// Parameters:
//   NodeID - String - ID of the sub-asset.
//   DataOfSUBAsset - See InformationRegisters.DataOf1CDocumentManagementNodes.NewDataOfSUBAsset
//
Procedure ToSetDataOfSUBAsset(NodeID, DataOfSUBAsset) Export
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.NodeID.Set(NodeID);
	
	Record = RecordSet.Add();
	Record.NodeID = NodeID;
	Record.WebServiceAddress = DataOfSUBAsset.WebServiceAddress;
	Record.ExternalURLHostAddress = DataOfSUBAsset.ExternalURLHostAddress;
	Record.LocationTypeOfExternalURLHostAddress = DataOfSUBAsset.LocationTypeOfExternalURLHostAddress;
	
	RecordSet.Write();
	
EndProcedure

#EndRegion

#EndIf
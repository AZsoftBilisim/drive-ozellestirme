#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// Subsystem "Basic functionality in the service model".
// General-purpose server procedures and functions:
// - Manage permissions in security profiles.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

// Ids of requests to use external resources for which the object is initialized.
Var RequestsIDs; // Array of UUID - request IDs.

// The current plan for applying requests to use external resources.
Var RequestsApplicationPlan; // Structure - Structure Fields:
//  * 
//     ** 
//     ** 
//     ** 
//     ** 
//  * 
//     ** 
//     ** 
//     ** 
//     ** 
//     ** 
//     ** 
//        *** 
//                            ,
//        *** 
//  * 
//     ** 
//     ** 
//     ** 
//     ** 
//     ** 
//     ** 
//        *** 
//                            ,
//        *** 

// The initial section of permissions (in the context of the permission holders).
Var SourcePermissionSliceByOwners; // ValueTable - Columns:
// * 
// * 
// * 
// * 
// * 
// * 
//   ** 
//                      ,
//   ** 

// The initial slice of permissions (excluding permission holders). 
Var SourcePermissionSliceIgnoringOwners; // ValueTable - Columns:
// * 
// * 
// * 
// * 
//   ** 
//                      ,
//   ** 

// A slice of permissions as a result of applying requests (in the context of permission holders).
Var RequestsApplicationResultByOwners; // ValueTable - Columns:
// * 
// * 
// * 
// * 
// * 
// * 
//   ** 
//                      ,
//   ** 

// A slice of permissions as a result of applying requests (in the context of permission holders).
Var RequestsApplicationResultIgnoringOwners; // ValueTable - Columns:
// * 
// * 
// * 
// * 
//   ** 
//      Permission to use external resources),
//   ** 

// The delta between the original and resulting permission slices (in the context of permission holders).
Var DeltaByOwners; // Structure - Fields:
//  * 
//    ** 
//    ** 
//    ** 
//    ** 
//    ** 
//    ** 
//       *** 
//                           ,
//       *** 
//  * 
//    ** 
//    ** 
//    ** 
//    ** 
//    ** 
//    ** 
//       *** 
//                           ,
//       *** 

// The delta between the original and resulting permission slices (excluding permission holders).
Var DeltaIgnoringOwners; // Structure:
//  * 
//    ** 
//    ** 
//    ** 
//    ** 
//       *** 
//                           ,
//       *** 
//  * 
//    ** 
//    ** 
//    ** 
//    ** 
//       *** 
//                           ,
//       *** 

#EndRegion

#Region Private

// Adds the request ID to the list of processed requests. After successful application, cleaning will be performed
// queries, whose identifiers have been added.
//
// Parameters:
//  QueryID - UUID - ID of the request to use external resources.
//
Procedure AddRequestID(Val QueryID) Export
	
	RequestsIDs.Add(QueryID);

EndProcedure

// Adds properties for requesting permissions to use external resources to the query application plan.
//
// Parameters:
//  ProgramModuleType - CatalogRef.MetadataObjectIDs - 
//  ModuleID - UUID - 
//  OwnerType - CatalogRef.MetadataObjectIDs - 
//  OwnerID - UUID - 
//  Var_ReplacementMode - Boolean - 
//  PermissionsToAdd - Array of XDTODataObject, Undefined - permissions to add.
//  PermissionsToDelete - Array of XDTODataObject, Undefined - permissions to delete.
//
Procedure AddRequestForPermissionsToUseExternalResources(
		Val ProgramModuleType, Val ModuleID,
		Val OwnerType, Val OwnerID,
		Val Var_ReplacementMode,
		Val PermissionsToAdd = Undefined,
		Val PermissionsToDelete = Undefined) Export
	
	If Var_ReplacementMode Then
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", ProgramModuleType);
		Filter.Insert("ModuleID", ModuleID);
		Filter.Insert("OwnerType", OwnerType);
		Filter.Insert("OwnerID", OwnerID);
		
		SafeModeManagerInternalSaaS.PermissionsTableRow(
			RequestsApplicationPlan.PermissionsToReplace, Filter);
		
	EndIf;
	
	If PermissionsToAdd <> Undefined Then
		
		For Each PermissionToAdd In PermissionsToAdd Do
			
			Filter = New Structure();
			Filter.Insert("ProgramModuleType", ProgramModuleType);
			Filter.Insert("ModuleID", ModuleID);
			Filter.Insert("OwnerType", OwnerType);
			Filter.Insert("OwnerID", OwnerID);
			Filter.Insert("Type", PermissionToAdd.Type().Name);
			
			String = SafeModeManagerInternalSaaS.PermissionsTableRow(
				RequestsApplicationPlan.ItemsToAdd, Filter);
			
			PermissionKey = SafeModeManagerInternalSaaS.PermissionKey(PermissionToAdd);
			String.Permissions.Insert(PermissionKey, Common.XDTODataObjectToXMLString(PermissionToAdd));
			
		EndDo;
		
	EndIf;
	
	If PermissionsToDelete <> Undefined Then
		
		For Each PermissionToDelete In PermissionsToDelete Do
			
			Filter = New Structure();
			Filter.Insert("ProgramModuleType", ProgramModuleType);
			Filter.Insert("ModuleID", ModuleID);
			Filter.Insert("OwnerType", OwnerType);
			Filter.Insert("OwnerID", OwnerID);
			Filter.Insert("Type", PermissionToAdd.Type().Name);
			
			String = SafeModeManagerInternalSaaS.PermissionsTableRow(
				RequestsApplicationPlan.ItemsToDelete, Filter);
			
			PermissionKey = SafeModeManagerInternalSaaS.PermissionKey(PermissionToDelete);
			String.Permissions.Add(PermissionKey, Common.XDTODataObjectToXMLString(PermissionToDelete));
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Calculates the result of applying requests to use external resources.
//
Procedure CalculateRequestsApplication() Export
	
	ExternalTransaction = TransactionActive();
	
	If Not ExternalTransaction Then
		BeginTransaction();
	EndIf;
	
	Try
		
		SafeModeManagerInternalSaaS.LockRegistersOfGrantedPermissions();
		
		SourcePermissionSliceByOwners = SafeModeManagerInternalSaaS.PermissionsSlice();
		CalculateRequestsApplicationResultByOwners();
		CalculateDeltaByOwners();
		
		SourcePermissionSliceIgnoringOwners = SafeModeManagerInternalSaaS.PermissionsSlice(False, True);
		CalculateRequestsApplicationResultIgnoringOwners();
		CalculateDeltaIgnoringOwners();
		
		If Not ExternalTransaction Then
			RollbackTransaction();
		EndIf;
		
	Except
		
		If Not ExternalTransaction Then
			RollbackTransaction();
		EndIf;
		
		Raise;
		
	EndTry;
	
EndProcedure

// Calculates the result of applying queries by owner.
//
Procedure CalculateRequestsApplicationResultByOwners()
	
	RequestsApplicationResultByOwners = New ValueTable();
	
	For Each SourceColumn In SourcePermissionSliceByOwners.Columns Do
		RequestsApplicationResultByOwners.Columns.Add(SourceColumn.Name, SourceColumn.ValueType);
	EndDo;
	
	For Each InitialString In SourcePermissionSliceByOwners Do
		NewRow = RequestsApplicationResultByOwners.Add();
		FillPropertyValues(NewRow, InitialString);
	EndDo;
	
	// Applying the plan
	
	// Replacing
	For Each ReplacementTableRow In RequestsApplicationPlan.PermissionsToReplace Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", ReplacementTableRow.ProgramModuleType);
		Filter.Insert("ModuleID", ReplacementTableRow.ModuleID);
		Filter.Insert("OwnerType", ReplacementTableRow.OwnerType);
		Filter.Insert("OwnerID", ReplacementTableRow.OwnerID);
		
		Rows = RequestsApplicationResultByOwners.FindRows(Filter);
		
		For Each String In Rows Do
			RequestsApplicationResultByOwners.Delete(String);
		EndDo;
		
	EndDo;
	
	// Adding Permissions
	For Each PermissionsToAddRow In RequestsApplicationPlan.ItemsToAdd Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", PermissionsToAddRow.ProgramModuleType);
		Filter.Insert("ModuleID", PermissionsToAddRow.ModuleID);
		Filter.Insert("OwnerType", PermissionsToAddRow.OwnerType);
		Filter.Insert("OwnerID", PermissionsToAddRow.OwnerID);
		Filter.Insert("Type", PermissionsToAddRow.Type);
		
		String = SafeModeManagerInternalSaaS.PermissionsTableRow(
			RequestsApplicationResultByOwners, Filter);
		
		For Each KeyAndValue In PermissionsToAddRow.Permissions Do
			String.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
		
	EndDo;
	
	// Removing Permissions
	For Each ItemsToDeleteRow In RequestsApplicationPlan.ItemsToDelete Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", ItemsToDeleteRow.ProgramModuleType);
		Filter.Insert("ModuleID", ItemsToDeleteRow.ModuleID);
		Filter.Insert("OwnerType", ItemsToDeleteRow.OwnerType);
		Filter.Insert("OwnerID", ItemsToDeleteRow.OwnerID);
		Filter.Insert("Type", ItemsToDeleteRow.Type);
		
		String = SafeModeManagerInternalSaaS.PermissionsTableRow(
			RequestsApplicationResultByOwners, Filter);
		
		For Each KeyAndValue In ItemsToDeleteRow.Permissions Do
			String.Permissions.Delete(KeyAndValue.Key);
		EndDo;
		
	EndDo;
	
EndProcedure

// Calculates the result of applying queries without taking owners into account.
//
Procedure CalculateRequestsApplicationResultIgnoringOwners()
	
	RequestsApplicationResultIgnoringOwners = New ValueTable();
	If TypeOf(SourcePermissionSliceIgnoringOwners) = Type("ValueTable") Then
		For Each SourceColumn In SourcePermissionSliceIgnoringOwners.Columns Do
			RequestsApplicationResultIgnoringOwners.Columns.Add(SourceColumn.Name, SourceColumn.ValueType);
		EndDo;
	EndIf;
	
	For Each ResultString1 In RequestsApplicationResultByOwners Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", ResultString1.ProgramModuleType);
		Filter.Insert("ModuleID", ResultString1.ModuleID);
		Filter.Insert("Type", ResultString1.Type);
		
		String = SafeModeManagerInternalSaaS.PermissionsTableRow(
			RequestsApplicationResultIgnoringOwners, Filter);
		
		For Each KeyAndValue In ResultString1.Permissions Do
			
			SourcePermission = Common.XDTODataObjectFromXMLString(KeyAndValue.Value);
			SourcePermission.Description = ""; // The descriptions should not affect the hash amounts for the variant without taking into account the owners
			
			PermissionKey = SafeModeManagerInternalSaaS.PermissionKey(SourcePermission);
			
			Resolution = String.Permissions.Get(PermissionKey);
			
			If Resolution = Undefined Then
				
				If ResultString1.Type = "FileSystemAccess" Then
					
					// For permissions to use the file system directory, we additionally look
					// for nested or enclosing permissions.
					
					If SourcePermission.AllowedRead Then
						
						If SourcePermission.AllowedWrite Then
							
							// Let's search for permission to use the same directory, but read-only.
							
							PermissionCopy = Common.XDTODataObjectFromXMLString(Common.XDTODataObjectToXMLString(SourcePermission));
							PermissionCopy.AllowedWrite = False;
							CopyKey = SafeModeManagerInternalSaaS.PermissionKey(PermissionCopy);
							
							NestedPermission = String.Permissions.Get(CopyKey);
							
							If NestedPermission <> Undefined Then
								
								// Delete the nested permission, after adding the current one, it will not be needed
								String.Permissions.Delete(CopyKey);
								
							EndIf;
							
						Else
							
							// Let's search for permission to use the same directory, but also for writing.
							
							PermissionCopy = Common.XDTODataObjectFromXMLString(Common.XDTODataObjectToXMLString(SourcePermission));
							PermissionCopy.AllowedWrite = True;
							CopyKey = SafeModeManagerInternalSaaS.PermissionKey(PermissionCopy);
							
							ParentPermission = String.Permissions.Get(CopyKey);
							
							If ParentPermission <> Undefined Then
								
								// There is no need to process this permission, the directory will be resolved at the expense of the enclosing one.
								Continue;
								
							EndIf;
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
				String.Permissions.Insert(PermissionKey, Common.XDTODataObjectToXMLString(SourcePermission));
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Calculates the Delta of the two sections of permissions in the context of permit-holders.
//
Procedure CalculateDeltaByOwners()
	
	DeltaByOwners = New Structure();
	
	DeltaByOwners.Insert("ItemsToAdd", New ValueTable);
	DeltaByOwners.ItemsToAdd.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToAdd.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToAdd.Columns.Add("OwnerID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToAdd.Columns.Add("Type", New TypeDescription("String"));
	DeltaByOwners.ItemsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));
	
	DeltaByOwners.Insert("ItemsToDelete", New ValueTable);
	DeltaByOwners.ItemsToDelete.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToDelete.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaByOwners.ItemsToDelete.Columns.Add("OwnerID", New TypeDescription("UUID"));
	DeltaByOwners.ItemsToDelete.Columns.Add("Type", New TypeDescription("String"));
	DeltaByOwners.ItemsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));
	
	// We compare the original resolutions with the resulting ones
	
	For Each String In SourcePermissionSliceByOwners Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", String.ProgramModuleType);
		Filter.Insert("ModuleID", String.ModuleID);
		Filter.Insert("OwnerType", String.OwnerType);
		Filter.Insert("OwnerID", String.OwnerID);
		Filter.Insert("Type", String.Type);
		
		Rows = RequestsApplicationResultByOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			ResultString1 = Rows.Get(0);
		Else
			ResultString1 = Undefined;
		EndIf;
		
		For Each KeyAndValue In String.Permissions Do
			
			If ResultString1 = Undefined Or ResultString1.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The permission was in the original ones, but is missing in the resulting ones - this is the permission being deleted.
				
				ItemsToDeleteRow = SafeModeManagerInternalSaaS.PermissionsTableRow(
					DeltaByOwners.ItemsToDelete, Filter);
				
				If ItemsToDeleteRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					ItemsToDeleteRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// We compare the resulting resolutions with the original ones
	
	For Each String In RequestsApplicationResultByOwners Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", String.ProgramModuleType);
		Filter.Insert("ModuleID", String.ModuleID);
		Filter.Insert("OwnerType", String.OwnerType);
		Filter.Insert("OwnerID", String.OwnerID);
		Filter.Insert("Type", String.Type);
		
		Rows = SourcePermissionSliceByOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			InitialString = Rows.Get(0);
		Else
			InitialString = Undefined;
		EndIf;
		
		For Each KeyAndValue In String.Permissions Do
			
			If InitialString = Undefined Or InitialString.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The resolution is in the resulting ones, but it is not in the source ones - this is the resolution being added.
				
				PermissionsToAddRow = SafeModeManagerInternalSaaS.PermissionsTableRow(
					DeltaByOwners.ItemsToAdd, Filter);
				
				If PermissionsToAddRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					PermissionsToAddRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Calculates the Delta of the two sections of the permits without the account holders permission.
//
Procedure CalculateDeltaIgnoringOwners()
	
	DeltaIgnoringOwners = New Structure();
	
	DeltaIgnoringOwners.Insert("ItemsToAdd", New ValueTable);
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("Type", New TypeDescription("String"));
	DeltaIgnoringOwners.ItemsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));
	
	DeltaIgnoringOwners.Insert("ItemsToDelete", New ValueTable);
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("Type", New TypeDescription("String"));
	DeltaIgnoringOwners.ItemsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));
	
	// We compare the original resolutions with the resulting ones
	
	For Each String In SourcePermissionSliceIgnoringOwners Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", String.ProgramModuleType);
		Filter.Insert("ModuleID", String.ModuleID);
		Filter.Insert("Type", String.Type);
		
		Rows = RequestsApplicationResultIgnoringOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			ResultString1 = Rows.Get(0);
		Else
			ResultString1 = Undefined;
		EndIf;
		
		For Each KeyAndValue In String.Permissions Do
			
			If ResultString1 = Undefined Or ResultString1.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The permission was in the original ones, but is missing in the resulting ones - this is the permission being deleted.
				
				ItemsToDeleteRow = SafeModeManagerInternalSaaS.PermissionsTableRow(
					DeltaIgnoringOwners.ItemsToDelete, Filter);
				
				If ItemsToDeleteRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					ItemsToDeleteRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// We compare the resulting resolutions with the original ones
	
	For Each String In RequestsApplicationResultIgnoringOwners Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", String.ProgramModuleType);
		Filter.Insert("ModuleID", String.ModuleID);
		Filter.Insert("Type", String.Type);
		
		Rows = SourcePermissionSliceIgnoringOwners.FindRows(Filter);
		If Rows.Count() > 0 Then
			InitialString = Rows.Get(0);
		Else
			InitialString = Undefined;
		EndIf;
		
		For Each KeyAndValue In String.Permissions Do
			
			If InitialString = Undefined Or InitialString.Permissions.Get(KeyAndValue.Key) = Undefined Then
				
				// The resolution is in the resulting ones, but it is not in the source ones - this is the resolution being added.
				
				PermissionsToAddRow = SafeModeManagerInternalSaaS.PermissionsTableRow(
					DeltaIgnoringOwners.ItemsToAdd, Filter);
				
				If PermissionsToAddRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					PermissionsToAddRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Returns:
// Structure:
//  * ItemsToAdd - ValueTable - description of permissions and columns to add:
//    ** ProgramModuleType - CatalogRef.MetadataObjectIDs,
//    ** ModuleID - UUID,
//    ** Type - String - name of the XDTO type that describes permissions,
//    ** Permissions - Map of KeyAndValue - description of permissions:
//       *** Key - String - permission key (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//                           ,
//       *** Value - XDTODataObject - XDTO-description of the resolution,
//  * ItemsToDelete - ValueTable - description of permissions to delete, columns:
//    ** ProgramModuleType - CatalogRef.MetadataObjectIDs,
//    ** ModuleID - UUID,
//    ** Type - String - name of the XDTO type that describes permissions,
//    ** Permissions - Map of KeyAndValue - description of permissions:
//       *** Key - String - permission key (See InformationRegisters.PermissionsToUseExternalResources.PermissionKey)
//                           ,
//       *** Value - XDTODataObject - XDTO - description of the permission.
//
Function DeltaIgnoringOwners() Export
	
	Return DeltaIgnoringOwners;
	
EndFunction

// Checks whether permissions must be applied in the server cluster.
//
// Returns:
//   Boolean - 
//
Function MustApplyPermissionsInServersCluster() Export
	
	Return DeltaIgnoringOwners.ItemsToAdd.Count() > 0 Or DeltaIgnoringOwners.ItemsToDelete.Count() > 0;
	
EndFunction

// Checks whether permissions need to be written to registers.
//
// Returns:
//   Boolean - indicates whether permission should be recorded.
//
Function RecordPermissionsToRegisterRequired() Export
	
	Return DeltaByOwners.ItemsToAdd.Count() > 0 Or DeltaByOwners.ItemsToDelete.Count() > 0;
	
EndFunction


// Serializes the internal state of an object.
// 
// Returns:
// 	String - the state of the object.
Function WriteStateToXMLString() Export
	
	State = New Structure();
	
	State.Insert("SourcePermissionSliceByOwners", SourcePermissionSliceByOwners);
	State.Insert("RequestsApplicationResultByOwners", RequestsApplicationResultByOwners);
	State.Insert("DeltaByOwners", DeltaByOwners);
	State.Insert("SourcePermissionSliceIgnoringOwners", SourcePermissionSliceIgnoringOwners);
	State.Insert("RequestsApplicationResultIgnoringOwners", RequestsApplicationResultIgnoringOwners);
	State.Insert("DeltaIgnoringOwners", DeltaIgnoringOwners);
	State.Insert("RequestsIDs", RequestsIDs);
	
	Return Common.ValueToXMLString(State);
	
EndFunction

// Deserializes the internal state of the object.
//
// Parameters:
//  XMLLine - String - the result returned by the write state function in the XML () String.
//
Procedure ReadStateFromXMLString(Val XMLLine) Export
	
	State = Common.ValueFromXMLString(XMLLine);
	
	SourcePermissionSliceByOwners = State.SourcePermissionSliceByOwners;
	RequestsApplicationResultByOwners = State.RequestsApplicationResultByOwners;
	DeltaByOwners = State.DeltaByOwners;
	SourcePermissionSliceIgnoringOwners = State.SourcePermissionSliceIgnoringOwners;
	RequestsApplicationResultIgnoringOwners = State.RequestsApplicationResultIgnoringOwners;
	DeltaIgnoringOwners = State.DeltaIgnoringOwners;
	RequestsIDs = State.RequestsIDs;
	
EndProcedure

// Registers the fact of applying requests to use external resources in the information security system.
//
Procedure CompleteApplyRequestsToUseExternalResources() Export
	
	BeginTransaction();
	
	Try
		
		If RecordPermissionsToRegisterRequired() Then
			
			For Each ItemsToDelete In DeltaByOwners.ItemsToDelete Do
				
				For Each KeyAndValue In ItemsToDelete.Permissions Do
					
					SafeModeManagerInternalSaaS.DeletePermission(
						ItemsToDelete.ProgramModuleType,
						ItemsToDelete.ModuleID,
						ItemsToDelete.OwnerType,
						ItemsToDelete.OwnerID,
						KeyAndValue.Key,
						Common.XDTODataObjectFromXMLString(KeyAndValue.Value));
					
				EndDo;
				
			EndDo;
			
			For Each ItemsToAdd In DeltaByOwners.ItemsToAdd Do
				
				For Each KeyAndValue In ItemsToAdd.Permissions Do
					
					SafeModeManagerInternalSaaS.AddPermission(
						ItemsToAdd.ProgramModuleType,
						ItemsToAdd.ModuleID,
						ItemsToAdd.OwnerType,
						ItemsToAdd.OwnerID,
						KeyAndValue.Key,
						Common.XDTODataObjectFromXMLString(KeyAndValue.Value));
					
				EndDo;
				
			EndDo;
			
		EndIf;
		
		SafeModeManagerInternalSaaS.DeleteRequests(RequestsIDs);
		SafeModeManagerInternalSaaS.ClearObsoleteRequests();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

Procedure CancelRequestsToUseExternalResources() Export
	
	SafeModeManagerInternalSaaS.DeleteRequests(RequestsIDs);
	
EndProcedure

#EndRegion

#Region Initialize

RequestsIDs = New Array();

RequestsApplicationPlan = New Structure();

MOIDType = New TypeDescription("CatalogRef.MetadataObjectIDs");

RequestsApplicationPlan.Insert("PermissionsToReplace", New ValueTable);
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("ProgramModuleType", MOIDType);
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("ModuleID", New TypeDescription("UUID"));
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("OwnerType", MOIDType);
RequestsApplicationPlan.PermissionsToReplace.Columns.Add("OwnerID", New TypeDescription("UUID"));

RequestsApplicationPlan.Insert("ItemsToAdd", New ValueTable);
RequestsApplicationPlan.ItemsToAdd.Columns.Add("ProgramModuleType", MOIDType);
RequestsApplicationPlan.ItemsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
RequestsApplicationPlan.ItemsToAdd.Columns.Add("OwnerType", MOIDType);
RequestsApplicationPlan.ItemsToAdd.Columns.Add("OwnerID", New TypeDescription("UUID"));
RequestsApplicationPlan.ItemsToAdd.Columns.Add("Type", New TypeDescription("String"));
RequestsApplicationPlan.ItemsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));

RequestsApplicationPlan.Insert("ItemsToDelete", New ValueTable);
RequestsApplicationPlan.ItemsToDelete.Columns.Add("ProgramModuleType", MOIDType);
RequestsApplicationPlan.ItemsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
RequestsApplicationPlan.ItemsToDelete.Columns.Add("OwnerType", MOIDType);
RequestsApplicationPlan.ItemsToDelete.Columns.Add("OwnerID", New TypeDescription("UUID"));
RequestsApplicationPlan.ItemsToDelete.Columns.Add("Type", New TypeDescription("String"));
RequestsApplicationPlan.ItemsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));

AdministrationOperations = New ValueTable;
AdministrationOperations.Columns.Add("ProgramModuleType", MOIDType);
AdministrationOperations.Columns.Add("ModuleID", New TypeDescription("UUID"));
AdministrationOperations.Columns.Add("Operation", New TypeDescription("EnumRef.SecurityProfileAdministrativeOperations"));
AdministrationOperations.Columns.Add("Name", New TypeDescription("String"));

#EndRegion

#EndIf

///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

// Array of UUID - Requests to use external resources for using which this object is initialized.
// 
//
Var RequestsIDs;

// Administration operation execution plan upon applying requests to use external resources.
Var AdministrationOperations; // See AdministrationOperations

// The current plan of applying requests to use external resources.
Var RequestsApplicationPlan; // See RequestsApplicationPlan

// Source permission slice (by permission owners).
Var SourcePermissionSliceByOwners; // See InformationRegisters.PermissionsToUseExternalResources.NewPermissionsSliceByOwner

// Source permission slice (owners are ignored).
Var SourcePermissionSliceIgnoringOwners; // See InformationRegisters.PermissionsToUseExternalResources.NewPermissionsSlice

// Permission slice after applying requests (by permission owners).
Var RequestsApplicationResultByOwners; // See InformationRegisters.PermissionsToUseExternalResources.NewPermissionsSliceByOwner

// Permission slice after applying requests (by permission owners).
Var RequestsApplicationResultIgnoringOwners; // See InformationRegisters.PermissionsToUseExternalResources.NewPermissionsSlice

// Delta between the source and resulting permission slices (by permission owners).
Var DeltaByOwners; // See DeltaByOwners

// Delta between the source and resulting permission slices (ignoring permission owners).
Var DeltaIgnoringOwners; // See DeltaIgnoringOwners

// Flag indication whether information about granted permissions is cleared before applying the permissions.
Var ClearingPermissionsBeforeApply; // Boolean

#EndRegion

#Region Internal

// Adds a permission ID to the list of permissions to be processed. Once the permissions are applied, the
// requests with added IDs are cleared.
//
// Parameters:
//  QueryID - UUID - an ID of the request to use
//    external resources.
//
Procedure AddRequestID(Val QueryID) Export
	
	RequestsIDs.Add(QueryID);
	
EndProcedure

// Adds a security profile administration operation to the request application plan.
//
// Parameters:
//  ProgramModuleType - CatalogRef.MetadataObjectIDs,
//  ModuleID - UUID,
//  Operation - EnumRef.SecurityProfileAdministrativeOperations,
//  Name - String - a security profile name.
//
Procedure AddAdministrationOperation(Val ProgramModuleType, Val ModuleID, Val Operation, Val Name) Export
	
	Filter = New Structure();
	Filter.Insert("ProgramModuleType", ProgramModuleType);
	Filter.Insert("ModuleID", ModuleID);
	Filter.Insert("Operation", Operation);
	
	Rows = AdministrationOperations.FindRows(Filter);
	
	If Rows.Count() = 0 Then
		
		String = AdministrationOperations.Add();
		FillPropertyValues(String, Filter);
		String.Name = Name;
		
	EndIf;
	
EndProcedure

// Adds properties of the request for permissions to use external resources to the request application plan.
//
// Parameters:
//  ProgramModuleType - CatalogRef.MetadataObjectIDs,
//  ModuleID - UUID,
//  OwnerType - CatalogRef.MetadataObjectIDs,
//  OwnerID - UUID,
//  Var_ReplacementMode - Boolean,
//  PermissionsToAdd - Array of XDTODataObject, Undefined,
//  PermissionsToDelete - Array of XDTODataObject, Undefined
//
Procedure AddRequestForPermissionsToUseExternalResources(
		Val ProgramModuleType, Val ModuleID,
		Val OwnerType, Val OwnerID,
		Val Var_ReplacementMode,
		Val PermissionsToAdd = Undefined,
		Val PermissionsToDelete = Undefined) Export
	
	Filter = New Structure();
	Filter.Insert("ProgramModuleType", ProgramModuleType);
	Filter.Insert("ModuleID", ModuleID);
	
	String = DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
		AdministrationOperations, Filter, False);
	
	If String = Undefined Then
		
		If ProgramModuleType = Catalogs.MetadataObjectIDs.EmptyRef() Then
			
			Name = SafeModeManager.InfobaseSecurityProfile();
			
		Else
			
			Name = InformationRegisters.ExternalModulesAttachmentModes.ExternalModuleAttachmentMode(
				SafeModeManagerInternal.ReferenceFormPermissionRegister(
					ProgramModuleType, ModuleID));
			
		EndIf;
		
		AddAdministrationOperation(
			ProgramModuleType,
			ModuleID,
			Enums.SecurityProfileAdministrativeOperations.RefreshEnabled,
			Name);
		
	Else
		
		Name = String.Name;
		
	EndIf;
	
	If Var_ReplacementMode Then
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", ProgramModuleType);
		Filter.Insert("ModuleID", ModuleID);
		Filter.Insert("OwnerType", OwnerType);
		Filter.Insert("OwnerID", OwnerID);
		
		DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
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
			
			String = DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
				RequestsApplicationPlan.ItemsToAdd, Filter);
			
			PermissionKey = InformationRegisters.PermissionsToUseExternalResources.PermissionKey(PermissionToAdd);
			PermissionAddition = InformationRegisters.PermissionsToUseExternalResources.PermissionAddition(PermissionToAdd);
			
			String.Permissions.Insert(PermissionKey, Common.XDTODataObjectToXMLString(PermissionToAdd));
			
			If ValueIsFilled(PermissionAddition) Then
				String.PermissionsAdditions.Insert(PermissionKey, Common.ValueToXMLString(PermissionAddition));
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If PermissionsToDelete <> Undefined Then
		
		For Each PermissionToDelete In PermissionsToDelete Do
			
			Filter = New Structure();
			Filter.Insert("ProgramModuleType", ProgramModuleType);
			Filter.Insert("ModuleID", ModuleID);
			Filter.Insert("OwnerType", OwnerType);
			Filter.Insert("OwnerID", OwnerID);
			Filter.Insert("Type", PermissionToDelete.Type().Name);
			
			String = DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
				RequestsApplicationPlan.ItemsToDelete, Filter);
			
			PermissionKey = InformationRegisters.PermissionsToUseExternalResources.PermissionKey(PermissionToDelete);
			PermissionAddition = InformationRegisters.PermissionsToUseExternalResources.PermissionAddition(PermissionToDelete);
			
			String.Permissions.Insert(PermissionKey, Common.XDTODataObjectToXMLString(PermissionToDelete));
			
			If ValueIsFilled(PermissionAddition) Then
				String.PermissionsAdditions.Insert(PermissionKey, Common.ValueToXMLString(PermissionAddition));
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds a flag whether to clear permission data from the registers to the request application plan.
// Used to restore profiles.
//
Procedure AddClearingPermissionsBeforeApplying() Export
	
	ClearingPermissionsBeforeApply = True;
	
EndProcedure

// Calculates a result of application of requests to use external resources.
//
Procedure CalculateRequestsApplication() Export
	
	ExternalTransaction = TransactionActive();
	If Not ExternalTransaction Then
		BeginTransaction(); // ACC:326 - BeginTransaction does not have a paired CommitTransaction because the action is aborted.
	EndIf;
	
	Try
		DataProcessors.ExternalResourcesPermissionsSetup.LockRegistersOfGrantedPermissions();
		
		SourcePermissionSliceByOwners = InformationRegisters.PermissionsToUseExternalResources.PermissionsSlice();
		CalculateRequestsApplicationResultByOwners();
		CalculateDeltaByOwners();
		
		SourcePermissionSliceIgnoringOwners = InformationRegisters.PermissionsToUseExternalResources.PermissionsSlice(False, True);
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
	
	If MustApplyPermissionsInServersCluster() Then
		LockDataForEdit(Semaphore());
	EndIf;
	
EndProcedure

// Checks whether permissions must be applied in the server cluster.
//
// Returns:
//   Boolean
//
Function MustApplyPermissionsInServersCluster() Export
	
	If DeltaIgnoringOwners.ItemsToAdd.Count() > 0 Then
		Return True;
	EndIf;
	
	If DeltaIgnoringOwners.ItemsToDelete.Count() > 0 Then
		Return True;
	EndIf;
	
	For Each AdministrationOperation In AdministrationOperations Do
		If AdministrationOperation.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Checks whether the permissions must be written to registers.
//
// Returns:
//   Boolean
//
Function RecordPermissionsToRegisterRequired() Export
	
	If DeltaByOwners.ItemsToAdd.Count() > 0 Then
		Return True;
	EndIf;
	
	If DeltaByOwners.ItemsToDelete.Count() > 0 Then
		Return True;
	EndIf;
	
	For Each AdministrationOperation In AdministrationOperations Do
		If AdministrationOperation.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Returns a presentation of requests for permissions to use external resources.
//
// Parameters:
//  AsRequired - Boolean - a presentation is generated as a list of permissions, not as a list of operations
//    upon changing permissions.
//
// Returns:
//   SpreadsheetDocument
//
Function Presentation(Val AsRequired = False) Export
	
	Return Reports.ExternalResourcesInUse.RequestsForPermissionsToUseExternalResoursesPresentation(
		AdministrationOperations,
		DeltaIgnoringOwners.ItemsToAdd,
		DeltaIgnoringOwners.ItemsToDelete,
		AsRequired);
	
EndFunction

// Returns a scenario of applying requests for permissions to use external resources.
//
// Returns:
//   Array of Structure:
//                        * Operation - EnumRef.SecurityProfileAdministrativeOperations,
//                        * Profile - String - a security profile name,
//                        * Permissions - See ClusterAdministration.SecurityProfileProperties
//
Function ApplyingScenario() Export
	
	Result = New Array();
	
	For Each LongDesc In AdministrationOperations Do
		
		ResultItem = New Structure("Operation,Profile,Permissions");
		ResultItem.Operation = LongDesc.Operation;
		ResultItem.Profile = LongDesc.Name;
		ResultItem.Permissions = ProfileInClusterAdministrationInterfaceNotation(ResultItem.Profile, LongDesc.ProgramModuleType, LongDesc.ModuleID);
		
		IsConfigurationProfile = (LongDesc.ProgramModuleType = Catalogs.MetadataObjectIDs.EmptyRef());
		
		If IsConfigurationProfile Then
			
			AdditionalOperationPriority = False;
			
			If LongDesc.Operation = Enums.SecurityProfileAdministrativeOperations.Creating Then
				AdditionalOperation = Enums.SecurityProfileAdministrativeOperations.Purpose;
			EndIf;
			
			If LongDesc.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
				AdditionalOperation = Enums.SecurityProfileAdministrativeOperations.AssignmentDeletion;
				AdditionalOperationPriority = True;
			EndIf;
			
			AdditionalItem = New Structure("Operation,Profile,Permissions", AdditionalOperation, LongDesc.Name);
			
		EndIf;
		
		If IsConfigurationProfile And AdditionalOperationPriority Then
			
			Result.Add(AdditionalItem);
			
		EndIf;
		
		Result.Add(ResultItem);
		
		If IsConfigurationProfile And Not AdditionalOperationPriority Then
			
			Result.Add(AdditionalItem);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Serializes an internal state of the object.
//
// Returns:
//   String
//
Function WriteStateToXMLString() Export
	
	State = New Structure();
	
	State.Insert("SourcePermissionSliceByOwners", SourcePermissionSliceByOwners);
	State.Insert("RequestsApplicationResultByOwners", RequestsApplicationResultByOwners);
	State.Insert("DeltaByOwners", DeltaByOwners);
	State.Insert("SourcePermissionSliceIgnoringOwners", SourcePermissionSliceIgnoringOwners);
	State.Insert("RequestsApplicationResultIgnoringOwners", RequestsApplicationResultIgnoringOwners);
	State.Insert("DeltaIgnoringOwners", DeltaIgnoringOwners);
	State.Insert("AdministrationOperations", AdministrationOperations);
	State.Insert("RequestsIDs", RequestsIDs);
	State.Insert("ClearingPermissionsBeforeApply", ClearingPermissionsBeforeApply);
	
	Return Common.ValueToXMLString(State);
	
EndFunction

// Deserializes an internal object state.
//
// Parameters:
//  XMLLine - String - a result returned by the WriteStateToXMLString() function.
//
Procedure ReadStateFromXMLString(Val XMLLine) Export
	
	State = Common.ValueFromXMLString(XMLLine);
	
	SourcePermissionSliceByOwners = State.SourcePermissionSliceByOwners;
	RequestsApplicationResultByOwners = State.RequestsApplicationResultByOwners;
	DeltaByOwners = State.DeltaByOwners;
	SourcePermissionSliceIgnoringOwners = State.SourcePermissionSliceIgnoringOwners;
	RequestsApplicationResultIgnoringOwners = State.RequestsApplicationResultIgnoringOwners;
	DeltaIgnoringOwners = State.DeltaIgnoringOwners;
	AdministrationOperations = State.AdministrationOperations;
	RequestsIDs = State.RequestsIDs;
	ClearingPermissionsBeforeApply = State.ClearingPermissionsBeforeApply;
	
EndProcedure

// Saves in the infobase the fact that requests to use external resource are applied.
//
Procedure CompleteApplyRequestsToUseExternalResources() Export
	
	BeginTransaction();
	Try
		
		If RecordPermissionsToRegisterRequired() Then
			
			If ClearingPermissionsBeforeApply Then
				
				DataProcessors.ExternalResourcesPermissionsSetup.ClearPermissions(, False);
				
			EndIf;
			
			For Each ItemsToDelete In DeltaByOwners.ItemsToDelete Do
				
				For Each KeyAndValue In ItemsToDelete.Permissions Do
					
					InformationRegisters.PermissionsToUseExternalResources.DeletePermission(
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
					
					Supplement = ItemsToAdd.PermissionsAdditions.Get(KeyAndValue.Key);
					If Supplement <> Undefined Then
						Supplement = Common.ValueFromXMLString(Supplement);
					EndIf;
					
					InformationRegisters.PermissionsToUseExternalResources.AddPermission(
						ItemsToAdd.ProgramModuleType,
						ItemsToAdd.ModuleID,
						ItemsToAdd.OwnerType,
						ItemsToAdd.OwnerID,
						KeyAndValue.Key,
						Common.XDTODataObjectFromXMLString(KeyAndValue.Value),
						Supplement);
					
				EndDo;
				
			EndDo;
			
			For Each LongDesc In AdministrationOperations Do
				
				IsConfigurationProfile = (LongDesc.ProgramModuleType = Catalogs.MetadataObjectIDs.EmptyRef());
				
				If LongDesc.Operation = Enums.SecurityProfileAdministrativeOperations.Creating Then
					
					If IsConfigurationProfile Then
						
						Constants.InfobaseSecurityProfile.Set(LongDesc.Name);
						
					Else
						
						Manager = InformationRegisters.ExternalModulesAttachmentModes.CreateRecordManager();
						Manager.ProgramModuleType = LongDesc.ProgramModuleType;
						Manager.ModuleID = LongDesc.ModuleID;
						Manager.SafeMode = LongDesc.Name;
						Manager.Write();
						
					EndIf;
					
				EndIf;
				
				If LongDesc.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
					
					If IsConfigurationProfile Then
						
						Constants.InfobaseSecurityProfile.Set("");
						DataProcessors.ExternalResourcesPermissionsSetup.ClearPermissions();
						
					Else
						
						ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
							LongDesc.ProgramModuleType, LongDesc.ModuleID);
						DataProcessors.ExternalResourcesPermissionsSetup.ClearPermissions(
							ProgramModule, True);
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		InformationRegisters.RequestsForPermissionsToUseExternalResources.DeleteRequests(RequestsIDs);
		InformationRegisters.RequestsForPermissionsToUseExternalResources.ClearObsoleteRequests();
		
		UnlockDataForEdit(Semaphore());
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

// Calculates a request application result by owners.
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
	
	// Apply the plan.
	
	// Overwrite
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
	
	// Add permissions.
	For Each AddedItemsRow In RequestsApplicationPlan.ItemsToAdd Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", AddedItemsRow.ProgramModuleType);
		Filter.Insert("ModuleID", AddedItemsRow.ModuleID);
		Filter.Insert("OwnerType", AddedItemsRow.OwnerType);
		Filter.Insert("OwnerID", AddedItemsRow.OwnerID);
		Filter.Insert("Type", AddedItemsRow.Type);
		
		String = DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
			RequestsApplicationResultByOwners, Filter);
		
		For Each KeyAndValue In AddedItemsRow.Permissions Do
			
			String.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
			
			If AddedItemsRow.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
				String.PermissionsAdditions.Insert(KeyAndValue.Key, AddedItemsRow.PermissionsAdditions.Get(KeyAndValue.Key));
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Delete permissions
	For Each ItemsToDeleteRow In RequestsApplicationPlan.ItemsToDelete Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", ItemsToDeleteRow.ProgramModuleType);
		Filter.Insert("ModuleID", ItemsToDeleteRow.ModuleID);
		Filter.Insert("OwnerType", ItemsToDeleteRow.OwnerType);
		Filter.Insert("OwnerID", ItemsToDeleteRow.OwnerID);
		Filter.Insert("Type", ItemsToDeleteRow.Type);
		
		String = DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
			RequestsApplicationResultByOwners, Filter);
		
		For Each KeyAndValue In ItemsToDeleteRow.Permissions Do
			
			String.Permissions.Delete(KeyAndValue.Key);
			
			If ItemsToDeleteRow.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
				
				String.PermissionsAdditions.Insert(KeyAndValue.Key, ItemsToDeleteRow.PermissionsAdditions.Get(KeyAndValue.Key));
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Calculates a request application result ignoring owners.
//
Procedure CalculateRequestsApplicationResultIgnoringOwners()
	
	RequestsApplicationResultIgnoringOwners = New ValueTable();
	
	For Each SourceColumn In SourcePermissionSliceIgnoringOwners.Columns Do
		RequestsApplicationResultIgnoringOwners.Columns.Add(SourceColumn.Name, SourceColumn.ValueType);
	EndDo;
	
	For Each ResultString1 In RequestsApplicationResultByOwners Do
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", ResultString1.ProgramModuleType);
		Filter.Insert("ModuleID", ResultString1.ModuleID);
		Filter.Insert("Type", ResultString1.Type);
		
		String = DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
			RequestsApplicationResultIgnoringOwners, Filter);
		
		For Each KeyAndValue In ResultString1.Permissions Do
			
			SourcePermission = Common.XDTODataObjectFromXMLString(KeyAndValue.Value);
			// Details must not affect hash sums for an option without owners.
			PermissionDetails = SourcePermission.Description;
			SourcePermission.Description = ""; 
			PermissionKey = InformationRegisters.PermissionsToUseExternalResources.PermissionKey(SourcePermission);
			
			Resolution = String.Permissions.Get(PermissionKey);
			If Resolution = Undefined Then
				
				If ResultString1.Type = "FileSystemAccess" Then
					
					// Search for nested or parent permissions in order to use the file system directory.
					// 
					
					If SourcePermission.AllowedRead Then
						
						If SourcePermission.AllowedWrite Then
							
							// Searching for the read permission for the same catalog.
							PermissionCopy = Common.XDTODataObjectFromXMLString(Common.XDTODataObjectToXMLString(SourcePermission));
							PermissionCopy.AllowedWrite = False;
							CopyKey = InformationRegisters.PermissionsToUseExternalResources.PermissionKey(PermissionCopy);
							
							// Deleting the nested permission. It becomes useless once the current one is added.
							NestedPermission = String.Permissions.Get(CopyKey);
							If NestedPermission <> Undefined Then
								String.Permissions.Delete(CopyKey);
							EndIf;
							
						Else
							
							// Searching for a permission to read and write to the same catalog.
							PermissionCopy = Common.XDTODataObjectFromXMLString(Common.XDTODataObjectToXMLString(SourcePermission));
							PermissionCopy.AllowedWrite = True;
							CopyKey = InformationRegisters.PermissionsToUseExternalResources.PermissionKey(PermissionCopy);
							
							// No need to process the permission, the catalog is available by the parent permission.
							ParentPermission = String.Permissions.Get(CopyKey);
							If ParentPermission <> Undefined Then
								Continue;
							EndIf;
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
				SourcePermission.Description = PermissionDetails; 
				String.Permissions.Insert(PermissionKey, Common.XDTODataObjectToXMLString(SourcePermission));
				
				Supplement = ResultString1.PermissionsAdditions.Get(KeyAndValue.Key);
				If Supplement <> Undefined Then
					String.PermissionsAdditions.Insert(PermissionKey, Supplement);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Returns:
//  Structure:
//   * ItemsToAdd - ValueTable - Details of the permissions being added. Columns are:
//    ** ProgramModuleType - CatalogRef.MetadataObjectIDs,
//    ** ModuleID - UUID,
//    ** OwnerType - CatalogRef.MetadataObjectIDs,
//    ** OwnerID - UUID,
//    ** Type - String - Name of the XDTO type that describes permissions.
//    ** Permissions - Map of KeyAndValue:
//      *** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//      *** Value - XDTODataObject - Permission details in XDTO format.
//    ** PermissionsAdditions - Map of KeyAndValue - Describes permission additions:
//      *** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//      *** Value - See InformationRegister.PermissionsToUseExternalResources.PermissionAddition
//   * ItemsToDelete - ValueTable - Details of the permissions being deleted. Contains the following columns:
//    ** ProgramModuleType - CatalogRef.MetadataObjectIDs,
//    ** ModuleID - UUID,
//    ** OwnerType - CatalogRef.MetadataObjectIDs,
//    ** OwnerID - UUID,
//    ** Type - String - Name of the XDTO type that describes permissions.
//    ** Permissions - Map of KeyAndValue:
//      *** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//      *** Value - XDTODataObject - Permission details in XDTO format.
//    ** PermissionsAdditions - Map of KeyAndValue:
//      *** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//      *** Value - See InformationRegister.PermissionsToUseExternalResources.PermissionAddition
//
Function DeltaByOwners()
		
	Result = New Structure();
	
	Result.Insert("ItemsToAdd", New ValueTable);
	Result.ItemsToAdd.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.ItemsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
	Result.ItemsToAdd.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.ItemsToAdd.Columns.Add("OwnerID", New TypeDescription("UUID"));
	Result.ItemsToAdd.Columns.Add("Type", New TypeDescription("String"));
	Result.ItemsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));
	Result.ItemsToAdd.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	Result.Insert("ItemsToDelete", New ValueTable);
	Result.ItemsToDelete.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.ItemsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
	Result.ItemsToDelete.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.ItemsToDelete.Columns.Add("OwnerID", New TypeDescription("UUID"));
	Result.ItemsToDelete.Columns.Add("Type", New TypeDescription("String"));
	Result.ItemsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));
	Result.ItemsToDelete.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	Return Result;
	
EndFunction

// Calculates a delta between two permission slices by owners.
//
Procedure CalculateDeltaByOwners()
	
	DeltaByOwners = DeltaByOwners();
	
	// Comparing source permissions with the resulting ones.
	
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
				
				// The permission was in the source ones  but it is absent in the resulting ones, it is a permission being deleted.
				
				ItemsToDeleteRow = DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
					DeltaByOwners.ItemsToDelete, Filter);
				
				If ItemsToDeleteRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					
					ItemsToDeleteRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
					
					If String.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
						ItemsToDeleteRow.PermissionsAdditions.Insert(KeyAndValue.Key, String.PermissionsAdditions.Get(KeyAndValue.Key));
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Comparing the resulting permissions with the source ones.
	
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
				
				// The permission is in resulting ones but it is absent in the source ones, it is a permission being added.
				
				PermissionsToAddRow = DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
					DeltaByOwners.ItemsToAdd, Filter);
				
				If PermissionsToAddRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					
					PermissionsToAddRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
					
					If String.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
						PermissionsToAddRow.PermissionsAdditions.Insert(KeyAndValue.Key, String.PermissionsAdditions.Get(KeyAndValue.Key));
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Returns:
//  Structure:
//   * ItemsToAdd - ValueTable - Details of the permissions being added. Columns are:
//    ** ProgramModuleType - CatalogRef.MetadataObjectIDs,
//    ** ModuleID - UUID,
//    ** Type - String - Name of the XDTO type that describes permissions.
//    ** Permissions - Map of KeyAndValue:
//      *** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//      *** Value - XDTODataObject - Permission details in XDTO format.
//    ** PermissionsAdditions - Map of KeyAndValue:
//      *** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//      *** Value - See InformationRegister.PermissionsToUseExternalResources.PermissionAddition
//   * ItemsToDelete - ValueTable - Details of the permissions being deleted. Contains the following columns:
//    ** ProgramModuleType - CatalogRef.MetadataObjectIDs,
//    ** ModuleID - UUID,
//    ** Type - String - Name of the XDTO type that describes permissions.
//    ** Permissions - Map of KeyAndValue:
//      *** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//      *** Value - XDTODataObject - Permission details in XDTO format.
//    ** PermissionsAdditions - Map of KeyAndValue:
//      *** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//      *** Value - See InformationRegister.PermissionsToUseExternalResources.PermissionAddition
//
Function DeltaIgnoringOwners()
	
	Result = New Structure();
	
	Result.Insert("ItemsToAdd", New ValueTable);
	Result.ItemsToAdd.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.ItemsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
	Result.ItemsToAdd.Columns.Add("Type", New TypeDescription("String"));
	Result.ItemsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));
	Result.ItemsToAdd.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	Result.Insert("ItemsToDelete", New ValueTable);
	Result.ItemsToDelete.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.ItemsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
	Result.ItemsToDelete.Columns.Add("Type", New TypeDescription("String"));
	Result.ItemsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));
	Result.ItemsToDelete.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	Return Result;
	
EndFunction 

// Calculates a delta between two permission slices ignoring owners.
//
Procedure CalculateDeltaIgnoringOwners()
	
	DeltaIgnoringOwners = DeltaIgnoringOwners();
	
	// Comparing source permissions with the resulting ones.
	
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
				
				// The permission was in the source ones  but it is absent in the resulting ones, it is a permission being deleted.
				
				ItemsToDeleteRow = DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
					DeltaIgnoringOwners.ItemsToDelete, Filter);
				
				If ItemsToDeleteRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					
					ItemsToDeleteRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
					
					If String.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
						ItemsToDeleteRow.PermissionsAdditions.Insert(KeyAndValue.Key, String.PermissionsAdditions.Get(KeyAndValue.Key));
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Comparing the resulting permissions with the source ones.
	
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
				
				// The permission is in resulting ones but it is absent in the source ones, it is a permission being added.
				
				PermissionsToAddRow = DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
					DeltaIgnoringOwners.ItemsToAdd, Filter);
				
				If PermissionsToAddRow.Permissions.Get(KeyAndValue.Key) = Undefined Then
					
					PermissionsToAddRow.Permissions.Insert(KeyAndValue.Key, KeyAndValue.Value);
					
					If String.PermissionsAdditions.Get(KeyAndValue.Key) <> Undefined Then
						PermissionsToAddRow.PermissionsAdditions.Insert(KeyAndValue.Key, String.PermissionsAdditions.Get(KeyAndValue.Key));
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Creates security profile details in the
// cluster server administration interface notation.
//
// Parameters:
//  ProfileName - String - a security profile name,
//  ProgramModuleType - CatalogRef.MetadataObjectIDs,
//  ModuleID - UUID
//
// Returns:
//   See ClusterAdministration.SecurityProfileProperties
//
Function ProfileInClusterAdministrationInterfaceNotation(Val ProfileName, Val ProgramModuleType, Val ModuleID)
	
	Profile = ClusterAdministration.SecurityProfileProperties();
	Profile.Name = ProfileName;
	Profile.LongDesc = NewSecurityProfileDetails(ProgramModuleType, ModuleID);
	Profile.SafeModeProfile = True;
	
	Profile.FileSystemFullAccess = False;
	Profile.COMObjectFullAccess = False;
	Profile.AddInFullAccess = False;
	Profile.ExternalModuleFullAccess = False;
	Profile.FullOperatingSystemApplicationAccess = False;
	Profile.InternetResourcesFullAccess = False;
	
	Profile.FullAccessToPrivilegedMode = False;
	
	Filter = New Structure();
	Filter.Insert("ProgramModuleType", ProgramModuleType);
	Filter.Insert("ModuleID", ModuleID);
	
	Rows = RequestsApplicationResultIgnoringOwners.FindRows(Filter);
	
	For Each String In Rows Do
		
		For Each KeyAndValue In String.Permissions Do
			
			Resolution = Common.XDTODataObjectFromXMLString(KeyAndValue.Value);
			
			If String.Type = "FileSystemAccess" Then
				
				If StandardVirtualDirectories().Get(Resolution.Path) <> Undefined Then
					
					ISecurityProfileVirtualDirectory = ClusterAdministration.VirtualDirectoryProperties();
					ISecurityProfileVirtualDirectory.LogicalURL = Resolution.Path;
					ISecurityProfileVirtualDirectory.PhysicalURL = StandardVirtualDirectories().Get(Resolution.Path);
					ISecurityProfileVirtualDirectory.DataReader = Resolution.AllowedRead;
					ISecurityProfileVirtualDirectory.DataWriter = Resolution.AllowedWrite;
					ISecurityProfileVirtualDirectory.LongDesc = Resolution.Description;
					Profile.VirtualDirectories.Add(ISecurityProfileVirtualDirectory);
					
				Else
					
					ISecurityProfileVirtualDirectory = ClusterAdministration.VirtualDirectoryProperties();
					ISecurityProfileVirtualDirectory.LogicalURL = Resolution.Path;
					ISecurityProfileVirtualDirectory.PhysicalURL = EscapePercentChar(Resolution.Path);
					ISecurityProfileVirtualDirectory.DataReader = Resolution.AllowedRead;
					ISecurityProfileVirtualDirectory.DataWriter = Resolution.AllowedWrite;
					ISecurityProfileVirtualDirectory.LongDesc = Resolution.Description;
					Profile.VirtualDirectories.Add(ISecurityProfileVirtualDirectory);
					
				EndIf;
				
			ElsIf String.Type = "CreateComObject" Then
				
				COMClass = ClusterAdministration.COMClassProperties();
				COMClass.Name = Resolution.ProgId;
				COMClass.CLSID = Resolution.CLSID;
				COMClass.Computer = Resolution.ComputerName;
				COMClass.LongDesc = Resolution.Description;
				Profile.COMClasses.Add(COMClass);
				
			ElsIf String.Type = "AttachAddin" Then
				
				Supplement = Common.ValueFromXMLString(String.PermissionsAdditions.Get(KeyAndValue.Key));
				For Each AdditionKeyAndValue In Supplement Do
					
					AddIn = ClusterAdministration.AddInProperties();
					AddIn.Name = Resolution.TemplateName + "\" + AdditionKeyAndValue.Key;
					AddIn.HashSum = AdditionKeyAndValue.Value;
					AddIn.LongDesc = Resolution.Description;
					Profile.AddIns.Add(AddIn);
					
				EndDo;
				
			ElsIf String.Type = "ExternalModule" Then
				
				ExternalModule = ClusterAdministration.ExternalModuleProperties();
				ExternalModule.Name = Resolution.Name;
				ExternalModule.HashSum = Resolution.Hash;
				ExternalModule.LongDesc = Resolution.Description;
				Profile.ExternalModules.Add(ExternalModule);
				
			ElsIf String.Type = "RunApplication" Then
				
				OSApplication = ClusterAdministration.OSApplicationProperties();
				OSApplication.Name = Resolution.CommandMask;
				OSApplication.CommandLinePattern = Resolution.CommandMask;
				OSApplication.LongDesc = Resolution.Description;
				Profile.OSApplications.Add(OSApplication);
				
			ElsIf String.Type = "InternetResourceAccess" Then
				
				InternetResource = ClusterAdministration.InternetResourceProperties();
				InternetResource.Name = Lower(Resolution.Protocol) + "://" + Lower(Resolution.Host) + ":" + Resolution.Port;
				InternetResource.Protocol = Resolution.Protocol;
				InternetResource.Address = Resolution.Host;
				InternetResource.Port = Resolution.Port;
				InternetResource.LongDesc = Resolution.Description;
				Profile.InternetResources.Add(InternetResource);
				
			ElsIf String.Type = "ExternalModulePrivilegedModeAllowed" Then
				
				Profile.FullAccessToPrivilegedMode = True;
				
			EndIf;
			
			
		EndDo;
		
	EndDo;
	
	Return Profile;
	
EndFunction

// Generates security profile details for the infobase or the external module.
//
// Parameters:
//  ExternalModule - AnyRef - a reference to the catalog item used
//    as an external module.
//
// Returns: 
//   String - details of the security profile.
//
Function NewSecurityProfileDetails(Val ProgramModuleType, Val ModuleID)
	
	Template = NStr("vi = '[CSDL %1] %2 ""%3""';
					|ru = '[ИБ %1] %2 ""%3""';
					|en = '[Infobase %1] %2 ""%3""'; fa = '[Infobase %1] %2 ""%3""';
					|it = '[DB %1]%2 ""%3""';
					|pl = '[BI %1] %2 ""%3""';
					|tr = '[Infobase %1] %2 ""%3""'");
	
	IBName = "";
	ConnectionString = InfoBaseConnectionString();
	Substrings = StrSplit(ConnectionString, ";");
	For Each Substring In Substrings Do
		If StrStartsWith(Substring, "Ref") Then
			IBName = StrReplace(Right(Substring, StrLen(Substring) - 4), """", "");
		EndIf;
	EndDo;
	If IsBlankString(IBName) Then
		Raise NStr("vi = 'Dòng kết nối cơ sở thông tin cần có cơ sở thông tin';
					|ru = 'Строка соединения информационной базы должна содержать информационной базы';
					|en = 'Infobase connection string must contain the infobase.'; fa = 'Infobase connection string must contain the infobase.';
					|it = 'La riga di connessione del database deve contenere il database';
					|pl = 'Wiersz połączenia bazy informacyjnej powinna zawierać bazy informacyjnej';
					|tr = 'Infobase birleşme satırı Infobase''i içermelidir'");
	EndIf;
	
	If ProgramModuleType = Catalogs.MetadataObjectIDs.EmptyRef() Then
		Return StringFunctionsClientServer.SubstituteParametersToString(Template, IBName,
			NStr("vi = 'Hồ sơ bảo mật đối với cơ sở thông tin';
				|ru = 'Профиль безопасности для информационной базы';
				|en = 'Security profile for infobase'; fa = 'Security profile for infobase';
				|it = 'Profilo di sicurezza per il database';
				|pl = 'Profil bezpieczeństwa dla bazy informacyjnej';
				|tr = 'Infobase güvenlik profili'"), InfoBaseConnectionString());
	Else
		ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(ProgramModuleType, ModuleID);
		Dictionary = SafeModeManagerInternal.ExternalModuleManager(ProgramModule).ExternalModuleContainerDictionary();
		ModuleDescription = Common.ObjectAttributeValue(ProgramModule, "Description");
		Return StringFunctionsClientServer.SubstituteParametersToString(Template, IBName, Dictionary.Nominative, ModuleDescription);
	EndIf;
	
EndFunction

// Returns physical paths of standard virtual directories.
//
// Returns:
//   Map of KeyAndValue:
//                         * Key - String - a virtual directory alias,
//                         * Value - String - a physical path.
//
Function StandardVirtualDirectories()
	
	Result = New Map();
	
	Result.Insert("/temp", "%t/%r/%s/%p");
	Result.Insert("/bin", "%e");
	
	Return Result;
	
EndFunction

// Escapes the percent character in the physical path of the virtual directory.
//
// Parameters:
//  InitialString - String - a source physical path of the virtual directory.
//
// Returns:
//   String
//
Function EscapePercentChar(Val InitialString)
	
	Return StrReplace(InitialString, "%", "%%");
	
EndFunction

// Returns a semaphore to be used when applying requests to use external resources.
//
// Returns:
//   InformationRegisterRecordKey.RequestsForPermissionsToUseExternalResources
//
Function Semaphore()
	
	Var_Key = New Structure();
	Var_Key.Insert("QueryID", New UUID("8e02fbd3-3f9f-4c3c-964d-7c602ad4eb38"));
	
	Return InformationRegisters.RequestsForPermissionsToUseExternalResources.CreateRecordKey(Var_Key);
	
EndFunction

// Returns:
//   ValueTable:
//   * ProgramModuleType - CatalogRef.MetadataObjectIDs
//   * ModuleID - UUID
//   * Operation - EnumRef.SecurityProfileAdministrativeOperations
//   * Name - String - Security profile name.
//
Function AdministrationOperations()
	
	AdministrationOperations = New ValueTable;
	AdministrationOperations.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	AdministrationOperations.Columns.Add("ModuleID", New TypeDescription("UUID"));
	AdministrationOperations.Columns.Add("Operation", New TypeDescription("EnumRef.SecurityProfileAdministrativeOperations"));
	AdministrationOperations.Columns.Add("Name", New TypeDescription("String"));
	
	Return AdministrationOperations;
	
EndFunction

// Returns:
//  Structure:
//   * PermissionsToReplace - ValueTable - Operations that replace the existing permissions with permissions to use external resources.:
//      ** ProgramModuleType - CatalogRef.MetadataObjectIDs,
//      ** ModuleID - UUID,
//      ** OwnerType - CatalogRef.MetadataObjectIDs,
//      ** OwnerID - UUID,
//   * ItemsToAdd - ValueTable - Operations that add permissions to use external resources.:
//      ** ProgramModuleType - CatalogRef.MetadataObjectIDs,
//      ** ModuleID - UUID,
//      ** OwnerType - CatalogRef.MetadataObjectIDs,
//      ** OwnerID - UUID,
//      ** Type - String - Name of the XDTO type that describes permissions.
//      ** Permissions - Map of KeyAndValue - Describes the permissions being added:
//         *** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//         *** Value - XDTODataObject - XDTO details of the permission being added
//      ** PermissionsAdditions - Map of KeyAndValue - Describes the additions of the permissions being added:
//         *** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//         *** Value - See InformationRegister.PermissionsToUseExternalResources.PermissionAddition
//   * ItemsToDelete - ValueTable - Operations that remove permissions on external resources:
//      * ProgramModuleType - CatalogRef.MetadataObjectIDs,
//      * ModuleID - UUID,
//      * OwnerType - CatalogRef.MetadataObjectIDs,
//      * OwnerID - UUID,
//      * Type - String - Name of the XDTO type that describes permissions.
//      * Permissions - Map of KeyAndValue - Describes the permissions being removed:
//         * Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//         * Value - XDTODataObject - XDTP details of the permission being removed.
//      * PermissionsAdditions - Map of KeyAndValue - Describes the additions of the permissions being removed:
//         * Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//         * Value - See InformationRegister.PermissionsToUseExternalResources.PermissionAddition
//
Function RequestsApplicationPlan()
	
	RequestsApplicationPlan = New Structure();

	RequestsApplicationPlan.Insert("PermissionsToReplace", New ValueTable);
	RequestsApplicationPlan.PermissionsToReplace.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	RequestsApplicationPlan.PermissionsToReplace.Columns.Add("ModuleID", New TypeDescription("UUID"));
	RequestsApplicationPlan.PermissionsToReplace.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	RequestsApplicationPlan.PermissionsToReplace.Columns.Add("OwnerID", New TypeDescription("UUID"));
	
	RequestsApplicationPlan.Insert("ItemsToAdd", New ValueTable);
	RequestsApplicationPlan.ItemsToAdd.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	RequestsApplicationPlan.ItemsToAdd.Columns.Add("ModuleID", New TypeDescription("UUID"));
	RequestsApplicationPlan.ItemsToAdd.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	RequestsApplicationPlan.ItemsToAdd.Columns.Add("OwnerID", New TypeDescription("UUID"));
	RequestsApplicationPlan.ItemsToAdd.Columns.Add("Type", New TypeDescription("String"));
	RequestsApplicationPlan.ItemsToAdd.Columns.Add("Permissions", New TypeDescription("Map"));
	RequestsApplicationPlan.ItemsToAdd.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	RequestsApplicationPlan.Insert("ItemsToDelete", New ValueTable);
	RequestsApplicationPlan.ItemsToDelete.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	RequestsApplicationPlan.ItemsToDelete.Columns.Add("ModuleID", New TypeDescription("UUID"));
	RequestsApplicationPlan.ItemsToDelete.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	RequestsApplicationPlan.ItemsToDelete.Columns.Add("OwnerID", New TypeDescription("UUID"));
	RequestsApplicationPlan.ItemsToDelete.Columns.Add("Type", New TypeDescription("String"));
	RequestsApplicationPlan.ItemsToDelete.Columns.Add("Permissions", New TypeDescription("Map"));
	RequestsApplicationPlan.ItemsToDelete.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	Return RequestsApplicationPlan;
	
EndFunction

#EndRegion

#Region Initialize

RequestsIDs = New Array();

RequestsApplicationPlan = RequestsApplicationPlan();

AdministrationOperations = AdministrationOperations();

ClearingPermissionsBeforeApply = False;

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf
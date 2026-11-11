///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Updates register data after changing the access kind.
//
// Parameters:
//  HasChanges - Boolean - (return value) - if recorded,
//                  True is set, otherwise, it does not change.
//
//  WithoutUpdatingDependentData - Boolean - if True, 
//                  do not call the OnChangeAccessKindsUse procedure and
//                  do not schedule the update of the access restriction parameters.
//
Procedure UpdateRegisterData(HasChanges = Undefined, WithoutUpdatingDependentData = False) Export
	
	If AccessManagementInternal.IsRecordLevelRestrictionDisabled() Then
		AccessManagementInternal.ClearInformationRegister(
			Metadata.InformationRegisters.UsedAccessKinds.FullName(), HasChanges);
		Return;
	EndIf;
	
	InformationRegisters.ExtensionVersionParameters.LockForChangeInFileIB();
	AccessKindsProperties = AccessManagementInternal.AccessKindsProperties();
	
	RecordSet = CreateRecordSet();
	
	For Each AccessKindProperties In AccessKindsProperties.Array Do
		
		If AccessKindProperties.Name = "ExternalUsers"
		 Or AccessKindProperties.Name = "Users" Then
			// These access kinds cannot be disabled by functional options.
			Used = True;
		Else
			Used = True;
			SSLSubsystemsIntegration.OnFillAccessKindUsage(AccessKindProperties.Name, Used);
			AccessManagementOverridable.OnFillAccessKindUsage(AccessKindProperties.Name, Used);
		EndIf;
		
		NewRecord = RecordSet.Add();
		NewRecord.AccessValuesType = AccessKindProperties.Ref;
		NewRecord.Used = Used;
		
		If NewRecord.AccessValuesType <> AccessKindProperties.Ref Then
			RecordSet.Delete(NewRecord);
		EndIf;
	EndDo;
	
	If Not HasChangesInAccessKindsUsage(RecordSet) Then
		Return;
	EndIf;
	
	Block = New DataLock;
	Block.Add("InformationRegister.UsedAccessKinds");
	
	BeginTransaction();
	Try
		Block.Lock();
		
		If HasChangesInAccessKindsUsage(RecordSet) Then
			RecordSet.Write();
			HasChanges = True;
			If Not WithoutUpdatingDependentData Then
				WhenChangingTheUseOfAccessTypes(True);
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Parameters:
//  RecordSet - InformationRegisterRecordSet.UsedAccessKinds
//
// Returns:
//  Boolean
//
Function HasChangesInAccessKindsUsage(RecordSet)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UsedAccessKinds.AccessValuesType AS AccessValuesType,
	|	UsedAccessKinds.Used AS Used
	|INTO NewRecords
	|FROM
	|	&NewRecords AS UsedAccessKinds
	|WHERE
	|	&Filter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	NewRecords AS NewRecords
	|		LEFT JOIN InformationRegister.UsedAccessKinds AS UsedAccessKinds
	|		ON (UsedAccessKinds.AccessValuesType = NewRecords.AccessValuesType)
	|			AND (UsedAccessKinds.Used = NewRecords.Used)
	|WHERE
	|	UsedAccessKinds.AccessValuesType IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.UsedAccessKinds AS UsedAccessKinds
	|		LEFT JOIN NewRecords AS NewRecords
	|		ON (NewRecords.AccessValuesType = UsedAccessKinds.AccessValuesType)
	|			AND (NewRecords.Used = UsedAccessKinds.Used)
	|WHERE
	|	&Filter
	|	AND NewRecords.AccessValuesType IS NULL";
	
	Query.SetParameter("NewRecords", RecordSet.Unload());
	
	If RecordSet.Filter.AccessValuesType.Use Then
		Query.SetParameter("AccessValuesType",
			RecordSet.Filter.AccessValuesType.Value);
		Query.Text = StrReplace(Query.Text, "&Filter",
			"UsedAccessKinds.AccessValuesType = &AccessValuesType");
	Else
		Query.Text = StrReplace(Query.Text, "&Filter", "TRUE");
	EndIf;
	
	QueryResults = Query.ExecuteBatch();
	
	Return Not QueryResults[1].IsEmpty() Or Not QueryResults[2].IsEmpty();
	
EndFunction

// Parameters:
//  DataElement - InformationRegisterRecordSet.UsedAccessKinds
//
Procedure RegisterChangeUponDataImport(DataElement) Export
	
	If AccessManagementInternal.IsRecordLevelRestrictionDisabled()
	 Or Not HasChangesInAccessKindsUsage(DataElement) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	UsersInternal.RegisterRefs("UsedAccessKinds", Undefined);
	
EndProcedure

// For internal use only.
Procedure ProcessChangeRegisteredUponDataImport() Export
	
	If Common.DataSeparationEnabled() Then
		// In the SWS, right settings are locked for editing and are not imported into the data area.
		Return;
	EndIf;
	
	Changes = UsersInternal.RegisteredRefs("UsedAccessKinds");
	If Changes.Count() = 0 Then
		Return;
	EndIf;
	
	If Not AccessManagementInternal.IsRecordLevelRestrictionDisabled() Then
		WhenChangingTheUseOfAccessTypes(Changes.Count() = 1 And Changes[0] <> Undefined);
	EndIf;
	
	UsersInternal.RegisterRefs("UsedAccessKinds", Null);
	
EndProcedure

Procedure ScheduleUpdateOnChangeAccessKindsUsage() Export
	
	If AccessManagementInternal.IsRecordLevelRestrictionDisabled() Then
		Return;
	EndIf;
	
	UsersInternal.RegisterRefs("UsedAccessKinds", Undefined);
	
EndProcedure

// For the UpdateRegisterData, ProcessChangeRecordedOnImport procedures.
Procedure WhenChangingTheUseOfAccessTypes(PlanToUpdateAccessRestrictionSettings = False) Export
	
	InformationRegisters.AccessGroupsValues.UpdateRegisterData();
	InformationRegisters.UsedAccessKindsByTables.UpdateRegisterData();
	
	If PlanToUpdateAccessRestrictionSettings Then
		AccessManagementInternal.ScheduleAccessRestrictionParametersUpdate(
			"WhenChangingTheUseOfAccessTypes");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

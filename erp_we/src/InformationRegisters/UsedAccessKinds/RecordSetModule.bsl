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

Var OldRecords; // Filled "BeforeWrite" to use "OnWrite".

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// ACC:75-off - The DataExchange.Load check must follow the logging of changes.
	If UsersInternal.ShouldRegisterChangesInAccessRights() Then
		PrepareChangesForLogging(ThisObject, Replacing, OldRecords);
	EndIf;
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// ACC:75-off - The DataExchange.Load check must follow the logging of changes.
	If UsersInternal.ShouldRegisterChangesInAccessRights() Then
		DoLogChanges(ThisObject, Replacing, OldRecords);
	EndIf;
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure PrepareChangesForLogging(RecordSet, Replacing, OldRecords)
	
	OldRecords = Common.SetRecordsFromDatabase(RecordSet, Replacing, FieldList());
	
EndProcedure

Procedure DoLogChanges(RecordSet, Replacing, OldRecords)
	
	If Common.IsRecordSetDeletion(Replacing) Then
		Table = RecordSet.Unload(New Array, FieldList());
	Else
		Table = RecordSet.Unload(, FieldList());
	EndIf;
	Table.Columns.Add("ChangeType", New TypeDescription("String"));
	Table.FillValues("Added2", "ChangeType");
	
	If ValueIsFilled(OldRecords) Then
		IndexOf = Table.Count();
		While IndexOf > 0 Do
			IndexOf = IndexOf - 1;
			NewRecord = Table.Get(IndexOf);
			OldRecord = OldRecords.Find(NewRecord.AccessValuesType, "AccessValuesType");
			If OldRecord = Undefined Then
				Continue;
			EndIf;
			If NewRecord.Used = OldRecord.Used Then
				Table.Delete(NewRecord);
			Else
				NewRecord.ChangeType = "IsChanged";
			EndIf;
			OldRecords.Delete(OldRecord);
		EndDo;
		For Each OldRecord In OldRecords Do
			NewRow = Table.Add();
			FillPropertyValues(NewRow, OldRecord);
			NewRow.ChangeType = "Deleted";
		EndDo;
	EndIf;
	
	If Table.Count() = 0 Then
		Return;
	EndIf;
	
	Table.Columns.AccessValuesType.Name = "AccessKind";
	ObjectDetails = New Structure("AccessKindsChange", Table);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Catalogs.AccessGroups.RegisterChangeInAllowedValues(ObjectDetails, Undefined);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Intended for procedures "PrepareChangesForLogging" and "DoLogChanges".
Function FieldList()
	
	RegisterMetadata = Metadata();
	
	Fields = New Array;
	Fields.Add(RegisterMetadata.Dimensions.AccessValuesType.Name);
	Fields.Add(RegisterMetadata.Resources.Used.Name);
	
	Return StrConcat(Fields, ",");
	
EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Недопустимый вызов объекта на клиенте.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf
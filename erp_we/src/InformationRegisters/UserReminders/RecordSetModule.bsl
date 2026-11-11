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

Var OldRecords, ReminderPeriodBoundary;

#EndRegion

#Region EventHandlers

// ACC:75-off Notify about each reminder change.
Procedure BeforeWrite(Cancel, Replacing)
	
	If Not ShouldDisableClientNotifications(ThisObject) Then
		ReminderPeriodBoundary = CurrentSessionDate()
			+ UserRemindersInternal.ReminderTimeReserveForCache();
		OldRecords = OldRecords(ThisObject, Cancel, Replacing);
	EndIf;
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each Record In ThisObject Do
		Record.SourcePresentation = Common.SubjectString(Record.Source);
		If Record.ReminderTimeSettingMethod <> Enums.ReminderTimeSettingMethods.RelativeToSubjectTime Then
			Record.SourceAttributeName = "";
		EndIf;
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If Not ShouldDisableClientNotifications(ThisObject) Then
		SendClientNotification(OldRecords, ThisObject, Cancel, Replacing);
	EndIf;
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure
// ACC:75-on

#EndRegion

#Region Private

Function ShouldDisableClientNotifications(CurrentObject)
	
	Return CurrentObject.WriteDataHistory.AdditionalDataFieldsPresentations.Get("ShouldDisableClientNotifications") <> Undefined
	    Or CurrentObject.AdditionalProperties.Property("ShouldDisableClientNotifications");

EndFunction

Procedure SendClientNotification(OldRecords, RecordSet, Cancel, Replacing)
	
	If Cancel
	 Or Not GetFunctionalOption("UseUserReminders") Then
		Return;
	EndIf;
	
	FieldList = "User, EventTime, Source, ReminderTime, LongDesc, Id";
	ModifiedRecords = ModifiedRecords(OldRecords, RecordSet, Replacing, FieldList);
	
	UsersReminders = New Map;
	For Each Record In ModifiedRecords Do
		Reminders = UsersReminders.Get(Record.User);
		If Reminders = Undefined Then
			Reminders = UserRemindersInternal.NewModifiedReminders();
			UsersReminders.Insert(Record.User, Reminders);
		EndIf;
		Properties = New Structure(FieldList);
		FillPropertyValues(Properties, Record);
		Properties.Insert("PictureIndex", 2);
		Properties.Insert("URL", UserRemindersInternal.ReminderURL(Properties));
		If Record.LineChangeType = 1 Then
			Reminders.Added1.Add(Properties);
		Else
			Reminders.Trash.Add(Properties);
		EndIf;
	EndDo;
	
	NameOfAlert = UserRemindersClientServer.ServerNotificationName();
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	For Each KeyAndValue In UsersReminders Do
		IBUser = Users.FindByReference(KeyAndValue.Key);
		If IBUser = Undefined Then
			Continue;
		EndIf;
		Recipients = New Map;
		Recipients.Insert(IBUser.UUID,
			CommonClientServer.ValueInArray("*"));
		ServerNotifications.SendServerNotification(NameOfAlert,
			KeyAndValue.Value, Recipients);
	EndDo;
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

Function OldRecords(RecordSet, Cancel, Replacing)
	
	If Cancel
	 Or Not GetFunctionalOption("UseUserReminders") Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Reminders.User AS User,
	|	Reminders.EventTime AS EventTime,
	|	Reminders.Source AS Source,
	|	Reminders.ReminderTime AS ReminderTime,
	|	Reminders.LongDesc AS LongDesc,
	|	Reminders.Id AS Id,
	|	-1 AS LineChangeType
	|FROM
	|	InformationRegister.UserReminders AS Reminders
	|WHERE
	|	Reminders.ReminderTime <= &ReminderPeriodBoundary
	|	AND &FilterCriterion";
	
	Query.SetParameter("ReminderPeriodBoundary", ReminderPeriodBoundary);
	
	Parameters = Common.NewParametersToFilterSetRecordsFromDatabase();
	Parameters.TableAlias = "Reminders.";
	Common.FilterSetRecordsFromDatabase(RecordSet, Replacing, Query, Parameters);
	
	Return Query.Execute().Unload();
	
EndFunction

Function ModifiedRecords(OldRecords, RecordSet, Replacing, FieldList)
	
	If Common.IsRecordSetDeletion(Replacing) Then
		NewRecords = RecordSet.Unload(New Array);
	Else
		NewRecords = RecordSet.Unload();
	EndIf;
	
	For Each Record In NewRecords Do
		If Record.ReminderTime > ReminderPeriodBoundary Then
			Continue;
		EndIf;
		NewRow = OldRecords.Add();
		FillPropertyValues(NewRow, Record);
		NewRow.LineChangeType = 1;
	EndDo;
	
	OldRecords.GroupBy(FieldList, "LineChangeType");
	
	Rows = OldRecords.FindRows(New Structure("LineChangeType", 0));
	For Each String In Rows Do
		OldRecords.Delete(String);
	EndDo;
	
	Return OldRecords;
	
EndFunction

#EndRegion


#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf
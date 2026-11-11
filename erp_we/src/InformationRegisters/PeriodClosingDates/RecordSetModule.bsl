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
	PrepareChangesForLogging(ThisObject, Replacing, OldRecords);
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Filter.User.Use
	   And Not PeriodClosingDatesInternal.IsPeriodClosingAddressee(Filter.User.Value) Then
		// Import restriction dates are set up separately in each infobase.
		AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// ACC:75-off - The DataExchange.Load check must follow the logging of changes.
	DoLogChanges(ThisObject, Replacing, OldRecords);
	
	// For "DataExchange.Load", update the UUID in the constant "PeriodClosingDatesVersion",
	// which notifies the sessions that the period-end closing dates cache needs to be updated.
	If DataExchange.Load
	   And Not AdditionalProperties.Property("SkipPeriodClosingDatesVersionUpdate") Then
		
		PeriodClosingDatesInternal.UpdatePeriodClosingDatesVersionOnDataImport(ThisObject);
	EndIf;
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not AdditionalProperties.Property("SkipPeriodClosingDatesVersionUpdate") Then
		PeriodClosingDatesInternal.UpdatePeriodClosingDatesVersion();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure PrepareChangesForLogging(RecordSet, Replacing, OldRecords)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	RegisterMetadata = Metadata.InformationRegisters.PeriodClosingDates;
	
	Fields = New Array;
	Fields.Add(RegisterMetadata.Dimensions.Section.Name);
	Fields.Add(RegisterMetadata.Dimensions.Object.Name);
	Fields.Add(RegisterMetadata.Dimensions.User.Name);
	Fields.Add(RegisterMetadata.Resources.PeriodEndClosingDate.Name);
	Fields.Add(RegisterMetadata.Attributes.PeriodEndClosingDateDetails.Name);
	Fields.Add(RegisterMetadata.Attributes.Comment.Name);
	
	FieldList = StrConcat(Fields, ",");
	
	OldRecords = Common.SetRecordsFromDatabase(RecordSet, Replacing, FieldList);
	
EndProcedure

Procedure DoLogChanges(RecordSet, Replacing, OldRecords)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Table = Common.SetRecordsChange(OldRecords, RecordSet, Replacing);
	
	AddedRows = Table.FindRows(New Structure("LineChangeType", 1));
	DeletedRows = Table.FindRows(New Structure("LineChangeType", -1));
	
	If Not ValueIsFilled(AddedRows)
	   And Not ValueIsFilled(DeletedRows) Then
		Return;
	EndIf;
	
	RegisterMetadata = Metadata.InformationRegisters.PeriodClosingDates;
	
	Fields = New Array;
	Fields.Add(NewFieldDescription(RegisterMetadata.Dimensions.Section));
	Fields.Add(NewFieldDescription(RegisterMetadata.Dimensions.Object));
	Fields.Add(NewFieldDescription(RegisterMetadata.Dimensions.User));
	Fields.Add(NewFieldDescription(RegisterMetadata.Resources.PeriodEndClosingDate));
	Fields.Add(NewFieldDescription(RegisterMetadata.Attributes.PeriodEndClosingDateDetails));
	Fields.Add(NewFieldDescription(RegisterMetadata.Attributes.Comment));
	
	Title = New Array;
	Title.Add("");
	For Each Field In Fields Do
		Title.Add(AugmentedString(Field.Presentation, Fields, Field));
	EndDo;
	
	CommentLines = New Array;
	CommentLines.Add(StrConcat(Title, " | "));
	
	If ValueIsFilled(AddedRows) Then
		AddLines(CommentLines, AddedRows, Fields, "+");
	EndIf;
	If ValueIsFilled(DeletedRows) Then
		AddLines(CommentLines, DeletedRows, Fields, "-");
	EndIf;
	
	Comment = StrConcat(CommentLines, Chars.LF) + Chars.LF;
	
	SpacesByWidth = SpacesByWidth();
	InitialWidth = StrLen(SpacesByWidth);
	For Each Field In Fields Do
		ReplacementString = Left(SpacesByWidth, InitialWidth - Field.Width) + "/" + Fields.Find(Field) + " | ";
		Comment = StrReplace(Comment, ReplacementString, " | ");
	EndDo;
	
	WriteLogEvent(
		NStr("vi = 'Ngày cấm.Ghi nhận thay đổi';
			|ru = 'Даты запрета.Регистрация изменений';
			|en = 'Period-end closing dates.Change registration'; fa = 'Period-end closing dates.Change registration';
			|it = 'Dati divieto.Registrazione modifiche';
			|pl = 'Daty zakazu.Rejestracja zmian';
			|tr = 'Yasak tarihleri. Değişikliklerin kaydı'",
			Common.DefaultLanguageCode()),
		EventLogLevel.Information, RegisterMetadata,
		,
		Comment,
		EventLogEntryTransactionMode.Transactional);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

Function NewFieldDescription(FieldMetadata)
	
	FieldDetails = New Structure;
	FieldDetails.Insert("Name", FieldMetadata.Name);
	FieldDetails.Insert("Presentation", FieldMetadata.Presentation());
	FieldDetails.Insert("Width", 0);
	
	Return FieldDetails;
	
EndFunction

Function AugmentedString(Value, Fields, Field)
	
	Type = TypeOf(Value);
	If Type = Type("Date") Then
		String = Format(Value, "DLF=DT");
	Else
		String = String(Value);
	EndIf;
	If Not ValueIsFilled(String) And Type <> Type("String") Then
		String = "<> (" + String(TypeOf(Value)) + ")";
	EndIf;
	String = StrReplace(TrimAll(String), Chars.LF, " ");
	
	FieldIndex = Fields.Find(Field);
	If FieldIndex = Fields.UBound() Then
		Return String;
	EndIf;
	
	StringLength = StrLen(String);
	SpacesByWidth = SpacesByWidth();
	InitialWidth = StrLen(SpacesByWidth);
	If StringLength >= InitialWidth Then
		Return String;
	EndIf;
	
	If Field.Width < StringLength Then
		Field.Width = StringLength;
	EndIf;
	
	Return String + Left(SpacesByWidth, InitialWidth - StringLength) + "/" + FieldIndex;
	
EndFunction

Function SpacesByWidth()
	Return "                                                                      ";
EndFunction

Procedure AddLines(CommentLines, TableRows, Fields, Operation)
	
	For Each TableRow In TableRows Do
		CommentLine = New Array;
		For Each Field In Fields Do
			CommentLine.Add(AugmentedString(TableRow[Field.Name], Fields, Field));
		EndDo;
		CommentLines.Add(Operation + "| " + StrConcat(CommentLine, " | "));
	EndDo;
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf
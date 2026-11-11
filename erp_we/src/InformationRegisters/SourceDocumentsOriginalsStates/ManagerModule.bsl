///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use "SourceDocumentsOriginalsRecording.WriteDocumentOriginalsStatesAfterPrintForm".
// Records states of print form originals to the register after printing the form.
//
//	Parameters:
//  PrintObjects - ValueList - a document list.
//  PrintForms - ValueList - a description of templates and a presentation of print forms.
//  Written1 - Boolean - indicates that the document state is written to the register.
//
Procedure WriteDocumentOriginalsStatesAfterPrintForm(PrintObjects, PrintForms, Written1 = False) Export
	
	SSLSubsystemsIntegration.BeforeWriteOriginalStatesAfterPrint(PrintObjects, PrintForms);
	SourceDocumentsOriginalsRecordingOverridable.BeforeWriteOriginalStatesAfterPrint(PrintObjects, PrintForms);
	
	State = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.FormPrinted");
	If Not ValueIsFilled(PrintObjects) Then 
		Return;
	EndIf;
	
	Block = New DataLock();

	BeginTransaction();
	Try
		
		For Each Document In PrintObjects Do
			If SourceDocumentsOriginalsRecording.IsAccountingObject(Document.Value) Then 
				LockItem = Block.Add("InformationRegister.SourceDocumentsOriginalsStates");
				LockItem.SetValue("Owner", Document.Value); 
			EndIf;
		EndDo;
		Block.Lock();
		
		For Each Document In PrintObjects Do
			If SourceDocumentsOriginalsRecording.IsAccountingObject(Document.Value) Then 
				TS = SourceDocumentsOriginalsRecording.TableOfEmployees(Document.Value);
				If TS <> "" Then
					For Each Employee In Document.Value[TS] Do
						For Each Form In PrintForms Do 
							SourceDocumentsOriginalsRecording.WriteDocumentOriginalStateByPrintForms(Document.Value, 
								Form.Value, Form.Presentation, State, False, Employee.Employee);
						EndDo;
					EndDo;
				Else
					For Each Form In PrintForms Do
						SourceDocumentsOriginalsRecording.WriteDocumentOriginalStateByPrintForms(Document.Value, 
							Form.Value, Form.Presentation, State, False);
					EndDo;
				EndIf;
				SourceDocumentsOriginalsRecording.WriteCommonDocumentOriginalState(Document.Value, State);
				Written1 = True;
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except	
		
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Deprecated. Instead, use "SourceDocumentsOriginalsRecording.WriteDocumentOriginalStateByPrintForms".
// Records states of print form originals in the register after printing the form.
//
//	Parameters:
//  Document - DocumentRef - document reference.
//  PrintForm - String - a print form template name.
//  Presentation - String - a print form description.
//  State - CatalogRef.SourceDocumentsOriginalsStates - Reference to the print form original state.
//  FromOutside - Boolean - indicates whether the form belongs to 1C:Enterprise.
//  Employee - CatalogRef - A reference to an employee if the source document contains employees information.
//
Procedure WriteDocumentOriginalStateByPrintForms(Document, PrintForm, Presentation, State, 
	FromOutside, Employee = Undefined) Export
	
	SetPrivilegedMode(True);
	
	OriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordManager();
	OriginalStateRecord.Owner = Document;
	OriginalStateRecord.SourceDocument = PrintForm;
	If ValueIsFilled(Employee) Then
		LastFirstName = PersonsClientServer.InitialsAndLastName(Employee.Description);
		Values = New Structure("Presentation, LASTFIRSTNAME", Presentation, LastFirstName);
		EmployeeView = StrFind(Presentation, LastFirstName);
		If EmployeeView = 0 Then
			OriginalStateRecord.SourceDocumentPresentation = StringFunctionsClientServer.InsertParametersIntoString(
				NStr("vi = '[Presentation] [LastFirstName]';
					|ru = '[Presentation] [LastFirstName]';
					|en = '[Presentation] [LastFirstName]'; fa = '[Presentation] [LastFirstName]';
					|it = '[Presentation] [LastFirstName]';
					|pl = '[Presentation] [LastFirstName]';
					|tr = '[Presentation][LastFirstName]'"), Values);
		Else
			OriginalStateRecord.SourceDocumentPresentation = Presentation;
		EndIf;
	Else
		OriginalStateRecord.SourceDocumentPresentation = Presentation;
	EndIf; 
	If TypeOf(State) = Type("String") Then
		OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.FindByDescription(State);
	Else
		OriginalStateRecord.State = State;
	EndIf;
	OriginalStateRecord.ChangeAuthor = Users.CurrentUser();
	OriginalStateRecord.OverallState = False;
	OriginalStateRecord.ExternalForm = FromOutside;
	OriginalStateRecord.LastChangeDate = CurrentSessionDate();
	OriginalStateRecord.Employee = Employee;
	OriginalStateRecord.Write();

EndProcedure

// Deprecated. Instead, use SourceDocumentsOriginalsRecording.WriteCommonDocumentOriginalState.
// Records the aggregated state of the document original in the register.
//
//	Parameters:
//  Document - DocumentRef - document reference.
//  State - CatalogRef.SourceDocumentsOriginalsStates - Reference to the original state.
//
Procedure WriteCommonDocumentOriginalState(Document, State) Export
	
	If TypeOf(State) = Type("String") Then
		OriginalState = Catalogs.SourceDocumentsOriginalsStates.FindByDescription(State);
	Else
		OriginalState = State;
	EndIf;

	SetPrivilegedMode(True);
		
	OriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordManager();
	OriginalStateRecord.Owner = Document;
	OriginalStateRecord.SourceDocument = "";
		
	CheckOriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
	CheckOriginalStateRecord.Filter.Owner.Set(Document);
	CheckOriginalStateRecord.Filter.OverallState.Set(False);
	CheckOriginalStateRecord.Read();
	If CheckOriginalStateRecord.Count() Then
		For Each Record In CheckOriginalStateRecord Do
			If Record.ChangeAuthor <> Users.CurrentUser() Then
				OriginalStateRecord.ChangeAuthor = Undefined;
			Else
				OriginalStateRecord.ChangeAuthor = Users.CurrentUser();
			EndIf;
		EndDo;
		If SourceDocumentsOriginalsRecording.PrintFormsStateSame(Document, OriginalState) Then
			OriginalStateRecord.State = OriginalState;
		Else
			OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.OriginalsNotAll;
		EndIf;
	Else
		OriginalStateRecord.State = OriginalState;
	EndIf;
		
	OriginalStateRecord.OverallState = True;
	OriginalStateRecord.LastChangeDate = CurrentSessionDate();
	OriginalStateRecord.Write();
	
	SSLSubsystemsIntegration.OnChangeAggregatedOriginalState(Document, State);
	SourceDocumentsOriginalsRecordingOverridable.OnChangeAggregatedOriginalState(Document, State);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf


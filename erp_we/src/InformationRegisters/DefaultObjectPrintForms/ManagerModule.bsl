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

Function CommandID(Object) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DefaultObjectPrintForms.Id
		|FROM
		|	InformationRegister.DefaultObjectPrintForms AS DefaultObjectPrintForms
		|WHERE
		|	DefaultObjectPrintForms.Object = &Object";
	
	Query.SetParameter("Object", Object);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		Result = Selection.Id;
	Else
		Result = "";
	EndIf;
	
	Return Result;
	
EndFunction

Function CommandsIDs(Objects) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DefaultObjectPrintForms.Object AS Object,
		|	DefaultObjectPrintForms.Id AS Id
		|FROM
		|	InformationRegister.DefaultObjectPrintForms AS DefaultObjectPrintForms
		|WHERE
		|	DefaultObjectPrintForms.Object IN (&Objects)
		|TOTALS
		|BY
		|	Id";
	
	Query.SetParameter("Objects", Objects);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	IDsSelection = QueryResult.Select(QueryResultIteration.ByGroups);
	
	Result = New Structure;
	
	While IDsSelection.Next() Do
		Selection = IDsSelection.Select();
		
		References = New Array;
		While Selection.Next() Do
			References.Add(Selection.Object);
		EndDo;
		Result.Insert(IDsSelection.Id, References);
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure SaveDescriptionOfDefaultPrintForm(References, PrintFormDescription, Id) Export
	
	If TypeOf(References) <> Type("Array") Then
		ReferencesArrray = CommonClientServer.ValueInArray(References);
	Else
		ReferencesArrray = Common.CopyRecursive(References);
	EndIf;
	
	User = Users.CurrentUser();
	Date = CurrentSessionDate();
	
	For Each ObjectReference In ReferencesArrray Do
		
		Record = CreateRecordManager();
		Record.Object = ObjectReference;
		Record.Id = PrintManagementClientServer.IDWithoutSpecialChars(Id);
		Record.User = User;
		Record.Date = Date;
		Record.PrintFormDescription = PrintFormDescription;
		SetPrivilegedMode(True);
		Record.Write(True);
		SetPrivilegedMode(False);
		
	EndDo;
	
EndProcedure

Function PrintFormsDescriptions(References) Export
	
	Result = New Map;
	For Each Ref In References Do
		Result.Insert(Ref, Undefined);
	EndDo;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DefaultObjectPrintForms.Object AS Object,
		|	DefaultObjectPrintForms.PrintFormDescription AS PrintFormDescription
		|FROM
		|	InformationRegister.DefaultObjectPrintForms AS DefaultObjectPrintForms
		|WHERE
		|	DefaultObjectPrintForms.Object IN (&References)";
	
	Query.SetParameter("References", References);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	Selection = QueryResult.Select();
	While Selection.Next() Do
		Result[Selection.Object] = Selection.PrintFormDescription;
	EndDo;
	
	Return Result;
	
EndFunction

Function SavedDescriptions(Objects) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DefaultObjectPrintForms.PrintFormDescription AS PrintFormDescription,
		|	DefaultObjectPrintForms.Id,
		|	DefaultObjectPrintForms.User,
		|	DefaultObjectPrintForms.Date
		|FROM
		|	InformationRegister.DefaultObjectPrintForms AS DefaultObjectPrintForms
		|WHERE
		|	DefaultObjectPrintForms.Object IN (&Objects)";
	
	Query.SetParameter("Objects", Objects);
	SetPrivilegedMode(True);
	QueryResult = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Return Common.ValueTableToArray(QueryResult);
	
EndFunction
#EndRegion

#EndIf

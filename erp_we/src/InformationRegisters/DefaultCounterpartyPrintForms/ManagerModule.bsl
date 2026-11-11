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

Function CommandID(Document, Organization, Recipient) Export
	
	ObjectType = Common.MetadataObjectID(TypeOf(Document));
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DefaultCounterpartyPrintForms.Id
		|FROM
		|	InformationRegister.DefaultCounterpartyPrintForms AS DefaultCounterpartyPrintForms
		|WHERE
		|	DefaultCounterpartyPrintForms.Organization = &Organization
		|	AND DefaultCounterpartyPrintForms.Recipient = &Recipient
		|	AND DefaultCounterpartyPrintForms.ObjectType = &ObjectType
		|
		|UNION ALL
		|
		|SELECT
		|	DefaultCounterpartyPrintForms.Id
		|FROM
		|	InformationRegister.DefaultCounterpartyPrintForms AS DefaultCounterpartyPrintForms
		|WHERE
		|	DefaultCounterpartyPrintForms.Organization = &Organization
		|	AND DefaultCounterpartyPrintForms.ObjectType = &ObjectType";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Recipient", Recipient);
	Query.SetParameter("ObjectType", ObjectType);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		Result = Selection.Id;
	Else
		Result = "";
	EndIf;
	
	Return Result;
	
EndFunction

Procedure WritePrintFormID(Ref, Id) Export
	
	KeyAttributes = KeyAttributes();
	
	PrintManagementOverridable.OnDefineKeyAttributesOfDefaultPrintForms(
		Ref, KeyAttributes);
	
	Organization = KeyAttributes.Organization;
	Recipient  = KeyAttributes.Recipient;
	ObjectType  = Common.MetadataObjectID(Ref.Metadata());
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.Organization.Set(Organization);
	RecordSet.Filter.Recipient.Set(Recipient);
	RecordSet.Filter.ObjectType.Set(ObjectType);
	SetPrivilegedMode(True);
	RecordSet.Read();
	SetPrivilegedMode(False);
	
	IDWithoutSpecialChars = PrintManagementClientServer.IDWithoutSpecialChars(Id);
	
	If RecordSet.Count() = 1 Then
		If RecordSet[0].Id = IDWithoutSpecialChars Then
			Return;
		Else
			RecordSet[0].Id = IDWithoutSpecialChars;
		EndIf;
	Else
		RecordSet.Add();
		RecordSet[0].Organization   = Organization;
		RecordSet[0].Recipient    = Recipient;
		RecordSet[0].ObjectType    = ObjectType;
		RecordSet[0].Id = IDWithoutSpecialChars;
	EndIf;
	
	SetPrivilegedMode(True);
	RecordSet.Write();
	SetPrivilegedMode(False);
EndProcedure

Function KeyAttributes() Export
	
	Structure = New Structure;
	Structure.Insert("Organization", Undefined);
	Structure.Insert("Recipient", Undefined);
	
	Return Structure;
	
EndFunction

#EndRegion

#EndIf

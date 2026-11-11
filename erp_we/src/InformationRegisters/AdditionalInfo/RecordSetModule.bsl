///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModifiedObjects = UnloadColumn("Object");
		ModifiedObjects = CommonClientServer.CollapseArray(ModifiedObjects);

		If ModifiedObjects.Count() = 0 Then
			If ValueIsFilled(Filter.Object.Value) Then
				ModifiedObjects.Add(Filter.Object.Value);
			Else
				ModifiedObjects = AllObjects(Filter.Property.Value);
			EndIf;
		EndIf;
		
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		SetPrivilegedMode(True);
		
		For Each Ref In ModifiedObjects Do
			If Common.IsRecordSetDeletion(Replacing) Then
				ObjectRecords = New Array;
			Else
				AllRecords = Unload();
				ObjectRecords = AllRecords.FindRows(New Structure("Object", Ref));
			EndIf;
			
			ModifiedObject = Ref.GetObject();
			If ModifiedObject <> Undefined Then
				ModifiedObject.AdditionalProperties.Insert("WrittenAdditionalInfo", ObjectRecords);
				ModuleObjectsVersioning.WriteObjectVersion(ModifiedObject);
			EndIf;
		EndDo;
		
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function AllObjects(Property)
	
	FilterCriterion = "TRUE";
	
	QueryText =
	"SELECT
	|	AdditionalInfo.Object AS Object
	|FROM
	|	InformationRegister.AdditionalInfo AS AdditionalInfo
	|WHERE
	|	&FilterCriterion
	|
	|GROUP BY
	|	AdditionalInfo.Object";
	
	Query = New Query;
	If ValueIsFilled(Property) Then
		FilterCriterion = "AdditionalInfo.Property = &Property";
		Query.SetParameter("Property", Property);
	EndIf;
	QueryText = StrReplace(QueryText, "&FilterCriterion", FilterCriterion);
	Query.Text = QueryText;
	
	Return Query.Execute().Unload().UnloadColumn("Object");
	
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
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

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

#EndRegion

#EndRegion

#Region Private

// Returns a reference to the add-in catalog by ID and version.
//
// Parameters:
//  Id - String - Add-in object ID.
//  Version        - String - Add-in version.
//
// Returns:
//  CatalogRef.AddIns - a reference to an add-in container in the infobase.
//
Function FindByID(Id, Version = Undefined) Export
	
	Query = New Query;
	Query.SetParameter("Id", Id);
	
	If Not ValueIsFilled(Version) Then 
		Query.Text = 
			"SELECT TOP 1
			|	AddIns.Ref AS Ref
			|FROM
			|	Catalog.CommonAddIns AS AddIns
			|WHERE
			|	AddIns.Id = &Id
			|
			|ORDER BY
			|	AddIns.VersionDate DESC";
	Else 
		Query.SetParameter("Version", Version);
		Query.Text = 
			"SELECT TOP 1
			|	AddIns.Ref AS Ref
			|FROM
			|	Catalog.CommonAddIns AS AddIns
			|WHERE
			|	AddIns.Id = &Id
			|	AND AddIns.Version = &Version";
		
	EndIf;
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then 
		Return EmptyRef();
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Result.Unload()[0].Ref;
	
EndFunction

#Region UpdateHandlers

// Fills the "TargetPlatforms" attribute in the "CommonAddIns" catalog.
//
Procedure HandleCommonAddIns() Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CommonAddIns.Ref,
	|	CommonAddIns.AddInStorage,
	|	CommonAddIns.TargetPlatforms
	|FROM
	|	Catalog.CommonAddIns AS CommonAddIns";
		
	Selection = Query.Execute().Select();
	
	If Selection.Count() = 0 Then
		Return;
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;

	While Selection.Next() Do

		TargetPlatforms = Selection.TargetPlatforms.Get();
		ComponentBinaryData = Selection.AddInStorage.Get();
		
		If TypeOf(ComponentBinaryData) <> Type("BinaryData") Then
			ObjectsProcessed = ObjectsProcessed + 1;
			Continue;
		EndIf;
		
		InformationOnAddInFromFile = AddInsInternal.InformationOnAddInFromFile(
			ComponentBinaryData, False);
		If Not InformationOnAddInFromFile.Disassembled Then
			ObjectsProcessed = ObjectsProcessed + 1;
			Continue;
		EndIf;
		
		Attributes = InformationOnAddInFromFile.Attributes;
		
		If TargetPlatforms <> Undefined And Common.IdenticalCollections(TargetPlatforms, Attributes.TargetPlatforms) Then
			ObjectsProcessed = ObjectsProcessed + 1;
			Continue;
		EndIf;
		
		RepresentationOfTheReference = String(Selection.Ref);
		BeginTransaction();
		Try

			Block = New DataLock;
			LockItem = Block.Add("Catalog.CommonAddIns");
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();

			ComponentObject_ = Selection.Ref.GetObject(); // CatalogObject.CommonAddIns
			ComponentObject_.TargetPlatforms = New ValueStorage(Attributes.TargetPlatforms, New Deflation(9));
			InfobaseUpdate.WriteObject(ComponentObject_);

			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();

		Except

			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;

			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xử lý cấu phần chung %1 do nguyên nhân:
					 |%2';
					 |ru = 'Не удалось обработать общую компоненту %1 по причине:
					 |%2';
					 |en = 'Couldn''t process the common add-in %1 due to:
					 |%2'; fa = 'Couldn''t process the common add-in %1 due to:
					 |%2';
					 |it = 'Не удалось обработать общую компоненту %1 по причине:
					 |%2';
					 |pl = 'Couldn''t process the common add-in %1 due to:
					 |%2';
					 |tr = 'Ortak %1 bileşeni şu nedenle işlenemedi:
					 |%2'"), RepresentationOfTheReference, ErrorProcessing.DetailErrorDescription(ErrorInfo()));

			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning, Selection.Ref.Metadata(), Selection.Ref, MessageText);

		EndTry;

	EndDo;

	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý cấu phần chung (bị bỏ qua): %1';
				|ru = 'Не удалось обработать общие компоненты (пропущены): %1';
				|en = 'Couldn''t process (skipped) some common add-ins: %1'; fa = 'Couldn''t process (skipped) some common add-ins: %1';
				|it = 'Не удалось обработать общие компоненты (пропущены): %1';
				|pl = 'Couldn''t process (skipped) some common add-ins: %1';
				|tr = 'Ortak bileşenler işlenemedi (atlandı): %1'"),
			ObjectsWithIssuesCount);
		Raise MessageText;
	EndIf;
	
EndProcedure

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("HandleCommonAddIns");
	
EndProcedure

#EndRegion

#EndIf
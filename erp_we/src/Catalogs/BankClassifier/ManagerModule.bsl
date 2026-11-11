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

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("*");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// CloudTechnology.ExportImportData

// Returns the catalog attributes
// that naturally form a catalog item key.
//
// Returns:
//  Array - Array of attribute names used to generate a natural key.
//
Function NaturalKeyFields() Export
	
	Result = New Array();
	
	Result.Add("Code");
	Result.Add("CorrAccount");
	
	Return Result;
	
EndFunction

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#Region Internal

// Registers the objects to be updated in the InfobaseUpdate exchange plan.
// 
//
// Parameters:
//  Parameters - Structure - Internal parameter to pass to the InfobaseUpdate.MarkForProcessing procedure.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		Return;
	EndIf;
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return
	EndIf;
	
	QueryText =
	"SELECT
	|	BankClassifier.Ref
	|FROM
	|	Catalog.BankClassifier AS BankClassifier
	|WHERE
	|	NOT BankClassifier.IsFolder
	|	AND BankClassifier.CountryCode = """"
	|	AND BankClassifier.ObsoleteCountry <> &EmptyCountryRef";
	
	ModuleContactsManagerInternal = Common.CommonModule("ContactsManagerInternal");
	WorldCountriesCatalogEmptyRef = ModuleContactsManagerInternal.WorldCountriesCatalogEmptyRef();
	
	Query = New Query(QueryText);
	Query.SetParameter("EmptyCountryRef", WorldCountriesCatalogEmptyRef);
	Banks = Query.Execute().Unload().UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, Banks);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		Return;
	EndIf;
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	ModuleContactsManagerInternal = Common.CommonModule("ContactsManagerInternal");
	CountriesCodes = ModuleContactsManagerInternal.CountriesCodes();
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.BankClassifier");
	
	While Selection.Next() Do
		Block = New DataLock;
		LockItem = Block.Add("Catalog.BankClassifier");
		LockItem.SetValue("Ref", Selection.Ref);
		
		BeginTransaction();
		Try
			Block.Lock();
			
			Bank = Selection.Ref.GetObject();
			Bank.CountryCode = CountriesCodes[Bank.ObsoleteCountry];
			InfobaseUpdate.WriteData(Bank);
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			Raise;
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.BankClassifier");
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý một số người tham gia tính toán (đã bỏ qua): %1';
				|ru = 'Не удалось обработать некоторых участников расчетов (пропущены): %1';
				|en = 'Couldn''t process (skipped) some settlement parties: %1'; fa = 'Couldn''t process (skipped) some settlement parties: %1';
				|it = 'Couldn''t process (skipped) some settlement parties: %1';
				|pl = 'Couldn''t process (skipped) some settlement parties: %1';
				|tr = 'Bazı alacak/borç muhasebesi katılımcıları işlenemedi (atlandı): %1'"),
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information, Metadata.Catalogs.BankClassifier,,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã xử lý một phần người tham gia tính toán việc in: %1';
						|ru = 'Обработана очередная порция участников расчетов печати: %1';
						|en = 'Another batch of settlement parties is processed: %1'; fa = 'Another batch of settlement parties is processed: %1';
						|it = 'Another batch of settlement parties is processed: %1';
						|pl = 'Another batch of settlement parties is processed: %1';
						|tr = 'Başka bir takım alacak/borç muhasebesi katılımcıları işlendi: %1'"),
			ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#EndIf


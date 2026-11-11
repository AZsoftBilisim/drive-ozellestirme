///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Adds an entry to the information register.
//
// Parameters:
//  BinaryDataStorageRef	- CatalogRef.BinaryDataStorage - Value of the BinaryDataStorage dimension.
//  RecordAttributesValues			- Structure
//
Procedure AddChangeRecord(BinaryDataStorageRef, RecordAttributesValues) Export

	Set = CreateRecordSet();
	Set.Filter.BinaryDataStorage.Set(BinaryDataStorageRef);

	Block = New DataLock;
	Block.Add("InformationRegister.BinaryDataStorages").SetValue("BinaryDataStorage", BinaryDataStorageRef);

	BeginTransaction();	
	Try

		Block.Lock();	
		
		Set.Read();
		If Set.Count() = 0 Then
			Record = Set.Add();
		Else
			Record = Set[0];
		EndIf;
		
		Record.BinaryDataStorage	= BinaryDataStorageRef;
		FillPropertyValues(Record, RecordAttributesValues);

		Set.Write();

		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

// Deletes an entry from the information register.
//
// Parameters:
//  BinaryDataStorageRef	- CatalogRef.BinaryDataStorage - Value of the BinaryDataStorage dimension.
//
Procedure DeleteRecord(BinaryDataStorageRef) Export

	Record = CreateRecordManager();
	Record.BinaryDataStorage = BinaryDataStorageRef;

	Record.Delete();	

EndProcedure

#EndRegion

#EndIf
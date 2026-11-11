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

// Updates register data if the developer
// changed dependencies in the overridable module.
//
// Parameters:
//  HasChanges - Boolean - (return value) - if recorded,
//                  True is set, otherwise, it does not change.
//
Procedure UpdateRegisterData(HasChanges = Undefined) Export
	
	If AccessManagementInternal.IsRecordLevelRestrictionDisabled() Then
		AccessManagementInternal.ClearInformationRegister(
			Metadata.InformationRegisters.AccessRightsDependencies.FullName(), HasChanges);
		Return;
	EndIf;
	
	StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
	SetPrivilegedMode(True);
	
	AccessRightsDependencies = AccessRightsDependencies();
	
	TemporaryTablesQueriesText =
	"SELECT
	|	NewData.SubordinateTable,
	|	NewData.LeadingTableType
	|INTO NewData
	|FROM
	|	&AccessRightsDependencies AS NewData";
	
	QueryText =
	"SELECT
	|	NewData.SubordinateTable,
	|	NewData.LeadingTableType,
	|	&RowChangeKindFieldSubstitution
	|FROM
	|	NewData AS NewData";
	
	// Preparing the selected fields with optional filter.
	Fields = New Array;
	Fields.Add(New Structure("SubordinateTable"));
	Fields.Add(New Structure("LeadingTableType"));
	
	Query = New Query;
	AccessRightsDependencies.GroupBy("SubordinateTable, LeadingTableType");
	Query.SetParameter("AccessRightsDependencies", AccessRightsDependencies);
	
	Query.Text = AccessManagementInternal.ChangesSelectionQueryText(
		QueryText, Fields, "InformationRegister.AccessRightsDependencies", TemporaryTablesQueriesText);
	
	Block = New DataLock;
	Block.Add("InformationRegister.AccessRightsDependencies");
	
	BeginTransaction();
	Try
		Block.Lock();
		
		Data = New Structure;
		Data.Insert("RegisterManager",      InformationRegisters.AccessRightsDependencies);
		Data.Insert("EditStringContent", Query.Execute().Unload());
		
		AccessManagementInternal.UpdateInformationRegister(Data, HasChanges);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

// Returns:
//  ValueTable:
//   * SubordinateTable - CatalogRef.MetadataObjectIDs
//   * LeadingTableType  - AnyRef
//
Function AccessRightsDependencies() Export
	
	AccessRightsDependencies = CreateRecordSet();
	
	Table = New ValueTable;
	Table.Columns.Add("SubordinateTable", New TypeDescription("String"));
	Table.Columns.Add("LeadingTable",     New TypeDescription("String"));
	
	SSLSubsystemsIntegration.OnFillAccessRightsDependencies(Table);
	AccessManagementOverridable.OnFillAccessRightsDependencies(Table);
	
	AccessRightsDependencies = CreateRecordSet().Unload();
	For Each String In Table Do
		NewRow = AccessRightsDependencies.Add();
		
		MetadataObject = Common.MetadataObjectByFullName(String.SubordinateTable);
		If MetadataObject = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi trong thủ tục %1
				           |của mô-đun chung %2.
				           |
				           |Không tìm thấy bảng trực thuộc ""%3"".';
				           |ru = 'Ошибка в процедуре %1
				           |общего модуля %2.
				           |
				           |Не найдена подчиненная таблица ""%3"".';
				           |en = 'Error in procedure %1
				           |of common module %2.
				           |
				           |Cannot find subordinate table ""%3"".'; fa = 'Error in procedure %1
				           |of common module %2.
				           |
				           |Cannot find subordinate table ""%3"".';
				           |it = 'Errore nella procedura %1
				           | del modulo comune %2.
				           | 
				           |Tabella subordinata ""%3"" non trovata.';
				           |pl = 'Błąd w procedurze %1
				           |do wspólnego modułu %2.
				           |
				           |Nie znaleziono podległej tabeli ""%3"".';
				           |tr = '%2genel modülünün %1
				           |prosedüründe hata oluştu.
				           |
				           |Alt tablo bulunamadı ""%3"".'"),
				"OnFillAccessRightsDependencies",
				"AccessManagementOverridable",
				String.SubordinateTable);
			Raise ErrorText;
		EndIf;
		NewRow.SubordinateTable = Common.MetadataObjectID(
			String.SubordinateTable);
		
		MetadataObject = Common.MetadataObjectByFullName(String.LeadingTable);
		If MetadataObject = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi trong thủ tục %1
				           |của mô-đun chung %2.
				           |
				           |Không tìm thấy bảng chính ""%3"".';
				           |ru = 'Ошибка в процедуре %1
				           |общего модуля %2.
				           |
				           |Не найдена ведущая таблица ""%3"".';
				           |en = 'Error in procedure %1
				           |of common module %2.
				           |
				           |Cannot find master table ""%3"".'; fa = 'Error in procedure %1
				           |of common module %2.
				           |
				           |Cannot find master table ""%3"".';
				           |it = 'Errore nella procedura %1
				           | del modulo comune %2.
				           | 
				           |Tabella principale ""%3"" non trovata.';
				           |pl = 'Błąd w procedurze %1
				           |do wspólnego modułu %2.
				           |
				           |Nie znaleziono wiodącej tabeli ""%3"".';
				           |tr = '%2genel modülünün %1
				           |prosedüründe hata oluştu.
				           |
				           |Alt tablo bulunamadı ""%3"".'"),
				"OnFillAccessRightsDependencies",
				"AccessManagementOverridable",
				String.LeadingTable);
			Raise ErrorText;
		EndIf;
		NewRow.LeadingTableType = Common.ObjectManagerByFullName(
			String.LeadingTable).EmptyRef();
	EndDo;
	
	Return AccessRightsDependencies;
	
EndFunction

#EndRegion

#EndIf
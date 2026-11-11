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

// Generates a permission key (to be used in registers, in which the granted
// permission details are stored).
//
// Parameters:
//  Resolution - XDTODataObject
//
// Returns:
//   String
//
Function PermissionKey(Val Resolution) Export
	
	Hashing = New DataHashing(HashFunction.MD5);
	Hashing.Append(Common.XDTODataObjectToXMLString(Resolution));
	
	Supplement = PermissionAddition(Resolution);
	If ValueIsFilled(Supplement) Then
		Hashing.Append(Common.ValueToXMLString(Supplement));
	EndIf;
	
	Var_Key = XDTOFactory.Create(XDTOFactory.Type("http://www.w3.org/2001/XMLSchema", "hexBinary"), Hashing.HashSum).LexicalValue;
	
	If StrLen(Var_Key) > 32 Then
		Raise NStr("vi = 'Đã vượt quá chiều dài khóa';
					|ru = 'Превышение длины ключа';
					|en = 'Key length exceeded'; fa = 'Key length exceeded';
					|it = 'Superamento della lunghezza della chiave';
					|pl = 'Przekroczenie długości klucza';
					|tr = 'Anahtar uzunluğu aşıldı'");
	EndIf;
	
	Return Var_Key;
	
EndFunction

// Generates a permission addition.
//
// Parameters:
//  Resolution - XDTODataObject
//
// Returns:
//   Arbitrary
//
Function PermissionAddition(Val Resolution) Export
	
	If Resolution.Type() = XDTOFactory.Type(SafeModeManagerInternal.Package(), "AttachAddin") Then
		Return SafeModeManagerInternal.AddInBundleFilesChecksum(Resolution.TemplateName);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns:
//   ValueTable:
//   * ProgramModuleType - CatalogRef.MetadataObjectIDs
//   * ModuleID - UUID
//   * Type - String - Name of the XDTO type that describes permissions.
//   * Permissions - Map of KeyAndValue:
//       ** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//       ** Value - XDTODataObject - XDTO permission details.
//   * PermissionsAdditions - Map of KeyAndValue - Describes permission additions:
//       ** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//       ** Value - See InformationRegister.PermissionsToUseExternalResources.PermissionAddition
//
Function NewPermissionsSlice() Export
	
	Result = New ValueTable();
	
	Result.Columns.Add("ProgramModuleType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.Columns.Add("ModuleID", New TypeDescription("UUID"));
	Result.Columns.Add("Type", New TypeDescription("String"));
	Result.Columns.Add("Permissions", New TypeDescription("Map"));
	Result.Columns.Add("PermissionsAdditions", New TypeDescription("Map"));
	
	Return Result;
	
EndFunction

// Returns:
//   ValueTable:
//   * ProgramModuleType - CatalogRef.MetadataObjectIDs
//   * ModuleID - UUID
//   * OwnerType - CatalogRef.MetadataObjectIDs
//   * OwnerID - UUID
//   * Type - String - Name of the XDTO type that describes permissions.
//   * Permissions - Map of KeyAndValue:
//       ** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//       ** Value - XDTODataObject - Permission details in XDTO format.
//   * PermissionsAdditions - Map of KeyAndValue - Describes permission additions:
//       ** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//       ** Value - See InformationRegister.PermissionsToUseExternalResources.PermissionAddition
//
Function NewPermissionsSliceByOwner() Export
	
	Result = NewPermissionsSlice();
	
	Result.Columns.Add("OwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.Columns.Add("OwnerID", New TypeDescription("UUID"));
	
	Return Result;
	
EndFunction

// Returns the current slice of granted permissions.
//
// Parameters:
//  ByOwners - Boolean - if True, the return table will contain information on permission owners.
//    Otherwise, the current slice will be collapsed by owner.
//  NoDetails1 - Boolean - If True, the slice is returned with its permissions having the Description field cleared.
//
// Returns:
//   ValueTable:
//   * ProgramModuleType - CatalogRef.MetadataObjectIDs
//   * ModuleID - UUID
//   * OwnerType - CatalogRef.MetadataObjectIDs
//   * OwnerID - UUID
//   * Type - String - an XDTO type name describing permissions.
//   * Permissions - Map of KeyAndValue:
//       ** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//       ** Value - XDTODataObject - XDTO permission details.
//   * PermissionsAdditions - Map of KeyAndValue - permission addition details:
//       ** Key - See InformationRegister.PermissionsToUseExternalResources.PermissionKey
//       ** Value - See InformationRegister.PermissionsToUseExternalResources.PermissionAddition
//
Function PermissionsSlice(Val ByOwners = True, Val NoDetails1 = False) Export
	
	Result = ?(ByOwners, NewPermissionsSliceByOwner(), NewPermissionsSlice());

	Selection = Select();
	
	While Selection.Next() Do
		
		Resolution = Common.XDTODataObjectFromXMLString(Selection.PermissionBody);
		
		FilterByTable = New Structure();
		FilterByTable.Insert("ProgramModuleType", Selection.ProgramModuleType);
		FilterByTable.Insert("ModuleID", Selection.ModuleID);
		If ByOwners Then
			FilterByTable.Insert("OwnerType", Selection.OwnerType);
			FilterByTable.Insert("OwnerID", Selection.OwnerID);
		EndIf;
		FilterByTable.Insert("Type", Resolution.Type().Name);
		
		String = DataProcessors.ExternalResourcesPermissionsSetup.PermissionsTableRow(
			Result, FilterByTable);
		
		PermissionBody = Selection.PermissionBody;
		PermissionKey = Selection.PermissionKey;
		PermissionAddition = Selection.PermissionAddition;
		
		If NoDetails1 Then
			
			If ValueIsFilled(Resolution.Description) Then
				
				Resolution.Description = "";
				PermissionBody = Common.XDTODataObjectToXMLString(Resolution);
				PermissionKey = PermissionKey(Resolution);
				
			EndIf;
			
		EndIf;
		
		String.Permissions.Insert(PermissionKey, PermissionBody);
		
		If ValueIsFilled(PermissionAddition) Then
			String.PermissionsAdditions.Insert(PermissionKey, PermissionAddition);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Writes a permission to the register.
//
// Parameters:
//  ProgramModuleType - CatalogRef.MetadataObjectIDs,
//  ModuleID - UUID,
//  OwnerType - CatalogRef.MetadataObjectIDs,
//  OwnerID - UUID,
//  PermissionKey - String - a permission key,
//  Resolution - XDTODataObject - XDTO permission presentation,
//  PermissionAddition - Arbitrary (serialized to XDTO).
//
Procedure AddPermission(Val ProgramModuleType, Val ModuleID, Val OwnerType, Val OwnerID, Val PermissionKey, Val Resolution, Val PermissionAddition = Undefined) Export
	
	Manager = CreateRecordManager();
	Manager.ProgramModuleType = ProgramModuleType;
	Manager.ModuleID = ModuleID;
	Manager.OwnerType = OwnerType;
	Manager.OwnerID = OwnerID;
	Manager.PermissionKey = PermissionKey;
	
	Manager.Read();
	
	If Manager.Selected() Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã tồn tại quyền được phép bổ sung:
				|%1, %2, %3, %4, %5.';
				|ru = 'Добавляемое разрешение уже существует:
				|%1, %2, %3, %4, %5.';
				|en = 'The extension to be added already exists:
				|%1, %2, %3, %4, %5.'; fa = 'The extension to be added already exists:
				|%1, %2, %3, %4, %5.';
				|it = 'L''estensione da aggiungere esiste già:
				|%1, %2, %3, %4, %5.';
				|pl = 'Dodawane zezwolenie już istnieje:
				|%1, %2, %3, %4, %5.';
				|tr = 'Eklenen uzantı artık mevcut:
				|%1, %2, %3, %4, %5.'"),
			String(ProgramModuleType),
			String(ModuleID),
			String(OwnerType),
			String(OwnerID),
			PermissionKey);
		
	Else
		
		Manager.ProgramModuleType = ProgramModuleType;
		Manager.ModuleID = ModuleID;
		Manager.OwnerType = OwnerType;
		Manager.OwnerID = OwnerID;
		Manager.PermissionKey = PermissionKey;
		Manager.PermissionBody = Common.XDTODataObjectToXMLString(Resolution);
		
		If ValueIsFilled(PermissionAddition) Then
			Manager.PermissionAddition = Common.ValueToXMLString(PermissionAddition);
		EndIf;
		
		Manager.Write(False);
		
	EndIf;
	
EndProcedure

// Deletes the permission from the register.
//
// Parameters:
//  ProgramModuleType - CatalogRef.MetadataObjectIDs,
//  ModuleID - UUID,
//  OwnerType - CatalogRef.MetadataObjectIDs,
//  OwnerID - UUID,
//  PermissionKey - String - a permission key,
//  Resolution - XDTODataObject - XDTO permission presentation.
//
Procedure DeletePermission(Val ProgramModuleType, Val ModuleID, Val OwnerType, Val OwnerID, Val PermissionKey, Val Resolution) Export
	
	Manager = CreateRecordManager();
	Manager.ProgramModuleType = ProgramModuleType;
	Manager.ModuleID = ModuleID;
	Manager.OwnerType = OwnerType;
	Manager.OwnerID = OwnerID;
	Manager.PermissionKey = PermissionKey;
	
	Manager.Read();
	
	If Manager.Selected() Then
		
		If Manager.PermissionBody <> Common.XDTODataObjectToXMLString(Resolution) Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Vị trí cho phép theo khóa:
	                  |%1, %2, %3, %4, %5.';
	                  |ru = 'Позиция разрешений по ключам:
	                  |%1, %2, %3, %4, %5.';
	                  |en = 'Position of permissions by keys:
	                  |%1, %2, %3, %4, %5.'; fa = 'Position of permissions by keys:
	                  |%1, %2, %3, %4, %5.';
	                  |it = 'Posizione delle estensioni per chiavi:
	                  |%1, %2, %3, %4, %5.';
	                  |pl = 'Pozycja zezwoleń według kluczy:
	                  |%1, %2, %3, %4, %5.';
	                  |tr = 'Anahtar izinlerinin konumu:
	                  |%1, %2, %3, %4, %5.'"),
				String(ProgramModuleType),
				String(ModuleID),
				String(OwnerType),
				String(OwnerID),
				PermissionKey);
				
		EndIf;
		
		Manager.Delete();
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thử xóa quyền được phép không tồn tại:
                  |%1, %2, %3, %4, %5.';
                  |ru = 'Попытка удаления несуществующего разрешения:
                  |%1, %2, %3, %4, %5.';
                  |en = 'Attempt to delete an extension that does not exist:
                  |%1, %2, %3, %4, %5.'; fa = 'Attempt to delete an extension that does not exist:
                  |%1, %2, %3, %4, %5.';
                  |it = 'Tentativo di eliminazione dell''estensione inesistente:
                  |%1, %2, %3, %4, %5.';
                  |pl = 'Próba usunięcie nieistniejącego zezwolenia:
                  |%1, %2, %3, %4, %5.';
                  |tr = 'Var olmayan izni kaldırma girişimi:
                  |%1, %2, %3, %4, %5.'"),
			String(ProgramModuleType),
			String(ModuleID),
			String(OwnerType),
			String(OwnerID),
			PermissionKey);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf


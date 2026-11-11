////////////////////////////////////////////////////////////////////////////////
// Subsystem "Basic functionality in the service model".
// General-purpose server procedures and functions:
// - Support for security profiles.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Fills the structure with arrays of supported versions of all subsystems to be versioned,
// using the names of subsystems as keys.
// Provides the functionality of the InterfaceVersion Web service.
// During implementation, it is necessary to change the body of the procedure so that it returns the current version sets (see example below).
//
// Parameters:
// SupportedVersionsStructure - Structure - where:
//  the Keys are the names of subsystems, 
//  Values are arrays of names of supported versions.
//
// Example:
//
//	Servertransmission of files
//	Version Array = New Array;
//	Array of versions.Add("1.0.1.1");	
//	Array of versions.Add("1.0.2.1"); 
//	Structure of supported versions.Insert("Servertransmission of files", array of versions);
//	End of servertransmission of files
//
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
	
	If SafeModeManagerInternal.SecurityProfilesUsageAvailable() Then
		VersionsArray = New Array;
		VersionsArray.Add("1.0.0.2");
		SupportedVersionsStructure.Insert("SecurityProfileCompatibilityMode", VersionsArray);
	EndIf;
	
EndProcedure

// Called when checking whether security profiles can be configured
//
// Parameters:
//  Cancel - Boolean - If the use of security profiles is not available for the information base
//    , the value of this parameter should be set to True.
//
Procedure OnCheckCanSetupSecurityProfiles(Cancel) Export
	
	If Common.DataSeparationEnabled() Then
		
		// In the service model, the configuration of security profiles is managed centrally
		// from the service manager.
		Cancel = True;
		
	EndIf;
	
EndProcedure

// Called when creating a request for permissions to use external resources.
//
// Parameters:
//  ProgramModule - AnyRef - a reference to an information database object that represents the software
//    module that is being requested for permissions,
//  Owner - AnyRef - reference to an information database object that represents the owner of the requested
//    permissions to use external resources,
//  Var_ReplacementMode - Boolean - flag for replacing previously granted permissions by owner,
//  PermissionsToAdd - Array of XDTODataObject - array of permissions to add,
//  PermissionsToDelete - Array of XDTODataObject - array of permissions to delete,
//  StandardProcessing - Boolean - flag for performing standard processing for creating a request to use
//    external resources.
//  Result - UUID - the ID of the request (in that case, if inside the handler
//    the value of the standard Processing parameter is set to False).
//
Procedure OnRequestPermissionsToUseExternalResources(Val ProgramModule, Val Owner, Val Var_ReplacementMode, 
	Val PermissionsToAdd, Val PermissionsToDelete, StandardProcessing, Result) Export
	
	If Common.DataSeparationEnabled() Then
		
		StandardProcessing = False;
		
		If ProgramModule = Undefined Then
			ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef();
		EndIf;
		
		If Owner = Undefined Then
			Owner = ProgramModule;
		EndIf;
		
		If GetFunctionalOption("UseSecurityProfiles") Then
			
			If Common.SeparatedDataUsageAvailable() Then
				
				RequestRegister = InformationRegisters.RequestPermissionsToAccessExternalResourcesForDataAreas;
				
			Else
				
				RequestRegister = InformationRegisters.RequestPermissionsToAccessExternalResourcesSaaS;
				
			EndIf;
			
			PermissionsRequest = RequestRegister.CreateRecordManager();
			
			PermissionsRequest.QueryID = New UUID;
			
			If SafeModeManager.SafeModeSet() Then
				PermissionsRequest.SafeMode = SafeMode();
			Else
				PermissionsRequest.SafeMode = False;
			EndIf;
			
			SoftwareModuleKey = RegisterKeyByReference(ProgramModule);
			PermissionsRequest.ProgramModuleType = SoftwareModuleKey.Type;
			PermissionsRequest.ModuleID = SoftwareModuleKey.Id;
			
			OwnerSKey = RegisterKeyByReference(Owner);
			PermissionsRequest.OwnerType = OwnerSKey.Type;
			PermissionsRequest.OwnerID = OwnerSKey.Id;
			
			PermissionsRequest.ReplacementMode = Var_ReplacementMode;
			
			If PermissionsToAdd <> Undefined Then
				
				PermissionsArray = New Array();
				For Each NewPermission In PermissionsToAdd Do
					PermissionsArray.Add(Common.XDTODataObjectToXMLString(NewPermission));
				EndDo;
				
				If PermissionsArray.Count() > 0 Then
					PermissionsRequest.PermissionsToAdd = Common.ValueToXMLString(PermissionsArray);
				EndIf;
				
			EndIf;
			
			If PermissionsToDelete <> Undefined Then
				
				PermissionsArray = New Array();
				For Each PermissionToRevoke In PermissionsToDelete Do
					PermissionsArray.Add(Common.XDTODataObjectToXMLString(PermissionToRevoke));
				EndDo;
				
				If PermissionsArray.Count() > 0 Then
					PermissionsRequest.PermissionsToDelete = Common.ValueToXMLString(PermissionsArray);
				EndIf;
				
			EndIf;
			
			PermissionsRequest.Write();
			
			Result = PermissionsRequest.QueryID;
			
		Else
			
			Result = New UUID();
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Called when requesting the creation of a security profile.
//
// Parameters:
//  ProgramModule - AnyRef - a reference to an information database object that represents the software
//    module that is being requested for permissions,
//  StandardProcessing - Boolean - flag for performing standard processing,
//  Result - UUID - the ID of the request (in that case, if inside the handler
//    the value of the standard Processing parameter is set to False).
//
Procedure OnRequestToCreateSecurityProfile(Val ProgramModule, StandardProcessing, Result) Export
	
	WhenRequestingChangesToSecurityProfiles(ProgramModule, StandardProcessing, Result);
	
EndProcedure

// Called when requesting the creation of a security profile.
//
// Parameters:
//  ProgramModule - AnyRef - a reference to an information database object that represents the software
//    module that is being requested for permissions,
//  StandardProcessing - Boolean - flag for performing standard processing,
//  Result - UUID - the ID of the request (in that case, if inside the handler
//    the value of the standard Processing parameter is set to False).
//
Procedure OnRequestToDeleteSecurityProfile(Val ProgramModule, StandardProcessing, Result) Export
	
	WhenRequestingChangesToSecurityProfiles(ProgramModule, StandardProcessing, Result);
	
EndProcedure

// Called when an external module is connected. In the body of the handler procedure, you can change
// the safe mode in which the connection will be performed.
//
// Parameters:
//  ExternalModule - AnyRef - reference to the information base object that represents
//    the external plug-in,
//  SafeMode - DefinedType.SafeMode - safe mode in which the external
//    module will be connected to the information database. Can be changed within this procedure.
//
Procedure OnAttachExternalModule(Val ExternalModule, SafeMode) Export
	
	If Common.DataSeparationEnabled() Then
		
		SafeMode = SafeModeManagerSaaS.ExternalModuleExecutionMode(ExternalModule);
		
	EndIf;
	
EndProcedure

// Generates a list of information security parameters.
//
// Parameters:
// ParametersTable - ValueTable - parameter description table.
// The description of the composition of the columns is See SaaSOperations.
//                                       ().
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "UseSecurityProfiles");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, 
		"InfobaseSecurityProfile");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, 
		"AutomaticallyConfigurePermissionsInSecurityProfiles");
	
EndProcedure

// Fills the passed array with General modules that are handlers
//  for the received message interfaces.
//
// Parameters:
//  HandlersArray - Array - handlers.
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
	
	HandlersArray.Add(MessagesPermissionsManagementControlInterface);
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Constants.MasterApplicationExternalAddress);
	
	Types.Add(Metadata.InformationRegisters.RequestPermissionsToAccessExternalResourcesSaaS);
	Types.Add(Metadata.InformationRegisters.RequestPermissionsToAccessExternalResourcesForDataAreas);
	
	Types.Add(Metadata.InformationRegisters.PermissionsToUseExternalResourcesSaaS);
	Types.Add(Metadata.InformationRegisters.PermissionsToUseExternalResourcesForDataAreas);
	
	Types.Add(Metadata.InformationRegisters.ExternalModulesConnectionOptionsSaaS);
	Types.Add(Metadata.InformationRegisters.DataAreaExternalModulesAttachmentModes);
	
	Types.Add(Metadata.InformationRegisters.ApplyPermissionsToUseExternalResourcesSaaS);
	Types.Add(Metadata.InformationRegisters.ApplyPermissionsToUseExternalResourcesForDataAreas);
	
EndProcedure

// Parameters:
// 	Ref - CatalogRef.MetadataObjectIDs - 
// 	
// Returns:
// 	Structure - LongDesc:
// * Type - CatalogRef.MetadataObjectIDs - IOM 
// * Id - UUID - 
// 
Function RegisterKeyByReference(Val Ref) Export
	
	Result = New Structure("Type,Id");
	
	If Ref = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Result.Type = Catalogs.MetadataObjectIDs.EmptyRef();
		Result.Id = New UUID("00000000-0000-0000-0000-000000000000");
		
	Else
		
		Result.Type = Common.MetadataObjectID(Ref.Metadata());
		Result.Id = Ref.UUID();
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters: 
//  Type - CatalogRef.MetadataObjectIDs
//  Id - UUID
// 
// Returns: 
//  AnyRef - link by register key.
Function ReferenceByRegisterKey(Val Type, Val Id) Export
	
	If Type = Catalogs.MetadataObjectIDs.EmptyRef() Then
		Return Type;
	Else
		
		MetadataObject = Common.MetadataObjectByID(Type);
		Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		
		Return Manager.GetRef(Id);
		
	EndIf;
	
EndFunction

// Generates a permission key (for use in registers that store information about
// granted permissions).
//
// Parameters:
//  Resolution - XDTODataObject -
//
// Returns:
//   String - key.
//
Function PermissionKey(Val Resolution) Export
	
	Hashing = New DataHashing(HashFunction.MD5);
	Hashing.Append(Common.XDTODataObjectToXMLString(Resolution));
	
	Var_Key = XDTOFactory.Create(XDTOFactory.Type("http://www.w3.org/2001/XMLSchema", "hexBinary"), 
		Hashing.HashSum).LexicalValue;
	
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

// Returns the row in the permission table that corresponds to the selection.
// If there are no rows in the table that match the selection, a new one can be added.
// If there is more than one row in the table that matches the selection, an exception is thrown.
//
// Parameters:
//  PermissionsTable - ValueTable - 
//  Filter - Structure - 
//  AddIfAbsent - Boolean - 
//
// Returns:
//   ValueTableRow, Undefined - 
//
Function PermissionsTableRow(Val PermissionsTable, Val Filter, Val AddIfAbsent = True) Export
	
	Rows = PermissionsTable.FindRows(Filter);
	
	If Rows.Count() = 0 Then
		
		If AddIfAbsent Then
			
			String = PermissionsTable.Add();
			FillPropertyValues(String, Filter);
			Return String;
			
		Else
			
			Return Undefined;
			
		EndIf;
		
	ElsIf Rows.Count() = 1 Then
		
		Return Rows.Get(0);
		
	Else
		
		Raise StrTemplate(NStr("vi = 'Vi phạm tính đơn trị của dòng trong bảng cho phép theo bộ lọc %1';
								|ru = 'Нарушение уникальности строк в таблице разрешений по отбору %1';
								|en = 'Row uniqueness violation in permission table filtered by %1'; fa = 'Row uniqueness violation in permission table filtered by %1';
								|it = 'Violazione dell''originalità delle righe nella tabella delle autorizzazioni relativa alla selezione %1';
								|pl = 'Naruszenie wyjątkowości wierszy w tabeli uprawnień wyboru %1';
								|tr = 'Seçimle izinler tablosundaki satır benzersizliğinin ihlali %1'"),
			Common.ValueToXMLString(Filter));
		
	EndIf;
	
EndFunction

// Sets an exclusive managed lock on the tables of all registers used
// to store the list of granted permissions.
//
// Parameters:
//  ProgramModule - AnyRef - a reference to a directory element corresponding to an external module
//    that you want to clear information about previously granted permissions for. If the parameter value is not set
//    , information about granted permissions for all external modules will be blocked.
// BlockConnectionModesOfExternalModules - Boolean - flag for additional blocking
//    of external module connection modes.
//
Procedure LockRegistersOfGrantedPermissions(Val ProgramModule = Undefined, 
	Val BlockConnectionModesOfExternalModules = True) Export
	
	If Not TransactionActive() Then
		Raise NStr("vi = 'Giao tác chưa được kích hoạt';
					|ru = 'Транзакция не активна';
					|en = 'Transaction is not active'; fa = 'Transaction is not active';
					|it = 'Transazione non è attiva';
					|pl = 'Transakcja nie jest aktywna';
					|tr = 'İşem aktif değil'");
	EndIf;
	
	Registers = New Array();
	
	If Common.SeparatedDataUsageAvailable() Then
		
		Registers.Add(InformationRegisters.PermissionsToUseExternalResourcesForDataAreas);
		
		If BlockConnectionModesOfExternalModules Then
			Registers.Add(InformationRegisters.ExternalModulesConnectionOptionsSaaS);
		EndIf;
		
	Else
		
		Registers.Add(InformationRegisters.PermissionsToUseExternalResourcesForDataAreas);
		
		If BlockConnectionModesOfExternalModules Then
			Registers.Add(InformationRegisters.ExternalModulesConnectionOptionsSaaS);
		EndIf;
		
	EndIf;
	
	If ProgramModule <> Undefined Then
		Var_Key = RegisterKeyByReference(ProgramModule);
	EndIf;
	
	Block = New DataLock();
	
	For Each Register In Registers Do
		RegisterLock = Block.Add(Register.CreateRecordSet().Metadata().FullName());
		If ProgramModule <> Undefined Then
			RegisterLock.SetValue("ProgramModuleType", Var_Key.Type);
			RegisterLock.SetValue("ModuleID", Var_Key.Id);
		EndIf;
	EndDo;
	
	Block.Lock();
	
EndProcedure

// Returns the current slice of granted permissions.
//
// Parameters:
//  ByOwners - Boolean - if True , the returned table will contain information
//    about the owners of permissions, otherwise the current slice will be collapsed by the owner.
//  NoDetails1 - Boolean - if True, the slice will be returned with the cleared Description field for the permissions.
//
// Returns:
// ValueTable - Columns:
// * ProgramModuleType - CatalogRef.MetadataObjectIDs - 
// * ModuleID - UUID - 
// * OwnerType - CatalogRef.MetadataObjectIDs -
// * OwnerID - UUID - 
// * Type - String - name of the XDTO type that describes permissions,
// * Permissions - Map of KeyAndValue - description of permissions:
//   ** Key - String - resolution key (see the Resolution key function in the Register Manager module
//      Permission to use external resources).
//   ** Value - XDTODataObject - XDTO - description of the permission.
// * PermissionsAdditions - Map of KeyAndValue - description of permission extensions:
//   ** Key - String - resolution key (see the Resolution key function in the Register Manager module
//      Permission to use external resources).
//   ** Value - See InformationRegisters.PermissionsToUseExternalResources.PermissionAddition
//
Function PermissionsSlice(Val ByOwners = True, Val NoDetails1 = False) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.PermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.PermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Result = New ValueTable();
	
	Result.Columns.Add("ProgramModuleType", 
		New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.Columns.Add("ModuleID", New TypeDescription("UUID"));
	If ByOwners Then
		Result.Columns.Add("OwnerType", 
			New TypeDescription("CatalogRef.MetadataObjectIDs"));
		Result.Columns.Add("OwnerID", New TypeDescription("UUID"));
	EndIf;
	Result.Columns.Add("Type", New TypeDescription("String"));
	Result.Columns.Add("Permissions", New TypeDescription("Map"));
	
	Selection = Register.Select();
	
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
		
		String = PermissionsTableRow(Result, FilterByTable);
		
		PermissionBody = Selection.PermissionBody;
		PermissionKey = Selection.PermissionKey;
		
		If NoDetails1 Then
			
			If ValueIsFilled(Resolution.Description) Then
				
				Resolution.Description = "";
				PermissionBody = Common.XDTODataObjectToXMLString(Resolution);
				PermissionKey = PermissionKey(Resolution);
				
			EndIf;
			
		EndIf;
		
		String.Permissions.Insert(PermissionKey, PermissionBody);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Writes permission to the register.
//
// Parameters:
//  ProgramModuleType - CatalogRef.MetadataObjectIDs - 
//  ModuleID - UUID - 
//  OwnerType - CatalogRef.MetadataObjectIDs - 
//  OwnerID - UUID - 
//  PermissionKey - String - permission key
//  Resolution - XDTODataObject - XDTO-resolution representation
//  PermissionAddition - Arbitrary - serializable in XDTO.
//
Procedure AddPermission(Val ProgramModuleType, Val ModuleID, Val OwnerType, 
	Val OwnerID, Val PermissionKey, Val Resolution, Val PermissionAddition = Undefined) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.PermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.PermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.ProgramModuleType = ProgramModuleType;
	Manager.ModuleID = ModuleID;
	Manager.OwnerType = OwnerType;
	Manager.OwnerID = OwnerID;
	Manager.PermissionKey = PermissionKey;
	
	Manager.Read();
	
	If Manager.Selected() Then
		
		Raise StrTemplate("%1
                  |- ProgramModuleType: %2
                  |- ModuleID: %3
                  |- OwnerType: %4
                  |- OwnerID: %5
                  |- PermissionKey: %6.",
			NStr("vi = 'Trùng lặp quyền được phép theo các trường chính:';
				|ru = 'Дублирование разрешений по ключевым полям:';
				|en = 'Duplicate permissions by key fields:'; fa = 'Duplicate permissions by key fields:';
				|it = 'Duplicato delle posizioni per campi chiave:';
				|pl = 'Dublowanie zezwoleń według pól kluczowych:';
				|tr = 'Anahtar alanlarda tekrar eden izinler:'"),
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
		
		Manager.Write(False);
		
	EndIf;
	
EndProcedure

// Removes the permission from the register.
//
// Parameters:
//  ProgramModuleType - CatalogRef.MetadataObjectIDs - 
//  ModuleID - UUID -
//  OwnerType - CatalogRef.MetadataObjectIDs - 
//  OwnerID - UUID -
//  PermissionKey - String - permission key
//  Resolution - XDTODataObject - XDTO-representation of the resolution.
//
Procedure DeletePermission(Val ProgramModuleType, Val ModuleID, Val OwnerType, 
	Val OwnerID, Val PermissionKey, Val Resolution) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.PermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.PermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.ProgramModuleType = ProgramModuleType;
	Manager.ModuleID = ModuleID;
	Manager.OwnerType = OwnerType;
	Manager.OwnerID = OwnerID;
	Manager.PermissionKey = PermissionKey;
	
	Manager.Read();
	
	If Manager.Selected() Then
		
		If Manager.PermissionBody <> Common.XDTODataObjectToXMLString(Resolution) Then
			
			Raise StrTemplate("%1
	                  |- ProgramModuleType: %2
	                  |- ModuleID: %3
	                  |- OwnerType: %4
	                  |- OwnerID: %5
	                  |- PermissionKey: %6.",
				NStr("vi = 'Xung đột quyền được phép theo các trường:';
					|ru = 'Коллизия разрешений по ключам:';
					|en = 'Permission collision by keys:'; fa = 'Permission collision by keys:';
					|it = 'Collisione estensioni per chiavi:';
					|pl = 'Kolizja zezwoleń według kluczy:';
					|tr = 'Anahtar izinler çakışması:'"),
				String(ProgramModuleType),
				String(ModuleID),
				String(OwnerType),
				String(OwnerID),
				PermissionKey);
				
		EndIf;
		
		Manager.Delete();
		
	Else
		
		Raise StrTemplate("%1
                  |- ProgramModuleType: %2
                  |- ModuleID: %3
                  |- OwnerType: %4
                  |- OwnerID: %5
                  |- PermissionKey: %6.",
			NStr("vi = 'Thử xóa quyền cho phép không tồn tại:';
				|ru = 'Попытка удаления несуществующего разрешения:';
				|en = 'Attempt to delete a non-existing permission:'; fa = 'Attempt to delete a non-existing permission:';
				|it = 'Tentativo eliminazione estensione inesistente:';
				|pl = 'Próba usunięcia nieistniejącego zezwolenia:';
				|tr = 'Mevcut olmayan izini silme çabası'"),
			String(ProgramModuleType),
			String(ModuleID),
			String(OwnerType),
			String(OwnerID),
			PermissionKey);
		
	EndIf;
	
EndProcedure

// Delete requests for the use of external resources.
//
// Parameters:
//  RequestsIDs - Array of UUID - IDs of the requests to delete.
//
Procedure DeleteRequests(Val RequestsIDs) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesSaaS;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		For Each QueryID In RequestsIDs Do
			
			Manager = Register.CreateRecordManager();
			Manager.QueryID = QueryID;
			Manager.Delete();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Clears out-of-date requests to use external resources.
//
Procedure ClearObsoleteRequests() Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesSaaS;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Selection = Register.Select();
		
		While Selection.Next() Do
			
			Try
				
				Var_Key = Register.CreateRecordKey(New Structure("QueryID", Selection.QueryID));
				LockDataForEdit(Var_Key);
				
			Except
				
				// Exception handling is not required.
				// The expected exception is an attempt to delete the same register entry from another session.
				Continue;
				
			EndTry;
			
			Manager = Register.CreateRecordManager();
			Manager.QueryID = Selection.QueryID;
			Manager.Delete();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Creates and initializes the Manager for applying requests to use external resources.
//
// Parameters:
//  RequestsIDs - Array of UUID - IDs of requests
//   that the Manager is being created to apply.
//
// Returns:
//   DataProcessorObject.ExternalResourcesPermissionsSetup - manager.
//
Function PermissionsApplicationManager(Val RequestsIDs) Export
	
	Manager = DataProcessors.ExternalResourcesPermissionsSetupSaaS.Create();
	
	If Common.SeparatedDataUsageAvailable() Then
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.RequestPermissionsToAccessExternalResourcesSaaS;
	EndIf;
	
	QueryText =
		"SELECT
		|	Queries.ProgramModuleType,
		|	Queries.ModuleID,
		|	Queries.OwnerType,
		|	Queries.OwnerID,
		|	Queries.ReplacementMode,
		|	Queries.PermissionsToAdd,
		|	Queries.PermissionsToDelete,
		|	Queries.QueryID
		|FROM
		|	&Table AS Queries
		|WHERE
		|	Queries.QueryID IN(&RequestsIDs)";
	
	QueryText = StrReplace(QueryText, "&Table", Register.CreateRecordSet().Metadata().FullName());
	
	Query = New Query(QueryText);
	Query.SetParameter("RequestsIDs", RequestsIDs);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RecordKey = Register.CreateRecordKey(New Structure("QueryID", Selection.QueryID));
		LockDataForEdit(RecordKey);
		
		PermissionsToAdd = New Array();
		If ValueIsFilled(Selection.PermissionsToAdd) Then
			
			Array = Common.ValueFromXMLString(Selection.PermissionsToAdd);
			
			For Each ArrayElement In Array Do
				PermissionsToAdd.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
			
		EndIf;
		
		PermissionsToDelete = New Array();
		If ValueIsFilled(Selection.PermissionsToDelete) Then
			
			Array = Common.ValueFromXMLString(Selection.PermissionsToDelete);
			
			For Each ArrayElement In Array Do
				PermissionsToDelete.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
			
		EndIf;
		
		Manager.AddRequestID(Selection.QueryID);
		
		Manager.AddRequestForPermissionsToUseExternalResources(
			Selection.ProgramModuleType,
			Selection.ModuleID,
			Selection.OwnerType,
			Selection.OwnerID,
			Selection.ReplacementMode,
			PermissionsToAdd,
			PermissionsToDelete);
		
	EndDo;
	
	Manager.CalculateRequestsApplication();
	
	Return Manager;
	
EndFunction

// ID of the batch of requests being applied
// 
// Parameters: 
//  State - String - xml string
// 
// Returns:
//  UUID
Function PackageOfAppliedRequests(Val State) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.IDOfPackage = New UUID();
	Manager.State = State;
	
	Manager.Write();
	
	Return Manager.IDOfPackage;
	
EndFunction

// Parameters: 
//  IDOfPackage - String
// 
// Returns: 
//  EnumRef.ExternalResourcesUsageQueriesProcessingResultsSaaS
Function PackageProcessingResult(Val IDOfPackage) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.IDOfPackage = New UUID();
	Manager.Read();
	
	If Manager.Selected() Then
		
		Return Manager.Result;
		
	Else
		
		Raise StrTemplate(
			NStr("vi = 'Không tìm thấy gói yêu cầu %1';
				|ru = 'Не найден пакет запросов %1';
				|en = 'Query pack %1 is not found'; fa = 'Query pack %1 is not found';
				|it = 'Il pacchetto richieste %1 non è stato trovato';
				|pl = 'Nie znaleziono pakietu żądania %1';
				|tr = '%1 sorgu paketi bulunamadı '"), IDOfPackage);
		
	EndIf;
	
EndFunction

Procedure SetResultOfPacketProcessing(Val Result) Export
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.IDOfPackage = New UUID();
	Manager.Result = Result;
	Manager.Write();
	
EndProcedure

// Package application Manager
// 
// Parameters: 
//  IDOfPackage - UUID
// 
// Returns: 
//  DataProcessorObject.ExternalResourcesPermissionsSetupSaaS
Function PackageApplicationManager (Val IDOfPackage) Export
	
	Manager = DataProcessors.ExternalResourcesPermissionsSetupSaaS.Create();
	Manager.ReadStateFromXMLString(StateOfPacketProcessing(IDOfPackage));
	
	Return Manager;
	
EndFunction

// Serializes requests to use external resources to send to the service Manager.
//
// Parameters:
//  RequestsIDs - Array of UUID - request IDs.
//
// Returns:
//	XDTODataObject - {http://www.1c.ru/1cFresh/Application/Permissions/Management/a.b.c.d}PermissionsRequestsList.
//
Function SerializeRequestsForExternalResources(Val RequestsIDs) Export
	
	Envelope = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), "PermissionsRequestsList"));
	
	QueryText =
		"SELECT
		|	Queries.ProgramModuleType,
		|	Queries.ModuleID,
		|	Queries.OwnerType,
		|	Queries.OwnerID,
		|	Queries.ReplacementMode,
		|	Queries.PermissionsToAdd,
		|	Queries.PermissionsToDelete
		|FROM
		|	&Table AS Queries
		|WHERE
		|	Queries.QueryID IN(&RequestsIDs)";
	
	If SaaSOperations.SeparatedDataUsageAvailable() Then
		
		QueryText = StrReplace(QueryText, "&Table", 
			"InformationRegister.RequestPermissionsToAccessExternalResourcesForDataAreas");
		
	Else
		
		QueryText = StrReplace(QueryText, "&Table", 
			"InformationRegister.RequestPermissionsToAccessExternalResourcesSaaS");
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("RequestsIDs", RequestsIDs);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		PermissionsRequest = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), "PermissionsRequest"));
		
		PermissionsRequest.UUID = Selection.QueryID;
		
		ProgramModule = ReferenceByRegisterKey(Selection.ProgramModuleType, Selection.ModuleID);
		Owner = ReferenceByRegisterKey(Selection.OwnerType, Selection.OwnerID);
		
		SoftwareModulePresentation = Undefined;
		OwnerPresentation = Undefined;
		
		StandardProcessing = True;
		
		If Common.SubsystemExists(
			"StandardSubsystems.SaaSOperations.AdditionalReportsAndDataProcessorsSaaS") Then
			
			ModuleAdditionalReportsAndDataProcessorsSaaS = 
				Common.CommonModule("AdditionalReportsAndDataProcessorsSaaS");
			ModuleAdditionalReportsAndDataProcessorsSaaS.OnSerializeExternalResourceUsagePermissionsOwner(
				Owner, StandardProcessing, OwnerPresentation);
			
		EndIf;
		
		If StandardProcessing Then
			
			If ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef() Then
				
				SoftwareModulePresentation = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), 
					"PermissionModuleApplication"));
				
			Else
				
				Raise StrTemplate(
					NStr("vi = 'Mô-đun chương trình không được tuần tự hóa bằng khóa:
                          |- Тип: %1
                          |- Идентификатор: %2';
                          |ru = 'Не сериализован программный модуль по ключу:
                          |- Тип: %1
                          |- Идентификатор: %2';
                          |en = 'Unserialized key program module:
                          |- Type: %1
                          |- ID: %2'; fa = 'Unserialized key program module:
                          |- Type: %1
                          |- ID: %2';
                          |it = 'Il modulo software non è serializzato per la chiave: 
                          |- Tipo: %1
                          |- Identificatore: %2';
                          |pl = 'Moduł oprogramowania nie został spersonalizowany według klucza:
                          |- Typ:%1
                          |- Identyfikator %2:';
                          |tr = 'Program modülü anahtarla seri hale getirilmedi:
                          |- Tür: %1
                          |- Kimlik: %2'"),
					Selection.ProgramModuleType,
					Selection.ModuleID);
				
			EndIf;
			
			If Owner = Catalogs.MetadataObjectIDs.EmptyRef() Then
				
				OwnerPresentation = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), 
					"PermissionsOwnerApplication"));
				
			Else
				
				OwnerPresentation = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), 
					"PermissionsOwnerApplicationObject"));
				OwnerPresentation.Type = Selection.Owner.Metadata().FullName();
				OwnerPresentation.UUID = Selection.Owner.UUID();
				OwnerPresentation.Description = String(Selection.Owner);
				
			EndIf;
			
		EndIf;
		
		PermissionsRequest.Module = SoftwareModulePresentation;
		PermissionsRequest.Owner = OwnerPresentation;
		
		PermissionsToAdd = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), "PermissionsList"));
		If Not IsBlankString(Selection.PermissionsToAdd) Then
			PermissionsArray = Common.ValueFromXMLString(Selection.PermissionsToAdd);
			For Each ArrayElement In PermissionsArray Do
				PermissionsList = PermissionsToAdd.Permission; // XDTOList
				PermissionsList.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
		EndIf;
		PermissionsRequest.GrantPermissions = PermissionsToAdd;
		
		PermissionsToDelete = XDTOFactory.Create(XDTOFactory.Type(PackageAdministrationOfPermissions(), "PermissionsList"));
		If Not IsBlankString(Selection.PermissionsToDelete) Then
			PermissionsArray = Common.ValueFromXMLString(Selection.PermissionsToDelete);
			For Each ArrayElement In PermissionsArray Do
				PermissionsList = PermissionsToDelete.Permission; // XDTOList
				PermissionsList.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
		EndIf;
		PermissionsRequest.CancelPermissions = PermissionsToDelete;
		
		PermissionsRequest.ReplaceOwnerPermissions = Selection.ReplacementMode;
		
		ListOfRequests = Envelope.Request; // XDTOList
		ListOfRequests.Add(PermissionsRequest);
		
	EndDo;
	
	Return Envelope;
	
EndFunction

// The Permissions administration package.
// 
// Returns:
//  String
Function PackageAdministrationOfPermissions() Export
	
	Return "http://www.1c.ru/1cFresh/Application/Permissions/Management/1.0.0.1";
	
EndFunction

#EndRegion

#Region Private

Function StateOfPacketProcessing(Val IDOfPackage)
	
	If Common.DataSeparationEnabled() Then
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesForDataAreas;
	Else
		Register = InformationRegisters.ApplyPermissionsToUseExternalResourcesSaaS;
	EndIf;
	
	Manager = Register.CreateRecordManager();
	Manager.IDOfPackage = New UUID();
	Manager.Read();
	
	If Manager.Selected() Then
		
		Return Manager.State;
		
	Else
		
		Raise StrTemplate(NStr("vi = 'Không tìm thấy gói yêu cầu %1';
								|ru = 'Не найден пакет запросов %1';
								|en = 'Query pack %1 is not found'; fa = 'Query pack %1 is not found';
								|it = 'Il pacchetto richieste %1 non è stato trovato';
								|pl = 'Nie znaleziono pakietu żądania %1';
								|tr = '%1 sorgu paketi bulunamadı '"), IDOfPackage);
		
	EndIf;
	
EndFunction

Procedure WhenRequestingChangesToSecurityProfiles(Val ProgramModule, StandardProcessing, Result)
	
	If Common.DataSeparationEnabled() Then
		
		StandardProcessing = False;
		Result  = New UUID();
		
	EndIf;
	
EndProcedure

#EndRegion
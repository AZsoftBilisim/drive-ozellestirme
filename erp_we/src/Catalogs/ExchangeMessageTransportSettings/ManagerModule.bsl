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

Procedure UpdateSettings2(SettingsStructure) Export
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.ExchangeMessageTransportSettings");
		LockItem.SetValue("Peer", SettingsStructure.Peer);
		LockItem.SetValue("TransportID", SettingsStructure.TransportID);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	TransportSettings.Ref AS Ref
			|FROM
			|	Catalog.ExchangeMessageTransportSettings AS TransportSettings
			|WHERE
			|	TransportSettings.Peer = &Peer
			|	AND TransportSettings.TransportID = &TransportID";
			
		Query.SetParameter("Peer", SettingsStructure.Peer);
		Query.SetParameter("TransportID", SettingsStructure.TransportID);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			Object = Selection.Ref.GetObject();
		Else
			Object = Catalogs.ExchangeMessageTransportSettings.CreateItem();
		EndIf;
		
		FillPropertyValues(Object, SettingsStructure, , "Settings");
		
		Object.Settings.Clear();
		
		For Each KeyAndValue In SettingsStructure.Settings Do
			
			NewRow = Object.Settings.Add();
			NewRow.Setting = KeyAndValue.Key;
			NewRow.Value = KeyAndValue.Value;
			
		EndDo;
		
		Object.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
	
	EndTry;
	
EndProcedure

Procedure DeleteAllSettings(Peer) Export

	TypeOfCorrespondent = TypeOf(Peer);
	If Not Metadata.DefinedTypes.ExchangePlansDSL.Type.ContainsType(TypeOfCorrespondent) Then
		Return;
	EndIf;

	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.ExchangeMessageTransportSettings");
		LockItem.SetValue("Peer", Peer);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
	
		Query = New Query;
		Query.Text =
			"SELECT
			|	TransportSettings.Ref AS Ref,
			|	TransportSettings.TransportID AS TransportID,
			|	TransportSettings.Settings.(
			|		Setting AS Setting,
			|		Value AS Value
			|	) AS Settings
			|FROM
			|	Catalog.ExchangeMessageTransportSettings AS TransportSettings
			|WHERE
			|	TransportSettings.Peer = &Peer";
			
		Query.SetParameter("Peer", Peer);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			AttributesForSecureStorage = ExchangeMessagesTransport.TransportParameter(
				Selection.TransportID, "AttributesForSecureStorage");
				
			If AttributesForSecureStorage.Count() > 0 Then
				
				SelectionBySettings = Selection.Settings.Select();
				
				While SelectionBySettings.Next() Do
					
					If AttributesForSecureStorage.Find(SelectionBySettings.Setting) <> Undefined 
						And ValueIsFilled(SelectionBySettings.Value) Then
						Common.DeleteDataFromSecureStorage(SelectionBySettings.Value);
					EndIf;
					
				EndDo;
				
			EndIf;
				
			Object = Selection.Ref.GetObject();
			Object.Delete();
		
		EndDo;
	
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		Raise;
	
	EndTry;
		
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	Selection = SavedTransportSettings();
	
	While Selection.Next() Do
		
		QueryOptions = RequiestToUseExternalResourcesParameters();
		RequestToUseExternalResources(PermissionsRequests, Selection, QueryOptions);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Function DefaultTransport(Peer) Export
	
	SetPrivilegedMode(True);
	
	// Function return value.
	TransportID = Undefined;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TransportSettings.TransportID AS TransportID
		|FROM
		|	Catalog.ExchangeMessageTransportSettings AS TransportSettings
		|WHERE
		|	TransportSettings.Peer = &Peer
		|	AND TransportSettings.DefaultSetting";
	
	Query.SetParameter("Peer", Peer);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		TransportID = Selection.TransportID;
	EndIf;
	
	Return TransportID;
	
EndFunction

Function TransportSettings(Peer, TransportID) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Settings.Setting AS Setting,
		|	Settings.Value AS Value
		|FROM
		|	Catalog.ExchangeMessageTransportSettings.Settings AS Settings
		|WHERE
		|	Settings.Ref.Peer = &Peer
		|	AND Settings.Ref.TransportID = &TransportID";
	
	Query.SetParameter("Peer", Peer);
	Query.SetParameter("TransportID", TransportID);
	
	QueryResult = Query.Execute();
	
	TransportSettings = New Structure;
	
	If QueryResult.IsEmpty() Then
		Return TransportSettings;
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		TransportSettings.Insert(Selection.Setting, Selection.Value);
	EndDo;
		
	Return TransportSettings;
	
EndFunction

Function DefaultTransportSettings(Peer, TransportID = "") Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	TransportSettings.TransportID AS TransportID,
		|	TransportSettings.Settings.(
		|		Setting AS Setting,
		|		Value AS Value
		|	) AS Settings
		|FROM
		|	Catalog.ExchangeMessageTransportSettings AS TransportSettings
		|WHERE
		|	TransportSettings.Peer = &Peer
		|	AND TransportSettings.DefaultSetting";
	
	Query.SetParameter("Peer", Peer);
	
	QueryResult = Query.Execute();
	
	TransportSettings = New Structure;
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		TransportID = Selection.TransportID;
		
		SelectionBySettings = Selection.Settings.Select();
		
		While SelectionBySettings.Next() Do
			TransportSettings.Insert(SelectionBySettings.Setting, SelectionBySettings.Value);
		EndDo;
		
	EndDo;
		
	Return TransportSettings;
	
EndFunction

Function ConfiguredTransportTypes(Peer) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	TransportSettings.TransportID AS TransportID
		|FROM
		|	Catalog.ExchangeMessageTransportSettings AS TransportSettings
		|WHERE
		|	TransportSettings.Peer = &Peer";
	
	Query.SetParameter("Peer", Peer);
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure AssignDefaultTransport(Peer, TransportID) Export
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.ExchangeMessageTransportSettings");
	LockItem.SetValue("Peer", Peer);
	LockItem.Mode = DataLockMode.Exclusive;
	
	BeginTransaction();
	
	Try
		
		Block.Lock();
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	TransportSettings.Ref AS Ref,
			|	TransportSettings.TransportID AS TransportID,
			|	TransportSettings.TransportID = &TransportID AS DefaultSetting
			|FROM
			|	Catalog.ExchangeMessageTransportSettings AS TransportSettings
			|WHERE
			|	TransportSettings.Peer = &Peer
			|	AND TransportSettings.DefaultSetting <> (TransportSettings.TransportID = &TransportID)";
		
		Query.SetParameter("Peer", Peer);
		Query.SetParameter("TransportID", TransportID);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			CatalogOfSettings = Selection.Ref.GetObject();
			CatalogOfSettings.DefaultSetting = Selection.DefaultSetting;
			CatalogOfSettings.Write();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
		
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion() Export

	BeginTransaction();
	
	Try
	
		Block = New DataLock;
		Block.Add("InformationRegister.DeleteDataExchangeTransportSettings");
		
		If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
			
			Block.Add("InformationRegister.DataAreaExchangeTransportSettings");
			
		EndIf;
		
		Block.Add("Catalog.DataExchangeScenarios");
		Block.Add("Catalog.ExchangeMessageTransportSettings");
		Block.Lock();
		
		TransferTransportSettings();
		
		If Common.DataSeparationEnabled()
			And Common.SeparatedDataUsageAvailable() Then
			
			TransferTransportSettingsOfServiceManager();
			
		EndIf;
		
		TransferTransportSettingsForExchangeScenarios();
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		Raise;
	
	EndTry;
	
EndProcedure

Procedure TransferTransportSettings()
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		Block.Add("Catalog.ExchangeMessageTransportSettings");
		Block.Lock();
	
		Set = InformationRegisters.DeleteDataExchangeTransportSettings.CreateRecordSet();
		Set.Read();
	
		For Each Record In Set Do
			
			If Not ValueIsFilled(Record.Peer)
				Or Record.Peer.GetObject() = Undefined Then
				
				// Skip settings with empty or broken links (to protect from corrupted data)
				Continue;
				
			EndIf;
			
			TransferTransportSettingsForRecording(Record)
			
		EndDo;
		
		Set.Clear();
		Set.Write();
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

Procedure TransferTransportSettingsForRecording(Record)
	
	Passwords = Common.ReadDataFromSecureStorage(Record.Peer,
		"COMUserPassword, FTPConnectionPassword, WSPassword, ArchivePasswordExchangeMessages");
	
	ConfiguredTransportKinds = ConfiguredTransportKinds(Record);
	
	For Each TransportKind In ConfiguredTransportKinds Do
		
		NewCatalog = Catalogs.ExchangeMessageTransportSettings.CreateItem();
		NewCatalog.Peer = Record.Peer;
		NewCatalog.DefaultSetting = (Record.DefaultExchangeMessagesTransportKind = TransportKind);
		NewCatalog.TransportID = Common.EnumerationValueName(TransportKind);
		Settings = NewCatalog.Settings;
	
		If TransportKind = Enums.ExchangeMessagesTransportTypes.EMAIL Then
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "MaxMessageSize";
			NewRow.Value = Record.EMAILMaxMessageSize;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "CompressOutgoingMessageFile";
			NewRow.Value = Record.EMAILCompressOutgoingMessageFile;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "Account";
			NewRow.Value = Record.EMAILAccount;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "Transliteration";
			NewRow.Value = Record.EMAILTransliterateExchangeMessageFileNames;
			
			If ValueIsFilled(Passwords.ArchivePasswordExchangeMessages) Then
				ArchivePasswordExchangeMessages = String(New UUID);
				Common.WriteDataToSecureStorage(ArchivePasswordExchangeMessages, Passwords.ArchivePasswordExchangeMessages);
				
				NewRow = NewCatalog.Settings.Add();
				NewRow.Setting = "ArchivePasswordExchangeMessages";
				NewRow.Value = ArchivePasswordExchangeMessages;
			EndIf;
	
		ElsIf TransportKind = Enums.ExchangeMessagesTransportTypes.FILE Then
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "DataExchangeDirectory";
			NewRow.Value = Record.FILEDataExchangeDirectory;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "CompressOutgoingMessageFile";
			NewRow.Value = Record.FILECompressOutgoingMessageFile;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "Transliteration";
			NewRow.Value = Record.FILETransliterateExchangeMessageFileNames;
			
			If ValueIsFilled(Passwords.ArchivePasswordExchangeMessages) Then
				ArchivePasswordExchangeMessages = String(New UUID);
				Common.WriteDataToSecureStorage(ArchivePasswordExchangeMessages, Passwords.ArchivePasswordExchangeMessages);
				
				NewRow = NewCatalog.Settings.Add();
				NewRow.Setting = "ArchivePasswordExchangeMessages";
				NewRow.Value = ArchivePasswordExchangeMessages;
			EndIf;
			
		ElsIf TransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "MaxMessageSize";
			NewRow.Value = Record.FTPConnectionMaxMessageSize;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "PassiveConnection";
			NewRow.Value = Record.FTPConnectionPassiveConnection;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "User";
			NewRow.Value = Record.FTPConnectionUser;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "Port";
			NewRow.Value = Record.FTPConnectionPort;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "Path";
			NewRow.Value = Record.FTPConnectionPath;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "CompressOutgoingMessageFile";
			NewRow.Value = Record.FTPCompressOutgoingMessageFile;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "Transliteration";
			NewRow.Value = Record.FTPTransliterateExchangeMessageFileNames;
			
			If ValueIsFilled(Passwords.ArchivePasswordExchangeMessages) Then
				ArchivePasswordExchangeMessages = String(New UUID);
				Common.WriteDataToSecureStorage(ArchivePasswordExchangeMessages, Passwords.ArchivePasswordExchangeMessages);
				
				NewRow = NewCatalog.Settings.Add();
				NewRow.Setting = "ArchivePasswordExchangeMessages";
				NewRow.Value = ArchivePasswordExchangeMessages;
			EndIf;
			
			If ValueIsFilled(Passwords.FTPConnectionPassword) Then
				Password = String(New UUID);
				Common.WriteDataToSecureStorage(Password, Passwords.FTPConnectionPassword);
				
				NewRow = NewCatalog.Settings.Add();
				NewRow.Setting = "Password";
				NewRow.Value = Password;
			EndIf;
			
		ElsIf TransportKind = Enums.ExchangeMessagesTransportTypes.WS Then
			
			If ValueIsFilled(Record.WSCorrespondentEndpoint) Then
				
				NewCatalog.TransportID = "SM";
				
				NewRow = NewCatalog.Settings.Add();
				NewRow.Setting = "InternalPublication";
				NewRow.Value = True;
				
				NewRow = NewCatalog.Settings.Add();
				NewRow.Setting = "CorrespondentEndpoint";
				NewRow.Value = Record.WSCorrespondentEndpoint;
				
				NewRow = NewCatalog.Settings.Add();
				NewRow.Setting = "CorrespondentDataArea";
				NewRow.Value = Record.WSPeerDataArea;
				
			Else
				
				NewRow = NewCatalog.Settings.Add();
				NewRow.Setting = "WebServiceAddress";
				NewRow.Value = Record.WSWebServiceURL;
				
				NewRow = NewCatalog.Settings.Add();
				NewRow.Setting = "UserName";
				NewRow.Value = Record.WSUserName;
				
				NewRow = NewCatalog.Settings.Add();
				NewRow.Setting = "RememberPassword";
				NewRow.Value = Record.WSRememberPassword;
					
				If Record.WSRememberPassword And ValueIsFilled(Passwords.WSPassword) Then
				
					Password = String(New UUID);
					Common.WriteDataToSecureStorage(Password, Passwords.WSPassword);
					
					NewRow = NewCatalog.Settings.Add();
					NewRow.Setting = "Password";
					NewRow.Value = Password;
					
				EndIf;
			
			EndIf;
			
		ElsIf TransportKind = Enums.ExchangeMessagesTransportTypes.COM Then
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "InfobaseOperatingMode";
			NewRow.Value = Record.COMInfobaseOperatingMode;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "InfobaseDirectory";
			NewRow.Value = Record.COMInfobaseDirectory;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "OperatingSystemAuthentication";
			NewRow.Value = Record.COMOperatingSystemAuthentication;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "UserName";
			NewRow.Value = Record.COMUserName;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "NameOf1CEnterpriseServer";
			NewRow.Value = Record.COM1CEnterpriseServerName;
			
			NewRow = NewCatalog.Settings.Add();
			NewRow.Setting = "NameOfInfobaseOn1CEnterpriseServer";
			NewRow.Value = Record.COM1CEnterpriseServerSideInfobaseName;
			
			If ValueIsFilled(Passwords.COMUserPassword) Then
				UserPassword = String(New UUID);
				Common.WriteDataToSecureStorage(UserPassword, Passwords.COMUserPassword);
				
				NewRow = NewCatalog.Settings.Add();
				NewRow.Setting = "UserPassword";
				NewRow.Value = UserPassword;
			EndIf;
			
		ElsIf TransportKind = Enums.ExchangeMessagesTransportTypes.WSPassiveMode Then
			
			NewCatalog.TransportID = "PassiveMode";
			
		EndIf;
		
		NewCatalog.Write();
		
	EndDo;
	
	Common.DeleteDataFromSecureStorage(Record.Peer, "");
			
EndProcedure

Function ConfiguredTransportKinds(Record)
	
	Result = New Array;
	
	If ValueIsFilled(Record.COMInfobaseDirectory) 
		Or ValueIsFilled(Record.COM1CEnterpriseServerSideInfobaseName) Then
		Result.Add(Enums.ExchangeMessagesTransportTypes.COM);
	EndIf;
	
	If ValueIsFilled(Record.EMAILAccount) Then
		Result.Add(Enums.ExchangeMessagesTransportTypes.EMAIL);
	EndIf;
	
	If ValueIsFilled(Record.FILEDataExchangeDirectory) Then
		Result.Add(Enums.ExchangeMessagesTransportTypes.FILE);
	EndIf;
	
	If ValueIsFilled(Record.FTPConnectionPath) Then
		Result.Add(Enums.ExchangeMessagesTransportTypes.FTP);
	EndIf;
	
	If ValueIsFilled(Record.WSWebServiceURL)
		Or ValueIsFilled(Record.WSCorrespondentEndpoint) Then
		Result.Add(Enums.ExchangeMessagesTransportTypes.WS);
	EndIf;
	
	If Record.DefaultExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WSPassiveMode Then
		Result.Add(Enums.ExchangeMessagesTransportTypes.WSPassiveMode);  
	EndIf;
	
	Return Result;
	
EndFunction

Procedure TransferTransportSettingsOfServiceManager()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DataAreaExchangeTransportSettings.Peer AS Peer,
		|	DataAreaExchangeTransportSettings.CorrespondentEndpoint AS CorrespondentEndpoint,
		|	ExchangeMessageTransportSettings.TransportID AS TransportID
		|FROM
		|	InformationRegister.DataAreaExchangeTransportSettings AS DataAreaExchangeTransportSettings
		|		LEFT JOIN Catalog.ExchangeMessageTransportSettings AS ExchangeMessageTransportSettings
		|		ON DataAreaExchangeTransportSettings.Peer = ExchangeMessageTransportSettings.Peer
		|			AND (ExchangeMessageTransportSettings.TransportID = ""SM"")
		|WHERE
		|	ExchangeMessageTransportSettings.Peer IS NULL";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		NewCatalog = Catalogs.ExchangeMessageTransportSettings.CreateItem();
		NewCatalog.Peer = Selection.Peer;
		NewCatalog.TransportID = "SM";
		NewCatalog.DefaultSetting = True;
		
		NewRow = NewCatalog.Settings.Add();
		NewRow.Setting = "CorrespondentEndpoint";
		NewRow.Value = Selection.CorrespondentEndpoint;
		
		NewRow = NewCatalog.Settings.Add();
		NewRow.Setting = "PeerInfobaseName";
		NewRow.Value = String(Selection.Peer);
		
		NewCatalog.Write();
		
	EndDo;
	
EndProcedure

Procedure TransferTransportSettingsForExchangeScenarios()

	Query = New Query;
	Query.Text =
		"SELECT DISTINCT
		|	ExchangeSettings.Ref AS Ref
		|FROM
		|	Catalog.DataExchangeScenarios.ExchangeSettings AS ExchangeSettings
		|WHERE
		|	(CAST(ExchangeSettings.TransportID AS STRING(100))) = """"";

	BeginTransaction();

	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.DataExchangeScenarios");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
				
			Scenario = Selection.Ref.GetObject();
			
			For Each Setting In Scenario.ExchangeSettings Do
				
				If ValueIsFilled(Setting.TransportID) Then
					Continue;
				EndIf;
				
				If Not ValueIsFilled(Setting.DeleteExchangeTransportKind) Then
					Continue; // Skip rows with empty transport
				EndIf;
				
				If Common.DataSeparationEnabled()
					And Common.SeparatedDataUsageAvailable() Then
				
					Setting.TransportID = "SM";
					
				Else
					
					TransportID = Common.EnumerationValueName(Setting.DeleteExchangeTransportKind);
					
					If TransportID = "WSPassiveMode" Then 
						
						TransportID = "PassiveMode";
						
					ElsIf TransportID = "ExternalSystem" Then
						
						TransportID = "";
						
					EndIf;
					
					Setting.TransportID = TransportID;
					
				EndIf;
				
			EndDo;
			
			Scenario.Write();
			
		EndDo;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

Function SavedTransportSettings()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TransportSettings.TransportID AS TransportID,
		|	TransportSettings.Peer AS Peer,
		|	TransportSettings.Settings.(
		|		Setting AS Setting,
		|		Value AS Value
		|	) AS Settings
		|FROM
		|	Catalog.ExchangeMessageTransportSettings AS TransportSettings";
	
	Return Query.Execute().Select();
	
EndFunction

Function RequiestToUseExternalResourcesParameters()
	
	Parameters = New Structure;
	Parameters.Insert("RequestCOM",  True);
	Parameters.Insert("RequestFILE", True);
	Parameters.Insert("RequestWS",   True);
	Parameters.Insert("RequestFTP",  True);
	
	Return Parameters;
	
EndFunction

Procedure RequestToUseExternalResources(PermissionsRequests, Record, QueryOptions) Export
	
	Permissions = New Array;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	TransportID = Record.TransportID;
	Peer = Record.Peer;
	
	TransportSettings = New Structure;
	SelectionBySettings = Record.Settings.Select();
	While SelectionBySettings.Next() Do
		TransportSettings.Insert(SelectionBySettings.Setting, SelectionBySettings.Value);
	EndDo;
		
	If Not ValueIsFilled(TransportSettings) Then
		Return;
	EndIf;
	
	If QueryOptions.RequestFTP 
		And TransportID = "FTP"
		And Not IsBlankString(TransportSettings.Path) Then
		
		AddressStructure1 = CommonClientServer.URIStructure(TransportSettings.Path);
		Permissions.Add(ModuleSafeModeManager.PermissionToUseInternetResource(
			AddressStructure1.Schema, AddressStructure1.Host, TransportSettings.Port));
		
	EndIf;
	
	If QueryOptions.RequestFILE 
		And TransportID = "FILE"
		And Not IsBlankString(TransportSettings.DataExchangeDirectory) Then
		
		Permissions.Add(ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
			TransportSettings.DataExchangeDirectory, True, True));
		
	EndIf;
	
	If QueryOptions.RequestWS 
		And (TransportID = "WS" Or TransportID = "HTTP")
		And Not IsBlankString(TransportSettings.WebServiceAddress) Then
		
		AddressStructure1 = CommonClientServer.URIStructure(TransportSettings.WebServiceAddress);
		If ValueIsFilled(AddressStructure1.Schema) Then
			Permissions.Add(ModuleSafeModeManager.PermissionToUseInternetResource(
				AddressStructure1.Schema, AddressStructure1.Host, AddressStructure1.Port));
		EndIf;
		
	EndIf;
	
	If QueryOptions.RequestCOM 
		And TransportID = "COM"
		And (Not IsBlankString(TransportSettings.InfobaseDirectory)
		Or Not IsBlankString(TransportSettings.NameOfInfobaseOn1CEnterpriseServer)) Then
		
		COMConnectorName = CommonClientServer.COMConnectorName();
		Permissions.Add(ModuleSafeModeManager.PermissionToCreateCOMClass(
			COMConnectorName, Common.COMConnectorID(COMConnectorName)));
		
	EndIf;
	
	// Permissions to perform synchronization by email are requested in the Email operations subsystem.
	
	If Permissions.Count() > 0 Then
		
		PermissionsRequests.Add(
			ModuleSafeModeManager.RequestToUseExternalResources(Permissions, Peer));
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
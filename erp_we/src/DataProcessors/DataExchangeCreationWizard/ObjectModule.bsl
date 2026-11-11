///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ErrorMessageStringField; // String - Error message.

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Export service procedures and functions.

// Performs the following actions on data exchange creation:
// - creates or updates nodes of the current exchange plan
// - loads data conversion rules from the template of the current exchange plan (if infobase is not a DIB)
// - loads data registration rules from the template of the current exchange plan
// - loads exchange message transport settings
// - sets the infobase prefix constant value (if it is not set)
// - registers all data on the current exchange plan node according to object registration rules.
//
// Parameters:
//  Cancel - Boolean - a cancellation flag. It is set to True if errors occur during the procedure execution.
// 
Procedure ExecuteActionsToSetNewDataExchange(Cancel,
	NodeFiltersSetting,
	DefaultNodeValues,
	RecordDataForExport = True,
	UseTransportSettings = True)
	
	ThisNodeCode = ?(UsePrefixesForExchangeSettings,
					GetThisBaseNodeCode(SourceInfobasePrefix),
					GetThisBaseNodeCode(SourceInfobaseID));
	If WizardRunOption = "ContinueDataExchangeSetup" Then
		NewNodeCode = SecondInfobaseNewNodeCode;
	ElsIf UsePrefixesForExchangeSettings Then
		NewNodeCode = DataExchangeServer.ExchangePlanNodeCodeString(DestinationInfobasePrefix);
	Else
		NewNodeCode = DestinationInfobaseID;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		// Creating/updating the exchange plan node.
		CreateUpdateExchangePlanNodes(NodeFiltersSetting, DefaultNodeValues, ThisNodeCode, NewNodeCode);
		
		If UseTransportSettings Then
			
			// Loading message transport settings.
			UpdateExchangeMessagesTransportSettings();
			
		EndIf;
		
		// Updating the infobase prefix constant value.
		If UsePrefixesForExchangeSettings
			And Not SourceInfobasePrefixIsSet Then
			
			UpdateInfobasePrefixConstantValue();
			
		EndIf;
		
		If IsDistributedInfobaseSetup
			And WizardRunOption = "ContinueDataExchangeSetup" Then
			
			Constants.SubordinateDIBNodeSetupCompleted.Set(True);
			Constants.UseDataSynchronization.Set(True);
			Constants.DoNotUseSeparationByDataAreas.Set(True);
			
			// Importing rules as exchange rules are not migrated to DIB.
			DataExchangeServer.UpdateDataExchangeRules();
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		InformAboutError(ErrorInfo(), Cancel);
		Return;
	EndTry;
	
	// Updating cached values of the object registration mechanism.
	DataExchangeInternal.CheckObjectsRegistrationMechanismCache();
	
	Try
		
		If RecordDataForExport
			And Not IsDistributedInfobaseSetup Then
			
			// Registering changes for an exchange plan node.
			RecordChangesForExchange(Cancel);
			
		EndIf;
		
	Except
		InformAboutError(ErrorInfo(), Cancel);
		Return;
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// To work via an external connection.

// Registers changes for an exchange plan node.
//
Procedure ExternalConnectionRecordChangesForExchange() Export
	
	// Registering changes for an exchange plan node.
	RecordChangesForExchange(False);
	
EndProcedure

// Reads settings of data exchange wizard from an XML string.
//
Procedure ExternalConnectionImportWizardParameters(Cancel, XMLLine) Export
	
	ImportWizardParameters(Cancel, XMLLine);
	
EndProcedure

// Updates data exchange node settings over an external connection and sets default values.
//
Procedure ExternalConnectionUpdateDataExchangeSettings(DefaultNodeValues) Export
	
	BeginTransaction();
	Try
		Block = New DataLock;
	    LockItem = Block.Add(Common.TableNameByRef(InfobaseNode));
	    LockItem.SetValue("Ref", InfobaseNode);
	    Block.Lock();
		
		// Updating settings for the node.
		LockDataForEdit(InfobaseNode);
		InfobaseNodeObject = InfobaseNode.GetObject();
		
		// Setting default values.
		DataExchangeEvents.SetDefaultNodeValues(InfobaseNodeObject, DefaultNodeValues);
		
		InfobaseNodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
		InfobaseNodeObject.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Exports wizard parameters to the temporary storage to continue exchange setup in the second base.
//
// Parameters:
//  Cancel - Boolean - a cancellation flag. It is set to True if errors occur during the procedure execution.
//  TempStorageAddress - String - on successful export xml file with settings
//                                      a temporary storage address is written in this variable.
//                                      The data file is available on server and client at the address.
// 
Procedure ExportWizardParametersToTempStorage(Cancel, TempStorageAddress) Export
	
	SetPrivilegedMode(True);
	
	// Getting the temporary file name in the local file system on the server.
	TempFileName = GetTempFileName("xml");
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	Try
		ModuleSetupWizard.ConnectionSettingsInXML(ThisObject, TempFileName);
	Except
		InformAboutError(ErrorInfo(), Cancel);
		FileSystem.DeleteTempFile(TempFileName);
		Return;
	EndTry;
	
	TempStorageAddress = PutToTempStorage(New BinaryData(TempFileName));
	
	FileSystem.DeleteTempFile(TempFileName);
	
EndProcedure

// Sets up a new data exchange over a web service.
// See the detailed description in the SetUpNewDataExchange procedure.
//
Procedure SetUpNewDataExchangeWebService(Cancel, NodeFiltersSetting, DefaultNodeValues) Export
	
	NodeFiltersSetting    = GetFilterSettingsValues(NodeFiltersSetting);
	DefaultNodeValues = GetFilterSettingsValues(DefaultNodeValues);
	If UsePrefixesForExchangeSettings Then
		SourceInfobasePrefixIsSet = ValueIsFilled(GetFunctionalOption("InfobasePrefix"));
	EndIf;

	// {Handler: OnGetSenderData} Start
	If DataExchangeServer.HasExchangePlanManagerAlgorithm("OnGetSenderData",ExchangePlanName) Then
		Try
			ExchangePlans[ExchangePlanName].OnGetSenderData(NodeFiltersSetting, False);
		Except
			InformAboutError(ErrorInfo(), Cancel);
			Return;
		EndTry;
	EndIf;
	// {Handler: OnGetSenderData} End
	
	ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WSPassiveMode;
	
	ExecuteActionsToSetNewDataExchange(Cancel,
													NodeFiltersSetting,
													DefaultNodeValues,
													False,
													True);
	
	If Cancel Then
		DeleteDataExchangeSettings();
	EndIf;
	
EndProcedure

Procedure DeleteDataExchangeSettings()
	
	ManagerExchangePlan = ExchangePlans[ExchangePlanName];
	Node_ToDelete = ManagerExchangePlan.FindByCode(SecondInfobaseNewNodeCode);
	
	If Not Node_ToDelete.IsEmpty() Then
		DataExchangeServer.DeleteSynchronizationSetting(Node_ToDelete);
	EndIf;
	
EndProcedure

// Initializes exchange node settings.
//
Procedure Initialize(Node) Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Node);
	CorrespondentExchangePlanName = ExchangePlanName;
	ThisNode = ExchangePlans[ExchangePlanName].ThisNode();
	AttributesOfThisSubAsset = Common.ObjectAttributesValues(ThisNode, "Code, Description");
	NodeCode = AttributesOfThisSubAsset.Code;
	ThisInfobaseDescription = AttributesOfThisSubAsset.Description;
	SourceInfobasePrefix = AttributesOfThisSubAsset.Code;
	
	InfobaseNode = Node;
	NodeAttributes = Common.ObjectAttributesValues(Node, "Code, Description");
	CorrespondentNodeCode = NodeAttributes.Code;
	SecondInfobaseDescription = NodeAttributes.Description;
	DestinationInfobasePrefix = NodeAttributes.Code;

	UsePrefixesForExchangeSettings = Not (DataExchangeServer.IsXDTOExchangePlan(ExchangePlanName)
		And DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(ExchangePlans[ExchangePlanName].EmptyRef()));
		
	If UsePrefixesForExchangeSettings Then
		If Common.DataSeparationEnabled() Then
			SourceInfobasePrefix = DataExchangeServer.PredefinedExchangePlanNodeCode(ExchangePlanName);
		Else
			SourceInfobasePrefix = GetFunctionalOption("InfobasePrefix");
		EndIf;
		SourceInfobasePrefixIsSet = ValueIsFilled(SourceInfobasePrefix);
	Else
		PredefinedNodeCode = DataExchangeServer.PredefinedExchangePlanNodeCode(ExchangePlanName);
		SourceInfobaseID = PredefinedNodeCode;
		DestinationInfobasePrefixSpecified = False;
		SourceInfobasePrefixIsSet = True;
	EndIf;
	
	If Not SourceInfobasePrefixIsSet
		And UsePrefixesForExchangeSettings Then
		DataExchangeOverridable.OnDetermineDefaultInfobasePrefix(SourceInfobasePrefix);
	EndIf;
	
	TransportSettings = ExchangeMessagesTransport.DefaultTransportSettings(Node, TransportID);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Functions-properties

// Returns the data exchange error message string.
//
// Returns:
//  String - a data exchange error message string.
//
Function ErrorMessageString() Export
	
	If TypeOf(ErrorMessageStringField) <> Type("String") Then
		
		ErrorMessageStringField = "";
		
	EndIf;
	
	Return ErrorMessageStringField;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary service procedures and functions.

Procedure CreateUpdateExchangePlanNodes(NodeFiltersSetting, DefaultNodeValues, ThisNodeCode, NewNodeCode)
	
	ManagerExchangePlan = ExchangePlans[ExchangePlanName]; // ExchangePlanManager
	
	// UPDATING THIS NODE, IF NECESSARY
	
	// Getting references to this exchange plan node.
	ThisNode = ManagerExchangePlan.ThisNode();
	
	ThisNodeCodeInDatabase = Common.ObjectAttributeValue(ThisNode, "Code");
	IsDIBExchangePlan  = DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName);
	
	If IsBlankString(Common.ObjectAttributeValue(ThisNode, "Code"))
		Or (IsDIBExchangePlan And ThisNodeCodeInDatabase <> ThisNodeCode)
		Or (UsePrefixesForExchangeSettings And ThisNodeCodeInDatabase <> ThisNodeCode) Then
		
		BeginTransaction();
		Try
		    Block = New DataLock;
		    LockItem = Block.Add(Common.TableNameByRef(ThisNode));
		    LockItem.SetValue("Ref", ThisNode);
		    Block.Lock();
		    
		    ThisNodeObject = ThisNode.GetObject();
			ThisNodeObject.Code = ThisNodeCode;
			ThisNodeObject.Description = ThisInfobaseDescription;
			ThisNodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
			ThisNodeObject.Write();

		    CommitTransaction();
		Except
		    RollbackTransaction();
			Raise;
		EndTry;
		
	EndIf;
	
	// GETTING THE NODE FOR EXCHANGE
	CreateNewNode = False;
	If IsDistributedInfobaseSetup
		And WizardRunOption = "ContinueDataExchangeSetup" Then
		
		MasterNode = DataExchangeServer.MasterNode();
		
		If MasterNode = Undefined Then
			
			Raise NStr("vi = 'Chưa xác định nút chính đối với cơ sở thông tin hiện tại.
							|Có thể là cơ sở thông tin không phải là nút trực thuộc trong CSTTPT.';
							|ru = 'Главный узел для текущей информационной базы не определен.
							|Возможно, информационная база не является подчиненным узлом в РИБ.';
							|en = 'The master node is not defined.
							|Probably this infobase is not a subordinate DIB node.'; fa = 'The master node is not defined.
							|Probably this infobase is not a subordinate DIB node.';
							|it = 'Il nodo principale per il database informatico corrente non è definito.
							|È possibile che il database informatico non sia un nodo subordinato nel database informatico distribuito.';
							|pl = 'Główny węzeł dla bieżącej bazy informacyjnej nie został zdefiniowany. 
							|Możliwe, baza informacyjna nie jest podwładnym węzłem w RBI.';
							|tr = 'Geçerli Infobase için master düğüm tanımlanmamıştır.
							| Infobase DBT''deki alt düğüm olmayabilir.'");
		EndIf;
		
		NewNode = MasterNode.GetObject();
		
	Else
		
		// CREATE/UPDATE NODE
		NewNode = ManagerExchangePlan.FindByCode(NewNodeCode);
		CreateNewNode = NewNode.IsEmpty();
		If CreateNewNode Then
			NewNode = ManagerExchangePlan.CreateNode();
			NewNode.Code = NewNodeCode;
			NewNode.Fill(Undefined)
		Else
			Raise NStr("vi = 'Giá trị tiền tố cơ sở thông tin thứ nhất không đơn trị.
				|Trong hệ thống đã tồn tại đồng bộ hóa dữ liệu đối với cơ sở thông tin (chương trình) có tiền tố như vậy.';
				|ru = 'Значение префикса первой информационной базы не уникально.
				|В системе уже существует синхронизация данных для информационной базы (программы) с указанным префиксом.';
				|en = 'The first infobase prefix is not unique.
				|A data synchronization for an infobase (application) with this prefix already exists.'; fa = 'The first infobase prefix is not unique.
				|A data synchronization for an infobase (application) with this prefix already exists.';
				|it = 'Il valore del prefisso del primo database informatico non è univoco.
				|Nel sistema esiste già una sincronizzazione dati per il database informatico (programma) con il prefisso indicato.';
				|pl = 'Wartość przedrostka pierwszej bazy informacyjnej nie jest unikalna. 
				|W systemie istnieje już synchronizacja danych dla bazy informacyjnej (programu) z podanym prefiksem.';
				|tr = 'İlk infobase''in önekinin değeri benzersiz değil. 
				| Sistemde belirtilen öneke sahip infobase (program) için veri eşleşmesi zaten mevcut.'");
		EndIf;
		
		NewNode.Description = SecondInfobaseDescription;
		
		If Common.HasObjectAttribute("SettingsMode", Metadata.ExchangePlans[ExchangePlanName]) Then
			NewNode.SettingsMode = ExchangeSetupOption;
		EndIf;
		
	EndIf;
	
	// Setting filter values for the new node.
	DataExchangeEvents.SetNodeFilterValues(NewNode, NodeFiltersSetting);
	
	// Setting default values for the new node.
	DataExchangeEvents.SetDefaultNodeValues(NewNode, DefaultNodeValues);
	
	// Reset message counters.
	NewNode.SentNo = 0;
	NewNode.ReceivedNo     = 0;
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable()
		And DataExchangeServer.IsSeparatedSSLExchangePlan(ExchangePlanName) Then
		
		NewNode.RegisterChanges = True;
		
	EndIf;
	
	If ValueIsFilled(RefToNew) Then
		NewNode.SetNewObjectRef(RefToNew);
	EndIf;
	
	NewNode.DataExchange.Load = True;
	NewNode.Write();
	
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		
		DatabaseObjectsTable = DataExchangeXDTOServer.SupportedObjectsInFormat(ExchangePlanName,
			"SendReceive", NewNode.Ref);
		CorrespondentObjectsTable = DatabaseObjectsTable.CopyColumns();
		
		For Each BaseObjectsRow In DatabaseObjectsTable Do
			CorrespondentObjectsRow = CorrespondentObjectsTable.Add();
			FillPropertyValues(CorrespondentObjectsRow, BaseObjectsRow, "Version, Object");
			CorrespondentObjectsRow.Send  = BaseObjectsRow.Receive;
			CorrespondentObjectsRow.Receive = BaseObjectsRow.Send;
		EndDo;
		
		XDTOSettingManager = Common.CommonModule("InformationRegisters.XDTODataExchangeSettings");
		XDTOSettingManager.UpdateSettings2(
			NewNode.Ref, "SupportedObjects", DatabaseObjectsTable);
		XDTOSettingManager.UpdateCorrespondentSettings(
			NewNode.Ref, "SupportedObjects", CorrespondentObjectsTable);
		
		RecordStructure = New Structure;
		RecordStructure.Insert("InfobaseNode",       NewNode.Ref);
		RecordStructure.Insert("CorrespondentExchangePlanName", CorrespondentExchangePlanName);
		
		DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "XDTODataExchangeSettings");
	EndIf;
	
	// Shared node data.
	InformationRegisters.CommonInfobasesNodesSettings.UpdatePrefixes(
		NewNode.Ref,
		?(UsePrefixesForExchangeSettings, SourceInfobasePrefix, ""),
		DestinationInfobasePrefix);
		
	If Not DataExchangeServer.SynchronizationSetupCompleted(NewNode.Ref) Then
		DataExchangeServer.CompleteDataSynchronizationSetup(NewNode.Ref);
	EndIf;
	
	InfobaseNode = NewNode.Ref;
	
	If CreateNewNode
		And Not Common.DataSeparationEnabled() Then
		DataExchangeServer.UpdateDataExchangeRules();
	EndIf;
	If ThisNodeCode <> ThisNodeCodeInDatabase 
		And (UsePrefixesForExchangeSettings
			Or UsePrefixesForCorrespondentExchangeSettings) Then
		// Node in the correspondent base needs recoding.
		StructureTemporaryCode = New Structure("Peer, NodeCode", InfobaseNode, ThisNodeCode);
		DataExchangeInternal.AddRecordToInformationRegister(StructureTemporaryCode, "PredefinedNodesAliases");
	EndIf;

EndProcedure

Procedure UpdateExchangeMessagesTransportSettings()
	
	If ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WSPassiveMode Then
		
		NewCatalog = Catalogs.ExchangeMessageTransportSettings.CreateItem();
		NewCatalog.Peer = InfobaseNode;
		NewCatalog.DefaultSetting = True;
		NewCatalog.TransportID = "PassiveMode";
		NewCatalog.Write();
		
	EndIf;
	
EndProcedure

Procedure UpdateInfobasePrefixConstantValue()
	ValueBeforeUpdate = GetFunctionalOption("InfobasePrefix");
	
	If IsBlankString(ValueBeforeUpdate)
		And ValueBeforeUpdate <> SourceInfobasePrefix Then
		
		DataExchangeServer.SetInfobasePrefix(TrimAll(SourceInfobasePrefix));
		
	EndIf;
	
EndProcedure

Procedure RecordChangesForExchange(Cancel)
	
	Try
		DataExchangeServer.RegisterDataForInitialExport(InfobaseNode);
	Except
		InformAboutError(ErrorInfo(), Cancel);
		Return;
	EndTry;
	
EndProcedure

Function GetThisBaseNodeCode(Val InfobasePrefixSpecifiedByUser)
	
	If WizardRunOption = "ContinueDataExchangeSetup" Then
		
		If ValueIsFilled(PredefinedNodeCode) Then
			Return PredefinedNodeCode;
		Else
			Return TrimAll(InfobasePrefixSpecifiedByUser);
		EndIf;
		
	EndIf;
	If UsePrefixesForExchangeSettings Then
		If ValueIsFilled(SourceInfobasePrefix) Then
			Result = SourceInfobasePrefix;
		Else
			If IsBlankString(Result) Then
				Result = InfobasePrefixSpecifiedByUser;
			
				If IsBlankString(Result) Then
					
					Return "000";
					
				EndIf;
			EndIf;
		EndIf;
		Return DataExchangeServer.ExchangePlanNodeCodeString(Result);
	Else
		If ValueIsFilled(SourceInfobaseID) Then 
			Return SourceInfobaseID;
		Else
			Return "";
		EndIf;
	EndIf;
EndFunction

// Reads settings of data exchange wizard from an XML string.
//
Procedure ImportWizardParameters(Cancel, XMLLine, TransportID = "") Export
	
	// Checking whether it is possible to use the exchange plan in SaaS.
	If Common.DataSeparationEnabled()
		And Not DataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlanName) Then
		ErrorMessageStringField = NStr("vi = 'Không được phép đồng bộ dữ liệu với chương trình này ở chế độ dịch vụ.';
										|ru = 'Синхронизация данных с этой программой в режиме сервиса не предусмотрена.';
										|en = 'Data synchronization with this application is not available in SaaS mode.'; fa = 'Data synchronization with this application is not available in SaaS mode.';
										|it = 'La sincronizzazione dei dati con questo programma in modalità di servizio non è prevista.';
										|pl = 'Synchronizacja danych z tym programem w trybie serwisu nie jest przewidziana.';
										|tr = 'Servis modunda verilerin bu programla eşleşmesi öngörülmemiştir.'");
		DataExchangeServer.ReportError(ErrorMessageString(), Cancel);
		Return;
	EndIf;
	
	If IsBlankString(WizardRunOption) Then
		WizardRunOption = "ContinueDataExchangeSetup";
	EndIf;
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	Try
		ModuleSetupWizard.FillConnectionSettingsFromXMLString(ThisObject, XMLLine,,, TransportID);
	Except
		InformAboutError(ErrorInfo(), Cancel);
	EndTry;
	
EndProcedure

Procedure InformAboutError(ErrorInfo, Cancel)
	
	ErrorMessageStringField = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	
	DataExchangeServer.ReportError(ErrorProcessing.BriefErrorDescription(ErrorInfo), Cancel);
	
	WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(), EventLogLevel.Error,,, ErrorMessageString());
	
EndProcedure

Function GetFilterSettingsValues(ExternalConnectionSettingsStructure)
	
	Return DataExchangeServer.GetFilterSettingsValues(ExternalConnectionSettingsStructure);
	
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
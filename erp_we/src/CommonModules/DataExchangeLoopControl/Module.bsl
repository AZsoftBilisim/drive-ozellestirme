///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure ImportCircuitFromMessage(ExchangeComponents, Header) Export
	
	If Not Header.IsSet("SynchronizationContour") Then
		Return;
	EndIf;
		
	If Header.SynchronizationContour <> Undefined Then
		
		Tree = New ValueTree;
		Tree.Columns.Add("NodeCode");
		Tree.Columns.Add("CorrespondentNodeCode");
		Tree.Columns.Add("NodeName");
		Tree.Columns.Add("PeerInfobaseNodeName");
		Tree.Columns.Add("LatestUpdate");
		Tree.Columns.Add("Prefix");
		Tree.Columns.Add("Looping");
		
		For Each Node In Header.SynchronizationContour.Node Do
			
			NewNode = Tree.Rows.Add();
			NewNode.NodeCode = Node.Code;
			NewNode.NodeName = GetStringFromBinaryData(GetBinaryDataFromBase64String(Node.Name));
			NewNode.LatestUpdate = Node.LastUpdate;
			NewNode.Prefix = Node.Prefix;
				
			For Each CorrNode In Node.CorrNodes.CorrNode Do
					
				NewPeerNode = NewNode.Rows.Add();
				NewPeerNode.CorrespondentNodeCode = CorrNode.Code;
				NewPeerNode.PeerInfobaseNodeName = GetStringFromBinaryData(GetBinaryDataFromBase64String(CorrNode.Name));
				NewPeerNode.Looping = CorrNode.Looping;
				
			EndDo;
			
		EndDo;
		
		ExchangePlanName = ExchangeComponents.CorrespondentNode.Metadata().Name;
		
		UpdateCircuitFromTree(Tree, ExchangePlanName);
		ReplacePrefixes();
		CheckLooping(ExchangePlanName);
		
	EndIf;
	
EndProcedure

Procedure ExportCircuitToMessage(Header, ExchangePlanName) Export
	
	UpdateCircuit(ExchangePlanName);
	
	SynchronizationCircuit = XDTOFactory.Create(XDTOFactory.Type(XMLBasicSchema(), "SynchronizationContour"));
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Circuit.NodeCode AS NodeCode,
		|	Circuit.CorrespondentNodeCode AS CorrespondentNodeCode,
		|	Circuit.NodeName AS NodeName,
		|	Circuit.PeerInfobaseNodeName AS PeerInfobaseNodeName,
		|	Circuit.LatestUpdate AS LatestUpdate,
		|	Circuit.Prefix AS Prefix,
		|	Circuit.Looping AS Looping
		|FROM
		|	InformationRegister.SynchronizationCircuit AS Circuit
		|TOTALS
		|	MAX(NodeName),
		|	MAX(LatestUpdate),
		|	MAX(Prefix)
		|BY
		|	NodeCode";
	
	SelectionByNodes = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While SelectionByNodes.Next() Do
		
		Node = XDTOFactory.Create(XDTOFactory.Type(XMLBasicSchema(), "Node"));
		Node.Code 		= SelectionByNodes.NodeCode;
		Node.Name 		= GetBase64StringFromBinaryData(GetBinaryDataFromString(SelectionByNodes.NodeName));
		Node.LastUpdate = SelectionByNodes.LatestUpdate;
		Node.Prefix 	= SelectionByNodes.Prefix;
		
		PeerNodes = XDTOFactory.Create(XDTOFactory.Type(XMLBasicSchema(), "CorrNodes"));
		
		SelectionByPeerNodes = SelectionByNodes.Select();
		While SelectionByPeerNodes.Next() Do	
			
			PeerNode = XDTOFactory.Create(XDTOFactory.Type(XMLBasicSchema(), "CorrNode"));
			PeerNode.Code = SelectionByPeerNodes.CorrespondentNodeCode;
			PeerNode.Name = GetBase64StringFromBinaryData(GetBinaryDataFromString(SelectionByPeerNodes.PeerInfobaseNodeName));
			PeerNode.Looping = SelectionByPeerNodes.Looping;
			PeerNodes.CorrNode.Add(PeerNode);
			
		EndDo;
		
		If PeerNodes.CorrNode.Count() > 0 Then
			Node.CorrNodes = PeerNodes;
		Else
			Node.CorrNodes = Undefined;
		EndIf;
		
		SynchronizationCircuit.Node.Add(Node);
		
	EndDo;

	If SynchronizationCircuit.Node.Count() > 0 Then
		Header.SynchronizationContour = SynchronizationCircuit;
	Else
		Header.SynchronizationContour = Undefined;	
	EndIf;
		
EndProcedure

Procedure UpdateCircuit(ExchangePlanName) Export

	QueryText = 
		"SELECT DISTINCT
		|	Circuit.NodeCode AS NodeCode,
		|	Circuit.Prefix AS Prefix
		|INTO TT_Prefixes
		|FROM
		|	InformationRegister.SynchronizationCircuit AS Circuit
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Circuit.InfobaseNode AS InfobaseNode,
		|	Circuit.NodeCode AS NodeCode,
		|	Circuit.CorrespondentNodeCode AS CorrespondentNodeCode,
		|	Circuit.NodeName AS NodeName,
		|	Circuit.PeerInfobaseNodeName AS PeerInfobaseNodeName,
		|	Circuit.LatestUpdate AS LatestUpdate
		|INTO TT_Circuit
		|FROM
		|	InformationRegister.SynchronizationCircuit AS Circuit
		|WHERE
		|	Circuit.InfobaseNode <> UNDEFINED
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Nodes.Ref AS Ref,
		|	ISNULL(TT_Prefixes.NodeCode, Nodes.Code) AS Code,
		|	Nodes.Description AS Description
		|INTO TT_Nodes
		|FROM
		|	&ExchangePlan AS Nodes
		|		LEFT JOIN TT_Prefixes AS TT_Prefixes
		|		ON Nodes.Code = TT_Prefixes.Prefix
		|WHERE
		|	Nodes.Ref <> &ThisNode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TRUE AS DeletionRequired
		|INTO TT_DeletionRequired
		|FROM
		|	TT_Circuit AS TT_Circuit
		|		FULL JOIN TT_Nodes AS TT_Nodes
		|		ON TT_Circuit.InfobaseNode = TT_Nodes.Ref
		|WHERE
		|	TT_Nodes.Ref IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_Nodes.Ref AS Ref,
		|	TT_Nodes.Code AS Code,
		|	TT_Nodes.Description AS Description,
		|	TT_Circuit.NodeCode AS NodeCode,
		|	TT_Circuit.CorrespondentNodeCode AS CorrespondentNodeCode,
		|	TT_Circuit.InfobaseNode AS InfobaseNode,
		|	CASE
		|		WHEN NOT TT_Circuit.InfobaseNode IS NULL
		|				AND NOT TT_Nodes.Ref IS NULL
		|				AND (TT_Circuit.NodeCode <> &ThisNodeCode
		|					OR TT_Circuit.NodeName <> &ThisNodeDescription
		|					OR TT_Circuit.CorrespondentNodeCode <> TT_Nodes.Code
		|					OR TT_Circuit.PeerInfobaseNodeName <> TT_Nodes.Description)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS UpdateBankingDetails,
		|	CASE
		|		WHEN TT_Circuit.InfobaseNode IS NULL
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS AddNodeToCircuit,
		|	CASE
		|		WHEN TT_Nodes.Ref IS NULL
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS RemoveNodeFromCircuit,
		|	CASE
		|		WHEN ISNULL(TT_DeletionRequired.DeletionRequired, FALSE)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS InstallNewestUpdate
		|FROM
		|	TT_Circuit AS TT_Circuit
		|		FULL JOIN TT_Nodes AS TT_Nodes
		|		ON TT_Circuit.InfobaseNode = TT_Nodes.Ref
		|		FULL JOIN TT_DeletionRequired AS TT_DeletionRequired
		|		ON (TRUE)";
		
	QueryText = StrReplace(QueryText, "&ExchangePlan", "ExchangePlan." + ExchangePlanName);
	
	ThisNode = DataExchangeCached.GetThisExchangePlanNode(ExchangePlanName);
	Prefix = Constants.DistributedInfobaseNodePrefix.Get();
	
	Query = New Query(QueryText);
	Query.SetParameter("ThisNode", ThisNode);
	Query.SetParameter("ThisNodeCode", ThisNode.Code);
	Query.SetParameter("ThisNodeDescription", ThisNode.Description);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If Selection.UpdateBankingDetails Then
			BeginTransaction();

			Try
				DataLock = New DataLock;
				DataLockItem = DataLock.Add("InformationRegister.SynchronizationCircuit");
				DataLockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
				DataLockItem.SetValue("NodeCode", Selection.NodeCode);
				DataLockItem.SetValue("CorrespondentNodeCode", Selection.CorrespondentNodeCode);
				DataLockItem.Mode = DataLockMode.Exclusive;
				DataLock.Lock();

				Record = InformationRegisters.SynchronizationCircuit.CreateRecordManager();
				FillPropertyValues(Record, Selection);
				Record.Read();
				Record.NodeCode = ThisNode.Code;
				Record.NodeName = ThisNode.Description;
				Record.CorrespondentNodeCode = Selection.Code;
				Record.PeerInfobaseNodeName = Selection.Description;
				Record.LatestUpdate = ToUniversalTime(CurrentSessionDate());
				Record.Prefix = Prefix;
				Record.Write();

				CommitTransaction();
			Except
				RollbackTransaction();

				ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

				Event = NStr("vi = 'Контроль зацикливания.Обновление реквизитов записи контура синхронизации';
							|ru = 'Контроль зацикливания.Обновление реквизитов записи контура синхронизации';
							|en = 'Loop control.Update attributes of the synchronization circuit record'; fa = 'Loop control.Update attributes of the synchronization circuit record';
							|it = 'Контроль зацикливания.Обновление реквизитов записи контура синхронизации';
							|pl = 'Loop control.Update attributes of the synchronization circuit record';
							|tr = 'Контроль зацикливания.Обновление реквизитов записи контура синхронизации'", Common.DefaultLanguageCode());

				WriteLogEvent(Event, EventLogLevel.Error,
					Metadata.InformationRegisters.SynchronizationCircuit, , ErrorMessage);
			EndTry; 
			
		ElsIf Selection.AddNodeToCircuit Then
			
			Record = InformationRegisters.SynchronizationCircuit.CreateRecordManager();
			Record.InfobaseNode = Selection.Ref;
			Record.NodeCode = ThisNode.Code;
			Record.NodeName= ThisNode.Description;
			Record.CorrespondentNodeCode = Selection.Code;
			Record.PeerInfobaseNodeName = Selection.Description;
			Record.LatestUpdate = ToUniversalTime(CurrentSessionDate());
			Record.Prefix = Prefix;
			Record.Write(); 
			
		ElsIf Selection.RemoveNodeFromCircuit Then
			
			BeginTransaction();

			Try
				DataLock = New DataLock;
				DataLockItem = DataLock.Add("InformationRegister.SynchronizationCircuit");
				DataLockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
				DataLockItem.SetValue("NodeCode", Selection.NodeCode);
				DataLockItem.SetValue("CorrespondentNodeCode", Selection.CorrespondentNodeCode);
				DataLockItem.Mode = DataLockMode.Exclusive;
				DataLock.Lock();

				Record = InformationRegisters.SynchronizationCircuit.CreateRecordManager();
				FillPropertyValues(Record, Selection);
				Record.Read();
				Record.Delete();

				DeletePeerNode(Selection.NodeCode, Selection.CorrespondentNodeCode);

				CommitTransaction();
			Except
				RollbackTransaction();

				ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

				Event = NStr("vi = 'Контроль зацикливания.Удаление записи контура синхронизации';
							|ru = 'Контроль зацикливания.Удаление записи контура синхронизации';
							|en = 'Loop control.Delete the synchronization circuit record'; fa = 'Loop control.Delete the synchronization circuit record';
							|it = 'Контроль зацикливания.Удаление записи контура синхронизации';
							|pl = 'Loop control.Delete the synchronization circuit record';
							|tr = 'Контроль зацикливания.Удаление записи контура синхронизации'", Common.DefaultLanguageCode());

				WriteLogEvent(Event, EventLogLevel.Error,
					Metadata.InformationRegisters.SynchronizationCircuit, , ErrorMessage);
			EndTry;
			
		ElsIf Selection.InstallNewestUpdate Then
			
			BeginTransaction();

			Try
				DataLock = New DataLock;
				DataLockItem = DataLock.Add("InformationRegister.SynchronizationCircuit");
				DataLockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
				DataLockItem.SetValue("NodeCode", Selection.NodeCode);
				DataLockItem.SetValue("CorrespondentNodeCode", Selection.CorrespondentNodeCode);
				DataLockItem.Mode = DataLockMode.Exclusive;
				DataLock.Lock();

				Record = InformationRegisters.SynchronizationCircuit.CreateRecordManager();
				FillPropertyValues(Record, Selection);
				Record.Read();
				Record.LatestUpdate = ToUniversalTime(CurrentSessionDate());
				Record.Write();

				CommitTransaction();
			Except
				RollbackTransaction();

				ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

				Event = NStr("vi = 'Контроль зацикливания.Очистка устаревшей версии';
							|ru = 'Контроль зацикливания.Очистка устаревшей версии';
							|en = 'Loop control.Clear the outdated version'; fa = 'Loop control.Clear the outdated version';
							|it = 'Контроль зацикливания.Очистка устаревшей версии';
							|pl = 'Loop control.Clear the outdated version';
							|tr = 'Контроль зацикливания.Очистка устаревшей версии'", Common.DefaultLanguageCode());

				WriteLogEvent(Event, EventLogLevel.Error,
					Metadata.InformationRegisters.SynchronizationCircuit, , ErrorMessage);
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndProcedure 

Procedure CheckLooping(ExchangePlanName, Mode = "CircuitImport") Export
	
	ThisNode = ExchangePlans[ExchangePlanName].ThisNode();
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = 
		"SELECT
		|	Nodes.InfobaseNode AS InfobaseNode,
		|	Nodes.NodeCode AS NodeCode,
		|	Nodes.CorrespondentNodeCode AS CorrespondentNodeCode,
		|	Nodes.NodeName AS NodeName,
		|	Nodes.PeerInfobaseNodeName AS PeerInfobaseNodeName,
		|	Nodes.IsSyncDeleted AS IsSyncDeleted,
		|	Nodes.LatestUpdate AS LatestUpdate,
		|	Nodes.Prefix AS Prefix,
		|	Nodes.Looping AS Looping
		|INTO TT_Circuit
		|FROM
		|	InformationRegister.SynchronizationCircuit AS Nodes
		|		INNER JOIN InformationRegister.SynchronizationCircuit AS PeerNodes
		|		ON Nodes.NodeCode = PeerNodes.CorrespondentNodeCode
		|			AND Nodes.CorrespondentNodeCode = PeerNodes.NodeCode";
	
	Query.Execute();
			
	If Mode = "CircuitImport" Then
		
		// If looping was defined in another infobase and the current infobase is part of it, 
		// do not set the loop flag in the current node.

		Query.Text = 
			"SELECT TOP 1
			|	Circuit.NodeCode AS NodeCode
			|FROM
			|	TT_Circuit AS Circuit
			|WHERE
			|	Circuit.InfobaseNode = UNDEFINED
			|	AND Circuit.CorrespondentNodeCode = &NodeCode
			|	AND Circuit.Looping";
		
		Query.SetParameter("NodeCode", ThisNode.Code);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Return;
		EndIf;
		
	EndIf;
	
	//
	Query.Text =
		"SELECT
		|	Circuit.NodeCode AS NodeCode,
		|	Circuit.CorrespondentNodeCode AS CorrespondentNodeCode,
		|	Circuit.NodeName AS NodeName,
		|	Circuit.PeerInfobaseNodeName AS PeerInfobaseNodeName
		|FROM
		|	TT_Circuit AS Circuit
		|TOTALS
		|	MAX(NodeName)
		|BY
		|	NodeCode";
		
	SynchronizationCircuit = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	NodesList = CheckLoopRecursively(SynchronizationCircuit, ThisNode.Code);
	
	If NodesList = Undefined Then
		ClearLoopFlag();
	Else
		SetLoopFlag(NodesList);	
	EndIf;
		
EndProcedure  

Procedure HideShowLoopingWarningFromUser(Direction) Export
	
	SettingsDescription = NStr("vi = 'Ẩn chỉ dẫn về cài đặt đồng bộ hóa theo chu kỳ.';
								|ru = 'Скрыть подсказку о цикличных настройках синхронизации.';
								|en = 'Hide the hint about cyclic settings of synchronization.'; fa = 'Hide the hint about cyclic settings of synchronization.';
								|it = 'Скрыть подсказку о цикличных настройках синхронизации.';
								|pl = 'Hide the hint about cyclic settings of synchronization.';
								|tr = 'Döngüsel senkronizasyon ayarlarına dair ipucunu gizle.'", Common.DefaultLanguageCode());
	
	ObjectKey = "HideShowLoopingWarning";
	SettingsKey = "HideShowLoopingWarning";
	Common.CommonSettingsStorageSave(ObjectKey, SettingsKey, Direction);
	
EndProcedure

Function LoopingWarningIsHiddenFromUser() Export
	
	ObjectKey = "HideShowLoopingWarning";
	SettingsKey = "HideShowLoopingWarning";
	Return Common.CommonSettingsStorageLoad(ObjectKey, SettingsKey, False);
	
EndFunction

Function HasLoop(ConsiderDisablingMonitoring = True) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	TRUE AS DisableSynchronizationCircuitMonitoring
	|INTO ContourMonitoringIsDisabled
	|FROM
	|	InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
	|WHERE
	|	CommonInfobasesNodesSettings.DisableSynchronizationCircuitMonitoring = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE AS HasLoop,
	|	ContourMonitoringIsDisabled.DisableSynchronizationCircuitMonitoring AS DisableSynchronizationCircuitMonitoring
	|FROM
	|	InformationRegister.SynchronizationCircuit AS SynchronizationCircuit
	|		LEFT JOIN ContourMonitoringIsDisabled AS ContourMonitoringIsDisabled
	|		ON (ContourMonitoringIsDisabled.DisableSynchronizationCircuitMonitoring = TRUE)
	|WHERE
	|	SynchronizationCircuit.Looping");
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		
		Return False;
		
	EndIf;
	
	// Verify if control is disabled
	If ConsiderDisablingMonitoring Then
		
		SelectionOfResult = Result.Select();
		SelectionOfResult.Next();
		If SelectionOfResult.DisableSynchronizationCircuitMonitoring = True Then
			
			Return False; // Control is disabled
			
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

Function IsNodeLooped(InfobaseNode, ConsiderDisablingMonitoring = True) Export
	
	Query = New Query;
	Query.SetParameter("InfobaseNode", InfobaseNode);
	Query.SetParameter("NodeCode", InfobaseNode.Code);
	
	// Allow the OR clause in the left join, as the number of nodes is tens, hundreds at most.
	Query.Text = 
	"SELECT TOP 1
	|	CommonInfobasesNodesSettings.DisableSynchronizationCircuitMonitoring AS DisableSynchronizationCircuitMonitoring,
	|	CommonInfobasesNodesSettings.InfobaseNode AS InfobaseNode
	|INTO ContourMonitoringIsDisabled
	|FROM
	|	InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
	|WHERE
	|	CommonInfobasesNodesSettings.InfobaseNode = &InfobaseNode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	SynchronizationCircuit.InfobaseNode AS InfobaseNode,
	|	ContourMonitoringIsDisabled.DisableSynchronizationCircuitMonitoring AS DisableSynchronizationCircuitMonitoring
	|FROM
	|	InformationRegister.SynchronizationCircuit AS SynchronizationCircuit,
	|	ContourMonitoringIsDisabled AS ContourMonitoringIsDisabled
	|WHERE
	|	SynchronizationCircuit.Looping
	|	AND (SynchronizationCircuit.NodeCode = &NodeCode
	|			OR SynchronizationCircuit.CorrespondentNodeCode = &NodeCode)";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		
		Return False;
		
	EndIf;
	
	// Verify if control is disabled
	If ConsiderDisablingMonitoring Then
		
		SelectionOfResult = Result.Select();
		SelectionOfResult.Next();
		If SelectionOfResult.DisableSynchronizationCircuitMonitoring = True Then
			
			Return False; // Control is disabled
			
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

Function AllLoopedNodesPresentation() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Circuit.NodeName AS NodeName,
		|	Circuit.PeerInfobaseNodeName AS PeerInfobaseNodeName
		|INTO TT_Circuit
		|FROM
		|	InformationRegister.SynchronizationCircuit AS Circuit
		|WHERE
		|	Circuit.Looping
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TT_Circuit.NodeName AS NodeName
		|FROM
		|	TT_Circuit AS TT_Circuit
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	TT_Circuit.PeerInfobaseNodeName
		|FROM
		|	TT_Circuit AS TT_Circuit";
	
	NodesArray = New Array;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NodeName = Selection.NodeName;
		NodesArray.Add(" - " + NodeName);
	EndDo;
	
	Return StrConcat(NodesArray, Chars.LF);
	
EndFunction

Function InfobaseWithSuspendedRegistrationPresentation() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	Circuit.NodeName AS NodeName
		|FROM
		|	InformationRegister.SynchronizationCircuit AS Circuit
		|WHERE
		|	Circuit.Looping";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.NodeName;
	Else
		Return "";
	EndIf;
	
EndFunction

#EndRegion

#Region Private

Function CheckLoopRecursively(SynchronizationCircuit, InitialNode, CurrentNode = "", Val Parent = "", Val NodesChain = Undefined) 
	
	If NodesChain = Undefined Then
		NodesChain = New ValueList; 
	EndIf;
	
	If NodesChain.FindByValue(CurrentNode) <> Undefined Then // The node has already been analyzed
		Return NodesChain;
	EndIf;
	
	If NodesChain.FindByValue(InitialNode) <> Undefined Then // Loop detected
		Return NodesChain;
	EndIf;
	
	If IsBlankString(CurrentNode) Then
		CurrentNode = InitialNode;
	Else
		NodesChain.Add(CurrentNode); // Add all nodes except for the initial node
	EndIf;
	
	Filter = New Structure("NodeCode", CurrentNode);
	Nodes = SynchronizationCircuit.Rows.FindRows(Filter);
	
	For Each Node In Nodes Do
		For Each PeerNode In Node.Rows Do
			
			If PeerNode.CorrespondentNodeCode = Parent Then // Exchange between two peer nodes 
				Continue;
			EndIf;
			
			Result = CheckLoopRecursively(SynchronizationCircuit, InitialNode, PeerNode.CorrespondentNodeCode, CurrentNode, NodesChain);
			
			If Result <> Undefined Then
				Return Result;
			EndIf;
			
		EndDo;
	EndDo;
	
EndFunction

Procedure UpdateCircuitFromTree(Tree, ExchangePlanName)
	
	ManagerExchangePlan = ExchangePlans[ExchangePlanName];
	ThisNode = ManagerExchangePlan.ThisNode();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Circuit.NodeCode AS NodeCode,
		|	Circuit.CorrespondentNodeCode AS CorrespondentNodeCode,
		|	Circuit.NodeName AS NodeName,
		|	Circuit.PeerInfobaseNodeName AS PeerInfobaseNodeName,
		|	Circuit.LatestUpdate AS LatestUpdate,
		|	1 AS RecordsCount
		|FROM
		|	InformationRegister.SynchronizationCircuit AS Circuit
		|WHERE
		|	Circuit.InfobaseNode = UNDEFINED
		|TOTALS
		|	MAX(LatestUpdate),
		|	SUM(RecordsCount)
		|BY
		|	NodeCode";
	
	SynchronizationCircuit = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	For Each TreeNode In Tree.Rows Do
		
		// Do not update data in the current node
		If TreeNode.NodeCode = ThisNode.Code Then
			Continue;
		EndIf;
		
		Filter = New Structure("NodeCode", TreeNode.NodeCode);
		CircuitNodes = SynchronizationCircuit.Rows.FindRows(Filter);

		// Delete obsolete records
		If CircuitNodes.Count() > 0 
			And CircuitNodes[0].LatestUpdate < TreeNode.LatestUpdate
			And CircuitNodes[0].RecordsCount > 0 Then
			
			For Each CircuitPeerNode In CircuitNodes[0].Rows Do
				
				BeginTransaction();

				Try
					DataLock = New DataLock;
					DataLockItem = DataLock.Add("InformationRegister.SynchronizationCircuit");
					DataLockItem.SetValue("InfobaseNode", Undefined);
					DataLockItem.SetValue("NodeCode", CircuitPeerNode.NodeCode);
					DataLockItem.SetValue("CorrespondentNodeCode", CircuitPeerNode.CorrespondentNodeCode);
					DataLockItem.Mode = DataLockMode.Exclusive;
					DataLock.Lock();

					Record = InformationRegisters.SynchronizationCircuit.CreateRecordManager();
					Record.InfobaseNode = Undefined;
					Record.NodeCode = CircuitPeerNode.NodeCode;
					Record.CorrespondentNodeCode = CircuitPeerNode.CorrespondentNodeCode;
					Record.Read();
					Record.Delete();

					CommitTransaction();
				Except
					RollbackTransaction();

					ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

					Event = NStr("vi = 'Контроль зацикливания.Обновление контура синхронизации';
								|ru = 'Контроль зацикливания.Обновление контура синхронизации';
								|en = 'Loop control.Update the synchronization circuit'; fa = 'Loop control.Update the synchronization circuit';
								|it = 'Контроль зацикливания.Обновление контура синхронизации';
								|pl = 'Loop control.Update the synchronization circuit';
								|tr = 'Контроль зацикливания.Обновление контура синхронизации'", Common.DefaultLanguageCode());

					WriteLogEvent(Event, EventLogLevel.Error,
						Metadata.InformationRegisters.SynchronizationCircuit, , ErrorMessage);
				EndTry;
				
			EndDo;
			
		EndIf;
		
		If CircuitNodes.Count() = 0
			Or (CircuitNodes[0].LatestUpdate < TreeNode.LatestUpdate 
			And CircuitNodes[0].RecordsCount > 0) Then
			
			For Each TreePeerNode In TreeNode.Rows Do
				
				Record = InformationRegisters.SynchronizationCircuit.CreateRecordManager();
				Record.InfobaseNode = Undefined;
				Record.NodeCode = TreeNode.NodeCode;
				Record.NodeName = TreeNode.NodeName;
				Record.CorrespondentNodeCode = TreePeerNode.CorrespondentNodeCode;
				Record.PeerInfobaseNodeName = TreePeerNode.PeerInfobaseNodeName;
				Record.LatestUpdate = TreeNode.LatestUpdate;
				Record.Prefix = TreeNode.Prefix;
				Record.Looping = TreePeerNode.Looping;
				Record.Write();
				
			EndDo;
			
		EndIf;
		
	EndDo;
			
EndProcedure

Procedure ReplacePrefixes()
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Circuit1.InfobaseNode AS InfobaseNode,
	|	Circuit1.NodeCode AS NodeCode,
	|	Circuit1.CorrespondentNodeCode AS CorrespondentNodeCode,
	|	Circuit2.NodeCode AS NewCodeOfPeerNode
	|FROM
	|	InformationRegister.SynchronizationCircuit AS Circuit1
	|		INNER JOIN InformationRegister.SynchronizationCircuit AS Circuit2
	|		ON Circuit1.CorrespondentNodeCode = Circuit2.Prefix";

	Selection = Query.Execute().Select();

	While Selection.Next() Do
		BeginTransaction();

		Try
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.SynchronizationCircuit");
			DataLockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
			DataLockItem.SetValue("NodeCode", Selection.NodeCode);
			DataLockItem.SetValue("CorrespondentNodeCode", Selection.CorrespondentNodeCode);
			DataLockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();

			Record = InformationRegisters.SynchronizationCircuit.CreateRecordManager();
			FillPropertyValues(Record, Selection);
			Record.Read();
			Record.CorrespondentNodeCode = Selection.NewCodeOfPeerNode;
			Record.LatestUpdate = ToUniversalTime(CurrentSessionDate());
			Record.Write();

			CommitTransaction();
		Except
			RollbackTransaction();

			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

			Event = NStr("vi = 'Контроль зацикливания.Замена префиксов';
						|ru = 'Контроль зацикливания.Замена префиксов';
						|en = 'Loop control.Replace the prefix'; fa = 'Loop control.Replace the prefix';
						|it = 'Контроль зацикливания.Замена префиксов';
						|pl = 'Loop control.Replace the prefix';
						|tr = 'Контроль зацикливания.Замена префиксов'", Common.DefaultLanguageCode());

			WriteLogEvent(Event, EventLogLevel.Error,
				Metadata.InformationRegisters.SynchronizationCircuit, , ErrorMessage);
		EndTry;

	EndDo;
	
EndProcedure

Procedure SetLoopFlag(NodesList = Undefined)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Circuit.InfobaseNode AS InfobaseNode,
		|	Circuit.NodeCode AS NodeCode,
		|	Circuit.CorrespondentNodeCode AS CorrespondentNodeCode
		|FROM
		|	InformationRegister.SynchronizationCircuit AS Circuit
		|WHERE
		|	Circuit.InfobaseNode <> UNDEFINED
		|	AND Circuit.CorrespondentNodeCode IN(&NodesList)";
	
	Query.SetParameter("NodesList", NodesList);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		BeginTransaction();

		Try
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.SynchronizationCircuit");
			DataLockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
			DataLockItem.SetValue("NodeCode", Selection.NodeCode);
			DataLockItem.SetValue("CorrespondentNodeCode", Selection.CorrespondentNodeCode);
			DataLockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();

			Record = InformationRegisters.SynchronizationCircuit.CreateRecordManager();
			FillPropertyValues(Record, Selection);
			Record.Read();
			Record.Looping = True;
			Record.LatestUpdate = ToUniversalTime(CurrentSessionDate());
			Record.Write();

			CommitTransaction();
		Except
			RollbackTransaction();

			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

			Event = NStr("vi = 'Контроль зацикливания.Изменение признака зацикливание';
						|ru = 'Контроль зацикливания.Изменение признака зацикливание';
						|en = 'Loop control.Change the looping flag'; fa = 'Loop control.Change the looping flag';
						|it = 'Контроль зацикливания.Изменение признака зацикливание';
						|pl = 'Loop control.Change the looping flag';
						|tr = 'Контроль зацикливания.Изменение признака зацикливание'", Common.DefaultLanguageCode());

			WriteLogEvent(Event, EventLogLevel.Error,
				Metadata.InformationRegisters.SynchronizationCircuit, , ErrorMessage);
		EndTry;
		
		InformationRegisters.CommonInfobasesNodesSettings.SetLoop(Selection.InfobaseNode, True);
			
	EndDo;
	
	RefreshReusableValues();
	
EndProcedure

Procedure ClearLoopFlag()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Circuit.InfobaseNode AS InfobaseNode,
		|	Circuit.NodeCode AS NodeCode,
		|	Circuit.CorrespondentNodeCode AS CorrespondentNodeCode
		|FROM
		|	InformationRegister.SynchronizationCircuit AS Circuit";
		
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		BeginTransaction();

		Try
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.SynchronizationCircuit");
			DataLockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
			DataLockItem.SetValue("NodeCode", Selection.NodeCode);
			DataLockItem.SetValue("CorrespondentNodeCode", Selection.CorrespondentNodeCode);
			DataLockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();

			Record = InformationRegisters.SynchronizationCircuit.CreateRecordManager();
			FillPropertyValues(Record, Selection);
			Record.Read();
			Record.Looping = False;
			Record.LatestUpdate = ToUniversalTime(CurrentSessionDate());
			Record.Write();

			CommitTransaction();
		Except
			RollbackTransaction();

			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

			Event = NStr("vi = 'Контроль зацикливания.Изменение признака зацикливания';
						|ru = 'Контроль зацикливания.Изменение признака зацикливания';
						|en = 'Loop control.Change the looping flag'; fa = 'Loop control.Change the looping flag';
						|it = 'Контроль зацикливания.Изменение признака зацикливания';
						|pl = 'Loop control.Change the looping flag';
						|tr = 'Контроль зацикливания.Изменение признака зацикливания'", Common.DefaultLanguageCode());

			WriteLogEvent(Event, EventLogLevel.Error,
				Metadata.InformationRegisters.SynchronizationCircuit, , ErrorMessage);
		EndTry;
		
		InformationRegisters.CommonInfobasesNodesSettings.SetLoop(Selection.InfobaseNode, False, False);
			
	EndDo;
	
	RefreshReusableValues();
	
EndProcedure

Procedure DeletePeerNode(NodeCode, CorrespondentNodeCode)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Circuit.InfobaseNode AS InfobaseNode,
		|	Circuit.NodeCode AS NodeCode,
		|	Circuit.CorrespondentNodeCode AS CorrespondentNodeCode
		|FROM
		|	InformationRegister.SynchronizationCircuit AS Circuit
		|WHERE
		|	Circuit.NodeCode = &NodeCode
		|	AND Circuit.CorrespondentNodeCode = &CorrespondentNodeCode";
	
	Query.SetParameter("NodeCode", CorrespondentNodeCode);
	Query.SetParameter("CorrespondentNodeCode", NodeCode);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		BeginTransaction();

		Try
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.SynchronizationCircuit");
			DataLockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
			DataLockItem.SetValue("NodeCode", Selection.NodeCode);
			DataLockItem.SetValue("CorrespondentNodeCode", Selection.CorrespondentNodeCode);
			DataLockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();

			Record = InformationRegisters.SynchronizationCircuit.CreateRecordManager();
			FillPropertyValues(Record, Selection);
			Record.Read();
			Record.Delete();

			CommitTransaction();
		Except
			RollbackTransaction();

			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

			Event = NStr("vi = 'Контроль зацикливания.Удаление записи';
						|ru = 'Контроль зацикливания.Удаление записи';
						|en = 'Loop control.Delete the record'; fa = 'Loop control.Delete the record';
						|it = 'Контроль зацикливания.Удаление записи';
						|pl = 'Loop control.Delete the record';
						|tr = 'Контроль зацикливания.Удаление записи'", Common.DefaultLanguageCode());

			WriteLogEvent(Event, EventLogLevel.Error,
				Metadata.InformationRegisters.SynchronizationCircuit, , ErrorMessage);
		EndTry; 
		
	EndDo;
	
EndProcedure

Function XMLBasicSchema()
	
	Return "http://www.1c.ru/SSL/Exchange/Message";
	
EndFunction

#EndRegion
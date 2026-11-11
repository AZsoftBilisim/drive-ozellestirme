///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MasterNode = Constants.MasterNode.Get();
	
	If Not ValueIsFilled(MasterNode) Then
		Raise NStr("vi = 'Nút chính chưa được lưu.';
					|ru = 'Главный узел не сохранен.';
					|en = 'The master node is not saved.'; fa = 'The master node is not saved.';
					|it = 'Nodo principale non salvato.';
					|pl = 'Węzeł główny nie został zapisany.';
					|tr = 'Ana düğüm kaydedilmedi.'");
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Raise NStr("vi = 'Đã thiết lập nút chính.';
					|ru = 'Главный узел установлен.';
					|en = 'The master node is set.'; fa = 'The master node is set.';
					|it = 'Nodo principale impostato.';
					|pl = 'Węzeł główny został zapisany.';
					|tr = 'Ana düğüm belirlendi.'");
	EndIf;
	
	Items.WarningText.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.WarningText.Title, String(MasterNode));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	ReconnectAtServer();
	
	Close(New Structure("Cancel", False));
	
EndProcedure

&AtClient
Procedure Disconnect(Command)
	
	DisconnectAtServer();
	
	Close(New Structure("Cancel", False));
	
EndProcedure

&AtClient
Procedure ExitApplication(Command)
	
	Close(New Structure("Cancel", True));
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure DisconnectAtServer()
	
	BeginTransaction();
	Try
		
		MasterNode = Constants.MasterNode.Get();
		
		MasterNodeManager = Constants.MasterNode.CreateValueManager();
		MasterNodeManager.Value = Undefined;
		InfobaseUpdate.WriteData(MasterNodeManager);
		
		If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
			If Common.IsStandaloneWorkplace() Then
				ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
				ModuleStandaloneMode.WhenConfirmingDisconnectionOfCommunicationWithTheMasterNode();
			EndIf;
		EndIf;
			
		If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			ModuleDataExchangeServer.DeleteSynchronizationSettingsForMasterDIBNode(MasterNode);
		EndIf;
		
		StandardSubsystemsServer.RestorePredefinedItems();
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

&AtServerNoContext
Procedure ReconnectAtServer()
	
	MasterNode = Constants.MasterNode.Get();
	
	ExchangePlans.SetMasterNode(MasterNode);
	
EndProcedure

#EndRegion

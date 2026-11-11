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
	
	// Verify that the form is opened with the required parameters
	If Not Parameters.Property("ExchangePlanName") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		Items.FormSetNewCode.Enabled = False;
		Items.GroupPanel.CurrentPage = Items.ServiceWorkPage;
		
	EndIf;
	
	ExchangePlanName = Parameters.ExchangePlanName;
	InfobaseNode = ExchangePlans[ExchangePlanName].ThisNode();	
	
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetNewCode(Command)
	
	If InstallANewCodeOnTheServer() Then
		Close();	
	EndIf;
	
EndProcedure

&AtServer
Function InstallANewCodeOnTheServer()
	
	BeginTransaction();
	Try
		
		DataLock = New DataLock;
		
		DataLockItem = DataLock.Add("ExchangePlan." + ExchangePlanName);
		DataLockItem.SetValue("Ref", InfobaseNode);
				
		DataLock.Lock();

		ExchangeNodeObject = InfobaseNode.GetObject();
		ExchangeNodeObject.Code = String(New UUID);
		ExchangeNodeObject.DataExchange.Load = True;
		ExchangeNodeObject.Write();
						
		CommitTransaction();
		
		Return True;
		
	Except
				
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	Return False;
	
EndFunction

&AtClient
Procedure CloseForm(Command)
	
	Close()
	
EndProcedure

#EndRegion

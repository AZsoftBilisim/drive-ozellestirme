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
	
	If Not Parameters.Property("Peer")
		Or Not Parameters.Property("TransportID")
		Or Not Parameters.Property("AccountPasswordRecoveryAddress")
		Or Not Parameters.Property("AutomaticSynchronizationSetup") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'",
			Common.DefaultLanguageCode());
		
	EndIf;
	
	DataExchangeServer.CheckExchangeManagementRights();
	
	SetPrivilegedMode(True);
	
	AccountPasswordRecoveryAddress = Parameters.AccountPasswordRecoveryAddress;
	AutomaticSynchronizationSetup = Parameters.AutomaticSynchronizationSetup;
	
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		Items.InternetAccessParameters.Visible = True;
	Else
		Items.InternetAccessParameters.Visible = False;
	EndIf;
		
	FillPropertyValues(ThisForm, Parameters,
		"Peer,TransportID,AccountPasswordRecoveryAddress,AutomaticSynchronizationSetup");
	
	TransportSettings = ExchangeMessagesTransport.TransportSettings(Peer, TransportID);
		
	If Not IsBlankString(TransportSettings.UserName) Then
		User = Users.FindByName(TransportSettings.UserName);
	EndIf;
	
	For Each SynchronizationUser In DataSynchronizationUsers() Do
		Items.User.ChoiceList.Add(SynchronizationUser.User, SynchronizationUser.Presentation);
	EndDo;
		
	Items.ForgotPassword.Visible = Not IsBlankString(AccountPasswordRecoveryAddress);
	
	If ValueIsFilled(TransportSettings.Password) Then
		
		Password = Common.ReadDataFromSecureStorage(TransportSettings.Password);
		
	Else
		
		TransportSettings.Password = String(New UUID);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckConnectionAndClose(Command)
	
	Cancel = False;
	TestServiceConnection(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	If AutomaticSynchronizationSetup Then
		
		Notify("Write_ExchangeTransportSettings",
			New Structure("AutomaticSynchronizationSetup"));
		
	EndIf;

	Close();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordOnChange(Item)
	PasswordChanged = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ForgotPassword(Command)
	
	ExchangeMessagesTransportClient.OpenInstructionHowToChangeDataSynchronizationPassword(AccountPasswordRecoveryAddress);
	
EndProcedure

&AtClient
Procedure InternetAccessParameters(Command)
	
	ExchangeMessagesTransportClient.OpenProxyServerParametersForm();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure TestServiceConnection(Cancel)
	
	SetPrivilegedMode(True);
	
	// Determine the user name.
	UserProperties = Users.IBUserProperies(
		Common.ObjectAttributeValue(User, "IBUserID"));

	TransportParameters = ExchangeMessagesTransport.InitializationParameters();
	TransportParameters.Peer = Peer;
	TransportParameters.TransportID = TransportID;
	TransportParameters.TransportSettings = TransportSettings;
	
	Transport = ExchangeMessagesTransport.Initialize(TransportParameters); // DataProcessorObject.ExchangeMessageTransportWS
	Transport.Password = Password;
	
	If UserProperties <> Undefined Then
		Transport.UserName = UserProperties.Name
	EndIf;
	
	If Transport.ConnectionIsSet() Then
		
		TransportSettings.UserName = Transport.UserName;
		TransportSettings.RememberPassword = True;
		
		ExchangeMessagesTransport.SaveTransportSettings(Peer, TransportID, TransportSettings, True);
		
		// Connection check is completed successfully. Writing password if it has been changed
		If PasswordChanged Then
			Common.WriteDataToSecureStorage(TransportSettings.Password, Password);
		EndIf
		
	Else
		
		Common.MessageToUser(Transport.ErrorMessage,, "Password",, Cancel);
		
	EndIf;
	
EndProcedure

&AtServer
Function DataSynchronizationUsers()
	
	Result = New ValueTable;
	Result.Columns.Add("User"); // Type: CatalogRef.Users
	Result.Columns.Add("Presentation");
	
	QueryText =
	"SELECT
	|	Users.Ref AS User,
	|	Users.Description AS Presentation,
	|	Users.IBUserID AS IBUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	NOT Users.DeletionMark
	|	AND NOT Users.Invalid
	|	AND NOT Users.IsInternal
	|
	|ORDER BY
	|	Users.Description";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If ValueIsFilled(Selection.IBUserID) Then
			
			IBUser = InfoBaseUsers.FindByUUID(Selection.IBUserID);
			
			If IBUser <> Undefined
				And DataExchangeServer.DataSynchronizationPermitted(IBUser) Then
				
				FillPropertyValues(Result.Add(), Selection);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

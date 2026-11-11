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
	
	If Not Parameters.Property("Peer") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", 
			Common.DefaultLanguageCode());
		
	EndIf;
	
	SetConditionalAppearance();
	
	InitializationOfFormAttributes();
	
	InitializingFormElements();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
		
	If EventName = "TransportSettingsChanged" Then
		Filter = New Structure("TransportID", Parameter.TransportID);
		SearchResult = TypesOfTransport.FindRows(Filter);
		
		If SearchResult.Count() = 0 Then
			Return;
		EndIf;
		
		String = SearchResult[0];
		
		String.RequiredAttributesOfSettingsAreFilledIn = Parameter.RequiredAttributesOfSettingsAreFilledIn;
	EndIf;
		
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TypesOfTransportOnActivateRow(Item)
	
	CurrentData = Items.TypesOfTransport.CurrentData; 
	Items.TypesOfTransportUseByDefault.Check = CurrentData.DefaultSetting;
	
EndProcedure 

&AtClient
Procedure TypesOfTransportSelection(Item, RowSelected, Field, StandardProcessing)
	
	If StrFind(Field.Name, "Flag") Then
		UseByDefault("");
	ElsIf StrFind(Field.Name, "Help") Then
		Help("");
	Else
		Customize("");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UseByDefault(Command)
		
	CurrentData = Items.TypesOfTransport.CurrentData;
	
	If CurrentData.DefaultSetting Then
		Return;
	EndIf;
	
	If Not CurrentData.HasSettings Then
		
		Text = NStr("vi = 'Невозможно установить тип транспорта, который не настроен используемым по умолчанию.';
					|ru = 'Невозможно установить тип транспорта, который не настроен используемым по умолчанию.';
					|en = 'Cannot set the unconfigured transport type as the default one.'; fa = 'Cannot set the unconfigured transport type as the default one.';
					|it = 'Невозможно установить тип транспорта, который не настроен используемым по умолчанию.';
					|pl = 'Cannot set the unconfigured transport type as the default one.';
					|tr = 'Невозможно установить тип транспорта, который не настроен используемым по умолчанию.'",
			CommonClient.DefaultLanguageCode());
		
		CommonClient.MessageToUser(Text);
			
		Return;
		
	EndIf;
	
	TransportID = CurrentData.TransportID;
	
	ExchangeMessageTransportServerCall.AssignDefaultTransport(Peer, TransportID);
	
	For Each String In TypesOfTransport Do
		
		If String.TransportID = TransportID Then
			String.PictureFlag = PictureLib.DefaultTransport;
			String.DefaultSetting = True;
		Else
			String.PictureFlag = Undefined;
			String.DefaultSetting = False;
		EndIf;
			
	EndDo;
	
	Items.TypesOfTransportUseByDefault.Check = True;
	
EndProcedure

&AtClient
Procedure Customize(Command)
	
	CurrentData = Items.TypesOfTransport.CurrentData;
	TransportID = CurrentData.TransportID;
	
	FullNameOfConfigurationForm = ExchangeMessageTransportServerCall.FullNameOfConfigurationForm(TransportID);
	
	If CurrentData.HasSettings Then
		TransportSettings = ExchangeMessageTransportServerCall.TransportSettings(
			Peer, TransportID);
	Else
		TransportSettings = New Structure;
	EndIf;
	
	FormParameters = New Structure("TransportSettings", TransportSettings);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Peer", Peer);
	AdditionalParameters.Insert("TransportID", TransportID);
	
	Notification = New CallbackDescription("SaveTransportSettings", ThisObject, AdditionalParameters);
	
	OpenForm(FullNameOfConfigurationForm, FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure Help(Command)
	
	CurrentData = Items.TypesOfTransport.CurrentData;
	OpenHelp(CurrentData.FullNameOfTransportProcessing);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializationOfFormAttributes()

	Parameters.Property("Peer", Peer);

	For Each String In ExchangeMessagesTransport.TableOfTransportParameters(Peer) Do
		
		NewRow = TypesOfTransport.Add();
		FillPropertyValues(NewRow, String);
		NewRow.PictureHelp = PictureLib.FormHelp;
		
	EndDo;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	TypesOfTransport.TransportID AS TransportID
		|INTO TT_TypesOfTransport
		|FROM
		|	&TypesOfTransport AS TypesOfTransport
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TransportSettings.DefaultSetting AS DefaultSetting,
		|	TransportSettings.TransportID AS TransportID,
		|	TransportSettings.Settings.(
		|		Ref AS Ref,
		|		LineNumber AS LineNumber,
		|		Setting AS Setting,
		|		Value AS Value
		|	) AS Settings
		|FROM
		|	TT_TypesOfTransport AS TT_TypesOfTransport
		|		LEFT JOIN Catalog.ExchangeMessageTransportSettings AS TransportSettings
		|		ON TT_TypesOfTransport.TransportID = TransportSettings.TransportID
		|WHERE
		|	TransportSettings.Peer = &Peer";
	
	Query.SetParameter("Peer", Peer);
	Query.SetParameter("TypesOfTransport", TypesOfTransport.Unload(,"TransportID"));
		
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		Filter = New Structure("TransportID", Selection.TransportID);
		SearchResult = TypesOfTransport.FindRows(Filter);
		
		If SearchResult.Count() = 0 Then
			Continue;
		EndIf;
		
		String = SearchResult[0];
		String.DefaultSetting = Selection.DefaultSetting;
		String.HasSettings = Not Selection.Settings.IsEmpty();
		If String.HasSettings Then
			String.RequiredAttributesOfSettingsAreFilledIn = ExchangeMessagesTransport.RequiredAttributesOfTransportSettingsHaveBeenFilledIn(Selection.Settings, Selection.TransportID);
		ElsIf String.DefaultSetting Then	
			String.RequiredAttributesOfSettingsAreFilledIn = True;
		Else
			String.RequiredAttributesOfSettingsAreFilledIn = False;
		EndIf;
		
		If Selection.DefaultSetting Then
			String.PictureFlag = PictureLib.DefaultTransport;
		EndIf;
		
	EndDo;
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
EndProcedure

&AtServer
Procedure InitializingFormElements()
	
	IsFullUser = Users.IsFullUser();
	Items.TypesOfTransportPictureFlag.Enabled = IsFullUser; 
	Items.TypesOfTransportUseByDefault.Enabled = IsFullUser;
	
	
	If Not DataExchangeServer.SynchronizationSetupCompleted(Peer) Then
		
		Items.PanelMain.CurrentPage = Items.SetupPageIsNotCompleted;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("TypesOfTransportAlias");
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
    FilterGroup.Use = True;
	
	FilterGroup2 = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
    FilterGroup2.Use = True;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TypesOfTransport.RequiredAttributesOfSettingsAreFilledIn");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TypesOfTransport.HasSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TypesOfTransport.DefaultSetting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;	
	
	Item.Appearance.SetParameterValue("Font", New Font(,,True));
	
EndProcedure

&AtClient
Procedure SaveTransportSettings(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	RequiredAttributesOfSettingsAreFilledIn = True;
	
	ExchangeMessageTransportServerCall.ProcessChangesToTransportSettings(
		AdditionalParameters.Peer,
		AdditionalParameters.TransportID,
		Result,
		RequiredAttributesOfSettingsAreFilledIn);
		
	CurrentData = Items.TypesOfTransport.CurrentData;
	CurrentData.HasSettings = True;
	CurrentData.RequiredAttributesOfSettingsAreFilledIn = RequiredAttributesOfSettingsAreFilledIn;
		
EndProcedure

#EndRegion





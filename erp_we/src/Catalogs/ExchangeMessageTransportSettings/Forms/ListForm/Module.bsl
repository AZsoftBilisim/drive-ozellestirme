///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData.Property("TransportID")
		And ValueIsFilled(CurrentData.TransportID) Then
		StandardProcessing = False;
	Else
		Return;
	EndIf;
	
	FullNameOfConfigurationForm = ExchangeMessageTransportServerCall.FullNameOfConfigurationForm(
		CurrentData.TransportID);
		
	TransportSettings = ExchangeMessageTransportServerCall.TransportSettings(
		CurrentData.Peer, CurrentData.TransportID);
	
	FormParameters = New Structure("TransportSettings", TransportSettings);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Peer", CurrentData.Peer);
	AdditionalParameters.Insert("TransportID", CurrentData.TransportID);
	
	Notification = New CallbackDescription("SaveTransportSettings", ThisObject, AdditionalParameters);
	
	OpenForm(FullNameOfConfigurationForm, FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

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

	NotificationParameters = New Structure("RequiredAttributesOfSettingsAreFilledIn, TransportID", RequiredAttributesOfSettingsAreFilledIn, AdditionalParameters.TransportID);	
	Notify("TransportSettingsChanged", NotificationParameters);

EndProcedure

#EndRegion
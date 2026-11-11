///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure SetDataSynchronizationPassword(Val Peer, Val AuthenticationData) Export
	
	ExchangeMessagesTransport.SetDataSynchronizationPassword(Peer, AuthenticationData);
	
EndProcedure

Function FullNameOfFirstSetupForm(Val TransportID) Export
	
	Return ExchangeMessagesTransport.FullNameOfFirstSetupForm(TransportID)
	
EndFunction

Function FullNameOfConfigurationForm(Val TransportID) Export
	
	Return ExchangeMessagesTransport.FullNameOfConfigurationForm(TransportID)
	
EndFunction

Procedure SaveTransportSettings(Val Peer, Val TransportID, Val TransportSettings) Export
	
	ExchangeMessagesTransport.SaveTransportSettings(Peer, TransportID, TransportSettings);
	
EndProcedure

Function TransportSettings(Val Peer, Val TransportID) Export
	
	Return Catalogs.ExchangeMessageTransportSettings.TransportSettings(
		Peer, TransportID);
	
EndFunction

Procedure ProcessChangesToTransportSettings(Val Peer, Val TransportID, Val TransportSettings, RequiredAttributesOfSettingsAreFilledIn) Export
	
	SaveTransportSettings(
		Peer,
		TransportID,
		TransportSettings);
		
	RequiredAttributesOfSettingsAreFilledIn = ExchangeMessagesTransport.RequiredAttributesOfTransportSettingsHaveBeenFilledIn(TransportSettings, TransportID);
			
EndProcedure

#EndRegion

#Region Private

Function DefaultTransport(Val Peer) Export

	Return Catalogs.ExchangeMessageTransportSettings.DefaultTransport(Peer);
	
EndFunction

Function AssignDefaultTransport(Val Peer, Val TransportID) Export
	
	Catalogs.ExchangeMessageTransportSettings.AssignDefaultTransport(
		Peer, TransportID);
	
EndFunction

Function AuthenticationRequired(Val AuthenticationParameters, FormName) Export
	
	Return ExchangeMessagesTransport.AuthenticationRequired(AuthenticationParameters, FormName);
	
EndFunction

#EndRegion
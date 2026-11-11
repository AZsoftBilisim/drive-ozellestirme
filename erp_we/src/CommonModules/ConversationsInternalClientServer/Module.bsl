///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function ExternalSystemsTypes() Export

	IntegrationsTypes = New Structure;
	IntegrationsTypes.Insert("Max", "MAX");
	IntegrationsTypes.Insert("Telegram", "Telegram");
	IntegrationsTypes.Insert("VKontakte", "VK");
	IntegrationsTypes.Insert("WhatsApp", "WhatsApp Devino");
	IntegrationsTypes.Insert("WebChat", "WebChat");
	IntegrationsTypes.Insert("Webhook", "Webhook");
	
	Return IntegrationsTypes;

EndFunction

#EndRegion
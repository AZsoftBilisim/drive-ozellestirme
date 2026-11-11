///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

//Work with external equipment
Var HLConnectedHardwareEventProcessed Export; // to prevent event re-processing
Var glConnectedEquipmentEventProcessedData Export; // to prevent event re-processing
Var HLAvailableTypesOfEquipment Export;
//End Work with external equipment

// StandardSubsystems

// Storage of global variables.
//
// Application Parametersapplication - Matching from Key Value:
//   * Key String - the name of the variable in the format "Library name.The name of the variable";
//   * Value - Arbitrary - variable value.
//
// Initialization example:
//   Parameter name = "Standard Subsystems.Messages for the Registration Log";
//   If the Application parametersapplication[Parameter Name] = Undefined Then
//     Application parametersapplication.Insert(Parameter name, New list of values);
//   The end if;
//  
// Usage example:
//   Application parameters["Standard subsystems.Messages for the Registration Log"].Add(...);
//   Application parameters["Standard subsystems.Messages for the Registration Log"] = ...;
Var ApplicationParameters Export;

// End StandardSubsystems

#EndRegion

#Region EventHandlers

Procedure BeforeStart()
	
	#If MobileClient Then
		If MainServerAvailable() = False Then
			If ApplicationParameters = Undefined Then
				ApplicationParameters = New Map;
			EndIf;
			Return;
		EndIf;
	#EndIf
	
	// StandardSubsystems
	#If MobileClient Then
		Execute("StandardSubsystemsClient.BeforeStart()");
	#Else
		StandardSubsystemsClient.BeforeStart();
	#EndIf
	// End StandardSubsystems
	
EndProcedure

Procedure OnStart()
	
	// StandardSubsystems
	#If MobileClient Then
		Execute("StandardSubsystemsClient.OnStart()");
	#Else
		StandardSubsystemsClient.OnStart();
	#EndIf
	// End StandardSubsystems
	
EndProcedure

Procedure BeforeExit(Cancel, WarningText)
	
	// StandardSubsystems
	#If MobileClient Then
		Execute("StandardSubsystemsClient.BeforeExit(Cancel, WarningText)");
	#Else
		StandardSubsystemsClient.BeforeExit(Cancel, WarningText);
	#EndIf
	// End StandardSubsystems
	
EndProcedure

Procedure ExternEventProcessing(Source, Event, Data)
	If Left(Source, 17) = "MobileApplication" Then
		#If MobileClient Then
			Execute("MobileAppsClient.ProcessExternalEventFromMobileApp(Source, Event, Data)");
		#Else
			MobileAppsClient.ProcessExternalEventFromMobileApp(Source, Event, Data);
		#EndIf
		Return;
	EndIf;
	If glConnectedEquipmentEventProcessedData <> Undefined
		And glConnectedEquipmentEventProcessedData[Data] <> Undefined Then
		glConnectedEquipmentEventProcessedData.Delete(Data);
		Return;
	EndIf;
	
	HLConnectedHardwareEventProcessed = False;
	
	// Peripherals
	#If MobileClient Then
		Execute("PELSubsystemsIntegrationClient.ExternEventProcessing(Source, Event, Data)");
	#Else
		PELSubsystemsIntegrationClient.ExternEventProcessing(Source, Event, Data);
	#EndIf
	// End Peripherals
	
EndProcedure

Procedure CollaborationSystemUsersChoiceFormGetProcessing(ChoicePurpose,
			Form, ConversationID, Parameters, SelectedForm, StandardProcessing)
	
	// StandardSubsystems
	#If MobileClient Then
		Execute("StandardSubsystemsClient.CollaborationSystemUsersChoiceFormGetProcessing(ChoicePurpose,
			|Form, ConversationID, Parameters, SelectedForm, StandardProcessing)");
	#Else
		StandardSubsystemsClient.CollaborationSystemUsersChoiceFormGetProcessing(ChoicePurpose,
			Form, ConversationID, Parameters, SelectedForm, StandardProcessing);
	#EndIf
	// End StandardSubsystems
	
EndProcedure

Procedure OnGlobalSearch(SearchString, SearchPlan)
	
		// StandardSubsystems
#If MobileClient Then
	Execute("StandardSubsystemsClient.OnGlobalSearch(SearchString, SearchPlan)");
#Else
	StandardSubsystemsClient.OnGlobalSearch(SearchString, SearchPlan);
#EndIf
	// End StandardSubsystems
	
EndProcedure

Procedure OnGlobalSearchResultChoice(ResultItem, StandardProcessing)
	
	// StandardSubsystems
#If MobileClient Then
	Execute("StandardSubsystemsClient.OnGlobalSearchResultChoice(ResultItem,
		|StandardProcessing)");
#Else
	StandardSubsystemsClient.OnGlobalSearchResultChoice(ResultItem,
		StandardProcessing);
#EndIf
	// End StandardSubsystems
	
EndProcedure

Procedure OnGlobalSearchResultActionChoice(ResultItem, Action)
	
	// StandardSubsystems
#If MobileClient Then
	Execute("StandardSubsystemsClient.OnGlobalSearchResultActionChoice(ResultItem,
		|Action)");
#Else
	StandardSubsystemsClient.OnGlobalSearchResultActionChoice(ResultItem, Action);
#EndIf
	// End StandardSubsystems

EndProcedure

Procedure NavigationByURLProcessing(URLNavigationData, StandardProcessing)
	
	// StandardSubsystems
#If MobileClient Then
	Execute("StandardSubsystemsClient.NavigationByURLProcessing(URLNavigationData,
		|StandardProcessing)");
#Else
	StandardSubsystemsClient.NavigationByURLProcessing(URLNavigationData,
		StandardProcessing);
#EndIf
	// End StandardSubsystems
	
EndProcedure

Procedure OnCollaborationSystemMessageButtonPanelButtonClick(Message, Button)
	#If MobileClient Then
		Execute("UserNotificationsOfEventsClient.OnCollaborationSystemMessageButtonPanelButtonClick(Message, Button)");
	#Else
		UserNotificationsOfEventsClient.OnCollaborationSystemMessageButtonPanelButtonClick(Message, Button);
	#EndIf
EndProcedure

#EndRegion

// The procedure checks for the need to exchange data at a specified interval
Procedure CheckingNeedForSynchronization() Export

#If MobileClient Then
	If MainServerAvailable() = True Then
		ExchangeMobileOfflineClient.StartExchange();
	EndIf;
#EndIf

EndProcedure

#If MobileClient Then
Procedure MonitoringSynchronization() Export
	
	ErrorText = "";
	If ExchangeMobileOfflineServer.DataExchangeIsOver(ApplicationParameters["StandardSubsystems.ObjectsOfTMCAERP.BackgroundJobIdentifier"], ErrorText) Then
		DetachIdleHandler("MonitoringSynchronization");
		If  ErrorText <> "" Then
			Message = New UserMessage();
			Message.Text = ErrorText;
			Message.Message();
		Else
			If MainServerAvailable() = True Then
				ExchangeMobileClient.NotifyAboutEnd();
			EndIf
		EndIf
	EndIf
	
EndProcedure
#EndIf

Procedure OnMainServerAvailabilityChange(MainServerSessionStart)
#If MobileClient Then
	If Not MainServerSessionStart Then
		ExchangeMobileOfflineClient.DisableWaitHandlers();
	Else
		If Not ValueIsFilled(ApplicationParameters) Then
			BeforeStart();
		EndIf;
	EndIf;
#EndIf
EndProcedure

#Region Initialize

HLConnectedHardwareEventProcessed = False;

#EndRegion
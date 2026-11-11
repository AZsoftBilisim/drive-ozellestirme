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
	
	// StandardSubsystems
	StandardSubsystemsClient.BeforeStart();
	// End StandardSubsystems
	
EndProcedure

Procedure OnStart()
	
	// StandardSubsystems
	StandardSubsystemsClient.OnStart();
	// End StandardSubsystems
	
EndProcedure

Procedure BeforeExit(Cancel, WarningText)
	
	// StandardSubsystems
	StandardSubsystemsClient.BeforeExit(Cancel, WarningText);
	// End StandardSubsystems
	
EndProcedure

Procedure ExternEventProcessing(Source, Event, Data)
	If Left(Source, 17) = "MobileApplication" Then
		MobileAppsClient.ProcessExternalEventFromMobileApp(Source, Event, Data);
		Return;
	EndIf;
	If glConnectedEquipmentEventProcessedData <> Undefined
		And glConnectedEquipmentEventProcessedData[Data] <> Undefined Then
		glConnectedEquipmentEventProcessedData.Delete(Data);
		Return;
	EndIf;
	
	HLConnectedHardwareEventProcessed = False;
	
	//Work with external equipment
	// Prepare data
	EventDescription1 = New Structure();
	ErrorDescription  = "";
	
	EventDescription1.Insert("Source", Source);
	EventDescription1.Insert("Event",  Event);
	EventDescription1.Insert("Data",   Data);
	
	// Submit data for processing
	Result = True;
	Result = EquipmentManagerClient.ProcessEventFromDevice(EventDescription1, ErrorDescription);
	
	If Not Result Then
		CommonClientServer.MessageToUser(NStr("vi = 'Đã xảy ra lỗi khi xử lý sự kiện bên ngoài từ thiết bị.';
												|ru = 'При обработке внешнего события от устройства произошла ошибка.';
												|en = 'An error occurred when processing an external event from the device.'; fa = 'An error occurred when processing an external event from the device.';
												|it = 'Errore durante l''elaborazione di un evento esterno al dispositivo.';
												|pl = 'Przy przetwarzaniu zdarzenia zewnętrznego od urządzenia zaistniał błąd.';
												|tr = 'Harici olayın cihazdan işlenmesi sırasında bir hata oluştu.'")
			+ Chars.LF + ErrorDescription);
	EndIf;
	//End Work with external equipment
	
EndProcedure

Procedure CollaborationSystemUsersChoiceFormGetProcessing(ChoicePurpose,
			Form, ConversationID, Parameters, SelectedForm, StandardProcessing)
	
	// StandardSubsystems
	StandardSubsystemsClient.CollaborationSystemUsersChoiceFormGetProcessing(ChoicePurpose,
		Form, ConversationID, Parameters, SelectedForm, StandardProcessing);
	// End StandardSubsystems
	
EndProcedure

#EndRegion

Procedure OnMainServerAvailabilityChange(MainServerSessionStart)

EndProcedure

#Region Initialize
GLContainerNumberSberbank     = 0;
GLEstablishedChannelWithSberbank = False;
HLConnectedHardwareEventProcessed = False;

#EndRegion
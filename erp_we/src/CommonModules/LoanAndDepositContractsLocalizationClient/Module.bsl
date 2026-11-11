#Region Internal

#Region ElementFormEventHandlers

// Event handler For opening the form of the directory element Contracts
//
// Parameters:
//  Cancel - Boolean - a sign of failure.
//  Form - ClientApplicationForm - the form for which the handler is executed.
//
Procedure OnOpen(Cancel, Form) Export
EndProcedure

// Event handler for handling the Announcement of the form of the directory element Contracts
//
// Parameters:
//  EventName - String - see the description of the platform method for processing the announcement
//  Parameter - AnyRef - see the description of the platform method for processing the announcement
//  Source - AnyRef - see the description of the platform method for processing the announcement
//  Form - ClientApplicationForm - the form for which the procedure is being performed.
//
Procedure NotificationProcessing(EventName, Parameter, Source, Form) Export
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

Procedure ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing, Form) Export
EndProcedure

// Handler for the change event
// 
// Parameters:
//     Item - FormField - Changed element.
//     Form - ClientApplicationForm - shape.
//
Procedure OnChangeAttribute(Item, Form) Export
EndProcedure

#EndRegion

#Region ElementFormCommandHandlers

Procedure ExecuteLocalizationCommand(Command, Form) Export
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FormCommandHandlers_Counterparties_Service

#EndRegion

#EndRegion

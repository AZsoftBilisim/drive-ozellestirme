#Region Public

#EndRegion

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
//  EventName - Arbitrary - event name;
//  Parameter   - Arbitrary - notification parameter;
//  Source   - Arbitrary - source of the alert.
//  Form      - ClientApplicationForm -//
Procedure NotificationProcessing(EventName, Parameter, Source, Form) Export
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

Procedure ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing, Form) Export
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
// 	Form - ClientApplicationForm
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



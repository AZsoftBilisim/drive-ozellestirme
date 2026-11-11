////////////////////////////////////////////////////////////////////////////////
// The module "Formclientserver Events" contains procedures and functions running on the client and server
// for form events.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Client-server overridable procedure that is called from the event handler of the element.
//
// Parameters:
//   Form                   - ClientApplicationForm - the form from which the procedure is called.
//   Item                 - String           - name of the source element of the "when changed" event.
//   AdditionalParameters - Structure        - values of additional parameters that affect processing.
//
Procedure WhenChangingElement(Form, Item, AdditionalParameters = Undefined) Export
	
	FormEventsClientServerLocalization.WhenChangingElement(Form, Item, AdditionalParameters);
	
EndProcedure

#EndRegion
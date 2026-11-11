#Region Public

#Region GeneralProceduresAndFunctionsOfPartnerCatalogForms

// Specifies whether to ask a question before closing the form
// 
// Parameters:
// 	Form - ClientApplicationForm - form being checked
// Returns:
// 	Boolean - A sign of the need for a question
//
Function NeedForQuestionBeforeClosing(Form) Export
	NecessityOfQuestion = False;
	Return NecessityOfQuestion;
	
EndFunction

// Checks the information of the head counterparty
// 
// Parameters:
// 	Form - ClientApplicationForm - the partner form
// 	Cancel - Boolean - sign of failure
Procedure InformationOfHeadCounterpartyIsFilledInIncorrectly(Form, Cancel) Export
EndProcedure

// Checks the primary information for correct filling in
// 
// Parameters:
// 	Form - ClientApplicationForm - handler form
// 	Cancel - Boolean - a sign of treatment failure
//
Procedure PrimaryInformationIsFilledInIncorrectly(Form, Cancel) Export
EndProcedure

// Checks if necessary
// 
// Parameters:
// 	Form - ClientApplicationForm -
// Returns:
// 	Boolean - a search is needed
//
Function SearchForDetachedDetachedUnitsIsNeeded(Form) Export
	
	SearchNeeded = False;
	Return SearchNeeded
	
EndFunction

#EndRegion

#Region GeneralProceduresAndFunctionsOfCounterpartyFormsElementInCatalog


// Add parameters to the new partner creation form
//
// Parameters:
//  CreationParameters	 - Structure - parameter structure
//  Form				 - ClientApplicationForm - reference form-bases
//
Procedure AddParametersForCreatingPartner(CreationParameters, Form) Export
EndProcedure

// Checks whether the TIN meets the requirements.
//
// Parameters:
//  Form          - ClientApplicationForm - form of the object being checked.
//  IsCheckOnly - Boolean - a sign that the TIN will only be checked, and the filling procedures will not be called.
//
Procedure CheckTIN_(Form, IsCheckOnly = False) Export
EndProcedure

// Checks the compliance of the OGRN with the requirements.
//
// Parameters:
//	Form - ClientApplicationForm - form of the object being checked.
//
Procedure CheckOGRN(Form) Export
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region FormEventHandlers_Counterparties

// Event handler Before recording the form of the Contractors directory element
//
// Parameters:
//  Cancel           - Boolean - indicates that the form was not created.
//  WriteParameters - Structure - structure containing the record parameters.
//  Form           - ClientApplicationForm - the form for which the handler is executed.
//
Procedure BeforeRecordingCounterparty(Cancel, WriteParameters, Form) Export
EndProcedure

#EndRegion

#Region EventHandlersForFormHeaderElements_Counterparty

Procedure ProcessingNavigationLinkOfForm_Counterparty(Item, FormattedStringURL, StandardProcessing, Form) Export
EndProcedure

Procedure WhenChangingBankingDetails_Counterparty(Item, Form) Export
EndProcedure

Procedure EndOfTextInput_Counterparty(Item, Text, ChoiceData, Parameters, StandardProcessing, Form) Export
EndProcedure

#EndRegion

#Region FormCommandHandlers_Counterparties

Procedure ExecuteLocalizationCommand(Command, Form) Export
EndProcedure

#EndRegion

#Region EventHandlersForFormHeaderElementsNewAssistant

// Handler On changing the bank in the New Form
// 
// Parameters:
//  Form - ClientApplicationForm - assistant Form.
//  Postfix - String - addition to the Attribute name on the Form.
//
Procedure WhenChangingBankLocalization(Form, Postfix) Export
	
	
	Return;
	
EndProcedure

#EndRegion

#Region OtherUtilityMethods

Procedure AddDataHistoryOfIPName(StringName, FillingData, AbbreviatedDescription, DescriptionFull) Export
EndProcedure


Procedure AddNameHistoryData(NameHistoryLine, AttributeNameAbbreviatedName, AbbreviatedDescription) Export
EndProcedure

#EndRegion




#EndRegion

#Region Private


#Region EventHandlersForFormHeaderElements_Counterparty_Service

#EndRegion

#Region FormCommandHandlers_Counterparties_Service
#EndRegion

#Region EventHandlersForFormHeaderElements_Assistant__Service

#EndRegion

#EndRegion

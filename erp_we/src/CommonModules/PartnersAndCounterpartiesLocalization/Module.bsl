#Region Public

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands_Counterparties(ReportsCommands, Parameters) Export
	
	ReportsOptionsLocalization.AddCounterpartyVerificationCommand(ReportsCommands);
	ReportsOptionsLocalization.AddCommandSearchForCounterparties(ReportsCommands);
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands_Partners(ReportsCommands, Parameters) Export
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	If UsePartnersAsCounterparties Then
		
		VisibilityInForms = "ItemForm,ListForm,ListFormWithoutFullTextSearch,CounterpartyAttributesItemForm";
		
		ReportsOptionsLocalization.AddCounterpartyVerificationCommand(ReportsCommands, VisibilityInForms);
		ReportsOptionsLocalization.AddCommandSearchForCounterparties(ReportsCommands, VisibilityInForms);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithForms

// Handler of the event for adding a form To the server of the partners directory element.
//
// Parameters:
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure SelectingHeadCounterpartyWhenCreatingItOnServer(Form, Cancel, StandardProcessing) Export
EndProcedure

#EndRegion

#Region SeparateBusinessUnits

// Searches for unconnected separate divisions
// 
// Parameters:
// 	Form - ClientApplicationForm - handler form
//
Procedure SearchForUnboundDetachedUnits(Form) Export
	
EndProcedure

#EndRegion

#Region ProceduresForCheckingCorrectnessOfFilling

// Checks whether the counterparty is filled in correctly. Is called from the procedure "Obrabatyvaniya".
//
// Parameters:
//  Object     - CatalogObject.Counterparties, ClientApplicationForm - an object containing the counterparty's data.
//  Counterparty - CatalogRef.Counterparties - link to the counterparty being checked.
//  Cancel      - Boolean - flag for refusal in the fill-in verification procedure.
//
Procedure CheckWhetherCounterpartyIsFilledInCorrectly(Object, Counterparty, Cancel) Export
EndProcedure

#EndRegion

#Region OtherProgrammingInterface

// Complements the values of the details of the selected counterparty.
//
// Parameters:
//  Counterparty - CatalogRef.Counterparties - Link to the counterparty.
//  CounterpartyDetails_ - Structure - details of the selected counterparty.
//  DateOfLastEdit - Date - date the information was received.
//
Procedure AddCounterpartyDetails(Counterparty, CounterpartyDetails_, DateOfLastEdit = Undefined) Export
EndProcedure


#EndRegion

#Region ProceduresAndFunctionsForSettingUpVATAccountingAtCommitteeSUSN

// Returns a table of current settings values for the list of counterparties as of the date.
// 
// Parameters:
// 	RegisterName - String - name of the information register.
// 	Counterparty - Array of CatalogRef.Counterparties - array of counterparty links.
// 	ValidityDate - Date - period of validity of settings.
// 	ReturnDefault - Boolean - a sign of the filling of default values 
// 		if passed false - returns an empty table.
//
// Returns:
// 	ValueTable - LongDesc:
// 		* Period - Date
// 		* BasicTaxation - EnumRef.VATTaxationTypes
// 		* VATRate - CatalogRef.VATRates
// 		* AccountingPoliciesExist - Boolean
//
Function TableOfCurrentTaxesAccountingPoliciesByCounterparty(RegisterName, Counterparty, ValidityDate = Undefined, ReturnDefault = True) Export
	
	QueryResultTable = New ValueTable();
	
	
	Return QueryResultTable;
	
EndFunction

// Fills in the description of the current accounting policy parameters on the form.
// 
// Parameters:
// 	Form - See Catalog.Counterparties.Form.ItemForm.
// 	Counterparty - CatalogRef.Counterparties - link to the contractors directory.
// 	RegisterName - String - name of the periodic register of information.
// 	ValidityDate - Date - data acquisition period.
//
Procedure FillInDescriptionOfCurrentCounterpartyParameters(Form, Counterparty, RegisterName = "", Val ValidityDate = "") Export
	

EndProcedure

// Returns a table of current settings values for the list of counterparties as of the date.
// 
// Parameters:
// 	RegisterName - String - name of the information register.
// 	Counterparty - Array of CatalogRef.Counterparties - array of counterparty links.
// 	ValidityDate - Date - period of validity of settings.
// 	ReturnDefault - Boolean - a sign of the filling of default values 
// 		if passed false - returns an empty table.
// 	ThrowException - Boolean - indicates whether an exception has been raised.
//
// Returns:
// 	Undefined - if there are no accounting settings entries, it is undefined.
// 	Structure Of the Key Value :
// 		Key String - the name of the Attribute from the PC "VAT accounting settings for USN Committees"
// 		Value - the value of the Attribute in the RS "VAT accounting settings for the Committees' USN".
//
Function CurrentParametersOfTaxesAccountingPoliciesOfCounterparties(RegisterName, Counterparty, Val ValidityDate = Undefined, ReturnDefault = True, ThrowException = False) Export
	
	
	Return Undefined;
	
EndFunction

// Forms a match between the case name and the form elements associated with the case.
//
// Returns:
// 	Map of KeyAndValue - Matching form elements, where:
// 		* Key - String - name of the setting.
// 		* Value - Structure:
//      ** ItemArray - array of form element names.
//      ** DescriptionElement - String - name of the form element to describe the setting.
//
Function MatchingCounterpartyFormElements()  Export
	
	MatchingElements = New Map();

	
	Return MatchingElements;
	
EndFunction

// Filling out the form PriceList - formanastroykesfillingstavnds.
// 
// Parameters:
//   Counterparty - CatalogRef.Counterparties - Contractor.
//   ValidityDate - Date - date of action.
//   VATRate - CatalogRef.VATRates - VAT rate.
//
Procedure GetCounterpartyTaxation(Counterparty, ValidityDate, VATRate) Export

	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region GeneralProceduresForCreatingPartnerCatalogElement

// Handler of the event for adding a form To the server of the partners directory element.
//
// Parameters:
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingPartnerElementFormOnServer(Form, Cancel, StandardProcessing) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

// Event handler for adding a New Partners directory to the server of the assistant form.
//
// Parameters:
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingNewFormOnServer(Form, Cancel, StandardProcessing) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

// The event handler precontamination the form, details of the counterpart directory of Partners
//
// Parameters:
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingCounterpartyDetailsElementFormOnServer(Form, Cancel, StandardProcessing) Export
	
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
	
EndProcedure

// Event handler for the postrecording Server of the Counterparty directory element form
//
// Parameters:
//  CurrentObject   - CatalogObject.Partners, CatalogObject.Counterparties - the object to be read.
//  WriteParameters - Structure - structure containing the record parameters.
//  Form           - ClientApplicationForm - the form for which the handler is executed.
//
Procedure AfterRecordingOnServerFormOfCounterpartySDetailsElement(CurrentObject, WriteParameters, Form) Export
EndProcedure

// Sets a conditional value for the form details of the Contractors directory element.
//
// Parameters:
//	Form - ClientApplicationForm - the form for which the conditional design is configured.
//
Procedure SetConditionalAppearance_ForNew(Form) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
EndProcedure

// Records the counterparty based on the Partner form data
// 
// Parameters:
// 	CounterpartyObject - CatalogObject.Counterparties - the counterparty to change.
// 	Form - ClientApplicationForm - form of directory Partners.
//
Procedure BeforeRecordingPartnerSCounterparty(CounterpartyObject, Form) Export
EndProcedure 

// Handler for creating a new head counterparty
// 
// Parameters:
// 	Form - ClientApplicationForm - new partner's assistant form
//
Procedure WhenCreatingNewHeadCounterparty(Form) Export
EndProcedure

// Complements the data of the partner's counterparty
// 
// Parameters:
// 	Receiver - CatalogObject.Counterparties - the reference to the counterparty
// 	Partner - CatalogRef.Partners - link to partner
// 	WithHistoricalData - Boolean - flag for adding historical data
//
Procedure AddPartnerCounterpartyData(Receiver, Partner, WithHistoricalData = True) Export
EndProcedure

// Complements the counterparty's data when recording
// 
// Parameters:
// 	CounterpartyObject_ - CatalogObject.Counterparties - created counterparty
// 	Form - ClientApplicationForm - data source form
//
Procedure AddCounterpartyDataWhenRecording(CounterpartyObject_, Form) Export
EndProcedure

// Complements the data of the head counterparty when recording
// 
// Parameters:
// 	HeadCounterpartyObject - CatalogObject.Counterparties - created counterparty
// 	Form                    - ClientApplicationForm - data source form
//
Procedure AddDataOfHeadCounterpartyWhenRecording(HeadCounterpartyObject, Form) Export
EndProcedure

// Fills in the counterparty's data
// 
// Parameters:
// 	CounterpartyData - Structure - data structure
// 	Cancel - Boolean - sign of failure
//
Procedure FillInCounterpartySDetailsUsingLink(CounterpartyData, Cancel) Export
EndProcedure

// Fills in the assistant form based on the counterparty's data
// 
// Parameters:
// 	CounterpartyData - Structure - data structure
// 	Form - ClientApplicationForm - form to fill in
//
Procedure FillInBasedOnCounterparty(CounterpartyData, Form) Export
EndProcedure

// Binds separate divisions
// 
// Parameters:
// 	Form - ClientApplicationForm - assistant form
//
Procedure LinkSeparateDivisions(Form) Export
	// linking separate divisions
	If Form.ThisIsACompany = 0 And Form.TypeOfCompany = 0 And ValueIsFilled(Form.TIN) And Form.LinkSeparateDivisions = 0 Then
		
		For Each TableRow In Form.SeparateBusinessUnits Do
			If TableRow.Selected Then
				
				ErrorDescription = "";
				PartnersAndCounterpartiesLocalizationServerCall.ChangeHeadCounterparty(TableRow.Counterparty, Form.TheCounterpartySelection, ErrorDescription);
				
				If Not IsBlankString(ErrorDescription) Then
					Raise ErrorDescription;
				EndIf;
				
			EndIf;
		EndDo;
		
	EndIf;
EndProcedure

// Fills in the selection list
// 
// Parameters:
// 	Form - ClientApplicationForm - handler form
//
Procedure FillInListOfSelectingHeadCounterparty(Form) Export
EndProcedure

#EndRegion

#Region GeneralProceduresAndFunctionsOfCounterpartyFormsElementInCatalog

// Handler for the event before Writing to the server of the Counterparty directory element form
//
// Parameters:
//  Cancel                - Boolean - indicates that the form was not created.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//
Procedure ProcessingFillCheckOnCounterpartyServer(Cancel, CheckedAttributes, Form) Export
	
EndProcedure

// Sets a conditional value for the form details of the Contractors directory element.
//
// Parameters:
//	Form - ClientApplicationForm - the form for which the conditional design is configured.
//
Procedure EstablishConditionalAppearanceCounterparty(Form) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
EndProcedure

// The event handler pictureisunrelated the form of a dictionary element Counterparties
//
// Parameters:
//  Form           - ClientApplicationForm - the form for which the handler is executed.
//
Procedure WhenReadingCreatingOnServerCounterparty(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

// Event handler Before recording the Contractors directory
// 
// Parameters:
// 	Object - CatalogObject.Counterparties - the object of the company.
// 	Cancel - Boolean - indicates that processing failed.
//
Procedure BeforeRecordingCounterparty(Object, Cancel) Export
EndProcedure

Procedure AtEndOfChangeOfProps_Counterparty(TagName, Form) Export
	
	
EndProcedure

Procedure ExecuteLocalizationCommand(Form, CommandName, ProcessingParameters) Export
EndProcedure

#EndRegion

#Region GeneralProceduresAndFunctionsOfListAndSelectionFormsInContractorsCatalog

// Event handler for Adding a server to the list form (parametric) of the Contractors directory
//
// Parameters:
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingParametricCounterpartyListFormOnServer(Form,  Cancel, StandardProcessing) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

// Event handler for Adding a server to the list form of the Business partners directory
//
// Parameters:
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingCounterpartyListFormOnServer(Form,  Cancel, StandardProcessing) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

// Event handler for the server Of the Counterparty directory selection form
//
// Parameters:
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingCounterpartySelectionFormOnServer(Form,  Cancel, StandardProcessing) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

// Event handler for the server Of the Counterparty directory selection form
//
// Parameters:
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingFormOnServerSelectHeadCounterparty(Form,  Cancel, StandardProcessing) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
	
EndProcedure

// Event handler for Adding a server to the list/select directory form Contractors
//
// Parameters:
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//  RequestWithCounterpartyInformation - Boolean - flag for a request with information about the counterparty
//
Procedure WhenCreatingPartnersListSelectionFormOnServer(Form, Cancel, StandardProcessing, RequestWithCounterpartyInformation = False) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

Procedure SetPropertiesOfDynamicListOfCounterparties(Form) Export
EndProcedure

Procedure SetPropertiesOfDynamicListOfContractorsSelectionForm(Form) Export
EndProcedure


#EndRegion

#Region GeneralProceduresAndFunctionsOfListAndCatalogSelectionForms

Function RequestTextForPartnersDynamicListWithInformationOnCounterparty() Export
EndFunction

#EndRegion

#Region SearchForDuplicatesOfPartnersCounterparties

Procedure FillInSummaryInformation(Summary, Form) Export
	Summary = StrReplace(Summary, "#WE#", "");
	TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#OG#");
	TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#OGI#");
	TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#SKD#");
	TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#DD#");
	TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#BA#");
	TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#OKPOCode#");
	TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#INN#");
	TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#OGRN#");
	TMCommonUseClientServer.RemoveSubstringFromString(Summary, "#OGRNIP#");
EndProcedure

Procedure SearchForPrimaryInformationCompletion(Form, DetailsPresentations) Export
EndProcedure

Procedure AddSearchStructure(Form, TheStructureOfTheSearch) Export
EndProcedure

Procedure BeforeCreatingPartnerInFormOfNewAssistant(Form, LegalEntityIndividual,  Cancel) Export
	
	
EndProcedure

Procedure AddSearchQueryText(QueryText, TheStructureOfTheSearch, BasedOnTheCounterparty) Export
EndProcedure

Procedure SetSearchQueryParameters(Form, Query) Export
EndProcedure

Procedure AddPresentationsOfSearchDetails(DetailsPresentations) Export
EndProcedure

Procedure PlaceTemporaryTablesOfCounterpartyDetails(DetailsPresentations, TheStructureOfTheSearch, DetailsOfInformationWithoutSearch, CounterpartyDetails_, Form) Export
EndProcedure

Procedure AddSummaryQueryBasedOnSearchStructure(SummaryQuery, TheStructureOfTheSearch) Export
	
EndProcedure

Procedure SetAdditionalConditionsForSummaryQuery(SummaryQuery) Export
EndProcedure

#EndRegion


#Region OtherUtilityMethods

Procedure ParseFileOnServer(FileRef, HasError, Form) Export
EndProcedure

// Gets the necessary data about the partner to display the list forms in the information panel 
// and select the "Partners"directory.
//
// Parameters:
//  PartnerData - Structure - information about the partner.
//  Partner        - CatalogRef.Partners - the partner for which you need to get information.
//
Procedure AddPartnerDataForInformationPanel(PartnerData, Partner) Export
EndProcedure

Procedure AddDetailsThatCannotBeEditedInGroupProcessingCounterparty(NotAttributesToEdit) Export
EndProcedure

// Fills in the information panel in the list form based on the partner's data.
// 
// Parameters:
//  Form     - ClientApplicationForm - a form that contains a dynamic list of partners.
//  Partner   - CatalogRef.Partners - the partner whose data is filled in the information panel.
//  PartnerData - Structure - the structure of the data partner.
//
Procedure FillInInformationPanelBasedOnPartnerData(Form, Partner, PartnerData) Export
EndProcedure


#EndRegion

#EndRegion

#Region Private

#Region GeneralProceduresForCreatingPartnerCatalogElement


#EndRegion

#Region AuxiliaryProceduresAndFunctions
#EndRegion

#EndRegion

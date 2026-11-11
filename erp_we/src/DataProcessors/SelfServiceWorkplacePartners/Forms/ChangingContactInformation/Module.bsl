
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser());
	
	If Partner = Undefined Or Partner.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	PartnersContactInformation.LineNumber           AS LineNumber,
	|	PartnersContactInformation.Type                   AS Type,
	|	PartnersContactInformation.Kind                   AS Kind,
	|	PartnersContactInformation.Presentation         AS Presentation,
	|	PartnersContactInformation.FieldValues         AS FieldValues,
	|	PartnersContactInformation.Country                AS Country,
	|	PartnersContactInformation.State                AS State,
	|	PartnersContactInformation.City                 AS City,
	|	PartnersContactInformation.EMAddress               AS EMAddress,
	|	PartnersContactInformation.ServerDomainName    AS ServerDomainName,
	|	PartnersContactInformation.PhoneNumber         AS PhoneNumber,
	|	PartnersContactInformation.PhoneNumberWithoutCodes AS PhoneNumberWithoutCodes
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnersContactInformation
	|WHERE
	|	PartnersContactInformation.Ref = &Partner
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("Partner",Partner);
	
	ContactInformation.Load(Query.Execute().Unload());
	
	// StandardSubsystems.ContactInformation
	AdditionalCIParameters = ContactsManager.ContactInformationParameters();
	AdditionalCIParameters.Insert("ItemForPlacementName", "ContactInformationGroup");
	AdditionalCIParameters.Insert("CITitleLocation", FormItemTitleLocation.Left);
	ContactsManager.OnCreateAtServer(ThisObject, ThisObject, AdditionalCIParameters);
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		
		PartnerSCounterparty = PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Partner);
		
		AdditionalCIParameters.Insert("ItemForPlacementName", "GroupContactInformationOfTheCounterparty");
		AdditionalCIParameters.Insert("CITitleLocation", FormItemTitleLocation.Left);
		AdditionalCIParameters.Insert("HiddenKinds",  TMCommonUseCached.ArrayOfExcludedTypesOfCounterpartyCIForOutputInPartnerForm());
		ContactsManager.OnCreateAtServer(ThisObject, PartnerSCounterparty, AdditionalCIParameters);
	
	EndIf;
	// End StandardSubsystems.ContactInformation
	
	Ref = Partner;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersContactInformation

&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	ContactsManagerClient.ToBeginUpdate(ThisObject, Item);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item, , StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	ContactsManagerClient.StartSelection(ThisObject, Item,, StandardProcessing);
EndProcedure

// Event handler for clearing contact information
// 
// Parameters:
// 	Item              - FormField -
// 	StandardProcessing - Boolean -
&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	ContactsManagerClient.StartClearing(ThisObject, Item.Name);
EndProcedure


// Executes the connected contact information command
// 
// Parameters:
// 	Command - FormCommand - 
//
&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	ContactsManagerClient.StartCommandExecution(ThisObject, Command.Name);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing);
	
EndProcedure

// Handling the selection of a contact information item
// 
// Parameters:
// 	Item              - FormField - 
// 	ValueSelected    - Arbitrary
// 	StandardProcessing - Boolean -
&AtClient
Procedure Attachable_ContactInformationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ContactsManagerClient.ChoiceProcessing(ThisObject, ValueSelected, Item.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	ContactsManagerClient.StartURLProcessing(ThisObject, Item, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContinueContactInformationUpdate(Result, AdditionalParameters) Export
	
	UpdateContactInformation(Result);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	RecordPartnerContactInformation();
	Notify("Write_Partners", New Structure("Partner",Partner));
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	RecordPartnerContactInformation();
	Notify("Write_Partners", New Structure("Partner",Partner));
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RecordPartnerContactInformation()
	
	If Modified Then
		
		SetPrivilegedMode(True);
		
		Cancel = False;
		PartnerObject = Partner.GetObject();
		ContactsManager.BeforeWriteAtServer(ThisForm, PartnerObject, Cancel);
		PartnerObject.Write();
		
		SetPrivilegedMode(False);
		
		If GetFunctionalOption("UsePartnersAsCounterparties") And ValueIsFilled(PartnerSCounterparty) Then
			CounterpartyObject = PartnerSCounterparty.GetObject();
			ContactsManager.BeforeWriteAtServer(ThisObject, CounterpartyObject);
			CounterpartyObject.Write();
		EndIf;
		Modified = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateContactInformation(Result)
	
	ContactsManager.UpdateContactInformation(ThisObject, Object, Result);
	
EndProcedure

#EndRegion

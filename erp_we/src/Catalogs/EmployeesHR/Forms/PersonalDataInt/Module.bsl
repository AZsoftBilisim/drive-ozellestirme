#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Individual = Parameters.Individual;
	
	ToInitializeForm();		
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DocumentsOfIndividualsHistory(Command)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Person", Individual);
	FilterStructure1.Insert("ThisIsAnIdentityDocument", True);
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Filter", FilterStructure1);
	FormOpenParameters.Insert("ReadOnly", ReadOnly);
	FormOpenParameters.Insert("FromThePersonalDataEditingForm", True);
	FormOpenParameters.Insert("CloseOnOwnerClose", True);
	
	OpenForm("InformationRegister.DocumentsPersons.Form.DocumentsPerson", FormOpenParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	 SaveAndCloseOnClient();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	Close();
	
EndProcedure

#EndRegion


#Region Private

&AtServer
Procedure ToInitializeForm()
	
	AdditionalParameters = ContactsManager.ContactInformationParameters();
	AdditionalParameters.ItemForPlacementName = "ContactInformationGroup";
	AdditionalParameters.CITitleLocation = FormItemTitleLocation.Top;
	
	ContactsManager.OnCreateAtServer(ThisObject, Individual, AdditionalParameters);
	CatalogsSalaryAndPersonnelServer.WhenCreatingEmployeeSPersonalDataATServer(
				ThisObject, Individual);
	
	EditRight = AccessRight("Update", Metadata.Catalogs.Persons);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ContactInformationGroup",
		"ReadOnly",
		Not EditRight);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ContactInformationActionGroup",
		"Enabled",
		EditRight); 

	
EndProcedure

// StandardSubsystems.ContactInformation

&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	If Not BlockPersonWhenEditing() Then
		Return;
	EndIf;
	ContactsManagerClient.ToBeginUpdate(ThisObject, Item);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	If Not BlockPersonWhenEditing() Then
		StandardProcessing = False;
		Return;
	EndIf;
	ContactsManagerClient.StartSelection(ThisObject, Item, , StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	If Not BlockPersonWhenEditing() Then
		StandardProcessing = False;
		Return;
	EndIf;
	ContactsManagerClient.StartSelection(ThisObject, Item, , StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	If Not BlockPersonWhenEditing() Then
		StandardProcessing = False;
		Return;
	EndIf;
	ContactsManagerClient.StartClearing(ThisObject, Item.Name);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	If Not BlockPersonWhenEditing() Then
		Return;
	EndIf;
	ContactsManagerClient.StartCommandExecution(ThisObject, Command.Name);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing);
	
EndProcedure

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

// End StandardSubsystems.ContactInformation

&AtClient
Function BlockPersonWhenEditing()
	Return True;
EndFunction

&AtClient
Procedure SaveAndCloseOnClient() Export 

	If Not ReadOnly Then
		
		If CheckFilling() Then
			
			RememberContactInformation();
		EndIf;
		
	EndIf; 
	
	Close();
	
EndProcedure  

&AtClient
Function BlockObjectInOwnerForm() Export
	
	Return True;
	
EndFunction

&AtServer
Procedure RememberContactInformation()
	
	IndividualObject = Individual.GetObject(); 
	
	CatalogsSalaryAndPersonnelServer.WriteDownIdentityDocument(ThisObject, Individual);
	
	// StandardSubsystems.ContactInformation
	ContactsManager.BeforeWriteAtServer(ThisObject, IndividualObject);
	// End StandardSubsystems.ContactInformation
	
	IndividualObject.Write();
	
EndProcedure

// StandardSubsystems.ContactInformation

&AtServer
Procedure UpdateContactInformation(Result)
	
	ContactsManager.UpdateContactInformation(ThisObject, Individual, Result);
	
EndProcedure
// End StandardSubsystems.ContactInformation

#EndRegion


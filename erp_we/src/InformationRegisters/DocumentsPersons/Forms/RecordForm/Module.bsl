
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetVisibilityAvailability(ThisObject);
	SetFormItemsProperties(ThisObject);
	
	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not Record.ThisIsAnIdentityDocument Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("SalaryCadresCorpSubsystems.HealthInsurance") Then
		ModuleHealthInsuranceForms = Common.CommonModule("HealthInsuranceForms");
		ModuleHealthInsuranceForms.CheckChangeOfIdentityDocumentFromRecordForm(Record);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If Record.ThisIsAnIdentityDocument Then
		WriteParameters = New Structure;
		WriteParameters.Insert("DocumentKind", Record.DocumentKind);
		WriteParameters.Insert("PassportSeries", Record.Series);
		WriteParameters.Insert("PassportNumber_", Record.Number);
		WriteParameters.Insert("PassportIssued", Record.IssuedBy);
		WriteParameters.Insert("PassportDateOfIssue", Record.DateOfIssue1);
		WriteParameters.Insert("Presentation", Record.Presentation);
		Notify("Write_DocumentIndividuals", WriteParameters, ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DocumentKindOnChange(Item)
	
	If IsIdentityCard(Record.Person, Record.DocumentKind, Record.Period) Then
		Record.ThisIsAnIdentityDocument = True;
	EndIf;
	
	SetFormItemsProperties(ThisObject);
	
EndProcedure

&AtClient
Procedure VehicleCategoriesStartChoice(Item, ChoiceData, StandardProcessing)
	Return; // in UT11 is not used
EndProcedure

&AtClient
Procedure VehicleCategoriesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("String") Then
		Record.VehicleCategories = ValueSelected;
	EndIf;	
	
EndProcedure

&AtClient
Procedure VehicleCategoriesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	Return; // in UT11 is not used
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function IsIdentityCard(Person, DocumentKind, Date)
	
	Return InformationRegisters.DocumentsPersons.IsIdentityCard(Person, DocumentKind, Date);
	
EndFunction

&AtClientAtServerNoContext
Procedure SetVisibilityAvailability(Form)
	Return; // in UT11 is not used
EndProcedure

&AtClientAtServerNoContext
Procedure SetFormItemsProperties(Form)
	
	
	CommonClientServer.SetFormItemProperty(
		Form.Items, 
		"VehicleCategories", 
		"Visible", 
		Form.Record.DocumentKind = PredefinedValue("Catalog.DocumentKindsOfPersons.DriverLicense"));
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	Return; // in UT11 is not used
EndProcedure

#EndRegion

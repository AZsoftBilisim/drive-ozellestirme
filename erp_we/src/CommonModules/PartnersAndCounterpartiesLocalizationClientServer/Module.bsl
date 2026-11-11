#Region Public

// Defines the type of legal Entity in the new assistant form
// 
// Parameters:
// 	ThisIsACompany - Number - indicates that the partner is a company
// 	TypeOfCompany - Number - company type
// Returns:
// 	EnumRef.LegalEntityIndividual - the transfer of the legal entity is obvious
//
Function CounterpartySLegalEntityType(ThisIsACompany, TypeOfCompany) Export
	
	If ThisIsACompany = 0 Then
		If TypeOfCompany = 0 Or TypeOfCompany = 3 Then
			Return PredefinedValue("Enum.LegalEntityIndividual.Entity");
		ElsIf TypeOfCompany = 1 Then
			Return PredefinedValue("Enum.LegalEntityIndividual.LegalEntityNonResident");
		Else
			Return PredefinedValue("Enum.LegalEntityIndividual.IndividualEntrepreneur"); 
		EndIf;
	Else
		Return PredefinedValue("Enum.LegalEntityIndividual.Person");
	EndIf;
	
EndFunction

// Retrieves the list of available tax registers of counterparty accounting policies.
//
// Returns:
//  Array - list of register names
//
Function AvailableRegistersOfTaxesAccountingPoliciesOfCounterparties() Export
	
	ArrayOfRegisters = New Array();

	
	Return ArrayOfRegisters;
	
EndFunction

// Fills in the Attributes of the form.
// 
// Parameters:
// 	Form - Form
// 		Catalog.Partners.The form.The formaelementarequizitycontragent
// 		Catalog.Counterparties.The form.The form of the element.
//
Procedure ManagingVisibilityOfCommitteeSVATAccountingSettings(Form) Export


EndProcedure

#EndRegion

#Region Internal

#Region AvailabilityControl

// Sets the availability of elements in the Contractors directory element form.
//
// Parameters:
//	Form - ClientApplicationForm - the form for which accessibility is configured.
//
Procedure ManagingCounterpartyAvailability(Form) Export
EndProcedure

// Sets the availability of elements in the Contractors directory element form.
//
// Parameters:
//	Form - ClientApplicationForm - the form for which accessibility is configured.
//
Procedure ManagingAvailabilityOfNameInTranscription(Form) Export 
	
	
EndProcedure

// Sets the availability of elements in the Contractors directory element form.
//
// Parameters:
//	Form - ClientApplicationForm - the form for which accessibility is configured.
//
Procedure AvailabilityManagementHeadCounterparty(Form) Export
EndProcedure

// Sets the availability and visibility of legal details: INN, KPP, KPO Code, head Agent,
// depending on the type of counterparty.
//
// Parameters:
//  Form - ClientApplicationForm - the form for which actions are performed.
//
Procedure ManagingElementsOfLegalDetails(Form) Export
	
EndProcedure


#EndRegion

#Region FillingInHeadCounterparty

// Add parameters to the head counterparty creation form
//
// Parameters:
//  CreationParameters	 - Structure - augmented parameter structure
//  DataSource		 - FormDataStructure, Structure - data for the selected row
//
Procedure AddParametersForHeadCounterparty(CreationParameters, DataSource = Undefined) Export
EndProcedure

#EndRegion

#Region OtherUtilityMethods

Procedure UpdateTitleHistoryLines(Val NameHistory, GoToNameHistory, ColorOfHyperlink) Export
	
TextIsSetInitially = NStr("vi = 'cài đặt ban đầu';
							|ru = 'установлено изначально';
							|en = 'set initially'; fa = 'set initially';
							|it = 'inizialmente impostato';
							|pl = 'jest określone pierwotnie';
							|tr = 'başlangıçta ayarlandı'");
	
	TextTheNameHistoryCommand = "";
	
	If NameHistory.Count() = 0 Then
		
		TextTheNameHistoryCommand = TextIsSetInitially;
		
	Else
		
		NameHistory.Sort("Period Desc");
		DateOfLastPeriod = NameHistory[0].Period;
		
		If ValueIsFilled(DateOfLastPeriod) Then
			
			TextTheNameHistoryCommand = StrTemplate(NStr("vi = 'được cài đặt từ %1';
														|ru = 'установлено с %1';
														|en = 'set from %1'; fa = 'set from %1';
														|it = 'impostato dal %1';
														|pl = 'jest określone od %1';
														|tr = '%1 ile ayarlandı'"), Format(DateOfLastPeriod,"DLF=D")); 
			
		Else
			
			TextTheNameHistoryCommand = TextIsSetInitially;
			
		EndIf;
		
	EndIf;
	
	GoToNameHistory = New FormattedString(TextTheNameHistoryCommand,,ColorOfHyperlink,, "NameHistory");

EndProcedure


#EndRegion

#EndRegion

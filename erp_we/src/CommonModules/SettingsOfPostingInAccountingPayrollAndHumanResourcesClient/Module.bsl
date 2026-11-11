
#Region Internal   

// Opens a Form for editing the HR accounting reflection settings and processes the result of closing it.
//
// Parameters:
//   Form - ClientApplicationForm - The Form from which editing is called
//   FormParameters - Structure - Parameters passed to the Form to open
//
Procedure EditReflectionSettings(Form, FormParameters) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
		
	ClosingNotification1 = New CallbackDescription("EditReflectionSettingsCompletion", ThisObject, AdditionalParameters);
	
	OpenForm("InformationRegister.SettingOfPostingInAccountingHR.Form.SettingsFormOfPostingInAccounting",
		FormParameters, Form, , , , ClosingNotification1);
	
EndProcedure

// Opens the Form for editing the HR accounting reflection settings in the document table.
//
// Parameters:
//   Form - ClientApplicationForm - The Form from which editing is called
//   FormParameters - Structure - Parameters passed to the Form to open
//
Procedure EditReflectionSettingsInDocumentTable(Form, FormParameters) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
		
	ClosingNotification1 = New CallbackDescription("EditReflectionSettingsCompletion", ThisObject, AdditionalParameters);
	
	OpenForm("InformationRegister.SettingOfPostingInAccountingHR.Form.SettingsFormOfPostingInAccounting",
		FormParameters, Form, , , , ClosingNotification1);
	
EndProcedure

// Returns display parameters for setting up the reflection in accounting.
//
// Returns:
//   Structure - Display parameters used to configure the reflection in accounting:
//       * VisibilityOfReflectionSetting - Boolean - Indicates the visibility of the accounting reflection setting.
//       * VisibilityOfAccountingReflectionSettings - Boolean - Indicates the visibility of the accounting reflection setting.
//
Function GetDisplayParameters() Export
	
	Return SettingsOfPostingInAccountingPayrollAndHumanResourcesServerCall.GetDisplayParameters(); 
	
EndFunction

#EndRegion

#Region Private

Procedure EditReflectionSettingsCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then  
		
		ResultParameters = New Structure("PostingOption", Result.PostingOption);
	
		Notify("DataWasSavedToRegisterOfReflectionInAccounting", ResultParameters, AdditionalParameters.Form);
		
	EndIf;
	
EndProcedure

#EndRegion
	
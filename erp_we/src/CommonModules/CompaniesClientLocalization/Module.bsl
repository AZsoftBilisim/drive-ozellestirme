#Region Public

// Checks that this is not a new directory item
// 
// Parameters:
// 	Form - ClientApplicationForm - handler form:
// 		* Object - CatalogObject -
// 	FormName - String - name of the subordinate form
// 	NotificationAfterRecording - CallbackDescription - LongDesc
// 	QueryText - String - question text
//
Procedure CheckThatItIsNotNewElement(Form, FormName, NotificationAfterRecording, QueryText = Undefined) Export
	
	// Let's check that this is not a new element of the directory.
	If Not ValueIsFilled(Form.Object.Ref) Then
		
		If QueryText = Undefined Then
			QueryText = NStr("vi = 'Vẫn còn chưa ghi lại dữ liệu.
			|Chỉ có thể chuyển đến ""%FormName%"" sau khi ghi lại.
			|Sẽ ghi lại dữ liệu.';
			|ru = 'Данные еще не записаны.
			|Переход к ""%FormName%"" возможен только после записи.
			|Данные будут записаны.';
			|en = 'Data is not saved yet.
			|You can go to ""%FormName%"" only after saving the data.
			|The data will be saved.'; fa = 'Data is not saved yet.
			|You can go to ""%FormName%"" only after saving the data.
			|The data will be saved.';
			|it = 'Данные еще не записаны.
			|Переход к ""%FormName%"" возможен только после записи.
			|Данные будут записаны.';
			|pl = 'Data is not saved yet.
			|You can go to ""%FormName%"" only after saving the data.
			|The data will be saved.';
			|tr = 'Veriler henüz kaydedilmedi.
			|""%FormName%"" geçiş sadece verilerin kaydından sonra mümkündür.
			|Veriler kaydedilecektir.'");
			QueryText = StrReplace(QueryText, "%FormName%", FormName);
		EndIf;
		NotificationParameters = New Structure("Notification, Form", NotificationAfterRecording, Form);
		ShowQueryBox(New CallbackDescription("CheckThatThisIsNotNewElementProcessingResponse", ThisObject, NotificationParameters), QueryText, QuestionDialogMode.OKCancel);
		Return;
		
	EndIf;
	
	RunCallback(NotificationAfterRecording);
	
EndProcedure

// Checks whether the TIN meets the requirements.
//
// Parameters:
//  TIN                - String - check the individual number of the taxpayer.
//  Object - CatalogObject.Companies - auditee.
//
Procedure CheckTIN_(TIN, Object) Export
EndProcedure

#EndRegion

#Region Internal

#Region ElementFormEventHandlers

// Event handler for the post-Recording of the Business directory element form
//
// Parameters:
//  WriteParameters - Structure - structure containing the record parameters.
//  Form           - ClientApplicationForm - the form for which the handler is executed.
//
Procedure AfterWrite(WriteParameters, Form) Export
EndProcedure

// Event handler for the post-Recording of the Business directory element form
//
// Parameters:
//  Cancel           - Boolean - a sign of failure.
//  WriteParameters - Structure - structure containing the record parameters.
//  Form           - ClientApplicationForm - the form for which the handler is executed.
//
Procedure BeforeWrite(Cancel, WriteParameters, Form) Export
	
EndProcedure

// Event handler for Processing the selection of A business directory element form
// 
// Parameters:
// 	ValueSelected - Arbitrary - the result of the selection in the subordinate form.
// 	ChoiceSource    - Arbitrary - Form-the source of the event.
//  Form             - ClientApplicationForm - the form for which the handler is executed.
//
Procedure ChoiceProcessing(ValueSelected, ChoiceSource, Form) Export
EndProcedure

// Event handler for handling an Announcement of A business directory element form
//
// Parameters:
//  EventName - String -
//  Parameter - Arbitrary -
//  Source - Arbitrary -
//  Form - ClientApplicationForm -
//
Procedure NotificationProcessing(EventName, Parameter, Source, Form) Export
EndProcedure

// Event handler For Closing a business directory element form
//
// Parameters:
//  Exit - Boolean - indicates that the job is finished.
//  Form - ClientApplicationForm - the form for which the handler is executed.
//
Procedure OnClose(Exit, Form) Export
EndProcedure

// Event handler For Closing a business directory element form
//
// Parameters:
//  Cancel - Boolean - a sign of failure.
//  Exit - Boolean - indicates that the job is finished.
//  WarningText - String - warning text.
//  StandardProcessing - Boolean - indicates standard processing.
//  Form - ClientApplicationForm - the form for which the handler is executed.
//
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing, Form) Export
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

Procedure Click_Organization(Item, StandardProcessing, Form) Export
EndProcedure

Procedure ProcessingNavigationLinkOf_OrganizationForm(Item, FormattedStringURL, StandardProcessing, Form) Export
EndProcedure

Procedure CopySettingsCompletion(Result, AddlParameters) Export
	If Result = Undefined Or Result = False Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure();
	EventName = "RecordingSettingsAndAccountingPolicies";
	Notify(EventName, NotificationParameters);
	
EndProcedure

Procedure OnChangeAttribute(Item, Form) Export
EndProcedure

Procedure EndOfTextEntry_Organization(Item, Text, ChoiceData, Parameters, StandardProcessing, Form) Export
EndProcedure

Procedure StartSelecting_Organization(Item, ChoiceData, StandardProcessing, Form) Export
EndProcedure

Procedure AutoComplete_Companies(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, Form) Export
	
	
EndProcedure

#EndRegion

#Region ElementFormCommandHandlers

// Execute the localization command.
// 
// Parameters:
//  Command - FormCommand - Command
//  Form - ClientApplicationForm - Form
Procedure ExecuteLocalizationCommand(Command, Form) Export
EndProcedure

#EndRegion

#Region EventHandlersForItemsInNameHistoryEditingForm

Procedure NameHistoryAbbreviatedDescriptionOnChange(CurrentData, Form) Export
EndProcedure

#EndRegion

#EndRegion

#Region Private


#Region OtherUtilityMethods

Procedure CheckThatThisIsNotNewElementProcessingResponse(ResponseCode, AdditionalParameters) Export
	
	If ResponseCode = DialogReturnCode.OK Then 
		Form = AdditionalParameters.Form; // ManagedFormExtensionForDocuments - 
		
		WriteParameters = New Structure;
		WriteParameters.Insert("NotCloseForm_", True);
		
		ItemRecorded = Form.Write(WriteParameters);
		
		If Not ItemRecorded Then
			Return;
		EndIf;
		
		Notification = AdditionalParameters.Notification;
		
		RunCallback(Notification);
		
	EndIf;
	
EndProcedure

Procedure AvailableRegistersOfTaxesAndAccountingPolicies(ArrayOfRegisters) Export
EndProcedure

// Dependent register.
// 
// Parameters:
//  RegisterName - String - Register name
// 
// Returns:
//  String - Name of the dependent register
Function DependentRegister(RegisterName) Export
	
	DependentRegister = ""; 
	
	
	Return DependentRegister;

EndFunction



#EndRegion

#EndRegion

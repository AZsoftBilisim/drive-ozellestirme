#Region Internal

// Called ON change of the employee's full name.
// Form parameters are being filled in.
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure OnChangingEmployeeSFullName(Form) Export
	
	If Not BlockPersonWhenEditing(Form) Then
		Return;
	EndIf;
	
	If Form.Object.Individual.IsEmpty() Then
		CheckNamesakes(Form);
	EndIf;
	
	OnChangingFullName(Form, Form.Individual, Form.FullNameOfPersons);
	
	CatalogsPayrollAndHumanResourcesClientOverridable.OnChangingFullName(Form, Form.Individual, Form.FullNameOfPersons);
	
EndProcedure

// Called when opening the Form of the Job Title directory element
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure JobTitlesWhenOpeningFormOfElement(Form) Export
	
	CatalogsPayrollAndHumanResourcesClientOverridable.JobTitlesWhenOpeningFormOfElement(Form);
	
EndProcedure	

// Called before writing the Form of the Employees directory element
//
// Parameters:
//  Form - ClientApplicationForm - the form from which the check is called:
//  	* Object - CatalogObject.EmployeesHR
//  Cancel - Boolean - The flag of failure 
//
Procedure EmployeesBeforeWritingItemForm(Form, Cancel) Export
	
	Object = Form.Object;
	
	If Not ValueIsFilled(Object.ParentCompany) Then
		
		ErrorMessage = NStr("ru = 'Не заполнена организация';
							|vi = 'Company is required';
							|en = 'Company is required'; fa = 'Company is required';
							|it = 'Company is required';
							|pl = 'Company is required';
							|tr = 'İş yeri bilgisi doldurulmamış'"); 
				
		CommonClient.MessageToUser(ErrorMessage, , "ParentCompany", "Object", Cancel); 
		
	EndIf;	

	If Not ValueIsFilled(Object.Description) Then
		
		ErrorMessage = NStr("ru = 'Не заполнено Полное имя сотрудника';
							|vi = 'Employees'' full name is required';
							|en = 'Employees'' full name is required'; fa = 'Employees'' full name is required';
							|it = 'Employees'' full name is required';
							|pl = 'Employees'' full name is required';
							|tr = 'Çalışanın tam adı doldurulmamış'"); 
				
		CommonClient.MessageToUser(ErrorMessage, , "Description", "Object", Cancel); 
		
	EndIf;	
	
	CatalogsPayrollAndHumanResourcesClientOverridable.EmployeesBeforeWritingItemForm(Form, Cancel);
	
EndProcedure	

// Blocks a person from editing
// 
// Parameters:
//  Form - ClientApplicationForm
//  ReportImpossibilityOfBlocking - Boolean -  Yes - Display a message
//   
// Returns:
// 		Boolean - True if blocked
//
Function BlockPersonWhenEditing(Form, ReportImpossibilityOfBlocking = True) Export
	
	If Not Form.PersonIsBlocked Then
		
		If Not CatalogsPayrollAndHumanResourcesServerCall.LockIndividualOnEditAtServer(Form.Individual.Ref, "", Form.UUID) Then
			
			If ReportImpossibilityOfBlocking Then
				
					ShowMessageBox(, NStr("ru = 'Не удается внести изменения в личные данные сотрудника. Возможно, уже открыта форма с личными данными.';
											|vi = 'Cannot change employee personal data. Form with personal data may have been opened.';
											|en = 'Cannot change employee personal data. Form with personal data may have been opened.'; fa = 'Cannot change employee personal data. Form with personal data may have been opened.';
											|it = 'Cannot change employee personal data. Form with personal data may have been opened.';
											|pl = 'Cannot change employee personal data. Form with personal data may have been opened.';
											|tr = 'Çalışanın kişisel verilerinde değişiklik yapılamıyor. Kişisel verilerin bulunduğu form zaten açık olabilir.'"));
				
			EndIf;
			
			Form.SetModeForViewingPersonalDataOnly();
			
			Return False;
			
		Else
			Form.PersonIsBlocked = True;
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region Private

Procedure OnChangingFullName(Form, Individual, RecordManagerFullName)
	
	LastFirstName = TrimAll(Individual.LastFirstName);
	While StrFind(LastFirstName, "  ") > 0 Do
		LastFirstName = StrReplace(LastFirstName, "  ", " ");
	EndDo;
	
	FullNameStructure = CatalogsPayrollAndHumanResourcesServerCall.FullName(LastFirstName);
	
	Individual.Initials = IndividualsPayrollAndHumanResourcesClientServer.InitialsByFirstNamePatronymic(
		FullNameStructure.Name, FullNameStructure.MiddleName);
	
	RecordManagerFullName.LastName = FullNameStructure.LastName;
	RecordManagerFullName.Name = FullNameStructure.Name;
	RecordManagerFullName.MiddleName = FullNameStructure.MiddleName;
	RecordManagerFullName.Initials = Individual.Initials;
	
	FullNameFull = IndividualsPayrollAndHumanResourcesClientServer.FullNameFromParts(RecordManagerFullName);
	EndOfFullName = StrReplace(LastFirstName, FullNameFull, "");
	If Not IsBlankString(EndOfFullName) Then
		RecordManagerFullName.MiddleName = RecordManagerFullName.MiddleName + " " + TrimAll(EndOfFullName);
	EndIf;
	
	If StrFind(LastFirstName, FullNameFull) = 0 Then
		Individual.LastFirstName = IndividualsPayrollAndHumanResourcesClientServer.FullNameFromParts(RecordManagerFullName);
		ShowMessageBox(, NStr("ru = 'Возможно, не корректно введено полное имя
			|Полное имя не соответствует восстановленному по данным о фамилии, имени и отчеству.';
			|vi = 'The full name may have been entered incorrectly.
			|The full name does not match the one retrieved from the last name, first name and patronymic data.';
			|en = 'The full name may have been entered incorrectly.
			|The full name does not match the one retrieved from the last name, first name and patronymic data.'; fa = 'The full name may have been entered incorrectly.
			|The full name does not match the one retrieved from the last name, first name and patronymic data.';
			|it = 'The full name may have been entered incorrectly.
			|The full name does not match the one retrieved from the last name, first name and patronymic data.';
			|pl = 'The full name may have been entered incorrectly.
			|The full name does not match the one retrieved from the last name, first name and patronymic data.';
			|tr = 'Tam ad hatalı girilmiş olabilir. 
			| Tam adı, soyadı, adı verilerinden oluşturulan adla eşleşmiyor.'"));
	EndIf;
	
	If Not ValueIsFilled(RecordManagerFullName.Period) Then
		
		If ValueIsFilled(Individual.BirthDate) Then
			RecordManagerFullName.Period = Individual.BirthDate;
		Else
			RecordManagerFullName.Period = '18991231000000';
		EndIf;
		
	EndIf;
	
EndProcedure

// Checks for individuals with similar data ON changing the employee's full name and opens the selection form when matches are found.
//
// Parameters:
//  Form - ClientApplicationForm - the form from which the check is called:
//  	* Object - CatalogObject.EmployeesHR
//
Procedure CheckNamesakes(Form)
	
	Object = Form.Object;
	
	SearchParameters = New Structure("LASTFIRSTNAME", "");
	SearchParameters.LASTFIRSTNAME = Object.Description;
	
	ArrayOfFoundPersons = CatalogsPayrollAndHumanResourcesServerCall.SimilarIndividuals(SearchParameters);
	NumberOfSimilar = ArrayOfFoundPersons.Count();
	
	If NumberOfSimilar > 0 Then
		
		OpeningParameters = New Structure("ListOfIndividuals", ArrayOfFoundPersons);
								
		AdditionalParameters = New Structure("Form", Form);						
								
		Notification = New CallbackDescription("CheckNamesakesDataOfPersons", ThisObject,
			AdditionalParameters);
		OpenForm("CommonForm.SimilarPersons", OpeningParameters, Form, 
			Form.Individual, , , Notification);
		
	EndIf;	
	
EndProcedure 

Procedure CheckNamesakesDataOfPersons(SelectionResult, AdditionalParameters) Export 
	
	Form = AdditionalParameters.Form;

	If SelectionResult <> Undefined
		And SelectionResult <> False Then
		
		IdentifyPersonInFormOfEmployee(Form, SelectionResult.SimilarPerson);
		
	EndIf;	
	
EndProcedure	

Procedure IdentifyPersonInFormOfEmployee(Form, Individual) Export
	
	If Individual = Undefined Or Individual.IsEmpty() Then
		Return;
	EndIf;
	
	Form.Object.Individual = Individual;
	Form.IndividualOnChangeAtServer();
	
EndProcedure

#EndRegion

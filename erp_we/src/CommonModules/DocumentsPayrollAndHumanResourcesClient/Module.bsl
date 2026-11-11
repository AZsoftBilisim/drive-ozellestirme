////////////////////////////////////////////////////////////////////////////////
// Documentarplataykadryclient: methods of international payroll and personnel accounting, working on the client's side.
//  
////////////////////////////////////////////////////////////////////////////////

#Region Private

// Performs the selection of employees in accordance with the specified parameters for opening the Form.
//
// Parameters:
//   Form - ClientApplicationForm  - The Form from which the selection of employees is called
//   OpeningParameters - Structure - Parameters passed when opening the employee recruitment Form
//   DataRepresentationElement - FormField - The Form element associated with employee data is Undefined by default
//
Procedure EmployeeRecruitment(Form, OpeningParameters, DataRepresentationElement = Undefined) Export
	
	If DataRepresentationElement = Undefined Then
		If OpeningParameters.Property("DataRepresentationElement") Then
			DataRepresentationElement = Form.Items[OpeningParameters.DataRepresentationElement];
		Else
			Return;
		EndIf;
	EndIf;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", OpeningParameters.Organization);
	If OpeningParameters.Property("Department") And ValueIsFilled(OpeningParameters.Department) Then
		FilterStructure1.Insert("Department", OpeningParameters.Department);
	EndIf;
	If OpeningParameters.Property("WorkingForPeriod") Then
		FilterStructure1.Insert("WorkingForPeriod", OpeningParameters.WorkingForPeriod);
	EndIf; 
	If OpeningParameters.Property("ItWorks") Then
		FilterStructure1.Insert("ItWorks", OpeningParameters.ItWorks);
	EndIf; 
	If OpeningParameters.Property("Period") Then
		FilterStructure1.Insert("Period", OpeningParameters.Period);
	EndIf;
	If OpeningParameters.Property("FilterApplyPeriodStart") Then
		FilterStructure1.Insert("FilterApplyPeriodStart", OpeningParameters.FilterApplyPeriodStart);
	EndIf;
	If OpeningParameters.Property("FilterApplyPeriodEnd") Then
		FilterStructure1.Insert("FilterApplyPeriodEnd", OpeningParameters.FilterApplyPeriodEnd);
	EndIf;
	
	OpeningParameters.Insert("Filter", FilterStructure1);
	
	OpenForm("Catalog.EmployeesHR.Form.ChoiceFormInternational", OpeningParameters, DataRepresentationElement);
	
EndProcedure

// Performs the selection of individuals of the corresponding employees in accordance with the specified parameters for opening the Form.
//
// Parameters:
//   Form - ClientApplicationForm  - The Form from which the selection of employees is called
//   OpeningParameters - Structure - Parameters passed when opening the employee recruitment Form
//   DataRepresentationElement - FormField - The Form element associated with employee data is Undefined by default
//
Procedure PersonsOfEmployeesSelection(Form, OpeningParameters, DataRepresentationElement = Undefined) Export
	
	If DataRepresentationElement = Undefined Then
		If OpeningParameters.Property("DataRepresentationElement") Then
			DataRepresentationElement = Form.Items[OpeningParameters.DataRepresentationElement];
		Else
			Return;
		EndIf;
	EndIf;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", OpeningParameters.Organization);
	If OpeningParameters.Property("Department") And ValueIsFilled(OpeningParameters.Department) Then
		FilterStructure1.Insert("Department", OpeningParameters.Department);
	EndIf;
	If OpeningParameters.Property("WorkingForPeriod") Then
		FilterStructure1.Insert("WorkingForPeriod", OpeningParameters.WorkingForPeriod);
	EndIf; 
	If OpeningParameters.Property("ItWorks") Then
		FilterStructure1.Insert("ItWorks", OpeningParameters.ItWorks);
	EndIf; 
	If OpeningParameters.Property("Period") Then
		FilterStructure1.Insert("Period", OpeningParameters.Period);
	EndIf;
	If OpeningParameters.Property("InArchive") Then
		FilterStructure1.Insert("InArchive", OpeningParameters.InArchive);
	Else
		FilterStructure1.Insert("InArchive", False);
	EndIf;
	
	OpeningParameters.Insert("Filter", FilterStructure1);
	
	OpenForm("Catalog.Persons.Form.InternationalEmployeeChoiceForm", OpeningParameters, DataRepresentationElement);
	
EndProcedure

Procedure TableOfValuesOnFormBeforeAdding(Form, Item, Cancel, Copy, Parent, Group) Export
	
	Form.Modified = True;
	
EndProcedure

// Creates and opens the Form of a new document based on the creation and selection commands in the list.
//
// Parameters:
//   Form - ClientApplicationForm - The form from which the document creation Command is called
//   CommandName - String - The name of the document creation command in the collection of Document creation commandsreferences
//   AdditionalFillInValues - Structure - Optional. Additional values for filling in the Attributes of the new document
Procedure CreateDocumentBasedOnDescription(Form, CommandName, AdditionalFillInValues = Undefined) Export
	
	CommandDetails = Form.DocumentCreationCommands.Get(CommandName);
	
	OpeningParameters = CommandDetails.Parameters;
	If OpeningParameters = Undefined Then
		OpeningParameters = New Structure;
	EndIf; 
	
	If Not OpeningParameters.Property("FillingValues") Then
		OpeningParameters.Insert("FillingValues", New Structure);
	EndIf; 
	
	If AdditionalFillInValues <> Undefined Then
		For Each AdditionalValue In AdditionalFillInValues Do
			OpeningParameters.FillingValues.Insert(AdditionalValue.Key, AdditionalValue.Value);
		EndDo;
	EndIf; 
	
	SettingsComposer = Form.List.SettingsComposer; // DataCompositionSettingsComposer
	
	For Each ConfiguringComposer In SettingsComposer.UserSettings.Items Do
		If TypeOf(ConfiguringComposer) = Type("DataCompositionFilter") Then
			For Each FilterElement In ConfiguringComposer.Items Do
				If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
					Continue;
				EndIf;
				If FilterElement.Use And FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
					SelectionKey = String(FilterElement.LeftValue);
					If Upper(Left(SelectionKey, 7)) = Upper("Ref.") Then
						SelectionKey = Mid(SelectionKey, 8);
					EndIf;
					SelectionKey = StrReplace(SelectionKey, ".", "");
					OpeningParameters.FillingValues.Insert(SelectionKey, FilterElement.RightValue);
				EndIf;
			EndDo;
		EndIf; 
	EndDo;
	
	For Each FilterElement In SettingsComposer.FixedSettings.Filter.Items Do 
		If FilterElement.Use And FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
			SelectionKey = String(FilterElement.LeftValue);
			If Upper(Left(SelectionKey, 7)) = Upper("Ref.") Then
				SelectionKey = Mid(SelectionKey, 8);
			EndIf;
			SelectionKey = StrReplace(SelectionKey, ".", "");
			OpeningParameters.FillingValues.Insert(SelectionKey, FilterElement.RightValue);
		EndIf;
	EndDo;
	
	OpenForm(CommandDetails.FullName + "." + CommandDetails.FormName, OpeningParameters, Form);
	
EndProcedure

#EndRegion
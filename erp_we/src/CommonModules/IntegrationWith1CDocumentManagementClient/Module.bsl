////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module integration1sdocumentclient: client
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region GeneralProceduresAndFunctions

// Opens the user selection form in the context of divisions and places the selected user in the form details.
//
// Parameters:
//   Attribute - String - the name of the form details that the selected user will be placed in.
//   OwnerForm - ClientApplicationForm - the form from which the user's selection form is called.
//
Procedure SelectUserFromUnitTree(Attribute, OwnerForm) Export
	
	FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingUserWithDepartments";
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Attribute", Attribute);
	NotificationParameters.Insert("OwnerForm", OwnerForm);
	
	Notification = New CallbackDescription("SelectUserFromUnitTreeCompletion",
		IntegrationWith1CDocumentManagementClient,
		NotificationParameters);
	
	OpenForm(FormName, , OwnerForm,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Opens a form for specifying the value of a composite type of props.
//
// Parameters:
//   Form - ClientApplicationForm - the form on which the work with the props
//     is carried out and from which the filling form is called.
//   CurrentData - FormDataCollectionItem
//   Attribute - String - the name of the prop from the current data.
//   StandardProcessing - Boolean- the processing parameter used in the handler on the form
//     from which the filling of the value of the additional props is called.
//
Procedure SelectValueOfCompositeTypePropsInTable(Form, CurrentData, Attribute, StandardProcessing) Export
	
	StandardProcessing = False;
	
	AvailableTypeList = CurrentData[Attribute + "TypesList"];
	
	If AvailableTypeList.Count() = 0 Then
		Return;
	EndIf;
	
	If AvailableTypeList.Count() > 1 Then
		FormCaption = NStr("vi = 'Chọn kiểu dữ liệu';
							|ru = 'Выбор типа данных';
							|en = 'Select data type'; fa = 'Select data type';
							|it = 'Scelta del tipo dati';
							|pl = 'Wybór typu danych';
							|tr = 'Veri türünü seçin'");
		FormParameters = New Structure("AvailableTypeList, FormCaption", AvailableTypeList, FormCaption);
		FormName = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingOneTypeFromCompositeType";
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("Form", Form);
		NotificationParameters.Insert("CurrentData", CurrentData);
		NotificationParameters.Insert("Attribute", Attribute);
		
		Notification = New CallbackDescription(
			"SelectValueOfCompositeTypeAttributeInSelectTypeTable",
			IntegrationWith1CDocumentManagementClient,
			NotificationParameters);
		
		OpenForm(FormName, FormParameters, Form,,,, Notification);
	Else
		TypeName = AvailableTypeList[0].Value.XDTOClassName;
		SelectValueOfCompositeAttributeInProcessingTable(TypeName, Form, CurrentData, Attribute);
	EndIf;
	
EndProcedure

// Continues execution of the connected integration command after connection verification.
//
// Parameters:
//   Command - FormCommand - the command called.
//   Form - ClientApplicationForm - the form from which the command is called.
//   Source - FormDataStructure, FormTable - the data specifying the command parameter contains a reference to the IC object.
//
Procedure ExecutePlugInIntegrationCommandCompletion(Command, Form, Source) Export
	
	If Command.Name = "IntegrationWith1CDocumentManagement_SpecifyTheLaborCosts" Then
		SpecifyLaborCosts(Source, Form);
		
	ElsIf Command.Name = "IntegrationWith1CDocumentManagement_SwitchTimekeeping" Then
		SwitchTiming(Source, Form);
		
	ElsIf Command.Name = "IntegrationWith1CDocumentManagement_Files" Then
		If TypeOf(Source) = Type("FormDataStructure") Then
			ObjectIS = Source; // DocumentObject
			Ref = ObjectIS.Ref;
		Else
			If Source.CurrentData = Undefined Then
				Return;
			EndIf;
			Ref = Undefined;
			If Not Source.CurrentData.Property("Ref", Ref) Then
				Ref = Source.CurrentRow;
			EndIf;
		EndIf;
		IntegrationWith1CDocumentManagementCoreClient.OpenFormAttachedFiles(
			Ref,
			IntegrationWith1CDocumentManagementCoreClient.OptionsForOpeningListOfFiles(Form));
		
	EndIf;
	
EndProcedure

// Clears the ID and Type when clearing the details of the Workflow object on the form.
//
// Parameters:
//   Attribute - String - name of the form's details.
//   OwnerForm - ClientApplicationForm - a managed form containing the details to be cleared.
//
Procedure ClearReferenceProps(Attribute, OwnerForm) Export
	
	OwnerForm[Attribute + "ID"] = "";
	OwnerForm[Attribute + "Type"] = "";
	OwnerForm.Modified = True;
	
EndProcedure

// Sets the selected value to a list item.
//
// Parameters:
//   ItemList - FormTable - an element of a managed form.
//   ValueSelected - Structure:
//     * ID - String - object identifier.
//     * type - String - object type.
//     * name - String - representation of objects.
//   StandardProcessing - Boolean - an implicitly returned value, a sign that standard processing
//     will not be performed.
//   OwnerForm - ClientApplicationForm - the form from which the method is called.
//
Procedure ApplySelectionOfPropsValueInList(ItemList, ValueSelected,
		StandardProcessing, OwnerForm) Export
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		StandardProcessing = False;
		
		ItemList.CurrentData["Value"] = ValueSelected.Name;
		ItemList.CurrentData["ValueID"] = ValueSelected.ID;
		ItemList.CurrentData["ValueType"] = ValueSelected.type;
		OwnerForm.Modified = True;
	EndIf;
	
EndProcedure

// Creates an alert when recording Workflow documents.
//
// Parameters:
//   Form - ClientApplicationForm - the document form of the document flow.
//
Procedure Notify_DocumentEntry(Form) Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("name", Form.Presentation);
	NotificationParameters.Insert("ID", Form.ID);
	NotificationParameters.Insert("type", Form.Type);
	NotificationParameters.Insert("documentType", Form.DocumentKind);
	NotificationParameters.Insert("ExternalObject", Form.ExternalObject);
	
	Notify("Recording_1CDocumentManagementDocument", NotificationParameters, Form.FormOwner);
	
EndProcedure

// Creates an alert when recording Workflow business processes.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the Workflow business process.
//   Started - Boolean - a flag indicating whether the business process is running.
//
Procedure Notify_BusinessProcessRecord(Form, Started) Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("ID", Form.ID);
	NotificationParameters.Insert("Started", Started);
	
	// Let's collect the items.
	Subjects = New Array;
	If Form.MultiSubjectivityIsAvailable Then
		For Each SubjectLine In Form.Subjects Do
			If SubjectLine.RoleOfSubject = "Основной" Then //@NON-NLS-1
				SubjectOf = New Structure;
				SubjectOf.Insert("ID", SubjectLine.SubjectOfID);
				SubjectOf.Insert("Type", SubjectLine.SubjectOfType);
				Subjects.Add(SubjectOf);
			EndIf;
		EndDo;
	Else // One item.
		SubjectOf = New Structure;
		SubjectOf.Insert("ID", Form.SubjectOfID);
		SubjectOf.Insert("Type", Form.SubjectOfType);
		Subjects.Add(SubjectOf);
	EndIf;
	NotificationParameters.Insert("Subjects", Subjects);
	
	Notify("Recording_1CDocumentManagementBusinessProcess", NotificationParameters, Form.FormOwner);

EndProcedure

// Creates an alert when recording an outgoing Workflow email.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the outgoing document flow letter.
//
Procedure Notify_OutgoingEmailRecord(Form) Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("ID", Form.ID);
	NotificationParameters.Insert("SubjectOfID", Form.SubjectOfID);
	NotificationParameters.Insert("EmailBasisID",Form.EmailBasisID);
	
	Notify("Recording_1CDocumentManagementOutgoingEmail", NotificationParameters, Form.FormOwner);
	
EndProcedure

// Creates an alert when recording a Workflow object.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the document flow object.
//   ExternalObject - AnyRef - reference to the IP object.
//
Procedure Notify_ObjectRecord(Form, ExternalObject = Undefined) Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("name", Form.Presentation);
	NotificationParameters.Insert("ID", Form.ID);
	NotificationParameters.Insert("type", Form.Type);
	NotificationParameters.Insert("ExternalObject", ExternalObject);
	
	Notify("Recording_1CDocumentManagementObject", NotificationParameters, Form.FormOwner);
	
EndProcedure

// Shows the question "Yes"/ "No", taking Esc and closing the form with a cross as the answer "No".
//
// Parameters:
//   CallbackDescriptionOnCompletion - CallbackDescription - the procedure called after closing with
//     the transmission of the parameter of the code of the return of the directory.Yes or the return code of the radio. No.
//   QueryText - String - the text of the question being asked.
//   QuestionParameters - See IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo
//
Procedure ShowQuestionYesNo(CallbackDescriptionOnCompletion, QueryText, QuestionParameters = Undefined) Export
	
	CallbackDescription = New CallbackDescription(
		"ShowQuestionYesNoCompletion",
		IntegrationWith1CDocumentManagementClient,
		CallbackDescriptionOnCompletion);
	
	If QuestionParameters = Undefined Then
		QuestionParameters = IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo();
	EndIf;
	
	Buttons = New ValueList;
	If QuestionParameters.YesButtonText = "" Then
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Có';
												|ru = 'Да';
												|en = 'Yes'; fa = 'بله';
												|it = 'Да';
												|pl = 'Tak';
												|tr = 'Evet'"));
	Else
		Buttons.Add(DialogReturnCode.Yes, QuestionParameters.YesButtonText);
	EndIf;
	If QuestionParameters.NoButtonText = "" Then
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Không';
												|ru = 'Нет';
												|en = 'No'; fa = 'خیر';
												|it = 'Нет';
												|pl = 'Nie';
												|tr = 'Hayır'"));
	Else
		Buttons.Add(DialogReturnCode.No, QuestionParameters.NoButtonText);
	EndIf;
	
	If QuestionParameters.DefaultButton = Undefined Then
		ShowQueryBox(CallbackDescription, QueryText, Buttons,,, QuestionParameters.Title);
	ElsIf QuestionParameters.DefaultButton = DialogReturnCode.Yes Then
		ShowQueryBox(CallbackDescription, QueryText, Buttons,, DialogReturnCode.Yes, QuestionParameters.Title);
	ElsIf QuestionParameters.DefaultButton = DialogReturnCode.No Then
		ShowQueryBox(CallbackDescription, QueryText, Buttons,, DialogReturnCode.No, QuestionParameters.Title);
	Else
		Raise StrTemplate(NStr("vi = 'Giá trị không hợp lệ của nút theo mặc định: %1';
								|ru = 'Недопустимое значение кнопки по умолчанию: %1';
								|en = 'Invalid value for default button: %1'; fa = 'Invalid value for default button: %1';
								|it = 'Недопустимое значение кнопки по умолчанию: %1';
								|pl = 'Domyślna niedopuszczalna wartość przycisku: %1';
								|tr = 'Geçersiz düğmenin varsayılan değeri: %1'"),
			QuestionParameters.DefaultButton);
	EndIf;
	
EndProcedure

// It is called after closing the window with the question "Yes" / "No" and calls the previously passed
// notification handler with the transmission of the user's response.
//
// Parameters:
//   Result - DialogReturnCode - the user's response, the return code of the dialog.Yes or the return code of the dialog.No.
//   CallbackDescription - CallbackDescription - description of the alert being called.
//
Procedure ShowQuestionYesNoCompletion(Result, CallbackDescription) Export
	
	If Result = DialogReturnCode.Yes Then
		RunCallback(CallbackDescription, DialogReturnCode.Yes);
	Else
		RunCallback(CallbackDescription, DialogReturnCode.No);
	EndIf;
	
EndProcedure

// Opens the value selection form from the list of workflow objects and places the selected value on the form.
//
// Parameters:
//   TypeOfSelectionObject - String - the name of the XDTO class corresponding to the type of object being selected.
//   Attribute - String - the name of the form's details in which the value selected from the workflow will be placed.
//   OwnerForm - ClientApplicationForm - the form from which the selection form is called.
//   Filter - Structure - conditions imposed on the list.
//
Procedure SelectAValueFromTheList(TypeOfSelectionObject, Attribute, OwnerForm, Filter = Undefined) Export
	
	Parameters = New Structure;
	Parameters.Insert("Attribute", Attribute);
	Parameters.Insert("OwnerForm", OwnerForm);
	
	Notification = New CallbackDescription("SelectAValueFromTheListCompletion", IntegrationWith1CDocumentManagementClient, Parameters);
	
	SelectValueByObjectType(Notification, TypeOfSelectionObject, Filter, OwnerForm[Attribute + "ID"], OwnerForm);
	
EndProcedure

// Processing the selection of a value from a list.
//
// Parameters:
//   Result - Structure:
//     * AttributeID - String
//     * AttributePresentation - String
//     * AttributeType - String
//   Parameters - Structure:
//     * Attribute - String
//     * OwnerForm - ClientApplicationForm
//
Procedure SelectAValueFromTheListCompletion(Result, Parameters) Export
	
	OwnerForm = Parameters.OwnerForm;
	Attribute = Parameters.Attribute;
	
	If TypeOf(Result) = Type("Structure") Then
		
		OwnerForm[Attribute] = Result.AttributePresentation;
		OwnerForm[Attribute + "ID"] = Result.AttributeID;
		OwnerForm[Attribute + "Type"] = Result.AttributeType;
		
		OwnerForm.Modified = True;
		
		Notify("DocumentManagement_SelectAValueFromTheListCompletion", Attribute, OwnerForm);
		
	EndIf;
	
EndProcedure

// Opens the form for selecting the value of the props in the table from the list of document flow objects.
//
// Parameters:
//   TypeOfSelectionObject - String - the name of the XDTO class corresponding to the type of object being selected.
//   Attribute - String - the name of the form's details in which the value selected from the workflow will be placed.
//   CurrentData - FormDataCollectionItem
//   OwnerForm - ClientApplicationForm - the form from which the selection form is called.
//   Filter - Structure - conditions imposed on the list.
//
Procedure SelectAValueFromTheListInTheTable(TypeOfSelectionObject, Attribute, CurrentData, OwnerForm,
		Filter = Undefined) Export
	
	Parameters = New Structure;
	Parameters.Insert("CurrentData", CurrentData);
	Parameters.Insert("Attribute", Attribute);
	Parameters.Insert("OwnerForm", OwnerForm);
	
	Notification = New CallbackDescription("SelectAValueFromTheListInTheTableCompletion", IntegrationWith1CDocumentManagementClient, Parameters);
	
	SelectValueByObjectType(Notification, TypeOfSelectionObject, Filter, CurrentData[Attribute + "ID"], OwnerForm);
	
EndProcedure

// Processing the selection of a value in a table from a list.
//
// Parameters:
//   Result - Structure:
//     * AttributeID - String
//     * AttributePresentation - String
//     * AttributeType - String
//   Parameters - Structure:
//     * Attribute - String
//     * OwnerForm - ClientApplicationForm
//     * CurrentData - FormDataCollectionItem
//
Procedure SelectAValueFromTheListInTheTableCompletion(Result, Parameters) Export
	
	CurrentData = Parameters.CurrentData;
	Attribute = Parameters.Attribute;
	OwnerForm = Parameters.OwnerForm;
	
	If TypeOf(Result) = Type("Structure") Then
		
		CurrentData[Attribute] = Result.AttributePresentation;
		CurrentData[Attribute + "ID"] = Result.AttributeID;
		CurrentData[Attribute + "Type"] = Result.AttributeType;
		
		OwnerForm.Modified = True;
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("Attribute", Attribute);
		NotificationParameters.Insert("Data", CurrentData);
		NotificationParameters.Insert("Result", Result);
		
		Notify("DocumentManagement_SelectAValueFromTheListInTheTableCompletion", NotificationParameters, OwnerForm);
		
	EndIf;
	
EndProcedure

// Opens the value selection list from the list of workflow objects and places the selected value on the form.
//
// Parameters:
//   TypeOfSelectionObject - String - the name of the XDTO class corresponding to the type of object being selected.
//   Attribute - String - the name of the form's details in which the value selected from the workflow will be placed.
//   OwnerForm - ClientApplicationForm - the form from which the selection form is called.
//   Filter - Structure - conditions imposed on the list.
//   ThisIsTable - Boolean - indicates that the value is selected in the tabular part.
//   Item - FormField - the form element in which the value is selected.
//
Procedure SelectAValueFromTheDropDownList(TypeOfSelectionObject, Attribute, OwnerForm,
		Filter = Undefined, ThisIsTable = False, Item = Undefined) Export
	
	ChoiceList = IntegrationWith1CDocumentManagementCoreServerCall.ValuesForSelection(
		TypeOfSelectionObject, Filter);
	
	If ThisIsTable Then
		CurrentValue = Item.Parent.CurrentData[Attribute + "ID"];
	Else
		CurrentValue = OwnerForm[Attribute + "ID"];
	EndIf;
	
	InitialValue = Undefined;
	For Each ListItem In ChoiceList Do
		If ListItem.Value.AttributeID = CurrentValue Then
			InitialValue = ListItem;
			Break;
		EndIf;
	EndDo;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Attribute", Attribute);
	AdditionalParameters.Insert("OwnerForm", OwnerForm);
	AdditionalParameters.Insert("ThisIsTable", ThisIsTable);
	AdditionalParameters.Insert("Item", Item);
	AdditionalParameters.Insert("TypeOfSelectionObject", TypeOfSelectionObject);
	
	Notification = New CallbackDescription("SelectAValueFromTheDropDownListCompletion",
		IntegrationWith1CDocumentManagementClient, AdditionalParameters);
	
	If InitialValue = Undefined Then
		OwnerForm.ShowChooseFromList(
			Notification,
			ChoiceList,
			?(ThisIsTable,Item,OwnerForm[Attribute]));
		
	Else
		OwnerForm.ShowChooseFromList(
			Notification,
			ChoiceList,
			?(ThisIsTable,Item,OwnerForm[Attribute]),
			InitialValue);
		
	EndIf;
	
EndProcedure

// Processing the selection of a value from a drop-down list.
//
// Parameters:
//   Result - Arbitrary
//   Parameters - Structure:
//     * Form - ClientApplicationForm
//     * Item - FormTable
//
Procedure SelectAValueFromTheDropDownListCompletion(Result, Parameters) Export
	
	Attribute = Parameters.Attribute;
	OwnerForm = Parameters.OwnerForm;
	ThisIsTable = Parameters.ThisIsTable;
	Item = Parameters.Item;
	
	If Result <> Undefined Then
		If TypeOf(Result.Value) = Type("Structure") Then
			If Not ThisIsTable Then
				OwnerForm[Attribute] = Result.Value.AttributePresentation;
				OwnerForm[Attribute + "ID"] = Result.Value.AttributeID;
				OwnerForm[Attribute + "Type"] = Result.Value.AttributeType;
			Else
				Item.Parent.CurrentData[Attribute] = Result.Value.AttributePresentation;
				Item.Parent.CurrentData[Attribute + "ID"] = Result.Value.AttributeID;
				Item.Parent.CurrentData[Attribute + "Type"] = Result.Value.AttributeType;
			EndIf;
			OwnerForm.Modified = True;
			
			NotificationParameters = New Structure;
			NotificationParameters.Insert("Attribute", Attribute);
			NotificationParameters.Insert("ThisIsTable", ThisIsTable);
			NotificationParameters.Insert("Item", Item);
			
			Notify("DocumentManagement_SelectAValueFromTheDropDownListCompletion",
				NotificationParameters, OwnerForm);
		EndIf;
	EndIf;
	
EndProcedure

// Starts the process of selecting an object UP TO the specified type, returning the result by calling an alert.
//
// Parameters:
//   CallbackDescription - CallbackDescription - called after the selection is completed with the transmission of a structure
//      describing the selected object.
//   TypeOfSelectionObject - String - the type of the selected object (XDTO, for example, "DMCorrespondent").
//   Filter - Structure - imposed selection.
//   ValueSelected - String - id of the previously selected value.
//   OwnerForm - ClientApplicationForm - the form from which the selection is called.
//
Procedure SelectValueByObjectType(CallbackDescription, TypeOfSelectionObject, Filter = Undefined,
		ValueSelected = "", OwnerForm = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", TypeOfSelectionObject);
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("Title",
		IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(TypeOfSelectionObject,, True));
	FormParameters.Insert("SelectedElement", ValueSelected);
	
	// In the new versions, the selection of the object by search is available.
	If IntegrationWith1CDocumentManagementCoreClientCached.FunctionalityOfServiceVersionIsAvailable("1.4.6.1")
			And (TypeOfSelectionObject = "DMIncomingDocument"
				Or TypeOfSelectionObject = "DMInternalDocument"
				Or TypeOfSelectionObject = "DMOutgoingDocument"
				Or TypeOfSelectionObject = "DMCorrespondent") Then
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingObjectBySearch",
			FormParameters,
			OwnerForm,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
	Else // In older versions, we use simple forms.
		// Getting subfolders of any type.
		If TypeOfSelectionObject = "DMInternalDocument"
				And IntegrationWith1CDocumentManagementCoreClientCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3") Then
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingInternalDocument",
				FormParameters,
				OwnerForm,,,,
				CallbackDescription,
				FormWindowOpeningMode.LockWholeInterface);
		Else
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList",
				FormParameters,
				OwnerForm,
				New UUID,,,
				CallbackDescription,
				FormWindowOpeningMode.LockWholeInterface);
		EndIf;
	EndIf;
	
EndProcedure

// Called after switching timekeeping in the form of an IC object.
//
// Parameters:
//   Result - Boolean
//   NotificationParameters - FormItems
//
Procedure MarkSwitchTimekeepingButton(Result, NotificationParameters) Export
	
	If Result = True Then
		If NotificationParameters.Find("IntegrationWith1CDocumentManagement_SwitchTimekeeping") <> Undefined Then
			NotificationParameters.IntegrationWith1CDocumentManagement_SwitchTimekeeping.Check = False;
		EndIf;
	EndIf;
	
EndProcedure

// Returns the duration of the operation in seconds from the start of the event to the current date.
//
// Parameters:
//   StartDateOfTimekeeping - Date - the start date of the timekeeping.
//
// Returns:
//   Number - duration of operation in seconds.
//
Function GetRunningTime(StartDateOfTimekeeping) Export
	
	WorkDuration = 0;
	
	If StartDateOfTimekeeping <> '00010101' Then
		Today_ = BegOfDay(CurrentDate()); // The use is justified: duration calculation.
		StartDay = BegOfDay(StartDateOfTimekeeping);
		
		If StartDay = Today_ Then
			EndOfTimekeeping = CurrentDate(); // The use is justified: duration calculation.
			WorkDuration = EndOfTimekeeping - StartDateOfTimekeeping;
		EndIf;
	EndIf;
	
	Return WorkDuration;
	
EndFunction

// Performs the creation of the object BEFORE, its filling in by the IC object and establishing communication after recording. If
// necessary, it offers the user a choice of rules.
//
// Parameters:
//   ObjectIS - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object
//     on the basis of which the DO object is created.
//   CallbackDescription - CallbackDescription - the handler that is called after creation.
//   OpenForm - Boolean - True if you need to open the form of the created object, and False if
//     the linked object should be created silently. In case of recording errors, the form will still be open.
//
Procedure StartCreatingARelatedObjectDM(ObjectIS, CallbackDescription, OpenForm = False) Export
	
	Parameters = New Structure;
	Parameters.Insert("ObjectIS", ObjectIS);
	Parameters.Insert("CallbackDescription", CallbackDescription);
	Parameters.Insert("OpenForm", OpenForm);
	
	Rules = IntegrationWith1CDocumentManagementCoreServerCall.FindCreateAppropriateRules(ObjectIS);
	
	If Rules.Count() = 1 Then
		
		StartCreatingLinkedObjectDMAfterSelectingRule(Rules[0], Parameters);
		
	ElsIf Rules.Count() = 0 Then
		
		DescriptionOfContinuationNotification = New CallbackDescription(
			"StartCreatingLinkedObjectDMAfterSelectingType",
			IntegrationWith1CDocumentManagementClient,
			Parameters);
		
		FormParameters = New Structure;
		FormParameters.Insert("Title", NStr("vi = 'Tạo mới trong 1C:Document Management';
											|ru = 'Создать в 1С:Документообороте';
											|en = 'Create in 1C:Document Management'; fa = 'Create in 1C:Document Management';
											|it = 'Creazione in 1C:Document Management';
											|pl = 'Utwórz w 1C:Document Management';
											|tr = '1C:Document Management''te oluştur'"));
		FormParameters.Insert("CommandTitle", NStr("vi = 'Tạo mới';
													|ru = 'Создать';
													|en = 'Create'; fa = 'ایجاد';
													|it = 'Creare';
													|pl = 'Create';
													|tr = 'Oluştur'"));
		FormParameters.Insert("ObjectIS", ObjectIS);
		
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingTypeOfDocumentManagementObject",
			FormParameters,,,,,
			DescriptionOfContinuationNotification,
			FormWindowOpeningMode.LockWholeInterface);
		
	Else // Multiple rules, user selection required.
		
		DescriptionOfContinuationNotification = New CallbackDescription(
			"StartCreatingLinkedObjectDMAfterSelectingRule",
			IntegrationWith1CDocumentManagementClient,
			Parameters);
		
		FormParameters = New Structure;
		FormParameters.Insert("Rules", Rules);
		
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingRule",
			FormParameters,,,,,
			DescriptionOfContinuationNotification,
			FormWindowOpeningMode.LockWholeInterface);
		
	EndIf;
	
EndProcedure

// Continues object creation UNTIL after type selection.
//
// Parameters:
//   Type - String - the type of the object being created, for example, "DMInternalDocument".
//   Parameters - Structure:
//     ObjectIS - Arbitrary - IS object, on the basis of which the object is created BEFORE.
//     Description of the announcement - The description of the announcement is the handler that is called after creation.
//     Open the form - Boolean - True if you need to open the form of the created object, and False if
//       the associated object should be created silently.
//
Procedure StartCreatingLinkedObjectDMAfterSelectingType(Type, Parameters) Export
	
	If TypeOf(Type) <> Type("String") Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExternalObject", Parameters.ObjectIS);
	
	If Type = "DMIncomingDocument" Then
		FormName = "IncomingDocument";
	ElsIf Type = "DMOutgoingDocument" Then
		FormName = "OutgoingDocument";
	ElsIf Type = "DMInternalDocument" Then
		FormName = "InternalDocument";
	ElsIf Type = "DMCorrespondent" Then
		FormName = "Counterparty";
	EndIf;
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form." + FormName,
		FormParameters,,Parameters.ObjectIS,,,Parameters.CallbackDescription);
	
EndProcedure

// Performs the creation of the object BEFORE, its filling in by the IC object and establishing communication after recording. If
// necessary, it offers the user a choice of rules.
//
// Parameters:
//   Rule - Structure - a suitable rule:
//     Link - Reference link.The ruleintegrationis1 Document management.
//     The object type is a string.
//     The object type is a string.
//     The representation of the objectis a string.
//     The representation of the object is a string.
//   Parameters - Structure:
//     ObjectIS - Arbitrary - IS object, on the basis of which the object is created BEFORE.
//     Description of the announcement - The description of the announcement is the handler that is called after creation.
//     Open the form - Boolean - True if you need to open the form of the created object, and False if
//       the associated object should be created silently.
//
Procedure StartCreatingLinkedObjectDMAfterSelectingRule(Rule, Parameters) Export
	
	If TypeOf(Rule) <> Type("Structure") Then
		Return;
	EndIf;
	
	If Parameters.OpenForm Then
		
		FormParameters = New Structure;
		FormParameters.Insert("ExternalObject", Parameters.ObjectIS);
		FormParameters.Insert("Rule", Rule.Ref);
		
		If Rule.ObjectTypeDM = "DMIncomingDocument" Then
			FormName = "IncomingDocument";
		ElsIf Rule.ObjectTypeDM = "DMOutgoingDocument" Then
			FormName = "OutgoingDocument";
		ElsIf Rule.ObjectTypeDM = "DMInternalDocument" Then
			FormName = "InternalDocument";
		ElsIf Rule.ObjectTypeDM = "DMCorrespondent" Then
			FormName = "Counterparty";
		EndIf;
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form." + FormName,
			FormParameters,,Parameters.ObjectIS,,,Parameters.CallbackDescription);
		
	Else // Without opening the form.
		
		ObjectDMOrMessage = IntegrationWith1CDocumentManagementCoreServerCall.CreateMapItemUsingRule(
			Parameters.ObjectIS,
			Rule.Ref);
			
		If TypeOf(ObjectDMOrMessage) = Type("String") Then // error message.
			
			Parameters.Insert("Rule", Rule.Ref);
			Parameters.Insert("ObjectTypeDM", Rule.ObjectTypeDM);
			
			CallbackDescription = New CallbackDescription(
				"StartCreatingLinkedObjectDMAfterWarning",
				IntegrationWith1CDocumentManagementClient,
				Parameters);
			
			ShowMessageBox(CallbackDescription, ObjectDMOrMessage,,
				NStr("vi = 'Không thể tạo đối tượng 1C:Document Management';
					|ru = 'Не удалось создать объект 1С:Документооборота';
					|en = 'Cannot create a 1C:Document Management object'; fa = 'Cannot create a 1C:Document Management object';
					|it = 'Non è stato possibile creare l''oggetto di 1C:Document Management';
					|pl = 'Nie udało się utworzyć obiektu w 1C:Document Management';
					|tr = '1C:Document Management nesnesi oluşturulamadı'"));
			
		Else // A structure with a description of the created result object.
			
			RunCallback(Parameters.CallbackDescription, ObjectDMOrMessage);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Continues the creation of the linked object UNTIL after showing a warning about the impossibility of recording
// the automatically created object. Opens its form for interactive filling.
//
// Parameters:
//   Parameters - Structure:
//     ObjectIS - Arbitrary - IS object, on the basis of which the object is created BEFORE.
//     Description of the announcement - The description of the announcement is the handler that is called after creation.
//     Open the form - Boolean - True if you need to open the form of the created object, and False if
//       the associated object should be created silently.
//
Procedure StartCreatingLinkedObjectDMAfterWarning(Parameters) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ExternalObject", Parameters.ObjectIS);
	FormParameters.Insert("Rule", Parameters.Rule);
	
	If Parameters.ObjectTypeDM = "DMIncomingDocument" Then
		FormName = "IncomingDocument";
	ElsIf Parameters.ObjectTypeDM = "DMOutgoingDocument" Then
		FormName = "OutgoingDocument";
	ElsIf Parameters.ObjectTypeDM = "DMInternalDocument" Then
		FormName = "InternalDocument";
	ElsIf Parameters.ObjectTypeDM = "DMCorrespondent" Then
		FormName = "Counterparty";
	EndIf;
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form." + FormName,
		FormParameters,,Parameters.ObjectIS,,,Parameters.CallbackDescription);
	
EndProcedure

// Creates an IP object based on the data of the form of the object BEFORE.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the document flow object or another form that requires notification.
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement - the rule used.
//
Procedure CreateIntegratedObjectBasedOnFormData(Form, Rule) Export
	
	CreateIntegratedObjectByRule(Form, Rule, Form.Type, Form.ID);

EndProcedure

// Creates an IP object based on the specified object BEFORE and of a known type.
//
// Parameters:
//   Form - ClientApplicationForm - the shape of the object BEFORE or another form that requires notification.
//   ObjectTypeIS - String - the type of IP object.
//   ObjectTypeDM - String - the object type is UP TO.
//   ObjectIDDM - String - the ID of the object BEFORE.
//
Procedure CreateIntegratedObjectByType(Form, ObjectTypeIS, ObjectTypeDM, ObjectIDDM) Export
	
	Rules = IntegrationWith1CDocumentManagementServerCall.SuitableRules(,,
		ObjectTypeIS,
		ObjectTypeDM,
		ObjectIDDM);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Form", Form);
	NotificationParameters.Insert("ObjectTypeDM", ObjectTypeDM);
	NotificationParameters.Insert("ObjectIDDM", ObjectIDDM);
	
	CallbackDescription = New CallbackDescription(
		"CreateIntegratedObjectByTypeAfterSelectingRule",
		IntegrationWith1CDocumentManagementClient,
		NotificationParameters);
	
	If Rules.Count() = 1 Then
		
		RunCallback(CallbackDescription, Rules[0]);
		
	ElsIf Rules.Count() = 0 Then
		
		CreateIntegratedObjectWithoutRule(Form, ObjectTypeIS, ObjectTypeDM, ObjectIDDM);
		
	Else
		
		FormParameters = New Structure;
		FormParameters.Insert("Rules", Rules);
		FormParameters.Insert("ObjectCreationIS", True);
		
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingRule",
			FormParameters,,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	EndIf;
	
EndProcedure

// Continues the creation of the IP object in case of ambiguity of the rules after selecting the rule.
//
// Parameters:
//   Result - Structure:
//     * Ref - CatalogRef.RulesForIntegrationWith1CDocumentManagement - the selected rule.
//   Parameters - Structure:
//     * Form - ClientApplicationForm - the shape of the object BEFORE or another form that requires notification.
//     * ObjectTypeDM - String - the object type is UP TO.
//     * ObjectIDDM - String - the ID of the object BEFORE.
//
Procedure CreateIntegratedObjectByTypeAfterSelectingRule(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	CreateIntegratedObjectByRule(
		Parameters.Form,
		Result.Ref,
		Parameters.ObjectTypeDM,
		Parameters.ObjectIDDM);
	
EndProcedure

// Creates an IP object for the specified object BEFORE, fills it in and establishes a connection.
//
// Parameters:
//   Form - ClientApplicationForm - the shape of the object BEFORE or another form that requires notification.
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement - the rule used.
//   ObjectTypeDM - String - the object type is UP TO.
//   ObjectIDDM - String - the ID of the object BEFORE.
//
Procedure CreateIntegratedObjectByRule(Form, Rule, ObjectTypeDM, ObjectIDDM) Export
	
	FillingData = IntegrationWith1CDocumentManagementCoreServerCall.DataForFillingInIntegratedObject(
		Rule.UUID(),
		ObjectTypeDM,
		ObjectIDDM);
	
	IntegrationWith1CDocumentManagementCoreClient.CreateIntegratedObjectFromFillingData(
		FillingData,
		Form);
	
EndProcedure

// Creates an IP object for the specified object BEFORE, fills it in and establishes a connection.
//
// Parameters:
//   Form - ClientApplicationForm - the shape of the object BEFORE or another form that requires notification.
//   ObjectTypeIS - String - the full name of the IP object type.
//   ObjectTypeDM - String - the object type is UP TO.
//   ObjectIDDM - String - the ID of the object BEFORE.
//
Procedure CreateIntegratedObjectWithoutRule(Form, ObjectTypeIS, ObjectTypeDM, ObjectIDDM) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("IntegrationWith1CDocumentManagement_ObjectTypeDM", ObjectTypeDM);
	FormParameters.Insert("IntegrationWith1CDocumentManagement_ObjectIdentifierDM", ObjectIDDM);
	
	FormName = ObjectTypeIS + ".ObjectForm";
	
	ObjectForm = OpenForm(
		FormName,
		FormParameters,
		Form,
		ObjectIDDM,,,,
		FormWindowOpeningMode.Independent);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Object1CDocumentManagement",
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			ObjectIDDM,
			ObjectTypeDM));
	NotificationParameters.Insert("ObjectForm", ObjectForm);
	NotificationParameters.Insert("WhetherFilesAreAttached", Undefined);
	NotificationParameters.Insert("TypeOfObjectToCreate", ObjectTypeIS);
	
	Notification = New CallbackDescription("CreateIntegratedCompletionObject",
		IntegrationWith1CDocumentManagementCoreClient,
		NotificationParameters);
	
	ObjectForm.CallbackDescriptionOnClose = Notification;
	
	ShowUserNotification(NStr("vi = 'Không tìm thấy quy tắc phù hợp.';
								|ru = 'Подходящих правил не найдено.';
								|en = 'No suitable rules found.'; fa = 'No suitable rules found.';
								|it = 'Diritti adeguati non trovati.';
								|pl = 'Nie znaleziono pasujących reguł.';
								|tr = 'Uygun kural bulunamadı.'"));
	
EndProcedure

// Called when automatic integration settings are selected.
//
// Parameters:
//   ObjectTypeName - String - the full name of the IP object type, as in the metadata.
//
Procedure StartAutomaticIntegrationConfiguration(ObjectTypeName) Export
	
	CreatedRules = IntegrationWith1CDocumentManagementServerCall.CreateIntegrationRulesAutomatically(ObjectTypeName);
	
	If CreatedRules.Count() > 0 Then
		
		Notify("IntegrationWith1CDocumentManagement_RuleCreated", CreatedRules);
		
		For Each CreatedRule In CreatedRules Do
			ShowUserNotification(
				NStr("vi = 'Tạo mới:';
					|ru = 'Создание:';
					|en = 'Creating:'; fa = 'Creating:';
					|it = 'Creazione:';
					|pl = 'Creating:';
					|tr = 'Oluşturuldu:'"),
				GetURL(CreatedRule.Ref),
				String(CreatedRule.Ref),
				PictureLib.Information32);
		EndDo;
		
	EndIf;
	
EndProcedure

// Fills in the correspondence of BID forms to document management objects.
//
// Parameters:
//   MatchingForms - Map of KeyAndValue - implicitly returned value, matching Forms:
//     * Key - String - type of the XDTO object.
//     * Value - String - The name of the form.
//
Procedure FillInMatchingForms(MatchingForms) Export
	
	MatchingForms.Insert("DMBusinessProcessInternalDocumentProcessing", "BusinessProcessInternalDocumentProcessing");
	MatchingForms.Insert("DMBusinessProcessIncomingDocumentProcessing", "BusinessProcessIncomingDocumentProcessing");
	MatchingForms.Insert("DMBusinessProcessOutgoingDocumentProcessing", "BusinessProcessOutgoingDocumentProcessing");
	
	MatchingForms.Insert("DMBusinessProcessPerformance", "BusinessProcessExecution");
	MatchingForms.Insert("DMBusinessProcessAcquaintance", "BusinessProcessExamination");
	MatchingForms.Insert("DMBusinessProcessOrder", "BusinessProcessInstructions_");
	MatchingForms.Insert("DMBusinessProcessConsideration", "BusinessProcessReview");
	MatchingForms.Insert("DMBusinessProcessRegistration", "BusinessProcessRegistration");
	MatchingForms.Insert("DMBusinessProcessApproval", "BusinessProcessApproval");
	MatchingForms.Insert("DMBusinessProcessConfirmation", "BusinessProcessAdoption");
	
	MatchingForms.Insert("DMBusinessProcessTask", "Task");
	MatchingForms.Insert("DMBusinessProcessOrderTaskCheckup", "Task");
	MatchingForms.Insert("DMBusinessProcessApprovalTaskApproval", "Task");
	MatchingForms.Insert("DMBusinessProcessApprovalTaskCheckup", "Task");
	MatchingForms.Insert("DMBusinessProcessConfirmationTaskConfirmation", "Task");
	MatchingForms.Insert("DMBusinessProcessConfirmationTaskCheckup", "Task");
	MatchingForms.Insert("DMBusinessProcessRegistrationTaskRegistration", "Task");
	MatchingForms.Insert("DMBusinessProcessRegistrationTaskCheckup", "Task");
	MatchingForms.Insert("DMBusinessProcessPerfomanceTaskCheckup", "Task");
	MatchingForms.Insert("DMBusinessProcessConsiderationTaskAcquaint", "Task");
	MatchingForms.Insert("DMBusinessProcessIssuesSolutionTaskQuestion", "Task");
	MatchingForms.Insert("DMBusinessProcessIssuesSolutionTaskAnswer", "Task");
	MatchingForms.Insert("DMBusinessProcessInvitationTaskInvitation", "Task");
	MatchingForms.Insert("DMBusinessProcessInvitationTaskAcquaint", "Task");
	MatchingForms.Insert("DMBusinessProcessInvitationTaskNotify", "Task");
	
	MatchingForms.Insert("DMInternalDocument", "InternalDocument");
	MatchingForms.Insert("DMIncomingDocument", "IncomingDocument");
	MatchingForms.Insert("DMOutgoingDocument", "OutgoingDocument");
	
	MatchingForms.Insert("DMInternalDocumentFolder", "InternalDocumentFolder");
	
	// complex processes.
	If IntegrationWith1CDocumentManagementCoreClientCached.FunctionalityOfServiceVersionIsAvailable("1.2.6.2") Then
		MatchingForms.Insert("DMComplexBusinessProcess", "BusinessProcessCompositeProcess");
	EndIf;
	
	// invitation, questions to the author.
	If IntegrationWith1CDocumentManagementCoreClientCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3") Then
		MatchingForms.Insert("DMBusinessProcessInvitation", "BusinessProcessInvitation");
		MatchingForms.Insert("DMBusinessProcessIssuesSolution", "BusinessProcessIssueSolving");
	EndIf;
	
	// Mail.
	If IntegrationWith1CDocumentManagementCoreClientCached.FunctionalityOfServiceVersionIsAvailable("1.2.8.1.CORP") Then
		MatchingForms.Insert("DMIncomingEMail", "Incoming_Email");
		MatchingForms.Insert("DMOutgoingEMail", "Outgoing_Email");
	EndIf;
	
	// daily reports and work with contractors.
	If IntegrationWith1CDocumentManagementCoreClientCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3") Then
		MatchingForms.Insert("DMDailyReport", "DailyReport");
		MatchingForms.Insert("DMCorrespondent", "Counterparty");
	EndIf;
	
EndProcedure

// Opens the modal form for configuring the auto-update of the list. At the end of the dialog
// , sets the selected parameters for auto-updating the list.
//
// Parameters:
//   Form - ClientApplicationForm - the unique identifier of the open form.
//   ListName - String - the name of the list details on the form.
//
Procedure SetParametersForAutoUpdatingList(Form, ListName) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("AutoRefresh", Form.Items[ListName].AutoRefresh);
	FormParameters.Insert("AutoRefreshPeriod", Form.Items[ListName].AutoRefreshPeriod);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Form", Form);
	NotificationParameters.Insert("ListName", ListName);
	
	Notification = New CallbackDescription(
		"SetParametersForAutoUpdatingListCompletion",
		IntegrationWith1CDocumentManagementClient,
		NotificationParameters);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SettingAutoupdate",
		FormParameters,
		Form,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Completes the setting of the list auto-update parameters after closing the settings window.
//
// Parameters:
//   Result - Structure:
//     * AutoRefresh - Boolean
//     * AutoRefreshPeriod - Number - period in seconds.
//   NotificationParameters - Structure:
//     * Form - ClientApplicationForm
//     * ListName - String
//
Procedure SetParametersForAutoUpdatingListCompletion(Result, NotificationParameters) Export
	
	Form = NotificationParameters.Form;
	ListName = NotificationParameters.ListName;
	
	If ValueIsFilled(Result) Then
		IntegrationWith1CDocumentManagementServerCall.SaveListAutoUpdateSettings(
			Form.FormName,
			ListName,
			Result);
		
		Form.Items[ListName].AutoRefresh = Result.AutoRefresh;
		Form.Items[ListName].AutoRefreshPeriod = Result.AutoRefreshPeriod;
		If Result.AutoRefresh Then
			Form.Items[ListName].Refresh();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Documents

// Opens the document status window for editing or viewing.
//
// Parameters:
//   Form - ClientApplicationForm - the form of processing corresponding to the document.
//   ReadOnly - Boolean - True if the form should be opened for viewing.
//
Procedure OpenDocumentStates(Form, ReadOnly = False) Export
	
	If Form.ID = "" Or Form.Type = "" Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Document", Form.Presentation);
	FormParameters.Insert("DocumentID", Form.ID);
	FormParameters.Insert("DocumentType", Form.Type);
	
	States1 = New Structure;
	States1.Insert("StateRegistration");
	States1.Insert("StateReviewal");
	States1.Insert("StateApproval");
	States1.Insert("StateConfirmation");
	If Form.Type = "DMInternalDocument" Then
		States1.Insert("StateSigning");
	EndIf;
	States1.Insert("StatePerformance");
	For Each KeyValue In States1 Do
		AttributeName = KeyValue.Key;
		FormParameters.Insert(AttributeName, Form[AttributeName]);
		FormParameters.Insert(AttributeName + "ID", Form[AttributeName + "ID"]);
		FormParameters.Insert(AttributeName + "Type", Form[AttributeName + "Type"]);
	EndDo;
	
	FormParameters.Insert("ReadOnly", ReadOnly);
	
	Notification = New CallbackDescription(
		"OpenDocumentStatesCompletion",
		IntegrationWith1CDocumentManagementClient,
		Form);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.DocumentStates",
		FormParameters, Form,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// After closing the document status window, it transfers the changes to the document form.
//
// Parameters:
//   Result - Structure:
//     * StatePerformance - String
//     * StatePerformanceID - String
//     * StatePerformanceType - String
//     * StateSigning - String
//     * StateSigningID - String
//     * StateSigningType - String
//     * StateReviewal - String
//     * StateReviewalID - String
//     * StateReviewalType - String
//     * StateRegistration - String
//     * StateRegistrationID - String
//     * StateRegistrationType - String
//     * StateApproval - String
//     * StateApprovalID - String
//     * StateApprovalType - String
//     * StateConfirmation - String
//     * StateConfirmationID - String
//     * StateConfirmationType - String
//   Form - ClientApplicationForm
//
Procedure OpenDocumentStatesCompletion(Result, Form) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Attributes = New Structure;
	Attributes.Insert("StateRegistration");
	Attributes.Insert("StateReviewal");
	Attributes.Insert("StateApproval");
	Attributes.Insert("StateConfirmation");
	If Form.Type = "DMInternalDocument" Then
		Attributes.Insert("StateSigning");
	EndIf;
	Attributes.Insert("StatePerformance");
	Form.StateList.Clear();
	
	For Each Attribute In Attributes Do
		AttributeName = Attribute.Key;
		Form[AttributeName] = Result[AttributeName];
		Form[AttributeName + "ID"] = Result[AttributeName + "ID"];
		Form[AttributeName + "Type"] = Result[AttributeName + "Type"];
		
		If ValueIsFilled(Result[AttributeName + "ID"]) Then
			Form.StateList.Add(
				Result[AttributeName + "ID"],
				Result[AttributeName]);
		EndIf;
	EndDo;
	
	If Form.StateList.Count() > 1 Then
		For Each Item In Form.StateList Do
			If Item.Value = "Project" Then
				Form.StateList.Delete(Item);
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Form.Modified = True;
	Notify("UpdateOverview",, Form);
	
EndProcedure

// Opens the window for changing the expiration date of the document for editing or viewing.
//
// Parameters:
//   Form - ClientApplicationForm:
//     * Description - String
//   ReadOnly - Boolean - True if the form should be opened for viewing.
//
Procedure OpenDocumentExpiration(Form, ReadOnly = False) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Document", Form.Description);
	FormParameters.Insert("DocumentID", Form.ID);
	FormParameters.Insert("DocumentType", Form.Type);
	FormParameters.Insert("ValidityStartDate", Form.ValidityStartDate);
	FormParameters.Insert("ValidityEndDate", Form.ValidityEndDate);
	FormParameters.Insert("ExtensionProcedure", Form.ExtensionProcedure);
	FormParameters.Insert("ExtensionProcedureID", Form.ExtensionProcedureID);
	FormParameters.Insert("ExtensionProcedureType", Form.ExtensionProcedureType);
	FormParameters.Insert("Permanent", Form.Permanent);
	
	FormParameters.Insert("ReadOnly", ReadOnly);
	Notification = New CallbackDescription(
		"OpenDocumentExpirationCompletion",
		IntegrationWith1CDocumentManagementClient,
		Form);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement.Form.PeriodOfValidityChange",
		FormParameters,
		Form,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// After closing the document expiration window, it transfers the changes to the document form.
//
// Parameters:
//   Result - Structure:
//     * Permanent - Boolean
//     * ValidityStartDate - Date
//     * ValidityEndDate - Date
//     * ExtensionProcedure - String
//     * ExtensionProcedureID - String
//     * ExtensionProcedureType - String
//   Form - ClientApplicationForm
//
Procedure OpenDocumentExpirationCompletion(Result, Form) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(Form, Result);
	Form.ValidityPeriodPresentation = IntegrationWith1CDocumentManagementClientServer.PresentationOfValidityPeriodOfDocument(
		Result.ValidityStartDate,
		Result.Permanent,
		Result.ValidityEndDate,
		Result.ExtensionProcedureID,
		Result.ExtensionProcedure);
	
	Form.Modified = True;
	Notify("UpdateOverview",, Form);
	
EndProcedure

// Opens the visa approval document.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the owner document.
//   EndorsementOfApproval - FormDataStructure:
//     * ApprovingPerson - String
//     * ApprovingPersonID - String
//     * ApprovingPersonType - String
//     * Date - Date
//     * Result - String
//     * ResultID - String
//     * ResultType - String
//     * Comment - String
//     * CaptionStatusImage - Picture
//     * Contributed - String
//     * ContributedID - String
//     * ContributedType - String
//     * ID - String
//     * Type - String
//     * Description - String
//
Procedure OpenVisa(Form, EndorsementOfApproval) Export
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Description", EndorsementOfApproval.Description);
	FormParameters.Insert("ID", EndorsementOfApproval.ID);
	FormParameters.Insert("Type", EndorsementOfApproval.Type);
	
	FormParameters.Insert("Contributed", EndorsementOfApproval.Contributed);
	FormParameters.Insert("ContributedID", EndorsementOfApproval.ContributedID);
	FormParameters.Insert("ContributedType", EndorsementOfApproval.ContributedType);
	
	FormParameters.Insert("ApprovingPerson", EndorsementOfApproval.ApprovingPerson);
	FormParameters.Insert("ApprovingPersonID", EndorsementOfApproval.ApprovingPersonID);
	FormParameters.Insert("ApprovingPersonType", EndorsementOfApproval.ApprovingPersonType);
	
	FormParameters.Insert("Result", EndorsementOfApproval.Result);
	FormParameters.Insert("ResultID", EndorsementOfApproval.ResultID);
	FormParameters.Insert("ResultType", EndorsementOfApproval.ResultType);
	
	FormParameters.Insert("Date", EndorsementOfApproval.Date);
	FormParameters.Insert("Comment", EndorsementOfApproval.Comment);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.EndorsementOfApproval",
		FormParameters, Form,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Opens the document composition window.
//
// Parameters:
//   Form - ClientApplicationForm - the form of processing corresponding to the document.
//
Procedure OpenDocumentComposition(Form) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Document", Form.Presentation);
	FormParameters.Insert("DocumentID", Form.ID);
	FormParameters.Insert("DocumentType", Form.Type);
	
	FormParameters.Insert("SheetQuantity", Form.SheetQuantity);
	FormParameters.Insert("NumberOfApplications", Form.NumberOfApplications);
	FormParameters.Insert("SheetsInApplications", Form.SheetsInApplications);
	FormParameters.Insert("Copies", Form.Copies);
	
	Notification = New CallbackDescription(
		"OpenDocumentCompositionCompletion",
		IntegrationWith1CDocumentManagementClient,
		Form);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.DocumentContents",
		FormParameters, Form,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// After closing the document composition window, it transfers the changes to the document form.
//
// Parameters:
//   Result - Structure:
//     * SheetQuantity - Number
//     * NumberOfApplications - Number
//     * Copies - Number
//     * SheetsInApplications - Number
//   Form - ClientApplicationForm
//
Procedure OpenDocumentCompositionCompletion(Result, Form) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Form.SheetQuantity = Result.SheetQuantity;
	Form.NumberOfApplications = Result.NumberOfApplications;
	Form.SheetsInApplications = Result.SheetsInApplications;
	Form.Copies = Result.Copies;
	
	Form.CompositionString = IntegrationWith1CDocumentManagementClientServer.GetDocumentCompositionString(Form);
	
	Form.Modified = True;
	Notify("UpdateOverview",, Form);
	
EndProcedure

// Opens the case nomenclature selection window.
//
// Parameters:
//   Form - ClientApplicationForm - the form of processing corresponding to the document.
//
Procedure OpenProductList(Form) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Document", Form.Presentation);
	FormParameters.Insert("DocumentID", Form.ID);
	FormParameters.Insert("DocumentType", Form.Type);
	
	FormParameters.Insert("DocumentKind", Form.DocumentKind);
	FormParameters.Insert("DocumentKindID", Form.DocumentKindID);
	FormParameters.Insert("DocumentKindType", Form.DocumentKindType);
	
	FormParameters.Insert("QuestionOfActivity", Form.QuestionOfActivity);
	FormParameters.Insert("QuestionOfActivityID", Form.QuestionOfActivityID);
	FormParameters.Insert("QuestionOfActivityType", "DMActivityMatter");
	
	FormParameters.Insert("CaseFileNomenclature", Form.CaseFileNomenclature);
	FormParameters.Insert("CaseFileNomenclatureID", Form.CaseFileNomenclatureID);
	FormParameters.Insert("CaseFileNomenclatureType", "DMCaseFilesCatalog");
	FormParameters.Insert("CaseFileNomenclatureYear", Form.CaseFileNomenclatureYear);
	
	FormParameters.Insert("Counterparty", Form.Counterparty);
	FormParameters.Insert("CounterpartyID", Form.CounterpartyID);
	FormParameters.Insert("CounterpartyType", "DMCorrespondent");
	
	FormParameters.Insert("Organization", Form.Organization);
	FormParameters.Insert("OrganizationID", Form.OrganizationID);
	FormParameters.Insert("OrganizationType", "DMOrganization");
	
	FormParameters.Insert("Department", Form.Department);
	FormParameters.Insert("DepartmentID", Form.DepartmentID);
	FormParameters.Insert("DepartmentType", "DMSubdivision");
	
	Notification = New CallbackDescription(
		"OpenProductListCompletion",
		IntegrationWith1CDocumentManagementClient,
		Form);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingCaseFilesCatalog",
		FormParameters, Form,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// After closing the document composition window, it transfers the changes to the document form.
//
// Parameters:
//   Result - Structure:
//     * CaseFileNomenclature - String
//     * CaseFileNomenclatureID - String
//     * CaseFileNomenclatureType - String
//     * CaseFileNomenclatureYear - Number
//   Form - ClientApplicationForm
//
Procedure OpenProductListCompletion(Result, Form) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Form.CaseFileNomenclature = Result.CaseFileNomenclature;
	Form.CaseFileNomenclatureID = Result.CaseFileNomenclatureID;
	Form.CaseFileNomenclatureType = Result.CaseFileNomenclatureType;
	Form.CaseFileNomenclatureYear = Result.CaseFileNomenclatureYear;
	
	Form.Modified = True;
	Notify("UpdateOverview",, Form);
	
EndProcedure

// Opens the Document Storage case selection window.
//
// Parameters:
//   Form - ClientApplicationForm - the form of processing corresponding to the document.
//
Procedure OpenDocumentStorageCase(Form) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Document", Form.Presentation);
	FormParameters.Insert("DocumentID", Form.ID);
	FormParameters.Insert("DocumentType", Form.Type);
	
	FormParameters.Insert("RegistrationDate", Form.RegistrationDate);
	
	FormParameters.Insert("QuestionOfActivity", Form.QuestionOfActivity);
	FormParameters.Insert("QuestionOfActivityID", Form.QuestionOfActivityID);
	FormParameters.Insert("QuestionOfActivityType", "DMActivityMatter");
	
	FormParameters.Insert("DocumentKind", Form.DocumentKind);
	FormParameters.Insert("DocumentKindID", Form.DocumentKindID);
	FormParameters.Insert("DocumentKindType", Form.DocumentKindType);
	
	FormParameters.Insert("ToDoItem", Form.ToDoItem);
	FormParameters.Insert("ToDoItemID", Form.ToDoItemID);
	FormParameters.Insert("ToDoItemType", "DMCaseFilesDossiers");
	
	FormParameters.Insert("CaseFileNomenclature", Form.CaseFileNomenclature);
	FormParameters.Insert("CaseFileNomenclatureID", Form.CaseFileNomenclatureID);
	FormParameters.Insert("CaseFileNomenclatureType", "DMCaseFilesCatalog");
	
	FormParameters.Insert("Counterparty", Form.Counterparty);
	FormParameters.Insert("CounterpartyID", Form.CounterpartyID);
	FormParameters.Insert("CounterpartyType", "DMCorrespondent");
	
	FormParameters.Insert("Organization", Form.Organization);
	FormParameters.Insert("OrganizationID", Form.OrganizationID);
	FormParameters.Insert("OrganizationType", "DMOrganization");
	
	FormParameters.Insert("Department", Form.Department);
	FormParameters.Insert("DepartmentID", Form.DepartmentID);
	FormParameters.Insert("DepartmentType", "DMSubdivision");
	
	Notification = New CallbackDescription(
		"OpenDocumentStorageCaseCompletion",
		IntegrationWith1CDocumentManagementClient,
		Form);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingArchiveCaseFile",
		FormParameters, Form,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// After closing the document composition window, it transfers the changes to the document form.
//
// Parameters:
//   Result - Structure:
//     * ToDoItem - String
//     * ToDoItemID - String
//     * ToDoItemType - String
//   Form - ClientApplicationForm
//
Procedure OpenDocumentStorageCaseCompletion(Result, Form) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Form.ToDoItem = Result.ToDoItem;
	Form.ToDoItemID = Result.ToDoItemID;
	Form.ToDoItemType = Result.ToDoItemType;
	
	Form.Modified = True;
	Notify("UpdateOverview",, Form);
	
EndProcedure

#EndRegion

#Region BusinessProcesses

// Creates a business process based on the document BEFORE.
//
// Parameters:
//   Id - String - the ID of the foundation document.
//   Type - String - the document type is grounds.
//   Description - String - the name of the document is the basis.
//   ExternalObject - AnyRef - a link to the associated IP object.
//
Procedure CreateABusinessProcessByTheObjectDM(Id, Type, Description, ExternalObject) Export
	
	SubjectOf = New Structure;
	SubjectOf.Insert("ID", Id);
	SubjectOf.Insert("type", Type);
	SubjectOf.Insert("name", Description);
	SubjectOf.Insert("ExternalObject", ExternalObject);
	
	CreateBusinessProcess(SubjectOf);
	
EndProcedure

// Creates a business process. When passing a reference to an object as a subject, the IC creates a related
// object BEFORE, if this relationship has not been established before.
//
// Parameters:
//   SubjectOf - AnyRef
//           - Structure:
//     * ID - String
//     * type - String
//     * name - String
//     * ExternalObject - AnyRef
//   MainTask - Structure:
//     * ID - String
//     * type - String
//     * name - String
//   CallbackDescription - CallbackDescription - description of the notification that is called at the end.
//
Procedure CreateBusinessProcess(SubjectOf = Undefined, MainTask = Undefined,
		CallbackDescription = Undefined) Export
	
	Cancel = False;
	IntegrationWith1CDocumentManagementCoreClientOverridable.BeforeCreatingBusinessProcess(SubjectOf, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("MainTask", MainTask);
	Parameters.Insert("CallbackDescription", CallbackDescription);
	Parameters.Insert("SubjectOf", SubjectOf);
	
	CallbackDescriptionContinued = New CallbackDescription(
		"CreateABusinessProcessAfterSearchingForARelatedObjectDM",
		IntegrationWith1CDocumentManagementClient,
		Parameters);
	
	If SubjectOf = Undefined Or TypeOf(SubjectOf) = Type("Structure") Then
		RunCallback(CallbackDescriptionContinued, SubjectOf);
	Else
		IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
			SubjectOf,
			CallbackDescriptionContinued);
	EndIf;
	
EndProcedure

// Continues the creation of the business process after searching for the associated object BEFORE.
//
// Parameters:
//   Result - Undefined
//             - Structure:
//     * ID - String
//     * type - String
//     * name - String
//   Parameters - Structure:
//     * MainTask- Structure:
//         ** ID - String
//         ** type - String
//         ** name - String
//     * CallbackDescription - CallbackDescription - description of the notification that is called at the end.
//     * SubjectOf - AnyRef,
//               - Structure:
//         ** ID - String
//         ** type - String
//         ** name - String
//         ** ExternalObject - AnyRef
//
Procedure CreateABusinessProcessAfterSearchingForARelatedObjectDM(Result, Parameters) Export
	
	// Let's distinguish the case when the item is not selected from the case when the item is not needed.
	If Parameters.SubjectOf <> Undefined Then
		If Result = Undefined Then
			Return;
		EndIf;
		Parameters.SubjectOf = Result;
	EndIf;
	
	// getting a tree of process templates.
	If IntegrationWith1CDocumentManagementCoreClientCached.FunctionalityOfServiceVersionIsAvailable("1.2.6.2") Then
		
		CallbackDescription = Parameters.CallbackDescription;
		Parameters.CallbackDescription = Undefined;
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.CreatingBusinessProcess",
			Parameters,,,,, CallbackDescription);
		
	Else
		
		Notification = New CallbackDescription("CompatibilitySupport_CreateBusinessProcessCompletion",
			ThisObject, Parameters);
		
		StartSelectingTypeOfBusinessProcess(Notification);
		
	EndIf;
	
EndProcedure

// Sets the result of selecting a business process participant
// from the list that is generated during auto-selection to the row of the business process participants table.
//
// Parameters:
//   Item - FormTable - table of business process participants.
//   ValueSelected - AnyRef - the structure of the selected value.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//   Form - ClientApplicationForm - a form with a table of business process participants.
//
Procedure ApplyBusinessProcessParticipantSelectionInList(Item, ValueSelected, StandardProcessing, Form) Export
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		
		StandardProcessing = False;
		
		If ValueSelected.type = "DMUser" Then
			
			Item.CurrentData.Performer = ValueSelected.Name;
			Item.CurrentData.PerformerID = ValueSelected.ID;
			Item.CurrentData.PerformerType = ValueSelected.type;
			Form.Modified = True;
			
		ElsIf ValueSelected.type = "DMBusinessProcessExecutorRole" Then
			
			NotificationParameters = New Structure;
			NotificationParameters.Insert("Form", Form);
			NotificationParameters.Insert("Item", Item);
			
			Notification = New CallbackDescription(
				"ApplyBusinessProcessParticipantSelectionInListCompletion",
				IntegrationWith1CDocumentManagementClient,
				NotificationParameters);
			
			IntegrationWith1CDocumentManagementCoreClient.ShowGettingAddressingObjectsOfRole(
				Notification,
				ValueSelected.Name,
				ValueSelected.type,
				ValueSelected.ID,
				Form);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Sets in the field on the form the result of selecting a business process participant from the list
// that is generated during auto-selection.
//
// Parameters:
//   FieldName - String - the name of the details of the participant in the business process of the form.
//   FieldNameOfAddressingObject - String - the name of the address object's details.
//   ValueSelected - Structure:
//     * name - String - the name of the selected participant in the business process.
//     * ID - String - ID of the selected business process participant.
//     * type - String - the type of the selected business process participant.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//   Form - ClientApplicationForm - a managed form with a business process participant selection field.
//
Procedure ApplyBusinessProcessParticipantSelectionInField(FieldName, FieldNameOfAddressingObject, ValueSelected,
		StandardProcessing, Form) Export
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		
		StandardProcessing = False;
		
		If ValueSelected.type = "DMUser" Then
			
			Form[FieldName] = ValueSelected.Name;
			Form[FieldName + "ID"] = ValueSelected.ID;
			Form[FieldName + "Type"] = ValueSelected.type;
			Form.Modified = True;
			
		ElsIf ValueSelected.type = "DMBusinessProcessExecutorRole" Then
			
			NotificationParameters = New Structure;
			NotificationParameters.Insert("Form", Form);
			NotificationParameters.Insert("FieldName", FieldName);
			NotificationParameters.Insert("FieldNameOfAddressingObject", FieldNameOfAddressingObject);
			
			Notification = New CallbackDescription(
				"ApplyBusinessProcessParticipantSelectionInFieldCompletion",
				IntegrationWith1CDocumentManagementClient,
				NotificationParameters);
			
			IntegrationWith1CDocumentManagementCoreClient.ShowGettingAddressingObjectsOfRole(
				Notification,
				ValueSelected.Name,
				ValueSelected.type,
				ValueSelected.ID,
				Form);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Select the type of business process.
// Opens the dialog for selecting the type of business process to start.
//
// Parameters:
//   OnCloseNotifyDescription - CallbackDescription
//
Procedure StartSelectingTypeOfBusinessProcess(OnCloseNotifyDescription) Export
	
	TypesOfXDTO = New Array;
	TypesOfXDTO.Add("DMBusinessProcessPerformance");
	TypesOfXDTO.Add("DMBusinessProcessAcquaintance");
	TypesOfXDTO.Add("DMBusinessProcessOrder");
	TypesOfXDTO.Add("DMBusinessProcessConsideration");
	TypesOfXDTO.Add("DMBusinessProcessRegistration");
	TypesOfXDTO.Add("DMBusinessProcessApproval");
	TypesOfXDTO.Add("DMBusinessProcessConfirmation");
	TypesOfXDTO.Add("DMBusinessProcessInternalDocumentProcessing");
	TypesOfXDTO.Add("DMBusinessProcessIncomingDocumentProcessing");
	TypesOfXDTO.Add("DMBusinessProcessOutgoingDocumentProcessing");
	
	ListOfAvailableBusinessProcessTypes = New ValueList;
	For Each XDTOType In TypesOfXDTO Do
		Presentation = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(XDTOType);
		ListOfAvailableBusinessProcessTypes.Add(
			New Structure("XDTOClassName, Presentation", XDTOType, Presentation));
	EndDo;
	
	FormCaption = NStr("vi = 'Dạng quy trình nghiệp vụ';
						|ru = 'Тип бизнес-процесса';
						|en = 'Type of business process'; fa = 'Type of business process';
						|it = 'Tipo di processo aziendale';
						|pl = 'Typ procesu biznesowego';
						|tr = 'İş süreci türü'");
	FormParameters = New Structure("AvailableTypeList, FormCaption",
		ListOfAvailableBusinessProcessTypes, FormCaption);
	
	FormName = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingOneTypeFromCompositeType";
	OpenForm(FormName, FormParameters,,,,, OnCloseNotifyDescription);
	
EndProcedure

// Opens the form for selecting a business process template from the list.
//
// Parameters:
//   OnCloseNotifyDescription - CallbackDescription - description of the closure notification
//   Form - ClientApplicationForm - the form of the Workflow business process
//
Procedure StartSelectingBusinessProcessTemplate(OnCloseNotifyDescription, Form) Export
	
	SubjectData = Undefined;
	
	If ValueIsFilled(Form.SubjectOf) Then
		SubjectData = New Structure;
		SubjectData.Insert("ID", Form.SubjectOfID);
		SubjectData.Insert("type", Form.SubjectOfType);
	EndIf;
	
	TemplateList = IntegrationWith1CDocumentManagementServerCall.BusinessProcessTemplates(Form.Type, SubjectData);
	
	If TemplateList.Count() > 1 Then
		FormParameters = New Structure("ListOfValuesToSelect", TemplateList);
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList",
			FormParameters, Form,,,, OnCloseNotifyDescription);
		
	ElsIf TemplateList.Count() = 1 Then
		TemplateSelectionResult = New Structure("AttributeID, AttributeType, AttributePresentation");
		TemplateSelectionResult.AttributeID = TemplateList[0].Value.ID;
		TemplateSelectionResult.AttributeType = TemplateList[0].Value.type;
		TemplateSelectionResult.AttributePresentation = TemplateList[0].Value.Name;
		RunCallback(OnCloseNotifyDescription, TemplateSelectionResult);
		
	Else
		WarningText = NStr("vi = 'Không tìm thấy mẫu quy trình nghiệp vụ phù hợp nào.';
							|ru = 'Не найдено ни одного подходящего шаблона бизнес-процесса.';
							|en = 'No suitable business process template is found.'; fa = 'No suitable business process template is found.';
							|it = 'Non è stato trovato nessun modello adeguato di processo aziendale.';
							|pl = 'Nie znaleziono ani jednego pasującego szablonu procesu biznesowego.';
							|tr = 'Hiç bir uygun iş süreci numunesi bulunamadı.'");
		ShowMessageBox(, WarningText);
		RunCallback(OnCloseNotifyDescription, Undefined);
	EndIf;
	
EndProcedure

// Starts the approval process in UP to the specified object.
//
// Parameters:
//   Parameters - Structure:
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * Source - ClientApplicationForm - optional, the source of the command.
//     * CallbackDescription - CallbackDescription - optional, called in case of successful launch.
//
Procedure StartApproval(Parameters) Export
	
	Cancel = False;
	IntegrationWith1CDocumentManagementCoreClientOverridable.BeforeCreatingBusinessProcess(Parameters.SubjectOfApproval, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	// Unify the composition of the parameters.
	If Not Parameters.Property("CallbackDescription") Then
		Parameters.Insert("CallbackDescription", Undefined);
	EndIf;
	If Not Parameters.Property("Source") Then
		Parameters.Insert("Source", Undefined);
	EndIf;
	
	DescriptionOfAlertAfterAlert = New CallbackDescription(
		"ReconciliationCommandsAfterWarning",
		ThisObject,
		Parameters);
	
	// Let's check the possibility of starting approval.
	WarningText = "";
	If Not IntegrationWith1CDocumentManagementServerCall.UserIsAllowedToStartMatching(
			Parameters.SubjectOfApproval, WarningText) Then
		If WarningText = "" Then // Default text.
			WarningText = NStr("vi = 'Không đủ quyền để khởi chạy quy trình thống nhất trong 1C:Document Management.';
								|ru = 'Недостаточно прав для запуска согласования в 1С:Документообороте.';
								|en = 'Insufficient rights for approval launch in 1C:Document Management.'; fa = 'Insufficient rights for approval launch in 1C:Document Management.';
								|it = 'Diritti insufficienti per l''avvio dell''accordo in 1C:Document Management.';
								|pl = 'Nie wystarcza praw do uruchomienia uzgodnienia w 1C:Document Management.';
								|tr = '1C:Document Management''te anlaşmayı başlatmak için yeterli yetki mevcut değil.'");
		EndIf;
		ShowMessageBox(DescriptionOfAlertAfterAlert, WarningText);
		Return;
	EndIf;
	
	DescriptionOfAlertAfterSearchingForRelatedObject = New CallbackDescription(
		"StartMatchingAfterSearchingForRelatedObject",
		ThisObject,
		Parameters);
	
	IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
		Parameters.SubjectOfApproval,
		DescriptionOfAlertAfterSearchingForRelatedObject);
	
EndProcedure

// Continues the reconciliation process after finding or creating a linked object.
//
// Parameters:
//   Result - Structure:
//     * name - String
//     * ID - String
//     * type - String
//   Parameters - Structure:
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * Source - ClientApplicationForm - optional, the source of the command.
//     * CallbackDescription - CallbackDescription - optional, called in case of successful launch.
//
Procedure StartMatchingAfterSearchingForRelatedObject(Result, Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Parameters.Insert("SubjectOf", Result);
	
	InterruptFormParameters = New Structure;
	InterruptFormParameters.Insert("SubjectOf", Parameters.SubjectOf);
	InterruptFormParameters.Insert("RepeatedStart", True);
	DescriptionOfNotificationAfterQuestion = New CallbackDescription(
		"StartApprovalAfterQuestion",
		ThisObject,
		Parameters);
	Open_Form = OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement.Form.ApprovalTermination",
		InterruptFormParameters,,,,,
		DescriptionOfNotificationAfterQuestion,
		FormWindowOpeningMode.LockWholeInterface);
	
	If Open_Form = Undefined Then // There is no visa approval, there is no need to show the sheet.
		RunCallback(DescriptionOfNotificationAfterQuestion, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

// Continues to run the negotiation in BEFORE after showing the question about restarting previously started processes.
//
// Parameters:
//   Result - DialogReturnCode
//   Parameters - Structure:
//     * SubjectOf - Structure:
//       ** name - String
//       ** ID - String
//       ** type - String
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * Source - ClientApplicationForm - optional, the source of the command.
//     * CallbackDescription - CallbackDescription - optional, called in case of successful launch.
//
Procedure StartApprovalAfterQuestion(Result, Parameters) Export
	
	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	// We will get suitable templates.
	SuitableTemplates = IntegrationWith1CDocumentManagementServerCall.BusinessProcessTemplates(
		"DMBusinessProcessApproval",
		Parameters.SubjectOf);
	
	// Let's run a single template or offer a choice of several.
	If SuitableTemplates.Count() = 0 Then
		// Let's open the general form of launching an arbitrary process.
		IntegrationWith1CDocumentManagementServerCall.AbortApproval(Parameters.SubjectOf);
		DescriptionOfAlertAfterInteractiveLaunch = New CallbackDescription(
			"StartMatchingAfterInteractiveLaunch",
			ThisObject,
			Parameters);
		FormParameters = New Structure;
		FormParameters.Insert("SubjectOf", Parameters.SubjectOf);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			"DMBusinessProcessApproval",
			Undefined,,
			FormParameters,
			DescriptionOfAlertAfterInteractiveLaunch);
		ShowUserNotification(NStr("vi = 'Không tìm thấy khuôn mẫu phù hợp.';
									|ru = 'Подходящих шаблонов не найдено.';
									|en = 'No suitable templates found.'; fa = 'No suitable templates found.';
									|it = 'Modelli corrispondenti non trovati.';
									|pl = 'Nie znaleziono pasujących szablonów.';
									|tr = 'Uygun numunesi bulunamadı.'"));
		
	Else // There is a template(s).
		DescriptionOfNotificationAfterSelectingTemplate = New CallbackDescription(
			"StartMatchingAfterSelectingTemplate",
			ThisObject,
			Parameters);
		If SuitableTemplates.Count() = 1 Then
			SelectionResult = New Structure;
			SelectionResult.Insert("AttributePresentation", SuitableTemplates[0].Value.name);
			SelectionResult.Insert("AttributeID", SuitableTemplates[0].Value.ID);
			SelectionResult.Insert("AttributeType", SuitableTemplates[0].Value.type);
			RunCallback(DescriptionOfNotificationAfterSelectingTemplate, SelectionResult);
		Else // We will offer a choice.
			FormParameters = New Structure;
			FormParameters.Insert("Title", NStr("vi = 'Chọn khuôn mẫu thống nhất';
												|ru = 'Выбор шаблона согласования';
												|en = 'Select approval template'; fa = 'Select approval template';
												|it = 'Selezione modello di omologazione';
												|pl = 'Wybór szablonu uzgodnienia';
												|tr = 'Anlaşma numunesi seçimi'"));
			FormParameters.Insert("SelectGroups", False);
			FormParameters.Insert("ListOfValuesToSelect", SuitableTemplates);
			OpenForm(
				"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList",
				FormParameters,,,,,
				DescriptionOfNotificationAfterSelectingTemplate,
				FormWindowOpeningMode.LockWholeInterface);
		EndIf;
		
	EndIf;
	
EndProcedure

// Continues to run the approval in BEFORE after selecting the approval template.
//
// Parameters:
//   Result - Structure:
//     * AttributePresentation - String
//     * AttributeID - String
//     * AttributeType - String
//   Parameters - Structure:
//     * SubjectOf - Structure:
//       ** name - String
//       ** ID - String
//       ** type - String
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * Source - ClientApplicationForm - optional, the source of the command.
//     * CallbackDescription - CallbackDescription - optional, called in case of successful launch.
//
Procedure StartMatchingAfterSelectingTemplate(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then // The template is not selected.
		Return;
	EndIf;
	
	Template = New Structure;
	Template.Insert("name", Result.AttributePresentation);
	Template.Insert("ID",   Result.AttributeID);
	Template.Insert("type", Result.AttributeType);
	
	// We will interrupt other approval processes that we warned the initiator about, or that
	// were started by other users during the time of reflection when choosing a template.
	IntegrationWith1CDocumentManagementServerCall.AbortApproval(Parameters.SubjectOf);
	
	// Let's start the process according to the template.
	If IntegrationWith1CDocumentManagementServerCall.StartMatchingTemplate(Template, Parameters.SubjectOf) Then
		Parameters.Insert(
			"State",
			PredefinedValue("Enum.ApprovalStatesIn1CDocumentManagement.AwaitingApproval"));
		WhenApprovalStateChanges(Parameters);
		If Parameters.CallbackDescription <> Undefined Then
			RunCallback(Parameters.CallbackDescription, True);
		EndIf;
		Notify("DocumentManagement_ApprovalStarted", Parameters.SubjectOfApproval);
		ShowUserNotification(NStr("vi = 'Đã khởi chạy quy trình thống nhất.';
									|ru = 'Согласование запущено.';
									|en = 'Approval is started.'; fa = 'Approval is started.';
									|it = 'Omologazione avviata.';
									|pl = 'Uruchomiono uzgodnienie.';
									|tr = 'Anlaşma başlatıldı.'"));
		
	Else
		// You may need to fill in the required details. Let's open the form of a new process.
		DescriptionOfAlertAfterInteractiveLaunch = New CallbackDescription(
			"StartMatchingAfterInteractiveLaunch",
			ThisObject,
			Parameters);
		FormParameters = New Structure;
		FormParameters.Insert("Template", Template);
		FormParameters.Insert("SubjectOf", Parameters.SubjectOf);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			"DMBusinessProcessApproval",
			Undefined,,
			FormParameters,
			DescriptionOfAlertAfterInteractiveLaunch);
		
	EndIf;
	
EndProcedure

// Completes the start of approval in BEFORE after opening the business process form.
//
// Parameters:
//   Result - Boolean
//   Parameters - Structure:
//     * SubjectOf - Structure:
//       ** name - String
//       ** ID - String
//       ** type - String
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * Source - ClientApplicationForm - optional, the source of the command.
//     * CallbackDescription - CallbackDescription - optional, called in case of successful launch.
//     * State - EnumRef.ApprovalStatesIn1CDocumentManagement
//
Procedure StartMatchingAfterInteractiveLaunch(Result, Parameters) Export
	
	If Result <> True Then
		Return;
	EndIf;
	
	Parameters.Insert(
		"State",
		PredefinedValue("Enum.ApprovalStatesIn1CDocumentManagement.AwaitingApproval"));
	WhenApprovalStateChanges(Parameters);
	If Parameters.CallbackDescription <> Undefined Then
		RunCallback(Parameters.CallbackDescription, True);
	EndIf;
	Notify("DocumentManagement_ApprovalStarted", Parameters.SubjectOfApproval);
	
EndProcedure

// Interrupts the approval processes in UP to the specified object.
//
// Parameters:
//   Parameters - Structure:
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * Source - ClientApplicationForm - optional, the source of the command.
//     * CallbackDescription - CallbackDescription - optional, called if successful.
//
Procedure AbortApproval(Parameters) Export
	
	// Unify the composition of the parameters.
	If Not Parameters.Property("CallbackDescription") Then
		Parameters.Insert("CallbackDescription", Undefined);
	EndIf;
	If Not Parameters.Property("Source") Then
		Parameters.Insert("Source", Undefined);
	EndIf;
	
	DescriptionOfAlertAfterAlert = New CallbackDescription(
		"ReconciliationCommandsAfterWarning",
		ThisObject,
		Parameters);
	
	// Let's check the existence of a linked object.
	LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
		Parameters.SubjectOfApproval);
	If LinkedObjectBefore = Undefined Then
		WarningText = NStr("vi = 'Trong 1C:Document Management chưa khởi chạy quy trình thống nhất.';
							|ru = 'В 1С:Документообороте не запущено согласование.';
							|en = 'Approval is not started in 1C:Document Management.'; fa = 'Approval is not started in 1C:Document Management.';
							|it = 'Non è stata avviata l''omologazione in 1C:Document Management.';
							|pl = 'W 1С:Document Management nie uruchomiono uzgodnienia.';
							|tr = '1C:Document Management''te anlaşma başlatılamadı.'");
		ShowMessageBox(DescriptionOfAlertAfterAlert, WarningText);
		Return;
	EndIf;
	Parameters.Insert("SubjectOf", LinkedObjectBefore);
	
	// Let's check the possibility of interrupting the agreement.
	WarningText = "";
	If Not IntegrationWith1CDocumentManagementServerCall.UserIsAllowedToInterruptNegotiation(
			Parameters.SubjectOfApproval, Parameters.SubjectOf, WarningText) Then
		If WarningText = "" Then // The default warning.
			WarningText = NStr("vi = 'Không đủ quyền để ngắt quy trình thống nhất trong 1C:Document Management.';
								|ru = 'Недостаточно прав для прерывания согласования в 1С:Документообороте.';
								|en = 'Insufficient rights for approval cancellation in 1C:Document Management.'; fa = 'Insufficient rights for approval cancellation in 1C:Document Management.';
								|it = 'Diritti insufficienti per l''interruzione dell''omologazione in 1C:Document Management.';
								|pl = 'Nie wystarcza praw do przerywania uzgodnienia w 1C:Document Management.';
								|tr = '1C:Document Management''te anlaşmayı kesintiye uğratmak için yeterli hak mevcut değil.'");
		EndIf;
		ShowMessageBox(DescriptionOfAlertAfterAlert, WarningText);
		Return;
	EndIf;
	
	InterruptFormParameters = New Structure;
	InterruptFormParameters.Insert("SubjectOf", Parameters.SubjectOf);
	DescriptionOfNotificationAfterQuestion = New CallbackDescription(
		"AbortApprovalAfterQuestion",
		ThisObject,
		Parameters);
	Open_Form = OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.ApprovalTermination",
		InterruptFormParameters,,,,, DescriptionOfNotificationAfterQuestion, FormWindowOpeningMode.LockWholeInterface);
	If Open_Form = Undefined Then // There is no visa approval, there is no need to show the sheet.
		RunCallback(DescriptionOfNotificationAfterQuestion, DialogReturnCode.OK);
	EndIf;
		
EndProcedure

// Continues the process of interrupting the approval after the question is shown.
//
// Parameters:
//   Result - DialogReturnCode
//   Parameters - Structure:
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * Source - ClientApplicationForm - optional, the source of the command.
//     * CallbackDescription - CallbackDescription - optional, called if successful.
//
Procedure AbortApprovalAfterQuestion(Result, Parameters) Export
	
	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementServerCall.AbortApproval(Parameters.SubjectOf);
	
	// We will notify the open forms, the source of the call and the user.
	Parameters.Insert("State", Undefined);
	WhenApprovalStateChanges(Parameters);
	If Parameters.CallbackDescription <> Undefined Then
		RunCallback(Parameters.CallbackDescription, True);
	EndIf;
	Notify("DocumentManagement_ApprovalInterrupted", Parameters.SubjectOfApproval);
	ShowUserNotification(NStr("vi = 'Đã ngắt quy trình thống nhất.';
								|ru = 'Согласование прервано.';
								|en = 'Approval is canceled.'; fa = 'Approval is canceled.';
								|it = 'Omologazione interrotta.';
								|pl = 'Uzgodnienie zostało przerwane.';
								|tr = 'Anlaşma kesildi.'"));
	
EndProcedure

// Performs matching on the specified object with the specified result.
//
// Parameters:
//   Parameters - Structure:
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * Source - ClientApplicationForm - optional, the source of the command.
//     * Result - String - "Agreed", "Agreed notes", "Inconsistent".
//     * CallbackDescription - CallbackDescription - optional, called if successful.
//
Procedure PerformReconciliation(Parameters) Export
	
	// Unify the composition of the parameters.
	If Not Parameters.Property("CallbackDescription") Then
		Parameters.Insert("CallbackDescription", Undefined);
	EndIf;
	If Not Parameters.Property("Source") Then
		Parameters.Insert("Source", Undefined);
	EndIf;
	
	DescriptionOfAlertAfterAlert = New CallbackDescription(
		"ReconciliationCommandsAfterWarning",
		ThisObject,
		Parameters);
	
	// Let's check the existence of a linked object.
	LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
		Parameters.SubjectOfApproval);
	If LinkedObjectBefore = Undefined Then
		WarningText = NStr("vi = 'Trong 1C:Document Management chưa khởi chạy quy trình thống nhất.';
							|ru = 'В 1С:Документообороте не запущено согласование.';
							|en = 'Approval is not started in 1C:Document Management.'; fa = 'Approval is not started in 1C:Document Management.';
							|it = 'Non è stata avviata l''omologazione in 1C:Document Management.';
							|pl = 'W 1С:Document Management nie uruchomiono uzgodnienia.';
							|tr = '1C:Document Management''te anlaşma başlatılamadı.'");
		ShowMessageBox(DescriptionOfAlertAfterAlert, WarningText);
		Return;
	EndIf;
	Parameters.Insert("SubjectOf", LinkedObjectBefore);
	
	// Let's check whether the approval process has been started at all.
	If Not IntegrationWith1CDocumentManagementServerCall.StartedCoordinationOnSubjectDM(Parameters.SubjectOf) Then
		WarningText = NStr("vi = 'Trong 1C:Document Management chưa khởi chạy quy trình thống nhất.';
							|ru = 'В 1С:Документообороте не запущено согласование.';
							|en = 'Approval is not started in 1C:Document Management.'; fa = 'Approval is not started in 1C:Document Management.';
							|it = 'Non è stata avviata l''omologazione in 1C:Document Management.';
							|pl = 'W 1С:Document Management nie uruchomiono uzgodnienia.';
							|tr = '1C:Document Management''te anlaşma başlatılamadı.'");
		ShowMessageBox(DescriptionOfAlertAfterAlert, WarningText);
		Return;
	EndIf;
	
	// Let's check whether the approval tasks are addressed to the user.
	ReconciliationTasks = IntegrationWith1CDocumentManagementServerCall.GetApprovalIssues(Parameters.SubjectOf);
	If ReconciliationTasks.Count() = 0 Then
		QueryText = NStr("vi = 'Trong 1C:Document Management không có nhiệm vụ thống nhất gửi đến người sử dụng hiện tại %1';
						|ru = 'В 1С:Документообороте нет задач согласования, адресованных на текущего пользователя %1';
						|en = '1C:Document Management does not contain any approval tasks addressed to the current user %1'; fa = '1C:Document Management does not contain any approval tasks addressed to the current user %1';
						|it = 'Non vi sono compiti di omologazione in 1C:Document Management indirizzati all''utente corrente %1';
						|pl = 'W 1С:Document Management nie ma zadań uzgodnienia, adresowanych bieżącemu użytkownikowi %1';
						|tr = '1C:Document Management''ta mevcut kullanıcıya yönelik herhangi onay görevi yok %1'");
		Buttons = New ValueList;
		Buttons.Add("OK", NStr("vi = 'Đồng ý';
								|ru = 'ОК';
								|en = 'OK'; fa = 'تأیید';
								|it = 'OK';
								|pl = 'OK';
								|tr = 'Tamam'"));
		Buttons.Add("ApprovalForm", NStr("vi = 'Tờ thống nhất';
										|ru = 'Лист согласования';
										|en = 'Approval sheet '; fa = 'برگه تأیید';
										|it = 'Foglio di omologazione';
										|pl = 'Arkusz uzgodnienia';
										|tr = 'Anlaşma listesi'"));
		DescriptionOfNotificationAfterQuestion = New CallbackDescription(
			"PerformReconciliationAfterQuestion",
			ThisObject,
			Parameters);
		ShowQueryBox(DescriptionOfNotificationAfterQuestion, QueryText, Buttons);
		Return;
	Else // There are tasks addressed to the user.
		Parameters.Insert("ReconciliationTasks", ReconciliationTasks);
		DescriptionOfNotificationAfterEnteringComment = New CallbackDescription(
			"PerformReconciliationAfterEnteringComment",
			ThisObject,
			Parameters);
		If Parameters.Result = "Approved" Then // No comment is needed.
			RunCallback(DescriptionOfNotificationAfterEnteringComment, "");
		Else
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.EnteringExecutionResultTasks",,,,,,
				DescriptionOfNotificationAfterEnteringComment, FormWindowOpeningMode.LockWholeInterface);
		EndIf;
	EndIf;
	
EndProcedure

// Terminates the work of the approval commands after the output of the question.
//
// Parameters:
//   Result - String
//   Parameters - Structure:
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * Source - ClientApplicationForm - optional, the source of the command.
//     * Result - String - "Agreed", "Agreed notes", "Inconsistent".
//     * CallbackDescription - CallbackDescription - optional, called if successful.
//
Procedure PerformReconciliationAfterQuestion(Result, Parameters) Export
	
	If Result <> "ApprovalForm" Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		IntegrationWith1CDocumentManagementCoreClient.ExecutePrintCommand(
			"DataProcessor.IntegrationWith1CDocumentManagement",
			"PF_MXL_ApprovalForm",
			Parameters.SubjectOfApproval,
			Parameters.Source);
	Else
		IntegrationWith1CDocumentManagementCoreClientOverridable.ExecutePrintApprovalSheetCommand(
			Parameters.SubjectOfApproval);
	EndIf;
	
EndProcedure

// Terminates the approval commands after entering a comment.
//
// Parameters:
//   Result - String
//   Parameters - Structure:
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * Source - ClientApplicationForm - optional, the source of the command.
//     * Result - String - "Agreed", "Agreed notes", "Inconsistent".
//     * CallbackDescription - CallbackDescription - optional, called if successful.
//     * SubjectOf - See IntegrationWith1CDocumentManagementCore.ObjectDataUpToExternalObject
//     * ReconciliationTasks - Array of String - ids of the approval tasks in UP to.
//
Procedure PerformReconciliationAfterEnteringComment(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("String") Then // Refusal to enter a comment.
		Return;
	EndIf;
	
	ErrorMessageText = "";
	If Not IntegrationWith1CDocumentManagementServerCall.PerformReconciliation(
			Parameters.ReconciliationTasks, Parameters.Result, Result, ErrorMessageText) Then
		DescriptionOfAlertAfterAlert = New CallbackDescription(
			"ReconciliationCommandsAfterWarning",
			ThisObject,
			Parameters);
		ShowMessageBox(DescriptionOfAlertAfterAlert, ErrorMessageText);
		Return;
	EndIf;
	
	// We will notify the open forms, the source of the call and the user.
	
	If Parameters.Result = "Согласовано" Then //@NON-NLS-1
		Parameters.Insert(
			"State",
			PredefinedValue("Enum.ApprovalStatesIn1CDocumentManagement.Approved"));
		WhenApprovalStateChanges(Parameters);
		Notify("DocumentManagement_Approved", Parameters.SubjectOfApproval);
		ShowUserNotification(NStr("vi = 'Đã thống nhất.';
									|ru = 'Согласовано.';
									|en = 'Approved.'; fa = 'Approved.';
									|it = 'Concordato.';
									|pl = 'Approved.';
									|tr = 'Onaylandı.'"));
		
	ElsIf Parameters.Result = "СогласованоСЗамечаниями" Then //@NON-NLS-1
		Parameters.Insert(
			"State",
			PredefinedValue("Enum.ApprovalStatesIn1CDocumentManagement.Approved"));
		WhenApprovalStateChanges(Parameters);
		Notify("DocumentManagement_ApprovedWithReservations", Parameters.SubjectOfApproval);
		ShowUserNotification(NStr("vi = 'Đã thống nhất và có lưu ý.';
									|ru = 'Согласовано с замечаниями.';
									|en = 'Approved with comments.'; fa = 'Approved with comments.';
									|it = 'Omologato con note.';
									|pl = 'Uzgodniono z uwagami.';
									|tr = 'Yorumlarla onaylandı.'"));
		
	ElsIf Parameters.Result = "НеСогласовано" Then //@NON-NLS-1
		Parameters.Insert(
			"State",
			PredefinedValue("Enum.ApprovalStatesIn1CDocumentManagement.NotApproved"));
		WhenApprovalStateChanges(Parameters);
		Notify("DocumentManagement_NotApproved", Parameters.SubjectOfApproval);
		ShowUserNotification(NStr("vi = 'Không thống nhất.';
									|ru = 'Не согласовано.';
									|en = 'Not approved.'; fa = 'Not approved.';
									|it = 'Non concordato.';
									|pl = 'Nie uzgodniono.';
									|tr = 'Onaylanmadı.'"));
		
	EndIf;
	
	If Parameters.CallbackDescription <> Undefined Then
		RunCallback(Parameters.CallbackDescription, True);
	EndIf;
	
EndProcedure

// Terminates the reconciliation commands after the issue warning is displayed.
//
// Parameters:
//   Parameters - Structure:
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * Source - ClientApplicationForm - optional, the source of the command.
//     * Result - String - "Agreed", "Agreed notes", "Inconsistent".
//     * CallbackDescription - CallbackDescription - optional, called if successful.
//     * SubjectOf - See IntegrationWith1CDocumentManagementCore.ObjectDataUpToExternalObject
//     * ReconciliationTasks - Array of String - ids of the approval tasks in UP to.
//
Procedure ReconciliationCommandsAfterWarning(Parameters) Export
	
	If Parameters.CallbackDescription <> Undefined Then
		RunCallback(Parameters.CallbackDescription, False);
	EndIf;
	
EndProcedure

// Called when the state of the agreement changes to BEFORE. Changes the state on the IC side.
//
// Parameters:
//   Parameters - Structure:
//     * SubjectOfApproval - AnyRef - a consistent object.
//     * SubjectOf - Structure - description of the linked object BEFORE.
//     * State - EnumRef.ApprovalStatesIn1CDocumentManagement - new state.
//                 - Undefined - in case of termination of the agreement.
//     * Source - ClientApplicationForm:
//         ** Object - DefinedType.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable
//                   - DefinedType.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable
//
Procedure WhenApprovalStateChanges(Parameters) Export
	
	// Let's determine the source of the call. If this is the form of a consistent object, then you should not
	// change the state of the object in the database in order to avoid the effect of optimistic locking.
	If Parameters.Source = Undefined Then
		CallingFromObjectForm = False;
	Else
		Try
			Object = Parameters.Source.Object;
			CallingFromObjectForm = ValueIsFilled(Object.Ref);
		Except
			CallingFromObjectForm = False;
		EndTry;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCall.WhenApprovalStateChanges(
		Parameters.SubjectOf.ID,
		Parameters.SubjectOf.type,
		Parameters.State,
		CallingFromObjectForm,
		Parameters.SubjectOfApproval);
	
	IntegrationWith1CDocumentManagementCoreClientOverridable.WhenApprovalStateChanges(
		Parameters.SubjectOfApproval,
		Parameters.Source,
		Parameters.State,
		CallingFromObjectForm);
		
EndProcedure

// Starts the process of adding an item to a process or task.
//
// Parameters:
//   OwnerSForm - ClientApplicationForm - the form of processing corresponding to the process or task.
//   RoleOfSubject - String - the role of the added item corresponds to the enumeration of the role of the subjects.
//   CallbackDescription - CallbackDescription - optional, an alert that is called after successfully adding
//     an item with the transmission of a structure containing its description.
//
Procedure AddSubject(OwnerSForm, RoleOfSubject, CallbackDescription = Undefined) Export
	
	Parameters = New Structure;
	Parameters.Insert("OwnerSForm", OwnerSForm);
	Parameters.Insert("OwnerID", OwnerSForm.ID);
	Parameters.Insert("OwnerType", OwnerSForm.Type);
	Parameters.Insert("RoleOfSubject", RoleOfSubject);
	Parameters.Insert("CallbackDescription", CallbackDescription);
	
	DescriptionOfTypeSelectionNotification = New CallbackDescription(
		"AddSubjectAfterTypeSelection",
		IntegrationWith1CDocumentManagementClient,
		Parameters);
	
	ParametersItemTypeSelection = New Structure("Process_Type, Type");
	FillPropertyValues(ParametersItemTypeSelection, OwnerSForm);
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectSubjectType",
		ParametersItemTypeSelection,
		ThisObject,,,,
		DescriptionOfTypeSelectionNotification,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// Continues the process of adding an item after selecting its type.
//
// Parameters:
//   Result - Structure:
//     * Variant - String
//     * Filter - ValueList of AnyRef
//   Parameters - Structure - See AddSubject.
//
Procedure AddSubjectAfterTypeSelection(Result, Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Variant = "FileFromDisk" Then
		
		OwnerSForm = Parameters.OwnerSForm;
		// The owner of the file will be the process, even if it was added from the task form.
		If Find(Parameters.OwnerType, "Task") <> 0 Then
			Parameters.OwnerType = OwnerSForm.Process_Type;
			Parameters.OwnerID = OwnerSForm.Process_ID;
		Else
			// To attach a file, the process must be recorded.
			If Not ValueIsFilled(Parameters.OwnerID) Then
				RecordingResult = OwnerSForm.WriteObject();
				If RecordingResult Then
					Parameters.OwnerID = OwnerSForm.ID;
					Parameters.OwnerType = OwnerSForm.Type;
				Else // The recording failed, the Form informed the user about the source of the problem.
					Return;
				EndIf;
			EndIf;
		EndIf;
		
		ParametersForStartOfCreation =
			IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters();
		ParametersForStartOfCreation.OwnerID = Parameters.OwnerID;
		ParametersForStartOfCreation.OwnerType = Parameters.OwnerType;
		ParametersForStartOfCreation.FormUniqueID = OwnerSForm.UUID;
		ParametersForStartOfCreation.OwnerPresentation =
			?(Parameters.Property("Presentation"),
				Parameters.Presentation,
				OwnerSForm.Presentation);
		ParametersForStartOfCreation.CallbackDescription = New CallbackDescription(
			"AddSubjectAfterAddingFile",
			IntegrationWith1CDocumentManagementClient,
			Parameters);
		
		IntegrationWith1CDocumentManagementCoreClient.CreateFileFromDisk(ParametersForStartOfCreation);
		
	ElsIf Left(Result.Variant, 2) = "DM" Then // Selecting an object in the DO.
		CallbackDescription = New CallbackDescription(
			"AddSubjectAfterObjectSelectionDM",
			IntegrationWith1CDocumentManagementClient,
			Parameters);
		SelectValueByObjectType(CallbackDescription, Result.Variant);
		
	Else // Selecting an IP object.
		CallbackDescription = New CallbackDescription(
			"AddSubjectAfterObjectSelectionIS",
			IntegrationWith1CDocumentManagementClient,
			Parameters);
		FormParameters = New Structure;
		FormParameters.Insert("Filter", New Structure);
		For Each ListItem In Result.Filter Do
			FormParameters.Filter.Insert(ListItem.Presentation, ListItem.Value);
		EndDo;
		OpenForm(Result.Variant + ".ChoiceForm", FormParameters,,,,, CallbackDescription);
		
	EndIf;
	
EndProcedure

// Continues the process of adding an item after selecting the 1C object:Document management.
//
// Parameters:
//   ObjectBefore - Structure - Propitid, propitype, propitpresentation.
//   Parameters - Structure - See AddSubject.
//
Procedure AddSubjectAfterObjectSelectionDM(ObjectBefore, Parameters) Export
	
	If ObjectBefore = Undefined Or Parameters.CallbackDescription = Undefined Then
		Return;
	EndIf;
	
	ItemDescription = New Structure;
	ItemDescription.Insert("SubjectOf", ObjectBefore.AttributePresentation);
	ItemDescription.Insert("SubjectOfID", ObjectBefore.AttributeID);
	ItemDescription.Insert("SubjectOfType", ObjectBefore.AttributeType);
	ItemDescription.Insert("RoleOfSubject", Parameters.RoleOfSubject);
	ItemDescription.Insert("Presentation", ObjectBefore.AttributePresentation);
	
	RunCallback(
		Parameters.CallbackDescription,
		CommonClientServer.ValueInArray(ItemDescription));
	
EndProcedure

// Continues the process of adding an item after selecting an object of the integrated system.
//
// Parameters:
//   ObjectIS - AnyRef - the selected IP object.
//   Parameters - Structure - See AddSubject.
//
Procedure AddSubjectAfterObjectSelectionIS(ObjectIS, Parameters) Export
	
	If ObjectIS = Undefined Then
		Return;
	EndIf;
	
	Parameters.Insert("ObjectIS", ObjectIS);
	
	CallbackDescription = New CallbackDescription(
		"AddSubjectAfterFindingRelatedObjectDM",
		IntegrationWith1CDocumentManagementClient,
		Parameters);
	
	IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
		ObjectIS,
		CallbackDescription);
	
EndProcedure

// Continues the process of adding an item after searching for a related object BEFORE.
//
// Parameters:
//   Result - Structure - found or created object BEFORE (name, ID, type).
//   Parameters - Structure - See AddSubject.
//
Procedure AddSubjectAfterFindingRelatedObjectDM(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure")
		Or Parameters.CallbackDescription = Undefined Then
		Return;
	EndIf;
	
	ItemDescription = New Structure;
	ItemDescription.Insert("SubjectOf", Result.name);
	ItemDescription.Insert("SubjectOfID", Result.ID);
	ItemDescription.Insert("SubjectOfType", Result.type);
	ItemDescription.Insert("RoleOfSubject", Parameters.RoleOfSubject);
	ItemDescription.Insert("Presentation", String(Parameters.ObjectIS));
	ItemDescription.Insert("Ref", Parameters.ObjectIS);
	
	RunCallback(
		Parameters.CallbackDescription,
		CommonClientServer.ValueInArray(ItemDescription));
	
EndProcedure

// Continues the process of adding an item after adding a file from disk.
//
// Parameters:
//   FileDetails - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//   Parameters - Structure - See AddSubject.
//
Procedure AddSubjectAfterAddingFile(FileDetails, Parameters) Export
	
	If FileDetails = Undefined Or Parameters.CallbackDescription = Undefined Then
		Return;
	EndIf;
	
	Added_Items = New Array;
	
	For Each FileThatWasPut In FileDetails Do
		
		ItemDescription = New Structure;
		ItemDescription.Insert("SubjectOf", FileThatWasPut.Description);
		ItemDescription.Insert("SubjectOfID", FileThatWasPut.ID);
		ItemDescription.Insert("SubjectOfType", FileThatWasPut.Type);
		ItemDescription.Insert("RoleOfSubject", Parameters.RoleOfSubject);
		ItemDescription.Insert("Presentation", FileThatWasPut.Description);
		ItemDescription.Insert("Extension", FileThatWasPut.Extension);
		
		Added_Items.Add(ItemDescription);
		
	EndDo;
	
	RunCallback(Parameters.CallbackDescription, Added_Items);
	
EndProcedure

// Stops the process BEFORE.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the business process.
//
Procedure StopProcess(Form) Export
	
	IntegrationWith1CDocumentManagementServerCall.StopProcess(Form.ID, Form.Type);
	
	Notify_BusinessProcessRecord(Form, False);
	
	ShowUserNotification(
		NStr("vi = 'Đã dừng quy trình';
			|ru = 'Процесс остановлен';
			|en = 'Process is terminated'; fa = 'Process is terminated';
			|it = 'Processo fermato';
			|pl = 'Proces został zatrzymany';
			|tr = 'Süreç durduruldu'"),,
		Form.Title,
		PictureLib.Information32);
	
EndProcedure

// Interrupts an active or stopped process BEFORE.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the business process.
//
Procedure InterruptProcess(Form) Export
	
	NotificationParameters = New Structure("Form", Form);
	
	CallbackDescription = New CallbackDescription(
		"AbortProcessAfterQuestion",
		ThisObject,
		NotificationParameters);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement.Form.ProcessTermination",,,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Continues the stopped process UNTIL.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the business process.
//
Procedure ContinueProcess(Form) Export
	
	IntegrationWith1CDocumentManagementServerCall.ContinueProcess(Form.ID, Form.Type);
	
	Notify_BusinessProcessRecord(Form, False);
	
	ShowUserNotification(
		NStr("vi = 'Đã tiếp tục quy trình';
			|ru = 'Процесс продолжен';
			|en = 'Process is continued'; fa = 'Process is continued';
			|it = 'Processo continuato';
			|pl = 'Proces został kontynuowany';
			|tr = 'Süreç devam ediyor'"),,
		Form.Title,
		PictureLib.Information32);
	
EndProcedure

// Checks whether there are any items that have not been entered among the task items.
//
// Parameters:
//   Subjects - FormDataTreeItemCollection - all subjects of the task.
//   ColumnNameID - String - the name of the column containing the item ID.
//   ColumnNameSubject - String - the name of the column containing the Presentation of the subject.
//
// Returns:
//   Boolean
//
Function ThereAreUnfilledItems(Subjects, ColumnNameID, ColumnNameSubject) Export
	
	ThereAreUnfilledItems = False;
	For Each SubjectLine In Subjects Do
		If SubjectLine.RoleOfSubject = "Заполняемый"
				And SubjectLine.Mandatory = True
				And Not ValueIsFilled(SubjectLine[ColumnNameID]) Then //@NON-NLS-1
			ClearMessages();
			MessageText = StrTemplate(
				NStr("vi = 'Chưa nhập chủ đề được điền ""%1"". Có thể điền chủ đề ở bên 1C:Document Management.';
					|ru = 'Не введен заполняемый предмет ""%1"". Заполнить предмет можно на стороне 1С:Документооборот.';
					|en = 'The ""%1"" object is not entered. You can fill the object in 1C:Document Management.'; fa = 'The ""%1"" object is not entered. You can fill the object in 1C:Document Management.';
					|it = 'Не введен заполняемый предмет ""%1"". Заполнить предмет можно на стороне 1С:Документооборот.';
					|pl = 'The ""%1"" object is not entered. You can fill the object in 1C:Document Management.';
					|tr = 'Doldurulan ""%1"" konusu girilmedi. Konu, 1C:Document Management tarafında doldurulabilir.'"),
				SubjectLine[ColumnNameSubject]);
			PathToTabularSection = CommonClientServer.PathToTabularSection(
				"ApplicationTree",
				Subjects.IndexOf(SubjectLine),
				"Presentation");
			CommonClient.MessageToUser(MessageText,, PathToTabularSection);
			ThereAreUnfilledItems = True;
			Break;
		EndIf;
	EndDo;
	
	Return ThereAreUnfilledItems;
	
EndFunction

#EndRegion

#Region DocumentLinks

// Starts adding a link to the specified document BEFORE. Triggers an alert on success.
//
// Parameters:
//   ID - String - id of the source document.
//   Type - String - the type of the source document.
//   Presentation - String - presentation of the source document.
//   TypeOfDocumentToAdd - String - the type of document the link is being added to, or
//                            - Undefined - indicates whether the user needs to be given a choice.
//   CallbackDescription - CallbackDescription - notification called on success, with the transmission
//     of the structure (source document, linked document, type of connection).
//   Filter - Structure - description of the preset selection in terms of the XDTO package.
//
Procedure StartAddingLink(ID, Type, Presentation, TypeOfDocumentToAdd = Undefined,
		CallbackDescription = Undefined, Filter = Undefined) Export
	
	If TypeOfDocumentToAdd = Undefined Then
		
		FormParameters = New Structure;
		FormParameters.Insert("ID", ID);
		FormParameters.Insert("Type", Type);
		FormParameters.Insert("Presentation", Presentation);
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("ID", ID);
		NotificationParameters.Insert("Type", Type);
		NotificationParameters.Insert("Presentation", Presentation);
		NotificationParameters.Insert("CallbackDescription", CallbackDescription);
		NotificationParameters.Insert("Filter", Filter);
		
		ChoiceNotificationDetails = New CallbackDescription(
			"StartAddingLinkAfterLinkCreationForm",
			ThisObject,
			NotificationParameters);
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.CreateRelation",
			FormParameters,,
			ID,,,
			ChoiceNotificationDetails,
			FormWindowOpeningMode.LockWholeInterface);
		
	Else // The type is specified explicitly.
		
		StartAddingLinkAfterSelectingType(
			ID,
			Type,
			Presentation,
			TypeOfDocumentToAdd,
			CallbackDescription,
			Filter);
		
	EndIf;
	
EndProcedure

// Continues adding the link after showing the "Create Link" form.
//
// Parameters:
//   Result - Structure - description of the selection with properties:
//     Props Type - String - type of the selected object.
//     Detailid - String - ID of the selected object.
//   NotificationParameters - Structure - additional parameters required to continue:
//     * ID - String - id of the source document.
//     * Type - String - the type of the source document.
//     * Presentation - String - presentation of the source document.
//     * CallbackDescription - CallbackDescription - description of the alert that is called after adding.
//     * Filter - Structure - description of the selection imposed when opening the search card.
//
Procedure StartAddingLinkAfterLinkCreationForm(Result, NotificationParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	If ValueIsFilled(Result.AttributeID) Then // A specific document is selected.
		
		Parameters = New Structure;
		
		SourceDocument_ = New Structure;
		SourceDocument_.Insert("ID", NotificationParameters.ID);
		SourceDocument_.Insert("Type", NotificationParameters.Type);
		SourceDocument_.Insert("Presentation", NotificationParameters.Presentation);
		
		Parameters.Insert("SourceDocument_", SourceDocument_);
		Parameters.Insert("CallbackDescription", NotificationParameters.CallbackDescription);
		Parameters.Insert("Filter", NotificationParameters.Filter);
		
		StartAddingLinkAfterSelectingDocument(Result, Parameters);
		
	Else // Only the type is selected.
		
		StartAddingLinkAfterSelectingType(
			NotificationParameters.ID,
			NotificationParameters.Type,
			NotificationParameters.Presentation,
			Result.AttributeType,
			NotificationParameters.CallbackDescription,
			NotificationParameters.Filter);
		
	EndIf;
	
EndProcedure

// Starts adding a link to a document UP to the specified type. Triggers an alert on success.
//
// Parameters:
//   ID - String - id of the source document.
//   Type - String - the type of the source document.
//   Presentation - String - presentation of the source document.
//   TypeOfDocumentToAdd - String - the type of document that the link is being added to.
//   CallbackDescription - CallbackDescription - notification called on success, with the transmission
//     of the structure (source document, linked document, type of connection).
//   Filter - Structure - description of the preset selection in terms of the XDTO package.
//
Procedure StartAddingLinkAfterSelectingType(ID, Type, Presentation, TypeOfDocumentToAdd,
		CallbackDescription = Undefined, Filter = Undefined) Export
	
	SourceDocument_ = New Structure;
	SourceDocument_.Insert("ID", ID);
	SourceDocument_.Insert("Type", Type);
	SourceDocument_.Insert("Presentation", Presentation);
	
	Parameters = New Structure;
	Parameters.Insert("SourceDocument_", SourceDocument_);
	Parameters.Insert("CallbackDescription", CallbackDescription);
	Parameters.Insert("Filter", Filter);
	
	ContinueNotification = New CallbackDescription(
		"StartAddingLinkAfterSelectingDocument",
		IntegrationWith1CDocumentManagementClient,
		Parameters);
	
	SelectValueByObjectType(ContinueNotification, TypeOfDocumentToAdd, Filter);
	
EndProcedure

// Continues adding the link after selecting the linked document BEFORE.
//
// Parameters:
//   Result - Structure - selection result:
//     Detailid - String - ID of the selected document.
//     Props Type - String - type of the selected document.
//     Props Representation - String - Presentation of the selected document.
//   Parameters - Structure - See StartAddingLink.
//
Procedure StartAddingLinkAfterSelectingDocument(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	LinkedDocument = New Structure;
	LinkedDocument.Insert("ID", Result.AttributeID);
	LinkedDocument.Insert("Type", Result.AttributeType);
	LinkedDocument.Insert("Presentation", Result.AttributePresentation);
	
	Parameters.Insert("LinkedDocument", LinkedDocument);
	
	ContinueNotification = New CallbackDescription(
		"StartAddingLinkAfterSelectingLinkType",
		IntegrationWith1CDocumentManagementClient,
		Parameters);
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("SourceDocument_", Parameters.SourceDocument_);
	ChoiceFormParameters.Insert("LinkedDocument", Parameters.LinkedDocument);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingTypeOfLink",
		ChoiceFormParameters,,,,,
		ContinueNotification,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// Continues adding the link after selecting the link type.
//
// Parameters:
//   Result - Structure - selection result:
//     * AttributeID - String - id of the selected type of connection.
//     * AttributeType - String - the type of the selected type of connection.
//     * AttributePresentation - String - representation of the selected type of connection.
//   Parameters - Structure:
//     * SourceDocument_ - Structure - description of the source document.
//     * LinkedDocument - Structure - description of the linked document.
//     * CallbackDescription - CallbackDescription - an alert that is triggered on success.
//
Procedure StartAddingLinkAfterSelectingLinkType(Result, Parameters) Export
	
	If Result = "RepeatDocumentSelection" Then // The "Back" button is pressed.
		ContinueNotification = New CallbackDescription(
			"StartAddingLinkAfterSelectingDocument",
			IntegrationWith1CDocumentManagementClient,
			Parameters);
		SelectValueByObjectType(ContinueNotification, Parameters.LinkedDocument.Type, Parameters.Filter);
		Return;
		
	ElsIf TypeOf(Result) <> Type("Structure") Then
		Return;
		
	EndIf;
	
	IntegrationWith1CDocumentManagementServerCall.AddDocumentLink(
		Parameters.SourceDocument_,
		Parameters.LinkedDocument,
		Result);
	
	If Parameters.CallbackDescription <> Undefined Then
		Parameters.Insert("LinkType", Result);
		RunCallback(Parameters.CallbackDescription, Parameters);
	EndIf;
	
EndProcedure

// Starts deleting the specified type of relationship between two documents.
//
// Parameters:
//   SourceDocument_ - Structure - The original document.
//   LinkedDocument - Structure - linked document.
//   LinkType - Structure - type of connection. Properties of structures:
//     ID String - ID of the object BEFORE.
//     Type - String - object type BEFORE.
//     Presentation - String - Presentation of the object BEFORE.
//   CallbackDescription - CallbackDescription - called upon success with the transfer
//     of the structure (source document, linked document, type of connection).
//
Async Procedure StartDeletingLink(Val SourceDocument_, Val LinkedDocument, Val LinkType,
		Val CallbackDescription = Undefined) Export
	
	Parameters = New Structure;
	Parameters.Insert("SourceDocument_", SourceDocument_);
	Parameters.Insert("LinkedDocument", LinkedDocument);
	Parameters.Insert("LinkType", LinkType);
	Parameters.Insert("CallbackDescription", CallbackDescription);
	
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
		NStr("vi = 'Xóa liên kết?';
			|ru = 'Удалить связь?';
			|en = 'Remove the link?'; fa = 'Remove the link?';
			|it = 'Удалить связь?';
			|pl = 'Usunąć powiązanie?';
			|tr = 'Bağlantı silinsin mi?'"));
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.SourceDocument_.ID) Then
		IntegrationWith1CDocumentManagementServerCall.DeleteDocumentAssociation(
			Parameters.SourceDocument_,
			Parameters.LinkedDocument,
			Parameters.LinkType);
	EndIf;
	
	If Parameters.CallbackDescription <> Undefined Then
		RunCallback(Parameters.CallbackDescription, Parameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region AsynchronousOperationWithTheInterfaceIS

// Launches an asynchronous method, which, at the end of the work, triggers an alert,
// in the parameters of which information about the possibility of negotiation is transmitted.
//
// Parameters:
//   Form - ClientApplicationForm - the form from which the call was made.
//   SubjectOfApproval - AnyRef - subject of approval.
//   CallbackOnCompletion - CallbackDescription - notification with the result of execution.
//
Procedure CoordinationIsPossible(Form, SubjectOfApproval, CallbackOnCompletion) Export
	
	StartGettingMatchingOpportunity(Form, SubjectOfApproval, CallbackOnCompletion);
	
EndProcedure

// Launches an asynchronous method that sends the item for approval, and at the end of the work
// calls an alert, in the parameters of which information about the results of the approval is transmitted.
//
// Parameters:
//   Form - ClientApplicationForm:
//     * Object - DefinedType.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable
//              - DefinedType.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable
//   SubjectOfApproval - AnyRef - subject of approval.
//   CallbackOnCompletion - CallbackDescription - notification with the result of execution.
//
Procedure AgreeAsynchronously(Form, SubjectOfApproval, CallbackOnCompletion) Export
	
	If SubjectOfApproval.IsEmpty() Then
		AdditionalParameters = New Structure("Form, SubjectOfApproval, CallbackOnCompletion",
			Form, SubjectOfApproval, CallbackOnCompletion);
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
							|Chỉ có thể thống nhất văn bản sau khi ghi lại dữ liệu.
							|Dữ liệu sẽ được ghi lại.';
							|ru = 'Данные еще не записаны.
							|Согласование документа возможно только после записи данных.
							|Данные будут записаны.';
							|en = 'Data not saved yet.
							|Document approval can be performed only after data is saved.
							|Data will be saved.'; fa = 'Data not saved yet.
							|Document approval can be performed only after data is saved.
							|Data will be saved.';
							|it = 'Dati non ancora registrati.
							|L''omologazione del documento è possibile solo dopo la registrazione dei dati.
							|I dati saranno registrati.';
							|pl = 'Dane jeszcze nie są zapisane.
							|Uzgodnienie dokumentu jest możliwe tylko po zapisaniu danych.
							|Dane zostaną zapisane.';
							|tr = 'Veriler henüz kaydedilmedi.
							|Belgenin onaylanması ancak veriler kaydedildikten sonra mümkündür.
							|Veriler yazılacaktır.'");
		
		CallbackDescription = New CallbackDescription("AgreeAsynchronouslyCompletion",
			ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel);
	Else
		StartNegotiationAsynchronously(Form, SubjectOfApproval, CallbackOnCompletion);
	EndIf;
	
EndProcedure

// Launches an asynchronous method, which, at the end of the work, triggers an alert,
// in the parameters of which information is transmitted about the possibility of interrupting the negotiation.
//
// Parameters:
//   Form - ClientApplicationForm - the form from which the call was made.
//   SubjectOfApproval - AnyRef - subject of approval.
//   CallbackOnCompletion - CallbackDescription - notification with the result of execution.
//
Procedure AgreementInterruptionIsPossible(Form, SubjectOfApproval, CallbackOnCompletion) Export
	
	StartGettingAbilityToInterruptNegotiation(Form, SubjectOfApproval, CallbackOnCompletion);
	
EndProcedure

// Launches an asynchronous method that interrupts the coordination of the subject, and at the end of the work
// calls an alert, in the parameters of which information about the results of the interruption of the coordination is transmitted.
//
// Parameters:
//   Form - ClientApplicationForm:
//     * Object - DefinedType.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable
//              - DefinedType.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable
//   SubjectOfApproval - AnyRef - subject of approval.
//   CallbackOnCompletion - CallbackDescription - notification with the result of execution.
//
Procedure AbortNegotiationAsynchronously(Form, SubjectOfApproval, CallbackOnCompletion) Export
	
	If SubjectOfApproval.IsEmpty() Then
		AdditionalParameters = New Structure("Form, SubjectOfApproval, CallbackOnCompletion",
			Form, SubjectOfApproval, CallbackOnCompletion);
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
							|Chỉ có thể ngắt thống nhất văn bản sau khi ghi lại dữ liệu.
							|Dữ liệu sẽ được ghi lại.';
							|ru = 'Данные еще не записаны.
							|Прерывание согласования документа возможно только после записи данных.
							|Данные будут записаны.';
							|en = 'Data has not been saved yet.
							|Aborting document approval can only be performed after data is saved.
							|Data will be saved.'; fa = 'Data has not been saved yet.
							|Aborting document approval can only be performed after data is saved.
							|Data will be saved.';
							|it = 'Dati non ancora registrati.
							|L''interruzione dell''omologazione del documento è possibile solo dopo la registrazione dei dati.
							|I dati saranno registrati.';
							|pl = 'Dane jeszcze nie są zapisane.
							|Przerywanie uzgodnienia dokumentu jest możliwe tylko po zapisaniu danych.
							|Dane zostaną zapisane.';
							|tr = 'Veriler henüz kaydedilmedi.
							|Belge onayının iptali ancak veriler yazıldıktan sonra mümkündür.
							|Veriler yazılacaktır.'");
		
		CallbackDescription = New CallbackDescription("AbortNegotiationAsynchronouslyCompletion",
			ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel);
	Else
		StartAbortNegotiationAsynchronously(Form, SubjectOfApproval, CallbackOnCompletion);
	EndIf;
	
EndProcedure

// Launches an asynchronous method, which, at the end of the work, triggers an alert,
// in the parameters of which information about the status of the agreement is transmitted.
//
// Parameters:
//   Form - ClientApplicationForm - the form from which the call was made.
//   SubjectOfApproval - AnyRef - subject of approval.
//   CallbackOnCompletion - CallbackDescription - notification with the result of execution.
//
Procedure StateOfApproval(Form, SubjectOfApproval, CallbackOnCompletion) Export
	
	BeginGettingApprovalStates(Form, SubjectOfApproval, CallbackOnCompletion);
	
EndProcedure

#EndRegion

#Region CommandProcessing

// The handler of the general integration command1sdocumentsreferences
//
// Parameters:
//   ReferencesArrray - Arbitrary - the parameter is passed the value from the source in which the command is implemented.
//     It can contain either a single value or an array of values.
//   ExecutionParameters - CommandExecuteParameters - in the command handler, you can change the value
//     of the parameter properties.
//
Procedure ProcessingCommandsCreateBusinessProcess(ReferencesArrray, ExecutionParameters) Export
	
	If TypeOf(ReferencesArrray) = Type("Array") And ReferencesArrray.Count() > 0 Then
		CommandParameter = ReferencesArrray[0];
	Else
		CommandParameter = ReferencesArrray;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"CreateBusinessProcessCheckConnectionEnd",
		ThisObject,
		CommandParameter);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,
		True);
	
EndProcedure

// Handler of the general integration command1sdocumentsreferencesfurther reading
//
// Parameters:
//   ReferencesArrray - Arbitrary - the parameter is passed the value from the source in which the command is implemented.
//     It can contain either a single value or an array of values.
//   ExecutionParameters - CommandExecuteParameters - in the command handler, you can change the value
//     of the parameter properties.
//
Procedure ProcessingOutgoingMessageCommand(ReferencesArrray, ExecutionParameters) Export
	
	If TypeOf(ReferencesArrray) = Type("Array") And ReferencesArrray.Count() > 0 Then
		CommandParameter = ReferencesArrray[0];
	Else
		CommandParameter = ReferencesArrray;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"OutgoingEmailCheckConnectionEnd",
		ThisObject,
		CommandParameter);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,
		True);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure StartGettingMatchingOpportunity(Form, SubjectOfApproval, CallbackOnCompletion)
	
	TimeConsumingOperation = IntegrationWith1CDocumentManagementServerCall.LongOperationIsNotPossible(
		Form.UUID,
		SubjectOfApproval);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.OutputMessages = False;
	
	NotificationParameters = New Structure(
		"Form,
		|CallbackOnCompletion");
	NotificationParameters.Form = Form;
	NotificationParameters.CallbackOnCompletion = CallbackOnCompletion;
	
	CallbackOnCompletion = New CallbackDescription("FinishGettingMatchingOption",
		ThisObject, NotificationParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

Procedure FinishGettingMatchingOption(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khong thể xác định khả năng thống nhất văn bản do:
						|%1';
						|ru = 'Не удалось определить возможность согласования документа по причине:
						|%1';
						|en = 'Cannot determine the document approval capability. Reason:
						|%1'; fa = 'Cannot determine the document approval capability. Reason:
						|%1';
						|it = 'Non è stato possibile definire la possibilità di omologazione del documento a causa di:
						|%1';
						|pl = 'Nie udało się określić możliwości uzgodnienia dokumentu z powodu:
						|%1';
						|tr = 'Aşağıdakiler nedeniyle belge onaylama olasılığını belirlemek mümkün olmadı:
						|%1'"), Result.BriefErrorDescription);
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	RunCallback(
		AdditionalParameters.CallbackOnCompletion,
		GetFromTempStorage(Result.ResultAddress));
	
EndProcedure

// The handler for the "Agree to Synchronize Completion" notification.
//
// Parameters:
//   Response - Arbitrary
//   AdditionalParameters - Structure:
//     * Form - ClientApplicationFormExtensionForObjects:
//         ** Object - DefinedType.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable
//                   - DefinedType.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable
//     * CallbackOnCompletion - CallbackDescription
//
Procedure AgreeAsynchronouslyCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.OK Then
		AdditionalParameters.Form.Write();
		ObjectReference = IntegrationWith1CDocumentManagementCoreClient.ReferenceToIntegratedObjectFromForm(
			AdditionalParameters.Form,
			TypeOf(AdditionalParameters.SubjectOfApproval));
		If Not ObjectReference.IsEmpty() And Not AdditionalParameters.Form.Modified Then
			StartNegotiationAsynchronously(
				AdditionalParameters.Form,
				ObjectReference,
				AdditionalParameters.CallbackOnCompletion);
			Return;
		EndIf;
	EndIf;
	
	RunCallback(
		AdditionalParameters.CallbackOnCompletion,
		New Structure("ExecutedSuccessfully, ErrorDescription",
			False,
			NStr("vi = 'Chưa ghi lại đối tượng thống nhất.';
				|ru = 'Предмет согласования не записан.';
				|en = 'The approval subject has not been saved.'; fa = 'The approval subject has not been saved.';
				|it = 'Elemento di omologazione non registrato.';
				|pl = 'Przedmiot uzgodnienia nie jest zapisany.';
				|tr = 'Onaylama konusu kaydedilmedi.'")));
	
EndProcedure

Procedure StartNegotiationAsynchronously(Form, SubjectOfApproval, CallbackOnCompletion)
	
	TimeConsumingOperation = IntegrationWith1CDocumentManagementServerCall.LongOperationStartMatching(
		Form.UUID, SubjectOfApproval);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.OutputMessages = False;
	
	NotificationParameters = New Structure(
		"Form,
		|CallbackOnCompletion");
	NotificationParameters.Form = Form;
	NotificationParameters.CallbackOnCompletion = CallbackOnCompletion;
	
	CallbackOnCompletion = New CallbackDescription("EndNegotiationAsynchronously",
		ThisObject, NotificationParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

Procedure EndNegotiationAsynchronously(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể gửi văn bản để thống nhất do:
						|%1';
						|ru = 'Не удалось отправить документ на согласование по причине:
						|%1';
						|en = 'Cannot send the document for approval. Reason:
						|%1'; fa = 'Cannot send the document for approval. Reason:
						|%1';
						|it = 'Non è stato possibile inviare il documento per l''omologazione a causa di:
						|%1';
						|pl = 'Nie udało się wysłać dokumentu do uzgodnienia z powodu:
						|%1';
						|tr = 'Doküman bu nedenlerle onaya gönderilemedi:
						|%1'"), Result.BriefErrorDescription);
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	RunCallback(
		AdditionalParameters.CallbackOnCompletion,
		GetFromTempStorage(Result.ResultAddress));
	
EndProcedure

Procedure StartGettingAbilityToInterruptNegotiation(Form, SubjectOfApproval, CallbackOnCompletion)
	
	TimeConsumingOperation = IntegrationWith1CDocumentManagementServerCall.LongRunningOperationInterruptNegotiationIsPossible(
		Form.UUID,
		SubjectOfApproval);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.OutputMessages = False;
	
	NotificationParameters = New Structure(
		"Form,
		|CallbackOnCompletion");
	NotificationParameters.Form = Form;
	NotificationParameters.CallbackOnCompletion = CallbackOnCompletion;
	
	CallbackOnCompletion = New CallbackDescription("CompleteObtainingAbortNegotiationCapability",
		ThisObject, NotificationParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

Procedure CompleteObtainingAbortNegotiationCapability(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xác định khả năng ngắt thống nhất văn bản do nguyên nhân:
						|%1';
						|ru = 'Не удалось определить возможность прерывания согласования документа по причине:
						|%1';
						|en = 'Cannot determine the document approval aborting capability. Reason:
						|%1'; fa = 'Cannot determine the document approval aborting capability. Reason:
						|%1';
						|it = 'Non è stato possibile definire la possibilità di interrompere l''omologazione del documento a causa di:
						|%1';
						|pl = 'Nie udało się określić możliwości przerywania uzgodnienia dokumentu z powodu:
						|%1';
						|tr = 'Aşağıdakiler nedeniyle belge onaylamasının kesintiye uğrama olasılığını belirlemek mümkün olamadı:
						|%1'"), Result.BriefErrorDescription);
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	RunCallback(
		AdditionalParameters.CallbackOnCompletion,
		GetFromTempStorage(Result.ResultAddress));
	
EndProcedure

// The handler for the "Interrupt concurrentasync Completion" alert.
//
// Parameters:
//   Response - Arbitrary
//   AdditionalParameters - Structure:
//     * Form - ClientApplicationFormExtensionForObjects:
//         ** Object - DefinedType.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable
//                   - DefinedType.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable
//     * CallbackOnCompletion - CallbackDescription
//
Procedure AbortNegotiationAsynchronouslyCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.OK Then
		AdditionalParameters.Form.Write();
		ObjectReference = IntegrationWith1CDocumentManagementCoreClient.ReferenceToIntegratedObjectFromForm(
			AdditionalParameters.Form,
			TypeOf(AdditionalParameters.SubjectOfApproval));
		If Not ObjectReference.IsEmpty() And Not AdditionalParameters.Form.Modified Then
			StartAbortNegotiationAsynchronously(
				AdditionalParameters.Form,
				AdditionalParameters.SubjectOfApproval,
				AdditionalParameters.CallbackOnCompletion);
			Return;
		EndIf;
	EndIf;
	
	RunCallback(
		AdditionalParameters.CallbackOnCompletion,
		New Structure("ExecutedSuccessfully, ErrorDescription",
			False,
			NStr("vi = 'Chưa ghi lại đối tượng thống nhất.';
				|ru = 'Предмет согласования не записан.';
				|en = 'The approval subject has not been saved.'; fa = 'The approval subject has not been saved.';
				|it = 'Elemento di omologazione non registrato.';
				|pl = 'Przedmiot uzgodnienia nie jest zapisany.';
				|tr = 'Onaylama konusu kaydedilmedi.'")));
	
EndProcedure

Procedure StartAbortNegotiationAsynchronously(Form, SubjectOfApproval, CallbackOnCompletion)
	
	TimeConsumingOperation = IntegrationWith1CDocumentManagementServerCall.LongRunningOperationAbortNegotiation(
		Form.UUID,
		SubjectOfApproval);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.OutputMessages = False;
	
	NotificationParameters = New Structure(
		"Form,
		|CallbackOnCompletion");
	NotificationParameters.Form = Form;
	NotificationParameters.CallbackOnCompletion = CallbackOnCompletion;
	
	CallbackOnCompletion = New CallbackDescription("EndNegotiationInterruptAsynchronously",
		ThisObject, NotificationParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

Procedure EndNegotiationInterruptAsynchronously(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể ngắt thống nhất văn bản do nguyên nhân:
						|%1';
						|ru = 'Не удалось прервать согласование документа по причине:
						|%1';
						|en = 'Cannot abort document approval. Reason:
						|%1'; fa = 'Cannot abort document approval. Reason:
						|%1';
						|it = 'Non è stato possibile interrompere l''omologazione del documento a causa di:
						|%1';
						|pl = 'Nie udało się przerwać uzgodnienia dokumentu z powodu:
						|%1';
						|tr = 'Bu nedenlerle belge onayı iptal edilemedi:
						|%1'"), Result.BriefErrorDescription);
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	RunCallback(
		AdditionalParameters.CallbackOnCompletion,
		GetFromTempStorage(Result.ResultAddress));
	
EndProcedure

Procedure BeginGettingApprovalStates(Form, SubjectOfApproval, CallbackOnCompletion)
	
	TimeConsumingOperation = IntegrationWith1CDocumentManagementServerCall.LongRunningOperationStateOfApproval(
		Form.UUID,
		SubjectOfApproval);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.OutputMessages = False;
	
	NotificationParameters = New Structure(
		"Form,
		|CallbackOnCompletion");
	NotificationParameters.Form = Form;
	NotificationParameters.CallbackOnCompletion = CallbackOnCompletion;
	
	CallbackOnCompletion = New CallbackDescription("CompleteGettingApprovalState",
		ThisObject, NotificationParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

Procedure CompleteGettingApprovalState(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận trạng thái thống nhất văn bản do:
						|%1';
						|ru = 'Не удалось получить состояние согласования документа по причине:
						|%1';
						|en = 'Cannot get document approval state. Reason:
						|%1'; fa = 'Cannot get document approval state. Reason:
						|%1';
						|it = 'Non è stato possibile ricevere lo stato di omologazione del documento a causa di:
						|%1';
						|pl = 'Nie udało otrzymać się statusu uzgodnienia dokumentu z powodu:
						|%1';
						|tr = 'Bu nedenlerle belge onay durumu alınamadı:
						|%1'"), Result.BriefErrorDescription);
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	RunCallback(
		AdditionalParameters.CallbackOnCompletion,
		GetFromTempStorage(Result.ResultAddress));
	
EndProcedure

Procedure SelectUserFromUnitTreeCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		NotificationParameters.OwnerForm[NotificationParameters.Attribute] = Result.AttributePresentation;
		NotificationParameters.OwnerForm[NotificationParameters.Attribute + "ID"] = Result.AttributeID;
		NotificationParameters.OwnerForm[NotificationParameters.Attribute + "Type"] = Result.AttributeType;
		NotificationParameters.OwnerForm.Modified = True;
	EndIf;
	
EndProcedure

Procedure SelectValueOfCompositeTypeAttributeInSelectTypeTable(TypeName, NotificationParameters) Export
	
	Form = NotificationParameters.Form;
	CurrentData = NotificationParameters.CurrentData;
	Attribute = NotificationParameters.Attribute;
	
	If TypeName = Undefined Then
		Return;
	EndIf;
		
	SelectValueOfCompositeAttributeInProcessingTable(TypeName, Form, CurrentData, Attribute)
	
EndProcedure

Procedure SelectValueOfCompositeAttributeInProcessingTable(TypeName, Form, CurrentData, Attribute)
	
	If TypeName = "integer"
		Or TypeName = "boolean"
		Or TypeName = "string"
		Or TypeName = "date" Then
		
		If TypeName = "integer" Then
			ValueType = Type("Number");
		ElsIf TypeName = "boolean" Then
			ValueType = Type("Boolean");
		ElsIf TypeName = "string" Then
			ValueType = Type("String");
		ElsIf TypeName = "date" Then
			ValueType = Type("Date");
		EndIf;
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("Form", Form);
		NotificationParameters.Insert("CurrentData", CurrentData);
		NotificationParameters.Insert("Attribute", Attribute);
		
		Notification = New CallbackDescription("SelectValueOfCompositeTypePropsInEnterValueTable", IntegrationWith1CDocumentManagementClient, NotificationParameters);
		
		ShowInputValue(Notification, CurrentData[Attribute], NStr("vi = 'Hãy nhập giá trị';
																	|ru = 'Введите значение';
																	|en = 'Enter a value'; fa = 'مقداری وارد کنید';
																	|it = 'Immettere un valore';
																	|pl = 'Wprowadź wartość';
																	|tr = 'Değer gir'"), ValueType);
		
	Else
		
		FormParameters = New Structure;
		FormParameters.Insert("TypeOfSelectionObject", TypeName);
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("Form", Form);
		NotificationParameters.Insert("CurrentData", CurrentData);
		NotificationParameters.Insert("Attribute", Attribute);
		
		Notification = New CallbackDescription(
			"SelectValueOfCompositeTypePropsInTableCompletion", IntegrationWith1CDocumentManagementClient, NotificationParameters);
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList",
			FormParameters, Form,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
			
	EndIf;

EndProcedure

Procedure SelectValueOfCompositeTypePropsInEnterValueTable(Result, NotificationParameters) Export
	
	If Result <> Undefined Then
		NotificationParameters.CurrentData[NotificationParameters.Attribute] = Result;
		NotificationParameters.Form.Modified = True;
	EndIf;
	
EndProcedure

Procedure SelectValueOfCompositeTypePropsInTableCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		NotificationParameters.CurrentData[NotificationParameters.Attribute + "ID"] = Result.AttributeID;
		NotificationParameters.CurrentData[NotificationParameters.Attribute + "Type"] = Result.AttributeType;
		NotificationParameters.CurrentData[NotificationParameters.Attribute] = Result.AttributePresentation;
		NotificationParameters.Form.Modified = True;
	EndIf;
	
EndProcedure

// The handler for the "Toggle Chronometer Completion" alert.
//
// Parameters:
//   RoleSelectionResult - Arbitrary
//   NotificationParameters - Structure:
//     * Form - ClientApplicationForm
//     * Item - FormTable
//
Procedure ApplyBusinessProcessParticipantSelectionInListCompletion(RoleSelectionResult, NotificationParameters) Export
	
	CurrentData = NotificationParameters.Item.CurrentData;
	
	If RoleSelectionResult = Undefined Then
		Return;
	EndIf;
		
	CurrentData.Performer = RoleSelectionResult.Performer;
	CurrentData.PerformerID = RoleSelectionResult.PerformerID;
	CurrentData.PerformerType = RoleSelectionResult.PerformerType;
	
	CurrentData.MainAddressingObject = RoleSelectionResult.MainAddressingObject;
	CurrentData.MainAddressingObjectID = RoleSelectionResult.MainAddressingObjectID;
	CurrentData.MainAddressingObjectType = RoleSelectionResult.MainAddressingObjectType;
	
	CurrentData.AdditionalAddressingObject = RoleSelectionResult.AdditionalAddressingObject;
	CurrentData.AdditionalAddressingObjectID = RoleSelectionResult.AdditionalAddressingObjectID;
	CurrentData.AdditionalAddressingObjectType = RoleSelectionResult.AdditionalAddressingObjectType;
	
	NotificationParameters.Form.Modified = True;
	
EndProcedure

// The handler for the "Toggle Chronometer Completion" alert.
//
// Parameters:
//   Result - DialogReturnCode
//   NotificationParameters - Structure:
//     * ObjectIS - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable
//     * ObjectBefore - Structure:
//         ** documentType - Structure:
//              *** ID - String
//              *** name - String
//              *** type - String
//         ** ID - String
//         ** name - String
//         ** type - String
//         ** ExternalObject - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable
//     * TimingParameters - Structure:
//         ** TimekeepingEnabled - Boolean
//         ** StartDateOfTimekeeping - Date
//         ** EndDateOfTimekeeping - Date
//     * ActiveEntries - Array of Structure:
//         ** TimekeepingEnabled - Boolean
//         ** StartDateOfTimekeeping - Date
//         ** EndDateOfTimekeeping - Date
//         ** Source - String
//         ** SourceID - String
//         ** SourceType - String
//     * Form - ClientApplicationForm
//
Procedure SwitchTimingCompletion(Result, NotificationParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		Records = IntegrationWith1CDocumentManagementServerCall.SwitchTimeTrackingBy1CDocumentManagementObjects(
			NotificationParameters.ActiveEntries);
		
		For Each Record In Records Do
			Parameters = New Structure;
			Parameters.Insert("name", Record.Source);
			Parameters.Insert("ID", Record.SourceID);
			Parameters.Insert("type", Record.SourceType);
			Notify("Recording_1CDocumentManagementTimeSpent", Parameters, Record.SourceID);
		EndDo;
		
		TimingParameters = IntegrationWith1CDocumentManagementServerCall.SwitchTimekeepingForExternalObject(
			NotificationParameters.ObjectIS,
			NotificationParameters.TimingParameters);
			
		NotificationParameters.Form.Items.IntegrationWith1CDocumentManagement_SwitchTimekeeping.Check =
			TimingParameters.TimekeepingEnabled;
		
		If TimingParameters.TimekeepingEnabled Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
				|ru = 'Включен хронометраж по ""%1""';
				|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
				|it = 'Crono-analisi attivata per ""%1""';
				|pl = 'Chronometraż jest włączony według ""%1""';
				|tr = '""%1"" ile kronometre etkin'"), String(NotificationParameters.ObjectIS));
			Status(Text);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CompatibilitySupport_CreateBusinessProcessCompletion(BusinessProcessType, Parameters) Export
	
	If BusinessProcessType = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		BusinessProcessType,
		Undefined,,
		Parameters);
	
EndProcedure

Procedure ApplyBusinessProcessParticipantSelectionInFieldCompletion(RoleSelectionResult, NotificationParameters) Export
	
	Form = NotificationParameters.Form;
	FieldName = NotificationParameters.FieldName;
	FieldNameOfAddressingObject = NotificationParameters.FieldNameOfAddressingObject;
	
	If RoleSelectionResult = Undefined Then
		Return;
	EndIf;
		
	Form[FieldName] = RoleSelectionResult.Performer;
	Form[FieldName + "ID"] = RoleSelectionResult.PerformerID;
	Form[FieldName + "Type"] = RoleSelectionResult.PerformerType;
	
	Form["Main" + FieldNameOfAddressingObject] = RoleSelectionResult.MainAddressingObject;
	Form["Main" + FieldNameOfAddressingObject + "ID"] = RoleSelectionResult.MainAddressingObjectID;
	Form["Main" + FieldNameOfAddressingObject + "Type"] = RoleSelectionResult.MainAddressingObjectType;
	
	Form["Additional" + FieldNameOfAddressingObject] = RoleSelectionResult.AdditionalAddressingObject;
	Form["Additional" + FieldNameOfAddressingObject + "ID"] = RoleSelectionResult.AdditionalAddressingObjectID;
	Form["Additional" + FieldNameOfAddressingObject + "Type"] = RoleSelectionResult.AdditionalAddressingObjectType;
	
	Form.Modified = True;
	
EndProcedure

// A handler for a dynamically connected labor indication command.
//
// Parameters:
//   Source - FormDataCollection
//            - FormDataStructure:
//     * Ref - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable
//   Form - ClientApplicationForm - the shape of this object.
//
Procedure SpecifyLaborCosts(Source, Form)
	
	If Source = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Source) = Type("FormDataStructure") Then
		Ref = Source.Ref;
	Else
		If Source.CurrentData = Undefined Then
			Return;
		EndIf;
		Ref = Undefined;
		If Not Source.CurrentData.Property("Ref", Ref) Then
			Ref = Source.CurrentRow;
		EndIf;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"SpecifyTimeSpentAfterSearchingForARelatedObjectDM",
		IntegrationWith1CDocumentManagementClient,
		Form);
	IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
		Ref,
		CallbackDescription);
	
EndProcedure

// The handler of the connected timekeeping switching command.
//
// Parameters:
//   Source - FormDataCollection
//            - FormDataStructure:
//     * Ref - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable
//   Form - ClientApplicationForm - the shape of this object.
//
Procedure SwitchTiming(Source, Form)
	
	If Source = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Source) = Type("FormDataStructure") Then
		Ref = Source.Ref;
	Else
		If Source.CurrentData = Undefined Then
			Return;
		EndIf;
		Ref = Undefined;
		If Not Source.CurrentData.Property("Ref", Ref) Then
			Ref = Source.CurrentRow;
		EndIf;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("ObjectIS", Ref);
	Parameters.Insert("Form", Form);
	
	CallbackDescription = New CallbackDescription(
		"SwitchTimekeepingAfterSearchingForRelatedObjectTo",
		IntegrationWith1CDocumentManagementClient,
		Parameters);
	IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
		Ref,
		CallbackDescription);
	
EndProcedure

// Continues to enter labor costs after finding or creating a linked object BEFORE.
//
// Parameters:
//   Result - Undefined
//             - Structure:
//     * ID - String
//     * type - String
//     * name - String
//   Form - ClientApplicationForm - the shape of the timekeeping object.
//
Procedure SpecifyTimeSpentAfterSearchingForARelatedObjectDM(Result, Form) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Source", Result.name);
	FormParameters.Insert("SourceID", Result.ID);
	FormParameters.Insert("SourceType", Result.type);
	
	Notification = New CallbackDescription(
		"MarkSwitchTimekeepingButton",
		IntegrationWith1CDocumentManagementClient,
		Form.Items);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement.Form.InsertWork",
		FormParameters,
		Form.Items,,,,
		Notification);
	
EndProcedure

// Continues switching timekeeping after finding or creating a linked object BEFORE.
//
// Parameters:
//   Result - Undefined
//             - Structure:
//     * ID - String
//     * type - String
//     * name - String
//   Parameters - Structure:
//     * ObjectIS - AnyRef - reference to the timekeeping object.
//     * Form - ClientApplicationForm - the shape of the timekeeping object.
//
Procedure SwitchTimekeepingAfterSearchingForRelatedObjectTo(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	TimingParameters = IntegrationWith1CDocumentManagementServerCall.ObjectTimingParameters(Parameters.ObjectIS);
	
	NeedDialogue = True;
	
	WorkDuration = GetRunningTime(TimingParameters.StartDateOfTimekeeping);
	If WorkDuration < 60 Then // Less than 1 minute.
		NeedDialogue = False;
	EndIf;
	
	If NeedDialogue Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Source", Result.name);
		FormParameters.Insert("SourceID", Result.ID);
		FormParameters.Insert("SourceType", Result.type);
		
		Notification = New CallbackDescription(
			"MarkSwitchTimekeepingButton",
			IntegrationWith1CDocumentManagementClient,
			Parameters.Form.Items);
		
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagement.Form.InsertWork",
			FormParameters,
			Parameters.ObjectIS,,,,
			Notification);
		
	Else
		
		If TimingParameters.TimekeepingEnabled Then
			
			TimingParameters = IntegrationWith1CDocumentManagementServerCall.SwitchTimekeepingForExternalObject(
				Parameters.ObjectIS,
				TimingParameters);
			
			Parameters.Form.Items.IntegrationWith1CDocumentManagement_SwitchTimekeeping.Check =
				TimingParameters.TimekeepingEnabled;
			
			If TimingParameters.TimekeepingEnabled Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
						|ru = 'Включен хронометраж по ""%1""';
						|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
						|it = 'Crono-analisi attivata per ""%1""';
						|pl = 'Chronometraż jest włączony według ""%1""';
						|tr = '""%1"" ile kronometre etkin'"), String(Parameters.ObjectIS));
				Status(Text);
			EndIf;
			
		Else
			
			ActiveEntries = IntegrationWith1CDocumentManagementServerCall.ActiveTimekeepingRecords();
			
			If ActiveEntries.Count() = 0 Then
				
				TimingParameters = IntegrationWith1CDocumentManagementServerCall.SwitchTimekeepingForExternalObject(
					Parameters.ObjectIS,
					TimingParameters);
				Parameters.Form.Items.IntegrationWith1CDocumentManagement_SwitchTimekeeping.Check =
					TimingParameters.TimekeepingEnabled;
				
				If TimingParameters.TimekeepingEnabled Then
					Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
							|ru = 'Включен хронометраж по ""%1""';
							|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
							|it = 'Crono-analisi attivata per ""%1""';
							|pl = 'Chronometraż jest włączony według ""%1""';
							|tr = '""%1"" ile kronometre etkin'"), String(Parameters.ObjectIS));
					Status(Text);
				EndIf;
				
			Else
				
				NotificationParameters = New Structure;
				NotificationParameters.Insert("ObjectIS", Parameters.ObjectIS);
				NotificationParameters.Insert("ObjectBefore", Result);
				NotificationParameters.Insert("TimingParameters", TimingParameters);
				NotificationParameters.Insert("ActiveEntries", ActiveEntries);
				NotificationParameters.Insert("Form", Parameters.Form);
				
				Notification = New CallbackDescription(
					"SwitchTimingCompletion",
					IntegrationWith1CDocumentManagementClient,
					NotificationParameters);
					
				StringOfTimekeepingObjects = "";
				For Each Record In ActiveEntries Do
					StringOfTimekeepingObjects = StringOfTimekeepingObjects + Chars.Tab
						+ Record.Source + Chars.LF;
				EndDo;
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sử dụng đồng hồ tính thời gian theo các đối tượng khác nhau:
						|%1
						|Tắt đồng hồ tính thời gian và ghi nhận công lao động trước khi sử dụng đồng hồ tính thời gian mới?';
						|ru = 'Включен хронометраж по другим объектам:
						|%1
						|Отключить хронометраж и зафиксировать трудозатраты перед включением нового хронометража?';
						|en = 'Timing by other objects is enabled:
						|%1
						|Disable timing and record labor costs before enabling new timing?'; fa = 'Timing by other objects is enabled:
						|%1
						|Disable timing and record labor costs before enabling new timing?';
						|it = 'Crono-analisi attivata per altri oggetti:
						|%1
						|Disattivare crono-analisi e bloccare il costo del lavoro prima dell''attivazione della nuova crono-analisi?';
						|pl = 'Włączono chronometraż według innych obiektów:
						|%1
						|Wyłączyć chronometraż i ustalić nakłady pracy przed włączeniem nowego chronometrażu?';
						|tr = 'Diğer nesneler için kronometraj etkinleştirildi:
						|%1
						|Yeni kronometrajı etkinleştirmeden önce kronometraj devre dışı bırakılsın ve iş gücü maliyetleri uygulansın mı?'"),
						StringOfTimekeepingObjects);
				Buttons = New ValueList;
				Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Có';
														|ru = 'Да';
														|en = 'Yes'; fa = 'بله';
														|it = 'Sì';
														|pl = 'Yes';
														|tr = 'Evet'"));
				Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
															|ru = 'Отмена';
															|en = 'Cancel'; fa = 'انصراف';
															|it = 'Annulla';
															|pl = 'Cancel';
															|tr = 'İptal'"));
				
				ShowQueryBox(Notification, QueryText, Buttons, 60, DialogReturnCode.Cancel);
				
			EndIf;
				
		EndIf;
		
	EndIf;
	
EndProcedure

// Continuation of the procedure to interrupt the process.
//
// Parameters:
//   Result - Boolean
//   Parameters - Structure:
//     * Form - ClientApplicationForm - the form of the business process.
//
Procedure AbortProcessAfterQuestion(Result, Parameters) Export
	
	If Result <> True Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementServerCall.InterruptProcess(Parameters.Form.ID, Parameters.Form.Type);
	
	Notify_BusinessProcessRecord(Parameters.Form, False);
	
	ShowUserNotification(
		NStr("vi = 'Quy trình đã bị ngắt';
			|ru = 'Процесс прерван';
			|en = 'Process is canceled'; fa = 'Process is canceled';
			|it = 'Processo interrotto';
			|pl = 'Proces został przerwany';
			|tr = 'Süreç kesildi'"),,
		Parameters.Form.Title,
		PictureLib.Information32);
	
EndProcedure

// Continuation of the processing procedure by creating a business process.
//
// Parameters:
//   Result - Boolean
//   CommandParameter - AnyRef
//
Procedure CreateBusinessProcessCheckConnectionEnd(Result, CommandParameter) Export
	
	If Result = True Then
		// Authorization is successful.
		CreateBusinessProcess(CommandParameter);
	EndIf;
	
EndProcedure

// Continuation of the processing procedure of the outgoing command.
//
// Parameters:
//   Result - Boolean
//   ObjectIS - AnyRef
//
Procedure OutgoingEmailCheckConnectionEnd(Result, ObjectIS) Export
	
	If Result = True Then
		// Authorization is successful.
		CallbackDescription = New CallbackDescription(
			"OutgoingEmailRelatedObjectSearchEnd",
			ThisObject,
			ObjectIS);
		IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
			ObjectIS,
			CallbackDescription);
	EndIf;
	
EndProcedure

// Continuation of the procedure outgoing writing to check the connection completion.
//
// Parameters:
//   Result - Structure:
//     * name - String
//     * ID - String
//     * type - String
//   ObjectIS - AnyRef
//
Procedure OutgoingEmailRelatedObjectSearchEnd(Result, ObjectIS) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("SubjectOf", Result);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Outgoing_Email", Parameters);
	
EndProcedure

#EndRegion
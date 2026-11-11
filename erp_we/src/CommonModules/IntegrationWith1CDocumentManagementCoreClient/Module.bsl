////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module Integration1 Document management Database functionality Client: client
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region InterfaceImplementation

#Region StandardSubsystems_BasicFunctionality

// See CommonClientOverridable.AfterStart
Async Procedure AfterStart() Export
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	If ApplicationStartParameters.Property("HideDesktopOnStart") Then
		Return;
	EndIf;
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If Not ClientRunParameters.SeparatedDataUsageAvailable Then
		Return;
	EndIf;
	
	AuthorizationSettingsFromDatabase = Await ReadAuthorizationSettingsAsync();
	
	CallbackOnCompletion = New CallbackDescription(
		"AfterStartCompletion",
		ThisObject,
		AuthorizationSettingsFromDatabase);
	
	TimeConsumingOperation = IntegrationWith1CDocumentManagementCoreServerCall.ConnectAndGetServiceVersionAsynchronously(
		AuthorizationSettingsFromDatabase.UserName,
		AuthorizationSettingsFromDatabase.Password);
	ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CallbackOnCompletion);
	
EndProcedure

#EndRegion

#EndRegion

#Region GeneralProceduresAndFunctions

// Returns the previously saved indication of the completed display of the authorization window.
//
// Returns:
//   Boolean - True if authorization was offered in this session, and False otherwise.
//
Function AuthorizationOffered() Export
	
	Result = (ApplicationParameters["IntegrationWith1CDocumentManagement.AuthorizationOffered"] = True);
	
	IntegrationWith1CDocumentManagementCoreClientOverridable.WhenDefiningAuthorizationOffer(
		Result);
	
	Return Result;
	
EndFunction

// Opens the form for specifying the value of the additional props.
//
// Parameters:
//   Form - ClientApplicationForm - the form on which the work with additional details
//     is carried out and from which the filling form is called.
//   Item - FormField - the element of the form in which the specified value will be placed.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//
Procedure SelectValueOfAdditionalProps(Form, Item, StandardProcessing) Export
	
	StandardProcessing = False;
	
	AvailableTypeList = Item.Parent.CurrentData.AvailableTypeList;
	
	If AvailableTypeList.Count() = 0 Then
		Return;
	EndIf;
	
	If AvailableTypeList.Count() > 1 Then
		
		FormCaption = NStr("vi = 'Kiểu mục tin ""%Property%""';
							|ru = 'Тип реквизита ""%Property%""';
							|en = 'The ""%Property%"" attribute type'; fa = 'The ""%Property%"" attribute type';
							|it = 'Tipo di attributo ""%Property%""';
							|pl = 'Typ atrybutu ""%Property%""';
							|tr = 'Öznitelik türü ""%Property%""'");
		FormCaption = StrReplace(FormCaption,"%Property%",Item.Parent.CurrentData.Property);
		FormParameters = New Structure("AvailableTypeList, FormCaption",
			AvailableTypeList,
			FormCaption);
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("Form", Form);
		NotificationParameters.Insert("Item", Item);
		
		Notification = New CallbackDescription(
			"SelectValueOfAdditionalPropsSelectCompletionType",
			IntegrationWith1CDocumentManagementCoreClient,
			NotificationParameters);
		FormName = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingOneTypeFromCompositeType";
		
		OpenForm(FormName, FormParameters, Form,,,, Notification);
		
	Else
		
		TypeName = AvailableTypeList[0].Value.XDTOClassName;
		SelectValueOfAdditionalAttributeProcessing(TypeName, Form, Item);
		
	EndIf;
	
EndProcedure

// A universal method for selecting an arbitrary value in an input field.
//
// Parameters:
//   Form - ClientApplicationForm - the form from which the command is called.
//   Item - FormField - the field where the selected value should be placed.
//   Types - ValueList of Type - the type of value to select.
//        - Array of Type
//   ValueSelectionParameters - See IntegrationWith1CDocumentManagementCoreClient.ValueSelectionParametersBefore
//
Procedure ChooseValueOfAttributeBefore(Form, Item, Types, ValueSelectionParameters) Export
	
	If Types.Count() = 1 Then
		If TypeOf(Types) = Type("Array") Then
			Value = Types[0];
		Else
			Value = Types[0].Value;
		EndIf;
		ChooseValueOfAttributeBeforeCompletion(Value, ValueSelectionParameters);
	Else
		CallbackDescription = New CallbackDescription(
			"ChooseValueOfAttributeBeforeCompletion",
			ThisObject,
			ValueSelectionParameters);
		If TypeOf(Types) = Type("Array") Then
			Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
			TypesList = New ValueList;
			For Each XDTOType In Types Do
				TypesList.Add(XDTOType, ObjectTypePresentationXDTO(XDTOType, Settings));
			EndDo;
		Else
			TypesList = Types;
		EndIf;
		
		Form.ShowChooseFromList(CallbackDescription, TypesList, Item);
	EndIf;
	
EndProcedure

// A universal method for selecting an arbitrary value in an input field.
//
// Parameters:
//   Form - ClientApplicationForm - the form from which the command is called.
//   Item - FormField - the field where the selected value should be placed.
//   Type - TypeDescription - the type of value to select.
//   Presentation - String - representation of the Attribute for which the value is selected.
//   AttributeValue - Arbitrary - the Cur value in the input field.
//   AdditionalAttributeIS - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - passed if
//     you need to select the value of an additional Attribute.
//   Notification - CallbackDescription - calls the procedure of the form to which the selected value is passed.
//
Procedure ChooseValueOfAttributeIS(Form, Item, Type, Presentation, AttributeValue, AdditionalAttributeIS,
		Notification) Export
	
	Types = Type.Types();
	
	ParametersSelectValue = New Structure;
	ParametersSelectValue.Insert("TypeDetails", Type);
	ParametersSelectValue.Insert("EditText", Item.EditText);
	ParametersSelectValue.Insert("Presentation", Presentation);
	ParametersSelectValue.Insert("AttributeValue", AttributeValue);
		ParametersSelectValue.Insert("AdditionalAttributeIS", AdditionalAttributeIS);
	ParametersSelectValue.Insert("Notification", Notification);
	
	If Types.Count() = 1 Then
		ChooseValueOfAttributeISCompletionTypeSelection(Types[0], ParametersSelectValue);
	Else
		NotificationSelectValue = New CallbackDescription(
			"ChooseValueOfAttributeISCompletionTypeSelection",
			ThisObject,
			ParametersSelectValue);
		TypesList = New ValueList;
		TypesList.LoadValues(Types);
		Form.ShowChooseFromList(NotificationSelectValue, TypesList, Item);
	EndIf;
	
EndProcedure

// starts a long-term operation of a request to the 1C service:Document flow, and also displays on the form a sign of
// a long-term operation.
//
// Parameters:
//   Owner - ClientApplicationForm - the form from which the command is called.
//            - CommonModule - the client module from which the command is called.
//   TimeConsumingOperation - See TimeConsumingOperations.ExecuteInBackground
//   CallbackOnCompletion - CallbackDescription - calls the procedure of the form to which the result of the request is passed.
//   OutputIdleWindow - Boolean - if True, then open the standby window with a visual indication of a long operation.
//   MessageText - String - the text of the message displayed on the waiting form.
//   HideInterface - Boolean - if the waiting window is not displayed, then this parameter indicates whether to use
//     page switching, which will hide the entire interface, or whether you do not need to hide the interface, but make visible
//     a group of elements of a long operation.
//
Procedure ExecuteRequestAsynchronously(Owner, TimeConsumingOperation, CallbackOnCompletion,
		OutputIdleWindow = False, MessageText = Undefined, HideInterface = True) Export
	
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	If TimeConsumingOperation.Status <> "Running" And TimeConsumingOperation.JobID = Undefined Then
		// handlers for waiting for the End of a background task are linked to the id.
		TimeConsumingOperation.JobID = New UUID;
	EndIf;
	
	If TypeOf(Owner) = Type("ClientApplicationForm") Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Owner);
		Items = Owner.Items;
		If Not OutputIdleWindow Then
			
			If HideInterface And (Items.Find("ConnectionPageGroup") <> Undefined) Then
				
				Items.ConnectionPageGroup.CurrentPage = Items.PageLoadingFromDM;
				If ValueIsFilled(MessageText) Then
					OldTitle = Items.DescriptionLoadingFromTOPage.Title;
					Items.DescriptionLoadingFromTOPage.Title = StrTemplate("%1..", MessageText);
				EndIf;
				
			ElsIf Items.Find("GroupUploadFromDM") <> Undefined Then
				
				Items.GroupUploadFromDM.Visible = True;
				
			EndIf;
			
		EndIf;
		
	Else
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Undefined);
		
	EndIf;
	
	If ValueIsFilled(MessageText) Then
		IdleParameters.MessageText = MessageText;
	Else
		IdleParameters.MessageText = NStr("vi = 'Nhận dữ liệu từ 1C:Document Management.';
											|ru = 'Получение данных из 1С:Документооборота.';
											|en = 'Get data from 1C:Document Management.'; fa = 'Get data from 1C:Document Management.';
											|it = 'Получение данных из 1С:Документооборота.';
											|pl = 'Get data from 1C:Document Management.';
											|tr = '1C:Document Management üzerinden verilerin alınması.'");
	EndIf;
	IdleParameters.OutputIdleWindow = OutputIdleWindow;
	
	NotificationOfLongTermOperation = New CallbackDescription(
		"ExecuteRequestAsynchronouslyCompletion",
		ThisObject,
		TimeConsumingOperation.JobID);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Owner", Owner);
	NotificationParameters.Insert("CallbackOnCompletion", CallbackOnCompletion);
	NotificationParameters.Insert("OutputIdleWindow", OutputIdleWindow);
	NotificationParameters.Insert("HideInterface", HideInterface);
	NotificationParameters.Insert("OldTitle", OldTitle);
	
	IdleHandlers = ActiveBackgroundJobWaitingHandlers();
	TaskWaitingHandlers = IdleHandlers[TimeConsumingOperation.JobID];
	If TaskWaitingHandlers = Undefined Then
		ParametersArray = New Array;
		ParametersArray.Add(NotificationParameters);
		IdleHandlers.Insert(TimeConsumingOperation.JobID, ParametersArray)
	Else
		TaskWaitingHandlers.Add(NotificationParameters);
	EndIf;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, NotificationOfLongTermOperation, IdleParameters);
	
EndProcedure

// Generates and displays printed forms.
//
// Parameters:
//   PrintManagerName - String - the print Manager for printing objects;
//   TemplatesNames - String - print form IDs;
//   ObjectsArray - AnyRef
//                  - Array of AnyRef - print objects;
//   FormOwner - ClientApplicationForm - the form to print from;
//
Procedure ExecutePrintCommand(PrintManagerName, TemplatesNames, ObjectsArray, FormOwner) Export
	
	PrintParameters = New Structure;
	PrintParameters.Insert(
		"IntegrationWith1CWorkflow_ParametersOfOperation",
		IntegrationWith1CDocumentManagementCoreServerCall.TimeConsumingOperationParameters());
	
	ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
	ModulePrintManagerClient.ExecutePrintCommand(
		PrintManagerName,
		TemplatesNames,
		ObjectsArray,
		FormOwner,
		PrintParameters);
	
EndProcedure

// Executes the connected integration command with 1C:Document flow from the object form or list.
//
// Parameters:
//   Command - FormCommand - the command called.
//   Form - ClientApplicationForm - the form from which the command is called.
//   Source - FormDataStructure, FormTable - the data specifying the command parameter contains a reference to the IC object.
//
Procedure ExecutePlugInIntegrationCommand(Command, Form, Source) Export
	
	Parameters = New Structure;
	Parameters.Insert("Command", Command);
	Parameters.Insert("Form", Form);
	Parameters.Insert("Source", Source);
	
	CallbackDescription = New CallbackDescription(
		"ExecutePlugInIntegrationCommandCompletion",
		ThisObject,
		Parameters);
	TestConnection(
		CallbackDescription,
		ThisObject,
		True);
	
EndProcedure

// Continues execution of the connected integration command after connection verification.
//
// Parameters:
//   Result - Boolean - True if the connection is successful.
//   Parameters - Structure:
//     * Command - FormCommand - the command called.
//     * Form - ClientApplicationForm - the form from which the command is called.
//     * Source - FormTable
//                - FormDataStructure:
//         ** Ref - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable
//
Procedure ExecutePlugInIntegrationCommandCompletion(Result, Parameters) Export
	
	If Result <> True Then
		Return;
	EndIf;
	
	Command = Parameters.Command;
	Form = Parameters.Form;
	Source = Parameters.Source;
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If Settings.UseIntegrationBefore2 Then
		ModuleIntegrationWith1CDocumentManagementClient = CommonClient.CommonModule(
			"IntegrationWith1CDocumentManagementClient");
		ModuleIntegrationWith1CDocumentManagementClient.ExecutePlugInIntegrationCommandCompletion(
			Command,
			Form,
			Source);
	ElsIf Settings.UseIntegrationBefore3 Then
		ModuleIntegrationWith1CDocumentManagement3Client = CommonClient.CommonModule(
			"IntegrationWith1CDocumentManagement3Client");
		ModuleIntegrationWith1CDocumentManagement3Client.ExecutePlugInIntegrationCommandCompletion(
			Command,
			Form,
			Source);
	EndIf;
	
EndProcedure

// Checks whether the integrated system object is recorded. If not recorded, it prompts the user to record.
//
// Parameters:
//   ObjectReferenceIS - AnyRef - the IC object being checked.
//   ShapeOfIPObject - ClientApplicationForm - the form from which the command is called.
//   ContinueNotification - CallbackDescription - action called after verification.
//   Action - String - name of the action.
//
Async Procedure PerformRecordCheckAndContinue(Val ObjectReferenceIS, Val ShapeOfIPObject,
		Val ContinueNotification, Val Action) Export
	
	If ObjectReferenceIS.IsEmpty() Then
		
		WarningText = StrTemplate(
			NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
			|Chỉ có thể thực hiện lệnh ""%1"" sau khi ghi lại dữ liệu.';
			|ru = 'Данные еще не записаны.
			|Выполнение действия ""%1"" возможно только после записи данных.';
			|en = 'You have unsaved data.
			|You can perform the ""%1"" action only after you save the data.'; fa = 'You have unsaved data.
			|You can perform the ""%1"" action only after you save the data.';
			|it = 'Данные еще не записаны.
			|Выполнение действия ""%1"" возможно только после записи данных.';
			|pl = 'You have unsaved data.
			|You can perform the ""%1"" action only after you save the data.';
			|tr = 'Veriler henüz kaydedilmedi.
			| Eylem ""%1"" ancak veriler yazıldıktan sonra gerçekleştirilebilir.'"),
			Action);
		
		CanIAskQuestion = True;
		If ShapeOfIPObject = Undefined Then
			CanIAskQuestion = False;
		Else
			// let's check if we can determine the main Attributes of the form.
			FormAttributes = New Structure("Object", Undefined);
			FillPropertyValues(FormAttributes, ShapeOfIPObject);
			If FormAttributes.Object = Undefined Then
				CanIAskQuestion = False;
			Else
				FormObject = FormAttributes.Object; // DocumentObject
				If TypeOf(FormObject.Ref) <> TypeOf(ObjectReferenceIS) Then
					CanIAskQuestion = False;
				EndIf;
			EndIf;
		EndIf;
		
		If CanIAskQuestion = False Then
			// We can't do anything.
			ShowMessageBox(, WarningText);
			Return;
		EndIf;
		
		// We will offer the user to automatically record the IC object and continue.
		AdditionalParameters = New Structure("ShapeOfIPObject, ContinueNotification",
			ShapeOfIPObject,
			ContinueNotification);
		QueryText = StrTemplate(
			NStr("vi = '%1
			|Dữ liệu sẽ được ghi lại.';
			|ru = '%1
			|Данные будут записаны.';
			|en = '%1
			|The data will be saved.'; fa = '%1
			|The data will be saved.';
			|it = '%1
			|Данные будут записаны.';
			|pl = '%1
			|The data will be saved.';
			|tr = '%1
			|Veriler kaydedilecek.'"),
			WarningText);
		QuestionParametersYesNo = QuestionParametersYesNo(DialogReturnCode.Yes);
		QuestionParametersYesNo.YesButtonText = NStr("vi = 'Đồng ý';
													|ru = 'ОК';
													|en = 'OK'; fa = 'تأیید';
													|it = 'ОК';
													|pl = 'OK';
													|tr = 'Tamam'");
		QuestionParametersYesNo.NoButtonText = NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Отмена';
													|pl = 'Anuluj';
													|tr = 'İptal'");
		Response = Await ShowQuestionYesNoAsync(
			QueryText,
			QuestionParametersYesNo);
		
		If Response = DialogReturnCode.Yes Then
			Form = AdditionalParameters.ShapeOfIPObject;
			Form.Write();
			FormObject = Form.Object; // DocumentObject
			If Not FormObject.Ref.IsEmpty() And Not Form.Modified Then
				RunCallback(
					AdditionalParameters.ContinueNotification,
					FormObject.Ref);
			EndIf;
		EndIf;
		
	Else
		// The user does not need a question.
		RunCallback(ContinueNotification, ObjectReferenceIS);
	EndIf;
	
EndProcedure

// Determines whether BID modules designed for integration with 1C are built into the configuration:Document management of edition 2.
//
// Returns:
//   Boolean
//
Function ThereIsSubsystemUPTo2() Export
	
	Return CommonClient.SubsystemExists(
		"IntegrationWith1CDocumentManagementSubsystem.IntegrationWith1CDocumentManagementEdition2Subsystem");
	
EndFunction

// Determines whether BID modules designed for integration with 1C are built into the configuration:Document management of edition 3.
//
// Returns:
//   Boolean
//
Function ThereIsSubsystemUPTo3() Export
	
	Return CommonClient.SubsystemExists(
		"IntegrationWith1CDocumentManagementSubsystem.IntegrationWith1CDocumentManagementEdition3Subsystem");
	
EndFunction

// Records changes to the object in the Workflow in the background job.
//
// Parameters:
//   FormUniqueID - UUID - ID of the calling form.
//   RowObject - String - string Presentation of the XDTO object with stored data.
//   CallbackOnCompletion - CallbackDescription - calls the Form procedure after writing the object.
//
Procedure WriteObjectAsynchronously(FormUniqueID, RowObject, CallbackOnCompletion) Export
	
	TimeConsumingOperation = IntegrationWith1CDocumentManagementCoreServerCall.WriteObjectAsynchronously(
		FormUniqueID,
		RowObject);
	
	ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CallbackOnCompletion,
		True,
		NStr("vi = 'Đang thực hiện ghi.';
			|ru = 'Выполняется запись.';
			|en = 'Saving the object.'; fa = 'Saving the object.';
			|it = 'Выполняется запись.';
			|pl = 'Saving the object.';
			|tr = 'Kayıt yapılıyor.'"),
		False);
	
EndProcedure

// Searches for a related object UP TO, if necessary, creating it based on the IP object
// with filling in according to the integration rules, if a suitable rule exists.
//
// Parameters:
//   ObjectIS - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object
//     for which the associated object is being searched BEFORE.
//   CallbackDescription - CallbackDescription - a handler called after creation with
//     passing as a Structure parameter (ID, type, name).
//   GetPersonalIncomeTax - Boolean - You need to get the State-based accessibility settings on the Workflow side.
//   UsePriorityRules - Boolean - do I need to ask the user a question when creating a new IP object according to
//     the integration rules, if several different integration rules are configured for the IP object,
//     or do I need to use the rule with the highest priority for key Attributes? This parameter is used only in
//     case of integration with UP to 3.
//   AskQuestionAboutFileTransfer - Boolean - indicates whether you want to ask a question about transferring files from the IP to BEFORE
//      after adding a new link.
//
Procedure StartSearchingForARelatedObjectDM(ObjectIS, CallbackDescription, GetPersonalIncomeTax = False,
		UsePriorityRules = False, AskQuestionAboutFileTransfer = True) Export
	
	LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
		ObjectIS,,
		GetPersonalIncomeTax);
	
	If LinkedObjectBefore <> Undefined Then // Found.
		RunCallback(CallbackDescription, LinkedObjectBefore);
		Return;
	EndIf;
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If Settings.UseIntegrationBefore2 Then
		ModuleIntegrationWith1CDocumentManagementClient = CommonClient.CommonModule(
			"IntegrationWith1CDocumentManagementClient");
		ModuleIntegrationWith1CDocumentManagementClient.StartCreatingARelatedObjectDM(ObjectIS, CallbackDescription);
	ElsIf Settings.UseIntegrationBefore3 Then
		ModuleIntegrationWith1CDocumentManagement3Client = CommonClient.CommonModule(
			"IntegrationWith1CDocumentManagement3Client");
		ModuleIntegrationWith1CDocumentManagement3Client.StartCreatingARelatedObjectDM(
			ObjectIS,
			CallbackDescription,
			UsePriorityRules,
			AskQuestionAboutFileTransfer);
	EndIf;
	
EndProcedure

// Fills in the details of the form for the selected value.
//
// Parameters:
//   Attribute - String - a string with the name of the form's props.
//   ValueSelected - String, Structure - selected value.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//   OwnerForm - ClientApplicationForm - a form containing the details to be filled in.
//   ThisIsTable - Boolean - a sign indicating that it is required to fill in the details of the row of the table part.
//   Item - FormField - the field of the table part in which the user enters the value.
//   SetModification - Boolean - set the modification of the owner form.
//
Procedure ProcessingSelectionOfDataForAutoMatching(Attribute, ValueSelected, StandardProcessing, OwnerForm,
		ThisIsTable = False, Item = Undefined, SetModification = True) Export
	
	HadChanges = False;
	If TypeOf(ValueSelected) = Type("Structure") Then
		StandardProcessing = False;
		
		If ValueSelected.Property("isNotAvailableAccordingCommunicationRules")
				And ValueSelected.isNotAvailableAccordingCommunicationRules = True Then
			ModuleIntegrationWith1CDocumentManagement3Client =
				CommonClient.CommonModule("IntegrationWith1CDocumentManagement3Client");
			ModuleIntegrationWith1CDocumentManagement3Client.ShowViolationOfRulesOfCommunication();
			Return;
		EndIf;
		
		If Not ValueSelected.Property("presentation") Then
			ValueSelected.Insert("presentation", ValueSelected.name);
		EndIf;
		
		Result = New Structure;
		Result.Insert(Attribute, ValueSelected.name);
		Result.Insert(Attribute + "ID", ValueSelected.ID);
		Result.Insert(Attribute + "Type", ValueSelected.type);
		Result.Insert(Attribute + "Presentation", ValueSelected.presentation);
		If ThisIsTable Then
			FillPropertyValues(FieldStringOfTablePart(Item), Result);
		Else
			FillPropertyValues(OwnerForm, Result);
		EndIf;
		HadChanges = True;
	ElsIf TypeOf(ValueSelected) = Type("String") Then
		If ThisIsTable Then
			FieldStringOfTablePart(Item)[Attribute] = ValueSelected;
		Else
			OwnerForm[Attribute] = ValueSelected;
		EndIf;
		HadChanges = True;
	EndIf;
	
	If HadChanges Then
		If SetModification Then
			OwnerForm.Modified = True;
		EndIf;
		NotificationParameters = New Structure;
		NotificationParameters.Insert("Attribute", Attribute);
		NotificationParameters.Insert("ThisIsTable", ThisIsTable);
		NotificationParameters.Insert("Item", Item);
		Notify("DocumentManagement_SelectingDataForAutoComplete", NotificationParameters, OwnerForm);
	EndIf;
	
EndProcedure

// Checks whether a long-term of operation has been completed.
//
// Parameters:
//   Result - See TimeConsumingOperations.ActionCompleted
//   NeedToProcessForm - Boolean - an implicit return value, True, if you want to process the Form.
//   OutputDetailedPresentationOfError - Boolean - in case of an error, you need to raise
//     an exception with a detailed Presentation.
//
// Returns:
//   Boolean - True if a long-running Operation has been performed, False if the Operation is still in progress or an error has occurred.
//
Function ActionCompleted(Result, NeedToProcessForm = False, OutputDetailedPresentationOfError = False) Export
	
	If Result = Undefined Then
		Return False;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		Return True;
		
	ElsIf Result.Status = "Error" Then
		
		If OutputDetailedPresentationOfError Then
			ErrorPresentation = Result.DetailErrorDescription;
		Else
			ErrorPresentation = Result.BriefErrorDescription;
		EndIf;
		NeedToProcessForm = IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
			ErrorPresentation);
		
	EndIf;
	
	Return False;
	
EndFunction

// Creates an alert when a connection is added on the client.
//
// Parameters:
//   ID - String - ID of the document flow object.
//   Type - String - the XDTO type of the Workflow object.
//   ObjectReference - AnyRef - reference to the integrated system object.
//   AskQuestionAboutFileTransfer - Boolean - indicates whether you want to ask a question about transferring files from the IP to BEFORE
//     after adding a new link.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure Notify_AddingConnection(ID, Type, ObjectReference, AskQuestionAboutFileTransfer = True,
		FormUniqueID = Undefined) Export

	NotificationParameters = New Structure;
	NotificationParameters.Insert("ID", ID);
	NotificationParameters.Insert("Type", Type);
	NotificationParameters.Insert("Object", ObjectReference);
	NotificationParameters.Insert("FormUniqueID", FormUniqueID);
	
	Notify("DocumentManagement_AddingALink", NotificationParameters);
	
	If AskQuestionAboutFileTransfer Then
		FileTransferOptions =
			IntegrationWith1CDocumentManagementCoreServerCall.ParametersForTransferringFilesToDM(
				NotificationParameters);
		If FileTransferOptions.NeedToAskQuestionAboutTransferringFilesToDM
				And (FileTransferOptions.StateAllowsFileAddition
					Or FileTransferOptions.StateAllowsAddingScannedCopy) Then
			ModuleIntegrationWith1CDocumentManagement3Client = CommonClient.CommonModule(
				"IntegrationWith1CDocumentManagement3Client");
			ModuleIntegrationWith1CDocumentManagement3Client.ToAskQuestionAboutTransferringFilesToDM(
				FileTransferOptions,,
				FormUniqueID);
		EndIf;
	EndIf;
	
EndProcedure

// Creates an alert when a connection is deleted on the client.
//
// Parameters:
//   ID - String - ID of the document flow object.
//   Type - String - the XDTO type of the Workflow object.
//   ObjectReference - AnyRef - a reference to the system object.
//
Procedure Notify_RemovingLink(ID, Type, ObjectReference) Export

	NotificationParameters = New Structure;
	NotificationParameters.Insert("ID", ID);
	NotificationParameters.Insert("Type", Type);
	NotificationParameters.Insert("Object", ObjectReference);
	
	Notify("DocumentManagement_DeletingALink", NotificationParameters);
	
EndProcedure

// Sets the selection when selecting a DO object associated with an IP object.
//
// Parameters:
//   ObjectToLink - AnyRef - the IP object associated with the object BEFORE.
//   ObjectType1CDocumentManagement - String - the type of the selected object is UP TO.
//   DocumentKindDM - Structure - filled in for objects UP to the Document type:
//     * Value - String - name of the document type.
//     * ValueID - String - id of the document type.
//
// Returns:
//   Undefined, Structure - the structure of the selection imposed before presentation to the user:
//     * documentType - Undefined
//                    - Structure - filled in for objects UP to the Document type:
//       ** Value - String - name of the document type.
//       ** ValueID - String - id of the document type.
//
Function SelectionWhenSelectingLinkedObject(ObjectToLink, ObjectType1CDocumentManagement,
		DocumentKindDM = Undefined) Export
	
	Filter = Undefined;
	
	IntegrationWith1CDocumentManagementCoreClientOverridable.WhenSettingSelectionWhenSelectingRelatedObject(
		ObjectToLink,
		ObjectType1CDocumentManagement,
		Filter);
	
	If ValueIsFilled(DocumentKindDM) Then
		If Filter = Undefined Then
			Filter = New Structure;
		EndIf;
		Filter.Insert("documentType", DocumentKindDM);
	EndIf;
	
	Return Filter;
	
EndFunction

// opens the required version of the "tasks for me" form, depending on which version of 1C:Document management is used.
//
// Parameters:
//   Owner - ClientApplicationWindow , ClientApplicationForm - a form or control of another form.
//   Uniqueness - Arbitrary - the key whose value will be used to search for already open forms.
//   Window - ClientApplicationWindow - the application window where the form will be opened.
//
Procedure OpenTasksForMe(Owner, Uniqueness, Window) Export
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If Settings.UseIntegrationBefore2 Then
		FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.TasksToMe";
	ElsIf Settings.UseIntegrationBefore3 Then
		FormName = "DataProcessor.IntegrationWith1CDocumentManagement3.Form.TasksToMe";
	Else
		Return;
	EndIf;
	
	OpenForm(FormName,, Owner, Uniqueness, Window);
	
EndProcedure

// Opens the navigation link in the program that is associated with the navigation link protocol.
// Valid protocols: http, https, e1c, v8help, mailto, tel, skype.
//
// Parameters:
//   URL - String - the link to open.
//
Procedure OpenURL(Val URL) Export
	
	ProcessURL1(URL);
	
	FileSystemClient.OpenURL(URL);
	
EndProcedure

// Opens the Workflow object.
//
// Parameters:
//   ObjectType - String - the type of the Document Flow object XDTO.
//   ID - String - ID of the document flow object.
//   FormOwner - Arbitrary - an arbitrary value that is set as the owner of the form.
//   AdditionalParameters - Structure - parameters passed to the object being opened.
//   Notification - CallbackDescription - notification when the form is closed.
//
Procedure OpenObject(ObjectType, ID, FormOwner = Undefined, AdditionalParameters = Undefined,
		Notification = Undefined) Export
	
	If Not ValueIsFilled(ObjectType) Then
		Return;
	EndIf;
	
	SourceOfFormIsBasic = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.";
	
	MatchingFormsBasic = New Map;
	MatchingFormsBasic.Insert("DMFile", "File");
	
	FormName = MatchingFormsBasic.Get(ObjectType);
	
	If ValueIsFilled(FormName) Then
		
		FormParameters = New Structure("ID, type", ID, ObjectType);
		If ValueIsFilled(AdditionalParameters) Then
			For Each Item In AdditionalParameters Do
				FormParameters.Insert(Item.Key, Item.Value);
			EndDo;
		EndIf;
		
		OpenForm(SourceOfFormIsBasic + FormName, FormParameters, FormOwner, ID,,, Notification);
		
	Else
		
		MatchingForms = New Map;
		
		Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
		If Settings.UseIntegrationBefore2 Then
			FormSource = "DataProcessor.IntegrationWith1CDocumentManagement.Form.";
			ModuleIntegrationWith1CDocumentManagementClient = CommonClient.CommonModule(
				"IntegrationWith1CDocumentManagementClient");
			ModuleIntegrationWith1CDocumentManagementClient.FillInMatchingForms(MatchingForms);
		ElsIf Settings.UseIntegrationBefore3 Then
			FormSource = "DataProcessor.IntegrationWith1CDocumentManagement3.Form.";
			ModuleIntegrationWith1CDocumentManagement3Client = CommonClient.CommonModule(
				"IntegrationWith1CDocumentManagement3Client");
			ModuleIntegrationWith1CDocumentManagement3Client.FillInMatchingForms(MatchingForms);
		EndIf;
		
		FormName = MatchingForms.Get(ObjectType);
		
		If ValueIsFilled(FormName) Then
			
			FormParameters = New Structure("ID, type", ID, ObjectType);
			If ValueIsFilled(AdditionalParameters) Then
				For Each Item In AdditionalParameters Do
					FormParameters.Insert(Item.Key, Item.Value);
				EndDo;
			EndIf;
			
			OpenForm(FormSource + FormName, FormParameters, FormOwner, ID,,, Notification);
			
		Else
			ShowMessageBox(,
				NStr("vi = 'Phiên bản 1C:Document Management này không hỗ trợ xem đối tượng kiểu này.';
					|ru = 'Просмотр объектов такого типа не поддерживается в этой версии 1С:Документооборота.';
					|en = 'View of this type objects is not supported in this version of 1C:Document Management.'; fa = 'View of this type objects is not supported in this version of 1C:Document Management.';
					|it = 'La visualizzazione degli oggetto di questo tipo non è supportata in questa versione di 1C:Document Management.';
					|pl = 'Przegląd obiektów takiego typu nie jest obsługiwany w tej wersji 1C:Document Management.';
					|tr = 'Bu türdeki nesnelerin görüntülenmesi, 1C:Document Management''ın bu sürümünde desteklenmemektedir.'"));
		EndIf;
		
	EndIf;
	
EndProcedure

// A structure constructor for showing the "Yes"/ "No" question.
//
// Parameters:
//   DefaultButton - QuestionDialogMode, Undefined - optional, default button.
//
// Returns:
//   Structure:
//     * YesButtonText - String - optional, the text of the "Yes" button.
//     * NoButtonText - String - optional, the text of the "No" button.
//     * DefaultButton - QuestionDialogMode, Undefined - optional, default button.
//     * Title - String - optional, contains the title of the question window.
//
Function QuestionParametersYesNo(DefaultButton = Undefined) Export
	
	QuestionParametersYesNo = New Structure;
	QuestionParametersYesNo.Insert("DefaultButton", DefaultButton);
	QuestionParametersYesNo.Insert("YesButtonText", "");
	QuestionParametersYesNo.Insert("NoButtonText", "");
	QuestionParametersYesNo.Insert("Title", "");
	
	Return QuestionParametersYesNo;
	
EndFunction

// Structure constructor for selecting an arbitrary value UP to.
//
// Returns:
//   Structure:
//     * EditText - String - the text of editing the Form element.
//     * Presentation - String - representation of the Attribute for which the value is selected.
//     * AttributeValue - String - the Cur value in the input field.
//     * AttributeValueID - String - the Cur value in the input field.
//     * AttributeValueType - String - the Cur value in the input field.
//     * Notification - CallbackDescription, Undefined - calls the procedure to which the selected value is passed.
//     * Filter - Structure, Undefined - selection for selection from the list.
//
Function ValueSelectionParametersBefore() Export
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("EditText", "");
	ChoiceParameters.Insert("Presentation", "");
	ChoiceParameters.Insert("AttributeValue", "");
	ChoiceParameters.Insert("AttributeValueID", "");
	ChoiceParameters.Insert("AttributeValueType", "");
	ChoiceParameters.Insert("Notification", Undefined);
	ChoiceParameters.Insert("Filter", Undefined);
	
	Return ChoiceParameters;
	
EndFunction

// Checks whether it is necessary to add a link if the IP object was created based on the object BEFORE.
//
// Parameters:
//   Source - ClientApplicationForm - The Form of a new IP object.
//
Procedure BeforeExecutingCommand(Source) Export
	
	If TypeOf(Source) = Type("ClientApplicationForm")
			And TypeOf(Source.CallbackDescriptionOnClose) = Type("CallbackDescription")
			And Source.CallbackDescriptionOnClose.ProcedureName = "CreateIntegratedCompletionObject" Then
		CreateIntegratedCompletionObject(
			Undefined,
			Source.CallbackDescriptionOnClose.AdditionalParameters);
		Source.CallbackDescriptionOnClose = Undefined;
	EndIf;
	
EndProcedure

// Shows the question "Yes"/ "No", taking Esc and closing the form with a cross as the answer "No".
//
// Parameters:
//   QueryText - String - the text of the question being asked.
//   QuestionParameters - See IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo
//
// Returns:
//   Promise - the result of fulfilling the promise of the code of return of the dialog.
//
Function ShowQuestionYesNoAsync(QueryText, QuestionParameters = Undefined) Export
	
	If QuestionParameters = Undefined Then
		QuestionParameters = QuestionParametersYesNo();
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
		Return DoQueryBoxAsync(QueryText, Buttons,,, QuestionParameters.Title);
	ElsIf QuestionParameters.DefaultButton = DialogReturnCode.Yes Then
		Return DoQueryBoxAsync(QueryText, Buttons,, DialogReturnCode.Yes, QuestionParameters.Title);
	ElsIf QuestionParameters.DefaultButton = DialogReturnCode.No Then
		Return DoQueryBoxAsync(QueryText, Buttons,, DialogReturnCode.No, QuestionParameters.Title);
	Else
		Raise StrTemplate(NStr("vi = 'Giá trị không hợp lệ của nút theo mặc định: %1';
								|ru = 'Недопустимое значение кнопки по умолчанию: %1';
								|en = 'Invalid value for the default button: %1'; fa = 'Invalid value for the default button: %1';
								|it = 'Недопустимое значение кнопки по умолчанию: %1';
								|pl = 'Domyślna niedopuszczalna wartość przycisku: %1';
								|tr = 'Geçersiz düğmenin varsayılan değeri: %1'"),
			QuestionParameters.DefaultButton);
	EndIf;
	
EndFunction

// Returns a Presentation of the Document Flow object type XDTO by type name.
// By default, it returns a singular Presentation.
//
// Parameters:
//   XDTOType - String - the name of the XDTO object type.
//   Settings - See IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration
//   PluralForm - Boolean - It is required to return the Presentation in the plural.
//   ForFormOfSelection - Boolean - it is required to return a Presentation for the selection Form starting with "Selection ...".
//
// Returns:
//   String - representation of the type of the Document Flow object XDTO by type name.
//
Function ObjectTypePresentationXDTO(XDTOType, Settings = Undefined, PluralForm = False,
		ForFormOfSelection = False) Export
	
	If Settings = Undefined Then
		Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	EndIf;
	
	If Settings.UseIntegrationBefore2 Then
		ModuleIntegrationWith1CDocumentManagementClientServer = CommonClient.CommonModule(
			"IntegrationWith1CDocumentManagementClientServer");
		Return ModuleIntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(
			XDTOType,
			PluralForm,
			ForFormOfSelection);
		
	ElsIf Settings.UseIntegrationBefore3 Then
		ModuleIntegrationWith1CDocumentManagement3ClientServer = CommonClient.CommonModule(
			"IntegrationWith1CDocumentManagement3ClientServer");
		Return ModuleIntegrationWith1CDocumentManagement3ClientServer.ObjectTypePresentationXDTO(
			XDTOType,
			PluralForm,
			ForFormOfSelection);
		
	EndIf;
	
EndFunction

// Controls the activity of the access token update handler in the DO.
//
// Parameters:
//   JWTAuthenticationIsUsed - Boolean - the Cur user uses authorization via a jwt token.
//
Procedure WhenLoggingIn(JWTAuthenticationIsUsed) Export
	
	If JWTAuthenticationIsUsed Then
		AttachIdleHandler(
			"WhenLifetimeOfAccessTokenExpires",
			IntegrationWith1CDocumentManagementCoreServerCall.LifetimeOfAccessToken());
	Else
		DetachIdleHandler("WhenLifetimeOfAccessTokenExpires");
	EndIf;
	
EndProcedure

// Checks the result of a long-term operation of operation for errors, and, if necessary, switches
// the Form interface to the error page when updating.
//
// Parameters:
//   Form - ClientApplicationForm - The Form in which the update is performed.
//   Result - See TimeConsumingOperations.ActionCompleted
//   NeedToProcessForm - Boolean - an implicit return value, True, if you want to process the Form.
//
Procedure CheckForErrorsWhenUpdatingForm(Form, Result, NeedToProcessForm = False) Export
	
	If Result <> Undefined Then
		If Result.Status = "Error" And Form.IsInitialized = False Then
			Form.Items.ConnectionPageGroup.CurrentPage = Form.Items.PageUpdateError;
			Form.TextOfUpdateError = Result.BriefErrorDescription;
		ElsIf Form.Items.ConnectionPageGroup.CurrentPage = Form.Items.PageUpdateError Then
			Form.TextOfUpdateError = "";
			NeedToProcessForm = True;
		EndIf;
	EndIf;
	
EndProcedure

// Checks the connection to 1C:Document management, if necessary, requesting a username and password.
//
// Parameters:
//
//   CallbackDescription - CallbackDescription - description of the notification that is called after checking the connection with
//     the Boolean parameter.
//   Owner - ClientApplicationForm - the form in which to call the connection attempt again.
//            - CommonModule - the client module from which the command is called.
//   ReShowAuthorizationWindow - Boolean - True if, when there is no connection, it is necessary
//     to re-show the authorization window, even if it was shown earlier.
//   OutputIdleWindow - Boolean - if True, then open the standby window with a visual indication of a long operation.
//   HideInterface - Boolean - if the waiting window is not displayed, then this parameter indicates whether to use
//     page switching, which will hide the entire interface, or whether you do not need to hide the interface, but make visible
//     a group of elements of a long operation.
//   AddressOfDocumentManagementWebService - String - the address of the web service BEFORE, or
//                                   - Undefined - indicates the need to use a previously saved address.
//
Async Procedure TestConnection(Val CallbackDescription, Val Owner,
		Val ReShowAuthorizationWindow = False, Val OutputIdleWindow = True,
		Val HideInterface = False, Val AddressOfDocumentManagementWebService = Undefined) Export
	
	If IntegrationWith1CDocumentManagementCoreServerCall.PasswordKnown()
			And AddressOfDocumentManagementWebService = Undefined Then
		RunCallback(CallbackDescription, True);
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("AuthorizationSettings", Await ReadAuthorizationSettingsAsync());
	NotificationParameters.Insert("CallbackDescription", CallbackDescription);
	NotificationParameters.Insert("Owner", Owner);
	NotificationParameters.Insert("ReShowAuthorizationWindow", ReShowAuthorizationWindow);
	
	CallbackOnCompletion = New CallbackDescription(
		"TestConnectionCompletion",
		ThisObject,
		NotificationParameters);
	
	If TypeOf(Owner) = Type("ClientApplicationForm") Then
		UUID = Owner.UUID;
	Else
		UUID = Undefined;
	EndIf;
	
	TimeConsumingOperation = IntegrationWith1CDocumentManagementCoreServerCall.ConnectAndGetServiceVersionAsynchronously(
		NotificationParameters.AuthorizationSettings.UserName,
		NotificationParameters.AuthorizationSettings.Password,
		UUID,,
		AddressOfDocumentManagementWebService);
	ExecuteRequestAsynchronously(
		Owner,
		TimeConsumingOperation,
		CallbackOnCompletion,
		OutputIdleWindow,
		NStr("vi = 'Kết nối đến 1C:Document Management.';
			|ru = 'Подключение к 1С:Документооборот.';
			|en = 'Connect to 1C:Document Management.'; fa = 'Connect to 1C:Document Management.';
			|it = 'Подключение к 1С:Документооборот.';
			|pl = 'Connect to 1C:Document Management.';
			|tr = '1C:Document Management''e bağlantı.'"),
		HideInterface);
	
EndProcedure

// Called after the authorization window is closed. Calls the handler passed by the calling form.
//
// Parameters:
//   Result - Boolean - True if OK is pressed in the authorization window and the connection is successful.
//   Parameters - Structure:
//     Description of the announcement - The description of the announcement is the handler of the calling form.
//
Procedure CheckConnectionAfterAuthorizationWindow(Result, Parameters) Export
	
	If Result = True Then // Success, authorization settings are saved in the session settings.
		RunCallback(Parameters.CallbackDescription, True);
		
	Else // The connection failed, or the user refused the authorization attempt.
		IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings("0.0.0.0");
		RunCallback(Parameters.CallbackDescription, False);
	EndIf;
	
EndProcedure

// Gets a username and password to access 1C:Document management.
// In the web client, only the username is returned. Only the username is returned even
// when the settings were saved in the web client or on another computer the previous time.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement
//
Async Function ReadAuthorizationSettingsAsync() Export
	
	AuthorizationSettings =
		IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement();
	
	AuthorizationSettings.Password = Undefined;
	PartOfVIBPassword = Undefined;
	TempFileName = Undefined;
	
#If WebClient Then
	IntegrationWith1CDocumentManagementCoreServerCall.ReadAuthorizationSettings(
		AuthorizationSettings);
	AuthorizationSettings.PasswordIsSaved = False;
#Else
	IntegrationWith1CDocumentManagementCoreServerCall.ReadAuthorizationSettings(
		AuthorizationSettings,
		ComputerName(),
		PartOfVIBPassword,
		TempFileName);
#EndIf
	
	If AuthorizationSettings.OSAuthenticationIsUsed Or AuthorizationSettings.JWTAuthenticationIsUsed Then
		Return AuthorizationSettings;
		
	ElsIf AuthorizationSettings.PasswordIsSaved Then
#If Not WebClient Then
		TextDocument = New TextDocument;
		Try
			Await TextDocument.ReadAsync(TempFileName);
			SeparatedPassword = New Array;
			SeparatedPassword.Add(PartOfVIBPassword);
			SeparatedPassword.Add(TextDocument.GetText());
			AuthorizationSettings.Password =
				IntegrationWith1CDocumentManagementCoreClientServer.CollectPassword(SeparatedPassword);
			AuthorizationSettings.PasswordIsSaved = (AuthorizationSettings.Password <> Undefined);
		Except
			// The file has been deleted or corrupted.
			AuthorizationSettings.PasswordIsSaved = False;
			IntegrationWith1CDocumentManagementCoreServerCall.WriteWarning(
				NStr("vi = 'Không tìm thấy dữ liệu hoạt động đã lưu của người sử dụng 1C:Document Management';
					|ru = 'Не найдены сохраненные учетные данные пользователя 1С:Документооборота';
					|en = 'Saved accounting data of 1C:Document Management user is not found'; fa = 'Saved accounting data of 1C:Document Management user is not found';
					|it = 'Non sono stati trovati i dati di account salvati dall''utente di 1C:Document Management';
					|pl = 'Nie znaleziono zapisanych danych kont użytkownika 1C:Document Management';
					|tr = '1C:Document Management kullanıcısının kayıtlı bilgileri bulunamadı'"));
		EndTry;
		If AuthorizationSettings.PasswordIsSaved
				And IntegrationWith1CDocumentManagementCoreServerCall.ThisIsExchangeJobUser() Then
			IntegrationWith1CDocumentManagementCoreServerCall.SaveAuthorizationSettingsForExchange(
				AuthorizationSettings.UserName,
				AuthorizationSettings.Password);
		EndIf;
#EndIf
		
	Else
		// The password is not saved.
		// We will get the settings from the old shared settings repository, save them in the new one and delete them.
		IntegrationWith1CDocumentManagementCoreServerCall.ReadAuthorizationSettingsFromGeneralSettingsStore(
			AuthorizationSettings.UserName,
			AuthorizationSettings.Password,
			AuthorizationSettings.PasswordIsSaved);
		If AuthorizationSettings.UserName <> "" And AuthorizationSettings.PasswordIsSaved = True Then
			SaveAuthorizationSettings(AuthorizationSettings);
			If IntegrationWith1CDocumentManagementCoreServerCall.ThisIsExchangeJobUser() Then
				IntegrationWith1CDocumentManagementCoreServerCall.SaveAuthorizationSettingsForExchange(
					AuthorizationSettings.UserName,
					AuthorizationSettings.Password);
			EndIf;
#If Not WebClient Then
			// The password has not been saved in the web client, and the deletion is premature.
			IntegrationWith1CDocumentManagementCoreServerCall.DeleteAuthorizationSettingsFromGeneralSettingsStore();
#EndIf
		EndIf;
		
	EndIf;
	
	Return AuthorizationSettings;
	
EndFunction

// Opens the Form for creating a new IP object filled in based on the transmitted data.
// If the user interactively writes down the IP object, the link to the original DO object will be established automatically in
// the Form closing notification handler.
//
// Parameters:
//   FillingData - See IntegrationWith1CDocumentManagementCore.DataForFillingInIntegratedObject
//   Form - ClientApplicationForm - the shape of the object BEFORE or another form that requires notification.
//
Procedure CreateIntegratedObjectFromFillingData(FillingData, Form = Undefined) Export
	
	Basis = New Structure;
	For Each Item In FillingData Do
		Basis.Insert(Item.Key, Item.Value);
	EndDo;
	For Each Item In FillingData.AttributesValues Do
		Basis.Insert(Item.Key, Item.Value);
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("Basis", Basis);
	FormParameters.Insert("FillingValues", FillingData.AttributesValues);
	FormParameters.Insert("IntegrationWith1CDocumentManagement_ObjectTypeDM",
		FillingData.Object1CDocumentManagement.Type);
	FormParameters.Insert("IntegrationWith1CDocumentManagement_ObjectIdentifierDM",
		FillingData.Object1CDocumentManagement.ID);
	
	Uniqueness = New UUID();
	
	IntegrationWith1CDocumentManagementCoreServerCallOverridable.BeforeOpeningFormForCreatingNewIPObjectBasedOnObjectBEFORE(
		FillingData.FormName,
		FormParameters);
	
	ObjectForm = OpenForm(
		FillingData.FormName,
		FormParameters,
		Form,
		Uniqueness,,,,
		FormWindowOpeningMode.Independent);
	
	If ObjectForm = Undefined Then
		Info = StringFunctionsClient.FormattedString(
			StrTemplate(
				NStr("vi = 'Không thể điền đối tượng theo dữ liệu từ 1C:Document management.
					|Hãy kiểm tra <a href = ""%1"">quy tắc tích hợp</a>.';
					|ru = 'Не удалось заполнить объект по данным из 1С:Документооборот.
					|Проверьте <a href = ""%1"">правило интеграции</a>.';
					|en = 'Cannot fill the object by data from 1C:Document Management.
					|Check the <a href = ""%1"">integration rule</a>.'; fa = 'Cannot fill the object by data from 1C:Document Management.
					|Check the <a href = ""%1"">integration rule</a>.';
					|it = 'Не удалось заполнить объект по данным из 1С:Документооборот.
					|Проверьте <a href = ""%1"">правило интеграции</a>.';
					|pl = 'Cannot fill the object by data from 1C:Document Management.
					|Check the <a href = ""%1"">integration rule</a>.';
					|tr = '1C:Document Management üzerindeki veriler kullanılarak nesne doldurulamadı.
					|<a href = ""%1entegrasyon kuralını</a> kontrol edin.'"),
				GetURL(FillingData.IntegrationRule)));
		ShowMessageBox(, Info);
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Object1CDocumentManagement", FillingData.Object1CDocumentManagement);
	NotificationParameters.Insert("ObjectForm", ObjectForm);
	NotificationParameters.Insert("WhetherFilesAreAttached", FillingData.WhetherFilesAreAttached);
	NotificationParameters.Insert("TypeOfObjectToCreate", FillingData.TypeOfObjectToCreate);
	
	Notification = New CallbackDescription(
		"CreateIntegratedCompletionObject",
		IntegrationWith1CDocumentManagementCoreClient,
		NotificationParameters);
	
	ObjectForm.CallbackDescriptionOnClose = Notification;
	
EndProcedure

// Remembers the fact that the authorization window is displayed so as not to bother the user within the session anymore.
//
Procedure SaveAuthorizationOffered() Export
	
	If ApplicationParameters["IntegrationWith1CDocumentManagement.AuthorizationOffered"] = Undefined Then
		ApplicationParameters.Insert("IntegrationWith1CDocumentManagement.AuthorizationOffered", True);
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClientOverridable.WhenSavingAuthorizationOffer();
	
EndProcedure

// Saves the username and password to access 1C:Document management.
// Only the username is saved in the web client.
//
// Parameters:
//   AuthorizationSettings - See IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement
//
Async Procedure SaveAuthorizationSettings(Val AuthorizationSettings) Export
	
#If WebClient Then
	IntegrationWith1CDocumentManagementCoreServerCall.SaveAuthorizationSettings(
		AuthorizationSettings);
#Else
	NameOfOldTemporaryFile = Undefined;
	IntegrationWith1CDocumentManagementCoreServerCall.ReadAuthorizationSettings(
		IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement(),,,
		NameOfOldTemporaryFile); // We get the name of the old temporary file.
	If ValueIsFilled(NameOfOldTemporaryFile) Then
		File = New File(NameOfOldTemporaryFile);
		If Await File.ExistsAsync() Then
			Await File.SetReadOnlyAsync(False);
			Await DeleteFilesAsync(NameOfOldTemporaryFile);
		EndIf;
	EndIf;
	
	PartOfVIBPassword = "";
	TempFileName = "";
	
	If Not AuthorizationSettings.OSAuthenticationIsUsed
			And Not AuthorizationSettings.JWTAuthenticationIsUsed Then
		SeparatedPassword = IntegrationWith1CDocumentManagementCoreClientServer.SplitPassword(
			AuthorizationSettings.Password);
		
		PartOfVIBPassword = SeparatedPassword[0];
		TempFileName = GetTempFileName();
		
		// In a Windows Remote Desktop connection session, the temporary files directory can be a temporary
		// subdirectory created for the duration of the session. In this case, we will create a file in the user's shared directory.
		SharedFolderPosition = StrFind(Upper(TempFileName), "\TEMP\", SearchDirection.FromEnd);
		If SharedFolderPosition <> 0 Then
			PositionOfPenultimateSeparator = SharedFolderPosition + StrLen("\TEMP");
			PositionOfLastSeparator = StrFind(TempFileName, "\", SearchDirection.FromEnd);
			If PositionOfLastSeparator > PositionOfPenultimateSeparator Then
				TempFileName = Left(TempFileName, PositionOfPenultimateSeparator - 1)
					+ Mid(TempFileName, PositionOfLastSeparator);
			EndIf;
		EndIf;
		
		TextDocument = New TextDocument;
		TextDocument.AddLine(SeparatedPassword[1]);
		TextDocument.Write(TempFileName);
		File = New File(TempFileName);
		Await File.SetReadOnlyAsync(True);
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCall.SaveAuthorizationSettings(
		AuthorizationSettings,
		ComputerName(),
		PartOfVIBPassword,
		TempFileName);
#EndIf
	
EndProcedure

// Retrieves a link from the client application form to an object that integrates with the software.
//
// Parameters:
//   Form - ClientApplicationForm - the form in which the link is searched.
//   TypeOfIntegratedObject - Type - the type of link you want to find on the form.
//
// Returns:
//   AnyRef - reference to the object being integrated.
//
Function ReferenceToIntegratedObjectFromForm(Form, TypeOfIntegratedObject = Undefined) Export
	
	FormAttributeValues = IntegrationWith1CDocumentManagementCoreClientServer.FormOfIntegratedObject();
	FillPropertyValues(FormAttributeValues, Form);
	
	// If the method was called in the event of the Attachment form in the server
	// integrations1documentofunctionbase functionality.If you join the server, then the name of the Attribute containing
	// the object reference will be in the Attribute of the form requesite_name of the objectintegrated by Document Management.
	If Not ValueIsFilled(FormAttributeValues.NameOfAttributeOfObjectIntegratedWith1CDocumentManagement) Then
		// If the Attribute name is unknown, we will try to determine it. It can be specified in an overridden module.
		FormAttributeValues.NameOfAttributeOfObjectIntegratedWith1CDocumentManagement =
			IntegrationWith1CDocumentManagementCoreServerCall.NameOfAttributeOfObjectIntegratedWith1CDocumentManagement(
				FormAttributeValues,
				Undefined,
				TypeOfIntegratedObject);
	EndIf;
	
	Return IntegrationWith1CDocumentManagementCoreClientServer.ReferenceToIntegratedObjectFromForm(
		Form,
		FormAttributeValues.NameOfAttributeOfObjectIntegratedWith1CDocumentManagement,
		TypeOfIntegratedObject);
	
EndFunction

// Opens the integrated system metadata object selection form.
//
// Parameters:
//   ObjectTypeIS - String - The Cur type of the integrated system metadata object.
//   CallbackDescription - CallbackDescription - description of the alert being called.
//
Procedure ObjectTypeISStartChoice(ObjectTypeIS, CallbackDescription) Export
	
	FormParameter = New Structure;
	FormParameter.Insert("CurrentRow", ObjectTypeIS);
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectMetadataObject",
		FormParameter,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Called when opening related data forms BEFORE and sets the header according to the owner.
//
// Parameters:
//   Form - ClientApplicationFormExtensionForObjects - A Form whose title should be clarified from the owner:
//     * Title - String
//     * FormOwner - ClientApplicationForm:
//         ** Title - String
//
Procedure SetTitleWhenOpening(Form) Export
	
	If Form.Window = Undefined
			And TypeOf(Form.FormOwner) = Type("ClientApplicationForm")
			And ValueIsFilled(Form.FormOwner.Title) Then
		
		If ValueIsFilled(Form.Title) Then
			Form.Title = StrTemplate("%1 (%2)", Form.Title, Form.FormOwner.Title);
		Else
			Form.Title = Form.FormOwner.Title;
		EndIf;
		
	EndIf;
	
EndProcedure

// Saves an array of user settings an array of structures. It can be used for cases of a call from a client.
//
// Parameters:
//   StructuresArray - Array of Structure:
//     * Object - String
//     * Setting - String
//     * AutoRefresh - Boolean
//   NeedToRefreshCachedValues - Boolean - reused values need to be updated
//
Procedure CommonSettingsStorageSaveArray(StructuresArray, NeedToRefreshCachedValues = False) Export
	
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreClientOverridable.WhenSavingUserSettings(
		StructuresArray,
		NeedToRefreshCachedValues,
		StandardProcessing);
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	GeneralPurposeModuleServerCall = CommonClient.CommonModule("CommonServerCall");
	GeneralPurposeModuleServerCall.CommonSettingsStorageSaveArray(
		StructuresArray,
		NeedToRefreshCachedValues);
	
EndProcedure

// Checks whether the passed string is an external or internal navigation link.
//
// Parameters:
//   String - String - navigation links.
//
// Returns:
//   Boolean - The result of the check.
//
Function IsURL(Val String) Export
	
	ProcessURL1(String);
	String = Lower(String);
	
	Return StrStartsWith(String, "e1c:")
		Or StrStartsWith(String, "e1cib/")
		Or StrStartsWith(String, "e1ccs/")
		Or (StrStartsWith(String, "http") And (StrFind(String, "#e1c") > 0));
	
EndFunction

#EndRegion

#Region Files

// Returns the files selected in the table, ignoring the file roles.
//
// Parameters:
//   CollectionFiles - FormDataCollection - a table or file tree.
//   SelectedRows - Array of Number - ids of the selected collection rows.
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
Function Selected_Files(CollectionFiles, SelectedRows) Export
	
	Selected_Files = New Array;
	
	For Each SelectedRow In SelectedRows Do
		Data = CollectionFiles.FindByID(SelectedRow);
		FileRoleID = Undefined;
		If Data.Property("FileRoleID") Then
			FileRoleID = Data.FileRoleID;
		EndIf;
		Type = "";
		If Data.Property("Type") Then
			Type = Data.Type;
		EndIf;
		If Type = "DMFile" Then
			FileData = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
				Data.Description,
				Data.ID,
				Type,
				Data.Extension,
				FileRoleID);
			Selected_Files.Add(FileData);
		EndIf;
	EndDo;
	
	Return Selected_Files;
	
EndFunction

// Starts adding a file from disk to the DO object associated with the specified IC object.
//
// Parameters:
//   FileOwner - AnyRef - the source of the Command, the IP object, is the owner of the files.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure AddFileFromDiskToICObject(FileOwner, FormUniqueID) Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("FileOwner", FileOwner);
	NotificationParameters.Insert("FormUniqueID", FormUniqueID);
	
	Notification = New CallbackDescription(
		"AddFileFromDiskToICObjectAfterSearchingForObjectDM",
		ThisObject,
		NotificationParameters);
	
	StartSearchingForARelatedObjectDM(FileOwner, Notification, True);
	
EndProcedure

// Finishes editing the file by putting it in BEFORE and removing the capture if necessary.
//
// Parameters:
//   ID - String - ID of the file BEFORE.
//   Description - String - the name of the file being edited.
//   Extension - String - the extension of the file being edited.
//   FormUniqueID - UUID - ID of the calling form.
//   CallbackDescriptionOnCompletion - CallbackDescription - optional, called on successful completion.
//   OwnerID - String - ID of the file owner.
//
Async Procedure EndFileEditing(Val ID, Val Description, Val Extension,
		Val FormUniqueID, Val CallbackDescriptionOnCompletion = Undefined,
		Val OwnerID = "") Export
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Description,
		ID,
		"DMFile",
		Extension);
	
	Parameters = New Structure;
	Parameters.Insert("CurrentFile", CurrentFile);
	Parameters.Insert("OwnerID", OwnerID);
	Parameters.Insert("FormUniqueID", FormUniqueID);
	Parameters.Insert("CallbackDescription", CallbackDescriptionOnCompletion);
	
	If Not Await FileSystemExtensionAttached1Async() Then
		CallbackDescription = New CallbackDescription(
			"FinishEditingWithoutExpandingAfterPlacement",
			IntegrationWith1CDocumentManagementCoreClient,
			Parameters);
		Try
			ImportParameters = FileSystemClient.FileImportParameters();
			ImportParameters.FormIdentifier = FormUniqueID;
			FileSystemClient.ImportFile_(
				CallbackDescription,
				ImportParameters);
		Except
			WarningText = StrTemplate(
				NStr("vi = 'Không thể lưu các thay đổi do nguyên nhân:
					|%1';
					|ru = 'Не удалось сохранить изменения по причине:
					|%1';
					|en = 'Cannot save changes due to:
					|%1'; fa = 'Cannot save changes due to:
					|%1';
					|it = 'Non è stato possibile salvare le modifiche a causa di:
					|%1';
					|pl = 'Nie udało się zapisać zmiany z powodu:
					|%1';
					|tr = 'Bu nedenlerle değişiklikler kaydedilemedi:
					|%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			ShowMessageBox(, WarningText);
		EndTry;
		Return;
	EndIf;
	
	EditingInformation =
		IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile(
			ID,
			"DMFile");
	Parameters.Insert("EditingInformation", EditingInformation);
	
	// Let's check if it is possible to perform the operation at all (the situation could have changed on the side BEFORE).
	If Not EditingInformation.Saved_ Or EditingInformation.ForReading Then
		Response = Await ShowQuestionYesNoAsync(NStr("vi = 'Không tìm thấy tệp trong thư mục làm việc. Giải phóng tệp?';
													|ru = 'Файл не найден в рабочем каталоге. Освободить его?';
													|en = 'File is not found in the working directory. Unlock the file?'; fa = 'File is not found in the working directory. Unlock the file?';
													|it = 'Файл не найден в рабочем каталоге. Освободить его?';
													|pl = 'Nie znaleziono pliku w roboczym katalogu. Zwolnić go?';
													|tr = 'Dosya çalışma klasöründe bulunamadı. Serbest bırak?'"));
		If Response = DialogReturnCode.Yes Then
			FinishEditingWithExtensionAfterReleaseQuestion(Parameters);
		EndIf;
		Return;
	EndIf;
	
	// Let's check if the file exists in the specified location.
	File = New File(EditingInformation.FullPath);
	Parameters.Insert("File", File);
	If Not Await File.ExistsAsync() Then
		Response = Await ShowQuestionYesNoAsync(NStr("vi = 'Không tìm thấy tệp trong thư mục làm việc. Giải phóng tệp?';
													|ru = 'Файл не найден в рабочем каталоге. Освободить его?';
													|en = 'File is not found in the working directory. Unlock the file?'; fa = 'File is not found in the working directory. Unlock the file?';
													|it = 'Файл не найден в рабочем каталоге. Освободить его?';
													|pl = 'Nie znaleziono pliku w roboczym katalogu. Zwolnić go?';
													|tr = 'Dosya çalışma klasöründe bulunamadı. Serbest bırak?'"));
		If Response = DialogReturnCode.Yes Then
			FinishEditingWithExtensionAfterReleaseQuestion(Parameters);
		EndIf;
		Return;
	EndIf;
	
	Parameters.CurrentFile.Size = Await File.SizeAsync();
	Parameters.CurrentFile.ModificationDate = Await File.GetModificationTimeAsync();
	Parameters.CurrentFile.UniversalModificationDate = Await File.GetModificationUniversalTimeAsync();
	
	// Everything is fine, we will put the file in BEFORE and release it.
	ExplanationText = StrTemplate(NStr("vi = 'Đang lưu lại tệp ""%1"" (%2). Xin vui lòng đợi...';
										|ru = 'Идет сохранение файла ""%1"" (%2). Пожалуйста, подождите...';
										|en = 'Saving the ""%1"" file (%2). Please wait...'; fa = 'Saving the ""%1"" file (%2). Please wait...';
										|it = 'Salvataggio del file ""%1"" (%2). Attendere...';
										|pl = 'Trwa zapisywanie pliku ""%1"" (%2). Proszę czekać...';
										|tr = 'Dosya kaydediliyor ""%1"" (%2). Lütfen bekleyin...'"),
		EditingInformation.FullPath,
		IntegrationWith1CDocumentManagementCoreClientServer.BriefSizePresentation(
			Parameters.CurrentFile.Size));
	Status(ExplanationText);
	
	NotificationAfterPlacingFile = New CallbackDescription(
		"FinishEditingWithExtensionAfterPlacement",
		IntegrationWith1CDocumentManagementCoreClient,
		Parameters);
	Parameters.Insert("NotificationAfterPlacingFile", NotificationAfterPlacingFile);
	
	If EditingInformation.Property("VersionComment") Then
		NotificationAfterEnteringComment = New CallbackDescription(
			"AfterEnteringDescriptionOfChangesMade",
			IntegrationWith1CDocumentManagementCoreClient,
			Parameters);
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SaveFileToInfobaseForm",,,,,,
			NotificationAfterEnteringComment,
			FormWindowOpeningMode.LockWholeInterface);
	Else
		AfterEnteringDescriptionOfChangesMade(DialogReturnCode.OK, Parameters);
	EndIf;
	
EndProcedure

// Extracts text from a file and returns it as a string.
//
// Parameters:
//   FullFileName - String - full file name.
//
// Returns:
//   String - The extracted text.
//
Async Function ExtractText1Async(Val FullFileName) Export
	
	ExtractedText = "";
	
	Try
		File = New File(FullFileName);
		If Not Await File.ExistsAsync() Then
			Return ExtractedText;
		EndIf;
	Except
		Return ExtractedText;
	EndTry;
	
	Dismiss = False;
	Cancel = False;
	
	CommonSettings = StandardSubsystemsClient.ClientRunParameters().CommonFilesOperationsSettings;
	
#If Not WebClient And Not MobileClient Then
	
	FileNameExtension = CommonClientServer.GetFileNameExtension(FullFileName);
	
	FileExtensionInList = IntegrationWith1CDocumentManagementCoreClientServer.FileExtensionInList(
		CommonSettings.TextFilesExtensionsList,
		FileNameExtension);
	
	If FileExtensionInList Then
		Return IntegrationWith1CDocumentManagementCoreClientServer.ExtractTextFromTextFile(
			FullFileName,
			Undefined,
			Cancel);
	EndIf;
	
	Try
		Extracting = New TextExtraction(FullFileName);
		ExtractedText = Extracting.GetText();
	Except
		// When there is no one to extract the text, an exception is not required. This is a normal case.
		ExtractedText = "";
		Dismiss = True;
	EndTry;
	
#EndIf
	
	If IsBlankString(ExtractedText) Then
		
		FileNameExtension = CommonClientServer.GetFileNameExtension(FullFileName);
		
		FileExtensionInList = IntegrationWith1CDocumentManagementCoreClientServer.FileExtensionInList(
			CommonSettings.FilesExtensionsListOpenDocument,
			FileNameExtension);
		
		If FileExtensionInList Then
			Return IntegrationWith1CDocumentManagementCoreClientServer.ExtractOpenDocumentText(
				FullFileName,
				Cancel);
		EndIf;
		
	EndIf;
	
	If Dismiss Then
		Cancel = True;
	EndIf;
	
	Return ExtractedText;
	
EndFunction

// Gets the index of the file icon - the index in the image of the collection of pictogram files.
//
// Parameters:
//   Extension - String - file extension.
//   DeletionMark - Boolean - the file is marked for deletion.
//
// Returns:
//   Number
//
Function IndexOfFileIcon(Extension, DeletionMark = False) Export
	
	PictureIndex = IntegrationWith1CDocumentManagementCoreClientServer.IndexOfFileIcon(Extension);
	
	If DeletionMark Then
		PictureIndex = PictureIndex + 1;
	EndIf;
	
	Return PictureIndex;
	
EndFunction

// At the end of signing, it creates a notification about signing the file.
//
// Parameters:
//   FileOperation - See IntegrationWith1CDocumentManagementCoreClientServer.FileOperation
//   FileName - String - the name of the file to output to the message.
//   FileID - String - ID of the workflow file.
//   FileOwner - String - ID of the file owner.
//   MessageText - String - State text.
//   NotifyDocumentCard - Boolean - whether it is necessary to call the notification processing in the document card.
//     For example, if the change occurred in the file card, you need to call an alert in the document card.
//     If, for example, there is a group signing of 10 files from the document card itself
//     , you don't need to call an alert in the document card 10 additional times.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure InformAboutFileChanges(FileOperation, FileName, FileID, FileOwner,
		MessageText = "", NotifyDocumentCard = True, FormUniqueID = Undefined) Export
	
	NotificationSettingsRecordFile = New Structure;
	NotificationSettingsRecordFile.Insert("FileOperation", FileOperation);
	NotificationSettingsRecordFile.Insert("FileName", FileName);
	NotificationSettingsRecordFile.Insert("FileID", FileID);
	NotificationSettingsRecordFile.Insert("FileOwner", FileOwner);
	NotificationSettingsRecordFile.Insert("NotifyDocumentCard", NotifyDocumentCard);
	NotificationSettingsRecordFile.Insert("FormUniqueID", FormUniqueID);
	Notify("Recording_1CDocumentManagementFile", NotificationSettingsRecordFile);
	
	If ValueIsFilled(MessageText) Then
		Status(MessageText);
	EndIf;
	
EndProcedure

// Checks whether 1C is being used:Workflow for storing object files.
//
// Parameters:
//   Form - ClientApplicationForm - form of the file owner.
//   Command - FormCommand - the Command to manage attached files that is being executed.
//   AttachedFilesOwner - AnyRef - owner of the attached files.
//
// Returns:
//   Boolean
//
Function UseEDIToStoreObjectFiles(Form, Command, AttachedFilesOwner) Export
	
	UseEDIToStoreObjectFiles = False;
	
	FormParameters = New Structure("UseAttachedFiles1CDocumentManagement", Undefined);
	FillPropertyValues(FormParameters, Form);
	
	If FormParameters.UseAttachedFiles1CDocumentManagement = True Then
		UseEDIToStoreObjectFiles =
			IntegrationWith1CDocumentManagementCoreServerCall.Use1CDocumentManagementAttachedFilesForTheObject(
				AttachedFilesOwner);
	EndIf;
	
	Return UseEDIToStoreObjectFiles;
	
EndFunction

// Sends files for printing.
//
// Parameters:
//   CollectionFiles - FormDataCollection - a table or file tree.
//                  - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//   SelectedRows - Array of Number - ids of the selected collection rows.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure PrintFiles(CollectionFiles, SelectedRows, FormUniqueID) Export
	
	If TypeOf(CollectionFiles) = Type("Array") Then
		Selected_Files = CollectionFiles;
	Else
		Selected_Files = Selected_Files(CollectionFiles, SelectedRows);
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"PrintFilesAfterReceiving",
		IntegrationWith1CDocumentManagementCoreClient);
	
	GetFilesAndContinue(
		Selected_Files,
		FormUniqueID,
		CallbackDescription);
	
EndProcedure

// Starts saving the selected files.
//
// Parameters:
//   CollectionFiles - FormDataCollection - a table of files with columns ID, Name, Extension.
//   SelectedRows - Array of Number - ids of the selected collection rows.
//   FormUniqueID - UUID - ID of the calling form.
//   CallbackDescription - CallbackDescription - optional, a handler called with passing the file name
//     after saving it.
//
Procedure StartSavingSelectedFiles(CollectionFiles, SelectedRows, FormUniqueID,
		CallbackDescription = Undefined) Export
	
	Selected_Files = Selected_Files(CollectionFiles, SelectedRows);
	
	If Selected_Files.Count() = 0 Then
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("RemainingFiles", New Array);
	Parameters.Insert("UseVisualizationOfItemInstanceStamp", True);
	For IndexOf = 0 To Selected_Files.UBound() Do
		If IndexOf = 0 Then
			Parameters.Insert("CurrentFile", Selected_Files[IndexOf]);
		Else
			Parameters.RemainingFiles.Add(Selected_Files[IndexOf]);
		EndIf;
	EndDo;
	Parameters.Insert("FormUniqueID", FormUniqueID);
	Parameters.Insert("CallbackDescription", CallbackDescription);
	
	SaveFilesAsStart(Parameters);
	
EndProcedure

// Checks whether it is possible to add only a scanned copy and asks the user a question.
//
// Parameters:
//   StateAllowsAddingScannedCopy - Boolean - you can add a scanned copy.
//   StateAllowsFileAddition - Boolean - you can add a file.
//
// Returns:
//   Promise - the result of fulfilling the promise of the code of return of the dialog.
//   The code of the return of the dialog
//
Function YouNeedToAddScannedCopyAsync(StateAllowsAddingScannedCopy,
		StateAllowsFileAddition) Export
	
	If StateAllowsAddingScannedCopy And Not StateAllowsFileAddition Then
		QueryText = NStr(
			"vi = 'Với trạng thái hiện tại chỉ có thể thêm bản sao scan của chứng từ. Tiếp tục?';
			|ru = 'В текущем состоянии можно добавить только скан-копию оригинала документа. Продолжить?';
			|en = 'In the current state, you can add only a scanned copy of the original document. Proceed?'; fa = 'In the current state, you can add only a scanned copy of the original document. Proceed?';
			|it = 'В текущем состоянии можно добавить только скан-копию оригинала документа. Продолжить?';
			|pl = 'W bieżącym statusie można dodać tylko kopie skanowaną dokumentu. Kontynuować?';
			|tr = 'Geçerli durumda, yalnızca orijinal belgenin taranmış kopyası eklenebilir. Devam et?'");
		QuestionParametersYesNo = QuestionParametersYesNo(DialogReturnCode.Yes);
		QuestionParametersYesNo.Title = NStr("vi = 'Thêm tệp';
											|ru = 'Добавление файла';
											|en = 'Adding the file'; fa = 'Adding the file';
											|it = 'Добавление файла';
											|pl = 'Dodawanie pliku';
											|tr = 'Dosya ekleme'");
		
		Return ShowQuestionYesNoAsync(
			QueryText,
			QuestionParametersYesNo);
	Else
		Return DialogReturnCode.Yes;
	EndIf;
	
EndFunction

// Updates the file TO from a file on disk.
//
// Parameters:
//   ID - String - ID of the file BEFORE.
//   Description - String - the name of the file being edited.
//   Extension - String - the extension of the file being edited.
//   ModificationDate - Date - date of modification of the file being edited. Local time.
//   FormUniqueID - UUID - ID of the calling form.
//   CallbackDescriptionOnCompletion - CallbackDescription - optional, called on successful completion.
//   OwnerID - String - ID of the file owner.
//
Async Procedure UpdateFromFileOnHardDrive(Val ID, Val Description, Val Extension, Val ModificationDate,
		Val FormUniqueID, Val CallbackDescriptionOnCompletion = Undefined,
		Val OwnerID = "") Export
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Description,
		ID,
		"DMFile",
		Extension);
	CurrentFile.ModificationDate = ModificationDate;
	
	Parameters = New Structure;
	Parameters.Insert("CurrentFile", CurrentFile);
	Parameters.Insert("OwnerID", OwnerID);
	Parameters.Insert("FormUniqueID", FormUniqueID);
	Parameters.Insert("CallbackDescription", CallbackDescriptionOnCompletion);
	Parameters.Insert("UnlockFile", False);
	Parameters.Insert("UpdateEditInformation", False);
	
	Filter = NStr("vi = 'Tệp (*.%1)|*.%1|Tất cả các tệp (*.*)|*.*';
					|ru = 'Файл (*.%1)|*.%1|Все файлы (*.*)|*.*';
					|en = 'File (*.%1)|*.%1|All files (*.*)|*.*'; fa = 'File (*.%1)|*.%1|All files (*.*)|*.*';
					|it = 'File (*.%1)|*.%1|Tutti i file (*.*)|*.*';
					|pl = 'Plik (*.%1)|*.%1|Wszystkie pliki (*.*)|*.*';
					|tr = 'Dosya (*.%1) | *.%1| Tüm dosyalar (*. *) | *. *'");
	DialogParameters = New PutFilesDialogParameters;
	DialogParameters.Filter = StrTemplate(Filter, Extension);
	
	If Not Await FileSystemExtensionAttached1Async() Then
		CallbackDescription = New CallbackDescription(
			"UpdateFromFileOnDiskAfterPlacingFileWithoutExtension",
			IntegrationWith1CDocumentManagementCoreClient,
			Parameters);
		Try
			BeginPutFileToServer(
				CallbackDescription,,,,
				DialogParameters,
				Parameters.FormUniqueID);
		Except
			WarningText = StrTemplate(
				NStr("vi = 'Không thể cập nhật tệp do nguyên nhân:
					|%1';
					|ru = 'Не удалось обновить файл по причине:
					|%1';
					|en = 'Cannot update file because:
					|%1'; fa = 'Cannot update file because:
					|%1';
					|it = 'Non è stato possibile aggiornare il file a causa di:
					|%1';
					|pl = 'Nie udało się zaktualizować pliku z powodu:
					|%1';
					|tr = 'Bu nedenle dosya güncellenemedi:
					|%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			ShowMessageBox(, WarningText);
		EndTry;
		Return;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreClientCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1") Then
		EditingInformation =
			IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile(
				ID,
				"DMFile");
		Parameters.Insert("EditingInformation", EditingInformation);
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"UpdateFromFileOnDiskAfterPlacingFileWithExtension",
		IntegrationWith1CDocumentManagementCoreClient,
		Parameters);
	Try
		BeginPutFileToServer(
			CallbackDescription,,,,
			DialogParameters,
			Parameters.FormUniqueID);
	Except
		WarningText = StrTemplate(
			NStr("vi = 'Không thể cập nhật tệp do nguyên nhân:
				|%1';
				|ru = 'Не удалось обновить файл по причине:
				|%1';
				|en = 'Cannot update file because:
				|%1'; fa = 'Cannot update file because:
				|%1';
				|it = 'Non è stato possibile aggiornare il file a causa di:
				|%1';
				|pl = 'Nie udało się zaktualizować pliku z powodu:
				|%1';
				|tr = 'Bu nedenle dosya güncellenemedi:
				|%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		ShowMessageBox(, WarningText);
	EndTry;
	
EndProcedure

// Opens the file version for viewing.
//
// Parameters:
//   ID - String - id of the version in UP to.
//   Description - String - the name of the version.
//   Extension - String - version extension.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure OpenFileVersion(ID, Description, Extension, FormUniqueID) Export
	
	FileVersionData = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Description,
		ID,
		"DMFileVersion",
		Extension);
	
	Parameters = New Structure("ForReading, FormUniqueID", True, FormUniqueID);
	CallbackDescription = New CallbackDescription(
		"OpenFilesAfterReceiving",
		IntegrationWith1CDocumentManagementCoreClient,
		Parameters);
	
	GetFilesAndContinue(
		CommonClientServer.ValueInArray(FileVersionData),
		FormUniqueID,
		CallbackDescription,
		True);
	
EndProcedure

// Opens the directory of the file in which it is saved for viewing or editing.
//
// Parameters:
//   ID - String - id of the file in UP to.
//
Async Procedure OpenFileDirectory(Val ID) Export
	
	If Not Await FileSystemExtensionAttached1Async() Then
		ShowMessageBox(, NStr("vi = 'Chỉ có thể mở thư mục tệp sau khi kết nối
			|phần mở rộng để làm việc với tệp.';
			|ru = 'Открывать каталог файла можно только после подключения
			|расширения для работы с файлами.';
			|en = 'You can open the file directory only after
			|1C:Enterprise Extension is attached.'; fa = 'You can open the file directory only after
			|1C:Enterprise Extension is attached.';
			|it = 'È possibile aprire la directory di file solo dopo la connessione
			|dell''estensione per il lavoro con i file.';
			|pl = 'Otwierać katalog pliku można tylko po połączenia 
			|rozszerzenia do pracy z plikami.';
			|tr = 'Dosya klasörünü yalnızca dosyalarla çalışmak için uzantıyı
			|bağladıktan sonra açabilir.'"));
		Return;
	EndIf;
	
	EditingInformation =
		IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile(
			ID,
			"DMFile");
	If EditingInformation.Saved_ Then
		File = New File(EditingInformation.FullPath);
		If Await File.ExistsAsync() Then
			FileSystemClient.OpenExplorer(EditingInformation.FullPath);
		Else
			ShowMessageBox(, NStr("vi = 'Không tìm thấy tệp trong thư mục làm việc.';
									|ru = 'Файл не найден в рабочем каталоге.';
									|en = 'File is not found in the working directory.'; fa = 'File is not found in the working directory.';
									|it = 'File non trovato nella directory di lavoro.';
									|pl = 'Nie znaleziono pliku w roboczym katalogu.';
									|tr = 'Dosya çalışma klasöründe bulunamadı.'"));
		EndIf;
	Else
		ShowMessageBox(, NStr("vi = 'Không tìm thấy tệp trong thư mục làm việc.';
								|ru = 'Файл не найден в рабочем каталоге.';
								|en = 'File is not found in the working directory.'; fa = 'File is not found in the working directory.';
								|it = 'File non trovato nella directory di lavoro.';
								|pl = 'Nie znaleziono pliku w roboczym katalogu.';
								|tr = 'Dosya çalışma klasöründe bulunamadı.'"));
		Return;
	EndIf;
	
EndProcedure

// Opens the file for viewing or editing.
//
// Parameters:
//   ID - String - id of the file in UP to.
//   Description - String - file name.
//   Extension - String - file extension.
//   FormUniqueID - UUID - ID of the calling form.
//   ForReading - Boolean - True if the file is opened for reading, and False if for editing.
//   CallbackDescriptionOnCompletion - CallbackDescription - called when the file is opened successfully.
//   OwnerID - String - ID of the file owner.
//
Procedure OpenFile(ID, Description, Extension, FormUniqueID,
		ForReading = True, CallbackDescriptionOnCompletion = Undefined, OwnerID = "") Export
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Description,
		ID,
		"DMFile",
		Extension);
	
	Parameters = New Structure;
	Parameters.Insert("CurrentFile", CurrentFile);
	Parameters.Insert("OwnerID", OwnerID);
	Parameters.Insert("ForReading", ForReading);
	Parameters.Insert("CallbackDescriptionOnCompletion", CallbackDescriptionOnCompletion);
	Parameters.Insert("FormUniqueID", FormUniqueID);
	CallbackDescription = New CallbackDescription(
		"OpenFilesAfterReceiving",
		IntegrationWith1CDocumentManagementCoreClient,
		Parameters);
	
	GetFilesAndContinue(
		CommonClientServer.ValueInArray(CurrentFile),
		FormUniqueID,
		CallbackDescription,
		ForReading);
	
EndProcedure

// Opens the file received from BEFORE for viewing.
//
// Parameters:
//   FileAddress - String - the address in the temporary storage where the file data is placed.
//   Description - String - file name.
//   Extension - String - file extension.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure OpenReceivedFile(FileAddress, Description, Extension, FormUniqueID) Export
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Description,
		"",
		"",
		Extension);
	CurrentFile.RefToBinaryFileData = FileAddress;
	
	Parameters = New Structure;
	Parameters.Insert("CurrentFile", CurrentFile);
	Parameters.Insert("OwnerID", "");
	Parameters.Insert("ForReading", True);
	Parameters.Insert("CallbackDescriptionOnCompletion", Undefined);
	Parameters.Insert("FormUniqueID", FormUniqueID);
	CallbackDescription = New CallbackDescription(
		"OpenFilesAfterReceiving",
		IntegrationWith1CDocumentManagementCoreClient,
		Parameters);
	
	GetFilesAndContinue(
		CommonClientServer.ValueInArray(CurrentFile),
		FormUniqueID,
		CallbackDescription,
		True);
	
EndProcedure

// Opens the list of files attached to the IC object.
//
// Parameters:
//   FileOwner - AnyRef - the source of the Command, the IP object, is the owner of the files.
//   OpeningParameters - See IntegrationWith1CDocumentManagementCoreClient.OptionsForOpeningListOfFiles
//
Procedure OpenFormAttachedFiles(FileOwner, OpeningParameters = Undefined) Export
	
	If OpeningParameters = Undefined Then
		OpeningParameters = OptionsForOpeningListOfFiles();
	EndIf;
	
	BeforeExecutingCommand(OpeningParameters.FormOwner);
	
	If FileOwner = Undefined Then
		
		OpenAttachedFilesCompletion(FileOwner, OpeningParameters);
		
	Else
		
		ContinueNotification = New CallbackDescription(
			"OpenAttachedFilesCompletion",
			IntegrationWith1CDocumentManagementCoreClient,
			OpeningParameters);
		PerformRecordCheckAndContinue(
			FileOwner,
			OpeningParameters.FormOwner,
			ContinueNotification,
			NStr("vi = 'Tệp đính kèm';
				|ru = 'Присоединенные файлы';
				|en = 'Attachments'; fa = 'پیوست‌ها';
				|it = 'Присоединенные файлы';
				|pl = 'Załączone pliki';
				|tr = 'Ekli dosyalar'"));
		
	EndIf;
	
EndProcedure

// Opens the Form of the list of files stored in the IP database.
// An analogue of the BSP method is workfailamiclient.Open the File successform, which forcibly shows the files
// stored in the IP database.
//
// Parameters:
//   FilesOwner - DefinedType.AttachedFilesOwner - the file folder or object
//     that the selected files are attached to.
//   FormParameters - See FilesOperationsClient.FileListFormOpeningParameters
//   FormOwner - ClientApplicationForm, Undefined - the form from which the command is called.
//   ClosingNotification1 - CallbackDescription - contains a description of the procedure that will be called when the form is closed.
//
Procedure OpenBSPFileListForm(Val FilesOwner, Val FormParameters = Undefined,
		FormOwner = Undefined, ClosingNotification1 = Undefined) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		Return;
	EndIf;
	
	If FormParameters = Undefined Then
		SSLVersion = StandardSubsystemsServerCall.LibraryVersion();
		If CommonClientServer.CompareVersions(SSLVersion, "3.1.11.142") > 0 Then
			ModuleFilesOperationsClient = CommonClient.CommonModule("FilesOperationsClient");
			FormParameters = ModuleFilesOperationsClient.FileListFormOpeningParameters(FilesOwner);
		Else
			FormParameters = New Structure("FileOwner", FilesOwner);
		EndIf;
	EndIf;
	
	FormName = "DataProcessor.FilesOperations.Form.AttachedFiles";
	OpenForm(FormName, FormParameters, FormOwner,,,, ClosingNotification1);
	
EndProcedure

// Cancels editing of a previously captured file.
//
// Parameters:
//   ID - String - id of the file in UP to.
//   CallbackDescriptionOnCompletion - CallbackDescription - optional parameter, description of the alert
//     that is called after cancellation.
//   OwnerID - String - ID of the file owner.
//   FormUniqueID - UUID - ID of the calling form.
//
Async Procedure UndoFileEditing(Val ID, Val CallbackDescriptionOnCompletion = Undefined,
		Val OwnerID = "", Val FormUniqueID = Undefined) Export
	
	Response = Await ShowQuestionYesNoAsync(
		NStr("vi = 'Việc hủy soạn tệp có thể làm mất các thay đổi. Tiếp tục?';
			|ru = 'Отмена редактирования файла может привести к потере изменений. Продолжить?';
			|en = 'If you cancel file editing, the changes will be lost. Continue?'; fa = 'If you cancel file editing, the changes will be lost. Continue?';
			|it = 'Отмена редактирования файла может привести к потере изменений. Продолжить?';
			|pl = 'Anulowanie edycji pliku może spowodować utratę zmian. Kontynuować?';
			|tr = 'Dosya düzenlemeyi iptal etmek, değişikliklerin kaybolmasına neden olabilir. Devam et?'"));
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Undefined,
		ID,
		"DMFile",
		Undefined);
	
	IntegrationWith1CDocumentManagementCoreServerCall.UnlockFile(CurrentFile.ID);
	If Await FileSystemExtensionAttached1Async() Then
		EditingInformation =
			IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile(
				CurrentFile.ID,
				"DMFile");
		If EditingInformation.Saved_ And Not EditingInformation.ForReading Then
			File = New File(EditingInformation.FullPath);
			If Await File.ExistsAsync() Then
				If Not Await File.GetReadOnlyAsync() Then
					Await File.SetReadOnlyAsync(True);
				EndIf;
				EditingInformation.ForReading = True;
				EditingInformation.Size = Await File.SizeAsync();
				EditingInformation.UniversalModificationDate = Await File.GetModificationUniversalTimeAsync();
			Else
				EditingInformation.Saved_ = False;
			EndIf;
			IntegrationWith1CDocumentManagementCoreServerCall.SaveFileEditingInformation(
				EditingInformation);
		EndIf;
	EndIf;
	
	MessageText = StrTemplate(NStr("vi = 'Tệp %1 đã được giải phóng.';
									|ru = 'Файл %1 освобожден.';
									|en = 'The %1 file is unlocked.'; fa = 'The %1 file is unlocked.';
									|it = 'Файл %1 освобожден.';
									|pl = 'The %1 file is unlocked.';
									|tr = 'Dosya %1 kilidi açıldı.'"), CurrentFile.Description);
	FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
	FileOperation.FileEditingIsComplete = True;
	FileOperation.InformFormOfFile = True;
	FileOperation.InformFileListForm = True;
	InformAboutFileChanges(
		FileOperation,
		CurrentFile.Description,
		CurrentFile.ID,
		OwnerID,
		MessageText,,
		FormUniqueID);
	
	If CallbackDescriptionOnCompletion <> Undefined Then
		RunCallback(CallbackDescriptionOnCompletion, CurrentFile);
	EndIf;
	
EndProcedure

// Constructor of the parameter structure to start creating a file.
//
// Parameters:
//   FileRoleID - String, Undefined - the role of the file.
//
// Returns:
//   Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * OwnerID - String - ID of the file owner in the Document Flow.
//     * OwnerType - String - the XDTO type of the file owner in the Document Flow.
//     * FormUniqueID - UUID, Undefined - ID of the calling form.
//     * OwnerPresentation - String - representation of the file owner.
//     * Owner - AnyRef, Undefined - file owner.
//     * IsScannedCopy - Boolean - a sign of a scanned copy.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//     * FullFileNames - Array of String - the names of the added files.
//     * PlacedFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
Function FileCreationStartParameters(FileRoleID = Undefined) Export
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Undefined,
		Undefined,
		"DMFile",
		Undefined,
		FileRoleID);
	
	ParametersForStartOfCreation = New Structure("CurrentFile", CurrentFile);
	ParametersForStartOfCreation.Insert("OwnerID", "");
	ParametersForStartOfCreation.Insert("OwnerType", "");
	ParametersForStartOfCreation.Insert("FormUniqueID", Undefined);
	ParametersForStartOfCreation.Insert("OwnerPresentation", "");
	ParametersForStartOfCreation.Insert("Owner", Undefined);
	ParametersForStartOfCreation.Insert("IsScannedCopy", False);
	ParametersForStartOfCreation.Insert("CallbackDescription", Undefined);
	ParametersForStartOfCreation.Insert("FullFileNames", New Array);
	ParametersForStartOfCreation.Insert("PlacedFiles", New Array);
	
	Return ParametersForStartOfCreation;
	
EndFunction

// Constructor of the structure of parameters for opening a list of files.
//
// Parameters:
//   FormOwner - ClientApplicationForm, Undefined - the form from which the command is called.
//
// Returns:
//   Structure:
//     * FormOwner - ClientApplicationForm, Undefined - the form from which the command is called.
//     * ReadOnly - Boolean - the mode of opening the form.
//     * CurrentFile - String - id of the Cur file to position the list on.
//     * Uniqueness - Arbitrary, Undefined - the uniqueness key with which the file Form should be opened.
//     * Window - ClientApplicationWindow, Undefined - optional parameter, owner form window.
//     * IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement
//                         - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - a suitable integration rule.
//                         - Undefined - if the integration rule is not set.
//     * FileOwnerID - String - ID of the DO object that owns the file.
//     * FileOwnerType - String - the type of the BEFORE object that owns the file.
//     * OwnerPresentation - String - Presentation of the object BEFORE, which is the owner of the file.
//
Function OptionsForOpeningListOfFiles(FormOwner = Undefined) Export
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("FormOwner", FormOwner);
	If FormOwner = Undefined Then
		ReadOnly = False;
	Else
		ReadOnly = FormOwner.ReadOnly;
	EndIf;
	OpeningParameters.Insert("ReadOnly", ReadOnly);
	OpeningParameters.Insert("CurrentFile", "");
	OpeningParameters.Insert("Uniqueness", Undefined);
	OpeningParameters.Insert("Window", Undefined);
	OpeningParameters.Insert("IntegrationRule", Undefined);
	OpeningParameters.Insert("FileOwnerID", "");
	OpeningParameters.Insert("FileOwnerType", "");
	OpeningParameters.Insert("OwnerPresentation", "");
	
	Return OpeningParameters;
	
EndFunction

// Returns a filter with the sets of the most frequent file extensions.
//
// Returns:
//   String
//
Function GetFilterForFileSelectionDialog() Export
	
	Filter = NStr("vi = 'Tất cả tệp (*.*)|*.*';
					|ru = 'Все файлы (*.*)|*.*';
					|en = 'All files (*.*)|*.*'; fa = 'All files (*.*)|*.*';
					|it = 'Все файлы (*.*)|*.*';
					|pl = 'Wszystkie pliki (*.*)|*.*';
					|tr = 'Tüm dosyalar (*.*)|*.*'")
		+ NStr("vi = '|Văn bản MS Office(*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx)|*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx';
				|ru = '|Документы MS Office(*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx)|*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx';
				|en = '|MS Office documents(*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx)|*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx'; fa = '|MS Office documents(*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx)|*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx';
				|it = '|Документы MS Office(*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx)|*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx';
				|pl = '|MS Office documents(*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx)|*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx';
				|tr = '| MS Office belgeleri (*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx)|*.doc;*.docx;*.xls;*.xlsx;*.ppt;*.pptx'")
		+ NStr("vi = '|Văn bản Open Office(*.odt;*.odf;*.ods;*.odp)|*.odt;*.odf;*.ods;*.odp';
				|ru = '|Документы Open Office(*.odt;*.odf;*.ods;*.odp)|*.odt;*.odf;*.ods;*.odp';
				|en = '|Open Office documents(*.odt;*.odf;*.ods;*.odp)|*.odt;*.odf;*.ods;*.odp'; fa = '|Open Office documents(*.odt;*.odf;*.ods;*.odp)|*.odt;*.odf;*.ods;*.odp';
				|it = '|Документы Open Office(*.odt;*.odf;*.ods;*.odp)|*.odt;*.odf;*.ods;*.odp';
				|pl = '|Open Office documents(*.odt;*.odf;*.ods;*.odp)|*.odt;*.odf;*.ods;*.odp';
				|tr = '| Open Office belgeleri (*.odt;*.odf;*.ods;*.odp)|*.odt;*.odf;*.ods;*.odp'")
		+ NStr("vi = '|Tệp văn bản(*.txt)|*.txt';
				|ru = '|Текстовые файлы(*.txt)|*.txt';
				|en = '|Text files(*.txt)|*.txt'; fa = '|Text files(*.txt)|*.txt';
				|it = '|Текстовые файлы(*.txt)|*.txt';
				|pl = '|Text files(*.txt)|*.txt';
				|tr = '| Metin dosyaları (*.txt)|*.txt'")
		+ NStr("vi = '|Tệp PDF(*.pdf)|*.pdf';
				|ru = '|Файлы PDF(*.pdf)|*.pdf';
				|en = '|PDF files(*.pdf)|*.pdf'; fa = '|PDF files(*.pdf)|*.pdf';
				|it = '|Файлы PDF(*.pdf)|*.pdf';
				|pl = '|PDF files(*.pdf)|*.pdf';
				|tr = '| PDF dosyaları (*.pdf)|*.pdf'")
		+ NStr("vi = '|Tệp HTML(*.htm;*.html)|*.htm;*.html';
				|ru = '|Файлы HTML(*.htm;*.html)|*.htm;*.html';
				|en = '|HTML files(*.htm;*.html)|*.htm;*.html'; fa = '|HTML files(*.htm;*.html)|*.htm;*.html';
				|it = '|Файлы HTML(*.htm;*.html)|*.htm;*.html';
				|pl = '|HTML files(*.htm;*.html)|*.htm;*.html';
				|tr = '| HTML dosyaları (*.htm;*.html)|*.htm;*.html'")
		+ NStr("vi = '|Hình vẽ (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf';
				|ru = '|Картинки (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf';
				|en = '|Images (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf'; fa = '|Images (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf';
				|it = '|Картинки (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf';
				|pl = '|Images (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf';
				|tr = 'Resimler (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf'");
	
	Return Filter;
	
EndFunction

// Changes the file deletion tag.
//
// Parameters:
//   Selected_Files - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//   CurrentDeletionMark - Boolean - the Cur value of the file deletion mark that needs
//     to be changed to the opposite.
//   CallbackDescriptionOnCompletion - CallbackDescription - optional parameter, description of the alert
//     that is called after cancellation.
//   OwnerID - String - ID of the file owner.
//   FormUniqueID - UUID - ID of the calling form.
//
Async Procedure MarkForDeletionUncheckFiles(Val Selected_Files, Val CurrentDeletionMark,
		Val CallbackDescriptionOnCompletion = Undefined, Val OwnerID = "",
		Val FormUniqueID = Undefined) Export
	
	SelectedFilesQuantity = Selected_Files.Count();
	
	QueryText = "";
	If SelectedFilesQuantity = 0 Then
		Return;
		
	ElsIf SelectedFilesQuantity = 1 Then
		If CurrentDeletionMark = True Then
			TemplateText = NStr("vi = 'Bỏ dấu xóa ""%1""?';
								|ru = 'Снять с ""%1"" пометку на удаление?';
								|en = 'Do you want to clear the deletion mark for ""%1""?'; fa = 'Do you want to clear the deletion mark for ""%1""?';
								|it = 'Снять с ""%1"" пометку на удаление?';
								|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
								|tr = '""%1"" için silme işareti kaldırılsın mı?'");
		Else
			TemplateText = NStr("vi = 'Đặt dấu xóa ""%1""?';
								|ru = 'Пометить ""%1"" на удаление?';
								|en = 'Do you want to mark ""%1"" for deletion?'; fa = 'Do you want to mark ""%1"" for deletion?';
								|it = 'Пометить ""%1"" на удаление?';
								|pl = 'Zaznaczyć ""%1"" do usunięcia?';
								|tr = '""%1"" silinmek üzere işaretlensin mi?'");
		EndIf;
		QueryText = StrTemplate(TemplateText, Selected_Files[0].Description);
		
	Else
		If CurrentDeletionMark = True Then
			QueryText = NStr("vi = 'Bỏ dấu xóa các tệp đã chọn?';
							|ru = 'Снять с выделенных файлов пометку на удаление?';
							|en = 'Unmark selected files for deletion?'; fa = 'Unmark selected files for deletion?';
							|it = 'Rimuovere il contrassegno di eliminazione dai file evidenziati?';
							|pl = 'Usunąć z wybranych plików zaznaczenie do usunięcia?';
							|tr = 'Silinmek üzere seçili dosyaların işareti kaldırılsın mı?'");
		Else
			QueryText = NStr("vi = 'Đặt dấu xóa các tệp đã chọn?';
							|ru = 'Пометить выделенные файлы на удаление?';
							|en = 'Mark selected files for deletion?'; fa = 'Mark selected files for deletion?';
							|it = 'Contrassegnare i file evidenziati per l''eliminazione?';
							|pl = 'Zaznaczyć wybrane pliki do usunięcia?';
							|tr = 'Seçilen dosyalar silinmek üzere işaretlensin mi?'");
		EndIf;
		
	EndIf;
	
	Response = Await ShowQuestionYesNoAsync(QueryText);
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCall.MarkForDeletionUncheckItems(
		Selected_Files);
	
	For Each File In Selected_Files Do
		MessageText = StrTemplate(NStr("vi = 'Tệp %1 đã bị xóa.';
										|ru = 'Файл %1 удален.';
										|en = 'The %1 file is deleted.'; fa = 'The %1 file is deleted.';
										|it = 'Файл %1 удален.';
										|pl = 'The %1 file is deleted.';
										|tr = 'Dosya %1 silindi.'"), File.Description);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.DeleteFile = True;
		FileOperation.InformFormOfFile = True;
		InformAboutFileChanges(
			FileOperation,
			File.Description,
			File.ID,
			OwnerID,
			MessageText,,
			FormUniqueID);
	EndDo;
	If TypeOf(File) = Type("Structure") Then
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.DeleteFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			File.Description,
			File.ID,
			OwnerID,,,
			FormUniqueID);
	EndIf;
	
	If CallbackDescriptionOnCompletion <> Undefined Then
		RunCallback(CallbackDescriptionOnCompletion, Selected_Files);
	EndIf;
	
EndProcedure

// Decomposes the full file name into its components.
//
// Parameters:
//   FullFileName - String - full path to the file.
//   Is_Directory - Boolean - indicates that you want to decompose the full name of the folder, not the file.
//
// Returns:
//   See CommonClientServer.ParseFullFileName
//
Function ParseFullFileName(Val FullFileName, Is_Directory = False) Export
	
	FileNameStructure = CommonClientServer.ParseFullFileName(FullFileName, Is_Directory);
	
	IntegrationWith1CDocumentManagementCoreClientOverridable.WhenDecomposingFullFileName(
		FileNameStructure);
	
	Return FileNameStructure;
	
EndFunction

// Makes the specified file version active.
//
// Parameters:
//   FileName - String - the name of the version owner file.
//   FileID - String - ID .
//   FileOwner - String - ID of the file owner-the version owner.
//   VersionID - String - id of the version to make active.
//   CallbackDescription - CallbackDescription - description of the alert that is called when the change is successful.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure MakeVersionActive(FileName, FileID, FileOwner, VersionID,
		CallbackDescription = Undefined, FormUniqueID = Undefined) Export
	
	MessageText = "";
	If IntegrationWith1CDocumentManagementCoreServerCall.MakeVersionActive(
			FileID, VersionID, MessageText) Then
		If MessageText = "" Then
			MessageText = NStr("vi = 'Đã thay đổi phiên bản mặc định.';
								|ru = 'Активная версия изменена.';
								|en = 'The active version is changed.'; fa = 'The active version is changed.';
								|it = 'Versione attiva modificata.';
								|pl = 'Aktywna wersja została zmieniona.';
								|tr = 'Aktif sürüm değiştirildi.'");
		EndIf;
		
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.ChangingActiveVersionOfFile = True;
		FileOperation.InformFormOfFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			FileName,
			FileID,
			FileOwner,
			MessageText,,
			FormUniqueID);
		
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, VersionID);
		EndIf;
	Else
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

// Creates a file by copying.
//
// Parameters:
//   OriginalID - String - id of the original file.
//   CallbackDescription - CallbackDescription - description of the alert that is called when the file is successfully created.
//
Procedure CreateFileByCopying(OriginalID, CallbackDescription = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("OriginalID", OriginalID);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.File",
		FormParameters,,,,,
		CallbackDescription);
	
EndProcedure

// The beginning of creating a file from an image from the buffer.
//
// Parameters:
//   Parameters - See IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters
//
Async Procedure CreateFileFromBuffer(Val Parameters) Export
	
	If Await InitAddInAsync() Then
		InsertPictureFromEndBuffer(True, Parameters);
	Else
		Handler = New CallbackDescription("InsertPictureFromEndBuffer", ThisObject, Parameters);
		InstallAddInSSL(Handler);
	EndIf;
	
EndProcedure

// Start creating a file from a file on disk.
//
// Parameters:
//   Parameters - See IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters
//
Procedure CreateFileFromDisk(Parameters) Export
	
	BeginAttachingFileSystemExtension(
		New CallbackDescription("CreateFileFromDiskAfterConnectingExtension",
			IntegrationWith1CDocumentManagementCoreClient,
			Parameters));
	
EndProcedure

// Start creating files BEFORE from files dragged from the disk.
//
// Parameters:
//   FilesArray - File, Array of File - list of files to drag and drop.
//   Parameters - See IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters
//
Async Procedure CreateFileFromDiskByDraggingAndDropping(Val FilesArray, Val Parameters) Export
	
	SelectedFiles = New Array;
	
	If TypeOf(FilesArray) = Type("Array") Then
		For Each File In FilesArray Do
			If TypeOf(File) = Type("File") And Await File.IsFileAsync() Then
				SelectedFiles.Add(File.FullName);
			EndIf;
		EndDo;
	ElsIf TypeOf(FilesArray) = Type("File") And Await FilesArray.IsFileAsync() Then
		SelectedFiles.Add(FilesArray.FullName);
	EndIf;
	
	If SelectedFiles.Count() = 0 Then
		Return;
	EndIf;
	
	CreateFilesFromAsyncDisk(SelectedFiles, Parameters);
	
EndProcedure

// Saves the file version to disk in the directory specified by the user.
//
// Parameters:
//   ID - String - ID of the Workflow version.
//   Description - String - the name of the file version.
//   Extension - String - file version extension.
//   FormUniqueID - UUID - ID of the calling form.
//   CallbackDescription - CallbackDescription - optional, a handler called with passing the file name
//     after saving it.
//
Procedure SaveVersionAs(ID, Description, Extension, FormUniqueID,
		CallbackDescription = Undefined) Export
	
	FileVersionData = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Description,
		ID,
		"DMFileVersion",
		Extension);
	
	Parameters = New Structure;
	Parameters.Insert("CurrentFile", FileVersionData);
	Parameters.Insert("FormUniqueID", FormUniqueID);
	Parameters.Insert("CallbackDescription", CallbackDescription);
	Parameters.Insert("RemainingFiles", New Array);
	Parameters.Insert("UseVisualizationOfItemInstanceStamp", True);
	
	SaveFilesAsStart(Parameters);
	
EndProcedure

// Saves file changes to BEFORE without removing the capture.
//
// Parameters:
//   ID - String - ID of the file BEFORE.
//   Description - String - the name of the file being edited.
//   Extension - String - the extension of the file being edited.
//   FormUniqueID - UUID - ID of the calling form.
//   CallbackDescriptionOnCompletion - CallbackDescription - optional, called on successful completion.
//   OwnerID - String - ID of the file owner.
//
Async Procedure SaveChangesToEditedFile(Val ID, Val Description, Val Extension,
		Val FormUniqueID, Val CallbackDescriptionOnCompletion = Undefined,
		Val OwnerID = "") Export
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Description,
		ID,
		"DMFile",
		Extension);
	
	Parameters = New Structure;
	Parameters.Insert("CurrentFile", CurrentFile);
	Parameters.Insert("OwnerID", OwnerID);
	Parameters.Insert("FormUniqueID", FormUniqueID);
	Parameters.Insert("CallbackDescription", CallbackDescriptionOnCompletion);
	
	If Not Await FileSystemExtensionAttached1Async() Then
		CallbackDescription = New CallbackDescription(
			"SaveChangesWithoutExpandingAfterPlacement",
			IntegrationWith1CDocumentManagementCoreClient,
			Parameters);
		Try
			ImportParameters = FileSystemClient.FileImportParameters();
			ImportParameters.FormIdentifier = FormUniqueID;
			FileSystemClient.ImportFile_(
				CallbackDescription,
				ImportParameters);
		Except
			WarningText = StrTemplate(
				NStr("vi = 'Không thể lưu các thay đổi do nguyên nhân:
					|%1';
					|ru = 'Не удалось сохранить изменения по причине:
					|%1';
					|en = 'Cannot save changes due to:
					|%1'; fa = 'Cannot save changes due to:
					|%1';
					|it = 'Non è stato possibile salvare le modifiche a causa di:
					|%1';
					|pl = 'Nie udało się zapisać zmiany z powodu:
					|%1';
					|tr = 'Bu nedenlerle değişiklikler kaydedilemedi:
					|%1'"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			ShowMessageBox(, WarningText);
		EndTry;
		Return;
	EndIf;
	
	EditingInformation =
		IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile(
			ID,
			"DMFile");
	Parameters.Insert("EditingInformation", EditingInformation);
	
	// Let's check if it is possible to perform the operation at all (the situation could have changed on the side BEFORE).
	If Not EditingInformation.Saved_ Then
		ShowMessageBox(, NStr("vi = 'Không thể lưu các thay đổi của tệp
			|bởi vì hiện tại tệp không bị chiếm để chỉnh sửa.';
			|ru = 'Не удалось сохранить изменения файла,
			|так как он сейчас не захвачен на редактирование.';
			|en = 'Cannot save changes in the file
			|as it is not locked for editing now.'; fa = 'Cannot save changes in the file
			|as it is not locked for editing now.';
			|it = 'Non è stato possibile salvare le modifiche al file,
			|poiché al momento non è preso per la modifica.';
			|pl = 'Nie udało się zapisać zmiany pliku,
			|ponieważ nie jest on teraz zajęty do edycji.';
			|tr = 'Şu anda düzenleme için ele geçirilen
			|dosyada yapılan değişiklikler kaydedilemedi.'"));
		Return;
	EndIf;
	If EditingInformation.ForReading Then
		ShowMessageBox(, NStr("vi = 'Không thể lưu các thay đổi của tệp
			|bởi vì hiện tại tệp chỉ được lưu để xem.';
			|ru = 'Не удалось сохранить изменения файла,
			|так как он сейчас сохранен только для просмотра.';
			|en = 'Cannot save changes
			|as the file is saved only for reading.'; fa = 'Cannot save changes
			|as the file is saved only for reading.';
			|it = 'Non è stato possibile salvare le modifiche al file,
			|poiché al momento è salvato solo per la visualizzazione.';
			|pl = 'Nie udało się zapisać zmiany pliku,
			|ponieważ jest on zapisany tylko do przeglądu.';
			|tr = 'Dosya şu anda sadece okunur dosya
			|olarak kaydedildiğinden, dosyada yapılan değişiklikler kaydedilemedi.'"));
		Return;
	EndIf;
	
	// Let's check if the file exists in the specified location.
	File = New File(EditingInformation.FullPath);
	Parameters.Insert("File", File);
	If Not Await File.ExistsAsync() Then
		Response = Await ShowQuestionYesNoAsync(NStr("vi = 'Không tìm thấy tệp trong thư mục làm việc. Giải phóng tệp?';
													|ru = 'Файл не найден в рабочем каталоге. Освободить его?';
													|en = 'File is not found in the working directory. Unlock the file?'; fa = 'File is not found in the working directory. Unlock the file?';
													|it = 'Файл не найден в рабочем каталоге. Освободить его?';
													|pl = 'Nie znaleziono pliku w roboczym katalogu. Zwolnić go?';
													|tr = 'Dosya çalışma klasöründe bulunamadı. Serbest bırak?'"));
		If Response = DialogReturnCode.No Then
			SaveChangesWithExtensionAfterReleaseQuestion(Parameters);
		EndIf;
		Return;
	EndIf;
	
	Parameters.CurrentFile.Size = Await File.SizeAsync();
	Parameters.CurrentFile.ModificationDate = Await File.GetModificationTimeAsync();
	Parameters.CurrentFile.UniversalModificationDate = Await File.GetModificationUniversalTimeAsync();
	
	// Everything is fine, we will put the file in BEFORE and release it.
	ExplanationText = StrTemplate(NStr("vi = 'Đang lưu tệp ""%1"" (%2). Xin vui lòng đợi...';
										|ru = 'Идет сохранение файла ""%1"" (%2). Пожалуйста, подождите...';
										|en = 'Saving the ""%1"" file (%2). Please wait...'; fa = 'Saving the ""%1"" file (%2). Please wait...';
										|it = 'Salvataggio del file ""%1"" (%2). Attendere...';
										|pl = 'Trwa zapisywanie pliku ""%1"" (%2). Proszę czekać...';
										|tr = 'Dosya kaydediliyor ""%1"" (%2). Lütfen bekleyin...'"),
		EditingInformation.FullPath,
		IntegrationWith1CDocumentManagementCoreClientServer.BriefSizePresentation(
			Parameters.CurrentFile.Size));
	Status(ExplanationText);
	
	NotificationAfterPlacingFile = New CallbackDescription(
		"SaveChangesWithExtensionAfterPlacement",
		IntegrationWith1CDocumentManagementCoreClient,
		Parameters);
	Parameters.Insert("NotificationAfterPlacingFile", NotificationAfterPlacingFile);
	
	If EditingInformation.Property("VersionComment") Then
		NotificationAfterEnteringComment = New CallbackDescription(
			"AfterEnteringDescriptionOfChangesMade",
			IntegrationWith1CDocumentManagementCoreClient,
			Parameters);
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SaveFileToInfobaseForm",,,,,,
			NotificationAfterEnteringComment,
			FormWindowOpeningMode.LockWholeInterface);
	Else
		AfterEnteringDescriptionOfChangesMade(DialogReturnCode.OK, Parameters);
	EndIf;
	
EndProcedure

// Saves the file to disk in the directory specified by the user.
//
// Parameters:
//   ID - String - ID of the workflow file.
//   Description - String - file name.
//   Extension - String - file extension.
//   FormUniqueID - UUID - ID of the calling form.
//   CallbackDescription - CallbackDescription - optional, a handler called with passing the file name
//     after saving it.
//   UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//
Procedure SaveFileAs(ID, Description, Extension, FormUniqueID,
		CallbackDescription = Undefined, UseVisualizationOfItemInstanceStamp = True) Export
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Description,
		ID,
		"DMFile",
		Extension);
	
	Parameters = New Structure;
	Parameters.Insert("CurrentFile", CurrentFile);
	Parameters.Insert("FormUniqueID", FormUniqueID);
	Parameters.Insert("CallbackDescription", CallbackDescription);
	Parameters.Insert("RemainingFiles", New Array);
	Parameters.Insert("UseVisualizationOfItemInstanceStamp", UseVisualizationOfItemInstanceStamp);
	
	SaveFilesAsStart(Parameters);
	
EndProcedure

// Saves the file or version to disk in the directory specified by the user. A common entry point for the file and version.
//
// Parameters:
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * RemainingFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//     * FormUniqueID - UUID - ID of the calling form.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - no call is required.
//
Async Procedure SaveFilesAsStart(Val Parameters) Export
	
	If Not Await FileSystemExtensionAttached1Async() Then
		
		ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang lưu lại tệp ""%1"". Xin vui lòng đợi...';
				|ru = 'Идет сохранение файла ""%1"". Пожалуйста, подождите...';
				|en = 'Saving the ""%1"" file. Please wait...'; fa = 'Saving the ""%1"" file. Please wait...';
				|it = 'Salvataggio del file ""%1"". Attendere...';
				|pl = 'Trwa zapisywanie pliku ""%1"". Proszę czekać...';
				|tr = 'Dosya kaydediliyor ""%1"". Lütfen bekleyin...'"),
			Parameters.CurrentFile.FileName);
		Status(ExplanationText);
		
		UseVisualizationOfItemInstanceStamp = True;
		If ValueIsFilled(Parameters.CurrentFile.RefToBinaryFileData)
				And IsTempStorageURL(Parameters.CurrentFile.RefToBinaryFileData) Then
			Address = Parameters.CurrentFile.RefToBinaryFileData;
		ElsIf Parameters.CurrentFile.Type = "DMFile" Then
			Address = IntegrationWith1CDocumentManagementCoreServerCall.GetFileAndPutItInStorage(
				Parameters.CurrentFile.ID,
				UseVisualizationOfItemInstanceStamp,
				Parameters.FormUniqueID,,
				Parameters.CurrentFile);
		ElsIf Parameters.CurrentFile.Type = "DMFileVersion" Then
			Address = IntegrationWith1CDocumentManagementCoreServerCall.GetVersionOfFileAndPutItInRepository(
				Parameters.CurrentFile.ID,
				UseVisualizationOfItemInstanceStamp,
				Parameters.FormUniqueID,
				Parameters.CurrentFile);
		Else
			Raise StrTemplate(NStr("vi = 'Kiểu tệp không xác định: %1';
									|ru = 'Неизвестный тип файла: %1';
									|en = 'Unknown file type: %1'; fa = 'Unknown file type: %1';
									|it = 'Unknown file type: %1';
									|pl = 'Unknown file type: %1';
									|tr = 'Bilinmeyen dosya türü: %1'"), Parameters.CurrentFile.Type);
		EndIf;
		Parameters.Insert("TempFileStorageAddress", Address);
		Parameters.Insert("ReceivingMode", "TakeFromThe1CDocumentManagement");
		Parameters.Insert("Directory", "");
		
		FileSystemClient.SaveFile(
			New CallbackDescription(
				"ContinueSaveAsAfterSelectingSource",
				IntegrationWith1CDocumentManagementCoreClient,
				Parameters),
			Address,
			Parameters.CurrentFile.FileName);
		
		Return;
		
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"SaveAsAfterFileSelectionDialog",
		IntegrationWith1CDocumentManagementCoreClient,
		Parameters);
	If Parameters.RemainingFiles.Count() = 0 Then
		Parameters.Insert("FileDialogMode", FileDialogMode.Save);
		Dialog = New FileDialog(Parameters.FileDialogMode);
		Dialog.FullFileName = Parameters.CurrentFile.FileName;
		Dialog.Filter = StrTemplate(NStr("vi = 'Tất cả tệp (*.%1)|*.%1';
										|ru = 'Все файлы (*.%1)|*.%1';
										|en = 'All files (*.%1)|*.%1'; fa = 'All files (*.%1)|*.%1';
										|it = 'Tutti file (*.%1)|*.%1';
										|pl = 'Wszystkie pliki (*.%1)|*.%1';
										|tr = 'Tüm dosyalar (*.%1)|*.%1'"), Parameters.CurrentFile.Extension);
		Dialog.Show(CallbackDescription);
	Else
		Parameters.Insert("FileDialogMode", FileDialogMode.ChooseDirectory);
		FileSystemClient.SelectDirectory(CallbackDescription);
	EndIf;
	
EndProcedure

// Checks whether the is a scanned copy of the original attribute can be set.
//
// Parameters:
//   TemplateID - String - ID of the file template.
//   Extension - String - file extension.
//   ListOfExtensionsOfScannedCopiesOfOriginals - String - list of possible extensions of scanned copies of originals.
//
// Returns:
//   Boolean
//
Async Function SettingAttributeIsOriginalIsPossible(Val TemplateID, Val Extension,
		Val ListOfExtensionsOfScannedCopiesOfOriginals) Export
	
	If ValueIsFilled(TemplateID) Then
		ShowMessageBox(, NStr("vi = 'Không thể đánh dấu như là tệp chính được tạo từ khuôn mẫu.';
								|ru = 'Нельзя отметить как оригинал файл, созданный из шаблона.';
								|en = 'You cannot mark a file created from the template as an original.'; fa = 'You cannot mark a file created from the template as an original.';
								|it = 'Нельзя отметить как оригинал файл, созданный из шаблона.';
								|pl = 'You cannot mark a file created from the template as an original.';
								|tr = 'Numuneden oluşturulan dosya orijinal olarak işaretlenemez.'"));
		Return False;
	EndIf;
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ThisIsExtensionOfScannedCopy(
			Extension, ListOfExtensionsOfScannedCopiesOfOriginals) Then
		QuestionParametersYesNo = QuestionParametersYesNo();
		QuestionParametersYesNo.DefaultButton = DialogReturnCode.No;
		QuestionParametersYesNo.Title = NStr("vi = 'Đánh dấu là bản chính';
											|ru = 'Отметка оригинала';
											|en = 'Original mark'; fa = 'Original mark';
											|it = 'Отметка оригинала';
											|pl = 'Original mark';
											|tr = 'Orijinal işareti'");
		Response = Await ShowQuestionYesNoAsync(
			NStr("vi = 'Tệp được chọn, có thể không phải là bản sao scan.
				|Bạn thực sự muốn đánh dấu tệp đó là bản chính?';
				|ru = 'Выбранный файл, возможно, не является скан-копией.
				|Вы действительно хотите отметить его как оригинал?';
				|en = 'The selected file might not be a scanned copy.
				|Do you want to mark it as an original document?'; fa = 'The selected file might not be a scanned copy.
				|Do you want to mark it as an original document?';
				|it = 'Выбранный файл, возможно, не является скан-копией.
				|Вы действительно хотите отметить его как оригинал?';
				|pl = 'The selected file might not be a scanned copy.
				|Do you want to mark it as an original document?';
				|tr = 'Seçilen dosya tarama kopyası olmayabilir.
				|Orijinal olarak işaretlemek istediğinizden emin misiniz?'"),
			QuestionParametersYesNo);
		If Response = DialogReturnCode.No Then
			// Roll back the mark change.
			Return False;
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region DigitalSignatures

// Gets a table of values of the selected signature lines by the selected dates.
//
// Parameters:
//   SelectedRows - Array of Number - array of indexes of selected signature lines.
//   SignatureTree - FormDataTree - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//   ObjectID - String - ID of the object that owns the signatures.
//
// Returns:
//   Array of Structure:
//     * LineNumber - Number
//     * ObjectID - String
//
Function SelectedSignatures(SelectedRows, SignatureTree, ObjectID = Undefined) Export
	
	Result = New Array;
	
	For Each Item In SelectedRows Do
		RowData = SignatureTree.FindByID(Item);
		If ThisIsSignature(RowData) Then
			AddSignatureToArray(RowData, Result, RowData, ObjectID);
		ElsIf TypeOf(RowData) = Type("FormDataTreeItem") Then
			For Each Signature In RowData.GetItems() Do
				AddSignatureToArray(RowData, Result, Signature, RowData.ObjectID)
			EndDo;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Converts the signature table on the form into an array of structured signature data.
//
// Parameters:
//   SignatureTable - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagementCoreClientServer.SignatureData
//
Function DataOfSignatures(SignatureTable) Export
	
	ArrayOfSignatureData = New Array; // signatures left after deletion
	
	// forming an array of signature data.
	For Each RowData In SignatureTable Do
		
		CertificateBinaryData = Undefined;
		If ValueIsFilled(RowData.CertificateAddress) Then
			CertificateBinaryData = GetFromTempStorage(RowData.CertificateAddress);
		EndIf;
		SignatureData = SignatureData(
			GetFromTempStorage(RowData.SignatureAddress),
			CertificateBinaryData,
			RowData);
		ArrayOfSignatureData.Add(SignatureData);
		
	EndDo;
	
	Return ArrayOfSignatureData;
	
EndFunction

// Returns the data from which the XDTO DMSignature object will be generated for transmission to the DO.
//
// Parameters:
//   Signature - BinaryData - binary signature data.
//   CertificateBinaryData - BinaryData - binary data of the certificate.
//   SignatureProperties - Structure - There may be either a signature property structure that the BSP returns when
//     adding a new signature, or a signature table row if it is already an existing signature on the side BEFORE.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreClientServer.SignatureData
//
Function SignatureData(Signature, CertificateBinaryData, SignatureProperties) Export
	
	Return IntegrationWith1CDocumentManagementCoreClientServer.SignatureData(
		Signature,
		CertificateBinaryData,
		SignatureProperties);
	
EndFunction

// At the end of the signing, it displays the status of the signature installation to the object.
//
// Parameters:
//   Presentation - String - representation of the signed object to inform the user about the signing.
//   AddedObjectSignatures - Map of KeyAndValue:
//     * Key - String - ID of the DO object that owns the signature.
//     * Value - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails
//   DocumentID - String - ID of the signed document.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure InformAboutSigning(Presentation, AddedObjectSignatures, DocumentID,
		FormUniqueID = Undefined) Export
	
	Status(StrTemplate(NStr("vi = 'Đã đặt chữ ký cho ""%1""';
							|ru = 'Установлена подпись для ""%1""';
							|en = 'Signature is set for ""%1""'; fa = 'Signature is set for ""%1""';
							|it = 'Impostata firma per ""%1""';
							|pl = 'Ustawiono podpis dla ""%1""';
							|tr = '""%1"" için imza ayarlandı'"), Presentation));
	
	For Each Item In AddedObjectSignatures Do
		SignatureOwnerSDetails = Item.Value;
		If SignatureOwnerSDetails.Type <> "DMFile" Then
			Continue;
		EndIf;
		MessageText = StrTemplate(NStr("vi = 'Đã đặt chữ ký cho ""%1""';
										|ru = 'Установлена подпись для ""%1""';
										|en = 'Signature is set for ""%1""'; fa = 'Signature is set for ""%1""';
										|it = 'Impostata firma per ""%1""';
										|pl = 'Ustawiono podpis dla ""%1""';
										|tr = '""%1"" için imza ayarlandı'"), SignatureOwnerSDetails.Description);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.SigningDocumentWithFiles = True;
		FileOperation.InformFormOfFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			SignatureOwnerSDetails.Description,
			SignatureOwnerSDetails.ID,
			DocumentID,
			MessageText,
			False,
			FormUniqueID);
	EndDo;
	
EndProcedure

// Converts a 2-level tree into an array.
//
// Parameters:
//   SignatureTree - FormDataTree - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//
// Returns:
//   Array of Number - ids of signature lines.
//
Function SignaturesArray(SignatureTree) Export
	
	SignaturesArray = New Array;
	
	FirstLevelElements = SignatureTree.GetItems();
	
	For Each RowLevelOne In FirstLevelElements Do
		SecondLevelElements = RowLevelOne.GetItems();
		
		For Each String In SecondLevelElements Do
			SignaturesArray.Add(String.GetID());
		EndDo;
	EndDo;
	
	Return SignaturesArray;
	
EndFunction

// Returns the general electronic signature module for the client if the corresponding subsystem exists and
// the integration setting is enabled, allowing the integrated system to create electronic
// signatures for 1C objects:Document management.
//
// Parameters:
//   ToCreate - Boolean - indicates that the module is requested for creating signatures.
//
// Returns:
//   CommonModule, Undefined - The general electronic signature module is either Undefined if there is no
//     subsystem or the setting is turned off.
//
Function ModuleDigitalSignatureClient(ToCreate = False) Export
	
	ModuleDigitalSignatureClient = Undefined;
	
	If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		If Not ToCreate
				Or IntegrationWith1CDocumentManagementCoreClientCached.CreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem() Then
			ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		Else
			ShowMessageBox(, NStr("ru = 'Возможность создания подписей выключена в настройках интеграции с 1С:Документооборотом.
				|
				|Нужно включить настройку, либо подписать объект на стороне 1С:Документооборота.';
				|vi = 'The ability to create signatures is disabled in the 1C:Document Management integration settings.
				|
				|You need to enable this setting or sign the object in 1C:Document Management.';
				|en = 'The ability to create signatures is disabled in the 1C:Document Management integration settings.
				|
				|You need to enable this setting or sign the object in 1C:Document Management.'; fa = 'The ability to create signatures is disabled in the 1C:Document Management integration settings.
				|
				|You need to enable this setting or sign the object in 1C:Document Management.';
				|it = 'The ability to create signatures is disabled in the 1C:Document Management integration settings.
				|
				|You need to enable this setting or sign the object in 1C:Document Management.';
				|pl = 'The ability to create signatures is disabled in the 1C:Document Management integration settings.
				|
				|You need to enable this setting or sign the object in 1C:Document Management.';
				|tr = 'E-imza oluşturma imkanı 1C:Document Management entegrasyon ayarlarında kapalı.
				|
				|Ayarın açılması veya nesnenin 1C:Document Management tarafında imzalanması gerekir.'"));
		EndIf;
	Else
		ShowMessageBox(, NStr("ru = 'Отсутствует стандартная подсистема ""Электронная подпись"".';
								|vi = 'The standard ""Digital signature"" subsystem is missing.';
								|en = 'The standard ""Digital signature"" subsystem is missing.'; fa = 'The standard ""Digital signature"" subsystem is missing.';
								|it = 'The standard ""Digital signature"" subsystem is missing.';
								|pl = 'The standard ""Digital signature"" subsystem is missing.';
								|tr = 'Standart bir ""Elektronik İmza"" alt sistemi eksiktir.'"));
	EndIf;
	
	Return ModuleDigitalSignatureClient;
	
EndFunction

// Adds a signature from the file.
//
// Parameters:
//   FileProperties - See IntegrationWith1CDocumentManagementCoreClientServer.FileProperties
//
Procedure StartAddingItemsFromFile(FileProperties) Export
	
	Parameters = New Structure;
	Parameters.Insert("FileProperties", FileProperties);
	
	BeginAttachingFileSystemExtension(
		New CallbackDescription(
			"StartAddingItemsFromFileAfterEnablingExtension",
			IntegrationWith1CDocumentManagementCoreClient,
			Parameters));
	
EndProcedure

// Saves the file and signature to disk.
//
// Parameters:
//   ID - String - ID of the workflow file.
//   Extension - String - file extension.
//   Description - String - file name.
//   Size - Number - file size in bytes.
//   UniversalModificationDate - Date - the file modification date is universal.
//   FormUniqueID - String - ID of the calling form.
//   Signatures - Array of See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignature
//
Procedure StartSavingTogetherBOT(ID, Extension, Description, Size, UniversalModificationDate,
		FormUniqueID, Signatures = Undefined) Export
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		Description,
		ID,
		"DMFile",
		Extension);
	CurrentFile.Size = Size;
	CurrentFile.UniversalModificationDate = UniversalModificationDate;
	
	Parameters = New Structure;
	Parameters.Insert("CurrentFile", CurrentFile);
	Parameters.Insert("FormUniqueID", FormUniqueID);
	Parameters.Insert("Signatures", Signatures);
	
	BeginAttachingFileSystemExtension(
		New CallbackDescription(
			"StartSavingBotFilesAfterEnablingExtension",
			IntegrationWith1CDocumentManagementCoreClient,
			Parameters));
	
EndProcedure

// Generates a signature for the 1C object:Workflow and all its attached files.
//
// Parameters:
//   ObjectBefore - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//   Files - FormDataCollection
//         - Array of FormDataTreeItem:
//     * ID - String - ID of the workflow file.
//     * Description - String - file name.
//   AddressOfObjectSBinaryData - See IntegrationWith1CDocumentManagementCoreClientServer.AddressOfObjectSBinaryData
//   OnCloseNotifyDescription - CallbackDescription:
//     * AdditionalParameters - Structure:
//         ** AddressesArray - Array of String
//         ** DataArrayToStoreInDatabase - Array of See IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails
//
Procedure StartCreatingItemSSignature(ObjectBefore, Files, AddressOfObjectSBinaryData,
		OnCloseNotifyDescription) Export
	
	ModuleDigitalSignatureClient = ModuleDigitalSignatureClient(True);
	If ModuleDigitalSignatureClient = Undefined Then
		Return;
	EndIf;
	
	DataArrayToStoreInDatabase = OnCloseNotifyDescription.AdditionalParameters.DataArrayToStoreInDatabase;
	FilesArray = New Array;
	For Each File In Files Do
		FilesArray.Add(File.ID);
	EndDo;
	ArrayOfCaptionObjects = New Array;
	IntegrationWith1CDocumentManagementCoreServerCall.GetObjectsForCaption(
		ObjectBefore.Description,
		ObjectBefore.ID,
		ObjectBefore.Type,
		ArrayOfCaptionObjects,
		FilesArray,
		AddressOfObjectSBinaryData);
	
	DataSet = New Array;
	For Each CaptionObject In ArrayOfCaptionObjects Do
		DataForSignature = New Structure;
		DataForSignature.Insert("Data", CaptionObject.BinaryData);
		If CaptionObject.CaptionReferenceObject = ObjectBefore.ID Then
			DataForSignature.Insert("Presentation",
				New Structure("Value, Presentation", ObjectBefore.Presentation, ObjectBefore.Presentation));
		ElsIf CaptionObject.ObjectType = "DMFile" Then
			Rows = New Array;
			For Each File In Files Do
				If File.ID = CaptionObject.CaptionReferenceObject Then
					FilePresentation = StrTemplate(NStr("vi = 'Tệp: %1';
														|ru = 'Файл: %1';
														|en = 'File: %1'; fa = 'File: %1';
														|it = 'File: %1';
														|pl = 'Plik: %1';
														|tr = 'Dosya: %1'"), File.Description);
					Rows.Add(File);
				EndIf
			EndDo;
			If Rows.Count() = 1 Then
				DataForSignature.Insert("Presentation",
					New Structure("Value, Presentation", FilePresentation, FilePresentation));
			Else
				DataForSignature.Insert("Presentation", ObjectTypePresentationXDTO(CaptionObject.ObjectType));
			EndIf;
		Else
			DataForSignature.Insert("Presentation", ObjectTypePresentationXDTO(CaptionObject.ObjectType));
		EndIf;
		DataSet.Add(DataForSignature);
		DataArrayToStoreInDatabase.Add(
			IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails(
				CaptionObject.ObjectName_1,
				CaptionObject.CaptionReferenceObject,
				CaptionObject.ObjectType,
				CaptionObject.Encrypted));
	EndDo;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation", NStr("vi = 'Ký văn bản';
										|ru = 'Подписание документа';
										|en = 'Document signing'; fa = 'Document signing';
										|it = 'Firma del documento';
										|pl = 'Podpisanie dokumentu';
										|tr = 'Belge imzalama'"));
	DataDetails.Insert("DataTitle", NStr("vi = 'Văn bản';
										|ru = 'Документ';
										|en = 'Document'; fa = 'سند';
										|it = 'Документ';
										|pl = 'Document';
										|tr = 'Belge'"));
	DataDetails.Insert("DataSet", DataSet);
	DataDetails.Insert("Presentation", ObjectBefore.Description);
	DataDetails.Insert("SetPresentation", NStr("vi = 'Đối tượng (%1)';
												|ru = 'Объекты (%1)';
												|en = 'Objects (%1)'; fa = 'Objects (%1)';
												|it = 'Oggetti (%1)';
												|pl = 'Obiekty (%1)';
												|tr = 'Nesne (%1)'"));
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Form", OnCloseNotifyDescription.Module);
	NotificationParameters.Insert("OnCloseNotifyDescription", OnCloseNotifyDescription);
	CompletionHandler = New CallbackDescription(
		"StartCreatingItemSSignatureCompletion",
		IntegrationWith1CDocumentManagementCoreClient,
		NotificationParameters);
	
	ModuleDigitalSignatureClient.Sign(DataDetails, Undefined, CompletionHandler);
	
EndProcedure

// Opens the form for viewing the item's signature.
//
// Parameters:
//   SignatureTableCurData - FormDataCollectionItem - the Cur signature String.
//
Procedure OpenSignature(SignatureTableCurData) Export
	
	If SignatureTableCurData = Undefined Or Not ValueIsFilled(SignatureTableCurData.Object) Then
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = ModuleDigitalSignatureClient();
	If ModuleDigitalSignatureClient = Undefined Then
		Return;
	EndIf;
	ModuleDigitalSignatureInternalClientServer = CommonClient.CommonModule("DigitalSignatureInternalClientServer");
	
	SignatureProperties = IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString(
		SignatureTableCurData);
	If Not ValueIsFilled(SignatureProperties.SignatureValidationDate) Then
		SignatureProperties.SignatureValidationDate = CurrentDate(); // The use is justified: the date-time is fixed on the client.
	EndIf;
	If Not ValueIsFilled(SignatureProperties.SignatureType) Then
		Try
			PropertiesFromBinaryData = ModuleDigitalSignatureInternalClientServer.SignaturePropertiesFromBinaryData(
				SignatureProperties.SignatureAddress,
				CommonClient.SessionDate() - CommonClient.UniversalDate());
			SignatureProperties.SignatureType = PropertiesFromBinaryData.SignatureType;
		Except
			SignatureProperties.SignatureType = Undefined;
		EndTry;
	EndIf;
	
	ModuleDigitalSignatureClient.OpenSignature(SignatureProperties);
	
EndProcedure

// Signs the file in the Workflow.
//
// Parameters:
//   FileProperties - See IntegrationWith1CDocumentManagementCoreClientServer.FileProperties
//
Procedure SignFile(FileProperties) Export
	
	If FileProperties.IsBeingEdited Then
		ShowMessageBox(,
			IntegrationWith1CDocumentManagementCoreClientServer.FileUsedByAnotherProcessCannotBeSignedMessageString());
		Return;
	EndIf;
	
	If FileProperties.Encrypted Then
		ShowMessageBox(,
			IntegrationWith1CDocumentManagementCoreClientServer.EncryptedFileCannotBeSignedMessageString());
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = ModuleDigitalSignatureClient(True);
	If ModuleDigitalSignatureClient = Undefined Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation", NStr("vi = 'Ký tên tệp';
										|ru = 'Подписание файла';
										|en = 'Sign file'; fa = 'امضای فایل';
										|it = 'Firma del file';
										|pl = 'Podpisanie pliku';
										|tr = 'Dosya imzalama'"));
	DataDetails.Insert("DataTitle", NStr("vi = 'Tệp';
										|ru = 'Файл';
										|en = 'File'; fa = 'فایل';
										|it = 'Файл';
										|pl = 'File';
										|tr = 'Dosya'"));
	DataDetails.Insert("Data",
		IntegrationWith1CDocumentManagementCoreServerCall.FileBinaryData(
			FileProperties.FileID,
			False));
	DataDetails.Insert("Presentation", FileProperties.FileName);
	DataDetails.Insert("PresentationsList", New ValueList());
	DataDetails.PresentationsList.Add(, FileProperties.FileName);
	
	CompletionHandler = New CallbackDescription(
		"SignFileCompletion",
		IntegrationWith1CDocumentManagementCoreClient,
		FileProperties);
	
	ModuleDigitalSignatureClient.Sign(DataDetails, Undefined, CompletionHandler);
	
EndProcedure

// Checks all selected signatures.
//
// Parameters:
//   SignatureTable - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable
//   AddressOfObjectSBinaryData - See IntegrationWith1CDocumentManagementCoreClientServer.AddressOfObjectSBinaryData
//   CallbackDescription - CallbackDescription - the handler that is called after verifying signatures.
//   SelectedSignatures - See IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures
//
Procedure VerifySignatures(SignatureTable, AddressOfObjectSBinaryData = Undefined,
		CallbackDescription = Undefined, SelectedSignatures = Undefined) Export
	
	ThereIsItemInstanceSubsystem = CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature");
	If ThereIsItemInstanceSubsystem Then
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		ModuleDigitalSignatureInternalClientServer =
			CommonClient.CommonModule("DigitalSignatureInternalClientServer");
	EndIf;
	
	ItemInstanceSettings = GeneralItemInstanceSettings();
	
	UpdateAddressOfObjectSBinaryData(SignatureTable, SelectedSignatures, AddressOfObjectSBinaryData);
	
	For Each RowData In SignatureTable Do
		
		If Not IntegrationWith1CDocumentManagementCoreClientServer.SignatureHighlighted(
				SelectedSignatures, RowData) Then
			Continue;
		EndIf;
		
		If Not ThereIsItemInstanceSubsystem Then
			RowData.Status = IntegrationWith1CDocumentManagementCoreClientServer.ItemInstanceStatus(
				True,
				NStr("vi = 'không có phân hệ chuẩn ""Chữ ký điện tử""';
					|ru = 'отсутствует стандартная подсистема ""Электронная подпись""';
					|en = 'the standard ""Digital signature"" subsystem is missing'; fa = 'the standard ""Digital signature"" subsystem is missing';
					|it = 'отсутствует стандартная подсистема ""Электронная подпись""';
					|pl = 'the standard ""Digital signature"" subsystem is missing';
					|tr = 'Standart bir ""Elektronik İmza"" alt sistemi eksiktir'"));
			RowData.SignatureValidationDate = CurrentDate(); // The use is justified: the date-time is fixed on the client.
			RowData.History = True;
			RowData.SignatureCorrect = False;
			RowData.WhoReceivedCertificateAndStatus = RowData.CertificateOwner + Chars.LF + RowData.Status;
			Continue;
		EndIf;
		
		// Let's define the signature algorithm.
		Application = Undefined;
		If ItemInstanceSettings.ApplicationsDetailsCollection.Count() > 1 And IsTempStorageURL(RowData.SignatureAddress) Then
			SignatureData = GetFromTempStorage(RowData.SignatureAddress);
			If TypeOf(SignatureData) = Type("BinaryData") Then
				SignAlgorithm = ModuleDigitalSignatureInternalClientServer.GeneratedSignAlgorithm(SignatureData);
				For Each ApplicationDetails In ItemInstanceSettings.ApplicationsDetailsCollection Do
					If ApplicationDetails.SignAlgorithm = SignAlgorithm Then
						Application = ApplicationDetails.Ref;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		If ItemInstanceSettings.VerifyDigitalSignaturesOnTheServer Then
			
			SignatureTablesAfterVerification = CommonClientServer.ValueInArray(
				IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString(RowData));
			IntegrationWith1CDocumentManagementCoreServerCall.VerifySignatures(
				SignatureTablesAfterVerification,
				SelectedSignatures,
				AddressOfObjectSBinaryData,
				Application);
			FillPropertyValues(RowData, SignatureTablesAfterVerification[0],, "SignatureType");
			MatchingCryptographySignatureTypesToXDTOEnumeration =
				IntegrationWith1CDocumentManagementCoreClientServer.MatchingCryptographySignatureTypesToXDTOEnumeration();
			RowData.SignatureType = MatchingCryptographySignatureTypesToXDTOEnumeration[
				SignatureTablesAfterVerification[0].SignatureType];
			
		Else
			
			Parameters = New Structure;
			Parameters.Insert("SignatureTable", CommonClientServer.ValueInArray(RowData));
			Parameters.Insert("AddressOfObjectSBinaryData", AddressOfObjectSBinaryData);
			Parameters.Insert("SelectedSignatures", SelectedSignatures);
			Parameters.Insert("CallbackDescription", CallbackDescription);
			
			NotificationToCheckSignaturesAfterCreatingManager = New CallbackDescription(
				"VerifySignaturesAfterCreatingManager",
				IntegrationWith1CDocumentManagementCoreClient,
				Parameters);
			ModuleDigitalSignatureClient.CreateCryptoManager(
				NotificationToCheckSignaturesAfterCreatingManager,
				"CheckSignature",,
				Application);
			
		EndIf;
		
	EndDo;
	
	If ItemInstanceSettings.VerifyDigitalSignaturesOnTheServer And CallbackDescription <> Undefined Then
		RunCallback(CallbackDescription, SignatureTable);
	EndIf;
	
EndProcedure

// Saves the signature to disk.
//
// Parameters:
//   SignatureTableCurData - FormDataCollectionItem - the Cur signature String.
//
Procedure SaveSignature(SignatureTableCurData) Export
	
	If Not ThisIsSignature(SignatureTableCurData) Then
		Return;
	EndIf;
	
	If IsBlankString(SignatureTableCurData.Object) Then
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = ModuleDigitalSignatureClient();
	If ModuleDigitalSignatureClient = Undefined Then
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient.SaveSignature(SignatureTableCurData.SignatureAddress);
	
EndProcedure

// Deletes the signatures of the document and its files.
//
// Parameters:
//   DeletedRows - See IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures
//   SignatureTable - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable
//   FileOwner - String - ID of the common owner of all files included in the signature table.
//   CallbackDescription - CallbackDescription - optional, a handler that is called after deleting signatures.
//   FormUniqueID - UUID - ID of the calling form.
//
Async Procedure DeleteSignatures(Val DeletedRows, Val SignatureTable, Val FileOwner,
		Val CallbackDescription = Undefined, Val FormUniqueID = Undefined) Export
	
	If DeletedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QuestionParametersYesNo = QuestionParametersYesNo();
	QuestionParametersYesNo.YesButtonText = NStr("vi = 'Xóa bỏ';
												|ru = 'Удалить';
												|en = 'Delete'; fa = 'حذف';
												|it = 'Удалить';
												|pl = 'Delete';
												|tr = 'Sil'");
	QuestionParametersYesNo.NoButtonText = NStr("vi = 'Không xóa';
												|ru = 'Не удалять';
												|en = 'Do not delete'; fa = 'حذف نشود';
												|it = 'Не удалять';
												|pl = 'Nie usuwaj';
												|tr = 'Silme'");
	Response = Await ShowQuestionYesNoAsync(
		NStr("vi = 'Xóa chữ ký đã chọn?';
			|ru = 'Удалить выделенные подписи?';
			|en = 'Do you want to delete the selected signatures?'; fa = 'Do you want to delete the selected signatures?';
			|it = 'Удалить выделенные подписи?';
			|pl = 'Usunąć zaznaczone podpisy?';
			|tr = 'Seçilen imzalar silinsin mi?'"),
		QuestionParametersYesNo);
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FilesForNotification = IntegrationWith1CDocumentManagementCoreServerCall.DeleteSignatures(
		DeletedRows,
		SignatureTable);
	
	ThereIsSeparateNotification = (CallbackDescription <> Undefined);
	NotifyDocumentCardAboutFileChanges = Not ThereIsSeparateNotification;
	
	For Each MapItem In FilesForNotification Do
		MessageText = StrTemplate(NStr("vi = 'Đã xóa chữ ký tệp ""%1""';
										|ru = 'Удалена подпись файла ""%1""';
										|en = 'The ""%1"" file signature is deleted.'; fa = 'The ""%1"" file signature is deleted.';
										|it = 'Удалена подпись файла ""%1""';
										|pl = 'The ""%1"" file signature is deleted.';
										|tr = '""%1"" dosya imzası ayarlandı'"), MapItem.Value);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.DeletingItemInstanceFile = True;
		FileOperation.InformFormOfFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			MapItem.Value,
			MapItem.Key,
			FileOwner,
			MessageText,
			NotifyDocumentCardAboutFileChanges,
			FormUniqueID);
	EndDo;
	
	If ThereIsSeparateNotification Then
		RunCallback(CallbackDescription, True);
	EndIf;
	
EndProcedure

// Completes verification of signatures, setting their Status and verification date.
//
// Parameters:
//   SignatureTree - FormDataTree - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//   SignatureTable - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable
//
Procedure SetStatusOfSignatures(SignatureTree, SignatureTable) Export
	
	For Each SignatureOwner In SignatureTree.GetItems() Do
		
		For Each Signature In SignatureOwner.GetItems() Do
			
			ItemInstanceVerificationResultString = ItemInstanceVerificationResultString(Signature, SignatureTable);
			If ItemInstanceVerificationResultString = Undefined Then
				Continue;
			EndIf;
			
			FillPropertyValues(
				Signature,
				ItemInstanceVerificationResultString,
				"History, Status, WhoReceivedCertificateAndStatus, SignatureCorrect, SignatureValidationDate");
			
			SeparatorPosition = StrFind(Signature.WhoReceivedCertificateAndStatus, " (", SearchDirection.FromEnd);
			If SeparatorPosition > 0 And Mid(Signature.WhoReceivedCertificateAndStatus, SeparatorPosition + 4, 1) = "." Then
				Signature.WhoReceivedCertificateAndStatus = Left(Signature.WhoReceivedCertificateAndStatus, SeparatorPosition - 1);
			EndIf;
			
			If ValueIsFilled(Signature.SignatureValidationDate) Then
				Signature.WhoReceivedCertificateAndStatus = StrTemplate("%1 (%2)",
					Signature.WhoReceivedCertificateAndStatus,
					Format(Signature.SignatureValidationDate, NStr("ru = 'ДФ=''dd.MM.yyyy HH:mm''';
																	|vi = 'DF=''MM/dd/yyyy hh:mm tt''';
																	|en = 'DF=''MM/dd/yyyy hh:mm tt'''; fa = 'DF=''MM/dd/yyyy hh:mm tt''';
																	|it = 'DF=''MM/dd/yyyy hh:mm tt''';
																	|pl = 'DF=''MM/dd/yyyy hh:mm tt''';
																	|tr = 'DF=''dd.MM.yyyy HH:mm'''")));
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Determines whether a line in the signature tree is a line containing signature data.
//
// Parameters:
//   SignatureTreeString - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//
// Returns:
//   Boolean
//
Function ThisIsSignature(SignatureTreeString) Export
	
	If SignatureTreeString = Undefined Then
		Return False;
	Else
		Return IsTempStorageURL(SignatureTreeString.SignatureAddress);
	EndIf;
	
EndFunction

#EndRegion

#Region WorkingWithPictures

// Sets the scan component.
//
// Parameters:
//   HandlerResults_1 - CallbackDescription
//
Async Procedure InstallAddInSSL(Val HandlerResults_1) Export
	
	If ApplicationParameters["IntegrationWith1CDocumentManagementAddInToGetPicturesFromClipboard"] = Undefined Then
		ReturnCode = Await AttachAddInAsync(
			"CommonTemplate.IntegrationWith1CDocumentManagementAddInToGetPicturesFromClipboard",
			"ImageFromClipboard",
			AddInType.Native);
		
		If ReturnCode Then
			Status(NStr("vi = 'Đã cài đặt cấu phần scan.';
						|ru = 'Компонента сканирования уже установлена.';
						|en = 'The scanner add-in is already installed.'; fa = 'The scanner add-in is already installed.';
						|it = 'Компонента сканирования уже установлена.';
						|pl = 'The scanner add-in is already installed.';
						|tr = 'Tarama add-in zaten ayarlıdır.'"));
		Else
			
			ExecutionParameters = New Structure;
			ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
			
			CallbackDescription = New CallbackDescription(
				"BeginInstallAddInContinued",
				ThisObject,
				ExecutionParameters);
			BeginInstallAddIn(
				CallbackDescription,
				"CommonTemplate.IntegrationWith1CDocumentManagementAddInToGetPicturesFromClipboard");
			Return;
			
		EndIf;
		ApplicationParameters["IntegrationWith1CDocumentManagementAddInToGetPicturesFromClipboard"] =
			New("AddIn.ImageFromClipboard.AddInNativeExtension");
	Else
		Status(NStr("vi = 'Đã cài đặt cấu phần scan.';
					|ru = 'Компонента сканирования уже установлена.';
					|en = 'The scanner add-in is already installed.'; fa = 'The scanner add-in is already installed.';
					|it = 'Компонента сканирования уже установлена.';
					|pl = 'The scanner add-in is already installed.';
					|tr = 'Tarama add-in zaten ayarlıdır.'"));
	EndIf;
	
EndProcedure

// Continuation of the component installation.
//
// Parameters:
//   ExecutionParameters - Structure:
//     * HandlerResults_1 - CallbackDescription
//
Procedure BeginInstallAddInContinued(ExecutionParameters) Export
	
	ConnectionExecutionParameters = New Structure;
	ConnectionExecutionParameters.Insert("HandlerResults_1", ExecutionParameters.HandlerResults_1);
	
	CallbackDescription = New CallbackDescription(
		"BeginAttachingAddInContinued",
		ThisObject,
		ConnectionExecutionParameters);
	
	BeginAttachingAddIn(
		CallbackDescription,
		"CommonTemplate.IntegrationWith1CDocumentManagementAddInToGetPicturesFromClipboard",
		"ImageFromClipboard",
		AddInType.Native);
	
EndProcedure

// Continuation of the component installation.
//
// Parameters:
//   Connected - Boolean - the component is connected.
//   ExecutionParameters - Structure:
//     * HandlerResults_1 - CallbackDescription
//
Procedure BeginAttachingAddInContinued(Connected, ExecutionParameters) Export
	
	If Connected Then
		
		ApplicationParameters["IntegrationWith1CDocumentManagementAddInToGetPicturesFromClipboard"] =
			New("AddIn.ImageFromClipboard.AddInNativeExtension");
		RunCallback(ExecutionParameters.HandlerResults_1, Connected);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Tasks

// Opens forms for getting role addressing objects.
//
// Parameters:
//   OnCloseNotifyDescription - CallbackDescription - description of the closure notification.
//   NameOfRole - String - name of the role for getting addressing objects.
//   RoleType - String - the type of role for getting addressing objects.
//   IDRoles - String - ID of the role in the Workflow.
//   OwnerForm - ClientApplicationForm - the managed form where the role is selected.
//
Procedure ShowGettingAddressingObjectsOfRole(OnCloseNotifyDescription, NameOfRole, RoleType, IDRoles,
		OwnerForm) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Role", NameOfRole);
	FormParameters.Insert("RoleID", IDRoles);
	FormParameters.Insert("RoleType", RoleType);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("OnCloseNotifyDescription", OnCloseNotifyDescription);
	NotificationParameters.Insert("NameOfRole", NameOfRole);
	NotificationParameters.Insert("RoleType", RoleType);
	NotificationParameters.Insert("IDRoles", IDRoles);
	NotificationParameters.Insert("OwnerForm", OwnerForm);
	
	Notification = New CallbackDescription(
		"ShowGettingAddressingObjectsOfRoleCompletion",
		IntegrationWith1CDocumentManagementCoreClient,
		NotificationParameters);
	
	ChoiceForm = OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectPerformerRole",
		FormParameters,
		OwnerForm,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
	If ChoiceForm = Undefined Then
		Result = New Structure("Result", "WithoutAddressingObjects");
		RunCallback(Notification, Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. Should be used
// integration1documentobase functionclient.Open the formunjoined files.
// Opens the list of files attached to the IC object.
//
// Parameters:
//   FileOwner - AnyRef - the source of the Command, the IP object, is the owner of the files.
//   CurrentFile - String - id of the Cur file to position the list on.
//   ReadOnly - Boolean - the mode of opening the form.
//   FormOwner - ClientApplicationForm - the form from which the command is called.
//   Uniqueness - Arbitrary - the uniqueness key with which the attached files form should be opened.
//   Window - ClientApplicationWindow - optional parameter, owner form window.
//   IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement
//                     - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - a suitable integration rule.
//   FileOwnerID - String - ID of the DO object that owns the file.
//   FileOwnerType - String - the type of the BEFORE object that owns the file.
//   OwnerPresentation - String - Presentation of the object BEFORE, which is the owner of the file.
//
Procedure OpenAttachedFiles(FileOwner, CurrentFile = Undefined, ReadOnly = False,
		FormOwner = Undefined, Uniqueness = Undefined, Window = Undefined, IntegrationRule = Undefined,
		FileOwnerID = "", FileOwnerType = "", OwnerPresentation= "") Export
	
	OpeningParameters = OptionsForOpeningListOfFiles(FormOwner);
	OpeningParameters.CurrentFile = CurrentFile;
	OpeningParameters.ReadOnly = ReadOnly;
	OpeningParameters.Uniqueness = Uniqueness;
	OpeningParameters.Window = Window;
	OpeningParameters.IntegrationRule = IntegrationRule;
	OpeningParameters.FileOwnerID = FileOwnerID;
	OpeningParameters.FileOwnerType = FileOwnerType;
	OpeningParameters.OwnerPresentation = OwnerPresentation;
	
	OpenFormAttachedFiles(
		FileOwner,
		OpeningParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region NotificationProcessing

#Region ProcessingAlertFiles

Procedure InsertPictureFromEndBuffer(Result, Parameters) Export
	
	If Result <> True Then
		Return;
	EndIf;
	
	PathToFile =
		ApplicationParameters["IntegrationWith1CDocumentManagementAddInToGetPicturesFromClipboard"].GetPictureFromClipboard();
	
	If Not IsBlankString(PathToFile) Then
		Parameters.Insert("FullFileName", PathToFile);
		Parameters.Insert("DeleteFileAfterPut", True);
		CreateFilesFromAsyncDisk(CommonClientServer.ValueInArray(PathToFile), Parameters);
	Else
		ShowMessageBox(, NStr("vi = 'Bộ nhớ đệm trao đổi không chứa hình ảnh';
								|ru = 'Буфер обмена не содержит картинки';
								|en = 'Clipboard contains no pictures'; fa = 'Clipboard contains no pictures';
								|it = 'Буфер обмена не содержит картинки';
								|pl = 'Clipboard contains no pictures';
								|tr = 'Pano resim içermiyor'"));
	EndIf;
	
EndProcedure

// Continues adding a file from disk after searching for a related object BEFORE.
//
// Parameters:
//   ObjectBefore - Structure:
//     * ID - String
//     * type - String
//     * name - String
//     * documentType - Structure:
//       ** ID - String
//       ** type - String
//       ** name - String
//     * ExternalObject - AnyRef
//     * StateAllowsAddingScannedCopy - Boolean
//     * StateAllowsFileAddition - Boolean
//     * StateAllowsChangesToItemInstance - Boolean
//     * StateAllowsFileEditing - Boolean
//     * StateAllowsFileDeletion - Boolean
//   Parameters - Structure:
//     * FileOwner - AnyRef - the source of the Command, the IP object, is the owner of the files.
//     * FormUniqueID - UUID - ID of the calling form.
//
Async Procedure AddFileFromDiskToICObjectAfterSearchingForObjectDM(Val ObjectBefore, Val Parameters) Export
	
	If TypeOf(ObjectBefore) <> Type("Structure") Or Not ValueIsFilled(ObjectBefore.ID) Then
		Return;
	EndIf;
	
	YouNeedToAddScannedCopy = Await YouNeedToAddScannedCopyAsync(
		ObjectBefore.StateAllowsAddingScannedCopy,
		ObjectBefore.StateAllowsFileAddition);
	
	If YouNeedToAddScannedCopy = DialogReturnCode.Yes Then
		ParametersForStartOfCreation = FileCreationStartParameters();
		ParametersForStartOfCreation.IsScannedCopy = (ObjectBefore.StateAllowsAddingScannedCopy
			And Not ObjectBefore.StateAllowsFileAddition);
		ParametersForStartOfCreation.OwnerID = ObjectBefore.ID;
		ParametersForStartOfCreation.OwnerType = ObjectBefore.type;
		ParametersForStartOfCreation.FormUniqueID = Parameters.FormUniqueID;
		ParametersForStartOfCreation.OwnerPresentation = String(Parameters.FileOwner);
		ParametersForStartOfCreation.Owner = Parameters.FileOwner;
		CreateFileFromDisk(ParametersForStartOfCreation);
	EndIf;
	
EndProcedure

// Performs file release in BEFORE after user permission.
//
// Parameters:
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * OwnerID - String - ID of the file owner.
//     * EditingInformation - See IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile.
//     * FormUniqueID - UUID - ID of the calling form.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Procedure FinishEditingWithExtensionAfterReleaseQuestion(Parameters)
	
	IntegrationWith1CDocumentManagementCoreServerCall.UnlockFile(
		Parameters.CurrentFile.ID);
	
	// Delete the information about editing the file.
	EditingInformation = Parameters.EditingInformation;
	EditingInformation.Saved_ = False;
	IntegrationWith1CDocumentManagementCoreServerCall.SaveFileEditingInformation(
		EditingInformation);
	MessageText = StrTemplate(NStr("vi = 'Tệp %1 đã cập nhật và giải phóng.';
									|ru = 'Файл %1 обновлен и освобожден.';
									|en = 'The %1 file is updated and unlocked.'; fa = 'The %1 file is updated and unlocked.';
									|it = 'Файл %1 обновлен и освобожден.';
									|pl = 'The %1 file is updated and unlocked.';
									|tr = 'Dosya %1 güncellendi ve kilidi açıldı.'"), Parameters.CurrentFile.Description);
	FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
	FileOperation.FileEditingIsComplete = True;
	FileOperation.InformFormOfFile = True;
	FileOperation.InformFileListForm = True;
	InformAboutFileChanges(
		FileOperation,
		Parameters.CurrentFile.Description,
		Parameters.CurrentFile.ID,
		Parameters.OwnerID,
		MessageText,,
		Parameters.FormUniqueID);
	If Parameters.CallbackDescription <> Undefined Then
		RunCallback(Parameters.CallbackDescription, Parameters.CurrentFile);
	EndIf;
	
EndProcedure

// Completes the placement of the file in the UP without using the file extension.
//
// Parameters:
//   FileThatWasPut - Structure - if the file is placed in the repository:
//     * Location - String - The address of the file data in the temporary storage.
//     * Name - String - the full path to the placed file.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * OwnerID - String - ID of the file owner.
//     * FormUniqueID - UUID - ID of the calling form.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Procedure FinishEditingWithoutExpandingAfterPlacement(FileThatWasPut, Parameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Parameters.Insert("TempFileStorageAddress", FileThatWasPut.Location);
	Parameters.Insert("UnlockFile", True);
	Parameters.Insert("UpdateEditInformation", True);
	
	// Get the extension: it could have changed.
	NameStructure = ParseFullFileName(FileThatWasPut.Name);
	Parameters.CurrentFile.Extension = NameStructure.Extension;
	
	// We will delete the parameters that cannot and do not need to be transmitted to the server.
	CallbackDescription = Parameters.CallbackDescription;
	Parameters.Delete("CallbackDescription");
	
	If IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileWithBinaryTemporaryStorageData(
			Parameters) Then
		MessageText = StrTemplate(NStr("vi = 'Tệp %1 đã cập nhật và giải phóng.';
										|ru = 'Файл %1 обновлен и освобожден.';
										|en = 'The %1 file is updated and unlocked.'; fa = 'The %1 file is updated and unlocked.';
										|it = 'Файл %1 обновлен и освобожден.';
										|pl = 'The %1 file is updated and unlocked.';
										|tr = 'Dosya %1 güncellendi ve kilidi açıldı.'"), Parameters.CurrentFile.Description);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.FileEditingIsComplete = True;
		FileOperation.InformFormOfFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			Parameters.CurrentFile.Description,
			Parameters.CurrentFile.ID,
			Parameters.OwnerID,
			MessageText,,
			Parameters.FormUniqueID);
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, Parameters.CurrentFile);
		EndIf;
	EndIf;
	
EndProcedure

// Completes the placement of the file in the BEFORE using the extension for working with files.
//
// Parameters:
//   FileThatWasPut - Structure - if the file is placed in the repository:
//     * Location - String - The address of the file data in the temporary storage.
//     * Name - String - the full path to the placed file.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * OwnerID - String - ID of the file owner.
//     * FormUniqueID - UUID - ID of the calling form.
//     * EditingInformation - See IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile.
//     * File - File - the file being placed in the working directory.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Async Procedure FinishEditingWithExtensionAfterPlacement(Val FileThatWasPut, Val Parameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Parameters.Insert("TempFileStorageAddress", FileThatWasPut.Location);
	Parameters.Insert("UnlockFile", True);
	Parameters.Insert("UpdateEditInformation", True);
	
	// Extract the text, if necessary.
	Settings1CDocumentManagement = IntegrationWith1CDocumentManagementCoreClientCached.GetSettings();
	If Settings1CDocumentManagement.NeedToExtractText Then
		Parameters.CurrentFile.Text = Await ExtractText1Async(Parameters.EditingInformation.FullPath);
	EndIf;
	
	// We will delete the parameters that cannot and do not need to be transmitted to the server.
	CallbackDescription = Parameters.CallbackDescription;
	Parameters.Delete("CallbackDescription");
	File = Parameters.File;
	Parameters.Delete("File");
	
	If IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileWithBinaryTemporaryStorageData(
			Parameters) Then
		If Not Await File.GetReadOnlyAsync() Then
			Await File.SetReadOnlyAsync(True);
		EndIf;
		MessageText = StrTemplate(NStr("vi = 'Tệp %1 đã cập nhật và giải phóng.';
										|ru = 'Файл %1 обновлен и освобожден.';
										|en = 'The %1 file is updated and unlocked.'; fa = 'The %1 file is updated and unlocked.';
										|it = 'Файл %1 обновлен и освобожден.';
										|pl = 'The %1 file is updated and unlocked.';
										|tr = 'Dosya %1 güncellendi ve kilidi açıldı.'"), Parameters.CurrentFile.Description);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.FileEditingIsComplete = True;
		FileOperation.InformFormOfFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			Parameters.CurrentFile.Description,
			Parameters.CurrentFile.ID,
			Parameters.OwnerID,
			MessageText,,
			Parameters.FormUniqueID);
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, Parameters.CurrentFile);
		EndIf;
	EndIf;
	
EndProcedure

// Called after receiving the files and sends them to print.
//
// Parameters:
//   FullFileNames - Array of String - an array of strings containing the full names of the received files.
//   Parameters - Arbitrary - not use.
//
Procedure PrintFilesAfterReceiving(FullFileNames, Parameters) Export
	
	For Each FullFileName In FullFileNames Do
		PrintFileByApplication(FullFileName);
	EndDo;
	
EndProcedure

// Called during the update from a file on disk after placing the file without using the extension.
//
// Parameters:
//   StoredFileDescription - StoredFileDescription - contains a description of the file placed in temporary storage.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * OwnerID - String - ID of the file owner.
//     * FormUniqueID - UUID - ID of the calling form.
//     * UnlockFile - Boolean - indicates whether the file needs to be released.
//     * UpdateEditInformation - Boolean - indicates whether the editing information needs to be updated.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Procedure UpdateFromFileOnDiskAfterPlacingFileWithoutExtension(StoredFileDescription, Parameters) Export
	
	If StoredFileDescription = Undefined Or StoredFileDescription.PutFileCanceled Then
		Return;
	EndIf;
	
	Parameters.Insert("TempFileStorageAddress", StoredFileDescription.Address);
	
	If StoredFileDescription.FileRef.File <> Undefined Then
		Parameters.CurrentFile.Extension = StoredFileDescription.FileRef.File.Extension;
	EndIf;
	
	// We will delete the parameters that cannot and do not need to be transmitted to the server.
	CallbackDescription = Parameters.CallbackDescription;
	Parameters.Delete("CallbackDescription");
	
	If IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileWithBinaryTemporaryStorageData(
			Parameters) Then
		MessageText = StrTemplate(NStr("vi = 'Tệp %1 đã cập nhật.';
										|ru = 'Файл %1 обновлен.';
										|en = 'The %1 file is updated.'; fa = 'The %1 file is updated.';
										|it = 'Файл %1 обновлен.';
										|pl = 'The %1 file is updated.';
										|tr = 'Dosya %1 güncellendi.'"), Parameters.CurrentFile.Description);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.EditingFile = True; // Creates a new version of the file, but does not finish editing it.
		FileOperation.InformFormOfFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			Parameters.CurrentFile.Description,
			Parameters.CurrentFile.ID,
			Parameters.OwnerID,
			MessageText,,
			Parameters.FormUniqueID);
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, Parameters.CurrentFile);
		EndIf;
	EndIf;
	
EndProcedure

// Called during the update from a file on disk after placing the file using the extension.
//
// Parameters:
//   StoredFileDescription - StoredFileDescription - contains a description of the file placed in temporary storage.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * OwnerID - String - ID of the file owner.
//     * FormUniqueID - UUID - ID of the calling form.
//     * UnlockFile - Boolean - indicates whether the file needs to be released.
//     * UpdateEditInformation - Boolean - indicates whether the editing information needs to be updated.
//     * EditingInformation - See IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Async Procedure UpdateFromFileOnDiskAfterPlacingFileWithExtension(Val StoredFileDescription,
		Val Parameters) Export
	
	If StoredFileDescription = Undefined
			Or StoredFileDescription.PutFileCanceled
			Or StoredFileDescription.FileRef.File = Undefined Then
		Return;
	EndIf;
	
	Parameters.Insert("TempFileStorageAddress", StoredFileDescription.Address);
	FullPath = StoredFileDescription.FileRef.File.FullName;
	Parameters.CurrentFile.Extension = StoredFileDescription.FileRef.File.Extension;
	
	File = New File(FullPath);
	ChangeTimeSelected = Await File.GetModificationUniversalTimeAsync();
	DateOfModificationSelected = ToLocalTime(ChangeTimeSelected);
	
	If DateOfModificationSelected < Parameters.CurrentFile.ModificationDate Then // There is a newer one in the repository.
		
		ErrorText = StrTemplate(
			NStr("vi = 'Tệp ""%1""
				|trong kho chứa tệp có ngày thay đổi muộn hơn (%2),
				|tệp được chọn (%3).
				|
				|Giao dịch bị ngắt.';
				|ru = 'Файл ""%1""
				|в хранилище файлов имеет более позднюю дату изменения (%2),
				|чем выбранный файл (%3).
				|
				|Операция прервана.';
				|en = 'The %1 file
				|in the file storage was changed later (%2)
				|than the selected file (%3).
				|
				|The operation is canceled.'; fa = 'The %1 file
				|in the file storage was changed later (%2)
				|than the selected file (%3).
				|
				|The operation is canceled.';
				|it = 'Файл ""%1""
				|в хранилище файлов имеет более позднюю дату изменения (%2),
				|чем выбранный файл (%3).
				|
				|Операция прервана.';
				|pl = 'The %1 file
				|in the file storage was changed later (%2)
				|than the selected file (%3).
				|
				|The operation is canceled.';
				|tr = '""%1""
				|dosya deposundaki dosyanın değiştirilme tarihi(%2),
				|, seçilen dosyadan daha sonradır (%3).
				|
				|İşlem iptal edildi.'"),
			Parameters.CurrentFile.Description,
			Parameters.CurrentFile.ModificationDate,
			DateOfModificationSelected);
		
		ShowMessageBox(,ErrorText);
		Return;
	EndIf;
	
	Parameters.CurrentFile.Size = Await File.SizeAsync();
	Parameters.CurrentFile.ModificationDate = Await File.GetModificationTimeAsync();
	Parameters.CurrentFile.UniversalModificationDate = ChangeTimeSelected;
	
	// Extract the text, if necessary.
	Settings1CDocumentManagement = IntegrationWith1CDocumentManagementCoreClientCached.GetSettings();
	If Settings1CDocumentManagement.NeedToExtractText Then
		Parameters.CurrentFile.Text = Await ExtractText1Async(FullPath);
	EndIf;
	
	// We will delete the parameters that cannot and do not need to be transmitted to the server.
	CallbackDescription = Parameters.CallbackDescription;
	Parameters.Delete("CallbackDescription");
	
	If IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileWithBinaryTemporaryStorageData(
			Parameters) Then
		MessageText = StrTemplate(NStr("vi = 'Tệp %1 đã cập nhật.';
										|ru = 'Файл %1 обновлен.';
										|en = 'The %1 file is updated.'; fa = 'The %1 file is updated.';
										|it = 'Файл %1 обновлен.';
										|pl = 'The %1 file is updated.';
										|tr = 'Dosya %1 güncellendi.'"), Parameters.CurrentFile.Description);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.EditingFile = True; // Creates a new version of the file, but does not finish editing it.
		FileOperation.InformFormOfFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			Parameters.CurrentFile.Description,
			Parameters.CurrentFile.ID,
			Parameters.OwnerID,
			MessageText,,
			Parameters.FormUniqueID);
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, Parameters.CurrentFile);
		EndIf;
	EndIf;
	
EndProcedure

// Continuation of the procedure for obtaining the file after receiving the document flow.
//
// Parameters:
//   FilesToObtain - Array of TransferredFileDescription
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * RemainingFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//     * ForReading - Boolean - True if the files are saved for reading, and False if for editing.
//     * CallbackDescription - CallbackDescription - called by passing an array of full file names.
//     * FullFileNames - Array of String - full names of files already received.
//     * FormUniqueID - UUID - ID of the calling form.
//     * EditingInformation - See IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile.
//     * TempFilesDir - String - the directory to save the temporary file.
//     * TempFileName - String - the name under which the file will be saved.
//     * TempFileStorageAddress - String - the address where the file received from BEFORE is stored.
//
Async Procedure ProcessTheFileAfterReceivingItFrom1CDocumentManagement(Val FilesToObtain, Val Parameters) Export
	
	// We delete the file from the temporary storage after writing to disk.
	If IsTempStorageURL(Parameters.TempFileStorageAddress) Then
		DeleteFromTempStorage(Parameters.TempFileStorageAddress);
	EndIf;
	
	If TypeOf(FilesToObtain) = Type("Array") And FilesToObtain.Count() > 0 Then
		
		TempFileName = FilesToObtain[0].FullName;
		
		EditingInformation = Undefined;
		If Parameters.Property("EditingInformation", EditingInformation) Then // Let's update them.
			
			EditingInformation.Insert("Saved_", True);
			EditingInformation.Insert("FullPath", TempFileName);
			EditingInformation.Insert("SaveDate", CurrentDate()); // The use is justified: the date-time is fixed on the client.
			If Not EditingInformation.Property("ForReading") Then
				EditingInformation.Insert("ForReading", Parameters.ForReading);
			Else
				EditingInformation.ForReading = EditingInformation.ForReading And Parameters.ForReading;
			EndIf;
			EditingInformation.Insert("UniversalModificationDate", Parameters.CurrentFile.UniversalModificationDate);
			EditingInformation.Insert("Size", Parameters.CurrentFile.Size);
			
			// When saving, we pass the ID of the current version received earlier, and not the file.
			IntegrationWith1CDocumentManagementCoreServerCall.SaveFileEditingInformation(
				EditingInformation);
			
		EndIf;
		
		If Await FileSystemExtensionAttached1Async() Then
			File = New File(TempFileName);
			If ValueIsFilled(Parameters.CurrentFile.UniversalModificationDate) Then
				Await File.SetModificationUniversalTimeAsync(Parameters.CurrentFile.UniversalModificationDate);
			EndIf;
			If Parameters.ForReading Then
				Await File.SetReadOnlyAsync(True);
			EndIf;
		EndIf;
		
		Parameters.FullFileNames.Add(TempFileName);
		
	EndIf;
	
	GetFilesStarted(Parameters);
	
EndProcedure

// Continuation of the procedure for opening the file list.
//
// Parameters:
//   FileOwner - AnyRef - the source of the command, the IP object is the owner of the files.
//   OpeningParameters - See IntegrationWith1CDocumentManagementCoreClient.OptionsForOpeningListOfFiles
//
Procedure OpenAttachedFilesCompletion(FileOwner, OpeningParameters) Export
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If Settings.UseIntegrationBefore2 Then
		FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.AttachedFiles";
		If FileOwner = Undefined Then
			ShowMessageBox(, NStr("vi = 'Chưa chỉ ra đối tượng chủ của tệp trong hệ thống dược tích hợp.';
									|ru = 'Не указан владелец файла в интегрированной системе.';
									|en = 'A file owner is not specified in the integrated system.'; fa = 'A file owner is not specified in the integrated system.';
									|it = 'Не указан владелец файла в интегрированной системе.';
									|pl = 'A file owner is not specified in the integrated system.';
									|tr = 'Entegre sistemde dosyanın sahibi belirtilmemiştir.'"));
			Return;
		EndIf;
		
	ElsIf Settings.UseIntegrationBefore3 Then
		FormName = "DataProcessor.IntegrationWith1CDocumentManagement3.Form.AttachedFiles";
		
	Else
		Return;
		
	EndIf;
	
	OpeningParameters.Insert("FileOwner", FileOwner);
	
	FormOwner = OpeningParameters.FormOwner;
	OpeningParameters.Delete("FormOwner");
	
	Window = OpeningParameters.Window;
	OpeningParameters.Delete("Window");
	
	If ValueIsFilled(OpeningParameters.Uniqueness) Then
		Uniqueness = OpeningParameters.Uniqueness;
	Else
		Uniqueness = FileOwner;
	EndIf;
	
	OpenForm(
		FormName,
		OpeningParameters,
		FormOwner,
		Uniqueness,
		Window);
	
EndProcedure

// Opens files by the application after receiving them.
//
// Parameters:
//   FullFileNames - Array of String - array of full names received from UP to files.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * OwnerID - String - ID of the file owner.
//     * CallbackDescriptionOnCompletion - CallbackDescription - called on successful End.
//                                     - Undefined - there is no need to call anything.
//     * FormUniqueID - UUID - ID of the calling form.
//     * ForReading - Boolean
//
Procedure OpenFilesAfterReceiving(FullFileNames, Parameters) Export
	
	For Each FullFileName In FullFileNames Do
		OpenFileWithApplication(FullFileName);
	EndDo;
	
	If Parameters.ForReading = False Then
		MessageText = StrTemplate(NStr("vi = 'Bắt đầu soạn tệp %1.';
										|ru = 'Начато редактирование файла %1.';
										|en = 'Started editing the %1 file.'; fa = 'Started editing the %1 file.';
										|it = 'Начато редактирование файла %1.';
										|pl = 'Started editing the %1 file.';
										|tr = 'Dosya düzenleme başladı %1.'"), Parameters.CurrentFile.Description);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.EditingFile = True;
		FileOperation.InformFormOfFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			Parameters.CurrentFile.Description,
			Parameters.CurrentFile.ID,
			Parameters.OwnerID,
			MessageText,,
			Parameters.FormUniqueID);
	EndIf;
	
	If TypeOf(Parameters) = Type("Structure")
			And Parameters.Property("CallbackDescriptionOnCompletion")
			And Parameters.CallbackDescriptionOnCompletion <> Undefined Then
		RunCallback(Parameters.CallbackDescriptionOnCompletion, Parameters.CurrentFile);
	EndIf;
	
EndProcedure

// Called during the receipt of the file after selecting the source: take from BEFORE or use an existing one.
//
// Parameters:
//   Result - String - "Take from document management" or "Use existing".
//             - Undefined - if the user refused the choice.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * RemainingFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//     * ForReading - Boolean - True if the files are saved for reading, and False if for editing.
//     * CallbackDescription - CallbackDescription - called by passing an array of full file names.
//     * FullFileNames - Array of String - full names of files already received.
//     * FormUniqueID - UUID - ID of the calling form.
//     * EditingInformation - See IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile.
//     * TempFilesDir - String - the directory to save the temporary file.
//     * TempFileName - String - the name under which the file will be saved.
//     * UpdateEditInformation - Boolean
//
Async Procedure RetrievingFileAfterSelectingSource(Val Result, Val Parameters) Export
	
	If Not ValueIsFilled(Result) Then // Cancel.
		Return;
	EndIf;
	
	If Result = "TakeFromThe1CDocumentManagement" Then
		
		// Get the file from BEFORE on the server.
		UseVisualizationOfItemInstanceStamp = True;
		If ValueIsFilled(Parameters.CurrentFile.RefToBinaryFileData)
				And IsTempStorageURL(Parameters.CurrentFile.RefToBinaryFileData) Then
			Address = Parameters.CurrentFile.RefToBinaryFileData;
		ElsIf Parameters.CurrentFile.Type = "DMFile" Then
			Address = IntegrationWith1CDocumentManagementCoreServerCall.GetFileAndPutItInStorage(
				Parameters.CurrentFile.ID,
				UseVisualizationOfItemInstanceStamp,
				Parameters.FormUniqueID,
				?(Parameters.ForReading, Undefined, CurrentDate()), // The use is justified: the date-time is fixed on the client.
				Parameters.CurrentFile);
		ElsIf Parameters.CurrentFile.Type = "DMFileVersion" Then
			Address = IntegrationWith1CDocumentManagementCoreServerCall.GetVersionOfFileAndPutItInRepository(
				Parameters.CurrentFile.ID,
				UseVisualizationOfItemInstanceStamp,
				Parameters.FormUniqueID,
				Parameters.CurrentFile);
		Else
			Raise StrTemplate(NStr("vi = 'Kiểu tệp không xác định: %1';
									|ru = 'Неизвестный тип файла: %1';
									|en = 'Unknown file type: %1'; fa = 'Unknown file type: %1';
									|it = 'Unknown file type: %1';
									|pl = 'Unknown file type: %1';
									|tr = 'Bilinmeyen dosya türü: %1'"), Parameters.CurrentFile.Type);
		EndIf;
		CheckFileEncryption(Parameters.CurrentFile);
		Parameters.Insert("TempFileStorageAddress", Address);
		
		File = New File(Parameters.TempFileName);
		Try
			Await File.SetReadOnlyAsync(False);
		Except
			ShowMessageBox(,
				NStr("vi = 'Không thể thay thế tệp trên đĩa bởi tệp từ 1C:Document Management.
					|Có thể là tệp đó đã bị phong tỏa bởi ứng dụng khác.';
					|ru = 'Не удалось заменить файл на диске файлом из 1С:Документооборота.
					|Возможно, он заблокирован другим приложением.';
					|en = 'Cannot replace a file on the disk with the file from 1C:Document Management.
					|Maybe, it is locked by another application.'; fa = 'Cannot replace a file on the disk with the file from 1C:Document Management.
					|Maybe, it is locked by another application.';
					|it = 'Non è stato possibile sostituire il file su disco con il file da 1C:Document Management.
					|Probabilmente è bloccato da un''altra applicazione.';
					|pl = 'Nie udało się zastąpić pliku na dysku plikiem z 1C:Document Management.
					|Możliwe, że jest on zablokowany przez inną aplikacją.';
					|tr = 'Diskteki dosya, 1C:Document Management''tan bir dosyayla değiştirilemedi.
					|Başka bir uygulama tarafından engellenmiş olabilir.'"));
			Return;
		EndTry;
		
		ReceivingFileAfterReceivingFrom1CDocumentManagement(Parameters);
		
	ElsIf Result = "UseExistingOne" Then
		
		If Parameters.EditingInformation.ForReading And Not Parameters.ForReading Then
			Parameters.EditingInformation.ForReading = False;
			Parameters.UpdateEditInformation = True;
			File = New File(Parameters.TempFileName);
			Try
				Await File.SetReadOnlyAsync(False);
			Except
				ShowMessageBox(,
					NStr("vi = 'Không thể mở tệp để chỉnh sửa. Có thể là,
						|tệp đã bị phong tỏa bởi ứng dụng khác.';
						|ru = 'Не удалось открыть файл для редактирования. Возможно,
						|он заблокирован другим приложением.';
						|en = 'Cannot open the file to edit.
						|It might be locked by another application.'; fa = 'Cannot open the file to edit.
						|It might be locked by another application.';
						|it = 'Не удалось открыть файл для редактирования. Возможно,
						|он заблокирован другим приложением.';
						|pl = 'Cannot open the file to edit.
						|It might be locked by another application.';
						|tr = 'Düzenleme için dosya açılamadı. Başka,
						|bir uygulama tarafından engellenmiş olabilir.'"));
				GetFilesStarted(Parameters);
			EndTry;
			IntegrationWith1CDocumentManagementCoreServerCall.CaptureFile(
				Parameters.CurrentFile.ID,
				CurrentDate()); // The use is justified: the date-time is fixed on the client.
		EndIf;
		If Parameters.UpdateEditInformation Then
			IntegrationWith1CDocumentManagementCoreServerCall.SaveFileEditingInformation(
				Parameters.EditingInformation);
		EndIf;
		
		Parameters.FullFileNames.Add(Parameters.TempFileName);
		GetFilesStarted(Parameters);
		
	EndIf;
	
EndProcedure

// Called after entering a comment on the file version.
//
// Parameters:
//   Result - DialogReturnCode - the user's response.
//   Parameters - Structure:
//     * NotificationAfterPlacingFile - CallbackDescription - description of the procedure
//         that will be called if the files are successfully placed.
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * OwnerID - String - ID of the file owner.
//     * FormUniqueID - UUID - ID of the calling form.
//     * EditingInformation - See IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile.
//     * File - File - the file being placed in the working directory.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Procedure AfterEnteringDescriptionOfChangesMade(Result, Parameters) Export
	
	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	NotificationAfterPlacingFile = Parameters.NotificationAfterPlacingFile;
	Parameters.Delete("NotificationAfterPlacingFile");
	
	Try
		ImportParameters = FileSystemClient.FileImportParameters();
		ImportParameters.Interactively = False;
		ImportParameters.FormIdentifier = Parameters.FormUniqueID;
		FileSystemClient.ImportFile_(
			NotificationAfterPlacingFile,
			ImportParameters,
			Parameters.EditingInformation.FullPath);
	Except
		WarningText = StrTemplate(
			NStr("vi = 'Không thể lưu các thay đổi do nguyên nhân:
				|%1';
				|ru = 'Не удалось сохранить изменения по причине:
				|%1';
				|en = 'Cannot save changes due to:
				|%1'; fa = 'Cannot save changes due to:
				|%1';
				|it = 'Non è stato possibile salvare le modifiche a causa di:
				|%1';
				|pl = 'Nie udało się zapisać zmiany z powodu:
				|%1';
				|tr = 'Bu nedenlerle değişiklikler kaydedilemedi:
				|%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		ShowMessageBox(, WarningText);
	EndTry;
	
EndProcedure

// Continuation of the save procedure after selecting the source.
//
// Parameters:
//   FilesToObtain - Array of TransferredFileDescription
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * RemainingFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//     * FormUniqueID - UUID - ID of the calling form.
//     * FullPath - String - the full path to the file in the directory selected by the user.
//     * FullFileName - String - the full path to the file in the directory selected by the user.
//     * Directory - String - the directory where you want to save the files.
//     * TempFileName - String - name of the temporary file.
//     * FileDialogMode - FileDialogMode - file selection dialog mode.
//     * ReceivingMode - String - receiving mode.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Async Procedure ContinueSaveAsAfterSelectingSource(Val FilesToObtain, Val Parameters) Export
	
	If TypeOf(FilesToObtain) = Type("Array") And FilesToObtain.Count() > 0 Then
		FullPath = FilesToObtain[0].FullName;
		If Parameters.ReceivingMode = "TakeFromThe1CDocumentManagement" Then
			DeleteFromTempStorage(Parameters.TempFileStorageAddress);
			If Await FileSystemExtensionAttached1Async()
					And ValueIsFilled(Parameters.CurrentFile.UniversalModificationDate) Then
				File = New File(FullPath);
				Await File.SetModificationUniversalTimeAsync(Parameters.CurrentFile.UniversalModificationDate);
			EndIf;
		EndIf;
		Status(NStr("vi = 'Đã lưu lại tệp.';
					|ru = 'Файл сохранен.';
					|en = 'File is saved.'; fa = 'File is saved.';
					|it = 'File salvato.';
					|pl = 'Plik został zapisany.';
					|tr = 'Dosya kaydedildi.'"),, FullPath);
	EndIf;
	
	If Parameters.RemainingFiles.Count() <> 0 And ValueIsFilled(Parameters.Directory) Then
		FillPropertyValues(Parameters.CurrentFile, Parameters.RemainingFiles[0]);
		SelectedFiles = CommonClientServer.ValueInArray(Parameters.Directory);
		Parameters.RemainingFiles.Delete(0);
		SaveAsAfterFileSelectionDialog(SelectedFiles, Parameters);
	ElsIf Parameters.CallbackDescription <> Undefined Then
		RunCallback(Parameters.CallbackDescription, Parameters);
	EndIf;
	
EndProcedure

// It is performed during the creation of a file from disk after connecting the extension.
//
// Parameters:
//   Attached - Boolean - True if the extension is enabled.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * Owner - AnyRef - file owner.
//     * OwnerID - String - ID of the file owner in the Document Flow.
//     * OwnerType - String - the XDTO type of the file owner in the Document Flow.
//     * OwnerPresentation - String - representation of the file owner.
//     * FullFileNames - Array of String - the names of the added files.
//     * PlacedFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * IsScannedCopy - Boolean - a sign of a scanned copy.
//     * FormUniqueID - UUID - ID of the calling form.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Procedure CreateFileFromDiskAfterConnectingExtension(Attached, Parameters) Export
	
	If Attached Then
		
		SelectingFile = New FileDialog(FileDialogMode.Open);
		SelectingFile.Multiselect = True;
		If Parameters.IsScannedCopy Then
			SelectingFile.Title = NStr("vi = 'Chọn bản sao scan của bản gốc văn bản';
										|ru = 'Выбор скан-копии оригинала документа';
										|en = 'Select the scanned copy of the original document'; fa = 'Select the scanned copy of the original document';
										|it = 'Выбор скан-копии оригинала документа';
										|pl = 'Select the scanned copy of the original document';
										|tr = 'Orijinal belgenin tarama kopyası seçimi'");
			
			ExtensionsString = "";
			FilterByExtensions = "";
			SettingsBefore = IntegrationWith1CDocumentManagementCoreClientCached.GetSettings();
			ListOfExtensionsOfScannedCopiesOfOriginals = SettingsBefore.ListOfExtensionsOfScannedCopiesOfOriginals;
			ListOfExtensionsOfScannedCopiesOfOriginals = StrReplace(ListOfExtensionsOfScannedCopiesOfOriginals, " ", ",");
			ListOfExtensionsOfScannedCopiesOfOriginals = StrReplace(ListOfExtensionsOfScannedCopiesOfOriginals, ";", ",");
			ArrayOfScannedCopyExtensions = StrSplit(ListOfExtensionsOfScannedCopiesOfOriginals, ",", False);
			For Each Extension In ArrayOfScannedCopyExtensions Do
				ExtensionsString = ExtensionsString + Extension + ", ";
				FilterByExtensions = FilterByExtensions + "*." + Extension + ";";
			EndDo;
			
			If ValueIsFilled(ExtensionsString) Then
				ExtensionsString = Left(ExtensionsString, StrLen(ExtensionsString) - 2);
				FilterByExtensions = Left(FilterByExtensions, StrLen(FilterByExtensions) - 1);
				SelectingFile.Filter = StrTemplate(NStr("vi = 'Bản sao scan (%1)|%2|Tất cả tệp (*.*)|*.*';
														|ru = 'Скан-копии (%1)|%2|Все файлы (*.*)|*.*';
														|en = 'Scanned copies (%1)|%2|All files (*.*)|*.*'; fa = 'Scanned copies (%1)|%2|All files (*.*)|*.*';
														|it = 'Скан-копии (%1)|%2|Все файлы (*.*)|*.*';
														|pl = 'Scanned copies (%1)|%2|All files (*.*)|*.*';
														|tr = 'Tarama dosyaları (%1)|%2| Tüm dosyalar (*.*)|*.*'"),
					ExtensionsString, FilterByExtensions);
			Else
				SelectingFile.Filter = GetFilterForFileSelectionDialog();
			EndIf;
		Else
			SelectingFile.Title = NStr("vi = 'Chọn tệp';
										|ru = 'Выбор файла';
										|en = 'Select file'; fa = 'انتخاب فایل';
										|it = 'Selezione del file';
										|pl = 'Wybór pliku';
										|tr = 'Dosya seçimi'");
			SelectingFile.Filter = GetFilterForFileSelectionDialog();
		EndIf;
		SelectingFile.Show(
			New CallbackDescription(
				"CreateFilesFromAsyncDisk",
				IntegrationWith1CDocumentManagementCoreClient,
				Parameters));
		
	Else // Web client without extension.
		
		Try
			ImportParameters = FileSystemClient.FileImportParameters();
			ImportParameters.FormIdentifier = Parameters.FormUniqueID;
			FileSystemClient.ImportFile_(
				New CallbackDescription(
					"CreateFileFromDiskAfterPlacingFileWithoutExtension",
					IntegrationWith1CDocumentManagementCoreClient,
					Parameters),
				ImportParameters);
		Except
			WarningText = StrTemplate(
				NStr("vi = 'Không thể tạo mới tệp do nguyên nhân:
					|%1';
					|ru = 'Не удалось создать файл по причине:
					|%1';
					|en = 'Cannot create file because:
					|%1'; fa = 'Cannot create file because:
					|%1';
					|it = 'Non è stato possibile creare il file a causa di:
					|%1';
					|pl = 'Nie udało się utworzyć pliku z powodu:
					|%1';
					|tr = 'Dosya bu nedenlerle oluşturulamadı:
					|%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			ShowMessageBox(, WarningText);
		EndTry;
		
	EndIf;
	
EndProcedure

// It is performed during the creation of a file from disk after placing the file (thin and web with the extension).
//
// Parameters:
//   FileThatWasPut - Structure - if the file is placed in the repository:
//     * Location - String - The address of the file data in the temporary storage.
//     * Name - String - the full path to the placed file.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * File - File - initialized file.
//     * Owner - AnyRef - file owner.
//     * OwnerID - String - ID of the file owner in the Document Flow.
//     * OwnerType - String - the XDTO type of the file owner in the Document Flow.
//     * OwnerPresentation - String - representation of the file owner.
//     * FullFileName - String - the full name of the file selected by the user.
//     * FullFileNames - Array of String - the names of the added files.
//     * PlacedFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * IsScannedCopy - Boolean - a sign of a scanned copy.
//     * FormUniqueID - UUID - ID of the calling form.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Async Procedure CreateFileFromDiskAfterPlacingFile(Val FileThatWasPut, Val Parameters) Export
	
	Status();
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Parameters.Insert("TempFileStorageAddress", FileThatWasPut.Location);
	
	If Parameters.Property("DeleteFileAfterPut") And Parameters.DeleteFileAfterPut Then
		BeginDeletingFiles(New CallbackDescription, Parameters.File.FullName);
		Parameters.File = Undefined;
	EndIf;
	
	Settings1CDocumentManagement = IntegrationWith1CDocumentManagementCoreClientCached.GetSettings();
	If Settings1CDocumentManagement.NeedToExtractText Then
		Parameters.CurrentFile.Text = Await ExtractText1Async(Parameters.FullFileName);
	EndIf;
	
	CreateFileFromDiskCompletion(Parameters);
	
EndProcedure

// It is performed during the creation of a file from disk after placing the file (web without extension).
//
// Parameters:
//   FileThatWasPut - Structure - if the file is placed in the repository:
//     * Location - String - The address of the file data in the temporary storage.
//     * Name - String - the full path to the placed file.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * Owner - AnyRef - file owner.
//     * OwnerID - String - ID of the file owner in the Document Flow.
//     * OwnerType - String - the XDTO type of the file owner in the Document Flow.
//     * OwnerPresentation - String - representation of the file owner.
//     * FullFileNames - Array of String - the names of the added files.
//     * PlacedFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * IsScannedCopy - Boolean - a sign of a scanned copy.
//     * FormUniqueID - UUID - ID of the calling form.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Procedure CreateFileFromDiskAfterPlacingFileWithoutExtension(FileThatWasPut, Parameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Parameters.Insert("TempFileStorageAddress", FileThatWasPut.Location);
	Parameters.Insert("FullFileName", FileThatWasPut.Name);
	
	File = New File(FileThatWasPut.Name);
	Parameters.Insert("File", File);
	
	CreateFileFromDiskCompletion(Parameters);
	
EndProcedure

// It is performed during the creation of a file from a disk after the file selection dialog, or after dragging and dropping files.
//
// Parameters:
//   SelectedFiles - Array of String - full names of the selected files.
//                  - Undefined - if the user refused the choice.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * Owner - AnyRef - file owner.
//     * OwnerID - String - ID of the file owner in the Document Flow.
//     * OwnerType - String - the XDTO type of the file owner in the Document Flow.
//     * OwnerPresentation - String - representation of the file owner.
//     * FullFileNames - Array of String - full names of the added files.
//     * PlacedFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * IsScannedCopy - Boolean - a sign of a scanned copy.
//     * FormUniqueID - UUID - ID of the calling form.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Async Procedure CreateFilesFromAsyncDisk(Val SelectedFiles, Val Parameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Parameters.FullFileNames = SelectedFiles;
	Parameters.Insert("FullFileName", Parameters.FullFileNames[0]);
	Parameters.FullFileNames.Delete(0);
	
	Parameters.Insert("File", New File(Parameters.FullFileName));
	
	SettingsBefore = IntegrationWith1CDocumentManagementCoreClientCached.GetSettings();
	ListOfScanCopyExtensions = SettingsBefore.ListOfExtensionsOfScannedCopiesOfOriginals;
	ThisIsExtensionOfScannedCopy = IntegrationWith1CDocumentManagementCoreClientServer.ThisIsExtensionOfScannedCopy(
		Parameters.File.Extension,
		ListOfScanCopyExtensions);
	Parameters.IsScannedCopy = Parameters.IsScannedCopy Or ThisIsExtensionOfScannedCopy;
	
	If Parameters.IsScannedCopy And Not IsBlankString(ListOfScanCopyExtensions) And Not ThisIsExtensionOfScannedCopy Then
		WarningText = StrTemplate(
			NStr("ru = 'Файл ""%1"" не является скан-копией. Выберите файл с расширением: %2.';
				|vi = 'The %1 file is not a scanned copy. Select a file with the extension: %2.';
				|en = 'The %1 file is not a scanned copy. Select a file with the extension: %2.'; fa = 'The %1 file is not a scanned copy. Select a file with the extension: %2.';
				|it = 'Файл ""%1"" не является скан-копией. Выберите файл с расширением: %2.';
				|pl = 'The %1 file is not a scanned copy. Select a file with the extension: %2.';
				|tr = 'Dosya ""%1"" tarama kopyası değil. Uzantıya sahip dosyayı seçin: %2.'"),
			Parameters.File.Name,
			ListOfScanCopyExtensions);
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	Parameters.CurrentFile.Size = Await Parameters.File.SizeAsync();
	
	MaxFileSize1 =
		IntegrationWith1CDocumentManagementCoreClientCached.MaximumFileSize_();
	
	WarningText = "";
	If IntegrationWith1CDocumentManagementCoreClientServer.FileSizeExceedsMaximumAllowed(
			MaxFileSize1, Parameters.CurrentFile.Size, Parameters.FullFileName, False, WarningText) Then
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	Parameters.CurrentFile.ModificationDate = Await Parameters.File.GetModificationTimeAsync();
	Parameters.CurrentFile.UniversalModificationDate = Await Parameters.File.GetModificationUniversalTimeAsync();
	
	ExplanationText = StrTemplate(NStr("vi = 'Đang lưu tệp ""%1"" (%2). Xin vui lòng đợi...';
										|ru = 'Идет сохранение файла ""%1"" (%2). Пожалуйста, подождите...';
										|en = 'Saving the ""%1"" file (%2). Please wait...'; fa = 'Saving the ""%1"" file (%2). Please wait...';
										|it = 'Salvataggio del file ""%1"" (%2). Attendere...';
										|pl = 'Trwa zapisywanie pliku ""%1"" (%2). Proszę czekać...';
										|tr = 'Dosya kaydediliyor ""%1"" (%2). Lütfen bekleyin...'"),
		Parameters.FullFileName,
		IntegrationWith1CDocumentManagementCoreClientServer.BriefSizePresentation(
			Parameters.CurrentFile.Size));
	Status(ExplanationText);
	
	Try
		ImportParameters = FileSystemClient.FileImportParameters();
		ImportParameters.Interactively = False;
		ImportParameters.FormIdentifier = Parameters.FormUniqueID;
		FileSystemClient.ImportFile_(
			New CallbackDescription(
				"CreateFileFromDiskAfterPlacingFile",
				IntegrationWith1CDocumentManagementCoreClient,
				Parameters),
			ImportParameters,
			Parameters.FullFileName);
	Except
		WarningText = StrTemplate(
			NStr("vi = 'Không thể tạo tệp do nguyên nhân:
				|%1';
				|ru = 'Не удалось создать файл по причине:
				|%1';
				|en = 'Cannot create file because:
				|%1'; fa = 'Cannot create file because:
				|%1';
				|it = 'Non è stato possibile creare il file a causa di:
				|%1';
				|pl = 'Nie udało się utworzyć pliku z powodu:
				|%1';
				|tr = 'Dosya bu nedenlerle oluşturulamadı:
				|%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		ShowMessageBox(, WarningText);
	EndTry;
	
EndProcedure

// Performs file release in BEFORE after user permission.
//
// Parameters:
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * OwnerID - String - ID of the file owner.
//     * FormUniqueID - UUID - ID of the calling form.
//     * EditingInformation - See IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile.
//     * File - File - the file being placed in the working directory.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Procedure SaveChangesWithExtensionAfterReleaseQuestion(Parameters)
	
	IntegrationWith1CDocumentManagementCoreServerCall.UnlockFile(Parameters.CurrentFile.ID);
	
	// Delete the information about editing the file.
	EditingInformation = Parameters.EditingInformation;
	EditingInformation.Saved_ = False;
	IntegrationWith1CDocumentManagementCoreServerCall.SaveFileEditingInformation(
		EditingInformation);
	
	MessageText = StrTemplate(NStr("vi = 'Đã lưu các thay đổi tệp %1.';
									|ru = 'Изменения файла %1 сохранены.';
									|en = 'The %1 file changes are saved.'; fa = 'The %1 file changes are saved.';
									|it = 'Изменения файла %1 сохранены.';
									|pl = 'The %1 file changes are saved.';
									|tr = 'Dosya değişiklikleri %1 kaydedildi.'"), Parameters.CurrentFile.Description);
	FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
	FileOperation.FileEditingIsComplete = True;
	FileOperation.InformFormOfFile = True;
	FileOperation.InformFileListForm = True;
	InformAboutFileChanges(
		FileOperation,
		Parameters.CurrentFile.Description,
		Parameters.CurrentFile.ID,
		Parameters.OwnerID,
		MessageText,,
		Parameters.FormUniqueID);
	
	If Parameters.CallbackDescription <> Undefined Then
		RunCallback(Parameters.CallbackDescription, Parameters.CurrentFile);
	EndIf;
	
EndProcedure

// Completes saving changes to BEFORE without using the file extension.
//
// Parameters:
//   FileThatWasPut - Structure - if the file is placed in the repository:
//     * Location - String - The address of the file data in the temporary storage.
//     * Name - String - the full path to the placed file.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * OwnerID - String - ID of the file owner.
//     * FormUniqueID - UUID - ID of the calling form.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Procedure SaveChangesWithoutExpandingAfterPlacement(FileThatWasPut, Parameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Parameters.Insert("TempFileStorageAddress", FileThatWasPut.Location);
	Parameters.Insert("UnlockFile", False);
	Parameters.Insert("UpdateEditInformation", True);
	
	// Get the extension: it could have changed.
	NameStructure = ParseFullFileName(FileThatWasPut.Name);
	Parameters.CurrentFile.Extension = NameStructure.Extension;
	
	// We will delete the parameters that cannot and do not need to be transmitted to the server.
	CallbackDescription = Parameters.CallbackDescription;
	Parameters.Delete("CallbackDescription");
	
	If IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileWithBinaryTemporaryStorageData(
			Parameters) Then
		MessageText = StrTemplate(NStr("vi = 'Đã lưu các thay đổi tệp %1.';
										|ru = 'Изменения файла %1 сохранены.';
										|en = 'The %1 file changes are saved.'; fa = 'The %1 file changes are saved.';
										|it = 'Изменения файла %1 сохранены.';
										|pl = 'The %1 file changes are saved.';
										|tr = 'Dosya değişiklikleri %1 kaydedildi.'"), Parameters.CurrentFile.Description);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.EditingFile = True; // Creates a new version of the file, but does not finish editing it.
		FileOperation.InformFormOfFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			Parameters.CurrentFile.Description,
			Parameters.CurrentFile.ID,
			Parameters.OwnerID,
			MessageText,,
			Parameters.FormUniqueID);
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, Parameters.CurrentFile);
		EndIf;
	EndIf;
	
EndProcedure

// Completes saving changes to BEFORE using the file extension.
//
// Parameters:
//   FileThatWasPut - Structure - if the file is placed in the repository:
//     * Location - String - The address of the file data in the temporary storage.
//     * Name - String - the full path to the placed file.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * OwnerID - String - ID of the file owner.
//     * FormUniqueID - UUID - ID of the calling form.
//     * EditingInformation - See IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile.
//     * File - File - the file being placed in the working directory.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Async Procedure SaveChangesWithExtensionAfterPlacement(Val FileThatWasPut, Val Parameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Parameters.Insert("TempFileStorageAddress", FileThatWasPut.Location);
	Parameters.Insert("UnlockFile", False);
	Parameters.Insert("UpdateEditInformation", True);
	
	// Extract the text, if necessary.
	Settings1CDocumentManagement = IntegrationWith1CDocumentManagementCoreClientCached.GetSettings();
	If Settings1CDocumentManagement.NeedToExtractText Then
		ExtractedText = Await ExtractText1Async(Parameters.EditingInformation.FullPath);
		Parameters.CurrentFile.Text = ExtractedText;
	EndIf;
	
	// We will delete the parameters that cannot and do not need to be transmitted to the server.
	CallbackDescription = Parameters.CallbackDescription;
	Parameters.Delete("CallbackDescription");
	Parameters.Delete("File");
	
	If IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileWithBinaryTemporaryStorageData(
			Parameters) Then
		MessageText = StrTemplate(NStr("vi = 'Đã lưu các thay đổi tệp %1.';
										|ru = 'Изменения файла %1 сохранены.';
										|en = 'The %1 file changes are saved.'; fa = 'The %1 file changes are saved.';
										|it = 'Изменения файла %1 сохранены.';
										|pl = 'The %1 file changes are saved.';
										|tr = 'Dosya değişiklikleri %1 kaydedildi.'"), Parameters.CurrentFile.Description);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.EditingFile = True; // Creates a new version of the file, but does not finish editing it.
		FileOperation.InformFormOfFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			Parameters.CurrentFile.Description,
			Parameters.CurrentFile.ID,
			Parameters.OwnerID,
			MessageText,,
			Parameters.FormUniqueID);
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, Parameters.CurrentFile);
		EndIf;
	EndIf;
	
EndProcedure

// Called during saving a file to disk after selecting the source (or in the absence of a file on disk).
//
// Parameters:
//   Result - String - if "Take from the document flow", then take the file from BEFORE, if "use existing",
//     then take the file from the temporary directory.
//             - Undefined - do nothing.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * RemainingFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//     * FormUniqueID - UUID - ID of the calling form.
//     * FullPath - String - the full path to the file in the directory selected by the user.
//     * FullFileName - String - the full path to the file in the directory selected by the user.
//     * Directory - String - the directory where you want to save the files.
//     * TempFileName - String - name of the temporary file.
//     * FileDialogMode - FileDialogMode - file selection dialog mode.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Async Procedure SaveAsAfterSelectingSource(Val Result, Val Parameters) Export
	
	If Not ValueIsFilled(Result) Then // Cancel.
		Return;
	EndIf;
	
	File = New File(Parameters.FullPath);
	If Await File.ExistsAsync() Then
		Await File.SetReadOnlyAsync(False);
		Await DeleteFilesAsync(Parameters.FullPath);
	EndIf;
	
	Parameters.Insert("ReceivingMode", Result);
	
	If Result = "TakeFromThe1CDocumentManagement" Then
		
		// Get the file from BEFORE on the server.
		If ValueIsFilled(Parameters.CurrentFile.RefToBinaryFileData)
				And IsTempStorageURL(Parameters.CurrentFile.RefToBinaryFileData) Then
			Address = Parameters.CurrentFile.RefToBinaryFileData;
		ElsIf Parameters.CurrentFile.Type = "DMFile" Then
			Address = IntegrationWith1CDocumentManagementCoreServerCall.GetFileAndPutItInStorage(
				Parameters.CurrentFile.ID,
				Parameters.UseVisualizationOfItemInstanceStamp,
				Parameters.FormUniqueID,,
				Parameters.CurrentFile);
		ElsIf Parameters.CurrentFile.Type = "DMFileVersion" Then
			Address = IntegrationWith1CDocumentManagementCoreServerCall.GetVersionOfFileAndPutItInRepository(
				Parameters.CurrentFile.ID,
				Parameters.UseVisualizationOfItemInstanceStamp,
				Parameters.FormUniqueID,
				Parameters.CurrentFile);
		Else
			Raise StrTemplate(NStr("vi = 'Kiểu tệp không xác định: %1';
									|ru = 'Неизвестный тип файла: %1';
									|en = 'Unknown file type: %1'; fa = 'Unknown file type: %1';
									|it = 'Unknown file type: %1';
									|pl = 'Unknown file type: %1';
									|tr = 'Bilinmeyen dosya türü: %1'"), Parameters.CurrentFile.Type);
		EndIf;
		Parameters.Insert("TempFileStorageAddress", Address);
		
		// Let's collect a description of the received file and get it.
		FilesToObtain = New Array;
		LongDesc = New TransferableFileDescription(
			Parameters.FullPath,
			Parameters.TempFileStorageAddress);
		FilesToObtain.Add(LongDesc);
		
		SavingParameters = FileSystemClient.FileSavingParameters();
		SavingParameters.Interactively = False;
		FileSystemClient.SaveFile(
			New CallbackDescription(
				"ContinueSaveAsAfterSelectingSource",
				IntegrationWith1CDocumentManagementCoreClient,
				Parameters),
			Parameters.TempFileStorageAddress,
			Parameters.FullPath,
			SavingParameters);
		
	ElsIf Result = "UseExistingOne" Then
		
		Try
			Await CopyFileAsync(Parameters.TempFileName, Parameters.FullPath);
			File = New File(Parameters.FullPath);
			Await File.SetReadOnlyAsync(False);
		Except
			Info = ErrorInfo();
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể sao chép tệp (""%1"").';
					|ru = 'Не удалось скопировать файл (""%1"").';
					|en = 'Cannot copy file (""%1"").'; fa = 'Cannot copy file (""%1"").';
					|it = 'Non è stato possibile copiare il file (""%1"").';
					|pl = 'Nie udało się skopiować pliku (""%1"").';
					|tr = 'Dosya kopyalanmadı (""%1"").'"),
				ErrorProcessing.BriefErrorDescription(Info));
			ShowMessageBox(, WarningText);
			Return;
		EndTry;
		
		ContinueSaveAsAfterSelectingSource(FilesToObtain, Parameters);
		
	EndIf;
	
EndProcedure

// Called during file saving after the user selects the directory and name.
//
// Parameters:
//   Result - Array of String - array with the file name, if the file is selected.
//             - String - if a directory is selected.
//             - Undefined - if the user refused the choice.
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * RemainingFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//     * FormUniqueID - UUID - ID of the calling form.
//     * FileDialogMode - FileDialogMode - file selection dialog mode.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Async Procedure SaveAsAfterFileSelectionDialog(Val Result, Val Parameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		Result = Result[0];
	EndIf;
	
	If Parameters.FileDialogMode = FileDialogMode.Save Then
		Parameters.Insert("FullPath", Result);
	Else
		Parameters.Insert("Directory", Result);
		Parameters.Insert("FullPath", Parameters.Directory + GetPathSeparator() + Parameters.CurrentFile.FileName);
	EndIf;
	
	Parameters.Insert("FullFileName", Parameters.FullPath); // The Full file name parameter is used in BSP methods.
	
	If IntegrationWith1CDocumentManagementCoreClientCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1")
			And Parameters.CurrentFile.Type <> "DMFileVersion"
			And Parameters.CurrentFile.Type <> "DMIncomingElectronicDocument"
			And Parameters.CurrentFile.Type <> "DMOutgoingElectronicDocument" Then
		
		EditingInformation =
			IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile(
				Parameters.CurrentFile.ID,
				Parameters.CurrentFile.Type);
		
		If Await NeedChoiceOfActionsWhenFileDifferencesAreDetectedAsync(
				EditingInformation,
				Parameters,
				"SaveAsAfterSelectingSource",
				False) Then
			Return;
		EndIf;
		
	EndIf;
	
	// There is no choice: the file must be obtained from BEFORE.
	CallbackDescription = New CallbackDescription(
		"SaveAsAfterSelectingSource",
		ThisObject,
		Parameters);
	RunCallback(CallbackDescription, "TakeFromThe1CDocumentManagement");
	
EndProcedure

#EndRegion

#Region NotificationProcessingElectronicSignatures

Procedure StartAddingItemsFromFileCompletion(Result, NotificationParameters) Export
	
	DataDetails = Result.DataDetails;
	
	If Not DataDetails.Property("Signatures") Then
		Return;
	EndIf;
	
	FileProperties = NotificationParameters.FileProperties;
	Signatures = DataDetails.Signatures;
	
	If TypeOf(Signatures) <> Type("Array") Or Signatures.Count() = 0 Then
		Return;
	EndIf;
	
	SignaturesArray = New Array;
	For Each Signature In Signatures Do
		If TypeOf(Signature) = Type("String") Then
			SignatureProperties = GetFromTempStorage(Signature);
		Else
			SignatureProperties = Signature;
		EndIf;
		SignaturesArray.Add(
			SignatureData(
				SignatureProperties.Signature,
				SignatureProperties.Certificate,
				SignatureProperties));
	EndDo;
	CommonClientServer.SupplementArray(SignaturesArray, FileProperties.FileSignatureData);
	
	IntegrationWith1CDocumentManagementCoreServerCall.EnterInformationAboutItemSignatures(
		FileProperties.FileName,
		FileProperties.FileID,
		"DMFile",
		FileProperties.Encrypted,
		SignaturesArray);
	
	If SignaturesArray.Count() = 1 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã thêm chữ ký từ tệp đối với ""%1""';
				|ru = 'Добавлена подпись из файла для ""%1""';
				|en = 'The signature from file was added for ""%1""'; fa = 'The signature from file was added for ""%1""';
				|it = 'Aggiunta firma da file per ""%1""';
				|pl = 'Dodano podpis z pliku dla ""%1""';
				|tr = '""%1"" için dosyadan imza eklendi'"), FileProperties.FileName);
	Else
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã thêm các chữ ký từ tệp đối với ""%1""';
				|ru = 'Добавлены подписи из файлов для ""%1""';
				|en = 'Signatures from files were added for ""%1""'; fa = 'Signatures from files were added for ""%1""';
				|it = 'Aggiunte firme da file per ""%1""';
				|pl = 'Dodano podpisy z plików dla ""%1""';
				|tr = '""%1"" için dosyadan imzalar eklendi'"), FileProperties.FileName);
	EndIf;
	FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
	FileOperation.AddingItemInstanceFile = True;
	FileOperation.InformFormOfFile = True;
	FileOperation.InformFileListForm = True;
	InformAboutFileChanges(
		FileOperation,
		FileProperties.FileName,
		FileProperties.FileID,
		FileProperties.FileOwner,
		MessageText,,
		FileProperties.FormUniqueID);
	
	RunCallback(Result.Notification, New Structure);
	
EndProcedure

// Called during adding a signature from a file after connecting the extension.
//
// Parameters:
//   Attached - Boolean
//   Parameters - Structure:
//     * FileProperties - See IntegrationWith1CDocumentManagementCoreClientServer.FileProperties
//
Procedure StartAddingItemsFromFileAfterEnablingExtension(Attached, Parameters) Export
	
	If Not Attached Then
		ShowMessageBox(, NStr("vi = 'Để thực hiện giao dịch, cần cài đặt phần mở rộng làm việc với tệp.';
								|ru = 'Для выполнения операции нужно установить расширение работы с файлами.';
								|en = 'To perform the operation, install 1C:Enterprise Extension.'; fa = 'To perform the operation, install 1C:Enterprise Extension.';
								|it = 'Per l''esecuzione dell''operazione è necessario impostare l''estensione di lavoro con file.';
								|pl = 'W celu wykonania operacji należy zainstalować rozszerzenie pracy z plikami.';
								|tr = 'İşlemi gerçekleştirmek için dosyalarla çalışma uzantısını yüklemeniz gerekir.'"));
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = ModuleDigitalSignatureClient();
	If ModuleDigitalSignatureClient = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription(
		"StartAddingItemsFromFileCompletion",
		IntegrationWith1CDocumentManagementCoreClient,
		Parameters);
	
	DataDetails = New Structure;
	DataDetails.Insert("DataTitle", "File");
	DataDetails.Insert("Object", Notification);
	DataDetails.Insert("Presentation", Parameters.FileProperties.FileName);
	DataDetails.Insert("PresentationsList", New ValueList());
	DataDetails.PresentationsList.Add(, Parameters.FileProperties.FileName);
	
	ModuleDigitalSignatureClient.AddSignatureFromFile(DataDetails);
	
EndProcedure

// It is called during saving the file with the item instance after connecting the extension.
//
// Parameters:
//   Attached - Boolean
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * FormUniqueID - UUID - ID of the calling form.
//     * Signatures - Array of See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignature
//
Procedure StartSavingBotFilesAfterEnablingExtension(Attached, Parameters) Export
	
	If Not Attached Then
		ShowMessageBox(, NStr("vi = 'Để thực hiện giao dịch, cần cài đặt phần mở rộng làm việc với tệp.';
								|ru = 'Для выполнения операции нужно установить расширение работы с файлами.';
								|en = 'To perform the operation, install 1C:Enterprise Extension.'; fa = 'To perform the operation, install 1C:Enterprise Extension.';
								|it = 'Per l''esecuzione dell''operazione è necessario impostare l''estensione di lavoro con file.';
								|pl = 'W celu wykonania operacji należy zainstalować rozszerzenie pracy z plikami.';
								|tr = 'İşlemi gerçekleştirmek için dosyalarla çalışma uzantısını yüklemeniz gerekir.'"));
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = ModuleDigitalSignatureClient();
	If ModuleDigitalSignatureClient = Undefined Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("DataTitle", "File");
	DataDetails.Insert("Presentation", Parameters.CurrentFile.Description);
	DataDetails.Insert("PresentationsList", New ValueList());
	DataDetails.PresentationsList.Add(, Parameters.CurrentFile.Description);
	If Parameters.Signatures = Undefined Then
		AddressInStorage = IntegrationWith1CDocumentManagementCoreServerCall.PlaceFileSignaturesInStorage(
			Parameters.CurrentFile.ID);
	Else
		AddressInStorage = PutToTempStorage(Parameters.Signatures);
	EndIf;
	DataDetails.Insert("Object", AddressInStorage);
	DataDetails.Insert("Data",
		New CallbackDescription(
			"SaveTogetherBOTSaveFile",
			IntegrationWith1CDocumentManagementCoreClient,
			Parameters));
	ModuleDigitalSignatureClient.SaveDataWithSignature(DataDetails);
	
EndProcedure

// The handler for the notification "Start formationposition of the Completion object".
//
// Parameters:
//   DataDetails - Structure:
//     * SelectedCertificate - Structure:
//         ** Data - String
//         ** Thumbprint - String
//         ** Ref - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//     * DataTitle - String
//     * DataSet - Array of Structure:
//         ** Data - BinaryData
//         ** Presentation - Structure:
//              *** Value - String
//              *** Presentation - String
//         ** SignatureProperties - Structure:
//              *** SignatureDate - Date
//              *** SignatureValidationDate - Date
//              *** SignatureFileName - String
//              *** Comment - String
//              *** CertificateOwner - String
//              *** Thumbprint - String
//              *** Signature - BinaryData
//              *** SignatureCorrect - Boolean
//              *** Certificate - BinaryData
//              *** SignatureSetBy - CatalogRef.Users
//     * Operation - String
//     * Cancel - Boolean
//     * UserClickedSignButton - Boolean
//     * Presentation - String
//     * SetPresentation - String
//     * CurrentDataSetItem - Structure:
//         ** Data - BinaryData
//         ** Presentation - Structure:
//              *** Value - String
//              *** Presentation - String
//         ** SignatureProperties - Structure:
//              *** SignatureDate - Date
//              *** SignatureValidationDate - Date
//              *** SignatureFileName - String
//              *** Comment - String
//              *** CertificateOwner - String
//              *** Thumbprint - String
//              *** Signature - BinaryData
//              *** SignatureCorrect - Boolean
//              *** Certificate - BinaryData
//              *** SignatureSetBy - CatalogRef.Users
//     * Success - Boolean
//   NotificationParameters - Structure:
//     * Form - ClientApplicationForm
//     * OnCloseNotifyDescription - CallbackDescription:
//       ** AdditionalParameters - Structure:
//         *** AddressesArray - Array of String
//         *** DataArrayToStoreInDatabase - Array of See IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails
//
Procedure StartCreatingItemSSignatureCompletion(DataDetails, NotificationParameters) Export
	
	If Not DataDetails.Success Then
		Return;
	EndIf;
	
	CallbackDescription = NotificationParameters.OnCloseNotifyDescription;
	DataArrayToStoreInDatabase = CallbackDescription.AdditionalParameters.DataArrayToStoreInDatabase;
	
	AddedObjectSignatures = New Map;
	
	For ItemNumberToSign = 0 To DataDetails.DataSet.Count() - 1 Do
		// The order of the signature data passed to Sign() coincides with the order
		// of the objects to be placed in the database passed in the notification parameters.
		DataForSignature = DataDetails.DataSet[ItemNumberToSign];
		SignatureProperties = Undefined;
		If Not DataForSignature.Property("SignatureProperties", SignatureProperties) Then
			Continue;
		EndIf;
		
		If TypeOf(SignatureProperties) = Type("String") Then
			SignatureProperties = GetFromTempStorage(SignatureProperties);
		EndIf;
		
		SignatureData = SignatureData(
			SignatureProperties.Signature,
			SignatureProperties.Certificate,
			SignatureProperties);
		
		SignatureOwnerSDetails = DataArrayToStoreInDatabase[ItemNumberToSign];
		IntegrationWith1CDocumentManagementCoreClientServer.AddObjectCaptions(
			AddedObjectSignatures,
			SignatureOwnerSDetails.Description,
			SignatureOwnerSDetails.ID,
			SignatureOwnerSDetails.Type,
			SignatureOwnerSDetails.Encrypted,
			CommonClientServer.ValueInArray(SignatureData));
	EndDo;
	
	CallbackDescription.AdditionalParameters.Insert("AddedObjectSignatures", AddedObjectSignatures);
	
	RunCallback(CallbackDescription);
	
EndProcedure

Procedure SignFileCompletion(DataDetails, FileProperties) Export
	
	SignatureProperties = Undefined;
	If TypeOf(DataDetails) = Type("Structure") And DataDetails.Property("SignatureProperties", SignatureProperties) Then
		
		If IsTempStorageURL(SignatureProperties) Then
			SignatureProperties = GetFromTempStorage(SignatureProperties);
		EndIf;
		
		SignaturesArray = CommonClientServer.ValueInArray(
			SignatureData(
				SignatureProperties.Signature,
				SignatureProperties.Certificate,
				SignatureProperties));
		CommonClientServer.SupplementArray(SignaturesArray, FileProperties.FileSignatureData);
		
		IntegrationWith1CDocumentManagementCoreServerCall.EnterInformationAboutItemSignatures(
			FileProperties.FileName,
			FileProperties.FileID,
			"DMFile",
			FileProperties.Encrypted,
			SignaturesArray);
		
		MessageText = StrTemplate(NStr("vi = 'Đã cài đặt chữ ký cho ""%1""';
										|ru = 'Установлена подпись для ""%1""';
										|en = 'Signature is set for ""%1""'; fa = 'Signature is set for ""%1""';
										|it = 'Impostata firma per ""%1""';
										|pl = 'Ustawiono podpis dla ""%1""';
										|tr = '""%1"" için imza ayarlandı'"), FileProperties.FileName);
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.AddingItemInstanceFile = True;
		FileOperation.InformFormOfFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			FileProperties.FileName,
			FileProperties.FileID,
			FileProperties.FileOwner,
			MessageText,,
			FileProperties.FormUniqueID);
		
	EndIf;
	
EndProcedure

// Called during signature verification after creating a cryptography manager.
//
// Parameters:
//   CryptoManager - CryptoManager
//   Parameters - See IntegrationWith1CDocumentManagementCoreClient.VerifySignatures
//
Procedure VerifySignaturesAfterCreatingManager(CryptoManager, Parameters) Export
	
	If TypeOf(CryptoManager) = Type("String") Then
		ShowMessageBox(, CryptoManager);
		Return;
	EndIf;
	
	MatchingObjectIDAndBinaryData = New Map;
	
	For Each RowData In Parameters.SignatureTable Do
		If IntegrationWith1CDocumentManagementCoreClientServer.SignatureHighlighted(
				Parameters.SelectedSignatures, RowData) Then
			VerifySingleSignature(
				RowData,
				CryptoManager,
				MatchingObjectIDAndBinaryData,
				Parameters.AddressOfObjectSBinaryData);
		EndIf;
	EndDo;
	
	If Parameters.CallbackDescription <> Undefined Then
		RunCallback(Parameters.CallbackDescription, Parameters.SignatureTable);
	EndIf;
	
EndProcedure

// It is called during the saving of the item instance along with the file, saves the file and calls the handler, passing it the full file name.
//
// Parameters:
//   Result - Arbitrary
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * FormUniqueID - UUID - ID of the calling form.
//     * Signatures - Array of See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignature
//
Procedure SaveTogetherBOTSaveFile(Result, Parameters) Export
	
	SaveFileAs(
		Parameters.CurrentFile.ID,
		Parameters.CurrentFile.Description,
		Parameters.CurrentFile.Extension,
		Parameters.FormUniqueID,
		Result.Notification,
		False);
	
EndProcedure

#EndRegion

// The handler of the alert "Select the value of the additional request for the value of the completion".
//
// Parameters:
//   Result - Arbitrary
//   NotificationParameters - Structure:
//     * Form - ClientApplicationForm
//     * Item - FormTable
//
Procedure SelectValueOfAdditionalPropsEnterValueCompletion(Result, NotificationParameters) Export
	
	If Result <> Undefined Then
		NotificationParameters.Item.Parent.CurrentData.Value = Result;
		NotificationParameters.Form.Modified = True;
	EndIf;
	
EndProcedure

// The handler of the alert "Select the value of an additional request to select the completion".
//
// Parameters:
//   TypeName - Arbitrary
//   NotificationParameters - Structure:
//     * Form - ClientApplicationForm
//     * Item - FormTable
//
Procedure SelectValueOfAdditionalPropsSelectCompletionType(TypeName, NotificationParameters) Export
	
	Form = NotificationParameters.Form;
	Item = NotificationParameters.Item;
	
	If TypeName = Undefined Then
		Return;
	EndIf;
	SelectValueOfAdditionalAttributeProcessing(TypeName, Form, Item)
	
EndProcedure

// The handler of the alert "Select the value of the additional request Completion".
//
// Parameters:
//   Result - Arbitrary
//   NotificationParameters - Structure:
//     * Form - ClientApplicationForm
//     * Item - FormTable
//
Procedure SelectValueOfAdditionalPropsCompletion(Result, NotificationParameters) Export
	
	Item = NotificationParameters.Item;
	Form = NotificationParameters.Form;
	
	If TypeOf(Result) = Type("Structure") Then
		Item.Parent.CurrentData.ValueID = Result.AttributeID;
		Item.Parent.CurrentData.ValueType = Result.AttributeType;
		Item.Parent.CurrentData.Value = Result.AttributePresentation;
		Form.Modified = True;
	EndIf;
	
EndProcedure

// The handler for the "Select the value of the Session Completion" notification.
//
// Parameters:
//   TypeValue - Type
//                - ValueListItem
//   ValueSelectionParameters - See IntegrationWith1CDocumentManagementCoreClient.ValueSelectionParametersBefore
//
Procedure ChooseValueOfAttributeBeforeCompletion(TypeValue, ValueSelectionParameters) Export
	
	If TypeOf(TypeValue) = Type("ValueListItem") Then
		TypeValue = TypeValue.Value;
	EndIf;
	
	If TypeValue = "String" Then
		ShowInputString(
			ValueSelectionParameters.Notification,
			StrReplace(ValueSelectionParameters.EditText, "¶", Chars.LF),
			ValueSelectionParameters.Presentation,,
			True);
		
	ElsIf TypeValue = "Number" Then
		ShowInputNumber(
			ValueSelectionParameters.Notification,
			ValueSelectionParameters.AttributeValue,
			ValueSelectionParameters.Presentation,
			15,
			5);
		
	ElsIf TypeValue = "Date" Then
		ShowInputDate(
			ValueSelectionParameters.Notification,
			ValueSelectionParameters.AttributeValue,
			ValueSelectionParameters.Presentation,
			DateFractions.Date);
		
	ElsIf TypeValue = "DateTime" Then
		ShowInputDate(
			ValueSelectionParameters.Notification,
			ValueSelectionParameters.AttributeValue,
			ValueSelectionParameters.Presentation,
			DateFractions.DateTime);
		
	ElsIf TypeValue = "Time" Then
		ShowInputDate(
			ValueSelectionParameters.Notification,
			ValueSelectionParameters.AttributeValue,
			ValueSelectionParameters.Presentation,
			DateFractions.Time);
		
	ElsIf TypeValue = "Boolean" Then
		ShowInputValue(
			ValueSelectionParameters.Notification,
			ValueSelectionParameters.AttributeValue,
			ValueSelectionParameters.Presentation,
			Type("Boolean"));
		
	ElsIf ValueIsFilled(TypeValue) Then
		FormParameters = New Structure;
		FormParameters.Insert("TypeOfSelectionObject", TypeValue);
		If ValueIsFilled(ValueSelectionParameters.AttributeValueID)
				And TypeValue = ValueSelectionParameters.AttributeValueType Then
			FormParameters.Insert("SelectedElement", ValueSelectionParameters.AttributeValueID);
		EndIf;
		If ValueSelectionParameters.Filter = Undefined Then
			FormParameters.Insert("Filter", New Structure);
		Else
			FormParameters.Insert("Filter", ValueSelectionParameters.Filter);
		EndIf;
		
		If TypeValue = "DMDocument" Or TypeValue = "DMCorrespondent" Or TypeValue = "DMMeeting" Then
			
			// There are potentially a lot of objects UP to, you need a choice of search.
			If ValueIsFilled(ValueSelectionParameters.AttributeValue) Then
				FormParameters.Filter.Insert("name", TrimAll(ValueSelectionParameters.AttributeValue));
				FormParameters.Insert("SearchImmediately", False);
			EndIf;
			
			Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
			If Settings.UseIntegrationBefore2 Then
				FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingObjectBySearch";
			ElsIf Settings.UseIntegrationBefore3 Then
				FormName = "DataProcessor.IntegrationWith1CDocumentManagement3.Form.SelectingObjectBySearch";
			Else
				Return;
			EndIf;
			
			OpenForm(FormName,
				FormParameters,
				ThisObject,
				New UUID,,,
				ValueSelectionParameters.Notification,
				FormWindowOpeningMode.LockWholeInterface);
			
		Else
			
			// The usual selection from the list.
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList",
				FormParameters,
				ThisObject,
				New UUID,,,
				ValueSelectionParameters.Notification,
				FormWindowOpeningMode.LockWholeInterface);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The handler for the notification "Select the value of the session and the completion of the type selection".
//
// Parameters:
//   TypeValue - Type
//                - ValueListItem
//   ParametersSelectValue - Structure:
//     * TypeDetails - TypeDescription
//     * EditText - String
//     * Presentation - String
//     * AttributeValue - Arbitrary
//     * AdditionalAttributeIS - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
//     * Notification - CallbackDescription
//
Procedure ChooseValueOfAttributeISCompletionTypeSelection(TypeValue, ParametersSelectValue) Export
	
	If TypeValue = Undefined Then
		Return;
	ElsIf TypeOf(TypeValue) = Type("ValueListItem") Then
		ObjectType = TypeValue.Value; // Type
	Else
		ObjectType = TypeValue; // Type
	EndIf;
	
	TypeDetails = ParametersSelectValue.TypeDetails;
	
	If ObjectType = Type("String") Then
		If TypeDetails.StringQualifiers.Length = 0 Or TypeDetails.StringQualifiers.Length > 40 Then
			Multiline = True;
		Else
			Multiline = False;
		EndIf;
		
		ShowInputString(
			ParametersSelectValue.Notification,
			StrReplace(ParametersSelectValue.EditText, "¶", Chars.LF),
			ParametersSelectValue.Presentation,
			TypeDetails.StringQualifiers.Length,
			Multiline);
		
	ElsIf ObjectType = Type("Number") Then
		ShowInputNumber(
			ParametersSelectValue.Notification,
			ParametersSelectValue.AttributeValue,
			ParametersSelectValue.Presentation,
			TypeDetails.NumberQualifiers.Digits,
			TypeDetails.NumberQualifiers.FractionDigits);
		
	ElsIf ObjectType = Type("Date") Then
		ShowInputDate(
			ParametersSelectValue.Notification,
			ParametersSelectValue.AttributeValue,
			ParametersSelectValue.Presentation,
			TypeDetails.DateQualifiers.DateFractions);
		
	ElsIf ObjectType = Type("Boolean") Then
		ShowInputValue(
			ParametersSelectValue.Notification,
			ParametersSelectValue.AttributeValue,
			ParametersSelectValue.Presentation,
			Type("Boolean"));
		
	Else
		ObjectName = IntegrationWith1CDocumentManagementCoreServerCall.NameOfMetadataObjectByType(
			ObjectType);
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("CurrentRow", ParametersSelectValue.AttributeValue);
		If ObjectName = "Catalog.ObjectsPropertiesValues" Then
			Filter = New Structure("Owner", ParametersSelectValue.AdditionalAttributeIS);
			FormParameters.Insert("Filter", Filter);
		EndIf;
		OpenForm(ObjectName + ".ChoiceForm", FormParameters, ThisObject,,,,
			ParametersSelectValue.Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

// a waiting handler that is called when a long-running request execution operation Ends.
//
// Parameters:
//   Result - See TimeConsumingOperations.ActionCompleted
//   JobID - UUID
//
Procedure ExecuteRequestAsynchronouslyCompletion(Result, JobID) Export
	
	IdleHandlers = ActiveBackgroundJobWaitingHandlers();
	TaskWaitingHandlers = IdleHandlers[JobID];
	If TaskWaitingHandlers = Undefined Then
		Return;
	EndIf;
	
	If Result <> Undefined Then
		If Result.Status = "Completed2" Then
			Result.Insert("ResultLongOperation", GetFromTempStorage(Result.ResultAddress));
		ElsIf Result.Status = "Error" Then
			ServiceVersion = GetFromTempStorage(Result.ResultAddress);
			IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings(
				ServiceVersion);
		EndIf;
	EndIf;
	
	For Each Parameters In TaskWaitingHandlers Do
		
		If Not Parameters.OutputIdleWindow And TypeOf(Parameters.Owner) = Type("ClientApplicationForm") Then
			
			Items = Parameters.Owner.Items;
			If Parameters.HideInterface And (Items.Find("ConnectionPageGroup") <> Undefined) Then
				
				If Items.ConnectionPageGroup.CurrentPage = Items.PageLoadingFromDM Then
					If Result <> Undefined And Result.Status = "Error"
							And Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
						Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
					Else
						Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
					EndIf;
				EndIf;
				
				If ValueIsFilled(Parameters.OldTitle) Then
					Items.DescriptionLoadingFromTOPage.Title = Parameters.OldTitle;
				EndIf;
				
			ElsIf Items.Find("GroupUploadFromDM") <> Undefined Then
				
				Items.GroupUploadFromDM.Visible = False;
				
			EndIf;
			
		EndIf;
		
		RunCallback(Parameters.CallbackOnCompletion, Result);
		
	EndDo;
	
	IdleHandlers.Delete(JobID);
	
EndProcedure

// The waiting handler that is called after selecting the objects addressing the executor role.
//
// Parameters:
//   FillingResult - Structure:
//     * Result - String
//     * Performer - String
//     * PerformerID - String
//     * PerformerType - String
//     * MainAddressingObject - String
//     * MainAddressingObjectID - String
//     * MainAddressingObjectType - String
//     * AdditionalAddressingObject - String
//     * AdditionalAddressingObjectID - String
//     * AdditionalAddressingObjectType - String
//   NotificationParameters - Structure:
//     * OnCloseNotifyDescription - CallbackDescription - description of the closure notification.
//     * NameOfRole - String - name of the role for getting addressing objects.
//     * RoleType - String - the type of role for getting addressing objects.
//     * IDRoles - String - ID of the role in the Workflow.
//     * OwnerForm - ClientApplicationForm - the managed form where the role is selected.
//
Procedure ShowGettingAddressingObjectsOfRoleCompletion(FillingResult, NotificationParameters) Export
	
	OnCloseNotifyDescription = NotificationParameters.OnCloseNotifyDescription;
	NameOfRole = NotificationParameters.NameOfRole;
	RoleType = NotificationParameters.RoleType;
	IDRoles = NotificationParameters.IDRoles;
	
	ReturnData = New Structure;
	
	If TypeOf(FillingResult) = Type("Structure") Then
		
		If FillingResult.Result = "OK" Then
			
			ReturnData.Insert("Performer", FillingResult.Performer);
			ReturnData.Insert("PerformerID", FillingResult.PerformerID);
			ReturnData.Insert("PerformerType", FillingResult.PerformerType);
			
			ReturnData.Insert("MainAddressingObject", FillingResult.MainAddressingObject);
			ReturnData.Insert("MainAddressingObjectID", FillingResult.MainAddressingObjectID);
			ReturnData.Insert("MainAddressingObjectType", FillingResult.MainAddressingObjectType);
			
			ReturnData.Insert("AdditionalAddressingObject", FillingResult.AdditionalAddressingObject);
			ReturnData.Insert("AdditionalAddressingObjectID", FillingResult.AdditionalAddressingObjectID);
			ReturnData.Insert("AdditionalAddressingObjectType", FillingResult.AdditionalAddressingObjectType);
			
		ElsIf FillingResult.Result = "WithoutAddressingObjects" Then
			
			ReturnData.Insert("Performer", NameOfRole);
			ReturnData.Insert("PerformerID", IDRoles);
			ReturnData.Insert("PerformerType", RoleType);
			
			ReturnData.Insert("MainAddressingObject", "");
			ReturnData.Insert("MainAddressingObjectID", "");
			ReturnData.Insert("MainAddressingObjectType", "");
			
			ReturnData.Insert("AdditionalAddressingObject", "");
			ReturnData.Insert("AdditionalAddressingObjectID", "");
			ReturnData.Insert("AdditionalAddressingObjectType", "");
			
		Else
			
			ReturnData = Undefined;
			
		EndIf;
		
	Else
		
		ReturnData = Undefined;
		
	EndIf;
	
	RunCallback(OnCloseNotifyDescription, ReturnData);
	
EndProcedure

// a waiting handler that is called when a long-term connection operation is Ended before and after
// the system starts working.
//
// Parameters:
//   Result - Structure:
//     * AdditionalResultAddress - String
//     * ResultAddress - String
//     * BriefErrorDescription - String
//     * DetailErrorDescription - String
//     * Messages - Array of UserMessage
//     * Status - String
//     * ResultLongOperation - See IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters
//   AuthorizationSettingsFromDatabase - See IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement
//
Procedure AfterStartCompletion(Result, AuthorizationSettingsFromDatabase) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		Parameters = Result.ResultLongOperation;
		
		ServiceVersion = Parameters.IntegrationWith1CDocumentManagementServiceVersion;
		IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings(
			ServiceVersion);
		
		If IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
			// The connection was completed successfully, the service is still available.
			IntegrationWith1CDocumentManagementCoreServerCall.SetAuthorizationSettingsInSessionSettings(
				Parameters.IntegrationWith1CDocumentManagementUsername,
				Parameters.IntegrationWith1CDocumentManagementPassword,
				Parameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed,
				Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed,
				Parameters.IntegrationWith1CDocumentManagementWSDefinitions,
				Parameters.IntegrationWith1CDocumentManagementProxyServerLocation);
			WhenLoggingIn(Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed);
			
#If WebClient Then
			ComputerName = Undefined;
#Else
			ComputerName = ComputerName();
#EndIf
			If Parameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed <>
					AuthorizationSettingsFromDatabase.OSAuthenticationIsUsed Then
				IntegrationWith1CDocumentManagementCoreServerCall.SaveFAAuthenticationUsageSettings(
					ComputerName,
					Parameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed);
			EndIf;
			If Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed <>
					AuthorizationSettingsFromDatabase.JWTAuthenticationIsUsed Then
				IntegrationWith1CDocumentManagementCoreServerCall.SaveSettingsForUsingJWTAuthentication(
					ComputerName,
					Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed);
			EndIf;
		EndIf;
		
	ElsIf Result.Status = "Error" Then
		
		IntegrationWith1CDocumentManagementCoreServerCall.WriteError(Result.BriefErrorDescription);
		
	EndIf;
	
EndProcedure

// the wait handler, which is called when a long-term connection operation is Ended,
// from the verify connection procedure.
//
// Parameters:
//   Result - Structure:
//     * AdditionalResultAddress - String
//     * ResultAddress - String
//     * BriefErrorDescription - String
//     * DetailErrorDescription - String
//     * Messages - Array of UserMessage
//     * Status - String
//     * ResultLongOperation - See IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters
//   NotificationParameters - Structure:
//     * AuthorizationSettings - See IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement
//     * CallbackDescription - CallbackDescription
//     * Owner - ClientApplicationForm - the form in which to call the connection attempt again.
//                - CommonModule - the client module from which the command is called.
//     * ReShowAuthorizationWindow - Boolean
//
Procedure TestConnectionCompletion(Result, NotificationParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	OSAuthenticationIsUsed = False;
	JWTAuthenticationIsUsed = False;
	LoggedInEarlier = NotificationParameters.AuthorizationSettings.PasswordIsSaved
		Or NotificationParameters.AuthorizationSettings.OSAuthenticationIsUsed
		Or NotificationParameters.AuthorizationSettings.JWTAuthenticationIsUsed;
	SuccessfulConnection = False;
	
	If Result.Status = "Completed2" Then
		
		Parameters = Result.ResultLongOperation;
		
		ServiceVersion = Parameters.IntegrationWith1CDocumentManagementServiceVersion;
		IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings(
			ServiceVersion);
		
		If IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
			IntegrationWith1CDocumentManagementCoreServerCall.SetAuthorizationSettingsInSessionSettings(
				Parameters.IntegrationWith1CDocumentManagementUsername,
				Parameters.IntegrationWith1CDocumentManagementPassword,
				Parameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed,
				Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed,
				Parameters.IntegrationWith1CDocumentManagementWSDefinitions,
				Parameters.IntegrationWith1CDocumentManagementProxyServerLocation);
			WhenLoggingIn(Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed);
			
			SuccessfulConnection = True;
			NotificationParameters.ReShowAuthorizationWindow = False;
			OSAuthenticationIsUsed = Parameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed;
			JWTAuthenticationIsUsed = Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed;
			
#If WebClient Then
			ComputerName = Undefined;
#Else
			ComputerName = ComputerName();
#EndIf
			If OSAuthenticationIsUsed <> NotificationParameters.AuthorizationSettings.OSAuthenticationIsUsed Then
				IntegrationWith1CDocumentManagementCoreServerCall.SaveFAAuthenticationUsageSettings(
					ComputerName,
					OSAuthenticationIsUsed);
			EndIf;
			If JWTAuthenticationIsUsed <> NotificationParameters.AuthorizationSettings.JWTAuthenticationIsUsed Then
				IntegrationWith1CDocumentManagementCoreServerCall.SaveSettingsForUsingJWTAuthentication(
					ComputerName,
					JWTAuthenticationIsUsed);
			EndIf;
		EndIf;
		
	ElsIf Result.Status = "Error" Then
		
		Raise Result.BriefErrorDescription;
		
	EndIf;
	
	// We offer an authorization window only if it is known from the context of the call that the user explicitly
	// initiated access to the functionality BEFORE.
	If Not SuccessfulConnection
			And (NotificationParameters.ReShowAuthorizationWindow
				Or ((NotificationParameters.AuthorizationSettings.UserName = Undefined Or Not LoggedInEarlier)
					And Not AuthorizationOffered())) Then
		
		SaveAuthorizationOffered();
		
		AuthorizationFormParameters = New Structure;
		AuthorizationFormParameters.Insert("UserName", NotificationParameters.AuthorizationSettings.UserName);
		AuthorizationFormParameters.Insert("PasswordIsSaved", NotificationParameters.AuthorizationSettings.PasswordIsSaved);
		AuthorizationFormParameters.Insert("Password", NotificationParameters.AuthorizationSettings.Password);
		AuthorizationFormParameters.Insert("AutomaticCallWhenCheckingConnection", True);
		
		ConnectionVerificationParameters = New Structure;
		ConnectionVerificationParameters.Insert("CallbackDescription", NotificationParameters.CallbackDescription);
		
		DescriptionOfConnectionVerificationAlert = New CallbackDescription(
			"CheckConnectionAfterAuthorizationWindow",
			ThisObject,
			ConnectionVerificationParameters);
		
		AuthorizationForm = OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement",
			AuthorizationFormParameters,
			NotificationParameters.Owner,,,,
			DescriptionOfConnectionVerificationAlert,
			FormWindowOpeningMode.LockOwnerWindow);
		
		// In case of successful OS authentication, the form will not open.
		If AuthorizationForm = Undefined Then
			
			SuccessfulConnection = True;
			
			IntegrationWith1CDocumentManagementCoreServerCall.ReadAuthorizationSettingsFromSessionParameters(
				OSAuthenticationIsUsed,
				JWTAuthenticationIsUsed);
			If OSAuthenticationIsUsed <> NotificationParameters.AuthorizationSettings.OSAuthenticationIsUsed Then
				IntegrationWith1CDocumentManagementCoreServerCall.SaveFAAuthenticationUsageSettings(
					ComputerName,
					OSAuthenticationIsUsed);
			EndIf;
			If JWTAuthenticationIsUsed <> NotificationParameters.AuthorizationSettings.JWTAuthenticationIsUsed Then
				IntegrationWith1CDocumentManagementCoreServerCall.SaveSettingsForUsingJWTAuthentication(
					ComputerName,
					JWTAuthenticationIsUsed);
			EndIf;
			
		Else // The authorization Form has opened.
			Return; // with asynchronous continuation after clicking OK.
		EndIf;
		
	EndIf;
	
	RunCallback(NotificationParameters.CallbackDescription, SuccessfulConnection);
	
EndProcedure

// Handler for the "Create Integrated Object Completion" alert.
//
// Parameters:
//   Result - Arbitrary
//   NotificationParameters - Structure:
//     * Object1CDocumentManagement - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//     * ObjectForm - ClientApplicationForm:
//         ** Object - DefinedType.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable
//                   - DefinedType.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable
//     * WhetherFilesAreAttached - Boolean
//     * TypeOfObjectToCreate - String - the full name of the metadata object that is being created in the integrated system.
//
Procedure CreateIntegratedCompletionObject(Result, NotificationParameters) Export
	
	TypeOfIntegratedObject = Type(IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(
		NotificationParameters.TypeOfObjectToCreate));
	ObjectReference = ReferenceToIntegratedObjectFromForm(
		NotificationParameters.ObjectForm,
		TypeOfIntegratedObject);
	NotificationParameters.ObjectForm = Undefined;
	
	If Not ValueIsFilled(ObjectReference) Then
		Return;
	EndIf;
	
	ID = NotificationParameters.Object1CDocumentManagement.ID;
	Type = NotificationParameters.Object1CDocumentManagement.Type;
	
	AddVDOConnection = True;
	RegisterForExchange = True;
	IntegrationWith1CDocumentManagementCoreServerCall.AddLink(
		ID,
		Type,
		ObjectReference,
		NotificationParameters.WhetherFilesAreAttached,
		AddVDOConnection,
		RegisterForExchange);
	Notify_AddingConnection(ID, Type, ObjectReference);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctionsFiles

Function FileNameWithSuffix(DirectoryWithSuffix, CurrentFile)
	
	FileNameWithSuffix = DirectoryWithSuffix
		+ GetPathSeparator()
		+ IntegrationWith1CDocumentManagementCoreClientServer.FileNameWithExtension(
			CurrentFile.Description,
			CurrentFile.Extension);
	
	FullPathMaxSize = 260;
	If Lower(CurrentFile.Extension) = "xls" Or Lower(CurrentFile.Extension) = "xlsx" Then
		// Excel the length of the file name along with the path should not exceed 218 characters.
		FullPathMaxSize = 218;
	EndIf;
	
#If Not WebClient Then
	
	LengthFileNameWithSuffix = StrLen(FileNameWithSuffix);
	
	If LengthFileNameWithSuffix > FullPathMaxSize Then
		
		MaximumLengthWithPath = FullPathMaxSize - 5; // 5 is the minimum for "C:1"
		HowMuchShouldICutOff = LengthFileNameWithSuffix - MaximumLengthWithPath + 1;
		
		// Cut it down.
		CurrentFile.Description = Left(CurrentFile.Description, StrLen(CurrentFile.Description) - HowMuchShouldICutOff);
		CurrentFile.Description = TrimAll(CurrentFile.Description);
		CurrentFile.FileName = StrTemplate("%1.%2", CurrentFile.Description, CurrentFile.Extension);
		
		FileNameWithSuffix = DirectoryWithSuffix
			+ GetPathSeparator()
			+ IntegrationWith1CDocumentManagementCoreClientServer.FileNameWithExtension(
				CurrentFile.Description,
				CurrentFile.Extension);
		
	EndIf;
	
#EndIf
	
	Return FileNameWithSuffix;
	
EndFunction

// Starts printing a file in an external application or, for some types of files, by means of the platform.
//
Async Procedure PrintFileByApplication(Val FullFileName)
	
#If MobileClient Then
	
	ShowMessageBox(, NStr("vi = 'Trên mobile client không hỗ trợ tệp.';
							|ru = 'В мобильном клиенте печать файлов не поддерживается.';
							|en = 'Printing files is not supported in the mobile client.'; fa = 'Printing files is not supported in the mobile client.';
							|it = 'Printing files is not supported in the mobile client.';
							|pl = 'Printing files is not supported in the mobile client.';
							|tr = 'Mobil istemcide dosya yazdırma desteklenmiyor.'"));
	Return;
	
#ElsIf WebClient Then
	
	ShowMessageBox(, NStr("vi = 'Trên Web-client không hỗ trợ in tệp.';
							|ru = 'В веб-клиенте печать файлов не поддерживается.';
							|en = 'Printing files is not supported in the web client.'; fa = 'Printing files is not supported in the web client.';
							|it = 'Printing files is not supported in the web client.';
							|pl = 'Printing files is not supported in the web client.';
							|tr = 'Web istemcisinde, dosyaların yazdırılması desteklenmiyor.'"));
	Return;
	
#Else
	
	ExtensionsExceptions =
		"m3u, m4a, mID, mIDi, mp2, mp3, mpa, rmi, wav, wma,
		|3g2, 3gp, 3gp2, 3gpp, asf, asx, avi, m1v, m2t, m2ts,
		|m2v, m4v, mkv, mov, mp2v, mp4, mp4v, mpe, mpeg, mts,
		|vob, wm, wmv, wmx, wvx, 7z, zip, rar, arc, arh, arj,
		|ark, p7m, pak, package, app, com, exe, jar, dll, res,
		|iso, isz, mdf, mds, cf, dt, epf, erf";
	ExceptionExtensionsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
		ExtensionsExceptions,
		",",
		True,
		True);
	
	PointPosition = StrFind(FullFileName, ".", SearchDirection.FromEnd);
	If PointPosition <> 0 Then
		Extension = Lower(Mid(FullFileName, PointPosition + 1));
	Else
		Extension = "";
	EndIf;
	
	Extension = Lower(Extension);
	If ExceptionExtensionsArray.Find(Extension) <> Undefined Then
		Return;
	
	ElsIf Extension = "grs" Then
		Schema = New GraphicalSchema;
		Await Schema.ReadAsync(FullFileName);
		Schema.Print();
	
	ElsIf Extension = "mxl" Then
		Result = Await PutFileToServerAsync(,,, FullFileName);
		If TypeOf(Result) = Type("StoredFileDescription") And Not Result.PutFileCanceled Then
			SpreadsheetDocument =
				IntegrationWith1CDocumentManagementCoreServerCall.ReadingTabularDocument(
					Result.Address);
			SpreadsheetDocument.Print();
		EndIf;
		
	Else
		
		Try
			SystemData = New SystemInfo;
			If SystemData.PlatformType = PlatformType.Windows_x86
					Or SystemData.PlatformType = PlatformType.Windows_x86_64 Then
				FullFileName = StrReplace(FullFileName, "/", "\");
			EndIf;
			FileSystemClient.PrintFromApplicationByFileName(FullFileName);
		Except
			Info = ErrorInfo();
			ShowMessageBox(, StrTemplate(
				NStr("vi = 'Mô tả=""%1""';
					|ru = 'Описание=""%1""';
					|en = 'Details=""%1""'; fa = 'Details=""%1""';
					|it = 'Описание=""%1""';
					|pl = 'Details=""%1""';
					|tr = 'Açıklama = ""%1""'"),
				ErrorProcessing.BriefErrorDescription(Info)));
		EndTry;
		
	EndIf;
	
#EndIf
	
EndProcedure

// Opens the file with the corresponding application.
//
// Parameters:
//   FullFileName - String - the full path to the file to open.
//
// Returns:
//   Boolean - True if the file is opened successfully.
//
Function OpenFileWithApplication(FullFileName)
	
	StructureOfFullName = CommonClientServer.ParseFullFileName(FullFileName);
	
	If ValueIsFilled(StructureOfFullName.Path) Then
		Try
			SystemData = New SystemInfo;
			If SystemData.PlatformType = PlatformType.Windows_x86
					Or SystemData.PlatformType = PlatformType.Windows_x86_64 Then
				FullFileName = StrReplace(FullFileName, "/", "\");
			EndIf;
			FileSystemClient.OpenFile(FullFileName);
		Except
			WarningText = StrTemplate(NStr("vi = 'Mô tả=""%1""';
											|ru = 'Описание=""%1""';
											|en = 'Details=""%1""'; fa = 'Details=""%1""';
											|it = 'Описание=""%1""';
											|pl = 'Details=""%1""';
											|tr = 'Açıklama = ""%1""'"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			ShowMessageBox(, WarningText);
			Return False;
		EndTry;
	EndIf;
	
	Return True;
	
EndFunction

// Starts receiving one file from the Workflow.
//
// Parameters:
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * RemainingFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//     * ForReading - Boolean - True if the files are saved for reading, and False if for editing.
//     * CallbackDescription - CallbackDescription - called by passing an array of full file names.
//     * FullFileNames - Array of String - full names of files already received.
//     * FormUniqueID - UUID - ID of the calling form.
//
Async Procedure GettingStartFile(Val Parameters)
	
	If Not Await FileSystemExtensionAttached1Async() Then
		
		UseVisualizationOfItemInstanceStamp = True;
		If ValueIsFilled(Parameters.CurrentFile.RefToBinaryFileData)
				And IsTempStorageURL(Parameters.CurrentFile.RefToBinaryFileData) Then
			Address = Parameters.CurrentFile.RefToBinaryFileData;
		ElsIf Parameters.CurrentFile.Type = "DMFile" Then
			Address = IntegrationWith1CDocumentManagementCoreServerCall.GetFileAndPutItInStorage(
				Parameters.CurrentFile.ID,
				UseVisualizationOfItemInstanceStamp,
				Parameters.FormUniqueID,
				?(Parameters.ForReading, Undefined, CurrentDate()),
				Parameters.CurrentFile); // The use is justified: the date-time is fixed on the client.
		ElsIf Parameters.CurrentFile.Type = "DMFileVersion" Then
			Address = IntegrationWith1CDocumentManagementCoreServerCall.GetVersionOfFileAndPutItInRepository(
				Parameters.CurrentFile.ID,
				UseVisualizationOfItemInstanceStamp,
				Parameters.FormUniqueID,
				Parameters.CurrentFile);
		Else
			Raise StrTemplate(NStr("vi = 'Kiểu tệp không xác định: %1';
									|ru = 'Неизвестный тип файла: %1';
									|en = 'Unknown file type: %1'; fa = 'Unknown file type: %1';
									|it = 'Unknown file type: %1';
									|pl = 'Unknown file type: %1';
									|tr = 'Bilinmeyen dosya türü: %1'"), Parameters.CurrentFile.Type);
		EndIf;
		CheckFileEncryption(Parameters.CurrentFile);
		Parameters.Insert("TempFileStorageAddress", Address);
		
		FileSystemClient.SaveFile(
			New CallbackDescription(
				"ProcessTheFileAfterReceivingItFrom1CDocumentManagement",
				IntegrationWith1CDocumentManagementCoreClient,
				Parameters),
			Address,
			Parameters.CurrentFile.FileName);
		
		Return;
		
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreClientCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1")
			And (Parameters.CurrentFile.Type = "DMFile" Or Parameters.CurrentFile.Type = "DMFileVersion") Then
		
		EditingInformation =
			IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile(
				Parameters.CurrentFile.ID,
				Parameters.CurrentFile.Type);
		Parameters.Insert("EditingInformation", EditingInformation);
		
		If Await NeedChoiceOfActionsWhenFileDifferencesAreDetectedAsync(
				EditingInformation, Parameters, "RetrievingFileAfterSelectingSource", True) Then
			Return;
		EndIf;
		
		If Parameters.UseExistingOne Then
			CallbackDescription = New CallbackDescription(
				"RetrievingFileAfterSelectingSource",
				IntegrationWith1CDocumentManagementCoreClient,
				Parameters);
			RunCallback(CallbackDescription, "UseExistingOne");
			Return;
		EndIf;
		
		// If a working folder is specified in the DO, we will try to use it.
		If ValueIsFilled(EditingInformation.RecommendedFolder) Then
			File = New File(EditingInformation.RecommendedFolder);
			If Await File.ExistsAsync() And Await File.IsDirectoryAsync() Then // we use the specified folder.
				TempFilesDir = EditingInformation.RecommendedFolder;
			ElsIf Await File.ExistsAsync() And Await File.IsFileAsync() Then // it is impossible to use it.
				TempFilesDir = UserDataWorkDir();
			Else // Let's try to create this folder.
				Try
					Await CreateDirectoryAsync(EditingInformation.RecommendedFolder);
					TempFilesDir = EditingInformation.RecommendedFolder;
				Except // no access or other problems.
					TempFilesDir = UserDataWorkDir();
					IntegrationWith1CDocumentManagementCoreServerCall.WriteWarning(
						StrTemplate(
							NStr("vi = 'Không có quyền truy cập đến thư mục làm việc: %1';
								|ru = 'Нет доступа к рабочей папке: %1';
								|en = 'No access to the working folder: %1'; fa = 'No access to the working folder: %1';
								|it = 'Non vi è accesso alla cartella di lavoro: %1';
								|pl = 'Brak dostępu do folderu roboczego: %1';
								|tr = 'Çalışma klasörüne erişim mevcut değil: %1'"),
							EditingInformation.RecommendedFolder));
				EndTry;
			EndIf;
		Else // The recommended directory is not specified.
			TempFilesDir = UserDataWorkDir();
		EndIf;
		
	Else // The web service of this version does not support extended work with files.
		TempFilesDir = UserDataWorkDir();
	EndIf;
	
	If Right(TempFilesDir, 1) = GetPathSeparator() Then
		TempFilesDir = Left(TempFilesDir, StrLen(TempFilesDir) - 1);
	EndIf;
	
	// We will get the name of the temporary file that does not match the name of the file that exists in the temporary directory,
	// creating, if necessary, a subdirectory of the form A...Z, A0...Z9.
	AttemptCounter = 0;
	Success = False;
#If Not WebClient Then
	Generator = New RandomNumberGenerator(Second(CurrentDate())); // The use is justified: RNG.
#EndIf
	While AttemptCounter < 100 Do
		AttemptCounter = AttemptCounter + 1;
#If Not WebClient Then
		If AttemptCounter = 1 Then
			Suffix = "";
		Else
			Suffix = Char(CharCode("A") + Generator.RandomNumber(0, 25));
			If AttemptCounter > 13 Then // It's time to complicate the suffix.
				Suffix = Suffix + String(Generator.RandomNumber(0, 9));
			EndIf;
		EndIf;
#Else
		If AttemptCounter = 1 Then
			Suffix = "";
		Else
			Suffix = Char(CharCode("A") + (Second(CurrentDate()) + AttemptCounter) % 26); // The use is justified: RNG.
			If AttemptCounter > 13 Then // It's time to complicate the suffix.
				Suffix = Suffix + String((Second(CurrentDate()) + AttemptCounter) % 10); // The use is justified: RNG.
			EndIf;
		EndIf;
#EndIf
		DirectoryWithSuffix = TempFilesDir + ?(Suffix = "",
			"",
			GetPathSeparator() + Suffix);
		File = New File(DirectoryWithSuffix);
		If Await File.ExistsAsync() Then
			If Await File.IsFileAsync() Then
				Continue;
			EndIf;
		Else
			Try
				Await CreateDirectoryAsync(DirectoryWithSuffix);
			Except
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Lỗi khi tạo thư mục ""%1"":
						|""%2"".';
						|ru = 'Ошибка при создании каталога ""%1"":
						|""%2"".';
						|en = 'Cannot create directory ""%1"". Reason:
						|%2'; fa = 'Cannot create directory ""%1"". Reason:
						|%2';
						|it = 'Errore durante la creazione della directory ""%1"":
						|""%2"".';
						|pl = 'Błąd przy utworzeniu katalogu ""%1"":
						|""%2"".';
						|tr = '""%1"":
						|""%2"" klasör oluşturulurken hata.'"),
					DirectoryWithSuffix,
					ErrorProcessing.BriefErrorDescription(ErrorInfo()) );
			EndTry;
		EndIf;
		
		FileNameWithSuffix = FileNameWithSuffix(DirectoryWithSuffix, Parameters.CurrentFile);
		File = New File(FileNameWithSuffix);
		If Not Await File.ExistsAsync() Then
			Success = True;
			Break;
		EndIf;
	EndDo;
	If Not Success Then
		Raise NStr("vi = 'Không thể tạo tệp trong thư mục tệp tạm thời.';
					|ru = 'Не удается создать файл в каталоге временных файлов.';
					|en = 'Cannot create file in the temporary directory.'; fa = 'Cannot create file in the temporary directory.';
					|it = 'Non è possibile creare il file nella directory di file temporanei.';
					|pl = 'Nie można utworzyć pliku w katalogu plików tymczasowych.';
					|tr = 'Geçici dosyalar klasöründe dosya oluşturulamıyor.'");
	EndIf;
	Parameters.Insert("TempFilesDir", DirectoryWithSuffix);
	Parameters.Insert("TempFileName", FileNameWithSuffix);
	
	// Get the file from BEFORE on the server.
	UseVisualizationOfItemInstanceStamp = True;
	If ValueIsFilled(Parameters.CurrentFile.RefToBinaryFileData)
			And IsTempStorageURL(Parameters.CurrentFile.RefToBinaryFileData) Then
		Address = Parameters.CurrentFile.RefToBinaryFileData;
	ElsIf Parameters.CurrentFile.Type = "DMFile" Then
		Address = IntegrationWith1CDocumentManagementCoreServerCall.GetFileAndPutItInStorage(
			Parameters.CurrentFile.ID,
			UseVisualizationOfItemInstanceStamp,
			Parameters.FormUniqueID,
			?(Parameters.ForReading, Undefined, CurrentDate()), // The use is justified: the date-time is fixed on the client.
			Parameters.CurrentFile);
	ElsIf Parameters.CurrentFile.Type = "DMFileVersion" Then
		Address = IntegrationWith1CDocumentManagementCoreServerCall.GetVersionOfFileAndPutItInRepository(
			Parameters.CurrentFile.ID,
			UseVisualizationOfItemInstanceStamp,
			Parameters.FormUniqueID,
			Parameters.CurrentFile);
	Else
		Raise StrTemplate(NStr("vi = 'Kiểu tệp không xác định: %1';
								|ru = 'Неизвестный тип файла: %1';
								|en = 'Unknown file type: %1'; fa = 'Unknown file type: %1';
								|it = 'Unknown file type: %1';
								|pl = 'Unknown file type: %1';
								|tr = 'Bilinmeyen dosya türü: %1'"), Parameters.CurrentFile.Type);
	EndIf;
	CheckFileEncryption(Parameters.CurrentFile);
	Parameters.Insert("TempFileStorageAddress", Address);
	
	ReceivingFileAfterReceivingFrom1CDocumentManagement(Parameters);
	
EndProcedure

// Starts receiving files, triggering an alert after receiving all files.
//
// Parameters:
//   Parameters - Structure:
//     * RemainingFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//     * ForReading - Boolean - True if the files are saved for reading, and False if for editing.
//     * CallbackDescription - CallbackDescription - called by passing an array of full file names.
//     * FullFileNames - Array of String - full names of files already received.
//     * FormUniqueID - UUID - ID of the calling form.
//
Procedure GetFilesStarted(Parameters)
	
	// Have all the files been received?
	If Parameters.RemainingFiles.Count() = 0 Then
		
		If Parameters.FullFileNames.Count() <> 0 Then
			RunCallback(
				Parameters.CallbackDescription,
				Parameters.FullFileNames);
		EndIf;
		
		Return;
		
	EndIf;
	
	Parameters.Insert("CurrentFile", Parameters.RemainingFiles[0]);
	Parameters.RemainingFiles.Delete(0);
	
	GettingStartFile(Parameters);
	
EndProcedure

Async Function NeedChoiceOfActionsWhenFileDifferencesAreDetectedAsync(Val EditingInformation, Val Parameters,
		Val ContinuationProcedure, Val FileIsBeingOpened)
	
	Parameters.Insert("UseExistingOne", False);
	
	If Not EditingInformation.Saved_ Or Parameters.CurrentFile.Type = "DMFileVersion" Then
		Return False;
	EndIf;
	
	Parameters.Insert("TempFileName", EditingInformation.FullPath);
	Parameters.Insert("TempFilesDir", EditingInformation.RecommendedFolder);
	
	File = New File(EditingInformation.FullPath);
	If Not Await File.ExistsAsync() Then
		Return False;
	EndIf;
	
	// Let's check the date-time of the existing file.
	DateTimeOnDisk = Await File.GetModificationUniversalTimeAsync();
	DateTimeInThe1CDocumentManagement = Date(EditingInformation.UniversalModificationDate);
	DiskSize = Await File.SizeAsync();
	SizeInThe1CDocumentManagement = EditingInformation.Size;
	DateDifference = DateTimeOnDisk - DateTimeInThe1CDocumentManagement;
	
	// Let's determine whether the editing information needs to be updated.
	If Parameters.Property("EditingInformation") And Parameters.Property("ForReading") Then
		If DateDifference <> 0 Or (EditingInformation.ForReading And Not Parameters.ForReading) Then
			Parameters.Insert("UpdateEditInformation", True);
			Parameters.EditingInformation.Insert("UniversalModificationDate", DateTimeOnDisk);
			Parameters.EditingInformation.Insert("Size", DiskSize);
		Else
			Parameters.Insert("UpdateEditInformation", False);
		EndIf;
	EndIf;
	
	// Let's determine whether to ask the user a question, or whether the solution is obvious.
	SizeAndDateMatch = (DateDifference >= -1 And DateDifference <= 1 And SizeInThe1CDocumentManagement = DiskSize);
	FileUnderEditing = (DateDifference > 0 And EditingInformation.ForReading = False);
	
	If FileIsBeingOpened Then
		
		// When opening a file, if the temporary file matches the file BEFORE, or if the file
		// is currently being edited, you don't need to ask anything, use the existing temporary file.
		If (SizeAndDateMatch Or FileUnderEditing) Then
			Parameters.UseExistingOne = True;
			Return False;
		EndIf;
		
	Else
		
		// When saving a file to disk, if the temporary file matches the file BEFORE, you don't need
		// to ask anything, we'll take the file from BEFORE to save it. If the temporary file differs from the file BEFORE, we will ask
		// which file you want to save to disk.
		If SizeAndDateMatch Then
			Return False;
		EndIf;
		
	EndIf;
	
	// there is no certainty, user intervention is required
	FormParameters = New Structure;
	FormParameters.Insert("FullPath", EditingInformation.FullPath);
	FormParameters.Insert("DateTimeOnDisk", DateTimeOnDisk);
	FormParameters.Insert("DateTimeInThe1CDocumentManagement", DateTimeInThe1CDocumentManagement);
	FormParameters.Insert("DiskSize", DiskSize);
	FormParameters.Insert("SizeInThe1CDocumentManagement", SizeInThe1CDocumentManagement);
	
	// Let's formulate the question depending on which of the files is fresh.
	If DateDifference > 0 Then
		// the file on the disk is fresh
		FormParameters.Insert("Title", NStr("vi = 'Trên ổ đĩa có tệp mới';
											|ru = 'На диске новый файл';
											|en = 'A new file on the disk'; fa = 'A new file on the disk';
											|it = 'Nuovo file su disco';
											|pl = 'Na dysku jest nowy plik';
											|tr = 'Diskteki yeni dosya'"));
		FormParameters.Insert("Message",
			NStr("vi = 'Tệp trên ổ đĩa mới hơn tệp trong 1C:Document Management.
				|Có thể là tệp đó đã bị thay đổi.
				|
				|Sử dụng tệp hiện tại hoặc thay thế bằng tệp từ 1C:Document Management
				|và có thể sẽ mất các thay đổi?';
				|ru = 'Файл на диске новее, чем файл в 1С:Документообороте.
				|Возможно, он был изменен.
				|
				|Использовать существующий файл или заменить его на файл из 1С:Документооборота,
				|возможно, с потерей изменений?';
				|en = 'Disk file is newer than the file in 1C:Document Management.
				|It might have been modified.
				|
				|Use the existing file or replace it with the file from 1C:Document Management
				|and possibly lose the changes?'; fa = 'Disk file is newer than the file in 1C:Document Management.
				|It might have been modified.
				|
				|Use the existing file or replace it with the file from 1C:Document Management
				|and possibly lose the changes?';
				|it = 'Il file sul disco è più recente del file in 1C:Document Management.
				|Probabilmente ha subito delle modifiche.
				|
				|Utilizzare il file corrente o sostituirlo con il file da 1C:Document Management
				| con possibile perdita delle modifiche?';
				|pl = 'Plik na dysku jest nowszy, niż plik w 1C:Document Management.
				|Możliwe, że został zmieniony.
				|
				|Używać istniejącego pliku czy zastąpić go plikiem z 1C:Document Management,
				|możliwe, z utratą zmian?';
				|tr = 'Diskteki dosya, 1C:Document Management''taki dosyadan daha yeni.
				|
				|
				|Mevcut dosyayı kullan veya 1C:Document Management''tan
				|dosyayla değiştir, değişiklik kaybıyla mümkün?'"));
	Else
		// the file on the disk is older
		FormParameters.Insert("Title", NStr("vi = 'Trong 1C:Document Management có tệp mới';
											|ru = 'В 1С:Документообороте новый файл';
											|en = 'There is a new file in 1C:Document Management.'; fa = 'There is a new file in 1C:Document Management.';
											|it = 'Nuovo file in 1C:Document Management';
											|pl = 'W 1C:Document Management jest nowy plik';
											|tr = '1C:Document Management''te yeni dosya'"));
		FormParameters.Insert("Message",
			NStr("vi = 'Tệp trong 1C:Document Management mới hơn tệp trên ổ đĩa.
				|Có thể là tệp đã bị thay đổi.
				|
				|Lấy tệp từ 1C:Document Management, sau khi thay thế tệp trên ổ đĩa và
				|mất đi các thay đổi, hoặc sử dụng tệp hiện tại?';
				|ru = 'Файл в 1С:Документообороте новее, чем файл на диске.
				|Возможно, он был изменен.
				|
				|Взять файл из 1С:Документооборота, заменив файл на диске с потерей
				|изменений, или использовать существующий файл?';
				|en = 'File in 1C:Document Management is newer than the one on the disk.
				|It might have been modified.
				|
				|Take the file from 1C:Document Management replacing the file on the disk and lose the
				|changes or use the existing file?'; fa = 'File in 1C:Document Management is newer than the one on the disk.
				|It might have been modified.
				|
				|Take the file from 1C:Document Management replacing the file on the disk and lose the
				|changes or use the existing file?';
				|it = 'Il file su 1C:Document Management è più recente del file su disco.
				|Probabilmente ha subito delle modifiche.
				|
				|Vuoi prendere il file da 1C:Document Management, sostituendolo con il file su disco e perdendo
				|le modifiche, oppure utilizzare il file esistente?';
				|pl = 'Plik w 1C:Document Management jest nowszy, niż plik na dysku.
				|Możliwe, że został zmieniony.
				|
				|Pobrać plik z 1C:Document Management, zastępując plik na dysku z utratą
				|zmian, lub używać istniejącego pliku?';
				|tr = '1C:Document Management''taki dosya, diskteki dosyadan daha yenidir.
				|Belki de değiştirilmiştir.
				|
				|1C:Document Management''ten dosya al
				|, diskteki dosyayı değişiklik kaybıyla değiştirmek veya mevcut dosyayı kullanmak?'"));
	EndIf;
	
	NotificationContinued = New CallbackDescription(
		ContinuationProcedure,
		IntegrationWith1CDocumentManagementCoreClient,
		Parameters);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingActionsWhenFileDifferencesAreFound",
		FormParameters,,,,,
		NotificationContinued,
		FormWindowOpeningMode.LockWholeInterface);
	
	Return True;
	
EndFunction

// Called during the receipt of the file after receiving the file from BEFORE.
//
// Parameters:
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * RemainingFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * UseVisualizationOfItemInstanceStamp - Boolean - it is required to get the binary data of the file with the visualization of the item instance stamp.
//     * ForReading - Boolean - True if the files are saved for reading, and False if for editing.
//     * CallbackDescription - CallbackDescription - called by passing an array of full file names.
//     * FullFileNames - Array of String - full names of files already received.
//     * FormUniqueID - UUID - ID of the calling form.
//     * EditingInformation - See IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile
//     * TempFilesDir - String - the directory to save the temporary file.
//     * TempFileName - String - the name under which the file will be saved.
//     * TempFileStorageAddress - String - the address where the file received from BEFORE is stored.
//
Procedure ReceivingFileAfterReceivingFrom1CDocumentManagement(Parameters)
	
	// Let's collect a description of the received file and get it.
	FilesToObtain = New Array;
	LongDesc = New TransferableFileDescription(
		Parameters.TempFileName,
		Parameters.TempFileStorageAddress);
	FilesToObtain.Add(LongDesc);
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Interactively = False;
	FileSystemClient.SaveFile(
		New CallbackDescription(
			"ProcessTheFileAfterReceivingItFrom1CDocumentManagement",
			IntegrationWith1CDocumentManagementCoreClient,
			Parameters),
		Parameters.TempFileStorageAddress,
		Parameters.TempFileName,
		SavingParameters);
	
EndProcedure

// Retrieves files from BEFORE to the temporary files directory and transfers them for further processing.
//
// Parameters:
//   Files - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData.
//   FormUniqueID - UUID - ID of the calling form.
//   CallbackDescriptionOnCompletion - CallbackDescription - called by passing an array of full file names.
//   ForReading - Boolean - True if the files are saved for reading, and False if for editing.
//
Procedure GetFilesAndContinue(Files, FormUniqueID, CallbackDescriptionOnCompletion,
		ForReading = True)
	
	Parameters = New Structure;
	Parameters.Insert("RemainingFiles", Files);
	Parameters.Insert("UseVisualizationOfItemInstanceStamp", True);
	Parameters.Insert("FullFileNames", New Array);
	Parameters.Insert("FormUniqueID", FormUniqueID);
	Parameters.Insert("CallbackDescription", CallbackDescriptionOnCompletion);
	Parameters.Insert("ForReading", ForReading);
	
	GetFilesStarted(Parameters);
	
EndProcedure

Procedure CheckFileEncryption(FileData)
	
	If FileData.Encrypted Then
		Raise(
			NStr("ru = 'Файл зашифрован. Расшифровка файла доступна только на стороне 1С:Документооборот.';
				|vi = 'The file is encrypted. Decryption is only available in 1C:Document Management.';
				|en = 'The file is encrypted. Decryption is only available in 1C:Document Management.'; fa = 'The file is encrypted. Decryption is only available in 1C:Document Management.';
				|it = 'The file is encrypted. Decryption is only available in 1C:Document Management.';
				|pl = 'The file is encrypted. Decryption is only available in 1C:Document Management.';
				|tr = 'Dosya şifrelenmiş. Dosya şifre çözme işlemi yalnızca 1C:Document Management tarafında mevcuttur.'"));
	EndIf;
	
EndProcedure

// Initialize the scan component.
//
// Returns:
//   Boolean
//
Async Function InitAddInAsync()
	
	If ApplicationParameters["IntegrationWith1CDocumentManagementAddInToGetPicturesFromClipboard"] = Undefined Then
		ReturnCode = Await AttachAddInAsync(
			"CommonTemplate.IntegrationWith1CDocumentManagementAddInToGetPicturesFromClipboard",
			"ImageFromClipboard",
		AddInType.Native);
		
		If Not ReturnCode Then
			Return False;
		EndIf;
		
		ApplicationParameters["IntegrationWith1CDocumentManagementAddInToGetPicturesFromClipboard"] =
			New("AddIn.ImageFromClipboard.AddInNativeExtension");
	EndIf;
	
	Return True;
	
EndFunction

// Returns the result of enabling the file management extension.
//
// Returns:
//   Boolean - in the thin client, it is always True, in the Google Chrome browser, it is always False.
//
Async Function FileSystemExtensionAttached1Async()
	
	If ClientSupportsSynchronousCalls() Then
		Return Await AttachFileSystemExtensionAsync();
	Else
		Return False;
	EndIf;
	
EndFunction

// It is performed during the creation of a file from disk after placing the file (universal completion).
//
// Parameters:
//   Parameters - Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * TempFileStorageAddress - String - the address of the file's temporary storage.
//     * File - File - initialized file.
//     * Owner - AnyRef - file owner.
//     * OwnerID - String - ID of the file owner in the Document Flow.
//     * OwnerType - String - the XDTO type of the file owner in the Document Flow.
//     * OwnerPresentation - String - representation of the file owner.
//     * FullFileName - String - the full name of the file selected by the user.
//     * FullFileNames - Array of String - the names of the added files.
//     * PlacedFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * IsScannedCopy - Boolean - a sign of a scanned copy.
//     * FormUniqueID - UUID - ID of the calling form.
//     * CallbackDescription - CallbackDescription - called on successful End.
//                          - Undefined - there is no need to call anything.
//
Procedure CreateFileFromDiskCompletion(Parameters)
	
	// Let's analyze the full path by name and extension.
	NameStructure = ParseFullFileName(Parameters.FullFileName);
	Parameters.CurrentFile.Description = NameStructure.BaseName;
	Parameters.CurrentFile.Extension = NameStructure.Extension;
	
	CreationParameters = IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions(
		Parameters.CurrentFile);
	CreationParameters.TempFileStorageAddress = Parameters.TempFileStorageAddress;
	CreationParameters.Owner = Parameters.Owner;
	CreationParameters.IsScannedCopy = Parameters.IsScannedCopy;
	
	Parameters.CurrentFile.ID =
		IntegrationWith1CDocumentManagementCoreServerCall.CreateFileInWorkflow(
			CreationParameters,
			Parameters.OwnerID,
			Parameters.OwnerType,
			Parameters.OwnerPresentation);
	
	MessageText = StrTemplate(NStr("vi = 'Đã tạo tệp ""%1""';
									|ru = 'Создан файл ""%1""';
									|en = 'The ""%1"" file is created'; fa = 'The ""%1"" file is created';
									|it = 'Создан файл ""%1""';
									|pl = 'The ""%1"" file is created';
									|tr = '""%1"" dosyası oluşturuldu'"), Parameters.CurrentFile.Description);
	FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
	FileOperation.CreatingFile = True;
	FileOperation.InformFormOfFile = True;
	InformAboutFileChanges(
		FileOperation,
		Parameters.CurrentFile.Description,
		Parameters.CurrentFile.ID,
		Parameters.OwnerID,
		MessageText,,
		Parameters.FormUniqueID);
	
	Parameters.PlacedFiles.Add(Parameters.CurrentFile);
	
	// Are all the files placed?
	If Parameters.FullFileNames.Count() = 0 Then
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.CreatingFile = True;
		FileOperation.InformFileListForm = True;
		InformAboutFileChanges(
			FileOperation,
			Parameters.CurrentFile.Description,
			Parameters.CurrentFile.ID,
			Parameters.OwnerID,,,
			Parameters.FormUniqueID);
		If Parameters.CallbackDescription <> Undefined Then // We will notify you by passing the descriptions.
			RunCallback(Parameters.CallbackDescription, Parameters.PlacedFiles);
		EndIf;
	Else
		// Let's continue the creation.
		Parameters.CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
			Undefined,
			Undefined,
			Parameters.CurrentFile.Type,
			Undefined,
			Parameters.CurrentFile.FileRoleID);
		CreateFilesFromAsyncDisk(Parameters.FullFileNames, Parameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctionsOfElectronicSignatures

Procedure AddSignatureToArray(RowData, SignaturesArray, Signature, ObjectID)
	
	SelectedRow = New Structure("LineNumber, ObjectID");
	SelectedRow.LineNumber = Signature.LineNumber;
	If ObjectID = Undefined Then
		SelectedRow.ObjectID = RowData.ObjectID;
	Else
		SelectedRow.ObjectID = ObjectID;
	EndIf;
	SignaturesArray.Add(SelectedRow);
	
EndProcedure

// Checks whether the client supports synchronous calls.
//
Function ClientSupportsSynchronousCalls()
	
#If WebClient Then
	// The extension does not connect in Chrome.
	SystemInfo = New SystemInfo;
	ApplicationInformationArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
		SystemInfo.UserAgentInformation, " ");
	
	For Each ApplicationInformation In ApplicationInformationArray Do
		If Find(ApplicationInformation, "Chrome") > 0 Then
			Return False;
		EndIf;
	EndDo;
#EndIf
	
	Return True;
	
EndFunction

Procedure UpdateAddressOfObjectSBinaryData(SignatureTable, SelectedSignatures, AddressOfObjectSBinaryData)
	
	If AddressOfObjectSBinaryData = Undefined Then
		AddressOfObjectSBinaryData =
			IntegrationWith1CDocumentManagementCoreClientServer.AddressOfObjectSBinaryData(
				New UUID);
	EndIf;
	
	FilesWithoutBinaryData = New Array;
	For Each RowData In SignatureTable Do
		If Not IntegrationWith1CDocumentManagementCoreClientServer.SignatureHighlighted(
				SelectedSignatures, RowData) Then
			Continue;
		EndIf;
		If RowData.ObjectType <> "DMFile" Then
			Continue;
		EndIf;
		FileBinaryDataAddress = AddressOfObjectSBinaryData.AddressesOfBinaryDataFiles[RowData.ObjectID];
		If Not IsTempStorageURL(FileBinaryDataAddress)
				And FilesWithoutBinaryData.Find(RowData.ObjectID) = Undefined Then
			FilesWithoutBinaryData.Add(RowData.ObjectID);
		EndIf;
	EndDo;
	
	If FilesWithoutBinaryData.Count() > 0 Then
		BinaryFilesData = IntegrationWith1CDocumentManagementCoreServerCall.BinaryFilesData(
			FilesWithoutBinaryData,
			False);
		For Each FileBinaryData In BinaryFilesData Do
			AddressOfObjectSBinaryData.AddressesOfBinaryDataFiles[FileBinaryData.Key] =
				PutToTempStorage(
					FileBinaryData.Value,
					AddressOfObjectSBinaryData.FormUniqueID);
		EndDo;
	EndIf;
	
EndProcedure

// Returns the general settings of the electronic signature.
//
// Returns:
//   Structure:
//     * UseDigitalSignature - Boolean - if True, then electronic signatures are used.
//     * UseEncryption - Boolean - if True, then encryption is used.
//     * VerifyDigitalSignaturesOnTheServer - Boolean - if True, electronic signatures and
//         certificates are checked on the server.
//     * GenerateDigitalSignaturesAtServer - Boolean - if True, electronic signatures are created
//         first on the server, and in case of failure on the client.
//     * ApplicationsDetailsCollection - Array of See DigitalSignatureInternalCached.ApplicationDetails - information about
//         supported cryptography programs.
//
Function GeneralItemInstanceSettings()
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	
	If ClientRunParameters.Property("DigitalSignature") Then
		Return ClientRunParameters.DigitalSignature.CommonSettings;
	Else
		GeneralItemInstanceSettings = New Structure;
		GeneralItemInstanceSettings.Insert("UseDigitalSignature", False);
		GeneralItemInstanceSettings.Insert("UseEncryption", False);
		GeneralItemInstanceSettings.Insert("VerifyDigitalSignaturesOnTheServer", False);
		GeneralItemInstanceSettings.Insert("GenerateDigitalSignaturesAtServer", False);
		GeneralItemInstanceSettings.Insert("ApplicationsDetailsCollection", New Array);
		Return GeneralItemInstanceSettings;
	EndIf;
	
EndFunction

// Verifies one digital signature.
//
// Parameters:
//   RowData - FormDataTreeItem - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//   CryptoManager - CryptoManager - Cryptography Manager object.
//   MatchingObjectIDAndBinaryData - Map of KeyAndValue:
//     * Key - String - object identifier.
//     * Value - BinaryData - binary object data.
//   AddressOfObjectSBinaryData - See IntegrationWith1CDocumentManagementCoreClientServer.AddressOfObjectSBinaryData
//
Procedure VerifySingleSignature(RowData, CryptoManager, MatchingObjectIDAndBinaryData,
		AddressOfObjectSBinaryData)
	
	DSVerificationParameters = IntegrationWith1CDocumentManagementCoreClientServer.DSVerificationParameters(
		RowData,
		MatchingObjectIDAndBinaryData,
		AddressOfObjectSBinaryData);
	If DSVerificationParameters.Signature = Undefined Then
		Return;
	EndIf;
	
	ErrorDescription = "";
	Try
		History = False;
		Certificate = Undefined;
		CryptoManager.VerifySignature(
			DSVerificationParameters.BinaryObjectData,
			DSVerificationParameters.Signature,
			Certificate);
		CheckModesArray = New Array;
		CheckModesArray.Add(CryptoCertificateCheckMode.IgnoreTimeValidity);
		CheckModesArray.Add(CryptoCertificateCheckMode.AllowTestCertificates);
		CryptoManager.CheckCertificate(Certificate, CheckModesArray);
	Except
		History = True;
		Info = ErrorInfo();
		If Info.Cause <> Undefined Then
			ErrorDescription = Info.Cause.Description;
		EndIf;
	EndTry;
	
	RowData.SignatureValidationDate = CurrentDate(); // The use is justified: the date-time is fixed on the client.
	RowData.History = History;
	RowData.SignatureCorrect = Not History;
	RowData.Status = IntegrationWith1CDocumentManagementCoreClientServer.ItemInstanceStatus(History, ErrorDescription);
	RowData.WhoReceivedCertificateAndStatus = RowData.CertificateOwner + Chars.LF + RowData.Status;
	
EndProcedure

Function ItemInstanceVerificationResultString(Signature, Result)
	
	For Each ItemInstanceVerificationResultString In Result Do
		If ItemInstanceVerificationResultString.ObjectID = Signature.ObjectID
				And ItemInstanceVerificationResultString.LineNumber = Signature.LineNumber Then
			Return ItemInstanceVerificationResultString;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion

// Returns active handlers waiting for a background task.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - UUID - ID of the background task.
//     * Value - Array of Structure:
//       ** Owner - ClientApplicationForm
//       ** CallbackOnCompletion - CallbackDescription
//       ** OutputIdleWindow - Boolean
//       ** HideInterface - Boolean
//       ** OldTitle - String
//
Function ActiveBackgroundJobWaitingHandlers()
	
	ParameterName = "IntegrationWith1CDocumentManagementSubsystem.ActiveBackgroundJobWaitingHandlers";
	If ApplicationParameters[ParameterName] = Undefined Then
		Handlers = New Map;
		ApplicationParameters.Insert(ParameterName, Handlers);
	EndIf;
	
	Return ApplicationParameters[ParameterName];
	
EndFunction

Procedure SelectValueOfAdditionalAttributeProcessing(TypeName, Form, Item)
	
	CurrentData = Item.Parent.CurrentData;
	
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
		// Entering a primitive type value - string, number, etc.
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("Item", Item);
		NotificationParameters.Insert("Form", Form);
		Notification = New CallbackDescription(
			"SelectValueOfAdditionalPropsEnterValueCompletion",
			IntegrationWith1CDocumentManagementCoreClient,
			NotificationParameters);
		ShowInputValue(Notification, CurrentData.Value, CurrentData.Property, ValueType);
		
	Else
		
		FormParameters = New Structure;
		
		Owner = New Structure;
		Owner.Insert("ID", CurrentData.PropertyID);
		Owner.Insert("type", CurrentData.PropertyType);
		
		Filter = New Structure;
		If TypeName = "DMObjectPropertyValue"
			Or TypeName = "DMObjectPropertyValueHierarchy" Then
			Filter.Insert("additionalProperty", Owner);
		EndIf;
		
		FormParameters.Insert("Filter", Filter);
		FormParameters.Insert("TypeOfSelectionObject", TypeName);
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("Item", Item);
		NotificationParameters.Insert("Form", Form);
		
		Notification = New CallbackDescription(
			"SelectValueOfAdditionalPropsCompletion",
			IntegrationWith1CDocumentManagementCoreClient,
			NotificationParameters);
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList", FormParameters, Form,,,, Notification);
		
	EndIf;
	
EndProcedure

Procedure ProcessURL1(URL)
	
	URL = TrimAll(StrReplace(URL, Chars.NBSp, " "));
	
EndProcedure

Function FieldStringOfTablePart(Item)
	
	ItemParent = Item.Parent;
	While TypeOf(ItemParent) = Type("FormGroup") Do
		ItemParent = ItemParent.Parent;
	EndDo;
	
	Return ItemParent.CurrentData;
	
EndFunction

#EndRegion
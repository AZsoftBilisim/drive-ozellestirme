////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module integration1sdocumentwork3client: client
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region DynamicList

// Handler for the dynamic list button click event.
//
// Parameters:
//   Form - ClientApplicationForm - the form on which the dynamic list is located.
//   Command - FormCommand - the form command whose name corresponds to the pressed button.
//   CurrentPage - Number - the Cur page number.
//   TotalPages - Number - maximum number of pages.
//   CallbackDescription - CallbackDescription - description of the notification where the number of the selected page will be sent.
//
Procedure SelectDynamicListPage(Form, Command, CurrentPage, TotalPages, CallbackDescription) Export
	
	PageButton = Form.Items[Command.Name];
	
	If PageButton.Title = "..." Then
		Parameters = New Structure;
		Parameters.Insert("CurrentPage", CurrentPage);
		Parameters.Insert("TotalPages", TotalPages);
		Parameters.Insert("CallbackDescription", CallbackDescription);
		Notification = New CallbackDescription("EnteringPageManuallyEnding", ThisObject, Parameters);
		ShowInputNumber(
			Notification,
			CurrentPage,
			NStr("vi = 'Trang';
				|ru = 'Страница';
				|en = 'Page'; fa = 'Page';
				|it = 'Страница';
				|pl = 'Page';
				|tr = 'Sayfa'"),
			StrLen(Format(TotalPages, "NG=0")),
			0);
	Else
		NewPage = Number(PageButton.Title);
		If NewPage <> CurrentPage Then
			RunCallback(CallbackDescription, NewPage);
		EndIf;
	EndIf;
	
EndProcedure

// Updates the header of the dynamic list.
//
// Parameters:
//   Form - ClientApplicationForm - the form on which the dynamic list is located.
//   OldSortingField - String - the name of the dynamic list Attribute that sorting was performed on earlier.
//   SortingField - String - the name of the dynamic list Attribute to sort by.
//   FieldSortingDirection - Boolean - if False, then sort in ascending order, if True, then in descending order.
//   FormKey - String - ID of the form to save the sorting settings to the vault.
//
Procedure ArrangeCommand(Form, OldSortingField, SortingField, FieldSortingDirection,
		FormKey) Export
	
	If OldSortingField <> "" Then
		ElementField = Form.Items[OldSortingField];
#If WebClient Then
		ElementField.Title = StrTemplate("%1 %2", ElementField.ToolTip, AddingHeader(ElementField));
		ElementField.Title = TrimAll(ElementField.Title);
#Else
		If ElementField.HeaderPicture.Type = PictureType.Empty Then
			ElementField.Title = StrTemplate("%1 %2", ElementField.ToolTip, AddingHeader(ElementField));
			ElementField.Title = TrimAll(ElementField.Title);
		Else
			ElementField.Title = "";
			ElementField.Width = 1;
			ElementField.TitleLocation = FormItemTitleLocation.None;
		EndIf;
#EndIf
	EndIf;
	
	StructuresArray = New Array;
	
	Item = New Structure;
	Item.Insert("Object", FormKey);
	Item.Insert("Setting", "FieldSortingDirection");
	Item.Insert("Value", FieldSortingDirection);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", FormKey);
	Item.Insert("Setting", "SortingField");
	Item.Insert("Value", SortingField);
	StructuresArray.Add(Item);
	
	IntegrationWith1CDocumentManagementCoreClient.CommonSettingsStorageSaveArray(StructuresArray);
	
	UpdateSortingInCellHeader(Form, SortingField, FieldSortingDirection);
	
EndProcedure

// Adds a sorting direction symbol for the corresponding field to the header of the dynamic list.
//
// Parameters:
//   Form - ClientApplicationForm - the form on which the dynamic list is located.
//   SortingField - String - the name of the dynamic list Attribute to sort by.
//   FieldSortingDirection - Boolean - if False, then sort in ascending order, if True, then in descending order.
//
Procedure UpdateSortingInCellHeader(Form, SortingField, FieldSortingDirection) Export
	
	If FieldSortingDirection = False Then
		HeadingDirection = SymbolIsAscending();
	Else
		HeadingDirection = SymbolIsDecreasing();
	EndIf;
	
	ElementField = Form.Items[SortingField];
	
#If WebClient Then
	ElementField.Title = StrTemplate("%1 %2 %3",
		ElementField.ToolTip,
		HeadingDirection,
		AddingHeader(ElementField));
	ElementField.Title = TrimAll(ElementField.Title);
#Else
	If ElementField.HeaderPicture.Type = PictureType.Empty Then
		ElementField.Title = StrTemplate("%1 %2 %3",
			ElementField.ToolTip,
			HeadingDirection,
			AddingHeader(ElementField));
		ElementField.Title = TrimAll(ElementField.Title);
	Else
		ElementField.Title = HeadingDirection;
		ElementField.Width = 2;
		ElementField.TitleLocation = FormItemTitleLocation.Right;
	EndIf;
#EndIf
	
EndProcedure

#EndRegion

#Region GeneralProceduresAndFunctions

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
	
	Notification = New CallbackDescription("SelectAValueFromTheListCompletion",
		IntegrationWith1CDocumentManagement3Client, Parameters);
	
	SelectValueByObjectType(Notification, TypeOfSelectionObject, Filter, OwnerForm[Attribute + "ID"], OwnerForm);
	
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
	
	Notification = New CallbackDescription("SelectAValueFromTheListInTheTableCompletion",
		IntegrationWith1CDocumentManagement3Client, Parameters);
	
	SelectValueByObjectType(Notification, TypeOfSelectionObject, Filter, CurrentData[Attribute + "ID"], OwnerForm);
	
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
		IntegrationWith1CDocumentManagement3ClientServer.ObjectTypePresentationXDTO(TypeOfSelectionObject,, True));
	FormParameters.Insert("SelectedElement", ValueSelected);
	
	If IntegrationWith1CDocumentManagement3ClientCached.IsDocumentBefore3(TypeOfSelectionObject)
			Or TypeOfSelectionObject = "DMCorrespondent"
			Or TypeOfSelectionObject = "DMMeeting" Then
		FormParameters.Insert("SearchImmediately", False);
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.SelectingObjectBySearch",
			FormParameters,
			OwnerForm,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	ElsIf TypeOfSelectionObject = "DMFile" Then
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFile",
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
	
EndProcedure

// Opens the employee selection Form by division, and places the selected employee in the Form Attributes.
//
// Parameters:
//   Attribute - String - The name of the Form Attribute that the selected employee will be placed in.
//   OwnerForm - ClientApplicationForm - The Form from which the employee selection Form is called.
//   FillInPresentation - Boolean - indicates whether the employee's Presentation needs to be completed.
//
Procedure SelectEmployeeFromDepartmentTree(Attribute, OwnerForm, FillInPresentation = False) Export
	
	FormName = "DataProcessor.IntegrationWith1CDocumentManagement3.Form.SelectAnEmployeeWithDepartment";
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Attribute", Attribute);
	NotificationParameters.Insert("OwnerForm", OwnerForm);
	NotificationParameters.Insert("FillInPresentation", FillInPresentation);
	
	Notification = New CallbackDescription("SelectEmployeeFromDepartmentTreeCompletion",
		IntegrationWith1CDocumentManagement3Client,
		NotificationParameters);
	
	OpenForm(
		FormName,,
		OwnerForm,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Performs the required interactive action, and reports whether interactive processing has been called or not.
//
// Parameters:
//   ActionResult - See IntegrationWith1CDocumentManagement3.ResultOfCommandOnObject
//   OperationType - See IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask
//   RepeatedAction - CallbackDescription - the method that will be called at the End of interactive processing.
//
// Returns:
//   Boolean
//
Function InteractiveProcessingTriggered(ActionResult, OperationType, RepeatedAction) Export
	
	InteractiveProcessingTriggered = False;
	
	Context = ActionResult.RequiredInteractiveAction.Context;
	
	FillPropertyValues(
		RepeatedAction.AdditionalParameters.RequiredInteractiveAction,
		ActionResult.RequiredInteractiveAction,,
		"Context");
	
	NotificationParameters = NotificationParametersAfterPerformingInteractiveActionOnIssue();
	NotificationParameters.OperationType = OperationType;
	NotificationParameters.RepeatedAction = RepeatedAction;
	NotificationParameters.InitialContext = Context;
	
	If ActionResult.RequiredInteractiveAction.BackToTask Then
		
		// Nothing needs to be done.
		InteractiveProcessingTriggered = True;
		
	ElsIf ActionResult.RequiredInteractiveAction.SelectTaskExecutor Then
		
		CallbackDescription = New CallbackDescription(
			"ProcessExecutionDataAfterSelectingPerformer",
			ThisObject,
			NotificationParameters);
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagement3.Form.SelectActualTaskAssignee",
			ActionResult,,,,,
			CallbackDescription);
		InteractiveProcessingTriggered = True;
		
	ElsIf ActionResult.RequiredInteractiveAction.AskRandomQuestion Then
		
		CallbackDescription = New CallbackDescription(
			"ProcessExecutionDataAfterAnsweringQuestion",
			ThisObject,
			NotificationParameters);
		ShowQuestionBeforeCompletingTask(Context, CallbackDescription);
		InteractiveProcessingTriggered = True;
		
	ElsIf ActionResult.RequiredInteractiveAction.AskQuestionAboutCycleLimit Then
		
		CallbackDescription = New CallbackDescription(
			"ProcessExecutionDataAfterAnsweringQuestionAboutCycleLimit",
			ThisObject,
			NotificationParameters);
		ShowQuestionBeforeCompletingTask(Context, CallbackDescription);
		InteractiveProcessingTriggered = True;
		
	ElsIf ActionResult.RequiredInteractiveAction.ChangeProcessParameters Then
		
		CallbackDescription = New CallbackDescription(
			"ProcessExecutionDataAfterProcessChanges",
			ThisObject,
			NotificationParameters);
		FormParameters = New Structure("DialogMode", True);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			Context.ActionType,
			Context.ActionID,,
			FormParameters,
			CallbackDescription);
		InteractiveProcessingTriggered = True;
	
	ElsIf ActionResult.RequiredInteractiveAction.PerformSigning Then
		
		ModuleDigitalSignatureClient =
			IntegrationWith1CDocumentManagementCoreClient.ModuleDigitalSignatureClient(True);
		If ModuleDigitalSignatureClient <> Undefined Then
			CallbackDescription = New CallbackDescription(
				"ProcessExecutionDataAfterSigning",
				ThisObject,
				NotificationParameters);
			DataSet = New Array;
			For Each CaptionObject In Context.SigningObjects Do
				DataForSignature = New Structure;
				DataForSignature.Insert("Data", CaptionObject.Data);
				DataForSignature.Insert("Presentation", New Structure("Value, Presentation",
					CaptionObject.ObjectBefore, CaptionObject.ObjectBefore.Presentation));
				DataSet.Add(DataForSignature);
			EndDo;
			DataDetails = New Structure;
			DataDetails.Insert("Operation", Context.Operation);
			DataDetails.Insert("DataTitle", Context.DataTitle);
			DataDetails.Insert("DataSet", DataSet);
			DataDetails.Insert("SetPresentation", NStr("ru = 'Объекты (%1)';
														|vi = 'Objects (%1)';
														|en = 'Objects (%1)'; fa = 'Objects (%1)';
														|it = 'Objects (%1)';
														|pl = 'Objects (%1)';
														|tr = 'Nesne (%1)'"));
			ModuleDigitalSignatureClient.Sign(DataDetails, Undefined, CallbackDescription);
		EndIf;
		InteractiveProcessingTriggered = True;
		
	EndIf;
	
	Return InteractiveProcessingTriggered;
	
EndFunction

// Continues execution of the connected integration command after connection verification.
//
// Parameters:
//   Command - FormCommand - the command called.
//   Form - ClientApplicationForm - the form from which the command is called.
//   Source - FormDataStructure, FormTable - the data specifying the command parameter contains a reference to the IC object.
//
Procedure ExecutePlugInIntegrationCommandCompletion(Command, Form, Source) Export
	
	If Command.Name = "IntegrationWith1CDocumentManagement_Files" Then
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

// Fills in the correspondence of BID forms to document management objects.
//
// Parameters:
//   MatchingForms - Map of KeyAndValue - implicitly returned value, matching forms.
//
Procedure FillInMatchingForms(MatchingForms) Export
	
	MatchingForms.Insert("DMTaskAction", "Task");
	MatchingForms.Insert("DMActionApproval", "ApprovalAction");
	MatchingForms.Insert("DMActionPerformance", "ExecutionAction");
	MatchingForms.Insert("DMActionExamination", "PreviewAction");
	MatchingForms.Insert("DMActionSigning", "SigningAction");
	MatchingForms.Insert("DMActionRegistration", "RegistrationAction");
	MatchingForms.Insert("DMActionConfirmation", "ConfirmationAction");
	
EndProcedure

// Changes the relative time (days, hours, minutes) by adding the transmitted duration.
// If the minutes are filled, then only the minutes change.
// If there are no minutes and the clock is full, then only the clock changes.
// If only the days are filled in, then only they change.
//
// Parameters:
//   Days - Number - duration, days.
//   Hours1 - Number - duration, hours.
//   Minutes1 - Number - duration, minutes.
//   Duration - Number - duration to add. To reduce the term, use "-1", to increase "1".
//
Procedure ChangeRelativeTerm(Days, Hours1, Minutes1, Duration) Export
	
	If ValueIsFilled(Minutes1) Then
		Minutes1 = Minutes1 + Duration;
	ElsIf ValueIsFilled(Hours1) Then
		Hours1 = Hours1 + Duration;
	Else
		Days = Days + Duration;
	EndIf;
	
	If Minutes1 > 59 Then
		Minutes1 = Minutes1 - 60;
		Hours1 = Hours1 + 1;
	EndIf;
	
	If Hours1 > 23 Then
		Hours1 = Hours1 - 23;
		Days = Days + 1;
	EndIf;
	
	If Days > 999 Then
		Days = 999;
	EndIf;
	
EndProcedure

// Handler for an event that occurs when you click (click with the mouse or using the keyboard) on any element
// of the statement for an expression in the built-in language.
//
// Parameters:
//   Item - FormField - a Form element of the "HTML document field" type.
//   EventData - FixedStructure - the parameter is filled with a fixed structure with properties:
//     * Anchor - ExternalObject
//     * Element - ExternalObject
//     * Button - ExternalObject
//     * Event - ExternalObject
//     * Document - ExternalObject
//     * HRef - ExternalObject
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//
Procedure InstructionOnClick(Item, EventData, StandardProcessing) Export
	
#If Not WebClient Then
	If ThisIsDisclosedGroup(EventData.Button) Or ThisIsDisclosedGroup(EventData.Element) Then
		// If the user has clicked on the drop-down group, then only standard processing is required.
		Return;
	EndIf;
	
	// Otherwise, we will process clicking on the hyperlink.
	StandardProcessing = False;
#EndIf
	
	If Not ValueIsFilled(EventData.HRef) Then
		Return;
	EndIf;
	
	Position = StrFind(EventData.HRef, "#", SearchDirection.FromEnd);
	Ref = Mid(EventData.HRef, Position + 1);
	FormParameters = New Structure;
	FormParameters.Insert("Ref", Ref);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.WebServiceDescription",
		FormParameters, ThisObject,,,,, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// Generates a Form tree string key.
//
// Parameters:
//   TreeType - See IntegrationWith1CDocumentManagement3Client.TreeType
//   TreeRow - ValueTreeRow
//
// Returns:
//   String
//
Function TreeRowKey(TreeType, TreeRow) Export
	
	If TreeType.ThisIsProcessingTree Then
		Return ProcessingTreeRowKey(TreeRow);
		
	ElsIf TreeType.ThisIsApplicationTree Then
		Return ApplicationTreeRowKey(TreeRow);
		
	ElsIf TreeType.ThisIsTreeOfCODESUBAssets Then
		Return KeyOfTreeStringSUBAssetsIsCODE(TreeRow);
		
	EndIf;
	
EndFunction

// Performs the creation of the object BEFORE, its filling in by the IC object and establishing communication after recording. If
// necessary, it offers the user a choice of rules.
//
// Parameters:
//   ObjectIS - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object
//     on the basis of which the DO object is created.
//   CallbackDescription - CallbackDescription - the handler that is called after creation.
//   UsePriorityRules - Boolean - do I need to ask the user a question if
//     several different integration rules are configured for the IP object, or do I need to use the rule that has the highest
//     priority in terms of key Attributes?
//   AskQuestionAboutFileTransfer - Boolean - indicates whether you want to ask a question about transferring files from the IP to BEFORE
//      after adding a new link.
//
Procedure StartCreatingARelatedObjectDM(ObjectIS, CallbackDescription = Undefined,
		UsePriorityRules = False, AskQuestionAboutFileTransfer = True) Export
	
	If ObjectIS.IsEmpty() Then
		ErrorText = NStr("vi = 'Chưa đặt hoặc chưa ghi lại đối tượng liên kết của hệ thống được tích hợp.';
						|ru = 'Связанный объект интегрированной системы не задан или не записан.';
						|en = 'A linked object of the integrated system is not set or not saved.'; fa = 'A linked object of the integrated system is not set or not saved.';
						|it = 'Связанный объект интегрированной системы не задан или не записан.';
						|pl = 'A linked object of the integrated system is not set or not saved.';
						|tr = 'İlgili entegre sistem nesnesi tanımlanmamış veya kaydedilmemiş.'");
		ShowMessageBox(,ErrorText,, NStr("vi = 'Không thể tạo đối tượng 1C:Document Management';
										|ru = 'Не удалось создать объект 1С:Документооборота';
										|en = 'Cannot create a 1C:Document Management object'; fa = 'Cannot create a 1C:Document Management object';
										|it = 'Non è stato possibile creare l''oggetto di 1C:Document Management';
										|pl = 'Nie udało się utworzyć obiektu w 1C:Document Management';
										|tr = '1C:Document Management nesnesi oluşturulamadı'"));
		Return
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("ObjectIS", ObjectIS);
	Parameters.Insert("CallbackDescription", CallbackDescription);
	Parameters.Insert("AskQuestionAboutFileTransfer", AskQuestionAboutFileTransfer);
	
	ListOfIPObjects = New Array;
	ListOfIPObjects.Add(ObjectIS);
	SuitableIntegrationRules = IntegrationWith1CDocumentManagement3ServerCall.SuitableIntegrationRules(
		ListOfIPObjects,
		UsePriorityRules,
		True);
	Rules = SuitableIntegrationRules[ObjectIS];
	If Rules = Undefined Then
		Rules = New Array;
	EndIf;
	
	If Rules.Count() = 1 Then
		
		StartCreatingLinkedObjectDMAfterSelectingRule(Rules[0], Parameters);
		
	ElsIf Rules.Count() > 1 Then
		
		// Multiple rules, user selection required.
		DescriptionOfContinuationNotification = New CallbackDescription(
			"StartCreatingLinkedObjectDMAfterSelectingRule",
			IntegrationWith1CDocumentManagement3Client,
			Parameters);
		
		FormParameters = New Structure;
		FormParameters.Insert("Rules", Rules);
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingRule",
			FormParameters,,,,,
			DescriptionOfContinuationNotification,
			FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		ErrorText = StrTemplate(NStr("vi = 'Đối với đối tượng %1 không có quy tắc tích hợp phù hợp.';
									|ru = 'Для объекта %1 нет подходящих правил интеграции.';
									|en = 'There are no suitable integration rules for the %1 object.'; fa = 'There are no suitable integration rules for the %1 object.';
									|it = 'Non vi è alcuna regola di integrazione adatta per l''oggetto %1.';
									|pl = 'Dla obiektu %1 brak pasujących reguł integracji.';
									|tr = '%1 nesnesi için uygun kural entegrasyonu mevcut değil.'"), ObjectIS);
		ShowMessageBox(,ErrorText,, NStr("vi = 'Không thể tạo đối tượng 1C:Document Management';
										|ru = 'Не удалось создать объект 1С:Документооборота';
										|en = 'Cannot create a 1C:Document Management object'; fa = 'Cannot create a 1C:Document Management object';
										|it = 'Non è stato possibile creare l''oggetto di 1C:Document Management';
										|pl = 'Nie udało się utworzyć obiektu w 1C:Document Management';
										|tr = '1C:Document Management nesnesi oluşturulamadı'"));
		
	EndIf;
	
EndProcedure

// Performs the creation of the object BEFORE, its filling in by the IC object and establishing communication after recording. If
// necessary, it offers the user a choice of rules.
//
// Parameters:
//   Result - CatalogRef.RulesForIntegrationWith1CDocumentManagement - filling rule.
//   Parameters - Structure:
//     * ObjectIS - Arbitrary - the IP object, on the basis of which the object is created BEFORE.
//     * CallbackDescription - CallbackDescription - the handler that is called after creation.
//     * AskQuestionAboutFileTransfer - Boolean - indicates whether you want to ask a question about transferring files from the IP to BEFORE
//         after adding a new link.
//
Procedure StartCreatingLinkedObjectDMAfterSelectingRule(Val Result, Parameters) Export
	
	If Result = Undefined Or Result = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("CatalogRef.RulesForIntegrationWith1CDocumentManagement3") Then
		Parameters.Insert("Rule", Result);
		
	ElsIf TypeOf(Result) = Type("Structure") Then
		Parameters.Insert("Rule", Result.Ref);
		
	EndIf;
	
	PreliminaryData = IntegrationWith1CDocumentManagement3ServerCall.PreliminaryDataForUnloadingVDO(
		Parameters.ObjectIS,
		Parameters.Rule);
	Parameters.Insert("PreliminaryDataInRepository", PreliminaryData.PreliminaryDataInRepository);
	RequiredLinks = PreliminaryData.RequiredLinks;
	
	Parameters.Insert("FormUniqueID", New UUID);
	If Parameters.CallbackDescription <> Undefined
			And TypeOf(Parameters.CallbackDescription.Module) = Type("ClientApplicationForm") Then
		Parameters.FormUniqueID = Parameters.CallbackDescription.Module.UUID;
	EndIf;
	
	For Each NewObjectBefore In PreliminaryData.NewObjectsBefore Do
		IntegrationWith1CDocumentManagementCoreClient.Notify_AddingConnection(
			NewObjectBefore.ID,
			NewObjectBefore.Type,
			NewObjectBefore.ObjectReference,
			Parameters.AskQuestionAboutFileTransfer,
			Parameters.FormUniqueID);
	EndDo;
	
	If RequiredLinks.Count() = 0 Then
		
		StartCreatingLinkedObjectBEFOREAfterSelectingRuleAndMandatoryLink(New Array, Parameters);
		
	Else
		
		FormParameters = New Structure("RequiredLinks", RequiredLinks);
		CallbackDescription = New CallbackDescription(
			"StartCreatingLinkedObjectBEFOREAfterSelectingRuleAndMandatoryLink",
			ThisObject,
			Parameters);
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.CreatingRequiredLinks",
			FormParameters,,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	EndIf;
	
EndProcedure

// Continues to create a new Document management object after selecting the required links.
//
// Parameters:
//   LinksToCreation - Array of See IntegrationWith1CDocumentManagementCoreClientServer.ConnectionToCreation
//   Parameters - Structure:
//     * ObjectIS - Arbitrary - the IP object, on the basis of which the object is created BEFORE.
//     * CallbackDescription - CallbackDescription - the handler that is called after creation.
//     * AskQuestionAboutFileTransfer - Boolean - indicates whether you want to ask a question about transferring files from the IP to BEFORE
//         after adding a new link.
//     * Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - rule for filling in an item BEFORE.
//     * PreliminaryDataInRepository - String - the address in the temporary storage containing
//         the structure See IntegrationWith1CDocumentManagement3.PreliminaryDataForUnloadingVDO
//     * FormUniqueID - UUID - ID of the calling form.
//
Procedure StartCreatingLinkedObjectBEFOREAfterSelectingRuleAndMandatoryLink(LinksToCreation, Parameters) Export
	
	If TypeOf(LinksToCreation) <> Type("Array") Then
		Return;
	EndIf;
	
	ObjectDMOrMessage = IntegrationWith1CDocumentManagementCoreServerCall.CreateMapItemUsingRule(
		Parameters.ObjectIS,
		Parameters.Rule,
		LinksToCreation,
		Parameters.PreliminaryDataInRepository);
	
	If TypeOf(ObjectDMOrMessage) = Type("String") Then // error message.
		
		ShowWarningFromBEFORE(,ObjectDMOrMessage,,
			NStr("vi = 'Không thể tạo đối tượng 1C:Document Management';
				|ru = 'Не удалось создать объект 1С:Документооборота';
				|en = 'Cannot create a 1C:Document Management object'; fa = 'Cannot create a 1C:Document Management object';
				|it = 'Non è stato possibile creare l''oggetto di 1C:Document Management';
				|pl = 'Nie udało się utworzyć obiektu w 1C:Document Management';
				|tr = '1C:Document Management nesnesi oluşturulamadı'"));
		
	Else // A structure with a description of the created result object.
		
		IntegrationWith1CDocumentManagementCoreClient.Notify_AddingConnection(
			ObjectDMOrMessage.ID,
			ObjectDMOrMessage.type,
			Parameters.ObjectIS,
			Parameters.AskQuestionAboutFileTransfer,
			Parameters.FormUniqueID);
		If Parameters.CallbackDescription <> Undefined Then
			If TypeOf(Parameters.CallbackDescription.AdditionalParameters) = Type("Structure") Then
				Parameters.CallbackDescription.AdditionalParameters.Insert("NewObjectWasCreatedBEFORE", True);
			EndIf;
			RunCallback(Parameters.CallbackDescription, ObjectDMOrMessage);
		EndIf;
		
	EndIf;
	
EndProcedure

// Launches the integrated database BEFORE and follows the specified link.
//
// Parameters:
//   ObjectReferenceBefore - String - the navigation link you want to click on in the database BEFORE.
//     If the parameter is omitted, the link will be taken from the integration session parameter 1documentobject d.
//   AddressOfDatabaseBEFORE - String - the address of the database publication that you want to open.
//
Procedure OpenDMObject(Val ObjectReferenceBefore = Undefined, Val AddressOfDatabaseBEFORE = "") Export
	
	If ObjectReferenceBefore = Undefined Then
		ObjectReferenceBefore = IntegrationWith1CDocumentManagement3ServerCall.GetLinkToObjectBefore();
	EndIf;
	
	If Not ValueIsFilled(ObjectReferenceBefore) Then
		Return;
	EndIf;
	
	If AddressOfDatabaseBEFORE = "" Then
		AddressOfDatabaseBEFORE = IntegrationWith1CDocumentManagement3ServerCall.NavigationLinkOfDatabaseDM(True);
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenURL(
		StrTemplate("%1#%2", AddressOfDatabaseBEFORE, ObjectReferenceBefore));
	
EndProcedure

// Opens the object for viewing.
//
// Parameters:
//   ObjectIS - AnyRef - reference to the IP object.
//   ObjectBefore - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//   FileExtention - String - file extension.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure OpenPlaceForViewing(ObjectIS, ObjectBefore, FileExtention, FormUniqueID) Export
	
	If ValueIsFilled(ObjectIS) Then
		ShowValue(, ObjectIS);
		
	ElsIf ObjectBefore.Type = "DMFile" Then
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			ObjectBefore.ID,
			ObjectBefore.Description,
			FileExtention,
			FormUniqueID);
		
	ElsIf ObjectBefore.Type = "DMIncomingElectronicDocument" Or ObjectBefore.Type = "DMOutgoingElectronicDocument" Then
		Description = "";
		FileExtention = "";
		FileAddress = IntegrationWith1CDocumentManagement3ServerCall.GetDocumentFileAndPutItInRepository(
			ObjectBefore.ID,
			ObjectBefore.Type,
			FormUniqueID,
			FileExtention,
			Description);
		If ThisIsFormalizedEDODocument(FileExtention) And ValueIsFilled(ObjectBefore.URL) Then
			OpenDMObject(ObjectBefore.URL);
		Else
			IntegrationWith1CDocumentManagementCoreClient.OpenReceivedFile(
				FileAddress,
				Description,
				FileExtention,
				FormUniqueID);
		EndIf;
		
	ElsIf ValueIsFilled(ObjectBefore.URL)
			And (IntegrationWith1CDocumentManagement3ClientCached.IsDocumentBefore3(ObjectBefore.Type)
				Or ObjectBefore.Type = "DMCorrespondent"
				Or ObjectBefore.Type = "DMMeeting") Then
		OpenDMObject(ObjectBefore.URL);
		
	Else
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			ObjectBefore.Type,
			ObjectBefore.ID,
			ThisObject);
		
	EndIf;
	
EndProcedure

// Displays a warning window. In the text of the warning, navigation links to PRE- and IP objects
// are converted into hyperlinks.
//
// Parameters:
//   CallbackDescriptionOnCompletion - CallbackDescription - contains a description of the procedure that will
//     be called after the warning window is closed.
//   WarningText - String - warning text.
//   Timeout - Number - the time interval in seconds during which the system will wait for the user's response.
//     After the interval has elapsed, the warning window will be closed.
//     If the parameter is not specified, then the waiting time is unlimited.
//     If the parameter has a negative value, an exception will be thrown.
//   Title - String - contains the title of the warning window.
//     If not set, the dialog title is not displayed.
//
Procedure ShowWarningFromBEFORE(CallbackDescriptionOnCompletion = Undefined, WarningText, Timeout = 0,
		Title = Undefined) Export
	
	TextDocument = New TextDocument;
	TextDocument.SetText(WarningText);
	RowsArray = New Array;
	ReferenceToObjectIsSetTo = False;
	TitleOfLinkToIPObject = StrTemplate(
		NStr("vi = 'Tham chiếu đến đối tượng trong %1';
			|ru = 'Ссылка на объект в %1';
			|en = 'Reference to the object in %1'; fa = 'Reference to the object in %1';
			|it = 'Reference to the object in %1';
			|pl = 'Reference to the object in %1';
			|tr = '%1 dahilindeki nesne bağlantısı'"),
		IntegrationWith1CDocumentManagementCoreServerCall.AbbreviatedNameOfConfiguration());
	For LineNumber = 1 To TextDocument.LineCount() Do
		If LineNumber > 1 Then
			RowsArray.Add(New FormattedString(Chars.LF));
		EndIf;
		CurrentRow = TextDocument.GetLine(LineNumber);
		URL = "";
		RefStart = StrFind(CurrentRow, "e1cib/data/");
		LinkLength = StrFind(CurrentRow, "?ref=") + 37 - RefStart;
		If RefStart > 0 And LinkLength > RefStart Then
			URL = Mid(CurrentRow, RefStart, LinkLength);
		EndIf;
		If Not IsBlankString(URL) Then
			If StrFind(CurrentRow, NStr("vi = 'Tham chiếu đến đối tượng trong hệ thống thông tin:';
										|ru = 'Ссылка на объект в ИС:';
										|en = 'Reference to the object in IS:'; fa = 'Reference to the object in IS:';
										|it = 'Reference to the object in IS:';
										|pl = 'Reference to the object in IS:';
										|tr = 'Entegre Sistemindeki nesne bağlantısı:'")) = 1 Then
				RowsArray.Add(StringFunctionsClient.FormattedString(
					StrTemplate("<a href = ""%1"">%2</a>", URL, TitleOfLinkToIPObject)));
			ElsIf Not ReferenceToObjectIsSetTo Then
				IntegrationWith1CDocumentManagement3ServerCall.SetObjectReferenceTO(URL);
				ReferenceToObjectIsSetTo = True;
				RepresentationOfTheReference = StrTemplate(
					"<a href = ""e1cib/command/DataProcessor.IntegrationWith1CDocumentManagement3.Command.OpenDMObject"">%1</a>",
					NStr("vi = 'Tham chiếu đến đối tượng trong DM';
						|ru = 'Ссылка на объект в ДО';
						|en = 'Reference to an object in DI'; fa = 'Reference to an object in DI';
						|it = 'Ссылка на объект в ДО';
						|pl = 'Reference to an object in DI';
						|tr = 'İş Akışındaki nesne bağlantısı:'"));
				If StrFind(CurrentRow, NStr("vi = 'Tham chiếu đến đối tượng trong DM';
											|ru = 'Ссылка на объект в ДО:';
											|en = 'Reference to the object in DI:'; fa = 'Reference to the object in DI:';
											|it = 'Reference to the object in DI:';
											|pl = 'Reference to the object in DI:';
											|tr = 'İş Akışındaki nesne bağlantısı:'")) = 1 Then
					RowsArray.Add(StringFunctionsClient.FormattedString(RepresentationOfTheReference));
				Else
					RowsArray.Add(New FormattedString(Left(CurrentRow, RefStart - 1)));
					RowsArray.Add(StringFunctionsClient.FormattedString(RepresentationOfTheReference));
					RowsArray.Add(New FormattedString(Mid(CurrentRow, RefStart + LinkLength)));
				EndIf;
			Else
				RowsArray.Add(New FormattedString(CurrentRow));
			EndIf;
		Else
			RowsArray.Add(New FormattedString(CurrentRow));
		EndIf;
	EndDo;
	
	ShowMessageBox(
		CallbackDescriptionOnCompletion,
		New FormattedString(RowsArray),
		Timeout,
		Title);
	
EndProcedure

// Unfolds the tree on the Form.
//
// Parameters:
//   TreeType - See IntegrationWith1CDocumentManagement3Client.TreeType
//   TreeRows - FormDataTreeItemCollection - tree data on the Form.
//   FormTable - FormTable - the Form element where the tree is displayed.
//   CurCurrentStateOfTree - See IntegrationWith1CDocumentManagement3Client.CurCurrentStateOfTree
//
Procedure ExpandTheTree(TreeType, TreeRows, FormTable, CurCurrentStateOfTree = Undefined) Export
	
	If CurCurrentStateOfTree = Undefined Then
		
		If TreeType.ThisIsProcessingTree Then
			ExpandProcessingTree(TreeRows, FormTable);
			
		ElsIf TreeType.ThisIsApplicationTree Then
			ExpandApplicationTree(TreeRows, FormTable);
			
		ElsIf TreeType.ThisIsTreeOfCODESUBAssets Then
			ExpandTreeOfSUBAssetsCODE(TreeRows, FormTable);
			
		EndIf;
		
	Else
		
		CurrentTreeRow = Undefined;
		ExpandTreeRows(
			TreeType,
			TreeRows,
			FormTable,
			CurCurrentStateOfTree.StateIsDeployed,
			CurCurrentStateOfTree.KeyOfCurRowOfTree,
			CurrentTreeRow);
		
		If CurrentTreeRow <> Undefined Then
			FormTable.CurrentRow = CurrentTreeRow.GetID();
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns the Cur State of the tree on the Form.
//
// Parameters:
//   TreeType - See IntegrationWith1CDocumentManagement3Client.TreeType
//   TreeRows - FormDataTreeItemCollection - tree data on the Form.
//   FormTable - FormTable - the Form element where the tree is displayed.
//
// Returns:
//   Structure:
//     * StateIsDeployed - Map of KeyAndValue:
//       ** Key - String
//       ** Value - Boolean
//     * KeyOfCurRowOfTree - String
//
Function CurCurrentStateOfTree(TreeType, TreeRows, FormTable) Export
	
	If TreeRows.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	CurCurrentStateOfTree = New Structure("StateIsDeployed, KeyOfCurRowOfTree");
	
	CurCurrentStateOfTree.StateIsDeployed = New Map;
	FillInStateOfTreeRows(
		TreeType,
		TreeRows,
		FormTable,
		CurCurrentStateOfTree.StateIsDeployed);
	
	If FormTable.CurrentData = Undefined Then
		TreeRow = TreeRows[0];
	Else
		TreeRow = FormTable.CurrentData;
	EndIf;
	CurCurrentStateOfTree.KeyOfCurRowOfTree = TreeRowKey(TreeType, TreeRow);
	
	Return CurCurrentStateOfTree;
	
EndFunction

// Constructor of the structure describing the type of tree.
//
// Returns:
//   Structure:
//     * ThisIsApplicationTree - Boolean
//     * ThisIsProcessingTree - Boolean
//     * ThisIsTreeOfCODESUBAssets - Boolean
//
Function TreeType() Export
	
	TreeType = New Structure;
	TreeType.Insert("ThisIsApplicationTree", False);
	TreeType.Insert("ThisIsProcessingTree", False);
	TreeType.Insert("ThisIsTreeOfCODESUBAssets", False);
	
	Return TreeType;
	
EndFunction

#EndRegion

#Region CommandProcessing

// The handler of the general integration command1sdocumentation to start processing
//
// Parameters:
//   ReferencesArrray - Arbitrary - the parameter is passed the value from the source in which the command is implemented.
//     It can contain either a single value or an array of values.
//   ExecutionParameters - CommandExecuteParameters - in the command handler, you can change the value
//     of the parameter properties.
//
Procedure ProcessingStartProcessingCommand(Val ReferencesArrray, ExecutionParameters) Export
	
	If TypeOf(ReferencesArrray) <> Type("Array") Then
		ReferencesArrray = CommonClientServer.ValueInArray(ReferencesArrray);
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"StartProcessingCheckConnectionEnd",
		ThisObject,
		ReferencesArrray);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,
		True);
	
EndProcedure

#EndRegion

#Region Files

// Opens the role selection form for the selected files.
//
// Parameters:
//   FilesTree - FormDataTree - The Form Attribute containing the file tree.
//   ElementsOfFileTree - FormTable - a form element containing a file tree.
//   FormParameters - Structure - parameters of the role selection Form:
//     * FilesOwner - String - ID of the DO object that owns the files.
//     * AvailableRoles - ValueList of String - available file roles.
//     * IdOfOwnerSForm - UUID - ID of the Form from which the selection is being made.
//     * UseFileRoles - Boolean - indicates whether file roles are used.
//
Procedure ChooseFileRole(FilesTree, ElementsOfFileTree, FormParameters) Export
	
	If Not FormParameters.UseFileRoles Or FormParameters.AvailableRoles.Count() = 0 Then
		CommonClient.MessageToUser(
			NStr("ru = 'Для данного вида документов не настроены роли файлов.';
				|vi = 'File roles are not configured for this document type.';
				|en = 'File roles are not configured for this document type.'; fa = 'File roles are not configured for this document type.';
				|it = 'File roles are not configured for this document type.';
				|pl = 'File roles are not configured for this document type.';
				|tr = 'Bu belge türü için dosya rolleri yapılandırılmadı.'"));
		Return;
	EndIf;
	
	ListOfFiles = IntegrationWith1CDocumentManagementCoreClient.Selected_Files(
		FilesTree,
		ElementsOfFileTree.SelectedRows);
	
	If ListOfFiles.Count() = 0 Then
		Return;
	EndIf;
	
	FormParameters.Insert("SelectedRole", CurCurrentFileRole(FilesTree, ElementsOfFileTree.CurrentRow));
	FormParameters.Insert("ListOfFiles", ListOfFiles);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.SelectRolesForFile",
		FormParameters,
		ThisObject);
	
EndProcedure

// Asks the user a question about transferring files from the IP to the DO, and initiates the transfer if the answer is yes.
//
// Parameters:
//   FileTransferOptions - See IntegrationWith1CDocumentManagementCore.ParametersForTransferringFilesToDM
//   NotificationToPerformTransfer - CallbackDescription - the procedure to be performed if
//     the user's answer is yes.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure ToAskQuestionAboutTransferringFilesToDM(FileTransferOptions, NotificationToPerformTransfer = Undefined,
		FormUniqueID = Undefined) Export
	
	QueryText = StrTemplate(
		NStr("vi = 'Trong %1 ""%2"" có các tệp đính kèm được lưu trong %3.
			|
			|Chuyển tệp dữ liệu %1 từ %3 sang 1C:Document Management?';
			|ru = 'У %1 ""%2"" есть присоединенные файлы, хранящиеся на стороне %3.
			|
			|Перенести файлы данного %1 из %3 в 1С:Документооборот?';
			|en = 'The ""%2"" %1 has attachments stored in %3.
			|
			|Do you want to transfer the files of the %1 from %3 to 1C:Document Management?'; fa = 'The ""%2"" %1 has attachments stored in %3.
			|
			|Do you want to transfer the files of the %1 from %3 to 1C:Document Management?';
			|it = 'У %1 ""%2"" есть присоединенные файлы, хранящиеся на стороне %3.
			|
			|Перенести файлы данного %1 из %3 в 1С:Документооборот?';
			|pl = 'The ""%2"" %1 has attachments stored in %3.
			|
			|Do you want to transfer the files of the %1 from %3 to 1C:Document Management?';
			|tr = '%1 ""%2""  %3tarafında saklanan ekli dosyalar mevcut.
			|
			| %1 veri dosyalarını %3 dan 1C:Document Management''te taşı?'"),
		FileTransferOptions.OwnerTypePresentation,
		String(FileTransferOptions.OwnerIS),
		FileTransferOptions.AbbreviatedNameOfConfiguration);
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes);
	Buttons.Add(DialogReturnCode.No);
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		Buttons.Add("ShowFiles", NStr("ru = 'Показать файлы';
										|vi = 'Show files';
										|en = 'Show files'; fa = 'Show files';
										|it = 'Show files';
										|pl = 'Show files';
										|tr = 'Dosyaları göster'"));
	EndIf;
	WarningParameters = StandardSubsystemsClient.QuestionToUserParameters();
	WarningParameters.DefaultButton = DialogReturnCode.Yes;
	WarningParameters.Title = NStr("vi = 'Chuyển tệp vào 1C:Document Management';
									|ru = 'Перенос файлов в 1С:Документооборот';
									|en = 'File transfer to 1C:Document Management'; fa = 'File transfer to 1C:Document Management';
									|it = 'Перенос файлов в 1С:Документооборот';
									|pl = 'File transfer to 1C:Document Management';
									|tr = '1C:Document Management''te dosya seçimi'");
	WarningParameters.Picture = PictureLib.Information32;
	IntegrationWith1CDocumentManagementCoreClientOverridable.WhenDeterminingNeedToSuggestNoLongerAskingThisQuestion(
		WarningParameters.PromptDontAskAgain,
		QueryText,
		FileTransferOptions.FileCatalogType,
		"AskQuestionAboutTransferringFilesToDM");
	If WarningParameters.PromptDontAskAgain Then
		WarningParameters.CheckBoxText =
			StrTemplate(
				NStr("vi = 'Không hiển thị nữa (có thể sẽ chuyển thủ công dưới dạng danh sách các tệp bằng lệnh ""Thêm - Tệp %1"")';
					|ru = 'Больше не показывать (перенос можно будет выполнить вручную в форме списка файлов командой ""Добавить - Файлы %1"")';
					|en = 'Do not show again. You can click ""Add > %1 files"" in the file list form to transfer them manually'; fa = 'Do not show again. You can click ""Add > %1 files"" in the file list form to transfer them manually';
					|it = 'Больше не показывать (перенос можно будет выполнить вручную в форме списка файлов командой ""Добавить - Файлы %1"")';
					|pl = 'Do not show again. You can click ""Add > %1 files"" in the file list form to transfer them manually';
					|tr = 'Artık gösterilmiyor (""Ekle - Dosyalar %1"" komutu ile dosya listesi formunda aktarım manuel olarak yapılabilir)'"),
				FileTransferOptions.OwnerTypePresentation);
	EndIf;
	NotificationParameters = New Structure;
	NotificationParameters.Insert("FileTransferOptions", FileTransferOptions);
	NotificationParameters.Insert("NotificationToPerformTransfer", NotificationToPerformTransfer);
	NotificationParameters.Insert("FormUniqueID", FormUniqueID);
	CallbackDescription = New CallbackDescription(
		"ToAskQuestionAboutTransferringFilesToDMContinued",
		ThisObject,
		NotificationParameters);
	StandardSubsystemsClient.ShowQuestionToUser(
		CallbackDescription,
		QueryText,
		Buttons,
		WarningParameters);
	
EndProcedure

// Continuation of the procedure to set the file transfer request.
//
// Parameters:
//   Result - Structure:
//     * NeverAskAgain - Boolean - the result of the user's choice in the checkbox of the same name.
//     * Value - DialogReturnCode - the result of the user's choice: the value associated with the pressed button.
//   NotificationParameters - Structure:
//     * FileTransferOptions - See IntegrationWith1CDocumentManagementCore.ParametersForTransferringFilesToDM
//     * NotificationToPerformTransfer - CallbackDescription - the procedure to be performed if
//         the user's answer is yes.
//     * FormUniqueID - UUID - ID of the calling form.
//
Procedure ToAskQuestionAboutTransferringFilesToDMContinued(Result, NotificationParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.NeverAskAgain Then
		CommonServerCall.CommonSettingsStorageSave(
			NotificationParameters.FileTransferOptions.FileCatalogType,
			"AskQuestionAboutTransferringFilesToDM",
			False);
		RefreshReusableValues();
	EndIf;
	
	If Result.Value = DialogReturnCode.Yes Then
		If NotificationParameters.NotificationToPerformTransfer = Undefined Then
			TransferFilesAndSvTO(
				NotificationParameters.FileTransferOptions.AttachedVISFiles,
				NotificationParameters.FileTransferOptions.OwnerID,
				NotificationParameters.FileTransferOptions.OwnerType,
				NotificationParameters.FileTransferOptions.OwnerIS,,
				NotificationParameters.FormUniqueID);
		Else
			If ValueIsFilled(NotificationParameters.FileTransferOptions.OwnerID) Then // The associated object is already known.
				RunCallback(NotificationParameters.NotificationToPerformTransfer, Undefined);
			Else // The linked object should be found or created.
				IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
					NotificationParameters.FileTransferOptions.OwnerIS,
					NotificationParameters.NotificationToPerformTransfer,,,
					False);
			EndIf;
		EndIf;
	ElsIf Result.Value = "ShowFiles" Then
		IntegrationWith1CDocumentManagementCoreClient.OpenBSPFileListForm(
			NotificationParameters.FileTransferOptions.OwnerIS);
	EndIf;
	
EndProcedure

// Changes file roles.
//
// Parameters:
//   ListOfFiles - Array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//                - FormDataCollection:
//     * Description - String
//     * ID - String
//     * Type - String
//   SelectedRoleID - String - ID of the new file role.
//   FilesOwner - String - ID of the file owner.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure ReplaceRoleOfFiles(ListOfFiles, SelectedRoleID, FilesOwner,
		FormUniqueID = Undefined) Export
	
	If TypeOf(ListOfFiles) = Type("FormDataCollection") Then
		FilesData = New Array;
		For Each String In ListOfFiles Do
			File = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
				String.Description,
				String.ID,
				String.Type);
			FilesData.Add(File);
		EndDo;
	Else
		FilesData = ListOfFiles;
	EndIf;
	
	IntegrationWith1CDocumentManagement3ServerCall.ReplaceRoleOfFiles(FilesData, SelectedRoleID);
	
	For Each File In FilesData Do
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.ChangingFileRole = True;
		FileOperation.InformFormOfFile = True;
		MessageText = StrTemplate(NStr("vi = 'Đã thay đổi vai trò tệp ""%1""';
										|ru = 'Изменена роль файла ""%1""';
										|en = 'The ""%1"" file role is changed'; fa = 'The ""%1"" file role is changed';
										|it = 'Изменена роль файла ""%1""';
										|pl = 'The ""%1"" file role is changed';
										|tr = '""%1"" dosya rolü değiştirildi'"), File.Description);
		IntegrationWith1CDocumentManagementCoreClient.InformAboutFileChanges(
			FileOperation,
			File.Description,
			File.ID,
			FilesOwner,
			MessageText ,,
			FormUniqueID);
	EndDo;
	If TypeOf(File) = Type("Structure") Then
		// We will inform the forms containing the list of files separately once.
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.ChangingFileRole = True;
		FileOperation.InformFileListForm = True;
		IntegrationWith1CDocumentManagementCoreClient.InformAboutFileChanges(
			FileOperation,
			File.Description,
			File.ID,
			FilesOwner,,,
			FormUniqueID);
	EndIf;
	
EndProcedure

// Returns data of dragged files in the file tree.
//
// Parameters:
//   FilesTree - FormDataTree - file tree.
//   DragValue - File - a file that is being dragged from yandex.disk.
//                          - FileRef - a file that is being dragged from yandex.disk.
//                          - Array of File - list of files that are being dragged from yandex.disk.
//                          - Array of FileRef - list of files that are being dragged from yandex.disk.
//                          - Array of Number - list of IDs of dragged lines in the file tree.
//
// Returns:
//   Array of File
//   An array of See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
Function ArrayOfFilesFromDragAndDropOptions(FilesTree, DragValue) Export
	
	FilesArray = New Array;
	
	If TypeOf(DragValue) = Type("File") And DragValue.IsFile() Then
		
		FilesArray.Add(DragValue);
		
	ElsIf TypeOf(DragValue) = Type("FileRef") And DragValue.File.IsFile() Then
		
		FilesArray.Add(DragValue.File);
		
	ElsIf TypeOf(DragValue) = Type("Array") Then
		
		For Each FileToDrag In DragValue Do
			If TypeOf(FileToDrag) = Type("File") And FileToDrag.IsFile() Then
				FilesArray.Add(FileToDrag);
			ElsIf TypeOf(FileToDrag) = Type("FileRef") And FileToDrag.File.IsFile() Then
				FilesArray.Add(FileToDrag.File);
			ElsIf TypeOf(FileToDrag) = Type("Number") Then
				TreeFile = FilesTree.FindByID(FileToDrag);
				If TreeFile <> Undefined And TreeFile.Type <> "DMFileRole" Then
					FileData = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
						TreeFile.Description,
						TreeFile.ID,
						TreeFile.Type,
						TreeFile.Extension,
						TreeFile.FileRoleID);
					FilesArray.Add(FileData);
				EndIf;
			EndIf;
		EndDo;
		
	ElsIf TypeOf(DragValue) = Type("Number") Then
		
		TreeFile = FilesTree.FindByID(DragValue);
		If TreeFile <> Undefined And TreeFile.Type <> "DMFileRole" Then
			FileData = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
				TreeFile.Description,
				TreeFile.ID,
				TreeFile.Type,
				TreeFile.Extension,
				TreeFile.FileRoleID);
			FilesArray.Add(FileData);
		EndIf;
		
	EndIf;
	
	Return FilesArray;
	
EndFunction

// Determines whether the object can be saved to disk.
//
// Parameters:
//   ObjectTypeDM - String - the object type is UP TO.
//
// Returns:
//   Boolean
//
Function ObjectCanBeSavedToDisk(ObjectTypeDM) Export
	
	Return (ObjectTypeDM = "DMFile")
		Or (ObjectTypeDM = "DMIncomingElectronicDocument")
		Or (ObjectTypeDM = "DMOutgoingElectronicDocument");
	
EndFunction

// Copies the attached object files stored on the IP side to the linked object on the DO side.
//
// Parameters:
//   AttachedVISFiles - ValueList of AnyRef - list of attached files in the IP.
//   OwnerID - String - ID of the file owner in the Document Flow.
//   OwnerType - String - the XDTO type of the file owner in the Document Flow.
//   OwnerIS - AnyRef - the reference to the object is the owner of the file in the IP.
//   FileRoleID - String - the role of the file.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure TransferFilesAndSvTO(AttachedVISFiles, OwnerID, OwnerType, OwnerIS,
		FileRoleID = Undefined, FormUniqueID = Undefined) Export
	
	CreatedFiles = IntegrationWith1CDocumentManagement3ServerCall.TransferFilesAndSvTO(
		AttachedVISFiles,
		OwnerID,
		OwnerType,
		OwnerIS,
		FileRoleID);
	
	For Each File In CreatedFiles Do
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.CreatingFile = True;
		FileOperation.InformFormOfFile = True;
		MessageText = StrTemplate(NStr("vi = 'Đã tạo tệp ""%1""';
										|ru = 'Создан файл ""%1""';
										|en = 'The ""%1"" file is created'; fa = 'The ""%1"" file is created';
										|it = 'Создан файл ""%1""';
										|pl = 'The ""%1"" file is created';
										|tr = '""%1"" dosyası oluşturuldu'"), File.Description);
		IntegrationWith1CDocumentManagementCoreClient.InformAboutFileChanges(
			FileOperation,
			File.Description,
			File.ID,
			OwnerID,
			MessageText,,
			FormUniqueID);
	EndDo;
	If TypeOf(File) = Type("Structure") Then
		// We will inform the forms containing the list of files separately once.
		FileOperation = IntegrationWith1CDocumentManagementCoreClientServer.FileOperation();
		FileOperation.CreatingFile = True;
		FileOperation.InformFileListForm = True;
		IntegrationWith1CDocumentManagementCoreClient.InformAboutFileChanges(
			FileOperation,
			File.Description,
			File.ID,
			OwnerID,,,
			FormUniqueID);
	EndIf;
	
EndProcedure

// Searches for a line in the file tree by file ID.
//
// Parameters:
//   FilesTree - FormDataTree - file tree.
//   UseFileRoles - Boolean - indicates whether file roles are used.
//   IdYouAreLookingFor - String - ID to use to find the row.
//   SearchableType - String - the type to use to find the string.
//
// Returns:
//   FormDataTreeItem - file tree string.
//
Function FileTreeStringByID(FilesTree, UseFileRoles, IdYouAreLookingFor,
		SearchableType = Undefined) Export
	
	For Each String In FilesTree.GetItems() Do
		
		If String.ID = IdYouAreLookingFor And String.Type = SearchableType Then
			Return String;
			
		ElsIf String.ID = IdYouAreLookingFor And SearchableType = Undefined Then
			Return String;
			
		EndIf;
		
		If UseFileRoles Then
			For Each FileRow In String.GetItems() Do
				If FileRow.ID = IdYouAreLookingFor And FileRow.Type = SearchableType Then
					Return FileRow;
					
				ElsIf FileRow.ID = IdYouAreLookingFor And SearchableType = Undefined Then
					Return FileRow;
					
				EndIf;
			EndDo;
		EndIf;
		
	EndDo;
	
EndFunction

// returns the id of the Cur role of the files.
//
// Parameters:
//   FilesTree - FormDataTree - file tree.
//   CurrentRow - Number - id of the Cur row.
//
// Returns:
//   String - the Cur role of the files.
//   Undefined - no role found.
//
Function CurCurrentFileRole(FilesTree, CurrentRow) Export
	
	If CurrentRow <> Undefined Then
		CurrentData = FilesTree.FindByID(CurrentRow);
		If CurrentData <> Undefined Then
			If CurrentData.Type = "DMFileRole" And ValueIsFilled(CurrentData.ID) Then
				// The pointer is on a specific role.
				Return CurrentData.ID;
			ElsIf ValueIsFilled(CurrentData.FileRoleID) Then
				// The pointer is on the file with the specified role.
				Return CurrentData.FileRoleID;
			EndIf;
		EndIf;
	EndIf;
	
	// the Cur line is not set or the pointer is on an empty role.
	// We will return the first required role.
	For Each String In FilesTree.GetItems() Do
		If String.RoleIsMandatory And String.Type = "DMFileRole" And ValueIsFilled(String.ID) Then
			Return String.ID;
		EndIf;
	EndDo;
	// We will return the first any role.
	For Each String In FilesTree.GetItems() Do
		If String.Type = "DMFileRole" And ValueIsFilled(String.ID) Then
			Return String.ID;
		EndIf;
	EndDo;
	
	// Nothing was found.
	Return Undefined;
	
EndFunction

#EndRegion

#Region DigitalSignatures

// Opens the item instance view Form or file.
//
// Parameters:
//   SignatureTreeCurrentData - FormDataTreeItem - the current row of the signature tree.
//   FilesTree - FormDataTree - file tree.
//   UseFileRoles - Boolean - indicates whether file roles are used.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure OpenSignature(SignatureTreeCurrentData, FilesTree, UseFileRoles,
		FormUniqueID) Export
	
	If SignatureTreeCurrentData = Undefined Then
		Return;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreClient.ThisIsSignature(SignatureTreeCurrentData) Then
		
		IntegrationWith1CDocumentManagementCoreClient.OpenSignature(SignatureTreeCurrentData);
		
	ElsIf SignatureTreeCurrentData.ObjectType = "DMFile" Then
		
		FilesTreeRow = FileTreeStringByID(
			FilesTree,
			UseFileRoles,
			SignatureTreeCurrentData.ObjectID,
			SignatureTreeCurrentData.ObjectType);
		If FilesTreeRow <> Undefined Then
			IntegrationWith1CDocumentManagementCoreClient.OpenFile(
				FilesTreeRow.ID,
				FilesTreeRow.Description,
				FilesTreeRow.Extension,
				FormUniqueID);
		EndIf;
		
	EndIf;
	
EndProcedure

// Deletes selected electronic signatures.
//
// Parameters:
//   SignatureTreeSelectedLines - Array of Number - array of indexes of selected signature lines.
//   SignatureTree - FormDataTree - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//   FileOwner - String - ID of the common owner of all files included in the signature table.
//   CallbackDescription - CallbackDescription - optional, a handler that is called after deleting signatures.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure DeleteSignature(SignatureTreeSelectedLines, SignatureTree, FileOwner,
		CallbackDescription = Undefined, FormUniqueID = Undefined) Export
	
	SelectedSignatures = IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures(
		SignatureTreeSelectedLines,
		SignatureTree);
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(SignatureTree);
	
	IntegrationWith1CDocumentManagementCoreClient.DeleteSignatures(
		SelectedSignatures,
		SignatureTable,
		FileOwner,
		CallbackDescription,
		FormUniqueID);
	
EndProcedure

#EndRegion

#Region Tasks

// Returns task data filled in from the task form or task list form.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the task or task list.
//   ID - String - ID of the workflow task.
//   Type - String - XDTO is a type of Workflow task.
//   Title - String - task title.
//   OperationParametersList - Structure:
//     * ResultOfOptionNumber - String - The name of the form Attribute containing the user-selected option
//         for completing the task action.
//     * Flag - String - flag name, takes the values of the DMObjectFlag enumeration (http://www.1c.ru/dm ).
//
// Returns:
//   See IntegrationWith1CDocumentManagement3ClientServer.DataByTask
//
Function DataByTask(Form, ID, Type, Title, OperationParametersList = Undefined) Export
	
	ResultOfOptionNumber = "";
	Flag = "";
	If OperationParametersList <> Undefined Then
		OperationParametersList.Property("ResultOfOptionNumber", ResultOfOptionNumber);
		OperationParametersList.Property("Flag", Flag);
	EndIf;
	
	DataByTask = IntegrationWith1CDocumentManagement3ClientServer.DataByTask(ID, Type, Title);
	
	If ValueIsFilled(ResultOfOptionNumber) Then
		DataByTask.ActionResult.ID = Form[ResultOfOptionNumber + "ID"];
		DataByTask.ActionResult.Type = Form[ResultOfOptionNumber + "Type"];
		DataByTask.ActionResult.Description = Form[ResultOfOptionNumber];
		DataByTask.ResultOfActionInText = Form.ResultOfActionInText;
		DataByTask.DataVersionOfTaskAction = Form.DataVersionOfTaskAction;
		Form.Items.ResultOfActionInText.ReadOnly = True;
	EndIf;
	
	DataByTask.Flag = Flag;
	
	Return DataByTask;
	
EndFunction

// Called before starting interactive changes to the application tree line.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   Cancel - Boolean - indicates that you don't want to edit the line.
//
Procedure ApplicationTreeTasksBeforeStartOfChange(ApplicationTreeLine, Cancel) Export
	
	Cancel = True;
	OpenTaskApplicationCard(ApplicationTreeLine);
	
EndProcedure

// Returns data from the main task application.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - The current row of the task's application tree.
//   ApplicationTree - FormDataTree - the task application tree.
//
// Returns:
//   FormDataTreeItem
//
Function MainSubjectInApplicationTree(ApplicationTreeLine, ApplicationTree) Export
	
	If ApplicationTreeLine <> Undefined And Lower(ApplicationTreeLine.RowType) = "application" Then
		Return ApplicationTreeLine;
	EndIf;
	
	For Each Item In ApplicationTree.GetItems() Do
		If Lower(Item.RowType) = "application" Then
			Return Item;
		EndIf;
	EndDo;
	
EndFunction

// Opens the app card.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//
Procedure OpenTaskApplicationCard(ApplicationTreeLine) Export
	
	If ApplicationTreeLine = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(ApplicationTreeLine.Ref) Then
		ShowValue(, ApplicationTreeLine.Ref);
		
	ElsIf ValueIsFilled(ApplicationTreeLine.URL)
			And (IntegrationWith1CDocumentManagement3ClientCached.IsDocumentBefore3(ApplicationTreeLine.ApplicationType)
				Or ApplicationTreeLine.ApplicationType = "DMCorrespondent"
				Or ApplicationTreeLine.ApplicationType = "DMMeeting") Then
		OpenDMObject(ApplicationTreeLine.URL);
		
	Else
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			ApplicationTreeLine.ApplicationType,
			ApplicationTreeLine.ApplicationID,
			ThisObject);
		
	EndIf;
	
EndProcedure

// Opens the app for viewing.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure OpenTasksToViewApp(ApplicationTreeLine, FormUniqueID) Export
	
	If ApplicationTreeLine = Undefined Then
		Return;
	EndIf;
	
	ObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		ApplicationTreeLine.ApplicationID,
		ApplicationTreeLine.ApplicationType,
		ApplicationTreeLine.Application,,
		ApplicationTreeLine.URL);
	OpenPlaceForViewing(
		ApplicationTreeLine.Ref,
		ObjectBefore,
		ApplicationTreeLine.Extension,
		FormUniqueID);
	
EndProcedure

// Opens the "Workflow" Form.
//
// Parameters:
//   HomePage - String - The name of the Workflow Form page to open.
//   ApplicationTree - FormDataTree - application tree.
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure OpenWorkflowFormFromApplicationTree(HomePage, ApplicationTree, ApplicationTreeLine,
		FormUniqueID) Export
	
	LineIsMainSubject = MainSubjectInApplicationTree(ApplicationTreeLine, ApplicationTree);
	If LineIsMainSubject <> Undefined Then
		If ValueIsFilled(LineIsMainSubject.Ref) Then
			FormParameters = New Structure;
			FormParameters.Insert("ExternalObject", LineIsMainSubject.Ref);
			FormParameters.Insert("HomePage", HomePage);
			OpenForm(
				"DataProcessor.IntegrationWith1CDocumentManagement3.Form.DocumentManagement",
				FormParameters,
				ThisObject,
				LineIsMainSubject.ApplicationID,,,,
				FormWindowOpeningMode.LockOwnerWindow);
		Else
			OpenTasksToViewApp(LineIsMainSubject, FormUniqueID);
		EndIf;
	EndIf;
	
EndProcedure

// Commands with this handler are created programmatically according to the subjects of the active task.
//
// Parameters:
//   Command - FormCommand - the creation command is based on.
//   MainSubjectID - String - ID of the main task object.
//   MainSubjectType - String - the type of the main task object.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure Attachable_CreateLinkedObject(Command, MainSubjectID, MainSubjectType,
		FormUniqueID) Export
	
	CommandName = Command.Name;
	GUID = Right(CommandName, 36);
	GUID = StrReplace(GUID, "_", "-");
	
	PartsOfCommand = StrSplit(CommandName, "_");
	
	If PartsOfCommand[0] = "Create" Then
		
		// Create a new IP object according to the integration rule.
		UIDRules = New UUID(GUID);
		
		FillingData =
			IntegrationWith1CDocumentManagementCoreServerCall.DataForFillingInIntegratedObject(
				UIDRules,
				MainSubjectType,
				MainSubjectID);
		
		IntegrationWith1CDocumentManagementCoreClient.CreateIntegratedObjectFromFillingData(
			FillingData);
		
	Else
		
		// We will reflect the EDI document in the accounting.
		SubsystemNameEDIDocumentInterface = "ElectronicInteraction.ExchangeWithCounterparties.InterfaceForEDIDocuments";
		ThereIsInterfaceForEDODocuments = CommonClient.SubsystemExists(SubsystemNameEDIDocumentInterface);
		If ThereIsInterfaceForEDODocuments Then
			
			Extension = "";
			FileAddress = IntegrationWith1CDocumentManagement3ServerCall.GetDocumentFileAndPutItInRepository(
				GUID,
				PartsOfCommand[0],
				FormUniqueID,
				Extension);
			
			If ThisIsFormalizedEDODocument(Extension) Then
				SelectionDone = True;
				AdditionalParameters = New Structure("DocumentReference, UUID",
					Undefined, FormUniqueID);
				ModuleNameEDIInterface = "InterfaceForEDIDocumentsClient";
				ModuleDocumentInterfaceEDIClient = CommonClient.CommonModule(ModuleNameEDIInterface);
				ModuleDocumentInterfaceEDIClient.LoadDataFromFileProcessResultOfPlacingFile(
					SelectionDone,
					FileAddress,
					"data.xml",
					AdditionalParameters);
			Else
				ShowMessageBox(,NStr("vi = 'Chỉ có thể ghi nhận vào hệ thống đối với văn bản được chuẩn hóa';
									|ru = 'Отразить в учете можно только формализованный документ ЭДО';
									|en = 'You can record only formalized EDI document in accounting'; fa = 'You can record only formalized EDI document in accounting';
									|it = 'You can record only formalized EDI document in accounting';
									|pl = 'You can record only formalized EDI document in accounting';
									|tr = 'Muhasebede sadece resmi bir EDI belgesinin kaydı oluşturulabilir'"));
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Adds an image from the buffer to the application.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   FormUniqueID - UUID - ID of the calling form.
//
Async Procedure ApplicationsTasksFilesInsertPictureFromBuffer(Val ApplicationTreeLine,
		Val FormUniqueID) Export
	
	If ApplicationTreeLine = Undefined Then
		Return;
	EndIf;
	
	If ApplicationTreeLine.RoleOfSubject = "filledin"
			And Not ValueIsFilled(ApplicationTreeLine.ApplicationType)
			And ValueIsFilled(ApplicationTreeLine.ApplicationPresentation) Then
		
		ShowMessageBox(,NStr("vi = 'Chỉ có thể thêm tệp đính kèm nhiệm vụ trong 1C:Document management.';
							|ru = 'Добавить приложение задачи можно только на стороне 1С:Документооборот.';
							|en = 'You can add task applications only in 1C:Document Management.'; fa = 'You can add task applications only in 1C:Document Management.';
							|it = 'Добавить приложение задачи можно только на стороне 1С:Документооборот.';
							|pl = 'You can add task applications only in 1C:Document Management.';
							|tr = 'Görev uygulamasını yalnızca 1C:Document Management tarafında eklenebilir.'"));
		Return;
		
	Else
		
		StateAllowsFileAddition = True;
		StateAllowsAddingScannedCopy = True;
		DocumentLine = IntegrationWith1CDocumentManagement3ClientServer.DocumentLineInApplicationTree(
			ApplicationTreeLine);
		If DocumentLine <> Undefined Then
			StateAllowsFileAddition = DocumentLine.StateAllowsFileAddition;
			StateAllowsAddingScannedCopy = DocumentLine.StateAllowsAddingScannedCopy;
		EndIf;
		
		YouNeedToAddScannedCopy =
			Await IntegrationWith1CDocumentManagementCoreClient.YouNeedToAddScannedCopyAsync(
				StateAllowsAddingScannedCopy,
				StateAllowsFileAddition);
		
		If YouNeedToAddScannedCopy = DialogReturnCode.Yes Then
			OnlyScannedCopyIsAllowed = StateAllowsAddingScannedCopy And Not StateAllowsFileAddition;
			IntegrationWith1CDocumentManagementCoreClient.CreateFileFromBuffer(
				FileCreationStartParameters(ApplicationTreeLine, FormUniqueID, OnlyScannedCopyIsAllowed));
		EndIf;
		
	EndIf;
	
EndProcedure

// Adds a file from yandex.disk to the application.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   FormUniqueID - UUID - ID of the calling form.
//
Async Procedure ApplicationsTasksFilesAdd(Val ApplicationTreeLine, Val FormUniqueID) Export
	
	If ApplicationTreeLine = Undefined Then
		Return;
	EndIf;
	
	If ApplicationTreeLine.RoleOfSubject = "filledin"
			And Not ValueIsFilled(ApplicationTreeLine.ApplicationType)
			And ValueIsFilled(ApplicationTreeLine.ApplicationPresentation) Then
		
		ShowMessageBox(,NStr("vi = 'Chỉ có thể thêm tệp đính kèm nhiệm vụ trong 1C:Document management.';
							|ru = 'Добавить приложение задачи можно только на стороне 1С:Документооборот.';
							|en = 'You can add task applications only in 1C:Document Management.'; fa = 'You can add task applications only in 1C:Document Management.';
							|it = 'Добавить приложение задачи можно только на стороне 1С:Документооборот.';
							|pl = 'You can add task applications only in 1C:Document Management.';
							|tr = 'Görev uygulamasını yalnızca 1C:Document Management tarafında eklenebilir.'"));
		Return;
		
	Else
		
		StateAllowsFileAddition = True;
		StateAllowsAddingScannedCopy = True;
		DocumentLine = IntegrationWith1CDocumentManagement3ClientServer.DocumentLineInApplicationTree(
			ApplicationTreeLine);
		If DocumentLine <> Undefined Then
			StateAllowsFileAddition = DocumentLine.StateAllowsFileAddition;
			StateAllowsAddingScannedCopy = DocumentLine.StateAllowsAddingScannedCopy;
		EndIf;
		
		YouNeedToAddScannedCopy =
			Await IntegrationWith1CDocumentManagementCoreClient.YouNeedToAddScannedCopyAsync(
				StateAllowsAddingScannedCopy,
				StateAllowsFileAddition);
		
		If YouNeedToAddScannedCopy = DialogReturnCode.Yes Then
			OnlyScannedCopyIsAllowed = StateAllowsAddingScannedCopy And Not StateAllowsFileAddition;
			IntegrationWith1CDocumentManagementCoreClient.CreateFileFromDisk(
				FileCreationStartParameters(ApplicationTreeLine, FormUniqueID, OnlyScannedCopyIsAllowed));
		EndIf;
		
	EndIf;
	
EndProcedure

// Finishes editing the file by putting it in BEFORE and removing the capture if necessary.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure ApplicationsTasksFilesFinishEditing(ApplicationTreeLine, FormUniqueID) Export
	
	If ApplicationTreeLine = Undefined Then
		Return;
	EndIf;
	
	If ApplicationTreeLine.ApplicationType = "DMFile" Then
		
		FileRoleAndApplication = FileRoleAndApplication(ApplicationTreeLine);
		
		IntegrationWith1CDocumentManagementCoreClient.EndFileEditing(
			ApplicationTreeLine.ApplicationID,
			ApplicationTreeLine.Application,
			ApplicationTreeLine.Extension,
			FormUniqueID,,
			FileRoleAndApplication.Application.ID);
		
	Else
		
		ShowMessageBox(,NStr("vi = 'Hãy chọn tệp.';
							|ru = 'Выберите файл.';
							|en = 'Select a file.'; fa = 'Select a file.';
							|it = 'Выберите файл.';
							|pl = 'Select a file.';
							|tr = 'Dosya ekle.'"));
		
	EndIf;
	
EndProcedure

// Updates the file TO from a file on disk.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure ApplicationsTasksFilesToUpdateFromFileOnDisk(ApplicationTreeLine, FormUniqueID) Export
	
	If ApplicationTreeLine = Undefined Then
		Return;
	EndIf;
	
	If ApplicationTreeLine.ApplicationType = "DMFile" Then
		
		FileRoleAndApplication = FileRoleAndApplication(ApplicationTreeLine);
		
		IntegrationWith1CDocumentManagementCoreClient.UpdateFromFileOnHardDrive(
			ApplicationTreeLine.ApplicationID,
			ApplicationTreeLine.Application,
			ApplicationTreeLine.Extension,
			ApplicationTreeLine.ModificationDate,
			FormUniqueID,,
			FileRoleAndApplication.Application.ID);
		
	Else
		
		ShowMessageBox(,NStr("vi = 'Hãy chọn tệp.';
							|ru = 'Выберите файл.';
							|en = 'Select a file.'; fa = 'Select a file.';
							|it = 'Выберите файл.';
							|pl = 'Select a file.';
							|tr = 'Dosya ekle.'"));
		
	EndIf;
	
EndProcedure

// Cancels editing of a previously captured file.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure ApplicationsTasksFilesToRelease(ApplicationTreeLine, FormUniqueID) Export
	
	If ApplicationTreeLine = Undefined Then
		Return;
	EndIf;
	
	If ApplicationTreeLine.ApplicationType = "DMFile" Then
		
		FileRoleAndApplication = FileRoleAndApplication(ApplicationTreeLine);
		
		IntegrationWith1CDocumentManagementCoreClient.UndoFileEditing(
			ApplicationTreeLine.ApplicationID,,
			FileRoleAndApplication.Application.ID,
			FormUniqueID);
		
	Else
		
		ShowMessageBox(,NStr("vi = 'Hãy chọn tệp.';
							|ru = 'Выберите файл.';
							|en = 'Select a file.'; fa = 'Select a file.';
							|it = 'Выберите файл.';
							|pl = 'Select a file.';
							|tr = 'Dosya ekle.'"));
		
	EndIf;
	
EndProcedure

// Opens the file for editing.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure ApplicationsTasksFilesEdit(ApplicationTreeLine, FormUniqueID) Export
	
	If ApplicationTreeLine = Undefined Then
		Return;
	EndIf;
	
	If ApplicationTreeLine.ApplicationType = "DMFile" Then
		
		FileRoleAndApplication = FileRoleAndApplication(ApplicationTreeLine);
		
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			ApplicationTreeLine.ApplicationID,
			ApplicationTreeLine.Application,
			ApplicationTreeLine.Extension,
			FormUniqueID,
			False,,
			FileRoleAndApplication.Application.ID);
		
	Else
		
		ShowMessageBox(,NStr("vi = 'Hãy chọn tệp.';
							|ru = 'Выберите файл.';
							|en = 'Select a file.'; fa = 'Select a file.';
							|it = 'Выберите файл.';
							|pl = 'Select a file.';
							|tr = 'Dosya ekle.'"));
		
	EndIf;
	
EndProcedure

// Saves files from the application tree to disk, to the directory specified by the user.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   Form - ClientApplicationForm - the form of the task or task list.
//
Procedure ApplicationsTasksFilesSaveAs(ApplicationTreeLine, Form) Export
	
	If ApplicationTreeLine = Undefined Then
		Return;
	EndIf;
	
	Selected_Files = New Array;
	
	If Form.Items.ApplicationTree.SelectedRows.Count() > 1 Then
		For Each RowSelected In Form.Items.ApplicationTree.SelectedRows Do
			RowData = Form.Items.ApplicationTree.RowData(RowSelected);
			If ObjectCanBeSavedToDisk(RowData.ApplicationType) Then
				Selected_Files.Add(FileDataToSave(RowData, Form));
			EndIf;
		EndDo;
	Else
		If ObjectCanBeSavedToDisk(ApplicationTreeLine.ApplicationType) Then
			Selected_Files.Add(FileDataToSave(ApplicationTreeLine, Form));
		EndIf;
	EndIf;
	
	If Selected_Files.Count() = 0 Then
		ShowMessageBox(,NStr("vi = 'Hãy chọn tệp.';
							|ru = 'Выберите файл.';
							|en = 'Select a file.'; fa = 'Select a file.';
							|it = 'Выберите файл.';
							|pl = 'Select a file.';
							|tr = 'Dosya ekle.'"));
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
	Parameters.Insert("FormUniqueID", Form.UUID);
	Parameters.Insert("CallbackDescription", Undefined);
	
	IntegrationWith1CDocumentManagementCoreClient.SaveFilesAsStart(Parameters);
	
EndProcedure

// Deletes the app.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure ApplicationsTasksFilesToDelete(ApplicationTreeLine, FormUniqueID) Export
	
	If ApplicationTreeLine = Undefined Then
		Return;
	EndIf;
	
	If ApplicationTreeLine.RoleOfSubject = "filledin"
			And ValueIsFilled(ApplicationTreeLine.ApplicationType)
			And ValueIsFilled(ApplicationTreeLine.ApplicationPresentation) Then
		
		ShowMessageBox(,NStr("vi = 'Chỉ có thể xóa tệp đính kèm nhiệm vụ trong 1C:Document management.';
							|ru = 'Удалить приложение задачи можно только на стороне 1С:Документооборот.';
							|en = 'You can delete task applications only in 1C:Document Management.'; fa = 'You can delete task applications only in 1C:Document Management.';
							|it = 'Удалить приложение задачи можно только на стороне 1С:Документооборот.';
							|pl = 'You can delete task applications only in 1C:Document Management.';
							|tr = 'Görev uygulaması yalnızca 1C:Document Management tarafında silinebilir.'"));
		Return;
		
	ElsIf ApplicationTreeLine.ApplicationType = "DMFile" Then
		
		FileRoleAndApplication = FileRoleAndApplication(ApplicationTreeLine);
		CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
			ApplicationTreeLine.Application,
			ApplicationTreeLine.ApplicationID,
			ApplicationTreeLine.ApplicationType,
			ApplicationTreeLine.Extension,
			ApplicationTreeLine.FileRoleID);
		IntegrationWith1CDocumentManagementCoreClient.MarkForDeletionUncheckFiles(
			CommonClientServer.ValueInArray(CurrentFile),
			ApplicationTreeLine.DeletionMark,,
			FileRoleAndApplication.Application.ID,
			FormUniqueID);
		
	EndIf;
	
EndProcedure

// Sets the visibility and availability of commands in the application tree.
//
// Parameters:
//   CurrentRow - Number - the Cur line number of the application tree.
//   Form - ClientApplicationForm - the form of the task or task list.
//   ThisIsThinWindowsClient - Boolean - required to set the availability of the paste command from the clipboard.
//
Procedure SetAvailabilityOfCommandsOfTaskApplications(CurrentRow, Form, ThisIsThinWindowsClient) Export
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	IsFile = False;
	IsTask = False;
	ThisIsFillableApplication = False;
	ThisIsDifferentApplication = False;
	ThisIsRoleOfFile = False;
	ThisIsApplicationFile = False;
	
	InteractiveFileModificationIsAvailable = False;
	
	EditAvailability = True;
	FinishEditingAccessibility = True;
	ApplicationToBeFilledInIsSpecified = False;
	
	StateAllowsFileAddition = True;
	StateAllowsAddingScannedCopy = True;
	StateAllowsFileEditing = True;
	StateAllowsFileDeletion = True;
	
	CurrentData = Form.ApplicationTree.FindByID(CurrentRow);
	If CurrentData <> Undefined Then
		
		DocumentLine = IntegrationWith1CDocumentManagement3ClientServer.DocumentLineInApplicationTree(CurrentData);
		If DocumentLine <> Undefined Then
			StateAllowsFileAddition = DocumentLine.StateAllowsFileAddition;
			StateAllowsAddingScannedCopy = DocumentLine.StateAllowsAddingScannedCopy;
			StateAllowsFileEditing = DocumentLine.StateAllowsFileEditing;
			StateAllowsFileDeletion = DocumentLine.StateAllowsFileDeletion;
		EndIf;
		
		If CurrentData.ApplicationType = "DMFile" Then
			
			EditedByAnotherUser =
				CurrentData.IsBeingEdited
				And Not CurrentData.EditedByCurUser;
			If Not StateAllowsFileEditing
					Or EditedByAnotherUser
					Or CurrentData.SignedWithDS
					Or CurrentData.Encrypted Then
				EditAvailability = False;
			EndIf;
			
			If Not StateAllowsFileEditing
					Or Not CurrentData.EditedByCurUser
					Or CurrentData.SignedWithDS
					Or CurrentData.Encrypted Then
				FinishEditingAccessibility = False;
			EndIf;
			
		Else
			
			EditAvailability = False;
			FinishEditingAccessibility = False;
			
		EndIf;
		
		IsFile = (CurrentData.ApplicationType = "DMFile");
		ThisIsDifferentApplication = ValueIsFilled(CurrentData.ApplicationType)
			And (CurrentData.ApplicationType <> "DMFile")
			And (CurrentData.ApplicationType <> "DMTaskAction");
		IsTask = (CurrentData.RowType = "task");
		ThisIsFillableApplication = (CurrentData.RoleOfSubject = "filledin");
		ThisIsRoleOfFile = (CurrentData.RowType = "filerole");
		ThisIsApplicationFile = (CurrentData.RowType = "file");
		
		ApplicationToBeFilledInIsSpecified = (CurrentData.RoleOfSubject = "filledin")
			And ValueIsFilled(CurrentData.ApplicationType);
		
		If CurrentData.RowType = "file" Then
			
			ParentData = CurrentData.GetParent();
			If ParentData <> Undefined And ParentData.RowType = "filerole" Then
				ParentData = ParentData.GetParent();
			EndIf;
			
			InteractiveFileModificationIsAvailable = ParentData <> Undefined
				And ValueIsFilled(ParentData.ApplicationType)
				And InteractiveFileModificationIsAvailable(ParentData.ApplicationType);
			
		ElsIf CurrentData.RowType = "filerole" Then
			
			ParentData = CurrentData.GetParent();
			InteractiveFileModificationIsAvailable = ValueIsFilled(ParentData.Application)
				And InteractiveFileModificationIsAvailable(ParentData.ApplicationType);
			
		ElsIf CurrentData.RowType = "application" Then
			
			InteractiveFileModificationIsAvailable = ValueIsFilled(CurrentData.Application)
				And InteractiveFileModificationIsAvailable(CurrentData.ApplicationType);
			
		EndIf;
		
	EndIf;
	
	// Visibility.
	Form.Items.ApplicationTreeContextMenuFilesAdd.Visible =
		ThisIsFillableApplication
		Or (ThisIsDifferentApplication And InteractiveFileModificationIsAvailable)
		Or (ThisIsRoleOfFile And InteractiveFileModificationIsAvailable)
		Or (ThisIsApplicationFile And InteractiveFileModificationIsAvailable);
	Form.Items.ApplicationTreeContextMenuFilesInsertImageFromBuffer.Visible =
		ThisIsThinWindowsClient
		And ((ThisIsDifferentApplication And InteractiveFileModificationIsAvailable)
			Or (ThisIsRoleOfFile And InteractiveFileModificationIsAvailable)
			Or (ThisIsApplicationFile And InteractiveFileModificationIsAvailable));
	Form.Items.ApplicationTreeContextMenuOpenCard.Visible =
		IsFile Or ThisIsDifferentApplication Or IsTask;
	Form.Items.ApplicationTreeContextMenuOpenApp.Visible = IsFile;
	Form.Items.ApplicationTreeContextMenuEdit.Visible = IsFile;
	Form.Items.ApplicationTreeContextMenuFinishEditing.Visible = IsFile;
	Form.Items.ApplicationTreeContextMenuRelease.Visible = IsFile;
	Form.Items.ApplicationTreeContextMenuUpdateFromFileOnDisk.Visible = IsFile;
	Form.Items.ApplicationTreeContextMenuFilesDelete.Visible =
		ThisIsFillableApplication
		Or (ThisIsApplicationFile And InteractiveFileModificationIsAvailable);
	Form.Items.ApplicationTreeContextMenuSaveAs.Visible =
		ObjectCanBeSavedToDisk(CurrentData.ApplicationType);
	Form.Items.ApplicationTreeContextMenuCopyToClipboard.Visible =
		IsFile Or ThisIsDifferentApplication;
	
	// Availability.
	Form.Items.ApplicationTreeContextMenuOpenCard.Enabled = IsFile;
	Form.Items.ApplicationTreeContextMenuSaveAs.Enabled =
		ObjectCanBeSavedToDisk(CurrentData.ApplicationType) And Not CurrentData.Encrypted;
	Form.Items.ApplicationTreeContextMenuOpenApp.Enabled = IsFile And Not CurrentData.Encrypted;
	Form.Items.ApplicationTreeContextMenuEdit.Enabled =
		EditAvailability;
	Form.Items.ApplicationTreeContextMenuFinishEditing.Enabled =
		FinishEditingAccessibility;
	Form.Items.ApplicationTreeContextMenuRelease.Enabled =
		FinishEditingAccessibility;
	Form.Items.ApplicationTreeContextMenuUpdateFromFileOnDisk.Enabled = EditAvailability;
	
	If ThisIsFillableApplication Then
		Form.Items.ApplicationTreeContextMenuFilesAdd.Enabled = Not ApplicationToBeFilledInIsSpecified
			And (StateAllowsFileAddition Or StateAllowsAddingScannedCopy);
		Form.Items.ApplicationTreeContextMenuFilesDelete.Enabled =
			ApplicationToBeFilledInIsSpecified;
	Else
		Form.Items.ApplicationTreeContextMenuFilesAdd.Enabled = StateAllowsFileAddition
			Or StateAllowsAddingScannedCopy;
		Form.Items.ApplicationTreeContextMenuFilesDelete.Enabled = Not CurrentData.IsBeingEdited
			And StateAllowsFileDeletion;
	EndIf;
	
	Form.Items.ApplicationTreeContextMenuFilesInsertImageFromBuffer.Enabled =
		StateAllowsFileAddition Or StateAllowsAddingScannedCopy;
	
EndProcedure

#EndRegion

#Region DataProcessor

// Starts processing the linked object BEFORE. When transferring a reference to an object as a subject, the IP
// creates a related object BEFORE, if this relationship has not been established before.
//
// Parameters:
//   SubjectOf - Array of AnyRef
//           - Structure:
//     * ID - String
//     * type - String
//     * name - String
//     * ExternalObject - AnyRef
//   CallbackDescription - CallbackDescription - description of the notification that is called at the end.
//   UsePriorityRules - Boolean - do I need to ask the user a question when creating a new IP object according to
//     the integration rules, if several different integration rules are configured for the IP object,
//     or do I need to use the rule with the highest priority for key Attributes?
//
Procedure StartProcessing(SubjectOf, CallbackDescription = Undefined, UsePriorityRules = False) Export
	
	Parameters = New Structure("SubjectOf");
	Parameters.Insert("CallbackDescription", CallbackDescription);
	Parameters.Insert("NewObjectWasCreatedBEFORE", False);
	
	If TypeOf(SubjectOf) = Type("Structure") Then
		
		Parameters.SubjectOf = SubjectOf;
		StartProcessingAfterSearchingForRelatedObjectDM(Undefined, Parameters);
		
	ElsIf TypeOf(SubjectOf) = Type("Array") Then
		
		For Each ObjectIS In SubjectOf Do
			Parameters.SubjectOf = ObjectIS;
			CallbackDescriptionContinued = New CallbackDescription(
				"StartProcessingAfterSearchingForRelatedObjectDM",
				IntegrationWith1CDocumentManagement3Client,
				Parameters);
			IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
				ObjectIS,
				CallbackDescriptionContinued,,
				UsePriorityRules);
		EndDo;
		
	EndIf;
	
EndProcedure

// Continues the creation of the business process after searching for the associated object BEFORE.
//
// Parameters:
//   Result - Undefined
//             - See IntegrationWith1CDocumentManagementCore.ObjectDataUpToExternalObject
//   Parameters - Structure:
//     * SubjectOf - AnyRef,
//               - Structure:
//         ** ID - String
//         ** type - String
//         ** name - String
//         ** ExternalObject - AnyRef
//     * CallbackDescription - CallbackDescription - description of the notification that is called at the end.
//     * NewObjectWasCreatedBEFORE - Boolean
//
Procedure StartProcessingAfterSearchingForRelatedObjectDM(Result, Parameters) Export
	
	// Let's distinguish the case when the item is not selected from the case when the item is not needed.
	If Parameters.SubjectOf <> Undefined Then
		If Result = Undefined Then
			Return;
		EndIf;
		Parameters.SubjectOf = Result;
	EndIf;
	
	ObjectNeedsToBeUpdatedTO = Not Parameters.NewObjectWasCreatedBEFORE;
	ErrorText = "";
	If IntegrationWith1CDocumentManagement3ServerCall.StartProcessing(
			Parameters.SubjectOf, ObjectNeedsToBeUpdatedTO, ErrorText) Then
		
		ShowUserNotification(
			NStr("vi = 'Bộ xử lý';
				|ru = 'Обработка';
				|en = 'Processing'; fa = 'پردازش';
				|it = 'Elaborazione';
				|pl = 'Processing';
				|tr = 'İşleme'"),,
			StrTemplate(NStr("vi = 'Đã khởi động thành công bộ xử lý ""%1""';
							|ru = 'Обработка ""%1"" успешно запущена';
							|en = 'Processing ""%1"" is started'; fa = 'Processing ""%1"" is started';
							|it = 'Elaborazione ""%1"" avviata con successo';
							|pl = 'Procesor danych ""%1"" został pomyślnie uruchomiony';
							|tr = '""%1"" işleme başarıyla başlatıldı'"), Parameters.SubjectOf.Name),
			PictureLib.Information32,
			UserNotificationStatus.Important);
		If Parameters.CallbackDescription <> Undefined Then
			RunCallback(Parameters.CallbackDescription);
		EndIf;
		
	Else
		
		ShowWarningFromBEFORE(,ErrorText,,
			StrTemplate(NStr("ru = 'Не удалось начать обработку ""%1""';
							|vi = 'Cannot start processing ""%1""';
							|en = 'Cannot start processing ""%1""'; fa = 'Cannot start processing ""%1""';
							|it = 'Cannot start processing ""%1""';
							|pl = 'Cannot start processing ""%1""';
							|tr = '""%1"" işlemi başlatılamadı'"), Parameters.SubjectOf.Name));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Actions

// Listing the types of changes of participants in actions.
//
// Returns:
//   Structure:
//     * ChangingArtist - String
//     * MovingUp - String
//     * MovingDown - String
//     * AddingStage - String
//
Function TypesOfChangesOfParticipantsInAction() Export
	
	TypesOfChanges = New Structure;
	TypesOfChanges.Insert("ChangingArtist", "ChangingArtist");
	TypesOfChanges.Insert("MovingUp", "MovingUp");
	TypesOfChanges.Insert("MovingDown", "MovingDown");
	TypesOfChanges.Insert("AddingStage", "AddingStage");
	
	Return TypesOfChanges;
	
EndFunction

// Adds a new stage of the action to the Participants table.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   StageFunction - String - the function of the participants of the stage.
//
Procedure AddActionStep(Form, StageFunction) Export
	
	Items = Form.Items;
	Attendees = Form.Attendees;
	
	CurrentData = Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Property("ThisIsChildMember") And CurrentData.ThisIsChildMember Then
		ItemParent = CurrentData.GetParent();
		If ItemParent <> Undefined Then
			CurrentData = ItemParent;
		EndIf;
	EndIf;
	
	ItemParent = CurrentData.GetParent();
	If ItemParent <> Undefined Then
		CurrentData = ItemParent;
	EndIf;
	
	StageLines_ = Attendees.GetItems();
	
	IndexOfNewElement = StageLines_.IndexOf(CurrentData);
	If CurrentData.Function = StageFunction Then
		IndexOfNewElement = IndexOfNewElement + 1;
	EndIf;
	
	StageString = StageLines_.Insert(IndexOfNewElement);
	StageString.StageName = NStr("vi = 'Giai đoạn mới';
								|ru = 'Новый этап';
								|en = 'New stage'; fa = 'New stage';
								|it = 'Новый этап';
								|pl = 'New stage';
								|tr = 'Yeni aşama'");
	StageString.ThisIsAStep = True;
	StageString.Order = CurrentData.Order;
	StageString.Function = StageFunction;
	StageString.Id = String(New UUID());
	StageString.AllowedToAdd = Form.YouCanOnlyAddMembers Or Form.YouCanAddParticipants;
	FillInAvailabilityOfMovingStagesOfParticipantsOfAction(StageLines_);
	Form.ThereAreStages = True;
	Items.Attendees.CurrentRow = StageString.GetID();
	
	NotificationParameters = NewNotificationParametersChangesInParticipants();
	NotificationParameters.CurrentData = CurrentData;
	NotificationParameters.ChangeType = TypesOfChangesOfParticipantsInAction().AddingStage;
	
	Notify("UpdatePresentationsInParticipantTree", NotificationParameters, Form.UUID);
	
EndProcedure

// Fills in the availability of moving stages and participants in the approval or signing action card.
//
// Parameters:
//   TreeRows - FormDataTree
//                - FormDataTreeItemCollection - a tree of stages or participants.
//   FillingEntireTree - Boolean - True if you fill the entire tree.
//
Procedure FillInAvailabilityOfMovingStagesOfParticipantsOfAction(TreeRows, FillingEntireTree = False) Export
	
	If FillingEntireTree And TypeOf(TreeRows) = Type("FormDataTree") Then
		
		RowsStages = TreeRows.GetItems();
		
		For Each StageString In RowsStages Do
			
			If StageString.Unavailable Then
				StageString.CanBeMovedDown = False;
				StageString.CanBeMovedUp = False;
				Continue;
			EndIf;
			
			CurrentRowIndex = RowsStages.IndexOf(StageString);
			If CurrentRowIndex = 0
					Or ValueIsFilled(StageString.State)
					Or ValueIsFilled(RowsStages[CurrentRowIndex - 1].State) Then
				StageString.CanBeMovedUp = False;
			Else
				StageString.CanBeMovedUp = True;
			EndIf;
			
			If CurrentRowIndex = RowsStages.Count() - 1
					Or ValueIsFilled(StageString.State)
					Or ValueIsFilled(RowsStages[CurrentRowIndex + 1].State)
					Or IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(
						RowsStages[CurrentRowIndex + 1].Function) Then
				StageString.CanBeMovedDown = False;
			Else
				StageString.CanBeMovedDown = True;
			EndIf;
			
			MemberLines = StageString.GetItems();
			
			For Each MemberString In MemberLines Do
				
				CurrentRowIndex = MemberLines.IndexOf(MemberString);
				
				If CurrentRowIndex = 0
						Or ValueIsFilled(MemberString.State)
						Or StageString.Order = "OneByOne"
							And ValueIsFilled(MemberLines[CurrentRowIndex - 1].State) Then
					MemberString.CanBeMovedUp = False;
				Else
					MemberString.CanBeMovedUp = True;
				EndIf;
				
				If CurrentRowIndex = MemberLines.Count() - 1
						Or ValueIsFilled(MemberString.State)
						Or StageString.Order = "OneByOne"
							And ValueIsFilled(MemberLines[CurrentRowIndex + 1].State) Then
					MemberString.CanBeMovedDown = False;
				Else
					MemberString.CanBeMovedDown = True;
				EndIf;
				
			EndDo;
			
		EndDo;
		
	Else
		
		If TreeRows.Count() > 0 Then
			If TreeRows[0].ThisIsAStep Then
				
				For IndexOf = 0 To TreeRows.Count() - 1 Do
					
					If TreeRows[IndexOf].Unavailable Then
						TreeRows[IndexOf].CanBeMovedDown = False;
						TreeRows[IndexOf].CanBeMovedUp = False;
						Continue;
					EndIf;
					
					If IndexOf = 0
							Or ValueIsFilled(TreeRows[IndexOf].State)
							Or ValueIsFilled(TreeRows[IndexOf - 1].State) Then
						TreeRows[IndexOf].CanBeMovedUp = False;
					Else
						TreeRows[IndexOf].CanBeMovedUp = True;
					EndIf;
					
					If IndexOf = TreeRows.Count() - 1
							Or ValueIsFilled(TreeRows[IndexOf].State)
							Or ValueIsFilled(TreeRows[IndexOf + 1].State)
							Or IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(
								TreeRows[IndexOf + 1].Function) Then
						TreeRows[IndexOf].CanBeMovedDown = False;
					Else
						TreeRows[IndexOf].CanBeMovedDown = True;
					EndIf;
				
				EndDo;
				
			Else
				
				Stage = TreeRows[0].GetParent();
				
				For IndexOf = 0 To TreeRows.Count() - 1 Do
					
					If IndexOf = 0
							Or ValueIsFilled(TreeRows[IndexOf].State)
							Or Stage.Order = "OneByOne"
								And ValueIsFilled(TreeRows[IndexOf - 1].State) Then
						TreeRows[IndexOf].CanBeMovedUp = False;
					Else
						TreeRows[IndexOf].CanBeMovedUp = True;
					EndIf;
					
					If IndexOf = TreeRows.Count() - 1
							Or ValueIsFilled(TreeRows[IndexOf].State)
							Or Stage.Order = "OneByOne"
								And ValueIsFilled(TreeRows[IndexOf + 1].State) Then
						TreeRows[IndexOf].CanBeMovedDown = False;
					Else
						TreeRows[IndexOf].CanBeMovedDown = True;
					EndIf;
					
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// The Command handler is protected in the forms of action settings and the actions themselves.
// Sets/removes the security mark in the form for the selected participant or stage.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure ChangeProtectedActionParticipantAttribute(Form) Export
	
	WarnWhenProtectingParticipant = IntegrationWith1CDocumentManagement3ClientCached.WarnWhenProtectingParticipant();
	ShowWarning = False;
	GeneralSecurity = Undefined;
	
	For Each RowIndex In Form.Items.Attendees.SelectedRows Do
		CurrentData = Form.Attendees.FindByID(RowIndex);
		
		If Not ChangingSecurityOfParticipantIsAvailable(CurrentData, Form.YouCanChangeProtectedParticipants) Then
			Continue;
		EndIf;
		
		CurrentData.IsProtected = Not CurrentData.IsProtected;
		
		If GeneralSecurity = Undefined Then
			GeneralSecurity = CurrentData.IsProtected;
		EndIf;
		GeneralSecurity = GeneralSecurity And CurrentData.IsProtected;
		
		ShowWarning = ShowWarning Or CurrentData.IsProtected And WarnWhenProtectingParticipant;
		
		Form.Modified = True;
	EndDo;
	
	If ShowWarning Then
		WarningText =
			NStr("vi = 'Không thể xóa tự động hoặc thủ công người tham gia thao tác được bảo mật.';
				|ru = 'Защищенного участника действий нельзя удалить ни автоматически, ни вручную.';
				|en = 'Cannot delete a protected action participant automatically or manually.'; fa = 'Cannot delete a protected action participant automatically or manually.';
				|it = 'Защищенного участника действий нельзя удалить ни автоматически, ни вручную.';
				|pl = 'Cannot delete a protected action participant automatically or manually.';
				|tr = 'Korumalı eylem katılımcısı ne otomatik ne de manuel olarak silinemez.'");
		WarningParameters = StandardSubsystemsClient.QuestionToUserParameters();
		WarningParameters.Title = NStr("vi = 'Bảo mật người tham gia khỏi việc xóa';
										|ru = 'Защита участника от удаления';
										|en = 'Protect participants from deletion'; fa = 'Protect participants from deletion';
										|it = 'Защита участника от удаления';
										|pl = 'Protect participants from deletion';
										|tr = 'Katılımcının silinmeye karşı korunması'");
		WarningParameters.Picture = PictureLib.Information32;
		IntegrationWith1CDocumentManagementCoreClientOverridable.WhenDeterminingNeedToSuggestNoLongerAskingThisQuestion(
			WarningParameters.PromptDontAskAgain,
			WarningText,
			"SettingsNoLongerShow",
			"ShowWarningWhenSettingProtectionOfParticipantOfAction");
		If WarningParameters.PromptDontAskAgain Then
			WarningParameters.CheckBoxText = NStr("vi = 'Không hiển thị nữa';
													|ru = 'Больше не показывать';
													|en = 'Do not show again'; fa = 'دوباره نمایش داده نشود';
													|it = 'Больше не показывать';
													|pl = 'Do not show again';
													|tr = 'Bir daha gösterme'");
		EndIf;
		CallbackDescription = New CallbackDescription("AfterWarningAboutSecurityOfParticipantInAction", ThisObject);
		StandardSubsystemsClient.ShowQuestionToUser(
			CallbackDescription,
			WarningText,
			QuestionDialogMode.OK,
			WarningParameters);
	EndIf;
	
	Form.Items.IsProtected.Check = ?(GeneralSecurity <> Undefined, GeneralSecurity, False);
	Form.SetFormItemEnabled();
	
EndProcedure

// Constructor of parameters of the notification about changes in the participants of the action.
//
// Returns:
//   Structure:
//     * CurrentData - Undefined - there is no changeable line.
//                     - FormDataCollectionItem - a variable string of participants.
//     * ChangeType - Undefined - the type of change has not been identified.
//                    - String - See TypesOfChangesOfParticipantsInAction
//
Function NewNotificationParametersChangesInParticipants() Export
	
	Parameters = New Structure;
	Parameters.Insert("CurrentData", Undefined);
	Parameters.Insert("ChangeType", Undefined);
	
	Return Parameters;
	
EndFunction

// Handler for clicking on the description field of the initial execution.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//
Procedure DescriptionOfDelayedStartOfClickAction(Form, StandardProcessing) Export
	
	StandardProcessing = False;
	
	If Not Form.DelayedStartOfExecutionSettingIsAvailable Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Form", Form);
	
	FormParameters = New Structure;
	FormParameters.Insert("Title", NStr("vi = 'Bắt đầu hoãn thực hiện';
										|ru = 'Отложенное начало выполнения';
										|en = 'Deferred execution start'; fa = 'شروع اجرای معوق';
										|it = 'Отложенное начало выполнения';
										|pl = 'Deferred execution start';
										|tr = 'Ertelenmiş gerçekleştirme başlangıcı'"));
	FormParameters.Insert("Days", Form.DelayedStartOfExecutionDays);
	FormParameters.Insert("Hours1", Form.DelayedStartOfExecutionHours);
	FormParameters.Insert("PostponedDate", Form.DeferredExecutionDate);
	
	CallbackDescription = New CallbackDescription(
		"DescriptionOfDelayedStartOfClickActionContinued",
		ThisObject,
		NotificationParameters);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.DeferredExecutionStartSetting",
		FormParameters,
		Form,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Continuation of the procedure DescriptionThe initial execution of the action is performed by pressing.
//
// Parameters:
//   Result - Structure:
//     * Days - Number
//     * Hours1 - Number
//     * PostponedDate - Date
//   NotificationParameters - Structure:
//     * Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure DescriptionOfDelayedStartOfClickActionContinued(Result, NotificationParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Form = NotificationParameters.Form;
	
	Form.DelayedStartOfExecutionDays = Result.Days;
	Form.DelayedStartOfExecutionHours = Result.Hours1;
	Form.DeferredExecutionDate = Result.PostponedDate;
	
	IntegrationWith1CDocumentManagement3ClientServer.ConfigureDisplayOfDelayedStartOfAction(Form);
	Form.Modified = True;
	
EndProcedure

// The handler of the Move Commands up in the form of an action.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure ClearActionDelay(Form) Export
	
	If Not Form.DelayedStartOfExecutionSettingIsAvailable Then
		Return;
	EndIf;
	
	Form.DelayedStartOfExecutionDays = 0;
	Form.DelayedStartOfExecutionHours = 0;
	Form.DeferredExecutionDate = Date(1, 1, 1);
	
	IntegrationWith1CDocumentManagement3ClientServer.ConfigureDisplayOfDelayedStartOfAction(Form);
	Form.Modified = True;
	
EndProcedure

// Constructor of the structure that describes the parameters for adding participants to an action.
//
// Returns:
//   Structure:
//     * WithStages - Boolean - the action has stages.
//     * ChildPerformersArePossible - Boolean - the action supports child executors.
//     * ByPoints - Boolean - the action is performed point by point.
//     * YouCanAddStages - Boolean - you can add action steps.
//     * YouCanOnlyAddMembers - Boolean - you can only add participants to the action.
//     * ParticipantFunction - String - the function of the participant of the action.
//
Function ParametersForAddingParticipantsToAction() Export
	
	AddingOptions = New Structure;
	AddingOptions.Insert("WithStages", False);
	AddingOptions.Insert("ChildPerformersArePossible", False);
	AddingOptions.Insert("ByPoints", False);
	AddingOptions.Insert("YouCanAddStages", False);
	AddingOptions.Insert("YouCanOnlyAddMembers", False);
	AddingOptions.Insert("ParticipantFunction", "");
	
	Return AddingOptions;
	
EndFunction

// The handler of the Move Commands up in the form of an action.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   YouCanChangeOrderOfStages - Boolean - The action allows you to change the order of the stages.
//   ByPoints - Boolean - the action is performed point by point.
//
Procedure MoveParticipantOfActionUp(Form, YouCanChangeOrderOfStages = True, ByPoints = False) Export
	
	CurrentData = Form.Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(CurrentData.Function) Then
		Return;
	EndIf;
	
	If CurrentData.ThisIsAStep Then
		
		If Not YouCanChangeOrderOfStages And Not ByPoints Then
			ShowMessageBox(,NStr("vi = 'Không thể thay đổi trình tự các giai đoạn.';
								|ru = 'Нельзя менять порядок этапов.';
								|en = 'Cannot change the stage order.'; fa = 'Cannot change the stage order.';
								|it = 'Нельзя менять порядок этапов.';
								|pl = 'Cannot change the stage order.';
								|tr = 'Aşamaların sırası değiştirilemez.'"));
			Return;
		EndIf;
		
		Stages = Form.Attendees.GetItems();
		CurrentRowIndex = Stages.IndexOf(CurrentData);
		If CurrentRowIndex = 0 Then
			Return;
		EndIf;
		Stages.Move(CurrentRowIndex, -1);
		
		If YouCanChangeOrderOfStages Then
			FillInAvailabilityOfMovingStagesOfParticipantsOfAction(Stages);
		EndIf;
		
	Else
		
		ParticipantsOfStage = CurrentData.GetParent().GetItems();
		
		CurrentRowIndex = ParticipantsOfStage.IndexOf(CurrentData);
		
		If CurrentRowIndex = 0 Then
			Return;
		EndIf;
		
		ParticipantsOfStage.Move(CurrentRowIndex, -1);
		
		If YouCanChangeOrderOfStages Then
			FillInAvailabilityOfMovingStagesOfParticipantsOfAction(ParticipantsOfStage);
		EndIf;
		
	EndIf;
	
	NotificationParameters = NewNotificationParametersChangesInParticipants();
	NotificationParameters.CurrentData = CurrentData;
	NotificationParameters.ChangeType = TypesOfChangesOfParticipantsInAction().MovingUp;
	
	Notify("UpdatePresentationsInParticipantTree", NotificationParameters, Form.UUID);
	ParticipantsInActionWhenLineIsActivated(Form);
	
EndProcedure

// The handler of the Move Commands is in the form of an action.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   YouCanChangeOrderOfStages - Boolean - The action allows you to change the order of the stages.
//   ByPoints - Boolean - the action is performed point by point.
//
Procedure MoveParticipantOfActionDown(Form, YouCanChangeOrderOfStages = True, ByPoints = False) Export
	
	CurrentData = Form.Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(CurrentData.Function) Then
		Return;
	EndIf;
	
	If CurrentData.ThisIsAStep Then
		
		If Not YouCanChangeOrderOfStages And Not ByPoints Then
			ShowMessageBox(,NStr("vi = 'Không thể thay đổi trình tự các giai đoạn.';
								|ru = 'Нельзя менять порядок этапов.';
								|en = 'Cannot change the stage order.'; fa = 'Cannot change the stage order.';
								|it = 'Нельзя менять порядок этапов.';
								|pl = 'Cannot change the stage order.';
								|tr = 'Aşamaların sırası değiştirilemez.'"));
			Return;
		EndIf;
		
		Stages = Form.Attendees.GetItems();
		CurrentRowIndex = Stages.IndexOf(CurrentData);
		If CurrentRowIndex = Stages.Count() - 1
				Or IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(
					Stages[CurrentRowIndex + 1].Function) Then
			Return;
		EndIf;
		Stages.Move(CurrentRowIndex, 1);
		
		If YouCanChangeOrderOfStages Then
			FillInAvailabilityOfMovingStagesOfParticipantsOfAction(Stages);
		EndIf;
		
	Else
		
		ParticipantsOfStage = CurrentData.GetParent().GetItems();
		
		CurrentRowIndex = ParticipantsOfStage.IndexOf(CurrentData);
		
		If CurrentRowIndex = ParticipantsOfStage.Count() - 1 Then
			Return;
		EndIf;
		
		ParticipantsOfStage.Move(CurrentRowIndex, 1);
		
		If YouCanChangeOrderOfStages Then
			FillInAvailabilityOfMovingStagesOfParticipantsOfAction(ParticipantsOfStage);
		EndIf;
		
	EndIf;
	
	NotificationParameters = NewNotificationParametersChangesInParticipants();
	NotificationParameters.CurrentData = CurrentData;
	NotificationParameters.ChangeType = TypesOfChangesOfParticipantsInAction().MovingDown;
	
	Notify("UpdatePresentationsInParticipantTree", NotificationParameters, Form.UUID);
	ParticipantsInActionWhenLineIsActivated(Form);
	
EndProcedure

// The handler for processing the selection in the Order field in the action form.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   ValueSelected - Arbitrary - the selected value that will be set as the input field values.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//
Procedure OrderOfExecutionOfActionByParticipantsProcessingSelection(Form, ValueSelected, StandardProcessing) Export
	
	CurrentData = Form.Items.Attendees.CurrentData;
	
	If CurrentData <> Undefined Then
		CurrentData.Order = ValueSelected;
	EndIf;
	
EndProcedure

// Handler for changes in the Order field in the action form.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure ProcedureForPerformingActionByParticipantsWhenChanging(Form) Export
	
	CurrentData = Form.Items.Attendees.CurrentData;
	
	If CurrentData <> Undefined And CurrentData.Order = "AllAtOnce" Then
		
		ParticipantsOfStage = CurrentData.GetItems();
		If ParticipantsOfStage.Count() < 2 Then
			Return;
		EndIf;
		
		PerformerRow = ParticipantsOfStage[0];
		FillInDeadlinesOfCoExecutorsForCurrentLine(Form.Attendees, PerformerRow);
		Form.FillInPresentationOfDeadlines();
		Form.Modified = True;
	EndIf;
	
EndProcedure

// Saves the value of the "No longer show" checkbox after a warning about the security of participants.
//
// Parameters:
//   Result - Structure:
//     * NeverAskAgain - Boolean - the result of the user's choice in the checkbox of the same name.
//     * Value - DialogReturnCode - the result of the user's choice: the value associated with the pressed button.
//   AdditionalParameters - Undefined
//
Procedure AfterWarningAboutSecurityOfParticipantInAction(Result, AdditionalParameters) Export
	
	If Result <> Undefined And Result.NeverAskAgain Then
		CommonServerCall.CommonSettingsStorageSave(
			"SettingsNoLongerShow",
			"ShowWarningWhenSettingProtectionOfParticipantOfAction",
			False,,,
			True);
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Event handler for the automatic selection of the View item in the action participants table.
//
// Parameters:
//   Item - FormField - The Representation element is displayed in the action participants table.
//   Text - String - A string of text entered in the input field.
//   ChoiceData - ValueList of Structure - list to fill in:
//     * ID - String
//     * type - String
//     * name - String
//     * presentation - String
//   DataGetParameters - Structure:
//     * ChoiceFoldersAndItems - FoldersAndItemsUse
//     * Filter - Undefined
//     * FullTextSearch - Undefined
//     * ModeOfReceivingSelectionData - ChoiceDataGetModeOnInputByString
//     * StringSearchMethod - Undefined
//     * SearchString - String
//   Waiting - Number - the interval in seconds after the text entry that the event occurred in.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure PresentationOfParticipantOfActionAutoSelection(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing, Form) Export
	
	CurrentData = Form.Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ThisIsAStep = False;
	CurrentData.Property("ThisIsAStep", ThisIsAStep);
	
	If ValueIsFilled(Text) And ThisIsAStep = False Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing,
			New Structure("ContextOfCommunicationRules", ContextOfCommunicationRules(Form, Item.Name)));
	EndIf;
	
EndProcedure

// Handler for the event of the start of the selection of the Representation element in the table of participants of the action.
//
// Parameters:
//   Item - FormField - The Representation element is displayed in the action participants table.
//   ChoiceData - ValueList of Structure - list to fill in:
//     * ID - String
//     * type - String
//     * name - String
//     * presentation - String
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure PresentationOfParticipantOfActionBeginningOfChoice(Item, ChoiceData, StandardProcessing, Form) Export
	
	CurrentData = Form.Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	NotificationParameters = New Structure("Form, CurrentData", Form, CurrentData);
	Notification = New CallbackDescription(
		"PresentationOfParticipantOfActionBeginningOfChoiceCompletion",
		ThisObject,
		NotificationParameters);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.AddressBook",
		New Structure("ContextOfCommunicationRules", ContextOfCommunicationRules(Form, Item.Name)),
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Handler for the event Representation of the actionparticipation of the initial completion.
//
// Parameters:
//   Result - Structure:
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
//     * Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//     * CurrentData - FormDataTreeItem
//
Procedure PresentationOfParticipantOfActionBeginningOfChoiceCompletion(Result, NotificationParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentData = NotificationParameters.CurrentData;
	
	Result.Property("Performer", CurrentData.Member);
	Result.Property("PerformerID", CurrentData.MemberID);
	Result.Property("PerformerType", CurrentData.MemberType);
	
	Result.Property("MainAddressingObject", CurrentData.MainAddressingObjectMember);
	Result.Property("MainAddressingObjectID", CurrentData.MainAddressingObjectMemberID);
	Result.Property("MainAddressingObjectType", CurrentData.MainAddressingObjectMemberType);
	
	Result.Property("AdditionalAddressingObject", CurrentData.AdditionalAddressingObjectParticipant);
	Result.Property("AdditionalAddressingObjectID", CurrentData.AdditionalAddressingObjectParticipantID);
	Result.Property("AdditionalAddressingObjectType", CurrentData.AdditionalAddressingObjectParticipantType);
	
	CurrentData.MemberPresentation =
		IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
			CurrentData.Member,
			CurrentData.MainAddressingObjectMember,
			CurrentData.AdditionalAddressingObjectParticipant);
	
	NotificationParameters = NewNotificationParametersChangesInParticipants();
	NotificationParameters.CurrentData = CurrentData;
	NotificationParameters.ChangeType = TypesOfChangesOfParticipantsInAction().ChangingArtist;
	
	Notify("UpdatePresentationsInParticipantTree", NotificationParameters, NotificationParameters.Form.UUID);
	NotificationParameters.Form.Modified = True;
	
EndProcedure

// The event handler for processing the selection of the View item in the action participant table.
//
// Parameters:
//   Item - FormField - The Representation element is displayed in the action participants table.
//   ValueSelected - Arbitrary - the selected value that will be set as the input field values.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure PresentationOfParticipantOfActionProcessingOfChoice(Item, ValueSelected, StandardProcessing, Form) Export
	
	CurrentData = Form.Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ClearParticipantField(CurrentData);
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Member",
		ValueSelected,
		StandardProcessing,
		Form,
		True,
		Item);
	CurrentData.MemberPresentation =
		IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
			CurrentData.Member,
			CurrentData.MainAddressingObjectMember,
			CurrentData.AdditionalAddressingObjectParticipant);
	
	NotificationParameters = NewNotificationParametersChangesInParticipants();
	NotificationParameters.CurrentData = CurrentData;
	NotificationParameters.ChangeType = TypesOfChangesOfParticipantsInAction().ChangingArtist;
	
	Notify("UpdatePresentationsInParticipantTree", NotificationParameters, Form.UUID);
	
EndProcedure

// Handler for the event of the end of the Water text of the View Structure element in the table of participants in the action.
//
// Parameters:
//   Item - FormField - The Representation element is displayed in the action participants table.
//   Text - String - A string of text entered in the input field.
//   ChoiceData - ValueList of Structure - list to fill in:
//     * ID - String
//     * type - String
//     * name - String
//     * presentation - String
//   DataGetParameters - Structure:
//     * ChoiceFoldersAndItems - FoldersAndItemsUse
//     * Filter - Undefined
//     * FullTextSearch - Undefined
//     * ModeOfReceivingSelectionData - ChoiceDataGetModeOnInputByString
//     * StringSearchMethod - Undefined
//     * SearchString - String
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure PresentationOfParticipantOfActionEndOfTextInput(Item, Text, ChoiceData, DataGetParameters,
		StandardProcessing, Form) Export
	
	CurrentData = Form.Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ThisIsAStep = False;
	CurrentData.Property("ThisIsAStep", ThisIsAStep);
	
	If ValueIsFilled(Text) Then
		
		If ThisIsAStep Then
			
			CurrentData.StageName = Text;
			
		Else
			
			IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
				"DMEmployee",
				ChoiceData,
				Text,
				StandardProcessing,
				New Structure("ContextOfCommunicationRules", ContextOfCommunicationRules(Form, Item.Name)));
			
			If ChoiceData.Count() = 1 And Not ChoiceData[0].Value.isNotAvailableAccordingCommunicationRules Then
				
				ClearParticipantField(CurrentData);
				IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
					"Member",
					ChoiceData[0].Value,
					StandardProcessing,
					Form,
					True,
					Item);
				CurrentData.MemberPresentation =
					IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
						CurrentData.Member,
						CurrentData.MainAddressingObjectMember,
						CurrentData.AdditionalAddressingObjectParticipant);
				
				NotificationParameters = NewNotificationParametersChangesInParticipants();
				NotificationParameters.CurrentData = CurrentData;
				NotificationParameters.ChangeType = TypesOfChangesOfParticipantsInAction().ChangingArtist;
				
				Notify("UpdatePresentationsInParticipantTree",
					NotificationParameters, Form.UUID);
				StandardProcessing = True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The event handler Clears the View item in the action participant table.
//
// Parameters:
//   Item - FormField - The Representation element is displayed in the action participants table.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure PresentationOfParticipantOfCleaningAction(Item, StandardProcessing, Form) Export
	
	CurrentData = Form.Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ClearParticipantField(CurrentData);
	CurrentData.MemberPresentation =
		IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
			CurrentData.Member,
			CurrentData.MainAddressingObjectMember,
			CurrentData.AdditionalAddressingObjectParticipant);
	
	NotificationParameters = NewNotificationParametersChangesInParticipants();
	NotificationParameters.CurrentData = CurrentData;
	NotificationParameters.ChangeType = TypesOfChangesOfParticipantsInAction().ChangingArtist;
	
	Notify("UpdatePresentationsInParticipantTree", NotificationParameters, Form.UUID);
	Form.Modified = True;
	
EndProcedure

// Calls the code that is executed in the event handler when the action form is opened on the side BEFORE.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure WhenOpeningActionForm(Form) Export
	
	Form.SetFormItemEnabled();
	Form.FillInPresentationOfDeadlines();
	Form.IsInitialized = True;
	
EndProcedure

// Checks the participants, and records the action in case of successful verification.
//
// Parameters:
//   ActionXDTOString - String - string Presentation of an XDTO object of the type inheriting DMAction.
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   CallbackOnCompletion - CallbackDescription - calls the Form procedure after writing the object.
//
Procedure CheckParticipantsAndRecordAction(ActionXDTOString, Form, CallbackOnCompletion) Export
	
	TimeConsumingOperation = IntegrationWith1CDocumentManagement3ServerCall.CheckParticipantsAsynchronously(
		ActionXDTOString,
		Form.UUID);
	
	ParametersForRecording = New Structure("ActionXDTOString, Form, CallbackOnCompletion",
		ActionXDTOString, Form, CallbackOnCompletion);
	CheckParticipantsAndRecordActionCompletion = New CallbackDescription(
		"CheckParticipantsAndRecordActionCompletion",
		ThisObject,
		ParametersForRecording);
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CheckParticipantsAndRecordActionCompletion,
		True,
		NStr("vi = 'Kiểm tra người tham gia thao tác.';
			|ru = 'Проверка участников действия.';
			|en = 'Check action participants.'; fa = 'Check action participants.';
			|it = 'Проверка участников действия.';
			|pl = 'Check action participants.';
			|tr = 'Eylem katılımcılarının kontrolü.'"),
		False);
	
EndProcedure

// Called after executing a request to the DO to check the participants of the action in the background task.
//
// Parameters:
//   Result - See TimeConsumingOperations.ActionCompleted
//   ParametersForRecording - Structure:
//     * ActionXDTOString - String - string Presentation of an XDTO object of the type inheriting DMAction.
//     * Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//     * CallbackOnCompletion - CallbackDescription - calls the Form procedure after writing the object.
//
Procedure CheckParticipantsAndRecordActionCompletion(Result, ParametersForRecording) Export
	
	ProcessAForm = False;
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		CheckResult = IntegrationWith1CDocumentManagement3ServerCall.ResultOfCheckingParticipantsOfAction(
			Result.ResultLongOperation);
		If CheckResult.Success Then
			RecordActionAsynchronously(ParametersForRecording);
		Else
			ProcessResultOfCheckingValidityOfParticipantsInAction(
				CheckResult,
				ParametersForRecording);
		EndIf;
	ElsIf ProcessAForm Then
		ParametersForRecording.Form.ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

// Expands the rows of the action participant tree.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure ExpandActionParticipantTree(Form) Export
	
	For Each Stage In Form.Attendees.GetItems() Do
		Form.Items.Attendees.Expand(Stage.GetID());
	EndDo;
	
EndProcedure

// Event handler for a change in the Due date field in the action Form.
// In 1C:The document flow corresponds to the client's action.The deadline for submitting a change.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   FillInCoExecutors - Boolean - if True, then we fill in the same deadlines with the co-executors.
//
Procedure DeadlineForExecutionOfActionByParticipantInCaseOfChange(Form, FillInCoExecutors = False) Export
	
	CurrentData = Form.Items.Attendees.CurrentData;
	
	TermChangeParameters = IntegrationWith1CDocumentManagement3ClientServer.ParametersForChangingDeadlineForSubmission();
	TermChangeParameters.Performer = CurrentData.Member;
	TermChangeParameters.PerformerID = CurrentData.MemberID;
	TermChangeParameters.PerformerType = CurrentData.MemberType;
	TermChangeParameters.MainAddressingObjectPerformer = CurrentData.MainAddressingObjectMember;
	TermChangeParameters.MainAddressingObjectPerformerID = CurrentData.MainAddressingObjectMemberID;
	TermChangeParameters.MainAddressingObjectPerformerType = CurrentData.MainAddressingObjectMemberType;
	TermChangeParameters.AdditionalAddressingObjectExecutor =
		CurrentData.AdditionalAddressingObjectParticipant;
	TermChangeParameters.AdditionalAddressingObjectExecutorID =
		CurrentData.AdditionalAddressingObjectParticipantID;
	TermChangeParameters.AdditionalAddressingObjectExecutorType =
		CurrentData.AdditionalAddressingObjectParticipantType;
	
	FillingResult = IntegrationWith1CDocumentManagement3ServerCall.ChangeDeadlineForExecutionByPresentation(
		CurrentData.DueDate,
		CurrentData.Term_Days,
		CurrentData.TermHours,
		CurrentData.TermMinutes,
		CurrentData.OptionForSettingDeadline,
		CurrentData.DueDatePresentation,
		TermChangeParameters);
	
	If IntegrationWith1CDocumentManagement3ClientServer.ThisIsSigningAction(Form.Type) Then
		SubordinateItems = CurrentData.GetItems();
		If SubordinateItems.Count() = 1 Then
			// Copy down.
			Form.CopyDataToSigner(SubordinateItems[0], CurrentData);
		EndIf;
	EndIf;
	
	If FillingResult Then
		If FillInCoExecutors Then
			FillInDeadlinesOfCoExecutorsForCurrentLine(Form.Attendees, CurrentData);
		EndIf;
		Form.FillInPresentationOfDeadlines();
	EndIf;
	
	If ValueIsFilled(TermChangeParameters.TextOfWarningMessage) Then
		ShowWarningFromBEFORE(,TermChangeParameters.TextOfWarningMessage);
	EndIf;
	
EndProcedure

// The event handler is specified in the Time field in the Form of an action.
// In 1C:The document flow corresponds to the client's action.The timing of the presentation is deregulation.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   Direction - Number - When you press up, the parameter is 1, when you press down, the parameter is -1.
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//   FillInCoExecutors - Boolean - if True, then we fill in the same deadlines with the co-executors.
//
Procedure DurationOfActionByParticipantIsRegulation(Form, Direction, StandardProcessing,
		FillInCoExecutors = False) Export
	
	Items = Form.Items;
	CurrentData = Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ChangeRelativeTerm(
		CurrentData.Term_Days,
		CurrentData.TermHours,
		CurrentData.TermMinutes,
		Direction);
	
	OptionsForSettingDeadline = IntegrationWith1CDocumentManagement3ClientServer.OptionsForSettingDueDate();
	CurrentData.OptionForSettingDeadline = OptionsForSettingDeadline.RelativeTerm;
	CurrentData.DueDate = Date(1,1,1);
	
	If FillInCoExecutors Then
		FillInDeadlinesOfCoExecutorsForCurrentLine(Form.Attendees, CurrentData);
	EndIf;
	
	If IntegrationWith1CDocumentManagement3ClientServer.ThisIsSigningAction(Form.Type) Then
		SubordinateItems = CurrentData.GetItems();
		If SubordinateItems.Count() = 1 Then
			// Copy down.
			Form.CopyDataToSigner(SubordinateItems[0], CurrentData);
		EndIf;
	EndIf;
	
	Form.Modified = True;
	
	Form.FillInPresentationOfDeadlines();
	
EndProcedure

// Recursively sets the same deadline for all participants within each stage. When the "Different
// deadlines" option is disabled in some Forms of actions.
// In 1C:The document flow corresponds to the client's action.Install one such Macro recursively.
//
// Parameters:
//   TreeRows - FormDataTreeItemCollection - the Cur branch from the tree "Participants" on the Forms of actions.
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure SetSameExpirationDateRecursively(TreeRows, Form) Export
	
	If Form.Items.AttendeesDifferentTerms.Check Then
		Return; // The "Different dates" option is enabled.
	EndIf;
	
	For Each TreeRow In TreeRows Do
		SetSameExpirationDateRecursively(TreeRow.GetItems(), Form);
		
		If ThisIsLineOfResponsible(TreeRow) Then
			Continue;
		EndIf;
		
		If ValueIsFilled(TreeRow.DueDatePresentation) Then
			FillInDeadlinesOfCoExecutorsForCurrentLine(Form.Attendees, TreeRow);
			Form.Modified = True;
			Break;
		EndIf;
	EndDo;
	
	If Form.Modified Then
		Form.FillInPresentationOfDeadlines();
	EndIf;
	
EndProcedure

// If at least one branch of the tree has different deadlines, then the "Different deadlines" button is turned on.
// In 1C:The document flow corresponds to the client's action.Set the parameter to the buttons of the different options recursively.
//
// Parameters:
//   TreeRows - FormDataTreeItemCollection - the Cur branch from the tree "Participants" on the Forms of actions.
//   ButtonDifferentDates - FormButton - the "Different deadlines" button from the action Form.
//
Procedure MarkButtonsWithDifferentExpirationDatesRecursively(TreeRows, ButtonDifferentDates) Export
	
	PreviousTerm = Undefined;
	For Each TreeRow In TreeRows Do
		If ButtonDifferentDates.Check Then
			Return; // Already installed inside the recursion, it makes no sense to go further.
		EndIf;
		
		ThisIsLineOfResponsible = ThisIsLineOfResponsible(TreeRow);
		
		If TreeRow.Property("Order") And TreeRow.Order = "OneByOne" Then
			Continue;
		EndIf;
		
		If ValueIsFilled(TreeRow.Member)
				And Not ThisIsLineOfResponsible
				And PreviousTerm <> Undefined
				And PreviousTerm <> TreeRow.DueDatePresentation Then
			ButtonDifferentDates.Check = True;
			Return;
		EndIf;
		
		If Not ThisIsLineOfResponsible Then
			PreviousTerm = TreeRow.DueDatePresentation;
		EndIf;
		
		MarkButtonsWithDifferentExpirationDatesRecursively(TreeRow.GetItems(), ButtonDifferentDates);
	EndDo;
	
EndProcedure

// Event handler Selection of the Participants table.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   RowSelected - Number - the value of the selected row.
//   Field - FormField - active field (column).
//   StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//   OpenSpecialNameAndDescription - Boolean - You can open a separate Form to enter a description.
//   OnlyViewingSpecialNameAndDescription - Boolean - only view the specific name and description of the task.
//   ChangeTaskName - Boolean - In addition to the description, you also need to change the name of the task.
//
Procedure ParticipantsInActionChoice(Form, RowSelected, Field, StandardProcessing,
		OpenSpecialNameAndDescription = False, OnlyViewingSpecialNameAndDescription = True,
		ChangeTaskName = False) Export
	
	CurrentData = Form.Attendees.FindByID(RowSelected);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If OpenSpecialNameAndDescription And Field = Form.Items.ThereIsSpecialNameDescription Then
		
		StandardProcessing = False;
		
		FormParameters = New Structure;
		FormParameters.Insert("LongDesc", "");
		FormParameters.Insert("DescriptionIsSpecial", "");
		FillPropertyValues(FormParameters, CurrentData);
		FormParameters.Insert("Description", CurrentData.TaskDescription);
		If Not ChangeTaskName Then
			FormParameters.Insert("JustDescription", True);
		EndIf;
		FormParameters.Insert("ReadOnly", OnlyViewingSpecialNameAndDescription);
		
		NotificationParameters = New Structure(
			"Form, CurrentData, ChangeTaskName",
			Form,
			CurrentData,
			ChangeTaskName);
		CallbackDescription = New CallbackDescription(
			"CompleteConfigurationOfSpecialNameAndDescriptionOfArtist",
			ThisObject,
			NotificationParameters);
		
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagement3.Form.EditSpecialTaskDescriptionAndDetails",
			FormParameters,
			ThisObject,,,,
			CallbackDescription);
		
		Return;
		
	EndIf;
	
	If Form.ReadOnly Then
		Return;
	EndIf;
	
	If Field = Form.Items.AttendeesIsProtected Then
		ChangeProtectedActionParticipantAttribute(Form);
	EndIf;
	
EndProcedure

// Event handler before the start of adding the Participants table.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   Cancel - Boolean - rejection from the Form event handler.
//   Copy - Boolean - defines the copy mode.
//   ParametersForAddingParticipants - See IntegrationWith1CDocumentManagement3Client.ParametersForAddingParticipantsToAction
//
Procedure ParticipantsOfActionBeforeAdding(Form, Cancel, Copy, ParametersForAddingParticipants) Export
	
	Items = Form.Items;
	Attendees = Form.Attendees;
	WithStages = ParametersForAddingParticipants.WithStages;
	YouCanAddStages = ParametersForAddingParticipants.YouCanAddStages;
	ChildPerformersArePossible = ParametersForAddingParticipants.ChildPerformersArePossible;
	
	Cancel = True;
	
	If Copy Then
		Return;
	EndIf;
	
	If WithStages Then
		
		CurrentData = Items.Attendees.CurrentData;
		If CurrentData = Undefined Then
			Return;
		EndIf;
		
		If CurrentData.Property("ThisIsChildMember") And CurrentData.ThisIsChildMember Then
			Return;
		EndIf;
		
		If Not CurrentData.ThisIsAStep Then
			CurrentData = CurrentData.GetParent();
			If CurrentData = Undefined Then
				Return;
			EndIf;
			
			If ChildPerformersArePossible And Not CurrentData.ThisIsAStep Then
				CurrentData = CurrentData.GetParent();
				If CurrentData = Undefined Then
					Return;
				EndIf;
			EndIf;
		EndIf;
		
		If IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(CurrentData.Function) Then
			ShowMessageBox(,NStr("vi = 'Không thể thêm vào giai đoạn xử lý kết quả.';
								|ru = 'Добавление в этап обработки результата невозможно.';
								|en = 'Cannot add to the result processing stage.'; fa = 'Cannot add to the result processing stage.';
								|it = 'Добавление в этап обработки результата невозможно.';
								|pl = 'Cannot add to the result processing stage.';
								|tr = 'Sonucun işlem aşamasına eklenmesi mümkün değildir.'"));
			Return;
		EndIf;
		
		// Prohibited by the Action availability settings.
		If CurrentData.Unavailable Then
			If YouCanAddStages Then
				If Not CurrentData.AllowedToAdd Then
					Return;
				EndIf;
			Else
				If Not ParametersForAddingParticipants.YouCanOnlyAddMembers Then
					Return;
				EndIf;
			EndIf;
		EndIf;
		
	EndIf;
	
	If WithStages Then
		StageLines = CurrentData.GetItems();
	Else
		StageLines = Attendees.GetItems();
	EndIf;
	
	ParticipantLine = StageLines.Add();
	
	If ParticipantLine.Property("AllowedToAdd") Then
		ParticipantLine.AllowedToAdd = CurrentData.AllowedToAdd;
	EndIf;
	ParticipantLine.Function = ParametersForAddingParticipants.ParticipantFunction;
	ParticipantLine.Id = String(New UUID);
	If ParticipantLine.Property("SuperiorMember") Then
		ParticipantLine.SuperiorMember = "00000000-0000-0000-0000-000000000000";
	EndIf;
	ParticipantLine.LinePresentation = IntegrationWith1CDocumentManagement3ClientServer.ParticipantPresentation(
		ParticipantLine);
	
	IndexOfPreviousElement = StageLines.Count() - 2;
	
	If ChildPerformersArePossible Then
		While IndexOfPreviousElement >= 0 Do
			If IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(
					StageLines[IndexOfPreviousElement].Function) Then
				IndexOfPreviousElement = IndexOfPreviousElement - 1;
			Else
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	OptionsForSettingDeadline = IntegrationWith1CDocumentManagement3ClientServer.OptionsForSettingDueDate();
	
	If IndexOfPreviousElement >= 0 Then
		
		ParticipantLine.OptionForSettingDeadline = StageLines[IndexOfPreviousElement].OptionForSettingDeadline;
		
		If ParticipantLine.Property("Point_Id") Then
			ParticipantLine.Point_Id = StageLines[IndexOfPreviousElement].Point_Id;
		EndIf;
		
		If ParticipantLine.OptionForSettingDeadline = OptionsForSettingDeadline.Exact_Date Then
			If WithStages And YouCanAddStages Then
				If CurrentData.Order = "AllAtOnce" Then
					ParticipantLine.DueDate = StageLines[IndexOfPreviousElement].DueDate;
				EndIf;
			Else
				ParticipantLine.DueDate = StageLines[IndexOfPreviousElement].DueDate;
			EndIf;
		Else
			ParticipantLine.Term_Days = StageLines[IndexOfPreviousElement].Term_Days;
			ParticipantLine.TermHours = StageLines[IndexOfPreviousElement].TermHours;
			ParticipantLine.TermMinutes = StageLines[IndexOfPreviousElement].TermMinutes;
		EndIf;
		
		If ChildPerformersArePossible Then
			
			If IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(
					StageLines[IndexOfPreviousElement].Function) Then
				ParticipantLine.Function = ParametersForAddingParticipants.ParticipantFunction;
			Else
				ParticipantLine.Function = StageLines[IndexOfPreviousElement].Function;
			EndIf;
			
			CrntStringIndex = StageLines.IndexOf(ParticipantLine);
			If CrntStringIndex <> IndexOfPreviousElement + 1 Then
				StageLines.Move(CrntStringIndex, - 1);
			EndIf;
			
		EndIf;
		
		If ParticipantLine.Function = "ReviewingPerson" Then
			ParticipantLine.OptionForSettingResolutionProcessingTime =
				StageLines[IndexOfPreviousElement].OptionForSettingResolutionProcessingTime;
			If ParticipantLine.OptionForSettingResolutionProcessingTime = OptionsForSettingDeadline.Exact_Date Then
				ParticipantLine.ResolutionProcessingTime = StageLines[IndexOfPreviousElement].ResolutionProcessingTime;
			Else
				ParticipantLine.DeadlineForProcessingResolutionIsDays =
					StageLines[IndexOfPreviousElement].DeadlineForProcessingResolutionIsDays;
				ParticipantLine.ResolutionProcessingTimeHours =
					StageLines[IndexOfPreviousElement].ResolutionProcessingTimeHours;
				ParticipantLine.ProcessingTimeOfResolutionIsMinutes =
					StageLines[IndexOfPreviousElement].ProcessingTimeOfResolutionIsMinutes;
			EndIf;
		EndIf;
		
	Else
		
		ParticipantLine.OptionForSettingDeadline = OptionsForSettingDeadline.RelativeTerm;
		If ChildPerformersArePossible Then
			ParticipantLine.Function = CurrentData.Function;
		EndIf;
		
	EndIf;
	
	If WithStages And YouCanAddStages Then
		If CurrentData.TermIsGeneral Then
			FillPropertyValues(ParticipantLine, CurrentData,, "Order");
		EndIf;
		FillInAvailabilityOfMovingStagesOfParticipantsOfAction(StageLines);
	EndIf;
	
	Items.Attendees.CurrentRow = ParticipantLine.GetID();
	
	Form.SetFormItemEnabled();
	Form.FillInPresentationOfDeadlines();
	If ParticipantLine.Function = "ReviewingPerson" Then
		Form.FillInPresentationOfResolutionProcessingDeadlines();
	EndIf;
	
	Form.Modified = True;
	
EndProcedure

// Handler for the event before the Participants table is changed.
// Checks the security of the string, does not allow to change the executor if it is protected.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   Cancel - Boolean - rejection from the Form event handler.
//   WithStages - Boolean - the action has stages.
//
Procedure ParticipantsOfActionBeforeStartOfChange(Form, Cancel, WithStages = False) Export
	
	CurrentData = Form.Items.Attendees.CurrentData;
	
	If WithStages Then
		If CurrentData = Undefined Then
			Cancel = True;
		EndIf;
		If CurrentData.ThisIsAStep Then
			Cancel = True;
		EndIf;
	EndIf;
	
	If CurrentData <> Undefined
			And Form.Items.Attendees.CurrentItem.Name = "LinePresentation"
			And CurrentData.IsProtected
			And Not Form.YouCanChangeProtectedParticipants Then
		Cancel = True;
	EndIf;
	
EndProcedure

// Event handler before deleting the Participants table.
// Checks the security of the string, does not allow to delete the executor if he is protected or completed the task.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   Cancel - Boolean - rejection from the Form event handler.
//   WithStages - Boolean - the action has stages.
//   YouCanDeleteStages - Boolean - A stage can be deleted if there is more than one stage with the same function in the action.
//   ByPoints - Boolean - the action is performed point by point.
//
Procedure ParticipantsOfActionBeforeDeletion(Form, Cancel, WithStages = False, YouCanDeleteStages = False, ByPoints = False) Export
	
	Items = Form.Items;
	Attendees = Form.Attendees;
	Cancel = True;
	
	SelectedRows = CommonClient.CopyRecursive(Items.Attendees.SelectedRows);
	
	If WithStages Then
		
		AllStages = Attendees.GetItems();
		
		SelectedLinesNumber = SelectedRows.Count();
		
		// If only one line is selected, then we display a message that it cannot
		// be deleted. Otherwise, we silently delete all possible rows of the tree.
		If SelectedLinesNumber = 1 Then
			
			TreeRow = Attendees.FindByID(SelectedRows[0]);
			
			WarningText = "";
			
			If TreeRow.ThisIsAStep And YouCanDeleteStages Then
				NumberOfStagesOfThisType = 0;
				For Each Stage In AllStages Do
					If Stage.Function = TreeRow.Function Then
						NumberOfStagesOfThisType = NumberOfStagesOfThisType + 1;
					EndIf;
				EndDo;
				
				If NumberOfStagesOfThisType < 2 Then
					If TreeRow.Function = "Signer" Then
						WarningText = NStr("vi = 'Không thể xóa giai đoạn ký duy nhất.';
											|ru = 'Удаление единственного этапа подписания невозможно.';
											|en = 'Cannot delete the only signing stage.'; fa = 'Cannot delete the only signing stage.';
											|it = 'Удаление единственного этапа подписания невозможно.';
											|pl = 'Cannot delete the only signing stage.';
											|tr = 'Tek imza aşamasının silinmesi mümkün değildir.'");
					ElsIf TreeRow.Function = "ApprovingPerson" Then
						WarningText = NStr("vi = 'Không thể xóa giai đoạn thống nhất duy nhất.';
											|ru = 'Удаление единственного этапа согласования невозможно.';
											|en = 'Cannot delete the only approval stage.'; fa = 'Cannot delete the only approval stage.';
											|it = 'Удаление единственного этапа согласования невозможно.';
											|pl = 'Cannot delete the only approval stage.';
											|tr = 'Tek mutabakat aşamasının silinmesi mümkün değildir.'");
					ElsIf IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(TreeRow.Function) Then
						WarningText = NStr("vi = 'Không thể xóa giai đoạn xử lý kết quả.';
											|ru = 'Удаление этапа обработки результата невозможно.';
											|en = 'Cannot delete the result processing stage.'; fa = 'Cannot delete the result processing stage.';
											|it = 'Удаление этапа обработки результата невозможно.';
											|pl = 'Cannot delete the result processing stage.';
											|tr = 'Sonuç işleme aşamasının silinmesi mümkün değildir.'");
					EndIf;
				EndIf;
			EndIf;
			
			If TreeRow.ThisIsAStep And Not ByPoints And Not YouCanDeleteStages Then
				WarningText = WarningTextWhenDeletingStage();
			EndIf;
			
			If ValueIsFilled(WarningText) Then
				ShowMessageBox(,WarningText);
				Return;
			EndIf;
			
		EndIf;
		
		If Not YouCanDeleteStages Or SelectedLinesNumber > 1 Then
			
			// First, we exclude stages and participants that cannot be deleted.
			RowIndex = SelectedLinesNumber - 1;
			
			While RowIndex >= 0 Do
				
				CurrentRowIndex = RowIndex;
				RowIndex = RowIndex - 1;
				
				TreeRow = Attendees.FindByID(SelectedRows[CurrentRowIndex]);
				
				If TreeRow.ThisIsAStep And Not ByPoints Then
					SelectedRows.Delete(CurrentRowIndex);
					Continue;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	// We delete all selected participants.
	SelectedLinesNumber = SelectedRows.Count();
	RowIndex = SelectedLinesNumber - 1;
	
	While RowIndex >= 0 Do
		
		CurrentRowIndex = RowIndex;
		RowIndex = RowIndex - 1;
		
		ParticipantLine = Attendees.FindByID(SelectedRows[CurrentRowIndex]);
		If ParticipantLine = Undefined Then
			Continue;
		EndIf;
		
		IsProtected = False;
		Unavailable = False;
		ParticipantLine.Property("IsProtected", IsProtected);
		ParticipantLine.Property("Unavailable", Unavailable);
		
		If IsProtected = True And Not Form.YouCanChangeProtectedParticipants Then
			WarningText = WarningTextWhenDeletingProtected();
		ElsIf Unavailable = True And Not ValueIsFilled(WarningText) Then
			WarningText = WarningTextWhenDeletingUnavailable();
		EndIf;
		
		If ParticipantLine.State = "Completed" Then
			WarningText = WarningTextWhenDeletingCompleted();
		EndIf;
		
		If ValueIsFilled(WarningText) Then
			ShowMessageBox(,WarningText);
			Return;
		EndIf;
		
		If WithStages Then
			StageString_ = ParticipantLine.GetParent();
			If StageString_ = Undefined And (ByPoints Or YouCanDeleteStages) Then
				// Delete the stage.
				AllStages.Delete(ParticipantLine);
				
				If YouCanDeleteStages Then
					FillInAvailabilityOfMovingStagesOfParticipantsOfAction(AllStages);
				EndIf;
			Else
				// Delete the participant.
				ElementsOfParticipants = StageString_.GetItems();
				If IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(StageString_.Function) Then
					If Items.Attendees.CurrentItem.Name = "LinePresentation" Then
						ElementsOfParticipants[0].Member = "";
						ElementsOfParticipants[0].MemberID = "";
						ElementsOfParticipants[0].MemberType = "";
						ElementsOfParticipants[0].MainAddressingObjectMember = "";
						ElementsOfParticipants[0].MainAddressingObjectMemberID = "";
						ElementsOfParticipants[0].MainAddressingObjectMemberType = "";
						ElementsOfParticipants[0].AdditionalAddressingObjectParticipant = "";
						ElementsOfParticipants[0].AdditionalAddressingObjectParticipantID = "";
						ElementsOfParticipants[0].AdditionalAddressingObjectParticipantType = "";
						ElementsOfParticipants[0].MemberPresentation =
							IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
								ElementsOfParticipants[0].Member,
								ElementsOfParticipants[0].MainAddressingObjectMember,
								ElementsOfParticipants[0].AdditionalAddressingObjectParticipant);
					EndIf;
				Else
					ElementsOfParticipants.Delete(ParticipantLine);
				EndIf;
				
				If YouCanDeleteStages Then
					FillInAvailabilityOfMovingStagesOfParticipantsOfAction(ElementsOfParticipants);
				EndIf;
			EndIf;
		Else
			Attendees.GetItems().Delete(ParticipantLine);
		EndIf;
		
		SelectedRows.Delete(CurrentRowIndex);
		Form.Modified = True;
	EndDo;
	
	If Form.Modified Then
		Notify("DeletingParticipantsInAction",, Form.UUID);
	EndIf;
	
EndProcedure

// Handler for activating a row in the action participants table.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure ParticipantsInActionWhenLineIsActivated(Form) Export
	
	MarkCommandsProtected(Form);
	SetAvailabilityOfCommandsProtected(Form);
	SetOnlyViewingAndDeletingParticipantBySecurity(Form);
	SetAvailabilityOfButtonDifferentDates(Form);
	
EndProcedure

// Checks the uniqueness of the action steps.
//
// Parameters:
//   Attendees - FormDataTree - a tree with the participants of the action.
//
// Returns:
//   Boolean
//
Function StagesOfActionAreUnique(Attendees) Export
	
	Stages = New Map;
	For Each ElementStage In Attendees.GetItems() Do
		If ValueIsFilled(ElementStage.StageName)
				And Stages.Get(Upper(ElementStage.StageName)) <> Undefined Then
			ShowMessageBox(,StrTemplate(NStr("vi = 'Lặp lại giai đoạn ""%1""';
											|ru = 'Повторяется этап ""%1""';
											|en = 'The ""%1"" stage is duplicated'; fa = 'The ""%1"" stage is duplicated';
											|it = 'Повторяется этап ""%1""';
											|pl = 'The ""%1"" stage is duplicated';
											|tr = '""%1"" aşaması tekrarlanıyor'"), ElementStage.StageName));
			Return False;
		EndIf;
		Stages.Insert(Upper(ElementStage.StageName), True);
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion

#Region Links

// Returns the current row data of the link tree for viewing the linked object.
//
// Parameters:
//   LinkTree - FormTable - a tree of links on a Form.
//
// Returns:
//   FormDataTreeItem
//   Undefined - if the current data is not highlighted.
//
Function LinkTreeCurrentDataToView(Val LinkTree) Export
	
	CurrentData = LinkTree.CurrentData;
	If CurrentData <> Undefined And (CurrentData.ThisIsCommunicationBranch Or CurrentData.ThisIsRoleOfFile) Then
		CurrentData = CurrentData.GetParent();
	EndIf;
	
	Return CurrentData;
	
EndFunction

// Starts adding a link to the specified Workflow object.
//
// Parameters:
//   InitialObjectBefore - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
Procedure StartAddingLink(InitialObjectBefore) Export
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.CreateRelation",
		InitialObjectBefore,,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Starts deleting a link from the link tree.
//
// Parameters:
//   LinkTree - FormTable - a tree of links on a Form.
//   InitialObjectBefore - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
Async Procedure StartDeletingLink(Val LinkTree, Val InitialObjectBefore) Export
	
	CurrentData = LinkTree.CurrentData;
	
	If Not LinkCanBeDeleted(CurrentData) Then
		Return;
	EndIf;
	
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
		NStr("vi = 'Xóa liên kết?';
			|ru = 'Удалить связь?';
			|en = 'Remove the link?'; fa = 'Remove the link?';
			|it = 'Удалить связь?';
			|pl = 'Usunąć powiązanie?';
			|tr = 'Bağlantı silinsin mi?'"));
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	LinkedObject = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		CurrentData.LinkedObjectID,
		CurrentData.LinkedObjectType,
		CurrentData.LinkedObject,
		CurrentData.RelatedString);
	
	LinkType = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		CurrentData.LinkTypeID,
		"DMRelationType");
	
	IntegrationWith1CDocumentManagement3ServerCall.DeleteObjectLinksBEFORE(
		InitialObjectBefore,
		LinkedObject,
		LinkType);
	
	Notify("DeletingObjectLinksBEFORE", InitialObjectBefore);
	
EndProcedure

// Opens the linked object for viewing.
//
// Parameters:
//   LinkTreeString - FormDataTreeItem - the current row of the relationship tree.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure OpenLinkedObjectForViewing(Val LinkTreeString, FormUniqueID) Export
	
	If LinkTreeString = Undefined Then
		Return;
	EndIf;
	
	If LinkTreeString.ThisIsCommunicationBranch Then
		OpenWorkflowFormFromLinkTree(
			"LinkPage",
			LinkTreeString.GetParent(),
			FormUniqueID);
		Return;
	ElsIf LinkTreeString.ThisIsRoleOfFile Then
		LinkTreeString = LinkTreeString.GetParent();
	EndIf;
	
	If ValueIsFilled(LinkTreeString.RelatedString) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenURL(
			LinkTreeString.RelatedString);
		Return;
	EndIf;
	
	ObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		LinkTreeString.LinkedObjectID,
		LinkTreeString.LinkedObjectType,
		LinkTreeString.LinkedObject,,
		LinkTreeString.URL);
	OpenPlaceForViewing(
		LinkTreeString.Ref,
		ObjectBefore,
		LinkTreeString.FileExtention,
		FormUniqueID);
	
EndProcedure

// Opens the "Workflow" Form.
//
// Parameters:
//   HomePage - String - The name of the Workflow Form page to open.
//   LinkTreeString - FormDataTreeItem - the current row of the relationship tree.
//   FormUniqueID - UUID - ID of the calling form.
//
Procedure OpenWorkflowFormFromLinkTree(HomePage, Val LinkTreeString,
		FormUniqueID) Export
	
	If LinkTreeString = Undefined Then
		Return;
	EndIf;
	If LinkTreeString.ThisIsCommunicationBranch Or LinkTreeString.ThisIsRoleOfFile Then
		LinkTreeString = LinkTreeString.GetParent();
	EndIf;
	
	If ValueIsFilled(LinkTreeString.Ref) Then
		FormParameters = New Structure;
		FormParameters.Insert("ExternalObject", LinkTreeString.Ref);
		FormParameters.Insert("HomePage", HomePage);
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagement3.Form.DocumentManagement",
			FormParameters,
			ThisObject,
			LinkTreeString.LinkedObjectID,,,,
			FormWindowOpeningMode.LockOwnerWindow);
	Else
		OpenLinkedObjectForViewing(LinkTreeString, FormUniqueID);
	EndIf;
	
EndProcedure

// Opens the links of the Document management object.
//
// Parameters:
//   ObjectBefore - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
Procedure ShowObjectConnections(ObjectBefore) Export
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.ObjectLinks", ObjectBefore,, ObjectBefore.ID);
	
EndProcedure

// Expands the row of the relationship tree.
//
// Parameters:
//   LineToExpand - Number - index of the line to expand.
//   LinkTree - FormDataTree - A Form Attribute containing a tree of links.
//   ElementsOfRelationshipTree - FormTable - a Form element containing a tree of links.
//
Procedure ExpandLinkTreeLevel(LineToExpand, LinkTree, ElementsOfRelationshipTree) Export
	
	If LineToExpand = 0 Then
		StringCollectionLinkTypeLevel = LinkTree.GetItems();
	Else
		StringCollectionLinkTypeLevel = LinkTree.FindByID(LineToExpand).GetItems();
	EndIf;
	
	For Each LinkTypeString In StringCollectionLinkTypeLevel Do
		RowID = LinkTypeString.GetID();
		ElementsOfRelationshipTree.Expand(RowID, False);
		CollectionOfStringsLevelOfRelatedObjects = LinkTypeString.GetItems();
		For Each StringRelatedObject In CollectionOfStringsLevelOfRelatedObjects Do
			RowID = StringRelatedObject.GetID();
			ElementsOfRelationshipTree.Expand(RowID, StringRelatedObject.ThisIsRoleOfFile);
			StringCollectionFileLevel = StringRelatedObject.GetItems();
			For Each FileRow In StringCollectionFileLevel Do
				If Not FileRow.ThisIsCommunicationBranch Then
					RowID = FileRow.GetID();
					ElementsOfRelationshipTree.Expand(RowID, FileRow.ThisIsRoleOfFile);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

// Returns whether the link can be deleted.
//
// Parameters:
//   RelationshipTreeCurrentData - FormDataTreeItem - the current row of the relationship tree.
//
// Returns:
//   Boolean
//
Function LinkCanBeDeleted(RelationshipTreeCurrentData) Export
	
	If RelationshipTreeCurrentData = Undefined
			Or RelationshipTreeCurrentData.ThisIsParent
			Or RelationshipTreeCurrentData.ThisIsRoleOfFile
			Or RelationshipTreeCurrentData.ThisIsCommunicationBranch Then
		Return False;
	EndIf;
	
	ParentRow = RelationshipTreeCurrentData.GetParent();
	
	If RelationshipTreeCurrentData.LinkedObjectType = "DMFile" And Not ParentRow.ThisIsParent Then
		// This is the file attached to the linked document.
		Return False;
	EndIf;
	
	If ParentRow.GetParent() <> Undefined Then
		// This is a nested link.
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region CommunicationRules

// Returns the context of the communication rules.
//
// Parameters:
//   Form - ClientApplicationForm - Form-the source of the event.
//   FieldName - String - the name of the field from which the call was made.
//
// Returns:
//   Structure:
//     * ref - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//     * action - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//     * initiator - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//     * participantFunction - String - the function of the participant.
//     * pointName - String - Name of the stage.
//     * fieldName - String - field name.
//     * target - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
Function ContextOfCommunicationRules(Form, FieldName = "") Export
	
	Context = New Structure;
	
	If StrStartsWith(Form.FormName, "DataProcessor.IntegrationWith1CDocumentManagement3.Form.Action") Then
		
		Context.Insert("ref", ValueOfObjectTypeContextElement(Form, "MainSubject"));
		Context.Insert("action", ValueOfObjectTypeContextElement(Form));
		Context.Insert("initiator", ValueOfObjectTypeContextElement(Form, "Author"));
		
		ParticipantFunctionIsFilledIn = False;
		StageNameIsFilledIn = False;
		ParticipantsCurrentData = Form.Items.Attendees.CurrentData;
		While ParticipantsCurrentData <> Undefined Do
			If Not ParticipantFunctionIsFilledIn Then
				ParticipantFunction = CommonClientServer.StructureProperty(ParticipantsCurrentData, "Function");
				If ValueIsFilled(ParticipantFunction) Then
					Context.Insert("participantFunction", ParticipantFunction);
					ParticipantFunctionIsFilledIn = True;
				EndIf;
			EndIf;
			If Not StageNameIsFilledIn Then
				StageName = CommonClientServer.StructureProperty(
					ParticipantsCurrentData,
					"StageName");
				If ValueIsFilled(StageName) Then
					Context.Insert("pointName", StageName);
					StageNameIsFilledIn = True;
				EndIf;
			EndIf;
			If ParticipantFunctionIsFilledIn And StageNameIsFilledIn Then
				Break;
			EndIf;
			ParticipantsCurrentData = ParticipantsCurrentData.GetParent();
		EndDo;
		
		If FieldName = "LinePresentation" Then
			Context.Insert("fieldName", "ActionParticipant");
		ElsIf FieldName = "Whom" Then
			Context.Insert("fieldName", "NewTaskPerformer");
		EndIf;
		
	ElsIf Form.FormName =
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.TaskRedirecting" Then
		
		Context.Insert("target", ValueOfObjectTypeContextElement(Form, "Task"));
		
	EndIf;
	
	Return Context;
	
EndFunction

// Displays a warning about selecting an item that is not available according to the communication rules.
//
Procedure ShowViolationOfRulesOfCommunication() Export
	
	WarningText = NStr("vi = 'Phần tử được chọn sẽ không khả dụng theo phân cấp trao đổi và xử lý công việc';
						|ru = 'Выбранный элемент недоступен по правилам коммуникаций';
						|en = 'The selected item is unavailable according to the communication rules'; fa = 'The selected item is unavailable according to the communication rules';
						|it = 'Выбранный элемент недоступен по правилам коммуникаций';
						|pl = 'The selected item is unavailable according to the communication rules';
						|tr = 'Seçili öğe iletişim kuralları ile uyuşmuyor'");
	ShowMessageBox(,WarningText);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ActionsAuxiliaryMethods

// Checks the availability of changes to the security of the document processing participant.
// You cannot change the security of a participant if it is set in the action setting.
//
// Parameters:
//   Member - FormDataTreeItem - the participant string in the processing participant tree.
//   YouCanChangeProtected - Boolean
//
// Returns:
//   Boolean - Changing The Security Of The Participant Is Available
//
Function ChangingSecurityOfParticipantIsAvailable(Member, YouCanChangeProtected)
	
	Result = True;
	Parent = Member.GetParent();
	ThisIsConsideration = False;
	If Parent <> Undefined Then
		ThisIsConsideration = (Parent.Function = "ReviewingPerson") And Not Parent.ThisIsAStep;
	EndIf;
	If Member.ThisIsAStep Then
		Result = False;
	ElsIf Not ValueIsFilled(Member.Member) Then
		Result = False;
	ElsIf Member.Property("Unavailable") And Member.Unavailable Then
		Result = False;
	ElsIf Member.Property("FromSettings") And Member.FromSettings And Not YouCanChangeProtected Then
		Result = Not Member.ProtectedInSetting;
	ElsIf ThisIsConsideration Then
		Result = False;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure RecordActionAsynchronously(ParametersForRecording)
	
	If ParametersForRecording.Form.DialogMode Then
		ParametersForRecording.Form.Modified = False;
		ParametersForRecording.Form.Close(ParametersForRecording.ActionXDTOString);
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.WriteObjectAsynchronously(
		ParametersForRecording.Form.UUID,
		ParametersForRecording.ActionXDTOString,
		ParametersForRecording.CallbackOnCompletion);
	
EndProcedure

// Fills in the deadlines of the co-executors of the stage according to the line in which the deadline has changed.
//
// Parameters:
//   Attendees - FormDataTree - a tree with the participants of the action.
//   PerformerRow - ValueTreeRow - the line where the deadline has changed.
//
Procedure FillInDeadlinesOfCoExecutorsForCurrentLine(Attendees, PerformerRow)
	
	ParticipantsOfStage = Attendees.GetItems();
	
	If ThisIsLineOfResponsible(PerformerRow) Then
		Return;
	EndIf;
	
	// With sequential execution, the deadlines are adjusted individually.
	CurrentParent = PerformerRow.GetParent();
	If CurrentParent <> Undefined Then
		ThereAreStages = True;
		If CurrentParent.Property("Order") And CurrentParent.Order = "OneByOne" Then
			Return;
		EndIf;
		
		// For those considering deadlines, we do not copy.
		If ThisIsLineOfReviewer(CurrentParent) Then
			Return;
		EndIf;
	Else
		ThereAreStages = False;
	EndIf;
	
	OptionsForSettingDeadline = IntegrationWith1CDocumentManagement3ClientServer.OptionsForSettingDueDate();
	OptionForSettingDeadline = PerformerRow.OptionForSettingDeadline;
	
	If OptionForSettingDeadline = OptionsForSettingDeadline.Exact_Date Then
		DueDate = PerformerRow.DueDate;
		Term_Days = 0;
		TermHours = 0;
		TermMinutes = 0;
	Else
		DueDate = Date(1,1,1);
		Term_Days = PerformerRow.Term_Days;
		TermHours = PerformerRow.TermHours;
		TermMinutes = PerformerRow.TermMinutes;
	EndIf;
	
	If ThereAreStages Then
		
		For Each AllParticipantsOfStage In ParticipantsOfStage Do
			If CurrentParent <> AllParticipantsOfStage Then
				Continue;
			EndIf;
			
			For Each StageParticipant In AllParticipantsOfStage.GetItems() Do
				If ThisIsLineOfResponsible(StageParticipant) Then
					Continue;
				EndIf;
				
				StageParticipant.DueDate = DueDate;
				StageParticipant.Term_Days = Term_Days;
				StageParticipant.TermHours = TermHours;
				StageParticipant.TermMinutes = TermMinutes;
				StageParticipant.OptionForSettingDeadline = OptionForSettingDeadline;
			EndDo;
		EndDo;
		
	Else
		
		For Each StageParticipant In ParticipantsOfStage Do
			StageParticipant.DueDate = DueDate;
			StageParticipant.Term_Days = Term_Days;
			StageParticipant.TermHours = TermHours;
			StageParticipant.TermMinutes = TermMinutes;
			StageParticipant.OptionForSettingDeadline = OptionForSettingDeadline;
		EndDo;
		
	EndIf;
	
EndProcedure

// Returns a property of an object. If the property is missing, returns an empty value.
//
// Parameters:
//   Object - Arbitrary - Any object with fields/Attributes/properties.
//   PropertyName - String - Name of the property whose value needs to be determined.
//   EmptyValue - Arbitrary - Empty property value.
//
// Returns:
//   Arbitrary
//
Function ObjectPropertyValue(Object, PropertyName, EmptyValue)
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert(PropertyName, EmptyValue);
	
	FillPropertyValues(TheStructureOfTheSearch, Object);
	
	Return TheStructureOfTheSearch[PropertyName];
	
EndFunction

// Processes the result of checking the participants of the action.
//
// Parameters:
//   CheckResult - See IntegrationWith1CDocumentManagement3ServerCall.ResultOfCheckingParticipantsOfAction
//   ParametersForRecording - Structure:
//     * ActionXDTOString - String - string Presentation of an XDTO object of the type inheriting DMAction.
//     * Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//     * CallbackOnCompletion - CallbackDescription - calls the Form procedure after writing the object.
//
Procedure ProcessResultOfCheckingValidityOfParticipantsInAction(CheckResult, ParametersForRecording)
	
	QuestionButtons = New ValueList(); // ValueList of Number, DialogReturnCode
	QuestionButtons.Add(0, NStr("vi = 'Thay thế';
								|ru = 'Заменить';
								|en = 'Replace'; fa = 'جایگزینی';
								|it = 'Заменить';
								|pl = 'Replace';
								|tr = 'Değiştir'"));
	QuestionButtons.Add(1, NStr("vi = 'Để lại như cũ';
								|ru = 'Оставить как есть';
								|en = 'Keep as-is.'; fa = 'Keep as-is.';
								|it = 'Lasciare come è';
								|pl = 'Zostaw jak jest';
								|tr = 'Olduğu gibi bırak'"));
	QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Отмена';
														|pl = 'Cancel';
														|tr = 'İptal'"));
	
	DefaultButton = 0;
	
	NotificationAfterQuestionOfReplacement = New CallbackDescription(
		"ProcessResultOfCheckingValidityOfParticipantsInActionContinued",
		ThisObject,
		ParametersForRecording);
	
	ShowQueryBox(
		NotificationAfterQuestionOfReplacement,
		CheckResult.WarningText,
		QuestionButtons,,
		DefaultButton);
	
EndProcedure

// Processes the result of checking the participants of the action continuation.
//
// Parameters:
//   QuestionResult - Number
//                    - DialogReturnCode - Replace, Leave as is, Cancel.
//   ParametersForRecording - Structure:
//     * ActionXDTOString - String - string Presentation of an XDTO object of the type inheriting DMAction.
//     * Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//     * CallbackOnCompletion - CallbackDescription - calls the Form procedure after writing the object.
//
Procedure ProcessResultOfCheckingValidityOfParticipantsInActionContinued(QuestionResult,
		ParametersForRecording) Export
	
	// Selected cancellation or agreed to replace participants.
	If QuestionResult = DialogReturnCode.Cancel Or QuestionResult = 0 Then
		Return;
	EndIf;
	
	// He wants to continue as it is.
	If QuestionResult = 1 Then
		RecordActionAsynchronously(ParametersForRecording);
	EndIf;
	
EndProcedure

// Returns the text of the warning that the processing stage cannot be deleted.
//
// Returns:
//   String
//
Function WarningTextWhenDeletingStage()
	
	Return NStr("vi = 'Không thể xóa bỏ giai đoạn.';
				|ru = 'Удаление этапа невозможно.';
				|en = 'Cannot delete the stage.'; fa = 'Cannot delete the stage.';
				|it = 'Удаление этапа невозможно.';
				|pl = 'Cannot delete the stage.';
				|tr = 'Aşamanın silinmesi mümkün değildir.'");
	
EndFunction

// Returns the text of a warning about the inability to delete protected participants.
//
// Returns:
//   String
//
Function WarningTextWhenDeletingProtected()
	
	Return NStr("vi = 'Không thể xóa người tham gia bảo mật.';
				|ru = 'Удаление защищенных участников невозможно.';
				|en = 'Cannot delete protected participants.'; fa = 'Cannot delete protected participants.';
				|it = 'Удаление защищенных участников невозможно.';
				|pl = 'Cannot delete protected participants.';
				|tr = 'Korumalı katılımcıların silinmesi mümkün değildir.'");
	
EndFunction

// Returns the text of the warning that the participant who completed the task cannot be deleted.
//
// Returns:
//   String
//
Function WarningTextWhenDeletingCompleted()
	
	Return NStr("vi = 'Không thể xóa người tham gia hoàn tất nhiệm vụ.';
				|ru = 'Удаление участника завершившего задачу невозможно.';
				|en = 'Cannot delete a participant who completed a task.'; fa = 'Cannot delete a participant who completed a task.';
				|it = 'Удаление участника завершившего задачу невозможно.';
				|pl = 'Cannot delete a participant who completed a task.';
				|tr = 'Görevi tamamlayan katılımcının silinmesi mümkün değildir.'");
	
EndFunction

// Returns the text of a warning that unavailable participants cannot be deleted.
//
// Returns:
//   String
//
Function WarningTextWhenDeletingUnavailable()
	
	Return NStr("vi = 'Không thể xóa người tham gia.';
				|ru = 'Удаление участника невозможно.';
				|en = 'Cannot delete the participant.'; fa = 'Cannot delete the participant.';
				|it = 'Удаление участника невозможно.';
				|pl = 'Cannot delete the participant.';
				|tr = 'Katılımcının silinmesi mümkün değildir.'");
	
EndFunction

// Sets the availability of the "Protected" Command in the action participants command panel.
// Used when activating a row in the participant table.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure SetAvailabilityOfCommandsProtected(Form)
	
	CurrentData = Form.Items.Attendees.CurrentData;
	
	If CurrentData = Undefined Then
		Form.Items.IsProtected.Enabled = False;
		Return;
	EndIf;
	
	Form.Items.IsProtected.Enabled = ChangingSecurityOfParticipantIsAvailable(
		CurrentData,
		Form.YouCanChangeProtectedParticipants);
	
EndProcedure

// Determines the availability of the "Different terms" button - it is not available in all types of actions, and is not available under any conditions.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure SetAvailabilityOfButtonDifferentDates(Form)
	
	If Form.Items.Find("AttendeesDifferentTerms") = Undefined Then
		Return; // There is no "Different deadlines" button.
	EndIf;
	Form.Items.AttendeesDifferentTerms.Enabled = False;
	
	If Form.ReadOnly Then
		Return;
	EndIf;
	
	TreeRow = Form.Items.Attendees.CurrentData;
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	If Form.Items.Find("DueDatePresentation") = Undefined Then
		Return;
	EndIf;
	If Form.Items.DueDatePresentation.ReadOnly Then
		If Not TreeRow.ThisIsAStep Then
			Return; // If the deadline change is not available, then you can't press the button either.
		EndIf;
		
		// If this is a stage, then you need to check whether the change of participants in this stage is available.
		If TreeRow.Property("Unavailable") And TreeRow.Unavailable Then
			Return;
		EndIf;
	EndIf;
	
	If TreeRow.Property("Order") And TreeRow.Order = "OneByOne" Then
		Return;
	EndIf;
	ThisIsExecutionSetting = False;
	ThisIsExecution = (Form.Type = "DMActionPerformance") Or ThisIsExecutionSetting;
	
	If ThisIsExecutionSetting And Form.ByPoints Then
		Return;
	EndIf;
	If ThisIsExecution And ThisIsLineOfReviewer(TreeRow) Then
		Return;
	EndIf;
	
	ParentRow = TreeRow.GetParent();
	If ParentRow <> Undefined Then
		If ParentRow.Property("Order") And ParentRow.Order = "OneByOne" Then
			Return;
		EndIf;
		If ThisIsExecution And ThisIsLineOfReviewer(ParentRow) Then
			Return;
		EndIf;
	EndIf;
	
	Form.Items.AttendeesDifferentTerms.Enabled = True;
	
EndProcedure

// Sets the "Protected" Command mark in the action participants command panel.
// Used when activating a row in the participant table.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure MarkCommandsProtected(Form)
	
	GeneralSecurity = Undefined;
	For Each SelectedRow In Form.Items.Attendees.SelectedRows Do
		
		TreeRow = Form.Attendees.FindByID(SelectedRow);
		
		If GeneralSecurity = Undefined Then
			GeneralSecurity = TreeRow.IsProtected;
		EndIf;
		
		GeneralSecurity = GeneralSecurity And TreeRow.IsProtected;
		
	EndDo;
	
	If GeneralSecurity = Undefined Then
		Form.Items.IsProtected.Check = False;
	Else
		Form.Items.IsProtected.Check = GeneralSecurity;
	EndIf;
	
EndProcedure

// Sets the availability of the "Delete" Command in the action participants command panel.
// Checks whether the selected participant or the participants of the selected stage are not protected from deletion.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
Procedure SetOnlyViewingAndDeletingParticipantBySecurity(Form)
	
	YouCanChangeProtected = Form.YouCanChangeProtectedParticipants;
	IsDeletionDenied = False;
	
	CurrentData = Form.Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ThisIsSecuringSigning = IntegrationWith1CDocumentManagement3ClientServer.ThisIsSigningAction(Form.Type)
		And CurrentData.ThisIsChildMember
		And CurrentData.Function = "EnsuringSigning";
	
	If CurrentData.ThisIsAStep Then
		IsDeletionDenied = IntegrationWith1CDocumentManagement3ClientServer.ThereAreProtectedParticipantsInAction(CurrentData);
	ElsIf CurrentData.IsProtected Then
		IsDeletionDenied = True;
	EndIf;
	
	If IsDeletionDenied Then
		CommonClientServer.SetFormItemProperty(
			Form.Items,
			"Delete",
			"Enabled",
			False);
		CommonClientServer.SetFormItemProperty(
			Form.Items,
			"DeleteContext",
			"Enabled",
			False);
	ElsIf ThisIsSecuringSigning And Not CurrentData.Unavailable Then
		CommonClientServer.SetFormItemProperty(
			Form.Items,
			"Delete",
			"Enabled",
			True);
		CommonClientServer.SetFormItemProperty(
			Form.Items,
			"DeleteContext",
			"Enabled",
			True);
	EndIf;
	
	If Not CurrentData.ThisIsAStep And Not ThisIsSecuringSigning Then
		Form.Items.LinePresentation.ReadOnly = Form.Items.LinePresentation.ReadOnly
			Or CurrentData.IsProtected And Not YouCanChangeProtected;
	ElsIf ThisIsSecuringSigning And Not CurrentData.Unavailable Then
		Form.Items.LinePresentation.ReadOnly = False;
	EndIf;
	
EndProcedure

// Determines whether the Cur executor is Responsible.
//
// Parameters:
//   PerformerRow - ValueTableRow, FormDataCollectionItem - a row in the Performers table.
//
// Returns:
//   Boolean - returns True if the Cur line contains the Responsible field and it has the value True.
//
Function ThisIsLineOfResponsible(PerformerRow)
	
	Return ObjectPropertyValue(PerformerRow, "EmployeeResponsible", False);
	
EndFunction

// Determines whether the Cur executor is a Reviewer.
//
// Parameters:
//   PerformerRow - ValueTableRow, FormDataCollectionItem - a row in the Performers table.
//
// Returns:
//   Boolean - returns True if there is a Function field in the Cur line and it has the value Considering.
//
Function ThisIsLineOfReviewer(PerformerRow)
	
	Return ObjectPropertyValue(PerformerRow, "Function", Undefined) = "ReviewingPerson";
	
EndFunction

#EndRegion

#Region CommunicationRules

// Generates a description of the context element of the object-type communication rules.
//
// Parameters:
//   Source - ClientApplicationForm - The source to get the element description from.
//   AttributeName - String - The name of the source Attribute to get a description of.
//
// Returns:
//   Undefined, See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
Function ValueOfObjectTypeContextElement(Source, AttributeName = "")
	
	ElementValue = Undefined;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Source, AttributeName + "ID")
			And ValueIsFilled(Source[AttributeName + "ID"]) Then
		
		Description = "";
		If ValueIsFilled(AttributeName)
				And CommonClientServer.HasAttributeOrObjectProperty(Source, AttributeName)
				And ValueIsFilled(Source[AttributeName]) Then
			Description = Source[AttributeName];
		EndIf;
		
		ElementValue = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			Source[AttributeName + "ID"],
			Source[AttributeName + "Type"],
			Description);
		
	EndIf;
	
	Return ElementValue;
	
EndFunction

#EndRegion

// The notification handler that is called after the user enters the page number.
//
// Parameters:
//   NewPage - Number - the page number entered by the user.
//   Parameters - Structure:
//     * CurrentPage - Number - the Cur page number.
//     * TotalPages - Number - maximum number of pages.
//     * CallbackDescription - CallbackDescription - description of the notification where the number of the selected page will be sent.
//
Procedure EnteringPageManuallyEnding(NewPage, Parameters) Export
	
	If NewPage = Undefined Then
		Return;
	EndIf;
	
	If NewPage < 1 Then
		NewPage = 1;
	ElsIf NewPage > Parameters.TotalPages Then
		NewPage = Parameters.TotalPages;
	EndIf;
	
	If NewPage = Parameters.CurrentPage Then
		Return;
	EndIf;
	
	RunCallback(Parameters.CallbackDescription, NewPage);
	
EndProcedure

Function AllSubordinatesAreExecuted(ProcessingTreeString)
	
	AllSubordinatesAreExecuted = False;
	
	If ValueIsFilled(ProcessingTreeString.Result) Then
		AllSubordinatesAreExecuted = True;
		CheckAllSubordinatesAreCompleted(ProcessingTreeString, AllSubordinatesAreExecuted);
	EndIf;
	
	Return AllSubordinatesAreExecuted;
	
EndFunction

// Processing the selection of a value in a table from a list.
//
// Parameters:
//   Result - Structure:
//     * AttributePresentation - String
//     * AttributeID - String
//     * AttributeType - String
//   Parameters - Structure:
//     * CurrentData - FormDataCollectionItem
//     * Attribute - String
//     * OwnerForm - ClientApplicationForm
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

// Processing the selection of a value from a list.
//
// Parameters:
//   Result - Structure:
//     * AttributePresentation - String
//     * AttributeID - String
//     * AttributeType - String
//   Parameters - Structure:
//     * CurrentData - FormDataCollectionItem
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

// Processing employee selection.
//
// Parameters:
//   Result - Structure:
//     * Attribute - String
//     * AttributePresentation - String
//     * AttributeID - String
//     * AttributeType - String
//   Parameters - Structure:
//     * Attribute - String - The name of the Form Attribute that the selected employee will be placed in.
//     * OwnerForm - ClientApplicationForm - The Form from which the employee selection Form is called.
//     * FillInPresentation - Boolean - indicates whether the employee's Presentation needs to be completed.
//
Procedure SelectEmployeeFromDepartmentTreeCompletion(Result, Parameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		Parameters.OwnerForm[Parameters.Attribute] = Result.Attribute;
		Parameters.OwnerForm[Parameters.Attribute + "ID"] = Result.AttributeID;
		Parameters.OwnerForm[Parameters.Attribute + "Type"] = Result.AttributeType;
		If Parameters.FillInPresentation Then
			Parameters.OwnerForm[Parameters.Attribute + "Presentation"] = Result.AttributePresentation;
		EndIf;
		Parameters.OwnerForm.Modified = True;
	EndIf;
	
EndProcedure

Function FileDataToSave(ApplicationTreeLine, Form)
	
	If ApplicationTreeLine.ApplicationType = "DMIncomingElectronicDocument"
			Or ApplicationTreeLine.ApplicationType = "DMOutgoingElectronicDocument" Then
		Extension = "xml";
	Else
		Extension = ApplicationTreeLine.Extension;
	EndIf;
	
	FileData = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		ApplicationTreeLine.Application,
		ApplicationTreeLine.ApplicationID,
		ApplicationTreeLine.ApplicationType,
		Extension,
		ApplicationTreeLine.FileRoleID);
	
	If ApplicationTreeLine.ApplicationType = "DMIncomingElectronicDocument"
			Or ApplicationTreeLine.ApplicationType = "DMOutgoingElectronicDocument" Then
		FileData.RefToBinaryFileData =
			IntegrationWith1CDocumentManagement3ServerCall.GetDocumentFileAndPutItInRepository(
				ApplicationTreeLine.ApplicationID,
				ApplicationTreeLine.ApplicationType,
				Form.UUID,
				Extension);
	EndIf;
	
	Return FileData;
	
EndFunction

Function AddingHeader(ElementField)
	
	BeginningOfAddOn = StrFind(ElementField.Title, "(");
	If BeginningOfAddOn > 0 Then
		AddingHeader = Mid(ElementField.Title, BeginningOfAddOn, StrLen(ElementField.Title));
	EndIf;
	
	Return AddingHeader;
	
EndFunction

// Determines whether interactive file modification is available.
//
// Parameters:
//   ApplicationType - String
//
// Returns:
//   Boolean - interactive file modification is available.
//
Function InteractiveFileModificationIsAvailable(ApplicationType)
	
	InteractiveFileModificationIsAvailable = IntegrationWith1CDocumentManagement3ClientCached.IsDocumentBefore3(ApplicationType)
		Or ApplicationType = "DMCorrespondent"
		Or ApplicationType = "DMMeeting";
	
	Return InteractiveFileModificationIsAvailable;
	
EndFunction

Function ThereAreSubtasks(ProcessingTreeString)
	
	ThereAreSubtasks = False;
	
	For Each CurActionString In ProcessingTreeString.GetItems() Do
		If CurActionString.ThisIsSubtask Then
			ThereAreSubtasks = True;
			Break;
		EndIf;
	EndDo;
	
	Return ThereAreSubtasks;
	
EndFunction

// The notification handler that is called after entering a special description.
//
// Parameters:
//   NameAndDescription - Structure:
//     * Description - String
//     * LongDesc - String
//     * DescriptionIsSpecial - String
//   NotificationParameters - Structure:
//     * Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//     * CurrentData - FormDataTreeItem
//
Procedure CompleteConfigurationOfSpecialNameAndDescriptionOfArtist(NameAndDescription, NotificationParameters) Export
	
	If NameAndDescription = Undefined Then
		Return;
	EndIf;
	
	NotificationParameters.CurrentData.ThereIsSpecialNameDescription =
		ValueIsFilled(NameAndDescription.Description)
			Or ValueIsFilled(NameAndDescription.LongDesc)
			Or ValueIsFilled(NameAndDescription.DescriptionIsSpecial);
	
	If NotificationParameters.ChangeTaskName Then
		NotificationParameters.CurrentData.TaskDescription = NameAndDescription.Description;
	EndIf;
	NameAndDescription.Delete("Description");
	
	FillPropertyValues(NotificationParameters.CurrentData, NameAndDescription);
	
	NotificationParameters.Form.Modified = True;
	
EndProcedure

Procedure FillInStateOfTreeRows(TreeType, TreeRows, FormTable, StateIsDeployed)
	
	For Each TreeRow In TreeRows Do
		LineIsExpanded = FormTable.Expanded(TreeRow.GetID());
		StateIsDeployed[TreeRowKey(TreeType, TreeRow)] = LineIsExpanded;
		FillInStateOfTreeRows(TreeType, TreeRow.GetItems(), FormTable, StateIsDeployed);
	EndDo;
	
EndProcedure

// Generates a string key of the processing tree.
//
// Parameters:
//   ProcessingTreeString - Structure:
//     * ActionID - String
//     * TaskActionID - String
//     * Id - UUID
//
// Returns:
//   String
//
Function ProcessingTreeRowKey(ProcessingTreeString)
	
	Return StrTemplate("%1_%2_%3_%4_%5_%6",
		ProcessingTreeString.ActionID,
		ProcessingTreeString.TaskActionID,
		ProcessingTreeString.ActionKindID,
		?(ProcessingTreeString.ThisIsParticipant, String(ProcessingTreeString.Id), ""),
		ProcessingTreeString.Presentation,
		ProcessingTreeLineNeedsToBeExpanded(ProcessingTreeString));
	
EndFunction

// Generates the application tree row key.
//
// Parameters:
//   ApplicationTreeLine - Structure:
//     * ApplicationPresentation - String
//     * ApplicationID - String
//     * ApplicationType - String
//     * RowType - String
//     * FileRoleID - String
//
// Returns:
//   String
//
Function ApplicationTreeRowKey(ApplicationTreeLine)
	
	If ApplicationTreeLine <> Undefined Then
		If ApplicationTreeLine.RowType = "filerole" Then
			Return StrTemplate("%1_%2",
				ApplicationTreeLine.RowType,
				ApplicationTreeLine.FileRoleID);
		Else
			Return StrTemplate("%1_%2_%3",
				ApplicationTreeLine.ApplicationPresentation,
				ApplicationTreeLine.ApplicationID,
				ApplicationTreeLine.ApplicationType);
		EndIf;
	EndIf;
	
EndFunction

// Generates a string key of the SUB-asset tree CODE.
//
// Parameters:
//   TreeStringSUBAssetsAreCODE - Structure:
//     * WebServiceAddress - String
//     * Running - Number
//     * NodeID - String
//     * NodeName - String
//     * PresentationOfNode - String
//     * CentralNode - Boolean
//
// Returns:
//   String
//
Function KeyOfTreeStringSUBAssetsIsCODE(TreeStringSUBAssetsAreCODE)
	
	Return StrTemplate("%1_%2", TreeStringSUBAssetsAreCODE.NodeName, TreeStringSUBAssetsAreCODE.NodeID);
	
EndFunction

// Continuation of the processing procedure, the command to start processing.
//
// Parameters:
//   Result - Boolean
//   ReferencesArrray - Array of AnyRef
//
Procedure StartProcessingCheckConnectionEnd(Result, ReferencesArrray) Export
	
	If Result = True Then
		// authorization is successful
		StartProcessing(ReferencesArrray);
	EndIf;
	
EndProcedure

// The notification handler after selecting the actual performer.
//
// Parameters:
//   Result - Structure - the selected artist.
//   NotificationParameters - See NotificationParametersAfterPerformingInteractiveActionOnIssue
//
Procedure ProcessExecutionDataAfterSelectingPerformer(Result, NotificationParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		// Go back to the task.
		WhenReturningToTask(NotificationParameters.RepeatedAction.Module);
		Return;
	EndIf;
	
	RequiredInteractiveAction =
		NotificationParameters.RepeatedAction.AdditionalParameters.RequiredInteractiveAction;
	RequiredInteractiveAction.SelectTaskExecutor = True;
	RequiredInteractiveAction.Context = Result;
	
	// Complete the task.
	RunCallback(NotificationParameters.RepeatedAction, NotificationParameters.OperationType);
	
EndProcedure

// The notification handler after changing the process parameters.
//
// Parameters:
//   Result - String - modified action. String Presentation of an XDTO object of the type inheriting DMAction.
//             - DialogReturnCode - if the action was closed without recording.
//   NotificationParameters - See NotificationParametersAfterPerformingInteractiveActionOnIssue
//
Procedure ProcessExecutionDataAfterProcessChanges(Result, NotificationParameters) Export
	
	ResultType = TypeOf(Result);
	
	If Result = Undefined
			Or (ResultType = Type("DialogReturnCode") And Result <> DialogReturnCode.OK) Then
		// Go back to the task.
		WhenReturningToTask(NotificationParameters.RepeatedAction.Module);
		Return;
	EndIf;
	
	RequiredInteractiveAction =
		NotificationParameters.RepeatedAction.AdditionalParameters.RequiredInteractiveAction;
	RequiredInteractiveAction.ChangeProcessParameters = True;
	If ResultType = Type("String") Then
		RequiredInteractiveAction.Context = Result;
	EndIf;
	
	// Complete the task.
	RunCallback(NotificationParameters.RepeatedAction, NotificationParameters.OperationType);
	
EndProcedure

// The notification handler after answering an arbitrary question before completing the task.
//
// Parameters:
//   Response - String - the answer from the user in the question dialog.
//   NotificationParameters - See NotificationParametersAfterPerformingInteractiveActionOnIssue
//
Procedure ProcessExecutionDataAfterAnsweringQuestion(Response, NotificationParameters) Export
	
	RequiredInteractiveAction =
		NotificationParameters.RepeatedAction.AdditionalParameters.RequiredInteractiveAction;
	RequiredInteractiveAction.AskRandomQuestion = True;
	RequiredInteractiveAction.Context = Response;
	
	// Complete the task.
	RunCallback(NotificationParameters.RepeatedAction, NotificationParameters.OperationType);
	
EndProcedure

// The notification handler after answering the question about reaching the cycle limit before completing the task.
//
// Parameters:
//   Response - String - the answer from the user in the question dialog.
//   NotificationParameters - See NotificationParametersAfterPerformingInteractiveActionOnIssue
//
Procedure ProcessExecutionDataAfterAnsweringQuestionAboutCycleLimit(Response, NotificationParameters) Export
	
	RequiredInteractiveAction =
		NotificationParameters.RepeatedAction.AdditionalParameters.RequiredInteractiveAction;
	RequiredInteractiveAction.AskQuestionAboutCycleLimit = True;
	RequiredInteractiveAction.Context = Response;
	
	// Complete the task.
	RunCallback(NotificationParameters.RepeatedAction, NotificationParameters.OperationType);
	
EndProcedure

// Notification handler after signing objects with an electronic signature.
//
// Parameters:
//   Result - Undefined
//   NotificationParameters - See NotificationParametersAfterPerformingInteractiveActionOnIssue
//
Procedure ProcessExecutionDataAfterSigning(Result, NotificationParameters) Export
	
	If Not Result.Success Then
		// Go back to the task.
		WhenReturningToTask(NotificationParameters.RepeatedAction.Module);
		Return;
	EndIf;
	
	RequiredInteractiveAction =
		NotificationParameters.RepeatedAction.AdditionalParameters.RequiredInteractiveAction;
	RequiredInteractiveAction.PerformSigning = True;
	RequiredInteractiveAction.Context = NotificationParameters.InitialContext;
	RequiredInteractiveAction.Context.Insert("DataSet", Result.DataSet);
	
	// Complete the task.
	RunCallback(NotificationParameters.RepeatedAction, NotificationParameters.OperationType);
	
EndProcedure

Procedure ClearParticipantField(CurrentData)
	
	CurrentData.Member = "";
	CurrentData.MemberID = "";
	CurrentData.MemberType = "";
	
	CurrentData.MainAddressingObjectMember = "";
	CurrentData.MainAddressingObjectMemberID = "";
	CurrentData.MainAddressingObjectMemberType = "";
	
	CurrentData.AdditionalAddressingObjectParticipant = "";
	CurrentData.AdditionalAddressingObjectParticipantID = "";
	CurrentData.AdditionalAddressingObjectParticipantType = "";
	
EndProcedure

// Constructor of the parameter structure to start creating a file.
//
// Parameters:
//   ApplicationTreeLine - FormDataTreeItem - the Cur row of the application tree.
//   FormUniqueID - UUID - ID of the calling form.
//   OnlyScannedCopyIsAllowed - Boolean - indicates that the file being added can only be a scanned copy.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters
//
Function FileCreationStartParameters(ApplicationTreeLine, FormUniqueID, OnlyScannedCopyIsAllowed)
	
	FileRoleAndApplication = FileRoleAndApplication(ApplicationTreeLine);
	ParametersForStartOfCreation =
		IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters(
			FileRoleAndApplication.FileRoleID);
	ParametersForStartOfCreation.IsScannedCopy = OnlyScannedCopyIsAllowed;
	ParametersForStartOfCreation.OwnerID = FileRoleAndApplication.Application.ID;
	ParametersForStartOfCreation.OwnerType = FileRoleAndApplication.Application.Type;
	ParametersForStartOfCreation.FormUniqueID = FormUniqueID;
	ParametersForStartOfCreation.OwnerPresentation = FileRoleAndApplication.Application.Presentation;
	ParametersForStartOfCreation.Owner = FileRoleAndApplication.Owner;
	
	Return ParametersForStartOfCreation;
	
EndFunction

// Constructor of the parameter structure of the notification handler that will be called after performing the required
// interactive action on the task.
//
// Returns:
//   Structure:
//     * OperationType - See IntegrationWith1CDocumentManagementCoreClientServer.TypeOfOperationOnTask
//     * RepeatedAction - CallbackDescription - the method that will be called at the End of interactive processing.
//     * InitialContext - Structure, String - arbitrary data transmitted initially.
//
Function NotificationParametersAfterPerformingInteractiveActionOnIssue()
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("OperationType", Undefined);
	NotificationParameters.Insert("RepeatedAction", Undefined);
	NotificationParameters.Insert("InitialContext", Undefined);
	
	Return NotificationParameters;
	
EndFunction

// Displays a question window for the user.
//
// Parameters:
//   QuestionStructure - See IntegrationWith1CDocumentManagement3.StructureOfQuestionToUser
//   CallbackDescriptionOnCompletion - CallbackDescription - contains a description of the procedure that will
//     be called after answering the question.
//
Procedure ShowQuestionBeforeCompletingTask(QuestionStructure, CallbackDescriptionOnCompletion)
	
	DefaultButtonIsSet = ValueIsFilled(QuestionStructure.DefaultButton)
		And (QuestionStructure.Buttons.FindByValue(QuestionStructure.DefaultButton) <> Undefined);
	
	If DefaultButtonIsSet Then
		ShowQueryBox(
			CallbackDescriptionOnCompletion,
			QuestionStructure.Text,
			QuestionStructure.Buttons,,
			QuestionStructure.DefaultButton,
			QuestionStructure.Title);
	Else
		ShowQueryBox(
			CallbackDescriptionOnCompletion,
			QuestionStructure.Text,
			QuestionStructure.Buttons,,,
			QuestionStructure.Title);
	EndIf;
	
EndProcedure

Procedure WhenReturningToTask(Module)
	
	If TypeOf(Module) = Type("ClientApplicationForm") Then
		Module.Items.ResultOfActionInText.ReadOnly = False;
		Module.AttachIdleHandler("SaveActionResult", 0.2, True);
	EndIf;
	
EndProcedure

// Checks the completion of the action by recursively bypassing the action string and subordinates.
//
// Parameters:
//   ActionString - FormDataTreeItem - the action string being checked.
//   AllSubordinatesAreExecuted - Boolean - an implicitly returned value, True if
//     the action and all subordinate strings are executed, and False in the opposite case.
//
Procedure CheckAllSubordinatesAreCompleted(ActionString, AllSubordinatesAreExecuted)
	
	If Not ValueIsFilled(ActionString.Result) Then
		AllSubordinatesAreExecuted = False;
		Return;
	EndIf;
	
	For Each CurActionString In ActionString.GetItems() Do
		CheckAllSubordinatesAreCompleted(CurActionString, AllSubordinatesAreExecuted);
	EndDo;
	
EndProcedure

Procedure ExpandAction(FormTable, ActionString)
	
	// All lines in which the result is not filled are expanded.
	// If there are several stages in action, the completed stages will not be deployed.
	If ThereAreSubtasks(ActionString) Then
		FormTable.Collapse(ActionString.GetID());
	ElsIf AllSubordinatesAreExecuted(ActionString) = False Then
		FormTable.Expand(ActionString.GetID());
	EndIf;
	
	For Each CurActionString In ActionString.GetItems() Do
		ExpandAction(FormTable, CurActionString);
	EndDo;
	
EndProcedure

Procedure ExpandProcessingTree(TreeRows, FormTable)
	
	For Each TreeRow In TreeRows Do
		ExpandAction(FormTable, TreeRow);
	EndDo;
	
EndProcedure

Procedure ExpandApplicationTree(TreeRows, FormTable)
	
	For Each TreeRow In TreeRows Do
		
		FormTable.Expand(TreeRow.GetID());
		
		For Each StringAttachment In TreeRow.GetItems() Do
			NeedToDeploy = True;
			If StringAttachment.RowType = "filerole" And Not StringAttachment.RoleIsMandatory Then
				NeedToDeploy = False;
			EndIf;
			
			If Not NeedToDeploy Then
				Continue;
			EndIf;
			
			FormTable.Expand(StringAttachment.GetID(), True);
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure ExpandTreeOfSUBAssetsCODE(TreeRows, FormTable)
	
	For Each TreeRow In TreeRows Do
		FormTable.Expand(TreeRow.GetID());
		ExpandTreeOfSUBAssetsCODE(TreeRow.GetItems(), FormTable);
	EndDo;
	
EndProcedure

Procedure ExpandTreeRows(TreeType, TreeRows, FormTable, StateIsDeployed, KeyOfCurRowOfTree,
		CurrentTreeRow)
	
	For Each TreeRow In TreeRows Do
		RowKey = TreeRowKey(TreeType, TreeRow);
		
		If StateIsDeployed[RowKey] = True Or StateIsDeployed[RowKey] = Undefined Then
			// Expand new lines and lines that were expanded earlier.
			If TreeType.ThisIsProcessingTree Then
				If ProcessingTreeLineNeedsToBeExpanded(TreeRow) Then
					FormTable.Expand(TreeRow.GetID(), False);
				EndIf;
			Else
				FormTable.Expand(TreeRow.GetID(), False);
			EndIf;
		EndIf;
		If KeyOfCurRowOfTree = RowKey Then
			CurrentTreeRow = TreeRow;
		EndIf;
		
		ExpandTreeRows(
			TreeType,
			TreeRow.GetItems(),
			FormTable,
			StateIsDeployed,
			KeyOfCurRowOfTree,
			CurrentTreeRow);
	EndDo;
	
EndProcedure

Function FileRoleAndApplication(RowData)
	
	Owner = Undefined;
	Application = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM("", "");
	FileRoleID = "";
	
	If RowData.RowType = "file" Then
		
		ParentData = RowData.GetParent();
		If ParentData <> Undefined And ParentData.RowType = "filerole" Then
			FileRoleID = ParentData.FileRoleID;
			ParentData = ParentData.GetParent();
		EndIf;
		
		If ParentData <> Undefined Then
			Owner = ParentData.Ref;
			Application.Description = ParentData.Application;
			Application.ID = ParentData.ApplicationID;
			Application.Type = ParentData.ApplicationType;
			Application.Presentation = ParentData.ApplicationPresentation;
		EndIf;
		
	ElsIf RowData.RowType = "filerole" Then
		
		FileRoleID = RowData.FileRoleID;
		ParentData = RowData.GetParent();
		
		If ParentData <> Undefined Then
			Owner = ParentData.Ref;
			Application.Description = ParentData.Application;
			Application.ID = ParentData.ApplicationID;
			Application.Type = ParentData.ApplicationType;
			Application.Presentation = ParentData.ApplicationPresentation;
		EndIf;
		
	ElsIf RowData.RowType = "application" Then
		
		Owner = RowData.Ref;
		Application.Description = RowData.Application;
		Application.ID = RowData.ApplicationID;
		Application.Type = RowData.ApplicationType;
		Application.Presentation = RowData.ApplicationPresentation;
		
		SubordinateElementsOfApplication = RowData.GetItems();
		If SubordinateElementsOfApplication.Count() > 0 Then
			
			FirstSubordinateElement = SubordinateElementsOfApplication[0];
			If FirstSubordinateElement.RowType = "filerole" Then
				FileRoleID = FirstSubordinateElement.FileRoleID;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	FileRoleAndApplication = New Structure("Owner, Application, FileRoleID", Owner, Application, FileRoleID);
	
	Return FileRoleAndApplication;
	
EndFunction

Function SymbolIsAscending()
	
	Return "↓";
	
EndFunction

Function SymbolIsDecreasing()
	
	Return "↑";
	
EndFunction

Function ProcessingTreeLineNeedsToBeExpanded(ProcessingTreeString)
	
	Expand = False;
	If ThereAreSubtasks(ProcessingTreeString) Then
		Expand = False;
	ElsIf Not AllSubordinatesAreExecuted(ProcessingTreeString) Then
		Expand = True;
	EndIf;
	
	Return Expand;
	
EndFunction

Function ThisIsDisclosedGroup(HTMLElement)
	
	Try
		ThisIsDisclosedGroup = (TypeOf(HTMLElement) = Type("ExternalObject"))
			And (HTMLElement.tagName = "U"
				Or HTMLElement.className = "pointer"
				Or HTMLElement.textContent = NStr("vi = 'Chi tiết nguồn';
													|ru = 'Реквизиты источника';
													|en = 'Source attributes '; fa = 'ویژگی‌های مبدأ';
													|it = 'Requisiti della fonte';
													|pl = 'Dane płatnicze źródła';
													|tr = 'Kaynak öznitelikleri'")
				Or HTMLElement.textContent = NStr("vi = 'Chi tiết đích';
													|ru = 'Реквизиты приемника';
													|en = 'Destination attributes'; fa = 'Destination attributes';
													|it = 'Destination attributes';
													|pl = 'Destination attributes';
													|tr = 'Alıcının öznitelikleri'"));
	Except
		ThisIsDisclosedGroup = False;
	EndTry;
	
	Return ThisIsDisclosedGroup;
	
EndFunction

Function ThisIsFormalizedEDODocument(Extension)
	
	Return (Lower(Extension) = "xml");
	
EndFunction

#EndRegion
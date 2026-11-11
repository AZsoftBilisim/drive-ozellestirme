////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module of integration1sdocumentworkingbazofunctionclientdetermined: client
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called from the forms of the matched objects. It is intended for displaying the approval sheet in cases
// when adding a command to the print submenu is impossible or undesirable, as well as for implementation in configurations
// without the BSP subsystem of print management.
//
// Parameters:
//   SubjectOfApproval - AnyRef - a consistent object.
//   FormOwner - ClientApplicationForm - optional, the form is the source of the command.
//
Procedure ExecutePrintApprovalSheetCommand(SubjectOfApproval, FormOwner = Undefined) Export
	
	
	
EndProcedure

// Called from the processing forms corresponding to the processes, documents and tasks BEFORE. It is intended for processing
// commands added programmatically when calling the Additional Form Processing procedure<...> redefined module.
//
// Parameters:
//   Command - FormCommand - a command called by the user.
//   ThisForm - ClientApplicationForm - the processing form from where the command is called.
//
Procedure ExecuteProgrammaticallyAddedCommand(Command, ThisForm) Export
	
	
	
EndProcedure

// Called before executing the Open Panel processing Command.
// Allows you to override the Form setationintegration1 with Document management.
//
// Parameters:
//   CommandExecuteParameters - Arbitrary - Parameters for executing the Open Panel command.
//   StandardProcessing - Boolean - An implicitly returned value, indicating that the standard
//     Form for customizing Integration and Document management will not be opened.
//
// Example:
//	Standard processing = A lie;
//	Open the form(
//		"Processing.Administrirovaniyabid panel.Form.Customizationintegrationis1sdocumentorecountable",
//		New Structure,
//		Command execution parameterization.Source,
//		"Processing.Administrirovaniyabid panel.Form.customizationintegrationis1cdocumentoredefinable"
//			+ ?(Command execution parameter.The window = It is uncertain,".Separate window", ""),
//		Command execution parameter.Window);
//
Procedure OpenBidAdministrationPanel(CommandExecuteParameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
	OpenForm(
		"DataProcessor.AdministrationPanelDMIL.Form.IntegrationWith1CDocumentManagementSettingOverridable",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.AdministrationPanelDMIL.Form.IntegrationWith1CDocumentManagementSettingOverridable"
			+ ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

// Called before creating a business process and allows you to refuse to run.
//
// Parameters:
//   SubjectOf - AnyRef - a reference to the object of the integrated system, or
//           - Structure - description of the object BEFORE, with properties:
//               ID - ID String;
//               type - String - type;
//               name - String - name of the item.
//   Cancel - Boolean - when set to True, the process will not be started.
//
// Example:
//	If the item type is (Item) = Type("Document link.Buyer's _democorder") Then
//		Message text = "";
//		If Not selling the Server call.The order is filled in correctly (Subject, message text) Then
//			Rejection = Truth;
//			Show a warning(, Message text);
//		The end if;
//	The end if;
//
Procedure BeforeCreatingBusinessProcess(SubjectOf, Cancel) Export
	
	
	
EndProcedure

// Called when the state of the agreement changes to BEFORE. It is intended to change the shape
// of the agreed object, if the modification of the form module itself is undesirable.
//
// Parameters:
//   SubjectOfApproval - AnyRef - a consistent object.
//   Source - ClientApplicationForm - the form is the source of the call.
//   State - EnumRef.ApprovalStatesIn1CDocumentManagement
//   CallingFromObjectForm - Boolean - True if the state change is caused by the user from the object form.
//
Procedure WhenApprovalStateChanges(SubjectOfApproval, Source, State, CallingFromObjectForm) Export
	
	
	
EndProcedure

// Allows you to hide the "No longer show" checkbox in the dialog with the user.
//
// Parameters:
//   PromptDontAskAgain - Boolean - implicitly returned value, if True, then in the question window
//     A checkbox with the same name will be available.
//   QueryText - String - the text of the question to the user.
//   ObjectKey - String - the key of the configuration object that stores the need to show the question to the user.
//   SettingsKey - String - the key of the saved setting that stores the need to show the question to the user.
//
// Example:
//	If the Setting key is = "Set the File Transfer request to" Then
//		Suggest More questions = False;
//	The end if;
//
Procedure WhenDeterminingNeedToSuggestNoLongerAskingThisQuestion(PromptDontAskAgain,
		QueryText, ObjectKey, SettingsKey) Export
	
	If SettingsKey = "AskQuestionAboutTransferringFilesToDM" Then
		PromptDontAskAgain = False;
	EndIf;
	
EndProcedure

// Returns the previously saved indication of the completed display of the authorization window.
//
// Parameters:
//   AuthorizationOffered - Boolean - implicitly returned value,
//     True if authorization was offered in this session, and False otherwise.
//
Procedure WhenDefiningAuthorizationOffer(AuthorizationOffered) Export
	
	
	
EndProcedure

// Allows you to redefine the decomposition of the full file name into components.
//
// Parameters:
//   FileNameStructure - Structure:
//     * FullName - String - Contains the full path to the file, i.e. fully corresponds to the input
//         parameter of the full file name.
//     * Path - String - Contains the path to the directory where the file is located.
//     * Name - String - Contains the file name with the extension, without the path to the file.
//     * Extension - String - Contains the file extension.
//     * BaseName - String - Contains a file name with no extension and no path to the file.
//
Procedure WhenDecomposingFullFileName(FileNameStructure) Export
	
	
	
EndProcedure

// Called when saving an array of user settings, an array of structures.
//
// Parameters:
//   StructuresArray - Array - array of structures with the fields "Object", "Setting", "Value".
//   NeedToRefreshCachedValues - Boolean - the reused values need to be updated.
//   StandardProcessing - Boolean - an implicitly returned value, a sign that standard
//     processing will not be called.
//
Procedure WhenSavingUserSettings(StructuresArray, NeedToRefreshCachedValues,
		StandardProcessing) Export
	
	
	
EndProcedure

// Remembers the fact that the authorization window is displayed so as not to bother the user within the session anymore.
//
Procedure WhenSavingAuthorizationOffer() Export
	
	
	
EndProcedure

// Sets the selection when selecting a DO object associated with an IP object.
//
// Parameters:
//   ObjectToLink - AnyRef - the IP object associated with the object BEFORE.
//   ObjectType1CDocumentManagement - String - the type of the selected object is UP TO.
//   Filter - Structure, Undefined - an implicitly returned value, a selection imposed before
//     being presented to the user.
//
// Example:
//	If the type is a (Linkable object) = Type("Reference link.Counterparties")
//			And Document Flow ObjectType = "DMCorrespondent" Then
//		Session valuesrequestions = General purpose of Server callsreferences.Values of the object's requestionsobject(
//			Linkable object, "Name, TIN, CHECKPOINT");
//		If the value is filled in (Session values.INN) Then
//			Selection = New Structure;
//			Selection.Insert("inn", session valuesreferences.INN);
//			Selection.Insert("kpp", session values.CHECKPOINT);
//		And if the value is filled in(Session valuesreferences.Name) Then
//			Selection = New Structure;
//			Selection.Insert("name", session valuesreferences.Name);
//		The end if;
//	The end if;
//
Procedure WhenSettingSelectionWhenSelectingRelatedObject(ObjectToLink, ObjectType1CDocumentManagement, Filter) Export
	
	If TypeOf(ObjectToLink) = Type("CatalogRef.Counterparties")
			And ObjectType1CDocumentManagement = "DMCorrespondent" Then
		
		AttributesValues = GeneralPurposeTMServerCall.ObjectAttributesValues(
			ObjectToLink, "Description, TIN, CRTR");
		
		If ValueIsFilled(AttributesValues.TIN) Then
			Filter = New Structure;
			Filter.Insert("inn", AttributesValues.TIN);
			Filter.Insert("kpp", AttributesValues.CRTR);
			
		ElsIf ValueIsFilled(AttributesValues.Description) Then
			Filter = New Structure;
			Filter.Insert("name", AttributesValues.Description);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
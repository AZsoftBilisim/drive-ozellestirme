////////////////////////////////////////////////////////////////////////////////
//THE MODULE CONTAINS PROCEDURES AND FUNCTIONS FOR WORKING WITH CONTEXTUAL REPORTS USING THE SCD
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// The function processes the transcript in the report displayed on the form. If the decryption involves opening a value, then
// further processing in the form does not need to be done.if you need to generate a decryption report, the function returns a description of the decryption
// that needs to be passed to the corresponding server function.
//
// Parameters:
//		Form - ClientApplicationForm - the form where the report is located
//		FormAttributeName - String - form details associated with the report
//		DetailsID - DataCompositionDetailsID - parameter of the decryption Processing event
//		StandardProcessing - Boolean - parameter of the decryption Processing event
//		DetailsParameters - Structure - contains additional decryption parameters:
//				*ReportMenu - Array - an array whose values are of the Structure type and describe reports that can be decrypted
//				*ActionMenu - Array - an array whose values are of the Structure type and describe actions that can be performed
//
Procedure ProcessDecryption(Form, FormAttributeName, DetailsID, StandardProcessing, DetailsParameters = Undefined) Export
	
	StandardProcessing = False;
	
	AdditionalMenuOptions = AdditionalDecryptionMenuOptions(
		Form["DetailsDataAddress" + FormAttributeName],
		DetailsParameters,
		DetailsID);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("Form", Form);
	HandlerParameters.Insert("FormAttributeName", FormAttributeName);
	HandlerParameters.Insert("DetailsID", DetailsID);
	
	ShowActionSelectionWhenDecrypting(
			AdditionalMenuOptions, 
			DetailsID, 
			Form["DetailsDataAddress" + FormAttributeName], 
			Form["SchemaURL" + FormAttributeName],
			Undefined,
			"ProcessDecryptionCompletion",
			HandlerParameters);
	
EndProcedure

// The procedure works out the transcript in the report by forming the action menu and working out the selected action.
//
// Parameters:
//		Form - Form - the form where the report is located
//		DetailsParameters - Structure - Decryption Processing event parameter
//				The menu of reports is an array - an array whose values are of the Structure type and describe the receiver report
//				Action Menu - Array - an array whose values are of the Structure type and describe the type of action being performed
//				Decryption - Arbitrary - for the decryption value
//						, see the events for "Expanding the form field for a tabular document field" in the help.
//		StandardProcessing - Boolean - parameter of the decryption Processing event.
//
Procedure DecryptionProcessingWithAdditionalMenu(Form, DetailsParameters, StandardProcessing) Export
	
	DetailsID = DetailsParameters.Details;
	
	AdditionalMenuOptions = AdditionalDecryptionMenuOptions(
		Form.ReportDetailsData,
		DetailsParameters,
		DetailsID);
	
	
	If AdditionalMenuOptions = Undefined Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ShowActionSelectionWhenDecrypting(
			AdditionalMenuOptions, 
			DetailsID, 
			Form.ReportDetailsData, 
			Form.Report,
			Form.ReportSettings.FullName,
			"DecryptionProcessingWithAdditionalMenuCompletion",
			Undefined);
	
EndProcedure

#EndRegion

#Region Internal

Procedure ProcessDecryptionCompletion(ChosenAction, ChosenActionParameter, AdditionalParameters) Export
	
	If ProcessNonStandardDecryption(ChosenAction, AdditionalParameters) Then
		Return;
	EndIf; 
	
	DescriptionOfDecryptionProcessing = Undefined;
	If ChosenActionParameter <> Undefined Then
		If ChosenAction = DataCompositionDetailsProcessingAction.OpenValue Then
			ShowValue(,ChosenActionParameter);
		Else
			DescriptionOfDecryptionProcessing = New DataCompositionDetailsProcessDescription(
				AdditionalParameters.DetailsData,
				AdditionalParameters.HandlerParameters.DetailsID,
				ChosenActionParameter);
		EndIf;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("DescriptionOfDecryptionProcessing", DescriptionOfDecryptionProcessing);
	Parameters.Insert("FormAttributeName", AdditionalParameters.HandlerParameters.FormAttributeName);
	Notify("ProcessDecryption", Parameters); 
	
EndProcedure

Procedure DecryptionProcessingWithAdditionalMenuCompletion(ChosenAction, ChosenActionParameter, AdditionalParameters) Export 
	
	If ProcessNonStandardDecryption(ChosenAction, AdditionalParameters) Then
		Return;
	EndIf;
	
	If ChosenActionParameter <> Undefined Then
		
		If ChosenAction = DataCompositionDetailsProcessingAction.OpenValue Then
			
			ShowValue(,ChosenActionParameter);
			
		ElsIf ChosenAction <> DataCompositionDetailsProcessingAction.None Then
			
			DescriptionOfDecryptionProcessing = New DataCompositionDetailsProcessDescription(
				AdditionalParameters.DetailsData,
				AdditionalParameters.Details,
				ChosenActionParameter);
			
			FormParameters = New Structure;
			FormParameters.Insert("GenerateOnOpen", True);
			FormParameters.Insert("PurposeUseKey", AdditionalParameters.Details);
			FormParameters.Insert("Details", DescriptionOfDecryptionProcessing);
			
			OpenForm(AdditionalParameters.ObjectKey + ".Form", FormParameters);
			
		EndIf;
	
	EndIf; 
	
EndProcedure

#EndRegion 

#Region Private

Procedure ShowActionSelectionWhenDecrypting(AdditionalMenuOptions, Details, DetailsData, SchemaURL, ObjectKey, HandlerName, HandlerParameters)
	
	AdditionalMenu = Undefined;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Details", Details);
	AdditionalParameters.Insert("DetailsData", DetailsData);
	AdditionalParameters.Insert("SchemaURL", SchemaURL);
	AdditionalParameters.Insert("ObjectKey", ObjectKey);
	AdditionalParameters.Insert("HandlerParameters", HandlerParameters);
	
	If AdditionalMenuOptions <> Undefined Then
		AdditionalParameters.Insert("ActionMenu", AdditionalMenuOptions.ActionMenu);
		AdditionalParameters.Insert("ReportMenu", AdditionalMenuOptions.ReportMenu);
		AdditionalParameters.Insert("ExplanationFormParameters", AdditionalMenuOptions.ExplanationFormParameters);
		AdditionalParameters.Insert("Action_Parameters", AdditionalMenuOptions.Action_Parameters);
		AdditionalParameters.Insert("ReportsParameters", AdditionalMenuOptions.ReportsParameters);
		AdditionalMenu = AdditionalMenuOptions.AdditionalMenu;
	EndIf; 
	
	CallbackDescription = New CallbackDescription(HandlerName, ThisObject, AdditionalParameters);
	
	DetailProcessing = New DataCompositionDetailsProcess(
		DetailsData, 
		New DataCompositionAvailableSettingsSource(SchemaURL));
	
	DetailProcessing.ShowActionChoice(
		CallbackDescription,
		Details,,
		AdditionalMenu);

EndProcedure

Function AdditionalDecryptionMenuOptions(DetailsDataAddress, DetailsParameters, Details)

	If DetailsParameters = Undefined Then
		Return Undefined;
	EndIf;
	
	// We will get all the decryption fields and parameters
	ExplanationFormParameters = ExplanationFormParameters(DetailsDataAddress, DetailsParameters, Details);
	
	// Menu formation
	AdditionalMenu = New ValueList;
	
	ReportsParameters = New Map;
	Action_Parameters = New Map;
	
	// Menu - Decrypt Report
	ReportMenu = New ValueList;
	If DetailsParameters.Property("ReportMenu") And DetailsParameters.ReportMenu.Count() <> 0 Then
		For Each ReportParameters In DetailsParameters.ReportMenu Do
			If ThereAreNecessaryParametersAndValues(ReportParameters, ExplanationFormParameters)
				And ThereAreSufficientParametersAndValues(ReportParameters, ExplanationFormParameters) Then
				ReportMenu.Add(ReportParameters.Name, ReportParameters["Title"]);
				ReportsParameters.Insert(ReportParameters.Name, ReportParameters);
			EndIf; 
		EndDo;
	EndIf;
	If ReportMenu.Count() <> 0 Then
		AdditionalMenu.Add(ReportMenu, NStr("vi = 'Giải mã với một báo cáo khác';
											|ru = 'Расшифровать другим отчетом';
											|en = 'Drill down using another report'; fa = 'Drill down using another report';
											|it = 'Decifrare un altro rapporto';
											|pl = 'Rozszyfruj przez inny raport';
											|tr = 'Diğer raporla detaylandır'"));
	EndIf; 
	
	// Menu - Go to
	ActionMenu = New ValueList;
	If DetailsParameters.Property("ActionMenu") And DetailsParameters.ActionMenu.Count() <> 0 Then
		For Each ActionParameters In DetailsParameters.ActionMenu Do
			If ThereAreNecessaryParametersAndValues(ActionParameters, ExplanationFormParameters) Then
				ActionMenu.Add(ActionParameters.Name, ActionParameters["Title"]);
				Action_Parameters.Insert(ActionParameters.Name, ActionParameters);
			EndIf; 
		EndDo;
	EndIf;
	If ActionMenu.Count() <> 0 Then
		AdditionalMenu.Add(ActionMenu, NStr("vi = 'Chuyển đến';
											|ru = 'Перейти';
											|en = 'Navigate'; fa = 'پیمایش';
											|it = 'Vai a';
											|pl = 'Navigate';
											|tr = 'Git'"));
	EndIf; 

	If AdditionalMenu.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	AdditionalMenuOptions = New Structure;
	AdditionalMenuOptions.Insert("AdditionalMenu", AdditionalMenu);
	AdditionalMenuOptions.Insert("ReportsParameters", ReportsParameters);
	AdditionalMenuOptions.Insert("Action_Parameters", Action_Parameters);
	AdditionalMenuOptions.Insert("ReportMenu", ReportMenu);
	AdditionalMenuOptions.Insert("ActionMenu", ActionMenu);
	AdditionalMenuOptions.Insert("ExplanationFormParameters", ExplanationFormParameters);
	
	Return AdditionalMenuOptions;
	
EndFunction

Function ExplanationFormParameters(DetailsDataAddress, DetailsParameters, Details)
	
	ParametersList = New Array;
	DecryptionFields = New Array;
	
	ListOfSources = New Array;
	ListOfSources.Add("ReportMenu");
	ListOfSources.Add("ActionMenu");
	
	For Each SourceName In ListOfSources Do
		If DetailsParameters.Property(SourceName) And DetailsParameters[SourceName].Count() <> 0 Then
			For Each SourceParameters In DetailsParameters[SourceName] Do
				If SourceParameters.Property("DecryptionFields") Then
					For Each FieldName In SourceParameters.DecryptionFields Do
						If DecryptionFields.Find(FieldName) = Undefined Then
							DecryptionFields.Add(FieldName);
						EndIf;
					EndDo; 
				EndIf;
				If SourceParameters.Property("ParametersList") Then
					For Each ParameterName In SourceParameters.ParametersList Do
						If ParametersList.Find(ParameterName) = Undefined Then
							ParametersList.Add(ParameterName);
						EndIf;
					EndDo; 
				EndIf;
			EndDo;
		EndIf;
	EndDo; 
	
	If ParametersList.Count() <> 0 Or DecryptionFields.Count() <> 0 Then
		ExplanationFormParameters = DataCompositionServerCall.ExplanationFormParameters(
			Details,
			DetailsDataAddress,
			ParametersList,
			DecryptionFields);
	Else
		ExplanationFormParameters = Undefined;
	EndIf;

	Return ExplanationFormParameters;
	
EndFunction

Function ProcessNonStandardDecryption(ChosenAction, AdditionalParameters)

	ActionMenu = Undefined;
	ReportMenu = Undefined;
	If AdditionalParameters.Property("ActionMenu") Then
		ActionMenu = AdditionalParameters.ActionMenu;
	EndIf; 
	If AdditionalParameters.Property("ReportMenu") Then
		ReportMenu = AdditionalParameters.ReportMenu;
	EndIf; 
	
	If ActionMenu = Undefined And ReportMenu = Undefined Then
		Return False;
	EndIf;
	
	ExplanationFormParameters = AdditionalParameters.ExplanationFormParameters;
	Action_Parameters = AdditionalParameters.Action_Parameters;
	ReportsParameters = AdditionalParameters.ReportsParameters;
	
	If ReportMenu.FindByValue(ChosenAction) <> Undefined Then
		
		ReportParameters = ReportsParameters.Get(ChosenAction);
		
		FormParameters = New Structure;
		If ReportParameters.Property("DetailsMode") Then
			FormParameters.Insert("DetailsMode", ReportParameters.DetailsMode);
		EndIf;
		FormParameters.Insert("UserSettingsKey", ChosenAction);
		FormParameters.Insert("GenerateOnOpen", True);
		FormParameters.Insert("PurposeUseKey", ChosenAction + String(New UUID));
		FormParameters.Insert("VariantKey", ChosenAction);
		FormParameters.Insert("Filter", ExplanationFormParameters);
		
		// Transfer of selections supported by the source and receiver
		If ExplanationFormParameters.Property("Filter") Then
			ParametersOfDecryptionForm = ExplanationFormParameters.Filter; // DataCompositionFilter - 
			For Each Filter In ParametersOfDecryptionForm.Items Do
				// Extended selections can only be in the "root" of the collection, not in the group
				If Not TypeOf(Filter) = Type("DataCompositionFilterItem") Then
					Continue;
				EndIf;
				
				SelectionKey = StrReplace(String(Filter.LeftValue), ".", "_");
				If ReportParameters.DecryptionFields.Find(SelectionKey) <> Undefined
					And Filter.Use Then
					SelectionData_ = New Structure("ComparisonType, RightValue");
					FillPropertyValues(SelectionData_, Filter);
					ExplanationFormParameters.Insert(SelectionKey, SelectionData_);
				EndIf;
			EndDo;
		EndIf;
		FormParameters.Filter.Delete("Filter");
		
		If ReportParameters.Property("ReplacingParameters") Then
			For Each KeyAndValueOfParameterReplacement In ReportParameters.ReplacingParameters Do
				KeyOfSelectionBeingDeleted = "";
				KeyForDesiredParameterSelection = KeyAndValueOfParameterReplacement.Key;
				KeyOfSelectionTargetParameter = KeyAndValueOfParameterReplacement.Value;
				
				// Direct search for receiver form parameters by key
				If ExplanationFormParameters.Property(KeyForDesiredParameterSelection) Then
					
					If TypeOf(KeyOfSelectionTargetParameter) = Type("String") Then
						FormParameters.Filter.Insert(KeyOfSelectionTargetParameter, ExplanationFormParameters[KeyForDesiredParameterSelection]);
						KeyOfSelectionBeingDeleted = KeyForDesiredParameterSelection;
						
					ElsIf TypeOf(KeyOfSelectionTargetParameter) = Type("Map") Then
						ReplacementParameters_ = KeyOfSelectionTargetParameter;
						FoundReplacementParameters = ReplacementParameters_.Get(ExplanationFormParameters[KeyForDesiredParameterSelection]);
						
						If FoundReplacementParameters <> Undefined Then
							For Each FoundReplacementParameter In FoundReplacementParameters Do
								FormParameters.Filter.Insert(FoundReplacementParameter.Key, FoundReplacementParameter.Value);
							EndDo;
						EndIf;
						KeyOfSelectionBeingDeleted = KeyForDesiredParameterSelection;
						
					ElsIf TypeOf(KeyOfSelectionTargetParameter) = Type("Undefined") Then
						KeyOfSelectionBeingDeleted = KeyForDesiredParameterSelection;
							
					EndIf;
				EndIf;
				
				If ValueIsFilled(KeyOfSelectionBeingDeleted) Then
					FormParameters.Filter.Delete(KeyOfSelectionBeingDeleted);
				EndIf;
				
				// Search for parameters requiring replacement - fields "through the dot"
				For Each DecryptionFormParameter In ExplanationFormParameters Do 
					If StrFind(DecryptionFormParameter.Key, KeyForDesiredParameterSelection + "_") > 0 Then
						FormParameters.Filter.Insert(StrReplace(DecryptionFormParameter.Key, KeyForDesiredParameterSelection + "_", KeyOfSelectionTargetParameter + "_"), DecryptionFormParameter.Value);
						KeyOfSelectionBeingDeleted = DecryptionFormParameter.Key;
					EndIf;
				EndDo;
				
				If ValueIsFilled(KeyOfSelectionBeingDeleted) Then
					FormParameters.Filter.Delete(KeyOfSelectionBeingDeleted);
				EndIf;
			EndDo; 
		EndIf; 
		
		If ReportParameters.Property("FixedParameters") Then
			For Each FixedParameter In ReportParameters.FixedParameters Do
				FormParameters.Filter.Insert(FixedParameter.Key, FixedParameter.Value);
			EndDo;
		EndIf;
				
		OpenForm(ReportParameters.ReportName + ".Form", FormParameters);
		
		Return True;
		
	ElsIf ActionMenu.FindByValue(ChosenAction) <> Undefined Then
		
		ActionParameters = Action_Parameters.Get(ChosenAction);
		
		If ActionParameters.Property("Action") Then
			ExecuteAction = ActionParameters["Action"];
		Else
			ExecuteAction = ChosenAction;
		EndIf;	
		
		If ExecuteAction = "OpenForm" Then
			If ActionParameters.Property("FormParameters") Then
				
				FormParameters = ActionParameters.FormParameters;
				FillPropertyValues(FormParameters, ExplanationFormParameters);
				If ActionParameters.Property("ReplacingParameters") Then
					For Each KeyAndValueOfParameterReplacement In ActionParameters.ReplacingParameters Do
						If ExplanationFormParameters.Property(KeyAndValueOfParameterReplacement.Key) Then
							FormParameters.Insert(KeyAndValueOfParameterReplacement.Value, ExplanationFormParameters[KeyAndValueOfParameterReplacement.Key]);
						EndIf;
					EndDo;
				EndIf; 
				
			Else
				FormParameters = Undefined;
			EndIf;
			
			OpenForm(ActionParameters.FormName, FormParameters);
		Else
			CommonModuleName = ActionParameters.CommonModuleName;
			CommonClient.CommonModule(CommonModuleName).PerformDecryptionAction(ActionParameters, ExplanationFormParameters);
		EndIf; 
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

Function ThereAreNecessaryParametersAndValues(MenuOptions, ExplanationFormParameters)

	If Not MenuOptions.Property("RequiredParameters") Then
		Return True;
	EndIf;
	
	If ExplanationFormParameters = Undefined Then
		Return False;
	EndIf; 
	
	RequiredParameters = MenuOptions.RequiredParameters;
	For Each KeyAndValue In RequiredParameters Do
		If Not ExplanationFormParameters.Property(KeyAndValue.Key) Then
			Return False;
		Else
			If KeyAndValue.Value <> Undefined
				And KeyAndValue.Value.Find(ExplanationFormParameters[KeyAndValue.Key]) = Undefined Then
				Return False;
			EndIf;
		EndIf; 
	EndDo; 
	
	Return True;

EndFunction
 
Function ThereAreSufficientParametersAndValues(MenuOptions, ExplanationFormParameters)
	If Not MenuOptions.Property("SufficientParameters") Then
		Return True;
	EndIf;
	
	If ExplanationFormParameters = Undefined Then
		Return False;
	EndIf; 
	
	SufficientParameters = MenuOptions.SufficientParameters;
	ThereAreSufficientParametersAndValues = True;
	For Each KeyAndValue In SufficientParameters Do
		If Not ExplanationFormParameters.Property(KeyAndValue.Key) Then
			ThereAreSufficientParametersAndValues = False;
		ElsIf ExplanationFormParameters.Property(KeyAndValue.Key) Then
			ThereAreSufficientParametersAndValues = True;
			Break;
		Else
			If KeyAndValue.Value <> Undefined
				And KeyAndValue.Value.Find(ExplanationFormParameters[KeyAndValue.Key]) = Undefined Then
				ThereAreSufficientParametersAndValues = False;
			Else
				ThereAreSufficientParametersAndValues = True;
				Break;
			EndIf;
		EndIf; 
	EndDo; 
	
	Return ThereAreSufficientParametersAndValues;

EndFunction
 
#EndRegion

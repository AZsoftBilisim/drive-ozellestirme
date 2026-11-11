////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module integration1sdocumentserver Call: server, server call
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region GeneralProceduresAndFunctions

// Returns an array of matching rules. Accesses the service for the object BEFORE when
// the rule selection is ambiguous, if the object is not passed, but its type and identifier are passed.
//
// Parameters:
//   ObjectIS - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//   ObjectBefore - XDTODataObject - Document flow object.
//   ObjectTypeIS - String - the type of IP object.
//   ObjectTypeDM - String - the type of document flow object.
//   ObjectIDDM - String - ID of the document flow object.
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagementCoreClientServer.TheseIntegrationRules
//
Function SuitableRules(ObjectIS = Undefined, ObjectBefore = Undefined, ObjectTypeIS = Undefined,
		ObjectTypeDM = Undefined, ObjectIDDM = Undefined) Export
	
	If TypeOf(ObjectBefore) = Type("XDTODataObject") Then
		XDTODataObject = ObjectBefore;
	Else
		XDTODataObject = Undefined;
	EndIf;
	
	Enough = False;
	
	While Not Enough Do
		
		Rules = New Array;
		
		Query = New Query(
			"SELECT
			|	ExportingRules.Ref AS Ref,
			|	TRUE AS ExportRule,
			|	ExportingRules.AttributeNameObjectDM AS AttributeName,
			|	ExportingRules.IsAdditionalAttributeDM AS IsAdditionalAttribute,
			|	ExportingRules.AdditionalAttributeDMID AS AdditionalAttributeID,
			|	ExportingRules.AdditionalAttributeDMType AS AdditionalAttributeType,
			|	CASE
			|		WHEN ExportingRules.Variant = VALUE(Enum.VariantsOfTheRulesForFillingInAttributes.FromTemplate)
			|			THEN ExportingRules.TemplateMeaning
			|		ELSE ExportingRules.AttributeValueDM
			|	END AS AttributeValue,
			|	CASE
			|		WHEN ExportingRules.Variant = VALUE(Enum.VariantsOfTheRulesForFillingInAttributes.FromTemplate)
			|			THEN ExportingRules.TemplateType
			|		ELSE ExportingRules.AttributeValueDMType
			|	END AS AttributeValueDMType,
			|	CASE
			|		WHEN ExportingRules.Variant = VALUE(Enum.VariantsOfTheRulesForFillingInAttributes.FromTemplate)
			|			THEN ExportingRules.TemplateID
			|		ELSE ExportingRules.AttributeValueDMID
			|	END AS AttributeValueDMID
			|INTO KeyAttributes
			|FROM
			|	Catalog.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesDM AS ExportingRules
			|WHERE
			|	ExportingRules.KeyAttribute_
			|
			|UNION ALL
			|
			|SELECT
			|	ImportingRules.Ref,
			|	FALSE,
			|	ImportingRules.AttributeNameObjectIS,
			|	ImportingRules.IsAdditionalAttributeIS,
			|	ImportingRules.AdditionalAttributeIS,
			|	UNDEFINED,
			|	ImportingRules.AttributeValueIS,
			|	UNDEFINED,
			|	UNDEFINED
			|FROM
			|	Catalog.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesIS AS ImportingRules
			|WHERE
			|	ImportingRules.KeyAttribute_
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Rules.Ref AS Ref,
			|	Rules.ObjectTypeIS AS ObjectTypeIS,
			|	Rules.ObjectTypeDM AS ObjectTypeDM,
			|	Rules.ObjectPresentationIS AS ObjectPresentationIS,
			|	Rules.ObjectPresentationDM AS ObjectPresentationDM,
			|	Rules.ApplicabilityConditionOnExport AS ApplicabilityConditionOnExport,
			|	Rules.ApplicabilityConditionOnImport AS ApplicabilityConditionOnImport,
			|	KeyAttributes.ExportRule AS ExportRule,
			|	KeyAttributes.AttributeName AS AttributeName,
			|	KeyAttributes.AttributeValue AS AttributeValue,
			|	KeyAttributes.AttributeValueDMType AS AttributeValueDMType,
			|	KeyAttributes.AttributeValueDMID AS AttributeValueDMID,
			|	KeyAttributes.IsAdditionalAttribute AS IsAdditionalAttribute,
			|	KeyAttributes.AdditionalAttributeID AS AdditionalAttributeID,
			|	KeyAttributes.AdditionalAttributeType AS AdditionalAttributeType
			|FROM
			|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rules
			|		LEFT JOIN KeyAttributes AS KeyAttributes
			|		ON Rules.Ref = KeyAttributes.Ref
			|WHERE
			|	NOT Rules.DeletionMark
			|	AND &ConditionObjectIS
			|	AND &ConditionObjectDM
			|TOTALS BY
			|	Ref");
			
		If ValueIsFilled(ObjectIS) Then
			ObjectIsReference = Common.IsReference(TypeOf(ObjectIS));
			ObjectTypeIS = ObjectIS.Metadata().FullName();
			ConditionObjectIS = "Rules.ObjectTypeIS = &ObjectTypeIS";
			Query.SetParameter("ObjectTypeIS", ObjectTypeIS);
		ElsIf ValueIsFilled(ObjectTypeIS) Then
			ConditionObjectIS = "Rules.ObjectTypeIS = &ObjectTypeIS";
			Query.SetParameter("ObjectTypeIS", ObjectTypeIS);
		Else
			ObjectIsReference = False;
			ConditionObjectIS = "TRUE";
		EndIf;
		
		If TypeOf(XDTODataObject) = Type("XDTODataObject") Then
			ObjectTypeDM = XDTODataObject.objectID.type;
			ConditionObjectDM = "Rules.ObjectTypeDM = &ObjectTypeDM";
			Query.SetParameter("ObjectTypeDM", ObjectTypeDM);
		ElsIf ValueIsFilled(ObjectTypeDM) Then
			ConditionObjectDM = "Rules.ObjectTypeDM = &ObjectTypeDM";
			Query.SetParameter("ObjectTypeDM", ObjectTypeDM);
		Else
			ConditionObjectDM = "TRUE";
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&ConditionObjectIS", ConditionObjectIS);
		Query.Text = StrReplace(Query.Text, "&ConditionObjectDM", ConditionObjectDM);
		
		RuleSelection_ = Query.Execute().Select(QueryResultIteration.ByGroups);
		While RuleSelection_.Next() Do
			
			IDOfDocumentType = Undefined;
			TypeOfDocumentType = Undefined;
			
			// Verification of key details.
			
			MatchesKeyDetails = True;
			
			SampleKeyDetails = RuleSelection_.Select();
			While SampleKeyDetails.Next() Do
				
				If SampleKeyDetails.ExportRule = True Then
					
					If SampleKeyDetails.AttributeName = "documentType" Then
						IDOfDocumentType = SampleKeyDetails.AttributeValueDMID;
						TypeOfDocumentType = SampleKeyDetails.AttributeValueDMType;
					EndIf;
					
					If TypeOf(XDTODataObject) <> Type("XDTODataObject") Then
						Continue;
					EndIf;
					
					If Not SampleKeyDetails.IsAdditionalAttribute Then
						If Not XDTODataObject.IsSet(SampleKeyDetails.AttributeName) Then
							AttributeValue = Undefined;
						Else
							AttributeValue = XDTODataObject.Get(SampleKeyDetails.AttributeName);
						EndIf;
					Else
						If XDTODataObject.IsSet("additionalProperties") Then
							AttributeValue = Undefined;
							For Each AdditionalAttribute5 In XDTODataObject.additionalProperties Do
								If AdditionalAttribute5.objectID.ID = SampleKeyDetails.AdditionalAttributeID
									And AdditionalAttribute5.objectID.type = SampleKeyDetails.AdditionalAttributeType Then
									If AdditionalAttribute5.IsSet("propertySimpleValue") Then
										AttributeValue = AdditionalAttribute5.propertySimpleValue;
									Else
										AttributeValue = AdditionalAttribute5.propertyObjectValue;
									EndIf;
								EndIf;
							EndDo;
						Else
							AttributeValue = Undefined;
						EndIf;
					EndIf;
					
					If SampleKeyDetails.AttributeValueDMType = "String"
						Or SampleKeyDetails.AttributeValueDMType = "Number"
						Or SampleKeyDetails.AttributeValueDMType = "Date"
						Or SampleKeyDetails.AttributeValueDMType = "Boolean" Then
						
						If AttributeValue <> SampleKeyDetails.AttributeValue Then
							MatchesKeyDetails = False;
							Break;
						EndIf;
						
					ElsIf AttributeValue = Undefined Then
						
						MatchesKeyDetails = False;
						Break;
						
					Else // Reference type.
						
						If Not AttributeValue.IsSet("objectID")
								Or AttributeValue.objectID.ID <> SampleKeyDetails.AttributeValueDMID
								Or AttributeValue.objectID.type <> SampleKeyDetails.AttributeValueDMType Then
							MatchesKeyDetails = False;
							Break;
						EndIf;
						
					EndIf;
					
				ElsIf SampleKeyDetails.ExportRule = False Then // Loading rule.
					
					Cancel = False;
					IntegrationWith1CDocumentManagementCoreOverridable.WhenCheckingWhetherRuleMatchesFunctionalOptions(
						RuleSelection_.Ref,
						RuleSelection_.ObjectTypeDM,
						RuleSelection_.ObjectTypeIS,
						Cancel,
						SampleKeyDetails.AttributeName,
						SampleKeyDetails.AttributeValue);
						
					If Cancel Then
						MatchesKeyDetails = False;
						Break;
					EndIf;
					
					If Not ValueIsFilled(ObjectIS) Then
						Continue;
					EndIf;
					
					If Not SampleKeyDetails.IsAdditionalAttribute Then
						
						If ObjectIsReference Then
							AttributeValue = Common.ObjectAttributeValue(
								ObjectIS,
								SampleKeyDetails.AttributeName);
						Else // Object.
							AttributeValue = ObjectIS[SampleKeyDetails.AttributeName];
						EndIf;
						
					Else // additional banking details.
						
						AttributeValue = Undefined;
						
						If ObjectIsReference Then
							
							RequestDetailsValue = New Query(
								"SELECT ALLOWED TOP 1
								|	PropertiesTable.Value AS AttributeValue
								|FROM
								|	&ObjectWithPropertiesName AS PropertiesTable
								|WHERE
								|	PropertiesTable.Ref = &Ref
								|	AND PropertiesTable.Property = &Property");
							
							RequestDetailsValue.Text = StrReplace(RequestDetailsValue.Text,
								"&ObjectWithPropertiesName",
								StrTemplate("%1.AdditionalAttributes",
									Common.TableNameByRef(ObjectIS.Ref)));
							
							RequestDetailsValue.SetParameter("Ref", ObjectIS.Ref);
							RequestDetailsValue.SetParameter("Property", SampleKeyDetails.AdditionalAttributeID);
							
							SelectingPropsValue = RequestDetailsValue.Execute().Select();
							If SelectingPropsValue.Next() Then
								AttributeValue = SelectingPropsValue.AttributeValue;
							EndIf;
							
						Else // Object.
							
							TheStructureOfTheSearch = New Structure("Property", SampleKeyDetails.AdditionalAttributeID);
							StringsOfProps = ObjectIS.AdditionalAttributes.FindRows(TheStructureOfTheSearch);
							If StringsOfProps.Count() <> 0 Then
								AttributeValue = StringsOfProps[0].Value;
							EndIf;
							
						EndIf;
					EndIf;
					
					If AttributeValue <> SampleKeyDetails.AttributeValue Then
						MatchesKeyDetails = False;
						Break;
					EndIf;
					
				EndIf;
				
			EndDo;
			
			If Not MatchesKeyDetails Then
				Continue;
			EndIf;
			
			// Checking the conditions of applicability.
			
			If ValueIsFilled(ObjectIS) And ValueIsFilled(RuleSelection_.ApplicabilityConditionOnExport) Then
				
				Parameters = New Structure;
				Parameters.Insert("Source", ObjectIS);
				Parameters.Insert("Result", True);
				
				IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
					RuleSelection_.ApplicabilityConditionOnExport,
					Parameters);
				
				If Parameters.Result <> True Then
					Continue;
				EndIf;
				
			EndIf;
			
			If TypeOf(XDTODataObject) = Type("XDTODataObject") And ValueIsFilled(RuleSelection_.ApplicabilityConditionOnImport) Then
				
				Parameters = New Structure;
				Parameters.Insert("Source", XDTODataObject);
				Parameters.Insert("Result", True);
				
				IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
					RuleSelection_.ApplicabilityConditionOnImport,
					Parameters);
				
				If Parameters.Result <> True Then
					Continue;
				EndIf;
				
			EndIf;
			
			Rule = IntegrationWith1CDocumentManagementCoreClientServer.TheseIntegrationRules();
			Rule.Ref = RuleSelection_.Ref;
			Rule.ObjectTypeIS = RuleSelection_.ObjectTypeIS;
			Rule.ObjectTypeDM = RuleSelection_.ObjectTypeDM;
			Rule.ObjectPresentationIS = RuleSelection_.ObjectPresentationIS;
			Rule.ObjectPresentationDM = RuleSelection_.ObjectPresentationDM;
			Rule.IDOfDocumentType = IDOfDocumentType;
			Rule.TypeOfDocumentType = TypeOfDocumentType;
			
			Rules.Add(Rule);
			
		EndDo;
		
		// Perhaps you should clarify the selection by contacting the service for the object itself.
		If Rules.Count() > 1
				And TypeOf(XDTODataObject) <> Type("XDTODataObject")
				And ValueIsFilled(ObjectIDDM)
				And ValueIsFilled(ObjectTypeDM) Then
			
			Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
			
			XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
				Proxy,
				ObjectTypeDM,
				ObjectIDDM)
			
		Else
			
			Enough = True;
			
		EndIf;
	
	EndDo; // Not enough yet.
	
	Return Rules;
	
EndFunction

// Returns the value of the props read from the information base by reference to the object.
// If you don't have access to the account details, an access rights exception will occur.
// If you need to read the details regardless of the current user's rights,
// you should use the pre - transition to privileged mode.
//
// Parameters:
//   Ref - AnyRef- object reference.
//   AttributeName - String - name of the received account details.
//
// Returns:
//   Arbitrary - depends on the type of value of the read props.
//
Function ObjectAttributeValue(Ref, AttributeName) Export
	
	Return Common.ObjectAttributeValue(Ref, AttributeName);
	
EndFunction

// Creates integration rules for the specified type of IP object.
//
// Parameters:
//   ObjectTypeName - String, AnyRef - the full name of the IP object type, as in metadata,
//     or a reference to the object.
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagementCoreClientServer.TheseIntegrationRules
//
Function CreateIntegrationRulesAutomatically(Val ObjectTypeName) Export
	
	RulesForIntegration = New Array;
	
	If Not AccessRight("Edit", Metadata.Catalogs.RulesForIntegrationWith1CDocumentManagement) Then
		Return RulesForIntegration;
	EndIf;
	
	If Common.IsReference(TypeOf(ObjectTypeName)) Then
		ObjectTypeName = ObjectTypeName.Metadata().FullName();
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCallOverridable.WhenCreatingIntegrationRulesAutomatically(
		ObjectTypeName,
		RulesForIntegration);
	
	Return RulesForIntegration;
	
EndFunction

// Saves the list auto-update settings.
//
// Parameters:
//   FormName - String - the name of the form whose settings should be saved.
//   ListName - String - the name of the form list that should be updated.
//   Settings - Structure:
//     * AutoRefresh - Boolean - indicates that auto-update is enabled.
//     * AutoRefreshPeriod - Number - the auto-update period in seconds.
//
Procedure SaveListAutoUpdateSettings(FormName, ListName, Settings) Export
	
	ObjectKey = FormName + ".AutoRefresh." + GetClientConnectionSpeed();
	SystemSettingsStorage.Save(ObjectKey, ListName, Settings);
	
EndProcedure

#EndRegion

#Region Timing

// Returns the structure of timekeeping parameters for the specified object.
//
// Parameters:
//   ExternalObject - AnyRef - reference to the timekeeping object.
//
// Returns:
//   Structure:
//     * TimekeepingEnabled - Boolean
//     * StartDateOfTimekeeping - Date
//     * EndDateOfTimekeeping - Date
//     * Source - String
//     * SourceID - String
//     * SourceType - String
//
Function ObjectTimingParameters(ExternalObject) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetChronometrationSettingsRequest");
	
	ListOfObjects = Query.objects; // XDTOList
	ListOfObjects.Add(
		IntegrationWith1CDocumentManagementCore.CreateExternalObject(Proxy, ExternalObject));
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	XDTOTimekeepingParameters = Result.settings[0];
	
	If XDTOTimekeepingParameters.beginDate = Undefined Then
		StartDateOfTimekeeping = '00010101';
	Else
		StartDateOfTimekeeping = XDTOTimekeepingParameters.beginDate;
	EndIf;
	
	If XDTOTimekeepingParameters.endDate = Undefined Then
		EndDateOfTimekeeping = '00010101';
	Else
		EndDateOfTimekeeping = XDTOTimekeepingParameters.endDate;
	EndIf;
	
	TimingParameters = New Structure;
	TimingParameters.Insert("TimekeepingEnabled", XDTOTimekeepingParameters.chronometrationOn);
	TimingParameters.Insert("StartDateOfTimekeeping", StartDateOfTimekeeping);
	TimingParameters.Insert("EndDateOfTimekeeping", EndDateOfTimekeeping);
	If XDTOTimekeepingParameters.objectID <> Undefined Then
		TimingParameters.Insert("SourceID", XDTOTimekeepingParameters.objectID.ID);
		TimingParameters.Insert("SourceType", XDTOTimekeepingParameters.objectID.type);
		TimingParameters.Insert("Source", XDTOTimekeepingParameters.objectID.presentation);
	EndIf;
	
	Return TimingParameters;
	
EndFunction

// Returns an array of active timekeeping records.
//
// Returns:
//   Array of Structure:
//     * TimekeepingEnabled - Boolean
//     * StartDateOfTimekeeping - Date
//     * EndDateOfTimekeeping - Date
//     * Source - String
//     * SourceID - String
//     * SourceType - String
//
Function ActiveTimekeepingRecords() Export
	
	ActiveEntries = New Array;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetChronometrationSettingsRequest");
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	For Each XDTOTimekeepingParameters In Result.settings Do
		
		TimingParameters = New Structure;
		TimingParameters.Insert("TimekeepingEnabled", XDTOTimekeepingParameters.chronometrationOn);
		TimingParameters.Insert("StartDateOfTimekeeping", XDTOTimekeepingParameters.beginDate);
		TimingParameters.Insert("EndDateOfTimekeeping", XDTOTimekeepingParameters.endDate);
		If XDTOTimekeepingParameters.objectID <> Undefined Then
			TimingParameters.Insert("SourceID", XDTOTimekeepingParameters.objectID.ID);
			TimingParameters.Insert("SourceType",  XDTOTimekeepingParameters.objectID.type);
			TimingParameters.Insert("Source",  XDTOTimekeepingParameters.objectID.presentation);
		EndIf;
		
		ActiveEntries.Add(TimingParameters);
		
	EndDo;
	
	Return ActiveEntries;
	
EndFunction

// Switches the timekeeping and returns the resulting timekeeping parameters for the external object.
//
// Parameters:
//   ExternalObject - AnyRef - reference to the timekeeping object.
//   TimingParameters - See IntegrationWith1CDocumentManagementServerCall.ObjectTimingParameters
//
// Returns:
//   Structure:
//     * TimekeepingEnabled - Boolean
//     * StartDateOfTimekeeping - Date
//     * EndDateOfTimekeeping - Date
//
Function SwitchTimekeepingForExternalObject(ExternalObject, TimingParameters) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMSetChronometrationSettingsRequest");
	
	ListOfObjects = Query.objects; // XDTOList
	ListOfObjects.Add(
		IntegrationWith1CDocumentManagementCore.CreateExternalObject(Proxy, ExternalObject));
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);

	XDTOTimekeepingParameters = Result.settings[0];
	
	If XDTOTimekeepingParameters.beginDate = Undefined Then
		StartDateOfTimekeeping = '00010101';
	Else
		StartDateOfTimekeeping = XDTOTimekeepingParameters.beginDate;
	EndIf;
	
	If XDTOTimekeepingParameters.endDate = Undefined Then
		EndDateOfTimekeeping = '00010101';
	Else
		EndDateOfTimekeeping = XDTOTimekeepingParameters.endDate;
	EndIf;
	
	TimingParameters = New Structure;
	TimingParameters.Insert("TimekeepingEnabled", XDTOTimekeepingParameters.chronometrationOn);
	TimingParameters.Insert("StartDateOfTimekeeping", StartDateOfTimekeeping);
	TimingParameters.Insert("EndDateOfTimekeeping", EndDateOfTimekeeping);
	
	Return TimingParameters;
	
EndFunction

// Switches timekeeping and returns timekeeping parameters for 1C objects:Document management.
//
// Parameters:
//   Sources - Array - an array of structures describing objects UP TO, with the properties SourceID and sourceType.
//
// Returns:
//   Array of Structure:
//     * TimekeepingEnabled - Boolean
//     * StartDateOfTimekeeping - Date
//     * EndDateOfTimekeeping - Date
//     * Source - String
//     * SourceID - String
//     * SourceType - String
//
Function SwitchTimeTrackingBy1CDocumentManagementObjects(Sources) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMSetChronometrationSettingsRequest");
	ListOfObjects = Query.objects; // XDTOList
	
	For Each Source In Sources Do
		
		XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			Source.SourceID,
			Source.SourceType);
		ListOfObjects.Add(XDTODataObject);
		
	EndDo;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	ActiveEntries = New Array;
	
	For Each XDTOTimekeepingParameters In Result.settings Do
		
		TimingParameters = New Structure;
		TimingParameters.Insert("TimekeepingEnabled", XDTOTimekeepingParameters.chronometrationOn);
		TimingParameters.Insert("StartDateOfTimekeeping", XDTOTimekeepingParameters.beginDate);
		TimingParameters.Insert("EndDateOfTimekeeping", XDTOTimekeepingParameters.endDate);
		If XDTOTimekeepingParameters.objectID <> Undefined Then
			TimingParameters.Insert("SourceID", XDTOTimekeepingParameters.objectID.ID);
			TimingParameters.Insert("SourceType",  XDTOTimekeepingParameters.objectID.type);
			TimingParameters.Insert("Source",  XDTOTimekeepingParameters.objectID.presentation);
		EndIf;
		
		ActiveEntries.Add(TimingParameters);
		
	EndDo;
	
	Return ActiveEntries;
	
EndFunction

#EndRegion

#Region ProcessesAndTasks_

// Retrieves a list of templates defined in the Workflow for the specified BP type and subject.
//
// Parameters:
//   BusinessProcessType - String - the name of the type XDTO.
//   SubjectOfBusinessProcess - Structure:
//     * ID - String - the unique identifier of the subject of the business process in the Document Flow.
//     * type - String - the name of the XDTO type of the business process subject.
//
// Returns:
//   ValueList:
//     * name - String - the name of the template.
//     * ID - String - the unique identifier of the template.
//     * type - String - the name of the template's XDTO type.
//
Function BusinessProcessTemplates(Val BusinessProcessType, Val SubjectOfBusinessProcess) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetBusinessProcessTemplatesRequest");
	Query.businessProcessType = BusinessProcessType;
	
	If SubjectOfBusinessProcess <> Undefined Then
		SubjectOfBusinessProcessID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			SubjectOfBusinessProcess.ID,
			SubjectOfBusinessProcess.type);
		
		Query.businessProcessTargetID = SubjectOfBusinessProcessID;
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	ListOfDocumentTemplates = New ValueList;
	For Each Template In Result.BusinessProcessTemplates Do
		TemplateData = New Structure;
		TemplateData.Insert("ID", Template.objectID.ID);
		TemplateData.Insert("type", Template.objectID.type);
		TemplateData.Insert("name", Template.name);
		ListOfDocumentTemplates.Add(TemplateData);
	EndDo;
	
	Return ListOfDocumentTemplates;
	
EndFunction

// Checks the possibility of starting the negotiation in the UP.
//
// Parameters:
//   SubjectOfApproval - AnyRef - the agreed object is.
//   WarningText - String - implicitly returned value, warning text.
//
// Returns:
//   Boolean - True if the start of the negotiation is allowed, and False otherwise
//
Function UserIsAllowedToStartMatching(Val SubjectOfApproval, WarningText) Export
	
	Result = Undefined;
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingUserSPermissionToStartNegotiation(
		SubjectOfApproval, WarningText, Result);
		
	If TypeOf(Result) = Type("Boolean") Then
		Return Result;
	Else
		Return True;
	EndIf;
	
EndFunction

// Checks the possibility of interrupting the negotiation in the UP.
//
// Parameters:
//   SubjectOfApproval - AnyRef - the agreed object is.
//   SubjectOfBefore - Structure - description of the linked object BEFORE:
//      the name string is a Presentation of the linked object.
//      ID String is the ID of the linked object.
//      type - String is the name of the XDTO type.
//   WarningText - String - implicitly returned value, warning text.
//
// Returns:
//   Boolean - True if agreement interruption is allowed, and False otherwise
//
Function UserIsAllowedToInterruptNegotiation(Val SubjectOfApproval, Val SubjectOfBefore,
		WarningText) Export
	
	Result = Undefined;
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingUserSPermissionToInterruptNegotiation(
		SubjectOfApproval, SubjectOfBefore, WarningText, Result);
		
	If TypeOf(Result) = Type("Boolean") Then
		Return Result;
	Else
		Return True;
	EndIf;
	
EndFunction

// Checks whether the approval processes have already been started in the DO according to the description of the subject in the DO.
//
// Parameters:
//   SubjectOfBefore - Structure:
//     * name - String - presentation of the subject.
//     * ID - String - id of the linked object BEFORE.
//     * type - String - the name of the type XDTO.
//
// Returns:
//   Boolean - True if there are active reconciliation processes, and False otherwise.
//
Function StartedCoordinationOnSubjectDM(Val SubjectOfBefore) Export
	
	// Let's choose active processes of the "coordination" type for the specified subject.
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ObjectSelectionCriteria = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMObjectListQuery");
	ListOfSelectionConditions = ObjectSelectionCriteria.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "target";
	Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		SubjectOfBefore.ID,
		SubjectOfBefore.type);
	ListOfSelectionConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "withExecuted";
	Condition.value = False;
	ListOfSelectionConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "withDelayed";
	Condition.value = False;
	ListOfSelectionConditions.Add(Condition);
	
	Try
		Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
			Proxy,
			"DMBusinessProcessApproval",
			ObjectSelectionCriteria);
	Except
		Return False;
	EndTry;
	
	Return (Response.items.Count() <> 0);
	
EndFunction

// Starts matching according to the specified template and subject and returns a sign of successful launch.
//
// Parameters:
//    Template - Structure:
//      * name - String - template representation.
//      * ID - String - template ID.
//      * type - String - the name of the type XDTO.
//    SubjectOf - Structure:
//      * name - String - presentation of the subject.
//      * ID - String - item ID.
//      * type - String - the name of the type XDTO.
//
// Returns:
//    Boolean - True if the process is started successfully.
//
Function StartMatchingTemplate(Val Template, Val SubjectOf) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	TemplateProcess = IntegrationWith1CDocumentManagement.NewBusinessProcessByTemplate(Proxy,
		"DMBusinessProcessApproval", Template, SubjectOf);
	NewProcess = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMBusinessProcessApproval");
	IntegrationWith1CDocumentManagementCore.FillInXDTOPropertyValues(Proxy, NewProcess, TemplateProcess);
	
	Try
		RunResult = IntegrationWith1CDocumentManagement.StartBusinessProcess(Proxy, NewProcess);
	Except
		Return False;
	EndTry;
	
	Return (IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, RunResult, "DMError") = False);
	
EndFunction

// Interrupts the approval processes for the specified subject.
//
// Parameters:
//   SubjectOfBefore - Structure:
//     * name - String - presentation of the subject.
//     * ID - String - id of the linked object BEFORE.
//     * type - String - the name of the type XDTO.
//
// Returns:
//   Boolean - True if the process was aborted successfully.
//
Function AbortApproval(Val SubjectOfBefore) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = query.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "target";
	Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		SubjectOfBefore.ID,
		SubjectOfBefore.type);
	
	FilterConditions.Add(Condition);
	
	Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMBusinessProcessApproval",
		query);
	
	If Response.items.Count() = 0 Then
		Return True;
	EndIf;
	
	// There may be several approval processes. Let's interrupt everything.
	ListOfObjectsToRecord = New Array;
	
	For Each Item In Response.items Do
		
		Process_ = Item.object;
		ReadProcess = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			Process_.objectID.type,
			Process_.objectID.ID);
		InterruptedState = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy, "DMBusinessProcessState");
		InterruptedState.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			"Прерван",
			"DMBusinessProcessState"); //@NON-NLS-1
		InterruptedState.name = "Aborted";
		ReadProcess.state = InterruptedState;
		ListOfObjectsToRecord.Add(ReadProcess);
		
	EndDo;
	
	IntegrationWith1CDocumentManagementCore.WriteObjects(Proxy, ListOfObjectsToRecord);
	
	Return True;
	
EndFunction

// Receives subject-specific approval tasks addressed to the user.
//
// Parameters:
//   SubjectOfBefore - Structure:
//     * name - String - presentation of the subject.
//     * ID - String - id of the linked object BEFORE.
//     * type - String - the name of the type XDTO.
//
// Returns:
//   Array of String - ids of the approval tasks in UP to.
//
Function GetApprovalIssues(Val SubjectOfBefore) Export
	
	Result = New Array;
	
	// Let's select the user's active tasks, requiring you to specify their type.
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = query.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "target";
	Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		SubjectOfBefore.ID,
		SubjectOfBefore.type);
	FilterConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "byUser";
	Condition.value = True;
	FilterConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "typed";
	Condition.value = True;
	FilterConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "withExecuted";
	Condition.value = False;
	FilterConditions.Add(Condition);
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "withDelayed";
	Condition.value = False;
	FilterConditions.Add(Condition);
	
	Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMBusinessProcessApprovalTaskApproval",
		query);
	
	// Let's select the received tasks by the type of "Coordination".
	For Each Item In Response.items Do
		Task = Item.object;
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Task,
			"DMBusinessProcessApprovalTaskApproval") Then
			Result.Add(Task.objectID.ID);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Performs coordination tasks. Returns True in case of success, False in case of error.
//
// Parameters:
//   Var_Tasks - Array of String - task IDs.
//   Result - String - the description of the result:
//     is "Agreed",
//     "Agreed by notes" or
//     "Inconsistent".
//   Comment - String - comment on the results of "inconsistent" or "consistent notes".
//   ErrorMessageText - String - implicitly returned value, error description.
//
// Returns:
//   Boolean - True if the coordination of all tasks is completed successfully, and False otherwise.
//
Function PerformReconciliation(Val Var_Tasks, Val Result, Val Comment, ErrorMessageText) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	For Each TaskID__ In Var_Tasks Do
		
		Task = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			"DMBusinessProcessApprovalTaskApproval",
			TaskID__);
		
		Response = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMApprovalResult");
		Response.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			Result,
			"DMApprovalResult");
		If Result = "Согласовано" Then //@NON-NLS-1
			Response.name = NStr("vi = 'Đã thống nhất';
								|ru = 'Согласовано';
								|en = 'Approved'; fa = 'تأییدشده';
								|it = 'Concordato';
								|pl = 'Uzgodniono';
								|tr = 'Onaylandı'");
			
		ElsIf Result = "СогласованоСЗамечаниями" Then //@NON-NLS-1
			Response.name = NStr("vi = 'Đã thống nhất và có lưu ý';
								|ru = 'Согласовано с замечаниями';
								|en = 'Approved with comments'; fa = 'تأییدشده با توضیحات';
								|it = 'Omologato con note';
								|pl = 'Uzgodniono z uwagami';
								|tr = 'Yorumlarla onaylandı'");
			
		ElsIf Result = "НеСогласовано" Then //@NON-NLS-1
			Response.name = NStr("vi = 'Không thống nhất';
								|ru = 'Не согласовано';
								|en = 'Not approved'; fa = 'تأییدنشده';
								|it = 'Non concordato';
								|pl = 'Nie uzgodniono';
								|tr = 'Onaylanmadı'");
			
		EndIf;
		Task.approvalResult = Response;
		Task.executed = True;
		Task.endDate = CurrentSessionDate();
		Task.executionComment = Comment;
		
		RecordingResult = IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, Task);
		
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, RecordingResult, "DMError") Then
			ErrorMessageText = RecordingResult.description;
			Return False;
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

// Stops the process BEFORE. Raises an exception if it is impossible to do this in the case
// when the rights are insufficient or the current state of the process does not allow it to be done.
//
// Parameters:
//   ID - String - process ID.
//   Type - String - type of the XDTO-type of the process.
//
Procedure StopProcess(ID, Type) Export
	
	StateName = "Остановлен"; //@NON-NLS-1
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ReadProcess = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		Type,
		ID);
	
	NewState = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMBusinessProcessState");
	NewState.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		StateName,
		"DMBusinessProcessState");
	NewState.name = StateName;
	ReadProcess.state = NewState;
	
	IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, ReadProcess);
	
EndProcedure

// Interrupts the process UNTIL. Raises an exception if it is impossible to do this in the case
// when the rights are insufficient or the current state of the process does not allow it to be done.
//
// Parameters:
//   ID - String - process ID.
//   Type - String - type of the XDTO-type of the process.
//
Procedure InterruptProcess(ID, Type) Export
	
	StateName = "Прерван"; //@NON-NLS-1
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ReadProcess = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		Type,
		ID);
	
	NewState = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMBusinessProcessState");
	NewState.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		StateName,
		"DMBusinessProcessState");
	NewState.name = StateName;
	ReadProcess.state = NewState;
	
	IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, ReadProcess);
	
EndProcedure

// Continues the process UNTIL. Raises an exception if it is impossible to do this in the case
// when the rights are insufficient or the current state of the process does not allow it to be done.
//
// Parameters:
//   ID - String - process ID.
//   Type - String - type of the XDTO-type of the process.
//
Procedure ContinueProcess(ID, Type) Export
	
	StateName = "Активен"; //@NON-NLS-1
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ReadProcess = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		Type,
		ID);
	
	NewState = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMBusinessProcessState");
	NewState.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		StateName,
		"DMBusinessProcessState");
	NewState.name = StateName;
	ReadProcess.state = NewState;
	
	IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, ReadProcess);
	
EndProcedure

// Returns the signature of the duration of the postponement.
//
// Parameters:
//   Author - String - user's view.
//   AuthorID - String - user ID.
//   AuthorType - String - the name of the user type.
//   OldDeadline - Date - the old deadline.
//   NewTerm - Date - a new deadline for execution.
//
// Returns:
//   String - signature of the duration of the postponement.
//
Function SignatureOfPostponementDuration(Author, AuthorID, AuthorType, OldDeadline, NewTerm) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMPostponementDurationRequest");
	Query.user = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMUser");
	Query.user.name = Author;
	Query.user.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, AuthorID, AuthorType);
	Query.oldDueDate = OldDeadline;
	Query.newDueDate = NewTerm;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	Return Response.postponementDuration;
	
EndFunction

#EndRegion

#Region Documents

// Adds a relationship of the specified type between two documents.
//
// Parameters:
//   SourceDocument_ - Structure - Source Document:
//     * ID - String - the ID of the object BEFORE.
//     * Type - String - the object type is UP TO.
//     * Presentation - String - representation of the object BEFORE.
//   LinkedDocument - Structure - Linked Document:
//     * ID - String - the ID of the object BEFORE.
//     * Type - String - the object type is UP TO.
//     * Presentation - String - representation of the object BEFORE.
//   LinkType - Structure - communication type (optional):
//     * ID - String - the ID of the object BEFORE.
//     * Type - String - the object type is UP TO.
//     * Presentation - String - representation of the object BEFORE.
//
Procedure AddDocumentLink(SourceDocument_, LinkedDocument, LinkType = Undefined) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Link = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMDocumentRelation");
	
	Document = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMDocument");
	Document.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		SourceDocument_.ID,
		SourceDocument_.Type);
	Document.name = SourceDocument_.Presentation;
	Link.document = Document;
	
	RelatedDocument = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMDocument");
	RelatedDocument.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		LinkedDocument.ID,
		LinkedDocument.Type);
	RelatedDocument.name = LinkedDocument.Presentation;
	Link.relatedDocument = RelatedDocument;
	
	If ValueIsFilled(LinkType) Then
		RelationType = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelationType");
		RelationType.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			LinkType.ID,
			LinkType.Type);
		RelationType.name = LinkType.Presentation;
		Link.relationType = RelationType;
	EndIf;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMAddDocumentRelationRequest");
	Query.relation = Link;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
EndProcedure

// Deletes a relationship of the specified type between two documents.
//
// Parameters:
//   SourceDocument_ - Structure - The original document.
//   LinkedDocument - Structure - linked document.
//   LinkType - Structure - type of connection. Properties of structures:
//     ID String - ID of the object BEFORE.
//     Type - String - object type BEFORE.
//     Presentation - String - Presentation of the object BEFORE.
//
Procedure DeleteDocumentAssociation(SourceDocument_, LinkedDocument, LinkType) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Document = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMDocument");
	Document.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		SourceDocument_.ID,
		SourceDocument_.Type);
	Document.name = SourceDocument_.Presentation;
	
	RelatedDocument = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMDocument");
	RelatedDocument.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		LinkedDocument.ID,
		LinkedDocument.Type);
	RelatedDocument.name = LinkedDocument.Presentation;
	
	RelationType = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelationType");
	RelationType.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		LinkType.ID,
		LinkType.Type);
	RelationType.name = LinkType.Presentation;
	
	Link = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMDocumentRelation");
	Link.document = Document;
	Link.relationType = RelationType;
	Link.relatedDocument = RelatedDocument;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRemoveDocumentRelationRequest");
	Query.relation = Link;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
EndProcedure

// Registers the document if it has not been registered yet.
//
// Parameters:
//   DocumentType - String - Document type.
//   DocumentID - String - Document type.
//
Procedure RegisterDocumentIfNecessary(DocumentType, DocumentID) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		DocumentType,
		DocumentID,
		"regNumber,regDate");
	
	If ValueIsFilled(XDTODataObject.regNumber) And ValueIsFilled(XDTODataObject.regDate) Then
		Return;
	EndIf;
	
	XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, DocumentType);
	XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DocumentID,
		DocumentType);
	XDTODataObject.name = "";
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMDocumentRegistrationRequest");
	Query.document = XDTODataObject;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Runs a long integration operation in the background process1sdocumentation.Coordination is possible.
//
// Parameters:
//   FormUniqueID - UUID - ID of the calling form.
//   SubjectOfApproval - AnyRef - subject of approval.
//
// Returns:
//   Structure:
//     * Status - String - "In progress" if the task hasn't finished yet;
//         "Completed" if the task was completed successfully;
//         " Error "if the task was completed with an error;
//         " Canceled " if the task was canceled by the user or administrator.
//     * JobID - UUID - if Status = "In progress", then contains
//         the ID of the running background job.
//     * ResultAddress - String - address of the temporary storage where
//         the result of the procedure will be placed (or already placed).
//     * AdditionalResultAddress - String - if the additional Result parameter is set,
//         it contains the address of the additional temporary storage
//         where the result of the procedure will be placed (or has already been placed).
//     * BriefErrorDescription - String - brief information about the exception if the Status = "Error".
//     * DetailErrorDescription - String - detailed information about the exception if the Status = "Error".
//     * Messages - FixedArray of String - if the Status <> is "In Progress", then an array of objects
//         Messages to the user that were generated in the background task.
//
Function LongOperationIsNotPossible(FormUniqueID, SubjectOfApproval) Export
	
	TimeConsumingOperationParameters = IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters();
	TimeConsumingOperationParameters.Insert("SubjectOfApproval", SubjectOfApproval);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Xác định khả năng thống nhất';
														|ru = 'Определение возможности согласования';
														|en = 'Determining approval capability'; fa = 'Determining approval capability';
														|it = 'Definizione possibilità di omologazione';
														|pl = 'Określenie możliwości uzgodnienia';
														|tr = 'Anlaşma olasılığının belirlenmesi'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"IntegrationWith1CDocumentManagement.CoordinationIsPossible",
		TimeConsumingOperationParameters,
		ExecutionParameters);
	
EndFunction

// Runs a long integration operation in the background process1sdocumentation.Start the negotiation.
//
// Parameters:
//   FormUniqueID - UUID - ID of the calling form.
//   SubjectOfApproval - AnyRef - subject of approval.
//
// Returns:
//   Structure:
//     * Status - String - "In progress" if the task hasn't finished yet;
//         "Completed" if the task was completed successfully;
//         " Error "if the task was completed with an error;
//         " Canceled " if the task was canceled by the user or administrator.
//     * JobID - UUID - if Status = "In progress", then contains
//         the ID of the running background job.
//     * ResultAddress - String - address of the temporary storage where
//         the result of the procedure will be placed (or already placed).
//     * AdditionalResultAddress - String - if the additional Result parameter is set,
//         it contains the address of the additional temporary storage
//         where the result of the procedure will be placed (or has already been placed).
//     * BriefErrorDescription - String - brief information about the exception if the Status = "Error".
//     * DetailErrorDescription - String - detailed information about the exception if the Status = "Error".
//     * Messages - FixedArray of String - if the Status <> is "In Progress", then an array of objects
//         Messages to the user that were generated in the background task.
//
Function LongOperationStartMatching(FormUniqueID, SubjectOfApproval) Export
	
	TimeConsumingOperationParameters = IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters();
	TimeConsumingOperationParameters.Insert("SubjectOfApproval", SubjectOfApproval);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Gửi chứng từ sang DM để thống nhất';
														|ru = 'Отправка документа на согласование в ДО';
														|en = 'Sending a document for approval in DI'; fa = 'Sending a document for approval in DI';
														|it = 'Invio documenti da omologare in DM';
														|pl = 'Wysyłka dokumentu do uzgodnienia w Document Management';
														|tr = 'İş Akışında onaylamaya belge gönderimi'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"IntegrationWith1CDocumentManagement.StartApproval",
		TimeConsumingOperationParameters,
		ExecutionParameters);
	
EndFunction

// Runs a long integration operation in the background process1sdocumentation.Interrupting the agreement is possible.
//
// Parameters:
//   FormUniqueID - UUID - ID of the calling form.
//   SubjectOfApproval - AnyRef - subject of approval.
//
// Returns:
//   Structure:
//     * Status - String - "In progress" if the task hasn't finished yet;
//         "Completed" if the task was completed successfully;
//         " Error "if the task was completed with an error;
//         " Canceled " if the task was canceled by the user or administrator.
//     * JobID - UUID - if Status = "In progress", then contains
//         the ID of the running background job.
//     * ResultAddress - String - address of the temporary storage where
//         the result of the procedure will be placed (or already placed).
//     * AdditionalResultAddress - String - if the additional Result parameter is set,
//         it contains the address of the additional temporary storage
//         where the result of the procedure will be placed (or has already been placed).
//     * BriefErrorDescription - String - brief information about the exception if the Status = "Error".
//     * DetailErrorDescription - String - detailed information about the exception if the Status = "Error".
//     * Messages - FixedArray of String - if the Status <> is "In Progress", then an array of objects
//         Messages to the user that were generated in the background task.
//
Function LongRunningOperationInterruptNegotiationIsPossible(FormUniqueID, SubjectOfApproval) Export
	
	TimeConsumingOperationParameters = IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters();
	TimeConsumingOperationParameters.Insert("SubjectOfApproval", SubjectOfApproval);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Xác định khả năng ngắt quy trình thống nhất';
														|ru = 'Определение возможности прерывания согласования';
														|en = 'Determining approval aborting capability'; fa = 'Determining approval aborting capability';
														|it = 'Definizione possibilità di interruzione omologazione';
														|pl = 'Określenie możliwości przerwania uzgodnienia';
														|tr = 'Onaylamanın kesilme olasılığının belirlenmesi'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"IntegrationWith1CDocumentManagement.AgreementInterruptionIsPossible",
		TimeConsumingOperationParameters,
		ExecutionParameters);
	
EndFunction

// Runs a long integration operation in the background process1sdocumentation.Break the agreement.
//
// Parameters:
//   FormUniqueID - UUID - ID of the calling form.
//   SubjectOfApproval - AnyRef - subject of approval.
//
// Returns:
//   Structure:
//     * Status - String - "In progress" if the task hasn't finished yet;
//         "Completed" if the task was completed successfully;
//         " Error "if the task was completed with an error;
//         " Canceled " if the task was canceled by the user or administrator.
//     * JobID - UUID - if Status = "In progress", then contains
//         the ID of the running background job.
//     * ResultAddress - String - address of the temporary storage where
//         the result of the procedure will be placed (or already placed).
//     * AdditionalResultAddress - String - if the additional Result parameter is set,
//         it contains the address of the additional temporary storage
//         where the result of the procedure will be placed (or has already been placed).
//     * BriefErrorDescription - String - brief information about the exception if the Status = "Error".
//     * DetailErrorDescription - String - detailed information about the exception if the Status = "Error".
//     * Messages - FixedArray of String - if the Status <> is "In Progress", then an array of objects
//         Messages to the user that were generated in the background task.
//
Function LongRunningOperationAbortNegotiation(FormUniqueID, SubjectOfApproval) Export
	
	TimeConsumingOperationParameters = IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters();
	TimeConsumingOperationParameters.Insert("SubjectOfApproval", SubjectOfApproval);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Ngắt quy trình nghiệp vụ thống nhất chứng từ trong DM';
			|ru = 'Прерывание бизнес-процесса согласования документа в ДО';
			|en = 'Aborting the document approval business process in DI'; fa = 'Aborting the document approval business process in DI';
			|it = 'Interruzione del processo aziendale di omologazione del documento in DM';
			|pl = 'Przerwanie procesu biznesowego uzgodnienia dokumentu w Document Management';
			|tr = 'İş Akışında belge onaylama iş sürecinin kesintiye uğraması'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"IntegrationWith1CDocumentManagement.AbortApproval",
		TimeConsumingOperationParameters,
		ExecutionParameters);
	
EndFunction

// Runs a long integration operation in the background process1sdocumentation.States of agreement.
//
// Parameters:
//   FormUniqueID - UUID - ID of the calling form.
//   SubjectOfApproval - AnyRef - subject of approval.
//
// Returns:
//   Structure:
//     * Status - String - "In progress" if the task hasn't finished yet;
//         "Completed" if the task was completed successfully;
//         " Error "if the task was completed with an error;
//         " Canceled " if the task was canceled by the user or administrator.
//     * JobID - UUID - if Status = "In progress", then contains
//         the ID of the running background job.
//     * ResultAddress - String - address of the temporary storage where
//         the result of the procedure will be placed (or already placed).
//     * AdditionalResultAddress - String - if the additional Result parameter is set,
//         it contains the address of the additional temporary storage
//         where the result of the procedure will be placed (or has already been placed).
//     * BriefErrorDescription - String - brief information about the exception if the Status = "Error".
//     * DetailErrorDescription - String - detailed information about the exception if the Status = "Error".
//     * Messages - FixedArray of String - if the Status <> is "In Progress", then an array of objects
//         Messages to the user that were generated in the background task.
//
Function LongRunningOperationStateOfApproval(FormUniqueID, SubjectOfApproval) Export
	
	TimeConsumingOperationParameters = IntegrationWith1CDocumentManagementCore.TimeConsumingOperationParameters();
	TimeConsumingOperationParameters.Insert("SubjectOfApproval", SubjectOfApproval);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormUniqueID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Nhận trạng thái thống nhất hiện thời chứng từ trong DM';
			|ru = 'Получение текущего состояния согласования документа в ДО';
			|en = 'Getting the current document approval state in DI'; fa = 'Getting the current document approval state in DI';
			|it = 'Ricezione dello stato corrente di omologazione del documento in DM';
			|pl = 'Otrzymanie bieżącego statusu uzgodnienia dokumentu w Document Management';
			|tr = 'İş Akışında belge onaylama mevcut durumunu alma'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"IntegrationWith1CDocumentManagement.StateOfApproval",
		TimeConsumingOperationParameters,
		ExecutionParameters);
	
EndFunction

#EndRegion
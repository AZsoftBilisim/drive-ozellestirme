////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module Integration1 Document management: server, external connection
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region InterfaceImplementation

#Region StandardSubsystems_BasicFunctionality

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("StartApproval", True);
	Methods.Insert("GetRelatedDocumentFilesAsynchronously", True);
	Methods.Insert("AbortApproval", True);
	Methods.Insert("AgreementInterruptionIsPossible", True);
	Methods.Insert("CoordinationIsPossible", True);
	Methods.Insert("StateOfApproval", True);
	
EndProcedure

#EndRegion

#EndRegion

#Region GeneralProceduresAndFunctions

// Returns information about whether integration with 1C is enabled:Document management of edition 2.
//
// Returns:
//   Boolean
//
Function UseIntegration() Export
	
	Return GetFunctionalOption("UseIntegrationWith1CDocumentManagement");
	
EndFunction

// Adds Workflow commands to the object form when created on the server.
//
// Parameters:
//   Form - ClientApplicationForm - the form from which the procedure is called.
//   CommandLocation - FormGroup - the default location is the command panel of the form.
//   NotificationParameters - Structure - parameters where the command source can be set.
//   Ref - AnyRef - a reference to the IP object, which is the main object of the Form.
//
Procedure OnCreateAtServer(Form, CommandLocation = Undefined, NotificationParameters = Undefined,
		Ref = Undefined) Export
	
	If Not UseIntegration() Then
		Return;
	EndIf;
	
	// Let's add the timing commands.
	// Exceptions should not make it impossible to open the forms of integrable objects.
	Try
		If GetFunctionalOption("UseDailyReports1CDocumentManagement") Then
			If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP", True) Then
				AddSwitchTimekeepingCommand(Form, CommandLocation, Ref);
				AddSpecifyLaborCostsCommand(Form, CommandLocation);
			EndIf;
		EndIf;
	Except
		ErrorMessageText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(
			IntegrationWith1CDocumentManagementCore.EventLogEventName(),
			EventLogLevel.Error,,,
			ErrorMessageText);
		Common.MessageToUser(ErrorMessageText);
	EndTry;
	
	// Hide the extra BID commands.
	IntegrationWith1CDocumentManagementCore.RemoveDuplicatesOfIntegrationCommands(
		Form,
		Metadata.CommonCommands.IntegrationWith1CDocumentManagementCreateBusinessProcess.Name);
	IntegrationWith1CDocumentManagementCore.RemoveDuplicatesOfIntegrationCommands(
		Form,
		Metadata.CommonCommands.IntegrationWith1CDocumentManagementCreateLetter.Name);
	
EndProcedure

// Retrieves the object filled in by default from the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Type - String - the name of the XDTO object type.
//   SubjectOf - Structure - Used to get business processes:
//     * ID - String - the unique identifier of the object in the Workflow.
//     * type - String - the name of the type XDTO.
//
// Returns:
//   XDTODataObject - an XDTO object of the dmgetnewobjectreresponse type.
//
Function NewObjectBefore(Proxy, Type, SubjectOf) Export
	
	If SubjectOf = Undefined Then
		Return Undefined;
	EndIf;
	
	If StrFind(Type, "BusinessProcess") > 0 Then
		Return NewBusinessProcess(Proxy, Type, SubjectOf);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Starts receiving files of related documents.
//
// Parameters:
//   RelatedDocuments - Array of Structure:
//     * ID - String - ID of the linked document.
//     * Type - String - the type of linked document.
//
// Returns:
//   String - the address in the temporary storage where the result will be placed.
//
Function GetRelatedDocumentFiles(RelatedDocuments) Export
	
	JobKey = New UUID;
	AddressInTempStorage = PutToTempStorage(Undefined, JobKey);
	
	ParametersArray = New Array;
	ParametersArray.Add(AddressInTempStorage);
	ParametersArray.Add(RelatedDocuments);
	ParametersArray.Add(SessionParameters.IntegrationWith1CDocumentManagementUsername);
	ParametersArray.Add(SessionParameters.IntegrationWith1CDocumentManagementPassword);
	
	BackgroundJobs.Execute(
		"IntegrationWith1CDocumentManagement.GetRelatedDocumentFilesAsynchronously",
		ParametersArray, JobKey, NStr("vi = 'Nhận tệp chứng từ liên kết';
										|ru = 'Получение файлов связанных документов';
										|en = 'Receive linked document files'; fa = 'Receive linked document files';
										|it = 'Ricezione file dei documenti collegati';
										|pl = 'Otrzymanie plików powiązanych dokumentów';
										|tr = 'İlgili belge dosyalarını alma'"));
		
	Return AddressInTempStorage;
	
EndFunction

// Asynchronously, in the background task, receives files of related documents.
//
// Parameters:
//   Address - String - the address for the execution result in the temporary storage.
//   RelatedDocuments - Array of Structure:
//     * ID - String - ID of the linked document.
//     * Type - String - the type of linked document.
//   UserName - String - the name of the user BEFORE saved in the settings of the user
//     from whose session the asynchronous call was initiated.
//   Password - String - the password of this user.
//
Procedure GetRelatedDocumentFilesAsynchronously(Address, RelatedDocuments, UserName, Password) Export
	
	SessionParameters.IntegrationWith1CDocumentManagementUsername = UserName;
	SessionParameters.IntegrationWith1CDocumentManagementPassword = Password;
	
	Result = DataProcessors.IntegrationWith1CDocumentManagement.GetRelatedDocumentFiles(RelatedDocuments);
	PutToTempStorage(Result, Address);
	
EndProcedure

// Retrieves a list of objects by links from the specified IP object that are suitable for automatically
// adding links (having configured integration rules). Takes into account tabular parts.
//
// Parameters:
//   ObjectReferenceIS - AnyRef - the IP object to which the links are being added.
//
// Returns:
//   Array of AnyRef - links to suitable IP objects.
//
Function GetSuitableObjectsToAddLinksTo(ObjectReferenceIS) Export
	
	SuitableObjects = New Array;
	
	TypesOfObjectsWithRules = IntegrationWith1CDocumentManagementCached.GetObjectTypesWithIntegrationRules(
		"DMInternalDocument, DMIncomingDocument, DMOutgoingDocument");
	If TypesOfObjectsWithRules.Count() = 0 Then
		Return SuitableObjects;
	EndIf;
	
	ObjectMetadata = ObjectReferenceIS.Metadata();
	
	ObjectIS = Undefined; // We will get the object below if necessary.
	
	// Let's check the details of the header.
	For Each Attribute In ObjectMetadata.Attributes Do
		
		SuitableByType = False;
		For Each ItemTypeWithRules In TypesOfObjectsWithRules Do
			If Attribute.Type.ContainsType(ItemTypeWithRules) Then
				SuitableByType = True;
				Break;
			EndIf;
		EndDo;
		
		If Not SuitableByType Then
			Continue;
		EndIf;
		
		If ObjectIS = Undefined Then
			ObjectIS = ObjectReferenceIS.GetObject();
		EndIf;
		
		AttributeValueIS = ObjectIS[Attribute.Name];
		AttributeValueDMTypeIS = TypeOf(AttributeValueIS);
		
		If TypesOfObjectsWithRules.Find(AttributeValueDMTypeIS) <> Undefined
				And ValueIsFilled(AttributeValueIS) Then
			SuitableObjects.Add(AttributeValueIS);
		EndIf;
		
	EndDo;
	
	// Let's check the tabular parts.
	For Each TabularSection In ObjectMetadata.TabularSections Do
		For Each Attribute In TabularSection.Attributes Do
			
			SuitableByType = False;
			For Each ItemTypeWithRules In TypesOfObjectsWithRules Do
				If Attribute.Type.ContainsType(ItemTypeWithRules) Then
					SuitableByType = True;
					Break;
				EndIf;
			EndDo;
			
			If Not SuitableByType Then
				Continue;
			EndIf;
			
			If ObjectIS = Undefined Then
				ObjectIS = ObjectReferenceIS.GetObject();
			EndIf;
			
			For Each LineOfATabularSection In ObjectIS[TabularSection.Name] Do
				
				AttributeValueIS = LineOfATabularSection[Attribute.Name];
				AttributeValueDMTypeIS = TypeOf(AttributeValueIS);
				
				If TypesOfObjectsWithRules.Find(AttributeValueDMTypeIS) <> Undefined
						And ValueIsFilled(AttributeValueIS) Then
					SuitableObjects.Add(AttributeValueIS);
				EndIf;
				
			EndDo;
			
		EndDo;
	EndDo;
	
	// Links to relevant documents may be stored somewhere else, for example, in the data registers.
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingSuitableObjectsToAddLink(
		ObjectIS,
		SuitableObjects);
	
	SuitableObjects = CommonClientServer.CollapseArray(SuitableObjects);
	
	Return SuitableObjects;
	
EndFunction

// Returns the integration rules for the object UP to in the form of a list of values to present to the user.
//
// Parameters:
//   ObjectBefore - XDTODataObject - the object BEFORE, the source of the fill data.
//
// Returns:
//   ValueList of KeyAndValue - rules for integration and Presentation of created IP objects:
//     * Key - CatalogRef.RulesForIntegrationWith1CDocumentManagement
//     * Value - String
//
Function RulesForFillingIntegratedObjectsWithList(ObjectBefore) Export
	
	Result = New ValueList;
	
	Rules = IntegrationWith1CDocumentManagementServerCall.SuitableRules(, ObjectBefore);
	
	For Each Rule In Rules Do
		Result.Add(Rule.Ref, Rule.ObjectPresentationIS);
	EndDo;
	
	Return Result;
	
EndFunction

// Generates a universal table of attached printed forms for subsequent creation.
//
// Parameters:
//   PrintForms - ValueTable - the tabular part of the Catalog of the Integration rules1 with document management:
//     * CommandName - String
//     * PrintManager - String
//     * ShouldUpdate - Boolean
//     * CommandPresentation - String
//     * AdditionalParameters - String
//
// Returns:
//   ValueTable - See IntegrationWith1CDocumentManagementCore.AttachedPrintedForms
//
Function AttachedPrintedForms(PrintForms) Export
	
	AttachedPrintedForms = IntegrationWith1CDocumentManagementCore.AttachedPrintedForms();
	For Each String In PrintForms Do
		FillPropertyValues(AttachedPrintedForms.Add(), String);
	EndDo;
	
	Return AttachedPrintedForms;
	
EndFunction

// Returns the structure of the object BEFORE to be filled in by the passed type name.
//
// Parameters:
//   ObjectTypeDM - String - the type of the object, for example, DMInternalDocument or DMCorrespondent.
//
// Returns:
//   Structure - the details of the object of the specified type to be filled in.
//
Function StructureOfTheAttributesOfTheFilledObjectDM(ObjectTypeDM) Export
	
	AttributesStructure1 = New Structure;
	ReferenceTypeAttributes = New Structure;
	
	// Banking details common to all types.
	AttributesStructure1.Insert("ID");
	AttributesStructure1.Insert("Type", ObjectTypeDM);
	AttributesStructure1.Insert("Description");
	AttributesStructure1.Insert("Comment");
	
	If ObjectTypeDM = "DMCorrespondent" Then
		
		AttributesStructure1.Insert("TIN");
		AttributesStructure1.Insert("CRTR");
		AttributesStructure1.Insert("NCBOCode");
		AttributesStructure1.Insert("FullDescr");
		
	Else // Documents.
		
		AttributesStructure1.Insert("Files", New Array);
		
		AttributesStructure1.Insert("LongDesc");
		AttributesStructure1.Insert("RegistrationNumber");
		AttributesStructure1.Insert("RegistrationDate");
		AttributesStructure1.Insert("TaskDueDate");
		AttributesStructure1.Insert("Sum");
		
		ReferenceTypeAttributes.Insert("SignedBy");
		ReferenceTypeAttributes.Insert("Department");
		ReferenceTypeAttributes.Insert("AccessBar");
		ReferenceTypeAttributes.Insert("DocumentKind");
		ReferenceTypeAttributes.Insert("QuestionOfActivity");
		ReferenceTypeAttributes.Insert("Organization");
		ReferenceTypeAttributes.Insert("EmployeeResponsible");
		ReferenceTypeAttributes.Insert("State");
		ReferenceTypeAttributes.Insert("StateApproval");
		ReferenceTypeAttributes.Insert("StateConfirmation");
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP")
				And ObjectTypeDM = "DMInternalDocument" Then
			ReferenceTypeAttributes.Insert("StateSigning");
		EndIf;
		ReferenceTypeAttributes.Insert("StateReviewal");
		ReferenceTypeAttributes.Insert("StateRegistration");
		ReferenceTypeAttributes.Insert("StatePerformance");
		ReferenceTypeAttributes.Insert("Currency");
		
		// Templates.
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.0.8.1") Then
			ReferenceTypeAttributes.Insert("Template");
		EndIf;
		
		// Projects.
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
			ReferenceTypeAttributes.Insert("Project");
		EndIf;
		
		// The composition of the document.
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
			ReferenceTypeAttributes.Insert("SheetQuantity");
			ReferenceTypeAttributes.Insert("NumberOfApplications");
			ReferenceTypeAttributes.Insert("SheetsInApplications");
			ReferenceTypeAttributes.Insert("Copies");
		EndIf;
		
		// Document storage.
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
			ReferenceTypeAttributes.Insert("CaseFileNomenclature");
			ReferenceTypeAttributes.Insert("ToDoItem");
		EndIf;
		
	EndIf;
	
	If ObjectTypeDM = "DMInternalDocument" Then
		
		AttributesStructure1.Insert("ValidityStartDate");
		AttributesStructure1.Insert("ValidityEndDate");
		AttributesStructure1.Insert("Permanent");
		
		ReferenceTypeAttributes.Insert("Addressee");
		ReferenceTypeAttributes.Insert("Folder");
		ReferenceTypeAttributes.Insert("Prepared");
		ReferenceTypeAttributes.Insert("Counterparty");
		ReferenceTypeAttributes.Insert("ContactPerson");
		ReferenceTypeAttributes.Insert("ExtensionProcedure");
		ReferenceTypeAttributes.Insert("Recipient");
		
		CFItems = New ValueTable;
		CFItems.Columns.Add("CFItem");
		CFItems.Columns.Add("CFItemID");
		CFItems.Columns.Add("CFItemType");
		CFItems.Columns.Add("Sum");
		CFItems.Columns.Add("VATAmount");
		
		AttributesStructure1.Insert("CFItems", CFItems);
		
		AttributesStructure1.Insert("VATAmount");
		
		Goods = New ValueTable;
		Goods.Columns.Add("Products");
		Goods.Columns.Add("ProductsID");
		Goods.Columns.Add("ProductsType");
		Goods.Columns.Add("Price");
		Goods.Columns.Add("Count");
		Goods.Columns.Add("UnitOfMeasure");
		Goods.Columns.Add("UnitOfMeasureID");
		Goods.Columns.Add("UnitOfMeasureType");
		Goods.Columns.Add("VATRate");
		Goods.Columns.Add("VATRateID");
		Goods.Columns.Add("VATRateType");
		Goods.Columns.Add("VATAmount");
		Goods.Columns.Add("Sum");
		
		AttributesStructure1.Insert("Goods", Goods);
		
		Parties = New ValueTable;
		Parties.Columns.Add("SignatureDate");
		Parties.Columns.Add("Comment");
		Parties.Columns.Add("ContactPerson");
		Parties.Columns.Add("ContactPersonID");
		Parties.Columns.Add("ContactPersonType");
		Parties.Columns.Add("Description");
		Parties.Columns.Add("DescriptionID");
		Parties.Columns.Add("DescriptionType");
		Parties.Columns.Add("SignedBy");
		Parties.Columns.Add("SignedByID");
		Parties.Columns.Add("SignedByType");
		Parties.Columns.Add("Signed");
		Parties.Columns.Add("Party");
		Parties.Columns.Add("PartyID");
		Parties.Columns.Add("PartyType");
		Parties.Columns.Add("Set");
		Parties.Columns.Add("SetID");
		Parties.Columns.Add("SetType");
		
		AttributesStructure1.Insert("Parties", Parties);
		
		Counterparties = New ValueTable;
		Counterparties.Columns.Add("Counterparty");
		Counterparties.Columns.Add("CounterpartyID");
		Counterparties.Columns.Add("CounterpartyType");
		Counterparties.Columns.Add("ContactPerson");
		Counterparties.Columns.Add("ContactPersonID");
		Counterparties.Columns.Add("ContactPersonType");
		Counterparties.Columns.Add("SignedFromCounterparty");
		Counterparties.Columns.Add("SignedFromCounterpartyID");
		Counterparties.Columns.Add("SignedFromCounterpartyType");
		
		AttributesStructure1.Insert("Counterparties", Counterparties);
		
	ElsIf ObjectTypeDM = "DMIncomingDocument" Then
		
		AttributesStructure1.Insert("SenderSNumber");
		AttributesStructure1.Insert("SenderDate");
		
		ReferenceTypeAttributes.Insert("Sender");
		ReferenceTypeAttributes.Insert("Addressee");
		ReferenceTypeAttributes.Insert("MethodOfObtaining");
		
	ElsIf ObjectTypeDM = "DMOutgoingDocument" Then
		
		AttributesStructure1.Insert("RecipientNumber");
		AttributesStructure1.Insert("RecipientDate");
		AttributesStructure1.Insert("Shipped_5");
		AttributesStructure1.Insert("DateSent");
		
		ReferenceTypeAttributes.Insert("Recipient");
		ReferenceTypeAttributes.Insert("Addressee");
		ReferenceTypeAttributes.Insert("Prepared");
		ReferenceTypeAttributes.Insert("SendingMethod");
		
	ElsIf ObjectTypeDM = "DMCorrespondent" Then
		
		ReferenceTypeAttributes.Insert("Person");
		ReferenceTypeAttributes.Insert("EmployeeResponsible");
		ReferenceTypeAttributes.Insert("LegalEntityIndividual");
		
	EndIf;
	
	// Expand the details of the reference type, adding their ID and type.
	For Each Attribute In ReferenceTypeAttributes Do
		
		AttributesStructure1.Insert(Attribute.Key, Attribute.Value);
		AttributesStructure1.Insert(Attribute.Key + "ID", Attribute.Value);
		AttributesStructure1.Insert(Attribute.Key + "Type", Attribute.Value);
		
	EndDo;
	
	// Marking the deletion.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.0.1") Then
		AttributesStructure1.Insert("DeletionMark");
	EndIf;
	
	// Fill in the additional properties.
	AdditionalProperties = New ValueTable;
	AdditionalProperties.Columns.Add("Property");
	AdditionalProperties.Columns.Add("PropertyType");
	AdditionalProperties.Columns.Add("PropertyID");
	AdditionalProperties.Columns.Add("Value");
	AdditionalProperties.Columns.Add("ValueType");
	AdditionalProperties.Columns.Add("ValueID");
	TypesArray = New Array;
	TypesArray.Add(Type("ValueList"));
	AdditionalProperties.Columns.Add("AvailableTypeList", New TypeDescription(TypesArray));
	
	AttributesStructure1.Insert("Properties", AdditionalProperties);
	
	Return AttributesStructure1;
	
EndFunction

// Fills in the default upload fill rules.
//
// Parameters:
//   FillingRules - Map of KeyAndValue - matching Attribute names to XDTO properties:
//     * Key - String - name of the prop.
//     * Value - String - the name of the XDTO property.
//   Receiver - String - the name of the XDTO-type of the receiver.
//   Source - String - the full name of the source metadata object.
//
Procedure SetDefaultFillingRulesForUploading(FillingRules, Receiver, Source) Export
	
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenSettingDefaultUploadFillRule(
		FillingRules,
		Receiver,
		Source,
		StandardProcessing);
	
	If StandardProcessing = False Then
		Return;
	EndIf;
	
	SourceMetadata = Metadata.FindByFullName(Source); // MetadataObjectDocument
	If SourceMetadata = Undefined Then
		Return;
	EndIf;
	
	FillingOptions = New Map;
	FillingOptions.Insert("Organization", "organization");
	FillingOptions.Insert("Counterparty", "correspondent");
	FillingOptions.Insert("Comment", "comment");
	FillingOptions.Insert("StartDate", "beginDate");
	FillingOptions.Insert("EndDate", "endDate");
	FillingOptions.Insert("TaskDueDate", "performanceDate");
	FillingOptions.Insert("Sum", "sum");
	FillingOptions.Insert("DocumentAmount", "sum");
	FillingOptions.Insert("Currency", "currency");
	FillingOptions.Insert("ARAPCurrency", "currency");
	FillingOptions.Insert("SettlementsCurrency", "currency");
	FillingOptions.Insert("DocumentCurrency", "currency");
	FillingOptions.Insert("Content", "summary");
	FillingOptions.Insert("RegistrationNumber", "regNumber");
	FillingOptions.Insert("RegistrationDate", "regDate");
	FillingOptions.Insert("Department_Company", "subdivision");
	FillingOptions.Insert("Department", "subdivision");
	FillingOptions.Insert("Approved_1", "signer");
	FillingOptions.Insert("Prepared", "author");
	FillingOptions.Insert("Author", "author");
	FillingOptions.Insert("ContactPerson", "contactPerson");
	FillingOptions.Insert("EmployeeResponsible", "responsible");
	FillingOptions.Insert("Description", "name");
	FillingOptions.Insert("DeletionMark", "deletionMark");
	FillingOptions.Insert("LegalEntityIndividual", "legalPrivatePerson");
	FillingOptions.Insert("TIN", "inn");
	FillingOptions.Insert("CRTR", "kpp");
	FillingOptions.Insert("NCBOCode", "okpo");
	FillingOptions.Insert("FullDescr", "fullName");
	FillingOptions.Insert("DescriptionFull", "fullName");
	FillingOptions.Insert("Individual", "privatePerson");
	FillingOptions.Insert("Person", "privatePerson");
	FillingOptions.Insert("EmployeeResponsible", "author");
	FillingOptions.Insert("Project", "project");
	
	FillingOptions.Insert("IncomingDocumentDate", "externalDate");
	FillingOptions.Insert("IncomingDocumentNumber", "externalNumber");
	
	For Each Attribute In SourceMetadata.StandardAttributes Do
		Value = FillingOptions.Get(Attribute.Name);
		If Value <> Undefined Then
			FillingRules.Insert(Value, Attribute.Name);
		EndIf;
	EndDo;
	
	For Each Attribute In SourceMetadata.Attributes Do
		Value = FillingOptions.Get(Attribute.Name);
		If Value <> Undefined Then
			FillingRules.Insert(Value, Attribute.Name);
		EndIf;
	EndDo;
	
EndProcedure

// Fills in the default fill-in rules when loading.
//
// Parameters:
//   FillingRules - Map of KeyAndValue - matching Attribute names to XDTO properties:
//     * Key - String - name of the prop.
//     * Value - String - the name of the XDTO property.
//   Receiver - String - the full name of the receiver metadata object.
//   Source - String - the name of the source's XDTO type.
//
Procedure SetDefaultFillInRulesWhenLoading(FillingRules, Receiver, Source) Export
	
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenSettingTheDefaultFillInRuleOnLoading(
		FillingRules,
		Receiver,
		Source,
		StandardProcessing);
	
	If StandardProcessing = False Then
		Return;
	EndIf;
	
	FillingOptions = New Map;
	
	ReceiverMetadata = Metadata.FindByFullName(Receiver); // MetadataObjectDocument
	If ReceiverMetadata = Undefined Then
		Return;
	EndIf;
	
	If Find(Source, "Document") <> 0 Then
		FillingOptions.Insert("Organization", "organization");
		FillingOptions.Insert("Counterparty", "correspondent");
		FillingOptions.Insert("Comment", "comment");
		FillingOptions.Insert("StartDate", "beginDate");
		FillingOptions.Insert("EndDate", "endDate");
		FillingOptions.Insert("TaskDueDate", "performanceDate");
		FillingOptions.Insert("Sum", "sum");
		FillingOptions.Insert("DocumentAmount", "sum");
		FillingOptions.Insert("Currency", "currency");
		FillingOptions.Insert("ARAPCurrency", "currency");
		FillingOptions.Insert("SettlementsCurrency", "currency");
		FillingOptions.Insert("DocumentCurrency", "currency");
		FillingOptions.Insert("Content", "summary");
		FillingOptions.Insert("RegistrationNumber", "regNumber");
		FillingOptions.Insert("RegistrationDate", "regDate");
		FillingOptions.Insert("Department_Company", "subdivision");
		FillingOptions.Insert("Department", "subdivision");
		FillingOptions.Insert("Approved_1", "signer");
		FillingOptions.Insert("Prepared", "author");
		FillingOptions.Insert("Author", "author");
		FillingOptions.Insert("ContactPerson", "contactPerson");
		FillingOptions.Insert("EmployeeResponsible", "responsible");
		FillingOptions.Insert("Description", "title");
		FillingOptions.Insert("DeletionMark", "deletionMark");
		FillingOptions.Insert("Status", "statusApproval");
		FillingOptions.Insert("Approved", "statusApproval");
		
		FillingOptions.Insert("IncomingDocumentDate", "externalDate");
		FillingOptions.Insert("IncomingDocumentNumber", "externalNumber");
		
	ElsIf Source = "DMCorrespondent" Then
		FillingOptions.Insert("Description", "name");
		FillingOptions.Insert("DeletionMark", "deletionMark");
		FillingOptions.Insert("EmployeeResponsible", "responsible");
		FillingOptions.Insert("LegalEntityIndividual", "legalPrivatePerson");
		FillingOptions.Insert("TIN", "inn");
		FillingOptions.Insert("CRTR", "kpp");
		FillingOptions.Insert("NCBOCode", "okpo");
		FillingOptions.Insert("FullDescr", "fullName");
		FillingOptions.Insert("DescriptionFull", "fullName");
		FillingOptions.Insert("Individual", "privatePerson");
		FillingOptions.Insert("Person", "privatePerson");
	EndIf;
	
	For Each Attribute In ReceiverMetadata.StandardAttributes Do
		If FillingOptions[Attribute.Name] <> Undefined Then
			FillingRules[Attribute.Name] =
				IntegrationWith1CDocumentManagementCore.RuleForFillingInFromObjectAttributesTO(
					FillingOptions[Attribute.Name]);
		EndIf;
	EndDo;
	
	For Each Attribute In ReceiverMetadata.Attributes Do
		If FillingOptions[Attribute.Name] <> Undefined Then
			FillingRules[Attribute.Name] =
				IntegrationWith1CDocumentManagementCore.RuleForFillingInFromObjectAttributesTO(
					FillingOptions[Attribute.Name]);
		EndIf;
	EndDo;
	
EndProcedure

// Returns a description of the 1C web service:Document management.
//
// Returns:
//   String
//
Function WebServiceDescription() Export
	
	Template = Catalogs.RulesForIntegrationWith1CDocumentManagement.GetTemplate("WebServiceDescription");
	
	Return Template.GetText();
	
EndFunction

// Checks for the presence of related objects, if there are none, gets information about them from the Workflow.
//
Procedure CheckUpdateRelatedObjectData() Export
	
	Query = New Query(
		"SELECT TOP 1
		|	ObjectsIntegratedWith1CDocumentManagement.Object
		|FROM
		|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement");
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Return;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetLinkedObjectsRequest");
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	RecordSet = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.CreateRecordSet();
	
	For Each XDTODataObject In Response.objects Do
		Objects = IntegrationWith1CDocumentManagementCore.LinksToExternalObjects(XDTODataObject);
		For Each Object In Objects Do
			Record = RecordSet.Add();
			Record.ObjectIDDM = XDTODataObject.objectID.ID;
			Record.ObjectTypeDM = XDTODataObject.objectID.type;
			Record.Object = Object;
		EndDo;
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

#EndRegion

#Region ProcessesAndTasks_

// Checks if the item has any outstanding tasks.
//
// Parameters:
//   ID - String - item ID.
//   Type - String - type XDTO-item type.
//
// Returns:
//   Boolean
//
Function ThereAreTasks(ID, Type) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetTasksTreeRequest");
	Filter = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetTasksTreeQuery");
	SelectionOfSubjects = Filter.target; // XDTOList
	
	SubjectOf = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMObject");
	SubjectOf.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		ID,
		Type);
	SubjectOf.name = "";
	SelectionOfSubjects.Add(SubjectOf);
	
	Query.query = Filter;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	ThereAreTasks = False;
	For Each XDTOBusinessProcess In Response.businessProcesses Do
		For Each XDTOTask In XDTOBusinessProcess.tasks Do
			If XDTOTask.executed = False Then
				ThereAreTasks = True;
				Break;
			EndIf;
		EndDo;
		If ThereAreTasks Then
			Break;
		EndIf;
	EndDo;
	
	Return ThereAreTasks;
	
EndFunction

// Fills in a business process form based on a template.
//
// Parameters:
//   Form - ClientApplicationForm - 1C business process form:Document management.
//   TemplateData_ - Structure:
//     * AttributeID - String - id of the 1C template:Document management.
//     * AttributeType - String - the type of the XDTO template.
//
// Returns:
//   XDTODataObject - a business process filled in according to a template.
//
Function FillInBusinessProcessUsingTemplate(Val Form, Val TemplateData_) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMGetBusinessProcessByTemplateRequest");
	
	Query.type = Form.Type;
	
	If ValueIsFilled(Form.SubjectOf)Then
		
		SubjectOfBusinessProcessID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			Form.SubjectOfID,
			Form.SubjectOfType);
		
		Query.targetID = SubjectOfBusinessProcessID;
		
	EndIf;
	
	IDBusinessProcessTemplate = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		TemplateData_.AttributeID,
		TemplateData_.AttributeType);
	
	Query.businessProcessTemplateID = IDBusinessProcessTemplate;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	Return Result;
	
EndFunction

// Saves and starts the business process.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Object - XDTODataObject - XDTO is an object that stores business process data.
//
// Returns:
//   XDTODataObject - An object of type DMLaunchBusinessProcessResponse.
//
Function StartBusinessProcess(Proxy, Object) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMLaunchBusinessProcessRequest");
	Query.businessProcess = Object;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	Return Response;
	
EndFunction

// Returns the index of the process or task completion tag image by the tag value.
//
// Parameters:
//   Value - String - the value of the tag.
//
// Returns:
//   Number - index of the image.
//
Function IndexOfCompletionTagImage(Value) Export
	
	If Value = "NotExecuted" Then
		Return 0;
		
	ElsIf Value = "Stopped" Then
		Return 1;
		
	ElsIf Value = "Interrupted" Then
		Return 2;
		
	ElsIf Value = "ReadyToStart" Then
		Return 3;
		
	ElsIf Value = "StartCanceled" Then
		Return 4;
		
	ElsIf Value = "ExecutedNeutral" Then
		Return 5;
		
	ElsIf Value = "ExecutedNegative" Then
		Return 6;
		
	ElsIf Value = "ExecutedAlmostPositive" Then
		Return 7;
		
	ElsIf Value = "ExecutedPositive" Then
		Return 8;
		
	ElsIf Value = "ReadyToExecute" Then
		Return 9;
		
	ElsIf Value = "ExecutionCanceled" Then
		Return 10;
		
	Else
		Return -1;
		
	EndIf;
	
EndFunction

// Returns the short name of the route point.
//
// Parameters:
//   Process_Type - String - type of process.
//   FullName - String - full name of the route point
//
// Returns:
//   String - the short name of the route point.
//
Function ShortRoutePointName(Process_Type, FullName) Export
	
	If Process_Type = "DMBusinessProcessApproval" Then
		If FullName = "Ознакомиться с результатом согласования" Then //@NON-NLS-1
			ShortName = "Ознакомиться"; //@NON-NLS-1
		Else
			ShortName = FullName;
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessOrder" Then
		If FullName = "Контролировать поручение" Then //@NON-NLS-1
			ShortName = "Контролировать"; //@NON-NLS-1
		ElsIf FullName = "Проверить поручение" Then //@NON-NLS-1
			ShortName = "Проверить"; //@NON-NLS-1
		Else
			ShortName = FullName;
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessPerformance" Then
		If FullName = "Ответственное исполнение" Then //@NON-NLS-1
			ShortName = "ОтветственноеИсполнение"; //@NON-NLS-1
		ElsIf FullName = "Контролировать исполнение" Then //@NON-NLS-1
			ShortName = "Контролировать"; //@NON-NLS-1
		ElsIf FullName = "Проверить исполнение" Then //@NON-NLS-1
			ShortName = "Проверить"; //@NON-NLS-1
		Else
			ShortName = FullName;
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessRegistration" Then
		If FullName = "Ознакомиться с регистрацией" Then //@NON-NLS-1
			ShortName = "Ознакомиться"; //@NON-NLS-1
		Else
			ShortName = FullName;
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessConfirmation" Then
		If Find(FullName, "Ознакомиться с результатом утверждения") <> 0 Then //@NON-NLS-1
			ShortName = "Ознакомиться"; //@NON-NLS-1
		Else
			ShortName = FullName;
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessConsideration" Then
		If FullName = "Обработать резолюцию" Then //@NON-NLS-1
			ShortName = "Ознакомиться"; //@NON-NLS-1
		Else
			ShortName = FullName;
		EndIf;
		
	ElsIf Process_Type = "DMComplexBusinessProcess" Then
		If FullName = "Контролировать ход процесса" Then //@NON-NLS-1
			ShortName = "Контролировать"; //@NON-NLS-1
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessIncomingDocumentProcessing" Then
		If FullName = "Исполнение \ ознакомление" Then //@NON-NLS-1
			ShortName = "ИсполнениеОзнакомление"; //@NON-NLS-1
		ElsIf FullName = "В дело" Then //@NON-NLS-1
			ShortName = "ВДело"; //@NON-NLS-1
		Else
			ShortName = FullName;
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessInternalDocumentProcessing" Then
		If FullName = "Рассмотрение" Then //@NON-NLS-1
			ShortName = "ВложенныйПроцесс1"; //@NON-NLS-1
		ElsIf FullName = "Исполнение \ ознакомление" Then //@NON-NLS-1
			ShortName = "ВложенныйПроцесс2"; //@NON-NLS-1
		ElsIf FullName = "В дело" Then //@NON-NLS-1
			ShortName = "ВложенныйПроцесс3"; //@NON-NLS-1
		Else
			ShortName = FullName;
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessIssuesSolution" Then
		If FullName = "Рассмотреть вопрос" Then //@NON-NLS-1
			ShortName = "РассмотрениеИнициатором"; //@NON-NLS-1
		ElsIf FullName = "Ознакомиться с результатом рассмотрения" Then //@NON-NLS-1
			ShortName = "ОзнакомлениеСРезультатомРассмотрения"; //@NON-NLS-1
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessInvitation" Then
		If FullName = "Пригласить" Then //@NON-NLS-1
			ShortName = "Пригласить"; //@NON-NLS-1
		ElsIf FullName = "Ознакомиться с результатом приглашения" Then //@NON-NLS-1
			ShortName = "Ознакомиться"; //@NON-NLS-1
		ElsIf FullName = "Оповестить о результатах приглашения" Then //@NON-NLS-1
			ShortName = "Оповестить"; //@NON-NLS-1
		EndIf;
		
	Else
		ShortName = FullName;
	EndIf;
	
	Return ShortName;
	
EndFunction

// Gets the XDTO object of the business process.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Type - String - type of business process.
//   SubjectOf - Structure:
//     * ID - String - item ID.
//     * type - String - item type.
//
// Returns:
//   XDTODataObject, Undefined - XDTO is an object with a business process of the specified type.
//
Function NewBusinessProcess(Proxy, Type, SubjectOf = Undefined) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMGetNewBusinessProcessRequest");
	
	Query.type = Type;
	If SubjectOf <> Undefined Then
		Query.targetID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			SubjectOf.ID,
			SubjectOf.type);
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(
			Proxy, Response, "DMGetNewBusinessProcessResponse") Then
		Return Response.object;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Gets the XDTO object of the business process, filled in according to the data of the transferred subject and template.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Type - String - type of business process.
//   Template - Structure:
//     * ID - String - template ID.
//     * type - String - template type.
//   SubjectOf - Structure:
//     * ID - String - item ID.
//     * type - String - item type.
//
// Returns:
//   XDTODataObject - XDTO object with the type of business process.
//
Function NewBusinessProcessByTemplate(Proxy, Type, Template, SubjectOf = Undefined) Export
	
	// Creating a business process
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetBusinessProcessByTemplateRequest");
	
	Query.type = Type;
	
	IDBusinessProcessTemplate = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Template.ID,
		Template.type);
	
	Query.businessProcessTemplateID = IDBusinessProcessTemplate;
	
	If ValueIsFilled(SubjectOf) Then
		SubjectOfBusinessProcessID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			SubjectOf.ID,
			SubjectOf.type);
		
		Query.targetID = SubjectOfBusinessProcessID;
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	Return Response.Object;
	
EndFunction

// Performs the cancellation of accepting tasks for execution.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Var_Tasks - Array of String - an array of ids of workflow tasks
//     that need to be canceled for execution.
//
// Returns:
//   Boolean - a sign of success in canceling the acceptance of tasks for execution.
//
Function CancelAcceptTasksForExecution(Proxy, Var_Tasks) Export
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
		
		If Proxy = Undefined Then
			Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		EndIf;
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRevokeTaskAcceptanceRequest");
		TaskList = Query.tasks; // XDTOList
		
		For Each ID In Var_Tasks Do
			XDTOTask = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObject");
			XDTOTask.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				ID,
				"DMBusinessProcessTask");
			XDTOTask.name = "";
			TaskList.Add(XDTOTask);
		EndDo;
		
		Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		
		Try
			IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
			Return True;
		Except
			Return False;
		EndTry;
		
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns the XDTO object of the business process, filled in according to the parameters.
//
// Parameters:
//   ProcessTypeXDTO - String - type of business process.
//   Parameters - Structure:
//     * ID - String - ID of the business process.
//     * type - String - type of business process.
//     * Template - Structure:
//         ** ID - String - template ID.
//         ** type - String - template type.
//     * SubjectOf - Structure:
//         ** ID - String - item ID.
//         ** type - String - item type.
//
// Returns:
//   XDTODataObject
//
Function GetProcessXDTOObject(ProcessTypeXDTO, Parameters) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	// If a new card opens according to the completed template.
	If ValueIsFilled(Parameters.ID) And ValueIsFilled(Parameters.type) Then
		XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			Parameters.type,
			Parameters.ID);
		
	ElsIf Parameters.Property("Template") Then
		If Parameters.Property("SubjectOf") Then
			XDTODataObject = NewBusinessProcessByTemplate(Proxy, ProcessTypeXDTO, Parameters.Template, Parameters.SubjectOf);
		Else
			XDTODataObject = NewBusinessProcessByTemplate(Proxy, ProcessTypeXDTO, Parameters.Template);
		EndIf;
		
	Else
		If Parameters.Property("SubjectOf") Then
			XDTODataObject = NewBusinessProcess(
				Proxy,
				ProcessTypeXDTO,
				Parameters.SubjectOf);
		Else
			XDTODataObject = NewBusinessProcess(
				Proxy,
				ProcessTypeXDTO);
		EndIf;
		
	EndIf;
	
	Return XDTODataObject;
	
EndFunction

// Gets the approval status in the UP by reference to the IP object
//
// Parameters:
//   SubjectOfApproval - AnyRef - reference to the IP object.
//   Explanation - String - an implicitly returned value, an explanation of the state.
//
// Returns:
//   EnumRef.ApprovalStatesIn1CDocumentManagement - approval status or
//   Undefined - if object matching is not started.
//
Function GetApprovalState(Val SubjectOfApproval, Explanation = "") Export
	
	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	ApprovalStates.State AS State,
		|	ApprovalStates.Set AS Set,
		|	ApprovalStates.InstallationDate AS InstallationDate
		|FROM
		|	InformationRegister.ApprovalStatesIn1CDocumentManagement AS ApprovalStates
		|		INNER JOIN InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS
		|			ObjectsIntegratedWith1CDocumentManagement
		|		ON ApprovalStates.ObjectIDDM = ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM
		|WHERE
		|	ObjectsIntegratedWith1CDocumentManagement.Object = &SubjectOfApproval");
	Query.SetParameter("SubjectOfApproval", SubjectOfApproval);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Explanation = ExplanationOfApprovalState(Selection.Set, Selection.InstallationDate);
		Return Selection.State;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Receives an explanation of the approval status intended for reading by the user.
//
// Parameters:
//   Set - String - a representation of the user who has set the new state.
//   InstallationDate - Date - date and time when the new state was set.
//
// Returns:
//   String - explanation of the approval status.
//
Function ExplanationOfApprovalState(Set, InstallationDate) Export
	
	Result = "";
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingCurrentStateOfApproval(
		Set, InstallationDate, Result);
	If Result <> "" Then
		Return Result;
	EndIf;
	
	If ValueIsFilled(InstallationDate) Then
		Result = Format(InstallationDate, "DLF=DT");
		If ValueIsFilled(Set) Then
			Result = Result + " (" + TrimAll(Set) + ")";
		EndIf;
	Else
		If ValueIsFilled(Set) Then
			Result = Set;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Performs the acceptance of tasks for execution.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Var_Tasks - Array of String - an array of ids of workflow tasks that need to be accepted for execution.
//
// Returns:
//   Boolean - a sign of success in accepting tasks for execution.
//
Function AcceptTaskForExecution(Proxy, Var_Tasks) Export
	
	If Proxy = Undefined Then
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	EndIf;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMAcceptTasksRequest");
	TaskList = Query.tasks; // XDTOList
	
	For Each ID In Var_Tasks Do
		XDTOTask = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObject");
		XDTOTask.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			ID,
			"DMBusinessProcessTask");
		XDTOTask.name = "";
		TaskList.Add(XDTOTask);
	EndDo;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	
	Try
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
		Return True;
	Except
		Return False;
	EndTry;

EndFunction

// Returns a structure describing the execution options of the task.
//
// Parameters:
//   TaskDetails__ - Structure:
//     * TaskType - String - the task type is a string.
//     * TaskID - String - the ID of the task.
//     * Process_Type - String - name of the process type.
//     * Process_ID - String - process ID.
//     * RoutePointBriefly - String - route point.
//     * Executed - Boolean - a sign of task completion.
//     * TypeOfQuestionID - String - the type of question of the route point is "Consideration by the initiator".
//     * ResultID - String - the result of the task.
//
// Returns:
//   Structure:
//     * FunctionalityNotAvailable - Boolean - a sign of the availability of the task execution functionality in this version BEFORE.
//     * ExecuteTaskFirst - String - the title of the first button.
//     * TextColorFirst - Color - the color of the first button.
//     * ExecuteTaskSecond - String - the title of the second button.
//     * TextColorSecond - Color - the color of the second button.
//     * ExecuteTaskThird - String - the title of the third button.
//     * TextColorThird - Color - the color of the third button.
//
Function TaskExecutionStructure(Val TaskDetails__) Export
	
	Result = New Structure;
	Result.Insert("FunctionalityNotAvailable", False);
	Result.Insert("ExecuteTaskFirst", "");
	Result.Insert("ExecuteTaskSecond", "");
	Result.Insert("ExecuteTaskThird", "");
	Result.Insert("TextColorFirst", StyleColors.PositiveTaskCompletionFlag);
	Result.Insert("TextColorSecond", New Color);
	Result.Insert("TextColorThird", StyleColors.NegativeTaskCompletionFlag);
	
	If TaskDetails__.Executed Then
		Return Result;
	EndIf;
	
	If TaskDetails__.RoutePointBriefly = "РассмотрениеИнициатором" And TaskDetails__.TypeOfQuestionID = "ПереносСрока"
			And Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then //@NON-NLS-1 @NON-NLS-2
		Result.FunctionalityNotAvailable = True;
		Return Result;
	EndIf;
	
	If TaskDetails__.State = "Остановлен" Or TaskDetails__.State = "Прерван" Then //@NON-NLS-1 @NON-NLS-2
		Return Result;
	EndIf;
	
	// Agreement.
	If TaskDetails__.Process_Type = "DMBusinessProcessApproval" Then
		If TaskDetails__.RoutePointBriefly = "Согласовать" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã thống nhất';
													|ru = 'Согласовано';
													|en = 'Approved'; fa = 'تأییدشده';
													|it = 'Concordato';
													|pl = 'Uzgodniono';
													|tr = 'Onaylandı'"));
			Result.Insert("ExecuteTaskSecond", NStr("vi = 'Đã thống nhất
																|và có lưu ý';
																|ru = 'Согласовано
																|с замечаниями';
																|en = 'Approved with 
																|comments'; fa = 'Approved with 
																|comments';
																|it = 'Omologato
																| con note';
																|pl = 'Uzgodniono
																|z uwagami';
																|tr = 'Yorumlarla
																|onaylandı'"));
			Result.Insert("TextColorSecond", StyleColors.PositiveTaskCompletionFlag);
			Result.Insert("ExecuteTaskThird", NStr("vi = 'Không thống nhất';
													|ru = 'Не согласовано';
													|en = 'Not approved'; fa = 'تأییدنشده';
													|it = 'Non concordato';
													|pl = 'Nie uzgodniono';
													|tr = 'Onaylanmadı'"));
			
		ElsIf TaskDetails__.RoutePointBriefly = "Ознакомиться" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã tham khảo';
													|ru = 'Ознакомился';
													|en = 'I have read and understood'; fa = 'مطالعه کردم و متوجه شدم';
													|it = 'Esaminato';
													|pl = 'I have read and understood';
													|tr = 'İncelendi'"));
			
			If TaskDetails__.ResultID = "НеСогласовано" Then //@NON-NLS-1
				
				Result.ExecuteTaskFirst = NStr("vi = 'Kết thúc thống nhất';
												|ru = 'Завершить согласование';
												|en = 'Complete approval'; fa = 'Complete approval';
												|it = 'Completare omologazione';
												|pl = 'Zakończ uzgodnienie';
												|tr = 'Onaylamayı tamamla'");
				Result.Insert("ExecuteTaskSecond", NStr("vi = 'Thống nhất lại...';
														|ru = 'Повторить согласование...';
														|en = 'Repeat approval...'; fa = 'Repeat approval...';
														|it = 'Ripetere omologazione...';
														|pl = 'Powtórz uzgodnienie...';
														|tr = 'Onaylamayı tekrarla...'"));
				Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
				
			EndIf;
		EndIf;
		
	// Statement.
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessConfirmation" Then
		If TaskDetails__.RoutePointBriefly = "Утвердить" Then //@NON-NLS-1
			
			If TaskDetails__.ThisIsSigning Then
				Result.Insert("ExecuteTaskFirst", NStr("vi = 'Ký tên';
														|ru = 'Подписать';
														|en = 'Sign'; fa = 'امضا';
														|it = 'Firmare';
														|pl = 'Sign';
														|tr = 'İmzala'"));
				Result.Insert("ExecuteTaskSecond", NStr("vi = 'Từ chối';
														|ru = 'Отклонить';
														|en = 'Reject'; fa = 'رد';
														|it = 'Declinare';
														|pl = 'Reject';
														|tr = 'Reddet'"));
			Else
				Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã duyệt';
														|ru = 'Утверждено';
														|en = 'Confirmed'; fa = 'تأییدشده';
														|it = 'Confermato';
														|pl = 'Confirmed';
														|tr = 'Onaylandı'"));
				Result.Insert("ExecuteTaskSecond", NStr("vi = 'Không duyệt';
														|ru = 'Не утверждено';
														|en = 'Not confirmed'; fa = 'تصدیق‌نشده';
														|it = 'Non confermato';
														|pl = 'Nie zatwierdzono';
														|tr = 'Onaylanmadı'"));
			EndIf;
			Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
			
		ElsIf TaskDetails__.RoutePointBriefly = "Ознакомиться" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã tham khảo';
													|ru = 'Ознакомился';
													|en = 'I have read and understood'; fa = 'مطالعه کردم و متوجه شدم';
													|it = 'Esaminato';
													|pl = 'I have read and understood';
													|tr = 'İncelendi'"));
			If TaskDetails__.ResultID = "НеУтверждено" Then //@NON-NLS-1
				
				If TaskDetails__.ThisIsSigning Then
					Result.ExecuteTaskFirst = NStr("vi = 'Hoàn thành ký tên';
													|ru = 'Завершить подписание';
													|en = 'Complete signature'; fa = 'Complete signature';
													|it = 'Completare firma';
													|pl = 'Zakończ podpisanie';
													|tr = 'İmzalamayı tamamla'");
					Result.Insert("ExecuteTaskSecond", NStr("vi = 'Ký lại...';
															|ru = 'Повторить подписание...';
															|en = 'Repeat signature...'; fa = 'Repeat signature...';
															|it = 'Ripetere firma...';
															|pl = 'Powtórz podpisanie...';
															|tr = 'İmzalamayı tekrarla...'"));
				Else
					Result.ExecuteTaskFirst = NStr("vi = 'Hoàn thành phê duyệt';
													|ru = 'Завершить утверждение';
													|en = 'Complete confirmation'; fa = 'Complete confirmation';
													|it = 'Completare conferma';
													|pl = 'Zakończ zatwierdzenie';
													|tr = 'Onaylamayı tamamla'");
					Result.Insert("ExecuteTaskSecond", NStr("vi = 'Duyệt lại...';
															|ru = 'Повторить утверждение...';
															|en = 'Repeat confirmation...'; fa = 'Repeat confirmation...';
															|it = 'Ripetere conferma...';
															|pl = 'Potwierdź zatwierdzenie...';
															|tr = 'Onaylamayı tekrarla...'"));
				EndIf;
				Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
				
			EndIf;
			
		EndIf;
		
	// Consideration.
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessConsideration" Then
		If TaskDetails__.RoutePointBriefly = "Рассмотреть" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã xem xét';
													|ru = 'Рассмотрено';
													|en = 'Reviewed'; fa = 'بررسی‌شده';
													|it = 'Analizzato';
													|pl = 'Reviewed';
													|tr = 'İncelendi'"));
			
		ElsIf TaskDetails__.RoutePointBriefly = "Ознакомиться" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã xử lý';
													|ru = 'Обработано';
													|en = 'Processed'; fa = 'پردازش‌شده';
													|it = 'Elaborato';
													|pl = 'Processed';
													|tr = 'İşlendi'"));
			
		EndIf;
		
	// An errand.
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessOrder" Then
		If TaskDetails__.RoutePointBriefly = "Выполнить" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã thực hiện';
													|ru = 'Выполнено';
													|en = 'Completed'; fa = 'تکمیل‌شده';
													|it = 'Completato';
													|pl = 'Completed';
													|tr = 'Gerçekleştirildi'"));
			
		ElsIf TaskDetails__.RoutePointBriefly = "Проверить" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Hoàn thành ủy nhiệm';
													|ru = 'Завершить поручение';
													|en = 'Complete the order'; fa = 'Complete the order';
													|it = 'Terminare commissione';
													|pl = 'Zakończ polecenie';
													|tr = 'Görevi tamamla'"));
			Result.Insert("ExecuteTaskSecond", NStr("vi = 'Trả lại để hoàn thiện';
													|ru = 'Вернуть на доработку';
													|en = 'Return for revision'; fa = 'Return for revision';
													|it = 'Restituire in rilavorazione';
													|pl = 'Zwróć na dopracowanie';
													|tr = 'Revizyona gönder'"));
			Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
			
		ElsIf TaskDetails__.RoutePointBriefly = "Контролировать" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Bỏ kiểm soát';
													|ru = 'Снять с контроля';
													|en = 'Remove from control'; fa = 'Remove from control';
													|it = 'Rimuovere dal controllo';
													|pl = 'Usuń z kontroli';
													|tr = 'Kontrolden kaldır'"));
			
		EndIf;
		
	// Execution.
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessPerformance" Then
		If TaskDetails__.RoutePointBriefly = "Исполнить"
				Or TaskDetails__.RoutePointBriefly = "ОтветственноеИсполнение" Then //@NON-NLS-1 @NON-NLS-2
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã thực hiện';
													|ru = 'Исполнено';
													|en = 'Committed'; fa = 'Committed';
													|it = 'Eseguito';
													|pl = 'Committed';
													|tr = 'Yürütüldü'"));
			
		ElsIf TaskDetails__.RoutePointBriefly = "Контролировать" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Bỏ kiểm soát';
													|ru = 'Снять с контроля';
													|en = 'Remove from control'; fa = 'Remove from control';
													|it = 'Rimuovere dal controllo';
													|pl = 'Usuń z kontroli';
													|tr = 'Kontrolden kaldır'"));
			
		ElsIf TaskDetails__.RoutePointBriefly = "Проверить" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Kết thúc';
													|ru = 'Завершить';
													|en = 'Finish'; fa = 'پایان';
													|it = 'Completare';
													|pl = 'Finish';
													|tr = 'Tamamla'"));
			Result.Insert("ExecuteTaskSecond", NStr("vi = 'Trả lại...';
													|ru = 'Вернуть...';
													|en = 'Return...'; fa = 'Return...';
													|it = 'Restituire...';
													|pl = 'Return...';
													|tr = 'Geri al...'"));
			Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
			
		EndIf;
	ElsIf TaskDetails__.Process_Type = "DMComplexBusinessProcess" Then
		If TaskDetails__.RoutePointBriefly = "Контролировать" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã kiểm soát';
													|ru = 'Проконтролировано';
													|en = 'Controlled'; fa = 'Controlled';
													|it = 'Controllato';
													|pl = 'Controlled';
													|tr = 'Kontrollü'"));
			
		EndIf;
		
	// Registration.
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessRegistration" Then
		If TaskDetails__.RoutePointBriefly = "Зарегистрировать" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đăng ký';
													|ru = 'Зарегистрировать';
													|en = 'Register'; fa = 'ثبات';
													|it = 'Registra';
													|pl = 'Register';
													|tr = 'Kayıt ol'"));
			Result.Insert("ExecuteTaskSecond", NStr("vi = 'Chưa đăng ký';
													|ru = 'Не регистрировать';
													|en = 'Do not register'; fa = 'ثبت نشود';
													|it = 'Non registrare';
													|pl = 'Nie rejestruj';
													|tr = 'Kayıt yaptırma'"));
			Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
			
		ElsIf TaskDetails__.RoutePointBriefly = "Ознакомиться" Then //@NON-NLS-1
			If TaskDetails__.ResultID = "НеЗарегистрировано" Then //@NON-NLS-1
				
				Result.Insert("ExecuteTaskFirst", NStr("vi = 'Hoàn thành đăng ký';
														|ru = 'Завершить регистрацию';
														|en = 'Complete registration'; fa = 'Complete registration';
														|it = 'Completare registrazione';
														|pl = 'Zakończ rejestrację';
														|tr = 'Kaydı tamamla'"));
				Result.Insert("ExecuteTaskSecond", NStr("vi = 'Đăng ký lại';
														|ru = 'Повторить регистрацию';
														|en = 'Repeat registration'; fa = 'Repeat registration';
														|it = 'Ripetere registrazione';
														|pl = 'Powtórz rejestrację';
														|tr = 'Kaydı tekrarla'"));
				Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
				
			Else
				Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã tham khảo';
														|ru = 'Ознакомился';
														|en = 'I have read and understood'; fa = 'مطالعه کردم و متوجه شدم';
														|it = 'Esaminato';
														|pl = 'I have read and understood';
														|tr = 'İncelendi'"));
			EndIf;
		EndIf;
		
	// Familiarization.
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessAcquaintance" Then
		If TaskDetails__.RoutePointBriefly = "Ознакомиться" Then //@NON-NLS-1
			
			Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã tham khảo';
													|ru = 'Ознакомился';
													|en = 'I have read and understood'; fa = 'مطالعه کردم و متوجه شدم';
													|it = 'Esaminato';
													|pl = 'I have read and understood';
													|tr = 'İncelendi'"));
			
		EndIf;
		
	// Solving issues.
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessIssuesSolution" Then
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3") Then
			If TaskDetails__.RoutePointBriefly = "РассмотрениеИнициатором"
					And TaskDetails__.TypeOfQuestionID = "Иное" Then //@NON-NLS-1 @NON-NLS-2
				
				Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã xem xét';
														|ru = 'Рассмотрено';
														|en = 'Reviewed'; fa = 'بررسی‌شده';
														|it = 'Analizzato';
														|pl = 'Reviewed';
														|tr = 'İncelendi'"));
				
			ElsIf TaskDetails__.RoutePointBriefly = "РассмотрениеИнициатором"
					And TaskDetails__.TypeOfQuestionID = "ПереносСрока" Then //@NON-NLS-1 @NON-NLS-2
				
				Result.Insert("ExecuteTaskFirst", NStr("vi = 'Gia hạn';
														|ru = 'Перенести срок';
														|en = 'Move deadline'; fa = 'Move deadline';
														|it = 'Spostare termine';
														|pl = 'Przenieś termin';
														|tr = 'Tarihi taşı'"));
				Result.Insert("ExecuteTaskSecond", NStr("vi = 'Từ chối gia hạn';
														|ru = 'Отказать в переносе';
														|en = 'Refuse to move'; fa = 'Refuse to move';
														|it = 'Rifiutare il trasferimento';
														|pl = 'Odmów w przenoszeniu';
														|tr = 'Aktarmada reddet'"));
				Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
				
			ElsIf TaskDetails__.RoutePointBriefly = "ОзнакомлениеСРезультатомРассмотрения" Then //@NON-NLS-1
				
				Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đóng câu hỏi';
														|ru = 'Закрыть вопрос';
														|en = 'Close issue'; fa = 'Close issue';
														|it = 'Chiudere domanda';
														|pl = 'Zamknij sprawę';
														|tr = 'Soruyu kapat'"));
				Result.Insert("ExecuteTaskSecond", NStr("vi = 'Làm rõ';
														|ru = 'Уточнить';
														|en = 'Specify'; fa = 'تعیین';
														|it = 'Specificare';
														|pl = 'Specify';
														|tr = 'Kesinleştir'"));
				Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
				
			Else
				Result.FunctionalityNotAvailable = True;
				Return Result;
			EndIf;
		EndIf;
		
	// Invitation.
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessInvitation" Then
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3") Then
			If TaskDetails__.RoutePointBriefly = "Пригласить" Then //@NON-NLS-1
				
				Result.Insert("ExecuteTaskFirst", NStr("vi = 'Nhận lời mời';
														|ru = 'Принять приглашение';
														|en = 'Accept invitation'; fa = 'Accept invitation';
														|it = 'Accettare invito';
														|pl = 'Przyjmij zaproszenie';
														|tr = 'Daveti kabul et'"));
				Result.Insert("ExecuteTaskSecond", NStr("vi = 'Hủy lời mời';
														|ru = 'Отклонить приглашение';
														|en = 'Reject invitation'; fa = 'Reject invitation';
														|it = 'Rifiutare invito';
														|pl = 'Odrzuć zaproszenie';
														|tr = 'Daveti reddet'"));
				Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
				
			ElsIf TaskDetails__.RoutePointBriefly = "Ознакомиться" Then //@NON-NLS-1
				// Depends on the outcome of acceptance.
				If TaskDetails__.ResultID = "ПринятоВсемиУчастниками" Then //@NON-NLS-1
					
					Result.Insert("ExecuteTaskFirst", NStr("vi = 'Xác nhận lời mời';
															|ru = 'Подтвердить приглашения';
															|en = 'Confirm invitations'; fa = 'Confirm invitations';
															|it = 'Confermare invito';
															|pl = 'Zatwierdź zaproszenia';
															|tr = 'Daveti onayla'"));
					
				ElsIf TaskDetails__.ResultID = "ПринятоОбязательнымиУчастниками" Then //@NON-NLS-1
					
					Result.Insert("ExecuteTaskFirst", NStr("vi = 'Xác nhận lời mời';
															|ru = 'Подтвердить приглашения';
															|en = 'Confirm invitations'; fa = 'Confirm invitations';
															|it = 'Confermare invito';
															|pl = 'Zatwierdź zaproszenia';
															|tr = 'Daveti onayla'"));
					Result.Insert("ExecuteTaskSecond", NStr("vi = 'Mời lại...';
															|ru = 'Повторить приглашение...';
															|en = 'Repeat invitation ...'; fa = 'Repeat invitation ...';
															|it = 'Ripetere invito...';
															|pl = 'Powtórz zaproszenie...';
															|tr = 'Daveti tekrar et...'"));
					Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
					
				ElsIf TaskDetails__.ResultID = "НеПринятоОбязательнымиУчастниками"
						Or TaskDetails__.ResultID = "НеПринятоВсемиУчастниками" Then //@NON-NLS-1 @NON-NLS-2
					
					Result.Insert("ExecuteTaskFirst", NStr("vi = 'Mời lại...';
															|ru = 'Повторить приглашение...';
															|en = 'Repeat invitation ...'; fa = 'Repeat invitation ...';
															|it = 'Ripetere invito...';
															|pl = 'Powtórz zaproszenie...';
															|tr = 'Daveti tekrar et...'"));
					Result.Insert("ExecuteTaskSecond", NStr("vi = 'Hủy lời mời';
															|ru = 'Отменить приглашение';
															|en = 'Cancel invitation'; fa = 'Cancel invitation';
															|it = 'Annullare invito';
															|pl = 'Anuluj zaproszenie';
															|tr = 'Daveti iptal et'"));
					Result.Insert("TextColorSecond", StyleColors.NegativeTaskCompletionFlag);
					
				EndIf;
			ElsIf TaskDetails__.RoutePointBriefly = "Оповестить" Then //@NON-NLS-1
				
				Result.Insert("ExecuteTaskFirst", NStr("vi = 'Đã tham khảo';
														|ru = 'Ознакомился';
														|en = 'I have read and understood'; fa = 'مطالعه کردم و متوجه شدم';
														|it = 'Esaminato';
														|pl = 'I have read and understood';
														|tr = 'İncelendi'"));
				
			EndIf;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a structure describing the main actions on the Workflow object
//
// Parameters:
//   Type - String - the XDTO type of the Workflow object.
//   Id - String - ID of the document flow object.
//
// Returns:
//   Structure:
//     * CreationCommands - Array of Structure:
//         ** Type - String - the full name of the type, for example, Directory.Counterparties
//         ** Presentation - String - representation of the type, for example, "Receipt of goods and services"
//     * DocumentKindID - String - for documents, the type of document of the subject
//
Function StructureOfCreateAndOpenCommands(Val Type, Val Id) Export
	
	If Not ValueIsFilled(Type) Or Not ValueIsFilled(Id) Then
		Return Undefined;
	EndIf;
	
	Result = New Structure;
	
	// does the linked object exist?
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Attributes = New Array;
	Attributes.Add("externalObject");
	
	If IntegrationWith1CDocumentManagementClientServer.IsDocument(Type) Then
		
		Attributes.Add("documentType");
		XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			Type,
			Id,
			Attributes);
		DocumentKindID = XDTODataObject.documentType.ObjectID.ID;
		
	Else // An object of a different type, for which the types of documents do not make sense.
		
		XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			Type,
			Id,
			Attributes);
		DocumentKindID = Undefined;
		
	EndIf;
	
	CreationCommands = New Array;
	If XDTODataObject.externalObject = Undefined Then
		FillingRules = IntegrationWith1CDocumentManagementServerCall.SuitableRules(,XDTODataObject);
		For Each FillingRule In FillingRules Do
			CreationCommand = New Structure;
			CreationCommand.Insert("Type", FillingRule.ObjectTypeIS);
			MetadataObject = Metadata.FindByFullName(FillingRule.ObjectTypeIS);
			If MetadataObject = Undefined Then
				Presentation = FillingRule.ObjectTypeIS;
			Else
				If Metadata.Catalogs.Contains(MetadataObject) Then
					Presentation = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Phần tử danh mục %1';
							|ru = 'Элемент справочника %1';
							|en = 'Directory element %1'; fa = 'Directory element %1';
							|it = 'Elemento di directory %1';
							|pl = 'Element katalogu %1';
							|tr = 'Katalog öğesi %1'"),
						MetadataObject.Presentation());
				Else
					Presentation = MetadataObject.Presentation();
				EndIf;
			EndIf;
			CreationCommand.Insert("Presentation", Presentation);
			CreationCommands.Add(CreationCommand);
		EndDo;
	EndIf;
	Result.Insert("CreationCommands", CreationCommands);
	Result.Insert("DocumentKindID", DocumentKindID);
	
	Return Result;
	
EndFunction

// Generates an XDTO object describing the task participant.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Performer - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   MainAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   AdditionalAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
// Returns:
//   XDTODataObject - an XDTO object of type DMBusinessProcessTaskExecutor.
//
Function TaskParticipant(Proxy, Performer, MainAddressingObject = Undefined,
		AdditionalAddressingObject = Undefined) Export
	
	TaskParticipant = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMBusinessProcessTaskExecutor");
	
	If ValueIsFilled(Performer.Description) Then
		FillInTaskParticipant(
			Proxy,
			TaskParticipant,
			Performer,
			MainAddressingObject,
			AdditionalAddressingObject);
	EndIf;
	
	Return TaskParticipant;
	
EndFunction

// Generates an XDTO object describing the executor in the "Execution" business process in the Document Flow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Performer - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   MainAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   AdditionalAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
// Returns:
//   XDTODataObject - an XDTO object of type DMBusinessProcessPerformanceParticipant.
//
Function ParticipantInProcessExecution(Proxy, Performer, MainAddressingObject = Undefined,
		AdditionalAddressingObject = Undefined) Export
	
	TaskParticipant = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMBusinessProcessPerformanceParticipant");
	
	If ValueIsFilled(Performer.Description) Then
		FillInTaskParticipant(
			Proxy,
			TaskParticipant,
			Performer,
			MainAddressingObject,
			AdditionalAddressingObject);
	EndIf;
	
	Return TaskParticipant;
	
EndFunction

// Generates an XDTO object describing the participant of the business process "Invitation" in the Document Flow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Performer - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   MainAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   AdditionalAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
// Returns:
//   XDTODataObject - an XDTO object of type DMBusinessProcessInvitationParticipant.
//
Function ParticipantInInvitationProcess(Proxy, Performer, MainAddressingObject = Undefined,
		AdditionalAddressingObject = Undefined) Export
	
	TaskParticipant = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMBusinessProcessInvitationParticipant");
	
	If ValueIsFilled(Performer.Description) Then
		FillInTaskParticipant(
			Proxy,
			TaskParticipant,
			Performer,
			MainAddressingObject,
			AdditionalAddressingObject);
	EndIf;
	
	Return TaskParticipant;
	
EndFunction

// Generates an XDTO object that describes the coordinator in the business process "Approval" in the Document Flow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Performer - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   MainAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   AdditionalAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
// Returns:
//   XDTODataObject - an XDTO object of type DMBusinessProcessApprovalParticipant.
//
Function ParticipantInApprovalProcess(Proxy, Performer, MainAddressingObject = Undefined,
		AdditionalAddressingObject = Undefined) Export
	
	TaskParticipant = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMBusinessProcessApprovalParticipant");
	
	If ValueIsFilled(Performer.Description) Then
		FillInTaskParticipant(
			Proxy,
			TaskParticipant,
			Performer,
			MainAddressingObject,
			AdditionalAddressingObject);
	EndIf;
	
	Return TaskParticipant;
	
EndFunction

#EndRegion

#Region Documents

// Returns a list of XDTO documents by Workflow object.
//
// Parameters:
//   OwnerID - UUID - the unique identifier of the document flow object.
//   OwnerName - String - representation of the document flow object.
//   OwnerType - String - type of Document flow object XDTO
//
// Returns:
//   XDTODataObject - A list of XDTO objects of the DMInternalDocument type.
//
Function DocumentsOnOwner(OwnerID, OwnerName, OwnerType) Export

	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMGetDocumentListByOwnerRequest");
	Owners = Query.owners; // XDTOList
	FieldsReceived = Query.columnSet; // XDTOList
	
	OwnerObject =  IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObject");
	OwnerObject.name = OwnerName;
	OwnerObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		String(OwnerID),
		OwnerType);
	
	Owners.Add(OwnerObject);
	
	FieldsReceived.Add("objectID");
	FieldsReceived.Add("signatures");
	FieldsReceived.Add("name");
	FieldsReceived.Add("author");
	
	Files = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Files);
	
	Return Files;
	
EndFunction

// Fills in the details of the form from the properties of the XDTO object according to the correspondence of the properties and details.
//
// Parameters:
//   XDTODataObject - XDTODataObject - the XDTO object to be filled in.
//   Form - ClientApplicationForm - the source of the fill data.
//   PropsAndProperties_ - Map of KeyAndValue:
//     * Key - String - the XDTO property.
//     * Value - String - Attributes.
//
Procedure FillInXDTOObjectFromForm(XDTODataObject, Form, PropsAndProperties_) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	For Each PropsAndProperties In PropsAndProperties_ Do
		FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			XDTODataObject,
			PropsAndProperties.Key,
			Form,
			PropsAndProperties.Value);
	EndDo;
	
EndProcedure

// Fills in the property of the XDTO object from the details structure of the original IC object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTODataObject - XDTODataObject - the object to be filled in BEFORE.
//   PropertyName - String - the name of the property of the XDTO object to be filled in.
//   AttributesStructure1 - Structure, FormDataStructure - a pre-filled structure
//     with object data.
//   DataPath_ - Structure, String - the name of the original prop.
//
Procedure FillInXDTPropertyOfOizPropsStructure(Proxy, XDTODataObject, PropertyName, AttributesStructure1,
		DataPath_) Export
	
	IntegrationWith1CDocumentManagementCore.PropertyExists(XDTODataObject, PropertyName, True);
	
	If TypeOf(DataPath_) = Type("Structure") Then
		
		ContainerProperty = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			XDTODataObject.Properties().Get(PropertyName).Type.Name);
		
		For Each KeyAndValue In DataPath_ Do
			
			TableName = KeyAndValue.Key;
			Table = ContainerProperty[TableName]; // XDTOList
			ElementType = ContainerProperty.Properties().Get(TableName).Type.Name;
			If AttributesStructure1[KeyAndValue.Value[0]] = Undefined Then
				Return;
			EndIf;
			
			SourceTable = AttributesStructure1[KeyAndValue.Value[0]];
			If TypeOf(SourceTable) = Type("ValueTable") Then
				SourceTable1 = SourceTable.Copy();
			Else // The tabular part.
				SourceTable1 = SourceTable.Unload();
			EndIf;
			SourceTable1.Columns.Add("Type");
			SourceTable1.FillValues(AttributesStructure1.Type, "Type");
			
			For Each SourceItem In SourceTable1 Do
				Item = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, ElementType);
				For Each MapRow In KeyAndValue.Value[1] Do
					FillInXDTPropertyOfOizPropsStructure(
						Proxy,
						Item,
						MapRow.Key,
						SourceItem,
						MapRow.Value);
				EndDo;
				Table.Add(Item);
			EndDo;
			
		EndDo;
		
		XDTODataObject[PropertyName] = ContainerProperty;
		
	ElsIf TypeOf(DataPath_) = Type("String") Then
		
		AttributeName = DataPath_;
		If AttributesStructure1[AttributeName] = Undefined Then
			Return;
		EndIf;
		
		If IntegrationWith1CDocumentManagementCore.ThisIsObjectProperty(Proxy, XDTODataObject, PropertyName) Then
			
			Attribute = AttributesStructure1[AttributeName];
			AttributeID = AttributesStructure1[AttributeName + "ID"];
			AttributeType = AttributesStructure1[AttributeName + "Type"];
			
			ThisIsISObject = False;
			ReferenceToConsumer_ = Undefined;
			If Metadata.FindByFullName(AttributeType) <> Undefined Then
				ThisIsISObject = True;
				ReferenceToConsumer_ = IntegrationWith1CDocumentManagementCore.LinkFromUUID(AttributeType, AttributeID);
			EndIf;
			
			PropertyType1 = XDTODataObject.Properties().Get(PropertyName).Type.Name;
			PropertyValue = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				PropertyType1,
				ReferenceToConsumer_,
				ThisIsISObject);
			
			If ThisIsISObject Then
				
				If AttributesStructure1.Type = "DMInternalDocument" Then
					If PropertyName = "contactPerson" And Not PropertyValue.IsSet("correspondent") Then
						FillInXDTPropertyOfOizPropsStructure(
							Proxy,
							PropertyValue,
							"correspondent",
							AttributesStructure1,
							"Counterparty");
					EndIf;
					
				ElsIf AttributesStructure1.Type = "DMOutgoingDocument" Then
					If PropertyName = "addressee" And Not PropertyValue.IsSet("correspondent") Then
						FillInXDTPropertyOfOizPropsStructure(
							Proxy,
							PropertyValue,
							"correspondent",
							AttributesStructure1,
							"Recipient");
					EndIf;
					
				ElsIf AttributesStructure1.Type = "DMIncomingDocument" Then
					If PropertyName = "signer" And Not PropertyValue.IsSet("correspondent") Then
						FillInXDTPropertyOfOizPropsStructure(
							Proxy,
							PropertyValue,
							"correspondent",
							AttributesStructure1,
							"Sender");
					EndIf;
					
				EndIf;
				
			ElsIf AttributeType = "String" Then
				
				PropertyValue.name = Attribute;
				PropertyValue.externalObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(Proxy);
				
				If AttributesStructure1.Type = "DMInternalDocument" Then
					If PropertyName = "contactPerson" And Not PropertyValue.IsSet("correspondent") Then
						FillInXDTPropertyOfOizPropsStructure(
							Proxy,
							PropertyValue,
							"correspondent",
							AttributesStructure1,
							"Counterparty");
					EndIf;
				ElsIf AttributesStructure1.Type = "DMOutgoingDocument" Then
					If PropertyName = "addressee" And Not PropertyValue.IsSet("correspondent") Then
						FillInXDTPropertyOfOizPropsStructure(
							Proxy,
							PropertyValue,
							"correspondent",
							AttributesStructure1,
							"Recipient");
					EndIf;
				ElsIf AttributesStructure1.Type = "DMIncomingDocument" Then
					If PropertyName = "signer" And Not PropertyValue.IsSet("correspondent") Then
						FillInXDTPropertyOfOizPropsStructure(
							Proxy,
							PropertyValue,
							"correspondent",
							AttributesStructure1,
							"Sender");
					EndIf;
				EndIf;
				
				If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, PropertyValue, "DMPartyRowContact") Then
					PropertyValue.contactName = Attribute;
				EndIf;
				
			ElsIf ValueIsFilled(Attribute) Then
				
				PropertyValue.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
					Proxy,
					AttributeID,
					AttributeType);
				PropertyValue.name = Attribute;
				
			Else
				
				PropertyValue.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy);
				PropertyValue.name = "";
				
			EndIf;
			
			XDTODataObject.Set(PropertyName, PropertyValue);
			
		Else
			XDTODataObject.Set(PropertyName, AttributesStructure1[AttributeName]);
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the details of the form from the properties of the XDTO object according to the correspondence of the properties and details.
//
// Parameters:
//   Form - ClientApplicationForm - the form to be filled out.
//   XDTODataObject - XDTODataObject - the source of the fill data.
//   PropsAndProperties_ - Map of KeyAndValue:
//     * Key - String - the XDTO property.
//     * Value - String - Attributes.
//
Procedure FillOutFormFromXDTOObject(Form, XDTODataObject, PropsAndProperties_) Export
	
	For Each PropsAndProperties In PropsAndProperties_ Do
		FillInDetailsFromXDTOObject(
			Form,
			PropsAndProperties.Value,
			XDTODataObject,
			PropsAndProperties.Key);
	EndDo;
	
EndProcedure

// Searches for types of documents in the UP by the type of object and by the exact coincidence of the name. Creates a new
// type of documents with the specified properties if nothing is found.
//
// Parameters:
//   Properties - See IntegrationWith1CDocumentManagement.StructureOfTheAttributesOfTheFilledDocumentKindDM.
//
// Returns:
//   XDTODataObject - An XDTO object of type DM<...>DocumentType or DMError.
//
Function FindCreateVDODocumentView(Properties) Export
	
	SearchResults = IntegrationWith1CDocumentManagementCoreServerCall.FindVDOObjectByName(
		Properties.Type,
		Properties.Name);
	
	If SearchResults = Undefined Then
		Return CreateVDODocumentView(Properties);
	Else
		Return SearchResults;
	EndIf;
	
EndFunction

// Searches for folders of internal documents in the DO by exact coincidence of the name. Creates a new
// folder with the specified properties if nothing is found.
//
// Parameters:
//   Properties - See IntegrationWith1CDocumentManagement.StructureOfDetailsOfInternalDocumentsFolderToFillIn.
//
// Returns:
//   XDTODataObject - An XDTO object of type DMInternalDocumentFolder or DMError.
//
Function FindCreateVDOInternalDocumentsFolder(Properties) Export
	
	SearchResults = IntegrationWith1CDocumentManagementCoreServerCall.FindVDOObjectByName(
		"DMInternalDocumentFolder",
		Properties.Name);
	
	If SearchResults = Undefined Then
		Return CreateFolderOfInternalVDODocuments(Properties);
	Else
		Return SearchResults;
	EndIf;
	
EndFunction

// Adjusts the form of the document according to its type.
//
// Parameters:
//   Form - ClientApplicationForm - 1C document form:Document management.
//   documentType - XDTODataObject - type of document.
//   organization - XDTODataObject - Organization.
//
Procedure CustomizeDocumentFormAccordingToXDTODocumentView(Form, documentType, organization = Undefined) Export
	
	FormName = Form.FormName;
	Items = Form.Items;
	
	If FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.IncomingDocument" Then
		
		Items.TaskDueDate.Visible =
			(documentType <> Undefined And documentType.performanceDateEnabled = True);
		Items.Sum.Visible =
			(documentType <> Undefined And documentType.sumEnabled = True);
		Items.Currency.Visible =
			(documentType <> Undefined And documentType.sumEnabled = True);
		
	ElsIf FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.OutgoingDocument" Then
		
		Items.TaskDueDate.Visible =
			(documentType <> Undefined And documentType.PerformanceDateEnabled = True);
		Items.GroupNumberRecipientDate.Visible =
			(documentType <> Undefined And documentType.ExternalNumberEnabled = True);
		Items.Sum.Visible =
			(documentType <> Undefined And documentType.SumEnabled = True);
		Items.Currency.Visible =
			(documentType <> Undefined And documentType.SumEnabled = True);
		
	ElsIf FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.InternalDocument" Then
		
		Items.TaskDueDate.Visible =
			(documentType <> Undefined And documentType.performanceDateEnabled = True);
		Items.Sum.Visible =
			(documentType <> Undefined And documentType.sumEnabled = True);
		Items.Currency.Visible =
			(documentType <> Undefined And documentType.sumEnabled = True);
		Items.ValidityPeriodPresentation.Visible =
			(documentType <> Undefined And documentType.durationEnabled = True);
		Items.Addressee.Visible =
			(documentType <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertySet(documentType, "addresseeEnabled")
			And documentType.addresseeEnabled);
		
		Form.KeepRecordsOfCounterparties =
			documentType <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertySet(documentType, "correspondentEnabled")
			And documentType.correspondentEnabled;
		Form.KeepRecordsOfParties =
			documentType <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertySet(documentType, "partiesEnabled")
			And documentType.partiesEnabled;
		Form.IsRequestForPayment =
			documentType <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertySet(documentType, "isAPaymentRequest")
			And documentType.isAPaymentRequest;
		Form.KeepRecordsOfCFItem =
			documentType <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertySet(documentType, "cashFlowDetailsEnabled")
			And documentType.cashFlowDetailsEnabled;
		Form.KeepRecordsOfGoodsAndServices =
			documentType <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertySet(documentType, "productRowsEnabled")
			And documentType.productRowsEnabled;
		Form.UseSigning =
			documentType <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertySet(documentType, "useSigningByManager")
			And documentType.useSigningByManager;
		Form.UseAssertion =
			documentType <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertySet(documentType, "useConfirmation")
			And documentType.useConfirmation;
		
		If documentType <> Undefined
				And IntegrationWith1CDocumentManagementCore.PropertySet(documentType, "signatureOption") Then
			SigningOption = documentType.signatureOption.objectID.ID;
		Else
			SigningOption = "";
		EndIf;
		
		Items.PartyGroup.Visible = Form.KeepRecordsOfParties
			And Not Form.IsRequestForPayment;
		Items.PartiesSigned.Visible = Form.KeepRecordsOfParties
			And Not Form.IsRequestForPayment
			And SigningOption <> "NotSubscribed";
		Items.PartiesSignatureDate.Visible = Form.KeepRecordsOfParties
			And Not Form.IsRequestForPayment
			And SigningOption <> "NotSubscribed";
		
		If Not Form.KeepRecordsOfParties Or Form.IsRequestForPayment Then
			Items.GroupOurOrganization.Visible =
				(documentType <> Undefined And documentType.organizationEnabled = True);
		Else
			Items.GroupOurOrganization.Visible = False;
		EndIf;
		
		// Request for payment.
		If Form.IsRequestForPayment Then
			NameRecipientXDTO = IntegrationWith1CDocumentManagementCore.PredefinedValueBefore(
				"DMPartyName", "Получатель"); //@NON-NLS-2
			Form.Recipient = "";
			Form.RecipientID = "";
			Form.RecipientType = "";
			For Each StringSide In Form.Parties Do
				If StringSide.DescriptionID = NameRecipientXDTO.objectID.ID Then
					Form.Recipient = StringSide.Party;
					Form.RecipientID = StringSide.PartyID;
					Form.RecipientType = StringSide.PartyType;
				EndIf;
			EndDo;
			Items.RecipientGroup.Visible = True;
			Items.Organization.Title = NStr("vi = 'Người nộp';
											|ru = 'Плательщик';
											|en = 'Payer'; fa = 'پرداخت‌کننده';
											|it = 'Плательщик';
											|pl = 'Payer';
											|tr = 'Ödeyen'");
			Items.GroupOurOrganization.ShowTitle = False;
			Items.ExpenseReport.Visible = (Form.RecipientType = "DMUser"
				Or IntegrationWith1CDocumentManagementCoreServerCall.TypeNameXDTO(
					Form.RecipientType) = "DMUser");
		Else
			Items.RecipientGroup.Visible = False;
			Items.Organization.Title = NStr("vi = 'Doanh nghiệp';
											|ru = 'Организация';
											|en = 'Company'; fa = 'Company';
											|it = 'Организация';
											|pl = 'Firma';
											|tr = 'İş yeri'");
			Items.GroupOurOrganization.ShowTitle = True;
		EndIf;
		
		Items.CounterpartyGroup.ShowTitle = Form.KeepRecordsOfCounterparties;
		Items.Counterparty.Visible = Form.KeepRecordsOfCounterparties;
		Items.ContactPerson.Visible = Form.KeepRecordsOfCounterparties;
		Items.CFItemsGroup.Visible = Form.KeepRecordsOfCFItem;
		Items.GoodsPage.Visible = Form.KeepRecordsOfGoodsAndServices;
		
		If organization <> Undefined
				And IntegrationWith1CDocumentManagementCore.PropertySet(organization, "VATpayer") Then
			Form.ConsiderVAT = organization.VATpayer;
		Else
			Form.ConsiderVAT = True;
		EndIf;
		Items.VATAmount.Visible =
			Form.ConsiderVAT
			And documentType <> Undefined
			And documentType.sumEnabled = True;
		Items.GoodsVATRate.Visible =
			Form.ConsiderVAT
			And documentType <> Undefined
			And documentType.sumEnabled = True;
		Items.GoodsVATAmount.Visible =
			Form.ConsiderVAT
			And documentType <> Undefined
			And documentType.sumEnabled = True;
		
		Items.SignedBy.Visible = True;
		If Form.UseSigning Then
			Items.SignedBy.Title = NStr("vi = 'Đã ký';
										|ru = 'Подписан';
										|en = 'Signed'; fa = 'امضاشده';
										|it = 'Подписан';
										|pl = 'Signed';
										|tr = 'İmzalandı'");
		ElsIf Form.UseAssertion Then
			Items.SignedBy.Title = NStr("vi = 'Đã duyệt';
										|ru = 'Утвержден';
										|en = 'Confirmed'; fa = 'تأییدشده';
										|it = 'Утвержден';
										|pl = 'Confirmed';
										|tr = 'Onaylandı'");
		Else
			Items.SignedBy.Visible = False;
		EndIf;
		
	EndIf;
	
EndProcedure

// Updates the approval visa table on the document form.
//
// Parameters:
//   XDTOVisas - XDTOList - list of visas, DMVisa type objects.
//   VisaApprovals - FormDataCollection - updated visa table.
//   FormItem - FormGroup - the element whose title should be updated.
//
Procedure UpdateVisaApprovals(XDTOVisas, VisaApprovals, FormItem) Export
	
	VisaApprovals.Clear();
	
	If XDTOVisas.Count() = 0 Then
		FormItem.Title = NStr("vi = 'Xác thực';
								|ru = 'Визы';
								|en = 'Approval notes'; fa = 'یادداشت‌های تأیید';
								|it = 'Visti';
								|pl = 'Approval notes';
								|tr = 'Vizeler'");
		Return;
	EndIf;
	
	For Each XDTOVisa In XDTOVisas Do
		
		Visa = VisaApprovals.Add();
		
		Visa.Description = XDTOVisa.name;
		Visa.ID = XDTOVisa.objectID.ID;
		Visa.Type = XDTOVisa.objectID.type;
		
		If XDTOVisa.IsSet("addedBy") Then
			Visa.Contributed = XDTOVisa.addedBy.name;
			Visa.ContributedID = XDTOVisa.addedBy.objectID.ID;
			Visa.ContributedType = XDTOVisa.addedBy.objectID.type;
		EndIf;
		
		If XDTOVisa.IsSet("reviewer") Then
			Visa.ApprovingPerson = XDTOVisa.reviewer.name;
			Visa.ApprovingPersonID = XDTOVisa.reviewer.objectID.ID;
			Visa.ApprovingPersonType = XDTOVisa.reviewer.objectID.type;
		EndIf;
		
		If XDTOVisa.IsSet("result") Then
			Visa.Result = XDTOVisa.result.name;
			Visa.ResultID = XDTOVisa.result.objectID.ID;
			Visa.ResultType = XDTOVisa.result.objectID.type;
		EndIf;
		
		Visa.Date = XDTOVisa.date;
		Visa.Comment = XDTOVisa.comment;
		
		If XDTOVisa.signed Then
			If XDTOVisa.signatureChecked Then
				If XDTOVisa.signatureValid Then
					Visa.CaptionStatusImage = 2;
				Else
					Visa.CaptionStatusImage = 3;
				EndIf;
			Else
				Visa.CaptionStatusImage = 1;
			EndIf;
		Else
			Visa.CaptionStatusImage = 0;
		EndIf;
		Visa.Comment = XDTOVisa.comment;
		
	EndDo;
	
	FormItem.Title = StrTemplate(NStr("vi = 'Xác thực (%1)';
										|ru = 'Визы (%1)';
										|en = 'Approval notes (%1)'; fa = 'Approval notes (%1)';
										|it = 'Visti (%1)';
										|pl = 'Wizy (%1)';
										|tr = 'Vizeler (%1)'"), XDTOVisas.Count());
	
EndProcedure

// Updates the HTML representation of resolutions on the document form.
//
// Parameters:
//   XDTOResolutions - XDTOList - a list of resolutions, objects of the DMResolution type.
//   PresentationHTML - String - updated HTML representation.
//   FormItem - FormGroup - the element whose title should be updated.
//
Procedure UpdateResolutionsPresentation(XDTOResolutions, PresentationHTML, FormItem) Export
	
	If XDTOResolutions.Count() = 0 Then
		PresentationHTML = "";
		FormItem.Title = NStr("vi = 'Ý kiến chỉ đạo';
								|ru = 'Резолюции';
								|en = 'Resolutions'; fa = 'دستورها';
								|it = 'Risoluzione';
								|pl = 'Resolutions';
								|tr = 'Kararlar'");
		Return;
	EndIf;
	
	Presentation = "";
	For Each XDTOResolution In XDTOResolutions Do
		If XDTOResolution.IsSet("reviewer") Then
			NamePresentation = XDTOResolution.reviewer.name;
		Else
			NamePresentation = "";
		EndIf;
		If XDTOResolution.signed Then
			If XDTOResolution.signatureChecked Then
				If XDTOResolution.signatureValid Then
					CheckStatus = "true";
				Else
					CheckStatus = "false";
				EndIf;
			Else // Not tested.
				CheckStatus = "not";
			EndIf;
		Else // Not signed.
			CheckStatus = "";
		EndIf;
		Presentation = StrTemplate(
			"%1<div class=""field""><p>%2</p><p><span class=""status %3"">%4</span></p><p>%5</p></div>",
			Presentation, // 1
			StrReplace(XDTOResolution.text, Chars.LF, "<br/>"), // 2
			CheckStatus, // 3
			NamePresentation, // 4
			Format(XDTOResolution.date, NStr("vi = 'DF=''dd.MM.yyyy HH:mm''';
											|ru = 'ДФ=''dd.MM.yyyy ЧЧ:мм''';
											|en = 'DF=''MM/dd/yyyy hh:mm t'''; fa = 'DF=''MM/dd/yyyy hh:mm t''';
											|it = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
											|pl = 'DF=''dd.MM.yyyy ЧЧ:мм''';
											|tr = 'DF=''dd.MM.yyyy SS:dd'''"))); // 5
	EndDo;
		
	PresentationHTML = StrTemplate(
		"<html>
		|<head><meta http-equiv=""X-UA-Compatible"" content=""IE=edge""></head>
		|<body>
		|<style>
		|* { font-family: sans-serif; font-size: 9pt; }
		|body { padding: 0; margin: 8px; overflow: auto; }
		|a { color: #1E90FF; }
		|p { padding: 0 0 4px 0; margin: 0; }
		|.field { margin-bottom: 6px; padding: 6px 8px 2px 8px; }
		|.active { background-color: #EEEEEE; }
		|.status { background-position: center right; background-repeat: no-repeat; padding: 1px 24px 2px 0; }
		|.not { background-image: url(""data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAB3RJTUUH3gcIDAYg91pdKgAAAAd0RVh0QXV0aG9yAKmuzEgAAAAMdEVYdERlc2NyaXB0aW9uABMJISMAAAAKdEVYdENvcHlyaWdodACsD8w6AAAADnRFWHRDcmVhdGlvbiB0aW1lADX3DwkAAAAJdEVYdFNvZnR3YXJlAF1w/zoAAAALdEVYdERpc2NsYWltZXIAt8C0jwAAAAh0RVh0V2FybmluZwDAG+aHAAAAB3RFWHRTb3VyY2UA9f+D6wAAAAh0RVh0Q29tbWVudAD2zJa/AAAABnRFWHRUaXRsZQCo7tInAAACAklEQVQ4ja2TsWsUQRjF35udOZNKK5tDAgtXyFleaxLBFPkDUooEJKTKXpWrlJAuVrtdECGFdvkDRFJ4mvbaw+Lg8AhnoZXdejs7zyJz4YhREPzK4f2+ed98bygJi5Vl2RrJdQAdSS0AIDkCMJDUL4ri46Ke8wbdbveepG2S9yX1SQ5ms9kIABqNRktSh+S6pM8kT/I8v7hqEOF9AMMkSd5UVbWSJElbUhodjOu6HjrnJnVdPwHQJvkyz/MLCwCStgEMrbWnVVVtGmOaAIYATqPT1Biz4b2fOudOvfdz5pB7e3trJHeNMc+895skfywtLX06Ojr6uThrr9e7VZblqqTb1tp3IYTXko5tnKtfVdWKMaYpqSzL8mmWZbhekr6SbEZtn+S6BdAheZAkSTvaTouiePUbfbmhHZLDqB0AODCSWrPZbCQplTS+CbzmYiwpjUzL3qCZZFm28wd+cv3Akhw1Go0WgDGANM/z939z0O12HwMYR2ZkcZmwTgjh3Biz0ev1zsuyXAXwBcADY8x3AKjr+s7y8vKZpHYI4cwY85DkwMbU7Trn3nrvp2VZri6scTS/eWGNU+fcJITwXNIxJSHLshcAvsUgPSLZJDmcPyrJVFI7wh+891sA7hZFcWij4ETSvvce1tqrKAPYigbGIYQz59zEe38VZeB/fabF+tfv/AvEjVUkU5cRDAAAAABJRU5ErkJggg==""); }
		|.true { background-image: url(""data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAB3RJTUUH3gcIDAcDTCYdGQAAAAd0RVh0QXV0aG9yAKmuzEgAAAAMdEVYdERlc2NyaXB0aW9uABMJISMAAAAKdEVYdENvcHlyaWdodACsD8w6AAAADnRFWHRDcmVhdGlvbiB0aW1lADX3DwkAAAAJdEVYdFNvZnR3YXJlAF1w/zoAAAALdEVYdERpc2NsYWltZXIAt8C0jwAAAAh0RVh0V2FybmluZwDAG+aHAAAAB3RFWHRTb3VyY2UA9f+D6wAAAAh0RVh0Q29tbWVudAD2zJa/AAAABnRFWHRUaXRsZQCo7tInAAABwElEQVQ4ja2TMWsUURSFv7nz8hQbrWwWCQxsIWOZ1s0KpvAHpBQJSCZdunRKSGlnlxEhhXb7A0S2cDXttoPFwOIS1kIru3H2zX0W+0Z3l0UQPOXl3nPePfe8yHvPMqIs3gX6wA7QDeUSGAMjnzcfV/pbgiiL7wAHwF1gBIypKQGwdANhH/gMXPi8ufpNEIZPgMIYfeNq2caQoiQACBMchbE6dU4eAynwwufNlQkvOQAKjA5cLY8QOigFMABASRD2XC0zrA5w0s6cRRzKLnBkjD4Nwz+2ruun+qX/ubyrPY6uzSvpodw0Vt85J6+BcxP2GrlatoNyNa/kSZTFrEJA+YrQCb0joG+COadh5wIh8Xnzig2IsvhwsSopyhg4FaBLTRkMm2waXMMEJQkX6poNDdOgtAnT9YIBSixdZMHs8+b93+SjLH6IMAnZKA2LhO3guETYs8fR5bySHvAFuIfwHQDHra0bOgRJcQwR7gNjwyJ1R8bqW1fLbF5Jb+mMZau8dMZZCNQz4LxN4nPgG0YH1PIAoQMU/DE1AVKUGVY/4GQfuO3z5qw18QI4wQnGrkR5H2ijPFyPMvyvz7Tm8j9951+Qy9eWUE15/AAAAABJRU5ErkJggg==""); }
		|.false { background-image: url(""data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAB3RJTUUH3gcIDAcaKE212QAAAAd0RVh0QXV0aG9yAKmuzEgAAAAMdEVYdERlc2NyaXB0aW9uABMJISMAAAAKdEVYdENvcHlyaWdodACsD8w6AAAADnRFWHRDcmVhdGlvbiB0aW1lADX3DwkAAAAJdEVYdFNvZnR3YXJlAF1w/zoAAAALdEVYdERpc2NsYWltZXIAt8C0jwAAAAh0RVh0V2FybmluZwDAG+aHAAAAB3RFWHRTb3VyY2UA9f+D6wAAAAh0RVh0Q29tbWVudAD2zJa/AAAABnRFWHRUaXRsZQCo7tInAAACBUlEQVQ4ja2TsWtTURTGf/fm3ZcSClZBl1BDX/IGiWNX0wh26B/QUaQgpX9BN6V07F9QROigW0cHkQ5Gu2YNgi99+ihxsIMRpLzcE+91yEuNWgTBbzz3fOd+55zvKO89s0hUbUVj2sAySDyJmgToOqQT++zNbL6aFjhRtUVgA8wtBx2NdL/hE4B5VOwwyxraIO+Ag7rPTi8KnKjaosNsg/RCwmfnjGohYRMkKhSkFturUM4s9j6Ypkb26j47DQolGyC9OdThOXYtRFWBnoNDAA1RiFrNsYMK6jBHCg676j03VzRmK0A9zLFrGvN1ge9vr/sPo9lez9RSeUip5ZArc4Qvx/inDtkPNKbtoDORrapjJB9iHgxVg19RwiGfAqieM6oFhB2Naas+9RcgO2Ai4IuDKPb9J1yCRDU2NaTAVZAUzI4GiSfTlsgh6WXEWUxyJCo4cfBnimSJamxeTpfs90gAJplHYjCphqju+6/+puBENe4BacFJAqDrMMtj7HGIWj1TS8dDSi2Qjxpua8IzAItduIY+Ate0+KOA8I6GbuCQjsZsVSg/z7GDIaXWZI3ZCEimP/9coxtUKGdj/COH7E+d+NjB54mR/N0AqmB606FqTATSHMOggnqd49c13Kj7bHc6xAMw2znC3IWVaWpYL95Tiz+qUM7ywsoge/C/jmkW/3rOPwBzWQNrm2r0hAAAAABJRU5ErkJggg==""); }
		|</style>
		|%1
		|</body>
		|</html>",
		Presentation);
		
	FormItem.Title = StrTemplate(
		NStr("vi = 'Ý kiến chỉ đạo (%1)';
			|ru = 'Резолюции (%1)';
			|en = 'Resolutions (%1)'; fa = 'Resolutions (%1)';
			|it = 'Risoluzione (%1)';
			|pl = 'Rezolucje (%1)';
			|tr = 'Kararlar (%1)'"),
		XDTOResolutions.Count());
	
EndProcedure

// Creates a document view with the specified properties.
//
// Parameters:
//   Properties - See IntegrationWith1CDocumentManagement.StructureOfTheAttributesOfTheFilledDocumentKindDM.
//
// Returns:
//   XDTODataObject - An XDTO object of type DM<...>DocumentType or DMError.
//
Function CreateVDODocumentView(Properties) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	DocumentKind = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Properties.Type);
	DocumentKind.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, "", Properties.Type);
	
	DocumentKind.name = Properties.Name;
	FillInXDTPropertyOfOizPropsStructure(
		Proxy,
		DocumentKind,
		"automaticNumeration",
		Properties,
		"Autonumbering");
	FillInXDTPropertyOfOizPropsStructure(
		Proxy,
		DocumentKind,
		"sumEnabled",
		Properties,
		"ConsiderDocumentAmount");
	FillInXDTPropertyOfOizPropsStructure(
		Proxy,
		DocumentKind,
		"performanceDateEnabled",
		Properties,
		"UseDueDate");
	FillInXDTPropertyOfOizPropsStructure(
		Proxy,
		DocumentKind,
		"templateRequired",
		Properties,
		"ProhibitCreationOfDocumentsThatAreNotTemplate");
	If IntegrationWith1CDocumentManagementCore.PropertyExists(DocumentKind, "accountingForCaseFilesEnabled") Then
		FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			DocumentKind,
			"accountingForCaseFilesEnabled",
			Properties,
			"AccountingByProductOfCasesIsIncluded");
	EndIf;
	
	If Properties.Type = "DMInternalDocumentType" Then
		FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			DocumentKind,
			"addresseeEnabled",
			Properties,
			"KeepRecordsByAddressees");
		FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			DocumentKind,
			"cashFlowDetailsEnabled",
			Properties,
			"KeepRecordsOfCFItem");
		FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			DocumentKind,
			"correspondentEnabled",
			Properties,
			"KeepRecordsOfCounterparties");
		FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			DocumentKind,
			"durationEnabled",
			Properties,
			"ConsiderExpirationDate");
		FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			DocumentKind,
			"organizationEnabled",
			Properties,
			"KeepRecordsOfOrganizations");
		FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			DocumentKind,
			"signatureOption",
			Properties,
			"SigningOption");
		If IntegrationWith1CDocumentManagementCore.PropertyExists(DocumentKind, "partiesEnabled") Then
			FillInXDTPropertyOfOizPropsStructure(
				Proxy,
				DocumentKind,
				"partiesEnabled",
				Properties,
				"KeepRecordsOfParties");
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertyExists(DocumentKind, "isAPaymentRequest") Then
			FillInXDTPropertyOfOizPropsStructure(
				Proxy,
				DocumentKind,
				"isAPaymentRequest",
				Properties,
				"IsRequestForPayment");
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertyExists(DocumentKind, "productRowsEnabled") Then
			FillInXDTPropertyOfOizPropsStructure(
				Proxy,
				DocumentKind,
				"productRowsEnabled",
				Properties,
				"KeepRecordsOfGoodsAndServices");
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertyExists(DocumentKind, "useConfirmation") Then
			FillInXDTPropertyOfOizPropsStructure(
				Proxy,
				DocumentKind,
				"useConfirmation",
				Properties,
				"UseAssertion");
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertyExists(DocumentKind, "useSigningByManager") Then
			FillInXDTPropertyOfOizPropsStructure(
				Proxy,
				DocumentKind,
				"useSigningByManager",
				Properties,
				"UseSigning");
		EndIf;
	ElsIf Properties.Type = "DMOutgoingDocumentType" Then
		FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			DocumentKind,
			"externalNumberEnabled",
			Properties,
			"ConsiderRecipientSIncomingNumberAndDate");
	EndIf;
	
	Return IntegrationWith1CDocumentManagementCore.CreateNewObject(Proxy, DocumentKind).object;
	
EndFunction

// Creates a new Document flow object according to the IP object and the specified rule.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ObjectIS - AnyRef - the IP object, the data source of the filling.
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement - filling rule.
//
// Returns:
//   XDTODataObject - created object:
//     * name - String
//     * objectID - XDTODataObject:
//       ** ID - String
//       ** type - String
//   The string is an error message.
//
Function CreateMapItemUsingRule(Proxy, ObjectIS, Rule) Export
	
	TheseRules = Catalogs.RulesForIntegrationWith1CDocumentManagement.TheseRulesForUploading(Rule);
	
	AttributesStructure1 = StructureOfTheAttributesOfTheFilledObjectDM(TheseRules.ObjectTypeDM);
	
	ControlOverSendingFiles = IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles();
	
	Catalogs.RulesForIntegrationWith1CDocumentManagement.FillInMapItemDetailsStructureUsingRule(
		ObjectIS,
		AttributesStructure1,
		TheseRules,
		ControlOverSendingFiles);
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetNewObjectRequest");
	Query.type = TheseRules.ObjectTypeDM;
	
	// Filling out documents according to templates.
	Template = Undefined;
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.0.8.1") Then
		
		If ValueIsFilled(TheseRules.TemplateID) Then
			
			Template = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				TheseRules.TemplateType);
			Template.name = TheseRules.Template;
			Template.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				TheseRules.TemplateID,
				TheseRules.TemplateType);
			
			Query.dataSource = Template;
			
		EndIf;
		
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMError") Then
		Return Response.description;
	EndIf;
	
	XDTODataObject = Response;
	
	MatchingXDTPropertiesAndProps =
		Catalogs.RulesForIntegrationWith1CDocumentManagement.MatchingXDTPropertiesAndObjectFormDetailsTo(
			TheseRules.ObjectTypeDM);
	
	For Each MapRow In MatchingXDTPropertiesAndProps Do
		FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			XDTODataObject,
			MapRow.Key,
			AttributesStructure1,
			MapRow.Value);
	EndDo;
	
	// Save the template files for separate filling.
	If XDTODataObject.Properties().Get("files") <> Undefined And AttributesStructure1.Property("Files") Then
		
		FileNumber = 0;
		While FileNumber <= XDTODataObject.files.Count() - 1 Do
			XDTOFile = XDTODataObject.files[FileNumber];
			
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "template")
					And ValueIsFilled(XDTOFile.template.objectID.ID) Then
				
				CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
					XDTOFile.name,
					Undefined,
					"DMFile",
					XDTOFile.extension);
				
				FileCreationParameters =
					IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions(CurrentFile);
				FileCreationParameters.TemplateID = XDTOFile.template.objectID.ID;
				FileCreationParameters.Owner = ObjectIS;
				
				AttributesStructure1.Files.Add(FileCreationParameters);
				
				XDTODataObject.files.Delete(FileNumber);
				
			Else
				
				FileNumber = FileNumber + 1;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.GenerateAdditionalProperties(
		Proxy,
		XDTODataObject,
		AttributesStructure1);
	
	XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy);
	XDTODataObject.name = String(ObjectIS);
	
	If ValueIsFilled(ObjectIS) Then
		XDTODataObject.externalObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
			Proxy,
			ObjectIS);
	EndIf;
	
	If Template <> Undefined Then
		XDTODataObject.template = Template;
	EndIf;
	
	SynchronizeITCHAttributesCounterparties(Proxy, XDTODataObject);
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCreateRequest");
	Query.object = XDTODataObject;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMError") Then
		Return Response.description;
	EndIf;
	
	XDTODataObject = Response.object;
	
	WhetherFilesAreAttached = Undefined;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "files") Then
		WhetherFilesAreAttached = (XDTODataObject.files.Count() > 0);
	EndIf;
	InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.AddLink(
		XDTODataObject.objectID.ID,
		XDTODataObject.objectID.type,
		ObjectIS,
		WhetherFilesAreAttached);
	
	BatchRequestsFunctionalityIsAvailable =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3");
	
	If AttributesStructure1.Property("Files") And AttributesStructure1.Files.Count() > 0 Then
		
		If BatchRequestsFunctionalityIsAvailable Then
			PackageQueries = New Array;
		EndIf;
		
		For Each CreationParameters In AttributesStructure1.Files Do
			
			XDTOFile = IntegrationWith1CDocumentManagementCore.XDTOFileFromCreationParameters(
				Proxy,
				CreationParameters);
			Query = IntegrationWith1CDocumentManagementCore.CreateRequestFile(
				Proxy,
				XDTOFile,
				XDTODataObject.objectID.ID,
				XDTODataObject.objectID.type,
				XDTODataObject.name);
			
			If BatchRequestsFunctionalityIsAvailable Then
				PackageQueries.Add(Query);
			Else
				Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
				If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMError") Then
					Return Response.description;
				EndIf;
			EndIf;
			
		EndDo;
		
		If BatchRequestsFunctionalityIsAvailable Then
			ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(
				Proxy,
				PackageQueries);
			For Each Response In ResponseToPackageRequests.responses Do
				If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMError") Then
					Return Response.description;
				EndIf;
			EndDo;
		EndIf;
		
		IntegrationWith1CDocumentManagementCore.OnAdd1CDocumentManagementAttachedFiles(
			XDTODataObject.objectID.ID,
			XDTODataObject.objectID.type,
			ObjectIS,
			True);
		
	EndIf;
	
	For Each String In ControlOverSendingFiles Do
		InformationRegisters.ControlOverSendingFilesTo1CDocumentManagement.SaveHashSumOfFileVersion(
			String.Source,
			String.FileName,
			String.SpreadsheetDocument)
	EndDo;
	
	IntegrationWith1CDocumentManagementCore.SetBarcode(
		ObjectIS,
		XDTODataObject.objectID.ID,
		XDTODataObject.objectID.type);
	
	// We will automatically add links by links from the IP object.
	If GetFunctionalOption("UseRelatedDocuments1CDocumentManagement")
			And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.0.1")
			And Not TheseRules.DoNotCreateRelationsByLinks
			And IntegrationWith1CDocumentManagementClientServer.IsDocument(XDTODataObject.objectID.type) Then
		
		SuitableObjects = GetSuitableObjectsToAddLinksTo(ObjectIS);
		
		If SuitableObjects.Count() = 0 Then
			Return XDTODataObject;
		EndIf;
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		
		For Each SuitableObject In SuitableObjects Do
			
			LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
				SuitableObject);
			
			If LinkedObjectBefore = Undefined Then
				
				Rules = IntegrationWith1CDocumentManagementServerCall.SuitableRules(SuitableObject);
				If Rules.Count() <> 1 Then
					Continue;
				EndIf;
				
				If Not IntegrationWith1CDocumentManagementClientServer.IsDocument(Rules[0].ObjectTypeDM) Then
					Continue;
				EndIf;
				
			EndIf;
			
			If LinkedObjectBefore = Undefined Then // Create a document in BEFORE.
				
				NewObjectBefore = CreateMapItemUsingRule(
					Proxy,
					SuitableObject,
					Rules[0].Ref);
				
				If TypeOf(NewObjectBefore) = Type("XDTODataObject") Then
					LinkedDocument_ = New Structure("ID, Type, Presentation",
						NewObjectBefore.objectID.ID,
						NewObjectBefore.objectID.type,
						NewObjectBefore.name);
				Else // error message.
					EventName = NStr("vi = 'Tự động tạo đối tượng liên kết';
									|ru = 'Автоматическое создание связанного объекта';
									|en = 'Automatic creation of linked object'; fa = 'Automatic creation of linked object';
									|it = 'Creazione automatica dell''oggetto collegato';
									|pl = 'Automatyczne tworzenie powiązanego obiektu';
									|tr = 'İlgili nesnenin otomatik olarak oluşturulması'");
					WriteLogEvent(
						IntegrationWith1CDocumentManagementCore.EventLogEventName(EventName),
						EventLogLevel.Error,,,
						NewObjectBefore);
					ExceptionText = StrTemplate(NStr("vi = 'Không thể tạo chứng từ liên kết đối với ""%1"":
						|%2';
						|ru = 'Не удалось создать связанный документ для ""%1"":
						|%2';
						|en = 'Cannot create a linked document for ""%1"":
						|%2'; fa = 'Cannot create a linked document for ""%1"":
						|%2';
						|it = 'Non è stato possibile creare il documento collegato per ""%1"":
						|%2';
						|pl = 'Nie udało się utworzyć powiązanego dokumentu dla ""%1"":
						|%2';
						|tr = '""%1"":
						|%2 için ilgili belge oluşturulamadı'"),
						SuitableObject,
						NewObjectBefore);
					Raise ExceptionText;
				EndIf;
				
			Else // Add a link to an existing document BEFORE.
				
				If Not IntegrationWith1CDocumentManagementClientServer.IsDocument(LinkedObjectBefore.type) Then
					Continue;
				EndIf;
				
				LinkedDocument_ = New Structure("ID, Type, Presentation",
					LinkedObjectBefore.ID,
					LinkedObjectBefore.type,
					LinkedObjectBefore.name);
				
			EndIf;
			
			SourceDocument_ = New Structure("ID, Type, Presentation",
				XDTODataObject.objectID.ID,
				XDTODataObject.objectID.type,
				XDTODataObject.name);
			
			IntegrationWith1CDocumentManagementServerCall.AddDocumentLink(
				SourceDocument_,
				LinkedDocument_);
			
		EndDo;
		
	EndIf;
	
	Return XDTODataObject;
	
EndFunction

// Creates a folder of internal documents with the specified properties.
//
// Parameters:
//   Properties - See IntegrationWith1CDocumentManagement.StructureOfDetailsOfInternalDocumentsFolderToFillIn.
//
// Returns:
//   XDTODataObject - An XDTO object of type DMInternalDocumentFolder or DMError.
//
Function CreateFolderOfInternalVDODocuments(Properties) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Folder = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMInternalDocumentFolder");
	Folder.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		"",
		"DMInternalDocumentFolder");
	
	Folder.name = Properties.Name;
	FillInXDTPropertyOfOizPropsStructure(
		Proxy,
		Folder,
		"description",
		Properties,
		"LongDesc");
	FillInXDTPropertyOfOizPropsStructure(
		Proxy,
		Folder,
		"responsible",
		Properties,
		"EmployeeResponsible");
	FillInXDTPropertyOfOizPropsStructure(
		Proxy,
		Folder,
		"creationDate",
		Properties,
		"CreationDate");
	FillInXDTPropertyOfOizPropsStructure(
		Proxy,
		Folder,
		"parent",
		Properties,
		"Parent");
	
	Return IntegrationWith1CDocumentManagementCore.CreateNewObject(Proxy, Folder).object;
	
EndFunction

// Returns the structure of the Document Type TO be filled in by the passed type name.
//
// Parameters:
//   ObjectTypeDM - String - object type: DMInternalDocumentType or DMIncomingDocumentType or DMOutgoingDocumentType.
//
// Returns:
//   Structure - the details of the object of the specified type to be filled in.
//
Function StructureOfTheAttributesOfTheFilledDocumentKindDM(ObjectTypeDM) Export
	
	AttributesStructure1 = New Structure;
	
	// Banking details common to all types.
	AttributesStructure1.Insert("Type", ObjectTypeDM);
	AttributesStructure1.Insert("Name");
	AttributesStructure1.Insert("UseDueDate");
	AttributesStructure1.Insert("ConsiderDocumentAmount");
	AttributesStructure1.Insert("Autonumbering");
	AttributesStructure1.Insert("ProhibitCreationOfDocumentsThatAreNotTemplate");
	AttributesStructure1.Insert("AccountingByProductOfCasesIsIncluded");
	
	If ObjectTypeDM = "DMInternalDocumentType" Then
		AttributesStructure1.Insert("KeepRecordsByAddressees");
		AttributesStructure1.Insert("KeepRecordsOfCFItem");
		AttributesStructure1.Insert("KeepRecordsOfCounterparties");
		AttributesStructure1.Insert("KeepRecordsOfParties");
		AttributesStructure1.Insert("IsRequestForPayment");
		AttributesStructure1.Insert("ConsiderExpirationDate");
		AttributesStructure1.Insert("KeepRecordsOfOrganizations");
		AttributesStructure1.Insert("KeepRecordsOfGoodsAndServices");
		AttributesStructure1.Insert("SigningOption");
		AttributesStructure1.Insert("SigningOptionID");
		AttributesStructure1.Insert("SigningOptionType");
		AttributesStructure1.Insert("UseAssertion");
		AttributesStructure1.Insert("UseSigning");
	ElsIf ObjectTypeDM = "DMIncomingDocumentType" Then
		
	ElsIf ObjectTypeDM = "DMOutgoingDocumentType" Then
		AttributesStructure1.Insert("ConsiderRecipientSIncomingNumberAndDate");
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kiểu ""%1"" không tương ứng với dạng chứng từ DM';
				|ru = 'Тип ""%1"" не относится к видам документов ДО';
				|en = 'Type ""%1"" does not apply to DI documents types'; fa = 'Type ""%1"" does not apply to DI documents types';
				|it = 'Il tipo ""%1"" non si riferisce ai tipi di documenti di DM';
				|pl = 'Typ ""%1"" nie należy do rodzajów dokumentów Document Management';
				|tr = '""%1"" türü İş Akışı belge türlerine ait değil'"),
			ObjectTypeDM);
	EndIf;
	
	Return AttributesStructure1;
	
EndFunction

// Returns the structure of the Internal Documents Folder TO be filled in.
//
// Returns:
//   Structure - the details of the object of the specified type to be filled in.
//
Function StructureOfDetailsOfInternalDocumentsFolderToFillIn() Export
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Name");
	AttributesStructure1.Insert("LongDesc");
	AttributesStructure1.Insert("EmployeeResponsible");
	AttributesStructure1.Insert("EmployeeResponsibleID");
	AttributesStructure1.Insert("EmployeeResponsibleType");
	AttributesStructure1.Insert("CreationDate");
	AttributesStructure1.Insert("Parent");
	AttributesStructure1.Insert("ParentID");
	AttributesStructure1.Insert("ParentType");
	
	Return AttributesStructure1;
	
EndFunction

#EndRegion

#Region Files

// Returns a list of XDTO files by consumer object.
//
// Parameters:
//   OwnerID - UUID - the unique identifier of the consumer object.
//   OwnerName - String - representation of the consumer object.
//   OwnerType - String - the type of the consumer object (the full name of the metadata object is used).
//
// Returns:
//   XDTODataObject - A list of XDTO objects of the DMFile type.
//
Function FilesByObjectConsumer(OwnerID, OwnerName, OwnerType) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetFileListRequest");
	
	Owners = Query.externalObjects; // XDTOList
	Owners.Add(
		IntegrationWith1CDocumentManagementCore.CreateExternalObject(
			Proxy,,
			String(OwnerID),
			OwnerType,
			OwnerName));
	
	FieldsReceived = Query.columnSet; // XDTOList
	
	FieldsReceived.Add("objectID");
	FieldsReceived.Add("signed");
	FieldsReceived.Add("name");
	FieldsReceived.Add("size");
	FieldsReceived.Add("creationDate");
	FieldsReceived.Add("modificationDateUniversal");
	FieldsReceived.Add("author");
	FieldsReceived.Add("extension");
	FieldsReceived.Add("description");
	FieldsReceived.Add("editing");
	FieldsReceived.Add("encrypted");
	
	FieldsReceived.Add("signatures.author");
	FieldsReceived.Add("signatures.date");
	FieldsReceived.Add("signatures.comment");
	FieldsReceived.Add("signatures.signature");
	FieldsReceived.Add("signatures.thumbprint");
	FieldsReceived.Add("signatures.signer");
	FieldsReceived.Add("signatures.certificate");
	FieldsReceived.Add("signatures.signatureFileName");
	
	Files = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Files);
	
	Return Files;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// BID update handler for version 1.1.6.1. Updating the names of the integration rules
// and setting the Key details for the types of documents TO.
//
Procedure RestoreVersion_1_1_6_1() Export
	
	RuleRequest = New Query(
		"SELECT
		|	Rules.Ref AS Ref
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rules
		|WHERE
		|	(Rules.ObjectTypeIS <> """"
		|				AND (CAST(Rules.ObjectPresentationIS AS STRING(1))) = """"
		|			OR Rules.ObjectTypeDM <> """"
		|				AND (CAST(Rules.ObjectPresentationDM AS STRING(1))) = """")");
	
	RuleSelection_ = RuleRequest.Execute().Select();
	While RuleSelection_.Next() Do
		
		RuleObject_ = RuleSelection_.Ref.GetObject();
		Try
			RuleObject_.Lock();
		Except
			WriteLogEvent(
				IntegrationWith1CDocumentManagementCore.EventLogEventName(),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Continue;
		EndTry;
		
		For Each ExportRule In RuleObject_.AttributeFillingRulesDM Do
			If ExportRule.AttributeNameObjectDM = "documentType" Then
				ExportRule.KeyAttribute_ = True;
			EndIf;
		EndDo;
		
		InfobaseUpdate.WriteData(RuleObject_);
		
	EndDo;
	
EndProcedure

// BID update handler for version 1.1.8.4. Setting the "Do not create links by links" flag.
//
Procedure RestoreVersion_1_1_8_4() Export
	
	RuleRequest = New Query(
		"SELECT
		|	Rules.Ref AS Ref
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rules
		|WHERE
		|	NOT Rules.DoNotCreateRelationsByLinks");
	
	RuleSelection_ = RuleRequest.Execute().Select();
	While RuleSelection_.Next() Do
		
		RuleObject_ = RuleSelection_.Ref.GetObject();
		Try
			RuleObject_.Lock();
		Except
			WriteLogEvent(
				IntegrationWith1CDocumentManagementCore.EventLogEventName(),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Continue;
		EndTry;
		
		RuleObject_.DoNotCreateRelationsByLinks = True;
		
		InfobaseUpdate.WriteData(RuleObject_);
		
	EndDo;
	
EndProcedure

// BID update handler for version 1.1.12.2. Setting the mode for changing the data of the completed document.
//
Procedure RestoreVersion_1_1_12_2() Export
	
	EmptyMode = Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.EmptyRef();
	RuleRequest = New Query(
		"SELECT DISTINCT
		|	ImportingRules.Ref AS Ref
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesIS AS ImportingRules
		|WHERE
		|	ImportingRules.ModeOfChangingTheDataOfThePostedDocument = &EmptyMode
		|	AND ImportingRules.Ref.ObjectTypeIS LIKE ""Document.%""");
	RuleRequest.SetParameter("EmptyMode", EmptyMode);
	
	RuleSelection_ = RuleRequest.Execute().Select();
	While RuleSelection_.Next() Do
		
		RuleObject_ = RuleSelection_.Ref.GetObject();
		Try
			RuleObject_.Lock();
		Except
			WriteLogEvent(
				IntegrationWith1CDocumentManagementCore.EventLogEventName(),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Continue;
		EndTry;
		
		For Each LoadingRule In RuleObject_.AttributeFillingRulesIS Do
			If LoadingRule.ModeOfChangingTheDataOfThePostedDocument = EmptyMode Then
				LoadingRule.ModeOfChangingTheDataOfThePostedDocument =
					Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited;
			EndIf;
		EndDo;
		
		InfobaseUpdate.WriteData(RuleObject_);
		
	EndDo;
	
EndProcedure

// The BID update handler for version 3.0.4.2. Processes entries in the tabular part of the rule for filling in the requestionis,
// clears the value of the Attribute of the change mode of the specified valid document for Catalogs.
//
Procedure RestoreVersion_3_0_4_2() Export
	
	EmptyMode = Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.EmptyRef();
	RuleRequest = New Query(
		"SELECT DISTINCT
		|	RulesForIntegrationWith1CDocumentManagement.Ref AS Ref
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement AS RulesForIntegrationWith1CDocumentManagement
		|		INNER JOIN Catalog.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesIS AS RulesForIntegrationWith1CDocumentManagementAttributeFillingRulesIS
		|		ON (RulesForIntegrationWith1CDocumentManagement.Ref = RulesForIntegrationWith1CDocumentManagementAttributeFillingRulesIS.Ref)
		|WHERE
		|	NOT RulesForIntegrationWith1CDocumentManagement.DeletionMark
		|	AND RulesForIntegrationWith1CDocumentManagement.ObjectTypeIS LIKE ""Catalog.%""
		|	AND RulesForIntegrationWith1CDocumentManagementAttributeFillingRulesIS.ModeOfChangingTheDataOfThePostedDocument <> &EmptyMode");
	RuleRequest.SetParameter("EmptyMode", EmptyMode);
	
	RuleSelection_ = RuleRequest.Execute().Select();
	While RuleSelection_.Next() Do
		
		RuleObject_ = RuleSelection_.Ref.GetObject();
		Try
			RuleObject_.Lock();
		Except
			WriteLogEvent(
				IntegrationWith1CDocumentManagementCore.EventLogEventName(),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Continue;
		EndTry;
		
		For Each String In RuleObject_.AttributeFillingRulesIS Do
			String.ModeOfChangingTheDataOfThePostedDocument = EmptyMode;
		EndDo;
		
		InfobaseUpdate.WriteData(RuleObject_);
		
	EndDo;
	
EndProcedure

// A handler that checks whether the integration rules match the configuration metadata.
//
Procedure CheckIfIntegrationRulesMatchMetadata() Export
	
	If Not UseIntegration() Then
		Return;
	EndIf;
	
	RuleRequest = New Query(
		"SELECT
		|	Rules.Ref AS Ref
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rules
		|WHERE
		|	NOT DeletionMark
		|	AND ObjectTypeIS <> """"");
	
	RuleSelection_ = RuleRequest.Execute().Select();
	While RuleSelection_.Next() Do
		
		RuleObject_ = RuleSelection_.Ref.GetObject(); // CatalogObject.RulesForIntegrationWith1CDocumentManagement
		Try
			RuleObject_.Lock();
		Except
			WriteLogEvent(
				IntegrationWith1CDocumentManagementCore.EventLogEventName(),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Continue;
		EndTry;
		
		NeedEntry = False;
		
		MetadataObject = Metadata.FindByFullName(RuleObject_.ObjectTypeIS); // MetadataObjectDocument
		
		If MetadataObject = Undefined Then
			
			MessageText = StrTemplate(
				NStr("vi = 'Đã đặt dấu xóa quy tắc đối với đối tượng không tồn tại %1';
					|ru = 'Помечено на удаление правило для несуществующего объекта %1';
					|en = 'The rule is marked for deletion for the non-existent object %1'; fa = 'The rule is marked for deletion for the non-existent object %1';
					|it = 'Regola per l''oggetto inesistente %1 contrassegnata per l''eliminazione';
					|pl = 'Zaznaczono do usunięcie regułę dla nieistniejącego obiektu %1';
					|tr = 'Var olmayan nesne için kural silinmek üzere işaretlendi %1'",
					Common.DefaultLanguageCode()),
				RuleObject_.ObjectTypeIS);
			WriteLogEvent(
				IntegrationWith1CDocumentManagementCore.EventLogEventName(),
				EventLogLevel.Error,,,
				MessageText);
			
			RuleObject_.DeletionMark = True;
			NeedEntry = True;
			
		Else
			
			For Each Rule In RuleObject_.AttributeFillingRulesDM Do
				
				If Rule.Variant <> Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute
						Or Rule.IsAdditionalAttributeIS
						Or Rule.ThisIsTable
						Or ValueIsFilled(Rule.Table) Then
					Continue;
				EndIf;
				
				PointPosition = StrFind(Rule.AttributeNameObjectIS, ".");
				If PointPosition = 0 Then
					AttributeNameObjectIS = Rule.AttributeNameObjectIS;
				Else
					AttributeNameObjectIS = Left(Rule.AttributeNameObjectIS, PointPosition - 1);
				EndIf;
				
				If MetadataObject.Attributes.Find(AttributeNameObjectIS) = Undefined
						And AttributeNameObjectIS <> "Presentation" Then
					
					Found = False;
					For Each StandardAttribute In MetadataObject.StandardAttributes Do
						If StandardAttribute.Name = AttributeNameObjectIS Then
							Found = True;
							Break;
						EndIf;
					EndDo;
					
					If Not Found Then
						
						MessageText = StrTemplate(NStr("vi = 'Đã xóa quy tắc kết xuất đối với mục tin không tồn tại %1';
														|ru = 'Очищено правило выгрузки для несуществующего реквизита %1';
														|en = 'Export rule was cleared for non-existing attribute %1'; fa = 'Export rule was cleared for non-existing attribute %1';
														|it = 'Regola di upload per l''attributo inesistente %1 cancellata';
														|pl = 'Wyczyszczono regułę eksportu dla nieistniejącego atrybutu %1';
														|tr = 'Var olmayan öznitelik için kaldırma kuralı temizlendi %1'"),
							Rule.AttributeNameObjectIS);
						WriteLogEvent(
							IntegrationWith1CDocumentManagementCore.EventLogEventName(),
							EventLogLevel.Error,,
							RuleSelection_.Ref,
							MessageText);
						NeedEntry = True;
						
						Rule.Variant = Undefined;
						Rule.AttributeNameObjectIS = Undefined;
						Rule.AttributeValueDM = MessageText;
						
					EndIf;
					
				EndIf;
				
			EndDo;
		
			For Each Rule In RuleObject_.AttributeFillingRulesIS Do
				
				If Rule.Variant <> Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute
						Or Rule.IsAdditionalAttributeIS
						Or Rule.ThisIsTable
						Or ValueIsFilled(Rule.Table) Then
					Continue;
				EndIf;
				
				If MetadataObject.Attributes.Find(Rule.AttributeNameObjectIS) = Undefined
						And Rule.AttributeNameObjectIS <> "Presentation" Then
					
					Found = False;
					For Each StandardAttribute In MetadataObject.StandardAttributes Do
						If StandardAttribute.Name = Rule.AttributeNameObjectIS Then
							Found = True;
							Break;
						EndIf;
					EndDo;
					
					If Not Found Then
						
						MessageText = StrTemplate(NStr("vi = 'Đã xóa quy tắc kết nhập đối với mục tin không tồn tại %1';
														|ru = 'Очищено правило загрузки для несуществующего реквизита %1';
														|en = 'Import rule was cleared for the non-existing attribute %1'; fa = 'Import rule was cleared for the non-existing attribute %1';
														|it = 'Regola di download per l''attributo inesistente %1 cancellata';
														|pl = 'Wyczyszczono regułę importu dla nieistniejącego atrybutu %1';
														|tr = 'Var olmayan öznitelik için indirme kuralı temizlendi %1'"),
							Rule.AttributeNameObjectIS);
						WriteLogEvent(
							IntegrationWith1CDocumentManagementCore.EventLogEventName(),
							EventLogLevel.Error,,
							RuleSelection_.Ref,
							MessageText);
						NeedEntry = True;
						
						Rule.Variant = Undefined;
						Rule.AttributeNameObjectIS = Undefined;
						Rule.AttributeValueIS = MessageText;
						Rule.ShouldUpdate = False;
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If NeedEntry Then
			InfobaseUpdate.WriteData(RuleObject_);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure CoordinationIsPossible(Parameters, ResultAddress) Export
	
	IntegrationWith1CDocumentManagementCoreServerCall.SetAuthorizationSettingsInSessionSettings(
		Parameters.IntegrationWith1CDocumentManagementUsername,
		Parameters.IntegrationWith1CDocumentManagementPassword,
		Parameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed,
		Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed);
	IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings();
	
	Result = New Structure("Perhaps_, ErrorDescription", True, "");
	
	// Let's check the possibility of starting approval.
	If Not IntegrationWith1CDocumentManagementServerCall.UserIsAllowedToStartMatching(
			Parameters.SubjectOfApproval, Result.ErrorDescription) Then
		If Result.ErrorDescription = "" Then // Default text.
			Result.ErrorDescription = NStr("vi = 'Không đủ quyền để khởi chạy quy trình thống nhất trong 1C:Document Management.';
											|ru = 'Недостаточно прав для запуска согласования в 1С:Документообороте.';
											|en = 'Insufficient rights for approval launch in 1C:Document Management.'; fa = 'Insufficient rights for approval launch in 1C:Document Management.';
											|it = 'Diritti insufficienti per l''avvio dell''accordo in 1C:Document Management.';
											|pl = 'Nie wystarcza praw do uruchomienia uzgodnienia w 1C:Document Management.';
											|tr = '1C:Document Management''te anlaşmayı başlatmak için yeterli yetki mevcut değil.'");
		EndIf;
		Result.Perhaps_ = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	DocumentType = New Structure("name, ID, type");
	
	// Let's check if there is a related object in BEFORE.
	LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
		Parameters.SubjectOfApproval);
	If LinkedObjectBefore = Undefined Then
		// Let's check if it is possible to create a linked object in BEFORE.
		SuitableRules = IntegrationWith1CDocumentManagementCoreServerCall.FindCreateAppropriateRules(
			Parameters.SubjectOfApproval);
		If SuitableRules.Count() = 1 Then
			DocumentType.name = SuitableRules[0].ObjectPresentationDM;
			DocumentType.ID = SuitableRules[0].IDOfDocumentType;
			DocumentType.type = SuitableRules[0].TypeOfDocumentType;
		Else
			Result.ErrorDescription = NStr("vi = 'Không thể tự động tạo chứng từ liên kết trong DM.';
											|ru = 'Невозможно автоматически создать связанный документ в ДО.';
											|en = 'Cannot automatically create linked document in DI.'; fa = 'Cannot automatically create linked document in DI.';
											|it = 'Impossibile creare automaticamente il documento collegato in DM.';
											|pl = 'Nie można automatycznie utworzyć powiązanego dokumentu w Document Management.';
											|tr = 'İş Akışında ilgili belgeyi oluşturmak otomatik olarak mümkün değil.'");
			Result.Perhaps_ = False;
			PutToTempStorage(Result, ResultAddress);
			Return;
		EndIf;
	Else
		// Let's check if there are any business processes already running.
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
		FilterConditions = query.conditions; // XDTOList
		
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "target";
		Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			LinkedObjectBefore.ID,
			LinkedObjectBefore.type);
		
		FilterConditions.Add(Condition);
		
		Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
			Proxy,
			"DMBusinessProcessApproval",
			query);
		
		If Response.items.Count() <> 0 Then
			Result.ErrorDescription = NStr("vi = 'Có quy trình thống nhất đã khởi chạy.';
											|ru = 'Есть запущенные процессы согласования.';
											|en = 'There are running approval processes.'; fa = 'There are running approval processes.';
											|it = 'Vi sono processi di omologazione avviati.';
											|pl = 'Są uruchomione procesy uzgodnienia.';
											|tr = 'Devam eden anlaşma süreçleri mevcut.'");
			Result.Perhaps_ = False;
			PutToTempStorage(Result, ResultAddress);
			Return;
		EndIf;
		
		FillPropertyValues(DocumentType, LinkedObjectBefore.documentType);
	EndIf;
	
	// Let's check if there is a default matching template.
	SuitableTemplates = IntegrationWith1CDocumentManagementServerCall.BusinessProcessTemplates(
		"ApprovalTemplates",
		DocumentType);
	If SuitableTemplates.Count() <> 1 Then
		Result.ErrorDescription = NStr("vi = 'Không thể xác định khuôn mẫu thống nhất.';
										|ru = 'Невозможно определить шаблон согласования.';
										|en = 'Cannot determine approval template.'; fa = 'Cannot determine approval template.';
										|it = 'Impossibile definire il modello di omologazione.';
										|pl = 'Nie można określić szablonu uzgodnienia.';
										|tr = 'Anlaşma numunesi belirtmek mümkün değil.'");
		Result.Perhaps_ = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure StartApproval(Parameters, ResultAddress) Export
	
	IntegrationWith1CDocumentManagementCoreServerCall.SetAuthorizationSettingsInSessionSettings(
		Parameters.IntegrationWith1CDocumentManagementUsername,
		Parameters.IntegrationWith1CDocumentManagementPassword,
		Parameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed,
		Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed);
	IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings();
	
	Result = New Structure("ExecutedSuccessfully, ErrorDescription", True, "");
	
	// Let's check if there is a related object in the BEFORE, in case of absence, we will try to create it.
	LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
		Parameters.SubjectOfApproval);
	If LinkedObjectBefore = Undefined Then
		// Let's try to create a linked object.
		SuitableRules = IntegrationWith1CDocumentManagementCoreServerCall.FindCreateAppropriateRules(
			Parameters.SubjectOfApproval);
		If SuitableRules.Count() = 1 Then
			ObjectDMOrMessage = IntegrationWith1CDocumentManagementCoreServerCall.CreateMapItemUsingRule(
				Parameters.SubjectOfApproval,
				SuitableRules[0].Ref);
				
			If TypeOf(ObjectDMOrMessage) = Type("String") Then
				// Error message
				Result.ErrorDescription = ObjectDMOrMessage;
				Result.ExecutedSuccessfully = False;
				PutToTempStorage(Result, ResultAddress);
				Return;
			Else
				// structure with a description of the created result object
				LinkedObjectBefore = ObjectDMOrMessage;
				LinkedObjectBefore.Insert("documentType",
					New Structure("name, ID, type",
						SuitableRules[0].ObjectPresentationDM,
						SuitableRules[0].IDOfDocumentType,
						SuitableRules[0].TypeOfDocumentType));
			EndIf;
		Else
			Result.ErrorDescription = NStr("vi = 'Không thể tự động tạo chứng từ liên kết trong DM.';
											|ru = 'Невозможно автоматически создать связанный документ в ДО.';
											|en = 'Cannot automatically create linked document in DI.'; fa = 'Cannot automatically create linked document in DI.';
											|it = 'Impossibile creare automaticamente il documento collegato in DM.';
											|pl = 'Nie można automatycznie utworzyć powiązanego dokumentu w Document Management.';
											|tr = 'İş Akışında ilgili belgeyi oluşturmak otomatik olarak mümkün değil.'");
			Result.ExecutedSuccessfully = False;
			PutToTempStorage(Result, ResultAddress);
			Return;
		EndIf;
	EndIf;
	
	// Let's check if there is a default matching template.
	SuitableTemplates = IntegrationWith1CDocumentManagementServerCall.BusinessProcessTemplates(
		"ApprovalTemplates",
		LinkedObjectBefore.documentType);
	If SuitableTemplates.Count() <> 1 Then
		Result.ErrorDescription = NStr("vi = 'Không thể xác định khuôn mẫu thống nhất.';
										|ru = 'Невозможно определить шаблон согласования.';
										|en = 'Cannot determine approval template.'; fa = 'Cannot determine approval template.';
										|it = 'Impossibile definire il modello di omologazione.';
										|pl = 'Nie można określić szablonu uzgodnienia.';
										|tr = 'Anlaşma numunesi belirtmek mümkün değil.'");
		Result.ExecutedSuccessfully = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	// Let's start the process according to the template.
	If Not IntegrationWith1CDocumentManagementServerCall.StartMatchingTemplate(
			SuitableTemplates[0].Value, LinkedObjectBefore) Then
		Result.ErrorDescription = StrTemplate(NStr("vi = 'Không thể khởi chạy quy trình thống nhất theo khuôn mẫu ""%1"".';
													|ru = 'Не удалось запустить согласование по шаблону ""%1"".';
													|en = 'Cannot start approval based on template ""%1"".'; fa = 'Cannot start approval based on template ""%1"".';
													|it = 'Non è stato possibile avviare l''omologazione da modello ""%1"".';
													|pl = 'Nie udało się uruchomić uzgodnienia według szablonu ""%1"".';
													|tr = '""%1"" numunesiyle anlaşma başlatılamadı.'"),
			SuitableTemplates[0].Value.name);
		Result.ExecutedSuccessfully = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure AgreementInterruptionIsPossible(Parameters, ResultAddress) Export
	
	IntegrationWith1CDocumentManagementCoreServerCall.SetAuthorizationSettingsInSessionSettings(
		Parameters.IntegrationWith1CDocumentManagementUsername,
		Parameters.IntegrationWith1CDocumentManagementPassword,
		Parameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed,
		Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed);
	IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings();
	
	Result = New Structure("Perhaps_, ErrorDescription", True, "");
	
	// Let's check the existence of a linked object.
	LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
		Parameters.SubjectOfApproval);
	If LinkedObjectBefore = Undefined Then
		Result.ErrorDescription = NStr("vi = 'Không tìm thấy chứng từ liên kết trong DM.';
										|ru = 'Связанный документ в ДО не найден.';
										|en = 'Cannot find the linked document in DI.'; fa = 'Cannot find the linked document in DI.';
										|it = 'Documento collegato in DM non trovato.';
										|pl = 'Nie znaleziono powiązanego dokumentu w Document Management.';
										|tr = 'İş Akışında ilgili belge bulunamadı.'");
		Result.Perhaps_ = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	// Let's check the possibility of interrupting the agreement.
	If Not IntegrationWith1CDocumentManagementServerCall.UserIsAllowedToInterruptNegotiation(
			Parameters.SubjectOfApproval, LinkedObjectBefore, Result.ErrorDescription) Then
		If Result.ErrorDescription = "" Then // The default warning.
			Result.ErrorDescription = NStr("vi = 'Không đủ quyền để ngắt quy trình thống nhất trong 1C:Document Management.';
											|ru = 'Недостаточно прав для прерывания согласования в 1С:Документообороте.';
											|en = 'Insufficient rights for approval cancellation in 1C:Document Management.'; fa = 'Insufficient rights for approval cancellation in 1C:Document Management.';
											|it = 'Diritti insufficienti per l''interruzione dell''omologazione in 1C:Document Management.';
											|pl = 'Nie wystarcza praw do przerywania uzgodnienia w 1C:Document Management.';
											|tr = '1C:Document Management''te anlaşmayı kesintiye uğratmak için yeterli hak mevcut değil.'");
		EndIf;
		Result.Perhaps_ = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = query.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "target";
	Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		LinkedObjectBefore.ID,
		LinkedObjectBefore.type);
	
	FilterConditions.Add(Condition);
	
	Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMBusinessProcessApproval",
		query);
	
	If Response.items.Count() = 0 Then
		Result.ErrorDescription = NStr("vi = 'Không có quy trình thống nhất đã khởi chạy.';
										|ru = 'Нет запущенных процессов согласования.';
										|en = 'No running approval processes.'; fa = 'No running approval processes.';
										|it = 'Non vi sono processi di omologazione avviati.';
										|pl = 'Brak uruchomionych procesów uzgodnienia.';
										|tr = 'Başlatılan anlaşma süreçleri mevcut değil.'");
		Result.Perhaps_ = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure AbortApproval(Parameters, ResultAddress) Export
	
	IntegrationWith1CDocumentManagementCoreServerCall.SetAuthorizationSettingsInSessionSettings(
		Parameters.IntegrationWith1CDocumentManagementUsername,
		Parameters.IntegrationWith1CDocumentManagementPassword,
		Parameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed,
		Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed);
	IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings();
	
	Result = New Structure("ExecutedSuccessfully, ErrorDescription", True, "");
	
	// Find the related object in TO.
	LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
		Parameters.SubjectOfApproval);
	If LinkedObjectBefore = Undefined Then
		Result.ErrorDescription = NStr("vi = 'Không tìm thấy chứng từ liên kết trong DM.';
										|ru = 'Связанный документ в ДО не найден.';
										|en = 'Cannot find the linked document in DI.'; fa = 'Cannot find the linked document in DI.';
										|it = 'Documento collegato in DM non trovato.';
										|pl = 'Nie znaleziono powiązanego dokumentu w Document Management.';
										|tr = 'İş Akışında ilgili belge bulunamadı.'");
		Result.ExecutedSuccessfully = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	// Let's interrupt the coordination.
	If Not IntegrationWith1CDocumentManagementServerCall.AbortApproval(LinkedObjectBefore) Then
		Result.ErrorDescription = NStr("vi = 'Không thể ngắt quy trình thống nhất.';
										|ru = 'Не удалось прервать согласование.';
										|en = 'Cannot abort approval.'; fa = 'Cannot abort approval.';
										|it = 'Non è stato possibile interrompere l''omologazione.';
										|pl = 'Nie udało się przerwać uzgodnienia.';
										|tr = 'Anlaşma kesintiye uğratılamadı.'");
		Result.ExecutedSuccessfully = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure StateOfApproval(Parameters, ResultAddress) Export
	
	IntegrationWith1CDocumentManagementCoreServerCall.SetAuthorizationSettingsInSessionSettings(
		Parameters.IntegrationWith1CDocumentManagementUsername,
		Parameters.IntegrationWith1CDocumentManagementPassword,
		Parameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed,
		Parameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed);
	IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings();
	
	Result = New Structure("ReceivedSuccessfully, State, Explanation", True, Undefined, "");
	
	// Find the related object in TO.
	LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
		Parameters.SubjectOfApproval);
	If LinkedObjectBefore = Undefined Then
		Result.Explanation = NStr("vi = 'Không tìm thấy chứng từ liên kết trong DM.';
									|ru = 'Связанный документ в ДО не найден.';
									|en = 'Cannot find the linked document in DI.'; fa = 'Cannot find the linked document in DI.';
									|it = 'Documento collegato in DM non trovato.';
									|pl = 'Nie znaleziono powiązanego dokumentu w Document Management.';
									|tr = 'İş Akışında ilgili belge bulunamadı.'");
		Result.ReceivedSuccessfully = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	// Get the object from BEFORE.
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
	ListOfObjects = Query.objectIDs; // XDTOList
	FieldsReceived = Query.columnSet; // XDTOList
	
	ListOfObjects.Add(
		IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			LinkedObjectBefore.ID,
			LinkedObjectBefore.type));
	FieldsReceived.Add("statusApproval");
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMError") Then
		Result.Explanation = TrimAll(Response.description);
		Result.ReceivedSuccessfully = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	ElsIf Response.objects.Count() = 1 Then
		If Response.objects[0].statusApproval <> Undefined And Response.objects[0].statusApproval.objectID.ID <> "" Then
			Result.State = Enums.ApprovalStatesIn1CDocumentManagement[
				Response.objects[0].statusApproval.objectID.ID];
		EndIf;
	Else
		Result.Explanation = NStr("vi = 'Không thể nhận trạng thái thống nhất.';
									|ru = 'Не удалось получить статус согласования.';
									|en = 'Cannot receive approval status.'; fa = 'Cannot receive approval status.';
									|it = 'Non è stato possibile ricevere lo stato di omologazione.';
									|pl = 'Nie udało się otrzymać statusu uzgodnienia.';
									|tr = 'Anlaşma durumu alınamadı.'");
		Result.ReceivedSuccessfully = False;
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

// Adds a timekeeping switching command.
//
// Parameters:
//   Form - ClientApplicationForm:
//     * Object - DefinedType.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable
//              - DefinedType.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable
//   CommandLocation - FormGroup
//                         - Undefined
//   Ref - AnyRef - a reference to the IP object, which is the main object of the Form.
//
Procedure AddSwitchTimekeepingCommand(Form, Val CommandLocation, Ref)
	
	ThisFormIsMetadata = Metadata.FindByFullName(Form.FormName);
	MetadataParent = ThisFormIsMetadata.Parent();
	
	If TypeOf(MetadataParent) = Type("ConfigurationMetadataObject")
			Or Metadata.DocumentJournals.Contains(MetadataParent)
			Or Metadata.DataProcessors.Contains(MetadataParent)
			Or Not MetadataParent.DefaultObjectForm = ThisFormIsMetadata Then
		Return;
	EndIf;
	
	If CommandLocation = Undefined Then
		CommandLocation = Form.CommandBar;
	EndIf;
	
	If ValueIsFilled(Ref) Then
		Rules = IntegrationWith1CDocumentManagementServerCall.SuitableRules(Ref);
		TimekeepingIsAvailable = False;
		For Each Rule In Rules Do
			TimekeepingIsAvailable = TimekeepingIsAvailable
				Or IntegrationWith1CDocumentManagementClientServer.IsDocument(Rule.ObjectTypeDM)
				Or IntegrationWith1CDocumentManagementClientServer.ThisIsBusinessProcessTask(Rule.ObjectTypeDM);
		EndDo;
		If Not TimekeepingIsAvailable Then
			Return;
		EndIf;
		
		Try
			ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
			If IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
				TimingParameters = IntegrationWith1CDocumentManagementServerCall.ObjectTimingParameters(Ref);
			Else
				Return;
			EndIf;
		Except
			ErrorPresentation = StrTemplate(
				NStr("vi = 'Không thể nhận tham số đồng hồ tính thời gian (%1)';
					|ru = 'Не удалось получить параметры хронометража (%1)';
					|en = 'Cannot get timing parameters (%1)'; fa = 'Cannot get timing parameters (%1)';
					|it = 'Non è stato possibile ricevere i parametri della crono-analisi (%1)';
					|pl = 'Nie udało się otrzymać parametrów chronometrażu (%1)';
					|tr = 'Kronometre parametreleri alınamadı (%1)'"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(
				IntegrationWith1CDocumentManagementCore.EventLogEventName(),
				EventLogLevel.Error,,,
				ErrorPresentation);
			Return;
		EndTry;
		
	EndIf;
	
	CommandName = "IntegrationWith1CDocumentManagement_SwitchTimekeeping";
	
	If Form.Commands.Find(CommandName) = Undefined Then
		FormCommand = Form.Commands.Add(CommandName);
		FormCommand.Action = "Attachable_ExecuteIntegrationCommand";
		FormCommand.Title = NStr("vi = 'Chuyển đổi đồng hồ đếm thời gian';
								|ru = 'Переключить хронометраж';
								|en = 'Switch timing'; fa = 'تغییر زمان‌بندی';
								|it = 'Passare alla crono-analisi';
								|pl = 'Przełącz chronometraż';
								|tr = 'Kronometreyi etkinleştir'");
		FormCommand.ToolTip = NStr("vi = 'Chuyển đổi đồng hồ đếm thời gian';
									|ru = 'Переключить хронометраж';
									|en = 'Switch timing'; fa = 'تغییر زمان‌بندی';
									|it = 'Passare alla crono-analisi';
									|pl = 'Przełącz chronometraż';
									|tr = 'Kronometreyi etkinleştir'");
		FormCommand.ModifiesStoredData = False;
		FormCommand.Representation = ButtonRepresentation.Auto;
		FormCommand.Picture = PictureLib.SetTime;
	EndIf;
	
	OriginalElementName = "IntegrationWith1CDocumentManagement_SwitchTimekeeping";
	
	TagName = OriginalElementName;
	While Form.Items.Find(TagName) <> Undefined Do
		TagName = Form.Items.Find(TagName).Name;
		Iterator_SSLy = StrReplace(TagName, OriginalElementName, "");
		Iterator_SSLy = Number(?(IsBlankString(Iterator_SSLy),"0",Iterator_SSLy));
		Iterator_SSLy = Iterator_SSLy + ?(Iterator_SSLy = 0, 2, 1);
		TagName = OriginalElementName + Format(Iterator_SSLy,"NG=0");
	EndDo;
	
	NewItem = Form.Items.Add(TagName, Type("FormButton"), CommandLocation);
	NewItem.Type = FormButtonType.CommandBarButton;
	NewItem.CommandName = CommandName;
	
	If ValueIsFilled(Ref) Then
		If TimingParameters.TimekeepingEnabled Then
			NewItem.Check = True;
		EndIf;
	Else
		NewItem.Enabled = False;
	EndIf;
	
EndProcedure

Procedure AddSpecifyLaborCostsCommand(Form, Val CommandLocation)
	
	If CommandLocation = Undefined Then
		CommandLocation = Form.CommandBar;
	EndIf;
	
	CommandName = "IntegrationWith1CDocumentManagement_SpecifyTheLaborCosts";
	
	If Form.Commands.Find(CommandName) = Undefined Then
		FormCommand = Form.Commands.Add(CommandName);
		FormCommand.Action = "Attachable_ExecuteIntegrationCommand";
		FormCommand.Title = NStr("vi = 'Chỉ ra công lao động';
								|ru = 'Указать трудозатраты';
								|en = 'Specify labor costs'; fa = 'تعیین هزینه‌های دستمزد';
								|it = 'Mostrare costo del lavoro';
								|pl = 'Wskaż nakłady pracy';
								|tr = 'İş gücü maliyetlerini işaretle'");
		FormCommand.ToolTip = NStr("vi = 'Chỉ ra công lao động';
									|ru = 'Указать трудозатраты';
									|en = 'Specify labor costs'; fa = 'تعیین هزینه‌های دستمزد';
									|it = 'Mostrare costo del lavoro';
									|pl = 'Wskaż nakłady pracy';
									|tr = 'İş gücü maliyetlerini işaretle'");
		FormCommand.ModifiesStoredData = False;
		FormCommand.Representation = ButtonRepresentation.Auto;
		FormCommand.Picture = PictureLib.AddToDailyReport;
	EndIf;
	
	OriginalElementName = "IntegrationWith1CDocumentManagement_SpecifyTheLaborCosts";
	
	TagName = OriginalElementName;
	While Form.Items.Find(TagName) <> Undefined Do
		TagName = Form.Items.Find(TagName).Name;
		Iterator_SSLy = StrReplace(TagName, OriginalElementName, "");
		Iterator_SSLy = Number(?(IsBlankString(Iterator_SSLy),"0",Iterator_SSLy));
		Iterator_SSLy = Iterator_SSLy + ?(Iterator_SSLy = 0, 2, 1);
		TagName = OriginalElementName + Format(Iterator_SSLy,"NG=0");
	EndDo;
	
	NewItem = Form.Items.Add(TagName, Type("FormButton"), CommandLocation);
	NewItem.Type = FormButtonType.CommandBarButton;
	NewItem.CommandName = CommandName;
	
EndProcedure

// Fills in the specified table details by the property of the XDTO object.
//
// Parameters:
//   ObjectToFillIn - FormDataStructure, FormDataCollection - the object or table to be filled in.
//   AttributeDetails - String, Structure, Array - description of the filled-in props.
//   XDTODataObject - XDTODataObject, XDTOList - the source of the fill data.
//   PropertyName - String - the name of the source property for the XDTO objects, or
//               - Undefined - for XDTO lists.
//
Procedure FillInDetailsFromXDTOObject(ObjectToFillIn, AttributeDetails, XDTODataObject, PropertyName = Undefined)
	
	If TypeOf(XDTODataObject) = Type("XDTOList") Then // Filling in the collection (form tables).
		
		ObjectToFillIn.Clear();
		For Each XDTOPropertyValue In XDTODataObject Do
			ItemToFill = ObjectToFillIn.Add();
			For Each MapRow In AttributeDetails Do
				FillInDetailsFromXDTOObject(
					ItemToFill,
					MapRow.Value,
					XDTOPropertyValue,
					MapRow.Key);
			EndDo;
		EndDo;
		
	ElsIf XDTODataObject.Properties().Get(PropertyName) <> Undefined
		And XDTODataObject.IsSet(PropertyName) Then // Filling in the Attributes (of the object).
		
		XDTOPropertyValue = XDTODataObject[PropertyName];
		If TypeOf(AttributeDetails) = Type("String") Then
			If TypeOf(XDTOPropertyValue) = Type("XDTODataObject") Then // Description of the link.
				ObjectToFillIn[AttributeDetails + "Type"] = XDTOPropertyValue.objectID.type;
				ObjectToFillIn[AttributeDetails + "ID"] = XDTOPropertyValue.objectID.ID;
				ObjectToFillIn[AttributeDetails] = XDTOPropertyValue.name;
			Else // Primitive type.
				ObjectToFillIn[AttributeDetails] = XDTOPropertyValue;
			EndIf;
		ElsIf TypeOf(AttributeDetails) = Type("Structure") Then
			For Each MapRow In AttributeDetails Do
				FillInDetailsFromXDTOObject(
					ObjectToFillIn,
					MapRow.Value,
					XDTOPropertyValue,
					MapRow.Key);
			EndDo;
		ElsIf TypeOf(AttributeDetails) = Type("Array") Then
			FillInDetailsFromXDTOObject(
				ObjectToFillIn[AttributeDetails[0]],
				AttributeDetails[1],
				XDTOPropertyValue);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInTaskParticipant(Proxy, TaskParticipant, Performer, MainAddressingObject,
		AdditionalAddressingObject)
	
	If Performer.Type = "DMUser" Then
		
		TaskParticipant.user = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMUser");
		TaskParticipant.user.name = Performer.Description;
		TaskParticipant.user.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			Performer.ID,
			"DMUser");
		
	ElsIf Performer.Type = "DMBusinessProcessExecutorRole" Then
		
		IntegrationWith1CDocumentManagementCore.FillInFullRole(
			Proxy,
			TaskParticipant,
			Performer,
			MainAddressingObject,
			AdditionalAddressingObject);
		
	Else
		
		Raise StrTemplate(NStr("vi = 'Đã xác định sai kiểu người tham gia nhiệm vụ: %1';
								|ru = 'Некорректно задан тип участника задачи: %1';
								|en = 'The task participant type is incorrect: %1'; fa = 'The task participant type is incorrect: %1';
								|it = 'Некорректно задан тип участника задачи: %1';
								|pl = 'The task participant type is incorrect: %1';
								|tr = 'Görev katılımcısının tipi doğru belirtilmedi: %1'"), Performer.Type);
		
	EndIf;
	
EndProcedure

Procedure SynchronizeITCHAttributesCounterparties(Proxy, XDTODataObject)
	
	If Not IntegrationWith1CDocumentManagementCore.PropertyExists(XDTODataObject, "correspondentRows") Then
		Return;
	EndIf;
	
	If XDTODataObject.correspondentRows.rows.Count() > 0 Then
		String = XDTODataObject.correspondentRows.rows[0];
		If IntegrationWith1CDocumentManagementCore.PropertySet(String, "correspondent") Then
			CopyXdtoCounterparty(Proxy, String.correspondent, XDTODataObject.correspondent);
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(String, "contact") Then
			CopyXDTOContactPerson(Proxy, String.contact, XDTODataObject.contactPerson);
		EndIf;
	Else
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "correspondent") Then
			XDTORow = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCorrespondentRow");
			
			CopyXdtoCounterparty(Proxy, XDTODataObject.correspondent, XDTORow.correspondent);
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "contactPerson") Then
				CopyXDTOContactPerson(Proxy, XDTODataObject.contactPerson, XDTORow.contact);
			EndIf;
			
			XDTODataObject.correspondentRows.rows.Add(XDTORow);
		EndIf;
	EndIf;
	
EndProcedure

Procedure CopyXdtoCounterparty(Proxy, Source, Receiver)
	
	Receiver = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCorrespondent");
	Receiver.name = Source.name;
	Receiver.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Source.objectID.ID,
		Source.objectID.type);
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(Source, "externalObject") Then
		Receiver.externalObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
			Proxy,,
			Source.externalObject.ID,
			Source.externalObject.type,
			Source.externalObject.name);
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(Source, "legalPrivatePerson") Then
		Receiver.legalPrivatePerson = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMLegalPrivatePerson");
		Receiver.legalPrivatePerson.name = Source.legalPrivatePerson.name;
		Receiver.legalPrivatePerson.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			Source.legalPrivatePerson.objectID.ID,
			Source.legalPrivatePerson.objectID.type);
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(Source, "inn") Then
		Receiver.inn = Source.inn;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(Source, "kpp") Then
		Receiver.kpp = Source.kpp;
	EndIf;
	
EndProcedure

Procedure CopyXDTOContactPerson(Proxy, Source, Receiver)
	
	Receiver = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMContactPerson");
	Receiver.name = Source.name;
	Receiver.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Source.objectID.ID,
		Source.objectID.type);
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(Source, "externalObject") Then
		Receiver.externalObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
			Proxy,,
			Source.externalObject.ID,
			Source.externalObject.type,
			Source.externalObject.name);
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(Source, "position") Then
		Receiver.position = Source.position;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(Source, "comment") Then
		Receiver.comment = Source.comment;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(Source, "correspondent") Then
		CopyXdtoCounterparty(Proxy, Source.correspondent, Receiver.correspondent);
	EndIf;
	
EndProcedure

#EndRegion
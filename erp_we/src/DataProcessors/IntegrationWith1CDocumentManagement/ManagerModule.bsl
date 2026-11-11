#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the values of the state details in the form of a Workflow document
//
// Parameters:
//   Form - ClientApplicationForm - the form of the 1C document:Document management
//   XDTODataObject - XDTODataObject - the document for which the states will be filled in
//
Procedure SetDocumentStates(Form, XDTODataObject) Export
	
	// independent document states
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
		Return
	EndIf;
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		Form,
		XDTODataObject.statusRegistration,
		"StateRegistration");
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		Form,
		XDTODataObject.statusConsideration,
		"StateReviewal");
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		Form,
		XDTODataObject.statusApproval,
		"StateApproval");
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		Form,
		XDTODataObject.statusConfirmation,
		"StateConfirmation");
	If Form.Type = "DMInternalDocument"
			And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTODataObject.statusSigning,
			"StateSigning");
	EndIf;
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		Form,
		XDTODataObject.statusPerformance,
		"StatePerformance");
	
	Attributes = New Structure;
	Attributes.Insert("StateApproval");
	Attributes.Insert("StateConfirmation");
	If Form.Type = "DMInternalDocument" Then
		Attributes.Insert("StateSigning");
	EndIf;
	Attributes.Insert("StateRegistration");
	Attributes.Insert("StateReviewal");
	Attributes.Insert("StatePerformance");
	Form.StateList.Clear();
	For Each Attribute In Attributes Do
		AttributeName = Attribute.Key;
		If ValueIsFilled(Form[AttributeName + "ID"]) Then
			Form.StateList.Add(Form[AttributeName + "ID"], Form[AttributeName]);
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
	
EndProcedure

// Sets the document title depending on the type of integrated object.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the 1C document:Document management:
//     * Description - String
//
Procedure SetDocumentTitle(Form) Export
	
	TypePresentation = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(Form.Type);
	
	PresentationOfDocument = "";
	If ValueIsFilled(Form.ExternalObject) Then
		If Common.IsDocument(Form.ExternalObject.Metadata()) Then
			PresentationOfDocument = Form.Description;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(PresentationOfDocument) And ValueIsFilled(Form.Presentation) Then
		PresentationOfDocument = Form.Presentation;
	EndIf;
	
	If Not ValueIsFilled(Form.ID) Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (tạo mới)';
				|ru = '%1 (создание)';
				|en = '%1 (Create)'; fa = '%1 (Create)';
				|it = '%1 (creazione)';
				|pl = '%1 (utworzenie)';
				|tr = '%1 (oluşturma)'"), TypePresentation);
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (%2)';
				|ru = '%1 (%2)';
				|en = '%1 (%2)'; fa = '%1 (%2)';
				|it = '%1 (%2)';
				|pl = '%1 (%2)';
				|tr = '%1 (%2)'"), PresentationOfDocument, TypePresentation);
	EndIf;
	
	Form.Title = Title;
	
EndProcedure

// Sets the properties of the timekeeping elements of the form
//
// Parameters:
//   TimekeepingEnabled - Boolean
//   SwitchTimekeepingCommand - FormCommand
//   SwitchTimekeepingElement - FormButton
//
Procedure SetPropertiesOfTimekeepingElements(TimekeepingEnabled, SwitchTimekeepingCommand,
		SwitchTimekeepingElement) Export
	
	If TimekeepingEnabled Then // Timekeeping is enabled.
		SwitchTimekeepingCommand.ToolTip = NStr("vi = 'Kết thúc đồng hồ tính thời gian';
												|ru = 'Закончить хронометраж';
												|en = 'End timing'; fa = 'End timing';
												|it = 'Concludere crono-analisi';
												|pl = 'Zakończ chronometraż';
												|tr = 'Kronometreyi bitir'");
		SwitchTimekeepingElement.Check = True;
	Else
		SwitchTimekeepingCommand.ToolTip = NStr("vi = 'Sử dụng đồng hồ tính thời gian';
												|ru = 'Включить хронометраж';
												|en = 'Enable timing'; fa = 'Enable timing';
												|it = 'Attivare crono-analisi';
												|pl = 'Włącz chronometraż';
												|tr = 'Kronometreyi etkinleştir'");
		SwitchTimekeepingElement.Check = False;
	EndIf;
	
EndProcedure

// Fills in the timekeeping parameters of the Document management object.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the document flow object.
//   XDTODataObject - XDTODataObject - contains timekeeping settings.
//
Procedure FillInTimekeepingParameters(Form, XDTODataObject) Export
	
	// Timing.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMGetChronometrationSettingsResponse")
				Or IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMSetChronometrationSettingsResponse") Then
			Parameters = XDTODataObject.settings[0];
		Else
			Parameters = XDTODataObject.chronometrationSettings;
		EndIf;
		Form.TimekeepingEnabled = Parameters.chronometrationOn;
		Form.StartDateOfTimekeeping = Parameters.beginDate;
		Form.EndDateOfTimekeeping = Parameters.endDate;
		SetPropertiesOfTimekeepingElements(
			Form.TimekeepingEnabled,
			Form.Commands.SwitchTiming,
			Form.Items.FormSwitchTiming);
	EndIf;
	
EndProcedure

// Inverts the timekeeping value
//
// Parameters:
//   Form - ClientApplicationForm
//
Procedure SwitchTiming(Form) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMSetChronometrationSettingsRequest");
	ObjectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, Form.ID, Form.Type);
	ListOfObjects = Query.objects; // XDTOList
	ListOfObjects.Add(ObjectID);
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	FillInTimekeepingParameters(Form, Result);
	
EndProcedure

// Fills in the link tree in the form by the XDTO object and starts asynchronous file retrieval.
//
// Parameters:
//   Form - ClientApplicationForm - the completed form for processing integration1sdocumentation.
//   XDTODataObject - XDTODataObject - the object from which the form details are filled in.
//   ElementToUpdateHeader - FormField, FormGroup - the element whose title is being updated.
//   AddedDocument - String - id of the document whose files should be updated, or
//                       - Undefined - indicates whether all files need to be updated.
//
// Returns:
//   String - the address in the repository where the file information will be placed.
//
Function FillInLinkTreeAndStartReceivingFiles(Form, XDTODataObject,
		ElementToUpdateHeader = Undefined, AddedDocument = Undefined) Export
	
	If XDTODataObject.Properties().Get("relations") = Undefined
			Or Not XDTODataObject.IsSet("relations") Then
		
		TreeItems = Form.LinkTree.GetItems();
		TreeItems.Clear();
		
		If ElementToUpdateHeader <> Undefined Then
			ElementToUpdateHeader.Title = NStr("vi = 'Liên kết';
												|ru = 'Связи';
												|en = 'Links'; fa = 'پیوندها';
												|it = 'Collegamenti';
												|pl = 'Links';
												|tr = 'Bağlantılar'");
		EndIf;
		
		Return Undefined;
		
	EndIf;
	
	Tree = Form.FormAttributeToValue("LinkTree"); // ValueTree
	
	// Save the files of the current documents.
	FileCache = New Map;
	For Each StringType In Tree.Rows Do
		For Each LineDocument In StringType.Rows Do
			DocumentFiles = New Array;
			For Each FileRow In LineDocument.Rows Do
				File = New Structure;
				File.Insert("ID", FileRow.ID);
				File.Insert("Type", FileRow.Type);
				File.Insert("Title", FileRow.Title);
				File.Insert("Extension", FileRow.Extension);
				File.Insert("Picture", FileRow.Picture);
				DocumentFiles.Add(File);
			EndDo;
			If DocumentFiles.Count() > 0 Then
				FileCache.Insert(LineDocument.ID, DocumentFiles);
			EndIf;
		EndDo;
	EndDo;
	
	Tree.Rows.Clear();
	
	FillOutAdvanceReport =
		(IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.28.12.CORP")
		And Form.FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.InternalDocument"
		And Form.IsRequestForPayment);
	
	RelatedDocuments = New Array;
	
	For Each Link In XDTODataObject.relations Do
		
		// Find a connection string by type or create it.
		FoundRow = Tree.Rows.Find(Link.relationType.name, "Title", False);
		If FoundRow <> Undefined Then
			LinkTypeString = FoundRow;
		Else
			LinkTypeString = Tree.Rows.Add();
			LinkTypeString.Title = Link.relationType.name;
			LinkTypeString.ID = Link.relationType.objectID.ID;
			LinkTypeString.Type = Link.relationType.objectID.type;
		EndIf;
		
		// Let's add a line for the document.
		LineDocument = LinkTypeString.Rows.Add();
		If ValueIsFilled(Link.relatedDocument.regNumber)
			And ValueIsFilled(Link.relatedDocument.regDate) Then
			LineDocument.Title = StringFunctionsClientServer.
				SubstituteParametersToString(NStr("vi = '%1 (số %2 ngày %3)';
													|ru = '%1 (№ %2 от %3)';
													|en = '%1 (No. %2 from %3)'; fa = '%1 (No. %2 from %3)';
													|it = '%1 (№%2 del %3)';
													|pl = '%1 (Nr %2 z %3)';
													|tr = '%1 (%3 itibarıyla %2 numaralı)'"),
					Link.relatedDocument.title,
					Link.relatedDocument.regNumber,
					Link.relatedDocument.regDate);
		Else
			LineDocument.Title = Link.relatedDocument.title;
		EndIf;
		LineDocument.Type = Link.relatedDocument.objectID.type;
		LineDocument.ID = Link.relatedDocument.objectID.ID;
		LineDocument.RegistrationNumber = Link.relatedDocument.regNumber;
		LineDocument.RegistrationDate = Link.relatedDocument.regDate;
		
		DocumentFiles = FileCache.Get(LineDocument.ID);
		If DocumentFiles <> Undefined Then
			For Each File In DocumentFiles Do
				FileRow = LineDocument.Rows.Add();
				FillPropertyValues(FileRow, File);
			EndDo;
		EndIf;
		
		// Prepare the parameters for asynchronous file retrieval.
		If AddedDocument = Undefined
			Or AddedDocument = Link.relatedDocument.objectID.ID Then
			LinkedDocument = New Structure;
			LinkedDocument.Insert("ID", Link.relatedDocument.objectID.ID);
			LinkedDocument.Insert("Type", Link.relatedDocument.objectID.type);
			RelatedDocuments.Add(LinkedDocument);
		EndIf;
		
		If FillOutAdvanceReport And Link.relationType.predefinedName = "АвансовыйОтчет" Then //@NON-NLS-1
			Form.ExpenseReport = Link.relatedDocument.name;
			Form.ExpenseReportID = Link.relatedDocument.objectID.ID;
			Form.ExpenseReportType = Link.relatedDocument.objectID.type;
		EndIf;
		
	EndDo;
	
	Form.ValueToFormAttribute(Tree, "LinkTree");
	
	If ElementToUpdateHeader <> Undefined Then
		If XDTODataObject.relations.Count() = 0 Then
			TitleText = NStr("vi = 'Liên kết';
							|ru = 'Связи';
							|en = 'Links'; fa = 'پیوندها';
							|it = 'Collegamenti';
							|pl = 'Powiązania';
							|tr = 'Bağlantılar'");
		Else
			TitleText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Liên kết (%1)';
					|ru = 'Связи (%1)';
					|en = 'Links (%1)'; fa = 'Links (%1)';
					|it = 'Collegamenti (%1)';
					|pl = 'Powiązania (%1)';
					|tr = 'Bağlantılar (%1)'"),
				XDTODataObject.relations.Count());
		EndIf;
		ElementToUpdateHeader.Title = TitleText;
	EndIf;
	
	If RelatedDocuments.Count() > 0 Then
		Return IntegrationWith1CDocumentManagement.GetRelatedDocumentFiles(
			RelatedDocuments);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Retrieves file descriptions from a list of related owner documents.
//
// Parameters:
//   RelatedDocuments - Array of Structure:
//     * ID - String - ID of the linked document.
//     * Type - String - the type of linked document.
//
// Returns:
//   Array of Structure:
//     * ID - String - ID of the linked document.
//     * Type - String - the type of linked document.
//     * Files - Array of Structure:
//         ** ID - String - file identifier.
//         ** Type - String - file type (DMFile).
//         ** Description - String - name without extension.
//         ** Extension - String - file extension.
//
Function GetRelatedDocumentFiles(RelatedDocuments) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfXDTOOwners = IntegrationWith1CDocumentManagementCore.GetObjects(
		Proxy,
		RelatedDocuments,
		"files");
	
	Result = New Array;
	
	For Each XDTOOwner In ListOfXDTOOwners Do
		
		Owner = New Structure;
		Owner.Insert("ID", XDTOOwner.objectID.ID);
		Owner.Insert("Type", XDTOOwner.objectID.type);
		Owner.Insert("Files", New Array);
		
		For Each XDTOFile In XDTOOwner.files Do
			File = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
				XDTOFile.name,
				XDTOFile.objectID.ID,
				XDTOFile.objectID.type,
				XDTOFile.extension);
			Owner.Files.Add(File);
		EndDo;
		
		Result.Add(Owner);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Fills in the relationship tree automatically based on the links in the integrated configuration object.
//
// Parameters:
//   Form - ClientApplicationForm - the completed form for processing integration1sdocumentation.
//   ObjectIS - AnyRef - the object on the basis of which the object is filled UP TO.
//   ElementToUpdateHeader - FormField, FormGroup - the element whose title is being updated.
//
Procedure FillInLinksOfNewDocument(Form, ObjectIS, ElementToUpdateHeader) Export
	
	SuitableObjects = IntegrationWith1CDocumentManagement.GetSuitableObjectsToAddLinksTo(ObjectIS);
	
	If SuitableObjects.Count() = 0 Then
		Return;
	EndIf;
	
	DocumentKind = New Structure("ID, Type",
		Form.DocumentKindID,
		Form.DocumentKindType);
	
	Tree = Form.FormAttributeToValue("LinkTree");
	LinkCount = 0;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	For Each SuitableObject In SuitableObjects Do
		
		LinkedDocument_ = New Structure("Ref, Title",
			SuitableObject,
			String(SuitableObject));
			
		Try
			LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
				SuitableObject);
		Except
			MessageText = StrTemplate(
				NStr("vi = 'Không thể nhận đối tượng liên kết Document Management khi tự động tạo liên kết: %1';
					|ru = 'Не удалось получить связанный объект Документооборота при автоматическом создании связей: %1';
					|en = 'Cannot receive the 1C:Document Management linked object when automatically creating the link: %1'; fa = 'Cannot receive the 1C:Document Management linked object when automatically creating the link: %1';
					|it = 'Non è stato possibile ricevere l''oggetto collegato di Document Management durante la creazione automatica del collegamento: %1';
					|pl = 'Nie udało się otrzymać powiązanego obiektu Document Management przy automatycznym utworzeniu powiązań: %1';
					|tr = 'Bağlantılar otomatik olarak oluşturulurken ilişkili İş Akışı nesnesi alınamadı: %1'"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(
				IntegrationWith1CDocumentManagementCore.EventLogEventName(),
				EventLogLevel.Error,,,
				MessageText);
			Continue;
		EndTry;
			
		If LinkedObjectBefore = Undefined Then
			
			Rules = IntegrationWith1CDocumentManagementServerCall.SuitableRules(SuitableObject);
			If Rules.Count() <> 1 Then
				Continue;
			EndIf;
			
			If Not IntegrationWith1CDocumentManagementClientServer.IsDocument(Rules[0].ObjectTypeDM) Then
				Continue;
			EndIf;
			
			TypeOfLinkedDocument = New Structure("ID, Type",
				Rules[0].IDOfDocumentType,
				Rules[0].TypeOfDocumentType);
			
			LinkedDocument_.Insert("Rule", Rules[0].Ref);
			
		Else // We will get links based on the type of existing document.
			
			If Not IntegrationWith1CDocumentManagementClientServer.IsDocument(LinkedObjectBefore.type) Then
				Continue;
			EndIf;
			
			TypeOfLinkedDocument = New Structure("ID, Type",
				LinkedObjectBefore.documentType.ID,
				LinkedObjectBefore.documentType.type);
			
			LinkedDocument_.Insert("ID", LinkedObjectBefore.ID);
			LinkedDocument_.Insert("Type", LinkedObjectBefore.type);
			
		EndIf;
		
		Conditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
		ListOfSelectionConditions = Conditions.conditions; // XDTOList
		
		ConditionFrom = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		ConditionFrom.property = "DocumentFrom";
		ConditionFrom.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			DocumentKind.ID,
			DocumentKind.Type);
		ListOfSelectionConditions.Add(ConditionFrom);
		
		ConditionB = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		ConditionB.property = "DocumentTo";
		ConditionB.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			TypeOfLinkedDocument.ID,
			TypeOfLinkedDocument.Type);
		ListOfSelectionConditions.Add(ConditionB);
		
		ConditionPredefined = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		ConditionPredefined.property = "Predefined";
		ConditionPredefined.value = False;
		ListOfSelectionConditions.Add(ConditionPredefined);
		
		Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
			Proxy,
			"DMRelationType",
			Conditions);
		
		If Result.items.Count() > 1 Then
			Continue;
		ElsIf Result.items.Count() = 1 Then
			CommunicationTypeXDTO = Result.items[0].object;
			LinkType = New Structure("ID, Type, Title",
				CommunicationTypeXDTO.objectID.ID,
				CommunicationTypeXDTO.objectID.type,
				CommunicationTypeXDTO.name);
		Else // Predefined.
			LinkType = New Structure("ID, Type, Title",
				"",
				"DMRelationType",
				NStr("vi = 'Có tham chiếu đến';
					|ru = 'Содержит ссылку на';
					|en = 'Contains reference to'; fa = 'Contains reference to';
					|it = 'Contiene collegamento a';
					|pl = 'Zawiera odnośnik na';
					|tr = 'Bağlantı içerir'"));
		EndIf;
			
		SuitableTreeRows = Tree.Rows.FindRows(LinkType);
		If SuitableTreeRows.Count() = 0 Then
			TypeRow = Tree.Rows.Add();
			FillPropertyValues(TypeRow, LinkType);
		Else
			TypeRow = SuitableTreeRows[0];
		EndIf;
		
		SuitableTreeRows = TypeRow.Rows.FindRows(LinkedDocument_);
		If SuitableTreeRows.Count() = 0 Then
			DocumentLine = TypeRow.Rows.Add();
			FillPropertyValues(DocumentLine, LinkedDocument_);
			DocumentLine.LinkingNewDocument = True;
			LinkCount = LinkCount + 1;
		EndIf;
		
	EndDo;
	
	Form.ValueToFormAttribute(Tree, "LinkTree");
	
	If LinkCount = 0 Then
		TitleText = NStr("vi = 'Liên kết';
						|ru = 'Связи';
						|en = 'Links'; fa = 'پیوندها';
						|it = 'Collegamenti';
						|pl = 'Powiązania';
						|tr = 'Bağlantılar'");
	Else
		TitleText = StrTemplate(
			NStr("vi = 'Liên kết (%1)';
				|ru = 'Связи (%1)';
				|en = 'Links (%1)'; fa = 'Links (%1)';
				|it = 'Collegamenti (%1)';
				|pl = 'Powiązania (%1)';
				|tr = 'Bağlantılar (%1)'"),
			LinkCount);
	EndIf;
	ElementToUpdateHeader.Title = TitleText;
	
EndProcedure

// Creates a new document in the link box, added automatically when it is created based
// on the IP object, but not yet recorded.
//
// Parameters:
//   LinkTree - FormDataTree - a tree of relationships in the form of a document.
//   ID - String - ID of the owner document.
//   Type - String - the type of the owner document.
//   Presentation - String - presentation of the owner document.
//
Procedure RecordConnectionsOfNewDocument(LinkTree, ID, Type, Presentation) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	SourceDocument_ = New Structure("ID, Type, Presentation",
		ID,
		Type,
		Presentation);
	
	RelationshipTypeStrings_ = LinkTree.GetItems();
	For Each LinkTypeString_ In RelationshipTypeStrings_ Do
		
		If ValueIsFilled(LinkTypeString_.ID) Then
			LinkType = New Structure("ID, Type, Presentation",
				LinkTypeString_.ID,
				LinkTypeString_.Type,
				LinkTypeString_.Title);
		Else
			LinkType = Undefined;
		EndIf;
		
		DocumentStrings = LinkTypeString_.GetItems();
		For Each DocumentLine In DocumentStrings Do
			
			If Not DocumentLine.LinkingNewDocument Then
				Continue;
			EndIf;
			
			If ValueIsFilled(DocumentLine.ID) Then
				
				LinkedDocument_ = New Structure("ID, Type, Presentation",
					DocumentLine.ID,
					DocumentLine.Type,
					DocumentLine.Title);
				
			Else
				
				NewObjectBefore = IntegrationWith1CDocumentManagement.CreateMapItemUsingRule(
					Proxy,
					DocumentLine.Ref,
					DocumentLine.Rule);
				
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
						DocumentLine.Title,
						NewObjectBefore);
					Raise ExceptionText;
				
				EndIf;
				
			EndIf;
			
			IntegrationWith1CDocumentManagementServerCall.AddDocumentLink(
				SourceDocument_,
				LinkedDocument_,
				LinkType);
			
			DocumentLine.LinkingNewDocument = False;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Transfers the files of the new document to the UP.
//
// Parameters:
//   Files - FormDataCollection - a list of files in the form of a document.
//   OwnerID - String - ID of the owner document.
//   OwnerType - String - the type of the owner document.
//   OwnerPresentation - String - presentation of the owner document.
//   Owner - AnyRef - the owner's document.
//
Procedure WriteNewDocumentFiles(Files, OwnerID, OwnerType, OwnerPresentation, Owner) Export
	
	For Each File In Files Do
		
		If ValueIsFilled(File.ID) Then
			Continue;
		EndIf;
		
		CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
			File.Description,
			Undefined,
			"DMFile",
			File.Extension);
		
		CreationParameters = IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions(
			CurrentFile);
		CreationParameters.Owner = Owner;
		
		If ValueIsFilled(File.TempFileStorageAddress) Then
			// We will transfer to the DO the printed forms that could have been added on the IC side before the document was recorded.
			CreationParameters.CurrentFile.Size = File.Size;
			CreationParameters.CurrentFile.ModificationDate = File.CreationDate;
			CreationParameters.CurrentFile.UniversalModificationDate = File.UniversalModificationDate;
			CreationParameters.TempFileStorageAddress = File.TempFileStorageAddress;
		ElsIf ValueIsFilled(File.TemplateID) Then
			// Let's create files in the DO based on their templates copied from the document template and stored in the DO.
			CreationParameters.TemplateID = File.TemplateID;
		EndIf;
		
		File.ID = IntegrationWith1CDocumentManagementCoreServerCall.CreateFileInWorkflow(
			CreationParameters,
			OwnerID,
			OwnerType,
			OwnerPresentation);
		
	EndDo;
	
EndProcedure

// Sets the visibility of the group of information about the unavailability of the functionality of the web service version.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the object or list 1C:Document management
//
Procedure ProcessFormIfServiceVersionFunctionalityIsUnavailable(Form) Export
	
	Form.Items.FunctionalityGroupIsNotSupported.Visible = True;
	Form.Items.DecorationFunctionalityIsNotSupported.Title =
		NStr("vi = 'Tính năng này không được hỗ trợ trong phiên bản 1C:Document Management hiện tại.';
			|ru = 'Функционал не поддерживается в данной версии 1С:Документооборота.';
			|en = 'Functionality is not supported in this version of 1C:Document Management.'; fa = 'این قابلیت در این نسخه از 1C:Document Management پشتیبانی نمی‌شود.';
			|it = 'La funzione non è supportata in questa versione di 1C:Document Management.';
			|pl = 'Funkcja nie jest obsługiwana w tej wersji 1C:Document Management.';
			|tr = 'Fonksiyonellik, 1C:Document Management''ın bu sürümünde desteklenmemektedir.'");
	
	Form.ReadOnly = True;
	
EndProcedure

// Fills in the standard details of the business process in the appropriate processing form.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of processing corresponding to the business process:
//     * StartDate - Date
//     * Description - String
//     * LongDesc - String
//   XDTODataObject - XDTODataObject - An XDTO object of the type inheriting the DMBusinessProcess type, with process data.
//
Procedure FillInStandardHeaderOfBusinessProcess(Form, XDTODataObject) Export
	
	Form.Started = XDTODataObject.started;
	Form.Completed = XDTODataObject.completed;
	Form.StartDate = XDTODataObject.beginDate;
	Form.CompletedOn = XDTODataObject.endDate;
	Form.Description = XDTODataObject.name;
	If XDTODataObject.objectID.Properties().Get("presentation") <> Undefined Then
		Form.Title = XDTODataObject.objectID.presentation;
	Else
		Form.Title = XDTODataObject.name;
	EndIf;
	If Form.Items.Find("TermDate") <> Undefined Then
		Form.DueDate = XDTODataObject.dueDate;
	EndIf;
	If Form.Items.Find("LongDesc") <> Undefined Then
		Form.LongDesc = XDTODataObject.description;
	EndIf;
	Form.Type = XDTODataObject.objectID.type;
	If XDTODataObject.objectID.Properties().Get("presentation") <> Undefined Then
		Form.Presentation = XDTODataObject.objectID.presentation;
	EndIf;
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		Form,
		XDTODataObject.author,
		"Author");
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		Form,
		XDTODataObject.parentTask,
		"MainTask");
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		Form,
		XDTODataObject.state,
		"State");
	
	If Form.Parameters.Property("MainTask") And Not ValueIsFilled(Form.MainTaskID) Then
		Form.MainTask = Form.Parameters.MainTask.name;
		Form.MainTaskID = Form.Parameters.MainTask.ID;
		Form.MainTaskType = Form.Parameters.MainTask.type;
	EndIf;
	
	If Not ValueIsFilled(Form.MainTaskID) Then
		If Form.Items.Find("MainTaskPresentation") <> Undefined Then
			Form.Items.MainTaskPresentation.Visible = False;
		EndIf;
	EndIf;
	
	FillInItemsInForm(Form, XDTODataObject);
	
	If Form.Items.Find("StateGroup") <> Undefined Then
		If Form.StateID = "Остановлен" Then //@NON-NLS-1
			Form.Items.StateGroup.Visible = True;
			Form.Items.TextState.Title = NStr("vi = 'Đã tạm dừng';
												|ru = 'Остановлен';
												|en = 'Stopped'; fa = 'متوقف‌شده';
												|it = 'Interrotto';
												|pl = 'Stopped';
												|tr = 'Durduruldu'");
			Form.PictureState = 1;
		ElsIf Form.StateID = "Прерван" Then //@NON-NLS-1
			Form.Items.StateGroup.Visible = True;
			Form.Items.TextState.Title = NStr("vi = 'Đã ngắt';
												|ru = 'Прерван';
												|en = 'Canceled'; fa = 'لغوشده';
												|it = 'Interrotto';
												|pl = 'Canceled';
												|tr = 'Kesildi'");
			Form.PictureState = 2;
		ElsIf XDTODataObject.completionMark = "ReadyToStart" Then
			Form.Items.StateGroup.Visible = True;
			Form.Items.TextState.Title = NStr("vi = 'Khởi động sau';
												|ru = 'Старт отложен';
												|en = 'Start is delayed'; fa = 'Start is delayed';
												|it = 'Avvio postposto';
												|pl = 'Rozpoczęcie jest odłożone';
												|tr = 'Başlatma ertelendi'");
			Form.PictureState = 3;
		ElsIf XDTODataObject.completionMark = "StartCanceled" Then
			Form.Items.StateGroup.Visible = True;
			Form.Items.TextState.Title = NStr("vi = 'Hủy bỏ khởi động';
												|ru = 'Старт отменен';
												|en = 'Start is canceled'; fa = 'شروع لغو شده است';
												|it = 'L''avvio annullato';
												|pl = 'Start odwołany';
												|tr = 'Başlatma iptal edildi'");
			Form.PictureState = 4;
		ElsIf XDTODataObject.completionMark = "ReadyToExecute" Then
			Form.Items.StateGroup.Visible = True;
			Form.Items.TextState.Title = NStr(
				"vi = 'Quy trình đang chờ khởi động. Nó sẽ tự khởi động trong thời gian tới.';
				|ru = 'Процесс находится в очереди для запуска. Его старт произойдет автоматически в ближайшее время.';
				|en = 'The process is in the starting queue. It will start automatically soon.'; fa = 'The process is in the starting queue. It will start automatically soon.';
				|it = 'Il processo si trova in coda di avvio. Il suo avvio avverrà automaticamente quanto prima.';
				|pl = 'Proces jest w kolejce do uruchomienia. Jego uruchomienie odbędzie się automatycznie w najbliższym czasie.';
				|tr = 'İşlem çalıştırılmak için sırada bekliyor. En kısa sürede otomatik olarak başlayacaktır.'");
			Form.PictureState = 0;
		ElsIf XDTODataObject.completionMark = "ExecutionCanceled" Then
			Form.Items.StateGroup.Visible = True;
			Form.Items.TextState.Title = NStr("vi = 'Lỗi khi khởi động quy trình';
												|ru = 'Ошибка при старте процесса';
												|en = 'Process start error'; fa = 'Process start error';
												|it = 'Errore durante l''avvio del processo';
												|pl = 'Błąd podczas uruchomienia procesu';
												|tr = 'İşlem başlatılırken hata'");
			Form.PictureState = 0;
		Else
			Form.Items.StateGroup.Visible = False;
		EndIf;
	EndIf;
	
	If Form.Items.Find("ProcessViewPresentation") <> Undefined Then
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "processType") Then
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				Form,
				XDTODataObject.processType,
				"ProcessView");
			Form.Items.ProcessViewPresentation.Visible = True;
		Else
			Form.ProcessView = "Adoption";
			Form.ProcessViewID = "Утверждение"; //@NON-NLS-1
			Form.ProcessViewType = "DMProcessConfirmationType";
			Form.Items.ProcessViewPresentation.Visible = False;
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "target")
				And XDTODataObject.target.objectID.type = "DMInternalDocument" Then
			Form.Items.ProcessViewPresentation.Visible = False;
		EndIf;
		If Not Form.Items.ProcessViewPresentation.Visible Then
			Form.Title = Form.ProcessView;
		EndIf;
	EndIf;
	
	If Form.Items.Find("ImportancePresentation") <> Undefined
			Or Form.Items.Find("Importance") <> Undefined Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTODataObject.importance,
			"Importance");
	EndIf;
	
	If XDTODataObject.started Or XDTODataObject.completed Then
		Form.ReadOnly = True;
		If Form.Items.Find("FormStartAndClose") <> Undefined Then
			Form.Items.FormStartAndClose.Enabled = False;
		EndIf;
		If Form.Items.Find("FormFillFromTemplate") <> Undefined Then
			Form.Items.FormFillFromTemplate.Enabled = False;
		EndIf;
		If Form.Items.Find("PerformersMovingGroup") <> Undefined Then
			Form.Items.PerformersMovingGroup.Enabled = False;
		EndIf;
		If Form.Items.Find("TermOfExecutionDays") <> Undefined Then
			Form.Items.TermOfExecutionDays.ReadOnly = True;
		EndIf;
		If Form.Items.Find("TermOfExecutionHours") <> Undefined Then
			Form.Items.TermOfExecutionHours.ReadOnly = True;
		EndIf;
		
		If XDTODataObject.completed Then
			Form.Items.FormWrite.Enabled = False;
			If Form.Items.Find("Subjects") <> Undefined Then
				Form.Items.Subjects.Enabled = False;
			EndIf;
			If Form.Items.Find("FormAddSubject") <> Undefined Then
				Form.Items.FormAddSubject.Enabled = False;
			EndIf;
			If Form.Items.Find("FormDeleteSubject") <> Undefined Then
				Form.Items.FormDeleteSubject.Enabled = False;
			EndIf;
			If Form.Items.Find("AddSubject") <> Undefined Then
				Form.Items.AddSubject.Enabled = False;
			EndIf;
			If Form.Items.Find("DeleteSubject") <> Undefined Then
				Form.Items.DeleteSubject.Enabled = False;
			EndIf;
			If Form.Items.Find("AddSubjectFromDecoration") <> Undefined Then
				Form.Items.AddSubjectFromDecoration.Enabled = False;
			EndIf;
		EndIf;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "state")
			And XDTODataObject.state.objectID.ID = "Прерван" Then //@NON-NLS-2
		Form.Items.FormWrite.Enabled = False;
		If Form.Items.Find("Subjects") <> Undefined Then
			Form.Items.Subjects.Enabled = False;
		EndIf;
	EndIf;
	
	// Changing the shape depending on the functional options.
	If Form.Items.Find("MainTaskPresentation") <> Undefined Then
		Form.Items.MainTaskPresentation.Visible = XDTODataObject.parentTaskEnabled;
	EndIf;
	If Form.Items.Find("TermTime") <> Undefined Then
		Form.Items.TermTime.Visible = XDTODataObject.dueTimeEnabled;
	ElsIf Form.Items.Find("TermOfExecutionHours") <> Undefined Then
		Form.Items.TermOfExecutionHours.Visible = XDTODataObject.dueTimeEnabled;
		Form.Items.Hours.Visible = XDTODataObject.dueTimeEnabled;
	EndIf;
	
	If Not ValueIsFilled(Form.ID) Then
		Form.Title = StrTemplate(NStr("vi = '%1 (Tạo mới)';
										|ru = '%1 (Создание)';
										|en = '%1 (Create)'; fa = '%1 (Create)';
										|it = '%1 (creazione)';
										|pl = '%1 (utworzenie)';
										|tr = '%1 (Oluşturma)'"), Form.Title);
		If Form.Items.Find("InfoGroup") <> Undefined Then
			Form.Items.InfoGroup.Visible = False;
		EndIf;
	EndIf;
	
EndProcedure

// Fills in the business process items in the appropriate processing form.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of processing corresponding to the business process:
//     * Subjects - ValueTable:
//         ** Ref - AnyRef
//   XDTODataObject - XDTODataObject - An XDTO object of the type inheriting the DMBusinessProcess type, with process data.
//
Procedure FillInItemsInForm(Form, XDTODataObject) Export
	
	If ValueIsFilled(Form.MainTaskID) And Not ValueIsFilled(XDTODataObject.objectID.ID) Then
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		MainTaskOfXDTO = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			Form.MainTaskType,
			Form.MainTaskID);
		If Form.MultiSubjectivityIsAvailable Then
			XDTOItems = MainTaskOfXDTO.targets.items;
		Else
			SubjectXDTO = MainTaskOfXDTO.target;
		EndIf;
	Else // The subjects of the task itself.
		If Form.MultiSubjectivityIsAvailable Then
			XDTOItems = XDTODataObject.targets.items;
		Else
			SubjectXDTO = XDTODataObject.target;
		EndIf;
	EndIf;
	
	If Form.MultiSubjectivityIsAvailable Then
		
		Form.Subjects.Clear();
		
		For Each SubjectXDTO In XDTOItems Do
			
			SubjectLine = Form.Subjects.Add();
			SubjectLine.ItemName = SubjectXDTO.name;
			SubjectLine.SubjectOf = SubjectXDTO.target.name;
			SubjectLine.SubjectOfID = SubjectXDTO.target.objectID.ID;
			SubjectLine.SubjectOfType = SubjectXDTO.target.objectID.type;
			SubjectLine.RoleOfSubject = SubjectXDTO.role.objectID.ID;
			SubjectLine.Picture = IntegrationWith1CDocumentManagementClientServer.
				ImageNumberBySubjectRole(SubjectLine.RoleOfSubject);
			ArrayOfLinksToExternalObjects = IntegrationWith1CDocumentManagementCore.LinksToExternalObjects(SubjectXDTO.target);
			SubjectLine.Ref = ?(ArrayOfLinksToExternalObjects.Count() > 0,
				ArrayOfLinksToExternalObjects[0],
				Undefined);
			
			If ValueIsFilled(SubjectLine.Ref) Then
				SubjectLine.Presentation = String(SubjectLine.Ref);
			Else
				If ValueIsFilled(SubjectLine.ItemName) Then
					SubjectLine.Presentation = StringFunctionsClientServer.SubstituteParametersToString(
						"%1 (%2)",
						SubjectLine.SubjectOf,
						SubjectLine.ItemName);
				Else
					SubjectLine.Presentation = SubjectLine.SubjectOf;
				EndIf;
			EndIf;
			
		EndDo; // By subjects.
		
	Else // Multi-subject is not supported.
		
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(Form, SubjectXDTO, "SubjectOf");
		
	EndIf;
	
EndProcedure

// Fills in the business process controller in the appropriate processing form.
//
// Parameters:
//   Form - ClientApplicationForm - the form of processing corresponding to the business process.
//   XDTODataObject - XDTODataObject - An XDTO object of the type inheriting the DMBusinessProcess type, with process data.
//
Procedure FillInControllerInForm(Form, XDTODataObject) Export
	
	If XDTODataObject.controller.IsSet("user") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTODataObject.controller.user,
			"Inspector");
	ElsIf XDTODataObject.controller.IsSet("role") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTODataObject.controller.role,
			"Inspector");
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTODataObject.controller.mainAddressingObject,
			"MainObjectOfControllerAddressing");
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTODataObject.controller.secondaryAddressingObject,
			"AdditionalControllerAddressingObject");
	EndIf;
	
EndProcedure

// Fills in the verifying business process in the appropriate processing form.
//
// Parameters:
//   Form - ClientApplicationForm - the form of processing corresponding to the business process.
//   XDTODataObject - XDTODataObject - An XDTO object of the type inheriting the DMBusinessProcess type, with process data.
//
Procedure FillInExaminerInForm(Form, XDTODataObject) Export
	
	If XDTODataObject.verifier.IsSet("user") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTODataObject.verifier.user,
			"Supervisor");
	ElsIf XDTODataObject.verifier.IsSet("role") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTODataObject.verifier.role,
			"Supervisor");
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTODataObject.verifier.mainAddressingObject,
			"MainObjectOfVerifierAddressing");
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTODataObject.verifier.secondaryAddressingObject,
			"AdditionalVerifierAddressingObject");
	EndIf;
	
EndProcedure

// Fills in the executor of the business process in the appropriate processing form.
//
// Parameters:
//   Receiver - ValueTableRow - a row in the value table Performers.
//   XDTODataObject - XDTODataObject - An XDTO object of the type inheriting the DMBusinessProcess type, with process data.
//
Procedure FillInInformationInForm(Receiver, XDTODataObject) Export
	
	If XDTODataObject.Properties().Get("performer") = Undefined Then
		ArtistXDTO = XDTODataObject;
	Else
		ArtistXDTO = XDTODataObject.performer;
	EndIf;
		
	If ArtistXDTO.IsSet("user") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Receiver,
			ArtistXDTO.user,
			"Performer");
	ElsIf ArtistXDTO.IsSet("role") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Receiver,
			ArtistXDTO.role,
			"Performer");
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Receiver,
			ArtistXDTO.mainAddressingObject,
			"MainAddressingObject");
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Receiver,
			ArtistXDTO.secondaryAddressingObject,
			"AdditionalAddressingObject");
	EndIf;
	
EndProcedure

// Sets the availability of commands that change the state of the process in its form.
//
// Parameters:
//   Form - ClientApplicationForm - the form of processing corresponding to the business process.
//   XDTODataObject - XDTODataObject - An XDTO object of the type inheriting the DMBusinessProcess type, with process data.
//
Procedure SetVisibilityOfProcessStateChangeCommands(Form, XDTODataObject) Export
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "leadingTask") Then
		Form.Items.FormStopProcess.Visible = False;
		Form.Items.FormContinueProcess.Visible = False;
		Form.Items.FormInterruptProcess.Visible = False;
		
	ElsIf Not IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "state") Then
		Form.Items.FormStopProcess.Visible = False;
		Form.Items.FormContinueProcess.Visible = False;
		Form.Items.FormInterruptProcess.Visible = False;
		
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "completed") And XDTODataObject.completed Then
		Form.Items.FormStopProcess.Visible = False;
		Form.Items.FormContinueProcess.Visible = False;
		Form.Items.FormInterruptProcess.Visible = False;
		
	ElsIf Not IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "started") Or Not XDTODataObject.started Then
		Form.Items.FormStopProcess.Visible = False;
		Form.Items.FormContinueProcess.Visible = False;
		Form.Items.FormInterruptProcess.Visible = False;
		
	ElsIf XDTODataObject.state.objectID.ID = "Активен" Then //@NON-NLS-1
		Form.Items.FormStopProcess.Visible = True;
		Form.Items.FormContinueProcess.Visible = False;
		Form.Items.FormInterruptProcess.Visible = True;
		
	ElsIf XDTODataObject.state.objectID.ID = "Остановлен" Then //@NON-NLS-1
		Form.Items.FormStopProcess.Visible = False;
		Form.Items.FormContinueProcess.Visible = True;
		Form.Items.FormInterruptProcess.Visible = True;
		
	ElsIf XDTODataObject.state.objectID.ID = "Прерван" Then //@NON-NLS-1
		Form.Items.FormStopProcess.Visible = False;
		Form.Items.FormInterruptProcess.Visible = False;
		Form.Items.FormContinueProcess.Visible = False;
	EndIf;
	
EndProcedure

// Passes the Attributes related to the result processing period by filling them in the XDTO object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Form - ClientApplicationForm - the form of processing corresponding to the business process.
//   XDTODataObject - XDTODataObject - An XDTO object of the type inheriting the DMBusinessProcess type, with process data.
//
Procedure PassDeadlineForProcessingResult(Proxy, Form, XDTODataObject) Export
	
	IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
		Proxy,
		Form,
		"OptionForSettingDeadlineForProcessingResults",
		XDTODataObject.resultProcessingDueDateSpecificationOption,
		"DMDueDateSpecificationOption");
	XDTODataObject.resultProcessingDueDate = Form.DeadlineForProcessingResults;
	XDTODataObject.resultProcessingDueDateDays = Form.DeadlineForProcessingResultsIsDays;
	XDTODataObject.resultProcessingDueDateHours = Form.ProcessingTimeOfResultsIsHours;
	XDTODataObject.resultProcessingDueDateMinutes = Form.ProcessingTimeForResultsIsMinutes;
	
EndProcedure

// Creates an XDTO object of type DMBusinessProcess[ProcessName], and fills in the general properties according to the form data.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Type - String - the type of the business process's XDTO object.
//   Form - ClientApplicationForm - contains Attributes - sources of filling:
//     * StartDate - Date
//     * Description - String
//     * LongDesc - String
//   Exceptions - String - the names of the form details to be excluded from filling are separated by commas.
//
// Returns:
//   XDTODataObject
//
Function PrepareBusinessProcessHeader(Proxy, Type, Form, Exceptions = "") Export
	
	Object = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Type);
	
	Object.name = Form.Description;
	Object.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, Form.ID, Type);
	
	// The general header of business processes.
	IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
		Proxy,
		Form,
		"Author",
		Object.author,
		"DMUser");
	IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
		Proxy,
		Form,
		"State",
		Object.state,
		"DMBusinessProcessState");
	
	If Form.MultiSubjectivityIsAvailable Then
		FillProcessWithItemsFromForm(Proxy, Form.Subjects, Object);
	Else
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			Form,
			"SubjectOf",
			Object.target,
			"DMObject");
	EndIf;
	
	If Find(Exceptions, "ProcessView") = 0
			And IntegrationWith1CDocumentManagementCore.PropertyExists(Object, "processType") Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			Form,
			"ProcessView",
			Object.processType,
			"DMProcessConfirmationType");
	EndIf;
	
	If Find(Exceptions, "Importance") = 0 Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			Form,
			"Importance",
			Object.importance,
			"DMBusinessProcessImportance");
	EndIf;
	
	If Find(Exceptions, "Template") = 0 Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			Form,
			"Template",
			Object.businessProcessTemplate,
			Type + "Template");
	EndIf;
	
	Object.beginDate = Form.StartDate;
	
	If Find(Exceptions,"Started") = 0 Then
		Object.started = Form.Started;
	EndIf;
	If Find(Exceptions,"Completed") = 0 Then
		Object.completed = Form.Completed;
	EndIf;
	If Find(Exceptions,"LongDesc") = 0 Then
		Object.description = Form.LongDesc;
	EndIf;
	If Find(Exceptions,"DueDate") = 0 Then
		Object.dueDate = Form.DueDate;
	EndIf;
	
	If ValueIsFilled(Form.MainTaskID) Then
		MainTaskOfXDTO = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			Form.MainTaskType,
			Form.MainTaskID);
		MainTaskIsReceiver = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMBusinessProcessTask");
		IntegrationWith1CDocumentManagementCore.FillInXDTOPropertyValues(
			Proxy,
			MainTaskIsReceiver,
			MainTaskOfXDTO);
		Object.parentTask = MainTaskIsReceiver;
	EndIf;
	
	Return Object;
	
EndFunction

// Searches for objects UP to by details, saving the result to temporary storage
//
// Parameters:
//   ObjectType - String - the type of object to search for
//   SearchAttributes - Structure - description of search details
//   AddressInTempStorage - String - the parameter in which the address of the search results is placed
//   NumberOfResults - Number - number of search results
//   LimitNumberOfResults - Number - the maximum number of selected objects, if it is exceeded
//
Procedure PerformSearchByBankingDetails(ObjectType, SearchAttributes, AddressInTempStorage,
		NumberOfResults, LimitNumberOfResults) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	LimitNumberOfResults = IntegrationWith1CDocumentManagementCore.MaximumNumberOfSelectedObjects(
		ObjectType);
	ListOfConditions.limit = LimitNumberOfResults;
	SelectedFields = ListOfConditions.columnSet; // XDTOList
	
	SetOfColumns = New Array;
	If ObjectType = "DMIncomingDocument"
			Or ObjectType = "DMInternalDocument"
			Or ObjectType = "DMOutgoingDocument" Then
		SetOfColumns.Add("documentType");
		SetOfColumns.Add("regNumber");
		SetOfColumns.Add("regDate");
		SetOfColumns.Add("sum");
		SetOfColumns.Add("organization");
		SetOfColumns.Add("correspondent");
		If ObjectType = "DMInternalDocument" Then
			SetOfColumns.Add("folder");
		EndIf;
		
	ElsIf ObjectType = "DMCorrespondent" Then
		SetOfColumns.Add("inn");
		SetOfColumns.Add("kpp");
		SetOfColumns.Add("legalPrivatePerson");
		
	EndIf;
	
	Presentation = "";
	For Each SearchDetails In SearchAttributes Do
		AttributeName = SearchDetails.Key;
		ConditionDetails = SearchDetails.Value;
		AddDetailsToConditionsList(
			Proxy,
			AttributeName,
			ConditionDetails,
			ListOfConditions,
			Presentation);
		// The details with the selection for equality are not informative.
		If ConditionDetails.ComparisonOperator = "=" Then
			PositionInArray = SetOfColumns.Find(AttributeName);
			If PositionInArray <> Undefined Then
				SetOfColumns.Delete(PositionInArray);
			EndIf;
		EndIf;
	EndDo;
	
	// Add the remaining columns to the selection requirement.
	For Each AttributeName In SetOfColumns Do
		SelectedFields.Add(AttributeName);
	EndDo;
	
	If Presentation = "" Then
		Presentation = NStr("vi = 'Chưa đặt điều kiện.';
							|ru = 'Условия не заданы.';
							|en = 'Conditions are not specified.'; fa = 'Conditions are not specified.';
							|it = 'Condizioni non indicate.';
							|pl = 'Warunki nie są zadane.';
							|tr = 'Şartlar belirlenmedi.'");
	Else
		Presentation = Presentation + ".";
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		ObjectType,
		ListOfConditions);
	
	FoundObjects = New Array;
	For Each XDTODataObject In Result.items Do
		FoundObject = New Structure;
		FoundObjects.Add(FoundObject);
		FoundObject.Insert("name", XDTODataObject.object.name);
		FoundObject.Insert("ID", XDTODataObject.object.objectID.ID);
		For Each ColumnDetails In SetOfColumns Do
			AttributeName = ColumnDetails;
			PropertyValue = XDTODataObject.object.Get(AttributeName);
			If TypeOf(PropertyValue) = Type("XDTODataObject") Then // The reference type is UP to.
				FoundObject.Insert(AttributeName, PropertyValue.name);
				FoundObject.Insert(AttributeName + "ID", PropertyValue.objectID.ID);
			Else // Primitive type.
				FoundObject.Insert(AttributeName, PropertyValue);
			EndIf;
		EndDo;
	EndDo;
	
	// Early versions BEFORE do not support tooManyObjects.
	If ?(Result.IsSet("tooManyObjects"), Result.tooManyObjects, False) Then
		Presentation = Presentation
			+ " " + NStr("vi = 'Kéo thả mục tin bất kỳ vào đây để làm rõ điều kiện.';
						|ru = 'Перетащите сюда любой реквизит, чтобы уточнить условия.';
						|en = 'Drag an attribute here to refine the criteria.'; fa = 'Drag an attribute here to refine the criteria.';
						|it = 'Trascinare qui qualsiasi attributo per indicare le condizioni.';
						|pl = 'Przenieś tutaj dowolny atrybut, aby uściślić warunki.';
						|tr = 'Şartları netleştirmek için herhangi bir özniteliği buraya sürükleyip bırakın.'");
		
	Else
		LimitNumberOfResults = 0;
	EndIf;
	
	Result = New Structure;
	Result.Insert("FoundObjects", FoundObjects);
	Result.Insert("SetOfColumns", SetOfColumns);
	Result.Insert("PresentationOfSearchTerms", Presentation);
	
	AddressInTempStorage = PutToTempStorage(Result, New UUID);
	
	NumberOfResults = FoundObjects.Count();
	
EndProcedure

// The standard print handler for the BSP Print Management subsystem.
//
// Parameters:
//   ObjectsArray  - Array of AnyRef - references to the objects that you want to print.
//   PrintParameters - Structure - additional print settings.
//   PrintFormsCollection - ValueTable - generated tabular documents.
//   PrintObjects - ValueList - the value is a reference to the object, the representation is the name of the area
//     in which the object was output.
//   OutputParameters - Structure - additional parameters of generated table documents.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If IntegrationWith1CDocumentManagementCoreCached.IsBackgroundJob()
			And PrintParameters.Property("IntegrationWith1CWorkflow_ParametersOfOperation") Then
		IntegrationWith1CDocumentManagementCore.ConnectAndGetServiceVersionInBackground(
			PrintParameters.IntegrationWith1CWorkflow_ParametersOfOperation);
	EndIf;
	
	ModulePrintManager = Common.CommonModule("PrintManagement");
	
	For Each PrintForm In PrintFormsCollection Do
		If PrintForm.TemplateName = "PF_MXL_ApprovalForm" Then
			FullTemplatePath = "DataProcessor.IntegrationWith1CDocumentManagement.PF_MXL_ApprovalForm";
			ModulePrintManager.OutputSpreadsheetDocumentToCollection(
				PrintFormsCollection,
				PrintForm.TemplateName,
				PrintForm.TemplateSynonym,
				PrepareApprovalSheet(ObjectsArray, FullTemplatePath, ModulePrintManager),,
				FullTemplatePath);
		EndIf;
	EndDo;
	
EndProcedure

// Returns in the form of a tabular document the printed form of the approval sheet for the transferred subject.
//
// Parameters:
//   SubjectsOfApproval - AnyRef, Array of AnyRef - consistent IP objects.
//   FullTemplatePath - String - path to the layout in the metadata tree.
//   ModulePrintManager - CommonModule - a common print management module.
//
// Returns:
//   SpreadsheetDocument - the printed form of the approval sheet(s).
//
Function PrepareApprovalSheet(SubjectsOfApproval, FullTemplatePath = "",
		ModulePrintManager = Undefined) Export
	
	If ModulePrintManager = Undefined Then
		Template = DataProcessors.IntegrationWith1CDocumentManagement.GetTemplate("PF_MXL_ApprovalForm");
	Else
		Template = ModulePrintManager.PrintFormTemplate(FullTemplatePath);
	EndIf;
	
	// Without the support of the approval sheet from the web service, this Command should not be in the interface.
	// In case of an unexpected version change on the service side, we will issue an exception.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.8.1") Then
		Raise NStr("vi = 'Để hiển thị tờ thống nhất, cần có phiên bản 1C:Document Managemet không thấp hơn 1.4.8.1';
					|ru = 'Для вывода листа согласования нужен 1С:Документооборот версии не ниже 1.4.8.1';
					|en = 'To display an approval sheet, 1C:Document Management version should be not earlier than 1.4.8.1'; fa = 'To display an approval sheet, 1C:Document Management version should be not earlier than 1.4.8.1';
					|it = 'Per la creazione di un foglio di omologazione è necessaria una versione di Document Manager non precedente alla 1.4.8.1';
					|pl = 'W celu wyprowadzenia arkusza uzgodnienia jest potrzebny 1C:Document Management wersji nie niższej niż 1.4.8.1';
					|tr = 'Anlaşma sayfasını görüntülemek için, 1.4.8.1''den düşük olmayan 1C:Document Management sürümü gerekmektedir'");
	EndIf;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PrintingParameters_IntegrationWith1CDocumentFlow_ApprovalSheet";
	SpreadsheetDocument.Protection = True;
	
	HeaderArea_ = Template.GetArea("Title");
	SectionHeader = Template.GetArea("Header");
	PerformersAreaHeader = Template.GetArea("PerformersHeader");
	PerformersArea = Template.GetArea("Assignees");
	NoNegotiationWasStarted = Template.GetArea("NegotiationDidNotStart");
	
	NeedPageSeparator = False;
	
	If TypeOf(SubjectsOfApproval) = Type("Array") Then
		ArrayOfItems = SubjectsOfApproval;
	Else
		// The only link.
		ArrayOfItems = CommonClientServer.ValueInArray(SubjectsOfApproval);
	EndIf;
	
	For Each SubjectOfApproval In ArrayOfItems Do
		
		If NeedPageSeparator Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		SpreadsheetDocument.Put(HeaderArea_);
		SectionHeader.Parameters.SubjectOf = String(SubjectOfApproval);
		SpreadsheetDocument.Put(SectionHeader);
		
		// Let's check the existence of a linked object.
		LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
			SubjectOfApproval);
		If LinkedObjectBefore = Undefined Then
			// The approval did not start.
			SpreadsheetDocument.Put(NoNegotiationWasStarted);
			
		Else
			Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
			Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetApprovalSheetRequest");
			Query.object = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, LinkedObjectBefore.type);
			Query.object.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				LinkedObjectBefore.ID,
				LinkedObjectBefore.type);
			Query.object.name = LinkedObjectBefore.name;
			Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
			IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
			If Response.items.Count() = 0 Then
				SpreadsheetDocument.Put(NoNegotiationWasStarted);
			Else
				SpreadsheetDocument.Put(PerformersAreaHeader);
				For Each Point In Response.items Do
					PerformersArea.Parameters.JobTitle = Point.position;
					PerformersArea.Parameters.Performer = Point.name;
					PerformersArea.Parameters.ApprovalResult = Point.result;
					PerformersArea.Parameters.CompletionDate = Point.date;
					PerformersArea.Parameters.ExecutionResult = Point.comment;
					SpreadsheetDocument.Put(PerformersArea);
				EndDo;
			EndIf;
			
		EndIf;
		
		NeedPageSeparator = True;
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Sets the deadline for processing the results in the Form of a business process.
//
// Parameters:
//   Form - ClientApplicationForm - the form of processing corresponding to the business process.
//   XDTODataObject - XDTODataObject - An XDTO object of the type inheriting the DMBusinessProcess type, with process data.
//
Procedure SetDeadlineForProcessingResults(Form, XDTODataObject) Export
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(
			XDTODataObject, "resultProcessingDueDateSpecificationOption") Then
		
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTODataObject.resultProcessingDueDateSpecificationOption,
			"OptionForSettingDeadlineForProcessingResults");
		Form.DeadlineForProcessingResults = XDTODataObject.resultProcessingDueDate;
		Form.DeadlineForProcessingResultsIsDays = XDTODataObject.resultProcessingDueDateDays;
		Form.ProcessingTimeOfResultsIsHours = XDTODataObject.resultProcessingDueDateHours;
		Form.ProcessingTimeForResultsIsMinutes = XDTODataObject.resultProcessingDueDateMinutes;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Fills the XDTO object of the business process with items from the form table.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Subjects - FormDataCollection - table of items.
//   Process_ - XDTODataObject - An XDTO object of type DMBusinessProcess<...> is a process to be filled in.
//
Procedure FillProcessWithItemsFromForm(Proxy, Subjects, Process_)
	
	targetCollection = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy, "DMBusinessProcessTargetCollection");
	ItemDescription = targetCollection.items; // XDTOList
		
	For Each SubjectLine In Subjects Do
			
		If Not Process_.IsSet("target") Then
			Process_.target = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, SubjectLine.SubjectOfType);
			Process_.target.name = SubjectLine.SubjectOf;
			Process_.target.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				SubjectLine.SubjectOfID,
				SubjectLine.SubjectOfType);
		EndIf;
		
		target = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMBusinessProcessTarget");
		target.name = SubjectLine.ItemName;
		
		target.role = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMBusinessProcessTargetRole");
		target.role.name = SubjectLine.RoleOfSubject;
		target.role.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			SubjectLine.RoleOfSubject,
			"DMBusinessProcessTargetRole");
		
		target.target = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, SubjectLine.SubjectOfType);
		target.target.name = SubjectLine.SubjectOf;
		target.target.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			SubjectLine.SubjectOfID,
			SubjectLine.SubjectOfType);
		
		ItemDescription.Add(target);
		
	EndDo;
	
	Process_.targets = targetCollection;
	
EndProcedure

// Adds the search details to the list of XDTO conditions, forming a condition representation in parallel
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   AttributeName - String - the name of the search details.
//   Description of conditions - Structure - description of search conditions.
//   ListOfConditions - XDTODataObject - A XDTO object of type DMObjectListQuery, replenished list of conditions.
//   Presentation - String - the updated representation of the condition.
//
Procedure AddDetailsToConditionsList(Proxy, AttributeName, ConditionDetails, ListOfConditions, Presentation)
	
	If Presentation = "" Then
		Presentation = Presentation + ConditionDetails.Presentation;
	Else
		Presentation = Presentation + "; " + Lower(ConditionDetails.Presentation);
	EndIf;
	
	If ConditionDetails.Property("ConditionPresentation")
			And ValueIsFilled(ConditionDetails.ConditionPresentation) Then
		Presentation = Presentation + ": " + ConditionDetails.ConditionPresentation;
	Else
		Presentation = Presentation + ": "
			+ ?(TypeOf(ConditionDetails.Value) = Type("Date"),
				Format(ConditionDetails.Value, "DLF=D"),
				ConditionDetails.Value);
	EndIf;
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = AttributeName;
	If ConditionDetails.ComparisonOperator = "<=" And TypeOf(ConditionDetails.Value) = Type("Date") Then
		Condition.value = EndOfDay(ConditionDetails.Value);
	Else
		If ConditionDetails.Property("ValueID") And ValueIsFilled(ConditionDetails.ValueID) Then
			AttributeValue = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				ConditionDetails.ValueID,
				ConditionDetails.ValueType);
			Condition.value = AttributeValue;
		Else // Primitive type.
			Condition.value = ConditionDetails.Value;
		EndIf;
	EndIf;
	
	If ConditionDetails.ComparisonOperator = "=" And TypeOf(ConditionDetails.Value) = Type("Date") Then
		Condition.comparisonOperator = ">=";
	Else
		Condition.comparisonOperator = ConditionDetails.ComparisonOperator;
	EndIf;
	
	Conditions = ListOfConditions.conditions; // XDTOList
	Conditions.Add(Condition);
	
	If ConditionDetails.Property("ComparisonOperator2")
			And ValueIsFilled(ConditionDetails.ComparisonOperator2) Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = AttributeName;
		If ConditionDetails.ComparisonOperator2 = "<=" And TypeOf(ConditionDetails.Value2) = Type("Date") Then
			Condition.value = EndOfDay(ConditionDetails.Value2);
		Else
			Condition.value = ConditionDetails.Value2;
		EndIf;
		Condition.comparisonOperator = ConditionDetails.ComparisonOperator2;
		Conditions.Add(Condition);
	ElsIf ConditionDetails.ComparisonOperator = "="
			And TypeOf(ConditionDetails.Value) = Type("Date")
			And AttributeName <> "anyDate" Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = AttributeName;
		Condition.value = EndOfDay(ConditionDetails.Value);
		Condition.comparisonOperator = "<=";
		Conditions.Add(Condition);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
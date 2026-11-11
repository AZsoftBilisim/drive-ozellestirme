////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module of integration1 and document management 3: server, external connection
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region AsynchronousOperations

// Gets an HTML preview of an object from the Workflow in the background task.
//
// Parameters:
//   Parameters - Structure:
//     * IntegrationWith1CDocumentManagementWSDefinitions - ValueStorage
//     * IntegrationWith1CDocumentManagementServiceVersion - String
//     * IntegrationWith1CDocumentManagementUsername - String
//     * IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementOSAuthenticationIsUsed - Boolean
//     * IntegrationWith1CDocumentManagementProxyServerLocation - String
//     * IntegrationWith1CDocumentManagementPassword - String
//     * IntegrationWith1CDocumentManagementPasswordIsKnown - Boolean
//     * ID - String
//     * Type - String
//     * IgnoreMaxSize - Boolean - allows you to ignore the Workflow setting
//         "File size limit for preview".
//     * ObjectForGettingPersonalData - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//     * ReturnBinaryData - Boolean - instead of an HTML preview string, you need to get binary file data for
//         visualization using platform tools, for example, through a PDF document.
//   StorageAddress - String - the address of the repository where the request result will be placed.
//
Procedure GetHTMLPreviewOfObjectInBackground(Parameters, StorageAddress) Export
	
	Proxy = IntegrationWith1CDocumentManagementCore.GetProxyInBackground(Parameters);
	
	Try
		Result = HTMLObjectPreview(
			Proxy,
			Parameters.ID,
			Parameters.Type,
			Parameters.IgnoreMaxSize,
			Parameters.ObjectForGettingPersonalData,
			Parameters.ReturnBinaryData);
	Except
		PutToTempStorage(
			IntegrationWith1CDocumentManagementCore.ServiceVersion(),
			StorageAddress);
		Raise;
	EndTry;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

#Region StandardSubsystems_BasicFunctionality

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("GetHTMLPreviewOfObjectInBackground", True);
	
EndProcedure

#EndRegion

#EndRegion

#Region BIDWebService

#Region UniversalMessageProcessing

// Returns the result of universal message processing.
//
// Parameters:
//   Message - XDTODataObject - descendant of DMILRequest.
//
// Returns:
//   XDTODataObject - descendant of DMILResponse.
//
Function ProcessUniversalMessage(Message) Export
	
	Try
		
		BeginningOfTimeMeasurement = CurrentSessionDate();
		
		SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = VersionDMByMessage(Message);
		SessionParameters.Integration1CDocumentManagementXMLSchema = DMServiceSchemeByMessage(Message);
		
		Result = Undefined;
		IntegrationWith1CDocumentManagementCoreOverridable.WhenProcessingUniversalMessage(
			Message,
			Result);
		If Result = Undefined Then
			
			If CheckBIDType(Message, "DMILBatchRequest") Then
				Result = ProcessPackage(Message);
				
			ElsIf CheckBIDType(Message, "DMILCheckExpressionOnBuiltInLanguageRequest") Then
				Result = CheckExpressionInEmbeddedLanguage(Message);
				
			ElsIf CheckBIDType(Message, "DMILCreateRelatedIntegrationRuleExistenceRequest") Then
				Result = Catalogs.RulesForIntegrationWith1CDocumentManagement3.CreateRelatedIntegrationRule(
					Message);
				
			ElsIf CheckBIDType(Message, "DMILGetExpressionListRequest") Then
				Result = ListOfExpressionsInBuiltInLanguageToExecuteOnSideDM(Message);
				
			ElsIf CheckBIDType(Message, "DMILGetMetadataRequest") Then
				Result = IntegratedSystemMetadataStructure(Message);
				
			ElsIf CheckBIDType(Message, "DMILGetPrintedFormsRequest") Then
				Result = ListOfPrintedFormsOfIPObjects(Message);
				
			ElsIf CheckBIDType(Message, "DMILPutChangesRequest") Then
				Result = IntegrationWith1CDocumentManagement3Exchange.RecordChangesToObjects(Message);
				
			ElsIf CheckBIDType(Message, "DMILRelatedIntegrationRulesExistenceRequest") Then
				Result = Catalogs.RulesForIntegrationWith1CDocumentManagement3.RelatedIntegrationRulesExist(
					Message);
				
			ElsIf CheckBIDType(Message, "DMILSynchronizeUsersRequest") Then
				Result = SynchronizeUsersOfIntegratedSystemAndUsersUPTO(Message);
				
			EndIf;
			
		EndIf;
		
		If Result <> Undefined Then
			RunTime = CurrentSessionDate() - BeginningOfTimeMeasurement;
			If RunTime > 15 Then
				FixErrorExceedingExecutionTime(RunTime, Message, Result);
			EndIf;
			Return Result;
		EndIf;
		
		Return DescriptionOfXDTOError(
			NStr("vi = 'Thông điệp không xác định';
				|ru = 'Неизвестное сообщение';
				|en = 'Unknown message'; fa = 'Unknown message';
				|it = 'Messaggio sconosciuto';
				|pl = 'Nieznana wiadomość';
				|tr = 'Bilinmeyen mesaj'"),
			String(Message.Type()));
		
	Except
		
		Return DescriptionOfXDTOError(
			NStr("vi = 'Lỗi khi xử lý thông điệp';
				|ru = 'Ошибка при обработке сообщения';
				|en = 'Message processing error'; fa = 'Message processing error';
				|it = 'Errore durante l''elaborazione del messaggio';
				|pl = 'Błąd podczas przetwarzania komunikatu';
				|tr = 'İleti işlenirken hata'"),
			GetErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndFunction

#EndRegion

// Returns the URI of the namespace of the BID web service.
//
// Returns:
//   String
//
Function URIOfNamespaceOfBIDWebService() Export
	
	Return "http://www.1c.ru/dmil";
	
EndFunction

// Creates a DMILError object.
//
// Parameters:
//   SubjectOf - String - subject of the error message.
//   LongDesc - String - text description of the error, as well as debugging information.
//   ArrayOfExternalObjectsWithoutErrors - Array of XDTODataObject - list of external objects that were successfully processed.
//
// Returns:
//   XDTODataObject
//
Function DescriptionOfXDTOError(SubjectOf = "", LongDesc = "", ArrayOfExternalObjectsWithoutErrors = Undefined) Export
	
	Error = CreateBIDObject("DMILError");
	Error.subject = SubjectOf;
	Error.description = LongDesc;
	
	If TypeOf(ArrayOfExternalObjectsWithoutErrors) = Type("Array") Then
		ListOfExternalObjectsWithoutErrors = Error.externalObjectsWithoutErrors; // XDTOList
		For Each ExternalObject In ArrayOfExternalObjectsWithoutErrors Do
			ListOfExternalObjectsWithoutErrors.Add(ExternalObject);
		EndDo;
	EndIf;
	
	Return Error;
	
EndFunction

// Fills in the XDTO object that describes the expression in the embedded language
// that you want to pass and execute on the DO side.
//
// Parameters:
//   ExpressionOfXDTORule - XDTODataObject - an XDTO object that describes an expression in the embedded language.
//   ExpressionToExecuteOnDMSide - ValueTableRow - a row in the tabular part of the integration rule.
//     See Catalogs.RulesForIntegrationWith1CDocumentManagement3.ExpressionsToExecuteOnSideDM
//
Procedure PrepareCalculatedExpressionToBeTransferredToDMSide(ExpressionOfXDTORule,
		ExpressionToExecuteOnDMSide) Export
	
	ExpressionOfXDTORule.id = ExpressionToExecuteOnDMSide.id;
	ExpressionOfXDTORule.expressionOnBuiltInLanguage = ExpressionToExecuteOnDMSide.ComputedExpression;
	ExpressionOfXDTORule.tabularSectionName = ExpressionToExecuteOnDMSide.SourceTableName;
	
	If ExpressionToExecuteOnDMSide.ThisIsTable = True Then
		ExpressionOfXDTORule.type = "TabularSection";
		
	ElsIf ExpressionToExecuteOnDMSide.ThisIsTable = False
			And ExpressionToExecuteOnDMSide.Table <> "" Then
		ExpressionOfXDTORule.type = "TabularSectionAttribute";
		
	Else
		ExpressionOfXDTORule.type = "Attribute";
		
	EndIf;
	
EndProcedure

// Returns a description of the error.
//
// Parameters:
//   Info - ErrorInfo
//
// Returns:
//   String - the text of the detailed description of the error.
//
Function GetErrorDescription(Info) Export
	
	Messages = GetUserMessages(True);
	
	MessageText = "";
	For Each Message In Messages Do
		MessageText = MessageText + Message.Text + Chars.LF;
	EndDo;
	
	ErrorPresentation = ErrorProcessing.DetailErrorDescription(Info);
	If Not IsBlankString(Info.Description) And IsBlankString(ErrorPresentation) Then
		ErrorPresentation = Info.Description;
	EndIf;
	
	Return ErrorPresentation + ?(ErrorPresentation + MessageText = "", "", Chars.LF) + MessageText;
	
EndFunction

// Returns a reference to the IP object by ObjectId
//
// Parameters:
//   ObjectID - XDTODataObject - an XDTO object of the DMILObjectID type.
//   RaiseException1 - Boolean - an exception is required if an error occurs.
//   MessageText - String - implicitly returned value, error message text.
//
// Returns:
//   AnyRef - reference to the IP object.
//
Function GetLinkByObjectID(ObjectID, RaiseException1 = True, MessageText = "") Export
	
	Ref = Undefined;
	
	If ObjectID <> Undefined And ObjectID.ID <> "" And ObjectID.type <> "" Then
		
		Manager = Common.ObjectManagerByFullName(ObjectID.type);
		Ref = Manager.EmptyRef();
		
		If StringFunctionsClientServer.IsUUID(ObjectID.ID) Then
			Ref = Manager.GetRef(New UUID(ObjectID.ID));
			
		Else
			// Perhaps it is the name of a predefined element or an enumeration.
			Try
				Ref = Manager[ObjectID.ID];
			Except
				MessageText = StrTemplate(
					NStr("vi = 'Không có giá trị ""%1"" trong số các giá trị kiểu ""%2""';
						|ru = 'Нет значения ""%1"" среди значений типа ""%2""';
						|en = 'There is no ""%1"" value among values of the ""%2"" type'; fa = 'There is no ""%1"" value among values of the ""%2"" type';
						|it = 'Nessun valore ""%1"" tra i valori del tipo ""%2""';
						|pl = 'Brak wartości ""%1"" wśród wartości typu ""%2""';
						|tr = '""%2"" türü değerleri arasında ""%1""  değeri mevcut değil'"),
					ObjectID.ID,
					ObjectID.type);
				If RaiseException1 Then
					Raise MessageText;
				Else
					Return Undefined;
				EndIf;
			EndTry;
			
		EndIf;
		
		If Common.IsReference(TypeOf(Ref)) And Not Common.RefExists(Ref)Then
			MessageText = StrTemplate(
				NStr("vi = 'Không tìm thấy đối tượng kiểu ""%1"" theo ID ""%2""';
					|ru = 'Объект типа ""%1"" не найден по идентификатору ""%2""';
					|en = 'The object of the ""%1"" type is not found by ID %2'; fa = 'The object of the ""%1"" type is not found by ID %2';
					|it = 'The object of the ""%1"" type is not found by ID %2';
					|pl = 'The object of the ""%1"" type is not found by ID %2';
					|tr = '""%1"" tipindeki nesne ""%2"" tanımlayıcısı tarafından bulunamadı'"),
				ObjectID.type,
				ObjectID.ID);
			If RaiseException1 Then
				Raise MessageText;
			Else
				Return Undefined;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return Ref;
	
EndFunction

// Checks the type of the XDTO object.
//
// Parameters:
//   XDTODataObject - XDTODataObject - the object being checked.
//   Type - String - the name of the type XDTO.
//
// Returns:
//   Boolean - True if the object is an object of the specified type.
//
Function CheckBIDType(XDTODataObject, Type) Export
	
	Return (TypeOf(XDTODataObject) = Type("XDTODataObject"))
		And IntegrationWith1CDocumentManagementCore.XDTOTypesAreSame(
			XDTODataObject.Type(),
			XDTOFactory.Type(URIOfNamespaceOfBIDWebService(), Type));
	
EndFunction

// Creates an XDTO object of the specified type from the namespace of the BID web service.
//
// Parameters:
//   ObjectType - String - type name XDTO
//
// Returns:
//   XDTODataObject - created object of the specified type
//
Function CreateBIDObject(ObjectType) Export
	
	Return XDTOFactory.Create(XDTOFactory.Type(URIOfNamespaceOfBIDWebService(), ObjectType));
	
EndFunction

// Reads XDTO objects from a DMILRequest message.
//
// Parameters:
//   BinaryMessageData - BinaryData - property of the MessageData message.
//
// Returns:
//   Array of XDTODataObject
//
Function ListOfXDTObjectsAboutMessage(BinaryMessageData) Export
	
	ListOfXDTOObjects = New Array;
	
	ExchangeMessageFileName = GetTempFileName("xml");
	BinaryMessageData.Write(ExchangeMessageFileName);
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(ExchangeMessageFileName);
	XMLReader.Read();
	XMLReader.Read();
	
	URIOfNamespaceOfWorkflowWebService =
		IntegrationWith1CDocumentManagementCore.URIOfNamespaceOfWorkflowWebService();
	
	DMFactory = IntegrationWith1CDocumentManagementCore.DMFactory();
	
	While XMLReader.NodeType = XMLNodeType.StartElement Do
		// Sequential reading of one object after another is performed.
		XDTOType = DMFactory.Type(URIOfNamespaceOfWorkflowWebService, XMLReader.Name);
		ListOfXDTOObjects.Add(DMFactory.ReadXML(XMLReader, XDTOType));
	EndDo;
	
	XMLReader.Close();
	XMLReader = Undefined;
	DeleteFiles(ExchangeMessageFileName);
	
	Return ListOfXDTOObjects;
	
EndFunction

#EndRegion

#Region GeneralProceduresAndFunctions

// Returns an HTML preview of the object.
// The receipt of the document's NDPS is combined with the receipt of a preview to optimize the work of the task list.
// We will get the NDPS in one batch request along with a preview of the task application, for one call to the service BEFORE.
// In advance, when receiving the task list, it is impossible to get the NDPS of all items, because this
// will significantly slow down the updating of the list.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ID - String - id of the XDTO object.
//   Type - String - type of the XDTO object.
//   IgnoreMaxSize - Boolean - allows you to ignore the Workflow setting
//     "File size limit for preview".
//   ObjectForGettingPersonalData - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   ReturnBinaryData - Boolean - instead of an HTML preview string, you need to get binary file data for
//     visualization using platform tools, for example, through a PDF document.
//
// Returns:
//   Structure - object preview structure:
//     * PresentationHTML - String - HTML object preview.
//     * PreviewCut - Boolean - The preview of the object has been cut down.
//     * BinaryData - BinaryData, Undefined - binary file data for visualization by means of the platform.
//
Function HTMLObjectPreview(Proxy, ID, Type, IgnoreMaxSize = False,
		ObjectForGettingPersonalData = Undefined, ReturnBinaryData = False) Export
	
	Result = New Structure("PresentationHTML, PreviewCut, BinaryData", "", False, Undefined);
	
	PackageQueries = New Array;
	
	If ReturnBinaryData Then
		PackageQueries.Add(IntegrationWith1CDocumentManagementCore.GetRequestObjects(
			Proxy,
			CommonClientServer.ValueInArray(New Structure("ID, Type", ID, Type)),
			"binaryData"));
	Else
		PackageQueries.Add(HTMLPreviewOfRequestObject(Proxy, ID, Type, IgnoreMaxSize));
	EndIf;
	
	If ObjectForGettingPersonalData <> Undefined Then
		PackageQueries.Add(
			IntegrationWith1CDocumentManagementCore.GetRequestObjects(
				Proxy,
				CommonClientServer.ValueInArray(ObjectForGettingPersonalData),
				"enabledProperties"));
	EndIf;
	
	ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(
		Proxy,
		PackageQueries);
	
	ResponsePreview = ResponseToPackageRequests.responses[0];
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponsePreview, "DMError") Then
		ErrorText = TrimAll(ResponsePreview.description);
		
		// Let's write the full text of the error in the LR.
		WriteLogEvent(
			IntegrationWith1CDocumentManagementCore.EventLogEventName(ResponsePreview.subject),
			EventLogLevel.Error,,,
			ErrorText);
		
		ErrorText = StrReplace(ErrorText, "{", "<br>{");
		
		SettingsBefore = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
		
		Result.PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.PreviewMessage(
			StrTemplate(
				"%1:<br>
				|%2",
				ResponsePreview.subject,
				ErrorText),
			SettingsBefore.TitleOfMessageInPreviewArea);
	ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponsePreview, "DMRetrieveResponse") Then
		Result.BinaryData = ResponsePreview.objects[0].binaryData;
	Else
		XDTORepresentation = ResponsePreview.ObjectsHTMLPresentations[0];
		Result.PresentationHTML = XDTORepresentation.htmlView;
		Result.PreviewCut = XDTORepresentation.truncated;
	EndIf;
	
	If ResponseToPackageRequests.responses.Count() = 2 Then
		IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(Result);
		DocumentData = ResponseToPackageRequests.responses[1];
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, DocumentData, "DMError") Then
			IntegrationWith1CDocumentManagementCoreClientServer.SetValuesOfAllNDPSFields(
				Result,
				False);
			EventName = NStr("vi = 'Nhận tùy chỉnh tính khả dụng theo trạng thái đối tượng';
							|ru = 'Получение настроек доступности по состоянию объекта';
							|en = 'Get availability settings based on object state'; fa = 'Get availability settings based on object state';
							|it = 'Get availability settings based on object state';
							|pl = 'Get availability settings based on object state';
							|tr = 'Nesnenin durumuna göre kullanılabilirlik ayarlarının alınması'");
			ErrorText = New Array;
			ErrorText.Add(StrTemplate(
				NStr("vi = 'Không thể nhận tùy chỉnh tính khả dụng theo trạng thái đối tượng DM (ID = ""%1"", kiểu = ""%2"") do nguyên nhân:';
					|ru = 'Не удалось получить настройки доступности по состоянию объекта ДО (ID = ""%1"", тип = ""%2"") по причине:';
					|en = 'Cannot get the availability settings based on the DI object state (ID = ""%1"", type = ""%2"") due to:'; fa = 'Cannot get the availability settings based on the DI object state (ID = ""%1"", type = ""%2"") due to:';
					|it = 'Cannot get the availability settings based on the DI object state (ID = ""%1"", type = ""%2"") due to:';
					|pl = 'Cannot get the availability settings based on the DI object state (ID = ""%1"", type = ""%2"") due to:';
					|tr = 'BY nesne durumu (ID = ""%1"", tip = ""%2"") için kullanılabilirlik ayarları şu nedenden dolayı alınamadı:'"),
				ObjectForGettingPersonalData.ID,
				ObjectForGettingPersonalData.Type));
			ErrorText.Add(DocumentData.description);
			WriteLogEvent(
				IntegrationWith1CDocumentManagementCore.EventLogEventName(EventName),
				EventLogLevel.Error,,,
				StrConcat(ErrorText, Chars.LF));
		Else
			IntegrationWith1CDocumentManagementCore.FillInPPEOfXDTOObject(
				Result,
				DocumentData.objects[0]);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a request to 1C:Document flow for getting an HTML preview of the object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ID - String - id of the XDTO object.
//   Type - String - type of the XDTO object.
//   IgnoreMaxSize - Boolean - allows you to ignore the Workflow setting
//     "File size limit for preview".
//
// Returns:
//   XDTODataObject - an XDTO object of the DMGetObjectsHTMLPresentationsRequest type.
//
Function HTMLPreviewOfRequestObject(Proxy, ID, Type, IgnoreMaxSize = False) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMGetObjectsHTMLPresentationsRequest");
	XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObject");
	XDTODataObject.name = "";
	XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		ID,
		Type);
	If IntegrationWith1CDocumentManagementCore.PropertyExists(Query, "IgnoreMaxSize") Then
		Query.IgnoreMaxSize = IgnoreMaxSize;
	EndIf;
	ListOfObjects = Query.Objects; // XDTOList
	ListOfObjects.Add(XDTODataObject);
	
	Return Query;
	
EndFunction

// Forms a universal incoming data structure designed for uploading objects to 1C:Document flow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ObjectReferenceIS - AnyRef - the IP object, the data source of the filling.
//   ListOfTSToBeUnloaded - Array of String - a list of names of table parts that need to be uploaded to the DO.
//   ListOfExpressions - XDTOList - a list of expressions in the embedded language that need to be executed on the IC side.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMIncomingData type.
//
Function IncomingIPObjectData(Proxy, ObjectReferenceIS, ListOfTSToBeUnloaded, ListOfExpressions) Export
	
	ObjectIS = ObjectReferenceIS.GetObject();
	
	MetadataObject = ObjectIS.Metadata();
	
	If Not IntegrationWith1CDocumentManagementCore.MetadataObjectIsSupported(MetadataObject) Then
		Raise StrTemplate(
			NStr("vi = 'Tích hợp liền mạch không hỗ trợ đối tượng %1 (%2). Không thể gửi nó sang 1C:Document management.';
				|ru = 'Объект %1 (%2) не поддерживается бесшовной интеграцией. Его нельзя отправить в 1С:Документооборот.';
				|en = 'Seamless integration does not support the %1 (%2) object. Cannot send the object to 1C:Document Management.'; fa = 'Seamless integration does not support the %1 (%2) object. Cannot send the object to 1C:Document Management.';
				|it = 'Объект %1 (%2) не поддерживается бесшовной интеграцией. Его нельзя отправить в 1С:Документооборот.';
				|pl = 'Seamless integration does not support the %1 (%2) object. Cannot send the object to 1C:Document Management.';
				|tr = '%1 (%2) nesnesi kesintisiz entegrasyon tarafından desteklenmemektedir. 1C:Document Management''a gönderilemez.'"),
			ObjectReferenceIS,
			MetadataObject.FullName());
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMIncomingData");
	Attributes = Result.attributes; // XDTOList
	TabularSections = Result.tabularSections; // XDTOList
	
	// Standard banking details
	Attributes.Add(
		ConvertAttributeOfObjectToXDTOObject(Proxy, "Presentation", String(ObjectReferenceIS)));
	
	FillInAttributesFromMetadata(Proxy, Attributes, MetadataObject.StandardAttributes, ObjectIS, True);
	
	// Attributes
	FillInAttributesFromMetadata(Proxy, Attributes, MetadataObject.Attributes, ObjectIS);
	
	// General banking details
	UsingAttributeToUse = Metadata.ObjectProperties.CommonAttributeUse.Use;
	UsingAutoAttributes = Metadata.ObjectProperties.CommonAttributeUse.Auto;
	AutoUseOfAttributeToUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use;
	DoNotUseDataSeparationAttributes = Metadata.ObjectProperties.CommonAttributeDataSeparation.DontUse;
	
	AllGeneralDetails = New Array;
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = DoNotUseDataSeparationAttributes Then
			AllGeneralDetails.Add(CommonAttribute);
		EndIf;
	EndDo;
	
	GeneralAttributesOfObject = New Array;
	For Each CommonAttribute In AllGeneralDetails Do
		CompositionItem = CommonAttribute.Content.Find(MetadataObject);
		If CompositionItem = Undefined Then
			// There is no common Attribute in the document.
			Continue;
		EndIf;
		If CompositionItem.Use = UsingAttributeToUse
				Or (CompositionItem.Use = UsingAutoAttributes
					And CommonAttribute.AutoUse = AutoUseOfAttributeToUse) Then
			GeneralAttributesOfObject.Add(CommonAttribute);
		EndIf;
	EndDo;
	
	FillInAttributesFromMetadata(Proxy, Attributes, GeneralAttributesOfObject, ObjectIS);
	
	// Table parts
	For Each TabularSection In MetadataObject.TabularSections Do
		
		If TabularSection.Name = "AdditionalAttributes"
				Or (TypeOf(ListOfTSToBeUnloaded) = Type("Array")
					And ListOfTSToBeUnloaded.Find(TabularSection.Name) = Undefined) Then
			Continue;
		EndIf;
		
		Columns = New Array;
		For Each Attribute In TabularSection.StandardAttributes Do
			Columns.Add(Attribute);
		EndDo;
		For Each Attribute In TabularSection.Attributes Do
			Columns.Add(Attribute);
		EndDo;
		
		If Columns.Count() = 0 Then
			Continue;
		EndIf;
		
		TabularSections.Add(
			ConvertWISObjectTableToXDTOObject(
				Proxy,
				TabularSection.Name,
				ObjectIS[TabularSection.Name],
				Columns));
		
	EndDo;
	
	// Data from expressions in the embedded language
	FillInDataFromListOfExpressions(Proxy, ObjectIS, Attributes, TabularSections, ListOfExpressions);
	
	// additional banking details
	If PropertyManager.UseAddlAttributes(ObjectReferenceIS) Then
		FillInAttributesFromMetadata(
			Proxy,
			Attributes,
			PropertyManager.ObjectProperties(ObjectReferenceIS, True, False),
			ObjectIS,,
			True);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns flag data.
//
// Parameters:
//   Flag - String - flag name, takes the values of the DMObjectFlag enumeration (http://www.1c.ru/dm ).
//
// Returns:
//   Structure:
//     * PictureIndex - Number - Index of the image in the collectionflagovpisem.
//     * Picture - Picture - picture of the flag.
//     * Presentation - String - Presentation of the flag.
//
Function FlagData(Flag) Export
	
	FlagData = New Structure;
	FlagData.Insert("PictureIndex", 0);
	FlagData.Insert("Picture", PictureLib.IsEmptyFlag);
	FlagData.Insert("Presentation", NStr("vi = 'Hộp kiểm trống';
										|ru = 'Пустой флаг';
										|en = 'Blank checkbox'; fa = 'کادر انتخاب خالی';
										|it = 'Пустой флаг';
										|pl = 'Blank checkbox';
										|tr = 'Boş bayrak'"));
	
	If Lower(Flag) = "purple" Then
		FlagData.PictureIndex = 6;
		FlagData.Picture = PictureLib.PurpleFlag;
		FlagData.Presentation = NStr("vi = 'Cờ màu tím';
									|ru = 'Лиловый флаг';
									|en = 'Purple checkbox'; fa = 'کادر انتخاب بنفش';
									|it = 'Лиловый флаг';
									|pl = 'Purple checkbox';
									|tr = 'Eflatun bayrak'");
		
	ElsIf Lower(Flag) = "orange" Then
		FlagData.PictureIndex = 5;
		FlagData.Picture = PictureLib.OrangeFlag;
		FlagData.Presentation = NStr("vi = 'Cờ màu cam';
									|ru = 'Оранжевый флаг';
									|en = 'Orange checkbox'; fa = 'کادر انتخاب نارنجی';
									|it = 'Оранжевый флаг';
									|pl = 'Orange checkbox';
									|tr = 'Turuncu bayrak'");
		
	ElsIf Lower(Flag) = "green" Then
		FlagData.PictureIndex = 4;
		FlagData.Picture = PictureLib.GreenFlag;
		FlagData.Presentation = NStr("vi = 'Cờ màu xanh lá';
									|ru = 'Зеленый флаг';
									|en = 'Green checkbox'; fa = 'کادر انتخاب سبز';
									|it = 'Зеленый флаг';
									|pl = 'Green checkbox';
									|tr = 'Yeşil bayrak'");
		
	ElsIf Lower(Flag) = "yellow" Then
		FlagData.PictureIndex = 3;
		FlagData.Picture = PictureLib.YellowFlag;
		FlagData.Presentation = NStr("vi = 'Cờ màu vàng';
									|ru = 'Желтый флаг';
									|en = 'Yellow checkbox'; fa = 'کادر انتخاب زرد';
									|it = 'Желтый флаг';
									|pl = 'Yellow checkbox';
									|tr = 'Sarı bayrak'");
		
	ElsIf Lower(Flag) = "blue" Then
		FlagData.PictureIndex = 2;
		FlagData.Picture = PictureLib.BFlag;
		FlagData.Presentation = NStr("vi = 'Cờ màu xanh dương';
									|ru = 'Синий флаг';
									|en = 'Blue checkbox'; fa = 'کادر انتخاب آبی';
									|it = 'Синий флаг';
									|pl = 'Blue checkbox';
									|tr = 'Mavi bayrak'");
		
	ElsIf Lower(Flag) = "red" Then
		FlagData.PictureIndex = 1;
		FlagData.Picture = PictureLib.RedFlag;
		FlagData.Presentation = NStr("vi = 'Cờ màu đỏ';
									|ru = 'Красный флаг';
									|en = 'Red checkbox'; fa = 'کادر انتخاب قرمز';
									|it = 'Красный флаг';
									|pl = 'Red checkbox';
									|tr = 'Kırmızı bayrak'");
		
	EndIf;
	
	Return FlagData;
	
EndFunction

// Checks support for the functionality of getting the main EDI document file from 1C:Document management.
//
// Returns:
//   Boolean
//
Function FunctionalityOfGettingMainFileOfEDIDocumentIsAvailable() Export
	
	Return IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.18.19");
	
EndFunction

// Checks whether the Workflow web service supports working with files.
//
// Returns:
//   Boolean
//
Function FileFunctionalityIsAvailable() Export
	
	Return IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.9.18");
	
EndFunction

// Checks whether the Workflow web service supports the functionality of creating links.
//
// Returns:
//   Boolean
//
Function CreatingLinksIsAvailable() Export
	
	Return IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.19.30");
	
EndFunction

// Returns information about whether integration with 1C is enabled:Document management of edition 3.
//
// Returns:
//   Boolean
//
Function UseIntegration() Export
	
	Return GetFunctionalOption("UseIntegrationWith1CDocumentManagement3");
	
EndFunction

// Returns a copy of the XDTO object.
//
// Parameters:
//   Source - XDTODataObject - from where to copy.
//   ProxyBefore - WSProxy - an object for connecting to Document Management web services. If specified, the object is copied
//     DMService, if omitted, the DMILService object is copied.
//
// Returns:
//   XDTODataObject - a copy of the source object.
//
Function CopyOfXDTOObject(Source, ProxyBefore = Undefined) Export
	
	Result = Undefined;
	
	CopyXDTOObject(Result, Source, ProxyBefore);
	
	Return Result;
	
EndFunction

// updates the quick search Presentation. returns a Presentation of filters.
//
// Parameters:
//   QuickSearch - FormDataCollection - the "Quick search" table on the task list form.
//   ResetSelectionButton - FormButton - the "Reset selection" button.
//
// Returns:
//   String - Presentation of filters
//
Function UpdateQuickSearchPresentation(QuickSearch, ResetSelectionButton) Export
	
	ThereIsQuickSearch = False;
	Filters_Presentation = New FormattedString("");
	
	For Each String In QuickSearch Do
		
		String.ValuePresentation = ValuePresentation(String.Value);
		
		If ValueIsFilled(String.Value) And Not String.Fixed Then
			
			ThereIsQuickSearch = True;
			
			If String(Filters_Presentation) <> "" Then
				Filters_Presentation = New FormattedString(Filters_Presentation, ", ");
			EndIf;
			
			Filters_Presentation = New FormattedString(
				Filters_Presentation,
				New FormattedString(String.ParameterPresentation,, StyleColors.HelpText),
				New FormattedString(" " + String.ValuePresentation));
			
		EndIf;
		
	EndDo;
	
	ResetSelectionButton.Visible = ThereIsQuickSearch;
	
	Return Filters_Presentation;
	
EndFunction

// Returns a description of the 1C web service:Document management.
//
// Returns:
//   String
//
Function WebServiceDescription() Export
	
	Template = Catalogs.RulesForIntegrationWith1CDocumentManagement3.GetTemplate("WebServiceDescription");
	
	Return Template.GetText();
	
EndFunction

// Returns the main employee of the Cur of the 1C user:Document management.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMEmployee type.
//   Undefined
//
Function MainEmployeeOfCurrentUser() Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If SessionParameters.IntegrationWith1CDocumentManagementCurrentUser = "" Then
		
		Query = IntegrationWith1CDocumentManagementCore.CurCurrentWorkflowUserRequest(Proxy);
		Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		
	Else
		
		Response = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
			Proxy,
			SessionParameters.IntegrationWith1CDocumentManagementCurrentUser);
		
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMError") Then
		Return Undefined;
	Else
		UserEmployees = Response.employees; // XDTOList
		For Each Employee In UserEmployees Do
			If Employee.mainEmployee = True Then
				Return Employee;
			EndIf;
		EndDo;
	EndIf;
	
EndFunction

// Returns suitable objects to create based on the task.
//
// Parameters:
//   XDTOTask - XDTODataObject - an XDTO object of the DMTaskAction type.
//   ApplicationTree - ValueTreeRowCollection - the task application tree.
//   MainSubjectID - String - an implicit return value, the ID of the main object.
//   MainSubjectType - String - an implicit return value, the type of the main object.
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagement3ClientServer.ObjectToCreateBasedOnTask
//
Function SuitableObjectsToCreateBasedOnTask(XDTOTask, ApplicationTree,
		MainSubjectID = "", MainSubjectType = "") Export
	
	MainSubject = MainSubjectOfTask(XDTOTask);
	MainSubjectID = MainSubject.ID;
	MainSubjectType = MainSubject.Type;
	
	SuitableObjects = New Array;
	
	SubsystemNameEDIDocumentInterface = "ElectronicInteraction.ExchangeWithCounterparties.InterfaceForEDIDocuments";
	ThereIsInterfaceForEDODocuments = Common.SubsystemExists(SubsystemNameEDIDocumentInterface);
	If ThereIsInterfaceForEDODocuments And FunctionalityOfGettingMainFileOfEDIDocumentIsAvailable() Then
		For Each ApplicationRow In ApplicationTree Do
			For Each FileRow In ApplicationRow.Rows Do
				If FileRow.ApplicationType = "DMIncomingElectronicDocument"
						Or FileRow.ApplicationType = "DMOutgoingElectronicDocument" Then
					SuitableObject = IntegrationWith1CDocumentManagement3ClientServer.ObjectToCreateBasedOnTask();
					SuitableObject.DocumentEDI.Description = FileRow.Application;
					SuitableObject.DocumentEDI.ID = FileRow.ApplicationID;
					SuitableObject.DocumentEDI.Type = FileRow.ApplicationType;
					SuitableObject.ObjectPresentationIS = StrTemplate(
						NStr("vi = 'Ghi nhận văn bản điện tử ""%1"" vào hệ thống';
							|ru = 'Отразить электронный документ ""%1"" в учете';
							|en = 'Record the ""%1"" electronic document in accounting'; fa = 'Record the ""%1"" electronic document in accounting';
							|it = 'Record the ""%1"" electronic document in accounting';
							|pl = 'Record the ""%1"" electronic document in accounting';
							|tr = 'Elektronik belgeyi ""%1"" muhasebesinde yansıt'"),
						FileRow.Application);
					SuitableObjects.Add(SuitableObject);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	If MainSubject.ObjectTypeDM = "" Then
		Return SuitableObjects;
	EndIf;
	
	RuleSelection = IntegrationWith1CDocumentManagement3Cached.CommonSetOfIntegrationRules(
		MainSubject.ObjectTypeDM,
		MainSubject.DocumentKindDMID);
	While RuleSelection.Next() Do
		
		If RuleSelection.UseApplicabilityConditionWhenImporting Then
			
			RuleFits = ResultOfExpressionInEmbeddedLanguage(
				RuleSelection.ApplicabilityConditionOnImport,
				MainSubject.mainApplication);
			
		Else
			
			KeyAttributesDM = RuleSelection.KeyAttributesDM; // QueryResultSelection
			KeyAttribute = KeyAttributesDM.Select();
			RuleFits = True;
			While KeyAttribute.Next() Do
				If KeyAttribute.IsAdditionalAttributeDM Then
					
					AdditionalAttributesAreSuitable = False;
					For Each AdditionalAttributesOfXdto In MainSubject.mainApplication.additionalProperties Do
						If AdditionalAttributesOfXdto.objectID.id = KeyAttribute.Name Then
							If IntegrationWith1CDocumentManagementCore.PropertySet(
									AdditionalAttributesOfXdto, "propertySimpleValue") Then
								AdditionalAttributesAreSuitable =
									(AdditionalAttributesOfXdto.propertySimpleValue = KeyAttribute.AttributeValue)
										Or (AdditionalAttributesOfXdto.propertySimpleValue = KeyAttribute.AttributeValueID);
							ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(
									AdditionalAttributesOfXdto, "propertyObjectValue") Then
								AdditionalAttributesAreSuitable =
									(AdditionalAttributesOfXdto.propertyObjectValue.objectID.id = KeyAttribute.AttributeValueID)
									And (AdditionalAttributesOfXdto.propertyObjectValue.objectID.type = KeyAttribute.AttributeValueType);
							EndIf;
							Break;
						EndIf;
					EndDo;
					If Not AdditionalAttributesAreSuitable Then
						RuleFits = False;
						Break;
					EndIf;
					
				ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(
						MainSubject.mainApplication, KeyAttribute.Name) Then
					
					If TypeOf(MainSubject.mainApplication[KeyAttribute.Name]) = Type("XDTODataObject")
							And IntegrationWith1CDocumentManagementCore.PropertySet(
								MainSubject.mainApplication[KeyAttribute.Name], "objectID") Then
						If MainSubject.mainApplication[KeyAttribute.Name].objectID.ID <> KeyAttribute.AttributeValueID
								Or MainSubject.mainApplication[KeyAttribute.Name].objectID.type
									<> KeyAttribute.AttributeValueType Then
							RuleFits = False;
							Break;
						EndIf;
					Else
						If MainSubject.mainApplication[KeyAttribute.Name] <> KeyAttribute.AttributeValue
								And MainSubject.mainApplication[KeyAttribute.Name] <> KeyAttribute.AttributeValueID Then
							RuleFits = False;
							Break;
						EndIf;
					EndIf;
					
				Else
					
					RuleFits = False;
					Break;
					
				EndIf;
			EndDo;
		EndIf;
		
		If RuleFits Then
			SuitableObject = IntegrationWith1CDocumentManagement3ClientServer.ObjectToCreateBasedOnTask();
			SuitableObject.IntegrationRule = RuleSelection.Ref;
			ArrayPresentationOfICObject = New Array;
			ArrayPresentationOfICObject.Add(RuleSelection.ObjectPresentationISWithKeyFields);
			If Not IsBlankString(RuleSelection.Comment) Then
				ArrayPresentationOfICObject.Add(RuleSelection.Comment);
			EndIf;
			SuitableObject.ObjectPresentationIS = StrConcat(ArrayPresentationOfICObject, ", ");
			SuitableObjects.Add(SuitableObject);
		EndIf;
		
	EndDo;
	RuleSelection.Reset();
	
	Return SuitableObjects;
	
EndFunction

// Returns from the preliminary data the loading rule in the DO corresponding to the IC object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   PreliminaryData - See IntegrationWith1CDocumentManagement3.PreliminaryDataForUnloadingVDO
//   ObjectIS - AnyRef - the IP object to get the rule for.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMDataLoadingRule type.
//   Undefined - if a suitable loading rule was not found.
//
Function RuleForLoadingVDOSFromPreliminaryData(Proxy, PreliminaryData, ObjectIS) Export
	
	VDOLoadingRule = Undefined;
	
	RuleForLoadingVDOLine = PreliminaryData.ComplianceOfRulesForLoadingVDOWithIPObjects[ObjectIS];
	If RuleForLoadingVDOLine <> Undefined Then
		VDOLoadingRule = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
			Proxy,
			RuleForLoadingVDOLine);
	EndIf;
	
	Return VDOLoadingRule;
	
EndFunction

// Returns the data required to upload the IP object to the DO: a list of tabular parts of the IP object that are required
// to fill in the DO object, a list of expressions in the built-in language that need to be executed on the IP side for
// subsequent transfer of results to the DO side, a list of printed forms that need to be generated on the IP side,
// a list of links to the DO object being created, which are automatically generated based on the data of the IP object,
// a list of required links to be selected interactively.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ListOfIPObjects - Array of AnyRef - IP objects for which you want to find the appropriate rules.
//   SuitableIntegrationRules - Map of KeyAndValue - relevant integration rules:
//     * Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//     * Value - Array of CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - a list of suitable rules.
//   ListOfExpressionsIsRequired - Boolean - you need to get a list of expressions in the embedded language.
//   ListOfRequiredLinksIsRequired - Boolean - It is required to get a list of required links
//     that the user must select interactively.
//   NewObjectsBefore - Array of See IntegrationWith1CDocumentManagement3ClientServer.NewObjectBefore
//
// Returns:
//   Structure:
//     * FileFunctionalityIsAvailable - Boolean - does the Workflow web service support working with files?
//     * CreatingLinksIsAvailable - Boolean - does the Workflow web service support the functionality
//         of creating links.
//     * ComplianceOfRulesForLoadingVDOWithIPObjects - Map of KeyAndValue - the corresponding rules for uploading to:
//       ** Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//       ** Value - String - string Presentation of an XDTO object of type DMDataLoadingRule.
//                   - Undefined - if a suitable upload rule was not found.
//     * ComplianceOfListOfTSToBeUnloadedWithIPObjects - Map of KeyAndValue:
//       ** Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//       ** Value - Array of String - a list of names of table parts that need to be uploaded to the DO.
//     * MatchingListOfExpressionsToIPObjects - Map of KeyAndValue:
//       ** Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//       ** Value - XDTOList - list of expressions in the embedded language.
//     * ComplianceOfPrintedFormsWithIPObjects - Map of KeyAndValue:
//       ** Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//       ** Value - XDTOList - table of printed forms for transfer to the DO.
//     * TypesOfPrintedFormFiles - Map of KeyAndValue:
//       ** Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//       ** Value - String - type of files for saving printed forms.
//     * MatchingCreatedLinksToIPObjects - Map of KeyAndValue:
//       ** Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//       ** Value - Array of See IntegrationWith1CDocumentManagementCoreClientServer.ConnectionToCreation
//     * ComplianceOfMandatoryLinksWithIPObjects - Map of KeyAndValue:
//       ** Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//       ** Value - Array of See IntegrationWith1CDocumentManagementCoreClientServer.SettingUpConnectionOfObjectsTO
//
Function PreliminaryDataForUnloadingVDO(Proxy, ListOfIPObjects, SuitableIntegrationRules,
		ListOfExpressionsIsRequired = True, ListOfRequiredLinksIsRequired = True,
		NewObjectsBefore = Undefined) Export
	
	Data = New Structure;
	Data.Insert("FileFunctionalityIsAvailable", FileFunctionalityIsAvailable());
	Data.Insert("CreatingLinksIsAvailable", CreatingLinksIsAvailable());
	Data.Insert("ComplianceOfRulesForLoadingVDOWithIPObjects", New Map);
	Data.Insert("ComplianceOfListOfTSToBeUnloadedWithIPObjects", New Map);
	Data.Insert("MatchingListOfExpressionsToIPObjects", New Map);
	Data.Insert("ComplianceOfPrintedFormsWithIPObjects", New Map);
	Data.Insert("TypesOfPrintedFormFiles", New Map);
	Data.Insert("MatchingCreatedLinksToIPObjects", New Map);
	Data.Insert("ComplianceOfMandatoryLinksWithIPObjects", New Map);
	
	Data.ComplianceOfRulesForLoadingVDOWithIPObjects = ComplianceOfRulesForLoadingVDOWithIPObjects(
		Proxy,
		ListOfIPObjects,
		SuitableIntegrationRules);
	
	ListOfUnloadedTSIsRequired = ListOfExpressionsIsRequired
		And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.16.30");
	
	If ListOfIPObjects.Count() = 0
			Or (Not ListOfUnloadedTSIsRequired
				And Not ListOfExpressionsIsRequired
				And Not Data.FileFunctionalityIsAvailable
				And Not Data.CreatingLinksIsAvailable) Then
		Return Data;
	EndIf;
	
	If ListOfUnloadedTSIsRequired Then
		RequestingListOfUnloadedTS = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMGetRequiredTabularSectionListRequest");
		RulesForListOfListOfTSThatAreBeingUnloaded = RequestingListOfUnloadedTS.allObjectsTabularSections; // XDTOList
	EndIf;
	If ListOfExpressionsIsRequired Then
		RequestingListOfExpressions = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMGetExpressionListRequest");
		RulesForListOfExpressions = RequestingListOfExpressions.objects; // XDTOList
	EndIf;
	If Data.FileFunctionalityIsAvailable Then
		RequestForPrintedForms = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMGetPrintedFormListRequest");
		RulesForPrintedForms = RequestForPrintedForms.objects; // XDTOList
	EndIf;
	If Data.CreatingLinksIsAvailable Then
		RequestForLinksToBeCreated = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMGetAddedRelationsRequest");
		RulesForCreatedLinks = RequestForLinksToBeCreated.objects; // XDTOList
	EndIf;
	
	AddedRules = New Array;
	For Each ObjectIS In ListOfIPObjects Do
		VDOLoadingRule = RuleForLoadingVDOSFromPreliminaryData(Proxy, Data, ObjectIS);
		If VDOLoadingRule = Undefined
				Or AddedRules.Find(VDOLoadingRule.ID) <> Undefined Then
			Continue;
		EndIf;
		
		If ListOfUnloadedTSIsRequired Then
			RuleAndListOfAllTS = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMObjectTabularSections");
			ListOfAllTS = RuleAndListOfAllTS.tabularSections; // XDTOList
			RuleAndListOfAllTS.object = CopyOfXDTOObject(VDOLoadingRule, Proxy);
			For Each TabularSection In ObjectIS.Metadata().TabularSections Do
				ListOfAllTS.Add(TabularSection.Name);
			EndDo;
			RulesForListOfListOfTSThatAreBeingUnloaded.Add(RuleAndListOfAllTS);
		EndIf;
		If ListOfExpressionsIsRequired Then
			RulesForListOfExpressions.Add(CopyOfXDTOObject(VDOLoadingRule, Proxy));
		EndIf;
		If Data.FileFunctionalityIsAvailable Then
			RulesForPrintedForms.Add(CopyOfXDTOObject(VDOLoadingRule, Proxy));
		EndIf;
		If Data.CreatingLinksIsAvailable Then
			RulesForCreatedLinks.Add(CopyOfXDTOObject(VDOLoadingRule, Proxy));
		EndIf;
		AddedRules.Add(VDOLoadingRule.ID);
	EndDo;
	
	ArrayOfAllUnloadedTS = New Array;
	ArrayOfAllExpressions = New Array;
	ArrayOfAllPrintedForms = New Array;
	ArrayOfAllCreatedLinks = New Array;
	ArrayOfAllLinkSettings = New Array;
	
	PackageQueries = New Array;
	
	If ListOfUnloadedTSIsRequired And RulesForListOfListOfTSThatAreBeingUnloaded.Count() > 0 Then
		PackageQueries.Add(RequestingListOfUnloadedTS);
	EndIf;
	If ListOfExpressionsIsRequired And RulesForListOfExpressions.Count() > 0 Then
		PackageQueries.Add(RequestingListOfExpressions);
	EndIf;
	If Data.FileFunctionalityIsAvailable And RulesForPrintedForms.Count() > 0 Then
		PackageQueries.Add(RequestForPrintedForms);
	EndIf;
	If Data.CreatingLinksIsAvailable Then
		If RulesForCreatedLinks.Count() > 0 Then
			PackageQueries.Add(RequestForLinksToBeCreated);
		EndIf;
		If ListOfRequiredLinksIsRequired Then
			MatchingLinkFromIPObjects = New Map;
			For Each MatchingElementMatchingRules In SuitableIntegrationRules Do
				If MatchingElementMatchingRules.Value.Count() <> 1 Then
					Continue;
				EndIf;
				IntegrationRule = MatchingElementMatchingRules.Value[0];
				RuleDetails = Common.ObjectAttributesValues(IntegrationRule, "ObjectTypeDM, DocumentKindDMID");
				If RuleDetails.ObjectTypeDM = "DMDocument" Then
					LinkFromType = "DMDocumentType";
					LinkFromID = RuleDetails.DocumentKindDMID;
				Else
					LinkFromType = RuleDetails.ObjectTypeDM;
					LinkFromID = "";
				EndIf;
				If LinkFromType = "DMCorrespondent" Then
					Continue;
				EndIf;
				LinkFrom = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
					LinkFromID,
					LinkFromType);
				RequestHasAlreadyBeenCreated = False;
				For Each MatchingElementLinkFrom In MatchingLinkFromIPObjects Do
					If Common.DataMatch(MatchingElementLinkFrom.Value, LinkFrom) Then
						RequestHasAlreadyBeenCreated = True;
						Break;
					EndIf;
				EndDo;
				If Not RequestHasAlreadyBeenCreated Then
					PackageQueries.Add(LinkSettingsRequest(Proxy, LinkFrom));
				EndIf;
				MatchingLinkFromIPObjects.Insert(MatchingElementMatchingRules.Key, LinkFrom);
			EndDo;
		EndIf;
	EndIf;
	
	If PackageQueries.Count() > 0 Then
		
		ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(
			Proxy,
			PackageQueries,
			True);
		
		For Each Response In ResponseToPackageRequests.responses Do
			
			If IntegrationWith1CDocumentManagementCore.ValidateType(
					Proxy, Response, "DMGetRequiredTabularSectionListResponse") Then
				ArrayOfAllUnloadedTS = Response.requiredObjectsTabularSections; // XDTOList
				
			ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(
					Proxy, Response, "DMGetExpressionListResponse") Then
				ArrayOfAllExpressions = Response.objectsExpressionRows; // XDTOList
				
			ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(
					Proxy, Response, "DMGetPrintedFormListResponse") Then
				ArrayOfAllPrintedForms = Response.objectsPrintedForms; // XDTOList
				
			ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(
					Proxy, Response, "DMGetAddedRelationsResponse") Then
				ArrayOfAllCreatedLinks = Response.objectsAddedRelations; // XDTOList
				
			ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(
					Proxy, Response, "DMGetRelationsSettingsResponse") Then
				CommonClientServer.SupplementArray(
					ArrayOfAllLinkSettings,
					Response.relationsSettings);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	For Each ObjectIS In ListOfIPObjects Do
		VDOLoadingRule = RuleForLoadingVDOSFromPreliminaryData(Proxy, Data, ObjectIS);
		ListOfTSToBeUnloaded = New Array;
		ListOfExpressions = New Array;
		PrintFormsList = New Array;
		ListOfAutomaticallyAddedLinks = New Array;
		TypeOfPrintedFormFiles = "";
		
		If VDOLoadingRule <> Undefined Then
			If ListOfUnloadedTSIsRequired Then
				For Each Item In ArrayOfAllUnloadedTS Do
					If Item.object.ID = VDOLoadingRule.ID Then
						ListOfTSToBeUnloaded = Item.tabularSections;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			If ListOfExpressionsIsRequired Then
				For Each Item In ArrayOfAllExpressions Do
					If Item.object.ID = VDOLoadingRule.ID Then
						ListOfExpressions = Item.expressionRows;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			If Data.FileFunctionalityIsAvailable Then
				For Each Item In ArrayOfAllPrintedForms Do
					If Item.object.ID = VDOLoadingRule.ID Then
						PrintFormsList = Item.printedForms;
						TypeOfPrintedFormFiles = Item.spreadsheetDocumentFileType;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			If Data.CreatingLinksIsAvailable Then
				For Each Item In ArrayOfAllCreatedLinks Do
					If Item.object.ID = VDOLoadingRule.ID Then
						ListOfAutomaticallyAddedLinks = Item.addedRelations;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		If ListOfUnloadedTSIsRequired Then
			Data.ComplianceOfListOfTSToBeUnloadedWithIPObjects[ObjectIS] = New Array;
			For Each NameOfIPTable In ListOfTSToBeUnloaded Do
				Data.ComplianceOfListOfTSToBeUnloadedWithIPObjects[ObjectIS].Add(NameOfIPTable);
			EndDo;
		EndIf;
		If ListOfExpressionsIsRequired Then
			Data.MatchingListOfExpressionsToIPObjects.Insert(ObjectIS, ListOfExpressions);
		EndIf;
		If Data.FileFunctionalityIsAvailable Then
			Data.ComplianceOfPrintedFormsWithIPObjects.Insert(ObjectIS, PrintFormsList);
			Data.TypesOfPrintedFormFiles.Insert(ObjectIS, TypeOfPrintedFormFiles);
		EndIf;
		If Data.CreatingLinksIsAvailable Then
			// Fill in the links that will be created automatically.
			LinksToCreation = New Array;
			FillInListOfLinksToCreate(
				Proxy,
				LinksToCreation,
				ObjectIS,
				ListOfAutomaticallyAddedLinks,
				NewObjectsBefore);
			Data.MatchingCreatedLinksToIPObjects.Insert(ObjectIS, LinksToCreation);
			If ListOfRequiredLinksIsRequired Then
				// Fill in the required links that you want to select interactively.
				RequiredLinks = New Array;
				LinkFrom = MatchingLinkFromIPObjects[ObjectIS];
				If LinkFrom <> Undefined Then
					For Each ConfigureLink In ArrayOfAllLinkSettings Do
						If Not ConfigureLink.required Or ConfigureLink.relationFrom.objectID.type <> LinkFrom.Type Then
							Continue;
						EndIf;
						If ValueIsFilled(ConfigureLink.relationFrom.objectID.ID)
								And ConfigureLink.relationFrom.objectID.ID <> LinkFrom.ID Then
							Continue;
						EndIf;
						LinkWillBeCreatedAutomatically = False;
						RefToType = ConfigureLink.relationTo.objectID.type;
						If RefToType = "DMDocumentType" Then
							RefToType = "DMDocument";
						EndIf;
						For Each ConnectionToCreation In LinksToCreation Do
							If ConnectionToCreation.LinkTypeID = ConfigureLink.relationType.objectID.ID
									And ConnectionToCreation.RefToType = RefToType Then
								LinkWillBeCreatedAutomatically = True;
								Break;
							EndIf;
						EndDo;
						If Not LinkWillBeCreatedAutomatically Then
							RefTo = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
								ConfigureLink.relationTo.objectID.ID,
								ConfigureLink.relationTo.objectID.type,
								ConfigureLink.relationTo.name,
								ConfigureLink.relationTo.objectID.presentation,
								ConfigureLink.relationTo.objectID.navigationRef);
							LinkType = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
								ConfigureLink.relationType.objectID.ID,
								ConfigureLink.relationType.objectID.type,
								ConfigureLink.relationType.name,
								ConfigureLink.relationType.objectID.presentation,
								ConfigureLink.relationType.objectID.navigationRef);
							MandatoryCommunication = IntegrationWith1CDocumentManagementCoreClientServer.SettingUpConnectionOfObjectsTO(
								LinkFrom,
								RefTo,
								LinkType);
							MandatoryCommunication.TypeOfLinkComment = ConfigureLink.relationType.comment;
							RequiredLinks.Add(MandatoryCommunication);
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			Data.ComplianceOfMandatoryLinksWithIPObjects.Insert(ObjectIS, RequiredLinks);
		EndIf;
	EndDo;
	
	Return Data;
	
EndFunction

// Generates a universal table of attached printed forms for subsequent creation.
//
// Parameters:
//   PrintForms - Array of XDTODataObject - list of XDTO objects of the DMPrintedForm type.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCore.AttachedPrintedForms
//
Function AttachedPrintedForms(PrintForms) Export
	
	AttachedPrintedForms = IntegrationWith1CDocumentManagementCore.AttachedPrintedForms();
	For Each String In PrintForms Do
		NewRow = AttachedPrintedForms.Add();
		NewRow.CommandName = String.commandName;
		NewRow.PrintManager = String.printManager;
		NewRow.ShouldUpdate = String.update;
		If IntegrationWith1CDocumentManagementCore.PropertySet(String, "role") Then
			NewRow.FileRoleID = String.role.objectID.id;
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(String, "additionalParameters") Then
			NewRow.AdditionalParameters = String.additionalParameters;
		EndIf;
	EndDo;
	
	Return AttachedPrintedForms;
	
EndFunction

// Adds Workflow commands to the object form when created on the server.
//
// Parameters:
//   Form - ClientApplicationForm - the form from which the procedure is called.
//   CommandLocation - FormGroup - the default location is the command panel of the form.
//   NotificationParameters - Structure - parameters where the command source can be set.
//
Procedure OnCreateAtServer(Form, CommandLocation = Undefined, NotificationParameters = Undefined) Export
	
	If Not UseIntegration() Then
		Return;
	EndIf;
	
	// Hide the extra BID commands.
	IntegrationWith1CDocumentManagementCore.RemoveDuplicatesOfIntegrationCommands(
		Form,
		Metadata.CommonCommands.IntegrationWith1CDocumentManagementStartProcessing.Name);
	
EndProcedure

// Processes the result of an action on a task or with processing.
//
// Parameters:
//   ResultOfActionIsString - String - the result of the action, converted to a string.
//   DataForUpdate - XDTODataObject - an implicit return value to which the data
//     required to update the form will be passed.
//   ObjectIsBeingUpdated - Boolean - indicates whether the batch request contains a request to update the object.
//   ControlOverSendingFiles - See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
//
// Returns:
//   Structure:
//     * Success - Boolean
//     * WarningText - String
//     * RequiredInteractiveAction - See IntegrationWith1CDocumentManagement3ClientServer.RequiredInteractiveAction
//
Function ResultOfCommandOnObject(ResultOfActionIsString, DataForUpdate,
		ObjectIsBeingUpdated = False, ControlOverSendingFiles = Undefined) Export
	
	Result = New Structure("Success, WarningText, RequiredInteractiveAction",
		True, "", IntegrationWith1CDocumentManagement3ClientServer.RequiredInteractiveAction());
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
		Proxy,
		ResultOfActionIsString);
	
	If ObjectIsBeingUpdated Then
		AnswerIsToUpdateObject = ResponseToPackageRequests.responses[0];
		ExecutionResult = ResponseToPackageRequests.responses[1];
		NumberOfDataRequestToUpdate = 2;
		
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, AnswerIsToUpdateObject, "DMError") Then
			IntegrationWith1CDocumentManagementCore.RecordXDTOError(AnswerIsToUpdateObject);
		Else
			// The object BEFORE was successfully updated.
			For Each String In ControlOverSendingFiles Do
				InformationRegisters.ControlOverSendingFilesTo1CDocumentManagement.SaveHashSumOfFileVersion(
					String.Source,
					String.FileName,
					String.SpreadsheetDocument)
			EndDo;
		EndIf;
	Else
		ExecutionResult = ResponseToPackageRequests.responses[0];
		NumberOfDataRequestToUpdate = 1;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ExecutionResult, "DMError") Then
		Result.Success = False;
		Result.WarningText = TrimAll(ExecutionResult.description);
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(
			ExecutionResult, "requiredInteractiveAction") Then
		Result.Success = False;
		FillInInteractiveAction(
			Proxy,
			Result.RequiredInteractiveAction,
			ExecutionResult.requiredInteractiveAction);
		If IntegrationWith1CDocumentManagementCore.PropertySet(
				ExecutionResult, "interactiveActionResultCache") Then
			Result.RequiredInteractiveAction.CacheOfPreviousResults =
				IntegrationWith1CDocumentManagementCore.XDTOObjectInString(Proxy, ExecutionResult);
		EndIf;
	EndIf;
	
	If ResponseToPackageRequests.responses.Count() = NumberOfDataRequestToUpdate + 1 Then
		DataForUpdate = ResponseToPackageRequests.responses[NumberOfDataRequestToUpdate];
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, DataForUpdate, "DMError") Then
			IntegrationWith1CDocumentManagementCore.WriteError(
				TrimAll(DataForUpdate.description),
				DataForUpdate.subject);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the result of executing an expression in the embedded language. An expression can only be used to calculate
// any value that the function will eventually return. No changes should be made to the database at
// the same time, so the expression is executed in a transaction that is rolled back after the End of execution.
//
// Parameters:
//   ComputedExpression - String - expression in the built-in language.
//   Source - Arbitrary - data source.
//   Receiver - Arbitrary - data receiver.
//   CurrentRow - Arbitrary - passed if the expression is used to fill in the Attributes
//     of a row in the table part.
//
// Returns:
//   Arbitrary - the result of executing an expression in the embedded language.
//
Function ResultOfExpressionInEmbeddedLanguage(ComputedExpression, Val Source, Receiver = Undefined,
		CurrentRow = Undefined) Export
	
	Parameters = New Structure("Source", Source);
	
	If TypeOf(Source) = Type("XDTODataObject") Then
		// Let's convert the XDTO object into a structure, and add properties to the resulting structure that are not in
		// the original XDTO object, but which can be accessed from an expression in the embedded language.
		Parameters.Source = New Structure;
		For Each XDTOProperty In Source.Type().Properties Do
			Parameters.Source.Insert(XDTOProperty.Name, Source[XDTOProperty.Name]);
		EndDo;
		If IntegrationWith1CDocumentManagementCore.PropertySet(Source, "statusByActionTypeRows") Then
			For Each RowStatus In Source.statusByActionTypeRows.rows Do
				Parameters.Source.Insert(
					StrTemplate("status_%1", StrReplace(RowStatus.actionType.objectID.id, "-", "_")),
					RowStatus.status);
			EndDo;
		EndIf;
	EndIf;
	Parameters.Insert("Receiver", Receiver);
	Parameters.Insert("CurrentRow", CurrentRow);
	Parameters.Insert("Result", Undefined);
	
	Error = "";
	Try
		IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
			ComputedExpression,
			Parameters);
	Except
		Error = StrTemplate(
			NStr("vi = 'Đã tìm thấy lỗi trong biểu thức bằng ngôn ngữ hệ thống:
				|%1';
				|ru = 'Найдена ошибка в выражении на встроенном языке:
				|%1';
				|en = 'An error is found in the expression in 1C:Enterprise language:
				|%1'; fa = 'An error is found in the expression in 1C:Enterprise language:
				|%1';
				|it = 'Найдена ошибка в выражении на встроенном языке:
				|%1';
				|pl = 'An error is found in the expression in 1C:Enterprise language:
				|%1';
				|tr = 'Yerleşik dildeki ifadede hata bulundu:
				|%1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
	
	If Error = "" Then
		Return Parameters.Result;
	Else
		Raise Error;
	EndIf;
	
EndFunction

// Resets the quick search (selection of objects).
//
// Parameters:
//   QuickSearch - FormDataCollection - the "Quick search" table on the task list form.
//   ResetSelectionButton - FormButton - the "Reset selection" button.
//
Procedure ResetQuickSearch(QuickSearch, ResetSelectionButton) Export
	
	For Each String In QuickSearch Do
		
		If String.Fixed Then
			Continue;
		EndIf;
		
		String.Value = String.DefaultValue;
		String.ValueID = String.DefaultValueID;
		String.ValueType = String.DefaultValueType;
		
	EndDo;
	
	UpdateQuickSearchPresentation(QuickSearch, ResetSelectionButton);
	
EndProcedure

// Copies the XDTO object.
//
// Parameters:
//   Receiver - XDTODataObject - where to copy.
//   Source - XDTODataObject - from where to copy.
//   ProxyBefore - WSProxy - an object for connecting to Document Management web services. If specified, the object is copied
//     DMService, if omitted, the DMILService object is copied.
//
Procedure CopyXDTOObject(Receiver, Source, ProxyBefore = Undefined) Export
	
	If ProxyBefore = Undefined Then
		Receiver = CreateBIDObject(Source.Type().Name);
	Else
		Receiver = IntegrationWith1CDocumentManagementCore.CreateObject(ProxyBefore, Source.Type().Name);
	EndIf;
	For Each Property In Source.Type().Properties Do
		
		If Not IntegrationWith1CDocumentManagementCore.PropertySet(Source, Property.Name) Then
			Continue;
		EndIf;
		
		If TypeOf(Source[Property.Name]) = Type("XDTODataObject") Then
			CopyXDTOObject(Receiver[Property.Name], Source[Property.Name], ProxyBefore);
			
		ElsIf TypeOf(Source[Property.Name]) = Type("XDTOList") Then
			DestinationTable1 = Receiver[Property.Name]; // XDTOList
			For Each SourceListString In Source[Property.Name] Do
				ReceiverListLine = Undefined;
				CopyXDTOObject(ReceiverListLine, SourceListString, ProxyBefore);
				DestinationTable1.Add(ReceiverListLine);
			EndDo;
			
		Else
			Receiver[Property.Name] = Source[Property.Name];
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Creates a new Document flow object according to the IP object and the specified rule.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ObjectIS - AnyRef - the IP object, the data source of the filling.
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - filling rule.
//   LinksToCreation - Array of See IntegrationWith1CDocumentManagementCoreClientServer.ConnectionToCreation
//   PreliminaryDataInRepository - String - the address in the temporary storage containing
//     the structure See IntegrationWith1CDocumentManagement3.PreliminaryDataForUnloadingVDO
//   NewObjectsBefore - Array of See IntegrationWith1CDocumentManagement3ClientServer.NewObjectBefore
//
// Returns:
//   XDTODataObject - created object:
//     * name - String
//     * objectID - XDTODataObject:
//       ** ID - String
//       ** type - String
//   The string is an error message.
//
Function CreateMapItemUsingRule(Proxy, ObjectIS, Rule, LinksToCreation = Undefined,
		PreliminaryDataInRepository = Undefined, NewObjectsBefore = Undefined) Export
	
	LinkedObjectBefore =
		InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ObjectDataUpToExternalObject(ObjectIS);
	If LinkedObjectBefore <> Undefined Then
		If ValueIsFilled(LinkedObjectBefore.ID) And ValueIsFilled(LinkedObjectBefore.type) Then
			Return IntegrationWith1CDocumentManagementCore.GetObject(
				Proxy,
				LinkedObjectBefore.type,
				LinkedObjectBefore.ID);
		Else
			Return NStr("ru = 'Выгрузка в 1С:Документооборот уже началась. Повторите попытку еще раз.';
						|vi = 'Export to 1C:Document Management has already started. Try again.';
						|en = 'Export to 1C:Document Management has already started. Try again.'; fa = 'Export to 1C:Document Management has already started. Try again.';
						|it = 'Export to 1C:Document Management has already started. Try again.';
						|pl = 'Export to 1C:Document Management has already started. Try again.';
						|tr = '1C:Document Management''ne yükleme zaten başladı. Lütfen bir kez daha deneyin.'");
		EndIf;
	EndIf;
	
	InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.AddLink("", "", ObjectIS, False);
	
	Try
		
		ListOfIPObjects = CommonClientServer.ValueInArray(ObjectIS);
		
		SuitableIntegrationRules = New Map;
		SuitableIntegrationRules.Insert(ObjectIS, CommonClientServer.ValueInArray(Rule));
		
		PreliminaryData = Undefined;
		If PreliminaryDataInRepository <> Undefined Then
			PreliminaryData = GetFromTempStorage(PreliminaryDataInRepository);
			DeleteFromTempStorage(PreliminaryDataInRepository);
		EndIf;
		
		If PreliminaryData = Undefined Then
			PreliminaryData = PreliminaryDataForUnloadingVDO(
				Proxy,
				ListOfIPObjects,
				SuitableIntegrationRules,,,
				NewObjectsBefore);
		EndIf;
		
		If LinksToCreation <> Undefined Then
			For Each ConnectionToCreation In LinksToCreation Do
				PreliminaryData.MatchingCreatedLinksToIPObjects[ObjectIS].Add(ConnectionToCreation);
			EndDo;
		EndIf;
		
		Result = CreateObjectsUPToRules(
			Proxy,
			ListOfIPObjects,
			PreliminaryData);
		
		If Result[ObjectIS].Success Then
			Return Result[ObjectIS].XDTODataObject;
		Else
			InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.DeleteLink("", "", ObjectIS);
			Return Result[ObjectIS].ErrorText;
		EndIf;
		
	Except
		
		InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.DeleteLink("", "", ObjectIS);
		Raise;
		
	EndTry;
	
EndFunction

// Creates new Workflow objects for the list of IP objects according to the rules corresponding to them.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ListOfIPObjects - Array of AnyRef - IP objects, the source of the filling data.
//   PreliminaryData - See IntegrationWith1CDocumentManagement3.PreliminaryDataForUnloadingVDO
//
// Returns:
//   Map of KeyAndValue:
//     * Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//     * Value - Structure - the result for the IP object:
//       ** Success - Boolean - True if the linked object in BEFORE was created successfully, False if errors occurred.
//       ** ErrorText - String - error message.
//       ** XDTODataObject - XDTODataObject - an object created in BEFORE.
//
Function CreateObjectsUPToRules(Proxy, ListOfIPObjects, PreliminaryData) Export
	
	Result = New Map;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCreateFromIncomingDataRequest");
	
	ControlOverSendingFiles = IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles();
	
	// We will add to the request those objects for which there is a single suitable dataLoadingRule.
	For Each ObjectIS In ListOfIPObjects Do
		
		ObjectResults = New Structure("Success, ErrorText, XDTODataObject", True, "", Undefined);
		
		VDOLoadingRule = RuleForLoadingVDOSFromPreliminaryData(Proxy, PreliminaryData, ObjectIS);
		If VDOLoadingRule = Undefined Then
			ObjectResults.Success = False;
			ObjectResults.ErrorText = NStr("vi = 'Không tìm thấy quy tắc kết nhập dữ liệu phù hợp vào 1C:Document Management';
											|ru = 'Не найдено подходящее правило загрузки данных в 1С:Документооборот';
											|en = 'Suitable 1C:Document Management data import rule is not found'; fa = 'Suitable 1C:Document Management data import rule is not found';
											|it = 'Non è stata trovata alcuna regola di caricamento dati adatta in 1C:Document Management';
											|pl = 'Nie znaleziono pasującej reguły eksportu danych do 1C:Document Management';
											|tr = '1C:Document Management''te uygun veri indirme kuralı bulunamadı'");
			Result.Insert(ObjectIS, ObjectResults);
			Continue;
		EndIf;
		
		ObjectCreationStructure = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMIncomingDataRequestStructure",
			ObjectIS);
		
		Try
			ObjectCreationStructure.incomingData = IncomingIPObjectData(
				Proxy,
				ObjectIS,
				PreliminaryData.ComplianceOfListOfTSToBeUnloadedWithIPObjects[ObjectIS],
				PreliminaryData.MatchingListOfExpressionsToIPObjects[ObjectIS]);
		Except
			ObjectResults.Success = False;
			ObjectResults.ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			Result.Insert(ObjectIS, ObjectResults);
			Continue;
		EndTry;
		
		ObjectCreationStructure.dataLoadingRule = VDOLoadingRule;
		
		If PreliminaryData.FileFunctionalityIsAvailable Then
			
			PrintForms = ObjectCreationStructure.files; // XDTOList
			
			PrintedFormsToCreate = IntegrationWith1CDocumentManagementCore.PrintedFormsToCreate(
				ObjectIS,
				AttachedPrintedForms(PreliminaryData.ComplianceOfPrintedFormsWithIPObjects[ObjectIS]),
				Enums.TypesOfSavedPrintedFormFileOfObjects[PreliminaryData.TypesOfPrintedFormFiles[ObjectIS]],
				ControlOverSendingFiles);
			
			For Each CreationParameters In PrintedFormsToCreate Do
				XDTOFile = IntegrationWith1CDocumentManagementCore.XDTOFileFromCreationParameters(
					Proxy,
					CreationParameters);
				PrintForms.Add(XDTOFile);
			EndDo;
			
		EndIf;
		
		If PreliminaryData.CreatingLinksIsAvailable Then
			TransferLinksToBeCreatedToIncomingDataStructure(
				Proxy,
				PreliminaryData.MatchingCreatedLinksToIPObjects[ObjectIS],
				ObjectCreationStructure);
		EndIf;
		
		Query.objects.Add(ObjectCreationStructure);
		
		Result.Insert(ObjectIS, ObjectResults);
		
	EndDo;
	
	If Query.objects.Count() = 0 Then
		Return Result;
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	For Each String In ControlOverSendingFiles Do
		InformationRegisters.ControlOverSendingFilesTo1CDocumentManagement.SaveHashSumOfFileVersion(
			String.Source,
			String.FileName,
			String.SpreadsheetDocument)
	EndDo;
	
	BarcodeIsSetWhenCreating =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.19.30");
	
	For Each ResponseStructure In Response.objects Do
		ObjectIS = IntegrationWith1CDocumentManagementCore.LinkFromUUID(
			ResponseStructure.key.type,
			ResponseStructure.key.ID);
		If ResponseStructure.success Then
			
			XDTODataObject = ResponseStructure.object;
			Result[ObjectIS].XDTODataObject = XDTODataObject;
			
			WhetherFilesAreAttached = False; // An additional request to the DO is not required.
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "files") Then
				WhetherFilesAreAttached = (XDTODataObject.files.Count() > 0);
			EndIf;
			IntegrationWith1CDocumentManagementCoreServerCall.AddLink(
				XDTODataObject.objectID.ID,
				XDTODataObject.objectID.type,
				ObjectIS,
				WhetherFilesAreAttached,
				False);
			
			If Not BarcodeIsSetWhenCreating Then
				IntegrationWith1CDocumentManagementCore.SetBarcode(
					ObjectIS,
					XDTODataObject.objectID.ID,
					XDTODataObject.objectID.type);
			EndIf;
			
		Else
			Result[ObjectIS].Success = False;
			Result[ObjectIS].ErrorText =
				IntegrationWith1CDocumentManagementCoreClientServer.DeleteThoseInformationFromErrorText(
					ResponseStructure.error.description);
			IntegrationWith1CDocumentManagementCore.WriteError(ResponseStructure.error.description);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Finds it on the 1C side:Workflow rules for uploading data to 1C:Document flow corresponding
// to the transferred objects of the integrated system.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ListOfIPObjects - Array of AnyRef - IP objects for which you want to find the appropriate rules.
//   SuitableIntegrationRules - Map of KeyAndValue - relevant integration rules:
//     * Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//     * Value - Array of CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - a list of suitable rules.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IP object.
//     * Value - String - string Presentation of an XDTO object of type DMDataLoadingRule.
//                - Undefined - if a suitable upload rule was not found.
//
Function ComplianceOfRulesForLoadingVDOWithIPObjects(Proxy, ListOfIPObjects, SuitableIntegrationRules) Export
	
	Result = New Map;
	
	If ListOfIPObjects.Count() = 0 Then
		Return Result;
	EndIf;
	
	AllRules = New Array;
	For Each ComplianceWithRules In SuitableIntegrationRules Do
		For Each Rule In ComplianceWithRules.Value Do
			If AllRules.Find(Rule) = Undefined Then
				AllRules.Add(Rule);
			EndIf;
		EndDo;
	EndDo;
	LinksToRulesForLoadingVDO = Common.ObjectsAttributeValue(AllRules, "DMDataLoadingRule");
	
	For Each ObjectIS In ListOfIPObjects Do
		VDOLoadingRule = Undefined;
		If SuitableIntegrationRules[ObjectIS] <> Undefined
				And SuitableIntegrationRules[ObjectIS].Count() = 1 Then
			IntegrationRule = SuitableIntegrationRules[ObjectIS][0];
			RuleOfLoadingVDOXDTO = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				LinksToRulesForLoadingVDO[IntegrationRule],
				"DMDataLoadingRule");
			VDOLoadingRule = IntegrationWith1CDocumentManagementCore.XDTOObjectInString(
				Proxy,
				RuleOfLoadingVDOXDTO);
		EndIf;
		Result.Insert(ObjectIS, VDOLoadingRule);
	EndDo;
	
	Return Result;
	
EndFunction

// sets the Conditional appearance of the "quick search" table.
//
// Parameters:
//   ConditionalAppearance - DataCompositionConditionalAppearance
//   QuickSearchTable - FormTable - the "Quick search" table.
//   Cell_Value - FormField - the "Value" cell of the "Quick Search" table.
//
Procedure SetConditionalAppearanceOfQuickSearchTable(ConditionalAppearance, QuickSearchTable, Cell_Value) Export
	
	// Empty text of the value.
	Item = ConditionalAppearance.Items.Add();
	
	Fields = Item.Fields.Items;
	Fields.Add().Field = New DataCompositionField(Cell_Value.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(QuickSearchTable.Name + ".Value");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", "");
	
	// Fixed cell.
	Item = ConditionalAppearance.Items.Add();
	
	Fields = Item.Fields.Items;
	Fields.Add().Field = New DataCompositionField(QuickSearchTable.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(QuickSearchTable.Name + ".Fixed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.BackgroundColorAllFields);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Checks whether the transmitted document type describes UP to 3.
//
// Parameters:
//   XDTOObjectType - String - object type.
//
// Returns:
//   Boolean
//
Function IsDocumentBefore3(XDTOObjectType) Export
	
	TypesList = New Array;
	TypesList.Add("DMDocument");
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.11.25") Then
		TypesList.Add("DMInternalDocument");
		TypesList.Add("DMIncomingDocument");
		TypesList.Add("DMOutgoingDocument");
	EndIf;
	
	Return TypesList.Find(XDTOObjectType) <> Undefined;
	
EndFunction

// Checks whether the passed type describes a known review object.
//
// Parameters:
//   XDTOObjectType - String - object type.
//
// Returns:
//   Boolean
//
Function ThisIsWellKnownObjectOfReview(XDTOObjectType) Export
	
	TypesList = New Array;
	TypesList.Add("DMIncomingElectronicDocument");
	TypesList.Add("DMOutgoingElectronicDocument");
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.14.31") Then
		TypesList.Add("DMCorrespondent");
		TypesList.Add("DMMeeting");
		TypesList.Add("DMMeetingMinutesItem");
		TypesList.Add("DMProject");
		TypesList.Add("DMProjectTask");
		TypesList.Add("DMReservation");
		TypesList.Add("DMIncomingEMail");
		TypesList.Add("DMOutgoingEMail");
		TypesList.Add("DMForumMessage");
		TypesList.Add("DMForumThread");
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.15.41") Then
		TypesList.Add("DMEmployee");
	EndIf;
	
	Return IsDocumentBefore3(XDTOObjectType) Or TypesList.Find(XDTOObjectType) <> Undefined;
	
EndFunction

#EndRegion

#Region Files

// Redraws the overview bookmark in the form.
//
// Parameters:
//   Form - ClientApplicationForm - A Form with an "Overview" tab.
//   ObjectBEFOREXDTOPresentation - XDTODataObject - an XDTO object of the DMGetObjectsHTMLPresentationsResponse type.
//   XDTODataObject - XDTODataObject - An XDTO object of the DMDocument or DMMeeting or DMCorrespondent type.
//
Procedure FillInOverviewTabInForm(Form, ObjectBEFOREXDTOPresentation, XDTODataObject) Export
	
	FileRoles = New Array;
	If IsDocumentBefore3(XDTODataObject.objectID.type) Then
		FileRoles = XDTODataObject.documentType.roles;
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "roles") Then
		FileRoles = XDTODataObject.roles;
	EndIf;
	
	Form.UseFileRoles = (FileRoles.Count() > 0);
	
	ListOfFiles = New Array;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "files") Then
		ListOfFiles = XDTODataObject.files; // XDTOList
	EndIf;
	
	FilesCount = ListOfFiles.Count();
	
	ObjectPresentation = IntegrationWith1CDocumentManagement3ClientServer.ObjectTypePresentationXDTO(
		XDTODataObject.objectID.type);
	
	FilesTree = Form.FilesTree; // See DataProcessor.IntegrationWith1CDocumentManagement3.Form.DocumentManagement.FilesTree
	FilesTreeRows = FilesTree.GetItems();
	FilesTreeRows.Clear();
	
	// 1. Print the line of the object itself.
	ObjectString = FilesTreeRows.Add();
	ObjectString.PictureIndex = 10;
	ObjectString.Description = ObjectPresentation;
	ObjectString.ID = Form.ObjectBeforeID;
	ObjectString.Type = Form.ObjectBeforeType;
	ObjectString.URL = Form.MapItemDMNavigationLink;
	ObjectString.PresentationHTML = ObjectBEFOREXDTOPresentation.ObjectsHTMLPresentations[0].htmlView;
	
	// 2. We will display the EDI documents (if available).
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "EDIDocuments") Then
		For Each DocumentEDI In XDTODataObject.EDIDocuments Do
			NewRow = FilesTreeRows.Add();
			NewRow.PictureIndex = 30;
			NewRow.Description = StrTemplate(NStr("ru = '%1 (Документ ЭДО)';
													|vi = '%1 (EDI document)';
													|en = '%1 (EDI document)'; fa = '%1 (EDI document)';
													|it = '%1 (EDI document)';
													|pl = '%1 (EDI document)';
													|tr = '%1 (EBY Belgesi)'"), DocumentEDI.objectID.presentation);
			NewRow.ID = DocumentEDI.objectID.ID;
			NewRow.Type = DocumentEDI.objectID.type;
			NewRow.URL = DocumentEDI.objectID.navigationRef;
			NewRow.SignedEncryptedPictureNumber = -1;
		EndDo;
	EndIf;
	
	// 3. Display the attached files.
	IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileTree(
		FilesTree,
		Form.AvailableRoles,
		ListOfFiles,
		Form.UseFileRoles,
		FileRoles);
	
	Items = Form.Items;
	
	If FilesCount = 0 Then
		Items.FileDescription.Title = StrTemplate(NStr("ru = '%1 и файлы';
														|vi = '%1 and files';
														|en = '%1 and files'; fa = '%1 and files';
														|it = '%1 and files';
														|pl = '%1 and files';
														|tr = '%1 ve dosyalar'"), ObjectPresentation);
	Else
		Items.FileDescription.Title =
			StrTemplate(NStr("ru = '%1 и файлы (%2)';
							|vi = '%1 and files (%2)';
							|en = '%1 and files (%2)'; fa = '%1 and files (%2)';
							|it = '%1 and files (%2)';
							|pl = '%1 and files (%2)';
							|tr = '%1 ve dosyalar (%2)'"), ObjectPresentation, FilesCount);
	EndIf;
	
	If Form.UseDigitalSignatureBefore Then
		If IsDocumentBefore3(XDTODataObject.objectID.type) Then
			Form.AddressOfObjectSBinaryData.AddressOfDocumentImpression = PutToTempStorage(
				XDTODataObject.keyPropertiesValue, Form.UUID);
		EndIf;
		ObjectSignatures = New Array;
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "signatures") Then
			ObjectSignatures = XDTODataObject.signatures; // XDTOList
			ObjectString.SignedWithDS = (ObjectSignatures.Count() > 0);
		EndIf;
		ObjectDocumentManagement =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				Form.ObjectBeforeID,
				Form.ObjectBeforeType,
				Form.ObjectBefore);
		IntegrationWith1CDocumentManagementCore.FillSignatureList(
			ObjectDocumentManagement,
			ObjectSignatures,
			ListOfFiles,
			Form.SignatureTree,
			Form.NumberOfItemInstances,
			Form.UUID);
	EndIf;
	Form.SignedWithDS = ObjectString.SignedWithDS;
	If ObjectString.SignedWithDS Then
		ObjectString.SignedEncryptedPictureNumber = 2;
	Else
		ObjectString.SignedEncryptedPictureNumber = -1;
	EndIf;
	
	// Let's check the availability of the add commands.
	IntegrationWith1CDocumentManagementCore.FillInPPEOfXDTOObject(Form, XDTODataObject);
	Items.FilesAdd.Enabled = (Form.StateAllowsFileAddition
		Or Form.StateAllowsAddingScannedCopy) And Not ObjectString.SignedWithDS;
	Items.FilesAddContext.Enabled = (Form.StateAllowsFileAddition
		Or Form.StateAllowsAddingScannedCopy) And Not ObjectString.SignedWithDS;
	Items.FilesAddPrintedForm.Enabled = (Form.StateAllowsFileAddition
		Or Form.StateAllowsAddingScannedCopy) And Not ObjectString.SignedWithDS;
	Items.FilesAddPrintedFormContext.Enabled = (Form.StateAllowsFileAddition
		Or Form.StateAllowsAddingScannedCopy) And Not ObjectString.SignedWithDS;
	Items.FilesInsertImageFromBuffer.Enabled = (Form.StateAllowsFileAddition
		Or Form.StateAllowsAddingScannedCopy) And Not ObjectString.SignedWithDS;
	Items.FilesImportFilesContext.Enabled = (Form.StateAllowsFileAddition
		Or Form.StateAllowsAddingScannedCopy) And Not ObjectString.SignedWithDS;
	
	// Fill in the State group.
	ObjectBEFOREHasGroupOfStates = IsDocumentBefore3(XDTODataObject.objectID.type) Or XDTODataObject.objectID.type = "DMMeeting";
	If Form.ReceivingFormDataIsAvailable And ObjectBEFOREHasGroupOfStates Then
		Items.StatusGroup_3.Visible = True;
		
		ElementStructure = StructureOfImageField(XDTODataObject.form.interactionStatusInObjectOverview);
		FillPropertyValues(Items.PictureInteraction, ElementStructure);
		Form.StatusInteraction = ElementStructure.PictureIndex;
		
		ElementStructure = StructureOfImageField(XDTODataObject.form.categoryStatusInObjectOverview);
		FillPropertyValues(Items.CategoryPicture, ElementStructure);
		Form.CategoryStatus = ElementStructure.PictureIndex;
		
		ElementStructure = StructureOfImageField(XDTODataObject.form.forumStatusInObjectOverview);
		FillPropertyValues(Items.PictureForum, ElementStructure);
		Form.StatusForum = ElementStructure.PictureIndex;
		
		ElementStructure = StructureOfImageField(XDTODataObject.form.monitoringStatusInObjectOverview);
		FillPropertyValues(Items.ImageControl, ElementStructure);
		Form.ControlStatus = ElementStructure.PictureIndex;
		
		If IsDocumentBefore3(XDTODataObject.objectID.type) Then
			ElementStructure = StructureOfImageField(XDTODataObject.form.digitalSignatureStatusInObjectOverviews);
			FillPropertyValues(Items.EPImage, ElementStructure);
			Form.ItemInstanceStatus = ElementStructure.PictureIndex;
			// Let's set the item instance image for the line of the object itself.
			If Form.ItemInstanceStatus > 0 Then
				ObjectString.SignedEncryptedPictureNumber = Form.ItemInstanceStatus * 2;
			EndIf;
			
			ElementStructure = StructureOfImageField(XDTODataObject.form.EDIStatusInObjectOverview);
			FillPropertyValues(Items.EDOImage, ElementStructure);
			Form.EDIStatus = ElementStructure.PictureIndex;
			
			ElementStructure = StructureOfImageField(XDTODataObject.form.caseStatusInObjectOverview);
			FillPropertyValues(Items.UserTaskStatePicture, ElementStructure);
			Form.StorageUserTaskState = ElementStructure.PictureIndex;
		Else
			Items.EPImage.Visible = False;
			Items.EDOImage.Visible = False;
			Items.UserTaskStatePicture.Visible = False;
		EndIf;
	Else
		Items.StatusGroup_3.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region Tasks

// Returns a request to take the task to work.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   DataByTask - See IntegrationWith1CDocumentManagement3ClientServer.DataByTask
//
// Returns:
//   XDTODataObject - an XDTO object of the DMAcceptTasksRequest type.
//
Function TakeTaskToWorkRequest(Proxy, DataByTask) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMAcceptTasksRequest");
	TaskList = Query.tasks; // XDTOList
	
	taskAction = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		DataByTask.TaskAction.Type);
	taskAction.name = DataByTask.TaskAction.Description;
	taskAction.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DataByTask.TaskAction.ID,
		DataByTask.TaskAction.Type);
	
	TaskList.Add(taskAction);
	
	Return Query;
	
EndFunction

// Returns a request to perform a task action in the Workflow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   DataByTask - See IntegrationWith1CDocumentManagement3ClientServer.DataByTask
//
// Returns:
//   XDTODataObject - an XDTO object of the DMExecuteTaskActionRequest type.
//
Function PerformRequestTaskAction(Proxy, DataByTask) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMExecuteTaskActionRequest");
	If IntegrationWith1CDocumentManagementCore.PropertyExists(Query, "interactiveActionResult") Then
		ResultsOfInteractiveActions = Query.interactiveActionResult; // XDTOList
	Else
		ResultsOfInteractiveActions = New Array;
	EndIf;
	
	Query.taskAction = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		DataByTask.TaskAction.Type);
	Query.taskAction.name = DataByTask.TaskAction.Description;
	Query.taskAction.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DataByTask.TaskAction.ID,
		DataByTask.TaskAction.Type);
	
	Query.resultOfTaskAction = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		DataByTask.ActionResult.Type);
	Query.resultOfTaskAction.name = DataByTask.ActionResult.Description;
	Query.resultOfTaskAction.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DataByTask.ActionResult.ID,
		DataByTask.ActionResult.Type);
	
	Query.actionResultString = DataByTask.ResultOfActionInText;
	Query.dataVersion = DataByTask.DataVersionOfTaskAction;
	
	Context = DataByTask.RequiredInteractiveAction.Context;
	
	If DataByTask.RequiredInteractiveAction.SelectTaskExecutor Then
		
		ResultOfXDTO = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMInteractiveActionContext");
		ResultOfXDTO.interactiveAction = "SelectTaskPerformer";
		ResultOfXDTO.context = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMActualTaskPerformer");
		If Context.Addressee <> Undefined Then
			ResultOfXDTO.context.addressee =
				IntegrationWith1CDocumentManagementCore.CreateFromReferenceObjectDataUPTO(
				Proxy,
				Context.Addressee);
		EndIf;
		If Context.Employee <> Undefined Then
			ResultOfXDTO.context.actualPerformer =
				IntegrationWith1CDocumentManagementCore.CreateFromReferenceObjectDataUPTO(
				Proxy,
				Context.Employee);
		EndIf;
		ResultOfXDTO.context.isDeputy = Context.ThisIsSubstitute;
		ResultsOfInteractiveActions.Add(ResultOfXDTO);
		
	ElsIf DataByTask.RequiredInteractiveAction.AskRandomQuestion Then
		
		ResultOfXDTO = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMInteractiveActionContext");
		ResultOfXDTO.interactiveAction = "AskAQuestion";
		ResultOfXDTO.context = Context;
		
		ResultsOfInteractiveActions.Add(ResultOfXDTO);
		
	ElsIf DataByTask.RequiredInteractiveAction.AskQuestionAboutCycleLimit Then
		
		ResultOfXDTO = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMInteractiveActionContext");
		ResultOfXDTO.interactiveAction = "CycleLimitExhaustQuestion";
		ResultOfXDTO.context = Context;
		
		ResultsOfInteractiveActions.Add(ResultOfXDTO);
		
	ElsIf DataByTask.RequiredInteractiveAction.ChangeProcessParameters Then
		
		ResultOfXDTO = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMInteractiveActionContext");
		ResultOfXDTO.interactiveAction = "ChangeProcessParameters";
		If TypeOf(Context) = Type("String") And Not IsBlankString(Context) Then
			ResultOfXDTO.context = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
				Proxy,
				Context);
		EndIf;
		ResultsOfInteractiveActions.Add(ResultOfXDTO);
		
	ElsIf DataByTask.RequiredInteractiveAction.PerformSigning Then
		
		ResultOfXDTO = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMInteractiveActionContext");
		ResultOfXDTO.interactiveAction = "PerformSigning";
		ResultOfXDTO.context = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMSigningContext");
		ListOfDataAndSignatures = ResultOfXDTO.context.dataAndSignatureList; // XDTOList
		For Each SignedObject In Context.DataSet Do
			SignedXDTOObject = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMDataAndSignature");
			SignedXDTOObject.object = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				SignedObject.Presentation.Value.ID,
				SignedObject.Presentation.Value.Type);
			SignedXDTOObject.object.presentation = SignedObject.Presentation.Presentation;
			SignedXDTOObject.signature = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMSignature");
			SignatureData = IntegrationWith1CDocumentManagementCoreClientServer.SignatureData(
				SignedObject.SignatureProperties.Signature,
				SignedObject.SignatureProperties.Certificate,
				SignedObject.SignatureProperties);
			IntegrationWith1CDocumentManagementCore.FillOutXDTOSignature(
				Proxy,
				SignedXDTOObject.signature,
				SignatureData);
			ListOfDataAndSignatures.Add(SignedXDTOObject);
		EndDo;
		If ValueIsFilled(Context.CompletionDate) Then
			ResultOfXDTO.context.executionDate = Context.CompletionDate;
		EndIf;
		If ValueIsFilled(Context.Operation) Then
			ResultOfXDTO.context.operation = Context.Operation;
		EndIf;
		If ValueIsFilled(Context.DataTitle) Then
			ResultOfXDTO.context.title = Context.DataTitle;
		EndIf;
		ResultsOfInteractiveActions.Add(ResultOfXDTO);
		
	EndIf;
	
	If ValueIsFilled(DataByTask.RequiredInteractiveAction.CacheOfPreviousResults) Then
		XDTOCache = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
			Proxy,
			DataByTask.RequiredInteractiveAction.CacheOfPreviousResults);
		For Each ResultOfXDTO In XDTOCache.interactiveActionResultCache Do
			ResultsOfInteractiveActions.Add(ResultOfXDTO);
		EndDo;
	EndIf;
	
	Return Query;
	
EndFunction

// Returns the structure of additional task data.
//
// Parameters:
//   XDTOTask - XDTODataObject - an XDTO object of the DMTaskAction type.
//   CurCurrentUserAndEmployees - Array of XDTODataObject - An XDTO object of type DMUser, DMEmployee, or Undefined.
//
// Returns:
//   Structure:
//     * Scope - See NewTaskScope
//     * ApplicationTree - See NewApplicationTree
//
Function AdditionalInformationOnIssue(XDTOTask, CurCurrentUserAndEmployees = Undefined) Export
	
	If CurCurrentUserAndEmployees = Undefined Then
		CurCurrentUserAndEmployees =
			IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
	EndIf;
	
	If Not IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask, "actionArea") Then
		Return Undefined;
	EndIf;
	
	AdditionalData = New Structure;
	
	AdditionalData.Insert("Scope", ScopeOfTask(XDTOTask.actionArea, XDTOTask.flag));
	
	ApplicationTree = NewApplicationTree();
	ApplicationTreeFromXDTO(XDTOTask, ApplicationTree.Rows, CurCurrentUserAndEmployees);
	AdditionalData.Insert("ApplicationTree", ApplicationTree);
	
	Return AdditionalData;
	
EndFunction

// Converts the "Quick Search" table into a set of filters for requesting a Workflow web service
// to get a list of tasks.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   DisplayFilters - ValueList of Arbitrary - selections to be added to the task list.
//   QuickSearch - FormDataCollection - the "Quick search" table on the task list form.
//
Procedure AddTaskSelectionFilters(Proxy, DisplayFilters, QuickSearch) Export
	
	For Each String In QuickSearch Do
		
		If Not ValueIsFilled(String.Value) Then
			Continue;
		EndIf;
		
		If String.Parameter = "Author" Then
			
			Author = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				String.ValueID,
				String.ValueType,
				String.ValuePresentation);
			AuthorOfXDTO = MemberOfXDTOTasks(Proxy, Author);
			DisplayFilters.Add(AuthorOfXDTO, "author");
			
		ElsIf String.Parameter = "Performer" Then
			
			Performer = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				String.ValueID,
				String.ValueType,
				String.ValuePresentation);
			ArtistXDTO = MemberOfXDTOTasks(Proxy, Performer);
			DisplayFilters.Add(ArtistXDTO, "performer");
			
		ElsIf String.Parameter = "ActionKind" Then
			
			ActionKindXDTO = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				String.ValueID,
				String.ValueType);
			DisplayFilters.Add(ActionKindXDTO, "taskActionType");
			
		ElsIf String.Parameter = "ApplicationKind" Then
			
			AppTypeXDTO = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				String.ValueID,
				String.ValueType);
			DisplayFilters.Add(AppTypeXDTO, "applicationType");
			
		ElsIf String.Parameter = "Project" Then
			
			XDTOProject = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				String.ValueID,
				String.ValueType);
			DisplayFilters.Add(XDTOProject, "project");
			
		ElsIf String.Parameter = "Flag" Then
			
			DisplayFilters.Add(String.Value, "flag");
			
		ElsIf String.Parameter = "DateFrom1" Then
			
			DisplayFilters.Add(String.Value, "beginDate");
			
		ElsIf String.Parameter = "DateTo" Then
			
			DisplayFilters.Add(String.Value, "endDate");
			
		ElsIf String.Parameter = "State" Then
			
			FiltersBasedOnStatusOfIssues = New Array;
			TaskStates = New Array;
			
			ValueType = TypeOf(String.Value);
			If ValueType = Type("String") Then
				
				If String.ValueType = "DMTaskStatusFilter" Then
					FiltersBasedOnStatusOfIssues.Add(String.ValueID);
				ElsIf String.ValueType = "DMTaskStatus" Then
					TaskStates.Add(String.ValueID);
				EndIf;
				
			ElsIf ValueType = Type("ValueList") Then
				
				For Each Item In String.Value Do
					
					If Item.Value.Type = "DMTaskStatusFilter" Then
						FiltersBasedOnStatusOfIssues.Add(Item.Value.ID);
					ElsIf Item.Value.Type = "DMTaskStatus" Then
						TaskStates.Add(Item.Value.ID);
					EndIf;
					
				EndDo;
				
			EndIf;
			
			If FiltersBasedOnStatusOfIssues.Count() > 0 Then
				DisplayFilters.Add(FiltersBasedOnStatusOfIssues, "taskStatusFilter");
			EndIf;
			
			If TaskStates.Count() > 0 Then
				DisplayFilters.Add(TaskStates, "taskStatus");
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Constructor of the task scope.
//
// Returns:
//   Structure:
//     * PerformTaskActionOption1 - Undefined
//     * PerformTaskActionOption2 - Undefined
//     * PerformTaskActionOption3 - Undefined
//     * PerformTemplateTaskAction1 - Undefined
//     * PerformTemplateTaskAction2 - Undefined
//     * PerformTemplateTaskAction3 - Undefined
//     * SelectTemplateForTask - Undefined
//     * PerformConnectedTaskAction1 - Undefined
//     * CancelExecution - Undefined
//     * DataVersionOfTaskAction - String
//     * ResultOfActionInText - String
//     * ResultOfActionIsInputField - Undefined
//     * FlagsSubmenu - Undefined
//     * Flag - String
//     * TakeToWork - Undefined
//     * CancelTakingToWork - Undefined
//     * AddParticipants - Undefined
//     * ResultOfOption1 - String
//     * ResultOfOption1ID - String
//     * ResultOfOption1Type - String
//     * ResultOfOption2 - String
//     * ResultOfOption2ID - String
//     * ResultOfOption2Type - String
//     * ResultOfOption3 - String
//     * ResultOfOption3ID - String
//     * ResultOfOption3Type - String
//
Function NewTaskScope() Export
	
	Scope = New Structure;
	
	Scope.Insert("PerformTaskActionOption1", Undefined);
	Scope.Insert("PerformTaskActionOption2", Undefined);
	Scope.Insert("PerformTaskActionOption3", Undefined);
	Scope.Insert("PerformTemplateTaskAction1", Undefined);
	Scope.Insert("PerformTemplateTaskAction2", Undefined);
	Scope.Insert("PerformTemplateTaskAction3", Undefined);
	Scope.Insert("SelectTemplateForTask", Undefined);
	Scope.Insert("PerformConnectedTaskAction1", Undefined);
	Scope.Insert("CancelExecution", Undefined);
	
	Scope.Insert("ResultOfOption1", "");
	Scope.Insert("ResultOfOption1ID", "");
	Scope.Insert("ResultOfOption1Type", "");
	Scope.Insert("ResultOfOption2", "");
	Scope.Insert("ResultOfOption2ID", "");
	Scope.Insert("ResultOfOption2Type", "");
	Scope.Insert("ResultOfOption3", "");
	Scope.Insert("ResultOfOption3ID", "");
	Scope.Insert("ResultOfOption3Type", "");
	
	Scope.Insert("DataVersionOfTaskAction", "");
	Scope.Insert("ResultOfActionInText", "");
	Scope.Insert("ResultOfActionIsInputField", Undefined);
	Scope.Insert("FlagsSubmenu", Undefined);
	Scope.Insert("Flag", "");
	Scope.Insert("TakeToWork", Undefined);
	Scope.Insert("CancelTakingToWork", Undefined);
	
	Scope.Insert("AddParticipants", Undefined);
	Scope.Insert("ProcessingAction", "");
	Scope.Insert("ProcessingActionID", "");
	Scope.Insert("ProcessingActionType", "");
	
	Return Scope;
	
EndFunction

// Creates a new group of creation commands based on the appropriate rules on the task or task list form.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the task or task list.
//   SuitableObjects - See IntegrationWith1CDocumentManagement3.SuitableObjectsToCreateBasedOnTask
//
// Returns:
//   String - the key of the created task page.
//
Function NewPageOfCommandsToCreateBasedOnTask(Form, SuitableObjects) Export
	
	PageKey = String(New UUID);
	PageKey = StrReplace(PageKey, "-", "_");
	
	// Elements to be copied.
	NameOfPageGroup = "TeamPageGroup";
	SourcePageName = "GroupTeamPage";
	SourcePage = Form.Items[SourcePageName];
	NameOfOriginalSubmenu = "FormCreateBasedOn";
	SourcePanelName = "TaskTeamGroup";
	SourcePanel = Form.Items[SourcePanelName];
	
	NameOfNewPage = SourcePageName + PageKey;
	NameOfNewPanel = SourcePanelName + PageKey;
	
	// Let's create a new page.
	NewPage = Form.Items.Add(NameOfNewPage, Type("FormGroup"), Form.Items[NameOfPageGroup]);
	FillPropertyValues(NewPage, SourcePage,, "Name, TitleDataPath");
	
	// Let's create a new command panel.
	NewPanel = Form.Items.Add(NameOfNewPanel, Type("FormGroup"), NewPage);
	FillPropertyValues(NewPanel, SourcePanel,, "Name");
	
	// Let's copy the command panel elements, limiting ourselves to two levels.
	For Each SourceElement In SourcePanel.ChildItems Do
		NewItem = Form.Items.Add(SourceElement.Name + PageKey, TypeOf(SourceElement), NewPanel);
		FillPropertyValues(NewItem, SourceElement,, "Name");
		If TypeOf(SourceElement) = Type("FormGroup") Then
			NewFolder = NewItem;
			For Each OriginalGroupElement In SourceElement.ChildItems Do
				NewGroupElement = Form.Items.Add(OriginalGroupElement.Name + PageKey,
					TypeOf(OriginalGroupElement), NewFolder);
				FillPropertyValues(NewGroupElement, OriginalGroupElement, , "Name");
			EndDo;
		EndIf;
	EndDo;
	
	// Let's add items specific to this type of object to the standard creation submenu.
	NewSubmenu = Form.Items.Find(NameOfOriginalSubmenu + PageKey);
	For Each SuitableObject In SuitableObjects Do
		If ValueIsFilled(SuitableObject.IntegrationRule) Then
			Command = "Create";
			GUID = StrReplace(String(SuitableObject.IntegrationRule.UUID()), "-", "_");
		Else
			Command = SuitableObject.DocumentEDI.Type;
			GUID = StrReplace(SuitableObject.DocumentEDI.ID, "-", "_");
		EndIf;
		CommandName = StrTemplate("%1_%2", Command, GUID);
		
		If Form.Commands.Find(CommandName) = Undefined Then
			CreateLinkedObjectCommand = Form.Commands.Add(CommandName);
			CreateLinkedObjectCommand.Action = "Attachable_CreateLinkedObject";
		EndIf;
		
		TagName = CommandName + PageKey;
		If Form.Items.Find(TagName) = Undefined Then // Insurance against duplicate rules.
			Button = Form.Items.Add(TagName, Type("FormButton"), NewSubmenu);
			Button.Title = SuitableObject.ObjectPresentationIS;
			Button.CommandName = CommandName;
			Button.LocationInCommandBar = ButtonLocationInCommandBar.InCommandBar;
		EndIf;
	EndDo;
	
	Return PageKey;
	
EndFunction

// Task application tree constructor.
//
// Returns:
//   ValueTree:
//     * Ref - AnyRef
//     * URL - String
//     * PictureIndex - Number
//                      - Picture
//     * Application - String
//     * ApplicationID - String
//     * ApplicationType - String
//     * ApplicationPresentation - String
//     * RowType - String
//     * RoleOfSubject - String
//     * DeletionAvailable - Boolean
//     * Mandatory - Boolean
//     * RoleIsMandatory - Boolean
//     * WaitingForPreview - Boolean
//     * IsBlankString - String
//     * DeletionMark - Boolean
//     * IsOriginal - Boolean
//     * IsBeingEdited - Boolean
//     * EditedByCurUser - Boolean
//     * FileRoleID - String
//     * PresentationHTML - String
//     * PreviewCut - Boolean
//     * SignedWithDS - Boolean
//     * Encrypted - Boolean
//     * ModificationDate - Date
//     * Extension - String
//     * AddressInPreviewFileStorage - String
//     * StateAllowsFileAddition - Boolean
//     * StateAllowsFileDeletion - Boolean
//     * StateAllowsFileEditing - Boolean
//     * StateAllowsAddingScannedCopy - Boolean
//     * StateAllowsChangesToItemInstance - Boolean
//
Function NewApplicationTree() Export
	
	TypesOfImages = New Array;
	TypesOfImages.Add(Type("Number"));
	TypesOfImages.Add(Type("Picture"));
	
	NewApplicationTree = New ValueTree;
	NewApplicationTree.Columns.Add("Ref",
		Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Type);
	NewApplicationTree.Columns.Add("URL", New TypeDescription("String"));
	NewApplicationTree.Columns.Add("PictureIndex", New TypeDescription(TypesOfImages));
	NewApplicationTree.Columns.Add("Application", New TypeDescription("String"));
	NewApplicationTree.Columns.Add("ApplicationID", New TypeDescription("String"));
	NewApplicationTree.Columns.Add("ApplicationType", New TypeDescription("String"));
	NewApplicationTree.Columns.Add("ApplicationPresentation", New TypeDescription("String"));
	NewApplicationTree.Columns.Add("RowType", New TypeDescription("String"));
	NewApplicationTree.Columns.Add("RoleOfSubject", New TypeDescription("String"));
	NewApplicationTree.Columns.Add("DeletionAvailable", New TypeDescription("Boolean"));
	NewApplicationTree.Columns.Add("Mandatory", New TypeDescription("Boolean"));
	NewApplicationTree.Columns.Add("RoleIsMandatory", New TypeDescription("Boolean"));
	NewApplicationTree.Columns.Add("WaitingForPreview", New TypeDescription("Boolean"));
	NewApplicationTree.Columns.Add("IsBlankString", New TypeDescription("String"));
	NewApplicationTree.Columns.Add("DeletionMark", New TypeDescription("Boolean"));
	NewApplicationTree.Columns.Add("IsOriginal", New TypeDescription("Boolean"));
	NewApplicationTree.Columns.Add("IsBeingEdited", New TypeDescription("Boolean"));
	NewApplicationTree.Columns.Add("EditedByCurUser", New TypeDescription("Boolean"));
	NewApplicationTree.Columns.Add("FileRoleID", New TypeDescription("String"));
	NewApplicationTree.Columns.Add("PresentationHTML", New TypeDescription("String"));
	NewApplicationTree.Columns.Add("PreviewCut", New TypeDescription("Boolean"));
	NewApplicationTree.Columns.Add("SignedWithDS", New TypeDescription("Boolean"));
	NewApplicationTree.Columns.Add("Encrypted", New TypeDescription("Boolean"));
	NewApplicationTree.Columns.Add("ModificationDate", New TypeDescription("Date"));
	NewApplicationTree.Columns.Add("Extension", New TypeDescription("String"));
	NewApplicationTree.Columns.Add("AddressInPreviewFileStorage", New TypeDescription("String"));
	
	// NDPS.
	For Each Field In IntegrationWith1CDocumentManagementCoreClientServer.ASBSFields() Do
		NewApplicationTree.Columns.Add(Field.Value, New TypeDescription("Boolean"));
	EndDo;
	
	Return NewApplicationTree;
	
EndFunction

// Redraws the scope in the form of a task and in the form of a task list.
//
// Parameters:
//   Form - ClientApplicationForm - a form with the scope of the task.
//   Scope - See NewTaskScope
//   SavedComment - String - the result of the action is text.
//   ToChangeFont - Boolean - the font of the form elements will be changed if necessary.
//
Procedure UpdateTaskScope(Form, Scope, SavedComment = Undefined,
		ToChangeFont = True) Export
	
	// Update the form elements.
	UpdateButtonInScope(
		Form.Items.PerformTaskActionOption1,
		Form.Commands.PerformTaskActionOption1,
		Scope.PerformTaskActionOption1,
		ToChangeFont);
	UpdateButtonInScope(
		Form.Items.PerformTaskActionOption2,
		Form.Commands.PerformTaskActionOption2,
		Scope.PerformTaskActionOption2,
		ToChangeFont);
	UpdateButtonInScope(
		Form.Items.PerformTaskActionOption3,
		Form.Commands.PerformTaskActionOption3,
		Scope.PerformTaskActionOption3,
		ToChangeFont);
	UpdateButtonInScope(
		Form.Items.PerformTemplateTaskAction1,
		Form.Commands.PerformTemplateTaskAction1,
		Scope.PerformTemplateTaskAction1,
		ToChangeFont);
	UpdateButtonInScope(
		Form.Items.PerformTemplateTaskAction2,
		Form.Commands.PerformTemplateTaskAction2,
		Scope.PerformTemplateTaskAction2,
		ToChangeFont);
	UpdateButtonInScope(
		Form.Items.PerformTemplateTaskAction3,
		Form.Commands.PerformTemplateTaskAction3,
		Scope.PerformTemplateTaskAction3,
		ToChangeFont);
	UpdateButtonInScope(
		Form.Items.SelectTemplateForTask,
		Form.Commands.SelectTemplateForTask,
		Scope.SelectTemplateForTask,
		ToChangeFont);
	UpdateButtonInScope(
		Form.Items.PerformConnectedTaskAction1,
		Form.Commands.PerformConnectedTaskAction1,
		Scope.PerformConnectedTaskAction1,
		ToChangeFont);
	UpdateButtonInScope(
		Form.Items.CancelExecution,
		Form.Commands.CancelExecution,
		Scope.CancelExecution,
		ToChangeFont);
	
	UpdateInputFieldInScope(
		Form.Items.ResultOfActionInText,
		Scope.ResultOfActionIsInputField);
	
	UpdateFormGroup(
		Form.Items.FlagsSubmenu,
		Scope.FlagsSubmenu);
	FlagData = FlagData(Scope.Flag);
	Form.Items.FlagsSubmenu.Picture = FlagData.Picture;
	
	UpdateFormButton(Form.Items.TakeToWork, Scope.TakeToWork);
	UpdateFormButton(Form.Items.CancelTakingToWork, Scope.CancelTakingToWork);
	UpdateFormButton(Form.Items.AddParticipants, Scope.AddParticipants);
	
	// update the Attributes of the form.
	If SavedComment = Undefined Then
		Form.ResultOfActionInText = Scope.ResultOfActionInText;
	Else
		Form.ResultOfActionInText = SavedComment;
	EndIf;
	
	Form.DataVersionOfTaskAction = Scope.DataVersionOfTaskAction;
	Form.ResultOfOption1 = Scope.ResultOfOption1;
	Form.ResultOfOption1ID = Scope.ResultOfOption1ID;
	Form.ResultOfOption1Type = Scope.ResultOfOption1Type;
	Form.ResultOfOption2 = Scope.ResultOfOption2;
	Form.ResultOfOption2ID = Scope.ResultOfOption2ID;
	Form.ResultOfOption2Type = Scope.ResultOfOption2Type;
	Form.ResultOfOption3 = Scope.ResultOfOption3;
	Form.ResultOfOption3ID = Scope.ResultOfOption3ID;
	Form.ResultOfOption3Type = Scope.ResultOfOption3Type;
	Form.ProcessingAction = Scope.ProcessingAction;
	Form.ProcessingActionID = Scope.ProcessingActionID;
	Form.ProcessingActionType = Scope.ProcessingActionType;
	
EndProcedure

// Reads the main subject from an XDTO object of type DMTaskAction.
//
// Parameters:
//   XDTOTask - XDTODataObject - an XDTO object of the DMTaskAction type.
//
// Returns:
//   Structure:
//     * mainApplication - XDTODataObject
//                       - Undefined
//     * ID - String
//     * Type - String
//     * ObjectTypeDM - String
//     * DocumentKindDMID - String
//
Function MainSubjectOfTask(XDTOTask) Export
	
	MainSubject = New Structure;
	MainSubject.Insert("mainApplication", Undefined);
	MainSubject.Insert("ID", "");
	MainSubject.Insert("Type", "");
	MainSubject.Insert("ObjectTypeDM", "");
	MainSubject.Insert("DocumentKindDMID", "");
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask, "mainApplication") Then
		If IntegrationWith1CDocumentManagementCore.PropertySet(
				XDTOTask.mainApplication, "document") Then
			MainSubject.mainApplication = XDTOTask.mainApplication.document; // XDTODataObject
			MainSubject.DocumentKindDMID = XDTOTask.mainApplication.document.documentType.objectID.ID;
		ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(
				XDTOTask.mainApplication, "correspondent") Then
			MainSubject.mainApplication = XDTOTask.mainApplication.correspondent; // XDTODataObject
		ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(
				XDTOTask.mainApplication, "meeting") Then
			MainSubject.mainApplication = XDTOTask.mainApplication.meeting; // XDTODataObject
		EndIf;
		If TypeOf(MainSubject.mainApplication) = Type("XDTODataObject") Then
			SubjectType = MainSubject.mainApplication.Type(); // XDTOObjectType
			MainSubject.ObjectTypeDM = SubjectType.Name;
			MainSubject.ID = MainSubject.mainApplication.objectID.ID;
			MainSubject.Type = MainSubject.mainApplication.objectID.type;
		EndIf;
	EndIf;
	
	Return MainSubject;
	
EndFunction

// Returns a request to cancel taking the task to work.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   DataByTask - See IntegrationWith1CDocumentManagement3ClientServer.DataByTask
//
// Returns:
//   XDTODataObject - An XDTO object of the DMRevokeTaskAcceptanceRequest type.
//
Function CancelTakingTaskToWorkRequest(Proxy, DataByTask) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMRevokeTaskAcceptanceRequest");
	TaskList = Query.tasks; // XDTOList
	
	taskAction = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		DataByTask.TaskAction.Type);
	taskAction.name = DataByTask.TaskAction.Description;
	taskAction.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DataByTask.TaskAction.ID,
		DataByTask.TaskAction.Type);
	
	TaskList.Add(taskAction);
	
	Return Query;
	
EndFunction

// Returns a request to 1C:Workflow for getting a list of tasks.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   CurrentPage - Number - the Cur page number of the list.
//   DynamicListPageSize - Number - the number of tasks per page.
//   SortingField - String - the name of the Attribute by which the list will be sorted.
//   FieldSortingDirection - Boolean - if False, then sort in ascending order, if True, then in descending order.
//   DisplayFilters - ValueList of Arbitrary - selections to be added to the task list.
//   DisplayingTaskCard - EnumRef.HowToDisplayReadingPane - option for displaying
//     the task reading area.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMGetDynamicListRequest type.
//
Function ListOfIssuesRequest(Proxy, CurrentPage, DynamicListPageSize, SortingField,
		FieldSortingDirection, DisplayFilters, DisplayingTaskCard) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetDynamicListRequest");
	
	Query.numberOfObjectsPerPage = DynamicListPageSize;
	Query.page = CurrentPage;
	Query.type = "DMTaskAction";
	
	FilterConditions = Query.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "byUser";
	Condition.value = True;
	FilterConditions.Add(Condition);
	
	For Each Filter In DisplayFilters Do
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = Filter.Presentation;
		If TypeOf(Filter.Value) = Type("Array") Then
			ConditionValues = Condition.valueList; // XDTOList
			For Each Item In Filter.Value Do
				ConditionValues.Add(Item);
			EndDo;
		Else
			Condition.value = Filter.Value;
		EndIf;
		FilterConditions.Add(Condition);
	EndDo;
	
	Sort = Query.orderBy; // XDTOList
	SortingCondition = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMDynamicListSortingCondition");
	SortingCondition.column = SortingField;
	If FieldSortingDirection = True Then
		SortingCondition.sortingOperator = "DESC";
	Else
		SortingCondition.sortingOperator = "ASC";
	EndIf;
	Sort.Add(SortingCondition);
	
	If DisplayingTaskCard <> Enums.HowToDisplayReadingPane.DontDisplay Then
		FieldsReceived = Query.columnSet; // XDTOList
		FieldsReceived.Add("htmlView");
	EndIf;
	
	Return Query;
	
EndFunction

// Constructor of the structure of the question to the user.
//
// Parameters:
//   QuestionToUserXDTO - XDTODataObject - an XDTO object of the DMQuesion type:
//     * text - String
//     * title - String
//     * buttons - Array of String
//     * defaultButton - String
//
// Returns:
//   Structure:
//     * Text - String
//     * Title - String
//     * Buttons - ValueList of String
//     * DefaultButton - String
//
Function StructureOfQuestionToUser(QuestionToUserXDTO) Export
	
	StructureOfQuestionToUser = New Structure;
	StructureOfQuestionToUser.Insert("Text", QuestionToUserXDTO.text);
	If IntegrationWith1CDocumentManagementCore.PropertySet(QuestionToUserXDTO, "title") Then
		StructureOfQuestionToUser.Insert("Title", QuestionToUserXDTO.title);
	Else
		StructureOfQuestionToUser.Insert("Title", "");
	EndIf;
	Buttons = New ValueList;
	For Each XDTOButton In QuestionToUserXDTO.buttons Do
		Buttons.Add(XDTOButton);
	EndDo;
	StructureOfQuestionToUser.Insert("Buttons", Buttons);
	If IntegrationWith1CDocumentManagementCore.PropertySet(QuestionToUserXDTO, "defaultButton") Then
		StructureOfQuestionToUser.Insert("DefaultButton", QuestionToUserXDTO.defaultButton);
	Else
		StructureOfQuestionToUser.Insert("DefaultButton", "");
	EndIf;
	
	Return StructureOfQuestionToUser;
	
EndFunction

// Returns a request to set the task flag.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   DataByTask - See IntegrationWith1CDocumentManagement3ClientServer.DataByTask
//
// Returns:
//   XDTODataObject - An XDTO object of the DMSetFlagRequest type.
//
Function SetRequestTaskFlag(Proxy, DataByTask) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMSetFlagRequest");
	TaskList = Query.tasks; // XDTOList
	
	taskAction = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		DataByTask.TaskAction.Type);
	taskAction.name = DataByTask.TaskAction.Description;
	taskAction.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DataByTask.TaskAction.ID,
		DataByTask.TaskAction.Type);
	
	TaskList.Add(taskAction);
	
	If ValueIsFilled(DataByTask.Flag) Then
		Query.flag = DataByTask.Flag;
	EndIf;
	
	Return Query;
	
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
//   XDTODataObject - An XDTO object of the DMTaskParticipant type.
//
Function MemberOfXDTOTasks(Proxy, Performer, MainAddressingObject = Undefined,
		AdditionalAddressingObject = Undefined) Export
	
	ArrayOfPresentationLines = New Array;
	ArrayOfPresentationLines.Add(Performer.Description);
	If ValueIsFilled(MainAddressingObject)
			And ValueIsFilled(MainAddressingObject.Description) Then
		ArrayOfPresentationLines.Add(MainAddressingObject.Description);
	EndIf;
	If ValueIsFilled(AdditionalAddressingObject)
			And ValueIsFilled(AdditionalAddressingObject.Description) Then
		ArrayOfPresentationLines.Add(AdditionalAddressingObject.Description);
	EndIf;
	Presentation = StrConcat(ArrayOfPresentationLines, ", ");
	
	MemberOfXDTOTasks = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMTaskParticipant");
	MemberOfXDTOTasks.name = Presentation;
	
	If Performer.Type = "DMEmployee" Then
		
		MemberOfXDTOTasks.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			Performer.ID,
			"DMEmployee");
		MemberOfXDTOTasks.employee = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMEmployee");
		MemberOfXDTOTasks.employee.name = Performer.Description;
		MemberOfXDTOTasks.employee.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			Performer.ID,
			"DMEmployee");
		
	ElsIf Performer.Type = "DMCompleteRole" Then
		
		MemberOfXDTOTasks.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			Performer.ID,
			"DMCompleteRole");
		MemberOfXDTOTasks.completeRole = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMCompleteRole");
		MemberOfXDTOTasks.completeRole.name = Performer.Description;
		MemberOfXDTOTasks.completeRole.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			Performer.ID,
			"DMCompleteRole");
		
	ElsIf Performer.Type = "DMBusinessProcessExecutorRole" Then
		
		MemberOfXDTOTasks.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy);
		MemberOfXDTOTasks.completeRole = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMCompleteRole");
		MemberOfXDTOTasks.completeRole.name = Presentation;
		MemberOfXDTOTasks.completeRole.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy);
		IntegrationWith1CDocumentManagementCore.FillInFullRole(
			Proxy,
			MemberOfXDTOTasks.completeRole,
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
	
	Return MemberOfXDTOTasks;
	
EndFunction

// Fills in the Attribute that is a participant in the tasks BEFORE, in the receiver for the object participant of the tasks XDTO.
//
// Parameters:
//   Receiver - Arbitrary - an object containing the requisites or properties
//     that must be filled in by the property of the XDTO object.
//   MemberOfXDTOTasks - XDTODataObject - An XDTO object of the DMTaskParticipant type.
//   AttributeName - String - the name of the object props.
//   FillInPresentation - Boolean - a sign of the need to fill in the presentation details
//     by the ObjectId.presentation property.
//
Procedure TaskParticipantBefore(Receiver, MemberOfXDTOTasks, AttributeName, FillInPresentation = True) Export
	
	If MemberOfXDTOTasks = Undefined Then
		Return;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(MemberOfXDTOTasks, "employee") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Receiver,
			MemberOfXDTOTasks.employee,
			AttributeName);
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(
			MemberOfXDTOTasks, "completeRole") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Receiver,
			MemberOfXDTOTasks.completeRole.role,
			AttributeName);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Receiver,
			MemberOfXDTOTasks.completeRole.mainAddressingObject,
			"MainAddressingObject" + AttributeName);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Receiver,
			MemberOfXDTOTasks.completeRole.secondaryAddressingObject,
			"AdditionalAddressingObject" + AttributeName);
	EndIf;
	
	If FillInPresentation Then
		Receiver[AttributeName + "Presentation"] =
			IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
				Receiver[AttributeName],
				Receiver["MainAddressingObject" + AttributeName],
				Receiver["AdditionalAddressingObject" + AttributeName]);
	EndIf;
	
EndProcedure

#EndRegion

#Region DataProcessor

// Performs a redraw of the processing in the Form.
//
// Parameters:
//   Form - ClientApplicationForm - A Form with a processing tree.
//   XDTOProcessingData - XDTODataObject - an XDTO object of the DMGetCurrentObjectProcessingResponse type.
//
Procedure FillInProcessingInForm(Form, XDTOProcessingData) Export
	
	PrintingIsAvailable =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.14.31");
	
	ActionTree = Form.FormAttributeToValue("Actions"); // ValueTree
	ActionTree.Rows.Clear();
	NumberOfActions = 0;
	
	SubjectType = Undefined;
	Form.ProcessingState = "";
	ThereIsRightToStopProcessing = False;
	ThereAreFamiliarizationActions = False;
	ThereAreMatchingActions = False;
	CompletedNegativelyAndThereAreComments = False;
	UseApprovalVisas = False;
	ProcessingStartDate = Date(1, 1, 1);
	DateOfChangeOfProcessingState = Date(1, 1, 1);
	ASBS = New Structure;
	IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(ASBS);
	If IntegrationWith1CDocumentManagementCore.PropertySet(
			XDTOProcessingData, "objectProcessing") Then
		If IntegrationWith1CDocumentManagementCore.PropertySet(
				XDTOProcessingData.objectProcessing, "target") Then
			SubjectType = XDTOProcessingData.objectProcessing.target.objectID.type;
		EndIf;
		Form.ProcessingState = XDTOProcessingData.objectProcessing.state;
		ThereIsRightToStopProcessing = XDTOProcessingData.objectProcessing.haveRightsToStopProcessing;
		ThereAreFamiliarizationActions = XDTOProcessingData.objectProcessing.haveExaminationActions;
		ThereAreMatchingActions = XDTOProcessingData.objectProcessing.haveApprovalActions;
		If IntegrationWith1CDocumentManagementCore.PropertySet(
				XDTOProcessingData.objectProcessing, "completedNegativelyWithComments") Then
			CompletedNegativelyAndThereAreComments = XDTOProcessingData.objectProcessing.completedNegativelyWithComments;
		EndIf;
		UseApprovalVisas = XDTOProcessingData.objectProcessing.useVisas;
		ProcessingStartDate = XDTOProcessingData.objectProcessing.startDate;
		DateOfChangeOfProcessingState = XDTOProcessingData.objectProcessing.stateChangeDate;
		IntegrationWith1CDocumentManagementCore.FillInNDPPpeOfXDTOProperties(
			ASBS,
			XDTOProcessingData.objectProcessing,
			"stateAllowsStartAndTerminateProcessing,stateAllowsStopAndContinueProcessing,stateAllowsRestartProcessing");
		
		ActionsFromXDTO(XDTOProcessingData.objectProcessing, ActionTree.Rows, NumberOfActions);
	EndIf;
	
	Interrupted = "";
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOProcessingData, "interrupted")
			And ValueIsFilled(XDTOProcessingData.interrupted.objectID.presentation) Then
		Interrupted = XDTOProcessingData.interrupted.objectID.presentation;
	EndIf;
	ReasonForInterruption = XDTOProcessingData.terminationReason;
	EndDate = XDTOProcessingData.endDate;
	ProcessingIsSetByRules = XDTOProcessingData.processingIsSetByRules;
	
	Form.Items.DecorationOfState.Visible = False;
	Form.Items.DetailsDecoration.Visible = True;
	Form.Items.DetailsDecoration.HorizontalStretch = False;
	Form.Items.DetailsDecoration.Title = NStr("vi = 'Không chạy';
												|ru = 'Не запущена';
												|en = 'Not started'; fa = 'شروع‌نشده';
												|it = 'Не запущена';
												|pl = 'Not started';
												|tr = 'Çalışmadı'");
	Form.Items.DetailsDecoration.ToolTip = Form.Items.DetailsDecoration.Title;
	Form.Items.ActionsSend.Visible = (NumberOfActions > 0);
	Form.Items.DecorationActionError.Visible = False;
	Form.Items.ActionsRestartProcessing.Visible = False;
	Form.Items.ActionsPrintApprovalSheet.Visible = PrintingIsAvailable
		And ThereAreMatchingActions
		And UseApprovalVisas;
	Form.Items.PrintHistoryApprovalSheet.Visible = PrintingIsAvailable
		And ThereAreMatchingActions
		And UseApprovalVisas;
	Form.Items.FamiliarizationSheet.Visible = PrintingIsAvailable And ThereAreFamiliarizationActions;
	Form.Items.ActionsProtocolOfDisagreement.Visible = PrintingIsAvailable And CompletedNegativelyAndThereAreComments;
	Form.Items.ActionsToStop.Visible = False;
	Form.Items.DecorationIndentationOfState.Visible = False;
	
	If Not ValueIsFilled(Form.ProcessingState) Or Form.ProcessingState = "Terminated" Then
		
		If NumberOfActions > 0 Then
			Form.Items.ActionsSend.Title = NStr("vi = 'Bắt đầu xử lý';
												|ru = 'Начать обработку';
												|en = 'Start processing'; fa = 'شروع پردازش';
												|it = 'Начать обработку';
												|pl = 'Start processing';
												|tr = 'İşlemeye başla'");
			If SubjectType = "DMDocument" Then
				ToolTip = NStr("vi = 'Bắt đầu xử lý chứng từ';
								|ru = 'Начать обработку документа';
								|en = 'Start document processing'; fa = 'Start document processing';
								|it = 'Начать обработку документа';
								|pl = 'Start document processing';
								|tr = 'Belgeyi işlemeye başla'");
			Else
				ToolTip = NStr("vi = 'Bắt đầu xử lý cuộc họp';
								|ru = 'Начать обработку мероприятия';
								|en = 'Start event processing'; fa = 'Start event processing';
								|it = 'Начать обработку мероприятия';
								|pl = 'Start event processing';
								|tr = 'Etkinliği işlemeye başla'");
			EndIf;
			
			If TypeOf(Form.Items.ActionsSend) = Type("FormButton") Then
				Form.Commands[Form.Items.ActionsSend.CommandName].ToolTip = ToolTip;
			Else
				Form.Items.ActionsSend.ToolTip = ToolTip;
			EndIf;
			
			Form.Items.ActionsSend.Representation = ButtonRepresentation.PictureAndText;
			Form.Items.ActionsSend.Picture = PictureLib.GenerateReport;
		Else
			// There is no action.
			Form.Items.ActionsSend.Visible = False;
		EndIf;
		Form.Items.DetailsDecoration.Visible = False;
		
	ElsIf Form.ProcessingState = "Executing" Or Form.ProcessingState = "Stopped" Then
		
		If ThereIsRightToStopProcessing Then
			Form.Items.ActionsSend.Title = NStr("vi = 'Ngừng';
												|ru = 'Прервать';
												|en = 'Terminate'; fa = 'Terminate';
												|it = 'Прервать';
												|pl = 'Terminate';
												|tr = 'Sonlandır'");
			If SubjectType = "DMDocument" Then
				ToolTip = NStr("vi = 'Ngừng xử lý chứng từ';
								|ru = 'Прервать обработку документа';
								|en = 'Terminate document processing'; fa = 'Terminate document processing';
								|it = 'Прервать обработку документа';
								|pl = 'Terminate document processing';
								|tr = 'Belge işlemeyi sonlandır'");
			Else
				ToolTip = NStr("vi = 'Ngừng xử lý cuộc họp';
								|ru = 'Прервать обработку мероприятия';
								|en = 'Terminate event processing'; fa = 'Terminate event processing';
								|it = 'Прервать обработку мероприятия';
								|pl = 'Terminate event processing';
								|tr = 'Etkinlik işlemeyi sonlandır'");
			EndIf;
			If TypeOf(Form.Items.ActionsSend) = Type("FormButton") Then
				Form.Commands[Form.Items.ActionsSend.CommandName].ToolTip = ToolTip;
			Else
				Form.Items.ActionsSend.ToolTip = ToolTip;
			EndIf;
			
			Form.Items.ActionsSend.Representation = ButtonRepresentation.Picture;
			Form.Items.ActionsSend.Picture = PictureLib.AbortProcessing;
			Form.Items.DecorationIndentationOfState.Visible = True;
			
			Form.Items.ActionsToStop.Visible = True;
			If Form.ProcessingState = "Executing" Then
				Form.Items.ActionsToStop.Title = NStr("vi = 'Chờ tạm dừng';
														|ru = 'На паузу';
														|en = 'Pause'; fa = 'Pause';
														|it = 'На паузу';
														|pl = 'Pause';
														|tr = 'Duraklat'");
				If SubjectType = "DMDocument" Then
					ToolTip = NStr("vi = 'Dừng xử lý chứng từ';
									|ru = 'Поставить обработку документа на паузу';
									|en = 'Pause document processing'; fa = 'Pause document processing';
									|it = 'Поставить обработку документа на паузу';
									|pl = 'Pause document processing';
									|tr = 'Belge işlemeyi duraklat'");
				Else
					ToolTip = NStr("vi = 'Dừng xử lý cuộc họp';
									|ru = 'Поставить обработку мероприятия на паузу';
									|en = 'Pause event processing'; fa = 'Pause event processing';
									|it = 'Поставить обработку мероприятия на паузу';
									|pl = 'Pause event processing';
									|tr = 'Etkinlik işlemeyi duraklat'");
				EndIf;
				Form.Items.ActionsToStop.Picture = PictureLib.SignPause;
			ElsIf Form.ProcessingState = "Stopped" Then
				Form.Items.ActionsToStop.Title = NStr("vi = 'Tiếp tục';
														|ru = 'Продолжить';
														|en = 'Continue'; fa = 'ادامه';
														|it = 'Продолжить';
														|pl = 'Continue';
														|tr = 'Devam et'");
				Form.Items.DecorationIndentationOfState.Visible = True;
				If SubjectType = "DMDocument" Then
					ToolTip = NStr("vi = 'Tiếp tục xử lý chứng từ';
									|ru = 'Продолжить обработку документа';
									|en = 'Continue document processing'; fa = 'Continue document processing';
									|it = 'Продолжить обработку документа';
									|pl = 'Continue document processing';
									|tr = 'Belge işlemeye devam et'");
				Else
					ToolTip = NStr("vi = 'Tiếp tục xử lý cuộc họp';
									|ru = 'Продолжить обработку мероприятия';
									|en = 'Continue event processing'; fa = 'Continue event processing';
									|it = 'Продолжить обработку мероприятия';
									|pl = 'Continue event processing';
									|tr = 'Etkinlik işlemeye devam et'");
				EndIf;
				Form.Items.ActionsToStop.Picture = PictureLib.GenerateReport;
			EndIf;
			If TypeOf(Form.Items.ActionsSend) = Type("FormButton") Then
				Form.Commands[Form.Items.ActionsToStop.CommandName].ToolTip = ToolTip;
			Else
				Form.Items.ActionsToStop.ToolTip = ToolTip;
			EndIf;
			
		Else
			// A simple user cannot interrupt the process.
			Form.Items.ActionsSend.Visible = False;
			Form.Items.ActionsSend.Title = "";
			Form.Items.ActionsToStop.Visible = False;
			If TypeOf(Form.Items.ActionsSend) = Type("FormButton") Then
				Form.Commands[Form.Items.ActionsSend.CommandName].ToolTip =
					Form.Items.ActionsSend.Title;
			Else
				Form.Items.ActionsSend.ToolTip = Form.Items.ActionsSend.Title;
			EndIf;
		EndIf;
		
		If Form.ProcessingState = "Executing" Then
			Form.Items.DecorationOfState.Picture = PictureLib.GenerateReport;
			Form.Items.DetailsDecoration.Title = StrTemplate(NStr("vi = 'Đã bắt đầu xử lý %1';
																	|ru = 'Обработка начата %1';
																	|en = 'Processing is started on %1'; fa = 'Processing is started on %1';
																	|it = 'Обработка начата %1';
																	|pl = 'Processing is started on %1';
																	|tr = 'İşleme başlatıldı %1'"),
				FormattedDateOfProcessingEvent(ProcessingStartDate));
		ElsIf Form.ProcessingState = "Stopped" Then
			Form.Items.DecorationOfState.Picture = PictureLib.SignPause;
			Form.Items.DetailsDecoration.Title = StrTemplate(NStr("vi = 'Quá trình xử lý tạm dừng từ %1';
																	|ru = 'Обработка на паузе с %1';
																	|en = 'Processing is paused from %1'; fa = 'Processing is paused from %1';
																	|it = 'Обработка на паузе с %1';
																	|pl = 'Processing is paused from %1';
																	|tr = 'İşleme %1 ile duraklatıldı'"),
				FormattedDateOfProcessingEvent(DateOfChangeOfProcessingState));
		EndIf;
		Form.Items.DetailsDecoration.ToolTip = Form.Items.DetailsDecoration.Title;
		Form.Items.DecorationOfState.Visible = True;
		
	ElsIf Form.ProcessingState = "Completed" Then
		
		Form.Items.ActionsRestartProcessing.Visible = True;
		Form.Items.ActionsSend.Visible = False;
		
		Form.Items.DecorationOfState.Picture = PictureLib.AppearanceCheckBox;
		Form.Items.DetailsDecoration.Title = StrTemplate(NStr("vi = 'Đã kết thúc xử lý %1';
																|ru = 'Обработка завершена  %1';
																|en = 'Processing is completed on %1'; fa = 'Processing is completed on %1';
																|it = 'Обработка завершена  %1';
																|pl = 'Processing is completed on %1';
																|tr = 'İşleme tamamlandı  %1'"),
			FormattedDateOfProcessingEvent(DateOfChangeOfProcessingState));
		Form.Items.DetailsDecoration.ToolTip = Form.Items.DetailsDecoration.Title;
		Form.Items.DecorationOfState.Visible = True;
		
	EndIf;
	
	Form.Items.ActionsSend.Enabled = Not Form.ReadOnly And ASBS.StateAllowsProcessingToBegin;
	Form.Items.ActionsToStop.Enabled = Not Form.ReadOnly And ASBS.StateAllowsYouToStopProcessing;
	Form.Items.ActionsRestartProcessing.Enabled = Not Form.ReadOnly
		And ASBS.StateAllowsYouToRestartProcessing;
	
	Form.Items.ActionsToFillIn.Visible = ProcessingIsSetByRules;
	
	Form.Items.LaunchButtonGroup.Visible = True;
	Form.Items.ProcessingInterruptionInformationGroup.Visible = False;
	Form.Items.GroupInterruptedProcessing.Visible = False;
	
	If ValueIsFilled(EndDate) Then
		
		Form.Items.ProcessingInterruptionInformationGroup.Visible = True;
		Form.Items.ActionsLabelReasonForProcessingInterruption.AutoMaxWidth = False;
		BoldFont = StyleFonts.ImportantLabelFont;
		RowsArray = New Array;
		RowsArray.Add(New FormattedString(PictureLib.AbortProcessing));
		RowsArray.Add(New FormattedString(Chars.NBSp));
		RowsArray.Add(New FormattedString(NStr("vi = 'Đã ngắt xử lý:';
												|ru = 'Обработка прервана:';
												|en = 'Processing is terminated:'; fa = 'Processing is terminated:';
												|it = 'Обработка прервана:';
												|pl = 'Processing is terminated:';
												|tr = 'İşleme sonlandırıldı:'"), BoldFont));
		RowsArray.Add(New FormattedString(Chars.NBSp));
		RowsArray.Add(New FormattedString(FormattedDateOfProcessingEvent(EndDate)));
		RowsArray.Add(New FormattedString(Chars.LF));
		If ValueIsFilled(ReasonForInterruption) Then
			RowsArray.Add(New FormattedString(Chars.NBSp));
			RowsArray.Add(New FormattedString(NStr("vi = 'Lý do:';
													|ru = 'Причина:';
													|en = 'Reason:'; fa = 'دلیل:';
													|it = 'Причина:';
													|pl = 'Reason:';
													|tr = 'Sebep:'"), BoldFont));
			RowsArray.Add(New FormattedString(Chars.NBSp));
			RowsArray.Add(New FormattedString(ReasonForInterruption));
			RowsArray.Add(New FormattedString(Chars.LF));
		EndIf;
		Form.Items.ActionsLabelReasonForProcessingInterruption.Title = New FormattedString(RowsArray);
		If ValueIsFilled(Interrupted) Then
			Form.Items.GroupInterruptedProcessing.Visible = True;
			RowsArray = New Array;
			RowsArray.Add(New FormattedString(Chars.NBSp));
			RowsArray.Add(New FormattedString(NStr("vi = 'Đã ngắt:';
													|ru = 'Прервал:';
													|en = 'Terminated by:'; fa = 'خاتمه‌یافته توسط:';
													|it = 'Прервал:';
													|pl = 'Terminated by:';
													|tr = 'Sonlandırılan:'"), BoldFont));
			RowsArray.Add(New FormattedString(Chars.NBSp));
			RowsArray.Add(New FormattedString(Interrupted));
			Form.Items.ActionInscriptionInterrupted.Title = New FormattedString(RowsArray);
		EndIf;
		
	EndIf;
	
	Form.ValueToFormAttribute(ActionTree, "Actions");
	
	If NumberOfActions = 0 And Not ProcessingIsSetByRules And Not Form.Items.DetailsDecoration.Visible Then
		If SubjectType = "DMDocument" Then
			Template = NStr("vi = 'Đối với chứng từ dạng ""%1"", chưa thiết lập xử lý';
							|ru = 'Для документов вида ""%1"" обработка не настроена';
							|en = 'The data processor is not configured for documents of the %1 kind'; fa = 'The data processor is not configured for documents of the %1 kind';
							|it = 'Для документов вида ""%1"" обработка не настроена';
							|pl = 'The data processor is not configured for documents of the %1 kind';
							|tr = '""%1"" belge türü için işleme ayarlanmadı'");
		Else
			Template = NStr("vi = 'Đối với cuộc họp dạng ""%1"", chưa thiết lập xử lý';
							|ru = 'Для мероприятий вида ""%1"" обработка не настроена';
							|en = 'The data processor is not configured for events of the %1 kind'; fa = 'The data processor is not configured for events of the %1 kind';
							|it = 'Для мероприятий вида ""%1"" обработка не настроена';
							|pl = 'The data processor is not configured for events of the %1 kind';
							|tr = '""%1"" etkinlik türü için işleme ayarlanmadı'");
		EndIf;
		Form.Items.DecorationOfState.Visible = True;
		Form.Items.DecorationOfState.Picture = PictureLib.Information;
		Form.Items.DetailsDecoration.Visible = True;
		Form.Items.DetailsDecoration.HorizontalStretch = True;
		Form.Items.DetailsDecoration.Title = StrTemplate(Template, Form.ObjectKindBefore);
		Form.Items.DetailsDecoration.ToolTip = Form.Items.DetailsDecoration.Title;
	EndIf;
	
EndProcedure

// Returns a request to complete the processing.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   DataProcessorData - See IntegrationWith1CDocumentManagement3ClientServer.DataProcessorData
//
// Returns:
//   XDTODataObject - an XDTO object of the DMFillProcessingRequest type.
//
Function FillInProcessingRequest(Proxy, DataProcessorData) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMFillProcessingRequest");
	
	Query.object = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DataProcessorData.SubjectOfID,
		DataProcessorData.SubjectOfType);
	
	Return Query;
	
EndFunction

// Returns a request to start processing.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   DataProcessorData - See IntegrationWith1CDocumentManagement3ClientServer.DataProcessorData
//   ExternalObject - AnyRef - reference to the IP object.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMStartProcessingRequest type.
//
Function StartProcessingRequest(Proxy, DataProcessorData, ExternalObject = Undefined) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMStartProcessingRequest");
	
	Query.object = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DataProcessorData.SubjectOfID,
		DataProcessorData.SubjectOfType);
	
	If IntegrationWith1CDocumentManagementCore.PropertyExists(Query, "link")
			And ValueIsFilled(ExternalObject) Then
		Query.link = IntegrationWith1CDocumentManagementCore.CreateDMLink(
			Proxy,
			DataProcessorData.SubjectOfID,
			DataProcessorData.SubjectOfType,
			ExternalObject);
	EndIf;
	
	Return Query;
	
EndFunction

// Checks whether it is possible to start processing an object of the specified type.
//
// Parameters:
//   XDTOObjectType - String - object type.
//
// Returns:
//   Boolean
//
Function DMObjectSupportsProcessing(XDTOObjectType) Export
	
	ObjectsWithProcessingSupport = New Array;
	ObjectsWithProcessingSupport.Add("DMMeeting");
	
	Return IsDocumentBefore3(XDTOObjectType) Or ObjectsWithProcessingSupport.Find(XDTOObjectType) <> Undefined;
	
EndFunction

// Returns a request to stop processing.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   DataProcessorData - See IntegrationWith1CDocumentManagement3ClientServer.DataProcessorData
//
// Returns:
//   XDTODataObject - an XDTO object of the DMStopContinueProcessingRequest type.
//
Function StopProcessingRequest(Proxy, DataProcessorData) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMStopContinueProcessingRequest");
	
	Query.objectProcessingState = "Stopped";
	Query.object = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DataProcessorData.SubjectOfID,
		DataProcessorData.SubjectOfType);
	
	Return Query;
	
EndFunction

// Returns a request to restart processing.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   DataProcessorData - See IntegrationWith1CDocumentManagement3ClientServer.DataProcessorData
//
// Returns:
//   XDTODataObject - an XDTO object of the DMRestartProcessingRequest type.
//
Function RestartRequestProcessing(Proxy, DataProcessorData) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMRestartProcessingRequest");
	
	Query.object = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DataProcessorData.SubjectOfID,
		DataProcessorData.SubjectOfType);
	
	Return Query;
	
EndFunction

// Returns a request to interrupt processing.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   DataProcessorData - See IntegrationWith1CDocumentManagement3ClientServer.DataProcessorData
//
// Returns:
//   XDTODataObject - an XDTO object of the DMTerminateProcessingRequest type.
//
Function AbortRequestProcessing(Proxy, DataProcessorData) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMTerminateProcessingRequest");
	
	Query.terminationReason = DataProcessorData.ReasonForInterruption;
	Query.object = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DataProcessorData.SubjectOfID,
		DataProcessorData.SubjectOfType);
	
	Return Query;
	
EndFunction

// Returns a request to continue processing.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   DataProcessorData - See IntegrationWith1CDocumentManagement3ClientServer.DataProcessorData
//
// Returns:
//   XDTODataObject - an XDTO object of the DMStopContinueProcessingRequest type.
//
Function ContinueProcessingRequest(Proxy, DataProcessorData) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMStopContinueProcessingRequest");
	
	Query.objectProcessingState = "Executing";
	Query.object = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		DataProcessorData.SubjectOfID,
		DataProcessorData.SubjectOfType);
	
	Return Query;
	
EndFunction

// Returns a request to 1C:Document flow to receive the Cur processing of the object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ID - String - id of the XDTO object.
//   Type - String - type of the XDTO object.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMGetCurrentObjectProcessingRequest type.
//
Function CurProcessingOfRequestObject(Proxy, ID, Type) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMGetCurrentObjectProcessingRequest");
	Query.target = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, ID, Type);
	
	Return Query;
	
EndFunction

#EndRegion

#Region Actions

// Returns child participants of the action.
//
// Parameters:
//   Attendees - XDTOList - list of participants in the action.
//   ParentID - String - ID of the upstream member.
//
// Returns:
//   Array of XDTODataObject
//
Function ChildParticipantsOfAction(Attendees, ParentID) Export
	
	ChildMembers = New Array;
	
	For Each ParticipantLine In Attendees Do
		If ParticipantLine.higherLevelParticipant = ParentID Then
			ChildMembers.Add(ParticipantLine);
		EndIf;
	EndDo;
	
	Return ChildMembers;
	
EndFunction

// Fills in the action States of specific participants in the action form.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   XDTOAction - XDTODataObject - an XDTO object of the type inheriting DMAction.
//
Procedure FillInStatesAndResultsInActionForm(Form, XDTOAction) Export
	
	Items = Form.Items;
	If Form.DialogMode Then
		Items.AttendeesPictureNumber.Visible = False;
		Return;
	EndIf;
	
	AllStatesAndResults = AllStatesAndResults(XDTOAction);
	
	If AllStatesAndResults.Count() = 0 Then
		Items.AttendeesPictureNumber.Visible = False;
		Return;
	EndIf;
	
	// Setting States and results.
	StringsToProcess = New Array;
	
	For Each ParticipantLine In Form.Attendees.GetItems() Do
		StringsToProcess.Add(ParticipantLine.GetID());
		For Each SubordinateRow In ParticipantLine.GetItems() Do
			StringsToProcess.Add(SubordinateRow.GetID());
			For Each ProvidingString In SubordinateRow.GetItems() Do
				StringsToProcess.Add(ProvidingString.GetID());
			EndDo;
		EndDo;
	EndDo;
	
	// Results and pictures of performers.
	DateOfInstallationOfStatesByParticipants = New Map();
	
	For Each RowID In StringsToProcess Do
		
		String = Form.Attendees.FindByID(RowID);
		If String.ThisIsAStep Then
			Continue;
		EndIf;
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("Action", XDTOAction.name);
		FilterStructure1.Insert("ActionID", XDTOAction.objectID.ID);
		FilterStructure1.Insert("ActionType", XDTOAction.objectID.type);
		FilterStructure1.Insert("Function", String.Function);
		FilterStructure1.Insert("ParticipantID", String.Id);
		FoundRows = AllStatesAndResults.FindRows(FilterStructure1);
		
		If FoundRows.Count() = 0 And ValueIsFilled(String.MemberID) Then
			FilterStructure1 = New Structure;
			FilterStructure1.Insert("Action", XDTOAction.name);
			FilterStructure1.Insert("ActionID", XDTOAction.objectID.ID);
			FilterStructure1.Insert("ActionType", XDTOAction.objectID.type);
			FilterStructure1.Insert("ParticipantID", String.MemberID);
			FoundRows = AllStatesAndResults.FindRows(FilterStructure1);
		EndIf;
		
		If FoundRows.Count() > 0 Then
			FoundRow = FoundRows[0];
			String.Result = FoundRow.Result;
			String.State = FoundRow.State;
			String.PictureNumber = IntegrationWith1CDocumentManagement3ClientServer.NumberOfImageOfResultOfAction(
				String.Result,
				String.State);
			
			DateOfInstallationOfStatesByParticipants[FoundRow.ParticipantID] = FoundRow.Date;
		EndIf;
		
	EndDo;
	
	// The date when the action State was set.
	DateWhenActionStateWasSet = Date(1, 1, 1);
	StateOfAction = "";
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Action", XDTOAction.name);
	FilterStructure1.Insert("ActionID", XDTOAction.objectID.ID);
	FilterStructure1.Insert("ActionType", XDTOAction.objectID.type);
	FilterStructure1.Insert("Function", "");
	FilterStructure1.Insert("ParticipantID", "");
	FilterStructure1.Insert("Point_Id", "00000000-0000-0000-0000-000000000000");
	FoundRows = AllStatesAndResults.FindRows(FilterStructure1);
	
	If FoundRows.Count() > 0 Then
		DateWhenActionStateWasSet = FoundRows[0].Date;
		StateOfAction = FoundRows[0].State;
	EndIf;
	
	// Results and pictures of stages based on the results of performers.
	For Each RowID In StringsToProcess Do
		
		String = Form.Attendees.FindByID(RowID);
		If Not String.ThisIsAStep Then
			Continue;
		EndIf;
		
		OverallState = Undefined;
		CommonResult = Undefined;
		
		SubordinateRows = String.GetItems();
		For Each SubordinateRow In SubordinateRows Do
			DateStateWasSet = DateOfInstallationOfStatesByParticipants[SubordinateRow.Id];
			
			If StateOfAction = "Completed"
					And ValueIsFilled(DateStateWasSet)
					And ValueIsFilled(DateWhenActionStateWasSet)
					And DateStateWasSet > DateWhenActionStateWasSet Then
				Continue;
			EndIf;
			
			CommonResult = IntegrationWith1CDocumentManagement3ClientServer.OverallResultOfAction(
				CommonResult,
				SubordinateRow.Result);
			OverallState = IntegrationWith1CDocumentManagement3ClientServer.GeneralStateOfAction(
				OverallState,
				SubordinateRow.State);
		EndDo;
		
		String.State = OverallState;
		String.Result = ?(OverallState = "Performing",
			Undefined,
			CommonResult);
		
		String.PictureNumber = IntegrationWith1CDocumentManagement3ClientServer.NumberOfImageOfResultOfAction(
			String.Result,
			OverallState);
		
	EndDo;
	
	// Display of the start delay.
	If Items.Find("GroupDescriptionOfDeferredExecution") <> Undefined
			And Items.GroupDescriptionOfDeferredExecution.Visible = True
			And ValueIsFilled(StateOfAction) Then
		If StateOfAction = "DelayedStart" Then
			IntegrationWith1CDocumentManagement3ClientServer.ConfigureDisplayOfDelayedStartOfAction(
				Form,
				Form.LaunchPresentation,
				Form.Commands.ClearDelay.ToolTip,
				Form.Items.DescriptionOfDelayedStartOfExecution.ToolTip);
		Else
			Items.GroupDescriptionOfDeferredExecution.Visible = False;
		EndIf;
	EndIf;
	
	If Items.Find("FlagSettingsGroup") <> Undefined And ValueIsFilled(StateOfAction) Then
		Items.FlagSettingsGroup.Enabled = False;
	EndIf;
	
EndProcedure

// Fills in the action participant line XDTO from the value tree line Participants in the action form.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTORow - XDTODataObject - an XDTO object of the type inheriting DMActionParticipantRow.
//   ParticipantLine - FormDataTreeItem - a row of the value tree of Participants in the Form of an action.
//
Procedure FillInXDTOLineFromActionParticipant(Proxy, XDTORow, ParticipantLine) Export
	
	ParticipantStringStructure = ParticipantStringStructure();
	FillPropertyValues(ParticipantStringStructure, ParticipantLine);
	
	// Properties of the DMActionParticipantRow object.
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "participant")
			And ValueIsFilled(ParticipantStringStructure.MemberID) Then
		Member = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			ParticipantStringStructure.MemberID,
			ParticipantStringStructure.MemberType,
			ParticipantStringStructure.Member);
		DataMainObjectOfAddressingParticipant =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				ParticipantStringStructure.MainAddressingObjectMemberID,
				ParticipantStringStructure.MainAddressingObjectMemberType,
				ParticipantStringStructure.MainAddressingObjectMember);
		DataAdditionalAddressingObjectParticipant =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				ParticipantStringStructure.AdditionalAddressingObjectParticipantID,
				ParticipantStringStructure.AdditionalAddressingObjectParticipantType,
				ParticipantStringStructure.AdditionalAddressingObjectParticipant);
		XDTORow.participant = ParticipantOfXDTOAction(
			Proxy,
			Member,
			DataMainObjectOfAddressingParticipant,
			DataAdditionalAddressingObjectParticipant);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "id")
			And ParticipantStringStructure.Id <> Undefined Then
		XDTORow.id = ParticipantStringStructure.Id;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "description")
			And ParticipantStringStructure.LongDesc <> Undefined Then
		XDTORow.description = ParticipantStringStructure.LongDesc;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "detailsSpecial")
			And ParticipantStringStructure.DescriptionIsSpecial <> Undefined Then
		XDTORow.detailsSpecial = ParticipantStringStructure.DescriptionIsSpecial;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "dueDate")
			And ParticipantStringStructure.DueDate <> Undefined Then
		XDTORow.dueDate = ParticipantStringStructure.DueDate;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "dueDateDays")
			And ParticipantStringStructure.Term_Days <> Undefined Then
		XDTORow.dueDateDays = ParticipantStringStructure.Term_Days;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "dueDateHours")
			And ParticipantStringStructure.TermHours <> Undefined Then
		XDTORow.dueDateHours = ParticipantStringStructure.TermHours;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "dueDateMinutes")
			And ParticipantStringStructure.TermMinutes <> Undefined Then
		XDTORow.dueDateMinutes = ParticipantStringStructure.TermMinutes;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "fromSettings")
			And ParticipantStringStructure.FromSettings <> Undefined Then
		XDTORow.fromSettings = ParticipantStringStructure.FromSettings;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "protected")
			And ParticipantStringStructure.IsProtected <> Undefined Then
		XDTORow.protected = ParticipantStringStructure.IsProtected;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "protectedInSettings")
			And ParticipantStringStructure.ProtectedInSetting <> Undefined Then
		XDTORow.protectedInSettings = ParticipantStringStructure.ProtectedInSetting;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "dueDateSpecificationVariant")
			And ParticipantStringStructure.OptionForSettingDeadline <> Undefined
			And ValueIsFilled(ParticipantStringStructure.OptionForSettingDeadline) Then
		// Enumeration.
		XDTORow.dueDateSpecificationVariant = ParticipantStringStructure.OptionForSettingDeadline;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "dueDatePresentation")
			And ParticipantStringStructure.DueDatePresentation <> Undefined Then
		XDTORow.dueDatePresentation = ParticipantStringStructure.DueDatePresentation;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "presentation")
			And ParticipantStringStructure.LinePresentation <> Undefined Then
		XDTORow.presentation = ParticipantStringStructure.LinePresentation;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "condition")
			And ParticipantStringStructure.ConditionID <> Undefined Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			ParticipantStringStructure,
			"Condition",
			XDTORow.condition);
	EndIf;
	
	// Properties of the heirs of the DMActionParticipantRow object.
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "stageID")
			And ParticipantStringStructure.StageID <> Undefined Then
		XDTORow.stageID = ParticipantStringStructure.StageID;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "pointID")
			And ParticipantStringStructure.Point_Id <> Undefined Then
		XDTORow.pointID = ParticipantStringStructure.Point_Id;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "higherLevelParticipant")
			And ParticipantStringStructure.SuperiorMember <> Undefined Then
		XDTORow.higherLevelParticipant = ParticipantStringStructure.SuperiorMember;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "dueDateTotal")
			And ParticipantStringStructure.TermIsGeneral <> Undefined Then
		XDTORow.dueDateTotal = ParticipantStringStructure.TermIsGeneral;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "taskDescription")
			And ParticipantStringStructure.TaskDescription <> Undefined Then
		XDTORow.taskDescription = ParticipantStringStructure.TaskDescription;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "resolutionDraft")
			And ParticipantStringStructure.ProjectResolution <> Undefined Then
		XDTORow.resolutionDraft = ParticipantStringStructure.ProjectResolution;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "resolutionExist")
			And ParticipantStringStructure.ThereIsResolution <> Undefined Then
		XDTORow.resolutionExist = ParticipantStringStructure.ThereIsResolution;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "resolutionPresentation")
			And ParticipantStringStructure.PresentationOfResolution <> Undefined Then
		XDTORow.resolutionPresentation = ParticipantStringStructure.PresentationOfResolution;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "resolutionProcessingDate")
			And ParticipantStringStructure.ResolutionProcessingTime <> Undefined Then
		XDTORow.resolutionProcessingDate = ParticipantStringStructure.ResolutionProcessingTime;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "resolutionProcessingDateDays")
			And ParticipantStringStructure.DeadlineForProcessingResolutionIsDays <> Undefined Then
		XDTORow.resolutionProcessingDateDays = ParticipantStringStructure.DeadlineForProcessingResolutionIsDays;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "resolutionProcessingDateHours")
			And ParticipantStringStructure.ResolutionProcessingTimeHours <> Undefined Then
		XDTORow.resolutionProcessingDateHours = ParticipantStringStructure.ResolutionProcessingTimeHours;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "resolutionProcessingDateMinutes")
			And ParticipantStringStructure.ProcessingTimeOfResolutionIsMinutes <> Undefined Then
		XDTORow.resolutionProcessingDateMinutes = ParticipantStringStructure.ProcessingTimeOfResolutionIsMinutes;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "resolutionProcessingDatePresentation") 
			And ParticipantStringStructure.ResolutionProcessingTimePresentation <> Undefined Then
		XDTORow.resolutionProcessingDatePresentation = ParticipantStringStructure.ResolutionProcessingTimePresentation;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "resolutionProcessingDateSpecificationVariant") 
			And ParticipantStringStructure.OptionForSettingResolutionProcessingTime <> Undefined
			And ValueIsFilled(ParticipantStringStructure.OptionForSettingResolutionProcessingTime) Then
		// Enumeration.
		XDTORow.resolutionProcessingDateSpecificationVariant = ParticipantStringStructure.OptionForSettingResolutionProcessingTime;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "responsible")
			And ParticipantStringStructure.EmployeeResponsible <> Undefined Then
		XDTORow.responsible = ParticipantStringStructure.EmployeeResponsible;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "participantFunction")
			And ParticipantStringStructure.ParticipantFunction <> Undefined
			And ValueIsFilled(ParticipantStringStructure.ParticipantFunction) Then
		// Enumeration.
		XDTORow.participantFunction = ParticipantStringStructure.ParticipantFunction;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "number")
			And ParticipantStringStructure.Number <> Undefined Then
		XDTORow.number = ParticipantStringStructure.Number;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "dataSource")
			And ParticipantStringStructure.DataSourceID <> Undefined Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			ParticipantStringStructure,
			"DataSource",
			XDTORow.dataSource);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "controller")
			And ValueIsFilled(ParticipantStringStructure.InspectorID) Then
		Inspector = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			ParticipantStringStructure.InspectorID,
			ParticipantStringStructure.InspectorType,
			ParticipantStringStructure.Inspector);
		DataIsMainObjectOfAddressingController =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				ParticipantStringStructure.MainAddressingObjectInspectorID,
				ParticipantStringStructure.MainAddressingObjectInspectorType,
				ParticipantStringStructure.MainAddressingObjectInspector);
		DataAdditionalAddressingObjectController =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				ParticipantStringStructure.AdditionalAddressingObjectControllerID,
				ParticipantStringStructure.AdditionalAddressingObjectControllerType,
				ParticipantStringStructure.AdditionalAddressingObjectController);
		XDTORow.controller = ParticipantOfXDTOAction(
			Proxy,
			Inspector,
			DataIsMainObjectOfAddressingController,
			DataAdditionalAddressingObjectController);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "author")
			And ValueIsFilled(ParticipantStringStructure.AuthorID) Then
		Author = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			ParticipantStringStructure.AuthorID,
			ParticipantStringStructure.AuthorType,
			ParticipantStringStructure.Author);
		XDTORow.author = ParticipantOfXDTOAction(Proxy, Author);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "organization")
			And ParticipantStringStructure.OrganizationID <> Undefined Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			ParticipantStringStructure,
			"Organization",
			XDTORow.organization);
	EndIf;
	
	// Properties of the heirs of the DMActionStageRow object.
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "rankFrom")
			And ParticipantStringStructure.GradeC <> Undefined Then
		XDTORow.rankFrom = ParticipantStringStructure.GradeC;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "rankTo")
			And ParticipantStringStructure.RankBy <> Undefined Then
		XDTORow.rankTo = ParticipantStringStructure.RankBy;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTORow, "orderOfExecutionByParticipants")
			And ParticipantStringStructure.OrderOfExecutionByParticipants <> Undefined
			And ValueIsFilled(ParticipantStringStructure.OrderOfExecutionByParticipants) Then
		// Enumeration.
		XDTORow.orderOfExecutionByParticipants = ParticipantStringStructure.OrderOfExecutionByParticipants;
	EndIf;
	
EndProcedure

// Fills in a row of the Participants value tree in the action form.
//
// Parameters:
//   ParticipantLine - FormDataTreeItem - a row of the value tree of Participants in the Form of an action.
//   XDTORow - XDTODataObject - an XDTO object of the type inheriting DMActionParticipantRow.
//
Procedure FillInActionParticipantLineFromXDTO(ParticipantLine, XDTORow) Export
	
	ParticipantStringStructure = ParticipantStringStructure();
	
	// Properties of the DMActionParticipantRow object.
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "participant") Then
		ParticipantOfActionDM(ParticipantStringStructure, XDTORow.participant, "Member");
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "id") Then
		ParticipantStringStructure.Id = XDTORow.id;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "description") Then
		ParticipantStringStructure.LongDesc = XDTORow.description;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "detailsSpecial") Then
		ParticipantStringStructure.DescriptionIsSpecial = XDTORow.detailsSpecial;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "dueDate") Then
		ParticipantStringStructure.DueDate = XDTORow.dueDate;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "dueDateDays") Then
		ParticipantStringStructure.Term_Days = XDTORow.dueDateDays;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "dueDateHours") Then
		ParticipantStringStructure.TermHours = XDTORow.dueDateHours;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "dueDateMinutes") Then
		ParticipantStringStructure.TermMinutes = XDTORow.dueDateMinutes;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "fromSettings") Then
		ParticipantStringStructure.FromSettings = XDTORow.fromSettings;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "protected") Then
		ParticipantStringStructure.IsProtected = XDTORow.protected;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "protectedInSettings") Then
		ParticipantStringStructure.ProtectedInSetting = XDTORow.protectedInSettings;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "dueDateSpecificationVariant") Then
		ParticipantStringStructure.OptionForSettingDeadline = XDTORow.dueDateSpecificationVariant;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "dueDatePresentation") Then
		ParticipantStringStructure.DueDatePresentation = XDTORow.dueDatePresentation;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "presentation") Then
		ParticipantStringStructure.LinePresentation = XDTORow.presentation;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "condition") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			ParticipantStringStructure,
			XDTORow.condition,
			"Condition",
			True);
	EndIf;
	
	// Properties of the heirs of the DMActionParticipantRow object.
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "stageID") Then
		ParticipantStringStructure.StageID = XDTORow.stageID;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "pointID") Then
		ParticipantStringStructure.Point_Id = XDTORow.pointID;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "higherLevelParticipant") Then
		ParticipantStringStructure.SuperiorMember = XDTORow.higherLevelParticipant;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "dueDateTotal") Then
		ParticipantStringStructure.TermIsGeneral = XDTORow.dueDateTotal;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "taskDescription") Then
		ParticipantStringStructure.TaskDescription = XDTORow.taskDescription;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "resolutionDraft") Then
		ParticipantStringStructure.ProjectResolution = XDTORow.resolutionDraft;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "resolutionExist") Then
		ParticipantStringStructure.ThereIsResolution = XDTORow.resolutionExist;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "resolutionPresentation") Then
		ParticipantStringStructure.PresentationOfResolution = XDTORow.resolutionPresentation;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "resolutionProcessingDate") Then
		ParticipantStringStructure.ResolutionProcessingTime = XDTORow.resolutionProcessingDate;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "resolutionProcessingDateDays") Then
		ParticipantStringStructure.DeadlineForProcessingResolutionIsDays = XDTORow.resolutionProcessingDateDays;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "resolutionProcessingDateHours") Then
		ParticipantStringStructure.ResolutionProcessingTimeHours = XDTORow.resolutionProcessingDateHours;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "resolutionProcessingDateMinutes") Then
		ParticipantStringStructure.ProcessingTimeOfResolutionIsMinutes = XDTORow.resolutionProcessingDateMinutes;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "resolutionProcessingDatePresentation") Then
		ParticipantStringStructure.DueDatePresentation = XDTORow.resolutionProcessingDatePresentation;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "resolutionProcessingDateSpecificationVariant") Then
		ParticipantStringStructure.OptionForSettingResolutionProcessingTime = XDTORow.resolutionProcessingDateSpecificationVariant;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "responsible") Then
		ParticipantStringStructure.EmployeeResponsible = XDTORow.responsible;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "participantFunction") Then
		ParticipantStringStructure.ParticipantFunction = XDTORow.participantFunction;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "number") Then
		ParticipantStringStructure.Number = XDTORow.number;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "dataSource") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			ParticipantStringStructure,
			XDTORow.dataSource,
			"DataSource",
			True);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "controller") Then
		ParticipantOfActionDM(ParticipantStringStructure, XDTORow.controller, "Inspector");
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "author") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			ParticipantStringStructure,
			XDTORow.author,
			"Author",
			True);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "organization") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			ParticipantStringStructure,
			XDTORow.organization,
			"Organization");
	EndIf;
	
	// Properties of the heirs of the DMActionStageRow object.
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "rankFrom") Then
		ParticipantStringStructure.GradeC = XDTORow.rankFrom;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "rankTo") Then
		ParticipantStringStructure.RankBy = XDTORow.rankTo;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "orderOfExecutionByParticipants") Then
		ParticipantStringStructure.OrderOfExecutionByParticipants = XDTORow.orderOfExecutionByParticipants;
	EndIf;
	
	FillPropertyValues(ParticipantLine, ParticipantStringStructure);
	
EndProcedure

// Fills in the table of participants of the action from the XDTO object.
//
// Parameters:
//   TableOfParticipants - ValueTable:
//     * MemberID - String
//     * MemberType - String
//     * MainAddressingObjectMemberID - String
//     * MainAddressingObjectMemberType - String
//     * AdditionalAddressingObjectParticipantID - String
//     * AdditionalAddressingObjectParticipantType - String
//     * Id - String
//   XDTOAction - XDTODataObject - an XDTO object of the type inheriting DMAction.
//
Procedure FillInTableOfParticipantsInAction(TableOfParticipants, XDTOAction) Export
	
	TableOfParticipants.Clear();
	For Each XDTORow In XDTOAction.participantRows.rows Do
		FillInActionParticipantLineFromXDTO(TableOfParticipants.Add(), XDTORow);
	EndDo;
	
EndProcedure

// The handler that is called after receiving the data BEFORE in the Form of the action.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   XDTOAction - XDTODataObject - an XDTO object of the type inheriting DMAction.
//
Procedure ProcessWebServiceSResponseToReceivingAction(Form, XDTOAction) Export
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(Form, XDTOAction);
	
	FillInTheseActions(Form, XDTOAction.form, XDTOAction.changeAllowed, XDTOAction.permissionRows.rows);
	
	Form.Items.AdvancedGroup.ReadOnly = Not XDTOAction.changeAllowed
		Or Form.Items.GroupIsNotAvailableForModification.Visible;
	
	Form.MomentOfDereferenceOfParticipants = XDTOAction.participantsDereferenceMoment;
	Form.ExecutionOfActionWithNewParticipants = XDTOAction.actionPerformedWithNewParticipants;
	If Form.DelayedStartOfExecutionSettingIsAvailable Then
		Form.DeferredExecutionDate = XDTOAction.delayedExecutionDate;
	EndIf;
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		Form,
		XDTOAction.author,
		"Author",
		True);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		Form,
		XDTOAction.actionSettings,
		"SettingOfAction");
	If Form.MainSubjectID = ""
			And IntegrationWith1CDocumentManagementCore.PropertySet(XDTOAction, "target") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			Form,
			XDTOAction.target,
			"MainSubject");
	EndIf;
	
	FillInTableOfParticipantsInAction(Form.ParticipantsAtOpening, XDTOAction);
	
EndProcedure

// Generates an XDTO object to be recorded in the Workflow based on data from the action Form.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
// Returns:
//   XDTODataObject - an XDTO object of the type inheriting DMAction.
//
Function PrepareActionForRecording(Proxy, Form) Export
	
	XDTOAction = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Form.Type);
	XDTOAction.name = "";
	XDTOAction.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Form.ID,
		Form.Type);
	
	If ValueIsFilled(Form.AuthorPresentation) Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy, Form, "Author", XDTOAction.author, "DMEmployee");
	EndIf;
	
	If ValueIsFilled(Form.MomentOfDereferenceOfParticipants) Then
		XDTOAction.participantsDereferenceMoment = Form.MomentOfDereferenceOfParticipants;
	EndIf;
	
	XDTOAction.actionPerformedWithNewParticipants = Form.ExecutionOfActionWithNewParticipants;
	
	If Form.DelayedStartOfExecutionSettingIsAvailable Then
		XDTOAction.delayedExecutionDate = Form.DeferredExecutionDate;
		XDTOAction.form = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMActionForm");
		XDTOAction.form.delayedExecutionStartDays = Form.DelayedStartOfExecutionDays;
		XDTOAction.form.delayedExecutionStartHours = Form.DelayedStartOfExecutionHours;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTOAction, "dialogueMode") Then
		XDTOAction.dialogueMode = Form.DialogMode;
	EndIf;
	
	Return XDTOAction;
	
EndFunction

// The hint of the "Different deadlines" button in some Forms of actions.
//
// Parameters:
//   ByPoints - Boolean - the action is performed point by point.
//   ByStages - Boolean - the action is performed in stages.
//
// Returns:
//   String - hint.
//
Function HintButtonsHaveDifferentExpirationDates(ByPoints, ByStages) Export
	
	Refinement = "";
	If ByPoints Then
		Refinement = NStr("vi = ', trong giới hạn của mục,';
							|ru = ', в пределах пункта,';
							|en = ', within the point,'; fa = ', within the point,';
							|it = ', в пределах пункта,';
							|pl = ', within the point,';
							|tr = ', nokta içinde,'")
	ElsIf ByStages Then
		Refinement = NStr("vi = ', trong giới hạn của mục,';
							|ru = ', в пределах этапа,';
							|en = ', within the stage,'; fa = ', within the stage,';
							|it = ', в пределах этапа,';
							|pl = ', within the stage,';
							|tr = ', aşama içinde,'")
	EndIf;
	
	Return StrTemplate(
		NStr("vi = 'Nếu đã bật sử dụng thì có thể chỉ ra thời hạn riêng ở mỗi người tham gia %1';
			|ru = 'Если включен, то у каждого участника%1 можно указать свой срок';
			|en = 'If enabled, you can specify a separate due date for every %1 participant'; fa = 'If enabled, you can specify a separate due date for every %1 participant';
			|it = 'Если включен, то у каждого участника%1 можно указать свой срок';
			|pl = 'If enabled, you can specify a separate due date for every %1 participant';
			|tr = 'Etkinleştirilirse, her %1 katılımcısının kendi vadesi belirtilebilir'"), Refinement);
	
EndFunction

// The event handler is attached to the action Form server.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   Parameters - Structure - the structure of the Form parameters of the action:
//     * ID - String
//     * type - String
//     * MainSubject - String
//     * MainSubjectID - String
//     * MainSubjectType - String
//
Procedure WhenCreatingActionFormOnServer(Form, Parameters) Export
	
	If Parameters.Property("DialogMode") Then
		Form.DialogMode = Parameters.DialogMode;
	EndIf;
	
	Form.ID = Parameters.ID;
	Form.Type = Parameters.type;
	
	Form.MainSubject = Parameters.MainSubject;
	Form.MainSubjectID = Parameters.MainSubjectID;
	Form.MainSubjectType = Parameters.MainSubjectType;
	
	AttributesToBeAdded = New Array;
	
	AttributesToBeAdded.Add(New FormAttribute(
		"ParticipantsAtOpening",
		New TypeDescription("ValueTable"),,
		NStr("vi = 'Người tham gia khi mở';
			|ru = 'Участники при открытии';
			|en = 'Participants on opening'; fa = 'Participants on opening';
			|it = 'Участники при открытии';
			|pl = 'Participants on opening';
			|tr = 'Açılıştaki katılımcılar'")));
	AttributesToBeAdded.Add(New FormAttribute(
		"AttendeesBeforeWrite",
		New TypeDescription("ValueTable"),,
		NStr("vi = 'Người tham gia trước khi ghi';
			|ru = 'Участники перед записью';
			|en = 'Participants before writing'; fa = 'Participants before writing';
			|it = 'Участники перед записью';
			|pl = 'Participants before writing';
			|tr = 'Kayıt öncesi katılımcılar'")));
	TableFields = StrSplit(IntegrationWith1CDocumentManagement3ClientServer.FieldNamesOfActionParticipantsTable(), ",");
	For Each FieldName In TableFields Do
		AttributesToBeAdded.Add(New FormAttribute(
			FieldName,
			New TypeDescription("String"),
			"ParticipantsAtOpening"));
		AttributesToBeAdded.Add(New FormAttribute(
			FieldName,
			New TypeDescription("String"),
			"AttendeesBeforeWrite"));
	EndDo;
	
	Form.ChangeAttributes(AttributesToBeAdded);
	
	Form.DelayedStartOfExecutionSettingIsAvailable =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.14.31");
	
EndProcedure

// Sets the visibility of the Command of the direction of action with new participants.
// In 1C:Document flow corresponds to the action of the server.Set the visibility of the direction of new participants.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   StateOfAction - String - an XDTO enumeration of the DMActionExecutionState type.
//   Permissions - XDTOList - a list of XDTO of the DMActionPermissionRows type.
//
Procedure EstablishVisibilityOfDirectionToNewParticipantsOfAction(Form, StateOfAction, Permissions) Export
	
	SendToNewMembers = False;
	
	If Not Form.ExecutionOfActionWithNewParticipants
			And (StateOfAction = "Completed" Or StateOfAction = "Skipped") Then
		
		ThereIsPermissionToChange = False;
		For Each PermissionRow In Permissions Do
			If PermissionRow.permission = "Allowed" Then
				ThereIsPermissionToChange = True;
				Break;
			EndIf;
		EndDo;
		
		If ThereIsPermissionToChange Then
			SendToNewMembers = True;
		EndIf;
		
	EndIf;
	
	Form.Items.SendToNewMembers.Visible = SendToNewMembers;
	
EndProcedure

// Sets the visibility of the "Condition" column if there are participants with conditions in the action.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   XDTOAction - XDTODataObject - an XDTO object of the type inheriting DMAction.
//
Procedure EstablishVisibilityOfConditionsOfParticipantsInAction(Form, XDTOAction) Export
	
	ThereAreConditions = False;
	
	If XDTOAction.participantsDereferenceMoment <> "WhenFillingOutProcessing" Then
		For Each MemberString In XDTOAction.participantRows.rows Do
			If IntegrationWith1CDocumentManagementCore.PropertySet(MemberString, "condition")
					And ValueIsFilled(MemberString.condition.objectID.ID) Then
				ThereAreConditions = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Form.Items.AttendeesConditionPresentation.Visible = ThereAreConditions;
	
EndProcedure

// Sets the View Only flag on the Form if the action doesn't have permission to change it.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   Permissions - ValueTable - permission table:
//     * StageID - String
//     * Resolution - String
//
Procedure SetAvailabilityOfChangeOfParticipantsOfAction(Form, Permissions) Export
	
	If Form.ReadOnly = True Then
		Return;
	EndIf;
	
	GeneralResolution = Undefined;
	If Permissions.Count() > 0 Then
		GeneralResolution = Permissions[0].Resolution;
	EndIf;
	
	Form.ReadOnly = (Form.ReadOnly Or GeneralResolution = "Forbidden")
		And Not Form.YouCanOnlyAddMembers;
	
	Form.Items.GroupDescriptionOfDeferredExecution.Enabled = Not Form.ReadOnly;
	
EndProcedure

// Generates an XDTO object describing the participant of the action.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Performer - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   MainAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   AdditionalAddressingObject - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
// Returns:
//   XDTODataObject - an XDTO object of the DMActionParticipant type.
//
Function ParticipantOfXDTOAction(Proxy, Performer, MainAddressingObject = Undefined,
		AdditionalAddressingObject = Undefined) Export
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.14.31") Then
		Return MemberOfXDTOTasks(
			Proxy,
			Performer,
			MainAddressingObject,
			AdditionalAddressingObject);
	EndIf;
	
	ArrayOfPresentationLines = New Array;
	ArrayOfPresentationLines.Add(Performer.Description);
	If ValueIsFilled(MainAddressingObject)
			And ValueIsFilled(MainAddressingObject.Description) Then
		ArrayOfPresentationLines.Add(MainAddressingObject.Description);
	EndIf;
	If ValueIsFilled(AdditionalAddressingObject)
			And ValueIsFilled(AdditionalAddressingObject.Description) Then
		ArrayOfPresentationLines.Add(AdditionalAddressingObject.Description);
	EndIf;
	Presentation = StrConcat(ArrayOfPresentationLines, ", ");
	
	ParticipantOfXDTOAction = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMActionParticipant");
	ParticipantOfXDTOAction.name = Presentation;
	If Performer.Type = "DMBusinessProcessExecutorRole" Then
		ParticipantOfXDTOAction.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy);
	Else
		ParticipantOfXDTOAction.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			Performer.ID,
			Performer.Type);
	EndIf;
	
	If Performer.Type = "DMEmployee"
			Or Performer.Type = "DMCompleteRole"
			Or Performer.Type = "DMBusinessProcessExecutorRole" Then
		ParticipantOfXDTOAction.taskParticipant = MemberOfXDTOTasks(
			Proxy,
			Performer,
			MainAddressingObject,
			AdditionalAddressingObject);
		Return ParticipantOfXDTOAction;
	EndIf;
	
	PropertyNameXDTO = "";
	If Performer.Type = "DMAutoSubstitutionForObjects" Then
		PropertyNameXDTO = "autoSubstitutionForObjects";
		
	ElsIf Performer.Type = "DMContainerProjects" Then
		PropertyNameXDTO = "containerProjects";
		
	ElsIf Performer.Type = "DMContainerSubdivisions" Then
		PropertyNameXDTO = "containerSubdivisions";
		
	ElsIf Performer.Type = "DMUser" Then
		PropertyNameXDTO = "user";
		
	ElsIf Performer.Type = "DMUserGroup" Then
		PropertyNameXDTO = "userGroup";
		
	Else
		
		Raise StrTemplate(NStr("vi = 'Đã xác định sai kiểu người tham gia thao tác: %1';
								|ru = 'Некорректно задан тип участника действия: %1';
								|en = 'The action participant type is incorrect: %1'; fa = 'The action participant type is incorrect: %1';
								|it = 'Некорректно задан тип участника действия: %1';
								|pl = 'The action participant type is incorrect: %1';
								|tr = 'Eylem katılımcısının tipi doğru belirtilmedi: %1'"), Performer.Type);
		
	EndIf;
	
	ParticipantOfXDTOAction[PropertyNameXDTO] = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		Performer.Type);
	ParticipantOfXDTOAction[PropertyNameXDTO].name = Performer.Description;
	ParticipantOfXDTOAction[PropertyNameXDTO].objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Performer.ID,
		Performer.Type);
	
	Return ParticipantOfXDTOAction;
	
EndFunction

// Fills in the Attribute that is a participant in the action BEFORE, in the receiver for the object participant of the ACTIONXDTO.
//
// Parameters:
//   Receiver - Arbitrary - an object containing the requisites or properties
//     that must be filled in by the property of the XDTO object.
//   ParticipantOfXDTOAction - XDTODataObject - an XDTO object of the DMActionParticipant type.
//   AttributeName - String - the name of the object props.
//   FillInPresentation - Boolean - a sign of the need to fill in the presentation details
//     by the ObjectId.presentation property.
//
Procedure ParticipantOfActionDM(Receiver, ParticipantOfXDTOAction, AttributeName, FillInPresentation = True) Export
	
	If ParticipantOfXDTOAction = Undefined Then
		Return;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(
			Undefined, ParticipantOfXDTOAction, "DMTaskParticipant") Then
		TaskParticipantBefore(Receiver, ParticipantOfXDTOAction, AttributeName, FillInPresentation);
		Return;
		
	ElsIf Not IntegrationWith1CDocumentManagementCore.ValidateType(
			Undefined, ParticipantOfXDTOAction, "DMActionParticipant") Then
		Return;
		
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ParticipantOfXDTOAction, "taskParticipant") Then
		TaskParticipantBefore(Receiver, ParticipantOfXDTOAction.taskParticipant, AttributeName, FillInPresentation);
		Return;
	EndIf;
	
	PropertyNameXDTO = "";
	If IntegrationWith1CDocumentManagementCore.PropertySet(
			ParticipantOfXDTOAction, "autoSubstitutionForObjects") Then
		PropertyNameXDTO = "autoSubstitutionForObjects";
		
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(
			ParticipantOfXDTOAction, "containerProjects") Then
		PropertyNameXDTO = "containerProjects";
		
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(
			ParticipantOfXDTOAction, "containerSubdivisions") Then
		PropertyNameXDTO = "containerSubdivisions";
		
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(
			ParticipantOfXDTOAction, "user") Then
		PropertyNameXDTO = "user";
		
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(
			ParticipantOfXDTOAction, "userGroup") Then
		PropertyNameXDTO = "userGroup";
		
	EndIf;
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		Receiver,
		ParticipantOfXDTOAction[PropertyNameXDTO],
		AttributeName,
		FillInPresentation);
	
EndProcedure

// Returns participants with the specified function.
//
// Parameters:
//   AllMembers - XDTOList - a list of all participants in the action.
//   ParticipantFunction - String - the function of the participant.
//
// Returns:
//   Array of XDTODataObject
//
Function ParticipantsInActionWithFunction(AllMembers, ParticipantFunction) Export
	
	Attendees = New Array;
	
	For Each ParticipantLine In AllMembers Do
		ThereIsHigherParticipant =
			IntegrationWith1CDocumentManagementCore.PropertyExists(ParticipantLine, "higherLevelParticipant")
			And IntegrationWith1CDocumentManagement3ClientServer.IdFilledIn(ParticipantLine.higherLevelParticipant);
		If Not ThereIsHigherParticipant And ParticipantLine.participantFunction = ParticipantFunction Then
			Attendees.Add(ParticipantLine);
		EndIf;
	EndDo;
	
	Return Attendees;
	
EndFunction

#EndRegion

#Region Links

// Performs a redrawing of the relationship tree in the Form.
//
// Parameters:
//   Form - ClientApplicationForm - A Form with a tree of links.
//   ListOfXDTOLinks - XDTODataObject - an XDTO object of the DMGetRelationsResponse type.
//
Procedure FillInLinkTreeInForm(Form, ListOfXDTOLinks) Export
	
	If Form.TreeOfLinksIsExpandedString = 0 Then
		TreeItems = Form.LinkTree.GetItems();
	Else
		BranchBeingDeployed = Form.LinkTree.FindByID(Form.TreeOfLinksIsExpandedString);
		TreeItems = BranchBeingDeployed.GetItems();
	EndIf;
	
	TreeItems.Clear();
	
	CurCurrentUserAndEmployees =
		IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
	
	For Each Link In ListOfXDTOLinks.relations Do
		
		If Form.TreeOfLinksIsExpandedString <> 0 And ValueIsFilled(Link.relatedObject.objectID.ID) Then
			Existing_Connection = IntegrationWith1CDocumentManagement3ClientServer.LinkByID(
				Form.LinkTree.GetItems(),
				Link.relatedObject.objectID.ID,
				Link.relatedObject.objectID.type);
			If Existing_Connection <> Undefined
					Or (Form.ObjectBeforeID = Link.relatedObject.objectID.ID
						And Form.ObjectBeforeType = Link.relatedObject.objectID.type) Then
				// To prevent looping, we skip the connection with an object that is already present in the tree.
				Continue;
			EndIf;
		EndIf;
		
		Form.TotalConnections = Form.TotalConnections + 1;
		
		If Form.OnlyImportantConnections And Not Link.relationType.important Then
			// We miss the connection, which is not important.
			Continue;
		EndIf;
		
		Form.ReadLinks = Form.ReadLinks + 1;
		
		LinkTypeString = Undefined;
		For Each TreeItem In TreeItems Do
			If TreeItem.LinkTypeID = Link.relationType.objectID.ID
					And TreeItem.LinkTypeType = Link.relationType.objectID.type Then
				LinkTypeString = TreeItem;
				Break;
			EndIf;
		EndDo;
		If LinkTypeString = Undefined Then
			LinkTypeString = TreeItems.Add();
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				LinkTypeString,
				Link.relationType,
				"LinkType");
			LinkTypeString.PictureIndex = -1;
			LinkTypeString.ThisIsParent = True;
		EndIf;
		
		RelatedObjects = LinkTypeString.GetItems();
		StringRelatedObject = RelatedObjects.Add();
		LinkTypeString.LinkedObject = StrTemplate("%1 (%2)", Link.relationType.abbreviatedName, RelatedObjects.Count());
		
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			StringRelatedObject,
			Link.relatedObject,
			"LinkedObject");
		StringRelatedObject.Ref =
			InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
				StringRelatedObject.LinkedObjectID,
				StringRelatedObject.LinkedObjectType);
		StringRelatedObject.URL = Link.relatedObject.objectID.navigationRef;
		
		If ValueIsFilled(StringRelatedObject.Ref) Then
			// A situation where there are rights to an object in the DO, but not in the IP, should not lead to an exception.
			// If an exception occurs, we will get a Presentation from BEFORE, and the user
			// will see a "Violation of access rights" only when trying to open the object.
			Try
				StringRelatedObject.LinkedObject = StrTemplate(NStr("vi = '%1, đối tượng %2';
																	|ru = '%1, объект %2';
																	|en = '%1, object %2'; fa = '%1, object %2';
																	|it = '%1, объект %2';
																	|pl = '%1, object %2';
																	|tr = '%1, nesne %2'"),
					String(StringRelatedObject.Ref),
					IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration());
			Except
				WriteLogEvent(
					IntegrationWith1CDocumentManagementCore.EventLogEventName(
						NStr("vi = 'Lỗi khi nhận trình bày đối tượng liên kết';
							|ru = 'Ошибка при получении представления связанного объекта';
							|en = 'An error occurred when receiving presentation of the linked object'; fa = 'An error occurred when receiving presentation of the linked object';
							|it = 'Errore alla ricezione della presentazione dell''oggetto collegato';
							|pl = 'Błąd przy otrzymaniu prezentacji powiązanego obiektu';
							|tr = 'İlgili nesnenin sunumu alınırken hata'",
							Common.DefaultLanguageCode())),
					EventLogLevel.Error,,
					StringRelatedObject.Ref,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
		
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			StringRelatedObject,
			Link.relationType,
			"LinkType");
		StringRelatedObject.DocumentNumber = Link.relatedObject.number;
		StringRelatedObject.DocumentDate = Link.relatedObject.date;
		StringRelatedObject.Sum = Link.relatedObject.sumPresentation;
		StringRelatedObject.PictureIndex = -1;
		StringRelatedObject.DeletionMark = Link.relatedObject.deletionMark;
		StringRelatedObject.ImportantLink = Link.relationType.important;
		StringRelatedObject.ItemName = Link.relatedObject.subjectName;
		If IntegrationWith1CDocumentManagementCore.PropertySet(Link.relatedObject, "extension") Then
			StringRelatedObject.FileExtention = Link.relatedObject.extension;
		EndIf;
		If ValueIsFilled(StringRelatedObject.FileExtention) Then
			StringRelatedObject.PictureIndex =
				IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(
					StringRelatedObject.FileExtention);
		EndIf;
		If Not ValueIsFilled(StringRelatedObject.LinkedObjectID)
				And Not ValueIsFilled(StringRelatedObject.LinkedObjectType) Then
			StringRelatedObject.RelatedString = Link.relatedObject.subjectName;
		EndIf;
		
		For Each File In Link.relatedObject.files Do
			StringRole = Undefined;
			If IntegrationWith1CDocumentManagementCore.PropertySet(File, "role") Then
				For Each TreeItem In StringRelatedObject.GetItems() Do
					If TreeItem.LinkedObjectID = File.role.objectID.ID
							And TreeItem.LinkedObjectType = File.role.objectID.type Then
						StringRole = TreeItem;
						Break;
					EndIf;
				EndDo;
				If StringRole = Undefined Then
					StringRole = StringRelatedObject.GetItems().Add();
					IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
						StringRole,
						File.role,
						"LinkedObject");
					IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
						StringRole,
						Link.relationType,
						"LinkType");
					StringRole.PictureIndex = 2;
					StringRole.ThisIsRoleOfFile = True;
				EndIf;
			EndIf;
			
			If Form.ShowOnlyOriginalsInLinks = True And File.scannedOriginal = False Then
				Continue
			EndIf;
			
			If StringRole = Undefined Then
				FileRow = StringRelatedObject.GetItems().Add();
			Else
				FileRow = StringRole.GetItems().Add();
			EndIf;
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				FileRow,
				File,
				"LinkedObject");
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				FileRow,
				Link.relationType,
				"LinkType");
			FileRow.IsOriginal = File.scannedOriginal;
			FileRow.Encrypted = File.encrypted;
			FileRow.PictureIndex =
				IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(File.extension);
			FileRow.PresentationHTML = File.htmlView;
			FileRow.PreviewCut = File.htmlViewTruncated;
			FileRow.FileExtention = File.extension;
			FileRow.DeletionMark = File.deletionMark;
			FileRow.URL = File.objectID.navigationRef;
			
			FileRow.IsBeingEdited = File.editing;
			If IntegrationWith1CDocumentManagementCore.PropertySet(File, "editingUser") Then
				FileRow.EditedByCurUser =
					IntegrationWith1CDocumentManagementCoreServerCall.FileIsBeingEditedByCurUser(
						File.editingUser.objectID.ID,
						File.editingUser.objectID.type,
						CurCurrentUserAndEmployees);
			Else
				FileRow.EditedByCurUser = False;
			EndIf;
		EndDo;
		
		If Link.relatedObject.hasAnotherRelations Then
			LinkString = StringRelatedObject.GetItems().Add();
			LinkString.LinkedObject = NStr("vi = 'Liên kết';
											|ru = 'Связи';
											|en = 'Links'; fa = 'پیوندها';
											|it = 'Links';
											|pl = 'Links';
											|tr = 'Bağlantılar'");
			LinkString.PictureIndex = 0;
			LinkString.ThisIsCommunicationBranch = True;
			ServiceLinkString = LinkString.GetItems().Add();
			ServiceLinkString.ServiceLine = True;
		EndIf;
		
	EndDo;
	
	If Form.OnlyImportantConnections Then
		Form.Items.InfoCommunicationGroup.Visible = (Form.ReadLinks <> Form.TotalConnections);
		Form.Items.DecorationOnlyImportantText.Title = StrTemplate(
			NStr("vi = 'Chỉ hiển thị các liên kết quan trọng (%1). Để xem tất cả (%2), hãy nhấn ""Hiển thị tất cả liên kết"".';
				|ru = 'Показаны только важные связи (%1). Чтобы увидеть все (%2), нажмите ""Показать все связи"".';
				|en = 'Only important links are shown (%1). To see all (%2), click ""Show all links"".'; fa = 'Only important links are shown (%1). To see all (%2), click ""Show all links"".';
				|it = 'Only important links are shown (%1). To see all (%2), click ""Show all links"".';
				|pl = 'Only important links are shown (%1). To see all (%2), click ""Show all links"".';
				|tr = 'Sadece önemli bağlantılar gösterilir (%1). Tümünü görmek için(%2) ""Tüm bağlantıları göster"" butonuna tıklayın.'"),
			Form.ReadLinks, Form.TotalConnections);
	EndIf;
	
EndProcedure

// Gets 1C object relationship settings:Document management.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   LinkFrom - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//   RefTo - String
//            - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
// Returns:
//   XDTODataObject - an XDTO object of the DMGetRelationsSettingsResponse type.
//
Function RelationshipSettings(Proxy, LinkFrom, RefTo = Undefined) Export
	
	Query = LinkSettingsRequest(Proxy, LinkFrom, RefTo);
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	Return Response;
	
EndFunction

// Returns a request for 1C object relationship settings:Document management.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   LinkFrom - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//   RefTo - String
//            - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
// Returns:
//   XDTODataObject - An XDTO object of the DMGetRelationsSettingsRequest type.
//
Function LinkSettingsRequest(Proxy, LinkFrom, RefTo = Undefined) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetRelationsSettingsRequest");
	
	Query.relationFrom = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectID");
	Query.relationFrom = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		LinkFrom.ID,
		LinkFrom.Type);
	
	If ValueIsFilled(RefTo)
			And IntegrationWith1CDocumentManagementCore.PropertyExists(Query, "relationTo") Then
		Query.relationTo = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelatedObject");
		Query.relationTo.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			RefTo.ID,
			RefTo.Type);
		Query.relationTo.name = RefTo.Presentation;
	EndIf;
	
	Return Query;
	
EndFunction

// Transfers the list of relationships to the incoming data structure required to create and modify the object BEFORE.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   LinksToCreation - Array of See IntegrationWith1CDocumentManagementCoreClientServer.ConnectionToCreation
//   StructureOfIncomingData - XDTODataObject - an XDTO object of the DMIncomingDataRequestStructure type.
//
Procedure TransferLinksToBeCreatedToIncomingDataStructure(Proxy, LinksToCreation, StructureOfIncomingData) Export
	
	ListOfLinksOfIPObject = StructureOfIncomingData.relations; // XDTOList
	
	For Each ConnectionToCreation In LinksToCreation Do
		XDTOConnection = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelation");
		
		XDTOConnection.object = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy, "DMRelatedObject");
		XDTOConnection.object.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy);
		XDTOConnection.object.name = "";
		
		XDTOConnection.relatedObject = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy, "DMRelatedObject");
		XDTOConnection.relatedObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			ConnectionToCreation.RefToID,
			ConnectionToCreation.RefToType);
		XDTOConnection.relatedObject.name = ConnectionToCreation.RefTo;
		
		XDTOConnection.relationType = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy, "DMRelationType");
		XDTOConnection.relationType.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			ConnectionToCreation.LinkTypeID,
			"DMRelationType");
		XDTOConnection.relationType.name = "";
		
		XDTOConnection.comment = ConnectionToCreation.Comment;
		
		ListOfLinksOfIPObject.Add(XDTOConnection);
	EndDo;
	
EndProcedure

// Retrieves a list of objects suitable for automatically adding links to the specified IP object.
// Takes into account the tabular parts of the IP object.
//
// Parameters:
//   ObjectIS - AnyRef - a reference to the original IP object to which the links are added.
//   ListOfAutomaticallyAddedLinks - XDTOList - a list of link creation settings specified in the rules
//     for uploading data to the DO.
//   EventName - String - name of the event for the log.
//
// Returns:
//   ValueTable:
//     * Ref - AnyRef - a reference to the IP object being linked.
//     * LinkedObjectBefore - Undefined - if the linked IP object has not yet been uploaded to the DO.
//                         - See IntegrationWith1CDocumentManagementCore.ObjectDataUpToExternalObject
//     * LinkType - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//     * IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - integration rule for
//         uploading a linked IP object to a DO.
//     * Comment - String - comment on the link being created.
//
Function SuitableObjectsForAddingLinks(ObjectIS, Val ListOfAutomaticallyAddedLinks, EventName) Export
	
	SuitableObjects = New ValueTable;
	SuitableObjects.Columns.Add("Ref", Common.AllRefsTypeDetails());
	SuitableObjects.Columns.Add("LinkedObjectBefore");
	SuitableObjects.Columns.Add("LinkType", New TypeDescription("Structure"));
	SuitableObjects.Columns.Add("IntegrationRule",
		New TypeDescription("CatalogRef.RulesForIntegrationWith1CDocumentManagement3"));
	SuitableObjects.Columns.Add("Comment", New TypeDescription("String"));
	
	TypesOfObjectsWithRules =
		IntegrationWith1CDocumentManagementCoreCached.TypesOfObjectsThatSupportIntegration();
	If TypesOfObjectsWithRules.Count() = 0 Then
		Return SuitableObjects;
	EndIf;
	
	AttributesNames = New Array;
	For Each XDTOSetup In ListOfAutomaticallyAddedLinks Do
		If ValueIsFilled(XDTOSetup.tabularSectionName) Then
			AttributesNames.Add(XDTOSetup.tabularSectionName);
		ElsIf StrFind(XDTOSetup.attributeName, "AdditionalAttribute5_") = 0 Then
			AttributesNames.Add(XDTOSetup.attributeName);
		EndIf;
	EndDo;
	ObjectAttributesIS = Common.ObjectAttributesValues(ObjectIS, AttributesNames);
	
	ValuesToUpload = New Map;
	For Each XDTOSetup In ListOfAutomaticallyAddedLinks Do
		If ValueIsFilled(XDTOSetup.tabularSectionName) Then
			TabularPartOfIPObject = ObjectAttributesIS[XDTOSetup.tabularSectionName].Unload();
			For Each String In TabularPartOfIPObject Do
				AttributeValueIS = String[XDTOSetup.attributeName];
				AddSuitableObjectsToCreateLinks(
					AttributeValueIS,
					SuitableObjects,
					XDTOSetup,
					ValuesToUpload);
			EndDo;
		ElsIf StrFind(XDTOSetup.attributeName, "AdditionalAttribute5_") = 1 Then
			Property = IntegrationWith1CDocumentManagementCore.AdditionalAttributeByName(
				XDTOSetup.attributeName);
			AttributeValueIS = PropertyManager.PropertyValue(ObjectIS, Property);
			AddSuitableObjectsToCreateLinks(
				AttributeValueIS,
				SuitableObjects,
				XDTOSetup,
				ValuesToUpload);
		Else
			AttributeValueIS = ObjectAttributesIS[XDTOSetup.attributeName];
			AddSuitableObjectsToCreateLinks(
				AttributeValueIS,
				SuitableObjects,
				XDTOSetup,
				ValuesToUpload);
		EndIf;
	EndDo;
	
	For Each MapItem In ValuesToUpload Do
		If SuitableObjects.Find(MapItem.Key, "Ref") <> Undefined Then
			Continue;
		EndIf;
		ErrorText = StrTemplate(
			NStr("vi = 'Không thể kết xuất đối tượng ""%1"" sang 1C:Document Management do nguyên nhân:
				|%2';
				|ru = 'Не удалось выгрузить объект ""%1"" в 1С:Документооборот по причине:
				|%2';
				|en = 'Cannot export the ""%1"" object to 1C:Document Management due to:
				|%2'; fa = 'Cannot export the ""%1"" object to 1C:Document Management due to:
				|%2';
				|it = 'Cannot export the ""%1"" object to 1C:Document Management due to:
				|%2';
				|pl = 'Cannot export the ""%1"" object to 1C:Document Management due to:
				|%2';
				|tr = '""%1"" nesnesi 1C:Document Management''e şu nedenle yüklenemedi çünkü:
				|%2'"),
			MapItem.Key,
			StrConcat(MapItem.Value, Chars.LF));
		IntegrationWith1CDocumentManagementCore.WriteError(ErrorText, EventName);
	EndDo;
	
	// Links to relevant documents may be stored somewhere else, for example, in the data registers.
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingSuitableObjectsToAddLink(
		ObjectIS,
		SuitableObjects);
	
	Return SuitableObjects;
	
EndFunction

// Gets 1C object connections:Document management.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ObjectAttributes - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMGetRelationsResponse type.
//
Function ObjectLinks(Proxy, ObjectAttributes) Export
	
	Query = ConnectionsOfRequestObject(Proxy, ObjectAttributes);
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	Return Response;
	
EndFunction

// Returns a request for 1C object relationships:Document management.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ObjectAttributes - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMGetRelationsRequest type.
//
Function ConnectionsOfRequestObject(Proxy, ObjectAttributes) Export
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetRelationsRequest");
	
	Query.object = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRelatedObject");
	Query.object.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		ObjectAttributes.ID,
		ObjectAttributes.Type);
	Query.object.name = ObjectAttributes.Presentation;
	
	Return Query;
	
EndFunction

#EndRegion

#Region CommunicationRules

// Complements the selection conditions with the context of the communication rules.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Context - See IntegrationWith1CDocumentManagement3Client.ContextOfCommunicationRules.
//   FilterConditions - XDTOList - list of selection conditions.
//
Procedure ToSupplementSelectionWithContextOfCommunicationRules(Proxy, Context, FilterConditions) Export
	
	If Not ValueIsFilled(Context)
			Or Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.15.41") Then
		Return;
	EndIf;
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "communicationRulesContext";
	ContextOfCommunicationRules = Condition.valueList; // XDTOList
	
	For Each DescriptionOfContextElement In Context Do
		If DescriptionOfContextElement.Value = Undefined Then
			Continue;
		EndIf;
		
		ContextElement = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMCommunicationRulesContextItem");
		ContextElement.name = DescriptionOfContextElement.Key;
		
		If TypeOf(DescriptionOfContextElement.Value) = Type("Structure") Then
			ContextElement.objectValue = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				DescriptionOfContextElement.Value.ID,
				DescriptionOfContextElement.Value.Type)
		Else
			ContextElement.simpleValue = DescriptionOfContextElement.Value;
		EndIf;
		
		ContextOfCommunicationRules.Add(ContextElement);
	EndDo;
	
	FilterConditions.Add(Condition);
	
EndProcedure

#EndRegion

#Region WorkingWithPDF

// Checks and programmatically adds the "DocumentPDFRequisit" Attribute and the "Documentpdffield" field to the form.
//
// Parameters:
//   Form - ClientApplicationForm - the required form.
//   ParentName - String - the name of the parent of the "documentpdffield" element.
//   TagName - String - the name of the Form element containing the PDF document field.
//   AttributeName - String - the name of the Attribute of the form containing the data of the PDF document.
//
Procedure OutputPDFDocumentToForm(Form, ParentName, TagName = "DocumentPDFField",
		AttributeName = "PDFDocumentAttributes") Export
	
	Items = Form.Items;
	If Items.Find(TagName) <> Undefined Then
		// The documentpdf field is already on the form.
		Return;
	EndIf;
	
	AttributesOfPDFDocument = IntegrationWith1CDocumentManagementCore.FormAttributeByName(
		Form.GetAttributes(),
		AttributeName);
	If AttributesOfPDFDocument = Undefined Then
		AttributesToBeAdded = New Array;
		AttributesToBeAdded.Add(New FormAttribute(AttributeName, New TypeDescription("PDFDocument")));
		Form.ChangeAttributes(AttributesToBeAdded);
	EndIf;
	
	CommandGroup = Items.Find("GroupOverviewOfCommandFile");
	If CommandGroup <> Undefined
			And CommandGroup.Group <> ChildFormItemsGroup.Vertical Then
		// Only the vertical group of Commands should be located to the right of the PDF field.
		CommandGroup = Undefined;
	EndIf;
	
	PDFField = Items.Insert(TagName, Type("FormField"), Items.Find(ParentName), CommandGroup);
	PDFField.Type = FormFieldType.PDFDocumentField;
	PDFField.DataPath = AttributeName;
	PDFField.TitleLocation = FormItemTitleLocation.None;
	PDFField.ToolTipRepresentation = ToolTipRepresentation.None;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// BID update handler for version 3.0.2.5. Replacing the ID of the action type to fill in the State of the document.
//
Procedure RestoreVersion_3_0_2_5() Export
	
	RuleRequest = New Query(
		"SELECT DISTINCT
		|	RulesForIntegrationWith1CDocumentManagement3AttributeFillingRulesIS.Ref AS Ref
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement3.AttributeFillingRulesIS AS RulesForIntegrationWith1CDocumentManagement3AttributeFillingRulesIS
		|		INNER JOIN Catalog.RulesForIntegrationWith1CDocumentManagement3 AS RulesForIntegrationWith1CDocumentManagement3
		|		ON RulesForIntegrationWith1CDocumentManagement3AttributeFillingRulesIS.Ref = RulesForIntegrationWith1CDocumentManagement3.Ref
		|WHERE
		|	NOT RulesForIntegrationWith1CDocumentManagement3.DeletionMark
		|	AND (CAST(RulesForIntegrationWith1CDocumentManagement3AttributeFillingRulesIS.AttributeNameObjectDM AS STRING(7))) = ""status_""");
	RuleSelection_ = RuleRequest.Execute().Select();
	
	While RuleSelection_.Next() Do
		
		RuleObject_ = RuleSelection_.Ref.GetObject(); // CatalogObject.RulesForIntegrationWith1CDocumentManagement3
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
			If StrFind(String.AttributeNameObjectDM, "status_") = 1 Then
				String.AttributeNameObjectDM = StrReplace(String.AttributeNameObjectDM, "-", "_");
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
		|	RulesForIntegrationWith1CDocumentManagement3.Ref AS Ref
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement3 AS RulesForIntegrationWith1CDocumentManagement3
		|		INNER JOIN Catalog.RulesForIntegrationWith1CDocumentManagement3.AttributeFillingRulesIS AS RulesForIntegrationWith1CDocumentManagement3AttributeFillingRulesIS
		|		ON (RulesForIntegrationWith1CDocumentManagement3.Ref = RulesForIntegrationWith1CDocumentManagement3AttributeFillingRulesIS.Ref)
		|WHERE
		|	NOT RulesForIntegrationWith1CDocumentManagement3.DeletionMark
		|	AND RulesForIntegrationWith1CDocumentManagement3.ObjectTypeIS LIKE ""Catalog.%""
		|	AND RulesForIntegrationWith1CDocumentManagement3AttributeFillingRulesIS.ModeOfChangingTheDataOfThePostedDocument <> &EmptyMode");
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
		|	Catalog.RulesForIntegrationWith1CDocumentManagement3 AS Rules
		|WHERE
		|	NOT DeletionMark
		|	AND ObjectTypeIS <> """"");
	
	RuleSelection_ = RuleRequest.Execute().Select();
	While RuleSelection_.Next() Do
		
		RuleObject_ = RuleSelection_.Ref.GetObject(); // CatalogObject.RulesForIntegrationWith1CDocumentManagement3
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
				NStr("ru = 'Помечено на удаление правило для несуществующего объекта %1';
					|vi = 'The rule is marked for deletion for the non-existent object %1';
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
			
			RowsCount = RuleObject_.AttributeFillingRulesIS.Count();
			For Number = 1 To RowsCount Do
				
				RowIndex = RowsCount - Number;
				Rule = RuleObject_.AttributeFillingRulesIS[RowIndex];
				
				If Rule.Variant <> Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute
						Or Rule.IsAdditionalAttributeIS
						Or Rule.ThisIsTable
						Or ValueIsFilled(Rule.Table)
						Or Rule.AttributeNameObjectIS = "Presentation"
						Or MetadataObject.Attributes.Find(Rule.AttributeNameObjectIS) <> Undefined Then
					Continue;
				EndIf;
				
				IsStandardAttribute = False;
				For Each StandardAttribute In MetadataObject.StandardAttributes Do
					If StandardAttribute.Name = Rule.AttributeNameObjectIS Then
						IsStandardAttribute = True;
						Break;
					EndIf;
				EndDo;
				
				If IsStandardAttribute Then
					Continue;
				EndIf;
				
				MessageText = StrTemplate(NStr("ru = 'Очищено правило загрузки для несуществующего реквизита %1';
												|vi = 'Import rule was cleared for the non-existing attribute %1';
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
				
				RuleObject_.AttributeFillingRulesIS.Delete(RowIndex);
				
				NeedEntry = True;
				
			EndDo;
			
		EndIf;
		
		If NeedEntry Then
			InfobaseUpdate.WriteData(RuleObject_);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Holding

// Returns the ID of the user's priority sub-asset.
//
// Parameters:
//   User - DefinedType.User - link to the user.
//   AllSUBAssetsOfXDTO - XDTOList - a list of XDTO objects of the DMDataExchangeNode type.
//
// Returns:
//   String - ID of the sub-asset.
//
Function PrioritySubAsset(User, AllSUBAssetsOfXDTO) Export
	
	NodesData = InformationRegisters.DataOf1CDocumentManagementNodes.NodesData();
	AvailableSUBAsset = IntegrationWith1CDocumentManagementCore.SubAssetForAuthorizationOfVDO(User);
	
	UserSSubAssets = New ValueTable;
	UserSSubAssets.Columns.Add("Node", New TypeDescription("String"));
	UserSSubAssets.Columns.Add("NodeID", New TypeDescription("String"));
	UserSSubAssets.Columns.Add("CentralNode", New TypeDescription("Boolean"));
	UserSSubAssets.Columns.Add("ThereIsAccess", New TypeDescription("Boolean"));
	
	For Each XDTOSubAsset In AllSUBAssetsOfXDTO Do
		NodeID = XDTOSubAsset.objectID.ID;
		ThisIsCentralNode = IntegrationWith1CDocumentManagementCore.PropertySet(XDTOSubAsset, "isCentral")
			And XDTOSubAsset.isCentral;
		If Not ThisIsCentralNode
				And (NodesData[NodeID] = Undefined
					Or Not ValueIsFilled(NodesData[NodeID].WebServiceAddress)) Then
			Continue;
		EndIf;
		NewRow = UserSSubAssets.Add();
		NewRow.Node = XDTOSubAsset.name;
		NewRow.NodeID = NodeID;
		NewRow.CentralNode = ThisIsCentralNode;
		NewRow.ThereIsAccess = (NodeID = AvailableSUBAsset);
	EndDo;
	
	If UserSSubAssets.Count() > 0 Then
		UserSSubAssets.Sort("ThereIsAccess DESC, CentralNode DESC, Node");
		UserSSubAsset = UserSSubAssets[0];
		If UserSSubAsset.CentralNode Then
			// If there is a user in the central sub-asset, we will leave the integration session parameter 1 of the Document Management node
			// empty. We will perform all calls to the service according to the data of the constant Addresswebservise1 Document flow.
			Return "";
		Else
			Return UserSSubAsset.NodeID;
		EndIf;
	Else
		// The user sub-asset data is not set. Let's leave the parameter of the integration session 1sdocument Node empty.
		// We will perform all calls to the service according to the data of the constant Addresswebservise1 Document flow.
		Return "";
	EndIf;
	
EndFunction

// Returns the 1C sub-asset:Document management Holding, which corresponds to the Cur current user.
//
// Returns:
//   String - ID of the sub-asset.
//
Function CurrentUserSSUBAsset() Export
	
	If Not InformationRegisters.DataOf1CDocumentManagementNodes.SUBAssetsOfHoldingAreUsed() Then
		Return "";
	EndIf;
	
	User = Users.CurrentUser();
	
	DesignatedSUBAsset = InformationRegisters.MapUsersTo1CDocumentManagementNodes.UserSSubAsset(User);
	If ValueIsFilled(DesignatedSUBAsset) Then
		Return DesignatedSUBAsset;
	EndIf;
	
	UserAttributes = Common.ObjectAttributesValues(
		User, "IsInternal, Invalid, DeletionMark");
	If UserAttributes.IsInternal = True
			Or UserAttributes.Invalid = True
			Or UserAttributes.DeletionMark = True Then
		// An official or invalid user must contact the Control Center.
		Return "";
	EndIf;
	
	// If, according to the information security data, the sub-asset could not be identified, it is required to make a request to the Control Center to determine the list of sub
	// -assets where the user is and to select the priority sub-asset.
	
	Try
		
		AuthorizationSettings =
			IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement();
		
		SetPrivilegedMode(True);
		AuthorizationSettings.UserName = Constants.IntegrationWith1CDocumentManagementUsernameForExchange.Get();
		If Not ValueIsFilled(AuthorizationSettings.UserName) Then
			Raise
				NStr("vi = 'Tên người sử dụng để trao đổi với 1C:Document Management';
					|ru = 'Не установлено значение константы ""Имя пользователя для обмена с 1С:Документооборотом""';
					|en = 'The ""Username for exchange with 1C:Document Management"" constant value is not set.'; fa = 'The ""Username for exchange with 1C:Document Management"" constant value is not set.';
					|it = 'Не установлено значение константы ""Имя пользователя для обмена с 1С:Документооборотом""';
					|pl = 'The ""Username for exchange with 1C:Document Management"" constant value is not set.';
					|tr = '""1C:Document Management ile değiştirilecek kullanıcı adı"" sabitinin değeri ayarlanmamış'");
		EndIf;
		AuthorizationSettings.Password = Constants.IntegrationWith1CDocumentManagementPasswordForExchange.Get();
		SetPrivilegedMode(False);
		
		RaiseException1 = True;
		ThisIsExchangeJobUser = True;
		Proxy = IntegrationWith1CDocumentManagementCore.GetProxy(
			RaiseException1,
			AuthorizationSettings,
			IntegrationWith1CDocumentManagementCore.AddressOf1CDocumentManagementWebService(True),,
			ThisIsExchangeJobUser);
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetUserNodesRequest");
		
		Query.user = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMUser", User);
		
		Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
		
		Return PrioritySubAsset(User, Response.nodes);
		
	Except
		
		IntegrationWith1CDocumentManagementCore.WriteError(
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return "";
		
	EndTry;
	
EndFunction

// Sets the Conditional appearance of the tree of sub-assets of 1C:Document Management Of The Holding.
//
// Parameters:
//   Form - ClientApplicationForm - a form containing a tree of sub-assets.
//
Procedure ToEstablishConditionalAppearanceOfHoldingSSUBAssets(Form) Export
	
	// The central sub-asset is in bold.
	AppearanceItem = Form.ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.CODESUBAssets.Name);
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("CODESUBAssets.CentralNode");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
	
	// The inactive sub-asset is grayed out.
	AppearanceItem = Form.ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Form.Items.CODESUBAssets.Name);
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("CODESUBAssets.Running");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = 1;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableData);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region BIDWebService

// Returns the version BEFORE by the VersionNumber message property.
//
// Parameters:
//   Message - XDTODataObject - an XDTO object of the DMILRequest type. A message from BEFORE.
//
// Returns:
//   String - version BEFORE.
//
Function VersionDMByMessage(Message)
	
	VersionBefore = "0.0.0.0";
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(Message, "versionNumber")
			And ValueIsFilled(Message.versionNumber) Then
		VersionBefore = Message.versionNumber;
	EndIf;
	
	Return VersionBefore;
	
EndFunction

// Adds a description of additional Attributes.
//
// Parameters:
//   ListOfXDTOAttributes - XDTOList
//   AttributesList - Array of ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
//   Synonyms - Map of KeyAndValue:
//     * Key - String
//     * Value - String
//
Procedure AddDescriptionOfAdditionalAttributes(ListOfXDTOAttributes, AttributesList, Synonyms)
	
	For Each Attribute In AttributesList Do
		XDTOAttribute = CreateBIDObject("DMILMetadataAttribute");
		XDTOAttribute.name = IntegrationWith1CDocumentManagementCore.NameOfAdditionalProps(Attribute);
		XDTOAttribute.synonym = StrTemplate(NStr("vi = 'Mục tin bổ sung: %1';
												|ru = 'Доп. реквизит: %1';
												|en = 'Additional attribute: %1'; fa = 'Additional attribute: %1';
												|it = 'Additional attribute: %1';
												|pl = 'Additional attribute: %1';
												|tr = 'Ek öznitelik: %1'"), Attribute.Description);
		
		AddDescriptionOfAttributeTypes(XDTOAttribute.typesList, Attribute.ValueType, Synonyms);
		ListOfXDTOAttributes.Add(XDTOAttribute);
	EndDo;
	
EndProcedure

// Adds a description of the Attributes from the metadata.
//
// Parameters:
//   ListOfXDTOAttributes - XDTOList
//   AttributesList - StandardAttributeDescriptions
//   Synonyms - Map of KeyAndValue:
//     * Key - String
//     * Value - String
//   TheseAreStandardAttributes - Boolean
//
Procedure AddDescriptionOfAttributes(ListOfXDTOAttributes, AttributesList, Synonyms, TheseAreStandardAttributes = False)
	
	For Each Attribute In AttributesList Do
		Synonym = Attribute.Synonym;
		
		If TheseAreStandardAttributes Then
			If Attribute.Name <> "Code"
					And Attribute.Name <> "Description"
					And Attribute.Name <> "Owner"
					And Attribute.Name <> "Parent"
					And Attribute.Name <> "Number"
					And Attribute.Name <> "Date"
					And Attribute.Name <> "Posted"
					And Attribute.Name <> "DeletionMark" Then
				Continue;
			EndIf;
			If Attribute.Name = "DeletionMark" Then
				Synonym = NStr("vi = 'Đặt dấu xóa';
								|ru = 'Пометка удаления';
								|en = 'Deletion mark'; fa = 'علامت حذف';
								|it = 'Contrassegnato per eliminazione';
								|pl = 'Zaznaczenie usunięcia';
								|tr = 'Silme işareti'");
			EndIf;
		EndIf;
		
		If StrStartsWith(Attribute.Name, "Delete") Then
			Continue;
		EndIf;
		
		XDTOAttribute = CreateBIDObject("DMILMetadataAttribute");
		XDTOAttribute.name = Attribute.Name;
		XDTOAttribute.synonym = ?(Synonym = "", Attribute.Name, Synonym);
		
		AddDescriptionOfAttributeTypes(XDTOAttribute.typesList, Attribute.Type, Synonyms);
		ListOfXDTOAttributes.Add(XDTOAttribute);
	EndDo;
	
EndProcedure

// Adds a description of the Attribute types.
//
// Parameters:
//   ListOfXDTOTypes - XDTOList
//   AttributeType - TypeDescription
//   Synonyms - Map of KeyAndValue:
//     * Key - String
//     * Value - String
//
Procedure AddDescriptionOfAttributeTypes(ListOfXDTOTypes, AttributeType, Synonyms)
	
	If TypeOf(AttributeType) <> Type("TypeDescription") Then
		ListOfXDTOTypes.Add(NStr("vi = 'Không xác định';
								|ru = 'Неопределено';
								|en = 'Undefined'; fa = 'تعریف‌نشده';
								|it = 'Неопределено';
								|pl = 'Undefined';
								|tr = 'Tanımlanmamış'"));
		Return;
	EndIf;
	
	For Each TypeDetails In AttributeType.Types() Do
		
		MetadataObject = Metadata.FindByType(TypeDetails);
		
		If (MetadataObject <> Undefined) Then
			FullName = MetadataObject.FullName();
			NameParts = StrSplit(FullName, ".");
			If NameParts[0] = "Catalog"
					Or NameParts[0] = "Document"
					Or NameParts[0] = "Enum"
					Or NameParts[0] = "ChartOfCharacteristicTypes"
					Or NameParts[0] = "BusinessProcess"
					Or NameParts[0] = "Task" Then
				ListOfXDTOTypes.Add(FullName);
				AddSynonym(Synonyms, FullName, MetadataObject.Synonym);
			Else
				ListOfXDTOTypes.Add(String(TypeDetails));
			EndIf;
		Else
			ListOfXDTOTypes.Add(String(TypeDetails));
		EndIf;
		
	EndDo;
	
EndProcedure

// Adds a synonym to the match.
//
// Parameters:
//   Synonyms - Map of KeyAndValue:
//     * Key - String
//     * Value - String
//   FullName - String
//   Synonym - String
//
Procedure AddSynonym(Synonyms, FullName, Synonym)
	
	If Synonyms.Get(FullName) = Undefined Then
		Synonyms.Insert(FullName, Synonym);
	EndIf;
	
EndProcedure

// Adds printed Forms to the XDTO object describing the IP metadata object.
//
// Parameters:
//   XDTOMetadataObject - XDTODataObject - XDTO object of type DMILMetadataObject:
//     * printedForms - XDTOList
//
Procedure FillInPrintedFormsOfMetadataObject(XDTOMetadataObject)
	
	TableOfPrintedForms = IntegrationWith1CDocumentManagementCore.PrintManagers(
		XDTOMetadataObject.name);
	
	For Each StructureOfPrintedForm In TableOfPrintedForms Do
		XDTOPrintedForm = CreateBIDObject("DMILPrintedForm");
		XDTOPrintedForm.commandName = StructureOfPrintedForm.CommandName;
		XDTOPrintedForm.printManager = StructureOfPrintedForm.PrintManager;
		XDTOPrintedForm.commandPresentation = StructureOfPrintedForm.CommandPresentation;
		XDTOPrintedForm.additionalParameters = StructureOfPrintedForm.AdditionalParameters;
		XDTOMetadataObject.printedForms.Add(XDTOPrintedForm);
	EndDo;
	
EndProcedure

Procedure FixErrorExceedingExecutionTime(RunTime, Message, Result)
	
	WriteLogEvent(
		IntegrationWith1CDocumentManagementCore.EventLogEventName(
			NStr("vi = 'Bộ xử lý truy vấn XDTO';
				|ru = 'Обработка запросов XDTO';
				|en = 'XDTO request processing'; fa = 'XDTO request processing';
				|it = 'Elaborazione richieste XDTO';
				|pl = 'Przetwarzanie zapytań XDTO';
				|tr = 'XDTO sorguları işleme'", Common.DefaultLanguageCode())),
		EventLogLevel.Error,,,
		StrTemplate(NStr("ru = 'Превышено время ожидания выполнения запроса.
			|Время выполнения: %1 сек.
			|
			|Текст запроса:
			|%2
			|
			|Результат запроса:
			|%3';
			|vi = 'Query time-out.
			|Execution time: %1 sec.
			|
			|Query text: 
			|%2
			|
			|Query result:
			|%3';
			|en = 'Query time-out.
			|Execution time: %1 sec.
			|
			|Query text: 
			|%2
			|
			|Query result:
			|%3'; fa = 'Query time-out.
			|Execution time: %1 sec.
			|
			|Query text: 
			|%2
			|
			|Query result:
			|%3';
			|it = 'Query time-out.
			|Execution time: %1 sec.
			|
			|Query text: 
			|%2
			|
			|Query result:
			|%3';
			|pl = 'Query time-out.
			|Execution time: %1 sec.
			|
			|Query text: 
			|%2
			|
			|Query result:
			|%3';
			|tr = 'Sorgu yürütme zaman aşımına uğradı.
			|Yürütme süresi: %1
			|
			|Sorgu metni:
			|%2
			|
			|Sorgu sonucu:
			|%3'"),
				RunTime,
				TextOfXDTOObjectForLC(Message),
				TextOfXDTOObjectForLC(Result)));
	
EndProcedure

// Returns a DMILBatchResponse object containing the results of a batch request.
//
// Parameters:
//   Message - XDTODataObject - an XDTO object of the DMILBatchRequest type.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMILBatchResponse or DMILError type.
//
Function ProcessPackage(Message)
	
	Try
		
		ResponsePackage = CreateBIDObject("DMILBatchResponse");
		
		For Each PackageMessage In Message.Requests Do
			
			Response = ProcessUniversalMessage(PackageMessage);
			ResponsePackage.responses.Add(Response);
			
		EndDo;
		
		Return ResponsePackage;
		
	Except
		
		Return DescriptionOfXDTOError(
			NStr("vi = 'Lỗi khi xử lý gói thông báo';
				|ru = 'Ошибка при обработке пакета сообщений';
				|en = 'An error occurred when processing the message package'; fa = 'An error occurred when processing the message package';
				|it = 'An error occurred when processing the message package';
				|pl = 'An error occurred when processing the message package';
				|tr = 'Mesaj paketi işlenirken hata oluştu'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndFunction

// Returns the ObjectId by reference to the IC object.
//
// Parameters:
//   Ref - AnyRef - reference to the IP object.
//   RequiredFieldsOnly - Boolean - fill in only required fields.
//   Presentation - String - representation of objects.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMILObjectID type.
//
Function GetDMILObjectIDFromLink(Ref, RequiredFieldsOnly = False, Presentation = Undefined)
	
	DMILObjectID = CreateBIDObject("DMILObjectID");
	DMILObjectID.ID = IntegrationWith1CDocumentManagementCore.GetIDFromLink(Ref);
	DMILObjectID.type = IntegrationWith1CDocumentManagementCore.GetLinkTypeName(Ref);
	
	If RequiredFieldsOnly Then
		Return DMILObjectID;
	EndIf;
	
	If Not Enums.AllRefsType().ContainsType(TypeOf(Ref)) Then
		DMILObjectID.navigationRef = GetURL(Ref);
	Else
		DMILObjectID.navigationRef = "";
	EndIf;
	
	If Presentation <> Undefined Then
		DMILObjectID.presentation = Presentation;
	ElsIf Ref.IsEmpty() Then
		DMILObjectID.presentation = Ref.Metadata().Synonym;
	Else
		DMILObjectID.presentation = String(Ref);
	EndIf;
	
	Return DMILObjectID;
	
EndFunction

// Checks the correctness of the expression in the embedded language used to fill in the Attributes in
// the integration rules.
//
// Parameters:
//   Message - XDTODataObject - an XDTO object of type DMILCheckExpressionOnBuiltInLanguageRequest.
//
// Returns:
//   XDTODataObject - an XDTO object of type DMILOK or DMILError.
//
Function CheckExpressionInEmbeddedLanguage(Message)
	
	Try
		
		If Not Users.IsFullUser() Then
			Raise NStr("vi = 'Không đủ quyền để thực hiện biểu thức bằng ngôn ngữ hệ thống.
				|Hãy liên hệ với người quản trị.';
				|ru = 'Недостаточно прав для выполнения выражения на встроенном языке.
				|Обратитесь к администратору.';
				|en = 'Insufficient rights to execute an expression in 1C:Enterprise language.
				|Contact the administrator.'; fa = 'Insufficient rights to execute an expression in 1C:Enterprise language.
				|Contact the administrator.';
				|it = 'Недостаточно прав для выполнения выражения на встроенном языке.
				|Обратитесь к администратору.';
				|pl = 'Insufficient rights to execute an expression in 1C:Enterprise language.
				|Contact the administrator.';
				|tr = 'Yerleşik dilde bir ifadeyi çalıştırmak için izniniz yetersiz. 
				|Yöneticiniz ile iletişime geçin.'");
		EndIf;
		
		If TrimAll(Message.expressionOnBuiltInLanguage) <> "" Then
			Parameters = New Structure;
			Source = IntegrationWith1CDocumentManagementCore.NewIPObject(Message.objectType);
			Parameters.Insert("Source", Source);
			Parameters.Insert("Result", Undefined);
			If IntegrationWith1CDocumentManagementCore.PropertySet(Message, "tabularSectionName")
					And Message.tabularSectionName <> "" Then
				Table = Source[Message.tabularSectionName]; // ValueTable
				Parameters.Insert("CurrentRow", Table.Add());
			EndIf;
			
			IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
				Message.expressionOnBuiltInLanguage,
				Parameters);
			
			If (Message.forTabularSection = True) And TypeOf(Parameters.Result) <> Type("ValueTable") Then
				Raise StrTemplate(
					NStr("ru = 'Для заполнения таблицы результат должен иметь тип %1';
						|vi = 'To fill the table, the result must have the %1 type';
						|en = 'To fill the table, the result must have the %1 type'; fa = 'To fill the table, the result must have the %1 type';
						|it = 'Для заполнения таблицы результат должен иметь тип %1';
						|pl = 'To fill the table, the result must have the %1 type';
						|tr = 'Tabloyu doldurmak için sonucun sütun türünde %1 olması gerekir'"),
					"ValueTable");
			EndIf;
		EndIf;
		
		Response = CreateBIDObject("DMILOK");
		
	Except
		
		Response = DescriptionOfXDTOError(
			NStr("vi = 'Đã tìm thấy lỗi trong biểu thức bằng ngôn ngữ hệ thống';
				|ru = 'Найдена ошибка в выражении на встроенном языке';
				|en = 'There is an error in expression in 1C:Enterprise language'; fa = 'There is an error in expression in 1C:Enterprise language';
				|it = 'Individuato un errore nell''espressione in linguaggio integrato';
				|pl = 'Wykryto błąd w wyrażeniu w języku wbudowanym';
				|tr = 'Yerleşik dildeki ifadede hata bulundu'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Response;
	
EndFunction

// Performs synchronization of users BEFORE and after the integrated system.
//
// Parameters:
//   Message - XDTODataObject - an XDTO object of the DMILSynchronizeUsersRequest type.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMILSynchronizeUsersResponse or DMILError type.
//
Function SynchronizeUsersOfIntegratedSystemAndUsersUPTO(Message)
	
	BeginTransaction();
	
	Try
		
		Response = CreateBIDObject("DMILSynchronizeUsersResponse");
		
		ThisIsSlaveSUBAsset = (Right(Message.versionNumber, 4) = "HOLD");
		
		UserConnections = New Map;
		
		For Each UserBefore In ListOfXDTObjectsAboutMessage(Message.messageData) Do
			
			OldIPUser =
				InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
					UserBefore.objectID.ID,
					UserBefore.objectID.type);
			If ValueIsFilled(OldIPUser) Then
				OldData =
					InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ObjectDataUpToExternalObject(
						OldIPUser);
				If TypeOf(OldData.AdditionalData) <> Type("Structure") Then
					OldData.AdditionalData = New Structure("ThisIsSlaveSUBAsset, Node", False, Undefined);
				EndIf;
				If ThisIsSlaveSUBAsset And Not OldData.AdditionalData.ThisIsSlaveSUBAsset Then
					// Communication between the user of the IC and the user TO from the MC is more priority than communication with the PU.
					ownerObject = CreateBIDObject("ExternalObjectID");
					ownerObject.ID = OldData.ID;
					ownerObject.type = OldData.type;
					UserConnections[OldIPUser] = ownerObject;
					Continue;
				EndIf;
				InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.DeleteLink(
					UserBefore.objectID.ID,
					UserBefore.objectID.type,
					OldIPUser);
			EndIf;
			
			IPUser =
				IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
					IntegrationWith1CDocumentManagementCoreCached.TypeUsers(),
					IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(UserBefore),,
					False);
			If ValueIsFilled(IPUser) Then
				
				CurrentData =
					InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ObjectDataUpToExternalObject(
						IPUser);
				If CurrentData <> Undefined Then
					If TypeOf(CurrentData.AdditionalData) <> Type("Structure") Then
						CurrentData.AdditionalData = New Structure("ThisIsSlaveSUBAsset, Node", False, Undefined);
					EndIf;
					If ThisIsSlaveSUBAsset And Not CurrentData.AdditionalData.ThisIsSlaveSUBAsset Then
						// Communication between the user of the IC and the user TO from the MC is more priority than communication with the PU.
						ownerObject = CreateBIDObject("ExternalObjectID");
						ownerObject.ID = CurrentData.ID;
						ownerObject.type = CurrentData.type;
						UserConnections[IPUser] = ownerObject;
						Continue;
					EndIf;
				EndIf;
				
				If IntegrationWith1CDocumentManagementCore.PropertySet(
						UserBefore, "infoBaseUser") Then
					AdditionalData =
						IntegrationWith1CDocumentManagementCore.AdditionalDataOfCommunicationOfUsersDOiIS();
					AdditionalData.IBUser = UserBefore.infoBaseUser.name;
					AdditionalData.OSUser = UserBefore.infoBaseUser.OSUserName;
					AdditionalData.Email = UserBefore.infoBaseUser.email;
					AdditionalData.Node = Message.nodeID;
					AdditionalData.ThisIsSlaveSUBAsset = ThisIsSlaveSUBAsset;
				EndIf;
				InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.AddLink(
					UserBefore.objectID.ID,
					UserBefore.objectID.type,
					IPUser,
					False,
					AdditionalData);
				ownerObject = CreateBIDObject("ExternalObjectID");
				ownerObject.ID = UserBefore.objectID.ID;
				ownerObject.type = UserBefore.objectID.type;
				UserConnections[IPUser] = ownerObject;
				
			ElsIf ValueIsFilled(OldIPUser)
					And OldData.AdditionalData.Node <> Message.nodeID Then
				
				// We will restore the previously deleted connection, because it may be relevant for another sub-asset.
				InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.AddLink(
					OldData.ID,
					OldData.type,
					OldData.ExternalObject,
					False,
					OldData.AdditionalData);
				
			EndIf;
			
		EndDo;
		
		XDTOUserConnections = Response.links; // XDTOList
		
		For Each Link In UserConnections Do
			XDTOConnection = CreateBIDObject("DMILLink");
			XDTOConnection.linkedObject = GetDMILObjectIDFromLink(Link.Key);
			XDTOConnection.ownerObject = Link.Value;
			XDTOUserConnections.Add(XDTOConnection);
		EndDo;
		
		CommitTransaction();
		
		Return Response;
		
	Except
		
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Return DescriptionOfXDTOError(
			StrTemplate(NStr("vi = 'Lỗi khi đồng bộ người sử dụng DM với người sử dụng %1';
							|ru = 'Ошибка при синхронизации пользователей ДО с пользователями %1';
							|en = 'An error occurred when syncing DI users with %1 users'; fa = 'An error occurred when syncing DI users with %1 users';
							|it = 'Ошибка при синхронизации пользователей ДО с пользователями %1';
							|pl = 'An error occurred when syncing DI users with %1 users';
							|tr = 'Şu tarihe kadar kullanıcıları %1 kullanıcıları ile senkronize edilirken hata oluştu'"),
				IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration()),
			GetErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndFunction

// Searches the integration rules for expressions in the embedded language that need to be executed on the DO side,
// for later filling in the object data on the IC side.
//
// Parameters:
//   Message - XDTODataObject - an XDTO object of type DMILGetExpressionListRequest.
//
// Returns:
//   XDTODataObject - an XDTO object of type DMILGetExpressionListResponse or DMILError.
//
Function ListOfExpressionsInBuiltInLanguageToExecuteOnSideDM(Message)
	
	Try
		
		Response = CreateBIDObject("DMILGetExpressionListResponse");
		ExpressionsByObjects = Response.objectsExpressionRows; // XDTOList
		
		ListOfIPObjects = New Array;
		MatchingObjectIDToIPObjects = New Map;
		
		For Each ObjectID In Message.objects Do
			Ref = GetLinkByObjectID(ObjectID);
			ListOfIPObjects.Add(Ref);
			MatchingObjectIDToIPObjects.Insert(Ref, ObjectID);
		EndDo;
		
		SuitableRules = IntegrationWith1CDocumentManagement3ServerCall.SuitableIntegrationRules(
			ListOfIPObjects,
			True);
		
		RulesForAnalysis = New Array;
		For Each ComplianceWithRules In SuitableRules Do
			For Each Rule In ComplianceWithRules.Value Do
				If RulesForAnalysis.Find(Rule) = Undefined Then
					RulesForAnalysis.Add(Rule);
				EndIf;
			EndDo;
		EndDo;
		
		RuleExpressionTable =
			Catalogs.RulesForIntegrationWith1CDocumentManagement3.ExpressionsToExecuteOnSideDM(RulesForAnalysis);
		
		For Each MatchingObjectID In MatchingObjectIDToIPObjects Do
			ComplianceWithXDTORules = CreateBIDObject("DMILObjectExpressionRow");
			CopyXDTOObject(ComplianceWithXDTORules.object, MatchingObjectID.Value);
			ListOfExpressions = ComplianceWithXDTORules.expressionRows; // XDTOList
			
			ComplianceWithRules = SuitableRules[MatchingObjectID.Key];
			If TypeOf(ComplianceWithRules) <> Type("Array") Then
				RulesQuantity = 0;
			Else
				RulesQuantity = ComplianceWithRules.Count();
			EndIf;
			If RulesQuantity = 1 Then
				RuleExpressions = RuleExpressionTable.FindRows(New Structure("Ref", ComplianceWithRules[0]));
				For Each ExpressionToExecuteOnDMSide In RuleExpressions Do
					ExpressionOfXDTORule = CreateBIDObject("DMILExpressionRow");
					PrepareCalculatedExpressionToBeTransferredToDMSide(
						ExpressionOfXDTORule,
						ExpressionToExecuteOnDMSide);
					ListOfExpressions.Add(ExpressionOfXDTORule);
				EndDo;
			Else
				ComplianceWithXDTORules.error = DescriptionOfXDTOError(
					NStr("vi = 'Lỗi khi nhận danh sách biểu thức bằng ngôn ngữ hệ thống';
						|ru = 'Ошибка при получении списка выражений на встроенном языке';
						|en = 'An error occurred when receiving the 1C:Enterprise language expression list'; fa = 'An error occurred when receiving the 1C:Enterprise language expression list';
						|it = 'Errore durante la ricezione dell''elenco di espressioni in linguaggio integrato';
						|pl = 'Błąd podczas otrzymania listy wyrażeń w języku wbudowanym';
						|tr = 'Yerleşik dildeki ifadelerin listesi alınırken hata'"),
					StrTemplate(
						NStr("vi = 'Đối với đối tượng ""%1"" không thể chọn quy tắc tích hợp phù hợp duy nhất.
							|Tổng số quy tắc đã tìm thấy: %2';
							|ru = 'Для объекта ""%1"" не удалось подобрать единственное подходящее правило интеграции.
							|Всего найдено правил: %2';
							|en = 'Cannot select the only integration rule suitable for the ""%1"" object.
							|Found rules in total: %2'; fa = 'Cannot select the only integration rule suitable for the ""%1"" object.
							|Found rules in total: %2';
							|it = 'Non è stato possibile selezionare l''unica regola di integrazione adatta per l''oggetto ""%1"".
							| Regole trovate in totale: %2';
							|pl = 'Dla obiektu ""%1"" nie udało się znaleźć jedynej pasującej reguły integracji.
							|Łącznie znaleziono reguł: %2';
							|tr = '""%1"" nesnesi için tek uygun entegrasyon kuralı bulunamadı.
							| Toplam bulunan kurallar: %2'"),
							MatchingObjectID.Key,
							RulesQuantity));
			EndIf;
			
			ExpressionsByObjects.Add(ComplianceWithXDTORules);
		EndDo;
		
	Except
		
		Response = DescriptionOfXDTOError(
			NStr("vi = 'Lỗi khi nhận danh sách biểu thức bằng ngôn ngữ hệ thống';
				|ru = 'Ошибка при получении списка выражений на встроенном языке';
				|en = 'An error occurred when receiving the 1C:Enterprise language expression list'; fa = 'An error occurred when receiving the 1C:Enterprise language expression list';
				|it = 'Errore durante la ricezione dell''elenco di espressioni in linguaggio integrato';
				|pl = 'Błąd podczas otrzymania listy wyrażeń w języku wbudowanym';
				|tr = 'Yerleşik dildeki ifadelerin listesi alınırken hata'"),
			GetErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Response;
	
EndFunction

// Gets a list of printed forms of IP objects.
//
// Parameters:
//   Message - XDTODataObject - an XDTO object of the DMILGetPrintedFormsRequest type.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMILGetPrintedFormsResponse or DMILError type.
//
Function ListOfPrintedFormsOfIPObjects(Message)
	
	Try
		
		Response = CreateBIDObject("DMILGetPrintedFormsResponse");
		ListOfObjects = Response.objects; // XDTOList
		
		For Each XDTOMetadataObject In Message.objects Do
			FillInPrintedFormsOfMetadataObject(XDTOMetadataObject);
			ListOfObjects.Add(XDTOMetadataObject);
		EndDo;
		
	Except
		
		Response = DescriptionOfXDTOError(
			NStr("vi = 'Lỗi khi nhận danh sách mẫu in';
				|ru = 'Ошибка при получении списка печатных форм';
				|en = 'An error occurred when getting the print form list'; fa = 'An error occurred when getting the print form list';
				|it = 'Ошибка при получении списка печатных форм';
				|pl = 'An error occurred when getting the print form list';
				|tr = 'Yazdırma formu listesi sırasında hata'"),
			GetErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Response;
	
EndFunction

// Returns the IP metadata structure.
//
// Parameters:
//   Message - XDTODataObject - an XDTO object of the DMILGetMetadataRequest type.
//
// Returns:
//   XDTODataObject - an XDTO object of the DMILGetMetadataResponse or DMError type.
//
Function IntegratedSystemMetadataStructure(Message)
	
	Try
		
		Response = CreateBIDObject("DMILGetMetadataResponse");
		MetadataObjects = Response.metadataObjects; // XDTOList
		SynonymsOfObjects = Response.metadataSynonyms; // XDTOList
		
		GetEverything = True;
		ShouldGetAttributes = False;
		GetTableParts = False;
		ReceivePrintedForms = False;
		GetIntegrationRules = False;
		If IntegrationWith1CDocumentManagementCore.PropertySet(Message, "columnSet")
				And Message.columnSet.Count() > 0 Then
			GetEverything = False;
			For Each AttributesToReceive In Message.columnSet Do
				If Lower(AttributesToReceive) = "objectsonly" Then
					ShouldGetAttributes = False;
					GetTableParts = False;
					ReceivePrintedForms = False;
					GetIntegrationRules = False;
					Break;
				ElsIf Lower(AttributesToReceive) = "attributes" Then
					ShouldGetAttributes = True;
				ElsIf Lower(AttributesToReceive) = "tabularsections" Then
					GetTableParts = True;
				ElsIf Lower(AttributesToReceive) = "printedforms" Then
					ReceivePrintedForms = True;
				ElsIf Lower(AttributesToReceive) = "integrationrules" Then
					GetIntegrationRules = True;
				EndIf;
			EndDo;
		EndIf;
		
		Response.dataBaseName = IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
		Response.dataBaseID = IntegrationWith1CDocumentManagementCoreCached.DatabaseId_();
		Response.dmilVersionNumber = IntegrationWith1CDocumentManagementCoreCached.DMILVersion();
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(Message, "objects")
				And Message.objects.Count() > 0 Then
			ObjectsTypesIS = New Array;
			For Each TypeName In Message.objects Do
				If StrFind(TypeName, "Ref.") = 0 Then
					TypeName = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(TypeName);
				EndIf;
				ObjectsTypesIS.Add(Type(TypeName));
			EndDo;
		Else
			ObjectsTypesIS = IntegrationWith1CDocumentManagementCoreCached.TypesOfObjectsThatSupportIntegration();
		EndIf;
		
		ObjectsThatSupportIntegration = New Array;
		CommonObjectsAttributes = New Map;
		For Each ValueType In ObjectsTypesIS Do
			MetadataObject = Metadata.FindByType(ValueType);
			If MetadataObject = Undefined
					Or Not IntegrationWith1CDocumentManagementCore.MetadataObjectIsSupported(MetadataObject) Then
				Continue;
			EndIf;
			ObjectsThatSupportIntegration.Add(MetadataObject);
			CommonObjectsAttributes[MetadataObject] = New Array;
		EndDo;
		
		UsingAttributeToUse = Metadata.ObjectProperties.CommonAttributeUse.Use;
		UsingAutoAttributes = Metadata.ObjectProperties.CommonAttributeUse.Auto;
		AutoUseOfAttributeToUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use;
		DoNotUseDataSeparationAttributes = Metadata.ObjectProperties.CommonAttributeDataSeparation.DontUse;
		For Each CommonAttribute In Metadata.CommonAttributes Do
			If CommonAttribute.DataSeparation <> DoNotUseDataSeparationAttributes Then
				Continue;
			EndIf;
			For Each CompositionItem In CommonAttribute.Content Do
				If (CompositionItem.Use = UsingAttributeToUse
						Or (CompositionItem.Use = UsingAutoAttributes
							And CommonAttribute.AutoUse = AutoUseOfAttributeToUse))
						And IntegrationWith1CDocumentManagementCore.MetadataObjectIsSupported(CompositionItem.Metadata)
						And ObjectsThatSupportIntegration.Find(CompositionItem.Metadata) <> Undefined Then
					CommonObjectsAttributes[CompositionItem.Metadata].Add(CommonAttribute);
				EndIf;
			EndDo;
		EndDo;
		
		Synonyms = New Map;
		
		For Each MetadataObject In ObjectsThatSupportIntegration Do
			
			FullName = MetadataObject.FullName();
			
			XDTOMetadataObject = CreateBIDObject("DMILMetadataObject");
			XDTOMetadataObject.name = FullName;
			Attributes = XDTOMetadataObject.attributes; // XDTOList
			TabularSections = XDTOMetadataObject.tabularSections; // XDTOList
			RulesForIntegration = XDTOMetadataObject.integrationRules; // XDTOList
			
			AddSynonym(Synonyms, FullName, MetadataObject.Synonym);
			
			If GetEverything Or ShouldGetAttributes Then
				
				XDTOAttribute = CreateBIDObject("DMILMetadataAttribute");
				XDTOAttribute.name = "Presentation";
				XDTOAttribute.synonym = NStr("vi = 'Trình bày';
											|ru = 'Представление';
											|en = 'Presentation'; fa = 'نمایش';
											|it = 'Visualizzazione';
											|pl = 'Presentation';
											|tr = 'Sunum'");
				AddDescriptionOfAttributeTypes(XDTOAttribute.typesList, New TypeDescription("String"), Synonyms);
				Attributes.Add(XDTOAttribute);
				
				AddDescriptionOfAttributes(
					Attributes,
					MetadataObject.StandardAttributes,
					Synonyms,
					True);
				AddDescriptionOfAttributes(
					Attributes,
					MetadataObject.Attributes,
					Synonyms);
				AddDescriptionOfAttributes(
					Attributes,
					CommonObjectsAttributes[MetadataObject],
					Synonyms);
				
				PropertiesOwner = New(ValueType);
				If PropertyManager.UseAddlAttributes(PropertiesOwner) Then
					AddDescriptionOfAdditionalAttributes(
						Attributes,
						PropertyManager.ObjectProperties(PropertiesOwner, True, False),
						Synonyms);
				EndIf;
				
			EndIf;
			
			If GetEverything Or GetTableParts Then
				
				For Each TabularSection In MetadataObject.TabularSections Do
					
					If TabularSection.Name = "AdditionalAttributes"
							Or Left(TabularSection.Name, 7) = "Delete"
							Or TabularSection.Attributes.Count() = 0 Then
						Continue;
					EndIf;
					
					XDTOTabularSection = CreateBIDObject("DMILMetadataTabularSection");
					XDTOTabularSection.name = TabularSection.Name;
					XDTOTabularSection.synonym = TabularSection.Synonym;
					
					AddDescriptionOfAttributes(
						XDTOTabularSection.attributes,
						TabularSection.StandardAttributes,
						Synonyms,
						True);
					AddDescriptionOfAttributes(
						XDTOTabularSection.attributes,
						TabularSection.Attributes,
						Synonyms);
					
					TabularSections.Add(XDTOTabularSection);
					
				EndDo;
				
			EndIf;
			
			If GetEverything Or ReceivePrintedForms Then
				FillInPrintedFormsOfMetadataObject(XDTOMetadataObject);
			EndIf;
			
			If GetEverything Or GetIntegrationRules Then
				SuitableRules =
					IntegrationWith1CDocumentManagement3ServerCall.SuitableIntegrationRulesForTypeOfIPObject(FullName);
				For Each TheseRules In SuitableRules Do
					XDTOIntegrationRule = CreateBIDObject("DMILIntegrationRule");
					XDTOIntegrationRule.objectID = GetDMILObjectIDFromLink(TheseRules.Ref);
					XDTOIntegrationRule.objectTypeDM = TheseRules.ObjectTypeDM;
					XDTOIntegrationRule.documentTypeID = TheseRules.IDOfDocumentType;
					XDTOIntegrationRule.documentType = TheseRules.PresentationOfTheDocumentType;
					
					RulesForIntegration.Add(XDTOIntegrationRule);
				EndDo;
			EndIf;
			
			MetadataObjects.Add(XDTOMetadataObject);
			
		EndDo;
		
		For Each Synonym In Synonyms Do
			XDTOMetadataObject = CreateBIDObject("DMILMetadataSynonym");
			XDTOMetadataObject.name = Synonym.Key;
			XDTOMetadataObject.synonym = Synonym.Value;
			SynonymsOfObjects.Add(XDTOMetadataObject);
		EndDo;
		
		Return Response;
		
	Except
		
		Return DescriptionOfXDTOError(
			NStr("vi = 'Lỗi khi nhận cấu trúc metadata';
				|ru = 'Ошибка при получении структуры метаданных';
				|en = 'An error occurred when receiving the metadata structure'; fa = 'An error occurred when receiving the metadata structure';
				|it = 'Ошибка при получении структуры метаданных';
				|pl = 'An error occurred when receiving the metadata structure';
				|tr = 'Meta veri yapısının alınmasında hata oluştu'"),
			GetErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndFunction

// Returns the XML schema of the web service UP to by the DMXMLSchema message property.
//
// Parameters:
//   Message - XDTODataObject - an XDTO object of the DMILRequest type. A message from BEFORE.
//
// Returns:
//   String - XML schema of the service BEFORE.
//
Function DMServiceSchemeByMessage(Message)
	
	XMLSchema = "";
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(Message, "DMXMLSchema")
			And ValueIsFilled(Message.DMXMLSchema) Then
		XMLSchema = Message.DMXMLSchema;
	EndIf;
	
	Return XMLSchema;
	
EndFunction

Function TextOfXDTOObjectForLC(XDTODataObject)
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOFactory.WriteXML(XMLWriter, XDTODataObject);
	ObjectText = XMLWriter.Close();
	XMLWriter = Undefined;
	
	NumberOfBinaryData = StrOccurrenceCount(ObjectText, "<binaryData>");
	For EntryNumber = 1 To NumberOfBinaryData Do
		InitialNumber = StrFind(ObjectText, "<binaryData>");
		If InitialNumber = 0 Then
			Break;
		EndIf;
		EndNumber = StrFind(ObjectText, "</binaryData>") + 13;
		CountOfCharacters = EndNumber - InitialNumber;
		
		Substring = Mid(ObjectText, InitialNumber, CountOfCharacters);
		ObjectText = StrReplace(ObjectText, Substring, "<binaryData/>");
	EndDo;
	
	Return Left(ObjectText, 10000);
	
EndFunction

#EndRegion

#Region ConditionalAppearance

// Sets up the Conditional appearance of the stage.
//
Procedure SetUpConditionalAppearanceOfStage(ConditionalAppearance, Tree = "Attendees",
		FormattedField = "LinePresentation")
	
	ConditionalAppearanceItem = ElementOfConditionalAppearanceByPresentation(
		ConditionalAppearance,
		NStr("vi = 'Tách chọn các giai đoạn';
			|ru = 'Выделение этапов';
			|en = 'Select stages'; fa = 'انتخاب مراحل';
			|it = 'Выделение этапов';
			|pl = 'Select stages';
			|tr = 'Aşamaların seçilmesi'"));
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField(Tree + ".ThisIsAStep");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Font");
	AppearanceColorItem.Value = Metadata.StyleItems.ActionStageFont.Value;
	AppearanceColorItem.Use = True;
	
	Field = ConditionalAppearanceItem.Fields.Items.Add();
	Field.Field = New DataCompositionField(FormattedField);
	
EndProcedure

// Sets up the Conditional appearance of an empty participant.
//
Procedure SetUpConditionalAppearanceOfEmptyParticipant(ConditionalAppearance, Tree = "Attendees",
		FormattedField = "LinePresentation", AddConditions = Undefined)
	
	ConditionalAppearanceItem = ElementOfConditionalAppearanceByPresentation(
		ConditionalAppearance,
		NStr("vi = 'Tách chọn người tham gia trống';
			|ru = 'Выделение пустого участника';
			|en = 'Select an empty participant'; fa = 'Select an empty participant';
			|it = 'Выделение пустого участника';
			|pl = 'Select an empty participant';
			|tr = 'Boş katılımcının seçilmesi'"));
		
	DataSelectionGroup = ConditionalAppearanceItem.Filter.Items.Add(
		Type("DataCompositionFilterItemGroup"));
	DataSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	DataFilterItem = DataSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField(Tree + ".Member");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	DataFilterItem.Use = True;
	
	DataFilterItem = DataSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField(Tree + ".ThisIsAStep");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	If AddConditions <> Undefined Then
		For Each AddlCondition In AddConditions Do
			DataFilterItem = DataSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
			FillPropertyValues(DataFilterItem, AddlCondition);
		EndDo;
	EndIf;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	AppearanceColorItem.Value = NStr("vi = '<Chưa chỉ ra>';
									|ru = '<Не указан>';
									|en = '<Not specified>'; fa = '<مشخص نشده>';
									|it = '<non specificato>';
									|pl = '<Nie określono>';
									|tr = '<Belirtilmedi>'");
	AppearanceColorItem.Use = True;
	
	Field = ConditionalAppearanceItem.Fields.Items.Add();
	Field.Field = New DataCompositionField(FormattedField);
	
EndProcedure

// Sets up the Conditional appearance of an empty condition.
//
Procedure SetUpConditionalAppearanceOfEmptyCondition(ConditionalAppearance, Tree = "Attendees",
		FormattedField = "ConditionPresentation")
	
	ConditionalAppearanceItem = ElementOfConditionalAppearanceByPresentation(
		ConditionalAppearance,
		NStr("vi = 'Tách chọn người tham gia trống';
			|ru = 'Выделение пустого условия';
			|en = 'Select an empty condition'; fa = 'Select an empty condition';
			|it = 'Выделение пустого условия';
			|pl = 'Select an empty condition';
			|tr = 'Boş şartın seçilmesi'"));
	
	DataSelectionGroup = ConditionalAppearanceItem.Filter.Items.Add(
		Type("DataCompositionFilterItemGroup"));
	DataSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	DataFilterItem = DataSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField(Tree + ".Condition");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	DataFilterItem.Use = True;
	
	DataFilterItem = DataSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField(Tree + ".ThisIsAStep");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.TextColorOfServiceActionData.Value;
	AppearanceColorItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	AppearanceColorItem.Value = NStr("vi = '<Chưa cài đặt>';
									|ru = '<Не установлено>';
									|en = '<Not set>'; fa = '<Not set>';
									|it = '<Не установлено>';
									|pl = '<Not set>';
									|tr = '<Yapılandırılmadı>'");
	AppearanceColorItem.Use = True;
	
	Field = ConditionalAppearanceItem.Fields.Items.Add();
	Field.Field = New DataCompositionField(FormattedField);
	
EndProcedure

// Sets the Conditional appearance of the participant's fill-in comment.
//
// Parameters:
//   ConditionalAppearance - DataCompositionConditionalAppearance - conditional form design.
//   FieldForFilter - String - the selection field, for example, for the process template card "Object.Performers.The performer."
//   FieldForAppearance - String - the field to be drawn up, for example, for the process template card "Executor".
//
Procedure SetUpConditionalAppearanceOfParticipantSComment(ConditionalAppearance, FieldForFilter, FieldForAppearance)
	
	ItemPresentation = StrTemplate(
		NStr("vi = 'Ghi chú điền người tham gia trong trường: %1';
			|ru = 'Комментарий заполнения участника в поле: %1';
			|en = 'Participant population comment in the field: %1'; fa = 'Participant population comment in the field: %1';
			|it = 'Комментарий заполнения участника в поле: %1';
			|pl = 'Participant population comment in the field: %1';
			|tr = 'Katılımcının alandaki doldurma yorumu: %1'"),
		FieldForFilter);
	
	ConditionalAppearanceItem = ElementOfConditionalAppearanceByPresentation(ConditionalAppearance, ItemPresentation);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField(FieldForFilter);
	DataFilterItem.ComparisonType = DataCompositionComparisonType.BeginsWith;
	DataFilterItem.RightValue = "[";
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = StyleColors.InvalidData;
	AppearanceColorItem.Use = True;
	
	Field = ConditionalAppearanceItem.Fields.Items.Add();
	Field.Field = New DataCompositionField(FieldForAppearance);
	
EndProcedure

Function ElementOfConditionalAppearanceByPresentation(ConditionalAppearance, Presentation)
	
	For Each AppearanceItem In ConditionalAppearance.Items Do
		If AppearanceItem.Presentation = Presentation Then
			AppearanceItem.Filter.Items.Clear();
			AppearanceItem.Fields.Items.Clear();
			Return AppearanceItem;
		EndIf;
	EndDo;
	
	AppearanceItem = ConditionalAppearance.Items.Insert(0);
	AppearanceItem.Presentation = Presentation;
	
	Return AppearanceItem;
	
EndFunction

#EndRegion

// Converts an XDTO list of type DMAllActionStatesAndResultsRows to a table of values.
//
// Parameters:
//   XDTOAction - XDTODataObject - an XDTO object of the type inheriting DMAction.
//
// Returns:
//   ValueTable:
//     * Action - String
//     * ActionID - String
//     * ActionType - String
//     * Function - String
//     * ParticipantID - String
//     * Point_Id - String
//     * State - String
//     * Result - String
//     * Date - Date
//
Function AllStatesAndResults(XDTOAction)
	
	AllStatesAndResults = New ValueTable;
	AllStatesAndResults.Columns.Add("Action", New TypeDescription("String"));
	AllStatesAndResults.Columns.Add("ActionID", New TypeDescription("String"));
	AllStatesAndResults.Columns.Add("ActionType", New TypeDescription("String"));
	AllStatesAndResults.Columns.Add("Function", New TypeDescription("String"));
	AllStatesAndResults.Columns.Add("ParticipantID", New TypeDescription("String"));
	AllStatesAndResults.Columns.Add("Point_Id", New TypeDescription("String"));
	AllStatesAndResults.Columns.Add("State", New TypeDescription("String"));
	AllStatesAndResults.Columns.Add("Result", New TypeDescription("String"));
	AllStatesAndResults.Columns.Add("Date", New TypeDescription("Date"));
	
	For Each XDTORow In XDTOAction.allStatesAndResultsRows.rows Do
		NewRow = AllStatesAndResults.Add();
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow,
			XDTORow.action,
			"Action");
		NewRow.Function = XDTORow.function;
		NewRow.ParticipantID = XDTORow.participantID;
		NewRow.Point_Id = XDTORow.pointID;
		NewRow.State = XDTORow.state;
		NewRow.Result = XDTORow.result;
		NewRow.Date = XDTORow.date;
	EndDo;
	
	Return AllStatesAndResults;
	
EndFunction

Procedure ActionsFromXDTO(XDTODataObject, Rows, NumberOfActions)
	
	If Not IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "actionsRows") Then
		Return;
	EndIf;
	
	For Each XDTORow In XDTODataObject.actionsRows.rows Do
		
		NewRow = Rows.Add();
		
		NewRow.Presentation = XDTORow.presentation;
		NewRow.PresentationStaff = XDTORow.employeesPresentation;
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "dueDateExceeded") Then
			NewRow.DeadlineHasBeenExceeded = XDTORow.dueDateExceeded;
		Else
			NewRow.DeadlineHasBeenExceeded = False;
		EndIf;
		NewRow.DueDatePresentation = XDTORow.dueDatePresentation;
		NewRow.ResultPresentation = XDTORow.statePresentation;
		NewRow.ThereAreReportFiles = XDTORow.haveReportFiles;
		NewRow.ResultIsInText = XDTORow.comment;
		NewRow.DateStateWasSet = XDTORow.statusDate;
		NewRow.StateOfControl = XDTORow.monitoringState;
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "additionalFields") Then
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				NewRow,
				XDTORow.additionalFields.action,
				"Action");
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				NewRow,
				XDTORow.additionalFields.taskAction,
				"TaskAction");
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				NewRow,
				XDTORow.additionalFields.actionType,
				"ActionKind");
			
			NewRow.UnavailableGroup = XDTORow.additionalFields.unavailableGroup;
			NewRow.Unavailable = XDTORow.additionalFields.unavailable;
			NewRow.ThisIsParticipant = XDTORow.additionalFields.itIsParticipant;
			NewRow.ThisIsSubtask = XDTORow.additionalFields.itIsSubtask;
			NewRow.ThisIsAnAction = XDTORow.additionalFields.itIsAction;
			NewRow.CouldnTDereference = XDTORow.additionalFields.failedToDereference;
			NewRow.Will_Be_Deleted = XDTORow.additionalFields.willBeDeleted;
			NewRow.State = XDTORow.additionalFields.state;
			NewRow.Result = XDTORow.additionalFields.result;
			NewRow.PictureNumber = IntegrationWith1CDocumentManagement3ClientServer.NumberOfImageOfResultOfAction(
				NewRow.Result,
				NewRow.State);
			NewRow.PresentationIsClean = XDTORow.additionalFields.cleanPresentation;
			NewRow.DeletionMark = XDTORow.additionalFields.deletionMark;
			
			If ValueIsFilled(XDTORow.additionalFields.id) Then
				NewRow.Id = New UUID(XDTORow.additionalFields.id);
			EndIf;
			
			If NewRow.ThisIsAnAction Then
				NumberOfActions = NumberOfActions + 1;
			EndIf;
		EndIf;
		
		ActionsFromXDTO(XDTORow, NewRow.Rows, NumberOfActions);
		
	EndDo;
	
EndProcedure

Procedure ApplicationTreeFromXDTO(XDTODataObject, Rows, CurCurrentUserAndEmployees)
	
	If Not IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "applicationRows") Then
		Return;
	EndIf;
	
	For Each XDTORow In XDTODataObject.applicationRows.rows Do
		
		If Lower(XDTORow.rowType) = "historyofperform" Then
			Continue;
		EndIf;
		
		NewRow = Rows.Add();
		
		NewRow.ApplicationPresentation = XDTORow.applicationPresentation;
		NewRow.DeletionAvailable = XDTORow.allowDeletion;
		NewRow.Mandatory = XDTORow.mandatoryFilling;
		NewRow.RoleIsMandatory = XDTORow.requiredRole;
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "rowType") Then
			NewRow.RowType = Lower(XDTORow.rowType);
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "applicationRole") Then
			NewRow.RoleOfSubject = Lower(XDTORow.applicationRole);
		EndIf;
		
		NewRow.PictureIndex = XDTORow.imageIndex;
		If NewRow.PictureIndex = -1 Then
			If NewRow.RoleOfSubject = "main" Then
				NewRow.PictureIndex = PictureLib.MainItem16;
				
			ElsIf NewRow.RoleOfSubject = "supplementary" Then
				NewRow.PictureIndex = PictureLib.AuxiliaryItem16;
				
			ElsIf NewRow.RoleOfSubject = "filledin" Then
				NewRow.PictureIndex = PictureLib.PopulatedItem16;
				
			ElsIf NewRow.RowType = "filerole" Then
				// In most cases, UP TO will return the role of the file with the index of the image 2.
				// However, if the file was added incorrectly, for example, with an empty role, you need to display
				// such an empty role as an auxiliary item.
				NewRow.PictureIndex = PictureLib.AuxiliaryItem16;
				
			ElsIf NewRow.RowType = "instruction" Then
				// The instruction comes without a picture.
				
			Else
				NewRow.PictureIndex = PictureLib.AuxiliaryItem16;
				
			EndIf;
		EndIf;
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "application") Then
			If NewRow.RowType = "filerole" Then
				
				NewRow.FileRoleID = XDTORow.application.objectID.ID;
				DocumentLine = IntegrationWith1CDocumentManagement3ClientServer.DocumentLineInApplicationTree(NewRow);
				If DocumentLine <> Undefined Then
					FillPropertyValues(NewRow, DocumentLine, "Application, ApplicationID, ApplicationType");
				EndIf;
				
			Else
				
				IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
					NewRow,
					XDTORow.application,
					"Application");
				NewRow.Ref =
					InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
						NewRow.ApplicationID,
						NewRow.ApplicationType);
				NewRow.URL = XDTORow.application.objectID.navigationRef;
				
				If ValueIsFilled(NewRow.Ref) Then
					// A situation when there are rights to an object in the DO, but not in the IP, should not lead to an exception
					// when selecting tasks. If an exception occurs, we will get a view from BEFORE, and the user
					// will see a "Violation of access rights" only when trying to open the item.
					Try
						NewRow.ApplicationPresentation = StrTemplate(NStr("vi = '%1, đối tượng %2';
																			|ru = '%1, объект %2';
																			|en = '%1, object %2'; fa = '%1, object %2';
																			|it = '%1, объект %2';
																			|pl = '%1, object %2';
																			|tr = '%1, nesne %2'"),
							String(NewRow.Ref),
							IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration());
					Except
						WriteLogEvent(
							IntegrationWith1CDocumentManagementCore.EventLogEventName(
								NStr("vi = 'Lỗi khi nhận trình bày đối tượng liên kết';
									|ru = 'Ошибка при получении представления связанного объекта';
									|en = 'An error occurred when receiving presentation of the linked object'; fa = 'An error occurred when receiving presentation of the linked object';
									|it = 'Errore alla ricezione della presentazione dell''oggetto collegato';
									|pl = 'Błąd przy otrzymaniu prezentacji powiązanego obiektu';
									|tr = 'İlgili nesnenin sunumu alınırken hata'",
									Common.DefaultLanguageCode())),
							EventLogLevel.Error,,
							NewRow.Ref,
							ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					EndTry;
				EndIf;
				
			EndIf;
		ElsIf NewRow.RowType = "task" Then
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				NewRow,
				XDTODataObject,
				"Application");
		EndIf;
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "file") Then
			NewRow.ModificationDate = XDTORow.file.modificationDateUniversal;
			NewRow.SignedWithDS = XDTORow.file.signed;
			NewRow.PresentationHTML = XDTORow.file.htmlView;
			NewRow.PreviewCut = XDTORow.file.htmlViewTruncated;
			NewRow.Extension = XDTORow.file.extension;
			NewRow.DeletionMark = XDTORow.file.deletionMark;
			NewRow.PictureIndex =
				IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(
					NewRow.Extension,
					NewRow.DeletionMark);
			
			NewRow.IsBeingEdited = XDTORow.file.editing;
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow.file, "editingUser") Then
				NewRow.EditedByCurUser =
					IntegrationWith1CDocumentManagementCoreServerCall.FileIsBeingEditedByCurUser(
						XDTORow.file.editingUser.objectID.ID,
						XDTORow.file.editingUser.objectID.type,
						CurCurrentUserAndEmployees);
			Else
				NewRow.EditedByCurUser = False;
			EndIf;
			
			NewRow.Encrypted = XDTORow.file.encrypted;
			NewRow.IsOriginal = XDTORow.file.scannedOriginal;
			
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow.file, "role") Then
				NewRow.FileRoleID = XDTORow.file.role.objectID.id;
			EndIf;
		EndIf;
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "htmlView") Then
			NewRow.PresentationHTML = XDTORow.htmlView;
			NewRow.PreviewCut = False;
		EndIf;
		
		ApplicationTreeFromXDTO(XDTORow, NewRow.Rows, CurCurrentUserAndEmployees);
		
	EndDo;
	
EndProcedure

Procedure AddSuitableObjectsToCreateLinks(AttributeValueIS, SuitableObjects, SettingUpCreationOfLinks,
		ValuesToUpload)
	
	If Not ValueIsFilled(AttributeValueIS) Then
		Return;
	EndIf;
	
	ExistingConnections = SuitableObjects.FindRows(New Structure("Ref", AttributeValueIS));
	For Each ThereIsConnection In ExistingConnections Do
		If ThereIsConnection.LinkType.ID = SettingUpCreationOfLinks.relationType.ObjectID.ID Then
			// There is already such a connection.
			Return;
		EndIf;
	EndDo;
	
	If ValuesToUpload[AttributeValueIS] = Undefined Then
		ValuesToUpload[AttributeValueIS] = New Array;
	EndIf;
	
	LinkedObjectBefore =
		IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
			AttributeValueIS);
	// Even if the value of the IP Attribute already has an associated object in the DO, the integration rule still needs to be selected,
	// because a reference to the DO object is not enough to determine which link creation setting is appropriate.
	IntegrationRule = Undefined;
	SuitableIntegrationRules = IntegrationWith1CDocumentManagement3ServerCall.SuitableObjectIntegrationRules(
		AttributeValueIS,
		True);
	DocumentViewBEFOREFromSettings = "";
	If IntegrationWith1CDocumentManagementCore.PropertySet(SettingUpCreationOfLinks, "documentType") Then
		DocumentViewBEFOREFromSettings = SettingUpCreationOfLinks.documentType.ObjectID.ID;
	EndIf;
	PresentationOfConnectionArray = New Array;
	PresentationOfConnectionArray.Add(SettingUpCreationOfLinks.relationType.name);
	If ValueIsFilled(SettingUpCreationOfLinks.comment) Then
		PresentationOfConnectionArray.Add(SettingUpCreationOfLinks.comment);
	EndIf;
	LinkPresentation = StrConcat(PresentationOfConnectionArray, ", ");
	If SuitableIntegrationRules.Count() = 1 Then
		IntegrationRule = SuitableIntegrationRules[0];
		If IntegrationRule.ObjectTypeDM <> SettingUpCreationOfLinks.objectType.xdtoClassName Then
			ValuesToUpload[AttributeValueIS].Add(StrTemplate(
				NStr("vi = 'Tạo liên kết ""%1"". Kiểu đối tượng DM ""%2"" được chỉ định trong quy tắc tích hợp, không trùng với kiểu đối tượng DM ""%3"" đã chỉ định trong tùy chỉnh tạo tự động liên kết.';
					|ru = 'Создание связи ""%1"". Тип объекта ДО ""%2"", указанный в правиле интеграции, не совпадает с типом объекта ДО ""%3"", указанным в настройке автоматического создания связей.';
					|en = 'Create the ""%1"" link. The ""%2"" DI object type specified in the integration rule does not match the ""%3"" DI object type specified in the automatic link creation setting.'; fa = 'Create the ""%1"" link. The ""%2"" DI object type specified in the integration rule does not match the ""%3"" DI object type specified in the automatic link creation setting.';
					|it = 'Create the ""%1"" link. The ""%2"" DI object type specified in the integration rule does not match the ""%3"" DI object type specified in the automatic link creation setting.';
					|pl = 'Create the ""%1"" link. The ""%2"" DI object type specified in the integration rule does not match the ""%3"" DI object type specified in the automatic link creation setting.';
					|tr = '""%1"" bağlantısının oluşturulması. Entegrasyon kuralında belirtilen ""%2"" İş Akışı nesnesinin türü, otomatik bağlantı oluşturma ayarında belirtilen ""%3"" İş Akışı nesnesinin türüyle eşleşmiyor.'"),
				LinkPresentation,
				IntegrationRule.ObjectTypeDM,
				SettingUpCreationOfLinks.objectType.xdtoClassName));
			IntegrationRule = Undefined;
		EndIf;
		If IntegrationRule.DocumentKindDMID <> DocumentViewBEFOREFromSettings Then
			ValuesToUpload[AttributeValueIS].Add(StrTemplate(
				NStr("vi = 'Tạo liên kết ""%1"". Dạng văn bản ""%2"" được chỉ định trong quy tắc tích hợp, không trùng với dạng văn bản ""%3"" đã chỉ định trng tùy chỉnh tự động tạo liên kết.';
					|ru = 'Создание связи ""%1"". Вид документа ""%2"", указанный в правиле интеграции, не совпадает с видом документа ""%3"", указанным в настройке автоматического создания связей.';
					|en = 'Create the ""%1"" link. The ""%2"" document type specified in the integration rule does not match the ""%3"" document type specified in the automatic link creation setting.'; fa = 'Create the ""%1"" link. The ""%2"" document type specified in the integration rule does not match the ""%3"" document type specified in the automatic link creation setting.';
					|it = 'Create the ""%1"" link. The ""%2"" document type specified in the integration rule does not match the ""%3"" document type specified in the automatic link creation setting.';
					|pl = 'Create the ""%1"" link. The ""%2"" document type specified in the integration rule does not match the ""%3"" document type specified in the automatic link creation setting.';
					|tr = '""%1"" bağlantısının oluşturulması. Entegrasyon kuralında belirtilen ""%2"" belgesinin türü, otomatik bağlantı oluşturma ayarında belirtilen ""%3"" belgesinin türüyle eşleşmiyor.'"),
				LinkPresentation,
				IntegrationRule.DocumentKindDM,
				SettingUpCreationOfLinks.documentType.name));
			IntegrationRule = Undefined;
		EndIf;
	Else
		ValuesToUpload[AttributeValueIS].Add(StrTemplate(
			NStr("vi = 'Tạo liên kết ""%1"". Không thể xác định quy tắc tích hợp phù hợp. Số lượng quy tắc tìm thấy: %2.';
				|ru = 'Создание связи ""%1"". Не удалось определить подходящее правило интеграции. Количество найденных правил: %2.';
				|en = 'Create the ""%1"" link. Cannot identify a suitable integration rule. The quantity of found rules is %2.'; fa = 'Create the ""%1"" link. Cannot identify a suitable integration rule. The quantity of found rules is %2.';
				|it = 'Create the ""%1"" link. Cannot identify a suitable integration rule. The quantity of found rules is %2.';
				|pl = 'Create the ""%1"" link. Cannot identify a suitable integration rule. The quantity of found rules is %2.';
				|tr = '""%1"" bağlantısının oluşturulması. Uygun bir entegrasyon kuralı belirlenemedi. Bulunan kural sayısı: %2.'"),
			LinkPresentation,
			SuitableIntegrationRules.Count()));
	EndIf;
	If IntegrationRule = Undefined Then
		// The link creation setting is not suitable.
		Return;
	EndIf;
	
	SuitableObject = SuitableObjects.Add();
	SuitableObject.Ref = AttributeValueIS;
	SuitableObject.LinkedObjectBefore = LinkedObjectBefore;
	SuitableObject.IntegrationRule = IntegrationRule;
	SuitableObject.LinkType =
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			SettingUpCreationOfLinks.relationType.ObjectID.ID, SettingUpCreationOfLinks.relationType.ObjectID.type);
	SuitableObject.Comment = SettingUpCreationOfLinks.comment;
	
EndProcedure

// Called when the action is initialized.
//
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   XDTOForm - XDTODataObject - an XDTO object of the DMActionForm type.
//   ChangingActionIsAllowed - Boolean
//   Permissions - XDTOList - a list of XDTO of the DMActionPermissionRows type.
//
Procedure FillInTheseActions(Form, XDTOForm, ChangingActionIsAllowed, Permissions)
	
	Items = Form.Items;
	
	Form.Title = XDTOForm.title;
	Form.ReadOnly = XDTOForm.readOnly;
	Form.YouCanOnlyAddMembers = XDTOForm.onlyAddParticipantsIsAvailable;
	Form.YouCanChangeProtectedParticipants = XDTOForm.protectedParticipantsCanBeChanged;
	
	AuthorElement = StructureOfFormInputField(XDTOForm.authorInputField);
	Items.Author.Enabled = AuthorElement.Enabled;
	RecordAndCloseElement = StructureOfFormButton(XDTOForm.buttonDone);
	Items.WriteAndClose.Visible = RecordAndCloseElement.Visible;
	ContinueDialogElement = StructureOfFormButton(XDTOForm.buttonContinue);
	Items.ContinueDialogue.Visible = ContinueDialogElement.Visible;
	Items.ContinueDialogue.DefaultButton = ContinueDialogElement.DefaultButton;
	CloseElement = StructureOfFormButton(XDTOForm.buttonCancel);
	Items.Close.Title = CloseElement.Title;
	Items.Close.DefaultButton = CloseElement.DefaultButton;
	GroupElementCannotBeChanged = FormGroupStructure(XDTOForm.groupNotEditable);
	Items.GroupIsNotAvailableForModification.Visible = GroupElementCannotBeChanged.Visible;
	
	ConditionalAppearance = Form.ConditionalAppearance;
	SetUpConditionalAppearanceOfStage(ConditionalAppearance);
	SetUpConditionalAppearanceOfEmptyParticipant(ConditionalAppearance);
	SetUpConditionalAppearanceOfEmptyCondition(ConditionalAppearance);
	SetUpConditionalAppearanceOfParticipantSComment(
		ConditionalAppearance,
		"Attendees.Member",
		"ParticipantsPresentationOfLine");
	
	// Rights from the subject. If there are rights to the subject, then there are rights to the Action.
	If ChangingActionIsAllowed Then
		PermissionsByTable = Form.FormAttributeToValue("Permissions"); // ValueTable
		For Each XDTOPermission In Permissions Do
			Resolution = PermissionsByTable.Add();
			Resolution.StageID = XDTOPermission.stageID;
			Resolution.Resolution = XDTOPermission.permission;
		EndDo;
		Form.ValueToFormAttribute(PermissionsByTable, "Permissions");
	EndIf;
	
	// Display of the start delay.
	If Items.Find("GroupDescriptionOfDeferredExecution") <> Undefined Then
		Form.DelayedStartOfExecutionDays = XDTOForm.delayedExecutionStartDays;
		Form.DelayedStartOfExecutionHours = XDTOForm.delayedExecutionStartHours;
		Form.DescriptionOfDelayedStartOfExecution = XDTOForm.delayedExecutionStartDescription;
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOForm, "startDateDescription") Then
			Form.LaunchPresentation = XDTOForm.startDateDescription;
		EndIf;
		
		ClearDelayElement = StructureOfFormButton(XDTOForm.buttonClearDelay);
		Form.Commands.ClearDelay.ToolTip = ClearDelayElement.TeamHint;
		Items.ClearDelay.Visible = ClearDelayElement.Visible;
		
		GroupElementDescriptionOfDeferredExecution = FormGroupStructure(XDTOForm.groupDelayedExecutionDescription);
		Items.GroupDescriptionOfDeferredExecution.Visible = GroupElementDescriptionOfDeferredExecution.Visible;
		Items.DeferredAction.Visible = XDTOForm.delayedExecutionPictureVisibility;
		
		ElementDescriptionOfDelayedStartOfExecution = StructureOfLabelField(XDTOForm.delayedExecutionStartLabelField);
		Items.DescriptionOfDelayedStartOfExecution.Enabled = ElementDescriptionOfDelayedStartOfExecution.Enabled;
		Items.DescriptionOfDelayedStartOfExecution.TitleHeight =
			ElementDescriptionOfDelayedStartOfExecution.TitleHeight;
		Items.DescriptionOfDelayedStartOfExecution.ToolTip = ElementDescriptionOfDelayedStartOfExecution.ToolTip;
		Items.DescriptionOfDelayedStartOfExecution.Width = ElementDescriptionOfDelayedStartOfExecution.Width;
		Items.DescriptionOfDelayedStartOfExecution.TitleLocation =
			ElementDescriptionOfDelayedStartOfExecution.TitleLocation;
	EndIf;
	
EndProcedure

Procedure FillInDataFromListOfExpressions(Proxy, ObjectIS, Attributes, TabularSections, ListOfExpressions)
	
	If TypeOf(ListOfExpressions) <> Type("XDTOList") And TypeOf(ListOfExpressions) <> Type("Array") Then
		Raise
			NStr("ru = 'Не удалось получить список выражений, необходимых для выгрузки объекта в 1С:Документооборот.
				|Повторите попытку еще раз.';
				|vi = 'Cannot get the list of expressions required for exporting the object to 1C:Document Management.
				|Try again.';
				|en = 'Cannot get the list of expressions required for exporting the object to 1C:Document Management.
				|Try again.'; fa = 'Cannot get the list of expressions required for exporting the object to 1C:Document Management.
				|Try again.';
				|it = 'Cannot get the list of expressions required for exporting the object to 1C:Document Management.
				|Try again.';
				|pl = 'Cannot get the list of expressions required for exporting the object to 1C:Document Management.
				|Try again.';
				|tr = 'Nesneyi 1C:Document Management’a aktarmak için gerekli ifadelerin listesi alınamadı. 
				|Bir kez daha deneyin.'");
	EndIf;
	
	For Each Expression In ListOfExpressions Do
		
		If TrimAll(Expression.expressionOnBuiltInLanguage) = "" Then
			Raise StrTemplate(
				NStr("vi = 'Chưa đặt nội dung biểu thức bằng ngôn ngữ hệ thống.
					|Tên định danh biểu thức: %1.';
					|ru = 'Не задан текст выражения на встроенном языке.
					|Идентификатор выражения: %1.';
					|en = 'Expression text in 1C:Enterprise language is not specified.
					|Expression ID: %1'; fa = 'Expression text in 1C:Enterprise language is not specified.
					|Expression ID: %1';
					|it = 'Il testo dell''espressione in linguaggio integrato non è impostato.
					|Identificativo dell''espressione: %1.';
					|pl = 'Nie zadano tekstu wyrażenia w języku wbudowanym.
					|Identyfikator wyrażenia: %1.';
					|tr = 'Yerleşik dildeki ifadenin metni belirtilmedi.
					| İfade tanımlayıcısı: %1.'"),
				Expression.id);
		EndIf;
		
		If Expression.type = "Attribute" Then
			// An expression for filling in the Attributes. We execute it once, put it in attributes.
			ResultOfExpression = ResultOfExpressionInEmbeddedLanguage(
				Expression.expressionOnBuiltInLanguage,
				ObjectIS);
			Attributes.Add(
				ConvertAttributeOfObjectToXDTOObject(
					Proxy, Expression.id, ResultOfExpression, Expression.expressionOnBuiltInLanguage));
			
		ElsIf Expression.type = "TabularSection" Then
			// An expression for filling in the table part. We execute it once, put it in tabularSections.
			ResultOfExpression = ResultOfExpressionInEmbeddedLanguage(
				Expression.expressionOnBuiltInLanguage,
				ObjectIS); // ValueTable
			TabularSections.Add(ConvertWISObjectTableToXDTOObject(
				Proxy,
				Expression.id,
				ResultOfExpression,
				ResultOfExpression.Columns,
				Expression.expressionOnBuiltInLanguage));
			
		ElsIf Expression.type = "TabularSectionAttribute" Then
			// Expression for filling in the Attributes tab. parts.
			ResultTable1 = New ValueTable;
			ResultTable1.Columns.Add("Result");
			
			If Expression.tabularSectionName = "" Then
				// Option: according to the rules for individual Attributes.
				// We execute it once, put it in attributes.
				ResultOfExpression = ResultOfExpressionInEmbeddedLanguage(
					Expression.expressionOnBuiltInLanguage,
					ObjectIS);
				ResultRow = ResultTable1.Add();
				ResultRow.Result = ResultOfExpression;
				
			Else
				// Option: from the source table.
				// We perform it repeatedly for each line of the source, put it in tabularSections.
				For Each CurrentRow In ObjectIS[Expression.tabularSectionName] Do
					ResultOfExpression = ResultOfExpressionInEmbeddedLanguage(
						Expression.expressionOnBuiltInLanguage,
						ObjectIS,,
						CurrentRow);
					ResultRow = ResultTable1.Add();
					ResultRow.Result = ResultOfExpression;
				EndDo;
				
			EndIf;
			
			TabularSections.Add(ConvertWISObjectTableToXDTOObject(
				Proxy,
				Expression.id,
				ResultTable1,
				ResultTable1.Columns,
				Expression.expressionOnBuiltInLanguage));
			
		Else
			Raise StrTemplate(
				NStr("vi = 'Chưa đặt phương án thực thi biểu thức bằng ngôn ngữ hệ thống.
					|Tên định danh biểu thức: %1.';
					|ru = 'Не задан вариант выполнения выражения на встроенном языке.
					|Идентификатор выражения: %1.';
					|en = 'Option of expression execution in 1C:Enterprise language is not specified.
					|Expression ID: %1.'; fa = 'Option of expression execution in 1C:Enterprise language is not specified.
					|Expression ID: %1.';
					|it = 'L''opzione per eseguire l''espressione in linguaggio integrato non è impostata.
					|Identificativo dell''espressione: %1.';
					|pl = 'Nie zadano wariantu wykonania wyrażenia w języku wbudowanym.
					|Identyfikator wyrażenia: %1.';
					|tr = 'İfadenin yerleşik dilde yürütme seçeneği belirtilmedi.
					|İfade tanımlayıcısı: %1.'"),
				Expression.id);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInInteractiveAction(Proxy, InteractiveAction, InteractiveXDTOAction)
	
	If Lower(InteractiveXDTOAction.interactiveAction) = "backtothetask" Then
		InteractiveAction.BackToTask = True;
		
	ElsIf Lower(InteractiveXDTOAction.interactiveAction) = "selecttaskperformer" Then
		InteractiveAction.SelectTaskExecutor = True;
		InteractiveAction.Context = IntegrationWith1CDocumentManagementCore.XDTOObjectInString(
			Proxy,
			InteractiveXDTOAction.context);
		
	ElsIf Lower(InteractiveXDTOAction.interactiveAction) = "askaquestion" Then
		InteractiveAction.AskRandomQuestion = True;
		InteractiveAction.Context = StructureOfQuestionToUser(InteractiveXDTOAction.context);
		
	ElsIf Lower(InteractiveXDTOAction.interactiveAction) = "cyclelimitexhaustquestion" Then
		InteractiveAction.AskQuestionAboutCycleLimit = True;
		InteractiveAction.Context = StructureOfQuestionToUser(InteractiveXDTOAction.context);
		
	ElsIf Lower(InteractiveXDTOAction.interactiveAction) = "changeprocessparameters" Then
		InteractiveAction.ChangeProcessParameters = True;
		InteractiveAction.Context = New Structure("ActionID, ActionType",
			InteractiveXDTOAction.context.id, InteractiveXDTOAction.context.type);
		
	ElsIf Lower(InteractiveXDTOAction.interactiveAction) = "performsigning" Then
		InteractiveAction.PerformSigning = True;
		InteractiveAction.Context = New Structure;
		InteractiveAction.Context.Insert("CompletionDate", InteractiveXDTOAction.context.executionDate);
		InteractiveAction.Context.Insert("Operation", InteractiveXDTOAction.context.operation);
		InteractiveAction.Context.Insert("DataTitle", InteractiveXDTOAction.context.title);
		InteractiveAction.Context.Insert("SigningObjects", New Array);
		For Each DataAndSignature In InteractiveXDTOAction.context.dataAndSignatureList Do
			ObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				DataAndSignature.object.ID,
				DataAndSignature.object.type,,
				DataAndSignature.object.presentation);
			InteractiveAction.Context.SigningObjects.Add(
				New Structure("ObjectBefore, Data", ObjectBefore, DataAndSignature.binaryData));
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillInAttributesFromMetadata(Proxy, ReceiverAttributes, AttributesSource, ObjectIS,
		TheseAreStandardAttributes = False, TheseAreAdditionalAttributes = False)
	
	For Each Attribute In AttributesSource Do
		If TheseAreAdditionalAttributes Then
			AttributeName = IntegrationWith1CDocumentManagementCore.NameOfAdditionalProps(Attribute);
			Value = PropertyManager.PropertyValue(ObjectIS.Ref, Attribute);
		Else
			AttributeName = Attribute.Name;
			Value = ObjectIS[Attribute.Name];
		EndIf;
		
		If AttributeName = "" Then
			Continue;
		EndIf;
		
		ReceiverAttributes.Add(ConvertAttributeOfObjectToXDTOObject(Proxy, AttributeName, Value));
	EndDo;
	
EndProcedure

// It is used to automatically add links to links from the IP object when it is uploaded to the DO.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   LinksToCreation - Array of See IntegrationWith1CDocumentManagementCoreClientServer.ConnectionToCreation
//   ObjectIS - AnyRef - a reference to the original IP object.
//   ListOfAutomaticallyAddedLinks - XDTOList - a list of link creation settings specified in the rules
//     for uploading data to the DO.
//   NewObjectsBefore - Array of See IntegrationWith1CDocumentManagement3ClientServer.NewObjectBefore
//
Procedure FillInListOfLinksToCreate(Proxy, LinksToCreation, ObjectIS, ListOfAutomaticallyAddedLinks,
		NewObjectsBefore)
	
	If NewObjectsBefore = Undefined Then
		NewObjectsBefore = New Array;
	EndIf;
	
	If ListOfAutomaticallyAddedLinks = Undefined
			Or ListOfAutomaticallyAddedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	EventName = NStr("vi = 'Tự động tạo đối tượng liên kết';
					|ru = 'Автоматическое создание связанного объекта';
					|en = 'Automatic creation of linked object'; fa = 'Automatic creation of linked object';
					|it = 'Creazione automatica dell''oggetto collegato';
					|pl = 'Automatyczne tworzenie powiązanego obiektu';
					|tr = 'İlgili nesnenin otomatik olarak oluşturulması'");
	
	Try
		
		SuitableObjectsForAddingLinks = SuitableObjectsForAddingLinks(
			ObjectIS,
			ListOfAutomaticallyAddedLinks,
			EventName);
		For Each SuitableObject In SuitableObjectsForAddingLinks Do
			
			ConnectionToCreation = IntegrationWith1CDocumentManagementCoreClientServer.ConnectionToCreation();
			
			If SuitableObject.LinkedObjectBefore = Undefined Then
				// Create a new object in the DO.
				NewObjectBEFOREOrMessage = CreateMapItemUsingRule(
					Proxy,
					SuitableObject.Ref,
					SuitableObject.IntegrationRule,,,
					NewObjectsBefore);
				If TypeOf(NewObjectBEFOREOrMessage) = Type("XDTODataObject") Then
					ConnectionToCreation.RefTo = NewObjectBEFOREOrMessage.name;
					ConnectionToCreation.RefToID = NewObjectBEFOREOrMessage.objectID.ID;
					ConnectionToCreation.RefToType = NewObjectBEFOREOrMessage.objectID.type;
					NewObjectBefore = IntegrationWith1CDocumentManagement3ClientServer.NewObjectBefore(
						NewObjectBEFOREOrMessage.objectID.ID,
						NewObjectBEFOREOrMessage.objectID.type,
						SuitableObject.Ref);
					NewObjectsBefore.Add(NewObjectBefore);
				Else
					ErrorText = StrTemplate(
						NStr("vi = 'Không thể kết xuất đối tượng ""%1"" sang 1C:Document Management:
							|%2';
							|ru = 'Не удалось выгрузить объект ""%1"" в 1С:Документооборот:
							|%2';
							|en = 'Cannot export the ""%1"" object to 1C:Document Management:
							|%2'; fa = 'Cannot export the ""%1"" object to 1C:Document Management:
							|%2';
							|it = 'Cannot export the ""%1"" object to 1C:Document Management:
							|%2';
							|pl = 'Cannot export the ""%1"" object to 1C:Document Management:
							|%2';
							|tr = '""%1"" nesnesi 1C:Document Management''e yüklenemedi çünkü:
							|%2'"),
						SuitableObject.Ref,
						NewObjectBEFOREOrMessage);
					IntegrationWith1CDocumentManagementCore.WriteError(ErrorText, EventName);
					Continue;
				EndIf;
			Else
				// Add a link to an existing object BEFORE.
				ConnectionToCreation.RefTo = SuitableObject.LinkedObjectBefore.name;
				ConnectionToCreation.RefToID = SuitableObject.LinkedObjectBefore.ID;
				ConnectionToCreation.RefToType = SuitableObject.LinkedObjectBefore.type;
			EndIf;
			
			ConnectionToCreation.LinkTypeID = SuitableObject.LinkType.ID;
			
			ConnectionToCreation.Comment = SuitableObject.Comment;
			
			LinksToCreation.Add(ConnectionToCreation);
			
		EndDo;
		
	Except
		
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		IntegrationWith1CDocumentManagementCore.WriteError(ErrorText, EventName);
		
	EndTry
	
EndProcedure

// Returns the structure of additional task data.
//
// Parameters:
//   ScopeOfXDTO - XDTODataObject - an XDTO object of type DMTaskActionArea.
//   Flag - String - flag name, takes the values of the DMObjectFlag enumeration (http://www.1c.ru/dm ).
//
// Returns:
//   See NewTaskScope
//
Function ScopeOfTask(ScopeOfXDTO, Flag)
	
	Scope = NewTaskScope();
	
	Scope.PerformTaskActionOption1 =
		StructureOfFormButton(ScopeOfXDTO.buttonExecuteOption1);
	Scope.PerformTaskActionOption2 =
		StructureOfFormButton(ScopeOfXDTO.buttonExecuteOption2);
	Scope.PerformTaskActionOption3 =
		StructureOfFormButton(ScopeOfXDTO.buttonExecuteOption3);
	
	Scope.PerformTemplateTaskAction1 =
		StructureOfFormButton(ScopeOfXDTO.buttonExecuteByTemplateOption1);
	Scope.PerformTemplateTaskAction2 =
		StructureOfFormButton(ScopeOfXDTO.buttonExecuteByTemplateOption2);
	Scope.PerformTemplateTaskAction3 =
		StructureOfFormButton(ScopeOfXDTO.buttonExecuteByTemplateOption3);
	
	Scope.SelectTemplateForTask =
		StructureOfFormButton(ScopeOfXDTO.buttonSelectTaskTemplate);
	Scope.PerformConnectedTaskAction1 =
		StructureOfFormButton(ScopeOfXDTO.buttonExecuteConnectedTaskAction1);
	Scope.CancelExecution =
		StructureOfFormButton(ScopeOfXDTO.buttonUndoExecution);
	
	Scope.DataVersionOfTaskAction = ScopeOfXDTO.dataVersion;
	Scope.ResultOfActionInText = ScopeOfXDTO.actionResultString;
	Scope.ResultOfActionIsInputField =
		StructureOfFormInputField(ScopeOfXDTO.actionResultInputField);
	Scope.FlagsSubmenu = FormGroupStructure(ScopeOfXDTO.flagsSubmenu);
	Scope.Flag = Flag;
	Scope.TakeToWork = StructureOfFormButton(ScopeOfXDTO.buttonAcceptTask);
	Scope.CancelTakingToWork = StructureOfFormButton(ScopeOfXDTO.buttonRevokeTaskAcceptance);
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ScopeOfXDTO, "buttonAddParticipants") Then
		Scope.AddParticipants = StructureOfFormButton(ScopeOfXDTO.buttonAddParticipants);
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ScopeOfXDTO, "processingAction") Then
		Scope.ProcessingAction = ScopeOfXDTO.processingAction.name;
		Scope.ProcessingActionID = ScopeOfXDTO.processingAction.objectID.id;
		Scope.ProcessingActionType = ScopeOfXDTO.processingAction.objectID.type;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ScopeOfXDTO, "resultOfOption1") Then
		Scope.ResultOfOption1 = ScopeOfXDTO.resultOfOption1.name;
		Scope.ResultOfOption1ID = ScopeOfXDTO.resultOfOption1.objectID.id;
		Scope.ResultOfOption1Type = ScopeOfXDTO.resultOfOption1.objectID.type;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ScopeOfXDTO, "resultOfOption2") Then
		Scope.ResultOfOption2 = ScopeOfXDTO.resultOfOption2.name;
		Scope.ResultOfOption2ID = ScopeOfXDTO.resultOfOption2.objectID.id;
		Scope.ResultOfOption2Type = ScopeOfXDTO.resultOfOption2.objectID.type;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ScopeOfXDTO, "resultOfOption3") Then
		Scope.ResultOfOption3 = ScopeOfXDTO.resultOfOption3.name;
		Scope.ResultOfOption3ID = ScopeOfXDTO.resultOfOption3.objectID.id;
		Scope.ResultOfOption3Type = ScopeOfXDTO.resultOfOption3.objectID.type;
	EndIf;
	
	Return Scope;
	
EndFunction

// Updates the form group.
//
// Parameters:
//   FormGroup - FormGroup
//   FormGroupParameters - See FormGroupStructure
//
Procedure UpdateFormGroup(FormGroup, FormGroupParameters)
	
	FormGroup.Visible = FormGroupParameters.Visible;
	FormGroup.Enabled = FormGroupParameters.Enabled;
	FormGroup.Title = FormGroupParameters.Title;
	
EndProcedure

Procedure UpdateButtonInScope(ButtonOnForm, ButtonCommand, ButtonParameters, ToChangeFont)
	
	ButtonOnForm.Visible = ButtonParameters.Visible;
	ButtonOnForm.Enabled = ButtonParameters.Enabled;
	ButtonOnForm.Title = ButtonParameters.Title;
	ButtonOnForm.TextColor = ButtonParameters.TextColor;
	ButtonOnForm.TitleHeight = ButtonParameters.TitleHeight;
	If ToChangeFont Then
		ButtonOnForm.Font = ButtonParameters.Font;
	EndIf;
	
	If ButtonParameters.TeamHint <> Undefined Then
		ButtonCommand.ToolTip = ButtonParameters.TeamHint;
	Else
		ButtonCommand.ToolTip = "";
	EndIf;
	
EndProcedure

Procedure UpdateFormButton(ButtonOnForm, ButtonParameters)
	
	If ButtonParameters <> Undefined Then
		ButtonOnForm.Visible = ButtonParameters.Visible;
		ButtonOnForm.Enabled = ButtonParameters.Enabled;
		ButtonOnForm.Title = ButtonParameters.Title;
		ButtonOnForm.TitleHeight = ButtonParameters.TitleHeight;
	Else
		ButtonOnForm.Visible = False;
	EndIf;
	
EndProcedure

Procedure UpdateInputFieldInScope(InputFieldOnForm, InputFieldParameters)
	
	InputFieldOnForm.Visible = InputFieldParameters.Visible;
	InputFieldOnForm.ReadOnly = InputFieldParameters.ReadOnly;
	InputFieldOnForm.InputHint = InputFieldParameters.InputHint;
	
EndProcedure

// generates a Presentation of the value for quick search.
//
// Parameters:
//   Value - String
//            - Date
//            - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//            - ValueList of See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
// Returns:
//   String - description.
//
Function ValuePresentation(Value)
	
	ValuePresentation = "";
	TypeValue = TypeOf(Value);
	
	If TypeValue = Type("ValueList") Then
		
		PresentationArray = New Array;
		For Each ListItem In Value Do
			PresentationArray.Add(ValuePresentation(ListItem.Value));
		EndDo;
		ValuePresentation = StrConcat(PresentationArray, "; ");
		
	ElsIf TypeValue = Type("Structure") Then
		
		ValuePresentation = Value.Description;
		
	ElsIf TypeValue = Type("Date") Then
		
		ValuePresentation = Format(Value, "DLF=D");
		
	ElsIf TypeValue = Type("String") Then
		
		FlagData = FlagData(Value);
		If FlagData.PictureIndex > 0 Then
			// It's a flag.
			ValuePresentation = FlagData.Presentation;
		Else
			ValuePresentation = String(Value);
		EndIf;
		
	Else
		
		ValuePresentation = String(Value);
		
	EndIf;
	
	Return ValuePresentation;
	
EndFunction

Function ConvertAttributeOfObjectToXDTOObject(Proxy, AttributeName, AttributeValue, Expression = "")
	
	Result = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMDataAttribute");
	Result.name = AttributeName;
	
	AttributeType = TypeOf(AttributeValue);
	
	If AttributeType = Type("Undefined") Or AttributeType = Type("Null") Then
		// We leave the value property not set.
		Return Result;
		
	ElsIf AttributeType = Type("XDTODataObject") Then
		CopyXDTOObject(Result.value, AttributeValue, Proxy);
		
	ElsIf Common.IsReference(AttributeType) Then
		If AttributeValue.IsEmpty() Then
			// We leave the value property not set.
			Return Result;
		Else
			TypeNameXDTO = IntegrationWith1CDocumentManagementCoreServerCall.TypeNameXDTO(
				Metadata.FindByType(AttributeType).FullName());
			If TypeNameXDTO = "" Then
				TypeNameXDTO = "DMObject";
			EndIf;
			
			Result.value = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				TypeNameXDTO,
				AttributeValue);
		EndIf;
		
	ElsIf AttributeType = Type("String")
			Or AttributeType = Type("Number")
			Or AttributeType = Type("Date")
			Or AttributeType = Type("Boolean") Then
		Result.value = AttributeValue;
		
	ElsIf AttributeType = Type("UUID") Then
		Result.value = String(AttributeValue);
		
	Else
		ErrorText = New Array;
		ErrorText.Add(NStr("ru = 'Ошибка формирования структуры загружаемых в 1С:Документооборот данных.';
							|vi = 'An error occurred while generating the structure of data imported to 1C:Document Management.';
							|en = 'An error occurred while generating the structure of data imported to 1C:Document Management.'; fa = 'An error occurred while generating the structure of data imported to 1C:Document Management.';
							|it = 'An error occurred while generating the structure of data imported to 1C:Document Management.';
							|pl = 'An error occurred while generating the structure of data imported to 1C:Document Management.';
							|tr = '1C:Document Management''a içe aktarılan verilerin yapısı oluşturulurken hata.'"));
		If ValueIsFilled(Expression) Then
			ErrorText.Add(StrTemplate(
				NStr("ru = 'Невозможно выгрузить данные из результата выражения на встроенном языке.
					|Тип результата: ""%1"".
					|Текст выражения на встроенном языке:
					|%2';
					|vi = 'Cannot export data from the result of an expression in the 1C:Enterprise language.
					|Result type: ""%1"".
					|Expression text in the 1C:Enterprise language:
					|%2';
					|en = 'Cannot export data from the result of an expression in the 1C:Enterprise language.
					|Result type: ""%1"".
					|Expression text in the 1C:Enterprise language:
					|%2'; fa = 'Cannot export data from the result of an expression in the 1C:Enterprise language.
					|Result type: ""%1"".
					|Expression text in the 1C:Enterprise language:
					|%2';
					|it = 'Cannot export data from the result of an expression in the 1C:Enterprise language.
					|Result type: ""%1"".
					|Expression text in the 1C:Enterprise language:
					|%2';
					|pl = 'Cannot export data from the result of an expression in the 1C:Enterprise language.
					|Result type: ""%1"".
					|Expression text in the 1C:Enterprise language:
					|%2';
					|tr = 'Yerleşik dildeki ifade sonucundan veriler dışa aktarılamıyor. 
					| Sonuç türü: ""%1"". 
					| Yerleşik dildeki ifade metni: 
					|%2'"),
				AttributeType,
				Expression));
		Else
			ErrorText.Add(StrTemplate(
				NStr("vi = 'Cần kết xuất dữ liệu từ mục tin ""%1"" có kiểu ""%2"".';
					|ru = 'Невозможно выгрузить данные из реквизита ""%1"" с типом ""%2"".';
					|en = 'Cannot export data from the ""%1"" attribute with the ""%2"" type.'; fa = 'Cannot export data from the ""%1"" attribute with the ""%2"" type.';
					|it = 'Impossibile scaricare i dati dall''attributo ""%1"" con il tipo ""%2"".';
					|pl = 'Nie można wyeksportować dane z atrybutu ""%1"" o typie ""%2"".';
					|tr = '""%2"" türünde ""%1"" öznitelik verilerinin dışa aktarılması mümkün değil.'"),
				AttributeName,
				AttributeType));
		EndIf;
		Result.error = StrConcat(ErrorText, Chars.LF);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ConvertWISObjectTableToXDTOObject(Proxy, TableName, ValueTable, Columns, Expression = "")
	
	Result = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMDataTabularSection");
	Result.name = TableName;
	Rows = Result.rows; // XDTOList
	
	For Each String In ValueTable Do
		XDTORow = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMDataTabularSectionRow");
		LineDetails = XDTORow.attributes; // XDTOList
		
		For Each Column In Columns Do
			LineDetails.Add(
				ConvertAttributeOfObjectToXDTOObject(Proxy, Column.Name, String[Column.Name], Expression));
		EndDo;
		
		Rows.Add(XDTORow);
	EndDo;
	
	Return Result;
	
EndFunction

// Constructor of the form group structure.
//
// Parameters:
//   XDTOFormGroup - XDTODataObject - an XDTO object of the DMFormGroup type:
//     * visible - Boolean
//     * enabled - Boolean
//     * title - String
//
// Returns:
//   Structure:
//     * Visible - Boolean
//     * Enabled - Boolean
//     * Title - String
//
Function FormGroupStructure(XDTOFormGroup)
	
	FormGroupStructure = New Structure;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFormGroup, "visible") Then
		FormGroupStructure.Insert("Visible", XDTOFormGroup.visible);
	Else
		FormGroupStructure.Insert("Visible", True);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFormGroup, "enabled") Then
		FormGroupStructure.Insert("Enabled", XDTOFormGroup.enabled);
	Else
		FormGroupStructure.Insert("Enabled", True);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFormGroup, "title") Then
		FormGroupStructure.Insert("Title", XDTOFormGroup.title);
	Else
		FormGroupStructure.Insert("Title", "");
	EndIf;
	
	Return FormGroupStructure;
	
EndFunction

// Constructor of the form button structure.
//
// Parameters:
//   XDTOButton - XDTODataObject - XDTO object of type DMButton:
//     * visible - Boolean
//     * enabled - Boolean
//     * title - String
//     * titleHeight - Number
//     * defaultButton - Boolean
//     * hint - String
//     * textColor - String
//     * font - String
//
// Returns:
//   Structure:
//     * Visible - Boolean
//     * Enabled - Boolean
//     * Title - String
//     * TitleHeight - Number
//     * DefaultButton - Boolean
//     * TeamHint - String
//                        - Undefined
//     * TextColor - Color
//     * Font - Font
//
Function StructureOfFormButton(XDTOButton)
	
	StructureOfFormButton = New Structure;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOButton, "visible") Then
		StructureOfFormButton.Insert("Visible", XDTOButton.visible);
	Else
		StructureOfFormButton.Insert("Visible", True);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOButton, "enabled") Then
		StructureOfFormButton.Insert("Enabled", XDTOButton.enabled);
	Else
		StructureOfFormButton.Insert("Enabled", True);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOButton, "title") Then
		StructureOfFormButton.Insert("Title", XDTOButton.title);
	Else
		StructureOfFormButton.Insert("Title", "");
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOButton, "titleHeight") Then
		StructureOfFormButton.Insert("TitleHeight", XDTOButton.titleHeight);
	Else
		StructureOfFormButton.Insert("TitleHeight", 0);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOButton, "defaultButton") Then
		StructureOfFormButton.Insert("DefaultButton", XDTOButton.defaultButton);
	Else
		StructureOfFormButton.Insert("DefaultButton", False);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOButton, "hint") Then
		StructureOfFormButton.Insert("TeamHint", XDTOButton.hint);
	Else
		StructureOfFormButton.Insert("TeamHint", Undefined);
	EndIf;
	
	TextColor = New Color;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOButton, "textColor") Then
		If XDTOButton.textColor = "Positive" Then
			TextColor = StyleColors.PositiveTaskCompletionFlag;
		ElsIf XDTOButton.textColor = "Negative" Then
			TextColor = StyleColors.NegativeTaskCompletionFlag;
		EndIf;
	EndIf;
	StructureOfFormButton.Insert("TextColor", TextColor);
	
	Font = New Font;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOButton, "font") Then
		If XDTOButton.font = "Normal" Then
			Font = StyleFonts.FontForTaskExecutionButtonStandard;
		ElsIf XDTOButton.font = "Small" Then
			Font = StyleFonts.FontForTaskExecutionButtonSmall;
		EndIf;
	EndIf;
	StructureOfFormButton.Insert("Font", Font);
	
	Return StructureOfFormButton;
	
EndFunction

// Constructor for the structure of the form input field.
//
// Parameters:
//   XDTOInputField - XDTODataObject - XDTO object of type DMInputField:
//     * visible - Boolean
//     * enabled - Boolean
//     * readOnly - Boolean
//     * inputHint - String
//
// Returns:
//   Structure:
//     * Visible - Boolean
//     * Enabled - Boolean
//     * ReadOnly - Boolean
//     * InputHint - String
//
Function StructureOfFormInputField(XDTOInputField)
	
	StructureOfFormInputField = New Structure;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOInputField, "visible") Then
		StructureOfFormInputField.Insert("Visible", XDTOInputField.visible);
	Else
		StructureOfFormInputField.Insert("Visible", True);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOInputField, "enabled") Then
		StructureOfFormInputField.Insert("Enabled", XDTOInputField.enabled);
	Else
		StructureOfFormInputField.Insert("Enabled", True);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOInputField, "readOnly") Then
		StructureOfFormInputField.Insert("ReadOnly", XDTOInputField.readOnly);
	Else
		StructureOfFormInputField.Insert("ReadOnly", False);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOInputField, "inputHint") Then
		StructureOfFormInputField.Insert("InputHint", XDTOInputField.inputHint);
	Else
		StructureOfFormInputField.Insert("InputHint", "");
	EndIf;
	
	Return StructureOfFormInputField;
	
EndFunction

// Constructor of the field structure of the image.
//
// Parameters:
//   XDTOImageField - XDTODataObject - an XDTO object of the DMPictureField type:
//     * visible - Boolean
//     * hint - String
//     * imageIndex - Number
//
// Returns:
//   Structure:
//     * Visible - Boolean
//     * ToolTip - String
//     * PictureIndex - Number
//
Function StructureOfImageField(XDTOImageField)
	
	StructureOfImageField = New Structure;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOImageField, "visible") Then
		StructureOfImageField.Insert("Visible", XDTOImageField.visible);
	Else
		StructureOfImageField.Insert("Visible", True);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOImageField, "hint") Then
		StructureOfImageField.Insert("ToolTip", XDTOImageField.hint);
	Else
		StructureOfImageField.Insert("ToolTip", "");
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOImageField, "imageIndex") Then
		StructureOfImageField.Insert("PictureIndex", XDTOImageField.imageIndex);
	Else
		StructureOfImageField.Insert("PictureIndex", -1);
	EndIf;
	
	Return StructureOfImageField;
	
EndFunction

// Constructor of the label field structure.
//
// Parameters:
//   XDTOLabelField - XDTODataObject - XDTO object of type DMLabelField:
//     * enabled - Boolean
//     * titleHeight - Number
//     * hint - String
//     * width - Number
//     * titleLocation - String
//
// Returns:
//   Structure:
//     * Enabled - Boolean
//     * TitleHeight - Number
//     * ToolTip - String
//     * Width - Number
//     * TitleLocation - FormItemTitleLocation
//
Function StructureOfLabelField(XDTOLabelField)
	
	StructureOfLabelField = New Structure;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOLabelField, "enabled") Then
		StructureOfLabelField.Insert("Enabled", XDTOLabelField.enabled);
	Else
		StructureOfLabelField.Insert("Enabled", True);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOLabelField, "titleHeight") Then
		StructureOfLabelField.Insert("TitleHeight", XDTOLabelField.titleHeight);
	Else
		StructureOfLabelField.Insert("TitleHeight", 0);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOLabelField, "hint") Then
		StructureOfLabelField.Insert("ToolTip", XDTOLabelField.hint);
	Else
		StructureOfLabelField.Insert("ToolTip", "");
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOLabelField, "width") Then
		StructureOfLabelField.Insert("Width", XDTOLabelField.width);
	Else
		StructureOfLabelField.Insert("Width", 0);
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOLabelField, "titleLocation") Then
		If XDTOLabelField.titleLocation = "Auto" Then
			HeaderLocation = FormItemTitleLocation.Auto;
			
		ElsIf XDTOLabelField.titleLocation = "Top" Then
			HeaderLocation = FormItemTitleLocation.Top;
			
		ElsIf XDTOLabelField.titleLocation = "Left" Then
			HeaderLocation = FormItemTitleLocation.Left;
			
		ElsIf XDTOLabelField.titleLocation = "None" Then
			HeaderLocation = FormItemTitleLocation.None;
			
		ElsIf XDTOLabelField.titleLocation = "Bottom" Then
			HeaderLocation = FormItemTitleLocation.Bottom;
			
		ElsIf XDTOLabelField.titleLocation = "Right" Then
			HeaderLocation = FormItemTitleLocation.Right;
			
		EndIf;
	Else
		HeaderLocation = FormItemTitleLocation.Auto;
	EndIf;
	StructureOfLabelField.Insert("TitleLocation", HeaderLocation);
	
	Return StructureOfLabelField;
	
EndFunction

Function ParticipantStringStructure()
	
	Return New Structure(
		"Id, Member, MemberID, MemberType, MemberPresentation,
		|MainAddressingObjectMember, MainAddressingObjectMemberID, MainAddressingObjectMemberType,
		|AdditionalAddressingObjectParticipant, AdditionalAddressingObjectParticipantID,
		|AdditionalAddressingObjectParticipantType,
		|Condition, ConditionID, ConditionType, ConditionPresentation, LongDesc, DescriptionIsSpecial,
		|DueDate, Term_Days, TermHours, TermMinutes, FromSettings,
		|IsProtected, ProtectedInSetting, OptionForSettingDeadline, DueDatePresentation,
		|LinePresentation, StageID, Point_Id,
		|SuperiorMember, TermIsGeneral, TaskDescription,
		|ProjectResolution, PresentationOfResolution, ThereIsResolution, EmployeeResponsible, ParticipantFunction, Number,
		|DataSource, DataSourceID, DataSourceType, DataSourcePresentation,
		|Inspector, InspectorID, InspectorType, InspectorPresentation,
		|MainAddressingObjectInspector, MainAddressingObjectInspectorID, MainAddressingObjectInspectorType,
		|AdditionalAddressingObjectController, AdditionalAddressingObjectControllerID,
		|AdditionalAddressingObjectControllerType,
		|Organization, OrganizationID, OrganizationType,
		|Author, AuthorID, AuthorType, AuthorPresentation,
		|OrderOfExecutionByParticipants, GradeC, RankBy,
		|ResolutionProcessingTime, DeadlineForProcessingResolutionIsDays, ResolutionProcessingTimeHours, ProcessingTimeOfResolutionIsMinutes,
		|ResolutionProcessingTimePresentation, OptionForSettingResolutionProcessingTime");
	
EndFunction

// Returns the date string of the processing event formatted according to the principle:
//   - 10:35, if the event occurred today
//   - 03/11/2026 10:35, if the event did not occur today
//
// Parameters:
//   EventDate - Date - date of the event.
//
// Returns:
//   String
//
Function FormattedDateOfProcessingEvent(EventDate)
	
	CurrentTime = CurrentSessionDate();
	EventHappenedToday = (BegOfDay(EventDate) = BegOfDay(CurrentTime));
	
	If EventHappenedToday Then
		DateFormat = NStr("ru = 'ДФ=''HH:mm''';
							|vi = 'DF=''HH:mm''';
							|en = 'DF=''HH:mm'''; fa = 'DF=''HH:mm''';
							|it = 'DF=''HH:mm''';
							|pl = 'DF=''HH:mm''';
							|tr = 'DF=''HH:mm'''");
	Else
		DateFormat = NStr("ru = 'ДФ=''dd.MM.yyyy HH:mm''';
							|vi = 'DF=''MM/dd/yyyy hh:mm tt''';
							|en = 'DF=''MM/dd/yyyy hh:mm tt'''; fa = 'DF=''MM/dd/yyyy hh:mm tt''';
							|it = 'DF=''MM/dd/yyyy hh:mm tt''';
							|pl = 'DF=''MM/dd/yyyy hh:mm tt''';
							|tr = 'DF=''dd.MM.yyyy HH:mm'''");
	EndIf;
	
	Return Format(EventDate, DateFormat);
	
EndFunction

#EndRegion
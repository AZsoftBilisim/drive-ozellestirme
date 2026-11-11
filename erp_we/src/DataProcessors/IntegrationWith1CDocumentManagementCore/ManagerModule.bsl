#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
	
	If FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.IncomingDocument"
			Or FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.OutgoingDocument"
			Or FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.InternalDocument" Then
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		ModuleIntegrationWith1CDocumentManagement.CustomizeDocumentFormAccordingToXDTODocumentView(
			Form,
			documentType,
			organization);
	EndIf;
	
	DisplayWarnings = WarningOnEditRepresentation.Show;
	NotDisplayWarnings = WarningOnEditRepresentation.DontShow;
	
	Form.AutomaticNumbering = (documentType <> Undefined And documentType.automaticNumeration = True);
	If Form.AutomaticNumbering Then
		Items.RegistrationNumber.WarningOnEditRepresentation = DisplayWarnings;
		Items.RegistrationDate.WarningOnEditRepresentation = DisplayWarnings;
		Items.Register.Enabled = True;
	Else
		Items.RegistrationNumber.WarningOnEditRepresentation = NotDisplayWarnings;
		Items.RegistrationDate.WarningOnEditRepresentation = NotDisplayWarnings;
		Items.Register.Enabled = False;
	EndIf;
	
	If documentType <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertySet(documentType,
				"accountingForCaseFilesEnabled")
			And documentType.accountingForCaseFilesEnabled Then
		Items.CaseFileNomenclature.Visible = True;
	Else
		Items.CaseFileNomenclature.Visible = False;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
		
		If Form.Items.ToDoItem.Visible Then
			If documentType <> Undefined
					And IntegrationWith1CDocumentManagementCore.PropertySet(documentType, "accountingForCaseFilesEnabled")
					And documentType.accountingForCaseFilesEnabled Then
				Form.Items.CaseFileNomenclature.Visible = True;
			Else
				Form.Items.CaseFileNomenclature.Visible = False;
			EndIf;
		Else
			Form.Items.CaseFileNomenclature.Visible = False;
		EndIf;
		
	EndIf;
	
EndProcedure

// Gets a set of additional object details and places it on the object form.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Form - ClientApplicationForm - The Form Of The 1C OBJECT:Document management:
//     * Description - String
//
Procedure GetAdditionalDetailsAndPlaceThemOnForm(Proxy, Form) Export
	
	Object = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Form.Type);
	Object.name = Form.Description;
	Object.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Form.ID,
		Form.Type);
	
	If Find(Form.Type, "Document") > 0 Then
		If ValueIsFilled(Form.DocumentKind) Then
			Object.documentType = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Form.Type + "Type");
			Object.documentType.name = Form.DocumentKind;
			Object.documentType.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				Form.DocumentKindID,
				Form.DocumentKindType);
		EndIf;
		
	ElsIf Form.Type = "DMCorrespondent" Then
		If ValueIsFilled(Form.LegalEntityIndividual) Then
			Object.legalPrivatePerson = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMLegalPrivatePerson");
			Object.legalPrivatePerson.name = Form.LegalEntityIndividual;
			Object.legalPrivatePerson.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				Form.LegalEntityIndividualID,
				Form.LegalEntityIndividualType);
		EndIf;
		
	EndIf;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetObjectAdditionalPropertiesRequest");
	Query.object = Object;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	PlaceAdditionalDetailsOnForm(Form, Result);
	
EndProcedure

// Places a set of additional object details on the object form
//
// Parameters:
//   Form - ClientApplicationForm - 1C document form:Document management.
//   XDTODataObject - XDTODataObject - the object from which the form details are filled in.
//   AddAttributes - XDTOList - array of additional Attributes from which the form Attributes are filled in.
//
Procedure PlaceAdditionalDetailsOnForm(Form, XDTODataObject = Undefined,
		AddAttributes = Undefined) Export
	
	If AddAttributes = Undefined Then
		If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTODataObject, "additionalProperties") Then
			AddAttributes = XDTODataObject.additionalProperties; // XDTOList
		Else
			AddAttributes = New Array;
		EndIf;
	EndIf;
	
	ThereAreProperties = (AddAttributes.Count() > 0);
	
	// On some forms, a separate page is allocated for properties.
	If Form.Items.Find("PropertiesPage") = Undefined Then
		Form.Items.PropertiesGroup.Visible = ThereAreProperties;
	Else
		Form.Items.PropertiesPage.Visible = ThereAreProperties;
	EndIf;
	
	PreviousValues1 = Form.Properties.Unload();
	Form.Properties.Clear();
	
	If Not ThereAreProperties Then
		Return;
	EndIf;
	
	For Each AdditionalProperty1 In AddAttributes Do
		
		If Not IntegrationWith1CDocumentManagementCore.PropertySet(
				AdditionalProperty1, "propertyValueTypes") Then
			Continue;
		EndIf;
		
		NewRow = Form.Properties.Add();
		AvailableTypeList = NewRow.AvailableTypeList; // ValueList
		
		NewRow.Property = AdditionalProperty1.name;
		NewRow.PropertyType = AdditionalProperty1.objectID.type;
		NewRow.PropertyID = AdditionalProperty1.objectID.ID;
		
		If AdditionalProperty1.Properties().Get("mandatory") <> Undefined Then
			NewRow.RequiredToFill = AdditionalProperty1.mandatory;
		EndIf;
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(
				AdditionalProperty1, "propertySimpleValue") Then
			NewRow.Value = AdditionalProperty1.propertySimpleValue;
		ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(
				AdditionalProperty1, "propertyObjectValue") Then
			NewRow.Value = AdditionalProperty1.propertyObjectValue.name;
			NewRow.ValueType = AdditionalProperty1.propertyObjectValue.objectID.type;
			NewRow.ValueID = AdditionalProperty1.propertyObjectValue.objectID.ID;
		Else
			FilterParameters = New Structure("PropertyType, PropertyID",
				NewRow.PropertyType,
				NewRow.PropertyID);
			ArrayOfStringsOldValues = PreviousValues1.FindRows(FilterParameters);
			If ArrayOfStringsOldValues.Count() = 1 Then
				FillPropertyValues(
					NewRow,
					ArrayOfStringsOldValues[0],
					"Value, ValueType, ValueID");
			Else
				NewRow.Value = "";
			EndIf;
		EndIf;
		
		For Each TypeDetails In AdditionalProperty1.PropertyValueTypes Do
			DataAboutType = New Structure("xdtoClassName, presentation");
			DataAboutType.xdtoClassName = TypeDetails.xdtoClassName;
			DataAboutType.presentation = TypeDetails.presentation;
			AvailableTypeList.Add(DataAboutType);
		EndDo;
		
	EndDo;
	
	Form.Items.Properties.HeightInTableRows = AddAttributes.Count();
	
EndProcedure

// Performs actions when changing the document type.
//
// Parameters:
//   Form - ClientApplicationForm - 1C document form:Document management.
//   ObjectsDataBefore - XDTOList - contains data of the document type and, possibly, the organization.
//
Procedure WhenChangingViewOnDocumentForm(Form, ObjectsDataBefore = Undefined) Export
	
	organization = Undefined;
	
	If ObjectsDataBefore = Undefined Then
		documentType = DocumentViewXDTOByDocumentForm(Form);
	Else
		documentType = ObjectsDataBefore[0];
		If ObjectsDataBefore.Count() > 1 And ObjectsDataBefore[1].objectID.type = "DMOrganization" Then
			organization = ObjectsDataBefore[1];
		EndIf;
	EndIf;
	
	If Not CheckAbilityToCreateDocumentThatIsNotTemplate(Form, documentType) Then
		Return;
	EndIf;
	
	CustomizeDocumentFormAccordingToXDTODocumentView(Form, documentType, organization);
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	GetAdditionalDetailsAndPlaceThemOnForm(Proxy, Form);
	
	If ValueIsFilled(Form.Type) And ValueIsFilled(Form.ID) Then
		XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			Form.Type,
			Form.ID,
			"registrationAvailable");
		SetRegistrationAvailability(Form, XDTODataObject);
	EndIf;
	
EndProcedure

// Puts the values of additional properties in the XDTO object from the object form.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   XDTODataObject - XDTODataObject - the XDTO object to be filled in.
//   Form - ClientApplicationForm, Structure - managed form or structure
//     of the 1C document details:Document management.
//
Procedure GenerateAdditionalProperties(Proxy, XDTODataObject, Form) Export
	
	For Each AdditionalProperty1 In Form.Properties Do
		
		AdditionalProperty = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMAdditionalProperty");
		AdditionalProperty.name = AdditionalProperty1.Property;
		
		AdditionalProperty.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			AdditionalProperty1.PropertyID,
			AdditionalProperty1.PropertyType);
		
		If ValueIsFilled(AdditionalProperty1.ValueID) Then
			
			// This is an object-type value.
			ThisIsISObject = False;
			ReferenceToConsumer_ = AdditionalProperty1.Value;
			If Metadata.FindByFullName(AdditionalProperty1.ValueType) <> Undefined Then
				ThisIsISObject = True;
				ReferenceToConsumer_ = IntegrationWith1CDocumentManagementCore.LinkFromUUID(
					AdditionalProperty1.ValueType,
					AdditionalProperty1.ValueID);
			EndIf;
			
			PropertyType1 = "DMObject";
			AvailableTypes = AdditionalProperty1.AvailableTypeList;
			If AvailableTypes.Count() = 1 Then
				PropertyType1 = AvailableTypes[0].Value.xdtoClassName;
			EndIf;
			
			PropertyValue = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				PropertyType1,
				ReferenceToConsumer_,
				ThisIsISObject);
			
			If Not ThisIsISObject Then
				
				If AdditionalProperty1.ValueType = "String" Then
					PropertyValue.externalObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
						Proxy,,
						AdditionalProperty1.ValueID,
						AdditionalProperty1.ValueType,
						AdditionalProperty1.Value);
				Else
					// The value is an object BEFORE.
					PropertyValue.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
						Proxy,
						AdditionalProperty1.ValueID,
						AdditionalProperty1.ValueType);
				EndIf;
				
			EndIf;
			
			AdditionalProperty.propertyObjectValue = PropertyValue;
			
		ElsIf ValueIsFilled(AdditionalProperty1.Value) Then
			
			If Common.IsReference(TypeOf(AdditionalProperty1.Value)) Then
				AdditionalProperty.propertySimpleValue = String(AdditionalProperty1.Value);
			Else
				AdditionalProperty.propertySimpleValue = AdditionalProperty1.Value;
			EndIf;
			
		EndIf;
		
		AdditionalProperties = XDTODataObject.additionalProperties; // XDTOList
		AdditionalProperties.Add(AdditionalProperty);
		
	EndDo;
	
EndProcedure

// Sets the visibility of the Register button on the document form.
//
// Parameters:
//   Form - ClientApplicationForm - 1C document form:Document management.
//   XDTODataObject - XDTODataObject - an object with document data.
//
Procedure SetRegistrationAvailability(Form, XDTODataObject) Export
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(
			XDTODataObject, "registrationAvailable") Then
		Form.Items.Register.Visible = XDTODataObject.registrationAvailable;
	Else
		Form.Items.Register.Visible = True;
	EndIf;
	
	If Form.Items.Register.Visible Then
		Form.Items.GroupRegNumberDate.ToolTip =
			NStr("vi = 'Để đăng ký văn bản, hãy sử dụng nút ""Đăng ký"" trên thanh lệnh.';
				|ru = 'Для регистрации документа используйте кнопку ""Зарегистрировать"" в командной панели.';
				|en = 'Use ""Register"" button in the command bar to register the document.'; fa = 'Use ""Register"" button in the command bar to register the document.';
				|it = 'Per la registrazione del documento, utilizzare il pulsante ""Registrarsi"" nel pannello di comando.';
				|pl = 'W celu rejestracji dokumentu używaj przycisku ""Zarejestruj"" w paneli poleceń.';
				|tr = 'Belgeyi kaydetmek için komut çubuğundaki ""Kayıt ol"" düğmesini kullan.'");
	Else
		Form.Items.GroupRegNumberDate.ToolTip = "";
	EndIf;
	
EndProcedure

// Sets the value of the Form's navigation link to the Workflow object.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the 1C object:Document management.
//   URL - XDTODataObject, String - an XDTO object with the ObjectId.navigationRef property, or the navigation
//     link itself in the form of a string, the value of which needs to be set to the Form.
//
Procedure SetNavigationLink(Form, Val URL) Export
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(URL, "objectID") Then
		URL = URL.objectID.navigationRef;
	EndIf;
	
	If TypeOf(URL) <> Type("String") Or Not ValueIsFilled(URL) Then
		Return;
	EndIf;
	
	Form.AutoURL = False;
	Form.URL = StringFunctionsClientServer.SubstituteParametersToString("%1#%2",
		IntegrationWith1CDocumentManagementCore.AddressOf1CDocumentManagementWebService(),
		URL);
	
EndProcedure

#EndRegion

#Region Private

// Returns an XDTO object corresponding to the type of document, according to its form.
//
// Parameters:
//   Form - ClientApplicationForm - 1C document form:Document management.
//
// Returns:
//   XDTODataObject
//
Function DocumentViewXDTOByDocumentForm(Form)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	DocumentKindID = Form.DocumentKindID;
	DocumentKindType = Form.DocumentKindType;
	
	If ValueIsFilled(DocumentKindID) And ValueIsFilled(DocumentKindType) Then
		ObjectToGetFromTO = New Structure("ID, Type", DocumentKindID, DocumentKindType);
		Query = IntegrationWith1CDocumentManagementCore.GetRequestObjects(
			Proxy,
			CommonClientServer.ValueInArray(ObjectToGetFromTO));
		
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		Try
			IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		Except
			Raise StrTemplate(
				NStr("vi = 'Không tìm thấy dạng văn bản ""%1"" trong 1C:Document Management';
					|ru = 'Вид документа ""%1"" не найден в 1С:Документообороте';
					|en = 'The ""%1"" document kind is not found in 1C:Document Management '; fa = 'The ""%1"" document kind is not found in 1C:Document Management ';
					|it = 'Tipo di documento ""%1"" non trovato in 1C:Document Management';
					|pl = 'Rodzaj dokumentu ""%1"" jest znaleziony w 1C:Document Management';
					|tr = '""%1"" belge türü 1C:Document Management''te bulunamadı'"),
				Form.DocumentKind);
		EndTry;
		
		documentType = Result.objects[0];
	Else
		documentType = Undefined;
	EndIf;
	
	Return documentType;
	
EndFunction

// Checks the possibility of creating a document of the specified type not according to a template, returning True,
// if there is such a possibility, and forming a message to the user with the reset
// of the document type selected by him.
//
// Parameters:
//   Form - ClientApplicationForm - 1C document form:Document management.
//   documentType - XDTODataObject - type of document.
//
// Returns:
//   Boolean
//
Function CheckAbilityToCreateDocumentThatIsNotTemplate(Form, documentType)
	
	If documentType <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertySet(documentType, "templateRequired")
			And documentType.templateRequired
			And Form.TemplateID = "" Then
		
		Message = New UserMessage();
		Message.Text = StrTemplate(
			NStr("vi = 'Trong tùy chỉnh dạng văn bản ""%1"" đã thiết lập cấm tạo văn bản không theo khuôn mẫu.';
				|ru = 'В настройках вида документа ""%1"" установлен запрет на создание документов не по шаблону.';
				|en = 'The prohibition on creating documents not based on the template is set in the settings for the document kind ""%1"".'; fa = 'The prohibition on creating documents not based on the template is set in the settings for the document kind ""%1"".';
				|it = 'Nelle impostazioni del tipo di documento ""%1"" è indicato che è possibile creare documenti solo da modello.';
				|pl = 'W ustawieniach rodzaju dokumentu ""%1"" jest ustawiony zakaz na utworzenie dokumentów nie zgodnie z szablonem.';
				|tr = '""%1"" belge türü ayarlarında numuneye uymayan belgelerin oluşturulmasına yönelik yasak ayarlandı.'"),
			Form.DocumentKind);
		Message.Field = "DocumentKind";
		Message.Message();
		
		Form.DocumentKindID = "";
		Form.DocumentKindType = "";
		Form.DocumentKind = "";
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#EndIf
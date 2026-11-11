#Region Internal

#Region ObjectEventHandlers

// Handler for the "Before recording" event for the protocol owner
// 
// Parameters:
//  Object - DocumentObject- Owner of the protocol.
//  Cancel - Boolean
//  WriteMode - DocumentWriteMode
//  PostingMode - DocumentPostingMode
Procedure BeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	
	NewState = OperationsWithDocumentProtocolClientServer.ModifiableProtocolProperties();
	OperationsWithDocumentProtocolClientServer.FillInProtocolPropertiesFromObject(NewState, Object);
	
	If ValueIsFilled(Object.Protocol) Then

		Initial_State = OperationsWithDocumentProtocolClientServer.ModifiableProtocolProperties();
		LastRow = OperationsWithDocumentProtocolClientServer.LastLineOfProtocol(Object.Protocol);
		FillPropertyValues(Initial_State, LastRow);
		
		If Not OperationsWithDocumentProtocolClientServer.ProtocolPropertiesHaveChanged(NewState, Initial_State) Then
			Return; // The protocol has not been changed (including programmatically), no data update is required.
		EndIf;
		
	EndIf;
	
	NewLineOfProtocol(Object.Protocol, NewState);
	
EndProcedure

#EndRegion

#Region FormEventHandlers

// Creates auxiliary Attributes on the Form and fills in the Presentation of the protocol
// 
// Parameters:
//  Form - ClientApplicationForm - Owner of the protocol.
Procedure FillInFormDetails(Form) Export

	InitializeTheForm(Form);
	OperationsWithDocumentProtocolClientServer.FillInFormDataAccordingToProtocol(Form);
	
EndProcedure

#EndRegion

#Region TransferContract

// Adds a description that affects adding the installation of a new contractor in the "Status Submission"
// field is called from the "Fill in Available Status route" methods of the document Status enumeration manager modules.
// 
// Parameters:
//  Form - ClientApplicationForm - Owner of the protocol.
//  InitialStatus - EnumRef - The Status from which you can set a new artist value.
Procedure AddRedirectionRoute(Form, InitialStatus) Export
	
	AddAvailableRoute(Form, InitialStatus, InitialStatus, NStr("ru = 'Перенаправить';
																|vi = 'Forward';
																|en = 'Forward'; fa = 'جلو';
																|it = 'Forward';
																|pl = 'Forward';
																|tr = 'Yönlendir'"));
	
EndProcedure

// Adds a description that affects adding a hyperlink to set a new Status in the Status View field.
// It is called from the "Fill in the available Status route" methods of the document Status enumeration manager modules.
// 
// Parameters:
//  Form - ClientApplicationForm - Owner of the protocol.
//  InitialStatus - EnumRef - The Status from which you can set a new value.
//  SetStatus_ - EnumRef - The Status that can be set from the source.
//  CommandPresentation - String - Presentation of the Status setting hyperlink.
//  NameOfPerformerSAttributes - String - The path to the Attribute of the object that stores the value of the installed artist.
// 								If not specified, the value of the performer does not change.
Procedure AddAvailableRoute(Form, InitialStatus, SetStatus_, CommandPresentation, NameOfPerformerSAttributes = "") Export
	
	AvailableStatusesRoutes = Form.AvailableStatusesRoutes; // FormDataCollection
	
	Route = AvailableStatusesRoutes.Add();
	Route.InitialStatus = InitialStatus;
	Route.SetStatus_ = SetStatus_;
	Route.CommandPresentation = CommandPresentation;
	Route.NameOfPerformerSAttributes = NameOfPerformerSAttributes;
	
EndProcedure

// Checks that the Status value completes the process of working with the document.
// 
// Parameters:
//  Status - EnumRef - Verifiable Status
// 
// Returns:
//  Boolean - True if the Status value is included in the list of final Statuses described in the enumeration module
Function ThisIsFinalStatusOfDocument(Status) Export

	Return Common.ObjectManagerByRef(Status).ThisIsFinalStatus(Status);

EndFunction

#EndRegion

#EndRegion

#Region Private

#Region InitializeForm

Procedure InitializeTheForm(Form)

	If CommonClientServer.HasAttributeOrObjectProperty(Form, "AvailableStatusesRoutes") Then
		// There is an Attribute created during initialization. No re-initialization is required.
		Return;
	EndIf;
	
	AttributesToBeAdded = New Array;
	AttributesToBeAdded.Add(New FormAttribute(
		"ProtocolCache", New TypeDescription()));
	
	TypeOfStatus = TMCommonUse.DescriptionOfTypesByType(TypeOf(Form.Object.Status));
	String150 = Common.StringTypeDetails(150);
	AttributesToBeAdded.Add(New FormAttribute(
		"AvailableStatusesRoutes", New TypeDescription("ValueTable")));
	AttributesToBeAdded.Add(New FormAttribute(
		"InitialStatus", TypeOfStatus, "AvailableStatusesRoutes"));
	AttributesToBeAdded.Add(New FormAttribute(
		"SetStatus_", TypeOfStatus, "AvailableStatusesRoutes"));
	AttributesToBeAdded.Add(New FormAttribute(
		"CommandPresentation", String150, "AvailableStatusesRoutes"));
	AttributesToBeAdded.Add(New FormAttribute(
		"CommandValue", String150, "AvailableStatusesRoutes"));
	AttributesToBeAdded.Add(New FormAttribute(
		"NameOfPerformerSAttributes", String150, "AvailableStatusesRoutes"));
	Form.ChangeAttributes(AttributesToBeAdded);
	
	FillInAvailableStatusRoutes(Form);
	
	// Properties for working in the client-server module:
	Form.ProtocolCache = New Structure;
	Form.ProtocolCache.Insert("BoldFont", StyleFonts.BoldFont);
	Form.ProtocolCache.Insert("BegOfDay", BegOfDay(CurrentSessionDate()));
	
EndProcedure

#EndRegion

#Region DocumentStatus

Procedure FillInAvailableStatusRoutes(Form)
	
	AvailableStatusesRoutes = Form.AvailableStatusesRoutes; // FormDataCollection
	AvailableStatusesRoutes.Clear();
	
	If Form.ReadOnly Then
		// The Status is a stored Attribute. Hyperlink editing is not available if the Form is not available
		Return;
	EndIf;
	
	CurrentStatus = Form.Object.Status;
	StatusManager = Common.ObjectManagerByRef(CurrentStatus);
	StatusManager.FillInAvailableStatusRoutes(Form);
	
	EnumerationMetadata = CurrentStatus.Metadata(); // MetadataObjectEnum
	EnumerationName = EnumerationMetadata.FullName();
	TemplateOfPredefinedValue = "%1.%2";
	
	For Each Route In AvailableStatusesRoutes Do
		
		If Route.InitialStatus = Route.SetStatus_ Then
			Route.CommandValue = OperationsWithDocumentProtocolClientServer.ValueOfRedirectCommand();
		Else
			Route.CommandValue = StrTemplate(
				TemplateOfPredefinedValue,
				EnumerationName,
				EnumerationMetadata.EnumValues[StatusManager.IndexOf(Route.SetStatus_)].Name);
		EndIf;
		
	EndDo;

EndProcedure

#EndRegion

#Region ProtocolChanges

// Adds a new line to the document protocol
// 
// Parameters:
//  Protocol - FormDataCollection - To which a new line will be added
//  ProtocolData - See OperationsWithDocumentProtocolClientServer.ModifiableProtocolProperties 
// 
// Returns:
//  FormDataCollectionItem - New Line Of The Protocol
Function NewLineOfProtocol(Protocol, ProtocolData) Export
	
	RowData = OperationsWithDocumentProtocolClientServer.StructureOfProtocolString();
	FillPropertyValues(RowData, ProtocolData);
	RowData.Author = Users.CurrentUser();
	RowData.Date = CurrentSessionDate();
	
	Return OperationsWithDocumentProtocolClientServer.NewLineOfProtocol(Protocol, RowData);
	
EndFunction

#EndRegion

#EndRegion
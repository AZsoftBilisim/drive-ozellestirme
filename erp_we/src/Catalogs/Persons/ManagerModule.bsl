#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export
	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|
	|LEFT JOIN Catalog.Users AS T1
	|	ON T1.Individual = T.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	IsFolder
	|	OR ValueAllowed(T.Ref)
	|	OR IsAuthorizedUser(T1.Ref)";
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// This function defines the details of an individual.
//
// Parameters:
//  Person - CatalogRef.Persons - Link to a reference list item
//
// Returns:
//	QueryResultSelection, Undefined - Details of the selected individual
//
Function GetDetailsOfIndividual(Person) Export
	
		
	Query = New Query("
	|SELECT
	|	Persons.TIN AS TIN
	|FROM
	|	Catalog.Persons AS Persons
	|WHERE
	|	Persons.Ref = &Person
	|");
	
	Query.SetParameter("Person", Person);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection;
	Else
		Return Undefined;
	EndIf;

EndFunction

// The function defines the representation of an individual's document.
// Returns a representation of an individual's document if one document is found.
// Returns an empty string if the document is not found or there are more than one documents.
//
// Parameters:
//  Person - CatalogRef.Persons - Link to Phys. face
//  DocumentKind - CatalogRef.DocumentKindsOfPersons - Type of document Phys. faces
//
// Returns:
//  String - Submission of an individual's document
//
Function GetIndividualSDefaultDocument(Person, DocumentKind = Undefined) Export
	
	Query = New Query("
	|SELECT TOP 2
	|	DocumentsPersons.Presentation AS PresentationOfDocumentOfIndividual
	|FROM
	|	InformationRegister.DocumentsPersons AS DocumentsPersons
	|WHERE
	|	DocumentsPersons.Person = &Person
	|	AND (DocumentsPersons.DocumentKind = &DocumentKind
	|		OR &DocumentKind = UNDEFINED)
	|");
	
	Query.SetParameter("Person", Person);
	Query.SetParameter("DocumentKind", ?(ValueIsFilled(DocumentKind), DocumentKind, Undefined));
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 
	   And Selection.Next()
	Then
		PresentationOfDocumentOfIndividual = Selection.PresentationOfDocumentOfIndividual;
	Else
		PresentationOfDocumentOfIndividual = "";
	EndIf;
	
	Return PresentationOfDocumentOfIndividual;

EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Parameters.SearchString) Then
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	Persons.Ref AS Ref,
		|	Persons.Description AS Presentation,
		|	Persons.Refinement,
		|	Persons.DeletionMark AS DeletionMark
		|FROM
		|	Catalog.Persons AS Persons
		|WHERE
		|	(Persons.Description LIKE &FullName
		|			OR Persons.Description LIKE &LastNameFirstName
		|			OR Persons.Description LIKE &LastName)
		|ORDER BY
		|	DeletionMark";
		
		LastFirstName = StringFunctionsClientServer.SplitStringIntoSubstringsArray(TrimAll(Parameters.SearchString)," ");
		
		SubstringCount = LastFirstName.Count();
		LastName            = ?(SubstringCount > 0,LastFirstName[0],"");
		Name                = ?(SubstringCount > 1,LastFirstName[1],"");
		MiddleName           = ?(SubstringCount > 2,LastFirstName[2],"");
		
		Query.SetParameter("FullName", TrimAll(LastName + " " + Name + " " + MiddleName) + "%");
		Query.SetParameter("LastNameFirstName", TrimAll(LastName + " " + Name + "%"));
		Query.SetParameter("LastName",  TrimAll(LastName) + "%");
			
		ChoiceData = New ValueList;
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			Presentation = Selection.Presentation + ?(IsBlankString(Selection.Refinement),""," (" + Selection.Refinement +")");
			
			If Selection.DeletionMark Then
				StructureValue = New Structure("Value,DeletionMark", Selection.Ref, Selection.DeletionMark);
				ChoiceData.Add(StructureValue,Selection.Presentation,,PictureLib.ItemMarkedForDeletion);
			Else
				ChoiceData.Add(Selection.Ref,Selection.Presentation);
			EndIf;
			
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map - list of Attributes used in the template:
//      ** Key     - String - name of the prop in the template;
//      ** Value - String - the fill value in the template.
//    * CommonAttributesValues - Map - list of common Attributes used in the template:
//      ** Key     - String - name of the prop in the template;
//      ** Value - String - the fill value in the template.
//    * Attachments - Map - the values of the requisites:
//      ** Key     - String - name of the attachment in the template;
//      ** Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion 

#Region OtherItems

Procedure FillCheckProcessingAtServer(Form, Cancel, CheckedAttributes) Export
	
	If ValueIsFilled(Form.Object.TIN) Then
		PhysicalSample = TinAlreadyAssignedToAnotherIndividual(Form.Object.TIN, Form.Object.Ref);
		If PhysicalSample <> Undefined Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'MST này đã chỉ định đối với cá nhân %1.';
					|ru = 'Данный ИНН уже указан для физического лица  %1.';
					|en = 'This TIN is already specified for person %1.'; fa = 'This TIN is already specified for person %1.';
					|it = 'Tale codice fiscale è già indicato per la persona fisica %1.';
					|pl = 'Dany NIP jest już wskazany dla osoby fizycznej %1.';
					|tr = 'Bu VKN, %1 gerçek kişisi için zaten belirtilmiş.'"),
				PhysicalSample.Presentation);
			CommonClientServer.MessageToUser(
				MessageText,
				,
				"Object.TIN",
				,
				Cancel);
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Persons.Ref
	|FROM
	|	Catalog.Persons AS Persons
	|WHERE
	|	Persons.Description = &Description
	|	AND Persons.Refinement = &Refinement
	|	AND Persons.Ref <> &Ref";
	
	Query.SetParameter("Description", Form.Object.Description);
	Query.SetParameter("Refinement",	  Form.Object.Refinement);
	Query.SetParameter("Ref", 	  Form.Object.Ref);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		MessageText = NStr("vi = 'Cá nhân có họ tên và thông tin chi tiết như vậy đã tồn tại trong cơ sở thông tin.
			|Cần chỉ ra thông tin chi tiết khác, hoặc sử dụng phần tử đã có trong danh mục.';
			|ru = 'Физическое лицое лицо с таким ФИО и уточнением уже существует в информационной базе.
			|Необходимо либо указать другую уточняющую информацию, либо воспользоваться уже имеющимся элементом справочника.';
			|en = 'A person with this name and personal feature already exists.
			|Specify a different personal feature or select an existing person.'; fa = 'A person with this name and personal feature already exists.
			|Specify a different personal feature or select an existing person.';
			|it = 'Persona fisica con queste credenziali e queste informazioni aggiuntive è già presente nel database.
			| è necessario indicare altre informazioni aggiuntive o utilizzare l''elemento della directory esistente.';
			|pl = 'Osoba fizyczna z takim imieniem, nazwiskiem i uściśleniem istnieje już w bazie informacyjnej.
			|Należy albo wskazać inną informację uściślającą, albo użyć istniejącego elementu katalogu.';
			|tr = 'Böyle bir tam adı ve belirtime sahip bir kişi, infobase''te zaten mevcut.
			|Ya başka açıklayıcı bilgiler belirtilmeli ya da kataloğun zaten var olan bir öğesi kullanılmalı.'"); 
		CommonClientServer.MessageToUser(
			MessageText,
			,
			"Object.Description",
			,
			Cancel);
	EndIf;
	
EndProcedure

//Determines whether there is an individual with the same TIN in the database
// Parameters:
//  TIN  - String - verified INN
//  ExcludingLink  - CatalogRef.Persons - an individual excluded from verification
//
// Returns:
//   QueryResultSelection, Undefined   - a sample with the data of a found individual
//  with the same TIN, It is uncertain if the desired TIN is not assigned to anyone.
//
Function TinAlreadyAssignedToAnotherIndividual(TIN, ExcludingLink = Undefined)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Persons.Ref,
	|	PRESENTATION(Persons.Description) AS Presentation
	|FROM
	|	Catalog.Persons AS Persons
	|WHERE
	|	Persons.TIN = &TIN
	|	AND Persons.Ref <> &Ref";
	
	Query.SetParameter("TIN",	TIN);
	Query.SetParameter("Ref", ExcludingLink);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#EndIf


#Region Private

#Region FillingInFormData

Procedure FillInFormDataAccordingToProtocol(Form) Export
	
	FillInStatusPresentation(Form);
	FillInPerformerSPresentation(Form);
	
EndProcedure

Function HyperlinkValues(Val PresentationOfHyperlink, HyperlinkValue)
	
	If TypeOf(PresentationOfHyperlink) <> Type("String") Then
		PresentationOfHyperlink = String(PresentationOfHyperlink);
	EndIf;
	
	Hyperlink = New FormattedString(
		PresentationOfHyperlink,,,,
		HyperlinkValue);
		
	Return Hyperlink;
	
EndFunction

Function ValueOfRedirectCommand() Export
	Return "Forward";
EndFunction

#Region StatusPresentation

Procedure FillInStatusPresentation(Form)
	
	BoldFont = Form.ProtocolCache.BoldFont;
	
	AvailableRoutes = AvailableStatusRoutes(Form);
	IndexOfLastRoute = AvailableRoutes.Count() - 1;
	RowData = New Array;
	
	// Title:
	RowData.Add(NStr("ru = 'Статус';
					|vi = 'Status';
					|en = 'Status'; fa = 'وضعیت';
					|it = 'Status';
					|pl = 'Status';
					|tr = 'Durum'"));
	RowData.Add(":");
	RowData.Add(" ");
	
	// Current value:
	RowData.Add(New FormattedString(
		String(Form.Object.Status), BoldFont,,,"ChangeStatus_"));
	
	// Separator before actions:
	RowData.Add(" ");
	RowData.Add(" ");
	
	For RouteIndex = 0 To IndexOfLastRoute Do
		
		// Action:
		Route = AvailableRoutes[RouteIndex];
			
		CommandPresentation = Route.CommandPresentation;
		If RouteIndex <> 0 Then
			// All but the first command must be in lowercase:
			CommandPresentation = Lower(CommandPresentation);
		EndIf;
			
		RowData.Add(HyperlinkValues(CommandPresentation, Route.CommandValue));
			
		// Action Separator:
		If RouteIndex = IndexOfLastRoute Then
			Continue;
		ElsIf RouteIndex = IndexOfLastRoute - 1 Then
			RowData.Add(" ");
			RowData.Add(NStr("ru = 'или';
							|vi = 'or';
							|en = 'or'; fa = 'یا';
							|it = 'or';
							|pl = 'or';
							|tr = 'veya'"));
			RowData.Add(" ");
		Else
			RowData.Add(",");
			RowData.Add(" ");
		EndIf;
		
	EndDo;
	
	Form.StatusPresentation = New FormattedString(RowData);
	
EndProcedure

#Region StatusRoutes

Function AvailableStatusRoutes(Form)
	
	ReturnValue = New Array;
	
	SelectionStatus = Form.Object.Status;
	For Each RouteString In Form.AvailableStatusesRoutes Do // We save the sequence of lines
		
		If RouteString.InitialStatus <> SelectionStatus Then
			Continue;
		EndIf;

		ReturnValue.Add(RouteString);
		
	EndDo;
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#EndRegion

#Region ArtistPresentation

Procedure FillInPerformerSPresentation(Form)
	
	CompositionOfPerformerSPresentation = New Array;
	CompositionOfPresentationOpenProtocol = New Array;
	
	ProtocolData = StructureOfProtocolString();
	If ValueIsFilled(Form.Object.Protocol) Then
		LastRow = LastLineOfProtocol(Form.Object.Protocol);
		FillPropertyValues(ProtocolData, LastRow);
		ProtocolCompleted = True;
	Else
		FillInProtocolPropertiesFromObject(ProtocolData, Form.Object);
		ProtocolCompleted = False;
	EndIf;
		
	// Performer:
	CompositionOfPerformerSPresentation.Add(NStr("ru = 'Направлена';
												|vi = 'Sent';
												|en = 'Sent'; fa = 'ارسال‌شده';
												|it = 'Sent';
												|pl = 'Sent';
												|tr = 'Yönlendirildi'"));
	CompositionOfPerformerSPresentation.Add(":");
	CompositionOfPerformerSPresentation.Add(" ");
	If ValueIsFilled(ProtocolData.Performer) Then
		CompositionOfPerformerSPresentation.Add(
			HyperlinkValues(ProtocolData.Performer, ValueOfRedirectCommand()));
	Else
		CompositionOfPerformerSPresentation.Add("<...>"); // An empty performer. Not redirected in closed Statuses 
	EndIf;
	
	AddedSeparatorBetweenHyperlinks = False; // If false, then the next "word separator" should not be a hyperlink.
	
	// Author:
	If ProtocolData.Author <> ProtocolData.Performer Then
		
		CompositionOfPerformerSPresentation.Add(" ");
		CompositionOfPerformerSPresentation.Add(NStr("ru = 'от';
													|vi = 'dated';
													|en = 'dated'; fa = 'مورخ';
													|it = 'dated';
													|pl = 'dated';
													|tr = 'den'"));
		CompositionOfPerformerSPresentation.Add(" ");
		AddedSeparatorBetweenHyperlinks = True;
		
		CompositionOfPresentationOpenProtocol.Add(String(ProtocolData.Author));
		
	EndIf;
	
	// Date. It displays either today's time or a date without time:
	If ProtocolCompleted Then // If the protocol has not been completed yet, then there is no date
		
		If AddedSeparatorBetweenHyperlinks Then
			CompositionForSeparator = CompositionOfPresentationOpenProtocol;
		Else
			CompositionForSeparator = CompositionOfPerformerSPresentation;
			AddedSeparatorBetweenHyperlinks = True;
		EndIf;
		
		CompositionForSeparator.Add(",");
		CompositionForSeparator.Add(" ");
		
		Date = ProtocolData.Date;
		If BegOfDay(Date) = Form.ProtocolCache.BegOfDay Then
			DateAsString = Format(Date, "DF=HH:mm");
		Else
			DateAsString = Format(Date, "DLF=D");
		EndIf;
		
		CompositionOfPresentationOpenProtocol.Add(DateAsString);
		
	EndIf;
		
	// The number of entries in the protocol. Is displayed in parentheses:
	LineNumberOfRecordsInProtocol = StrTemplate("(%1)", Form.Object.Protocol.Count());
	
	Comment = ProtocolData.Comment;
	If IsBlankString(Comment) Then // There is not a single printable character
		
		If AddedSeparatorBetweenHyperlinks Then
			CompositionForSeparator = CompositionOfPresentationOpenProtocol;
		Else
			CompositionForSeparator = CompositionOfPerformerSPresentation;
			AddedSeparatorBetweenHyperlinks = True;
		EndIf;
		CompositionForSeparator.Add(" ");
		CompositionOfPresentationOpenProtocol.Add(LineNumberOfRecordsInProtocol);
		
	Else // Comment. Output the first significant line. If it is not included, then "cut off" and add an ellipsis:
		
		For Each RowPart In StrSplit(ProtocolData.Comment, Chars.LF, False) Do
			
			// If the first line is empty and there is, for example, a space in it, then Split will still return this value.
			// Skip such lines and take the first line with characters:
			If Not IsBlankString(RowPart) Then 
				
				Comment = TrimAll(RowPart);
				Break;
				
			EndIf;
			
		EndDo;
		
		PresentationLength = StrLen(StrConcat(CompositionOfPerformerSPresentation, ""))
			+ StrLen(StrConcat(CompositionOfPresentationOpenProtocol, ""))
			+ StrLen(LineNumberOfRecordsInProtocol) + 1; // Taking into account the separator " "
			
		MaximumLengthOfPresentation = 123;
		CommentLength = MaximumLengthOfPresentation - PresentationLength; 
			
		If StrLen(Comment) > CommentLength Then
			
			EllipsisLength = 3;
			Comment = StrTemplate(
				"%1...",
				Left(Comment, CommentLength - EllipsisLength));
			
		EndIf;
		
		If AddedSeparatorBetweenHyperlinks Then
			CompositionForSeparator = CompositionOfPresentationOpenProtocol;
		Else
			CompositionForSeparator = CompositionOfPerformerSPresentation;
			AddedSeparatorBetweenHyperlinks = True;
		EndIf;
		CompositionForSeparator.Add(":");
		CompositionForSeparator.Add(" ");
		
		CompositionOfPresentationOpenProtocol.Add(Comment);
		
		CompositionOfPresentationOpenProtocol.Add(" ");
		CompositionOfPresentationOpenProtocol.Add(LineNumberOfRecordsInProtocol);
		
	EndIf;
	
	PresentationOpenProtocol = HyperlinkValues(
		StrConcat(CompositionOfPresentationOpenProtocol, ""),
		"OpenProtocol");
		
	CompositionOfPerformerSPresentation.Add(PresentationOpenProtocol);
	Form.ArtistPresentation = New FormattedString(CompositionOfPerformerSPresentation);
	
EndProcedure

#EndRegion

#EndRegion

#Region DataOperations

// Returns the index of the last line of the protocol.
// 
// Parameters:
//  Protocol - FormDataCollection
// 
// Returns:
//  Number
Function LastLineOfProtocol(Protocol) Export

	Return Protocol.Get(Protocol.Count() - 1);

EndFunction

// Adds a new row to the protocol table
// 
// Parameters:
//  Protocol - FormDataCollection - To which the line will be added
//  ProtocolData - See StructureOfProtocolString
// 
// Returns:
//   FormDataCollectionItem
Function NewLineOfProtocol(Protocol, ProtocolData)  Export
	
	ProtocolString = Protocol.Add();
	FillPropertyValues(ProtocolString, ProtocolData);
	
	Return ProtocolString;
	
EndFunction

Procedure FillInProtocolPropertiesFromObject(ProtocolData, Object) Export
	
	FillPropertyValues(ProtocolData, Object);
	
EndProcedure

// Checks the change of the new State relative to the original one.
// 
// Parameters:
//  NewState - Structure
//  Initial_State - Structure
//  ThisIsAddingLine - Boolean - Enables checking whether the comment is full to account for changes.
// 
// Returns:
//  Boolean - True, if there are changes
Function ProtocolPropertiesHaveChanged(NewState, Initial_State, ThisIsAddingLine = False) Export
	
	ChangedProperties = ChangedProtocolProperties(NewState, Initial_State);
	
	If ThisIsAddingLine
		And ChangedProperties.Count() = 1
		And ChangedProperties.Property("Comment")
		And Not ValueIsFilled(NewState.Comment) Then
		
		ReturnValue = False;
		
	Else
		
		ReturnValue = ValueIsFilled(ChangedProperties);
		
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Compares two protocol States and returns the changes.
// 
// Parameters:
//  NewState - Structure
//  Initial_State - Structure
// 
// Returns:
//  Structure of KeyAndValue: 
//   * Key - String - Name of the protocol property
//   * Value - Arbitrary - The value from the new State
//
//@skip-check function-return-types -- Dynamically created structure. The keys are not described.
Function ChangedProtocolProperties(NewState, Initial_State) Export
	
	ReturnValue = New Structure;
	
	For Each KeyAndValue In NewState Do
		
		If KeyAndValue.Value = Initial_State[KeyAndValue.Key] Then
			Continue;
		EndIf;
		
		ReturnValue.Insert(KeyAndValue.Key, KeyAndValue.Value);
		
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// Returns:
//  Structure - Structure with protocol string properties:
// * Date - Date - Adding an entry to the protocol.
// * Author - CatalogRef.Users - The author of the added entry.
// * Performer - CatalogRef.Users - To whom the document was sent.
// * Comment - String - Comment on the redirect.
// * Status - Undefined, EnumRef - The established Status of the document
Function StructureOfProtocolString() Export
	
	ReturnValue = New Structure;
	
	ReturnValue.Insert("Date",        '00010101');
	ReturnValue.Insert("Author",       PredefinedValue("Catalog.Users.EmptyRef"));
	ReturnValue.Insert("Performer", PredefinedValue("Catalog.Users.EmptyRef"));
	ReturnValue.Insert("Comment", "");
	ReturnValue.Insert("Status",      Undefined);
	
	Return ReturnValue;
	
EndFunction
 
// Returns:
//  Structure - A structure with protocol string properties that can be changed:
// * Performer - CatalogRef.Users - To whom the document was sent.
// * Comment - String - Comment on the redirect.
// * Status - Undefined, EnumRef - The established Status of the document
Function ModifiableProtocolProperties() Export
	
	ReturnValue = New Structure;
	
	ReturnValue.Insert("Performer", PredefinedValue("Catalog.Users.EmptyRef"));
	ReturnValue.Insert("Comment", "");
	ReturnValue.Insert("Status",      Undefined);
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#EndRegion

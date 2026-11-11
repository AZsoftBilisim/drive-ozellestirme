// The "Save data changes" flag has been removed from all Attributes, because otherwise the header "*" is displayed when modified
// The "Logged" flag is responsible for tracking changes, which is cocked when sending a new message or editing the last one.
// Because the Form can be opened with an empty table, the current State is stored in the "Data Protocol" to track changes

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	EnableEdit = Parameters.EnableEdit;
	ProtocolData = Parameters.ProtocolData;
	FillPropertyValues(ThisObject, ProtocolData,, "Comment");
	FillProtocol();
	
	FormControl();
	
	If ValueIsFilled(Protocol) Then
		LastRow = OperationsWithDocumentProtocolClientServer.LastLineOfProtocol(Protocol);
		Items.Protocol.CurrentRow = LastRow.GetID();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	If ThisIsFinalStatusOfDocument Then
		
		AttributesNotToCheck.Add("Performer");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProtocol

&AtClient
Procedure ProtocolSelection(Item, RowSelected, Field, StandardProcessing)
	OpenProtocolLineForm(RowSelected, StandardProcessing);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Send(Command)
	AddProtocolLine();
EndProcedure

&AtClient
Procedure OK(Command)
		
	AddProtocolLine();
	
	ReturnValue = Undefined;
	If ProtocolChanged Then
		
		ReturnValue = OperationsWithDocumentProtocolClient.ProtocolToArray(Protocol);
		
	EndIf;
	
	Close(ReturnValue);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializingTable

&AtServer
Procedure FillProtocol()
	
	CurrentDayStart = BegOfDay(CurrentSessionDate());
	
	For Each SourceRow In Parameters.Protocol Do
		
		DestinationRow = Protocol.Add();
		FillPropertyValues(DestinationRow, SourceRow);
		FillInPresentationOfTheseProtocolLines(DestinationRow, CurrentDayStart);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region AddingLines

&AtClient
Procedure AddProtocolLine()
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	NewState = OperationsWithDocumentProtocolClientServer.ModifiableProtocolProperties();
	FillPropertyValues(NewState, ProtocolData); // For properties that do not change in the form
	FillPropertyValues(NewState, ThisObject);
	
	If Not OperationsWithDocumentProtocolClientServer.ProtocolPropertiesHaveChanged(NewState, ProtocolData, True) Then
		Return;
	EndIf;
	
	ProtocolString = OperationsWithDocumentProtocolClient.NewLineOfProtocol(Protocol, NewState);
	CurrentDayStart = BegOfDay(CommonClient.SessionDate());
	FillInPresentationOfTheseProtocolLines(ProtocolString, CurrentDayStart);
	Items.Protocol.CurrentRow = ProtocolString.GetID();
	
	Comment = Undefined; // The comment is reset because the "message" has been sent successfully	
	OnChangeOfProtocolData();
	
EndProcedure

#EndRegion

#Region OpeningLines

&AtClient
Procedure OpenProtocolLineForm(RowSelected, StandardProcessing = False)
	
	CurrentData = Protocol.FindByID(RowSelected);
	
	OpeningParameters = OperationsWithDocumentProtocolClient.ProtocolLineOpeningParameters();
	FillPropertyValues(OpeningParameters.ProtocolData, CurrentData);
	
	OpeningParameters.IsNewRecord = False; 
	OpeningParameters.DocumentAuthor_ = DocumentAuthor_;
	
	OpeningParameters.EnableEdit = EnableEdit
		And CurrentData.Author = UsersClient.CurrentUser()
		And Protocol.IndexOf(CurrentData) = Protocol.IndexOf(OperationsWithDocumentProtocolClientServer.LastLineOfProtocol(Protocol));
		
	CallbackDescription = New CallbackDescription("Attachable_OnChangingProtocolString", ThisObject);
	OperationsWithDocumentProtocolClient.OpenProtocolLine(ThisObject, OpeningParameters, CallbackDescription);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangingProtocolString(NewState, AdditionalParameters = Undefined) Export
	
	If NewState = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.Protocol.CurrentData;
	
	If Not OperationsWithDocumentProtocolClientServer.ProtocolPropertiesHaveChanged(NewState, ProtocolData) Then
		Return;
	EndIf;
	
	FillPropertyValues(CurrentData, NewState);
	CurrentData.Date = CommonClient.SessionDate(); // Updating the date the line was changed
	OnChangeOfProtocolData();
	
EndProcedure

#EndRegion

#Region CurrentStatus

&AtClient
Procedure OnChangeOfProtocolData()
	
	LastRow = OperationsWithDocumentProtocolClientServer.LastLineOfProtocol(Protocol);
	FillPropertyValues(ProtocolData, LastRow); // New current State for tracking changes
	ProtocolChanged = True;
	
EndProcedure

#EndRegion

#Region PresentationOfProtocol

&AtClientAtServerNoContext
Procedure FillInPresentationOfTheseProtocolLines(ProtocolString, CurrentDayStart)
	
	FillInDatePresentation(ProtocolString, CurrentDayStart);
	FillInRedirectionPresentation(ProtocolString);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDatePresentation(ProtocolString, CurrentDayStart)
		
	If BegOfDay(ProtocolString.Date) = CurrentDayStart Then
		// For the current date, only the time is displayed
		ProtocolString.DatePresentation = Format(ProtocolString.Date, "DF=HH:mm");
	Else // Display the date without seconds. You can look in more detail when considering a specific line
		ProtocolString.DatePresentation = StrTemplate("%1 %2",
			Format(ProtocolString.Date, "DLF=D"),
			Format(ProtocolString.Date, "DF=HH:mm"));
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInRedirectionPresentation(ProtocolString)
		
	If ProtocolString.Performer <> ProtocolString.Author And ValueIsFilled(ProtocolString.Performer) Then 
		ProtocolString.PresentationOfRedirection = StrTemplate("%1 --> %2",
			ProtocolString.Author,
			ProtocolString.Performer);
	Else
		ProtocolString.PresentationOfRedirection = StrTemplate("%1",
			ProtocolString.Author);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormControl

&AtServer
Procedure FormControl()
	
	Items.EditGroup.Visible = EnableEdit;
	Items.FormOK.Visible = EnableEdit;
	Items.FormOK.DefaultButton = EnableEdit;
	Items.FormClose.DefaultButton = Not EnableEdit;
	
	ThisIsFinalStatusOfDocument = OperationsWithDocumentProtocol.ThisIsFinalStatusOfDocument(ProtocolData.Status);
	Items.Performer.Visible = Not ThisIsFinalStatusOfDocument;
	Items.DecorationArtist.Visible = ThisIsFinalStatusOfDocument;
	
EndProcedure

#EndRegion

#EndRegion

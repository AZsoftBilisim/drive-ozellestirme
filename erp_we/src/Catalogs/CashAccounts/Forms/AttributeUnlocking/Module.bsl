
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	GenerateHeaderDetails();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
	Close(True);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateHeaderDetails()
	
	TextTitle_ = "";
	RowsArray = New Array;
	
	For Each String In Parameters.AttributeEditProhibitionParameters Do
		
		If Not String.RightToEdit Then 
			Continue;
		EndIf;
		
		If Not TextTitle_ = "" And StrLen(TextTitle_ + ", " + String.Presentation) > 75 Then 
			RowsArray.Add(TextTitle_ + ",");
			TextTitle_ = String.Presentation;
		Else 
			TextTitle_ = TextTitle_ + ?(TextTitle_ = "", "", ", ") + String.Presentation;
		EndIf;
		
	EndDo;
	
	RowsArray.Add(TextTitle_);
	Items.TitleDetails.Title = StrConcat(RowsArray, Chars.LF);
	
EndProcedure

#EndRegion

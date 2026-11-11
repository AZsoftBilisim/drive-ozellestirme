
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	If TypeOf(Parameters.ObjectTypes_) = Type("Array") Then
			
		TypeDetails = New TypeDescription(Parameters.ObjectTypes_);
		ListOfObjects.ValueType = TypeDetails;
	
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveTo_(Command)
	
	Close(ListOfObjects);
	
EndProcedure

#EndRegion

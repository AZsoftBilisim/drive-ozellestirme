#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	
	FillingValues = New Structure;
	FillingValues.Insert("CopyingValue", CopyingValue);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	
	ObjectFormName = DocumentOfBalanceInputByString + ".ObjectForm";
					
	OpenForm(ObjectFormName, FormParameters);
	
	Cancel = True;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	CopyingValue          = Parameters.CopyingValue;
	DocumentOfBalanceInputByString = Parameters.DocumentOfBalanceInputByString;
EndProcedure

#EndRegion
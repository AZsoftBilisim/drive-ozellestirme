#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UseFinishedProducts = Parameters.UseFinishedProducts;
	UseMaterials = Parameters.UseMaterials;
	UseOperations = Parameters.UseOperations;
	UseLaborCosts = Parameters.UseLaborCosts;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("ShowFormClosingConfirmationCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,, WarningText);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not UseFinishedProducts
		And Not UseMaterials
		And Not UseOperations
		And Not UseLaborCosts Then
		
		MessageText = NStr("vi = 'Cần sử dụng ít nhất một dữ liệu.';
							|ru = 'Необходимо использовать хотя бы одни данные.';
							|en = 'At least one piece of data should be used.'; fa = 'At least one piece of data should be used.';
							|it = 'È necessario utilizzare almeno un dato.';
							|pl = 'Wymagane jest używanie chociażby jednych danych.';
							|tr = 'En az bir veri kullanmanız gerekmektedir.'");
		CommonClientServer.MessageToUser(MessageText,,,, Cancel);
		
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FinishEditingCommand(Command)
	
	CompleteEditing();
	
EndProcedure

&AtClient
Procedure CancelEdit(Command)
	
	Modified = False;
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ShowFormClosingConfirmationCompletion(Result, AdditionalParameters) Export
	
	CompleteEditing();
	
EndProcedure

&AtClient
Procedure CompleteEditing()
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Modified = False;
	
	ClosingResult = New Structure;
	ClosingResult.Insert("UseFinishedProducts", UseFinishedProducts);
	ClosingResult.Insert("UseMaterials", UseMaterials);
	ClosingResult.Insert("UseOperations", UseOperations);
	ClosingResult.Insert("UseLaborCosts", UseLaborCosts);
	
	Close(ClosingResult);
	
EndProcedure

#EndRegion

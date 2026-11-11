#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.CloseOnChoice            = True;
	Parameters.CloseOnOwnerClose = True;
	
	If Parameters.Property("DocumentName")
		And Parameters.DocumentName = "VendorInvoice" Then
		ThisForm.ReadOnly = Not AccessRight("Update", Metadata.Documents.VendorInvoice);
	EndIf;
	
	FillPropertyValues(ThisForm, Parameters.PrintData);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	StandardProcessing = False;
	
	If Modified And Not Done Then
		
		Cancel = True;
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatmayın'"));
		
		ShowQueryBox(
			New CallbackDescription("BeforeCloseCompletion", ThisObject), 
			NStr("vi = 'Tất cả dữ liệu đã thay đổi sẽ bị mất. Đóng biểu mẫu?';
				|ru = 'Все измененные данные будут потеряны. Закрыть форму?';
				|en = 'All changed data will be lost. Close the form?'; fa = 'All changed data will be lost. Close the form?';
				|it = 'Tutti i dati modificati andranno persi. Chiudere il form?';
				|pl = 'Wszystkie zmodyfikowane dane zostaną utracone. Chcesz zamknąć formularz?';
				|tr = 'Tüm değişiklikler kaybolacak. Kapatılsın mı?'"), 
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "Close" Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If Not Modified Or ReadOnly Then
		
		Close();
		
	Else
		ObjectStructure = New Structure;
		ObjectStructure.Insert("AdvancePurpose",             AdvancePurpose);
		ObjectStructure.Insert("DocumentsCount",         DocumentsCount);
		ObjectStructure.Insert("SheetQuantity",             SheetQuantity);
		ObjectStructure.Insert("Director",                 Director);
		ObjectStructure.Insert("ChiefAccountant",             ChiefAccountant);
		
		Done = True;
		
		NotifyChoice(ObjectStructure);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion
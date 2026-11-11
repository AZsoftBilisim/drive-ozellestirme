#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Description = Parameters.Description;
	LongDesc = Parameters.LongDesc;
	DescriptionIsSpecial = Parameters.DescriptionIsSpecial;
	Items.DescriptionIsSpecial.Visible = ValueIsFilled(DescriptionIsSpecial);
	
	If ReadOnly Then
		Items.Description.ReadOnly = ReadOnly;
		Items.LongDesc.ReadOnly = ReadOnly;
		Items.DescriptionIsSpecial.ReadOnly = ReadOnly;
		
		Items.Done.Visible = False;
		Items.Cancel.Title = NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Закрыть';
									|pl = 'Close';
									|tr = 'Kapat'");
		Items.Cancel.DefaultButton = True;
	EndIf;
	
	If Parameters.Property("JustDescription") Then
		Items.Description.Visible = False;
		Title = NStr("vi = 'Mô tả đặc biệt nhiệm vụ';
					|ru = 'Особое описание задачи';
					|en = 'Special task details'; fa = 'Special task details';
					|it = 'Особое описание задачи';
					|pl = 'Special task details';
					|tr = 'Görevin özel ayrıntıları'");
	EndIf;
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.17.36") Then
		Items.DescriptionIsSpecial.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	Result = New Structure;
	Result.Insert("Description", Description);
	Result.Insert("LongDesc", LongDesc);
	Result.Insert("DescriptionIsSpecial", DescriptionIsSpecial);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion
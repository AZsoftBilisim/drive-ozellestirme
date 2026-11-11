
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Object.AssignmentType = Enums.AssignmentTypes.Own Then
		Items.Partner.Title = NStr("vi = 'Bên gia công';
									|ru = 'Переработчик';
									|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
									|it = 'Subfornitore';
									|pl = 'Przetwórca';
									|tr = 'Fason üretici'");
		
	ElsIf Object.AssignmentType = Enums.AssignmentTypes.DeliveryForPrincipal Then
		Items.Partner.Title = NStr("vi = 'Bên giao hàng ký gửi';
									|ru = 'Принципал';
									|en = 'Principal'; fa = 'اصل مبلغ';
									|it = 'Mandante';
									|pl = 'Principal';
									|tr = 'Anapara'");
		
	Else
		Items.Partner.Title = NStr("vi = 'Bên đặt gia công';
									|ru = 'Давалец';
									|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
									|it = 'Committente';
									|pl = 'Material provider';
									|tr = 'Tedarikçi'");
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	Items.AssignmentType.Visible = CommonClientServer.DebugMode();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	Items.Partner.Visible = ValueIsFilled(Object.Partner);
	Items.Contract.Visible = ValueIsFilled(Object.Partner);
	Items.ControlOnlyStock.Visible = ValueIsFilled(Object.LineOfBusiness)
		And Not ValueIsFilled(Object.Partner)
		And Not ValueIsFilled(Object.OrderDocument);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion


#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	WhenCreatingAndReadingOnServer();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	WhenCreatingAndReadingOnServer();
	
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

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	SetFormHeader();
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure WhenCreatingAndReadingOnServer()

	SetFormHeader();

EndProcedure

&AtServer
Procedure SetFormHeader()

	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		AutoTitle = False;
		If Object.Ref.IsEmpty() Then
			
			Title = NStr("vi = 'Nhóm truy cập đối tác (tạo mới)';
						|ru = 'Группа доступа контрагентов (создание)';
						|en = 'Counterparty access group (Create)'; fa = 'Counterparty access group (Create)';
						|it = 'Gruppo di accesso dei contraenti (creazione)';
						|pl = 'Grupa dostępu kontrahentów (tworzenie)';
						|tr = 'Cari hesap erişim grupları (oluşturma)'");
			
		Else
			
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (Nhóm truy cập đối tác)';
																					|ru = '%1 (Группа доступа контрагентов)';
																					|en = '%1 (Counterparty access group)'; fa = '%1 (Counterparty access group)';
																					|it = '%1 (Gruppo di accesso dei contraenti)';
																					|pl = '%1 (Grupa dostępu kontrahentów)';
																					|tr = '%1 (Cari hesap erişim grupları)'"), Object.Description);
			
		EndIf;
	EndIf;

EndProcedure

#EndRegion




#Region FormEventHandlers

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// form the name of the connection
	Object.Description = Object.PartnerSRole1 + " - " + Object.PartnerSRole2;
	Object.ReverseName = Object.PartnerSRole2 + " - " + Object.PartnerSRole1;

EndProcedure 

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnCreatReadAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	        ThisObject, "PartnerSRole1", NStr("vi = 'Vai trò của đối tác 1';
												|ru = 'Роль контрагента 1';
												|en = 'Counterparty role 1'; fa = 'Counterparty role 1';
												|it = 'Ruolo del contraente 1';
												|pl = 'Rola kontrahenta 1';
												|tr = 'Cari hesap rolü 1'"), UsePartnersAsCounterparties);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	        ThisObject, "PartnerSRole2", NStr("vi = 'Vai trò của đối tác 2';
												|ru = 'Роль контрагента 2';
												|en = 'Counterparty role 2'; fa = 'Counterparty role 2';
												|it = 'Ruolo del contraente 2';
												|pl = 'Rola kontrahenta 2';
												|tr = 'Cari hesap rolü 2'"), UsePartnersAsCounterparties);

	If Object.Ref.IsEmpty() Then
		OnCreatReadAtServer();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	SetElementFormTitle();
	
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
Procedure SetElementFormTitle()
	
	If Not UsePartnersAsCounterparties Then
		Return;
	EndIf;
	
	AutoTitle = False;

	If Object.Ref.IsEmpty() Then
		
		Title = NStr("vi = 'Dạng quan hệ giữa các đối tác (tạo mới)';
					|ru = 'Виды связей между контрагентами (создание)';
					|en = 'Types of relationship between counterparties (Create)'; fa = 'Types of relationship between counterparties (Create)';
					|it = 'Tipi delle connessioni tra contraenti (creazione)';
					|pl = 'Rodzaje połączeń pomiędzy kontrahentami (tworzenie)';
					|tr = 'Cari hesaplar arasındaki ilişki türleri (oluşturma)'");
		
	Else
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (Dạng mối quan hệ giữa các đối tác)';
																				|ru = '%1 (Вид связей между контрагентами)';
																				|en = '%1 (Connection kind between counterparties)'; fa = '%1 (Connection kind between counterparties)';
																				|it = '%1 (Tipo delle connessioni tra contraenti)';
																				|pl = '%1 (Rodzaje połączeń pomiędzy kontrahentami)';
																				|tr = '%1 (cari hesaplar arasındaki ilişki türleri)'"), Object.Description);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()

	SetElementFormTitle();

EndProcedure 

#EndRegion



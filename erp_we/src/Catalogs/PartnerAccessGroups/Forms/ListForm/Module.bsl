#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
		ThisObject, "", NStr("vi = 'Nhóm truy cập đối tác';
							|ru = 'Группы доступа контрагентов';
							|en = 'Counterparty access groups'; fa = 'Counterparty access groups';
							|it = 'Gruppi d''accesso dei contraenti';
							|pl = 'Grupy dostępu kontrahentów';
							|tr = 'Cari hesap erişim grupları'"));

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion


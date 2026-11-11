#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	            ThisObject, "", NStr("vi = 'Dạng quan hệ giữa các đối tác';
									|ru = 'Виды связей между контрагентами';
									|en = 'Types of relationship between counterparties'; fa = 'Types of relationship between counterparties';
									|it = 'Tipi delle connessioni tra contraenti';
									|pl = 'Rodzaje połączeń pomiędzy kontrahentami';
									|tr = 'Cari hesaplar arasındaki ilişki türleri'"));

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion


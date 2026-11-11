
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CounterpartyEditRight = AccessRight("Update", Metadata.Catalogs.Counterparties);
	Items.FormSelect.Visible = CounterpartyEditRight;
	Items.FormClose.Visible = CounterpartyEditRight;
	
	If Not CounterpartyEditRight Then
		Items.ChoiceList.ReadOnly = True;
		Items.DecorationHint.Title = NStr("vi = 'Không thể chọn đối tác mẹ bởi vì không có quyền thay đổi.';
											|ru = 'Выбор головного контрагента недоступен, так как нет прав на изменение.';
											|en = 'Cannot select main counterparty, no editing rights.'; fa = 'Cannot select main counterparty, no editing rights.';
											|it = 'Selezione del contraente principale non è disponibile in quanto non si dispone dei diritti di modifica.';
											|pl = 'Wybór głównego kontrahenta jest niedostępny, ponieważ nie ma praw do zmiany.';
											|tr = 'Düzenleme yetkisi olmadığı için ana cari hesap seçimi erişilebilir değildir.'");
	EndIf;
	
	PartnersAndCounterpartiesLocalization.SelectingHeadCounterpartyWhenCreatingItOnServer(ThisForm, Cancel, StandardProcessing);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersChoiceList

&AtClient
Procedure ChoiceListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If CounterpartyEditRight Then
		Close(Item.CurrentData.Value);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	CurrentData = Items.ChoiceList.CurrentData;
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn đối tác.';
								|ru = 'Контрагент не выбран.';
								|en = 'Counterparty is not selected.'; fa = 'Counterparty is not selected.';
								|it = 'Il contraente non è selezionato.';
								|pl = 'Nie wybrano kontrahenta.';
								|tr = 'Cari hesap seçilmedi.'"));
	Else
		Close(CurrentData.Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateNewOne(Command)
	
	Close(PredefinedValue("Catalog.Counterparties.EmptyRef"));
	
EndProcedure

#EndRegion

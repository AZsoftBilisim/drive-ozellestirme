
#Region Public

// Sets the subordinate counterparty to its parent counterparty
//
// Parameters:
//  Counterparty          - CatalogRef.Counterparties - the counterparty to which the head office is assigned
//  MainCounterparty  - CatalogRef.Counterparties - the set value of the head counterparty
//  ErrorDescription      - String - the parameter that records the errors that occur.
//
Procedure ChangeHeadCounterparty(Counterparty, MainCounterparty, ErrorDescription) Export
	CounterpartyObject = Counterparty.GetObject();
	
	Try
		CounterpartyObject.Lock();
	Except
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thay đổi đối tác mẹ đối với %1.
				|Có thể là hiện tại đối tác đang được chỉnh sửa.';
				|ru = 'Не удалось изменить головного контрагента для %1.
				|Возможно, контрагент в настоящий момент редактируется.';
				|en = 'Cannot change the main counterparty for %1.
				|Maybe, the counterparty is being edited.'; fa = 'Cannot change the main counterparty for %1.
				|Maybe, the counterparty is being edited.';
				|it = 'Impossibile modificare il contraente principale per %1.
				|Forse il contraente è attualmente in fase di modifica.';
				|pl = 'Nie można zmienić głównego kontrahenta dla %1.
				|Możliwie, że kontrahent w danym momencie jest edytowany.';
				|tr = '%1 için ana cari hesap değiştirilemedi.
				| Cari hesap şu anda düzenleniyor olabilir.'"),
			Counterparty);
		Return;
	EndTry;
	
	CounterpartyObject.MainCounterparty = MainCounterparty;
	CounterpartyObject.Write();
	
	CounterpartyObject.Unlock();
	
EndProcedure

// Identifies potential head contractors at the INN.
// 
// Parameters:
//  TIN        - String - TIN for which you need to get a list of contractors.
//  Counterparty - CatalogRef.Counterparties - link to the counterparty excluded from the search.
//
// Returns:
//  Number - number of counterparties
//
Function NumberOfPossibleHeadCounterparties(TIN, Counterparty = Undefined) Export
	Result = 0;
	Return Result;
EndFunction

#EndRegion

#Region Internal

// Returns the attribute value of the directory partners element
// 
// Returns:
//   See Common.ObjectAttributeValue
//
Function ValueOfPropsPartners(Ref, AttributeName) Export
	Result = Common.ObjectAttributeValue(Ref, AttributeName);
	Return Result
EndFunction

#EndRegion
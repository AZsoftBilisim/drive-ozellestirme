///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Sets change history storage mode.
// It:
//   - sets a value to the UseObjectsVersioning constant
//   - changes the value of the UseObjectsVersioning functional option
//   
Function SetChangeHistoryStorageMode(StoreChangeHistory) Export
	
	If Not Users.IsFullUser(,, False) Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện giao dịch.';
					|ru = 'Недостаточно прав для выполнения операции.';
					|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione.';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji.';
					|tr = 'İşlem için gerekli yetkiler yok.'"), ErrorCategory.AccessViolation);
	EndIf;
	
	Try
		Constants.UseObjectsVersioning.Set(StoreChangeHistory);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// (See ObjectsVersioning.StoreHistoryCheckBoxValue)
//
Function StoreHistoryCheckBoxValue() Export
	
	Return ObjectsVersioning.StoreHistoryCheckBoxValue();
	
EndFunction

#EndRegion


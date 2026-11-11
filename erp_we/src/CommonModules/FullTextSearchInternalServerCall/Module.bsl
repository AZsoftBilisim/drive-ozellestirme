///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Sets the full text search mode
// Executes:
//   - Changes mode of the platform full text search mechanism
//   - Sets value to the UseFullTextSearch constant
//   - Changes value of the UseFullTextSearch functional option
//   - Changes mode of the FullTextSearchIndexUpdate scheduled job
//   - Changes mode of the FullTextSearchMergeIndex scheduled job
//   - Changes mode of the TextExtraction scheduled job of the FilesOperations subsystem
//
Function SetFullTextSearchMode(UseFullTextSearch) Export
	
	If Not Users.IsFullUser(,, False) Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện giao dịch.';
					|ru = 'Недостаточно прав для выполнения операции.';
					|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione.';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji.';
					|tr = 'İşlem için gerekli yetkiler yok.'"), ErrorCategory.AccessViolation);
	EndIf;
	
	Try
		Constants.UseFullTextSearch.Set(UseFullTextSearch);	
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// See FullTextSearchServer.UseSearchFlagValue
Function UseSearchFlagValue() Export

	Return FullTextSearchServer.UseSearchFlagValue();

EndFunction

#EndRegion


///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Parameters:
//  Id - String
//  Version - String
//  ThePathToTheLayoutToSearchForTheLatestVersion - String
//
// Returns:
//   See AddInsInternal.SavedAddInInformation
//
Function SavedAddInInformation(Val Id, Val Version = Undefined, 
	Val ThePathToTheLayoutToSearchForTheLatestVersion = Undefined) Export
	
	Result = AddInsInternal.SavedAddInInformation(Id, Version, ThePathToTheLayoutToSearchForTheLatestVersion);
	If Result.State = "FoundInStorage" Or Result.State = "FoundInSharedStorage" Then 
		Version = Result.Attributes.Version;
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với tên định danh %1 (phiên bản %2) đã nhận cấu phần ngoài %3 (phiên bản %4) từ danh mục.
			|Trạng thái: %5';
			|ru = 'Для идентификатора %1 (версия %2) получена внешняя компонента %3 (версия %4) из справочника.
			|Состояние: %5';
			|en = 'For the %1 ID (version %2), the %3 add-in (version %4) is received from the catalog.
			|State: %5'; fa = 'For the %1 ID (version %2), the %3 add-in (version %4) is received from the catalog.
			|State: %5';
			|it = 'Для идентификатора %1 (версия %2) получена внешняя компонента %3 (версия %4) из справочника.
			|Состояние: %5';
			|pl = 'For the %1 ID (version %2), the %3 add-in (version %4) is received from the catalog.
			|State: %5';
			|tr = '%1 kimlik için (sürüm %2) harici bileşen %3 (versiyon %4) katalogdan alındı. 
			|Durum: %5'"), 
			Id, ?(Version <> Undefined, Version, NStr("vi = 'chưa chỉ ra';
														|ru = 'не указана';
														|en = 'not specified'; fa = 'مشخص نشده';
														|it = 'non specificato';
														|pl = 'nie określona';
														|tr = 'belirtilmemiş'")), Result.Attributes.Description, 
			Result.Attributes.Version, Result.State);
		WriteLogEvent(NStr("vi = 'Cấu phần ngoài';
							|ru = 'Внешние компоненты';
							|en = 'Add-ins'; fa = 'افزونه‌ها';
							|it = 'Componenti esterni';
							|pl = 'Komponenty zewnętrzne';
							|tr = 'Dış bileşenler'", Common.DefaultLanguageCode()),
			EventLogLevel.Information,, Result.Ref, MessageText);
	Else
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với tên định danh %1 (phiên bản %2) trong danh mục không có cấu phần ngoài phù hợp.
			|Trạng thái: %3';
			|ru = 'Для идентификатора %1 (версия %2) в справочнике нет подходящей внешней компоненты.
			|Состояние: %3';
			|en = 'For the %1 ID (version %2), there is no appropriate add-in in the catalog.
			|State: %3'; fa = 'For the %1 ID (version %2), there is no appropriate add-in in the catalog.
			|State: %3';
			|it = 'Для идентификатора %1 (версия %2) в справочнике нет подходящей внешней компоненты.
			|Состояние: %3';
			|pl = 'For the %1 ID (version %2), there is no appropriate add-in in the catalog.
			|State: %3';
			|tr = '%1 kimlik için (sürüm %2) katalogda uygun harici bileşenler mevcut değil.
			|Durum: %3'"),
			Id, ?(Version <> Undefined, Version, NStr("vi = 'chưa chỉ ra';
														|ru = 'не указана';
														|en = 'not specified'; fa = 'مشخص نشده';
														|it = 'non specificato';
														|pl = 'nie określona';
														|tr = 'belirtilmemiş'")), Result.State);
		WriteLogEvent(NStr("vi = 'Cấu phần ngoài';
							|ru = 'Внешние компоненты';
							|en = 'Add-ins'; fa = 'افزونه‌ها';
							|it = 'Componenti esterni';
							|pl = 'Komponenty zewnętrzne';
							|tr = 'Dış bileşenler'", Common.DefaultLanguageCode()),
			EventLogLevel.Information,,, MessageText);
	EndIf;
	Return Result;
	
EndFunction

// Parameters:
//  References - Array of CatalogRef.AddIns
// 
// Returns:
//  Array of Structure:
//   * Location - String
//   * FileName - String
//
Function AddInsFilesDetails(Val References) Export
	
	Result = New Array;
	
	AttributesValues = Common.ObjectsAttributesValues(References, "FileName, Id");
	For Each KeyAndValue In AttributesValues Do
		AddInFileDetails = New Structure;
		AddInFileDetails.Insert("Location", 
			GetURL(KeyAndValue.Key, "AddInStorage"));
		FileName = KeyAndValue.Value.FileName;
		If Not ValueIsFilled(FileName) Then
			FileName = KeyAndValue.Value.Id + ".zip";
		EndIf;
		AddInFileDetails.Insert("Name", FileName);
		Result.Add(AddInFileDetails);
	EndDo;
	
	Return Result;
	
EndFunction

Function TemplateAddInInfo(Val Location) Export
	Return AddInsInternal.TemplateAddInInfo(Location);
EndFunction

#EndRegion


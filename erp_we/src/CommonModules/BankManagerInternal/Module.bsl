///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Not Common.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.Procedure = "Catalogs.BankClassifier.ProcessDataForMigrationToNewVersion";
		Handler.Version = "3.1.11.1";
		Handler.ExecutionMode = "Deferred";
		Handler.Id = New UUID("ffab8bb3-4bb1-4dde-9283-8328c8ede4d9");
		Handler.UpdateDataFillingProcedure = "Catalogs.BankClassifier.RegisterDataToProcessForMigrationToNewVersion";
		Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
		Handler.Comment = NStr("vi = 'Điền mã quốc gia trong Danh mục Mã ngân hàng.';
								|ru = 'Заполняет код страны в Справочнике БИК.';
								|en = 'Populates country code in the ""Bank codes"" catalog.'; fa = 'Populates country code in the ""Bank codes"" catalog.';
								|it = 'Populates country code in the ""Bank codes"" catalog.';
								|pl = 'Populates country code in the ""Bank codes"" catalog.';
								|tr = 'BIC Kataloğu''ndaki ülke kodunu doldurur.'");
		
		Editable1 = New Array;
		Editable1.Add(Metadata.Catalogs.BankClassifier.FullName());
		Handler.ObjectsToChange = StrConcat(Editable1, ",");
		
		ToLock = New Array;
		ToLock.Add(Metadata.Catalogs.BankClassifier.FullName());
		Handler.ObjectsToLock = StrConcat(ToLock, ",");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Determines if classifier data update is necessary.
//
Function ClassifierUpToDate() Export
	
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		Return DataProcessors[DataProcessorName].ClassifierUpToDate();
	EndIf;
	
	Return True;
	
EndFunction

Function ClassifierEmpty()
	
	QueryText =
	"SELECT TOP 1
	|	BankClassifier.Ref AS Ref
	|FROM
	|	Catalog.BankClassifier AS BankClassifier";
	
	Query = New Query(QueryText);
	Return Query.Execute().IsEmpty();
	
EndFunction

Function PromptToImportClassifier() Export
	
	Return Not Common.DataSeparationEnabled() And ClassifierEmpty();
	
EndFunction

#EndRegion

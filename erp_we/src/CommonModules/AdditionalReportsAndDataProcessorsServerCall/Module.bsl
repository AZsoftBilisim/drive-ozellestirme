///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Attaches an external report or data processor.
// For details, See AdditionalReportsAndDataProcessors.AttachExternalDataProcessor.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - a data processor to attach.
//
// Returns: 
//   String       - a name of the attached report or data processor.
//   Undefined - if an invalid reference is passed.
//
Function AttachExternalDataProcessor(Ref) Export // ACC:469 
	
	Return AdditionalReportsAndDataProcessors.AttachExternalDataProcessor(Ref);
	
EndFunction

// Creates and returns an instance of an external report or data processor.
// For details, See AdditionalReportsAndDataProcessors.ExternalDataProcessorObject.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - a report or a data processor to attach.
//
// Returns:
//   ExternalDataProcessor 
//   ExternalReport     
//   Undefined     - if an invalid reference is passed.
//
Function ExternalDataProcessorObject(Ref) Export
	
	Return AdditionalReportsAndDataProcessors.ExternalDataProcessorObject(Ref);
	
EndFunction


// See AdditionalReportsAndDataProcessors.ExecuteCommand.
Function ExecuteCommand(CommandParameters, ResultAddress = Undefined) Export
	
	Return AdditionalReportsAndDataProcessors.ExecuteCommand(CommandParameters, ResultAddress);
	
EndFunction

Function PutInStorage(Ref, FormIdentifier) Export
	If TypeOf(Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") 
		Or Ref = Catalogs.AdditionalReportsAndDataProcessors.EmptyRef() Then
		Return Undefined;
	EndIf;
	If Not AdditionalReportsAndDataProcessors.CanExportDataProcessorToFile(Ref) Then
		Raise(NStr("vi = 'Không đủ quyền để kết xuất tệp báo cáo và bộ xử lý bổ sung.';
					|ru = 'Недостаточно прав для выгрузки файлов дополнительных отчетов и обработок.';
					|en = 'Insufficient rights to export additional report or data processor files.'; fa = 'Insufficient rights to export additional report or data processor files.';
					|it = 'Недостаточно прав для выгрузки файлов дополнительных отчетов и обработок.';
					|pl = 'Insufficient rights to export additional report or data processor files.';
					|tr = 'Ek raporların ve veri işlemcilerinin dosyalarını dışa aktarmak için yetersiz haklar.'"),
			ErrorCategory.AccessViolation);
	EndIf;
	
	DataProcessorStorage = Common.ObjectAttributeValue(Ref, "DataProcessorStorage");
	Return PutToTempStorage(DataProcessorStorage.Get(), FormIdentifier);
EndFunction

Function StartTimeConsumingOperation(Val UUID, Val CommandParameters) Export
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.WaitCompletion = 0;
	StartSettings1.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thực hiện báo cáo hoặc bộ xử lý bổ sung ""%1"", tên lệnh ""%2""';
			|ru = 'Выполнение дополнительного отчета или обработки ""%1"", имя команды ""%2""';
			|en = 'Running %1 additional report or data processor, command name: %2.'; fa = 'Running %1 additional report or data processor, command name: %2.';
			|it = 'Esecuzione del report o dell''elaborazione aggiuntiva ""%1"", nome del comando ""%2""';
			|pl = 'Wykonanie raportu lub przetwarzania dodatkowego ""%1"", nazwa polecenia ""%2""';
			|tr = 'Ek rapor veya veri işlemcisi çalıştırılıyor ""%1"", komut adı ""%2""'"),
		String(CommandParameters.AdditionalDataProcessorRef),
		CommandParameters.CommandID);
	
	Return TimeConsumingOperations.ExecuteInBackground("AdditionalReportsAndDataProcessors.ExecuteCommand",
		CommandParameters, StartSettings1);
	
EndFunction

Function IsPostingAvailable(References) Export
	
	RefsTypes = New Map;
	
	For Each Ref In References Do
		If Ref = Undefined Then
			Continue;
		EndIf;
		Type = TypeOf(Ref);
		If RefsTypes[Type] = Undefined Then
			RefsTypes[Type] = New Array;
		EndIf;
		RefsTypes[Type].Add(Ref);
	EndDo;
	
	If Not ValueIsFilled(RefsTypes) Then
		Return False;
	EndIf;
	
	For Each RefsType In RefsTypes Do
		MetadataObject = Metadata.FindByType(RefsType.Key);
		If MetadataObject = Undefined Or Not Common.IsDocument(MetadataObject) 
			Or MetadataObject.Posting = Metadata.ObjectProperties.Posting.Deny Then
				Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion

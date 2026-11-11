///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region InternalEventsHandlers

#Region StandardSubsystems

#Region Core

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
//
// Parameters:
//   See the OnSendDataToMaster event handler in Syntax Assistant.
// 
Procedure OnSendDataToMaster(DataElement, ItemSend, Recipient) Export
	
	If ItemSend = DataItemSend.Ignore Then
		//
	ElsIf Common.IsStandaloneWorkplace() Then
		
		If TypeOf(DataElement) = Type("CatalogObject.AdditionalReportsAndDataProcessors") Then
			
			If Not IsServiceProcessing(DataElement.Ref) Then
				ItemSend = DataItemSend.Ignore;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
//
// Parameters:
//   See the OnSendDataToSlave event handler in Syntax Assistant.
// 
Procedure OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If ItemSend = DataItemSend.Delete
		Or ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
		
	If TypeOf(DataElement) = Type("CatalogObject.AdditionalReportsAndDataProcessors") Then
		If AdditionalReportsAndDataProcessorsSaaS.IsSuppliedDataProcessor(DataElement.Ref) Then
			DataProcessorStartupParameters = AdditionalReportsAndDataProcessorsSaaS.DataProcessorToUseAttachmentParameters(DataElement.Ref);
			FillPropertyValues(DataElement, DataProcessorStartupParameters);
		EndIf;
	EndIf;
	
	If TypeOf(DataElement) = Type("ConstantValueManager.UseAdditionalReportsAndDataProcessors") Then
		If Not InitialImageCreating Then
			ItemSend = DataItemSend.Ignore;
		EndIf;
	EndIf;
	
EndProcedure

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
//
// Parameters:
//   See the OnReceiveDataFromMaster event handler in Syntax Assistant.
// 
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender) Export
	
	If ItemReceive = DataItemReceive.Ignore Then
		
		// No overriding for standard processing
		
	ElsIf Common.IsStandaloneWorkplace() Then
		
		If TypeOf(DataElement) = Type("CatalogObject.AdditionalReportsAndDataProcessors") Then
			
			If ValueIsFilled(DataElement.Ref) Then
				DataProcessorRef1 = DataElement.Ref;
			Else
				DataProcessorRef1 = DataElement.GetNewObjectRef();
			EndIf;
			
			RegisterServiceProcessing(DataProcessorRef1);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure handles the same-name event that occurs during data exchange
// in a distributed infobase.
//
// Parameters:
//   See the OnReceiveDataFromSlave event handler in Syntax Assistant.
// 
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If ItemReceive = DataItemReceive.Ignore Then
		
		// No overriding for standard processing
		
	Else
		
		If TypeOf(DataElement) = Type("CatalogObject.AdditionalReportsAndDataProcessors") Then
			
			If AdditionalReportsAndDataProcessorsSaaS.IsSuppliedDataProcessor(DataElement.Ref) Then
				
				DataProcessorStartupParameters = AdditionalReportsAndDataProcessorsSaaS.DataProcessorToUseAttachmentParameters(DataElement.Ref);
				FillPropertyValues(DataElement, DataProcessorStartupParameters);
				DataElement.DataProcessorStorage = Undefined;
				
			Else
				
				If Not GetFunctionalOption("IndependentUsageOfAdditionalReportsAndDataProcessorsSaaS") Then
					ItemReceive = DataItemReceive.Ignore;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region AdditionalReportsAndDataProcessors

// Call to determine whether the current user has right to add an additional
// report or data processor to a data area.
//
// Parameters:
//  AdditionalDataProcessor - CatalogObject.AdditionalReportsAndDataProcessors, catalog item
//    written by user.
//  Result - Boolean - indicates whether the required rights are granted.
//  StandardProcessing - Boolean - flag specifying whether
//    standard processing is used to validate rights.
//
Procedure OnCheckInsertRight(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	If Common.IsStandaloneWorkplace() Then
		
		Result = True;
		StandardProcessing = False;
		Return;
		
	EndIf;
	
EndProcedure

// Called to check whether an additional report or data processor can be imported from file.
//
// Parameters:
//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors,
//  Result - Boolean - indicates whether additional reports or data processors can be
//    imported from files.
//  StandardProcessing - Boolean - indicates whether
//    standard processing checks if additional reports or data processors can be imported from files.
//
Procedure OnCheckCanImportDataProcessorFromFile(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	SetPrivilegedMode(True);
	
	If Common.IsStandaloneWorkplace() Then
		
		Result = Not IsServiceProcessing(AdditionalDataProcessor);
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

// Called to check whether an additional report or data processor can be exported to a file.
//
// Parameters:
//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors,
//  Result - Boolean - indicates whether additional reports or data processors can be
//    exported to files.
//  StandardProcessing - Boolean - indicates whether
//    standard processing checks if additional reports or data processors can be exported to files.
//
Procedure OnCheckCanExportDataProcessorToFile(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	SetPrivilegedMode(True);
	
	If Common.IsStandaloneWorkplace() Then
		
		Result = Not IsServiceProcessing(AdditionalDataProcessor);
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

// Fills additional report or data processor publication kinds that cannot be used
// in the current infobase model.
//
// Parameters:
//  NotAvailablePublicationKinds - Array of String
//
Procedure OnFillUnavailablePublicationKinds(Val NotAvailablePublicationKinds) Export
	
	If Common.IsStandaloneWorkplace() Then
		NotAvailablePublicationKinds.Add("DebugMode");
	EndIf;
	
EndProcedure

// The procedure is called from the "BeforeWrite" event of catalog
//  "AdditionalReportsAndDataProcessors". Validates changes to the catalog item
//  attributes for additional data processors retrieved from the
//  additional data processor directory from the service manager.
//
// Parameters:
//  Source - CatalogObject.AdditionalReportsAndDataProcessors,
//  Cancel - Boolean - indicates whether writing a catalog item must be canceled.
//
Procedure BeforeWriteAdditionalDataProcessor(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		
		If (Source.DeletionMark Or Source.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.TurnedOff) And IsServiceProcessing(Source.Ref) Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Báo cáo hoặc xử lý bổ sung %1 đã được kết nhập từ dịch vụ và không thể ngắt kết nối khỏi chỗ làm việc độc lập.
					|Để xóa báo cáo hoặc xử lý bổ sung, hãy thực hiện thao tác ngắt kết nối trong ứng dụng dịch vụ
					|và đồng bộ dữ liệu giữa chỗ làm việc độc lập với dịch vụ.';
					|ru = 'Дополнительный отчет или обработка %1 был загружен из сервиса и не может быть отключен из автономного рабочего места.
					|Для удаления дополнительного отчета или обработки выполните операцию отключения в
					|приложении сервиса и проведите синхронизацию данных автономного рабочего места с сервисом.';
					|en = 'Additional report or data processor %1 was imported from the service and cannot be disabled from the standalone workstation.
					|To remove the additional report or data processor, perform a disconnection operation
					|in the service application and synchronize the standalone workstation data with the service.'; fa = 'Additional report or data processor %1 was imported from the service and cannot be disabled from the standalone workstation.
					|To remove the additional report or data processor, perform a disconnection operation
					|in the service application and synchronize the standalone workstation data with the service.';
					|it = 'Il report aggiuntivo o elaborazione %1 è stato scaricato dal servizio e non può essere disattivato dalla postazione di lavoro autonoma.
					|Per l''eliminazione del report aggiuntivo o elaborazione, eseguire l''operazione di disattivazione nell''
					|app del servizio e sincronizzare i dati della postazione di lavoro autonoma con il servizio.';
					|pl = 'Dodatkowy raport lub przetwarzanie %1 został pobrany z usługi i nie może być odłączony z auto miejsca pracy.
					|W celu usunięcia dodatkowego raportu lub przetwarzania wykonaj operację odłączenia w
					|aplikacji usługi i wykonaj synchronizację danych autonomicznego miejsca pracy z usługą.';
					|tr = '%1 ek rapor veya veri işlemcisi servisten indirildi ve çevrimdışı çalışma alanıyla bağlantısı kesilemez.
					|Ek bir raporu veya veri işlemcisini silmek için servis uygulamasını devre dışı bırakın
					|ve çevrimdışı çalışma alanı verilerini servisle senkronize edin.'"),
				Source.Description);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndRegion

#Region Private

// It registers an additional report or a data processor as a data processor received
// to a standalone workstation from the service.
//
// Parameters:
//  Ref - CatalogRef.AdditionalReportsAndDataProcessors
//
Procedure RegisterServiceProcessing(Val Ref)
	
	Set = InformationRegisters.UseAdditionalReportsAndServiceProcessorsAtStandaloneWorkstation.CreateRecordSet();
	Set.Filter.AdditionalReportOrDataProcessor.Set(Ref);
	Record = Set.Add();
	Record.AdditionalReportOrDataProcessor = Ref;
	Record.Supplied = True;
	Set.Write();
	
EndProcedure

// The function checks whether an additional data processor was received to a standalone workstation from the service.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors
//
// Returns:
//  Boolean
//
Function IsServiceProcessing(Ref)
	
	Manager = InformationRegisters.UseAdditionalReportsAndServiceProcessorsAtStandaloneWorkstation.CreateRecordManager();
	Manager.AdditionalReportOrDataProcessor = Ref;
	Manager.Read();
	
	If Manager.Selected() Then
		Return Manager.Supplied;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion

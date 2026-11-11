///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ExchangePlansWithRulesFromFile") Then
		
		Items.RulesSource.Visible = False;
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"RulesSource",
			Enums.DataExchangeRulesSources.File,
			DataCompositionComparisonType.Equal);
		
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateAllStandardRules(Command)
	
	UpdateAllStandardRulesAtServer();
	Items.List.Refresh();
	
	ShowUserNotification(NStr("vi = 'Đã cập nhật quy tắc thành công.';
								|ru = 'Обновление правил успешно завершено.';
								|en = 'The rule update is completed.'; fa = 'The rule update is completed.';
								|it = 'L''aggiornamento delle regole è stato effettuato con successo.';
								|pl = 'Aktualizacja reguł zakończona powodzeniem.';
								|tr = 'Kurallar başarıyla güncellendi.'"));
	
EndProcedure

&AtClient
Procedure UseStandardRules(Command)
	UseStandardRulesAtServer();
	Items.List.Refresh();
	ShowUserNotification(NStr("vi = 'Đã cập nhật quy tắc thành công.';
								|ru = 'Обновление правил успешно завершено.';
								|en = 'The rule update is completed.'; fa = 'The rule update is completed.';
								|it = 'L''aggiornamento delle regole è stato effettuato con successo.';
								|pl = 'Aktualizacja reguł zakończona powodzeniem.';
								|tr = 'Kurallar başarıyla güncellendi.'"));
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateAllStandardRulesAtServer()
	
	DataExchangeServer.UpdateDataExchangeRules();
	
	RefreshReusableValues();
	
EndProcedure

&AtServer
Procedure UseStandardRulesAtServer()
	
	For Each Record In Items.List.SelectedRows Do
		BeginTransaction();

		Try
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.DataExchangeRules");
			DataLockItem.SetValue("ExchangePlanName", Record.ExchangePlanName);
			DataLockItem.SetValue("RulesKind", Record.RulesKind);
			DataLockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();

			RecordManager = InformationRegisters.DataExchangeRules.CreateRecordManager();
			FillPropertyValues(RecordManager, Record);
			RecordManager.Read();
			RecordManager.RulesSource = Enums.DataExchangeRulesSources.ConfigurationTemplate;

			HasErrors = False;
			InformationRegisters.DataExchangeRules.ImportRules(HasErrors, RecordManager);

			If HasErrors Then
				RollbackTransaction();
			Else
				RecordManager.Write();
				CommitTransaction();
			EndIf;
		Except
			RollbackTransaction();

			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

			Event = NStr("vi = 'Обмен данными.Обновление правил';
						|ru = 'Обмен данными.Обновление правил';
						|en = 'Data exchange.Update rules'; fa = 'Data exchange.Update rules';
						|it = 'Обмен данными.Обновление правил';
						|pl = 'Data exchange.Update rules';
						|tr = 'Обмен данными.Обновление правил'", Common.DefaultLanguageCode());

			WriteLogEvent(Event, EventLogLevel.Error,
				Metadata.InformationRegisters.DataExchangeRules, , ErrorMessage);
		EndTry;
	EndDo;
	
	DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
	RefreshReusableValues();
	
EndProcedure

#EndRegion

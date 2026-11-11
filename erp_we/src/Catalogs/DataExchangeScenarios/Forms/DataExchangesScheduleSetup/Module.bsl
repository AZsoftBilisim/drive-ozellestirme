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
	
	SetConditionalAppearance();
	
	DataExchangeServer.UpdateRoutineTasks();
	
	List.Parameters.Items[0].Value = Parameters.InfobaseNode;
	List.Parameters.Items[0].Use = True;
	
	Title = NStr("vi = 'Kịch bản đồng bộ dữ liệu đối với: [InfobaseNode]';
				|ru = 'Сценарии синхронизации данных для: [InfobaseNode]';
				|en = 'Synchronization scenario setup for: [InfobaseNode]'; fa = 'Synchronization scenario setup for: [InfobaseNode]';
				|it = 'Scenari di sincronizzazione dati per: [InfobaseNode]';
				|pl = 'Scenariusz synchronizacji danych dla: [InfobaseNode]';
				|tr = 'Şunlar için veri senkronizasyonu senaryoları:[InfobaseNode]'");
	Title = StrReplace(Title, "[InfobaseNode]", String(Parameters.InfobaseNode));
	
	If Common.DataSeparationEnabled() Then
		Items.EnableDisableExportImport.Visible = False;
		Items.FormExecuteScenario.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_DataExchangeScenarios" Then
		
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.ImportUsageFlag Then
		
		EnableDisableImportAtServer(CurrentData.ImportUsageFlag, CurrentData.Ref);
		
	ElsIf Field = Items.ExportUsageFlag Then
		
		EnableDisableExportAtServer(CurrentData.ExportUsageFlag, CurrentData.Ref);
		
	ElsIf Field = Items.Description Then
		
		ChangeDataExchangeScenario(Undefined);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Create(Command)
	
	FormParameters = New Structure("InfobaseNode", Parameters.InfobaseNode);
	
	OpenForm("Catalog.DataExchangeScenarios.ObjectForm", FormParameters, ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChangeDataExchangeScenario(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", CurrentData.Ref);
	
	OpenForm("Catalog.DataExchangeScenarios.ObjectForm", FormParameters, ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure EnableDisableScheduledJob(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	EnableDisableScheduledJobAtServer(CurrentData.Ref);
	
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure EnableDisableExport(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	EnableDisableExportAtServer(CurrentData.ExportUsageFlag, CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure EnableDisableImport(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	EnableDisableImportAtServer(CurrentData.ImportUsageFlag, CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure EnableDisableImportExport(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	EnableDisableImportExportAtServer(CurrentData.ImportUsageFlag Or CurrentData.ExportUsageFlag, CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure ExecuteScenario(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Cancel = False;
	
	// Start a data exchange.
	DataExchangeServerCall.ExecuteDataExchangeByDataExchangeScenario(Cancel, CurrentData.Ref);
	
	If Cancel Then
		Message = NStr("vi = 'Đã thực hiện kịch bản đồng bộ bị lỗi.';
						|ru = 'Сценарий синхронизации выполнен с ошибками.';
						|en = 'The synchronization scenario completed with errors.'; fa = 'The synchronization scenario completed with errors.';
						|it = 'Lo scenario di sincronizzazione è stato completato con degli errori.';
						|pl = 'Scenariusz synchronizacji został wykonany z błędami.';
						|tr = 'Veri senkronizasyonu senaryosu hatalarla tamamlandı.'");
		Picture = PictureLib.Error32;
	Else
		Message = NStr("vi = 'Đã thực hiện thành công kịch bản đồng bộ.';
						|ru = 'Сценарий синхронизации успешно выполнен.';
						|en = 'The synchronization scenario is completed.'; fa = 'The synchronization scenario is completed.';
						|it = 'Lo scenario di sincronizzazione è stato completato con successo.';
						|pl = 'Scenariusz synchronizacji został wykonany pomyślnie.';
						|tr = 'Senkronizasyon senaryosu başarı ile tamamlandı.'");
		Picture = Undefined;
	EndIf;
	ShowUserNotification(Message,,,Picture);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//   Ref - CatalogRef.DataExchangeScenarios - Data exchange scenario.
//
&AtServerNoContext
Procedure EnableDisableScheduledJobAtServer(Ref)
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("Catalog.DataExchangeScenarios");
		LockItem.SetValue("Ref", Ref);
		Block.Lock();
		
		LockDataForEdit(Ref);
		ScenarioObject = Ref.GetObject();
		
		ScenarioObject.UseScheduledJob = Not ScenarioObject.UseScheduledJob;
		
		Cancel = False;
		Schedule = Catalogs.DataExchangeScenarios.GetDataExchangeExecutionSchedule(Ref);
		Catalogs.DataExchangeScenarios.UpdateScheduledJobData(Cancel, Schedule, ScenarioObject);
		
		ScenarioObject.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Procedure EnableDisableExportAtServer(Val ExportUsageFlag, Val DataExchangeScenario)
	
	If ExportUsageFlag Then
		
		Catalogs.DataExchangeScenarios.DeleteExportToDataExchangeScenarios(DataExchangeScenario, Parameters.InfobaseNode);
		
	Else
		
		Catalogs.DataExchangeScenarios.AddExportToDataExchangeScenarios(DataExchangeScenario, Parameters.InfobaseNode);
		
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure EnableDisableImportAtServer(Val ImportUsageFlag, Val DataExchangeScenario)
	
	If ImportUsageFlag Then
		
		Catalogs.DataExchangeScenarios.DeleteImportToDataExchangeScenarios(DataExchangeScenario, Parameters.InfobaseNode);
		
	Else
		
		Catalogs.DataExchangeScenarios.AddImportToDataExchangeScenarios(DataExchangeScenario, Parameters.InfobaseNode);
		
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure EnableDisableImportExportAtServer(Val UsageFlag, Val DataExchangeScenario)
	
	EnableDisableImportAtServer(UsageFlag, DataExchangeScenario);
	
	EnableDisableExportAtServer(UsageFlag, DataExchangeScenario);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.UsageFlag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("BackColor", WebColors.Azure);
	
EndProcedure

#EndRegion
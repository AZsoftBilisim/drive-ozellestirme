///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var ChoiceContext;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("vi = 'Quản lý phần tổng kết và phần thống kê không khả dụng trong mô hình dịch vụ.';
					|ru = 'Управление итогами и агрегатами недоступно в модели сервиса.';
					|en = 'Totals and aggregates are unavailable in SaaS.'; fa = 'Totals and aggregates are unavailable in SaaS.';
					|it = 'La gestione dei totali e aggregati non è disponibile nel modulo di servizio.';
					|pl = 'Zarządzanie wynikami i agregatami jest niedostępne w modelu serwisu.';
					|tr = 'Hizmet modelinde toplamlar ve agregalar yönetimi mevcut değildir.'");
	EndIf;
	
	If Not Users.IsFullUser() Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	ReadInformationOnRegisters();
	
	UpdateTotalsListAtServer();
	UpdateAggregatesByRegistersAtServer();
	
	If AggregatesByRegisters.Count() <> 0 Then
		Items.AggregatesList.Title = Prefix() + " " + AggregatesByRegisters[0].Description;
	Else
		Items.AggregatesList.Title = Prefix();
	EndIf;
	
	If TotalsList.Count() = 0 Then
		Items.TotalsGroup.Enabled = False;
		Items.SetTotalsPeriod.Enabled = False;
		Items.EnableTotalsUsage.Enabled = False;
	EndIf;
	
	If AggregatesByRegisters.Count() = 0 Then
		Items.AggregatesGroup.Enabled = False;
		Items.RebuildAndFillAggregates.Enabled = False;
		Items.GetOptimalAggregates.Enabled = False;
	EndIf;
	
	Items.Operations.PagesRepresentation = FormPagesRepresentation.None;
	
	SetAdvancedMode();
	
	CalculateTotalsFor = CurrentSessionDate();
	
	Items.PeriodSettingDescription.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.PeriodSettingDescription.Title,
		Format(PeriodEnding(AddMonth(CalculateTotalsFor, -1)), "DLF=D"),
		Format(PeriodEnding(CalculateTotalsFor), "DLF=D"));
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetAdvancedMode();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("DataProcessor.TotalsAndAggregatesManagement.Form.PeriodChoiceForm") Then
		
		If TypeOf(ValueSelected) <> Type("Structure") Then
			Return;
		EndIf;
		
		TotalsParameters = New Structure;
		TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Thiết lập kỳ của phần tổng kết đã tính toán ...';
														|ru = 'Установка периода рассчитанных итогов ...';
														|en = 'Setting calculated totals period…'; fa = 'Setting calculated totals period…';
														|it = 'Impostazione del periodo dei totali calcolati ...';
														|pl = 'Ustawienie okresu obliczonych wyników...';
														|tr = 'Hesaplanan toplamların dönemini ayarlama...'"));
		TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất thiết lập kỳ của phần tổng kết đã tính toán';
																|ru = 'Установка периода рассчитанных итогов завершена';
																|en = 'Setting of calculated totals period is complete'; fa = 'Setting of calculated totals period is complete';
																|it = 'L''impostazione del periodo dei totali calcolati è stata completata';
																|pl = 'Ustawienie okresu obliczonych wyników jest zakończono';
																|tr = 'Hesaplanan toplamların dönemini ayarlama tamamlandı'"));
		TotalsParameters.Insert("Action",               "SetTotalPeriod");
		TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
		TotalsParameters.Insert("Field",                   "TotalsPeriod");
		TotalsParameters.Insert("Value1",              ValueSelected.PeriodForAccumulationRegisters);
		TotalsParameters.Insert("Value2",              ValueSelected.PeriodForAccountingRegisters);
		TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể thiết lập kỳ phần tổng kết đã tính.';
														|ru = 'Не удалось установить период рассчитанных итогов.';
														|en = 'Cannot set the calculated totals period.'; fa = 'Cannot set the calculated totals period.';
														|it = 'Impossibile impostare il periodo dei totali calcolati.';
														|pl = 'Nie udało się ustawić okres rozliczonych wyników.';
														|tr = 'Hesaplanan toplamların dönemi kurulamadı.'"));
		
		TotalsControl(TotalsParameters);
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.TotalsAndAggregatesManagement.Form.RebuildParametersForm") Then
		
		If TypeOf(ValueSelected) <> Type("Structure") Then
			Return;
		EndIf;
		
		If ChoiceContext = "RebuildAggregates" Then
			
			RelativeSize = ValueSelected.RelativeSize;
			MinimumEffect   = ValueSelected.MinimumEffect;
			
			TotalsParameters = New Structure;
			TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Tái tạo phần thống kê ...';
															|ru = 'Перестроение агрегатов ...';
															|en = 'Rebuilding aggregates…'; fa = 'Rebuilding aggregates…';
															|it = 'Ristrutturazione degli aggregati ...';
															|pl = 'Przebudowa agregatów ...';
															|tr = 'Agregaları yeniden oluşturma...'"));
			TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất tái tạo phần thống kê';
																	|ru = 'Перестроение агрегатов завершено';
																	|en = 'Aggregates are rebuilt'; fa = 'Aggregates are rebuilt';
																	|it = 'La ristrutturazione degli aggregati è stata completata';
																	|pl = 'Przebudowa agregatów jest zakończona';
																	|tr = 'Agregaları yeniden oluşturma tamamlandı'"));
			TotalsParameters.Insert("Action",               "RebuildAggregates");
			TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
			TotalsParameters.Insert("Field",                   "Description");
			TotalsParameters.Insert("Value1",              ValueSelected.RelativeSize);
			TotalsParameters.Insert("Value2",              ValueSelected.MinimumEffect);
			TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể xây dựng lại phần thống kê.';
															|ru = 'Не удалось перестроить агрегаты.';
															|en = 'Cannot rebuild aggregates.'; fa = 'Cannot rebuild aggregates.';
															|it = 'Impossibile ristrutturare aggregati.';
															|pl = 'Nie udało się przebudować agragatów.';
															|tr = 'Agregalar yeniden oluşturulamadı.'"));
			
			ChangeAggregatesClient(TotalsParameters);
			
		ElsIf ChoiceContext = "OptimalAggregates" Then
			
			OptimalRelativeSize = ValueSelected.RelativeSize;
			GetOptimalAggregatesClient();
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HyperlinkWithTextClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FullFunctionality = Not FullFunctionality;
	SetAdvancedMode();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTotalsList

&AtClient
Procedure TotalsListOnActivateRow(Item)
	
	AttachIdleHandler("TotalsListOnActivateRowDeferred", 0.1, True);	
		
EndProcedure

&AtClient
Procedure TotalsListOnActivateRowDeferred()
	
	TotalsListOnActivateRowAtServer();	
	
EndProcedure

&AtServer
Procedure TotalsListOnActivateRowAtServer()
		
	SelectedRows = Items.TotalsList.SelectedRows;
	
	RegistersWithTotalsSelected = False;
	RegistersWithTotalsAndBalanceSelected = False;
	RegistersWithTotalsSplitSelected = False;
	
	For Each RowID In SelectedRows Do
		TableRow =  TotalsList.FindByID(RowID);
		If TableRow = Undefined Then
			Continue;
		EndIf;
		If TableRow.AggregatesTotals = 0 Or TableRow.AggregatesTotals = 2 Then
			RegistersWithTotalsSelected = True;
			If TableRow.BalanceAndTurnovers Then
				RegistersWithTotalsAndBalanceSelected = True;
			EndIf;
		EndIf;
		If TableRow.EnableTotalsSplitting Then
			RegistersWithTotalsSplitSelected = True;
		EndIf;
	EndDo;
	
	Items.Totals1Group.Enabled              = RegistersWithTotalsSelected;
	Items.CurrentTotalsGroup.Enabled       = RegistersWithTotalsAndBalanceSelected;
	Items.TotalsSplittingGroup.Enabled   = RegistersWithTotalsSplitSelected;
	Items.SetTotalPeriod.Enabled   = RegistersWithTotalsAndBalanceSelected;	
	
EndProcedure
	
&AtClient
Procedure TotalsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	NameOfMetadataObject = TotalsList.FindByID(RowSelected).NameOfMetadataObject;
	If Field.Name = "TotalsAggregatesTotals" Then
		
		StandardProcessing = False;
		
		ResultArray = AggregatesByRegisters.FindRows(
			New Structure("NameOfMetadataObject", NameOfMetadataObject));
		
		If ResultArray.Count() > 0 Then
			
			IndexOf = AggregatesByRegisters.IndexOf(ResultArray[0]);
			CurrentItem = Items.AggregatesByRegisters;
			Items.AggregatesByRegisters.CurrentRow = IndexOf;
			Items.AggregatesByRegisters.CurrentItem = Items.AggregatesByRegistersDescription;
			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableTotalsUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Bật sử dụng phần tổng kết ...';
													|ru = 'Включение использования итогов ...';
													|en = 'Enabling totals…'; fa = 'Enabling totals…';
													|it = 'Abilitazione dell''utilizzo di totali ...';
													|pl = 'Włączenie używania wyników...';
													|tr = 'Toplamların kullanımını etkinleştirme...'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất bật sử dụng phần tổng kết';
															|ru = 'Включение использования итогов завершено';
															|en = 'Totals are enabled'; fa = 'Totals are enabled';
															|it = 'L''abilitazione dell''utilizzo di totali è stata completata';
															|pl = 'Włączenie używania wyników zostało zakończone';
															|tr = 'Toplamların kullanımını etkinleştirme tamamlandı'"));
	TotalsParameters.Insert("Action",               "SetTotalsUsing");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "UseTotals");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể bật sử dụng phần tổng kết.';
													|ru = 'Не удалось включить использование итогов.';
													|en = 'Cannot enable totals usage.'; fa = 'Cannot enable totals usage.';
													|it = 'Impossibile abilitare l''utilizzo di totali.';
													|pl = 'Nie udało się włączyć używanie wyników.';
													|tr = 'Toplamların kullanımı etkinleştirilemedi.'"));
	
	TotalsControl(TotalsParameters);

EndProcedure

&AtClient
Procedure EnableCurrentTotalsUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Bật sử dụng tổng kết hiện tại ...';
													|ru = 'Включение использования текущих итогов ...';
													|en = 'Enabling current totals…'; fa = 'Enabling current totals…';
													|it = 'Abilitazione dell''utilizzo di totali correnti ...';
													|pl = 'Włączenie używania bieżących wyników ...';
													|tr = 'Mevcut toplamların kullanılmasının etkinleştirilmesi...'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tât bật sử dụng tổng kết hiện tại';
															|ru = 'Включение использования текущих итогов завершено';
															|en = 'Current totals are enabled'; fa = 'Current totals are enabled';
															|it = 'L''abilitazione dell''utilizzo di totali correnti è stata completata';
															|pl = 'Włączenie używania bieżących wyników zostało zakończone';
															|tr = 'Mevcut toplamların kullanılmasının etkinleştirilmesi tamamlandı'"));
	TotalsParameters.Insert("Action",               "UseCurrentTotals");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "UseCurrentTotals");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể bật sử dụng phần tổng kết hiện tại.';
													|ru = 'Не удалось включить использование текущих итогов.';
													|en = 'Cannot enable usage of current subtotals.'; fa = 'Cannot enable usage of current subtotals.';
													|it = 'Impossibile abilitare l''utilizzo di totali correnti.';
													|pl = 'Nie udało się włączyć używanie bieżących wyników.';
													|tr = 'Mevcut toplamların kullanımı etkinleştirilemedi.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure DisableTotalsUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Tắt sử dụng phần tổng kết ...';
													|ru = 'Выключение использования итогов ...';
													|en = 'Disabling totals…'; fa = 'Disabling totals…';
													|it = 'Disabilitazione dell''utilizzo di totali ...';
													|pl = 'Wyłączenie używania wyników ...';
													|tr = 'Toplamların kullanımının kapatılması.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất tắt sử dụng phần tổng kết';
															|ru = 'Выключение использования итогов завершено';
															|en = 'Totals are disabled'; fa = 'Totals are disabled';
															|it = 'La disabilitazione dell''utilizzo di totali è stata completata';
															|pl = 'Wyłączenie używania wyników zostało zakończone';
															|tr = 'Toplamların kullanımının kapatılması tamamlandı'"));
	TotalsParameters.Insert("Action",               "SetTotalsUsing");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "UseTotals");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể tắt sử dụng phần tổng kết.';
													|ru = 'Не удалось выключить использование итогов.';
													|en = 'Cannot disable totals usage.'; fa = 'Cannot disable totals usage.';
													|it = 'Impossibile disabilitare l''utilizzo di totali.';
													|pl = 'Nie udało się wyłączyć używanie wyników.';
													|tr = 'Toplamların kullanımı kapatılamadı.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure DisableCurrentTotalsUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Tắt sử dụng phần tổng kết hiện tại ...';
													|ru = 'Выключение использования текущих итогов ...';
													|en = 'Disabling current totals…'; fa = 'Disabling current totals…';
													|it = 'Disabilitazione dell''utilizzo di totali correnti ...';
													|pl = 'Wyłączenie używania bieżących wyników ...';
													|tr = 'Mevcut toplamların kullanımının kapatılması.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất tắt sử dụng phần tổng kết hiện tại';
															|ru = 'Выключение использования текущих итогов завершено';
															|en = 'Current totals are disabled'; fa = 'Current totals are disabled';
															|it = 'La disabilitazione dell''utilizzo di totali correnti è stata completata';
															|pl = 'Wyłączenie używania bieżących wyników zostało zakończone';
															|tr = 'Mevcut toplamların kullanımının devre dışı bırakılması tamamlandı'"));
	TotalsParameters.Insert("Action",               "UseCurrentTotals");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "UseCurrentTotals");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể tắt sử dụng phần tổng kết hiện tại.';
													|ru = 'Не удалось выключить использование текущих итогов.';
													|en = 'Cannot disable usage of current subtotals.'; fa = 'Cannot disable usage of current subtotals.';
													|it = 'Impossibile disabilitare l''utilizzo di totali correnti.';
													|pl = 'Nie udało się wyłączyć używanie bieżących wyników.';
													|tr = 'Mevcut toplamların kullanımı kapatılamadı.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure UpdateTotalState(Command)
	
	UpdateTotalsListAtServer();
	
EndProcedure

&AtClient
Procedure SetTotalPeriod(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("AccumulationReg",  False);
	FormParameters.Insert("AccountingReg", False);
	
	For Each IndexOf In Items.TotalsList.SelectedRows Do
		RegisterInformation1 = TotalsList.FindByID(IndexOf);
		FormParameters.AccumulationReg  = FormParameters.AccumulationReg  Or RegisterInformation1.Type = 0;
		FormParameters.AccountingReg = FormParameters.AccountingReg Or RegisterInformation1.Type = 1;
	EndDo;
	
	OpenForm("DataProcessor.TotalsAndAggregatesManagement.Form.PeriodChoiceForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure EnableSplitTotals(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Bật chia tách phần tổng kết ...';
													|ru = 'Включение разделения итогов ...';
													|en = 'Enable totals separation…'; fa = 'Enable totals separation…';
													|it = 'Abilitazione della divisione di totali ...';
													|pl = 'Włączenie podziału wyników...';
													|tr = 'Bölünmüş toplamları etkinleştirme.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất bật chia tách phần tổng kết';
															|ru = 'Включение разделения итогов завершено';
															|en = 'Enabling of total separation is completed'; fa = 'Enabling of total separation is completed';
															|it = 'L''abilitazione della divisione di totali è stata completata';
															|pl = 'Włączenie podziału wyników zostało zakończone';
															|tr = 'Bölünmüş toplamların etkinleştirilmesi tamamlandı'"));
	TotalsParameters.Insert("Action",               "SetTotalsSeparation");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "TotalsSeparation");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể bật phân chia phần tổng kết.';
													|ru = 'Не удалось включить разделение итогов.';
													|en = 'Cannot enable totals split.'; fa = 'Cannot enable totals split.';
													|it = 'Impossibile disabilitare l''utilizzo di totali.';
													|pl = 'Nie udało się włączyć podział wyników.';
													|tr = 'Bölünmüş toplamlar etkinleştirilemedi.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure DisableTotalsSplitting(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Tắt chia tách phần tổng kết ...';
													|ru = 'Выключение разделения итогов ...';
													|en = 'Disable totals separation…'; fa = 'Disable totals separation…';
													|it = 'Disabilitazione della divisione di totali ...';
													|pl = 'Wyłączenie podziału wyników ...';
													|tr = 'Bölünmüş toplamların kapatılması.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất chia tách phần tổng kết';
															|ru = 'Выключение разделения итогов завершено';
															|en = 'Disabling division of totals is completed'; fa = 'Disabling division of totals is completed';
															|it = 'La disabilitazione della divisione di totali è stata completata';
															|pl = 'Wyłączenie podziału wyników zostało zakończone';
															|tr = 'Bölünmüş toplamların kapatılması tamamlandı'"));
	TotalsParameters.Insert("Action",               "SetTotalsSeparation");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "TotalsSeparation");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể tắt chia tách phần tổng kết.';
													|ru = 'Не удалось выключить разделение итогов.';
													|en = 'Cannot disable totals split.'; fa = 'Cannot disable totals split.';
													|it = 'Impossibile disabilitare la divisione di totali.';
													|pl = 'Nie udało się wyłączyć podział wyników.';
													|tr = 'Bölünmüş toplamlar kapatılamadı.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure UpdateAggregatesInformation(Command)
	
	UpdateAggregatesByRegistersAtServer();
	SetAggregatesListFilter();
	
EndProcedure

&AtClient
Procedure AggregatesByRegistersOnActivateRow(Item)
	
	SetAggregatesListFilter();
	
	If Item.CurrentData = Undefined Then
		ItemsAvailability = False;
		
	ElsIf Item.SelectionMode = TableSelectionMode.SingleRow Then
		ItemsAvailability = Item.CurrentData.AggregateMode;
	Else
		ItemsAvailability = True;
	EndIf;
	
	Items.AggregatesRebuildButton.Enabled                     = ItemsAvailability;
	Items.AggregatesClearAggregatesByRegistersButton.Enabled     = ItemsAvailability;
	Items.AggregatesFillAggregatesByRegistersButton.Enabled    = ItemsAvailability;
	Items.AggregatesOptimalButton.Enabled                     = ItemsAvailability;
	Items.AggregatesDisableAggregatesUsageButton.Enabled = ItemsAvailability;
	Items.AggregatesEnableAggregatesUsageButton.Enabled  = ItemsAvailability;
	
EndProcedure

&AtClient
Procedure EnableAggregateMode(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Bật chế độ phần thống kê ...';
													|ru = 'Включение режима агрегатов ...';
													|en = 'Enabling aggregates mode…'; fa = 'Enabling aggregates mode…';
													|it = 'Abilitazione della modalità di aggregati ...';
													|pl = 'Włączenie trybu agregatów ...';
													|tr = 'Agregalar modunun etkileştirilmesi.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất bật chế độ phần thống kê';
															|ru = 'Включение режима агрегатов завершено';
															|en = 'Aggregates mode is enabled'; fa = 'Aggregates mode is enabled';
															|it = 'L''abilitazione della modalità di aggregati è stata completata';
															|pl = 'Włączenie trybu agregatów zostało zakończone';
															|tr = 'Agregalar modunun etkinleştirilmesi tamamlandı'"));
	TotalsParameters.Insert("Action",               "SetAggregatesMode");
	TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
	TotalsParameters.Insert("Field",                   "AggregateMode");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể bật chế độ phần thống kê.';
													|ru = 'Не удалось включить режим агрегатов.';
													|en = 'Cannot enable aggregate mode.'; fa = 'Cannot enable aggregate mode.';
													|it = 'Impossibile abilitare la modalità di aggregati.';
													|pl = 'Nie udało się włączyć tryb agregatów.';
													|tr = 'Agregalar modu etkinleştirilemedi.'"));
	
	ChangeAggregatesClient(TotalsParameters);
	
EndProcedure

&AtClient
Procedure EnableTotalsMode(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Bật chế độ phần tổng kết ...';
													|ru = 'Включение режима итогов ...';
													|en = 'Enabling totals mode…'; fa = 'Enabling totals mode…';
													|it = 'Abilitazione della modalità totali ...';
													|pl = 'Włączenie trybu wyników...';
													|tr = 'Toplamlar modunun etkinleştirilmesi.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất bật chế độ phần tổng kết';
															|ru = 'Включение режима итогов завершено';
															|en = 'Totals mode is enabled'; fa = 'Totals mode is enabled';
															|it = 'L''abilitazione della modalità totali è stata completata';
															|pl = 'Włączenie trybu wyników zostało zakończone';
															|tr = 'Toplamlar modunun etkinleştirilmesi tamamlandı'"));
	TotalsParameters.Insert("Action",               "SetAggregatesMode");
	TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
	TotalsParameters.Insert("Field",                   "AggregateMode");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể bật chế độ phần tổng kết.';
													|ru = 'Не удалось включить режим итогов.';
													|en = 'Cannot enable totals mode.'; fa = 'Cannot enable totals mode.';
													|it = 'Impossibile disabilitare l''utilizzo della modalità totali.';
													|pl = 'Nie udało się włączyć tryb wyników.';
													|tr = 'Toplamlar modu etkinleştirilemedi.'"));
	
	ChangeAggregatesClient(TotalsParameters);
	
EndProcedure

&AtClient
Procedure EnableAggregatesUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Bật và sử dụng phần tổng kết ...';
													|ru = 'Включение использования агрегатов ...';
													|en = 'Enabling aggregates…'; fa = 'Enabling aggregates…';
													|it = 'Abilitazione dell''utilizzo di aggregati ...';
													|pl = 'Włączenie używania agregatów ...';
													|tr = 'Agregalar kullanımının etkinleştirilmesi.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất bật sử dụng phần tổng kết';
															|ru = 'Включение использования агрегатов завершено';
															|en = 'Aggregates are enabled'; fa = 'Aggregates are enabled';
															|it = 'L''abilitazione dell''utilizzo di aggregati è stata completata';
															|pl = 'Włączenie używania agregatów zostało zakończone';
															|tr = 'Agregalar kullanımının etkinleştirilmesi tamamlandı'"));
	TotalsParameters.Insert("Action",               "SetAggregatesUsing");
	TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
	TotalsParameters.Insert("Field",                   "AgregateUsage");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể bật sử dụng phần thống kê.';
													|ru = 'Не удалось включить использование агрегатов.';
													|en = 'Cannot enable aggregate usage.'; fa = 'Cannot enable aggregate usage.';
													|it = 'Impossibile abilitare l''utilizzo di aggregati.';
													|pl = 'Nie udało się włączyć używanie agregatów.';
													|tr = 'Agregaların kullanımı etkinleştirilemedi.'"));
	
	ChangeAggregatesClient(TotalsParameters);
	
EndProcedure

&AtClient
Procedure DisableAggregatesUsage(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Tắt sử dụng phần thống kê ...';
													|ru = 'Выключение использования агрегатов ...';
													|en = 'Disabling aggregates…'; fa = 'Disabling aggregates…';
													|it = 'Disabilitazione dell''utilizzo di aggregati ...';
													|pl = 'Wyłączenie używania agregatów ...';
													|tr = 'Agregaların kullanımını kapatma.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất tắt sử dụng phần thống kê';
															|ru = 'Выключение использования агрегатов завершено';
															|en = 'Aggregates are disabled'; fa = 'Aggregates are disabled';
															|it = 'La disabilitazione dell''utilizzo di aggregati è stata completata';
															|pl = 'Wyłączenie używania agregatów zostało zakończone';
															|tr = 'Agregaların kullanımını kapatılması tamamlandı'"));
	TotalsParameters.Insert("Action",               "SetAggregatesUsing");
	TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
	TotalsParameters.Insert("Field",                   "AgregateUsage");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể tắt sử dụng phần thống kê.';
													|ru = 'Не удалось выключить использование агрегатов.';
													|en = 'Cannot disable aggregate usage.'; fa = 'Cannot disable aggregate usage.';
													|it = 'Impossibile disabilitare l''utilizzo di aggregati.';
													|pl = 'Nie udało się wyłączyć używanie agregatów.';
													|tr = 'Agregaların kullanımı devre dışı bırakılamadı.'"));
	
	ChangeAggregatesClient(TotalsParameters);
	
EndProcedure

&AtClient
Procedure RebuildAggregates(Command)
	
	ChoiceContext = "RebuildAggregates";
	
	FormParameters = New Structure;
	FormParameters.Insert("RelativeSize", RelativeSize);
	FormParameters.Insert("MinimumEffect",   MinimumEffect);
	FormParameters.Insert("RebuildMode",   True);
	
	OpenForm("DataProcessor.TotalsAndAggregatesManagement.Form.RebuildParametersForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ClearAggregatesByRegisters(Command)
	
	QueryText = NStr("vi = 'Xóa phần tổng kết có thể dẫn đến làm chậm đáng kể báo cáo.';
					|ru = 'Очистка агрегатов может привести к существенному замедлению отчетов.';
					|en = 'Aggregate cleanup may significantly slow down the reports.'; fa = 'Aggregate cleanup may significantly slow down the reports.';
					|it = 'La cancellazione di aggregati potrebbe comportare il rallentamento significativo dei report.';
					|pl = 'Oczyszczenie agregatów może doprowadzić do znacznego spowolnienia raportów.';
					|tr = 'Agregaların temizlenmesi, raporların önemli ölçüde yavaşlamasına neden olabilir.'");
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa phần tổng kết';
											|ru = 'Очистить агрегаты';
											|en = 'Clear aggregates'; fa = 'پاک کردن تجمیع‌ها';
											|it = 'Cancellare aggregati';
											|pl = 'Oczyść agregaty';
											|tr = 'Toplamları Temizle'"));
	Buttons.Add(DialogReturnCode.Cancel);
	
	Handler = New CallbackDescription("ClearAggregatesByRegistersCompletion", ThisObject);
	ShowQueryBox(Handler, QueryText, Buttons, , DialogReturnCode.Cancel);
	
EndProcedure

&AtClient
Procedure FillAggregatesByRegisters(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Điền thống kê ...';
													|ru = 'Заполнение агрегатов ...';
													|en = 'Populating aggregates…'; fa = 'Populating aggregates…';
													|it = 'Compilazione aggregati ...';
													|pl = 'Wypełnienie agregatów ...';
													|tr = 'Agregaların doldurulması.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã kết thúc điền thống kê';
															|ru = 'Заполнение агрегатов завершено';
															|en = 'Aggregates are populated'; fa = 'Aggregates are populated';
															|it = 'La compilazione di aggregati è stata completata';
															|pl = 'Wypełnienie agregatów zostało zakończone';
															|tr = 'Agregaların doldurulması tamamlandı'"));
	TotalsParameters.Insert("Action",               "FillAggregates");
	TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
	TotalsParameters.Insert("Field",                   "Description");
	TotalsParameters.Insert("Value1",              Undefined);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể điền phần thống kê.';
													|ru = 'Не удалось заполнить агрегаты.';
													|en = 'Cannot fill in aggregates.'; fa = 'Cannot fill in aggregates.';
													|it = 'Impossibile compilare aggregati.';
													|pl = 'Nie udało się wypełnić agregatów.';
													|tr = 'Agregalar doldurulamadı.'"));
	
	ChangeAggregatesClient(TotalsParameters);
	
EndProcedure

&AtClient
Procedure OptimalAggregates(Command)
	ChoiceContext = "OptimalAggregates";
	
	FormParameters = New Structure;
	FormParameters.Insert("RelativeSize", OptimalRelativeSize);
	FormParameters.Insert("MinimumEffect",   0);
	FormParameters.Insert("RebuildMode",   False);
	
	OpenForm("DataProcessor.TotalsAndAggregatesManagement.Form.RebuildParametersForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure SetTotalsPeriod(Command)
	
	ClearMessages();
	
	ActionsArray = TotalsList.FindRows(New Structure("BalanceAndTurnovers", True));
	
	If ActionsArray.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không có biểu ghi mà đối với chúng có thể thực hiện giao dịch này.';
								|ru = 'Отсутствуют регистры, для которых можно выполнить данную операцию.';
								|en = 'No registers to perform this action.'; fa = 'No registers to perform this action.';
								|it = 'Non ci sono i registri per i quali è possibile eseguire questa operazione.';
								|pl = 'Brak rejestrów, dla których można wykonać tą operację.';
								|tr = 'Bu işlemin gerçekleştirilebileceği kayıt yok.'"));
		Return;
	EndIf;
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Thiết lập kỳ của phần tổng kết đã tính toán ...';
													|ru = 'Установка периода рассчитанных итогов ...';
													|en = 'Setting calculated totals period…'; fa = 'Setting calculated totals period…';
													|it = 'Impostazione del periodo dei totali calcolati ...';
													|pl = 'Ustawienie okresu obliczonych wyników...';
													|tr = 'Hesaplanan toplamların dönemini ayarlama...'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất thiết lập kỳ của phần tổng kết đã tính toán';
															|ru = 'Установка периода рассчитанных итогов завершена';
															|en = 'Setting of calculated totals period is complete'; fa = 'Setting of calculated totals period is complete';
															|it = 'L''impostazione del periodo dei totali calcolati è stata completata';
															|pl = 'Ustawienie okresu obliczonych wyników jest zakończono';
															|tr = 'Hesaplanan toplamların dönemini ayarlama tamamlandı'"));
	TotalsParameters.Insert("Action",               "SetTotalPeriod");
	TotalsParameters.Insert("RowsArray",            ActionsArray);
	TotalsParameters.Insert("Field",                   "TotalsPeriod");
	TotalsParameters.Insert("Value1",              PeriodEnding(AddMonth(CalculateTotalsFor, -1)) );
	TotalsParameters.Insert("Value2",              PeriodEnding(CalculateTotalsFor) );
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể thiết lập kỳ phần tổng kết đã tính.';
													|ru = 'Не удалось установить период рассчитанных итогов.';
													|en = 'Cannot set the calculated totals period.'; fa = 'Cannot set the calculated totals period.';
													|it = 'Impossibile impostare il periodo dei totali calcolati.';
													|pl = 'Nie udało się ustawić okres rozliczonych wyników.';
													|tr = 'Hesaplanan toplamların dönemi kurulamadı.'"));
	TotalsParameters.Insert("GroupProcessing",     True);
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure EnableTotalsUsageQuickAccess(Command)
	
	ClearMessages();
	
	ActionsArray = TotalsList.FindRows(New Structure("UseTotals", False));
	
	If ActionsArray.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không có biểu ghi mà đối với chúng có thể thực hiện giao dịch này.';
								|ru = 'Отсутствуют регистры, для которых можно выполнить данную операцию.';
								|en = 'No registers to perform this action.'; fa = 'No registers to perform this action.';
								|it = 'Non ci sono i registri per i quali è possibile eseguire questa operazione.';
								|pl = 'Brak rejestrów, dla których można wykonać tą operację.';
								|tr = 'Bu işlemin gerçekleştirilebileceği kayıt yok.'"));
		Return;
	EndIf;
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Bật sử dụng phần tổng kết ...';
													|ru = 'Включение использования итогов ...';
													|en = 'Enabling totals…'; fa = 'Enabling totals…';
													|it = 'Abilitazione dell''utilizzo di totali ...';
													|pl = 'Włączenie używania wyników...';
													|tr = 'Toplamların kullanımını etkinleştirme...'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất bật sử dụng phần tổng kết';
															|ru = 'Включение использования итогов завершено';
															|en = 'Totals are enabled'; fa = 'Totals are enabled';
															|it = 'L''abilitazione dell''utilizzo di totali è stata completata';
															|pl = 'Włączenie używania wyników zostało zakończone';
															|tr = 'Toplamların kullanımını etkinleştirme tamamlandı'"));
	TotalsParameters.Insert("Action",               "SetTotalsUsing");
	TotalsParameters.Insert("RowsArray",            ActionsArray);
	TotalsParameters.Insert("Field",                   "");
	TotalsParameters.Insert("Value1",              True);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể bật sử dụng phần tổng kết.';
													|ru = 'Не удалось включить использование итогов.';
													|en = 'Cannot enable totals usage.'; fa = 'Cannot enable totals usage.';
													|it = 'Impossibile abilitare l''utilizzo di totali.';
													|pl = 'Nie udało się włączyć używanie wyników.';
													|tr = 'Toplamların kullanımı etkinleştirilemedi.'"));
	TotalsParameters.Insert("GroupProcessing",     True);
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure FillAggregatesAndPerformRebuild(Command)
	
	ClearMessages();
	
	ActionsArray = AggregatesByRegisters.FindRows(New Structure("AggregateMode,AgregateUsage", True, True));
	
	If ActionsArray.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không có biểu ghi mà đối với chúng có thể thực hiện các thao tác đã chọn.';
								|ru = 'Отсутствуют регистры, для которых можно выполнить выбранное действие.';
								|en = 'No registers to perform the selected action for.'; fa = 'No registers to perform the selected action for.';
								|it = 'Non ci sono i registri per i quali è possibile eseguire l''azione selezionata.';
								|pl = 'Brak rejestrów, dla których można wykonać wybrane działanie.';
								|tr = 'Seçili eylemi gerçekleştirebileceğiniz kayıt yok.'"));
		Return;
	EndIf;
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Tái tạo phần thống kê ...';
													|ru = 'Перестроение агрегатов ...';
													|en = 'Rebuilding aggregates…'; fa = 'Rebuilding aggregates…';
													|it = 'Ristrutturazione degli aggregati ...';
													|pl = 'Przebudowa agregatów ...';
													|tr = 'Agregaları yeniden oluşturma...'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất tái tạo phần thống kê';
															|ru = 'Перестроение агрегатов завершено';
															|en = 'Aggregates are rebuilt'; fa = 'Aggregates are rebuilt';
															|it = 'La ristrutturazione degli aggregati è stata completata';
															|pl = 'Przebudowa agregatów jest zakończona';
															|tr = 'Agregaları yeniden oluşturma tamamlandı'"));
	TotalsParameters.Insert("Action",               "RebuildAggregates");
	TotalsParameters.Insert("RowsArray",            ActionsArray);
	TotalsParameters.Insert("Field",                   "");
	TotalsParameters.Insert("Value1",              0);
	TotalsParameters.Insert("Value2",              0);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể xây dựng lại phần thống kê.';
													|ru = 'Не удалось перестроить агрегаты.';
													|en = 'Cannot rebuild aggregates.'; fa = 'Cannot rebuild aggregates.';
													|it = 'Impossibile ristrutturare aggregati.';
													|pl = 'Nie udało się przebudować agragatów.';
													|tr = 'Agregalar yeniden oluşturulamadı.'"));
	TotalsParameters.Insert("GroupProcessing",     True);
	
	ChangeAggregatesClient(TotalsParameters, True);
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Điền thống kê ...';
													|ru = 'Заполнение агрегатов ...';
													|en = 'Populating aggregates…'; fa = 'Populating aggregates…';
													|it = 'Compilazione aggregati ...';
													|pl = 'Wypełnienie agregatów ...';
													|tr = 'Agregaların doldurulması.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã kết thúc điền thống kê';
															|ru = 'Заполнение агрегатов завершено';
															|en = 'Aggregates are populated'; fa = 'Aggregates are populated';
															|it = 'La compilazione di aggregati è stata completata';
															|pl = 'Wypełnienie agregatów zostało zakończone';
															|tr = 'Agregaların doldurulması tamamlandı'"));
	TotalsParameters.Insert("Action",               "FillAggregates");
	TotalsParameters.Insert("RowsArray",            ActionsArray);
	TotalsParameters.Insert("Field",                   "");
	TotalsParameters.Insert("Value1",              Undefined);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể điền phần thống kê.';
													|ru = 'Не удалось заполнить агрегаты.';
													|en = 'Cannot fill in aggregates.'; fa = 'Cannot fill in aggregates.';
													|it = 'Impossibile compilare aggregati.';
													|pl = 'Nie udało się wypełnić agregatów.';
													|tr = 'Agregalar doldurulamadı.'"));
	
	ChangeAggregatesClient(TotalsParameters, False);
	
EndProcedure

&AtClient
Procedure GetOptimalAggregates(Command)
	GetOptimalAggregatesClient();
EndProcedure

&AtClient
Procedure RecalcTotals(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Tính lại phần tổng kết ...';
													|ru = 'Пересчет итогов ...';
													|en = 'Recalculating totals…'; fa = 'Recalculating totals…';
													|it = 'Ricalcolo totali ...';
													|pl = 'Przeliczenie wyników ...';
													|tr = 'Toplamların yeniden hesaplanması.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất tính lại phần tổng kết.';
															|ru = 'Пересчет итогов завершен.';
															|en = 'Totals are recalculated.'; fa = 'Totals are recalculated.';
															|it = 'Il ricalcolo dei totali è stato completato.';
															|pl = 'Zakończono przeliczenie wyników.';
															|tr = 'Toplamların yeniden hesaplanması tamamlandı.'"));
	TotalsParameters.Insert("Action",               "RecalcTotals");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "Description");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể đọc lại phần tổng kết.';
													|ru = 'Не удалось пересчитать итоги.';
													|en = 'Cannot recalculate totals.'; fa = 'Cannot recalculate totals.';
													|it = 'Impossibile ricalcolare i totali.';
													|pl = 'NIe udało się przeliczyć wyniki.';
													|tr = 'Toplamlar yeniden hesaplanamadı.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure RecalcPresentTotals(Command)
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Tính lại phần tổng kết hiện tại ...';
													|ru = 'Пересчет текущих итогов ...';
													|en = 'Recalculating current totals…'; fa = 'Recalculating current totals…';
													|it = 'Ricalcolo dei totali correnti ...';
													|pl = 'Przeliczenie bieżących wyników...';
													|tr = 'Mevcut toplamların yeniden hesaplanması.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất tính lại phần tổng kết hiện tại.';
															|ru = 'Пересчет текущих итогов завершен.';
															|en = 'Current totals recalculation completed.'; fa = 'Current totals recalculation completed.';
															|it = 'Il ricalcolo dei totali correnti è stato completato.';
															|pl = 'Zakończono przeliczenie bieżących wyników.';
															|tr = 'Mevcut toplamların yeniden hesaplanması tamamlandı.'"));
	TotalsParameters.Insert("Action",               "RecalcPresentTotals");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "Description");
	TotalsParameters.Insert("Value1",              False);
	TotalsParameters.Insert("Value2",              Undefined);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể đọc lại phần tổng kết hiện tại.';
													|ru = 'Не удалось пересчитать текущие итоги.';
													|en = 'Cannot recalculate current totals.'; fa = 'Cannot recalculate current totals.';
													|it = 'Impossibile ricalcolare i totali correnti.';
													|pl = 'NIe udało się przeliczyć bieżące wyniki.';
													|tr = 'Mevcut toplamlar yeniden hesaplanamadı.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

&AtClient
Procedure RecalcTotalsForPeriod(Command)
	Handler = New CallbackDescription("RecalcTotalsForPeriodCompletion", ThisObject);
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = RegistersRecalculationPeriod;
	Dialog.Show(Handler);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsAggregatesTotals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.AggregatesTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tổng số';
													|ru = 'Итоги';
													|en = 'Totals'; fa = 'جمع‌ها';
													|it = 'Totali';
													|pl = 'Wyniki';
													|tr = 'Toplamlar'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsAggregatesTotals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.AggregatesTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thống kê';
													|ru = 'Агрегаты';
													|en = 'Aggregates'; fa = 'تجمیع‌ها';
													|it = 'Aggregati';
													|pl = 'Agregaty';
													|tr = 'Toplamlar'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsAggregatesTotals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.AggregatesTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đơn giản biểu ghi tổng kết';
													|ru = 'Просто итоговый регистр';
													|en = 'Just total register'; fa = 'Just total register';
													|it = 'Solo il registro finale';
													|pl = 'Po prostu rejestr końcowy';
													|tr = 'Sadece toplam kayıt'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsUseCurrentTotals.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsTotalsPeriod.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsTotalsSplitting.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.BalanceAndTurnovers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", WebColors.Gainsboro);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsAggregatesTotals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.AggregatesTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;

	Item.Appearance.SetParameterValue("BackColor", WebColors.Gainsboro);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TotalsUseTotals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalsList.AggregatesTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("BackColor", WebColors.Gainsboro);

EndProcedure

#Region AsyncDialogHandlers

&AtClient
Procedure ClearAggregatesByRegistersCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		TotalsParameters = New Structure;
		TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Xóa bỏ phần tổng kết ...';
														|ru = 'Очистка агрегатов ...';
														|en = 'Clearing aggregates…'; fa = 'Clearing aggregates…';
														|it = 'Cancellazione degli aggregati ...';
														|pl = 'Oczyszczenie agregatów...';
														|tr = 'Agregaların temizlenmesi.'"));
		TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất xóa phần tổng kết';
																|ru = 'Очистка агрегатов завершена';
																|en = 'Aggregates are cleared'; fa = 'Aggregates are cleared';
																|it = 'La cancellazione degli aggregati è stata completata';
																|pl = 'Zakończono oczyszczenie agregatów';
																|tr = 'Agregaların temizlenmesi tamamlandı'"));
		TotalsParameters.Insert("Action",               "ClearAggregates");
		TotalsParameters.Insert("RowsArray",            Items.AggregatesByRegisters.SelectedRows);
		TotalsParameters.Insert("Field",                   "Description");
		TotalsParameters.Insert("Value1",              Undefined);
		TotalsParameters.Insert("Value2",              Undefined);
		TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể xóa phần thống kê.';
														|ru = 'Не удалось очистить агрегаты.';
														|en = 'Cannot clear aggregates.'; fa = 'Cannot clear aggregates.';
														|it = 'Impossibile cancellare aggregati.';
														|pl = 'Nie udało się oczyścić agregatów.';
														|tr = 'Agregalar temizlenemedi.'"));
		
		ChangeAggregatesClient(TotalsParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecalcTotalsForPeriodCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	RegistersRecalculationPeriod = ValueSelected;
	
	TotalsParameters = New Structure;
	TotalsParameters.Insert("ProcessTitle",  NStr("vi = 'Tính lại phần tổng kết trong kỳ...';
													|ru = 'Пересчет итогов за период...';
													|en = 'Recalculating totals for the period…'; fa = 'Recalculating totals for the period…';
													|it = 'Ricalcolo dei totali per il periodo ...';
													|pl = 'Przeliczenie wyników za okres...';
													|tr = 'Dönem için toplamların yeniden hesaplanması.'"));
	TotalsParameters.Insert("AfterProcess1",          NStr("vi = 'Đã hoàn tất tính lại phần tổng kết trong kỳ.';
															|ru = 'Пересчет итогов за период завершен.';
															|en = 'Totals recalculation for the period completed.'; fa = 'Totals recalculation for the period completed.';
															|it = 'Ricalcolo dei totali per il periodo è completato.';
															|pl = 'Zakończono przeliczenie wyników za okres.';
															|tr = 'Dönem için toplamların yeniden hesaplanması tamamlandı.'"));
	TotalsParameters.Insert("Action",               "RecalcTotalsForPeriod");
	TotalsParameters.Insert("RowsArray",            Items.TotalsList.SelectedRows);
	TotalsParameters.Insert("Field",                   "Description");
	TotalsParameters.Insert("Value1",              RegistersRecalculationPeriod.StartDate);
	TotalsParameters.Insert("Value2",              RegistersRecalculationPeriod.EndDate);
	TotalsParameters.Insert("ErrorMessageText", NStr("vi = 'Không thể đọc lại phần tổng kết trong kỳ.';
													|ru = 'Не удалось пересчитать итоги за период.';
													|en = 'Cannot recalculate totals for the period.'; fa = 'Cannot recalculate totals for the period.';
													|it = 'Impossibile ricalcolare i totali per il periodo.';
													|pl = 'Nie udało się przeliczyć wyniki za okres.';
													|tr = 'Dönem içi toplamlar yeniden hesaplanamadı.'"));
	
	TotalsControl(TotalsParameters);
	
EndProcedure

#EndRegion

#Region Client

&AtClient
Procedure SetAggregatesListFilter()
	
	CurrentData = Items.AggregatesByRegisters.CurrentData;
	
	If CurrentData <> Undefined Then
		Filter = New FixedStructure("NameOfMetadataObject", CurrentData.NameOfMetadataObject);
		NewTitle = Prefix() +  " " + CurrentData.Description;
	Else
		Filter = New FixedStructure("NameOfMetadataObject", "");
		NewTitle = Prefix();
	EndIf;
	
	Items.AggregatesList.RowFilter = Filter;
	
	If Items.AggregatesList.Title <> NewTitle Then
		Items.AggregatesList.Title = NewTitle;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeAggregatesClient(Val TotalsParameters, Val ClearMessages = True)
	
	Result = True;
	If ClearMessages Then
		ClearMessages();
	EndIf;
	Selected_ = TotalsParameters.RowsArray;
	
	If Selected_.Count() = 0 Then
		Return;
	EndIf;
	
	ProcessStep = 100/Selected_.Count();
	
	If TotalsParameters.Property("GroupProcessing") Then
		NeedAbortAfterError = ?(TotalsParameters.GroupProcessing, False, InterruptOnError);
	Else
		NeedAbortAfterError = InterruptOnError;
	EndIf;
	
	For Counter = 1 To Selected_.Count() Do
		If TypeOf(Selected_[Counter - 1]) = Type("Number") Then
			RowSelected = AggregatesByRegisters.FindByID(Selected_[Counter-1]);
		Else
			RowSelected = Selected_[Counter-1];
		EndIf;
		
		AfterErrorMessage = "";
		If Not IsBlankString(TotalsParameters.Field) Then
			AfterErrorMessage = "AggregatesByRegisters[" + Format(Selected_[Counter-1], "NG=0") + "]." + TotalsParameters.Field;
		EndIf;
		
		If Not RowSelected.AggregateMode
			And Upper(TotalsParameters.Action) <> Upper("SetAggregatesMode") Then
			CommonClient.MessageToUser(
				NStr("vi = 'Thao tác là không thể trong chế độ tổng kết';
					|ru = 'Операция невозможна в режиме итогов';
					|en = 'The operation is not allowed in the totals mode'; fa = 'The operation is not allowed in the totals mode';
					|it = 'Non è possibile eseguire l''operazione in modalità totali';
					|pl = 'Operacja jest niemożliwa w trybie wyników';
					|tr = 'Toplam modunda işlem mümkün değil'"),
				,
				AfterErrorMessage);
			Continue;
		EndIf;
		
		Status(TotalsParameters.ProcessTitle, Counter * ProcessStep, RowSelected.Description);
		
		ServerParameters = New Structure;
		ServerParameters.Insert("RegisterName",        RowSelected.NameOfMetadataObject);
		ServerParameters.Insert("Action",           TotalsParameters.Action);
		ServerParameters.Insert("ActionValue1",  TotalsParameters.Value1);
		ServerParameters.Insert("ActionValue2",  TotalsParameters.Value2);
		ServerParameters.Insert("ErrorMessage",  TotalsParameters.ErrorMessageText);
		ServerParameters.Insert("FormField",          AfterErrorMessage);
		ServerParameters.Insert("FormIdentifier", UUID);
		Result = ChangeAggregatesServer(ServerParameters);
		
		UserInterruptProcessing();
		
		If Not Result.Success And NeedAbortAfterError Then
			Break;
		EndIf;
		
	EndDo;
	
	If Upper(TotalsParameters.Action) = Upper("SetAggregatesMode")
		Or Upper(TotalsParameters.Action) = Upper("SetAggregatesUsing") Then
		UpdateTotalsListAtServer();
	EndIf;
	
	UpdateAggregatesByRegistersAtServer();
	
	Status(TotalsParameters.AfterProcess1);
	SetAggregatesListFilter();
	
EndProcedure

&AtClient
Procedure TotalsControl(Val TotalsParameters)
	
	Result = True;
	ClearMessages();
	
	Selected_ = TotalsParameters.RowsArray;
	If Selected_.Count() = 0 Then
		Return;
	EndIf;
	
	ProcessStep = 100/Selected_.Count();
	Action = Lower(TotalsParameters.Action);
	
	If TotalsParameters.Property("GroupProcessing") Then
		NeedAbortAfterError = ?(TotalsParameters.GroupProcessing, False, InterruptOnError);
	Else
		NeedAbortAfterError = InterruptOnError;
	EndIf;
	
	ProcessedRowsCount = 0;
	HasRegistersToProcess    = False;
	
	For Counter = 1 To Selected_.Count() Do
		If TypeOf(Selected_[Counter-1]) = Type("Number") Then
			RowSelected = TotalsList.FindByID(Selected_[Counter-1]);
		Else
			RowSelected = Selected_[Counter-1];
		EndIf;
		
		Status(TotalsParameters.ProcessTitle, Counter * ProcessStep, RowSelected.Description);
		
		If Upper(Action) = Upper("SetTotalsUsing") Then
			If RowSelected.AggregatesTotals = 1 Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("UseCurrentTotals") Then
			If RowSelected.AggregatesTotals = 1 Or Not RowSelected.BalanceAndTurnovers Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("SetTotalPeriod") Then
			If RowSelected.AggregatesTotals = 1 Or Not RowSelected.BalanceAndTurnovers Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("SetTotalsSeparation") Then
			If Not RowSelected.EnableTotalsSplitting Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("RecalcTotals") Then
			If RowSelected.AggregatesTotals = 1 Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("RecalcTotalsForPeriod") Then
			If RowSelected.AggregatesTotals = 1 Or Not RowSelected.BalanceAndTurnovers Then
				Continue;
			EndIf;
			
		ElsIf Upper(Action) = Upper("RecalcPresentTotals") Then
			If Not RowSelected.BalanceAndTurnovers Then
				Continue;
			EndIf;
		EndIf;
		
		AfterErrorMessage = "";
		If Not IsBlankString(TotalsParameters.Field) Then
			AfterErrorMessage = "TotalsList[" + Format(Selected_[Counter-1], "NG=0") + "]." + TotalsParameters.Field;
		EndIf;
		
		HasRegistersToProcess = True;
		
		Result = SetRegisterParametersAtServer(
			RowSelected.Type,
			RowSelected.NameOfMetadataObject,
			TotalsParameters.Action,
			TotalsParameters.Value1,
			TotalsParameters.Value2,
			AfterErrorMessage,
			TotalsParameters.ErrorMessageText);
		
		UserInterruptProcessing();
		
		If Not Result And NeedAbortAfterError Then
			Break;
		EndIf;
		
		If Result Then
			ProcessedRowsCount = ProcessedRowsCount + 1;
		EndIf;
	EndDo;
	
	If Not HasRegistersToProcess Then
		ShowMessageBox(, NStr("vi = 'Không có biểu ghi mà đối với chúng có thể thực hiện giao dịch này.';
								|ru = 'Отсутствуют регистры, для которых можно выполнить данную операцию.';
								|en = 'No registers to perform this action.'; fa = 'No registers to perform this action.';
								|it = 'Non ci sono i registri per i quali è possibile eseguire questa operazione.';
								|pl = 'Brak rejestrów, dla których można wykonać tą operację.';
								|tr = 'Bu işlemin gerçekleştirilebileceği kayıt yok.'"));
		Return;
	EndIf;
	
	UpdateTotalsListAtServer();
	
	StateText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã tính lại (%1 trong số %2)';
			|ru = 'Пересчитаны (%1 из %2)';
			|en = 'Recalculated (%1 of %2)'; fa = 'Recalculated (%1 of %2)';
			|it = 'Ricalcolati (%1 da %2)';
			|pl = 'Przeliczono (%1 z %2)';
			|tr = 'Yeniden hesaplandı (%2 den %1)'"),
		ProcessedRowsCount,
		Selected_.Count());
	
	Status(TotalsParameters.AfterProcess1 + Chars.LF + StateText);
	
EndProcedure

&AtClient
Procedure GetOptimalAggregatesClient()
	
	If FullFunctionality Then
		If Items.AggregatesByRegisters.SelectedRows.Count() = 0 Then
			Return;
		EndIf;
	Else
		If AggregatesByRegisters.Count() = 0 Then
			ShowMessageBox(, NStr("vi = 'Không có biểu ghi mà đối với chúng có thể thực hiện giao dịch này.';
									|ru = 'Отсутствуют регистры, для которых можно выполнить данную операцию.';
									|en = 'No registers to perform this action.'; fa = 'No registers to perform this action.';
									|it = 'Non ci sono i registri per i quali è possibile eseguire questa operazione.';
									|pl = 'Brak rejestrów, dla których można wykonać tą operację.';
									|tr = 'Bu işlemin gerçekleştirilebileceği kayıt yok.'"));
			Return;
		EndIf;
	EndIf;
	
	Result = GetOptimalAggregatesServer();
	Handler = New CallbackDescription("GetOptimalAggregatesClientCompletion", ThisObject, Result);
	If Not Result.CanGet Then
		Return;
	EndIf;
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("vi = 'Lưu tổng hợp tối ưu vào tệp';
										|ru = 'Сохранить оптимальные агрегаты в файл';
										|en = 'Save optimal aggregates to file'; fa = 'Save optimal aggregates to file';
										|it = 'Salvare gli aggregati ottimali nel file';
										|pl = 'Zapisz optymalne agregaty do pliku';
										|tr = 'En uygun toplamaları dosyaya kaydet'");
	Extension = Lower(Mid(Result.FileName, StrFind(Result.FileName, ".") + 1));
	If Extension = "zip" Then
		Filter = NStr("vi = 'Tệp cài đặt đơn vị (*.zip)|*.zip';
						|ru = 'Файлы настроек агрегатов (*.zip)|*.zip';
						|en = 'Aggregate setting files (*.zip)|*.zip'; fa = 'Aggregate setting files (*.zip)|*.zip';
						|it = 'File delle impostazioni degli aggregati (*.zip)|*.zip';
						|pl = 'Pliki ustawień agregatów (*.zip)|*.zip';
						|tr = 'Toplama ayarları dosyası (*.zip)|*.zip'");
	ElsIf Extension = "xml" Then
		Filter = NStr("vi = 'Tệp cài đặt đơn vị (*.xml)|*.xml';
						|ru = 'Файлы настроек агрегатов (*.xml)|*.xml';
						|en = 'Aggregate setting files (*.xml)|*.xml'; fa = 'Aggregate setting files (*.xml)|*.xml';
						|it = 'File delle impostazioni degli aggregati (*.xml)|*.xml';
						|pl = 'Pliki ustawień agregatów (*.xml)|*.xml';
						|tr = 'Toplama ayarları dosyası (*.xml)|*.xml'");
	Else
		Filter = "";
	EndIf;
	SavingParameters.Dialog.Filter = Filter;
	SavingParameters.Dialog.FullFileName = Result.FileName;
	FileSystemClient.SaveFile(Handler, Result.FileAddress, Result.FileName, SavingParameters);
	
EndProcedure

&AtClient
Procedure GetOptimalAggregatesClientCompletion(ObtainedFiles, ExecutionResult) Export
	
	If ObtainedFiles = Undefined Then
		Return;
	EndIf;
	
	If ExecutionResult.HasErrors Then
		Raise ExecutionResult.MessageText;
	EndIf;
	ShowUserNotification(NStr("vi = 'Đã nhận thành công thống kê.';
								|ru = 'Агрегаты успешно получены.';
								|en = 'Aggregates are received.'; fa = 'Aggregates are received.';
								|it = 'Aggregati ricevuti con successo.';
								|pl = 'Agregaty zostały pomyślnie otrzymane.';
								|tr = 'Toplamalar başarıyla alındı.'"),,
		 ExecutionResult.MessageText, PictureLib.Success32);

EndProcedure

#EndRegion

#Region ClientServer

&AtClientAtServerNoContext
Function PeriodEnding(Val Date)
	
	Return EndOfDay(EndOfMonth(Date));
	
EndFunction

&AtClientAtServerNoContext
Function Prefix()
	
	Return NStr("vi = 'Thống kê biểu ghi';
				|ru = 'Агрегаты регистра';
				|en = 'Register aggregates'; fa = 'تجمیع‌های رجیستر';
				|it = 'Aggregati del registro';
				|pl = 'Agregaty rejestru';
				|tr = 'Toplamları Kaydet'");
	
EndFunction

#EndRegion

#Region ServerCallServer

&AtServer
Function GetOptimalAggregatesServer()
	
	Result = New Structure;
	Result.Insert("CanGet", False);
	Result.Insert("FileAddress", "");
	Result.Insert("FileName", "");
	Result.Insert("HasErrors", False);
	Result.Insert("MessageText", "");
	
	If FullFunctionality Then
		Collection = SelectedRows("AggregatesByRegisters");
		MaximumRelativeSize = OptimalRelativeSize;
	Else
		Collection = AggregatesByRegisters;
		MaximumRelativeSize = 0;
	EndIf;
	Total = Collection.Count();
	Success = 0;
	DetailedErrorText1 = "";
	
	TempFilesDir = CommonClientServer.AddLastPathSeparator(
		GetTempFileName(".TAM")); // Totals & Aggregates Management.
	CreateDirectory(TempFilesDir);
	
	FilesToArchive = New ValueList;
	
	// Get aggregates.
	For LineNumber = 1 To Total Do
		
		AccumulationRegisterName = Collection[LineNumber - 1].NameOfMetadataObject;
		
		RegisterManager = AccumulationRegisters[AccumulationRegisterName];
		Try
			OptimalAggregates1 = RegisterManager.DetermineOptimalAggregates(MaximumRelativeSize);
		Except
			Result.HasErrors = True;
			DetailedErrorText1 = DetailedErrorText1
				+ ?(IsBlankString(DetailedErrorText1), "", Chars.LF + Chars.LF)
				+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1: %2';
																				|ru = '%1: %2';
																				|en = '%1: %2'; fa = '%1: %2';
																				|it = '%1: %2';
																				|pl = '%1: %2';
																				|tr = '%1: %2'"), AccumulationRegisterName, 
					ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Continue;
		EndTry;
		
		FullFileName = TempFilesDir + AccumulationRegisterName + ".xml";
		
		XMLWriter = New XMLWriter();
		XMLWriter.OpenFile(FullFileName);
		XMLWriter.WriteXMLDeclaration();
		XDTOSerializer.WriteXML(XMLWriter, OptimalAggregates1);
		XMLWriter.Close();
		
		FilesToArchive.Add(FullFileName, AccumulationRegisterName);
		Success = Success + 1;
		
	EndDo;
	
	// Preparing result to be passed to client.
	If Success > 0 Then
		
		If Success = 1 Then
			ListItem = FilesToArchive[0];
			FullFileName = ListItem.Value;
			ShortFileName = ListItem.Presentation + ".xml";
		Else
			ShortFileName = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Phần tổng kết tối ưu của biểu ghi tích lũy %1.zip';
					|ru = 'Оптимальные агрегаты регистров накопления %1.zip';
					|en = 'Optimal aggregates of accumulation register %1.zip'; fa = 'Optimal aggregates of accumulation register %1.zip';
					|it = 'Aggregati ottimali dei registri di accumulo %1.zip';
					|pl = 'Optymalne agregaty rejestrów akumulacji %1.zip';
					|tr = 'En uygun birikim kayıtları toplamı%1.zip'"),
				Format(CurrentSessionDate(), "DF=yyyy-MM-dd"));
			FullFileName = TempFilesDir + ShortFileName;
			SaveMode = ZIPStorePathMode.StoreRelativePath;
			ProcessingMode = ZIPSubDirProcessingMode.ProcessRecursively;
			ZipFileWriter = New ZipFileWriter(FullFileName);
			For Each ListItem In FilesToArchive Do
				ZipFileWriter.Add(ListItem.Value, SaveMode, ProcessingMode);
			EndDo;
			ZipFileWriter.Write();
		EndIf;
		BinaryData = New BinaryData(FullFileName);
		Result.CanGet = True;
		Result.FileName      = ShortFileName;
		Result.FileAddress    = PutToTempStorage(BinaryData, UUID);
		
	EndIf;
	
	// Clean up garbage.
	DeleteFiles(TempFilesDir);
	
	// Prepare message texts.
	If Total = 1 Then
		
		// If there is only one register.
		ListItem = Collection[0];
		RegisterName = ListItem.Description;
		If Result.HasErrors Then
			Result.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể nhận được tổng hợp đăng ký tích lũy tối ưu ""%1"" vì lý do:
					|%2';
					|ru = 'Не удалось получить оптимальные агрегаты регистра накопления ""%1"" по причине:
					|%2';
					|en = 'Cannot receive optimal aggregates of the ""%1"" accumulation register due to:
					|%2'; fa = 'Cannot receive optimal aggregates of the ""%1"" accumulation register due to:
					|%2';
					|it = 'Impossibile ottenere aggregati ottimali del registro di accumulo ""%1"" a causa di: 
					|%2';
					|pl = 'Nie udało się otrzyać optymelne agregaty rejestru akumulacji ""%1"" z powodu:
					|%2';
					|tr = '
					|nedeniyle birikim ""%1"" kaydının en uygun agregalarını elde etmek mümkün olmadı:%2'"), RegisterName, DetailedErrorText1);
		Else
			Result.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 (biểu ghi tích lũy)';
					|ru = '%1 (регистр накопления)';
					|en = '%1 (accumulation register)'; fa = '%1 (accumulation register)';
					|it = '%1 (registro di accumulo)';
					|pl = '%1 (rejestr akumulacji)';
					|tr = '%1 (birikim kaydı)'"),	RegisterName);
		EndIf;
		
	ElsIf Success = 0 Then
		
		// That did not work.
		Result.HasErrors = True;
		Result.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không lấy được tổng số biểu ghi tích lũy tối ưu vì lý do:
			|%1';
			|ru = 'Не удалось получить оптимальные агрегаты регистров накопления по причине:
			|%1';
			|en = 'Cannot receive ideal aggregates of accumulation registers due to:
			|%1'; fa = 'Cannot receive ideal aggregates of accumulation registers due to:
			|%1';
			|it = 'Impossibile ottenere aggregati ottimali dei registri di accumulo a causa di: 
			| %1';
			|pl = 'Nie udało sie otrzymać optymalnych agregatów rejestrów akumulacji z powodu:
			|%1';
			|tr = '
			|%1nedeniyle birikim kaydının en uygun agregalarını elde etmek mümkün olmadı:'"), DetailedErrorText1);
		
	ElsIf Result.HasErrors Then
		
		// Partially succeeded.
		Result.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tổng hợp đã được nhận thành công cho %1 từ %2 biểu ghi.
				|Chưa nhận được cho %3 vì lý do:
				|%4';
				|ru = 'Агрегаты успешно получены для %1 из %2 регистров.
				|Не получены для %3 по причине:
				|%4';
				|en = 'Aggregates are successfully received for %1 of %2 registers.
				|Not received for %3 due to:
				|%4'; fa = 'Aggregates are successfully received for %1 of %2 registers.
				|Not received for %3 due to:
				|%4';
				|it = 'Aggregati ricevuti correttamente per %1 da %2 registri.
				|Non sono ricevuti per %3 a causa di:
				|%4';
				|pl = 'Agregaty są pomyślnie otrzymane dla %1 z %2 rejestrów.
				|Nie otrzymano dla %3 z powodu:
				|%4';
				|tr = '%1 için %2den agregalar başarıyla alındı. 
				|%4 nedeniyle %3 için alınamadı
				|:'"),
				Success,
				Total,
				Total - Success,
				DetailedErrorText1);
		
	Else
		
		// Successfully completed.
		Result.MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Biểu ghi tích lũy (%1)';
				|ru = 'Регистры накопления (%1)';
				|en = 'Accumulation registers (%1)'; fa = 'Accumulation registers (%1)';
				|it = 'Registri di accumulo (%1)';
				|pl = 'Rejestry akumulacji (%1)';
				|tr = 'Birikim kayıtları (%1)'"), Success);
			
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Procedure UpdateTotalsListAtServer()
	
	Managers = New Array;
	Managers.Add(AccumulationRegisters);
	Managers.Add(AccountingRegisters);
	
	For Each TableRow In TotalsList Do
		
		Register = Managers[TableRow.Type][TableRow.NameOfMetadataObject];
		
		TableRow.UseTotals = Register.GetTotalsUsing();
		TableRow.TotalsSeparation  = Register.GetTotalsSplittingMode();
		
		If TableRow.BalanceAndTurnovers Then
			
			TableRow.UseCurrentTotals = Register.GetPresentTotalsUsing();
			TableRow.TotalsPeriod             = Register.GetMaxTotalsPeriod();
			TableRow.AggregatesTotals            = 2;
			
		Else
			
			TableRow.UseCurrentTotals = False;
			TableRow.TotalsPeriod             = Undefined;
			TableRow.AggregatesTotals            = Register.GetAggregatesMode();
			
			If TableRow.AggregatesTotals Then
				TableRow.UseTotals = False;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	TotalsGroupTitle = NStr("vi = 'Tổng số';
							|ru = 'Итоги';
							|en = 'Totals'; fa = 'جمع‌ها';
							|it = 'Totali';
							|pl = 'Wyniki';
							|tr = 'Toplamlar'");
	TotalsCount = TotalsList.Count();
	If TotalsCount > 0 Then
		TotalsGroupTitle = TotalsGroupTitle + " (" + Format(TotalsCount, "NG=") + ")";
	EndIf;
	
	Items.TotalsGroup.Title = TotalsGroupTitle;
	
EndProcedure

&AtServer
Procedure UpdateAggregatesByRegistersAtServer()
	
	RegisterAggregatesList.Clear();
	
	For Each TableRow In AggregatesByRegisters Do
		
		RegisterManager = AccumulationRegisters[TableRow.NameOfMetadataObject];
		
		TableRow.AggregateMode         = RegisterManager.GetAggregatesMode();
		TableRow.AgregateUsage = RegisterManager.GetAggregatesUsing();

		Aggregates = RegisterManager.GetAggregates();
		TableRow.BuildDate     = Aggregates.BuildDate;
		TableRow.Size             = Aggregates.Size;
		TableRow.SizeLimit = Aggregates.SizeLimit;
		TableRow.Effect             = Aggregates.Effect;
		
		For Each Aggregate In Aggregates.Aggregates Do // AggregateInformation
			
			DimensionsSynonyms = New Array;
			For Each DimensionName In Aggregate.Dimensions Do
				DimensionSynonym = Metadata.AccumulationRegisters[TableRow.NameOfMetadataObject].Dimensions[DimensionName].Synonym;
				DimensionsSynonyms.Add(DimensionSynonym);
			EndDo;
			
			RegisterAggregatesRow = RegisterAggregatesList.Add();
			RegisterAggregatesRow.NameOfMetadataObject = TableRow.NameOfMetadataObject;
			RegisterAggregatesRow.Periodicity  = String(Aggregate.Periodicity);
			RegisterAggregatesRow.Dimensions      = StrConcat(DimensionsSynonyms, ", ");
			RegisterAggregatesRow.Use  = Aggregate.Use;
			RegisterAggregatesRow.BeginOfPeriod  = Aggregate.BeginOfPeriod;
			RegisterAggregatesRow.EndOfPeriod   = Aggregate.EndOfPeriod;
			RegisterAggregatesRow.Size         = Aggregate.Size;
			
		EndDo;
	EndDo;
	
	RegisterAggregatesList.Sort("Use Desc");
	
	AggregatesGroupTitle = NStr("vi = 'Thống kê';
								|ru = 'Агрегаты';
								|en = 'Aggregates'; fa = 'تجمیع‌ها';
								|it = 'Aggregati';
								|pl = 'Agregaty';
								|tr = 'Toplamlar'");
	AggregatesCount = AggregatesByRegisters.Count();
	If AggregatesCount > 0 Then
		AggregatesGroupTitle = AggregatesGroupTitle + " (" + Format(AggregatesCount, "NG=") + ")";
	EndIf;
	
	Items.AggregatesGroup.Title = AggregatesGroupTitle;
	
EndProcedure

&AtServerNoContext
Function SetRegisterParametersAtServer(Val RegisterType,
                                             Val RegisterName,
                                             Val Action,
                                             Val Value1,
                                             Val Value2, // The default value is Undefined.
                                             Val ErrorField,
                                             Val ErrorMessage)
	
	Managers = New Array;
	Managers.Add(AccumulationRegisters);
	Managers.Add(AccountingRegisters);
	
	Manager = Managers[RegisterType][RegisterName];
	Action = Lower(Action);
	
	Try
		
		If Upper(Action) = Upper("SetTotalsUsing") Then
			Manager.SetTotalsUsing(Value1);
			
		ElsIf Upper(Action) = Upper("UseCurrentTotals") Then
			Manager.SetPresentTotalsUsing(Value1);
			
		ElsIf Upper(Action) = Upper("SetTotalsSeparation") Then
			Manager.SetTotalsSplittingMode(Value1);
			
		ElsIf Upper(Action) = Upper("SetTotalPeriod") Then
			
			If RegisterType = 0 Then
				Date = Value1;
				
			ElsIf RegisterType = 1 Then
				Date = Value2;
			EndIf;
			
			Manager.SetMaxTotalsPeriod(Date);
			
		ElsIf Upper(Action) = Upper("RecalcTotals") Then
			Manager.RecalcTotals();
			
		ElsIf Upper(Action) = Upper("RecalcPresentTotals") Then
			Manager.RecalcPresentTotals();
			
		ElsIf Upper(Action) = Upper("RecalcTotalsForPeriod") Then
			Manager.RecalcTotalsForPeriod(Value1, Value2);
			
		Else
			Raise NStr("vi = 'Sai tên tham số';
						|ru = 'Неправильное имя параметра';
						|en = 'Incorrect partner name'; fa = 'Incorrect partner name';
						|it = 'Il nome del parametro non valido';
						|pl = 'Nieprawidłowa nazwa parametru';
						|tr = 'Geçersiz parametre adı'") + "(1): " + Action;
		EndIf;
		
	Except
		
		Common.MessageToUser(
			ErrorMessage
			+ Chars.LF
			+ ErrorProcessing.BriefErrorDescription(ErrorInfo()),
			,
			ErrorField);
		Return False;
		
	EndTry;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function ChangeAggregatesServer(Val ServerParameters)
	
	Result = New Structure;
	Result.Insert("Success", True);
	Result.Insert("ActionValue1", ServerParameters.ActionValue1);
	Result.Insert("FileAddressInTempStorage", "");
	
	RegisterManager = AccumulationRegisters[ServerParameters.RegisterName];
	
	Try
		
		If Upper(ServerParameters.Action) = Upper("SetAggregatesMode") Then
			RegisterManager.SetAggregatesMode(ServerParameters.ActionValue1);
			
		ElsIf Upper(ServerParameters.Action) = Upper("SetAggregatesUsing") Then
			RegisterManager.SetAggregatesUsing(ServerParameters.ActionValue1);
			
		ElsIf Upper(ServerParameters.Action) = Upper("FillAggregates") Then
			RegisterManager.UpdateAggregates(False);
			
		ElsIf Upper(ServerParameters.Action) = Upper("RebuildAggregates") Then
			RegisterManager.RebuildAggregatesUsing(ServerParameters.ActionValue1, ServerParameters.ActionValue2);
			
		ElsIf Upper(ServerParameters.Action) = Upper("ClearAggregates") Then
			RegisterManager.ClearAggregates();
			
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sai tên tham số: %1';
					|ru = 'Неправильное имя параметра: %1';
					|en = 'Incorrect name of parameter: %1'; fa = 'Incorrect name of parameter: %1';
					|it = 'Il nome del parametro non valido: %1';
					|pl = 'Nieprawidłowa nazwa parametru: %1';
					|tr = 'Geçersiz parametre adı:%1'"),
				ServerParameters.Action);
		EndIf;
		
	Except
		
		ErrorMessage = ServerParameters.ErrorMessage + " (" + ErrorProcessing.BriefErrorDescription(ErrorInfo()) + ")";
		Common.MessageToUser(ErrorMessage);
		Result.Success = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetAdvancedMode()
	
	If FullFunctionality Then
		Title        = NStr("vi = 'Quản lý phần tổng kết - tính năng đầy đủ';
							|ru = 'Управление итогами - полные возможности';
							|en = 'Totals management - full functionality'; fa = 'Totals management - full functionality';
							|it = 'Gestione dei risultati - piene funzionalità';
							|pl = 'Zarządzanie wynikami - pełne możliwości';
							|tr = 'Toplam yönetimi - tüm olanaklar'");
		HyperlinkText = NStr("vi = 'Tính năng thường xuyên được sử dụng';
							|ru = 'Часто используемые возможности';
							|en = 'Frequently used features'; fa = 'قابلیت‌های پرکاربرد';
							|it = 'Funzionalità più utilizzate';
							|pl = 'Często używane możliwości';
							|tr = 'Sık kullanılan olanaklar'");
		Items.Operations.CurrentPage = Items.AdvancedFeatures;
	Else
		Title        = NStr("vi = 'Quản lý phần tổng kết - tính năng thường được sử dụng';
							|ru = 'Управление итогами - часто используемые возможности';
							|en = 'Totals management - frequently used features'; fa = 'Totals management - frequently used features';
							|it = 'Gestione dei risultati - funzionalità più utilizzate';
							|pl = 'Zarządzanie wynikami - często używane możliwości';
							|tr = 'Toplam yönetimi - sık kullanılan olanaklar'");
		HyperlinkText = NStr("vi = 'Tính năng đầy đủ';
							|ru = 'Полные возможности';
							|en = 'Full functionality'; fa = 'عملکرد کامل';
							|it = 'Funzionalità complete';
							|pl = 'Pełne możliwości';
							|tr = 'Tam olanaklar'");
		Items.Operations.CurrentPage = Items.QuickAccess;
	EndIf;
	
EndProcedure

#EndRegion

#Region Server

&AtServer
Function SelectedRows(TableName)
	
	Result = New Array;
	SelectedRows = Items[TableName].SelectedRows;
	Table = ThisObject[TableName];
	For Each Id In SelectedRows Do
		Result.Add(Table.FindByID(Id));
	EndDo;
	Return Result;
	
EndFunction

&AtServer
Procedure ReadInformationOnRegisters()
	
	TotalsList.Clear();
	AggregatesByRegisters.Clear();
	RegisterAggregatesList.Clear();
	
	Picture = PictureLib.AccountingRegister;
	For Each Register In Metadata.AccountingRegisters Do
		
		If Not AccessRight("TotalsControl", Register) Then
			Continue;
		EndIf;
		
		Presentation = Register.Presentation() + " (" + NStr("vi = 'biểu ghi kế toán';
															|ru = 'регистр бухгалтерии';
															|en = 'accounting register'; fa = 'accounting register';
															|it = 'registro contabilità';
															|pl = 'rejestr księgowości';
															|tr = 'muhasebe kaydı'") + ")";
		
		TableRow = TotalsList.Add();
		TableRow.Type                       = 1;
		TableRow.NameOfMetadataObject            = Register.Name;
		TableRow.Picture                  = Picture;
		TableRow.BalanceAndTurnovers           = True;
		TableRow.Description              = Presentation;
		TableRow.EnableTotalsSplitting = Register.EnableTotalsSplitting;
		
	EndDo;
	
	Picture = PictureLib.AccumulationRegister;
	For Each Register In Metadata.AccumulationRegisters Do
		
		Postfix = "";
		If Register.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers Then
			BalanceAndTurnovers = False;
			Postfix = NStr("vi = 'Biểu ghi tích lũy, chỉ phát sinh';
							|ru = 'регистр накопления, только обороты';
							|en = 'accumulation register, turnovers only'; fa = 'accumulation register, turnovers only';
							|it = 'registro di accumulo, solo fatturati';
							|pl = 'rejestr akumulacji, tylko obroty';
							|tr = 'birikim kaydı, sadece cirolar'");
		Else
			BalanceAndTurnovers = True;
			Postfix = NStr("vi = 'Biểu ghi tích lũy, số dư và phát sinh';
							|ru = 'регистр накопления, остатки и обороты';
							|en = 'accumulation register, balance and turnovers'; fa = 'accumulation register, balance and turnovers';
							|it = 'registro di accumulo, residui e fatturati';
							|pl = 'rejestr akumulacji, zapasy i obroty';
							|tr = 'birikim kaydı, kalanlar ve cirolar'");
		EndIf;
		
		If Not AccessRight("TotalsControl", Register) Then
			Continue;
		EndIf;
		
		Presentation = Register.Presentation() + " (" + Postfix + ")";
		
		TableRow = TotalsList.Add();
		TableRow.Type                       = 0;
		TableRow.NameOfMetadataObject            = Register.Name;
		TableRow.Picture                  = Picture;
		TableRow.BalanceAndTurnovers           = BalanceAndTurnovers;
		TableRow.Description              = Presentation;
		TableRow.EnableTotalsSplitting = Register.EnableTotalsSplitting ;
		
	EndDo;
	
	Picture = PictureLib.AccumulationRegister;
	For Each Register In Metadata.AccumulationRegisters Do
		
		If Register.RegisterType <> Metadata.ObjectProperties.AccumulationRegisterType.Turnovers Then
			Continue;
		EndIf;
		
		If Not AccessRight("TotalsControl", Register) Then
			Continue;
		EndIf;
		
		Presentation = Register.Presentation();
		Aggregates = Register.Aggregates;
		If Aggregates.Count() = 0 Then
			Continue;
		EndIf;
		
		TableRow = AggregatesByRegisters.Add();
		TableRow.NameOfMetadataObject       = Register.Name;
		TableRow.Picture             = Picture;
		TableRow.Description         = Presentation;
		TableRow.CompositionIsOptimal = True;
		
	EndDo;
	
	TotalsList.Sort("Description Asc");
	AggregatesByRegisters.Sort("Description Asc");
	
EndProcedure

#EndRegion

#EndRegion
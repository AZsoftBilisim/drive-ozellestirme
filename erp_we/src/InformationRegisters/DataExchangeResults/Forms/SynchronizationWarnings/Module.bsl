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
	
	ConditionalFormDesign();
	
	ValuesCache = New Structure("ArrayOfExchangePlanNodes, SelectionByDateOfOccurrence, SelectionOfExchangePlanNodes, SelectingTypesOfWarnings");
	ValuesCache.Insert("WarningsShowHiddenWarnings", False);
	ValuesCache.Insert("RejectedDueToPeriodEndClosingDateObjectExistsInInfobase", Undefined);
	ValuesCache.Insert("RejectedDueToPeriodEndClosingDateObjectDoesNotExistInInfobase", Undefined);
	ValuesCache.Insert("RejectedConflictData", Undefined);
	ValuesCache.Insert("ConflictDataAccepted", Undefined);
	
	TheVersioningSubsystemExists = Common.SubsystemExists("StandardSubsystems.ObjectsVersioning");
	ThereIsRightToReadVersionOfObjects = False;
	
	If TheVersioningSubsystemExists Then
		
		ThereIsRightToReadVersionOfObjects = AccessRight("Read", Metadata.InformationRegisters.ObjectsVersions);

		If ThereIsRightToReadVersionOfObjects Then

			EnumManager = Enums["ObjectVersionTypes"];
			ValuesCache.Insert("RejectedDueToPeriodEndClosingDateObjectExistsInInfobase",
				EnumManager.RejectedDueToPeriodEndClosingDateObjectExistsInInfobase);
			ValuesCache.Insert("RejectedDueToPeriodEndClosingDateObjectDoesNotExistInInfobase",
				EnumManager.RejectedDueToPeriodEndClosingDateObjectDoesNotExistInInfobase);
			ValuesCache.Insert("RejectedConflictData", EnumManager.RejectedConflictData);
			ValuesCache.Insert("ConflictDataAccepted", EnumManager.ConflictDataAccepted);

			DynamicListWithVersioningWarnings();

			Items.ListConflicts.Visible = True;
			Items.ListImportRestrictionByDate.Visible = True;

		EndIf;
		
	EndIf;
	
	SelectionsBasedOnTheTransmittedParameters();
	
	FieldArray = New Array;
	FieldArray.Add("HasComment");
	FieldArray.Add("ObjectWithIssue");
	FieldArray.Add("LongDesc");
	
	List.SetRestrictionsForUseInOrder(FieldArray);
	
	List.Parameters.SetParameterValue("UnpostedDocument", NStr("vi = 'Chứng từ chưa kết chuyển';
																|ru = 'Непроведенный документ';
																|en = 'Unposted document'; fa = 'سند ثبت قطعی‌نشده';
																|it = 'Documento non inviato';
																|pl = 'Niezaksięgowany dokument';
																|tr = 'Gönderilmeyen belge'", Common.DefaultLanguageCode()));
	List.Parameters.SetParameterValue("EmptyAttributes", NStr("vi = 'Mục tin trống';
																|ru = 'Пустые реквизиты';
																|en = 'Empty attributes'; fa = 'Empty attributes';
																|it = 'Requisiti vuoti';
																|pl = 'Puste atrybuty';
																|tr = 'Boş öznitelikler'", Common.DefaultLanguageCode()));
	List.Parameters.SetParameterValue("CheckBeforeSend", NStr("vi = 'Kiểm tra trước khi gửi';
																|ru = 'Проверка перед отправкой';
																|en = 'Check before sending'; fa = 'Check before sending';
																|it = 'Verifica prima dell''invio';
																|pl = 'Sprawdzenie przed wysyłką';
																|tr = 'Gönderimden önce kontrol'", Common.DefaultLanguageCode()));
	List.Parameters.SetParameterValue("TechnicalErrorSend", NStr("vi = 'Lỗi kỹ thuật (gửi)';
																|ru = 'Тех. ошибка (отправка)';
																|en = 'Technical error (sending)'; fa = 'Technical error (sending)';
																|it = 'Errore tecn. (invio)';
																|pl = 'Błąd techniczny (wysyłka)';
																|tr = 'Tek. hata (gönderim)'", Common.DefaultLanguageCode()));
	List.Parameters.SetParameterValue("TechnicalErrorGet", NStr("vi = 'Lỗi kỹ thuật (nhận)';
																|ru = 'Тех. ошибка (получение)';
																|en = 'Technical error (receipt)'; fa = 'Technical error (receipt)';
																|it = 'Errore tecn. (ricezione)';
																|pl = 'Błąd techniczny (odbiór)';
																|tr = 'Tek. hata (alım)'", Common.DefaultLanguageCode()));
	
	If TheVersioningSubsystemExists And ThereIsRightToReadVersionOfObjects Then
		
		List.Parameters.SetParameterValue("UnrecognizedExisting", NStr("vi = 'Chưa nhận, hiện có';
																		|ru = 'Непринятый, существующий';
																		|en = 'Rejected, existing'; fa = 'Rejected, existing';
																		|it = 'Non ricevuto, esistente';
																		|pl = 'Nieprzyjęty, istniejący';
																		|tr = 'Alınmayan, geçerli'", Common.DefaultLanguageCode()));
		List.Parameters.SetParameterValue("RejectedNew", NStr("vi = 'Chưa nhận, mới';
																|ru = 'Непринятый, новый';
																|en = 'Rejected, new'; fa = 'Rejected, new';
																|it = 'Non ricevuto, nuovo';
																|pl = 'Nieprzyjęty, nowy';
																|tr = 'Alınmayan, yeni'", Common.DefaultLanguageCode()));
		List.Parameters.SetParameterValue("AcceptedCollisionData", NStr("vi = 'Đã tiếp nhận dữ liệu xung đột';
																		|ru = 'Приняты данные коллизии';
																		|en = 'Received conflict data'; fa = 'Received conflict data';
																		|it = 'Dati conflitto ricevuti';
																		|pl = 'Przyjęte dane kolizji';
																		|tr = 'Veri çarpışmaları kabul edildi'", Common.DefaultLanguageCode()));
		List.Parameters.SetParameterValue("RejectedCollisionData", NStr("vi = 'Chưa tiếp nhận dữ liệu xung đột';
																		|ru = 'Неприняты данные коллизии';
																		|en = 'Rejected conflict data'; fa = 'Rejected conflict data';
																		|it = 'Dati conflitto non ricevuti';
																		|pl = 'Nieprzyjęte dane kolizji';
																		|tr = 'Veri çarpışmaları kabul edilmedi'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FilterByPeriodPresentation();
	RepresentationOfTheSelectionOfExchangeNodes();
	RepresentationOfTheSelectionByTypesOfWarnings();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CorrectionOfDocumentSynchronizationWarnings"
		Or EventName = "FixingSynchronizationWarningsReviewingCollisions"
		Or EventName = "CorrectionOfSynchronizationWarningsRevisionOfTheBanDate"
		Then
		
		UpdateTheFormList();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterByPeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Dialog = New StandardPeriodEditDialog();
	Dialog.Period = ValuesCache.SelectionByDateOfOccurrence;
	Dialog.Show(New CallbackDescription("AfterSelectionByDateOfOccurrence", ThisObject));
	
EndProcedure

&AtClient
Procedure AfterSelectionByDateOfOccurrence(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("StandardPeriod") Then
		
		Return;
		
	EndIf;
	
	ValuesCache.SelectionByDateOfOccurrence = Result;
	SelectionByDateOfOccurrence();
	FilterByPeriodPresentation();
	
EndProcedure

&AtClient
Procedure FilterByPeriodPresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SynchronizationsFilterPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ArrayOfExchangePlanNodes", ValuesCache.ArrayOfExchangePlanNodes);
	OpeningParameters.Insert("SelectionOfExchangePlanNodes", ValuesCache.SelectionOfExchangePlanNodes);
	
	CallbackDescription = New CallbackDescription("AfterSelectingTheExchangeNodes", ThisObject);
	
	OpenForm("InformationRegister.DataExchangeResults.Form.SynchronizationsFilter", OpeningParameters, ThisObject, , , , CallbackDescription);
	
EndProcedure

&AtClient
Procedure AfterSelectingTheExchangeNodes(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("Array") Then
		
		Return;
		
	EndIf;
	
	ValuesCache.SelectionOfExchangePlanNodes = Result;
	SelectionByNodesOfTheInformationBase();
	RepresentationOfTheSelectionOfExchangeNodes();
	
EndProcedure

&AtClient
Procedure SynchronizationsFilterPresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure WarningsTypesFilterPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("SelectingTypesOfWarnings", ValuesCache.SelectingTypesOfWarnings);
	
	CallbackDescription = New CallbackDescription("AfterSelectionByTypeOfWarnings", ThisObject);
	
	OpenForm("InformationRegister.DataExchangeResults.Form.WarningsFilterByTypes", OpeningParameters, ThisObject, , , , CallbackDescription);
	
EndProcedure

&AtClient
Procedure AfterSelectionByTypeOfWarnings(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("Array") Then
		
		Return;
		
	EndIf;
	
	ValuesCache.SelectingTypesOfWarnings = Result;
	SelectionByTypesOfWarnings();
	RepresentationOfTheSelectionByTypesOfWarnings();
	
EndProcedure

&AtClient
Procedure WarningsTypesFilterPresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRowData = CurrentWarningListData();
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("OccurrenceDate", CurrentRowData.OccurrenceDate);
	OpeningParameters.Insert("ObjectWithIssue", CurrentRowData.ObjectWithIssue);
	OpeningParameters.Insert("LongDesc", CurrentRowData.LongDesc);
	OpeningParameters.Insert("WarningType", CurrentRowData.WarningType);
	OpeningParameters.Insert("InfobaseNode", CurrentRowData.InfobaseNode);
	OpeningParameters.Insert("MetadataObject", CurrentRowData.MetadataObject);
	OpeningParameters.Insert("UniqueKey", CurrentRowData.UniqueKey);
	OpeningParameters.Insert("HideWarning", CurrentRowData.HideWarning);
	OpeningParameters.Insert("WarningComment", CurrentRowData.WarningComment);
	OpeningParameters.Insert("VersionFromOtherApplication", CurrentRowData.VersionFromOtherApplication);
	OpeningParameters.Insert("ThisApplicationVersion", CurrentRowData.ThisApplicationVersion);
	OpeningParameters.Insert("ThisApplicationVersion", CurrentRowData.ThisApplicationVersion);
	OpeningParameters.Insert("VersionFromOtherApplicationAccepted", CurrentRowData.VersionFromOtherApplicationAccepted);
	OpeningParameters.Insert("IsNewObject", CurrentRowData.IsNewObject);
	
	OpenTheProblemCard(OpeningParameters);
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("AvailabilityOfFormListCommands", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenObject(Command)
	
	TheCurrentDataRow = CurrentWarningListData();
	OpenTheObjectOfTheCurrentLine(TheCurrentDataRow);
	
EndProcedure

&AtClient
Procedure WarningsHideFromList(Command)
	
	ChangeTheWarningStatus(Items.List.SelectedRows, True);
	
EndProcedure

&AtClient
Procedure WarningsShowInList(Command)
	
	ChangeTheWarningStatus(Items.List.SelectedRows, False);
	
EndProcedure

&AtClient
Procedure WarningsShowHiddenWarnings(Command)
	
	ValuesCache.WarningsShowHiddenWarnings = Not ValuesCache.WarningsShowHiddenWarnings;
	
	SelectionOfHiddenWarnings();
	Items.ListWarningsShowHiddenWarnings.Check = ValuesCache.WarningsShowHiddenWarnings;
	Items.ListContextMenuWarningsShowHiddenWarnings.Check = ValuesCache.WarningsShowHiddenWarnings;
	
	
EndProcedure

&AtClient
Procedure EventLog(Command)
	
	WarningsLevels = New Array;
	WarningsLevels.Add(NStr("vi = 'Lỗi';
							|ru = 'Ошибка';
							|en = 'Error'; fa = 'خطا';
							|it = 'Errore';
							|pl = 'Błąd';
							|tr = 'Hata'", CommonClient.DefaultLanguageCode()));
	WarningsLevels.Add(NStr("vi = 'Cảnh báo';
							|ru = 'Предупреждение';
							|en = 'Warning'; fa = 'هشدار';
							|it = 'Avviso';
							|pl = 'Ostrzeżenie';
							|tr = 'Uyarı'", CommonClient.DefaultLanguageCode()));
	
	ThereAreUploadEvents = False;
	ThereAreLoadingEvents = False;
	DefineUploadUploadEvents(ThereAreUploadEvents, ThereAreLoadingEvents);
		
	LogFilterParameters = New Structure;
	LogFilterParameters.Insert("Level", WarningsLevels);

	EventLogEvent = New Array;
	For Each Node In ValuesCache.ArrayOfExchangePlanNodes Do
		
		If ThereAreUploadEvents Then
			MessageKey = DataExchangeServerCall.EventLogMessageKeyByActionString(Node, "DataExport");
			If EventLogEvent.Find(MessageKey) = Undefined Then
				EventLogEvent.Add(MessageKey);
			EndIf;
		EndIf;
		
		If ThereAreLoadingEvents Then
			MessageKey = DataExchangeServerCall.EventLogMessageKeyByActionString(Node, "DataImport");
			If EventLogEvent.Find(MessageKey) = Undefined Then
				EventLogEvent.Add(MessageKey);
			EndIf;
		EndIf;
		
	EndDo;
	
	LogFilterParameters.Insert("EventLogEvent", EventLogEvent); 

	OpenForm("DataProcessor.EventLog.Form", LogFilterParameters, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure DefineUploadUploadEvents(ThereAreUploadEvents, ThereAreLoadingEvents)
	
	Filter = ValuesCache.SelectingTypesOfWarnings;
	
	ThereAreUploadEvents = 
		Filter.Find(Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData) <> Undefined
		Or Filter.Find(Enums.DataExchangeIssuesTypes.ConvertedObjectValidationError) <> Undefined;
		
	ThereAreLoadingEvents =
		Filter.Find(Enums.DataExchangeIssuesTypes.UnpostedDocument) <> Undefined
		Or Filter.Find(Enums.DataExchangeIssuesTypes.BlankAttributes) <> Undefined
		Or Filter.Find(Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData) <> Undefined;
		
	TheVersioningSubsystemExists = Common.SubsystemExists("StandardSubsystems.ObjectsVersioning");
	If Not ThereAreLoadingEvents And TheVersioningSubsystemExists Then
		
		If AccessRight("Read", Metadata.InformationRegisters.ObjectsVersions) Then

			EnumManager = Enums["ObjectVersionTypes"];

			ThereAreLoadingEvents = Filter.Find(EnumManager.RejectedDueToPeriodEndClosingDateObjectExistsInInfobase) <> Undefined
				Or Filter.Find(EnumManager.RejectedDueToPeriodEndClosingDateObjectDoesNotExistInInfobase) <> Undefined
				Or Filter.Find(EnumManager.RejectedConflictData) <> Undefined Or Filter.Find(
				EnumManager.ConflictDataAccepted) <> Undefined;

		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EventLogAtSpecifiedTime(Command)
	
	CurrentRowData = CurrentWarningListData();
	
	If Not ValueIsFilled(CurrentRowData.OccurrenceDate) Then
		
		WarningText = NStr("vi = 'Trong dòng hiện tại chưa chỉ ra ngày và giờ xuất hiện cảnh báo';
							|ru = 'В текущей строке не указано время и дата возникновения предупреждения';
							|en = 'The current line does not contain the time and warning date specified'; fa = 'The current line does not contain the time and warning date specified';
							|it = 'Nella riga corrente non sono indicate ora e data del rilevamento della notifica';
							|pl = 'W bieżącym wierszu nie podano czasu i daty powstania ostrzeżenia';
							|tr = 'Geçerli satırda uyarının oluşma saati ve tarihi belirtilmemiş'", CommonClient.DefaultLanguageCode());
		ShowMessageBox(Undefined, WarningText);
		
	EndIf;
	
	LogFilterParameters = New Structure;
	LogFilterParameters.Insert("StartDate",                CurrentRowData.OccurrenceDate - 1);
	LogFilterParameters.Insert("EndDate",             CurrentRowData.OccurrenceDate + 1);
	
	OpenForm("DataProcessor.EventLog.Form", LogFilterParameters, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure DisableAutomaticFormUpdate(Command)
	
	Items.ListDisableAutomaticFormUpdate.Check = Not Items.ListDisableAutomaticFormUpdate.Check;
	
EndProcedure

&AtClient
Procedure ObsoleteRecordsDeletion(Command)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ArrayOfExchangePlanNodes", ValuesCache.ArrayOfExchangePlanNodes);
	OpeningParameters.Insert("SelectionByDateOfOccurrence", ValuesCache.SelectionByDateOfOccurrence);
	OpeningParameters.Insert("SelectionOfExchangeNodes", ValuesCache.SelectionOfExchangePlanNodes);
	OpeningParameters.Insert("SelectingTypesOfWarnings", ValuesCache.SelectingTypesOfWarnings); 
	OpeningParameters.Insert("OnlyHiddenRecords", True);
	
	CallbackDescription = New CallbackDescription("AfterDeletingOutdatedRecords", ThisObject);
	
	DataExchangeClient.OpenFormForDeletingSyncAlerts(OpeningParameters, CallbackDescription);
	
EndProcedure

&AtClient
Procedure AfterDeletingOutdatedRecords(Result, AdditionalParameters) Export
	
	UpdateTheFormList();
	
EndProcedure

&AtClient
Procedure PreviousWarningsForm(Command)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ExchangeNodes", ValuesCache.ArrayOfExchangePlanNodes);
	
	OpenForm("InformationRegister.DataExchangeResults.Form.Form", OpeningParameters, ThisObject);
	
	Close();
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	NavigateDocumentsThroughTheSelectedLines(Items.List.SelectedRows);
	
EndProcedure

&AtClient
Procedure Conflicts(Command)
	
	CollisionsOnSelectedLines(Items.List.SelectedRows);
	
EndProcedure

&AtClient
Procedure ImportRestrictionByDate(Command)
	
	ForbiddingLoadingBySelectedLines(Items.List.SelectedRows);
	
EndProcedure

&AtClient
Procedure BatchEditAttributes(Command)
	
	GroupChangeOfDetailsForSelectedLines(Items.List.SelectedRows);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function CurrentWarningListData()
	
	CurrentRowData = Items.List.CurrentData;
	If CurrentRowData = Undefined
		Or TypeOf(Items.List.CurrentRow) = Type("DynamicListGroupRow")
		Then
		
		ExceptionText = NStr("vi = 'Đối với dòng hiện tại không cho phép thực hiện lệnh';
							|ru = 'Для текущей строки выполнение команды не предусмотрено';
							|en = 'No command execution is provided for the current line'; fa = 'No command execution is provided for the current line';
							|it = 'Non è prevista l''esecuzione del comando per la riga corrente';
							|pl = 'Dla bieżącego wiersza wykonanie polecenia nie jest przewidziane';
							|tr = 'Geçerli satır için komut çalıştırılmaz '", CommonClient.DefaultLanguageCode());
		Raise ExceptionText;
		
	EndIf;
	
	Return CurrentRowData;
	
EndFunction

&AtClient
Procedure OpenTheObjectOfTheCurrentLine(CurrentRowData)
	
	If Not ValueIsFilled(CurrentRowData.ObjectWithIssue) Then
		
		WarningText = NStr("vi = 'Cảnh báo tại dòng hiện tại không liên quan với đối tượng của cơ sở thông tin';
							|ru = 'Предупреждение в текущей строке не привязано к объекту информационной базы';
							|en = 'Warning in the current line is not linked to an infobase object'; fa = 'Warning in the current line is not linked to an infobase object';
							|it = 'La notifica nella riga corrente non è collegata all''oggetto di infobase';
							|pl = 'Ostrzeżenie w bieżącym wierszu nie jest powiązane z obiektem bazy informacyjnej';
							|tr = 'Geçerli satırdaki uyarı infobase nesnesine bağlı değil'", CommonClient.DefaultLanguageCode());
		ShowMessageBox(Undefined, WarningText);
		Return;
		
	EndIf;
	
	CallbackDescription = New CallbackDescription("AfterOpeningTheObject", ThisObject);
	ShowValue(CallbackDescription, CurrentRowData.ObjectWithIssue);
	
EndProcedure

&AtClient
Procedure AfterOpeningTheObject(AdditionalParameters) Export
	
	UpdateTheFormList();
	
EndProcedure

&AtClient
Procedure FilterByPeriodPresentation()
	
	If Not ValueIsFilled(ValuesCache.SelectionByDateOfOccurrence) Then
		
		FilterByPeriodPresentation = NStr("vi = 'Chưa đặt bộ lọc';
											|ru = 'Отбор не установлен';
											|en = 'Filter not set'; fa = 'Filter not set';
											|it = 'La selezione non è impostata';
											|pl = 'Filtr nie jest ustawiony';
											|tr = 'Filtre kurulmadı'", CommonClient.DefaultLanguageCode());
		
	Else
		
		FilterByPeriodPresentation = TrimAll(ValuesCache.SelectionByDateOfOccurrence);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RepresentationOfTheSelectionOfExchangeNodes()
	
	If ValuesCache.SelectionOfExchangePlanNodes = Undefined
		Or ValuesCache.SelectionOfExchangePlanNodes.Count() = 0 Then
		
		SynchronizationsFilterPresentation = NStr("vi = 'Chưa đặt bộ lọc';
													|ru = 'Отбор не установлен';
													|en = 'Filter not set'; fa = 'Filter not set';
													|it = 'La selezione non è impostata';
													|pl = 'Filtr nie jest ustawiony';
													|tr = 'Filtre kurulmadı'", CommonClient.DefaultLanguageCode());
		
	ElsIf ValuesCache.SelectionOfExchangePlanNodes.Count() = 1 Then
		
		SynchronizationsFilterPresentation = String(ValuesCache.SelectionOfExchangePlanNodes[0]);
		
	Else
		
		TextTemplate1 = NStr("vi = '%1%2 (và hơn nữa %3)';
							|ru = '%1%2 (и еще %3 шт.)';
							|en = '%1%2 (and %3 more pcs)'; fa = '%1%2 (and %3 more pcs)';
							|it = '%1%2 (e ancora %3 pz.)';
							|pl = '%1%2 (i jeszcze %3 szt.)';
							|tr = '%1%2 (ve ek olarak %3 ad.)'", CommonClient.DefaultLanguageCode());
		Triplets = ?(StrLen(TrimAll(ValuesCache.SelectionOfExchangePlanNodes[0])) > 32, "...", "");
		NumberOfMore = ValuesCache.SelectionOfExchangePlanNodes.Count() - 1;
		
		SynchronizationsFilterPresentation = StrTemplate(TextTemplate1, Left(TrimAll(ValuesCache.SelectionOfExchangePlanNodes[0]), 33), Triplets, NumberOfMore);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RepresentationOfTheSelectionByTypesOfWarnings()
	
	If ValuesCache.SelectingTypesOfWarnings = Undefined
		Or ValuesCache.SelectingTypesOfWarnings.Count() = 0 Then
		
		WarningsTypesFilterPresentation = NStr("vi = 'Chưa đặt bộ lọc';
												|ru = 'Отбор не установлен';
												|en = 'Filter not set'; fa = 'Filter not set';
												|it = 'La selezione non è impostata';
												|pl = 'Filtr nie jest ustawiony';
												|tr = 'Filtre kurulmadı'", CommonClient.DefaultLanguageCode());
		
	ElsIf ValuesCache.SelectingTypesOfWarnings.Count() = 1 Then
		
		WarningsTypesFilterPresentation = String(ValuesCache.SelectingTypesOfWarnings[0]);
		
	ElsIf ValuesCache.SelectingTypesOfWarnings.Count() > 8 Then
		
		WarningsTypesFilterPresentation = NStr("vi = 'Tất cả kiểu cảnh báo';
												|ru = 'Все типы предупреждений';
												|en = 'All warning types'; fa = 'All warning types';
												|it = 'Tutti i tipi di notifica';
												|pl = 'Wszystkie typy ostrzeżeń';
												|tr = 'Tüm uyarı türleri'", CommonClient.DefaultLanguageCode());
		
	Else
		
		TextTemplate1 = NStr("vi = '%1%2 (và hơn nữa %3)';
							|ru = '%1%2 (и еще %3 шт.)';
							|en = '%1%2 (and %3 more pcs)'; fa = '%1%2 (and %3 more pcs)';
							|it = '%1%2 (e ancora %3 pz.)';
							|pl = '%1%2 (i jeszcze %3 szt.)';
							|tr = '%1%2 (ve ek olarak %3 ad.)'", CommonClient.DefaultLanguageCode());
		Triplets = ?(StrLen(TrimAll(ValuesCache.SelectingTypesOfWarnings[0])) > 32, "...", "");
		NumberOfMore = ValuesCache.SelectingTypesOfWarnings.Count() - 1;
		
		WarningsTypesFilterPresentation = StrTemplate(TextTemplate1, Left(TrimAll(ValuesCache.SelectingTypesOfWarnings[0]), 33), Triplets, NumberOfMore);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenTheProblemCard(OpeningParameters)
	Var ObjectWithIssue, WarningType;
	
	OpeningParameters.Property("ObjectWithIssue", ObjectWithIssue);
	OpeningParameters.Property("WarningType", WarningType);
	
	CallbackDescription = New CallbackDescription("AfterClosingTheWarningCard", ThisObject);
	
	If WarningType = PredefinedValue("Enum.DataExchangeIssuesTypes.ApplicationAdministrativeError") Then
		
		OpenForm("InformationRegister.DataExchangeResults.Form.ApplicationAdministrationWarning", OpeningParameters, ThisObject, , , , CallbackDescription);
		
	ElsIf WarningType = PredefinedValue("Enum.DataExchangeIssuesTypes.BlankAttributes") Then
		
		OpenForm("InformationRegister.DataExchangeResults.Form.BlankAttributeWarning", OpeningParameters, ThisObject, , , , CallbackDescription);
		
	ElsIf WarningType = PredefinedValue("Enum.DataExchangeIssuesTypes.UnpostedDocument") Then
		
		OpenForm("InformationRegister.DataExchangeResults.Form.UnpostedDocumentWarning", OpeningParameters, ThisObject, , , , CallbackDescription);
		
	ElsIf WarningType = PredefinedValue("Enum.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData")
		Or WarningType = PredefinedValue("Enum.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData") Then
		
		OpenForm("InformationRegister.DataExchangeResults.Form.ReceiptSendingHandlersWarnings", OpeningParameters, ThisObject, , , , CallbackDescription);
		
	ElsIf WarningType = PredefinedValue("Enum.DataExchangeIssuesTypes.ConvertedObjectValidationError") Then
		
		OpenForm("InformationRegister.DataExchangeResults.Form.ObjectConversionWarningOnSend", OpeningParameters, ThisObject, , , , CallbackDescription);
		
	ElsIf WarningType = ValuesCache.RejectedDueToPeriodEndClosingDateObjectExistsInInfobase
		Or WarningType = ValuesCache.RejectedDueToPeriodEndClosingDateObjectDoesNotExistInInfobase Then
		
		OpenForm("InformationRegister.DataExchangeResults.Form.WarningByImportRestrictionDate", OpeningParameters, ThisObject, , , , CallbackDescription);
		
	ElsIf WarningType = ValuesCache.RejectedConflictData
		Or WarningType = ValuesCache.ConflictDataAccepted Then
		
		OpenForm("InformationRegister.DataExchangeResults.Form.ConflictWarning", OpeningParameters, ThisObject, , , , CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingTheWarningCard(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		UpdateTheFormList();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeTheWarningStatus(SelectedRows, HideDisplay)
	
	ASetOfStructures = New Array;
	For Each RowIndex In SelectedRows Do
		
		RowData = Items.List.RowData(RowIndex);
		If RowData = Undefined Then
			
			Continue;
			
		EndIf;
		
		StringDataStructure = New Structure("ObjectWithIssue, WarningType, InfobaseNode, UniqueKey, VersionFromOtherApplication");
		FillPropertyValues(StringDataStructure, RowData);
		
		ASetOfStructures.Add(StringDataStructure);
		
	EndDo;
	
	ChangeTheWarningStatusOnTheServer(ASetOfStructures, HideDisplay);
	UpdateTheFormList();
	AvailabilityOfFormListCommands();
	
EndProcedure

&AtClient
Procedure UpdateTheFormList()
	
	If Not Items.ListDisableAutomaticFormUpdate.Check Then
		
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AvailabilityOfFormListCommands()
	
	CurrentRowData = Items.List.CurrentData;
	If CurrentRowData = Undefined
		Or TypeOf(Items.List.CurrentRow) = Type("DynamicListGroupRow")
		Then
		
		Items.ListWarningsHideFromList.Enabled = False;
		Items.ListWarningsShowInList.Enabled = False;
		Items.ListContextMenuWarningsHideFromList.Enabled = False;
		Items.ListContextMenuWarningsShowInList.Enabled = False;
		Items.ListOpenObject.Enabled = False;
		Items.ListPostDocument.Enabled = False;
		Items.ListBatchEditAttributes.Enabled = False;
		Items.ListConflicts.Enabled = False;
		Items.ListImportRestrictionByDate.Enabled = False;
		Return;
		
	EndIf;
	
	Items.ListWarningsHideFromList.Enabled = Not CurrentRowData.HideWarning;
	Items.ListWarningsShowInList.Enabled = CurrentRowData.HideWarning;
	Items.ListContextMenuWarningsHideFromList.Enabled = Not CurrentRowData.HideWarning;
	Items.ListContextMenuWarningsShowInList.Enabled = CurrentRowData.HideWarning;
	
	If Items.ListOpenObject.Enabled = False Then
		
		Items.ListOpenObject.Enabled = True;
		Items.ListPostDocument.Enabled = True;
		Items.ListBatchEditAttributes.Enabled = True;
		Items.ListConflicts.Enabled = True;
		Items.ListImportRestrictionByDate.Enabled = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DynamicListWithVersioningWarnings()
	
	ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
	QueryTextVersions = ModuleObjectsVersioning.TextOfTheVersionWarningListRequest();
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = List.QueryText + Chars.LF + "UNION ALL" + Chars.LF + QueryTextVersions;
	ListProperties.MainTable = "";
	ListProperties.DynamicDataRead = False;
	
	Common.SetDynamicListProperties(Items.List, ListProperties)
	
EndProcedure

&AtServer
Procedure AddDesignFields(ConditionalAppearanceItem, DesignFieldNames)
	
	For Each FieldName In DesignFieldNames Do
		
		AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
		AppearanceField.Field = New DataCompositionField(FieldName);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ConditionalFormDesign()
	
	DesignFieldNames = New Array;
	DesignFieldNames.Add("OccurrenceDate");
	DesignFieldNames.Add("ObjectWithIssue");
	DesignFieldNames.Add("LongDesc");
	DesignFieldNames.Add("WarningTypePresentation");
	DesignFieldNames.Add("InfobaseNode");
	DesignFieldNames.Add("UniqueKey");
	
	// Highlight blocking warnings in red.
	TypesOfCriticalWarnings = New ValueList;
	TypesOfCriticalWarnings.Add(Enums.DataExchangeIssuesTypes.ApplicationAdministrativeError);
	TypesOfCriticalWarnings.Add(Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData);
	TypesOfCriticalWarnings.Add(Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData);
	
	ErrorsInRed = ConditionalAppearance.Items.Add();
	CommonClientServer.AddCompositionItem(ErrorsInRed.Filter, "List.WarningType", DataCompositionComparisonType.InList, TypesOfCriticalWarnings);
	ErrorsInRed.Appearance.SetParameterValue("TextColor", WebColors.DarkRed);
	AddDesignFields(ErrorsInRed, DesignFieldNames);
	
	// Format hidden warnings in gray.
	HiddenWarningsInGray = ConditionalAppearance.Items.Add();
	CommonClientServer.AddCompositionItem(HiddenWarningsInGray.Filter, "List.HideWarning", DataCompositionComparisonType.Equal, True);
	HiddenWarningsInGray.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	AddDesignFields(HiddenWarningsInGray, DesignFieldNames);
	
EndProcedure

&AtServer
Procedure SelectionsBasedOnTheTransmittedParameters()
	
	Parameters.Property("SelectionByDateOfOccurrence", ValuesCache.SelectionByDateOfOccurrence);
	SelectionByDateOfOccurrence();
	
	Parameters.Property("ExchangeNodes", ValuesCache.ArrayOfExchangePlanNodes);
	Parameters.Property("SelectionOfExchangeNodes", ValuesCache.SelectionOfExchangePlanNodes);
	SelectionByNodesOfTheInformationBase();
	
	Parameters.Property("SelectingTypesOfWarnings", ValuesCache.SelectingTypesOfWarnings); 
	SelectionByTypesOfWarnings();
	
	SelectionOfHiddenWarnings()
	
EndProcedure

&AtServer
Procedure SelectionByDateOfOccurrence()
	Var DataSelectionGroup;
	
	If TypeOf(ValuesCache.SelectionByDateOfOccurrence) <> Type("StandardPeriod") Then
		
		ValuesCache.SelectionByDateOfOccurrence = New StandardPeriod;
		
	EndIf;
	
	Use = ValueIsFilled(ValuesCache.SelectionByDateOfOccurrence);
	
	RepresentationOfTheSelectionGroup = NStr("vi = 'Lọc theo ngày xuất hiện';
											|ru = 'Отбор по дате возникновения';
											|en = 'Filter by issue date'; fa = 'Filter by issue date';
											|it = 'Filtro per data di rilevamento';
											|pl = 'Filtr według daty powstania';
											|tr = 'Oluşma tarihine göre seçim'", Common.DefaultLanguageCode());
	
	FindTheSelectionElementOfTheDynamicList(Undefined, DataSelectionGroup, Undefined, RepresentationOfTheSelectionGroup, True);
	If DataSelectionGroup = Undefined Then
		
		DataSelectionGroup = List.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		DataSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		DataSelectionGroup.Presentation = RepresentationOfTheSelectionGroup;
		DataSelectionGroup.Use = Use;
		
	Else
		
		DataSelectionGroup.Use = Use;
		
	EndIf;
	
	SelectionByDateOfOccurrence = ValuesCache.SelectionByDateOfOccurrence; // StandardPeriod
	
	ParametersOfTheSelectionElement = New Structure;
	ParametersOfTheSelectionElement.Insert("ItemsCollection", DataSelectionGroup.Items);
	ParametersOfTheSelectionElement.Insert("DataFilterItem", Undefined);
	ParametersOfTheSelectionElement.Insert("LeftSelectionValue", New DataCompositionField("OccurrenceDate"));
	ParametersOfTheSelectionElement.Insert("ComparisonType", DataCompositionComparisonType.GreaterOrEqual);
	ParametersOfTheSelectionElement.Insert("RightValue", SelectionByDateOfOccurrence.StartDate);
	ParametersOfTheSelectionElement.Insert("FilterPresentation", NStr("vi = 'Lọc ngày từ';
																		|ru = 'Отбор даты с';
																		|en = 'Filter date from'; fa = 'Filter date from';
																		|it = 'Filtro data da';
																		|pl = 'Filtr daty od';
																		|tr = 'Tarih seçimi'", Common.DefaultLanguageCode()));
	ParametersOfTheSelectionElement.Insert("Use", Use);
	
	SetTheDynamicListSelectionValue(ParametersOfTheSelectionElement);
	
	ParametersOfTheSelectionElement.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ParametersOfTheSelectionElement.RightValue = SelectionByDateOfOccurrence.EndDate;
	ParametersOfTheSelectionElement.FilterPresentation = NStr("vi = 'Lọc ngày đến';
																|ru = 'Отбор даты по';
																|en = 'Filter date to'; fa = 'Filter date to';
																|it = 'Filtro data fino a';
																|pl = 'Filtr daty do';
																|tr = 'Tarih seçimi'", Common.DefaultLanguageCode());
	
	SetTheDynamicListSelectionValue(ParametersOfTheSelectionElement);
	
EndProcedure

&AtServer
Procedure SelectionByNodesOfTheInformationBase()
	
	Use = TypeOf(ValuesCache.SelectionOfExchangePlanNodes) = Type("Array")
		And (ValuesCache.SelectionOfExchangePlanNodes.Count() > 0);
		
	ParametersOfTheSelectionElement = New Structure;
	ParametersOfTheSelectionElement.Insert("DataFilterItem", Undefined);
	ParametersOfTheSelectionElement.Insert("LeftSelectionValue", New DataCompositionField("InfobaseNode"));
	ParametersOfTheSelectionElement.Insert("ComparisonType", DataCompositionComparisonType.InList);
	ParametersOfTheSelectionElement.Insert("RightValue", ValuesCache.SelectionOfExchangePlanNodes);
	ParametersOfTheSelectionElement.Insert("FilterPresentation", NStr("vi = 'Lọc đồng bộ';
																		|ru = 'Отбор синхронизаций';
																		|en = 'Synchronization filter'; fa = 'Synchronization filter';
																		|it = 'Filtro sincronizzazione';
																		|pl = 'Filtr synchronizacji';
																		|tr = 'Senkronizasyon seçimi'", Common.DefaultLanguageCode()));
	ParametersOfTheSelectionElement.Insert("Use", Use);
	
	SetTheDynamicListSelectionValue(ParametersOfTheSelectionElement);
	
EndProcedure

&AtServer
Procedure SelectionByTypesOfWarnings()
	
	Use = TypeOf(ValuesCache.SelectingTypesOfWarnings) = Type("Array")
		And (ValuesCache.SelectingTypesOfWarnings.Count() > 0);
		
	ParametersOfTheSelectionElement = New Structure;
	ParametersOfTheSelectionElement.Insert("DataFilterItem", Undefined);
	ParametersOfTheSelectionElement.Insert("LeftSelectionValue", New DataCompositionField("WarningType"));
	ParametersOfTheSelectionElement.Insert("ComparisonType", DataCompositionComparisonType.InList);
	ParametersOfTheSelectionElement.Insert("RightValue", ValuesCache.SelectingTypesOfWarnings);
	ParametersOfTheSelectionElement.Insert("FilterPresentation", NStr("vi = 'Lọc theo kiểu cảnh báo';
																		|ru = 'Отбор по типу предупреждения';
																		|en = 'Filter by warning type'; fa = 'Filter by warning type';
																		|it = 'Filtro per tipo di notifica';
																		|pl = 'Filtr według typu ostrzeżenia';
																		|tr = 'Uyarı türüne göre seçim'", Common.DefaultLanguageCode()));
	ParametersOfTheSelectionElement.Insert("Use", Use);

	SetTheDynamicListSelectionValue(ParametersOfTheSelectionElement);
	
EndProcedure

&AtServer
Procedure SelectionOfHiddenWarnings()
	
	Use = Not ValuesCache.WarningsShowHiddenWarnings;
	
	ParametersOfTheSelectionElement = New Structure;
	ParametersOfTheSelectionElement.Insert("DataFilterItem", Undefined);
	ParametersOfTheSelectionElement.Insert("LeftSelectionValue", New DataCompositionField("HideWarning"));
	ParametersOfTheSelectionElement.Insert("ComparisonType", DataCompositionComparisonType.Equal);
	ParametersOfTheSelectionElement.Insert("RightValue", False);
	ParametersOfTheSelectionElement.Insert("FilterPresentation", NStr("vi = 'Lọc cảnh báo ẩn';
																		|ru = 'Отбор скрытых предупреждений';
																		|en = 'Filter hidden warnings'; fa = 'Filter hidden warnings';
																		|it = 'Filtro delle notifiche nascoste';
																		|pl = 'Filtr ukrytych ostrzeżeń';
																		|tr = 'Gizli uyarıların seçimi'", Common.DefaultLanguageCode()));
	ParametersOfTheSelectionElement.Insert("Use", Use);

	SetTheDynamicListSelectionValue(ParametersOfTheSelectionElement);
	
EndProcedure

&AtServer
Procedure FindTheSelectionElementOfTheDynamicList(ItemsCollection, DataFilterItem, LeftSelectionValue, FilterPresentation, SearchForAGroupOfElements = False)
	
	If ItemsCollection = Undefined Then
		
		ItemsCollection = List.Filter.Items;
		
	EndIf;
	
	For Each FilterElement In ItemsCollection Do
		
		If SearchForAGroupOfElements
			And TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup")
			And FilterElement.Presentation = FilterPresentation Then
			
			DataFilterItem = FilterElement;
			Break;
			
		ElsIf FilterElement.Presentation = FilterPresentation
			And FilterElement.LeftValue = LeftSelectionValue Then
			
			DataFilterItem = FilterElement;
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetTheDynamicListSelectionValue(ParametersOfTheSelectionElement)
	Var ItemsCollection, DataFilterItem, LeftSelectionValue, TypeOfDynamicListSelectionComparison;
	Var RightValue, FilterPresentation, Use;
	
	ParametersOfTheSelectionElement.Property("ItemsCollection", ItemsCollection);
	ParametersOfTheSelectionElement.Property("DataFilterItem", DataFilterItem);
	ParametersOfTheSelectionElement.Property("LeftSelectionValue",	LeftSelectionValue);
	ParametersOfTheSelectionElement.Property("ComparisonType",		TypeOfDynamicListSelectionComparison);
	ParametersOfTheSelectionElement.Property("RightValue",		RightValue);
	ParametersOfTheSelectionElement.Property("FilterPresentation", FilterPresentation);
	ParametersOfTheSelectionElement.Property("Use",		Use);
	
	If ItemsCollection = Undefined Then
		
		ItemsCollection = List.Filter.Items;
		
	EndIf;
	
	If DataFilterItem = Undefined Then
		
		FindTheSelectionElementOfTheDynamicList(ItemsCollection, DataFilterItem, LeftSelectionValue, FilterPresentation);
		
	EndIf;
	
	If DataFilterItem = Undefined Then
		
		DataFilterItem = ItemsCollection.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue = LeftSelectionValue;
		DataFilterItem.ComparisonType = TypeOfDynamicListSelectionComparison;
		DataFilterItem.RightValue = RightValue;
		DataFilterItem.Presentation = FilterPresentation;
		DataFilterItem.Use = Use;
		
	Else
		
		DataFilterItem.RightValue = RightValue;
		DataFilterItem.Use = Use;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeTheWarningStatusOnTheServer(ASetOfStructures, HideDisplay)
	
	For Each StructureWithStringData In ASetOfStructures Do
		
		If TypeOf(StructureWithStringData.WarningType) = Type("EnumRef.DataExchangeIssuesTypes") Then
			
			InformationRegisters.DataExchangeResults.Ignore(StructureWithStringData.ObjectWithIssue, StructureWithStringData.WarningType, HideDisplay,
				StructureWithStringData.InfobaseNode, StructureWithStringData.UniqueKey);
			
		ElsIf Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
			
			If AccessRight("Read", Metadata.InformationRegisters.ObjectsVersions) Then
				ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
				ModuleObjectsVersioning.IgnoreObjectVersion(StructureWithStringData.ObjectWithIssue,
					StructureWithStringData.VersionFromOtherApplication, HideDisplay);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#Region BatchErrorCorrection

&AtClient
Procedure NavigateDocumentsThroughTheSelectedLines(SelectedRows)
	
	DataForSelectedRows = New Array;
	For Each RowIndex In SelectedRows Do
		
		RowData = Items.List.RowData(RowIndex);
		If RowData = Undefined
			Or RowData.WarningType <> PredefinedValue("Enum.DataExchangeIssuesTypes.UnpostedDocument")
			Or Not ValueIsFilled(RowData.ObjectWithIssue)
			Then
			
			Continue;
			
		EndIf;
		
		DataForSelectedRows.Add(RowData.ObjectWithIssue);
		
	EndDo;
	
	If DataForSelectedRows.Count() = 0 Then
		
		ErrorMessage = NStr("vi = 'Trong các dòng đã chọn không có cảnh báo có kiểu <Chứng từ chưa kết chuyển>';
							|ru = 'В выделенных строках нет предупреждений с типом <Непроведенный документ>';
							|en = 'There are no warnings with the <Unposted document> type in the selected lines'; fa = 'There are no warnings with the <Unposted document> type in the selected lines';
							|it = 'Nelle righe evidenziate non ci sono notifiche con tipo <Documento non pubblicato>';
							|pl = 'W wybranych wierszach nie ma ostrzeżeń z typem <Niezatwierdzony dokument>';
							|tr = 'Seçilen satırlarda <Geçirilmeyen belge> türlü uyarı yok'", CommonClient.DefaultLanguageCode());
		ShowMessageBox(Undefined, ErrorMessage);
		Return
		
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("DataForSelectedRows", DataForSelectedRows);
	
	CallbackDescription = New CallbackDescription("AfterGroupProcessingOfWarnings", ThisObject);
	
	OpenForm("InformationRegister.DataExchangeResults.Form.PostingWarningsProcessing", OpeningParameters, ThisObject, , , , CallbackDescription);
	
EndProcedure

&AtClient
Procedure CollisionsOnSelectedLines(SelectedRows)
	
	TypesOfCollisionWarnings = New Array(2);
	TypesOfCollisionWarnings[0] = ValuesCache.RejectedConflictData;
	TypesOfCollisionWarnings[1] = ValuesCache.ConflictDataAccepted;
	
	DataForSelectedRows = New Array;
	For Each RowIndex In SelectedRows Do
		
		RowData = Items.List.RowData(RowIndex);
		If RowData = Undefined
			Or TypesOfCollisionWarnings.Find(RowData.WarningType) = Undefined
			Or Not ValueIsFilled(RowData.ObjectWithIssue)
			Then
			
			Continue;
			
		EndIf;
		
		StructureOfData = New Structure;
		StructureOfData.Insert("VersionFromOtherApplication", RowData.VersionFromOtherApplication);
		StructureOfData.Insert("ThisApplicationVersion", RowData.ThisApplicationVersion);
		StructureOfData.Insert("ObjectWithIssue", RowData.ObjectWithIssue);
		
		DataForSelectedRows.Add(StructureOfData);
		
	EndDo;
	
	If DataForSelectedRows.Count() = 0 Then
		
		ErrorMessage = NStr("vi = 'Trong các dòng đã chọn không có cảnh báo có kiểu <Chưa tiếp nhận dữ liệu xung đột>, <Đã tiếp nhận dữ liệu xung đột>';
							|ru = 'В выделенных строках нет предупреждений с типами <Неприняты данные коллизии>, <Приняты данные коллизии>';
							|en = 'There are no warnings with the <Rejected conflict data> and <Received conflict data> types in the selected lines'; fa = 'There are no warnings with the <Rejected conflict data> and <Received conflict data> types in the selected lines';
							|it = 'Nelle righe evidenziate non ci sono notifiche con tipi <Dati conflitto non ricevuti> e <Dati conflitto ricevuti>';
							|pl = 'W wybranych wierszach nie ma ostrzeżeń z typami <Nieprzyjęte dane kolizji>, <Przyjęte dane kolizji>';
							|tr = 'Seçilen satırlarda <Veri çarpışmaları kabul edilmedi>, <Veri çarpışmaları kabul edildi> türlü uyarılar yok'", CommonClient.DefaultLanguageCode());
		ShowMessageBox(Undefined, ErrorMessage);
		Return
		
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("DataForSelectedRows", DataForSelectedRows);
	
	CallbackDescription = New CallbackDescription("AfterGroupProcessingOfWarnings", ThisObject);
	
	OpenForm("InformationRegister.DataExchangeResults.Form.ConflictWarningsProcessing", OpeningParameters, ThisObject, , , , CallbackDescription);
	
EndProcedure

&AtClient
Procedure ForbiddingLoadingBySelectedLines(SelectedRows)
	
	TypesOfCollisionWarnings = New Array(2);
	TypesOfCollisionWarnings[0] = ValuesCache.RejectedDueToPeriodEndClosingDateObjectDoesNotExistInInfobase;
	TypesOfCollisionWarnings[1] = ValuesCache.RejectedDueToPeriodEndClosingDateObjectExistsInInfobase;
	
	DataForSelectedRows = New Array;
	For Each RowIndex In SelectedRows Do
		
		RowData = Items.List.RowData(RowIndex);
		If RowData = Undefined
			Or TypesOfCollisionWarnings.Find(RowData.WarningType) = Undefined
			Or Not ValueIsFilled(RowData.ObjectWithIssue)
			Then
			
			Continue;
			
		EndIf;
		
		StructureOfData = New Structure;
		StructureOfData.Insert("VersionFromOtherApplication", RowData.VersionFromOtherApplication);
		StructureOfData.Insert("ThisApplicationVersion", RowData.ThisApplicationVersion);
		StructureOfData.Insert("ObjectWithIssue", RowData.ObjectWithIssue);
		
		DataForSelectedRows.Add(StructureOfData);
		
	EndDo;
	
	If DataForSelectedRows.Count() = 0 Then
		
		ErrorMessage = NStr("vi = 'Trong các dòng đã chọn không có cảnh báo có kiểu<Chưa tiếp nhận, có sẵn>,<Chưa tiếp nhận, mới>,
			|xảy ra do thử kết nhập dữ liệu vào kỳ đã đóng.';
			|ru = 'В выделенных строках нет предупреждений с типами <Непринятый, существующий>, <Непринятый, новый>,
			|которые возникли из-за попытки загрузить данных в закрытый период.';
			|en = 'The selected lines do not contain warnings with the <Rejected, existing> and <Rejected, new> types
			|resulted from an attempt to import data to a closed period.'; fa = 'The selected lines do not contain warnings with the <Rejected, existing> and <Rejected, new> types
			|resulted from an attempt to import data to a closed period.';
			|it = 'Nelle righe evidenziate non ci sono notifiche con i tipi <Non ricevuto, esistente>, <Non ricevuto, nuovo>,
			| rilevati a causa del tentativo di scaricare dati nel periodo chiuso.';
			|pl = 'W wybranych wierszach nie ma ostrzeżeń z typami <Nieprzyjęty, istniejący>, <Nieprzyjęty, nowy>,
			|które powstały z powodu próby ładowania danych do zamkniętego okresu.';
			|tr = 'Seçilen satırlarda kapalı dönemde veri yüklemesinden dolayı oluşan <Kabul edilmedi, var olan>, <Kabul edilmedi, yeni> türlü uyarılar yok.
			|.'", CommonClient.DefaultLanguageCode());
		ShowMessageBox(Undefined, ErrorMessage);
		Return
		
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("DataForSelectedRows", DataForSelectedRows);
	
	CallbackDescription = New CallbackDescription("AfterGroupProcessingOfWarnings", ThisObject);
	
	OpenForm("InformationRegister.DataExchangeResults.Form.WarningsProcessingByImportRestrictionDate", OpeningParameters, ThisObject, , , , CallbackDescription);
	
EndProcedure

&AtClient
Procedure GroupChangeOfDetailsForSelectedLines(SelectedRows)
	
	DataForSelectedRows = New Array;
	For Each RowIndex In SelectedRows Do
		
		RowData = Items.List.RowData(RowIndex);
		If RowData = Undefined
			Or RowData.WarningType <> PredefinedValue("Enum.DataExchangeIssuesTypes.BlankAttributes")
			Or Not ValueIsFilled(RowData.ObjectWithIssue)
			Then
			
			Continue;
			
		EndIf;
		
		DataForSelectedRows.Add(RowData.ObjectWithIssue);
		
	EndDo;
	
	If DataForSelectedRows.Count() = 0 Then
		
		ErrorMessage = NStr("vi = 'Trong các dòng đã chọn không có cảnh báo có kiểu <Mục tin trống>.';
							|ru = 'В выделенных строках нет предупреждений с типами <Пустые реквизиты>.';
							|en = 'There are no warnings with the <Empty attributes> types in the selected lines.'; fa = 'There are no warnings with the <Empty attributes> types in the selected lines.';
							|it = 'Nelle righe evidenziate non ci sono notifiche con i tipi <Attributi vuoti>.';
							|pl = 'W wybranych wierszach nie ma ostrzeżeń z typami <Puste atrybuty>.';
							|tr = 'Seçilen satırlarda <Boş öznitelikler> türlü uyarılar yok.'", CommonClient.DefaultLanguageCode());
		ShowMessageBox(Undefined, ErrorMessage);
		Return
		
	EndIf;
	
	ChangeTheDetailsOfTheGroupProcessing(DataForSelectedRows)
	
EndProcedure

&AtClient
Procedure ChangeTheDetailsOfTheGroupProcessing(DataForSelectedRows)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.BatchEditObjects") Then
		
		Return;
		
	EndIf;
	
	BulkEditParameters = New Structure;
	BulkEditParameters.Insert("ObjectsArray", DataForSelectedRows);
	
	CallbackDescription = New CallbackDescription("AfterGroupProcessingOfWarnings", ThisObject);
	
	ModuleBatchObjectsModificationClient = CommonClient.CommonModule("BatchEditObjectsClient");
	ModuleBatchObjectsModificationClient.StartChangingTheSelectedOnesWithAnAlert(BulkEditParameters, CallbackDescription)
	
EndProcedure

&AtClient
Procedure AfterGroupProcessingOfWarnings(Result, AdditionalParameters) Export
	
	// Cannot add "Result <> Undefined" due to:
	// - "ChangeTheDetailsOfTheGroupProcessing" always returns "Undefined".
	// - In other forms, the user can do the fixing and then click Cancel.
	UpdateTheFormList();
	
EndProcedure

#EndRegion

#EndRegion